
`timescale 1ns / 1ps
module stopwatch_control (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst = 1'b0,
    output logic counter_enable = 1'b0,
    output logic lap_hold = 1'b0
);
  logic next_counter_rst;
  logic next_counter_enable;
  logic next_lap_hold;

  // State Registers
  always_ff @(posedge clk) begin
    counter_rst <= next_counter_rst;
    counter_enable <= next_counter_enable;
    lap_hold <= next_lap_hold;
  end
  // counter_rst: high for one cycle when lap is pressed in Stopped+Live (000).
  assign next_counter_rst = !counter_rst && !counter_enable && !lap_hold && rise_lap;

  // lap_hold: toggled by lap, except in Stopped+Live (where lap triggers reset
  // instead) and in Reset (where lap_hold stays 0). The (counter_enable ||
  // lap_hold) mask excludes exactly those two states.
  assign next_lap_hold = lap_hold ^ (rise_lap && (counter_enable || lap_hold));

  // counter_enable: toggled by start/stop, held during Reset so we exit to
  // Stopped+Live (counter_enable=0) regardless of what start/stop did.
  always_comb begin
    next_counter_enable = counter_enable;
    if (!counter_rst && rise_start_stop) next_counter_enable = !counter_enable;
  end

  // The state encoding is directly compatible with the output specification - No OCL needed

endmodule
