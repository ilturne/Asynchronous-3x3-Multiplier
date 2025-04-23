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

  // ------------- stimulus --------------
  initial begin
    rst = 1; Ki = 1'b1;     // reset to NULL
    #20  rst = 0;

    $display("time  Ai  Bi   | product");
    $monitor("%4t  %b%b  %b%b | %b%b%b%b%b%b",
             $time,
             Ai0_rail1,Ai0_rail0,Bi0_rail1,Bi0_rail0,
             Po5_rail1,Po4_rail1,Po3_rail1,Po2_rail1,Po1_rail1,Po0_rail1);

    apply_DR_input(1'b0,1'b1, 1'b0,1'b1);  // 0 × 0
    apply_DR_input(1'b0,1'b1, 1'b1,1'b0);  // 0 × 1
    apply_DR_input(1'b1,1'b0, 1'b0,1'b1);  // 1 × 0
    apply_DR_input(1'b1,1'b0, 1'b1,1'b0);  // 1 × 1

    #200;
    $finish;
  end
endmodule
