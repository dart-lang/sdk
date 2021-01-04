// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/cpu.h"
#include "vm/cpu_arm.h"

#include "vm/cpuinfo.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/simulator.h"

#if defined(HOST_OS_IOS)
#include <libkern/OSCacheControl.h>
#endif

#if !defined(TARGET_HOST_MISMATCH)
#include <sys/syscall.h> /* NOLINT */
#include <unistd.h>      /* NOLINT */
#endif

// ARM version differences.
// We support only ARMv7 and variants. We detect the presence of vfp,
// neon, and integer division instructions. Considering ARMv5TE as the baseline,
// later versions add the following features/instructions that we use:
//
// ARMv6:
// - PC read offset in store instructions is 8 rather than 12, matching the
//   offset in read instructions,
// - strex, ldrex, and clrex load/store/clear exclusive instructions,
// - umaal multiplication instruction,
// ARMv7:
// - movw, movt 16-bit immediate load instructions,
// - mls multiplication instruction,
// - vmovs, vmovd floating point immediate load instructions.
//
// If an aarch64 CPU is detected, we generate ARMv7 code.
//
// Where we are missing vfp, we do not unbox doubles, or generate intrinsics for
// floating point operations. Where we are missing neon, we do not unbox SIMD
// values, or inline operations on SIMD values. Where we are missing integer
// division, we do not inline division operations, and we do not generate
// intrinsics that do division. See the feature tests in flow_graph_optimizer.cc
// for details.

