# Universal-Asynchronous-Receiver-Transmittersystem-in-Verilog
Got it ✅ — you want a polished **GitHub-style README** version for your UART project. Here’s a clean and professional one (with proper formatting and no contributor/owner details):

---

# 🔌 UART Transceiver in Verilog

<div align="center">
  <img src="https://img.shields.io/badge/Language-Verilog-blue" alt="Language">
  <img src="https://img.shields.io/badge/Status-Completed-brightgreen" alt="Status">
</div>

## 📖 Overview

This project implements a **configurable full-duplex UART (Universal Asynchronous Receiver-Transmitter)** in Verilog.
It supports multiple baud rates, data lengths, parity options, and stop bit configurations — making it adaptable for various communication scenarios.

The design includes:

* UART **Transmitter**
* UART **Receiver**
* **Baud Rate Generator**
* **FIFO Buffers** for smooth data flow
* **Testbenches** for verification

---

## ✨ Features

* **Full-Duplex**: Simultaneous transmit & receive
* **Configurable Baud Rates**: `600` to `115200` (default `9600`)
* **Flexible Data Format**:

  * Data bits: 5, 6, 7, or 8
  * Parity: None, Even, Odd
  * Stop bits: 1, 1.5, 2
* **FIFO Buffers**: Reduce data loss and improve performance
* **Error Flags**: `parity_error`, `frame_error`

---

## 📂 Project Structure

```
.
├── srcs/
│   ├── uart_transceiver.v      # Top-level UART wrapper
│   ├── uart_tx.v               # Transmitter
│   ├── uart_rx.v               # Receiver
│   ├── baud_generator.v        # Baud generator
│   ├── timer_input.v           # Timer module
│   └── fifo_generator_0.v      # FIFO (custom/IP)

├── tb/
│   ├── tb_uart_tx.v            # Transmitter testbench
│   ├── tb_uart_rx.v            # Receiver testbench
│   ├── tb_baud_generator.v     # Baud generator testbench
│   └── tb_uart_transceiver.v   # Full transceiver testbench

├── constraint/                 
│   └── Nexys_4.xdc             # Example constraints

└── README.md
```

---

## 🔧 Configuration

Parameters are set through `uart_transceiver` input ports:

| Port              | Width | Description                               |
| ----------------- | ----- | ----------------------------------------- |
| `baud_rate_sel`   | 4-bit | Selects baud rate (e.g., `4'd8` → 115200) |
| `dbit_select_i`   | 3-bit | Data bits (5–8)                           |
| `sbit_select_i`   | 2-bit | Stop bits (1, 1.5, 2)                     |
| `parity_select_i` | 2-bit | Parity (None, Even, Odd)                  |

---

## 🧪 Simulation & Testing

* **Transmitter Testbench (`tb_uart_tx`)**
  Validates multiple configurations: 8-N-1, 7-E-2, 8-O-1.5, and stress tests

* **Receiver Testbench (`tb_uart_rx`)**
  Simulates UART frames with variable data widths, parity, stop bits, and error conditions

* **Baud Generator Testbench (`tb_baud_generator`)**
  Verifies correct tick generation for all supported baud rates

---

## 🚀 Future Improvements

* AXI/APB bus wrappers for SoC integration
* Auto baud rate detection
* Idle-line and framing watchdog
* Self-checking UVM/SystemVerilog testbenches
* Integration with RISC-V / PicoRV32 cores

---

## 📌 Usage

1. Clone the repository

   ```bash
   git clone https://github.com/your-username/uart-transceiver.git
   cd uart-transceiver
   ```
2. Open the design files in your preferred HDL tool (Vivado, Quartus, ModelSim, etc.)
3. Run the provided testbenches to verify functionality

---

✅ This UART design is modular, configurable, and ready for integration into larger FPGA/SoC projects.
