// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_KERNEL_FINGERPRINTS_H_
#define RUNTIME_VM_COMPILER_FRONTEND_KERNEL_FINGERPRINTS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/allocation.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class KernelSourceFingerprintHelper : public AllStatic {
 public:
  static uint32_t CalculateClassFingerprint(const Class& klass);
  static uint32_t CalculateFieldFingerprint(const Field& field);
  static uint32_t CalculateFunctionFingerprint(const Function& func);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_KERNEL_FINGERPRINTS_H_
