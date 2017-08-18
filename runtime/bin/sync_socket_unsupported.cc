// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(SynchronousSocket_CreateConnectSync)(
    Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_LookupRequest)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_CloseSync)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_Available)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_Read)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_ReadList)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_WriteList)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_ShutdownRead)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_ShutdownWrite)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_GetPort)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SynchronousSocket_GetRemotePeer)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
