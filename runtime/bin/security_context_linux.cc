// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED) && !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

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

const char* commandline_root_certs_file = NULL;
const char* commandline_root_certs_cache = NULL;

void SSLCertContext::TrustBuiltinRoots() {
  // First, try to use locations specified on the command line.
  if (commandline_root_certs_file != NULL) {
    LoadRootCertFile(commandline_root_certs_file);
    return;
  }

  if (commandline_root_certs_cache != NULL) {
    LoadRootCertCache(commandline_root_certs_cache);
    return;
  }

  // On Linux, we use the compiled-in trusted certs as a last resort. First,
  // we try to find the trusted certs in various standard locations. A good
  // discussion of the complexities of this endeavor can be found here:
  //
  // https://www.happyassassin.net/2015/01/12/a-note-about-ssltls-trusted-certificate-stores-and-platforms/
  const char* bundle = "/etc/pki/tls/certs/ca-bundle.crt";
  const char* cachedir = "/etc/ssl/certs";
  if (File::Exists(bundle)) {
    LoadRootCertFile(bundle);
    return;
  }

  if (Directory::Exists(cachedir) == Directory::EXISTS) {
    LoadRootCertCache(cachedir);
    return;
  }

  // Fall back on the compiled-in certs if the standard locations don't exist,
  // or we aren't on Linux.
  if (SSL_LOG_STATUS) {
    Log::Print("Trusting compiled-in roots\n");
  }
  AddCompiledInCerts();
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  // No callbacks to register for implementations using BoringSSL's built-in
  // verification mechanism.
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX)

#endif  // !defined(DART_IO_DISABLED) &&
        // !defined(DART_IO_SECURE_SOCKET_DISABLED)
