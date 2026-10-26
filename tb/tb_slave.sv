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
logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_fifo[$:15];
logic [DATA_WIDTH-1:0] rx_fifo[$:15];


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
    $display("Assert reset");
    rst_n = 1'b0;
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;
    arvalid = 1'b0;
    rready = 1'b0;
    repeat(4) @(posedge clk);
    $display("De-Assert reset");
    rst_n = 1'b1;
end


initial begin
    #20000 $fatal(1, "Time limit exceeded");
end

task automatic write_addr(  input logic [ADDR_WIDTH-1:0] addr,
                            input logic [7:0] burst);
    @(posedge clk);
    awaddr <= addr;
    awburst <= burst;
    awvalid <= 1'b1;
    wait(awready);
    @(posedge clk);
    awvalid <= 1'b0;

    $display("WRITE ADDRESS handshake completed, ADDR=%h BURST=%0d", addr, burst);
endtask

task automatic write_data(  input logic [DATA_WIDTH-1:0] data,
                            input logic [$clog2(DATA_WIDTH)-2:0] strobe);
    @(posedge clk);
    wdata <= data;
    wvalid <= 1'b1;
    wstrb <= strobe;
    wait(wready);
    @(posedge clk);
    wvalid <= 1'b0;

    $display("WRITE DATA handshake complete, DATA=%h STROBE=%b", data, strobe);
endtask

task automatic take_resp();
    @(posedge clk);
    bready <= 1'b1;
    wait(bvalid);
    @(posedge clk);
    // @(posedge clk);
    bready <= 1'b0;

    $display("RESPONSE recieved, BRESP=%b", bresp);
endtask

task automatic read_addr(  input logic [ADDR_WIDTH-1:0] addr,
                            input logic [7:0] burst);
    @(posedge clk);
    arvalid <= 1'b1;
    araddr <= addr;
    arburst <= burst;
    wait(arready);
    @(posedge clk);
    arvalid <= 1'b0;

    $display("READ ADDR handshake completed, ADDR=%h BURST=%d", addr, burst);
endtask

task automatic read_data();
    @(negedge clk);
    rready <= 1'b1;
    wait(rvalid);
    @(posedge clk);
    rready <= 1'b0;

    $display("RECIEVED READ DATA successfully, DATA=%h RESP=%b", rdata, rresp);
endtask

always @(posedge clk) begin
    if(tx_wr_en && tx_fifo.size()!=16) tx_fifo.push_back(tx_data);
    if(rx_rd_en && rx_fifo.size()!=0) rx_data = rx_fifo.pop_front();

    rx_empty <= (rx_fifo.size()==0);
    tx_full <= (tx_fifo.size()==16);
end



initial begin
    repeat(10) @(posedge clk);

    $display("\nTEST 1:Begin the testing.");
    write_addr(32'h0000_0004, 8'h00);
    write_data(32'hDEAF_FACE, 4'hF);
    take_resp();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 2:Testing write at wrong address");
    write_addr(32'h0000_0000, 8'h00);
    write_data(32'h0000_0010, 4'hF);
    take_resp();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 3:testing single write at txfifo");
    read_addr(32'h0000_0008, 8'h00);
    read_data();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 4:testing read at ctrl register");
    read_addr(32'h0000_0000, 8'h00);
    read_data();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 5:updating the ctrl register");
    write_addr(32'h0000_0000, 8'h00);
    write_data(32'hCAFE_501A, 4'hF);
    take_resp();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 6:reading the ctrl register again to confirm write");
    read_addr(32'h0000_0000, 8'h00);
    read_data();

    repeat(5) @(posedge clk);
    $display("\n\nTEST 7:burst write at tx fifo");
    write_addr(32'h0000_0008, 8'd5);
    wdata <= $urandom();
    wvalid <= 1'b1;
    wstrb <=4'hf;
    wait(wready);
    repeat(5) begin
        @(posedge clk);
        wdata <= $urandom;
        $display("Writing data=%h", wdata);
    end
    @(posedge clk);
    $display("Writing data=%h", wdata);
    wvalid <= 1'b0;
    take_resp();
    while(tx_fifo.size != 0) begin
        $display("front=%h", tx_fifo.pop_front());
    end

    repeat(5) @(posedge clk);
    $display("\n\nTEST 8:burst read at rxfifo");
    repeat(8) rx_fifo.push_back($urandom());
    @(posedge clk);
    read_addr(32'h0000_000C, 8'h7);
    wait(rvalid);
    @(posedge clk);
    rready <= 1'b1;
    repeat(3) @(posedge clk);
    rready <= 1'b0;
    @(posedge clk);
    @(posedge clk);
    rready <= 1'b1;
    repeat(6) begin
        @(posedge clk);
        rready <= rvalid;
        $display("rxfifo data=%h", rdata);
    end
    rready <= 1'b0;

    repeat(5) @(posedge clk);
    #10 $finish;
end

initial begin
    $dumpfile("sim/tb_slave.vcd");
    $dumpvars(0, tb_slave);
end

endmodule