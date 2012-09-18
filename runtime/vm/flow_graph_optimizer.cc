// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/cha.h"
#include "vm/flow_graph_builder.h"
#include "vm/hash_map.h"
#include "vm/il_printer.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/scopes.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, eliminate_type_checks);
DECLARE_FLAG(bool, enable_type_checks);
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DECLARE_FLAG(bool, trace_type_check_elimination);
DEFINE_FLAG(bool, use_cha, true, "Use class hierarchy analysis.");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");

void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


void FlowGraphOptimizer::OptimizeComputations() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* defn = it.Current()->AsDefinition();
      if (defn != NULL) {
        Definition* result = defn->Canonicalize();
        if (result != defn) {
          if (result != NULL) {
            defn->ReplaceUsesWith(result);
            if (FLAG_trace_optimization) {
              OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                        defn->ssa_temp_index(),
                        result->ssa_temp_index());
            }
          } else if (FLAG_trace_optimization) {
              OS::Print("Removing v%"Pd".\n", defn->ssa_temp_index());
          }
          it.RemoveCurrentFromGraph();
        }
      }
    }
  }
}


static Definition* CreateConversion(Representation from,
                                    Representation to,
                                    Definition* def,
                                    Instruction* deopt_target) {
  if ((from == kUnboxedDouble) && (to == kTagged)) {
    return new BoxDoubleInstr(new Value(def), NULL);
  } else if ((from == kTagged) && (to == kUnboxedDouble)) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT((deopt_target != NULL) || (def->GetPropagatedCid() == kDoubleCid));
    return new UnboxDoubleInstr(new Value(def), deopt_id);
  } else {
    UNREACHABLE();
    return NULL;
  }
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

    Definition* converted =
        CreateConversion(from_rep, to_rep, def, deopt_target);
    InsertBefore(instr, converted, use->instruction()->env(),
                 Definition::kValue);
    use->set_definition(converted);
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
        if ((phi != NULL) && (phi->GetPropagatedCid() == kDoubleCid)) {
          phi->set_representation(kUnboxedDouble);
        }
      }
    }
  }

  // Process all instructions and insert conversions where needed.
  GraphEntryInstr* graph_entry = block_order_[0]->AsGraphEntry();

  // Visit incoming parameters.
  for (intptr_t i = 0; i < graph_entry->start_env()->Length(); i++) {
    Value* val = graph_entry->start_env()->ValueAt(i);
    InsertConversionsFor(val->definition());
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


static bool HasOneSmi(const ICData& ic_data) {
  return ICDataHasReceiverClassId(ic_data, kSmiCid);
}


static bool HasOnlyTwoSmi(const ICData& ic_data) {
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


static bool HasOneDouble(const ICData& ic_data) {
  return ICDataHasReceiverClassId(ic_data, kDoubleCid);
}


static bool ShouldSpecializeForDouble(const ICData& ic_data) {
  if (ic_data.NumberOfChecks() != 1) return false;
  if (ic_data.num_args_tested() != 2) return false;

  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  ASSERT(class_ids.length() == 2);

  const bool seen_double =
      (class_ids[0] == kDoubleCid) || (class_ids[1] == kDoubleCid);

  const bool seen_only_smi_or_double =
      ((class_ids[0] == kDoubleCid) || (class_ids[0] == kSmiCid)) &&
      ((class_ids[1] == kDoubleCid) || (class_ids[1] == kSmiCid));

  return seen_double && seen_only_smi_or_double;
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


// Returns true if all targets are the same.
// TODO(srdjan): if targets are native use their C_function to compare.
static bool HasOneTarget(const ICData& ic_data) {
  ASSERT(ic_data.NumberOfChecks() > 0);
  const Function& first_target = Function::Handle(ic_data.GetTargetAt(0));
  Function& test_target = Function::Handle();
  for (intptr_t i = 1; i < ic_data.NumberOfChecks(); i++) {
    test_target = ic_data.GetTargetAt(i);
    if (first_target.raw() != test_target.raw()) {
      return false;
    }
  }
  return true;
}


static intptr_t ReceiverClassId(InstanceCallInstr* call) {
  if (!call->HasICData()) return kIllegalCid;

  const ICData& ic_data = ICData::Handle(call->ic_data()->AsUnaryClassChecks());

  if (ic_data.NumberOfChecks() == 0) return kIllegalCid;
  // TODO(vegorov): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return kIllegalCid;
  ASSERT(HasOneTarget(ic_data));

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
  CheckClassInstr* check = new CheckClassInstr(value, call, unary_checks);
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


bool FlowGraphOptimizer::TryReplaceWithArrayOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  // TODO(fschneider): Optimize []= operator in checked mode as well.
  if (op_kind == Token::kASSIGN_INDEX && FLAG_enable_type_checks) return false;

  const intptr_t class_id = ReceiverClassId(call);
  switch (class_id) {
    case kImmutableArrayCid:
      // Stores are only specialized for Array and GrowableObjectArray,
      // not for ImmutableArray.
      if (op_kind == Token::kASSIGN_INDEX) return false;
      // Fall through.
    case kArrayCid:
    case kGrowableObjectArrayCid: {
      Value* array = call->ArgumentAt(0)->value();
      Value* index = call->ArgumentAt(1)->value();
      // Insert class check and index smi checks and attach a copy of the
      // original environment because the operation can still deoptimize.
      AddCheckClass(call, array->Copy());
      InsertBefore(call,
                   new CheckSmiInstr(index->Copy(), call->deopt_id()),
                   call->env(),
                   Definition::kEffect);
      // If both index and array are constants, then the bound check always
      // succeeded.
      // TODO(srdjan): Remove once constant propagation lands.
      if (!(array->BindsToConstant() && index->BindsToConstant())) {
        // Insert array bounds check.
        InsertBefore(call,
                     new CheckArrayBoundInstr(array->Copy(),
                                              index->Copy(),
                                              class_id,
                                              call),
                     call->env(),
                     Definition::kEffect);
      }
      if (class_id == kGrowableObjectArrayCid) {
        // Insert data elements load.
        LoadFieldInstr* elements =
            new LoadFieldInstr(array->Copy(),
                               GrowableObjectArray::data_offset(),
                               Type::ZoneHandle(Type::DynamicType()));
        elements->set_result_cid(kArrayCid);
        InsertBefore(call, elements, NULL, Definition::kValue);
        array = new Value(elements);
      }
      Definition* array_op = NULL;
      if (op_kind == Token::kINDEX) {
        array_op = new LoadIndexedInstr(array, index);
      } else {
        bool needs_store_barrier = true;
        if (ArgIsAlwaysSmi(*call->ic_data(), 2)) {
          InsertBefore(call,
                       new CheckSmiInstr(call->ArgumentAt(2)->value()->Copy(),
                                         call->deopt_id()),
                       call->env(),
                       Definition::kEffect);
          needs_store_barrier = false;
        }
        Value* value = call->ArgumentAt(2)->value();
        array_op =
            new StoreIndexedInstr(array, index, value, needs_store_barrier);
      }
      call->ReplaceWith(array_op, current_iterator());
      RemovePushArguments(call);
      return true;
    }
    default:
      return false;
  }
}


void FlowGraphOptimizer::InsertBefore(Instruction* instr,
                                      Definition* defn,
                                      Environment* env,
                                      Definition::UseKind use_kind) {
  if (env != NULL) env->DeepCopyTo(defn);
  if (use_kind == Definition::kValue) {
    defn->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
  }
  defn->InsertBefore(instr);
}


void FlowGraphOptimizer::InsertAfter(Instruction* instr,
                                     Definition* defn,
                                     Environment* env,
                                     Definition::UseKind use_kind) {
  if (env != NULL) env->DeepCopyTo(defn);
  if (use_kind == Definition::kValue) {
    defn->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
  }
  defn->InsertAfter(instr);
}


bool FlowGraphOptimizer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
                                                Token::Kind op_kind) {
  intptr_t operands_type = kIllegalCid;
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
      if (HasOnlyTwoSmi(ic_data)) {
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
      // TODO(vegorov): implement fast path code for modulo.
      return false;
    case Token::kBIT_AND:
      if (HasOnlyTwoSmi(ic_data)) {
        operands_type = kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data)) {
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kTRUNCDIV:
    case Token::kSHR:
    case Token::kSHL:
      if (HasOnlyTwoSmi(ic_data)) {
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

    UnboxedDoubleBinaryOpInstr* double_bin_op =
        new UnboxedDoubleBinaryOpInstr(op_kind,
                                       left->Copy(),
                                       right->Copy(),
                                       call);
    call->ReplaceWith(double_bin_op, current_iterator());
    RemovePushArguments(call);
  } else if (operands_type == kMintCid) {
    Value* left = call->ArgumentAt(0)->value();
    Value* right = call->ArgumentAt(1)->value();
    BinaryMintOpInstr* bin_op = new BinaryMintOpInstr(op_kind,
                                                      call,
                                                      left,
                                                      right);
    call->ReplaceWith(bin_op, current_iterator());
    RemovePushArguments(call);
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
  if (call->ic_data()->NumberOfChecks() != 1) {
    // TODO(srdjan): Not yet supported.
    return false;
  }
  ASSERT(call->ArgumentCount() == 1);
  Definition* unary_op = NULL;
  if (HasOneSmi(*call->ic_data())) {
    Value* value = call->ArgumentAt(0)->value();
    InsertBefore(call,
                 new CheckSmiInstr(value->Copy(), call->deopt_id()),
                 call->env(),
                 Definition::kEffect);
    unary_op = new UnarySmiOpInstr(op_kind,
                                   (op_kind == Token::kNEGATE) ? call : NULL,
                                   value);
  } else if (HasOneDouble(*call->ic_data()) && (op_kind == Token::kNEGATE)) {
    Value* value = call->ArgumentAt(0)->value();
    AddCheckClass(call, value->Copy());
    ConstantInstr* minus_one =
        new ConstantInstr(Double::ZoneHandle(Double::NewCanonical(-1)));
    InsertBefore(call, minus_one, NULL, Definition::kValue);
    unary_op = new UnboxedDoubleBinaryOpInstr(Token::kMUL,
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

// Only unique implicit instance getters can be currently handled.
bool FlowGraphOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }
  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  ASSERT(class_ids.length() == 1);

  if (target.kind() == RawFunction::kImplicitGetter) {
    if (!HasOneTarget(ic_data)) {
      // TODO(srdjan): Implement for mutiple targets.
      return false;
    }
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
    return true;
  }

  // Not an implicit getter.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  // VM objects length getter.
  if ((recognized_kind == MethodRecognizer::kObjectArrayLength) ||
      (recognized_kind == MethodRecognizer::kImmutableArrayLength) ||
      (recognized_kind == MethodRecognizer::kGrowableArrayLength)) {
    if (!HasOneTarget(ic_data)) {
      // TODO(srdjan): Implement for mutiple targets.
      return false;
    }
    intptr_t length_offset = -1;
    bool is_immutable = false;
    switch (recognized_kind) {
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
        length_offset = Array::length_offset();
        is_immutable = true;
        break;
      case MethodRecognizer::kGrowableArrayLength:
        length_offset = GrowableObjectArray::length_offset();
        break;
      default:
        UNREACHABLE();
    }
    // Check receiver class.
    AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

    LoadFieldInstr* load = new LoadFieldInstr(
        call->ArgumentAt(0)->value(),
        length_offset,
        Type::ZoneHandle(Type::SmiType()),
        is_immutable);
    load->set_result_cid(kSmiCid);
    call->ReplaceWith(load, current_iterator());
    RemovePushArguments(call);
    return true;
  }

  if (recognized_kind == MethodRecognizer::kGrowableArrayCapacity) {
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

    call->ReplaceWith(length_load, current_iterator());
    RemovePushArguments(call);
    return true;
  }

  if (recognized_kind == MethodRecognizer::kStringBaseLength) {
    if (!HasOneTarget(ic_data)) {
      // Target is not only StringBase_get_length.
      return false;
    }
    // Check receiver class.
    AddCheckClass(call, call->ArgumentAt(0)->value()->Copy());

    const bool is_immutable = true;  // String length is immutable.
    LoadFieldInstr* load = new LoadFieldInstr(
        call->ArgumentAt(0)->value(),
        String::length_offset(),
        Type::ZoneHandle(Type::SmiType()),
        is_immutable);
    load->set_result_cid(kSmiCid);
    call->ReplaceWith(load, current_iterator());
    RemovePushArguments(call);
    return true;
  }
  return false;
}


// Inline only simple, frequently called core library methods.
bool FlowGraphOptimizer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if ((ic_data.NumberOfChecks() == 0) || !HasOneTarget(ic_data)) {
    // No type feedback collected.
    return false;
  }
  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  if ((recognized_kind == MethodRecognizer::kDoubleToDouble) &&
      (class_ids[0] == kDoubleCid)) {
    DoubleToDoubleInstr* d2d_instr =
        new DoubleToDoubleInstr(call->ArgumentAt(0)->value(), call);
    call->ReplaceWith(d2d_instr, current_iterator());
    RemovePushArguments(call);
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
  return false;
}


void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (instr->HasICData() && (instr->ic_data()->NumberOfChecks() > 0)) {
    const Token::Kind op_kind = instr->token_kind();
    if (Token::IsIndexOperator(op_kind) &&
        TryReplaceWithArrayOp(instr, op_kind)) {
      return;
    }
    if (Token::IsBinaryToken(op_kind) &&
        TryReplaceWithBinaryOp(instr, op_kind)) {
      return;
    }
    if (Token::IsUnaryToken(op_kind) &&
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
      // TODO(srdjan): Add check class instr for mixed smi/non-smi.
      if (HasOneTarget(unary_checks) &&
          (unary_checks.GetReceiverClassIdAt(0) != kSmiCid)) {
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
  // An instance call without ICData should continue calling via IC calls
  // which should trigger reoptimization of optimized code.
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
  if (!HasOneTarget(unary_ic_data)) {
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
  ASSERT(HasOneTarget(ic_data));

  if (HasOnlyTwoSmi(ic_data)) {
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
  if (!comp->HasICData() || (comp->ic_data()->NumberOfChecks() == 0)) return;
  if (comp->ic_data()->NumberOfChecks() == 1) {
    ASSERT(comp->ic_data()->num_args_tested() == 2);
    GrowableArray<intptr_t> class_ids;
    Function& target = Function::Handle();
    comp->ic_data()->GetCheckAt(0, &class_ids, &target);
    // TODO(srdjan): allow for mixed mode comparison.
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
    } else {
      ASSERT(comp->receiver_class_id() == kIllegalCid);
    }
  } else if (comp->ic_data()->AllReceiversAreNumbers()) {
    comp->set_receiver_class_id(kNumberCid);
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
class SminessPropagator {
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
  PhiInstr* phi = worklist_.Last();
  ASSERT(in_worklist_->Contains(phi->ssa_temp_index()));
  worklist_.RemoveLast();
  in_worklist_->Remove(phi->ssa_temp_index());
  return phi;
}


static bool IsSmiPhi(PhiInstr* phi) {
  for (intptr_t i = 0; i < phi->InputCount(); i++) {
    Value* input = phi->InputAt(i);
    if ((input->definition() != phi) &&
        (input->ResultCid() != kSmiCid)) {
      return false;
    }
  }
  return true;
}


void SminessPropagator::ProcessPhis() {
  while (!worklist_.is_empty()) {
    PhiInstr* phi = RemoveLastFromWorklist();
    if (IsSmiPhi(phi)) {
      ASSERT(phi->GetPropagatedCid() != kSmiCid);
      phi->SetPropagatedCid(kSmiCid);
      for (Value* use = phi->input_use_list();
           use != NULL;
           use = use->next_use()) {
        if (use->definition()->IsPhi() &&
            (use->definition()->GetPropagatedCid() != kSmiCid)) {
          AddToWorklist(use->definition()->AsPhi());
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
  if (graph_entry->start_env() == NULL) {
    return;
  }
  // Visit incoming parameters.
  for (intptr_t i = 0; i < graph_entry->start_env()->Length(); i++) {
    Value* val = graph_entry->start_env()->ValueAt(i);
    ParameterInstr* param = val->definition()->AsParameter();
    if (param != NULL) {
      ASSERT(param->index() == i);
      VisitParameter(param);
    }
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
  if (param->index() < 2) {
    const Function& function = parsed_function().function();
    if (((param->index() == 0) && function.IsDynamicFunction()) ||
        ((param->index() == 1) && function.IsConstructor())) {
      // Parameter is the receiver or the constructor phase.
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


void FlowGraphAnalyzer::Analyze() {
  is_leaf_ = true;
  for (intptr_t i = 0; i < blocks_.length(); ++i) {
    BlockEntryInstr* entry = blocks_[i];
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      LocationSummary* locs = it.Current()->locs();
      if ((locs != NULL) && locs->can_call()) {
        is_leaf_ = false;
        return;
      }
    }
  }
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
                 Definition* current) {
  // TODO(fschneider): Avoid repeated deoptimization when
  // speculatively hoisting checks.
  if (FLAG_trace_optimization) {
    OS::Print("Hoisting instruction %s:%"Pd" from B%"Pd" to B%"Pd"\n",
              current->DebugName(),
              current->deopt_id(),
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
                                      Definition* current) {
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
  current->SetInputAt(non_smi_input, phi->InputAt(non_smi_input));
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
        Definition* current = it.Current()->AsDefinition();
        if (current != NULL &&
            !current->IsPushArgument() &&
            !current->AffectedBySideEffect()) {
          bool inputs_loop_invariant = true;
          for (int i = 0; i < current->InputCount(); ++i) {
            Definition* input_def = current->InputAt(i)->definition();
            if (!input_def->GetBlock()->Dominates(pre_header)) {
              inputs_loop_invariant = false;
              break;
            }
          }
          if (inputs_loop_invariant) {
            Hoist(&it, pre_header, current);
          } else if (current->IsCheckSmi() &&
                     current->InputAt(0)->definition()->IsPhi()) {
            TryHoistCheckSmiThroughPhi(&it, header, pre_header, current);
          }
        }
      }
    }
  }
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
      if ((defn == NULL) ||
          !defn->IsLoadField() ||
          !defn->AffectedBySideEffect()) {
        // TODO(fschneider): Extend to other load instructions.
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
      if ((defn == NULL) ||
          !defn->IsLoadField() ||
          !defn->AffectedBySideEffect()) {
        // TODO(fschneider): Extend to other load instructions.
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


static void OptimizeLoads(
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
    if ((defn == NULL) ||
        !defn->IsLoadField() ||
        !defn->AffectedBySideEffect()) {
      // Immutable loads are handled in normal CSE.
      // TODO(fschneider): Extend to other load instructions.
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
      OptimizeLoads(child, &child_defs, avail_in);
    } else {
      OptimizeLoads(child, definitions, avail_in);
    }
  }
}


void DominatorBasedCSE::Optimize(FlowGraph* graph) {
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

      OptimizeLoads(graph->graph_entry(), &definitions, avail_in);
    }
  }

  DirectChainedHashMap<Definition*> map;
  OptimizeRecursive(graph->graph_entry(), &map);
}


void DominatorBasedCSE::OptimizeRecursive(
    BlockEntryInstr* block,
    DirectChainedHashMap<Definition*>* map) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Definition* defn = it.Current()->AsDefinition();
    if ((defn == NULL) || defn->AffectedBySideEffect()) continue;
    Definition* result = map->Lookup(defn);
    if (result == NULL) {
      map->Insert(defn);
      continue;
    }
    // Replace current with lookup result.
    defn->ReplaceUsesWith(result);
    it.RemoveCurrentFromGraph();
    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%"Pd" with v%"Pd"\n",
                defn->ssa_temp_index(),
                result->ssa_temp_index());
    }
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i  < num_children - 1) {
      DirectChainedHashMap<Definition*> child_map(*map);  // Copy map.
      OptimizeRecursive(child, &child_map);
    } else {
      OptimizeRecursive(child, map);  // Reuse map for the last child.
    }
  }
}


}  // namespace dart
