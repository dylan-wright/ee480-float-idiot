
    reg `WORD x,y;
    reg `OP op;
    wire `WORD z;
    alu uut(z,op,x,y);

    initial begin
op = `OPf2i;
x = 16'h0000;
#10 $display("%h", z);
x = 16'h3f80;
#10 $display("%h", z);
x = 16'h4000;
#10 $display("%h", z);
x = 16'h4040;
#10 $display("%h", z);
x = 16'h4080;
#10 $display("%h", z);
x = 16'h40a0;
#10 $display("%h", z);
x = 16'h40c0;
#10 $display("%h", z);
x = 16'h46a5;
#1 $display("%h", z);
x = 16'hc653;
#1 $display("%h", z);
