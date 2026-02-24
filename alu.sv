module alu(
    input  rv32i_types_pkg::aluop_t alu_op,
    input  rv32i_types_pkg::XLEN_t a,
    input  rv32i_types_pkg::XLEN_t b,
    output rv32i_types_pkg::XLEN_t y,
    output logic zero
);
    import rv32i_types_pkg::*;
    logic [4:0] shamt;
    assign shamt = b[4:0];

    always_comb begin
        unique case(alu_op)
            ADD:  y = a + b;
            SUB:  y = a - b;
            AND:  y = a & b;
            OR:   y = a | b;
            XOR:  y = a ^ b;
            SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            SLTU: y = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;
            SLL:  y = a << shamt;
            SRL:  y = $unsigned(a) >> shamt;
            SRA:  y = $signed(a) >>> shamt;
            default: y = 'd0;
        endcase
    end

    assign zero = (y == 'd0);
endmodule