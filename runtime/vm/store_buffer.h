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
class RawObject;

class StoreBufferBlock {
 public:
  // Each block contains kSize pointers.
  static const int32_t kSize = 1024;

  explicit StoreBufferBlock(StoreBufferBlock* next) : next_(next), top_(0) {}

  void Reset() { top_ = 0; }

  StoreBufferBlock* next() const { return next_; }

  intptr_t Count() const { return top_; }

  RawObject* At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < top_);
    return pointers_[i];
  }

  static intptr_t top_offset() { return OFFSET_OF(StoreBufferBlock, top_); }
  static intptr_t pointers_offset() {
    return OFFSET_OF(StoreBufferBlock, pointers_);
  }

 private:
  StoreBufferBlock* next_;
  int32_t top_;
  RawObject* pointers_[kSize];

  friend class StoreBuffer;

  DISALLOW_COPY_AND_ASSIGN(StoreBufferBlock);
};


class StoreBuffer {
 public:
  StoreBuffer() : blocks_(new StoreBufferBlock(NULL)), full_count_(0) {}
  explicit StoreBuffer(bool shallow_copy) : blocks_(NULL), full_count_(0) {
    // The value shallow_copy is only used to select this non-allocating
    // constructor. It is always expected to be true.
    ASSERT(shallow_copy);
  }
  ~StoreBuffer();

  intptr_t Count() const {
    return blocks_->Count() + (full_count_ * StoreBufferBlock::kSize);
  }

  void Reset();

  void AddObject(RawObject* obj) {
    StoreBufferBlock* block = blocks_;
    ASSERT(block->top_ < StoreBufferBlock::kSize);
    block->pointers_[block->top_++] = obj;
    if (block->top_ == StoreBufferBlock::kSize) {
      Expand(true);
    }
  }

  void AddObjectGC(RawObject* obj) {
    StoreBufferBlock* block = blocks_;
    ASSERT(block->top_ < StoreBufferBlock::kSize);
    block->pointers_[block->top_++] = obj;
    if (block->top_ == StoreBufferBlock::kSize) {
      Expand(false);
    }
  }

  StoreBufferBlock* Blocks() {
    StoreBufferBlock* result = blocks_;
    blocks_ = new StoreBufferBlock(NULL);
    full_count_ = 0;
    return result;
  }

  // Expand the storage and optionally check whethe to schedule an interrupt.
  void Expand(bool check);

  bool Contains(RawObject* raw);

  static int blocks_offset() { return OFFSET_OF(StoreBuffer, blocks_); }

 private:
  // Check if we run over the max number of deduplication sets.
  // If we did schedule an interrupt.
  void CheckThreshold();

  StoreBufferBlock* blocks_;
  intptr_t full_count_;

  DISALLOW_COPY_AND_ASSIGN(StoreBuffer);
};

}  // namespace dart

#endif  // VM_STORE_BUFFER_H_
