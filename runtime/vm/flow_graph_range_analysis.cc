// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_range_analysis.h"

#include "vm/bit_vector.h"
#include "vm/il_printer.h"

namespace dart {

DEFINE_FLAG(bool, array_bounds_check_elimination, true,
    "Eliminate redundant bounds checks.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool, trace_integer_ir_selection, false,
    "Print integer IR selection optimization pass.");
DECLARE_FLAG(bool, trace_constant_propagation);

// Quick access to the locally defined isolate() method.
#define I (isolate())

void RangeAnalysis::Analyze() {
  CollectValues();
  InsertConstraints();
  InferRanges();
  IntegerInstructionSelector iis(flow_graph_);
  iis.Select();
  RemoveConstraints();
}


void RangeAnalysis::CollectValues() {
  const GrowableArray<Definition*>& initial =
      *flow_graph_->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* current = initial[i];
    if (current->Type()->ToCid() == kSmiCid) {
      values_.Add(current);
    } else if (current->IsMintDefinition()) {
      values_.Add(current);
    }
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();


    if (block->IsGraphEntry() || block->IsCatchBlockEntry()) {
      const GrowableArray<Definition*>& initial = block->IsGraphEntry()
          ? *block->AsGraphEntry()->initial_definitions()
          : *block->AsCatchBlockEntry()->initial_definitions();
      for (intptr_t i = 0; i < initial.length(); ++i) {
        Definition* current = initial[i];
        if (current->Type()->ToCid() == kSmiCid) {
          values_.Add(current);
        } else if (current->IsMintDefinition()) {
          values_.Add(current);
        }
      }
    }

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* current = phi_it.Current();
        if (current->Type()->ToCid() == kSmiCid) {
          values_.Add(current);
        }
      }
    }

    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if (defn != NULL) {
        if ((defn->Type()->ToCid() == kSmiCid) &&
            (defn->ssa_temp_index() != -1)) {
          values_.Add(defn);
        } else if ((defn->IsMintDefinition()) &&
                   (defn->ssa_temp_index() != -1)) {
          values_.Add(defn);
        }
      } else if (current->IsCheckSmi()) {
        smi_checks_.Add(current->AsCheckSmi());
      }
    }
  }
}


// Returns true if use is dominated by the given instruction.
// Note: uses that occur at instruction itself are not dominated by it.
static bool IsDominatedUse(Instruction* dom, Value* use) {
  BlockEntryInstr* dom_block = dom->GetBlock();

  Instruction* instr = use->instruction();

  PhiInstr* phi = instr->AsPhi();
  if (phi != NULL) {
    return dom_block->Dominates(phi->block()->PredecessorAt(use->use_index()));
  }

  BlockEntryInstr* use_block = instr->GetBlock();
  if (use_block == dom_block) {
    // Fast path for the case of block entry.
    if (dom_block == dom) return true;

    for (Instruction* curr = dom->next(); curr != NULL; curr = curr->next()) {
      if (curr == instr) return true;
    }

    return false;
  }

  return dom_block->Dominates(use_block);
}


void RangeAnalysis::RenameDominatedUses(Definition* def,
                                        Instruction* dom,
                                        Definition* other) {
  for (Value::Iterator it(def->input_use_list());
       !it.Done();
       it.Advance()) {
    Value* use = it.Current();

    // Skip dead phis.
    PhiInstr* phi = use->instruction()->AsPhi();
    ASSERT((phi == NULL) || phi->is_alive());
    if (IsDominatedUse(dom, use)) {
      use->BindTo(other);
    }
  }
}


// For a comparison operation return an operation for the equivalent flipped
// comparison: a (op) b === b (op') a.
static Token::Kind FlipComparison(Token::Kind op) {
  switch (op) {
    case Token::kEQ: return Token::kEQ;
    case Token::kNE: return Token::kNE;
    case Token::kLT: return Token::kGT;
    case Token::kGT: return Token::kLT;
    case Token::kLTE: return Token::kGTE;
    case Token::kGTE: return Token::kLTE;
    default:
      UNREACHABLE();
      return Token::kILLEGAL;
  }
}


// Given a boundary (right operand) and a comparison operation return
// a symbolic range constraint for the left operand of the comparison assuming
// that it evaluated to true.
// For example for the comparison a < b symbol a is constrained with range
// [Smi::kMinValue, b - 1].
Range* RangeAnalysis::ConstraintRange(Token::Kind op, Definition* boundary) {
  switch (op) {
    case Token::kEQ:
      return new(I) Range(RangeBoundary::FromDefinition(boundary),
                          RangeBoundary::FromDefinition(boundary));
    case Token::kNE:
      return Range::Unknown();
    case Token::kLT:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(boundary, -1));
    case Token::kGT:
      return new(I) Range(RangeBoundary::FromDefinition(boundary, 1),
                          RangeBoundary::MaxSmi());
    case Token::kLTE:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(boundary));
    case Token::kGTE:
      return new(I) Range(RangeBoundary::FromDefinition(boundary),
                          RangeBoundary::MaxSmi());
    default:
      UNREACHABLE();
      return Range::Unknown();
  }
}


ConstraintInstr* RangeAnalysis::InsertConstraintFor(Definition* defn,
                                                    Range* constraint_range,
                                                    Instruction* after) {
  // No need to constrain constants.
  if (defn->IsConstant()) return NULL;

  ConstraintInstr* constraint = new(I) ConstraintInstr(
      new(I) Value(defn), constraint_range);
  flow_graph_->InsertAfter(after, constraint, NULL, FlowGraph::kValue);
  RenameDominatedUses(defn, constraint, constraint);
  constraints_.Add(constraint);
  return constraint;
}


