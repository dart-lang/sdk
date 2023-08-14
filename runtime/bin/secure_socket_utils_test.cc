// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/secure_socket_utils.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {
namespace bin {

TEST_CASE(SecureSocketUtils_CertNotYetValid) {
  const char* valid_after_2121 =
      "-----BEGIN CERTIFICATE-----\n"
      "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\n"
      "q8uu\n"
      "-----END CERTIFICATE-----\n";
  size_t len = strlen(valid_after_2121);
  BIO* cert_bio = BIO_new(BIO_s_mem());
  BIO_write(cert_bio, valid_after_2121, len);
  X509* cert_X509 = PEM_read_bio_X509(cert_bio, nullptr, nullptr, nullptr);
  EXPECT(cert_X509 != nullptr);
  EXPECT(!SecureSocketUtils::IsCurrentTimeInsideCertValidDateRange(cert_X509));
  BIO_free(cert_bio);
  X509_free(cert_X509);
}

TEST_CASE(SecureSocketUtils_CertValid) {
  const char* valid_in_2021 =
      "-----BEGIN CERTIFICATE-----\n"
      "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\n"
      "dw==\n"
      "-----END CERTIFICATE-----\n";
  size_t len = strlen(valid_in_2021);
  BIO* cert_bio = BIO_new(BIO_s_mem());
  BIO_write(cert_bio, valid_in_2021, len);
  X509* cert_X509 = PEM_read_bio_X509(cert_bio, nullptr, nullptr, nullptr);
  EXPECT(cert_X509 != nullptr);
  EXPECT(SecureSocketUtils::IsCurrentTimeInsideCertValidDateRange(cert_X509));
  BIO_free(cert_bio);
  X509_free(cert_X509);
}

TEST_CASE(SecureSocketUtils_CertAlreadyExpired) {
  const char* valid_before_2021 =
      "-----BEGIN CERTIFICATE-----\n"
      "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\n"
      "-----END CERTIFICATE-----\n";
  size_t len = strlen(valid_before_2021);
  BIO* cert_bio = BIO_new(BIO_s_mem());
  BIO_write(cert_bio, valid_before_2021, len);
  X509* cert_X509 = PEM_read_bio_X509(cert_bio, nullptr, nullptr, nullptr);
  EXPECT(cert_X509 != nullptr);
  EXPECT(!SecureSocketUtils::IsCurrentTimeInsideCertValidDateRange(cert_X509));
  BIO_free(cert_bio);
  X509_free(cert_X509);
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
