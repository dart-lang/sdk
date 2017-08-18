// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Directory_Current)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_SetCurrent)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_Exists)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_Create)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_SystemTemp)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_CreateTemp)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_Delete)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_Rename)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_FillWithDirectoryListing)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_GetAsyncDirectoryListerPointer)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

void FUNCTION_NAME(Directory_SetAsyncDirectoryListerPointer)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "Directory is not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
