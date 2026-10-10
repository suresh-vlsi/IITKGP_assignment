`timescale 1ns/1ps

module tb_cnn_address_generator_points;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    wire read_en, scan_done;
    wire [7:0] row, col;
    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;

    integer errors = 0;

    cnn_address_generator dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .read_en(read_en), .row(row), .col(col),
        .scan_done(scan_done),
        .bank0(bank0), .bank1(bank1), .bank2(bank2),
        .addr0(addr0), .addr1(addr1), .addr2(addr2)
    );

    always #5 clk = ~clk;

    task check_position;
        input [7:0] test_row;
        input [7:0] test_col;
        begin
            if (bank0 !== test_col[1:0] ||
                bank1 !== ((test_col + 1) & 3) ||
                bank2 !== ((test_col + 2) & 3) ||
                addr0 !== (test_row * 64 + test_col / 4) ||
                addr1 !== (test_row * 64 + (test_col + 1) / 4) ||
                addr2 !== (test_row * 64 + (test_col + 2) / 4)) begin
                $display("FAIL row=%0d col=%0d", test_row, test_col);
                errors = errors + 1;
            end
            else
                $display("PASS row=%0d col=%0d", test_row, test_col);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // Wait until the first active scan position is stable.
        wait (read_en);
        #1;
        check_position(0, 0);

        // Check the first row's last legal window.
        wait (row == 0 && col == 253);
        #1;
        check_position(0, 253);

        // Check the final image row's last legal window.
        wait (row == 255 && col == 253);
        #1;
        check_position(255, 253);

        wait (scan_done);
        #1;

        if (errors == 0)
            $display("POINT CHECKS PASSED");
        else
            $display("POINT CHECKS FAILED: %0d errors", errors);

        $finish;
    end

    initial begin
        #700000;
        $display("ERROR: timeout");
        $finish;
    end

endmodule
