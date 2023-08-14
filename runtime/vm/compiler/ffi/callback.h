// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_CALLBACK_H_
#define RUNTIME_VM_COMPILER_FFI_CALLBACK_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

namespace compiler {

namespace ffi {

FunctionPtr NativeCallbackFunction(const FunctionType& c_signature,
                                   const Function& dart_target,
                                   const Instance& exceptional_return,
                                   FfiCallbackKind kind);

// Builds a mapping from `callback-id` to code object / ...
//
// This mapping is used when a ffi trampoline function is invoked in order to
// find it's corresponding [Code] object as well as other metadata.
void SetFfiCallbackCode(Thread* thread,
                        const Function& ffi_trampoline,
                        const Code& code);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_CALLBACK_H_
