/* Binary to binary-coded decimal
Ports:
[6:0] bin  - binary input, 0-99 (NOT 100-128, no safety nets needed here)
[3:0] tens - decimal tens digit (BCD) (0-9)
[3:0] ones - decimal ones digit (BCD) (0-9)
*/

`timescale 1ns / 1ps
module binary_to_bcd (
    input  logic [6:0] bin,
    output logic [3:0] tens,
    output logic [3:0] ones
);
  assign tens = 4'(bin / 7'd10);  // 7-bit division, result can guaranteed be contained in 4 (0-9)
  assign ones = 4'(bin % (7'd10));
endmodule
