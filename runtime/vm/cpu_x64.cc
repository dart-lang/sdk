// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"
#include "vm/cpu_x64.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/constants_x64.h"
#include "vm/cpuinfo.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(bool, use_sse41, true, "Use SSE 4.1 if available");

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}

const char* CPU::Id() {
  return "x64";
}

bool HostCPUFeatures::sse2_supported_ = true;
bool HostCPUFeatures::sse4_1_supported_ = false;
const char* HostCPUFeatures::hardware_ = NULL;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();
  sse4_1_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "sse4_1") ||
                      CpuInfo::FieldContains(kCpuInfoFeatures, "sse4.1");

#if defined(DEBUG)
  initialized_ = true;
#endif
}

void HostCPUFeatures::Cleanup() {
  DEBUG_ASSERT(initialized_);
#if defined(DEBUG)
  initialized_ = false;
#endif
  ASSERT(hardware_ != NULL);
  free(const_cast<char*>(hardware_));
  hardware_ = NULL;
  CpuInfo::Cleanup();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
