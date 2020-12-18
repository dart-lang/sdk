// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/type_propagator.h"

#include "platform/text_buffer.h"

#include "vm/bit_vector.h"
#include "vm/compiler/compiler_state.h"
#include "vm/object_store.h"
#include "vm/regexp_assembler.h"
#include "vm/resolver.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool,
            trace_type_propagation,
            false,
            "Trace flow graph type propagation");

static void TraceStrongModeType(const Instruction* instr,
                                const AbstractType& type) {
  if (FLAG_trace_strong_mode_types) {
    THR_Print("[Strong mode] Type of %s - %s\n", instr->ToCString(),
              type.ToCString());
  }
}

static void TraceStrongModeType(const Instruction* instr,
                                CompileType* compileType) {
  if (FLAG_trace_strong_mode_types) {
    const AbstractType* type = compileType->ToAbstractType();
    if ((type != NULL) && !type->IsDynamicType()) {
      TraceStrongModeType(instr, *type);
    }
  }
}

void FlowGraphTypePropagator::Propagate(FlowGraph* flow_graph) {
  TIMELINE_DURATION(flow_graph->thread(), CompilerVerbose,
                    "FlowGraphTypePropagator");
  FlowGraphTypePropagator propagator(flow_graph);
  propagator.Propagate();
}

FlowGraphTypePropagator::FlowGraphTypePropagator(FlowGraph* flow_graph)
    : FlowGraphVisitor(flow_graph->reverse_postorder()),
      flow_graph_(flow_graph),
      visited_blocks_(new (flow_graph->zone())
                          BitVector(flow_graph->zone(),
                                    flow_graph->reverse_postorder().length())),
      types_(flow_graph->current_ssa_temp_index()),
      in_worklist_(NULL),
      asserts_(NULL),
      collected_asserts_(NULL) {
  for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
    types_.Add(NULL);
  }

  asserts_ = new ZoneGrowableArray<AssertAssignableInstr*>(
      flow_graph->current_ssa_temp_index());
  for (intptr_t i = 0; i < flow_graph->current_ssa_temp_index(); i++) {
    asserts_->Add(NULL);
  }

  collected_asserts_ = new ZoneGrowableArray<intptr_t>(10);
}

void FlowGraphTypePropagator::Propagate() {
  // Walk the dominator tree and propagate reaching types to all Values.
  // Collect all phis for a fixed point iteration.
  PropagateRecursive(flow_graph_->graph_entry());

  // Initially the worklist contains only phis.
  // Reset compile type of all phis to None to ensure that
  // types are correctly propagated through the cycles of
  // phis.
  in_worklist_ = new (flow_graph_->zone())
      BitVector(flow_graph_->zone(), flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    ASSERT(worklist_[i]->IsPhi());
    *worklist_[i]->Type() = CompileType::None();
  }

  // Iterate until a fixed point is reached, updating the types of
  // definitions.
  while (!worklist_.is_empty()) {
    Definition* def = RemoveLastFromWorklist();
    if (FLAG_support_il_printer && FLAG_trace_type_propagation &&
        flow_graph_->should_print()) {
      THR_Print("recomputing type of v%" Pd ": %s\n", def->ssa_temp_index(),
                def->Type()->ToCString());
    }
    if (def->RecomputeType()) {
      if (FLAG_support_il_printer && FLAG_trace_type_propagation &&
          flow_graph_->should_print()) {
        THR_Print("  ... new type %s\n", def->Type()->ToCString());
      }
      for (Value::Iterator it(def->input_use_list()); !it.Done();
           it.Advance()) {
        Instruction* instr = it.Current()->instruction();

        Definition* use_defn = instr->AsDefinition();
        if (use_defn != NULL) {
          AddToWorklist(use_defn);
        }
      }
    }
  }
}

void FlowGraphTypePropagator::PropagateRecursive(BlockEntryInstr* block) {
  if (visited_blocks_->Contains(block->postorder_number())) {
    return;
  }
  visited_blocks_->Add(block->postorder_number());

  const intptr_t rollback_point = rollback_.length();

  StrengthenAsserts(block);

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
    SetTypeOf(def, new (zone()) CompileType(CompileType::FromCid(cid)));
  }
}

void FlowGraphTypePropagator::GrowTypes(intptr_t up_to) {
  // Grow types array if a new redefinition was inserted.
  for (intptr_t i = types_.length(); i <= up_to; ++i) {
    types_.Add(nullptr);
  }
}

void FlowGraphTypePropagator::EnsureMoreAccurateRedefinition(
    Instruction* prev,
    Definition* original,
    CompileType new_type) {
  RedefinitionInstr* redef =
      flow_graph_->EnsureRedefinition(prev, original, new_type);
  if (redef != nullptr) {
    GrowTypes(redef->ssa_temp_index() + 1);
  }
}

