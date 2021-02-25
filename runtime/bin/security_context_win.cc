// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/security_context.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>
#include <wincrypt.h>

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/secure_socket_filter.h"
#include "bin/secure_socket_utils.h"
#include "platform/syslog.h"

#ifndef TARGET_OS_WINDOWS_UWP
#pragma comment(lib, "crypt32.lib")
#endif

namespace dart {
namespace bin {

// The security context won't necessarily use the compiled-in root certificates,
// but since there is no way to update the size of the allocation after creating
// the weak persistent handle, we assume that it will. Note that when the
// root certs aren't compiled in, |root_certificates_pem_length| is 0.
const intptr_t SSLCertContext::kApproximateSize =
    sizeof(SSLCertContext) + root_certificates_pem_length;

static void PrintSSLErr(const char* str) {
  int error = ERR_get_error();
  char error_string[SecureSocketUtils::SSL_ERROR_MESSAGE_BUFFER_SIZE];
  ERR_error_string_n(error, error_string,
                     SecureSocketUtils::SSL_ERROR_MESSAGE_BUFFER_SIZE);
  Syslog::PrintErr("%s ERROR: %d %s\n", str, error, error_string);
}

// Add certificates from Windows trusted root store.
static bool AddCertificatesFromRootStore(X509_STORE* store) {
// The UWP platform doesn't support CertEnumCertificatesInStore hence
// this function cannot work when compiled in UWP mode.
#ifdef TARGET_OS_WINDOWS_UWP
  return false;
#else
  // Open root system store.
  // Note that only current user certificates are accessible using this method,
  // not the local machine store.
  HCERTSTORE cert_store = CertOpenSystemStore(NULL, L"ROOT");
  if (cert_store == NULL) {
    if (SSL_LOG_STATUS) {
      DWORD error = GetLastError();
      Syslog::PrintErr("Failed to open Windows root store due to %d\n", error);
    }
    return false;
  }

  // Iterating through all certificates in the store. A NULL is required to
  // start iteration.
  PCCERT_CONTEXT cert_context = NULL;
  do {
    cert_context = CertEnumCertificatesInStore(cert_store, cert_context);
    if (cert_context == NULL) {
      // reach the end of store.
      break;
    }
    BIO* root_cert_bio =
        BIO_new_mem_buf(const_cast<unsigned char*>(cert_context->pbCertEncoded),
                        cert_context->cbCertEncoded);
    // `root_cert` has to be initialized to NULL, otherwise, it will be
    // considerred as an existing X509 and cause segmentation fault.
    X509* root_cert = NULL;
    if (d2i_X509_bio(root_cert_bio, &root_cert) == NULL) {
      if (SSL_LOG_STATUS) {
        PrintSSLErr("Fail to read certificate");
      }
      BIO_free(root_cert_bio);
      continue;
    }
    BIO_free(root_cert_bio);
    int status = X509_STORE_add_cert(store, root_cert);
    if (status == 0) {
      if (SSL_LOG_STATUS) {
        PrintSSLErr("Fail to add certificate to trust store");
      }
      X509_free(root_cert);
      CertFreeCertificateContext(cert_context);
      CertCloseStore(cert_store, 0);
      return false;
    }
  } while (cert_context != NULL);

  // It always returns non-zero.
  CertFreeCertificateContext(cert_context);
  if (!CertCloseStore(cert_store, 0)) {
    if (SSL_LOG_STATUS) {
      PrintSSLErr("Fail to close system root store");
    }
    return false;
  }
  return true;
#endif  // ifdef TARGET_OS_WINDOWS_UWP
}

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

  if (SSL_LOG_STATUS) {
    Syslog::Print("Trusting Windows built-in roots\n");
  }
  X509_STORE* store = SSL_CTX_get_cert_store(context());
  if (AddCertificatesFromRootStore(store)) {
    return;
  }
  // Reset store. SSL_CTX_set_cert_store will take ownership of store. A manual
  // free is not needed.
  SSL_CTX_set_cert_store(context(), X509_STORE_new());
  // Fall back on the compiled-in certs if the standard locations don't exist,
  // or fail to load certificates from Windows root store.
  if (SSL_LOG_STATUS) {
    Syslog::Print("Trusting compiled-in roots\n");
  }
  AddCompiledInCerts();
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  // No callbacks to register for implementations using BoringSSL's built-in
  // verification mechanism.
}

TrustEvaluateHandlerFunc SSLCertContext::GetTrustEvaluateHandler() const {
  return nullptr;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
