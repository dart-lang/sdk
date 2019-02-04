// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/loops.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Private class to perform induction variable analysis on a single loop
// or a full loop hierarchy. The analysis implementation is based on the
// paper by M. Gerlek et al. "Beyond Induction Variables: Detecting and
// Classifying Sequences Using a Demand-Driven SSA Form" (ACM Transactions
// on Programming Languages and Systems, Volume 17 Issue 1, Jan. 1995).
//
// The algorithm discovers and classifies definitions within loops that
// behave like induction variables, and attaches an InductionVar record
// to it (this mapping is stored in the loop data structure). The algorithm
// first finds strongly connected components in the flow graph and classifies
// each component as an induction when possible. Due to the descendant-first
// nature, classification happens "on-demand" (e.g. basic induction is
// classified before derived induction).
class InductionVarAnalysis : public ValueObject {
 public:
  // Constructor to set up analysis phase.
  explicit InductionVarAnalysis(const GrowableArray<BlockEntryInstr*>& preorder)
      : preorder_(preorder),
        stack_(),
        scc_(),
        cycle_(),
        map_(),
        current_index_(0),
        zone_(Thread::Current()->zone()) {}

  // Detects induction variables on the full loop hierarchy.
  void VisitHierarchy(LoopInfo* loop);

  // Detects induction variables on a single loop.
  void VisitLoop(LoopInfo* loop);

 private:
  // An information node needed during SCC traversal that can
  // reside in a map without any explicit memory allocation.
  struct SCCInfo {
    SCCInfo() : depth(-1), done(false) {}
    explicit SCCInfo(intptr_t d) : depth(d), done(false) {}
    intptr_t depth;
    bool done;
    bool operator!=(const SCCInfo& other) const {
      return depth != other.depth || done != other.done;
    }
    bool operator==(const SCCInfo& other) const {
      return depth == other.depth && done == other.done;
    }
  };
  typedef RawPointerKeyValueTrait<Definition, SCCInfo> VisitKV;

  // Traversal methods.
  bool Visit(LoopInfo* loop, Definition* def);
  intptr_t VisitDescendant(LoopInfo* loop, Definition* def);
  void Classify(LoopInfo* loop, Definition* def);
  void ClassifySCC(LoopInfo* loop);
  void ClassifyControl(LoopInfo* loop);

  // Transfer methods. Compute how induction of the operands, if any,
  // tranfers over the operation performed by the given definition.
  InductionVar* TransferPhi(LoopInfo* loop, Definition* def, intptr_t idx = -1);
  InductionVar* TransferBinary(LoopInfo* loop, Definition* def);
  InductionVar* TransferUnary(LoopInfo* loop, Definition* def);

  // Solver methods. Compute how temporary meaning given to the
  // definitions in a cycle transfer over the operation performed
  // by the given definition.
  InductionVar* SolvePhi(LoopInfo* loop, Definition* def, intptr_t idx = -1);
  InductionVar* SolveConstraint(LoopInfo* loop,
                                Definition* def,
                                InductionVar* init);
  InductionVar* SolveBinary(LoopInfo* loop,
                            Definition* def,
                            InductionVar* init);
  InductionVar* SolveUnary(LoopInfo* loop, Definition* def, InductionVar* init);

  // Lookup.
  InductionVar* Lookup(LoopInfo* loop, Definition* def);
  InductionVar* LookupCycle(Definition* def);

  // Arithmetic.
  InductionVar* Add(InductionVar* x, InductionVar* y);
  InductionVar* Sub(InductionVar* x, InductionVar* y);
  InductionVar* Mul(InductionVar* x, InductionVar* y);

  // Bookkeeping data (released when analysis goes out of scope).
  const GrowableArray<BlockEntryInstr*>& preorder_;
  GrowableArray<Definition*> stack_;
  GrowableArray<Definition*> scc_;
  GrowableArray<BranchInstr*> branches_;
  DirectChainedHashMap<LoopInfo::InductionKV> cycle_;
  DirectChainedHashMap<VisitKV> map_;
  intptr_t current_index_;
  Zone* zone_;

  DISALLOW_COPY_AND_ASSIGN(InductionVarAnalysis);
};

