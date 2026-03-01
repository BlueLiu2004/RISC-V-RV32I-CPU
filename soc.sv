module soc(
    input  logic sys_clk,
    input  logic sys_rst_n,
    output logic [7:0] SEG_DIS,
    output logic [3:0] SEG_DIS_EN
);
    import rv32i_types_pkg::*;
    import SYSinfo::*;

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

    XLEN_t mmio_rdata;
    logic dmem_is_mmio;
    logic mmio_seg_we;
    logic [1:0] mmio_seg_addr_offset;
    XLEN_t mmio_seg_wdata;
    XLEN_t mmio_seg_rdata;
    logic [IMEM_ADDR_WIDTH-1:0] imem_word_addr;

    (* ram_style = "distributed" *) XLEN_t dmem [0:DMEM_DEPTH-1];

    

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

    logic [3:0] seg_numbers [3:0];
    four_digits_eight_segments seg4(
        .clk(sys_clk),
        .reset_n(sys_rst_n),
        .numbers(seg_numbers),
        .dots(4'b0000),
        .segments(SEG_DIS),
        .digit_ena(SEG_DIS_EN)
    );

    mmio_router u_mmio_router(
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .seg_rdata(mmio_seg_rdata),
        .seg_we(mmio_seg_we),
        .seg_addr_offset(mmio_seg_addr_offset),
        .seg_wdata(mmio_seg_wdata),
        .dmem_is_mmio(dmem_is_mmio),
        .mmio_rdata(mmio_rdata)
    );

    mmio_seg u_mmio_seg(
        .clk(cpu_clk),
        .reset_n(reset_n),
        .we(mmio_seg_we),
        .addr_offset(mmio_seg_addr_offset),
        .wdata(mmio_seg_wdata),
        .rdata(mmio_seg_rdata),
        .seg_numbers(seg_numbers)
    );

    imem_rom #(
        .ADDR_WIDTH(IMEM_ADDR_WIDTH)
    ) u_imem_rom(
        .addr(imem_addr[2 +: IMEM_ADDR_WIDTH]),
        .rdata(imem_rdata)
    );

    always_comb begin
        if (dmem_is_mmio) begin
            dmem_rdata = mmio_rdata;
        end else begin
            dmem_rdata = dmem[dmem_addr[2 +: DMEM_ADDR_WIDTH]];
        end
    end

    always_ff @(posedge cpu_clk) begin
        if (dmem_we && !dmem_is_mmio) begin
            dmem[dmem_addr[2 +: DMEM_ADDR_WIDTH]] <= dmem_wdata;
        end
    end

endmodule