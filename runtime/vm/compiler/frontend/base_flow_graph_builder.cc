// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/base_flow_graph_builder.h"

#include "vm/compiler/frontend/flow_graph_builder.h"  // For InlineExitCollector.
#include "vm/compiler/jit/compiler.h"  // For Compiler::IsBackgroundCompilation().

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define I (thread_->isolate())

Fragment& Fragment::operator+=(const Fragment& other) {
  if (entry == NULL) {
    entry = other.entry;
    current = other.current;
  } else if (current != NULL && other.entry != NULL) {
    current->LinkTo(other.entry);
    current = other.current;
  }
  return *this;
}

Fragment& Fragment::operator<<=(Instruction* next) {
  if (entry == NULL) {
    entry = current = next;
  } else if (current != NULL) {
    current->LinkTo(next);
    current = next;
  }
  return *this;
}

void Fragment::Prepend(Instruction* start) {
  if (entry == NULL) {
    entry = current = start;
  } else {
    start->LinkTo(entry);
    entry = start;
  }
}

Fragment Fragment::closed() {
  ASSERT(entry != NULL);
  return Fragment(entry, NULL);
}

Fragment operator+(const Fragment& first, const Fragment& second) {
  Fragment result = first;
  result += second;
  return result;
}

Fragment operator<<(const Fragment& fragment, Instruction* next) {
  Fragment result = fragment;
  result <<= next;
  return result;
}

TestFragment::TestFragment(Instruction* entry, BranchInstr* branch)
    : entry(entry),
      true_successor_addresses(new SuccessorAddressArray(1)),
      false_successor_addresses(new SuccessorAddressArray(1)) {
  true_successor_addresses->Add(branch->true_successor_address());
  false_successor_addresses->Add(branch->false_successor_address());
}

void TestFragment::ConnectBranchesTo(
    BaseFlowGraphBuilder* builder,
    const TestFragment::SuccessorAddressArray& branches,
    JoinEntryInstr* join) {
  ASSERT(!branches.is_empty());
  for (auto branch : branches) {
    *branch = builder->BuildTargetEntry();
    (*branch)->Goto(join);
  }
}

BlockEntryInstr* TestFragment::CreateSuccessorFor(
    BaseFlowGraphBuilder* builder,
    const TestFragment::SuccessorAddressArray& branches) {
  ASSERT(!branches.is_empty());

  if (branches.length() == 1) {
    TargetEntryInstr* target = builder->BuildTargetEntry();
    *(branches[0]) = target;
    return target;
  }

  JoinEntryInstr* join = builder->BuildJoinEntry();
  ConnectBranchesTo(builder, branches, join);
  return join;
}

BlockEntryInstr* TestFragment::CreateTrueSuccessor(
    BaseFlowGraphBuilder* builder) {
  ASSERT(true_successor_addresses != nullptr);
  return CreateSuccessorFor(builder, *true_successor_addresses);
}

BlockEntryInstr* TestFragment::CreateFalseSuccessor(
    BaseFlowGraphBuilder* builder) {
  ASSERT(false_successor_addresses != nullptr);
  return CreateSuccessorFor(builder, *false_successor_addresses);
}

Fragment BaseFlowGraphBuilder::LoadContextAt(int depth) {
  intptr_t delta = context_depth_ - depth;
  ASSERT(delta >= 0);
  Fragment instructions = LoadLocal(parsed_function_->current_context_var());
  while (delta-- > 0) {
    instructions += LoadField(Context::parent_offset());
  }
  return instructions;
}

Fragment BaseFlowGraphBuilder::StrictCompare(Token::Kind kind,
                                             bool number_check /* = false */) {
  Value* right = Pop();
  Value* left = Pop();
  StrictCompareInstr* compare =
      new (Z) StrictCompareInstr(TokenPosition::kNoSource, kind, left, right,
                                 number_check, GetNextDeoptId());
  Push(compare);
  return Fragment(compare);
}

Fragment BaseFlowGraphBuilder::BranchIfTrue(TargetEntryInstr** then_entry,
                                            TargetEntryInstr** otherwise_entry,
                                            bool negate) {
  Fragment instructions = Constant(Bool::True());
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}

Fragment BaseFlowGraphBuilder::BranchIfNull(TargetEntryInstr** then_entry,
                                            TargetEntryInstr** otherwise_entry,
                                            bool negate) {
  Fragment instructions = NullConstant();
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}

