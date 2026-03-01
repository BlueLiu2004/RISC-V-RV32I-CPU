module four_digits_eight_segments(
    input logic clk,
    input logic reset_n,
    input logic [3:0] numbers [3:0],
    input logic [3:0] dots,
    output logic [7:0] segments, //a,b,c,d,e,f,g,dot
    output logic [3:0] digit_ena
);
    localparam int unsigned CLK_HZ = FPGAinfo::CLK_HZ;
    localparam int unsigned SCAN_HZ = 120;
    localparam int unsigned SCAN_DIV = CLK_HZ / (SCAN_HZ * 4) - 1;

    localparam IS_ACTIVE_LOW_SEG = 1'b0;
    localparam IS_ACTIVE_LOW_EN  = 1'b1;

    logic [$clog2(SCAN_DIV+1) - 1:0] scan_counter;
    logic [1:0] scan_idx;



    always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            scan_idx     <= 2'd0;
            scan_counter <= 'd0;
        end else if (scan_counter != SCAN_DIV) begin
            scan_counter <= scan_counter + 1'd1;
        end else begin
            scan_counter <= 'd0;
            scan_idx     <= scan_idx + 1'd1;
        end
    end

    always_comb begin
        digit_ena = 4'b0001 << scan_idx;
        if (IS_ACTIVE_LOW_EN) digit_ena = ~digit_ena;
    end

    // module eight_digitals(
    //     input  logic [3:0] number,
    //     input  logic       dot,
    //     input  logic       isActiveHigh,
    //     output logic [7:0] digit // a,b,c,d,e,f,g,dot
    // );

    logic [7:0] internal_segments [3:0];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_digits
            eight_digitals u_digit(
                .number(numbers[i]),
                .dot(dots[i]),
                .isActiveHigh(~IS_ACTIVE_LOW_SEG),
                .digit(internal_segments[i])
            );
        end
    endgenerate

    assign segments = internal_segments[scan_idx];
endmodule