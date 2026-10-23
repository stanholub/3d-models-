// =====================================================================
//  Wózek na przednie koła dla Bianki (whippet ok. 13 kg, prawa przednia
//  łapa w sztywnym opatrunku, zakaz obciążania)
//  OpenSCAD 2021.01+
//
//  Rama z rur aluminiowych Ø20 mm i złączek drukowanych z PETG (bez
//  podpór). Dwa koła po bokach przednich łap niosą przód psa przez
//  wyściełany temblak pod mostkiem. Prawa przednia łapa leży w kołysce
//  podwieszonej pod prawą rurą boczną, więc nie dotyka ziemi. Lewa
//  przednia i obie tylne łapy chodzą normalnie.
//
//  Każda część jest modelowana w orientacji do druku (Z = góra, Z = 0
//  to stół). Złożenie przenosi części macierzami do układu psa:
//  X = do przodu, Y = w lewo, Z = w górę, Z = 0 to ziemia,
//  X = 0 to linia popręgu (tuż za łokciami), Y = 0 to oś psa.
// =====================================================================

/* [Wybór części] */
// Co wygenerować. Pojedyncze części są już ustawione do druku.
part = "assembly"; // [assembly, frame, elbow, tee, axle_mount, anchor, end_cap, cast_cradle, plate]
// Sylwetka psa w złożeniu (tylko podgląd)
show_dog = true;

/* [Bianka - ZMIERZ] */
// Wysokość w kłębie (mm)
h_withers = 460;
// Wysokość spodu klatki piersiowej nad ziemią: mostek na wysokości łokci (mm)
h_sternum = 250;
// Szerokość klatki w najszerszym miejscu, tuż za łokciami (mm)
w_chest = 160;
// Długość klatki: od przedpiersia do linii popręgu za łokciami, poziomo (mm)
l_chest = 170;

/* [Opatrunek - ZMIERZ] */
// Największa średnica opatrunku (mm)
cast_d = 60;
// Długość kołyski: odcinek opatrunku, który ma w niej leżeć (mm)
cast_len = 150;
// Grubość wyściółki w kołysce: pianka + polar (mm)
pad_t = 6;

/* [Koła] */
// Średnica kół: hulajnogowe 200 mm z łożyskami 608
wheel_d = 200;
// Szerokość koła (mm)
wheel_w = 30;

/* [Rama] */
// Rura aluminiowa: średnica zewnętrzna (mm)
tube_d = 20;
// Luz między bokiem klatki a rurą boczną (mm)
side_clr = 35;
// Luz między kłębem a poprzeczką: szelki + zapas (mm)
top_clr = 45;
// Wysokość rur bocznych nad mostkiem (mm)
bar_above_sternum = 70;
// O ile rury boczne wystają przed klatkę (mm)
nose = 60;
// Oś kół: odległość od linii popręgu do przodu; -1 = auto (0,55 × l_chest)
axle_x = -1;
// Przesunięcie goleni z kołem na zewnątrz od rury bocznej (mm)
strut_off = 28;

/* [Pasowanie i druk] */
// Luz średnicy gniazd na rurę (mm)
fit = 0.4;
// Luz średnicy zaślepki (ciasno, mm)
cap_fit = 0.2;
// Ścianka złączek (mm)
wall = 4;
// Głębokość gniazd na rurę (mm)
sock = 32;
// Otwory na śruby M5 (mm)
bolt_d = 5.4;
// Otwór na oś M8 (mm)
axle_hole = 8.4;
// Gniazdo nakrętki M8: rozmiar pod klucz + luz (mm)
nut8_af = 13.4;

$fn = 64;

// ---------------------------------------------------------------------
//  Wymiary pochodne
// ---------------------------------------------------------------------
r_t = (tube_d + fit) / 2;   // otwór na rurę
r_o = r_t + wall;           // obrys złączki
s_e = r_t + 1;              // dno gniazda kolanka od narożnika
arm = s_e + sock;           // długość ramienia kolanka od narożnika
td_cap = r_t + 1.2;         // ścięcie "kropli" w poziomych gniazdach

