// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"

#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/utils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Platform_NumberOfProcessors)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewInteger(Platform::NumberOfProcessors()));
}

void FUNCTION_NAME(Platform_OperatingSystem)(Dart_NativeArguments args) {
  Dart_Handle str = DartUtils::NewString(Platform::OperatingSystem());
  ThrowIfError(str);
  Dart_SetReturnValue(args, str);
}

void FUNCTION_NAME(Platform_OperatingSystemVersion)(Dart_NativeArguments args) {
  const char* version = Platform::OperatingSystemVersion();
  if (version == NULL) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  } else {
    Dart_Handle str = DartUtils::NewString(version);
    ThrowIfError(str);
    Dart_SetReturnValue(args, str);
  }
}

void FUNCTION_NAME(Platform_PathSeparator)(Dart_NativeArguments args) {
  Dart_Handle str = DartUtils::NewString(File::PathSeparator());
  ThrowIfError(str);
  Dart_SetReturnValue(args, str);
}

void FUNCTION_NAME(Platform_LocalHostname)(Dart_NativeArguments args) {
  const intptr_t HOSTNAME_LENGTH = 256;
  char hostname[HOSTNAME_LENGTH];
  if (Platform::LocalHostname(hostname, HOSTNAME_LENGTH)) {
    Dart_Handle str = DartUtils::NewString(hostname);
    ThrowIfError(str);
    Dart_SetReturnValue(args, str);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Platform_ExecutableName)(Dart_NativeArguments args) {
  if (Platform::GetExecutableName() != NULL) {
    Dart_SetReturnValue(
        args, Dart_NewStringFromCString(Platform::GetExecutableName()));
  } else {
    Dart_SetReturnValue(args, Dart_Null());
  }
}

void FUNCTION_NAME(Platform_ResolvedExecutableName)(Dart_NativeArguments args) {
  if (Platform::GetResolvedExecutableName() != NULL) {
    Dart_SetReturnValue(
        args, Dart_NewStringFromCString(Platform::GetResolvedExecutableName()));
  } else {
    Dart_SetReturnValue(args, Dart_Null());
  }
}

void FUNCTION_NAME(Platform_ExecutableArguments)(Dart_NativeArguments args) {
  int end = Platform::GetScriptIndex();
  char** argv = Platform::GetArgv();
  Dart_Handle string_type = DartUtils::GetDartType("dart:core", "String");
  ThrowIfError(string_type);
  Dart_Handle result =
      Dart_NewListOfTypeFilled(string_type, Dart_EmptyString(), end - 1);
  for (intptr_t i = 1; i < end; i++) {
    Dart_Handle str = DartUtils::NewString(argv[i]);
    ThrowIfError(str);
    ThrowIfError(Dart_ListSetAt(result, i - 1, str));
  }
  Dart_SetReturnValue(args, result);
}

void FUNCTION_NAME(Platform_Environment)(Dart_NativeArguments args) {
  intptr_t count = 0;
  char** env = Platform::Environment(&count);
  if (env == NULL) {
    OSError error(-1, "Failed to retrieve environment variables.",
                  OSError::kUnknown);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
  } else {
    Dart_Handle result = Dart_NewList(count);
    ThrowIfError(result);
    intptr_t result_idx = 0;
    for (intptr_t env_idx = 0; env_idx < count; env_idx++) {
      Dart_Handle str = DartUtils::NewString(env[env_idx]);
      if (Dart_IsError(str)) {
        // Silently skip over environment entries that are not valid UTF8
        // strings.
        continue;
      }
      Dart_Handle error = Dart_ListSetAt(result, result_idx, str);
      ThrowIfError(error);
      result_idx++;
    }
    Dart_SetReturnValue(args, result);
  }
}

void FUNCTION_NAME(Platform_GetVersion)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewStringFromCString(Dart_VersionString()));
}

void FUNCTION_NAME(Platform_LocaleName)(Dart_NativeArguments args) {
  const char* locale = Platform::LocaleName();
  if (locale == NULL) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  } else {
    Dart_SetReturnValue(args, Dart_NewStringFromCString(locale));
  }
}

}  // namespace bin
}  // namespace dart
