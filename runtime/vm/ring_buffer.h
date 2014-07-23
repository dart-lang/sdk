// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RING_BUFFER_H_
#define VM_RING_BUFFER_H_

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {

// Fixed-capacity ring buffer.
template<typename T, int N>
class RingBuffer {
 public:
  RingBuffer() : count_(0) { }

  void Add(const T& t) {
    data_[count_++ & kMask] = t;
  }

  // Returns the i'th most recently added element. Requires 0 <= i < Size().
  const T& Get(int i) const {
    ASSERT(0 <= i && i < Size());
    return data_[(count_ - i - 1) & kMask];
  }

  // Returns the number of elements currently stored in this buffer (at most N).
  int64_t Size() const {
    return Utils::Minimum(count_, static_cast<int64_t>(N));
  }

 private:
  static const int kMask = N - 1;
  COMPILE_ASSERT((N & kMask) == 0);
  T data_[N];
  int64_t count_;
};

}  // namespace dart

#endif  // VM_RING_BUFFER_H_
