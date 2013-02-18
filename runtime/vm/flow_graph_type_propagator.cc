// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_type_propagator.h"

#include "vm/cha.h"
#include "vm/bit_vector.h"

namespace dart {

DEFINE_FLAG(bool, trace_type_propagation, false,
            "Trace flow graph type propagation");

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, use_cha);


FlowGraphTypePropagator::FlowGraphTypePropagator(FlowGraph* flow_graph)
    : FlowGraphVisitor(flow_graph->reverse_postorder()),
      flow_graph_(flow_graph),
      types_(flow_graph->current_ssa_temp_index()),
      in_worklist_(new BitVector(flow_graph->current_ssa_temp_index())) {
  for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
    types_.Add(NULL);
  }
}


void FlowGraphTypePropagator::Propagate() {
  // Walk dominator tree and propagate reaching types to all Values.
  // Collect all phis for a fix point iteration.
  PropagateRecursive(flow_graph_->graph_entry());

#ifdef DEBUG
  // Initially work-list contains only phis.
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    ASSERT(worklist_[i]->IsPhi());
    ASSERT(worklist_[i]->Type()->IsNone());
  }
#endif

  // Iterate until fix point is reached updating types of definitions.
  while (!worklist_.is_empty()) {
    Definition* def = RemoveLastFromWorklist();
    if (FLAG_trace_type_propagation) {
      OS::Print("recomputing type of v%"Pd": %s\n",
                def->ssa_temp_index(),
                def->Type()->ToCString());
    }
    if (def->RecomputeType()) {
      if (FLAG_trace_type_propagation) {
        OS::Print("  ... new type %s\n", def->Type()->ToCString());
      }
      for (Value::Iterator it(def->input_use_list());
           !it.Done();
           it.Advance()) {
        Definition* use_defn = it.Current()->instruction()->AsDefinition();
        if (use_defn != NULL) {
          AddToWorklist(use_defn);
        }
      }
    }
  }
}


void FlowGraphTypePropagator::PropagateRecursive(BlockEntryInstr* block) {
  const intptr_t rollback_point = rollback_.length();

  block->Accept(this);

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();

    for (intptr_t i = 0; i < instr->InputCount(); i++) {
      VisitValue(instr->InputAt(i));
    }
    instr->Accept(this);
  }

  GotoInstr* goto_instr = block->last_instruction()->AsGoto();
  if (goto_instr != NULL) {
    JoinEntryInstr* join = goto_instr->successor();
    intptr_t pred_index = join->IndexOfPredecessor(block);
    ASSERT(pred_index >= 0);
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      VisitValue(it.Current()->InputAt(pred_index));
    }
  }

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    PropagateRecursive(block->dominated_blocks()[i]);
  }

  for (intptr_t i = rollback_.length() - 1; i >= rollback_point; i--) {
    types_[rollback_[i].index()] = rollback_[i].type();
  }
  rollback_.TruncateTo(rollback_point);
}


CompileType* FlowGraphTypePropagator::TypeOf(Definition* def) {
  const intptr_t index = def->ssa_temp_index();

  CompileType* type = types_[index];
  if (type == NULL) {
    type = types_[index] = def->Type();
    ASSERT(type != NULL);
  }
  return type;
}


void FlowGraphTypePropagator::SetTypeOf(Definition* def, CompileType* type) {
  const intptr_t index = def->ssa_temp_index();
  rollback_.Add(RollbackEntry(index, types_[index]));
  types_[index] = type;
}


void FlowGraphTypePropagator::SetCid(Definition* def, intptr_t cid) {
  CompileType* current = TypeOf(def);
  if (current->ToCid() == cid) return;

  SetTypeOf(def, CompileType::FromCid(cid));
}


void FlowGraphTypePropagator::VisitValue(Value* value) {
  CompileType* type = TypeOf(value->definition());
  value->SetReachingType(type);

  if (FLAG_trace_type_propagation) {
    OS::Print("reaching type to v%"Pd" for v%"Pd" is %s\n",
              value->instruction()->IsDefinition() ?
                  value->instruction()->AsDefinition()->ssa_temp_index() : -1,
              value->definition()->ssa_temp_index(),
              type->ToCString());
  }
}


void FlowGraphTypePropagator::VisitJoinEntry(JoinEntryInstr* join) {
  for (PhiIterator it(join); !it.Done(); it.Advance()) {
    if (it.Current()->is_alive()) {
      worklist_.Add(it.Current());
    }
  }
}


void FlowGraphTypePropagator::VisitCheckSmi(CheckSmiInstr* check) {
  SetCid(check->value()->definition(), kSmiCid);
}


