vlib work

vcom -quiet fifo.vhd
vcom -2008 -quiet Arbiter.vhd
vcom -2008 -quiet Splitter.vhd
vcom -2008 -quiet types.vhd
vcom -2008 -quiet Router2.vhd
vcom -2008 -quiet Multi-router.vhd
vcom -2008 -quiet tb_noc.vhd

onbreak {resume}
vsim -do sim.do -novopt tb_noc