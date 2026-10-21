`timescale 1ns/1ps

module tb_top;

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam MEM_DEPTH = 16;

logic clk;
logic rst_n;

logic [ADDR_WIDTH-1:0] awaddr;
logic [7:0] awburst;
logic awvalid;
wire awready;

logic [DATA_WIDTH-1:0] wdata;
logic [$clog2(DATA_WIDTH)-2:0] wstrb;
logic wvalid;
wire wready;

wire [1:0] bresp;
wire bvalid;
logic bready;

logic [ADDR_WIDTH-1:0] araddr;
logic [8:0] arburst;
logic arvalid;
wire arready;

wire [DATA_WIDTH-1:0] rdata;
wire [1:0] rresp;
wire rvalid;
logic rready;

wire tx_empty;
logic tx_rclk;
logic tx_rd_en;
wire [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_rd_data;

wire rx_full;
logic rx_wclk;
logic rx_wr_en;
logic [DATA_WIDTH-1:0] rx_wr_data;

top #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) dut (
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

    .tx_empty(tx_empty),
    .tx_rclk(tx_rclk),
    .tx_rd_en(tx_rd_en),
    .tx_rd_data(tx_rd_data),

    .rx_full(rx_full),
    .rx_wclk(rx_wclk),
    .rx_wr_en(rx_wr_en),
    .rx_wr_data(rx_wr_data)
);

initial clk = 1'b0;
always #5 clk = ~clk;

initial tx_rclk = 1'b0;
always #7 tx_rclk = ~tx_rclk;

initial rx_wclk = 1'b0;
always #11 rx_wclk = ~rx_wclk;

initial begin
    rst_n = 1'b0;

    awaddr = '0;
    awburst = '0;
    awvalid = 1'b0;
    wdata = '0;
    wstrb = '0;
    wvalid = 1'b0;
    bready = 1'b0;

    araddr = '0;
    arburst = '0;
    arvalid = 1'b0;
    rready = 1'b0;

    tx_rd_en = 1'b0;
    rx_wr_en = 1'b0;
    rx_wr_data = '0;

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    $display("Reset released; add top-level test scenarios here.");

    // TODO: Add AXI write/read and RX/TX FIFO stimulus and checks.
    repeat (10) @(posedge clk);
    $finish;
end

initial begin
    #100000;
    $fatal(1, "Testbench timed out");
end

initial begin
    $dumpfile("sim/tb_top.vcd");
    $dumpvars(0, tb_top);
end

endmodule
