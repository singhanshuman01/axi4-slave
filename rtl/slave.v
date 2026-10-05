module slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input   clk,
    input   rst_n,

    input [ADDR_WIDTH-1:0]          awaddr,
    input                           awvalid,
    output reg                      awready,

    input [DATA_WIDTH-1:0]          wdata,
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
    .DATA_WIDTH(DATA_WIDTH),
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



reg wr_en_wdata, rd_en_wdata;
wire full_wdata, empty_wdata;
reg [ADDR_WIDTH-1:0] wr_data_wdata;
wire [ADDR_WIDTH-1:0] rd_data_wdata;
sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(16)
) wdata_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en_wdata),
    .wr_data(wr_data_wdata),
    .full(full_wdata),
    .rd_en(rd_en_wdata),
    .empty(empty_wdata),
    .rd_data(rd_data_wdata)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        awready <= 1'b0;
        wready <= 1'b0;
        bvalid <= 1'b0;
    end else begin
        wr_en_waddr <= 1'b0;
        awready <= 1'b0;
        if(awvalid && !awready && !full_waddr) awready <= 1'b1;
        if(awvalid && awready) begin
            wr_en_waddr <= 1'b1;
            wr_data_waddr <= awaddr;
        end

        wready <= 1'b0;
        wr_en_wdata <= 1'b0;
        if(wvalid && !wready && !full_wdata) wready <= 1'b1;
        if(wvalid && wready) begin
            wr_en_wdata <= 1'b1;
            wr_data_wdata <= wdata;
        end

        tx_wr_en <= 1'b0;
        rd_en_waddr <= 1'b0;
        rd_en_wdata <= 1'b0;
        if(bvalid && bready) bvalid <= 1'b0;
        if(!empty_waddr && !empty_wdata && (!bvalid || bready)) begin
            if(rd_data_waddr[1:0] != 2'b00) begin
                bresp <= 2'b10;
                bvalid <= 1'b1;
            end else begin
                case (rd_data_waddr[3:2])
                    2'b00: begin
                        ctrl <= rd_data_wdata;
                        bresp <= 2'b00;
                        bvalid <= 1'b1;
                    end

                    2'b10: begin
                        tx_wr_en <= 1'b1;
                        tx_data <= rd_data_wdata;
                    end

                    default: begin
                        bresp <= 2'b10;
                        bvalid <= 1'b1;
                    end
                endcase
                rd_en_waddr <= 1'b1;
                rd_en_wdata <= 1'b1;
            end
        end
    end
end

reg [ADDR_WIDTH-1:0] raddr_latch;
reg have_raddr;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        arready <= 1'b0;
        rvalid <= 1'b0;
        have_raddr <= 1'b0;
    end else begin
        arready <= 1'b0;
        if(arvalid && !rx_empty) arready <= 1'b1;

        have_raddr <= 1'b0;
        if(arvalid && arready) begin
            raddr_latch <= araddr;
            have_raddr <= 1'b1;
        end

        rx_rd_en <= 1'b0;
        if(rvalid && rready) rvalid <= 1'b0;
        if(have_raddr) begin
            if((raddr_latch[1:0] != 2'b00) || (raddr_latch[3:2]==2'b10)) begin
                rresp <= 2'b10;
                rvalid <= 1'b1;
            end else begin
                case (raddr_latch[3:2])
                    2'b00: rdata <= ctrl;
                    2'b01: rdata <= status;
                    2'b11: begin
                        rdata <= rx_data;
                        rx_rd_en <= 1'b1;
                    end
                    default: ;
                endcase
                rresp <= 2'b00;
                rvalid <= 1'b1;
            end
        end
    end
end

endmodule