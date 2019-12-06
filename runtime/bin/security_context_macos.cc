// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/security_context.h"

#include <Availability.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecureTransport.h>
#include <Security/Security.h>

#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/secure_socket_filter.h"

namespace dart {
namespace bin {

const intptr_t SSLCertContext::kApproximateSize = sizeof(SSLCertContext);

template <typename T>
class ScopedCFType {
 public:
  explicit ScopedCFType(T obj) : obj_(obj) {}

  ~ScopedCFType() {
    if (obj_ != NULL) {
      CFRelease(obj_);
    }
  }

  T get() { return obj_; }
  T* ptr() { return &obj_; }
  const T get() const { return obj_; }

  DART_WARN_UNUSED_RESULT T release() {
    T temp = obj_;
    obj_ = NULL;
    return temp;
  }

  void set(T obj) { obj_ = obj; }

  bool operator==(T other) { return other == get(); }

  bool operator!=(T other) { return other != get(); }

 private:
  T obj_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedCFType);
};

static void releaseObjects(const void* val, void* context) {
  CFRelease(val);
}

template <>
ScopedCFType<CFMutableArrayRef>::~ScopedCFType() {
  if (obj_ != NULL) {
    CFIndex count = 0;
    CFArrayApplyFunction(obj_, CFRangeMake(0, CFArrayGetCount(obj_)),
                         releaseObjects, &count);
    CFRelease(obj_);
  }
}

typedef ScopedCFType<CFMutableArrayRef> ScopedCFMutableArrayRef;
typedef ScopedCFType<CFDataRef> ScopedCFDataRef;
typedef ScopedCFType<CFStringRef> ScopedCFStringRef;
typedef ScopedCFType<SecPolicyRef> ScopedSecPolicyRef;
typedef ScopedCFType<SecCertificateRef> ScopedSecCertificateRef;
typedef ScopedCFType<SecTrustRef> ScopedSecTrustRef;

static SecCertificateRef CreateSecCertificateFromX509(X509* cert) {
  if (cert == NULL) {
    return NULL;
  }
  int length = i2d_X509(cert, NULL);
  if (length < 0) {
    return NULL;
  }
  // This can be `std::make_unique<unsigned char[]>(length)` in C++14
  // But the Mac toolchain is still using C++11.
  auto deb_cert = std::unique_ptr<unsigned char[]>(new unsigned char[length]);
  unsigned char* temp = deb_cert.get();
  if (i2d_X509(cert, &temp) != length) {
    return NULL;
  }
  // TODO(bkonyi): we create a copy of the deb_cert here since it's unclear
  // whether or not SecCertificateCreateWithData takes ownership of the CFData.
  // Implementation here:
  // https://opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-55050.2/lib/SecCertificate.cpp.auto.html
  ScopedCFDataRef cert_buf(CFDataCreate(NULL, deb_cert.get(), length));
  return SecCertificateCreateWithData(NULL, cert_buf.get());
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
      ScopedSecCertificateRef cert(CreateSecCertificateFromX509(ca));
      if (cert == NULL) {
        return ctx->verify_cb(0, ctx);
      }
      CFArrayAppendValue(cert_chain.get(), cert.release());
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
      ScopedSecCertificateRef cert(CreateSecCertificateFromX509(ca));
      if (cert == NULL) {
        return ctx->verify_cb(0, ctx);
      }
      CFArrayAppendValue(trusted_certs.get(), cert.release());
    }
  }

  // Generate a policy for validating chains for SSL.
  const int ssl_index = SSL_get_ex_data_X509_STORE_CTX_idx();
  SSL* ssl = static_cast<SSL*>(X509_STORE_CTX_get_ex_data(ctx, ssl_index));
  SSLFilter* filter = static_cast<SSLFilter*>(
      SSL_get_ex_data(ssl, SSLFilter::filter_ssl_index));
  CFStringRef cfhostname = NULL;
  if (filter->hostname() != NULL) {
    cfhostname = CFStringCreateWithCString(NULL, filter->hostname(),
                                           kCFStringEncodingUTF8);
  }
  ScopedCFStringRef hostname(cfhostname);
  ScopedSecPolicyRef policy(
      SecPolicyCreateSSL(filter->is_client(), hostname.get()));

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

  SecTrustResultType trust_result;

  // Perform the certificate verification.
#if ((defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && defined(__MAC_10_14_0) &&    \
      __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_14_0) ||                     \
     (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && defined(__IPHONE_12_0) &&   \
      _IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_12_0))
  // SecTrustEvaluateWithError available as of OSX 10.14 and iOS 12.
  // The result is ignored as we get more information from the following call to
  // SecTrustGetTrustResult which also happens to match the information we get from calling
  // SecTrustEvaluate.
  bool res = SecTrustEvaluateWithError(trust.get(), NULL);
  USE(res);
  status = SecTrustGetTrustResult(trust.get(), &trust_result);
#else
  // SecTrustEvaluate is deprecated as of OSX 10.15 and iOS 13.
  status = SecTrustEvaluate(trust.get(), &trust_result);
#endif

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
  if (root_certs_file() != NULL) {
    LoadRootCertFile(root_certs_file());
    return;
  }
  if (root_certs_cache() != NULL) {
    LoadRootCertCache(root_certs_cache());
    return;
  }
  set_trust_builtin(true);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_MACOS)

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
