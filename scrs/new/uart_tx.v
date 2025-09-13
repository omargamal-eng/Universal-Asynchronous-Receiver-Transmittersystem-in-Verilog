module uart_tx (
    input clk,
    reset_n,
    input tx_start,
    s_tick,

    // Control Inputs
    input [7:0] tx_din,          // 8-bit data input (max data width)
    input [2:0] dbit_select_i,   // 000: 5 bits, ..., 011: 8 bits
    input [1:0] sbit_select_i,   // 00: 1, 01: 1.5, 10: 2 stop bits
    input [1:0] parity_select_i, // 00: None, 01: Even, 10: Odd

    // Outputs
    output reg tx_done_tick,
    output tx
);

  // FSM States
  localparam idle = 0, start = 1, data = 2, parity = 3, stop = 4;

  // Registers
  reg [2:0] state_reg, state_next;
  reg [4:0] s_reg, s_next;  // Counter for baud ticks (up to 32 for 2 stop bits)
  reg [2:0] n_reg, n_next;  // Counter for data bits (up to 8)
  reg [7:0] b_reg, b_next;  // Data shift register
  reg p_reg, p_next;  // Parity bit register
  reg tx_reg, tx_next;  // Transmit line register

  // Helper logic for control inputs
  wire [2:0] data_bits_to_tx;  // Index of the last data bit (e.g., 4 for 5 bits)
  wire [4:0] stop_ticks;  // Total ticks for the stop bit duration
  wire       parity_en;  // Parity is enabled
  wire       calculated_parity;  // The final calculated parity bit to transmit
  reg        parity_xor_sum;  // Intermediate XOR sum for parity calculation

  assign data_bits_to_tx = dbit_select_i + 3'd4;
  assign parity_en = (parity_select_i != 2'b00);

  // Determine stop bit duration in ticks based on selection
  assign stop_ticks = (sbit_select_i == 2'b00) ? 5'd15 :  // 1 Stop Bit
      (sbit_select_i == 2'b01) ? 5'd23 :  // 1.5 Stop Bits
      5'd31;  // 2 Stop Bits

  // State and data registers
  always @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
      state_reg <= idle;
      s_reg     <= 0;
      n_reg     <= 0;
      b_reg     <= 0;
      p_reg     <= 0;
      tx_reg    <= 1'b1;  // UART is idle high
    end else begin
      state_reg <= state_next;
      s_reg     <= s_next;
      n_reg     <= n_next;
      b_reg     <= b_next;
      p_reg     <= p_next;
      tx_reg    <= tx_next;
    end
  end

  // Combinational logic for parity calculation
  always @(*) begin
    case (data_bits_to_tx)
      3'd4:    parity_xor_sum = ^(tx_din[4:0]); // 5 data bits
      3'd5:    parity_xor_sum = ^(tx_din[5:0]); // 6 data bits
      3'd6:    parity_xor_sum = ^(tx_din[6:0]); // 7 data bits
      3'd7:    parity_xor_sum = ^(tx_din[7:0]); // 8 data bits
      default: parity_xor_sum = 1'b0;
    endcase
  end

  // For Even parity, transmit the XOR sum. For Odd, transmit the inverted sum.
  assign calculated_parity = (parity_select_i == 2'b01) ? parity_xor_sum : ~parity_xor_sum;

  // Next-state logic for FSM
  always @(*) begin
    // Default assignments
    state_next = state_reg;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;
    p_next = p_reg;
    tx_done_tick = 1'b0;
    tx_next = tx_reg;

    case (state_reg)
      idle: begin
        tx_next = 1'b1;
        if (tx_start) begin
          state_next = start;
          b_next = tx_din;
          p_next = calculated_parity;  // Latch calculated parity
          s_next = 0;
        end
      end
      start: begin
        tx_next = 1'b0;  // Start bit
        if (s_tick)
          if (s_reg == 15) begin
            state_next = data;
            s_next = 0;
            n_next = 0;
          end else s_next = s_reg + 1;
      end
      data: begin
        tx_next = b_reg[0];  // Transmit LSB first
        if (s_tick)
          if (s_reg == 15) begin
            s_next = 0;
            b_next = {1'b0, b_reg[7:1]};  // Right shift for next bit
            if (n_reg == data_bits_to_tx)  // Check if all data bits are sent
              if (parity_en) state_next = parity;
              else state_next = stop;
            else n_next = n_reg + 1;
          end else s_next = s_reg + 1;
      end
      parity: begin
        tx_next = p_reg;  // Transmit latched parity bit
        if (s_tick)
          if (s_reg == 15) begin
            state_next = stop;
            s_next = 0;
          end else s_next = s_reg + 1;
      end
      stop: begin
        tx_next = 1'b1;  // Stop bit
        if (s_tick)
          if (s_reg == (stop_ticks)) begin
            tx_done_tick = 1'b1;
            state_next   = idle;
          end else s_next = s_reg + 1;
      end
      default: state_next = idle;
    endcase
  end

  // Output logic
  assign tx = tx_reg;

endmodule
