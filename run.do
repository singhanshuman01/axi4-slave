if {[file exists work]} {
	vdel -lib work -all
}
vlib work

vlog -sv +cover=bcesft rtl/sync_fifo.v rtl/async_fifo.v rtl/slave.v rtl/top.v tb/full_tb_top.sv

vsim -voptargs=+acc -coverage work.tb +TEST=random

coverage save -onexit cov_data.ucdb
run -all

quit -f
