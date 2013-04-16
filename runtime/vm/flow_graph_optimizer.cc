// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/cha.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/hash_map.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, array_bounds_check_elimination, true,
    "Eliminate redundant bounds checks.");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");
DEFINE_FLAG(int, max_polymorphic_checks, 4,
    "Maximum number of polymorphic check, otherwise it is megamorphic.");
DEFINE_FLAG(bool, remove_redundant_phis, true, "Remove redundant phis.");
DEFINE_FLAG(bool, trace_constant_propagation, false,
    "Print constant propagation and useless code elimination.");
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool, truncating_left_shift, true,
    "Optimize left shift to truncate if possible");
DEFINE_FLAG(bool, use_cha, true, "Use class hierarchy analysis.");
DECLARE_FLAG(bool, eliminate_type_checks);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, trace_type_check_elimination);



// Optimize instance calls using ICData.
void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


// Optimize instance calls using cid.
// Attempts to convert an instance call (IC call) using propagated class-ids,
// e.g., receiver class id, guarded-cid.
void FlowGraphOptimizer::ApplyClassIds() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (call->HasICData()) {
          if (TryCreateICData(call)) {
            VisitInstanceCall(call);
          }
        }
      } else if (instr->IsPolymorphicInstanceCall()) {
        SpecializePolymorphicInstanceCall(instr->AsPolymorphicInstanceCall());
      } else if (instr->IsStrictCompare()) {
        VisitStrictCompare(instr->AsStrictCompare());
      } else if (instr->IsBranch()) {
        ComparisonInstr* compare = instr->AsBranch()->comparison();
        if (compare->IsStrictCompare()) {
          VisitStrictCompare(compare->AsStrictCompare());
        }
      }
    }
    current_iterator_ = NULL;
  }
}


// Attempt to build ICData for call using propagated class-ids.
bool FlowGraphOptimizer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  if (call->ic_data()->NumberOfChecks() > 0) {
    // This occurs when an instance call has too many checks.
    // TODO(srdjan): Replace IC call with megamorphic call.
    return false;
  }
  GrowableArray<intptr_t> class_ids(call->ic_data()->num_args_tested());
  ASSERT(call->ic_data()->num_args_tested() <= call->ArgumentCount());
  for (intptr_t i = 0; i < call->ic_data()->num_args_tested(); i++) {
    intptr_t cid = call->PushArgumentAt(i)->value()->Type()->ToCid();
    class_ids.Add(cid);
  }
  // TODO(srdjan): Test for number of arguments checked greater than 1.
  if (class_ids.length() != 1) {
    return false;
  }
  if (class_ids[0] != kDynamicCid) {
    const intptr_t num_named_arguments = call->argument_names().IsNull() ?
        0 : call->argument_names().Length();
    const Class& receiver_class = Class::Handle(
        Isolate::Current()->class_table()->At(class_ids[0]));
    Function& function = Function::Handle();
    function = Resolver::ResolveDynamicForReceiverClass(
        receiver_class,
        call->function_name(),
        call->ArgumentCount(),
        num_named_arguments);
    if (function.IsNull()) {
      return false;
    }
    // Create new ICData, do not modify the one attached to the instruction
    // since it is attached to the assembly instruction itself.
    // TODO(srdjan): Prevent modification of ICData object that is
    // referenced in assembly code.
    ICData& ic_data = ICData::ZoneHandle(ICData::New(
        flow_graph_->parsed_function().function(),
        call->function_name(),
        call->deopt_id(),
        class_ids.length()));
    ic_data.AddReceiverCheck(class_ids[0], function);
    call->set_ic_data(&ic_data);
    return true;
  }
  return false;
}


static const ICData& SpecializeICData(const ICData& ic_data, intptr_t cid) {
  ASSERT(ic_data.num_args_tested() == 1);

  if ((ic_data.NumberOfChecks() == 1) &&
      (ic_data.GetReceiverClassIdAt(0) == cid)) {
    return ic_data;  // Nothing to do
  }

  const ICData& new_ic_data = ICData::ZoneHandle(ICData::New(
      Function::Handle(ic_data.function()),
      String::Handle(ic_data.target_name()),
      ic_data.deopt_id(),
      ic_data.num_args_tested()));

  const Function& function =
      Function::Handle(ic_data.GetTargetForReceiverClassId(cid));
  if (!function.IsNull()) {
    new_ic_data.AddReceiverCheck(cid, function);
  }

  return new_ic_data;
}


void FlowGraphOptimizer::SpecializePolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  if (!call->with_checks()) {
    return;  // Already specialized.
  }

  const intptr_t receiver_cid =
      call->PushArgumentAt(0)->value()->Type()->ToCid();
  if (receiver_cid == kDynamicCid) {
    return;  // No information about receiver was infered.
  }

  const ICData& ic_data = SpecializeICData(call->ic_data(), receiver_cid);

  const bool with_checks = false;
  PolymorphicInstanceCallInstr* specialized =
      new PolymorphicInstanceCallInstr(call->instance_call(),
                                       ic_data,
                                       with_checks);
  call->ReplaceWith(specialized, current_iterator());
}


static BinarySmiOpInstr* AsSmiShiftLeftInstruction(Definition* d) {
  BinarySmiOpInstr* instr = d->AsBinarySmiOp();
  if ((instr != NULL) && (instr->op_kind() == Token::kSHL)) {
    return instr;
  }
  return NULL;
}


static bool IsPositiveOrZeroSmiConst(Definition* d) {
  ConstantInstr* const_instr = d->AsConstant();
  if ((const_instr != NULL) && (const_instr->value().IsSmi())) {
    return Smi::Cast(const_instr->value()).Value() >= 0;
  }
  return false;
}


void FlowGraphOptimizer::OptimizeLeftShiftBitAndSmiOp(
    Definition* bit_and_instr,
    Definition* left_instr,
    Definition* right_instr) {
  ASSERT(bit_and_instr != NULL);
  ASSERT((left_instr != NULL) && (right_instr != NULL));

  // Check for pattern, smi_shift_left must be single-use.
  bool is_positive_or_zero = IsPositiveOrZeroSmiConst(left_instr);
  if (!is_positive_or_zero) {
    is_positive_or_zero = IsPositiveOrZeroSmiConst(right_instr);
  }
  if (!is_positive_or_zero) return;

  BinarySmiOpInstr* smi_shift_left = NULL;
  if (bit_and_instr->InputAt(0)->IsSingleUse()) {
    smi_shift_left = AsSmiShiftLeftInstruction(left_instr);
  }
  if ((smi_shift_left == NULL) && (bit_and_instr->InputAt(1)->IsSingleUse())) {
    smi_shift_left = AsSmiShiftLeftInstruction(right_instr);
  }
  if (smi_shift_left == NULL) return;

  // Pattern recognized.
  smi_shift_left->set_is_truncating(true);
  ASSERT(bit_and_instr->IsBinarySmiOp() || bit_and_instr->IsBinaryMintOp());
  if (bit_and_instr->IsBinaryMintOp()) {
    // Replace Mint op with Smi op.
    BinarySmiOpInstr* smi_op = new BinarySmiOpInstr(
        Token::kBIT_AND,
        bit_and_instr->AsBinaryMintOp()->instance_call(),
        new Value(left_instr),
        new Value(right_instr));
    bit_and_instr->ReplaceWith(smi_op, current_iterator());
  }
}


// Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
// shift can be a truncating Smi shift-left and result is always Smi.
void FlowGraphOptimizer::TryOptimizeLeftShiftWithBitAndPattern() {
  if (!FLAG_truncating_left_shift) return;
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      if (it.Current()->IsBinarySmiOp()) {
        BinarySmiOpInstr* binop = it.Current()->AsBinarySmiOp();
        if (binop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(binop,
                                       binop->left()->definition(),
                                       binop->right()->definition());
        }
      } else if (it.Current()->IsBinaryMintOp()) {
        BinaryMintOpInstr* mintop = it.Current()->AsBinaryMintOp();
        if (mintop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(mintop,
                                       mintop->left()->definition(),
                                       mintop->right()->definition());
        }
      }
    }
    current_iterator_ = NULL;
  }
}


static void EnsureSSATempIndex(FlowGraph* graph,
                               Definition* defn,
                               Definition* replacement) {
  if ((replacement->ssa_temp_index() == -1) &&
      (defn->ssa_temp_index() != -1)) {
    replacement->set_ssa_temp_index(graph->alloc_ssa_temp_index());
  }
}


static void ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                      Instruction* current,
                                      Instruction* replacement,
                                      FlowGraph* graph) {
  Definition* current_defn = current->AsDefinition();
  if ((replacement != NULL) && (current_defn != NULL)) {
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != NULL);
    current_defn->ReplaceUsesWith(replacement_defn);
    EnsureSSATempIndex(graph, current_defn, replacement_defn);

    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    if (current_defn == NULL) {
      OS::Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      OS::Print("Removing v%"Pd".\n", current_defn->ssa_temp_index());
    }
  }
  iterator->RemoveCurrentFromGraph();
}


void FlowGraphOptimizer::Canonicalize() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      Instruction* replacement = current->Canonicalize(this);
      if (replacement != current) {
        // For non-definitions Canonicalize should return either NULL or
        // this.
        ASSERT((replacement == NULL) || current->IsDefinition());
        ReplaceCurrentInstruction(&it, current, replacement, flow_graph_);
      }
    }
  }
}


void FlowGraphOptimizer::InsertConversion(Representation from,
                                          Representation to,
                                          Value* use,
                                          Instruction* insert_before,
                                          Instruction* deopt_target) {
  Definition* converted = NULL;
  if ((from == kTagged) && (to == kUnboxedMint)) {
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kDoubleCid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new UnboxIntegerInstr(use->CopyWithType(), deopt_id);

  } else if ((from == kUnboxedMint) && (to == kTagged)) {
    converted = new BoxIntegerInstr(use->CopyWithType());

  } else if (from == kUnboxedMint && to == kUnboxedDouble) {
    // Convert by boxing/unboxing.
    // TODO(fschneider): Implement direct unboxed mint-to-double conversion.
    BoxIntegerInstr* boxed = new BoxIntegerInstr(use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, Definition::kValue);

    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new UnboxDoubleInstr(new Value(boxed), deopt_id);

  } else if ((from == kUnboxedDouble) && (to == kTagged)) {
    converted = new BoxDoubleInstr(use->CopyWithType());

  } else if ((from == kTagged) && (to == kUnboxedDouble)) {
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kDoubleCid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ConstantInstr* constant = use->definition()->AsConstant();
    if ((constant != NULL) && constant->value().IsSmi()) {
      const double dbl_val = Smi::Cast(constant->value()).AsDoubleValue();
      const Double& dbl_obj =
          Double::ZoneHandle(Double::New(dbl_val, Heap::kOld));
      ConstantInstr* double_const = new ConstantInstr(dbl_obj);
      InsertBefore(insert_before, double_const, NULL, Definition::kValue);
      converted = new UnboxDoubleInstr(new Value(double_const), deopt_id);
    } else {
      converted = new UnboxDoubleInstr(use->CopyWithType(), deopt_id);
    }
  } else if ((from == kTagged) && (to == kUnboxedFloat32x4)) {
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kFloat32x4Cid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new UnboxFloat32x4Instr(use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedFloat32x4) && (to == kTagged)) {
    converted = new BoxFloat32x4Instr(use->CopyWithType());
  }
  ASSERT(converted != NULL);
  use->BindTo(converted);
  InsertBefore(insert_before, converted, use->instruction()->env(),
               Definition::kValue);
}


void FlowGraphOptimizer::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  for (Value::Iterator it(def->input_use_list());
       !it.Done();
       it.Advance()) {
    Value* use = it.Current();
    const Representation to_rep =
        use->instruction()->RequiredInputRepresentation(use->use_index());
    if (from_rep == to_rep || to_rep == kNoRepresentation) {
      continue;
    }

    Instruction* insert_before;
    Instruction* deopt_target;
    PhiInstr* phi = use->instruction()->AsPhi();
    if (phi != NULL) {
      ASSERT(phi->is_alive());
      // For phis conversions have to be inserted in the predecessor.
      insert_before =
          phi->block()->PredecessorAt(use->use_index())->last_instruction();
      deopt_target = NULL;
    } else {
      deopt_target = insert_before = use->instruction();
    }

    InsertConversion(from_rep, to_rep, use, insert_before, deopt_target);
  }
}


void FlowGraphOptimizer::SelectRepresentations() {
  // Convervatively unbox all phis that were proven to be of type Double.
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    JoinEntryInstr* join_entry = block_order_[i]->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        if (phi->Type()->ToCid() == kDoubleCid) {
          phi->set_representation(kUnboxedDouble);
        }
      }
    }
  }

  // Process all instructions and insert conversions where needed.
  GraphEntryInstr* graph_entry = block_order_[0]->AsGraphEntry();

  // Visit incoming parameters and constants.
  for (intptr_t i = 0; i < graph_entry->initial_definitions()->length(); i++) {
    InsertConversionsFor((*graph_entry->initial_definitions())[i]);
  }

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    JoinEntryInstr* join_entry = entry->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        ASSERT(phi->is_alive());
        InsertConversionsFor(phi);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* def = it.Current()->AsDefinition();
      if (def != NULL) {
        InsertConversionsFor(def);
      }
    }
  }
}


static bool ICDataHasReceiverArgumentClassIds(const ICData& ic_data,
                                              intptr_t receiver_class_id,
                                              intptr_t argument_class_id) {
  ASSERT(receiver_class_id != kIllegalCid);
  ASSERT(argument_class_id != kIllegalCid);
  if (ic_data.num_args_tested() != 2) return false;

  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
    ASSERT(class_ids.length() == 2);
    if ((class_ids[0] == receiver_class_id) &&
        (class_ids[1] == argument_class_id)) {
      return true;
    }
  }
  return false;
}


static bool ClassIdIsOneOf(intptr_t class_id,
                           const GrowableArray<intptr_t>& class_ids) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    if (class_ids[i] == class_id) {
      return true;
    }
  }
  return false;
}


// Returns true if ICData tests two arguments and all ICData cids are in the
// required sets 'receiver_class_ids' or 'argument_class_ids', respectively.
static bool ICDataHasOnlyReceiverArgumentClassIds(
    const ICData& ic_data,
    const GrowableArray<intptr_t>& receiver_class_ids,
    const GrowableArray<intptr_t>& argument_class_ids) {
  if (ic_data.num_args_tested() != 2) return false;
  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
    ASSERT(class_ids.length() == 2);
    if (!ClassIdIsOneOf(class_ids[0], receiver_class_ids) ||
        !ClassIdIsOneOf(class_ids[1], argument_class_ids)) {
      return false;
    }
  }
  return true;
}


static bool HasOnlyOneSmi(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1)
      && ic_data.HasReceiverClassId(kSmiCid);
}


static bool HasOnlySmiOrMint(const ICData& ic_data) {
  if (ic_data.NumberOfChecks() == 1) {
    return ic_data.HasReceiverClassId(kSmiCid)
        || ic_data.HasReceiverClassId(kMintCid);
  }
  return (ic_data.NumberOfChecks() == 2)
      && ic_data.HasReceiverClassId(kSmiCid)
      && ic_data.HasReceiverClassId(kMintCid);
}


static bool HasOnlyTwoSmis(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1) &&
      ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid);
}

static bool HasOnlyTwoFloat32x4s(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1) &&
      ICDataHasReceiverArgumentClassIds(ic_data, kFloat32x4Cid, kFloat32x4Cid);
}


// Returns false if the ICData contains anything other than the 4 combinations
// of Mint and Smi for the receiver and argument classes.
static bool HasTwoMintOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kMintCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}


static bool HasOnlyOneDouble(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1)
      && ic_data.HasReceiverClassId(kDoubleCid);
}


static bool ShouldSpecializeForDouble(const ICData& ic_data) {
  // Unboxed double operation can't handle case of two smis.
  if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
    return false;
  }

  // Check that it have seen only smis and doubles.
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kDoubleCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}


void FlowGraphOptimizer::ReplaceCall(Definition* call,
                                     Definition* replacement) {
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  call->ReplaceWith(replacement, current_iterator());
}


static intptr_t ReceiverClassId(InstanceCallInstr* call) {
  if (!call->HasICData()) return kIllegalCid;

  const ICData& ic_data = ICData::Handle(call->ic_data()->AsUnaryClassChecks());

  if (ic_data.NumberOfChecks() == 0) return kIllegalCid;
  // TODO(vegorov): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return kIllegalCid;
  ASSERT(ic_data.HasOneTarget());

  Function& target = Function::Handle();
  intptr_t class_id;
  ic_data.GetOneClassCheckAt(0, &class_id, &target);
  return class_id;
}


void FlowGraphOptimizer::AddCheckSmi(Definition* to_check,
                                     intptr_t deopt_id,
                                     Environment* deopt_environment,
                                     Instruction* insert_before) {
  if (to_check->Type()->ToCid() != kSmiCid) {
    InsertBefore(insert_before,
                 new CheckSmiInstr(new Value(to_check), deopt_id),
                 deopt_environment,
                 Definition::kEffect);
  }
}