void RangeAnalysis::ConstrainValueAfterBranch(Definition* defn, Value* use) {
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
      op_kind = FlipComparison(rel_op->kind());
    }

    // Constrain definition at the true successor.
    ConstraintInstr* true_constraint =
        InsertConstraintFor(defn,
                            ConstraintRange(op_kind, boundary),
                            branch->true_successor());
    // Mark true_constraint an artificial use of boundary. This ensures
    // that constraint's range is recalculated if boundary's range changes.
    if (true_constraint != NULL) {
      true_constraint->AddDependency(boundary);
      true_constraint->set_target(branch->true_successor());
    }

    // Constrain definition with a negated condition at the false successor.
    ConstraintInstr* false_constraint =
        InsertConstraintFor(
            defn,
            ConstraintRange(Token::NegateComparison(op_kind), boundary),
            branch->false_successor());
    // Mark false_constraint an artificial use of boundary. This ensures
    // that constraint's range is recalculated if boundary's range changes.
    if (false_constraint != NULL) {
      false_constraint->AddDependency(boundary);
      false_constraint->set_target(branch->false_successor());
    }
  }
}


void RangeAnalysis::InsertConstraintsFor(Definition* defn) {
  for (Value* use = defn->input_use_list();
       use != NULL;
       use = use->next_use()) {
    if (use->instruction()->IsBranch()) {
      ConstrainValueAfterBranch(defn, use);
    } else if (use->instruction()->IsCheckArrayBound()) {
      ConstrainValueAfterCheckArrayBound(
          defn,
          use->instruction()->AsCheckArrayBound(),
          use->use_index());
    }
  }
}


void RangeAnalysis::ConstrainValueAfterCheckArrayBound(
    Definition* defn, CheckArrayBoundInstr* check, intptr_t use_index) {
  Range* constraint_range = NULL;
  if (use_index == CheckArrayBoundInstr::kIndexPos) {
    Definition* length = check->length()->definition();
    constraint_range = new(I) Range(
        RangeBoundary::FromConstant(0),
        RangeBoundary::FromDefinition(length, -1));
  } else {
    ASSERT(use_index == CheckArrayBoundInstr::kLengthPos);
    Definition* index = check->index()->definition();
    constraint_range = new(I) Range(
        RangeBoundary::FromDefinition(index, 1),
        RangeBoundary::MaxSmi());
  }
  InsertConstraintFor(defn, constraint_range, check);
}


void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < smi_checks_.length(); i++) {
    CheckSmiInstr* check = smi_checks_[i];
    ConstraintInstr* constraint =
        InsertConstraintFor(check->value()->definition(),
                            Range::UnknownSmi(),
                            check);
    if (constraint == NULL) {
      // No constraint was needed.
      continue;
    }
    // Mark the constraint's value's reaching type as smi.
    CompileType* smi_compile_type =
        ZoneCompileType::Wrap(CompileType::FromCid(kSmiCid));
    constraint->value()->SetReachingType(smi_compile_type);
  }

  for (intptr_t i = 0; i < values_.length(); i++) {
    InsertConstraintsFor(values_[i]);
  }

  for (intptr_t i = 0; i < constraints_.length(); i++) {
    InsertConstraintsFor(constraints_[i]);
  }
}


void RangeAnalysis::ResetWorklist() {
  if (marked_defns_ == NULL) {
    marked_defns_ = new(I) BitVector(flow_graph_->current_ssa_temp_index());
  } else {
    marked_defns_->Clear();
  }
  worklist_.Clear();
}


void RangeAnalysis::MarkDefinition(Definition* defn) {
  // Unwrap constrained value.
  while (defn->IsConstraint()) {
    defn = defn->AsConstraint()->value()->definition();
  }

  if (!marked_defns_->Contains(defn->ssa_temp_index())) {
    worklist_.Add(defn);
    marked_defns_->Add(defn->ssa_temp_index());
  }
}


RangeAnalysis::Direction RangeAnalysis::ToDirection(Value* val) {
  if (val->BindsToConstant()) {
    return (Smi::Cast(val->BoundConstant()).Value() >= 0) ? kPositive
                                                          : kNegative;
  } else if (val->definition()->range() != NULL) {
    Range* range = val->definition()->range();
    if (Range::ConstantMin(range).ConstantValue() >= 0) {
      return kPositive;
    } else if (Range::ConstantMax(range).ConstantValue() <= 0) {
      return kNegative;
    }
  }
  return kUnknown;
}