void FlowGraphTypePropagator::VisitValue(Value* value) {
  CompileType* type = TypeOf(value->definition());

  // Force propagation of None type (which means unknown) to inputs of phis
  // in order to avoid contamination of cycles of phis with previously inferred
  // types.
  if (type->IsNone() && value->instruction()->IsPhi()) {
    value->SetReachingType(type);
  } else {
    value->RefineReachingType(type);
  }

  if (FLAG_support_il_printer && FLAG_trace_type_propagation &&
      flow_graph_->should_print()) {
    THR_Print("reaching type to %s for v%" Pd " is %s\n",
              value->instruction()->ToCString(),
              value->definition()->ssa_temp_index(),
              value->Type()->ToCString());
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
  // Use a monomorphic cid directly.
  const Cids& cids = check->cids();
  if (cids.IsMonomorphic()) {
    SetCid(check->value()->definition(), cids.MonomorphicReceiverCid());
    return;
  }
  // Take the union of polymorphic cids.
  CompileType result = CompileType::None();
  for (intptr_t i = 0, n = cids.length(); i < n; i++) {
    CidRange* cid_range = cids.At(i);
    if (cid_range->IsIllegalRange()) {
      return;
    }
    for (intptr_t cid = cid_range->cid_start; cid <= cid_range->cid_end;
         cid++) {
      CompileType tp = CompileType::FromCid(cid);
      result.Union(&tp);
    }
  }
  if (!result.IsNone()) {
    SetTypeOf(check->value()->definition(), new (zone()) CompileType(result));
  }
}

void FlowGraphTypePropagator::VisitCheckClassId(CheckClassIdInstr* check) {
  LoadClassIdInstr* load_cid =
      check->value()->definition()->OriginalDefinition()->AsLoadClassId();
  if (load_cid != NULL && check->cids().IsSingleCid()) {
    SetCid(load_cid->object()->definition(), check->cids().cid_start);
  }
}

void FlowGraphTypePropagator::VisitCheckNull(CheckNullInstr* check) {
  Definition* receiver = check->value()->definition();
  CompileType* type = TypeOf(receiver);
  if (type->is_nullable()) {
    // If the type is nullable, translate an implicit control
    // dependence to an explicit data dependence at this point
    // to guard against invalid code motion later. Valid code
    // motion of the check may still enable valid code motion
    // of the checked code.
    if (check->ssa_temp_index() == -1) {
      flow_graph_->AllocateSSAIndexes(check);
      GrowTypes(check->ssa_temp_index() + 1);
    }
    FlowGraph::RenameDominatedUses(receiver, check, check);
    // Set non-nullable type on check itself (but avoid None()).
    CompileType result = type->CopyNonNullable();
    if (!result.IsNone()) {
      SetTypeOf(check, new (zone()) CompileType(result));
    }
  }
}

void FlowGraphTypePropagator::CheckNonNullSelector(
    Instruction* call,
    Definition* receiver,
    const String& function_name) {
  if (!receiver->Type()->is_nullable()) {
    // Nothing to do if type is already non-nullable.
    return;
  }
  Thread* thread = Thread::Current();
  const Class& null_class =
      Class::Handle(thread->isolate()->object_store()->null_class());
  Function& target = Function::Handle();
  if (Error::Handle(null_class.EnsureIsFinalized(thread)).IsNull()) {
    target = Resolver::ResolveDynamicAnyArgs(thread->zone(), null_class,
                                             function_name);
  }
  if (target.IsNull()) {
    // If the selector is not defined on Null, we can propagate non-nullness.
    CompileType* type = TypeOf(receiver);
    if (type->is_nullable()) {
      // Insert redefinition for the receiver to guard against invalid
      // code motion.
      EnsureMoreAccurateRedefinition(call, receiver, type->CopyNonNullable());
    }
  }
}

void FlowGraphTypePropagator::VisitInstanceCall(InstanceCallInstr* instr) {
  if (instr->has_unique_selector()) {
    SetCid(instr->Receiver()->definition(),
           instr->ic_data()->GetReceiverClassIdAt(0));
    return;
  }
  CheckNonNullSelector(instr, instr->Receiver()->definition(),
                       instr->function_name());
}

void FlowGraphTypePropagator::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* instr) {
  if (instr->has_unique_selector()) {
    SetCid(instr->Receiver()->definition(),
           instr->targets().MonomorphicReceiverCid());
    return;
  }
  CheckNonNullSelector(instr, instr->Receiver()->definition(),
                       instr->function_name());
}

void FlowGraphTypePropagator::VisitGuardFieldClass(
    GuardFieldClassInstr* guard) {
  const intptr_t cid = guard->field().guarded_cid();
  if ((cid == kIllegalCid) || (cid == kDynamicCid)) {
    return;
  }

  Definition* def = guard->value()->definition();
  CompileType* current = TypeOf(def);
  if (current->IsNone() || (current->ToCid() != cid) ||
      (current->is_nullable() && !guard->field().is_nullable())) {
    const bool is_nullable =
        guard->field().is_nullable() && current->is_nullable();
    SetTypeOf(def, new (zone()) CompileType(is_nullable, cid, NULL));
  }
}

void FlowGraphTypePropagator::VisitAssertAssignable(
    AssertAssignableInstr* instr) {
  SetTypeOf(instr->value()->definition(),
            new (zone()) CompileType(instr->ComputeType()));
}

void FlowGraphTypePropagator::VisitAssertBoolean(AssertBooleanInstr* instr) {
  SetTypeOf(instr->value()->definition(),
            new (zone()) CompileType(CompileType::Bool()));
}

void FlowGraphTypePropagator::VisitAssertSubtype(AssertSubtypeInstr* instr) {}

