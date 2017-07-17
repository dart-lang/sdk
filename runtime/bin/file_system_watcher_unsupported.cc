// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(FileSystemWatcher_IsSupported)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_InitWatcher)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_CloseWatcher)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_WatchPath)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_UnwatchPath)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_ReadEvents)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

void FUNCTION_NAME(FileSystemWatcher_GetSocketId)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "FileSystemWatcher is not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
