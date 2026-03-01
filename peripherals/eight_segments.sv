module eight_digitals(
    input  logic [3:0] number,
    input  logic       dot,
    input  logic       isActiveHigh,
    output logic [7:0] digit // a,b,c,d,e,f,g,dot
);

    localparam logic [6:0] HEX2SEG [0:15] = '{
        7'b1111110, // 0
        7'b0110000, // 1
        7'b1101101, // 2
        7'b1111001, // 3
        7'b0110011, // 4
        7'b1011011, // 5
        7'b1011111, // 6
        7'b1110000, // 7
        7'b1111111, // 8
        7'b1111011, // 9
        7'b1110111, // A
        7'b0011111, // b
        7'b1001110, // C
        7'b0111101, // d
        7'b1001111, // E
        7'b1000111  // F
    };

    assign digit = {HEX2SEG[number], dot} ^ {8{~isActiveHigh}};

endmodule