// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_DBC_TRAMPOLINE_H_
#define RUNTIME_VM_COMPILER_FFI_DBC_TRAMPOLINE_H_

#include "vm/globals.h"

namespace dart {

#if !defined(HOST_OS_WINDOWS) &&                                               \
    (defined(HOST_ARCH_X64) || defined(HOST_ARCH_ARM64))

// Generic Trampoline for DBC dart:ffi calls. Argument needs to be layed out as
// a FfiMarshalledArguments.
extern "C" void FfiTrampolineCall(uint64_t* ffi_marshalled_args);

#else

void FfiTrampolineCall(uint64_t* ffi_marshalled_args) {
  UNREACHABLE();
}

#endif  //  defined(HOST_ARCH_X64) && !defined(HOST_OS_WINDOWS)

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_DBC_TRAMPOLINE_H_
