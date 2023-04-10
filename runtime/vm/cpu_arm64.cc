// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/cpu.h"
#include "vm/cpu_arm64.h"

#include "vm/cpuinfo.h"
#include "vm/simulator.h"

#if !defined(USING_SIMULATOR)
#if defined(DART_HOST_OS_FUCHSIA)
#include <zircon/syscalls.h>
#elif defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_IOS)
#include <libkern/OSCacheControl.h>
#elif defined(DART_HOST_OS_WINDOWS)
#include <processthreadsapi.h>
#endif
#endif

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#elif !defined(USING_SIMULATOR)
  // Nothing to do. Flushing no instructions.
  if (size == 0) {
    return;
  }

// ARM recommends using the gcc intrinsic __clear_cache on Linux and Android.
//
// https://community.arm.com/developer/ip-products/processors/b/processors-ip-blog/posts/caches-and-self-modifying-code
//
// On iOS we use sys_icache_invalidate from Darwin. See:
//
// https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sys_icache_invalidate.3.html
#if defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_IOS)
  sys_icache_invalidate(reinterpret_cast<void*>(start), size);
#elif defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  char* beg = reinterpret_cast<char*>(start);
  char* end = reinterpret_cast<char*>(start + size);
  __builtin___clear_cache(beg, end);
#elif defined(DART_HOST_OS_FUCHSIA)
  zx_status_t result = zx_cache_flush(reinterpret_cast<const void*>(start),
                                      size, ZX_CACHE_FLUSH_INSN);
  ASSERT(result == ZX_OK);
#elif defined(DART_HOST_OS_WINDOWS)
  BOOL result = FlushInstructionCache(
      GetCurrentProcess(), reinterpret_cast<const void*>(start), size);
  ASSERT(result != 0);
#else
#error FlushICache not implemented for this OS
#endif

#endif
}

const char* CPU::Id() {
  return
#if defined(USING_SIMULATOR)
      "sim"
#endif  // !defined(USING_SIMULATOR)
      "arm64";
}

const char* HostCPUFeatures::hardware_ = nullptr;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

#if !defined(USING_SIMULATOR)
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

#else  // !defined(USING_SIMULATOR)

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
#endif  // !defined(USING_SIMULATOR)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
