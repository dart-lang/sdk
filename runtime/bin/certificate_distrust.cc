// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/certificate_distrust.h"

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include <openssl/mem.h>
#include <openssl/sha.h>

namespace dart {
namespace bin {

// SHA-256 of the complete DER SubjectPublicKeyInfo, including its SEQUENCE
// tag and length. These eight keys are also distrusted by Go and rustls:
// https://github.com/golang/go/commit/7f86f957633ee31a1c17a1eb8452ca7a3d9bc141
// https://github.com/rustls/webpki/pull/546
// Match keys rather than certificate names, serial numbers, or fingerprints,
// so reissued and cross-signed certificates containing these keys are covered.
static constexpr uint8_t kDistrustedSPKIHashes[][SHA256_DIGEST_LENGTH] = {
    // EMDVTLSCAG3B
    {0xeb, 0xed, 0x64, 0x75, 0xc2, 0xc2, 0xd8, 0x0f, 0xcb, 0x19, 0x9f,
     0x3f, 0xe8, 0xdd, 0x6e, 0x6b, 0x3c, 0xe6, 0x0b, 0x77, 0xeb, 0x15,
     0xd4, 0xe4, 0x2c, 0x3d, 0xec, 0x0c, 0x6f, 0x5b, 0x51, 0x05},
    // EMDVTLSCAG3C
    {0x49, 0xdd, 0x35, 0x3d, 0xc2, 0xb9, 0x19, 0xa3, 0x77, 0x06, 0x45,
     0x11, 0x7d, 0x0e, 0x60, 0xc1, 0x61, 0x15, 0xe7, 0xd1, 0xbc, 0x25,
     0x9e, 0xef, 0xe7, 0x34, 0xb0, 0x0e, 0xa4, 0x34, 0xfe, 0x5f},
    // EMEVTLSCAG3B
    {0xe0, 0x25, 0x4c, 0x7f, 0xcd, 0xc2, 0x65, 0xe2, 0xf0, 0xf8, 0xa4,
     0x28, 0xda, 0xbb, 0x75, 0xab, 0x4a, 0xe0, 0x39, 0xb4, 0x87, 0x2d,
     0x62, 0xf5, 0xee, 0x57, 0xf0, 0x87, 0x7d, 0x5a, 0x8a, 0x41},
    // EMEVTLSCAG3C
    {0x5c, 0x06, 0x60, 0xa2, 0xb1, 0x64, 0x91, 0x0d, 0x8f, 0xf5, 0x89,
     0xc1, 0x8e, 0x14, 0x55, 0x2e, 0x9e, 0x0e, 0xc2, 0x37, 0xdc, 0xef,
     0xe2, 0xcb, 0x73, 0x6d, 0x41, 0xa4, 0x81, 0x1f, 0x81, 0xa0},
    // EMOVTLSCAG3B
    {0x43, 0xbf, 0xfa, 0x19, 0xd6, 0xef, 0x65, 0x14, 0x51, 0xf6, 0x84,
     0x1e, 0x01, 0x99, 0x31, 0xe9, 0x6f, 0x6f, 0x2e, 0xae, 0xff, 0x28,
     0xab, 0x4b, 0x6f, 0x1c, 0xe4, 0x57, 0x6d, 0xe2, 0x71, 0x7b},
    // EMOVTLSCAG3C
    {0x63, 0xec, 0xef, 0xee, 0x43, 0x1d, 0x49, 0x52, 0x3b, 0xc1, 0x13,
     0x6c, 0x4e, 0x72, 0xd0, 0x20, 0x6a, 0x47, 0x70, 0x86, 0xca, 0xf6,
     0x06, 0xcd, 0x5c, 0xf0, 0x25, 0x68, 0x6c, 0x10, 0x9c, 0xf8},
    // EMOVCSCAG3B
    {0xec, 0x4f, 0xfa, 0x1a, 0xd0, 0xac, 0x88, 0x08, 0x13, 0x14, 0xb7,
     0xaa, 0xff, 0xef, 0x6a, 0x91, 0xf9, 0x7c, 0xd5, 0x72, 0x91, 0xbb,
     0x5b, 0xa6, 0x86, 0xc5, 0x41, 0x5f, 0x5e, 0xb4, 0xf6, 0xb6},
    // EMOVCSCAG3C
    {0x92, 0xc0, 0x63, 0xd6, 0x7e, 0x8f, 0x14, 0xdb, 0x71, 0xd2, 0x88,
     0xe1, 0x12, 0x66, 0xff, 0xda, 0xf6, 0x9c, 0xbf, 0x11, 0x5f, 0x7b,
     0xab, 0x14, 0xf3, 0xbc, 0x2f, 0x68, 0xd2, 0x5e, 0x0e, 0x30},
};

int CertificateDistrust::CheckCertificate(const X509* certificate) {
  if (certificate == nullptr) {
    return X509_V_ERR_UNSPECIFIED;
  }
  uint8_t* der = nullptr;
  const int length = i2d_X509_PUBKEY(X509_get_X509_PUBKEY(certificate), &der);
  if (length <= 0) {
    OPENSSL_free(der);
    return X509_V_ERR_UNSPECIFIED;
  }
  uint8_t digest[SHA256_DIGEST_LENGTH];
  SHA256(der, length, digest);
  OPENSSL_free(der);
  for (const auto& distrusted : kDistrustedSPKIHashes) {
    if (memcmp(digest, distrusted, sizeof(digest)) == 0) {
      return X509_V_ERR_CERT_REJECTED;
    }
  }
  return X509_V_OK;
}

int CertificateDistrust::CheckChain(const STACK_OF(X509) * chain) {
  if (chain == nullptr || sk_X509_num(chain) == 0) {
    return X509_V_ERR_UNSPECIFIED;
  }
  for (size_t i = 0; i < sk_X509_num(chain); i++) {
    const int error = CheckCertificate(sk_X509_value(chain, i));
    if (error != X509_V_OK) {
      return error;
    }
  }
  return X509_V_OK;
}

int CertificateDistrust::VerifyChain(
    X509_STORE_CTX* store_ctx,
    int (*on_bad_certificate)(int, X509_STORE_CTX*)) {
  if (X509_verify_cert(store_ctx) != 1) {
    return 0;
  }
  // Inspect the selected path, not the peer's untrusted certificate list:
  // unused certificates must not invalidate an otherwise valid path.
  const int error = CheckChain(X509_STORE_CTX_get0_chain(store_ctx));
  if (error == X509_V_OK) {
    return 1;
  }
  X509_STORE_CTX_set_error(store_ctx, error);
  return error == X509_V_ERR_CERT_REJECTED && on_bad_certificate != nullptr
             ? on_bad_certificate(0, store_ctx)
             : 0;
}

#if defined(DART_HOST_OS_MACOS)
static CFArrayRef CopyEvaluatedChain(SecTrustRef trust) {
  if (__builtin_available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)) {
    return SecTrustCopyCertificateChain(trust);
  }
  // Older supported systems do not have SecTrustCopyCertificateChain. The
  // caller owns this trust object exclusively for the duration of evaluation.
  const CFIndex count = SecTrustGetCertificateCount(trust);
  CFMutableArrayRef chain =
      CFArrayCreateMutable(nullptr, count, &kCFTypeArrayCallBacks);
  if (chain == nullptr) {
    return nullptr;
  }
  for (CFIndex i = 0; i < count; i++) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, i);
#pragma clang diagnostic pop
    if (certificate == nullptr) {
      CFRelease(chain);
      return nullptr;
    }
    CFArrayAppendValue(chain, certificate);
  }
  return chain;
}

