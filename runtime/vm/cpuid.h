// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPUID_H_
#define RUNTIME_VM_CPUID_H_

#include "vm/globals.h"
#if !defined(HOST_OS_MACOS)
#include "vm/allocation.h"
#include "vm/cpuinfo.h"

namespace dart {

class CpuId : public AllStatic {
 public:
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  static void Init();
  static void Cleanup();

  // Caller must free the result of field.
  static const char* field(CpuInfoIndices idx);
#else
  static void Init() {}
  static void Cleanup() {}
  static const char* field(CpuInfoIndices idx) { return nullptr; }
#endif

 private:
  // Caller must free the result of id_string and brand_string.
  static const char* id_string();
  static const char* brand_string();

  static bool sse2() { return sse2_; }
  static bool sse41() { return sse41_; }
  static bool popcnt() { return popcnt_; }
  static bool abm() { return abm_; }

  static bool sse2_;
  static bool sse41_;
  static bool popcnt_;
  static bool abm_;
  static const char* id_string_;
  static const char* brand_string_;

  static void GetCpuId(int32_t level, uint32_t info[4]);
};

}  // namespace dart

#endif  // !defined(HOST_OS_MACOS)
#endif  // RUNTIME_VM_CPUID_H_
