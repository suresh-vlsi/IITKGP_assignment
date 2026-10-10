`timescale 1ns/1ps

module tb_part3_conv_window_fifo;
    reg clk = 0;
    reg rst_n = 0;
    reg pixel_valid = 0;
    reg signed [7:0] pixel_in = 0;

    // Kernel: [1 0 -1; 1 0 -1; 1 0 -1]
    reg signed [7:0] k0 = 1, k1 = 0, k2 = -1;
    reg signed [7:0] k3 = 1, k4 = 0, k5 = -1;
    reg signed [7:0] k6 = 1, k7 = 0, k8 = -1;

    wire signed [7:0] p00,p01,p02,p10,p11,p12,p20,p21,p22;
    wire win_valid_next;
    wire out_valid;
    wire signed [23:0] mac_sum;

    integer errors = 0;
    integer output_checks = 0;
    integer n;
    reg expected_win_next;

    cnn_conv_window_fifo dut (
        .clk(clk), .rst_n(rst_n),
        .pixel_valid(pixel_valid), .pixel_in(pixel_in),
        .kernel0(k0), .kernel1(k1), .kernel2(k2),
        .kernel3(k3), .kernel4(k4), .kernel5(k5),
        .kernel6(k6), .kernel7(k7), .kernel8(k8),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .win_valid_next(win_valid_next),
        .out_valid(out_valid), .mac_sum(mac_sum)
    );

    always #5 clk = ~clk;

    task send_pixel;
        input integer value;
        input integer index;
        begin
            @(negedge clk);
            pixel_valid = 1;
            pixel_in = value;
            #1;
            expected_win_next = (index >= 8);
            if (win_valid_next !== expected_win_next) begin
                $display("FAIL win_valid_next at input index %0d: got %b expected %b", index, win_valid_next, expected_win_next);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (index >= 8) begin
                output_checks = output_checks + 1;
                if (out_valid !== 1'b1) begin
                    $display("FAIL out_valid at input index %0d", index);
                    errors = errors + 1;
                end
                // With this vertical-edge kernel, each 9-sample window
                // of consecutive integers 1..9, then 2..10, sums to -6.
                if (mac_sum !== -24'sd6) begin
                    $display("FAIL mac_sum at input index %0d: got %0d expected -6", index, mac_sum);
                    errors = errors + 1;
                end else begin
                    $display("PASS window ending at input %0d: mac_sum=%0d", index+1, mac_sum);
                end
            end else if (out_valid !== 1'b0) begin
                $display("FAIL out_valid asserted before full window at index %0d", index);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("part3_conv_window_fifo.vcd");
        $dumpvars(0,tb_part3_conv_window_fifo);
        repeat (2) @(negedge clk);
        rst_n = 1;

        for (n = 1; n <= 10; n = n + 1)
            send_pixel(n, n-1);

        @(negedge clk);
        pixel_valid = 0;

        $display("------------------------------------");
        $display("Part 3 output checks : %0d", output_checks);
        $display("Errors              : %0d", errors);
        if (errors == 0 && output_checks == 2)
            $display("PART 3 STANDALONE WINDOW/MAC TEST PASSED");
        else
            $display("PART 3 STANDALONE WINDOW/MAC TEST FAILED");
        $display("------------------------------------");
        $finish;
    end

    initial begin
        #5000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