Range* RangeAnalysis::InferInductionVariableRange(JoinEntryInstr* loop_header,
                                                  PhiInstr* var) {
  BitVector* loop_info = loop_header->loop_info();

  Definition* initial_value = NULL;
  Direction direction = kUnknown;

  ResetWorklist();
  MarkDefinition(var);
  while (!worklist_.is_empty()) {
    Definition* defn = worklist_.RemoveLast();

    if (defn->IsPhi()) {
      PhiInstr* phi = defn->AsPhi();
      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        Definition* defn = phi->InputAt(i)->definition();

        if (!loop_info->Contains(defn->GetBlock()->preorder_number())) {
          // The value is coming from outside of the loop.
          if (initial_value == NULL) {
            initial_value = defn;
            continue;
          } else if (initial_value == defn) {
            continue;
          } else {
            return NULL;
          }
        }

        MarkDefinition(defn);
      }
    } else if (defn->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = defn->AsBinarySmiOp();

      switch (binary_op->op_kind()) {
        case Token::kADD: {
          const Direction growth_right =
              ToDirection(binary_op->right());
          if (growth_right != kUnknown) {
            UpdateDirection(&direction, growth_right);
            MarkDefinition(binary_op->left()->definition());
            break;
          }

          const Direction growth_left =
              ToDirection(binary_op->left());
          if (growth_left != kUnknown) {
            UpdateDirection(&direction, growth_left);
            MarkDefinition(binary_op->right()->definition());
            break;
          }

          return NULL;
        }

        case Token::kSUB: {
          const Direction growth_right =
              ToDirection(binary_op->right());
          if (growth_right != kUnknown) {
            UpdateDirection(&direction, Invert(growth_right));
            MarkDefinition(binary_op->left()->definition());
            break;
          }
          return NULL;
        }

        default:
          return NULL;
      }
    } else {
      return NULL;
    }
  }


  // We transitively discovered all dependencies of the given phi
  // and confirmed that it depends on a single value coming from outside of
  // the loop and some linear combinations of itself.
  // Compute the range based on initial value and the direction of the growth.
  switch (direction) {
    case kPositive:
      return new(I) Range(RangeBoundary::FromDefinition(initial_value),
                          RangeBoundary::MaxSmi());

    case kNegative:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(initial_value));

    case kUnknown:
    case kBoth:
      return Range::UnknownSmi();
  }

  UNREACHABLE();
  return NULL;
}


void RangeAnalysis::InferRangesRecursive(BlockEntryInstr* block) {
  JoinEntryInstr* join = block->AsJoinEntry();
  if (join != NULL) {
    const bool is_loop_header = (join->loop_info() != NULL);
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      if (definitions_->Contains(phi->ssa_temp_index())) {
        if (is_loop_header) {
          // Try recognizing simple induction variables.
          Range* range = InferInductionVariableRange(join, phi);
          if (range != NULL) {
            phi->range_ = range;
            continue;
          }
        }

        phi->InferRange();
      }
    }
  }

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();

    Definition* defn = current->AsDefinition();
    if ((defn != NULL) &&
        (defn->ssa_temp_index() != -1) &&
        definitions_->Contains(defn->ssa_temp_index())) {
      defn->InferRange();
    } else if (FLAG_array_bounds_check_elimination &&
               current->IsCheckArrayBound()) {
      CheckArrayBoundInstr* check = current->AsCheckArrayBound();
      RangeBoundary array_length =
          RangeBoundary::FromDefinition(check->length()->definition());
      if (check->IsRedundant(array_length)) {
        it.RemoveCurrentFromGraph();
      }
    }
  }

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    InferRangesRecursive(block->dominated_blocks()[i]);
  }
}


