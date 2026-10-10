
`timescale 1ns/1ps

module tb_cnn_input_sram_data_check;

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

    task write_pixel;
        input [1:0] bank;
        input [13:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            write_en   = 1'b1;
            write_bank = bank;
            write_addr = addr;
            write_data = data;

            @(negedge clk);
            write_en = 1'b0;
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

        $dumpfile("input_data_check.vcd");
        $dumpvars(0, tb_cnn_input_sram_data_check);

        $display("=== INPUT SRAM PIXEL DATA CHECK ===");

        // Initialize three consecutive pixels in banks 0, 1, 2.
        write_pixel(0, 0, 8'h11);
        write_pixel(1, 0, 8'h22);
        write_pixel(2, 0, 8'h33);

        start_row = 0;
        start_col = 0;

        @(negedge clk);
        read_en = 1'b1;

        @(posedge clk);
        #1;

        if (out_valid !== 1'b1 ||
            cnn_data !== 24'h112233) begin
            $display(
                "FAIL: data=%h valid=%b expected=112233 valid=1",
                cnn_data, out_valid
            );
            errors = errors + 1;
        end else begin
            $display(
                "PASS: data=%h valid=%b",
                cnn_data, out_valid
            );
        end

        @(negedge clk);
        read_en = 1'b0;

        @(posedge clk);
        #1;

        if (out_valid !== 1'b0 ||
            cnn_data !== 24'h000000) begin
            $display("FAIL: read-disabled behavior");
            errors = errors + 1;
        end else begin
            $display("PASS: read-disabled behavior");
        end

        if (errors == 0)
            $display("INPUT DATA CHECK PASSED: 2/2 checks");
        else
            $display("INPUT DATA CHECK FAILED: %0d errors", errors);

        $finish;
    end

endmodule
