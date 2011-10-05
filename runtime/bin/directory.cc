// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/directory.h"

#include "include/dart_api.h"

void FUNCTION_NAME(Directory_Open)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle directory_handle = Dart_GetNativeArgument(args, 0);
  Dart_Handle path_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsString(path_handle)) {
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
  } else {
    const char* path =
        DartUtils::GetStringValue(path_handle);
    intptr_t dir = 0;
    bool success = Directory::Open(path, &dir);
    if (success) {
      DartUtils::SetIntegerInstanceField(directory_handle,
                                         DartUtils::kIdFieldName,
                                         dir);
    }
    Dart_SetReturnValue(args, Dart_NewBoolean(success));
  }
  Dart_ExitScope();
}

void FUNCTION_NAME(Directory_Close)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t dir = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  bool success = Directory::Close(dir);
  Dart_SetReturnValue(args, Dart_NewBoolean(success));
  Dart_ExitScope();
}


static intptr_t GetHandlerPort(Dart_Handle handle) {
  if (Dart_IsNull(handle)) {
    // TODO(ager): Generalize this to Directory::kInvalidId.
    return 0;
  }
  return DartUtils::GetIntegerInstanceField(handle, DartUtils::kIdFieldName);
}


void FUNCTION_NAME(Directory_List)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t dir = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  bool recursive = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  Dart_Port dir_handler_port = GetHandlerPort(Dart_GetNativeArgument(args, 3));
  Dart_Port file_handler_port = GetHandlerPort(Dart_GetNativeArgument(args, 4));
  Dart_Port done_handler_port = GetHandlerPort(Dart_GetNativeArgument(args, 5));
  Dart_Port dir_error_handler_port =
      GetHandlerPort(Dart_GetNativeArgument(args, 6));
  Directory::List(dir,
                  recursive,
                  dir_handler_port,
                  file_handler_port,
                  done_handler_port,
                  dir_error_handler_port);
  Dart_ExitScope();
}
