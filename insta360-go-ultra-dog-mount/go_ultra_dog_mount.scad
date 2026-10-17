// =====================================================================
//  Uchwyt Insta360 GO Ultra dla psa (whippet "Bianka", ~13 kg)
//  OpenSCAD 2021.01+
//
//  Uchwyt nasuwa się na taśmę szelek albo obroży (tunele na taśmę),
//  a kamera wsuwa się od góry do kieszeni i zatrzaskuje się na
//  sprężystym języczku z zaczepem. Opcjonalna podkładka stalowa
//  wklejona w tylną ściankę współpracuje z magnesem w kamerze i
//  kasuje luzy.
//
//  Układ współrzędnych (tryb "harness"): pies idzie w kierunku +Y,
//  +Z to góra, grzbiet psa wypada na Z = 0 pod środkiem uchwytu.
// =====================================================================

/* [Wybór wariantu] */
// "harness" = kamera stoi na grzbiecie i patrzy do przodu; "collar" = kamera leży na obroży i patrzy na zewnątrz
mode = "harness"; // [harness, collar]
// Tylko harness: "across" = taśma biegnie w poprzek grzbietu (pas za łopatkami); "along" = taśma wzdłuż kręgosłupa (szelki typu H)
strap_dir = "across"; // [across, along]
// "mount" = cały uchwyt; "fit_test" = sama kieszeń do szybkiego sprawdzenia pasowania kamery
part = "mount"; // [mount, fit_test]

/* [Taśma szelek / obroży - ZMIERZ!] */
// Szerokość taśmy (mm)
strap_w = 25;
// Grubość taśmy (mm), mierzona suwmiarką bez ściskania
strap_t = 3.5;
// Promień ciała w miejscu montażu (mm): 0 = płaska baza (druk bez podpór), -1 = automatycznie
body_r = -1;

/* [Kamera] */
// Pochylenie kamery w górę (harness), stopnie. Ujemne = w dół
tilt = 10; // [-20:1:30]
// Dodatkowe uniesienie kamery nad bazą (mm), -1 = automatycznie (harness 3, collar 3.2 - miejsce na ugięcie języczka)
riser = -1;

/* [Wymiary Insta360 GO Ultra - zweryfikuj suwmiarką] */
cam_w = 46.0;
cam_h = 45.7;
cam_d = 18.3;
// Promień zaokrąglenia narożników korpusu w widoku z przodu. Mniejszy = bezpieczniej (kamera na pewno wejdzie)
cam_r = 6;
// Luz na stronę między kamerą a kieszenią
clr = 0.35;

/* [Kieszeń] */
wall = 2.2;        // ścianki boczne
back_t = 2.6;      // tylna ścianka (języczek)
lip = 2.2;         // ile wargi zachodzą na przód kamery
lip_t = 1.6;       // grubość wargi
hook_d = 2.2;      // ile zaczep zachodzi nad górną krawędź kamery
tab_w = 18;        // szerokość sprężystego języczka
slit_len = 22;     // długość nacięć języczka (dłuższe = miększy zatrzask)
slit_w = 1.2;
notch_len = 15;    // wycięcia na palce po bokach, od góry

/* [Podkładka stalowa pod magnes kamery] */
washer = true;
washer_d = 16;     // M8 DIN 125: 16 x 1.6 mm
washer_t = 1.6;
washer_y = -10;    // położenie środka względem środka kamery (w dół)

/* [Baza i tunele] */
base_t = 3.2;      // grubość płytki
bar_t = 2.6;       // grubość poprzeczki pod taśmą
bar_w = 8;         // szerokość poprzeczki (wzdłuż taśmy)
post_t = 3;        // słupki boczne tunelu
side_clr = 0.8;    // luz boczny taśmy w tunelu
strap_clr = 0.6;   // luz na grubość taśmy w tunelu
ridge = 1.2;       // garb dociskający taśmę (blokuje przesuwanie, jak klamra "triglide")

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---------------------------------------------------------------------
// Wartości pochodne
// ---------------------------------------------------------------------
collar = mode == "collar";
along = !collar && strap_dir == "along";