// Helper method that finds phi-index of the initial value
// that comes from a block outside the loop. Note that the
// algorithm still works if there are several of these.
static intptr_t InitIndex(LoopInfo* loop) {
  BlockEntryInstr* header = loop->header();
  for (intptr_t i = 0; i < header->PredecessorCount(); ++i) {
    if (!loop->Contains(header->PredecessorAt(i))) {  // pick first
      return i;
    }
  }
  UNREACHABLE();
  return -1;
}

// Helper method that determines if a definition is a constant.
static bool IsConstant(Definition* def, int64_t* val) {
  if (def->IsConstant()) {
    const Object& value = def->AsConstant()->value();
    if (value.IsInteger()) {
      *val = Integer::Cast(value).AsInt64Value();  // smi and mint
      return true;
    }
  }
  return false;
}

// Helper method to trace back to original true definition, now
// also ignoring constraints and (un)boxing operations, since
// these are not relevant to the induction behavior.
static Definition* OriginalDefinition(Definition* def) {
  while (true) {
    Definition* orig;
    if (def->IsConstraint() || def->IsBox() || def->IsUnbox()) {
      orig = def->InputAt(0)->definition();
    } else {
      orig = def->OriginalDefinition();
    }
    if (orig == def) return def;
    def = orig;
  }
}

void InductionVarAnalysis::VisitHierarchy(LoopInfo* loop) {
  for (; loop != nullptr; loop = loop->next_) {
    VisitLoop(loop);
    VisitHierarchy(loop->inner_);
  }
}

void InductionVarAnalysis::VisitLoop(LoopInfo* loop) {
  loop->ResetInduction();
  // Find strongly connected components (SSCs) in the SSA graph of this
  // loop using Tarjan's algorithm. Due to the descendant-first nature,
  // classification happens "on-demand".
  current_index_ = 0;
  ASSERT(stack_.is_empty());
  ASSERT(map_.IsEmpty());
  ASSERT(branches_.is_empty());
  for (BitVector::Iterator it(loop->blocks_); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = preorder_[it.Current()];
    ASSERT(block->loop_info() != nullptr);
    if (block->loop_info() != loop) {
      continue;  // inner loop
    }
    // Visit phi-operations.
    if (block->IsJoinEntry()) {
      for (PhiIterator it(block->AsJoinEntry()); !it.Done(); it.Advance()) {
        Visit(loop, it.Current());
      }
    }
    // Visit instructions and collect branches.
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* instruction = it.Current();
      Visit(loop, instruction->AsDefinition());
      if (instruction->IsBranch()) {
        branches_.Add(instruction->AsBranch());
      }
    }
  }
  ASSERT(stack_.is_empty());
  map_.Clear();
  // Classify loop control.
  ClassifyControl(loop);
  branches_.Clear();
}

bool InductionVarAnalysis::Visit(LoopInfo* loop, Definition* def) {
  if (def == nullptr || map_.HasKey(def)) {
    return false;  // no def, or already visited
  }
  intptr_t d = ++current_index_;
  map_.Insert(VisitKV::Pair(def, SCCInfo(d)));
  stack_.Add(def);

  // Visit all descendants.
  intptr_t low = d;
  for (intptr_t i = 0, n = def->InputCount(); i < n; i++) {
    Value* input = def->InputAt(i);
    if (input != nullptr) {
      low = Utils::Minimum(low, VisitDescendant(loop, input->definition()));
    }
  }

  // Lower or found SCC?
  if (low < d) {
    map_.Lookup(def)->value.depth = low;
  } else {
    // Pop the stack to build the SCC for classification.
    ASSERT(scc_.is_empty());
    while (!stack_.is_empty()) {
      Definition* top = stack_.RemoveLast();
      scc_.Add(top);
      map_.Lookup(top)->value.done = true;
      if (top == def) {
        break;
      }
    }
    // Classify.
    if (scc_.length() == 1) {
      Classify(loop, scc_[0]);
    } else {
      ASSERT(scc_.length() > 1);
      ASSERT(cycle_.IsEmpty());
      ClassifySCC(loop);
      cycle_.Clear();
    }
    scc_.Clear();
  }
  return true;
}

