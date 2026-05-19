/* Button Hold Pulse
Combines an instance of both a hold detect and rising edge detector.
Pulse is of MAX (but not strictly) length one cycle (see ris_edge spec)
*/
`timescale 1ns / 1ps
module button_hold_pulse #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input  logic clk,
    input  logic button,
    output logic pulse
);
  logic held;

  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_button_hold_detect (
      .clk(clk),
      .button(button),
      .held(held)
  );

  rising_edge_detector u_rising_edge_detector (
      .clk(clk),
      .sig_in(held),
      .rise(pulse)
  );

endmodule
