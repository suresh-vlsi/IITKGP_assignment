`timescale 1ns/1ps

module tb_cnn_input_sram_full_image;

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

    integer r, c, linear;
    integer errors = 0;
    integer writes = 0;
    integer windows = 0;
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

    function [7:0] pixel_value;
        input integer row;
        input integer col;
        begin
            pixel_value = (row * 17 + col) & 255;
        end
    endfunction

    initial begin
        $display("=== FULL IMAGE SRAM VERIFICATION ===");

        $dumpfile("cnn_input_sram_full_image.vcd");
        $dumpvars(0, tb_cnn_input_sram_full_image);

        // Write all 256 x 256 pixels.
        for (r = 0; r < 256; r = r + 1) begin
            for (c = 0; c < 256; c = c + 1) begin
                linear = r * 256 + c;

                @(negedge clk);
                write_en = 1;
                write_bank = linear % 4;
                write_addr = linear / 4;
                write_data = pixel_value(r, c);

                @(negedge clk);
                write_en = 0;
                writes = writes + 1;
            end
        end

        $display("Pixels written: %0d", writes);

        // Read every valid three-pixel window.
        // Columns 0..253 are valid on every row.
        // Columns 254..255 are valid except on the last row.
        for (r = 0; r < 256; r = r + 1) begin
            for (c = 0; c < 256; c = c + 1) begin
                if ((r < 255) || (c <= 253)) begin
                    @(negedge clk);
                    start_row = r;
                    start_col = c;
                    read_en = 1;

                    @(posedge clk);
                    #1;

                    windows = windows + 1;

                    if (out_valid !== 1'b1) begin
                        errors = errors + 1;
                        if (errors <= 10)
                            $display("FAIL valid row=%0d col=%0d",
                                     r, c);
                    end
                    else begin
                        checks = checks + 1;

                        if (cnn_data !== {
                            pixel_value(r, c),
                            pixel_value(r + ((c+1)/256),
                                        (c+1)%256),
                            pixel_value(r + ((c+2)/256),
                                        (c+2)%256)
                        }) begin
                            errors = errors + 1;
                            if (errors <= 10)
                                $display(
                                    "FAIL row=%0d col=%0d expected=%06h actual=%06h",
                                    r, c,
                                    {
                                        pixel_value(r, c),
                                        pixel_value(r + ((c+1)/256),
                                                    (c+1)%256),
                                        pixel_value(r + ((c+2)/256),
                                                    (c+2)%256)
                                    },
                                    cnn_data
                                );
                        end
                    end

                    @(negedge clk);
                    read_en = 0;
                end
            end
        end

        $display("------------------------------");
        $display("Pixels written : %0d", writes);
        $display("Windows tested : %0d", windows);
        $display("Data checks    : %0d", checks);
        $display("Errors         : %0d", errors);

        if (errors == 0)
            $display("FULL IMAGE TEST PASSED");
        else
            $display("FULL IMAGE TEST FAILED");

        $finish;
    end

endmodule
