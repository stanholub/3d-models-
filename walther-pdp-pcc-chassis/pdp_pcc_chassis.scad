// =====================================================================
//  Chassis PCC (konwersja na karabinek) do Walther PDP Full Size 4,5"
//  v1 - druk FDM bez podpór, OpenSCAD 2021.01+
//
//  Koncepcja (jak w fabrycznych zestawach typu "20/20"):
//    * dwie połówki (lewa/prawa) skręcane śrubami M5 zaciskają się na
//      szynie Picatinny pod lufą; dwie śruby przechodzą przez rowki
//      szyny i przenoszą odrzut,
//    * zamek pistoletu zostaje odkryty od góry (celownik zostaje na
//      zamku) i cofa się w tunel za pistoletem,
//    * kolba ma pióro wchodzące między połówki (4 śruby M5),
//    * pasy wzdłuż zamka są zbrojone 4 prętami gwintowanymi M5.
//
//  Każda część leży na stole płaską powierzchnią i jest "polem
//  wysokości" (brak nawisów), więc drukuje się bez podpór.
//
//  UKŁAD WSPÓŁRZĘDNYCH (pistolet):
//    X = 0 na tylnej płaszczyźnie zamka (zamek w przednim położeniu),
//        +X w stronę wylotu lufy,
//    Z = 0 na dolnej krawędzi zamka (linia podziału zamek/szkielet),
//        +Z do góry,
//    Y = 0 w płaszczyźnie symetrii, +Y = lewa strona strzelca.
//
//  UWAGA: wymiary pistoletu są przyjęte ze specyfikacji i szacunków,
//  NIE z pomiaru egzemplarza. Zmierz swój pistolet (sekcja "ZMIERZ")
//  i wydrukuj najpierw sprawdziany (part = "rail_gauge",
//  "profile_gauge").
// =====================================================================

/* [Wybór części] */
// Co wygenerować. Części inne niż "assembly" i "pistol" są ustawione do druku.
part = "assembly"; // [assembly, chassis_L, chassis_R, stock, acc_rail, rail_gauge, profile_gauge, pistol]
// Pokaż makietę pistoletu na podglądzie złożenia
show_pistol = true;
// Położenie zamka na podglądzie: 0 = z przodu, 1 = pełny odrzut
slide_pos = 0; // [0:0.1:1]
// Rozsunięcie połówek na podglądzie (mm)
explode = 0; // [0:1:60]
// Obrót połówek chassis na stole (45 = po przekątnej stołu 256 mm)
print_rot = 45; // [0:45:90]

/* [ZMIERZ: zamek] */
// Długość zamka
slide_len = 190.5;
// Szerokość zamka (najszersze miejsce)
slide_w = 29.5;
// Wysokość zamka od dolnej krawędzi (tylko makieta)
slide_h = 27;
// Droga zamka do tyłu przy pełnym odrzucie
slide_travel = 55;
// O ile zamek wystaje do przodu poza szkielet (PDP 4,5": ok. 12,7)
dc_overhang = 12.7;

/* [ZMIERZ: szkielet i szyna] */
// Szerokość szkieletu nad szyną (osłona sprężyny)
frame_w = 31.0;
// Największa szerokość pistoletu (po dźwigniach zwalniacza zamka)
ctrl_w = 34.5;
// Od dolnej krawędzi zamka do dolnej płaszczyzny szyny Picatinny
rail_drop = 17.5;
// Długość szyny (jaskółczego ogona) licząc od czoła szkieletu
rail_len = 42;
// Od czoła szkieletu do środka pierwszego rowka szyny
slot_first = 8.5;
// Podziałka rowków (Picatinny = 10,0)
slot_pitch = 10.0;
// Którymi rowkami idą śruby ryglujące (0 = pierwszy od czoła)
lock_slots = [0, 2];
// Od tylnej płaszczyzny zamka do końca "ogona" szkieletu (beavertail)
bt_over = 10;

