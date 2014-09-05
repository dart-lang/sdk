// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BIT_SET_H_
#define VM_BIT_SET_H_

#include "platform/utils.h"
#include "vm/globals.h"

namespace dart {

// Just like its namesake in the STL, a BitSet object contains a fixed
// length sequence of bits.
template<intptr_t N>
class BitSet {
 public:
  BitSet() {
    Reset();
  }

  void Set(intptr_t i, bool value) {
    ASSERT(i >= 0);
    ASSERT(i < N);
    uword mask = (static_cast<uword>(1) << (i & (kBitsPerWord - 1)));
    if (value) {
      data_[i >> kBitsPerWordLog2] |= mask;
    } else {
      data_[i >> kBitsPerWordLog2] &= ~mask;
    }
  }

  bool Test(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < N);
    uword mask = (static_cast<uword>(1) << (i & (kBitsPerWord - 1)));
    return (data_[i >> kBitsPerWordLog2] & mask) != 0;
  }

  intptr_t Next(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < N);
    intptr_t w = i >> kBitsPerWordLog2;
    uword mask = ~static_cast<uword>(0) << i;
    if ((data_[w] & mask) != 0) {
      uword tz = Utils::CountTrailingZeros(data_[w] & mask);
      return (w << kBitsPerWordLog2) + tz;
    }
    while (++w < kLengthInWords) {
      if (data_[w] != 0) {
        return (w << kBitsPerWordLog2) + Utils::CountTrailingZeros(data_[w]);
      }
    }
    return -1;
  }

  intptr_t Last() const {
    for (int w = kLengthInWords - 1; w >= 0; --w) {
      uword d = data_[w];
      if (d != 0) {
        // TODO(koda): Define HighestBit(uword) or use uint64_t[] for data_.
        return (w << kBitsPerWordLog2) + Utils::HighestBit(d);
      }
    }
    return -1;
  }

  void Reset() {
    memset(data_, 0, sizeof(data_));
  }

  intptr_t Size() const {
    return N;
  }

 private:
  static const int kLengthInWords = 1 + ((N - 1) / kBitsPerWord);
  uword data_[kLengthInWords];
};

}  // namespace dart

#endif  // VM_BIT_SET_H_
