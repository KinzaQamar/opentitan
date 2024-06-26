// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module clkgen_xil_ultrascale # (
  // Add BUFG if not done by downstream logic
  parameter bit AddClkBuf = 1
) (
  input  clk_i,
  input  rst_ni,
  output clk_main_o,
  output clk_io_o,
  output clk_48MHz_o,
  output clk_aon_o,
  output rst_no
);
  logic locked_pll;
  logic io_clk_buf;
  logic io_rst_buf_n;
  logic clk_main_buf;
  logic clk_main_unbuf;
  logic clk_io_buf;
  logic clk_io_unbuf;
  logic clk_fb_buf;
  logic clk_fb_unbuf;
  logic clk_48_buf;
  logic clk_48_unbuf;
  logic clk_aon_buf;
  logic clk_aon_unbuf;

  MMCME2_ADV #(
    .BANDWIDTH            ("OPTIMIZED"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .CLKIN1_PERIOD        (10.000), // f_CLKIN = 100 MHz
    .DIVCLK_DIVIDE        (1),      // f_PFD = 100 MHz
    .CLKFBOUT_MULT_F      (12.000), // f_VCO = 1200 MHz
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE_F     (50.0),   // f_sys = 24 MHz
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (25),     // f_usb = 48 MHz
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT2_DIVIDE       (50.0),   // f_io  = 24 MHz
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    // With CLKOUT4_CASCADE, CLKOUT6's divider is an input to CLKOUT4's
    // divider. The effective ratio is a multiplication of the two.
    .CLKOUT4_DIVIDE       (40),     // f_aon_pre = 30 MHz
    .CLKOUT4_PHASE        (0.000),
    .CLKOUT4_DUTY_CYCLE   (0.500),
    .CLKOUT4_CASCADE      ("TRUE"),
    .CLKOUT6_DIVIDE       (120)     // f_aon = 250 kHz
  ) pll (
    .CLKFBOUT            (clk_fb_unbuf),
    .CLKFBOUTB           (),
    .CLKOUT0             (clk_main_unbuf),
    .CLKOUT0B            (),
    .CLKOUT1             (clk_48_unbuf),
    .CLKOUT1B            (),
    .CLKOUT2             (clk_io_unbuf),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (clk_aon_unbuf),
    .CLKOUT5             (),
    .CLKOUT6             (),
     // Input clock control
    .CLKFBIN             (clk_fb_buf),
    .CLKIN1              (clk_i),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (),
    .DRDY                (),
    .DWE                 (1'b0),
    // Phase shift signals
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (),
    // Other control and status signals
    .CLKFBSTOPPED        (),
    .CLKINSTOPPED        (),
    .LOCKED              (locked_pll),
    .PWRDWN              (1'b0),
    // Do not reset MMCM on external reset, otherwise ILA disconnects at a reset
    .RST                 (1'b0));

  // output buffering
  BUFG clk_fb_bufg (
    .I (clk_fb_unbuf),
    .O (clk_fb_buf)
  );

  if (AddClkBuf == 1) begin : gen_clk_bufs
    BUFG clk_aon_bufg (
      .I (clk_aon_unbuf),
      .O (clk_aon_buf)
    );

    BUFG clk_main_bufg (
      .I (clk_main_unbuf),
      .O (clk_main_buf)
    );

    BUFG clk_io_bufg (
      .I (clk_io_unbuf),
      .O (clk_io_buf)
    );

    BUFG clk_48_bufg (
      .I (clk_48_unbuf),
      .O (clk_48_buf)
    );
  end else begin : gen_no_clk_bufs
    // BUFGs added by downstream modules, no need to add here
    assign clk_aon_buf = clk_aon_unbuf;
    assign clk_main_buf = clk_main_unbuf;
    assign clk_io_buf = clk_io_unbuf;
    assign clk_48_buf = clk_48_unbuf;
  end

  // outputs
  // clock
  assign clk_main_o = clk_main_buf;
  assign clk_io_o = clk_io_buf;
  assign clk_48MHz_o = clk_48_buf;
  assign clk_aon_o = clk_aon_buf;

  // reset
  assign rst_no = locked_pll & rst_ni;
endmodule
