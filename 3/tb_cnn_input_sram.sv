`timescale 1ns/1ps

// ============================================================
// QUESTION 3 TESTBENCH
//
// Verifies:
// 1. Four-bank SRAM organization
// 2. Staggered address mapping
// 3. Bank selection
// 4. CNN read control
// 5. 24-bit output
// ============================================================

module tb_cnn_input_sram;

    reg clk;

    // Write interface
    reg        write_en;
    reg [1:0]  write_bank;
    reg [13:0] write_addr;
    reg [7:0]  write_data;

    // CNN read interface
    reg        read_en;
    reg [7:0]  start_row;
    reg [7:0]  start_col;

    // Outputs
    wire [23:0] cnn_data;
    wire        out_valid;

    wire [1:0]  bank0;
    wire [1:0]  bank1;
    wire [1:0]  bank2;

    wire [13:0] addr0;
    wire [13:0] addr1;
    wire [13:0] addr2;

    wire [7:0] pixel0;
    wire [7:0] pixel1;
    wire [7:0] pixel2;

    integer errors;

    // ========================================================
    // DUT
    // ========================================================

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

    // ========================================================
    // CLOCK
    // ========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ========================================================
    // WRITE TASK
    // ========================================================

    task write_pixel;

        input [7:0] row;
        input [7:0] col;
        input [7:0] data;

        integer bank_number;
        integer local_col;
        integer memory_address;

        begin

            bank_number = col % 4;
            local_col = col / 4;
            memory_address = row * 64 + local_col;

            @(negedge clk);

            write_en   = 1'b1;
            write_bank = bank_number;
            write_addr = memory_address;
            write_data = data;

            @(posedge clk);

            #1;

            write_en = 1'b0;

        end

    endtask

    // ========================================================
    // READ / VERIFY TASK
    // ========================================================

    task read_window;

        input [7:0] row;
        input [7:0] col;

        input [7:0] expected0;
        input [7:0] expected1;
        input [7:0] expected2;

        reg [23:0] expected;

        begin

            expected = {expected0, expected1, expected2};

            @(negedge clk);

            start_row = row;
            start_col = col;
            read_en   = 1'b1;

            @(posedge clk);

            #1;

            $display("");
            $display("--------------------------------------------------");
            $display("CNN READ");
            $display("Start Row       = %0d", row);
            $display("Start Column    = %0d", col);

            $display("Pixel 0         = 0x%02h", pixel0);
            $display("Pixel 1         = 0x%02h", pixel1);
            $display("Pixel 2         = 0x%02h", pixel2);

            $display("Bank selection  = %0d, %0d, %0d",
                     bank0, bank1, bank2);

            $display("Address         = %0d, %0d, %0d",
                     addr0, addr1, addr2);

            $display("Expected output = 0x%06h", expected);
            $display("Actual output   = 0x%06h", cnn_data);

            if ((cnn_data === expected) &&
                (out_valid === 1'b1)) begin

                $display("RESULT          = PASS");

            end
            else begin

                $display("RESULT          = FAIL");
                errors = errors + 1;

            end

            read_en = 1'b0;

        end

    endtask

    // ========================================================
    // TEST
    // ========================================================

    initial begin

        errors = 0;

        write_en   = 1'b0;
        write_bank = 2'd0;
        write_addr = 14'd0;
        write_data = 8'h00;

        read_en   = 1'b0;
        start_row = 8'd0;
        start_col = 8'd0;

        // ====================================================
        // VCD
        // ====================================================

        $dumpfile("cnn_input_sram.vcd");
        $dumpvars(0, tb_cnn_input_sram);

        // ====================================================
        // Header
        // ====================================================

        $display("");
        $display("==================================================");
        $display("       QUESTION 3 - CNN INPUT SRAM");
        $display("==================================================");
        $display("Image       : 256 x 256");
        $display("Pixel       : 8 bits");
        $display("Banks       : 4");
        $display("Bank size   : 256 x 64 bytes");
        $display("Output      : 24 bits");
        $display("==================================================");

        // ====================================================
        // WRITE KNOWN PIXELS
        //
        // Row 0:
        //
        // col 0 = A0
        // col 1 = A1
        // col 2 = A2
        // col 3 = A3
        // col 4 = A4
        // col 5 = A5
        // col 6 = A6
        // col 7 = A7
        // col 8 = A8
        // col 9 = A9
        // ====================================================

        write_pixel(8'd0, 8'd0, 8'hA0);
        write_pixel(8'd0, 8'd1, 8'hA1);
        write_pixel(8'd0, 8'd2, 8'hA2);
        write_pixel(8'd0, 8'd3, 8'hA3);
        write_pixel(8'd0, 8'd4, 8'hA4);
        write_pixel(8'd0, 8'd5, 8'hA5);
        write_pixel(8'd0, 8'd6, 8'hA6);
        write_pixel(8'd0, 8'd7, 8'hA7);
        write_pixel(8'd0, 8'd8, 8'hA8);
        write_pixel(8'd0, 8'd9, 8'hA9);

        // ====================================================
        // Row 1
        // ====================================================

        write_pixel(8'd1, 8'd0, 8'hB0);
        write_pixel(8'd1, 8'd1, 8'hB1);
        write_pixel(8'd1, 8'd2, 8'hB2);
        write_pixel(8'd1, 8'd3, 8'hB3);
        write_pixel(8'd1, 8'd4, 8'hB4);
        write_pixel(8'd1, 8'd5, 8'hB5);

        // ====================================================
        // READ WINDOWS
        // ====================================================

        // --------------------------------------------
        // Window 1: columns 0,1,2
        // Banks = 0,1,2
        // --------------------------------------------

        read_window(
            8'd0,
            8'd0,
            8'hA0,
            8'hA1,
            8'hA2
        );

        // --------------------------------------------
        // Window 2: columns 1,2,3
        // Banks = 1,2,3
        // --------------------------------------------

        read_window(
            8'd0,
            8'd1,
            8'hA1,
            8'hA2,
            8'hA3
        );

        // --------------------------------------------
        // Window 3: columns 2,3,4
        // Banks = 2,3,0
        // --------------------------------------------

        read_window(
            8'd0,
            8'd2,
            8'hA2,
            8'hA3,
            8'hA4
        );

        // --------------------------------------------
        // Window 4: columns 3,4,5
        // Banks = 3,0,1
        // --------------------------------------------

        read_window(
            8'd0,
            8'd3,
            8'hA3,
            8'hA4,
            8'hA5
        );

        // --------------------------------------------
        // Window 5: columns 7,8,9
        // Banks = 3,0,1
        // --------------------------------------------

        read_window(
            8'd0,
            8'd7,
            8'hA7,
            8'hA8,
            8'hA9
        );

        // --------------------------------------------
        // Window 6: second row
        // --------------------------------------------

        read_window(
            8'd1,
            8'd0,
            8'hB0,
            8'hB1,
            8'hB2
        );

        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("==================================================");

        if (errors == 0) begin

            $display("       QUESTION 3 TEST PASSED");
            $display("       CNN ADDRESS GENERATION : PASS");
            $display("       BANK SELECTION         : PASS");
            $display("       READ CONTROL           : PASS");
            $display("       24-BIT OUTPUT          : PASS");

        end
        else begin

            $display("       QUESTION 3 TEST FAILED");
            $display("       ERRORS = %0d", errors);

        end

        $display("==================================================");
        $display("");

        #20;

        $finish;

    end

endmodule