void FlowGraphTypePropagator::VisitCheckClass(CheckClassInstr* check) {
  if ((check->unary_checks().NumberOfChecks() != 1) ||
      check->AffectedBySideEffect()) {
    // TODO(vegorov): If check is affected by side-effect we can still propagate
    // the type further but not the cid.
    return;
  }

  SetCid(check->value()->definition(),
         check->unary_checks().GetReceiverClassIdAt(0));
}


void FlowGraphTypePropagator::AddToWorklist(Definition* defn) {
  if (defn->ssa_temp_index() == -1) {
    return;
  }

  const intptr_t index = defn->ssa_temp_index();
  if (!in_worklist_->Contains(index)) {
    worklist_.Add(defn);
    in_worklist_->Add(index);
  }
}


Definition* FlowGraphTypePropagator::RemoveLastFromWorklist() {
  Definition* defn = worklist_.RemoveLast();
  ASSERT(defn->ssa_temp_index() != -1);
  in_worklist_->Remove(defn->ssa_temp_index());
  return defn;
}


void CompileType::Union(CompileType* other) {
  if (other->IsNone()) {
    return;
  }

  if (IsNone()) {
    ReplaceWith(other);
    return;
  }

  is_nullable_ = is_nullable_ || other->is_nullable_;

  if (ToNullableCid() == kNullCid) {
    cid_ = other->cid_;
    type_ = other->type_;
    return;
  }

  if (other->ToNullableCid() == kNullCid) {
    return;
  }

  if (ToNullableCid() != other->ToNullableCid()) {
    ASSERT(cid_ != kNullCid);
    cid_ = kDynamicCid;
  }

  if (ToAbstractType()->IsMoreSpecificThan(*other->ToAbstractType(), NULL)) {
    type_ = other->ToAbstractType();
  } else if (ToAbstractType()->IsMoreSpecificThan(*ToAbstractType(), NULL)) {
    // Nothing to do.
  } else {
    // Can't unify.
    type_ = &Type::ZoneHandle(Type::DynamicType());
  }
}


static bool IsNullableCid(intptr_t cid) {
  ASSERT(cid != kIllegalCid);
  return cid == kNullCid || cid == kDynamicCid;
}


CompileType* CompileType::New(intptr_t cid, const AbstractType& type) {
  return new CompileType(IsNullableCid(cid), cid, &type);
}


CompileType* CompileType::FromAbstractType(const AbstractType& type,
                                           bool is_nullable) {
  return new CompileType(is_nullable, kIllegalCid, &type);
}


CompileType* CompileType::FromCid(intptr_t cid) {
  return new CompileType(IsNullableCid(cid), cid, NULL);
}


CompileType* CompileType::Dynamic() {
  return New(kDynamicCid, Type::ZoneHandle(Type::DynamicType()));
}


CompileType* CompileType::Null() {
  return New(kNullCid, Type::ZoneHandle(Type::NullType()));
}


CompileType* CompileType::Bool() {
  return New(kBoolCid, Type::ZoneHandle(Type::BoolType()));
}


CompileType* CompileType::Int() {
  return FromAbstractType(Type::ZoneHandle(Type::IntType()), kNonNullable);
}


intptr_t CompileType::ToCid() {
  if ((cid_ == kNullCid) || (cid_ == kDynamicCid)) {
    return cid_;
  }

  return is_nullable_ ? static_cast<intptr_t>(kDynamicCid) : ToNullableCid();
}


intptr_t CompileType::ToNullableCid() {
  if (cid_ == kIllegalCid) {
    ASSERT(type_ != NULL);

    if (type_->IsMalformed()) {
      cid_ = kDynamicCid;
    } else if (type_->IsVoidType()) {
      cid_ = kNullCid;
    } else if (FLAG_use_cha && type_->HasResolvedTypeClass()) {
      const intptr_t cid = Class::Handle(type_->type_class()).id();
      cid_ = !CHA::HasSubclasses(cid) ? cid : kDynamicCid;
    } else {
      cid_ = kDynamicCid;
    }
  }

  return cid_;
}


bool CompileType::HasDecidableNullability() {
  return !is_nullable_ || IsNull();
}


bool CompileType::IsNull() {
  return (ToCid() == kNullCid);
}


const AbstractType* CompileType::ToAbstractType() {
  if (type_ == NULL) {
    ASSERT(cid_ != kIllegalCid);

    const Class& type_class =
        Class::Handle(Isolate::Current()->class_table()->At(cid_));

    if (type_class.HasTypeArguments()) {
      type_ = &Type::ZoneHandle(Type::DynamicType());
      return type_;
    }

    type_ = &Type::ZoneHandle(Type::NewNonParameterizedType(type_class));
  }

  return type_;
}


