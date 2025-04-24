`timescale 1ns/1ps
module tb;

  // ------------- DUT ports -------------
  logic Ai0_rail1, Ai0_rail0, Ai1_rail1, Ai1_rail0, Ai2_rail1, Ai2_rail0;
  logic Bi0_rail1, Bi0_rail0, Bi1_rail1, Bi1_rail0, Bi2_rail1, Bi2_rail0;
  logic Ki, rst;

  logic Po0_rail1, Po0_rail0, Po1_rail1, Po1_rail0, Po2_rail1, Po2_rail0;
  logic Po3_rail1, Po3_rail0, Po4_rail1, Po4_rail0, Po5_rail1, Po5_rail0;
  logic Ko;

  // ------------- DUT -------------------
  NCL_MULT3 dut (.*);   // SystemVerilog .* shorthand (all names match)

  // helper to drive one DATA value then NULL spacer
  task apply_DR_input(
        input logic a1, a0,
        input logic b1, b0);
    begin
      {Ai0_rail1,Ai0_rail0,Bi0_rail1,Bi0_rail0} = 4'b0000;  // NULL
      #50;
      {Ai0_rail1,Ai0_rail0} = {a1,a0};
      {Bi0_rail1,Bi0_rail0} = {b1,b0};
      #100;                                  // hold DATA
    end
  endtask
  
  task automatic encode_bit (input bit v, output logic r1, r0);
    {r1,r0} = v ? 2'b10 : 2'b01;   // 10 = “1”, 01 = “0”
  endtask
  
  task automatic drive_operands (input [2:0] A, input [2:0] B);
    // A2 A1 A0
    encode_bit(A[0], Ai0_rail1, Ai0_rail0);
    encode_bit(A[1], Ai1_rail1, Ai1_rail0);
    encode_bit(A[2], Ai2_rail1, Ai2_rail0);
    // B2 B1 B0
    encode_bit(B[0], Bi0_rail1, Bi0_rail0);
    encode_bit(B[1], Bi1_rail1, Bi1_rail0);
    encode_bit(B[2], Bi2_rail1, Bi2_rail0);
  endtask

  task automatic apply_vector (input [2:0] A, input [2:0] B);
    drive_operands(3'b000, 3'b000);
    Ki = 1'b0;
    @(negedge Ko);              // wait for DUT to report NULL

    #20;                         // spacer

    drive_operands(A,B);
    Ki = 1'b1;
    @(posedge Ko);              // wait for DATA accepted

    #20;                         // allow DATA to flow before next cycle
  endtask

  // ------------- stimulus --------------
  initial begin
    rst = 1; Ki = 1'b1;     // reset to NULL
    #20  rst = 0;

    $display("time  Ai  Bi    | product");
    $monitor("%4t  %b%b  %b%b | %b%b%b%b%b%b",
             $time,
             Ai0_rail1,Ai0_rail0,Bi0_rail1,Bi0_rail0,
             Po5_rail1,Po4_rail1,Po3_rail1,Po2_rail1,Po1_rail1,Po0_rail1);

    apply_DR_input(1'b0,1'b1, 1'b0,1'b1);  // 0 × 0
    apply_DR_input(1'b0,1'b1, 1'b1,1'b0);  // 0 × 1
    apply_DR_input(1'b1,1'b0, 1'b0,1'b1);  // 1 × 0
    apply_DR_input(1'b1,1'b0, 1'b1,1'b0);  // 1 × 1
    
    apply_vector(3'd5, 3'd4);   // 5 × 4 = 20
    apply_vector(3'd6, 3'd7);   // 6 × 7 = 42
    apply_vector(3'd7, 3'd1);   // 7 × 1 = 7

    #200;
    $finish;
  end
endmodule
