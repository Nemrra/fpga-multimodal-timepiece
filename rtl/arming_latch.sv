/* Arming Latch
One-bit memory that tracks whether the watch is currently in edit mode.
Disarm takes priority over Arm. Armed is initialised to zero.
Almost a primitive flip-flop
*/
`timescale 1ns / 1ps
module arming_latch (
    input logic clk,
    input logic arm,  // 'enter edit mode'
    input logic disarm,  // 'exit edit mode'
    output logic armed  // edit-mode
);
  initial armed = 1'b0;

  always_ff @(posedge clk)
    if (disarm) armed <= 1'b0;
    else if (arm) armed <= 1'b1;
  // else retain value (implicit)
endmodule
