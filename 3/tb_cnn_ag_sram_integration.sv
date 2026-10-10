
`timescale 1ns/1ps

module tb_cnn_ag_sram_integration;

    reg clk;
    reg rst_n;
    reg start;

    wire read_en;
    wire [7:0] row;
    wire [7:0] col;
    wire scan_done;

    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;

    reg write_en;
    reg [1:0] write_bank;
    reg [13:0] write_addr;
    reg [7:0] write_data;

    wire [23:0] cnn_data;
    wire out_valid;

    wire [7:0] pixel0, pixel1, pixel2;

    integer errors;
    integer windows;
    integer i;
    reg finished;

    // Short scan: row 0, columns 0 through 5.
    cnn_address_generator #(
        .LAST_ROW(8'd0),
        .LAST_COL(8'd5)
    ) ag (
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
        .bank0(),
        .bank1(),
        .bank2(),
        .addr0(),
        .addr1(),
        .addr2(),
        .pixel0(pixel0),
        .pixel1(pixel1),
        .pixel2(pixel2)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Write using the existing cyclic-bank mapping.
    task write_pixel;
        input [7:0] r;
        input [7:0] c;
        input [7:0] data;
        integer b;
        integer a;
        begin
            b = c % 4;
            a = r * 64 + c / 4;

            @(negedge clk);
            write_en = 1;
            write_bank = b;
            write_addr = a;
            write_data = data;

            @(negedge clk);
            write_en = 0;
        end
    endtask

    initial begin
        errors = 0;
        windows = 0;
        finished = 0;

        rst_n = 0;
        start = 0;

        write_en = 0;
        write_bank = 0;
        write_addr = 0;
        write_data = 0;

        $dumpfile("cnn_ag_sram_integration.vcd");
        $dumpvars(0, tb_cnn_ag_sram_integration);

        // Reset address generator.
        repeat (2) @(negedge clk);
        rst_n = 1;

        // Load known pixels into row 0.
        write_pixel(0, 0, 8'h10);
        write_pixel(0, 1, 8'h11);
        write_pixel(0, 2, 8'h12);
        write_pixel(0, 3, 8'h13);
        write_pixel(0, 4, 8'h14);
        write_pixel(0, 5, 8'h15);
        write_pixel(0, 6, 8'h16);
        write_pixel(0, 7, 8'h17);

        $display("=== ADDRESS GENERATOR + SRAM TEST ===");

        // Start the automatic scan.
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Check six windows. Read data is registered by the SRAM.
        while (!scan_done && windows < 10) begin
            @(posedge clk);
            #1;

            if (out_valid) begin
                $display(
                    "Window %0d: row=%0d col=%0d data=%06h",
                    windows, row, col, cnn_data
                );

                case (windows)
                    0: if (cnn_data !== 24'h101112)
                           errors = errors + 1;
                    1: if (cnn_data !== 24'h111213)
                           errors = errors + 1;
                    2: if (cnn_data !== 24'h121314)
                           errors = errors + 1;
                    3: if (cnn_data !== 24'h131415)
                           errors = errors + 1;
                    4: if (cnn_data !== 24'h141516)
                           errors = errors + 1;
                    5: if (cnn_data !== 24'h151617)
                           errors = errors + 1;
                    default: begin
                        $display("FAIL: unexpected extra window");
                        errors = errors + 1;
                    end
                endcase

                windows = windows + 1;
            end

            @(negedge clk);
        end

        if (windows != 6) begin
            $display("FAIL: expected 6 windows, got %0d", windows);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("INTEGRATION TEST PASSED: %0d windows", windows);
        else
            $display("INTEGRATION TEST FAILED: %0d errors", errors);

        finished = 1;
        $finish;
    end

    // Watchdog
    initial begin
        #10000;
        if (!finished) begin
            $display("ERROR: TESTBENCH TIMEOUT");
            $finish;
        end
    end

endmodule