Fragment BaseFlowGraphBuilder::BranchIfEqual(TargetEntryInstr** then_entry,
                                             TargetEntryInstr** otherwise_entry,
                                             bool negate) {
  Value* right_value = Pop();
  Value* left_value = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      TokenPosition::kNoSource, negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
      left_value, right_value, false, GetNextDeoptId());
  BranchInstr* branch = new (Z) BranchInstr(compare, GetNextDeoptId());
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}

Fragment BaseFlowGraphBuilder::BranchIfStrictEqual(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry) {
  Value* rhs = Pop();
  Value* lhs = Pop();
  StrictCompareInstr* compare =
      new (Z) StrictCompareInstr(TokenPosition::kNoSource, Token::kEQ_STRICT,
                                 lhs, rhs, false, GetNextDeoptId());
  BranchInstr* branch = new (Z) BranchInstr(compare, GetNextDeoptId());
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}

Fragment BaseFlowGraphBuilder::Return(TokenPosition position) {
  Fragment instructions;

  Value* value = Pop();
  ASSERT(stack_ == nullptr);

  ReturnInstr* return_instr =
      new (Z) ReturnInstr(position, value, GetNextDeoptId());
  if (exit_collector_ != nullptr) exit_collector_->AddExit(return_instr);

  instructions <<= return_instr;

  return instructions.closed();
}

Fragment BaseFlowGraphBuilder::CheckStackOverflow(TokenPosition position) {
  return Fragment(
      new (Z) CheckStackOverflowInstr(position, loop_depth_, GetNextDeoptId()));
}

Fragment BaseFlowGraphBuilder::Constant(const Object& value) {
  ASSERT(value.IsNotTemporaryScopedHandle());
  ConstantInstr* constant = new (Z) ConstantInstr(value);
  Push(constant);
  return Fragment(constant);
}

Fragment BaseFlowGraphBuilder::Goto(JoinEntryInstr* destination) {
  return Fragment(new (Z) GotoInstr(destination, GetNextDeoptId())).closed();
}

Fragment BaseFlowGraphBuilder::IntConstant(int64_t value) {
  return Fragment(
      Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld))));
}

Fragment BaseFlowGraphBuilder::ThrowException(TokenPosition position) {
  Fragment instructions;
  instructions += Drop();
  instructions +=
      Fragment(new (Z) ThrowInstr(position, GetNextDeoptId())).closed();
  // Use it's side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  pending_argument_count_ -= 1;

  return instructions;
}

Fragment BaseFlowGraphBuilder::TailCall(const Code& code) {
  Value* arg_desc = Pop();
  return Fragment(new (Z) TailCallInstr(code, arg_desc));
}

void BaseFlowGraphBuilder::InlineBailout(const char* reason) {
  if (IsInlining()) {
    parsed_function_->function().set_is_inlinable(false);
    parsed_function_->Bailout("kernel::BaseFlowGraphBuilder", reason);
  }
}

Fragment BaseFlowGraphBuilder::TestTypeArgsLen(Fragment eq_branch,
                                               Fragment neq_branch,
                                               intptr_t num_type_args) {
  Fragment test;

  TargetEntryInstr* eq_entry;
  TargetEntryInstr* neq_entry;

  test += LoadArgDescriptor();
  test += LoadNativeField(NativeFieldDesc::ArgumentsDescriptor_type_args_len());
  test += IntConstant(num_type_args);
  test += BranchIfEqual(&eq_entry, &neq_entry);

  eq_branch.Prepend(eq_entry);
  neq_branch.Prepend(neq_entry);

  JoinEntryInstr* join = BuildJoinEntry();
  eq_branch += Goto(join);
  neq_branch += Goto(join);

  return Fragment(test.entry, join);
}

Fragment BaseFlowGraphBuilder::TestDelayedTypeArgs(LocalVariable* closure,
                                                   Fragment present,
                                                   Fragment absent) {
  Fragment test;

  TargetEntryInstr* absent_entry;
  TargetEntryInstr* present_entry;

  test += LoadLocal(closure);
  test += LoadField(Closure::delayed_type_arguments_offset());
  test += Constant(Object::empty_type_arguments());
  test += BranchIfEqual(&absent_entry, &present_entry);

  present.Prepend(present_entry);
  absent.Prepend(absent_entry);

  JoinEntryInstr* join = BuildJoinEntry();
  absent += Goto(join);
  present += Goto(join);

  return Fragment(test.entry, join);
}

