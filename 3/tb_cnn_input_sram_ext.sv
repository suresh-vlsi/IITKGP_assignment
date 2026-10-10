
`timescale 1ns/1ps

module tb_cnn_input_sram_ext;

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

    reg finished;

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

    // Clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Write one pixel using cyclic bank interleaving.
    // bank = column % 4
    // address = row*64 + column/4
    // --------------------------------------------------------
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
            write_en   = 1'b1;
            write_bank = b;
            write_addr = a;
            write_data = data;

            // SRAM samples write controls at the next rising edge.
            @(negedge clk);
            write_en = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Read a three-pixel window and verify:
    // 1. Pixel data
    // 2. Output-valid
    // 3. Bank selections
    // 4. Local addresses
    // --------------------------------------------------------
    task check_window;
        input [7:0] row;
        input [7:0] col;
        input [7:0] e0;
        input [7:0] e1;
        input [7:0] e2;

        reg [23:0] expected;

        integer c0, c1, c2;
        integer r0, r1, r2;
        integer b0, b1, b2;
        integer a0, a1, a2;

        begin
            tests = tests + 1;
            expected = {e0, e1, e2};

            // Linear three-pixel window.
            c0 = col;
            c1 = col + 1;
            c2 = col + 2;

            // Handle crossing from column 255 to next row.
            r0 = row + c0 / 256;
            r1 = row + c1 / 256;
            r2 = row + c2 / 256;

            c0 = c0 % 256;
            c1 = c1 % 256;
            c2 = c2 % 256;

            b0 = c0 % 4;
            b1 = c1 % 4;
            b2 = c2 % 4;

            a0 = r0 * 64 + c0 / 4;
            a1 = r1 * 64 + c1 / 4;
            a2 = r2 * 64 + c2 / 4;

            @(negedge clk);
            start_row = row;
            start_col = col;
            read_en = 1'b1;

            @(posedge clk);
            #1;

            $display("");
            $display("------------------------------------------");
            $display("TEST %0d: row=%0d col=%0d", tests, row, col);
            $display("Expected data : %06h", expected);
            $display("Actual data   : %06h", cnn_data);
            $display("Banks         : %0d %0d %0d",
                     bank0, bank1, bank2);
            $display("Expected banks: %0d %0d %0d",
                     b0, b1, b2);
            $display("Addresses     : %0d %0d %0d",
                     addr0, addr1, addr2);
            $display("Expected addr : %0d %0d %0d",
                     a0, a1, a2);

            if (cnn_data !== expected) begin
                $display("FAIL: output data mismatch");
                errors = errors + 1;
            end

            if (out_valid !== 1'b1) begin
                $display("FAIL: out_valid was not asserted");
                errors = errors + 1;
            end

            if (bank0 !== b0 ||
                bank1 !== b1 ||
                bank2 !== b2) begin
                $display("FAIL: bank selection mismatch");
                errors = errors + 1;
            end

            if (addr0 !== a0 ||
                addr1 !== a1 ||
                addr2 !== a2) begin
                $display("FAIL: address mismatch");
                errors = errors + 1;
            end

            if (cnn_data === expected &&
                out_valid === 1'b1 &&
                bank0 === b0 && bank1 === b1 && bank2 === b2 &&
                addr0 === a0 && addr1 === a1 && addr2 === a2)
                $display("RESULT: PASS");

            // Disable read after checking.
            read_en = 1'b0;

            @(negedge clk);
        end
    endtask

    // --------------------------------------------------------
    // MAIN TEST SEQUENCE
    // --------------------------------------------------------
    initial begin
        errors = 0;
        tests = 0;
        finished = 1'b0;

        write_en = 1'b0;
        write_bank = 0;
        write_addr = 0;
        write_data = 0;

        read_en = 1'b0;
        start_row = 0;
        start_col = 0;

        $dumpfile("cnn_input_sram_ext.vcd");
        $dumpvars(0, tb_cnn_input_sram_ext);

        $display("==========================================");
        $display(" EXTENDED CNN INPUT SRAM VERIFICATION");
        $display("==========================================");

        // TEST A: Upper row addressing.
        write_pixel(8'd200, 8'd10, 8'hC1);
        write_pixel(8'd200, 8'd11, 8'hC2);
        write_pixel(8'd200, 8'd12, 8'hC3);

        check_window(
            8'd200, 8'd10,
            8'hC1, 8'hC2, 8'hC3
        );

        // TEST B: Cross the boundary from row 0 to row 1.
        write_pixel(8'd0, 8'd254, 8'hFE);
        write_pixel(8'd0, 8'd255, 8'hFF);
        write_pixel(8'd1, 8'd0,   8'hC0);

        check_window(
            8'd0, 8'd254,
            8'hFE, 8'hFF, 8'hC0
        );

        // TEST C: Last legal three-pixel window in row 254.
        write_pixel(8'd254, 8'd253, 8'hD1);
        write_pixel(8'd254, 8'd254, 8'hD2);
        write_pixel(8'd254, 8'd255, 8'hD3);

        check_window(
            8'd254, 8'd253,
            8'hD1, 8'hD2, 8'hD3
        );

        $display("");
        $display("==========================================");

        if (errors == 0)
            $display("EXTENDED TEST PASSED: %0d/%0d",
                     tests, tests);
        else
            $display("EXTENDED TEST FAILED: %0d errors in %0d tests",
                     errors, tests);

        $display("==========================================");

        finished = 1'b1;
        $finish;
    end

    // Watchdog: terminates a stalled simulation.
    initial begin
        #100000;

        if (!finished) begin
            $display("ERROR: SIMULATION TIMEOUT");
            $finish;
        end
    end

endmodule