R_auto = collar ? 55 : (along ? 400 : 80);
R_body = body_r < 0 ? R_auto : body_r;
R = R_body == 0 ? 1e5 : R_body;   // "płaska" = bardzo duży promień
lift = riser < 0 ? (collar ? 3.2 : 3) : riser;

cw = cam_w + 2 * clr;
ch = cam_h + 2 * clr;
cd = cam_d + 2 * clr;
cr = cam_r + clr;
ow = cw + 2 * wall;
oh = ch + 2 * wall;
o_r = cr + wall;
z_back = -cd / 2 - back_t;
z_front = cd / 2 + lip_t;

hook_y = cam_h / 2 + 0.2;             // spód zaczepu nad kamerą
hook_top = hook_y + 0.8 + hook_d * 1.5;
tab_top = hook_top + 1.2;

u_pin = strap_t + strap_clr;          // spód płytki nad powierzchnią ciała
u_top = u_pin + base_t;               // wierzch płytki
y_post = strap_w / 2 + side_clr;      // wewnętrzna krawędź słupka
y_out = y_post + post_t;              // zewnętrzna krawędź tunelu

// Wymiary płytki: X = wzdłuż taśmy, Y = w poprzek taśmy
Lx = collar ? ow + 4 : (along ? 64 : max(ow + 4, 50));
Ly = collar ? max(oh, 2 * y_out + 2)
            : (along ? max(ow, 2 * y_out + 4) : max(60, 2 * y_out + 4));

// Obrys podstawy kieszeni w układzie kamery (x = szerokość, y = przód)
hz_front = cd / 2 + lip_t;
hz_back = cd / 2 + back_t;
yaw = along ? -90 : 0;   // przy taśmie wzdłuż kręgosłupa kamera patrzy w +X

assert(washer_y + washer_d / 2 < ch / 2 - slit_len - 1,
       "Podkładka koliduje z nacięciami języczka");
assert(!collar || lift >= hook_d + 0.8,
       "W trybie collar riser musi zostawić miejsce na ugięcie języczka");

// ---------------------------------------------------------------------
// Pomocnicze
// ---------------------------------------------------------------------
module rrect(w, h, r) {
    offset(r = r) square([w - 2 * r, h - 2 * r], center = true);
}

// Pozycja na łuku ciała: s = długość łuku wzdłuż taśmy, u = odległość od ciała
module at(s, u) {
    translate([0, 0, -R]) rotate([0, s / R * 180 / PI, 0]) translate([0, 0, R + u])
        children();
}

// Zaokrąglony blok wygięty po łuku ciała (łańcuch otoczek z kul)
module arc_block(s0, s1, y0, y1, u0, u1, rr) {
    a = s0 + rr;
    b = s1 - rr;
    n = max(1, ceil((b - a) / 5));
    for (i = [0 : n - 1]) hull() {
        for (s = [a + (b - a) * i / n, a + (b - a) * (i + 1) / n],
             y = [y0 + rr, y1 - rr], u = [u0 + rr, u1 - rr])
            at(s, u) translate([0, y, 0]) sphere(r = rr, $fn = 12);
    }
}

// Przestrzeń poniżej spodu płytki (żeby cokół nie zalał tunelu)
module below_plate() {
    if (R_body == 0)
        translate([-200, -200, u_pin - 400]) cube([400, 400, 400]);
    else
        translate([0, 0, -R]) rotate([90, 0, 0])
            cylinder(r = R + u_pin, h = 400, center = true, $fn = 360);
}

// ---------------------------------------------------------------------
// Kieszeń na kamerę (układ lokalny: x szerokość, y góra/wsuwanie, z przód)
// ---------------------------------------------------------------------
module cradle_body() {
    translate([0, 0, z_back]) linear_extrude(z_front - z_back) rrect(ow, oh, o_r);
}

