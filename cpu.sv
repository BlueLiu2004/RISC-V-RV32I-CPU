module rv32i_cpu(
    input logic clk,
    input logic reset,
    input rv32i_types_pkg::XLEN_t imem_rdata, // instruction fetch from ROM
    input rv32i_types_pkg::XLEN_t dmem_rdata, // data fetch from memory

    output rv32i_types_pkg::XLEN_t imem_addr,
    output rv32i_types_pkg::XLEN_t dmem_addr,
    output logic dmem_we
);
    import rv32i_types_pkg::*;
    // Program Counter //
    logic is_jal, is_jalr;
    XLEN_t jal_target, jalr_target, branch_target;
    logic branch_taken;
    assign branch_target = pc + imm;

    XLEN_t pc, pc_next, pc_plus4;
    always_comb begin : NextProgramCounter
        pc_plus4 = pc + 'd4;
        pc_next = is_jal ? jal_target :
                  is_jalr ? jalr_target :
                  branch_taken ? branch_target :
                  pc_plus4;
    end

    always_ff @(posedge clk) begin : ProgramCounter
        pc <= reset ? 'b0 : pc_next;
    end

    assign imem_addr = pc;
    // Instruction Fetch //
    XLEN_t instruction;
    assign instruction = imem_rdata;

    // Instruction Decode //
    // inst_decoder.sv
    //XLEN_t inst;
    imm_t imm_sel;
    aluop_t alu_op;
    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic is_branch;
    // logic is_jal;
    // logic is_jalr;
    logic alu_src_imm;
    logic invalid_inst;

    inst_decoder inst_decoder1(
        .inst(instruction),
        .imm_sel(imm_sel),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .alu_src_imm(alu_src_imm),
        .invalid_inst(invalid_inst)
    );
    // imm_gen.sv
    //XLEN_t inst;
    //imm_t imm_sel;
    XLEN_t imm;

    imm_gen imm_gen1(
        .inst(instruction),
        .imm_sel(imm_sel),
        .imm(imm)
    );
    // alu.sv
    //aluop_t alu_op;
    XLEN_t alu_a, alu_b, alu_y;
    logic alu_zero;
    XLEN_t rs1_data, rs2_data;
    
    assign alu_a = rs1_data;
    assign alu_b = alu_src_imm ? imm : rs2_data;

    // let a is rs1, b is rs2, y is rd
    alu alu1(
        .alu_op(alu_op),
        .a(alu_a),
        .b(alu_b),
        .y(alu_y),
        .zero(alu_zero)
    );

    // regfile.sv
    inst_t inst_u; // instruction union
    XLEN_t wb_data;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;

    assign wb_data = (is_jal || is_jalr) ? pc_plus4 : (mem_read ? dmem_rdata : alu_y);
    assign inst_u.RAW = instruction;
    assign rs1_addr = inst_u.Rtype.rs1;
    assign rs2_addr = inst_u.Rtype.rs2;
    assign rd_addr = inst_u.Rtype.rd;

    regfile regfile1(
        .clk(clk),
        .rst(reset),
        .write_en(reg_write & ~invalid_inst),
        .write_addr(rd_addr),
        .write_data(wb_data),
        .read1_addr(rs1_addr),
        .read1_data(rs1_data),
        .read2_addr(rs2_addr),
        .read2_data(rs2_data)
    );

    assign jal_target = pc + imm;
    assign jalr_target = (rs1_data + imm) & ~XLEN'(1'b1); 

    // branch_unit.sv
    // logic branch_taken;

    branch_unit branch_unit1(
        .is_branch(is_branch),
        .funct3(inst_u.Btype.funct3),
        .rs1(rs1_data),
        .rs2(rs2_data),
        .take_branch(branch_taken)
    );

    // TODO
    assign dmem_addr = alu_y;
    assign dmem_we = mem_write & ~invalid_inst;
endmodule