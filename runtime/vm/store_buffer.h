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

class StoreBufferBlock {
 public:
  // Each full block contains kSize pointers.
  static const int32_t kSize = 1024;

  void Reset() { top_ = 0; }

  // TODO(koda): Make private after adding visitor interface to StoreBuffer.
  StoreBufferBlock* next() const { return next_; }

  intptr_t Count() const { return top_; }
  bool IsFull() const { return Count() == kSize; }

  void Add(RawObject* obj) {
    ASSERT(!IsFull());
    pointers_[top_++] = obj;
  }

  RawObject* At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < top_);
    return pointers_[i];
  }

#if defined(TESTING)
  bool Contains(RawObject* obj) const {
    for (intptr_t i = 0; i < Count(); i++) {
      if (At(i) == obj) {
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

  // Adds and transfers ownership of the block to the buffer.
  void PushBlock(StoreBufferBlock* block, bool check_threshold = true);
  // Partially filled blocks can be reused, and there is an "inifite" supply
  // of empty blocks (reused or newly allocated). In any case, the caller
  // takes ownership of the returned block.
  StoreBufferBlock* PopBlock();
  StoreBufferBlock* PopEmptyBlock();

  // Pops and returns all non-empty blocks as a linked list (owned by caller).
  // TODO(koda): Replace with VisitObjectPointers.
  StoreBufferBlock* Blocks();

  // Discards the contents of this store buffer.
  void Reset();

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

  // Check if we run over the max number of deduplication sets.
  // If we did schedule an interrupt.
  void CheckThreshold();

  List full_;
  List partial_;
  // TODO(koda): static List empty_
  Mutex* mutex_;

  DISALLOW_COPY_AND_ASSIGN(StoreBuffer);
};

}  // namespace dart

#endif  // VM_STORE_BUFFER_H_
