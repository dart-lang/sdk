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

static ssl_verify_result_t CertificateVerificationCallback(SSL* ssl,
                                                           uint8_t* out_alert) {
  SSLFilter* filter = static_cast<SSLFilter*>(
      SSL_get_ex_data(ssl, SSLFilter::filter_ssl_index));
  SSLCertContext* context = static_cast<SSLCertContext*>(
      SSL_get_ex_data(ssl, SSLFilter::ssl_cert_context_index));

  const X509TrustState* certificate_trust_state =
      filter->certificate_trust_state();
  if (certificate_trust_state != nullptr) {
    // Callback have been previously called to explicitly evaluate root_cert.
    STACK_OF(X509)* unverified = sk_X509_dup(SSL_get_peer_full_cert_chain(ssl));
    X509* root_cert = nullptr;
    for (uintptr_t i = sk_X509_num(unverified); i > 0; i--) {
      root_cert = sk_X509_shift(unverified);
      if (root_cert == nullptr) {
        break;
      }
    }
    if (certificate_trust_state->x509() == root_cert) {
      return certificate_trust_state->is_trusted() ? ssl_verify_ok
                                                   : ssl_verify_invalid;
    }
  }

  STACK_OF(X509)* unverified = sk_X509_dup(SSL_get_peer_full_cert_chain(ssl));

  // Convert BoringSSL formatted certificates to SecCertificate certificates.
  ScopedCFMutableArrayRef cert_chain(NULL);
  X509* root_cert = NULL;
  int num_certs = sk_X509_num(unverified);
  int current_cert = 0;
  cert_chain.set(CFArrayCreateMutable(NULL, num_certs, NULL));
  X509* ca;
  while ((ca = sk_X509_shift(unverified)) != NULL) {
    ScopedSecCertificateRef cert(CreateSecCertificateFromX509(ca));
    if (cert == NULL) {
      return ssl_verify_invalid;
    }
    CFArrayAppendValue(cert_chain.get(), cert.release());
    ++current_cert;

    if (current_cert == num_certs) {
      root_cert = ca;
    }
  }

  SSL_CTX* ssl_ctx = SSL_get_SSL_CTX(ssl);
  X509_STORE* store = SSL_CTX_get_cert_store(ssl_ctx);
  // Convert all trusted certificates provided by the user via
  // setTrustedCertificatesBytes or the command line into SecCertificates.
  ScopedCFMutableArrayRef trusted_certs(CFArrayCreateMutable(NULL, 0, NULL));
  ASSERT(store != NULL);

  if (store->objs != NULL) {
    for (uintptr_t i = 0; i < sk_X509_OBJECT_num(store->objs); ++i) {
      X509* ca = sk_X509_OBJECT_value(store->objs, i)->data.x509;
      ScopedSecCertificateRef cert(CreateSecCertificateFromX509(ca));
      if (cert == NULL) {
        return ssl_verify_invalid;
      }
      CFArrayAppendValue(trusted_certs.get(), cert.release());
    }
  }

  // Generate a policy for validating chains for SSL.
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
    return ssl_verify_invalid;
  }

  // If the user provided any additional CA certificates, add them to the trust
  // object.
  if (CFArrayGetCount(trusted_certs.get()) > 0) {
    status = SecTrustSetAnchorCertificates(trust.get(), trusted_certs.get());
    if (status != noErr) {
      return ssl_verify_invalid;
    }
  }

  // Specify whether or not to use the built-in CA certificates for
  // verification.
  status =
      SecTrustSetAnchorCertificatesOnly(trust.get(), !context->trust_builtin());
  if (status != noErr) {
    return ssl_verify_invalid;
  }

  // Handler should release trust and root_cert.
  Dart_CObject dart_cobject_trust;
  dart_cobject_trust.type = Dart_CObject_kInt64;
  dart_cobject_trust.value.as_int64 =
      reinterpret_cast<intptr_t>(CFRetain(trust.get()));

  Dart_CObject dart_cobject_root_cert;
  dart_cobject_root_cert.type = Dart_CObject_kInt64;
  dart_cobject_root_cert.value.as_int64 = reinterpret_cast<intptr_t>(root_cert);

  Dart_CObject reply_send_port;
  reply_send_port.type = Dart_CObject_kSendPort;
  reply_send_port.value.as_send_port.id = filter->reply_port();

  Dart_CObject array;
  array.type = Dart_CObject_kArray;
  array.value.as_array.length = 3;
  Dart_CObject* values[] = {&dart_cobject_trust, &dart_cobject_root_cert,
                            &reply_send_port};
  array.value.as_array.values = values;

  Dart_PostCObject(filter->trust_evaluate_reply_port(), &array);
  return ssl_verify_retry;
}

