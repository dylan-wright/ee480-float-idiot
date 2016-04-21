all:
	cd IDIOT/; make
	cd doc/; make
	cd verilog/; make
clean:
	cd IDIOT/; make clean
	cd doc/; make clean
	cd verilog/; make clean
