// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPU_IA32_H_
#define RUNTIME_VM_CPU_IA32_H_

#if !defined(RUNTIME_VM_CPU_H_)
#error Do not include cpu_ia32.h directly; use cpu.h instead.
#endif

#include "vm/allocation.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, use_sse41);

class HostCPUFeatures : public AllStatic {
 public:
  static void Init();
  static void Cleanup();
  static const char* hardware() {
    DEBUG_ASSERT(initialized_);
    return hardware_;
  }
  static bool sse2_supported() {
    DEBUG_ASSERT(initialized_);
    return sse2_supported_;
  }
  static bool sse4_1_supported() {
    DEBUG_ASSERT(initialized_);
    return sse4_1_supported_ && FLAG_use_sse41;
  }
  static bool popcnt_supported() {
    DEBUG_ASSERT(initialized_);
    return popcnt_supported_;
  }
  static bool abm_supported() {
    DEBUG_ASSERT(initialized_);
    return abm_supported_;
  }

 private:
  static const char* hardware_;
  static bool sse2_supported_;
  static bool sse4_1_supported_;
  static bool popcnt_supported_;
  static bool abm_supported_;
#if defined(DEBUG)
  static bool initialized_;
#endif
};

class TargetCPUFeatures : public AllStatic {
 public:
  static void Init() { HostCPUFeatures::Init(); }
  static void Cleanup() { HostCPUFeatures::Cleanup(); }
  static const char* hardware() { return HostCPUFeatures::hardware(); }
  static bool sse2_supported() { return HostCPUFeatures::sse2_supported(); }
  static bool sse4_1_supported() { return HostCPUFeatures::sse4_1_supported(); }
  static bool popcnt_supported() { return HostCPUFeatures::popcnt_supported(); }
  static bool abm_supported() { return HostCPUFeatures::abm_supported(); }
  static bool double_truncate_round_supported() { return sse4_1_supported(); }
};

}  // namespace dart

#endif  // RUNTIME_VM_CPU_IA32_H_
