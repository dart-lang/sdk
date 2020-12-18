// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/base_flow_graph_builder.h"

#include "vm/compiler/backend/range_analysis.h"  // For Range.
#include "vm/compiler/ffi/call.h"
#include "vm/compiler/frontend/flow_graph_builder.h"  // For InlineExitCollector.
#include "vm/compiler/jit/compiler.h"  // For Compiler::IsBackgroundCompilation().
#include "vm/compiler/runtime_api.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"
#include "vm/resolver.h"

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
  StrictCompareInstr* compare =
      new (Z) StrictCompareInstr(InstructionSource(position), kind, left, right,
                                 number_check, GetNextDeoptId());
  Push(compare);
  return Fragment(compare);
}

Fragment BaseFlowGraphBuilder::StrictCompare(Token::Kind kind,
                                             bool number_check /* = false */) {
  Value* right = Pop();
  Value* left = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      InstructionSource(), kind, left, right, number_check, GetNextDeoptId());
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
      InstructionSource(), negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
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
      new (Z) StrictCompareInstr(InstructionSource(), Token::kEQ_STRICT, lhs,
                                 rhs, false, GetNextDeoptId());
  BranchInstr* branch = new (Z) BranchInstr(compare, GetNextDeoptId());
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}

Fragment BaseFlowGraphBuilder::Return(TokenPosition position,
                                      intptr_t yield_index) {
  Fragment instructions;

  Value* value = Pop();
  ASSERT(stack_ == nullptr);
  const Function& function = parsed_function_->function();
  Representation representation;
  if (function.has_unboxed_integer_return()) {
    representation = kUnboxedInt64;
  } else if (function.has_unboxed_double_return()) {
    representation = kUnboxedDouble;
  } else {
    ASSERT(!function.has_unboxed_return());
    representation = kTagged;
  }
  ReturnInstr* return_instr =
      new (Z) ReturnInstr(InstructionSource(position), value, GetNextDeoptId(),
                          yield_index, representation);
  if (exit_collector_ != nullptr) exit_collector_->AddExit(return_instr);

  instructions <<= return_instr;

  return instructions.closed();
}

