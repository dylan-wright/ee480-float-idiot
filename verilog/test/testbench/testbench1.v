
    reg `WORD x,y;
    reg `OP op;
    wire `WORD z;
    alu uut(z,op,x,y);

    initial begin
op = `OPi2f;
x = 0;
#1 $display("%h", z);
x = 1;
#1 $display("%h", z);
x = 2;
#1 $display("%h", z);
x = 3;
#1 $display("%h", z);
x = 4;
#1 $display("%h", z);
x = 5;
#1 $display("%h", z);
x = 6;
#1 $display("%h", z);
x = 21235;
#1 $display("%h", z);
x = -13535;
#1 $display("%h", z);