/* [ZMIERZ: położenia okien (X od tyłu zamka)] */
// Początek płyty na wysokości szkieletu (za nią wolne miejsce na kciuk i dźwignię zwalniacza)
win_x1 = 60;
// Okno wyrzutowe łusek: tylna krawędź
ej_x0 = 76;
// Okno wyrzutowe łusek: przednia krawędź
ej_x1 = 124;
// Wysokość prawej ścianki pod oknem wyrzutowym (nad dolną krawędzią zamka)
ej_top = 5;
// Okienko na zaczepy rozkładania (takedown)
td_window = true;
td_x0 = 103;
td_x1 = 120;
td_z0 = -11;
td_z1 = -1;
// Położenie spustu (tylko do wyliczenia długości kolby)
trig_x = 75;

/* [Luzy] */
// Luz zamka w tunelu na stronę
tun_clr = 1.75;
// Luz płyt od dźwigni i szkieletu na stronę
ctrl_clr = 1.75;
// Luz szkieletu w gnieździe na stronę
frame_clr = 0.4;
// Luz na skosach szyny (mniejszy = ciaśniej)
rail_clr = 0.15;
// Szczelina między połówkami pod szyną (docisk zacisku)
clamp_gap = 0.5;
// Luz między ogonem szkieletu a oporą tylną (do podklejenia gumą)
bt_gap = 1.5;
// Luz zamka nad podłogą tunelu i nad nosem
floor_gap = 2.5;
// Luz pióra kolby w gnieździe na stronę
tongue_clr = 0.2;

/* [Chassis] */
// Grubość pasa obok zamka
strip_t = 9;
// Górna krawędź pasów nad dolną krawędzią zamka
z_top = 17.5;
// Dolna krawędź pasów
z_s0 = 1.5;
// Dolna krawędź płyt na wysokości szkieletu (nad palcem spustowym)
z_f0 = -14;
// Wysokość bloku zacisku pod szyną
blk_h = 15;
// Dolna krawędź podłogi tunelu
z_floor0 = -14.5;
// Dolna krawędź bloku tylnego
z_rb0 = -27;
// Długość bloku tylnego (gniazdo kolby)
rb_len = 28;
// Zapas tunelu za zamkiem w pełnym odrzucie
tun_margin = 7;
// Fazka krawędzi zewnętrznych
edge_c = 1.2;

/* [Zbrojenie i śruby] */
// Średnica pręta zbrojącego (M5 gwintowany, wklejany na epoksyd)
rod_d = 5;
// Luz kanału pręta na średnicy
rod_clr = 0.6;
// Wysokości osi prętów nad dolną krawędzią zamka
rod_z = [5.6, 13.4];
// Otwór przelotowy M5
bolt_d = 5.4;
// Gniazdo łba M5 DIN 912: średnica / głębokość
head_d = 9.4;
head_h = 5.5;
// Nakrętka M5: rozmiar pod klucz + luz / głębokość gniazda
nut_af = 8.3;
nut_h = 5;
// Wysokość warstwy (do mostków nad gniazdami łbów i nakrętek)
layer = 0.2;

/* [Kolba] */
// Długość kolby: spust -> stopka (LOP)
lop = 340;
// Grubość kolby
stock_t = 24;
// Wysokość stopki
butt_h = 110;
// Szerokość ramion szkieletu kolby
stock_web = 14;

/* [Szyna akcesoryjna] */
acc_len = 44;
acc_x0 = 143;
acc_bolt_x = [150, 170];

/* [Ukryte] */
$fn = 48;
eps = 0.01;

// ---------------- wielkości pochodne ----------------
ys_in = slide_w / 2 + tun_clr;          // wewn. płaszczyzna pasów
yf_in = ctrl_w / 2 + ctrl_clr;          // wewn. płaszczyzna płyt
yo = ys_in + strip_t;                   // zewn. płaszczyzna (stół)
x_dc = slide_len - dc_overhang;         // czoło szkieletu
x_rr = x_dc - rail_len;                 // tylny koniec szyny
x_nose = slide_len;                     // przód chassis
z_rail = -rail_drop;                    // dolna płaszczyzna szyny
z_blk0 = z_rail - blk_h;                // spód bloku zacisku
z_blk1 = -1;                            // góra bloku (pod zamkiem)
x_tun = -(slide_travel + tun_margin);   // tylna ściana tunelu
x_rear = x_tun - rb_len;                // tył chassis
x_bt = -(bt_over + bt_gap);             // opora za ogonem szkieletu
x_s1 = ej_x1;                           // koniec pełnej wysokości pasa
slot_x = [for (i = [0:4]) x_dc - slot_first - i * slot_pitch];
lock_x = [for (i = lock_slots) slot_x[i]];
z_lock = z_rail + 3 - bolt_d / 2 + 0.2; // oś śrub ryglujących (w rowku)
z_clamp = z_rail - 9;                   // oś śrub zacisku
ych = (ys_in + yo) / 2;                 // oś prętów w grubości pasa
rod_x1 = ej_x0 - 4;                     // przedni koniec prętów
tongue_t = stock_t;
tng_x0 = x_tun - 4;                     // przód gniazda pióra
tng_z0 = z_rb0 + 4;
tng_z1 = z_top - 4;
x_butt = trig_x - lop;

