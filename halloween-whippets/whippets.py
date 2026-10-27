#!/usr/bin/env python3
# =====================================================================
#  Halloweenowe whippety - zestaw 6 mini figurek (druk FDM bez podpór)
#
#  Figurki są budowane z pól odległości (SDF): kule, elipsoidy i
#  stożki zaokrąglone łączone gładko (smooth union), więc powierzchnia
#  jest miękka jak u odlewanych figurek. Siatka powstaje metodą
#  marching cubes i jest zapisywana jako STL.
#
#  Układ współrzędnych (jednostki projektowe, w STL mnożone przez
#  --scale): Z = góra, Z = 0 to stół, pies patrzy w stronę -Y.
#
#  Użycie:
#    python3 whippets.py                 # wszystkie 6, skala 1.25
#    python3 whippets.py witch ghost     # wybrane
#    python3 whippets.py --scale 1.5     # większe (ok. 37 mm)
#  Wymaga: numpy, scikit-image, trimesh, fast-simplification
# =====================================================================
import argparse
import os

import numpy as np
import trimesh
from skimage import measure

VOXEL = 0.14         # krok siatki w jednostkach projektowych
TARGET_FACES = 90_000


# --------------------------------------------------------------------
#  Prymitywy SDF (wektorowe, p = krotka tablic (x, y, z))
# --------------------------------------------------------------------
def v(*a):
    return np.array(a, dtype=np.float32)


def length(x, y, z):
    return np.sqrt(x * x + y * y + z * z)


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b + (a - b) * h - k * h * (1 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def rot_matrix(rx=0, ry=0, rz=0):
    rx, ry, rz = np.radians([rx, ry, rz])
    cx, sx, cy, sy, cz, sz = np.cos(rx), np.sin(rx), np.cos(ry), np.sin(ry), np.cos(rz), np.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return (Rz @ Ry @ Rx).astype(np.float32)


def to_local(p, center, R):
    """Punkty świata -> układ lokalny obiektu obróconego o R wokół center."""
    x, y, z = p[0] - center[0], p[1] - center[1], p[2] - center[2]
    # R^T * (p - c)
    return (R[0, 0] * x + R[1, 0] * y + R[2, 0] * z,
            R[0, 1] * x + R[1, 1] * y + R[2, 1] * z,
            R[0, 2] * x + R[1, 2] * y + R[2, 2] * z)


def sphere(p, c, r):
    return length(p[0] - c[0], p[1] - c[1], p[2] - c[2]) - r


def ellipsoid(p, c, r, R=None):
    if R is None:
        x, y, z = p[0] - c[0], p[1] - c[1], p[2] - c[2]
    else:
        x, y, z = to_local(p, c, R)
    k0 = length(x / r[0], y / r[1], z / r[2])
    k1 = length(x / r[0] ** 2, y / r[1] ** 2, z / r[2] ** 2)
    return k0 * (k0 - 1) / np.maximum(k1, 1e-6)


def round_cone(p, a, b, r1, r2):
    """Stożek zaokrąglony między punktami a (promień r1) i b (r2)."""
    a, b = v(*a), v(*b)
    ba = b - a
    l2 = float(ba @ ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    px, py, pz = p[0] - a[0], p[1] - a[1], p[2] - a[2]
    yy = px * ba[0] + py * ba[1] + pz * ba[2]
    zz = yy - l2
    qx, qy, qz = px * l2 - ba[0] * yy, py * l2 - ba[1] * yy, pz * l2 - ba[2] * yy
    x2 = qx * qx + qy * qy + qz * qz
    y2 = yy * yy * l2
    z2 = zz * zz * l2
    k = np.sign(rr) * rr * rr * x2
    d_mid = (np.sqrt(np.maximum(x2 * a2 * il2, 0)) + yy * rr) * il2 - r1
    d_b = np.sqrt(x2 + z2) * il2 - r2
    d_a = np.sqrt(x2 + y2) * il2 - r1
    return np.where(np.sign(zz) * a2 * z2 > k, d_b,
                    np.where(np.sign(yy) * a2 * y2 < k, d_a, d_mid))


def capsule(p, a, b, r):
    return round_cone(p, a, b, r, r)


def tube(p, pts, radii, k=0.0):
    """Gładka rurka przez punkty pts, promienie radii w węzłach."""
    d = None
    for i in range(len(pts) - 1):
        s = round_cone(p, pts[i], pts[i + 1], radii[i], radii[i + 1])
        d = s if d is None else smin(d, s, k)
    return d


def torus(p, c, R_major, r_minor, R=None):
    x, y, z = to_local(p, c, R if R is not None else np.eye(3, dtype=np.float32))
    q = np.sqrt(x * x + y * y) - R_major
    return np.sqrt(q * q + z * z) - r_minor


def rbox(p, c, half, r, R=None):
    x, y, z = to_local(p, c, R if R is not None else np.eye(3, dtype=np.float32))
    qx, qy, qz = np.abs(x) - half[0] + r, np.abs(y) - half[1] + r, np.abs(z) - half[2] + r
    out = length(np.maximum(qx, 0), np.maximum(qy, 0), np.maximum(qz, 0))
    return out + np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0) - r


def rcylinder(p, c, r, h, rr, R=None):
    """Walec o osi Z (lokalnie), promień r, połowa wysokości h, zaokrąglenie rr."""
    x, y, z = to_local(p, c, R if R is not None else np.eye(3, dtype=np.float32))
    dx = np.sqrt(x * x + y * y) - r + rr
    dz = np.abs(z) - h + rr
    return np.minimum(np.maximum(dx, dz), 0) + np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dz, 0) ** 2) - rr


