// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_
#define RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <utility>

#include "vm/allocation.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Information on an induction variable in a particular loop.
//
// Invariant:
//     offset + mult * def
// Linear:
//     initial + next * i, for invariant initial and next,
//                       and a "normalized" loop index i
// Wrap-around:
//     initial then next, for invariant initial and any next
// Periodic:
//     alternate initial and next, for invariant initial and next
//
class InductionVar : public ZoneAllocated {
 public:
  enum Kind {
    kInvariant,
    kLinear,
    kWrapAround,
    kPeriodic,
  };

  // Strict (exclusive) upper or lower bound on unit stride linear induction:
  //   i < U (i++)
  //   i > L (i--)
  struct Bound {
    Bound(BranchInstr* b, InductionVar* l) : branch_(b), limit_(l) {}
    BranchInstr* branch_;
    InductionVar* limit_;
  };

  // Constructor for an invariant.
  InductionVar(int64_t offset, int64_t mult, Definition* def)
      : kind_(kInvariant), offset_(offset), mult_(mult), def_(def), bounds_() {
    ASSERT(mult_ == 0 || def != nullptr);
  }

  // Constructor for a constant.
  explicit InductionVar(int64_t offset) : InductionVar(offset, 0, nullptr) {}

  // Constructor for an induction.
  InductionVar(Kind kind, InductionVar* initial, InductionVar* next)
      : kind_(kind), initial_(initial), next_(next), bounds_() {
    ASSERT(IsInvariant(initial));
    switch (kind) {
      case kLinear:
      case kPeriodic:
        ASSERT(IsInvariant(next));
        break;
      case kWrapAround:
        ASSERT(next != nullptr);
        break;
      default:
        UNREACHABLE();
    }
  }

  // Returns true if the other induction is structually equivalent.
  bool IsEqual(const InductionVar* other) const {
    ASSERT(other != nullptr);
    if (kind_ == other->kind_) {
      switch (kind_) {
        case kInvariant:
          return offset_ == other->offset_ && mult_ == other->mult_ &&
                 (mult_ == 0 || def_ == other->def_);
        case kLinear:
        case kWrapAround:
        case kPeriodic:
          return initial_->IsEqual(other->initial_) &&
                 next_->IsEqual(other->next_);
      }
    }
    return false;
  }

  // Returns true if a fixed difference between this and the other induction
  // can be computed. Sets the output parameter diff on success.
  bool CanComputeDifferenceWith(const InductionVar* other, int64_t* diff) const;

  // Returns true if this induction in the given loop can be bounded as
  // min <= this <= max by using bounds of more outer loops. On success
  // the output parameters min and max are set, which are always loop
  // invariant expressions inside the given loop.
  bool CanComputeBounds(LoopInfo* loop,
                        Instruction* pos,
                        InductionVar** min,
                        InductionVar** max);

  // Getters.
  Kind kind() const { return kind_; }
  int64_t offset() const {
    ASSERT(kind_ == kInvariant);
    return offset_;
  }
  int64_t mult() const {
    ASSERT(kind_ == kInvariant);
    return mult_;
  }
  Definition* def() const {
    ASSERT(kind_ == kInvariant);
    return def_;
  }
  InductionVar* initial() const {
    ASSERT(kind_ != kInvariant);
    return initial_;
  }
  InductionVar* next() const {
    ASSERT(kind_ != kInvariant);
    return next_;
  }
  const GrowableArray<Bound>& bounds() { return bounds_; }

  // For debugging.
  void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString() const;

  // Returns true if x is invariant.
  static bool IsInvariant(const InductionVar* x) {
    return x != nullptr && x->kind_ == kInvariant;
  }

  // Returns true if x is a constant (and invariant).
  static bool IsConstant(const InductionVar* x) {
    return x != nullptr && x->kind_ == kInvariant && x->mult_ == 0;
  }

  // Returns true if x is a constant. Sets the value.
  static bool IsConstant(const InductionVar* x, int64_t* c) {
    if (IsConstant(x)) {
      *c = x->offset_;
      return true;
    }
    return false;
  }

  // Returns true if x is linear.
  static bool IsLinear(const InductionVar* x) {
    return x != nullptr && x->kind_ == kLinear;
  }

