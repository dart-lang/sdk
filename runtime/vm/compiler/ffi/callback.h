// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_CALLBACK_H_
#define RUNTIME_VM_COMPILER_FFI_CALLBACK_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "vm/raw_object.h"

namespace dart {

namespace compiler {

namespace ffi {

FunctionPtr NativeCallbackFunction(const Function& c_signature,
                                   const Function& dart_target,
                                   const Instance& exceptional_return);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_CALLBACK_H_
