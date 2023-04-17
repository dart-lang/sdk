// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

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

#ifndef DART_TARGET_OS_WINDOWS_UWP
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
  Syslog::PrintErr("%s %s\n", str, error_string);
}

#ifndef DART_TARGET_OS_WINDOWS_UWP
static bool AddCertificatesFromNamedSystemStore(const wchar_t* name,
                                                DWORD store_type,
                                                X509_STORE* store) {
  ASSERT(store_type == CERT_SYSTEM_STORE_CURRENT_USER ||
         store_type == CERT_SYSTEM_STORE_LOCAL_MACHINE);

  if (SSL_LOG_STATUS) {
    Syslog::Print("AddCertificatesFromNamedSystemStore %ls type: %s\n", name,
                  store_type == CERT_SYSTEM_STORE_CURRENT_USER
                      ? "Current User"
                      : "Local Machine");
  }

  HCERTSTORE cert_store =
      CertOpenStore(CERT_STORE_PROV_SYSTEM,
                    0,     // the encoding type is not needed
                    NULL,  // use the default HCRYPTPROV
                    store_type | CERT_STORE_READONLY_FLAG, name);

  if (cert_store == nullptr) {
    if (SSL_LOG_STATUS) {
      DWORD error = GetLastError();
      Syslog::PrintErr(
          "Failed to open Windows root store %ls type %d due to %d\n", name,
          store_type, error);
    }
    return false;
  }

  // Iterating through all certificates in the store. A nullptr is required to
  // start iteration.
  PCCERT_CONTEXT cert_context = nullptr;
  do {
    cert_context = CertEnumCertificatesInStore(cert_store, cert_context);
    if (cert_context == nullptr) {
      // reach the end of store.
      break;
    }
    BIO* root_cert_bio =
        BIO_new_mem_buf(const_cast<unsigned char*>(cert_context->pbCertEncoded),
                        cert_context->cbCertEncoded);
    // `root_cert` has to be initialized to nullptr, otherwise, it will be
    // considered as an existing X509 and cause segmentation fault.
    X509* root_cert = nullptr;
    if (d2i_X509_bio(root_cert_bio, &root_cert) == nullptr) {
      if (SSL_LOG_STATUS) {
        PrintSSLErr("Fail to read certificate");
      }
      BIO_free(root_cert_bio);
      continue;
    }
    BIO_free(root_cert_bio);

    if (SSL_LOG_STATUS) {
      auto s_name = X509_get_subject_name(root_cert);
      auto s_issuer_name = X509_get_issuer_name(root_cert);
      auto serial_number = X509_get_serialNumber(root_cert);
      BIGNUM* bn = ASN1_INTEGER_to_BN(serial_number, nullptr);
      char* hex = BN_bn2hex(bn);
      Syslog::Print("Considering root certificate serial: %s subject name: ",
                    hex);
      OPENSSL_free(hex);
      X509_NAME_print_ex_fp(stdout, s_name, 4, 0);
      Syslog::Print(" issuer:");
      X509_NAME_print_ex_fp(stdout, s_issuer_name, 4, 0);
      Syslog::Print("\n");
    }

    if (!SecureSocketUtils::IsCurrentTimeInsideCertValidDateRange(root_cert)) {
      if (SSL_LOG_STATUS) {
        Syslog::Print("...certificate is outside of its valid date range\n");
      }
      X509_free(root_cert);
      continue;
    }

    int status = X509_STORE_add_cert(store, root_cert);
    if (status == 0) {
      int error = ERR_get_error();
      if (ERR_GET_REASON(error) == X509_R_CERT_ALREADY_IN_HASH_TABLE) {
        if (SSL_LOG_STATUS) {
          Syslog::Print("...duplicate\n");
        }
        X509_free(root_cert);
        continue;
      }
      if (SSL_LOG_STATUS) {
        PrintSSLErr("Failed to add certificate to x509 trust store");
      }
      X509_free(root_cert);
      CertFreeCertificateContext(cert_context);
      CertCloseStore(cert_store, 0);
      return false;
    }
  } while (cert_context != nullptr);

  // It always returns non-zero.
  CertFreeCertificateContext(cert_context);
  if (!CertCloseStore(cert_store, 0)) {
    if (SSL_LOG_STATUS) {
      PrintSSLErr("Fail to close system root store");
    }
    return false;
  }
  return true;
}

static bool AddCertificatesFromSystemStore(DWORD store_type,
                                           X509_STORE* store) {
  if (!AddCertificatesFromNamedSystemStore(L"ROOT", store_type, store)) {
    return false;
  }
  if (!AddCertificatesFromNamedSystemStore(L"CA", store_type, store)) {
    return false;
  }
  if (!AddCertificatesFromNamedSystemStore(L"TRUST", store_type, store)) {
    return false;
  }
  if (!AddCertificatesFromNamedSystemStore(L"MY", store_type, store)) {
    return false;
  }
  return true;
}
#endif  // ifdef DART_TARGET_OS_WINDOWS_UWP

// Add certificates from Windows trusted root store.
static bool AddCertificatesFromRootStore(X509_STORE* store) {
// The UWP platform doesn't support CertEnumCertificatesInStore hence
// this function cannot work when compiled in UWP mode.
#ifdef DART_TARGET_OS_WINDOWS_UWP
  return false;
#else
  if (!AddCertificatesFromSystemStore(CERT_SYSTEM_STORE_CURRENT_USER, store)) {
    return false;
  }

  if (!AddCertificatesFromSystemStore(CERT_SYSTEM_STORE_LOCAL_MACHINE, store)) {
    return false;
  }

  return true;
#endif  // ifdef DART_TARGET_OS_WINDOWS_UWP
}

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

  if (bypass_trusting_system_roots()) {
    if (SSL_LOG_STATUS) {
      Syslog::Print("Bypass trusting Windows built-in roots\n");
    }
  } else {
    if (SSL_LOG_STATUS) {
      Syslog::Print("Trusting Windows built-in roots\n");
    }
    X509_STORE* store = SSL_CTX_get_cert_store(context());
    if (AddCertificatesFromRootStore(store)) {
      return;
    }
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

#endif  // defined(DART_HOST_OS_WINDOWS)

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