def polygon2d(u, w, verts):
    """SDF wielokąta 2D (iq), verts = [(u, w), ...]."""
    vs = np.array(verts, dtype=np.float32)
    d = (u - vs[0, 0]) ** 2 + (w - vs[0, 1]) ** 2
    s = np.ones_like(u)
    n = len(vs)
    for i in range(n):
        j = (i - 1) % n
        ex, ey = vs[j] - vs[i]
        wx, wy = u - vs[i, 0], w - vs[i, 1]
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        bx, by = wx - ex * t, wy - ey * t
        d = np.minimum(d, bx * bx + by * by)
        c1 = w >= vs[i, 1]
        c2 = w < vs[j, 1]
        c3 = ex * wy > ey * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
    return s * np.sqrt(d)


def engrave(d, d_mark2d, depth, extra=None):
    """Grawer o stałej głębokości: d_mark2d < 0 tam, gdzie wycinamy."""
    cut = np.maximum(d_mark2d, -(d + depth))
    if extra is not None:
        cut = np.maximum(cut, extra)
    return np.maximum(d, -cut)


# --------------------------------------------------------------------
#  Whippet
# --------------------------------------------------------------------
NECK_TOP = v(0, -1.8, 18.0)   # punkt obrotu głowy


class Dog:
    """Siedzący whippet w stylu chibi. Opcje pozwalają zmieniać pozę."""

    def __init__(self, head_rot=(0, 0, 0), front_legs=None, tail=True,
                 ears="rose"):
        self.R_head = rot_matrix(*head_rot)
        self.front_legs = front_legs
        self.tail = tail
        self.ears = ears

    # punkt z układu głowy -> świat
    def hp(self, x, y, z):
        return NECK_TOP + self.R_head @ v(x, y, z)

    def head(self, p, dilate=0.0, with_eyes=True):
        hp = self.hp
        skull = ellipsoid(p, hp(0, -0.3, 2.7), (4.2 + dilate, 4.4 + dilate, 4.0 + dilate), self.R_head)
        cheeks = ellipsoid(p, hp(0, -2.5, 1.1), (3.2 + dilate, 2.7 + dilate, 2.5 + dilate), self.R_head)
        snout = round_cone(p, hp(0, -3.4, 1.35), hp(0, -6.5, 0.95), 2.35 + dilate, 1.45 + dilate)
        nose = ellipsoid(p, hp(0, -7.55, 1.3), (1.1 + dilate, 0.85 + dilate, 0.85 + dilate), self.R_head)
        d = smin(skull, cheeks, 1.0)
        d = smin(d, snout, 1.2)
        d = smin(d, nose, 0.35)
        for sx in (-1, 1):
            if self.ears == "rose":
                # uszy różyczkowe: płaski płatek złożony do tyłu i lekko na bok
                ear = ellipsoid(p, hp(sx * 2.75, 1.9, 4.7), (0.6 + dilate, 2.7 + dilate, 1.5 + dilate),
                                self.R_head @ rot_matrix(-28, sx * -38, sx * 18))
            else:  # uszy postawione (pod kapeluszem)
                ear = ellipsoid(p, hp(sx * 3.0, 0.9, 5.4), (0.6 + dilate, 1.6 + dilate, 2.2 + dilate),
                                self.R_head @ rot_matrix(-20, sx * -35, sx * 10))
            d = smin(d, ear, 1.0)
        if with_eyes:
            for sx in (-1, 1):
                eye = sphere(p, hp(sx * 1.85, -4.35, 2.9), 0.8)
                d = smax(d, -eye, 0.25)
        return d

    def legs(self, p):
        d = None
        legs = self.front_legs or [((-1.7, -2.4, 8.5), (-1.7, -3.0, 1.2)),
                                   ((1.7, -2.4, 8.5), (1.7, -3.0, 1.2))]
        for top, bottom in legs:
            leg = round_cone(p, top, bottom, 1.45, 1.1)
            paw = ellipsoid(p, (bottom[0], bottom[1] - 0.8, bottom[2] - 0.45),
                            (1.2, 1.65, 0.8))
            leg = smin(leg, paw, 0.5)
            d = leg if d is None else np.minimum(d, leg)
        return d

    def torso(self, p, dilate=0.0, hind=True):
        e = dilate
        butt = ellipsoid(p, (0, 4.2, 4.0), (3.6 + e, 3.6 + e, 3.8 + e))
        d = butt
        for sx in ((-1, 1) if hind else ()):
            thigh = ellipsoid(p, (sx * 3.2, 2.4, 3.5), (2.1 + e, 4.0 + e, 3.3 + e), rot_matrix(12, 0, 0))
            hpaw = capsule(p, (sx * 3.5, 0.6, 0.95), (sx * 3.3, -3.4, 0.95), 1.0 + e)
            d = smin(d, smin(thigh, hpaw, 0.6), 0.8)
        waist = round_cone(p, (0, 3.6, 5.0), (0, -0.6, 10.3), 3.3 + e, 3.7 + e)
        chest = ellipsoid(p, (0, -1.4, 9.6), (3.4 + e, 3.4 + e, 4.6 + e))
        neck = round_cone(p, (0, -0.8, 12.5), tuple(NECK_TOP), 2.8 + e, 2.25 + e)
        d = smin(d, waist, 1.2)
        d = smin(d, chest, 1.2)
        d = smin(d, neck, 1.0)
        return d

    def tail_sdf(self, p):
        pts = [(0, 7.2, 1.7), (2.6, 8.1, 0.95), (5.0, 6.4, 0.85),
               (5.9, 3.0, 0.8), (5.7, -0.6, 0.75), (4.9, -3.2, 0.7)]
        return tube(p, pts, [1.0, 0.95, 0.9, 0.82, 0.75, 0.7], k=0.3)

    def sdf(self, p):
        d = self.torso(p)
        d = smin(d, self.legs(p), 0.7)
        if self.tail:
            d = smin(d, self.tail_sdf(p), 0.4)
        d = smin(d, self.head(p), 1.0)
        return d


