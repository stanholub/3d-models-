// =====================================================================
//  Uchwyt Insta360 GO Ultra dla psa - v2 (druk FDM bez podpór)
//  OpenSCAD 2021.01+
//
//  Dwie części połączone standardowym złączem GoPro (śruba M5):
//    * kieszeń na kamerę z 2 palcami - drukowana na plecach,
//    * baza na taśmę szelek/obroży z 3 palcami - drukowana spodem do stołu.
//  Każda część leży na stole płaską powierzchnią, a wszystkie nawisy
//  mają co najmniej 45° albo są krótkimi mostami (< 5 mm), więc obie
//  drukują się bez podpór.
//
//  Taśma przeplatana jest przez dwie pionowe szczeliny bazy (jak w
//  klamrze plecaka): po wierzchu skrzydła, w dół przez szczelinę, pod
//  środkiem bazy, w górę przez drugą szczelinę. Naprzemienne prowadzenie
//  blokuje przesuwanie bez śrub i kleju.
//
//  Układ współrzędnych bazy: X = wzdłuż taśmy, Z = góra, Z = 0 to stół.
// =====================================================================

/* [Wybór części] */
// Co wygenerować. "cradle" i "base" są już ustawione do druku.
part = "assembly"; // [cradle, base, assembly, print_plate]
// "across" = taśma w poprzek grzbietu (pas za łopatkami, obroża); "along" = taśma wzdłuż kręgosłupa (szelki typu H)
strap_dir = "across"; // [across, along]
// "harness" = baza z długimi skrzydłami (stabilna na grzbiecie); "collar" = krótsza baza na obrożę
preset = "harness"; // [harness, collar]

/* [Taśma - ZMIERZ!] */
// Szerokość taśmy (mm)
strap_w = 25;
// Grubość taśmy (mm)
strap_t = 3.5;

/* [Złożenie (tylko podgląd)] */
// Pochylenie kamery w górę na podglądzie; w rzeczywistości ustawiasz je na śrubie
tilt = 10; // [-30:1:30]

/* [Wymiary Insta360 GO Ultra - zweryfikuj suwmiarką] */
cam_w = 46.0;
cam_h = 45.7;
cam_d = 18.3;
// Promień narożników korpusu w widoku z przodu. Mniejszy = bezpieczniej
cam_r = 6;
// Luz na stronę między kamerą a kieszenią
clr = 0.35;

/* [Kieszeń] */
wall = 2.2;        // ścianki boczne
back_t = 2.6;      // tylna ścianka (leży na stole)
lip = 2.2;         // ile wargi zachodzą na przód kamery
lip_t = 1.6;       // grubość wargi
lip_gusset = 1.2;  // podparcie 45° pod wargą (skraca nawis do lip - lip_gusset)
hook_d = 2.2;      // ile zaczep zachodzi nad górną krawędź kamery
tab_w = 18;        // szerokość sprężystego języczka
slit_len = 22;     // długość nacięć języczka (dłuższe = miększy zatrzask)
slit_w = 1.2;
notch_len = 14;    // wycięcia na palce w górnej części boków (od frontu)

/* [Podkładka stalowa pod magnes kamery] */
washer = true;
washer_d = 16;     // M8 DIN 125: 16 x 1.6 mm
washer_t = 1.6;
washer_y = -10;

/* [Złącze GoPro] */
fin_t = 3.0;       // grubość palca
fin_gap = 3.3;     // szczelina między palcami
fin_r = 7.5;       // promień zakończenia palca
hole_d = 5.4;      // otwór na M5
pivot_h = 9;       // oś śruby nad wierzchem bazy
cradle_gap = 8.5;  // oś śruby pod spodem kieszeni
nut_af = 8.2;      // nakrętka M5: rozmiar pod klucz 8 mm + luz
nut_h = 5;         // głębokość gniazda (nakrętka zwykła 4 mm lub nyloc 5 mm)
boss = 5.5;        // pogrubienie zewnętrznego palca z gniazdem nakrętki

