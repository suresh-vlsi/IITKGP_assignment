`timescale 1ns/1ps

module tb_sram_4banks;

    logic        clk;
    logic        we;
    logic        re;
    logic [13:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic [1:0]  bank_sel;

    integer i;
    integer errors;

    logic [13:0] test_addr [0:3];
    logic [31:0] test_data [0:3];

    // =========================================================
    // DUT
    // =========================================================

    sram_4banks dut (
        .clk      (clk),
        .we       (we),
        .re       (re),
        .addr     (addr),
        .wdata     (wdata),
        .rdata     (rdata),
        .bank_sel (bank_sel)
    );

    // =========================================================
    // CLOCK
    // =========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("sram_4banks.vcd");
        $dumpvars(0, tb_sram_4banks);

        we    = 1'b0;
        re    = 1'b0;
        addr  = 14'd0;
        wdata = 32'd0;

        errors = 0;

        // =====================================================
        // ONE LOCATION IN EACH BANK
        //
        // Same row and word position:
        //
        // Bank 0 -> 0x0005
        // Bank 1 -> 0x1005
        // Bank 2 -> 0x2005
        // Bank 3 -> 0x3005
        // =====================================================

        test_addr[0] = 14'h0005;
        test_addr[1] = 14'h1005;
        test_addr[2] = 14'h2005;
        test_addr[3] = 14'h3005;

        test_data[0] = 32'h11111111;
        test_data[1] = 32'h22222222;
        test_data[2] = 32'h33333333;
        test_data[3] = 32'h44444444;

        #10;

        // =====================================================
        // WRITE
        // =====================================================

        $display("");
        $display("==============================================");
        $display("       Q2(ii) FOUR-BANK SRAM WRITE");
        $display("==============================================");

        we = 1'b1;
        re = 1'b0;

        for (i = 0; i < 4; i = i + 1) begin

            @(negedge clk);

            addr  = test_addr[i];
            wdata = test_data[i];

            @(posedge clk);

            #1;

            $display(
                "WRITE | bank=%0d | addr=0x%04h | row=%0d | word=%0d | data=0x%08h",
                bank_sel,
                addr,
                addr[11:4],
                addr[3:0],
                wdata
            );

        end

        @(negedge clk);

        we = 1'b0;

        // =====================================================
        // READ AND VERIFY
        // =====================================================

        $display("");
        $display("==============================================");
        $display("       Q2(ii) FOUR-BANK SRAM READ");
        $display("==============================================");

        re = 1'b1;

        for (i = 0; i < 4; i = i + 1) begin

            @(negedge clk);

            addr = test_addr[i];

            #1;

            if (rdata === test_data[i]) begin

                $display(
                    "READ  | bank=%0d | addr=0x%04h | expected=0x%08h | actual=0x%08h | PASS",
                    bank_sel,
                    addr,
                    test_data[i],
                    rdata
                );

            end
            else begin

                $display(
                    "READ  | bank=%0d | addr=0x%04h | expected=0x%08h | actual=0x%08h | FAIL",
                    bank_sel,
                    addr,
                    test_data[i],
                    rdata
                );

                errors = errors + 1;

            end

        end

        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("       ASSIGNMENT 2(ii) TEST PASSED");
            $display("       ALL 4 BANKS VERIFIED");

        end
        else begin

            $display("       ASSIGNMENT 2(ii) TEST FAILED");
            $display("       ERRORS = %0d", errors);

        end

        $display("==============================================");
        $display("");

        re = 1'b0;

        #20;

        $finish;

    end

endmodule