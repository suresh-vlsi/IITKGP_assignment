`timescale 1ns/1ps

module cnn_conv_window_fifo (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              pixel_valid,
    input  wire signed [7:0]  pixel_in,

    input  wire signed [7:0]  kernel0,
    input  wire signed [7:0]  kernel1,
    input  wire signed [7:0]  kernel2,
    input  wire signed [7:0]  kernel3,
    input  wire signed [7:0]  kernel4,
    input  wire signed [7:0]  kernel5,
    input  wire signed [7:0]  kernel6,
    input  wire signed [7:0]  kernel7,
    input  wire signed [7:0]  kernel8,

    output wire signed [7:0]  p00,
    output wire signed [7:0]  p01,
    output wire signed [7:0]  p02,
    output wire signed [7:0]  p10,
    output wire signed [7:0]  p11,
    output wire signed [7:0]  p12,
    output wire signed [7:0]  p20,
    output wire signed [7:0]  p21,
    output wire signed [7:0]  p22,

    output wire              win_valid_next,
    output reg               out_valid,
    output reg signed [23:0] mac_sum
);

    reg signed [7:0] fifo [0:8];
    reg [3:0] fifo_count;
    integer i;

    // fifo[0] is the oldest sample; fifo[8] is the newest.
    assign p00 = fifo[0];
    assign p01 = fifo[1];
    assign p02 = fifo[2];
    assign p10 = fifo[3];
    assign p11 = fifo[4];
    assign p12 = fifo[5];
    assign p20 = fifo[6];
    assign p21 = fifo[7];
    assign p22 = fifo[8];

    // High when accepting the current input will produce a full 9-pixel window.
    assign win_valid_next = pixel_valid && (fifo_count >= 4'd8);

    // Calculate the window that will exist AFTER the current accepted pixel.
    // This lets the ninth input participate in the first complete MAC result.
    wire signed [7:0] q0 = (fifo_count >= 4'd8) ? fifo[1] : fifo[0];
    wire signed [7:0] q1 = (fifo_count >= 4'd8) ? fifo[2] : fifo[1];
    wire signed [7:0] q2 = (fifo_count >= 4'd8) ? fifo[3] : fifo[2];
    wire signed [7:0] q3 = (fifo_count >= 4'd8) ? fifo[4] : fifo[3];
    wire signed [7:0] q4 = (fifo_count >= 4'd8) ? fifo[5] : fifo[4];
    wire signed [7:0] q5 = (fifo_count >= 4'd8) ? fifo[6] : fifo[5];
    wire signed [7:0] q6 = (fifo_count >= 4'd8) ? fifo[7] : fifo[6];
    wire signed [7:0] q7 = (fifo_count >= 4'd8) ? fifo[8] : fifo[7];
    wire signed [7:0] q8 = pixel_in;

    wire signed [15:0] prod0 = q0 * kernel0;
    wire signed [15:0] prod1 = q1 * kernel1;
    wire signed [15:0] prod2 = q2 * kernel2;
    wire signed [15:0] prod3 = q3 * kernel3;
    wire signed [15:0] prod4 = q4 * kernel4;
    wire signed [15:0] prod5 = q5 * kernel5;
    wire signed [15:0] prod6 = q6 * kernel6;
    wire signed [15:0] prod7 = q7 * kernel7;
    wire signed [15:0] prod8 = q8 * kernel8;

    wire signed [23:0] sum_next =
        {{8{prod0[15]}},prod0} + {{8{prod1[15]}},prod1} +
        {{8{prod2[15]}},prod2} + {{8{prod3[15]}},prod3} +
        {{8{prod4[15]}},prod4} + {{8{prod5[15]}},prod5} +
        {{8{prod6[15]}},prod6} + {{8{prod7[15]}},prod7} +
        {{8{prod8[15]}},prod8};

    always @(posedge clk) begin
        if (!rst_n) begin
            fifo_count <= 0;
            out_valid  <= 0;
            mac_sum    <= 0;
            for (i = 0; i < 9; i = i + 1)
                fifo[i] <= 0;
        end else begin
            out_valid <= 0;
            if (pixel_valid) begin
                for (i = 0; i < 8; i = i + 1)
                    fifo[i] <= fifo[i+1];
                fifo[8] <= pixel_in;

                if (fifo_count < 9)
                    fifo_count <= fifo_count + 1'b1;

                if (fifo_count >= 8) begin
                    mac_sum   <= sum_next;
                    out_valid <= 1;
                end
            end
        end
    end
endmodule
