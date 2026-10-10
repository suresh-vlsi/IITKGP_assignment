`timescale 1ns/1ps
module tb_cnn_output_sram_part1;
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
    reg finished;
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
// 10 ns clock period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
// Write one 24-bit output word
    task write_word;
        input [7:0] addr;
        input [23:0] data;
        begin
            @(negedge clk);
            wr_en   = 1'b1;
            wr_addr = addr;
            wr_data = data;
@(negedge clk);
            wr_en = 1'b0;
        end
    endtask
// Read and compare one output word
    task check_word;
        input [7:0] addr;
        input [23:0] expected;
        begin
            tests = tests + 1;
@(negedge clk);
            rd_en   = 1'b1;
            rd_addr = addr;
@(posedge clk);
            #1;
$display(
                "Test %0d: addr=%0d expected=%06h actual=%06h",
                tests, addr, expected, rd_data
            );
if (rd_data !== expected || rd_valid !== 1'b1) begin
                $display("RESULT: FAIL");
                errors = errors + 1;
            end
            else begin
                $display("RESULT: PASS");
            end
@(negedge clk);
            rd_en = 1'b0;
        end
    endtask
initial begin
        errors = 0;
        tests = 0;
        finished = 1'b0;
wr_en = 1'b0;
        wr_addr = 0;
        wr_data = 0;
rd_en = 1'b0;
        rd_addr = 0;
$dumpfile("cnn_output_sram_part1.vcd");
        $dumpvars(0, tb_cnn_output_sram_part1);
$display("========================================");
        $display(" PART 1(iii): OUTPUT SRAM VERIFICATION");
        $display("========================================");
// Write known output values
        write_word(8'd0,   24'h123456);
        write_word(8'd1,   24'hABCDEF);
        write_word(8'd17,  24'h00FF80);
        write_word(8'd255, 24'hFEDCBA);
// Read back and verify
        check_word(8'd0,   24'h123456);
        check_word(8'd1,   24'hABCDEF);
        check_word(8'd17,  24'h00FF80);
        check_word(8'd255, 24'hFEDCBA);
        $display("----------------------------------------");
if (errors == 0)
            $display("PART 1(iii) PASSED: %0d/%0d tests",
                     tests, tests);
        else
            $display("PART 1(iii) FAILED: %0d errors", errors);
        $display("----------------------------------------");
finished = 1'b1;
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