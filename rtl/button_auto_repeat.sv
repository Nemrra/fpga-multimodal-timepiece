/* Button Auto Repeat
Maps button holds to a train of pulses. Supports a single pulse 'press',
and a pulse-train hold - both configurable.

Parameters:
HOLD_CYCLES - cycle # to go from single to train of pulses
REPEAT_CYCLES - How often pulse train goes high for single period
*/

`timescale 1ns / 1ps
module button_auto_repeat #(
    parameter int HOLD_CYCLES   = 50_000_000,
    // REPEAT_CYCLES must be smaller than HOLD_CYCLES
    // Maybe not 'must', but unconventional??
    parameter int REPEAT_CYCLES = 5_000_000
) (
    input  logic clk,
    input  logic button,
    output logic pulse
);
  logic rise;
  logic held;
  logic pulse_train;

  rising_edge_detector u_rising_edge_detector (
      .clk(clk),
      .sig_in(button),
      .rise(rise)
  );

  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES - REPEAT_CYCLES + 1)
  ) u_button_hold_detect (
      .clk(clk),
      .button(button),
      .held(held)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(REPEAT_CYCLES)
  ) u_restartable_rate_generator (
      .clk(clk),
      .run(held),  // drive only after HOLD_CYCLES
      .tick(pulse_train)
  );
  //          'pulse' | 'pulse-train'
  assign pulse = rise | (button & pulse_train);
endmodule
