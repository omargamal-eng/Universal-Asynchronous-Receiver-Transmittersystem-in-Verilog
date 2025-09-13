`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2025 04:33:00 PM
// Design Name: 
// Module Name: tb_baud_generator
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

module tb_baud_generator;

    // Testbench signals
    reg clk;
    reg reset_n;
    reg [3:0] baud_rate_sel;
    wire tick;
    
    // Instantiate the Design Under Test (DUT)
    baud_generator dut (
        .clk(clk),
        .reset_n(reset_n),
        .baud_rate_sel(baud_rate_sel),
        .tick(tick)
    );

    // 1. Clock Generation (100 MHz clock -> 10ns period)
    localparam CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 2. Test Sequence
    initial begin
        
        // Apply reset
        reset_n = 1'b0;
        # (CLK_PERIOD * 5); // Hold reset for 5 clock cycles
        reset_n = 1'b1;
        baud_rate_sel = 4'd8;
        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd6;
//        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd7;
//        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd3;
//        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd0;
//        # (CLK_PERIOD * 30000);
//        baud_rate_sel = 4'd1;
//        # (CLK_PERIOD * 30000);
//        baud_rate_sel = 4'd5;
//        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd8;
//        # (CLK_PERIOD * 5000);
//        baud_rate_sel = 4'd2;
        
    end

endmodule
