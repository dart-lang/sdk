// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/base_flow_graph_builder.h"

#include "vm/compiler/frontend/flow_graph_builder.h"  // For InlineExitCollector.
#include "vm/compiler/jit/compiler.h"  // For Compiler::IsBackgroundCompilation().
#include "vm/compiler/runtime_api.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"

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
    instructions += LoadNativeField(Slot::Context_parent());
  }
  return instructions;
}

Fragment BaseFlowGraphBuilder::StrictCompare(TokenPosition position,
                                             Token::Kind kind,
                                             bool number_check /* = false */) {
  Value* right = Pop();
  Value* left = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      position, kind, left, right, number_check, GetNextDeoptId());
  Push(compare);
  return Fragment(compare);
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

Fragment BaseFlowGraphBuilder::CheckStackOverflow(TokenPosition position,
                                                  intptr_t stack_depth,
                                                  intptr_t loop_depth) {
  return Fragment(new (Z) CheckStackOverflowInstr(
      position, stack_depth, loop_depth, GetNextDeoptId(),
      CheckStackOverflowInstr::kOsrAndPreemption));
}

Fragment BaseFlowGraphBuilder::CheckStackOverflowInPrologue(
    TokenPosition position) {
  if (IsInlining()) {
    // If we are inlining don't actually attach the stack check.  We must still
    // create the stack check in order to allocate a deopt id.
    CheckStackOverflow(position, 0, 0);
    return Fragment();
  }
  return CheckStackOverflow(position, 0, 0);
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
  test += LoadNativeField(Slot::ArgumentsDescriptor_type_args_len());
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
  test += LoadNativeField(Slot::Closure_delayed_type_arguments());
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
    LocalVariable* closure = parsed_function_->ParameterVariable(0);

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

Fragment BaseFlowGraphBuilder::LoadIndexed(intptr_t index_scale) {
  Value* index = Pop();
  Value* array = Pop();
  LoadIndexedInstr* instr = new (Z)
      LoadIndexedInstr(array, index, index_scale, kArrayCid, kAlignedAccess,
                       DeoptId::kNone, TokenPosition::kNoSource);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadUntagged(intptr_t offset) {
  Value* object = Pop();
  auto load = new (Z) LoadUntaggedInstr(object, offset);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::StoreUntagged(intptr_t offset) {
  Value* value = Pop();
  Value* object = Pop();
  auto store = new (Z) StoreUntaggedInstr(object, value, offset);
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::ConvertUntaggedToIntptr() {
  Value* value = Pop();
  auto converted = new (Z)
      IntConverterInstr(kUntagged, kUnboxedIntPtr, value, DeoptId::kNone);
  converted->mark_truncating();
  Push(converted);
  return Fragment(converted);
}

Fragment BaseFlowGraphBuilder::ConvertIntptrToUntagged() {
  Value* value = Pop();
  auto converted = new (Z)
      IntConverterInstr(kUnboxedIntPtr, kUntagged, value, DeoptId::kNone);
  converted->mark_truncating();
  Push(converted);
  return Fragment(converted);
}

Fragment BaseFlowGraphBuilder::AddIntptrIntegers() {
  Value* right = Pop();
  Value* left = Pop();
#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_X64)
  auto add = new (Z) BinaryInt64OpInstr(
      Token::kADD, left, right, DeoptId::kNone, Instruction::kNotSpeculative);
#else
  auto add =
      new (Z) BinaryInt32OpInstr(Token::kADD, left, right, DeoptId::kNone);
#endif
  add->mark_truncating();
  Push(add);
  return Fragment(add);
}

Fragment BaseFlowGraphBuilder::UnboxSmiToIntptr() {
  Value* value = Pop();
  auto untagged = new (Z)
      UnboxIntegerInstr(kUnboxedIntPtr, UnboxIntegerInstr::kNoTruncation, value,
                        DeoptId::kNone, Instruction::kNotSpeculative);
  Push(untagged);
  return Fragment(untagged);
}

Fragment BaseFlowGraphBuilder::LoadField(const Field& field) {
  return LoadNativeField(Slot::Get(MayCloneField(field), parsed_function_));
}

Fragment BaseFlowGraphBuilder::LoadNativeField(const Slot& native_field) {
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(Pop(), native_field, TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  ASSERT(!variable->is_captured());
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
    const Slot& field,
    StoreBarrierType emit_store_barrier) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      field, Pop(), value, emit_store_barrier, position);
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

  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      MayCloneField(field), Pop(), value, emit_store_barrier,
      TokenPosition::kNoSource, parsed_function_,
      is_initialization_store ? StoreInstanceFieldInstr::Kind::kInitializing
                              : StoreInstanceFieldInstr::Kind::kOther);

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

    // Field length guard can be omitted if it is not needed.
    // However, it is possible that we were tracking list length previously,
    // and generated length guards in the past. We need to generate same IL
    // to keep deopt ids stable, but we can discard generated IL fragment
    // if length guard is not needed.
    Fragment length_guard;
    length_guard += LoadLocal(store_expression);
    length_guard += GuardFieldLength(field_clone, GetNextDeoptId());

    if (field_clone.needs_length_check()) {
      instructions += length_guard;
    }

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

Fragment BaseFlowGraphBuilder::RedefinitionWithType(const AbstractType& type) {
  auto redefinition = new (Z) RedefinitionInstr(Pop());
  redefinition->set_constrained_type(
      new (Z) CompileType(CompileType::FromAbstractType(type)));
  Push(redefinition);
  return Fragment(redefinition);
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
      index, value, emit_store_barrier,
      compiler::target::Instance::ElementSizeFor(class_id), class_id,
      kAlignedAccess, DeoptId::kNone, TokenPosition::kNoSource);
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
        position, Slot::GetContextVariableSlotFor(thread_, *variable));
    return instructions;
  }
  return StoreLocalRaw(position, variable);
}

