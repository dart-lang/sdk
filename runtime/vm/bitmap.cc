// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bitmap.h"

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

bool BitmapBuilder::Get(intptr_t bit_offset) const {
  if (!InRange(bit_offset)) {
    return false;
  }
  return GetBit(bit_offset);
}


void BitmapBuilder::Set(intptr_t bit_offset, bool value) {
  while (!InRange(bit_offset)) {
    intptr_t new_size = size_in_bytes_ + kIncrementSizeInBytes;
    ASSERT(new_size > 0);
    uint8_t* new_bit_list =
        Isolate::Current()->current_zone()->Alloc<uint8_t>(new_size);
    ASSERT(new_bit_list != NULL);
    ASSERT(bit_list_ != NULL);
    uint8_t* old_bit_list = bit_list_;
    memmove(new_bit_list, old_bit_list, size_in_bytes_);
    memset((new_bit_list + size_in_bytes_), 0, kIncrementSizeInBytes);
    size_in_bytes_ = new_size;
    bit_list_ = new_bit_list;
  }
  SetBit(bit_offset, value);
}


// Return the bit offset of the highest bit set.
intptr_t BitmapBuilder::Maximum() const {
  intptr_t bound = SizeInBits();
  for (intptr_t i = (bound - 1); i >= 0; i--) {
    if (Get(i)) return i;
  }
  return Stackmap::kNoMaximum;
}


// Return the bit offset of the lowest bit set.
intptr_t BitmapBuilder::Minimum() const {
  intptr_t bound = SizeInBits();
  for (intptr_t i = 0; i < bound; i++) {
    if (Get(i)) return i;
  }
  return Stackmap::kNoMinimum;
}


void BitmapBuilder::SetRange(intptr_t min, intptr_t max, bool value) {
  for (intptr_t i = min; i <= max; i++) {
    Set(i, value);
  }
}


bool BitmapBuilder::GetBit(intptr_t bit_offset) const {
  ASSERT(InRange(bit_offset));
  int byte_offset = bit_offset >> kBitsPerByteLog2;
  int bit_remainder = bit_offset & (kBitsPerByte - 1);
  uint8_t mask = 1U << bit_remainder;
  ASSERT(bit_list_ != NULL);
  return ((bit_list_[byte_offset] & mask) != 0);
}


void BitmapBuilder::SetBit(intptr_t bit_offset, bool value) {
  ASSERT(InRange(bit_offset));
  int byte_offset = bit_offset >> kBitsPerByteLog2;
  int bit_remainder = bit_offset & (kBitsPerByte - 1);
  uint8_t mask = 1U << bit_remainder;
  uint8_t* byte_addr;
  ASSERT(bit_list_ != NULL);
  byte_addr = &(bit_list_[byte_offset]);
  if (value) {
    *byte_addr |= mask;
  } else {
    *byte_addr &= ~mask;
  }
}

}  // namespace dart