bool CompileType::CanComputeIsInstanceOf(const AbstractType& type,
                                         bool is_nullable,
                                         bool* is_instance) {
  ASSERT(is_instance != NULL);
  // We cannot give an answer if the given type is malformed.
  if (type.IsMalformed()) {
    return false;
  }

  if (type.IsDynamicType() || type.IsObjectType()) {
    *is_instance = true;
    return true;
  }

  if (IsNone()) {
    return false;
  }

  // We should never test for an instance of null.
  ASSERT(!type.IsNullType());

  // Consider the compile type of the value.
  const AbstractType& compile_type = *ToAbstractType();
  if (compile_type.IsMalformed()) {
    return false;
  }

  // If the compile type of the value is void, we are type checking the result
  // of a void function, which was checked to be null at the return statement
  // inside the function.
  if (compile_type.IsVoidType()) {
    ASSERT(FLAG_enable_type_checks);
    *is_instance = true;
    return true;
  }

  // The Null type is only a subtype of Object and of dynamic.
  // Functions that do not explicitly return a value, implicitly return null,
  // except generative constructors, which return the object being constructed.
  // It is therefore acceptable for void functions to return null.
  if (compile_type.IsNullType()) {
    *is_instance = is_nullable ||
        type.IsObjectType() || type.IsDynamicType() || type.IsVoidType();
    return true;
  }

  // A non-null value is not an instance of void.
  if (type.IsVoidType()) {
    *is_instance = IsNull();
    return HasDecidableNullability();
  }

  // If the value can be null then we can't eliminate the
  // check unless null is allowed.
  if (is_nullable_ && !is_nullable) {
    return false;
  }

  Error& malformed_error = Error::Handle();
  *is_instance = compile_type.IsMoreSpecificThan(type, &malformed_error);
  return malformed_error.IsNull() && *is_instance;
}


bool CompileType::IsMoreSpecificThan(const AbstractType& other) {
  return !IsNone() && ToAbstractType()->IsMoreSpecificThan(other, NULL);
}


CompileType* Value::Type() {
  if (reaching_type_ == NULL) {
    reaching_type_ = definition()->Type();
  }
  return reaching_type_;
}


CompileType* PhiInstr::ComputeInitialType() const {
  // Initially type of phis is unknown until type propagation is run
  // for the first time.
  return CompileType::None();
}


bool PhiInstr::RecomputeType() {
  if (!is_alive()) {
    return false;
  }

  CompileType* result = CompileType::None();

  for (intptr_t i = 0; i < InputCount(); i++) {
    if (FLAG_trace_type_propagation) {
      OS::Print("  phi %"Pd" input %"Pd": v%"Pd" has reaching type %s\n",
                ssa_temp_index(),
                i,
                InputAt(i)->definition()->ssa_temp_index(),
                InputAt(i)->Type()->ToCString());
    }
    result->Union(InputAt(i)->Type());
  }

  if (result->IsNone()) {
    ASSERT(Type()->IsNone());
    return false;
  }

  if (Type()->IsNone() || !Type()->IsEqualTo(result)) {
    Type()->ReplaceWith(result);
    return true;
  }

  return false;
}


static bool CanTrustParameterType(const Function& function, intptr_t index) {
  // Parameter is receiver.
  if (index == 0) {
    return function.IsDynamicFunction() || function.IsConstructor();
  }

  // Parameter is the constructor phase.
  return (index == 1) && function.IsConstructor();
}


CompileType* ParameterInstr::ComputeInitialType() const {
  // Note that returning the declared type of the formal parameter would be
  // incorrect, because ParameterInstr is used as input to the type check
  // verifying the run time type of the passed-in parameter and this check would
  // always be wrongly eliminated.
  // However there are parameters that are known to match their declared type:
  // for example receiver and construction phase.
  if (!CanTrustParameterType(block_->parsed_function().function(),
                             index())) {
    return CompileType::Dynamic();
  }

  LocalScope* scope = block_->parsed_function().node_sequence()->scope();
  return CompileType::FromAbstractType(scope->VariableAt(index())->type(),
                                       CompileType::kNonNullable);
}


CompileType* PushArgumentInstr::ComputeInitialType() const {
  return CompileType::Dynamic();
}


CompileType* ConstantInstr::ComputeInitialType() const {
  if (value().IsNull()) {
    return CompileType::Null();
  }

  if (value().IsInstance()) {
    return CompileType::New(
        Class::Handle(value().clazz()).id(),
        AbstractType::ZoneHandle(Instance::Cast(value()).GetType()));
  } else {
    ASSERT(value().IsAbstractTypeArguments());
    return CompileType::Dynamic();
  }
}


