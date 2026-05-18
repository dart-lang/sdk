// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPU_LOONG64_H_
#define RUNTIME_VM_CPU_LOONG64_H_

#if !defined(RUNTIME_VM_CPU_H_)
#error Do not include cpu_loong64.h directly; use cpu.h instead.
#endif

#include "vm/allocation.h"

namespace dart {

// TargetCPUFeatures gives CPU features for the architecture that we are
// generating code for. HostCPUFeatures gives the CPU features for the
// architecture that we are actually running on.

class HostCPUFeatures : public AllStatic {
 public:
  static void Init();
  static void Cleanup();
  static const char* hardware() {
    DEBUG_ASSERT(initialized_);
    return hardware_;
  }

 private:
  static const char* hardware_;
#if defined(DEBUG)
  static bool initialized_;
#endif
};

class TargetCPUFeatures : public AllStatic {
 public:
  static void Init() { HostCPUFeatures::Init(); }
  static void Cleanup() { HostCPUFeatures::Cleanup(); }
  static const char* hardware() { return HostCPUFeatures::hardware(); }
  static bool double_truncate_round_supported() { return false; }
};

}  // namespace dart

#endif  // RUNTIME_VM_CPU_LOONG64_H_
