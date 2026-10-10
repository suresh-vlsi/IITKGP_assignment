`timescale 1ns/1ps

module tb_part1v_output_read_advanced;

    reg clk;
    reg wr_en;
    reg [7:0] wr_addr;
    reg [23:0] wr_data;
    reg rd_en;
    reg [7:0] rd_addr;

    wire [23:0] rd_data;
    wire rd_valid;

    integer errors;
    integer tests;

    cnn_output_sram dut (
        .clk(clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_valid(rd_valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task write_word;
        input [7:0] addr;
        input [23:0] data;
        begin
            @(negedge clk);
            wr_en = 1;
            wr_addr = addr;
            wr_data = data;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task check_word;
        input [7:0] addr;
        input [23:0] expected;
        begin
            @(negedge clk);
            rd_en = 1;
            rd_addr = addr;
            @(posedge clk);
            #1;
            tests = tests + 1;

            if (rd_data !== expected || rd_valid !== 1'b1) begin
                $display("FAIL addr=%0d expected=%06h actual=%06h valid=%b",
                         addr, expected, rd_data, rd_valid);
                errors = errors + 1;
            end else begin
                $display("PASS addr=%0d data=%06h", addr, rd_data);
            end

            @(negedge clk);
            rd_en = 0;
        end
    endtask

    initial begin
        errors = 0;
        tests = 0;
        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_en = 0;
        rd_addr = 0;

        $dumpfile("part1v_output_read_advanced.vcd");
        $dumpvars(0, tb_part1v_output_read_advanced);

        $display("=== ADVANCED OUTPUT SRAM VERIFICATION ===");

        // Initialize two locations
        write_word(8'd5, 24'h112233);
        write_word(8'd6, 24'hAABBCC);

        // Test 1: Normal read
        check_word(8'd5, 24'h112233);

        // Test 2: Read the same address again
        check_word(8'd5, 24'h112233);

        // Test 3: Read a different initialized address
        check_word(8'd6, 24'hAABBCC);

        // Test 4: Disabled read behavior
        @(negedge clk);
        rd_en = 0;
        @(posedge clk);
        #1;
        tests = tests + 1;

        if (rd_valid !== 1'b0 || rd_data !== 24'h000000) begin
            $display("FAIL disabled-read behavior");
            errors = errors + 1;
        end else begin
            $display("PASS disabled-read behavior");
        end

        // Test 5: Simultaneous read and write to the same address.
        // The read observes the old value in this implementation.
        @(negedge clk);
        wr_en = 1;
        wr_addr = 8'd5;
        wr_data = 24'h445566;
        rd_en = 1;
        rd_addr = 8'd5;

        @(posedge clk);
        #1;
        tests = tests + 1;

        if (rd_data !== 24'h112233 || rd_valid !== 1'b1) begin
            $display("FAIL same-edge read/write behavior: %06h", rd_data);
            errors = errors + 1;
        end else begin
            $display("PASS same-edge read/write returns old value");
        end

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        // Verify the new value was written
        check_word(8'd5, 24'h445566);

        $display("----------------------------------");
        if (errors == 0)
            $display("ADVANCED TEST PASSED: %0d/%0d checks", tests, tests);
        else
            $display("ADVANCED TEST FAILED: %0d errors", errors);

        $finish;
    end

    initial begin
        #2000;
        $display("ERROR: Testbench timeout");
        $finish;
    end

endmodule