CompileType* AssertAssignableInstr::ComputeInitialType() const {
  CompileType* value_type = value()->Type();
  if (value_type->IsMoreSpecificThan(dst_type())) {
    return value_type;
  }
  return CompileType::FromAbstractType(dst_type());
}


bool AssertAssignableInstr::RecomputeType() {
  CompileType* value_type = value()->Type();
  if (value_type == Type()) {
    return false;
  }

  if (value_type->IsMoreSpecificThan(dst_type()) &&
      !Type()->IsEqualTo(value_type)) {
    Type()->ReplaceWith(value_type);
    return true;
  }

  return false;
}


CompileType* AssertBooleanInstr::ComputeInitialType() const {
  return CompileType::Bool();
}


CompileType* ArgumentDefinitionTestInstr::ComputeInitialType() const {
  return CompileType::Bool();
}


CompileType* BooleanNegateInstr::ComputeInitialType() const {
  return CompileType::Bool();
}


CompileType* InstanceOfInstr::ComputeInitialType() const {
  return CompileType::Bool();
}


CompileType* StrictCompareInstr::ComputeInitialType() const {
  return CompileType::Bool();
}


CompileType* EqualityCompareInstr::ComputeInitialType() const {
  return IsInlinedNumericComparison() ? CompileType::Bool()
                                      : CompileType::Dynamic();
}


CompileType* RelationalOpInstr::ComputeInitialType() const {
  return IsInlinedNumericComparison() ? CompileType::Bool()
                                      : CompileType::Dynamic();
}


CompileType* CurrentContextInstr::ComputeInitialType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType* CloneContextInstr::ComputeInitialType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType* AllocateContextInstr::ComputeInitialType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType* StaticCallInstr::ComputeInitialType() const {
  if (result_cid_ != kDynamicCid) {
    return CompileType::FromCid(result_cid_);
  }

  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(
        AbstractType::ZoneHandle(function().result_type()));
  }

  return CompileType::Dynamic();
}


CompileType* LoadLocalInstr::ComputeInitialType() const {
  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(local().type());
  }
  return CompileType::Dynamic();
}


CompileType* StoreLocalInstr::ComputeInitialType() const {
  // Returns stored value.
  return value()->Type();
}


CompileType* StringFromCharCodeInstr::ComputeInitialType() const {
  return CompileType::FromCid(cid_);
}


CompileType* StoreInstanceFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType* LoadStaticFieldInstr::ComputeInitialType() const {
  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(
        AbstractType::ZoneHandle(field().type()));
  }
  return CompileType::Dynamic();
}


CompileType* StoreStaticFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType* CreateArrayInstr::ComputeInitialType() const {
  return CompileType::FromAbstractType(type(), CompileType::kNonNullable);
}


CompileType* CreateClosureInstr::ComputeInitialType() const {
  const Function& fun = function();
  const Class& signature_class = Class::Handle(fun.signature_class());
  return CompileType::FromAbstractType(
      Type::ZoneHandle(signature_class.SignatureType()),
      CompileType::kNonNullable);
}


CompileType* AllocateObjectInstr::ComputeInitialType() const {
  // TODO(vegorov): Incorporate type arguments into the returned type.
  return CompileType::FromCid(cid_);
}


CompileType* LoadFieldInstr::ComputeInitialType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  // Keep it as null for debug purposes and do not return dynamic in production
  // mode, since misuse of the type would remain undetected.
  if (type().IsNull()) {
    return CompileType::Dynamic();
  }

  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(type());
  }

  return CompileType::FromCid(result_cid_);
}


CompileType* StoreVMFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType* BinarySmiOpInstr::ComputeInitialType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType* UnarySmiOpInstr::ComputeInitialType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType* DoubleToSmiInstr::ComputeInitialType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType* ConstraintInstr::ComputeInitialType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType* BinaryMintOpInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* ShiftMintOpInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* UnaryMintOpInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* BoxIntegerInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* UnboxIntegerInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* DoubleToIntegerInstr::ComputeInitialType() const {
  return CompileType::Int();
}


CompileType* BinaryDoubleOpInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* MathSqrtInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* UnboxDoubleInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* BoxDoubleInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* SmiToDoubleInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* DoubleToDoubleInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType* InvokeMathCFunctionInstr::ComputeInitialType() const {
  return CompileType::FromCid(kDoubleCid);
}


}  // namespace dart
