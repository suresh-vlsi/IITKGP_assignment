`timescale 1ns/1ps

module mac_seq_a #(
    parameter W = 8,
    parameter SEQ_LEN = 8
)(
    input  logic clk,
    input  logic reset_n,
    input  logic valid_in,

    input  logic signed [W-1:0] data_in,
    input  logic signed [W-1:0] weight_in,

    output logic signed [2*W+3:0] mac_out,
    output logic out_valid
);

    // Accumulator
    logic signed [2*W+3:0] accumulator;

    // Counts valid input samples
    logic [3:0] count;

    // 8-bit signed × 8-bit signed = 16-bit signed product
    logic signed [2*W-1:0] product;

    assign product = data_in * weight_in;

    always_ff @(posedge clk) begin

        if (!reset_n) begin
            accumulator <= '0;
            count       <= '0;
            mac_out     <= '0;
            out_valid   <= 1'b0;
        end

        else begin

            // Default value
            out_valid <= 1'b0;

            if (valid_in) begin

                // Last sample of 8-sample sequence
                if (count == SEQ_LEN-1) begin

                    // Include the 8th multiplication
                    mac_out <= accumulator + product;

                    out_valid <= 1'b1;

                    // Prepare for next MAC sequence
                    accumulator <= '0;
                    count       <= '0;

                end

                else begin

                    accumulator <= accumulator + product;
                    count       <= count + 1'b1;

                end

            end

        end

    end

endmodule