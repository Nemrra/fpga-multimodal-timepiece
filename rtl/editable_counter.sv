`timescale 1ns / 1ps
module editable_counter #(
    parameter int N = 60,  // max(count) = N-1
    parameter int WIDTH = 6  // Amount of registers containing count
) (
    input logic clk,
    input logic tick,  // count increments on tick when edit_mode is low
    input logic edit_mode,
    input logic inc,  // count increments by one when edit_mode is high
    input logic dec,  // count decrements by one when edit_mode is low
    output logic [WIDTH-1:0] count
);
  logic enable;
  logic up;

  up_down_counter #(
      .MAX  (N - 1),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .enable(enable),
      .up(up),
      .count(count)
  );

  wire inc_event = edit_mode && inc && !dec;  // ! for simultaneously pressing both
  wire dec_event = edit_mode && dec && !inc;
  wire tick_event = !edit_mode && tick;

  assign up = tick_event || inc_event;
  assign enable = tick_event || inc_event || dec_event;
endmodule
