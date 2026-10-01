`timescale 1ns/1ps

module mac_seq_b #(
    parameter W = 8,
    parameter N = 9
)(
    input  logic clk,
    input  logic reset_n,

    // Weight loading phase
    input  logic load_weight,
    input  logic signed [W-1:0] weight_in,

    // Compute phase
    input  logic signed [W-1:0] data_in,

    output logic signed [2*W+4:0] mac_out,
    output logic out_valid
);

    // ------------------------------------------------
    // Local weight register file
    // ------------------------------------------------
    logic signed [W-1:0] kernel_buff [0:N-1];

    // ------------------------------------------------
    // Load and compute counters
    // ------------------------------------------------
    logic [3:0] load_idx;
    logic [3:0] comp_idx;

    // ------------------------------------------------
    // Current weight and multiplication
    // ------------------------------------------------
    logic signed [W-1:0] current_weight;
    logic signed [2*W-1:0] product;

    // ------------------------------------------------
    // Accumulator
    // ------------------------------------------------
    logic signed [2*W+4:0] accumulator;

    // Weight selected during compute
    assign current_weight = kernel_buff[comp_idx];

    // Signed multiplication
    assign product = data_in * current_weight;

    // ------------------------------------------------
    // Sequential logic
    // ------------------------------------------------
    always_ff @(posedge clk) begin

        if (!reset_n) begin

            load_idx   <= '0;
            comp_idx   <= '0;

            accumulator <= '0;
            mac_out     <= '0;

            out_valid <= 1'b0;

        end

        else begin

            // Default
            out_valid <= 1'b0;

            // ------------------------------------------------
            // WEIGHT LOAD PHASE
            // ------------------------------------------------
            if (load_weight) begin

                kernel_buff[load_idx] <= weight_in;

                if (load_idx == N-1) begin
                    load_idx <= '0;
                    comp_idx <= '0;
                    accumulator <= '0;
                end
                else begin
                    load_idx <= load_idx + 1'b1;
                end

            end

            // ------------------------------------------------
            // COMPUTE PHASE
            // ------------------------------------------------
            else begin

                if (comp_idx == N-1) begin

                    // Include final product
                    mac_out <= accumulator + product;

                    out_valid <= 1'b1;

                    // Prepare for next sequence
                    accumulator <= '0;
                    comp_idx <= '0;

                end

                else begin

                    accumulator <= accumulator + product;

                    comp_idx <= comp_idx + 1'b1;

                end

            end

        end

    end

endmodule