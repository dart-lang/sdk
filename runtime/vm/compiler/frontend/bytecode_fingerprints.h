// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FINGERPRINTS_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FINGERPRINTS_H_

#include "platform/allocation.h"
#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

class BytecodeFingerprintHelper : public AllStatic {
 public:
  static uint32_t CalculateFunctionFingerprint(const Function& func);
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_FINGERPRINTS_H_