/* [Baza] */
base_t = 4;        // grubość płytki
edge_c = 1.0;      // fazowanie krawędzi 45° (góra i dół)
slot_clr = 1.0;    // luz szczeliny na grubość taśmy
slot_c = 0.8;      // fazowanie krawędzi szczelin (taśma nie przeciera się)
// Długość skrzydeł za szczelinami (mm), -1 = automatycznie (harness 9, collar 6)
wing = -1;
// Wymiar bazy w poprzek taśmy (mm), -1 = automatycznie
base_ly = -1;

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---------------------------------------------------------------------
// Wartości pochodne
// ---------------------------------------------------------------------
collar = preset == "collar";
along = strap_dir == "along";

cw = cam_w + 2 * clr;
ch = cam_h + 2 * clr;
cd = cam_d + 2 * clr;
cr = cam_r + clr;
ow = cw + 2 * wall;
oh = ch + 2 * wall;
o_r = cr + wall;
z_back = -cd / 2 - back_t;
z_front = cd / 2 + lip_t;

hook_y = cam_h / 2 + 0.2;
hook_top = hook_y + 0.8 + hook_d * 1.5;
tab_top = hook_top + 3.5;

// Palce: środki wzdłuż osi śruby
fin_pitch = fin_t + fin_gap;
two_x = [-fin_pitch / 2, fin_pitch / 2];         // 2 palce kieszeni
three_x = [-fin_pitch, 0, fin_pitch];            // 3 palce bazy
// Zasięg 3 palców wzdłuż osi śruby (strona nakrętki = ujemna)
fin_neg = fin_pitch + fin_t / 2 + boss;
fin_pos = fin_pitch + fin_t / 2;

// Oś obrotu kieszeni w jej układzie lokalnym (y w dół od spodu, z tuż nad stołem)
piv_y = -oh / 2 - cradle_gap;
piv_z = z_back + fin_r;

// Baza
sx_w = strap_t + slot_clr;          // szczelina wzdłuż taśmy
sy_w = strap_w + 1.2;               // szczelina w poprzek taśmy
wing_l = wing < 0 ? (collar ? 6 : 9) : wing;
// Środek bazy (między szczelinami) musi pomieścić 3 palce, łeb śruby i nakrętkę
slot_in = along ? (collar ? 10 : 14)
                : max(fin_neg + 1.5, fin_pos + 6.5);
Lx = 2 * (slot_in + sx_w + wing_l);
Ly = base_ly > 0 ? base_ly
   : (along ? max(sy_w + 8, 2 * fin_neg + 4)
            : (collar ? sy_w + 8 : 56));
base_r = 4;
piv_z_base = base_t + pivot_h;

assert(washer_y + washer_d / 2 < ch / 2 - slit_len - 1,
       "Podkładka koliduje z nacięciami języczka");
assert(Ly >= sy_w + 6, "Baza za wąska na taśmę");
assert(lip_gusset < lip, "Podparcie wargi musi być mniejsze niż warga");

// ---------------------------------------------------------------------
// Pomocnicze
// ---------------------------------------------------------------------
module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

// Otwór w kształcie kropli: oś pozioma w druku, szpic w górę (+v)
module teardrop2d(d) {
    circle(d = d);
    rotate(45) square(d / 2);
}

// Profil 2D (u, v) wyciągany wzdłuż osi X: u -> Y, v -> Z
module extrude_x(x0, x1) {
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children();
}

// Prostopadłościan z fazowanymi (45°) krawędziami góra/dół, druk bez nawisów
module chamfer_box(L, W, H, c, r) {
    hull() {
        linear_extrude(eps) rrect(L - 2 * c, W - 2 * c, r - c);
        translate([0, 0, c]) linear_extrude(H - 2 * c) rrect(L, W, r);
        translate([0, 0, H - eps]) linear_extrude(eps) rrect(L - 2 * c, W - 2 * c, r - c);
    }
}

