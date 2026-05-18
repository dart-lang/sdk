// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/cpu.h"
#include "vm/cpu_loong64.h"

#include "vm/cpuinfo.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  if (size == 0) {
    return;
  }

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  char* beg = reinterpret_cast<char*>(start);
  char* end = reinterpret_cast<char*>(start + size);
  __builtin___clear_cache(beg, end);
#else
#error FlushICache not implemented for this OS
#endif

#endif
}

const char* CPU::Id() {
  return "loong64";
}

const char* HostCPUFeatures::hardware_ = nullptr;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();
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

}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
