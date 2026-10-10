
`timescale 1ns/1ps

module tb_cnn_input_sram_address_check;

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

    task check_address;
        input [7:0] row;
        input [7:0] col;
        input [13:0] expected0;
        input [13:0] expected1;
        input [13:0] expected2;
        begin
            start_row = row;
            start_col = col;
            #1;

            if (addr0 !== expected0 ||
                addr1 !== expected1 ||
                addr2 !== expected2) begin
                $display(
                    "FAIL row=%0d col=%0d: got %0d,%0d,%0d expected %0d,%0d,%0d",
                    row, col, addr0, addr1, addr2,
                    expected0, expected1, expected2
                );
                errors = errors + 1;
            end else begin
                $display(
                    "PASS row=%0d col=%0d: addresses=%0d,%0d,%0d",
                    row, col, addr0, addr1, addr2
                );
            end
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

        $dumpfile("input_address_check.vcd");
        $dumpvars(0, tb_cnn_input_sram_address_check);

        $display("=== INPUT SRAM ADDRESS CHECK ===");

        check_address(0,   0,   0,     0,     0);
        check_address(1,   0,   64,    64,    64);
        check_address(4,   0,   256,   256,   256);
        check_address(255, 0,   16320, 16320, 16320);
        check_address(255, 252, 16383, 16383, 16383);
        check_address(0, 254, 63, 63, 64);
        check_address(0, 255, 63, 64, 64);

        if (errors == 0)
            $display("ADDRESS CHECK PASSED");
        else
            $display("ADDRESS CHECK FAILED: %0d errors", errors);

        $finish;
    end

endmodule
