// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(SecureSocket_Init)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_Connect)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_AddCertificate)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_GetSelectedProtocol)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_RegisterHandshakeCompleteCallback)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_RegisterBadCertificateCallback)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_ProcessBuffer)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_InitializeLibrary)
    (Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_PeerCertificate)
    (Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_FilterPointer)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_Renegotiate)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}


void FUNCTION_NAME(SecureSocket_NewServicePort)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}
}  // namespace bin
}  // namespace dart
