// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

DECLARE_FLAG(bool, eliminate_type_checks);
DECLARE_FLAG(bool, enable_type_checks);
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DECLARE_FLAG(bool, trace_type_check_elimination);
DEFINE_FLAG(bool, use_cha, true, "Use class hierarchy analysis.");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool, trace_constant_propagation, false,
            "Print constant propagation and useless code elimination.");
DEFINE_FLAG(bool, array_bounds_check_elimination, true,
            "Eliminate redundant bounds checks.");


void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


// Attempts to convert an instance call (IC call) using propagated class-ids,
// e.g., receiver class id.
void FlowGraphOptimizer::ApplyClassIds() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      if (it.Current()->IsInstanceCall()) {
        InstanceCallInstr* call = it.Current()->AsInstanceCall();
        if (call->HasICData()) {
          if (TryCreateICData(call)) {
            VisitInstanceCall(call);
          }
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
    intptr_t cid = call->ArgumentAt(i)->value()->ResultCid();
    class_ids.Add(cid);
  }
  // TODO(srdjan): Test for other class_ids > 1.
  if (class_ids.length() != 1) return false;
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


static void ReplaceCurrentInstruction(ForwardInstructionIterator* it,
                                      Instruction* current,
                                      Instruction* replacement) {
  if ((replacement != NULL) && current->IsDefinition()) {
    Definition* current_defn = current->AsDefinition();
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != NULL);
    current_defn->ReplaceUsesWith(replacement_defn);

    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    ASSERT(!current->IsDefinition() ||
           ((current->AsDefinition()->input_use_list() == NULL) &&
            (current->AsDefinition()->env_use_list() == NULL)));
    if (current->IsDefinition()) {
      OS::Print("Removing v%"Pd".\n",
                current->AsDefinition()->ssa_temp_index());
    } else {
      OS::Print("Removing %s\n", current->DebugName());
    }
  }
  it->RemoveCurrentFromGraph();
}


void FlowGraphOptimizer::OptimizeComputations() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      Instruction* replacement = current->Canonicalize();
      if (replacement != current) {
        // For non-definitions Canonicalize should return either NULL or
        // this.
        ASSERT((replacement == NULL) || current->IsDefinition());
        ReplaceCurrentInstruction(&it, current, replacement);
      }
    }
  }
}


void FlowGraphOptimizer::InsertConversion(Representation from,
                                          Representation to,
                                          Instruction* instr,
                                          Value* use,
                                          Definition* def,
                                          Instruction* deopt_target) {
  Definition* converted = NULL;
  if ((from == kTagged) && (to == kUnboxedMint)) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT((deopt_target != NULL) || (def->GetPropagatedCid() == kDoubleCid));
    converted = new UnboxIntegerInstr(new Value(def), deopt_id);
  } else if ((from == kUnboxedMint) && (to == kTagged)) {
    converted = new BoxIntegerInstr(new Value(def));
  } else if (from == kUnboxedMint && to == kUnboxedDouble) {
    // Convert by boxing/unboxing.
    // TODO(fschneider): Implement direct unboxed mint-to-double conversion.
    BoxIntegerInstr* boxed = new BoxIntegerInstr(new Value(def));
    InsertBefore(instr, boxed, NULL, Definition::kValue);
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new UnboxDoubleInstr(new Value(boxed), deopt_id);
  } else if ((from == kUnboxedDouble) && (to == kTagged)) {
    converted = new BoxDoubleInstr(new Value(def), NULL);
  } else if ((from == kTagged) && (to == kUnboxedDouble)) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT((deopt_target != NULL) || (def->GetPropagatedCid() == kDoubleCid));
    converted = new UnboxDoubleInstr(new Value(def), deopt_id);
  }
  ASSERT(converted != NULL);
  InsertBefore(instr, converted, use->instruction()->env(),
               Definition::kValue);
  use->set_definition(converted);
}


void FlowGraphOptimizer::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  for (Value* use = def->input_use_list();
       use != NULL;
       use = use->next_use()) {
    const Representation to_rep =
        use->instruction()->RequiredInputRepresentation(use->use_index());
    if (from_rep == to_rep) {
      continue;
    }

    Instruction* deopt_target = NULL;
    Instruction* instr = use->instruction();
    if (instr->IsPhi()) {
      if (!instr->AsPhi()->is_alive()) continue;

      // For phis conversions have to be inserted in the predecessor.
      const BlockEntryInstr* pred =
          instr->AsPhi()->block()->PredecessorAt(use->use_index());
      instr = pred->last_instruction();
    } else {
      deopt_target = instr;
    }

    InsertConversion(from_rep, to_rep, instr, use, def, deopt_target);
  }
}


