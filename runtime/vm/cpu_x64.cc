// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"
#include "vm/cpu_x64.h"

#include "vm/cpuinfo.h"

namespace dart {

DEFINE_FLAG(bool, use_sse41, true, "Use SSE 4.1 if available");

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}

const char* CPU::Id() {
  return
#if defined(DART_INCLUDE_SIMULATOR)
      "sim"
#endif  // !defined(DART_INCLUDE_SIMULATOR)
      "x64";
}

const char* HostCPUFeatures::hardware_ = nullptr;
bool HostCPUFeatures::sse2_supported_ = true;
bool HostCPUFeatures::sse4_1_supported_ = false;
bool HostCPUFeatures::popcnt_supported_ = false;
bool HostCPUFeatures::abm_supported_ = false;

#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

#if !defined(DART_INCLUDE_SIMULATOR)
void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();
  sse4_1_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "sse4_1") ||
                      CpuInfo::FieldContains(kCpuInfoFeatures, "sse4.1");
  popcnt_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "popcnt");
  abm_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "abm");
#if defined(DEBUG)
  initialized_ = true;
#endif
}

void HostCPUFeatures::Cleanup() {
  DEBUG_ASSERT(initialized_);
#if defined(DEBUG)
  initialized_ = false;
#endif
  ASSERT(hardware_ != nullptr);
  free(const_cast<char*>(hardware_));
  hardware_ = nullptr;
  CpuInfo::Cleanup();
}

#else  // !defined(DART_INCLUDE_SIMULATOR)

void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();
  sse4_1_supported_ = false;
  popcnt_supported_ = false;
  abm_supported_ = false;
#if defined(DEBUG)
  initialized_ = true;
#endif
}

void HostCPUFeatures::Cleanup() {
  DEBUG_ASSERT(initialized_);
#if defined(DEBUG)
  initialized_ = false;
#endif
  ASSERT(hardware_ != nullptr);
  free(const_cast<char*>(hardware_));
  hardware_ = nullptr;
  CpuInfo::Cleanup();
}
#endif  // !defined(DART_INCLUDE_SIMULATOR)

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
