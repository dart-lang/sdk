// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(DART_HOST_OS_FUCHSIA)

#include "bin/security_context.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/secure_socket_filter.h"
#include "bin/secure_socket_utils.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

// The security context won't necessarily use the compiled-in root certificates,
// but since there is no way to update the size of the allocation after creating
// the weak persistent handle, we assume that it will. Note that when the
// root certs aren't compiled in, |root_certificates_pem_length| is 0.
const intptr_t SSLCertContext::kApproximateSize =
    sizeof(SSLCertContext) + root_certificates_pem_length;

void SSLCertContext::TrustBuiltinRoots() {
  // First, try to use locations specified on the command line.
  if (root_certs_file() != nullptr) {
    LoadRootCertFile(root_certs_file());
    return;
  }
  if (root_certs_cache() != nullptr) {
    LoadRootCertCache(root_certs_cache());
    return;
  }

  int status = SSL_CTX_set_default_verify_paths(context());
  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure trusting builtin roots");
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  // No callbacks to register for implementations using BoringSSL's built-in
  // verification mechanism.
}

TrustEvaluateHandlerFunc SSLCertContext::GetTrustEvaluateHandler() {
  return nullptr;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA)

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
