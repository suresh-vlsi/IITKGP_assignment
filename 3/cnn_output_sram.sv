
`timescale 1ns/1ps

module cnn_output_sram (
    input  wire        clk,

    // Write interface
    input  wire        wr_en,
    input  wire [7:0]  wr_addr,
    input  wire [23:0] wr_data,

    // Read interface
    input  wire        rd_en,
    input  wire [7:0]  rd_addr,
    output reg  [23:0] rd_data,
    output reg         rd_valid
);

    // 256 words x 24 bits
    reg [23:0] mem [0:255];

    // Synchronous write and read
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;

        if (rd_en) begin
            rd_data  <= mem[rd_addr];
            rd_valid <= 1'b1;
        end
        else begin
            rd_data  <= 24'h000000;
            rd_valid <= 1'b0;
        end
    end

endmodule
