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
  Dart_Handle recursive = Dart_GetNativeArgument(args, 2);
  Dart_Port dir_port = GetHandlerPort(Dart_GetNativeArgument(args, 3));
  Dart_Port file_port = GetHandlerPort(Dart_GetNativeArgument(args, 4));
  Dart_Port done_port = GetHandlerPort(Dart_GetNativeArgument(args, 5));
  Dart_Port error_port =
      GetHandlerPort(Dart_GetNativeArgument(args, 6));
  if (!Dart_IsString(path) || !Dart_IsBoolean(recursive)) {
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
  } else {
    Directory::List(DartUtils::GetStringValue(path),
                    DartUtils::GetBooleanValue(recursive),
                    dir_port,
                    file_port,
                    done_port,
                    error_port);
    Dart_SetReturnValue(args, Dart_NewBoolean(true));
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Exists)(Dart_NativeArguments args) {
  static const int kError = -1;
  static const int kExists = 1;
  static const int kDoesNotExist = 0;
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  if (Dart_IsString(path)) {
    Directory::ExistsResult result =
        Directory::Exists(DartUtils::GetStringValue(path));
    int return_value = kError;
    if (result == Directory::EXISTS) {
      return_value = kExists;
    }
    if (result == Directory::DOES_NOT_EXIST) {
      return_value = kDoesNotExist;
    }
    Dart_SetReturnValue(args, Dart_NewInteger(return_value));
  } else {
    Dart_SetReturnValue(args, Dart_NewInteger(kDoesNotExist));
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Create)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  if (Dart_IsString(path)) {
    bool created = Directory::Create(DartUtils::GetStringValue(path));
    Dart_SetReturnValue(args, Dart_NewBoolean(created));
  } else {
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Directory_Delete)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  if (Dart_IsString(path)) {
    bool deleted = Directory::Delete(DartUtils::GetStringValue(path));
    Dart_SetReturnValue(args, Dart_NewBoolean(deleted));
  } else {
    Dart_SetReturnValue(args, Dart_NewBoolean(false));
  }
  Dart_ExitScope();
}
