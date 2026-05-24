`timescale 1ns / 1ps

module user_top_brightness_wrapper #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input  logic       clk,
    input  logic [3:0] button,
    input  logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic       blank_hours,
    output logic       blank_minutes,
    output logic       blank_seconds
);
  // PWM period of 1 ms - well above flicker threshold
  localparam int PeriodCycles = CYCLES_PER_SECOND / 1000;
  localparam int CountWidth = $clog2(PeriodCycles);

  // Grab the app's blanking signals so we can mix in our PWM
  logic app_blank_hours;
  logic app_blank_minutes;
  logic app_blank_seconds;

  // The wrapped app - everything else passes through untouched
  user_top #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top (
      .clk          (clk),
      .button       (button),
      .sw           (sw),
      .led          (led),
      .hours_disp   (hours_disp),
      .minutes_disp (minutes_disp),
      .seconds_disp (seconds_disp),
      .blank_hours  (app_blank_hours),
      .blank_minutes(app_blank_minutes),
      .blank_seconds(app_blank_seconds)
  );

  // Free-running counter for the PWM - cycles every 1 ms
  logic [CountWidth-1:0] pwm_count;
  mod_n_counter #(
      .N    (PeriodCycles),
      .WIDTH(CountWidth)
  ) u_pwm_counter (
      .clk   (clk),
      .rst   (1'b0),
      .enable(1'b1),
      .count (pwm_count)
  );

  // Grey-coded brightness from the top two switches:
  //   00 Dim     12.5%
  //   01 Low     25%
  //   11 Medium  50%
  //   10 Full    100%  (handled separately so we don't need the extra bit)
  wire full_brightness = (sw[9:8] == 2'b10);

  logic [CountWidth-1:0] threshold;
  always_comb begin
    case (sw[9:8])
      2'b00:   threshold = CountWidth'(PeriodCycles / 8);
      2'b01:   threshold = CountWidth'(PeriodCycles / 4);
      2'b11:   threshold = CountWidth'(PeriodCycles / 2);
      default: threshold = '0;  // 2'b10 handled by full_brightness
    endcase
  end

  // While pwm_count is below threshold we're in the on-phase; the rest
  // of the period we blank the display
  wire pwm_blank = !full_brightness && !(pwm_count < threshold);

  // App's blanking always wins - we can only ever make things dimmer
  assign blank_hours   = app_blank_hours | pwm_blank;
  assign blank_minutes = app_blank_minutes | pwm_blank;
  assign blank_seconds = app_blank_seconds | pwm_blank;

endmodule