void FlowGraphTypePropagator::VisitBranch(BranchInstr* instr) {
  StrictCompareInstr* comparison = instr->comparison()->AsStrictCompare();
  if (comparison == NULL) return;
  bool negated = comparison->kind() == Token::kNE_STRICT;
  LoadClassIdInstr* load_cid =
      comparison->InputAt(0)->definition()->AsLoadClassId();
  InstanceCallInstr* call =
      comparison->InputAt(0)->definition()->AsInstanceCall();
  InstanceOfInstr* instance_of =
      comparison->InputAt(0)->definition()->AsInstanceOf();
  bool is_simple_instance_of =
      (call != NULL) && call->MatchesCoreName(Symbols::_simpleInstanceOf());
  if (load_cid != NULL && comparison->InputAt(1)->BindsToConstant()) {
    intptr_t cid = Smi::Cast(comparison->InputAt(1)->BoundConstant()).Value();
    BlockEntryInstr* true_successor =
        negated ? instr->false_successor() : instr->true_successor();
    EnsureMoreAccurateRedefinition(true_successor,
                                   load_cid->object()->definition(),
                                   CompileType::FromCid(cid));
  } else if ((is_simple_instance_of || (instance_of != NULL)) &&
             comparison->InputAt(1)->BindsToConstant() &&
             comparison->InputAt(1)->BoundConstant().IsBool()) {
    if (comparison->InputAt(1)->BoundConstant().raw() == Bool::False().raw()) {
      negated = !negated;
    }
    BlockEntryInstr* true_successor =
        negated ? instr->false_successor() : instr->true_successor();
    const AbstractType* type = NULL;
    Definition* left = NULL;
    if (is_simple_instance_of) {
      ASSERT(call->ArgumentAt(1)->IsConstant());
      const Object& type_obj = call->ArgumentAt(1)->AsConstant()->value();
      if (!type_obj.IsType()) {
        return;
      }
      type = &Type::Cast(type_obj);
      left = call->ArgumentAt(0);
    } else {
      type = &(instance_of->type());
      left = instance_of->value()->definition();
    }
    if (!type->IsTopTypeForInstanceOf()) {
      const bool is_nullable = (type->IsNullable() || type->IsTypeParameter() ||
                                (type->IsNeverType() && type->IsLegacy()))
                                   ? CompileType::kNullable
                                   : CompileType::kNonNullable;
      EnsureMoreAccurateRedefinition(
          true_successor, left,
          CompileType::FromAbstractType(*type, is_nullable));
    }
  } else if (comparison->InputAt(0)->BindsToConstant() &&
             comparison->InputAt(0)->BoundConstant().IsNull()) {
    // Handle for expr != null.
    BlockEntryInstr* true_successor =
        negated ? instr->true_successor() : instr->false_successor();
    EnsureMoreAccurateRedefinition(
        true_successor, comparison->InputAt(1)->definition(),
        comparison->InputAt(1)->Type()->CopyNonNullable());

  } else if (comparison->InputAt(1)->BindsToConstant() &&
             comparison->InputAt(1)->BoundConstant().IsNull()) {
    // Handle for null != expr.
    BlockEntryInstr* true_successor =
        negated ? instr->true_successor() : instr->false_successor();
    EnsureMoreAccurateRedefinition(
        true_successor, comparison->InputAt(0)->definition(),
        comparison->InputAt(0)->Type()->CopyNonNullable());
  }
  // TODO(fschneider): Add propagation for generic is-tests.
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
    check_clone = new CheckSmiInstr(assert->value()->Copy(zone()),
                                    assert->deopt_id(), check->source());
    check_clone->AsCheckSmi()->set_licm_hoisted(
        check->AsCheckSmi()->licm_hoisted());
  } else {
    ASSERT(check->IsCheckClass());
    check_clone =
        new CheckClassInstr(assert->value()->Copy(zone()), assert->deopt_id(),
                            check->AsCheckClass()->cids(), check->source());
    check_clone->AsCheckClass()->set_licm_hoisted(
        check->AsCheckClass()->licm_hoisted());
  }
  ASSERT(check_clone != NULL);
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

  const AbstractType* abstract_type = ToAbstractType();
  if (ToNullableCid() != other->ToNullableCid()) {
    ASSERT(cid_ != kNullCid);
    cid_ = kDynamicCid;
  }

  const AbstractType* other_abstract_type = other->ToAbstractType();
  if (abstract_type->IsSubtypeOf(*other_abstract_type, Heap::kOld)) {
    type_ = other_abstract_type;
    return;
  } else if (other_abstract_type->IsSubtypeOf(*abstract_type, Heap::kOld)) {
    return;  // Nothing to do.
  }

  // Climb up the hierarchy to find a suitable supertype. Note that interface
  // types are not considered, making the union potentially non-commutative
  if (abstract_type->IsInstantiated() && !abstract_type->IsDynamicType()) {
    Class& cls = Class::Handle(abstract_type->type_class());
    for (; !cls.IsNull() && !cls.IsGeneric(); cls = cls.SuperClass()) {
      type_ = &AbstractType::ZoneHandle(cls.RareType());
      if (other_abstract_type->IsSubtypeOf(*type_, Heap::kOld)) {
        // Found suitable supertype: keep type_ only.
        cid_ = kDynamicCid;
        return;
      }
    }
  }

  // Can't unify.
  type_ = &Object::dynamic_type();
}

