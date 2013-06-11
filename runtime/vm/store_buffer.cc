// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "platform/assert.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, 1, Isolate* isolate) {
  StoreBuffer* buffer = isolate->store_buffer();
  buffer->Expand(true);
}
END_LEAF_RUNTIME_ENTRY


StoreBuffer::~StoreBuffer() {
  StoreBufferBlock* block = blocks_;
  blocks_ = NULL;
  while (block != NULL) {
    StoreBufferBlock* next = block->next();
    delete block;
    block = next;
  }
}


void StoreBuffer::Reset() {
  StoreBufferBlock* block = blocks_->next_;
  while (block != NULL) {
    StoreBufferBlock* next = block->next_;
    delete block;
    block = next;
  }
  blocks_->next_ = NULL;
  blocks_->top_ = 0;
  full_count_ = 0;
}


bool StoreBuffer::Contains(RawObject* raw) {
  StoreBufferBlock* block = blocks_;
  while (block != NULL) {
    intptr_t count = block->Count();
    for (intptr_t i = 0; i < count; i++) {
      if (block->At(i) == raw) {
        return true;
      }
    }
    block = block->next_;
  }
  return false;
}


void StoreBuffer::Expand(bool check) {
  ASSERT(blocks_->Count() == StoreBufferBlock::kSize);
  blocks_ = new StoreBufferBlock(blocks_);
  full_count_++;
  if (check) {
    CheckThreshold();
  }
}


void StoreBuffer::CheckThreshold() {
  // Schedule an interrupt if we have run over the max number of
  // StoreBufferBlocks.
  // TODO(iposva): Fix magic number.
  if (full_count_ > 100) {
    Isolate::Current()->ScheduleInterrupts(Isolate::kStoreBufferInterrupt);
  }
}

}  // namespace dart
