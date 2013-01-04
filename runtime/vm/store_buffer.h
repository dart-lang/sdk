// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STORE_BUFFER_H_
#define VM_STORE_BUFFER_H_

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/hash_set.h"

namespace dart {

// Forward declarations.
class Isolate;

class StoreBufferBlock {
 public:
  // Each block contains kSize pointers.
  static const int32_t kSize = 1024;

  StoreBufferBlock() : top_(0) {}

  static int top_offset() { return OFFSET_OF(StoreBufferBlock, top_); }
  static int pointers_offset() {
    return OFFSET_OF(StoreBufferBlock, pointers_);
  }

  void Reset() { top_ = 0; }

  intptr_t Count() const { return top_; }

  uword At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < top_);
    return pointers_[i];
  }

  // Add a pointer to the block of pointers. The buffer will be processed if it
  // has been filled by this operation.
  void AddPointer(uword pointer) {
    ASSERT(top_ < kSize);
    pointers_[top_++] = pointer;
    if (top_ == kSize) {
      ProcessBuffer();
    }
  }

  // Process this store buffer and remember its contents in the heap.
  void ProcessBuffer();
  void ProcessBuffer(Isolate* isolate);

  bool Contains(uword pointer);

 private:
  int32_t top_;
  uword pointers_[kSize];

  friend class StoreBuffer;

  DISALLOW_COPY_AND_ASSIGN(StoreBufferBlock);
};


class StoreBuffer {
 public:
  // Simple linked list element containing a HashSet of old->new pointers.
  class DedupSet {
   public:
    enum {
      kSetSize = 1024,
      kFillRatio = 75
    };

    explicit DedupSet(DedupSet* next)
        : next_(next), set_(new HashSet(kSetSize, kFillRatio)) {}
    ~DedupSet() {
      delete set_;
    }

    DedupSet* next() const { return next_; }
    HashSet* set() const { return set_; }

   private:
    DedupSet* next_;
    HashSet* set_;

    DISALLOW_COPY_AND_ASSIGN(DedupSet);
  };

  StoreBuffer() : dedup_sets_(new DedupSet(NULL)), count_(1) {}
  ~StoreBuffer();

  void Reset();

  void AddPointer(uword address);

  void ProcessBlock(StoreBufferBlock* block);

  DedupSet* DedupSets() {
    DedupSet* result = dedup_sets_;
    dedup_sets_ = new DedupSet(NULL);
    count_ = 1;
    return result;
  }

 private:
  DedupSet* dedup_sets_;
  intptr_t count_;

  DISALLOW_COPY_AND_ASSIGN(StoreBuffer);
};

}  // namespace dart

#endif  // VM_STORE_BUFFER_H_