# --------------------------------------------------------------------
#  Akcesoria
# --------------------------------------------------------------------
def pumpkin(p, c, r=3.6, h=3.0, lobes=8, face=True, stem=True, R=None):
    if R is None:
        R = np.eye(3, dtype=np.float32)
    c = v(*c)
    d = None
    for i in range(lobes):
        a = 2 * np.pi * i / lobes
        oc = c + R @ v(np.cos(a) * r * 0.42, np.sin(a) * r * 0.42, 0)
        lobe = ellipsoid(p, oc, (r * 0.62, r * 0.62, h), R)
        d = lobe if d is None else smin(d, lobe, 0.25)
    if stem:
        top = c + R @ v(0, 0, h - 0.3)
        d = smin(d, round_cone(p, top, top + R @ v(0.25, 0.3, 1.3), 0.6, 0.38), 0.35)
    if face:
        # buźka na stronie -Y lokalnego układu dyni
        lx, ly, lz = to_local(p, c, R)
        s = r / 3.6
        eyes = np.minimum(
            polygon2d(lx, lz, [(-1.9 * s, 0.25 * s), (-0.5 * s, 0.25 * s), (-1.2 * s, 1.35 * s)]),
            polygon2d(lx, lz, [(0.5 * s, 0.25 * s), (1.9 * s, 0.25 * s), (1.2 * s, 1.35 * s)]))
        mouth = polygon2d(lx, lz, [(-2.1 * s, -0.45 * s), (-1.3 * s, -0.75 * s), (-0.9 * s, -0.45 * s),
                                   (-0.3 * s, -0.75 * s), (0.3 * s, -0.75 * s), (0.9 * s, -0.45 * s),
                                   (1.3 * s, -0.75 * s), (2.1 * s, -0.45 * s), (1.2 * s, -1.6 * s),
                                   (-1.2 * s, -1.6 * s)])
        d = engrave(d, np.minimum(eyes, mouth), 0.5, extra=ly)
    return d


