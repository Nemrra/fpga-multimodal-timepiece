/* Editable Countdowwn
Adapted from editable_counter, with new features detailed in report
*/

`timescale 1ns / 1ps
module editable_countdown #(
    parameter int MAX   = 59,  // max(count) = MAX
    parameter int WIDTH = 6    // Amount of registers containing count
) (
    input logic clk,
    input logic clr,  // sets count to 0, priority over all other inputs
    input logic tick,  // count decrements on tick when edit_mode is low
    input logic edit_mode,
    input logic inc,  // count increments by one when edit_mode is high
    input logic dec,  // count decrements by one when edit_mode is high
    output logic [WIDTH-1:0] count,
    output logic borrow_out  // combinational, high on cycle that would underflow
);
  logic enable;
  logic up;

  up_down_counter_rst #(
      .MAX  (MAX),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .rst(clr),
      .enable(enable),
      .up(up),
      .count(count)
  );

  wire inc_event = edit_mode && inc && !dec;  // ! for simultaneously pressing both
  wire dec_event = edit_mode && dec && !inc;
  wire tick_event = !edit_mode && tick;

  assign up = inc_event;  // only inc_event counts up; dec_event and tick_event count down
  assign enable = tick_event || inc_event || dec_event;

  assign borrow_out = (count == '0) && tick && !edit_mode && !clr;
endmodule
