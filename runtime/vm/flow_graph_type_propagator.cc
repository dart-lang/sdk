// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_type_propagator.h"

#include "vm/cha.h"
#include "vm/bit_vector.h"
#include "vm/il_printer.h"
#include "vm/regexp_assembler.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool, trace_type_propagation, false,
            "Trace flow graph type propagation");

DECLARE_FLAG(bool, propagate_types);


void FlowGraphTypePropagator::Propagate(FlowGraph* flow_graph) {
#ifndef PRODUCT
  Thread* thread = flow_graph->thread();
  TimelineStream* compiler_timeline = Timeline::GetCompilerStream();
  TimelineDurationScope tds2(thread,
                             compiler_timeline,
                             "FlowGraphTypePropagator");
#endif  // !PRODUCT
  FlowGraphTypePropagator propagator(flow_graph);
  propagator.Propagate();
}


FlowGraphTypePropagator::FlowGraphTypePropagator(FlowGraph* flow_graph)
    : FlowGraphVisitor(flow_graph->reverse_postorder()),
      flow_graph_(flow_graph),
      visited_blocks_(new(flow_graph->zone()) BitVector(
          flow_graph->zone(), flow_graph->reverse_postorder().length())),
      types_(flow_graph->current_ssa_temp_index()),
      in_worklist_(new(flow_graph->zone()) BitVector(
          flow_graph->zone(), flow_graph->current_ssa_temp_index())),
      asserts_(NULL),
      collected_asserts_(NULL) {
  for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
    types_.Add(NULL);
  }

  if (Isolate::Current()->type_checks()) {
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
    if (FLAG_support_il_printer && FLAG_trace_type_propagation) {
      THR_Print("recomputing type of v%" Pd ": %s\n",
                def->ssa_temp_index(),
                def->Type()->ToCString());
    }
    if (def->RecomputeType()) {
      if (FLAG_support_il_printer && FLAG_trace_type_propagation) {
        THR_Print("  ... new type %s\n", def->Type()->ToCString());
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
          if (constrained_type != NULL) {
            constrained_type->Update();
          }
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

  if (Isolate::Current()->type_checks()) {
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

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    PropagateRecursive(block->dominated_blocks()[i]);
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
  if (current->is_nullable() && (current->ToCid() != kNullCid)) {
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

  if (FLAG_support_il_printer && FLAG_trace_type_propagation) {
    THR_Print("reaching type to %s for v%" Pd " is %s\n",
              value->instruction()->ToCString(),
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


void FlowGraphTypePropagator::VisitCheckArrayBound(
    CheckArrayBoundInstr* check) {
  // Array bounds checks also test index for smi.
  SetCid(check->index()->definition(), kSmiCid);
}


void FlowGraphTypePropagator::VisitCheckClass(CheckClassInstr* check) {
  if ((check->unary_checks().NumberOfChecks() != 1) ||
      !check->Dependencies().IsNone()) {
    // TODO(vegorov): If check is affected by side-effect we can still propagate
    // the type further but not the cid.
    return;
  }

  SetCid(check->value()->definition(),
         check->unary_checks().GetReceiverClassIdAt(0));
}


void FlowGraphTypePropagator::VisitCheckClassId(CheckClassIdInstr* check) {
  // Can't propagate the type/cid because it may cause illegal code motion and
  // we don't track dependencies in all places via redefinitions.
}


void FlowGraphTypePropagator::VisitInstanceCall(InstanceCallInstr* instr) {
  if (instr->has_unique_selector()) {
    SetCid(instr->ArgumentAt(0),
           instr->ic_data()->GetReceiverClassIdAt(0));
  }
}


void FlowGraphTypePropagator::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* instr) {
  if (instr->instance_call()->has_unique_selector()) {
    SetCid(instr->ArgumentAt(0),
           instr->ic_data().GetReceiverClassIdAt(0));
  }
}


void FlowGraphTypePropagator::VisitGuardFieldClass(
    GuardFieldClassInstr* guard) {
  const intptr_t cid = guard->field().guarded_cid();
  if ((cid == kIllegalCid) ||
      (cid == kDynamicCid) ||
      Field::IsExternalizableCid(cid)) {
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


void FlowGraphTypePropagator::VisitAssertAssignable(
    AssertAssignableInstr* instr) {
  SetTypeOf(instr->value()->definition(),
            ZoneCompileType::Wrap(instr->ComputeType()));
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
      Definition* defn = assert->value()->definition()->OriginalDefinition();
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

  Definition* defn = check->InputAt(0)->definition()->OriginalDefinition();

  AssertAssignableInstr* assert = (*asserts_)[defn->ssa_temp_index()];
  if ((assert == NULL) || (assert == kStrengthenedAssertMarker)) {
    return;
  }
  ASSERT(assert->env() != NULL);

  Instruction* check_clone = NULL;
  if (check->IsCheckSmi()) {
    check_clone =
        new CheckSmiInstr(assert->value()->Copy(zone()),
                          assert->env()->deopt_id(),
                          check->token_pos());
    check_clone->AsCheckSmi()->set_licm_hoisted(
        check->AsCheckSmi()->licm_hoisted());
  } else {
    ASSERT(check->IsCheckClass());
    check_clone =
        new CheckClassInstr(assert->value()->Copy(zone()),
                            assert->env()->deopt_id(),
                            check->AsCheckClass()->unary_checks(),
                            check->token_pos());
    check_clone->AsCheckClass()->set_licm_hoisted(
        check->AsCheckClass()->licm_hoisted());
  }
  ASSERT(check_clone != NULL);
  ASSERT(assert->deopt_id() == assert->env()->deopt_id());
  check_clone->InsertBefore(assert);
  assert->env()->DeepCopyTo(zone(), check_clone);

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

  const AbstractType* compile_type = ToAbstractType();
  const AbstractType* other_compile_type = other->ToAbstractType();
  if (compile_type->IsMoreSpecificThan(
          *other_compile_type, NULL, NULL, Heap::kOld)) {
    type_ = other_compile_type;
  } else if (other_compile_type->
      IsMoreSpecificThan(*compile_type, NULL, NULL, Heap::kOld)) {
  // Nothing to do.
  } else {
  // Can't unify.
  type_ = &Object::dynamic_type();
  }
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
  return Create(kDynamicCid, Object::dynamic_type());
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


CompileType CompileType::Smi() {
  return Create(kSmiCid, Type::ZoneHandle(Type::SmiType()));
}


CompileType CompileType::String() {
  return FromAbstractType(Type::ZoneHandle(Type::StringType()), kNonNullable);
}


intptr_t CompileType::ToCid() {
  if ((cid_ == kNullCid) || (cid_ == kDynamicCid)) {
    return cid_;
  }

  return is_nullable_ ? static_cast<intptr_t>(kDynamicCid) : ToNullableCid();
}


intptr_t CompileType::ToNullableCid() {
  if (cid_ == kIllegalCid) {
    if (type_ == NULL) {
      // Type propagation is turned off or has not yet run.
      return kDynamicCid;
    } else if (type_->IsMalformed()) {
      cid_ = kDynamicCid;
    } else if (type_->IsVoidType()) {
      cid_ = kNullCid;
    } else if (type_->IsFunctionType() || type_->IsDartFunctionType()) {
      cid_ = kClosureCid;
    } else if (type_->HasResolvedTypeClass()) {
      const Class& type_class = Class::Handle(type_->type_class());
      Thread* thread = Thread::Current();
      CHA* cha = thread->cha();
      // Don't infer a cid from an abstract type since there can be multiple
      // compatible classes with different cids.
      if (!CHA::IsImplemented(type_class) && !CHA::HasSubclasses(type_class)) {
        if (type_class.IsPrivate()) {
          // Type of a private class cannot change through later loaded libs.
          cid_ = type_class.id();
        } else if (FLAG_use_cha_deopt ||
                   thread->isolate()->all_classes_finalized()) {
          if (FLAG_trace_cha) {
            THR_Print("  **(CHA) Compile type not subclassed: %s\n",
                type_class.ToCString());
          }
          if (FLAG_use_cha_deopt) {
            cha->AddToGuardedClasses(type_class, /*subclass_count=*/0);
          }
          cid_ = type_class.id();
        } else {
          cid_ = kDynamicCid;
        }
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
    // Type propagation has not run. Return dynamic-type.
    if (cid_ == kIllegalCid) {
      type_ = &Object::dynamic_type();
      return type_;
    }

    // VM-internal objects don't have a compile-type. Return dynamic-type
    // in this case.
    if (cid_ < kInstanceCid) {
      type_ = &Object::dynamic_type();
      return type_;
    }

    const Class& type_class =
        Class::Handle(Isolate::Current()->class_table()->At(cid_));

    if (type_class.NumTypeArguments() > 0) {
      type_ = &Object::dynamic_type();
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
  // We cannot give an answer if the given type is malformed or malbounded.
  if (type.IsMalformedOrMalbounded()) {
    return false;
  }

  if (type.IsDynamicType() || type.IsObjectType()) {
    *is_instance = true;
    return true;
  }

  if (IsNone()) {
    return false;
  }

  // Consider the compile type of the value.
  const AbstractType& compile_type = *ToAbstractType();

  // The compile-type of a value should never be void. The result of a void
  // function must always be null, which wass checked to be null at the return
  // statement inside the function.
  ASSERT(!compile_type.IsVoidType());

  if (compile_type.IsMalformedOrMalbounded()) {
    return false;
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

  *is_instance = compile_type.IsMoreSpecificThan(type, NULL, NULL, Heap::kOld);
  return *is_instance;
}


bool CompileType::IsMoreSpecificThan(const AbstractType& other) {
  if (IsNone()) {
    return false;
  }

  if (other.IsVoidType()) {
    // The only value assignable to void is null.
    return IsNull();
  }

  return ToAbstractType()->IsMoreSpecificThan(other, NULL, NULL, Heap::kOld);
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
    if (FLAG_support_il_printer && FLAG_trace_type_propagation) {
      THR_Print("  phi %" Pd " input %" Pd ": v%" Pd " has reaching type %s\n",
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


CompileType RedefinitionInstr::ComputeType() const {
  return *value()->Type();
}


bool RedefinitionInstr::RecomputeType() {
  return UpdateType(ComputeType());
}


CompileType IfThenElseInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType ParameterInstr::ComputeType() const {
  // Note that returning the declared type of the formal parameter would be
  // incorrect, because ParameterInstr is used as input to the type check
  // verifying the run time type of the passed-in parameter and this check would
  // always be wrongly eliminated.
  // However there are parameters that are known to match their declared type:
  // for example receiver.
  GraphEntryInstr* graph_entry = block_->AsGraphEntry();
  if (graph_entry == NULL) {
    graph_entry = block_->AsCatchBlockEntry()->graph_entry();
  }
  // Parameters at OSR entries have type dynamic.
  //
  // TODO(kmillikin): Use the actual type of the parameter at OSR entry.
  // The code below is not safe for OSR because it doesn't necessarily use
  // the correct scope.
  if (graph_entry->IsCompiledForOsr()) {
    return CompileType::Dynamic();
  }

  const Function& function = graph_entry->parsed_function().function();
  if (function.IsIrregexpFunction()) {
    // In irregexp functions, types of input parameters are known and immutable.
    // Set parameter types here in order to prevent unnecessary CheckClassInstr
    // from being generated.
    switch (index()) {
      case RegExpMacroAssembler::kParamRegExpIndex:
        return CompileType::FromCid(kRegExpCid);
      case RegExpMacroAssembler::kParamStringIndex:
        return CompileType::FromCid(function.string_specialization_cid());
      case RegExpMacroAssembler::kParamStartOffsetIndex:
        return CompileType::FromCid(kSmiCid);
      default: UNREACHABLE();
    }
    UNREACHABLE();
    return CompileType::Dynamic();
  }

  // Parameter is the receiver.
  if ((index() == 0) &&
      (function.IsDynamicFunction() || function.IsGenerativeConstructor())) {
    LocalScope* scope = graph_entry->parsed_function().node_sequence()->scope();
    const AbstractType& type = scope->VariableAt(index())->type();
    if (type.IsObjectType() || type.IsNullType()) {
      // Receiver can be null.
      return CompileType::FromAbstractType(type, CompileType::kNullable);
    }

    // Receiver can't be null but can be an instance of a subclass.
    intptr_t cid = kDynamicCid;

    if (type.HasResolvedTypeClass()) {
      Thread* thread = Thread::Current();
      const Class& type_class = Class::Handle(type.type_class());
      if (!CHA::HasSubclasses(type_class)) {
        if (type_class.IsPrivate()) {
          // Private classes can never be subclassed by later loaded libs.
          cid = type_class.id();
        } else {
          if (FLAG_use_cha_deopt ||
              thread->isolate()->all_classes_finalized()) {
            if (FLAG_trace_cha) {
              THR_Print("  **(CHA) Computing exact type of receiver, "
                  "no subclasses: %s\n",
                  type_class.ToCString());
            }
            if (FLAG_use_cha_deopt) {
              thread->cha()->AddToGuardedClasses(
                  type_class, /*subclass_count=*/0);
            }
            cid = type_class.id();
          }
        }
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

  intptr_t cid = value().GetClassId();
  if (Field::IsExternalizableCid(cid)) {
    cid = kDynamicCid;
  }

  if (value().IsInstance()) {
    return CompileType::Create(cid,
        AbstractType::ZoneHandle(Instance::Cast(value()).GetType()));
  } else {
    // Type info for non-instance objects.
    return CompileType::FromCid(cid);
  }
}


CompileType AssertAssignableInstr::ComputeType() const {
  CompileType* value_type = value()->Type();

  if (value_type->IsMoreSpecificThan(dst_type())) {
    return *value_type;
  }

  if (dst_type().IsVoidType()) {
    // The only value assignable to void is null.
    return CompileType::Null();
  }

  return CompileType::Create(value_type->ToCid(), dst_type());
}


bool AssertAssignableInstr::RecomputeType() {
  return UpdateType(ComputeType());
}


CompileType AssertBooleanInstr::ComputeType() const {
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


CompileType TestSmiInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType TestCidsInstr::ComputeType() const {
  return CompileType::Bool();
}


CompileType EqualityCompareInstr::ComputeType() const {
  // Used for numeric comparisons only.
  return CompileType::Bool();
}


CompileType RelationalOpInstr::ComputeType() const {
  // Used for numeric comparisons only.
  return CompileType::Bool();
}


CompileType CurrentContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable,
                     kContextCid,
                     &Object::dynamic_type());
}


CompileType CloneContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable,
                     kContextCid,
                     &Object::dynamic_type());
}


CompileType AllocateContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable,
                     kContextCid,
                     &Object::dynamic_type());
}


CompileType AllocateUninitializedContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable,
                     kContextCid,
                     &Object::dynamic_type());
}


CompileType PolymorphicInstanceCallInstr::ComputeType() const {
  if (!HasSingleRecognizedTarget()) return CompileType::Dynamic();
  const Function& target = Function::Handle(ic_data().GetTargetAt(0));
  return (target.recognized_kind() != MethodRecognizer::kUnknown)
      ? CompileType::FromCid(MethodRecognizer::ResultCid(target))
      : CompileType::Dynamic();
}


CompileType StaticCallInstr::ComputeType() const {
  if (result_cid_ != kDynamicCid) {
    return CompileType::FromCid(result_cid_);
  }

  if (Isolate::Current()->type_checks()) {
    // Void functions are known to return null, which is checked at the return
    // from the function.
    const AbstractType& result_type =
        AbstractType::ZoneHandle(function().result_type());
    return CompileType::FromAbstractType(result_type.IsVoidType()
        ? AbstractType::ZoneHandle(Type::NullType())
        : result_type);
  }

  return CompileType::Dynamic();
}


CompileType LoadLocalInstr::ComputeType() const {
  if (Isolate::Current()->type_checks()) {
    return CompileType::FromAbstractType(local().type());
  }
  return CompileType::Dynamic();
}


CompileType DropTempsInstr::ComputeType() const {
  return *value()->Type();
}


CompileType StoreLocalInstr::ComputeType() const {
  // Returns stored value.
  return *value()->Type();
}


CompileType OneByteStringFromCharCodeInstr::ComputeType() const {
  return CompileType::FromCid(kOneByteStringCid);
}


CompileType StringToCharCodeInstr::ComputeType() const {
    return CompileType::FromCid(kSmiCid);
}


CompileType StringInterpolateInstr::ComputeType() const {
  // TODO(srdjan): Do better and determine if it is a one or two byte string.
  return CompileType::String();
}


CompileType LoadStaticFieldInstr::ComputeType() const {
  bool is_nullable = CompileType::kNullable;
  intptr_t cid = kDynamicCid;
  AbstractType* abstract_type = NULL;
  const Field& field = this->StaticField();
  if (Isolate::Current()->type_checks()) {
    cid = kIllegalCid;
    abstract_type = &AbstractType::ZoneHandle(field.type());
  }
  ASSERT(field.is_static());
  if (field.is_final()) {
    if (!FLAG_fields_may_be_reset) {
      const Instance& obj = Instance::Handle(field.StaticValue());
      if ((obj.raw() != Object::sentinel().raw()) &&
          (obj.raw() != Object::transition_sentinel().raw()) &&
          !obj.IsNull()) {
        is_nullable = CompileType::kNonNullable;
        cid = obj.GetClassId();
      }
    } else if (field.guarded_cid() != kIllegalCid) {
      cid = field.guarded_cid();
      if (!IsNullableCid(cid)) is_nullable = CompileType::kNonNullable;
    }
  }
  if (Field::IsExternalizableCid(cid)) {
    cid = kDynamicCid;
  }
  return CompileType(is_nullable, cid, abstract_type);
}


CompileType CreateArrayInstr::ComputeType() const {
  // TODO(fschneider): Add abstract type and type arguments to the compile type.
  return CompileType::FromCid(kArrayCid);
}


CompileType AllocateObjectInstr::ComputeType() const {
  if (!closure_function().IsNull()) {
    ASSERT(cls().id() == kClosureCid);
    return CompileType(CompileType::kNonNullable,
                       kClosureCid,
                       &Type::ZoneHandle(closure_function().SignatureType()));
  }
  // TODO(vegorov): Incorporate type arguments into the returned type.
  return CompileType::FromCid(cls().id());
}


CompileType LoadUntaggedInstr::ComputeType() const {
  return CompileType::Dynamic();
}


CompileType LoadClassIdInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType LoadFieldInstr::ComputeType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  // Keep it as null for debug purposes and do not return dynamic in production
  // mode, since misuse of the type would remain undetected.
  if (type().IsNull()) {
    return CompileType::Dynamic();
  }

  const AbstractType* abstract_type = NULL;
  if (Isolate::Current()->type_checks() &&
      (type().IsFunctionType() ||
       (type().HasResolvedTypeClass() &&
       !Field::IsExternalizableCid(Class::Handle(type().type_class()).id())))) {
    abstract_type = &type();
  }

  if ((field_ != NULL) && (field_->guarded_cid() != kIllegalCid)) {
    bool is_nullable = field_->is_nullable();
    intptr_t field_cid =  field_->guarded_cid();
    if (Field::IsExternalizableCid(field_cid)) {
      // We cannot assume that the type of the value in the field has not
      // changed on the fly.
      field_cid = kDynamicCid;
    }
    return CompileType(is_nullable, field_cid, abstract_type);
  }

  ASSERT(!Field::IsExternalizableCid(result_cid_));
  return CompileType::Create(result_cid_, *abstract_type);
}


CompileType LoadCodeUnitsInstr::ComputeType() const {
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      return can_pack_into_smi() ? CompileType::FromCid(kSmiCid)
                                 : CompileType::Int();
    default:
      UNIMPLEMENTED();
      return CompileType::Dynamic();
  }
}


CompileType BinaryInt32OpInstr::ComputeType() const {
  // TODO(vegorov): range analysis information shall be used here.
  return CompileType::Int();
}


CompileType BinarySmiOpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType UnarySmiOpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType UnaryDoubleOpInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType DoubleToSmiInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType ConstraintInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}

// Note that MintOp may produce Smi-s as result of an
// appended BoxInt64Instr node.
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
  return ValueFitsSmi() ? CompileType::FromCid(kSmiCid) : CompileType::Int();
}


bool BoxIntegerInstr::RecomputeType() {
  return UpdateType(ComputeType());
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


CompileType DoubleTestOpInstr::ComputeType() const {
  return CompileType::FromCid(kBoolCid);
}


CompileType BinaryFloat32x4OpInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Simd32x4ShuffleInstr::ComputeType() const {
  if ((op_kind() == MethodRecognizer::kFloat32x4ShuffleX) ||
      (op_kind() == MethodRecognizer::kFloat32x4ShuffleY) ||
      (op_kind() == MethodRecognizer::kFloat32x4ShuffleZ) ||
      (op_kind() == MethodRecognizer::kFloat32x4ShuffleW)) {
    return CompileType::FromCid(kDoubleCid);
  }
  if ((op_kind() == MethodRecognizer::kInt32x4Shuffle)) {
    return CompileType::FromCid(kInt32x4Cid);
  }
  ASSERT((op_kind() == MethodRecognizer::kFloat32x4Shuffle));
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Simd32x4ShuffleMixInstr::ComputeType() const {
  if (op_kind() == MethodRecognizer::kInt32x4ShuffleMix) {
    return CompileType::FromCid(kInt32x4Cid);
  }
  ASSERT((op_kind() == MethodRecognizer::kFloat32x4ShuffleMix));
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Simd32x4GetSignMaskInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType Float32x4ConstructorInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ZeroInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4SplatInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ComparisonInstr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType Float32x4MinMaxInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ScaleInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4SqrtInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ZeroArgInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ClampInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4WithInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float32x4ToInt32x4Instr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType Simd64x2ShuffleInstr::ComputeType() const {
  if ((op_kind() == MethodRecognizer::kFloat64x2GetX) ||
      (op_kind() == MethodRecognizer::kFloat64x2GetY)) {
    return CompileType::FromCid(kDoubleCid);
  }
  UNREACHABLE();
  return CompileType::FromCid(kDoubleCid);
}


CompileType Float64x2ZeroInstr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Float64x2SplatInstr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Float64x2ConstructorInstr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Float32x4ToFloat64x2Instr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Float64x2ToFloat32x4Instr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Float64x2ZeroArgInstr::ComputeType() const {
  if (op_kind() == MethodRecognizer::kFloat64x2GetSignMask) {
    return CompileType::Int();
  }
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Float64x2OneArgInstr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType Int32x4ConstructorInstr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType Int32x4BoolConstructorInstr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType Int32x4GetFlagInstr::ComputeType() const {
  return CompileType::FromCid(kBoolCid);
}


CompileType Int32x4SelectInstr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType Int32x4SetFlagInstr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType Int32x4ToFloat32x4Instr::ComputeType() const {
  return CompileType::FromCid(kFloat32x4Cid);
}


CompileType BinaryInt32x4OpInstr::ComputeType() const {
  return CompileType::FromCid(kInt32x4Cid);
}


CompileType BinaryFloat64x2OpInstr::ComputeType() const {
  return CompileType::FromCid(kFloat64x2Cid);
}


CompileType MathUnaryInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType MathMinMaxInstr::ComputeType() const {
  return CompileType::FromCid(result_cid_);
}


CompileType CaseInsensitiveCompareUC16Instr::ComputeType() const {
  return CompileType::FromCid(kBoolCid);
}


CompileType UnboxInstr::ComputeType() const {
  switch (representation()) {
    case kUnboxedDouble:
      return CompileType::FromCid(kDoubleCid);

    case kUnboxedFloat32x4:
      return CompileType::FromCid(kFloat32x4Cid);

    case kUnboxedFloat64x2:
      return CompileType::FromCid(kFloat64x2Cid);

    case kUnboxedInt32x4:
      return CompileType::FromCid(kInt32x4Cid);

    case kUnboxedMint:
      return CompileType::Int();

    default:
      UNREACHABLE();
      return CompileType::Dynamic();
  }
}


CompileType BoxInstr::ComputeType() const {
  switch (from_representation()) {
    case kUnboxedDouble:
      return CompileType::FromCid(kDoubleCid);

    case kUnboxedFloat32x4:
      return CompileType::FromCid(kFloat32x4Cid);

    case kUnboxedFloat64x2:
      return CompileType::FromCid(kFloat64x2Cid);

    case kUnboxedInt32x4:
      return CompileType::FromCid(kInt32x4Cid);

    default:
      UNREACHABLE();
      return CompileType::Dynamic();
  }
}


CompileType Int32ToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType SmiToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType MintToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType DoubleToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType FloatToDoubleInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType DoubleToFloatInstr::ComputeType() const {
  // Type is double when converted back.
  return CompileType::FromCid(kDoubleCid);
}


CompileType InvokeMathCFunctionInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}


CompileType MergedMathInstr::ComputeType() const {
  return CompileType::Dynamic();
}


CompileType ExtractNthOutputInstr::ComputeType() const {
  return CompileType::FromCid(definition_cid_);
}

}  // namespace dart
