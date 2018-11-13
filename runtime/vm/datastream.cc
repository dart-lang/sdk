// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/datastream.h"

namespace dart {

StreamingWriteStream::StreamingWriteStream(intptr_t initial_capacity,
                                           Dart_StreamingWriteCallback callback,
                                           void* callback_data)
    : flushed_size_(0), callback_(callback), callback_data_(callback_data) {
  buffer_ = reinterpret_cast<uint8_t*>(malloc(initial_capacity));
  if (buffer_ == NULL) {
    OUT_OF_MEMORY();
  }
  cursor_ = buffer_;
  limit_ = buffer_ + initial_capacity;
}

StreamingWriteStream::~StreamingWriteStream() {
  Flush();
  free(buffer_);
}

void StreamingWriteStream::VPrint(const char* format, va_list args) {
  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = Utils::VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  // Alloc.
  EnsureAvailable(len + 1);

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  Utils::VSNPrint(reinterpret_cast<char*>(cursor_), len + 1, format,
                  print_args);
  va_end(print_args);
  cursor_ += len;  // Not len + 1 to swallow the terminating NUL.
}

void StreamingWriteStream::EnsureAvailableSlowPath(intptr_t needed) {
  Flush();

  intptr_t available = limit_ - cursor_;
  if (available >= needed) return;

  intptr_t new_capacity = Utils::RoundUp(needed, 64 * KB);
  free(buffer_);
  buffer_ = reinterpret_cast<uint8_t*>(malloc(new_capacity));
  if (buffer_ == NULL) {
    OUT_OF_MEMORY();
  }
  cursor_ = buffer_;
  limit_ = buffer_ + new_capacity;
}

void StreamingWriteStream::Flush() {
  intptr_t size = cursor_ - buffer_;
  callback_(callback_data_, buffer_, size);
  flushed_size_ += size;
  cursor_ = buffer_;
}

}  // namespace dart
