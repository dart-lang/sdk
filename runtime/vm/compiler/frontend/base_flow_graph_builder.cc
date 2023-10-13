// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/base_flow_graph_builder.h"

#include <utility>

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
#define IG (thread_->isolate_group())

static bool SupportsCoverage() {
#if defined(PRODUCT)
  return false;
#else
  return !CompilerState::Current().is_aot();
#endif
}

Fragment& Fragment::operator+=(const Fragment& other) {
  ASSERT(is_valid());
  ASSERT(other.is_valid());
  if (entry == nullptr) {
    entry = other.entry;
    current = other.current;
  } else if (other.entry != nullptr) {
    if (current != nullptr) {
      current->LinkTo(other.entry);
    }
    // Although [other.entry] could be unreachable (if this fragment is
    // closed), there could be a yield continuation point in the middle of
    // [other] fragment so [other.current] is still reachable.
    current = other.current;
  }
  return *this;
}

Fragment& Fragment::operator<<=(Instruction* next) {
  ASSERT(is_valid());
  if (entry == nullptr) {
    entry = current = next;
  } else if (current != nullptr) {
    current->LinkTo(next);
    current = next;
  }
  return *this;
}

void Fragment::Prepend(Instruction* start) {
  ASSERT(is_valid());
  if (entry == nullptr) {
    entry = current = start;
  } else {
    start->LinkTo(entry);
    entry = start;
  }
}

Fragment Fragment::closed() {
  ASSERT(entry != nullptr);
  return Fragment(entry, nullptr);
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

Fragment BaseFlowGraphBuilder::Return(TokenPosition position) {
  Fragment instructions;

  Value* value = Pop();
  ASSERT(stack_ == nullptr);
  const Function& function = parsed_function_->function();
  const Representation representation =
      FlowGraph::ReturnRepresentationOf(function);
  ReturnInstr* return_instr = new (Z) ReturnInstr(
      InstructionSource(position), value, GetNextDeoptId(), representation);
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
  DEBUG_ASSERT(value.IsNotTemporaryScopedHandle());
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
                                          classid_t dest_cid,
                                          bool unboxed_inputs,
                                          bool can_overlap) {
  Value* length = Pop();
  Value* dest_start = Pop();
  Value* src_start = Pop();
  Value* dest = Pop();
  Value* src = Pop();
  auto copy =
      new (Z) MemoryCopyInstr(src, src_cid, dest, dest_cid, src_start,
                              dest_start, length, unboxed_inputs, can_overlap);
  return Fragment(copy);
}

Fragment BaseFlowGraphBuilder::MemoryCopyUntagged(intptr_t element_size,
                                                  bool unboxed_inputs,
                                                  bool can_overlap) {
  Value* length = Pop();
  Value* dest_start = Pop();
  Value* src_start = Pop();
  Value* dest = Pop();
  Value* src = Pop();
  auto copy =
      new (Z) MemoryCopyInstr(element_size, src, dest, src_start, dest_start,
                              length, unboxed_inputs, can_overlap);
  return Fragment(copy);
}

Fragment BaseFlowGraphBuilder::TailCall(const Code& code) {
  Value* arg_desc = Pop();
  return Fragment(new (Z) TailCallInstr(code, arg_desc)).closed();
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
                                           bool index_unboxed,
                                           AlignmentType alignment) {
  Value* index = Pop();
  // A C pointer if index_unboxed, otherwise a boxed Dart value.
  Value* array = Pop();

  // We use C behavior when dereferencing pointers, so we use aligned access in
  // all cases.
  LoadIndexedInstr* instr = new (Z)
      LoadIndexedInstr(array, index, index_unboxed, index_scale, class_id,
                       alignment, DeoptId::kNone, InstructionSource());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::LoadUntagged(intptr_t offset) {
  Value* object = Pop();
  auto load = new (Z) LoadUntaggedInstr(object, offset);
  Push(load);
  return Fragment(load);
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

Fragment BaseFlowGraphBuilder::LoadNativeField(
    const Slot& native_field,
    InnerPointerAccess loads_inner_pointer,
    bool calls_initializer) {
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      Pop(), native_field, loads_inner_pointer, InstructionSource(),
      calls_initializer, calls_initializer ? GetNextDeoptId() : DeoptId::kNone);
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
    DEBUG_ASSERT(field.IsNotTemporaryScopedHandle());
    return field;
  }
}

Fragment BaseFlowGraphBuilder::StoreNativeField(
    TokenPosition position,
    const Slot& slot,
    InnerPointerAccess stores_inner_pointer,
    StoreFieldInstr::Kind kind /* = StoreFieldInstr::Kind::kOther */,
    StoreBarrierType emit_store_barrier /* = kEmitStoreBarrier */,
    compiler::Assembler::MemoryOrder memory_order /* = kRelaxed */) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }
  StoreFieldInstr* store = new (Z)
      StoreFieldInstr(slot, Pop(), value, emit_store_barrier,
                      stores_inner_pointer, InstructionSource(position), kind);
  return Fragment(store);
}

