x = 3;
op = `OPi2f;
#10;
$display("%h", z);
x = 16'h4040;
op = `OPf2i;
#10;
$display("%h", z);
x = -10;  //check negative i2f
op = `OPi2f;
#10;
$display("%h", z);
x = 16'hc120; //check negative f2i
op = `OPf2i;
#10;
$display("%h", z);
x = -65535;  //check large negative i2f
op = `OPi2f;
#10;
$display("%h", z);
x = 16'hc77f; //check large negative f2i
op = `OPf2i;
#10;
$display("%h", z);
