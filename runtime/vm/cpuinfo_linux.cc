// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_LINUX)

#include "vm/cpuid.h"
#include "vm/cpuinfo.h"
#include "vm/proccpuinfo.h"

#include "platform/assert.h"

// As with Windows, on IA32 and X64, we use the cpuid instruction.
// The analogous instruction is privileged on ARM, so we resort to
// reading from /proc/cpuinfo.

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  fields_[kCpuInfoProcessor] = "vendor_id";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "model name";
  fields_[kCpuInfoFeatures] = "flags";
  fields_[kCpuInfoArchitecture] = "CPU architecture";
  method_ = kCpuInfoCpuId;
  CpuId::InitOnce();
#elif defined(HOST_ARCH_ARM)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
  fields_[kCpuInfoArchitecture] = "CPU architecture";
  method_ = kCpuInfoSystem;
  ProcCpuInfo::InitOnce();
#elif defined(HOST_ARCH_ARM64)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "CPU implementer";
  fields_[kCpuInfoHardware] = "CPU implementer";
  fields_[kCpuInfoFeatures] = "Features";
  fields_[kCpuInfoArchitecture] = "CPU architecture";
  method_ = kCpuInfoSystem;
  ProcCpuInfo::InitOnce();
#else
#error Unrecognized target architecture
#endif
}

void CpuInfo::Cleanup() {
  if (method_ == kCpuInfoCpuId) {
    CpuId::Cleanup();
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    ProcCpuInfo::Cleanup();
  }
}

bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  if (method_ == kCpuInfoCpuId) {
    const char* field = CpuId::field(idx);
    bool contains = (strstr(field, search_string) != NULL);
    free(const_cast<char*>(field));
    return contains;
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::FieldContains(FieldName(idx), search_string);
  }
}

const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  if (method_ == kCpuInfoCpuId) {
    return CpuId::field(idx);
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::ExtractField(FieldName(idx));
  }
}

bool CpuInfo::HasField(const char* field) {
  if (method_ == kCpuInfoCpuId) {
    return (strcmp(field, fields_[kCpuInfoProcessor]) == 0) ||
           (strcmp(field, fields_[kCpuInfoModel]) == 0) ||
           (strcmp(field, fields_[kCpuInfoHardware]) == 0) ||
           (strcmp(field, fields_[kCpuInfoFeatures]) == 0);
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::HasField(field);
  }
}

}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