// śruby poprzeczne [x, z]
rear_bolts = [[x_rear + 6, -6], [x_rear + 20, -6],
              [x_rear + 6, -19], [x_rear + 20, -19]];
floor_bolts = [[(x_tun + x_bt) / 2 - 2, (z_floor0 - floor_gap) / 2]];
clamp_bolts = [[x_rr + 4.7, z_clamp], [160, z_clamp],
               [x_dc + 1.7, z_clamp], [x_nose - 6, -11]];
all_bolts = concat(rear_bolts, floor_bolts, clamp_bolts,
                   [for (x = lock_x) [x, z_lock]]);

// profil szyny MIL-STD-1913
pic_w = 21.2;      // największa szerokość
pic_top = 15.67;   // szerokość płaszczyzny
pic_v = (pic_w - pic_top) / 2;  // 2,765: wysokość skosu 45°
pic_slot = 5.35;
pic_slot_d = 3.0;

// ---------------- narzędzia ----------------
// wyciągnięcie wielokąta z płaszczyzny XZ między y0 i y1
module xz(pts, y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(y1 - y0) polygon(pts);
}
// wyciągnięcie wielokąta z płaszczyzny YZ między x0 i x1
module yz(pts, x0, x1) {
    translate([x0, 0, 0]) rotate([90, 0, 90])
        linear_extrude(x1 - x0) polygon(pts);
}
module cyl_y(d, y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0]) cylinder(d = d, h = y1 - y0);
}

// Otwór poprzeczny z gniazdem od strony stołu (y = yo) i mostkami
// drukowanymi w powietrzu: warstwa ze szczeliną, warstwa z kwadratem,
// dalej okrągły otwór. hex = gniazdo nakrętki zamiast łba.
module bolt_hole(hex = false) {
    d1 = hex ? nut_af / cos(30) : head_d;
    h1 = hex ? nut_h : head_h;
    w = bolt_d + 0.3;   // mostki odrobinę szersze niż otwór
    cyl_y(bolt_d, -1, yo + 1);
    translate([0, yo - h1, 0]) rotate([-90, 0, 0])
        cylinder(d = d1, h = h1 + 1, $fn = hex ? 6 : $fn);
    intersection() {
        cyl_y(d1 - 0.2, yo - h1 - layer, yo - h1 + eps);
        translate([-w / 2, yo - h1 - layer - 1, -d1])
            cube([w, layer + 2, 2 * d1]);
    }
    translate([-w / 2, yo - h1 - 2 * layer, -w / 2])
        cube([w, layer + eps, w]);
}

// ---------------- połówka chassis (lewa, y >= 0) ----------------
// Przekrój gniazda szyny i szkieletu (do wycięcia), płaszczyzna YZ
function rail_cavity() = let (
    a = pic_top / 2 + rail_clr, b = pic_w / 2 + rail_clr,
    z0 = z_rail, r = 0.4) [
    [-1, z0 - 0.3], [a, z0 - 0.3], [a, z0],
    [b - r, z0 + pic_v - r], [b + 0.2, z0 + pic_v - r],
    [b + 0.2, z0 + pic_v + r], [b - r, z0 + pic_v + r],
    [a, z0 + 2 * pic_v], [a, z0 + 2 * pic_v + 0.6],
    [frame_w / 2 + frame_clr, z0 + 2 * pic_v + 0.6],
    [frame_w / 2 + frame_clr, 40], [-1, 40]];

