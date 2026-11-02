// =====================================================================
//  Drzwiczki rewizyjne do otworu w ścianie (szafka łazienkowa, wodomierz)
//  OpenSCAD 2021.01+
//
//  Dwie części:
//    * RAMKA - płaska płyta przyklejana do ściany wokół otworu, z kołnierzem
//      wchodzącym w otwór (centruje ramkę i zakrywa poszarpane krawędzie).
//      W narożnikach światła ramki są trójkątne wsporniki z gniazdami magnesów.
//    * DRZWICZKI - płaska płytka nakładana na ramkę, trzymana magnesami,
//      z otworem na palec do zdejmowania i opcjonalnymi szczelinami
//      wentylacyjnymi.
//
//  Obie części drukują się BEZ PODPÓR, przednią (widoczną) stroną do stołu.
//  Jeśli część nie mieści się na stole drukarki, jest automatycznie dzielona
//  w poziomie na kawałki:
//    * ramka - złącze ukośne 45° (klejone, samo się centruje),
//    * drzwiczki - złącze na jaskółczy ogon (klejone).
//
//  Układ współrzędnych (taki sam dla obu części):
//    X = poziomo wzdłuż ściany, Y = pionowo (góra ściany = +Y),
//    środek otworu w X = 0, Y = 0,
//    Z = 0 to przednia (widoczna) powierzchnia leżąca na stole,
//    +Z = w stronę ściany.
// =====================================================================

/* [Wybór części] */
// Co wygenerować
part = "assembly"; // [assembly, frame, door]
// Który kawałek (gdy część jest dzielona): -1 = wszystkie obok siebie, 0 = dolny, 1 = następny...
piece = -1;

/* [Otwór w ścianie - ZMIERZ!] */
// Szerokość otworu w płaszczyźnie ściany (najwęższe miejsce)
hole_w = 140;
// Wysokość otworu w płaszczyźnie ściany (najwęższe miejsce)
hole_h = 300;
// Głębokość, na jaką kołnierz wchodzi w otwór (0 = bez kołnierza; nie więcej niż grubość płyty ściany)
collar_d = 10;
// Luz między kołnierzem a krawędzią otworu (na stronę)
hole_clr = 1.0;

/* [Zakładki ramki na ścianę (mm poza krawędź otworu)] */
// 0 = ramka kończy się na krawędzi otworu (np. tuż obok boku szafki)
flange_left = 0;
flange_right = 20;
flange_top = 20;
// Na zdjęciu dno szafki jest prawie na wysokości dolnej krawędzi otworu
flange_bottom = 0;

/* [Ramka] */
plate_t = 4;       // grubość płyty ramki
collar_w = 3;      // grubość ścianki kołnierza
gusset = 17;       // przyprostokątna narożnego wspornika z magnesem
// Otwory na wkręty w zakładkach (tylko gdy zakładka >= 12 mm)
screws = true;
screw_d = 3.6;     // otwór na wkręt 3-3.5 mm
screw_head = 7.5;  // średnica łba stożkowego
screw_pitch = 110; // maks. rozstaw wkrętów wzdłuż boku

/* [Drzwiczki] */
door_t = 3.5;      // grubość drzwiczek
door_ov = 6;       // ile drzwiczki zachodzą na ramkę (ograniczane przez szerokość ramki)
door_r = 2;        // promień narożników
finger_d = 22;     // otwór na palec (0 = brak)
finger_off = 28;   // odległość środka otworu na palec od górnej krawędzi
vents = true;      // szczeliny wentylacyjne na dole (wilgoć w łazience)
vent_n = 3;
vent_w = 4;

/* [Magnesy] */
// Magnes neodymowy walcowy (np. 6 x 2 mm, po jednym w ramce i drzwiczkach w każdym narożniku)
mag_d = 6;
mag_h = 2;
mag_clr = 0.2;     // luz średnicy (wciskane/klejone)

