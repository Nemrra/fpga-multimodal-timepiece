// ------------------------------------------------------------------
// WARNING: This file is used by the automated test suite. Do not
// modify it.
//
// This file also serves as a template for your own designs. To use
// it:
//   1. Copy the entire contents into a new file with a descriptive
//      name.
//   2. Delete the test logic below and replace it with your own
//      code.
//   3. In top_de1_soc, change the module name from user_top to your
//      new module name.
//
//   The board wrapper sets CYCLES_PER_SECOND; use this parameter in
//   your design wherever timing is needed.
// ------------------------------------------------------------------
`timescale 1ns / 1ps

module user_top_watch_v2 #(
    /* verilator lint_off UNUSEDPARAM */
    parameter int CYCLES_PER_SECOND = 50_000_000
    /* verilator lint_on UNUSEDPARAM */
) (
    input logic clk,
    /* verilator lint_off UNUSED */
    input logic [3:0] button,
    input logic [9:0] sw,
    /* verilator lint_on UNUSED */
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);
  // --------------------
  //  Core Functionality
  // --------------------

  // seconds
  logic seconds_tick;
  logic seconds_edit;
  logic seconds_inc;
  logic seconds_dec;
  logic [5:0] seconds;  // width-matched to .WIDTH
  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds)
  );
  // minutes
  logic minutes_tick;
  logic minutes_edit;
  logic minutes_inc;
  logic minutes_dec;
  logic [5:0] minutes;  // width-matched to .WIDTH
  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .tick(minutes_tick),
      .edit_mode(minutes_edit),
      .inc(minutes_inc),
      .dec(minutes_dec),
      .count(minutes)
  );
  // hours
  logic hours_tick;
  logic hours_edit;
  logic hours_inc;
  logic hours_dec;
  logic [4:0] hours;  // width-matched to .WIDTH
  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .tick(hours_tick),
      .edit_mode(hours_edit),
      .inc(hours_inc),
      .dec(hours_dec),
      .count(hours)
  );

  // derive 1Hz tick from system clock
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_divider_1_Hz (
      .clk (clk),
      .run (1'b1),
      .tick(seconds_tick)
  );
  assign minutes_tick = seconds_tick && (seconds == 6'd59);
  assign hours_tick   = minutes_tick && (minutes == 6'd59);

  // tie low all edit functionality for V1
  assign seconds_edit = 1'b0;
  assign minutes_edit = 1'b0;
  assign hours_edit   = 1'b0;
  assign seconds_inc  = 1'b0;
  assign seconds_dec  = 1'b0;
  assign minutes_inc  = 1'b0;
  assign minutes_dec  = 1'b0;
  assign hours_inc    = 1'b0;
  assign hours_dec    = 1'b0;
  assign led          = 10'b0;

  // Zero-extend counter values to display outputs
  // Compatible with decimal_display_driver, which takes input 0-99 (7 bits)
  assign hours_disp   = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};


  // --------------------
  // Mode Selection Logic
  // --------------------
  logic [2:0] mode_enable;
  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)  // 1s hold enters edit
  ) u_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );

  // 2Hz, 80% duty, asserts blank during non-edit mode
  logic pwm_out;
  logic pwm_reset;
  assign pwm_reset = (mode_enable == 3'b000);
  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),  // 2Hz
      .DUTY_CYCLES(4 * CYCLES_PER_SECOND / 10)  // 80%
  ) u_pwm_generator (
      .clk(clk),
      .rst(pwm_reset),
      .pwm_out(pwm_out)
  );
  // assuming lit 80% of time, might be reversed
  assign blank_hours   = mode_enable[2] & ~pwm_out;
  assign blank_minutes = mode_enable[1] & ~pwm_out;
  assign blank_seconds = mode_enable[0] & ~pwm_out;
endmodule
