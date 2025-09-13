module uart_rx (
    input       clk,
    reset_n,  // Clock and active-low reset
    input       rx,
    s_tick,  // Serial RX input, and baud rate tick
    input [2:0] dbit_select_i,   // 000: 5 bits to 011: 8 bits
    input [1:0] sbit_select_i,   // 00: 1 stop, 01: 1.5 stop, 10: 2 stop bits
    input [1:0] parity_select_i, // 00: None, 01: Even, 10: Odd

    output reg       rx_done_tick,  // High for one cycle when byte received
    output reg [7:0] rx_dout,       // Received data byte (max 8 bits)
    output           parity_error,  // High if parity error detected
    output reg       frame_error    // High if stop bit is incorrect
);

  // FSM state encoding
  localparam idle = 3'd0;
  localparam start = 3'd1;
  localparam data = 3'd2;
  localparam parity = 3'd3;
  localparam stop = 3'd4;

  // Registers
  reg [2:0] state_reg, state_next;  // FSM current and next state
  reg [4:0] s_reg, s_next;  // Sample tick counter (max 31)
  reg [2:0] n_reg, n_next;  // Bit counter (max 7)
  reg [7:0] b_reg, b_next;  // Data shift register
  reg p_reg, p_next;  // Parity bit register
  reg rx_reg, rx_next;  // RX sampled register
  reg parity_error_next, parity_error_reg;

  // Derived parameters from control inputs
  wire [2:0] data_bits_to_rx;  // Number of data bits to receive - 1
  wire [4:0] stop_ticks;  // Stop bit duration in s_ticks
  wire       parity_en;  // Parity enabled signal
  reg        parity_calc;  // Calculated parity from data bits
  wire       parity_expected;  // Expected parity bit (even/odd logic)

  // Number of data bits = dbit_select_i + 5
  assign data_bits_to_rx = dbit_select_i + 3'd4;

  // Parity enable
  assign parity_en = (parity_select_i != 2'b00);

  // Stop bit duration logic
  assign stop_ticks = (sbit_select_i == 2'b00) ? 5'd15 :  // 1 stop
      (sbit_select_i == 2'b01) ? 5'd23 :  // 1.5 stop
      5'd31;  // 2 stop

  // Parity calculation (XOR of received bits)
  always @(*) begin
    parity_calc = (rx_dout === rx_dout) ? ^rx_dout : 1'b0;
  end

  // Choose even or odd parity
  assign parity_expected = (parity_select_i == 2'b01) ? parity_calc : ~parity_calc;

  // Sequential logic for registers
  always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
      state_reg        <= idle;
      s_reg            <= 0;
      n_reg            <= 0;
      b_reg            <= 0;
      p_reg            <= 0;
      rx_reg           <= 1'b1;
      parity_error_reg <= 0;
    end else begin
      state_reg        <= state_next;
      s_reg            <= s_next;
      n_reg            <= n_next;
      b_reg            <= b_next;
      p_reg            <= p_next;
      rx_reg           <= rx_next;
      parity_error_reg <= parity_error_next;
    end
  end

  // Next-state logic (FSM + datapath control)
  always @(*) begin
    // Default values
    state_next        = state_reg;
    s_next            = s_reg;
    n_next            = n_reg;
    b_next            = b_reg;
    p_next            = p_reg;
    rx_done_tick      = 1'b0;
    parity_error_next = parity_error_reg;
    frame_error       = 1'b0;
    rx_next           = rx;
    rx_dout           = 0;

    case (state_reg)
      // Idle state: wait for falling edge (start bit)
      idle: begin
        if (~rx) begin
          state_next = start;
          s_next     = 0;
        end
      end

      // Start bit detection (sample in middle)
      start: begin
        if (s_tick) begin
          if (s_reg == 7) begin  // Mid-sample (assuming 16x oversampling)
            if (~rx) state_next = data;
            else state_next = idle;  // False start bit
            s_next = 0;
            n_next = 0;
          end else begin
            s_next = s_reg + 1;
          end
        end
      end

      // Receive data bits (LSB first)
      data: begin
        if (s_tick) begin
          if (s_reg == 15) begin  // Sample bit
            s_next = 0;
            b_next = {rx, b_reg[7:1]};  // Shift right
            if (n_reg == data_bits_to_rx) begin
              if (parity_en) state_next = parity;
              else state_next = stop;
            end else begin
              n_next = n_reg + 1;
            end
          end else begin
            s_next = s_reg + 1;
          end
        end
      end

      // Optional parity bit reception
      parity: begin
        if (s_tick) begin
          if (s_reg == 15) begin
            s_next = 0;
            p_next = rx;
            state_next = stop;
          end else begin
            s_next = s_reg + 1;
          end
        end
      end

      // Stop bit sampling
      stop: begin
        if (s_tick) begin
          if (s_reg == stop_ticks) begin
            state_next   = idle;
            rx_done_tick = 1'b1;
            case (data_bits_to_rx)
              'd4: rx_dout = {3'b000, b_reg[7:3]};
              'd5: rx_dout = {2'b00, b_reg[7:2]};
              'd6: rx_dout = {1'b0, b_reg[7:1]};
              'd7: rx_dout = b_reg;
              default: rx_dout = b_reg;
            endcase
            if (parity_select_i != 0)
              if (p_reg != parity_expected) parity_error_next = 1'b1;
              else parity_error_next = 1'b0;
            if (~rx) frame_error = 1'b1;
          end else begin
            s_next = s_reg + 1;
          end
        end
      end

      // Default safety fallback
      default: state_next = idle;
    endcase
  end
  assign parity_error = parity_error_reg;

endmodule
