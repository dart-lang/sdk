// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CPU_DBC_H_
#define VM_CPU_DBC_H_

#include "vm/allocation.h"
#include "vm/simulator.h"

namespace dart {

class HostCPUFeatures: public AllStatic {
 public:
  static const char* hardware() { return "simdbc"; }
};

class TargetCPUFeatures : public AllStatic {
 public:
  static void InitOnce() {}
  static void Cleanup() {}

  static bool double_truncate_round_supported() {
    return true;
  }
};

}  // namespace dart

#endif  // VM_CPU_DBC_H_
