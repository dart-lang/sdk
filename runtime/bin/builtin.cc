// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"

// Implementation of native functions which are used for some
// test/debug functionality in standalone dart mode.

void PrintString(FILE* out, Dart_Handle str) {
  Dart_Result result = Dart_StringToCString(str);
  const char* cstring = Dart_IsValidResult(result) ?
      Dart_GetResultAsCString(result) : Dart_GetErrorCString(result);
  fprintf(out, "%s\n", cstring);
  fflush(out);
}


void FUNCTION_NAME(Logger_PrintString)(Dart_NativeArguments args) {
  Dart_EnterScope();
  PrintString(stdout, Dart_GetNativeArgument(args, 0));
  Dart_ExitScope();
}
