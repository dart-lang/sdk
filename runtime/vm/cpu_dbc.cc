// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/cpu.h"
#include "vm/cpu_dbc.h"

#include "vm/cpuinfo.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
  // Nothing to do.
}

const char* CPU::Id() {
  return "dbc";
}

const char* HostCPUFeatures::hardware_ = NULL;
#if defined(DEBUG)
bool HostCPUFeatures::initialized_ = false;
#endif

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

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
