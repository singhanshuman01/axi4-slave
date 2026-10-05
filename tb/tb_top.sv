interface axif#(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
) (
    input logic clk
);
    logic rst_n;

    logic [ADDR_WIDTH-1:0] awaddr;
    logic awvalid;
    logic awready;
    
    logic [DATA_WIDTH-1:0] wdata;
    logic wvalid;
    logic wready;

    logic [1:0] bresp;
    logic bvalid;
    logic bready;

    logic [ADDR_WIDTH-1:0] araddr;
    logic arvalid;
    logic arready;

    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;

    logic tx_full;
    logic tx_clk;
    logic tx_rst_n;
    logic tx_wr_en;
    logic tx_data;

    logic rx_empty;
    logic rx_clk;
    logic rx_rst_n;
    logic rx_rd_en;
    logic rx_data;
endinterface //axif

module tb;
localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;
logic clk;

initial clk = 0;
always #5 clk = ~clk;

initial begin
    rst_n = 0;
    #10 rst_n = 1;
end

axif axi(clk);

slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) DUT(
    .clk(clk),
    .rst_n(axi.rst_n),
    .awaddr(axi.awaddr),
    .awvalid(axi.awvalid),
    .awready(axi.awready),
    .wdata(axi.wdata),
    .wvalid(axi.wvalid),
    .wready(axi.wready),
    .bresp(axi.bresp),
    .bvalid(axi.bvalid),
    .bready(axi.bready),
    .araddr(axi.araddr),
    .arvalid(axi.arvalid),
    .arready(axi.arready),
    .rdata(axi.rdata),
    .rresp(axi.rresp),
    .rvalid(axi.rvalid),
    .rready(axi.rready),
    .tx_full(axi.tx_full),
    .tx_clk(axi.tx_clk),
    .tx_rst_n(axi.tx_rst_n),
    .tx_wr_en(axi.tx_wr_en),
    .tx_data(axi.tx_data),
    .rx_empty(axi.rx_empty),
    .rx_clk(axi.rx_clk),
    .rx_rst_n(axi.rx_rst_n),
    .rx_rd_en(axi.rx_rd_en),
    .rx_data(axi.rx_data)
);



endmodule