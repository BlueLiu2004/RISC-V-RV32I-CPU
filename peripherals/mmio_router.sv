module mmio_router(
    input  rv32i_types_pkg::XLEN_t dmem_addr,
    input  rv32i_types_pkg::XLEN_t dmem_wdata,
    input  logic dmem_we,
    input  rv32i_types_pkg::XLEN_t seg_rdata,
    output logic seg_we,
    output logic [1:0] seg_addr_offset,
    output rv32i_types_pkg::XLEN_t seg_wdata,
    output logic dmem_is_mmio,
    output rv32i_types_pkg::XLEN_t mmio_rdata
);
    import rv32i_types_pkg::*;
    import SYSinfo::*;

    logic seg_sel;

    assign seg_sel = (dmem_addr == MMIO_SEG0_ADDR)
                  || (dmem_addr == MMIO_SEG1_ADDR)
                  || (dmem_addr == MMIO_SEG2_ADDR)
                  || (dmem_addr == MMIO_SEG3_ADDR);

    assign seg_we = dmem_we && seg_sel;
    assign seg_addr_offset = dmem_addr[3:2];
    assign seg_wdata = dmem_wdata;

    assign dmem_is_mmio = seg_sel;
    assign mmio_rdata = seg_sel ? seg_rdata : '0;
endmodule
