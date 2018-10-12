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

  // Returns true if this loop is nested inside other loop.
  bool IsIn(LoopInfo* other) const;

  // Returns the nesting depth of this loop.
  intptr_t NestingDepth() const;

  // Getters.
  intptr_t id() const { return id_; }
  BlockEntryInstr* header() const { return header_; }
  BitVector* blocks() const { return blocks_; }
  LoopInfo* outer() const { return outer_; }
  LoopInfo* inner() const { return inner_; }
  LoopInfo* next() const { return next_; }
  LoopInfo* prev() const { return prev_; }

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

  // Loop hierarchy.
  LoopInfo* outer_;
  LoopInfo* inner_;
  LoopInfo* next_;
  LoopInfo* prev_;

  DISALLOW_COPY_AND_ASSIGN(LoopInfo);
};

// Information on the loop hierarchy in the flow graph.
class LoopHierarchy : public ZoneAllocated {
 public:
  explicit LoopHierarchy(ZoneGrowableArray<BlockEntryInstr*>* headers);

  // Getters.
  const ZoneGrowableArray<BlockEntryInstr*>& headers() const {
    return *headers_;
  }
  LoopInfo* first() const { return first_; }
  LoopInfo* last() const { return last_; }

 private:
  void AddLoop(LoopInfo* loop);
  void Build();

  ZoneGrowableArray<BlockEntryInstr*>* headers_;
  LoopInfo* first_;
  LoopInfo* last_;

  DISALLOW_COPY_AND_ASSIGN(LoopHierarchy);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_
