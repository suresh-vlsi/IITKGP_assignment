`timescale 1ns/1ps

module tb_sram_64kb;

    logic        clk;
    logic        we;
    logic        re;
    logic [13:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    integer i;
    integer errors;

    // ---------------------------------------------------------
    // Test addresses
    // ---------------------------------------------------------

    logic [13:0] test_addr [0:7];
    logic [31:0] test_data [0:7];

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------

    sram_64kb dut (
        .clk   (clk),
        .we    (we),
        .re    (re),
        .addr  (addr),
        .wdata (wdata),
        .rdata (rdata)
    );

    // ---------------------------------------------------------
    // Clock
    // ---------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ---------------------------------------------------------
    // Test
    // ---------------------------------------------------------

    initial begin

        $dumpfile("sram_64kb.vcd");
        $dumpvars(0, tb_sram_64kb);

        we = 1'b0;
        re = 1'b0;
        addr = 14'd0;
        wdata = 32'd0;

        errors = 0;

        // -----------------------------------------------------
        // Eight test locations
        // -----------------------------------------------------

        test_addr[0] = 14'd0;
        test_addr[1] = 14'd1;
        test_addr[2] = 14'd15;
        test_addr[3] = 14'd16;
        test_addr[4] = 14'd100;
        test_addr[5] = 14'd1023;
        test_addr[6] = 14'd4095;
        test_addr[7] = 14'd16383;

        test_data[0] = 32'hA5A50001;
        test_data[1] = 32'hA5A50002;
        test_data[2] = 32'hA5A50003;
        test_data[3] = 32'hA5A50004;
        test_data[4] = 32'hA5A50005;
        test_data[5] = 32'hA5A50006;
        test_data[6] = 32'hA5A50007;
        test_data[7] = 32'hA5A50008;

        // -----------------------------------------------------
        // RESET / INITIALIZATION
        // -----------------------------------------------------

        #10;

        // =====================================================
        // WRITE 8 LOCATIONS
        // =====================================================

        $display("");
        $display("==============================================");
        $display("       Q2(i) SRAM WRITE OPERATION");
        $display("==============================================");

        we = 1'b1;
        re = 1'b0;

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge clk);

            addr  = test_addr[i];
            wdata = test_data[i];

            @(posedge clk);

            #1;

            $display(
                "WRITE | addr=%0d | row=%0d | word=%0d | data=0x%08h",
                addr,
                addr >> 4,
                addr & 14'h000F,
                wdata
            );

        end

        // Stop writing
        @(negedge clk);

        we = 1'b0;

        // =====================================================
        // READ AND VERIFY 8 LOCATIONS
        // =====================================================

        $display("");
        $display("==============================================");
        $display("       Q2(i) SRAM READ / VERIFY");
        $display("==============================================");

        re = 1'b1;

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge clk);

            addr = test_addr[i];

            #1;

            if (rdata === test_data[i]) begin

                $display(
                    "READ  | addr=%0d | expected=0x%08h | actual=0x%08h | PASS",
                    addr,
                    test_data[i],
                    rdata
                );

            end
            else begin

                $display(
                    "READ  | addr=%0d | expected=0x%08h | actual=0x%08h | FAIL",
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

            $display("       ASSIGNMENT 2(i) TEST PASSED");
            $display("       64 KB CONSOLIDATED SRAM");
            $display("       8 LOCATIONS VERIFIED");

        end
        else begin

            $display("       ASSIGNMENT 2(i) TEST FAILED");
            $display("       ERRORS = %0d", errors);

        end

        $display("==============================================");
        $display("");

        re = 1'b0;

        #20;

        $finish;

    end

endmodule