// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/flow_graph_builder.h"
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

void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


void FlowGraphOptimizer::OptimizeComputations() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      BindInstr* instr = it.Current()->AsBind();
      if (instr != NULL) {
        Definition* result = instr->computation()->TryReplace(instr);
        if (result != NULL) {
          // Replace uses and remove the current instructions via the iterator.
          instr->ReplaceUsesWith(result);
          it.RemoveCurrentFromGraph();
          if (FLAG_trace_optimization) {
            OS::Print("Replacing v%d with v%d\n",
                      instr->ssa_temp_index(),
                      result->ssa_temp_index());
          }
        }
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
                           GrowableArray<intptr_t>* class_ids) {
  for (intptr_t i = 0; i < class_ids->length(); i++) {
    if ((*class_ids)[i] == class_id) {
      return true;
    }
  }
  return false;
}


static bool ICDataHasOnlyReceiverArgumentClassIds(
    const ICData& ic_data,
    GrowableArray<intptr_t>* receiver_class_ids,
    GrowableArray<intptr_t>* argument_class_ids) {
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
  GrowableArray<intptr_t> class_ids;
  class_ids.Add(kSmiCid);
  class_ids.Add(kMintCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, &class_ids, &class_ids);
}


static bool HasOneDouble(const ICData& ic_data) {
  return ICDataHasReceiverClassId(ic_data, kDoubleCid);
}


static bool HasOnlyTwoDouble(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1) &&
      ICDataHasReceiverArgumentClassIds(ic_data, kDoubleCid, kDoubleCid);
}


