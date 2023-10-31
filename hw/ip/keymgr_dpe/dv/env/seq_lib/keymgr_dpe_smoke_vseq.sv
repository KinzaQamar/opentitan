// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// smoke test vseq
class keymgr_dpe_smoke_vseq extends keymgr_dpe_base_vseq;
  `uvm_object_utils(keymgr_dpe_smoke_vseq)
  `uvm_object_new

  // limit to SW operations
  constraint gen_operation_c {
    gen_operation inside {keymgr_dpe_pkg::OpDpeGenId, keymgr_dpe_pkg::OpDpeGenSwOut};
  }

  task body();
    keymgr_dpe_pkg::keymgr_dpe_exposed_working_state_e state;
    `uvm_info(`gfn, "Key manager dpe seq start", UVM_HIGH)
    // Advance from StReset to last state StDisabled and advance one extra time,
    // then it should stay at StDisabled
    // In each state check SW/HW output
    repeat (state.num() + 1) begin
      keymgr_dpe_operations(.advance_state(1), .num_gen_op(1), .clr_output(1));
    end

  endtask : body

endclass : keymgr_dpe_smoke_vseq