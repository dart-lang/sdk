// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bit_vector.h"

#include "vm/os.h"

namespace dart {

void BitVector::Iterator::Advance() {
  ++bit_index_;
  // Skip zero words.
  if (current_word_ == 0) {
    do {
      ++word_index_;
      if (Done()) return;
      current_word_ = target_->data_[word_index_];
    } while (current_word_ == 0);
    bit_index_ = word_index_ * kBitsPerWord;
  }
  // Skip zero bytes.
  while ((current_word_ & 0xff) == 0) {
    current_word_ >>= 8;
    bit_index_ += 8;
  }
  // Skip zero bits.
  while ((current_word_ & 0x1) == 0) {
    current_word_ >>= 1;
    ++bit_index_;
  }
  current_word_ = current_word_ >> 1;
}


}  // namespace dart
