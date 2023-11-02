// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_serializer.h"

#include "vm/closure_functions_cache.h"
#if defined(DART_PRECOMPILER)
#include "vm/compiler/aot/precompiler.h"
#endif
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/call.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/object_store.h"
#include "vm/parser.h"

#define Z zone_

// This file declares write/read methods for each type,
// sorted alphabetically by type/class name (case-insensitive).
// Each "write" method is followed by corresponding "read" method
// or constructor.

namespace dart {

FlowGraphSerializer::FlowGraphSerializer(NonStreamingWriteStream* stream)
    : stream_(stream),
      zone_(Thread::Current()->zone()),
      thread_(Thread::Current()),
      isolate_group_(IsolateGroup::Current()),
      heap_(IsolateGroup::Current()->heap()) {}

FlowGraphSerializer::~FlowGraphSerializer() {
  heap_->ResetObjectIdTable();
}

FlowGraphDeserializer::FlowGraphDeserializer(
    const ParsedFunction& parsed_function,
    ReadStream* stream)
    : parsed_function_(parsed_function),
      stream_(stream),
      zone_(Thread::Current()->zone()),
      thread_(Thread::Current()),
      isolate_group_(IsolateGroup::Current()) {}

ClassPtr FlowGraphDeserializer::GetClassById(classid_t id) const {
  return isolate_group()->class_table()->At(id);
}

template <>
void FlowGraphSerializer::WriteTrait<const AbstractType*>::Write(
    FlowGraphSerializer* s,
    const AbstractType* x) {
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    s->Write<const AbstractType&>(*x);
  }
}

template <>
const AbstractType* FlowGraphDeserializer::ReadTrait<const AbstractType*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return &(d->Read<const AbstractType&>());
}

template <>
void FlowGraphSerializer::WriteTrait<AliasIdentity>::Write(
    FlowGraphSerializer* s,
    AliasIdentity x) {
  x.Write(s);
}

template <>
AliasIdentity FlowGraphDeserializer::ReadTrait<AliasIdentity>::Read(
    FlowGraphDeserializer* d) {
  return AliasIdentity(d);
}

void AliasIdentity::Write(FlowGraphSerializer* s) const {
  s->Write<intptr_t>(value_);
}

AliasIdentity::AliasIdentity(FlowGraphDeserializer* d)
    : value_(d->Read<intptr_t>()) {}

void BlockEntryInstr::WriteTo(FlowGraphSerializer* s) {
  TemplateInstruction::WriteTo(s);
  s->Write<intptr_t>(block_id_);
  s->Write<intptr_t>(try_index_);
  s->Write<intptr_t>(stack_depth_);
  s->Write<ParallelMoveInstr*>(parallel_move_);
}

BlockEntryInstr::BlockEntryInstr(FlowGraphDeserializer* d)
    : TemplateInstruction(d),
      block_id_(d->Read<intptr_t>()),
      try_index_(d->Read<intptr_t>()),
      stack_depth_(d->Read<intptr_t>()),
      dominated_blocks_(1),
      parallel_move_(d->Read<ParallelMoveInstr*>()) {
  d->set_block(block_id_, this);
  d->set_current_block(this);
}

void BlockEntryInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateInstruction::WriteExtra(s);
  s->WriteRef<BlockEntryInstr*>(dominator_);
  s->WriteGrowableArrayOfRefs<BlockEntryInstr*>(dominated_blocks_);
  if (parallel_move_ != nullptr) {
    parallel_move_->WriteExtra(s);
  }
}

void BlockEntryInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateInstruction::ReadExtra(d);
  dominator_ = d->ReadRef<BlockEntryInstr*>();
  dominated_blocks_ = d->ReadGrowableArrayOfRefs<BlockEntryInstr*>();
  if (parallel_move_ != nullptr) {
    parallel_move_->ReadExtra(d);
  }
}

template <>
void FlowGraphSerializer::WriteRefTrait<BlockEntryInstr*>::WriteRef(
    FlowGraphSerializer* s,
    BlockEntryInstr* x) {
  ASSERT(s->can_write_refs());
  if (x == nullptr) {
    s->Write<intptr_t>(-1);
    return;
  }
  const intptr_t id = x->block_id();
  ASSERT(id >= 0);
  s->Write<intptr_t>(id);
}

template <>
BlockEntryInstr* FlowGraphDeserializer::ReadRefTrait<BlockEntryInstr*>::ReadRef(
    FlowGraphDeserializer* d) {
  const intptr_t id = d->Read<intptr_t>();
  if (id < 0) {
    return nullptr;
  }
  return d->block(id);
}

#define INSTRUCTION_REFS_SERIALIZABLE_AS_BLOCK_ENTRY(V)                        \
  V(CatchBlockEntry, CatchBlockEntryInstr)                                     \
  V(FunctionEntry, FunctionEntryInstr)                                         \
  V(IndirectEntry, IndirectEntryInstr)                                         \
  V(JoinEntry, JoinEntryInstr)                                                 \
  V(OsrEntry, OsrEntryInstr)                                                   \
  V(TargetEntry, TargetEntryInstr)

#define SERIALIZABLE_AS_BLOCK_ENTRY(name, type)                                \
  template <>                                                                  \
  void FlowGraphSerializer::WriteRefTrait<type*>::WriteRef(                    \
      FlowGraphSerializer* s, type* x) {                                       \
    s->WriteRef<BlockEntryInstr*>(x);                                          \
  }                                                                            \
  template <>                                                                  \
  type* FlowGraphDeserializer::ReadRefTrait<type*>::ReadRef(                   \
      FlowGraphDeserializer* d) {                                              \
    BlockEntryInstr* instr = d->ReadRef<BlockEntryInstr*>();                   \
    ASSERT((instr == nullptr) || instr->Is##name());                           \
    return static_cast<type*>(instr);                                          \
  }

INSTRUCTION_REFS_SERIALIZABLE_AS_BLOCK_ENTRY(SERIALIZABLE_AS_BLOCK_ENTRY)
#undef SERIALIZABLE_AS_BLOCK_ENTRY
#undef INSTRUCTION_REFS_SERIALIZABLE_AS_BLOCK_ENTRY

void BlockEntryWithInitialDefs::WriteTo(FlowGraphSerializer* s) {
  BlockEntryInstr::WriteTo(s);
  s->Write<GrowableArray<Definition*>>(initial_definitions_);
}

BlockEntryWithInitialDefs::BlockEntryWithInitialDefs(FlowGraphDeserializer* d)
    : BlockEntryInstr(d),
      initial_definitions_(d->Read<GrowableArray<Definition*>>()) {
  for (Definition* def : initial_definitions_) {
    def->set_previous(this);
    if (auto par = def->AsParameter()) {
      par->set_block(this);
    }
  }
}

void BlockEntryWithInitialDefs::WriteExtra(FlowGraphSerializer* s) {
  BlockEntryInstr::WriteExtra(s);
  for (Definition* def : initial_definitions_) {
    def->WriteExtra(s);
  }
}

void BlockEntryWithInitialDefs::ReadExtra(FlowGraphDeserializer* d) {
  BlockEntryInstr::ReadExtra(d);
  for (Definition* def : initial_definitions_) {
    def->ReadExtra(d);
  }
}

template <>
void FlowGraphSerializer::WriteTrait<bool>::Write(FlowGraphSerializer* s,
                                                  bool x) {
  s->stream()->Write<uint8_t>(x ? 1 : 0);
}

template <>
bool FlowGraphDeserializer::ReadTrait<bool>::Read(FlowGraphDeserializer* d) {
  return (d->stream()->Read<uint8_t>() != 0);
}

void BranchInstr::WriteExtra(FlowGraphSerializer* s) {
  // Branch reuses inputs from its embedded Comparison.
  // Instruction::WriteExtra is not called to avoid
  // writing/reading inputs twice.
  WriteExtraWithoutInputs(s);
  comparison_->WriteExtra(s);
  s->WriteRef<TargetEntryInstr*>(true_successor_);
  s->WriteRef<TargetEntryInstr*>(false_successor_);
  s->WriteRef<TargetEntryInstr*>(constant_target_);
}

void BranchInstr::ReadExtra(FlowGraphDeserializer* d) {
  ReadExtraWithoutInputs(d);
  comparison_->ReadExtra(d);
  for (intptr_t i = comparison_->InputCount() - 1; i >= 0; --i) {
    comparison_->InputAt(i)->set_instruction(this);
  }
  true_successor_ = d->ReadRef<TargetEntryInstr*>();
  false_successor_ = d->ReadRef<TargetEntryInstr*>();
  constant_target_ = d->ReadRef<TargetEntryInstr*>();
}

template <>
void FlowGraphSerializer::WriteTrait<const compiler::ffi::CallbackMarshaller&>::
    Write(FlowGraphSerializer* s, const compiler::ffi::CallbackMarshaller& x) {
  s->Write<const Function&>(x.dart_signature());
}

template <>
const compiler::ffi::CallbackMarshaller& FlowGraphDeserializer::ReadTrait<
    const compiler::ffi::CallbackMarshaller&>::Read(FlowGraphDeserializer* d) {
  const Function& dart_signature = d->Read<const Function&>();
  const char* error = nullptr;
  return *compiler::ffi::CallbackMarshaller::FromFunction(
      d->zone(), dart_signature, &error);
}

template <>
void FlowGraphSerializer::WriteTrait<const compiler::ffi::CallMarshaller&>::
    Write(FlowGraphSerializer* s, const compiler::ffi::CallMarshaller& x) {
  s->Write<const Function&>(x.dart_signature());
  s->Write<const FunctionType&>(x.c_signature());
}

template <>
const compiler::ffi::CallMarshaller&
FlowGraphDeserializer::ReadTrait<const compiler::ffi::CallMarshaller&>::Read(
    FlowGraphDeserializer* d) {
  const Function& dart_signature = d->Read<const Function&>();
  const FunctionType& c_signature = d->Read<const FunctionType&>();
  const char* error = nullptr;
  return *compiler::ffi::CallMarshaller::FromFunction(d->zone(), dart_signature,
                                                      c_signature, &error);
}

template <>
void FlowGraphSerializer::WriteTrait<const CallTargets&>::Write(
    FlowGraphSerializer* s,
    const CallTargets& x) {
  x.Write(s);
}

template <>
const CallTargets& FlowGraphDeserializer::ReadTrait<const CallTargets&>::Read(
    FlowGraphDeserializer* d) {
  return *(new (d->zone()) CallTargets(d));
}

void CallTargets::Write(FlowGraphSerializer* s) const {
  const intptr_t len = cid_ranges_.length();
  s->Write<intptr_t>(len);
  for (intptr_t i = 0; i < len; ++i) {
    TargetInfo* t = TargetAt(i);
    s->Write<intptr_t>(t->cid_start);
    s->Write<intptr_t>(t->cid_end);
    s->Write<const Function&>(*(t->target));
    s->Write<intptr_t>(t->count);
    s->Write<int8_t>(t->exactness.Encode());
  }
}

CallTargets::CallTargets(FlowGraphDeserializer* d) : Cids(d->zone()) {
  const intptr_t len = d->Read<intptr_t>();
  cid_ranges_.EnsureLength(len, nullptr);
  for (intptr_t i = 0; i < len; ++i) {
    const intptr_t cid_start = d->Read<intptr_t>();
    const intptr_t cid_end = d->Read<intptr_t>();
    const Function& target = d->Read<const Function&>();
    const intptr_t count = d->Read<intptr_t>();
    const StaticTypeExactnessState exactness =
        StaticTypeExactnessState::Decode(d->Read<int8_t>());
    TargetInfo* t = new (d->zone())
        TargetInfo(cid_start, cid_end, &target, count, exactness);
    cid_ranges_[i] = t;
  }
}

void CatchBlockEntryInstr::WriteTo(FlowGraphSerializer* s) {
  BlockEntryWithInitialDefs::WriteTo(s);
  s->Write<const Array&>(catch_handler_types_);
  s->Write<intptr_t>(catch_try_index_);
  s->Write<bool>(needs_stacktrace_);
  s->Write<bool>(is_generated_);
}

CatchBlockEntryInstr::CatchBlockEntryInstr(FlowGraphDeserializer* d)
    : BlockEntryWithInitialDefs(d),
      graph_entry_(d->graph_entry()),
      predecessor_(nullptr),
      catch_handler_types_(d->Read<const Array&>()),
      catch_try_index_(d->Read<intptr_t>()),
      exception_var_(nullptr),
      stacktrace_var_(nullptr),
      raw_exception_var_(nullptr),
      raw_stacktrace_var_(nullptr),
      needs_stacktrace_(d->Read<bool>()),
      is_generated_(d->Read<bool>()) {}

template <>
void FlowGraphSerializer::WriteTrait<const char*>::Write(FlowGraphSerializer* s,
                                                         const char* x) {
  ASSERT(x != nullptr);
  const intptr_t len = strlen(x);
  s->Write<intptr_t>(len);
  s->stream()->WriteBytes(x, len);
}

template <>
const char* FlowGraphDeserializer::ReadTrait<const char*>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t len = d->Read<intptr_t>();
  char* str = d->zone()->Alloc<char>(len + 1);
  d->stream()->ReadBytes(str, len);
  str[len] = 0;
  return str;
}

