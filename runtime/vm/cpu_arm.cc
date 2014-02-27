// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_ARM)

#include "vm/cpu.h"
#include "vm/cpuinfo.h"
#include "vm/simulator.h"

#if defined(HOST_ARCH_ARM)
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(HOST_ARCH_ARM)
  // Nothing to do. Flushing no instructions.
  if (size == 0) {
    return;
  }

  // ARM recommends using the gcc intrinsic __clear_cache on Linux, and the
  // library call cacheflush from unistd.h on Android:
  // blogs.arm.com/software-enablement/141-caches-and-self-modifying-code/
  #if defined(__linux__) && !defined(ANDROID)
    extern void __clear_cache(char*, char*);
    char* beg = reinterpret_cast<char*>(start);
    char* end = reinterpret_cast<char*>(start + size);
    ::__clear_cache(beg, end);
  #elif defined(ANDROID)
    cacheflush(start, start + size, 0);
  #else
    #error FlushICache only tested/supported on Linux and Android
  #endif

#endif
}


const char* CPU::Id() {
  return
#if !defined(HOST_ARCH_ARM)
  "sim"
#endif  // !defined(HOST_ARCH_ARM)
  "arm";
}


bool HostCPUFeatures::integer_division_supported_ = false;
bool HostCPUFeatures::neon_supported_ = false;
const char* HostCPUFeatures::hardware_ = NULL;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif


#if defined(HOST_ARCH_ARM)
void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();
  hardware_ = CpuInfo::GetCpuModel();
  // Implements ARMv7.
  ASSERT(CpuInfo::FieldContains(kCpuInfoProcessor, "ARMv7"));
  // Has floating point unit.
  ASSERT(CpuInfo::FieldContains(kCpuInfoFeatures, "vfp"));
  // Has integer division.
  bool is_krait = CpuInfo::FieldContains(kCpuInfoModel, "QCT APQ8064");
  if (is_krait) {
    // Special case for Qualcomm Krait CPUs in Nexus 4 and 7.
    integer_division_supported_ = true;
  } else {
    integer_division_supported_ =
        CpuInfo::FieldContains(kCpuInfoFeatures, "idiva");
  }
  neon_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "neon");
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
  integer_division_supported_ = true;
  neon_supported_ = true;
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
#endif  // defined(HOST_ARCH_ARM)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
