// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_ARM64)

#include "vm/cpu.h"
#include "vm/cpuinfo.h"
#include "vm/simulator.h"

#if defined(HOST_ARCH_ARM64)
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(HOST_ARCH_ARM64)
  // Nothing to do. Flushing no instructions.
  if (size == 0) {
    return;
  }

  // ARM recommends using the gcc intrinsic __clear_cache on Linux and Android.
  // blogs.arm.com/software-enablement/141-caches-and-self-modifying-code/
  #if defined(__linux__) || defined(ANDROID)
    extern void __clear_cache(char*, char*);
    char* beg = reinterpret_cast<char*>(start);
    char* end = reinterpret_cast<char*>(start + size);
    ::__clear_cache(beg, end);
  #else
    #error FlushICache only tested/supported on Linux and Android
  #endif

#endif
}


const char* CPU::Id() {
  return
#if !defined(HOST_ARCH_ARM64)
  "sim"
#endif  // !defined(HOST_ARCH_ARM64)
  "arm64";
}


const char* HostCPUFeatures::hardware_ = NULL;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif


#if defined(HOST_ARCH_ARM64)
void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();
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
  ASSERT(hardware_ != NULL);
  free(const_cast<char*>(hardware_));
  hardware_ = NULL;
  CpuInfo::Cleanup();
}

#else

void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();
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
  ASSERT(hardware_ != NULL);
  free(const_cast<char*>(hardware_));
  hardware_ = NULL;
  CpuInfo::Cleanup();
}
#endif  // defined(HOST_ARCH_ARM64)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