void FlowGraphOptimizer::AddCheckClass(Definition* to_check,
                                       const ICData& unary_checks,
                                       intptr_t deopt_id,
                                       Environment* deopt_environment,
                                       Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = NULL;
  if ((unary_checks.NumberOfChecks() == 1) &&
      (unary_checks.GetReceiverClassIdAt(0) == kSmiCid)) {
    check = new CheckSmiInstr(new Value(to_check), deopt_id);
  } else {
    check = new CheckClassInstr(new Value(to_check), deopt_id, unary_checks);
  }
  InsertBefore(insert_before, check, deopt_environment, Definition::kEffect);
}


void FlowGraphOptimizer::AddReceiverCheck(InstanceCallInstr* call) {
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(call->ic_data()->AsUnaryClassChecks()),
                call->deopt_id(),
                call->env(),
                call);
}


static bool ArgIsAlwaysSmi(const ICData& ic_data, intptr_t arg_n) {
  ASSERT(ic_data.num_args_tested() > arg_n);
  if (ic_data.NumberOfChecks() == 0) return false;
  GrowableArray<intptr_t> class_ids;
  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    ic_data.GetCheckAt(i, &class_ids, &target);
    if (class_ids[arg_n] != kSmiCid) return false;
  }
  return true;
}


// Returns array classid to load from, array and index value

intptr_t FlowGraphOptimizer::PrepareIndexedOp(InstanceCallInstr* call,
                                              intptr_t class_id,
                                              Definition** array,
                                              Definition** index) {
  // Insert class check and index smi checks and attach a copy of the
  // original environment because the operation can still deoptimize.
  AddReceiverCheck(call);
  InsertBefore(call,
               new CheckSmiInstr(new Value(*index), call->deopt_id()),
               call->env(),
               Definition::kEffect);

  // If both index and array are constants, then do a compile-time check.
  // TODO(srdjan): Remove once constant propagation handles bounds checks.
  bool skip_check = false;
  if ((*array)->IsConstant() && (*index)->IsConstant()) {
    const ImmutableArray& constant_array =
        ImmutableArray::Cast((*array)->AsConstant()->value());
    const Object& constant_index = (*index)->AsConstant()->value();
      skip_check = constant_index.IsSmi() &&
          (Smi::Cast(constant_index).Value() < constant_array.Length());
  }
  if (!skip_check) {
    // Insert array length load and bounds check.
    const bool is_immutable =
        CheckArrayBoundInstr::IsFixedLengthArrayType(class_id);
    LoadFieldInstr* length =
        new LoadFieldInstr(new Value(*array),
                           CheckArrayBoundInstr::LengthOffsetFor(class_id),
                           Type::ZoneHandle(Type::SmiType()),
                           is_immutable);
    length->set_result_cid(kSmiCid);
    length->set_recognized_kind(
        LoadFieldInstr::RecognizedKindFromArrayCid(class_id));
    InsertBefore(call, length, NULL, Definition::kValue);

    InsertBefore(call,
                 new CheckArrayBoundInstr(new Value(length),
                                          new Value(*index),
                                          class_id,
                                          call),
                 call->env(),
                 Definition::kEffect);
  }
  if (class_id == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements =
        new LoadFieldInstr(new Value(*array),
                           GrowableObjectArray::data_offset(),
                           Type::ZoneHandle(Type::DynamicType()));
    elements->set_result_cid(kArrayCid);
    InsertBefore(call, elements, NULL, Definition::kValue);
    *array = elements;
    return kArrayCid;
  }
  if (RawObject::IsExternalTypedDataClassId(class_id)) {
    LoadUntaggedInstr* elements =
        new LoadUntaggedInstr(new Value(*array),
                              ExternalTypedData::data_offset());
    InsertBefore(call, elements, NULL, Definition::kValue);
    *array = elements;
  }
  return class_id;
}


static bool CanUnboxInt32() {
  // Int32/Uint32 can be unboxed if it fits into a smi or the platform
  // supports unboxed mints.
  return (kSmiBits >= 32) || FlowGraphCompiler::SupportsUnboxedMints();
}


bool FlowGraphOptimizer::TryReplaceWithStoreIndexed(InstanceCallInstr* call) {
  const intptr_t class_id = ReceiverClassId(call);
  ICData& value_check = ICData::ZoneHandle();
  switch (class_id) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
      if (ArgIsAlwaysSmi(*call->ic_data(), 2)) {
        value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Check that value is always smi.
      value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      if ((value_check.NumberOfChecks() != 1) ||
          (value_check.GetReceiverClassIdAt(0) != kSmiCid)) {
        return false;
      }
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (!CanUnboxInt32()) return false;
      // Check that value is always smi or mint, if the platform has unboxed
      // mints (ia32 with at least SSE 4.1).
      value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      for (intptr_t i = 0; i < value_check.NumberOfChecks(); i++) {
        intptr_t cid = value_check.GetReceiverClassIdAt(i);
        if (FlowGraphCompiler::SupportsUnboxedMints()) {
          if ((cid != kSmiCid) && (cid != kMintCid)) {
            return false;
          }
        } else if (cid != kSmiCid) {
          return false;
        }
      }
      break;
    }
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid: {
      // Check that value is always double.
      value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      if ((value_check.NumberOfChecks() != 1) ||
          (value_check.GetReceiverClassIdAt(0) != kDoubleCid)) {
        return false;
      }
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always a Float32x4.
      value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      if ((value_check.NumberOfChecks() != 1) ||
          (value_check.GetReceiverClassIdAt(0) != kFloat32x4Cid)) {
          return false;
      }
    }
    break;
    default:
      // TODO(fschneider): Add support for other array types.
      return false;
  }

  BuildStoreIndexed(call, value_check, class_id);
  return true;
}


void FlowGraphOptimizer::BuildStoreIndexed(InstanceCallInstr* call,
                                           const ICData& value_check,
                                           intptr_t class_id) {
  Definition* array = call->ArgumentAt(0);
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);
  if (FLAG_enable_type_checks) {
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const Function& target =
        Function::ZoneHandle(call->ic_data()->GetTargetAt(0));
    const AbstractType& value_type =
        AbstractType::ZoneHandle(target.ParameterTypeAt(2));
    Definition* instantiator = NULL;
    Definition* type_args = NULL;
    switch (class_id) {
      case kArrayCid:
      case kGrowableObjectArrayCid: {
        const Class& instantiator_class = Class::Handle(target.Owner());
        intptr_t type_arguments_field_offset =
            instantiator_class.type_arguments_field_offset();
        LoadFieldInstr* load_type_args =
            new LoadFieldInstr(new Value(array),
                               type_arguments_field_offset,
                               Type::ZoneHandle());  // No type.
        InsertBefore(call, load_type_args, NULL, Definition::kValue);
        instantiator = array;
        type_args = load_type_args;
        break;
      }
      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
        ASSERT(value_type.IsIntType());
        // Fall through.
      case kTypedDataFloat32ArrayCid:
      case kTypedDataFloat64ArrayCid: {
        type_args = instantiator = flow_graph_->constant_null();
        ASSERT((class_id != kTypedDataFloat32ArrayCid &&
                class_id != kTypedDataFloat64ArrayCid) ||
               value_type.IsDoubleType());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat32x4ArrayCid: {
        type_args = instantiator = flow_graph_->constant_null();
        ASSERT((class_id != kTypedDataFloat32x4ArrayCid) ||
               value_type.IsFloat32x4Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      default:
        // TODO(fschneider): Add support for other array types.
        UNREACHABLE();
    }
    AssertAssignableInstr* assert_value =
        new AssertAssignableInstr(call->token_pos(),
                                  new Value(stored_value),
                                  new Value(instantiator),
                                  new Value(type_args),
                                  value_type,
                                  Symbols::Value());
    // Newly inserted instructions that can deoptimize or throw an exception
    // must have a deoptimization id that is valid for lookup in the unoptimized
    // code.
    assert_value->deopt_id_ = call->deopt_id();
    InsertBefore(call, assert_value, call->env(), Definition::kValue);
  }

  intptr_t array_cid = PrepareIndexedOp(call, class_id, &array, &index);
  // Check if store barrier is needed. Byte arrays don't need a store barrier.
  StoreBarrierType needs_store_barrier =
      (RawObject::IsTypedDataClassId(array_cid) ||
       RawObject::IsTypedDataViewClassId(array_cid) ||
       RawObject::IsExternalTypedDataClassId(array_cid)) ? kNoStoreBarrier
                                                         : kEmitStoreBarrier;
  if (!value_check.IsNull()) {
    // No store barrier needed because checked value is a smi, an unboxed mint,
    // an unboxed double, an unboxed Float32x4, or unboxed Uint32x4.
    needs_store_barrier = kNoStoreBarrier;
    AddCheckClass(stored_value, value_check, call->deopt_id(), call->env(),
                  call);
  }

  intptr_t index_scale = FlowGraphCompiler::ElementSizeFor(array_cid);
  Definition* array_op = new StoreIndexedInstr(new Value(array),
                                               new Value(index),
                                               new Value(stored_value),
                                               needs_store_barrier,
                                               index_scale,
                                               array_cid,
                                               call->deopt_id());
  ReplaceCall(call, array_op);
}



bool FlowGraphOptimizer::TryReplaceWithLoadIndexed(InstanceCallInstr* call) {
  const intptr_t class_id = ReceiverClassId(call);
  // Set deopt_id to a valid id if the LoadIndexedInstr can cause deopt.
  intptr_t deopt_id = Isolate::kNoDeoptId;
  switch (class_id) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kGrowableObjectArrayCid:
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
        if (!CanUnboxInt32()) return false;

        // Set deopt_id if we can optimistically assume that the result is Smi.
        // Assume mixed Mint/Smi if this instruction caused deoptimization once.
        ASSERT(call->HasICData());
        const ICData& ic_data = *call->ic_data();
        deopt_id = (ic_data.deopt_reason() == kDeoptUnknown) ?
            call->deopt_id() : Isolate::kNoDeoptId;
      }
      break;
    default:
      return false;
  }
  Definition* array = call->ArgumentAt(0);
  Definition* index = call->ArgumentAt(1);
  intptr_t array_cid = PrepareIndexedOp(call, class_id, &array, &index);
  intptr_t index_scale = FlowGraphCompiler::ElementSizeFor(array_cid);
  Definition* array_op =
      new LoadIndexedInstr(new Value(array),
                           new Value(index),
                           index_scale,
                           array_cid,
                           deopt_id);
  ReplaceCall(call, array_op);
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
                                                Token::Kind op_kind) {
  intptr_t operands_type = kIllegalCid;
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
      if (HasOnlyTwoSmis(ic_data)) {
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        operands_type = (ic_data.deopt_reason() == kDeoptBinarySmiOp)
            ? kMintCid
            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 FlowGraphCompiler::SupportsUnboxedMints()) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.deopt_reason() == kDeoptBinaryMintOp) return false;
        operands_type = kMintCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoFloat32x4s(ic_data)) {
        operands_type = kFloat32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kMUL:
      if (HasOnlyTwoSmis(ic_data)) {
        // Don't generate smi code if the IC data is marked because of an
        // overflow.
        // TODO(fschneider): Add unboxed mint multiplication.
        if (ic_data.deopt_reason() == kDeoptBinarySmiOp) return false;
        operands_type = kSmiCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoFloat32x4s(ic_data)) {
        operands_type = kFloat32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoFloat32x4s(ic_data)) {
        operands_type = kFloat32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kMOD:
      if (HasOnlyTwoSmis(ic_data)) {
        operands_type = kSmiCid;
      } else {
        return false;
      }
      break;
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      if (HasOnlyTwoSmis(ic_data)) {
        operands_type = kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data)) {
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kSHR:
    case Token::kSHL:
      if (HasOnlyTwoSmis(ic_data)) {
        // Left shift may overflow from smi into mint or big ints.
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        if (ic_data.deopt_reason() == kDeoptShiftMintOp) return false;
        operands_type = (ic_data.deopt_reason() == kDeoptBinarySmiOp)
            ? kMintCid
            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 HasOnlyOneSmi(ICData::Handle(
                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.deopt_reason() == kDeoptShiftMintOp) return false;
        // Check for smi/mint << smi or smi/mint >> smi.
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kTRUNCDIV:
      if (HasOnlyTwoSmis(ic_data)) {
        if (ic_data.deopt_reason() == kDeoptBinarySmiOp) return false;
        operands_type = kSmiCid;
      } else {
        return false;
      }
      break;
    default:
      UNREACHABLE();
  }

  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  if (operands_type == kDoubleCid) {
    // Check that either left or right are not a smi.  Result of a
    // binary operation with two smis is a smi not a double.
    InsertBefore(call,
                 new CheckEitherNonSmiInstr(new Value(left),
                                            new Value(right),
                                            call),
                 call->env(),
                 Definition::kEffect);

    BinaryDoubleOpInstr* double_bin_op =
        new BinaryDoubleOpInstr(op_kind, new Value(left), new Value(right),
                                call);
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    if (!FlowGraphCompiler::SupportsUnboxedMints()) return false;
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      ShiftMintOpInstr* shift_op =
          new ShiftMintOpInstr(op_kind, new Value(left), new Value(right),
                               call);
      ReplaceCall(call, shift_op);
    } else {
      BinaryMintOpInstr* bin_op =
          new BinaryMintOpInstr(op_kind, new Value(left), new Value(right),
                                call);
      ReplaceCall(call, bin_op);
    }
  } else if (operands_type == kFloat32x4Cid) {
    // Type check left.
    AddCheckClass(left,
                  ICData::ZoneHandle(
                      call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                  call->deopt_id(),
                  call->env(),
                  call);
    // Type check right.
    AddCheckClass(right,
                  ICData::ZoneHandle(
                      call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                  call->deopt_id(),
                  call->env(),
                  call);
    // Replace call.
    BinaryFloat32x4OpInstr* float32x4_bin_op =
        new BinaryFloat32x4OpInstr(op_kind, new Value(left), new Value(right),
                                   call);
    ReplaceCall(call, float32x4_bin_op);
  } else if (op_kind == Token::kMOD) {
    // TODO(vegorov): implement fast path code for modulo.
    ASSERT(operands_type == kSmiCid);
    if (!right->IsConstant()) return false;
    const Object& obj = right->AsConstant()->value();
    if (!obj.IsSmi()) return false;
    const intptr_t value = Smi::Cast(obj).Value();
    if ((value <= 0) || !Utils::IsPowerOfTwo(value)) return false;

    // Insert smi check and attach a copy of the original environment
    // because the smi operation can still deoptimize.
    InsertBefore(call,
                 new CheckSmiInstr(new Value(left), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    ConstantInstr* constant =
        new ConstantInstr(Smi::Handle(Smi::New(value - 1)));
    InsertBefore(call, constant, NULL, Definition::kValue);
    BinarySmiOpInstr* bin_op =
        new BinarySmiOpInstr(Token::kBIT_AND, call,
                             new Value(left),
                             new Value(constant));
    ReplaceCall(call, bin_op);
  } else {
    ASSERT(operands_type == kSmiCid);
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    if (left->IsConstant() &&
        ((op_kind == Token::kADD) || (op_kind == Token::kMUL))) {
      // Constant should be on the right side.
      Definition* temp = left;
      left = right;
      right = temp;
    }
    BinarySmiOpInstr* bin_op =
        new BinarySmiOpInstr(op_kind, call, new Value(left), new Value(right));
    ReplaceCall(call, bin_op);
  }
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  ASSERT(call->ArgumentCount() == 1);
  Definition* input = call->ArgumentAt(0);
  Definition* unary_op = NULL;
  if (HasOnlyOneSmi(*call->ic_data())) {
    InsertBefore(call,
                 new CheckSmiInstr(new Value(input), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    unary_op = new UnarySmiOpInstr(op_kind, call, new Value(input));
  } else if ((op_kind == Token::kBIT_NOT) &&
             HasOnlySmiOrMint(*call->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    unary_op = new UnaryMintOpInstr(op_kind, new Value(input), call);
  } else if (HasOnlyOneDouble(*call->ic_data()) &&
             (op_kind == Token::kNEGATE)) {
    AddReceiverCheck(call);
    ConstantInstr* minus_one =
        new ConstantInstr(Double::ZoneHandle(Double::NewCanonical(-1)));
    InsertBefore(call, minus_one, NULL, Definition::kValue);
    unary_op = new BinaryDoubleOpInstr(Token::kMUL,
                                       new Value(input),
                                       new Value(minus_one),
                                       call);
  }
  if (unary_op == NULL) return false;

  ReplaceCall(call, unary_op);
  return true;
}


// Using field class
static RawField* GetField(intptr_t class_id, const String& field_name) {
  Class& cls = Class::Handle(Isolate::Current()->class_table()->At(class_id));
  Field& field = Field::Handle();
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      return field.raw();
    }
    cls = cls.SuperClass();
  }
  return Field::null();
}


// Use CHA to determine if the call needs a class check: if the callee's
// receiver is the same as the caller's receiver and there are no overriden
// callee functions, then no class check is needed.
bool FlowGraphOptimizer::InstanceCallNeedsClassCheck(
    InstanceCallInstr* call) const {
  if (!FLAG_use_cha) return true;
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->parsed_function().function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    return CHA::HasOverride(Class::Handle(function.Owner()),
                            call->function_name());
  }
  return true;
}


bool FlowGraphOptimizer::MethodExtractorNeedsClassCheck(
    InstanceCallInstr* call) const {
  if (!FLAG_use_cha) return true;
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->parsed_function().function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    const String& field_name =
      String::Handle(Field::NameFromGetter(call->function_name()));
    return CHA::HasOverride(Class::Handle(function.Owner()), field_name);
  }
  return true;
}


void FlowGraphOptimizer::AddToGuardedFields(Field* field) {
  if ((field->guarded_cid() == kDynamicCid) ||
      (field->guarded_cid() == kIllegalCid)) {
    return;
  }
  for (intptr_t j = 0; j < guarded_fields_->length(); j++) {
    if ((*guarded_fields_)[j]->raw() == field->raw()) {
      return;
    }
  }
  guarded_fields_->Add(field);
}


void FlowGraphOptimizer::InlineImplicitInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  ASSERT(class_ids.length() == 1);
  // Inline implicit instance getter.
  const String& field_name =
      String::Handle(Field::NameFromGetter(call->function_name()));
  const Field& field = Field::Handle(GetField(class_ids[0], field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(call)) {
    AddReceiverCheck(call);
  }
  LoadFieldInstr* load = new LoadFieldInstr(
      new Value(call->ArgumentAt(0)),
      field.Offset(),
      AbstractType::ZoneHandle(field.type()),
      field.is_final());
  if (field.guarded_cid() != kIllegalCid) {
    if (!field.is_nullable() || (field.guarded_cid() == kNullCid)) {
      load->set_result_cid(field.guarded_cid());
    }
    Field* the_field = &Field::ZoneHandle(field.raw());
    load->set_field(the_field);
    AddToGuardedFields(the_field);
  }
  load->set_field_name(String::Handle(field.name()).ToCString());

  // Discard the environment from the original instruction because the load
  // can't deoptimize.
  call->RemoveEnvironment();
  ReplaceCall(call, load);

  if (load->result_cid() != kDynamicCid) {
    // Reset value types if guarded_cid was used.
    for (Value::Iterator it(load->input_use_list());
         !it.Done();
         it.Advance()) {
      it.Current()->SetReachingType(NULL);
    }
  }
}


void FlowGraphOptimizer::InlineArrayLengthGetter(InstanceCallInstr* call,
                                                 intptr_t length_offset,
                                                 bool is_immutable,
                                                 MethodRecognizer::Kind kind) {
  AddReceiverCheck(call);

  LoadFieldInstr* load = new LoadFieldInstr(
      new Value(call->ArgumentAt(0)),
      length_offset,
      Type::ZoneHandle(Type::SmiType()),
      is_immutable);
  load->set_result_cid(kSmiCid);
  load->set_recognized_kind(kind);
  ReplaceCall(call, load);
}


void FlowGraphOptimizer::InlineGrowableArrayCapacityGetter(
    InstanceCallInstr* call) {
  AddReceiverCheck(call);

  // TODO(srdjan): type of load should be GrowableObjectArrayType.
  LoadFieldInstr* data_load = new LoadFieldInstr(
      new Value(call->ArgumentAt(0)),
      Array::data_offset(),
      Type::ZoneHandle(Type::DynamicType()));
  data_load->set_result_cid(kArrayCid);
  InsertBefore(call, data_load, NULL, Definition::kValue);

  LoadFieldInstr* length_load = new LoadFieldInstr(
      new Value(data_load),
      Array::length_offset(),
      Type::ZoneHandle(Type::SmiType()));
  length_load->set_result_cid(kSmiCid);
  length_load->set_recognized_kind(MethodRecognizer::kObjectArrayLength);

  ReplaceCall(call, length_load);
}


static LoadFieldInstr* BuildLoadStringLength(Definition* str) {
  // Treat length loads as mutable (i.e. affected by side effects) to avoid
  // hoisting them since we can't hoist the preceding class-check. This
  // is because of externalization of strings that affects their class-id.
  const bool is_immutable = false;
  LoadFieldInstr* load = new LoadFieldInstr(
      new Value(str),
      String::length_offset(),
      Type::ZoneHandle(Type::SmiType()),
      is_immutable);
  load->set_result_cid(kSmiCid);
  load->set_recognized_kind(MethodRecognizer::kStringBaseLength);
  return load;
}


void FlowGraphOptimizer::InlineStringLengthGetter(InstanceCallInstr* call) {
  AddReceiverCheck(call);
  LoadFieldInstr* load = BuildLoadStringLength(call->ArgumentAt(0));
  ReplaceCall(call, load);
}


void FlowGraphOptimizer::InlineStringIsEmptyGetter(InstanceCallInstr* call) {
  AddReceiverCheck(call);

  LoadFieldInstr* load = BuildLoadStringLength(call->ArgumentAt(0));
  InsertBefore(call, load, NULL, Definition::kValue);

  ConstantInstr* zero = new ConstantInstr(Smi::Handle(Smi::New(0)));
  InsertBefore(call, zero, NULL, Definition::kValue);

  StrictCompareInstr* compare =
      new StrictCompareInstr(Token::kEQ_STRICT,
                             new Value(load),
                             new Value(zero));
  ReplaceCall(call, compare);
}


static intptr_t OffsetForLengthGetter(MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
      return Array::length_offset();
    case MethodRecognizer::kTypedDataLength:
      // .length is defined in _TypedList which is the base class for internal
      // and external typed data.
      ASSERT(TypedData::length_offset() == ExternalTypedData::length_offset());
      return TypedData::length_offset();
    case MethodRecognizer::kGrowableArrayLength:
      return GrowableObjectArray::length_offset();
    default:
      UNREACHABLE();
      return 0;
  }
}


// Only unique implicit instance getters can be currently handled.
bool FlowGraphOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }
  Function& target = Function::Handle(ic_data.GetTargetAt(0));
  if (target.kind() == RawFunction::kImplicitGetter) {
    if (!ic_data.HasOneTarget()) {
      // TODO(srdjan): Implement for mutiple targets.
      return false;
    }
    InlineImplicitInstanceGetter(call);
    return true;
  } else if (target.kind() == RawFunction::kMethodExtractor) {
    return false;
  }

  // Not an implicit getter.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  // VM objects length getter.
  switch (recognized_kind) {
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
    case MethodRecognizer::kTypedDataLength:
    case MethodRecognizer::kGrowableArrayLength: {
      if (!ic_data.HasOneTarget()) {
        // TODO(srdjan): Implement for mutiple targets.
        return false;
      }
      const bool is_immutable =
          (recognized_kind == MethodRecognizer::kObjectArrayLength) ||
          (recognized_kind == MethodRecognizer::kImmutableArrayLength) ||
          (recognized_kind == MethodRecognizer::kTypedDataLength);
      InlineArrayLengthGetter(call,
                              OffsetForLengthGetter(recognized_kind),
                              is_immutable,
                              recognized_kind);
      return true;
    }
    case MethodRecognizer::kGrowableArrayCapacity:
      InlineGrowableArrayCapacityGetter(call);
      return true;
    case MethodRecognizer::kStringBaseLength:
      if (!ic_data.HasOneTarget()) {
        // Target is not only StringBase_get_length.
        return false;
      }
      InlineStringLengthGetter(call);
      return true;
    case MethodRecognizer::kStringBaseIsEmpty:
      if (!ic_data.HasOneTarget()) {
        // Target is not only StringBase_get_isEmpty.
        return false;
      }
      InlineStringIsEmptyGetter(call);
      return true;
    default:
      ASSERT(recognized_kind == MethodRecognizer::kUnknown);
  }
  return false;
}


LoadIndexedInstr* FlowGraphOptimizer::BuildStringCodeUnitAt(
    InstanceCallInstr* call,
    intptr_t cid) {
  Definition* str = call->ArgumentAt(0);
  Definition* index = call->ArgumentAt(1);
  AddReceiverCheck(call);
  InsertBefore(call,
               new CheckSmiInstr(new Value(index), call->deopt_id()),
               call->env(),
               Definition::kEffect);
  // If both index and string are constants, then do a compile-time check.
  // TODO(srdjan): Remove once constant propagation handles bounds checks.
  bool skip_check = false;
  if (str->IsConstant() && index->IsConstant()) {
    const String& constant_string =
        String::Cast(str->AsConstant()->value());
    const Object& constant_index = index->AsConstant()->value();
    skip_check = constant_index.IsSmi() &&
        (Smi::Cast(constant_index).Value() < constant_string.Length());
  }
  if (!skip_check) {
    // Insert bounds check.
    LoadFieldInstr* length = BuildLoadStringLength(str);
    InsertBefore(call, length, NULL, Definition::kValue);
    InsertBefore(call,
                 new CheckArrayBoundInstr(new Value(length),
                                          new Value(index),
                                          cid,
                                          call),
                 call->env(),
                 Definition::kEffect);
  }
  return new LoadIndexedInstr(new Value(str),
                              new Value(index),
                              FlowGraphCompiler::ElementSizeFor(cid),
                              cid,
                              Isolate::kNoDeoptId);  // Can't deoptimize.
}


void FlowGraphOptimizer::ReplaceWithMathCFunction(
  InstanceCallInstr* call,
  MethodRecognizer::Kind recognized_kind) {
  AddReceiverCheck(call);
  ZoneGrowableArray<Value*>* args =
      new ZoneGrowableArray<Value*>(call->ArgumentCount());
  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    args->Add(new Value(call->ArgumentAt(i)));
  }
  InvokeMathCFunctionInstr* invoke =
      new InvokeMathCFunctionInstr(args, call, recognized_kind);
  ReplaceCall(call, invoke);
}


