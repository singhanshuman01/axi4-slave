`timescale 1ns/1ps

module tb_sync_fifo;

localparam DATA_WIDTH = 32;
localparam MEM_DEPTH = 16;

logic [DATA_WIDTH-1:0] q [$:MEM_DEPTH-1];
logic [DATA_WIDTH-1:0] element;

logic clk;
logic rst_n;

logic full;
logic wr_en;
logic [DATA_WIDTH-1:0] wr_data;

logic empty;
logic rd_en;
logic [DATA_WIDTH-1:0] rd_data;

sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(wr_en),
    .full(full),
    .wr_data(wr_data),

    .rd_en(rd_en),
    .empty(empty),
    .rd_data(rd_data)
);

initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    rst_n = 1'b0;
    repeat(3) @(posedge clk);
    rst_n = 1'b1;
end

initial begin
    #20000 $fatal(1, "Terminated forcefully");
end

task automatic push(input logic [DATA_WIDTH-1:0] wdata);

@(negedge clk);
wr_en = 1'b1;
wr_data = wdata;

@(negedge clk);
wr_en = 1'b0;

endtask

task automatic pop();

@(negedge clk);
rd_en = 1'b1;
@(negedge clk);
rd_en = 1'b0;

endtask

task automatic check_empty(input logic expected);
if(empty == expected) $write("PASS");
else $write("ERROR");
$display("\tEmpty is %b expected %b", empty, expected);
endtask

task automatic check_full(input logic expected);
if(full==expected) $write("PASS");
else $write("ERROR");

$display("\tFull is %b expected %b", full, expected);
endtask

initial begin
    repeat(5) @(posedge clk);

    $display("Test 1: check full empty after reset");
    check_full(0);
    check_empty(1);

    $display("Test 2: check empty after a single write");
    push(32'hFACE_FACE);
    check_empty(0);
    pop();
    check_empty(1);

    $display("Test 3: check full after overflowing fifo");
    repeat(17) push($urandom());
    check_full(1);

    $display("Test 4: check empty after draining fifo");
    repeat(17) pop();
    check_empty(1);

    $display("Test 5: check reset midway");
    repeat(17) push($urandom());
    check_full(1);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    check_empty(1);
    check_full(0);

    $display("Test 6: check data integrity");
    repeat(5) @(posedge clk);
    
    repeat(16) begin
        @(negedge clk);
        element = $urandom();
        q.push_back(element);
        wr_en = 1;
        wr_data = element;
    end
    @(negedge clk);
    wr_en = 0;
    check_full(1);
    repeat(16) begin
        @(posedge clk);
        rd_en = 1;
        @(negedge clk);
        element = q.pop_front();
        if(rd_data == element) $display("PASS: Expected = %h actual = %h", element, rd_data);
        else $display("ERROR: Expected = %h actual = %h", element, rd_data);
    end
    rd_en = 0;


    #100 $finish;
end

initial begin
    $dumpfile("sim/sync_fifo.vcd");
    $dumpvars(1,tb_sync_fifo);
end

endmodule