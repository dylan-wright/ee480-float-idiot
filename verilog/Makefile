all: float mulf i2f

float: pipe.v
	iverilog -o float pipe.v
	vvp float

mulf: mulf.c
	gcc -o mulf mulf.c
i2f: i2f.c
	gcc -o i2f i2f.c

clean:
	rm mulf i2f float dump.vcd
