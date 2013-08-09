// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/utils.h"
#include "bin/stdin.h"

#include "platform/globals.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewInteger(Stdin::ReadByte()));
}


void FUNCTION_NAME(Stdin_SetEchoMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  Stdin::SetEchoMode(enabled);
  Dart_SetReturnValue(args, Dart_Null());
}


void FUNCTION_NAME(Stdin_SetLineMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  Stdin::SetLineMode(enabled);
  Dart_SetReturnValue(args, Dart_Null());
}

}  // namespace bin
}  // namespace dart
