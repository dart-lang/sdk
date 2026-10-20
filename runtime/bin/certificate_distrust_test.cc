// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/certificate_distrust.h"

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include <openssl/ec.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/mem.h>
#include <openssl/pem.h>
#include <openssl/x509v3.h>

#include "vm/unit_test.h"

namespace dart {
namespace bin {

// Public keys from rustls/webpki at
// f3caaa9f2ba94a42dcd31767e367688a416a3d87, src/data/distrusted/*.spki.der.
// Restore the outer SPKI SEQUENCE before PEM encoding. These are public keys
// only; certificates below are signed with unrelated, generated test keys.
static const char* const kDistrustedPublicKeys[] = {
    // EMDVTLSCAG3B
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE557ZwEqXc8RzXlERHahawr1eZKs3S4Dh\n"
    "LLwgOOweTw47gS/JhZ4eZ6+wTi+LyX90hbplqpEe6KTkW2LVzAPVa+Z4s8OMtNyT\n"
    "fKJGDiOEU8iSk10p1E+R4VYGtjzO2rRo\n"
    "-----END PUBLIC KEY-----\n",
    // EMDVTLSCAG3C
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEOnp4YsjETTJN3WkDOmeCwO/u/kBV5ooS\n"
    "P6A3G6O9kZRRTuFypDPjYw8CvRiAN9nlFJ+bd9uUooHfmHsv6oiLdL3+j9pMEJnu\n"
    "bKGVZv4+8OX2sJpVbMyLpQVh3xsqRB0B\n"
    "-----END PUBLIC KEY-----\n",
    // EMEVTLSCAG3B
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEJduoWmTTl9oLEFLp6lRuSHvv6pydnWig\n"
    "xerc/u91ppu11vwB9Cv7ym60C81kwHZ+Nv/QXZeoE8WqDGyVMOec9fCGZGjxOAZC\n"
    "CqXIUYQLHiUlQOeQ5LZUw4Uu1krx6GV9\n"
    "-----END PUBLIC KEY-----\n",
    // EMEVTLSCAG3C
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAELVboKab7gsZKRpfZYK+VHpBnrpH5JtND\n"
    "BtpIqKrreGm2pn5tJ0JuBEKqA7NuGYjf9jZRTuHPB/W6Sz/yoGZFrn0x1YZq0xqj\n"
    "0kbrCzF37pnLdWbFFs50gIpmj5HwxH/K\n"
    "-----END PUBLIC KEY-----\n",
    // EMOVTLSCAG3B
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEc4l6oOs8/cqLEkAv+vCrxOEhK6+N7neK\n"
    "ye4tbbg/rCgMXgVjiueirNccMiqONhzeufacQwK53Y1z0cxsqrLMCu5OIWzped1R\n"
    "ikr0tiblaEzdZYA37QyFTkzBL0z4ZG0N\n"
    "-----END PUBLIC KEY-----\n",
    // EMOVTLSCAG3C
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEE4JRzVKskpjByKrZdzId65fnCb0LTKCs\n"
    "pV3IrVHc/J0ViaFZfjpRIOHv1jHGPhg1ysrimGmmLhYx6KKBgatWYW3EXZGKvAnz\n"
    "qw5jz3kqpNztc4e+N7ulaVSfHAKycO1n\n"
    "-----END PUBLIC KEY-----\n",
    // EMOVCSCAG3B
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEqrsPsGZqz88B+tUr/P1MK/LLPDSX3nOV\n"
    "DlgZth/mlQmHQcjEkUObNKBDHK/+W/m0wcjorgAB+fTcitgsWfNjnpbNbD1NsM7+\n"
    "wmw9YlF7N3YTcnQ/jordd7EAZPKr5eBQ\n"
    "-----END PUBLIC KEY-----\n",
    // EMOVCSCAG3C
    "-----BEGIN PUBLIC KEY-----\n"
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEufDgY0cCppymqt1EPP1ixBubpLIJJGl9\n"
    "eXTnaRoSb7lq+z40wv07xfSDBh8mXcKlhDY0cyNRBDayjwTzhiNjBnmA4lA+AlMt\n"
    "ZUYjWnFlolmh70lvdBtf3ud4cgjkuPrv\n"
    "-----END PUBLIC KEY-----\n",
};

static constexpr time_t kVerificationTime = 1767225600;  // 2026-01-01 UTC.

static bssl::UniquePtr<EVP_PKEY> GenerateKey() {
  bssl::UniquePtr<EC_KEY> ec(EC_KEY_new_by_curve_name(NID_X9_62_prime256v1));
  EXPECT_EQ(1, EC_KEY_generate_key(ec.get()));
  bssl::UniquePtr<EVP_PKEY> key(EVP_PKEY_new());
  EXPECT_EQ(1, EVP_PKEY_assign_EC_KEY(key.get(), ec.release()));
  return key;
}

static bssl::UniquePtr<EVP_PKEY> ReadPublicKey(const char* pem) {
  bssl::UniquePtr<BIO> bio(BIO_new_mem_buf(pem, -1));
  bssl::UniquePtr<EVP_PKEY> key(
      PEM_read_bio_PUBKEY(bio.get(), nullptr, nullptr, nullptr));
  EXPECT(key != nullptr);
  return key;
}

static void AddExtension(X509* cert, int nid, const char* value) {
  bssl::UniquePtr<X509_EXTENSION> ext(
      X509V3_EXT_nconf_nid(nullptr, nullptr, nid, value));
  EXPECT(ext != nullptr);
  EXPECT_EQ(1, X509_add_ext(cert, ext.get(), -1));
}

static bssl::UniquePtr<X509> MakeCertificate(EVP_PKEY* key,
                                             const char* name,
                                             long serial,
                                             bool is_ca,
                                             X509* issuer,
                                             EVP_PKEY* signing_key) {
  bssl::UniquePtr<X509> cert(X509_new());
  EXPECT_EQ(1, X509_set_version(cert.get(), 2));
  EXPECT_EQ(1, ASN1_INTEGER_set(X509_get_serialNumber(cert.get()), serial));
  // Keep leaf validity short enough for Apple's SSL policy while covering
  // kVerificationTime. CA certificates retain their longer validity period.
  const char* not_before = is_ca ? "20250101000000Z" : "20251201000000Z";
  const char* not_after = is_ca ? "20300101000000Z" : "20260201000000Z";
  EXPECT_EQ(1, ASN1_TIME_set_string(X509_getm_notBefore(cert.get()), not_before));
  EXPECT_EQ(1, ASN1_TIME_set_string(X509_getm_notAfter(cert.get()), not_after));
  EXPECT_EQ(1, X509_set_pubkey(cert.get(), key));
  EXPECT_EQ(1, X509_NAME_add_entry_by_txt(
                   X509_get_subject_name(cert.get()), "CN", MBSTRING_ASC,
                   reinterpret_cast<const uint8_t*>(name), -1, -1, 0));
  EXPECT_EQ(1, X509_set_issuer_name(
                   cert.get(), X509_get_subject_name(
                                   issuer == nullptr ? cert.get() : issuer)));
  AddExtension(cert.get(), NID_basic_constraints,
               is_ca ? "critical,CA:TRUE" : "critical,CA:FALSE");
  AddExtension(cert.get(), NID_key_usage,
               is_ca ? "critical,keyCertSign,cRLSign" : "digitalSignature");
  if (!is_ca) {
    AddExtension(cert.get(), NID_subject_alt_name, "DNS:localhost");
    AddExtension(cert.get(), NID_ext_key_usage, "serverAuth,clientAuth");
  }
  EXPECT(X509_sign(cert.get(), signing_key, EVP_sha256()) > 0);
  return cert;
}

UNIT_TEST_CASE(CertificateDistrust_PublicKeys) {
  auto signer = GenerateKey();
  auto root = MakeCertificate(signer.get(), "Test root", 1, true, nullptr,
                              signer.get());
  EXPECT_EQ(X509_V_OK, CertificateDistrust::CheckCertificate(root.get()));
  for (const char* pem : kDistrustedPublicKeys) {
    auto key = ReadPublicKey(pem);
    auto cert = MakeCertificate(key.get(), "localhost", 2, false, root.get(),
                                signer.get());
    EXPECT_EQ(1, X509_verify(cert.get(), signer.get()));
    EXPECT_EQ(X509_V_ERR_CERT_REJECTED,
              CertificateDistrust::CheckCertificate(cert.get()));

    // Different issuer, subject, serial, and signature, but the same SPKI.
    auto other_signer = GenerateKey();
    auto other_root = MakeCertificate(other_signer.get(), "Other root", 3, true,
                                      nullptr, other_signer.get());
    auto reissued = MakeCertificate(key.get(), "Reissued CA", 4, true,
                                    other_root.get(), other_signer.get());
    EXPECT_EQ(1, X509_verify(reissued.get(), other_signer.get()));
    EXPECT_EQ(X509_V_ERR_CERT_REJECTED,
              CertificateDistrust::CheckCertificate(reissued.get()));
  }
}

UNIT_TEST_CASE(CertificateDistrust_ChainPositions) {
  auto key = GenerateKey();
  auto good = MakeCertificate(key.get(), "Good", 1, true, nullptr, key.get());
  for (const char* pem : kDistrustedPublicKeys) {
    auto bad_key = ReadPublicKey(pem);
    auto bad =
        MakeCertificate(bad_key.get(), "Bad", 2, true, good.get(), key.get());
    // Check the leaf, intermediate, and trust anchor positions independently.
    for (size_t bad_position = 0; bad_position < 3; bad_position++) {
      bssl::UniquePtr<STACK_OF(X509)> chain(sk_X509_new_null());
      for (size_t i = 0; i < 3; i++) {
        EXPECT(sk_X509_push(
            chain.get(),
            bssl::UpRef(i == bad_position ? bad.get() : good.get()).release()));
      }
      EXPECT_EQ(X509_V_ERR_CERT_REJECTED,
                CertificateDistrust::CheckChain(chain.get()));
    }
  }
}

UNIT_TEST_CASE(CertificateDistrust_InvalidInput) {
  EXPECT_EQ(X509_V_ERR_UNSPECIFIED,
            CertificateDistrust::CheckCertificate(nullptr));
  bssl::UniquePtr<X509> empty(X509_new());
  EXPECT_EQ(X509_V_ERR_UNSPECIFIED,
            CertificateDistrust::CheckCertificate(empty.get()));
  ERR_clear_error();
  EXPECT_EQ(X509_V_ERR_UNSPECIFIED, CertificateDistrust::CheckChain(nullptr));
  bssl::UniquePtr<STACK_OF(X509)> chain(sk_X509_new_null());
  EXPECT_EQ(X509_V_ERR_UNSPECIFIED,
            CertificateDistrust::CheckChain(chain.get()));
}

static bssl::UniquePtr<X509_STORE_CTX> MakeStoreContext(X509_STORE* store,
                                                        X509* leaf,
                                                        STACK_OF(X509) *
                                                            untrusted) {
  bssl::UniquePtr<X509_STORE_CTX> ctx(X509_STORE_CTX_new());
  EXPECT_EQ(1, X509_STORE_CTX_init(ctx.get(), store, leaf, untrusted));
  X509_VERIFY_PARAM_set_time(X509_STORE_CTX_get0_param(ctx.get()),
                             kVerificationTime);
  return ctx;
}

static int RejectDistrustedCertificate(int ok, X509_STORE_CTX* ctx) {
  EXPECT_EQ(0, ok);
  EXPECT_EQ(X509_V_ERR_CERT_REJECTED, X509_STORE_CTX_get_error(ctx));
  return 0;
}

static int AcceptDistrustedCertificate(int ok, X509_STORE_CTX* ctx) {
  EXPECT_EQ(0, ok);
  EXPECT_EQ(X509_V_ERR_CERT_REJECTED, X509_STORE_CTX_get_error(ctx));
  return 1;
}

UNIT_TEST_CASE(CertificateDistrust_VerifyChain) {
  auto root_key = GenerateKey();
  auto root =
      MakeCertificate(root_key.get(), "Root", 1, true, nullptr, root_key.get());
  bssl::UniquePtr<X509_STORE> store(X509_STORE_new());
  EXPECT_EQ(1, X509_STORE_add_cert(store.get(), root.get()));
  for (const char* pem : kDistrustedPublicKeys) {
    auto key = ReadPublicKey(pem);
    auto leaf = MakeCertificate(key.get(), "localhost", 2, false, root.get(),
                                root_key.get());
    // The test root can sign a certificate containing the public key without
    // possession of the corresponding private key. Ordinary validation passes.
    auto ordinary = MakeStoreContext(store.get(), leaf.get(), nullptr);
    EXPECT_EQ(1, X509_verify_cert(ordinary.get()));
    auto rejected = MakeStoreContext(store.get(), leaf.get(), nullptr);
    EXPECT_EQ(0, CertificateDistrust::VerifyChain(rejected.get(), nullptr));
    EXPECT_EQ(X509_V_ERR_CERT_REJECTED,
              X509_STORE_CTX_get_error(rejected.get()));
    auto callback_rejected = MakeStoreContext(store.get(), leaf.get(), nullptr);
    EXPECT_EQ(0, CertificateDistrust::VerifyChain(callback_rejected.get(),
                                                  RejectDistrustedCertificate));
    auto callback_accepted = MakeStoreContext(store.get(), leaf.get(), nullptr);
    EXPECT_EQ(1, CertificateDistrust::VerifyChain(callback_accepted.get(),
                                                  AcceptDistrustedCertificate));
  }
}

UNIT_TEST_CASE(CertificateDistrust_UnusedCertificates) {
  auto root_key = GenerateKey();
  auto root =
      MakeCertificate(root_key.get(), "Root", 1, true, nullptr, root_key.get());
  auto leaf_key = GenerateKey();
  auto leaf = MakeCertificate(leaf_key.get(), "localhost", 2, false, root.get(),
                              root_key.get());
  bssl::UniquePtr<X509_STORE> store(X509_STORE_new());
  EXPECT_EQ(1, X509_STORE_add_cert(store.get(), root.get()));
  bssl::UniquePtr<STACK_OF(X509)> untrusted(sk_X509_new_null());
  for (const char* pem : kDistrustedPublicKeys) {
    auto key = ReadPublicKey(pem);
    auto unused = MakeCertificate(key.get(), "Unused", 3, true, root.get(),
                                  root_key.get());
    // Neither an unused peer certificate nor an unused trusted certificate
    // should cause a valid path to be rejected.
    EXPECT_EQ(1, X509_STORE_add_cert(store.get(), unused.get()));
    EXPECT(sk_X509_push(untrusted.get(), unused.release()));
  }
  auto ctx = MakeStoreContext(store.get(), leaf.get(), untrusted.get());
  EXPECT_EQ(1, CertificateDistrust::VerifyChain(ctx.get(), nullptr));
  EXPECT_EQ(2u, sk_X509_num(X509_STORE_CTX_get0_chain(ctx.get())));

  // Adding the distrust check must not bypass ordinary chain validation.
  bssl::UniquePtr<X509_STORE> empty_store(X509_STORE_new());
  auto unknown = MakeStoreContext(empty_store.get(), leaf.get(), nullptr);
  EXPECT_EQ(0, CertificateDistrust::VerifyChain(unknown.get(),
                                                AcceptDistrustedCertificate));
  EXPECT_NE(X509_V_OK, X509_STORE_CTX_get_error(unknown.get()));
}

UNIT_TEST_CASE(CertificateDistrust_PartialChainAnchor) {
  auto root_key = GenerateKey();
  auto root =
      MakeCertificate(root_key.get(), "Root", 1, true, nullptr, root_key.get());
  for (const char* pem : kDistrustedPublicKeys) {
    auto key = ReadPublicKey(pem);
    auto anchor = MakeCertificate(key.get(), "Explicitly trusted CA", 2, true,
                                  root.get(), root_key.get());
    bssl::UniquePtr<X509_STORE> store(X509_STORE_new());
    EXPECT_EQ(1, X509_STORE_add_cert(store.get(), anchor.get()));
    // Dart permits chains ending at a user-supplied intermediate. Explicit
    // trust in such a certificate must not disable the SPKI distrust policy.
    auto ordinary = MakeStoreContext(store.get(), anchor.get(), nullptr);
    X509_VERIFY_PARAM_set_flags(X509_STORE_CTX_get0_param(ordinary.get()),
                                X509_V_FLAG_PARTIAL_CHAIN);
    EXPECT_EQ(1, X509_verify_cert(ordinary.get()));
    auto ctx = MakeStoreContext(store.get(), anchor.get(), nullptr);
    X509_VERIFY_PARAM_set_flags(X509_STORE_CTX_get0_param(ctx.get()),
                                X509_V_FLAG_PARTIAL_CHAIN);
    EXPECT_EQ(0, CertificateDistrust::VerifyChain(ctx.get(), nullptr));
    EXPECT_EQ(X509_V_ERR_CERT_REJECTED, X509_STORE_CTX_get_error(ctx.get()));
  }
}

#if defined(DART_HOST_OS_MACOS)
static SecCertificateRef ToSecCertificate(X509* certificate) {
  uint8_t* bytes = nullptr;
  const int length = i2d_X509(certificate, &bytes);
  EXPECT(length > 0);
  CFDataRef der = CFDataCreate(nullptr, bytes, length);
  OPENSSL_free(bytes);
  SecCertificateRef result = SecCertificateCreateWithData(nullptr, der);
  CFRelease(der);
  EXPECT(result != nullptr);
  return result;
}

static int CheckAppleTrust(X509* leaf, X509* root, bool expect_trusted) {
  SecCertificateRef sec_leaf = ToSecCertificate(leaf);
  SecCertificateRef sec_root = ToSecCertificate(root);
  const void* roots[] = {sec_root};
  CFArrayRef anchors = CFArrayCreate(nullptr, roots, 1, &kCFTypeArrayCallBacks);
  SecPolicyRef policy = SecPolicyCreateSSL(true, CFSTR("localhost"));
  SecTrustRef trust = nullptr;
  EXPECT_EQ(errSecSuccess,
            SecTrustCreateWithCertificates(sec_leaf, policy, &trust));
  EXPECT_EQ(errSecSuccess, SecTrustSetAnchorCertificates(trust, anchors));
  EXPECT_EQ(errSecSuccess, SecTrustSetAnchorCertificatesOnly(trust, true));
  EXPECT_EQ(errSecSuccess, SecTrustSetNetworkFetchAllowed(trust, false));
  CFDateRef date = CFDateCreate(
      nullptr, kVerificationTime - kCFAbsoluteTimeIntervalSince1970);
  EXPECT_EQ(errSecSuccess, SecTrustSetVerifyDate(trust, date));
  SecTrustResultType result;
  EXPECT_EQ(errSecSuccess, SecTrustGetTrustResult(trust, &result));
  if (expect_trusted) {
    EXPECT(result == kSecTrustResultProceed ||
           result == kSecTrustResultUnspecified);
    // The root was not in the peer's certificate list, but must be inspected.
    EXPECT_EQ(2, SecTrustGetCertificateCount(trust));
  }
  const int error = CertificateDistrust::CheckTrust(trust);
  CFRelease(date);
  CFRelease(trust);
  CFRelease(policy);
  CFRelease(anchors);
  CFRelease(sec_root);
  CFRelease(sec_leaf);
  return error;
}

UNIT_TEST_CASE(CertificateDistrust_AppleTrust) {
  auto root_key = GenerateKey();
  auto root =
      MakeCertificate(root_key.get(), "Root", 1, true, nullptr, root_key.get());
  auto leaf_key = GenerateKey();
  auto leaf = MakeCertificate(leaf_key.get(), "localhost", 2, false, root.get(),
                              root_key.get());
  EXPECT_EQ(X509_V_OK, CheckAppleTrust(leaf.get(), root.get(), true));
  for (const char* pem : kDistrustedPublicKeys) {
    auto key = ReadPublicKey(pem);
    auto blocked = MakeCertificate(key.get(), "localhost", 3, false, root.get(),
                                   root_key.get());
    // The platform may already distrust this key. Either way, Dart's check
    // must also reject it.
    EXPECT_EQ(X509_V_ERR_CERT_REJECTED,
              CheckAppleTrust(blocked.get(), root.get(), false));
  }
  EXPECT_EQ(X509_V_ERR_UNSPECIFIED, CertificateDistrust::CheckTrust(nullptr));
}
#endif

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
