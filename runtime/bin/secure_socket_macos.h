// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SECURE_SOCKET_MACOS_H_
#define BIN_SECURE_SOCKET_MACOS_H_

#if !defined(BIN_SECURE_SOCKET_H_)
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
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

// Forward declaration of SSLContext.
class SSLCertContext;

// SSLFilter encapsulates the SecureTransport code in a filter that communicates
// with the containing _SecureFilterImpl Dart object through four shared
// ExternalByteArray buffers, for reading and writing plaintext, and
// reading and writing encrypted text.  The filter handles handshaking
// and certificate verification.
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
      : cert_context_(NULL),
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

  SSLCertContext* cert_context_;
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

// Where the argument to the constructor is the handle for an object
// implementing List<int>, this class creates a scope in which the memory
// backing the list can be accessed.
//
// Do not make Dart_ API calls while in a ScopedMemBuffer.
// Do not call Dart_PropagateError while in a ScopedMemBuffer.
class ScopedMemBuffer {
 public:
  explicit ScopedMemBuffer(Dart_Handle object) {
    if (!Dart_IsTypedData(object) && !Dart_IsList(object)) {
      Dart_ThrowException(DartUtils::NewDartArgumentError(
          "Argument is not a List<int>"));
    }

    uint8_t* bytes = NULL;
    intptr_t bytes_len = 0;
    bool is_typed_data = false;
    if (Dart_IsTypedData(object)) {
      is_typed_data = true;
      Dart_TypedData_Type typ;
      ThrowIfError(Dart_TypedDataAcquireData(
          object,
          &typ,
          reinterpret_cast<void**>(&bytes),
          &bytes_len));
    } else {
      ASSERT(Dart_IsList(object));
      ThrowIfError(Dart_ListLength(object, &bytes_len));
      bytes = Dart_ScopeAllocate(bytes_len);
      ASSERT(bytes != NULL);
      ThrowIfError(Dart_ListGetAsBytes(object, 0, bytes, bytes_len));
    }

    object_ = object;
    bytes_ = bytes;
    bytes_len_ = bytes_len;
    is_typed_data_ = is_typed_data;
  }

  ~ScopedMemBuffer() {
    if (is_typed_data_) {
      ThrowIfError(Dart_TypedDataReleaseData(object_));
    }
  }

  uint8_t* get() const { return bytes_; }
  intptr_t length() const { return bytes_len_; }

 private:
  Dart_Handle object_;
  uint8_t* bytes_;
  intptr_t bytes_len_;
  bool is_typed_data_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedMemBuffer);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_SECURE_SOCKET_MACOS_H_
