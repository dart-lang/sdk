// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_NATIVE_FUNCTION_H_
#define RUNTIME_VM_NATIVE_FUNCTION_H_

#include "vm/allocation.h"

#include "include/dart_api.h"

namespace dart {

// Forward declarations.
class NativeArguments;

// We have three variants of native functions:
//  - bootstrap natives, which are called directly from stub code. The callee is
//    responsible for safepoint transitions and setting up handle scopes as
//    needed. Only VM-defined natives are bootstrap natives; they cannot be
//    defined by embedders or native extensions.
//  - no scope natives, which are called through a wrapper function. The wrapper
//    function handles the safepoint transition. The callee is responsible for
//    setting up API scopes as needed.
//  - auto scope natives, which are called through a wrapper function. The
//    wrapper function handles the safepoint transition and sets up an API
//    scope.

typedef void (*NativeFunction)(NativeArguments* arguments);
typedef void (*NativeFunctionWrapper)(Dart_NativeArguments args,
                                      Dart_NativeFunction func);

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_FUNCTION_H_