void CheckConditionInstr::WriteExtra(FlowGraphSerializer* s) {
  // CheckCondition reuses inputs from its embedded Comparison.
  // Instruction::WriteExtra is not called to avoid
  // writing/reading inputs twice.
  WriteExtraWithoutInputs(s);
  comparison_->WriteExtra(s);
}

void CheckConditionInstr::ReadExtra(FlowGraphDeserializer* d) {
  ReadExtraWithoutInputs(d);
  comparison_->ReadExtra(d);
  for (intptr_t i = comparison_->InputCount() - 1; i >= 0; --i) {
    comparison_->InputAt(i)->set_instruction(this);
  }
}

template <>
void FlowGraphSerializer::WriteTrait<CidRangeValue>::Write(
    FlowGraphSerializer* s,
    CidRangeValue x) {
  s->Write<intptr_t>(x.cid_start);
  s->Write<intptr_t>(x.cid_end);
}

template <>
CidRangeValue FlowGraphDeserializer::ReadTrait<CidRangeValue>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t cid_start = d->Read<intptr_t>();
  const intptr_t cid_end = d->Read<intptr_t>();
  return CidRangeValue(cid_start, cid_end);
}

template <>
void FlowGraphSerializer::WriteTrait<const Cids&>::Write(FlowGraphSerializer* s,
                                                         const Cids& x) {
  const intptr_t len = x.length();
  s->Write<intptr_t>(len);
  for (intptr_t i = 0; i < len; ++i) {
    const CidRange* r = x.At(i);
    s->Write<intptr_t>(r->cid_start);
    s->Write<intptr_t>(r->cid_end);
  }
}

template <>
const Cids& FlowGraphDeserializer::ReadTrait<const Cids&>::Read(
    FlowGraphDeserializer* d) {
  Zone* zone = d->zone();
  Cids* cids = new (zone) Cids(zone);
  const intptr_t len = d->Read<intptr_t>();
  for (intptr_t i = 0; i < len; ++i) {
    const intptr_t cid_start = d->Read<intptr_t>();
    const intptr_t cid_end = d->Read<intptr_t>();
    CidRange* r = new (zone) CidRange(cid_start, cid_end);
    cids->Add(r);
  }
  return *cids;
}

template <>
void FlowGraphSerializer::WriteTrait<const Class&>::Write(
    FlowGraphSerializer* s,
    const Class& x) {
  if (x.IsNull()) {
    s->Write<classid_t>(kIllegalCid);
    return;
  }
  s->Write<classid_t>(x.id());
}

template <>
const Class& FlowGraphDeserializer::ReadTrait<const Class&>::Read(
    FlowGraphDeserializer* d) {
  const classid_t cid = d->Read<classid_t>();
  if (cid == kIllegalCid) {
    return Class::ZoneHandle(d->zone());
  }
  return Class::ZoneHandle(d->zone(), d->GetClassById(cid));
}

void ConstraintInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateDefinition::WriteExtra(s);
  s->WriteRef<TargetEntryInstr*>(target_);
}

void ConstraintInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateDefinition::ReadExtra(d);
  target_ = d->ReadRef<TargetEntryInstr*>();
}

template <>
void FlowGraphSerializer::WriteTrait<const Code&>::Write(FlowGraphSerializer* s,
                                                         const Code& x) {
  ASSERT(!x.IsNull());
  ASSERT(x.IsStubCode());
  for (intptr_t i = 0, n = StubCode::NumEntries(); i < n; ++i) {
    if (StubCode::EntryAt(i).ptr() == x.ptr()) {
      s->Write<intptr_t>(i);
      return;
    }
  }
  intptr_t index = StubCode::NumEntries();
  ObjectStore* object_store = s->isolate_group()->object_store();
#define MATCH(member, name)                                                    \
  if (object_store->member() == x.ptr()) {                                     \
    s->Write<intptr_t>(index);                                                 \
    return;                                                                    \
  }                                                                            \
  ++index;
  OBJECT_STORE_STUB_CODE_LIST(MATCH)
#undef MATCH
  UNIMPLEMENTED();
}

template <>
const Code& FlowGraphDeserializer::ReadTrait<const Code&>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t stub_id = d->Read<intptr_t>();
  if (stub_id < StubCode::NumEntries()) {
    return StubCode::EntryAt(stub_id);
  }
  intptr_t index = StubCode::NumEntries();
  ObjectStore* object_store = d->isolate_group()->object_store();
#define MATCH(member, name)                                                    \
  if (index == stub_id) {                                                      \
    return Code::ZoneHandle(d->zone(), object_store->member());                \
  }                                                                            \
  ++index;
  OBJECT_STORE_STUB_CODE_LIST(MATCH)
#undef MATCH
  UNIMPLEMENTED();
}

template <>
void FlowGraphSerializer::WriteTrait<CompileType*>::Write(
    FlowGraphSerializer* s,
    CompileType* x) {
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    x->Write(s);
  }
}

template <>
CompileType* FlowGraphDeserializer::ReadTrait<CompileType*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return new (d->zone()) CompileType(d);
}

void CompileType::Write(FlowGraphSerializer* s) const {
  s->Write<bool>(can_be_null_);
  s->Write<bool>(can_be_sentinel_);
  s->Write<classid_t>(cid_);
  if (type_ == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    s->Write<const AbstractType&>(*type_);
  }
}

CompileType::CompileType(FlowGraphDeserializer* d)
    : can_be_null_(d->Read<bool>()),
      can_be_sentinel_(d->Read<bool>()),
      cid_(d->Read<classid_t>()),
      type_(nullptr) {
  if (d->Read<bool>()) {
    type_ = &d->Read<const AbstractType&>();
  }
}

void Definition::WriteTo(FlowGraphSerializer* s) {
  Instruction::WriteTo(s);
  s->Write<Range*>(range_);
  s->Write<intptr_t>(temp_index_);
  s->Write<intptr_t>(ssa_temp_index_);
  s->Write<CompileType*>(type_);
}

Definition::Definition(FlowGraphDeserializer* d)
    : Instruction(d),
      range_(d->Read<Range*>()),
      temp_index_(d->Read<intptr_t>()),
      ssa_temp_index_(d->Read<intptr_t>()),
      type_(d->Read<CompileType*>()) {
  if (HasSSATemp()) {
    d->set_definition(ssa_temp_index(), this);
  }
  if (type_ != nullptr) {
    type_->set_owner(this);
  }
}

template <>
void FlowGraphSerializer::WriteRefTrait<Definition*>::WriteRef(
    FlowGraphSerializer* s,
    Definition* x) {
  if (!x->HasSSATemp()) {
    if (auto* move_arg = x->AsMoveArgument()) {
      // Environments of the calls can reference MoveArgument instructions
      // and they don't have SSA temps.
      // Write a reference to the original definition.
      // When reading it is restored using RepairArgumentUsesInEnvironment.
      x = move_arg->value()->definition();
    } else {
      UNREACHABLE();
    }
  }
  ASSERT(x->HasSSATemp());
  ASSERT(s->can_write_refs());
  s->Write<intptr_t>(x->ssa_temp_index());
}

template <>
Definition* FlowGraphDeserializer::ReadRefTrait<Definition*>::ReadRef(
    FlowGraphDeserializer* d) {
  return d->definition(d->Read<intptr_t>());
}

template <>
void FlowGraphSerializer::WriteTrait<double>::Write(FlowGraphSerializer* s,
                                                    double x) {
  s->stream()->Write<int64_t>(bit_cast<int64_t>(x));
}

template <>
double FlowGraphDeserializer::ReadTrait<double>::Read(
    FlowGraphDeserializer* d) {
  return bit_cast<double>(d->stream()->Read<int64_t>());
}

template <>
void FlowGraphSerializer::WriteTrait<Environment*>::Write(
    FlowGraphSerializer* s,
    Environment* x) {
  ASSERT(s->can_write_refs());
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    x->Write(s);
  }
}

template <>
Environment* FlowGraphDeserializer::ReadTrait<Environment*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return new (d->zone()) Environment(d);
}

void Environment::Write(FlowGraphSerializer* s) const {
  s->Write<GrowableArray<Value*>>(values_);
  s->Write<intptr_t>(fixed_parameter_count_);
  s->Write<uintptr_t>(bitfield_);
  s->Write<const Function&>(function_);
  s->Write<Environment*>(outer_);
  if (locations_ == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    for (intptr_t i = 0, n = values_.length(); i < n; ++i) {
      locations_[i].Write(s);
    }
  }
}

Environment::Environment(FlowGraphDeserializer* d)
    : values_(d->Read<GrowableArray<Value*>>()),
      locations_(nullptr),
      fixed_parameter_count_(d->Read<intptr_t>()),
      bitfield_(d->Read<uintptr_t>()),
      function_(d->Read<const Function&>()),
      outer_(d->Read<Environment*>()) {
  for (intptr_t i = 0, n = values_.length(); i < n; ++i) {
    Value* value = values_[i];
    value->definition()->AddEnvUse(value);
  }
  if (d->Read<bool>()) {
    locations_ = d->zone()->Alloc<Location>(values_.length());
    for (intptr_t i = 0, n = values_.length(); i < n; ++i) {
      locations_[i] = Location::Read(d);
    }
  }
}

void FlowGraphSerializer::WriteFlowGraph(
    const FlowGraph& flow_graph,
    const ZoneGrowableArray<Definition*>& detached_defs) {
  ASSERT(!flow_graph.is_licm_allowed());

  Write<intptr_t>(flow_graph.current_ssa_temp_index());
  Write<intptr_t>(flow_graph.max_block_id());
  Write<intptr_t>(flow_graph.inlining_id());
  Write<const Array&>(flow_graph.coverage_array());

  PrologueInfo prologue_info = flow_graph.prologue_info();
  Write<intptr_t>(prologue_info.min_block_id);
  Write<intptr_t>(prologue_info.max_block_id);

  // Write instructions
  for (auto block : flow_graph.reverse_postorder()) {
    Write<Instruction*>(block);
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      Write<Instruction*>(current);
    }
  }
  Write<Instruction*>(nullptr);
  Write<const ZoneGrowableArray<Definition*>&>(detached_defs);
  can_write_refs_ = true;

  // Write instructions extra info.
  // It may contain references to other instructions.
  for (auto block : flow_graph.reverse_postorder()) {
    block->WriteExtra(this);
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      current->WriteExtra(this);
    }
  }
  for (auto* instr : detached_defs) {
    instr->WriteExtra(this);
  }

  const auto& optimized_block_order = flow_graph.optimized_block_order();
  Write<intptr_t>(optimized_block_order.length());
  for (intptr_t i = 0, n = optimized_block_order.length(); i < n; ++i) {
    WriteRef<BlockEntryInstr*>(optimized_block_order[i]);
  }

  const auto* captured_parameters = flow_graph.captured_parameters();
  if (captured_parameters->IsEmpty()) {
    Write<bool>(false);
  } else {
    Write<bool>(true);
    // Captured parameters are rare so write their bit numbers
    // instead of writing BitVector.
    GrowableArray<intptr_t> indices(Z, 0);
    for (intptr_t i = 0, n = captured_parameters->length(); i < n; ++i) {
      if (captured_parameters->Contains(i)) {
        indices.Add(i);
      }
    }
    Write<GrowableArray<intptr_t>>(indices);
  }
}

