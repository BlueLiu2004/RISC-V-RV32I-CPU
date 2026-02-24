module branch_unit (
    input  logic is_branch,
    input  logic [2:0] funct3,
    input  rv32i_types_pkg::XLEN_t rs1,
    input  rv32i_types_pkg::XLEN_t rs2,
    output logic take_branch
);
    import rv32i_types_pkg::*;
    
    always_comb begin
        if(!is_branch) take_branch = 0;
        else begin
            unique case(funct3)
                BEQ:  take_branch = (rs1 == rs2);
                BNE:  take_branch = (rs1 != rs2);
                BLT:  take_branch = ($signed(rs1)  < $signed(rs2));
                BGE:  take_branch = ($signed(rs1) >= $signed(rs2));
                BLTU: take_branch = ($unsigned(rs1)  < $unsigned(rs2));
                BGEU: take_branch = ($unsigned(rs1) >= $unsigned(rs2));
                default: take_branch = 0;
            endcase
        end
    end
endmodule