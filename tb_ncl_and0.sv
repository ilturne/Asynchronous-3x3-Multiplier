//----------------------------------------------------------------------
// tb.sv  –  unit-test for ncl_and0, compatible with Icarus Verilog 12
//----------------------------------------------------------------------

`timescale 1ns/1ps          // pull in DUT & typedef

module tb_ncl_and0;

  // ---------- DUT connections ----------
  dual_rail_logic x, y, z;
  ncl_and0 dut ( .* );

  // ---------- local helpers ------------

  // encode one Boolean into dual-rail
  task dr_encode ( input  logic v,
                   output logic r1, r0 );
      {r1,r0} = v ? 2'b10 : 2'b01;
  endtask

  // drive vector & compare
  task apply_and_check ( input logic a,
                         input logic b );
      logic exp, z_val;           // <-- declare first (ivl rule)
      exp = a & b;

      dr_encode(a, x.rail1, x.rail0);
      dr_encode(b, y.rail1, y.rail0);
      #1;                          // settle

      // dual-rail → 1-bit
      case ({z.rail1,z.rail0})
        2'b10 : z_val = 1'b1;
        2'b01 : z_val = 1'b0;
        default: begin
            $display("### Illegal dual-rail output %b", {z.rail1,z.rail0});
            z_val = 1'bx;
        end
      endcase

      $display("%0t  a=%0b b=%0b  ->  %0b  (exp %0b)  %s",
               $time,a,b,z_val,exp, (z_val===exp)?"PASS":"FAIL");
      if (z_val !== exp) $fatal(1,"Mismatch");
  endtask

  // ---------- stimulus ---------------
  integer i;
  initial begin
      $display("time   a  b  |  z");

      for (i = 0; i < 4; i = i + 1) begin
          apply_and_check( i[1], i[0] );   // MSB,LSB = {a,b}
      end

      $display("All vectors passed."); 
      $finish;
  end

endmodule
