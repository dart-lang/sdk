// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/range_analysis.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"

namespace dart {

DEFINE_FLAG(bool,
            array_bounds_check_elimination,
            true,
            "Eliminate redundant bounds checks.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool,
            trace_integer_ir_selection,
            false,
            "Print integer IR selection optimization pass.");
DECLARE_FLAG(bool, trace_constant_propagation);

// Quick access to the locally defined isolate() and zone() methods.
#define I (isolate())
#define Z (zone())

void RangeAnalysis::Analyze() {
  CollectValues();
  InsertConstraints();
  flow_graph_->GetLoopHierarchy().ComputeInduction();
  InferRanges();
  EliminateRedundantBoundsChecks();
  MarkUnreachableBlocks();

  NarrowMintToInt32();

  IntegerInstructionSelector iis(flow_graph_);
  iis.Select();

  RemoveConstraints();
}

// Helper method to chase to a constrained definition.
static Definition* UnwrapConstraint(Definition* defn) {
  while (defn->IsConstraint()) {
    defn = defn->AsConstraint()->value()->definition();
  }
  return defn;
}

void RangeAnalysis::CollectValues() {
  auto graph_entry = flow_graph_->graph_entry();

  auto& initial = *graph_entry->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* current = initial[i];
    if (IsIntegerDefinition(current)) {
      values_.Add(current);
    }
  }

  for (intptr_t i = 0; i < graph_entry->SuccessorCount(); ++i) {
    auto successor = graph_entry->SuccessorAt(i);
    if (auto entry = successor->AsBlockEntryWithInitialDefs()) {
      const auto& initial = *entry->initial_definitions();
      for (intptr_t j = 0; j < initial.length(); ++j) {
        Definition* current = initial[j];
        if (IsIntegerDefinition(current)) {
          values_.Add(current);
        }
      }
    }
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* current = phi_it.Current();
        if (current->Type()->IsInt()) {
          values_.Add(current);
        }
      }
    }

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if (defn != NULL) {
        if (defn->HasSSATemp() && IsIntegerDefinition(defn)) {
          values_.Add(defn);
          if (defn->IsBinaryInt64Op()) {
            binary_int64_ops_.Add(defn->AsBinaryInt64Op());
          } else if (defn->IsShiftInt64Op() ||
                     defn->IsSpeculativeShiftInt64Op()) {
            shift_int64_ops_.Add(defn->AsShiftIntegerOp());
          }
        }
      }
      if (auto check = current->AsCheckBoundBase()) {
        bounds_checks_.Add(check);
      }
    }
  }
}

// Given a boundary (right operand) and a comparison operation return
// a symbolic range constraint for the left operand of the comparison assuming
// that it evaluated to true.
// For example for the comparison a < b symbol a is constrained with range
// [Smi::kMinValue, b - 1].
Range* RangeAnalysis::ConstraintSmiRange(Token::Kind op, Definition* boundary) {
  switch (op) {
    case Token::kEQ:
      return new (Z) Range(RangeBoundary::FromDefinition(boundary),
                           RangeBoundary::FromDefinition(boundary));
    case Token::kNE:
      return new (Z) Range(Range::Full(RangeBoundary::kRangeBoundarySmi));
    case Token::kLT:
      return new (Z) Range(RangeBoundary::MinSmi(),
                           RangeBoundary::FromDefinition(boundary, -1));
    case Token::kGT:
      return new (Z) Range(RangeBoundary::FromDefinition(boundary, 1),
                           RangeBoundary::MaxSmi());
    case Token::kLTE:
      return new (Z) Range(RangeBoundary::MinSmi(),
                           RangeBoundary::FromDefinition(boundary));
    case Token::kGTE:
      return new (Z) Range(RangeBoundary::FromDefinition(boundary),
                           RangeBoundary::MaxSmi());
    default:
      UNREACHABLE();
      return NULL;
  }
}

ConstraintInstr* RangeAnalysis::InsertConstraintFor(Value* use,
                                                    Definition* defn,
                                                    Range* constraint_range,
                                                    Instruction* after) {
  // No need to constrain constants.
  if (defn->IsConstant()) return NULL;

  // Check if the value is already constrained to avoid inserting duplicated
  // constraints.
  ConstraintInstr* constraint = after->next()->AsConstraint();
  while (constraint != NULL) {
    if ((constraint->value()->definition() == defn) &&
        constraint->constraint()->Equals(constraint_range)) {
      return NULL;
    }
    constraint = constraint->next()->AsConstraint();
  }

  constraint = new (Z) ConstraintInstr(use->CopyWithType(), constraint_range);

  flow_graph_->InsertAfter(after, constraint, NULL, FlowGraph::kValue);
  FlowGraph::RenameDominatedUses(defn, constraint, constraint);
  constraints_.Add(constraint);
  return constraint;
}

bool RangeAnalysis::ConstrainValueAfterBranch(Value* use, Definition* defn) {
  BranchInstr* branch = use->instruction()->AsBranch();
  RelationalOpInstr* rel_op = branch->comparison()->AsRelationalOp();
  if ((rel_op != NULL) && (rel_op->operation_cid() == kSmiCid)) {
    // Found comparison of two smis. Constrain defn at true and false
    // successors using the other operand as a boundary.
    Definition* boundary;
    Token::Kind op_kind;
    if (use->use_index() == 0) {  // Left operand.
      boundary = rel_op->InputAt(1)->definition();
      op_kind = rel_op->kind();
    } else {
      ASSERT(use->use_index() == 1);  // Right operand.
      boundary = rel_op->InputAt(0)->definition();
      // InsertConstraintFor assumes that defn is left operand of a
      // comparison if it is right operand flip the comparison.
      op_kind = Token::FlipComparison(rel_op->kind());
    }

    // Constrain definition at the true successor.
    ConstraintInstr* true_constraint =
        InsertConstraintFor(use, defn, ConstraintSmiRange(op_kind, boundary),
                            branch->true_successor());
    if (true_constraint != NULL) {
      true_constraint->set_target(branch->true_successor());
    }

    // Constrain definition with a negated condition at the false successor.
    ConstraintInstr* false_constraint = InsertConstraintFor(
        use, defn,
        ConstraintSmiRange(Token::NegateComparison(op_kind), boundary),
        branch->false_successor());
    if (false_constraint != NULL) {
      false_constraint->set_target(branch->false_successor());
    }

    return true;
  }

  return false;
}

void RangeAnalysis::InsertConstraintsFor(Definition* defn) {
  for (Value* use = defn->input_use_list(); use != NULL;
       use = use->next_use()) {
    if (auto branch = use->instruction()->AsBranch()) {
      if (ConstrainValueAfterBranch(use, defn)) {
        Value* other_value = branch->InputAt(1 - use->use_index());
        if (!IsIntegerDefinition(other_value->definition())) {
          ConstrainValueAfterBranch(other_value, other_value->definition());
        }
      }
    } else if (auto check = use->instruction()->AsCheckBoundBase()) {
      ConstrainValueAfterCheckBound(use, check, defn);
    }
  }
}

void RangeAnalysis::ConstrainValueAfterCheckBound(Value* use,
                                                  CheckBoundBase* check,
                                                  Definition* defn) {
  const intptr_t use_index = use->use_index();

  Range* constraint_range = NULL;
  if (use_index == CheckBoundBase::kIndexPos) {
    Definition* length = check->length()->definition();
    constraint_range = new (Z) Range(RangeBoundary::FromConstant(0),
                                     RangeBoundary::FromDefinition(length, -1));
  } else {
    ASSERT(use_index == CheckBoundBase::kLengthPos);
    Definition* index = check->index()->definition();
    constraint_range = new (Z)
        Range(RangeBoundary::FromDefinition(index, 1), RangeBoundary::MaxSmi());
  }
  InsertConstraintFor(use, defn, constraint_range, check);
}

void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < values_.length(); i++) {
    InsertConstraintsFor(values_[i]);
  }

  for (intptr_t i = 0; i < constraints_.length(); i++) {
    InsertConstraintsFor(constraints_[i]);
  }
}

const Range* RangeAnalysis::GetSmiRange(Value* value) const {
  Definition* defn = value->definition();
  const Range* range = defn->range();

  if ((range == NULL) && (defn->Type()->ToCid() != kSmiCid)) {
    // Type propagator determined that reaching type for this use is Smi.
    // However the definition itself is not a smi-definition and
    // thus it will never have range assigned to it. Just return the widest
    // range possible for this value.
    // We don't need to handle kMintCid here because all external mints
    // (e.g. results of loads or function call) can be used only after they
    // pass through UnboxInt64Instr which is considered as mint-definition
    // and will have a range assigned to it.
    // Note: that we can't return NULL here because it is used as lattice's
    // bottom element to indicate that the range was not computed *yet*.
    return &smi_range_;
  }

  return range;
}

const Range* RangeAnalysis::GetIntRange(Value* value) const {
  Definition* defn = value->definition();
  const Range* range = defn->range();

  if ((range == NULL) && !defn->Type()->IsInt()) {
    // Type propagator determined that reaching type for this use is int.
    // However the definition itself is not a int-definition and
    // thus it will never have range assigned to it. Just return the widest
    // range possible for this value.
    // Note: that we can't return NULL here because it is used as lattice's
    // bottom element to indicate that the range was not computed *yet*.
    return &int64_range_;
  }

  return range;
}

const char* RangeBoundary::KindToCString(Kind kind) {
  switch (kind) {
#define KIND_CASE(name)                                                        \
  case Kind::k##name:                                                          \
    return #name;
    FOR_EACH_RANGE_BOUNDARY_KIND(KIND_CASE)
#undef KIND_CASE
    default:
      UNREACHABLE();
      return nullptr;
  }
}

