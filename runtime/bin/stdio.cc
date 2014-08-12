// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/utils.h"
#include "bin/stdio.h"

#include "platform/globals.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  ScopedBlockingCall blocker;
  Dart_SetReturnValue(args, Dart_NewInteger(Stdin::ReadByte()));
}


void FUNCTION_NAME(Stdin_GetEchoMode)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewBoolean(Stdin::GetEchoMode()));
}


void FUNCTION_NAME(Stdin_SetEchoMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 0));
  Stdin::SetEchoMode(enabled);
}


void FUNCTION_NAME(Stdin_GetLineMode)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewBoolean(Stdin::GetLineMode()));
}


void FUNCTION_NAME(Stdin_SetLineMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 0));
  Stdin::SetLineMode(enabled);
}


void FUNCTION_NAME(Stdout_GetTerminalSize)(Dart_NativeArguments args) {
  int size[2];
  if (Stdout::GetTerminalSize(size)) {
    Dart_Handle list = Dart_NewList(2);
    Dart_ListSetAt(list, 0, Dart_NewInteger(size[0]));
    Dart_ListSetAt(list, 1, Dart_NewInteger(size[1]));
    Dart_SetReturnValue(args, list);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

}  // namespace bin
}  // namespace dart
