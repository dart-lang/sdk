// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_POINTER_BLOCK_H_
#define RUNTIME_VM_HEAP_POINTER_BLOCK_H_

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/os_thread.h"
#include "vm/tagged_pointer.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// A set of ObjectPtr. Must be emptied before destruction (using Pop/Reset).
template <int Size>
class PointerBlock : public MallocAllocated {
 public:
  enum { kSize = Size };

  void Reset() {
    top_ = 0;
    next_ = nullptr;
  }

  PointerBlock<Size>* next() const { return next_; }
  void set_next(PointerBlock<Size>* next) { next_ = next; }

  intptr_t Count() const { return top_; }
  bool IsFull() const { return Count() == kSize; }
  bool IsEmpty() const { return Count() == 0; }

  void Push(ObjectPtr obj) {
    ASSERT(!IsFull());
    pointers_[top_++] = obj;
  }

  ObjectPtr Pop() {
    ASSERT(!IsEmpty());
    return pointers_[--top_];
  }

#if defined(TESTING)
  bool Contains(ObjectPtr obj) const {
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(this, sizeof(*this));
    for (intptr_t i = 0; i < Count(); i++) {
      if (pointers_[i] == obj) {
        return true;
      }
    }
    return false;
  }
#endif  // TESTING

  static intptr_t top_offset() { return OFFSET_OF(PointerBlock<Size>, top_); }
  static intptr_t pointers_offset() {
    return OFFSET_OF(PointerBlock<Size>, pointers_);
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

 private:
  PointerBlock() : next_(nullptr), top_(0) {}
  ~PointerBlock() {
    ASSERT(IsEmpty());  // Guard against unintentionally discarding pointers.
  }

  PointerBlock<Size>* next_;
  int32_t top_;
  ObjectPtr pointers_[kSize];

  template <int>
  friend class BlockStack;

  DISALLOW_COPY_AND_ASSIGN(PointerBlock);
};

// A synchronized collection of pointer blocks of a particular size.
// This class is meant to be used as a base (note PushBlockImpl is protected).
// The global list of cached empty blocks is currently per-size.
template <int BlockSize>
class BlockStack {
 public:
  typedef PointerBlock<BlockSize> Block;

  BlockStack();
  ~BlockStack();
  static void Init();
  static void Cleanup();

  // Partially filled blocks can be reused, and there is an "inifite" supply
  // of empty blocks (reused or newly allocated). In any case, the caller
  // takes ownership of the returned block.
  Block* PopNonFullBlock();
  Block* PopEmptyBlock();
  Block* PopNonEmptyBlock();

  // Pops and returns all non-empty blocks as a linked list (owned by caller).
  Block* TakeBlocks();

  // Discards the contents of all non-empty blocks.
  void Reset();

  bool IsEmpty();

 protected:
  class List {
   public:
    List() : head_(nullptr), length_(0) {}
    ~List();
    void Push(Block* block);
    Block* Pop();
    intptr_t length() const { return length_; }
    bool IsEmpty() const { return head_ == nullptr; }
    Block* PopAll();
    Block* Peek() { return head_; }

   private:
    Block* head_;
    intptr_t length_;
    DISALLOW_COPY_AND_ASSIGN(List);
  };

  // Adds and transfers ownership of the block to the buffer.
  void PushBlockImpl(Block* block);

  // If needed, trims the global cache of empty blocks.
  static void TrimGlobalEmpty();

  List full_;
  List partial_;
  Mutex mutex_;

  // Note: This is shared on the basis of block size.
  static const intptr_t kMaxGlobalEmpty = 100;
  static List* global_empty_;
  static Mutex* global_mutex_;

 private:
  DISALLOW_COPY_AND_ASSIGN(BlockStack);
};

template <typename Stack>
class BlockWorkList : public ValueObject {
 public:
  typedef typename Stack::Block Block;

  explicit BlockWorkList(Stack* stack) : stack_(stack) {
    work_ = stack_->PopEmptyBlock();
  }

  ~BlockWorkList() {
    ASSERT(work_ == nullptr);
    ASSERT(stack_ == nullptr);
  }

  // Returns nullptr if no more work was found.
  ObjectPtr Pop() {
    ASSERT(work_ != nullptr);
    if (work_->IsEmpty()) {
      // TODO(koda): Track over/underflow events and use in heuristics to
      // distribute work and prevent degenerate flip-flopping.
      Block* new_work = stack_->PopNonEmptyBlock();
      if (new_work == nullptr) {
        return nullptr;
      }
      stack_->PushBlock(work_);
      work_ = new_work;
      // Generated code appends to marking stacks; tell MemorySanitizer.
      MSAN_UNPOISON(work_, sizeof(*work_));
    }
    return work_->Pop();
  }

  void Push(ObjectPtr raw_obj) {
    if (work_->IsFull()) {
      // TODO(koda): Track over/underflow events and use in heuristics to
      // distribute work and prevent degenerate flip-flopping.
      stack_->PushBlock(work_);
      work_ = stack_->PopEmptyBlock();
    }
    work_->Push(raw_obj);
  }

  void Finalize() {
    ASSERT(work_->IsEmpty());
    stack_->PushBlock(work_);
    work_ = nullptr;
    // Fail fast on attempts to mark after finalizing.
    stack_ = nullptr;
  }

  void AbandonWork() {
    stack_->PushBlock(work_);
    work_ = nullptr;
    stack_ = nullptr;
  }

  bool IsEmpty() {
    if (!work_->IsEmpty()) {
      return false;
    }
    return stack_->IsEmpty();
  }

 private:
  Block* work_;
  Stack* stack_;
};

static const int kStoreBufferBlockSize = 1024;
class StoreBuffer : public BlockStack<kStoreBufferBlockSize> {
 public:
  // Interrupt when crossing this threshold of non-empty blocks in the buffer.
  static const intptr_t kMaxNonEmpty = 100;

  enum ThresholdPolicy { kCheckThreshold, kIgnoreThreshold };

  // Adds and transfers ownership of the block to the buffer. Optionally
  // checks the number of non-empty blocks for overflow, and schedules an
  // interrupt on the current isolate if so.
  void PushBlock(Block* block, ThresholdPolicy policy);

  // Check whether non-empty blocks have exceeded kMaxNonEmpty (but takes no
  // action).
  bool Overflowed();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);
};

typedef StoreBuffer::Block StoreBufferBlock;

static const int kMarkingStackBlockSize = 64;
class MarkingStack : public BlockStack<kMarkingStackBlockSize> {
 public:
  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(Block* block) {
    BlockStack<Block::kSize>::PushBlockImpl(block);
  }
};

typedef MarkingStack::Block MarkingStackBlock;
typedef BlockWorkList<MarkingStack> MarkerWorkList;

static const int kPromotionStackBlockSize = 64;
class PromotionStack : public BlockStack<kPromotionStackBlockSize> {
 public:
  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(Block* block) {
    BlockStack<Block::kSize>::PushBlockImpl(block);
  }
};

typedef PromotionStack::Block PromotionStackBlock;
typedef BlockWorkList<PromotionStack> PromotionWorkList;

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_POINTER_BLOCK_H_
