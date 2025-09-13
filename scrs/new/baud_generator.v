`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2025 03:54:06 PM
// Design Name: 
// Module Name: baud_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module baud_generator (
    input clk,
    reset_n,
    input [3:0] baud_rate_sel,
    output tick
);


  reg [13:0] FINAL_VALUE;

  // This combinational block selects the counter value for the desired baud rate.
  always @(baud_rate_sel) begin
    case (baud_rate_sel)
      4'd0:
      FINAL_VALUE = 10416; // For 600 baud with 100MHz clock, divisor is 100M / (16 * 600) = 10416.66
      4'd1: FINAL_VALUE = 5208;  // For 1200 baud
      4'd2: FINAL_VALUE = 2604;  // For 2400 baud
      4'd3: FINAL_VALUE = 1302;  // For 4800 baud
      4'd4: FINAL_VALUE = 651;  // For 9600 baud
      4'd5: FINAL_VALUE = 325;  // For 19200 baud
      4'd6: FINAL_VALUE = 162;  // For 38400 baud
      4'd7: FINAL_VALUE = 108;  // For 57600 baud
      4'd8: FINAL_VALUE = 54;  // For 115200 baud
      default: FINAL_VALUE = 651;  // Default to 9600 baud
    endcase
  end
  // Instantiate the timer module which creates the tick.
  // The enable signal is tied high, so it's always running.
  timer_input #(
      .BITS(14)
  ) baud_gen (
      .clk(clk),
      .reset_n(reset_n),
      .enable(1'b1),
      .FINAL_VALUE(FINAL_VALUE),
      .tick(tick)
  );
endmodule
