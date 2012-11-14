// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_TLS_SOCKET_H_
#define BIN_TLS_SOCKET_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

#include <prinit.h>
#include <prerror.h>
#include <prnetdb.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "platform/globals.h"
#include "platform/thread.h"

static void ThrowException(const char* message) {
  Dart_Handle socket_io_exception =
      DartUtils::NewDartSocketIOException(message, Dart_Null());
  Dart_ThrowException(socket_io_exception);
}


/* Handle an error reported from the NSS library. */
static void ThrowPRException(const char* message) {
  PRErrorCode error_code = PR_GetError();
  int error_length = PR_GetErrorTextLength();
  char* error_message = static_cast<char*>(malloc(error_length + 1));
  ASSERT(error_message != NULL);
  int copied_length = PR_GetErrorText(error_message);
  ASSERT(copied_length == error_length);
  error_message[error_length] = '\0';
  OSError os_error_struct(error_code, error_message, OSError::kNSS);
  Dart_Handle os_error = DartUtils::NewDartOSError(&os_error_struct);
  Dart_Handle socket_io_exception =
      DartUtils::NewDartSocketIOException(message, os_error);
  free(error_message);
  Dart_ThrowException(socket_io_exception);
}

/*
 * TlsFilter encapsulates the NSS SSL(TLS) code in a filter, that communicates
 * with the containing _TlsFilterImpl Dart object through four shared
 * ExternalByteArray buffers, for reading and writing plaintext, and
 * reading and writing encrypted text.  The filter handles handshaking
 * and certificate verification.
 */
class TlsFilter {
 public:
  // These enums must agree with those in sdk/lib/io/tls_socket.dart.
  enum BufferIndex {
    kReadPlaintext,
    kWritePlaintext,
    kReadEncrypted,
    kWriteEncrypted,
    kNumBuffers
  };

  TlsFilter()
      : string_start_(NULL),
        string_length_(NULL),
        handshake_complete_(NULL),
        in_handshake_(false),
        memio_(NULL) { }

  void Init(Dart_Handle dart_this);
  void Connect(const char* host, int port);
  void Destroy();
  void DestroyPlatformIndependent();
  void Handshake();
  void RegisterHandshakeCompleteCallback(Dart_Handle handshake_complete);
  static void InitializeLibrary(const char* pkcert_directory);

  intptr_t ProcessBuffer(int bufferIndex);

 private:
  static const int kMemioBufferSize = 20 * KB;
  static bool library_initialized_;
  static dart::Mutex mutex_;  // To protect library initialization.

  uint8_t* buffers_[kNumBuffers];
  int64_t buffer_size_;
  Dart_Handle string_start_;
  Dart_Handle string_length_;
  Dart_Handle dart_buffer_objects_[kNumBuffers];
  Dart_Handle handshake_complete_;
  bool in_handshake_;
  PRFileDesc* memio_;

  void InitializeBuffers(Dart_Handle dart_this);
  void InitializePlatformData();

  DISALLOW_COPY_AND_ASSIGN(TlsFilter);
};

#endif  // BIN_TLS_SOCKET_H_
