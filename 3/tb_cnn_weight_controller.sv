`timescale 1ns/1ps
module tb_cnn_weight_controller;
reg clk;
    reg rst_n;
    reg start;
wire wt_wr_en;
    wire [3:0] wt_addr;
    wire [7:0] wt_data;
    wire scan_done;
    wire [1:0] state;
integer errors;
    integer writes;
cnn_weight_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .wt_wr_en(wt_wr_en),
        .wt_addr(wt_addr),
        .wt_data(wt_data),
        .scan_done(scan_done),
        .state(state)
    );
initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
initial begin
        $dumpfile("cnn_weight_controller.vcd");
        $dumpvars(0, tb_cnn_weight_controller);
errors = 0;
        writes = 0;
        rst_n = 0;
        start = 0;
// Hold reset for two clock edges.
        repeat (2) @(negedge clk);
        rst_n = 1;
// Start the weight-loading sequence.
        @(negedge clk);
        start = 1;
// Observe all nine weight writes.
        while (writes<9) begin
            @(negedge clk);
if (wt_wr_en) begin
                $display(
                    "WEIGHT WRITE: addr=%0d data=0x%02h",
                    wt_addr, wt_data
                );
if (wt_addr !== writes[3:0])
                    errors = errors + 1;
case (writes)
                    0, 3, 6:
                        if (wt_data !== 8'h01)
                            errors = errors + 1;
                    1, 4, 7:
                        if (wt_data !== 8'h00)
                            errors = errors + 1;
                    2, 5, 8:
                        if (wt_data !== 8'hFF)
                            errors = errors + 1;
                endcase
writes = writes + 1;
            end
        end
// Wait for completion.
        wait (scan_done === 1'b1);
        $display("scan_done asserted.");
if (errors == 0)
            $display("PART 1(i) CONTROLLER TEST PASSED");
        else
            $display("PART 1(i) FAILED: %0d errors", errors);
start = 0;
        repeat (2) @(negedge clk);
        $finish;
    end
// Watchdog to prevent a hung simulation.
    initial begin
        #2000;
        $display("ERROR: TESTBENCH TIMEOUT");
        $finish;
    end
endmodule