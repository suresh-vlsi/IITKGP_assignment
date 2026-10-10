`timescale 1ns/1ps
module tb_cnn_address_generator;
reg clk;
    reg rst_n;
    reg start;
wire read_en;
    wire [7:0] row, col;
    wire scan_done;
wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;
integer errors;
    integer windows;
    reg finished;
cnn_address_generator #(
        .LAST_ROW(8'd0),
        .LAST_COL(8'd7)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .read_en(read_en),
        .row(row),
        .col(col),
        .scan_done(scan_done),
        .bank0(bank0),
        .bank1(bank1),
        .bank2(bank2),
        .addr0(addr0),
        .addr1(addr1),
        .addr2(addr2)
    );
initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
initial begin
        errors = 0;
        windows = 0;
        finished = 0;
rst_n = 0;
        start = 0;
$dumpfile("cnn_address_generator.vcd");
        $dumpvars(0, tb_cnn_address_generator);
repeat (2) @(negedge clk);
        rst_n = 1;
@(negedge clk);
        start = 1;
@(negedge clk);
        start = 0;
// Sample on falling edges, away from counter updates.
        while (!scan_done && windows<20) begin
            if (read_en) begin
                $display(
                    "Window %0d: row=%0d col=%0d banks=%0d,%0d,%0d addr=%0d,%0d,%0d",
                    windows, row, col,
                    bank0, bank1, bank2,
                    addr0, addr1, addr2
                );
if (row !== 8'd0 || col !== windows)
                    errors = errors + 1;
if (bank0 !== (windows % 4) ||
                    bank1 !== ((windows + 1) % 4) ||
                    bank2 !== ((windows + 2) % 4))
                    errors = errors + 1;
if (addr0 !== (windows / 4) ||
                    addr1 !== ((windows + 1) / 4) ||
                    addr2 !== ((windows + 2) / 4))
                    errors = errors + 1;
windows = windows + 1;
            end
@(negedge clk);
        end
if (!scan_done) begin
            $display("FAIL: scan did not complete");
            errors = errors + 1;
        end
if (windows != 8) begin
            $display("FAIL: expected 8 windows, got %0d", windows);
            errors = errors + 1;
        end
if (errors == 0)
            $display("ADDRESS GENERATOR TEST PASSED: %0d windows", windows);
        else
            $display("ADDRESS GENERATOR TEST FAILED: %0d errors", errors);
finished = 1;
        $finish;
    end
// Watchdog
    initial begin
        #5000;
        if (!finished) begin
            $display("ERROR: TESTBENCH TIMEOUT");
            $finish;
        end
    end
endmodule
