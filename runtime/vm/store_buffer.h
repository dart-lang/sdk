// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STORE_BUFFER_H_
#define VM_STORE_BUFFER_H_

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class Isolate;
class Mutex;
class RawObject;

// A set of RawObject*. Must be emptied before destruction (using Pop/Reset).
class StoreBufferBlock {
 public:
  // Each full block contains kSize pointers.
  static const int32_t kSize = 1024;

  void Reset() {
    top_ = 0;
    next_ = NULL;
  }

  StoreBufferBlock* next() const { return next_; }

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

  static intptr_t top_offset() { return OFFSET_OF(StoreBufferBlock, top_); }
  static intptr_t pointers_offset() {
    return OFFSET_OF(StoreBufferBlock, pointers_);
  }

 private:
  StoreBufferBlock() : next_(NULL), top_(0) {}
  ~StoreBufferBlock() {
    ASSERT(IsEmpty());  // Guard against unintentionally discarding pointers.
  }

  StoreBufferBlock* next_;
  int32_t top_;
  RawObject* pointers_[kSize];

  friend class StoreBuffer;

  DISALLOW_COPY_AND_ASSIGN(StoreBufferBlock);
};


class StoreBuffer {
 public:
  StoreBuffer();
  ~StoreBuffer();
  static void InitOnce();

  // Interrupt when crossing this threshold of non-empty blocks in the buffer.
  static const intptr_t kMaxNonEmpty = 100;

  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(StoreBufferBlock* block, bool check_threshold = true);
  // Partially filled blocks can be reused, and there is an "inifite" supply
  // of empty blocks (reused or newly allocated). In any case, the caller
  // takes ownership of the returned block.
  StoreBufferBlock* PopNonFullBlock();
  StoreBufferBlock* PopEmptyBlock();
  StoreBufferBlock* PopNonEmptyBlock();

  // Pops and returns all non-empty blocks as a linked list (owned by caller).
  StoreBufferBlock* Blocks();

  // Discards the contents of this store buffer.
  void Reset();

  // Check whether non-empty blocks have exceeded kMaxNonEmpty.
  bool Overflowed();

  bool IsEmpty();

 private:
  class List {
   public:
    List() : head_(NULL), length_(0) {}
    ~List();
    void Push(StoreBufferBlock* block);
    StoreBufferBlock* Pop();
    intptr_t length() const { return length_; }
    bool IsEmpty() const { return head_ == NULL; }
    StoreBufferBlock* PopAll();
   private:
    StoreBufferBlock* head_;
    intptr_t length_;
    DISALLOW_COPY_AND_ASSIGN(List);
  };

  // If needed, trims the the global cache of empty blocks.
  static void TrimGlobalEmpty();

  List full_;
  List partial_;
  Mutex* mutex_;

  static const intptr_t kMaxGlobalEmpty = 100;
  static List* global_empty_;
  static Mutex* global_mutex_;

  DISALLOW_COPY_AND_ASSIGN(StoreBuffer);
};

}  // namespace dart

#endif  // VM_STORE_BUFFER_H_
