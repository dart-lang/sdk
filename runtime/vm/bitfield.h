// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BITFIELD_H_
#define VM_BITFIELD_H_

namespace dart {

// BitField is a template for encoding and decoding a bit field inside
// an unsigned machine word.
template<typename T, int position, int size>
class BitField {
 public:
  // Tells whether the provided value fits into the bit field.
  static bool is_valid(T value) {
    return (static_cast<uword>(value) & ~((1U << size) - 1)) == 0;
  }

  // Returns a uword mask of the bit field.
  static uword mask() {
    return (1U << size) - 1;
  }

  // Returns a uword mask of the bit field which can be applied directly to
  // to the raw unshifted bits.
  static uword mask_in_place() {
    return ((1U << size) - 1) << position;
  }

  // Returns the shift count needed to right-shift the bit field to
  // the least-significant bits.
  static int shift() {
    return position;
  }

  // Returns the size of the bit field.
  static int bitsize() {
    return size;
  }

  // Returns a uword with the bit field value encoded.
  static uword encode(T value) {
    ASSERT(is_valid(value));
    return static_cast<uword>(value) << position;
  }

  // Extracts the bit field from the value.
  static T decode(uword value) {
    return static_cast<T>((value >> position) & ((1U << size) - 1));
  }

  // Returns a uword with the bit field value encoded based on the
  // original value. Only the bits corresponding to this bit field
  // will be changed.
  static uword update(T value, uword original) {
    ASSERT(is_valid(value));
    return (static_cast<uword>(value) << position) |
        (~mask_in_place() & original);
  }
};

}  // namespace dart

#endif  // VM_BITFIELD_H_