def witch(p):
    dog = Dog(head_rot=(0, 0, -8), ears="up")
    d = dog.sdf(p)
    R = dog.R_head @ rot_matrix(-4, 4, 0)
    base = dog.hp(0, -0.2, 5.0)

    def hat(x, y, z):
        return base + R @ v(x, y, z)
    # rondo: cienki dysk osadzony nisko na czole; spód podparty głową,
    # przejście głowa-rondo zaokrąglone (fillet ze smooth union)
    brim = rcylinder(p, hat(0, 0, -0.1), 5.8, 0.36, 0.3, R)
    # spód ronda jako lejek ok. 57° od pionu, żeby nie wisiał w powietrzu
    hx, hy, hz = to_local(p, base, R)
    funnel = (np.sqrt(hx * hx + hy * hy) - (3.4 + (hz + 1.6) * 1.55)) * 0.54
    funnel = np.maximum(funnel, np.maximum(-(hz + 1.6), hz + 0.1))
    brim = smin(brim, funnel, 0.25)
    cone = tube(p, [hat(0, 0, 0.3), hat(0, 0.15, 4.5), hat(0, 0.7, 7.8), hat(0, 2.2, 9.8)],
                [3.2, 2.0, 1.0, 0.45], k=0.4)
    band = torus(p, hat(0, 0.0, 1.0), 2.95, 0.5, R)
    d = smin(d, brim, 1.4)
    d = smin(d, cone, 0.5)
    d = smin(d, band, 0.15)
    # gwiazdka-łatka na stożku od frontu
    lx, ly, lz = to_local(p, hat(0, 0, 3.4), R)
    star = []
    for i in range(10):
        a = np.pi / 2 + i * np.pi / 5
        rr = 1.0 if i % 2 == 0 else 0.42
        star.append((np.cos(a) * rr, np.sin(a) * rr))
    star_d = np.maximum(polygon2d(lx, lz, star), np.maximum(ly, -(ly + 4.0)))
    d = np.minimum(d, np.maximum(star_d, cone - 0.35))
    # kokarda pod szyją
    for sx in (-1, 1):
        d = smin(d, ellipsoid(p, (sx * 1.1, -3.4, 13.3), (1.1, 0.6, 0.75), rot_matrix(0, sx * 20, 0)), 0.3)
    d = smin(d, sphere(p, (0, -3.55, 13.3), 0.55), 0.2)
    return d


