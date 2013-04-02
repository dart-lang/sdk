// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "platform/assert.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, Isolate* isolate) {
  isolate->store_buffer_block()->ProcessBuffer(isolate);
}
END_LEAF_RUNTIME_ENTRY


void StoreBufferBlock::ProcessBuffer() {
  ProcessBuffer(Isolate::Current());
}


void StoreBufferBlock::ProcessBuffer(Isolate* isolate) {
  StoreBuffer* buffer = isolate->store_buffer();
  int32_t end = top_;
  for (int32_t i = 0; i < end; i++) {
    buffer->AddPointer(pointers_[i]);
  }
  top_ = 0;  // Reset back to the beginning.
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
    DedupSet* next = current->next();
    delete current;
    current = next;
  }
}


void StoreBuffer::Reset() {
  DedupSet* current = DedupSets();
  while (current != NULL) {
    DedupSet* next = current->next();
    delete current;
    current = next;
  }
}


void StoreBuffer::AddPointer(uword address) {
  ASSERT(dedup_sets_ != NULL);
  ASSERT(Isolate::Current()->heap()->OldContains(address));
  ASSERT((address & kSmiTagMask) != kSmiTag);
  if (!dedup_sets_->set()->Add(address)) {
    // Add a new DedupSet. Schedule an interrupt if we have run over the max
    // number of DedupSets.
    dedup_sets_ = new DedupSet(dedup_sets_);
    count_++;
    // TODO(iposva): Fix magic number.
    if (count_ > 100) {
      Isolate::Current()->ScheduleInterrupts(Isolate::kStoreBufferInterrupt);
    }
  }
}

}  // namespace dart