FlowGraph* FlowGraphDeserializer::ReadFlowGraph() {
  const intptr_t current_ssa_temp_index = Read<intptr_t>();
  const intptr_t max_block_id = Read<intptr_t>();
  const intptr_t inlining_id = Read<intptr_t>();
  const Array& coverage_array = Read<const Array&>();
  const PrologueInfo prologue_info(Read<intptr_t>(), Read<intptr_t>());

  definitions_.EnsureLength(current_ssa_temp_index, nullptr);
  blocks_.EnsureLength(max_block_id + 1, nullptr);

  // Read/create instructions.
  ZoneGrowableArray<Instruction*> instructions(16);
  Instruction* prev = nullptr;
  while (Instruction* instr = Read<Instruction*>()) {
    instructions.Add(instr);
    if (!instr->IsBlockEntry()) {
      ASSERT(prev != nullptr);
      prev->LinkTo(instr);
    }
    prev = instr;
  }
  ASSERT(graph_entry_ != nullptr);
  const auto& detached_defs = Read<const ZoneGrowableArray<Definition*>&>();

  // Read instructions extra info.
  // It may contain references to other instructions.
  for (Instruction* instr : instructions) {
    instr->ReadExtra(this);
  }
  for (auto* instr : detached_defs) {
    instr->ReadExtra(this);
  }

  FlowGraph* flow_graph = new (Z)
      FlowGraph(parsed_function(), graph_entry_, max_block_id, prologue_info);
  flow_graph->set_current_ssa_temp_index(current_ssa_temp_index);
  flow_graph->CreateCommonConstants();
  flow_graph->disallow_licm();
  flow_graph->set_inlining_id(inlining_id);
  flow_graph->set_coverage_array(coverage_array);

  {
    const intptr_t num_blocks = Read<intptr_t>();
    if (num_blocks != 0) {
      auto* codegen_block_order = flow_graph->CodegenBlockOrder(true);
      ASSERT(codegen_block_order == &flow_graph->optimized_block_order());
      for (intptr_t i = 0; i < num_blocks; ++i) {
        codegen_block_order->Add(ReadRef<BlockEntryInstr*>());
      }
    }
  }

  if (Read<bool>()) {
    GrowableArray<intptr_t> indices = Read<GrowableArray<intptr_t>>();
    for (intptr_t i : indices) {
      flow_graph->captured_parameters()->Add(i);
    }
  }

  return flow_graph;
}

template <>
void FlowGraphSerializer::WriteTrait<const Function&>::Write(
    FlowGraphSerializer* s,
    const Function& x) {
  if (x.IsNull()) {
    s->Write<int8_t>(-1);
    return;
  }
  Zone* zone = s->zone();
  s->Write<int8_t>(x.kind());
  switch (x.kind()) {
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kImplicitGetter:
    case UntaggedFunction::kImplicitSetter:
    case UntaggedFunction::kImplicitStaticGetter:
    case UntaggedFunction::kConstructor: {
      const auto& owner = Class::Handle(zone, x.Owner());
      s->Write<classid_t>(owner.id());
      const intptr_t function_index = owner.FindFunctionIndex(x);
      ASSERT(function_index >= 0);
      s->Write<intptr_t>(function_index);
      return;
    }
    case UntaggedFunction::kImplicitClosureFunction: {
      const auto& parent = Function::Handle(zone, x.parent_function());
      s->Write<const Function&>(parent);
      return;
    }
    case UntaggedFunction::kFieldInitializer: {
      const auto& field = Field::Handle(zone, x.accessor_field());
      s->Write<const Field&>(field);
      return;
    }
    case UntaggedFunction::kClosureFunction:
      // TODO(alexmarkov): we cannot rely on ClosureFunctionsCache
      // as it is lazily populated when compiling functions.
      // We need to serialize kernel offset and re-create
      // closure functions when reading as needed.
      s->Write<intptr_t>(ClosureFunctionsCache::FindClosureIndex(x));
      return;
    case UntaggedFunction::kMethodExtractor: {
      Function& function = Function::Handle(zone, x.extracted_method_closure());
      ASSERT(function.IsImplicitClosureFunction());
      function = function.parent_function();
      s->Write<const Function&>(function);
      s->Write<const String&>(String::Handle(zone, x.name()));
      return;
    }
    case UntaggedFunction::kInvokeFieldDispatcher: {
      s->Write<const Class&>(Class::Handle(zone, x.Owner()));
      s->Write<const String&>(String::Handle(zone, x.name()));
      s->Write<const Array&>(Array::Handle(zone, x.saved_args_desc()));
      return;
    }
    case UntaggedFunction::kDynamicInvocationForwarder: {
      const auto& target = Function::Handle(zone, x.ForwardingTarget());
      s->Write<const Function&>(target);
      return;
    }
    case UntaggedFunction::kFfiTrampoline: {
      s->Write<uint8_t>(static_cast<uint8_t>(x.GetFfiFunctionKind()));
      s->Write<const FunctionType&>(
          FunctionType::Handle(zone, x.FfiCSignature()));
      if (x.GetFfiFunctionKind() != FfiFunctionKind::kCall) {
        s->Write<const Function&>(
            Function::Handle(zone, x.FfiCallbackTarget()));
        s->Write<const Instance&>(
            Instance::Handle(zone, x.FfiCallbackExceptionalReturn()));
      } else {
        s->Write<const String&>(String::Handle(zone, x.name()));
        s->Write<const FunctionType&>(
            FunctionType::Handle(zone, x.signature()));
        s->Write<bool>(x.FfiIsLeaf());
      }
      return;
    }
    default:
      break;
  }
  switch (x.kind()) {
#define UNIMPLEMENTED_FUNCTION_KIND(kind)                                      \
  case UntaggedFunction::k##kind:                                              \
    FATAL("Unimplemented WriteTrait<const Function&>::Write for " #kind);
    FOR_EACH_RAW_FUNCTION_KIND(UNIMPLEMENTED_FUNCTION_KIND)
#undef UNIMPLEMENTED_FUNCTION_KIND
  }
  UNREACHABLE();
}

template <>
const Function& FlowGraphDeserializer::ReadTrait<const Function&>::Read(
    FlowGraphDeserializer* d) {
  const int8_t raw_kind = d->Read<int8_t>();
  if (raw_kind < 0) {
    return Object::null_function();
  }
  Zone* zone = d->zone();
  const auto kind = static_cast<UntaggedFunction::Kind>(raw_kind);
  switch (kind) {
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kImplicitGetter:
    case UntaggedFunction::kImplicitSetter:
    case UntaggedFunction::kImplicitStaticGetter:
    case UntaggedFunction::kConstructor: {
      const classid_t owner_class_id = d->Read<classid_t>();
      const intptr_t function_index = d->Read<intptr_t>();
      const auto& owner = Class::Handle(zone, d->GetClassById(owner_class_id));
      const auto& result =
          Function::ZoneHandle(zone, owner.FunctionFromIndex(function_index));
      ASSERT(!result.IsNull());
      return result;
    }
    case UntaggedFunction::kImplicitClosureFunction: {
      const auto& parent = d->Read<const Function&>();
      return Function::ZoneHandle(zone, parent.ImplicitClosureFunction());
    }
    case UntaggedFunction::kFieldInitializer: {
      const auto& field = d->Read<const Field&>();
      return Function::ZoneHandle(zone, field.EnsureInitializerFunction());
    }
    case UntaggedFunction::kClosureFunction: {
      const intptr_t index = d->Read<intptr_t>();
      return Function::ZoneHandle(
          zone, ClosureFunctionsCache::ClosureFunctionFromIndex(index));
    }
    case UntaggedFunction::kMethodExtractor: {
      const Function& function = d->Read<const Function&>();
      const String& name = d->Read<const String&>();
      return Function::ZoneHandle(zone, function.GetMethodExtractor(name));
    }
    case UntaggedFunction::kInvokeFieldDispatcher: {
      const Class& owner = d->Read<const Class&>();
      const String& target_name = d->Read<const String&>();
      const Array& args_desc = d->Read<const Array&>();
      return Function::ZoneHandle(
          zone,
          owner.GetInvocationDispatcher(
              target_name, args_desc, UntaggedFunction::kInvokeFieldDispatcher,
              /*create_if_absent=*/true));
    }
    case UntaggedFunction::kDynamicInvocationForwarder: {
      const auto& target = d->Read<const Function&>();
      auto& name = String::Handle(zone, target.name());
      name = Function::CreateDynamicInvocationForwarderName(name);
      return Function::ZoneHandle(zone,
                                  target.GetDynamicInvocationForwarder(name));
    }
    case UntaggedFunction::kFfiTrampoline: {
      const FfiFunctionKind kind =
          static_cast<FfiFunctionKind>(d->Read<uint8_t>());
      const FunctionType& c_signature = d->Read<const FunctionType&>();
      if (kind != FfiFunctionKind::kCall) {
        const Function& callback_target = d->Read<const Function&>();
        const Instance& exceptional_return = d->Read<const Instance&>();
        return Function::ZoneHandle(
            zone, compiler::ffi::NativeCallbackFunction(
                      c_signature, callback_target, exceptional_return, kind));
      } else {
        const String& name = d->Read<const String&>();
        const FunctionType& signature = d->Read<const FunctionType&>();
        const bool is_leaf = d->Read<bool>();
        return Function::ZoneHandle(
            zone, compiler::ffi::TrampolineFunction(name, signature,
                                                    c_signature, is_leaf));
      }
    }
    default:
      UNIMPLEMENTED();
      return Object::null_function();
  }
}

void FunctionEntryInstr::WriteTo(FlowGraphSerializer* s) {
  BlockEntryWithInitialDefs::WriteTo(s);
}

FunctionEntryInstr::FunctionEntryInstr(FlowGraphDeserializer* d)
    : BlockEntryWithInitialDefs(d), graph_entry_(d->graph_entry()) {}

void GraphEntryInstr::WriteTo(FlowGraphSerializer* s) {
  BlockEntryWithInitialDefs::WriteTo(s);
  s->Write<intptr_t>(osr_id_);
  s->Write<intptr_t>(entry_count_);
  s->Write<intptr_t>(spill_slot_count_);
  s->Write<intptr_t>(fixed_slot_count_);
  s->Write<bool>(needs_frame_);
}

GraphEntryInstr::GraphEntryInstr(FlowGraphDeserializer* d)
    : BlockEntryWithInitialDefs(d),
      parsed_function_(d->parsed_function()),
      osr_id_(d->Read<intptr_t>()),
      entry_count_(d->Read<intptr_t>()),
      spill_slot_count_(d->Read<intptr_t>()),
      fixed_slot_count_(d->Read<intptr_t>()),
      needs_frame_(d->Read<bool>()) {
  d->set_graph_entry(this);
}

void GraphEntryInstr::WriteExtra(FlowGraphSerializer* s) {
  BlockEntryWithInitialDefs::WriteExtra(s);
  s->WriteRef<FunctionEntryInstr*>(normal_entry_);
  s->WriteRef<FunctionEntryInstr*>(unchecked_entry_);
  s->WriteRef<OsrEntryInstr*>(osr_entry_);
  s->WriteGrowableArrayOfRefs<CatchBlockEntryInstr*>(catch_entries_);
  s->WriteGrowableArrayOfRefs<IndirectEntryInstr*>(indirect_entries_);
}

void GraphEntryInstr::ReadExtra(FlowGraphDeserializer* d) {
  BlockEntryWithInitialDefs::ReadExtra(d);
  normal_entry_ = d->ReadRef<FunctionEntryInstr*>();
  unchecked_entry_ = d->ReadRef<FunctionEntryInstr*>();
  osr_entry_ = d->ReadRef<OsrEntryInstr*>();
  catch_entries_ = d->ReadGrowableArrayOfRefs<CatchBlockEntryInstr*>();
  indirect_entries_ = d->ReadGrowableArrayOfRefs<IndirectEntryInstr*>();
}

void GotoInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateInstruction::WriteExtra(s);
  if (parallel_move_ != nullptr) {
    parallel_move_->WriteExtra(s);
  }
  s->WriteRef<JoinEntryInstr*>(successor_);
}

void GotoInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateInstruction::ReadExtra(d);
  if (parallel_move_ != nullptr) {
    parallel_move_->ReadExtra(d);
  }
  successor_ = d->ReadRef<JoinEntryInstr*>();
}

template <>
void FlowGraphSerializer::WriteTrait<const ICData*>::Write(
    FlowGraphSerializer* s,
    const ICData* x) {
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    ASSERT(!x->IsNull());
    s->Write<const Object&>(*x);
  }
}

template <>
const ICData* FlowGraphDeserializer::ReadTrait<const ICData*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return &ICData::Cast(d->Read<const Object&>());
}

void IfThenElseInstr::WriteExtra(FlowGraphSerializer* s) {
  // IfThenElse reuses inputs from its embedded Comparison.
  // Definition::WriteExtra is not called to avoid
  // writing/reading inputs twice.
  WriteExtraWithoutInputs(s);
  comparison_->WriteExtra(s);
}

void IfThenElseInstr::ReadExtra(FlowGraphDeserializer* d) {
  ReadExtraWithoutInputs(d);
  comparison_->ReadExtra(d);
  for (intptr_t i = comparison_->InputCount() - 1; i >= 0; --i) {
    comparison_->InputAt(i)->set_instruction(this);
  }
}

void IndirectGotoInstr::WriteTo(FlowGraphSerializer* s) {
  TemplateInstruction::WriteTo(s);
  s->Write<intptr_t>(offsets_.Length());
}

IndirectGotoInstr::IndirectGotoInstr(FlowGraphDeserializer* d)
    : TemplateInstruction(d),
      offsets_(TypedData::ZoneHandle(d->zone(),
                                     TypedData::New(kTypedDataInt32ArrayCid,
                                                    d->Read<intptr_t>(),
                                                    Heap::kOld))) {}

void IndirectGotoInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateInstruction::WriteExtra(s);
  s->WriteGrowableArrayOfRefs<TargetEntryInstr*>(successors_);
}

void IndirectGotoInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateInstruction::ReadExtra(d);
  successors_ = d->ReadGrowableArrayOfRefs<TargetEntryInstr*>();
}

template <>
void FlowGraphSerializer::WriteTrait<Instruction*>::Write(
    FlowGraphSerializer* s,
    Instruction* x) {
  if (x == nullptr) {
    s->Write<uint8_t>(Instruction::kNumInstructions);
  } else {
    s->Write<uint8_t>(static_cast<uint8_t>(x->tag()));
    x->WriteTo(s);
  }
}

template <>
Instruction* FlowGraphDeserializer::ReadTrait<Instruction*>::Read(
    FlowGraphDeserializer* d) {
  const uint8_t tag = d->Read<uint8_t>();
  switch (tag) {
#define READ_INSTRUCTION(type, attrs)                                          \
  case Instruction::k##type:                                                   \
    return new (d->zone()) type##Instr(d);
    FOR_EACH_INSTRUCTION(READ_INSTRUCTION)
#undef READ_INSTRUCTION
    case Instruction::kNumInstructions:
      return nullptr;
  }
  UNREACHABLE();
  return nullptr;
}

void Instruction::WriteTo(FlowGraphSerializer* s) {
  s->Write<intptr_t>(deopt_id_);
  s->Write<intptr_t>(inlining_id_);
}

Instruction::Instruction(FlowGraphDeserializer* d)
    : deopt_id_(d->Read<intptr_t>()), inlining_id_(d->Read<intptr_t>()) {}

void Instruction::WriteExtra(FlowGraphSerializer* s) {
  for (intptr_t i = 0, n = InputCount(); i < n; ++i) {
    s->Write<Value*>(InputAt(i));
  }
  WriteExtraWithoutInputs(s);
}

void Instruction::ReadExtra(FlowGraphDeserializer* d) {
  for (intptr_t i = 0, n = InputCount(); i < n; ++i) {
    SetInputAt(i, d->Read<Value*>());
  }
  for (intptr_t i = InputCount() - 1; i >= 0; --i) {
    Value* input = InputAt(i);
    input->definition()->AddInputUse(input);
  }
  ReadExtraWithoutInputs(d);
}

void Instruction::WriteExtraWithoutInputs(FlowGraphSerializer* s) {
  s->Write<Environment*>(env_);
  s->Write<LocationSummary*>(locs_);
}

void Instruction::ReadExtraWithoutInputs(FlowGraphDeserializer* d) {
  Environment* env = d->Read<Environment*>();
  SetEnvironment(env);
  locs_ = d->Read<LocationSummary*>();
}

#define INSTRUCTIONS_SERIALIZABLE_AS_INSTRUCTION(V)                            \
  V(Comparison, ComparisonInstr)                                               \
  V(Constant, ConstantInstr)                                                   \
  V(Definition, Definition)                                                    \
  V(ParallelMove, ParallelMoveInstr)                                           \
  V(Phi, PhiInstr)

#define SERIALIZABLE_AS_INSTRUCTION(name, type)                                \
  template <>                                                                  \
  void FlowGraphSerializer::WriteTrait<type*>::Write(FlowGraphSerializer* s,   \
                                                     type* x) {                \
    s->Write<Instruction*>(x);                                                 \
  }                                                                            \
  template <>                                                                  \
  type* FlowGraphDeserializer::ReadTrait<type*>::Read(                         \
      FlowGraphDeserializer* d) {                                              \
    Instruction* instr = d->Read<Instruction*>();                              \
    ASSERT((instr == nullptr) || instr->Is##name());                           \
    return static_cast<type*>(instr);                                          \
  }

INSTRUCTIONS_SERIALIZABLE_AS_INSTRUCTION(SERIALIZABLE_AS_INSTRUCTION)
#undef SERIALIZABLE_AS_INSTRUCTION
#undef INSTRUCTIONS_SERIALIZABLE_AS_INSTRUCTION

template <>
void FlowGraphSerializer::WriteTrait<int8_t>::Write(FlowGraphSerializer* s,
                                                    int8_t x) {
  s->stream()->Write<int8_t>(x);
}

template <>
int8_t FlowGraphDeserializer::ReadTrait<int8_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<int8_t>();
}

template <>
void FlowGraphSerializer::WriteTrait<int16_t>::Write(FlowGraphSerializer* s,
                                                     int16_t x) {
  s->stream()->Write<int16_t>(x);
}

template <>
int16_t FlowGraphDeserializer::ReadTrait<int16_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<int16_t>();
}

template <>
void FlowGraphSerializer::WriteTrait<int32_t>::Write(FlowGraphSerializer* s,
                                                     int32_t x) {
  s->stream()->Write<int32_t>(x);
}

template <>
int32_t FlowGraphDeserializer::ReadTrait<int32_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<int32_t>();
}

template <>
void FlowGraphSerializer::WriteTrait<int64_t>::Write(FlowGraphSerializer* s,
                                                     int64_t x) {
  s->stream()->Write<int64_t>(x);
}

template <>
int64_t FlowGraphDeserializer::ReadTrait<int64_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<int64_t>();
}

void JoinEntryInstr::WriteExtra(FlowGraphSerializer* s) {
  BlockEntryInstr::WriteExtra(s);
  if (phis_ != nullptr) {
    for (PhiInstr* phi : *phis_) {
      phi->WriteExtra(s);
    }
  }
}

void JoinEntryInstr::ReadExtra(FlowGraphDeserializer* d) {
  BlockEntryInstr::ReadExtra(d);
  if (phis_ != nullptr) {
    for (PhiInstr* phi : *phis_) {
      phi->ReadExtra(d);
    }
  }
}

template <>
void FlowGraphSerializer::WriteTrait<const LocalVariable&>::Write(
    FlowGraphSerializer* s,
    const LocalVariable& x) {
  UNIMPLEMENTED();
}

template <>
const LocalVariable&
FlowGraphDeserializer::ReadTrait<const LocalVariable&>::Read(
    FlowGraphDeserializer* d) {
  UNIMPLEMENTED();
  return *d->parsed_function().receiver_var();
}

void Location::Write(FlowGraphSerializer* s) const {
  if (IsPairLocation()) {
    s->Write<uword>(value_ & kLocationTagMask);
    PairLocation* pair = AsPairLocation();
    pair->At(0).Write(s);
    pair->At(1).Write(s);
  } else if (IsConstant()) {
    s->Write<uword>(value_ & kLocationTagMask);
    s->WriteRef<Definition*>(constant_instruction());
  } else {
    s->Write<uword>(value_);
  }
}

Location Location::Read(FlowGraphDeserializer* d) {
  const uword value = d->Read<uword>();
  if (value == kPairLocationTag) {
    const Location first = Location::Read(d);
    const Location second = Location::Read(d);
    return Location::Pair(first, second);
  } else if ((value & kConstantTag) == kConstantTag) {
    ConstantInstr* instr = d->ReadRef<Definition*>()->AsConstant();
    ASSERT(instr != nullptr);
    const int pair_index = (value & kPairLocationTag) != 0 ? 1 : 0;
    return Location::Constant(instr, pair_index);
  } else {
    return Location(value);
  }
}

template <>
void FlowGraphSerializer::WriteTrait<LocationSummary*>::Write(
    FlowGraphSerializer* s,
    LocationSummary* x) {
  ASSERT(s->can_write_refs());
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    x->Write(s);
  }
}

template <>
LocationSummary* FlowGraphDeserializer::ReadTrait<LocationSummary*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return new (d->zone()) LocationSummary(d);
}

void LocationSummary::Write(FlowGraphSerializer* s) const {
  s->Write<intptr_t>(input_count());
  s->Write<intptr_t>(temp_count());
  s->Write<int8_t>(static_cast<int8_t>(contains_call_));
  live_registers_.Write(s);

  for (intptr_t i = 0, n = input_count(); i < n; ++i) {
    in(i).Write(s);
  }
  for (intptr_t i = 0, n = temp_count(); i < n; ++i) {
    temp(i).Write(s);
  }
  ASSERT(output_count() == 1);
  out(0).Write(s);

  if ((stack_bitmap_ != nullptr) && (stack_bitmap_->Length() != 0)) {
    s->Write<int8_t>(1);
    stack_bitmap_->Write(s->stream());
  } else {
    s->Write<int8_t>(0);
  }

#if defined(DEBUG)
  s->Write<intptr_t>(writable_inputs_);
#endif
}

