// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "platform/assert.h"

namespace dart {

void StoreBufferBlock::ProcessBuffer() {
  // TODO(iposva): Do the right thing for store buffer overflow.
  top_ = 0;  // Currently just reset back to the beginning.
}


bool StoreBufferBlock::Contains(uword pointer) {
  for (int32_t i = 0; i < top_; i++) {
    if (pointers_[i] == pointer) {
      return true;
    }
  }
  return false;
}


StoreBuffer::~StoreBuffer() {
  DedupSet* current = dedup_sets_;
  dedup_sets_ = NULL;
  while (current != NULL) {
    DedupSet* next = current->next_;
    delete current;
    current = next;
  }
}


void StoreBuffer::AddPointer(uword address) {
  ASSERT(dedup_sets_ != NULL);
  if (!dedup_sets_->set_->Add(address)) {
    // TODO(iposva): Limit growth of deduplication sets until the rest of the
    // mechanism is hooked up.
    delete dedup_sets_;
    dedup_sets_ = NULL;

    DedupSet* fresh_element = new DedupSet();
    fresh_element->next_ = dedup_sets_;
    dedup_sets_ = fresh_element;
  }
}

}  // namespace dart
