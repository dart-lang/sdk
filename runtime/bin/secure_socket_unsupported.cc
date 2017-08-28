// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

const char* commandline_root_certs_file = NULL;
const char* commandline_root_certs_cache = NULL;

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

void FUNCTION_NAME(SecureSocket_InitializeLibrary)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecureSocket_PeerCertificate)(Dart_NativeArguments args) {
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

void FUNCTION_NAME(SecurityContext_Allocate)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_UsePrivateKeyBytes)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_SetAlpnProtocols)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_SetClientAuthoritiesBytes)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_SetTrustedCertificatesBytes)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_TrustBuiltinRoots)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(SecurityContext_UseCertificateChainBytes)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(X509_Subject)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(X509_Issuer)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(X509_StartValidity)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

void FUNCTION_NAME(X509_EndValidity)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Secure Sockets unsupported on this platform"));
}

class SSLFilter {
 public:
  static CObject* ProcessFilterRequest(const CObjectArray& request);
};

CObject* SSLFilter::ProcessFilterRequest(const CObjectArray& request) {
  return CObject::IllegalArgumentError();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_SECURE_SOCKET_DISABLED)