CompileType* CompileType::ComputeRefinedType(CompileType* old_type,
                                             CompileType* new_type) {
  ASSERT(new_type != nullptr);

  // In general, prefer the newly inferred type over old type.
  // It is possible that new and old types are unrelated or do not intersect
  // at all (for example, in case of unreachable code).

  // Discard None type as it is used to denote an unknown type.
  if (old_type == nullptr || old_type->IsNone()) {
    return new_type;
  }
  if (new_type->IsNone()) {
    return old_type;
  }

  // Prefer exact Cid if known.
  if (new_type->ToCid() != kDynamicCid) {
    return new_type;
  }
  if (old_type->ToCid() != kDynamicCid) {
    return old_type;
  }

  const AbstractType* old_abstract_type = old_type->ToAbstractType();
  const AbstractType* new_abstract_type = new_type->ToAbstractType();

  CompileType* preferred_type;
  if (old_abstract_type->IsSubtypeOf(*new_abstract_type, Heap::kOld)) {
    // Prefer old type, as it is clearly more specific.
    preferred_type = old_type;
  } else {
    // Prefer new type as it is more recent, even though it might be
    // no better than the old type.
    preferred_type = new_type;
  }

  // Refine non-nullability.
  bool is_nullable = old_type->is_nullable() && new_type->is_nullable();

  if (preferred_type->is_nullable() && !is_nullable) {
    return new CompileType(preferred_type->CopyNonNullable());
  } else {
    ASSERT(preferred_type->is_nullable() == is_nullable);
    return preferred_type;
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
  return CompileType(is_nullable && !type.IsStrictlyNonNullable(), kIllegalCid,
                     &type);
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

CompileType CompileType::Int32() {
#if defined(TARGET_ARCH_IS_64_BIT)
  return FromCid(kSmiCid);
#else
  return Int();
#endif
}

CompileType CompileType::NullableInt() {
  return FromAbstractType(Type::ZoneHandle(Type::NullableIntType()), kNullable);
}

CompileType CompileType::Smi() {
  return Create(kSmiCid, Type::ZoneHandle(Type::SmiType()));
}

CompileType CompileType::Double() {
  return Create(kDoubleCid, Type::ZoneHandle(Type::Double()));
}

CompileType CompileType::NullableDouble() {
  return FromAbstractType(Type::ZoneHandle(Type::NullableDouble()), kNullable);
}

CompileType CompileType::String() {
  return FromAbstractType(Type::ZoneHandle(Type::StringType()), kNonNullable);
}

intptr_t CompileType::ToCid() {
  if (cid_ == kIllegalCid) {
    // Make sure to initialize cid_ for Null type to consistently return
    // kNullCid.
    if ((type_ != NULL) && type_->IsNullType()) {
      cid_ = kNullCid;
    }
  }

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
    } else if (type_->IsVoidType()) {
      cid_ = kDynamicCid;
    } else if (type_->IsNullType()) {
      cid_ = kNullCid;
    } else if (type_->IsFunctionType() || type_->IsDartFunctionType()) {
      cid_ = kClosureCid;
    } else if (type_->type_class_id() != kIllegalCid) {
      const Class& type_class = Class::Handle(type_->type_class());
      Thread* thread = Thread::Current();
      CHA& cha = thread->compiler_state().cha();
      // Don't infer a cid from an abstract type since there can be multiple
      // compatible classes with different cids.
      if (!type_class.is_abstract() && !CHA::IsImplemented(type_class) &&
          !CHA::HasSubclasses(type_class)) {
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
            cha.AddToGuardedClasses(type_class, /*subclass_count=*/0);
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
      return &Object::dynamic_type();
    }

    // VM-internal objects don't have a compile-type. Return dynamic-type
    // in this case.
    if ((cid_ < kInstanceCid) || (cid_ == kTypeArgumentsCid)) {
      type_ = &Object::dynamic_type();
      return type_;
    }

    Isolate* I = Isolate::Current();
    const Class& type_class = Class::Handle(I->class_table()->At(cid_));
    type_ = &AbstractType::ZoneHandle(type_class.RareType());
  }

  return type_;
}

bool CompileType::IsSubtypeOf(const AbstractType& other) {
  if (other.IsTopTypeForSubtyping()) {
    return true;
  }

  if (IsNone()) {
    return false;
  }

  return ToAbstractType()->IsSubtypeOf(other, Heap::kOld);
}

bool CompileType::IsAssignableTo(const AbstractType& other) {
  if (other.IsTopTypeForSubtyping()) {
    return true;
  }
  if (IsNone()) {
    return false;
  }
  if (is_nullable() && !Instance::NullIsAssignableTo(other)) {
    return false;
  }
  return ToAbstractType()->IsSubtypeOf(other, Heap::kOld);
}

bool CompileType::IsInstanceOf(const AbstractType& other) {
  if (other.IsTopTypeForInstanceOf()) {
    return true;
  }
  if (IsNone() || !other.IsInstantiated()) {
    return false;
  }
  if (is_nullable() && !other.IsNullable()) {
    return false;
  }
  return ToAbstractType()->IsSubtypeOf(other, Heap::kOld);
}

bool CompileType::Specialize(GrowableArray<intptr_t>* class_ids) {
  ToNullableCid();
  if (cid_ != kDynamicCid) {
    class_ids->Add(cid_);
    return true;
  }
  if (type_ != nullptr && type_->type_class_id() != kIllegalCid) {
    const Class& type_class = Class::Handle(type_->type_class());
    if (!CHA::ConcreteSubclasses(type_class, class_ids)) return false;
    if (is_nullable_) {
      class_ids->Add(kNullCid);
    }
  }
  return false;
}

// For the given type conservatively computes whether Smi can potentially
// appear in a location of this type.
//
// If recurse is false this function will not call itself recursively
// to prevent infinite recursion when traversing a cycle in type parameter
// bounds.
static bool CanPotentiallyBeSmi(const AbstractType& type, bool recurse) {
  if (type.IsInstantiated()) {
    return CompileType::Smi().IsAssignableTo(type);
  } else if (type.IsTypeParameter()) {
    // For type parameters look at their bounds (if recurse allows us).
    const auto& param = TypeParameter::Cast(type);
    return !recurse || CanPotentiallyBeSmi(AbstractType::Handle(param.bound()),
                                           /*recurse=*/false);
  } else if (type.HasTypeClass()) {
    // If this is an unstantiated type then it can only potentially be a super
    // type of a Smi if it is either FutureOr<...> or Comparable<...>.
    // In which case we need to look at the type argument to determine whether
    // this location can contain a smi.
    //
    // Note: we are making a simplification here. This approach will yield
    // true for Comparable<T> where T extends int - while in reality Smi is
    // *not* assignable to it (because int implements Comparable<num> and not
    // Comparable<int>).
    if (type.IsFutureOrType() ||
        type.type_class() == CompilerState::Current().ComparableClass().raw()) {
      const auto& args = TypeArguments::Handle(Type::Cast(type).arguments());
      const auto& arg0 = AbstractType::Handle(args.TypeAt(0));
      return !recurse || CanPotentiallyBeSmi(arg0, /*recurse=*/true);
    }
    return false;
  }
  return false;
}

bool CompileType::CanBeSmi() {
  // Fast path for known cid.
  if (cid_ != kIllegalCid && cid_ != kDynamicCid) {
    return cid_ == kSmiCid;
  }
  return CanPotentiallyBeSmi(*ToAbstractType(), /*recurse=*/true);
}

void CompileType::PrintTo(BaseTextBuffer* f) const {
  const char* type_name = "?";
  if (IsNone()) {
    f->AddString("T{}");
    return;
  } else if ((cid_ != kIllegalCid) && (cid_ != kDynamicCid)) {
    const Class& cls =
        Class::Handle(Isolate::Current()->class_table()->At(cid_));
    type_name = String::Handle(cls.ScrubbedName()).ToCString();
  } else if (type_ != NULL) {
    type_name = type_->IsDynamicType()
                    ? "*"
                    : String::Handle(type_->UserVisibleName()).ToCString();
  } else if (!is_nullable()) {
    type_name = "!null";
  }

  f->Printf("T{%s%s}", type_name, is_nullable_ ? "?" : "");
}

const char* CompileType::ToCString() const {
  char buffer[1024];
  BufferFormatter f(buffer, sizeof(buffer));
  PrintTo(&f);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

CompileType* Value::Type() {
  if (reaching_type_ == NULL) {
    reaching_type_ = definition()->Type();
  }
  return reaching_type_;
}

void Value::SetReachingType(CompileType* type) {
  // If [type] is owned but not by the definition which flows into this use
  // then we need to disconect the type from original owner by cloning it.
  // This is done to prevent situations when [type] is updated by its owner
  // but [owner] is no longer connected to this use through def-use chain
  // and as a result type propagator does not recompute type of the current
  // instruction.
  if (type != nullptr && type->owner() != nullptr &&
      type->owner() != definition()) {
    type = new CompileType(*type);
  }
  reaching_type_ = type;
}

void Value::RefineReachingType(CompileType* type) {
  SetReachingType(CompileType::ComputeRefinedType(reaching_type_, type));
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
                ssa_temp_index(), i, InputAt(i)->definition()->ssa_temp_index(),
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
  if (constrained_type_ != NULL) {
    // Check if the type associated with this redefinition is more specific
    // than the type of its input. If yes, return it. Otherwise, fall back
    // to the input's type.

    // If either type is non-nullable, the resulting type is non-nullable.
    const bool is_nullable =
        value()->Type()->is_nullable() && constrained_type_->is_nullable();

    // If either type has a concrete cid, stick with it.
    if (value()->Type()->ToNullableCid() != kDynamicCid) {
      return CompileType::CreateNullable(is_nullable,
                                         value()->Type()->ToNullableCid());
    }
    if (constrained_type_->ToNullableCid() != kDynamicCid) {
      return CompileType::CreateNullable(is_nullable,
                                         constrained_type_->ToNullableCid());
    }
    if (value()->Type()->IsSubtypeOf(*constrained_type_->ToAbstractType())) {
      return is_nullable ? *value()->Type()
                         : value()->Type()->CopyNonNullable();
    } else {
      return is_nullable ? *constrained_type_
                         : constrained_type_->CopyNonNullable();
    }
  }
  return *value()->Type();
}

bool RedefinitionInstr::RecomputeType() {
  return UpdateType(ComputeType());
}

CompileType CheckNullInstr::ComputeType() const {
  CompileType* type = value()->Type();
  if (type->is_nullable()) {
    CompileType result = type->CopyNonNullable();
    if (!result.IsNone()) {
      return result;
    }
  }
  return *type;
}

bool CheckNullInstr::RecomputeType() {
  return UpdateType(ComputeType());
}

CompileType CheckArrayBoundInstr::ComputeType() const {
  return *index()->Type();
}

bool CheckArrayBoundInstr::RecomputeType() {
  return UpdateType(ComputeType());
}

CompileType GenericCheckBoundInstr::ComputeType() const {
  return *index()->Type();
}

bool GenericCheckBoundInstr::RecomputeType() {
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
    if (auto function_entry = block_->AsFunctionEntry()) {
      graph_entry = function_entry->graph_entry();
    } else if (auto osr_entry = block_->AsOsrEntry()) {
      graph_entry = osr_entry->graph_entry();
    } else if (auto catch_entry = block_->AsCatchBlockEntry()) {
      graph_entry = catch_entry->graph_entry();
    } else {
      UNREACHABLE();
    }
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
      default:
        UNREACHABLE();
    }
    UNREACHABLE();
    return CompileType::Dynamic();
  }

  // Parameter is the receiver.
  if ((index() == 0) &&
      (function.IsDynamicFunction() || function.IsGenerativeConstructor())) {
    const AbstractType& type =
        graph_entry->parsed_function().RawParameterVariable(0)->type();
    if (type.IsObjectType() || type.IsNullType()) {
      // Receiver can be null.
      return CompileType::FromAbstractType(type);
    }

    // Receiver can't be null but can be an instance of a subclass.
    intptr_t cid = kDynamicCid;

    if (type.type_class_id() != kIllegalCid) {
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
              THR_Print(
                  "  **(CHA) Computing exact type of receiver, "
                  "no subclasses: %s\n",
                  type_class.ToCString());
            }
            if (FLAG_use_cha_deopt) {
              thread->compiler_state().cha().AddToGuardedClasses(
                  type_class,
                  /*subclass_count=*/0);
            }
            cid = type_class.id();
          }
        }
      }
    }

    return CompileType(CompileType::kNonNullable, cid, &type);
  }

  const bool is_unchecked_entry_param =
      graph_entry->unchecked_entry() == block_;

  LocalScope* scope = graph_entry->parsed_function().scope();
  // Note: in catch-blocks we have ParameterInstr for each local variable
  // not only for normal parameters.
  const LocalVariable* param = nullptr;
  if (scope != nullptr && (index() < scope->num_variables())) {
    param = scope->VariableAt(index());
  } else if (index() < function.NumParameters()) {
    param = graph_entry->parsed_function().RawParameterVariable(index());
  }
  if (param != nullptr) {
    CompileType* inferred_type = NULL;
    if (!block_->IsCatchBlockEntry()) {
      inferred_type = param->parameter_type();
    }
    // Best bet: use inferred type if it is a concrete class or int.
    if ((inferred_type != nullptr) &&
        ((inferred_type->ToNullableCid() != kDynamicCid) ||
         inferred_type->IsNullableInt())) {
      TraceStrongModeType(this, inferred_type);
      return *inferred_type;
    }
    // If parameter type was checked by caller, then use Dart type annotation,
    // plus non-nullability from inferred type if known.
    // Do not trust static parameter type of 'operator ==' as it is a
    // non-nullable Object but VM handles comparison with null in
    // the callee, so 'operator ==' can take null as an argument.
    if ((function.name() != Symbols::EqualOperator().raw()) &&
        (param->was_type_checked_by_caller() ||
         (is_unchecked_entry_param &&
          !param->is_explicit_covariant_parameter()))) {
      const bool is_nullable =
          (inferred_type == NULL) || inferred_type->is_nullable();
      TraceStrongModeType(this, param->type());
      return CompileType::FromAbstractType(param->type(), is_nullable);
    }
    // Last resort: use inferred non-nullability.
    if (inferred_type != NULL) {
      TraceStrongModeType(this, inferred_type);
      return *inferred_type;
    }
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

  if (cid == kSmiCid && !compiler::target::IsSmi(Smi::Cast(value()).Value())) {
    return CompileType::Create(kMintCid,
                               AbstractType::ZoneHandle(Type::MintType()));
  }

  if ((cid != kTypeArgumentsCid) && value().IsInstance()) {
    // Allocate in old-space since this may be invoked from the
    // background compiler.
    return CompileType::Create(
        cid,
        AbstractType::ZoneHandle(Instance::Cast(value()).GetType(Heap::kOld)));
  } else {
    // Type info for non-instance objects.
    return CompileType::FromCid(cid);
  }
}

