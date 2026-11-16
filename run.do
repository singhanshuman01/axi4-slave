if {[file exists work]} {
	vdel -lib work -all
}
vlib work

vlog -sv +cover=bcesft rtl/sync_fifo.v rtl/async_fifo.v rtl/slave.v rtl/top.v tb/full_tb_top.sv

vopt +acc +cover=bcesft work.tb -o tb_opt

vsim -coverage tb_opt +TEST=fifo_backpressure

toggle disable /tb/dut/awaddr[31:4]
toggle disable /tb/dut/araddr[31:4]

coverage save -onexit cov_data3.ucdb
run -all

quit -f
