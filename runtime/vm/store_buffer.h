// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STORE_BUFFER_H_
#define RUNTIME_VM_STORE_BUFFER_H_

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class Isolate;
class Mutex;
class RawObject;

// A set of RawObject*. Must be emptied before destruction (using Pop/Reset).
template <int Size>
class PointerBlock {
 public:
  enum { kSize = Size };

  void Reset() {
    top_ = 0;
    next_ = NULL;
  }

  PointerBlock<Size>* next() const { return next_; }

  intptr_t Count() const { return top_; }
  bool IsFull() const { return Count() == kSize; }
  bool IsEmpty() const { return Count() == 0; }

  void Push(RawObject* obj) {
    ASSERT(!IsFull());
    pointers_[top_++] = obj;
  }

  RawObject* Pop() {
    ASSERT(!IsEmpty());
    return pointers_[--top_];
  }

#if defined(TESTING)
  bool Contains(RawObject* obj) const {
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

 private:
  PointerBlock() : next_(NULL), top_(0) {}
  ~PointerBlock() {
    ASSERT(IsEmpty());  // Guard against unintentionally discarding pointers.
  }

  PointerBlock<Size>* next_;
  int32_t top_;
  RawObject* pointers_[kSize];

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
  static void InitOnce();
  static void ShutDown();

  // Partially filled blocks can be reused, and there is an "inifite" supply
  // of empty blocks (reused or newly allocated). In any case, the caller
  // takes ownership of the returned block.
  Block* PopNonFullBlock();
  Block* PopEmptyBlock();
  Block* PopNonEmptyBlock();

  // Pops and returns all non-empty blocks as a linked list (owned by caller).
  Block* Blocks();

  // Discards the contents of all non-empty blocks.
  void Reset();

  bool IsEmpty();

 protected:
  class List {
   public:
    List() : head_(NULL), length_(0) {}
    ~List();
    void Push(Block* block);
    Block* Pop();
    intptr_t length() const { return length_; }
    bool IsEmpty() const { return head_ == NULL; }
    Block* PopAll();

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
  Mutex* mutex_;

  // Note: This is shared on the basis of block size.
  static const intptr_t kMaxGlobalEmpty = 100;
  static List* global_empty_;
  static Mutex* global_mutex_;

 private:
  DISALLOW_COPY_AND_ASSIGN(BlockStack);
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

}  // namespace dart

#endif  // RUNTIME_VM_STORE_BUFFER_H_
