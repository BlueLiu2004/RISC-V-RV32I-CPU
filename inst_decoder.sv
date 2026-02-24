module inst_decoder(
    input  rv32i_types_pkg::XLEN_t inst,
    output rv32i_types_pkg::imm_t imm_sel,
    output rv32i_types_pkg::aluop_t alu_op,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic is_branch,
    output logic is_jal, 
    output logic is_jalr,
    output logic alu_src_imm,
    output logic invalid_inst
);
    import rv32i_types_pkg::*;
    inst_t instruction;
    assign instruction = inst;

    opcode_t opcode;
    assign opcode = instruction.Rtype.opcode;

    logic [2:0] funct3;
    assign funct3 = instruction.Rtype.funct3;

    logic [6:0] funct7;
    assign funct7 = instruction.Rtype.funct7;

    logic invalid_opcode, invalid_funct;

    always_comb begin : opcode_imm_type_decoder
        imm_sel = IMM_I;
        invalid_opcode = 0;
        unique case(opcode)
            OP_IMM, LOAD, JALR: imm_sel = IMM_I;
            STORE: imm_sel = IMM_S;
            BRANCH: imm_sel = IMM_B;
            LUI, AUIPC: imm_sel = IMM_U;
            JAL: imm_sel = IMM_J;
            default: invalid_opcode = 1;
        endcase
    end
    /*
    output aluop_t alu_op,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic is_branch,
    output logic is_jal,
    output logic is_jalr,
    output logic alu_src_imm
    */

    // invalid_opcode has been drivered by opcode_imm_type_decoder block
    always_comb begin : opcode_signal_decoder
        alu_op = 'b0;
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        is_branch = 0;
        is_jal = 0;
        is_jalr = 0;
        alu_src_imm = 0;
        invalid_funct = 0;

        unique case(opcode)
            OP_IMM: begin
                alu_src_imm = 1;
                reg_write = 1;
                unique case(funct3)
                    3'b000: alu_op = ADD;  // ADDI
                    3'b001: begin   // SLLI
                        if(funct7 == 7'b0000000) alu_op = SLL;
                        else invalid_funct = 1;
                    end
                    3'b010: alu_op = SLT;  // SLTI
                    3'b011: alu_op = SLTU; // SLTIU
                    3'b100: alu_op = XOR;  // XORI
                    3'b101: begin   // SRLI & SRAI(funct7=0100000)
                        if(funct7 == 7'b0100000) alu_op = SRA;
                        else if(funct7 == 7'b0000000) alu_op = SRL;
                        else invalid_funct = 1;
                    end
                    3'b110: alu_op =  OR;  // ORI
                    3'b111: alu_op = AND;  // ANDI
                    default: invalid_funct = 1;
                endcase
            end
            LUI: begin
                alu_op = ADD;
                reg_write = 1;
                alu_src_imm = 1;
            end
            AUIPC: begin
                alu_op = ADD;
                reg_write = 1;
                alu_src_imm = 1;
            end
            OP: begin
                reg_write = 1;
                unique case({funct7, funct3})
                    {7'b0,3'b000}: alu_op = ADD;  // ADD
                    {7'b0100000,3'b000}: alu_op = SUB;  // SUB
                    {7'b0,3'b001}: alu_op = SLL;  // SLL
                    {7'b0,3'b010}: alu_op = SLT;  // SLT
                    {7'b0,3'b011}: alu_op = SLTU; // SLTU
                    {7'b0,3'b100}: alu_op = XOR;  // XOR
                    {7'b0,3'b101}: alu_op = SRL;  // SRL
                    {7'b0100000,3'b101}: alu_op = SRA;  // SRA
                    {7'b0,3'b110}: alu_op =  OR;  // OR
                    {7'b0,3'b111}: alu_op = AND;  // AND
                    default: invalid_funct = 1;
                endcase
            end
            JAL: begin
                alu_op = ADD;
                reg_write = 1;
                is_jal = 1;
                alu_src_imm = 1;
            end
            JALR: begin
                invalid_funct = (funct3 != 3'b000);
                alu_op = ADD;
                reg_write = 1;
                is_jalr = 1;
                alu_src_imm = 1;
            end
            BRANCH: begin
                is_branch = 1;
                invalid_funct = (funct3 != BEQ)
                             && (funct3 != BNE)
                             && (funct3 != BLT)
                             && (funct3 != BGE)
                             && (funct3 != BLTU)
                             && (funct3 != BGEU); // BEQ, BNE, BLT, BGE, BLTU, BGEU
            end
            LOAD: begin
                alu_op = ADD;
                mem_read = 1;
                reg_write = 1;
                alu_src_imm = 1;
                // implement LW only first
                invalid_funct = //(funct3 != 3'b000)
                            //  && (funct3 != 3'b001)
                            (funct3 != 3'b010);
                            //  && (funct3 != 3'b100)
                            //  && (funct3 != 3'b101); // LB, LH, LW, LBU, LHU
            end
            STORE: begin
                alu_op = ADD;
                mem_write = 1;
                alu_src_imm = 1;
                // implement SW only first
                invalid_funct = //(funct3 != 3'b000) 
                             //&& (funct3 != 3'b001) 
                             (funct3 != 3'b010); // SB, SH, SW
            end
            /*MISC_MEM, SYSTEM,*/ default: begin
            end
        endcase
    end

    assign invalid_inst = invalid_opcode || invalid_funct;

endmodule