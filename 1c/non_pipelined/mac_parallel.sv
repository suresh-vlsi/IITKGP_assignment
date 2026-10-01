`timescale 1ns/1ps

module mac_parallel #(
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
    // Nine parallel multipliers
    // =========================================================

    logic signed [2*W-1:0] product0;
    logic signed [2*W-1:0] product1;
    logic signed [2*W-1:0] product2;
    logic signed [2*W-1:0] product3;
    logic signed [2*W-1:0] product4;
    logic signed [2*W-1:0] product5;
    logic signed [2*W-1:0] product6;
    logic signed [2*W-1:0] product7;
    logic signed [2*W-1:0] product8;

    assign product0 = data0 * weight0;
    assign product1 = data1 * weight1;
    assign product2 = data2 * weight2;
    assign product3 = data3 * weight3;
    assign product4 = data4 * weight4;
    assign product5 = data5 * weight5;
    assign product6 = data6 * weight6;
    assign product7 = data7 * weight7;
    assign product8 = data8 * weight8;

    // =========================================================
    // Adder tree
    // =========================================================

    logic signed [2*W:0] sum01;
    logic signed [2*W:0] sum23;
    logic signed [2*W:0] sum45;
    logic signed [2*W:0] sum67;

    logic signed [2*W+1:0] sum0123;
    logic signed [2*W+1:0] sum4567;

    logic signed [2*W+2:0] sum_tree;

    assign sum01 = product0 + product1;
    assign sum23 = product2 + product3;
    assign sum45 = product4 + product5;
    assign sum67 = product6 + product7;

    assign sum0123 = sum01 + sum23;
    assign sum4567 = sum45 + sum67;

    assign sum_tree = sum0123 + sum4567 + product8;

    // =========================================================
    // Output
    // =========================================================

    always_comb begin

        if (!reset_n) begin
            mac_out   = '0;
            out_valid = 1'b0;
        end

        else begin
            mac_out   = sum_tree;
            out_valid = valid_in;
        end

    end

endmodule