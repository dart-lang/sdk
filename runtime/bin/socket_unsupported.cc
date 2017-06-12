// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {


void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_CreateBindConnect)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_CreateBindDatagram)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_Available)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_Read)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_RecvFrom)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_WriteList)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_SendTo)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetPort)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetRemotePeer)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetError)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetType)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetSocketId)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_SetSocketId)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(ServerSocket_CreateBindListen)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(ServerSocket_Accept)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_GetOption)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_SetOption)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_JoinMulticast)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}


void FUNCTION_NAME(Socket_LeaveMulticast)(Dart_NativeArguments args) {
  Dart_ThrowException(
      DartUtils::NewDartArgumentError("Sockets unsupported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
