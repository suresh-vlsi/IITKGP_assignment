`timescale 1ns/1ps

module mac_parallel_pipe3 #(
    parameter W = 8,
    parameter N = 9
)(
    input  logic clk,
    input  logic reset_n,
    input  logic valid_in,

    input  logic signed [W-1:0] data0,
    input  logic signed [W-1:0] data1,
    input  logic signed [W-1:0] data2,
    input  logic signed [W-1:0] data3,
    input  logic signed [W-1:0] data4,
    input  logic signed [W-1:0] data5,
    input  logic signed [W-1:0] data6,
    input  logic signed [W-1:0] data7,
    input  logic signed [W-1:0] data8,

    input  logic signed [W-1:0] weight0,
    input  logic signed [W-1:0] weight1,
    input  logic signed [W-1:0] weight2,
    input  logic signed [W-1:0] weight3,
    input  logic signed [W-1:0] weight4,
    input  logic signed [W-1:0] weight5,
    input  logic signed [W-1:0] weight6,
    input  logic signed [W-1:0] weight7,
    input  logic signed [W-1:0] weight8,

    output logic signed [2*W+4:0] mac_out,
    output logic out_valid
);

    // =========================================================
    // STAGE 1
    // Nine parallel multipliers
    // =========================================================

    logic signed [2*W-1:0] product0_s1;
    logic signed [2*W-1:0] product1_s1;
    logic signed [2*W-1:0] product2_s1;
    logic signed [2*W-1:0] product3_s1;
    logic signed [2*W-1:0] product4_s1;
    logic signed [2*W-1:0] product5_s1;
    logic signed [2*W-1:0] product6_s1;
    logic signed [2*W-1:0] product7_s1;
    logic signed [2*W-1:0] product8_s1;

    // =========================================================
    // STAGE 2
    // Partial sums
    // =========================================================

    logic signed [2*W:0] sum01_s2;
    logic signed [2*W:0] sum23_s2;
    logic signed [2*W:0] sum45_s2;
    logic signed [2*W:0] sum67_s2;

    logic signed [2*W+1:0] sum0123_s2;
    logic signed [2*W+1:0] sum4567_s2;

    logic signed [2*W-1:0] product8_s2;

    // =========================================================
    // STAGE 3
    // Final result
    // =========================================================

    logic signed [2*W+2:0] sum_tree_s3;

    // Valid pipeline
    logic valid_s1;
    logic valid_s2;
    logic valid_s3;

    // =========================================================
    // Sequential pipeline
    // =========================================================

    always_ff @(posedge clk) begin

        if (!reset_n) begin

            // Stage 1
            product0_s1 <= '0;
            product1_s1 <= '0;
            product2_s1 <= '0;
            product3_s1 <= '0;
            product4_s1 <= '0;
            product5_s1 <= '0;
            product6_s1 <= '0;
            product7_s1 <= '0;
            product8_s1 <= '0;

            // Stage 2
            sum01_s2   <= '0;
            sum23_s2   <= '0;
            sum45_s2   <= '0;
            sum67_s2   <= '0;
            sum0123_s2 <= '0;
            sum4567_s2 <= '0;
            product8_s2 <= '0;

            // Stage 3
            sum_tree_s3 <= '0;

            // Valid pipeline
            valid_s1 <= 1'b0;
            valid_s2 <= 1'b0;
            valid_s3 <= 1'b0;

            mac_out   <= '0;
            out_valid <= 1'b0;

        end

        else begin

            // =================================================
            // STAGE 1
            // =================================================

            valid_s1 <= valid_in;

            if (valid_in) begin

                product0_s1 <= data0 * weight0;
                product1_s1 <= data1 * weight1;
                product2_s1 <= data2 * weight2;
                product3_s1 <= data3 * weight3;
                product4_s1 <= data4 * weight4;
                product5_s1 <= data5 * weight5;
                product6_s1 <= data6 * weight6;
                product7_s1 <= data7 * weight7;
                product8_s1 <= data8 * weight8;

            end

            // =================================================
            // STAGE 2
            // =================================================

            valid_s2 <= valid_s1;

            if (valid_s1) begin

                sum01_s2 <= product0_s1 + product1_s1;
                sum23_s2 <= product2_s1 + product3_s1;
                sum45_s2 <= product4_s1 + product5_s1;
                sum67_s2 <= product6_s1 + product7_s1;

                sum0123_s2 <=
                    (product0_s1 + product1_s1) +
                    (product2_s1 + product3_s1);

                sum4567_s2 <=
                    (product4_s1 + product5_s1) +
                    (product6_s1 + product7_s1);

                product8_s2 <= product8_s1;

            end

            // =================================================
            // STAGE 3
            // =================================================

            valid_s3 <= valid_s2;

            if (valid_s2) begin

                sum_tree_s3 <=
                    sum0123_s2 +
                    sum4567_s2 +
                    product8_s2;

                mac_out <=
                    sum0123_s2 +
                    sum4567_s2 +
                    product8_s2;

            end

            out_valid <= valid_s2;

        end

    end

endmodule