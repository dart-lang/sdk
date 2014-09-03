// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "vm/cpuinfo.h"
#include "vm/proccpuinfo.h"

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
  // Initialize our read from /proc/cpuinfo.
  method_ = kCpuInfoSystem;
  ProcCpuInfo::InitOnce();

#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  fields_[kCpuInfoProcessor] = "vendor_id";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "model name";
  fields_[kCpuInfoFeatures] = "flags";
#elif defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
#elif defined(HOST_ARCH_MIPS)
  fields_[kCpuInfoProcessor] = "system type";
  fields_[kCpuInfoModel] = "cpu model";
  fields_[kCpuInfoHardware] = "cpu model";
  fields_[kCpuInfoFeatures] = "ASEs implemented";
#else
#error Unrecognized target architecture
#endif
}


void CpuInfo::Cleanup() {
  ProcCpuInfo::Cleanup();
}


bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  ASSERT(method_ != kCpuInfoDefault);
  return ProcCpuInfo::FieldContains(FieldName(idx), search_string);
}


bool CpuInfo::FieldContainsByString(const char* field,
                                    const char* search_string) {
  ASSERT(method_ != kCpuInfoDefault);
  return ProcCpuInfo::FieldContains(field, search_string);
}


const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  ASSERT(method_ != kCpuInfoDefault);
  return ProcCpuInfo::ExtractField(FieldName(idx));
}


const char* CpuInfo::ExtractFieldByString(const char* field) {
  ASSERT(method_ != kCpuInfoDefault);
  return ProcCpuInfo::ExtractField(field);
}


bool CpuInfo::HasField(const char* field) {
  ASSERT(method_ != kCpuInfoDefault);
  return ProcCpuInfo::HasField(field);
}

}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
