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
    localparam int unsigned CPU_CLK_DIV_BIT = 0;
    localparam logic BYPASS_CPU_FOR_SEG = 1'b0;
    localparam logic SHOW_MMIO_PROBE   = 1'b0;

    localparam XLEN_t MMIO_SEG0_ADDR = 32'h0000_0000;
    localparam XLEN_t MMIO_SEG1_ADDR = 32'h0000_0004;
    localparam XLEN_t MMIO_SEG2_ADDR = 32'h0000_0008;
    localparam XLEN_t MMIO_SEG3_ADDR = 32'h0000_000C;

    logic reset_n;
    logic cpu_clk;
    assign cpu_clk = sys_clk;

    reset_sync_2ff_n soc_reset(
        .clk(cpu_clk),
        .rst_async_n(sys_rst_n), // 外部來的非同步復位
        .rst_sync_n(reset_n)   // 供 CPU 內部使用的同步釋放訊號
    );

    XLEN_t imem_rdata;
    XLEN_t dmem_rdata;
    XLEN_t imem_addr;
    XLEN_t dmem_addr;
    XLEN_t dmem_wdata;
    logic dmem_we;

    logic [31:0] imem [0:IMEM_DEPTH-1];
    (* ram_style = "distributed" *) logic [31:0] dmem [0:DMEM_DEPTH-1];

    logic [3:0] seg_numbers [3:0];
    logic [3:0] seg_dots;

    rv32i_cpu cpu1(
        .clk(cpu_clk),
        .reset_n(reset_n),
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

    assign imem_rdata = imem[imem_addr[2 +: IMEM_AW]];

    always_comb begin
        unique case (dmem_addr)
            MMIO_SEG0_ADDR: dmem_rdata = {28'd0, seg_numbers[0]};
            MMIO_SEG1_ADDR: dmem_rdata = {28'd0, seg_numbers[1]};
            MMIO_SEG2_ADDR: dmem_rdata = {28'd0, seg_numbers[2]};
            MMIO_SEG3_ADDR: dmem_rdata = {28'd0, seg_numbers[3]};
            default:        dmem_rdata = dmem[dmem_addr[2 +: DMEM_AW]];
        endcase
    end

    logic dmem_is_mmio;
    assign dmem_is_mmio = (dmem_addr == MMIO_SEG0_ADDR)
                       || (dmem_addr == MMIO_SEG1_ADDR)
                       || (dmem_addr == MMIO_SEG2_ADDR)
                       || (dmem_addr == MMIO_SEG3_ADDR);

    logic mmio_wr_seen;
    logic [3:0] mmio_wr_count;
    XLEN_t last_mmio_addr;
    XLEN_t last_mmio_data;

    always_ff @(posedge cpu_clk or negedge reset_n) begin
        if (!reset_n) begin
            mmio_wr_seen  <= 1'b0;
            mmio_wr_count <= 4'd0;
            last_mmio_addr <= '0;
            last_mmio_data <= '0;
        end else if (dmem_we && dmem_is_mmio) begin
            mmio_wr_seen  <= 1'b1;
            mmio_wr_count <= mmio_wr_count + 4'd1;
            last_mmio_addr <= dmem_addr;
            last_mmio_data <= dmem_wdata;
        end
    end

    always_ff @(posedge cpu_clk or negedge reset_n) begin
        if (!reset_n) begin
            seg_numbers[0] <= 4'd0;
            seg_numbers[1] <= 4'd0;
            seg_numbers[2] <= 4'd0;
            seg_numbers[3] <= 4'd0;
        end else if (BYPASS_CPU_FOR_SEG) begin
            seg_numbers[0] <= 4'd3;
            seg_numbers[1] <= 4'd2;
            seg_numbers[2] <= 4'd1;
            seg_numbers[3] <= 4'd0;
        end else if (SHOW_MMIO_PROBE) begin
            seg_numbers[0] <= imem_addr[5:2];
            seg_numbers[1] <= dmem_addr[5:2];
            seg_numbers[2] <= {1'b0, dmem_we, dmem_is_mmio, mmio_wr_seen};
            seg_numbers[3] <= mmio_wr_count;
        end else if (dmem_we && dmem_is_mmio) begin
            unique case (dmem_addr)
                MMIO_SEG0_ADDR: seg_numbers[0] <= dmem_wdata[3:0];
                MMIO_SEG1_ADDR: seg_numbers[1] <= dmem_wdata[3:0];
                MMIO_SEG2_ADDR: seg_numbers[2] <= dmem_wdata[3:0];
                MMIO_SEG3_ADDR: seg_numbers[3] <= dmem_wdata[3:0];
                default: ;
            endcase
        end
    end

    always_ff @(posedge cpu_clk) begin
        if (dmem_we && !dmem_is_mmio) begin
            dmem[dmem_addr[2 +: DMEM_AW]] <= dmem_wdata;
        end
    end

    always_comb begin
        if (SHOW_MMIO_PROBE) begin
            seg_dots[0] = mmio_wr_seen;
            seg_dots[1] = dmem_we;
            seg_dots[2] = dmem_is_mmio;
            seg_dots[3] = 1'b0;
        end else begin
            seg_dots = 4'b0000;
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