module front_opening_2d() {
    hull() {
        rrect(cw - 2 * lip, ch - 2 * lip, max(cr - lip, 0.5));
        translate([0, oh + 10]) rrect(cw - 2 * lip, ch - 2 * lip, max(cr - lip, 0.5));
    }
}

module cradle_cuts() {
    // gniazdo kamery + kanał wsuwania od góry
    translate([0, 0, -cd / 2]) linear_extrude(cd) hull() {
        rrect(cw, ch, cr);
        translate([0, oh + 10]) rrect(cw, ch, cr);
    }
    // okno z przodu, wargi fazowane na zewnątrz (mniejsze winietowanie przy 155°)
    hull() {
        translate([0, 0, cd / 2 - eps]) linear_extrude(0.4 + eps) front_opening_2d();
        translate([0, 0, z_front]) linear_extrude(1) offset(delta = lip_t) front_opening_2d();
    }
    // wycięcia na palce po bokach (chwyt przy wyjmowaniu, wentylacja, mikrofony)
    rz = cd * 0.28;
    for (sx = [-1, 1]) hull() {
        translate([sx * (cw / 2 + wall / 2), ch / 2 - notch_len + rz, 0])
            rotate([0, 90, 0]) cylinder(r = rz, h = wall * 3, center = true);
        translate([sx * (cw / 2 + wall / 2), oh, 0]) cube([wall * 3, 1, 2 * rz], center = true);
    }
    // nacięcia uwalniające sprężysty języczek w tylnej ściance
    for (sx = [-1, 1]) translate([sx * (tab_w / 2 + slit_w / 2), 0, 0]) {
        translate([-slit_w / 2, ch / 2 - slit_len, z_back - 1])
            cube([slit_w, oh, back_t + 1 + eps]);
        translate([0, ch / 2 - slit_len, z_back - 1])
            cylinder(d = slit_w * 1.6, h = back_t + 1 + eps, $fn = 16);
    }
    // gniazdo na podkładkę stalową (od środka kieszeni, wkleić)
    if (washer)
        translate([0, washer_y, -cd / 2 - washer_t])
            cylinder(d = washer_d + 0.4, h = washer_t + eps);
}

