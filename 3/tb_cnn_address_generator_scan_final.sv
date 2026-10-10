`timescale 1ns/1ps

module tb_cnn_address_generator_scan_fixed;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    wire read_en;
    wire [7:0] row, col;
    wire scan_done;
    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;

    integer windows = 0;
    integer errors = 0;
    integer timeout = 0;
    integer row_windows [0:255];
    integer i;

    cnn_address_generator dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .read_en(read_en), .row(row), .col(col),
        .scan_done(scan_done),
        .bank0(bank0), .bank1(bank1), .bank2(bank2),
        .addr0(addr0), .addr1(addr1), .addr2(addr2)
    );

    always #5 clk = ~clk;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            row_windows[i] = 0;

        repeat (2) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // Count the initial window before the scanner advances.
        if (read_en) begin
            windows = windows + 1;
            row_windows[row] = row_windows[row] + 1;
        end

        // Count the remaining windows.
        while (!scan_done && timeout < 70000) begin
            @(negedge clk);
            timeout = timeout + 1;

            if (read_en) begin
                windows = windows + 1;
                row_windows[row] = row_windows[row] + 1;

                if (col > 253) begin
                    $display("FAIL invalid column: row=%0d col=%0d",
                             row, col);
                    errors = errors + 1;
                end
            end
        end

        for (i = 0; i < 256; i = i + 1) begin
            if (row_windows[i] != 254) begin
                $display("ROW ERROR row=%0d count=%0d",
                         i, row_windows[i]);
                errors = errors + 1;
            end
        end

        $display("Windows observed: %0d (expected 65024)", windows);

        if (windows != 65024) begin
            $display("FAIL: window count mismatch");
            errors = errors + 1;
        end

        if (!scan_done) begin
            $display("FAIL: scan did not complete");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("FULL SCAN TEST PASSED");
        else
            $display("FULL SCAN TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
