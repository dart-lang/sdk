// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SECURE_SOCKET_H_
#define BIN_SECURE_SOCKET_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

#include <prinit.h>
#include <prerror.h>
#include <prnetdb.h>
#include <ssl.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

/*
 * SSLFilter encapsulates the NSS SSL(TLS) code in a filter, that communicates
 * with the containing _SecureFilterImpl Dart object through four shared
 * ExternalByteArray buffers, for reading and writing plaintext, and
 * reading and writing encrypted text.  The filter handles handshaking
 * and certificate verification.
 */
class SSLFilter {
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
        string_start_(NULL),
        string_length_(NULL),
        handshake_complete_(NULL),
        bad_certificate_callback_(NULL),
        in_handshake_(false),
        client_certificate_name_(NULL),
        filter_(NULL) { }

  void Init(Dart_Handle dart_this);
  void Connect(const char* host,
               RawAddr* raw_addr,
               int port,
               bool is_server,
               const char* certificate_name,
               bool request_client_certificate,
               bool require_client_certificate,
               bool send_client_certificate);
  void Destroy();
  void Handshake();
  void Renegotiate(bool use_session_cache,
                   bool request_client_certificate,
                   bool require_client_certificate);
  void RegisterHandshakeCompleteCallback(Dart_Handle handshake_complete);
  void RegisterBadCertificateCallback(Dart_Handle callback);
  Dart_Handle bad_certificate_callback() {
    return Dart_HandleFromPersistent(bad_certificate_callback_);
  }
  intptr_t ProcessReadPlaintextBuffer(int start, int end);
  intptr_t ProcessWritePlaintextBuffer(int start1, int end1,
                                       int start2, int end2);
  intptr_t ProcessReadEncryptedBuffer(int start, int end);
  intptr_t ProcessWriteEncryptedBuffer(int start, int end);
  bool ProcessAllBuffers(int starts[kNumBuffers],
                         int ends[kNumBuffers],
                         bool in_handshake);
  Dart_Handle PeerCertificate();
  static void InitializeLibrary(const char* certificate_database,
                                const char* password,
                                bool use_builtin_root_certificates,
                                bool report_duplicate_initialization = true);
  Dart_Handle callback_error;

  static CObject* ProcessFilterRequest(const CObjectArray& request);

 private:
  static const int kMemioBufferSize = 20 * KB;
  static bool library_initialized_;
  static const char* password_;
  static dart::Mutex* mutex_;  // To protect library initialization.

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
  char* client_certificate_name_;
  PRFileDesc* filter_;

  static bool isBufferEncrypted(int i) {
    return static_cast<BufferIndex>(i) >= kFirstEncrypted;
  }
  void InitializeBuffers(Dart_Handle dart_this);
  void InitializePlatformData();

  DISALLOW_COPY_AND_ASSIGN(SSLFilter);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_SECURE_SOCKET_H_
