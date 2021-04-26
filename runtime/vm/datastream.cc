// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/datastream.h"

#include "vm/compiler/runtime_api.h"
#include "vm/zone.h"

namespace dart {

void BaseWriteStream::WriteTargetWord(word value) {
  ASSERT(compiler::target::kBitsPerWord == kBitsPerWord ||
         Utils::IsAbsoluteUint(compiler::target::kBitsPerWord, value));
  WriteFixed(static_cast<compiler::target::word>(value));
}

MallocWriteStream::~MallocWriteStream() {
  free(buffer_);
}

void MallocWriteStream::Realloc(intptr_t new_size) {
  const intptr_t old_offset = current_ - buffer_;
  buffer_ = reinterpret_cast<uint8_t*>(realloc(buffer_, new_size));
  capacity_ = buffer_ != nullptr ? new_size : 0;
  current_ = buffer_ != nullptr ? buffer_ + old_offset : nullptr;
}

void ZoneWriteStream::Realloc(intptr_t new_size) {
  const intptr_t old_offset = current_ - buffer_;
  buffer_ = zone_->Realloc(buffer_, capacity_, new_size);
  capacity_ = buffer_ != nullptr ? new_size : 0;
  current_ = buffer_ != nullptr ? buffer_ + old_offset : nullptr;
}

StreamingWriteStream::~StreamingWriteStream() {
  Flush();
  free(buffer_);
}

void StreamingWriteStream::Realloc(intptr_t new_size) {
  Flush();
  // Check whether resetting the internal buffer by flushing gave enough space.
  if (new_size <= capacity_) {
    return;
  }
  const intptr_t new_capacity = Utils::RoundUp(new_size, 64 * KB);
  buffer_ = reinterpret_cast<uint8_t*>(realloc(buffer_, new_capacity));
  capacity_ = buffer_ != nullptr ? new_capacity : 0;
  current_ = buffer_;  // Flushing reset the internal buffer offset to 0.
}

void StreamingWriteStream::Flush() {
  intptr_t size = current_ - buffer_;
  callback_(callback_data_, buffer_, size);
  flushed_size_ += size;
  current_ = buffer_;
}

}  // namespace dart
