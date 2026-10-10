
`timescale 1ns/1ps

module tb_part1v_output_read;

    reg clk = 1'b0;

    reg        wr_en   = 1'b0;
    reg [7:0]  wr_addr = 8'd0;
    reg [23:0] wr_data = 24'd0;

    reg        rd_en   = 1'b0;
    reg [7:0]  rd_addr = 8'd0;

    wire [23:0] rd_data;
    wire        rd_valid;

    integer errors = 0;
    integer checks = 0;

    // Expected MAC results for four known pixel windows.
    reg [23:0] expected [0:3];

    cnn_output_sram dut (
        .clk      (clk),
        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),
        .rd_en    (rd_en),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data),
        .rd_valid (rd_valid)
    );

    always #5 clk = ~clk;

    // Write one 24-bit expected convolution result.
    task write_result;
        input [7:0]  address;
        input [23:0] value;
        begin
            @(negedge clk);
            wr_en   = 1'b1;
            wr_addr = address;
            wr_data = value;

            @(posedge clk);
            #1;

            $display(
                "WRITE addr=%0d data=%0d (0x%06h)",
                address, value, value
            );

            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    // Read one location and compare address-associated data.
    task check_result;
        input [7:0]  address;
        input [23:0] value;
        begin
            @(negedge clk);
            rd_en   = 1'b1;
            rd_addr = address;

            // The SRAM read is synchronous.
            @(posedge clk);
            #1;

            checks = checks + 1;

            if (rd_valid !== 1'b1 ||
                rd_data  !== value) begin

                $display(
                    "FAIL addr=%0d expected=%0d (0x%06h) actual=%0d (0x%06h) valid=%b",
                    address, value, value,
                    rd_data, rd_data, rd_valid
                );

                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS addr=%0d data=%0d (0x%06h) valid=%b",
                    address, rd_data, rd_data, rd_valid
                );
            end

            @(negedge clk);
            rd_en = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("part1v_output_read.vcd");
        $dumpvars(0, tb_part1v_output_read);

        // Manually calculated reference values:
        // Window 0: sum(pixel[i] * kernel[i]) = 285
        // Window 1: sum(pixel[i] * kernel[i]) = 330
        // Window 2: sum(pixel[i] * kernel[i]) = 375
        // Window 3: sum(pixel[i] * kernel[i]) = 420

        expected[0] = 24'd285;
        expected[1] = 24'd330;
        expected[2] = 24'd375;
        expected[3] = 24'd420;

        $display("========================================");
        $display("PART 1(v): OUTPUT SRAM READ VERIFICATION");
        $display("========================================");

        // Store the reference convolution results.
        write_result(8'd0, expected[0]);
        write_result(8'd1, expected[1]);
        write_result(8'd2, expected[2]);
        write_result(8'd3, expected[3]);

        // Read back each address and verify its output.
        check_result(8'd0, expected[0]);
        check_result(8'd1, expected[1]);
        check_result(8'd2, expected[2]);
        check_result(8'd3, expected[3]);

        $display("----------------------------------------");
        $display("Read checks : %0d", checks);
        $display("Errors      : %0d", errors);

        if (errors == 0 && checks == 4)
            $display("PART 1(v) OUTPUT SRAM READ TEST PASSED");
        else
            $display("PART 1(v) OUTPUT SRAM READ TEST FAILED");

        $display("----------------------------------------");
        $finish;
    end

endmodule