y_bar = w_chest / 2 + side_clr + tube_d / 2;    // oś rury bocznej
z_bar = h_sternum + bar_above_sternum;
z_top = h_withers + top_clr + tube_d / 2;       // oś poprzeczki
x_front = l_chest + nose;                       // koniec rury bocznej
ax_x = axle_x < 0 ? 0.55 * l_chest : axle_x;
z_axle = wheel_d / 2;

tee_h = 40;         // długość tulei zacisku T (wzdłuż rury bocznej)
ear_len = 14;       // ucha zacisku
an_h = 35;          // obejma taśmy: wysokość wzdłuż rury
an_slot = [5, 27];  // szczelina na taśmę 25 mm (mieści dwie taśmy)
an_bar = 6;         // zewnętrzna belka ucha obejmy
cap_sock = 20;
cap_end = 3;

ax_rb = 15;                  // promień piasty osi
ax_ext = 10;                 // wysunięcie piasty na zewnątrz goleni
ax_stop = 12;                // dno gniazda goleni nad osią koła
ax_top = ax_stop + sock;
ax_h = 2 * r_o + ax_ext;     // grubość piasty wzdłuż osi koła
y_strut = y_bar + strut_off;
y_outer = y_strut + r_o + ax_ext;
washer_t = 2;
y_wheel = y_outer + washer_t + wheel_w / 2;

cr_ri = cast_d / 2 + pad_t;  // kołyska: promień wewnętrzny
cr_ro = cr_ri + 3;
cr_wrap = 0.25 * cr_ri;      // ile brzeg wychodzi ponad środek opatrunku
cr_len = cast_len;
cr_groove = 27;              // rowki na rzepy 25 mm

x_an_front = x_front - cap_sock - an_h / 2 - 3;   // obejma z przodu rury bocznej
z_an_up = z_bar + arm + an_h / 2 + 3;             // obejma na pionowej rurze

// długości cięcia rur (od dna do dna gniazd)
len_side = x_front - s_e;
len_upright = (z_top - s_e) - (z_bar + s_e);
len_cross = 2 * (y_bar - s_e);
len_strut = z_bar - (z_axle + ax_stop);
len_total = 2 * len_side + 2 * len_upright + len_cross + 2 * len_strut;

echo(str("RURY Ø", tube_d, ": boczne 2 × ", round(len_side), " mm, pionowe 2 × ",
         round(len_upright), " mm, poprzeczka 1 × ", round(len_cross),
         " mm, golenie 2 × ", round(len_strut), " mm, razem ", round(len_total), " mm"));
echo(str("Rozstaw kół (środki): ", round(2 * y_wheel), " mm, oś kół ", round(ax_x),
         " mm przed linią popręgu, prześwit pod piastą ", round(z_axle - ax_rb), " mm"));
echo(str("Śruba osi: M8 × ", ceil((washer_t + wheel_w + washer_t + ax_h + 3) / 5) * 5, " mm"));

// ---------------------------------------------------------------------
//  Pomocnicze
// ---------------------------------------------------------------------
// Otwór w kształcie kropli: szpic w +Y (po obrocie w górę stołu),
// opcjonalnie ścięty na wysokości cap (płaski most zamiast szpica).
module teardrop2d(d, cap = -1) {
    r = d / 2;
    h = cap < 0 ? r * sqrt(2) : min(cap, r * sqrt(2));
    intersection() {
        union() {
            circle(r = r);
            polygon([[-r / sqrt(2), r / sqrt(2)], [r / sqrt(2), r / sqrt(2)], [0, r * sqrt(2)]]);
        }
        translate([-r - 1, -r - 1]) square([2 * r + 2, r + 1 + h]);
    }
}

// poziomy otwór wzdłuż X (od x0 do x1), szpic kropli w górę
module bore_x(d, x0, x1, y, z, cap = -1) {
    translate([x0, y, z]) rotate([90, 0, 90]) linear_extrude(x1 - x0) teardrop2d(d, cap);
}

