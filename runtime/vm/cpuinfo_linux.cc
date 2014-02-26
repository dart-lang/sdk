// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_LINUX)

#include "vm/cpuinfo.h"
#include "vm/cpuid.h"
#include "vm/proccpuinfo.h"

#include "platform/assert.h"

// As with Windows, on IA32 and X64, we use the cpuid instruction.
// The analogous instruction is privileged on ARM and MIPS, so we resort to
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
  method_ = kCpuInfoCpuId;
  CpuId::InitOnce();
#elif defined(HOST_ARCH_ARM)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "Hardware";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
  method_ = kCpuInfoSystem;
  ProcCpuInfo::InitOnce();
#elif defined(HOST_ARCH_MIPS)
  fields_[kCpuInfoProcessor] = "system type";
  fields_[kCpuInfoModel] = "cpu model";
  fields_[kCpuInfoHardware] = "cpu model";
  fields_[kCpuInfoFeatures] = "ASEs implemented";
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
    return strstr(CpuId::field(idx), search_string);
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::FieldContains(FieldName(idx), search_string);
  }
}


bool CpuInfo::FieldContainsByString(const char* field,
                                    const char* search_string) {
  if (method_ == kCpuInfoCpuId) {
    for (int i = 0; i < kCpuInfoMax; i++) {
      if (strcmp(field, fields_[i]) == 0) {
        return FieldContains(static_cast<CpuInfoIndices>(i), search_string);
      }
    }
    UNIMPLEMENTED();
    return false;
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::FieldContains(field, search_string);
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


const char* CpuInfo::ExtractFieldByString(const char* field) {
  if (method_ == kCpuInfoCpuId) {
    for (int i = 0; i < kCpuInfoMax; i++) {
      if (strcmp(field, fields_[i]) == 0) {
        return ExtractField(static_cast<CpuInfoIndices>(i));
      }
    }
    UNIMPLEMENTED();
    return NULL;
  } else {
    ASSERT(method_ == kCpuInfoSystem);
    return ProcCpuInfo::ExtractField(field);
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

#endif  // defined(TARGET_OS_LINUX)
