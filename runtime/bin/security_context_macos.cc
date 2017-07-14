// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED) && !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/security_context.h"

#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecureTransport.h>
#include <Security/Security.h>

#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/secure_socket_filter.h"

namespace dart {
namespace bin {

const intptr_t SSLCertContext::kApproximateSize = sizeof(SSLCertContext);

const char* commandline_root_certs_file = NULL;
const char* commandline_root_certs_cache = NULL;

template <typename T>
class ScopedCFType {
 public:
  explicit ScopedCFType(T obj) : obj_(obj) {}

  ~ScopedCFType() { CFRelease(obj_); }

  T get() { return obj_; }
  T* ptr() { return &obj_; }
  const T get() const { return obj_; }

  void set(T obj) { obj_ = obj; }

 private:
  T obj_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedCFType);
};

typedef ScopedCFType<CFMutableArrayRef> ScopedCFMutableArrayRef;
typedef ScopedCFType<CFDataRef> ScopedCFDataRef;
typedef ScopedCFType<SecPolicyRef> ScopedSecPolicyRef;
typedef ScopedCFType<SecCertificateRef> ScopedSecCertificateRef;
typedef ScopedCFType<SecTrustRef> ScopedSecTrustRef;

static SecCertificateRef CreateSecCertificateFromX509(X509* cert) {
  if (cert == NULL) {
    return NULL;
  }
  unsigned char* deb_cert = NULL;
  int length = i2d_X509(cert, &deb_cert);
  if (length < 0) {
    return 0;
  }
  ASSERT(deb_cert != NULL);
  ScopedCFDataRef cert_buf(
      CFDataCreateWithBytesNoCopy(NULL, deb_cert, length, kCFAllocatorNull));
  SecCertificateRef auth_cert =
      SecCertificateCreateWithData(NULL, cert_buf.get());
  if (auth_cert == NULL) {
    return NULL;
  }
  return auth_cert;
}

static int CertificateVerificationCallback(X509_STORE_CTX* ctx, void* arg) {
  SSLCertContext* context = static_cast<SSLCertContext*>(arg);

  // Convert BoringSSL formatted certificates to SecCertificate certificates.
  ScopedCFMutableArrayRef cert_chain(NULL);
  X509* root_cert = NULL;
  if (ctx->untrusted != NULL) {
    STACK_OF(X509)* user_provided_certs = ctx->untrusted;
    int num_certs = sk_X509_num(user_provided_certs);
    int current_cert = 0;
    cert_chain.set(CFArrayCreateMutable(NULL, num_certs, NULL));
    X509* ca;
    while ((ca = sk_X509_shift(user_provided_certs)) != NULL) {
      SecCertificateRef cert = CreateSecCertificateFromX509(ca);
      if (cert == NULL) {
        return ctx->verify_cb(0, ctx);
      }
      CFArrayAppendValue(cert_chain.get(), cert);
      ++current_cert;

      if (current_cert == num_certs) {
        root_cert = ca;
      }
    }
  }

  // Convert all trusted certificates provided by the user via
  // setTrustedCertificatesBytes or the command line into SecCertificates.
  ScopedCFMutableArrayRef trusted_certs(CFArrayCreateMutable(NULL, 0, NULL));
  X509_STORE* store = ctx->ctx;
  ASSERT(store != NULL);

  if (store->objs != NULL) {
    for (uintptr_t i = 0; i < sk_X509_OBJECT_num(store->objs); ++i) {
      X509* ca = sk_X509_OBJECT_value(store->objs, i)->data.x509;
      SecCertificateRef cert = CreateSecCertificateFromX509(ca);
      if (cert == NULL) {
        return ctx->verify_cb(0, ctx);
      }
      CFArrayAppendValue(trusted_certs.get(), cert);
    }
  }

  // Generate a generic X509 verification policy.
  ScopedSecPolicyRef policy(SecPolicyCreateBasicX509());

  // Create the trust object with the certificates provided by the user.
  ScopedSecTrustRef trust(NULL);
  OSStatus status = SecTrustCreateWithCertificates(cert_chain.get(),
                                                   policy.get(), trust.ptr());
  if (status != noErr) {
    return ctx->verify_cb(0, ctx);
  }

  // If the user provided any additional CA certificates, add them to the trust
  // object.
  if (CFArrayGetCount(trusted_certs.get()) > 0) {
    status = SecTrustSetAnchorCertificates(trust.get(), trusted_certs.get());
    if (status != noErr) {
      return ctx->verify_cb(0, ctx);
    }
  }

  // Specify whether or not to use the built-in CA certificates for
  // verification.
  status =
      SecTrustSetAnchorCertificatesOnly(trust.get(), !context->trust_builtin());
  if (status != noErr) {
    return ctx->verify_cb(0, ctx);
  }

  // Perform the certificate verification.
  SecTrustResultType trust_result;
  status = SecTrustEvaluate(trust.get(), &trust_result);
  if (status != noErr) {
    return ctx->verify_cb(0, ctx);
  }

  if ((trust_result == kSecTrustResultProceed) ||
      (trust_result == kSecTrustResultUnspecified)) {
    // Successfully verified certificate!
    return ctx->verify_cb(1, ctx);
  }

  // Set current_cert to the root of the certificate chain. This will be passed
  // to the callback provided by the user for additional verification steps.
  ctx->current_cert = root_cert;
  return ctx->verify_cb(0, ctx);
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  SSL_CTX* ctx = SSL_get_SSL_CTX(ssl);
  SSL_CTX_set_cert_verify_callback(ctx, CertificateVerificationCallback, this);
}

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
  set_trust_builtin(true);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_MACOS)
#endif  // !defined(DART_IO_DISABLED) &&
        // !defined(DART_IO_SECURE_SOCKET_DISABLED)