Fragment BaseFlowGraphBuilder::StoreLocalRaw(TokenPosition position,
                                             LocalVariable* variable) {
  ASSERT(!variable->is_captured());
  Value* value = Pop();
  StoreLocalInstr* store = new (Z) StoreLocalInstr(*variable, value, position);
  Fragment instructions(store);
  Push(store);
  return instructions;
}

LocalVariable* BaseFlowGraphBuilder::MakeTemporary() {
  char name[64];
  intptr_t index = stack_->definition()->temp_index();
  Utils::SNPrint(name, 64, ":t%" Pd, index);
  const String& symbol_name =
      String::ZoneHandle(Z, Symbols::New(thread_, name));
  LocalVariable* variable =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            symbol_name, Object::dynamic_type());
  // Set the index relative to the base of the expression stack including
  // outgoing arguments.
  variable->set_index(
      VariableIndex(-parsed_function_->num_stack_locals() - index));

  // The value has uses as if it were a local variable.  Mark the definition
  // as used so that its temp index will not be cleared (causing it to never
  // be materialized in the expression stack).
  stack_->definition()->set_ssa_temp_index(0);

  return variable;
}

void BaseFlowGraphBuilder::SetTempIndex(Definition* definition) {
  definition->set_temp_index(
      stack_ == NULL ? 0 : stack_->definition()->temp_index() + 1);
}

void BaseFlowGraphBuilder::Push(Definition* definition) {
  SetTempIndex(definition);
  Value::AddToList(new (Z) Value(definition), &stack_);
}

