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
module user_top_stopwatch_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);
  // Rising edge detection of buttons
  logic rise0_raw;
  logic rise1_raw;

  rising_edge_detector u_rise_btn0 (
      .clk   (clk),
      .sig_in(button[0]),
      .rise  (rise0_raw)
  );
  rising_edge_detector u_rise_btn1 (
      .clk   (clk),
      .sig_in(button[1]),
      .rise  (rise1_raw)
  );

  // Simultaneous-press suppression
  logic rise_start_stop;
  logic rise_lap;
  // Button gated by the other
  assign rise_start_stop = rise0_raw && ~rise1_raw;
  assign rise_lap = rise1_raw && ~rise0_raw;

  // Control FSM
  logic counter_rst;
  logic counter_enable;
  logic lap_hold;

  stopwatch_control u_ctrl (
      .clk            (clk),
      .rise_start_stop(rise_start_stop),
      .rise_lap       (rise_lap),
      .counter_rst    (counter_rst),
      .counter_enable (counter_enable),
      .lap_hold       (lap_hold)
  );

  // Stopwatch Counter
  logic [6:0] minutes_live;
  logic [5:0] seconds_live;
  logic [6:0] centi_live;

  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk         (clk),
      .rst         (counter_rst),
      .enable      (counter_enable),
      .minutes     (minutes_live),
      .seconds     (seconds_live),
      .centiseconds(centi_live)
  );

  //Snapshot (lap) freeze
  logic [19:0] live_packed;
  logic [19:0] disp_packed;
  logic [ 6:0] minutes_disp_val;
  logic [ 5:0] seconds_disp_val;
  logic [ 6:0] centi_disp_val;

  assign live_packed = {minutes_live, seconds_live, centi_live};

  snapshot_mux #(
      .WIDTH(20)
  ) u_lap (
      .clk (clk),
      .hold(lap_hold),
      .d   (live_packed),
      .q   (disp_packed)
  );

  assign { minutes_disp_val,
             seconds_disp_val,
             centi_disp_val   } = disp_packed;


  assign hours_disp    = minutes_disp_val;
  assign minutes_disp  = {1'b0, seconds_disp_val};
  assign seconds_disp  = centi_disp_val;

  assign blank_hours   = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

  assign led = '0;

  // unused inputs
  logic _unused;
  assign _unused = &{1'b0, button[3:2], sw};

endmodule
