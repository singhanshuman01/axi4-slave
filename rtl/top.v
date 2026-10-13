module top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH = 16
) (
    input   clk,
    input   rst_n,

    input [ADDR_WIDTH-1:0]          awaddr,
    input [7:0]                     awburst,
    input                           awvalid,
    output reg                      awready,

    input [DATA_WIDTH-1:0]          wdata,
    input [$clog2(DATA_WIDTH)-2:0]  wstrb,
    input                           wvalid,
    output reg                      wready,

    output reg [1:0]                bresp,
    output reg                      bvalid,
    input                           bready,

    input [ADDR_WIDTH-1:0]          araddr,
    input [8:0]                     arburst,
    input                           arvalid,
    output reg                      arready,

    output reg [DATA_WIDTH-1:0]     rdata,
    output reg [1:0]                rresp,
    output reg                      rvalid,
    input                           rready,

    output                          tx_empty,
    input                           tx_rclk,
    // input                           tx_rrst_n,
    input                           tx_rd_en,
    output reg [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_rd_data,

    output                          rx_full,
    input                           rx_wclk,
    // input                           rx_wrst_n,
    input                           rx_wr_en,
    input [DATA_WIDTH-1:0]          rx_wr_data
);

wire tx_full, tx_wclk, tx_wrst_n, tx_wr_en;
wire [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_wdata;
async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) TX_FIFO (
    .rclk(tx_rclk),
    .rrst_n(tx_wrst_n),
    .empty(tx_empty),
    .read_en(tx_rd_en),
    .r_data(tx_rd_data),
    .wclk(tx_wclk),
    .wrst_n(tx_wrst_n),
    .full(tx_full)
    .write_en(tx_wr_en),
    .w_data(tx_wdata)
);


wire rx_rclk, rx_rrst_n, rx_rd_en, rx_empty;
wire [DATA_WIDTH-1:0] rx_rdata;
async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) RX_FIFO (
    .rclk(rx_rclk),
    .rrst_n(rx_rrst_n),
    .empty(rx_empty),
    .read_en(rx_rd_en),
    .r_data(rx_rdata),
    .wclk(rx_wclk),
    .wrst_n(rx_rrst_n),
    .full(rx_full)
    .write_en(rx_wr_en),
    .w_data(rx_wr_data)
);

slave #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) axi4slave (
    .clk(clk),
    .rst(rst),
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
)