Fragment BaseFlowGraphBuilder::StoreField(
    const Field& field,
    StoreFieldInstr::Kind kind /* = StoreFieldInstr::Kind::kOther */,
    StoreBarrierType emit_store_barrier) {
  return StoreNativeField(TokenPosition::kNoSource,
                          Slot::Get(MayCloneField(Z, field), parsed_function_),
                          kind, emit_store_barrier);
}

Fragment BaseFlowGraphBuilder::StoreFieldGuarded(
    const Field& field,
    StoreFieldInstr::Kind kind /* = StoreFieldInstr::Kind::kOther */) {
  Fragment instructions;
  const Field& field_clone = MayCloneField(Z, field);
  if (IG->use_field_guards()) {
    LocalVariable* store_expression = MakeTemporary();

    // Note: unboxing decision can only change due to hot reload at which
    // point all code will be cleared, so there is no need to worry about
    // stability of deopt id numbering.
    if (!field_clone.is_unboxed()) {
      instructions += LoadLocal(store_expression);
      instructions += GuardFieldClass(field_clone, GetNextDeoptId());
    }

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
  instructions +=
      StoreNativeField(Slot::Get(field_clone, parsed_function_), kind);
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
      new (Z) CompileType(CompileType::FromAbstractType(
          type, CompileType::kCanBeNull, CompileType::kCannotBeSentinel)));
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
                                                     bool index_unboxed,
                                                     AlignmentType alignment) {
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
    instructions += StoreNativeField(
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
      stack_ == nullptr ? 0 : stack_->definition()->temp_index() + 1);
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
  ASSERT(stack_ != nullptr);
  Value* value = stack_;
  stack_ = value->next_use();
  if (stack_ != nullptr) stack_->set_previous_use(nullptr);

  value->set_next_use(nullptr);
  value->set_previous_use(nullptr);
  value->definition()->ClearSSATempIndex();
  return value;
}