LocationSummary::LocationSummary(FlowGraphDeserializer* d)
    : num_inputs_(d->Read<intptr_t>()),
      num_temps_(d->Read<intptr_t>()),
      output_location_(),
      stack_bitmap_(nullptr),
      contains_call_(static_cast<ContainsCall>(d->Read<int8_t>())),
      live_registers_(d) {
  input_locations_ = d->zone()->Alloc<Location>(num_inputs_);
  for (intptr_t i = 0; i < num_inputs_; ++i) {
    input_locations_[i] = Location::Read(d);
  }
  temp_locations_ = d->zone()->Alloc<Location>(num_temps_);
  for (intptr_t i = 0; i < num_temps_; ++i) {
    temp_locations_[i] = Location::Read(d);
  }
  output_location_ = Location::Read(d);

  if (d->Read<int8_t>() != 0) {
    EnsureStackBitmap().Read(d->stream());
  }

#if defined(DEBUG)
  writable_inputs_ = d->Read<intptr_t>();
#endif
}

void MakeTempInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateDefinition::WriteExtra(s);
  null_->WriteExtra(s);
}

void MakeTempInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateDefinition::ReadExtra(d);
  null_->ReadExtra(d);
}

void MaterializeObjectInstr::WriteExtra(FlowGraphSerializer* s) {
  VariadicDefinition::WriteExtra(s);
  for (intptr_t i = 0, n = InputCount(); i < n; ++i) {
    locations_[i].Write(s);
  }
}

void MaterializeObjectInstr::ReadExtra(FlowGraphDeserializer* d) {
  VariadicDefinition::ReadExtra(d);
  locations_ = d->zone()->Alloc<Location>(InputCount());
  for (intptr_t i = 0, n = InputCount(); i < n; ++i) {
    locations_[i] = Location::Read(d);
  }
}

template <>
void FlowGraphSerializer::WriteTrait<MoveOperands*>::Write(
    FlowGraphSerializer* s,
    MoveOperands* x) {
  x->Write(s);
}

template <>
MoveOperands* FlowGraphDeserializer::ReadTrait<MoveOperands*>::Read(
    FlowGraphDeserializer* d) {
  return new (d->zone()) MoveOperands(d);
}

void MoveOperands::Write(FlowGraphSerializer* s) const {
  dest().Write(s);
  src().Write(s);
}

MoveOperands::MoveOperands(FlowGraphDeserializer* d)
    : dest_(Location::Read(d)), src_(Location::Read(d)) {}

template <>
void FlowGraphSerializer::
    WriteTrait<const compiler::ffi::NativeCallingConvention&>::Write(
        FlowGraphSerializer* s,
        const compiler::ffi::NativeCallingConvention& x) {
  // A subset of NativeCallingConvention currently used by CCallInstr.
  const auto& args = x.argument_locations();
  for (intptr_t i = 0, n = args.length(); i < n; ++i) {
    if (args.At(i)->payload_type().AsRepresentation() != kUnboxedFfiIntPtr) {
      UNIMPLEMENTED();
    }
  }
  if (x.return_location().payload_type().AsRepresentation() !=
      kUnboxedFfiIntPtr) {
    UNIMPLEMENTED();
  }
  s->Write<intptr_t>(args.length());
}

template <>
const compiler::ffi::NativeCallingConvention& FlowGraphDeserializer::ReadTrait<
    const compiler::ffi::NativeCallingConvention&>::Read(FlowGraphDeserializer*
                                                             d) {
  const intptr_t num_args = d->Read<intptr_t>();
  const auto& native_function_type =
      *compiler::ffi::NativeFunctionType::FromUnboxedRepresentation(
          d->zone(), num_args, kUnboxedFfiIntPtr);
  return compiler::ffi::NativeCallingConvention::FromSignature(
      d->zone(), native_function_type);
}

template <>
void FlowGraphSerializer::WriteTrait<const Object&>::Write(
    FlowGraphSerializer* s,
    const Object& x) {
  const intptr_t cid = x.GetClassId();
  ASSERT(cid != kIllegalCid);
  // Do not write objects repeatedly.
  const intptr_t object_id = s->heap()->GetObjectId(x.ptr());
  if (object_id > 0) {
    const intptr_t object_index = object_id - 1;
    s->Write<intptr_t>(kIllegalCid);
    s->Write<intptr_t>(object_index);
    return;
  }
  const intptr_t object_index = s->object_counter_++;
  s->heap()->SetObjectId(x.ptr(), object_index + 1);
  s->Write<intptr_t>(cid);
  s->WriteObjectImpl(x, cid, object_index);
}

template <>
const Object& FlowGraphDeserializer::ReadTrait<const Object&>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t cid = d->Read<intptr_t>();
  if (cid == kIllegalCid) {
    const intptr_t object_index = d->Read<intptr_t>();
    return *(d->objects_[object_index]);
  }
  const intptr_t object_index = d->object_counter_;
  d->object_counter_++;
  const Object& result = d->ReadObjectImpl(cid, object_index);
  d->SetObjectAt(object_index, result);
  return result;
}

void FlowGraphDeserializer::SetObjectAt(intptr_t object_index,
                                        const Object& object) {
  objects_.EnsureLength(object_index + 1, &Object::null_object());
  objects_[object_index] = &object;
}

bool FlowGraphSerializer::IsWritten(const Object& obj) {
  const intptr_t object_id = heap()->GetObjectId(obj.ptr());
  return (object_id != 0);
}

bool FlowGraphSerializer::HasEnclosingTypes(const Object& obj) {
  if (num_free_fun_type_params_ == 0) return false;
  if (obj.IsAbstractType()) {
    return !AbstractType::Cast(obj).IsInstantiated(kFunctions,
                                                   num_free_fun_type_params_);
  } else if (obj.IsTypeArguments()) {
    return !TypeArguments::Cast(obj).IsInstantiated(kFunctions,
                                                    num_free_fun_type_params_);
  } else {
    UNREACHABLE();
  }
}

bool FlowGraphSerializer::WriteObjectWithEnclosingTypes(const Object& obj) {
  if (HasEnclosingTypes(obj)) {
    Write<bool>(true);
    // Reset assigned object id so it could be written
    // while writing enclosing types.
    heap()->SetObjectId(obj.ptr(), -1);
    WriteEnclosingTypes(obj, num_free_fun_type_params_);
    Write<bool>(false);
    // Can write any type parameters after all enclosing types are written.
    const intptr_t saved_num_free_fun_type_params = num_free_fun_type_params_;
    num_free_fun_type_params_ = 0;
    Write<const Object&>(obj);
    num_free_fun_type_params_ = saved_num_free_fun_type_params;
    return true;
  } else {
    Write<bool>(false);
    return false;
  }
}

void FlowGraphSerializer::WriteEnclosingTypes(
    const Object& obj,
    intptr_t num_free_fun_type_params) {
  if (obj.IsType()) {
    const auto& type = Type::Cast(obj);
    if (type.arguments() != TypeArguments::null()) {
      const auto& type_args = TypeArguments::Handle(Z, type.arguments());
      WriteEnclosingTypes(type_args, num_free_fun_type_params);
    }
  } else if (obj.IsRecordType()) {
    const auto& rec = RecordType::Cast(obj);
    auto& elem = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = rec.NumFields(); i < n; ++i) {
      elem = rec.FieldTypeAt(i);
      WriteEnclosingTypes(elem, num_free_fun_type_params);
    }
  } else if (obj.IsFunctionType()) {
    const auto& sig = FunctionType::Cast(obj);
    const intptr_t num_parent_type_args = sig.NumParentTypeArguments();
    if (num_free_fun_type_params > num_parent_type_args) {
      num_free_fun_type_params = num_parent_type_args;
    }
    AbstractType& elem = AbstractType::Handle(Z, sig.result_type());
    WriteEnclosingTypes(elem, num_free_fun_type_params);
    for (intptr_t i = 0, n = sig.NumParameters(); i < n; ++i) {
      elem = sig.ParameterTypeAt(i);
      WriteEnclosingTypes(elem, num_free_fun_type_params);
    }
    if (sig.IsGeneric()) {
      const TypeParameters& type_params =
          TypeParameters::Handle(Z, sig.type_parameters());
      WriteEnclosingTypes(TypeArguments::Handle(Z, type_params.bounds()),
                          num_free_fun_type_params);
    }
  } else if (obj.IsTypeParameter()) {
    const auto& tp = TypeParameter::Cast(obj);
    if (tp.IsFunctionTypeParameter() &&
        (tp.index() < num_free_fun_type_params)) {
      const auto& owner =
          FunctionType::Handle(Z, tp.parameterized_function_type());
      if (!IsWritten(owner)) {
        Write<bool>(true);
        Write<const Object&>(owner);
      }
    }
  } else if (obj.IsTypeArguments()) {
    const auto& type_args = TypeArguments::Cast(obj);
    auto& elem = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = type_args.Length(); i < n; ++i) {
      elem = type_args.TypeAt(i);
      WriteEnclosingTypes(elem, num_free_fun_type_params);
    }
  }
}

const Object& FlowGraphDeserializer::ReadObjectWithEnclosingTypes() {
  if (Read<bool>()) {
    while (Read<bool>()) {
      Read<const Object&>();
    }
    return Read<const Object&>();
  } else {
    return Object::null_object();
  }
}

