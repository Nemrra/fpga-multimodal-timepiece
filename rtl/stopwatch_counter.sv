/* Stopwatch counter
minutes/seconds/centiseconds cascade clocked at 100 Hz.
cs rollover increments seconds, and seconds to minutes
*/
`timescale 1ns / 1ps
module stopwatch_counter #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic rst,  // priority over enable
    input logic enable,
    output logic [6:0] minutes,
    output logic [5:0] seconds,
    output logic [6:0] centiseconds  // 1/100s
);

  // One tick per centisecond, restarted on rst
  logic tick;
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 100)
  ) u_rate (
      .clk (clk),
      .run (enable && !rst),  // reset overrides (report 8)
      .tick(tick)
  );

  cascade_counter #(
      .N0(100),
      .W0(7),  // centiseconds: wraps 99 → 0
      .N1(60),
      .W1(6),  // seconds:      wraps 59 → 0
      .N2(100),
      .W2(7)  // minutes:      wraps 99 → 0
  ) u_cascade (
      .clk   (clk),
      .rst   (rst),
      .enable(tick), // one-cycle pulse from rrg
      .count0(centiseconds),
      .count1(seconds),
      .count2(minutes)
  );
endmodule
