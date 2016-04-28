op = `OPaddf;
x = 16'h4040;
y = 16'h4040;
#1 $display("%h", z);
x = 16'h4120;
y = 16'h41a0;
#1 $display("%h", z);
x = 16'h0000;
y = 16'h0000;
#1 $display("%h", z);
x = 16'h0000;
y = 16'h3f80; //1
#1 $display("%h", z);
x = 16'h4040;
#1 $display("%h", z);
x = 16'h4120;
#1 $display("%h", z);
x = 16'h4040;
y = 16'hc040;
#1 $display("%h", z);
x = 16'hc4a7; //-1342.5
y = 16'hc014; //-2.32
#1 $display("%h", z);
x = 16'hc4a4; //-1312.5
y = 16'h3f00; //.5
#1 $display("%h", z);
