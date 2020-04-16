// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_ABI_H_
#define RUNTIME_VM_COMPILER_FFI_ABI_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

namespace dart {

namespace compiler {

namespace ffi {

// These ABIs should be kept in sync with pkg/vm/lib/transformations/ffi.dart.
enum class Abi {
  kWordSize64 = 0,
  kWordSize32Align32 = 1,
  kWordSize32Align64 = 2
};

// The target ABI. Defines sizes and alignment of native types.
Abi TargetAbi();

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_ABI_H_
