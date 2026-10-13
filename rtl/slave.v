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

always @(posedge clk) begin
    status[0] = 1'b0;
    status[1] = !rx_empty;
    status[2] = tx_full;
    status[31:3] = 29'b0;
end



reg wr_en_waddr, rd_en_waddr;
wire full_waddr, empty_waddr;
reg [ADDR_WIDTH+8-1:0] wr_data_waddr;
wire [ADDR_WIDTH+8-1:0] rd_data_waddr;
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
                    rd_en_waddr <= 1'b1;                    
                    state <= WRITE;
                end
            end
            WRITE: begin
                if(rd_en_waddr) begin
                    {burstcnt, wr_addr} <= rd_data_waddr;
                    rd_en_waddr <= 1'b0;
                end
                wready <= !tx_full;
                if(burstcnt == 0) state <= RESP;
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
                    end
                    burstcnt <= burstcnt - 1'b1;
                end
            end
            RESP: begin
                wready <= 1'b0;
                tx_wr_en <= 1'b0;
                bresp <= resp_rg;
                bvalid <= 1'b1;
                if(bvalid && bready) state <= IDLE;
            end
            default: state = IDLE;
        endcase
    end
end


reg wr_en_raddr, rd_en_raddr;
wire full_raddr, empty_raddr;
reg [ADDR_WIDTH+8-1:0] wr_data_raddr;
wire [ADDR_WIDTH+8-1:0] rd_data_raddr;
sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH+8),
    .MEM_DEPTH(16)
) raddr_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en_raddr),
    .wr_data(wr_data_raddr),
    .full(full_raddr),
    .rd_en(rd_en_raddr),
    .empty(empty_raddr),
    .rd_data(rd_data_raddr)
);

localparam R_IDLE = 1'b0,
            R_READ = 1'b1;

reg r_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arready <= 1'b0;
    else begin
        wr_data_raddr <= {arburst, araddr};
        arready <= 1'b0;
        if(arvalid && !empty_raddr && !arready) arready <= 1'b1;
        if(arvalid && arready) begin
            rd_en_raddr <= 1'b1;
            arready <= 1'b0;
        end
    end
end

reg [7:0] r_burstcnt;
reg [ADDR_WIDTH-1:0] rd_addr;
reg [1:0] rresp_rg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state = R_IDLE;
    else begin
        case(state)
        R_IDLE: begin
            rvalid <= 1'b0;
            rx_rd_en <= 1'b0;
            if(!empty_raddr) begin
                rd_en_raddr <= 1'b1;
                state <= R_READ;
            end
        end
        R_READ: begin
            
            if(rd_en_raddr) begin
                rd_en_raddr <= 1'b0;
                {r_burstcnt, rd_addr} <= rd_data_raddr;
            end
            
            if(!rvalid || rready) begin
                if(rd_addr[1:0] != 2'b00) begin
                    rdata <= 0;
                    rresp <= 2'b10;
                    rvalid <= 1'b1;
                    if(r_burstcnt==0) state <= R_IDLE;
                    else r_burstcnt <= r_burstcnt-1'b1;
                end else begin
                    case(rd_addr[3:2])
                    2'b00: begin
                        rdata <= ctrl;
                        rresp <= 2'b00;
                        rvalid <= 1'b1;
                        if(r_burstcnt==0) state <= R_IDLE;
                        else begin
                            state <= R_READ;
                            r_burstcnt <= r_burstcnt-1'b1;
                        end
                    end
                    2'b01: begin
                        rdata <= status;
                        rresp <= 2'b00;
                        rvalid <= 1'b1;
                        if(r_burstcnt==0) state <= R_IDLE;
                        else begin
                            state <= R_READ;
                            r_burstcnt <= r_burstcnt-1'b1;
                        end
                    end
                    2'b10: begin
                        rdata <= 0;
                        rresp <= 2'b10;
                        rvalid <= 1'b1;
                        if(r_burstcnt==0) state <= R_IDLE;
                        else begin
                            state <= R_READ;
                            r_burstcnt <= r_burstcnt-1'b1;
                        end
                    end
                    2'b11: begin
                        if(!rx_empty) begin
                            rx_rd_en <= 1'b1;
                            if(rx_rd_en) begin                                
                                rdata <= rx_data;
                                rresp <= 2'b00;
                                rvalid <= 1'b1;
                                state <= (r_burstcnt==0) ? R_IDLE: R_READ;
                                if(r_burstcnt==0) begin
                                    rx_rd_en <= 1'b0;
                                end
                                else begin
                                    r_burstcnt <= r_burstcnt-1'b1;
                                end
                            end
                        end else rvalid <= 1'b0;
                    end
                    default: state <= R_IDLE;
                    endcase
                end
            end
        end
        default: state <= R_IDLE;
        endcase
    end
end


endmodule
