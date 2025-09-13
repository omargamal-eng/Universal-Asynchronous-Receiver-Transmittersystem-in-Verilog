`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2025 08:09:39 PM
// Design Name: 
// Module Name: tb_uart_tx
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


module tb_uart_tx;

    // Testbench signals
    reg clk;
    reg reset_n;
    reg tx_start;
    reg [7:0] tx_din;

    // New control signals for the DUT
    reg [2:0] dbit_select_i;  // 000: 5 bits ... 011: 8 bits
    reg [1:0] sbit_select_i;  // 00: 1, 01: 1.5, 10: 2 stop bits
    reg [1:0] parity_select_i;// 00: None, 01: Even, 10: Odd

    // Wires from the DUT
    wire tx;
    wire tx_done_tick;

    // Baud rate generator signals
    reg [3:0] baud_rate_sel;
    wire s_tick;

    // Instantiate the modified Design Under Test (DUT)
    // Note: Parameters are removed as they are now control inputs.
    uart_tx uut (
        .clk(clk),
        .reset_n(reset_n),
        .tx_start(tx_start),
        .s_tick(s_tick),
        .tx_din(tx_din),
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // Instantiate the baud_generator (assuming it exists in the project)
    // This module provides the s_tick required by the uart_tx module.
    baud_generator baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .baud_rate_sel(baud_rate_sel),
        .tick(s_tick)
    );

    // 1. Clock Generation (100 MHz clock -> 10ns period)
    localparam CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 2. Test Sequence
    initial begin
        // Initialize all inputs to a known state
        tx_start        = 1'b0;
        tx_din          = 8'h00;
        dbit_select_i   = 3'b011; // Default to 8 bits
        sbit_select_i   = 2'b00;  // Default to 1 stop bit
        parity_select_i = 2'b00;  // Default to no parity
        baud_rate_sel   = 4'd8;   // Set a fixed baud rate for testing (e.g., 115200)

        // Apply reset
        reset_n = 1'b0;
        #(CLK_PERIOD * 5); // Hold reset for 5 clock cycles
        reset_n = 1'b1;
        #(CLK_PERIOD * 2);

        // --- Test Cases ---

        // Case 1: Standard 8-N-1 (8 data bits, No parity, 1 stop bit)
        // Data: 0xAC (10101100)
        send_byte(8'hAC, 3'b011, 2'b00, 2'b00);

        // Case 2: 7-E-2 (7 data bits, Even parity, 2 stop bits)
        // Data: 0x55 (01010101+). For 7 bits (1010101), XOR sum is 1 (5 ones). Even parity bit should be 1.
        send_byte(8'h55, 3'b010, 2'b10, 2'b01);

        // Case 3: 8-O-1.5 (8 data bits, Odd parity, 1.5 stop bits)
        // Data: 0xF0 (11110000). XOR sum is 0 (4 ones). Odd parity bit should be 1.
        send_byte(8'hF0, 3'b011, 2'b01, 2'b10);

        // Case 4: 5-N-1 (5 data bits, No parity, 1 stop bit)
        // Data: 0x15 (00010101). For 5 bits (10101), this will be transmitted.
        send_byte(8'h15, 3'b000, 2'b00, 2'b00);

        // Case 5: 6-E-1 (6 data bits, Even parity, 1 stop bit)
        // Data: 0x2A (00101010). For 6 bits (101010), XOR sum is 1 (3 ones). Even parity should be 1.
        send_byte(8'h2A, 3'b001, 2'b00, 2'b01);

        // Case 6: Back-to-back transmission test (8-N-1)
        send_byte(8'hAA, 3'b011, 2'b00, 2'b00);
        send_byte(8'h55, 3'b011, 2'b00, 2'b00);

        // End simulation
        #(CLK_PERIOD * 100);
        $finish;
    end

    // Task to send a byte with specified UART parameters.
    // This makes the test sequence cleaner and easier to read.
    task send_byte (
        input [7:0] data,
        input [2:0] dbit_sel,
        input [1:0] sbit_sel,
        input [1:0] parity_sel
    );
    begin
        // Wait for a positive clock edge to ensure we are not at a transition point.
        @(posedge clk);

        // Set parameters for this transmission
        tx_din          <= data;
        dbit_select_i   <= dbit_sel;
        sbit_select_i   <= sbit_sel;
        parity_select_i <= parity_sel;
        tx_start        <= 1'b1;

        // Hold start for one clock cycle
        @(posedge clk);
        tx_start <= 1'b0;

        // Wait for the transmission to complete, indicated by the tx_done_tick pulse.
        wait (tx_done_tick == 1'b1);
        @(posedge clk); // Move past the done tick to avoid race conditions.

        // Add a small delay between transmissions for better waveform clarity.
        #(CLK_PERIOD * 20);
    end
    endtask

endmodule