Fragment BaseFlowGraphBuilder::Drop() {
  ASSERT(stack_ != nullptr);
  Fragment instructions;
  Definition* definition = stack_->definition();
  // The SSA renaming implementation doesn't like [LoadLocal]s without a
  // tempindex.
  if (definition->HasSSATemp() || definition->IsLoadLocal()) {
    instructions <<= new (Z) DropTempsInstr(1, nullptr);
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

InputsArray BaseFlowGraphBuilder::GetArguments(int count) {
  InputsArray arguments(Z, count);
  arguments.SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    arguments[i] = Pop();
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
      Z, IG->object_store()->call_closure_no_such_method_stub());
  failing += LoadArgDescriptor();
  failing += TailCall(nsm_handler);

  return nsm;
}

Fragment BaseFlowGraphBuilder::ThrowException(TokenPosition position) {
  Fragment instructions;
  Value* exception = Pop();
  instructions += Fragment(new (Z) ThrowInstr(InstructionSource(position),
                                              GetNextDeoptId(), exception))
                      .closed();
  // Use its side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  return instructions;
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
  AllocateContextInstr* allocate = new (Z) AllocateContextInstr(
      InstructionSource(), context_slots, GetNextDeoptId());
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::AllocateClosure(TokenPosition position) {
  auto const context = Pop();
  auto const function = Pop();
  auto* allocate = new (Z) AllocateClosureInstr(
      InstructionSource(position), function, context, GetNextDeoptId());
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

Fragment BaseFlowGraphBuilder::AllocateRecord(TokenPosition position,
                                              RecordShape shape) {
  AllocateRecordInstr* allocate = new (Z)
      AllocateRecordInstr(InstructionSource(position), shape, GetNextDeoptId());
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::AllocateSmallRecord(TokenPosition position,
                                                   RecordShape shape) {
  const intptr_t num_fields = shape.num_fields();
  ASSERT(num_fields == 2 || num_fields == 3);
  Value* value2 = (num_fields > 2) ? Pop() : nullptr;
  Value* value1 = Pop();
  Value* value0 = Pop();
  AllocateSmallRecordInstr* allocate = new (Z)
      AllocateSmallRecordInstr(InstructionSource(position), shape, value0,
                               value1, value2, GetNextDeoptId());
  Push(allocate);
  return Fragment(allocate);
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
  AllocateObjectInstr* allocate = new (Z) AllocateObjectInstr(
      InstructionSource(position), klass, GetNextDeoptId(), type_arguments);
  Push(allocate);
  return Fragment(allocate);
}

Fragment BaseFlowGraphBuilder::Box(Representation from) {
  BoxInstr* box = BoxInstr::Create(from, Pop());
  Push(box);
  return Fragment(box);
}

Fragment BaseFlowGraphBuilder::BuildFfiAsFunctionInternalCall(
    const TypeArguments& signatures,
    bool is_leaf) {
  ASSERT(signatures.IsInstantiated());
  ASSERT(signatures.Length() == 2);

  const auto& dart_type =
      FunctionType::Cast(AbstractType::Handle(signatures.TypeAt(0)));
  const auto& native_type =
      FunctionType::Cast(AbstractType::Handle(signatures.TypeAt(1)));

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  compiler::ffi::NativeFunctionTypeFromFunctionType(zone_, native_type, &error);
  if (error != nullptr) {
    const auto& language_error = Error::Handle(
        LanguageError::New(String::Handle(String::New(error, Heap::kOld)),
                           Report::kError, Heap::kOld));
    Report::LongJump(language_error);
  }

  const auto& name =
      String::Handle(parsed_function_->function().UserVisibleName());
  const Function& target = Function::ZoneHandle(
      compiler::ffi::TrampolineFunction(dart_type, native_type, is_leaf, name));

  Fragment code;
  // Store the pointer in the context, we cannot load the untagged address
  // here as these can be unoptimized call sites.
  LocalVariable* pointer = MakeTemporary();

  code += Constant(target);

  auto& context_slots = CompilerState::Current().GetDummyContextSlots(
      /*context_id=*/0, /*num_variables=*/1);
  code += AllocateContext(context_slots);
  LocalVariable* context = MakeTemporary();

  code += LoadLocal(context);
  code += LoadLocal(pointer);
  code += StoreNativeField(*context_slots[0]);

  code += AllocateClosure();

  // Drop address.
  code += DropTempsPreserveTop(1);

  return code;
}

Fragment BaseFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
#ifdef PRODUCT
  return Fragment();
#else
  return Fragment(new (Z) DebugStepCheckInstr(
      InstructionSource(position), UntaggedPcDescriptors::kRuntimeCall,
      GetNextDeoptId()));
#endif
}

Fragment BaseFlowGraphBuilder::CheckNull(TokenPosition position,
                                         LocalVariable* receiver,
                                         const String& function_name) {
  Fragment instructions = LoadLocal(receiver);

  CheckNullInstr* check_null = new (Z) CheckNullInstr(
      Pop(), function_name, GetNextDeoptId(), InstructionSource(position),
      function_name.IsNull() ? CheckNullInstr::kCastError
                             : CheckNullInstr::kNoSuchMethod);

  // Does not use the redefinition, no `Push(check_null)`.
  instructions <<= check_null;

  return instructions;
}

Fragment BaseFlowGraphBuilder::CheckNullOptimized(
    const String& function_name,
    CheckNullInstr::ExceptionType exception_type,
    TokenPosition position) {
  Value* value = Pop();
  CheckNullInstr* check_null =
      new (Z) CheckNullInstr(value, function_name, GetNextDeoptId(),
                             InstructionSource(position), exception_type);
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

  auto& function = Function::Handle(Z, parsed_function_->function().ptr());

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
                           Symbols::vm_trace_entrypoints(), /*multiple=*/false,
                           &options) ||
      options.IsNull() || !options.IsClosure()) {
    return Drop();
  }
  auto& closure = Closure::ZoneHandle(Z, Closure::Cast(options).ptr());
  LocalVariable* entry_point_num = MakeTemporary("entry_point_num");

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
  if (FLAG_precompiled_mode) {
    call_hook += Constant(closure);
  } else {
    call_hook += Constant(Function::ZoneHandle(Z, closure.function()));
  }
  call_hook += ClosureCall(Function::null_function(), TokenPosition::kNoSource,
                           /*type_args_len=*/0, /*argument_count=*/3,
                           /*argument_names=*/Array::ZoneHandle(Z));
  call_hook += Drop();                           // result of closure call
  call_hook += DropTemporary(&entry_point_num);  // entrypoint number
  return call_hook;
}

Fragment BaseFlowGraphBuilder::ClosureCall(const Function& target_function,
                                           TokenPosition position,
                                           intptr_t type_args_len,
                                           intptr_t argument_count,
                                           const Array& argument_names) {
  Fragment result = RecordCoverage(position);
  const intptr_t total_count =
      (type_args_len > 0 ? 1 : 0) + argument_count +
      /*closure (bare instructions) or function (otherwise)*/ 1;
  InputsArray arguments = GetArguments(total_count);
  ClosureCallInstr* call = new (Z) ClosureCallInstr(
      target_function, std::move(arguments), type_args_len, argument_names,
      InstructionSource(position), GetNextDeoptId());
  Push(call);
  result <<= call;
  return result;
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
    const Object* param_value = raw_parameter->inferred_arg_value();
    if (param_value != nullptr) {
      instructions += Constant(*param_value);
      instructions += StoreLocalRaw(TokenPosition::kNoSource, raw_parameter);
      instructions += Drop();
    }
  }
  return instructions;
}

