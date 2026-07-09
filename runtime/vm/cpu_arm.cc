// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/cpu.h"
#include "vm/cpu_arm.h"

#include "vm/cpuinfo.h"

#if !defined(TARGET_HOST_MISMATCH)
#if defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_IOS)
#include <libkern/OSCacheControl.h>
#elif defined(DART_HOST_OS_WINDOWS)
#include <processthreadsapi.h>
#elif defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
#include <asm/hwcap.h>
#include <sys/auxv.h>
#endif
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

DEFINE_FLAG(bool, use_neon, true, "Use neon instructions if supported");
DEFINE_FLAG(bool,
            use_integer_division,
            true,
            "Use integer division instruction if supported");

#if defined(TARGET_HOST_MISMATCH)
#if defined(DART_TARGET_OS_ANDROID) || defined(DART_TARGET_OS_MACOS_IOS)
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
#if defined(DART_HOST_OS_IOS)
  sys_icache_invalidate(reinterpret_cast<void*>(start), size);
#elif defined(DART_HOST_OS_LINUX)
  char* beg = reinterpret_cast<char*>(start);
  char* end = reinterpret_cast<char*>(start + size);
  __builtin___clear_cache(beg, end);
#elif defined(DART_HOST_OS_ANDROID)
  cacheflush(start, start + size, 0);
#elif defined(DART_HOST_OS_WINDOWS)
  BOOL result = FlushInstructionCache(
      GetCurrentProcess(), reinterpret_cast<const void*>(start), size);
  ASSERT(result != 0);
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
bool HostCPUFeatures::neon_supported_ = false;
bool HostCPUFeatures::hardfp_supported_ = false;
const char* HostCPUFeatures::hardware_ = nullptr;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

#if !defined(TARGET_HOST_MISMATCH)
#if DART_HOST_OS_IOS
void HostCPUFeatures::Init() {
  // TODO(24743): Actually check the CPU features and fail if we're missing
  // something assumed in a precompiled snapshot.
  hardware_ = "";
  // When the VM is targetted to ARMv7, pretend that the CPU is ARMv7 even if
  // the CPU is actually AArch64.
  integer_division_supported_ = FLAG_use_integer_division;
  neon_supported_ = FLAG_use_neon;
  hardfp_supported_ = false;
#if defined(DEBUG)
  initialized_ = true;
#endif
}
#elif DART_HOST_OS_WINDOWS
void HostCPUFeatures::Init() {
  hardware_ = "";
  integer_division_supported_ = true;
  neon_supported_ = true;
  hardfp_supported_ = true;
#if defined(DEBUG)
  initialized_ = true;
#endif
}
#else  // DART_HOST_OS_IOS
void HostCPUFeatures::Init() {
  // Reading /proc/cpuinfo under QEMU can report the host CPU instead of the
  // emulated CPU.
  unsigned long hwcap = getauxval(AT_HWCAP);  // NOLINT
  integer_division_supported_ = (hwcap & HWCAP_IDIVA) != 0;
  neon_supported_ = (hwcap & HWCAP_NEON) != 0;

  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();

  // Qualcomm Krait CPUs (QCT APQ8064) in Nexus 4 and 7 incorrectly report that
  // they lack integer division.
  if (CpuInfo::FieldContains(kCpuInfoHardware, "QCT APQ8064")) {
    integer_division_supported_ = true;
  }
  // Marvell Armada 370/XP incorrectly reports that it has integer division.
  if (CpuInfo::FieldContains(kCpuInfoHardware, "Marvell Armada 370/XP")) {
    integer_division_supported_ = false;
  }
  // Some Android ARM emulators claim support for integer division but do not
  // actually support it.
  if (CpuInfo::FieldContains(kCpuInfoHardware, "Dummy Virtual Machine")) {
    integer_division_supported_ = false;
  }

  // Allow flags to override feature detection.
  if (!FLAG_use_integer_division) {
    integer_division_supported_ = false;
  }
  if (!FLAG_use_neon) {
    neon_supported_ = false;
  }

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
#endif  // DART_HOST_OS_IOS

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

#else

void HostCPUFeatures::Init() {
  CpuInfo::Init();
  hardware_ = CpuInfo::GetCpuModel();

  integer_division_supported_ = FLAG_use_integer_division;
  neon_supported_ = FLAG_use_neon;
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
  ASSERT(hardware_ != nullptr);
  free(const_cast<char*>(hardware_));
  hardware_ = nullptr;
  CpuInfo::Cleanup();
}
#endif  // !defined(TARGET_HOST_MISMATCH)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
