// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_type_propagator.h"

#include "vm/cha.h"
#include "vm/bit_vector.h"
#include "vm/il_printer.h"

namespace dart {

DEFINE_FLAG(bool, trace_type_propagation, false,
            "Trace flow graph type propagation");

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, use_cha);


FlowGraphTypePropagator::FlowGraphTypePropagator(FlowGraph* flow_graph)
    : FlowGraphVisitor(flow_graph->reverse_postorder()),
      flow_graph_(flow_graph),
      visited_blocks_(new BitVector(flow_graph->reverse_postorder().length())),
      types_(flow_graph->current_ssa_temp_index()),
      in_worklist_(new BitVector(flow_graph->current_ssa_temp_index())),
      asserts_(NULL),
      collected_asserts_(NULL) {
  for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
    types_.Add(NULL);
  }

  if (FLAG_enable_type_checks) {
    asserts_ = new ZoneGrowableArray<AssertAssignableInstr*>(
        flow_graph->current_ssa_temp_index());
    for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
      asserts_->Add(NULL);
    }

    collected_asserts_ = new ZoneGrowableArray<intptr_t>(10);
  }
}


void FlowGraphTypePropagator::Propagate() {
  if (FLAG_trace_type_propagation) {
    FlowGraphPrinter::PrintGraph("Before type propagation", flow_graph_);
  }

  // Walk the dominator tree and propagate reaching types to all Values.
  // Collect all phis for a fixed point iteration.
  PropagateRecursive(flow_graph_->graph_entry());

  // Initially the worklist contains only phis.
  // Reset compile type of all phis to None to ensure that
  // types are correctly propagated through the cycles of
  // phis.
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    ASSERT(worklist_[i]->IsPhi());
    *worklist_[i]->Type() = CompileType::None();
  }

  // Iterate until a fixed point is reached, updating the types of
  // definitions.
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
        Instruction* instr = it.Current()->instruction();

        Definition* use_defn = instr->AsDefinition();
        if (use_defn != NULL) {
          AddToWorklist(use_defn);
        }

        // If the value flow into a branch recompute type constrained by the
        // branch (if any). This ensures that correct non-nullable type will
        // flow downwards from the branch on the comparison with the null
        // constant.
        BranchInstr* branch = instr->AsBranch();
        if (branch != NULL) {
          ConstrainedCompileType* constrained_type = branch->constrained_type();
          if (constrained_type != NULL) constrained_type->Update();
        }
      }
    }
  }

  if (FLAG_trace_type_propagation) {
    FlowGraphPrinter::PrintGraph("After type propagation", flow_graph_);
  }
}


void FlowGraphTypePropagator::PropagateRecursive(BlockEntryInstr* block) {
  if (visited_blocks_->Contains(block->postorder_number())) {
    return;
  }
  visited_blocks_->Add(block->postorder_number());

  const intptr_t rollback_point = rollback_.length();

  if (FLAG_enable_type_checks) {
    StrengthenAsserts(block);
  }

  block->Accept(this);

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();

    for (intptr_t i = 0; i < instr->InputCount(); i++) {
      VisitValue(instr->InputAt(i));
    }
    if (instr->IsDefinition()) {
      instr->AsDefinition()->RecomputeType();
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

  HandleBranchOnNull(block);

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    PropagateRecursive(block->dominated_blocks()[i]);
  }

  RollbackTo(rollback_point);
}


void FlowGraphTypePropagator::HandleBranchOnNull(BlockEntryInstr* block) {
  BranchInstr* branch = block->last_instruction()->AsBranch();
  if (branch == NULL) {
    return;
  }

  StrictCompareInstr* compare = branch->comparison()->AsStrictCompare();
  if ((compare == NULL) || !compare->right()->BindsToConstantNull()) {
    return;
  }

  const intptr_t rollback_point = rollback_.length();

  Definition* defn = compare->left()->definition();

  if (compare->kind() == Token::kEQ_STRICT) {
    branch->set_constrained_type(MarkNonNullable(defn));
    PropagateRecursive(branch->false_successor());

    SetCid(defn, kNullCid);
    PropagateRecursive(branch->true_successor());
  } else if (compare->kind() == Token::kNE_STRICT) {
    branch->set_constrained_type(MarkNonNullable(defn));
    PropagateRecursive(branch->true_successor());

    SetCid(defn, kNullCid);
    PropagateRecursive(branch->false_successor());
  }

  RollbackTo(rollback_point);
}


