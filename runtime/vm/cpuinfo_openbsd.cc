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
  UNIMPLEMENTED();

  return;
}


void CpuInfo::Cleanup() {
  UNIMPLEMENTED();

  return;
}


bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  UNIMPLEMENTED();

  return false;
}


bool CpuInfo::FieldContainsByString(const char* field,
                                    const char* search_string) {
  UNIMPLEMENTED();

  return false;
}


const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  UNIMPLEMENTED();

  return "";
}


const char* CpuInfo::ExtractFieldByString(const char* field) {
  UNIMPLEMENTED();

  return "";
}


bool CpuInfo::HasField(const char* field) {
  UNIMPLEMENTED();

  return false;
}

}  // namespace dart

#endif  // defined(TARGET_OS_OPENBSD)
