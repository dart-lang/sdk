// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/cpuinfo.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/simulator.h"

#if defined(HOST_ARCH_ARM)
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

namespace dart {

DEFINE_FLAG(bool, use_vfp, true, "Use vfp instructions if supported");
DEFINE_FLAG(bool, use_neon, true, "Use neon instructions if supported");
#if !defined(HOST_ARCH_ARM)
DEFINE_FLAG(bool, sim_use_armv7, true, "Use all ARMv7 instructions");
DEFINE_FLAG(bool, sim_use_armv5te, false, "Restrict to ARMv5TE instructions");
DEFINE_FLAG(bool, sim_use_armv6, false, "Restrict to ARMv6 instructions");
DEFINE_FLAG(bool, sim_use_hardfp, false, "Use the softfp ABI.");
#endif

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
bool HostCPUFeatures::vfp_supported_ = false;
bool HostCPUFeatures::neon_supported_ = false;
bool HostCPUFeatures::hardfp_supported_ = false;
const char* HostCPUFeatures::hardware_ = NULL;
ARMVersion HostCPUFeatures::arm_version_ = ARMvUnknown;
intptr_t HostCPUFeatures::store_pc_read_offset_ = 8;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif


#if defined(HOST_ARCH_ARM)
void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();
  hardware_ = CpuInfo::GetCpuModel();

  // Has floating point unit.
  vfp_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "vfp") &&
                   FLAG_use_vfp;

  // Check for ARMv5, ARMv6 or ARMv7. It can be in either the Processor or
  // Model information fields.
  if (CpuInfo::FieldContains(kCpuInfoProcessor, "ARM926EJ-S") ||
      CpuInfo::FieldContains(kCpuInfoModel, "ARM926EJ-S")) {
    // Lego Mindstorm EV3.
    arm_version_ = ARMv5TE;
    // On ARMv5, the PC read offset in an STR or STM instruction is either 8 or
    // 12 bytes depending on the implementation. On the Mindstorm EV3 it is 12
    // bytes.
    store_pc_read_offset_ = 12;
  } else if (CpuInfo::FieldContains(kCpuInfoProcessor, "ARMv6") ||
             CpuInfo::FieldContains(kCpuInfoModel, "ARMv6")) {
    // Raspberry Pi, etc.
    arm_version_ = ARMv6;
  } else {
    ASSERT(CpuInfo::FieldContains(kCpuInfoProcessor, "ARMv7") ||
           CpuInfo::FieldContains(kCpuInfoModel, "ARMv7"));
    arm_version_ = ARMv7;
  }

  // Has integer division.
  bool is_krait = CpuInfo::FieldContains(kCpuInfoHardware, "QCT APQ8064");
  if (is_krait) {
    // Special case for Qualcomm Krait CPUs in Nexus 4 and 7.
    integer_division_supported_ = true;
  } else {
    integer_division_supported_ =
        CpuInfo::FieldContains(kCpuInfoFeatures, "idiva");
  }
  neon_supported_ = CpuInfo::FieldContains(kCpuInfoFeatures, "neon") &&
                    FLAG_use_vfp && FLAG_use_neon;

  // Use the cross-compiler's predefined macros to determine whether we should
  // use the hard or soft float ABI.
#if defined(__ARM_PCS_VFP)
  hardfp_supported_ = true;
#else
  hardfp_supported_ = false;
#endif

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
  vfp_supported_ = FLAG_use_vfp;
  neon_supported_ = FLAG_use_vfp && FLAG_use_neon;
  hardfp_supported_ = FLAG_sim_use_hardfp;
  if (FLAG_sim_use_armv5te) {
    arm_version_ = ARMv5TE;
    integer_division_supported_ = false;
  } else if (FLAG_sim_use_armv6) {
    arm_version_ = ARMv6;
    integer_division_supported_ = true;
  } else if (FLAG_sim_use_armv7) {
    arm_version_ = ARMv7;
    integer_division_supported_ = true;
  }
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
