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

    wire [4:0] normxshift, normyshift, mulfzshift, addzshift, normnegxshift;
    reg `WORD negx;
    reg `WORD normx;
    reg [7:0] expnormx;
    reg [7:0] signormx;
    reg [15:0] mulfrac;
    reg `WORD normz;

    reg addsign;
    reg `WORD denorm;
    reg `WORD norm;
    reg `WORD addfrac;
    reg [7:0] diff;

    lead0s shiftx (normxshift, x);
    lead0s shiftnegx (normnegxshift, negx);
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
                    if (x[14:7] == y[14:7]) begin
                        norm = {1'b1, x[6:0]};
                        denorm = {1'b1, x[6:0]};
                        addsign = x[15]&y[15];
                        if (x[15]^y[15] & x[6:0] == y[6:0]) begin 
                            addfrac = 0;
                            expnormx = 0;
                        end else begin
                            addfrac = norm+denorm;
                            expnormx = (x[14:7]<y[14:7] ? y[14:7] : x[14:7]) + 
                                        (8-addzshift);
                        end
                    end else begin
                        if (x[14:7] < y[14:7]) begin
                            norm = {1'b1, y[6:0]};
                            denorm = {1'b1, x[6:0]} >> (y[14:7]-x[14:7]);
                            addsign = y[15];
                        end else if (x[14:7] > y[14:7]) begin
                            norm = {1'b1, x[6:0]};
                            denorm = {1'b1, y[6:0]} >> (x[14:7]-y[14:7]);
                            addsign = x[15];
                        end
                        expnormx = (x[14:7]<y[14:7] ? y[14:7] : x[14:7]) + 
                                    (8-addzshift);
                        addfrac = norm+denorm;
                    end
                    normz = addfrac<<addzshift+1;
                    z = {addsign,expnormx,normz[15:9]};
                end
            end
            `OPmulf: begin
                if (x == 0 || y == 0) begin
                    z = 0;
                end else begin
                    mulfrac = {1'b1,x[6:0]}*{1'b1,y[6:0]};
                    normz = mulfrac<<mulfzshift+1;
                    expnormx = x[14:7] + y[14:7] - 127;
                    if (mulfrac[15]) begin
                        expnormx += 1;
                    end
                    z = {x[15]^y[15], expnormx, normz[15:9]};
                end
            end
            `OPf2i: begin
                expnormx = x[14:7]-127-7;
                if (expnormx[7]) begin
                    expnormx = ~expnormx+1;
                    z = {1'b1,x[6:0]}>>expnormx;
                end else begin
                    z = {1'b1,x[6:0]}<<expnormx;
                end
                if (x[15]) begin
                    z = ~z+1;
                end
            end
            `OPi2f: begin
                if (x == 0) begin
                    z = 0;
                end else begin
                    if (x[15]) begin
                        negx = ~x+1;
                        normx = negx<<normnegxshift+1;
                        expnormx = 127+7+8-(normnegxshift);
                    end else begin
                        normx = x<<normxshift+1;
                        expnormx = 127+7+8-(normxshift);
                    end
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