void FlowGraphSerializer::WriteObjectImpl(const Object& x,
                                          intptr_t cid,
                                          intptr_t object_index) {
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid: {
      const auto& array = Array::Cast(x);
      const intptr_t len = array.Length();
      Write<intptr_t>(len);
      const auto& type_args =
          TypeArguments::Handle(Z, array.GetTypeArguments());
      Write<const TypeArguments&>(type_args);
      if ((len == 0) && type_args.IsNull()) {
        break;
      }
      Write<bool>(array.IsCanonical());
      auto& elem = Object::Handle(Z);
      for (intptr_t i = 0; i < len; ++i) {
        elem = array.At(i);
        Write<const Object&>(elem);
      }
      break;
    }
    case kBoolCid:
      Write<bool>(Bool::Cast(x).value());
      break;
    case kClosureCid: {
      const auto& closure = Closure::Cast(x);
      if (closure.context() != Object::null()) {
        UNIMPLEMENTED();
      }
      ASSERT(closure.IsCanonical());
      auto& type_args = TypeArguments::Handle(Z);
      type_args = closure.instantiator_type_arguments();
      Write<const TypeArguments&>(type_args);
      type_args = closure.function_type_arguments();
      Write<const TypeArguments&>(type_args);
      type_args = closure.delayed_type_arguments();
      Write<const TypeArguments&>(type_args);
      Write<const Function&>(Function::Handle(Z, closure.function()));
      break;
    }
    case kDoubleCid:
      ASSERT(x.IsCanonical());
      Write<double>(Double::Cast(x).value());
      break;
    case kFieldCid: {
      const auto& field = Field::Cast(x);
      const auto& owner = Class::Handle(Z, field.Owner());
      Write<classid_t>(owner.id());
      const intptr_t field_index = owner.FindFieldIndex(field);
      ASSERT(field_index >= 0);
      Write<intptr_t>(field_index);
      break;
    }
    case kFunctionCid:
      Write<const Function&>(Function::Cast(x));
      break;
    case kFunctionTypeCid: {
      const auto& type = FunctionType::Cast(x);
      ASSERT(type.IsFinalized());
      if (WriteObjectWithEnclosingTypes(type)) {
        break;
      }
      const intptr_t saved_num_free_fun_type_params = num_free_fun_type_params_;
      const intptr_t num_parent_type_args = type.NumParentTypeArguments();
      if (num_free_fun_type_params_ > num_parent_type_args) {
        num_free_fun_type_params_ = num_parent_type_args;
      }
      Write<int8_t>(static_cast<int8_t>(type.nullability()));
      Write<uint32_t>(type.packed_parameter_counts());
      Write<uint16_t>(type.packed_type_parameter_counts());
      Write<const TypeParameters&>(
          TypeParameters::Handle(Z, type.type_parameters()));
      Write<const AbstractType&>(AbstractType::Handle(Z, type.result_type()));
      Write<const Array&>(Array::Handle(Z, type.parameter_types()));
      Write<const Array&>(Array::Handle(Z, type.named_parameter_names()));
      num_free_fun_type_params_ = saved_num_free_fun_type_params;
      break;
    }
    case kICDataCid: {
      const auto& icdata = ICData::Cast(x);
      Write<int8_t>(static_cast<int8_t>(icdata.rebind_rule()));
      Write<const Function&>(Function::Handle(Z, icdata.Owner()));
      Write<const Array&>(Array::Handle(Z, icdata.arguments_descriptor()));
      Write<intptr_t>(icdata.deopt_id());
      Write<intptr_t>(icdata.NumArgsTested());
      if (icdata.rebind_rule() == ICData::kStatic) {
        ASSERT(icdata.NumberOfChecks() == 1);
        Write<const Function&>(Function::Handle(Z, icdata.GetTargetAt(0)));
      } else if (icdata.rebind_rule() == ICData::kInstance) {
        if (icdata.NumberOfChecks() != 0) {
          UNIMPLEMENTED();
        }
        Write<const String&>(String::Handle(Z, icdata.target_name()));
      } else {
        UNIMPLEMENTED();
      }
      break;
    }
    case kConstMapCid:
    case kConstSetCid: {
      const auto& map = LinkedHashBase::Cast(x);
      ASSERT(map.IsCanonical());
      const intptr_t length = map.Length();
      Write<intptr_t>(length);
      Write<const TypeArguments&>(
          TypeArguments::Handle(Z, map.GetTypeArguments()));
      const auto& data = Array::Handle(Z, map.data());
      auto& elem = Object::Handle(Z);
      intptr_t used_data;
      if (cid == kConstMapCid) {
        used_data = length << 1;
      } else {
        used_data = length;
      }
      for (intptr_t i = 0; i < used_data; ++i) {
        elem = data.At(i);
        Write<const Object&>(elem);
      }
      break;
    }
    case kLibraryPrefixCid: {
      const auto& prefix = LibraryPrefix::Cast(x);
      const Library& library = Library::Handle(Z, prefix.importer());
      Write<classid_t>(Class::Handle(Z, library.toplevel_class()).id());
      Write<const String&>(String::Handle(Z, prefix.name()));
      break;
    }
    case kMintCid:
      ASSERT(x.IsCanonical());
      Write<int64_t>(Integer::Cast(x).AsInt64Value());
      break;
    case kNullCid:
      break;
    case kOneByteStringCid: {
      ASSERT(x.IsCanonical());
      const auto& str = String::Cast(x);
      const intptr_t length = str.Length();
      Write<intptr_t>(length);
      NoSafepointScope no_safepoint;
      uint8_t* latin1 = OneByteString::DataStart(str);
      stream_->WriteBytes(latin1, length);
      break;
    }
    case kRecordCid: {
      ASSERT(x.IsCanonical());
      const auto& record = Record::Cast(x);
      Write<RecordShape>(record.shape());
      auto& field = Object::Handle(Z);
      for (intptr_t i = 0, n = record.num_fields(); i < n; ++i) {
        field = record.FieldAt(i);
        Write<const Object&>(field);
      }
      break;
    }
    case kRecordTypeCid: {
      const auto& rec = RecordType::Cast(x);
      ASSERT(rec.IsFinalized());
      if (WriteObjectWithEnclosingTypes(rec)) {
        break;
      }
      Write<int8_t>(static_cast<int8_t>(rec.nullability()));
      Write<RecordShape>(rec.shape());
      Write<const Array&>(Array::Handle(Z, rec.field_types()));
      break;
    }
    case kSentinelCid:
      if (x.ptr() == Object::sentinel().ptr()) {
        Write<uint8_t>(0);
      } else if (x.ptr() == Object::transition_sentinel().ptr()) {
        Write<uint8_t>(1);
      } else if (x.ptr() == Object::optimized_out().ptr()) {
        Write<uint8_t>(2);
      } else {
        UNIMPLEMENTED();
      }
      break;
    case kSmiCid:
      Write<intptr_t>(Smi::Cast(x).Value());
      break;
    case kTwoByteStringCid: {
      ASSERT(x.IsCanonical());
      const auto& str = String::Cast(x);
      const intptr_t length = str.Length();
      Write<intptr_t>(length);
      NoSafepointScope no_safepoint;
      uint16_t* utf16 = TwoByteString::DataStart(str);
      stream_->WriteBytes(reinterpret_cast<const uint8_t*>(utf16),
                          length * sizeof(uint16_t));
      break;
    }
    case kTypeCid: {
      const auto& type = Type::Cast(x);
      ASSERT(type.IsFinalized());
      if (WriteObjectWithEnclosingTypes(type)) {
        break;
      }
      const auto& cls = Class::Handle(Z, type.type_class());
      Write<int8_t>(static_cast<int8_t>(type.nullability()));
      Write<classid_t>(type.type_class_id());
      if (cls.IsGeneric()) {
        const auto& type_args = TypeArguments::Handle(Z, type.arguments());
        Write<const TypeArguments&>(type_args);
      }
      break;
    }
    case kTypeArgumentsCid: {
      const auto& type_args = TypeArguments::Cast(x);
      ASSERT(type_args.IsFinalized());
      if (WriteObjectWithEnclosingTypes(type_args)) {
        break;
      }
      const intptr_t len = type_args.Length();
      Write<intptr_t>(len);
      auto& type = AbstractType::Handle(Z);
      for (intptr_t i = 0; i < len; ++i) {
        type = type_args.TypeAt(i);
        Write<const AbstractType&>(type);
      }
      break;
    }
    case kTypeParameterCid: {
      const auto& tp = TypeParameter::Cast(x);
      ASSERT(tp.IsFinalized());
      if (WriteObjectWithEnclosingTypes(tp)) {
        break;
      }
      Write<intptr_t>(tp.base());
      Write<intptr_t>(tp.index());
      Write<int8_t>(static_cast<int8_t>(tp.nullability()));
      if (tp.IsFunctionTypeParameter()) {
        Write<bool>(true);
        Write<const FunctionType&>(
            FunctionType::Handle(Z, tp.parameterized_function_type()));
      } else {
        Write<bool>(false);
        Write<const Class&>(Class::Handle(Z, tp.parameterized_class()));
      }
      break;
    }
    case kTypeParametersCid: {
      const auto& tps = TypeParameters::Cast(x);
      Write<const Array&>(Array::Handle(Z, tps.names()));
      Write<const Array&>(Array::Handle(Z, tps.flags()));
      Write<const TypeArguments&>(TypeArguments::Handle(Z, tps.bounds()));
      Write<const TypeArguments&>(TypeArguments::Handle(Z, tps.defaults()));
      break;
    }
    default: {
      const classid_t cid = x.GetClassId();
      if ((cid >= kNumPredefinedCids) || (cid == kInstanceCid)) {
        const auto& instance = Instance::Cast(x);
        ASSERT(instance.IsCanonical());
        const auto& cls =
            Class::Handle(Z, isolate_group()->class_table()->At(cid));
        const auto unboxed_fields_bitmap =
            isolate_group()->class_table()->GetUnboxedFieldsMapAt(cid);
        const intptr_t next_field_offset = cls.host_next_field_offset();
        auto& obj = Object::Handle(Z);
        for (intptr_t offset = Instance::NextFieldOffset();
             offset < next_field_offset; offset += kCompressedWordSize) {
          if (unboxed_fields_bitmap.Get(offset / kCompressedWordSize)) {
            if (kCompressedWordSize == 8) {
              Write<int64_t>(*reinterpret_cast<int64_t*>(
                  instance.RawFieldAddrAtOffset(offset)));
            } else {
              Write<int32_t>(*reinterpret_cast<int32_t*>(
                  instance.RawFieldAddrAtOffset(offset)));
            }
          } else {
            obj = instance.RawGetFieldAtOffset(offset);
            Write<const Object&>(obj);
          }
        }
        break;
      }
      FATAL("Unimplemented WriteObjectImpl for %s", x.ToCString());
    }
  }
}