// obrysy boczne (płaszczyzna XZ)
xe = x_s1 + (z_top - z_blk1);
function p_strip() = [[x_rear, z_s0 - 0.1], [x_rear, z_top], [x_s1, z_top],
    [xe, z_blk1], [xe, z_blk1 - 1], [xe - 5, z_blk1 - 1],
    [xe - 5, z_s0 - 0.1]];
function p_plate() = [[win_x1, z_s0], [win_x1, z_f0 + 4], [win_x1 + 4, z_f0],
    [x_rr - 14, z_f0], [x_rr + 4.5, z_blk0], [x_rr + 5, z_blk0],
    [x_rr + 5, z_blk1], [xe - 6, z_blk1], [xe - 6, z_s0]];
function p_wall() = [[x_rear, z_rb0], [x_rear, z_s0], [x_bt, z_s0],
    [x_bt, z_floor0 + 5], [x_bt - 5, z_floor0],
    [x_tun + (z_floor0 - z_rb0), z_floor0], [x_tun, z_rb0]];
function p_core() = [[x_rear, z_rb0], [x_rear, z_top], [x_tun, z_top],
    [x_tun, -floor_gap], [x_bt, -floor_gap], [x_bt, z_floor0 + 5],
    [x_bt - 5, z_floor0], [x_tun + (z_floor0 - z_rb0), z_floor0],
    [x_tun, z_rb0]];
function p_block() = [[x_rr, z_blk0], [x_rr, z_blk1], [x_dc + 0.5, z_blk1],
    [x_dc + 0.5, -floor_gap], [x_nose, -floor_gap], [x_nose, z_blk0 + 4],
    [x_nose - 4, z_blk0]];

module half_solid() {
    // pas obok zamka (zbrojony prętami) + zejście do bloku zacisku
    xz(p_strip(), ys_in, yo);
    // płyta na wysokości szkieletu
    xz(p_plate(), yf_in, yo);
    // ściany boczne tunelu i bloku tylnego
    xz(p_wall(), ys_in, yo);
    // blok tylny + podłoga tunelu (do płaszczyzny podziału)
    xz(p_core(), 0, ys_in + 0.1);
    // blok zacisku z gniazdem szyny + nos przed czołem szkieletu
    difference() {
        xz(p_block(), clamp_gap / 2, yo);
        yz(rail_cavity(), x_rr - 1, x_dc + 0.5);
    }
}

// Bryła ograniczająca ze schodkową fazką krawędzi od strony stołu
// (krawędzie pod palcami nie są ostre, a pierwsza warstwa jest węższa).
module outline_2d() {
    polygon(p_strip()); polygon(p_plate()); polygon(p_wall());
    polygon(p_block());
}
module envelope() {
    n = 4;
    translate([0, yo - edge_c, 0]) rotate([90, 0, 0])
        linear_extrude(yo - edge_c + 1) outline_2d();
    for (i = [1:n]) translate([0, yo - edge_c + i * edge_c / n, 0])
        rotate([90, 0, 0]) linear_extrude(edge_c / n + eps)
            offset(delta = -i * edge_c / n) outline_2d();
}

module half(right = false) {
    intersection() {
    envelope();
    difference() {
        half_solid();

        // fazka dolnej wewnętrznej krawędzi pasa (ruch dźwigni zwalniacza)
        translate([x_bt - eps, 0, 0]) rotate([90, 0, 90])
            linear_extrude(win_x1 - x_bt)
                polygon([[ys_in - 0.1, z_s0 - 0.2], [ys_in + 3.2, z_s0 - 0.2],
                         [ys_in - 0.1, z_s0 + 3.1]]);

        // kanały prętów zbrojących
        for (z = rod_z) translate([x_rear - 1, ych, z]) rotate([0, 90, 0])
            cylinder(d = rod_d + rod_clr, h = rod_x1 - x_rear + 1);

        // gniazdo pióra kolby
        translate([x_rear - 1, -1, tng_z0])
            cube([tng_x0 - x_rear + 1, tongue_t / 2 + tongue_clr + 1,
                  tng_z1 - tng_z0]);

        // śruby poprzeczne: łby po lewej, nakrętki po prawej
        for (p = all_bolts) translate([p[0], 0, p[1]]) bolt_hole(hex = right);

        // śruby szyny akcesoryjnej: pół otworu i pół gniazda nakrętki
        for (x = acc_bolt_x) translate([x, 0, 0]) {
            translate([0, 0, z_blk0 - 1]) cylinder(d = bolt_d, h = 12);
            translate([0, 0, z_blk0 + 4.5]) rotate([0, 0, 30])
                cylinder(d = nut_af / cos(30), h = 4.4, $fn = 6);
        }

        // okienko zaczepów rozkładania
        if (td_window)
            translate([td_x0, yf_in - 1, td_z0])
                cube([td_x1 - td_x0, yo, td_z1 - td_z0]);

        // prawa strona: obniżenie ścianki pod oknem wyrzutowym
        if (right)
            xz([[ej_x0, ej_top], [ej_x0, z_top - 2], [ej_x0 - 2, z_top + 1],
                [x_nose + 1, z_top + 1], [x_nose + 1, ej_top]], 0, yo + 1);
    }
    }
}

