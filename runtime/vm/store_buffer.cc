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


StoreBuffer::List* StoreBuffer::global_empty_ = NULL;
Mutex* StoreBuffer::global_mutex_ = NULL;


void StoreBuffer::InitOnce() {
  global_empty_ = new List();
  global_mutex_ = new Mutex();
}


StoreBuffer::StoreBuffer() : mutex_(new Mutex()) {
}


StoreBuffer::~StoreBuffer() {
  Reset();
  delete mutex_;
}


void StoreBuffer::Reset() {
  MutexLocker local_mutex_locker(mutex_);
  {
    // Empty all blocks and move them to the global cache.
    MutexLocker global_mutex_locker(global_mutex_);
    while (!full_.IsEmpty()) {
      StoreBufferBlock* block = full_.Pop();
      block->Reset();
      global_empty_->Push(block);
    }
    while (!partial_.IsEmpty()) {
      StoreBufferBlock* block = partial_.Pop();
      block->Reset();
      global_empty_->Push(block);
    }
    TrimGlobalEmpty();
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
  ASSERT(block->next() == NULL);  // Should be just a single block.
  if (block->IsFull()) {
    MutexLocker ml(mutex_);
    full_.Push(block);
  } else if (block->IsEmpty()) {
    MutexLocker ml(global_mutex_);
    global_empty_->Push(block);
    TrimGlobalEmpty();
  } else {
    MutexLocker ml(mutex_);
    partial_.Push(block);
  }
  if (check_threshold && Overflowed()) {
    MutexLocker ml(mutex_);
    Isolate* isolate = Isolate::Current();
    // Sanity check: it makes no sense to schedule the GC in another isolate.
    // (If Isolate ever gets multiple store buffers, we should avoid this
    // coupling by passing in an explicit callback+parameter at construction.)
    ASSERT(isolate->store_buffer() == this);
    isolate->ScheduleInterrupts(Isolate::kVMInterrupt);
  }
}


StoreBufferBlock* StoreBuffer::PopNonFullBlock() {
  {
    MutexLocker ml(mutex_);
    if (!partial_.IsEmpty()) {
      return partial_.Pop();
    }
  }
  return PopEmptyBlock();
}


StoreBufferBlock* StoreBuffer::PopEmptyBlock() {
  {
    MutexLocker ml(global_mutex_);
    if (!global_empty_->IsEmpty()) {
      global_empty_->Pop();
    }
  }
  return new StoreBufferBlock();
}


StoreBufferBlock* StoreBuffer::PopNonEmptyBlock() {
  MutexLocker ml(mutex_);
  if (!full_.IsEmpty()) {
    return full_.Pop();
  } else if (!partial_.IsEmpty()) {
    return partial_.Pop();
  } else {
    return NULL;
  }
}


bool StoreBuffer::IsEmpty() {
  MutexLocker ml(global_mutex_);
  return full_.IsEmpty() && partial_.IsEmpty();
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
  ASSERT(block->next_ == NULL);
  block->next_ = head_;
  head_ = block;
  ++length_;
}


bool StoreBuffer::Overflowed() {
  MutexLocker ml(mutex_);
  return (full_.length() + partial_.length()) > kMaxNonEmpty;
}


void StoreBuffer::TrimGlobalEmpty() {
  DEBUG_ASSERT(global_mutex_->IsOwnedByCurrentThread());
  while (global_empty_->length() > kMaxGlobalEmpty) {
    delete global_empty_->Pop();
  }
}

}  // namespace dart
