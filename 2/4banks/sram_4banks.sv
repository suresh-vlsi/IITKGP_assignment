`timescale 1ns/1ps

module sram_4banks (
    input  logic        clk,
    input  logic        we,
    input  logic        re,

    // 14-bit 32-bit-word address
    //
    // [13:12] = bank select
    // [11:4]  = row address
    // [3:0]   = word select within 512-bit row
    input  logic [13:0] addr,

    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    output logic [1:0] bank_sel
);

    // =========================================================
    // FOUR-BANK SRAM
    //
    // Each bank:
    //     256 rows x 512 bits
    //
    // Each 512-bit row contains:
    //     512 / 32 = 16 words
    //
    // Therefore:
    //     256 x 16 = 4096 words
    //
    // Each bank:
    //     4096 x 4 bytes = 16384 bytes = 16 KB
    //
    // Four banks:
    //     4 x 16 KB = 64 KB
    // =========================================================

    logic [511:0] bank0 [0:255];
    logic [511:0] bank1 [0:255];
    logic [511:0] bank2 [0:255];
    logic [511:0] bank3 [0:255];

    // =========================================================
    // ADDRESS DECODING
    // =========================================================

    logic [7:0] row_addr;
    logic [3:0] word_sel;

    assign bank_sel = addr[13:12];
    assign row_addr = addr[11:4];
    assign word_sel = addr[3:0];

    // =========================================================
    // WRITE OPERATION
    // =========================================================

    always_ff @(posedge clk) begin

        if (we) begin

            case (bank_sel)

                2'd0: begin
                    bank0[row_addr][word_sel*32 +: 32] <= wdata;
                end

                2'd1: begin
                    bank1[row_addr][word_sel*32 +: 32] <= wdata;
                end

                2'd2: begin
                    bank2[row_addr][word_sel*32 +: 32] <= wdata;
                end

                2'd3: begin
                    bank3[row_addr][word_sel*32 +: 32] <= wdata;
                end

            endcase

        end

    end

    // =========================================================
    // READ OPERATION
    // =========================================================

    always_comb begin

        rdata = 32'b0;

        if (re) begin

            case (bank_sel)

                2'd0: begin
                    rdata = bank0[row_addr][word_sel*32 +: 32];
                end

                2'd1: begin
                    rdata = bank1[row_addr][word_sel*32 +: 32];
                end

                2'd2: begin
                    rdata = bank2[row_addr][word_sel*32 +: 32];
                end

                2'd3: begin
                    rdata = bank3[row_addr][word_sel*32 +: 32];
                end

            endcase

        end

    end

endmodule