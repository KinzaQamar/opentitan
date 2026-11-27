// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This interface connects the UVM environment to the keymgr_dpe DUT.
interface keymgr_dpe_if #(parameter int unsigned NUM_ROM_DIGESTS = 1)
(
  input clk_i,
  input rst_ni
);

  import lc_ctrl_pkg::lc_tx_t;
  import lc_ctrl_pkg::lc_keymgr_div_t;
  import rom_ctrl_pkg::keymgr_data_t;
  import keymgr_dpe_pkg::*;

  wire hw_key_req_t aes_key;

  // kmac_key_o contains the parent key when keymgr_dpe sends a request to KMAC during Advance or
  // Generate HW / SW Output operations. Otherwise it contains the sideload key.
  wire hw_key_req_t      kmac_key;
  wire wide_hw_key_req_t hmac_key;

  // otbn_key_o contains the parent key when keymgr_dpe sends a request to OTBN during Advance or
  // Generate HW / SW Output operations. Otherwise it contains the sideload key.
  wire wide_hw_key_req_t otbn_key;

  // LC interface to enable / disable keymgr_dpe.
  wire lc_tx_t         lc_keymgr_en;
  wire lc_keymgr_div_t lc_keymgr_div;

  // Root keys.
  wire keymgr_dpe_creator_root_key_t creator_root_key;
  wire keymgr_dpe_creator_root_key_t secondary_root_key;

  // Utilized as HW bindings in the KDF message argument (child_key = KDF(parent_key, message)).
  wire keymgr_dpe_creator_seed_t           creator_seed;
  wire keymgr_dpe_owner_seed_t             owner_seed;
  wire keymgr_dpe_device_id_t              device_id;
  wire keymgr_dpe_field_entropy_t          field_entropy;
  wire keymgr_data_t [NUM_ROM_DIGESTS-1:0] rom_digest;

  // The driver drives these *_internal signals in a block-level simulation. They are needed because
  // wires cannot be driven procedurally. The assigns below pass them on to the wires when the
  // interface is active, and release the wires (drive 'z) when it is passive.
  lc_tx_t         lc_keymgr_en_internal;
  lc_keymgr_div_t lc_keymgr_div_internal;

  keymgr_dpe_creator_root_key_t creator_root_key_internal;
  keymgr_dpe_creator_root_key_t secondary_root_key_internal;

  keymgr_dpe_creator_seed_t           creator_seed_internal;
  keymgr_dpe_owner_seed_t             owner_seed_internal;
  keymgr_dpe_device_id_t              device_id_internal;
  keymgr_dpe_field_entropy_t          field_entropy_internal;
  keymgr_data_t [NUM_ROM_DIGESTS-1:0] rom_digest_internal;

  // To use this interface in both top-level and block-level simulations, this is_active bit is
  // needed. The block-level environment assigns this bit. The top-level environment can leave it
  // unassigned, so the interface stays passive.
  bit is_active;

  assign lc_keymgr_en       = (is_active)? lc_keymgr_en_internal       :
                                           lc_tx_t'('z);
  assign lc_keymgr_div      = (is_active)? lc_keymgr_div_internal      :
                                           lc_keymgr_div_t'('z);
  assign creator_root_key   = (is_active)? creator_root_key_internal   :
                                           keymgr_dpe_creator_root_key_t'('z);
  assign secondary_root_key = (is_active)? secondary_root_key_internal :
                                           keymgr_dpe_creator_root_key_t'('z);
  assign creator_seed       = (is_active)? creator_seed_internal       :
                                           keymgr_dpe_creator_seed_t'('z);
  assign owner_seed         = (is_active)? owner_seed_internal         :
                                           keymgr_dpe_owner_seed_t'('z);
  assign device_id          = (is_active)? device_id_internal          :
                                           keymgr_dpe_device_id_t'('z);
  assign field_entropy      = (is_active)? field_entropy_internal      :
                                           keymgr_dpe_field_entropy_t'('z);
  assign rom_digest         = (is_active)? rom_digest_internal         :
                                           keymgr_data_t'('z);

  // Clocking block for monitor.
  //
  // The inputs to keymgr_dpe are quasi-static, so there is no need to declare a separate
  // (driving) clocking block for them.
  clocking mon_cb @(posedge clk_i);
    input aes_key;
    input kmac_key;
    input hmac_key;
    input otbn_key;
    input lc_keymgr_en;
    input lc_keymgr_div;
    input creator_root_key;
    input secondary_root_key;
    input creator_seed;
    input owner_seed;
    input device_id;
    input field_entropy;
    input rom_digest;
  endclocking

endinterface