CompileType AssertAssignableInstr::ComputeType() const {
  CompileType* value_type = value()->Type();

  const AbstractType* abs_type = &AbstractType::dynamic_type();
  if (dst_type()->BindsToConstant() &&
      dst_type()->BoundConstant().IsAbstractType()) {
    abs_type = &AbstractType::Cast(dst_type()->BoundConstant());
    if (value_type->IsSubtypeOf(*abs_type)) {
      return *value_type;
    }
  }
  return CompileType::FromAbstractType(*abs_type, value_type->is_nullable());
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

CompileType SpecialParameterInstr::ComputeType() const {
  switch (kind()) {
    case kContext:
      return CompileType::FromCid(kContextCid);
    case kTypeArgs:
      return CompileType::FromCid(kTypeArgumentsCid);
    case kArgDescriptor:
      return CompileType::FromCid(kImmutableArrayCid);
    case kException:
      return CompileType(CompileType::kNonNullable, kDynamicCid,
                         &Object::dynamic_type());
    case kStackTrace:
      // We cannot use [kStackTraceCid] here because any kind of object can be
      // used as a stack trace via `new Future.error(..., <obj>)` :-/
      return CompileType::Dynamic();
  }
  UNREACHABLE();
  return CompileType::Dynamic();
}

CompileType CloneContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable, kContextCid,
                     &Object::dynamic_type());
}