// poziomy otwór wzdłuż Y (od y0 do y1), szpic kropli w górę
module bore_y(d, y0, y1, x, z, cap = -1) {
    translate([x, y1, z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) teardrop2d(d, cap);
}

module chamf_sq(w, h, c) {
    offset(delta = c, chamfer = true) square([w - 2 * c, h - 2 * c], center = true);
}

// pręt między dwoma punktami (do podglądu)
module rod(p0, p1, d) {
    v = p1 - p0;
    L = norm(v);
    translate(p0) rotate([0, acos(v[2] / L), atan2(v[1], v[0])]) cylinder(d = d, h = L, $fn = 32);
}

// Przeniesienie części z układu druku do układu psa:
// punkt druku p trafia w at + [c1 c2 c3] * (p - from)
module place(c1, c2, c3, at, from = [0, 0, 0]) {
    multmatrix([[c1[0], c2[0], c3[0], at[0]],
                [c1[1], c2[1], c3[1], at[1]],
                [c1[2], c2[2], c3[2], at[2]],
                [0, 0, 0, 1]])
        translate(-from) children();
}

// ---------------------------------------------------------------------
//  Kolanko 90° (×4): leży płasko, ramię A wzdłuż +X, ramię B wzdłuż +Y.
//  Śruby M5 przechodzą w płaszczyźnie kolanka, więc w ramie żadna nie
//  celuje w psa.
// ---------------------------------------------------------------------
module elbow() {
    difference() {
        union() {
            translate([-r_o, 0, r_o]) rotate([90, 0, 90])
                linear_extrude(arm + r_o) chamf_sq(2 * r_o, 2 * r_o, 2);
            translate([0, arm, r_o]) rotate([90, 0, 0])
                linear_extrude(arm + r_o) chamf_sq(2 * r_o, 2 * r_o, 2);
        }
        bore_x(tube_d + fit, s_e, arm + 1, 0, r_o, td_cap);
        bore_y(tube_d + fit, s_e, arm + 1, 0, r_o, td_cap);
        bore_y(bolt_d, -r_o - 1, r_o + 1, s_e + sock / 2, r_o);
        bore_x(bolt_d, -r_o - 1, r_o + 1, s_e + sock / 2, r_o);
    }
}

// ---------------------------------------------------------------------
//  Zacisk rozprężny: ucha z nacięciem i śrubą M5 (w zacisku T i obejmie)
// ---------------------------------------------------------------------
module pinch_ears(h) {
    translate([-(r_o + ear_len), -9, 0]) cube([ear_len + 3, 18, h]);
}

module pinch_cuts(h) {
    translate([-(r_o + ear_len + 1), -1, -1]) cube([r_o + ear_len + 1, 2, h + 2]);
    bore_y(bolt_d, -10, 10, -(r_o + ear_len / 2), h / 2);
}

// ---------------------------------------------------------------------
//  Zacisk T (×2): tuleja przesuwna na rurze bocznej + gniazdo goleni koła.
//  Tuleja stoi pionowo w druku, gniazdo goleni leży poziomo wzdłuż +X,
//  odsunięte o strut_off w +Y (w ramie: na zewnątrz).
// ---------------------------------------------------------------------
module tee() {
    difference() {
        union() {
            hull() {
                cylinder(r = r_o, h = tee_h);
                translate([0, strut_off - r_o, 0]) cube([1, 2 * r_o, tee_h]);
            }
            translate([0, strut_off - r_o, 0]) cube([sock, 2 * r_o, tee_h]);
            pinch_ears(tee_h);
        }
        translate([0, 0, -1]) cylinder(r = r_t, h = tee_h + 2);
        pinch_cuts(tee_h);
        bore_x(tube_d + fit, 0, sock + 1, strut_off, tee_h / 2, td_cap);
        bore_y(bolt_d, strut_off - r_o - 1, strut_off + r_o + 1, sock / 2, tee_h / 2);
    }
}

// ---------------------------------------------------------------------
//  Piasta osi (×2): zewnętrzna ściana leży na stole, oś M8 pionowo,
//  gniazdo goleni poziomo wzdłuż +Y. Na wierzchu gniazdo nakrętki M8.
// ---------------------------------------------------------------------
module axle_mount() {
    difference() {
        linear_extrude(ax_h) hull() {
            circle(r = ax_rb);
            translate([-r_o, 0]) square([2 * r_o, ax_top]);
        }
        translate([0, 0, -1]) cylinder(d = axle_hole, h = ax_h + 2);
        translate([0, 0, ax_h - 7]) rotate([0, 0, 30])
            cylinder(d = nut8_af / cos(30), h = 8, $fn = 6);
        bore_y(tube_d + fit, ax_stop, ax_top + 1, 0, ax_ext + r_o, td_cap);
        bore_x(bolt_d, -r_o - 1, r_o + 1, ax_stop + sock / 2, ax_ext + r_o);
    }
}

// ---------------------------------------------------------------------
//  Obejma z uchem na taśmę (×4): pierścień przesuwny z zaciskiem M5.
//  Szczelina 5 × 27 mm mieści dwie taśmy 25 mm.
// ---------------------------------------------------------------------
module anchor() {
    ear_x1 = r_o + 2 + an_slot[0] + an_bar;
    difference() {
        union() {
            cylinder(r = r_o, h = an_h);
            translate([r_o - 3, -5, 0]) cube([ear_x1 - r_o + 3, 10, an_h]);
            pinch_ears(an_h);
        }
        translate([0, 0, -1]) cylinder(r = r_t, h = an_h + 2);
        pinch_cuts(an_h);
        translate([r_o + 2, -6, (an_h - an_slot[1]) / 2]) cube([an_slot[0], 12, an_slot[1]]);
    }
}

// ---------------------------------------------------------------------
//  Zaślepka końca rury (×2): zamyka ostre krawędzie z przodu
// ---------------------------------------------------------------------
module end_cap() {
    difference() {
        union() {
            cylinder(r1 = r_o - 1.5, r2 = r_o, h = 1.5);
            translate([0, 0, 1.5]) cylinder(r = r_o, h = cap_end + cap_sock - 1.5);
        }
        translate([0, 0, cap_end]) cylinder(d = tube_d + cap_fit, h = cap_sock + 1);
        translate([0, 0, cap_end + cap_sock - 1]) cylinder(d1 = tube_d + cap_fit, d2 = tube_d + cap_fit + 2.5, h = 1.01);
    }
}

// ---------------------------------------------------------------------
//  Kołyska na opatrunek (×1): rynna otwarta do góry, płaski spód z
//  fazami 45°, rowki na dwa rzepy, rozchylone końce (nie wpijają się
//  w łapę ponad opatrunkiem).
// ---------------------------------------------------------------------
module cradle_outer2d() {
    intersection() {
        hull() {
            translate([0, cr_ro]) circle(r = cr_ro, $fn = 96);
            translate([-cr_ro * tan(22.5) - 1, 0]) square([2 * cr_ro * tan(22.5) + 2, 0.01]);
        }
        translate([-cr_ro - 1, 0]) square([2 * cr_ro + 2, cr_ro + cr_wrap]);
    }
}

module cast_cradle() {
    difference() {
        rotate([90, 0, 90]) linear_extrude(cr_len) difference() {
            cradle_outer2d();
            translate([0, cr_ro]) circle(r = cr_ri, $fn = 96);
        }
        // rowki na rzepy
        for (xg = [cr_groove / 2 + 8, cr_len - cr_groove / 2 - 8])
            translate([xg - cr_groove / 2, 0, 0]) rotate([90, 0, 90])
                linear_extrude(cr_groove) intersection() {
                    difference() {
                        cradle_outer2d();
                        offset(delta = -1.5) cradle_outer2d();
                    }
                    translate([-cr_ro - 1, 2]) square([2 * cr_ro + 2, cr_ro + cr_wrap - 5]);
                }
        // rozchylenie końców
        translate([-0.01, 0, cr_ro]) rotate([0, 90, 0]) cylinder(r1 = cr_ri + 3, r2 = cr_ri, h = 3, $fn = 96);
        translate([cr_len + 0.01, 0, cr_ro]) rotate([0, -90, 0]) cylinder(r1 = cr_ri + 3, r2 = cr_ri, h = 3, $fn = 96);
    }
}

// ---------------------------------------------------------------------
//  Złożenie (podgląd)
// ---------------------------------------------------------------------
c_tube = [0.72, 0.74, 0.78];
c_part = [0.16, 0.55, 0.68];
c_wheel = [0.18, 0.18, 0.2];
c_strap = [0.2, 0.2, 0.24];
c_pad = [0.35, 0.36, 0.42];
c_dog = [0.87, 0.74, 0.58];
c_cast = [0.86, 0.2, 0.52];

// ucho obejmy skierowane w dół i do środka (rura boczna)
module anchor_on_side(x) {
    s = sqrt(0.5);
    place([0, -s, -s], [0, s, -s], [1, 0, 0], [x, y_bar, z_bar], [0, 0, an_h / 2]) anchor();
}

// ucho obejmy skierowane do przodu (rura pionowa)
module anchor_on_upright(z) {
    place([1, 0, 0], [0, 1, 0], [0, 0, 1], [0, y_bar, z], [0, 0, an_h / 2]) anchor();
}

module wheel() {
    color(c_wheel) translate([ax_x, y_wheel, z_axle]) rotate([90, 0, 0]) difference() {
        cylinder(d = wheel_d, h = wheel_w, center = true, $fn = 96);
        cylinder(d = wheel_d - 60, h = wheel_w - 10, center = true, $fn = 96);
    }
    color([0.85, 0.85, 0.85]) translate([ax_x, y_wheel, z_axle]) rotate([90, 0, 0])
        cylinder(d = 40, h = wheel_w, center = true);
    color([0.6, 0.6, 0.62]) rod([ax_x, y_outer - ax_h - 3, z_axle], [ax_x, y_wheel + wheel_w / 2 + 4, z_axle], 8);
}

module half_frame() {
    color(c_tube) {
        rod([s_e, y_bar, z_bar], [x_front, y_bar, z_bar], tube_d);
        rod([0, y_bar, z_bar + s_e], [0, y_bar, z_top - s_e], tube_d);
        rod([0, 0, z_top], [0, y_bar - s_e, z_top], tube_d);
        rod([ax_x, y_strut, z_bar], [ax_x, y_strut, z_axle + ax_stop], tube_d);
    }
    color(c_part) {
        place([1, 0, 0], [0, 0, 1], [0, -1, 0], [0, y_bar, z_bar], [0, 0, r_o]) elbow();
        place([0, -1, 0], [0, 0, -1], [1, 0, 0], [0, y_bar, z_top], [0, 0, r_o]) elbow();
        place([0, 0, -1], [0, 1, 0], [1, 0, 0], [ax_x, y_bar, z_bar], [0, 0, tee_h / 2]) tee();
        place([1, 0, 0], [0, 0, 1], [0, -1, 0], [ax_x, y_outer, z_axle]) axle_mount();
        place([0, 0, 1], [0, 1, 0], [-1, 0, 0], [x_front, y_bar, z_bar], [0, 0, cap_end]) end_cap();
        anchor_on_side(x_an_front);
        anchor_on_upright(z_an_up);
    }
    wheel();
}

// pasek taśmy między punktami; w = szerokość taśmy wzdłuż osi "ax"
module strap(pts, ax = [1, 0, 0], w = 25, t = 2.5) {
    sz = [ax[0] * w + t, ax[1] * w + t, ax[2] * w + t];
    color(c_strap) for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) cube(sz, center = true);
        translate(pts[i + 1]) cube(sz, center = true);
    }
}