void RangeAnalysis::InferRanges() {
  if (FLAG_trace_range_analysis) {
    OS::Print("---- before range analysis -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
  // Initialize bitvector for quick filtering of int values.
  definitions_ =
      new(I) BitVector(flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < values_.length(); i++) {
    definitions_->Add(values_[i]->ssa_temp_index());
  }
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    definitions_->Add(constraints_[i]->ssa_temp_index());
  }

  // Infer initial values of ranges.
  const GrowableArray<Definition*>& initial =
      *flow_graph_->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* definition = initial[i];
    if (definitions_->Contains(definition->ssa_temp_index())) {
      definition->InferRange();
    }
  }
  InferRangesRecursive(flow_graph_->graph_entry());

  if (FLAG_trace_range_analysis) {
    OS::Print("---- after range analysis -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
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


IntegerInstructionSelector::IntegerInstructionSelector(FlowGraph* flow_graph)
    : flow_graph_(flow_graph),
      isolate_(NULL) {
  ASSERT(flow_graph_ != NULL);
  isolate_ = flow_graph_->isolate();
  ASSERT(isolate_ != NULL);
  selected_uint32_defs_ =
      new(I) BitVector(flow_graph_->current_ssa_temp_index());
}


void IntegerInstructionSelector::Select() {
  if (FLAG_trace_integer_ir_selection) {
    OS::Print("---- starting integer ir selection -------\n");
  }
  FindPotentialUint32Definitions();
  FindUint32NarrowingDefinitions();
  Propagate();
  ReplaceInstructions();
  if (FLAG_trace_integer_ir_selection) {
    OS::Print("---- after integer ir selection -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
}


bool IntegerInstructionSelector::IsPotentialUint32Definition(Definition* def) {
  // TODO(johnmccutchan): Consider Smi operations, to avoid unnecessary tagging
  // & untagged of intermediate results.
  // TODO(johnmccutchan): Consider phis.
  return def->IsBoxInteger()   ||   // BoxMint.
         def->IsUnboxInteger() ||   // UnboxMint.
         def->IsBinaryMintOp() ||
         def->IsShiftMintOp()  ||
         def->IsUnaryMintOp();
}


void IntegerInstructionSelector::FindPotentialUint32Definitions() {
  if (FLAG_trace_integer_ir_selection) {
    OS::Print("++++ Finding potential Uint32 definitions:\n");
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if ((defn != NULL) && (defn->ssa_temp_index() != -1)) {
        if (IsPotentialUint32Definition(defn)) {
          if (FLAG_trace_integer_ir_selection) {
           OS::Print("Adding %s\n", current->ToCString());
          }
          potential_uint32_defs_.Add(defn);
        }
      }
    }
  }
}


// BinaryMintOp masks and stores into unsigned typed arrays that truncate the
// value into a Uint32 range.
bool IntegerInstructionSelector::IsUint32NarrowingDefinition(Definition* def) {
  if (def->IsBinaryMintOp()) {
    BinaryMintOpInstr* op = def->AsBinaryMintOp();
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
    OS::Print("++++ Selecting Uint32 definitions:\n");
    OS::Print("++++ Initial set:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (IsUint32NarrowingDefinition(defn)) {
      if (FLAG_trace_integer_ir_selection) {
        OS::Print("Adding %s\n", defn->ToCString());
      }
      selected_uint32_defs_->Add(defn->ssa_temp_index());
    }
  }
}


bool IntegerInstructionSelector::AllUsesAreUint32Narrowing(Value* list_head) {
  for (Value::Iterator it(list_head);
       !it.Done();
       it.Advance()) {
    Value* use = it.Current();
    Definition* defn = use->instruction()->AsDefinition();
    if ((defn == NULL) ||
        (defn->ssa_temp_index() == -1) ||
        !selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      return false;
    }
  }
  return true;
}


bool IntegerInstructionSelector::CanBecomeUint32(Definition* def) {
  ASSERT(IsPotentialUint32Definition(def));
  if (def->IsBoxInteger()) {
    // If a BoxInteger's input is a candidate, the box is a candidate.
    BoxIntegerInstr* box = def->AsBoxInteger();
    Definition* box_input = box->value()->definition();
    return selected_uint32_defs_->Contains(box_input->ssa_temp_index());
  }
  // A right shift with an input outside of Uint32 range cannot be converted
  // because we need the high bits.
  if (def->IsShiftMintOp()) {
    ShiftMintOpInstr* op = def->AsShiftMintOp();
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
      OS::Print("+++ Iteration: %" Pd "\n", iteration++);
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
        if (FLAG_trace_integer_ir_selection) {
          OS::Print("Adding %s\n", defn->ToCString());
        }
        // Found a new candidate.
        selected_uint32_defs_->Add(defn->ssa_temp_index());
        // Haven't reached fixed point yet.
        changed = true;
      }
    }
  }
  if (FLAG_trace_integer_ir_selection) {
    OS::Print("Reached fixed point\n");
  }
}


Definition* IntegerInstructionSelector::ConstructReplacementFor(
    Definition* def) {
  // Should only see mint definitions.
  ASSERT(IsPotentialUint32Definition(def));
  // Should not see constant instructions.
  ASSERT(!def->IsConstant());
  if (def->IsBinaryMintOp()) {
    BinaryMintOpInstr* op = def->AsBinaryMintOp();
    Token::Kind op_kind = op->op_kind();
    Value* left = op->left()->CopyWithType();
    Value* right = op->right()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return new(I) BinaryUint32OpInstr(op_kind, left, right, deopt_id);
  } else if (def->IsBoxInteger()) {
    BoxIntegerInstr* box = def->AsBoxInteger();
    Value* value = box->value()->CopyWithType();
    return new(I) BoxUint32Instr(value);
  } else if (def->IsUnboxInteger()) {
    UnboxIntegerInstr* unbox = def->AsUnboxInteger();
    Value* value = unbox->value()->CopyWithType();
    intptr_t deopt_id = unbox->deopt_id();
    return new(I) UnboxUint32Instr(value, deopt_id);
  } else if (def->IsUnaryMintOp()) {
    UnaryMintOpInstr* op = def->AsUnaryMintOp();
    Token::Kind op_kind = op->op_kind();
    Value* value = op->value()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return new(I) UnaryUint32OpInstr(op_kind, value, deopt_id);
  } else if (def->IsShiftMintOp()) {
    ShiftMintOpInstr* op = def->AsShiftMintOp();
    Token::Kind op_kind = op->op_kind();
    Value* left = op->left()->CopyWithType();
    Value* right = op->right()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return new(I) ShiftUint32OpInstr(op_kind, left, right, deopt_id);
  }
  UNREACHABLE();
  return NULL;
}


void IntegerInstructionSelector::ReplaceInstructions() {
  if (FLAG_trace_integer_ir_selection) {
    OS::Print("++++ Replacing instructions:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (!selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      // Not a candidate.
      continue;
    }
    Definition* replacement = ConstructReplacementFor(defn);
    ASSERT(replacement != NULL);
    if (FLAG_trace_integer_ir_selection) {
      OS::Print("Replacing %s with %s\n", defn->ToCString(),
                                          replacement->ToCString());
    }
    defn->ReplaceWith(replacement, NULL);
    ASSERT(flow_graph_->VerifyUseLists());
  }
}


RangeBoundary RangeBoundary::FromDefinition(Definition* defn, int64_t offs) {
  if (defn->IsConstant() && defn->AsConstant()->value().IsSmi()) {
    return FromConstant(Smi::Cast(defn->AsConstant()->value()).Value() + offs);
  }
  return RangeBoundary(kSymbol, reinterpret_cast<intptr_t>(defn), offs);
}


RangeBoundary RangeBoundary::LowerBound() const {
  if (IsInfinity()) {
    return NegativeInfinity();
  }
  if (IsConstant()) return *this;
  return Add(Range::ConstantMin(symbol()->range()),
             RangeBoundary::FromConstant(offset_),
             NegativeInfinity());
}


RangeBoundary RangeBoundary::UpperBound() const {
  if (IsInfinity()) {
    return PositiveInfinity();
  }
  if (IsConstant()) return *this;
  return Add(Range::ConstantMax(symbol()->range()),
             RangeBoundary::FromConstant(offset_),
             PositiveInfinity());
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

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  }
  return false;
}


static Definition* UnwrapConstraint(Definition* defn) {
  while (defn->IsConstraint()) {
    defn = defn->AsConstraint()->value()->definition();
  }
  return defn;
}


static bool AreEqualDefinitions(Definition* a, Definition* b) {
  a = UnwrapConstraint(a);
  b = UnwrapConstraint(b);
  return (a == b) ||
      (a->AllowsCSE() &&
       a->Dependencies().IsNone() &&
       b->AllowsCSE() &&
       b->Dependencies().IsNone() &&
       a->Equals(b));
}


// Returns true if two range boundaries refer to the same symbol.
static bool DependOnSameSymbol(const RangeBoundary& a, const RangeBoundary& b) {
  return a.IsSymbol() && b.IsSymbol() &&
      AreEqualDefinitions(a.symbol(), b.symbol());
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

  if ((value == 0) ||
      (shift_count == 0) ||
      ((limit > 0) && Utils::IsInt(static_cast<int>(limit), value))) {
    // Result stays in 64 bit range.
    int64_t result = value << shift_count;
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

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->min().symbol(), offset),
      RangeBoundary::NegativeInfinity());

  return true;
}