bool RangeBoundary::ParseKind(const char* str, Kind* out) {
#define KIND_CASE(name)                                                        \
  if (strcmp(str, #name) == 0) {                                               \
    *out = Kind::k##name;                                                      \
    return true;                                                               \
  }
  FOR_EACH_RANGE_BOUNDARY_KIND(KIND_CASE)
#undef KIND_CASE
  return false;
}

static bool AreEqualDefinitions(Definition* a, Definition* b) {
  a = UnwrapConstraint(a);
  b = UnwrapConstraint(b);
  return (a == b) || (a->AllowsCSE() && b->AllowsCSE() && a->Equals(b));
}

static bool DependOnSameSymbol(const RangeBoundary& a, const RangeBoundary& b) {
  return a.IsSymbol() && b.IsSymbol() &&
         AreEqualDefinitions(a.symbol(), b.symbol());
}

// Given the current range of a phi and a newly computed range check
// if it is growing towards negative infinity, if it does widen it to
// MinSmi.
static RangeBoundary WidenMin(const Range* range,
                              const Range* new_range,
                              RangeBoundary::RangeSize size) {
  RangeBoundary min = range->min();
  RangeBoundary new_min = new_range->min();

  if (min.IsSymbol()) {
    if (min.LowerBound().Overflowed(size)) {
      return RangeBoundary::MinConstant(size);
    } else if (DependOnSameSymbol(min, new_min)) {
      return min.offset() <= new_min.offset()
                 ? min
                 : RangeBoundary::MinConstant(size);
    } else if (min.UpperBound(size) <= new_min.LowerBound(size)) {
      return min;
    }
  }

  min = Range::ConstantMin(range, size);
  new_min = Range::ConstantMin(new_range, size);

  return (min.ConstantValue() <= new_min.ConstantValue())
             ? min
             : RangeBoundary::MinConstant(size);
}

// Given the current range of a phi and a newly computed range check
// if it is growing towards positive infinity, if it does widen it to
// MaxSmi.
static RangeBoundary WidenMax(const Range* range,
                              const Range* new_range,
                              RangeBoundary::RangeSize size) {
  RangeBoundary max = range->max();
  RangeBoundary new_max = new_range->max();

  if (max.IsSymbol()) {
    if (max.UpperBound().Overflowed(size)) {
      return RangeBoundary::MaxConstant(size);
    } else if (DependOnSameSymbol(max, new_max)) {
      return max.offset() >= new_max.offset()
                 ? max
                 : RangeBoundary::MaxConstant(size);
    } else if (max.LowerBound(size) >= new_max.UpperBound(size)) {
      return max;
    }
  }

  max = Range::ConstantMax(range, size);
  new_max = Range::ConstantMax(new_range, size);

  return (max.ConstantValue() >= new_max.ConstantValue())
             ? max
             : RangeBoundary::MaxConstant(size);
}

// Given the current range of a phi and a newly computed range check
// if we can perform narrowing: use newly computed minimum to improve precision
// of the computed range. We do it only if current minimum was widened and is
// equal to MinSmi.
// Newly computed minimum is expected to be greater or equal than old one as
// we are running after widening phase.
static RangeBoundary NarrowMin(const Range* range,
                               const Range* new_range,
                               RangeBoundary::RangeSize size) {
  const RangeBoundary min = Range::ConstantMin(range, size);
  const RangeBoundary new_min = Range::ConstantMin(new_range, size);
  if (min.ConstantValue() > new_min.ConstantValue()) return range->min();

  // TODO(vegorov): consider using negative infinity to indicate widened bound.
  return range->min().IsMinimumOrBelow(size) ? new_range->min() : range->min();
}

// Given the current range of a phi and a newly computed range check
// if we can perform narrowing: use newly computed maximum to improve precision
// of the computed range. We do it only if current maximum was widened and is
// equal to MaxSmi.
// Newly computed maximum is expected to be less or equal than old one as
// we are running after widening phase.
static RangeBoundary NarrowMax(const Range* range,
                               const Range* new_range,
                               RangeBoundary::RangeSize size) {
  const RangeBoundary max = Range::ConstantMax(range, size);
  const RangeBoundary new_max = Range::ConstantMax(new_range, size);
  if (max.ConstantValue() < new_max.ConstantValue()) return range->max();

  // TODO(vegorov): consider using positive infinity to indicate widened bound.
  return range->max().IsMaximumOrAbove(size) ? new_range->max() : range->max();
}

char RangeAnalysis::OpPrefix(JoinOperator op) {
  switch (op) {
    case WIDEN:
      return 'W';
    case NARROW:
      return 'N';
    case NONE:
      return 'I';
  }
  UNREACHABLE();
  return ' ';
}

static RangeBoundary::RangeSize RangeSizeForPhi(Definition* phi) {
  ASSERT(phi->IsPhi());
  if (phi->Type()->ToCid() == kSmiCid) {
    return RangeBoundary::kRangeBoundarySmi;
  } else if (phi->representation() == kUnboxedInt32) {
    return RangeBoundary::kRangeBoundaryInt32;
  } else if (phi->Type()->IsInt()) {
    return RangeBoundary::kRangeBoundaryInt64;
  } else {
    UNREACHABLE();
    return RangeBoundary::kRangeBoundaryInt64;
  }
}

bool RangeAnalysis::InferRange(JoinOperator op,
                               Definition* defn,
                               intptr_t iteration) {
  Range range;
  defn->InferRange(this, &range);

  if (!Range::IsUnknown(&range)) {
    if (!Range::IsUnknown(defn->range()) && defn->IsPhi()) {
      const RangeBoundary::RangeSize size = RangeSizeForPhi(defn);
      if (op == WIDEN) {
        range = Range(WidenMin(defn->range(), &range, size),
                      WidenMax(defn->range(), &range, size));
      } else if (op == NARROW) {
        range = Range(NarrowMin(defn->range(), &range, size),
                      NarrowMax(defn->range(), &range, size));
      }
    }

    if (!range.Equals(defn->range())) {
#ifndef PRODUCT
      if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
        THR_Print("%c [%" Pd "] %s:  %s => %s\n", OpPrefix(op), iteration,
                  defn->ToCString(), Range::ToCString(defn->range()),
                  Range::ToCString(&range));
      }
#endif  // !PRODUCT
      defn->set_range(range);
      return true;
    }
  }

  return false;
}

void RangeAnalysis::CollectDefinitions(BitVector* set) {
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        if (set->Contains(phi->ssa_temp_index())) {
          definitions_.Add(phi);
        }
      }
    }

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Definition* defn = it.Current()->AsDefinition();
      if ((defn != NULL) && defn->HasSSATemp() &&
          set->Contains(defn->ssa_temp_index())) {
        definitions_.Add(defn);
      }
    }
  }
}

void RangeAnalysis::Iterate(JoinOperator op, intptr_t max_iterations) {
  // TODO(vegorov): switch to worklist if this becomes performance bottleneck.
  intptr_t iteration = 0;
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < definitions_.length(); i++) {
      Definition* defn = definitions_[i];
      if (InferRange(op, defn, iteration)) {
        changed = true;
      }
    }

    iteration++;
  } while (changed && (iteration < max_iterations));
}

void RangeAnalysis::InferRanges() {
  Zone* zone = flow_graph_->zone();
  // Initialize bitvector for quick filtering of int values.
  BitVector* set =
      new (zone) BitVector(zone, flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < values_.length(); i++) {
    set->Add(values_[i]->ssa_temp_index());
  }
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    set->Add(constraints_[i]->ssa_temp_index());
  }

  // Collect integer definitions (including constraints) in the reverse
  // postorder. This improves convergence speed compared to iterating
  // values_ and constraints_ array separately.
  auto graph_entry = flow_graph_->graph_entry();
  const auto& initial = *graph_entry->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* definition = initial[i];
    if (set->Contains(definition->ssa_temp_index())) {
      definitions_.Add(definition);
    }
  }

  for (intptr_t i = 0; i < graph_entry->SuccessorCount(); ++i) {
    auto successor = graph_entry->SuccessorAt(i);
    if (auto function_entry = successor->AsFunctionEntry()) {
      const auto& initial = *function_entry->initial_definitions();
      for (intptr_t j = 0; j < initial.length(); ++j) {
        Definition* definition = initial[j];
        if (set->Contains(definition->ssa_temp_index())) {
          definitions_.Add(definition);
        }
      }
    }
  }

  CollectDefinitions(set);

  // Perform an iteration of range inference just propagating ranges
  // through the graph as-is without applying widening or narrowing.
  // This helps to improve precision of initial bounds.
  // We are doing 2 iterations to hit common cases where phi range
  // stabilizes quickly and yields a better precision than after
  // widening and narrowing.
  Iterate(NONE, 2);

  // Perform fix-point iteration of range inference applying widening
  // operator to phis to ensure fast convergence.
  // Widening simply maps growing bounds to the respective range bound.
  Iterate(WIDEN, kMaxInt32);

  // Perform fix-point iteration of range inference applying narrowing
  // to phis to compute more accurate range.
  // Narrowing only improves those boundaries that were widened up to
  // range boundary and leaves other boundaries intact.
  Iterate(NARROW, kMaxInt32);
}

void RangeAnalysis::AssignRangesRecursively(Definition* defn) {
  if (!Range::IsUnknown(defn->range())) {
    return;
  }

  if (!IsIntegerDefinition(defn)) {
    return;
  }

  for (intptr_t i = 0; i < defn->InputCount(); i++) {
    Definition* input_defn = defn->InputAt(i)->definition();
    if (!input_defn->HasSSATemp() || input_defn->IsConstant()) {
      AssignRangesRecursively(input_defn);
    }
  }

  Range new_range;
  defn->InferRange(this, &new_range);
  if (!Range::IsUnknown(&new_range)) {
    defn->set_range(new_range);
  }
}

// Scheduler is a helper class that inserts floating control-flow less
// subgraphs into the flow graph.
// It always attempts to schedule instructions into the loop preheader in the
// way similar to LICM optimization pass.
// Scheduler supports rollback - that is it keeps track of instructions it
// schedules and can remove all instructions it inserted from the graph.
class Scheduler {
 public:
  explicit Scheduler(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        loop_headers_(flow_graph->GetLoopHierarchy().headers()),
        pre_headers_(loop_headers_.length()) {
    for (intptr_t i = 0; i < loop_headers_.length(); i++) {
      pre_headers_.Add(loop_headers_[i]->ImmediateDominator());
    }
  }

  // Clear the list of emitted instructions.
  void Start() { emitted_.Clear(); }

  // Given the floating instruction attempt to schedule it into one of the
  // loop preheaders that dominates given post_dominator instruction.
  // Some of the instruction inputs can potentially be unscheduled as well.
  // Returns NULL is the scheduling fails (e.g. inputs are not invariant for
  // any loop containing post_dominator).
  // Resulting schedule should be equivalent to one obtained by inserting
  // instructions right before post_dominator and running CSE and LICM passes.
  template <typename T>
  T* Emit(T* instruction, Instruction* post_dominator) {
    return static_cast<T*>(EmitRecursively(instruction, post_dominator));
  }

  // Undo all insertions recorded in the list of emitted instructions.
  void Rollback() {
    for (intptr_t i = emitted_.length() - 1; i >= 0; i--) {
      emitted_[i]->RemoveFromGraph();
    }
    emitted_.Clear();
  }

 private:
  typedef DirectChainedHashMap<PointerKeyValueTrait<Instruction> > Map;

  Instruction* EmitRecursively(Instruction* instruction, Instruction* sink) {
    // Schedule all unscheduled inputs and unwrap all constrained inputs.
    for (intptr_t i = 0; i < instruction->InputCount(); i++) {
      Definition* defn = instruction->InputAt(i)->definition();

      // Instruction is not in the graph yet which means that none of
      // its input uses should be recorded at defn's use chains.
      // Verify this assumption to ensure that we are not going to
      // leave use-lists in an inconsistent state when we start
      // rewriting inputs via set_definition.
      ASSERT(instruction->InputAt(i)->IsSingleUse() &&
             !defn->HasOnlyInputUse(instruction->InputAt(i)));

      if (!defn->HasSSATemp()) {
        Definition* scheduled = Emit(defn, sink);
        if (scheduled == NULL) {
          return NULL;
        }
        instruction->InputAt(i)->set_definition(scheduled);
      } else if (defn->IsConstraint()) {
        instruction->InputAt(i)->set_definition(UnwrapConstraint(defn));
      }
    }

    // Attempt to find equivalent instruction that was already scheduled.
    // If the instruction is still in the graph (it could have been
    // un-scheduled by a rollback action) and it dominates the sink - use it.
    Instruction* emitted = map_.LookupValue(instruction);
    if (emitted != NULL && !emitted->WasEliminated() &&
        sink->IsDominatedBy(emitted)) {
      return emitted;
    }

    // Attempt to find suitable pre-header. Iterate loop headers backwards to
    // attempt scheduling into the outermost loop first.
    for (intptr_t i = loop_headers_.length() - 1; i >= 0; i--) {
      BlockEntryInstr* header = loop_headers_[i];
      BlockEntryInstr* pre_header = pre_headers_[i];

      if (pre_header == NULL) {
        continue;
      }

      if (!sink->IsDominatedBy(header)) {
        continue;
      }

      Instruction* last = pre_header->last_instruction();

      bool inputs_are_invariant = true;
      for (intptr_t j = 0; j < instruction->InputCount(); j++) {
        Definition* defn = instruction->InputAt(j)->definition();
        if (!last->IsDominatedBy(defn)) {
          inputs_are_invariant = false;
          break;
        }
      }

      if (inputs_are_invariant) {
        EmitTo(pre_header, instruction);
        return instruction;
      }
    }

    return NULL;
  }

  void EmitTo(BlockEntryInstr* block, Instruction* instr) {
    GotoInstr* last = block->last_instruction()->AsGoto();
    flow_graph_->InsertBefore(
        last, instr, last->env(),
        instr->IsDefinition() ? FlowGraph::kValue : FlowGraph::kEffect);
    instr->CopyDeoptIdFrom(*last);

    map_.Insert(instr);
    emitted_.Add(instr);
  }

  FlowGraph* flow_graph_;
  Map map_;
  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers_;
  GrowableArray<BlockEntryInstr*> pre_headers_;
  GrowableArray<Instruction*> emitted_;
};

// If bounds check 0 <= index < length is not redundant we attempt to
// replace it with a sequence of checks that guarantee
//
//           0 <= LowerBound(index) < UpperBound(index) < length
//
// and hoist all of those checks out of the enclosing loop.
//
// Upper/Lower bounds are symbolic arithmetic expressions with +, -, *
// operations.
class BoundsCheckGeneralizer {
 public:
  BoundsCheckGeneralizer(RangeAnalysis* range_analysis, FlowGraph* flow_graph)
      : range_analysis_(range_analysis),
        flow_graph_(flow_graph),
        scheduler_(flow_graph) {}

  void TryGeneralize(CheckArrayBoundInstr* check) {
    Definition* upper_bound =
        ConstructUpperBound(check->index()->definition(), check);
    if (upper_bound == UnwrapConstraint(check->index()->definition())) {
      // Unable to construct upper bound for the index.
      if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
        THR_Print("Failed to construct upper bound for %s index\n",
                  check->ToCString());
      }
      return;
    }

    // Re-associate subexpressions inside upper_bound to collect all constants
    // together. This will expose more redundancies when we are going to emit
    // upper bound through scheduler.
    if (!Simplify(&upper_bound, NULL)) {
      if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
        THR_Print("Failed to simplify upper bound for %s index\n",
                  check->ToCString());
      }
      return;
    }
    upper_bound = ApplyConstraints(upper_bound, check);
    range_analysis_->AssignRangesRecursively(upper_bound);