static void postReply(Dart_Port reply_port_id,
                      bool success,
                      X509* certificate = nullptr) {
  Dart_CObject dart_cobject_success;
  dart_cobject_success.type = Dart_CObject_kBool;
  dart_cobject_success.value.as_bool = success;

  Dart_CObject dart_cobject_certificate;
  dart_cobject_certificate.type = Dart_CObject_kInt64;
  dart_cobject_certificate.value.as_int64 =
      reinterpret_cast<intptr_t>(certificate);

  Dart_CObject array;
  array.type = Dart_CObject_kArray;
  array.value.as_array.length = 2;
  Dart_CObject* values[] = {&dart_cobject_success, &dart_cobject_certificate};
  array.value.as_array.values = values;

  Dart_PostCObject(reply_port_id, &array);
}

static void TrustEvaluateHandler(Dart_Port dest_port_id,
                                 Dart_CObject* message) {
  // This is used for testing to confirm that trust evaluation doesn't block
  // dart isolate.
  // First sleep exposes problem where ssl data structures are released/freed
  // by main isolate before this handler had a chance to access them.
  // Second sleep(below) is there to maintain same long delay of certificate
  // verification.
  if (SSLCertContext::long_ssl_cert_evaluation()) {
    usleep(2000 * 1000 /* 2 s*/);
  }

  CObjectArray request(message);
  ASSERT(request.Length() == 3);
  CObjectIntptr trust_cobject(request[0]);
  ScopedSecTrustRef trust(reinterpret_cast<SecTrustRef>(trust_cobject.Value()));
  CObjectIntptr root_cert_cobject(request[1]);
  X509* root_cert = reinterpret_cast<X509*>(root_cert_cobject.Value());
  CObjectSendPort reply_port(request[2]);
  Dart_Port reply_port_id = reply_port.Value();

  SecTrustResultType trust_result;
  if (SSLCertContext::long_ssl_cert_evaluation()) {
    usleep(3000 * 1000 /* 3 s*/);
  }

  // Perform the certificate verification.
#if ((defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && defined(__MAC_10_14_0) &&    \
      __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_14_0) ||                     \
     (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && defined(__IPHONE_12_0) &&   \
      _IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_12_0))
  // SecTrustEvaluateWithError available as of OSX 10.14 and iOS 12.
  // The result is ignored as we get more information from the following call to
  // SecTrustGetTrustResult which also happens to match the information we get
  // from calling SecTrustEvaluate.
  bool res = SecTrustEvaluateWithError(trust.get(), NULL);
  USE(res);
  OSStatus status = SecTrustGetTrustResult(trust.get(), &trust_result);
#else

  // SecTrustEvaluate is deprecated as of OSX 10.15 and iOS 13.
  OSStatus status = SecTrustEvaluate(trust.get(), &trust_result);
#endif

  postReply(reply_port_id,
            status == noErr && (trust_result == kSecTrustResultProceed ||
                                trust_result == kSecTrustResultUnspecified),
            root_cert);
}

void SSLCertContext::RegisterCallbacks(SSL* ssl) {
  SSL_set_custom_verify(ssl, SSL_VERIFY_PEER, CertificateVerificationCallback);
}

TrustEvaluateHandlerFunc SSLCertContext::GetTrustEvaluateHandler() const {
  return &TrustEvaluateHandler;
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