void FlowGraphTypePropagator::RollbackTo(intptr_t rollback_point) {
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
  if (current->IsNone() || (current->ToCid() != cid)) {
    SetTypeOf(def, ZoneCompileType::Wrap(CompileType::FromCid(cid)));
  }
}


ConstrainedCompileType* FlowGraphTypePropagator::MarkNonNullable(
    Definition* def) {
  CompileType* current = TypeOf(def);
  if (current->is_nullable()) {
    ConstrainedCompileType* constrained_type =
        new NotNullConstrainedCompileType(current);
    SetTypeOf(def, constrained_type->ToCompileType());
    return constrained_type;
  }
  return NULL;
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
    worklist_.Add(it.Current());
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


void FlowGraphTypePropagator::VisitGuardField(GuardFieldInstr* guard) {
  const intptr_t cid = guard->field().guarded_cid();
  if ((cid == kIllegalCid) || (cid == kDynamicCid)) {
    return;
  }

  Definition* def = guard->value()->definition();
  CompileType* current = TypeOf(def);
  if (current->IsNone() ||
      (current->ToCid() != cid) ||
      (current->is_nullable() && !guard->field().is_nullable())) {
    const bool is_nullable =
        guard->field().is_nullable() && current->is_nullable();
    SetTypeOf(def, ZoneCompileType::Wrap(CompileType(is_nullable, cid, NULL)));
  }
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


// Unwrap all assert assignable and get a real definition of the value.
static Definition* UnwrapAsserts(Definition* defn) {
  while (defn->IsAssertAssignable()) {
    defn = defn->AsAssertAssignable()->value()->definition();
  }
  return defn;
}


// In the given block strengthen type assertions by hoisting first class or smi
// check over the same value up to the point before the assertion. This allows
// to eliminate type assertions that are postdominated by class or smi checks as
// these checks are strongly stricter than type assertions.
void FlowGraphTypePropagator::StrengthenAsserts(BlockEntryInstr* block) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();

    if (instr->IsCheckSmi() || instr->IsCheckClass()) {
      StrengthenAssertWith(instr);
    }

    // If this is the first type assertion checking given value record it.
    AssertAssignableInstr* assert = instr->AsAssertAssignable();
    if (assert != NULL) {
      Definition* defn = UnwrapAsserts(assert->value()->definition());
      if ((*asserts_)[defn->ssa_temp_index()] == NULL) {
        (*asserts_)[defn->ssa_temp_index()] = assert;
        collected_asserts_->Add(defn->ssa_temp_index());
      }
    }
  }

  for (intptr_t i = 0; i < collected_asserts_->length(); i++) {
    (*asserts_)[(*collected_asserts_)[i]] = NULL;
  }

  collected_asserts_->TruncateTo(0);
}


void FlowGraphTypePropagator::StrengthenAssertWith(Instruction* check) {
  // Marker that is used to mark values that already had type assertion
  // strengthened.
  AssertAssignableInstr* kStrengthenedAssertMarker =
      reinterpret_cast<AssertAssignableInstr*>(-1);

  Definition* defn = UnwrapAsserts(check->InputAt(0)->definition());

  AssertAssignableInstr* assert = (*asserts_)[defn->ssa_temp_index()];
  if ((assert == NULL) || (assert == kStrengthenedAssertMarker)) {
    return;
  }

  Instruction* check_clone = NULL;
  if (check->IsCheckSmi()) {
    check_clone =
        new CheckSmiInstr(assert->value()->Copy(),
                          assert->env()->deopt_id());
  } else {
    ASSERT(check->IsCheckClass());
    check_clone =
        new CheckClassInstr(assert->value()->Copy(),
                            assert->env()->deopt_id(),
                            check->AsCheckClass()->unary_checks());
  }
  ASSERT(check_clone != NULL);
  ASSERT(assert->deopt_id() == assert->env()->deopt_id());
  check_clone->InsertBefore(assert);
  assert->env()->DeepCopyTo(check_clone);

  (*asserts_)[defn->ssa_temp_index()] = kStrengthenedAssertMarker;
}


