// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_deserializer.h"

#include "vm/compiler/backend/il_serializer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(bool,
            trace_round_trip_serialization,
            false,
            "Trace round trip serialization.");
DEFINE_FLAG(bool,
            trace_round_trip_serialization_skips,
            false,
            "Trace decisions to skip round trip serialization.");

void FlowGraphDeserializer::RoundTripSerialization(CompilerPassState* state) {
  auto const flow_graph = state->flow_graph;
  auto const inst =
      FlowGraphDeserializer::FirstUnhandledInstruction(flow_graph);
  if (inst != nullptr) {
    if (FLAG_trace_round_trip_serialization_skips) {
      THR_Print("Cannot serialize graph due to instruction: %s\n",
                inst->DebugName());
      if (auto const const_inst = inst->AsConstant()) {
        THR_Print("Constant value: %s\n", const_inst->value().ToCString());
      }
    }
    return;
  }

  // The deserialized flow graph must be in the same zone as the original flow
  // graph, to ensure it has the right lifetime. Thus, we leave an explicit
  // use of [flow_graph->zone()] in the deserializer construction.
  //
  // Otherwise, it would be nice to use a StackZone to limit the lifetime of the
  // serialized form (and other values created with this [zone] variable), since
  // it only needs to live for the dynamic extent of this method.
  //
  // However, creating a StackZone for it also changes the zone associated with
  // the thread. Also, some parts of the VM used in later updates to the
  // deserializer implicitly pick up the zone to use either from a passed-in
  // thread or the current thread instead of taking an explicit zone.
  //
  // For now, just serialize into the same zone as the original flow graph, and
  // we can revisit this if this causes a performance issue or if we can ensure
  // that those VM parts mentioned can be passed an explicit zone.
  Zone* const zone = flow_graph->zone();

  auto const sexp = FlowGraphSerializer::SerializeToSExp(zone, flow_graph);
  if (FLAG_trace_round_trip_serialization) {
    THR_Print("----- Serialized flow graph:\n");
    TextBuffer buf(1000);
    sexp->SerializeTo(zone, &buf, "");
    THR_Print("%s\n", buf.buf());
    THR_Print("----- END Serialized flow graph\n");
  }

  // For the deserializer, use the thread from the compiler pass and zone
  // associated with the existing flow graph to make sure the new flow graph
  // has the right lifetime.
  FlowGraphDeserializer d(state->thread, flow_graph->zone(), sexp,
                          &flow_graph->parsed_function());
  auto const new_graph = d.ParseFlowGraph();
  if (FLAG_trace_round_trip_serialization) {
    if (new_graph == nullptr) {
      THR_Print("Failure during deserialization: %s\n", d.error_message());
      THR_Print("At S-expression %s\n", d.error_sexp()->ToCString(zone));
    } else {
      THR_Print("Successfully deserialized graph for %s\n",
                sexp->AsList()->At(1)->AsSymbol()->value());
    }
  }
  if (new_graph != nullptr) state->flow_graph = new_graph;
}

