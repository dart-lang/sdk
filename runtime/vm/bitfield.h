// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITFIELD_H_
#define RUNTIME_VM_BITFIELD_H_

#include "platform/globals.h"

namespace dart {

static const uword kUwordOne = 1U;

// BitField is a template for encoding and decoding a value of type T
// inside a storage of type S.
template <typename S, typename T, int position, int size>
class BitField {
 public:
  static const intptr_t kNextBit = position + size;

  // Tells whether the provided value fits into the bit field.
  static bool is_valid(T value) {
    return (static_cast<S>(value) & ~((kUwordOne << size) - 1)) == 0;
  }

  // Returns a S mask of the bit field.
  static S mask() { return (kUwordOne << size) - 1; }

  // Returns a S mask of the bit field which can be applied directly to
  // to the raw unshifted bits.
  static S mask_in_place() { return ((kUwordOne << size) - 1) << position; }

  // Returns the shift count needed to right-shift the bit field to
  // the least-significant bits.
  static int shift() { return position; }

  // Returns the size of the bit field.
  static int bitsize() { return size; }

  // Returns an S with the bit field value encoded.
  static S encode(T value) {
    COMPILE_ASSERT((sizeof(S) * kBitsPerByte) >= (position + size));
    ASSERT(is_valid(value));
    return static_cast<S>(value) << position;
  }

  // Extracts the bit field from the value.
  static T decode(S value) {
    return static_cast<T>((value >> position) & ((kUwordOne << size) - 1));
  }

  // Returns an S with the bit field value encoded based on the
  // original value. Only the bits corresponding to this bit field
  // will be changed.
  static S update(T value, S original) {
    ASSERT(is_valid(value));
    return (static_cast<S>(value) << position) | (~mask_in_place() & original);
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_BITFIELD_H_
