// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdin_GetEchoMode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdin_SetEchoMode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdin_GetLineMode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdin_SetLineMode)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdin_AnsiSupported)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdin unsupported on this platform"));
}

void FUNCTION_NAME(Stdout_GetTerminalSize)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdout unsupported on this platform"));
}

void FUNCTION_NAME(Stdout_AnsiSupported)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Stdout unsupported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
