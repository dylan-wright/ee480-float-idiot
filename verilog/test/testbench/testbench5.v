
    reg `WORD x,y;
    reg `OP op;
    wire `WORD z;
    alu uut(z,op,x,y);

    initial begin
x = -32768;  //check large negative i2f
op = `OPi2f;
#10;
$display("%h", z);
