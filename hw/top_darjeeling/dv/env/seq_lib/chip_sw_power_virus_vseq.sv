// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class chip_sw_power_virus_vseq extends chip_sw_base_vseq;
  `uvm_object_utils(chip_sw_power_virus_vseq)

  `uvm_object_new

  virtual function int sw_symbol_backdoor_read32(string symbol);
    bit [7:0] byte_array[4];
    sw_symbol_backdoor_read(symbol, byte_array);
    return {<<byte{byte_array}};
  endfunction

  virtual task i2c_device_autoresponder(int i2c_idx);
    i2c_device_response_seq seq = i2c_device_response_seq::type_id::create("seq");
    fork seq.start(p_sequencer.i2c_sequencer_hs[i2c_idx]); join_none
  endtask

  // Utility task to configure the I2C agents
  virtual task configure_i2c_agents();
    bit [31:0] i2c_scl_period_ns;          // `kI2cSclPeriodNs` in SW
    bit [31:0] peripheral_clock_freq_hz;   // `kClockFreqPeripheralHz` in SW
    bit [31:0] peripheral_clock_period_ns; // `peripheral_clock_period_ns` in SW
    bit [31:0] half_cycles_in_i2c_period;
    // Hard-coded from `sw/top_darjeeling/sw/device/arch/device_sim_dv.c`.
    peripheral_clock_freq_hz = 24 * 1000 * 1000;
    peripheral_clock_period_ns = 1_000_000_000 / peripheral_clock_freq_hz;
    `uvm_info(`gfn, $sformatf("peripheral_clock_period_ns = %0d", peripheral_clock_period_ns),
      UVM_LOW);

    // Hard-coded from `sw/device/tests/power_virus_systemtest.c`.
    i2c_scl_period_ns = 1000;
    half_cycles_in_i2c_period = ((int'(i2c_scl_period_ns) / 2 - 1) /
      int'(peripheral_clock_period_ns)) + 1;
    `uvm_info(`gfn, $sformatf("Half (peripheral) cycles in I2C clock period: %d",
      half_cycles_in_i2c_period), UVM_LOW);

    foreach (cfg.m_i2c_agent_cfgs[i]) begin
      cfg.m_i2c_agent_cfgs[i].if_mode = Device;
      cfg.m_i2c_agent_cfgs[i].target_addr0 = i + 1;
      cfg.m_i2c_agent_cfgs[i].timing_cfg.tClockLow = half_cycles_in_i2c_period - 2;
      cfg.m_i2c_agent_cfgs[i].timing_cfg.tClockPulse = half_cycles_in_i2c_period + 1;
    end
  endtask

  // Utility task to send a SpiFlashReadQuad command to read 2048 bytes from
  // the spi_device_agent0. The expected read response is initialized to
  // an alternating pattern of 0xAA an Ox55 to maximize the toggling.
  virtual task execute_spi_flash_sequence();
    const int test_payload_size = 2048;
    bit [7:0] test_opcode = SpiFlashReadQuad;
    bit [7:0] rsp_fill_data;
    spi_device_flash_seq m_spi_device_seq;
    spi_host_flash_seq m_spi_host_seq;
    spi_item host_rsp, device_rsp;
    spi_item device_rsp_q[$];
    spi_agent_cfg agent_cfg = cfg.m_spi_host_agent_cfg;

    fork begin : isolation_fork
      // The device agent handles the incoming command.
      fork
        forever begin : send_spi_device_seq_forever
          `uvm_create_on(m_spi_device_seq, p_sequencer.spi_device_sequencer_hs[0]);
          // To maximize the toggling, fill the device agent's response queue
          // with an alternating pattern of 0xaa and 0x55.
          for (int ii = 0; ii < test_payload_size; ii = ii + 1) begin
            rsp_fill_data = (ii % 2 == 1) ? 8'haa : 8'h55;
            m_spi_device_seq.byte_data_q.push_back(rsp_fill_data);
          end
          `uvm_send(m_spi_device_seq);
          device_rsp_q.push_back(m_spi_device_seq.rsp);
        end

        // The host agent sends the command, receives the response, and
        // checks the result.
        begin : spi_host_thread
          `uvm_create_on(m_spi_host_seq, p_sequencer.spi_host_sequencer_h);
          // set the host sequence's parameters.
          m_spi_host_seq.opcode = test_opcode;
          m_spi_host_seq.read_size = test_payload_size;
          `uvm_info(`gfn, $sformatf("spi passthrough payload size = %0x",
                                    m_spi_host_seq.read_size), UVM_LOW);
          `uvm_send(m_spi_host_seq);
          // Wait for a small delay to allow the device agent to push the response
          // into the queue.
          #1ps;
          `uvm_info(`gfn, $sformatf("spi passthrough opcode = %0x",
                                    test_opcode), UVM_LOW);

          // Check that the command, address, and data sent matches on both sides.
          `DV_CHECK_EQ(device_rsp_q.size(), 1);
          host_rsp = m_spi_host_seq.rsp;
          device_rsp = device_rsp_q.pop_front();
          if (!host_rsp.compare(device_rsp)) begin
            `uvm_error(`gfn, $sformatf("Compare mismatch\nhost_rsp:\n%sdevice_rsp:\n%s",
                                        host_rsp.sprint(), device_rsp.sprint()))
          end
        end
      join_any
      disable fork;
    end join
  endtask

  // A local define to probe the state of an IP and to check if it is IDLE.
  `define _DV_PROBE_AND_CHECK_IDLE(SIGNAL_NAME, IDLE_VAL)                                         \
      SIGNAL_NAME = cfg.chip_vif.signal_probe_``SIGNAL_NAME``(SignalProbeSample);                 \
      `uvm_info(`gfn, $sformatf("%s = 0x%0x", `DV_STRINGIFY(SIGNAL_NAME), SIGNAL_NAME), UVM_LOW); \
      `DV_CHECK_NE(SIGNAL_NAME, IDLE_VAL);

  // A utility function to check the FSM states of the IPs.
  virtual task check_ip_activity();
    logic spi_device_cio_csb_i;
    logic spi_host_0_cio_csb_o;
    logic [csrng_pkg::MainSmStateWidth-1:0] csrng_main_fsm_state;
    logic [5:0] aes_ctrl_fsm_state;
    logic [2:0] hmac_fsm_state;
    logic [5:0] kmac_fsm_state;
    logic [6:0] otbn_fsm_state;
    logic [8:0] edn_0_fsm_state;
    logic [8:0] edn_1_fsm_state;

    // Wait for max-power indicator GPIO pin to go up.
    wait (cfg.chip_vif.dios[top_darjeeling_pkg::DioPadGpio0]);
    // Wait for 10 clock cycles.
    cfg.clk_rst_vif.wait_clks(10);

    `_DV_PROBE_AND_CHECK_IDLE(spi_device_cio_csb_i, 1'b1)
    `_DV_PROBE_AND_CHECK_IDLE(spi_host_0_cio_csb_o, 1'b1)
    `_DV_PROBE_AND_CHECK_IDLE(csrng_main_fsm_state, csrng_pkg::MainSmIdle)
    `_DV_PROBE_AND_CHECK_IDLE(aes_ctrl_fsm_state, aes_pkg::CTRL_IDLE)
    `_DV_PROBE_AND_CHECK_IDLE(hmac_fsm_state, 3'b000)
    `_DV_PROBE_AND_CHECK_IDLE(kmac_fsm_state, 6'b011000)
    `_DV_PROBE_AND_CHECK_IDLE(otbn_fsm_state, otbn_pkg::OtbnStartStopStateInitial)
    `_DV_PROBE_AND_CHECK_IDLE(edn_0_fsm_state, edn_pkg::Idle)
    `_DV_PROBE_AND_CHECK_IDLE(edn_1_fsm_state, edn_pkg::Idle)
  endtask

  task pre_start();
    // i2c_agent configs
    configure_i2c_agents();

    // Configs for SPI passthrough part of the test
    cfg.m_spi_device_agent_cfgs[0].byte_order = '0;
    // Set CSB inactive times to reasonable values. sys_clk is at 24 MHz, and
    // it needs to capture CSB pulses.
    cfg.m_spi_host_agent_cfg.min_idle_ns_after_csb_drop = 50;
    cfg.m_spi_host_agent_cfg.max_idle_ns_after_csb_drop = 200;
    spi_agent_configure_flash_cmds(cfg.m_spi_host_agent_cfg);
    spi_agent_configure_flash_cmds(cfg.m_spi_device_agent_cfgs[0]);
    // 'kClockFreqHiSpeedPeripheralHz / 2' in SW
    cfg.m_spi_host_agent_cfg.sck_period_ps = 48_000;
    super.pre_start();
  endtask

  virtual task body();
    // Turn off the FIFO data output assertion, as spi_device issues a read
    // before it knows whether it needs the data.
    $assertoff(0, "tb.dut.top_darjeeling.u_spi_device.u_readcmd.u_readsram.u_sram_fifo.DataKnown_A");
    $assertoff(0, "tb.dut.top_darjeeling.u_spi_device.u_readcmd.u_readsram.u_fifo.DataKnown_A");
    super.body();

    // Wait for configurations to be computed and max power epoch to start.
    `DV_WAIT(cfg.sw_logger_vif.printed_log == "Entering max power epoch ...");

    // Main fork-join block to handle IP-specific threads
    fork
      begin: i2c_agent_thread
        // Enable I2C monitors and sequences.
        foreach (cfg.m_i2c_agent_cfgs[i]) begin
          cfg.m_i2c_agent_cfgs[i].en_monitor = 1'b1;
          cfg.chip_vif.enable_i2c(.inst_num(i), .enable(1));
          i2c_device_autoresponder(i);
        end
      end

      begin : spi_passthrough_thread
        // Enable the spi agents.
        cfg.chip_vif.enable_spi_host = 1;
        cfg.chip_vif.enable_spi_device(.inst_num(0), .enable(1));
        // Send the command and check the response.
        execute_spi_flash_sequence();
      end

      begin : ip_activity_check_thread
        // Check if the IPs are active at the beginning of max power epoch.
        check_ip_activity();
      end
    join
  endtask
`undef _DV_PROBE_AND_CHECK_IDLE
endclass : chip_sw_power_virus_vseq
