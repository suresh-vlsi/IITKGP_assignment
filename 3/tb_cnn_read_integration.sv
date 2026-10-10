`timescale 1ns/1ps

module tb_cnn_read_integration;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    reg write_en = 0;
    reg [1:0] write_bank = 0;
    reg [13:0] write_addr = 0;
    reg [7:0] write_data = 0;

    wire read_en;
    wire [7:0] row, col;
    wire scan_done;

    wire [1:0] gb0, gb1, gb2;
    wire [13:0] ga0, ga1, ga2;

    wire [23:0] cnn_data;
    wire out_valid;

    wire [1:0] sb0, sb1, sb2;
    wire [13:0] sa0, sa1, sa2;
    wire [7:0] pixel0, pixel1, pixel2;

    integer errors = 0;
    integer checks = 0;

    cnn_address_generator #(
        .LAST_ROW(8'd1),
        .LAST_COL(8'd3)
    ) addr_gen (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .read_en(read_en),
        .row(row),
        .col(col),
        .scan_done(scan_done),
        .bank0(gb0), .bank1(gb1), .bank2(gb2),
        .addr0(ga0), .addr1(ga1), .addr2(ga2)
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
        .bank0(sb0), .bank1(sb1), .bank2(sb2),
        .addr0(sa0), .addr1(sa1), .addr2(sa2),
        .pixel0(pixel0), .pixel1(pixel1), .pixel2(pixel2)
    );

    always #5 clk = ~clk;

    task write_pixel;
        input [7:0] r;
        input [7:0] c;
        input [7:0] value;
        reg [1:0] b;
        reg [13:0] a;
        begin
            b = c[1:0];
            a = r * 64 + c / 4;

            @(negedge clk);
            write_en = 1;
            write_bank = b;
            write_addr = a;
            write_data = value;

            @(negedge clk);
            write_en = 0;
        end
    endtask

    task check_window;
        input [7:0] r;
        input [7:0] c;
        input [23:0] expected;
        begin
            @(negedge clk);
            if (row !== r || col !== c) begin
                $display("FAIL position expected=%0d,%0d got=%0d,%0d",
                         r, c, row, col);
                errors = errors + 1;
            end

            if ({gb0,gb1,gb2} !== {sb0,sb1,sb2} ||
                {ga0,ga1,ga2} !== {sa0,sa1,sa2}) begin
                $display("FAIL address generator/SRAM mismatch");
                errors = errors + 1;
            end

            @(posedge clk);
            #1;
            checks = checks + 1;

            if (out_valid !== 1'b1 || cnn_data !== expected) begin
                $display("FAIL row=%0d col=%0d expected=%06h actual=%06h valid=%b",
                         r, c, expected, cnn_data, out_valid);
                errors = errors + 1;
            end
            else begin
                $display("PASS row=%0d col=%0d data=%06h",
                         r, c, cnn_data);
            end
        end
    endtask

    initial begin
        $dumpfile("cnn_read_integration.vcd");
        $dumpvars(0, tb_cnn_read_integration);

        repeat (2) @(negedge clk);
        rst_n = 1;

        // Load deterministic pixels into row 0.
        write_pixel(0, 0, 8'h10);
        write_pixel(0, 1, 8'h11);
        write_pixel(0, 2, 8'h12);
        write_pixel(0, 3, 8'h13);
        write_pixel(0, 4, 8'h14);
        write_pixel(0, 5, 8'h15);

        // Load deterministic pixels into row 1.
        write_pixel(1, 0, 8'h20);
        write_pixel(1, 1, 8'h21);
        write_pixel(1, 2, 8'h22);
        write_pixel(1, 3, 8'h23);
        write_pixel(1, 4, 8'h24);
        write_pixel(1, 5, 8'h25);

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // Verify representative horizontal windows.
        wait (read_en && row == 0 && col == 0);
        check_window(0, 0, 24'h101112);

        wait (read_en && row == 0 && col == 1);
        check_window(0, 1, 24'h111213);

        wait (read_en && row == 0 && col == 2);
        check_window(0, 2, 24'h121314);

        wait (read_en && row == 0 && col == 3);
        check_window(0, 3, 24'h131415);

        wait (read_en && row == 1 && col == 0);
        check_window(1, 0, 24'h202122);

        wait (read_en && row == 1 && col == 1);
        check_window(1, 1, 24'h212223);

        if (errors == 0)
            $display("INTEGRATION TEST PASSED: %0d checks", checks);
        else
            $display("INTEGRATION TEST FAILED: %0d errors", errors);

        $finish;
    end

    initial begin
        #10000;
        $display("ERROR: integration test timeout");
        $finish;
    end

endmodule
