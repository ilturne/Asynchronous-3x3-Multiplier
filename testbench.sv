`timescale 1ns/1ps
module tb;

  // ------------- DUT ports -------------
  logic Ai0_rail1, Ai0_rail0, Ai1_rail1, Ai1_rail0, Ai2_rail1, Ai2_rail0;
  logic Bi0_rail1, Bi0_rail0, Bi1_rail1, Bi1_rail0, Bi2_rail1, Bi2_rail0;
  logic Ki, rst;

  logic Po0_rail1, Po0_rail0, Po1_rail1, Po1_rail0, Po2_rail1, Po2_rail0;
  logic Po3_rail1, Po3_rail0, Po4_rail1, Po4_rail0, Po5_rail1, Po5_rail0;
  logic Ko;
	
  dual_rail_logic [2:0] A_dbg, B_dbg; // for debugging purposes
  
  // ------------- DUT -------------------
  NCL_MULT3 dut (.*, .dbg_A(A_dbg), .dbg_B(B_dbg));
  
  wire [2:0] ai_vec, bi_vec;    
  wire [5:0] prod_vec;  
  
  wire [2:0] A_after  = {A_dbg[2].rail1, A_dbg[1].rail1, A_dbg[0].rail1};
  wire [2:0] B_after  = {B_dbg[2].rail1, B_dbg[1].rail1, B_dbg[0].rail1};
  
  assign ai_vec   = {Ai2_rail1, Ai1_rail1, Ai0_rail1};
  assign bi_vec   = {Bi2_rail1, Bi1_rail1, Bi0_rail1};
  assign prod_vec = {Po5_rail1,Po4_rail1,Po3_rail1,Po2_rail1,Po1_rail1,Po0_rail1};
  
  task automatic encode_bit (input bit v, output logic r1, r0);
    {r1,r0} = v ? 2'b10 : 2'b01;   // 10 = “1”, 01 = “0”
  endtask
  
  task automatic drive_operands (input [2:0] A, input [2:0] B);
    encode_bit(A[0], Ai0_rail1, Ai0_rail0);
    encode_bit(A[1], Ai1_rail1, Ai1_rail0);
    encode_bit(A[2], Ai2_rail1, Ai2_rail0);

    encode_bit(B[0], Bi0_rail1, Bi0_rail0);
    encode_bit(B[1], Bi1_rail1, Bi1_rail0);
    encode_bit(B[2], Bi2_rail1, Bi2_rail0);
  endtask

  task automatic ncl_cycle (input  [2:0] A, input [2:0] B);
   // 1. send NULL and request NULL
   drive_operands(3'b000, 3'b000);
   Ki = 1'b0;
   #50;
   
  // 2. send operands and request DATA
   drive_operands(A, B);
   Ki = 1'b1;
   #50;

   // 3. drop back to NULL so the pipeline can clear
   drive_operands(3'b000, 3'b000);
   Ki = 1'b0;
   #20;

  endtask

  // ------------- stimulus --------------
  initial begin
    rst = 1; Ki = 1'b1; 
    #20  rst = 0;      
    
    $display(" time | inA | inB | regA | regB | Ki | Ko");
    $monitor("%5t | %03b | %03b | %03b | %03b | %0b | %0b",
             $time, ai_vec, bi_vec, A_after, B_after, Ki, Ko);
    end
  
  initial begin
   ncl_cycle( 3'd2 , 3'd7 );   // 2×7
   #100 $finish;
   end
 
endmodule
