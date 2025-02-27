// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This file was autogenerated by `//sw/host/hsmtool/scripts/pkcs11_consts.py`.
// Do not edit.'

use cryptoki_sys::*;
use std::convert::TryFrom;

use crate::util::attribute::{AttrData, AttributeError};

#[derive(
    Clone,
    Copy,
    Debug,
    PartialEq,
    Eq,
    Hash,
    serde::Serialize,
    serde::Deserialize,
    strum::Display,
    strum::EnumString,
    strum::EnumIter,
    strum::FromRepr,
)]
#[repr(u64)]
pub enum ObjectClass {
    #[serde(rename = "CKO_DATA")]
    #[strum(serialize = "CKO_DATA", serialize = "Data", serialize = "data")]
    Data = CKO_DATA,
    #[serde(rename = "CKO_CERTIFICATE")]
    #[strum(
        serialize = "CKO_CERTIFICATE",
        serialize = "Certificate",
        serialize = "certificate"
    )]
    Certificate = CKO_CERTIFICATE,
    #[serde(rename = "CKO_PUBLIC_KEY")]
    #[strum(
        serialize = "CKO_PUBLIC_KEY",
        serialize = "PublicKey",
        serialize = "public_key"
    )]
    PublicKey = CKO_PUBLIC_KEY,
    #[serde(rename = "CKO_PRIVATE_KEY")]
    #[strum(
        serialize = "CKO_PRIVATE_KEY",
        serialize = "PrivateKey",
        serialize = "private_key"
    )]
    PrivateKey = CKO_PRIVATE_KEY,
    #[serde(rename = "CKO_SECRET_KEY")]
    #[strum(
        serialize = "CKO_SECRET_KEY",
        serialize = "SecretKey",
        serialize = "secret_key"
    )]
    SecretKey = CKO_SECRET_KEY,
    #[serde(rename = "CKO_HW_FEATURE")]
    #[strum(
        serialize = "CKO_HW_FEATURE",
        serialize = "HwFeature",
        serialize = "hw_feature"
    )]
    HwFeature = CKO_HW_FEATURE,
    #[serde(rename = "CKO_DOMAIN_PARAMETERS")]
    #[strum(
        serialize = "CKO_DOMAIN_PARAMETERS",
        serialize = "DomainParameters",
        serialize = "domain_parameters"
    )]
    DomainParameters = CKO_DOMAIN_PARAMETERS,
    #[serde(rename = "CKO_MECHANISM")]
    #[strum(
        serialize = "CKO_MECHANISM",
        serialize = "Mechanism",
        serialize = "mechanism"
    )]
    Mechanism = CKO_MECHANISM,
    #[serde(rename = "CKO_OTP_KEY")]
    #[strum(serialize = "CKO_OTP_KEY", serialize = "OtpKey", serialize = "otp_key")]
    OtpKey = CKO_OTP_KEY,
    #[serde(rename = "CKO_PROFILE")]
    #[strum(
        serialize = "CKO_PROFILE",
        serialize = "Profile",
        serialize = "profile"
    )]
    Profile = CKO_PROFILE,
    #[serde(rename = "CKO_VENDOR_DEFINED")]
    #[strum(
        serialize = "CKO_VENDOR_DEFINED",
        serialize = "VendorDefined",
        serialize = "vendor_defined"
    )]
    VendorDefined = CKO_VENDOR_DEFINED,
    UnknownObjectClass = u64::MAX,
}

impl From<u64> for ObjectClass {
    fn from(val: u64) -> Self {
        ObjectClass::from_repr(val).unwrap_or(ObjectClass::UnknownObjectClass)
    }
}

impl From<ObjectClass> for u64 {
    fn from(val: ObjectClass) -> u64 {
        val as u64
    }
}

impl From<cryptoki::object::ObjectClass> for ObjectClass {
    fn from(val: cryptoki::object::ObjectClass) -> Self {
        let val = CK_OBJECT_CLASS::from(val);
        Self::from(val)
    }
}

impl TryFrom<ObjectClass> for cryptoki::object::ObjectClass {
    type Error = cryptoki::error::Error;
    fn try_from(val: ObjectClass) -> Result<Self, Self::Error> {
        let val = CK_OBJECT_CLASS::from(val);
        cryptoki::object::ObjectClass::try_from(val)
    }
}

impl TryFrom<&AttrData> for ObjectClass {
    type Error = AttributeError;
    fn try_from(val: &AttrData) -> Result<Self, Self::Error> {
        match val {
            AttrData::ObjectClass(x) => Ok(*x),
            _ => Err(AttributeError::EncodingError),
        }
    }
}

impl From<ObjectClass> for AttrData {
    fn from(val: ObjectClass) -> Self {
        AttrData::ObjectClass(val)
    }
}