Fragment BaseFlowGraphBuilder::CheckStackOverflow(TokenPosition position,
                                                  intptr_t stack_depth,
                                                  intptr_t loop_depth) {
  return Fragment(new (Z) CheckStackOverflowInstr(
      InstructionSource(position), stack_depth, loop_depth, GetNextDeoptId(),
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

Fragment BaseFlowGraphBuilder::UnboxedIntConstant(
    int64_t value,
    Representation representation) {
  const auto& obj = Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld));
  auto const constant = new (Z) UnboxedConstantInstr(obj, representation);
  Push(constant);
  return Fragment(constant);
}

Fragment BaseFlowGraphBuilder::MemoryCopy(classid_t src_cid,
                                          classid_t dest_cid) {
  Value* length = Pop();
  Value* dest_start = Pop();
  Value* src_start = Pop();
  Value* dest = Pop();
  Value* src = Pop();
  auto copy = new (Z) MemoryCopyInstr(src, dest, src_start, dest_start, length,
                                      src_cid, dest_cid);
  return Fragment(copy);
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

Fragment BaseFlowGraphBuilder::LoadArgDescriptor() {
  if (has_saved_args_desc_array()) {
    const ArgumentsDescriptor descriptor(saved_args_desc_array());
    // Double-check that compile-time Size() matches runtime size on target.
    ASSERT_EQUAL(descriptor.Size(),
                 FlowGraph::ParameterOffsetAt(function_, descriptor.Count(),
                                              /*last_slot=*/false));
    return Constant(saved_args_desc_array());
  }
  ASSERT(parsed_function_->has_arg_desc_var());
  return LoadLocal(parsed_function_->arg_desc_var());
}

Fragment BaseFlowGraphBuilder::TestTypeArgsLen(Fragment eq_branch,
                                               Fragment neq_branch,
                                               intptr_t num_type_args) {
  Fragment test;

  // Compile-time arguments descriptor case.
  if (has_saved_args_desc_array()) {
    const ArgumentsDescriptor descriptor(saved_args_desc_array_);
    return descriptor.TypeArgsLen() == num_type_args ? eq_branch : neq_branch;
  }

  // Runtime arguments descriptor case.
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

Fragment BaseFlowGraphBuilder::LoadIndexed(classid_t class_id,
                                           intptr_t index_scale,
                                           bool index_unboxed) {
  Value* index = Pop();
  // A C pointer if index_unboxed, otherwise a boxed Dart value.
  Value* array = Pop();

  // We use C behavior when dereferencing pointers, so we use aligned access in
  // all cases.
  LoadIndexedInstr* instr = new (Z)
      LoadIndexedInstr(array, index, index_unboxed, index_scale, class_id,
                       kAlignedAccess, DeoptId::kNone, InstructionSource());
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

Fragment BaseFlowGraphBuilder::ConvertUntaggedToUnboxed(
    Representation to_representation) {
  ASSERT(to_representation == kUnboxedIntPtr ||
         to_representation == kUnboxedFfiIntPtr);
  Value* value = Pop();
  auto converted = new (Z)
      IntConverterInstr(kUntagged, to_representation, value, DeoptId::kNone);
  converted->mark_truncating();
  Push(converted);
  return Fragment(converted);
}

Fragment BaseFlowGraphBuilder::ConvertUnboxedToUntagged(
    Representation from_representation) {
  ASSERT(from_representation == kUnboxedIntPtr ||
         from_representation == kUnboxedFfiIntPtr);
  Value* value = Pop();
  auto converted = new (Z)
      IntConverterInstr(from_representation, kUntagged, value, DeoptId::kNone);
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

Fragment BaseFlowGraphBuilder::FloatToDouble() {
  Value* value = Pop();
  FloatToDoubleInstr* instr = new FloatToDoubleInstr(value, DeoptId::kNone);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::DoubleToFloat() {
  Value* value = Pop();
  DoubleToFloatInstr* instr = new DoubleToFloatInstr(
      value, DeoptId::kNone, Instruction::SpeculativeMode::kNotSpeculative);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadField(const Field& field,
                                         bool calls_initializer) {
  return LoadNativeField(Slot::Get(MayCloneField(Z, field), parsed_function_),
                         calls_initializer);
}

Fragment BaseFlowGraphBuilder::LoadNativeField(const Slot& native_field,
                                               bool calls_initializer) {
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      Pop(), native_field, InstructionSource(), calls_initializer,
      calls_initializer ? GetNextDeoptId() : DeoptId::kNone);
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  ASSERT(!variable->is_captured());
  LoadLocalInstr* load = new (Z) LoadLocalInstr(*variable, InstructionSource());
  Push(load);
  return Fragment(load);
}

Fragment BaseFlowGraphBuilder::NullConstant() {
  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}

Fragment BaseFlowGraphBuilder::GuardFieldLength(const Field& field,
                                                intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldLengthInstr(Pop(), field, deopt_id));
}

Fragment BaseFlowGraphBuilder::GuardFieldClass(const Field& field,
                                               intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldClassInstr(Pop(), field, deopt_id));
}

const Field& BaseFlowGraphBuilder::MayCloneField(Zone* zone,
                                                 const Field& field) {
  if (CompilerState::Current().should_clone_fields() && field.IsOriginal()) {
    return Field::ZoneHandle(zone, field.CloneFromOriginal());
  } else {
    ASSERT(field.IsZoneHandle());
    return field;
  }
}

Fragment BaseFlowGraphBuilder::StoreInstanceField(
    TokenPosition position,
    const Slot& field,
    StoreInstanceFieldInstr::Kind
        kind /* = StoreInstanceFieldInstr::Kind::kOther */,
    StoreBarrierType emit_store_barrier /* = kEmitStoreBarrier */) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }
  StoreInstanceFieldInstr* store =
      new (Z) StoreInstanceFieldInstr(field, Pop(), value, emit_store_barrier,
                                      InstructionSource(position), kind);
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreInstanceField(
    const Field& field,
    StoreInstanceFieldInstr::Kind
        kind /* = StoreInstanceFieldInstr::Kind::kOther */,
    StoreBarrierType emit_store_barrier) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }

  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      MayCloneField(Z, field), Pop(), value, emit_store_barrier,
      InstructionSource(), parsed_function_, kind);

  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreInstanceFieldGuarded(
    const Field& field,
    StoreInstanceFieldInstr::Kind
        kind /* = StoreInstanceFieldInstr::Kind::kOther */) {
  Fragment instructions;
  const Field& field_clone = MayCloneField(Z, field);
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
  instructions += StoreInstanceField(field_clone, kind);
  return instructions;
}

Fragment BaseFlowGraphBuilder::LoadStaticField(const Field& field,
                                               bool calls_initializer) {
  LoadStaticFieldInstr* load = new (Z) LoadStaticFieldInstr(
      field, InstructionSource(), calls_initializer,
      calls_initializer ? GetNextDeoptId() : DeoptId::kNone);
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

Fragment BaseFlowGraphBuilder::ReachabilityFence() {
  Fragment instructions;
  instructions <<= new (Z) ReachabilityFenceInstr(Pop());
  return instructions;
}

Fragment BaseFlowGraphBuilder::Utf8Scan() {
  Value* table = Pop();
  Value* end = Pop();
  Value* start = Pop();
  Value* bytes = Pop();
  Value* decoder = Pop();
  const Field& scan_flags_field =
      compiler::LookupConvertUtf8DecoderScanFlagsField();
  auto scan = new (Z) Utf8ScanInstr(
      decoder, bytes, start, end, table,
      Slot::Get(MayCloneField(Z, scan_flags_field), parsed_function_));
  Push(scan);
  return Fragment(scan);
}

Fragment BaseFlowGraphBuilder::StoreStaticField(TokenPosition position,
                                                const Field& field) {
  return Fragment(new (Z) StoreStaticFieldInstr(MayCloneField(Z, field), Pop(),
                                                InstructionSource(position)));
}

Fragment BaseFlowGraphBuilder::StoreIndexed(classid_t class_id) {
  Value* value = Pop();
  Value* index = Pop();
  const StoreBarrierType emit_store_barrier =
      value->BindsToConstant() ? kNoStoreBarrier : kEmitStoreBarrier;
  StoreIndexedInstr* store = new (Z) StoreIndexedInstr(
      Pop(),  // Array.
      index, value, emit_store_barrier, /*index_unboxed=*/false,

      compiler::target::Instance::ElementSizeFor(class_id), class_id,
      kAlignedAccess, DeoptId::kNone, InstructionSource());
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreIndexedTypedData(classid_t class_id,
                                                     intptr_t index_scale,
                                                     bool index_unboxed) {
  // We use C behavior when dereferencing pointers, we assume alignment.
  const AlignmentType alignment = kAlignedAccess;

  Value* value = Pop();
  Value* index = Pop();
  Value* c_pointer = Pop();
  StoreIndexedInstr* instr = new (Z) StoreIndexedInstr(
      c_pointer, index, value, kNoStoreBarrier, index_unboxed, index_scale,
      class_id, alignment, DeoptId::kNone, InstructionSource(),
      Instruction::SpeculativeMode::kNotSpeculative);
  return Fragment(instr);
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
  StoreLocalInstr* store =
      new (Z) StoreLocalInstr(*variable, value, InstructionSource(position));
  Fragment instructions(store);
  Push(store);
  return instructions;
}

LocalVariable* BaseFlowGraphBuilder::MakeTemporary(const char* suffix) {
  static constexpr intptr_t kTemporaryNameLength = 64;
  char name[kTemporaryNameLength];
  intptr_t index = stack_->definition()->temp_index();
  if (suffix != nullptr) {
    Utils::SNPrint(name, kTemporaryNameLength, ":t_%s", suffix);
  } else {
    Utils::SNPrint(name, kTemporaryNameLength, ":t%" Pd, index);
  }
  const String& symbol_name =
      String::ZoneHandle(Z, Symbols::New(thread_, name));
  LocalVariable* variable =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            symbol_name, Object::dynamic_type());
  // Set the index relative to the base of the expression stack including
  // outgoing arguments.
  variable->set_index(
      VariableIndex(-parsed_function_->num_stack_locals() - index));

  // The value on top of the stack has uses as if it were a local variable.
  // Mark all definitions on the stack as used so that their temp indices
  // will not be cleared (causing them to never be materialized in the
  // expression stack and skew stack depth).
  for (Value* item = stack_; item != nullptr; item = item->next_use()) {
    item->definition()->set_ssa_temp_index(0);
  }

  return variable;
}

Fragment BaseFlowGraphBuilder::DropTemporary(LocalVariable** temp) {
  ASSERT(temp != nullptr && *temp != nullptr && (*temp)->HasIndex());
  // Check that the temporary matches the current stack definition.
  ASSERT_EQUAL(
      stack_->definition()->temp_index(),
      -(*temp)->index().value() - parsed_function_->num_stack_locals());
  *temp = nullptr;  // Clear to avoid inadvertent usage after dropping.
  return Drop();
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
  return new (Z) TargetEntryInstr(AllocateBlockId(), CurrentTryIndex(),
                                  GetNextDeoptId(), GetStackDepth());
}

FunctionEntryInstr* BaseFlowGraphBuilder::BuildFunctionEntry(
    GraphEntryInstr* graph_entry) {
  return new (Z) FunctionEntryInstr(graph_entry, AllocateBlockId(),
                                    CurrentTryIndex(), GetNextDeoptId());
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildJoinEntry(intptr_t try_index) {
  return new (Z) JoinEntryInstr(AllocateBlockId(), try_index, GetNextDeoptId(),
                                GetStackDepth());
}

JoinEntryInstr* BaseFlowGraphBuilder::BuildJoinEntry() {
  return new (Z) JoinEntryInstr(AllocateBlockId(), CurrentTryIndex(),
                                GetNextDeoptId(), GetStackDepth());
}

IndirectEntryInstr* BaseFlowGraphBuilder::BuildIndirectEntry(
    intptr_t indirect_id,
    intptr_t try_index) {
  return new (Z) IndirectEntryInstr(AllocateBlockId(), indirect_id, try_index,
                                    GetNextDeoptId());
}

InputsArray* BaseFlowGraphBuilder::GetArguments(int count) {
  InputsArray* arguments = new (Z) ZoneGrowableArray<Value*>(Z, count);
  arguments->SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    arguments->data()[i] = Pop();
  }
  return arguments;
}

Fragment BaseFlowGraphBuilder::SmiRelationalOp(Token::Kind kind) {
  Value* right = Pop();
  Value* left = Pop();
  RelationalOpInstr* instr = new (Z) RelationalOpInstr(
      InstructionSource(), kind, left, right, kSmiCid, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::SmiBinaryOp(Token::Kind kind,
                                           bool is_truncating) {
  return BinaryIntegerOp(kind, kTagged, is_truncating);
}

Fragment BaseFlowGraphBuilder::BinaryIntegerOp(Token::Kind kind,
                                               Representation representation,
                                               bool is_truncating) {
  ASSERT(representation == kUnboxedInt32 || representation == kUnboxedUint32 ||
         representation == kUnboxedInt64 || representation == kTagged);
  Value* right = Pop();
  Value* left = Pop();
  BinaryIntegerOpInstr* instr = BinaryIntegerOpInstr::Make(
      representation, kind, left, right, GetNextDeoptId());
  ASSERT(instr != nullptr);
  if (is_truncating) {
    instr->mark_truncating();
  }
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadFpRelativeSlot(
    intptr_t offset,
    CompileType result_type,
    Representation representation) {
  LoadIndexedUnsafeInstr* instr = new (Z)
      LoadIndexedUnsafeInstr(Pop(), offset, result_type, representation);
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
  const Code& nsm_handler = Code::ZoneHandle(
      Z, I->object_store()->call_closure_no_such_method_stub());
  failing += LoadArgDescriptor();
  failing += TailCall(nsm_handler);

  return nsm;
}

Fragment BaseFlowGraphBuilder::AssertBool(TokenPosition position) {
  Value* value = Pop();
  AssertBooleanInstr* instr = new (Z)
      AssertBooleanInstr(InstructionSource(position), value, GetNextDeoptId());
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
      new (Z) AllocateContextInstr(InstructionSource(), context_slots);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::AllocateClosure(
    TokenPosition position,
    const Function& closure_function) {
  const Class& cls = Class::ZoneHandle(Z, I->object_store()->closure_class());
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(InstructionSource(position), cls);
  allocate->set_closure_function(closure_function);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::CreateArray() {
  Value* element_count = Pop();
  CreateArrayInstr* array =
      new (Z) CreateArrayInstr(InstructionSource(),
                               Pop(),  // Element type.
                               element_count, GetNextDeoptId());
  Push(array);
  return Fragment(array);
}

Fragment BaseFlowGraphBuilder::AllocateTypedData(TokenPosition position,
                                                 classid_t class_id) {
  Value* num_elements = Pop();
  auto* instr = new (Z) AllocateTypedDataInstr(
      InstructionSource(position), class_id, num_elements, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::InstantiateType(const AbstractType& type) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  InstantiateTypeInstr* instr = new (Z)
      InstantiateTypeInstr(InstructionSource(), type, instantiator_type_args,
                           function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::InstantiateTypeArguments(
    const TypeArguments& type_arguments_value) {
  Fragment instructions;
  instructions += Constant(type_arguments_value);

  Value* type_arguments = Pop();
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  const Class& instantiator_class = Class::ZoneHandle(Z, function_.Owner());
  InstantiateTypeArgumentsInstr* instr = new (Z) InstantiateTypeArgumentsInstr(
      InstructionSource(), instantiator_type_args, function_type_args,
      type_arguments, instantiator_class, function_, GetNextDeoptId());
  Push(instr);
  instructions += Fragment(instr);
  return instructions;
}

Fragment BaseFlowGraphBuilder::InstantiateDynamicTypeArguments() {
  Value* type_arguments = Pop();
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  const Function& function = Object::null_function();
  const Class& instantiator_class = Class::ZoneHandle(Z);
  InstantiateTypeArgumentsInstr* instr = new (Z) InstantiateTypeArgumentsInstr(
      InstructionSource(), instantiator_type_args, function_type_args,
      type_arguments, instantiator_class, function, GetNextDeoptId());
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
  ASSERT((argument_count == 0) || (argument_count == 1));
  Value* type_arguments = (argument_count > 0) ? Pop() : nullptr;
  AllocateObjectInstr* allocate = new (Z)
      AllocateObjectInstr(InstructionSource(position), klass, type_arguments);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::Box(Representation from) {
  BoxInstr* box = BoxInstr::Create(from, Pop());
  Push(box);
  return Fragment(box);
}

Fragment BaseFlowGraphBuilder::BuildFfiAsFunctionInternalCall(
    const TypeArguments& signatures) {
  ASSERT(signatures.IsInstantiated());
  ASSERT(signatures.Length() == 2);

  const AbstractType& dart_type = AbstractType::Handle(signatures.TypeAt(0));
  const AbstractType& native_type = AbstractType::Handle(signatures.TypeAt(1));

  ASSERT(dart_type.IsFunctionType() && native_type.IsFunctionType());
  const Function& target =
      Function::ZoneHandle(compiler::ffi::TrampolineFunction(
          Function::Handle(Z, Type::Cast(dart_type).signature()),
          Function::Handle(Z, Type::Cast(native_type).signature())));

  Fragment code;
  // Store the pointer in the context, we cannot load the untagged address
  // here as these can be unoptimized call sites.
  LocalVariable* pointer = MakeTemporary();

  auto& context_slots = CompilerState::Current().GetDummyContextSlots(
      /*context_id=*/0, /*num_variables=*/1);
  code += AllocateContext(context_slots);
  LocalVariable* context = MakeTemporary();

  code += LoadLocal(context);
  code += LoadLocal(pointer);
  code += StoreInstanceField(TokenPosition::kNoSource, *context_slots[0]);

  code += AllocateClosure(TokenPosition::kNoSource, target);
  LocalVariable* closure = MakeTemporary();

  code += LoadLocal(closure);
  code += LoadLocal(context);
  code += StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_context(),
                             StoreInstanceFieldInstr::Kind::kInitializing);

  code += LoadLocal(closure);
  code += Constant(target);
  code += StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_function(),
                             StoreInstanceFieldInstr::Kind::kInitializing);

  // Drop address and context.
  code += DropTempsPreserveTop(2);

  return code;
}

Fragment BaseFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
#ifdef PRODUCT
  return Fragment();
#else
  return Fragment(new (Z) DebugStepCheckInstr(InstructionSource(position),
                                              PcDescriptorsLayout::kRuntimeCall,
                                              GetNextDeoptId()));
#endif
}

Fragment BaseFlowGraphBuilder::CheckNull(TokenPosition position,
                                         LocalVariable* receiver,
                                         const String& function_name,
                                         bool clear_the_temp /* = true */) {
  Fragment instructions = LoadLocal(receiver);

  CheckNullInstr* check_null = new (Z) CheckNullInstr(
      Pop(), function_name, GetNextDeoptId(), InstructionSource(position),
      function_name.IsNull() ? CheckNullInstr::kCastError
                             : CheckNullInstr::kNoSuchMethod);

  // Does not use the redefinition, no `Push(check_null)`.
  instructions <<= check_null;

  if (clear_the_temp) {
    // Null out receiver to make sure it is not saved into the frame before
    // doing the call.
    instructions += NullConstant();
    instructions += StoreLocal(TokenPosition::kNoSource, receiver);
    instructions += Drop();
  }

  return instructions;
}

Fragment BaseFlowGraphBuilder::CheckNullOptimized(TokenPosition position,
                                                  const String& function_name) {
  Value* value = Pop();
  CheckNullInstr* check_null = new (Z) CheckNullInstr(
      value, function_name, GetNextDeoptId(), InstructionSource(position));
  Push(check_null);  // Use the redefinition.
  return Fragment(check_null);
}

void BaseFlowGraphBuilder::RecordUncheckedEntryPoint(
    GraphEntryInstr* graph_entry,
    FunctionEntryInstr* unchecked_entry) {
  // Closures always check all arguments on their checked entry-point, most
  // call-sites are unchecked, and they're inlined less often, so it's very
  // beneficial to build multiple entry-points for them. Regular methods however
  // have fewer checks to begin with since they have dynamic invocation
  // forwarders, so in AOT we implement a more conservative time-space tradeoff
  // by only building the unchecked entry-point when inlining. We should
  // reconsider this heuristic if we identify non-inlined type-checks in
  // hotspots of new benchmarks.
  if (!IsInlining() && (parsed_function_->function().IsClosureFunction() ||
                        !CompilerState::Current().is_aot())) {
    graph_entry->set_unchecked_entry(unchecked_entry);
  } else if (InliningUncheckedEntry()) {
    graph_entry->set_normal_entry(unchecked_entry);
  }
}

Fragment BaseFlowGraphBuilder::BuildEntryPointsIntrospection() {
  if (!FLAG_enable_testing_pragmas) return Drop();

  auto& function = Function::Handle(Z, parsed_function_->function().raw());

  if (function.IsImplicitClosureFunction()) {
    const auto& parent = Function::Handle(Z, function.parent_function());
    const auto& func_name = String::Handle(Z, parent.name());
    const auto& owner = Class::Handle(Z, parent.Owner());
    if (owner.EnsureIsFinalized(thread_) == Error::null()) {
      function = Resolver::ResolveFunction(Z, owner, func_name);
    }
  }

  Object& options = Object::Handle(Z);
  if (!Library::FindPragma(thread_, /*only_core=*/false, function,
                           Symbols::vm_trace_entrypoints(), &options) ||
      options.IsNull() || !options.IsClosure()) {
    return Drop();
  }
  auto& closure = Closure::ZoneHandle(Z, Closure::Cast(options).raw());
  LocalVariable* entry_point_num = MakeTemporary();

  auto& function_name = String::ZoneHandle(
      Z, String::New(function.ToLibNamePrefixedQualifiedCString(), Heap::kOld));
  if (parsed_function_->function().IsImplicitClosureFunction()) {
    function_name = String::Concat(
        function_name, String::Handle(Z, String::New("#tearoff", Heap::kNew)),
        Heap::kOld);
  }
  if (!function_name.IsCanonical()) {
    function_name = Symbols::New(thread_, function_name);
  }

  Fragment call_hook;
  call_hook += Constant(closure);
  call_hook += Constant(function_name);
  call_hook += LoadLocal(entry_point_num);
  call_hook += Constant(Function::ZoneHandle(Z, closure.function()));
  call_hook += ClosureCall(TokenPosition::kNoSource,
                           /*type_args_len=*/0, /*argument_count=*/3,
                           /*argument_names=*/Array::ZoneHandle(Z));
  call_hook += Drop();  // result of closure call
  call_hook += Drop();  // entrypoint number
  return call_hook;
}

Fragment BaseFlowGraphBuilder::ClosureCall(TokenPosition position,
                                           intptr_t type_args_len,
                                           intptr_t argument_count,
                                           const Array& argument_names,
                                           bool is_statically_checked) {
  const intptr_t total_count = argument_count + (type_args_len > 0 ? 1 : 0) + 1;
  InputsArray* arguments = GetArguments(total_count);
  ClosureCallInstr* call = new (Z)
      ClosureCallInstr(arguments, type_args_len, argument_names,
                       InstructionSource(position), GetNextDeoptId(),
                       is_statically_checked ? Code::EntryKind::kUnchecked
                                             : Code::EntryKind::kNormal);
  Push(call);
  return Fragment(call);
}

Fragment BaseFlowGraphBuilder::StringInterpolate(TokenPosition position) {
  Value* array = Pop();
  StringInterpolateInstr* interpolate = new (Z) StringInterpolateInstr(
      array, InstructionSource(position), GetNextDeoptId());
  Push(interpolate);
  return Fragment(interpolate);
}

void BaseFlowGraphBuilder::reset_context_depth_for_deopt_id(intptr_t deopt_id) {
  if (is_recording_context_levels()) {
    for (intptr_t i = 0, n = context_level_array_->length(); i < n; i += 2) {
      if (context_level_array_->At(i) == deopt_id) {
        (*context_level_array_)[i + 1] = context_depth_;
        return;
      }
      ASSERT(context_level_array_->At(i) < deopt_id);
    }
  }
}

Fragment BaseFlowGraphBuilder::AssertAssignable(
    TokenPosition position,
    const String& dst_name,
    AssertAssignableInstr::Kind kind) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  Value* dst_type = Pop();
  Value* value = Pop();

  AssertAssignableInstr* instr = new (Z) AssertAssignableInstr(
      InstructionSource(position), value, dst_type, instantiator_type_args,
      function_type_args, dst_name, GetNextDeoptId(), kind);
  Push(instr);

  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::InitConstantParameters() {
  Fragment instructions;
  const intptr_t parameter_count = parsed_function_->function().NumParameters();
  for (intptr_t i = 0; i < parameter_count; ++i) {
    LocalVariable* raw_parameter = parsed_function_->RawParameterVariable(i);
    const Object* param_value = raw_parameter->parameter_value();
    if (param_value != nullptr) {
      instructions += Constant(*param_value);
      instructions += StoreLocalRaw(TokenPosition::kNoSource, raw_parameter);
      instructions += Drop();
    }
  }
  return instructions;
}

}  // namespace kernel
}  // namespace dart