/* [Druk] */
// Maks. wymiar na stole (Bambu Lab P2S: 256 mm; zostaw zapas)
bed = 245;
chamfer = 0.8;     // faza przednich krawędzi
dt_neck = 10;      // jaskółczy ogon: szerokość szyjki
dt_head = 15;      // szerokość główki
dt_len = 7;        // długość
dt_clr = 0.15;     // luz złącza na stronę

/* [Hidden] */
$fn = 48;
eps = 0.01;
BIG = 2000;

// ---------------------------------------------------------------------
// Wartości pochodne
// ---------------------------------------------------------------------
hx = hole_w / 2;
hy = hole_h / 2;
// Światło ramki (otwór, przez który sięgasz do wodomierza)
ox = hx - hole_clr - collar_w;
oy = hy - hole_clr - collar_w;
// Krawędzie zewnętrzne ramki (zakładka 0 = do krawędzi otworu)
fx0 = -hx - max(flange_left, -hole_clr);
fx1 =  hx + max(flange_right, -hole_clr);
fy0 = -hy - max(flange_bottom, -hole_clr);
fy1 =  hy + max(flange_top, -hole_clr);
frame_D = plate_t + collar_d;
// Szerokość ramki od światła do krawędzi (na każdą stronę)
rim_l = -ox - fx0;  rim_r = fx1 - ox;
rim_b = -oy - fy0;  rim_t = fy1 - oy;
// Drzwiczki
dx0 = -ox - min(door_ov, rim_l - 0.6);
dx1 =  ox + min(door_ov, rim_r - 0.6);
dy0 = -oy - min(door_ov, rim_b - 0.6);
dy1 =  oy + min(door_ov, rim_t - 0.6);
// Magnesy: środek w narożniku światła
mag_m = mag_d / 2 + 1.6;
mag_pts = [for (sx = [-1, 1], sy = [-1, 1]) [sx * (ox - mag_m), sy * (oy - mag_m)]];
pocket_d = mag_d + mag_clr;
pocket_h = mag_h + 0.2;

// Podział na kawałki
frame_H = fy1 - fy0;
door_H = dy1 - dy0;
frame_n = ceil(frame_H / (bed - frame_D));
door_n = ceil(door_H / (bed - dt_len));
function cuts(y0, H, n) = [for (i = [1 : 1 : n - 1]) y0 + H * i / n];
frame_cuts = cuts(fy0, frame_H, frame_n);
door_cuts = cuts(dy0, door_H, door_n);

assert(fx1 - fx0 <= bed, "Ramka szersza niż stół - zmniejsz zakładki");
assert(ox > gusset && oy > gusset, "Otwór za mały");
assert(plate_t >= pocket_h + 1.2, "Płyta ramki za cienka na magnes");
assert(door_t >= pocket_h + 1.0, "Drzwiczki za cienkie na magnes");
assert(gusset >= 2 * mag_m + (pocket_d / 2 + 1) * sqrt(2), "Wspornik za mały na magnes");

echo(str("Swiatlo ramki: ", 2 * ox, " x ", 2 * oy, " mm"));
echo(str("Ramka: ", fx1 - fx0, " x ", frame_H, " mm, kawalki: ", frame_n));
echo(str("Drzwiczki: ", dx1 - dx0, " x ", door_H, " mm, kawalki: ", door_n));

// ---------------------------------------------------------------------
// Pomocnicze
// ---------------------------------------------------------------------
module rrect(x0, y0, x1, y1, r) {
    if (r <= 0) translate([x0, y0]) square([x1 - x0, y1 - y0]);
    else hull() for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
        translate([x, y]) circle(r);
}

// Płyta z fazą 45° na przedniej (dolnej w druku) krawędzi
module chamfered_slab(x0, y0, x1, y1, r, t, c) {
    hull() {
        linear_extrude(eps) offset(delta = -c) rrect(x0, y0, x1, y1, r);
        translate([0, 0, c]) linear_extrude(t - c) rrect(x0, y0, x1, y1, r);
    }
}

