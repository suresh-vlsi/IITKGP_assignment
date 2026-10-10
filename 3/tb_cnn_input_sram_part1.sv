
`timescale 1ns/1ps

module tb_cnn_input_sram_part1;

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
        .bank0(bank0), .bank1(bank1), .bank2(bank2),
        .addr0(addr0), .addr1(addr1), .addr2(addr2),
        .pixel0(pixel0), .pixel1(pixel1), .pixel2(pixel2)
    );

    // 10 ns clock period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Write a pixel according to cyclic bank interleaving.
    task write_pixel;
        input [7:0] row;
        input [7:0] col;
        input [7:0] data;
        integer b;
        integer a;
        begin
            b = col % 4;
            a = row * 64 + col / 4;

            @(negedge clk);
            write_en   = 1;
            write_bank = b;
            write_addr = a;
            write_data = data;

            @(negedge clk);
            write_en = 0;
        end
    endtask

    // Read and check one three-pixel window.
    task check_window;
        input [7:0] row;
        input [7:0] col;
        input [7:0] exp0;
        input [7:0] exp1;
        input [7:0] exp2;

        reg [23:0] expected;
        begin
            expected = {exp0, exp1, exp2};
            tests = tests + 1;

            @(negedge clk);
            start_row = row;
            start_col = col;
            read_en = 1;

            @(posedge clk);
            #1;

            $display(
                "Test %0d: row=%0d col=%0d expected=%06h actual=%06h",
                tests, row, col, expected, cnn_data
            );

            if (cnn_data !== expected || out_valid !== 1'b1) begin
                $display("FAIL: data or valid");
                errors = errors + 1;
            end
            else begin
                $display("PASS: data and valid");
            end

            if (bank0 !== (col % 4) ||
                bank1 !== ((col + 1) % 4) ||
                bank2 !== ((col + 2) % 4)) begin
                $display("FAIL: bank selection");
                errors = errors + 1;
            end

            read_en = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        errors = 0;
        tests = 0;

        write_en = 0;
        write_bank = 0;
        write_addr = 0;
        write_data = 0;

        read_en = 0;
        start_row = 0;
        start_col = 0;

        $dumpfile("cnn_input_sram_part1.vcd");
        $dumpvars(0, tb_cnn_input_sram_part1);

        $display("=== PART 1(ii): SRAM VERIFICATION ===");

        // Write a known sequence into row 0.
        write_pixel(0, 0, 8'h10);
        write_pixel(0, 1, 8'h11);
        write_pixel(0, 2, 8'h12);
        write_pixel(0, 3, 8'h13);
        write_pixel(0, 4, 8'h14);
        write_pixel(0, 5, 8'h15);
        write_pixel(0, 6, 8'h16);
        write_pixel(0, 7, 8'h17);

        // Verify consecutive three-pixel windows.
        check_window(0, 0, 8'h10, 8'h11, 8'h12);
        check_window(0, 1, 8'h11, 8'h12, 8'h13);
        check_window(0, 2, 8'h12, 8'h13, 8'h14);
        check_window(0, 3, 8'h13, 8'h14, 8'h15);
        check_window(0, 4, 8'h14, 8'h15, 8'h16);
        check_window(0, 5, 8'h15, 8'h16, 8'h17);

        $display("----------------------------------");

        if (errors == 0)
            $display("PART 1(ii) PASSED: %0d/%0d tests",
                     tests, tests);
        else
            $display("PART 1(ii) FAILED: %0d errors", errors);

        $display("----------------------------------");
        $finish;
    end

    // Watchdog
    initial begin
        #10000;
        $display("ERROR: TESTBENCH TIMEOUT");
        $finish;
    end

endmodule
