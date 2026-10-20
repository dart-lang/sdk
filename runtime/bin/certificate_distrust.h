// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_CERTIFICATE_DISTRUST_H_
#define RUNTIME_BIN_CERTIFICATE_DISTRUST_H_

#include "platform/globals.h"

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include <openssl/x509.h>

#include "platform/allocation.h"

#if defined(DART_HOST_OS_MACOS)
#include <Security/Security.h>
#endif

namespace dart {
namespace bin {

class CertificateDistrust : public AllStatic {
 public:
  // Returns X509_V_OK, X509_V_ERR_CERT_REJECTED for an explicitly distrusted
  // public key, or X509_V_ERR_UNSPECIFIED if the certificate cannot be checked.
  static int CheckCertificate(const X509* certificate);
  static int CheckChain(const STACK_OF(X509) * chain);

  // Runs the ordinary verifier before inspecting the resulting chain.
  // Explicit distrust uses the same application override as other certificate
  // failures. Internal errors cannot be overridden.
  static int VerifyChain(X509_STORE_CTX* store_ctx,
                         int (*on_bad_certificate)(int, X509_STORE_CTX*));

#if defined(DART_HOST_OS_MACOS)
  // Checks the chain built by an evaluated SecTrust, including certificates
  // supplied by the system and its selected trust anchor.
  static int CheckTrust(SecTrustRef trust);
#endif
};

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
#endif  // RUNTIME_BIN_CERTIFICATE_DISTRUST_H_
