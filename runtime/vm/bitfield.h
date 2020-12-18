// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITFIELD_H_
#define RUNTIME_VM_BITFIELD_H_

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

static const uword kUwordOne = 1U;

// BitField is a template for encoding and decoding a value of type T
// inside a storage of type S.
template <typename S,
          typename T,
          int position,
          int size = (sizeof(S) * kBitsPerByte) - position>
class BitField {
 public:
  typedef T Type;

  static_assert((sizeof(S) * kBitsPerByte) >= (position + size),
                "BitField does not fit into the type.");

  static const intptr_t kNextBit = position + size;

  // Tells whether the provided value fits into the bit field.
  static constexpr bool is_valid(T value) {
    return (static_cast<S>(value) & ~((kUwordOne << size) - 1)) == 0;
  }

  // Returns a S mask of the bit field.
  static constexpr S mask() { return (kUwordOne << size) - 1; }

  // Returns a S mask of the bit field which can be applied directly to
  // to the raw unshifted bits.
  static constexpr S mask_in_place() {
    return ((kUwordOne << size) - 1) << position;
  }

  // Returns the shift count needed to right-shift the bit field to
  // the least-significant bits.
  static constexpr int shift() { return position; }

  // Returns the size of the bit field.
  static constexpr int bitsize() { return size; }

  // Returns an S with the bit field value encoded.
  static UNLESS_DEBUG(constexpr) S encode(T value) {
    DEBUG_ASSERT(is_valid(value));
    return static_cast<S>(value) << position;
  }

  // Extracts the bit field from the value.
  static constexpr T decode(S value) {
    return static_cast<T>((value >> position) & ((kUwordOne << size) - 1));
  }

  // Returns an S with the bit field value encoded based on the
  // original value. Only the bits corresponding to this bit field
  // will be changed.
  static UNLESS_DEBUG(constexpr) S update(T value, S original) {
    DEBUG_ASSERT(is_valid(value));
    return (static_cast<S>(value) << position) | (~mask_in_place() & original);
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_BITFIELD_H_
