module mmio_seg(
    input  logic clk,
    input  logic reset_n,
    input  logic we,
    input  logic [1:0] addr_offset,
    input  rv32i_types_pkg::XLEN_t wdata,
    output rv32i_types_pkg::XLEN_t rdata,
    output logic [3:0] seg_numbers [3:0]
);
    import rv32i_types_pkg::*;

    always_comb begin
        unique case (addr_offset)
            2'd0:    rdata = {28'd0, seg_numbers[0]};
            2'd1:    rdata = {28'd0, seg_numbers[1]};
            2'd2:    rdata = {28'd0, seg_numbers[2]};
            2'd3:    rdata = {28'd0, seg_numbers[3]};
            default: rdata = '0;
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            seg_numbers[0] <= 4'd0;
            seg_numbers[1] <= 4'd0;
            seg_numbers[2] <= 4'd0;
            seg_numbers[3] <= 4'd0;
        end else if (we) begin
            unique case (addr_offset)
                2'd0: seg_numbers[0] <= wdata[3:0];
                2'd1: seg_numbers[1] <= wdata[3:0];
                2'd2: seg_numbers[2] <= wdata[3:0];
                2'd3: seg_numbers[3] <= wdata[3:0];
                default: ;
            endcase
        end
    end
endmodule