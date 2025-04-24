//----------------------------------------------------------------------------
// NCL_MULT3.sv
// 3×3 NULL Convention Logic unsigned multiplier
//----------------------------------------------------------------------------
// 1) Gate library and type definitions
//----------------------------------------------------------------------------

`timescale 1ns/1ps

// Dual-rail type
typedef struct packed {
  logic rail1;
  logic rail0;
} dual_rail_logic;

// Vector of dual-rail signals
typedef dual_rail_logic dual_rail_logic_vector[];

// th12nx0 (NOR for register)
module th12nx0 (
    input wire a,
    input wire b,
    output reg zb
);

    always @ (a or b) begin
        if (a == 1'b0 && b == 1'b0)
            zb = 1'b1;
        else if (a == 1'b1 || b == 1'b1)
            zb = 1'b0;
        else
            zb = ~(a | b); // NOR fallback
    end

endmodule

// th12x0 (OR)
module th12x0 (
    input wire a,
    input wire b,
    output reg z
);
    always @ (a or b) begin
        if (a == 1'b0 && b == 1'b0)
            z = 1'b0;
        else if (a == 1'b1 || b == 1'b1)
            z = 1'b1;
        else
            z = a | b;
    end
endmodule

// th22x0 (AND)
module th22x0 (
    input  wire a,
    input  wire b,
    output reg  z
); //th22 gate

    always @ (a or b) begin
        if (a == 1'b1 && b == 1'b1)
            z = 1'b1;  // 127.85 ps delay
        else if (a == 1'b0 && b == 1'b0)
            z = 1'b0;   // 193.9 ps delay
        // Else: retain previous value (no change)
    end

endmodule

// th22rx0 (AND with reset)
module th22rx0 (
    input wire a,
    input wire b,
    input wire rst,
    output reg z
);

    always @ (a or b or rst) begin
        if (rst == 1'b1)
           z = 1'b0;
        else if (a == 1'b1 && b == 1'b1)
           z = 1'b1;
        else if (a == 1'b0 && b == 1'b0)
           z = 1'b0;
        // else: z holds its value (inertial delay style)
    end

endmodule

// th23x0 (3-input majority for HA/FA)
  module th23x0 (
    input wire a,
    input wire b,
    input wire c,
    output reg z
);
    always @ (a or b or c) begin
        if (a == 1'b0 && b == 1'b0 && c == 1'b0)
            z = 1'b0;
        else if ((a & b) || (b & c) || (c & a))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

// th33w2x0 (weighted TH33 for FA partial sums)
  module th33w2x0 (
    input wire a,
    input wire b,
    input wire c,
    output reg z
);
    always @ (a or b or c) begin
        if (a == 1'b0 && b == 1'b0 && c == 1'b0)
            z = 1'b0;
        else if (a == 1'b1 && (b == 1'b1 || c == 1'b1))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

// th44x0 (4-input AND)
module th44x0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);
    always @ (a or b or c or d) begin
        if (a & b & c & d)
            z = 1'b1;
        else if (~a & ~b & ~c & ~d)
            z = 1'b0;
        // Else: retain previous value (no change)
    end
endmodule

// th33x0 (3-input AND)
module th33x0 (
    input wire a,
    input wire b,
    input wire c,
    output reg z
);
    always @ (a or b or c) begin
        if (a & b & c)
            z = 1'b1;
        else if (~a & ~b & ~c)
            z = 1'b0;
        // Else: retain previous value (no change)
    end
endmodule

// thand0x0 (4-input OR for AND-0 function rail0)
module thand0x0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);
    always @ (a or b or c or d) begin
        if (~a & ~b & ~c & ~d)
            z = 1'b0;
        else if ((a & b) || (b & c) || (a & d))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

// th24compx0 (TH24comp for HA sum / XOR sum)
module th24compx0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);
    always @ (a or b or c or d) begin
        if (~a & ~b & ~c & ~d)
            z = 1'b0;
        else if ((a | b) & (c | d))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

// thxor0x0 (XOR as THxor0)
module thxor0x0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);
    always @ (a or b or c or d) begin
        if (~a & ~b & ~c & ~d)
            z = 1'b0;
        else if ((a & b) || (c & d))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

// th34w2x0 (weighted TH34w2 for full-adder sum)
  module th34w2x0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);
    always @ (a or b or c or d) begin
        if (~a & ~b & ~c & ~d)
            z = 1'b0;
        else if ((a & b) || (a & c)|| (a & d)|| (b & c & d))
            z = 1'b1;
        // Else: retain previous value (no change)
    end
endmodule

//----------------------------------------------------------------------------
// 1-bit, reset-to-NULL dual-rail register:
//   - on rst=1, q rails → NULL
//   - when Ki=1, pass DATA-phase d→q
//   - when Ki=0, pass NULL-phase d→q
//   - Ko= NOR(q.rail0, q.rail1)
//----------------------------------------------------------------------------

module ncl_reg_null (
  input  dual_rail_logic d,
  input  logic         Ki,
  input  logic         rst,
  output dual_rail_logic q,
  output logic         Ko
);

  // rail0: th22rx0 implements the reset-to-0, AND-style handshaking
  th22rx0 u_th0 (
    .a(d.rail0),
    .b(Ki),
    .rst(rst),
    .z(q.rail0)
  );

  // rail1: same, but reset-to-0 and AND
  th22rx0 u_th1 (
    .a(d.rail1),
    .b(Ki),
    .rst(rst),
    .z(q.rail1)
  );

  // Ko = NOR(q0, q1)
  th12nx0 u_nor (
    .a(q.rail0),
    .b(q.rail1),
    .zb(Ko)
  );

endmodule

//----------------------------------------------------------------------------
// Partial-Product array bits m[0..8]
// This is the first step in the 3x3 mujltiplier
//----------------------------------------------------------------------------

module ncl_and0 (
  input  dual_rail_logic x,
  input  dual_rail_logic y,
  output dual_rail_logic z
);

  // z.rail1 = x.rail1 AND y.rail1  (use th22x0)
  th22x0 g1(
    .a(x.rail1),
    .b(y.rail1),
    .z(z.rail1)
  );

  // z.rail0 = (x.rail0 OR y.rail0) NAND (x.rail1 OR y.rail1)
  //   = thand0x0( x0, y0, x1, y1 )
  thand0x0 g0(
    .a(x.rail0),
    .b(y.rail0),
    .c(x.rail1),
    .d(y.rail1),
    .z(z.rail0)
  );

endmodule

//----------------------------------------------------------------------------
// 3) NCL Half Adder  
//----------------------------------------------------------------------------

module ncl_ha0 (
  input  dual_rail_logic x,
  input  dual_rail_logic y,
  output dual_rail_logic sum,
  output dual_rail_logic carry
);

  // carry = x AND y  (same as ncl_and0)
  ncl_and0 u_and (
    .x(x), .y(y),
    .z(carry)
  );

  // sum = x XOR y
  // rail1: when exactly one rail1 is high  ⇒  use th24compx0
  th24compx0 sum1 (
    .a(x.rail1),
    .b(y.rail1),
    .c(x.rail0),
    .d(y.rail0),
    .z(sum.rail1)
  );
  // rail0: when both rails null or both rails one ⇒ also th24compx0
  th24compx0 sum0 (
    .a(x.rail0),
    .b(y.rail0),
    .c(x.rail1),
    .d(y.rail1),
    .z(sum.rail0)
  );

endmodule

//----------------------------------------------------------------------------
// NCL Full Adder  
//----------------------------------------------------------------------------

module ncl_fa0 (
  input  dual_rail_logic x,
  input  dual_rail_logic y,
  input  dual_rail_logic ci,
  output dual_rail_logic sum,
  output dual_rail_logic co
);

  // first level carry
  dual_rail_logic t1;
  ncl_and0 u_and0(.x(x),  .y(y),  .z(t1));   // t1 = x & y

  // propagate = x XOR y
  dual_rail_logic p;
  th24compx0 u_xor1(.a(x.rail1), .b(y.rail1), .c(x.rail0), .d(y.rail0), .z(p.rail1));
  th24compx0 u_xor0(.a(x.rail0), .b(y.rail0), .c(x.rail1), .d(y.rail1), .z(p.rail0));

  // second‐level carry out = t1 OR (p & ci)
  dual_rail_logic t2;
  ncl_and0 u_and1(.x(p),  .y(ci), .z(t2));   // t2 = p & ci

  // co.rail1 = t1.rail1 OR t2.rail1
  th12x0 u_or1(.a(t1.rail1), .b(t2.rail1), .z(co.rail1));
  // co.rail0 = NOR( t1.rail0 , t2.rail0 )
  th12nx0 u_nor0(.a(t1.rail0), .b(t2.rail0), .zb(co.rail0));

  // sum = p XOR ci  (same pattern as HA)
  th24compx0 u_sum1(.a(p.rail1), .b(ci.rail1), .c(p.rail0), .d(ci.rail0), .z(sum.rail1));
  th24compx0 u_sum0(.a(p.rail0), .b(ci.rail0), .c(p.rail1), .d(ci.rail1), .z(sum.rail0));

endmodule

//----------------------------------------------------------------------------
// 2) Top-level 3×3 multiplier
//----------------------------------------------------------------------------

module NCL_MULT3 (
  // dual-rail A inputs
  input  logic Ai0_rail1, Ai0_rail0,
  input  logic Ai1_rail1, Ai1_rail0,
  input  logic Ai2_rail1, Ai2_rail0,
  // dual-rail B inputs
  input  logic Bi0_rail1, Bi0_rail0,
  input  logic Bi1_rail1, Bi1_rail0,
  input  logic Bi2_rail1, Bi2_rail0,
  // hand-shaking
  input  logic Ki,
  input  logic rst,
  // dual-rail product outputs
  output logic Po0_rail1, Po0_rail0,
  output logic Po1_rail1, Po1_rail0,
  output logic Po2_rail1, Po2_rail0,
  output logic Po3_rail1, Po3_rail0,
  output logic Po4_rail1, Po4_rail0,
  output logic Po5_rail1, Po5_rail0,
  // acknowledge
  output logic Ko
);

  // 2-bit vectors to reconstruct your inputs and outputs
  dual_rail_logic [2:0] Ai, Bi;
  dual_rail_logic [5:0] Po;

  // A inputs
  assign Ai[0].rail1 = Ai0_rail1;
  assign Ai[0].rail0 = Ai0_rail0;
  assign Ai[1].rail0 = Ai1_rail0;
  assign Ai[1].rail1 = Ai1_rail1;
  assign Ai[2].rail1 = Ai2_rail1;
  assign Ai[2].rail0 = Ai2_rail0;

  // B inputs
  assign Bi[0].rail1 = Bi0_rail1;
  assign Bi[0].rail0 = Bi0_rail0;
  assign Bi[1].rail1 = Bi1_rail1;
  assign Bi[1].rail0 = Bi1_rail0;
  assign Bi[2].rail1 = Bi2_rail1;
  assign Bi[2].rail0 = Bi2_rail0;

  // Internal dual-rail vectors for registration stages:
  dual_rail_logic [2:0] A, B;   // post-input registers
  dual_rail_logic [2:0] C, D;   // post-intermediate registers
  dual_rail_logic [7:0] Po_pre; // Stage 2 registers
  dual_rail_logic [5:0] P;      // Stage 3 registers
  
  // handshaking between stages
  logic ko_in, ko_mid, ko_mid2;
  dual_rail_logic c1, c2, c3, c4, c5, c6;
  dual_rail_logic t1, t2;

   // stage 1: input regs
  ncl_reg_null rA0(.d(Ai[0]), .Ki(Ki),      .rst(rst), .q(A[0]), .Ko(ko_in));
  ncl_reg_null rA1(.d(Ai[1]), .Ki(ko_in),   .rst(rst), .q(A[1]), .Ko(ko_mid));
  ncl_reg_null rA2(.d(Ai[2]), .Ki(ko_mid),  .rst(rst), .q(A[2]), .Ko(ko_mid2));
  ncl_reg_null rB0(.d(Bi[0]), .Ki(Ki),      .rst(rst), .q(B[0]), .Ko());
  ncl_reg_null rB1(.d(Bi[1]), .Ki(Ki),      .rst(rst), .q(B[1]), .Ko());
  ncl_reg_null rB2(.d(Bi[2]), .Ki(Ki),      .rst(rst), .q(B[2]), .Ko());

  // 3×3 array: partial products m0..m8
  dual_rail_logic m[8:0];
  ncl_and0 and00(.x(A[0]), .y(B[0]), .z(m[0]));
  ncl_and0 and10(.x(A[1]), .y(B[0]), .z(m[1]));
  ncl_and0 and20(.x(A[2]), .y(B[0]), .z(m[2]));
  ncl_and0 and01(.x(A[0]), .y(B[1]), .z(m[3]));
  ncl_and0 and11(.x(A[1]), .y(B[1]), .z(m[4]));
  ncl_and0 and21(.x(A[2]), .y(B[1]), .z(m[5]));
  ncl_and0 and02(.x(A[0]), .y(B[2]), .z(m[6]));
  ncl_and0 and12(.x(A[1]), .y(B[2]), .z(m[7]));
  ncl_and0 and22(.x(A[2]), .y(B[2]), .z(m[8]));
  
  // reduction: diagonal adders
  ncl_ha0 ha1 (.x(m[1]), .y(m[3]), .sum(P[1]), .carry(c1));
  ncl_fa0 fa1 (.x(m[2]), .y(m[4]), .ci(c1), .sum(t1), .co(c2));
  ncl_ha0 ha2 (.x(t1), .y(m[6]), .sum(P[2]), .carry(c3));

  // stage 2 registers (pipeline stage 2 handshake chain)
  logic ko_stage2a, ko_stage2b, ko_stage2c, ko_stage2d, ko_stage2e, ko_stage2f, ko_stage2g, ko_stage2h;
  ncl_reg_null rP0(.d(m[0]), .Ki(ko_mid2),    .rst(rst), .q(Po_pre[0]), .Ko(ko_stage2a));
  ncl_reg_null rP1(.d(P[1]), .Ki(ko_stage2a), .rst(rst), .q(Po_pre[1]), .Ko(ko_stage2b));
  ncl_reg_null rP2(.d(P[2]), .Ki(ko_stage2b), .rst(rst), .q(Po_pre[2]), .Ko(ko_stage2c));
  ncl_reg_null rP3(.d(c3), .Ki(ko_stage2c), .rst(rst), .q(Po_pre[3]), .Ko(ko_stage2d));
  ncl_reg_null rP4(.d(c2), .Ki(ko_stage2d), .rst(rst), .q(Po_pre[4]), .Ko(ko_stage2e));
  ncl_reg_null rP5(.d(m[7]), .Ki(ko_stage2e), .rst(rst), .q(Po_pre[5]), .Ko(ko_stage2f));
  ncl_reg_null rP6(.d(m[5]), .Ki(ko_stage2f), .rst(rst), .q(Po_pre[6]), .Ko(ko_stage2g));
  ncl_reg_null rP7(.d(m[8]), .Ki(ko_stage2f), .rst(rst), .q(Po_pre[7]), .Ko(ko_stage2h));

  ncl_fa0 fa2 (.x(Po_pre[4]), .y(Po_pre[5]), .ci(Po_pre[3]), .sum(t2), .co(c4));
  ncl_ha0 ha3 (.x(Po_pre[6]), .y(t2), .sum(P[3]), .carry(c5));
  ncl_ha0 fa3 (.x(Po_pre[7]), .y(c4), .sum(P[4]), .carry(c6));
  
  // stage 3 output regs & completion tree
  logic ko_out0, ko_out1, ko_out2, ko_out3, ko_out4, ko_out5;
  
  ncl_reg_null rQ0(.d(Po_pre[0]), .Ki(ko_stage2f), .rst(rst), .q(Po[0]), .Ko(ko_out0));
  ncl_reg_null rQ1(.d(Po_pre[1]), .Ki(ko_stage2f), .rst(rst), .q(Po[1]), .Ko(ko_out1));
  ncl_reg_null rQ2(.d(Po_pre[2]), .Ki(ko_stage2f), .rst(rst), .q(Po[2]), .Ko(ko_out2));
  ncl_reg_null rQ3(.d(P[3]), .Ki(ko_stage2f), .rst(rst), .q(Po[3]), .Ko(ko_out3));
  ncl_reg_null rQ4(.d(P[4]), .Ki(ko_stage2f), .rst(rst), .q(Po[4]), .Ko(ko_out4));
  ncl_reg_null rQ5(.d(c6), .Ki(ko_stage2f), .rst(rst), .q(Po[5]), .Ko(ko_out5));
  
  // completion tree to generate final Ko
  wire ct10, ct11, ct12;
  wire ct20;

  th22x0 cstg1(.a(ko_out0), .b(ko_out1), .z(ct10));
  th22x0 cstg2(.a(ko_out2), .b(ko_out3), .z(ct11));
  th22x0 cstg3(.a(ct10),    .b(ct11),    .z(ct20));
  th22x0 cstg4(.a(ko_out4), .b(ko_out5), .z(ct12));
  th22x0 cstg5(.a(ct20),    .b(ct12),    .z(Ko));   // final acknowledge

  // unpack P to outputs
  assign Po0_rail1 = Po[0].rail1;
  assign Po0_rail0 = Po[0].rail0;
  assign Po1_rail1 = Po[1].rail1;
  assign Po1_rail0 = Po[1].rail0;
  assign Po2_rail1 = Po[2].rail1;
  assign Po2_rail0 = Po[2].rail0;
  assign Po3_rail1 = Po[3].rail1;
  assign Po3_rail0 = Po[3].rail0;
  assign Po4_rail1 = Po[4].rail1;
  assign Po4_rail0 = Po[4].rail0;
  assign Po5_rail1 = Po[5].rail1;
  assign Po5_rail0 = Po[5].rail0;

endmodule