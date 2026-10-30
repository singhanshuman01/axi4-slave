interface slave_intf #(
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32,
    parameter MEM_DEPTH=16
) (
    input logic clk
);
    logic                           rst_n;
    logic [ADDR_WIDTH-1:0]          awaddr;
    logic [7:0]                     awburst;
    logic                           awvalid;
    logic                           awready;
    logic [DATA_WIDTH-1:0]          wdata;
    logic [$clog2(DATA_WIDTH)-1:0]  wstrb;
    logic                           wvalid;
    logic                           wready;
    logic [1:0]                     bresp;
    logic                           bvalid;
    logic                           bready;
    logic [ADDR_WIDTH-1:0]          araddr;
    logic [7:0]                     arburst;
    logic                           arvalid;
    logic                           arready;
    logic [DATA_WIDTH-1:0]          rdata;
    logic                           rresp;
    logic                           rvalid;
    logic                           rready;
endinterface

interface tx_intf #(
    parameter DATA_WIDTH=32
) (tx_rclk);
    logic                                       tx_empty;
    logic                                       tx_rd_en;
    logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0]   tx_rd_data;
endinterface

interface rx_intf#(
    parameter DATA_WIDTH=32
) (
    input rx_wclk
);
    logic                   rx_full;
    logic                   rx_wr_en;
    logic [DATA_WIDTH-1:0]  rx_wr_data;
endinterface 

typedef enum bit { AXI_READ=1'b0, AXI_WRITE=1'b1 } AXI_OP_TYPE;
class txn #(int DATA_WIDTH = 32, int ADDR_WIDTH = 32);
    rand AXI_OP_TYPE op_type;
    rand bit [31:0] waddr;
    rand bit [31:0] raddr;
    rand bit [7:0] burstlen;
    rand bit [31:0] wdata;

    rand int unsigned pre_delay;
    rand int unsigned ready_delay;

    bit [31:0] wdata [$];
    bit [3:0] wstrb[$];

    bit [31:0] rdata[$];
    bit [1:0] rresp[$];
    bit [1:0] bresp;

    constraint c_len { burstlen inside {[0:8]}; }
    constraint c_waddr { waddr[31:4]==0;
                        waddr[1:0] dist { 2'b00 := 90, [2'b01:2'b11] :/ 10}; }
    constraint c_raddr { raddr[31:4]==0;
                        raddr[1:0] dist { 2'b00 := 90, [2'b01:2'b11] :/ 10}; }

    constraint c_delay { pre_delay inside {[0:5]}; }
    constraint c_ready_delay { ready_delay inside {[0:5]}; }

    constraint c_op_type { op_type dist {AXI_READ:=1, AXI_WRITE:=1}; }

    function void post_randomize();
        wdata.delete();
        wstrb.delete();
        if(op_type==AXI_WRITE) begin
            repeat(burstlen+1) begin
                wdata.push_back($urandom());
                wstrb.push_back($urandom_range(15));
            end
        end

    endfunction

    function string resp_name(bit [1:0] r);
        case (r)
        2'b00:   return "OKAY";
        2'b10:   return "SLVERR";
        default: return $sformatf("RESP_%b", r);
        endcase
    endfunction
endclass

class generator;
    mailbox #(txn) gen2drv;
    int unsigned num_sent=0;

    function new(mailbox #(txn) gen2drv);
        this.
endclass

class driver;

endclass

class monitor;

endclass

class scoreboard;

endclass

class agent;

endclass

class env;

endclass

class test;

endclass

module tb;

endmodule