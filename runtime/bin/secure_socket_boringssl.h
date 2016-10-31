// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURE_SOCKET_BORINGSSL_H_
#define RUNTIME_BIN_SECURE_SOCKET_BORINGSSL_H_

#if !defined(RUNTIME_BIN_SECURE_SOCKET_H_)
#error Do not include secure_socket_boringssl.h directly. Use secure_socket.h.
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/reference_counting.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

/* These are defined in root_certificates.cc. */
extern const unsigned char* root_certificates_pem;
extern unsigned int root_certificates_pem_length;

class SSLContext {
 public:
  explicit SSLContext(SSL_CTX* context) :
      context_(context),
      alpn_protocol_string_(NULL) {
  }

  ~SSLContext() {
    SSL_CTX_free(context_);
    if (alpn_protocol_string_ != NULL) {
      free(alpn_protocol_string_);
    }
  }

  SSL_CTX* context() const { return context_; }

  uint8_t* alpn_protocol_string() const { return alpn_protocol_string_; }
  void set_alpn_protocol_string(uint8_t* protocol_string) {
    if (alpn_protocol_string_ != NULL) {
      free(alpn_protocol_string_);
    }
    alpn_protocol_string_ = protocol_string;
  }

 private:
  SSL_CTX* context_;
  uint8_t* alpn_protocol_string_;

  DISALLOW_COPY_AND_ASSIGN(SSLContext);
};

/*
 * SSLFilter encapsulates the SSL(TLS) code in a filter, that communicates
 * with the containing _SecureFilterImpl Dart object through four shared
 * ExternalByteArray buffers, for reading and writing plaintext, and
 * reading and writing encrypted text.  The filter handles handshaking
 * and certificate verification.
 */
class SSLFilter : public ReferenceCounted<SSLFilter> {
 public:
  // These enums must agree with those in sdk/lib/io/secure_socket.dart.
  enum BufferIndex {
    kReadPlaintext,
    kWritePlaintext,
    kReadEncrypted,
    kWriteEncrypted,
    kNumBuffers,
    kFirstEncrypted = kReadEncrypted
  };

  SSLFilter()
      : callback_error(NULL),
        ssl_(NULL),
        socket_side_(NULL),
        string_start_(NULL),
        string_length_(NULL),
        handshake_complete_(NULL),
        bad_certificate_callback_(NULL),
        in_handshake_(false),
        hostname_(NULL) { }

  ~SSLFilter();

  Dart_Handle Init(Dart_Handle dart_this);
  void Connect(const char* hostname,
               SSL_CTX* context,
               bool is_server,
               bool request_client_certificate,
               bool require_client_certificate,
               Dart_Handle protocols_handle);
  void Destroy();
  void Handshake();
  void GetSelectedProtocol(Dart_NativeArguments args);
  void Renegotiate(bool use_session_cache,
                   bool request_client_certificate,
                   bool require_client_certificate);
  void RegisterHandshakeCompleteCallback(Dart_Handle handshake_complete);
  void RegisterBadCertificateCallback(Dart_Handle callback);
  Dart_Handle bad_certificate_callback() {
    return Dart_HandleFromPersistent(bad_certificate_callback_);
  }
  int ProcessReadPlaintextBuffer(int start, int end);
  int ProcessWritePlaintextBuffer(int start, int end);
  int ProcessReadEncryptedBuffer(int start, int end);
  int ProcessWriteEncryptedBuffer(int start, int end);
  bool ProcessAllBuffers(int starts[kNumBuffers],
                         int ends[kNumBuffers],
                         bool in_handshake);
  Dart_Handle PeerCertificate();
  static void InitializeLibrary();
  Dart_Handle callback_error;

  static CObject* ProcessFilterRequest(const CObjectArray& request);

  // The index of the external data field in _ssl that points to the SSLFilter.
  static int filter_ssl_index;

  // TODO(whesse): make private:
  SSL* ssl_;
  BIO* socket_side_;

 private:
  static bool library_initialized_;
  static Mutex* mutex_;  // To protect library initialization.

  uint8_t* buffers_[kNumBuffers];
  int buffer_size_;
  int encrypted_buffer_size_;
  Dart_PersistentHandle string_start_;
  Dart_PersistentHandle string_length_;
  Dart_PersistentHandle dart_buffer_objects_[kNumBuffers];
  Dart_PersistentHandle handshake_complete_;
  Dart_PersistentHandle bad_certificate_callback_;
  bool in_handshake_;
  bool is_server_;
  char* hostname_;

  static bool isBufferEncrypted(int i) {
    return static_cast<BufferIndex>(i) >= kFirstEncrypted;
  }
  Dart_Handle InitializeBuffers(Dart_Handle dart_this);
  void InitializePlatformData();

  DISALLOW_COPY_AND_ASSIGN(SSLFilter);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SECURE_SOCKET_BORINGSSL_H_
