// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/tls_socket.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <libgen.h>
#include <stdio.h>

#include <openssl/ssl.h>
#include <openssl/bio.h>
#include <openssl/err.h>

#include "bin/builtin.h"


class TlsFilterPlatformData {
 public:
  SSL* ssl;
  SSL_CTX* ssl_ctx;
  BIO* encrypted;
  BIO* plaintext;
  BIO* internal;
};


TlsFilter::TlsFilter() : in_handshake_(false) {
  LockInitMutex();
  if (!library_initialized_) {
    InitializeLibrary();
    library_initialized_ = true;
  }
  UnlockInitMutex();
}


void TlsFilter::InitializeLibrary() {
  SSL_library_init();
  SSL_load_error_strings();
  OpenSSL_add_all_algorithms();
}


void TlsFilter::InitializePlatformData() {
  data_ = new TlsFilterPlatformData;
  data_->ssl_ctx = SSL_CTX_new(SSLv23_client_method());
  BIO_new_bio_pair(&(data_->internal), 0, &(data_->encrypted), 0);
  data_->plaintext = BIO_new_ssl(data_->ssl_ctx, 1);
  data_->plaintext = BIO_push(data_->plaintext, data_->internal);
}


void TlsFilter::Connect() {
  int result = BIO_do_handshake(data_->plaintext);
  if (result == 1) {
    if (in_handshake_) {
      HandleError(Dart_InvokeClosure(handshake_finish_, 0, NULL));
      in_handshake_ = false;
    }
  } else if (BIO_should_retry(data_->plaintext)) {
    if (!in_handshake_) {
      HandleError(Dart_InvokeClosure(handshake_start_, 0, NULL));
      in_handshake_ = true;
    }
  }
}


void TlsFilter::Destroy() {
  DestroyPlatformIndependent();
  // TODO(whesse): Destroy OpenSSL objects here.
}


intptr_t TlsFilter::ProcessBuffer(int buffer_index) {
  Dart_Handle buffer_object = dart_buffer_objects_[buffer_index];
  Dart_Handle start_object = HandleError(
      Dart_GetField(buffer_object, stringStart_));
  Dart_Handle length_object = HandleError(
      Dart_GetField(buffer_object, stringLength_));
  int64_t unsafe_start = DartUtils::GetIntegerValue(start_object);
  int64_t unsafe_length = DartUtils::GetIntegerValue(length_object);
  if (unsafe_start < 0 || unsafe_start >= buffer_size_ ||
      unsafe_length < 0 || unsafe_length > buffer_size_) {
     Dart_ThrowException(DartUtils::NewDartIllegalArgumentException(
         "Illegal .start or .length on a _TlsExternalBuffer"));
  }
  intptr_t start = static_cast<intptr_t>(unsafe_start);
  intptr_t length = static_cast<intptr_t>(unsafe_length);

  BIO* bio_stream;
  if (buffer_index == kReadEncrypted || buffer_index == kWriteEncrypted) {
    bio_stream = data_->encrypted;
  } else {
    bio_stream = data_->plaintext;
  }

  intptr_t bytes_processed = 0;
  int bio_bytes = 0;
  switch (buffer_index) {
    case kReadPlaintext:
    case kWriteEncrypted: {
      // Write from the BIO to the buffer.
      intptr_t bytes_free = buffer_size_ - start - length;
      if (bytes_free > 0) {
        bio_bytes = BIO_read(bio_stream,
                             buffers_[buffer_index] + start + length,
                             bytes_free);
      }
      break;
    }
    case kReadEncrypted:
    case kWritePlaintext:
      if (length > 0) {
        // Call BIO_write.
        bio_bytes = BIO_write(bio_stream,
                              buffers_[buffer_index] + start,
                              length);
      }
      break;
  }
  if (bio_bytes > 0) {
          bytes_processed = bio_bytes;
  }
  return bytes_processed;
}
