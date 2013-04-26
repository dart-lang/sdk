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
  isolate->store_buffer()->ProcessBlock(this);
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


bool StoreBuffer::AddPointerInternal(uword address) {
  ASSERT(dedup_sets_ != NULL);
  ASSERT(Isolate::Current()->heap()->OldContains(address));
  ASSERT((address & kSmiTagMask) != kSmiTag);
  if (!dedup_sets_->set()->Add(address)) {
    // Add a new DedupSet.
    dedup_sets_ = new DedupSet(dedup_sets_);
    count_++;
    return true;
  }
  return false;
}


void StoreBuffer::AddPointer(uword address) {
  if (AddPointerInternal(address)) {
    // Had to create a new DedupSet.
    CheckThreshold();
  }
}


bool StoreBuffer::DrainBlock(StoreBufferBlock* block) {
  const intptr_t old_count = count_;
  intptr_t entries = block->Count();
  for (intptr_t i = 0; i < entries; i++) {
    AddPointerInternal(block->At(i));
  }
  block->Reset();
  return (count_ > old_count);
}


void StoreBuffer::CheckThreshold() {
  // Schedule an interrupt if we have run over the max number of DedupSets.
  // TODO(iposva): Fix magic number.
  if (count_ > 100) {
    Isolate::Current()->ScheduleInterrupts(Isolate::kStoreBufferInterrupt);
  }
}


void StoreBuffer::ProcessBlock(StoreBufferBlock* block) {
  if (DrainBlock(block)) {
    CheckThreshold();
  }
}

}  // namespace dart