// ---------------------------------------------------------------------
// Ramka
// ---------------------------------------------------------------------
module gussets2d() {
    for (sx = [-1, 1], sy = [-1, 1])
        polygon([[sx * ox, sy * oy],
                 [sx * (ox - gusset), sy * oy],
                 [sx * ox, sy * (oy - gusset)]]);
}

// Rozkład punktów na odcinku [a0, a1], maks. co screw_pitch
function spread_pts(a0, a1) = let (n = max(1, ceil((a1 - a0) / screw_pitch)))
    [for (i = [0 : n - 1]) a0 + (a1 - a0) * (i + 0.5) / n];
// Wkręty na bokach pionowych: osobno w każdym kawałku, z dala od cięć
cut_m = frame_D / 2 + screw_head / 2 + 3;
side_bounds = concat([fy0 + 6], [for (c = frame_cuts) each [c - cut_m, c + cut_m]], [fy1 - 6]);
side_ys = [for (k = [0 : 2 : len(side_bounds) - 2]) each spread_pts(side_bounds[k], side_bounds[k + 1])];

module screw_positions() {
    if (flange_left >= 12)  for (y = side_ys) translate([-hx - flange_left / 2, y]) children();
    if (flange_right >= 12) for (y = side_ys) translate([ hx + flange_right / 2, y]) children();
    if (flange_bottom >= 12) for (x = spread_pts(fx0 + 10, fx1 - 10)) translate([x, -hy - flange_bottom / 2]) children();
    if (flange_top >= 12)   for (x = spread_pts(fx0 + 10, fx1 - 10)) translate([x,  hy + flange_top / 2]) children();
}

module frame_whole() {
    difference() {
        union() {
            // Płyta
            difference() {
                chamfered_slab(fx0, fy0, fx1, fy1, 2, plate_t, chamfer);
                translate([0, 0, -1]) linear_extrude(plate_t + 2)
                    difference() {
                        rrect(-ox, -oy, ox, oy, 0);
                        gussets2d();
                    }
            }
            // Kołnierz w otworze
            if (collar_d > 0)
                translate([0, 0, plate_t - eps]) linear_extrude(collar_d + eps)
                    difference() {
                        rrect(-hx + hole_clr, -hy + hole_clr, hx - hole_clr, hy - hole_clr, 1);
                        rrect(-ox, -oy, ox, oy, 0);
                    }
        }
        // Gniazda magnesów - od przodu (od stołu)
        for (p = mag_pts) translate([p[0], p[1], -1]) cylinder(d = pocket_d, h = pocket_h + 1);
        // Wkręty z łbem stożkowym (stożek 45° od stołu - drukuje się bez podpór)
        if (screws) screw_positions() {
            translate([0, 0, -1]) cylinder(d = screw_d, h = plate_t + 2);
            translate([0, 0, -eps]) cylinder(d1 = screw_head, d2 = 0, h = screw_head / 2);
        }
    }
}

// Półprzestrzeń "poniżej" ukośnego cięcia: y + z < c + D/2
// (dolny kawałek ma dłuższy przód; obie powierzchnie styku są pod 45°)
module scarf_below(c, D) {
    translate([0, c, D / 2]) rotate([45, 0, 0])
        translate([-BIG / 2, -BIG, -BIG / 2]) cube(BIG);
}

module frame_piece(i) {
    intersection() {
        frame_whole();
        if (i < frame_n - 1) scarf_below(frame_cuts[i], frame_D);
        else translate([-BIG / 2, -BIG / 2, -BIG / 2]) cube(BIG);
        if (i > 0) difference() {
            translate([-BIG / 2, -BIG / 2, -BIG / 2]) cube(BIG);
            scarf_below(frame_cuts[i - 1], frame_D);
        }
    }
}

