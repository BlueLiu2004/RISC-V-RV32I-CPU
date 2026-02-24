package rv32i_types_pkg;

    localparam XLEN = 32;
    typedef logic [XLEN - 1:0] XLEN_t;
    typedef logic [2:0] imm_t;
    typedef logic [6:0] opcode_t;
    typedef logic [3:0] aluop_t;


    typedef enum imm_t {
        IMM_I = 'd0,
        IMM_S = 'd1,
        IMM_B = 'd2, 
        IMM_U = 'd3,
        IMM_J = 'd4
    } imm_enum;
    
    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        opcode_t opcode;
    } Rtype_t;

    typedef struct packed {
        logic [11:0] imm11_0;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        opcode_t opcode;     
    } Itype_t;

    typedef struct packed {
        logic [6:0] imm11_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm4_0;
        opcode_t opcode;
    } Stype_t;

    typedef struct packed {
        logic imm12;
        logic [5:0] imm10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm4_1;
        logic imm11;
        opcode_t opcode;
    } Btype_t;

    typedef struct packed {
        logic [19:0] imm31_12;
        logic [4:0] rd;
        opcode_t opcode;
    } Utype_t;

    typedef struct packed {
        logic imm20;
        logic [9:0] imm10_1;
        logic imm11;
        logic [7:0] imm19_12;
        logic [4:0] rd;
        opcode_t opcode;
    } Jtype_t;

    typedef union packed {
        XLEN_t RAW;
        Rtype_t Rtype;
        Itype_t Itype;
        Stype_t Stype;
        Btype_t Btype;
        Utype_t Utype;
        Jtype_t Jtype;
    } inst_t;

    typedef enum opcode_t {
        OP_IMM = 'b0010011,
        LUI = 'b0110111,
        AUIPC = 'b0010111,
        OP = 'b0110011,
        JAL = 'b1101111,
        JALR = 'b1100111,
        BRANCH = 'b1100011,
        LOAD = 'b0000011,
        STORE = 'b0100011,
        MISC_MEM = 'b0001111,
        SYSTEM = 'b1110011
    } opcode_enum;

    typedef enum aluop_t {
        ADD  = 'd0,
        SUB  = 'd1,
        AND  = 'd2,
        OR   = 'd3,
        XOR  = 'd4,
        SLT  = 'd5,
        SLTU = 'd6,
        SLL  = 'd7,
        SRL  = 'd8,
        SRA  = 'd9
    } aluop_enum;

    typedef enum logic [2:0] {
        BEQ = 'b000,
        BNE = 'b001,
        BLT = 'b100,
        BGE = 'b101,
        BLTU = 'b110,
        BGEU = 'b111
    } branch_t; // their opcode at Page 554.
endpackage