Definition* BaseFlowGraphBuilder::Peek(intptr_t depth) {
  Value* head = stack_;
  for (intptr_t i = 0; i < depth; ++i) {
    ASSERT(head != nullptr);
    head = head->next_use();
  }
  ASSERT(head != nullptr);
  return head->definition();
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

FunctionEntryInstr* BaseFlowGraphBuilder::BuildFunctionEntry(
    GraphEntryInstr* graph_entry) {
  return new (Z) FunctionEntryInstr(graph_entry, AllocateBlockId(),
                                    CurrentTryIndex(), GetNextDeoptId());
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

Fragment BaseFlowGraphBuilder::LoadFpRelativeSlot(intptr_t offset,
                                                  CompileType result_type) {
  LoadIndexedUnsafeInstr* instr =
      new (Z) LoadIndexedUnsafeInstr(Pop(), offset, result_type);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::StoreFpRelativeSlot(intptr_t offset) {
  Value* value = Pop();
  Value* index = Pop();
  StoreIndexedUnsafeInstr* instr =
      new (Z) StoreIndexedUnsafeInstr(index, value, offset);
  return Fragment(instr);
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildThrowNoSuchMethod() {
  JoinEntryInstr* nsm = BuildJoinEntry();

  Fragment failing(nsm);
  const Code& nsm_handler = StubCode::CallClosureNoSuchMethod();
  failing += LoadArgDescriptor();
  failing += TailCall(nsm_handler);

  return nsm;
}

Fragment BaseFlowGraphBuilder::AssertBool(TokenPosition position) {
  if (!I->should_emit_strong_mode_checks()) {
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

Fragment BaseFlowGraphBuilder::AllocateContext(
    const ZoneGrowableArray<const Slot*>& context_slots) {
  AllocateContextInstr* allocate =
      new (Z) AllocateContextInstr(TokenPosition::kNoSource, context_slots);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::AllocateClosure(
    TokenPosition position,
    const Function& closure_function) {
  const Class& cls = Class::ZoneHandle(Z, I->object_store()->closure_class());
  ArgumentArray arguments = new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, 0);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position, cls, arguments);
  allocate->set_closure_function(closure_function);
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
      TokenPosition::kNoSource, type_arguments, instantiator_class, function_,
      instantiator_type_args, function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadClassId() {
  LoadClassIdInstr* load = new (Z) LoadClassIdInstr(Pop());
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::AllocateObject(TokenPosition position,
                                              const Class& klass,
                                              intptr_t argument_count) {
  ArgumentArray arguments = GetArguments(argument_count);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position, klass, arguments);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::BuildFfiAsFunctionInternalCall(
    const TypeArguments& signatures) {
  ASSERT(signatures.IsInstantiated() && signatures.Length() == 2);

  const AbstractType& dart_type = AbstractType::Handle(signatures.TypeAt(0));
  const AbstractType& native_type = AbstractType::Handle(signatures.TypeAt(1));

  ASSERT(dart_type.IsFunctionType() && native_type.IsFunctionType());
  const Function& target =
      Function::ZoneHandle(compiler::ffi::TrampolineFunction(
          Function::Handle(Z, Type::Cast(dart_type).signature()),
          Function::Handle(Z, Type::Cast(native_type).signature())));

  Fragment code;
  code += LoadNativeField(Slot::Pointer_c_memory_address());
  LocalVariable* address = MakeTemporary();

  auto& context_slots = CompilerState::Current().GetDummyContextSlots(
      /*context_id=*/0, /*num_variables=*/1);
  code += AllocateContext(context_slots);
  LocalVariable* context = MakeTemporary();

  code += LoadLocal(context);
  code += LoadLocal(address);
  code += StoreInstanceField(TokenPosition::kNoSource, *context_slots[0]);

  code += AllocateClosure(TokenPosition::kNoSource, target);
  LocalVariable* closure = MakeTemporary();

  code += LoadLocal(closure);
  code += LoadLocal(context);
  code += StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_context());

  code += LoadLocal(closure);
  code += Constant(target);
  code +=
      StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_function());

  // Drop address and context.
  code += DropTempsPreserveTop(2);

  return code;
}

Fragment BaseFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
#ifdef PRODUCT
  return Fragment();
#else
  return Fragment(new (Z) DebugStepCheckInstr(
      position, RawPcDescriptors::kRuntimeCall, GetNextDeoptId()));
#endif
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
