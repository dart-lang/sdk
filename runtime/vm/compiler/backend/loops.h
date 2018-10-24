// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_
#define RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_

#include "vm/allocation.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Information on a "natural loop" in the flow graph.
class LoopInfo : public ZoneAllocated {
 public:
  LoopInfo(intptr_t id, BlockEntryInstr* header, BitVector* blocks);

  // Merges given blocks to this loop.
  void AddBlocks(BitVector* blocks);

  // Adds back edge to this loop.
  void AddBackEdge(BlockEntryInstr* block);

  // Returns true if given block is backedge of this loop.
  bool IsBackEdge(BlockEntryInstr* block) const;

  // Returns true if this loop is nested inside other loop.
  bool IsIn(LoopInfo* other) const;

  // Returns the nesting depth of this loop.
  intptr_t NestingDepth() const;

  // Getters.
  intptr_t id() const { return id_; }
  BlockEntryInstr* header() const { return header_; }
  const GrowableArray<BlockEntryInstr*>& back_edges() { return back_edges_; }
  BitVector* blocks() const { return blocks_; }
  LoopInfo* outer() const { return outer_; }
  LoopInfo* inner() const { return inner_; }
  LoopInfo* next() const { return next_; }

  // For debugging.
  const char* ToCString() const;

 private:
  friend class LoopHierarchy;

  // Unique id of loop. We use its index in the
  // loop header array for this.
  const intptr_t id_;

  // Header of loop.
  BlockEntryInstr* header_;

  // Compact represention of every block in the loop,
  // indexed by its "preorder_number".
  BitVector* blocks_;

  // Back edges of loop (usually one).
  GrowableArray<BlockEntryInstr*> back_edges_;

  // Loop hierarchy.
  LoopInfo* outer_;
  LoopInfo* inner_;
  LoopInfo* next_;

  DISALLOW_COPY_AND_ASSIGN(LoopInfo);
};

// Information on the loop hierarchy in the flow graph.
class LoopHierarchy : public ZoneAllocated {
 public:
  LoopHierarchy(ZoneGrowableArray<BlockEntryInstr*>* headers,
                const GrowableArray<BlockEntryInstr*>& preorder);

  // Getters.
  const ZoneGrowableArray<BlockEntryInstr*>& headers() const {
    return *headers_;
  }
  LoopInfo* top() const { return top_; }

  // Returns total number of loops in the hierarchy.
  intptr_t num_loops() const { return headers_->length(); }

 private:
  void Build();
  void Print(LoopInfo* loop);

  ZoneGrowableArray<BlockEntryInstr*>* headers_;
  const GrowableArray<BlockEntryInstr*>& preorder_;
  LoopInfo* top_;

  DISALLOW_COPY_AND_ASSIGN(LoopHierarchy);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_
