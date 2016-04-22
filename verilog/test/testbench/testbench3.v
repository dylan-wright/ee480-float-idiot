op = `OPmulf;
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
