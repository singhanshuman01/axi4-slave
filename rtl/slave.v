module slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input   clk,
    input   rst_n,

    input [ADDR_WIDTH-1:0]          awaddr,
    input [7:0]                     awburst,
    input                           awvalid,
    output reg                      awready,

    input [DATA_WIDTH-1:0]          wdata,
    input [$clog2(DATA_WIDTH)-1:0]  wstrb,
    input                           wvalid,
    output reg                      wready,

    output reg [1:0]                bresp,
    output reg                      bvalid,
    input                           bready,

    input [ADDR_WIDTH-1:0]          araddr,
    input                           arvalid,
    output reg                      arready,

    output reg [DATA_WIDTH-1:0]     rdata,
    output reg [1:0]                rresp,
    output reg                      rvalid,
    input                           rready,

    input                           tx_full,
    output                          tx_clk,
    output                          tx_rst_n,
    output reg                      tx_wr_en,
    output reg [DATA_WIDTH-1:0]     tx_data,

    input                           rx_empty,
    output                          rx_clk,
    output                          rx_rst_n,
    output reg                      rx_rd_en,
    input [DATA_WIDTH-1:0]          rx_data
);

reg [DATA_WIDTH-1:0] ctrl;
reg [DATA_WIDTH-1:0] status;

always @(*) begin
    status[0] = 1'b0;
    status[1] = !rx_empty;
    status[2] = tx_full;
    status[31:3] = 29'b0;
end



reg wr_en_waddr, rd_en_waddr;
wire full_waddr, empty_waddr;
reg [ADDR_WIDTH-1:0] wr_data_waddr;
wire [ADDR_WIDTH-1:0] rd_data_waddr;
sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH+8),
    .MEM_DEPTH(16)
) waddr_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en_waddr),
    .wr_data(wr_data_waddr),
    .full(full_waddr),
    .rd_en(rd_en_waddr),
    .empty(empty_waddr),
    .rd_data(rd_data_waddr)
);

localparam IDLE = 2'b00,
            WRITE = 2'b01,
            RESP = 2'b10;

reg [1:0] state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awready <= 1'b0;
    else begin
        wr_en_waddr <= (awvalid && awready) ? 1'b1: 1'b0;
        awready <= (awvalid && !full_waddr && !awready) ? 1'b1: 1'b0;
        wr_data_waddr <= {awburst, awaddr};
    end
end

reg [7:0] burstcnt;
reg [ADDR_WIDTH-1:0] wr_addr;
reg [1:0] resp_rg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state = IDLE;
    else begin
        case (state)
            IDLE: begin
                wready <= 1'b0;
                bvalid <= 1'b0;
                tx_wr_en <= 1'b0;
                if(!empty_waddr) begin
                    {burstcnt, wr_addr} <= rd_data_waddr;
                    rd_en_waddr <= 1'b1;
                    state <= WRITE;
                end
            end
            WRITE: begin
                wready <= (!tx_full)? 1'b1: 1'b0;
                if(wvalid && wready) begin
                    if(wr_addr[1:0] != 2'b00) begin
                        resp_rg <= 2'b10;
                    end else begin
                        case (wr_addr[3:2])
                            2'b00: begin
                                ctrl <= wdata;
                                resp_rg <= 2'b00;
                            end
                            2'b10: begin
                                tx_wr_en <= 1'b1;
                                tx_data <= {wstrb, wdata};
                                resp_rg <= 2'b00;
                            end
                            default: resp_rg <= 2'b10;
                        endcase
                        if(burstcnt == 0) begin
                            state <= RESP;
                            wready <= 1'b0;
                            bresp <= resp_rg;
                        end else begin
                            burstcnt <= burstcnt - 1'b1;
                        end
                    end
                end
            end
            RESP: begin
                bvalid <= 1'b1;
                if(bvalid && bready) state <= IDLE;s
            end
            default: state = IDLE;
        endcase
    end
end

endmodule