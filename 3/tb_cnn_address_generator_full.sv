`timescale 1ns/1ps

module tb_cnn_address_generator_full;

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

    reg finished = 0;

    cnn_address_generator dut (
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

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cnn_address_generator_full.vcd");
        $dumpvars(0, tb_cnn_address_generator_full);

        repeat (2) @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Check the active scan state before every rising edge.
        while (!finished && timeout < 70000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;

            // Check the address corresponding to the current scan position.
            if (read_en) begin
                windows = windows + 1;

                if (bank0 !== col[1:0] ||
                    bank1 !== ((col + 8'd1) & 8'd3) ||
                    bank2 !== ((col + 8'd2) & 8'd3)) begin
                    $display("FAIL bank mapping row=%0d col=%0d",
                             row, col);
                    errors = errors + 1;
                end

                if (addr0 !== (row * 64 + col / 4) ||
                    addr1 !== (row * 64 + (col + 1) / 4) ||
                    addr2 !== (row * 64 + (col + 2) / 4)) begin
                    $display("FAIL address row=%0d col=%0d",
                             row, col);
                    errors = errors + 1;
                end

                if ((row == 0 && col == 0) ||
                    (row == 0 && col == 253) ||
                    (row == 255 && col == 253)) begin
                    $display(
                        "CHECK row=%0d col=%0d banks=%0d,%0d,%0d addresses=%0d,%0d,%0d",
                        row, col, bank0, bank1, bank2,
                        addr0, addr1, addr2
                    );
                end
            end

            if (scan_done)
                finished = 1;
        end

        if (!finished) begin
            $display("FAIL: scan timeout");
            errors = errors + 1;
        end

        // The final scan position must also be included.
        if (windows != 65024) begin
            $display("FAIL expected 65024 windows, got %0d", windows);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ADDRESS GENERATOR FULL SCAN PASSED: %0d windows",
                     windows);
        else
            $display("ADDRESS GENERATOR FULL SCAN FAILED: %0d errors",
                     errors);

        $finish;
    end

endmodule