intptr_t InductionVarAnalysis::VisitDescendant(LoopInfo* loop,
                                               Definition* def) {
  // The traversal stops at anything not defined in this loop
  // (either a loop invariant entry value defined outside the
  // loop or an inner exit value defined by an inner loop).
  if (def->GetBlock()->loop_info() != loop) {
    return current_index_;
  }
  // Inspect descendant node.
  if (!Visit(loop, def) && map_.Lookup(def)->value.done) {
    return current_index_;
  }
  return map_.Lookup(def)->value.depth;
}

void InductionVarAnalysis::Classify(LoopInfo* loop, Definition* def) {
  // Classify different kind of instructions.
  InductionVar* induc = nullptr;
  if (loop->IsHeaderPhi(def)) {
    intptr_t idx = InitIndex(loop);
    induc = TransferPhi(loop, def, idx);
    if (induc != nullptr) {
      InductionVar* init = Lookup(loop, def->InputAt(idx)->definition());
      // Wrap-around (except for unusual header phi(x,..,x) = x).
      if (!init->IsEqual(induc)) {
        induc =
            new (zone_) InductionVar(InductionVar::kWrapAround, init, induc);
      }
    }
  } else if (def->IsPhi()) {
    induc = TransferPhi(loop, def);
  } else if (def->IsBinaryIntegerOp()) {
    induc = TransferBinary(loop, def);
  } else if (def->IsUnaryIntegerOp()) {
    induc = TransferUnary(loop, def);
  } else {
    Definition* orig = OriginalDefinition(def);
    if (orig != def) {
      induc = Lookup(loop, orig);  // pass-through
    }
  }
  // Successfully classified?
  if (induc != nullptr) {
    loop->AddInduction(def, induc);
  }
}

void InductionVarAnalysis::ClassifySCC(LoopInfo* loop) {
  intptr_t size = scc_.length();
  // Find a header phi, usually at the end.
  intptr_t p = -1;
  for (intptr_t i = size - 1; i >= 0; i--) {
    if (loop->IsHeaderPhi(scc_[i])) {
      p = i;
      break;
    }
  }
  // Rotate header phi up front.
  if (p >= 0) {
    Definition* phi = scc_[p];
    intptr_t idx = InitIndex(loop);
    InductionVar* init = Lookup(loop, phi->InputAt(idx)->definition());
    // Inspect remainder of the cycle. The cycle mapping assigns temporary
    // meaning to instructions, seeded from the phi instruction and back.
    // The init of the phi is passed as marker token to detect first use.
    cycle_.Insert(LoopInfo::InductionKV::Pair(phi, init));
    for (intptr_t i = 1, j = p; i < size; i++) {
      if (++j >= size) j = 0;
      Definition* def = scc_[j];
      InductionVar* update = nullptr;
      if (def->IsPhi()) {
        update = SolvePhi(loop, def);
      } else if (def->IsBinaryIntegerOp()) {
        update = SolveBinary(loop, def, init);
      } else if (def->IsUnaryIntegerOp()) {
        update = SolveUnary(loop, def, init);
      } else if (def->IsConstraint()) {
        update = SolveConstraint(loop, def, init);
      } else {
        Definition* orig = OriginalDefinition(def);
        if (orig != def) {
          update = LookupCycle(orig);  // pass-through
        }
      }
      // Continue cycle?
      if (update == nullptr) {
        return;
      }
      cycle_.Insert(LoopInfo::InductionKV::Pair(def, update));
    }
    // Success if all internal links (inputs to the phi that are along
    // back-edges) received the same temporary meaning. The external
    // link (initial value coming from outside the loop) is excluded
    // while taking this join.
    InductionVar* induc = SolvePhi(loop, phi, idx);
    if (induc != nullptr) {
      // Invariant means linear induction.
      if (induc->kind_ == InductionVar::kInvariant) {
        induc = new (zone_) InductionVar(InductionVar::kLinear, init, induc);
      } else {
        ASSERT(induc->kind_ == InductionVar::kPeriodic);
      }
      // Classify first phi and then the rest of the cycle "on-demand".
      loop->AddInduction(phi, induc);
      for (intptr_t i = 1, j = p; i < size; i++) {
        if (++j >= size) j = 0;
        Classify(loop, scc_[j]);
      }
    }
  }
}

