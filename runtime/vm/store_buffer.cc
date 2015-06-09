// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "platform/assert.h"
#include "vm/lockers.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, 1, Thread* thread) {
  thread->StoreBufferBlockProcess(true);
}
END_LEAF_RUNTIME_ENTRY


StoreBuffer::StoreBuffer() : mutex_(new Mutex()) {
}


StoreBuffer::~StoreBuffer() {
  Reset();
  delete mutex_;
}


void StoreBuffer::Reset() {
  MutexLocker ml(mutex_);
  // TODO(koda): Reuse and share empty blocks between isolates.
  while (!full_.IsEmpty()) {
    delete full_.Pop();
  }
  while (!partial_.IsEmpty()) {
    delete partial_.Pop();
  }
}


StoreBufferBlock* StoreBuffer::Blocks() {
  MutexLocker ml(mutex_);
  while (!partial_.IsEmpty()) {
    full_.Push(partial_.Pop());
  }
  return full_.PopAll();
}


void StoreBuffer::PushBlock(StoreBufferBlock* block, bool check_threshold) {
  MutexLocker ml(mutex_);
  List* list = block->IsFull() ? &full_ : &partial_;
  list->Push(block);
  if (check_threshold) {
    CheckThreshold();
  }
}


StoreBufferBlock* StoreBuffer::PopBlock() {
  MutexLocker ml(mutex_);
  return (!partial_.IsEmpty()) ? partial_.Pop() : PopEmptyBlock();
}


StoreBufferBlock* StoreBuffer::PopEmptyBlock() {
  // TODO(koda): Reuse and share empty blocks between isolates.
  return new StoreBufferBlock();
}


StoreBuffer::List::~List() {
  while (!IsEmpty()) {
    delete Pop();
  }
}


StoreBufferBlock* StoreBuffer::List::Pop() {
  StoreBufferBlock* result = head_;
  head_ = head_->next_;
  --length_;
  result->next_ = NULL;
  return result;
}


StoreBufferBlock* StoreBuffer::List::PopAll() {
  StoreBufferBlock* result = head_;
  head_ = NULL;
  length_ = 0;
  return result;
}


void StoreBuffer::List::Push(StoreBufferBlock* block) {
  block->next_ = head_;
  head_ = block;
  ++length_;
}


void StoreBuffer::CheckThreshold() {
  // Schedule an interrupt if we have run over the max number of
  // StoreBufferBlocks.
  // TODO(koda): Pass threshold and callback in constructor. Cap total?
  if (full_.length() > 100) {
    Isolate::Current()->ScheduleInterrupts(Isolate::kStoreBufferInterrupt);
  }
}

}  // namespace dart