int CertificateDistrust::CheckTrust(SecTrustRef trust) {
  if (trust == nullptr) {
    return X509_V_ERR_UNSPECIFIED;
  }
  CFArrayRef chain = CopyEvaluatedChain(trust);
  if (chain == nullptr) {
    return X509_V_ERR_UNSPECIFIED;
  }
  int error = X509_V_ERR_UNSPECIFIED;
  const CFIndex count = CFArrayGetCount(chain);
  for (CFIndex i = 0; i < count; i++) {
    auto certificate = static_cast<SecCertificateRef>(
        const_cast<void*>(CFArrayGetValueAtIndex(chain, i)));
    CFDataRef der = SecCertificateCopyData(certificate);
    if (der == nullptr) {
      error = X509_V_ERR_UNSPECIFIED;
      break;
    }
    const uint8_t* data = CFDataGetBytePtr(der);
    const uint8_t* end = data + CFDataGetLength(der);
    bssl::UniquePtr<X509> x509(d2i_X509(nullptr, &data, CFDataGetLength(der)));
    error = data == end ? CheckCertificate(x509.get()) : X509_V_ERR_UNSPECIFIED;
    CFRelease(der);
    if (error != X509_V_OK) {
      break;
    }
  }
  CFRelease(chain);
  return error;
}
#endif

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