void CompileType::Union(CompileType* other) {
  if (other->IsNone()) {
    return;
  }

  if (IsNone()) {
    *this = *other;
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

  Error& malformed_error = Error::Handle();
  if (ToAbstractType()->IsMoreSpecificThan(*other->ToAbstractType(),
                                           &malformed_error)) {
    type_ = other->ToAbstractType();
  } else if (ToAbstractType()->IsMoreSpecificThan(*ToAbstractType(),
                                                  &malformed_error)) {
    // Nothing to do.
  } else {
    // Can't unify.
    type_ = &Type::ZoneHandle(Type::DynamicType());
  }
  ASSERT(malformed_error.IsNull());
}


static bool IsNullableCid(intptr_t cid) {
  ASSERT(cid != kIllegalCid);
  return cid == kNullCid || cid == kDynamicCid;
}


CompileType CompileType::Create(intptr_t cid, const AbstractType& type) {
  return CompileType(IsNullableCid(cid), cid, &type);
}


CompileType CompileType::FromAbstractType(const AbstractType& type,
                                          bool is_nullable) {
  return CompileType(is_nullable, kIllegalCid, &type);
}


CompileType CompileType::FromCid(intptr_t cid) {
  return CompileType(IsNullableCid(cid), cid, NULL);
}


CompileType CompileType::Dynamic() {
  return Create(kDynamicCid, Type::ZoneHandle(Type::DynamicType()));
}


CompileType CompileType::Null() {
  return Create(kNullCid, Type::ZoneHandle(Type::NullType()));
}


CompileType CompileType::Bool() {
  return Create(kBoolCid, Type::ZoneHandle(Type::BoolType()));
}


CompileType CompileType::Int() {
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
      const Class& type_class = Class::Handle(type_->type_class());
      if (!type_class.is_implemented() &&
          !CHA::HasSubclasses(type_class.id())) {
        cid_ = type_class.id();
      } else {
        cid_ = kDynamicCid;
      }
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
  if (IsNone()) {
    return false;
  }

  if (other.IsVoidType()) {
    // The only value assignable to void is null.
    return IsNull();
  }

  Error& malformed_error = Error::Handle();
  const bool is_more_specific =
      ToAbstractType()->IsMoreSpecificThan(other, &malformed_error);
  return malformed_error.IsNull() && is_more_specific;
}


CompileType* Value::Type() {
  if (reaching_type_ == NULL) {
    reaching_type_ = definition()->Type();
  }
  return reaching_type_;
}


CompileType PhiInstr::ComputeType() const {
  // Initially type of phis is unknown until type propagation is run
  // for the first time.
  return CompileType::None();
}


bool PhiInstr::RecomputeType() {
  CompileType result = CompileType::None();
  for (intptr_t i = 0; i < InputCount(); i++) {
    if (FLAG_trace_type_propagation) {
      OS::Print("  phi %"Pd" input %"Pd": v%"Pd" has reaching type %s\n",
                ssa_temp_index(),
                i,
                InputAt(i)->definition()->ssa_temp_index(),
                InputAt(i)->Type()->ToCString());
    }
    result.Union(InputAt(i)->Type());
  }

  if (result.IsNone()) {
    ASSERT(Type()->IsNone());
    return false;
  }

  return UpdateType(result);
}


CompileType IfThenElseInstr::ComputeType() const {
  ASSERT(InputCount() == 2);
  return CompileType::FromCid(kSmiCid);
}


CompileType ParameterInstr::ComputeType() const {
  // Note that returning the declared type of the formal parameter would be
  // incorrect, because ParameterInstr is used as input to the type check
  // verifying the run time type of the passed-in parameter and this check would
  // always be wrongly eliminated.
  // However there are parameters that are known to match their declared type:
  // for example receiver and construction phase.
  const Function& function = block_->parsed_function().function();
  LocalScope* scope = block_->parsed_function().node_sequence()->scope();
  const AbstractType& type = scope->VariableAt(index())->type();

  // Parameter is the constructor phase.
  if ((index() == 1) && function.IsConstructor()) {
    return CompileType::FromAbstractType(type, CompileType::kNonNullable);
  }

  // Parameter is the receiver.
  if ((index() == 0) &&
      (function.IsDynamicFunction() || function.IsConstructor())) {
    if (type.IsObjectType() || type.IsNullType()) {
      // Receiver can be null.
      return CompileType::FromAbstractType(type, CompileType::kNullable);
    }

    // Receiver can't be null but can be an instance of a subclass.
    intptr_t cid = kDynamicCid;
    if (FLAG_use_cha && type.HasResolvedTypeClass()) {
      const Class& type_class = Class::Handle(type.type_class());
      if (!CHA::HasSubclasses(type_class.id())) {
        cid = type_class.id();
      }
    }

    return CompileType(CompileType::kNonNullable, cid, &type);
  }

  return CompileType::Dynamic();
}


CompileType PushArgumentInstr::ComputeType() const {
  return CompileType::Dynamic();
}


CompileType ConstantInstr::ComputeType() const {
  if (value().IsNull()) {
    return CompileType::Null();
  }

  if (value().IsInstance()) {
    return CompileType::Create(
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

  if (dst_type().IsVoidType()) {
    // The only value assignable to void is null.
    return ZoneCompileType::Wrap(CompileType::Null());
  }

  return ZoneCompileType::Wrap(CompileType::FromAbstractType(dst_type()));
}


bool AssertAssignableInstr::RecomputeType() {
  CompileType* value_type = value()->Type();
  if (value_type == Type()) {
    return false;
  }

  if (value_type->IsMoreSpecificThan(dst_type())) {
    return UpdateType(*value_type);
  }

  return false;
}


CompileType AssertBooleanInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType ArgumentDefinitionTestInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType BooleanNegateInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType InstanceOfInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType StrictCompareInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType EqualityCompareInstr::ComputeType() const {
  return IsInlinedNumericComparison() ? CompileType::Bool()
                                      : CompileType::Dynamic();
}


bool EqualityCompareInstr::RecomputeType() {
  return UpdateType(ComputeType());
}


CompileType RelationalOpInstr::ComputeType() const {
  return IsInlinedNumericComparison() ? CompileType::Bool()
                                      : CompileType::Dynamic();
}


bool RelationalOpInstr::RecomputeType() {
  return UpdateType(ComputeType());
}


CompileType CurrentContextInstr::ComputeType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType CloneContextInstr::ComputeType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType AllocateContextInstr::ComputeType() const {
  return CompileType::FromCid(kContextCid);
}


CompileType StaticCallInstr::ComputeType() const {
  if (result_cid_ != kDynamicCid) {
    return CompileType::FromCid(result_cid_);
  }

  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(
        AbstractType::ZoneHandle(function().result_type()));
  }

  return CompileType::Dynamic();
}


CompileType LoadLocalInstr::ComputeType() const {
  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(local().type());
  }
  return CompileType::Dynamic();
}


CompileType* StoreLocalInstr::ComputeInitialType() const {
  // Returns stored value.
  return value()->Type();
}


CompileType StringFromCharCodeInstr::ComputeType() const {
  return CompileType::FromCid(cid_);
}


CompileType* StoreInstanceFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType LoadStaticFieldInstr::ComputeType() const {
  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(
        AbstractType::ZoneHandle(field().type()));
  }
  return CompileType::Dynamic();
}