    // We are going to constrain any symbols participating in + and * operations
    // to guarantee that they are positive. Find all symbols that need
    // constraining. If there is a subtraction subexpression with non-positive
    // range give up on generalization for simplicity.
    GrowableArray<Definition*> non_positive_symbols;
    if (!FindNonPositiveSymbols(&non_positive_symbols, upper_bound)) {
#ifndef PRODUCT
      if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
        THR_Print(
            "Failed to generalize %s index to %s"
            " (can't ensure positivity)\n",
            check->ToCString(), IndexBoundToCString(upper_bound));
      }
#endif  // !PRODUCT
      return;
    }

    // Check that we can statically prove that lower bound of the index is
    // non-negative under the assumption that all potentially non-positive
    // symbols are positive.
    GrowableArray<ConstraintInstr*> positive_constraints(
        non_positive_symbols.length());
    Range* positive_range =
        new Range(RangeBoundary::FromConstant(0),
                  RangeBoundary::MaxConstant(RangeBoundary::kRangeBoundarySmi));
    for (intptr_t i = 0; i < non_positive_symbols.length(); i++) {
      Definition* symbol = non_positive_symbols[i];
      positive_constraints.Add(
          new ConstraintInstr(new Value(symbol), positive_range));
    }

    Definition* lower_bound =
        ConstructLowerBound(check->index()->definition(), check);
    // No need to simplify lower bound before applying constraints as
    // we are not going to emit it.
    lower_bound = ApplyConstraints(lower_bound, check, &positive_constraints);
    range_analysis_->AssignRangesRecursively(lower_bound);

    if (!RangeUtils::IsPositive(lower_bound->range())) {
// Can't prove that lower bound is positive even with additional checks
// against potentially non-positive symbols. Give up.
#ifndef PRODUCT
      if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
        THR_Print(
            "Failed to generalize %s index to %s"
            " (lower bound is not positive)\n",
            check->ToCString(), IndexBoundToCString(upper_bound));
      }
#endif  // !PRODUCT
      return;
    }

#ifndef PRODUCT
    if (FLAG_support_il_printer && FLAG_trace_range_analysis) {
      THR_Print("For %s computed index bounds [%s, %s]\n", check->ToCString(),
                IndexBoundToCString(lower_bound),
                IndexBoundToCString(upper_bound));
    }
#endif  // !PRODUCT

    // At this point we know that 0 <= index < UpperBound(index) under
    // certain preconditions. Start by emitting this preconditions.
    scheduler_.Start();

    // AOT should only see non-deopting GenericCheckBound.
    ASSERT(!CompilerState::Current().is_aot());

    ConstantInstr* max_smi = flow_graph_->GetConstant(
        Smi::Handle(Smi::New(compiler::target::kSmiMax)));
    for (intptr_t i = 0; i < non_positive_symbols.length(); i++) {
      CheckArrayBoundInstr* precondition = new CheckArrayBoundInstr(
          new Value(max_smi), new Value(non_positive_symbols[i]),
          DeoptId::kNone);
      precondition->mark_generalized();
      precondition = scheduler_.Emit(precondition, check);
      if (precondition == NULL) {
        if (FLAG_trace_range_analysis) {
          THR_Print("  => failed to insert positivity constraint\n");
        }
        scheduler_.Rollback();
        return;
      }
    }

    CheckArrayBoundInstr* new_check = new CheckArrayBoundInstr(
        new Value(UnwrapConstraint(check->length()->definition())),
        new Value(upper_bound), DeoptId::kNone);
    new_check->mark_generalized();
    if (new_check->IsRedundant()) {
      if (FLAG_trace_range_analysis) {
        THR_Print("  => generalized check is redundant\n");
      }
      RemoveGeneralizedCheck(check);
      return;
    }

    new_check = scheduler_.Emit(new_check, check);
    if (new_check != NULL) {
      if (FLAG_trace_range_analysis) {
        THR_Print("  => generalized check was hoisted into B%" Pd "\n",
                  new_check->GetBlock()->block_id());
      }
      RemoveGeneralizedCheck(check);
    } else {
      if (FLAG_trace_range_analysis) {
        THR_Print("  => generalized check can't be hoisted\n");
      }
      scheduler_.Rollback();
    }
  }

  static void RemoveGeneralizedCheck(CheckArrayBoundInstr* check) {
    BinarySmiOpInstr* binary_op = check->index()->definition()->AsBinarySmiOp();
    if (binary_op != NULL) {
      binary_op->set_can_overflow(false);
    }
    check->ReplaceUsesWith(check->index()->definition());
    check->RemoveFromGraph();
  }

 private:
  BinarySmiOpInstr* MakeBinaryOp(Token::Kind op_kind,
                                 Definition* left,
                                 Definition* right) {
    return new BinarySmiOpInstr(op_kind, new Value(left), new Value(right),
                                DeoptId::kNone);
  }

  BinarySmiOpInstr* MakeBinaryOp(Token::Kind op_kind,
                                 Definition* left,
                                 intptr_t right) {
    ConstantInstr* constant_right =
        flow_graph_->GetConstant(Smi::Handle(Smi::New(right)));
    return MakeBinaryOp(op_kind, left, constant_right);
  }

  Definition* RangeBoundaryToDefinition(const RangeBoundary& bound) {
    Definition* symbol = UnwrapConstraint(bound.symbol());
    if (bound.offset() == 0) {
      return symbol;
    } else {
      return MakeBinaryOp(Token::kADD, symbol, bound.offset());
    }
  }

  typedef Definition* (BoundsCheckGeneralizer::*PhiBoundFunc)(PhiInstr*,
                                                              LoopInfo*,
                                                              InductionVar*,
                                                              Instruction*);

  // Construct symbolic lower bound for a value at the given point.
  Definition* ConstructLowerBound(Definition* value, Instruction* point) {
    return ConstructBound(&BoundsCheckGeneralizer::InductionVariableLowerBound,
                          value, point);
  }

  // Construct symbolic upper bound for a value at the given point.
  Definition* ConstructUpperBound(Definition* value, Instruction* point) {
    return ConstructBound(&BoundsCheckGeneralizer::InductionVariableUpperBound,
                          value, point);
  }

  // Helper methods to implement "older" business logic.
  // TODO(ajcbik): generalize with new induction variable information

  // Only accept loops with a smi constraint on smi induction.
  LoopInfo* GetSmiBoundedLoop(PhiInstr* phi) {
    LoopInfo* loop = phi->GetBlock()->loop_info();
    if (loop == nullptr) {
      return nullptr;
    }
    ConstraintInstr* limit = loop->limit();
    if (limit == nullptr) {
      return nullptr;
    }
    Definition* def = UnwrapConstraint(limit->value()->definition());
    Range* constraining_range = limit->constraint();
    if (GetSmiInduction(loop, def) != nullptr &&
        constraining_range->min().Equals(RangeBoundary::MinSmi()) &&
        constraining_range->max().IsSymbol() &&
        def->IsDominatedBy(constraining_range->max().symbol())) {
      return loop;
    }
    return nullptr;
  }

  // Returns true if x is invariant and is either based on a Smi definition
  // or is a Smi constant.
  static bool IsSmiInvariant(const InductionVar* x) {
    return InductionVar::IsInvariant(x) && Smi::IsValid(x->offset()) &&
           Smi::IsValid(x->mult()) &&
           (x->mult() == 0 || x->def()->Type()->ToCid() == kSmiCid);
  }

  // Only accept smi linear induction with unit stride.
  InductionVar* GetSmiInduction(LoopInfo* loop, Definition* def) {
    if (loop != nullptr && def->Type()->ToCid() == kSmiCid) {
      InductionVar* induc = loop->LookupInduction(def);
      int64_t stride;
      if (induc != nullptr && InductionVar::IsLinear(induc, &stride) &&
          stride == 1 && IsSmiInvariant(induc->initial())) {
        return induc;
      }
    }
    return nullptr;
  }

  // Reconstruct invariant.
  Definition* GenerateInvariant(InductionVar* induc) {
    Definition* res = nullptr;
    if (induc->mult() == 0) {
      res =
          flow_graph_->GetConstant(Smi::ZoneHandle(Smi::New(induc->offset())));
    } else {
      res = induc->def();
      if (induc->mult() != 1) {
        res = MakeBinaryOp(Token::kMUL, res, induc->mult());
      }
      if (induc->offset() != 0) {
        res = MakeBinaryOp(Token::kADD, res, induc->offset());
      }
    }
    return res;
  }

  // Construct symbolic bound for a value at the given point:
  //
  //   1. if value is an induction variable use its bounds;
  //   2. if value is addition or multiplication construct bounds for left
  //      and right hand sides separately and use addition/multiplication
  //      of bounds as a bound (addition and multiplication are monotone
  //      operations for both operands);
  //   3. if value is a substraction then construct bound for the left hand
  //      side and use substraction of the right hand side from the left hand
  //      side bound as a bound for an expression (substraction is monotone for
  //      the left hand side operand).
  //
  Definition* ConstructBound(PhiBoundFunc phi_bound_func,
                             Definition* value,
                             Instruction* point) {
    value = UnwrapConstraint(value);
    if (value->IsPhi()) {
      PhiInstr* phi = value->AsPhi();
      LoopInfo* loop = GetSmiBoundedLoop(phi);
      InductionVar* induc = GetSmiInduction(loop, phi);
      if (induc != nullptr) {
        return (this->*phi_bound_func)(phi, loop, induc, point);
      }
    } else if (value->IsBinarySmiOp()) {
      BinarySmiOpInstr* bin_op = value->AsBinarySmiOp();
      if ((bin_op->op_kind() == Token::kADD) ||
          (bin_op->op_kind() == Token::kMUL) ||
          (bin_op->op_kind() == Token::kSUB)) {
        Definition* new_left =
            ConstructBound(phi_bound_func, bin_op->left()->definition(), point);
        Definition* new_right =
            (bin_op->op_kind() != Token::kSUB)
                ? ConstructBound(phi_bound_func, bin_op->right()->definition(),
                                 point)
                : UnwrapConstraint(bin_op->right()->definition());

        if ((new_left != UnwrapConstraint(bin_op->left()->definition())) ||
            (new_right != UnwrapConstraint(bin_op->right()->definition()))) {
          return MakeBinaryOp(bin_op->op_kind(), new_left, new_right);
        }
      }
    }
    return value;
  }

  Definition* InductionVariableUpperBound(PhiInstr* phi,
                                          LoopInfo* loop,
                                          InductionVar* induc,
                                          Instruction* point) {
    // Test if limit dominates given point.
    ConstraintInstr* limit = loop->limit();
    if (!point->IsDominatedBy(limit)) {
      return phi;
    }
    // Decide between direct or indirect bound.
    Definition* bounded_def = UnwrapConstraint(limit->value()->definition());
    if (bounded_def == phi) {
      // Given a smi bounded loop with smi induction variable
      //
      //          x <- phi(x0, x + 1)
      //
      // and a constraint x <= M that dominates the given
      // point we conclude that M is an upper bound for x.
      return RangeBoundaryToDefinition(limit->constraint()->max());
    } else {
      // Given a smi bounded loop with two smi induction variables
      //
      //          x <- phi(x0, x + 1)
      //          y <- phi(y0, y + 1)
      //
      // and a constraint x <= M that dominates the given
      // point we can conclude that
      //
      //          y <= y0 + (M - x0)
      //
      InductionVar* bounded_induc = GetSmiInduction(loop, bounded_def);
      Definition* x0 = GenerateInvariant(bounded_induc->initial());
      Definition* y0 = GenerateInvariant(induc->initial());
      Definition* m = RangeBoundaryToDefinition(limit->constraint()->max());
      BinarySmiOpInstr* loop_length =
          MakeBinaryOp(Token::kSUB, ConstructUpperBound(m, point),
                       ConstructLowerBound(x0, point));
      return MakeBinaryOp(Token::kADD, ConstructUpperBound(y0, point),
                          loop_length);
    }
  }

  Definition* InductionVariableLowerBound(PhiInstr* phi,
                                          LoopInfo* loop,
                                          InductionVar* induc,
                                          Instruction* point) {
    // Given a smi bounded loop with smi induction variable
    //
    //          x <- phi(x0, x + 1)
    //
    // we can conclude that LowerBound(x) == x0.
    return ConstructLowerBound(GenerateInvariant(induc->initial()), point);
  }

  // Try to re-associate binary operations in the floating DAG of operations
  // to collect all constants together, e.g. x + C0 + y + C1 is simplified into
  // x + y + (C0 + C1).
  bool Simplify(Definition** defn, intptr_t* constant) {
    if ((*defn)->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = (*defn)->AsBinarySmiOp();
      Definition* left = binary_op->left()->definition();
      Definition* right = binary_op->right()->definition();

      intptr_t c = 0;
      if (binary_op->op_kind() == Token::kADD) {
        intptr_t left_const = 0;
        intptr_t right_const = 0;
        if (!Simplify(&left, &left_const) || !Simplify(&right, &right_const)) {
          return false;
        }

        c = left_const + right_const;
        if (Utils::WillAddOverflow(left_const, right_const) ||
            !compiler::target::IsSmi(c)) {
          return false;  // Abort.
        }

        if (constant != NULL) {
          *constant = c;
        }

        if ((left == NULL) && (right == NULL)) {
          if (constant != NULL) {
            *defn = NULL;
          } else {
            *defn = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
          }
          return true;
        }

        if (left == NULL) {
          if ((constant != NULL) || (c == 0)) {
            *defn = right;
            return true;
          } else {
            left = right;
            right = NULL;
          }
        }

        if (right == NULL) {
          if ((constant != NULL) || (c == 0)) {
            *defn = left;
            return true;
          } else {
            right = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
            c = 0;
          }
        }
      } else if (binary_op->op_kind() == Token::kSUB) {
        intptr_t left_const = 0;
        intptr_t right_const = 0;
        if (!Simplify(&left, &left_const) || !Simplify(&right, &right_const)) {
          return false;
        }

        c = (left_const - right_const);
        if (Utils::WillSubOverflow(left_const, right_const) ||
            !compiler::target::IsSmi(c)) {
          return false;  // Abort.
        }

        if (constant != NULL) {
          *constant = c;
        }

        if ((left == NULL) && (right == NULL)) {
          if (constant != NULL) {
            *defn = NULL;
          } else {
            *defn = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
          }
          return true;
        }

        if (left == NULL) {
          left = flow_graph_->GetConstant(Object::smi_zero());
        }

        if (right == NULL) {
          if ((constant != NULL) || (c == 0)) {
            *defn = left;
            return true;
          } else {
            right = flow_graph_->GetConstant(Smi::Handle(Smi::New(-c)));
            c = 0;
          }
        }
      } else if (binary_op->op_kind() == Token::kMUL) {
        if (!Simplify(&left, NULL) || !Simplify(&right, NULL)) {
          return false;
        }
      } else {
        // Don't attempt to simplify any other binary operation.
        return true;
      }

      ASSERT(left != NULL);
      ASSERT(right != NULL);

      const bool left_changed = (left != binary_op->left()->definition());
      const bool right_changed = (right != binary_op->right()->definition());
      if (left_changed || right_changed) {
        if (!(*defn)->HasSSATemp()) {
          if (left_changed) binary_op->left()->set_definition(left);
          if (right_changed) binary_op->right()->set_definition(right);
          *defn = binary_op;
        } else {
          *defn = MakeBinaryOp(binary_op->op_kind(), UnwrapConstraint(left),
                               UnwrapConstraint(right));
        }
      }

      if ((c != 0) && (constant == NULL)) {
        *defn = MakeBinaryOp(Token::kADD, *defn, c);
      }
    } else if ((*defn)->IsConstant()) {
      ConstantInstr* constant_defn = (*defn)->AsConstant();
      if ((constant != NULL) && constant_defn->IsSmi()) {
        *defn = NULL;
        *constant = Smi::Cast(constant_defn->value()).Value();
      }
    }

    return true;
  }

  // If possible find a set of symbols that need to be non-negative to
  // guarantee that expression as whole is non-negative.
  bool FindNonPositiveSymbols(GrowableArray<Definition*>* symbols,
                              Definition* defn) {
    if (defn->IsConstant()) {
      const Object& value = defn->AsConstant()->value();
      return compiler::target::IsSmi(value) && (Smi::Cast(value).Value() >= 0);
    } else if (defn->HasSSATemp()) {
      if (!RangeUtils::IsPositive(defn->range())) {
        symbols->Add(defn);
      }
      return true;
    } else if (defn->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = defn->AsBinarySmiOp();
      ASSERT((binary_op->op_kind() == Token::kADD) ||
             (binary_op->op_kind() == Token::kSUB) ||
             (binary_op->op_kind() == Token::kMUL));

      if (RangeUtils::IsPositive(defn->range())) {
        // We can statically prove that this subexpression is always positive.
        // No need to inspect its subexpressions.
        return true;
      }

      if (binary_op->op_kind() == Token::kSUB) {
        // For addition and multiplication it's enough to ensure that
        // lhs and rhs are positive to guarantee that defn as whole is
        // positive. This does not work for substraction so just give up.
        return false;
      }

      return FindNonPositiveSymbols(symbols, binary_op->left()->definition()) &&
             FindNonPositiveSymbols(symbols, binary_op->right()->definition());
    }
    UNREACHABLE();
    return false;
  }

  // Find innermost constraint for the given definition dominating given
  // instruction.
  static Definition* FindInnermostConstraint(Definition* defn,
                                             Instruction* post_dominator) {
    for (Value* use = defn->input_use_list(); use != NULL;
         use = use->next_use()) {
      ConstraintInstr* constraint = use->instruction()->AsConstraint();
      if ((constraint != NULL) && post_dominator->IsDominatedBy(constraint)) {
        return FindInnermostConstraint(constraint, post_dominator);
      }
    }
    return defn;
  }

  // Replace symbolic parts of the boundary with respective constraints
  // that hold at the given point in the flow graph signified by
  // post_dominator.
  // Constraints array allows to provide a set of additional floating
  // constraints that were not inserted into the graph.
  static Definition* ApplyConstraints(
      Definition* defn,
      Instruction* post_dominator,
      GrowableArray<ConstraintInstr*>* constraints = NULL) {
    if (defn->HasSSATemp()) {
      defn = FindInnermostConstraint(defn, post_dominator);
      if (constraints != NULL) {
        for (intptr_t i = 0; i < constraints->length(); i++) {
          ConstraintInstr* constraint = (*constraints)[i];
          if (constraint->value()->definition() == defn) {
            return constraint;
          }
        }
      }
      return defn;
    }

    for (intptr_t i = 0; i < defn->InputCount(); i++) {
      defn->InputAt(i)->set_definition(ApplyConstraints(
          defn->InputAt(i)->definition(), post_dominator, constraints));
    }

    return defn;
  }

