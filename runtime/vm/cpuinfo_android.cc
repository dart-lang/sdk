// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_ANDROID)

#include "vm/cpuinfo.h"
#include "vm/proccpuinfo.h"

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {};

void CpuInfo::Init() {
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  fields_[kCpuInfoProcessor] = "vendor_id";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "model name";
  fields_[kCpuInfoFeatures] = "flags";
  fields_[kCpuInfoArchitecture] = "CPU architecture";
  method_ = kCpuInfoSystem;
  ProcCpuInfo::Init();
#elif defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
  fields_[kCpuInfoArchitecture] = "CPU architecture";
  method_ = kCpuInfoSystem;
  ProcCpuInfo::Init();
#elif defined(HOST_ARCH_RISCV64)
  // We only rely on the base Linux configuration of IMAFDC, so don't need
  // dynamic feature detection.
  method_ = kCpuInfoNone;
#else
#error Unrecognized target architecture
#endif
}

void CpuInfo::Cleanup() {
  if (method_ == kCpuInfoSystem) {
    ProcCpuInfo::Cleanup();
  } else {
    ASSERT(method_ == kCpuInfoNone);
  }
}

bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  if (method_ == kCpuInfoSystem) {
    return ProcCpuInfo::FieldContains(FieldName(idx), search_string);
  } else {
    UNREACHABLE();
  }
}

const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  if (method_ == kCpuInfoSystem) {
    return ProcCpuInfo::ExtractField(FieldName(idx));
  } else {
    UNREACHABLE();
  }
}

bool CpuInfo::HasField(const char* field) {
  if (method_ == kCpuInfoSystem) {
    return ProcCpuInfo::HasField(field);
  } else if (method_ == kCpuInfoNone) {
    return false;
  } else {
    UNREACHABLE();
  }
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID)
