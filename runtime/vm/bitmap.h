// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITMAP_H_
#define RUNTIME_VM_BITMAP_H_

#include "vm/allocation.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

// Forward declarations.
class RawStackMap;
class StackMap;

// BitmapBuilder is used to build a bitmap. The implementation is optimized
// for a dense set of small bit maps without a fixed upper bound (e.g: a
// pointer map description of a stack).
class BitmapBuilder : public ZoneAllocated {
 public:
  BitmapBuilder()
      : length_(0),
        data_size_in_bytes_(kInitialSizeInBytes),
        data_(Thread::Current()->zone()->Alloc<uint8_t>(kInitialSizeInBytes)) {
    memset(data_, 0, kInitialSizeInBytes);
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

 private:
  static const intptr_t kInitialSizeInBytes = 16;
  static const intptr_t kIncrementSizeInBytes = 16;

  bool InRange(intptr_t offset) const {
    if (offset < 0) {
      FATAL1(
          "Fatal error in BitmapBuilder::InRange :"
          " invalid bit_offset, %" Pd "\n",
          offset);
    }
    return (offset < length_);
  }

  // Get/Set a bit that is known to be covered by the backing store.
  bool GetBit(intptr_t bit_offset) const;
  void SetBit(intptr_t bit_offset, bool value);

  intptr_t length_;

  // Backing store for the bitmap.  Reading bits beyond the backing store
  // (up to length_) is allowed and they are assumed to be false.
  intptr_t data_size_in_bytes_;
  uint8_t* data_;

  DISALLOW_COPY_AND_ASSIGN(BitmapBuilder);
};

}  // namespace dart

#endif  // RUNTIME_VM_BITMAP_H_