void InductionVarAnalysis::ClassifyControl(LoopInfo* loop) {
  for (auto branch : branches_) {
    // Proper comparison?
    ComparisonInstr* compare = branch->comparison();
    if (compare->InputCount() != 2) {
      continue;
    }
    Token::Kind cmp = compare->kind();
    // Proper loop exit? Express the condition in "loop while true" form.
    TargetEntryInstr* ift = branch->true_successor();
    TargetEntryInstr* iff = branch->false_successor();
    if (loop->Contains(ift) && !loop->Contains(iff)) {
      // ok as is
    } else if (!loop->Contains(ift) && loop->Contains(iff)) {
      cmp = Token::NegateComparison(cmp);
    } else {
      continue;
    }
    // Comparison against linear constant stride induction?
    // Express the comparison such that induction appears left.
    int64_t stride = 0;
    InductionVar* x =
        Lookup(loop, OriginalDefinition(compare->left()->definition()));
    InductionVar* y =
        Lookup(loop, OriginalDefinition(compare->right()->definition()));
    if (InductionVar::IsLinear(x, &stride) && InductionVar::IsInvariant(y)) {
      // ok as is
    } else if (InductionVar::IsInvariant(x) &&
               InductionVar::IsLinear(y, &stride)) {
      InductionVar* tmp = x;
      x = y;
      y = tmp;
      cmp = Token::FlipComparison(cmp);
    } else {
      continue;
    }
    // Safe, strict comparison for looping condition? Note that
    // we reject symbolic bounds in non-strict looping conditions
    // like i <= U as upperbound or i >= L as lowerbound since this
    // could loop forever when U is kMaxInt64 or L is kMinInt64 under
    // Dart's 64-bit wrap-around arithmetic. Non-unit strides could
    // overshoot the bound with a wrap-around.
    //
    // TODO(ajcbik): accept more conditions when safe
    //
    switch (cmp) {
      case Token::kLT:
        // Accept i < U (i++).
        if (stride == 1) break;
        continue;
      case Token::kGT:
        // Accept i > L (i--).
        if (stride == -1) break;
        continue;
      case Token::kLTE: {
        // Accept i <= C (i++) as i < C + 1.
        int64_t end = 0;
        if (stride == 1 && InductionVar::IsConstant(y, &end) &&
            end < kMaxInt64) {
          y = new (zone_) InductionVar(end + 1);
          break;
        }
        continue;
      }
      case Token::kGTE: {
        // Accept i >= C (i--) as i > C - 1.
        int64_t end = 0;
        if (stride == -1 && InductionVar::IsConstant(y, &end) &&
            kMinInt64 < end) {
          y = new (zone_) InductionVar(end - 1);
          break;
        }
        continue;
      }
      case Token::kNE: {
        // Accept i != E as either i < E (i++) or i > E (i--)
        // for constants bounds that make the loop always-taken.
        int64_t start = 0;
        int64_t end = 0;
        if (InductionVar::IsConstant(x->initial_, &start) &&
            InductionVar::IsConstant(y, &end)) {
          if ((stride == +1 && start < end) || (stride == -1 && start > end)) {
            break;
          }
        }
        continue;
      }
      default:
        continue;
    }
    // We found a safe limit on the induction variable. Note that depending
    // on the intended use of this information, clients should still test
    // dominance on the test and the initial value of the induction variable.
    x->bounds_.Add(InductionVar::Bound(branch, y));
  }
}

InductionVar* InductionVarAnalysis::TransferPhi(LoopInfo* loop,
                                                Definition* def,
                                                intptr_t idx) {
  InductionVar* induc = nullptr;
  for (intptr_t i = 0, n = def->InputCount(); i < n; i++) {
    if (i != idx) {
      InductionVar* x = Lookup(loop, def->InputAt(i)->definition());
      if (x == nullptr) {
        return nullptr;
      } else if (induc == nullptr) {
        induc = x;
      } else if (!induc->IsEqual(x)) {
        return nullptr;
      }
    }
  }
  return induc;
}

InductionVar* InductionVarAnalysis::TransferBinary(LoopInfo* loop,
                                                   Definition* def) {
  InductionVar* x = Lookup(loop, def->InputAt(0)->definition());
  InductionVar* y = Lookup(loop, def->InputAt(1)->definition());

  switch (def->AsBinaryIntegerOp()->op_kind()) {
    case Token::kADD:
      return Add(x, y);
    case Token::kSUB:
      return Sub(x, y);
    case Token::kMUL:
      return Mul(x, y);
    default:
      return nullptr;
  }
}