Fragment BaseFlowGraphBuilder::InvokeMathCFunction(
    MethodRecognizer::Kind recognized_kind,
    intptr_t num_inputs) {
  InputsArray args = GetArguments(num_inputs);
  auto* instr = new (Z) InvokeMathCFunctionInstr(
      std::move(args), GetNextDeoptId(), recognized_kind,
      InstructionSource(TokenPosition::kNoSource));
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::DoubleToInteger(
    MethodRecognizer::Kind recognized_kind) {
  Value* value = Pop();
  auto* instr =
      new (Z) DoubleToIntegerInstr(value, recognized_kind, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::UnaryDoubleOp(Token::Kind op) {
  Value* value = Pop();
  auto* instr = new (Z) UnaryDoubleOpInstr(op, value, GetNextDeoptId(),
                                           Instruction::kNotSpeculative);
  Push(instr);
  return Fragment(instr);
}

Fragment BaseFlowGraphBuilder::RecordCoverage(TokenPosition position) {
  return RecordCoverageImpl(position, false /** is_branch_coverage **/);
}

Fragment BaseFlowGraphBuilder::RecordBranchCoverage(TokenPosition position) {
  return RecordCoverageImpl(position, true /** is_branch_coverage **/);
}

Fragment BaseFlowGraphBuilder::RecordCoverageImpl(TokenPosition position,
                                                  bool is_branch_coverage) {
  Fragment instructions;
  if (!SupportsCoverage()) return instructions;
  if (!position.IsReal()) return instructions;
  if (is_branch_coverage && !IG->branch_coverage()) return instructions;

  const intptr_t coverage_index =
      GetCoverageIndexFor(position.EncodeCoveragePosition(is_branch_coverage));
  instructions <<= new (Z) RecordCoverageInstr(coverage_array(), coverage_index,
                                               InstructionSource(position));
  return instructions;
}

intptr_t BaseFlowGraphBuilder::GetCoverageIndexFor(intptr_t encoded_position) {
  if (coverage_array_.IsNull()) {
    // We have not yet created coverage_array, this is the first time we are
    // building the graph for this function. Collect coverage positions.
    for (intptr_t i = 0; i < coverage_array_positions_.length(); i++) {
      if (coverage_array_positions_.At(i) == encoded_position) {
        return 2 * i + 1;
      }
    }
    const auto index = 2 * coverage_array_positions_.length() + 1;
    coverage_array_positions_.Add(encoded_position);
    return index;
  }

  for (intptr_t i = 0; i < coverage_array_.Length(); i += 2) {
    if (Smi::Value(static_cast<SmiPtr>(coverage_array_.At(i))) ==
        encoded_position) {
      return i + 1;
    }
  }
  // Reaching here indicates that the graph is constructed in an unstable way.
  UNREACHABLE();
  return 1;
}

void BaseFlowGraphBuilder::FinalizeCoverageArray() {
  if (!coverage_array_.IsNull()) {
    return;
  }

  if (coverage_array_positions_.is_empty()) {
    coverage_array_ = Array::empty_array().ptr();
    return;
  }

  coverage_array_ =
      Array::New(coverage_array_positions_.length() * 2, Heap::kOld);

  Smi& value = Smi::Handle();
  for (intptr_t i = 0; i < coverage_array_positions_.length(); i++) {
    value = Smi::New(coverage_array_positions_[i]);
    coverage_array_.SetAt(2 * i, value);
    value = Smi::New(0);  // no coverage recorded.
    coverage_array_.SetAt(2 * i + 1, value);
  }
}

}  // namespace kernel
}  // namespace dart
