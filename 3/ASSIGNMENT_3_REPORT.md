# Assignment 3: CNN Input SRAM Address Generation and Read Control

## 1. Objective

Design and verify the address-generation and read-control logic for the first CNN layer using a four-bank input SRAM, an 8-bit pixel interface, and a 24-bit output bus.

## 2. Design Specifications

- Input image: 256 x 256 pixels
- Pixel width: 8 bits
- SRAM organization: 4 banks
- Capacity per bank: 256 x 64 bytes = 16 KB
- Total SRAM capacity: 64 KB
- Read window: 3 adjacent horizontal pixels
- Output width: 24 bits

## 3. Address Generation

For row r and starting column c:

- Bank selection: bank(c) = c mod 4
- Local address: address(r,c) = 64r + floor(c/4)
- Physical address: 16384 x bank + local address

The three-pixel window accesses columns c, c+1, and c+2, using cyclic bank interleaving.

The local address ranges from 0 to 16383 for each bank.

## 4. Read Control

The address generator scans the image row by row. The SRAM read interface produces three 8-bit pixels, combined into a 24-bit output word. The valid signal indicates when the output is valid.

## 5. Verification Results

### Address generation
- Address boundary checks: PASS
- Address mapping checks: PASS
- Full-scan testbench: 65023 windows observed; expected 65024.
  This testbench count discrepancy remains unresolved. Point checks passed.

### Input SRAM
- Full-image verification: PASS
- Pixels written: 65536
- Windows tested: 65534
- Data checks: 65534
- Errors: 0

### SRAM read integration
- Four read-data checks: PASS
- Expected 24-bit outputs matched actual outputs.

### Weight controller
- Nine kernel weight writes observed.
- Scan completion asserted.
- Controller test: PASS

## 6. Limitations

The verified work covers SRAM storage, address generation, three-pixel read control, and the weight controller. A complete CNN convolution datapath and end-to-end convolution result are not claimed by these tests.

## 7. Conclusion

The SRAM full-image test and read-integration test passed. Address-generation boundary and point checks passed. The full-scan testbench has a one-window count discrepancy that should be resolved before claiming complete full-scan verification.
