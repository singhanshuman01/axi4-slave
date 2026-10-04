module async_fifo #(
    parameter DATA_WIDTH = 32
)
(
    output [DATA_WIDTH-1:0] r_data,
    output                  empty, full,
    input [DATA_WIDTH-1:0]  w_data,
    input                   rclk, wclk,
    input                   rrst_n, wrst_n,
    input                   write_en, read_en
);

wire [4:0] nxt_wptr_gray, nxt_rptr_gray;
wire [3:0] waddr, raddr;
wire [4:0] sync_nxt_wptr_gray, sync_nxt_rptr_gray;

memory #(.DATA_WIDTH(DATA_WIDTH)) mem_inst(
    .read_data  (r_data),
    .write_data (w_data),
    .read_addr  (raddr),
    .write_addr (waddr),
    .rclk       (rclk),
    .ren        (read_en),
    .empty      (empty),
    .wclk       (wclk),
    .wen        (write_en),
    .full       (full)
);

sync_wptr sync_wptr_inst(
    .sync_write_ptr (sync_nxt_wptr_gray),
    .wptr           (nxt_wptr_gray),
    .rclk           (rclk),
    .rrst_n         (rrst_n)
);

sync_rptr sync_rptr_inst (
    .sync_read_ptr  (sync_nxt_rptr_gray),
    .rptr           (nxt_rptr_gray),
    .write_clk      (wclk),
    .wrst_n         (wrst_n)
);

handler_rptr handler_rptr_inst (
    .read_addr      (raddr),
    .rptr           (nxt_rptr_gray),
    .empty          (empty),
    .sync_gray_wptr (sync_nxt_wptr_gray),
    .en             (read_en),
    .clk            (rclk),
    .arst_n         (rrst_n)
);

handler_wptr handler_wptr_inst (
    .write_addr     (waddr),
    .write_ptr      (nxt_wptr_gray),
    .full           (full),
    .sync_gray_rptr (sync_nxt_rptr_gray),
    .en             (write_en),
    .clk            (wclk),
    .rst_n          (wrst_n)
);

endmodule

module memory #(
    parameter DATA_WIDTH = 32
) (
    output [DATA_WIDTH-1:0]    read_data,
    input [DATA_WIDTH-1:0]     write_data,
    input [3:0]     read_addr, write_addr,
    input           rclk, ren, empty,
    input           wclk, wen, full 
);

reg [DATA_WIDTH-1:0] mem [0:15];

assign read_data = mem[read_addr];

always @(posedge wclk) begin
    if (wen && !full) mem[write_addr] <= write_data;
end

endmodule

module handler_rptr (
    output [3:0]        read_addr,
    output reg [4:0]    rptr,
    output reg          empty,
    input [4:0]         sync_gray_wptr,
    input               en, clk, arst_n
);

reg [4:0] local_read_addr_bin;
wire [4:0] next_read_gray, next_read_bin;
wire empty_r;

always @(posedge clk or negedge arst_n) begin
    if(!arst_n) {rptr, local_read_addr_bin} <= 0;
    else {rptr, local_read_addr_bin} <= {next_read_gray, next_read_bin};
end

assign read_addr = local_read_addr_bin[3:0];

assign next_read_bin = local_read_addr_bin + (en & !empty);
assign next_read_gray = next_read_bin ^ (next_read_bin>>1);

assign empty_r = (next_read_gray == sync_gray_wptr);

always @(posedge clk or negedge arst_n) begin
    if(!arst_n) empty <= 1'b1;
    else empty <= empty_r;
end

endmodule

module handler_wptr (
    output [3:0]        write_addr,
    output reg [4:0]    write_ptr,
    output reg          full,
    input [4:0]         sync_gray_rptr,
    input               en, clk, rst_n
);

reg [4:0] local_write_addr;
wire [4:0] next_write_addr_bin, next_write_addr_gray;
wire full_w;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) {local_write_addr, write_ptr} <= 0;
    else {local_write_addr, write_ptr} <= {next_write_addr_bin, next_write_addr_gray};
end

assign write_addr = local_write_addr[3:0];

    assign next_write_addr_bin = local_write_addr + (en & ~full);
assign next_write_addr_gray = next_write_addr_bin ^ (next_write_addr_bin>>1);

assign full_w = (next_write_addr_gray == {~sync_gray_rptr[4:3], sync_gray_rptr[2:0]});

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) full <= 1'b0;
    else full <= full_w;
end


endmodule

module sync_rptr (
    output reg [4:0]    sync_read_ptr,
    input [4:0]         rptr,
    input               write_clk,
    input               wrst_n
);

reg [4:0] temp;

always @(posedge write_clk or negedge wrst_n ) begin
    if(!wrst_n) {sync_read_ptr, temp} <= 0;
    else {sync_read_ptr, temp} <= {temp, rptr};
end

endmodule


module sync_wptr (
    output reg [4:0]    sync_write_ptr,
    input [4:0]         wptr,
    input               rclk, rrst_n
);

reg [4:0] temp;

always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n) {sync_write_ptr, temp} <= 0;
    else {sync_write_ptr, temp} <= {temp, wptr};
end

endmodule