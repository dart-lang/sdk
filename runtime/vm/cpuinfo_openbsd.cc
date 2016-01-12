// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_OPENBSD)

#include "vm/cpuinfo.h"
#include "vm/cpuid.h"

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
  fields_[kCpuInfoProcessor] = "vendor_id";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoHardware] = "model name";
  fields_[kCpuInfoFeatures] = "flags";
  method_ = kCpuInfoCpuId;
  CpuId::InitOnce();
}


void CpuInfo::Cleanup() {
  CpuId::Cleanup();
}


bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  return strstr(CpuId::field(idx), search_string);
}


bool CpuInfo::FieldContainsByString(const char* field,
                                    const char* search_string) {
  for (int i = 0; i < kCpuInfoMax; i++) {
    if (strcmp(field, fields_[i]) == 0) {
      return FieldContains(static_cast<CpuInfoIndices>(i), search_string);
    }
  }
  UNIMPLEMENTED();
  return false;
}


const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  return CpuId::field(idx);
}


const char* CpuInfo::ExtractFieldByString(const char* field) {
  for (int i = 0; i < kCpuInfoMax; i++) {
    if (strcmp(field, fields_[i]) == 0) {
      return ExtractField(static_cast<CpuInfoIndices>(i));
    }
  }
  UNIMPLEMENTED();
  return NULL;
}


bool CpuInfo::HasField(const char* field) {
  return (strcmp(field, fields_[kCpuInfoProcessor]) == 0) ||
    (strcmp(field, fields_[kCpuInfoModel]) == 0) ||
    (strcmp(field, fields_[kCpuInfoHardware]) == 0) ||
    (strcmp(field, fields_[kCpuInfoFeatures]) == 0);
}

}  // namespace dart

#endif  // defined(TARGET_OS_OPENBSD)