  // Returns true if x is linear with constant stride. Sets the stride.
  static bool IsLinear(const InductionVar* x, int64_t* s) {
    if (IsLinear(x)) {
      return IsConstant(x->next_, s);
    }
    return false;
  }

  // Returns true if x is wrap-around.
  static bool IsWrapAround(const InductionVar* x) {
    return x != nullptr && x->kind_ == kWrapAround;
  }

  // Returns true if x is periodic.
  static bool IsPeriodic(const InductionVar* x) {
    return x != nullptr && x->kind_ == kPeriodic;
  }

  // Returns true if x is any induction.
  static bool IsInduction(const InductionVar* x) {
    return x != nullptr && x->kind_ != kInvariant;
  }

 private:
  friend class InductionVarAnalysis;

  // Induction classification.
  const Kind kind_;
  union {
    struct {
      int64_t offset_;
      int64_t mult_;
      Definition* def_;
    };
    struct {
      InductionVar* initial_;
      InductionVar* next_;
    };
  };

  bool CanComputeBoundsImpl(LoopInfo* loop,
                            Instruction* pos,
                            InductionVar** min,
                            InductionVar** max);

  // Bounds on induction.
  GrowableArray<Bound> bounds_;

  DISALLOW_COPY_AND_ASSIGN(InductionVar);
};

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

  // Returns true if given block is alway taken in this loop.
  bool IsAlwaysTaken(BlockEntryInstr* block) const;

  // Returns true if given definition is a header phi for this loop.
  bool IsHeaderPhi(Definition* def) const;

  // Returns true if this loop is nested inside given loop.
  bool IsIn(LoopInfo* loop) const;

  // Returns true if this loop contains given block.
  bool Contains(BlockEntryInstr* block) const;

  // Returns the nesting depth of this loop.
  intptr_t NestingDepth() const;

  // Resets induction.
  void ResetInduction();

  // Assigns induction to a definition.
  void AddInduction(Definition* def, InductionVar* induc);

  // Looks up induction.
  InductionVar* LookupInduction(Definition* def) const;

  // Tests if index stays in [0,length) range in this loop at given position.
  bool IsInRange(Instruction* pos, Value* index, Value* length);

  // Getters.
  intptr_t id() const { return id_; }
  BlockEntryInstr* header() const { return header_; }
  BitVector* blocks() const { return blocks_; }
  const GrowableArray<BlockEntryInstr*>& back_edges() { return back_edges_; }
  ConstraintInstr* limit() const { return limit_; }
  InductionVar* control() const { return control_; }
  LoopInfo* outer() const { return outer_; }
  LoopInfo* inner() const { return inner_; }
  LoopInfo* next() const { return next_; }

  // For debugging.
  void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString() const;

 private:
  friend class InductionVar;
  friend class InductionVarAnalysis;
  friend class LoopHierarchy;

  // Mapping from definition to induction.
  typedef RawPointerKeyValueTrait<Definition, InductionVar*> InductionKV;

  // Mapping from induction to mapping from instruction to induction pair.
  class MemoVal : public ZoneAllocated {
   public:
    typedef RawPointerKeyValueTrait<Instruction,
                                    std::pair<InductionVar*, InductionVar*>>
        PosKV;
    MemoVal() : memo_() {}
    DirectChainedHashMap<PosKV> memo_;
  };
  typedef RawPointerKeyValueTrait<InductionVar, MemoVal*> MemoKV;

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

  // Map definition -> induction for this loop.
  DirectChainedHashMap<InductionKV> induction_;

  // A small, per-loop memoization cache, to avoid costly
  // recomputations while traversing very deeply nested loops.
  DirectChainedHashMap<MemoKV> memo_cache_;

  // Constraint on a header phi.
  // TODO(ajcbik): very specific to smi range analysis,
  //               should we really store it here?
  ConstraintInstr* limit_;

  // Control induction.
  InductionVar* control_;

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

  // Performs induction variable analysis on all loops.
  void ComputeInduction() const;

 private:
  void Build();
  void Print(LoopInfo* loop) const;

  ZoneGrowableArray<BlockEntryInstr*>* headers_;
  const GrowableArray<BlockEntryInstr*>& preorder_;
  LoopInfo* top_;

  DISALLOW_COPY_AND_ASSIGN(LoopHierarchy);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOOPS_H_
