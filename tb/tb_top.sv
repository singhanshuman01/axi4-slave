`timescale 1ns/1ps

module tb_top;

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam MEM_DEPTH = 16;


logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_data_buf[$];
logic [DATA_WIDTH-1:0] rx_data_buf[$];

logic clk;
logic rst_n;

logic [ADDR_WIDTH-1:0] awaddr;
logic [7:0] awburst;
logic awvalid;
logic awready;

logic [DATA_WIDTH-1:0] wdata;
logic [$clog2(DATA_WIDTH)-2:0] wstrb;
logic wvalid;
logic wready;

logic [1:0] bresp;
logic bvalid;
logic bready;

logic [ADDR_WIDTH-1:0] araddr;
logic [7:0] arburst;
logic arvalid;
logic arready;

logic [DATA_WIDTH-1:0] rdata;
logic [1:0] rresp;
logic rvalid;
logic rready;

logic tx_empty;
logic tx_rclk;
logic tx_rd_en;
logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0] tx_rd_data;

logic rx_full;
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
    @(posedge clk);
    rready <= 1'b1;
    wait(rvalid);
    @(posedge clk);
    rready <= 1'b0;

    $display("RECIEVED READ DATA successfully, DATA=%h RESP=%b", rdata, rresp);
endtask

task read_tx(input int num);
    @(posedge tx_rclk);
    for (int i = 0; i < num ; i=i+1) begin        
        if(!tx_empty) begin
            tx_rd_en <= 1'b1;
        end
        @(posedge tx_rclk);
        tx_data_buf.push_back(tx_rd_data);
    end
    tx_rd_en <= 1'b0;
endtask

task write_rx(input int num);
    @(posedge rx_wclk);
    for (int i = 0; i<num; i=i+1) begin
        if(!rx_full) begin
            rx_wr_en<=1'b1;
        end
        rx_wr_data <= $urandom();
        @(posedge rx_wclk);        
    end
    rx_wr_en<=1'b0;
endtask

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

    $display("Reset released.");

    // TODO: Add AXI write/read and RX/TX FIFO stimulus and checks.
    repeat (10) @(posedge clk);
    
    $display("\nTEST 1: single write on a register");
    write_addr(32'h0000_0000, 8'h00);
    write_data(32'hFAAA_14A5, 4'hF);
    take_resp();

    repeat(3) @(posedge clk);

    $display("\nTEST 2: single read on a register");
    read_addr(32'h0000_0000, 8'h00);
    read_data();

    $display("\nTEST 3: Burst write on a register");
    write_addr(32'h0000_0000, 8'h07);
    repeat(8) write_data($urandom(), 4'hf);
    take_resp();

    $display("\nTEST 4: single read on a register");
    read_addr(32'h0000_0000, 8'h00);
    read_data();

    $display("\nTEST 5: parallel read write on FIFOs");
    fork
        begin
            repeat(2) @(posedge clk);
            write_addr(32'h0000_00008, 8'h11);
            repeat(16) write_data($urandom(), 4'hF);
            read_tx(3);
            repeat(2) write_data($urandom(), 4'hF);
            take_resp();
        end
        write_rx(16);
        begin
            read_addr(32'h0000_000C, 8'hF);
            repeat(16) read_data();
        end
    join
    
    repeat (10) @(posedge clk);
    $finish;
end

initial begin
    #200000;
    $fatal(1, "Testbench timed out");
end

initial begin
    $dumpfile("sim/tb_top.vcd");
    $dumpvars(0, tb_top);
end

endmodule
