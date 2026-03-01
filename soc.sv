module soc(
    input  logic sys_clk,
    input  logic sys_rst_n,
    output logic [7:0] SEG_DIS,
    output logic [3:0] SEG_DIS_EN
);
    import rv32i_types_pkg::*;

    localparam int unsigned IMEM_DEPTH = 256;
    localparam int unsigned DMEM_DEPTH = 256;
    localparam int unsigned IMEM_AW = $clog2(IMEM_DEPTH);
    localparam int unsigned DMEM_AW = $clog2(DMEM_DEPTH);

    localparam XLEN_t MMIO_SEG0_ADDR = 32'h0000_0000;
    localparam XLEN_t MMIO_SEG1_ADDR = 32'h0000_0004;
    localparam XLEN_t MMIO_SEG2_ADDR = 32'h0000_0008;
    localparam XLEN_t MMIO_SEG3_ADDR = 32'h0000_000C;

    logic reset;
    assign reset = ~sys_rst_n;

    XLEN_t imem_rdata;
    XLEN_t dmem_rdata;
    XLEN_t imem_addr;
    XLEN_t dmem_addr;
    XLEN_t dmem_wdata;
    logic dmem_we;

    logic [31:0] imem [0:IMEM_DEPTH-1];
    logic [31:0] dmem [0:DMEM_DEPTH-1];

    logic [3:0] seg_numbers [3:0];
    logic [3:0] seg_dots;

    rv32i_cpu cpu1(
        .clk(sys_clk),
        .reset(reset),
        .imem_rdata(imem_rdata),
        .dmem_rdata(dmem_rdata),
        .imem_addr(imem_addr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we)
    );

    four_digits_eight_segments seg4(
        .clk(sys_clk),
        .reset_n(sys_rst_n),
        .numbers(seg_numbers),
        .dots(seg_dots),
        .segments(SEG_DIS),
        .digit_ena(SEG_DIS_EN)
    );

    assign seg_dots = 4'b0000;

    assign imem_rdata = imem[imem_addr[IMEM_AW+1:2]];

    always_comb begin
        unique case (dmem_addr)
            MMIO_SEG0_ADDR: dmem_rdata = {28'd0, seg_numbers[0]};
            MMIO_SEG1_ADDR: dmem_rdata = {28'd0, seg_numbers[1]};
            MMIO_SEG2_ADDR: dmem_rdata = {28'd0, seg_numbers[2]};
            MMIO_SEG3_ADDR: dmem_rdata = {28'd0, seg_numbers[3]};
            default:        dmem_rdata = dmem[dmem_addr[DMEM_AW+1:2]];
        endcase
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            seg_numbers[0] <= 4'd0;
            seg_numbers[1] <= 4'd0;
            seg_numbers[2] <= 4'd0;
            seg_numbers[3] <= 4'd0;
        end else if (dmem_we) begin
            unique case (dmem_addr)
                MMIO_SEG0_ADDR: seg_numbers[0] <= dmem_wdata[3:0];
                MMIO_SEG1_ADDR: seg_numbers[1] <= dmem_wdata[3:0];
                MMIO_SEG2_ADDR: seg_numbers[2] <= dmem_wdata[3:0];
                MMIO_SEG3_ADDR: seg_numbers[3] <= dmem_wdata[3:0];
                default:        dmem[dmem_addr[DMEM_AW+1:2]] <= dmem_wdata;
            endcase
        end
    end

    initial begin
        for (int i = 0; i < IMEM_DEPTH; i++) begin
            imem[i] = 32'h00000013;
        end
        for (int i = 0; i < DMEM_DEPTH; i++) begin
            dmem[i] = 32'h00000000;
        end

`include "assembler/imem.svinc"
    end
endmodule