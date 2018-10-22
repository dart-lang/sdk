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
      back_edges_(),
      outer_(nullptr),
      inner_(nullptr),
      next_(nullptr) {}

void LoopInfo::AddBlocks(BitVector* blocks) {
  blocks_->AddAll(blocks);
}

void LoopInfo::AddBackEdge(BlockEntryInstr* block) {
  back_edges_.Add(block);
}

bool LoopInfo::IsBackEdge(BlockEntryInstr* block) const {
  for (intptr_t i = 0, n = back_edges_.length(); i < n; i++) {
    if (back_edges_[i] == block) {
      return true;
    }
  }
  return false;
}

bool LoopInfo::IsIn(LoopInfo* other) const {
  if (other != nullptr) {
    return other->blocks_->Contains(header_->preorder_number());
  }
  return false;
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
  f.Print(" [");
  for (intptr_t i = 0, n = back_edges_.length(); i < n; i++) {
    f.Print(" B%" Pd, back_edges_[i]->block_id());
  }
  f.Print(" ]");
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

LoopHierarchy::LoopHierarchy(ZoneGrowableArray<BlockEntryInstr*>* headers,
                             const GrowableArray<BlockEntryInstr*>& preorder)
    : headers_(headers), preorder_(preorder), top_(nullptr) {
  Build();
}

void LoopHierarchy::Build() {
  // Link every entry block to the closest enveloping loop.
  for (intptr_t i = 0, n = headers_->length(); i < n; ++i) {
    LoopInfo* loop = (*headers_)[i]->loop_info();
    for (BitVector::Iterator it(loop->blocks()); !it.Done(); it.Advance()) {
      BlockEntryInstr* block = preorder_[it.Current()];
      if (block->loop_info() == nullptr) {
        block->set_loop_info(loop);
      } else {
        ASSERT(block->loop_info()->IsIn(loop));
      }
    }
  }
  // Build hierarchy from headers.
  for (intptr_t i = 0, n = headers_->length(); i < n; ++i) {
    BlockEntryInstr* header = (*headers_)[i];
    LoopInfo* loop = header->loop_info();
    LoopInfo* dom_loop = header->dominator()->loop_info();
    ASSERT(loop->outer_ == nullptr);
    ASSERT(loop->next_ == nullptr);
    if (loop->IsIn(dom_loop)) {
      loop->outer_ = dom_loop;
      loop->next_ = dom_loop->inner_;
      dom_loop->inner_ = loop;
    } else {
      loop->next_ = top_;
      top_ = loop;
    }
  }
  // If tracing is requested, print the loop hierarchy.
  if (FLAG_trace_optimization) {
    Print(top());
  }
}

void LoopHierarchy::Print(LoopInfo* loop) {
  for (; loop != nullptr; loop = loop->next_) {
    THR_Print("%s {", loop->ToCString());
    for (BitVector::Iterator it(loop->blocks()); !it.Done(); it.Advance()) {
      THR_Print(" B%" Pd, preorder_[it.Current()]->block_id());
    }
    THR_Print(" }\n");
    Print(loop->inner_);
  }
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