def ghost(p):
    dog = Dog(head_rot=(0, 0, 6))
    sheet_head = dog.head(p, dilate=0.75, with_eyes=False)
    # dzwon prześcieradła od karku do stołu, z falistym rąbkiem
    x, y, z = p
    cx, cy = 0.0, 0.8
    rho = np.sqrt(x * x + (y - cy) ** 2)
    th = np.arctan2(y - cy, x)
    t = np.clip(z / 18.0, 0, 1)
    radius = 9.0 - 6.2 * t ** 0.7 + 0.75 * np.sin(7 * th) * np.clip(1 - z / 4.0, 0, 1)
    bell = smax((rho - radius) * 0.85, z - 17.5, 2.5)
    d = smin(bell, sheet_head, 2.0)
    # ogon wystający spod prześcieradła
    tail = tube(p, [(0, 8.0, 1.2), (2.4, 10.4, 0.95), (5.0, 10.0, 0.85), (6.2, 8.0, 0.75)],
                [1.0, 0.92, 0.82, 0.72], k=0.3)
    d = smin(d, tail, 0.4)
    # przednie łapki spod rąbka
    for sx in (-1, 1):
        d = smin(d, ellipsoid(p, (sx * 1.9, -8.6, 0.8), (1.25, 1.7, 0.8)), 0.6)
    # otwory na oczy: owalne, głębokie
    eyes = None
    for sx in (-1, 1):
        ex, ey, ez = to_local(p, dog.hp(sx * 1.9, -4.6, 3.1), dog.R_head)
        e2d = length(ex / 0.85, 0 * ey, ez / 1.15) - 1.0
        eyes = e2d if eyes is None else np.minimum(eyes, e2d)
    _, ly, _ = to_local(p, dog.hp(0, -2.0, 0), dog.R_head)
    d = engrave(d, eyes * 0.85, 1.4, extra=ly)
    return d


def pumpkin_hug(p):
    legs = [((-2.0, -2.4, 9.0), (-3.0, -6.6, 5.9)),
            ((2.0, -2.4, 9.0), (3.0, -6.6, 5.9))]
    dog = Dog(head_rot=(14, 0, 0), front_legs=legs)
    d = dog.sdf(p)
    pk = pumpkin(p, (0, -7.0, 2.85), r=3.9, h=3.0, R=rot_matrix(0, 0, 0))
    d = smin(d, pk, 0.5)
    return d


def vampire(p):
    dog = Dog(head_rot=(0, 0, 0))
    d = dog.sdf(p)
    x, y, z = p
    # peleryna: dzwon za plecami, od karku do stołu
    cape = round_cone(p, (0, 1.6, 14.0), (0, 3.4, 0.6), 4.0, 8.0)
    cape = np.maximum(cape, -(y + 1.2 - 0.12 * z))         # tylko tył i boki
    cape = np.maximum(cape, -z)
    d = smin(d, cape, 0.4)
    # wysoki kołnierz: rozchylony lejek (ok. 25°), cienka ścianka
    t = (z - 12.4) / 6.6
    rho = np.sqrt(x * x + (y - (-0.6 + 1.2 * t)) ** 2)
    col = np.abs(rho - (3.3 + 2.5 * t)) * 0.93 - 0.38      # stożek, ścianka 0,76
    col = np.maximum(col, -(y + 0.4))
    col = np.maximum(col, np.maximum(z - 19.0, 12.0 - z))
    d = np.minimum(d, col)
    # medalion na piersi
    d = smin(d, ellipsoid(p, (0, -4.55, 12.2), (1.05, 0.45, 1.05)), 0.3)
    d = engrave(d, polygon2d(x, z - 12.2, [(-0.5, -0.4), (0.5, -0.4), (0, 0.5)]), 0.25, extra=y + 4.0)
    return d


