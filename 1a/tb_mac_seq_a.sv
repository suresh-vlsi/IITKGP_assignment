`timescale 1ns/1ps

module tb_mac_seq_a;

    localparam W = 8;
    localparam SEQ_LEN = 8;

    logic clk;
    logic reset_n;
    logic valid_in;

    logic signed [W-1:0] data_in;
    logic signed [W-1:0] weight_in;

    logic signed [2*W+3:0] mac_out;
    logic out_valid;

    integer expected;

    // DUT
    mac_seq_a #(
        .W(W),
        .SEQ_LEN(SEQ_LEN)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .weight_in(weight_in),
        .mac_out(mac_out),
        .out_valid(out_valid)
    );

    // 10 ns clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mac_seq_a.vcd");
        $dumpvars(0, tb_mac_seq_a);

        reset_n   = 1'b0;
        valid_in  = 1'b0;
        data_in   = '0;
        weight_in = '0;

        // Expected result:
        // 10*2 + 20*3 + (-5)*4 + 7*(-6)
        // + 12*5 + (-8)*(-3) + 4*9 + (-10)*2
        expected = 118;

        // Reset
        repeat (2) @(posedge clk);

        reset_n = 1'b1;

        // ------------------------------------------------
        // Input 1
        // 10 × 2 = 20
        // ------------------------------------------------
        @(negedge clk);
        valid_in  = 1'b1;
        data_in   = 8'sd10;
        weight_in = 8'sd2;

        // ------------------------------------------------
        // Input 2
        // 20 × 3 = 60
        // ------------------------------------------------
        @(negedge clk);
        data_in   = 8'sd20;
        weight_in = 8'sd3;

        // ------------------------------------------------
        // Input 3
        // -5 × 4 = -20
        // ------------------------------------------------
        @(negedge clk);
        data_in   = -8'sd5;
        weight_in = 8'sd4;

        // ------------------------------------------------
        // Input 4
        // 7 × -6 = -42
        // ------------------------------------------------
        @(negedge clk);
        data_in   = 8'sd7;
        weight_in = -8'sd6;

        // ------------------------------------------------
        // Input 5
        // 12 × 5 = 60
        // ------------------------------------------------
        @(negedge clk);
        data_in   = 8'sd12;
        weight_in = 8'sd5;

        // ------------------------------------------------
        // Input 6
        // -8 × -3 = 24
        // ------------------------------------------------
        @(negedge clk);
        data_in   = -8'sd8;
        weight_in = -8'sd3;

        // ------------------------------------------------
        // Input 7
        // 4 × 9 = 36
        // ------------------------------------------------
        @(negedge clk);
        data_in   = 8'sd4;
        weight_in = 8'sd9;

        // ------------------------------------------------
        // Input 8
        // -10 × 2 = -20
        // ------------------------------------------------
        @(negedge clk);
        data_in   = -8'sd10;
        weight_in = 8'sd2;

        // 8th MAC operation
        @(posedge clk);

        // Stop inputs
        @(negedge clk);
        valid_in  = 1'b0;
        data_in   = '0;
        weight_in = '0;

        // Check result
        @(posedge clk);

        if (mac_out == expected) begin
            $display("");
            $display("==============================================");
            $display("              TEST PASSED");
            $display("==============================================");
            $display("Expected MAC = %0d", expected);
            $display("Actual MAC   = %0d", mac_out);
            $display("==============================================");
            $display("");
        end
        else begin
            $display("");
            $display("==============================================");
            $display("              TEST FAILED");
            $display("==============================================");
            $display("Expected MAC = %0d", expected);
            $display("Actual MAC   = %0d", mac_out);
            $display("==============================================");
            $display("");
        end

        #10;
        $finish;

    end

    // Debug information
    always @(posedge clk) begin

        if (valid_in) begin
            $display(
                "TIME=%0t ns | DATA=%0d | WEIGHT=%0d | PRODUCT=%0d | COUNT=%0d | ACC=%0d",
                $time,
                data_in,
                weight_in,
                data_in * weight_in,
                dut.count,
                dut.accumulator
            );
        end

        if (out_valid) begin
            $display(
                "TIME=%0t ns | MAC COMPLETE | MAC_OUT=%0d",
                $time,
                mac_out
            );
        end

    end

endmodule