module tb;

localparam DATA_WIDTH = 32;
localparam MEM_DEPTH = 16;

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
    #20000 $fatal (1, "Terminated Forcefully");
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
    repeat(5) @(posedge rd_clk);

    
end

endmodule