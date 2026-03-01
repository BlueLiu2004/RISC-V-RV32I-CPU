module reset_sync_2ff_n (
    input  logic clk,
    input  logic rst_async_n, // 外部來的非同步復位
    output logic rst_sync_n   // 供 CPU 內部使用的同步釋放訊號
);
    logic rff1;

    always_ff @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            rff1       <= 1'b0;
            rst_sync_n <= 1'b0;
        end else begin
            rff1       <= 1'b1;
            rst_sync_n <= rff1; // 經過兩級 FF 同步
        end
    end
endmodule