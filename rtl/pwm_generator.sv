`timescale 1ns / 1ps

module pwm_generator #(
    // number of clock cycles in one pwm period
    parameter int PERIOD_CYCLES = 50_000_000,
    // number of clock cycles output is high
    parameter int DUTY_CYCLES   = 25_000_000
) (
    input  logic clk,
    input  logic rst,
    output logic pwm_out
);
  localparam int CountWidth = $clog2(PERIOD_CYCLES);

  logic [CountWidth-1:0] count;

  mod_n_counter #(
      .N(PERIOD_CYCLES),
      .WIDTH(CountWidth)
  ) u_mod_n_counter (
      .clk(clk),
      .rst(rst),
      .enable(1'b1),
      .count(count)
  );
  assign pwm_out = (32'(count) < DUTY_CYCLES);  // safer then extending the latter
endmodule
