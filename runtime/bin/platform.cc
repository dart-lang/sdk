// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"

#include "include/dart_api.h"

#include "bin/file.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
const char* Platform::package_root_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

void FUNCTION_NAME(Platform_NumberOfProcessors)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewInteger(Platform::NumberOfProcessors()));
}


void FUNCTION_NAME(Platform_OperatingSystem)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, DartUtils::NewString(Platform::OperatingSystem()));
}


void FUNCTION_NAME(Platform_PathSeparator)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, DartUtils::NewString(File::PathSeparator()));
}


void FUNCTION_NAME(Platform_LocalHostname)(Dart_NativeArguments args) {
  const intptr_t HOSTNAME_LENGTH = 256;
  char hostname[HOSTNAME_LENGTH];
  if (Platform::LocalHostname(hostname, HOSTNAME_LENGTH)) {
    Dart_SetReturnValue(args, DartUtils::NewString(hostname));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Platform_ExecutableName)(Dart_NativeArguments args) {
  ASSERT(Platform::GetExecutableName() != NULL);
  Dart_SetReturnValue(
      args, Dart_NewStringFromCString(Platform::GetExecutableName()));
}


void FUNCTION_NAME(Platform_ExecutableArguments)(Dart_NativeArguments args) {
  int end = Platform::GetScriptIndex();
  char** argv = Platform::GetArgv();
  Dart_Handle result = Dart_NewList(end - 1);
  for (intptr_t i = 1; i < end; i++) {
    Dart_Handle str = DartUtils::NewString(argv[i]);
    Dart_Handle error = Dart_ListSetAt(result, i - 1, str);
    if (Dart_IsError(error)) {
      Dart_PropagateError(error);
    }
  }
  Dart_SetReturnValue(args, result);
}


void FUNCTION_NAME(Platform_PackageRoot)(Dart_NativeArguments args) {
  const char* package_root = Platform::GetPackageRoot();
  if (package_root == NULL) {
    package_root = "";
  }
  Dart_SetReturnValue(args, Dart_NewStringFromCString(package_root));
}


void FUNCTION_NAME(Platform_Environment)(Dart_NativeArguments args) {
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
}


void FUNCTION_NAME(Platform_GetVersion)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewStringFromCString(Dart_VersionString()));
}

}  // namespace bin
}  // namespace dart
