// basic sizes of things
`define WORD	[15:0]
`define RNAME   [5:0]
`define OP	[4:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]
`define REGSIZE [63:0]
`define MEMSIZE [65535:0]

// opcode values, also state numbers
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
`define OPi2f	4'b1011
`define OPld	4'b1100
`define OPst	4'b1101
`define OPjzsz	4'b1110
`define OPli	4'b1111

// extended opcode values
`define OPjz	5'b10000
`define OPsz	5'b10001
`define OPsys	5'b10010
`define OPnop	5'b11111

// source field values for sys and sz
`define SRCsys	6'b000000
`define SRCsz	6'b000001


module decode(opout, regdst, opin, ir);
output reg `OP opout;
output reg `RNAME regdst;
input wire `OP opin;
input `WORD ir;

always @(opin, ir) begin
  if (opin == `OPli) begin
    opout = `OPnop;       // 2nd word of li becomes nop
    regdst = 0;	  	  // no writing
  end else begin
    case (ir `Opcode)
      `OPjzsz: begin
        regdst = 0;		   // no writing
        case (ir `Src)	           // use Src as extended opcode
          `SRCsys: opout = `OPsys;
          `SRCsz: opout = `OPsz;
          default: opout = `OPjz;
        endcase
      end
      `OPst: begin opout = ir `Opcode; regdst <= 0; end
      default: begin opout = ir `Opcode; regdst <= ir `Dest; end
    endcase
  end
end
endmodule


module alu(z, op, x, y);
    output reg `WORD z;
    input `WORD x, y;
    input `OP op;

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

    reg [7:0] recipmantissa;

    reg [7:0] recip [0:127];

    lead0s shiftx (normxshift, x);
    lead0s shiftnegx (normnegxshift, negx);
    lead0s shifty (normyshift, y);
    lead0s shiftm (mulfzshift, mulfrac);
    lead0s shifta (addzshift, addfrac);

    initial begin 
        $readmemh("recip.vmem", recip);
    end

    always @(*) begin
        case (op)
            `OPadd: z = y + x;
            `OPand: z = y & x;
            `OPor:  z = y | x;
            `OPxor: z = y ^ x;
            `OPany: z = (x ? 1 : 0);
            `OPshr: z = (x >> 1);
            `OPdup: z = x;
            `OPinvf:    begin
                if (x == 0) begin
                    z = 0;
                end else begin
                    expnormx = (x[6:0] == 0 ? 254 : 253) - x[14:7];
                    recipmantissa = recip[x[6:0]];
                    z = {x[15], expnormx, recipmantissa[6:0]};
                end
            end
            `OPaddf:    begin
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


module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD ir, srcval, dstval, newpc;
reg ifsquash, rrsquash;
wire `OP op;
wire `RNAME regdst;
wire `WORD res;
reg `OP s0op, s1op, s2op;
reg `RNAME s0src, s0dst, s0regdst, s1regdst, s2regdst;
reg `WORD pc;
reg `WORD s1srcval, s1dstval;
reg `WORD s2val;

always @(reset) begin
  halt = 0;
  pc = 0;
  s0op = `OPnop;
  s1op = `OPnop;
  s2op = `OPnop;
  $readmemh("pipe.vmem0", regfile);
  $readmemh("pipe.vmem1", mainmem);
end

decode mydecode(op, regdst, s0op, ir);
alu myalu(res, s1op, s1srcval, s1dstval);

always @(pc) ir = mainmem[pc];

// compute srcval, with value forwarding... also from 2nd word of li
always @(*) if (s0op == `OPli) srcval = ir; // catch immediate for li
            else srcval = ((s1regdst && (s0src == s1regdst)) ? res :
                           ((s2regdst && (s0src == s2regdst)) ? s2val :
                            regfile[s0src]));

// compute dstval, with value forwarding
always @(*) dstval = ((s1regdst && (s0dst == s1regdst)) ? res :
                      ((s2regdst && (s0dst == s2regdst)) ? s2val :
                       regfile[s0dst]));

// new pc value
always @(*) newpc = (((s1op == `OPjz) && (s1dstval == 0)) ? s1srcval :
                     (pc + 1));

// IF squash? Only for jz... with 2-cycle delay if taken
always @(*) ifsquash = ((s1op == `OPjz) && (s1dstval == 0));

// RR squash? For both jz and sz... extra cycle allows sz to squash li
always @(*) rrsquash = (((s1op == `OPsz) || (s1op == `OPjz)) && (s1dstval == 0));


// Instruction Fetch
always @(posedge clk) if (!halt) begin
  s0op <= (ifsquash ? `OPnop : op);
  s0regdst <= (ifsquash ? 0 : regdst);
  s0src <= ir `Src;
  s0dst <= ir `Dest;
  pc <= newpc;
end

// Register Read
always @(posedge clk) if (!halt) begin
  s1op <= (rrsquash ? `OPnop : s0op);
  s1regdst <= (rrsquash ? 0 : s0regdst);
  s1srcval <= srcval;
  s1dstval <= dstval;
end

// ALU and data memory operations
always @(posedge clk) if (!halt) begin
  s2op <= s1op;
  s2regdst <= s1regdst;
  s2val <= ((s1op == `OPld) ? mainmem[s1srcval] : res);
  if (s1op == `OPst) mainmem[s1srcval] <= s1dstval;
  if (s1op == `OPsys) halt <= 1;
end

// Register Write
always @(posedge clk) if (!halt) begin
  if (s2regdst != 0) regfile[s2regdst] <= s2val;
end
endmodule

module testbench;
//__START TB__
reg reset = 0;
reg clk = 0;
wire halted;
integer i = 0;
processor PE(halted, reset, clk);
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted && (i < 200)) begin
    #10 clk = 1;
    #10 clk = 0;
    i=i+1;
  end
  $finish;
//__END TB__
end
endmodule
