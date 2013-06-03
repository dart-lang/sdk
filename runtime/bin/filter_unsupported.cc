// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(Filter_CreateZLibInflate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ThrowException(DartUtils::NewInternalError(
        "ZLibInflater and Deflater not supported on this platform"));
  Dart_ExitScope();
}

void FUNCTION_NAME(Filter_CreateZLibDeflate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ExitScope();
}

void FUNCTION_NAME(Filter_Process)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ExitScope();
}


void FUNCTION_NAME(Filter_Processed)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ExitScope();
}


void FUNCTION_NAME(Filter_End)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ExitScope();
}

}  // namespace bin
}  // namespace dart
