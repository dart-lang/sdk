// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURITY_CONTEXT_H_
#define RUNTIME_BIN_SECURITY_CONTEXT_H_

#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/lockers.h"
#include "bin/reference_counting.h"
#include "bin/socket.h"

namespace dart {
namespace bin {

// Forward declaration
class SSLFilter;

class SSLCertContext : public ReferenceCounted<SSLCertContext> {
 public:
  static const intptr_t kApproximateSize;
  static const int kSecurityContextNativeFieldIndex = 0;
  static const int kX509NativeFieldIndex = 0;

  explicit SSLCertContext(SSL_CTX* context)
      : ReferenceCounted(),
        context_(context),
        alpn_protocol_string_(NULL),
        trust_builtin_(false) {}

  ~SSLCertContext() {
    SSL_CTX_free(context_);
    if (alpn_protocol_string_ != NULL) {
      free(alpn_protocol_string_);
    }
  }

  static int CertificateCallback(int preverify_ok, X509_STORE_CTX* store_ctx);

  static SSLCertContext* GetSecurityContext(Dart_NativeArguments args);
  static const char* GetPasswordArgument(Dart_NativeArguments args,
                                         intptr_t index);
  static void SetAlpnProtocolList(Dart_Handle protocols_handle,
                                  SSL* ssl,
                                  SSLCertContext* context,
                                  bool is_server);

  void SetTrustedCertificatesBytes(Dart_Handle cert_bytes,
                                   const char* password);

  void SetClientAuthoritiesBytes(Dart_Handle client_authorities_bytes,
                                 const char* password);

  int UseCertificateChainBytes(Dart_Handle cert_chain_bytes,
                               const char* password);

  void TrustBuiltinRoots();

  SSL_CTX* context() const { return context_; }

  uint8_t* alpn_protocol_string() const { return alpn_protocol_string_; }

  void set_alpn_protocol_string(uint8_t* protocol_string) {
    if (alpn_protocol_string_ != NULL) {
      free(alpn_protocol_string_);
    }
    alpn_protocol_string_ = protocol_string;
  }

  bool trust_builtin() const { return trust_builtin_; }

  void set_trust_builtin(bool trust_builtin) { trust_builtin_ = trust_builtin; }

  void RegisterCallbacks(SSL* ssl);

 private:
  void AddCompiledInCerts();
  void LoadRootCertFile(const char* file);
  void LoadRootCertCache(const char* cache);

  SSL_CTX* context_;
  uint8_t* alpn_protocol_string_;

  bool trust_builtin_;

  DISALLOW_COPY_AND_ASSIGN(SSLCertContext);
};


class X509Helper : public AllStatic {
 public:
  static Dart_Handle GetSubject(Dart_NativeArguments args);
  static Dart_Handle GetIssuer(Dart_NativeArguments args);
  static Dart_Handle GetStartValidity(Dart_NativeArguments args);
  static Dart_Handle GetEndValidity(Dart_NativeArguments args);
  static Dart_Handle WrappedX509Certificate(X509* certificate);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SECURITY_CONTEXT_H_
