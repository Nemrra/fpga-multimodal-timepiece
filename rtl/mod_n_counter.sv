/* mod_n_counter
A reusable counter that increments from 0 to N-1, then wraps back to zero, with a synchronous reset (priority over enable)
and an enable input. Used as a generic "count out N clock cycles" primitive throughout the design

Parameters:
int N = 4      - # of clock cycles before wrapping
int WIDTH = 2  - tunable counter width

Ports:
logic clk                - absolute rate determined by arbitrary external clock
logic rst                - when high, regardless of enable, resets count to zero
logic enable             - when high, increments count at next rising edge

logic [WIDTH-1:0] count  - width-specified counter, wraps at rate f_wrap = f_clk / N
*/

`timescale 1ns / 1ps
module mod_n_counter #(
    parameter int N = 4,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [WIDTH-1:0] count = '0
);
  localparam logic [WIDTH-1:0] Max = WIDTH'(N - 1);
  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk)
    if (rst) count <= '0;
    else if (enable) count <= next_count;

  always_comb begin
    next_count = (count >= Max) ? '0 : count + WIDTH'(1);
  end
endmodule