static bool IsSupportedByteArrayViewCid(intptr_t cid) {
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      return true;
    default:
      return false;
  }
}


// Inline only simple, frequently called core library methods.
bool FlowGraphOptimizer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if ((ic_data.NumberOfChecks() == 0) || !ic_data.HasOneTarget()) {
    // No type feedback collected or multiple targets found.
    return false;
  }

  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  if ((recognized_kind == MethodRecognizer::kStringBaseCodeUnitAt) &&
      (ic_data.NumberOfChecks() == 1) &&
      ((class_ids[0] == kOneByteStringCid) ||
       (class_ids[0] == kTwoByteStringCid))) {
    LoadIndexedInstr* instr = BuildStringCodeUnitAt(call, class_ids[0]);
    ReplaceCall(call, instr);
    return true;
  }
  if ((recognized_kind == MethodRecognizer::kStringBaseCharAt) &&
      (ic_data.NumberOfChecks() == 1) &&
      (class_ids[0] == kOneByteStringCid)) {
    // TODO(fschneider): Handle TwoByteString.
    LoadIndexedInstr* load_char_code =
        BuildStringCodeUnitAt(call, class_ids[0]);
    InsertBefore(call, load_char_code, NULL, Definition::kValue);
    StringFromCharCodeInstr* char_at =
        new StringFromCharCodeInstr(new Value(load_char_code),
                                    kOneByteStringCid);
    ReplaceCall(call, char_at);
    return true;
  }

  if ((recognized_kind == MethodRecognizer::kIntegerToDouble) &&
      (class_ids[0] == kSmiCid)) {
    SmiToDoubleInstr* s2d_instr = new SmiToDoubleInstr(call);
    call->ReplaceWith(s2d_instr, current_iterator());
    // Pushed arguments are not removed because SmiToDouble is implemented
    // as a call.
    return true;
  }

  if (class_ids[0] == kDoubleCid) {
    switch (recognized_kind) {
      case MethodRecognizer::kDoubleToInteger: {
        AddReceiverCheck(call);
        ASSERT(call->HasICData());
        const ICData& ic_data = *call->ic_data();
        Definition* input = call->ArgumentAt(0);
        Definition* d2i_instr = NULL;
        if (ic_data.deopt_reason() == kDeoptDoubleToSmi) {
          // Do not repeatedly deoptimize because result didn't fit into Smi.
          d2i_instr = new DoubleToIntegerInstr(new Value(input), call);
        } else {
          // Optimistically assume result fits into Smi.
          d2i_instr = new DoubleToSmiInstr(new Value(input), call);
        }
        ReplaceCall(call, d2i_instr);
        return true;
      }
      case MethodRecognizer::kDoubleMod:
      case MethodRecognizer::kDoublePow:
      case MethodRecognizer::kDoubleRound:
        ReplaceWithMathCFunction(call, recognized_kind);
        return true;
      case MethodRecognizer::kDoubleTruncate:
      case MethodRecognizer::kDoubleFloor:
      case MethodRecognizer::kDoubleCeil:
        if (!CPUFeatures::double_truncate_round_supported()) {
          ReplaceWithMathCFunction(call, recognized_kind);
        } else {
          AddReceiverCheck(call);
          DoubleToDoubleInstr* d2d_instr =
              new DoubleToDoubleInstr(new Value(call->ArgumentAt(0)),
                                      call,
                                      recognized_kind);
          ReplaceCall(call, d2d_instr);
        }
        return true;
      default:
        // Unsupported method.
        return false;
    }
  }

  if (IsSupportedByteArrayViewCid(class_ids[0]) &&
      (ic_data.NumberOfChecks() == 1)) {
    // For elements that may not fit into a smi on all platforms, check if
    // elements fit into a smi or the platform supports unboxed mints.
    if ((recognized_kind == MethodRecognizer::kByteArrayBaseGetInt32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseGetUint32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetInt32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetUint32)) {
      if (!CanUnboxInt32()) return false;
    }

    switch (recognized_kind) {
      // ByteArray getters.
      case MethodRecognizer::kByteArrayBaseGetInt8:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint8:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt16:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint16:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt32:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint32:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat64:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32x4:
        return BuildByteArrayViewLoad(
            call, class_ids[0], kTypedDataFloat32x4ArrayCid);

      // ByteArray setters.
      case MethodRecognizer::kByteArrayBaseSetInt8:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint8:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt16:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint16:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt32:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint32:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat64:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32x4:
        return BuildByteArrayViewStore(
            call, class_ids[0], kTypedDataFloat32x4ArrayCid);
      default:
        // Unsupported method.
        return false;
    }
  }
  return false;
}


bool FlowGraphOptimizer::BuildByteArrayViewLoad(
    InstanceCallInstr* call,
    intptr_t receiver_cid,
    intptr_t view_cid) {
  Definition* array = call->ArgumentAt(0);
  PrepareByteArrayViewOp(call, receiver_cid, view_cid, &array);

  // Optimistically build a smi-checked load for Int32 and Uint32
  // loads on ia32 like we do for normal array loads, and only revert to
  // mint case after deoptimizing here.
  intptr_t deopt_id = Isolate::kNoDeoptId;
  if ((view_cid == kTypedDataInt32ArrayCid ||
       view_cid == kTypedDataUint32ArrayCid) &&
      call->ic_data()->deopt_reason() == kDeoptUnknown) {
    deopt_id = call->deopt_id();
  }
  Definition* byte_index = call->ArgumentAt(1);
  LoadIndexedInstr* array_op = new LoadIndexedInstr(new Value(array),
                                                    new Value(byte_index),
                                                    1,  // Index scale.
                                                    view_cid,
                                                    deopt_id);
  ReplaceCall(call, array_op);
  return true;
}


bool FlowGraphOptimizer::BuildByteArrayViewStore(
    InstanceCallInstr* call,
    intptr_t receiver_cid,
    intptr_t view_cid) {
  Definition* array = call->ArgumentAt(0);
  PrepareByteArrayViewOp(call, receiver_cid, view_cid, &array);
  ICData& value_check = ICData::ZoneHandle();
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      // Check that value is always smi.
      value_check = ICData::New(Function::Handle(),
                                String::Handle(),
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kSmiCid, Function::Handle());
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // We don't have ICData for the value stored, so we optimistically assume
      // smis first. If we ever deoptimized here, we require to unbox the value
      // before storing to handle the mint case, too.
      if (call->ic_data()->deopt_reason() == kDeoptUnknown) {
        value_check = ICData::New(Function::Handle(),
                                  String::Handle(),
                                  Isolate::kNoDeoptId,
                                  1);
        value_check.AddReceiverCheck(kSmiCid, Function::Handle());
      }
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid: {
      // Check that value is always double.
      value_check = ICData::New(Function::Handle(),
                                String::Handle(),
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kDoubleCid, Function::Handle());
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always Float32x4.
      value_check = ICData::New(Function::Handle(),
                                String::Handle(),
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kFloat32x4Cid, Function::Handle());
      break;
    }
    default:
      // Array cids are already checked in the caller.
      UNREACHABLE();
      return NULL;
  }

  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);
  if (!value_check.IsNull()) {
    AddCheckClass(stored_value, value_check, call->deopt_id(), call->env(),
                  call);
  }
  StoreBarrierType needs_store_barrier = kNoStoreBarrier;
  StoreIndexedInstr* array_op = new StoreIndexedInstr(new Value(array),
                                                      new Value(index),
                                                      new Value(stored_value),
                                                      needs_store_barrier,
                                                      1,  // Index scale
                                                      view_cid,
                                                      call->deopt_id());
  ReplaceCall(call, array_op);
  return true;
}


