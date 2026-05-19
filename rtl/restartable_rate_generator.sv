/* Restartable Rate Generator
Returns a rate-specified single-cycle tick, outsourcing mod_n_counter primitive logic.
A Moore FSM whose state is `running` plus the internal counter; tick depends only on state.

Behaviour:
- When run is low: tick is low and the counter resets.
- When run is high: first tick fires CYCLE_COUNT-1 rising edges after run goes high,
  then repeats every CYCLE_COUNT rising edges thereafter.
- CYCLE_COUNT = 1 is supported as a special case: tick directly follows the
  clocked version of run (one cycle of delay through the `running` FF).

Restartable: deasserting run resets the counter, so the next assertion of run
starts a fresh CYCLE_COUNT-1 countdown.

Parameter:
CYCLE_COUNT - period of the output tick, measured in clock cycles

Ports:
clk, run     - clock and enable
tick         - single-cycle pulse at the configured rate
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
      localparam logic [CountWidth-1:0] MaxCount = CountWidth'(CYCLE_COUNT - 1);
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
      assign tick_qualifier = (count == MaxCount);

    end else begin : g_special
      assign tick_qualifier = 1'b1;  // tick follows run
    end
  endgenerate
endmodule
