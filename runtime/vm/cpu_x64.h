// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CPU_X64_H_
#define VM_CPU_X64_H_

#include "vm/allocation.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, use_sse41);

class HostCPUFeatures : public AllStatic {
 public:
  static void InitOnce();
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

 private:
  static const uint64_t kSSE2BitMask = static_cast<uint64_t>(1) << 26;
  static const uint64_t kSSE4_1BitMask = static_cast<uint64_t>(1) << 51;
  static const char* hardware_;
  static bool sse2_supported_;
  static bool sse4_1_supported_;
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
  static bool sse2_supported() {
    return HostCPUFeatures::sse2_supported();
  }
  static bool sse4_1_supported() {
    return HostCPUFeatures::sse4_1_supported();
  }
  static bool double_truncate_round_supported() {
    return false;
  }
};

}  // namespace dart

#endif  // VM_CPU_X64_H_