module chassis_L() { half(false); }
module chassis_R() { mirror([0, 1, 0]) half(true); }

// ---------------- kolba ----------------
module stock_2d() {
    zt = z_top; zb = z_top - butt_h;
    tri = [[x_rear - 0.3, zt], [x_butt, zt], [x_butt, zb],
           [x_butt + 16, zb], [x_rear - 0.3, z_rb0]];
    difference() {
        union() {
            offset(r = 3) offset(delta = -3) polygon(tri);
            // pióro
            translate([x_rear - 6, tng_z0 + 0.3])
                square([tng_x0 - x_rear + 6 - 0.3, tng_z1 - tng_z0 - 0.6]);
        }
        offset(r = 6) offset(delta = -6 - stock_web) polygon(tri);
    }
}
module stock() {
    c = edge_c; n = 4;
    difference() {
        rotate([90, 0, 0]) union() {
            translate([0, 0, -stock_t / 2 + c])
                linear_extrude(stock_t - 2 * c) stock_2d();
            // schodkowe fazki krawędzi (od stołu i od góry)
            for (s = [0, 1]) mirror([0, 0, s]) for (i = [1:n])
                translate([0, 0, stock_t / 2 - c + (i - 1) * c / n - eps])
                    linear_extrude(c / n + eps)
                        offset(delta = -i * c / n) stock_2d();
        }
        for (p = rear_bolts) translate([p[0], 0, p[1]])
            cyl_y(bolt_d, -stock_t, stock_t);
    }
}

// ---------------- szyna akcesoryjna (Picatinny) ----------------
// Modelowana w pozycji do druku: płaszczyzna montażowa na stole.
module acc_rail() {
    h = 9.4;
    difference() {
        rotate([90, 0, 90]) linear_extrude(acc_len) polygon([
            [-pic_top / 2, 0], [-pic_top / 2, h - 2 * pic_v],
            [-pic_w / 2, h - pic_v], [-pic_top / 2, h],
            [pic_top / 2, h], [pic_w / 2, h - pic_v],
            [pic_top / 2, h - 2 * pic_v], [pic_top / 2, 0]]);
        // rowki
        for (x = [acc_bolt_x[0] - acc_x0 - slot_pitch : slot_pitch : acc_len + 5])
            translate([x - pic_slot / 2, -pic_w, h - pic_slot_d])
                cube([pic_slot, 2 * pic_w, pic_slot_d + 1]);
        // śruby M5 w rowkach
        for (x = acc_bolt_x) translate([x - acc_x0, 0, -1]) {
            cylinder(d = bolt_d, h = h + 2);
            translate([0, 0, 1 + 3.4]) cylinder(d = head_d, h = h);
        }
    }
}