void FlowGraphOptimizer::PrepareByteArrayViewOp(
    InstanceCallInstr* call,
    intptr_t receiver_cid,
    intptr_t view_cid,
    Definition** array) {
  Definition* byte_index = call->ArgumentAt(1);

  AddReceiverCheck(call);
  const bool is_immutable = true;
  LoadFieldInstr* length = new LoadFieldInstr(
      new Value(*array),
      CheckArrayBoundInstr::LengthOffsetFor(receiver_cid),
      Type::ZoneHandle(Type::SmiType()),
      is_immutable);
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(
      LoadFieldInstr::RecognizedKindFromArrayCid(receiver_cid));
  InsertBefore(call, length, NULL, Definition::kValue);

  // len_in_bytes = length * kBytesPerElement(receiver)
  intptr_t element_size = FlowGraphCompiler::ElementSizeFor(receiver_cid);
  ConstantInstr* bytes_per_element =
      new ConstantInstr(Smi::Handle(Smi::New(element_size)));
  InsertBefore(call, bytes_per_element, NULL, Definition::kValue);
  BinarySmiOpInstr* len_in_bytes =
      new BinarySmiOpInstr(Token::kMUL,
                           call,
                           new Value(length),
                           new Value(bytes_per_element));
  InsertBefore(call, len_in_bytes, call->env(), Definition::kValue);

    // Check byte_index < len_in_bytes.
  InsertBefore(call,
               new CheckArrayBoundInstr(new Value(len_in_bytes),
                                        new Value(byte_index),
                                        receiver_cid,
                                        call),
               call->env(),
               Definition::kEffect);

  // Insert load of elements for external typed arrays.
  if (RawObject::IsExternalTypedDataClassId(receiver_cid)) {
    LoadUntaggedInstr* elements =
        new LoadUntaggedInstr(new Value(*array),
                              ExternalTypedData::data_offset());
    InsertBefore(call, elements, NULL, Definition::kValue);
    *array = elements;
  }
}


// Returns a Boolean constant if all classes in ic_data yield the same type-test
// result and the type tests do not depend on type arguments. Otherwise return
// Bool::null().
RawBool* FlowGraphOptimizer::InstanceOfAsBool(const ICData& ic_data,
                                              const AbstractType& type) const {
  ASSERT(ic_data.num_args_tested() == 1);  // Unary checks only.
  if (!type.IsInstantiated() || type.IsMalformed()) return Bool::null();
  const Class& type_class = Class::Handle(type.type_class());
  if (type_class.HasTypeArguments()) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const AbstractTypeArguments& type_arguments =
        AbstractTypeArguments::Handle(type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
        type_arguments.IsRaw(type_arguments.Length());
    if (!is_raw_type) {
      // Unknown result.
      return Bool::null();
    }
  }
  const ClassTable& class_table = *Isolate::Current()->class_table();
  Bool& prev = Bool::Handle();
  Class& cls = Class::Handle();
  for (int i = 0; i < ic_data.NumberOfChecks(); i++) {
    cls = class_table.At(ic_data.GetReceiverClassIdAt(i));
    if (cls.HasTypeArguments()) return Bool::null();
    const bool is_subtype = cls.IsSubtypeOf(TypeArguments::Handle(),
                                            type_class,
                                            TypeArguments::Handle(),
                                            NULL);
    if (prev.IsNull()) {
      prev = is_subtype ? Bool::True().raw() : Bool::False().raw();
    } else {
      if (is_subtype != prev.value()) return Bool::null();
    }
  }
  return prev.raw();
}


// TODO(srdjan): Use ICData to check if always true or false.
void FlowGraphOptimizer::ReplaceWithInstanceOf(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator = call->ArgumentAt(1);
  Definition* type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  const bool negate =
      Bool::Cast(call->ArgumentAt(4)->AsConstant()->value()).value();
  const ICData& unary_checks =
      ICData::ZoneHandle(call->ic_data()->AsUnaryClassChecks());
  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    Bool& as_bool = Bool::ZoneHandle(InstanceOfAsBool(unary_checks, type));
    if (!as_bool.IsNull()) {
      AddReceiverCheck(call);
      if (negate) {
        as_bool = Bool::Get(!as_bool.value());
      }
      ConstantInstr* bool_const = new ConstantInstr(as_bool);
      ReplaceCall(call, bool_const);
      return;
    }
  }
  InstanceOfInstr* instance_of =
      new InstanceOfInstr(call->token_pos(),
                          new Value(left),
                          new Value(instantiator),
                          new Value(type_args),
                          type,
                          negate,
                          call->deopt_id());
  ReplaceCall(call, instance_of);
}


void FlowGraphOptimizer::ReplaceWithTypeCast(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeCastOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator = call->ArgumentAt(1);
  Definition* type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  ASSERT(!type.IsMalformed());
  const ICData& unary_checks =
      ICData::ZoneHandle(call->ic_data()->AsUnaryClassChecks());
  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    Bool& as_bool = Bool::ZoneHandle(InstanceOfAsBool(unary_checks, type));
    if (as_bool.raw() == Bool::True().raw()) {
      AddReceiverCheck(call);
      // Remove the original push arguments.
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->PushArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
      // Remove call, replace it with 'left'.
      call->ReplaceUsesWith(left);
      call->RemoveFromGraph();
      return;
    }
  }
  const String& dst_name = String::ZoneHandle(
      Symbols::New(Exceptions::kCastErrorDstName));
  AssertAssignableInstr* assert_as =
      new AssertAssignableInstr(call->token_pos(),
                                new Value(left),
                                new Value(instantiator),
                                new Value(type_args),
                                type,
                                dst_name);
  // Newly inserted instructions that can deoptimize or throw an exception
  // must have a deoptimization id that is valid for lookup in the unoptimized
  // code.
  assert_as->deopt_id_ = call->deopt_id();
  ReplaceCall(call, assert_as);
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (!instr->HasICData() || (instr->ic_data()->NumberOfChecks() == 0)) {
    return;
  }

  const Token::Kind op_kind = instr->token_kind();
  // Type test is special as it always gets converted into inlined code.
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }

  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }

  const ICData& unary_checks =
      ICData::ZoneHandle(instr->ic_data()->AsUnaryClassChecks());

  if ((unary_checks.NumberOfChecks() > FLAG_max_polymorphic_checks) &&
      InstanceCallNeedsClassCheck(instr)) {
    // Too many checks, it will be megamorphic which needs unary checks.
    instr->set_ic_data(&unary_checks);
    return;
  }

  if ((op_kind == Token::kASSIGN_INDEX) && TryReplaceWithStoreIndexed(instr)) {
    return;
  }
  if ((op_kind == Token::kINDEX) && TryReplaceWithLoadIndexed(instr)) {
    return;
  }
  if (Token::IsBinaryOperator(op_kind) &&
      TryReplaceWithBinaryOp(instr, op_kind)) {
    return;
  }
  if (Token::IsPrefixOperator(op_kind) &&
      TryReplaceWithUnaryOp(instr, op_kind)) {
    return;
  }
  if ((op_kind == Token::kGET) && TryInlineInstanceGetter(instr)) {
    return;
  }
  if ((op_kind == Token::kSET) &&
      TryInlineInstanceSetter(instr, unary_checks)) {
    return;
  }
  if (TryInlineInstanceMethod(instr)) {
    return;
  }

  const bool has_one_target = unary_checks.HasOneTarget();

  if (has_one_target) {
    const bool is_method_extraction =
        Function::Handle(unary_checks.GetTargetAt(0)).IsMethodExtractor();

    if ((is_method_extraction && !MethodExtractorNeedsClassCheck(instr)) ||
        (!is_method_extraction && !InstanceCallNeedsClassCheck(instr))) {
      const bool call_with_checks = false;
      PolymorphicInstanceCallInstr* call =
          new PolymorphicInstanceCallInstr(instr, unary_checks,
                                           call_with_checks);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    bool call_with_checks;
    if (has_one_target) {
      // Type propagation has not run yet, we cannot eliminate the check.
      AddReceiverCheck(instr);
      // Call can still deoptimize, do not detach environment from instr.
      call_with_checks = false;
    } else {
      call_with_checks = true;
    }
    PolymorphicInstanceCallInstr* call =
        new PolymorphicInstanceCallInstr(instr, unary_checks,
                                         call_with_checks);
    instr->ReplaceWith(call, current_iterator());
  }
}


void FlowGraphOptimizer::VisitStaticCall(StaticCallInstr* call) {
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(call->function());
  if (recognized_kind == MethodRecognizer::kMathSqrt) {
    MathSqrtInstr* sqrt =
        new MathSqrtInstr(new Value(call->ArgumentAt(0)), call);
    ReplaceCall(call, sqrt);
  }
}


bool FlowGraphOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr,
                                                 const ICData& unary_ic_data) {
  ASSERT((unary_ic_data.NumberOfChecks() > 0) &&
      (unary_ic_data.num_args_tested() == 1));
  if (FLAG_enable_type_checks) {
    // TODO(srdjan): Add assignable check node if --enable_type_checks.
    return false;
  }

  ASSERT(instr->HasICData());
  if (unary_ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }
  if (!unary_ic_data.HasOneTarget()) {
    // TODO(srdjan): Implement when not all targets are the same.
    return false;
  }
  Function& target = Function::Handle();
  intptr_t class_id;
  unary_ic_data.GetOneClassCheckAt(0, &class_id, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Not an implicit setter.
    // TODO(srdjan): Inline special setters.
    return false;
  }
  // Inline implicit instance setter.
  const String& field_name =
      String::Handle(Field::NameFromSetter(instr->function_name()));
  const Field& field = Field::Handle(GetField(class_id, field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(instr)) {
    AddReceiverCheck(instr);
  }
  StoreBarrierType needs_store_barrier = kEmitStoreBarrier;
  if (ArgIsAlwaysSmi(*instr->ic_data(), 1)) {
    InsertBefore(instr,
                 new CheckSmiInstr(new Value(instr->ArgumentAt(1)),
                                   instr->deopt_id()),
                 instr->env(),
                 Definition::kEffect);
    needs_store_barrier = kNoStoreBarrier;
  }

  if (field.guarded_cid() != kDynamicCid) {
    InsertBefore(instr,
                 new GuardFieldInstr(new Value(instr->ArgumentAt(1)),
                                     field,
                                     instr->deopt_id()),
                 instr->env(),
                 Definition::kEffect);
  }

  // Field guard was detached.
  StoreInstanceFieldInstr* store = new StoreInstanceFieldInstr(
      field,
      new Value(instr->ArgumentAt(0)),
      new Value(instr->ArgumentAt(1)),
      needs_store_barrier);
  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCall(instr, store);
  return true;
}


void FlowGraphOptimizer::HandleRelationalOp(RelationalOpInstr* comp) {
  if (!comp->HasICData() || (comp->ic_data()->NumberOfChecks() == 0)) {
    return;
  }
  const ICData& ic_data = *comp->ic_data();
  Instruction* instr = current_iterator()->Current();
  if (ic_data.NumberOfChecks() == 1) {
    ASSERT(ic_data.HasOneTarget());
    if (HasOnlyTwoSmis(ic_data)) {
      InsertBefore(instr,
                   new CheckSmiInstr(comp->left()->Copy(), comp->deopt_id()),
                   instr->env(),
                   Definition::kEffect);
      InsertBefore(instr,
                   new CheckSmiInstr(comp->right()->Copy(), comp->deopt_id()),
                   instr->env(),
                   Definition::kEffect);
      comp->set_operands_class_id(kSmiCid);
    } else if (ShouldSpecializeForDouble(ic_data)) {
      comp->set_operands_class_id(kDoubleCid);
    } else if (HasTwoMintOrSmi(*comp->ic_data()) &&
               FlowGraphCompiler::SupportsUnboxedMints()) {
      comp->set_operands_class_id(kMintCid);
    } else {
      ASSERT(comp->operands_class_id() == kIllegalCid);
    }
  } else if (HasTwoMintOrSmi(*comp->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    comp->set_operands_class_id(kMintCid);
  }
}


void FlowGraphOptimizer::VisitRelationalOp(RelationalOpInstr* instr) {
  HandleRelationalOp(instr);
}


template <typename T>
void FlowGraphOptimizer::HandleEqualityCompare(EqualityCompareInstr* comp,
                                               T current_instruction) {
  // If one of the inputs is null, no ICdata will be collected.
  if (comp->left()->BindsToConstantNull() ||
      comp->right()->BindsToConstantNull()) {
    Token::Kind strict_kind = (comp->kind() == Token::kEQ) ?
        Token::kEQ_STRICT : Token::kNE_STRICT;
    StrictCompareInstr* strict_comp =
        new StrictCompareInstr(strict_kind,
                               comp->left()->Copy(),
                               comp->right()->Copy());
    current_instruction->ReplaceWith(strict_comp, current_iterator());
    return;
  }
  if (!comp->HasICData() || (comp->ic_data()->NumberOfChecks() == 0)) {
    return;
  }
  ASSERT(comp->ic_data()->num_args_tested() == 2);
  if (comp->ic_data()->NumberOfChecks() == 1) {
    GrowableArray<intptr_t> class_ids;
    Function& target = Function::Handle();
    comp->ic_data()->GetCheckAt(0, &class_ids, &target);
    // TODO(srdjan): allow for mixed mode int/double comparison.

    if ((class_ids[0] == kSmiCid) && (class_ids[1] == kSmiCid)) {
      InsertBefore(current_instruction,
                   new CheckSmiInstr(comp->left()->Copy(), comp->deopt_id()),
                   current_instruction->env(),
                   Definition::kEffect);
      InsertBefore(current_instruction,
                   new CheckSmiInstr(comp->right()->Copy(), comp->deopt_id()),
                   current_instruction->env(),
                   Definition::kEffect);
      comp->set_receiver_class_id(kSmiCid);
    } else if ((class_ids[0] == kDoubleCid) && (class_ids[1] == kDoubleCid)) {
      comp->set_receiver_class_id(kDoubleCid);
    } else if (HasTwoMintOrSmi(*comp->ic_data()) &&
               FlowGraphCompiler::SupportsUnboxedMints()) {
      comp->set_receiver_class_id(kMintCid);
    } else {
      ASSERT(comp->receiver_class_id() == kIllegalCid);
    }
  } else if (HasTwoMintOrSmi(*comp->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    comp->set_receiver_class_id(kMintCid);
  }

  if (comp->receiver_class_id() != kIllegalCid) {
    // Done.
    return;
  }

  // Check if ICDData contains checks with Smi/Null combinations. In that case
  // we can still emit the optimized Smi equality operation but need to add
  // checks for null or Smi.
  // TODO(srdjan): Add it for Double and Mint.
  GrowableArray<intptr_t> smi_or_null(2);
  smi_or_null.Add(kSmiCid);
  smi_or_null.Add(kNullCid);
  if (ICDataHasOnlyReceiverArgumentClassIds(*comp->ic_data(),
                                            smi_or_null,
                                            smi_or_null)) {
    const ICData& unary_checks_0 =
        ICData::ZoneHandle(comp->ic_data()->AsUnaryClassChecks());
    AddCheckClass(comp->left()->definition(),
                  unary_checks_0,
                  comp->deopt_id(),
                  current_instruction->env(),
                  current_instruction);

    const ICData& unary_checks_1 =
        ICData::ZoneHandle(comp->ic_data()->AsUnaryClassChecksForArgNr(1));
    AddCheckClass(comp->right()->definition(),
                  unary_checks_1,
                  comp->deopt_id(),
                  current_instruction->env(),
                  current_instruction);
    comp->set_receiver_class_id(kSmiCid);
  }
}


void FlowGraphOptimizer::VisitEqualityCompare(EqualityCompareInstr* instr) {
  HandleEqualityCompare(instr, instr);
}


void FlowGraphOptimizer::VisitBranch(BranchInstr* instr) {
  ComparisonInstr* comparison = instr->comparison();
  if (comparison->IsRelationalOp()) {
    HandleRelationalOp(comparison->AsRelationalOp());
  } else if (comparison->IsEqualityCompare()) {
    HandleEqualityCompare(comparison->AsEqualityCompare(), instr);
  } else {
    ASSERT(comparison->IsStrictCompare());
    // Nothing to do.
  }
}


static bool MayBeBoxableNumber(intptr_t cid) {
  return (cid == kDynamicCid) ||
         (cid == kMintCid) ||
         (cid == kBigintCid) ||
         (cid == kDoubleCid);
}


// Check if number check is not needed.
void FlowGraphOptimizer::VisitStrictCompare(StrictCompareInstr* instr) {
  if (!instr->needs_number_check()) return;

  // If one of the input is not a boxable number (Mint, Double, Bigint), no
  // need for number checks.
  if (!MayBeBoxableNumber(instr->left()->Type()->ToCid()) ||
      !MayBeBoxableNumber(instr->right()->Type()->ToCid()))  {
    instr->set_needs_number_check(false);
  }
}


// Range analysis for smi values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        marked_defns_(NULL) { }

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

 private:
  // Collect all values that were proven to be smi in smi_values_ array and all
  // CheckSmi instructions in smi_check_ array.
  void CollectSmiValues();

  // Iterate over smi values and constrain them at branch successors.
  // Additionally constraint values after CheckSmi instructions.
  void InsertConstraints();

  // Iterate over uses of the given definition and discover branches that
  // constrain it. Insert appropriate Constraint instructions at true
  // and false successor and rename all dominated uses to refer to a
  // Constraint instead of this definition.
  void InsertConstraintsFor(Definition* defn);

  // Create a constraint for defn, insert it after given instruction and
  // rename all uses that are dominated by it.
  ConstraintInstr* InsertConstraintFor(Definition* defn,
                                       Range* constraint,
                                       Instruction* after);

  void ConstrainValueAfterBranch(Definition* defn, Value* use);
  void ConstrainValueAfterCheckArrayBound(Definition* defn,
                                          CheckArrayBoundInstr* check);

  // Replace uses of the definition def that are dominated by instruction dom
  // with uses of other definition.
  void RenameDominatedUses(Definition* def,
                           Instruction* dom,
                           Definition* other);


  // Walk the dominator tree and infer ranges for smi values.
  void InferRanges();
  void InferRangesRecursive(BlockEntryInstr* block);

  enum Direction {
    kUnknown,
    kPositive,
    kNegative,
    kBoth
  };

  Range* InferInductionVariableRange(JoinEntryInstr* loop_header,
                                     PhiInstr* var);

  void ResetWorklist();
  void MarkDefinition(Definition* defn);

  static Direction ToDirection(Value* val);

  static Direction Invert(Direction direction) {
    return (direction == kPositive) ? kNegative : kPositive;
  }

  static void UpdateDirection(Direction* direction,
                              Direction new_direction) {
    if (*direction != new_direction) {
      if (*direction != kUnknown) new_direction = kBoth;
      *direction = new_direction;
    }
  }

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  FlowGraph* flow_graph_;

  GrowableArray<Definition*> smi_values_;  // Value that are known to be smi.
  GrowableArray<CheckSmiInstr*> smi_checks_;  // All CheckSmi instructions.

  // All Constraints inserted during InsertConstraints phase. They are treated
  // as smi values.
  GrowableArray<ConstraintInstr*> constraints_;

  // Bitvector for a quick filtering of known smi values.
  BitVector* smi_definitions_;

  // Worklist for induction variables analysis.
  GrowableArray<Definition*> worklist_;
  BitVector* marked_defns_;

  DISALLOW_COPY_AND_ASSIGN(RangeAnalysis);
};


void RangeAnalysis::Analyze() {
  CollectSmiValues();
  InsertConstraints();
  InferRanges();
  RemoveConstraints();
}


void RangeAnalysis::CollectSmiValues() {
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if (defn != NULL) {
        if ((defn->Type()->ToCid() == kSmiCid) &&
            (defn->ssa_temp_index() != -1)) {
          smi_values_.Add(defn);
        }
      } else if (current->IsCheckSmi()) {
        smi_checks_.Add(current->AsCheckSmi());
      }
    }

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* current = phi_it.Current();
        if ((current->Type()->ToCid() == kSmiCid)) {
          smi_values_.Add(current);
        }
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
static Range* ConstraintRange(Token::Kind op, Definition* boundary) {
  switch (op) {
    case Token::kEQ:
      return new Range(RangeBoundary::FromDefinition(boundary),
                       RangeBoundary::FromDefinition(boundary));
    case Token::kNE:
      return Range::Unknown();
    case Token::kLT:
      return new Range(RangeBoundary::MinSmi(),
                       RangeBoundary::FromDefinition(boundary, -1));
    case Token::kGT:
      return new Range(RangeBoundary::FromDefinition(boundary, 1),
                       RangeBoundary::MaxSmi());
    case Token::kLTE:
      return new Range(RangeBoundary::MinSmi(),
                       RangeBoundary::FromDefinition(boundary));
    case Token::kGTE:
      return new Range(RangeBoundary::FromDefinition(boundary),
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

  ConstraintInstr* constraint =
      new ConstraintInstr(new Value(defn), constraint_range);
  flow_graph_->InsertAfter(after, constraint, NULL, Definition::kValue);
  RenameDominatedUses(defn, constraint, constraint);
  constraints_.Add(constraint);
  return constraint;
}


void RangeAnalysis::ConstrainValueAfterBranch(Definition* defn, Value* use) {
  BranchInstr* branch = use->instruction()->AsBranch();
  RelationalOpInstr* rel_op = branch->comparison()->AsRelationalOp();
  if ((rel_op != NULL) && (rel_op->operands_class_id() == kSmiCid)) {
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
          use->instruction()->AsCheckArrayBound());
    }
  }
}


void RangeAnalysis::ConstrainValueAfterCheckArrayBound(
    Definition* defn, CheckArrayBoundInstr* check) {
  if (!CheckArrayBoundInstr::IsFixedLengthArrayType(check->array_type())) {
    return;
  }

  Definition* length = check->length()->definition();

  Range* constraint_range = new Range(
      RangeBoundary::FromConstant(0),
      RangeBoundary::FromDefinition(length, -1));
  InsertConstraintFor(defn, constraint_range, check);
}


void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < smi_checks_.length(); i++) {
    CheckSmiInstr* check = smi_checks_[i];
    InsertConstraintFor(check->value()->definition(), Range::Unknown(), check);
  }

  for (intptr_t i = 0; i < smi_values_.length(); i++) {
    InsertConstraintsFor(smi_values_[i]);
  }

  for (intptr_t i = 0; i < constraints_.length(); i++) {
    InsertConstraintsFor(constraints_[i]);
  }
}


