module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH = 16
) (
    input clk,
    input rst_n,

    input wr_en,
    input [DATA_WIDTH-1:0] wr_data,
    output full,

    input rd_en,
    output empty,
    output [DATA_WIDTH-1:0] rd_data
);

reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

localparam PTR_WIDTH = $clog2(MEM_DEPTH);

reg [PTR_WIDTH:0] wptr, rptr;

assign rd_data = mem[rptr[PTR_WIDTH-1:0]];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wptr <= 0;
        rptr <= 0;
    end else begin
        if(wr_en) begin
            mem[wptr[PTR_WIDTH-1:0]] <= wr_data;
            wptr <= wptr+1'b1;
        end
        if(rd_en) begin            
            rptr <= rptr + 1'b1;
        end
    end
end

assign full = ( (wptr[PTR_WIDTH] != rptr[PTR_WIDTH]) & (wptr[PTR_WIDTH-1:0] == rptr[PTR_WIDTH-1:0]) );
assign empty = wptr==rptr;

endmodule