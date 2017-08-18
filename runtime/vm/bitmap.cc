// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bitmap.h"

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

void BitmapBuilder::SetLength(intptr_t new_length) {
  // When this function is used to shorten the length, affected bits in the
  // backing store need to be cleared because the implementation assumes it.
  if (new_length < length_) {
    // Byte offset containing the first bit to be cleared.
    intptr_t byte_offset = new_length >> kBitsPerByteLog2;
    if (byte_offset < data_size_in_bytes_) {
      // First bit index (in the byte) to be cleared.
      intptr_t bit_index = new_length & (kBitsPerByte - 1);
      intptr_t mask = (1 << bit_index) - 1;
      data_[byte_offset] &= mask;
      // Clear the rest.
      ++byte_offset;
      if (byte_offset < data_size_in_bytes_) {
        memset(&data_[byte_offset], 0, data_size_in_bytes_ - byte_offset);
      }
    }
  }
  length_ = new_length;
}

bool BitmapBuilder::Get(intptr_t bit_offset) const {
  if (!InRange(bit_offset)) {
    return false;
  }
  intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
  // Bits not covered by the backing store are implicitly false.
  return (byte_offset < data_size_in_bytes_) && GetBit(bit_offset);
}

void BitmapBuilder::Set(intptr_t bit_offset, bool value) {
  if (!InRange(bit_offset)) {
    length_ = bit_offset + 1;
    // Bits not covered by the backing store are implicitly false.
    if (!value) return;
    // Grow the backing store if necessary.
    intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
    if (byte_offset >= data_size_in_bytes_) {
      uint8_t* old_data = data_;
      intptr_t old_size = data_size_in_bytes_;
      data_size_in_bytes_ =
          Utils::RoundUp(byte_offset + 1, kIncrementSizeInBytes);
      ASSERT(data_size_in_bytes_ > 0);
      data_ = Thread::Current()->zone()->Alloc<uint8_t>(data_size_in_bytes_);
      ASSERT(data_ != NULL);
      memmove(data_, old_data, old_size);
      memset(&data_[old_size], 0, (data_size_in_bytes_ - old_size));
    }
  }
  SetBit(bit_offset, value);
}

void BitmapBuilder::SetRange(intptr_t min, intptr_t max, bool value) {
  for (intptr_t i = min; i <= max; i++) {
    Set(i, value);
  }
}

void BitmapBuilder::Print() const {
  for (intptr_t i = 0; i < Length(); i++) {
    if (Get(i)) {
      OS::Print("1");
    } else {
      OS::Print("0");
    }
  }
}

bool BitmapBuilder::GetBit(intptr_t bit_offset) const {
  if (!InRange(bit_offset)) {
    return false;
  }
  intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
  ASSERT(byte_offset < data_size_in_bytes_);
  intptr_t bit_remainder = bit_offset & (kBitsPerByte - 1);
  uint8_t mask = 1U << bit_remainder;
  ASSERT(data_ != NULL);
  return ((data_[byte_offset] & mask) != 0);
}

void BitmapBuilder::SetBit(intptr_t bit_offset, bool value) {
  if (!InRange(bit_offset)) {
    FATAL1(
        "Fatal error in BitmapBuilder::SetBit :"
        " invalid bit_offset, %" Pd "\n",
        bit_offset);
  }
  intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
  ASSERT(byte_offset < data_size_in_bytes_);
  intptr_t bit_remainder = bit_offset & (kBitsPerByte - 1);
  uint8_t mask = 1U << bit_remainder;
  ASSERT(data_ != NULL);
  if (value) {
    data_[byte_offset] |= mask;
  } else {
    data_[byte_offset] &= ~mask;
  }
}

}  // namespace dart