static void RemovePushArguments(InstanceCallComp* comp) {
  // Remove original push arguments.
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    comp->ArgumentAt(i)->RemoveFromGraph();
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


static intptr_t ReceiverClassId(Computation* comp) {
  if (!comp->HasICData()) return kIllegalCid;

  const ICData& ic_data = *comp->ic_data();

  if (ic_data.NumberOfChecks() == 0) return kIllegalCid;
  // TODO(vegorov): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return kIllegalCid;
  ASSERT(HasOneTarget(ic_data));

  Function& target = Function::Handle();
  intptr_t class_id;
  ic_data.GetOneClassCheckAt(0, &class_id, &target);
  return class_id;
}


bool FlowGraphOptimizer::TryReplaceWithArrayOp(BindInstr* instr,
                                               InstanceCallComp* comp,
                                               Token::Kind op_kind) {
  // TODO(fschneider): Optimize []= operator in checked mode as well.
  if (op_kind == Token::kASSIGN_INDEX && FLAG_enable_type_checks) return false;

  const intptr_t class_id = ReceiverClassId(comp);
  switch (class_id) {
    case kImmutableArrayCid:
      // Stores are only specialized for Array and GrowableObjectArray,
      // not for ImmutableArray.
      if (op_kind == Token::kASSIGN_INDEX) return false;
      // Fall through.
    case kArrayCid:
    case kGrowableObjectArrayCid: {
      Computation* array_op = NULL;
      if (op_kind == Token::kINDEX) {
          array_op = new LoadIndexedComp(comp->ArgumentAt(0)->value(),
                                         comp->ArgumentAt(1)->value(),
                                         class_id,
                                         comp);
      } else {
          array_op = new StoreIndexedComp(comp->ArgumentAt(0)->value(),
                                          comp->ArgumentAt(1)->value(),
                                          comp->ArgumentAt(2)->value(),
                                          class_id,
                                          comp);
      }
      array_op->set_ic_data(comp->ic_data());
      instr->set_computation(array_op);
      RemovePushArguments(comp);
      return true;
    }
    default:
      return false;
  }
}


bool FlowGraphOptimizer::TryReplaceWithBinaryOp(BindInstr* instr,
                                                InstanceCallComp* comp,
                                                Token::Kind op_kind) {
  BinaryOpComp::OperandsType operands_type = BinaryOpComp::kDynamicOperands;
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
      if (HasOnlyTwoSmi(ic_data)) {
        operands_type = BinaryOpComp::kSmiOperands;
      } else if (HasOnlyTwoDouble(ic_data)) {
        operands_type = BinaryOpComp::kDoubleOperands;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
    case Token::kMOD:
      if (HasOnlyTwoDouble(ic_data)) {
        operands_type = BinaryOpComp::kDoubleOperands;
      } else {
        return false;
      }
    case Token::kBIT_AND:
      if (HasOnlyTwoSmi(ic_data)) {
        operands_type = BinaryOpComp::kSmiOperands;
      } else if (HasTwoMintOrSmi(ic_data)) {
        operands_type = BinaryOpComp::kMintOperands;
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
        operands_type = BinaryOpComp::kSmiOperands;
      } else {
        return false;
      }
      break;
    default:
      UNREACHABLE();
  };

  ASSERT(comp->ArgumentCount() == 2);
  if (operands_type == BinaryOpComp::kDoubleOperands) {
    DoubleBinaryOpComp* double_bin_op = new DoubleBinaryOpComp(op_kind, comp);
    double_bin_op->set_ic_data(comp->ic_data());
    instr->set_computation(double_bin_op);
  } else {
    Value* left = comp->ArgumentAt(0)->value();
    Value* right = comp->ArgumentAt(1)->value();
    BinaryOpComp* bin_op =
        new BinaryOpComp(op_kind,
                         operands_type,
                         comp,
                         left,
                         right);
    bin_op->set_ic_data(comp->ic_data());
    instr->set_computation(bin_op);
    RemovePushArguments(comp);
  }
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithUnaryOp(BindInstr* instr,
                                               InstanceCallComp* comp,
                                               Token::Kind op_kind) {
  if (comp->ic_data()->NumberOfChecks() != 1) {
    // TODO(srdjan): Not yet supported.
    return false;
  }
  ASSERT(comp->ArgumentCount() == 1);
  Computation* unary_op = NULL;
  if (HasOneSmi(*comp->ic_data())) {
    unary_op = new UnarySmiOpComp(op_kind, comp, comp->ArgumentAt(0)->value());
  } else if (HasOneDouble(*comp->ic_data()) && (op_kind == Token::kNEGATE)) {
    unary_op = new NumberNegateComp(comp, comp->ArgumentAt(0)->value());
  }
  if (unary_op == NULL) return false;

  unary_op->set_ic_data(comp->ic_data());
  instr->set_computation(unary_op);
  RemovePushArguments(comp);
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


// Only unique implicit instance getters can be currently handled.
bool FlowGraphOptimizer::TryInlineInstanceGetter(BindInstr* instr,
                                                 InstanceCallComp* comp) {
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
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
        String::Handle(Field::NameFromGetter(comp->function_name()));
    const Field& field = Field::Handle(GetField(class_ids[0], field_name));
    ASSERT(!field.IsNull());
    LoadInstanceFieldComp* load = new LoadInstanceFieldComp(
        field, comp->ArgumentAt(0)->value(), comp);
    load->set_ic_data(comp->ic_data());
    instr->set_computation(load);
    RemovePushArguments(comp);
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
    switch (recognized_kind) {
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
        length_offset = Array::length_offset();
        break;
      case MethodRecognizer::kGrowableArrayLength:
        length_offset = GrowableObjectArray::length_offset();
        break;
      default:
        UNREACHABLE();
    }
    LoadVMFieldComp* load = new LoadVMFieldComp(
        comp->ArgumentAt(0)->value(),
        length_offset,
        Type::ZoneHandle(Type::IntInterface()));
    load->set_original(comp);
    load->set_ic_data(comp->ic_data());
    instr->set_computation(load);
    RemovePushArguments(comp);
    return true;
  }

  if (recognized_kind == MethodRecognizer::kStringBaseLength) {
    if (!HasOneTarget(ic_data)) {
      // Target is not only StringBase_get_length.
      return false;
    }
    ASSERT(HasOneTarget(ic_data));
    LoadVMFieldComp* load = new LoadVMFieldComp(
        comp->ArgumentAt(0)->value(),
        String::length_offset(),
        Type::ZoneHandle(Type::IntInterface()));
    load->set_original(comp);
    load->set_ic_data(comp->ic_data());
    instr->set_computation(load);
    RemovePushArguments(comp);
    return true;
  }
  return false;
}


// Inline only simple, frequently called core library methods.
bool FlowGraphOptimizer::TryInlineInstanceMethod(BindInstr* instr,
                                                 InstanceCallComp* comp) {
  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
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
    DoubleToDoubleComp* d2d_comp =
        new DoubleToDoubleComp(comp->ArgumentAt(0)->value(), comp);
    instr->set_computation(d2d_comp);
    RemovePushArguments(comp);
    return true;
  }
  if ((recognized_kind == MethodRecognizer::kIntegerToDouble) &&
             (class_ids[0] == kSmiCid)) {
    SmiToDoubleComp* s2d_comp = new SmiToDoubleComp(comp);
    instr->set_computation(s2d_comp);
    // Pushed arguments are not removed because SmiToDouble is implemented
    // as a call.
    return true;
  }
  return false;
}


void FlowGraphOptimizer::VisitInstanceCall(InstanceCallComp* comp,
                                           BindInstr* instr) {
  if (comp->HasICData() && (comp->ic_data()->NumberOfChecks() > 0)) {
    const Token::Kind op_kind = comp->token_kind();
    if (Token::IsIndexOperator(op_kind) &&
        TryReplaceWithArrayOp(instr, comp, op_kind)) {
      return;
    }
    if (Token::IsBinaryToken(op_kind) &&
        TryReplaceWithBinaryOp(instr, comp, op_kind)) {
      return;
    }
    if (Token::IsUnaryToken(op_kind) &&
        TryReplaceWithUnaryOp(instr, comp, op_kind)) {
      return;
    }
    if ((op_kind == Token::kGET) && TryInlineInstanceGetter(instr, comp)) {
      return;
    }
    if ((op_kind == Token::kSET) && TryInlineInstanceSetter(instr, comp)) {
      return;
    }
    if (TryInlineInstanceMethod(instr, comp)) {
      return;
    }
    const intptr_t kMaxChecks = 4;
    if (comp->ic_data()->NumberOfChecks() <= kMaxChecks) {
      PolymorphicInstanceCallComp* call = new PolymorphicInstanceCallComp(comp);
      ICData& unary_checks =
          ICData::ZoneHandle(comp->ic_data()->AsUnaryClassChecks());
      call->set_ic_data(&unary_checks);
      instr->set_computation(call);
    }
  }
  // An instance call without ICData should continue calling via IC calls
  // which should trigger reoptimization of optimized code.
}


void FlowGraphOptimizer::VisitStaticCall(StaticCallComp* comp,
                                         BindInstr* instr) {
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(comp->function());
  if (recognized_kind == MethodRecognizer::kMathSqrt) {
    comp->set_recognized(MethodRecognizer::kMathSqrt);
  }
}


bool FlowGraphOptimizer::TryInlineInstanceSetter(BindInstr* instr,
                                                 InstanceCallComp* comp) {
  if (FLAG_enable_type_checks) {
    // TODO(srdjan): Add assignable check node if --enable_type_checks.
    return false;
  }

  ASSERT(comp->HasICData());
  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }
  if (!HasOneTarget(ic_data)) {
    // TODO(srdjan): Implement when not all targets are the same.
    return false;
  }
  Function& target = Function::Handle();
  intptr_t class_id;
  ic_data.GetOneClassCheckAt(0, &class_id, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Not an implicit setter.
    // TODO(srdjan): Inline special setters.
    return false;
  }
  // Inline implicit instance setter.
  const String& field_name =
      String::Handle(Field::NameFromSetter(comp->function_name()));
  const Field& field = Field::Handle(GetField(class_id, field_name));
  ASSERT(!field.IsNull());
  StoreInstanceFieldComp* store = new StoreInstanceFieldComp(
      field,
      comp->ArgumentAt(0)->value(),
      comp->ArgumentAt(1)->value(),
      comp);
  store->set_ic_data(comp->ic_data());
  instr->set_computation(store);
  RemovePushArguments(comp);
  return true;
}


