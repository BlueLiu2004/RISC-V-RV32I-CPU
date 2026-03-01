package SYSinfo;
    localparam int unsigned CLK_HZ = 50_000_000; // 50MHz
    localparam int unsigned IMEM_DEPTH = 256;
    localparam int unsigned DMEM_DEPTH = 256;
    localparam int unsigned IMEM_ADDR_WIDTH = $clog2(IMEM_DEPTH);
    localparam int unsigned DMEM_ADDR_WIDTH = $clog2(DMEM_DEPTH);
    
    typedef enum logic [31:0] {
        MMIO_SEG0_ADDR = 32'h0000_0000,
        MMIO_SEG1_ADDR = 32'h0000_0004,
        MMIO_SEG2_ADDR = 32'h0000_0008,
        MMIO_SEG3_ADDR = 32'h0000_000C
    } mmio_addr_e;
    
endpackage