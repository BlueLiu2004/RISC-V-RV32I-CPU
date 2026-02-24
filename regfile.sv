module regfile(
    input  logic clk,
    input  logic rst,
    input  logic write_en,
    input  logic [4:0]  write_addr,
    input  rv32i_types_pkg::XLEN_t write_data,
    input  logic [4:0]  read1_addr,
    output rv32i_types_pkg::XLEN_t read1_data,
    input  logic [4:0]  read2_addr,
    output rv32i_types_pkg::XLEN_t read2_data
);
    rv32i_types_pkg::XLEN_t GPR [31:0];
    integer reg_rst_i;

    always_ff @ (posedge clk) begin
        if(rst) begin
            for (int i = 1; i <= 31; i++) begin
                GPR[i] <= '0;
            end
        end else begin
            if (write_en && (write_addr != '0)) begin
                GPR[write_addr] <= write_data;
            end
        end
    end

    assign read1_data = (read1_addr == '0) ? '0 : ((write_en && (read1_addr == write_addr)) ? write_data : GPR[read1_addr]);
    assign read2_data = (read2_addr == '0) ? '0 : ((write_en && (read2_addr == write_addr)) ? write_data : GPR[read2_addr]);
endmodule