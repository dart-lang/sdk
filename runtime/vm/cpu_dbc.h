// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPU_DBC_H_
#define RUNTIME_VM_CPU_DBC_H_

#include "vm/allocation.h"
#include "vm/simulator.h"

namespace dart {

class HostCPUFeatures : public AllStatic {
 public:
  static void InitOnce();
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
  static void InitOnce() { HostCPUFeatures::InitOnce(); }
  static void Cleanup() { HostCPUFeatures::Cleanup(); }

  static const char* hardware() { return CPU::Id(); }

  static bool double_truncate_round_supported() { return true; }
};

}  // namespace dart

#endif  // RUNTIME_VM_CPU_DBC_H_