void RangeAnalysis::ResetWorklist() {
  if (marked_defns_ == NULL) {
    marked_defns_ = new BitVector(flow_graph_->current_ssa_temp_index());
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
    if (Range::ConstantMin(range).value() >= 0) {
      return kPositive;
    } else if (Range::ConstantMax(range).value() <= 0) {
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
      return new Range(RangeBoundary::FromDefinition(initial_value),
                       RangeBoundary::MaxSmi());

    case kNegative:
      return new Range(RangeBoundary::MinSmi(),
                       RangeBoundary::FromDefinition(initial_value));

    case kUnknown:
    case kBoth:
      return Range::Unknown();
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
      if (smi_definitions_->Contains(phi->ssa_temp_index())) {
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
        smi_definitions_->Contains(defn->ssa_temp_index())) {
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
  // Initialize bitvector for quick filtering of smi values.
  smi_definitions_ = new BitVector(flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < smi_values_.length(); i++) {
    smi_definitions_->Add(smi_values_[i]->ssa_temp_index());
  }
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    smi_definitions_->Add(constraints_[i]->ssa_temp_index());
  }

  // Infer initial values of ranges.
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


void FlowGraphOptimizer::InferSmiRanges() {
  RangeAnalysis range_analysis(flow_graph_);
  range_analysis.Analyze();
}


static BlockEntryInstr* FindPreHeader(BlockEntryInstr* header) {
  for (intptr_t j = 0; j < header->PredecessorCount(); ++j) {
    BlockEntryInstr* candidate = header->PredecessorAt(j);
    if (header->dominator() == candidate) {
      return candidate;
    }
  }
  return NULL;
}


LICM::LICM(FlowGraph* flow_graph) : flow_graph_(flow_graph) {
}


void LICM::Hoist(ForwardInstructionIterator* it,
                 BlockEntryInstr* pre_header,
                 Instruction* current) {
  // TODO(fschneider): Avoid repeated deoptimization when
  // speculatively hoisting checks.
  if (FLAG_trace_optimization) {
    OS::Print("Hoisting instruction %s:%"Pd" from B%"Pd" to B%"Pd"\n",
              current->DebugName(),
              current->GetDeoptId(),
              current->GetBlock()->block_id(),
              pre_header->block_id());
  }
  // Move the instruction out of the loop.
  current->RemoveEnvironment();
  it->RemoveCurrentFromGraph();
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  // Using kind kEffect will not assign a fresh ssa temporary index.
  flow_graph()->InsertBefore(last, current, last->env(), Definition::kEffect);
  current->deopt_id_ = last->GetDeoptId();
}


void LICM::TryHoistCheckSmiThroughPhi(ForwardInstructionIterator* it,
                                      BlockEntryInstr* header,
                                      BlockEntryInstr* pre_header,
                                      CheckSmiInstr* current) {
  PhiInstr* phi = current->value()->definition()->AsPhi();
  if (!header->loop_info()->Contains(phi->block()->preorder_number())) {
    return;
  }

  if (phi->Type()->ToCid() == kSmiCid) {
    it->RemoveCurrentFromGraph();
    return;
  }

  // Check if there is only a single kDynamicCid input to the phi that
  // comes from the pre-header.
  const intptr_t kNotFound = -1;
  intptr_t non_smi_input = kNotFound;
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Value* input = phi->InputAt(i);
    if (input->Type()->ToCid() != kSmiCid) {
      if ((non_smi_input != kNotFound) ||
          (input->Type()->ToCid() != kDynamicCid)) {
        // There are multiple kDynamicCid inputs or there is an input that is
        // known to be non-smi.
        return;
      } else {
        non_smi_input = i;
      }
    }
  }

  if ((non_smi_input == kNotFound) ||
      (phi->block()->PredecessorAt(non_smi_input) != pre_header)) {
    return;
  }

  // Host CheckSmi instruction and make this phi smi one.
  Hoist(it, pre_header, current);

  // Replace value we are checking with phi's input.
  current->value()->BindTo(phi->InputAt(non_smi_input)->definition());

  phi->UpdateType(CompileType::FromCid(kSmiCid));
}


void LICM::Optimize() {
  GrowableArray<BlockEntryInstr*> loop_headers;
  flow_graph()->ComputeLoops(&loop_headers);

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    BlockEntryInstr* header = loop_headers[i];
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = FindPreHeader(header);
    if (pre_header == NULL) continue;

    for (BitVector::Iterator loop_it(header->loop_info());
         !loop_it.Done();
         loop_it.Advance()) {
      BlockEntryInstr* block = flow_graph()->preorder()[loop_it.Current()];
      for (ForwardInstructionIterator it(block);
           !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        if (!current->IsPushArgument() && !current->AffectedBySideEffect()) {
          bool inputs_loop_invariant = true;
          for (int i = 0; i < current->InputCount(); ++i) {
            Definition* input_def = current->InputAt(i)->definition();
            if (!input_def->GetBlock()->Dominates(pre_header)) {
              inputs_loop_invariant = false;
              break;
            }
          }
          if (inputs_loop_invariant &&
              !current->IsAssertAssignable() &&
              !current->IsAssertBoolean()) {
            // TODO(fschneider): Enable hoisting of Assert-instructions
            // if it safe to do.
            Hoist(&it, pre_header, current);
          } else if (current->IsCheckSmi() &&
                     current->InputAt(0)->definition()->IsPhi()) {
            TryHoistCheckSmiThroughPhi(
                &it, header, pre_header, current->AsCheckSmi());
          }
        }
      }
    }
  }
}


static bool IsLoadEliminationCandidate(Definition* def) {
  // Immutable loads (not affected by side effects) are handled
  // in the DominatorBasedCSE pass.
  // TODO(fschneider): Extend to other load instructions.
  return (def->IsLoadField() && def->AffectedBySideEffect())
      || def->IsLoadIndexed();
}


static intptr_t ComputeLoadOffsetInWords(Definition* defn) {
  if (defn->IsLoadIndexed()) {
    // We are assuming that LoadField is never used to load the first word.
    return 0;
  }

  LoadFieldInstr* load_field = defn->AsLoadField();
  if (load_field != NULL) {
    const intptr_t idx = load_field->offset_in_bytes() / kWordSize;
    ASSERT(idx > 0);
    return idx;
  }

  UNREACHABLE();
  return 0;
}


static bool IsInterferingStore(Instruction* instr,
                               intptr_t* offset_in_words) {
  if (instr->IsStoreIndexed()) {
    // We are assuming that LoadField is never used to load the first word.
    *offset_in_words = 0;
    return true;
  }

  StoreInstanceFieldInstr* store_instance_field = instr->AsStoreInstanceField();
  if (store_instance_field != NULL) {
    ASSERT(store_instance_field->field().Offset() != 0);
    *offset_in_words = store_instance_field->field().Offset() / kWordSize;
    return true;
  }

  StoreVMFieldInstr* store_vm_field = instr->AsStoreVMField();
  if (store_vm_field != NULL) {
    ASSERT(store_vm_field->offset_in_bytes() != 0);
    *offset_in_words = store_vm_field->offset_in_bytes() / kWordSize;
    return true;
  }

  return false;
}


static Definition* GetStoredValue(Instruction* instr) {
  if (instr->IsStoreIndexed()) {
    return instr->AsStoreIndexed()->value()->definition();
  }

  StoreInstanceFieldInstr* store_instance_field = instr->AsStoreInstanceField();
  if (store_instance_field != NULL) {
    return store_instance_field->value()->definition();
  }

  StoreVMFieldInstr* store_vm_field = instr->AsStoreVMField();
  if (store_vm_field != NULL) {
    return store_vm_field->value()->definition();
  }

  UNREACHABLE();  // Should only be called for supported store instructions.
  return NULL;
}


// KeyValueTrait used for numbering of loads. Allows to lookup loads
// corresponding to stores.
class LoadKeyValueTrait {
 public:
  typedef Definition* Value;
  typedef Definition* Key;
  typedef Definition* Pair;

  static Key KeyOf(Pair kv) {
    return kv;
  }

  static Value ValueOf(Pair kv) {
    return kv;
  }

  static inline intptr_t Hashcode(Key key) {
    intptr_t object = 0;
    intptr_t location = 0;

    if (key->IsLoadIndexed()) {
      LoadIndexedInstr* load_indexed = key->AsLoadIndexed();
      object = load_indexed->array()->definition()->ssa_temp_index();
      location = load_indexed->index()->definition()->ssa_temp_index();
    } else if (key->IsStoreIndexed()) {
      StoreIndexedInstr* store_indexed = key->AsStoreIndexed();
      object = store_indexed->array()->definition()->ssa_temp_index();
      location = store_indexed->index()->definition()->ssa_temp_index();
    } else if (key->IsLoadField()) {
      LoadFieldInstr* load_field = key->AsLoadField();
      object = load_field->value()->definition()->ssa_temp_index();
      location = load_field->offset_in_bytes();
    } else if (key->IsStoreInstanceField()) {
      StoreInstanceFieldInstr* store_field = key->AsStoreInstanceField();
      object = store_field->instance()->definition()->ssa_temp_index();
      location = store_field->field().Offset();
    } else if (key->IsStoreVMField()) {
      StoreVMFieldInstr* store_field = key->AsStoreVMField();
      object = store_field->dest()->definition()->ssa_temp_index();
      location = store_field->offset_in_bytes();
    }

    return object * 31 + location;
  }

  static inline bool IsKeyEqual(Pair kv, Key key) {
    if (kv->Equals(key)) return true;

    if (kv->IsLoadIndexed()) {
      if (key->IsStoreIndexed()) {
        LoadIndexedInstr* load_indexed = kv->AsLoadIndexed();
        StoreIndexedInstr* store_indexed = key->AsStoreIndexed();
        return load_indexed->array()->Equals(store_indexed->array()) &&
               load_indexed->index()->Equals(store_indexed->index());
      }
      return false;
    }

    ASSERT(kv->IsLoadField());
    LoadFieldInstr* load_field = kv->AsLoadField();
    if (key->IsStoreVMField()) {
      StoreVMFieldInstr* store_field = key->AsStoreVMField();
      return load_field->value()->Equals(store_field->dest()) &&
             (load_field->offset_in_bytes() == store_field->offset_in_bytes());
    } else if (key->IsStoreInstanceField()) {
      StoreInstanceFieldInstr* store_field = key->AsStoreInstanceField();
      return load_field->value()->Equals(store_field->instance()) &&
             (load_field->offset_in_bytes() == store_field->field().Offset());
    }

    return false;
  }
};


static intptr_t NumberLoadExpressions(
    FlowGraph* graph,
    DirectChainedHashMap<LoadKeyValueTrait>* map,
    GrowableArray<BitVector*>* kill_by_offs) {
  intptr_t expr_id = 0;

  // Loads representing different expression ids will be collected and
  // used to build per offset kill sets.
  GrowableArray<Definition*> loads(10);

  for (BlockIterator it = graph->reverse_postorder_iterator();
       !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Definition* defn = instr_it.Current()->AsDefinition();
      if ((defn == NULL) || !IsLoadEliminationCandidate(defn)) {
        continue;
      }
      Definition* result = map->Lookup(defn);
      if (result == NULL) {
        map->Insert(defn);
        defn->set_expr_id(expr_id++);
        loads.Add(defn);
      } else {
        defn->set_expr_id(result->expr_id());
      }
    }
  }

  // Build per offset kill sets. Any store interferes only with loads from
  // the same offset.
  for (intptr_t i = 0; i < loads.length(); i++) {
    Definition* defn = loads[i];

    const intptr_t offset_in_words = ComputeLoadOffsetInWords(defn);
    while (kill_by_offs->length() <= offset_in_words) {
      kill_by_offs->Add(NULL);
    }
    if ((*kill_by_offs)[offset_in_words] == NULL) {
      (*kill_by_offs)[offset_in_words] = new BitVector(expr_id);
    }
    (*kill_by_offs)[offset_in_words]->Add(defn->expr_id());
  }

  return expr_id;
}


