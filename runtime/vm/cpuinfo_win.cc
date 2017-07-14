// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "vm/cpuid.h"
#include "vm/cpuinfo.h"

// __cpuid()
#include <intrin.h>  // NOLINT
#include <string.h>  // NOLINT

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
  method_ = kCpuInfoCpuId;

  // Initialize the CpuId information.
  CpuId::InitOnce();

  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "Hardware";
  fields_[kCpuInfoHardware] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
  fields_[kCpuInfoArchitecture] = NULL;
}

void CpuInfo::Cleanup() {
  CpuId::Cleanup();
}

bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  ASSERT(method_ != kCpuInfoDefault);
  return strstr(CpuId::field(idx), search_string);
}

const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  ASSERT(method_ != kCpuInfoDefault);
  return CpuId::field(idx);
}

bool CpuInfo::HasField(const char* field) {
  ASSERT(method_ != kCpuInfoDefault);
  return (strcmp(field, fields_[kCpuInfoProcessor]) == 0) ||
         (strcmp(field, fields_[kCpuInfoModel]) == 0) ||
         (strcmp(field, fields_[kCpuInfoHardware]) == 0) ||
         (strcmp(field, fields_[kCpuInfoFeatures]) == 0);
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