// ---------------------------------------------------------------------
// Kieszeń (układ lokalny: x szerokość, y góra/wsuwanie, z przód).
// Druk: tylną ścianką do stołu, czyli dokładnie w tym układzie.
// ---------------------------------------------------------------------
module slide2d(inset) {
    hull() {
        rrect(cw - 2 * inset, ch - 2 * inset, cr - inset);
        translate([0, oh + 10]) rrect(cw - 2 * inset, ch - 2 * inset, cr - inset);
    }
}

module front_opening_2d() {
    hull() {
        rrect(cw - 2 * lip, ch - 2 * lip, max(cr - lip, 0.5));
        translate([0, oh + 10]) rrect(cw - 2 * lip, ch - 2 * lip, max(cr - lip, 0.5));
    }
}

module cradle_body() {
    translate([0, 0, z_back]) linear_extrude(z_front - z_back) rrect(ow, oh, o_r);
}

module cradle_cuts() {
    // gniazdo + kanał wsuwania; pod wargami skos 45° zamiast poziomego nawisu
    hull() {
        translate([0, 0, -cd / 2]) linear_extrude(cd - lip_gusset) slide2d(0);
        translate([0, 0, cd / 2 - eps]) linear_extrude(eps) slide2d(lip_gusset);
    }
    // okno z przodu, wargi fazowane na zewnątrz (mniejsze winietowanie przy 155°)
    hull() {
        translate([0, 0, cd / 2 - eps]) linear_extrude(0.4 + eps) front_opening_2d();
        translate([0, 0, z_front]) linear_extrude(1) offset(delta = lip_t) front_opening_2d();
    }
    // wycięcia na palce: górna część boków ścięta od frontu do połowy głębokości
    // (otwarte od góry w druku, więc bez nawisu)
    nr = 3;
    for (sx = [-1, 1])
        extrude_x(sx > 0 ? cw / 2 - lip - 0.1 : -ow / 2 - 1,
                  sx > 0 ? ow / 2 + 1 : -(cw / 2 - lip - 0.1))
                hull() {
                    translate([ch / 2 - notch_len + nr, nr]) circle(r = nr);
                    translate([ch / 2 - notch_len + nr, 0]) square([oh, oh]);
                    translate([ch / 2 - notch_len, nr]) square([oh, oh]);
                }
    // nacięcia uwalniające sprężysty języczek
    for (sx = [-1, 1]) translate([sx * (tab_w / 2 + slit_w / 2), 0, 0]) {
        translate([-slit_w / 2, ch / 2 - slit_len, z_back - 1])
            cube([slit_w, oh, back_t + 1 + eps]);
        translate([0, ch / 2 - slit_len, z_back - 1])
            cylinder(d = slit_w * 1.6, h = back_t + 1 + eps, $fn = 16);
    }
    // gniazdo na podkładkę stalową (otwarte do góry w druku)
    if (washer)
        translate([0, washer_y, -cd / 2 - washer_t])
            cylinder(d = washer_d + 0.4, h = washer_t + eps);
}

module cradle_adds() {
    // przedłużenie języczka za kieszeń (leży na stole)
    translate([-tab_w / 2, ch / 2 - 0.5, z_back]) cube([tab_w, tab_top - ch / 2 + 0.5, back_t]);
    // zaczep: płaski spód trzyma kamerę, skos sam odgina języczek przy wsuwaniu
    hw = tab_w - 1;
    extrude_x(-hw / 2, hw / 2) polygon([
        [hook_y, -cd / 2 - 0.5],
        [hook_y, -cd / 2 + hook_d],
        [hook_y + 0.8, -cd / 2 + hook_d],
        [hook_top, -cd / 2],
        [hook_top, -cd / 2 - 0.5]
    ]);
    // grzbiet pod kciuk na końcu języczka: pchnij do tyłu, żeby zwolnić kamerę
    extrude_x(-hw / 2, hw / 2) polygon([
        [tab_top - 2.6, -cd / 2 - 0.5],
        [tab_top - 2.0, -cd / 2 + 1.6],
        [tab_top - 0.6, -cd / 2 + 1.6],
        [tab_top, -cd / 2 - 0.5]
    ]);
    // 2 palce GoPro pod spodem; płaski dół na stole, szpic 45° na końcu
    for (cx = two_x)
        extrude_x(cx - fin_t / 2, cx + fin_t / 2) difference() {
            hull() {
                translate([piv_y, piv_z]) circle(r = fin_r);
                translate([-oh / 2 - 0.5, z_back]) square([wall + 0.5, 2 * fin_r]);
                translate([piv_y - 3.1, z_back]) square([eps, eps]);
            }
            translate([piv_y, piv_z]) teardrop2d(hole_d);
        }
}

