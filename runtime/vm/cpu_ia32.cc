// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/cpu.h"

#include "vm/assembler.h"
#include "vm/constants_ia32.h"
#include "vm/cpuinfo.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(bool, use_sse41, true, "Use SSE 4.1 if available");

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}


const char* CPU::Id() {
  return "ia32";
}


bool HostCPUFeatures::sse2_supported_ = false;
bool HostCPUFeatures::sse4_1_supported_ = false;
char* HostCPUFeatures::hardware_ = NULL;
#ifdef DEBUG
bool HostCPUFeatures::initialized_ = false;
#endif


#define __ assembler.

void HostCPUFeatures::InitOnce() {
  CpuInfo::InitOnce();

  hardware_ = CpuInfo::GetCpuModel();
  sse2_supported_ = CpuInfo::FieldContainsById(
      CpuInfo::kCpuInfoFeatures, "sse2");
  sse4_1_supported_ =
      CpuInfo::FieldContainsById(CpuInfo::kCpuInfoFeatures, "sse4_1") ||
      CpuInfo::FieldContainsById(CpuInfo::kCpuInfoFeatures, "sse4.1");

#ifdef DEBUG
  initialized_ = true;
#endif
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
