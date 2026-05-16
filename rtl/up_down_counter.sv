/* Up-down counter with wrapping at {0,MAX}
Ports:
            clk    - flip flop reference signal
            enable - counter enabler by gating flip flop
            up     - 1 increment, 0 decrement
[WIDTH_1:0] count  - stores current count

Variables:
int MAX   - Max counter value
int WIDTH - bit allocation to count (must at least accomodate MAX)
*/

`timescale 1ns / 1ps
module up_down_counter #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2   // width controllability
) (
    input logic clk,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = WIDTH'(0)
    // width-matched cast, t=0 assignment (can seperate using intial keyword within module too)
);
  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);  // to satisfy linter
  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) if (enable) count <= next_count;
  // gate enable inside always_ff rather than NSL

  always_comb begin  // up-down count with wrapping
    if (up) next_count = (count == Max) ? WIDTH'(0) : count + WIDTH'(1);
    else next_count = (count == WIDTH'(0)) ? Max : count - WIDTH'(1);
  end
endmodule