RangeBoundary RangeBoundary::Min(RangeBoundary a, RangeBoundary b,
                                 RangeSize size) {
  ASSERT(!(a.IsNegativeInfinity() || b.IsNegativeInfinity()));
  ASSERT(!a.IsUnknown() || !b.IsUnknown());
  if (a.IsUnknown() && !b.IsUnknown()) {
    return b;
  }
  if (!a.IsUnknown() && b.IsUnknown()) {
    return a;
  }
  if (size == kRangeBoundarySmi) {
    if (a.IsSmiMaximumOrAbove() && !b.IsSmiMaximumOrAbove()) {
      return b;
    }
    if (!a.IsSmiMaximumOrAbove() && b.IsSmiMaximumOrAbove()) {
      return a;
    }
  } else {
    ASSERT(size == kRangeBoundaryInt64);
    if (a.IsMaximumOrAbove() && !b.IsMaximumOrAbove()) {
      return b;
    }
    if (!a.IsMaximumOrAbove() && b.IsMaximumOrAbove()) {
      return a;
    }
  }

  if (a.Equals(b)) {
    return b;
  }

  {
    RangeBoundary canonical_a =
        CanonicalizeBoundary(a, RangeBoundary::PositiveInfinity());
    RangeBoundary canonical_b =
        CanonicalizeBoundary(b, RangeBoundary::PositiveInfinity());
    do {
      if (DependOnSameSymbol(canonical_a, canonical_b)) {
        a = canonical_a;
        b = canonical_b;
        break;
      }
    } while (CanonicalizeMaxBoundary(&canonical_a) ||
             CanonicalizeMaxBoundary(&canonical_b));
  }

  if (DependOnSameSymbol(a, b)) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const int64_t min_a = a.UpperBound().Clamp(size).ConstantValue();
  const int64_t min_b = b.UpperBound().Clamp(size).ConstantValue();

  return RangeBoundary::FromConstant(Utils::Minimum(min_a, min_b));
}


RangeBoundary RangeBoundary::Max(RangeBoundary a, RangeBoundary b,
                                 RangeSize size) {
  ASSERT(!(a.IsPositiveInfinity() || b.IsPositiveInfinity()));
  ASSERT(!a.IsUnknown() || !b.IsUnknown());
  if (a.IsUnknown() && !b.IsUnknown()) {
    return b;
  }
  if (!a.IsUnknown() && b.IsUnknown()) {
    return a;
  }
  if (size == kRangeBoundarySmi) {
    if (a.IsSmiMinimumOrBelow() && !b.IsSmiMinimumOrBelow()) {
      return b;
    }
    if (!a.IsSmiMinimumOrBelow() && b.IsSmiMinimumOrBelow()) {
      return a;
    }
  } else {
     ASSERT(size == kRangeBoundaryInt64);
    if (a.IsMinimumOrBelow() && !b.IsMinimumOrBelow()) {
      return b;
    }
    if (!a.IsMinimumOrBelow() && b.IsMinimumOrBelow()) {
      return a;
    }
  }
  if (a.Equals(b)) {
    return b;
  }

  {
    RangeBoundary canonical_a =
        CanonicalizeBoundary(a, RangeBoundary::NegativeInfinity());
    RangeBoundary canonical_b =
        CanonicalizeBoundary(b, RangeBoundary::NegativeInfinity());

    do {
      if (DependOnSameSymbol(canonical_a, canonical_b)) {
        a = canonical_a;
        b = canonical_b;
        break;
      }
    } while (CanonicalizeMinBoundary(&canonical_a) ||
             CanonicalizeMinBoundary(&canonical_b));
  }

  if (DependOnSameSymbol(a, b)) {
    return (a.offset() <= b.offset()) ? b : a;
  }

  const int64_t max_a = a.LowerBound().Clamp(size).ConstantValue();
  const int64_t max_b = b.LowerBound().Clamp(size).ConstantValue();

  return RangeBoundary::FromConstant(Utils::Maximum(max_a, max_b));
}


int64_t RangeBoundary::ConstantValue() const {
  ASSERT(IsConstant());
  return value_;
}


bool Range::IsPositive() const {
  if (min().IsNegativeInfinity()) {
    return false;
  }
  if (min().LowerBound().ConstantValue() < 0) {
    return false;
  }
  if (max().IsPositiveInfinity()) {
    return true;
  }
  return max().UpperBound().ConstantValue() >= 0;
}


bool Range::OnlyLessThanOrEqualTo(int64_t val) const {
  if (max().IsPositiveInfinity()) {
    // Cannot be true.
    return false;
  }
  if (max().UpperBound().ConstantValue() > val) {
    // Not true.
    return false;
  }
  return true;
}