def skeleton(p):
    legs = [((-1.7, -2.4, 8.5), (-1.7, -3.0, 1.2)),
            ((1.7, -2.4, 8.5), (1.7, -3.0, 1.2))]
    dog = Dog(head_rot=(-6, 0, 12), front_legs=legs)
    d = dog.sdf(p)
    x, y, z = p
    # sweter: pogrubiony tułów + rękawy, bez zadu
    # grubość 0,5, a przy dolnym ściągaczu zbiega pod 45° do zera (bez półki)
    sweater = dog.torso(p, hind=False) - 0.5 + np.clip(6.1 - z, 0, None)
    sweater = np.maximum(sweater, y - 2.4)
    sleeves = None
    for top, bot in legs:
        s = round_cone(p, top, (top[0], -2.85, 4.4), 1.95, 1.75)
        sleeves = s if sleeves is None else np.minimum(sleeves, s)
    sweater = smin(sweater, sleeves, 0.6)
    sweater = np.maximum(sweater, z - 15.2)
    d = smin(d, sweater, 0.3)
    # golf (rolowany kołnierz) i ściągacze rękawów
    d = smin(d, torus(p, (0, -1.2, 15.1), 2.75, 0.75, rot_matrix(-15, 0, 0)), 0.3)
    for top, _ in legs:
        d = smin(d, torus(p, (top[0], -2.85, 4.6), 1.5, 0.45), 0.5)
    # kości wypukłe na swetrze: mostek + 3 pary żeber
    shell = sweater - 0.5
    front = y + 1.6
    sternum = np.maximum(np.maximum(shell, np.abs(x) - 0.5), np.maximum(front, np.abs(z - 10.8) - 2.8))
    ribs = None
    for i, zc in enumerate((12.4, 10.8, 9.2)):
        # pas łukiem w dół na boki
        band = np.abs(z - zc + 0.22 * x * x) - 0.5
        r = np.maximum(np.maximum(shell, band), np.maximum(-(np.abs(x) - 0.9), y + 0.2))
        r = np.maximum(r, np.abs(x) - 3.0)
        ribs = r if ribs is None else np.minimum(ribs, r)
    bones = np.minimum(sternum, ribs)
    d = smin(d, bones, 0.15)
    return d


def lantern_dog(p):
    legs = [((-1.7, -2.4, 8.5), (-1.7, -3.0, 1.2)),
            ((1.9, -2.4, 8.5), (3.0, -4.6, 6.6))]       # prawa łapa na daszku latarenki
    dog = Dog(head_rot=(10, 0, -18), front_legs=legs)
    d = dog.sdf(p)
    x, y, z = p
    # szeroka obroża (typowa dla chartów) z kółkiem
    col = torus(p, (0, -1.15, 14.6), 2.75, 0.62, rot_matrix(-18, 0, 0))
    d = smin(d, col, 0.2)
    d = smin(d, torus(p, (0, -3.9, 13.4), 0.55, 0.22, rot_matrix(90, 0, 0)), 0.1)
    # latarenka
    lc = v(4.0, -6.2, 0)
    base = rbox(p, lc + v(0, 0, 0.45), (1.9, 1.9, 0.45), 0.2)
    body = rbox(p, lc + v(0, 0, 2.7), (1.55, 1.55, 1.9), 0.15)
    # okienka wklęsłe na 4 ścianach
    lx, ly, lz = p[0] - lc[0], p[1] - lc[1], p[2] - lc[2] - 2.75
    win = np.minimum(np.maximum(np.abs(lx) - 0.9, np.abs(lz) - 1.25),
                     np.maximum(np.abs(ly) - 0.9, np.abs(lz) - 1.25))
    body = engrave(body, win, 0.35)
    # płomyk w środku okienka (wypukły)
    flame = round_cone(p, lc + v(0, -1.0, 2.2), lc + v(0, -1.0, 3.5), 0.55, 0.12)
    body = np.minimum(body, np.maximum(flame, -(ly + 1.6)))
    # daszek: piramida 45°
    roof_z = lc[2] + 4.6
    roof = np.maximum((np.maximum(np.abs(lx), np.abs(ly)) + (z - roof_z) - 2.0) / np.sqrt(2), roof_z - z)
    ring = torus(p, lc + v(0, 0, roof_z + 1.9), 0.7, 0.28, rot_matrix(90, 0, 0))
    lan = np.minimum(np.minimum(base, body), np.minimum(roof, ring))
    d = smin(d, lan, 0.3)
    return d


