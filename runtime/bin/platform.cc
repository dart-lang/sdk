// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  Dart_SetReturnValue(args, Dart_NewString(Platform::OperatingSystem()));
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_PathSeparator)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_NewString(File::PathSeparator()));
  Dart_ExitScope();
}


void FUNCTION_NAME(Platform_LocalHostname)(Dart_NativeArguments args) {
  Dart_EnterScope();
  const intptr_t HOSTNAME_LENGTH = 256;
  char hostname[HOSTNAME_LENGTH];
  if (Platform::LocalHostname(hostname, HOSTNAME_LENGTH)) {
    Dart_SetReturnValue(args, Dart_NewString(hostname));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
  Dart_ExitScope();
}
