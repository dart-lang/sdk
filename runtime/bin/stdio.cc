// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/stdio.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  ScopedBlockingCall blocker;
  int byte = -1;
  if (Stdin::ReadByte(&byte)) {
    Dart_SetReturnValue(args, Dart_NewInteger(byte));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_GetEchoMode)(Dart_NativeArguments args) {
  bool enabled = false;
  if (Stdin::GetEchoMode(&enabled)) {
    Dart_SetReturnValue(args, Dart_NewBoolean(enabled));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_SetEchoMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 0));
  if (Stdin::SetEchoMode(enabled)) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_GetLineMode)(Dart_NativeArguments args) {
  bool enabled = false;
  if (Stdin::GetLineMode(&enabled)) {
    Dart_SetReturnValue(args, Dart_NewBoolean(enabled));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_SetLineMode)(Dart_NativeArguments args) {
  bool enabled = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 0));
  if (Stdin::SetLineMode(enabled)) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_AnsiSupported)(Dart_NativeArguments args) {
  bool supported = false;
  if (Stdin::AnsiSupported(&supported)) {
    Dart_SetBooleanReturnValue(args, supported);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdout_GetTerminalSize)(Dart_NativeArguments args) {
  if (!Dart_IsInteger(Dart_GetNativeArgument(args, 0))) {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return;
  }
  intptr_t fd = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  if ((fd != 1) && (fd != 2)) {
    Dart_SetReturnValue(args, Dart_NewApiError("Terminal fd must be 1 or 2"));
    return;
  }

  int size[2];
  if (Stdout::GetTerminalSize(fd, size)) {
    Dart_Handle list = Dart_NewList(2);
    Dart_ListSetAt(list, 0, Dart_NewInteger(size[0]));
    Dart_ListSetAt(list, 1, Dart_NewInteger(size[1]));
    Dart_SetReturnValue(args, list);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdout_AnsiSupported)(Dart_NativeArguments args) {
  if (!Dart_IsInteger(Dart_GetNativeArgument(args, 0))) {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return;
  }
  intptr_t fd = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  if ((fd != 1) && (fd != 2)) {
    Dart_SetReturnValue(args, Dart_NewApiError("Terminal fd must be 1 or 2"));
    return;
  }
  bool supported = false;
  if (Stdout::AnsiSupported(fd, &supported)) {
    Dart_SetBooleanReturnValue(args, supported);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

}  // namespace bin
}  // namespace dart
