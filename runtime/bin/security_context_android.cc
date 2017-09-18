// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/security_context.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/secure_socket_filter.h"
#include "bin/secure_socket_utils.h"

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
  if (root_certs_file() != NULL) {
    LoadRootCertFile(root_certs_file());
    return;
  }
  if (root_certs_cache() != NULL) {
    LoadRootCertCache(root_certs_cache());
    return;
  }

  // On Android, we don't compile in the trusted root certificates. Insead,
  // we use the directory of trusted certificates already present on the device.
  // This saves ~240KB from the size of the binary. This has the drawback that
  // SSL_do_handshake will synchronously hit the filesystem looking for root
  // certs during its trust evaluation. We call SSL_do_handshake directly from
  // the Dart thread so that Dart code can be invoked from the "bad certificate"
  // callback called by SSL_do_handshake.
  const char* android_cacerts = "/system/etc/security/cacerts";
  LoadRootCertCache(android_cacerts);
  return;
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  // No callbacks to register for implementations using BoringSSL's built-in
  // verification mechanism.
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
