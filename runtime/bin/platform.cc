// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"
#include "bin/platform.h"
#include "include/dart_api.h"


void FUNCTION_NAME(Platform_NumberOfProcessors)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_NewInteger(Platform::NumberOfProcessors()));
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_OperatingSystem)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, DartUtils::NewString(Platform::OperatingSystem()));
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_PathSeparator)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, DartUtils::NewString(File::PathSeparator()));
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_LocalHostname)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const intptr_t HOSTNAME_LENGTH = 256;
  char hostname[HOSTNAME_LENGTH];
  if (Platform::LocalHostname(hostname, HOSTNAME_LENGTH)) {
    Dart_SetReturnValue(args, DartUtils::NewString(hostname));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_Environment)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t count = 0;
  char** env = Platform::Environment(&count);
  if (env == NULL) {
    OSError error(-1,
                  "Failed to retrieve environment variables.",
                  OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
  } else {
    Dart_Handle result = Dart_NewList(count);
    if (Dart_IsError(result)) {
      Platform::FreeEnvironment(env, count);
      Dart_PropagateError(result);
    }
    for (intptr_t i = 0; i < count; i++) {
      Dart_Handle str = DartUtils::NewString(env[i]);
      if (Dart_IsError(str)) {
        Platform::FreeEnvironment(env, count);
        Dart_PropagateError(str);
      }
      Dart_Handle error = Dart_ListSetAt(result, i, str);
      if (Dart_IsError(error)) {
        Platform::FreeEnvironment(env, count);
        Dart_PropagateError(error);
      }
    }
    Platform::FreeEnvironment(env, count);
    Dart_SetReturnValue(args, result);
  }
  Dart_ExitScope();
}
