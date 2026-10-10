
`timescale 1ns/1ps

module cnn_address_generator #(
    parameter [7:0] LAST_ROW = 8'd255,
    parameter [7:0] LAST_COL = 8'd253
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    output wire        read_en,
    output reg  [7:0]  row,
    output reg  [7:0]  col,
    output reg         scan_done,

    output wire [1:0]  bank0,
    output wire [1:0]  bank1,
    output wire [1:0]  bank2,

    output wire [13:0] addr0,
    output wire [13:0] addr1,
    output wire [13:0] addr2
);

    reg active;

    wire [7:0] col1;
    wire [7:0] col2;

    // A 3-pixel horizontal window must remain within one row.
    assign col1 = col + 8'd1;
    assign col2 = col + 8'd2;

    assign read_en = active;

    // Cyclic interleaving: column modulo 4 selects the bank.
    assign bank0 = col[1:0];
    assign bank1 = col1[1:0];
    assign bank2 = col2[1:0];

    // Local byte address = row*64 + column/4.
    assign addr0 = {row, 6'b0} + {6'b0, col[7:2]};
    assign addr1 = {row, 6'b0} + {6'b0, col1[7:2]};
    assign addr2 = {row, 6'b0} + {6'b0, col2[7:2]};

    always @(posedge clk) begin
        if (!rst_n) begin
            active    <= 1'b0;
            row       <= 8'd0;
            col       <= 8'd0;
            scan_done <= 1'b0;
        end
        else begin
            scan_done <= 1'b0;

            if (!active) begin
                if (start) begin
                    row    <= 8'd0;
                    col    <= 8'd0;
                    active <= 1'b1;
                end
            end
            else begin
                if (col < LAST_COL) begin
                    col <= col + 8'd1;
                end
                else if (row < LAST_ROW) begin
                    col <= 8'd0;
                    row <= row + 8'd1;
                end
                else begin
                    active    <= 1'b0;
                    scan_done <= 1'b1;
                end
            end
        end
    end

endmodule