bool Range::OnlyGreaterThanOrEqualTo(int64_t val) const {
  if (min().IsNegativeInfinity()) {
    return false;
  }
  if (min().LowerBound().ConstantValue() < val) {
    return false;
  }
  return true;
}


// Inclusive.
bool Range::IsWithin(int64_t min_int, int64_t max_int) const {
  RangeBoundary lower_min = min().LowerBound();
  if (lower_min.IsNegativeInfinity() || (lower_min.ConstantValue() < min_int)) {
    return false;
  }
  RangeBoundary upper_max = max().UpperBound();
  if (upper_max.IsPositiveInfinity() || (upper_max.ConstantValue() > max_int)) {
    return false;
  }
  return true;
}


bool Range::Overlaps(int64_t min_int, int64_t max_int) const {
  RangeBoundary lower = min().LowerBound();
  RangeBoundary upper = max().UpperBound();
  const int64_t this_min = lower.IsNegativeInfinity() ?
      RangeBoundary::kMin : lower.ConstantValue();
  const int64_t this_max = upper.IsPositiveInfinity() ?
      RangeBoundary::kMax : upper.ConstantValue();
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
  if (DependOnSameSymbol(min(), max()) && min().offset() > max().offset()) {
    return true;
  }
  return false;
}


void Range::Clamp(RangeBoundary::RangeSize size) {
  min_ = min_.Clamp(size);
  max_ = max_.Clamp(size);
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
      left_min,
      left_min.ConstantValue() > 0 ? right_min : right_max,
      left_min.ConstantValue() > 0
          ? RangeBoundary::PositiveInfinity()
          : RangeBoundary::NegativeInfinity());

  *result_max = RangeBoundary::Shl(
      left_max,
      left_max.ConstantValue() > 0 ? right_max : right_min,
      left_max.ConstantValue() > 0
          ? RangeBoundary::PositiveInfinity()
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
      left_min,
      left_min.ConstantValue() > 0 ? right_max : right_min);

  *result_max = RangeBoundary::Shr(
      left_max,
      left_max.ConstantValue() > 0 ? right_min : right_max);
}


bool Range::And(const Range* left_range,
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
    return true;
  }

  if (Range::ConstantMin(left_range).ConstantValue() >= 0) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = Range::ConstantMax(left_range);
    return true;
  }

  return false;
}


static bool IsArrayLength(Definition* defn) {
  if (defn == NULL) {
    return false;
  }
  LoadFieldInstr* load = defn->AsLoadField();
  return (load != NULL) && load->IsImmutableLengthLoad();
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

  RangeBoundary left_min =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->min();

  RangeBoundary left_max =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->max();

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

  RangeBoundary left_min =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->min();

  RangeBoundary left_max =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->max();

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


bool Range::Mul(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left_range != NULL);
  ASSERT(right_range != NULL);
  ASSERT(result_min != NULL);
  ASSERT(result_max != NULL);

  const int64_t left_max = ConstantAbsMax(left_range);
  const int64_t right_max = ConstantAbsMax(right_range);
  if ((left_max <= -kSmiMin) && (right_max <= -kSmiMin) &&
      ((left_max == 0) || (right_max <= kMaxInt64 / left_max))) {
    // Product of left and right max values stays in 64 bit range.
    const int64_t mul_max = left_max * right_max;
    if (Smi::IsValid(mul_max) && Smi::IsValid(-mul_max)) {
      const int64_t r_min =
          OnlyPositiveOrZero(*left_range, *right_range) ? 0 : -mul_max;
      *result_min = RangeBoundary::FromConstant(r_min);
      const int64_t r_max =
          OnlyNegativeOrZero(*left_range, *right_range) ? 0 : mul_max;
      *result_max = RangeBoundary::FromConstant(r_max);
      return true;
    }
  }
  return false;
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
  const int64_t abs_min = Utils::Abs(Range::ConstantMin(range).ConstantValue());
  const int64_t abs_max = Utils::Abs(Range::ConstantMax(range).ConstantValue());
  return Utils::Maximum(abs_min, abs_max);
}


Range* Range::BinaryOp(const Token::Kind op,
                       const Range* left_range,
                       const Range* right_range,
                       Definition* left_defn) {
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
    case Token::kMUL: {
      if (!Range::Mul(left_range, right_range, &min, &max)) {
        return NULL;
      }
      break;
    }
    case Token::kSHL: {
      Range::Shl(left_range, right_range, &min, &max);
      break;
    }
    case Token::kSHR: {
      Range::Shr(left_range, right_range, &min, &max);
      break;
    }
    case Token::kBIT_AND:
      if (!Range::And(left_range, right_range, &min, &max)) {
        return NULL;
      }
      break;
    default:
      return NULL;
      break;
  }

  ASSERT(!min.IsUnknown() && !max.IsUnknown());

  return new Range(min, max);
}


void Definition::InferRange() {
  if (Type()->ToCid() == kSmiCid) {
    if (range_ == NULL) {
      range_ = Range::UnknownSmi();
    }
  } else if (IsMintDefinition()) {
    if (range_ == NULL) {
      range_ = Range::Unknown();
    }
  } else {
    // Only Smi and Mint supported.
    UNREACHABLE();
  }
}


