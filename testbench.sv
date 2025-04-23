/* -----------------------------------------------------------
-- th22x0
----------------------------------------------------------- */
module th22x0 (
input wire a,
input wire b,
output reg z
); //th22 gate

always @ (a or b) begin
    if (a == 1'b1 && b == 1'b1)
        z = 1'b1; // 127.85 ps delay
    else if (a == 1'b0 && b == 1'b0)
        z = 1'b0; // 193.9 ps delay
    // Else: retain previous value (no change)
    end
endmodule

/* --------------------------------------------------------------
-- thand0x0
----------------------------------------------------------- */
module thand0x0 (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output reg z
);

always @ (a or b or c or d) begin
    if (~a & ~b & ~c & ~d)
        
    else if ((a & b) || (b & c) || (a & d))
        
    // Else: retain previous value (no change)
    end
endmodule

/* --------------------------------------------------------------
-- DUAL rail typedef
----------------------------------------------------------- */
typedef struct packed {
    logic rail1;
    logic rail0;
} dual_rail_logic;
// Vector (array) of dual-rail logic
typedef dual_rail_logic dual_rail_logic_vector[];
/* --------------------------------------------------------------
-- NCL AND
----------------------------------------------------------- */
module ncl_and0 (
    input dual_rail_logic x,
    input dual_rail_logic y,
    output dual_rail_logic z
);
// THAND0 for z rail0
thand0x0 g0 (
    .a(x.rail0),
    .b(y.rail0),
    .c(x.rail1),
    .d(y.rail1),
    .z(z.rail0)
);
// TH22x0 for z rail1
th22x0 g1 (
    .a(x.rail1),
    .b(y.rail1),
    .z(z.rail1)
);
endmodule

/* -----------------------------------------------------------
-- NCL AND TB
----------------------------------------------------------- */
module ncl_and0_tb;
// Import dual-rail type if using struct (comment out if using plain signals)
typedef struct packed {
    logic rail1;
    logic rail0;
} dual_rail_logic;
// Inputs to the UUT
reg [1:0] x, y;
wire [1:0] z;
// Instantiate the Unit Under Test (UUT)
ncl_and0 uut (
    .x(x),
    .y(y),
    .z(z)
);
// Helper task to apply dual-rail input
task apply_dual_rail_input(input [1:0] x_val, input [1:0] y_val);
    begin
        x = 2'b00; // NULL phase
        y = 2'b00;
        #50; // NULL duration
        x = x_val;
        y = y_val;
        #100; // hold valid input
end
endtask
initial begin
    $display("Starting NCL AND Testbench");
    $monitor("Time: %0t | X = %b | Y = %b | Z = %b",
    $time, x, y, z);
    // Initialize inputs
    x = 2'b00;
    y = 2'b00;
    // All combinations with NULL spacer
    apply_dual_rail_input(2'b01, 2'b01); // X = 0, Y = 0
    apply_dual_rail_input(2'b01, 2'b10); // X = 0, Y = 1
    apply_dual_rail_input(2'b10, 2'b01); // X = 1, Y = 0
    apply_dual_rail_input(2'b10, 2'b10); // X = 1, Y = 1
    #100;
    $display("Simulation complete.");
    $finish;
end
endmodule