// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  InductionVar* TransferDef(LoopInfo* loop, Definition* def);
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

// Helper method to determine if a non-strict (inclusive) bound on
// a unit stride linear induction can be made strict (exclusive)
// without arithmetic wrap-around complications.
static bool CanBeMadeExclusive(LoopInfo* loop,
                               InductionVar* x,
                               Instruction* branch,
                               bool is_lower) {
  InductionVar* min = nullptr;
  InductionVar* max = nullptr;
  if (x->CanComputeBounds(loop, branch, &min, &max)) {
    int64_t end = 0;
    if (is_lower) {
      if (InductionVar::IsConstant(min, &end)) {
        return kMinInt64 < end;
      }
    } else if (InductionVar::IsConstant(max, &end)) {
      return end < kMaxInt64;
    } else if (InductionVar::IsInvariant(max) && max->mult() == 1 &&
               Definition::IsArrayLength(max->def())) {
      return max->offset() < 0;  // a.length - C, C > 0
    }
  }
  return false;
}

// Helper method to adjust a range [lower_bound,upper_bound] into the
// range [lower_bound+lower_bound_offset,upper_bound+upper_bound+offset]
// without arithmetic wrap-around complications. On entry, we know that
// lower_bound <= upper_bound is enforced by an actual comparison in the
// code (so that even if lower_bound > upper_bound, the loop is not taken).
// This method ensures the resulting range has the same property by
// very conservatively testing if everything stays between constants
// or a properly offset array length.
static bool SafelyAdjust(Zone* zone,
                         InductionVar* lower_bound,
                         int64_t lower_bound_offset,
                         InductionVar* upper_bound,
                         int64_t upper_bound_offset,
                         InductionVar** min,
                         InductionVar** max) {
  bool success = false;
  int64_t lval = 0;
  int64_t uval = 0;
  if (InductionVar::IsConstant(lower_bound, &lval)) {
    const int64_t l = lval + lower_bound_offset;
    if (InductionVar::IsConstant(upper_bound, &uval)) {
      // Make sure a proper new range [l,u] results. Even if bounds
      // were subject to arithmetic wrap-around, we preserve the
      // property that the minimum is in l and the maximum in u.
      const int64_t u = uval + upper_bound_offset;
      success = (l <= u);
    } else if (InductionVar::IsInvariant(upper_bound) &&
               upper_bound->mult() == 1 &&
               Definition::IsArrayLength(upper_bound->def())) {
      // No arithmetic wrap-around on the lower bound, and a properly
      // non-positive offset on an array length, which is always >= 0.
      const int64_t c = upper_bound->offset() + upper_bound_offset;
      success = ((lower_bound_offset >= 0 && lval <= l) ||
                 (lower_bound_offset < 0 && lval > l)) &&
                (c <= 0);
    }
  }
  if (success) {
    *min = (lower_bound_offset == 0)
               ? lower_bound
               : new (zone) InductionVar(lval + lower_bound_offset);
    *max = (upper_bound_offset == 0)
               ? upper_bound
               : new (zone)
                     InductionVar(upper_bound->offset() + upper_bound_offset,
                                  upper_bound->mult(), upper_bound->def());
  }
  return success;
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
  } else {
    induc = TransferDef(loop, def);
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
        Definition* orig = def->OriginalDefinitionIgnoreBoxingAndConstraints();
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
    auto left = compare->left()
                    ->definition()
                    ->OriginalDefinitionIgnoreBoxingAndConstraints();
    auto right = compare->right()
                     ->definition()
                     ->OriginalDefinitionIgnoreBoxingAndConstraints();
    InductionVar* x = Lookup(loop, left);
    InductionVar* y = Lookup(loop, right);
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
    // Can we find a strict (exclusive) comparison for the looping condition?
    // Note that we reject symbolic bounds in non-strict (inclusive) looping
    // conditions like i <= U as upperbound or i >= L as lowerbound since this
    // could loop forever when U is kMaxInt64 or L is kMinInt64 under Dart's
    // 64-bit arithmetic wrap-around. Non-unit strides could overshoot the
    // bound due to aritmetic wrap-around.
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
        // Accept i <= U (i++) as i < U + 1
        // only when U != MaxInt is certain.
        if (stride == 1 &&
            CanBeMadeExclusive(loop, y, branch, /*is_lower=*/false)) {
          y = Add(y, new (zone_) InductionVar(1));
          break;
        }
        continue;
      }
      case Token::kGTE: {
        // Accept i >= L (i--) as i > L - 1
        // only when L != MinInt is certain.
        if (stride == -1 &&
            CanBeMadeExclusive(loop, y, branch, /*is_lower=*/true)) {
          y = Sub(y, new (zone_) InductionVar(1));
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
    // We found a strict upper or lower bound on a unit stride linear
    // induction. Note that depending on the intended use of this
    // information, clients should still test dominance on the test
    // and the initial value of the induction variable.
    x->bounds_.Add(InductionVar::Bound(branch, y));
    // Record control induction.
    if (branch == loop->header_->last_instruction()) {
      loop->control_ = x;
    }
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

InductionVar* InductionVarAnalysis::TransferDef(LoopInfo* loop,
                                                Definition* def) {
  if (def->IsBinaryIntegerOp()) {
    return TransferBinary(loop, def);
  } else if (def->IsUnaryIntegerOp()) {
    return TransferUnary(loop, def);
  } else {
    // Note that induction analysis does not really need the second
    // argument of a bound check, since it will just pass-through the
    // index. However, we do a lookup on the, most likely loop-invariant,
    // length anyway, to make sure it is stored in the induction
    // environment for later lookup during BCE.
    if (auto check = def->AsCheckBoundBase()) {
      Definition* len = check->length()
                            ->definition()
                            ->OriginalDefinitionIgnoreBoxingAndConstraints();
      Lookup(loop, len);  // pre-store likely invariant length
    }
    // Proceed with regular pass-through.
    Definition* orig = def->OriginalDefinitionIgnoreBoxingAndConstraints();
    if (orig != def) {
      return Lookup(loop, orig);  // pass-through
    }
  }
  return nullptr;
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
      // Look "under the hood" of invariant definitions to expose
      // more details on common constructs like "length - 1".
      induc = TransferDef(loop, def);
      if (induc == nullptr) {
        induc = new (zone_) InductionVar(0, 1, def);
      }
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

bool InductionVar::CanComputeDifferenceWith(const InductionVar* other,
                                            int64_t* diff) const {
  if (IsInvariant(this) && IsInvariant(other)) {
    if (def_ == other->def_ && mult_ == other->mult_) {
      *diff = other->offset_ - offset_;
      return true;
    }
  } else if (IsLinear(this) && IsLinear(other)) {
    return next_->IsEqual(other->next_) &&
           initial_->CanComputeDifferenceWith(other->initial_, diff);
  }
  // TODO(ajcbik): examine other induction kinds too?
  return false;
}

bool InductionVar::CanComputeBoundsImpl(LoopInfo* loop,
                                        Instruction* pos,
                                        InductionVar** min,
                                        InductionVar** max) {
  // Refine symbolic part of an invariant with outward induction.
  if (IsInvariant(this)) {
    if (mult_ == 1 && def_ != nullptr) {
      for (loop = loop->outer(); loop != nullptr; loop = loop->outer()) {
        InductionVar* induc = loop->LookupInduction(def_);
        InductionVar* i_min = nullptr;
        InductionVar* i_max = nullptr;
        // Accept i+C with i in [L,U] as [L+C,U+C] when this adjustment
        // does not have arithmetic wrap-around complications.
        if (IsInduction(induc) &&
            induc->CanComputeBounds(loop, pos, &i_min, &i_max)) {
          Zone* z = Thread::Current()->zone();
          return SafelyAdjust(z, i_min, offset_, i_max, offset_, min, max);
        }
      }
    }
    // Otherwise invariant itself suffices.
    *min = *max = this;
    return true;
  }
  // Refine unit stride induction with lower and upper bound.
  //    for (int i = L; i < U; i++)
  //       j = i+C in [L+C,U+C-1]
  int64_t stride = 0;
  int64_t off = 0;
  if (IsLinear(this, &stride) && Utils::Abs(stride) == 1 &&
      CanComputeDifferenceWith(loop->control(), &off)) {
    // Find ranges on both L and U first (and not just minimum
    // of L and maximum of U) to avoid arithmetic wrap-around
    // complications such as the one shown below.
    //   for (int i = 0; i < maxint - 10; i++)
    //     for (int j = i + 20; j < 100; j++)
    //       j in [minint, 99] and not in [20, 100]
    InductionVar* l_min = nullptr;
    InductionVar* l_max = nullptr;
    if (initial_->CanComputeBounds(loop, pos, &l_min, &l_max)) {
      // Find extreme using a control bound for which the branch dominates
      // the given position (to make sure it really is under its control).
      // Then refine with anything that dominates that branch.
      for (auto bound : loop->control()->bounds()) {
        if (pos->IsDominatedBy(bound.branch_)) {
          InductionVar* u_min = nullptr;
          InductionVar* u_max = nullptr;
          if (bound.limit_->CanComputeBounds(loop, bound.branch_, &u_min,
                                             &u_max)) {
            Zone* z = Thread::Current()->zone();
            return stride > 0 ? SafelyAdjust(z, l_min, 0, u_max, -stride - off,
                                             min, max)
                              : SafelyAdjust(z, u_min, -stride - off, l_max, 0,
                                             min, max);
          }
        }
      }
    }
  }
  // Failure. TODO(ajcbik): examine other kinds of induction too?
  return false;
}

// Driver method to compute bounds with per-loop memoization.
bool InductionVar::CanComputeBounds(LoopInfo* loop,
                                    Instruction* pos,
                                    InductionVar** min,
                                    InductionVar** max) {
  // Consult cache first.
  LoopInfo::MemoKV::Pair* pair1 = loop->memo_cache_.Lookup(this);
  if (pair1 != nullptr) {
    LoopInfo::MemoVal::PosKV::Pair* pair2 = pair1->value->memo_.Lookup(pos);
    if (pair2 != nullptr) {
      *min = pair2->value.first;
      *max = pair2->value.second;
      return true;
    }
  }
  // Compute and cache.
  if (CanComputeBoundsImpl(loop, pos, min, max)) {
    ASSERT(*min != nullptr && *max != nullptr);
    LoopInfo::MemoVal* memo = nullptr;
    if (pair1 != nullptr) {
      memo = pair1->value;
    } else {
      memo = new LoopInfo::MemoVal();
      loop->memo_cache_.Insert(LoopInfo::MemoKV::Pair(this, memo));
    }
    memo->memo_.Insert(
        LoopInfo::MemoVal::PosKV::Pair(pos, std::make_pair(*min, *max)));
    return true;
  }
  return false;
}

void InductionVar::PrintTo(BaseTextBuffer* f) const {
  switch (kind_) {
    case kInvariant:
      if (mult_ != 0) {
        f->Printf("(%" Pd64 " + %" Pd64 " x %.4s)", offset_, mult_,
                  def_->ToCString());
      } else {
        f->Printf("%" Pd64, offset_);
      }
      break;
    case kLinear:
      f->Printf("LIN(%s + %s * i)", initial_->ToCString(), next_->ToCString());
      break;
    case kWrapAround:
      f->Printf("WRAP(%s, %s)", initial_->ToCString(), next_->ToCString());
      break;
    case kPeriodic:
      f->Printf("PERIOD(%s, %s)", initial_->ToCString(), next_->ToCString());
      break;
  }
}

const char* InductionVar::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

LoopInfo::LoopInfo(intptr_t id, BlockEntryInstr* header, BitVector* blocks)
    : id_(id),
      header_(header),
      blocks_(blocks),
      back_edges_(),
      induction_(),
      memo_cache_(),
      limit_(nullptr),
      control_(nullptr),
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

bool LoopInfo::IsAlwaysTaken(BlockEntryInstr* block) const {
  // The loop header is always executed when executing a loop (including
  // loop body of a do-while). Reject any other loop body block that is
  // not directly controlled by header.
  if (block == header_) {
    return true;
  } else if (block->PredecessorCount() != 1 ||
             block->PredecessorAt(0) != header_) {
    return false;
  }
  // If the loop has a control induction, make sure the condition is such
  // that the loop body is entered at least once from the header.
  if (control_ != nullptr) {
    InductionVar* limit = nullptr;
    for (auto bound : control_->bounds()) {
      if (bound.branch_ == header_->last_instruction()) {
        limit = bound.limit_;
        break;
      }
    }
    // Control iterates at least once?
    if (limit != nullptr) {
      int64_t stride = 0;
      int64_t begin = 0;
      int64_t end = 0;
      if (InductionVar::IsLinear(control_, &stride) &&
          InductionVar::IsConstant(control_->initial(), &begin) &&
          InductionVar::IsConstant(limit, &end) &&
          ((stride == 1 && begin < end) || (stride == -1 && begin > end))) {
        return true;
      }
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
  memo_cache_.Clear();
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

// Checks if an index is in range of a given length:
//   for (int i = initial; i <= length - C; i++) {
//     .... a[i] ....  // initial >= 0 and C > 0:
//   }
bool LoopInfo::IsInRange(Instruction* pos, Value* index, Value* length) {
  InductionVar* induc = LookupInduction(
      index->definition()->OriginalDefinitionIgnoreBoxingAndConstraints());
  InductionVar* len = LookupInduction(
      length->definition()->OriginalDefinitionIgnoreBoxingAndConstraints());
  if (induc != nullptr && len != nullptr) {
    // First, try the most common case. A simple induction directly
    // bounded by [c>=0,length-C>=0) for the length we are looking for.
    int64_t stride = 0;
    int64_t val = 0;
    int64_t diff = 0;
    if (InductionVar::IsLinear(induc, &stride) && stride == 1 &&
        InductionVar::IsConstant(induc->initial(), &val) && 0 <= val) {
      for (auto bound : induc->bounds()) {
        if (pos->IsDominatedBy(bound.branch_) &&
            len->CanComputeDifferenceWith(bound.limit_, &diff) && diff <= 0) {
          return true;
        }
      }
    }
    // If that fails, try to compute bounds using more outer loops.
    // Since array lengths >= 0, the conditions used during this
    // process avoid arithmetic wrap-around complications.
    InductionVar* min = nullptr;
    InductionVar* max = nullptr;
    if (induc->CanComputeBounds(this, pos, &min, &max)) {
      return InductionVar::IsConstant(min, &val) && 0 <= val &&
             len->CanComputeDifferenceWith(max, &diff) && diff < 0;
    }
  }
  return false;
}

void LoopInfo::PrintTo(BaseTextBuffer* f) const {
  f->Printf("%*c", static_cast<int>(2 * NestingDepth()), ' ');
  f->Printf("loop%" Pd " B%" Pd " ", id_, header_->block_id());
  intptr_t num_blocks = 0;
  for (BitVector::Iterator it(blocks_); !it.Done(); it.Advance()) {
    num_blocks++;
  }
  f->Printf("#blocks=%" Pd, num_blocks);
  if (outer_ != nullptr) f->Printf(" outer=%" Pd, outer_->id_);
  if (inner_ != nullptr) f->Printf(" inner=%" Pd, inner_->id_);
  if (next_ != nullptr) f->Printf(" next=%" Pd, next_->id_);
  f->AddString(" [");
  for (intptr_t i = 0, n = back_edges_.length(); i < n; i++) {
    f->Printf(" B%" Pd, back_edges_[i]->block_id());
  }
  f->AddString(" ]");
}

const char* LoopInfo::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
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

void LoopHierarchy::Print(LoopInfo* loop) const {
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
