// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/datastream.h"

#include "platform/text_buffer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/os.h"
#include "vm/zone.h"

namespace dart {

// Setting up needed variables for the unrolled loop sections below.
#define UNROLLED_INIT()                                                        \
  using Unsigned = typename std::make_unsigned<T>::type;                       \
  Unsigned b = ReadByte();                                                     \
  if ((b & C::kMoreDataMask) == 0) {                                           \
    if ((b & C::kSignMask) != 0) {                                             \
      b |= ~Utils::NBitMask<Unsigned>(C::kDataBitsPerByte);                    \
    }                                                                          \
    return static_cast<T>(b);                                                  \
  }                                                                            \
  T r = static_cast<T>(b & C::kDataByteMask);

// Part of the unrolled loop where the loop may stop, having read the last part,
// or continue reading.
#define UNROLLED_BODY(bit_start)                                               \
  static_assert(bit_start % C::kDataBitsPerByte == 0,                          \
                "Bit start must be a multiple of the data bits per byte");     \
  static_assert(bit_start >= 0 && bit_start < kBitsPerByte * sizeof(T),        \
                "Starting unrolled body at invalid bit position");             \
  static_assert(bit_start + C::kDataBitsPerByte < kBitsPerByte * sizeof(T),    \
                "Unrolled body should not contain final bits in value");       \
  b = ReadByte();                                                              \
  r |= static_cast<Unsigned>(b & C::kDataByteMask) << bit_start;               \
  if ((b & C::kMoreDataMask) == 0) {                                           \
    if ((b & C::kSignMask) != 0) {                                             \
      r |= ~Utils::NBitMask<T>(bit_start + C::kDataBitsPerByte);               \
    }                                                                          \
    return r;                                                                  \
  }

// The end of the unrolled loop. Does not need to handle sign extension, as the
// last bits fill the rest of the bitspace.
#define UNROLLED_END(bit_start)                                                \
  static_assert(bit_start % C::kDataBitsPerByte == 0,                          \
                "Bit start must be a multiple of the data bits per byte");     \
  static_assert(bit_start >= 0 && bit_start < kBitsPerByte * sizeof(T),        \
                "Starting unrolled end at invalid bit position");              \
  static_assert(bit_start + C::kDataBitsPerByte >= kBitsPerByte * sizeof(T),   \
                "Unrolled end does not contain final bits in value");          \
  b = ReadByte();                                                              \
  ASSERT_EQUAL((b & C::kMoreDataMask), 0);                                     \
  r |= static_cast<Unsigned>(b & C::kDataByteMask) << bit_start;               \
  return r;

uint16_t ReadStream::Read16() {
  using T = uint16_t;
  UNROLLED_INIT();
  UNROLLED_BODY(7);
  UNROLLED_END(14);
}

uint32_t ReadStream::Read32() {
  using T = uint32_t;
  UNROLLED_INIT();
  UNROLLED_BODY(7);
  UNROLLED_BODY(14);
  UNROLLED_BODY(21);
  UNROLLED_END(28);
}

uint64_t ReadStream::Read64() {
  using T = uint64_t;
  UNROLLED_INIT();
  UNROLLED_BODY(7);
  UNROLLED_BODY(14);
  UNROLLED_BODY(21);
  UNROLLED_BODY(28);
  UNROLLED_BODY(35);
  UNROLLED_BODY(42);
  UNROLLED_BODY(49);
  UNROLLED_BODY(56);
  UNROLLED_END(63);
}
#undef UNROLLED_INIT
#undef UNROLLED_BODY
#undef UNROLLED_END

static constexpr intptr_t kRowSize = 16;

void ReadStream::WriteWindow(BaseTextBuffer* buffer,
                             intptr_t start,
                             intptr_t window_size) {
  const intptr_t buffer_size = end_ - buffer_;
  ASSERT(0 <= start && start <= buffer_size);
  intptr_t window_start = start - (window_size / 2);
  intptr_t window_end = start + (window_size / 2);
  if (window_start < 0) window_start = 0;
  if (buffer_size < window_start + window_end) window_end = buffer_size;
  for (intptr_t i = window_start - (window_start % kRowSize); i < window_end;
       i += kRowSize) {
    buffer->Printf("%016" Px " ", i);
    intptr_t j = i;
    if (j < window_start) {
      while (j < window_start) {
        buffer->AddString("    ");
        ++j;
      }
    }
    for (; j < Utils::Minimum(window_end, i + kRowSize); j++) {
      buffer->AddChar(j == start ? '|' : ' ');
      buffer->Printf("%02x", static_cast<uint8_t>(buffer_[j] % kMaxUint8));
      buffer->AddChar(j == start ? '|' : ' ');
    }
    buffer->AddChar('\n');
  }
}

void ReadStream::PrintWindow(intptr_t start, intptr_t window_size) {
  TextBuffer buffer(1024);
  WriteWindow(&buffer, start, window_size);
  OS::Print("%s", buffer.buffer());
}

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
