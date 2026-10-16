`timescale 1ns/100ps
module tb;

localparam DATA_WIDTH = 32;
localparam MEM_DEPTH = 16;
logic [DATA_WIDTH-1:0] item, item2, item3;
logic [DATA_WIDTH-1:0] q[$];

logic rd_clk;
logic rd_rst_n;
logic empty;
logic rd_en;
logic [DATA_WIDTH-1:0] rd_data;

logic wr_clk;
logic wr_rst_n;
logic full;
logic wr_en;
logic [DATA_WIDTH-1:0] wr_data;

async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) fifo_inst (
    .rclk(rd_clk),
    .wclk(wr_clk),

    .rrst_n(rd_rst_n),
    .wrst_n(wr_rst_n),

    .read_en(rd_en),
    .write_en(wr_en),

    .empty(empty),
    .full(full),

    .r_data(rd_data),
    .w_data(wr_data)
);

initial rd_clk = 0;
always #7 rd_clk = ~rd_clk;

initial wr_clk = 0;
always #5 wr_clk = ~wr_clk;

initial begin
    rd_rst_n = 1'b0;
    repeat(3) @(posedge rd_clk);
    rd_rst_n = 1'b1;
end

initial begin
    wr_rst_n = 1'b0;
    repeat(3) @(posedge wr_clk);
    wr_rst_n = 1'b1;
end

initial begin
    #200000 $fatal (1, "Terminated Forcefully");
end

task automatic push(input logic [DATA_WIDTH-1:0] elem);
    @(negedge wr_clk);
    wr_en  = 1'b1;
    wr_data = elem;
    @(negedge wr_clk);
    wr_en = 1'b0;
endtask

task automatic pop();
    @(negedge rd_clk);
    rd_en = 1'b1;
    @(negedge rd_clk);
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
    wr_en = 1'b0;
    rd_en = 1'b0;
    fork
        repeat(5) @(posedge rd_clk);
        repeat(5) @(posedge wr_clk);
    join

    $display("TEST 1: check full/empty after reset");
    check_empty(1);
    check_full(0);

    $display("TEST 2: check empty after single write");
    push($urandom());
    repeat(3) @(posedge rd_clk);
    check_empty(0);
    pop();
    repeat(3) @(posedge wr_clk);
    check_empty(1);
    
    $display("TEST 3: check full after overflowing fifo");
    repeat(16) push($urandom());
    check_full(1);

    $display("TEST 4: check full/empty after reset");
    fork
        begin
            @(negedge wr_clk);
            wr_rst_n = 1'b0;
            @(negedge wr_clk);
            wr_rst_n = 1'b1;
            check_full(0);
        end
        begin
            @(negedge rd_clk);
            rd_rst_n = 1'b0;
            @(negedge rd_clk);
            rd_rst_n = 1'b1;
            check_empty(1);
        end
    join

    repeat(5) @(posedge rd_clk);

    $display("TEST 5: overflowing then draining FIFO");
    repeat(17) push($urandom());
    check_full(1);
    @(posedge rd_clk);
    repeat(17) pop();
    check_empty(1);

    repeat(5) @(posedge rd_clk);
    $display("TEST 6: checking data integrity");
    @(negedge wr_clk);
    repeat(16) begin
        wr_en = 1'b1;
        item = $urandom();
        wr_data = item;
        q.push_back(item);
        @(negedge wr_clk);
    end
    wr_en = 1'b0;
    check_full(1);
    @(negedge rd_clk);
    repeat(16) begin
        rd_en = 1'b1;
        item = q.pop_front();
        @(negedge rd_clk);
        if(rd_data == item) $write("PASS:");
        else $write("ERROR:");

        $display("\tExpected %h actual %h", item, rd_data);
    end
    @(negedge rd_clk);
    rd_en = 1'b0;
    check_empty(1);

    repeat(5) @(posedge rd_clk);
    wr_rst_n = 1'b0;
    rd_rst_n = 1'b0;
    fork
        @(negedge wr_clk) wr_rst_n = 1'b1;
        @(negedge rd_clk) rd_rst_n = 1'b1;
    join
    repeat(5) @(posedge rd_clk);
    check_full(0);
    check_empty(1);


    $display("TEST 7: Mixed read write till fifo full");
    fork
        repeat(56) push($urandom());
        repeat(40) pop();
    join
    @(posedge wr_clk);
    check_full(1);
    repeat(16) pop();
    check_empty(1);
    check_full(0);

    repeat(5) @(posedge rd_clk);
    q.delete();

    $display("TEST 8: continous read write with data integrity check");
    fork
        repeat(55) begin
            @(negedge wr_clk);
            if(!full) begin
                wr_en = 1'b1;
                item = $urandom();
                wr_data = item;
                q.push_back(item);
            end
            @(posedge wr_clk); #1;
            wr_en = 1'b0;
        end
        repeat(55) begin            
            @(negedge rd_clk);
            rd_en = !empty;
            @(posedge rd_clk); #1;
            if(rd_en) begin
                item2 = rd_data;
                item3 = q.pop_front();
                if(item2 == item3) $write("PASS:");
                else $write("ERROR:");
                $display("\tExpected = %h arrived = %h", item3, item2);
            end
            rd_en = 1'b0;
        end
    join



    repeat(3) @(posedge rd_clk);
    wr_rst_n = 1'b0;
    rd_rst_n = 1'b0;
    fork
        @(negedge wr_clk) wr_rst_n = 1'b1;
        @(negedge rd_clk) rd_rst_n = 1'b1;
    join
    repeat(2) @(posedge rd_clk);
    check_full(0);
    check_empty(1);

    #100 $finish;
end

initial begin
    $dumpfile("sim/async_fifo.vcd");
    $dumpvars(1, tb);
end

endmodule