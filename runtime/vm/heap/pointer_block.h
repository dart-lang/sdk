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
  template <int, typename T>
  friend class LocalBlockWorkList;

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

  // Partially filled blocks can be reused, and there is an "infinite" supply
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

  Block* WaitForWork(RelaxedAtomic<uintptr_t>* num_busy);

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

  bool IsEmptyLocked();

  // Adds and transfers ownership of the block to the buffer.
  void PushBlockImpl(Block* block);

  // If needed, trims the global cache of empty blocks.
  static void TrimGlobalEmpty();

  List full_;
  List partial_;
  Monitor monitor_;

  // Note: This is shared on the basis of block size.
  static constexpr intptr_t kMaxGlobalEmpty = 100;
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
    local_output_ = stack_->PopEmptyBlock();
    local_input_ = stack_->PopEmptyBlock();
  }

  ~BlockWorkList() {
    ASSERT(local_output_ == nullptr);
    ASSERT(local_input_ == nullptr);
    ASSERT(stack_ == nullptr);
  }

  // Returns false if no more work was found.
  bool Pop(ObjectPtr* object) {
    ASSERT(local_input_ != nullptr);
    if (UNLIKELY(local_input_->IsEmpty())) {
      if (!local_output_->IsEmpty()) {
        auto temp = local_output_;
        local_output_ = local_input_;
        local_input_ = temp;
      } else {
        Block* new_work = stack_->PopNonEmptyBlock();
        if (new_work == nullptr) {
          return false;
        }
        stack_->PushBlock(local_input_);
        local_input_ = new_work;
        // Generated code appends to marking stacks; tell MemorySanitizer.
        MSAN_UNPOISON(local_input_, sizeof(*local_input_));
      }
    }
    *object = local_input_->Pop();
    return true;
  }

  void Push(ObjectPtr raw_obj) {
    if (UNLIKELY(local_output_->IsFull())) {
      stack_->PushBlock(local_output_);
      local_output_ = stack_->PopEmptyBlock();
    }
    local_output_->Push(raw_obj);
  }

  void Flush() {
    if (!local_output_->IsEmpty()) {
      stack_->PushBlock(local_output_);
      local_output_ = stack_->PopEmptyBlock();
    }
    if (!local_input_->IsEmpty()) {
      stack_->PushBlock(local_input_);
      local_input_ = stack_->PopEmptyBlock();
    }
  }

  bool WaitForWork(RelaxedAtomic<uintptr_t>* num_busy) {
    ASSERT(local_input_->IsEmpty());
    Block* new_work = stack_->WaitForWork(num_busy);
    if (new_work == nullptr) {
      return false;
    }
    stack_->PushBlock(local_input_);
    local_input_ = new_work;
    return true;
  }

  void Finalize() {
    ASSERT(local_output_->IsEmpty());
    stack_->PushBlock(local_output_);
    local_output_ = nullptr;
    ASSERT(local_input_->IsEmpty());
    stack_->PushBlock(local_input_);
    local_input_ = nullptr;
    // Fail fast on attempts to mark after finalizing.
    stack_ = nullptr;
  }

  void AbandonWork() {
    stack_->PushBlock(local_output_);
    local_output_ = nullptr;
    stack_->PushBlock(local_input_);
    local_input_ = nullptr;
    stack_ = nullptr;
  }

  bool IsLocalEmpty() {
    if (!local_input_->IsEmpty()) {
      return false;
    }
    if (!local_output_->IsEmpty()) {
      return false;
    }
    return true;
  }

  bool IsEmpty() { return IsLocalEmpty() && stack_->IsEmpty(); }

 private:
  Block* local_output_;
  Block* local_input_;
  Stack* stack_;
};

static constexpr int kStoreBufferBlockSize = 1024;
class StoreBuffer : public BlockStack<kStoreBufferBlockSize> {
 public:
  // Interrupt when crossing this threshold of non-empty blocks in the buffer.
  static constexpr intptr_t kMaxNonEmpty = 100;

  enum ThresholdPolicy { kCheckThreshold, kIgnoreThreshold };

  // Adds and transfers ownership of the block to the buffer. Optionally
  // checks the number of non-empty blocks for overflow, and schedules an
  // interrupt on the current isolate if so.
  void PushBlock(Block* block, ThresholdPolicy policy);

  // Check whether non-empty blocks have exceeded kMaxNonEmpty (but takes no
  // action).
  bool Overflowed();
  intptr_t Size();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);
};

typedef StoreBuffer::Block StoreBufferBlock;

static constexpr int kMarkingStackBlockSize = 64;
class MarkingStack : public BlockStack<kMarkingStackBlockSize> {
 public:
  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(Block* block) {
    BlockStack<Block::kSize>::PushBlockImpl(block);
  }
};

typedef MarkingStack::Block MarkingStackBlock;
typedef BlockWorkList<MarkingStack> MarkerWorkList;

static constexpr int kPromotionStackBlockSize = 64;
class PromotionStack : public BlockStack<kPromotionStackBlockSize> {
 public:
  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(Block* block) {
    BlockStack<Block::kSize>::PushBlockImpl(block);
  }
};

typedef PromotionStack::Block PromotionStackBlock;
typedef BlockWorkList<PromotionStack> PromotionWorkList;

template <int Size, typename T>
class LocalBlockWorkList : public ValueObject {
 public:
  LocalBlockWorkList() { head_ = new PointerBlock<Size>(); }
  ~LocalBlockWorkList() { ASSERT(head_ == nullptr); }

  template <typename Lambda>
  DART_FORCE_INLINE void Process(Lambda action) {
    auto* block = head_;
    head_ = new PointerBlock<Size>();
    while (block != nullptr) {
      while (!block->IsEmpty()) {
        action(static_cast<T>(block->Pop()));
      }
      auto* next = block->next();
      delete block;
      block = next;
    }
  }

  void Push(T obj) {
    if (UNLIKELY(head_->IsFull())) {
      PointerBlock<Size>* next = new PointerBlock<Size>();
      next->next_ = head_;
      head_ = next;
    }
    head_->Push(obj);
  }

  void Finalize() {
    ASSERT(head_ != nullptr);
    ASSERT(head_->IsEmpty());
    delete head_;
    head_ = nullptr;
  }

  void AbandonWork() {
    ASSERT(head_ != nullptr);
    auto* block = head_;
    head_ = nullptr;
    while (block != nullptr) {
      auto* next = block->next_;
      block->Reset();
      delete block;
      block = next;
    }
  }

 private:
  PointerBlock<Size>* head_;
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_POINTER_BLOCK_H_
