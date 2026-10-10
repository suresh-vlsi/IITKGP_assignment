`timescale 1ns/1ps

module tb_cnn_input_sram_boundary_check;

    reg clk;
    reg write_en;
    reg [1:0] write_bank;
    reg [13:0] write_addr;
    reg [7:0] write_data;

    reg read_en;
    reg [7:0] start_row;
    reg [7:0] start_col;

    wire [23:0] cnn_data;
    wire out_valid;

    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;
    wire [7:0] pixel0, pixel1, pixel2;

    integer errors;
    integer tests;
    integer row_num;
    integer col_num;
    integer linear_addr;
    integer i;

    cnn_input_sram dut (
        .clk(clk),
        .write_en(write_en),
        .write_bank(write_bank),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_en(read_en),
        .start_row(start_row),
        .start_col(start_col),
        .cnn_data(cnn_data),
        .out_valid(out_valid),
        .bank0(bank0),
        .bank1(bank1),
        .bank2(bank2),
        .addr0(addr0),
        .addr1(addr1),
        .addr2(addr2),
        .pixel0(pixel0),
        .pixel1(pixel1),
        .pixel2(pixel2)
    );

    always #5 clk = ~clk;

    // Deterministic reference pixel value.
    function [7:0] expected_pixel;
        input integer r;
        input integer c;
        begin
            expected_pixel = (r * 17 + c) & 255;
        end
    endfunction

    // Write one pixel using the staggered four-bank mapping.
    task write_pixel;
        input integer r;
        input integer c;
        reg [7:0] value;
        begin
            linear_addr = r * 256 + c;

            @(negedge clk);
            write_en   = 1'b1;
            write_bank = linear_addr % 4;
            write_addr = linear_addr / 4;
            value      = expected_pixel(r, c);
            write_data = value;

            @(negedge clk);
            write_en = 1'b0;
        end
    endtask

    // Check a three-pixel window.
    task check_window;
        input integer r;
        input integer c;
        reg [7:0] p0, p1, p2;
        reg [23:0] expected;
        integer r1, c1, r2, c2;
        begin
            r1 = r;
            c1 = c + 1;
            r2 = r;
            c2 = c + 2;

            if (c1 >= 256) begin
                r1 = r1 + 1;
                c1 = c1 - 256;
            end

            if (c2 >= 256) begin
                r2 = r2 + 1;
                c2 = c2 - 256;
            end

            p0 = expected_pixel(r, c);
            p1 = expected_pixel(r1, c1);
            p2 = expected_pixel(r2, c2);
            expected = {p0, p1, p2};

            @(negedge clk);
            start_row = r;
            start_col = c;
            read_en = 1'b1;

            @(posedge clk);
            #1;
            tests = tests + 1;

            if (out_valid !== 1'b1 || cnn_data !== expected) begin
                $display(
                    "FAIL row=%0d col=%0d expected=%06h actual=%06h valid=%b",
                    r, c, expected, cnn_data, out_valid
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS row=%0d col=%0d banks=%0d,%0d,%0d data=%06h",
                    r, c, bank0, bank1, bank2, cnn_data
                );
            end

            @(negedge clk);
            read_en = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        write_en = 0;
        write_bank = 0;
        write_addr = 0;
        write_data = 0;
        read_en = 0;
        start_row = 0;
        start_col = 0;
        errors = 0;
        tests = 0;

        $dumpfile("cnn_input_sram_boundary_check.vcd");
        $dumpvars(0, tb_cnn_input_sram_boundary_check);

        $display("=== INPUT SRAM BOUNDARY CHECK ===");

        // Populate the pixels around the row boundary.
        for (i = 252; i < 256; i = i + 1)
            write_pixel(0, i);

        write_pixel(1, 0);
        write_pixel(1, 1);

        // Verify windows that cross bank and row boundaries.
        check_window(0, 252);
        check_window(0, 253);
        check_window(0, 254);
        check_window(0, 255);

        // Verify read-disabled behavior.
        @(negedge clk);
        read_en = 0;
        @(posedge clk);
        #1;

        if (out_valid !== 1'b0) begin
            $display("FAIL: out_valid should be low when read_en=0");
            errors = errors + 1;
        end
        else begin
            $display("PASS: read-disabled behavior");
        end

        $display("--------------------------------");
        if (errors == 0)
            $display("BOUNDARY TEST PASSED: %0d windows", tests);
        else
            $display("BOUNDARY TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
