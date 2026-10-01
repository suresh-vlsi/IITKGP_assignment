`timescale 1ns/1ps

module tb_mac_parallel_pipe3;

    logic clk;
    logic reset_n;
    logic valid_in;

    logic signed [7:0] data0;
    logic signed [7:0] data1;
    logic signed [7:0] data2;
    logic signed [7:0] data3;
    logic signed [7:0] data4;
    logic signed [7:0] data5;
    logic signed [7:0] data6;
    logic signed [7:0] data7;
    logic signed [7:0] data8;

    logic signed [7:0] weight0;
    logic signed [7:0] weight1;
    logic signed [7:0] weight2;
    logic signed [7:0] weight3;
    logic signed [7:0] weight4;
    logic signed [7:0] weight5;
    logic signed [7:0] weight6;
    logic signed [7:0] weight7;
    logic signed [7:0] weight8;

    logic signed [20:0] mac_out;
    logic out_valid;

    integer expected;

    // =========================================================
    // DUT
    // =========================================================

    mac_parallel_pipe3 dut (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(valid_in),

        .data0(data0),
        .data1(data1),
        .data2(data2),
        .data3(data3),
        .data4(data4),
        .data5(data5),
        .data6(data6),
        .data7(data7),
        .data8(data8),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),
        .weight8(weight8),

        .mac_out(mac_out),
        .out_valid(out_valid)
    );

    // =========================================================
    // CLOCK
    // =========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("mac_parallel_pipe3.vcd");
        $dumpvars(0, tb_mac_parallel_pipe3);

        reset_n  = 1'b0;
        valid_in = 1'b0;

        data0 = 0;
        data1 = 0;
        data2 = 0;
        data3 = 0;
        data4 = 0;
        data5 = 0;
        data6 = 0;
        data7 = 0;
        data8 = 0;

        weight0 = 0;
        weight1 = 0;
        weight2 = 0;
        weight3 = 0;
        weight4 = 0;
        weight5 = 0;
        weight6 = 0;
        weight7 = 0;
        weight8 = 0;

        expected = 94;

        // =====================================================
        // RESET
        // =====================================================

        repeat (2) @(posedge clk);

        reset_n = 1'b1;

        // =====================================================
        // INPUT VECTOR
        // =====================================================

        @(negedge clk);

        data0 = 8'sd10;
        data1 = 8'sd20;
        data2 = -8'sd5;
        data3 = 8'sd7;
        data4 = 8'sd12;
        data5 = -8'sd8;
        data6 = 8'sd4;
        data7 = -8'sd10;
        data8 = 8'sd6;

        weight0 = 8'sd2;
        weight1 = 8'sd3;
        weight2 = 8'sd4;
        weight3 = -8'sd6;
        weight4 = 8'sd5;
        weight5 = -8'sd3;
        weight6 = 8'sd9;
        weight7 = 8'sd2;
        weight8 = -8'sd4;

        valid_in = 1'b1;

        // Stage 1
        @(posedge clk);

        // Remove valid after one input vector
        @(negedge clk);
        valid_in = 1'b0;

        // =====================================================
        // Wait for 3-stage pipeline
        // =====================================================

        repeat (2) @(posedge clk);

        #1;

        // =====================================================
        // CHECK
        // =====================================================

        if (out_valid && (mac_out == expected)) begin

            $display("");
            $display("==============================================");
            $display("       1(c)(ii) 3-STAGE PIPELINE PASSED");
            $display("==============================================");
            $display("Expected MAC = %0d", expected);
            $display("Actual MAC   = %0d", mac_out);
            $display("out_valid    = %b", out_valid);
            $display("==============================================");
            $display("");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("       1(c)(ii) 3-STAGE PIPELINE FAILED");
            $display("==============================================");
            $display("Expected MAC = %0d", expected);
            $display("Actual MAC   = %0d", mac_out);
            $display("out_valid    = %b", out_valid);
            $display("==============================================");
            $display("");

        end

        #20;
        $finish;

    end

endmodule