class LoadOptimizer : public ValueObject {
 public:
  LoadOptimizer(FlowGraph* graph,
                intptr_t max_expr_id,
                DirectChainedHashMap<LoadKeyValueTrait>* map,
                const GrowableArray<BitVector*>& kill_by_offset)
      : graph_(graph),
        map_(map),
        max_expr_id_(max_expr_id),
        kill_by_offset_(kill_by_offset),
        in_(graph_->preorder().length()),
        out_(graph_->preorder().length()),
        gen_(graph_->preorder().length()),
        kill_(graph_->preorder().length()),
        exposed_values_(graph_->preorder().length()),
        out_values_(graph_->preorder().length()),
        phis_(5),
        worklist_(5),
        in_worklist_(NULL) {
    const intptr_t num_blocks = graph_->preorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      out_.Add(new BitVector(max_expr_id_));
      gen_.Add(new BitVector(max_expr_id_));
      kill_.Add(new BitVector(max_expr_id_));
      in_.Add(new BitVector(max_expr_id_));

      exposed_values_.Add(NULL);
      out_values_.Add(NULL);
    }
  }

  void Optimize() {
    ComputeInitialSets();
    ComputeOutValues();
    ForwardLoads();
    EmitPhis();
  }

 private:
  // Compute sets of loads generated and killed by each block.
  // Additionally compute upwards exposed and generated loads for each block.
  // Exposed loads are those that can be replaced if a corresponding
  // reaching load will be found.
  // Loads that are locally redundant will be replaced as we go through
  // instructions.
  void ComputeInitialSets() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t preorder_number = block->preorder_number();

      BitVector* kill = kill_[preorder_number];
      BitVector* gen = gen_[preorder_number];

      ZoneGrowableArray<Definition*>* exposed_values = NULL;
      ZoneGrowableArray<Definition*>* out_values = NULL;

      for (ForwardInstructionIterator instr_it(block);
           !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        intptr_t offset_in_words = 0;
        if (IsInterferingStore(instr, &offset_in_words)) {
          // Interfering stores kill only loads from the same offset.
          if ((offset_in_words < kill_by_offset_.length()) &&
              (kill_by_offset_[offset_in_words] != NULL)) {
            kill->AddAll(kill_by_offset_[offset_in_words]);
            // There is no need to clear out_values when clearing GEN set
            // because only those values that are in the GEN set
            // will ever be used.
            gen->RemoveAll(kill_by_offset_[offset_in_words]);

            // Only forward stores to normal arrays and float64 arrays
            // to loads because other array stores (intXX/uintXX/float32)
            // may implicitly convert the value stored.
            StoreIndexedInstr* array_store = instr->AsStoreIndexed();
            if (array_store == NULL ||
                array_store->class_id() == kArrayCid ||
                array_store->class_id() == kTypedDataFloat64ArrayCid) {
              Definition* load = map_->Lookup(instr->AsDefinition());
              if (load != NULL) {
                // Store has a corresponding numbered load. Try forwarding
                // stored value to it.
                gen->Add(load->expr_id());
                if (out_values == NULL) out_values = CreateBlockOutValues();
                (*out_values)[load->expr_id()] = GetStoredValue(instr);
              }
            }
          }
          ASSERT(instr->IsDefinition() &&
                 !IsLoadEliminationCandidate(instr->AsDefinition()));
          continue;
        }

        // Other instructions with side effects kill all loads.
        if (instr->HasSideEffect()) {
          kill->SetAll();
          // There is no need to clear out_values when clearing GEN set
          // because only those values that are in the GEN set
          // will ever be used.
          gen->Clear();
          continue;
        }

        Definition* defn = instr->AsDefinition();
        if ((defn == NULL) || !IsLoadEliminationCandidate(defn)) {
          continue;
        }

        const intptr_t expr_id = defn->expr_id();
        if (gen->Contains(expr_id)) {
          // This is a locally redundant load.
          ASSERT((out_values != NULL) && ((*out_values)[expr_id] != NULL));

          Definition* replacement = (*out_values)[expr_id];
          EnsureSSATempIndex(graph_, defn, replacement);
          if (FLAG_trace_optimization) {
            OS::Print("Replacing load v%"Pd" with v%"Pd"\n",
                      defn->ssa_temp_index(),
                      replacement->ssa_temp_index());
          }

          defn->ReplaceUsesWith(replacement);
          instr_it.RemoveCurrentFromGraph();
          continue;
        } else if (!kill->Contains(expr_id)) {
          // This is an exposed load: it is the first representative of a
          // given expression id and it is not killed on the path from
          // the block entry.
          if (exposed_values == NULL) {
            static const intptr_t kMaxExposedValuesInitialSize = 5;
            exposed_values = new ZoneGrowableArray<Definition*>(
                Utils::Minimum(kMaxExposedValuesInitialSize, max_expr_id_));
          }

          exposed_values->Add(defn);
        }

        gen->Add(expr_id);

        if (out_values == NULL) out_values = CreateBlockOutValues();
        (*out_values)[expr_id] = defn;
      }

      out_[preorder_number]->CopyFrom(gen);
      exposed_values_[preorder_number] = exposed_values;
      out_values_[preorder_number] = out_values;
    }
  }

  // Compute OUT sets and corresponding out_values mappings by propagating them
  // iteratively until fix point is reached.
  // No replacement is done at this point and thus any out_value[expr_id] is
  // changed at most once: from NULL to an actual value.
  // When merging incoming loads we might need to create a phi.
  // These phis are not inserted at the graph immediately because some of them
  // might become redundant after load forwarding is done.
  void ComputeOutValues() {
    BitVector* temp = new BitVector(max_expr_id_);

    bool changed = true;
    while (changed) {
      changed = false;

      for (BlockIterator block_it = graph_->reverse_postorder_iterator();
           !block_it.Done();
           block_it.Advance()) {
        BlockEntryInstr* block = block_it.Current();

        const intptr_t preorder_number = block->preorder_number();

        BitVector* block_in = in_[preorder_number];
        BitVector* block_out = out_[preorder_number];
        BitVector* block_kill = kill_[preorder_number];
        BitVector* block_gen = gen_[preorder_number];

        if (FLAG_trace_optimization) {
          OS::Print("B%"Pd"", block->block_id());
          block_in->Print();
          block_out->Print();
          block_kill->Print();
          block_gen->Print();
          OS::Print("\n");
        }

        ZoneGrowableArray<Definition*>* block_out_values =
            out_values_[preorder_number];

        // Compute block_in as the intersection of all out(p) where p
        // is a predecessor of the current block.
        if (block->IsGraphEntry()) {
          temp->Clear();
        } else {
          // TODO(vegorov): this can be optimized for the case of a single
          // predecessor.
          // TODO(vegorov): this can be reordered to reduce amount of operations
          // temp->CopyFrom(first_predecessor)
          temp->SetAll();
          ASSERT(block->PredecessorCount() > 0);
          for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
            BlockEntryInstr* pred = block->PredecessorAt(i);
            BitVector* pred_out = out_[pred->preorder_number()];
            temp->Intersect(pred_out);
          }
        }

        if (!temp->Equals(*block_in)) {
          // If IN set has changed propagate the change to OUT set.
          block_in->CopyFrom(temp);
          if (block_out->KillAndAdd(block_kill, block_in)) {
            // If OUT set has changed then we have new values available out of
            // the block. Compute these values creating phi where necessary.
            for (BitVector::Iterator it(block_out);
                 !it.Done();
                 it.Advance()) {
              const intptr_t expr_id = it.Current();

              if (block_out_values == NULL) {
                out_values_[preorder_number] = block_out_values =
                    CreateBlockOutValues();
              }

              if ((*block_out_values)[expr_id] == NULL) {
                ASSERT(block->PredecessorCount() > 0);
                (*block_out_values)[expr_id] =
                    MergeIncomingValues(block, expr_id);
              }
            }
            changed = true;
          }
        }

        if (FLAG_trace_optimization) {
          OS::Print("after B%"Pd"", block->block_id());
          block_in->Print();
          block_out->Print();
          block_kill->Print();
          block_gen->Print();
          OS::Print("\n");
        }
      }
    }
  }

  // Compute incoming value for the given expression id.
  // Will create a phi if different values are incoming from multiple
  // predecessors.
  Definition* MergeIncomingValues(BlockEntryInstr* block, intptr_t expr_id) {
    // First check if the same value is coming in from all predecessors.
    Definition* incoming = NULL;
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      if (incoming == NULL) {
        incoming = (*pred_out_values)[expr_id];
      } else if (incoming != (*pred_out_values)[expr_id]) {
        incoming = NULL;
        break;
      }
    }

    if (incoming != NULL) {
      return incoming;
    }

    // Incoming values are different. Phi is required to merge.
    PhiInstr* phi = new PhiInstr(
        block->AsJoinEntry(), block->PredecessorCount());

    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      ASSERT((*pred_out_values)[expr_id] != NULL);

      // Sets of outgoing values are not linked into use lists so
      // they might contain values that were replaced and removed
      // from the graph by this iteration.
      // To prevent using them we additionally mark definitions themselves
      // as replaced and store a pointer to the replacement.
      Definition* replacement = (*pred_out_values)[expr_id]->Replacement();
      Value* input = new Value(replacement);
      phi->SetInputAt(i, input);
      replacement->AddInputUse(input);
    }

    phi->set_ssa_temp_index(graph_->alloc_ssa_temp_index());
    phis_.Add(phi);  // Postpone phi insertion until after load forwarding.

    return phi;
  }

  // Iterate over basic blocks and replace exposed loads with incoming
  // values.
  void ForwardLoads() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();

      ZoneGrowableArray<Definition*>* loads =
          exposed_values_[block->preorder_number()];
      if (loads == NULL) continue;  // No exposed loads.

      BitVector* in = in_[block->preorder_number()];

      for (intptr_t i = 0; i < loads->length(); i++) {
        Definition* load = (*loads)[i];
        if (!in->Contains(load->expr_id())) continue;  // No incoming value.

        Definition* replacement = MergeIncomingValues(block, load->expr_id());

        // Sets of outgoing values are not linked into use lists so
        // they might contain values that were replace and removed
        // from the graph by this iteration.
        // To prevent using them we additionally mark definitions themselves
        // as replaced and store a pointer to the replacement.
        replacement = replacement->Replacement();

        if (load != replacement) {
          EnsureSSATempIndex(graph_, load, replacement);

          if (FLAG_trace_optimization) {
            OS::Print("Replacing load v%"Pd" with v%"Pd"\n",
                      load->ssa_temp_index(),
                      replacement->ssa_temp_index());
          }

          load->ReplaceUsesWith(replacement);
          load->RemoveFromGraph();
          load->SetReplacement(replacement);
        }
      }
    }
  }

  // Check if the given phi take the same value on all code paths.
  // Eliminate it as redundant if this is the case.
  // When analyzing phi operands assumes that only generated during
  // this load phase can be redundant. They can be distinguished because
  // they are not marked alive.
  // TODO(vegorov): move this into a separate phase over all phis.
  bool EliminateRedundantPhi(PhiInstr* phi) {
    Definition* value = NULL;  // Possible value of this phi.

    worklist_.Clear();
    if (in_worklist_ == NULL) {
      in_worklist_ = new BitVector(graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    worklist_.Add(phi);
    in_worklist_->Add(phi->ssa_temp_index());

    for (intptr_t i = 0; i < worklist_.length(); i++) {
      PhiInstr* phi = worklist_[i];

      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        Definition* input = phi->InputAt(i)->definition();
        if (input == phi) continue;

        PhiInstr* phi_input = input->AsPhi();
        if ((phi_input != NULL) && !phi_input->is_alive()) {
          if (!in_worklist_->Contains(phi_input->ssa_temp_index())) {
            worklist_.Add(phi_input);
            in_worklist_->Add(phi_input->ssa_temp_index());
          }
          continue;
        }

        if (value == NULL) {
          value = input;
        } else if (value != input) {
          return false;  // This phi is not redundant.
        }
      }
    }

    // All phis in the worklist are redundant and have the same computed
    // value on all code paths.
    ASSERT(value != NULL);
    for (intptr_t i = 0; i < worklist_.length(); i++) {
      worklist_[i]->ReplaceUsesWith(value);
    }

    return true;
  }

  // Phis have not yet been inserted into the graph but they have uses of
  // their inputs.  Insert the non-redundant ones and clear the input uses
  // of the redundant ones.
  void EmitPhis() {
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if (phi->HasUses() && !EliminateRedundantPhi(phi)) {
        phi->mark_alive();
        phi->block()->InsertPhi(phi);
      } else {
        for (intptr_t j = phi->InputCount() - 1; j >= 0; --j) {
          phi->InputAt(j)->RemoveFromUseList();
        }
      }
    }
  }

  ZoneGrowableArray<Definition*>* CreateBlockOutValues() {
    ZoneGrowableArray<Definition*>* out =
        new ZoneGrowableArray<Definition*>(max_expr_id_);
    for (intptr_t i = 0; i < max_expr_id_; i++) {
      out->Add(NULL);
    }
    return out;
  }

  FlowGraph* graph_;
  DirectChainedHashMap<LoadKeyValueTrait>* map_;
  const intptr_t max_expr_id_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  const GrowableArray<BitVector*>& kill_by_offset_;

  // Per block sets of expression ids for loads that are: incoming (available
  // on the entry), outgoing (available on the exit), generated and killed.
  GrowableArray<BitVector*> in_;
  GrowableArray<BitVector*> out_;
  GrowableArray<BitVector*> gen_;
  GrowableArray<BitVector*> kill_;

  // Per block list of upwards exposed loads.
  GrowableArray<ZoneGrowableArray<Definition*>*> exposed_values_;

  // Per block mappings between expression ids and outgoing definitions that
  // represent those ids.
  GrowableArray<ZoneGrowableArray<Definition*>*> out_values_;

  // List of phis generated during ComputeOutValues and ForwardLoads.
  // Some of these phis might be redundant and thus a separate pass is
  // needed to emit only non-redundant ones.
  GrowableArray<PhiInstr*> phis_;

  // Auxiliary worklist used by redundant phi elimination.
  GrowableArray<PhiInstr*> worklist_;
  BitVector* in_worklist_;

  DISALLOW_COPY_AND_ASSIGN(LoadOptimizer);
};


bool DominatorBasedCSE::Optimize(FlowGraph* graph) {
  bool changed = false;
  if (FLAG_load_cse) {
    GrowableArray<BitVector*> kill_by_offs(10);
    DirectChainedHashMap<LoadKeyValueTrait> map;
    const intptr_t max_expr_id =
        NumberLoadExpressions(graph, &map, &kill_by_offs);
    if (max_expr_id > 0) {
      LoadOptimizer load_optimizer(graph, max_expr_id, &map, kill_by_offs);
      load_optimizer.Optimize();
    }
  }

  DirectChainedHashMap<PointerKeyValueTrait<Instruction> > map;
  changed = OptimizeRecursive(graph, graph->graph_entry(), &map) || changed;

  return changed;
}


bool DominatorBasedCSE::OptimizeRecursive(
    FlowGraph* graph,
    BlockEntryInstr* block,
    DirectChainedHashMap<PointerKeyValueTrait<Instruction> >* map) {
  bool changed = false;
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    if (current->AffectedBySideEffect()) continue;
    Instruction* replacement = map->Lookup(current);
    if (replacement == NULL) {
      map->Insert(current);
      continue;
    }
    // Replace current with lookup result.
    ReplaceCurrentInstruction(&it, current, replacement, graph);
    changed = true;
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i  < num_children - 1) {
      // Copy map.
      DirectChainedHashMap<PointerKeyValueTrait<Instruction> > child_map(*map);
      changed = OptimizeRecursive(graph, child, &child_map) || changed;
    } else {
      // Reuse map for the last child.
      changed = OptimizeRecursive(graph, child, map) || changed;
    }
  }
  return changed;
}


ConstantPropagator::ConstantPropagator(
    FlowGraph* graph,
    const GrowableArray<BlockEntryInstr*>& ignored)
    : FlowGraphVisitor(ignored),
      graph_(graph),
      unknown_(Object::transition_sentinel()),
      non_constant_(Object::sentinel()),
      reachable_(new BitVector(graph->preorder().length())),
      definition_marks_(new BitVector(graph->max_virtual_register_number())),
      block_worklist_(),
      definition_worklist_() {}


void ConstantPropagator::Optimize(FlowGraph* graph) {
  GrowableArray<BlockEntryInstr*> ignored;
  ConstantPropagator cp(graph, ignored);
  cp.Analyze();
  cp.Transform();
}


void ConstantPropagator::OptimizeBranches(FlowGraph* graph) {
  GrowableArray<BlockEntryInstr*> ignored;
  ConstantPropagator cp(graph, ignored);
  cp.VisitBranches();
  cp.Transform();
}


void ConstantPropagator::SetReachable(BlockEntryInstr* block) {
  if (!reachable_->Contains(block->preorder_number())) {
    reachable_->Add(block->preorder_number());
    block_worklist_.Add(block);
  }
}


void ConstantPropagator::SetValue(Definition* definition, const Object& value) {
  // We would like to assert we only go up (toward non-constant) in the lattice.
  //
  // ASSERT(IsUnknown(definition->constant_value()) ||
  //        IsNonConstant(value) ||
  //        (definition->constant_value().raw() == value.raw()));
  //
  // But the final disjunct is not true (e.g., mint or double constants are
  // heap-allocated and so not necessarily pointer-equal on each iteration).
  if (definition->constant_value().raw() != value.raw()) {
    definition->constant_value() = value.raw();
    if (definition->input_use_list() != NULL) {
      ASSERT(definition->HasSSATemp());
      if (!definition_marks_->Contains(definition->ssa_temp_index())) {
        definition_worklist_.Add(definition);
        definition_marks_->Add(definition->ssa_temp_index());
      }
    }
  }
}