CompileType AllocateContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable, kContextCid,
                     &Object::dynamic_type());
}

CompileType AllocateUninitializedContextInstr::ComputeType() const {
  return CompileType(CompileType::kNonNullable, kContextCid,
                     &Object::dynamic_type());
}

CompileType InstanceCallBaseInstr::ComputeType() const {
  // TODO(alexmarkov): calculate type of InstanceCallInstr eagerly
  // (in optimized mode) and avoid keeping separate result_type.
  CompileType* inferred_type = result_type();
  if ((inferred_type != NULL) &&
      (inferred_type->ToNullableCid() != kDynamicCid)) {
    TraceStrongModeType(this, inferred_type);
    return *inferred_type;
  }

  const Function& target = interface_target();
  if (!target.IsNull()) {
    const AbstractType& result_type =
        AbstractType::ZoneHandle(target.result_type());
    // Currently VM doesn't have enough information to instantiate generic
    // result types of interface targets:
    // 1. receiver type inferred by the front-end is not passed to VM.
    // 2. VM collects type arguments through the chain of superclasses but
    // not through implemented interfaces.
    // So treat non-instantiated generic types as dynamic to avoid pretending
    // the type is known.
    // TODO(dartbug.com/30480): instantiate generic result_type
    if (result_type.IsInstantiated()) {
      TraceStrongModeType(this, result_type);
      const bool is_nullable =
          (inferred_type == NULL) || inferred_type->is_nullable();
      return CompileType::FromAbstractType(result_type, is_nullable);
    }
  }

  return CompileType::Dynamic();
}

CompileType DispatchTableCallInstr::ComputeType() const {
  // TODO(dartbug.com/40188): Share implementation with InstanceCallBaseInstr.
  const Function& target = interface_target();
  ASSERT(!target.IsNull());
  const auto& result_type = AbstractType::ZoneHandle(target.result_type());
  if (result_type.IsInstantiated()) {
    TraceStrongModeType(this, result_type);
    return CompileType::FromAbstractType(result_type);
  }

  return CompileType::Dynamic();
}

CompileType PolymorphicInstanceCallInstr::ComputeType() const {
  bool is_nullable = CompileType::kNullable;
  if (IsSureToCallSingleRecognizedTarget()) {
    const Function& target = *targets_.TargetAt(0)->target;
    if (target.has_pragma()) {
      const intptr_t cid = MethodRecognizer::ResultCidFromPragma(target);
      if (cid != kDynamicCid) {
        return CompileType::FromCid(cid);
      } else if (MethodRecognizer::HasNonNullableResultTypeFromPragma(target)) {
        is_nullable = CompileType::kNonNullable;
      }
    }
  }

  CompileType type = InstanceCallBaseInstr::ComputeType();
  return is_nullable ? type : type.CopyNonNullable();
}

