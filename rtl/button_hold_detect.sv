/* Button Hold Detect
Active-high input hold detection. Detects a hold after a configurable time, and remains so until input is released.
*/

`timescale 1ns / 1ps
module button_hold_detect #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input  logic clk,
    input  logic button,
    output logic held
);
  localparam int CountMax = HOLD_CYCLES;
  localparam int CountWidth = $clog2(CountMax + 1);  // +1 for edge case

  logic count_rst;
  logic count_enable;
  logic [CountWidth-1:0] count;

  mod_n_counter #(
      .N(CountMax + 1),
      .WIDTH(CountWidth)
  ) u_mod_n_counter (
      .clk(clk),
      .rst(count_rst),
      .enable(count_enable),
      .count(count)
  );

  assign count_enable = button && !held;  // !held holds enable at max count
  assign count_rst = !button;  // button low continually resets count

  assign held = (count == CountWidth'(CountMax));
endmodule
