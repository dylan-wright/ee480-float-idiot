
    reg `WORD x,y;
    reg `OP op;
    wire `WORD z;
    alu uut(z,op,x,y);

    initial begin
op = `OPinvf;
x = 16'h3f80;
#10;
$display("%h", z);
x = 16'h4000;
#10;
$display("%h", z);
x = 16'h4040;
#10;
$display("%h", z);
x = 16'hbf80;
#10;
$display("%h", z);
x = 16'hc2f0;
#10;
$display("%h", z);