void PhiInstr::InferRange() {
  RangeBoundary new_min;
  RangeBoundary new_max;

  ASSERT(Type()->ToCid() == kSmiCid);

  for (intptr_t i = 0; i < InputCount(); i++) {
    Range* input_range = InputAt(i)->definition()->range();
    if (input_range == NULL) {
      range_ = Range::UnknownSmi();
      return;
    }

    if (new_min.IsUnknown()) {
      new_min = Range::ConstantMin(input_range);
    } else {
      new_min = RangeBoundary::Min(new_min,
                                   Range::ConstantMinSmi(input_range),
                                   RangeBoundary::kRangeBoundarySmi);
    }

    if (new_max.IsUnknown()) {
      new_max = Range::ConstantMax(input_range);
    } else {
      new_max = RangeBoundary::Max(new_max,
                                   Range::ConstantMaxSmi(input_range),
                                   RangeBoundary::kRangeBoundarySmi);
    }
  }

  ASSERT(new_min.IsUnknown() == new_max.IsUnknown());
  if (new_min.IsUnknown()) {
    range_ = Range::UnknownSmi();
    return;
  }

  range_ = new Range(new_min, new_max);
}


void ConstantInstr::InferRange() {
  if (value_.IsSmi()) {
    if (range_ == NULL) {
      int64_t value = Smi::Cast(value_).Value();
      range_ = new Range(RangeBoundary::FromConstant(value),
                         RangeBoundary::FromConstant(value));
    }
  } else if (value_.IsMint()) {
    if (range_ == NULL) {
      int64_t value = Mint::Cast(value_).value();
      range_ = new Range(RangeBoundary::FromConstant(value),
                         RangeBoundary::FromConstant(value));
    }
  } else {
    // Only Smi and Mint supported.
    UNREACHABLE();
  }
}


void UnboxIntegerInstr::InferRange() {
  if (range_ == NULL) {
    Definition* unboxed = value()->definition();
    ASSERT(unboxed != NULL);
    Range* range = unboxed->range();
    if (range == NULL) {
      range_ = Range::Unknown();
      return;
    }
    range_ = new Range(range->min(), range->max());
  }
}


void ConstraintInstr::InferRange() {
  Range* value_range = value()->definition()->range();

  // Only constraining smi values.
  ASSERT(value()->IsSmiValue());

  RangeBoundary min;
  RangeBoundary max;

  {
    RangeBoundary value_min = (value_range == NULL) ?
        RangeBoundary() : value_range->min();
    RangeBoundary constraint_min = constraint()->min();
    min = RangeBoundary::Max(value_min, constraint_min,
                             RangeBoundary::kRangeBoundarySmi);
  }

  ASSERT(!min.IsUnknown());

  {
    RangeBoundary value_max = (value_range == NULL) ?
        RangeBoundary() : value_range->max();
    RangeBoundary constraint_max = constraint()->max();
    max = RangeBoundary::Min(value_max, constraint_max,
                             RangeBoundary::kRangeBoundarySmi);
  }

  ASSERT(!max.IsUnknown());

  range_ = new Range(min, max);

  // Mark branches that generate unsatisfiable constraints as constant.
  if (target() != NULL && range_->IsUnsatisfiable()) {
    BranchInstr* branch =
        target()->PredecessorAt(0)->last_instruction()->AsBranch();
    if (target() == branch->true_successor()) {
      // True unreachable.
      if (FLAG_trace_constant_propagation) {
        OS::Print("Range analysis: True unreachable (B%" Pd ")\n",
                  branch->true_successor()->block_id());
      }
      branch->set_constant_target(branch->false_successor());
    } else {
      ASSERT(target() == branch->false_successor());
      // False unreachable.
      if (FLAG_trace_constant_propagation) {
        OS::Print("Range analysis: False unreachable (B%" Pd ")\n",
                  branch->false_successor()->block_id());
      }
      branch->set_constant_target(branch->true_successor());
    }
  }
}


void LoadFieldInstr::InferRange() {
  if ((range_ == NULL) &&
      ((recognized_kind() == MethodRecognizer::kObjectArrayLength) ||
       (recognized_kind() == MethodRecognizer::kImmutableArrayLength))) {
    range_ = new Range(RangeBoundary::FromConstant(0),
                       RangeBoundary::FromConstant(Array::kMaxElements));
    return;
  }
  if ((range_ == NULL) &&
      (recognized_kind() == MethodRecognizer::kTypedDataLength)) {
    range_ = new Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
    return;
  }
  if ((range_ == NULL) &&
      (recognized_kind() == MethodRecognizer::kStringBaseLength)) {
    range_ = new Range(RangeBoundary::FromConstant(0),
                       RangeBoundary::FromConstant(String::kMaxElements));
    return;
  }
  Definition::InferRange();
}



void LoadIndexedInstr::InferRange() {
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      range_ = new Range(RangeBoundary::FromConstant(-128),
                         RangeBoundary::FromConstant(127));
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      range_ = new Range(RangeBoundary::FromConstant(0),
                         RangeBoundary::FromConstant(255));
      break;
    case kTypedDataInt16ArrayCid:
      range_ = new Range(RangeBoundary::FromConstant(-32768),
                         RangeBoundary::FromConstant(32767));
      break;
    case kTypedDataUint16ArrayCid:
      range_ = new Range(RangeBoundary::FromConstant(0),
                         RangeBoundary::FromConstant(65535));
      break;
    case kTypedDataInt32ArrayCid:
      if (Typed32BitIsSmi()) {
        range_ = Range::UnknownSmi();
      } else {
        range_ = new Range(RangeBoundary::FromConstant(kMinInt32),
                           RangeBoundary::FromConstant(kMaxInt32));
      }
      break;
    case kTypedDataUint32ArrayCid:
      if (Typed32BitIsSmi()) {
        range_ = Range::UnknownSmi();
      } else {
        range_ = new Range(RangeBoundary::FromConstant(0),
                           RangeBoundary::FromConstant(kMaxUint32));
      }
      break;
    case kOneByteStringCid:
      range_ = new Range(RangeBoundary::FromConstant(0),
                         RangeBoundary::FromConstant(0xFF));
      break;
    case kTwoByteStringCid:
      range_ = new Range(RangeBoundary::FromConstant(0),
                         RangeBoundary::FromConstant(0xFFFF));
      break;
    default:
      Definition::InferRange();
      break;
  }
}


