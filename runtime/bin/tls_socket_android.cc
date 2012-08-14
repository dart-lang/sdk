// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/tls_socket.h"

#include "bin/builtin.h"


class TlsFilterPlatformData {
};


TlsFilter::TlsFilter() : in_handshake_(false) {
  LockInitMutex();
  if (!library_initialized_) {
    InitializeLibrary();
    library_initialized_ = true;
  }
  UnlockInitMutex();
}


void TlsFilter::InitializePlatformData() {
  UNIMPLEMENTED();
}


void TlsFilter::InitializeLibrary() {
  UNIMPLEMENTED();
}


void TlsFilter::Connect() {
  UNIMPLEMENTED();
}


void TlsFilter::Destroy() {
  UNIMPLEMENTED();
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

  intptr_t bytes_processed = 0;
  switch (buffer_index) {
    case kReadPlaintext:
    case kWriteEncrypted:
      // Write from the filter to the buffer.
      USE(start);
      UNIMPLEMENTED();
      break;
    case kReadEncrypted:
    case kWritePlaintext:
      if (length > 0) {
        // Write from the buffer to the filter.
        UNIMPLEMENTED();
      }
      break;
  }
  return bytes_processed;
}
