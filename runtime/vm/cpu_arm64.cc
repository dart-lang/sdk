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
#if !defined(HOST_OS_FUCHSIA)
#include <sys/syscall.h>
#else
#include <zircon/syscalls.h>
#endif
#include <unistd.h>
#endif

#if defined(HOST_OS_IOS)
#include <libkern/OSCacheControl.h>
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
#if defined(HOST_OS_IOS)
  sys_icache_invalidate(reinterpret_cast<void*>(start), size);
#elif defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX)
  extern void __clear_cache(char*, char*);
  char* beg = reinterpret_cast<char*>(start);
  char* end = reinterpret_cast<char*>(start + size);
  ::__clear_cache(beg, end);
#elif defined(HOST_OS_FUCHSIA)
  zx_status_t result = zx_cache_flush(reinterpret_cast<const void*>(start),
                                      size, ZX_CACHE_FLUSH_INSN);
  ASSERT(result == ZX_OK);
#else
#error FlushICache only tested/supported on Android, Fuchsia, Linux and iOS
#endif

#endif
}

const char* CPU::Id() {
  return
#if defined(USING_SIMULATOR)
      "sim"
#endif  // !defined(HOST_ARCH_ARM64)
      "arm64";
}

const char* HostCPUFeatures::hardware_ = NULL;
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
  ASSERT(hardware_ != NULL);
  free(const_cast<char*>(hardware_));
  hardware_ = NULL;
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
  ASSERT(hardware_ != NULL);
  free(const_cast<char*>(hardware_));
  hardware_ = NULL;
  CpuInfo::Cleanup();
}
#endif  // !defined(USING_SIMULATOR)

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