#ifndef PRODUCT
  static void PrettyPrintIndexBoundRecursively(BufferFormatter* f,
                                               Definition* index_bound) {
    BinarySmiOpInstr* binary_op = index_bound->AsBinarySmiOp();
    if (binary_op != NULL) {
      f->Print("(");
      PrettyPrintIndexBoundRecursively(f, binary_op->left()->definition());
      f->Print(" %s ", Token::Str(binary_op->op_kind()));
      PrettyPrintIndexBoundRecursively(f, binary_op->right()->definition());
      f->Print(")");
    } else if (index_bound->IsConstant()) {
      f->Print("%" Pd "",
               Smi::Cast(index_bound->AsConstant()->value()).Value());
    } else {
      f->Print("v%" Pd "", index_bound->ssa_temp_index());
    }
    f->Print(" {%s}", Range::ToCString(index_bound->range()));
  }

  static const char* IndexBoundToCString(Definition* index_bound) {
    char buffer[1024];
    BufferFormatter f(buffer, sizeof(buffer));
    PrettyPrintIndexBoundRecursively(&f, index_bound);
    return Thread::Current()->zone()->MakeCopyOfString(buffer);
  }
#endif  // !PRODUCT

  RangeAnalysis* range_analysis_;
  FlowGraph* flow_graph_;
  Scheduler scheduler_;
};

void RangeAnalysis::EliminateRedundantBoundsChecks() {
  if (FLAG_array_bounds_check_elimination) {
    const Function& function = flow_graph_->function();
    // Generalization only if we have not deoptimized on a generalized
    // check earlier and we are not compiling precompiled code
    // (no optimistic hoisting of checks possible)
    const bool try_generalization =
        !CompilerState::Current().is_aot() &&
        !function.ProhibitsBoundsCheckGeneralization();
    BoundsCheckGeneralizer generalizer(this, flow_graph_);
    for (CheckBoundBase* check : bounds_checks_) {
      if (check->IsRedundant(/*use_loops=*/true)) {
        check->ReplaceUsesWith(check->index()->definition());
        check->RemoveFromGraph();
      } else if (try_generalization) {
        if (auto jit_check = check->AsCheckArrayBound()) {
          generalizer.TryGeneralize(jit_check);
        }
      }
    }
  }
}

void RangeAnalysis::MarkUnreachableBlocks() {
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    if (Range::IsUnknown(constraints_[i]->range())) {
      TargetEntryInstr* target = constraints_[i]->target();
      if (target == NULL) {
        // TODO(vegorov): replace Constraint with an uncoditional
        // deoptimization and kill all dominated dead code.
        continue;
      }

      BranchInstr* branch =
          target->PredecessorAt(0)->last_instruction()->AsBranch();
      if (target == branch->true_successor()) {
        // True unreachable.
        if (FLAG_trace_constant_propagation && flow_graph_->should_print()) {
          THR_Print("Range analysis: True unreachable (B%" Pd ")\n",
                    branch->true_successor()->block_id());
        }
        branch->set_constant_target(branch->false_successor());
      } else {
        ASSERT(target == branch->false_successor());
        // False unreachable.
        if (FLAG_trace_constant_propagation && flow_graph_->should_print()) {
          THR_Print("Range analysis: False unreachable (B%" Pd ")\n",
                    branch->false_successor()->block_id());
        }
        branch->set_constant_target(branch->true_successor());
      }
    }
  }
}

void RangeAnalysis::RemoveConstraints() {
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    Definition* def = constraints_[i]->value()->definition();
    // Some constraints might be constraining constraints. Unwind the chain of
    // constraints until we reach the actual definition.
    while (def->IsConstraint()) {
      def = def->AsConstraint()->value()->definition();
    }
    constraints_[i]->ReplaceUsesWith(def);
    constraints_[i]->RemoveFromGraph();
  }
}

static void NarrowBinaryInt64Op(BinaryInt64OpInstr* int64_op) {
  if (RangeUtils::Fits(int64_op->range(), RangeBoundary::kRangeBoundaryInt32) &&
      RangeUtils::Fits(int64_op->left()->definition()->range(),
                       RangeBoundary::kRangeBoundaryInt32) &&
      RangeUtils::Fits(int64_op->right()->definition()->range(),
                       RangeBoundary::kRangeBoundaryInt32) &&
      BinaryInt32OpInstr::IsSupported(int64_op->op_kind(), int64_op->left(),
                                      int64_op->right())) {
    BinaryInt32OpInstr* int32_op = new BinaryInt32OpInstr(
        int64_op->op_kind(), int64_op->left()->CopyWithType(),
        int64_op->right()->CopyWithType(), int64_op->DeoptimizationTarget());
    int32_op->set_range(*int64_op->range());
    int32_op->set_can_overflow(false);
    int64_op->ReplaceWith(int32_op, NULL);
  }
}

static void NarrowShiftInt64Op(ShiftIntegerOpInstr* int64_op) {
  if (RangeUtils::Fits(int64_op->range(), RangeBoundary::kRangeBoundaryInt32) &&
      RangeUtils::Fits(int64_op->left()->definition()->range(),
                       RangeBoundary::kRangeBoundaryInt32) &&
      RangeUtils::Fits(int64_op->right()->definition()->range(),
                       RangeBoundary::kRangeBoundaryInt32) &&
      BinaryInt32OpInstr::IsSupported(int64_op->op_kind(), int64_op->left(),
                                      int64_op->right())) {
    BinaryInt32OpInstr* int32_op = new BinaryInt32OpInstr(
        int64_op->op_kind(), int64_op->left()->CopyWithType(),
        int64_op->right()->CopyWithType(), int64_op->DeoptimizationTarget());
    int32_op->set_range(*int64_op->range());
    int32_op->set_can_overflow(false);
    int64_op->ReplaceWith(int32_op, NULL);
  }
}

void RangeAnalysis::NarrowMintToInt32() {
  for (intptr_t i = 0; i < binary_int64_ops_.length(); i++) {
    NarrowBinaryInt64Op(binary_int64_ops_[i]);
  }

  for (intptr_t i = 0; i < shift_int64_ops_.length(); i++) {
    NarrowShiftInt64Op(shift_int64_ops_[i]);
  }
}