MODELS = {
    "witch": ("czarownica", witch),
    "ghost": ("duszek", ghost),
    "pumpkin": ("z_dynia", pumpkin_hug),
    "vampire": ("wampir", vampire),
    "skeleton": ("sweter_szkielet", skeleton),
    "lantern": ("z_latarenka", lantern_dog),
}

BOUNDS = ((-12.0, 12.0), (-13.5, 12.5), (-0.6, 37.0))


def build(name, scale):
    fn = MODELS[name][1]
    # dno siatki przesunięte o pół woksela, żeby płaszczyzna Z = 0 nie
    # wypadała w węzłach (inaczej marching cubes robi zdegenerowane ścianki)
    lows = [BOUNDS[0][0], BOUNDS[1][0], -3.5 * VOXEL]
    axes = [np.arange(lo, hi + VOXEL, VOXEL, dtype=np.float32) for lo, (_, hi) in zip(lows, BOUNDS)]
    X, Y, Z = np.meshgrid(*axes, indexing="ij")
    d = fn((X, Y, Z))
    d = np.maximum(d, -Z)                      # płaski spód na stole
    d = d.astype(np.float32)
    verts, faces, _, _ = measure.marching_cubes(d, 0.0, spacing=(VOXEL,) * 3)
    verts += np.array(lows, dtype=np.float32)
    verts *= scale
    mesh = trimesh.Trimesh(verts, faces, process=True)
    if len(mesh.faces) > TARGET_FACES:
        mesh = mesh.simplify_quadric_decimation(face_count=TARGET_FACES)
    # spłaszcz to, co leży na stole, dokładnie do Z = 0
    vtx = mesh.vertices.copy()
    vtx[vtx[:, 2] < 0.3 * VOXEL * scale, 2] = 0.0
    mesh.vertices = vtx
    # tylko największa bryła (usuwa ewentualne drobinki)
    parts = mesh.split(only_watertight=False)
    if len(parts) > 1:
        mesh = max(parts, key=lambda m: len(m.faces))
    return mesh


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("models", nargs="*", default=list(MODELS))
    ap.add_argument("--scale", type=float, default=1.25)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "stl"))
    ap.add_argument("--voxel", type=float, default=VOXEL)
    a = ap.parse_args()
    globals()["VOXEL"] = a.voxel
    os.makedirs(a.out, exist_ok=True)
    for i, name in enumerate(a.models):
        mesh = build(name, a.scale)
        idx = list(MODELS).index(name) + 1
        path = os.path.join(a.out, f"{idx}_whippet_{MODELS[name][0]}.stl")
        mesh.export(path)
        ext = mesh.extents
        print(f"{path}: {ext[0]:.1f} x {ext[1]:.1f} x {ext[2]:.1f} mm, "
              f"{mesh.volume / 1000:.2f} cm3, watertight={mesh.is_watertight}, faces={len(mesh.faces)}")


if __name__ == "__main__":
    main()
