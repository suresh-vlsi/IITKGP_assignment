`timescale 1ns/1ps

module tb_mac_seq_b;

    localparam W = 8;
    localparam N = 9;

    logic clk;
    logic reset_n;

    logic load_weight;

    logic signed [W-1:0] weight_in;
    logic signed [W-1:0] data_in;

    logic signed [2*W+4:0] mac_out;
    logic out_valid;

    integer expected;

    // ============================================================
    // DUT
    // ============================================================

    mac_seq_b #(
        .W(W),
        .N(N)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .load_weight(load_weight),
        .weight_in(weight_in),
        .data_in(data_in),
        .mac_out(mac_out),
        .out_valid(out_valid)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Waveform
        // --------------------------------------------------------

        $dumpfile("mac_seq_b.vcd");
        $dumpvars(0, tb_mac_seq_b);

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        reset_n    = 1'b0;
        load_weight = 1'b0;
        weight_in  = '0;
        data_in    = '0;

        // Expected result:
        //
        // 10  *  2  =  20
        // 20  *  3  =  60
        // -5  *  4  = -20
        // 7   * -6  = -42
        // 12  *  5  =  60
        // -8  * -3  =  24
        // 4   *  9  =  36
        // -10 *  2  = -20
        // 6   * -4  = -24
        //
        // TOTAL = 94

        expected = 94;

        // ========================================================
        // RESET
        // ========================================================

        repeat (2) @(posedge clk);

        reset_n = 1'b1;

        // ========================================================
        // WEIGHT LOAD PHASE
        // ========================================================

        // Weight 0 = +2
        @(negedge clk);
        load_weight = 1'b1;
        weight_in = 8'sd2;

        // Weight 1 = +3
        @(negedge clk);
        weight_in = 8'sd3;

        // Weight 2 = +4
        @(negedge clk);
        weight_in = 8'sd4;

        // Weight 3 = -6
        @(negedge clk);
        weight_in = -8'sd6;

        // Weight 4 = +5
        @(negedge clk);
        weight_in = 8'sd5;

        // Weight 5 = -3
        @(negedge clk);
        weight_in = -8'sd3;

        // Weight 6 = +9
        @(negedge clk);
        weight_in = 8'sd9;

        // Weight 7 = +2
        @(negedge clk);
        weight_in = 8'sd2;

        // Weight 8 = -4
        @(negedge clk);
        weight_in = -8'sd4;

        // ========================================================
        // TRANSITION TO COMPUTE
        // ========================================================
        //
        // IMPORTANT:
        // Put the FIRST DATA VALUE here BEFORE the next
        // positive clock edge.
        //
        // This prevents an unwanted data=0 compute cycle.
        // ========================================================

        @(negedge clk);
        load_weight = 1'b0;
        weight_in   = '0;
        data_in     = 8'sd10;

        // ========================================================
        // COMPUTE PHASE
        // ========================================================

        // Data 0 = +10
        @(posedge clk);

        // Data 1 = +20
        @(negedge clk);
        data_in = 8'sd20;

        // Data 2 = -5
        @(negedge clk);
        data_in = -8'sd5;

        // Data 3 = +7
        @(negedge clk);
        data_in = 8'sd7;

        // Data 4 = +12
        @(negedge clk);
        data_in = 8'sd12;

        // Data 5 = -8
        @(negedge clk);
        data_in = -8'sd8;

        // Data 6 = +4
        @(negedge clk);
        data_in = 8'sd4;

        // Data 7 = -10
        @(negedge clk);
        data_in = -8'sd10;

        // Data 8 = +6
        @(negedge clk);
        data_in = 8'sd6;

        // ========================================================
        // 9th COMPUTE OPERATION
        // ========================================================

        @(posedge clk);

        // Allow nonblocking assignments to update
        #1;

        // ========================================================
        // CHECK RESULT IMMEDIATELY
        // ========================================================

        if (out_valid && (mac_out == expected)) begin

            $display("");
            $display("==============================================");
            $display("          ASSIGNMENT 1(b) TEST PASSED");
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
            $display("          ASSIGNMENT 1(b) TEST FAILED");
            $display("==============================================");
            $display("Expected MAC = %0d", expected);
            $display("Actual MAC   = %0d", mac_out);
            $display("out_valid    = %b", out_valid);
            $display("==============================================");
            $display("");

        end

        // Stop simulation
        #10;
        $finish;

    end

    // ============================================================
    // DEBUG OUTPUT
    // ============================================================

    always @(posedge clk) begin

        if (!reset_n) begin

            $display(
                "RESET | TIME=%0t ns",
                $time
            );

        end

        else if (load_weight) begin

            $display(
                "LOAD | TIME=%0t ns | index=%0d | weight=%0d",
                $time,
                dut.load_idx,
                weight_in
            );

        end

        else begin

            $display(
                "COMPUTE | TIME=%0t ns | index=%0d | data=%0d | weight=%0d | product=%0d | acc=%0d",
                $time,
                dut.comp_idx,
                data_in,
                dut.current_weight,
                dut.product,
                dut.accumulator
            );

        end

        if (out_valid) begin

            $display(
                "RESULT | TIME=%0t ns | MAC_OUT=%0d",
                $time,
                mac_out
            );

        end

    end

endmodule