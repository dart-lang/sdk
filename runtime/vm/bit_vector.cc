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


bool BitVector::AddAll(BitVector* from) {
  ASSERT(data_length_ == from->data_length_);
  bool changed = false;
  for (intptr_t i = 0; i < data_length_; i++) {
    const uword before = data_[i];
    const uword after = data_[i] | from->data_[i];
    if (before != after) changed = true;
    data_[i] = after;
  }
  return changed;
}


bool BitVector::KillAndAdd(BitVector* kill, BitVector* gen) {
  ASSERT(data_length_ == kill->data_length_);
  ASSERT(data_length_ == gen->data_length_);
  bool changed = false;
  for (intptr_t i = 0; i < data_length_; i++) {
    const uword before = data_[i];
    const uword after = data_[i] | (gen->data_[i] & ~kill->data_[i]);
    if (before != after) changed = true;
    data_[i] = after;
  }
  return changed;
}


}  // namespace dart
