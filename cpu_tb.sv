module cpu_tb();
    import rv32i_types_pkg::*;
    logic clk;
    logic reset;

    XLEN_t imem_addr;
    XLEN_t dmem_addr;

    XLEN_t dmem_wdata;
    logic dmem_we;
    ////////////////////////////////////////////////////////
    logic [31:0] imem [0:31];
    logic [31:0] dmem [0:31];
    ////////////////////////////////////////////////////////
    int mode = 0;

    rv32i_cpu dut (
        .clk(clk),
        .reset(reset),
        .imem_rdata(imem[imem_addr[9:2]]),
        .dmem_rdata(dmem[dmem_addr[9:2]]),
        .imem_addr(imem_addr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata), 
        .dmem_we(dmem_we)
    );
    always_ff @ (posedge clk) begin
        if (dmem_we) dmem[dmem_addr[9:2]] <= dmem_wdata;
    end
    
    task recordSYS();
        begin
            $dumpfile("cpu_tb.vcd"); // 產生波形檔
            $dumpvars(0, cpu_tb);
        end
    endtask

    task initSYS(); 
        begin
            clk = 0;
            reset = 1;
            for(int i = 0; i <= 31; i++) imem[i] = XLEN_t'('h13); // fill NOP
            `include "assembler/imem.svinc"

            #10 reset = 0;
            repeat (2) @ (negedge clk); reset = 0;
            @ (negedge clk);
        end
    endtask
    always #5 clk = ~clk; // 每隔 5 個時間單位，時脈就反轉一次

    task exitSYS();
        begin
            repeat (5) @ (negedge clk);
            $finish;
        end
    endtask

    // main code
    task mainSYS();
        #100;
    endtask
    

    
    initial begin
        recordSYS();
        initSYS();

        mainSYS();

        exitSYS();
    end

endmodule