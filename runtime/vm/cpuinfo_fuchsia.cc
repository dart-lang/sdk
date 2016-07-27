// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/cpuinfo.h"

#include "platform/assert.h"

// TODO(zra): Use "vm/cpuid.h"

namespace dart {

CpuInfoMethod CpuInfo::method_ = kCpuInfoDefault;
const char* CpuInfo::fields_[kCpuInfoMax] = {0};

void CpuInfo::InitOnce() {
  UNIMPLEMENTED();
}


void CpuInfo::Cleanup() {
  UNIMPLEMENTED();
}


bool CpuInfo::FieldContains(CpuInfoIndices idx, const char* search_string) {
  UNIMPLEMENTED();
  return false;
}


const char* CpuInfo::ExtractField(CpuInfoIndices idx) {
  UNIMPLEMENTED();
  return "<undefined>";
}


bool CpuInfo::HasField(const char* field) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
