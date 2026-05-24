`timescale 1ns / 1ps

module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic       probe_running,
    output logic [2:0] probe_mode_enable,
`endif
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

  // --------------
  // Mode selection
  // --------------
  logic [2:0] mode_enable;
  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)  // 1 second hold to enter set mode
  ) u_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );

  wire  seconds_edit = mode_enable[0];
  wire  minutes_edit = mode_enable[1];
  wire  hours_edit = mode_enable[2];
  wire  in_edit = |mode_enable;

  // --------------
  // Running FSM
  // --------------
  logic running = 1'b0;
  logic at_zero;
  logic tick_1hz;

  logic rise_start_stop;
  rising_edge_detector u_rise_btn0 (
      .clk(clk),
      .sig_in(button[0]),
      .rise(rise_start_stop)
  );

  // Event-based auto-stop: the tick that would take the count from 0:00:01 to 0:00:00.
  wire reaching_zero = (seconds_count == 6'd1)
                    && (minutes_count == '0)
                    && (hours_count   == '0)
                    && tick_1hz;

  always_ff @(posedge clk) begin
    if (in_edit) running <= 1'b0;  // edit priority
    else if (running && reaching_zero) running <= 1'b0;  // auto-stop at zero
    else if (rise_start_stop) begin
      if (running) running <= 1'b0;  // pause
      else if (!at_zero) running <= 1'b1;  // start (only if count > 0)
    end
  end

  // --------------
  // 1 Hz tick
  // --------------
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_rate_1hz (
      .clk (clk),
      .run (running),
      .tick(tick_1hz)
  );

  // --------------
  // Auto-repeat for set-mode inc/dec
  // --------------
  logic inc_pulse;
  logic dec_pulse;

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),  // 0.5 s before repeat
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)  // 10 Hz repeat
  ) u_inc_repeat (
      .clk(clk),
      .button(button[1]),
      .pulse(inc_pulse)
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_dec_repeat (
      .clk(clk),
      .button(button[0]),
      .pulse(dec_pulse)
  );

  // --------------
  // Counter chain (h:m:s, cascaded via borrow_out)
  // --------------
  logic [5:0] seconds_count;
  logic [5:0] minutes_count;
  logic [4:0] hours_count;
  logic       seconds_borrow;
  logic       minutes_borrow;
  logic       hours_borrow;  // unused at top of chain

  wire        seconds_tick = tick_1hz && running && !at_zero;

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .clr(1'b0),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(seconds_count),
      .borrow_out(seconds_borrow)
  );

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .clr(1'b0),
      .tick(seconds_borrow),
      .edit_mode(minutes_edit),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(minutes_count),
      .borrow_out(minutes_borrow)
  );

  editable_countdown #(
      .MAX  (23),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(minutes_borrow),
      .edit_mode(hours_edit),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(hours_count),
      .borrow_out(hours_borrow)
  );

  assign at_zero = (seconds_count == '0) && (minutes_count == '0) && (hours_count == '0);

  // --------------
  // PWM flash for the currently-edited field
  // --------------
  logic pwm_out;
  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),       // 2 Hz
      .DUTY_CYCLES  ((CYCLES_PER_SECOND * 2) / 5)  // 80 %
  ) u_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  // --------------
  // Outputs
  // --------------
  assign hours_disp = {2'b0, hours_count};
  assign minutes_disp = {1'b0, minutes_count};
  assign seconds_disp = {1'b0, seconds_count};

  assign blank_hours = hours_edit & ~pwm_out;
  assign blank_minutes = minutes_edit & ~pwm_out;
  assign blank_seconds = seconds_edit & ~pwm_out;

  assign led = '0;

  // Sink unused inputs / outputs to silence Verilator
  logic _unused;
  assign _unused = &{1'b0, button[2], sw, hours_borrow};

`ifdef FORMAL
  assign probe_running     = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