// Compute the join of two values in the lattice, assign it to the first.
void ConstantPropagator::Join(Object* left, const Object& right) {
  // Join(non-constant, X) = non-constant
  // Join(X, unknown)      = X
  if (IsNonConstant(*left) || IsUnknown(right)) return;

  // Join(unknown, X)      = X
  // Join(X, non-constant) = non-constant
  if (IsUnknown(*left) || IsNonConstant(right)) {
    *left = right.raw();
    return;
  }

  // Join(X, X) = X
  // TODO(kmillikin): support equality for doubles, mints, etc.
  if (left->raw() == right.raw()) return;

  // Join(X, Y) = non-constant
  *left = non_constant_.raw();
}


// --------------------------------------------------------------------------
// Analysis of blocks.  Called at most once per block.  The block is already
// marked as reachable.  All instructions in the block are analyzed.
void ConstantPropagator::VisitGraphEntry(GraphEntryInstr* block) {
  const GrowableArray<Definition*>& defs = *block->initial_definitions();
  for (intptr_t i = 0; i < defs.length(); ++i) {
    defs[i]->Accept(this);
  }
  ASSERT(ForwardInstructionIterator(block).Done());

  SetReachable(block->normal_entry());
}


void ConstantPropagator::VisitJoinEntry(JoinEntryInstr* block) {
  // Phis are visited when visiting Goto at a predecessor. See VisitGoto.
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitTargetEntry(TargetEntryInstr* block) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitCatchBlockEntry(CatchBlockEntryInstr* block) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitParallelMove(ParallelMoveInstr* instr) {
  // Parallel moves have not yet been inserted in the graph.
  UNREACHABLE();
}


// --------------------------------------------------------------------------
// Analysis of control instructions.  Unconditional successors are
// reachable.  Conditional successors are reachable depending on the
// constant value of the condition.
void ConstantPropagator::VisitReturn(ReturnInstr* instr) {
  // Nothing to do.
}


void ConstantPropagator::VisitThrow(ThrowInstr* instr) {
  // Nothing to do.
}


void ConstantPropagator::VisitReThrow(ReThrowInstr* instr) {
  // Nothing to do.
}


void ConstantPropagator::VisitGoto(GotoInstr* instr) {
  SetReachable(instr->successor());

  // Phi value depends on the reachability of a predecessor. We have
  // to revisit phis every time a predecessor becomes reachable.
  for (PhiIterator it(instr->successor()); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitBranch(BranchInstr* instr) {
  instr->comparison()->Accept(this);

  // The successors may be reachable, but only if this instruction is.  (We
  // might be analyzing it because the constant value of one of its inputs
  // has changed.)
  if (reachable_->Contains(instr->GetBlock()->preorder_number())) {
    const Object& value = instr->comparison()->constant_value();
    if (IsNonConstant(value)) {
      SetReachable(instr->true_successor());
      SetReachable(instr->false_successor());
    } else if (value.raw() == Bool::True().raw()) {
      SetReachable(instr->true_successor());
    } else if (!IsUnknown(value)) {  // Any other constant.
      SetReachable(instr->false_successor());
    }
  }
}


// --------------------------------------------------------------------------
// Analysis of non-definition instructions.  They do not have values so they
// cannot have constant values.
void ConstantPropagator::VisitStoreContext(StoreContextInstr* instr) { }


void ConstantPropagator::VisitChainContext(ChainContextInstr* instr) { }


void ConstantPropagator::VisitCatchEntry(CatchEntryInstr* instr) { }


void ConstantPropagator::VisitCheckStackOverflow(
    CheckStackOverflowInstr* instr) { }


void ConstantPropagator::VisitCheckClass(CheckClassInstr* instr) { }

void ConstantPropagator::VisitGuardField(GuardFieldInstr* instr) { }

void ConstantPropagator::VisitCheckSmi(CheckSmiInstr* instr) { }


void ConstantPropagator::VisitCheckEitherNonSmi(
    CheckEitherNonSmiInstr* instr) { }


void ConstantPropagator::VisitCheckArrayBound(CheckArrayBoundInstr* instr) { }


// --------------------------------------------------------------------------
// Analysis of definitions.  Compute the constant value.  If it has changed
// and the definition has input uses, add the definition to the definition
// worklist so that the used can be processed.
void ConstantPropagator::VisitPhi(PhiInstr* instr) {
  // Compute the join over all the reachable predecessor values.
  JoinEntryInstr* block = instr->block();
  Object& value = Object::ZoneHandle(Unknown());
  for (intptr_t pred_idx = 0; pred_idx < instr->InputCount(); ++pred_idx) {
    if (reachable_->Contains(
            block->PredecessorAt(pred_idx)->preorder_number())) {
      Join(&value,
           instr->InputAt(pred_idx)->definition()->constant_value());
    }
  }
  SetValue(instr, value);
}


void ConstantPropagator::VisitParameter(ParameterInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitPushArgument(PushArgumentInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitAssertAssignable(AssertAssignableInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // We are ignoring the instantiator and instantiator_type_arguments, but
    // still monotonic and safe.
    // TODO(kmillikin): Handle constants.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitAssertBoolean(AssertBooleanInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle assertion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitArgumentDefinitionTest(
    ArgumentDefinitionTestInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitCurrentContext(CurrentContextInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitClosureCall(ClosureCallInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitInstanceCall(InstanceCallInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStaticCall(StaticCallInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitLoadLocal(LoadLocalInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}


void ConstantPropagator::VisitStoreLocal(StoreLocalInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}


void ConstantPropagator::VisitIfThenElse(IfThenElseInstr* instr) {
  ASSERT(Token::IsEqualityOperator(instr->kind()));

  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();

  if (IsNonConstant(left) || IsNonConstant(right)) {
    // TODO(vegorov): incorporate nullability information into the lattice.
    if ((left.IsNull() && instr->right()->Type()->HasDecidableNullability()) ||
        (right.IsNull() && instr->left()->Type()->HasDecidableNullability())) {
      bool result = left.IsNull() ? instr->right()->Type()->IsNull()
                                  : instr->left()->Type()->IsNull();
      if (instr->kind() == Token::kNE_STRICT ||
          instr->kind() == Token::kNE) {
        result = !result;
      }
      SetValue(instr, Smi::Handle(
          Smi::New(result ? instr->if_true() : instr->if_false())));
    } else {
      SetValue(instr, non_constant_);
    }
  } else if (IsConstant(left) && IsConstant(right)) {
    bool result = (left.raw() == right.raw());
    if (instr->kind() == Token::kNE_STRICT ||
        instr->kind() == Token::kNE) {
      result = !result;
    }
    SetValue(instr, Smi::Handle(
        Smi::New(result ? instr->if_true() : instr->if_false())));
  }
}


void ConstantPropagator::VisitStrictCompare(StrictCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();

  if (IsNonConstant(left) || IsNonConstant(right)) {
    // TODO(vegorov): incorporate nullability information into the lattice.
    if ((left.IsNull() && instr->right()->Type()->HasDecidableNullability()) ||
        (right.IsNull() && instr->left()->Type()->HasDecidableNullability())) {
      bool result = left.IsNull() ? instr->right()->Type()->IsNull()
                                  : instr->left()->Type()->IsNull();
      if (instr->kind() == Token::kNE_STRICT) result = !result;
      SetValue(instr, result ? Bool::True() : Bool::False());
    } else {
      SetValue(instr, non_constant_);
    }
  } else if (IsConstant(left) && IsConstant(right)) {
    bool result = (left.raw() == right.raw());
    if (instr->kind() == Token::kNE_STRICT) result = !result;
    SetValue(instr, result ? Bool::True() : Bool::False());
  }
}


static bool CompareIntegers(Token::Kind kind,
                            const Integer& left,
                            const Integer& right) {
  const int result = left.CompareWith(right);
  switch (kind) {
    case Token::kEQ: return (result == 0);
    case Token::kNE: return (result != 0);
    case Token::kLT: return (result < 0);
    case Token::kGT: return (result > 0);
    case Token::kLTE: return (result <= 0);
    case Token::kGTE: return (result >= 0);
    default:
      UNREACHABLE();
      return false;
  }
}


void ConstantPropagator::VisitEqualityCompare(EqualityCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(instr->kind(),
                                          Integer::Cast(left),
                                          Integer::Cast(right));
      SetValue(instr, result ? Bool::True() : Bool::False());
    } else {
      SetValue(instr, non_constant_);
    }
  }
}


void ConstantPropagator::VisitRelationalOp(RelationalOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(instr->kind(),
                                          Integer::Cast(left),
                                          Integer::Cast(right));
      SetValue(instr, result ? Bool::True() : Bool::False());
    } else {
      SetValue(instr, non_constant_);
    }
  }
}


void ConstantPropagator::VisitNativeCall(NativeCallInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStringFromCharCode(
    StringFromCharCodeInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitLoadIndexed(LoadIndexedInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStoreIndexed(StoreIndexedInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitLoadStaticField(LoadStaticFieldInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStoreStaticField(StoreStaticFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitBooleanNegate(BooleanNegateInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    bool val = value.raw() != Bool::True().raw();
    SetValue(instr, val ? Bool::True() : Bool::False());
  }
}


void ConstantPropagator::VisitInstanceOf(InstanceOfInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle instanceof on constants.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitCreateArray(CreateArrayInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitCreateClosure(CreateClosureInstr* instr) {
  // TODO(kmillikin): Treat closures as constants.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitAllocateObject(AllocateObjectInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitAllocateObjectWithBoundsCheck(
    AllocateObjectWithBoundsCheckInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitLoadUntagged(LoadUntaggedInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitLoadField(LoadFieldInstr* instr) {
  if ((instr->recognized_kind() == MethodRecognizer::kObjectArrayLength) &&
      (instr->value()->definition()->IsCreateArray())) {
    const intptr_t length =
        instr->value()->definition()->AsCreateArray()->num_elements();
    const Object& result = Smi::ZoneHandle(Smi::New(length));
    SetValue(instr, result);
    return;
  }

  if (instr->IsImmutableLengthLoad()) {
    ConstantInstr* constant = instr->value()->definition()->AsConstant();
    if (constant != NULL) {
      if (constant->value().IsString()) {
        SetValue(instr, Smi::ZoneHandle(
            Smi::New(String::Cast(constant->value()).Length())));
        return;
      }
      if (constant->value().IsArray()) {
        SetValue(instr, Smi::ZoneHandle(
            Smi::New(Array::Cast(constant->value()).Length())));
        return;
      }
    }
  }
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStoreVMField(StoreVMFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsInstr* instr) {
  const Object& object =
      instr->instantiator()->definition()->constant_value();
  if (IsNonConstant(object)) {
    SetValue(instr, non_constant_);
    return;
  }
  if (IsConstant(object)) {
    const intptr_t len = instr->type_arguments().Length();
    if (instr->type_arguments().IsRawInstantiatedRaw(len) &&
        object.IsNull()) {
      SetValue(instr, object);
      return;
    }
    if (instr->type_arguments().IsUninstantiatedIdentity() &&
        !object.IsNull() &&
        object.IsTypeArguments() &&
        (TypeArguments::Cast(object).Length() == len)) {
      SetValue(instr, object);
      return;
    }
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitExtractConstructorTypeArguments(
    ExtractConstructorTypeArgumentsInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitExtractConstructorInstantiator(
    ExtractConstructorInstantiatorInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitAllocateContext(AllocateContextInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitCloneContext(CloneContextInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitBinarySmiOp(BinarySmiOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsSmi() && right.IsSmi()) {
      const Smi& left_smi = Smi::Cast(left);
      const Smi& right_smi = Smi::Cast(right);
      switch (instr->op_kind()) {
        case Token::kADD:
        case Token::kSUB:
        case Token::kMUL:
        case Token::kTRUNCDIV:
        case Token::kMOD: {
          const Object& result = Integer::ZoneHandle(
              left_smi.ArithmeticOp(instr->op_kind(), right_smi));
          SetValue(instr, result);
          break;
        }
        case Token::kSHL:
        case Token::kSHR: {
          const Object& result = Integer::ZoneHandle(
              left_smi.ShiftOp(instr->op_kind(), right_smi));
          SetValue(instr, result);
          break;
        }
        case Token::kBIT_AND:
        case Token::kBIT_OR:
        case Token::kBIT_XOR: {
          const Object& result = Integer::ZoneHandle(
              left_smi.BitOp(instr->op_kind(), right_smi));
          SetValue(instr, result);
          break;
        }
        default:
          // TODO(kmillikin): support other smi operations.
          SetValue(instr, non_constant_);
      }
    } else {
      // TODO(kmillikin): support other types.
      SetValue(instr, non_constant_);
    }
  }
}


void ConstantPropagator::VisitBoxInteger(BoxIntegerInstr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitUnboxInteger(UnboxIntegerInstr* instr) {
  // TODO(kmillikin): Handle unbox operation.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitBinaryMintOp(
    BinaryMintOpInstr* instr) {
  // TODO(kmillikin): Handle binary operations.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitShiftMintOp(
    ShiftMintOpInstr* instr) {
  // TODO(kmillikin): Handle shift operations.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitUnaryMintOp(
    UnaryMintOpInstr* instr) {
  // TODO(kmillikin): Handle unary operations.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitUnarySmiOp(UnarySmiOpInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle unary operations.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitSmiToDouble(SmiToDoubleInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitDoubleToInteger(DoubleToIntegerInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitDoubleToSmi(DoubleToSmiInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitDoubleToDouble(DoubleToDoubleInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitInvokeMathCFunction(
    InvokeMathCFunctionInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitConstant(ConstantInstr* instr) {
  SetValue(instr, instr->value());
}


void ConstantPropagator::VisitConstraint(ConstraintInstr* instr) {
  // Should not be used outside of range analysis.
  UNREACHABLE();
}


void ConstantPropagator::VisitBinaryDoubleOp(
    BinaryDoubleOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle binary operation.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBinaryFloat32x4Op(
    BinaryFloat32x4OpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle binary operation.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitMathSqrt(MathSqrtInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle sqrt.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitUnboxDouble(UnboxDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxDouble(BoxDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitUnboxFloat32x4(UnboxFloat32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxFloat32x4(BoxFloat32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::Analyze() {
  GraphEntryInstr* entry = graph_->graph_entry();
  reachable_->Add(entry->preorder_number());
  block_worklist_.Add(entry);

  while (true) {
    if (block_worklist_.is_empty()) {
      if (definition_worklist_.is_empty()) break;
      Definition* definition = definition_worklist_.RemoveLast();
      definition_marks_->Remove(definition->ssa_temp_index());
      Value* use = definition->input_use_list();
      while (use != NULL) {
        use->instruction()->Accept(this);
        use = use->next_use();
      }
    } else {
      BlockEntryInstr* block = block_worklist_.RemoveLast();
      block->Accept(this);
    }
  }
}


void ConstantPropagator::VisitBranches() {
  GraphEntryInstr* entry = graph_->graph_entry();
  reachable_->Add(entry->preorder_number());
  // TODO(fschneider): Handle CatchEntry.
  reachable_->Add(entry->normal_entry()->preorder_number());
  block_worklist_.Add(entry->normal_entry());

  while (!block_worklist_.is_empty()) {
    BlockEntryInstr* block = block_worklist_.RemoveLast();
    Instruction* last = block->last_instruction();
    if (last->IsGoto()) {
      SetReachable(last->AsGoto()->successor());
    } else if (last->IsBranch()) {
      BranchInstr* branch = last->AsBranch();
      // The current block must be reachable.
      ASSERT(reachable_->Contains(branch->GetBlock()->preorder_number()));
      if (branch->constant_target() != NULL) {
        // Found constant target computed by range analysis.
        if (branch->constant_target() == branch->true_successor()) {
          SetReachable(branch->true_successor());
        } else {
          ASSERT(branch->constant_target() == branch->false_successor());
          SetReachable(branch->false_successor());
        }
      } else {
        // No new information: Assume both targets are reachable.
        SetReachable(branch->true_successor());
        SetReachable(branch->false_successor());
      }
    }
  }
}


void ConstantPropagator::Transform() {
  if (FLAG_trace_constant_propagation) {
    OS::Print("\n==== Before constant propagation ====\n");
    FlowGraphPrinter printer(*graph_);
    printer.PrintBlocks();
  }

  GrowableArray<PhiInstr*> redundant_phis(10);

  // We will recompute dominators, block ordering, block ids, block last
  // instructions, previous pointers, predecessors, etc. after eliminating
  // unreachable code.  We do not maintain those properties during the
  // transformation.
  for (BlockIterator b = graph_->reverse_postorder_iterator();
       !b.Done();
       b.Advance()) {
    BlockEntryInstr* block = b.Current();
    JoinEntryInstr* join = block->AsJoinEntry();
    if (!reachable_->Contains(block->preorder_number())) {
      if (FLAG_trace_constant_propagation) {
        OS::Print("Unreachable B%"Pd"\n", block->block_id());
      }
      // Remove all uses in unreachable blocks.
      if (join != NULL) {
        for (PhiIterator it(join); !it.Done(); it.Advance()) {
          it.Current()->UnuseAllInputs();
        }
      }
      block->UnuseAllInputs();
      for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
        it.Current()->UnuseAllInputs();
      }
      continue;
    }

    if (join != NULL) {
      // Remove phi inputs corresponding to unreachable predecessor blocks.
      // Predecessors will be recomputed (in block id order) after removing
      // unreachable code so we merely have to keep the phi inputs in order.
      ZoneGrowableArray<PhiInstr*>* phis = join->phis();
      if ((phis != NULL) && !phis->is_empty()) {
        intptr_t pred_count = join->PredecessorCount();
        intptr_t live_count = 0;
        for (intptr_t pred_idx = 0; pred_idx < pred_count; ++pred_idx) {
          if (reachable_->Contains(
                  join->PredecessorAt(pred_idx)->preorder_number())) {
            if (live_count < pred_idx) {
              for (PhiIterator it(join); !it.Done(); it.Advance()) {
                PhiInstr* phi = it.Current();
                ASSERT(phi != NULL);
                phi->SetInputAt(live_count, phi->InputAt(pred_idx));
              }
            }
            ++live_count;
          } else {
            for (PhiIterator it(join); !it.Done(); it.Advance()) {
              PhiInstr* phi = it.Current();
              ASSERT(phi != NULL);
              phi->InputAt(pred_idx)->RemoveFromUseList();
            }
          }
        }
        if (live_count < pred_count) {
          intptr_t to_idx = 0;
          for (intptr_t from_idx = 0; from_idx < phis->length(); ++from_idx) {
            PhiInstr* phi = (*phis)[from_idx];
            ASSERT(phi != NULL);
            if (FLAG_remove_redundant_phis && (live_count == 1)) {
              Value* input = phi->InputAt(0);
              phi->ReplaceUsesWith(input->definition());
              input->RemoveFromUseList();
            } else {
              phi->inputs_.TruncateTo(live_count);
              (*phis)[to_idx++] = phi;
            }
          }
          if (to_idx == 0) {
            join->phis_ = NULL;
          } else {
            phis->TruncateTo(to_idx);
          }
        }
      }
    }

    for (ForwardInstructionIterator i(block); !i.Done(); i.Advance()) {
      Definition* defn = i.Current()->AsDefinition();
      // Replace constant-valued instructions without observable side
      // effects.  Do this for smis only to avoid having to copy other
      // objects into the heap's old generation.
      if ((defn != NULL) &&
          IsConstant(defn->constant_value()) &&
          (defn->constant_value().IsSmi() || defn->constant_value().IsOld()) &&
          !defn->IsConstant() &&
          !defn->IsPushArgument() &&
          !defn->IsStoreIndexed() &&
          !defn->IsStoreInstanceField() &&
          !defn->IsStoreStaticField() &&
          !defn->IsStoreVMField()) {
        if (FLAG_trace_constant_propagation) {
          OS::Print("Constant v%"Pd" = %s\n",
                    defn->ssa_temp_index(),
                    defn->constant_value().ToCString());
        }
        defn->ReplaceWith(new ConstantInstr(defn->constant_value()), &i);
      }
    }

    // Replace branches where one target is unreachable with jumps.
    BranchInstr* branch = block->last_instruction()->AsBranch();
    if (branch != NULL) {
      TargetEntryInstr* if_true = branch->true_successor();
      TargetEntryInstr* if_false = branch->false_successor();
      JoinEntryInstr* join = NULL;
      Instruction* next = NULL;

      if (!reachable_->Contains(if_true->preorder_number())) {
        ASSERT(reachable_->Contains(if_false->preorder_number()));
        ASSERT(if_false->parallel_move() == NULL);
        ASSERT(if_false->loop_info() == NULL);
        join = new JoinEntryInstr(if_false->block_id(), if_false->try_index());
        join->InheritDeoptTarget(if_false);
        if_false->UnuseAllInputs();
        next = if_false->next();
      } else if (!reachable_->Contains(if_false->preorder_number())) {
        ASSERT(if_true->parallel_move() == NULL);
        ASSERT(if_true->loop_info() == NULL);
        join = new JoinEntryInstr(if_true->block_id(), if_true->try_index());
        join->InheritDeoptTarget(if_true);
        if_true->UnuseAllInputs();
        next = if_true->next();
      }

      if (join != NULL) {
        // Replace the branch with a jump to the reachable successor.
        // Drop the comparison, which does not have side effects as long
        // as it is a strict compare (the only one we can determine is
        // constant with the current analysis).
        GotoInstr* jump = new GotoInstr(join);
        jump->InheritDeoptTarget(branch);

        Instruction* previous = branch->previous();
        branch->set_previous(NULL);
        previous->LinkTo(jump);

        // Replace the false target entry with the new join entry. We will
        // recompute the dominators after this pass.
        join->LinkTo(next);
        branch->UnuseAllInputs();
      }
    }
  }

  graph_->DiscoverBlocks();
  GrowableArray<BitVector*> dominance_frontier;
  graph_->ComputeDominators(&dominance_frontier);

  if (FLAG_trace_constant_propagation) {
    OS::Print("\n==== After constant propagation ====\n");
    FlowGraphPrinter printer(*graph_);
    printer.PrintBlocks();
  }
}


// Returns true if the given phi has a single input use and
// is used in the environments either at the corresponding block entry or
// at the same instruction where input use is.
static bool PhiHasSingleUse(PhiInstr* phi, Value* use) {
  if ((use->next_use() != NULL) || (phi->input_use_list() != use)) {
    return false;
  }

  BlockEntryInstr* block = phi->block();
  for (Value* env_use = phi->env_use_list();
       env_use != NULL;
       env_use = env_use->next_use()) {
    if ((env_use->instruction() != block) &&
        (env_use->instruction() != use->instruction())) {
      return false;
    }
  }

  return true;
}


bool BranchSimplifier::Match(JoinEntryInstr* block) {
  // Match the pattern of a branch on a comparison whose left operand is a
  // phi from the same block, and whose right operand is a constant.
  //
  //   Branch(Comparison(kind, Phi, Constant))
  //
  // These are the branches produced by inlining in a test context.  Also,
  // the phi and the constant have no other uses so they can simply be
  // eliminated.  The block has no other phis and no instructions
  // intervening between the phi, constant, and branch so the block can
  // simply be eliminated.
  BranchInstr* branch = block->last_instruction()->AsBranch();
  ASSERT(branch != NULL);
  ComparisonInstr* comparison = branch->comparison();
  Value* left = comparison->left();
  PhiInstr* phi = left->definition()->AsPhi();
  Value* right = comparison->right();
  ConstantInstr* constant = right->definition()->AsConstant();
  return (phi != NULL) &&
      (constant != NULL) &&
      (phi->GetBlock() == block) &&
      PhiHasSingleUse(phi, left) &&
      constant->HasOnlyUse(right) &&
      (block->next() == constant) &&
      (constant->next() == branch) &&
      (block->phis()->length() == 1);
}


JoinEntryInstr* BranchSimplifier::ToJoinEntry(TargetEntryInstr* target) {
  // Convert a target block into a join block.  Branches will be duplicated
  // so the former true and false targets become joins of the control flows
  // from all the duplicated branches.
  JoinEntryInstr* join =
      new JoinEntryInstr(target->block_id(), target->try_index());
  join->InheritDeoptTarget(target);
  join->LinkTo(target->next());
  join->set_last_instruction(target->last_instruction());
  target->UnuseAllInputs();
  return join;
}


ConstantInstr* BranchSimplifier::CloneConstant(FlowGraph* flow_graph,
                                               ConstantInstr* constant) {
  ConstantInstr* new_constant = new ConstantInstr(constant->value());
  new_constant->set_ssa_temp_index(flow_graph->alloc_ssa_temp_index());
  return new_constant;
}


BranchInstr* BranchSimplifier::CloneBranch(BranchInstr* branch,
                                           Value* left,
                                           Value* right) {
  ComparisonInstr* comparison = branch->comparison();
  ComparisonInstr* new_comparison = NULL;
  if (comparison->IsStrictCompare()) {
    new_comparison = new StrictCompareInstr(comparison->kind(), left, right);
  } else if (comparison->IsEqualityCompare()) {
    EqualityCompareInstr* equality_compare = comparison->AsEqualityCompare();
    EqualityCompareInstr* new_equality_compare =
        new EqualityCompareInstr(equality_compare->token_pos(),
                                 comparison->kind(),
                                 left,
                                 right);
    new_equality_compare->set_ic_data(equality_compare->ic_data());
    new_comparison = new_equality_compare;
  } else {
    ASSERT(comparison->IsRelationalOp());
    RelationalOpInstr* relational_op = comparison->AsRelationalOp();
    RelationalOpInstr* new_relational_op =
        new RelationalOpInstr(relational_op->token_pos(),
                              comparison->kind(),
                              left,
                              right);
    new_relational_op->set_ic_data(relational_op->ic_data());
    new_comparison = new_relational_op;
  }
  return new BranchInstr(new_comparison, branch->is_checked());
}


void BranchSimplifier::Simplify(FlowGraph* flow_graph) {
  // Optimize some branches that test the value of a phi.  When it is safe
  // to do so, push the branch to each of the predecessor blocks.  This is
  // an optimization when (a) it can avoid materializing a boolean object at
  // the phi only to test its value, and (b) it can expose opportunities for
  // constant propagation and unreachable code elimination.  This
  // optimization is intended to run after inlining which creates
  // opportunities for optimization (a) and before constant folding which
  // can perform optimization (b).

  // Begin with a worklist of join blocks ending in branches.  They are
  // candidates for the pattern below.
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  GrowableArray<BlockEntryInstr*> worklist(postorder.length());
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    if (block->IsJoinEntry() && block->last_instruction()->IsBranch()) {
      worklist.Add(block);
    }
  }

  // Rewrite until no more instance of the pattern exists.
  bool changed = false;
  while (!worklist.is_empty()) {
    // All blocks in the worklist are join blocks (ending with a branch).
    JoinEntryInstr* block = worklist.RemoveLast()->AsJoinEntry();
    ASSERT(block != NULL);

    if (Match(block)) {
      changed = true;

      // The branch will be copied and pushed to all the join's
      // predecessors.  Convert the true and false target blocks into join
      // blocks to join the control flows from all of the true
      // (respectively, false) targets of the copied branches.
      //
      // The converted join block will have no phis, so it cannot be another
      // instance of the pattern.  There is thus no need to add it to the
      // worklist.
      BranchInstr* branch = block->last_instruction()->AsBranch();
      ASSERT(branch != NULL);
      JoinEntryInstr* join_true = ToJoinEntry(branch->true_successor());
      JoinEntryInstr* join_false = ToJoinEntry(branch->false_successor());

      ComparisonInstr* comparison = branch->comparison();
      PhiInstr* phi = comparison->left()->definition()->AsPhi();
      ConstantInstr* constant = comparison->right()->definition()->AsConstant();
      ASSERT(constant != NULL);
      // Copy the constant and branch and push it to all the predecessors.
      for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
        GotoInstr* old_goto =
            block->PredecessorAt(i)->last_instruction()->AsGoto();
        ASSERT(old_goto != NULL);

        // Insert a copy of the constant in all the predecessors.
        ConstantInstr* new_constant = CloneConstant(flow_graph, constant);
        new_constant->InsertBefore(old_goto);

        // Replace the goto in each predecessor with a rewritten branch,
        // rewritten to use the corresponding phi input instead of the phi.
        Value* new_left = phi->InputAt(i)->Copy();
        Value* new_right = new Value(new_constant);
        BranchInstr* new_branch = CloneBranch(branch, new_left, new_right);
        new_branch->InheritDeoptTarget(old_goto);
        new_branch->InsertBefore(old_goto);
        new_branch->set_next(NULL);  // Detaching the goto from the graph.
        old_goto->UnuseAllInputs();

        // Update the predecessor block.  We may have created another
        // instance of the pattern so add it to the worklist if necessary.
        BlockEntryInstr* branch_block = new_branch->GetBlock();
        branch_block->set_last_instruction(new_branch);
        if (branch_block->IsJoinEntry()) worklist.Add(branch_block);

        // Connect the branch to the true and false joins, via empty target
        // blocks.
        TargetEntryInstr* true_target =
            new TargetEntryInstr(flow_graph->max_block_id() + 1,
                                 block->try_index());
        true_target->InheritDeoptTarget(join_true);
        TargetEntryInstr* false_target =
            new TargetEntryInstr(flow_graph->max_block_id() + 2,
                                 block->try_index());
        false_target->InheritDeoptTarget(join_false);
        flow_graph->set_max_block_id(flow_graph->max_block_id() + 2);
        *new_branch->true_successor_address() = true_target;
        *new_branch->false_successor_address() = false_target;
        GotoInstr* goto_true = new GotoInstr(join_true);
        goto_true->InheritDeoptTarget(join_true);
        true_target->LinkTo(goto_true);
        true_target->set_last_instruction(goto_true);
        GotoInstr* goto_false = new GotoInstr(join_false);
        goto_false->InheritDeoptTarget(join_false);
        false_target->LinkTo(goto_false);
        false_target->set_last_instruction(goto_false);
      }
      // When all predecessors have been rewritten, the original block is
      // unreachable from the graph.
      phi->UnuseAllInputs();
      branch->UnuseAllInputs();
      block->UnuseAllInputs();
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}


static bool IsTrivialBlock(BlockEntryInstr* block, Definition* defn) {
  return (block->IsTargetEntry() && (block->PredecessorCount() == 1)) &&
    ((block->next() == block->last_instruction()) ||
     ((block->next() == defn) && (defn->next() == block->last_instruction())));
}


static void EliminateTrivialBlock(BlockEntryInstr* block,
                                  Definition* instr,
                                  IfThenElseInstr* before) {
  block->UnuseAllInputs();
  block->last_instruction()->UnuseAllInputs();

  if ((block->next() == instr) &&
      (instr->next() == block->last_instruction())) {
    before->previous()->LinkTo(instr);
    instr->LinkTo(before);
  }
}


void IfConverter::Simplify(FlowGraph* flow_graph) {
  if (!IfThenElseInstr::IsSupported()) {
    return;
  }

  bool changed = false;

  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    JoinEntryInstr* join = block->AsJoinEntry();

    // Detect diamond control flow pattern which materializes a value depending
    // on the result of the comparison:
    //
    // B_pred:
    //   ...
    //   Branch if COMP goto (B_pred1, B_pred2)
    // B_pred1: -- trivial block that contains at most one definition
    //   v1 = Constant(...)
    //   goto B_block
    // B_pred2: -- trivial block that contains at most one definition
    //   v2 = Constant(...)
    //   goto B_block
    // B_block:
    //   v3 = phi(v1, v2) -- single phi
    //
    // and replace it with
    //
    // Ba:
    //   v3 = IfThenElse(COMP ? v1 : v2)
    //
    if ((join != NULL) &&
        (join->phis() != NULL) &&
        (join->phis()->length() == 1) &&
        (block->PredecessorCount() == 2)) {
      BlockEntryInstr* pred1 = block->PredecessorAt(0);
      BlockEntryInstr* pred2 = block->PredecessorAt(1);

      PhiInstr* phi = (*join->phis())[0];
      Value* v1 = phi->InputAt(0);
      Value* v2 = phi->InputAt(1);

      if (IsTrivialBlock(pred1, v1->definition()) &&
          IsTrivialBlock(pred2, v2->definition()) &&
          (pred1->PredecessorAt(0) == pred2->PredecessorAt(0))) {
        BlockEntryInstr* pred = pred1->PredecessorAt(0);
        BranchInstr* branch = pred->last_instruction()->AsBranch();
        ComparisonInstr* comparison = branch->comparison();

        // Check if the platform supports efficient branchless IfThenElseInstr
        // for the given combination of comparison and values flowing from
        // false and true paths.
        if (IfThenElseInstr::Supports(comparison, v1, v2)) {
          Value* if_true = (pred1 == branch->true_successor()) ? v1 : v2;
          Value* if_false = (pred2 == branch->true_successor()) ? v1 : v2;

          IfThenElseInstr* if_then_else = new IfThenElseInstr(
              comparison->kind(),
              comparison->InputAt(0)->Copy(),
              comparison->InputAt(1)->Copy(),
              if_true->Copy(),
              if_false->Copy());
          flow_graph->InsertBefore(branch,
                                   if_then_else,
                                   NULL,
                                   Definition::kValue);

          phi->ReplaceUsesWith(if_then_else);

          // Connect IfThenElseInstr to the first instruction in the merge block
          // effectively eliminating diamond control flow.
          // Current block as well as pred1 and pred2 blocks are no longer in
          // the graph at this point.
          if_then_else->LinkTo(join->next());
          pred->set_last_instruction(join->last_instruction());

          // Resulting block must inherit block id from the eliminated current
          // block to guarantee that ordering of phi operands in its successor
          // stays consistent.
          pred->set_block_id(block->block_id());

          // If v1 and v2 were defined inside eliminated blocks pred1/pred2
          // move them out to the place before inserted IfThenElse instruction.
          EliminateTrivialBlock(pred1, v1->definition(), if_then_else);
          EliminateTrivialBlock(pred2, v2->definition(), if_then_else);

          // Update use lists to reflect changes in the graph.
          phi->UnuseAllInputs();
          branch->UnuseAllInputs();

          // The graph has changed. Recompute dominators and block orders after
          // this pass is finished.
          changed = true;
        }
      }
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}


}  // namespace dart
