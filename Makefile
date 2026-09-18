.PHONY: test clean

test:
	iverilog -g2012 -s tb_top -o simv rtl/riscv_alu.v tb/tb_top.v
	vvp simv

clean:
	rm -f simv *.vcd