InductionVar* InductionVarAnalysis::TransferUnary(LoopInfo* loop,
                                                  Definition* def) {
  InductionVar* x = Lookup(loop, def->InputAt(0)->definition());
  switch (def->AsUnaryIntegerOp()->op_kind()) {
    case Token::kNEGATE: {
      InductionVar* zero = new (zone_) InductionVar(0);
      return Sub(zero, x);
    }
    default:
      return nullptr;
  }
}

InductionVar* InductionVarAnalysis::SolvePhi(LoopInfo* loop,
                                             Definition* def,
                                             intptr_t idx) {
  InductionVar* induc = nullptr;
  for (intptr_t i = 0, n = def->InputCount(); i < n; i++) {
    if (i != idx) {
      InductionVar* c = LookupCycle(def->InputAt(i)->definition());
      if (c == nullptr) {
        return nullptr;
      } else if (induc == nullptr) {
        induc = c;
      } else if (!induc->IsEqual(c)) {
        return nullptr;
      }
    }
  }
  return induc;
}

InductionVar* InductionVarAnalysis::SolveConstraint(LoopInfo* loop,
                                                    Definition* def,
                                                    InductionVar* init) {
  InductionVar* c = LookupCycle(def->InputAt(0)->definition());
  if (c == init) {
    // Record a non-artifical bound constraint on a phi.
    ConstraintInstr* constraint = def->AsConstraint();
    if (constraint->target() != nullptr) {
      loop->limit_ = constraint;
    }
  }
  return c;
}

InductionVar* InductionVarAnalysis::SolveBinary(LoopInfo* loop,
                                                Definition* def,
                                                InductionVar* init) {
  InductionVar* x = Lookup(loop, def->InputAt(0)->definition());
  InductionVar* y = Lookup(loop, def->InputAt(1)->definition());
  switch (def->AsBinaryIntegerOp()->op_kind()) {
    case Token::kADD:
      if (InductionVar::IsInvariant(x)) {
        InductionVar* c = LookupCycle(def->InputAt(1)->definition());
        // The init marker denotes first use, otherwise aggregate.
        if (c == init) {
          return x;
        } else if (InductionVar::IsInvariant(c)) {
          return Add(x, c);
        }
      }
      if (InductionVar::IsInvariant(y)) {
        InductionVar* c = LookupCycle(def->InputAt(0)->definition());
        // The init marker denotes first use, otherwise aggregate.
        if (c == init) {
          return y;
        } else if (InductionVar::IsInvariant(c)) {
          return Add(c, y);
        }
      }
      return nullptr;
    case Token::kSUB:
      if (InductionVar::IsInvariant(x)) {
        InductionVar* c = LookupCycle(def->InputAt(1)->definition());
        // Note that i = x - i is periodic. The temporary
        // meaning is expressed in terms of the header phi.
        if (c == init) {
          InductionVar* next = Sub(x, init);
          if (InductionVar::IsInvariant(next)) {
            return new (zone_)
                InductionVar(InductionVar::kPeriodic, init, next);
          }
        }
      }
      if (InductionVar::IsInvariant(y)) {
        InductionVar* c = LookupCycle(def->InputAt(0)->definition());
        // The init marker denotes first use, otherwise aggregate.
        if (c == init) {
          InductionVar* zero = new (zone_) InductionVar(0);
          return Sub(zero, y);
        } else if (InductionVar::IsInvariant(c)) {
          return Sub(c, y);
        }
      }
      return nullptr;
    default:
      return nullptr;
  }
}

InductionVar* InductionVarAnalysis::SolveUnary(LoopInfo* loop,
                                               Definition* def,
                                               InductionVar* init) {
  InductionVar* c = LookupCycle(def->InputAt(0)->definition());
  switch (def->AsUnaryIntegerOp()->op_kind()) {
    case Token::kNEGATE:
      // Note that i = - i is periodic. The temporary
      // meaning is expressed in terms of the header phi.
      if (c == init) {
        InductionVar* zero = new (zone_) InductionVar(0);
        InductionVar* next = Sub(zero, init);
        if (InductionVar::IsInvariant(next)) {
          return new (zone_) InductionVar(InductionVar::kPeriodic, init, next);
        }
      }
      return nullptr;
    default:
      return nullptr;
  }
}

