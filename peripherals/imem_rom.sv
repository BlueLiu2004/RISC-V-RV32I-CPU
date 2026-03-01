module imem_rom #(
    parameter int unsigned ADDR_WIDTH = 8,
    parameter int unsigned DEPTH = (1 << ADDR_WIDTH)
)(
    input  logic [ADDR_WIDTH-1:0] addr,
    output rv32i_types_pkg::XLEN_t rdata
);
    import rv32i_types_pkg::*;

    XLEN_t rom [0:DEPTH-1];

    initial begin
        for (int i = 0; i < DEPTH; i++) begin
            rom[i] = 32'h00000013;
        end
    `include "../assembler/imem.hex"
    end

    assign rdata = rom[addr];
endmodule
