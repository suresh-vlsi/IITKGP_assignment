
`timescale 1ns/1ps

module tb_cnn_address_generator_rows;

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
    integer expected_addr0;
    integer expected_addr1;
    integer expected_addr2;
    reg finished;

    cnn_address_generator #(
        .LAST_ROW(8'd1),
        .LAST_COL(8'd3)
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

    // 10 ns clock
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

        $dumpfile("cnn_address_generator_rows.vcd");
        $dumpvars(0, tb_cnn_address_generator_rows);

        // Reset
        repeat (2) @(negedge clk);
        rst_n = 1;

        // Start scanning
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Observe each active window away from clock edges.
        while (!scan_done && windows < 12) begin

            if (read_en) begin
                expected_addr0 =
                    row * 64 + col / 4;

                expected_addr1 =
                    row * 64 + (col + 1) / 4;

                expected_addr2 =
                    row * 64 + (col + 2) / 4;

                $display("--------------------------------");
                $display("Window    : %0d", windows);
                $display("Row, Col  : %0d, %0d", row, col);

                $display("Banks     : %0d, %0d, %0d",
                         bank0, bank1, bank2);

                $display("Addresses : %0d, %0d, %0d",
                         addr0, addr1, addr2);

                // Check expected row-major scan order.
                if (row !== (windows / 4) ||
                    col !== (windows % 4)) begin
                    $display("FAIL: row/column sequence");
                    errors = errors + 1;
                end

                // Check cyclic bank selection.
                if (bank0 !== (col % 4) ||
                    bank1 !== ((col + 1) % 4) ||
                    bank2 !== ((col + 2) % 4)) begin
                    $display("FAIL: bank selection");
                    errors = errors + 1;
                end

                // Check local addresses.
                if (addr0 !== expected_addr0 ||
                    addr1 !== expected_addr1 ||
                    addr2 !== expected_addr2) begin
                    $display("FAIL: local address");
                    errors = errors + 1;
                end

                windows = windows + 1;
            end

            @(negedge clk);
        end

        // Completion checks
        if (windows != 8) begin
            $display("FAIL: expected 8 windows, got %0d",
                     windows);
            errors = errors + 1;
        end

        if (scan_done !== 1'b1) begin
            $display("FAIL: scan_done not asserted");
            errors = errors + 1;
        end

        if (read_en !== 1'b0) begin
            $display("FAIL: read_en should be low after scan");
            errors = errors + 1;
        end

        $display("================================");
        if (errors == 0)
            $display("ROW TRANSITION TEST PASSED: %0d windows",
                     windows);
        else
            $display("ROW TRANSITION TEST FAILED: %0d errors",
                     errors);

        $display("================================");

        finished = 1;
        $finish;
    end

    // Bounded simulation watchdog
    initial begin
        #5000;
        if (!finished) begin
            $display("ERROR: TESTBENCH TIMEOUT");
            $finish;
        end
    end

endmodule
