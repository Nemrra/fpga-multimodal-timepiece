/*  Snapshot MUX
Supports bitstream specified by width.
*/
`timescale 1ns / 1ps
module snapshot_mux #(
    parameter int WIDTH = 1
) (
    input logic clk,
    input logic hold,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
  logic [WIDTH-1:0] snapshot;
  always_ff @(posedge clk) if (!hold) snapshot <= q;  // snapshots value before hold is asserted
  assign q = hold ? snapshot : d;  // snapshot if held, continuous assignment otherwise
endmodule
