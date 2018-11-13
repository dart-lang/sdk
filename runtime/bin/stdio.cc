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

static bool GetIntptrArgument(Dart_NativeArguments args,
                              intptr_t idx,
                              intptr_t* value) {
  ASSERT(value != NULL);
  int64_t v;
  Dart_Handle status = Dart_GetNativeIntegerArgument(args, 0, &v);
  if (Dart_IsError(status)) {
    // The caller is expecting an OSError if something goes wrong.
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return false;
  }
  if ((v < kIntptrMin) || (kIntptrMax < v)) {
    // The caller is expecting an OSError if something goes wrong.
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return false;
  }
  *value = static_cast<intptr_t>(v);
  return true;
}

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  ScopedBlockingCall blocker;
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  int byte = -1;
  if (Stdin::ReadByte(fd, &byte)) {
    Dart_SetIntegerReturnValue(args, byte);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_GetEchoMode)(Dart_NativeArguments args) {
  bool enabled = false;
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  if (Stdin::GetEchoMode(fd, &enabled)) {
    Dart_SetBooleanReturnValue(args, enabled);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_SetEchoMode)(Dart_NativeArguments args) {
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  bool enabled;
  Dart_Handle status = Dart_GetNativeBooleanArgument(args, 1, &enabled);
  if (Dart_IsError(status)) {
    // The caller is expecting an OSError if something goes wrong.
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return;
  }
  if (Stdin::SetEchoMode(fd, enabled)) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_GetLineMode)(Dart_NativeArguments args) {
  bool enabled = false;
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  if (Stdin::GetLineMode(fd, &enabled)) {
    Dart_SetBooleanReturnValue(args, enabled);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_SetLineMode)(Dart_NativeArguments args) {
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  bool enabled;
  Dart_Handle status = Dart_GetNativeBooleanArgument(args, 1, &enabled);
  if (Dart_IsError(status)) {
    // The caller is expecting an OSError if something goes wrong.
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
    return;
  }
  if (Stdin::SetLineMode(fd, enabled)) {
    Dart_SetBooleanReturnValue(args, true);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdin_AnsiSupported)(Dart_NativeArguments args) {
  bool supported = false;
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
    return;
  }
  if (Stdin::AnsiSupported(fd, &supported)) {
    Dart_SetBooleanReturnValue(args, supported);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Stdout_GetTerminalSize)(Dart_NativeArguments args) {
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
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
  intptr_t fd;
  if (!GetIntptrArgument(args, 0, &fd)) {
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