Fragment BaseFlowGraphBuilder::TestAnyTypeArgs(Fragment present,
                                               Fragment absent) {
  if (parsed_function_->function().IsClosureFunction()) {
    LocalVariable* closure =
        parsed_function_->node_sequence()->scope()->VariableAt(0);

    JoinEntryInstr* complete = BuildJoinEntry();
    JoinEntryInstr* present_entry = BuildJoinEntry();

    Fragment test = TestTypeArgsLen(
        TestDelayedTypeArgs(closure, Goto(present_entry), absent),
        Goto(present_entry), 0);
    test += Goto(complete);

    Fragment(present_entry) + present + Goto(complete);

    return Fragment(test.entry, complete);
  } else {
    return TestTypeArgsLen(absent, present, 0);
  }
}

Fragment BaseFlowGraphBuilder::LoadField(intptr_t offset, intptr_t class_id) {
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      Pop(), offset, AbstractType::ZoneHandle(Z), TokenPosition::kNoSource);
  load->set_result_cid(class_id);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::LoadIndexed(intptr_t index_scale) {
  Value* index = Pop();
  Value* array = Pop();
  LoadIndexedInstr* instr = new (Z)
      LoadIndexedInstr(array, index, index_scale, kArrayCid, kAlignedAccess,
                       Thread::kNoDeoptId, TokenPosition::kNoSource);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadNativeField(
    const NativeFieldDesc* native_field) {
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(Pop(), native_field, TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  LoadLocalInstr* load =
      new (Z) LoadLocalInstr(*variable, TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::NullConstant() {
  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}

Fragment BaseFlowGraphBuilder::PushArgument() {
  PushArgumentInstr* argument = new (Z) PushArgumentInstr(Pop());
  Push(argument);

  argument->set_temp_index(argument->temp_index() - 1);
  ++pending_argument_count_;

  return Fragment(argument);
}

Fragment BaseFlowGraphBuilder::GuardFieldLength(const Field& field,
                                                intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldLengthInstr(Pop(), field, deopt_id));
}

Fragment BaseFlowGraphBuilder::GuardFieldClass(const Field& field,
                                               intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldClassInstr(Pop(), field, deopt_id));
}

const Field& BaseFlowGraphBuilder::MayCloneField(const Field& field) {
  if ((Compiler::IsBackgroundCompilation() ||
       FLAG_force_clone_compiler_objects) &&
      field.IsOriginal()) {
    return Field::ZoneHandle(Z, field.CloneFromOriginal());
  } else {
    ASSERT(field.IsZoneHandle());
    return field;
  }
}

Fragment BaseFlowGraphBuilder::StoreInstanceField(
    TokenPosition position,
    intptr_t offset,
    StoreBarrierType emit_store_barrier) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      offset, Pop(), value, emit_store_barrier, position);
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreInstanceField(
    const Field& field,
    bool is_initialization_store,
    StoreBarrierType emit_store_barrier) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }

  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(MayCloneField(field), Pop(), value,
                              emit_store_barrier, TokenPosition::kNoSource);
  store->set_is_initialization(is_initialization_store);

  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreInstanceFieldGuarded(
    const Field& field,
    bool is_initialization_store) {
  Fragment instructions;
  const Field& field_clone = MayCloneField(field);
  if (I->use_field_guards()) {
    LocalVariable* store_expression = MakeTemporary();
    instructions += LoadLocal(store_expression);
    instructions += GuardFieldClass(field_clone, GetNextDeoptId());
    instructions += LoadLocal(store_expression);
    instructions += GuardFieldLength(field_clone, GetNextDeoptId());

    // If we are tracking exactness of the static type of the field then
    // emit appropriate guard.
    if (field_clone.static_type_exactness_state().IsTracking()) {
      instructions += LoadLocal(store_expression);
      instructions <<=
          new (Z) GuardFieldTypeInstr(Pop(), field_clone, GetNextDeoptId());
    }
  }
  instructions += StoreInstanceField(field_clone, is_initialization_store);
  return instructions;
}

