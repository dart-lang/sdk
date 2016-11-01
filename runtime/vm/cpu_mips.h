// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPU_MIPS_H_
#define RUNTIME_VM_CPU_MIPS_H_

#include "vm/allocation.h"

namespace dart {

// TargetCPUFeatures gives CPU features for the architecture that we are
// generating code for. HostCPUFeatures gives the CPU features for the
// architecture that we are actually running on. When the architectures
// are the same, TargetCPUFeatures will query HostCPUFeatures. When they are
// different (i.e. we are running in a simulator), HostCPUFeatures will
// additionally mock the options needed for the target architecture so that
// they may be altered for testing.

enum MIPSVersion {
  MIPS32,
  MIPS32r2,
  MIPSvUnknown,
};

class HostCPUFeatures: public AllStatic {
 public:
  static void InitOnce();
  static void Cleanup();
  static const char* hardware() {
    DEBUG_ASSERT(initialized_);
    return hardware_;
  }
  static MIPSVersion mips_version() {
    DEBUG_ASSERT(initialized_);
    return mips_version_;
  }

 private:
  static const char* hardware_;
  static MIPSVersion mips_version_;
#if defined(DEBUG)
  static bool initialized_;
#endif
};

class TargetCPUFeatures : public AllStatic {
 public:
  static void InitOnce() {
    HostCPUFeatures::InitOnce();
  }
  static void Cleanup() {
    HostCPUFeatures::Cleanup();
  }
  static const char* hardware() {
    return HostCPUFeatures::hardware();
  }
  static bool double_truncate_round_supported() {
    return false;
  }
  static MIPSVersion mips_version() {
    return HostCPUFeatures::mips_version();
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_CPU_MIPS_H_