CompileType* StoreStaticFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType CreateArrayInstr::ComputeType() const {
  return CompileType::FromAbstractType(type(), CompileType::kNonNullable);
}


CompileType CreateClosureInstr::ComputeType() const {
  const Function& fun = function();
  const Class& signature_class = Class::Handle(fun.signature_class());
  return CompileType::FromAbstractType(
      Type::ZoneHandle(signature_class.SignatureType()),
      CompileType::kNonNullable);
}


CompileType AllocateObjectInstr::ComputeType() const {
  // TODO(vegorov): Incorporate type arguments into the returned type.
  return CompileType::FromCid(cid_);
}


CompileType LoadUntaggedInstr::ComputeType() const {
  return CompileType::Dynamic();
}


CompileType LoadFieldInstr::ComputeType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  // Keep it as null for debug purposes and do not return dynamic in production
  // mode, since misuse of the type would remain undetected.
  if (type().IsNull()) {
    return CompileType::Dynamic();
  }

  if (FLAG_enable_type_checks) {
    return CompileType::FromAbstractType(type());
  }

  if (field_ != NULL) {
    return CompileType::CreateNullable(field_->is_nullable(),
                                       field_->guarded_cid());
  }

  return CompileType::FromCid(result_cid_);
}


CompileType* StoreVMFieldInstr::ComputeInitialType() const {
  return value()->Type();
}


CompileType BinarySmiOpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType UnarySmiOpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType DoubleToSmiInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType ConstraintInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType BinaryMintOpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType ShiftMintOpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType UnaryMintOpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType BoxIntegerInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType UnboxIntegerInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType DoubleToIntegerInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType BinaryDoubleOpInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType BinaryFloat32x4OpInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType MathSqrtInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType UnboxDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType BoxDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType UnboxFloat32x4Instr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType BoxFloat32x4Instr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType SmiToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType DoubleToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType InvokeMathCFunctionInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


}  // namespace dart