D_chest = h_withers - h_sternum;
z_chest = h_sternum + D_chest / 2;
chest_c = [0.3 * l_chest, 0, z_chest];
chest_r = [0.85 * l_chest, w_chest / 2, D_chest / 2 - 5];

// prawa przednia łapa: przedramię w dół i do przodu pod kątem 20°
elbow_r = [25, -48, h_sternum + 5];
fa_dir = [cos(20), 0, -sin(20)];
cast_s0 = 40;                 // początek opatrunku od łokcia
cradle_s0 = cast_s0 + 8;      // początek kołyski

module leg(pts, rs) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) sphere(r = rs[i], $fn = 24);
        translate(pts[i + 1]) sphere(r = rs[i + 1], $fn = 24);
    }
}

module dog() {
    color(c_dog) {
        translate(chest_c) scale(chest_r) sphere(1, $fn = 48);
        hull() {
            translate([-50, 0, z_chest + 25]) scale([60, w_chest * 0.42, D_chest * 0.36]) sphere(1, $fn = 32);
            translate([-215, 0, h_withers - 55]) scale([55, w_chest * 0.36, D_chest * 0.24]) sphere(1, $fn = 32);
        }
        translate([-265, 0, h_withers - 75]) scale([75, w_chest * 0.42, 80]) sphere(1, $fn = 32);
        hull() {
            translate([l_chest * 0.8, 0, h_withers - 50]) sphere(r = 48, $fn = 32);
            translate([l_chest + 110, 0, h_withers + 110]) sphere(r = 30, $fn = 32);
        }
        hull() {
            translate([l_chest + 125, 0, h_withers + 125]) sphere(r = 40, $fn = 32);
            translate([l_chest + 285, 0, h_withers + 80]) sphere(r = 15, $fn = 24);
        }
        // uszy "różyczki" złożone do tyłu
        for (s = [-1, 1]) translate([l_chest + 85, s * 34, h_withers + 150]) rotate([s * 20, -25, 0])
            scale([42, 10, 20]) sphere(1, $fn = 24);
        // lewa przednia
        leg([[l_chest - 40, 52, z_chest + 30], [25, 48, h_sternum + 5], [32, 46, 45], [48, 46, 12]],
            [30, 20, 12, 13]);
        // tylne
        for (s = [-1, 1])
            leg([[-275, s * 52, h_withers - 95], [-215, s * 56, 230], [-305, s * 48, 108], [-292, s * 46, 12]],
                [42, 22, 13, 13]);
        // ogon
        leg([[-330, 0, h_withers - 65], [-362, 0, 320], [-358, 0, 215], [-332, 0, 160]], [10, 7, 5, 4]);
        // prawa przednia: ramię i przedramię do opatrunku
        leg([[l_chest - 40, -52, z_chest + 30], elbow_r, elbow_r + fa_dir * cast_s0], [30, 20, 17]);
    }
    // opatrunek
    color(c_cast) hull() {
        translate(elbow_r + fa_dir * cast_s0) sphere(d = cast_d * 0.85, $fn = 32);
        translate(elbow_r + fa_dir * (cast_s0 + cast_len + 15)) sphere(d = cast_d, $fn = 32);
    }
    // szelki (pas za łokciami)
    color([0.75, 0.15, 0.15]) intersection() {
        difference() {
            translate(chest_c) scale(chest_r + [6, 6, 6]) sphere(1, $fn = 48);
            translate(chest_c) scale(chest_r) sphere(1, $fn = 48);
        }
        translate([-30, -200, 0]) cube([28, 400, 1000]);
    }
}

