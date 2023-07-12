// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "vm/cpuid.h"
#include "vm/cpuinfo.h"

// __cpuid()
#include <intrin.h>  // NOLINT
#include <string.h>  // NOLINT

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {};

void CpuInfo::Init() {
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  method_ = kCpuInfoCpuId;

  // Initialize the CpuId information.
  CpuId::Init();

  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "Hardware";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
  fields_[kCpuInfoArchitecture] = nullptr;
#elif defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
  // We only rely on the base ARM64 version, so we don't need dynamic feature
  // detection.
  method_ = kCpuInfoNone;
#else
#error Unrecognized target architecture
#endif
}

void CpuInfo::Cleanup() {
  if (method_ == kCpuInfoCpuId) {
    CpuId::Cleanup();
  } else {
    ASSERT(method_ == kCpuInfoNone);
  }
}

bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  if (method_ == kCpuInfoCpuId) {
    return CpuId::field(idx);
  } else {
    UNREACHABLE();
  }
}

const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  if (method_ == kCpuInfoCpuId) {
    return CpuId::field(idx);
  } else if (method_ == kCpuInfoNone) {
    if (idx == kCpuInfoHardware) {
      return "Generic ARM64";
    }
    UNREACHABLE();
  } else {
    UNREACHABLE();
  }
}

bool CpuInfo::HasField(const char* field) {
  if (method_ == kCpuInfoCpuId) {
    return (strcmp(field, fields_[kCpuInfoProcessor]) == 0) ||
           (strcmp(field, fields_[kCpuInfoModel]) == 0) ||
           (strcmp(field, fields_[kCpuInfoHardware]) == 0) ||
           (strcmp(field, fields_[kCpuInfoFeatures]) == 0);
  } else if (method_ == kCpuInfoNone) {
    return false;
  } else {
    UNREACHABLE();
  }
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