module cradle() {
    difference() { cradle_body(); cradle_cuts(); }
    cradle_adds();
}

// ---------------------------------------------------------------------
// Baza (druk spodem do stołu)
// ---------------------------------------------------------------------
module three_prong() {
    difference() {
        union() {
            for (i = [0 : 2]) {
                x0 = three_x[i] - fin_t / 2 - (i == 0 ? boss : 0);
                extrude_x(x0, three_x[i] + fin_t / 2) hull() {
                    translate([0, piv_z_base]) circle(r = fin_r);
                    translate([-fin_r, base_t - 0.5]) square([2 * fin_r, pivot_h]);
                }
            }
        }
        // otwór na śrubę
        extrude_x(-fin_neg - 1, fin_pos + 1) translate([0, piv_z_base]) teardrop2d(hole_d);
        // gniazdo nakrętki z płaskim sufitem (most < 5 mm)
        extrude_x(-fin_neg - 1, -fin_neg + nut_h) translate([0, piv_z_base])
            circle(d = nut_af / cos(30), $fn = 6);
    }
}

module strap_slot() {
    translate([0, 0, -eps]) linear_extrude(base_t + 2 * eps) rrect(sx_w, sy_w, 1);
    // fazowanie wlotów z obu stron
    for (z = [[-eps, slot_c], [base_t + eps, base_t - slot_c]]) hull() {
        translate([0, 0, z[0]]) linear_extrude(eps, center = true) rrect(sx_w + 2 * slot_c, sy_w + 2 * slot_c, 1 + slot_c);
        translate([0, 0, z[1]]) linear_extrude(eps, center = true) rrect(sx_w, sy_w, 1);
    }
}

module base() {
    difference() {
        chamfer_box(Lx, Ly, base_t, edge_c, base_r);
        for (sx = [-1, 1]) translate([sx * (slot_in + sx_w / 2), 0, 0]) strap_slot();
        // szczeliny na opaskę/rzep/linkę asekuracyjną w skrzydłach przód-tył
        if (!along && !collar)
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * 8, sy * (Ly / 2 - 5), -1]) hull()
                    for (dy = [-1.6, 1.6]) translate([0, dy, 0]) cylinder(d = 2.4, h = base_t + 2, $fn = 16);
    }
    rotate([0, 0, along ? 90 : 0]) three_prong();
}

// ---------------------------------------------------------------------
// Złożenie i płyta do druku
// ---------------------------------------------------------------------
module cradle_on_base() {
    translate([0, 0, piv_z_base]) rotate([0, 0, along ? 90 : 0])
        rotate([tilt, 0, 0]) rotate([0, 0, 180]) rotate([90, 0, 0])
            translate([0, -piv_y, -piv_z]) children();
}

module cradle_print() { translate([0, 0, -z_back]) cradle(); }

if (part == "cradle") cradle_print();
else if (part == "base") base();
else if (part == "print_plate") {
    translate([-(Lx / 2 + 5), 0, 0]) base();
    translate([ow / 2 + 5, 0, 0]) cradle_print();
} else {
    color("SteelBlue") base();
    color("Orange") cradle_on_base() cradle();
}
