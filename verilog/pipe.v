`define WORD [15:0]
`define REGADDR [5:0]
`define REGSIZE [63:0]
`define MEMSIZE [32767:0]
`define ALUOP [3:0]

`define OPadd	4'b0000
`define OPinvf	4'b0001
`define OPaddf	4'b0010
`define OPmulf	4'b0011
`define OPand	4'b0100
`define OPor	4'b0101
`define OPxor	4'b0110
`define OPany	4'b0111
`define OPdup	4'b1000
`define OPshr	4'b1001
`define OPf2i	4'b1010
`define OPi2f	4'b1011 // last ALU op
`define OPld	4'b1100 // first non-ALU op
`define OPst	4'b1101
`define OPjzsz	4'b1110
`define OPli	4'b1111

`define SIGN [15];
`define EXP [14:7];
`define SIG [6:0];

module Alu(z, x, y, op);
    output reg `WORD z;
    input `WORD x, y;
    input `ALUOP op;

    wire [4:0] normxshift, normyshift, mulfzshift, addzshift;
    reg `WORD normx;
    reg [7:0] expnormx;
    reg [7:0] signormx;
    reg [15:0] mulfrac;
    reg `WORD normz;

    reg addsign;
    reg `WORD denorm;
    reg `WORD addfrac;
    reg [7:0] diff;

    lead0s shiftx (normxshift, x);
    lead0s shifty (normyshift, y);
    lead0s shiftm (mulfzshift, mulfrac);
    lead0s shifta (addzshift, addfrac);

    always @(*) begin
        case (op)
            `OPadd: z = y + x;
            `OPand: z = y & x;
            `OPor:  z = y | x;
            `OPxor: z = y ^ x;
            `OPany: z = (x ? 1 : 0);
            `OPshr: z = (x >> 1);
            `OPdup: z = x;
            `OPinvf: ;
            `OPaddf:    begin
                //$display("%h %h",x,y);
                if (x == 0) begin
                    z = y;
                end else if (y == 0) begin
                    z = x;
                end else begin
                    if (x[14:7] < y[14:7]) begin
                        diff = (y[14:7]-127)-(x[14:7]-127);
                        addfrac = {({1'b1,x[6:0]}>>diff)+{1'b1,y[6:0]}, 8'b0};
                        normz = addfrac<<addzshift+1;
                        addsign=0;
                        expnormx = y[14:7];
                    end else if (x[14:7] > y[14:7]) begin
                        diff = (x[14:7]-127)-(y[14:7]-127);
                        addfrac = {({1'b1,x[6:0]})+({1'b1,y[6:0]}>>diff), 8'b0};
                        normz = addfrac<<addzshift+1;
                        addsign=0;
                        if (diff == 1) begin
                            expnormx = x[14:7]+diff;
                        end else begin
                            expnormx = x[14:7];
                        end
                    end else begin
                        addfrac = {1'b1,x[6:0]}+{1'b1,y[6:0]};
                        normz = addfrac<<addzshift+1;
                        addsign = 0;
                        diff = 0;
                        if (addzshift == 0) begin
                            expnormx = (addzshift+1)+127;
                        end else begin
                            expnormx = (x[14:7]-127 + y[14:7]-127)+127;
                        end
                    end

                    z = {addsign,expnormx,normz[15:9]};
                end
            end
            `OPmulf: begin
                if (x == 0 || y == 0) begin
                    z = 0;
                end else begin
                    mulfrac = {1'b1,x[6:0]}*{1'b1,y[6:0]};
                    //$display("%b %b", x[6:0], y[6:0]);
                    //$display("%d", mulfzshift+1);
                    //$display("%b", mulfrac<<mulfzshift+1);
                    normz = mulfrac<<mulfzshift+1;
                    //$display("%b", normz);
                    
                    if (mulfzshift == 0) begin
                        expnormx = (x[14:7]-127 + y[14:7]-127 + mulfzshift+1)+127;
                    end else begin
                        expnormx = (x[14:7]-127 + y[14:7]-127)+127;
                    end
                    z = {x[15]^y[15], expnormx, normz[15:9]};
                end
            end
            `OPf2i: begin
                expnormx = -(x[14:7]-127-7);
                z = {1'b1,x[6:0]}>>expnormx;
            end
            `OPi2f: begin
                if (x == 0) begin
                    z = 0;
                end else begin
                    normx = x<<normxshift+1;
                    //expnormx = (8-normxshift)+127+7;
                    expnormx = 127+7+8-(normxshift);
                    z = {x[15], expnormx, normx[15:9]};
                end
            end
        endcase
    end
endmodule


module lead0s (d,s);
    input wire `WORD s;
    output reg [4:0] d;
    reg [7:0] s8; reg [3:0] s4; reg [1:0] s2;
    always @(*) begin
        if (s[15:0] == 0) begin 
            d = 16;
        end else begin
            d[4] = 0;
            {d[3],s8} = ((|s[15:8]) ? {1'b0,s[15:8]} : {1'b1,s[7:0]});
            {d[2],s4} = ((|s8[7:4]) ? {1'b0,s8[7:4]} : {1'b1,s8[3:0]});
            {d[1],s2} = ((|s4[3:2]) ? {1'b0,s4[3:2]} : {1'b1,s4[1:0]});
            d[0] = ~s2[1];
        end
    end
endmodule

module bench;
    reg `WORD x,y;
    reg `ALUOP op;
    wire `WORD z;
    Alu uut(z,x,y,op);

    initial begin
        //__START TB__
        $dumpfile("dump.vcd");
        $dumpvars(0, uut);

        //__END TB__
    end
endmodule
