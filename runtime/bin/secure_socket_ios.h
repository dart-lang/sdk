// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURE_SOCKET_IOS_H_
#define RUNTIME_BIN_SECURE_SOCKET_IOS_H_

#if !defined(RUNTIME_BIN_SECURE_SOCKET_H_)
#error Do not include secure_socket_macos.h directly. Use secure_socket.h.
#endif

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecureTransport.h>
#include <Security/Security.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/reference_counting.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

// SSLCertContext wraps the certificates needed for a SecureTransport
// connection. Fields are protected by the mutex_ field, and may only be set
// once. This is to allow access by both the Dart thread and the IOService
// thread. Setters return false if the field was already set.
class SSLCertContext : public ReferenceCounted<SSLCertContext> {
 public:
  SSLCertContext() :
      ReferenceCounted(),
      mutex_(new Mutex()),
      trusted_certs_(NULL),
      identity_(NULL),
      cert_chain_(NULL),
      trust_builtin_(false) {}

  ~SSLCertContext() {
    {
      MutexLocker m(mutex_);
      if (trusted_certs_ != NULL) {
        CFRelease(trusted_certs_);
      }
      if (identity_ != NULL) {
        CFRelease(identity_);
      }
      if (cert_chain_ != NULL) {
        CFRelease(cert_chain_);
      }
    }
    delete mutex_;
  }

  CFMutableArrayRef trusted_certs() {
    MutexLocker m(mutex_);
    return trusted_certs_;
  }
  void add_trusted_cert(SecCertificateRef trusted_cert) {
    // Takes ownership of trusted_cert.
    MutexLocker m(mutex_);
    if (trusted_certs_ == NULL) {
      trusted_certs_ = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    }
    CFArrayAppendValue(trusted_certs_, trusted_cert);
    CFRelease(trusted_cert);  // trusted_cert is retained by the array.
  }

  SecIdentityRef identity() {
    MutexLocker m(mutex_);
    return identity_;
  }
  bool set_identity(SecIdentityRef identity) {
    MutexLocker m(mutex_);
    if (identity_ == NULL) {
      identity_ = identity;
      return true;
    }
    return false;
  }

  CFArrayRef cert_chain() {
    MutexLocker m(mutex_);
    return cert_chain_;
  }
  bool set_cert_chain(CFArrayRef cert_chain) {
    MutexLocker m(mutex_);
    if (cert_chain_ == NULL) {
      cert_chain_ = cert_chain;
      return true;
    }
    return false;
  }

  bool trust_builtin() {
    MutexLocker m(mutex_);
    return trust_builtin_;
  }
  void set_trust_builtin(bool trust_builtin) {
    MutexLocker m(mutex_);
    trust_builtin_ = trust_builtin;
  }

 private:
  // The context is accessed both by Dart code and the IOService. This mutex
  // protects all fields.
  Mutex* mutex_;
  CFMutableArrayRef trusted_certs_;
  SecIdentityRef identity_;
  CFArrayRef cert_chain_;
  bool trust_builtin_;

  DISALLOW_COPY_AND_ASSIGN(SSLCertContext);
};

// SSLFilter encapsulates the SecureTransport code in a filter that communicates
// with the containing _SecureFilterImpl Dart object through four shared
// ExternalByteArray buffers, for reading and writing plaintext, and
// reading and writing encrypted text.  The filter handles handshaking
// and certificate verification.
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
      : ReferenceCounted(),
        cert_context_(NULL),
        ssl_context_(NULL),
        peer_certs_(NULL),
        string_start_(NULL),
        string_length_(NULL),
        handshake_complete_(NULL),
        bad_certificate_callback_(NULL),
        in_handshake_(false),
        connected_(false),
        bad_cert_(false),
        is_server_(false),
        hostname_(NULL) {
  }

  ~SSLFilter();

  // Callback called by the IOService.
  static CObject* ProcessFilterRequest(const CObjectArray& request);

  Dart_Handle Init(Dart_Handle dart_this);
  void Connect(Dart_Handle dart_this,
               const char* hostname,
               SSLCertContext* context,
               bool is_server,
               bool request_client_certificate,
               bool require_client_certificate);
  void Destroy();
  OSStatus CheckHandshake();
  void Renegotiate(bool use_session_cache,
                   bool request_client_certificate,
                   bool require_client_certificate);
  void RegisterHandshakeCompleteCallback(Dart_Handle handshake_complete);
  void RegisterBadCertificateCallback(Dart_Handle callback);
  Dart_Handle PeerCertificate();

 private:
  static OSStatus SSLReadCallback(SSLConnectionRef connection,
                                  void* data,
                                  size_t* data_length);
  static OSStatus SSLWriteCallback(SSLConnectionRef connection,
                                   const void* data,
                                   size_t* data_length);

  static bool isBufferEncrypted(intptr_t i) {
    return static_cast<BufferIndex>(i) >= kFirstEncrypted;
  }
  Dart_Handle InitializeBuffers(Dart_Handle dart_this);

  intptr_t GetBufferStart(intptr_t idx) const;
  intptr_t GetBufferEnd(intptr_t idx) const;
  void SetBufferStart(intptr_t idx, intptr_t value);
  void SetBufferEnd(intptr_t idx, intptr_t value);

  OSStatus ProcessAllBuffers(intptr_t starts[kNumBuffers],
                             intptr_t ends[kNumBuffers],
                             bool in_handshake);
  OSStatus ProcessReadPlaintextBuffer(intptr_t start,
                                      intptr_t end,
                                      intptr_t* bytes_processed);
  OSStatus ProcessWritePlaintextBuffer(intptr_t start,
                                       intptr_t end,
                                       intptr_t* bytes_processed);

  // These calls can block on IO, and should only be invoked from
  // from ProcessAllBuffers from ProcessFilterRequest.
  OSStatus EvaluatePeerTrust();
  OSStatus Handshake();
  Dart_Handle InvokeBadCertCallback(SecCertificateRef peer_cert);

  RetainedPointer<SSLCertContext> cert_context_;
  SSLContextRef ssl_context_;
  CFArrayRef peer_certs_;

  // starts and ends filled in at the start of ProcessAllBuffers.
  // If these are NULL, then try to get the pointers out of
  // dart_buffer_objects_.
  uint8_t* buffers_[kNumBuffers];
  intptr_t* buffer_starts_[kNumBuffers];
  intptr_t* buffer_ends_[kNumBuffers];
  intptr_t buffer_size_;
  intptr_t encrypted_buffer_size_;
  Dart_PersistentHandle string_start_;
  Dart_PersistentHandle string_length_;
  Dart_PersistentHandle dart_buffer_objects_[kNumBuffers];
  Dart_PersistentHandle handshake_complete_;
  Dart_PersistentHandle bad_certificate_callback_;
  bool in_handshake_;
  bool connected_;
  bool bad_cert_;
  bool is_server_;
  char* hostname_;

  DISALLOW_COPY_AND_ASSIGN(SSLFilter);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SECURE_SOCKET_IOS_H_
