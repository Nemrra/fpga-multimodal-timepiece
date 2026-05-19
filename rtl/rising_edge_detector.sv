`timescale 1ns / 1ps
module rising_edge_detector (
    input  logic clk,
    input  logic sig_in,
    output logic rise
);
  logic prev = 0;
  logic next_prev;

  always_ff @(posedge clk) prev <= next_prev;
  assign next_prev = sig_in;
  assign rise = !prev && sig_in;  // mealy! sig_in not registered
endmodule