// ---------------------------------------------------------------------
// Drzwiczki
// ---------------------------------------------------------------------
module dovetails2d(c, grow) {
    n = max(1, floor((dx1 - dx0) / 45));
    for (k = [0 : n - 1]) {
        x = dx0 + (dx1 - dx0) * (k + 0.5) / n;
        offset(delta = grow)
            polygon([[x - dt_neck / 2, c - 1], [x + dt_neck / 2, c - 1],
                     [x + dt_neck / 2, c],
                     [x + dt_head / 2, c + dt_len], [x - dt_head / 2, c + dt_len],
                     [x - dt_neck / 2, c]]);
    }
}

// Obszar 2D kawałka i: dolny dostaje "ogony" w górę, górny - gniazda z luzem
module door_region2d(i) {
    lo = i > 0 ? door_cuts[i - 1] : -BIG;
    hi = i < door_n - 1 ? door_cuts[i] : BIG;
    difference() {
        union() {
            translate([-BIG / 2, lo]) square([BIG, hi - lo]);
            if (i < door_n - 1) dovetails2d(hi, 0);
        }
        if (i > 0) dovetails2d(lo, dt_clr);
    }
}

module door_whole() {
    difference() {
        chamfered_slab(dx0, dy0, dx1, dy1, door_r, door_t, chamfer);
        // Magnesy - od tyłu (na górze w druku)
        for (p = mag_pts) translate([p[0], p[1], door_t - pocket_h]) cylinder(d = pocket_d, h = pocket_h + 1);
        // Otwór na palec z fazami
        if (finger_d > 0) translate([0, dy1 - finger_off, 0]) {
            translate([0, 0, -1]) cylinder(d = finger_d, h = door_t + 2);
            translate([0, 0, -eps]) cylinder(d1 = finger_d + 2 * chamfer, d2 = finger_d, h = chamfer);
        }
        // Szczeliny wentylacyjne
        if (vents) for (k = [0 : vent_n - 1])
            translate([0, dy0 + 16 + k * (vent_w + 4), -1]) linear_extrude(door_t + 2)
                hull() for (s = [-1, 1]) translate([s * ox * 0.45, 0]) circle(d = vent_w);
    }
}

module door_piece(i) {
    intersection() {
        door_whole();
        translate([0, 0, -1]) linear_extrude(door_t + 2) door_region2d(i);
    }
}

// ---------------------------------------------------------------------
// Wyjście
// ---------------------------------------------------------------------
module spread(n, w) {
    // kawałki obok siebie (podgląd); pojedynczy kawałek - bez przesunięcia
    if (piece >= 0) children(0);
    else for (i = [0 : n - 1]) translate([i * (w + 15), 0, 0]) children(0);
}

module wall_preview() {
    color("white", 0.35) translate([0, 0, -12]) linear_extrude(12)
        difference() {
            rrect(fx0 - 60, fy0 - 40, fx1 + 60, fy1 + 40, 0);
            rrect(-hx, -hy, hx, hy, 0);
        }
}

if (part == "frame") {
    if (piece >= 0) frame_piece(piece);
    else for (i = [0 : frame_n - 1]) translate([i * (fx1 - fx0 + 15), 0, 0]) frame_piece(i);
} else if (part == "door") {
    if (piece >= 0) door_piece(piece);
    else for (i = [0 : door_n - 1]) translate([i * (dx1 - dx0 + 15), 0, 0]) door_piece(i);
} else {
    // Złożenie na ścianie: przód w stronę widza (+Z), ściana w Z = 0
    wall_preview();
    color("gainsboro") translate([0, 0, plate_t]) mirror([0, 0, 1])
        for (i = [0 : frame_n - 1]) frame_piece(i);
    color("whitesmoke") translate([0, 0, plate_t + door_t + 0.3]) mirror([0, 0, 1])
        for (i = [0 : door_n - 1]) door_piece(i);
}
