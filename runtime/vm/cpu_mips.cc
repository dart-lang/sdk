// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/cpu.h"
#include "vm/cpu_mips.h"

#include "vm/cpuinfo.h"
#include "vm/simulator.h"

#if !defined(USING_SIMULATOR)
#include <asm/cachectl.h> /* NOLINT */
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if !defined(USING_SIMULATOR)
  int res;
  // See http://www.linux-mips.org/wiki/Cacheflush_Syscall.
  res = syscall(__NR_cacheflush, start, size, ICACHE);
  ASSERT(res == 0);
#else  // defined(HOST_ARCH_MIPS)
  // When running in simulated mode we do not need to flush the ICache because
  // we are not running on the actual hardware.
#endif  // defined(HOST_ARCH_MIPS)
}


const char* CPU::Id() {
  return
#if defined(USING_SIMULATOR)
  "sim"
#endif  // !defined(HOST_ARCH_MIPS)
  "mips";
}


const char* HostCPUFeatures::hardware_ = NULL;
MIPSVersion HostCPUFeatures::mips_version_ = MIPSvUnknown;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif


#if !defined(USING_SIMULATOR)
void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();
  hardware_ = CpuInfo::GetCpuModel();
  // Has a floating point unit.
  ASSERT(CpuInfo::FieldContains(kCpuInfoModel, "FPU"));

  // We want to know the ISA version, but on MIPS, CpuInfo can't tell us, so
  // we use the same ISA version that Dart's C++ compiler targeted.
#if defined(_MIPS_ARCH_MIPS32R2)
  mips_version_ = MIPS32r2;
#elif defined(_MIPS_ARCH_MIPS32)
  mips_version_ = MIPS32;
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
  mips_version_ = MIPS32r2;
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
#endif  // defined(HOST_ARCH_MIPS)

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
