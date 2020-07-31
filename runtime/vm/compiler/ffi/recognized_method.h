// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_RECOGNIZED_METHOD_H_
#define RUNTIME_VM_COMPILER_FFI_RECOGNIZED_METHOD_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "vm/compiler/method_recognizer.h"

namespace dart {

namespace compiler {

namespace ffi {

// TypedData class id for a NativeType type, except for Void and NativeFunction.
classid_t ElementTypedDataCid(classid_t class_id);

// Returns the kFFi<type>Cid for the recognized load/store method [kind].
classid_t RecognizedMethodTypeArgCid(MethodRecognizer::Kind kind);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_RECOGNIZED_METHOD_H_