Fragment BaseFlowGraphBuilder::LoadStaticField() {
  LoadStaticFieldInstr* load =
      new (Z) LoadStaticFieldInstr(Pop(), TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::StoreStaticField(TokenPosition position,
                                                const Field& field) {
  return Fragment(
      new (Z) StoreStaticFieldInstr(MayCloneField(field), Pop(), position));
}

Fragment BaseFlowGraphBuilder::StoreIndexed(intptr_t class_id) {
  Value* value = Pop();
  Value* index = Pop();
  const StoreBarrierType emit_store_barrier =
      value->BindsToConstant() ? kNoStoreBarrier : kEmitStoreBarrier;
  StoreIndexedInstr* store = new (Z) StoreIndexedInstr(
      Pop(),  // Array.
      index, value, emit_store_barrier, Instance::ElementSizeFor(class_id),
      class_id, kAlignedAccess, Thread::kNoDeoptId, TokenPosition::kNoSource);
  Push(store);
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreLocal(TokenPosition position,
                                          LocalVariable* variable) {
  if (variable->is_captured()) {
    Fragment instructions;
    LocalVariable* value = MakeTemporary();
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions += LoadLocal(value);
    instructions += StoreInstanceField(
        position, Context::variable_offset(variable->index().value()));
    return instructions;
  }
  return StoreLocalRaw(position, variable);
}

Fragment BaseFlowGraphBuilder::StoreLocalRaw(TokenPosition position,
                                             LocalVariable* variable) {
  Value* value = Pop();
  StoreLocalInstr* store = new (Z) StoreLocalInstr(*variable, value, position);
  Fragment instructions(store);
  Push(store);
  return instructions;
}

LocalVariable* BaseFlowGraphBuilder::MakeTemporary() {
  char name[64];
  intptr_t index = stack_->definition()->temp_index();
  Utils::SNPrint(name, 64, ":temp%" Pd, index);
  const String& symbol_name =
      String::ZoneHandle(Z, Symbols::New(thread_, name));
  LocalVariable* variable =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            symbol_name, Object::dynamic_type());
  // Set the index relative to the base of the expression stack including
  // outgoing arguments.
  variable->set_index(VariableIndex(-parsed_function_->num_stack_locals() -
                                    pending_argument_count_ - index));

  // The value has uses as if it were a local variable.  Mark the definition
  // as used so that its temp index will not be cleared (causing it to never
  // be materialized in the expression stack).
  stack_->definition()->set_ssa_temp_index(0);

  return variable;
}

intptr_t BaseFlowGraphBuilder::CurrentTryIndex() {
  if (try_catch_block_ == NULL) {
    return CatchClauseNode::kInvalidTryIndex;
  } else {
    return try_catch_block_->try_index();
  }
}

void BaseFlowGraphBuilder::SetTempIndex(Definition* definition) {
  definition->set_temp_index(
      stack_ == NULL ? 0 : stack_->definition()->temp_index() + 1);
}

void BaseFlowGraphBuilder::Push(Definition* definition) {
  SetTempIndex(definition);
  Value::AddToList(new (Z) Value(definition), &stack_);
}

Definition* BaseFlowGraphBuilder::Peek() {
  ASSERT(stack_ != NULL);
  return stack_->definition();
}

Value* BaseFlowGraphBuilder::Pop() {
  ASSERT(stack_ != NULL);
  Value* value = stack_;
  stack_ = value->next_use();
  if (stack_ != NULL) stack_->set_previous_use(NULL);

  value->set_next_use(NULL);
  value->set_previous_use(NULL);
  value->definition()->ClearSSATempIndex();
  return value;
}

Fragment BaseFlowGraphBuilder::Drop() {
  ASSERT(stack_ != NULL);
  Fragment instructions;
  Definition* definition = stack_->definition();
  // The SSA renaming implementation doesn't like [LoadLocal]s without a
  // tempindex.
  if (definition->HasSSATemp() || definition->IsLoadLocal()) {
    instructions <<= new (Z) DropTempsInstr(1, NULL);
  } else {
    definition->ClearTempIndex();
  }

  Pop();
  return instructions;
}

Fragment BaseFlowGraphBuilder::DropTempsPreserveTop(
    intptr_t num_temps_to_drop) {
  Value* top = Pop();

  for (intptr_t i = 0; i < num_temps_to_drop; ++i) {
    Pop();
  }

  DropTempsInstr* drop_temps = new (Z) DropTempsInstr(num_temps_to_drop, top);
  Push(drop_temps);

  return Fragment(drop_temps);
}

Fragment BaseFlowGraphBuilder::MakeTemp() {
  MakeTempInstr* make_temp = new (Z) MakeTempInstr(Z);
  Push(make_temp);
  return Fragment(make_temp);
}

TargetEntryInstr* BaseFlowGraphBuilder::BuildTargetEntry() {
  return new (Z)
      TargetEntryInstr(AllocateBlockId(), CurrentTryIndex(), GetNextDeoptId());
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildJoinEntry(intptr_t try_index) {
  return new (Z) JoinEntryInstr(AllocateBlockId(), try_index, GetNextDeoptId());
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildJoinEntry() {
  return new (Z)
      JoinEntryInstr(AllocateBlockId(), CurrentTryIndex(), GetNextDeoptId());
}

ArgumentArray BaseFlowGraphBuilder::GetArguments(int count) {
  ArgumentArray arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, count);
  arguments->SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    ASSERT(stack_->definition()->IsPushArgument());
    ASSERT(!stack_->definition()->HasSSATemp());
    arguments->data()[i] = stack_->definition()->AsPushArgument();
    Drop();
  }
  pending_argument_count_ -= count;
  ASSERT(pending_argument_count_ >= 0);
  return arguments;
}

Fragment BaseFlowGraphBuilder::SmiRelationalOp(Token::Kind kind) {
  Value* right = Pop();
  Value* left = Pop();
  RelationalOpInstr* instr = new (Z) RelationalOpInstr(
      TokenPosition::kNoSource, kind, left, right, kSmiCid, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::SmiBinaryOp(Token::Kind kind,
                                           bool is_truncating) {
  Value* right = Pop();
  Value* left = Pop();
  BinarySmiOpInstr* instr =
      new (Z) BinarySmiOpInstr(kind, left, right, GetNextDeoptId());
  if (is_truncating) {
    instr->mark_truncating();
  }
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadFpRelativeSlot(intptr_t offset) {
  LoadIndexedUnsafeInstr* instr = new (Z) LoadIndexedUnsafeInstr(Pop(), offset);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::StoreFpRelativeSlot(intptr_t offset) {
  Value* value = Pop();
  Value* index = Pop();
  StoreIndexedUnsafeInstr* instr =
      new (Z) StoreIndexedUnsafeInstr(index, value, offset);
  Push(instr);
  return Fragment(instr);
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildThrowNoSuchMethod() {
  JoinEntryInstr* nsm = BuildJoinEntry();

  Fragment failing(nsm);
  const Code& nsm_handler =
      Code::ZoneHandle(StubCode::CallClosureNoSuchMethod_entry()->code());
  failing += LoadArgDescriptor();
  failing += TailCall(nsm_handler);

  return nsm;
}

Fragment BaseFlowGraphBuilder::AssertBool(TokenPosition position) {
  if (FLAG_omit_strong_type_checks) {
    return Fragment();
  }
  Value* value = Pop();
  AssertBooleanInstr* instr =
      new (Z) AssertBooleanInstr(position, value, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::BooleanNegate() {
  BooleanNegateInstr* negate = new (Z) BooleanNegateInstr(Pop());
  Push(negate);
  return Fragment(negate);
}

Fragment BaseFlowGraphBuilder::AllocateContext(intptr_t size) {
  AllocateContextInstr* allocate =
      new (Z) AllocateContextInstr(TokenPosition::kNoSource, size);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::CreateArray() {
  Value* element_count = Pop();
  CreateArrayInstr* array =
      new (Z) CreateArrayInstr(TokenPosition::kNoSource,
                               Pop(),  // Element type.
                               element_count, GetNextDeoptId());
  Push(array);
  return Fragment(array);
}

Fragment BaseFlowGraphBuilder::InstantiateType(const AbstractType& type) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  InstantiateTypeInstr* instr = new (Z) InstantiateTypeInstr(
      TokenPosition::kNoSource, type, instantiator_type_args,
      function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::InstantiateTypeArguments(
    const TypeArguments& type_arguments) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  const Class& instantiator_class = Class::ZoneHandle(Z, function_.Owner());
  InstantiateTypeArgumentsInstr* instr = new (Z) InstantiateTypeArgumentsInstr(
      TokenPosition::kNoSource, type_arguments, instantiator_class,
      instantiator_type_args, function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
