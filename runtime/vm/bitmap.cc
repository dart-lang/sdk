// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bitmap.h"

#include "platform/assert.h"
#include "vm/object.h"
#include "vm/log.h"

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
      BackingStore()[byte_offset] &= mask;
      // Clear the rest.
      ++byte_offset;
      if (byte_offset < data_size_in_bytes_) {
        memset(&BackingStore()[byte_offset], 0,
               data_size_in_bytes_ - byte_offset);
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
  }

  // Bits not covered by the backing store are implicitly false.
  // Grow the backing store if necessary.
  if (value) {
    if (!InBackingStore(bit_offset)) {
      intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
      uint8_t* old_data = BackingStore();
      intptr_t old_size = data_size_in_bytes_;
      data_size_in_bytes_ =
          Utils::RoundUp(byte_offset + 1, kIncrementSizeInBytes);
      ASSERT(data_size_in_bytes_ > 0);
      // Note: do not update data_ yet because it might overwrite old_data
      // contents.
      uint8_t* new_data = AllocBackingStore(data_size_in_bytes_);
      memmove(new_data, old_data, old_size);
      memset(&new_data[old_size], 0, (data_size_in_bytes_ - old_size));
      data_.ptr_ = new_data;
    }
    ASSERT(InBackingStore(bit_offset));
  }

  // Set bit if in backing store.
  if (InBackingStore(bit_offset)) {
    SetBit(bit_offset, value);
  }
}

void BitmapBuilder::SetRange(intptr_t min, intptr_t max, bool value) {
  for (intptr_t i = min; i <= max; i++) {
    Set(i, value);
  }
}

void BitmapBuilder::Print() const {
  for (intptr_t i = 0; i < Length(); i++) {
    if (Get(i)) {
      THR_Print("1");
    } else {
      THR_Print("0");
    }
  }
}

void BitmapBuilder::AppendAsBytesTo(BaseWriteStream* stream) const {
  // Early return if there are no bits in the payload to copy.
  if (Length() == 0) return;

  const intptr_t total_size =
      Utils::RoundUp(Length(), kBitsPerByte) / kBitsPerByte;
  intptr_t payload_size;
  intptr_t extra_size;
  if (total_size > data_size_in_bytes_) {
    // A [BitmapBuilder] does not allocate storage for the trailing 0 bits in
    // the backing store, so we need to add additional empty bytes here.
    payload_size = data_size_in_bytes_;
    extra_size = total_size - data_size_in_bytes_;
  } else {
    payload_size = total_size;
    extra_size = 0;
  }
#if defined(DEBUG)
  // Make sure any bits in the payload beyond the bit length if we're not
  // appending trailing zeroes are cleared to ensure deterministic snapshots.
  if (extra_size == 0 && Length() % kBitsPerByte != 0) {
    const int8_t mask = (1 << (Length() % kBitsPerByte)) - 1;
    ASSERT_EQUAL(BackingStore()[payload_size - 1],
                 (BackingStore()[payload_size - 1] & mask));
  }
#endif
  stream->WriteBytes(BackingStore(), payload_size);
  for (intptr_t i = 0; i < extra_size; i++) {
    stream->WriteByte(0U);
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
  return ((BackingStore()[byte_offset] & mask) != 0);
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
  if (value) {
    BackingStore()[byte_offset] |= mask;
  } else {
    BackingStore()[byte_offset] &= ~mask;
  }
}

}  // namespace dart
