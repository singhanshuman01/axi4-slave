`timescale 1ns/100ps

module tb_slave;

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;

logic clk;
logic rst_n;

logic [ADDR_WIDTH-1:0] awaddr;
logic [7:0] awburst;
logic awvalid;
logic awready;

logic [DATA_WIDTH-1:0] wdata;
logic [$clog2(DATA_WIDTH)-2:0] wstrb;
logic wvalid, wready;

logic [1:0] bresp;
logic bvalid, bready;

logic [ADDR_WIDTH-1:0] araddr;
logic [7:0] arburst;
logic arvalid, arready;

logic [DATA_WIDTH-1:0] rdata;
logic [1:0] rresp;
logic rvalid, rready;

logic tx_full;
logic tx_wr_en;
logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_data;

logic rx_empty;
logic rx_rd_en;
logic [DATA_WIDTH-1:0] rx_data;


// queue to simulate fifo
logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_fifo[$];
logic [DATA_WIDTH-1:0] rx_fifo[$];


slave #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) slave_inst (
    .clk(clk),
    .rst_n(rst_n),

    .awaddr(awaddr),
    .awburst(awburst),
    .awvalid(awvalid),
    .awready(awready),

    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),

    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),

    .araddr(araddr),
    .arburst(arburst),
    .arvalid(arvalid),
    .arready(arready),

    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready),

    .tx_full(tx_full),
    .tx_wr_en(tx_wr_en),
    .tx_data(tx_data),

    .rx_empty(rx_empty),
    .rx_rd_en(rx_rd_en),
    .rx_data(rx_data)
);


initial clk = 0;
always #5 clk = ~clk;

initial begin
    rst_n = 1'b0;
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;
    arvalid = 1'b0;
    rready = 1'b0;
    tx_full = 1'b0;
    rx_empty = 1'b0;
    repeat(4) @(posedge clk);
    rst_n = 1'b1;
end


initial begin
    #20000 $fatal(1, "Time limit exceeded");
end

initial begin
    repeat(10) @(posedge clk);

    #10 $finish;
end

initial begin
    $dumpfile("sim/tb_slave.vcd");
    $dumpvars(0, tb_slave);
end

endmodule