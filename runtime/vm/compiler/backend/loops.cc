// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/loops.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/il.h"

namespace dart {

LoopInfo::LoopInfo(intptr_t id, BlockEntryInstr* header, BitVector* blocks)
    : id_(id),
      header_(header),
      blocks_(blocks),
      outer_(nullptr),
      inner_(nullptr),
      next_(nullptr),
      prev_(nullptr) {}

void LoopInfo::AddBlocks(BitVector* blocks) {
  blocks_->AddAll(blocks);
}

bool LoopInfo::IsIn(LoopInfo* other) const {
  return other->blocks_->Contains(header_->preorder_number());
}

intptr_t LoopInfo::NestingDepth() const {
  intptr_t nesting_depth = 1;
  for (LoopInfo* o = outer_; o != nullptr; o = o->outer()) {
    nesting_depth++;
  }
  return nesting_depth;
}

const char* LoopInfo::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  f.Print("%*c", static_cast<int>(2 * NestingDepth()), ' ');
  f.Print("loop%" Pd " B%" Pd " ", id_, header_->block_id());
  intptr_t num_blocks = 0;
  for (BitVector::Iterator it(blocks_); !it.Done(); it.Advance()) {
    num_blocks++;
  }
  f.Print("#blocks=%" Pd, num_blocks);
  if (outer_) f.Print(" outer=%" Pd, outer_->id_);
  if (inner_) f.Print(" inner=%" Pd, inner_->id_);
  if (next_) f.Print(" next=%" Pd, next_->id_);
  if (prev_) f.Print(" prev=%" Pd, prev_->id_);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

LoopHierarchy::LoopHierarchy(ZoneGrowableArray<BlockEntryInstr*>* headers)
    : headers_(headers), first_(nullptr), last_(nullptr) {
  Build();
}

void LoopHierarchy::AddLoop(LoopInfo* loop) {
  if (first_ == nullptr) {
    // First loop.
    ASSERT(last_ == nullptr);
    first_ = last_ = loop;
  } else if (loop->IsIn(last_)) {
    // First inner loop.
    loop->outer_ = last_;
    ASSERT(last_->inner_ == nullptr);
    last_ = last_->inner_ = loop;
  } else {
    // Subsequent loop.
    while (last_->outer_ != nullptr && !loop->IsIn(last_->outer_)) {
      last_ = last_->outer_;
    }
    loop->outer_ = last_->outer_;
    loop->prev_ = last_;
    ASSERT(last_->next_ == nullptr);
    last_ = last_->next_ = loop;
  }
}

void LoopHierarchy::Build() {
  for (intptr_t i = 0, n = headers_->length(); i < n; ++i) {
    LoopInfo* loop = (*headers_)[n - 1 - i]->loop_info();
    ASSERT(loop->id() == (n - 1 - i));
    AddLoop(loop);
  }
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
