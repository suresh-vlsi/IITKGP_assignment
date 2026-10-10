`timescale 1ns/1ps

module tb_part2_address_generator;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    wire read_en;
    wire [7:0] row, col;
    wire scan_done;

    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;

    reg write_en = 0;
    reg [1:0] write_bank = 0;
    reg [13:0] write_addr = 0;
    reg [7:0] write_data = 0;

    wire [23:0] cnn_data;
    wire out_valid;

    wire [1:0] sram_bank0, sram_bank1, sram_bank2;
    wire [13:0] sram_addr0, sram_addr1, sram_addr2;
    wire [7:0] pixel0, pixel1, pixel2;

    integer errors = 0;
    integer address_checks = 0;
    integer pixel_checks = 0;
    integer cycles = 0;

    reg [7:0] sampled_row, sampled_col;
    reg [1:0] expected_bank0, expected_bank1, expected_bank2;
    reg [13:0] expected_addr0, expected_addr1, expected_addr2;

    // Deterministic reference pixel function for this test.
    function [7:0] exp_pixel;
        input [7:0] r;
        input [7:0] c;
        begin
            exp_pixel = (r * 3 + c * 5 + 17) & 8'hFF;
        end
    endfunction

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

    cnn_input_sram sram (
        .clk(clk),
        .write_en(write_en),
        .write_bank(write_bank),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_en(read_en),
        .start_row(row),
        .start_col(col),
        .cnn_data(cnn_data),
        .out_valid(out_valid),
        .bank0(sram_bank0),
        .bank1(sram_bank1),
        .bank2(sram_bank2),
        .addr0(sram_addr0),
        .addr1(sram_addr1),
        .addr2(sram_addr2),
        .pixel0(pixel0),
        .pixel1(pixel1),
        .pixel2(pixel2)
    );

    always #5 clk = ~clk;

    // Store one pixel using bank = column modulo 4.
    task load_pixel;
        input [7:0] r;
        input [7:0] c;
        reg [1:0] b;
        reg [13:0] a;
        begin
            b = c[1:0];
            a = (r << 6) + (c >> 2);

            @(negedge clk);
            write_en   = 1;
            write_bank = b;
            write_addr = a;
            write_data = exp_pixel(r,c);

            @(negedge clk);
            write_en = 0;
        end
    endtask

    // Check the three bank selectors and local addresses.
    task check_address;
        input [7:0] r;
        input [7:0] c;
        reg [8:0] c1, c2;
        reg [1:0] eb0, eb1, eb2;
        reg [13:0] ea0, ea1, ea2;
        begin
            c1 = {1'b0,c} + 9'd1;
            c2 = {1'b0,c} + 9'd2;

            eb0 = c[1:0];
            eb1 = c1[1:0];
            eb2 = c2[1:0];

            ea0 = (r * 64) + (c  >> 2);
            ea1 = (r * 64) + (c1 >> 2);
            ea2 = (r * 64) + (c2 >> 2);

            address_checks = address_checks + 1;

            if (bank0 !== eb0 || bank1 !== eb1 ||
                bank2 !== eb2 ||
                addr0 !== ea0 || addr1 !== ea1 ||
                addr2 !== ea2) begin
                $display(
                    "FAIL ADDRESS row=%0d col=%0d", r, c
                );
                $display(
                    "  banks actual=%0d,%0d,%0d expected=%0d,%0d,%0d",
                    bank0,bank1,bank2,eb0,eb1,eb2
                );
                $display(
                    "  addrs actual=%0d,%0d,%0d expected=%0d,%0d,%0d",
                    addr0,addr1,addr2,ea0,ea1,ea2
                );
                errors = errors + 1;
            end

            // Check that the SRAM uses the same mapping.
            if (sram_bank0 !== eb0 || sram_bank1 !== eb1 ||
                sram_bank2 !== eb2 ||
                sram_addr0 !== ea0 || sram_addr1 !== ea1 ||
                sram_addr2 !== ea2) begin
                $display(
                    "FAIL SRAM ADDRESS row=%0d col=%0d", r, c
                );
                errors = errors + 1;
            end
        end
    endtask

    // Compare the synchronous 24-bit SRAM output against
    // three independently calculated reference pixels.
    task check_pixels;
        input [7:0] r;
        input [7:0] c;
        reg [23:0] expected_word;
        begin
            expected_word = {
                exp_pixel(r,c),
                exp_pixel(r,c+8'd1),
                exp_pixel(r,c+8'd2)
            };

            pixel_checks = pixel_checks + 1;

            if (out_valid !== 1'b1 ||
                cnn_data !== expected_word) begin
                $display(
                    "FAIL PIXELS row=%0d col=%0d expected=%h actual=%h valid=%b",
                    r,c,expected_word,cnn_data,out_valid
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS PIXELS row=%0d col=%0d data=%h",
                    r,c,cnn_data
                );
            end
        end
    endtask

    // Check signals sampled before the clock edge. SRAM registers
    // data for those same row/column values at this edge.
    always @(posedge clk) begin
        if (rst_n && read_en) begin
            sampled_row = row;
            sampled_col = col;

            check_address(sampled_row,sampled_col);

            #1;

            cycles = cycles + 1;

            if (sampled_row == 0 && sampled_col == 0)
                check_pixels(sampled_row,sampled_col);

            if (sampled_row == 7 && sampled_col == 12)
                check_pixels(sampled_row,sampled_col);

            // Verify progression to the next coordinate.
            if (sampled_col < 8'd253) begin
                if (row !== sampled_row ||
                    col !== sampled_col + 8'd1) begin
                    $display(
                        "FAIL SEQUENCE after row=%0d col=%0d",
                        sampled_row,sampled_col
                    );
                    errors = errors + 1;
                end
            end
            else if (sampled_row < 8'd255) begin
                if (row !== sampled_row + 8'd1 || col !== 8'd0) begin
                    $display(
                        "FAIL ROW TRANSITION after row=%0d col=%0d",
                        sampled_row,sampled_col
                    );
                    errors = errors + 1;
                end
            end
        end
    end

    initial begin
        $dumpfile("part2_address_generator.vcd");
        $dumpvars(0,tb_part2_address_generator);

        $display("==========================================");
        $display("PART 2: ADDRESS GENERATOR VERIFICATION");
        $display("==========================================");

        // Reset.
        repeat (2) @(negedge clk);
        rst_n = 1;

        // Preload the six pixels required by the two checks.
        load_pixel(8'd0,8'd0);
        load_pixel(8'd0,8'd1);
        load_pixel(8'd0,8'd2);

        load_pixel(8'd7,8'd12);
        load_pixel(8'd7,8'd13);
        load_pixel(8'd7,8'd14);

        // Start the address scan.
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Row 7, column 12 is reached after the scan advances.
        wait (row == 8'd7 && col == 8'd12 && read_en);
        // Allow the next rising edge to capture the target SRAM read.
        @(posedge clk);
        #2;

        $display("------------------------------------------");
        $display("Address checks : %0d", address_checks);
        $display("Pixel checks   : %0d", pixel_checks);
        $display("Errors         : %0d", errors);

        if (errors == 0 && pixel_checks == 2)
            $display("PART 2 TEST PASSED");
        else
            $display("PART 2 TEST FAILED");

        $display("------------------------------------------");
        $finish;
    end

    // Safety timeout if the scan never reaches the target.
    initial begin
        #200000;
        $display("TIMEOUT: address scan did not finish in time");
        $finish;
    end

endmodule