const Object& FlowGraphDeserializer::ReadObjectImpl(intptr_t cid,
                                                    intptr_t object_index) {
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid: {
      const intptr_t len = Read<intptr_t>();
      const auto& type_args = Read<const TypeArguments&>();
      if ((len == 0) && type_args.IsNull()) {
        return Object::empty_array();
      }
      const bool canonicalize = Read<bool>();
      auto& array = Array::ZoneHandle(
          Z, Array::New(len, canonicalize ? Heap::kNew : Heap::kOld));
      if (!type_args.IsNull()) {
        array.SetTypeArguments(type_args);
      }
      for (intptr_t i = 0; i < len; ++i) {
        array.SetAt(i, Read<const Object&>());
      }
      if (cid == kImmutableArrayCid) {
        array.MakeImmutable();
      }
      if (canonicalize) {
        array ^= array.Canonicalize(thread());
      }
      return array;
    }
    case kBoolCid:
      return Bool::Get(Read<bool>());
    case kClosureCid: {
      const auto& instantiator_type_arguments = Read<const TypeArguments&>();
      const auto& function_type_arguments = Read<const TypeArguments&>();
      const auto& delayed_type_arguments = Read<const TypeArguments&>();
      const auto& function = Read<const Function&>();
      auto& closure = Closure::ZoneHandle(
          Z,
          Closure::New(instantiator_type_arguments, function_type_arguments,
                       delayed_type_arguments, function, Context::Handle(Z)));
      closure ^= closure.Canonicalize(thread());
      return closure;
    }
    case kDoubleCid:
      return Double::ZoneHandle(Z, Double::NewCanonical(Read<double>()));
    case kFieldCid: {
      const classid_t owner_class_id = Read<classid_t>();
      const intptr_t field_index = Read<intptr_t>();
      const auto& owner = Class::Handle(Z, GetClassById(owner_class_id));
      auto& result = Field::ZoneHandle(Z, owner.FieldFromIndex(field_index));
      ASSERT(!result.IsNull());
      return result;
    }
    case kFunctionCid:
      return Read<const Function&>();
    case kFunctionTypeCid: {
      const auto& enc_type = ReadObjectWithEnclosingTypes();
      if (!enc_type.IsNull()) {
        return enc_type;
      }
      const Nullability nullability = static_cast<Nullability>(Read<int8_t>());
      auto& result =
          FunctionType::ZoneHandle(Z, FunctionType::New(0, nullability));
      SetObjectAt(object_index, result);
      result.set_packed_parameter_counts(Read<uint32_t>());
      result.set_packed_type_parameter_counts(Read<uint16_t>());
      result.SetTypeParameters(Read<const TypeParameters&>());
      result.set_result_type(Read<const AbstractType&>());
      result.set_parameter_types(Read<const Array&>());
      result.set_named_parameter_names(Read<const Array&>());
      result.SetIsFinalized();
      result ^= result.Canonicalize(thread());
      return result;
    }
    case kICDataCid: {
      const ICData::RebindRule rebind_rule =
          static_cast<ICData::RebindRule>(Read<int8_t>());
      const auto& owner = Read<const Function&>();
      const auto& arguments_descriptor = Read<const Array&>();
      const intptr_t deopt_id = Read<intptr_t>();
      const intptr_t num_args_tested = Read<intptr_t>();

      if (rebind_rule == ICData::kStatic) {
        const auto& target = Read<const Function&>();
        return ICData::ZoneHandle(
            Z,
            ICData::NewForStaticCall(owner, target, arguments_descriptor,
                                     deopt_id, num_args_tested, rebind_rule));
      } else if (rebind_rule == ICData::kInstance) {
        const auto& target_name = Read<const String&>();
        return ICData::ZoneHandle(
            Z, ICData::New(owner, target_name, arguments_descriptor, deopt_id,
                           num_args_tested, rebind_rule));
      } else {
        UNIMPLEMENTED();
      }
      break;
    }
    case kConstMapCid:
    case kConstSetCid: {
      const intptr_t length = Read<intptr_t>();
      const auto& type_args = Read<const TypeArguments&>();
      Instance& result = Instance::ZoneHandle(Z);
      intptr_t used_data;
      if (cid == kConstMapCid) {
        result = ConstMap::NewUninitialized(Heap::kOld);
        used_data = (length << 1);
      } else {
        result = ConstSet::NewUninitialized(Heap::kOld);
        used_data = length;
      }
      // LinkedHashBase is not a proper handle type, so
      // cannot create a LinkedHashBase handle upfront.
      const LinkedHashBase& map = LinkedHashBase::Cast(result);
      map.SetTypeArguments(type_args);
      map.set_used_data(used_data);
      const auto& data = Array::Handle(Z, Array::New(used_data));
      map.set_data(data);
      map.set_deleted_keys(0);
      map.ComputeAndSetHashMask();
      for (intptr_t i = 0; i < used_data; ++i) {
        data.SetAt(i, Read<const Object&>());
      }
      result ^= result.Canonicalize(thread());
      return result;
    }
    case kLibraryPrefixCid: {
      const Class& toplevel_class =
          Class::Handle(Z, GetClassById(Read<classid_t>()));
      const Library& library = Library::Handle(Z, toplevel_class.library());
      const String& name = Read<const String&>();
      const auto& prefix =
          LibraryPrefix::ZoneHandle(Z, library.LookupLocalLibraryPrefix(name));
      ASSERT(!prefix.IsNull());
      return prefix;
    }
    case kMintCid: {
      const int64_t value = Read<int64_t>();
      return Integer::ZoneHandle(Z, Integer::NewCanonical(value));
    }
    case kNullCid:
      return Object::null_object();
    case kOneByteStringCid: {
      const intptr_t length = Read<intptr_t>();
      uint8_t* latin1 = Z->Alloc<uint8_t>(length);
      stream_->ReadBytes(latin1, length);
      return String::ZoneHandle(Z,
                                Symbols::FromLatin1(thread(), latin1, length));
    }
    case kRecordCid: {
      const RecordShape shape = Read<RecordShape>();
      auto& record = Record::ZoneHandle(Z, Record::New(shape));
      for (intptr_t i = 0, n = shape.num_fields(); i < n; ++i) {
        record.SetFieldAt(i, Read<const Object&>());
      }
      record ^= record.Canonicalize(thread());
      return record;
    }
    case kRecordTypeCid: {
      const auto& enc_type = ReadObjectWithEnclosingTypes();
      if (!enc_type.IsNull()) {
        return enc_type;
      }
      const Nullability nullability = static_cast<Nullability>(Read<int8_t>());
      const RecordShape shape = Read<RecordShape>();
      const Array& field_types = Read<const Array&>();
      RecordType& rec = RecordType::ZoneHandle(
          Z, RecordType::New(shape, field_types, nullability));
      rec.SetIsFinalized();
      rec ^= rec.Canonicalize(thread());
      return rec;
    }
    case kSentinelCid:
      switch (Read<uint8_t>()) {
        case 0:
          return Object::sentinel();
        case 1:
          return Object::transition_sentinel();
        case 2:
          return Object::optimized_out();
        default:
          UNREACHABLE();
      }
    case kSmiCid:
      return Smi::ZoneHandle(Z, Smi::New(Read<intptr_t>()));
    case kTwoByteStringCid: {
      const intptr_t length = Read<intptr_t>();
      uint16_t* utf16 = Z->Alloc<uint16_t>(length);
      stream_->ReadBytes(reinterpret_cast<uint8_t*>(utf16),
                         length * sizeof(uint16_t));
      return String::ZoneHandle(Z, Symbols::FromUTF16(thread(), utf16, length));
    }
    case kTypeCid: {
      const auto& enc_type = ReadObjectWithEnclosingTypes();
      if (!enc_type.IsNull()) {
        return enc_type;
      }
      const Nullability nullability = static_cast<Nullability>(Read<int8_t>());
      const classid_t type_class_id = Read<classid_t>();
      const auto& cls = Class::Handle(Z, GetClassById(type_class_id));
      auto& result = Type::ZoneHandle(Z);
      if (cls.IsGeneric()) {
        result = Type::New(cls, Object::null_type_arguments(), nullability);
        SetObjectAt(object_index, result);
        const auto& type_args = Read<const TypeArguments&>();
        result.set_arguments(type_args);
        result.SetIsFinalized();
      } else {
        result = cls.DeclarationType();
        result = result.ToNullability(nullability, Heap::kOld);
      }
      result ^= result.Canonicalize(thread());
      return result;
    }
    case kTypeArgumentsCid: {
      const auto& enc_type_args = ReadObjectWithEnclosingTypes();
      if (!enc_type_args.IsNull()) {
        return enc_type_args;
      }
      const intptr_t len = Read<intptr_t>();
      auto& type_args = TypeArguments::ZoneHandle(Z, TypeArguments::New(len));
      SetObjectAt(object_index, type_args);
      for (intptr_t i = 0; i < len; ++i) {
        type_args.SetTypeAt(i, Read<const AbstractType&>());
      }
      type_args ^= type_args.Canonicalize(thread());
      return type_args;
    }
    case kTypeParameterCid: {
      const auto& enc_type = ReadObjectWithEnclosingTypes();
      if (!enc_type.IsNull()) {
        return enc_type;
      }
      const intptr_t base = Read<intptr_t>();
      const intptr_t index = Read<intptr_t>();
      const Nullability nullability = static_cast<Nullability>(Read<int8_t>());
      const Object* owner = nullptr;
      if (Read<bool>()) {
        owner = &Read<const FunctionType&>();
      } else {
        owner = &Read<const Class&>();
      }
      auto& tp = TypeParameter::ZoneHandle(
          Z, TypeParameter::New(*owner, base, index, nullability));
      SetObjectAt(object_index, tp);
      tp.SetIsFinalized();
      tp ^= tp.Canonicalize(thread());
      return tp;
    }
    case kTypeParametersCid: {
      const auto& tps = TypeParameters::ZoneHandle(Z, TypeParameters::New());
      tps.set_names(Read<const Array&>());
      tps.set_flags(Read<const Array&>());
      tps.set_bounds(Read<const TypeArguments&>());
      tps.set_defaults(Read<const TypeArguments&>());
      return tps;
    }
    default:
      if ((cid >= kNumPredefinedCids) || (cid == kInstanceCid)) {
        const auto& cls = Class::Handle(Z, GetClassById(cid));
        const auto unboxed_fields_bitmap =
            isolate_group()->class_table()->GetUnboxedFieldsMapAt(cid);
        const intptr_t next_field_offset = cls.host_next_field_offset();
        auto& instance = Instance::ZoneHandle(Z, Instance::New(cls));
        for (intptr_t offset = Instance::NextFieldOffset();
             offset < next_field_offset; offset += kCompressedWordSize) {
          if (unboxed_fields_bitmap.Get(offset / kCompressedWordSize)) {
            if (kCompressedWordSize == 8) {
              const int64_t v = Read<int64_t>();
              *reinterpret_cast<int64_t*>(
                  instance.RawFieldAddrAtOffset(offset)) = v;
            } else {
              const int32_t v = Read<int32_t>();
              *reinterpret_cast<int32_t*>(
                  instance.RawFieldAddrAtOffset(offset)) = v;
            }
          } else {
            const auto& obj = Read<const Object&>();
            instance.RawSetFieldAtOffset(offset, obj);
          }
        }
        instance = instance.Canonicalize(thread());
        return instance;
      }
  }
  UNIMPLEMENTED();
  return Object::null_object();
}

#define HANDLES_SERIALIZABLE_AS_OBJECT(V)                                      \
  V(AbstractType, Object::null_abstract_type())                                \
  V(Array, Object::null_array())                                               \
  V(Field, Field::Handle(d->zone()))                                           \
  V(FunctionType, Object::null_function_type())                                \
  V(Instance, Object::null_instance())                                         \
  V(String, Object::null_string())                                             \
  V(TypeArguments, Object::null_type_arguments())                              \
  V(TypeParameters, TypeParameters::Handle(d->zone()))

#define SERIALIZE_HANDLE_AS_OBJECT(handle, null_handle)                        \
  template <>                                                                  \
  void FlowGraphSerializer::WriteTrait<const handle&>::Write(                  \
      FlowGraphSerializer* s, const handle& x) {                               \
    s->Write<const Object&>(x);                                                \
  }                                                                            \
  template <>                                                                  \
  const handle& FlowGraphDeserializer::ReadTrait<const handle&>::Read(         \
      FlowGraphDeserializer* d) {                                              \
    const Object& result = d->Read<const Object&>();                           \
    if (result.IsNull()) {                                                     \
      return null_handle;                                                      \
    }                                                                          \
    return handle::Cast(result);                                               \
  }

HANDLES_SERIALIZABLE_AS_OBJECT(SERIALIZE_HANDLE_AS_OBJECT)
#undef SERIALIZE_HANDLE_AS_OBJECT
#undef HANDLES_SERIALIZABLE_AS_OBJECT

void OsrEntryInstr::WriteTo(FlowGraphSerializer* s) {
  BlockEntryWithInitialDefs::WriteTo(s);
}

OsrEntryInstr::OsrEntryInstr(FlowGraphDeserializer* d)
    : BlockEntryWithInitialDefs(d), graph_entry_(d->graph_entry()) {}

void ParallelMoveInstr::WriteExtra(FlowGraphSerializer* s) {
  Instruction::WriteExtra(s);
  s->Write<GrowableArray<MoveOperands*>>(moves_);
  s->Write<const MoveSchedule*>(move_schedule_);
}

void ParallelMoveInstr::ReadExtra(FlowGraphDeserializer* d) {
  Instruction::ReadExtra(d);
  moves_ = d->Read<GrowableArray<MoveOperands*>>();
  move_schedule_ = d->Read<const MoveSchedule*>();
}

void PhiInstr::WriteTo(FlowGraphSerializer* s) {
  VariadicDefinition::WriteTo(s);
  s->Write<Representation>(representation_);
  s->Write<bool>(is_alive_);
  s->Write<int8_t>(is_receiver_);
}

PhiInstr::PhiInstr(FlowGraphDeserializer* d)
    : VariadicDefinition(d),
      block_(d->current_block()->AsJoinEntry()),
      representation_(d->Read<Representation>()),
      is_alive_(d->Read<bool>()),
      is_receiver_(d->Read<int8_t>()) {}

template <>
void FlowGraphSerializer::WriteTrait<Range*>::Write(FlowGraphSerializer* s,
                                                    Range* x) {
  if (x == nullptr) {
    s->Write<bool>(false);
  } else {
    s->Write<bool>(true);
    x->Write(s);
  }
}

template <>
Range* FlowGraphDeserializer::ReadTrait<Range*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return new (d->zone()) Range(d);
}

void Range::Write(FlowGraphSerializer* s) const {
  min_.Write(s);
  max_.Write(s);
}

Range::Range(FlowGraphDeserializer* d)
    : min_(RangeBoundary(d)), max_(RangeBoundary(d)) {}

void RangeBoundary::Write(FlowGraphSerializer* s) const {
  s->Write<int8_t>(kind_);
  s->Write<int64_t>(value_);
  s->Write<int64_t>(offset_);
}

RangeBoundary::RangeBoundary(FlowGraphDeserializer* d)
    : kind_(static_cast<Kind>(d->Read<int8_t>())),
      value_(d->Read<int64_t>()),
      offset_(d->Read<int64_t>()) {}

template <>
void FlowGraphSerializer::WriteTrait<RecordShape>::Write(FlowGraphSerializer* s,
                                                         RecordShape x) {
  s->Write<intptr_t>(x.num_fields());
  s->Write<const Array&>(
      Array::Handle(s->zone(), x.GetFieldNames(s->thread())));
}

