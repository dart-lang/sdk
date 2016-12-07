// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DOUBLE_INTERNALS_H_
#define RUNTIME_VM_DOUBLE_INTERNALS_H_

#include "platform/utils.h"

namespace dart {

// We assume that doubles and uint64_t have the same endianness.
static uint64_t double_to_uint64(double d) {
  return bit_cast<uint64_t>(d);
}

// Helper functions for doubles.
class DoubleInternals {
 public:
  static const int kSignificandSize = 53;

  explicit DoubleInternals(double d) : d64_(double_to_uint64(d)) {}

  // Returns the double's bit as uint64.
  uint64_t AsUint64() const { return d64_; }

  int Exponent() const {
    if (IsDenormal()) return kDenormalExponent;

    uint64_t d64 = AsUint64();
    int biased_e =
        static_cast<int>((d64 & kExponentMask) >> kPhysicalSignificandSize);
    return biased_e - kExponentBias;
  }

  uint64_t Significand() const {
    uint64_t d64 = AsUint64();
    uint64_t significand = d64 & kSignificandMask;
    if (!IsDenormal()) {
      return significand + kHiddenBit;
    } else {
      return significand;
    }
  }

  // Returns true if the double is a denormal.
  bool IsDenormal() const {
    uint64_t d64 = AsUint64();
    return (d64 & kExponentMask) == 0;
  }

  // We consider denormals not to be special.
  // Hence only Infinity and NaN are special.
  bool IsSpecial() const {
    uint64_t d64 = AsUint64();
    return (d64 & kExponentMask) == kExponentMask;
  }

  int Sign() const {
    uint64_t d64 = AsUint64();
    return (d64 & kSignMask) == 0 ? 1 : -1;
  }

 private:
  static const uint64_t kSignMask = DART_2PART_UINT64_C(0x80000000, 00000000);
  static const uint64_t kExponentMask =
      DART_2PART_UINT64_C(0x7FF00000, 00000000);
  static const uint64_t kSignificandMask =
      DART_2PART_UINT64_C(0x000FFFFF, FFFFFFFF);
  static const uint64_t kHiddenBit = DART_2PART_UINT64_C(0x00100000, 00000000);
  static const int kPhysicalSignificandSize = 52;  // Excludes the hidden bit.
  static const int kExponentBias = 0x3FF + kPhysicalSignificandSize;
  static const int kDenormalExponent = -kExponentBias + 1;

  const uint64_t d64_;
};

}  // namespace dart

#endif  // RUNTIME_VM_DOUBLE_INTERNALS_H_