void FlowGraphOptimizer::SelectRepresentations() {
  // Convervatively unbox all phis that were proven to be of type Double.
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    JoinEntryInstr* join_entry = block_order_[i]->AsJoinEntry();
    if (join_entry == NULL) continue;

    if (join_entry->phis() != NULL) {
      for (intptr_t i = 0; i < join_entry->phis()->length(); ++i) {
        PhiInstr* phi = (*join_entry->phis())[i];
        if (phi == NULL) continue;
        if (phi->GetPropagatedCid() == kDoubleCid) {
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
    if ((join_entry != NULL) && (join_entry->phis() != NULL)) {
      for (intptr_t i = 0; i < join_entry->phis()->length(); ++i) {
        PhiInstr* phi = (*join_entry->phis())[i];
        if ((phi != NULL) && (phi->is_alive())) {
          InsertConversionsFor(phi);
        }
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


static bool ICDataHasReceiverClassId(const ICData& ic_data, intptr_t class_id) {
  ASSERT(ic_data.num_args_tested() > 0);
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    const intptr_t test_class_id = ic_data.GetReceiverClassIdAt(i);
    if (test_class_id == class_id) {
      return true;
    }
  }
  return false;
}


static bool ICDataHasReceiverArgumentClassIds(const ICData& ic_data,
                                              intptr_t receiver_class_id,
                                              intptr_t argument_class_id) {
  ASSERT(receiver_class_id != kIllegalCid);
  ASSERT(argument_class_id != kIllegalCid);
  if (ic_data.num_args_tested() != 2) return false;

  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
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
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
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
      && ICDataHasReceiverClassId(ic_data, kSmiCid);
}


static bool HasOnlySmiOrMint(const ICData& ic_data) {
  if (ic_data.NumberOfChecks() == 1) {
    return ICDataHasReceiverClassId(ic_data, kSmiCid)
        || ICDataHasReceiverClassId(ic_data, kMintCid);
  }
  return (ic_data.NumberOfChecks() == 2)
      && ICDataHasReceiverClassId(ic_data, kSmiCid)
      && ICDataHasReceiverClassId(ic_data, kMintCid);
}


static bool HasOnlyTwoSmis(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1) &&
      ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid);
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
      && ICDataHasReceiverClassId(ic_data, kDoubleCid);
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


static void RemovePushArguments(InstanceCallInstr* call) {
  // Remove original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->ArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
}


static void RemovePushArguments(StaticCallInstr* call) {
  // Remove original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->ArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
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


void FlowGraphOptimizer::AddCheckClass(InstanceCallInstr* call,
                                       Value* value) {
  // Type propagation has not run yet, we cannot eliminate the check.
  const ICData& unary_checks =
      ICData::ZoneHandle(call->ic_data()->AsUnaryClassChecks());
  Instruction* check = NULL;
  if ((unary_checks.NumberOfChecks() == 1) &&
      (unary_checks.GetReceiverClassIdAt(0) == kSmiCid)) {
    check = new CheckSmiInstr(value, call->deopt_id());
  } else {
    check = new CheckClassInstr(value, call->deopt_id(), unary_checks);
  }
  InsertBefore(call, check, call->env(), Definition::kEffect);
}


static bool ArgIsAlwaysSmi(const ICData& ic_data, intptr_t arg_n) {
  ASSERT(ic_data.num_args_tested() > arg_n);
  if (ic_data.NumberOfChecks() == 0) return false;
  GrowableArray<intptr_t> class_ids;
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    ic_data.GetCheckAt(i, &class_ids, &target);
    if (class_ids[arg_n] != kSmiCid) return false;
  }
  return true;
}


// Returns array classid to load from, array and idnex value

intptr_t FlowGraphOptimizer::PrepareIndexedOp(InstanceCallInstr* call,
                                              intptr_t class_id,
                                              Value** array,
                                              Value** index) {
  *array = call->ArgumentAt(0)->value();
  *index = call->ArgumentAt(1)->value();
  // Insert class check and index smi checks and attach a copy of the
  // original environment because the operation can still deoptimize.
  AddCheckClass(call, (*array)->Copy());
  InsertBefore(call,
               new CheckSmiInstr((*index)->Copy(), call->deopt_id()),
               call->env(),
               Definition::kEffect);
  // If both index and array are constants, then the bound check always
  // succeeded.
  // TODO(srdjan): Remove once constant propagation lands.
  if (!((*array)->BindsToConstant() && (*index)->BindsToConstant())) {
    // Insert array bounds check.
    InsertBefore(call,
                 new CheckArrayBoundInstr((*array)->Copy(),
                                          (*index)->Copy(),
                                          class_id,
                                          call),
                 call->env(),
                 Definition::kEffect);
  }
  if (class_id == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements =
        new LoadFieldInstr((*array)->Copy(),
                           GrowableObjectArray::data_offset(),
                           Type::ZoneHandle(Type::DynamicType()));
    elements->set_result_cid(kArrayCid);
    InsertBefore(call, elements, NULL, Definition::kValue);
    *array = new Value(elements);
    return kArrayCid;
  }
  return class_id;
}


bool FlowGraphOptimizer::TryReplaceWithStoreIndexed(InstanceCallInstr* call) {
  const intptr_t class_id = ReceiverClassId(call);
  ICData& value_check = ICData::ZoneHandle();
  switch (class_id) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
      // Acceptable store index classes.
      break;
    case kFloat32ArrayCid:
    case kFloat64ArrayCid: {
      // Check that value is always double.
      value_check = call->ic_data()->AsUnaryClassChecksForArgNr(2);
      if ((value_check.NumberOfChecks() != 1) ||
          (value_check.GetReceiverClassIdAt(0) != kDoubleCid)) {
        return false;
      }
      break;
    }
    default:
      // TODO(fschneider): Add support for other array types.
      return false;
  }

  if (FLAG_enable_type_checks) {
    Value* array = call->ArgumentAt(0)->value();
    Value* value = call->ArgumentAt(2)->value();
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const Function& target =
        Function::ZoneHandle(call->ic_data()->GetTargetAt(0));
    const AbstractType& value_type =
        AbstractType::ZoneHandle(target.ParameterTypeAt(2));
    Value* instantiator = NULL;
    Value* type_args = NULL;
    switch (class_id) {
      case kArrayCid:
      case kGrowableObjectArrayCid: {
        const Class& instantiator_class = Class::Handle(target.Owner());
        intptr_t type_arguments_instance_field_offset =
            instantiator_class.type_arguments_instance_field_offset();
        LoadFieldInstr* load_type_args =
            new LoadFieldInstr(array->Copy(),
                               type_arguments_instance_field_offset,
                               Type::ZoneHandle());  // No type.
        InsertBefore(call, load_type_args, NULL, Definition::kValue);
        instantiator = array->Copy();
        type_args = new Value(load_type_args);
        break;
      }
      case kFloat32ArrayCid:
      case kFloat64ArrayCid: {
        ConstantInstr* null_constant = new ConstantInstr(Object::ZoneHandle());
        InsertBefore(call, null_constant, NULL, Definition::kValue);
        instantiator = new Value(null_constant);
        type_args = new Value(null_constant);
        ASSERT(value_type.IsDoubleType());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      default:
        // TODO(fschneider): Add support for other array types.
        UNREACHABLE();
    }
    AssertAssignableInstr* assert_value =
        new AssertAssignableInstr(call->token_pos(),
                                  value->Copy(),
                                  instantiator,
                                  type_args,
                                  value_type,
                                  String::ZoneHandle(Symbols::New("value")));
    InsertBefore(call, assert_value, NULL, Definition::kValue);
  }

  Value* array = NULL;
  Value* index = NULL;
  intptr_t array_cid = PrepareIndexedOp(call, class_id, &array, &index);
  Value* value = call->ArgumentAt(2)->value();
  // Check if store barrier is needed.
  bool needs_store_barrier = true;
  if ((class_id == kFloat32ArrayCid) || (class_id == kFloat64ArrayCid)) {
    ASSERT(!value_check.IsNull());
    InsertBefore(call,
                 new CheckClassInstr(value->Copy(),
                                     call->deopt_id(),
                                     value_check),
                 call->env(),
                 Definition::kEffect);
    needs_store_barrier = false;
  } else if (ArgIsAlwaysSmi(*call->ic_data(), 2)) {
    InsertBefore(call,
                 new CheckSmiInstr(value->Copy(), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    needs_store_barrier = false;
  }

  Definition* array_op =
      new StoreIndexedInstr(array, index, value,
                            needs_store_barrier, array_cid, call->deopt_id());
  call->ReplaceWith(array_op, current_iterator());
  RemovePushArguments(call);
  return true;
}



bool FlowGraphOptimizer::TryReplaceWithLoadIndexed(InstanceCallInstr* call) {
  const intptr_t class_id = ReceiverClassId(call);
  switch (class_id) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kGrowableObjectArrayCid:
    case kFloat32ArrayCid:
    case kFloat64ArrayCid:
      // Acceptable load index classes.
      break;
    default:
      return false;
  }
  Value* array = NULL;
  Value* index = NULL;
  intptr_t array_cid = PrepareIndexedOp(call, class_id, &array, &index);
  Definition* array_op = new LoadIndexedInstr(array, index, array_cid);
  call->ReplaceWith(array_op, current_iterator());
  RemovePushArguments(call);
  return true;
}


void FlowGraphOptimizer::InsertBefore(Instruction* next,
                                      Instruction* instr,
                                      Environment* env,
                                      Definition::UseKind use_kind) {
  if (env != NULL) env->DeepCopyTo(instr);
  if (use_kind == Definition::kValue) {
    ASSERT(instr->IsDefinition());
    instr->AsDefinition()->set_ssa_temp_index(
        flow_graph_->alloc_ssa_temp_index());
  }
  instr->InsertBefore(next);
}


void FlowGraphOptimizer::InsertAfter(Instruction* prev,
                                     Instruction* instr,
                                     Environment* env,
                                     Definition::UseKind use_kind) {
  if (env != NULL) env->DeepCopyTo(instr);
  if (use_kind == Definition::kValue) {
    ASSERT(instr->IsDefinition());
    instr->AsDefinition()->set_ssa_temp_index(
        flow_graph_->alloc_ssa_temp_index());
  }
  instr->InsertAfter(prev);
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
        operands_type = kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 FlowGraphCompiler::SupportsUnboxedMints()) {
        operands_type = kMintCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else {
        return false;
      }
      break;
    case Token::kMUL:
      if (HasOnlyTwoSmis(ic_data)) {
        operands_type = kSmiCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
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
      } else if (HasTwoMintOrSmi(ic_data) &&
                 FlowGraphCompiler::SupportsUnboxedMints()) {
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kSHR:
    case Token::kSHL:
      if (HasOnlyTwoSmis(ic_data)) {
        operands_type = kSmiCid;
      } else if (FlowGraphCompiler::SupportsUnboxedMints() &&
                 HasTwoMintOrSmi(ic_data) &&
                 HasOnlyOneSmi(ICData::Handle(
                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
        // Check for smi/mint << smi or smi/mint >> smi.
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kTRUNCDIV:
      if (HasOnlyTwoSmis(ic_data)) {
        operands_type = kSmiCid;
      } else {
        return false;
      }
      break;
    default:
      UNREACHABLE();
  };

  ASSERT(call->ArgumentCount() == 2);
  if (operands_type == kDoubleCid) {
    Value* left = call->ArgumentAt(0)->value();
    Value* right = call->ArgumentAt(1)->value();

    // Check that either left or right are not a smi.  Result or a
    // binary operation with two smis is a smi not a double.
    InsertBefore(call,
                 new CheckEitherNonSmiInstr(left->Copy(),
                                            right->Copy(),
                                            call),
                 call->env(),
                 Definition::kEffect);

    BinaryDoubleOpInstr* double_bin_op =
        new BinaryDoubleOpInstr(op_kind, left->Copy(), right->Copy(), call);
    call->ReplaceWith(double_bin_op, current_iterator());
    RemovePushArguments(call);
  } else if (operands_type == kMintCid) {
    Value* left = call->ArgumentAt(0)->value();
    Value* right = call->ArgumentAt(1)->value();
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      ShiftMintOpInstr* shift_op =
          new ShiftMintOpInstr(op_kind, left, right, call);
      call->ReplaceWith(shift_op, current_iterator());
    } else {
      BinaryMintOpInstr* bin_op =
          new BinaryMintOpInstr(op_kind, left, right, call);
      call->ReplaceWith(bin_op, current_iterator());
    }
    RemovePushArguments(call);
  } else if (op_kind == Token::kMOD) {
    // TODO(vegorov): implement fast path code for modulo.
    ASSERT(operands_type == kSmiCid);
    if (!call->ArgumentAt(1)->value()->BindsToConstant()) return false;
    const Object& obj = call->ArgumentAt(1)->value()->BoundConstant();
    if (!obj.IsSmi()) return false;
    const intptr_t value = Smi::Cast(obj).Value();
    if ((value > 0) && Utils::IsPowerOfTwo(value)) {
      Value* left = call->ArgumentAt(0)->value();
      // Insert smi check and attach a copy of the original
      // environment because the smi operation can still deoptimize.
      InsertBefore(call,
                   new CheckSmiInstr(left->Copy(), call->deopt_id()),
                   call->env(),
                   Definition::kEffect);
      ConstantInstr* c = new ConstantInstr(Smi::Handle(Smi::New(value - 1)));
      InsertBefore(call, c, NULL, Definition::kValue);
      BinarySmiOpInstr* bin_op =
          new BinarySmiOpInstr(Token::kBIT_AND, call, left, new Value(c));
      call->ReplaceWith(bin_op, current_iterator());
      RemovePushArguments(call);
    } else {
      // Did not replace.
      return false;
    }
  } else {
    ASSERT(operands_type == kSmiCid);
    Value* left = call->ArgumentAt(0)->value();
    Value* right = call->ArgumentAt(1)->value();
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    InsertBefore(call,
                 new CheckSmiInstr(left->Copy(), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    InsertBefore(call,
                 new CheckSmiInstr(right->Copy(), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    BinarySmiOpInstr* bin_op = new BinarySmiOpInstr(op_kind, call, left, right);
    call->ReplaceWith(bin_op, current_iterator());
    RemovePushArguments(call);
  }
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  ASSERT(call->ArgumentCount() == 1);
  Definition* unary_op = NULL;
  if (HasOnlyOneSmi(*call->ic_data())) {
    Value* value = call->ArgumentAt(0)->value();
    InsertBefore(call,
                 new CheckSmiInstr(value->Copy(), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    unary_op = new UnarySmiOpInstr(op_kind, call, value);
  } else if ((op_kind == Token::kBIT_NOT) &&
             HasOnlySmiOrMint(*call->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    Value* value = call->ArgumentAt(0)->value();
    unary_op = new UnaryMintOpInstr(op_kind, value, call);
  } else if (HasOnlyOneDouble(*call->ic_data()) &&
             (op_kind == Token::kNEGATE)) {
    Value* value = call->ArgumentAt(0)->value();
    AddCheckClass(call, value->Copy());
    ConstantInstr* minus_one =
        new ConstantInstr(Double::ZoneHandle(Double::NewCanonical(-1)));
    InsertBefore(call, minus_one, NULL, Definition::kValue);
    unary_op = new BinaryDoubleOpInstr(Token::kMUL,
                                       value,
                                       new Value(minus_one),
                                       call);
  }
  if (unary_op == NULL) return false;

  call->ReplaceWith(unary_op, current_iterator());
  RemovePushArguments(call);
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
  Definition* callee_receiver = call->ArgumentAt(0)->value()->definition();
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->parsed_function().function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    const intptr_t static_receiver_cid = Class::Handle(function.Owner()).id();
    ZoneGrowableArray<intptr_t>* subclass_cids =
        CHA::GetSubclassIdsOf(static_receiver_cid);
    if (subclass_cids->is_empty()) {
      // No subclasses, no check needed.
      return false;
    }
    ZoneGrowableArray<Function*>* overriding_functions =
        CHA::GetNamedInstanceFunctionsOf(*subclass_cids, call->function_name());
    if (overriding_functions->is_empty()) {
      // No overriding functions.
      return false;
    }
  }
  return true;
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
    AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());
  }
  // Detach environment from the original instruction because it can't
  // deoptimize.
  call->set_env(NULL);
  LoadFieldInstr* load = new LoadFieldInstr(
      call->ArgumentAt(0)->value(),
      field.Offset(),
      AbstractType::ZoneHandle(field.type()));
  call->ReplaceWith(load, current_iterator());
  RemovePushArguments(call);
}


void FlowGraphOptimizer::InlineArrayLengthGetter(InstanceCallInstr* call,
                                                 intptr_t length_offset,
                                                 bool is_immutable,
                                                 MethodRecognizer::Kind kind) {
  // Check receiver class.
  AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

  LoadFieldInstr* load = new LoadFieldInstr(
      call->ArgumentAt(0)->value(),
      length_offset,
      Type::ZoneHandle(Type::SmiType()),
      is_immutable);
  load->set_result_cid(kSmiCid);
  load->set_recognized_kind(kind);
  call->ReplaceWith(load, current_iterator());
  RemovePushArguments(call);
}


void FlowGraphOptimizer::InlineGArrayCapacityGetter(InstanceCallInstr* call) {
  // Check receiver class.
  AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

  // TODO(srdjan): type of load should be GrowableObjectArrayType.
  LoadFieldInstr* data_load = new LoadFieldInstr(
      call->ArgumentAt(0)->value(),
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

  call->ReplaceWith(length_load, current_iterator());
  RemovePushArguments(call);
}


static LoadFieldInstr* BuildLoadStringLength(Value* str) {
  const bool is_immutable = true;  // String length is immutable.
  LoadFieldInstr* load = new LoadFieldInstr(
      str,
      String::length_offset(),
      Type::ZoneHandle(Type::SmiType()),
      is_immutable);
  load->set_result_cid(kSmiCid);
  return load;
}


void FlowGraphOptimizer::InlineStringLengthGetter(InstanceCallInstr* call) {
  // Check receiver class.
  AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

  LoadFieldInstr* load = BuildLoadStringLength(call->ArgumentAt(0)->value());
  call->ReplaceWith(load, current_iterator());
  RemovePushArguments(call);
}


void FlowGraphOptimizer::InlineStringIsEmptyGetter(InstanceCallInstr* call) {
  // Check receiver class.
  AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

  LoadFieldInstr* load = BuildLoadStringLength(call->ArgumentAt(0)->value());
  InsertBefore(call, load, NULL, Definition::kValue);

  ConstantInstr* zero = new ConstantInstr(Smi::Handle(Smi::New(0)));
  InsertBefore(call, zero, NULL, Definition::kValue);

  StrictCompareInstr* compare =
      new StrictCompareInstr(Token::kEQ_STRICT,
                             new Value(load),
                             new Value(zero));
  call->ReplaceWith(compare, current_iterator());
  RemovePushArguments(call);
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
  }

  // Not an implicit getter.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  // VM objects length getter.
  if ((recognized_kind == MethodRecognizer::kObjectArrayLength) ||
      (recognized_kind == MethodRecognizer::kImmutableArrayLength) ||
      (recognized_kind == MethodRecognizer::kGrowableArrayLength)) {
    if (!ic_data.HasOneTarget()) {
      // TODO(srdjan): Implement for mutiple targets.
      return false;
    }
    switch (recognized_kind) {
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
        InlineArrayLengthGetter(call,
                                Array::length_offset(),
                                true,
                                recognized_kind);
        break;
      case MethodRecognizer::kGrowableArrayLength:
        InlineArrayLengthGetter(call,
                                GrowableObjectArray::length_offset(),
                                false,
                                recognized_kind);
        break;
      default:
        UNREACHABLE();
    }
    return true;
  }

  if (recognized_kind == MethodRecognizer::kGrowableArrayCapacity) {
    InlineGArrayCapacityGetter(call);
    return true;
  }

  if (recognized_kind == MethodRecognizer::kStringBaseLength) {
    if (!ic_data.HasOneTarget()) {
      // Target is not only StringBase_get_length.
      return false;
    }
    InlineStringLengthGetter(call);
    return true;
  }

  if (recognized_kind == MethodRecognizer::kStringBaseIsEmpty) {
    if (!ic_data.HasOneTarget()) {
      // Target is not only StringBase_get_isEmpty.
      return false;
    }
    InlineStringIsEmptyGetter(call);
    return true;
  }

  return false;
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

  if ((recognized_kind == MethodRecognizer::kIntegerToDouble) &&
      (class_ids[0] == kSmiCid)) {
    SmiToDoubleInstr* s2d_instr = new SmiToDoubleInstr(call);
    call->ReplaceWith(s2d_instr, current_iterator());
    // Pushed arguments are not removed because SmiToDouble is implemented
    // as a call.
    return true;
  }

  if ((recognized_kind == MethodRecognizer::kDoubleToInteger) &&
      (class_ids[0] == kDoubleCid)) {
    AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());
    DoubleToIntegerInstr* d2int_instr =
        new DoubleToIntegerInstr(call->ArgumentAt(0)->value(), call);
    call->ReplaceWith(d2int_instr, current_iterator());
    RemovePushArguments(call);
    return true;
  }

  return false;
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (instr->HasICData() && (instr->ic_data()->NumberOfChecks() > 0)) {
    const Token::Kind op_kind = instr->token_kind();
    if ((op_kind == Token::kASSIGN_INDEX) &&
        TryReplaceWithStoreIndexed(instr)) {
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
    if ((op_kind == Token::kSET) && TryInlineInstanceSetter(instr)) {
      return;
    }
    if (TryInlineInstanceMethod(instr)) {
      return;
    }
    const ICData& unary_checks =
        ICData::ZoneHandle(instr->ic_data()->AsUnaryClassChecks());
    if (!InstanceCallNeedsClassCheck(instr)) {
      const bool call_with_checks = false;
      PolymorphicInstanceCallInstr* call =
          new PolymorphicInstanceCallInstr(instr, unary_checks,
                                           call_with_checks);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
    const intptr_t kMaxChecks = 4;
    if (instr->ic_data()->NumberOfChecks() <= kMaxChecks) {
      bool call_with_checks;
      if (unary_checks.HasOneTarget()) {
        // Type propagation has not run yet, we cannot eliminate the check.
        AddCheckClass(instr, instr->ArgumentAt(0)->value()->Copy());
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
  // An instance call without ICData will trigger deoptimization.
}


void FlowGraphOptimizer::VisitStaticCall(StaticCallInstr* call) {
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(call->function());
  if (recognized_kind == MethodRecognizer::kMathSqrt) {
    MathSqrtInstr* sqrt = new MathSqrtInstr(call->ArgumentAt(0)->value(), call);
    call->ReplaceWith(sqrt, current_iterator());
    RemovePushArguments(call);
  }
}


bool FlowGraphOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr) {
  if (FLAG_enable_type_checks) {
    // TODO(srdjan): Add assignable check node if --enable_type_checks.
    return false;
  }

  ASSERT(instr->HasICData());
  const ICData& unary_ic_data =
      ICData::Handle(instr->ic_data()->AsUnaryClassChecks());
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
    AddCheckClass(instr, instr->ArgumentAt(0)->value()->Copy());
  }
  bool needs_store_barrier = true;
  if (ArgIsAlwaysSmi(*instr->ic_data(), 1)) {
    InsertBefore(instr,
                 new CheckSmiInstr(instr->ArgumentAt(1)->value()->Copy(),
                                   instr->deopt_id()),
                 instr->env(),
                 Definition::kEffect);
    needs_store_barrier = false;
  }
  // Detach environment from the original instruction because it can't
  // deoptimize.
  instr->set_env(NULL);
  StoreInstanceFieldInstr* store = new StoreInstanceFieldInstr(
      field,
      instr->ArgumentAt(0)->value(),
      instr->ArgumentAt(1)->value(),
      needs_store_barrier);
  instr->ReplaceWith(store, current_iterator());
  RemovePushArguments(instr);
  return true;
}


// TODO(fschneider): Once we get rid of the distinction between Instruction
// and computation, this helper can go away.
static void HandleRelationalOp(FlowGraphOptimizer* optimizer,
                               RelationalOpInstr* comp,
                               Instruction* instr) {
  if (!comp->HasICData()) return;

  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) return;
  // TODO(srdjan): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return;
  ASSERT(ic_data.HasOneTarget());

  if (HasOnlyTwoSmis(ic_data)) {
    optimizer->InsertBefore(
        instr,
        new CheckSmiInstr(comp->left()->Copy(), comp->deopt_id()),
        instr->env(),
        Definition::kEffect);
    optimizer->InsertBefore(
        instr,
        new CheckSmiInstr(comp->right()->Copy(), comp->deopt_id()),
        instr->env(),
        Definition::kEffect);
    comp->set_operands_class_id(kSmiCid);
  } else if (ShouldSpecializeForDouble(ic_data)) {
    comp->set_operands_class_id(kDoubleCid);
  } else if (comp->ic_data()->AllReceiversAreNumbers()) {
    comp->set_operands_class_id(kNumberCid);
  }
}

void FlowGraphOptimizer::VisitRelationalOp(RelationalOpInstr* instr) {
  HandleRelationalOp(this, instr, instr);
}


// TODO(fschneider): Once we get rid of the distinction between Instruction
// and computation, this helper can go away.
template <typename T>
static void HandleEqualityCompare(FlowGraphOptimizer* optimizer,
                                  EqualityCompareInstr* comp,
                                  T instr,
                                  ForwardInstructionIterator* iterator) {
  // If one of the inputs is null, no ICdata will be collected.
  if (comp->left()->BindsToConstantNull() ||
      comp->right()->BindsToConstantNull()) {
    Token::Kind strict_kind = (comp->kind() == Token::kEQ) ?
        Token::kEQ_STRICT : Token::kNE_STRICT;
    StrictCompareInstr* strict_comp =
        new StrictCompareInstr(strict_kind, comp->left(), comp->right());
    instr->ReplaceWith(strict_comp, iterator);
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
      optimizer->InsertBefore(
          instr,
          new CheckSmiInstr(comp->left()->Copy(), comp->deopt_id()),
          instr->env(),
          Definition::kEffect);
      optimizer->InsertBefore(
          instr,
          new CheckSmiInstr(comp->right()->Copy(), comp->deopt_id()),
          instr->env(),
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
  } else if (comp->ic_data()->AllReceiversAreNumbers()) {
    comp->set_receiver_class_id(kNumberCid);
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
  if (ICDataHasOnlyReceiverArgumentClassIds(
        *comp->ic_data(), smi_or_null, smi_or_null)) {
    const ICData& unary_checks_0 =
        ICData::ZoneHandle(comp->ic_data()->AsUnaryClassChecks());
    const intptr_t deopt_id = comp->deopt_id();
    if ((unary_checks_0.NumberOfChecks() == 1) &&
        (unary_checks_0.GetReceiverClassIdAt(0) == kSmiCid)) {
      // Smi only.
      optimizer->InsertBefore(
        instr,
        new CheckSmiInstr(comp->left()->Copy(), deopt_id),
        instr->env(),
        Definition::kEffect);
    } else {
      // Smi or NULL.
      optimizer->InsertBefore(
        instr,
        new CheckClassInstr(comp->left()->Copy(), deopt_id, unary_checks_0),
        instr->env(),
        Definition::kEffect);
    }

    const ICData& unary_checks_1 =
        ICData::ZoneHandle(comp->ic_data()->AsUnaryClassChecksForArgNr(1));
    if ((unary_checks_1.NumberOfChecks() == 1) &&
        (unary_checks_1.GetReceiverClassIdAt(0) == kSmiCid)) {
      // Smi only.
      optimizer->InsertBefore(
        instr,
        new CheckSmiInstr(comp->right()->Copy(), deopt_id),
        instr->env(),
        Definition::kEffect);
    } else {
      // Smi or NULL.
      optimizer->InsertBefore(
        instr,
        new CheckClassInstr(comp->right()->Copy(), deopt_id, unary_checks_1),
        instr->env(),
        Definition::kEffect);
    }
    comp->set_receiver_class_id(kSmiCid);
  }
}


void FlowGraphOptimizer::VisitEqualityCompare(EqualityCompareInstr* instr) {
  HandleEqualityCompare(this, instr, instr, current_iterator());
}


void FlowGraphOptimizer::VisitBranch(BranchInstr* instr) {
  ComparisonInstr* comparison = instr->comparison();
  if (comparison->IsRelationalOp()) {
    HandleRelationalOp(this, comparison->AsRelationalOp(), instr);
  } else if (comparison->IsEqualityCompare()) {
    HandleEqualityCompare(this, comparison->AsEqualityCompare(), instr,
                          current_iterator());
  } else {
    ASSERT(comparison->IsStrictCompare());
    // Nothing to do.
  }
}


// SminessPropagator ensures that CheckSmis are eliminated across phis.
class SminessPropagator : public ValueObject {
 public:
  explicit SminessPropagator(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        known_smis_(new BitVector(flow_graph_->current_ssa_temp_index())),
        rollback_checks_(10),
        in_worklist_(NULL),
        worklist_(0) { }

  void Propagate();

 private:
  void PropagateSminessRecursive(BlockEntryInstr* block);
  void AddToWorklist(PhiInstr* phi);
  PhiInstr* RemoveLastFromWorklist();
  void ProcessPhis();

  FlowGraph* flow_graph_;

  BitVector* known_smis_;
  GrowableArray<intptr_t> rollback_checks_;

  BitVector* in_worklist_;
  GrowableArray<PhiInstr*> worklist_;

  DISALLOW_COPY_AND_ASSIGN(SminessPropagator);
};


void SminessPropagator::AddToWorklist(PhiInstr* phi) {
  if (in_worklist_ == NULL) {
    in_worklist_ = new BitVector(flow_graph_->current_ssa_temp_index());
  }
  if (!in_worklist_->Contains(phi->ssa_temp_index())) {
    in_worklist_->Add(phi->ssa_temp_index());
    worklist_.Add(phi);
  }
}


PhiInstr* SminessPropagator::RemoveLastFromWorklist() {
  PhiInstr* phi = worklist_.RemoveLast();
  ASSERT(in_worklist_->Contains(phi->ssa_temp_index()));
  in_worklist_->Remove(phi->ssa_temp_index());
  return phi;
}


static bool IsDefinitelySmiPhi(PhiInstr* phi) {
  for (intptr_t i = 0; i < phi->InputCount(); i++) {
    const intptr_t cid = phi->InputAt(i)->ResultCid();
    if (cid != kSmiCid) {
      return false;
    }
  }
  return true;
}


static bool IsPossiblySmiPhi(PhiInstr* phi) {
  for (intptr_t i = 0; i < phi->InputCount(); i++) {
    const intptr_t cid = phi->InputAt(i)->ResultCid();
    if ((cid != kSmiCid) && (cid != kDynamicCid)) {
      return false;
    }
  }
  return true;
}


void SminessPropagator::ProcessPhis() {
  // First optimistically mark all possible smi-phis: phi is possibly a smi if
  // its operands are either smis or phis in the worklist.
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    PhiInstr* phi = worklist_[i];
    ASSERT(phi->GetPropagatedCid() == kDynamicCid);
    phi->SetPropagatedCid(kSmiCid);

    // Append all phis that use this phi and can potentially be smi to the
    // end of worklist.
    for (Value* use = phi->input_use_list();
         use != NULL;
         use = use->next_use()) {
      PhiInstr* phi_use = use->instruction()->AsPhi();
      if ((phi_use != NULL) &&
          (phi_use->GetPropagatedCid() == kDynamicCid) &&
          IsPossiblySmiPhi(phi_use)) {
        AddToWorklist(phi_use);
      }
    }
  }

  // Now unmark phis that are not definitely smi: that is have only
  // smi operands.
  while (!worklist_.is_empty()) {
    PhiInstr* phi = RemoveLastFromWorklist();
    if (!IsDefinitelySmiPhi(phi)) {
      // Phi result is not a smi. Propagate this fact to phis that depend on it.
      phi->SetPropagatedCid(kDynamicCid);
      for (Value* use = phi->input_use_list();
           use != NULL;
           use = use->next_use()) {
        PhiInstr* phi_use = use->instruction()->AsPhi();
        if ((phi_use != NULL) && (phi_use->GetPropagatedCid() == kSmiCid)) {
          AddToWorklist(phi_use);
        }
      }
    }
  }
}


void SminessPropagator::PropagateSminessRecursive(BlockEntryInstr* block) {
  const intptr_t rollback_point = rollback_checks_.length();

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();
    if (instr->IsCheckSmi()) {
      const intptr_t value_ssa_index =
          instr->InputAt(0)->definition()->ssa_temp_index();
      if (!known_smis_->Contains(value_ssa_index)) {
        known_smis_->Add(value_ssa_index);
        rollback_checks_.Add(value_ssa_index);
      }
    }
  }

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    PropagateSminessRecursive(block->dominated_blocks()[i]);
  }

  if (block->last_instruction()->SuccessorCount() == 1 &&
      block->last_instruction()->SuccessorAt(0)->IsJoinEntry()) {
    JoinEntryInstr* join =
        block->last_instruction()->SuccessorAt(0)->AsJoinEntry();
    intptr_t pred_index = join->IndexOfPredecessor(block);
    ASSERT(pred_index >= 0);
    if (join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi == NULL) continue;
        Value* use = phi->InputAt(pred_index);
        const intptr_t value_ssa_index = use->definition()->ssa_temp_index();
        if (known_smis_->Contains(value_ssa_index) &&
            (phi->GetPropagatedCid() != kSmiCid)) {
          use->set_reaching_cid(kSmiCid);
          AddToWorklist(phi);
        }
      }
    }
  }

  for (intptr_t i = rollback_point; i < rollback_checks_.length(); i++) {
    known_smis_->Remove(rollback_checks_[i]);
  }
  rollback_checks_.TruncateTo(rollback_point);
}


void SminessPropagator::Propagate() {
  PropagateSminessRecursive(flow_graph_->graph_entry());
  ProcessPhis();
}


void FlowGraphOptimizer::PropagateSminess() {
  SminessPropagator propagator(flow_graph_);
  propagator.Propagate();
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
        if ((defn->GetPropagatedCid() == kSmiCid) &&
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
        if (current->GetPropagatedCid() == kSmiCid) {
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
  Value* next_use = NULL;
  Value* prev_use = NULL;
  for (Value* use = def->input_use_list();
       use != NULL;
       use = next_use) {
    next_use = use->next_use();

    // Skip dead phis.
    if (use->instruction()->IsPhi() &&
        !use->instruction()->AsPhi()->is_alive()) {
      prev_use = use;
      continue;
    }

    if (IsDominatedUse(dom, use)) {
      if (prev_use != NULL) {
        prev_use->set_next_use(next_use);
      } else {
        def->set_input_use_list(next_use);
      }
      use->set_definition(other);
      use->AddToInputUseList();
    } else {
      prev_use = use;
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

// For a comparison operation return an operation for the negated comparison:
// !(a (op) b) === a (op') b
static Token::Kind NegateComparison(Token::Kind op) {
  switch (op) {
    case Token::kEQ: return Token::kNE;
    case Token::kNE: return Token::kEQ;
    case Token::kLT: return Token::kGTE;
    case Token::kGT: return Token::kLTE;
    case Token::kLTE: return Token::kGT;
    case Token::kGTE: return Token::kLT;
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
  constraint->InsertAfter(after);
  constraint->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
  RenameDominatedUses(defn, after, constraint);
  constraints_.Add(constraint);
  constraint->value()->set_instruction(constraint);
  constraint->value()->set_use_index(0);
  constraint->value()->AddToInputUseList();
  return constraint;
}


void RangeAnalysis::InsertConstraintsFor(Definition* defn) {
  for (Value* use = defn->input_use_list();
       use != NULL;
       use = use->next_use()) {
    if (use->instruction()->IsBranch()) {
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
        if (true_constraint != NULL) true_constraint->AddDependency(boundary);

        // Constrain definition with a negated condition at the false successor.
        ConstraintInstr* false_constraint =
            InsertConstraintFor(
                defn,
                ConstraintRange(NegateComparison(op_kind), boundary),
                branch->false_successor());
        // Mark false_constraint an artificial use of boundary. This ensures
        // that constraint's range is recalculated if boundary's range changes.
        if (false_constraint != NULL) false_constraint->AddDependency(boundary);
      }
    }
  }
}


void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < smi_checks_.length(); i++) {
    CheckSmiInstr* check = smi_checks_[i];
    ConstraintInstr* constraint =
        InsertConstraintFor(check->value()->definition(),
                            Range::Unknown(),
                            check);
    if (constraint != NULL) {
      InsertConstraintsFor(constraint);  // Constrain uses further.
    }
  }

  for (intptr_t i = 0; i < smi_values_.length(); i++) {
    InsertConstraintsFor(smi_values_[i]);
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
               current->IsCheckArrayBound() &&
               current->AsCheckArrayBound()->IsRedundant()) {
      it.RemoveCurrentFromGraph();
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
    constraints_[i]->RemoveDependency();
    constraints_[i]->RemoveFromGraph();
  }
}


void FlowGraphOptimizer::InferSmiRanges() {
  RangeAnalysis range_analysis(flow_graph_);
  range_analysis.Analyze();
}


void FlowGraphTypePropagator::VisitBlocks() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      // No need to propagate the input types of the instruction, as long as
      // PhiInstr's are handled as part of JoinEntryInstr.

      // Visit the instruction and possibly eliminate type checks.
      current->Accept(this);
      // The instruction may have been removed from the graph.
      Definition* defn = current->AsDefinition();
      if ((defn != NULL) &&
          !defn->IsPushArgument() &&
          (defn->previous() != NULL)) {
        // Cache the propagated computation type.
        AbstractType& type = AbstractType::Handle(defn->CompileType());
        still_changing_ = defn->SetPropagatedType(type) || still_changing_;

        // Propagate class ids.
        const intptr_t cid = defn->ResultCid();
        still_changing_ = defn->SetPropagatedCid(cid) || still_changing_;
      }
    }
    current_iterator_ = NULL;
  }
}


void FlowGraphTypePropagator::VisitAssertAssignable(
    AssertAssignableInstr* instr) {
  bool is_null, is_instance;
  if (FLAG_eliminate_type_checks &&
      !instr->is_eliminated() &&
      ((instr->value()->CanComputeIsNull(&is_null) && is_null) ||
       (instr->value()->CanComputeIsInstanceOf(instr->dst_type(), &is_instance)
        && is_instance))) {
    // TODO(regis): Remove is_eliminated_ field and support.
    instr->eliminate();

    Value* use = instr->value();
    ASSERT(use != NULL);
    Definition* result = use->definition();
    ASSERT(result != NULL);
    // Replace uses and remove the current instruction via the iterator.
    instr->ReplaceUsesWith(result);
    ASSERT(current_iterator()->Current() == instr);
    current_iterator()->RemoveCurrentFromGraph();
    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                instr->ssa_temp_index(),
                result->ssa_temp_index());
    }

    if (FLAG_trace_type_check_elimination) {
      FlowGraphPrinter::PrintTypeCheck(parsed_function(),
                                       instr->token_pos(),
                                       instr->value(),
                                       instr->dst_type(),
                                       instr->dst_name(),
                                       instr->is_eliminated());
    }
  }
}


void FlowGraphTypePropagator::VisitAssertBoolean(AssertBooleanInstr* instr) {
  bool is_null, is_bool;
  if (FLAG_eliminate_type_checks &&
      !instr->is_eliminated() &&
      instr->value()->CanComputeIsNull(&is_null) &&
      !is_null &&
      instr->value()->CanComputeIsInstanceOf(Type::Handle(Type::BoolType()),
                                             &is_bool) &&
      is_bool) {
    // TODO(regis): Remove is_eliminated_ field and support.
    instr->eliminate();
    Value* use = instr->value();
    Definition* result = use->definition();
    ASSERT(result != NULL);
    // Replace uses and remove the current instruction via the iterator.
    instr->ReplaceUsesWith(result);
    ASSERT(current_iterator()->Current() == instr);
    current_iterator()->RemoveCurrentFromGraph();
    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                instr->ssa_temp_index(),
                result->ssa_temp_index());
    }

    if (FLAG_trace_type_check_elimination) {
      const String& name = String::Handle(Symbols::New("boolean expression"));
      FlowGraphPrinter::PrintTypeCheck(parsed_function(),
                                       instr->token_pos(),
                                       instr->value(),
                                       Type::Handle(Type::BoolType()),
                                       name,
                                       instr->is_eliminated());
    }
  }
}


void FlowGraphTypePropagator::VisitInstanceOf(InstanceOfInstr* instr) {
  bool is_null;
  bool is_instance = false;
  if (FLAG_eliminate_type_checks &&
      instr->value()->CanComputeIsNull(&is_null) &&
      (is_null ||
       instr->value()->CanComputeIsInstanceOf(instr->type(), &is_instance))) {
    Definition* result = new ConstantInstr(Bool::ZoneHandle(Bool::Get(
        instr->negate_result() ? !is_instance : is_instance)));
    result->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    result->InsertBefore(instr);
    // Replace uses and remove the current instruction via the iterator.
    instr->ReplaceUsesWith(result);
    ASSERT(current_iterator()->Current() == instr);
    current_iterator()->RemoveCurrentFromGraph();
    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                instr->ssa_temp_index(),
                result->ssa_temp_index());
    }

    if (FLAG_trace_type_check_elimination) {
      const String& name = String::Handle(Symbols::New("InstanceOf"));
      FlowGraphPrinter::PrintTypeCheck(parsed_function(),
                                       instr->token_pos(),
                                       instr->value(),
                                       instr->type(),
                                       name,
                                       /* eliminated = */ true);
    }
  }
}


void FlowGraphTypePropagator::VisitGraphEntry(GraphEntryInstr* graph_entry) {
  // Visit incoming parameters.
  for (intptr_t i = 0; i < graph_entry->initial_definitions()->length(); i++) {
    ParameterInstr* param =
        (*graph_entry->initial_definitions())[i]->AsParameter();
    if (param != NULL) VisitParameter(param);
  }
}


void FlowGraphTypePropagator::VisitJoinEntry(JoinEntryInstr* join_entry) {
  if (join_entry->phis() != NULL) {
    for (intptr_t i = 0; i < join_entry->phis()->length(); ++i) {
      PhiInstr* phi = (*join_entry->phis())[i];
      if (phi != NULL) {
        VisitPhi(phi);
      }
    }
  }
}


// TODO(srdjan): Investigate if the propagated cid should be more specific.
void FlowGraphTypePropagator::VisitPushArgument(PushArgumentInstr* push) {
  if (!push->has_propagated_cid()) push->SetPropagatedCid(kDynamicCid);
}


void FlowGraphTypePropagator::VisitPhi(PhiInstr* phi) {
  // We could set the propagated type of the phi to the least upper bound of its
  // input propagated types. However, keeping all propagated types allows us to
  // optimize method dispatch.
  // TODO(regis): Support a set of propagated types. For now, we compute the
  // least specific of the input propagated types.
  AbstractType& type = AbstractType::Handle(phi->LeastSpecificInputType());
  bool changed = phi->SetPropagatedType(type);
  if (changed) {
    still_changing_ = true;
  }

  // Merge class ids: if any two inputs have different class ids then result
  // is kDynamicCid.
  intptr_t merged_cid = kIllegalCid;
  for (intptr_t i = 0; i < phi->InputCount(); i++) {
    // Result cid of UseVal can be kIllegalCid if the referred definition
    // has not been visited yet.
    intptr_t cid = phi->InputAt(i)->ResultCid();
    if (cid == kIllegalCid) {
      still_changing_ = true;
      continue;
    }
    if (merged_cid == kIllegalCid) {
      // First time set.
      merged_cid = cid;
    } else if (merged_cid != cid) {
      merged_cid = kDynamicCid;
    }
  }
  if (merged_cid == kIllegalCid) {
    merged_cid = kDynamicCid;
  }
  changed = phi->SetPropagatedCid(merged_cid);
  if (changed) {
    still_changing_ = true;
  }
}


void FlowGraphTypePropagator::VisitParameter(ParameterInstr* param) {
  // TODO(regis): Once we inline functions, the propagated type of the formal
  // parameter will reflect the compile type of the passed-in argument.
  // For now, we do not know anything about the argument type and therefore set
  // it to the DynamicType, unless the argument is a compiler generated value,
  // i.e. the receiver argument or the constructor phase argument.
  AbstractType& param_type = AbstractType::Handle(Type::DynamicType());
  param->SetPropagatedCid(kDynamicCid);
  bool param_type_is_known = false;
  if (param->index() == 0) {
    const Function& function = parsed_function().function();
    if ((function.IsDynamicFunction() || function.IsConstructor())) {
      // Parameter is the receiver .
      param_type_is_known = true;
    }
  } else if ((param->index() == 1) &&
      parsed_function().function().IsConstructor()) {
    // Parameter is the constructor phase.
    param_type_is_known = true;
  }
  if (param_type_is_known) {
    LocalScope* scope = parsed_function().node_sequence()->scope();
    param_type = scope->VariableAt(param->index())->type().raw();
    if (FLAG_use_cha) {
      const intptr_t cid = Class::Handle(param_type.type_class()).id();
      if (!CHA::HasSubclasses(cid)) {
        // Receiver's class has no subclasses.
        param->SetPropagatedCid(cid);
      }
    }
  }
  bool changed = param->SetPropagatedType(param_type);
  if (changed) {
    still_changing_ = true;
  }
}


void FlowGraphTypePropagator::PropagateTypes() {
  // TODO(regis): Is there a way to make this more efficient, e.g. by visiting
  // only blocks depending on blocks that have changed and not the whole graph.
  do {
    still_changing_ = false;
    VisitBlocks();
  } while (still_changing_);
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
  it->RemoveCurrentFromGraph();
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  current->InsertBefore(last);
  // Attach the environment of the Goto instruction to the hoisted
  // instruction and set the correct deopt_id.
  ASSERT(last->env() != NULL);
  last->env()->DeepCopyTo(current);
  current->deopt_id_ = last->GetDeoptId();
}


void LICM::TryHoistCheckSmiThroughPhi(ForwardInstructionIterator* it,
                                      BlockEntryInstr* header,
                                      BlockEntryInstr* pre_header,
                                      CheckSmiInstr* current) {
  PhiInstr* phi = current->InputAt(0)->definition()->AsPhi();
  if (!header->loop_info()->Contains(phi->block()->preorder_number())) {
    return;
  }

  if (phi->GetPropagatedCid() == kSmiCid) {
    it->RemoveCurrentFromGraph();
    return;
  }

  // Check if there is only a single kDynamicCid input to the phi that
  // comes from the pre-header.
  const intptr_t kNotFound = -1;
  intptr_t non_smi_input = kNotFound;
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Value* input = phi->InputAt(i);
    if (input->ResultCid() != kSmiCid) {
      if ((non_smi_input != kNotFound) || (input->ResultCid() != kDynamicCid)) {
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

  // Replace value we are checking with phi's input. Maintain use lists.
  Definition* non_smi_input_defn = phi->InputAt(non_smi_input)->definition();
  current->value()->RemoveFromInputUseList();
  current->value()->set_definition(non_smi_input_defn);
  current->value()->AddToInputUseList();

  phi->SetPropagatedCid(kSmiCid);
}


void LICM::Optimize(FlowGraph* flow_graph) {
  GrowableArray<BlockEntryInstr*> loop_headers;
  flow_graph->ComputeLoops(&loop_headers);

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    BlockEntryInstr* header = loop_headers[i];
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = FindPreHeader(header);
    if (pre_header == NULL) continue;

    for (BitVector::Iterator loop_it(header->loop_info());
         !loop_it.Done();
         loop_it.Advance()) {
      BlockEntryInstr* block = flow_graph->preorder()[loop_it.Current()];
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


static intptr_t NumberLoadExpressions(FlowGraph* graph) {
  DirectChainedHashMap<Definition*> map;
  intptr_t expr_id = 0;
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
      Definition* result = map.Lookup(defn);
      if (result == NULL) {
        map.Insert(defn);
        defn->set_expr_id(expr_id++);
      } else {
        defn->set_expr_id(result->expr_id());
      }
    }
  }
  return expr_id;
}


static void ComputeAvailableLoads(
    FlowGraph* graph,
    intptr_t max_expr_id,
    const GrowableArray<BitVector*>& avail_in) {
  // Initialize gen-, kill-, out-sets.
  intptr_t num_blocks = graph->preorder().length();
  GrowableArray<BitVector*> avail_out(num_blocks);
  GrowableArray<BitVector*> avail_gen(num_blocks);
  GrowableArray<BitVector*> avail_kill(num_blocks);
  for (intptr_t i = 0; i < num_blocks; i++) {
    avail_out.Add(new BitVector(max_expr_id));
    avail_gen.Add(new BitVector(max_expr_id));
    avail_kill.Add(new BitVector(max_expr_id));
  }

  for (BlockIterator block_it = graph->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    intptr_t preorder_number = block->preorder_number();
    for (BackwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* instr = instr_it.Current();
      if (instr->HasSideEffect()) {
        avail_kill[preorder_number]->SetAll();
        break;
      }
      Definition* defn = instr_it.Current()->AsDefinition();
      if ((defn == NULL) || !IsLoadEliminationCandidate(defn)) {
        continue;
      }
      avail_gen[preorder_number]->Add(defn->expr_id());
    }
    avail_out[preorder_number]->CopyFrom(avail_gen[preorder_number]);
  }

  BitVector* temp = new BitVector(avail_in[0]->length());

  bool changed = true;
  while (changed) {
    changed = false;

    for (BlockIterator block_it = graph->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      BitVector* block_in = avail_in[block->preorder_number()];
      BitVector* block_out = avail_out[block->preorder_number()];
      BitVector* block_kill = avail_kill[block->preorder_number()];
      BitVector* block_gen = avail_gen[block->preorder_number()];

      if (FLAG_trace_optimization) {
        OS::Print("B%"Pd"", block->block_id());
        block_in->Print();
        block_out->Print();
        OS::Print("\n");
      }

      // Compute block_in as the intersection of all out(p) where p
      // is a predecessor of the current block.
      if (block->IsGraphEntry()) {
        temp->Clear();
      } else {
        temp->SetAll();
        ASSERT(block->PredecessorCount() > 0);
        for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
          BlockEntryInstr* pred = block->PredecessorAt(i);
          BitVector* pred_out = avail_out[pred->preorder_number()];
          temp->Intersect(*pred_out);
        }
      }
      if (!temp->Equals(*block_in)) {
        block_in->CopyFrom(temp);
        if (block_out->KillAndAdd(block_kill, block_gen)) changed = true;
      }
    }
  }
}


static bool OptimizeLoads(
    BlockEntryInstr* block,
    GrowableArray<Definition*>* definitions,
    const GrowableArray<BitVector*>& avail_in) {
  // TODO(fschneider): Factor out code shared with the existing CSE pass.

  // Delete loads that are killed (not available) at the entry.
  intptr_t pre_num = block->preorder_number();
  ASSERT(avail_in[pre_num]->length() == definitions->length());
  for (intptr_t i = 0; i < avail_in[pre_num]->length(); i++) {
    if (!avail_in[pre_num]->Contains(i)) {
      (*definitions)[i] = NULL;
    }
  }

  bool changed = false;
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();
    if (instr->HasSideEffect()) {
      // Handle local side effects by clearing current definitions.
      for (intptr_t i = 0; i < definitions->length(); i++) {
        (*definitions)[i] = NULL;
      }
      continue;
    }
    Definition* defn = instr->AsDefinition();
    if ((defn == NULL) || !IsLoadEliminationCandidate(defn)) {
      continue;
    }
    Definition* result = (*definitions)[defn->expr_id()];
    if (result == NULL) {
      (*definitions)[defn->expr_id()] = defn;
      continue;
    }

    // Replace current with lookup result.
    defn->ReplaceUsesWith(result);
    it.RemoveCurrentFromGraph();
    changed = true;
    if (FLAG_trace_optimization) {
      OS::Print("Replacing load v%"Pd" with v%"Pd"\n",
                defn->ssa_temp_index(),
                result->ssa_temp_index());
    }
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i  < num_children - 1) {
      GrowableArray<Definition*> child_defs(definitions->length());
      child_defs.AddArray(*definitions);
      changed = OptimizeLoads(child, &child_defs, avail_in) || changed;
    } else {
      changed = OptimizeLoads(child, definitions, avail_in) || changed;
    }
  }
  return changed;
}


bool DominatorBasedCSE::Optimize(FlowGraph* graph) {
  bool changed = false;
  if (FLAG_load_cse) {
    intptr_t max_expr_id = NumberLoadExpressions(graph);
    if (max_expr_id > 0) {
      intptr_t num_blocks = graph->preorder().length();
      GrowableArray<BitVector*> avail_in(num_blocks);
      for (intptr_t i = 0; i < num_blocks; i++) {
        avail_in.Add(new BitVector(max_expr_id));
      }

      ComputeAvailableLoads(graph, max_expr_id, avail_in);

      GrowableArray<Definition*> definitions(max_expr_id);
      for (intptr_t j = 0; j < max_expr_id ; j++) {
        definitions.Add(NULL);
      }
      changed = OptimizeLoads(graph->graph_entry(), &definitions, avail_in);
    }
  }

  DirectChainedHashMap<Instruction*> map;
  changed = OptimizeRecursive(graph->graph_entry(), &map) || changed;

  return changed;
}


bool DominatorBasedCSE::OptimizeRecursive(
    BlockEntryInstr* block,
    DirectChainedHashMap<Instruction*>* map) {
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
    ReplaceCurrentInstruction(&it, current, replacement);
    changed = true;
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i  < num_children - 1) {
      DirectChainedHashMap<Instruction*> child_map(*map);  // Copy map.
      changed = OptimizeRecursive(child, &child_map) || changed;
    } else {
      // Reuse map for the last child.
      changed = OptimizeRecursive(child, map) || changed;
    }
  }
  return changed;
}


ConstantPropagator::ConstantPropagator(
    FlowGraph* graph,
    const GrowableArray<BlockEntryInstr*>& ignored)
    : FlowGraphVisitor(ignored),
      graph_(graph),
      unknown_(Object::ZoneHandle(Object::transition_sentinel())),
      non_constant_(Object::ZoneHandle(Object::sentinel())),
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
  ZoneGrowableArray<PhiInstr*>* phis = block->phis();
  if (phis != NULL) {
    for (intptr_t phi_idx = 0; phi_idx < phis->length(); ++phi_idx) {
      PhiInstr* phi = (*phis)[phi_idx];
      if (phi == NULL) continue;
      phi->Accept(this);
    }
  }

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitTargetEntry(TargetEntryInstr* block) {
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
    } else if (value.raw() == Bool::True()) {
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


void ConstantPropagator::VisitStrictCompare(StrictCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();

  if (IsNonConstant(left) || IsNonConstant(right)) {
    // TODO(vegorov): incorporate nullability information into the lattice.
    if ((left.IsNull() && (instr->right()->ResultCid() != kDynamicCid)) ||
        (right.IsNull() && (instr->left()->ResultCid() != kDynamicCid))) {
      bool result = left.IsNull() ? (instr->right()->ResultCid() == kNullCid)
                                  : (instr->left()->ResultCid() == kNullCid);
      if (instr->kind() == Token::kNE_STRICT) result = !result;
      SetValue(instr, Bool::ZoneHandle(Bool::Get(result)));
    } else {
      SetValue(instr, non_constant_);
    }
  } else if (IsConstant(left) && IsConstant(right)) {
    bool result = (left.raw() == right.raw());
    if (instr->kind() == Token::kNE_STRICT) result = !result;
    SetValue(instr, Bool::ZoneHandle(Bool::Get(result)));
  }
}


void ConstantPropagator::VisitEqualityCompare(EqualityCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle equality comparison of constants.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitRelationalOp(RelationalOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle relational comparison of constants.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitNativeCall(NativeCallInstr* instr) {
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
    SetValue(instr, Bool::ZoneHandle(Bool::Get(value.raw() != Bool::True())));
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


void ConstantPropagator::VisitLoadField(LoadFieldInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitStoreVMField(StoreVMFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsInstr* instr) {
  SetValue(instr, non_constant_);
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
    if (!reachable_->Contains(block->preorder_number())) {
      if (FLAG_trace_constant_propagation) {
        OS::Print("Unreachable B%"Pd"\n", block->block_id());
      }
      continue;
    }

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      // Remove phi inputs corresponding to unreachable predecessor blocks.
      // Predecessors will be recomputed (in block id order) after removing
      // unreachable code so we merely have to keep the phi inputs in order.
      ZoneGrowableArray<PhiInstr*>* phis = join->phis();
      if (phis != NULL) {
        intptr_t pred_count = join->PredecessorCount();
        intptr_t live_count = 0;
        for (intptr_t pred_idx = 0; pred_idx < pred_count; ++pred_idx) {
          if (reachable_->Contains(
                  join->PredecessorAt(pred_idx)->preorder_number())) {
            if (live_count < pred_idx) {
              for (intptr_t phi_idx = 0; phi_idx < phis->length(); ++phi_idx) {
                PhiInstr* phi = (*phis)[phi_idx];
                if (phi == NULL) continue;
                phi->inputs_[live_count] = phi->inputs_[pred_idx];
              }
            }
            ++live_count;
          }
        }
        if (live_count < pred_count) {
          for (intptr_t phi_idx = 0; phi_idx < phis->length(); ++phi_idx) {
            PhiInstr* phi = (*phis)[phi_idx];
            if (phi == NULL) continue;
            phi->inputs_.TruncateTo(live_count);
            if (live_count == 1) redundant_phis.Add(phi);
          }
        }
      }
    }

    for (ForwardInstructionIterator i(block); !i.Done(); i.Advance()) {
      Definition* defn = i.Current()->AsDefinition();
      // Replace constant-valued instructions without observable side
      // effects.  Do this for smis only to avoid having to copy other
      // objects into the heap's old generation.
      //
      // TODO(kmillikin): Extend this to handle booleans, other number
      // types, etc.
      if ((defn != NULL) &&
          defn->constant_value().IsSmi() &&
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
        i.ReplaceCurrentWith(new ConstantInstr(defn->constant_value()));
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
        ASSERT(branch->comparison()->IsStrictCompare());
        ASSERT(if_false->parallel_move() == NULL);
        ASSERT(if_false->loop_info() == NULL);
        join =
            new JoinEntryInstr(if_false->block_id(), if_false->try_index());
        next = if_false->next();
      } else if (!reachable_->Contains(if_false->preorder_number())) {
        ASSERT(branch->comparison()->IsStrictCompare());
        ASSERT(if_true->parallel_move() == NULL);
        ASSERT(if_true->loop_info() == NULL);
        join = new JoinEntryInstr(if_true->block_id(), if_true->try_index());
        next = if_true->next();
      }

      if (join != NULL) {
        // Replace the branch with a jump to the reachable successor.
        // Drop the comparison, which does not have side effects as long
        // as it is a strict compare (the only one we can determine is
        // constant with the current analysis).
        GotoInstr* jump = new GotoInstr(join);
        Instruction* previous = branch->previous();
        branch->set_previous(NULL);
        previous->LinkTo(jump);
        // Replace the false target entry with the new join entry. We will
        // recompute the dominators after this pass.
        join->LinkTo(next);
      }
    }
  }

  graph_->DiscoverBlocks();
  GrowableArray<BitVector*> dominance_frontier;
  graph_->ComputeDominators(&dominance_frontier);
  graph_->ComputeUseLists();

  for (intptr_t i = 0; i < redundant_phis.length(); i++) {
    PhiInstr* phi = redundant_phis[i];
    phi->ReplaceUsesWith(phi->InputAt(0)->definition());
    phi->mark_dead();
  }

  if (FLAG_trace_constant_propagation) {
    OS::Print("\n==== After constant propagation ====\n");
    FlowGraphPrinter printer(*graph_);
    printer.PrintBlocks();
  }
}


}  // namespace dart