#define HANDLED_CASE(name)                                                     \
  if (inst->Is##name()) return true;
static bool IsHandledInstruction(Instruction* inst) {
  FOR_EACH_HANDLED_BLOCK_TYPE_IN_DESERIALIZER(HANDLED_CASE)
  FOR_EACH_HANDLED_INSTRUCTION_IN_DESERIALIZER(HANDLED_CASE)
  return false;
}
#undef HANDLED_CASE

Instruction* FlowGraphDeserializer::FirstUnhandledInstruction(
    const FlowGraph* graph) {
  ASSERT(graph != nullptr);
  for (auto block_it = graph->reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    auto const entry = block_it.Current();
    if (!IsHandledInstruction(entry)) return entry;
    // The constant pool (the initial definitions of the graph entry block) is
    // handled differently from other constant definitions, and there are no
    // body instructions for a graph entry block. We should still make sure the
    // values in the constant pool are serializable though.
    if (auto const graph_entry = entry->AsGraphEntry()) {
      auto const defs = graph_entry->initial_definitions();
      for (intptr_t i = 0; i < defs->length(); i++) {
        ASSERT(defs->At(i)->IsConstant());
        auto const current = defs->At(i)->AsConstant();
        if (!IsHandledConstant(current->value())) return current;
      }
      continue;
    }
    if (auto const def_block = entry->AsBlockEntryWithInitialDefs()) {
      auto const defs = def_block->initial_definitions();
      for (intptr_t i = 0; i < defs->length(); i++) {
        auto const current = defs->At(i);
        if (!IsHandledInstruction(current)) return current;
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      auto current = it.Current();
      if (!IsHandledInstruction(current)) return current;
    }
  }
  return nullptr;
}

// Keep in sync with work in ParseDartValue. Right now, this is just a shallow
// check, not a deep one.
bool FlowGraphDeserializer::IsHandledConstant(const Object& obj) {
  return obj.IsNull() || obj.IsBool() || obj.IsString() || obj.IsInteger() ||
         obj.IsDouble() || obj.IsClass() || obj.IsType() ||
         obj.IsTypeArguments();
}

SExpression* FlowGraphDeserializer::Retrieve(SExpList* list, intptr_t index) {
  if (list == nullptr) return nullptr;
  if (list->Length() <= index) {
    StoreError(list, "expected at least %" Pd " element(s) in list", index + 1);
    return nullptr;
  }
  auto const elem = list->At(index);
  if (elem == nullptr) {
    StoreError(list, "null value at index %" Pd "", index);
  }
  return elem;
}

SExpression* FlowGraphDeserializer::Retrieve(SExpList* list, const char* key) {
  if (list == nullptr) return nullptr;
  if (!list->ExtraHasKey(key)) {
    StoreError(list, "expected an extra info entry for key %s", key);
    return nullptr;
  }
  auto const elem = list->ExtraLookupValue(key);
  if (elem == nullptr) {
    StoreError(list, "null value for key %s", key);
  }
  return elem;
}

FlowGraph* FlowGraphDeserializer::ParseFlowGraph() {
  auto const root = CheckTaggedList(root_sexp_, "FlowGraph");
  if (root == nullptr) return nullptr;

  auto const name_sexp = CheckSymbol(Retrieve(root, 1));
  // TODO(sstrickl): If the FlowGraphDeserializer was constructed with a
  // non-null ParsedFunction, we should check that the name matches here.
  // If not, then we should create an appropriate ParsedFunction here.
  if (name_sexp == nullptr) return nullptr;

  intptr_t osr_id = Compiler::kNoOSRDeoptId;
  if (auto const osr_id_sexp = CheckInteger(root->ExtraLookupValue("osr_id"))) {
    osr_id = osr_id_sexp->value();
  }

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_id_sexp =
          CheckInteger(root->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_id_sexp->value();
  }

  auto const graph =
      new (zone()) GraphEntryInstr(*parsed_function_, osr_id, deopt_id);
  PrologueInfo pi(-1, -1);
  flow_graph_ = new (zone()) FlowGraph(*parsed_function_, graph, 0, pi);
  flow_graph_->CreateCommonConstants();

  intptr_t pos = 2;
  if (auto const pool = CheckTaggedList(Retrieve(root, pos), "Constants")) {
    if (!ParseConstantPool(pool)) return nullptr;
    pos++;
  }

  // The deopt environment for the graph entry may use entries from the
  // constant pool, so that must be parsed first.
  if (auto const env_sexp = CheckList(root->ExtraLookupValue("env"))) {
    auto const env = ParseEnvironment(env_sexp);
    if (env == nullptr) return nullptr;
    env->DeepCopyTo(zone(), graph);
  }

  auto const entries_sexp = CheckTaggedList(Retrieve(root, pos), "Entries");
  if (!ParseEntries(entries_sexp)) return nullptr;
  pos++;

  GrowableArray<BlockEntryInstr*> blocks(zone(), 2);
  for (intptr_t i = pos; i < root->Length(); i++) {
    auto const block_sexp = CheckTaggedList(Retrieve(root, i), "Block");
    auto const type_tag =
        CheckSymbol(block_sexp->ExtraLookupValue("block_type"));
    auto const block = ParseBlockHeader(block_sexp, type_tag);
    if (block == nullptr) return nullptr;
    blocks.Add(block);
  }
  // Double-check that blocks weren't inadvertently skipped or IDs repeated
  // and were appropriately added to the block_map_.
  ASSERT(blocks.length() == root->Length() - pos);
  ASSERT(block_map_.Length() == blocks.length());
  for (intptr_t i = pos; i < root->Length(); i++) {
    current_block_ = blocks.At(i - pos);
    if (!ParseBlockContents(root->At(i)->AsList())) {
      return nullptr;
    }
  }

  // Before we return the new graph, make sure all definitions were found for
  // all pending values.
  if (values_map_.Length() > 0) {
    auto it = values_map_.GetIterator();
    auto const kv = it.Next();
    StoreError(new (zone()) SExpInteger(kv->key),
               "no definition found for variable index in flow graph");
    return nullptr;
  }

  flow_graph_->set_max_block_id(max_block_id_);
  flow_graph_->set_current_ssa_temp_index(max_ssa_index_ + 1);
  // Now that the deserializer has finished re-creating all the blocks in the
  // flow graph, dominators must be recomputed before handing it off to the
  // caller. (They were were originally computed during FlowGraph construction,
  // which only had the GraphEntryInstr in it at that point.)
  flow_graph_->DiscoverBlocks();

  return flow_graph_;
}

bool FlowGraphDeserializer::ParseConstantPool(SExpList* pool) {
  ASSERT(flow_graph_ != nullptr);
  if (pool == nullptr) return false;
  for (intptr_t i = 1; i < pool->Length(); i++) {
    auto& obj = Object::ZoneHandle(zone());
    const auto def_sexp = CheckTaggedList(Retrieve(pool, i), "def");
    if (!ParseDartValue(Retrieve(def_sexp, 2), &obj)) return false;

    ConstantInstr* def = flow_graph_->GetConstant(obj);
    if (!ParseDefinitionWithParsedBody(def_sexp, def)) return false;
  }
  return true;
}

bool FlowGraphDeserializer::ParseEntries(SExpList* list) {
  ASSERT(flow_graph_ != nullptr);
  if (list == nullptr) return false;
  for (intptr_t i = 1; i < list->Length(); i++) {
    const auto entry = CheckTaggedList(Retrieve(list, i));
    if (entry == nullptr) return false;
    const auto tag = entry->At(0)->AsSymbol();
    if (ParseBlockHeader(entry, tag) == nullptr) return false;
  }
  return true;
}

bool FlowGraphDeserializer::ParseInitialDefinitions(SExpList* list) {
  ASSERT(current_block_ != nullptr);
  ASSERT(current_block_->IsBlockEntryWithInitialDefs());
  auto const block = current_block_->AsBlockEntryWithInitialDefs();
  if (list == nullptr) return false;
  for (intptr_t i = 2; i < list->Length(); i++) {
    const auto def_sexp = CheckTaggedList(Retrieve(list, i), "def");
    const auto def = ParseDefinition(def_sexp);
    if (def == nullptr) return false;
    flow_graph_->AddToInitialDefinitions(block, def);
  }
  return true;
}

BlockEntryInstr* FlowGraphDeserializer::ParseBlockHeader(SExpList* list,
                                                         SExpSymbol* tag) {
  ASSERT(flow_graph_ != nullptr);
  if (list == nullptr) return nullptr;

  auto const kind = FlowGraphSerializer::BlockEntryTagToKind(tag);

  intptr_t block_id;
  auto const id_sexp = CheckSymbol(Retrieve(list, 1));
  if (!ParseBlockId(id_sexp, &block_id)) return nullptr;
  if (block_id > max_block_id_) max_block_id_ = block_id;

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_int = CheckInteger(list->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_int->value();
  }
  intptr_t try_index = kInvalidTryIndex;
  if (auto const try_int = CheckInteger(list->ExtraLookupValue("try_index"))) {
    try_index = try_int->value();
  }

  BlockEntryInstr* block = nullptr;
  switch (kind) {
    case FlowGraphSerializer::kTarget:
      block = new (zone()) TargetEntryInstr(block_id, try_index, deopt_id);
      break;
    case FlowGraphSerializer::kNormal:
      // The Normal and Unchecked cases are the same except for the
      // set_XXX_entry call, so combine them.
      FALL_THROUGH;
    case FlowGraphSerializer::kUnchecked: {
      block = block_map_.LookupValue(block_id);
      // These blocks were already created during ParseEntries, so just
      // return the created block.
      if (block != nullptr) {
        ASSERT(block_id == block->block_id());
        return block;
      }
      auto const graph = flow_graph_->graph_entry();
      block =
          new (zone()) FunctionEntryInstr(graph, block_id, try_index, deopt_id);
      if (kind == FlowGraphSerializer::kUnchecked) {
        graph->set_unchecked_entry(block->AsFunctionEntry());
      } else {
        graph->set_normal_entry(block->AsFunctionEntry());
      }
      graph->AddDominatedBlock(block);
      current_block_ = block;
      if (!ParseInitialDefinitions(list)) return nullptr;
      break;
    }
    case FlowGraphSerializer::kInvalid:
      StoreError(tag, "invalid block entry tag");
      return nullptr;
    default:
      StoreError(tag, "unhandled block type");
      return nullptr;
  }

  // For blocks with initial definitions, this needs to be done after those
  // are parsed.
  if (auto const env_sexp = CheckList(list->ExtraLookupValue("env"))) {
    auto const env = ParseEnvironment(env_sexp);
    if (env == nullptr) return nullptr;
    env->DeepCopyTo(zone(), block);
  }

  if (block_map_.HasKey(block_id)) {
    StoreError(id_sexp, "duplicate definition of block");
    return nullptr;
  }
  block_map_.Insert(block_id, block);
  return block;
}

bool FlowGraphDeserializer::ParseBlockContents(SExpList* list) {
  ASSERT(current_block_ != nullptr);
  // All blocks are of the form (Block B# inst*), so the instructions start
  // at the second position of the S-expression.
  intptr_t pos = 2;

  // TODO(sstrickl): Handle phis appropriately. Earlier attempts changed
  // the serialization to separate them from the other definitions, but
  // we can also just check for them since they always appear as the first
  // definitions in a serialized JoinEntry block.

  for (intptr_t i = pos; i < list->Length(); i++) {
    auto const entry = CheckTaggedList(Retrieve(list, i));
    Instruction* inst = nullptr;
    if (strcmp(entry->At(0)->AsSymbol()->value(), "def") == 0) {
      inst = ParseDefinition(entry);
    } else {
      inst = ParseInstruction(entry);
    }
    if (inst == nullptr) return false;
    if (auto last = current_block_->last_instruction()) {
      last->AppendInstruction(inst);
    } else {
      current_block_->AppendInstruction(inst);
    }
    current_block_->set_last_instruction(inst);
  }

  return true;
}

bool FlowGraphDeserializer::ParseDefinitionWithParsedBody(SExpList* list,
                                                          Definition* def) {
  intptr_t index;
  auto const name_sexp = CheckSymbol(Retrieve(list, 1));
  if (name_sexp == nullptr) return false;

  if (ParseSSATemp(name_sexp, &index)) {
    if (definition_map_.HasKey(index)) {
      StoreError(list, "multiple definitions for the same SSA index");
      return false;
    }
    def->set_ssa_temp_index(index);
    if (index > max_ssa_index_) max_ssa_index_ = index;
  } else {
    // TODO(sstrickl): Add temp support for non-SSA computed graphs.
    StoreError(list, "unhandled name for definition");
    return false;
  }

  if (auto const type_sexp =
          CheckTaggedList(list->ExtraLookupValue("type"), "CompileType")) {
    CompileType* typ = ParseCompileType(type_sexp);
    if (typ == nullptr) return false;
    def->UpdateType(*typ);
  }

  definition_map_.Insert(index, def);
  FixPendingValues(index, def);
  return true;
}

Definition* FlowGraphDeserializer::ParseDefinition(SExpList* list) {
  auto const inst_sexp = CheckTaggedList(Retrieve(list, 2));
  Instruction* const inst = ParseInstruction(inst_sexp);
  if (inst == nullptr) return nullptr;
  if (auto const def = inst->AsDefinition()) {
    if (!ParseDefinitionWithParsedBody(list, def)) return nullptr;
    return def;
  } else {
    StoreError(list, "instruction cannot be body of definition");
    return nullptr;
  }
}

Instruction* FlowGraphDeserializer::ParseInstruction(SExpList* list) {
  if (list == nullptr) return nullptr;
  auto const tag = list->At(0)->AsSymbol();

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_int = CheckInteger(list->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_int->value();
  }
  CommonInstrInfo common_info = {deopt_id, TokenPosition::kNoSource};

  // Parse the environment before handling the instruction, as we may have
  // references to PushArguments and parsing the instruction may pop
  // PushArguments off the stack.
  Environment* env = nullptr;
  if (auto const env_sexp = CheckList(list->ExtraLookupValue("env"))) {
    env = ParseEnvironment(env_sexp);
    if (env == nullptr) return nullptr;
  }

  Instruction* inst = nullptr;

#define HANDLE_CASE(name)                                                      \
  case kHandled##name:                                                         \
    inst = Handle##name(list, common_info);                                    \
    break;
  switch (HandledInstructionForTag(tag)) {
    FOR_EACH_HANDLED_INSTRUCTION_IN_DESERIALIZER(HANDLE_CASE)
    case kHandledInvalid:
      StoreError(tag, "unhandled instruction");
      return nullptr;
  }
#undef HANDLE_CASE

  if (inst == nullptr) return nullptr;
  if (env != nullptr) env->DeepCopyTo(zone(), inst);
  return inst;
}

CheckStackOverflowInstr* FlowGraphDeserializer::HandleCheckStackOverflow(
    SExpList* sexp,
    const CommonInstrInfo& info) {
  intptr_t stack_depth = 0;
  if (auto const stack_sexp =
          CheckInteger(sexp->ExtraLookupValue("stack_depth"))) {
    stack_depth = stack_sexp->value();
  }

  intptr_t loop_depth = 0;
  if (auto const loop_sexp =
          CheckInteger(sexp->ExtraLookupValue("loop_depth"))) {
    loop_depth = loop_sexp->value();
  }

  auto kind = CheckStackOverflowInstr::kOsrAndPreemption;
  if (auto const kind_sexp = CheckSymbol(sexp->ExtraLookupValue("kind"))) {
    ASSERT(strcmp(kind_sexp->value(), "OsrOnly") == 0);
    kind = CheckStackOverflowInstr::kOsrOnly;
  }

  return new (zone()) CheckStackOverflowInstr(info.token_pos, stack_depth,
                                              loop_depth, info.deopt_id, kind);
}

ParameterInstr* FlowGraphDeserializer::HandleParameter(
    SExpList* sexp,
    const CommonInstrInfo& info) {
  ASSERT(current_block_ != nullptr);
  if (auto const index_sexp = CheckInteger(Retrieve(sexp, 1))) {
    return new (zone()) ParameterInstr(index_sexp->value(), current_block_);
  }
  return nullptr;
}

ReturnInstr* FlowGraphDeserializer::HandleReturn(SExpList* list,
                                                 const CommonInstrInfo& info) {
  Value* val = ParseValue(Retrieve(list, 1));
  if (val == nullptr) return nullptr;
  return new (zone()) ReturnInstr(info.token_pos, val, info.deopt_id);
}

SpecialParameterInstr* FlowGraphDeserializer::HandleSpecialParameter(
    SExpList* sexp,
    const CommonInstrInfo& info) {
  ASSERT(current_block_ != nullptr);
  auto const kind_sexp = CheckSymbol(Retrieve(sexp, 1));
  if (kind_sexp == nullptr) return nullptr;
  SpecialParameterInstr::SpecialParameterKind kind;
  if (!SpecialParameterInstr::KindFromCString(kind_sexp->value(), &kind)) {
    StoreError(kind_sexp, "unknown special parameter kind");
    return nullptr;
  }
  return new (zone())
      SpecialParameterInstr(kind, info.deopt_id, current_block_);
}

Value* FlowGraphDeserializer::ParseValue(SExpression* sexp) {
  auto name = sexp->AsSymbol();
  CompileType* type = nullptr;
  if (name == nullptr) {
    auto const list = CheckTaggedList(sexp, "value");
    name = CheckSymbol(Retrieve(list, 1));
    if (name == nullptr) return nullptr;
    if (auto const type_sexp =
            CheckTaggedList(list->ExtraLookupValue("type"), "CompileType")) {
      type = ParseCompileType(type_sexp);
      if (type == nullptr) return nullptr;
    }
  }
  intptr_t index;
  if (!ParseUse(name, &index)) return nullptr;
  auto const def = definition_map_.LookupValue(index);
  Value* val;
  if (def == nullptr) {
    val = AddPendingValue(index);
  } else {
    val = new (zone()) Value(def);
  }
  if (type != nullptr) val->SetReachingType(type);
  return val;
}

CompileType* FlowGraphDeserializer::ParseCompileType(SExpList* sexp) {
  // TODO(sstrickl): Currently we only print out nullable if it's false
  // (or during verbose printing). Switch this when NNBD is the standard.
  bool nullable = CompileType::kNullable;
  if (auto const nullable_sexp =
          CheckBool(sexp->ExtraLookupValue("nullable"))) {
    nullable = nullable_sexp->value() ? CompileType::kNullable
                                      : CompileType::kNonNullable;
  }

  // A cid as the second element means that the type is based off a concrete
  // class.
  intptr_t cid = kDynamicCid;
  if (sexp->Length() > 1) {
    if (auto const cid_sexp = CheckInteger(sexp->At(1))) {
      // TODO(sstrickl): Check that the cid is a valid cid.
      cid = cid_sexp->value();
    } else {
      return nullptr;
    }
  }

  AbstractType* type = nullptr;
  if (auto const type_sexp = CheckTaggedList(sexp->ExtraLookupValue("type"))) {
    auto& type_handle = AbstractType::ZoneHandle(zone());
    if (!ParseDartValue(type_sexp, &type_handle)) return nullptr;
    type = &type_handle;
  }
  return new (zone()) CompileType(nullable, cid, type);
}

Environment* FlowGraphDeserializer::ParseEnvironment(SExpList* list) {
  if (list == nullptr) return nullptr;
  intptr_t fixed_param_count = 0;
  if (auto const fpc_sexp =
          CheckInteger(list->ExtraLookupValue("fixed_param_count"))) {
    fixed_param_count = fpc_sexp->value();
  }
  Environment* outer_env = nullptr;
  if (auto const outer_sexp = CheckList(list->ExtraLookupValue("outer"))) {
    outer_env = ParseEnvironment(outer_sexp);
    if (outer_env == nullptr) return nullptr;
    if (auto const deopt_sexp =
            CheckInteger(outer_sexp->ExtraLookupValue("deopt_id"))) {
      outer_env->deopt_id_ = deopt_sexp->value();
    }
  }

  auto const env = new (zone()) Environment(list->Length(), fixed_param_count,
                                            *parsed_function_, outer_env);

  for (intptr_t i = 0; i < list->Length(); i++) {
    auto const sym = CheckSymbol(Retrieve(list, i));
    if (sym == nullptr) return nullptr;
    Definition* def = nullptr;
    intptr_t index;
    if (ParseUse(sym, &index)) {
      def = definition_map_.LookupValue(index);
      if (def == nullptr) {
        StoreError(sym, "no definition found for environment use");
        return nullptr;
      }
    } else {
      // TODO(sstrickl): Handle PushArgument references.
      StoreError(sym, "unexpected name in env list");
      return nullptr;
    }
    env->PushValue(new (zone()) Value(def));
  }

  return env;
}

bool FlowGraphDeserializer::ParseDartValue(SExpression* sexp, Object* out) {
  ASSERT(out != nullptr);
  if (sexp == nullptr) return false;
  *out = Object::null();

  // We'll use the null value in *out as a marker later, so go ahead and exit
  // early if we parse one.
  if (auto const sym = sexp->AsSymbol()) {
    if (strcmp(sym->value(), "null") == 0) return true;
  }

  // Other instance values may need to be canonicalized, so do that before
  // returning.
  if (auto const list = CheckTaggedList(sexp)) {
    auto const tag = list->At(0)->AsSymbol();
    if (strcmp(tag->value(), "Class") == 0) {
      auto const cid_sexp = CheckInteger(Retrieve(list, 1));
      if (cid_sexp == nullptr) return false;
      ClassTable* table = thread()->isolate()->class_table();
      if (!table->IsValidIndex(cid_sexp->value())) {
        StoreError(cid_sexp, "no class found for cid");
        return false;
      }
      *out = table->At(cid_sexp->value());
    } else if (strcmp(tag->value(), "Type") == 0) {
      if (const auto cls_sexp = CheckTaggedList(Retrieve(list, 1), "Class")) {
        auto& cls = Class::ZoneHandle(zone());
        if (!ParseDartValue(cls_sexp, &cls)) return false;
        auto& type_args = TypeArguments::ZoneHandle(zone());
        if (const auto ta_sexp = CheckTaggedList(
                list->ExtraLookupValue("type_args"), "TypeArguments")) {
          if (!ParseDartValue(ta_sexp, &type_args)) return false;
        }
        *out = Type::New(cls, type_args, TokenPosition::kNoSource, Heap::kOld);
        // Need to set this for canonicalization.
        Type::Cast(*out).SetIsFinalized();
      }
      // TODO(sstrickl): Handle types not derived from classes.
    } else if (strcmp(tag->value(), "TypeArguments") == 0) {
      *out = TypeArguments::New(list->Length() - 1, Heap::kOld);
      auto& typ = AbstractType::Handle(zone());
      for (intptr_t i = 1; i < list->Length(); i++) {
        if (!ParseDartValue(Retrieve(list, i), &typ)) return false;
        TypeArguments::Cast(*out).SetTypeAt(i - 1, typ);
      }
    }
  } else if (auto const b = sexp->AsBool()) {
    *out = Bool::Get(b->value()).raw();
  } else if (auto const str = sexp->AsString()) {
    *out = String::New(str->value(), Heap::kOld);
  } else if (auto const i = sexp->AsInteger()) {
    *out = Integer::New(i->value(), Heap::kOld);
  } else if (auto const d = sexp->AsDouble()) {
    *out = Double::New(d->value(), Heap::kOld);
  }

  // If we're here and still haven't gotten a non-null value, then something
  // went wrong. (Likely an unrecognized value.)
  if (out->IsNull()) {
    StoreError(sexp, "unhandled Dart value");
    return false;
  }

  if (out->IsInstance()) {
    const char* error_str = nullptr;
    // CheckAndCanonicalize uses the current zone for the passed in thread,
    // not an explicitly provided zone. This means we cannot be run in a context
    // where [thread()->zone()] does not match [zone()] (e.g., due to StackZone)
    // until this is addressed.
    *out = Instance::Cast(*out).CheckAndCanonicalize(thread(), &error_str);
    if (out->IsNull()) {
      if (error_str != nullptr) {
        StoreError(sexp, "error during canonicalization: %s", error_str);
      } else {
        StoreError(sexp, "unexpected error during canonicalization");
      }
      return false;
    }
  }
  return true;
}

bool FlowGraphDeserializer::ParseBlockId(SExpSymbol* sym, intptr_t* out) {
  return ParseSymbolAsPrefixedInt(sym, 'B', out);
}

bool FlowGraphDeserializer::ParseSSATemp(SExpSymbol* sym, intptr_t* out) {
  return ParseSymbolAsPrefixedInt(sym, 'v', out);
}

bool FlowGraphDeserializer::ParseUse(SExpSymbol* sym, intptr_t* out) {
  // TODO(sstrickl): Handle non-SSA temp uses.
  return ParseSSATemp(sym, out);
}

bool FlowGraphDeserializer::ParseSymbolAsPrefixedInt(SExpSymbol* sym,
                                                     char prefix,
                                                     intptr_t* out) {
  ASSERT(out != nullptr);
  if (sym == nullptr) return false;
  auto const name = sym->value();
  if (*name != prefix) {
    StoreError(sym, "expected symbol starting with '%c'", prefix);
    return false;
  }
  int64_t i;
  if (!OS::StringToInt64(name + 1, &i)) {
    StoreError(sym, "expected number following symbol prefix '%c'", prefix);
    return false;
  }
  *out = i;
  return true;
}

Value* FlowGraphDeserializer::AddPendingValue(intptr_t index) {
  ASSERT(flow_graph_ != nullptr);
  ASSERT(!definition_map_.HasKey(index));
  auto value_list = values_map_.LookupValue(index);
  if (value_list == nullptr) {
    value_list = new (zone()) ZoneGrowableArray<Value*>(zone(), 2);
    values_map_.Insert(index, value_list);
  }
  auto const val = new (zone()) Value(flow_graph_->constant_null());
  value_list->Add(val);
  return val;
}

void FlowGraphDeserializer::FixPendingValues(intptr_t index, Definition* def) {
  if (auto value_list = values_map_.LookupValue(index)) {
    for (intptr_t i = 0; i < value_list->length(); i++) {
      auto const val = value_list->At(i);
      val->BindTo(def);
    }
    values_map_.Remove(index);
  }
}

#define BASE_CHECK_DEF(name, type)                                             \
  SExp##name* FlowGraphDeserializer::Check##name(SExpression* sexp) {          \
    if (sexp == nullptr) return nullptr;                                       \
    if (!sexp->Is##name()) {                                                   \
      StoreError(sexp, "expected " #name);                                     \
      return nullptr;                                                          \
    }                                                                          \
    return sexp->As##name();                                                   \
  }

FOR_EACH_S_EXPRESSION(BASE_CHECK_DEF)

#undef BASE_CHECK_DEF

bool FlowGraphDeserializer::IsTag(SExpression* sexp, const char* label) {
  auto const sym = CheckSymbol(sexp);
  if (sym == nullptr) return false;
  if (label != nullptr && strcmp(label, sym->value()) != 0) {
    StoreError(sym, "expected symbol %s", label);
    return false;
  }
  return true;
}

SExpList* FlowGraphDeserializer::CheckTaggedList(SExpression* sexp,
                                                 const char* label) {
  auto const list = CheckList(sexp);
  const intptr_t tag_pos = 0;
  if (!IsTag(Retrieve(list, tag_pos), label)) return nullptr;
  return list;
}

void FlowGraphDeserializer::StoreError(SExpression* sexp,
                                       const char* format,
                                       ...) {
  va_list args;
  va_start(args, format);
  const char* const message = OS::VSCreate(zone(), format, args);
  va_end(args);
  error_sexp_ = sexp;
  error_message_ = message;
}

void FlowGraphDeserializer::ReportError() const {
  ASSERT(error_sexp_ != nullptr);
  ASSERT(error_message_ != nullptr);
  OS::PrintErr("Unable to deserialize flow_graph: %s\n", error_message_);
  OS::PrintErr("Error at S-expression %s\n", error_sexp_->ToCString(zone()));
  OS::Abort();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