namespace dart {

DEFINE_FLAG(bool, use_vfp, true, "Use vfp instructions if supported");
DEFINE_FLAG(bool, use_neon, true, "Use neon instructions if supported");
DEFINE_FLAG(bool,
            use_integer_division,
            true,
            "Use integer division instruction if supported");

#if defined(TARGET_HOST_MISMATCH)
#if defined(TARGET_OS_ANDROID) || defined(TARGET_OS_MACOS_IOS)
DEFINE_FLAG(bool, sim_use_hardfp, false, "Use the hardfp ABI.");
#else
DEFINE_FLAG(bool, sim_use_hardfp, true, "Use the hardfp ABI.");
#endif
#endif

void CPU::FlushICache(uword start, uword size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#elif !defined(TARGET_HOST_MISMATCH) && HOST_ARCH_ARM
  // Nothing to do. Flushing no instructions.
  if (size == 0) {
    return;
  }

// ARM recommends using the gcc intrinsic __clear_cache on Linux, and the
// library call cacheflush from unistd.h on Android:
//
// https://community.arm.com/developer/ip-products/processors/b/processors-ip-blog/posts/caches-and-self-modifying-code
//
// On iOS we use sys_icache_invalidate from Darwin. See:
//
// https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sys_icache_invalidate.3.html
#if defined(HOST_OS_IOS)
  sys_icache_invalidate(reinterpret_cast<void*>(start), size);
#elif defined(__linux__) && !defined(ANDROID)
  extern void __clear_cache(char*, char*);
  char* beg = reinterpret_cast<char*>(start);
  char* end = reinterpret_cast<char*>(start + size);
  ::__clear_cache(beg, end);
#elif defined(ANDROID)
  cacheflush(start, start + size, 0);
#else
#error FlushICache only tested/supported on Linux, Android and iOS
#endif
#endif
}

const char* CPU::Id() {
  return
#if defined(TARGET_HOST_MISMATCH)
      "sim"
#endif  // defined(TARGET_HOST_MISMATCH)
      "arm";
}

bool HostCPUFeatures::integer_division_supported_ = false;
bool HostCPUFeatures::vfp_supported_ = false;
bool HostCPUFeatures::neon_supported_ = false;
bool HostCPUFeatures::hardfp_supported_ = false;
const char* HostCPUFeatures::hardware_ = NULL;
intptr_t HostCPUFeatures::store_pc_read_offset_ = 8;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

#if !defined(TARGET_HOST_MISMATCH)
#if HOST_OS_IOS
void HostCPUFeatures::Init() {
  // TODO(24743): Actually check the CPU features and fail if we're missing
  // something assumed in a precompiled snapshot.
  hardware_ = "";
  // When the VM is targetted to ARMv7, pretend that the CPU is ARMv7 even if
  // the CPU is actually AArch64.
  vfp_supported_ = FLAG_use_vfp;
  integer_division_supported_ = FLAG_use_integer_division;
  neon_supported_ = FLAG_use_neon;
  hardfp_supported_ = false;
#if defined(DEBUG)
  initialized_ = true;
#endif
}
#else  // HOST_OS_IOS
void HostCPUFeatures::Init() {
  bool is_arm64 = false;
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();

  // Check for ARMv7, or aarch64.
  // It can be in either the Processor or Model information fields.
  if (CpuInfo::FieldContains(kCpuInfoProcessor, "aarch64") ||
      CpuInfo::FieldContains(kCpuInfoModel, "aarch64") ||
      CpuInfo::FieldContains(kCpuInfoArchitecture, "8") ||
      CpuInfo::FieldContains(kCpuInfoArchitecture, "AArch64")) {
    // pretend that this arm64 cpu is really an ARMv7
    is_arm64 = true;
  } else if (!CpuInfo::FieldContains(kCpuInfoProcessor, "ARMv7") &&
             !CpuInfo::FieldContains(kCpuInfoModel, "ARMv7") &&
             !CpuInfo::FieldContains(kCpuInfoArchitecture, "7")) {
#if !defined(DART_RUN_IN_QEMU_ARMv7)
    FATAL("Unrecognized ARM CPU architecture.");
#endif
  }

#if defined(DART_RUN_IN_QEMU_ARMv7)
  vfp_supported_ = true;
#else
  // Has floating point unit.
  vfp_supported_ =
      (CpuInfo::FieldContains(kCpuInfoFeatures, "vfp") || is_arm64) &&
      FLAG_use_vfp;
#endif

  // Has integer division.
  // Special cases:
  // - Qualcomm Krait CPUs (QCT APQ8064) in Nexus 4 and 7 incorrectly report
  //   that they lack integer division.
  // - Marvell Armada 370/XP incorrectly reports that it has integer division.
  bool is_krait = CpuInfo::FieldContains(kCpuInfoHardware, "QCT APQ8064");
  bool is_armada_370xp =
      CpuInfo::FieldContains(kCpuInfoHardware, "Marvell Armada 370/XP");
  bool is_virtual_machine =
      CpuInfo::FieldContains(kCpuInfoHardware, "Dummy Virtual Machine");
#if defined(HOST_OS_ANDROID)
  bool is_android = true;
#else
  bool is_android = false;
#endif
  if (is_krait) {
    integer_division_supported_ = FLAG_use_integer_division;
  } else if (is_android && is_arm64) {
    // Various Android ARM64 devices, including the Qualcomm Snapdragon 820/821
    // CPUs (MSM 8996 and MSM8996pro) in Xiaomi MI5 and Pixel lack integer
    // division even though ARMv8 requires it in A32. Instead of attempting to
    // track all of these devices, we conservatively disable use of integer
    // division on Android ARM64 devices.
    // TODO(29270): /proc/self/auxv might be more reliable here.
    integer_division_supported_ = false;
  } else if (is_armada_370xp) {
    integer_division_supported_ = false;
  } else if (is_android && !is_arm64 && is_virtual_machine) {
    // Some Android ARM emulators claim support for integer division in
    // /proc/cpuinfo but do not actually support it.
    integer_division_supported_ = false;
  } else {
    integer_division_supported_ =
        (CpuInfo::FieldContains(kCpuInfoFeatures, "idiva") || is_arm64) &&
        FLAG_use_integer_division;
  }
  neon_supported_ =
      (CpuInfo::FieldContains(kCpuInfoFeatures, "neon") || is_arm64) &&
      FLAG_use_vfp && FLAG_use_neon;

// Use the cross-compiler's predefined macros to determine whether we should
// use the hard or soft float ABI.
#if defined(__ARM_PCS_VFP) || defined(DART_RUN_IN_QEMU_ARMv7)
  hardfp_supported_ = true;
#else
  hardfp_supported_ = false;
#endif

#if defined(DEBUG)
  initialized_ = true;
#endif
}
#endif  // HOST_OS_IOS

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

void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();

  integer_division_supported_ = FLAG_use_integer_division;
  vfp_supported_ = FLAG_use_vfp;
  neon_supported_ = FLAG_use_vfp && FLAG_use_neon;
  hardfp_supported_ = FLAG_sim_use_hardfp;
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
#endif  // !defined(TARGET_HOST_MISMATCH)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