// ---------------- makieta pistoletu (tylko podgląd) ----------------
module pdp_slide() {
    ch = 4;
    yz([[-slide_w / 2, 0], [-slide_w / 2, slide_h - ch],
        [-slide_w / 2 + ch, slide_h], [slide_w / 2 - ch, slide_h],
        [slide_w / 2, slide_h - ch], [slide_w / 2, 0]], 0, slide_len);
    // lufa
    translate([slide_len - 20, 0, 16.5]) rotate([0, 90, 0])
        cylinder(d = 14.5, h = 22);
    // celownik kolimatorowy (poglądowo)
    translate([14, -13, slide_h]) cube([46, 26, 3]);
    translate([16, -13, slide_h]) cube([8, 26, 26]);
}
module pdp_frame() {
    fw = frame_w;
    // szkielet pod zamkiem
    xz([[-2, 0], [-bt_over, -2], [-bt_over, -6], [-2, -13], [4, -22],
        [20, -20], [x_dc - 75, -18], [x_dc - 75, z_rail + 2 * pic_v + 0.6],
        [x_dc, z_rail + 2 * pic_v + 0.6], [x_dc, 0]], -fw / 2, fw / 2);
    // szyna Picatinny z rowkami
    difference() {
        yz([[-pic_top / 2, z_rail], [-pic_w / 2, z_rail + pic_v],
            [-pic_top / 2, z_rail + 2 * pic_v], [-pic_top / 2, z_rail + 7],
            [pic_top / 2, z_rail + 7], [pic_top / 2, z_rail + 2 * pic_v],
            [pic_w / 2, z_rail + pic_v], [pic_top / 2, z_rail]], x_rr, x_dc);
        for (i = [0:2]) translate([slot_x[i] - 2.6, -15, z_rail - 1])
            cube([5.2, 30, 4]);
    }
    // kabłąk spustu
    difference() {
        xz([[x_dc - 75, -16], [x_dc - 70, -40], [x_dc - 80, -50], [48, -50],
            [40, -22]], -9, 9);
        xz([[x_dc - 82, -20], [x_dc - 78, -38], [x_dc - 85, -44], [52, -44],
            [47, -20]], -10, 10);
    }
    // spust
    xz([[trig_x - 2, -18], [trig_x + 3, -30], [trig_x + 1, -40],
        [trig_x - 3, -30]], -4, 4);
    // chwyt
    xz([[4, -20], [-6, -40], [-30, -112], [22, -118], [46, -50], [40, -18]],
       -fw / 2 - 0.5, fw / 2 + 0.5);
    // dźwignie zwalniacza zamka
    xz([[36, -2], [36, -8], [86, -9], [86, -3]], -ctrl_w / 2, ctrl_w / 2);
}
module pistol() {
    color([0.32, 0.33, 0.36]) translate([-slide_pos * slide_travel, 0, 0])
        render() pdp_slide();
    color([0.2, 0.2, 0.22]) render() pdp_frame();
}

// ---------------- układanie do druku i sprawdziany ----------------
module to_bed_L() { translate([0, 0, yo]) rotate([-90, 0, 0]) children(); }
module to_bed_R() { translate([0, 0, yo]) rotate([90, 0, 0]) children(); }

module rail_gauge() {
    x0 = lock_x[len(lock_x) - 1] - 6;
    module slab() { translate([x0, -100, -100]) cube([12, 200, 200]); }
    translate([-x0, 0, 0]) to_bed_L() intersection() { chassis_L(); slab(); }
    translate([-x0 + 16, 0, 0]) to_bed_R()
        intersection() { chassis_R(); slab(); }
}
module profile_gauge() {
    linear_extrude(1.2) offset(delta = 0.01) projection()
        rotate([90, 0, 0]) chassis_R();
}

// ---------------- wybór ----------------
if (part == "assembly") {
    color([0.85, 0.45, 0.1]) translate([0, explode, 0]) render() chassis_L();
    color([0.9, 0.55, 0.15]) translate([0, -explode, 0]) render() chassis_R();
    color([0.3, 0.32, 0.3]) translate([-explode, 0, 0]) render() stock();
    color([0.3, 0.32, 0.3]) translate([acc_x0, 0, z_blk0 - explode])
        mirror([0, 0, 1]) render() acc_rail();
    if (show_pistol) pistol();
} else if (part == "chassis_L") {
    rotate([0, 0, print_rot]) to_bed_L() chassis_L();
} else if (part == "chassis_R") {
    rotate([0, 0, -print_rot]) to_bed_R() chassis_R();
} else if (part == "stock") {
    translate([0, 0, stock_t / 2]) rotate([90, 0, 0]) stock();
} else if (part == "acc_rail") {
    acc_rail();
} else if (part == "rail_gauge") {
    rail_gauge();
} else if (part == "profile_gauge") {
    profile_gauge();
} else if (part == "pistol") {
    pistol();
}
