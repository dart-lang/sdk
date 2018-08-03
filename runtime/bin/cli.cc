// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(CLI_WaitForEvent)(Dart_NativeArguments args) {
  int64_t timeout_millis;
  Dart_Handle result = Dart_GetNativeIntegerArgument(args, 0, &timeout_millis);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  result = Dart_WaitForEvent(timeout_millis);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  Dart_SetReturnValue(args, result);
}

}  // namespace bin
}  // namespace dart