IntegerInstructionSelector::IntegerInstructionSelector(FlowGraph* flow_graph)
    : flow_graph_(flow_graph) {
  ASSERT(flow_graph_ != NULL);
  zone_ = flow_graph_->zone();
  selected_uint32_defs_ =
      new (zone_) BitVector(zone_, flow_graph_->current_ssa_temp_index());
}

void IntegerInstructionSelector::Select() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("---- starting integer ir selection -------\n");
  }
  FindPotentialUint32Definitions();
  FindUint32NarrowingDefinitions();
  Propagate();
  ReplaceInstructions();
  if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
    THR_Print("---- after integer ir selection -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
}

bool IntegerInstructionSelector::IsPotentialUint32Definition(Definition* def) {
  // TODO(johnmccutchan): Consider Smi operations, to avoid unnecessary tagging
  // & untagged of intermediate results.
  // TODO(johnmccutchan): Consider phis.
  return def->IsBoxInt64() || def->IsUnboxInt64() || def->IsShiftInt64Op() ||
         def->IsSpeculativeShiftInt64Op() ||
         (def->IsBinaryInt64Op() && BinaryUint32OpInstr::IsSupported(
                                        def->AsBinaryInt64Op()->op_kind())) ||
         (def->IsUnaryInt64Op() &&
          UnaryUint32OpInstr::IsSupported(def->AsUnaryInt64Op()->op_kind()));
}

void IntegerInstructionSelector::FindPotentialUint32Definitions() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Finding potential Uint32 definitions:\n");
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if ((defn != NULL) && defn->HasSSATemp()) {
        if (IsPotentialUint32Definition(defn)) {
          if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
            THR_Print("Adding %s\n", current->ToCString());
          }
          potential_uint32_defs_.Add(defn);
        }
      }
    }
  }
}

// BinaryInt64Op masks and stores into unsigned typed arrays that truncate the
// value into a Uint32 range.
bool IntegerInstructionSelector::IsUint32NarrowingDefinition(Definition* def) {
  if (def->IsBinaryInt64Op()) {
    BinaryInt64OpInstr* op = def->AsBinaryInt64Op();
    // Must be a mask operation.
    if (op->op_kind() != Token::kBIT_AND) {
      return false;
    }
    Range* range = op->range();
    if ((range == NULL) ||
        !range->IsWithin(0, static_cast<int64_t>(kMaxUint32))) {
      return false;
    }
    return true;
  }
  // TODO(johnmccutchan): Add typed array stores.
  return false;
}

void IntegerInstructionSelector::FindUint32NarrowingDefinitions() {
  ASSERT(selected_uint32_defs_ != NULL);
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Selecting Uint32 definitions:\n");
    THR_Print("++++ Initial set:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (IsUint32NarrowingDefinition(defn)) {
      if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
        THR_Print("Adding %s\n", defn->ToCString());
      }
      selected_uint32_defs_->Add(defn->ssa_temp_index());
    }
  }
}

bool IntegerInstructionSelector::AllUsesAreUint32Narrowing(Value* list_head) {
  for (Value::Iterator it(list_head); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    Definition* defn = use->instruction()->AsDefinition();
    if ((defn == NULL) || !defn->HasSSATemp() ||
        !selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      return false;
    }
    // Right-hand side operand of ShiftInt64Op is not narrowing (all its bits
    // should be taken into account).
    if (ShiftIntegerOpInstr* shift = defn->AsShiftIntegerOp()) {
      if (use == shift->right()) {
        return false;
      }
    }
  }
  return true;
}

bool IntegerInstructionSelector::CanBecomeUint32(Definition* def) {
  ASSERT(IsPotentialUint32Definition(def));
  if (def->IsBoxInt64()) {
    // If a BoxInt64's input is a candidate, the box is a candidate.
    Definition* box_input = def->AsBoxInt64()->value()->definition();
    return selected_uint32_defs_->Contains(box_input->ssa_temp_index());
  }
  // A right shift with an input outside of Uint32 range cannot be converted
  // because we need the high bits.
  if (def->IsShiftInt64Op() || def->IsSpeculativeShiftInt64Op()) {
    ShiftIntegerOpInstr* op = def->AsShiftIntegerOp();
    if (op->op_kind() == Token::kSHR) {
      Definition* shift_input = op->left()->definition();
      ASSERT(shift_input != NULL);
      Range* range = shift_input->range();
      if ((range == NULL) ||
          !range->IsWithin(0, static_cast<int64_t>(kMaxUint32))) {
        return false;
      }
    }
  }
  if (!def->HasUses()) {
    // No uses, skip.
    return false;
  }
  return AllUsesAreUint32Narrowing(def->input_use_list()) &&
         AllUsesAreUint32Narrowing(def->env_use_list());
}

void IntegerInstructionSelector::Propagate() {
  ASSERT(selected_uint32_defs_ != NULL);
  bool changed = true;
  intptr_t iteration = 0;
  while (changed) {
    if (FLAG_trace_integer_ir_selection) {
      THR_Print("+++ Iteration: %" Pd "\n", iteration++);
    }
    changed = false;
    for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
      Definition* defn = potential_uint32_defs_[i];
      if (selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
        // Already marked as a candidate, skip.
        continue;
      }
      if (defn->IsConstant()) {
        // Skip constants.
        continue;
      }
      if (CanBecomeUint32(defn)) {
        if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
          THR_Print("Adding %s\n", defn->ToCString());
        }
        // Found a new candidate.
        selected_uint32_defs_->Add(defn->ssa_temp_index());
        // Haven't reached fixed point yet.
        changed = true;
      }
    }
  }
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("Reached fixed point\n");
  }
}

Definition* IntegerInstructionSelector::ConstructReplacementFor(
    Definition* def) {
  // Should only see mint definitions.
  ASSERT(IsPotentialUint32Definition(def));
  // Should not see constant instructions.
  ASSERT(!def->IsConstant());
  if (def->IsBinaryIntegerOp()) {
    BinaryIntegerOpInstr* op = def->AsBinaryIntegerOp();
    Token::Kind op_kind = op->op_kind();
    Value* left = op->left()->CopyWithType();
    Value* right = op->right()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    if (def->IsBinaryInt64Op()) {
      return new (Z) BinaryUint32OpInstr(op_kind, left, right, deopt_id);
    } else if (def->IsShiftInt64Op()) {
      return new (Z) ShiftUint32OpInstr(op_kind, left, right, deopt_id);
    } else if (def->IsSpeculativeShiftInt64Op()) {
      return new (Z)
          SpeculativeShiftUint32OpInstr(op_kind, left, right, deopt_id);
    } else {
      UNREACHABLE();
    }
  } else if (def->IsBoxInt64()) {
    Value* value = def->AsBoxInt64()->value()->CopyWithType();
    return new (Z) BoxUint32Instr(value);
  } else if (def->IsUnboxInt64()) {
    UnboxInstr* unbox = def->AsUnboxInt64();
    Value* value = unbox->value()->CopyWithType();
    intptr_t deopt_id = unbox->DeoptimizationTarget();
    return new (Z)
        UnboxUint32Instr(value, deopt_id, def->SpeculativeModeOfInputs());
  } else if (def->IsUnaryInt64Op()) {
    UnaryInt64OpInstr* op = def->AsUnaryInt64Op();
    Token::Kind op_kind = op->op_kind();
    Value* value = op->value()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return new (Z) UnaryUint32OpInstr(op_kind, value, deopt_id);
  }
  UNREACHABLE();
  return NULL;
}

void IntegerInstructionSelector::ReplaceInstructions() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Replacing instructions:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (!selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      // Not a candidate.
      continue;
    }
    Definition* replacement = ConstructReplacementFor(defn);
    ASSERT(replacement != NULL);
    if (!Range::IsUnknown(defn->range())) {
      if (defn->range()->IsPositive()) {
        replacement->set_range(*defn->range());
      } else {
        replacement->set_range(Range(RangeBoundary::FromConstant(0),
                                     RangeBoundary::FromConstant(kMaxUint32)));
      }
    }
    if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
      THR_Print("Replacing %s with %s\n", defn->ToCString(),
                replacement->ToCString());
    }
    defn->ReplaceWith(replacement, NULL);
  }
}

RangeBoundary RangeBoundary::FromDefinition(Definition* defn, int64_t offs) {
  if (defn->IsConstant() && defn->AsConstant()->IsSmi()) {
    return FromConstant(Smi::Cast(defn->AsConstant()->value()).Value() + offs);
  }
  ASSERT(IsValidOffsetForSymbolicRangeBoundary(offs));
  return RangeBoundary(kSymbol, reinterpret_cast<intptr_t>(defn), offs);
}

RangeBoundary RangeBoundary::LowerBound() const {
  if (IsInfinity()) {
    return NegativeInfinity();
  }
  if (IsConstant()) return *this;
  return Add(Range::ConstantMinSmi(symbol()->range()),
             RangeBoundary::FromConstant(offset_), NegativeInfinity());
}

RangeBoundary RangeBoundary::UpperBound() const {
  if (IsInfinity()) {
    return PositiveInfinity();
  }
  if (IsConstant()) return *this;

  return Add(Range::ConstantMaxSmi(symbol()->range()),
             RangeBoundary::FromConstant(offset_), PositiveInfinity());
}

RangeBoundary RangeBoundary::Add(const RangeBoundary& a,
                                 const RangeBoundary& b,
                                 const RangeBoundary& overflow) {
  if (a.IsInfinity() || b.IsInfinity()) return overflow;

  ASSERT(a.IsConstant() && b.IsConstant());
  if (Utils::WillAddOverflow(a.ConstantValue(), b.ConstantValue())) {
    return overflow;
  }

  int64_t result = a.ConstantValue() + b.ConstantValue();

  return RangeBoundary::FromConstant(result);
}

RangeBoundary RangeBoundary::Sub(const RangeBoundary& a,
                                 const RangeBoundary& b,
                                 const RangeBoundary& overflow) {
  if (a.IsInfinity() || b.IsInfinity()) return overflow;
  ASSERT(a.IsConstant() && b.IsConstant());
  if (Utils::WillSubOverflow(a.ConstantValue(), b.ConstantValue())) {
    return overflow;
  }

  int64_t result = a.ConstantValue() - b.ConstantValue();

  return RangeBoundary::FromConstant(result);
}

bool RangeBoundary::SymbolicAdd(const RangeBoundary& a,
                                const RangeBoundary& b,
                                RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant()) {
    if (Utils::WillAddOverflow(a.offset(), b.ConstantValue())) {
      return false;
    }

    const int64_t offset = a.offset() + b.ConstantValue();

    if (!IsValidOffsetForSymbolicRangeBoundary(offset)) {
      return false;
    }

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  } else if (b.IsSymbol() && a.IsConstant()) {
    return SymbolicAdd(b, a, result);
  }
  return false;
}

bool RangeBoundary::SymbolicSub(const RangeBoundary& a,
                                const RangeBoundary& b,
                                RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant()) {
    if (Utils::WillSubOverflow(a.offset(), b.ConstantValue())) {
      return false;
    }

    const int64_t offset = a.offset() - b.ConstantValue();

    if (!IsValidOffsetForSymbolicRangeBoundary(offset)) {
      return false;
    }

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  }
  return false;
}

bool RangeBoundary::Equals(const RangeBoundary& other) const {
  if (IsConstant() && other.IsConstant()) {
    return ConstantValue() == other.ConstantValue();
  } else if (IsInfinity() && other.IsInfinity()) {
    return kind() == other.kind();
  } else if (IsSymbol() && other.IsSymbol()) {
    return (offset() == other.offset()) && DependOnSameSymbol(*this, other);
  } else if (IsUnknown() && other.IsUnknown()) {
    return true;
  }
  return false;
}

RangeBoundary RangeBoundary::Shl(const RangeBoundary& value_boundary,
                                 int64_t shift_count,
                                 const RangeBoundary& overflow) {
  ASSERT(value_boundary.IsConstant());
  ASSERT(shift_count >= 0);
  int64_t limit = 64 - shift_count;
  int64_t value = value_boundary.ConstantValue();

  if (value == 0) {
    return RangeBoundary(0);
  } else if (shift_count == 0 ||
             (limit > 0 && Utils::IsInt(static_cast<int>(limit), value))) {
    // Result stays in 64 bit range.
    const int64_t result = static_cast<uint64_t>(value) << shift_count;
    return RangeBoundary(result);
  }

  return overflow;
}

