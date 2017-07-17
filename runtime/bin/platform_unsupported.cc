// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Platform_NumberOfProcessors)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_OperatingSystem)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_PathSeparator)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_LocalHostname)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_ExecutableName)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_ResolvedExecutableName)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_ExecutableArguments)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_Environment)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_GetVersion)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

void FUNCTION_NAME(Platform_LocaleName)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Platform is not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