template <>
RecordShape FlowGraphDeserializer::ReadTrait<RecordShape>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t num_fields = d->Read<intptr_t>();
  const auto& field_names = d->Read<const Array&>();
  return RecordShape::Register(d->thread(), num_fields, field_names);
}

void RegisterSet::Write(FlowGraphSerializer* s) const {
  s->Write<uintptr_t>(cpu_registers_.data());
  s->Write<uintptr_t>(untagged_cpu_registers_.data());
  s->Write<uintptr_t>(fpu_registers_.data());
}

RegisterSet::RegisterSet(FlowGraphDeserializer* d)
    : cpu_registers_(d->Read<uintptr_t>()),
      untagged_cpu_registers_(d->Read<uintptr_t>()),
      fpu_registers_(d->Read<uintptr_t>()) {}

template <>
void FlowGraphSerializer::WriteTrait<Representation>::Write(
    FlowGraphSerializer* s,
    Representation x) {
  s->Write<uint8_t>(x);
}

template <>
Representation FlowGraphDeserializer::ReadTrait<Representation>::Read(
    FlowGraphDeserializer* d) {
  return static_cast<Representation>(d->Read<uint8_t>());
}

template <>
void FlowGraphSerializer::WriteTrait<const Slot&>::Write(FlowGraphSerializer* s,
                                                         const Slot& x) {
  x.Write(s);
}

template <>
const Slot& FlowGraphDeserializer::ReadTrait<const Slot&>::Read(
    FlowGraphDeserializer* d) {
  return Slot::Read(d);
}

template <>
void FlowGraphSerializer::WriteTrait<const Slot*>::Write(FlowGraphSerializer* s,
                                                         const Slot* x) {
  if (x == nullptr) {
    s->Write<bool>(false);
    return;
  }
  s->Write<bool>(true);
  x->Write(s);
}

template <>
const Slot* FlowGraphDeserializer::ReadTrait<const Slot*>::Read(
    FlowGraphDeserializer* d) {
  if (!d->Read<bool>()) {
    return nullptr;
  }
  return &Slot::Read(d);
}

void Slot::Write(FlowGraphSerializer* s) const {
  s->Write<serializable_type_t<Kind>>(
      static_cast<serializable_type_t<Kind>>(kind_));

  switch (kind_) {
    case Kind::kTypeArguments:
      s->Write<int8_t>(flags_);
      s->Write<intptr_t>(offset_in_bytes_);
      break;
    case Kind::kTypeArgumentsIndex:
      s->Write<intptr_t>(offset_in_bytes_);
      break;
    case Kind::kArrayElement:
      s->Write<intptr_t>(offset_in_bytes_);
      break;
    case Kind::kRecordField:
      s->Write<intptr_t>(offset_in_bytes_);
      break;
    case Kind::kCapturedVariable:
      s->Write<int8_t>(flags_);
      s->Write<intptr_t>(offset_in_bytes_);
      s->Write<const String&>(*DataAs<const String>());
      type_.Write(s);
      break;
    case Kind::kDartField:
      s->Write<const Field&>(field());
      break;
    default:
      break;
  }
}

const Slot& Slot::Read(FlowGraphDeserializer* d) {
  const Kind kind = static_cast<Kind>(d->Read<serializable_type_t<Kind>>());
  int8_t flags = 0;
  intptr_t offset = -1;
  const void* data = nullptr;
  CompileType type = CompileType::None();
  Representation representation = kTagged;

  switch (kind) {
    case Kind::kTypeArguments:
      flags = d->Read<int8_t>();
      offset = d->Read<intptr_t>();
      data = ":type_arguments";
      type = CompileType::FromCid(kTypeArgumentsCid);
      break;
    case Kind::kTypeArgumentsIndex:
      flags =
          IsImmutableBit::encode(true) |
          IsCompressedBit::encode(TypeArguments::ContainsCompressedPointers());
      offset = d->Read<intptr_t>();
      data = ":argument";
      type = CompileType(CompileType::kCannotBeNull,
                         CompileType::kCannotBeSentinel, kDynamicCid, nullptr);
      break;
    case Kind::kArrayElement:
      flags = IsCompressedBit::encode(Array::ContainsCompressedPointers());
      offset = d->Read<intptr_t>();
      data = ":array_element";
      type = CompileType::Dynamic();
      break;
    case Kind::kRecordField:
      flags = IsCompressedBit::encode(Record::ContainsCompressedPointers());
      offset = d->Read<intptr_t>();
      data = ":record_field";
      type = CompileType::Dynamic();
      break;
    case Kind::kCapturedVariable:
      flags = d->Read<int8_t>();
      offset = d->Read<intptr_t>();
      data = &d->Read<const String&>();
      type = CompileType(d);
      break;
    case Kind::kDartField: {
      const Field& field = d->Read<const Field&>();
      return Slot::Get(field, &d->parsed_function());
    }
    default:
      return Slot::GetNativeSlot(kind);
  }

  return GetCanonicalSlot(d->thread(), kind, flags, offset, data, type,
                          representation);
}

template <>
void FlowGraphSerializer::WriteTrait<const compiler::TableSelector*>::Write(
    FlowGraphSerializer* s,
    const compiler::TableSelector* x) {
#if defined(DART_PRECOMPILER)
  ASSERT(x != nullptr);
  s->Write<int32_t>(x->id);
#else
  UNREACHABLE();
#endif
}

template <>
const compiler::TableSelector*
FlowGraphDeserializer::ReadTrait<const compiler::TableSelector*>::Read(
    FlowGraphDeserializer* d) {
#if defined(DART_PRECOMPILER)
  const int32_t id = d->Read<int32_t>();
  const compiler::TableSelector* selector =
      Precompiler::Instance()->selector_map()->GetSelector(id);
  ASSERT(selector != nullptr);
  return selector;
#else
  UNREACHABLE();
#endif
}

void SpecialParameterInstr::WriteExtra(FlowGraphSerializer* s) {
  TemplateDefinition::WriteExtra(s);
  s->WriteRef<BlockEntryInstr*>(block_);
}

void SpecialParameterInstr::ReadExtra(FlowGraphDeserializer* d) {
  TemplateDefinition::ReadExtra(d);
  block_ = d->ReadRef<BlockEntryInstr*>();
}

template <intptr_t kExtraInputs>
void TemplateDartCall<kExtraInputs>::WriteExtra(FlowGraphSerializer* s) {
  VariadicDefinition::WriteExtra(s);
  if (move_arguments_ == nullptr) {
    s->Write<intptr_t>(-1);
  } else {
    s->Write<intptr_t>(move_arguments_->length());
#if defined(DEBUG)
    // Verify that MoveArgument instructions are inserted immediately
    // before this instruction. ReadExtra below relies on
    // that when restoring move_arguments_.
    Instruction* instr = this;
    for (intptr_t i = move_arguments_->length() - 1; i >= 0; --i) {
      do {
        instr = instr->previous();
        ASSERT(instr != nullptr);
      } while (!instr->IsMoveArgument());
      ASSERT(instr == (*move_arguments_)[i]);
    }
#endif
  }
}

template <intptr_t kExtraInputs>
void TemplateDartCall<kExtraInputs>::ReadExtra(FlowGraphDeserializer* d) {
  VariadicDefinition::ReadExtra(d);
  const intptr_t num_move_args = d->Read<intptr_t>();
  if (num_move_args >= 0) {
    move_arguments_ =
        new (d->zone()) MoveArgumentsArray(d->zone(), num_move_args);
    move_arguments_->EnsureLength(num_move_args, nullptr);
    Instruction* instr = this;
    for (int i = num_move_args - 1; i >= 0; --i) {
      do {
        instr = instr->previous();
        ASSERT(instr != nullptr);
      } while (!instr->IsMoveArgument());
      (*move_arguments_)[i] = instr->AsMoveArgument();
    }
    if (env() != nullptr) {
      RepairArgumentUsesInEnvironment();
    }
  }
}

// Explicit template instantiations, needed for the methods above.
template class TemplateDartCall<0>;
template class TemplateDartCall<1>;

template <>
void FlowGraphSerializer::WriteTrait<TokenPosition>::Write(
    FlowGraphSerializer* s,
    TokenPosition x) {
  s->Write<int32_t>(x.Serialize());
}

template <>
TokenPosition FlowGraphDeserializer::ReadTrait<TokenPosition>::Read(
    FlowGraphDeserializer* d) {
  return TokenPosition::Deserialize(d->Read<int32_t>());
}

template <>
void FlowGraphSerializer::WriteTrait<uint8_t>::Write(FlowGraphSerializer* s,
                                                     uint8_t x) {
  s->stream()->Write<uint8_t>(x);
}

template <>
uint8_t FlowGraphDeserializer::ReadTrait<uint8_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<uint8_t>();
}

template <>
void FlowGraphSerializer::WriteTrait<uint16_t>::Write(FlowGraphSerializer* s,
                                                      uint16_t x) {
  s->stream()->Write<uint16_t>(x);
}

template <>
uint16_t FlowGraphDeserializer::ReadTrait<uint16_t>::Read(
    FlowGraphDeserializer* d) {
  return d->stream()->Read<uint16_t>();
}

template <>
void FlowGraphSerializer::WriteTrait<uint32_t>::Write(FlowGraphSerializer* s,
                                                      uint32_t x) {
  s->stream()->Write<int32_t>(static_cast<int32_t>(x));
}

template <>
uint32_t FlowGraphDeserializer::ReadTrait<uint32_t>::Read(
    FlowGraphDeserializer* d) {
  return static_cast<uint32_t>(d->stream()->Read<int32_t>());
}

template <>
void FlowGraphSerializer::WriteTrait<uint64_t>::Write(FlowGraphSerializer* s,
                                                      uint64_t x) {
  s->stream()->Write<int64_t>(static_cast<int64_t>(x));
}

template <>
uint64_t FlowGraphDeserializer::ReadTrait<uint64_t>::Read(
    FlowGraphDeserializer* d) {
  return static_cast<uint64_t>(d->stream()->Read<int64_t>());
}

void UnboxedConstantInstr::WriteTo(FlowGraphSerializer* s) {
  ConstantInstr::WriteTo(s);
  s->Write<Representation>(representation_);
  // constant_address_ is not written - it is restored when reading.
}

UnboxedConstantInstr::UnboxedConstantInstr(FlowGraphDeserializer* d)
    : ConstantInstr(d),
      representation_(d->Read<Representation>()),
      constant_address_(0) {
  if (representation_ == kUnboxedDouble) {
    ASSERT(value().IsDouble());
    constant_address_ = FindDoubleConstant(Double::Cast(value()).value());
  }
}

template <>
void FlowGraphSerializer::WriteTrait<Value*>::Write(FlowGraphSerializer* s,
                                                    Value* x) {
  ASSERT(s->can_write_refs());
  CompileType* reaching_type = x->reaching_type();
  Definition* def = x->definition();
  // Omit reaching type if it is the same as definition type.
  if ((reaching_type != nullptr) && def->HasType() &&
      (reaching_type == def->Type())) {
    reaching_type = nullptr;
  }
  s->Write<CompileType*>(reaching_type);
  s->WriteRef<Definition*>(def);
}

template <>
Value* FlowGraphDeserializer::ReadTrait<Value*>::Read(
    FlowGraphDeserializer* d) {
  CompileType* type = d->Read<CompileType*>();
  Definition* def = d->ReadRef<Definition*>();
  Value* value = new (d->zone()) Value(def);
  value->SetReachingType(type);
  return value;
}

void VariadicDefinition::WriteTo(FlowGraphSerializer* s) {
  Definition::WriteTo(s);
  s->Write<intptr_t>(inputs_.length());
}

VariadicDefinition::VariadicDefinition(FlowGraphDeserializer* d)
    : Definition(d), inputs_(d->zone(), 0) {
  const intptr_t num_inputs = d->Read<intptr_t>();
  inputs_.EnsureLength(num_inputs, nullptr);
}

}  // namespace dart
