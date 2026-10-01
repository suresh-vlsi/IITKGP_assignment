`timescale 1ns/1ps

module sram_64kb (
    input  logic        clk,
    input  logic        we,
    input  logic        re,
    input  logic [13:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);

    // =========================================================
    // 64 KB SRAM
    //
    // Physical array:
    //     1024 rows x 512 bits
    //
    // 512 bits / 32 bits = 16 words per row
    //
    // Total:
    //     1024 x 16 = 16384 words
    //     16384 x 4 bytes = 65536 bytes = 64 KB
    // =========================================================

    logic [511:0] mem [0:1023];

    logic [9:0]  row_addr;
    logic [3:0]  word_sel;

    assign row_addr = addr[13:4];
    assign word_sel = addr[3:0];

    // =========================================================
    // WRITE
    // =========================================================

    always_ff @(posedge clk) begin

        if (we) begin

            mem[row_addr][word_sel*32 +: 32] <= wdata;

        end

    end

    // =========================================================
    // READ
    // =========================================================

    always_comb begin

        if (re) begin

            rdata = mem[row_addr][word_sel*32 +: 32];

        end
        else begin

            rdata = 32'b0;

        end

    end

endmodule