module cradle_adds() {
    // przedłużenie języczka ponad kieszeń
    translate([-tab_w / 2, ch / 2 - 0.5, z_back]) cube([tab_w, tab_top - ch / 2 + 0.5, back_t]);
    // uchwyt na paznokieć / kciuk z tyłu języczka
    translate([0, ch / 2 + tab_top - ch / 2 - 1.6, z_back])
        rotate([0, 90, 0]) cylinder(r = 1.6, h = tab_w - 2, center = true, $fn = 24);
    // zaczep: płaski spód trzyma kamerę, skos od góry sam odgina języczek przy wsuwaniu
    hw = tab_w - 1;
    translate([-hw / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(hw) polygon([
        [hook_y, -cd / 2 - 0.5],
        [hook_y, -cd / 2 + hook_d],
        [hook_y + 0.8, -cd / 2 + hook_d],
        [hook_top, -cd / 2],
        [hook_top, -cd / 2 - 0.5]
    ]);
}

module cradle() {
    difference() { cradle_body(); cradle_cuts(); }
    cradle_adds();
}

// ---------------------------------------------------------------------
// Ustawienie kieszeni względem bazy
// ---------------------------------------------------------------------
t_abs = abs(tilt);
zc_harness = u_top + lift + (oh / 2) * cos(tilt)
           + (tilt >= 0 ? hz_back : hz_front) * sin(t_abs);

module cam_place() {
    if (collar)
        translate([0, 0, u_top + lift - z_back]) children();
    else
        translate([0, 0, zc_harness]) rotate([0, 0, yaw]) rotate([tilt, 0, 0])
            rotate([0, 0, 180]) rotate([90, 0, 0]) children();
}

// Obrys cokołu na płytce, w układzie bazy: [s0, s1, y0, y1]
pad = collar ? [-ow / 2, ow / 2, -oh / 2, oh / 2]
     : along ? [-(hz_back + 5), hz_front + 2, -ow / 2, ow / 2]
             : [-ow / 2, ow / 2, -(hz_back + 5), hz_front + 2];

module pedestal() {
    difference() {
        hull() {
            arc_block(pad[0], pad[1], pad[2], pad[3], u_top - 0.6, u_top, 0.3);
            cam_place() {
                if (collar) {
                    translate([0, 0, z_back]) linear_extrude(0.5) rrect(ow, oh, o_r);
                } else {
                    // spód kieszeni: płaski odcinek + pełna szerokość nad zaokrągleniami
                    translate([0, -oh / 2 + 0.25, (z_back + z_front) / 2])
                        cube([ow - 2 * o_r, 0.5, z_front - z_back], center = true);
                    translate([0, -oh / 2 + o_r, (z_back + z_front) / 2])
                        cube([ow, 0.5, z_front - z_back], center = true);
                }
            }
        }
        below_plate();
    }
}

// Miejsce na ugięcie języczka, gdy tylna ścianka leży na cokole (collar)
module tab_pocket() {
    cam_place()
        translate([-(tab_w / 2 + slit_w + 0.3), ch / 2 - slit_len - 0.5, -50 + z_back + eps])
            cube([tab_w + 2 * slit_w + 0.6, oh, 50]);
}

// ---------------------------------------------------------------------
// Baza z tunelami na taśmę
// ---------------------------------------------------------------------
module base() {
    // płytka
    arc_block(-Lx / 2, Lx / 2, -Ly / 2, Ly / 2, u_pin, u_top, 1.2);
    // tunele na obu końcach
    for (sc = [-1, 1]) {
        s0 = sc > 0 ? Lx / 2 - bar_w : -Lx / 2;
        // poprzeczka pod taśmą (od strony psa)
        arc_block(s0, s0 + bar_w, -y_out, y_out, -bar_t, 0, 1.0);
        // słupki łączące poprzeczkę z płytką
        for (sy = [-1, 1])
            arc_block(s0, s0 + bar_w, sy > 0 ? y_post : -y_out, sy > 0 ? y_out : -y_post,
                      -bar_t, u_pin + 1, 1.0);
    }
    // garb pośrodku: taśma idzie pod poprzeczką - nad garbem - pod poprzeczką = blokada
    intersection() {
        translate([0, 0, u_pin - ridge + 4]) rotate([90, 0, 0])
            cylinder(r = 4, h = 2 * y_post, center = true);
        translate([-10, -y_post, u_pin - ridge - 1]) cube([20, 2 * y_post, ridge + 1.5]);
    }
}

// Pary szczelin na opaskę zaciskową / rzep - dodatkowe kotwienie i linka asekuracyjna
slot_y = Ly / 2 - 5.5;
slot_s = (slot_y - 3 > abs(pad[2]) && slot_y - 3 > abs(pad[3])) ? 8 : max(abs(pad[0]), abs(pad[1])) + 4;
use_slots = !collar && slot_y - 3 > y_out && slot_s + 3 < Lx / 2 - bar_w;

module tie_slots() {
    if (use_slots)
        for (ss = [-1, 1], sy = [-1, 1])
            at(ss * slot_s, u_pin - 2) translate([0, sy * slot_y, 0]) hull()
                for (dy = [-1.6, 1.6]) translate([0, dy, 0]) cylinder(d = 2.4, h = base_t + 4, $fn = 16);
}

// ---------------------------------------------------------------------
// Złożenie
// ---------------------------------------------------------------------
module mount() {
    difference() {
        union() {
            base();
            pedestal();
            cam_place() cradle_body();
        }
        cam_place() cradle_cuts();
        tie_slots();
        if (collar) tab_pocket();
    }
    cam_place() cradle_adds();
}

if (part == "fit_test")
    // drukowana na plecach; uchwyt języczka ścięty, żeby nie wystawał pod stół
    translate([0, 0, -z_back]) intersection() {
        cradle();
        translate([-100, -100, z_back]) cube(200);
    }
else
    mount();
