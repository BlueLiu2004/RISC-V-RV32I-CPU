module imm_gen(
input rv32i_types_pkg::XLEN_t inst,
input rv32i_types_pkg::imm_t imm_sel,
output rv32i_types_pkg::XLEN_t imm);
    import rv32i_types_pkg::*;
    inst_t instruction;
    assign instruction.RAW = inst;

    always_comb begin : combine_immediate
        imm = 'd0;
        unique case(imm_sel)
            IMM_I: imm = {{20{instruction.Itype.imm11_0[11]}}, instruction.Itype.imm11_0};
            IMM_S: imm = {{20{instruction.Stype.imm11_5[6]}}, instruction.Stype.imm11_5, instruction.Stype.imm4_0};
            IMM_B: imm = {{20{instruction.Btype.imm12}}, instruction.Btype.imm11, instruction.Btype.imm10_5, instruction.Btype.imm4_1, 1'b0};
            IMM_U: imm = {instruction.Utype.imm31_12, 12'b0};
            IMM_J: imm = {{12{instruction.Jtype.imm20}}, instruction.Jtype.imm19_12, instruction.Jtype.imm11, instruction.Jtype.imm10_1, 1'b0};
            default: imm = 'hDEADBEEF;
        endcase
    end
endmodule