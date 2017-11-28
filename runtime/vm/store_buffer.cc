// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "platform/assert.h"
#include "vm/lockers.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, 1, Thread* thread) {
  thread->StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
}
END_LEAF_RUNTIME_ENTRY

template <int BlockSize>
typename BlockStack<BlockSize>::List* BlockStack<BlockSize>::global_empty_ =
    NULL;
template <int BlockSize>
Mutex* BlockStack<BlockSize>::global_mutex_ = NULL;

template <int BlockSize>
void BlockStack<BlockSize>::InitOnce() {
  global_empty_ = new List();
  global_mutex_ = new Mutex();
}

template <int BlockSize>
void BlockStack<BlockSize>::ShutDown() {
  delete global_empty_;
  delete global_mutex_;
}

template <int BlockSize>
BlockStack<BlockSize>::BlockStack() : mutex_(new Mutex()) {}

template <int BlockSize>
BlockStack<BlockSize>::~BlockStack() {
  Reset();
  delete mutex_;
}

template <int BlockSize>
void BlockStack<BlockSize>::Reset() {
  MutexLocker local_mutex_locker(mutex_);
  {
    // Empty all blocks and move them to the global cache.
    MutexLocker global_mutex_locker(global_mutex_);
    while (!full_.IsEmpty()) {
      Block* block = full_.Pop();
      block->Reset();
      global_empty_->Push(block);
    }
    while (!partial_.IsEmpty()) {
      Block* block = partial_.Pop();
      block->Reset();
      global_empty_->Push(block);
    }
    TrimGlobalEmpty();
  }
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::Blocks() {
  MutexLocker ml(mutex_);
  while (!partial_.IsEmpty()) {
    full_.Push(partial_.Pop());
  }
  return full_.PopAll();
}

template <int BlockSize>
void BlockStack<BlockSize>::PushBlockImpl(Block* block) {
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
}

template <int Size>
void PointerBlock<Size>::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // Generated code appends to store buffers; tell MemorySanitizer.
  MSAN_UNPOISON(this, sizeof(*this));
  visitor->VisitPointers(&pointers_[0], top_);
}

void StoreBuffer::PushBlock(Block* block, ThresholdPolicy policy) {
  BlockStack<Block::kSize>::PushBlockImpl(block);
  if ((policy == kCheckThreshold) && Overflowed()) {
    MutexLocker ml(mutex_);
    Thread* thread = Thread::Current();
    // Sanity check: it makes no sense to schedule the GC in another isolate.
    // (If Isolate ever gets multiple store buffers, we should avoid this
    // coupling by passing in an explicit callback+parameter at construction.)
    ASSERT(thread->isolate()->store_buffer() == this);
    thread->ScheduleInterrupts(Thread::kVMInterrupt);
  }
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block*
BlockStack<BlockSize>::PopNonFullBlock() {
  {
    MutexLocker ml(mutex_);
    if (!partial_.IsEmpty()) {
      return partial_.Pop();
    }
  }
  return PopEmptyBlock();
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::PopEmptyBlock() {
  {
    MutexLocker ml(global_mutex_);
    if (!global_empty_->IsEmpty()) {
      return global_empty_->Pop();
    }
  }
  return new Block();
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block*
BlockStack<BlockSize>::PopNonEmptyBlock() {
  MutexLocker ml(mutex_);
  if (!full_.IsEmpty()) {
    return full_.Pop();
  } else if (!partial_.IsEmpty()) {
    return partial_.Pop();
  } else {
    return NULL;
  }
}

template <int BlockSize>
bool BlockStack<BlockSize>::IsEmpty() {
  MutexLocker ml(mutex_);
  return full_.IsEmpty() && partial_.IsEmpty();
}

template <int BlockSize>
BlockStack<BlockSize>::List::~List() {
  while (!IsEmpty()) {
    delete Pop();
  }
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::List::Pop() {
  Block* result = head_;
  head_ = head_->next_;
  --length_;
  result->next_ = NULL;
  return result;
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::List::PopAll() {
  Block* result = head_;
  head_ = NULL;
  length_ = 0;
  return result;
}

template <int BlockSize>
void BlockStack<BlockSize>::List::Push(Block* block) {
  ASSERT(block->next_ == NULL);
  block->next_ = head_;
  head_ = block;
  ++length_;
}

bool StoreBuffer::Overflowed() {
  MutexLocker ml(mutex_);
  return (full_.length() + partial_.length()) > kMaxNonEmpty;
}

void StoreBuffer::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  for (Block* block = full_.Peek(); block != NULL; block = block->next()) {
    block->VisitObjectPointers(visitor);
  }
  for (Block* block = partial_.Peek(); block != NULL; block = block->next()) {
    block->VisitObjectPointers(visitor);
  }
}

template <int BlockSize>
void BlockStack<BlockSize>::TrimGlobalEmpty() {
  DEBUG_ASSERT(global_mutex_->IsOwnedByCurrentThread());
  while (global_empty_->length() > kMaxGlobalEmpty) {
    delete global_empty_->Pop();
  }
}

template class BlockStack<kStoreBufferBlockSize>;
template class BlockStack<kMarkingStackBlockSize>;

}  // namespace dart
