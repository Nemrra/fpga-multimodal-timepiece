/* Hours-minutes-seconds counter
*
* Three cascaded counters for hours, minutes, and seconds, with
* configurable moduli. Each tick of 'enable' advances seconds by one;
* rollovers cascade upward through minutes and hours.
*
* Tick rates relative to `enable`:
*   seconds advances every 1 enable pulse
*   minutes advances every N_SECONDS enable pulses
*   hours   advances every N_SECONDS * N_MINUTES enable pulses
*   full wrap every N_SECONDS * N_MINUTES * N_HOURS enable pulses
*
* This module is rate-agnostic: the absolute rate is set by the caller's
* choice of how often to assert `enable`. Defaults (60, 60, 24) match a
* standard 24-hour clock when `enable` pulses once per real-time second.
*/
`timescale 1ns / 1ps
module hms_counter #(
    parameter int N_HOURS   = 24,  // N number of states
    parameter int N_MINUTES = 60,
    parameter int N_SECONDS = 60,

    parameter int W_HOURS   = 5,
    parameter int W_MINUTES = 6,
    parameter int W_SECONDS = 6
    // every parameter is 32-bit by default, module truncates appropriately
) (
    input logic clk,
    input logic enable,

    output logic [  W_HOURS-1:0] hours,
    output logic [W_MINUTES-1:0] minutes,
    output logic [W_SECONDS-1:0] seconds
);
  localparam logic [W_SECONDS-1:0] MaxSeconds = W_SECONDS'(N_SECONDS - 1);
  localparam logic [W_MINUTES-1:0] MaxMinutes = W_MINUTES'(N_MINUTES - 1);
  // Max = N-1, subtracts one so to avoid edge case where N does not fit in W, namely 2^W = N

  logic second_rollover;
  logic minute_rollover;

  assign second_rollover = (enable) && (seconds == MaxSeconds);
  assign minute_rollover = (second_rollover) && (minutes == MaxMinutes);

  up_down_counter #(
      .MAX  (N_SECONDS - 1), // equals MaxSeconds, BEFORE truncation, so to width-match 32-bit int of MAX
      .WIDTH(W_SECONDS)
  ) u_second (
      .clk(clk),
      .enable(enable),
      .up(1'b1),
      .count(seconds)
  );
  up_down_counter #(
      .MAX  (N_MINUTES - 1),
      .WIDTH(W_MINUTES)
  ) u_minute (
      .clk(clk),
      .enable(second_rollover),  // derived enable, high once every 60s
      .up(1'b1),
      .count(minutes)
  );
  up_down_counter #(
      .MAX  (N_HOURS - 1),
      .WIDTH(W_HOURS)
  ) u_hour (
      .clk(clk),
      .enable(minute_rollover),  // derived enable, high once every 60m
      .up(1'b1),
      .count(hours)
  );
endmodule
