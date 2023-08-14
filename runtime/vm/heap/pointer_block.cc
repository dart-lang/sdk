// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/pointer_block.h"

#include "platform/assert.h"
#include "vm/lockers.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBufferBlockProcess, 1, Thread* thread) {
  thread->StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
}
END_LEAF_RUNTIME_ENTRY

DEFINE_LEAF_RUNTIME_ENTRY(void, MarkingStackBlockProcess, 1, Thread* thread) {
  thread->MarkingStackBlockProcess();
}
END_LEAF_RUNTIME_ENTRY

template <int BlockSize>
typename BlockStack<BlockSize>::List* BlockStack<BlockSize>::global_empty_ =
    nullptr;
template <int BlockSize>
Mutex* BlockStack<BlockSize>::global_mutex_ = nullptr;

template <int BlockSize>
void BlockStack<BlockSize>::Init() {
  global_empty_ = new List();
  if (global_mutex_ == nullptr) {
    global_mutex_ = new Mutex();
  }
}

template <int BlockSize>
void BlockStack<BlockSize>::Cleanup() {
  delete global_empty_;
  global_empty_ = nullptr;
}

template <int BlockSize>
BlockStack<BlockSize>::BlockStack() : monitor_() {}

template <int BlockSize>
BlockStack<BlockSize>::~BlockStack() {
  Reset();
}

template <int BlockSize>
void BlockStack<BlockSize>::Reset() {
  MonitorLocker local_mutex_locker(&monitor_);
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
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::TakeBlocks() {
  MonitorLocker ml(&monitor_);
  while (!partial_.IsEmpty()) {
    full_.Push(partial_.Pop());
  }
  return full_.PopAll();
}

template <int BlockSize>
void BlockStack<BlockSize>::PushBlockImpl(Block* block) {
  ASSERT(block->next() == nullptr);  // Should be just a single block.
  if (block->IsFull()) {
    MonitorLocker ml(&monitor_);
    bool was_empty = IsEmptyLocked();
    full_.Push(block);
    if (was_empty) ml.Notify();
  } else if (block->IsEmpty()) {
    MutexLocker ml(global_mutex_);
    global_empty_->Push(block);
    TrimGlobalEmpty();
  } else {
    MonitorLocker ml(&monitor_);
    bool was_empty = IsEmptyLocked();
    partial_.Push(block);
    if (was_empty) ml.Notify();
  }
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::WaitForWork(
    RelaxedAtomic<uintptr_t>* num_busy) {
  MonitorLocker ml(&monitor_);
  if (num_busy->fetch_sub(1u) == 1 /* 1 is before subtraction */) {
    // This is the last worker, wake the others now that we know no further work
    // will come.
    ml.NotifyAll();
    return nullptr;
  }
  for (;;) {
    if (!full_.IsEmpty()) {
      num_busy->fetch_add(1u);
      return full_.Pop();
    }
    if (!partial_.IsEmpty()) {
      num_busy->fetch_add(1u);
      return partial_.Pop();
    }
    ml.Wait();
    if (num_busy->load() == 0) {
      return nullptr;
    }
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
    MonitorLocker ml(&monitor_);
    Thread* thread = Thread::Current();
    // Sanity check: it makes no sense to schedule the GC in another isolate
    // group.
    // (If Isolate ever gets multiple store buffers, we should avoid this
    // coupling by passing in an explicit callback+parameter at construction.)
    ASSERT(thread->isolate_group()->store_buffer() == this);
    thread->ScheduleInterrupts(Thread::kVMInterrupt);
  }
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block*
BlockStack<BlockSize>::PopNonFullBlock() {
  {
    MonitorLocker ml(&monitor_);
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
  MonitorLocker ml(&monitor_);
  if (!full_.IsEmpty()) {
    return full_.Pop();
  } else if (!partial_.IsEmpty()) {
    return partial_.Pop();
  } else {
    return nullptr;
  }
}

template <int BlockSize>
bool BlockStack<BlockSize>::IsEmpty() {
  MonitorLocker ml(&monitor_);
  return IsEmptyLocked();
}

template <int BlockSize>
bool BlockStack<BlockSize>::IsEmptyLocked() {
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
  result->next_ = nullptr;
  return result;
}

template <int BlockSize>
typename BlockStack<BlockSize>::Block* BlockStack<BlockSize>::List::PopAll() {
  Block* result = head_;
  head_ = nullptr;
  length_ = 0;
  return result;
}

template <int BlockSize>
void BlockStack<BlockSize>::List::Push(Block* block) {
  ASSERT(block->next_ == nullptr);
  block->next_ = head_;
  head_ = block;
  ++length_;
}

bool StoreBuffer::Overflowed() {
  MonitorLocker ml(&monitor_);
  return (full_.length() + partial_.length()) > kMaxNonEmpty;
}

intptr_t StoreBuffer::Size() {
  ASSERT(Thread::Current()->OwnsGCSafepoint());  // No lock needed.
  return full_.length() + partial_.length();
}

void StoreBuffer::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  for (Block* block = full_.Peek(); block != nullptr; block = block->next()) {
    block->VisitObjectPointers(visitor);
  }
  for (Block* block = partial_.Peek(); block != nullptr;
       block = block->next()) {
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