static CompileType ComputeListFactoryType(CompileType* inferred_type,
                                          Value* type_args_value) {
  ASSERT(inferred_type != nullptr);
  const intptr_t cid = inferred_type->ToNullableCid();
  ASSERT(cid != kDynamicCid);
  if ((cid == kGrowableObjectArrayCid || cid == kArrayCid ||
       cid == kImmutableArrayCid) &&
      type_args_value->BindsToConstant()) {
    const auto& type_args =
        type_args_value->BoundConstant().IsNull()
            ? TypeArguments::null_type_arguments()
            : TypeArguments::Cast(type_args_value->BoundConstant());
    const Class& cls =
        Class::Handle(Isolate::Current()->class_table()->At(cid));
    Type& type = Type::ZoneHandle(Type::New(
        cls, type_args, TokenPosition::kNoSource, Nullability::kNonNullable));
    ASSERT(type.IsInstantiated());
    type.SetIsFinalized();
    return CompileType(CompileType::kNonNullable, cid, &type);
  }
  return *inferred_type;
}

CompileType StaticCallInstr::ComputeType() const {
  // TODO(alexmarkov): calculate type of StaticCallInstr eagerly
  // (in optimized mode) and avoid keeping separate result_type.
  CompileType* const inferred_type = result_type();
  if (is_known_list_constructor()) {
    return ComputeListFactoryType(inferred_type, ArgumentValueAt(0));
  }
  if ((inferred_type != NULL) &&
      (inferred_type->ToNullableCid() != kDynamicCid)) {
    return *inferred_type;
  }

  bool is_nullable = CompileType::kNullable;
  if (function_.has_pragma()) {
    const intptr_t cid = MethodRecognizer::ResultCidFromPragma(function_);
    if (cid != kDynamicCid) {
      return CompileType::FromCid(cid);
    }
    if (MethodRecognizer::HasNonNullableResultTypeFromPragma(function_)) {
      is_nullable = CompileType::kNonNullable;
    }
  }

  const AbstractType& result_type =
      AbstractType::ZoneHandle(function().result_type());
  // TODO(dartbug.com/30480): instantiate generic result_type if possible.
  // Also, consider fixing AbstractType::IsSubtypeOf to handle
  // non-instantiated types properly.
  if (result_type.IsInstantiated()) {
    TraceStrongModeType(this, result_type);
    is_nullable = is_nullable &&
                  (inferred_type == nullptr || inferred_type->is_nullable());
    return CompileType::FromAbstractType(result_type, is_nullable);
  }

  return CompileType::Dynamic();
}

CompileType LoadLocalInstr::ComputeType() const {
  if (local().needs_covariant_check_in_method()) {
    // We may not yet have checked the actual type of the parameter value.
    // Assuming that the value has the required type can lead to unsound
    // optimizations. See dartbug.com/43464.
    return CompileType::FromCid(kDynamicCid);
  }
  const AbstractType& local_type = local().type();
  TraceStrongModeType(this, local_type);
  return CompileType::FromAbstractType(local_type);
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
  const Field& field = this->field();
  bool is_nullable = CompileType::kNullable;
  intptr_t cid = kIllegalCid;  // Abstract type is known, calculate cid lazily.
  AbstractType* abstract_type = &AbstractType::ZoneHandle(field.type());
  TraceStrongModeType(this, *abstract_type);
  ASSERT(field.is_static());
  const bool is_initialized = IsFieldInitialized() && !FLAG_fields_may_be_reset;
  if (field.is_final() && is_initialized) {
    const Instance& obj = Instance::Handle(field.StaticValue());
    if (!obj.IsNull()) {
      is_nullable = CompileType::kNonNullable;
      cid = obj.GetClassId();
      abstract_type = nullptr;  // Cid is known, calculate abstract type lazily.
    }
  }
  if ((field.guarded_cid() != kIllegalCid) &&
      (field.guarded_cid() != kDynamicCid)) {
    cid = field.guarded_cid();
    is_nullable = field.is_nullable();
    abstract_type = nullptr;  // Cid is known, calculate abstract type lazily.
  }
  if (field.needs_load_guard()) {
    // Should be kept in sync with Slot::Get.
    DEBUG_ASSERT(Isolate::Current()->HasAttemptedReload());
    return CompileType::Dynamic();
  }
  return CompileType(is_nullable, cid, abstract_type);
}

CompileType CreateArrayInstr::ComputeType() const {
  // TODO(fschneider): Add abstract type and type arguments to the compile type.
  return CompileType::FromCid(kArrayCid);
}

CompileType AllocateTypedDataInstr::ComputeType() const {
  return CompileType::FromCid(class_id());
}

