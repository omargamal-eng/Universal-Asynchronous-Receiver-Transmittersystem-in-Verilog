`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 06:28:01 AM
// Design Name: UART Transceiver
// Module Name: uart_transceiver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Full-duplex UART transceiver with programmable baud rate, 
//              parity, data bits, and stop bits using FIFOs.
// 
// Dependencies: 
// - baud_generator
// - uart_rx
// - uart_tx
// - fifo_generator_0 (for both RX and TX FIFOs)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_transceiver (
    input              clk,
    input              reset_n,

    // Receiver port
    output      [7:0]  r_data,
    input              rd_uart,
    output             rx_empty,
    input              rx,
    output             parity_error,

    // Control configuration
    input       [3:0]  baud_rate_sel,
    input       [2:0]  dbit_select_i,
    input       [1:0]  sbit_select_i,
    input       [1:0]  parity_select_i,

    // Transmitter port
    input       [7:0]  w_data,
    input              wr_uart,
    output             tx_full,
    output             tx
);

    // Tick signal from baud generator
    wire s_tick;

    // TX done signal
    wire tx_done_tick;

    // RX data and done tick
    wire        rx_done_tick;
    wire [7:0]  rx_dout;

    // TX FIFO signals
    wire [7:0]  tx_fifo_out;
    wire        tx_fifo_empty;

    ////////////////////////////////////////////////////////
    // Baud Rate Generator
    ////////////////////////////////////////////////////////
    baud_generator baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .baud_rate_sel(baud_rate_sel),
        .tick(s_tick)
    );

    ////////////////////////////////////////////////////////
    // UART Receiver with configurable format
    ////////////////////////////////////////////////////////
    uart_rx receiver (
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .s_tick(s_tick),
        .rx_done_tick(rx_done_tick),
        .rx_dout(rx_dout),
        .parity_error(parity_error),
        .frame_error(),  // Optional, unconnected
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i)
    );

    ////////////////////////////////////////////////////////
    // RX FIFO (stores received data)
    ////////////////////////////////////////////////////////
    fifo_generator_0 rx_fifo (
        .clk(clk),
        .srst(~reset_n),
        .din(rx_dout),
        .wr_en(rx_done_tick),
        .rd_en(rd_uart),
        .dout(r_data),
        .full(),         // Optional, not used
        .empty(rx_empty)
    );

    ////////////////////////////////////////////////////////
    // TX FIFO (buffers data to be transmitted)
    ////////////////////////////////////////////////////////
    fifo_generator_0 tx_fifo (
        .clk(clk),
        .srst(~reset_n),
        .din(w_data),
        .wr_en(wr_uart),
        .rd_en(tx_done_tick),
        .dout(tx_fifo_out),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    ////////////////////////////////////////////////////////
    // UART Transmitter with configurable format
    ////////////////////////////////////////////////////////
    uart_tx transmitter (
        .clk(clk),
        .reset_n(reset_n),
        .tx_start(~tx_fifo_empty),  // ⚠️ Consider pulsing this instead (see note below)
        .s_tick(s_tick),
        .tx_din(tx_fifo_out),
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

endmodule
