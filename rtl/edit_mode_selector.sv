/* Edit Mode Selecter
Button held for HOLD_CYCLES enters edit mode, and subsequent rising-edge presses switch from sec>min>hr>no-edit states.
*/
`timescale 1ns / 1ps
module edit_mode_selector #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input logic clk,
    input logic button,
    output logic [2:0] mode_enable
);

  // Fires one pulse when user holds for long enough
  logic long_press;
  button_hold_pulse #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_hold_pulse (
      .clk(clk),
      .button(button),
      .pulse(long_press)
  );

  // 'Advance to next field' trigger
  logic press;
  rising_edge_detector u_detector (
      .clk(clk),
      .sig_in(button),
      .rise(press)
  );

  // Registers whether in edit mode or not
  logic armed;
  logic disarm;
  arming_latch u_latch (
      .clk(clk),
      .arm(long_press),  // assert long_press -> assert armed (given disarm is not)
      .disarm(disarm),
      .armed(armed)
  );

  // Tracks which field is currently selected
  logic reset_counter;
  logic enable_counter;
  logic [1:0] count;
  mod_n_counter #(
      .N(3),
      .WIDTH(2)
  ) u_mod_3_counter (  //mod_3 -> 0,1,2
      .clk(clk),
      .rst(reset_counter),
      .enable(enable_counter),
      .count(count)
  );

  // Counter runs only while armed; resets when disarmed
  assign enable_counter = press && armed;
  assign reset_counter = !armed;

  // Disarm on the press that steps past the last mode
  assign disarm = enable_counter && (count == 2'd2);  // (&& !reset_counter, armed) would work, but is redundant

  // Output logic
  assign mode_enable = armed ? (3'b001 << count) : 3'b000;
  // not armed -> 000 = no-edit
  // armed -> shift according
  // A << B shift A left by B bits (no wrap, fill void right bits with zeroes)
endmodule
