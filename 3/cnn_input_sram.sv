`timescale 1ns/1ps

module cnn_input_sram (
    input  wire        clk,

    input  wire        write_en,
    input  wire [1:0]  write_bank,
    input  wire [13:0] write_addr,
    input  wire [7:0]  write_data,

    input  wire        read_en,
    input  wire [7:0]  start_row,
    input  wire [7:0]  start_col,

    output reg  [23:0] cnn_data,
    output reg         out_valid,

    output wire [1:0]  bank0,
    output wire [1:0]  bank1,
    output wire [1:0]  bank2,

    output wire [13:0] addr0,
    output wire [13:0] addr1,
    output wire [13:0] addr2,

    output wire [7:0]  pixel0,
    output wire [7:0]  pixel1,
    output wire [7:0]  pixel2
);

    // =========================================================
    // 64 KB SRAM
    // 4 banks x 16 KB
    // =========================================================

    reg [7:0] mem [0:65535];

    // =========================================================
    // WRITE
    //
    // Physical address:
    // bank 0 -> 0x0000 - 0x3FFF
    // bank 1 -> 0x4000 - 0x7FFF
    // bank 2 -> 0x8000 - 0xBFFF
    // bank 3 -> 0xC000 - 0xFFFF
    // =========================================================

    wire [15:0] write_phys_addr;

    assign write_phys_addr =
        {write_bank, write_addr};

    always @(posedge clk) begin
        if (write_en)
            mem[write_phys_addr] <= write_data;
    end

    // =========================================================
    // THREE-PIXEL CNN WINDOW
    //
    // Pixel 0 = (start_row, start_col)
    // Pixel 1 = (start_row, start_col+1)
    // Pixel 2 = (start_row, start_col+2)
    // =========================================================

    wire [8:0] col0;
    wire [8:0] col1;
    wire [8:0] col2;

    assign col0 = {1'b0,start_col};
    assign col1 = {1'b0,start_col} + 9'd1;
    assign col2 = {1'b0,start_col} + 9'd2;

    // =========================================================
    // STAGGERED BANK SELECTION
    //
    // column 0 -> bank 0
    // column 1 -> bank 1
    // column 2 -> bank 2
    // column 3 -> bank 3
    // column 4 -> bank 0
    // ...
    // =========================================================

    assign bank0 = col0[1:0];
    assign bank1 = col1[1:0];
    assign bank2 = col2[1:0];

    // =========================================================
    // LOCAL ADDRESS INSIDE EACH BANK
    //
    // 256 rows x 64 bytes
    //
    // address = row*64 + column/4
    // =========================================================

    assign addr0 =
        (start_row << 6) + col0[8:2];

    assign addr1 =
        (start_row << 6) + col1[8:2];

    assign addr2 =
        (start_row << 6) + col2[8:2];

    // =========================================================
    // PHYSICAL ADDRESSES
    // =========================================================

    wire [15:0] phys0;
    wire [15:0] phys1;
    wire [15:0] phys2;

    assign phys0 = {bank0,addr0};
    assign phys1 = {bank1,addr1};
    assign phys2 = {bank2,addr2};

    // =========================================================
    // READ PIXELS
    // =========================================================

    assign pixel0 = mem[phys0];
    assign pixel1 = mem[phys1];
    assign pixel2 = mem[phys2];

    // =========================================================
    // 24-BIT OUTPUT
    // =========================================================

    always @(posedge clk) begin

        if (read_en) begin
            cnn_data  <= {pixel0,pixel1,pixel2};
            out_valid <= 1'b1;
        end
        else begin
            cnn_data  <= 24'h000000;
            out_valid <= 1'b0;
        end

    end

endmodule