static RangeBoundary CanonicalizeBoundary(const RangeBoundary& a,
                                          const RangeBoundary& overflow) {
  if (a.IsConstant() || a.IsInfinity()) {
    return a;
  }

  int64_t offset = a.offset();
  Definition* symbol = a.symbol();

  bool changed;
  do {
    changed = false;
    if (symbol->IsConstraint()) {
      symbol = symbol->AsConstraint()->value()->definition();
      changed = true;
    } else if (symbol->IsBinarySmiOp()) {
      BinarySmiOpInstr* op = symbol->AsBinarySmiOp();
      Definition* left = op->left()->definition();
      Definition* right = op->right()->definition();
      switch (op->op_kind()) {
        case Token::kADD:
          if (right->IsConstant()) {
            int64_t rhs = Smi::Cast(right->AsConstant()->value()).Value();
            if (Utils::WillAddOverflow(offset, rhs)) {
              return overflow;
            }
            offset += rhs;
            symbol = left;
            changed = true;
          } else if (left->IsConstant()) {
            int64_t rhs = Smi::Cast(left->AsConstant()->value()).Value();
            if (Utils::WillAddOverflow(offset, rhs)) {
              return overflow;
            }
            offset += rhs;
            symbol = right;
            changed = true;
          }
          break;

        case Token::kSUB:
          if (right->IsConstant()) {
            int64_t rhs = Smi::Cast(right->AsConstant()->value()).Value();
            if (Utils::WillSubOverflow(offset, rhs)) {
              return overflow;
            }
            offset -= rhs;
            symbol = left;
            changed = true;
          }
          break;

        default:
          break;
      }
    }
  } while (changed);

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    return overflow;
  }

  return RangeBoundary::FromDefinition(symbol, offset);
}

static bool CanonicalizeMaxBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == NULL) || !range->max().IsSymbol()) return false;

  if (Utils::WillAddOverflow(range->max().offset(), a->offset())) {
    *a = RangeBoundary::PositiveInfinity();
    return true;
  }

  const int64_t offset = range->max().offset() + a->offset();

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    *a = RangeBoundary::PositiveInfinity();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->max().symbol(), offset),
      RangeBoundary::PositiveInfinity());

  return true;
}

static bool CanonicalizeMinBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == NULL) || !range->min().IsSymbol()) return false;

  if (Utils::WillAddOverflow(range->min().offset(), a->offset())) {
    *a = RangeBoundary::NegativeInfinity();
    return true;
  }

  const int64_t offset = range->min().offset() + a->offset();

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    *a = RangeBoundary::NegativeInfinity();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->min().symbol(), offset),
      RangeBoundary::NegativeInfinity());

  return true;
}

typedef bool (*BoundaryOp)(RangeBoundary*);

static bool CanonicalizeForComparison(RangeBoundary* a,
                                      RangeBoundary* b,
                                      BoundaryOp op,
                                      const RangeBoundary& overflow) {
  if (!a->IsSymbol() || !b->IsSymbol()) {
    return false;
  }

  RangeBoundary canonical_a = *a;
  RangeBoundary canonical_b = *b;

  do {
    if (DependOnSameSymbol(canonical_a, canonical_b)) {
      *a = canonical_a;
      *b = canonical_b;
      return true;
    }
  } while (op(&canonical_a) || op(&canonical_b));

  return false;
}

RangeBoundary RangeBoundary::JoinMin(RangeBoundary a,
                                     RangeBoundary b,
                                     RangeBoundary::RangeSize size) {
  if (a.Equals(b)) {
    return b;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMinBoundary,
                                RangeBoundary::NegativeInfinity())) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.LowerBound(size);
  const int64_t inf_b = b.LowerBound(size);
  const int64_t sup_a = a.UpperBound(size);
  const int64_t sup_b = b.UpperBound(size);

  if ((sup_a <= inf_b) && !a.LowerBound().Overflowed(size)) {
    return a;
  } else if ((sup_b <= inf_a) && !b.LowerBound().Overflowed(size)) {
    return b;
  } else {
    return RangeBoundary::FromConstant(Utils::Minimum(inf_a, inf_b));
  }
}

RangeBoundary RangeBoundary::JoinMax(RangeBoundary a,
                                     RangeBoundary b,
                                     RangeBoundary::RangeSize size) {
  if (a.Equals(b)) {
    return b;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMaxBoundary,
                                RangeBoundary::PositiveInfinity())) {
    return (a.offset() >= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.LowerBound(size);
  const int64_t inf_b = b.LowerBound(size);
  const int64_t sup_a = a.UpperBound(size);
  const int64_t sup_b = b.UpperBound(size);

  if ((sup_a <= inf_b) && !b.UpperBound().Overflowed(size)) {
    return b;
  } else if ((sup_b <= inf_a) && !a.UpperBound().Overflowed(size)) {
    return a;
  } else {
    return RangeBoundary::FromConstant(Utils::Maximum(sup_a, sup_b));
  }
}

RangeBoundary RangeBoundary::IntersectionMin(RangeBoundary a, RangeBoundary b) {
  ASSERT(!a.IsPositiveInfinity() && !b.IsPositiveInfinity());
  ASSERT(!a.IsUnknown() && !b.IsUnknown());

  if (a.Equals(b)) {
    return a;
  }

  if (a.IsMinimumOrBelow(RangeBoundary::kRangeBoundarySmi)) {
    return b;
  } else if (b.IsMinimumOrBelow(RangeBoundary::kRangeBoundarySmi)) {
    return a;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMinBoundary,
                                RangeBoundary::NegativeInfinity())) {
    return (a.offset() >= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.SmiLowerBound();
  const int64_t inf_b = b.SmiLowerBound();

  return (inf_a >= inf_b) ? a : b;
}

RangeBoundary RangeBoundary::IntersectionMax(RangeBoundary a, RangeBoundary b) {
  ASSERT(!a.IsNegativeInfinity() && !b.IsNegativeInfinity());
  ASSERT(!a.IsUnknown() && !b.IsUnknown());

  if (a.Equals(b)) {
    return a;
  }

  if (a.IsMaximumOrAbove(RangeBoundary::kRangeBoundarySmi)) {
    return b;
  } else if (b.IsMaximumOrAbove(RangeBoundary::kRangeBoundarySmi)) {
    return a;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMaxBoundary,
                                RangeBoundary::PositiveInfinity())) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const int64_t sup_a = a.SmiUpperBound();
  const int64_t sup_b = b.SmiUpperBound();

  return (sup_a <= sup_b) ? a : b;
}

int64_t RangeBoundary::ConstantValue() const {
  ASSERT(IsConstant());
  return value_;
}

bool Range::IsPositive() const {
  return OnlyGreaterThanOrEqualTo(0);
}

bool Range::OnlyLessThanOrEqualTo(int64_t val) const {
  const RangeBoundary upper_bound = max().UpperBound();
  return !upper_bound.IsPositiveInfinity() &&
         (upper_bound.ConstantValue() <= val);
}

bool Range::OnlyGreaterThanOrEqualTo(int64_t val) const {
  const RangeBoundary lower_bound = min().LowerBound();
  return !lower_bound.IsNegativeInfinity() &&
         (lower_bound.ConstantValue() >= val);
}

// Inclusive.
bool Range::IsWithin(int64_t min_int, int64_t max_int) const {
  return OnlyGreaterThanOrEqualTo(min_int) && OnlyLessThanOrEqualTo(max_int);
}

bool Range::Overlaps(int64_t min_int, int64_t max_int) const {
  RangeBoundary lower = min().LowerBound();
  RangeBoundary upper = max().UpperBound();
  const int64_t this_min =
      lower.IsNegativeInfinity() ? RangeBoundary::kMin : lower.ConstantValue();
  const int64_t this_max =
      upper.IsPositiveInfinity() ? RangeBoundary::kMax : upper.ConstantValue();
  if ((this_min <= min_int) && (min_int <= this_max)) return true;
  if ((this_min <= max_int) && (max_int <= this_max)) return true;
  if ((min_int < this_min) && (max_int > this_max)) return true;
  return false;
}

bool Range::IsUnsatisfiable() const {
  // Infinity case: [+inf, ...] || [..., -inf]
  if (min().IsPositiveInfinity() || max().IsNegativeInfinity()) {
    return true;
  }
  // Constant case: For example [0, -1].
  if (Range::ConstantMin(this).ConstantValue() >
      Range::ConstantMax(this).ConstantValue()) {
    return true;
  }
  // Symbol case: For example [v+1, v].
  return DependOnSameSymbol(min(), max()) && min().offset() > max().offset();
}

void Range::Clamp(RangeBoundary::RangeSize size) {
  min_ = min_.Clamp(size);
  max_ = max_.Clamp(size);
}

void Range::ClampToConstant(RangeBoundary::RangeSize size) {
  min_ = min_.LowerBound().Clamp(size);
  max_ = max_.UpperBound().Clamp(size);
}

void Range::Shl(const Range* left,
                const Range* right,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left != NULL);
  ASSERT(right != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);
  RangeBoundary left_max = Range::ConstantMax(left);
  RangeBoundary left_min = Range::ConstantMin(left);
  // A negative shift count always deoptimizes (and throws), so the minimum
  // shift count is zero.
  int64_t right_max = Utils::Maximum(Range::ConstantMax(right).ConstantValue(),
                                     static_cast<int64_t>(0));
  int64_t right_min = Utils::Maximum(Range::ConstantMin(right).ConstantValue(),
                                     static_cast<int64_t>(0));

  *result_min = RangeBoundary::Shl(
      left_min, left_min.ConstantValue() > 0 ? right_min : right_max,
      left_min.ConstantValue() > 0 ? RangeBoundary::PositiveInfinity()
                                   : RangeBoundary::NegativeInfinity());

  *result_max = RangeBoundary::Shl(
      left_max, left_max.ConstantValue() > 0 ? right_max : right_min,
      left_max.ConstantValue() > 0 ? RangeBoundary::PositiveInfinity()
                                   : RangeBoundary::NegativeInfinity());
}

void Range::Shr(const Range* left,
                const Range* right,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  RangeBoundary left_max = Range::ConstantMax(left);
  RangeBoundary left_min = Range::ConstantMin(left);
  // A negative shift count always deoptimizes (and throws), so the minimum
  // shift count is zero.
  int64_t right_max = Utils::Maximum(Range::ConstantMax(right).ConstantValue(),
                                     static_cast<int64_t>(0));
  int64_t right_min = Utils::Maximum(Range::ConstantMin(right).ConstantValue(),
                                     static_cast<int64_t>(0));

  *result_min = RangeBoundary::Shr(
      left_min, left_min.ConstantValue() > 0 ? right_max : right_min);

  *result_max = RangeBoundary::Shr(
      left_max, left_max.ConstantValue() > 0 ? right_min : right_max);
}

void Range::And(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);

  if (Range::ConstantMin(right_range).ConstantValue() >= 0) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = Range::ConstantMax(right_range);
    return;
  }

  if (Range::ConstantMin(left_range).ConstantValue() >= 0) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = Range::ConstantMax(left_range);
    return;
  }

  BitwiseOp(left_range, right_range, result_min, result_max);
}

static int BitSize(const Range* range) {
  const int64_t min = Range::ConstantMin(range).ConstantValue();
  const int64_t max = Range::ConstantMax(range).ConstantValue();
  return Utils::Maximum(Utils::BitLength(min), Utils::BitLength(max));
}

void Range::BitwiseOp(const Range* left_range,
                      const Range* right_range,
                      RangeBoundary* result_min,
                      RangeBoundary* result_max) {
  const int bitsize = Utils::Maximum(BitSize(left_range), BitSize(right_range));

  if (left_range->IsPositive() && right_range->IsPositive()) {
    *result_min = RangeBoundary::FromConstant(0);
  } else {
    *result_min =
        RangeBoundary::FromConstant(-(static_cast<uint64_t>(1) << bitsize));
  }

  *result_max =
      RangeBoundary::FromConstant((static_cast<uint64_t>(1) << bitsize) - 1);
}

