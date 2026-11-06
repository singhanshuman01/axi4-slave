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
) (input tx_rclk,
    input rst_n);
    logic                                       tx_empty;
    logic                                       tx_rd_en;
    logic [DATA_WIDTH+$clog2(DATA_WIDTH)-2:0]   tx_rd_data;
endinterface

interface rx_intf#(
    parameter DATA_WIDTH=32
) (
    input rx_wclk,
    input rst_n
);
    logic                   rx_full;
    logic                   rx_wr_en;
    logic [DATA_WIDTH-1:0]  rx_wr_data;
endinterface 

typedef enum bit[1:0] { AXI_READ=2'b00, AXI_WRITE=2'b01, AXI_BOTH=2'b10 } AXI_OP_TYPE;
class txn;
    rand AXI_OP_TYPE op_type;
    rand bit [31:0] waddr;
    rand bit [31:0] raddr;
    rand bit [7:0] wburstlen;
    rand bit [7:0] rburstlen;
    // rand bit [31:0] wdata;

    rand int unsigned pre_delay;
    rand int unsigned ready_delay;

    bit [31:0] wdata [$];
    bit [3:0] wstrb[$];

    bit [31:0] rdata[$];
    bit [1:0] rresp[$];
    bit [1:0] bresp;

    constraint c_len {   wburstlen inside {[0:8]};
                         rburstlen inside {[0:8]}; }
    constraint c_waddr { waddr[31:4]==0;
                         waddr[1:0] dist { 2'b00 := 90, [2'b01:2'b11] :/ 10}; }
    constraint c_raddr { raddr[31:4]==0;
                         raddr[1:0] dist { 2'b00 := 90, [2'b01:2'b11] :/ 10}; }

    constraint c_delay { pre_delay inside {[0:5]}; }
    constraint c_ready_delay { ready_delay inside {[0:5]}; }

    constraint c_op_type { op_type dist {AXI_READ:=1, AXI_WRITE:=1, AXI_BOTH:=1}; }

    function void post_randomize();
        wdata.delete();
        wstrb.delete();
        if(op_type==AXI_WRITE || op_type=AXI_BOTH) begin
            repeat(wburstlen+1) begin
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
        this.gen2drv = gen2drv;
    endfunction

    task send(txn t);
        gen2drv.put(t);
        num_sent++;
    endtask
    task write_word(bit [31:0] addr, bit [31:0] data, bit [3:0] strb);
        txn t = new(); t.op_type=AXI_WRITE;
        t.waddr = addr; t.burstlen=0;
        t.wdata.push_back(data);
        t.wstrb.push_back(strb);
        send(t);
    endtask

    task write_burst(bit[31:0] addr, unsigned int burstl);
        txn t = new();
        t.op_type = AXI_WRITE;
        t.waddr = addr; t.burstlen = burstl-1;
        repeat(burstl) begin
            t.wdata.push_back($urandom());
            t.wstrb.push_back($urandom_range(15));
        end
        send(t);
    endtask

    task read_word(bit[31:0] addr);
        txn t = new();
        t.op_type = AXI_READ;
        t.raddr = addr;
        send(t);
    endtask

    task read_burst(bit [31:0] addr, bit [7:0] rburstlen);
        txn t = new();
        t.op_type = AXI_READ; t.raddr = addr; t.rburstlen = rburstlen-1;
        send(t);
    endtask

    task random_txn(int unsigned n);
        repeat(n) begin
            txn t = new();
            if(!t.randomize()) $fatal(1, "[GEN: packet randomization failed]");
            send(t);
        end
    endtask
endclass

class driver;
    mailbox #(txn) gen2drv;
    virtual slave_intf vif;
    unsigned int num_done = 0;

    function new(virtual slave_intf vif, mailbox #(txn) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task reset_signals();
        vif.awaddr <= 0; vif.awburst <= 0; vif.awvalid <= 0;
        vif.wdata <= 0; vif.wstrb <= 0; vif.wvalid <= 0;
        vif.bready <= 0;
        vif.araddr <= 0; vif.arburst <= 0; vif.arvalid <= 0;
        vif.rready <= 0;
    endtask

    task run();
        txn t;
        reset_signals();
        wait(vif.rst_n === 1'b1);
        repeat(2) @(posedge vif.clk);

        forver begin
            gen2drv.get(t);
            repeat(t.pre_delay) @(posedge vif.clk);
            if(t.op_type==AXI_WRITE) drive_write(t);
            else if(t.op_type==AXI_READ) drive_read(t);
            else begin
                fork
                    drive_write(t);
                    drive_read(t);
                join
            end
            num_done++;
        end
    endtask

    task drive_write(txn t);
        fork
            drive_waddr(t);
            drive_wdata(t);
        join
        drive_resp(t);
    endtask

    task drive_waddr(txn t);
        vif.waddr <= t.waddr;
        vif.awburst <= t.wburstlen;
        vif.awvalid <= 1'b1;
        @(posedge vif.clk);
        while(!vif.awready) @(posedge vif.clk);
        vif.awvalid <= 1'b1;
    endtask

    task drive_wdata(txn t);
        for (int i= 0; i <= t.wburstlen; i++) begin
            vif.wdata <= t.wdata[i];
            vif.wstrb <= t.wstrb[i];
            vif.wvalid <= 1'b1;
            @(posedge vif.clk);
            while(!vif.wready) @(posedge vif.clk);
        end
        vif.wvalid <= 1'b0;
    endtask

    task drive_resp(txn t);
        int cycle_before_timeout = 0;
        repeat(t.ready_delay) @(posedge vif.clk);
        vif.bready <= 1'b1;
        @(posedge vif.clk;
        while(!vif.bvalid) begin
            @(posedge vif.clk);
            cycle_before_timeout++;
            if(cycle_before_timeout > 50) begin
                $display("[DRV]: bvalid timeout");
                break;
            end
        end
        t.resp = vif.bresp;
        vif.bready <= 1'b0;
    endtask

    task drive_read(txn t);
        drive_ar(t);
        drive_r(t);
    endtask

    task drive_ar(txn t);
        vif.araddr <= t.raddr;
        vif.arburst <= t.rburstlen;
        vif.arvalid <= 1'b1;
        @(posedge vif.clk);
        while(!vif.arready) @(posedge vif.clk);
        vif.arvalid <= 1'b0;
    endtask

    task drive_r(txn t);
        int cycle_before_timeout = 0;
        if(t.ready_delay>0) begin
            vif.rready <= 1'b0;
            repeat(t.ready_delay) @(posedge vif.clk);
        end
        for(int i = 0; i < t.rburstlen; i++) begin
            vif.rready <= 1'b1;
            @(posedge vif.clk);
            while(!vif.rvalid) begin
                @(posedge vif.clk);
                cycle_before_timeout++;
                if(cycle_before_timeout > 50) begin
                    $display("[DRV] Error: rvalid timeout");
                    vif.rready <= 1'b0;
                end
            end
            t.rdata.push_back(vif.rdata);
            t.rresp.push_back(vif.rresp);
        end
        vif.rready <= 1'b0;
    endtask
endclass

class monitor;
    virtual slave_intf vif;
    mailbox #(txn) mon2scb;

    bit [39:0] aw_queue[$];
    bit [35:0] w_queue[$];
    txn read_queue[$];

    function new(virtual slave_intf vif, mailbox #(txn) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            if(vif.rst_n !== 1'b1) begin
                aw_queue.delete();
                w_queue.delete();
                continue;
            end

            if(vif.awvalid && vif.awready) aw_queue.push_back({vif.awburst, vif.awaddr});
            if(vif.wvalid && wready) w_queue.push_back({vif.wstrb, vif.wdata});
            if(vif.bvalid && vif.bready) finish_write();
            if(vif.arvalid && vif.arready) start_read();
            if(vif.rvalid && vif.rready) add_packet();
        end
    endtask

    task finish_write();
        txn t;
        t = new();
        bit [39:0] aw;
        bit [35:0] w;
        if(aw_queue.size() == 0) begin
            $display("[MON] finish write called but address queue empty");
            return;
        end
        aw = aw_queue.pop_front();
        w = w_queue.pop_front();
        t.op_type = AXI_WRITE;
        t.waddr = aw[31:0];
        t.wburstlen = aw[39:32];
        for(int i = 0; i<t.wburstlen; i++) begin
            if(w_queue.size() == 0) begin
                $display("[MON] data queue empty");
                return;
            end
            w = w_queue.pop_front();
            t.wdata.push_back(w[31:0]);
            t.wstrb.push_back(w[35:32]);
        end
        t.bresp = vif.bresp;
        mon2scb.put(t);
    endtask

    task start_read();
        txn t;
        t = new();
        t.op_type = AXI_READ;
        t.raddr = vif.araddr;
        t.rburstlen = vif.arburst;
        read_queue.push_back(t);
    endtask

    task add_packet();
        txn t;
        if(read_queue.size() == 0) begin
            $display("[MON] no read pending yet data (rdata line)");
            return;
        end
        t = read_queue[0];
        t.rdata.push_back(vif.rdata);
        t.rresp.push_back(vif.rresp);
        if(t.rdata.size() == t.rburstlen) begin
            read_queue.pop_front();
            mon2scb.put(t);
        end
    endtask
endclass

class scoreboard;
    mailbox #(txn) mon2scb;
    mailbox #(fifo_agent::tx_agent::tx_txn) tx2scb;
    mailbox #(fifo_agent::rx_agent::rx_txn) rx2scb;

    bit [31:0] ctrl_copy;
    bit [39:0] tx_expcopy[$];
    bit [39:0] tx_gotcopy[$];
    bit [31:0] rx_expcopy[$];

    unsigned int pass=0;
    unsigned int fail=0;

    function new(mailbox #(txn) mon2scb, mailbox #(fifo_agent::tx_agent::tx_txn) tx2scb, mailbox #(fifo_agent::rx_agent::rx_txn) rx2scb);
        this.mon2scb = mon2scb;
        this.tx2scb = tx2scb;
        this.rx2scb = rx2scb;
    endfunction

    task run();
        fork
            axi_check();
            tx_check();
            rx_check();
        join_none
    endtask

    task axi_check();
        txn t;
        forever begin
            mon2scb.get(t);
            if(t.op_type==AXI_WRITE) write_check(t);
            if(t.op_type==AXI_READ) read_check(t);
        end
    endtask

    function void print_response(bit [1:0] exp, bit [1:0] actual);
        string s1, s2;
        s1 = (exp===2'b00) ? "OKAY" : "SLVERR";
        s2 = (actual===2'b00) ? "OKAY" : "SLVERR";
        if(exp===actual) begin
            pass++;
            $display("[SCB] Test passed: RESP=%s", s1);
            return;
        end
        fail++;
        $display("[SCB] Test failed: expected RESP=%s, actual RESP=%s", s1, s2);
        return;
    endfunction

    task write_check(txn t);
        if(t.waddr[1:0] === 2'b00) begin
            if(t.waddr[3:2] === 2'b00)begin
                ctrl_copy = t.wdata[t.wdata.size()-1];
                print_response(2'b00, t.bresp);
            end
            else if(t.waddr[3:2] === 2'b10) begin
                foreach(t.wdata[i]) tx_expcopy.push_back({t.wstrb[i], t.wdata[i]});
                print_response(2'b00, t.bresp);
            end
            else print_response(2'b10, t.bresp);
        end else print_response(2'b10, t.bresp);
    endtask

    task tx_check();
        fifo_agent::tx_agent::tx_txn ttx;
        forever begin
            tx2scb.get(ttx);
            tx_gotcopy.push_back({ttx.strb, ttx.data});
            compare_tx();
        end
    endtask

    function void compare_tx();
        bit[35:0] g, e;
        while(tx_gotcopy.size()>0 && tx_expcopy.size()>0) begin
            g = tx_gotcopy.pop_front();
            e = tx_expcopy.pop_front();
            if(g!==e) begin
                $display("[SCB] TX_data mismatch: got=%h exp=%h", g, e);
                fail++;
            end
        end
    endfunction
    
    task read_check(txn t);
        if(t.raddr[1:0] === 2'b00) begin
            if(t.raddr[3:2] === 2'b00) begin
                if(ctrl_copy===t.rdata[t.rdata.size()-1]) pass++;
                else fail++;
                print_response(2'b00, t.rresp[t.rresp.size()-1]);
            end
            else if(t.raddr[3:2] === 2'b01) begin
                foreach(t.rresp[i]) print_response(2'b00, t.rresp[i]);
            end
            else if(t.raddr[3:2] === 2'b11) begin
                foreach(t.rresp[i]) begin
                    print_response(2'b00, t.rresp[i]);
                end
                foreach(t.rdata[i]) begin
                    if(rx_expcopy.size()>0) begin
                        
                        if(t.rdata[i] === rx_expcopy.pop_front()) pass++;
                        else begin
                            $display("[SCB] Read data mismatch");
                            fail++;
                        end
                    end else begin
                        $display("[SCB] Error: No data in expected queue but data came on read channel");
                    end
                end
            end
            else foreach(t.rresp[i]) print_response(2'b10, t.rresp[i]);
        end else foreach(t.rresp[i]) print_response(2'b10, t.rresp[i]);
    endtask

    task rx_check();
        fifo_agent::rx_agent::rx_txn rtx;
        forever begin
            rx2scb.get(rtx);
            rx_expcopy.push_back(rtx.data);
        end
    endtask

endclass

class fifo_agent;
    tx_agent txa;
    rx_agent rxa;
    function new(   virtual tx_intf t_vif,
                    virtual rx_intf r_vif,
                    mailbox #(tx_txn) txm2scb,
                    mailbox #(rx_txn) rxm2scb);
        txa = new(t_vif, txm2scb);
        rxa = new(r_vif, rxm2scb);
    endfunction

    task start();
        fork            
            txa.run();
            rxa.run();
        join_none
    endtask

    class tx_agent;
        class tx_txn;
            bit [31:0] data;
            bit [3:0] strb;
        endclass

        class tx_driver;
            virtual tx_intf t_vif;

            function new(virtual tx_intf t_vif);
                this.t_vif = t_vif;
            endfunction

            task run();
                forever begin
                    if(t_vif.rst_n===1'b0) t_vif.tx_rd_en <= 1'b0;
                    wait(t_vif.rst_n===1'b1);
                    @(posedge t_vif.rclk);
                    t_vif.tx_rd_en <= !t_vif.tx_empty;
                end
            endtask

        endclass

        class tx_monitor;
            virtual tx_intf t_vif;
            mailbox #(tx_txn) txm2scb;

            function new(virtual tx_intf t_vif, mailbox #(tx_txn) txm2scb);
                this.t_vif = t_vif;
                this.txm2scb = txm2scb;
            endfunction

            task run();
                tx_txn  ttx;
                forever begin
                    @(posedge t_vif.rclk);
                    if(t_vif.rst_n !== 1'b0 && t_vif.tx_rd_en===1'b1 && t_vif.tx_empty===1'b0) begin
                        ttx = new();
                        ttx.data = t_vif.tx_rd_data[31:0];
                        ttx.strb = t_vif.tx_rd_data[35:32];
                        txm2scb.put(ttx);
                    end
                end
            endtask
        endclass

        tx_driver tdrv;
        tx_monitor txm;
        function new(virtual tx_intf t_vif, mailbox #(tx_txn) txm2scb);
            tdrv = new(t_vif);
            txm = new(t_vif, txm2scb);
        endfunction

        task run();
            fork
                tdrv.run();
                txm.run();
            join_none
        endtask
    endclass

    class rx_agent;
        class rx_txn;
            bit [31:0] data;
        endclass

        class rx_driver;
            virtual rx_intf r_vif;
            bit [31:0] wr_data;
            function new(virtual rx_intf r_vif);
                this.r_vif = r_vif;
            endfunction

            task run();
                forever begin
                    if(r_vif.rst_n===1'b0) r_vif.rx_wr_en<= 1'b0;
                    wait(r_vif.rst_n===1'b1);
                    @(posedge r_vif.rx_wclk);
                    wr_data = $urandom;
                    r_vif.rx_wr_en <= 1'b1;
                    r_vif.rx_wr_data <= wr_data;
                end
            endtask

        endclass

        class rx_monitor;
            virtual rx_intf r_vif;
            mailbox #(rx_txn) rxm2scb;

            function new(virtual rx_intf r_vif, mailbox #(rx_txn) rxm2scb;):
                this.r_vif = r_vif;
                this.rxm2scb = rxm2scb;
            endfunction

            task run();
                rx_txn rtx;
                forever begin
                    @(posedge r_vif.rx_wclk);
                    if(r_vif.rst_n!==1'b0 && r_vif.rx_wr_en===1'b1 && r_vif.rx_full===1'b0);
                    rtx = new();
                    rtx.data = r_vif.rx_wr_data;
                    rxm2scb.put(rtx);
                end
            endtask
        endclass

        rx_driver rdrv;
        rx_monitor rxm;
        function new(virtual rx_intf r_vif, mailbox #(rx_txn) rxm2scb);
            rdrv = new(r_vif);
            rxm = new(r_vif, rxm2scb);
        endfunction

        task run();
            fork
                rdrv.run();
                rxm.run();
            join_none
        endtask
    endclass
endclass

class agent;

endclass

class env;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    fifo_agent fag;

    mailbox #(txn) gen2drv;
    mailbox #(txn) mon2scb;
    mailbox #(fifo_agent::tx_agent::tx_txn) tx2scb;
    mailbox #(fifo_agent::rx_agent::rx_txn) rx2scb;

    virtual slave_intf vif;
    
    function new(virtual slave_intf vif, virtual tx_intf t_vif, virtual rx_intf r_vif);
        gen2drv = new();
        mon2scb = new();
        tx2scb  = new();
        rx2scb  = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb, tx2scb, rx2scb);
        fag = new(t_vif, r_vif, tx2scb, rx2scb);
    endfunction

    task start();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
            fag.start();
        join_none
    endtask
endclass

class test;

endclass

module tb;

endmodule