// temblak pod mostkiem
module sling() {
    color(c_pad) intersection() {
        difference() {
            translate(chest_c) scale(chest_r + [10, 10, 10]) sphere(1, $fn = 48);
            translate(chest_c) scale(chest_r + [3, 3, 3]) sphere(1, $fn = 48);
        }
        translate([-15, -200, 0]) cube([l_chest - 5, 400, h_sternum + 45]);
    }
}

module cradle_in_place() {
    p = elbow_r + fa_dir * cradle_s0;
    // oś kołyski wzdłuż przedramienia, środek opatrunku nad dnem o cr_ro
    color(c_part) place(fa_dir, [0, 1, 0], cross(fa_dir, [0, 1, 0]), p, [0, 0, cr_ro]) cast_cradle();
}

module assembly(with_dog = true) {
    half_frame();
    mirror([0, 1, 0]) half_frame();

    // temblak i jego taśmy
    sling();
    for (s = [-1, 1]) {
        strap([[x_an_front, s * (y_bar - 22), z_bar - 22], [l_chest - 30, s * 58, h_sternum + 40]]);
        strap([[r_o + 10, s * y_bar, z_an_up - 10], [5, s * 62, h_sternum + 45]]);
    }
    // pas piersiowy przed klatką (szerokość taśmy pionowo)
    strap([[x_an_front + 8, y_bar - 22, z_bar - 18], [l_chest + 30, 40, z_bar], [l_chest + 30, -40, z_bar],
           [x_an_front + 8, -(y_bar - 22), z_bar - 18]], [0, 0, 1]);
    // łącznik poprzeczki z szelkami
    strap([[0, 0, z_top - 8], [-14, 0, h_withers + 6]], [0, 1, 0]);

