/* Seven-segment display decoder for hexadecimal digits

Parameters:
ACTIVE_LOW - 1 for active-low leds, 0 for active-high.

Ports:
[3:0] digit     - hexadecimal digit to display (0x0 to 0xF - 16 states) (x is hex)
      blank     - when high, all segments turn off
[6:0] segments  - segment outputs [g,f,e,d,c,b,a] (letters are just convention)

Some nuances to pick up:
-Ternary operator '?' expects a single bit input - but can logically truncate a longer one -
the linter provides a warning for this. Also, '!=0' is better than '==1', since the latter follows
standard 'truthiness' semantics. And say ACTIVE_LOW=8, intentionally or by accident. The latter treats
that as a zero, but it makes more intuitive sense to treat every non-zero as a one, as the former does.

-'unique' assertions: Keyword assertion applicable to case blocks. It asserts that for any given case
expression, at most only a single case item matches. The branches may, and therefore will, be evaluated
in parallel. Why not just use a 'dumby' default case? Well, it can hide bugs, is ambiguous in intent, and
can produce worst hardware. Also from a maintenance perspective - if something changes along the line,
an overlapping pattern can accidentally occur.

- If-else usage
Recall that instructions in combinational blocks are executed sequentially - so last assignment wins.
For blank to override, as desired, specify the case block as the 'else' path of the if-statment.
*/

`timescale 1ns / 1ps

module seven_segment #(
    parameter int ACTIVE_LOW = 1
) (
    input  logic [3:0] digit,
    input  logic       blank,
    output logic [6:0] segments
);
  logic [6:0] segments_active_high;
  assign segments = (ACTIVE_LOW != 0) ? ~segments_active_high : segments_active_high;

  always_comb begin
    if (blank) segments_active_high = 7'b0000000;
    else
      unique case (digit)  //unique assertion
        4'h0: segments_active_high = 7'b0111111;  // a,b,c,d,e,f
        4'h1: segments_active_high = 7'b0000110;  // b,c
        4'h2: segments_active_high = 7'b1011011;  // a,b,d,e,g
        4'h3: segments_active_high = 7'b1001111;  // a,b,c,d,g
        4'h4: segments_active_high = 7'b1100110;  // b,c,f,g
        4'h5: segments_active_high = 7'b1101101;  // a,c,d,f,g
        4'h6: segments_active_high = 7'b1111101;  // a,c,d,e,f,g
        4'h7: segments_active_high = 7'b0000111;  // a,b,c
        4'h8: segments_active_high = 7'b1111111;  // a,b,c,d,e,f,g
        4'h9: segments_active_high = 7'b1101111;  // a,b,c,d,f,g
        4'ha: segments_active_high = 7'b1110111;  // a,b,c,e,f,g
        4'hb: segments_active_high = 7'b1111100;  // c,d,e,f,g
        4'hc: segments_active_high = 7'b0111001;  // a,d,e,f
        4'hd: segments_active_high = 7'b1011110;  // b,c,d,e,g
        4'he: segments_active_high = 7'b1111001;  // a,d,e,f,g
        4'hf: segments_active_high = 7'b1110001;  // a,e,f,g
      endcase
  end
endmodule
