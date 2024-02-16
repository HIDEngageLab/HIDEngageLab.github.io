$fn=100;

module text_line(content, text_size, align="left") {    
    linear_extrude(0.0001)
        translate([0,0,0.0001])
            if (align=="center") {
                text(content, size=text_size, halign="center", valign="center");
            } else {
                text(content, size=text_size);
            }
}

module board(board_name, w,d,h) {
    color("#00700f")
    cube([w,d,h], center=true);
    translate([-w/2+0.5,-d/2+0.5, h/2])
        text_line(board_name, 1);
}

module pins(width, count, w,d,h) {
    step = width/count;
    color("#f5f50f")
    for (i=[-width/2+step/2:step:width/2-step/2]) {
        translate([i, 0, 0])
        cube([w,d,h], center=true);
    }
}

module chip(chip_name, chip_w, chip_d, chip_h, pins, sides=4) {
    pin_count=pins/sides;
    pin_w=0.25;
    pin_d=0.3;
    pin_h=0.25;
    
    color("#050505")
    cube([chip_w, chip_d, chip_h], center=true);
    if (sides>0)
        rotate([0,0,0]) 
            translate([0,(chip_w+pin_d)/2,-chip_h/2+pin_h/2]) 
                pins(chip_w*.9, pin_count, pin_w, pin_d, pin_h);
    if (sides>1)
        rotate([0,0,0]) 
            translate([0,-(chip_w+pin_d)/2,-chip_h/2+pin_h/2]) 
                pins(chip_w*.9, pin_count, pin_w, pin_d, pin_h);
    if (sides>2)
        rotate([0,0,90])
            translate([0,(chip_w+pin_d)/2,-chip_h/2+pin_h/2]) 
                pins(chip_w*.9, pin_count, pin_w, pin_d, pin_h);
    if (sides>3)
        rotate([0,0,90])
            translate([0,-(chip_w+pin_d)/2,-chip_h/2+pin_h/2]) 
                pins(chip_w*.9, pin_count, pin_w, pin_d, pin_h);
    translate([0,0,chip_h/2])
        text_line(chip_name, 0.5, align="center");
}

module srcreen(w, d, h, text="", size=2) {
    translate([0,0,h/2/2])
        color("#05050f")
            cube([w*1.01, d*1.01, h/2], center=true);
    translate([0,0,h/2*0.75/2])
        color("#cfcfcf")
            cube([w*1.02, d*1.02, h/2*0.75], center=true);
    translate([0,0,-h/2/2])
        color("#05059f") 
            cube([w*1.02, d*1.02, h/2], center=true);
    translate([0,0,h/2+0.001])
        color("#ffffff")  
            text_line(text, size, align="center");
    }

module host() {
    translate([-15,-15,1/2])
        chip("CPU", 20, 20, 1, 80);
    translate([0,0,-1.5/2])
        board("Host", 80,60,1.5);
    translate([0,5, 10])
        srcreen(1280*0.04, 780*0.04, 1, "Welcome!", 2);
}

module stamp() {
    translate([0,0,-1.5/2])
        board("VariKey", 22,15,1.5);
    translate([0,0,0.75/2])
        chip("RP2040", 7, 7, 0.75, 40);
    translate([-7.5,4,0.5/2])
        chip("ADP5585", 3, 3, 0.5, 16);
    translate([7.5,-4,0.5/2])
        chip("", 2.5, 2.5, 0.2, 8, 2);
}

translate([40,-15,0])
    srcreen(128*0.2, 32*0.2, 1, "Hello, world!", 2);
translate([40,-30,0])
    stamp();

translate([0,0,-20]) {
    translate([0,0,-1])
        host();
}