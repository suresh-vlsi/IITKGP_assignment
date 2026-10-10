# Assignment 3 — Part 3 standalone implementation scaffold

These files are intentionally separate from the existing Assignment 3 Part 1 and Part 2 RTL/testbenches.

- `cnn_conv_window_fifo.sv`: 9-sample shift FIFO, exposes `p00` through `p22`, computes signed 3x3 weighted sum, and provides `win_valid_next`/`out_valid`.
- `tb_part3_conv_window_fifo.sv`: drives pixels 1..10 with kernel `[1 0 -1; 1 0 -1; 1 0 -1]`, checks the first full window and next sliding window against expected result -6, and checks valid timing.

Important scope limitation: this is a standalone nine-consecutive-sample FIFO/MAC scaffold. It does not implement row-aware line buffers for a full 256x256 image, nor does it integrate with the existing SRAM/address generator. The assignment PDF does not provide those RTL details, so this must not be described as verification of the original integrated DUT.

Run from this directory with:

```bash
iverilog -g2012 -Wall -s tb_part3_conv_window_fifo -o /tmp/part3.out cnn_conv_window_fifo.sv tb_part3_conv_window_fifo.sv && vvp /tmp/part3.out
```
