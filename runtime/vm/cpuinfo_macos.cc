// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_MACOS)

#include "vm/cpuinfo.h"

#include <errno.h>  // NOLINT
#include <sys/types.h>  // NOLINT
#include <sys/sysctl.h>  // NOLINT

#include "platform/assert.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
  method_ = kCpuInfoSystem;

  fields_[kCpuInfoProcessor] = "machdep.cpu.vendor";
  fields_[kCpuInfoModel] = "machdep.cpu.brand_string";
  fields_[kCpuInfoHardware] = "machdep.cpu.brand_string";
  fields_[kCpuInfoFeatures] = "machdep.cpu.features";
}


void CpuInfo::Cleanup() {}


bool CpuInfo::FieldContainsByString(const char* field,
                                    const char* search_string) {
  ASSERT(method_ != kCpuInfoDefault);
  ASSERT(search_string != NULL);
  char dest[1024];
  size_t dest_len = 1024;

  ASSERT(HasField(field));
  if (sysctlbyname(field, dest, &dest_len, NULL, 0) != 0) {
    UNREACHABLE();
    return false;
  }

  return (strcasestr(dest, search_string) != NULL);
}


bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  ASSERT(method_ != kCpuInfoDefault);
  return FieldContainsByString(FieldName(idx), search_string);
}


const char* CpuInfo::ExtractFieldByString(const char* field) {
  ASSERT(method_ != kCpuInfoDefault);
  ASSERT(field != NULL);
  size_t result_len;

  ASSERT(HasField(field));
  if (sysctlbyname(field, NULL, &result_len, NULL, 0) != 0) {
    UNREACHABLE();
    return 0;
  }

  char* result = new char[result_len];
  if (sysctlbyname(field, result, &result_len, NULL, 0) != 0) {
    UNREACHABLE();
    return 0;
  }

  return result;
}


const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  ASSERT(method_ != kCpuInfoDefault);
  return ExtractFieldByString(FieldName(idx));
}


bool CpuInfo::HasField(const char* field) {
  ASSERT(method_ != kCpuInfoDefault);
  ASSERT(field != NULL);
  int ret = sysctlbyname(field, NULL, NULL, NULL, 0);
  return (ret != ENOENT);
}

}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