InductionVar* InductionVarAnalysis::Lookup(LoopInfo* loop, Definition* def) {
  InductionVar* induc = loop->LookupInduction(def);
  if (induc == nullptr) {
    // Loop-invariants are added lazily.
    int64_t val = 0;
    if (IsConstant(def, &val)) {
      induc = new (zone_) InductionVar(val);
      loop->AddInduction(def, induc);
    } else if (!loop->Contains(def->GetBlock())) {
      induc = new (zone_) InductionVar(0, 1, def);
      loop->AddInduction(def, induc);
    }
  }
  return induc;
}

InductionVar* InductionVarAnalysis::LookupCycle(Definition* def) {
  LoopInfo::InductionKV::Pair* pair = cycle_.Lookup(def);
  if (pair != nullptr) {
    return pair->value;
  }
  return nullptr;
}

InductionVar* InductionVarAnalysis::Add(InductionVar* x, InductionVar* y) {
  if (InductionVar::IsInvariant(x)) {
    if (InductionVar::IsInvariant(y)) {
      // Invariant + Invariant : only for same or just one instruction.
      if (x->def_ == y->def_) {
        return new (zone_)
            InductionVar(x->offset_ + y->offset_, x->mult_ + y->mult_, x->def_);
      } else if (y->mult_ == 0) {
        return new (zone_)
            InductionVar(x->offset_ + y->offset_, x->mult_, x->def_);
      } else if (x->mult_ == 0) {
        return new (zone_)
            InductionVar(x->offset_ + y->offset_, y->mult_, y->def_);
      }
    } else if (y != nullptr) {
      // Invariant + Induction.
      InductionVar* i = Add(x, y->initial_);
      InductionVar* n =
          y->kind_ == InductionVar::kLinear ? y->next_ : Add(x, y->next_);
      if (i != nullptr && n != nullptr) {
        return new (zone_) InductionVar(y->kind_, i, n);
      }
    }
  } else if (InductionVar::IsInvariant(y)) {
    if (x != nullptr) {
      // Induction + Invariant.
      ASSERT(!InductionVar::IsInvariant(x));
      InductionVar* i = Add(x->initial_, y);
      InductionVar* n =
          x->kind_ == InductionVar::kLinear ? x->next_ : Add(x->next_, y);
      if (i != nullptr && n != nullptr) {
        return new (zone_) InductionVar(x->kind_, i, n);
      }
    }
  } else if (InductionVar::IsLinear(x) && InductionVar::IsLinear(y)) {
    // Linear + Linear.
    InductionVar* i = Add(x->initial_, y->initial_);
    InductionVar* n = Add(x->next_, y->next_);
    if (i != nullptr && n != nullptr) {
      return new (zone_) InductionVar(InductionVar::kLinear, i, n);
    }
  }
  return nullptr;
}

InductionVar* InductionVarAnalysis::Sub(InductionVar* x, InductionVar* y) {
  if (InductionVar::IsInvariant(x)) {
    if (InductionVar::IsInvariant(y)) {
      // Invariant + Invariant : only for same or just one instruction.
      if (x->def_ == y->def_) {
        return new (zone_)
            InductionVar(x->offset_ - y->offset_, x->mult_ - y->mult_, x->def_);
      } else if (y->mult_ == 0) {
        return new (zone_)
            InductionVar(x->offset_ - y->offset_, x->mult_, x->def_);
      } else if (x->mult_ == 0) {
        return new (zone_)
            InductionVar(x->offset_ - y->offset_, -y->mult_, y->def_);
      }
    } else if (y != nullptr) {
      // Invariant - Induction.
      InductionVar* i = Sub(x, y->initial_);
      InductionVar* n;
      if (y->kind_ == InductionVar::kLinear) {
        InductionVar* zero = new (zone_) InductionVar(0, 0, nullptr);
        n = Sub(zero, y->next_);
      } else {
        n = Sub(x, y->next_);
      }
      if (i != nullptr && n != nullptr) {
        return new (zone_) InductionVar(y->kind_, i, n);
      }
    }
  } else if (InductionVar::IsInvariant(y)) {
    if (x != nullptr) {
      // Induction - Invariant.
      ASSERT(!InductionVar::IsInvariant(x));
      InductionVar* i = Sub(x->initial_, y);
      InductionVar* n =
          x->kind_ == InductionVar::kLinear ? x->next_ : Sub(x->next_, y);
      if (i != nullptr && n != nullptr) {
        return new (zone_) InductionVar(x->kind_, i, n);
      }
    }
  } else if (InductionVar::IsLinear(x) && InductionVar::IsLinear(y)) {
    // Linear - Linear.
    InductionVar* i = Sub(x->initial_, y->initial_);
    InductionVar* n = Sub(x->next_, y->next_);
    if (i != nullptr && n != nullptr) {
      return new (zone_) InductionVar(InductionVar::kLinear, i, n);
    }
  }
  return nullptr;
}