void Range::Add(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max,
                Definition* left_defn) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);

  RangeBoundary left_min = Definition::IsArrayLength(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->min();

  RangeBoundary left_max = Definition::IsArrayLength(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->max();

  if (!RangeBoundary::SymbolicAdd(left_min, right_range->min(), result_min)) {
    *result_min = RangeBoundary::Add(left_range->min().LowerBound(),
                                     right_range->min().LowerBound(),
                                     RangeBoundary::NegativeInfinity());
  }
  if (!RangeBoundary::SymbolicAdd(left_max, right_range->max(), result_max)) {
    *result_max = RangeBoundary::Add(right_range->max().UpperBound(),
                                     left_range->max().UpperBound(),
                                     RangeBoundary::PositiveInfinity());
  }
}

void Range::Sub(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max,
                Definition* left_defn) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);

  RangeBoundary left_min = Definition::IsArrayLength(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->min();

  RangeBoundary left_max = Definition::IsArrayLength(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->max();

  if (!RangeBoundary::SymbolicSub(left_min, right_range->max(), result_min)) {
    *result_min = RangeBoundary::Sub(left_range->min().LowerBound(),
                                     right_range->max().UpperBound(),
                                     RangeBoundary::NegativeInfinity());
  }
  if (!RangeBoundary::SymbolicSub(left_max, right_range->min(), result_max)) {
    *result_max = RangeBoundary::Sub(left_range->max().UpperBound(),
                                     right_range->min().LowerBound(),
                                     RangeBoundary::PositiveInfinity());
  }
}

void Range::Mul(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);

  const int64_t left_max = ConstantAbsMax(left_range);
  const int64_t right_max = ConstantAbsMax(right_range);
  if ((left_max <= -compiler::target::kSmiMin) &&
      (right_max <= -compiler::target::kSmiMin) &&
      ((left_max == 0) || (right_max <= kMaxInt64 / left_max))) {
    // Product of left and right max values stays in 64 bit range.
    const int64_t mul_max = left_max * right_max;
    if (OnlyPositiveOrZero(*left_range, *right_range) ||
        OnlyNegativeOrZero(*left_range, *right_range)) {
      // If both ranges are of the same sign then the range of the result
      // is positive and is between multiplications of absolute minimums
      // and absolute maximums.
      const int64_t mul_min =
          ConstantAbsMin(left_range) * ConstantAbsMin(right_range);
      *result_min = RangeBoundary::FromConstant(mul_min);
      *result_max = RangeBoundary::FromConstant(mul_max);
    } else {
      // If ranges have mixed signs then use conservative approximation:
      // absolute value of the result is less or equal to multiplication
      // of absolute maximums.
      *result_min = RangeBoundary::FromConstant(-mul_max);
      *result_max = RangeBoundary::FromConstant(mul_max);
    }
    return;
  }

  // TODO(vegorov): handle mixed sign case that leads to (-Infinity, 0] range.
  if (OnlyPositiveOrZero(*left_range, *right_range) ||
      OnlyNegativeOrZero(*left_range, *right_range)) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = RangeBoundary::PositiveInfinity();
    return;
  }

  *result_min = RangeBoundary::NegativeInfinity();
  *result_max = RangeBoundary::PositiveInfinity();
}

void Range::TruncDiv(const Range* left_range,
                     const Range* right_range,
                     RangeBoundary* result_min,
                     RangeBoundary* result_max) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  if (left_range->OnlyGreaterThanOrEqualTo(0) &&
      right_range->OnlyGreaterThanOrEqualTo(1)) {
    const int64_t left_max = ConstantAbsMax(left_range);
    const int64_t left_min = ConstantAbsMin(left_range);
    const int64_t right_max = ConstantAbsMax(right_range);
    const int64_t right_min = ConstantAbsMin(right_range);

    *result_max = RangeBoundary::FromConstant(left_max / right_min);
    *result_min = RangeBoundary::FromConstant(left_min / right_max);
    return;
  }

  *result_min = RangeBoundary::NegativeInfinity();
  *result_max = RangeBoundary::PositiveInfinity();
}

void Range::Mod(const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);
  // Each modulo result is positive and bounded by one less than
  // the maximum of the right-hand-side (it is unlikely that the
  // left-hand-side further refines this in typical programs).
  // Note that x % MinInt can be MaxInt and x % 0 always throws.
  const int64_t kModMin = 0;
  int64_t mod_max = kMaxInt64;
  if (Range::ConstantMin(right_range).ConstantValue() != kMinInt64) {
    const int64_t right_max = ConstantAbsMax(right_range);
    mod_max = Utils::Maximum(right_max - 1, kModMin);
  }
  *result_min = RangeBoundary::FromConstant(kModMin);
  *result_max = RangeBoundary::FromConstant(mod_max);
}

// Both the a and b ranges are >= 0.
bool Range::OnlyPositiveOrZero(const Range& a, const Range& b) {
  return a.OnlyGreaterThanOrEqualTo(0) && b.OnlyGreaterThanOrEqualTo(0);
}

// Both the a and b ranges are <= 0.
bool Range::OnlyNegativeOrZero(const Range& a, const Range& b) {
  return a.OnlyLessThanOrEqualTo(0) && b.OnlyLessThanOrEqualTo(0);
}

// Return the maximum absolute value included in range.
int64_t Range::ConstantAbsMax(const Range* range) {
  if (range == NULL) {
    return RangeBoundary::kMax;
  }
  const int64_t abs_min =
      Utils::AbsWithSaturation(Range::ConstantMin(range).ConstantValue());
  const int64_t abs_max =
      Utils::AbsWithSaturation(Range::ConstantMax(range).ConstantValue());
  return Utils::Maximum(abs_min, abs_max);
}

// Return the minimum absolute value included in range.
int64_t Range::ConstantAbsMin(const Range* range) {
  if (range == NULL) {
    return 0;
  }
  const int64_t abs_min =
      Utils::AbsWithSaturation(Range::ConstantMin(range).ConstantValue());
  const int64_t abs_max =
      Utils::AbsWithSaturation(Range::ConstantMax(range).ConstantValue());
  return Utils::Minimum(abs_min, abs_max);
}

void Range::BinaryOp(const Token::Kind op,
                     const Range* left_range,
                     const Range* right_range,
                     Definition* left_defn,
                     Range* result) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);

  // Both left and right ranges are finite.
  ASSERT(left_range->IsFinite());
  ASSERT(right_range->IsFinite());

  RangeBoundary min;
  RangeBoundary max;
  ASSERT(min.IsUnknown() && max.IsUnknown());

  switch (op) {
    case Token::kADD:
      Range::Add(left_range, right_range, &min, &max, left_defn);
      break;

    case Token::kSUB:
      Range::Sub(left_range, right_range, &min, &max, left_defn);
      break;

    case Token::kMUL:
      Range::Mul(left_range, right_range, &min, &max);
      break;

    case Token::kTRUNCDIV:
      Range::TruncDiv(left_range, right_range, &min, &max);
      break;

    case Token::kMOD:
      Range::Mod(right_range, &min, &max);
      break;

    case Token::kSHL:
      Range::Shl(left_range, right_range, &min, &max);
      break;

    case Token::kSHR:
      Range::Shr(left_range, right_range, &min, &max);
      break;

    case Token::kBIT_AND:
      Range::And(left_range, right_range, &min, &max);
      break;

    case Token::kBIT_XOR:
    case Token::kBIT_OR:
      Range::BitwiseOp(left_range, right_range, &min, &max);
      break;

    default:
      *result = Range(RangeBoundary::NegativeInfinity(),
                      RangeBoundary::PositiveInfinity());
      return;
  }

  ASSERT(!min.IsUnknown() && !max.IsUnknown());

  // Sanity: avoid [l, u] with constants l > u.
  ASSERT(!min.IsConstant() || !max.IsConstant() ||
         min.ConstantValue() <= max.ConstantValue());

  *result = Range(min, max);
}

void Definition::set_range(const Range& range) {
  if (range_ == NULL) {
    range_ = new Range();
  }
  *range_ = range;
}

void Definition::InferRange(RangeAnalysis* analysis, Range* range) {
  if (Type()->ToCid() == kSmiCid) {
    *range = Range::Full(RangeBoundary::kRangeBoundarySmi);
  } else if (IsInt64Definition()) {
    *range = Range::Full(RangeBoundary::kRangeBoundaryInt64);
  } else if (IsInt32Definition()) {
    *range = Range::Full(RangeBoundary::kRangeBoundaryInt32);
  } else if (Type()->IsInt()) {
    *range = Range::Full(RangeBoundary::kRangeBoundaryInt64);
  } else {
    // Only Smi and Mint supported.
    UNREACHABLE();
  }
}

static bool DependsOnSymbol(const RangeBoundary& a, Definition* symbol) {
  return a.IsSymbol() && (UnwrapConstraint(a.symbol()) == symbol);
}

// Given the range and definition update the range so that
// it covers both original range and definitions range.
//
// The following should also hold:
//
//     [_|_, _|_] U a = a U [_|_, _|_] = a
//
static void Join(Range* range,
                 Definition* defn,
                 const Range* defn_range,
                 RangeBoundary::RangeSize size) {
  if (Range::IsUnknown(defn_range)) {
    return;
  }

  if (Range::IsUnknown(range)) {
    *range = *defn_range;
    return;
  }

  Range other = *defn_range;

  // Handle patterns where range already depends on defn as a symbol:
  //
  //    (..., S+o] U range(S) and [S+o, ...) U range(S)
  //
  // To improve precision of the computed join use [S, S] instead of
  // using range(S). It will be canonicalized away by JoinMin/JoinMax
  // functions.
  Definition* unwrapped = UnwrapConstraint(defn);
  if (DependsOnSymbol(range->min(), unwrapped) ||
      DependsOnSymbol(range->max(), unwrapped)) {
    other = Range(RangeBoundary::FromDefinition(defn, 0),
                  RangeBoundary::FromDefinition(defn, 0));
  }

  // First try to compare ranges based on their upper and lower bounds.
  const int64_t inf_range = range->min().LowerBound(size);
  const int64_t inf_other = other.min().LowerBound(size);
  const int64_t sup_range = range->max().UpperBound(size);
  const int64_t sup_other = other.max().UpperBound(size);

  if (sup_range <= inf_other) {
    // The range is fully below defn's range. Keep the minimum and
    // expand the maximum.
    range->set_max(other.max());
  } else if (sup_other <= inf_range) {
    // The range is fully above defn's range. Keep the maximum and
    // expand the minimum.
    range->set_min(other.min());
  } else {
    // Can't compare ranges as whole. Join minimum and maximum separately.
    *range = Range(RangeBoundary::JoinMin(range->min(), other.min(), size),
                   RangeBoundary::JoinMax(range->max(), other.max(), size));
  }
}

// A definition dominates a phi if its block dominates the phi's block
// and the two blocks are different.
static bool DominatesPhi(BlockEntryInstr* a, BlockEntryInstr* phi_block) {
  return a->Dominates(phi_block) && (a != phi_block);
}

// When assigning range to a phi we must take care to avoid self-reference
// cycles when phi's range depends on the phi itself.
// To prevent such cases we impose additional restriction on symbols that
// can be used as boundaries for phi's range: they must dominate
// phi's definition.
static RangeBoundary EnsureAcyclicSymbol(BlockEntryInstr* phi_block,
                                         const RangeBoundary& a,
                                         const RangeBoundary& limit) {
  if (!a.IsSymbol() || DominatesPhi(a.symbol()->GetBlock(), phi_block)) {
    return a;
  }

  // Symbol does not dominate phi. Try unwrapping constraint and check again.
  Definition* unwrapped = UnwrapConstraint(a.symbol());
  if ((unwrapped != a.symbol()) &&
      DominatesPhi(unwrapped->GetBlock(), phi_block)) {
    return RangeBoundary::FromDefinition(unwrapped, a.offset());
  }

  return limit;
}

static const Range* GetInputRange(RangeAnalysis* analysis,
                                  RangeBoundary::RangeSize size,
                                  Value* input) {
  switch (size) {
    case RangeBoundary::kRangeBoundarySmi:
      return analysis->GetSmiRange(input);
    case RangeBoundary::kRangeBoundaryInt32:
      return input->definition()->range();
    case RangeBoundary::kRangeBoundaryInt64:
      return analysis->GetIntRange(input);
    default:
      UNREACHABLE();
      return NULL;
  }
}

void PhiInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const RangeBoundary::RangeSize size = RangeSizeForPhi(this);
  for (intptr_t i = 0; i < InputCount(); i++) {
    Value* input = InputAt(i);
    Join(range, input->definition(), GetInputRange(analysis, size, input),
         size);
  }

  BlockEntryInstr* phi_block = GetBlock();
  range->set_min(
      EnsureAcyclicSymbol(phi_block, range->min(), RangeBoundary::MinSmi()));
  range->set_max(
      EnsureAcyclicSymbol(phi_block, range->max(), RangeBoundary::MaxSmi()));
}

void ConstantInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  if (value_.IsSmi()) {
    int64_t value = Smi::Cast(value_).Value();
    *range = Range(RangeBoundary::FromConstant(value),
                   RangeBoundary::FromConstant(value));
  } else if (value_.IsMint()) {
    int64_t value = Mint::Cast(value_).value();
    *range = Range(RangeBoundary::FromConstant(value),
                   RangeBoundary::FromConstant(value));
  } else {
    // Only Smi and Mint supported.
    UNREACHABLE();
  }
}

void ConstraintInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = analysis->GetSmiRange(value());
  if (Range::IsUnknown(value_range)) {
    return;
  }

  // TODO(vegorov) check if precision of the analysis can be improved by
  // recognizing intersections of the form:
  //
  //       (..., S+x] ^ [S+x, ...) = [S+x, S+x]
  //
  Range result = value_range->Intersect(constraint());

  if (result.IsUnsatisfiable()) {
    return;
  }

  *range = result;
}

void LoadFieldInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  switch (slot().kind()) {
    case Slot::Kind::kArray_length:
    case Slot::Kind::kGrowableObjectArray_length:
      *range = Range(
          RangeBoundary::FromConstant(0),
          RangeBoundary::FromConstant(compiler::target::Array::kMaxElements));
      break;

    case Slot::Kind::kTypedDataBase_length:
    case Slot::Kind::kTypedDataView_offset_in_bytes:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;

    case Slot::Kind::kString_length:
      *range = Range(
          RangeBoundary::FromConstant(0),
          RangeBoundary::FromConstant(compiler::target::String::kMaxElements));
      break;

    case Slot::Kind::kDartField:
    case Slot::Kind::kCapturedVariable:
      // Use default value.
      Definition::InferRange(analysis, range);
      break;

    case Slot::Kind::kLinkedHashMap_index:
    case Slot::Kind::kLinkedHashMap_data:
    case Slot::Kind::kGrowableObjectArray_data:
    case Slot::Kind::kContext_parent:
    case Slot::Kind::kTypeArguments:
    case Slot::Kind::kClosure_context:
    case Slot::Kind::kClosure_delayed_type_arguments:
    case Slot::Kind::kClosure_function:
    case Slot::Kind::kClosure_function_type_arguments:
    case Slot::Kind::kClosure_instantiator_type_arguments:
    case Slot::Kind::kPointerBase_data_field:
    case Slot::Kind::kTypedDataView_data:
    case Slot::Kind::kType_arguments:
    case Slot::Kind::kTypeArgumentsIndex:
    case Slot::Kind::kUnhandledException_exception:
    case Slot::Kind::kUnhandledException_stacktrace:
      // Not an integer valued field.
      UNREACHABLE();
      break;

    case Slot::Kind::kClosure_hash:
    case Slot::Kind::kLinkedHashMap_hash_mask:
    case Slot::Kind::kLinkedHashMap_used_data:
    case Slot::Kind::kLinkedHashMap_deleted_keys:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;

    case Slot::Kind::kArgumentsDescriptor_type_args_len:
    case Slot::Kind::kArgumentsDescriptor_positional_count:
    case Slot::Kind::kArgumentsDescriptor_count:
    case Slot::Kind::kArgumentsDescriptor_size:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;
  }
}

void LoadIndexedInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      *range = Range(RangeBoundary::FromConstant(-128),
                     RangeBoundary::FromConstant(127));
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(255));
      break;
    case kTypedDataInt16ArrayCid:
      *range = Range(RangeBoundary::FromConstant(-32768),
                     RangeBoundary::FromConstant(32767));
      break;
    case kTypedDataUint16ArrayCid:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(65535));
      break;
    case kTypedDataInt32ArrayCid:
      *range = Range(RangeBoundary::FromConstant(kMinInt32),
                     RangeBoundary::FromConstant(kMaxInt32));
      break;
    case kTypedDataUint32ArrayCid:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(kMaxUint32));
      break;
    case kOneByteStringCid:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(0xFF));
      break;
    case kTwoByteStringCid:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(0xFFFF));
      break;
    default:
      Definition::InferRange(analysis, range);
      break;
  }
}

void LoadCodeUnitsInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  ASSERT(IsStringClassId(class_id()));
  RangeBoundary zero = RangeBoundary::FromConstant(0);
  // Take the number of loaded characters into account when determining the
  // range of the result.
  ASSERT(element_count_ > 0);
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(element_count_ <= 4);
      *range = Range(zero, RangeBoundary::FromConstant(
                               Utils::NBitMask(kBitsPerByte * element_count_)));
      break;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      ASSERT(element_count_ <= 2);
      *range = Range(zero, RangeBoundary::FromConstant(Utils::NBitMask(
                               2 * kBitsPerByte * element_count_)));
      break;
    default:
      UNREACHABLE();
      break;
  }
}

void IfThenElseInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const intptr_t min = Utils::Minimum(if_true_, if_false_);
  const intptr_t max = Utils::Maximum(if_true_, if_false_);
  *range =
      Range(RangeBoundary::FromConstant(min), RangeBoundary::FromConstant(max));
}

static RangeBoundary::RangeSize RepresentationToRangeSize(Representation r) {
  switch (r) {
    case kTagged:
      return RangeBoundary::kRangeBoundarySmi;
    case kUnboxedInt32:
      return RangeBoundary::kRangeBoundaryInt32;
    case kUnboxedInt64:
    case kUnboxedUint32:  // Overapproximate Uint32 as Int64.
      return RangeBoundary::kRangeBoundaryInt64;
    default:
      UNREACHABLE();
      return RangeBoundary::kRangeBoundarySmi;
  }
}

void BinaryIntegerOpInstr::InferRangeHelper(const Range* left_range,
                                            const Range* right_range,
                                            Range* range) {
  // TODO(vegorov): canonicalize BinaryIntegerOp to always have constant on the
  // right and a non-constant on the left.
  if (Range::IsUnknown(left_range) || Range::IsUnknown(right_range)) {
    return;
  }

  Range::BinaryOp(op_kind(), left_range, right_range, left()->definition(),
                  range);
  ASSERT(!Range::IsUnknown(range));

  const RangeBoundary::RangeSize range_size =
      RepresentationToRangeSize(representation());

  // Calculate overflowed status before clamping if operation is
  // not truncating.
  if (!is_truncating()) {
    set_can_overflow(!range->Fits(range_size));
  }

  range->Clamp(range_size);
}

static void CacheRange(Range** slot,
                       const Range* range,
                       RangeBoundary::RangeSize size) {
  if (range != NULL) {
    if (*slot == NULL) {
      *slot = new Range();
    }
    **slot = *range;

    // Eliminate any symbolic dependencies from the range information.
    (*slot)->ClampToConstant(size);
  } else if (*slot != NULL) {
    **slot = Range();  // Clear cached range information.
  }
}

void BinarySmiOpInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* right_smi_range = analysis->GetSmiRange(right());
  // TODO(vegorov) completely remove this once GetSmiRange is eliminated.
  if (op_kind() == Token::kSHR || op_kind() == Token::kSHL ||
      op_kind() == Token::kMOD || op_kind() == Token::kTRUNCDIV) {
    CacheRange(&right_range_, right_smi_range,
               RangeBoundary::kRangeBoundarySmi);
  }
  InferRangeHelper(analysis->GetSmiRange(left()), right_smi_range, range);
}

void BinaryInt32OpInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  InferRangeHelper(analysis->GetSmiRange(left()),
                   analysis->GetSmiRange(right()), range);
}

void BinaryInt64OpInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  InferRangeHelper(left()->definition()->range(),
                   right()->definition()->range(), range);
}

void ShiftIntegerOpInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* right_range = RequiredInputRepresentation(1) == kTagged
                                 ? analysis->GetSmiRange(right())
                                 : right()->definition()->range();
  CacheRange(&shift_range_, right()->definition()->range(),
             RangeBoundary::kRangeBoundaryInt64);
  InferRangeHelper(left()->definition()->range(), right_range, range);
}

void BoxIntegerInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = value()->definition()->range();
  if (!Range::IsUnknown(value_range)) {
    *range = *value_range;
  }
}

void UnboxInt32Instr::InferRange(RangeAnalysis* analysis, Range* range) {
  if (value()->Type()->ToCid() == kSmiCid) {
    const Range* value_range = analysis->GetSmiRange(value());
    if (!Range::IsUnknown(value_range)) {
      *range = *value_range;
    }
  } else if (RangeAnalysis::IsIntegerDefinition(value()->definition())) {
    const Range* value_range = analysis->GetIntRange(value());
    if (!Range::IsUnknown(value_range)) {
      *range = *value_range;
    }
  } else if (value()->Type()->ToCid() == kSmiCid) {
    *range = Range::Full(RangeBoundary::kRangeBoundarySmi);
  } else {
    *range = Range::Full(RangeBoundary::kRangeBoundaryInt32);
  }
}

void UnboxUint32Instr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = NULL;

  if (value()->Type()->ToCid() == kSmiCid) {
    value_range = analysis->GetSmiRange(value());
  } else if (RangeAnalysis::IsIntegerDefinition(value()->definition())) {
    value_range = analysis->GetIntRange(value());
  } else {
    *range = Range(RangeBoundary::FromConstant(0),
                   RangeBoundary::FromConstant(kMaxUint32));
    return;
  }

  if (!Range::IsUnknown(value_range)) {
    if (value_range->IsPositive()) {
      *range = *value_range;
    } else {
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(kMaxUint32));
    }
  }
}

void UnboxInt64Instr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = value()->definition()->range();
  if (value_range != NULL) {
    *range = *value_range;
  } else if (!value()->definition()->IsInt64Definition() &&
             (value()->definition()->Type()->ToCid() != kSmiCid)) {
    *range = Range::Full(RangeBoundary::kRangeBoundaryInt64);
  }
}

void IntConverterInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  if (from() == kUntagged || to() == kUntagged) {
    ASSERT((from() == kUntagged &&
            (to() == kUnboxedIntPtr || to() == kUnboxedFfiIntPtr)) ||
           ((from() == kUnboxedIntPtr || from() == kUnboxedFfiIntPtr) &&
            to() == kUntagged));
  } else {
    ASSERT(from() == kUnboxedInt32 || from() == kUnboxedInt64 ||
           from() == kUnboxedUint32);
    ASSERT(to() == kUnboxedInt32 || to() == kUnboxedInt64 ||
           to() == kUnboxedUint32);
  }

  const Range* value_range = value()->definition()->range();
  if (Range::IsUnknown(value_range)) {
    return;
  }

  if (to() == kUnboxedUint32) {
    // TODO(vegorov): improve range information for unboxing to Uint32.
    *range =
        Range(RangeBoundary::FromConstant(0),
              RangeBoundary::FromConstant(static_cast<int64_t>(kMaxUint32)));
  } else {
    *range = *value_range;
    if (to() == kUnboxedInt32) {
      range->Clamp(RangeBoundary::kRangeBoundaryInt32);
    }
  }
}

static bool IsRedundantBasedOnRangeInformation(Value* index, Value* length) {
  // Range of the index is unknown can't decide if the check is redundant.
  Range* index_range = index->definition()->range();
  if (index_range == nullptr) {
    if (!(index->BindsToConstant() &&
          compiler::target::IsSmi(index->BoundConstant()))) {
      return false;
    }
    Range range;
    index->definition()->InferRange(nullptr, &range);
    ASSERT(!Range::IsUnknown(&range));
    index->definition()->set_range(range);
    index_range = index->definition()->range();
  }

  // Range of the index is not positive. Check can't be redundant.
  if (Range::ConstantMinSmi(index_range).ConstantValue() < 0) {
    return false;
  }

  RangeBoundary max = RangeBoundary::FromDefinition(index->definition());
  RangeBoundary max_upper = max.UpperBound();
  RangeBoundary array_length =
      RangeBoundary::FromDefinition(length->definition());
  RangeBoundary length_lower = array_length.LowerBound();
  if (max_upper.OverflowedSmi() || length_lower.OverflowedSmi()) {
    return false;
  }

  // Try to compare constant boundaries.
  if (max_upper.ConstantValue() < length_lower.ConstantValue()) {
    return true;
  }

  RangeBoundary canonical_length =
      CanonicalizeBoundary(array_length, RangeBoundary::PositiveInfinity());
  if (canonical_length.OverflowedSmi()) {
    return false;
  }

  // Try symbolic comparison.
  do {
    if (DependOnSameSymbol(max, canonical_length)) {
      return max.offset() < canonical_length.offset();
    }
  } while (CanonicalizeMaxBoundary(&max) ||
           CanonicalizeMinBoundary(&canonical_length));

  // Failed to prove that maximum is bounded with array length.
  return false;
}

bool CheckBoundBase::IsRedundant(bool use_loops) {
  // First, try to prove redundancy with the results of range analysis.
  if (IsRedundantBasedOnRangeInformation(index(), length())) {
    return true;
  } else if (!use_loops) {
    return false;
  }
  // Next, try to prove redundancy with the results of induction analysis.
  LoopInfo* loop = GetBlock()->loop_info();
  if (loop != nullptr) {
    return loop->IsInRange(this, index(), length());
  }
  return false;
}

}  // namespace dart