void FlowGraphOptimizer::VisitRelationalOp(RelationalOpComp* comp,
                                           BindInstr* instr) {
  if (!comp->HasICData()) return;

  const ICData& ic_data = *comp->ic_data();
  if (ic_data.NumberOfChecks() == 0) return;
  // TODO(srdjan): Add multiple receiver type support.
  if (ic_data.NumberOfChecks() != 1) return;
  ASSERT(HasOneTarget(ic_data));

  if (HasOnlyTwoSmi(ic_data)) {
    comp->set_operands_class_id(kSmiCid);
  } else if (HasOnlyTwoDouble(ic_data)) {
    comp->set_operands_class_id(kDoubleCid);
  } else if (comp->ic_data()->AllReceiversAreNumbers()) {
    comp->set_operands_class_id(kNumberCid);
  }
}


void FlowGraphOptimizer::VisitEqualityCompare(EqualityCompareComp* comp,
                                              BindInstr* instr) {
  if (!comp->HasICData() || (comp->ic_data()->NumberOfChecks() == 0)) return;
  if (comp->ic_data()->NumberOfChecks() == 1) {
    ASSERT(comp->ic_data()->num_args_tested() == 2);
    GrowableArray<intptr_t> class_ids;
    Function& target = Function::Handle();
    comp->ic_data()->GetCheckAt(0, &class_ids, &target);
    // TODO(srdjan): allow for mixed mode comparison.
    if ((class_ids[0] == kSmiCid) && (class_ids[1] == kSmiCid)) {
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


void FlowGraphOptimizer::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this, instr);
}


void FlowGraphTypePropagator::VisitAssertAssignable(AssertAssignableComp* comp,
                                                    BindInstr* instr) {
  if (FLAG_eliminate_type_checks &&
      !comp->is_eliminated() &&
      !comp->dst_type().IsMalformed() &&
      comp->value()->CompileTypeIsMoreSpecificThan(comp->dst_type())) {
    comp->eliminate();
    if (FLAG_trace_type_check_elimination) {
      FlowGraphPrinter::PrintTypeCheck(parsed_function(),
                                       comp->token_pos(),
                                       comp->value(),
                                       comp->dst_type(),
                                       comp->dst_name(),
                                       comp->is_eliminated());
    }
  }
}


void FlowGraphTypePropagator::VisitAssertBoolean(AssertBooleanComp* comp,
                                                 BindInstr* instr) {
  if (FLAG_eliminate_type_checks &&
      !comp->is_eliminated() &&
      comp->value()->CompileTypeIsMoreSpecificThan(
          Type::Handle(Type::BoolInterface()))) {
    comp->eliminate();
    if (FLAG_trace_type_check_elimination) {
      const String& name = String::Handle(Symbols::New("boolean expression"));
      FlowGraphPrinter::PrintTypeCheck(parsed_function(),
                                       comp->token_pos(),
                                       comp->value(),
                                       Type::Handle(Type::BoolInterface()),
                                       name,
                                       comp->is_eliminated());
    }
  }
}


void FlowGraphTypePropagator::VisitGraphEntry(GraphEntryInstr* graph_entry) {
  if (graph_entry->start_env() == NULL) {
    return;
  }
  // Visit incoming parameters.
  for (intptr_t i = 0; i < graph_entry->start_env()->values().length(); i++) {
    Value* val = graph_entry->start_env()->values()[i];
    if (val->IsUse()) {
      ParameterInstr* param = val->AsUse()->definition()->AsParameter();
      if (param != NULL) {
        ASSERT(param->index() == i);
        VisitParameter(param);
      }
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


void FlowGraphTypePropagator::VisitBind(BindInstr* bind) {
  // No need to propagate the input types of the bound computation, as long as
  // PhiInstr's are handled as part of JoinEntryInstr.
  // Visit computation and possibly eliminate type check.
  bind->computation()->Accept(this, bind);
  // Cache propagated computation type.
  AbstractType& type = AbstractType::Handle(bind->computation()->CompileType());
  bool changed = bind->SetPropagatedType(type);
  if (changed) {
    still_changing_ = true;
  }
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
}


void FlowGraphTypePropagator::VisitParameter(ParameterInstr* param) {
  // TODO(regis): Once we inline functions, the propagated type of the formal
  // parameter will reflect the compile type of the passed-in argument.
  // For now, we do not know anything about the argument type and therefore set
  // it to the DynamicType, unless the argument is a compiler generated value,
  // i.e. the receiver argument or the constructor phase argument.
  AbstractType& param_type = AbstractType::Handle(Type::DynamicType());
  if (param->index() < 2) {
    const Function& function = parsed_function().function();
    if (((param->index() == 0) && function.IsDynamicFunction()) ||
        ((param->index() == 1) && function.IsConstructor())) {
      // Parameter is the receiver or the constructor phase.
      LocalScope* scope = parsed_function().node_sequence()->scope();
      param_type = scope->VariableAt(param->index())->type().raw();
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

}  // namespace dart
