// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/directory.h"

#include "include/dart_api.h"

static intptr_t GetHandlerPort(Dart_Handle handle) {
  if (Dart_IsNull(handle)) {
    return 0;
  }
  return DartUtils::GetIntegerInstanceField(handle, DartUtils::kIdFieldName);
}


void FUNCTION_NAME(Directory_List)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  bool recursive = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  Dart_Port dir_port = GetHandlerPort(Dart_GetNativeArgument(args, 3));
  Dart_Port file_port = GetHandlerPort(Dart_GetNativeArgument(args, 4));
  Dart_Port done_port = GetHandlerPort(Dart_GetNativeArgument(args, 5));
  Dart_Port error_port =
      GetHandlerPort(Dart_GetNativeArgument(args, 6));
  ASSERT(Dart_IsString(path));
  Directory::List(DartUtils::GetStringValue(path),
                  recursive,
                  dir_port,
                  file_port,
                  done_port,
                  error_port);
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Exists)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsString(path));
  Directory::ExistsResult result =
      Directory::Exists(DartUtils::GetStringValue(path));
  int return_value = -1;
  if (result == Directory::EXISTS) {
    return_value = 1;
  }
  if (result == Directory::DOES_NOT_EXIST) {
    return_value = 0;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Create)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsString(path));
  bool created = Directory::Create(DartUtils::GetStringValue(path));
  Dart_SetReturnValue(args, Dart_NewBoolean(created));
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Delete)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsString(path));
  bool deleted = Directory::Delete(DartUtils::GetStringValue(path));
  Dart_SetReturnValue(args, Dart_NewBoolean(deleted));
  Dart_ExitScope();
}