CompileType AllocateObjectInstr::ComputeType() const {
  if (!closure_function().IsNull()) {
    ASSERT(cls().id() == kClosureCid);
    return CompileType(CompileType::kNonNullable, kClosureCid,
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
  const AbstractType& field_type = slot().static_type();
  CompileType compile_type_cid = slot().ComputeCompileType();
  if (field_type.raw() == AbstractType::null()) {
    return compile_type_cid;
  }

  const AbstractType* abstract_type = &field_type;
  TraceStrongModeType(this, *abstract_type);

  if (compile_type_cid.ToNullableCid() != kDynamicCid) {
    abstract_type = nullptr;
  }

  return CompileType(compile_type_cid.is_nullable(),
                     compile_type_cid.ToNullableCid(), abstract_type);
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

CompileType BinaryUint32OpInstr::ComputeType() const {
  return CompileType::Int32();
}

CompileType ShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int32();
}

CompileType SpeculativeShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int32();
}

CompileType UnaryUint32OpInstr::ComputeType() const {
  return CompileType::Int32();
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

// Note that Int64Op may produce Smi-s as result of an
// appended BoxInt64Instr node.
CompileType BinaryInt64OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType ShiftInt64OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType SpeculativeShiftInt64OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType UnaryInt64OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType CheckedSmiOpInstr::ComputeType() const {
  if (left()->Type()->IsNullableInt() && right()->Type()->IsNullableInt()) {
    const AbstractType& abstract_type =
        AbstractType::ZoneHandle(Type::IntType());
    TraceStrongModeType(this, abstract_type);
    return CompileType::FromAbstractType(abstract_type,
                                         CompileType::kNonNullable);
  } else {
    CompileType* type = call()->Type();
    TraceStrongModeType(this, type);
    return *type;
  }
}

bool CheckedSmiOpInstr::RecomputeType() {
  return UpdateType(ComputeType());
}

CompileType CheckedSmiComparisonInstr::ComputeType() const {
  CompileType* type = call()->Type();
  TraceStrongModeType(this, type);
  return *type;
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

static const intptr_t simd_op_result_cids[] = {
#define kInt8Cid kSmiCid
#define CASE(Arity, Mask, Name, Args, Result) k##Result##Cid,
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
#undef kWordCid
};

CompileType SimdOpInstr::ComputeType() const {
  return CompileType::FromCid(simd_op_result_cids[kind()]);
}

CompileType MathUnaryInstr::ComputeType() const {
  return CompileType::FromCid(kDoubleCid);
}

CompileType MathMinMaxInstr::ComputeType() const {
  return CompileType::FromCid(result_cid_);
}

CompileType CaseInsensitiveCompareInstr::ComputeType() const {
  return CompileType::FromCid(kBoolCid);
}

CompileType UnboxInstr::ComputeType() const {
  switch (representation()) {
    case kUnboxedFloat:
    case kUnboxedDouble:
      return CompileType::FromCid(kDoubleCid);

    case kUnboxedFloat32x4:
      return CompileType::FromCid(kFloat32x4Cid);

    case kUnboxedFloat64x2:
      return CompileType::FromCid(kFloat64x2Cid);

    case kUnboxedInt32x4:
      return CompileType::FromCid(kInt32x4Cid);

    case kUnboxedInt64:
      return CompileType::Int();

    default:
      UNREACHABLE();
      return CompileType::Dynamic();
  }
}

CompileType BoxInstr::ComputeType() const {
  switch (from_representation()) {
    case kUnboxedFloat:
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

CompileType Int64ToDoubleInstr::ComputeType() const {
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

CompileType TruncDivModInstr::ComputeType() const {
  return CompileType::Dynamic();
}

CompileType ExtractNthOutputInstr::ComputeType() const {
  return CompileType::FromCid(definition_cid_);
}

static AbstractTypePtr ExtractElementTypeFromArrayType(
    const AbstractType& array_type) {
  if (array_type.IsTypeParameter()) {
    return ExtractElementTypeFromArrayType(
        AbstractType::Handle(TypeParameter::Cast(array_type).bound()));
  }
  if (!array_type.IsType()) {
    return Object::dynamic_type().raw();
  }
  const intptr_t cid = array_type.type_class_id();
  if (cid == kGrowableObjectArrayCid || cid == kArrayCid ||
      cid == kImmutableArrayCid ||
      array_type.type_class() ==
          Isolate::Current()->object_store()->list_class()) {
    const auto& type_args = TypeArguments::Handle(array_type.arguments());
    return type_args.TypeAtNullSafe(Array::kElementTypeTypeArgPos);
  }
  return Object::dynamic_type().raw();
}

static AbstractTypePtr GetElementTypeFromArray(Value* array) {
  // Sometimes type of definition may contain a static type
  // which is useful to extract element type, but reaching type
  // only has a cid. So try out type of definition, if any.
  if (array->definition()->HasType()) {
    auto& elem_type = AbstractType::Handle(ExtractElementTypeFromArrayType(
        *(array->definition()->Type()->ToAbstractType())));
    if (!elem_type.IsDynamicType()) {
      return elem_type.raw();
    }
  }
  return ExtractElementTypeFromArrayType(*(array->Type()->ToAbstractType()));
}

static CompileType ComputeArrayElementType(Value* array) {
  // 1. Try to extract element type from array value.
  auto& elem_type = AbstractType::Handle(GetElementTypeFromArray(array));
  if (!elem_type.IsDynamicType()) {
    return CompileType::FromAbstractType(elem_type);
  }

  // 2. Array value may be loaded from GrowableObjectArray.data.
  // Unwrap and try again.
  if (auto* load_field = array->definition()->AsLoadField()) {
    if (load_field->slot().IsIdentical(Slot::GrowableObjectArray_data())) {
      array = load_field->instance();
      elem_type = GetElementTypeFromArray(array);
      if (!elem_type.IsDynamicType()) {
        return CompileType::FromAbstractType(elem_type);
      }
    }
  }

  // 3. If array was loaded from a Dart field, use field's static type.
  // Unlike propagated type (which could be cid), static type may contain
  // type arguments which can be used to figure out element type.
  if (auto* load_field = array->definition()->AsLoadField()) {
    if (load_field->slot().IsDartField()) {
      elem_type =
          ExtractElementTypeFromArrayType(load_field->slot().static_type());
    }
  }
  return CompileType::FromAbstractType(elem_type);
}

CompileType LoadIndexedInstr::ComputeType() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
      if (result_type_ != nullptr) {
        // The original call knew something.
        return *result_type_;
      }
      return ComputeArrayElementType(array());

    case kTypeArgumentsCid:
      return CompileType::FromAbstractType(Object::dynamic_type(),
                                           /*is_nullable=*/false);

    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return CompileType::FromCid(kDoubleCid);

    case kTypedDataFloat32x4ArrayCid:
      return CompileType::FromCid(kFloat32x4Cid);

    case kTypedDataInt32x4ArrayCid:
      return CompileType::FromCid(kInt32x4Cid);

    case kTypedDataFloat64x2ArrayCid:
      return CompileType::FromCid(kFloat64x2Cid);

    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return CompileType::Int32();

    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return CompileType::Int();

    default:
      UNIMPLEMENTED();
      return CompileType::Dynamic();
  }
}

bool LoadIndexedInstr::RecomputeType() {
  if ((class_id_ == kArrayCid) || (class_id_ == kImmutableArrayCid)) {
    // Array element type computation depends on computed
    // types of other instructions and may change over time.
    return UpdateType(ComputeType());
  }
  return false;
}

}  // namespace dart
