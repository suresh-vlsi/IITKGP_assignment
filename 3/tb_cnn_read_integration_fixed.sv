`timescale 1ns/1ps

module tb_cnn_read_integration_fixed;

    reg clk = 0;
    reg write_en = 0;
    reg [1:0] write_bank = 0;
    reg [13:0] write_addr = 0;
    reg [7:0] write_data = 0;
    reg read_en = 0;
    reg [7:0] start_row = 0;
    reg [7:0] start_col = 0;

    wire [23:0] cnn_data;
    wire out_valid;
    wire [1:0] bank0, bank1, bank2;
    wire [13:0] addr0, addr1, addr2;
    wire [7:0] pixel0, pixel1, pixel2;

    integer errors = 0;
    integer checks = 0;

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

    always #5 clk = ~clk;

    task write_pixel;
        input [7:0] c;
        input [7:0] value;
        begin
            @(negedge clk);
            write_en = 1;
            write_bank = c[1:0];
            write_addr = c / 4;
            write_data = value;
            @(negedge clk);
            write_en = 0;
        end
    endtask

    task check_window;
        input [7:0] c;
        input [23:0] expected;
        begin
            @(negedge clk);
            start_row = 0;
            start_col = c;
            read_en = 1;

            @(posedge clk);
            #1;
            checks = checks + 1;

            if (out_valid !== 1'b1 || cnn_data !== expected) begin
                $display("FAIL col=%0d expected=%06h actual=%06h valid=%b",
                         c, expected, cnn_data, out_valid);
                errors = errors + 1;
            end
            else begin
                $display("PASS col=%0d data=%06h", c, cnn_data);
            end

            @(negedge clk);
            read_en = 0;
        end
    endtask

    initial begin
        $dumpfile("cnn_read_integration_fixed.vcd");
        $dumpvars(0, tb_cnn_read_integration_fixed);

        write_pixel(0, 8'h10);
        write_pixel(1, 8'h11);
        write_pixel(2, 8'h12);
        write_pixel(3, 8'h13);
        write_pixel(4, 8'h14);
        write_pixel(5, 8'h15);

        check_window(0, 24'h101112);
        check_window(1, 24'h111213);
        check_window(2, 24'h121314);
        check_window(3, 24'h131415);

        if (errors == 0)
            $display("SRAM READ INTEGRATION PASSED: %0d/%0d checks",
                     checks, checks);
        else
            $display("SRAM READ INTEGRATION FAILED: %0d errors", errors);

        $finish;
    end

endmodule