    // kołyska z opatrunkiem i jej podwieszenie
    cradle_in_place();
    pc0 = elbow_r + fa_dir * (cradle_s0 + cr_groove / 2 + 8);
    pc1 = elbow_r + fa_dir * (cradle_s0 + cr_len - cr_groove / 2 - 8);
    // oba paski kołyski owinięte rzepem wokół prawej rury bocznej, przed i za zaciskiem T
    strap([pc1 + [0, 0, cast_d / 2 + 4], [ax_x + tee_h / 2 + 30, -y_bar + 8, z_bar - 8]]);
    strap([pc0 + [0, 0, cast_d / 2 + 4], [(arm + ax_x - tee_h / 2) / 2, -y_bar + 8, z_bar - 8]]);
    color(c_strap) for (x = [ax_x + tee_h / 2 + 30, (arm + ax_x - tee_h / 2) / 2])
        translate([x, -y_bar, z_bar]) rotate([0, 90, 0]) difference() {
            cylinder(r = tube_d / 2 + 3, h = 25, center = true, $fn = 32);
            cylinder(r = tube_d / 2 + 0.5, h = 26, center = true, $fn = 32);
        }
    color(c_strap) for (pc = [pc0, pc1]) translate(pc) rotate([0, 20, 0]) rotate([0, 90, 0])
        difference() {
            cylinder(r = cr_ro + 3, h = 25, center = true, $fn = 48);
            cylinder(r = cr_ro + 0.5, h = 26, center = true, $fn = 48);
        }

    if (with_dog) dog();
}

// ---------------------------------------------------------------------
//  Płyta druku: po jednej sztuce każdej części (liczba sztuk w README)
// ---------------------------------------------------------------------
module plate() {
    color(c_part) {
        translate([20, 160, 0]) elbow();
        translate([108, 160, 0]) tee();
        translate([170, 160, 0]) axle_mount();
        translate([222, 175, 0]) end_cap();
        translate([35, 115, 0]) anchor();
        translate([92, 85, 0]) cast_cradle();
    }
    color([0.9, 0.9, 0.9]) translate([0, 0, -1]) cube([256, 256, 1]);
}

// ---------------------------------------------------------------------
if (part == "assembly") assembly(show_dog);
else if (part == "frame") assembly(false);
else if (part == "elbow") elbow();
else if (part == "tee") tee();
else if (part == "axle_mount") axle_mount();
else if (part == "anchor") anchor();
else if (part == "end_cap") end_cap();
else if (part == "cast_cradle") cast_cradle();
else if (part == "plate") plate();
