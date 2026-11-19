if {[file exists work]} {
	vdel -lib work -all
}
vlib work

vlog -sv +cover=bcesft rtl/sync_fifo.v rtl/async_fifo.v rtl/slave.v rtl/top.v tb/full_tb_top.sv

vopt +acc +cover=bcesft work.tb -o tb_opt

vsim -coverage tb_opt +TEST=addr_test

toggle disable /tb/dut/awaddr[31:4]
toggle disable /tb/dut/araddr[31:4]
toggle disable /tb/dut/axi4slave/raddr_fifo/rst_n
toggle disable /tb/dut/axi4slave/raddr_fifo/rd_data[31:4]
toggle disable /tb/dut/axi4slave/raddr_fifo/rd_data[39:36]
toggle disable /tb/dut/axi4slave/raddr_fifo/wr_data[31:4]
toggle disable /tb/dut/axi4slave/raddr_fifo/wr_data[39:36]

toggle disable /tb/dut/axi4slave/waddr_fifo/rst_n
toggle disable /tb/dut/axi4slave/waddr_fifo/rd_data[39:36]
toggle disable /tb/dut/axi4slave/waddr_fifo/wr_data[39:36]
toggle disable /tb/dut/axi4slave/waddr_fifo/rd_data[31:4]
toggle disable /tb/dut/axi4slave/waddr_fifo/wr_data[31:4]

toggle disable /tb/dut/axi4slave/arburst[7:4]
toggle disable /tb/dut/axi4slave/awburst[7:4]
toggle disable /tb/dut/axi4slave/bresp[0]
toggle disable /tb/dut/axi4slave/rresp[0]
toggle disable /tb/dut/axi4slave/burstcnt[7:5]
toggle disable /tb/dut/axi4slave/r_burstcnt[7:4]
toggle disable /tb/dut/axi4slave/rd_addr[31:4]
toggle disable /tb/dut/axi4slave/wr_addr[31:4]
toggle disable /tb/dut/axi4slave/status[31:3]
toggle disable /tb/dut/axi4slave/status[0]

coverage save -onexit cov_data4.ucdb
run -all

quit -f
