`timescale 1ns / 1ps

module tb_uart_rx;

    // Clock generation
    reg clk = 0;
    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // DUT Inputs
    reg reset_n;
    reg rx;
    reg [2:0] dbit_select_i;
    reg [1:0] sbit_select_i;
    reg [1:0] parity_select_i;
    reg [3:0] baud_rate_sel;

    // DUT Outputs
    wire rx_done_tick;
    wire [7:0] rx_dout;
    wire parity_error;
    wire frame_error;

    // Baud generator output
    wire s_tick;

    // DUT Instance
    uart_rx uut (
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .s_tick(s_tick),
        .dbit_select_i(dbit_select_i),
        .sbit_select_i(sbit_select_i),
        .parity_select_i(parity_select_i),
        .rx_done_tick(rx_done_tick),
        .rx_dout(rx_dout),
        .parity_error(parity_error),
        .frame_error(frame_error)
    );

    // Baud Generator Instance
    baud_generator baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .baud_rate_sel(4'd8), // 115200 baud
        .tick(s_tick)
    );

    // Wait for N baud ticks
    task wait_s_ticks(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1)
                @(posedge s_tick);
        end
    endtask

    // Reset sequence
    initial begin
        rx = 1;
        reset_n = 0;
        #(CLK_PERIOD * 10);
        reset_n = 1;
    end

    // Main stimulus
    initial begin
        @(posedge reset_n);
        #100;

        // 1) Frame: 0xAC, 8N1
        send_frame(8'hAC, 3'd3, 2'd0, 2'd0); // 8 data, no parity, 1 stop
        wait_s_ticks(16 * 4);

        // 2) Frame: 0x15 (even number of 1s), 7E2
        send_frame(8'h15, 3'd2, 2'd2, 2'd1); // 7 data, even parity, 2 stop
        wait_s_ticks(16 * 4);

        // 3) Frame: 0x1E, 6O1
        send_frame(8'h1E, 3'd1, 2'd0, 2'd2); // 6 data, odd parity, 1 stop
        wait_s_ticks(16 * 4);

        // 4) Frame: 0x1B, 5N1
        send_frame(8'h1B, 3'd0, 2'd0, 2'd0); // 5 data, no parity, 1 stop
        wait_s_ticks(16 * 4);

        // 5) Frame: 0xA5, 8E1
        send_frame(8'hA5, 3'd3, 2'd0, 2'd1); // 8 data, even parity, 1 stop
        wait_s_ticks(16 * 4);

        // 6) Frame: 0x55, 8O2
        send_frame(8'h55, 3'd3, 2'd2, 2'd2); // 8 data, odd parity, 2 stop
        wait_s_ticks(16 * 4);

        $finish;
    end

    // Send a full UART frame with config
    task send_frame(input [7:0] data, input [2:0] dbits, input [1:0] sbits, input [1:0] parity);
        integer i;
        begin
            dbit_select_i     = dbits;
            sbit_select_i     = sbits;
            parity_select_i   = parity;

            send_bit(0); // Start bit
            send_data(data, dbits + 5); // 5 + dbits gives correct # of bits: (5,6,7,8)

            if (parity != 2'd0)
                send_parity(data, dbits + 5, parity == 2'd1); // Even=1, Odd=2

            for (i = 0; i <= sbits; i = i + 1)
                send_bit(1); // Stop bits
        end
    endtask

    // Send one bit for 16 s_ticks
    task send_bit(input bit);
        begin
            rx = bit;
            wait_s_ticks(16);
        end
    endtask

    // Send N data bits (LSB first)
    task send_data(input [7:0] data, input integer nbits);
        integer i;
        begin
            for (i = 0; i < nbits; i = i + 1)
                send_bit(data[i]);
        end
    endtask

    // Send parity bit
    task send_parity(input [7:0] data, input integer nbits, input is_even);
    reg parity;
    reg [7:0] masked_data;
    begin
        // Mask data to include only the relevant number of bits
        masked_data = data & ((1 << nbits) - 1);

        // Calculate parity: ^ is the reduction XOR operator
        parity = ^masked_data;

        // Even parity: send 0 if # of 1's is even
        // Odd parity: send 1 if # of 1's is even
        if (is_even)
            send_bit(parity);  // Even parity
        else
            send_bit(~parity);   // Odd parity
    end
endtask


endmodule
