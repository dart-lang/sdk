// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITMAP_H_
#define RUNTIME_VM_BITMAP_H_

#include "vm/allocation.h"
#include "vm/datastream.h"
#include "vm/thread_state.h"
#include "vm/zone.h"

namespace dart {

// BitmapBuilder is used to build a bitmap. The implementation is optimized
// for a dense set of small bit maps without a fixed upper bound (e.g: a
// pointer map description of a stack).
class BitmapBuilder : public ZoneAllocated {
 public:
  BitmapBuilder() : length_(0), data_size_in_bytes_(kInlineCapacityInBytes) {
    memset(data_.inline_, 0, data_size_in_bytes_);
  }

  BitmapBuilder(const BitmapBuilder& other)
      : ZoneAllocated(),
        length_(other.length_),
        data_size_in_bytes_(other.data_size_in_bytes_) {
    if (data_size_in_bytes_ == kInlineCapacityInBytes) {
      memmove(data_.inline_, other.data_.inline_, kInlineCapacityInBytes);
    } else {
      data_.ptr_ = AllocBackingStore(data_size_in_bytes_);
      memmove(data_.ptr_, other.data_.ptr_, data_size_in_bytes_);
    }
  }

  intptr_t Length() const { return length_; }
  void SetLength(intptr_t length);

  // Get/Set individual bits in the bitmap, setting bits beyond the bitmap's
  // length increases the length and expands the underlying bitmap if
  // needed.
  bool Get(intptr_t bit_offset) const;
  void Set(intptr_t bit_offset, bool value);

  // Return the bit offset of the highest bit set.
  intptr_t Maximum() const;

  // Return the bit offset of the lowest bit set.
  intptr_t Minimum() const;

  // Sets min..max (inclusive) to value.
  void SetRange(intptr_t min, intptr_t max, bool value);

  void Print() const;
  void AppendAsBytesTo(BaseWriteStream* stream) const;

 private:
  static constexpr intptr_t kIncrementSizeInBytes = 16;
  static constexpr intptr_t kInlineCapacityInBytes = 16;

  bool InRange(intptr_t offset) const {
    if (offset < 0) {
      FATAL1(
          "Fatal error in BitmapBuilder::InRange :"
          " invalid bit_offset, %" Pd "\n",
          offset);
    }
    return (offset < length_);
  }

  bool InBackingStore(intptr_t bit_offset) {
    intptr_t byte_offset = bit_offset >> kBitsPerByteLog2;
    return byte_offset < data_size_in_bytes_;
  }

  uint8_t* BackingStore() {
    return data_size_in_bytes_ == kInlineCapacityInBytes ? &data_.inline_[0]
                                                         : data_.ptr_;
  }

  const uint8_t* BackingStore() const {
    return data_size_in_bytes_ == kInlineCapacityInBytes ? &data_.inline_[0]
                                                         : data_.ptr_;
  }

  static uint8_t* AllocBackingStore(intptr_t size_in_bytes) {
    return ThreadState::Current()->zone()->Alloc<uint8_t>(size_in_bytes);
  }

  // Get/Set a bit that is known to be covered by the backing store.
  bool GetBit(intptr_t bit_offset) const;
  void SetBit(intptr_t bit_offset, bool value);

  intptr_t length_;

  // Backing store for the bitmap.  Reading bits beyond the backing store
  // (up to length_) is allowed and they are assumed to be false.
  intptr_t data_size_in_bytes_;
  union {
    uint8_t* ptr_;
    uint8_t inline_[kInlineCapacityInBytes];
  } data_;
};

}  // namespace dart

#endif  // RUNTIME_VM_BITMAP_H_
