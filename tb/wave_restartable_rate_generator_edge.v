`timescale 1ns / 1ps
module wave_restartable_rate_generator_edge;
  reg  clk = 0;
  reg  run = 0;
  wire tick;
  localparam int edgeCase = 1;

  restartable_rate_generator #(
      .CYCLE_COUNT(edgeCase)
  ) dut (
      .clk (clk),
      .run (run),
      .tick(tick)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave_restartable_rate_generator_edge.vcd");
    $dumpvars(0, wave_restartable_rate_generator_edge);

    run = 0;
    #20;  // a couple of clock periods low
    run = 1;
    #40;  // hold high for a few cycles
    run = 0;
    #20;
    run = 1;
    #10;  // brief pulse
    run = 0;
    #20;
    $finish;
  end
endmodule