void IfThenElseInstr::InferRange() {
  const intptr_t min = Utils::Minimum(if_true_, if_false_);
  const intptr_t max = Utils::Maximum(if_true_, if_false_);
  range_ = new Range(RangeBoundary::FromConstant(min),
                     RangeBoundary::FromConstant(max));
}


void BinarySmiOpInstr::InferRange() {
  // TODO(vegorov): canonicalize BinarySmiOp to always have constant on the
  // right and a non-constant on the left.
  Definition* left_defn = left()->definition();

  Range* left_range = left_defn->range();
  Range* right_range = right()->definition()->range();

  if ((left_range == NULL) || (right_range == NULL)) {
    range_ = Range::UnknownSmi();
    return;
  }

  Range* possible_range = Range::BinaryOp(op_kind(),
                                          left_range,
                                          right_range,
                                          left_defn);

  if ((range_ == NULL) && (possible_range == NULL)) {
    // Initialize.
    range_ = Range::UnknownSmi();
    return;
  }

  if (possible_range == NULL) {
    // Nothing new.
    return;
  }

  range_ = possible_range;

  ASSERT(!range_->min().IsUnknown() && !range_->max().IsUnknown());
  // Calculate overflowed status before clamping.
  const bool overflowed = range_->min().LowerBound().OverflowedSmi() ||
                          range_->max().UpperBound().OverflowedSmi();
  set_overflow(overflowed);

  // Clamp value to be within smi range.
  range_->Clamp(RangeBoundary::kRangeBoundarySmi);
}


void BinaryMintOpInstr::InferRange() {
  // TODO(vegorov): canonicalize BinaryMintOpInstr to always have constant on
  // the right and a non-constant on the left.
  Definition* left_defn = left()->definition();

  Range* left_range = left_defn->range();
  Range* right_range = right()->definition()->range();

  if ((left_range == NULL) || (right_range == NULL)) {
    range_ = Range::Unknown();
    return;
  }

  Range* possible_range = Range::BinaryOp(op_kind(),
                                          left_range,
                                          right_range,
                                          left_defn);

  if ((range_ == NULL) && (possible_range == NULL)) {
    // Initialize.
    range_ = Range::Unknown();
    return;
  }

  if (possible_range == NULL) {
    // Nothing new.
    return;
  }

  range_ = possible_range;

  ASSERT(!range_->min().IsUnknown() && !range_->max().IsUnknown());

  // Calculate overflowed status before clamping.
  const bool overflowed = range_->min().LowerBound().OverflowedMint() ||
                          range_->max().UpperBound().OverflowedMint();
  set_can_overflow(overflowed);

  // Clamp value to be within mint range.
  range_->Clamp(RangeBoundary::kRangeBoundaryInt64);
}


void ShiftMintOpInstr::InferRange() {
  Definition* left_defn = left()->definition();

  Range* left_range = left_defn->range();
  Range* right_range = right()->definition()->range();

  if ((left_range == NULL) || (right_range == NULL)) {
    range_ = Range::Unknown();
    return;
  }

  Range* possible_range = Range::BinaryOp(op_kind(),
                                          left_range,
                                          right_range,
                                          left_defn);

  if ((range_ == NULL) && (possible_range == NULL)) {
    // Initialize.
    range_ = Range::Unknown();
    return;
  }

  if (possible_range == NULL) {
    // Nothing new.
    return;
  }

  range_ = possible_range;

  ASSERT(!range_->min().IsUnknown() && !range_->max().IsUnknown());

  // Calculate overflowed status before clamping.
  const bool overflowed = range_->min().LowerBound().OverflowedMint() ||
                          range_->max().UpperBound().OverflowedMint();
  set_can_overflow(overflowed);

  // Clamp value to be within mint range.
  range_->Clamp(RangeBoundary::kRangeBoundaryInt64);
}


void BoxIntegerInstr::InferRange() {
  Range* input_range = value()->definition()->range();
  if (input_range != NULL) {
    bool is_smi = !input_range->min().LowerBound().OverflowedSmi() &&
                  !input_range->max().UpperBound().OverflowedSmi();
    set_is_smi(is_smi);
    // The output range is the same as the input range.
    range_ = input_range;
  }
}


bool CheckArrayBoundInstr::IsRedundant(const RangeBoundary& length) {
  Range* index_range = index()->definition()->range();

  // Range of the index is unknown can't decide if the check is redundant.
  if (index_range == NULL) {
    return false;
  }

  // Range of the index is not positive. Check can't be redundant.
  if (Range::ConstantMinSmi(index_range).ConstantValue() < 0) {
    return false;
  }

  RangeBoundary max = CanonicalizeBoundary(index_range->max(),
                                           RangeBoundary::PositiveInfinity());

  if (max.OverflowedSmi()) {
    return false;
  }


  RangeBoundary max_upper = max.UpperBound();
  RangeBoundary length_lower = length.LowerBound();

  if (max_upper.OverflowedSmi() || length_lower.OverflowedSmi()) {
    return false;
  }

  // Try to compare constant boundaries.
  if (max_upper.ConstantValue() < length_lower.ConstantValue()) {
    return true;
  }

  RangeBoundary canonical_length =
      CanonicalizeBoundary(length, RangeBoundary::PositiveInfinity());
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


}  // namespace dart