InductionVar* InductionVarAnalysis::Mul(InductionVar* x, InductionVar* y) {
  // Swap constant left.
  if (!InductionVar::IsConstant(x)) {
    InductionVar* tmp = x;
    x = y;
    y = tmp;
  }
  // Apply constant to any induction.
  if (InductionVar::IsConstant(x) && y != nullptr) {
    if (y->kind_ == InductionVar::kInvariant) {
      return new (zone_)
          InductionVar(x->offset_ * y->offset_, x->offset_ * y->mult_, y->def_);
    }
    return new (zone_)
        InductionVar(y->kind_, Mul(x, y->initial_), Mul(x, y->next_));
  }
  return nullptr;
}

const char* InductionVar::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  switch (kind_) {
    case kInvariant:
      if (mult_ != 0) {
        f.Print("(%" Pd64 " + %" Pd64 " x %.4s)", offset_, mult_,
                def_->ToCString());
      } else {
        f.Print("%" Pd64, offset_);
      }
      break;
    case kLinear:
      f.Print("LIN(%s + %s * i)", initial_->ToCString(), next_->ToCString());
      break;
    case kWrapAround:
      f.Print("WRAP(%s, %s)", initial_->ToCString(), next_->ToCString());
      break;
    case kPeriodic:
      f.Print("PERIOD(%s, %s)", initial_->ToCString(), next_->ToCString());
      break;
  }
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

LoopInfo::LoopInfo(intptr_t id, BlockEntryInstr* header, BitVector* blocks)
    : id_(id),
      header_(header),
      blocks_(blocks),
      back_edges_(),
      induction_(),
      limit_(nullptr),
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

bool LoopInfo::IsHeaderPhi(Definition* def) const {
  return def != nullptr && def->IsPhi() && def->GetBlock() == header_ &&
         !def->AsPhi()->IsRedundant();  // phi(x,..,x) = x
}

bool LoopInfo::IsIn(LoopInfo* loop) const {
  if (loop != nullptr) {
    return loop->Contains(header_);
  }
  return false;
}

bool LoopInfo::Contains(BlockEntryInstr* block) const {
  return blocks_->Contains(block->preorder_number());
}

intptr_t LoopInfo::NestingDepth() const {
  intptr_t nesting_depth = 1;
  for (LoopInfo* o = outer_; o != nullptr; o = o->outer()) {
    nesting_depth++;
  }
  return nesting_depth;
}

void LoopInfo::ResetInduction() {
  induction_.Clear();
}

void LoopInfo::AddInduction(Definition* def, InductionVar* induc) {
  ASSERT(def != nullptr);
  ASSERT(induc != nullptr);
  induction_.Insert(InductionKV::Pair(def, induc));
}

InductionVar* LoopInfo::LookupInduction(Definition* def) const {
  InductionKV::Pair* pair = induction_.Lookup(def);
  if (pair != nullptr) {
    return pair->value;
  }
  return nullptr;
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
    for (BitVector::Iterator it(loop->blocks_); !it.Done(); it.Advance()) {
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
    Print(top_);
  }
}

void LoopHierarchy::Print(LoopInfo* loop) {
  for (; loop != nullptr; loop = loop->next_) {
    THR_Print("%s {", loop->ToCString());
    for (BitVector::Iterator it(loop->blocks_); !it.Done(); it.Advance()) {
      THR_Print(" B%" Pd, preorder_[it.Current()]->block_id());
    }
    THR_Print(" }\n");
    Print(loop->inner_);
  }
}

void LoopHierarchy::ComputeInduction() const {
  InductionVarAnalysis(preorder_).VisitHierarchy(top_);
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
