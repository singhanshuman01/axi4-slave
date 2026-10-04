module slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input clk,
    input rst_n,

    input 
);

reg []


sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPT(16)
) waddr_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .full(full),
    .rd_en(rd_en),
    .empty(empty),
    .rd_data(rd_data)
);



endmodule