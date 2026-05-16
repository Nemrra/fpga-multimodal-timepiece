/* Restartable Rate Generator
Returns a rate-specified single-cycle tick, outsourcing mod_n_counter primitive logic.
Supports edge case where run follows tick.

Variable:
CYCLE_COUNT - specifies high-tick rate with respect to global clock

Ports:
clk, run
tick
*/

`timescale 1ns / 1ps
module restartable_rate_generator #(
    parameter int CYCLE_COUNT = 2
) (
    input  logic clk,
    input  logic run,
    output logic tick
);
  logic tick_qualifier;  //high at the end of each cycle
  logic running = 1'b0;

  always_ff @(posedge clk) running <= run;

  assign tick = tick_qualifier && running;

  generate
    if (CYCLE_COUNT > 1) begin : g_general
      // general case, including instantiation
      localparam int CountWidth = $clog2(CYCLE_COUNT);  // internally handled
      localparam logic [CountWidth-1:0] CycleCount = CountWidth'(CYCLE_COUNT);

      logic rst_count;
      logic enable_count;
      logic [CountWidth-1:0] count;

      mod_n_counter #(
          .N(CYCLE_COUNT),
          .WIDTH(CountWidth)
      ) u_count (
          .clk(clk),
          .rst(rst_count),
          .enable(enable_count),
          .count(count)
      );

      assign rst_count = !run;  // restartable
      assign enable_count = run;
      assign tick_qualifier = (count == CycleCount - 1);

    end else begin : g_special
      assign tick_qualifier = 1'b1;  // tick follows run
    end
  endgenerate
endmodule
