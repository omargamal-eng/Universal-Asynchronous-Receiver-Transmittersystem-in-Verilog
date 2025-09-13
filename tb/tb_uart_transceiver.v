`timescale 1ns / 1ps

module tb_uart_transceiver;

    localparam CLK_PERIOD = 10; // 100 MHz

    // Clock and reset
    reg clk;
    reg reset_n;

    // UART 1 signals (TX)
    reg [7:0] w_data_1;
    reg       wr_uart_1;
    wire      tx_full_1;
    wire      tx_1;
    wire [7:0] r_data_1;
    reg       rd_uart_1;
    wire      rx_empty_1;
    wire      parity_error_1;

    // UART 2 signals (RX)
    wire [7:0] r_data_2;
    reg       rd_uart_2;
    wire      rx_empty_2;
    wire      parity_error_2;
    reg [7:0] w_data_2;
    reg       wr_uart_2;
    wire      tx_full_2;
    wire      tx_2;

    // UART config (shared)
    reg [3:0] baud_rate_sel;
    reg [2:0] dbit_select_i;
    reg [1:0] sbit_select_i;
    reg [1:0] parity_select_i;

    // DUT1 (Transmitter)
    uart_transceiver dut1 (
        .clk(clk),
        .reset_n(reset_n),
        .r_data(r_data_1),
        .rd_uart(rd_uart_1),
        .rx_empty(rx_empty_1),
        .rx(tx_2),
        .parity_error(parity_error_1),
        .baud_rate_sel(baud_rate_sel),
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i),
        .w_data(w_data_1),
        .wr_uart(wr_uart_1),
        .tx_full(tx_full_1),
        .tx(tx_1)
    );

    // DUT2 (Receiver)
    uart_transceiver dut2 (
        .clk(clk),
        .reset_n(reset_n),
        .r_data(r_data_2),
        .rd_uart(rd_uart_2),
        .rx_empty(rx_empty_2),
        .rx(tx_1),
        .parity_error(parity_error_2),
        .baud_rate_sel(baud_rate_sel),
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i),
        .w_data(w_data_2),
        .wr_uart(wr_uart_2),
        .tx_full(tx_full_2),
        .tx(tx_2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Test sequence
    initial begin
        // Reset and init
        reset_n = 0;
        wr_uart_1 = 0; wr_uart_2 = 0;
        rd_uart_1 = 0; rd_uart_2 = 0;
        w_data_1 = 8'h00; w_data_2 = 8'h00;

        // UART config: 8 data bits, even parity, 1 stop bit = 8-E-1
        baud_rate_sel    = 4'd8;
        dbit_select_i    = 3'b011; // 8 bits
        sbit_select_i    = 2'b00;  // 1 stop bit
        parity_select_i  = 2'b01;  // Even parity

        // Apply reset
        #(CLK_PERIOD * 5);
        reset_n = 1;
        #(CLK_PERIOD * 5);

        // ========== First Frame ==========
        wait (tx_full_1 == 0);
        @(posedge clk);
        w_data_1  <= 8'h41;  // 'A'
        wr_uart_1 <= 1;
        @(posedge clk);
        wr_uart_1 <= 0;
        w_data_1  <= 8'h00;

        wait (rx_empty_2 == 0);
        @(posedge clk);
        rd_uart_2 <= 1;
        @(posedge clk);
        rd_uart_2 <= 0;

        #(CLK_PERIOD * 100);

        // ========== Second Frame ==========
        wait (tx_full_1 == 0);
        @(posedge clk);
        w_data_1  <= 8'h42;  // 'B'
        wr_uart_1 <= 1;
        @(posedge clk);
        wr_uart_1 <= 0;

        wait (rx_empty_2 == 0);
        @(posedge clk);
        rd_uart_2 <= 1;
        @(posedge clk);
        rd_uart_2 <= 0;

        #(CLK_PERIOD * 100);

        // ========== Test with Odd Parity ==========
        parity_select_i = 2'b01;  // Odd parity
        #(CLK_PERIOD * 20);

        wait (tx_full_1 == 0);
        @(posedge clk);
        w_data_1 <= 8'h55;  // 'U'
        wr_uart_1 <= 1;
        @(posedge clk);
        wr_uart_1 <= 0;

        wait (rx_empty_2 == 0);
        @(posedge clk);
        rd_uart_2 <= 1;
        @(posedge clk);
        rd_uart_2 <= 0;

        #(CLK_PERIOD * 100);

        // ========== Test with 7 Data Bits ==========
        dbit_select_i = 3'b010; // 7 bits
        #(CLK_PERIOD * 20);

        wait (tx_full_1 == 0);
        @(posedge clk);
        w_data_1 <= 8'h66;  // 'f'
        wr_uart_1 <= 1;
        @(posedge clk);
        wr_uart_1 <= 0;

        wait (rx_empty_2 == 0);
        @(posedge clk);
        rd_uart_2 <= 1;
        @(posedge clk);
        rd_uart_2 <= 0;

        #(CLK_PERIOD * 100);

        // ========== Test with No Parity ==========
        parity_select_i = 2'b00;  // No parity
        #(CLK_PERIOD * 20);

        wait (tx_full_1 == 0);
        @(posedge clk);
        w_data_1 <= 8'h99;  // 0x99
        wr_uart_1 <= 1;
        @(posedge clk);
        wr_uart_1 <= 0;

        wait (rx_empty_2 == 0);
        @(posedge clk);
        rd_uart_2 <= 1;
        @(posedge clk);
        rd_uart_2 <= 0;

        #(CLK_PERIOD * 200);
        $finish;
    end

endmodule
