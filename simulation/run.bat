@REM ------------------------------------------------------
@REM Simple DOS batch file to compile and run the testbench
@REM Ver 1.0 HT-Lab 2002
@REM Tested with Modelsim 5.8c
@REM ------------------------------------------------------
vlib work

@REM Compile HTL8259 

vcom -93 -quiet -work work ../rtl/pulselevel.vhd
vcom -93 -quiet -work work ../rtl/frontend_rtl.vhd
vcom -93 -quiet -work work ../rtl/priority_rtl.vhd
vcom -93 -quiet -work work ../rtl/backend_rtl.vhd
vcom -93 -quiet -work work ../rtl/wrctrl.vhd
vcom -93 -quiet -work work ../rtl/ctrl.vhd
vcom -93 -quiet -work work ../rtl/htl8259a.vhd

@REM Compile Testbench

vcom -93 -quiet -work work ../testbench/utils.vhd
vcom -93 -quiet -work work ../testbench/htl8259_tester.vhd
vcom -93 -quiet -work work ../testbench/htl8259_tb.vhd

@REM Run simulation
vsim HTL8259_tb -c -do "set StdArithNoWarnings 1; run -all; quit -f"
