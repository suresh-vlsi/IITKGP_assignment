
`timescale 1ns/1ps

module cnn_weight_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,

    output reg        wt_wr_en,
    output reg [3:0]  wt_addr,
    output reg [7:0]  wt_data,
    output reg        scan_done,
    output reg [1:0]  state
);

    localparam IDLE = 2'd0;
    localparam LOAD = 2'd1;
    localparam DONE = 2'd2;

    reg [3:0] count;

    // Example 3x3 kernel:
    //  1  0 -1
    //  1  0 -1
    //  1  0 -1
    function [7:0] kernel_value;
        input [3:0] index;
        begin
            case (index)
                0: kernel_value = 8'd1;
                1: kernel_value = 8'd0;
                2: kernel_value = -8'sd1;
                3: kernel_value = 8'd1;
                4: kernel_value = 8'd0;
                5: kernel_value = -8'sd1;
                6: kernel_value = 8'd1;
                7: kernel_value = 8'd0;
                8: kernel_value = -8'sd1;
                default: kernel_value = 8'd0;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            count     <= 0;
            wt_wr_en  <= 0;
            wt_addr   <= 0;
            wt_data   <= 0;
            scan_done <= 0;
        end
        else begin
            // Default: write enable and done are pulses.
            wt_wr_en  <= 0;
            scan_done <= 0;

            case (state)
                IDLE: begin
                    count <= 0;

                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    wt_wr_en <= 1;
                    wt_addr  <= count;
                    wt_data  <= kernel_value(count);

                    if (count == 8) begin
                        state <= DONE;
                    end
                    else begin
                        count <= count + 1'b1;
                    end
                end

                DONE: begin
                    scan_done <= 1;

                    if (!start)
                        state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    count <= 0;
                end
            endcase
        end
    end

endmodule
