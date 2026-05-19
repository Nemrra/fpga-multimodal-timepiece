/* Key Synchroniser
Takes 4-bit key_n, bitwise-inverts it, then synchronises through two series
flip-flops, mitigating instability. 2 rising-edge delay from input to output.
Input needs to be held until at least one rising edge to propagate to the output.
*/

`timescale 1ns / 1ps
module key_synchroniser (
    input logic clk,
    input logic [3:0] key_n,  // active-low, asynchronous
    output logic [3:0] key_sync  // active-high, synchronised
);
  logic [3:0] stage1 = '0;
  logic [3:0] stage2 = '0;  // initial-value

  always_ff @(posedge clk) begin
    stage1 <= ~key_n;  // bitwise-inversion
    stage2 <= stage1;
  end
  assign key_sync = stage2;
endmodule
