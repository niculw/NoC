## ##############################################################
##
##	Title		: Compilation and simulation
##
##	Developers	: Nicolai Weis Hansen
##
##	Revision	: NoC in fpga
##
##  Script starts simulation
#################################################################

add wave /tb_noc/clock
add wave /tb_noc/reset
add wave /tb_noc/valid_in_local
add wave /tb_noc/data_in_local
add wave /tb_noc/valid_out_local
add wave /tb_noc/data_out_local

run 2000ns

WaveRestoreZoom {0 ns} {2000 ns}