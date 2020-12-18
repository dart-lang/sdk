// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_deserializer.h"

#include "vm/compiler/backend/il_serializer.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/frontend/base_flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/flags.h"
#include "vm/json_writer.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(bool,
            trace_round_trip_serialization,
            false,
            "Print out tracing information during round trip serialization.");
DEFINE_FLAG(bool,
            print_json_round_trip_results,
            false,
            "Print out results of each round trip serialization in JSON form.");

// Contains the contents of a single round-trip result.
struct RoundTripResults : public ValueObject {
  explicit RoundTripResults(Zone* zone, const Function& func)
      : function(func), unhandled(zone, 2) {}

  // The function for which a flow graph was being parsed.
  const Function& function;
  // Whether the round trip succeeded.
  bool success = false;
  // An array of unhandled instructions found in the flow graph.
  GrowableArray<Instruction*> unhandled;
  // The serialized form of the flow graph, if computed.
  SExpression* serialized = nullptr;
  // The error information from the deserializer, if an error occurred.
  const char* error_message = nullptr;
  SExpression* error_sexp = nullptr;
};

// Return a textual description of how to find the sub-expression [to_find]
// inside a [root] S-Expression.
static const char* GetSExpressionPosition(Zone* zone,
                                          SExpression* root,
                                          SExpression* to_find) {
  // The S-expression to find _is_ the root, so no description is needed.
  if (root == to_find) return "";
  // The S-expression to find cannot be a sub-expression of the given root,
  // so return nullptr to signal this.
  if (!root->IsList()) return nullptr;
  auto const list = root->AsList();
  for (intptr_t i = 0, n = list->Length(); i < n; i++) {
    if (auto const str = GetSExpressionPosition(zone, list->At(i), to_find)) {
      return OS::SCreate(zone, "element %" Pd "%s%s", i,
                         *str == '\0' ? "" : " -> ", str);
    }
  }
  auto it = list->ExtraIterator();
  while (auto kv = it.Next()) {
    if (auto const str = GetSExpressionPosition(zone, kv->value, to_find)) {
      return OS::SCreate(zone, "label %s%s%s", kv->key,
                         *str == '\0' ? "" : " -> ", str);
    }
  }
  return nullptr;
}

static void PrintRoundTripResults(Zone* zone, const RoundTripResults& results) {
  // A few checks to make sure we'll print out enough info. First, if there are
  // no unhandled instructions, then we should have serialized the flow graph.
  ASSERT(!results.unhandled.is_empty() || results.serialized != nullptr);
  // If we failed, then either there are unhandled instructions or we have
  // an appropriate error message and sexp from the FlowGraphDeserializer.
  ASSERT(results.success || !results.unhandled.is_empty() ||
         (results.error_message != nullptr && results.error_sexp != nullptr));

  JSONWriter js;

  js.OpenObject();
  js.PrintProperty("function", results.function.ToFullyQualifiedCString());
  js.PrintPropertyBool("success", results.success);

  if (!results.unhandled.is_empty()) {
    CStringMap<intptr_t> count_map(zone);
    for (auto inst : results.unhandled) {
      auto const name = inst->DebugName();
      auto const old_count = count_map.LookupValue(name);
      count_map.Update({name, old_count + 1});
    }

    auto count_it = count_map.GetIterator();
    js.OpenObject("unhandled");
    while (auto kv = count_it.Next()) {
      js.PrintProperty64(kv->key, kv->value);
    }
    js.CloseObject();
  }

  if (results.serialized != nullptr) {
    TextBuffer buf(1000);
    results.serialized->SerializeTo(zone, &buf, "");
    js.PrintProperty("serialized", buf.buffer());
  }

  if (results.error_message != nullptr) {
    js.OpenObject("error");
    js.PrintProperty("message", results.error_message);

    ASSERT(results.error_sexp != nullptr);
    TextBuffer buf(1000);
    results.error_sexp->SerializeTo(zone, &buf, "");
    js.PrintProperty("expression", buf.buffer());

    auto const sexp_position =
        GetSExpressionPosition(zone, results.serialized, results.error_sexp);
    js.PrintProperty("path", sexp_position);
    js.CloseObject();
  }

  js.CloseObject();
  THR_Print("Results of round trip serialization: %s\n", js.buffer()->buffer());
}

void FlowGraphDeserializer::RoundTripSerialization(CompilerPassState* state) {
  auto const flow_graph = state->flow_graph();

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

  // Final flow graph, if we successfully serialize and deserialize.
  FlowGraph* new_graph = nullptr;

  // Stored information for printing results if requested.
  RoundTripResults results(zone, flow_graph->function());

  FlowGraphDeserializer::AllUnhandledInstructions(flow_graph,
                                                  &results.unhandled);
  if (results.unhandled.is_empty()) {
    results.serialized = FlowGraphSerializer::SerializeToSExp(zone, flow_graph);

    if (FLAG_trace_round_trip_serialization && results.serialized != nullptr) {
      TextBuffer buf(1000);
      results.serialized->SerializeTo(zone, &buf, "");
      THR_Print("Serialized flow graph:\n%s\n", buf.buffer());
    }

    // For the deserializer, use the thread from the compiler pass and zone
    // associated with the existing flow graph to make sure the new flow graph
    // has the right lifetime.
    FlowGraphDeserializer d(state->thread, flow_graph->zone(),
                            results.serialized, &flow_graph->parsed_function());
    new_graph = d.ParseFlowGraph();
    if (new_graph == nullptr) {
      ASSERT(d.error_message() != nullptr && d.error_sexp() != nullptr);
      if (FLAG_trace_round_trip_serialization) {
        THR_Print("Failure during deserialization: %s\n", d.error_message());
        THR_Print("At S-expression %s\n", d.error_sexp()->ToCString(zone));
        if (auto const pos = GetSExpressionPosition(zone, results.serialized,
                                                    d.error_sexp())) {
          THR_Print("Path from root: %s\n", pos);
        }
      }
      results.error_message = d.error_message();
      results.error_sexp = d.error_sexp();
    } else {
      if (FLAG_trace_round_trip_serialization) {
        THR_Print("Successfully deserialized graph for %s\n",
                  results.serialized->AsList()->At(1)->AsSymbol()->value());
      }
      results.success = true;
    }
  } else if (FLAG_trace_round_trip_serialization) {
    THR_Print("Cannot serialize graph due to instruction: %s\n",
              results.unhandled.At(0)->DebugName());
  }

  if (FLAG_print_json_round_trip_results) PrintRoundTripResults(zone, results);

  if (new_graph != nullptr) {
    state->set_flow_graph(new_graph);
  }
}

#define HANDLED_CASE(name)                                                     \
  if (inst->Is##name()) return true;
bool FlowGraphDeserializer::IsHandledInstruction(Instruction* inst) {
  if (auto const const_inst = inst->AsConstant()) {
    return IsHandledConstant(const_inst->value());
  }
  FOR_EACH_HANDLED_BLOCK_TYPE_IN_DESERIALIZER(HANDLED_CASE)
  FOR_EACH_HANDLED_INSTRUCTION_IN_DESERIALIZER(HANDLED_CASE)
  return false;
}
#undef HANDLED_CASE

void FlowGraphDeserializer::AllUnhandledInstructions(
    const FlowGraph* graph,
    GrowableArray<Instruction*>* unhandled) {
  ASSERT(graph != nullptr);
  ASSERT(unhandled != nullptr);
  for (auto block_it = graph->reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    auto const entry = block_it.Current();
    if (!IsHandledInstruction(entry)) unhandled->Add(entry);
    // Check that the Phi instructions in JoinEntrys do not have pair
    // representation.
    if (auto const join_block = entry->AsJoinEntry()) {
      auto const phis = join_block->phis();
      auto const length = ((phis == nullptr) ? 0 : phis->length());
      for (intptr_t i = 0; i < length; i++) {
        auto const current = phis->At(i);
        for (intptr_t j = 0; j < current->InputCount(); j++) {
          if (current->InputAt(j)->definition()->HasPairRepresentation()) {
            unhandled->Add(current);
          }
        }
      }
    }
    if (auto const def_block = entry->AsBlockEntryWithInitialDefs()) {
      auto const defs = def_block->initial_definitions();
      for (intptr_t i = 0; i < defs->length(); i++) {
        auto const current = defs->At(i);
        if (!IsHandledInstruction(current)) unhandled->Add(current);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      auto current = it.Current();
      // We handle branches, so we need to check the comparison instruction.
      if (current->IsBranch()) current = current->AsBranch()->comparison();
      if (!IsHandledInstruction(current)) unhandled->Add(current);
    }
  }
}

// Keep in sync with work in ParseDartValue. Right now, this is just a shallow
// check, not a deep one.
bool FlowGraphDeserializer::IsHandledConstant(const Object& obj) {
  if (obj.IsArray()) return Array::Cast(obj).IsImmutable();
  return obj.IsNull() || obj.IsClass() || obj.IsFunction() || obj.IsField() ||
         obj.IsInstance();
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

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_id_sexp =
          CheckInteger(root->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_id_sexp->value();
  }
  EntryInfo common_info = {0, kInvalidTryIndex, deopt_id};

  auto const graph = DeserializeGraphEntry(root, common_info);

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
    current_block_ = graph;
    auto const env = ParseEnvironment(env_sexp);
    if (env == nullptr) return nullptr;
    env->DeepCopyTo(zone(), graph);
  }

  auto const entries_sexp = CheckTaggedList(Retrieve(root, pos), "Entries");
  if (!ParseEntries(entries_sexp)) return nullptr;
  pos++;

  // Now prime the block worklist with entries. We keep the block worklist
  // in reverse order so that we can just pop the next block for content
  // parsing off the end.
  BlockWorklist block_worklist(zone(), entries_sexp->Length() - 1);

  const auto& indirect_entries = graph->indirect_entries();
  for (auto indirect_entry : indirect_entries) {
    block_worklist.Add(indirect_entry->block_id());
  }

  const auto& catch_entries = graph->catch_entries();
  for (auto catch_entry : catch_entries) {
    block_worklist.Add(catch_entry->block_id());
  }

  if (auto const osr_entry = graph->osr_entry()) {
    block_worklist.Add(osr_entry->block_id());
  }
  if (auto const unchecked_entry = graph->unchecked_entry()) {
    block_worklist.Add(unchecked_entry->block_id());
  }
  if (auto const normal_entry = graph->normal_entry()) {
    block_worklist.Add(normal_entry->block_id());
  }

  if (!ParseBlocks(root, pos, &block_worklist)) return nullptr;

  // Before we return the new graph, make sure all definitions were found for
  // all pending values.
  if (values_map_.Length() > 0) {
    auto it = values_map_.GetIterator();
    auto const kv = it.Next();
    ASSERT(kv->value->length() > 0);
    const auto& value_info = kv->value->At(0);
    StoreError(value_info.sexp, "no definition found for use in flow graph");
    return nullptr;
  }

  flow_graph_->set_max_block_id(max_block_id_);
  // The highest numbered SSA temp might need two slots (e.g. for unboxed
  // integers on 32-bit platforms), so we add 2 to the highest seen SSA temp
  // index to get to the new current SSA temp index. In cases where the highest
  // numbered SSA temp originally had only one slot assigned, this can result
  // in different SSA temp numbering in later passes between the original and
  // deserialized graphs.
  flow_graph_->set_current_ssa_temp_index(max_ssa_index_ + 2);
  // Now that the deserializer has finished re-creating all the blocks in the
  // flow graph, the blocks must be rediscovered. In addition, if ComputeSSA
  // has already been run, dominators must be recomputed as well.
  flow_graph_->DiscoverBlocks();
  // Currently we only handle SSA graphs, so always do this.
  GrowableArray<BitVector*> dominance_frontier;
  flow_graph_->ComputeDominators(&dominance_frontier);

  return flow_graph_;
}

bool FlowGraphDeserializer::ParseConstantPool(SExpList* pool) {
  ASSERT(flow_graph_ != nullptr);
  if (pool == nullptr) return false;
  // Definitions in the constant pool may refer to later definitions. However,
  // there should be no cycles possible between constant objects, so using a
  // worklist algorithm we should always be able to make progress.
  // Since we will not be adding new definitions, we make the initial size of
  // the worklist the number of definitions in the constant pool.
  GrowableArray<SExpList*> worklist(zone(), pool->Length() - 1);
  // In order to ensure that the definition order is the same in the original
  // flow graph, we can't just simply call GetConstant() whenever we
  // successfully parse a constant. Instead, we'll create a stand-in
  // ConstantInstr that we can temporarily stick in the definition_map_, and
  // then once finished we'll go back through, add the constants via
  // GetConstant() and parse any extra information.
  DirectChainedHashMap<RawPointerKeyValueTrait<SExpList, ConstantInstr*>>
      parsed_constants(zone());
  // We keep old_worklist in reverse order so that we can just RemoveLast
  // to get elements in their original order.
  for (intptr_t i = pool->Length() - 1; i > 0; i--) {
    const auto def_sexp = CheckTaggedList(pool->At(i), "def");
    if (def_sexp == nullptr) return false;
    worklist.Add(def_sexp);
  }
  while (true) {
    const intptr_t worklist_len = worklist.length();
    GrowableArray<SExpList*> parse_failures(zone(), worklist_len);
    while (!worklist.is_empty()) {
      const auto def_sexp = worklist.RemoveLast();
      auto& obj = Object::ZoneHandle(zone());
      if (!ParseDartValue(Retrieve(def_sexp, 2), &obj)) {
        parse_failures.Add(def_sexp);
        continue;
      }
      ConstantInstr* def = new (zone()) ConstantInstr(obj);
      // Instead of parsing the whole definition, just get the SSA index so
      // we can insert it into the definition_map_.
      intptr_t index;
      auto const name_sexp = CheckSymbol(Retrieve(def_sexp, 1));
      if (!ParseSSATemp(name_sexp, &index)) return false;
      def->set_ssa_temp_index(index);
      ASSERT(!definition_map_.HasKey(index));
      definition_map_.Insert(index, def);
      parsed_constants.Insert({def_sexp, def});
    }
    if (parse_failures.is_empty()) break;
    // We've gone through the whole worklist without success, so return
    // the last error we encountered.
    if (parse_failures.length() == worklist_len) return false;
    // worklist was added to in order, so we need to reverse its contents
    // when we add them to old_worklist.
    while (!parse_failures.is_empty()) {
      worklist.Add(parse_failures.RemoveLast());
    }
  }
  // Now loop back through the constant pool definition S-expressions and
  // get the real ConstantInstrs the flow graph will be using and finish
  // parsing.
  for (intptr_t i = 1; i < pool->Length(); i++) {
    auto const def_sexp = CheckTaggedList(pool->At(i));
    auto const temp_def = parsed_constants.LookupValue(def_sexp);
    ASSERT(temp_def != nullptr);
    // Remove the temporary definition from definition_map_ so this doesn't get
    // flagged as a redefinition.
    definition_map_.Remove(temp_def->ssa_temp_index());
    ConstantInstr* real_def = flow_graph_->GetConstant(temp_def->value());
    if (!ParseDefinitionWithParsedBody(def_sexp, real_def)) return false;
    ASSERT(temp_def->ssa_temp_index() == real_def->ssa_temp_index());
  }
  return true;
}

bool FlowGraphDeserializer::ParseEntries(SExpList* list) {
  ASSERT(flow_graph_ != nullptr);
  if (list == nullptr) return false;
  for (intptr_t i = 1; i < list->Length(); i++) {
    const auto entry = CheckTaggedList(Retrieve(list, i));
    if (entry == nullptr) return false;
    intptr_t block_id;
    if (!ParseBlockId(CheckSymbol(Retrieve(entry, 1)), &block_id)) {
      return false;
    }
    if (block_map_.LookupValue(block_id) != nullptr) {
      StoreError(entry->At(1), "multiple entries for block found");
      return false;
    }
    const auto tag = entry->Tag();
    if (ParseBlockHeader(entry, block_id, tag) == nullptr) return false;
  }
  return true;
}

bool FlowGraphDeserializer::ParseBlocks(SExpList* list,
                                        intptr_t pos,
                                        BlockWorklist* worklist) {
  // First, ensure that all the block headers have been parsed. Set up a
  // map from block IDs to S-expressions and the max_block_id while we're at it.
  IntMap<SExpList*> block_sexp_map(zone());
  for (intptr_t i = pos, n = list->Length(); i < n; i++) {
    auto const block_sexp = CheckTaggedList(Retrieve(list, i), "Block");
    intptr_t block_id;
    if (!ParseBlockId(CheckSymbol(Retrieve(block_sexp, 1)), &block_id)) {
      return false;
    }
    if (block_sexp_map.LookupValue(block_id) != nullptr) {
      StoreError(block_sexp->At(1), "multiple definitions of block found");
      return false;
    }
    block_sexp_map.Insert(block_id, block_sexp);
    auto const type_tag =
        CheckSymbol(block_sexp->ExtraLookupValue("block_type"));
    // Entry block headers are already parsed, but others aren't.
    if (block_map_.LookupValue(block_id) == nullptr) {
      if (ParseBlockHeader(block_sexp, block_id, type_tag) == nullptr) {
        return false;
      }
    }
    if (max_block_id_ < block_id) max_block_id_ = block_id;
  }

  // Now start parsing the contents of blocks from the worklist. We use an
  // IntMap to keep track of what blocks have already been fully parsed.
  IntMap<bool> fully_parsed_block_map(zone());
  while (!worklist->is_empty()) {
    auto const block_id = worklist->RemoveLast();

    // If we've already encountered this block, skip it.
    if (fully_parsed_block_map.LookupValue(block_id)) continue;

    auto const block_sexp = block_sexp_map.LookupValue(block_id);
    ASSERT(block_sexp != nullptr);

    current_block_ = block_map_.LookupValue(block_id);
    ASSERT(current_block_ != nullptr);
    ASSERT(current_block_->PredecessorCount() > 0);

    if (!ParseBlockContents(block_sexp, worklist)) return false;

    // Mark this block as done.
    fully_parsed_block_map.Insert(block_id, true);
  }

  // Double-check that all blocks were reached by the worklist algorithm.
  auto it = block_sexp_map.GetIterator();
  while (auto kv = it.Next()) {
    if (!fully_parsed_block_map.LookupValue(kv->key)) {
      StoreError(kv->value, "block unreachable in flow graph");
      return false;
    }
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
                                                         intptr_t block_id,
                                                         SExpSymbol* tag) {
  ASSERT(flow_graph_ != nullptr);
  // We should only parse block headers once.
  ASSERT(block_map_.LookupValue(block_id) == nullptr);
  if (list == nullptr) return nullptr;

#if defined(DEBUG)
  intptr_t parsed_block_id;
  auto const id_sexp = CheckSymbol(Retrieve(list, 1));
  if (!ParseBlockId(id_sexp, &parsed_block_id)) return nullptr;
  ASSERT(block_id == parsed_block_id);
#endif

  auto const kind = FlowGraphSerializer::BlockEntryTagToKind(tag);

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_int = CheckInteger(list->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_int->value();
  }
  intptr_t try_index = kInvalidTryIndex;
  if (auto const try_int = CheckInteger(list->ExtraLookupValue("try_index"))) {
    try_index = try_int->value();
  }

  BlockEntryInstr* block = nullptr;
  EntryInfo common_info = {block_id, try_index, deopt_id};
  switch (kind) {
    case FlowGraphSerializer::kTarget:
      block = DeserializeTargetEntry(list, common_info);
      break;
    case FlowGraphSerializer::kNormal:
      block = DeserializeFunctionEntry(list, common_info);
      if (block != nullptr) {
        auto const graph = flow_graph_->graph_entry();
        graph->set_normal_entry(block->AsFunctionEntry());
      }
      break;
    case FlowGraphSerializer::kUnchecked: {
      block = DeserializeFunctionEntry(list, common_info);
      if (block != nullptr) {
        auto const graph = flow_graph_->graph_entry();
        graph->set_unchecked_entry(block->AsFunctionEntry());
      }
      break;
    }
    case FlowGraphSerializer::kJoin:
      block = DeserializeJoinEntry(list, common_info);
      break;
    case FlowGraphSerializer::kInvalid:
      StoreError(tag, "invalid block entry tag");
      return nullptr;
    default:
      StoreError(tag, "unhandled block type");
      return nullptr;
  }
  if (block == nullptr) return nullptr;

  block_map_.Insert(block_id, block);
  return block;
}

bool FlowGraphDeserializer::ParsePhis(SExpList* list) {
  ASSERT(current_block_ != nullptr && current_block_->IsJoinEntry());
  auto const join = current_block_->AsJoinEntry();
  const intptr_t start_pos = 2;
  auto const end_pos = SkipPhis(list);
  if (end_pos < start_pos) return false;

  for (intptr_t i = start_pos; i < end_pos; i++) {
    auto const def_sexp = CheckTaggedList(Retrieve(list, i), "def");
    auto const phi_sexp = CheckTaggedList(Retrieve(def_sexp, 2), "Phi");
    // SkipPhis should already have checked which instructions, if any,
    // are Phi definitions.
    ASSERT(phi_sexp != nullptr);

    // This is a generalization of FlowGraph::AddPhi where we let ParseValue
    // create the values (as they may contain type information).
    auto const phi = new (zone()) PhiInstr(join, phi_sexp->Length() - 1);
    phi->mark_alive();
    for (intptr_t i = 0, n = phi_sexp->Length() - 1; i < n; i++) {
      auto const val = ParseValue(Retrieve(phi_sexp, i + 1));
      if (val == nullptr) return false;
      phi->SetInputAt(i, val);
      val->definition()->AddInputUse(val);
    }
    join->InsertPhi(phi);

    if (!ParseDefinitionWithParsedBody(def_sexp, phi)) return false;
  }

  return true;
}

intptr_t FlowGraphDeserializer::SkipPhis(SExpList* list) {
  // All blocks are S-exps of the form (Block B# inst...), so skip the first
  // two entries and then skip any Phi definitions.
  for (intptr_t i = 2, n = list->Length(); i < n; i++) {
    auto const def_sexp = CheckTaggedList(Retrieve(list, i), "def");
    if (def_sexp == nullptr) return i;
    auto const phi_sexp = CheckTaggedList(Retrieve(def_sexp, 2), "Phi");
    if (phi_sexp == nullptr) return i;
  }

  StoreError(list, "block is empty or contains only Phi definitions");
  return -1;
}

bool FlowGraphDeserializer::ParseBlockContents(SExpList* list,
                                               BlockWorklist* worklist) {
  ASSERT(current_block_ != nullptr);

  // Parse any Phi definitions now before parsing the block environment.
  if (current_block_->IsJoinEntry()) {
    if (!ParsePhis(list)) return false;
  }

  // For blocks with initial definitions or phi definitions, this needs to be
  // done after those are parsed. In addition, block environments can also use
  // definitions from dominating blocks, so we need the contents of dominating
  // blocks to first be parsed.
  //
  // However, we must parse the environment before parsing any instructions
  // in the body of the block to ensure we don't mistakenly allow local
  // definitions to appear in the environment.
  if (auto const env_sexp = CheckList(list->ExtraLookupValue("env"))) {
    auto const env = ParseEnvironment(env_sexp);
    if (env == nullptr) return false;
    env->DeepCopyTo(zone(), current_block_);
  }

  auto const pos = SkipPhis(list);
  if (pos < 2) return false;
  Instruction* last_inst = current_block_;
  for (intptr_t i = pos, n = list->Length(); i < n; i++) {
    auto const inst = ParseInstruction(CheckTaggedList(Retrieve(list, i)));
    if (inst == nullptr) return false;
    last_inst = last_inst->AppendInstruction(inst);
  }

  ASSERT(last_inst != nullptr && last_inst != current_block_);
  if (last_inst->SuccessorCount() > 0) {
    for (intptr_t i = last_inst->SuccessorCount() - 1; i >= 0; i--) {
      auto const succ_block = last_inst->SuccessorAt(i);
      succ_block->AddPredecessor(current_block_);
      worklist->Add(succ_block->block_id());
    }
  }

  return true;
}

bool FlowGraphDeserializer::ParseDefinitionWithParsedBody(SExpList* list,
                                                          Definition* def) {
  if (auto const type_sexp =
          CheckTaggedList(list->ExtraLookupValue("type"), "CompileType")) {
    CompileType* typ = ParseCompileType(type_sexp);
    if (typ == nullptr) return false;
    def->UpdateType(*typ);
  }

  if (auto const range_sexp =
          CheckTaggedList(list->ExtraLookupValue("range"), "Range")) {
    Range range;
    if (!ParseRange(range_sexp, &range)) return false;
    def->set_range(range);
  }

  auto const name_sexp = CheckSymbol(Retrieve(list, 1));
  if (name_sexp == nullptr) return false;

  // If the name is "_", this is a subclass of Definition where there's no real
  // "result" that's being bound. We were just here to add Definition-specific
  // extra info.
  if (name_sexp->Equals("_")) return true;

  intptr_t index;
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

  definition_map_.Insert(index, def);
  if (!FixPendingValues(index, def)) return false;
  return true;
}

Definition* FlowGraphDeserializer::ParseDefinition(SExpList* list) {
  if (list == nullptr) return nullptr;
  ASSERT(list->Tag() != nullptr && list->Tag()->Equals("def"));
  auto const inst_sexp = CheckTaggedList(Retrieve(list, 2));
  auto const inst = ParseInstruction(inst_sexp);
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
  auto const tag = list->Tag();
  if (tag->Equals("def")) return ParseDefinition(list);

  intptr_t deopt_id = DeoptId::kNone;
  if (auto const deopt_int = CheckInteger(list->ExtraLookupValue("deopt_id"))) {
    deopt_id = deopt_int->value();
  }
  TokenPosition token_pos = TokenPosition::kNoSource;
  if (auto const token_int =
          CheckInteger(list->ExtraLookupValue("token_pos"))) {
    token_pos = TokenPosition::Deserialize(token_int->value());
  }
  intptr_t inlining_id = -1;
  if (auto const inlining_int =
          CheckInteger(list->ExtraLookupValue("inlining_id"))) {
    inlining_id = inlining_int->value();
  }
  InstrInfo common_info = {deopt_id, InstructionSource(token_pos, inlining_id)};

  // Parse the environment before handling the instruction, as we may have
  // references to PushArguments and parsing the instruction may pop
  // PushArguments off the stack.
  // TODO(alexmarkov): revise as it may not be needed anymore.
  Environment* env = nullptr;
  if (auto const env_sexp = CheckList(list->ExtraLookupValue("env"))) {
    env = ParseEnvironment(env_sexp);
    if (env == nullptr) return nullptr;
  }

  Instruction* inst = nullptr;

#define HANDLE_CASE(name)                                                      \
  case kHandled##name:                                                         \
    inst = Deserialize##name(list, common_info);                               \
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

FunctionEntryInstr* FlowGraphDeserializer::DeserializeFunctionEntry(
    SExpList* sexp,
    const EntryInfo& info) {
  ASSERT(flow_graph_ != nullptr);
  auto const graph = flow_graph_->graph_entry();
  auto const block = new (zone())
      FunctionEntryInstr(graph, info.block_id, info.try_index, info.deopt_id);
  current_block_ = block;
  if (!ParseInitialDefinitions(sexp)) return nullptr;
  return block;
}

GraphEntryInstr* FlowGraphDeserializer::DeserializeGraphEntry(
    SExpList* sexp,
    const EntryInfo& info) {
  auto const name_sexp = CheckSymbol(Retrieve(sexp, 1));
  // TODO(sstrickl): If the FlowGraphDeserializer was constructed with a
  // non-null ParsedFunction, we should check that the name matches here.
  // If not, then we should create an appropriate ParsedFunction here.
  if (name_sexp == nullptr) return nullptr;

  intptr_t osr_id = Compiler::kNoOSRDeoptId;
  if (auto const osr_id_sexp = CheckInteger(sexp->ExtraLookupValue("osr_id"))) {
    osr_id = osr_id_sexp->value();
  }

  ASSERT(parsed_function_ != nullptr);
  return new (zone()) GraphEntryInstr(*parsed_function_, osr_id, info.deopt_id);
}

JoinEntryInstr* FlowGraphDeserializer::DeserializeJoinEntry(
    SExpList* sexp,
    const EntryInfo& info) {
  return new (zone())
      JoinEntryInstr(info.block_id, info.try_index, info.deopt_id);
}

TargetEntryInstr* FlowGraphDeserializer::DeserializeTargetEntry(
    SExpList* sexp,
    const EntryInfo& info) {
  return new (zone())
      TargetEntryInstr(info.block_id, info.try_index, info.deopt_id);
}

AllocateObjectInstr* FlowGraphDeserializer::DeserializeAllocateObject(
    SExpList* sexp,
    const InstrInfo& info) {
  auto& cls = Class::ZoneHandle(zone());
  auto const cls_sexp = CheckTaggedList(Retrieve(sexp, 1), "Class");
  if (!ParseClass(cls_sexp, &cls)) return nullptr;

  Value* type_arguments = nullptr;
  if (cls.NumTypeArguments() > 0) {
    type_arguments = ParseValue(Retrieve(sexp, 2));
    if (type_arguments == nullptr) return nullptr;
  }

  auto const inst =
      new (zone()) AllocateObjectInstr(info.source, cls, type_arguments);

  if (auto const closure_sexp = CheckTaggedList(
          sexp->ExtraLookupValue("closure_function"), "Function")) {
    auto& closure_function = Function::Handle(zone());
    if (!ParseFunction(closure_sexp, &closure_function)) return nullptr;
    inst->set_closure_function(closure_function);
  }

  if (auto const ident_sexp = CheckSymbol(sexp->ExtraLookupValue("identity"))) {
    auto id = AliasIdentity::Unknown();
    if (!AliasIdentity::Parse(ident_sexp->value(), &id)) {
      return nullptr;
    }
    inst->SetIdentity(id);
  }

  return inst;
}

AssertAssignableInstr* FlowGraphDeserializer::DeserializeAssertAssignable(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const val = ParseValue(Retrieve(sexp, 1));
  if (val == nullptr) return nullptr;

  auto const dst_type = ParseValue(Retrieve(sexp, 2));
  if (dst_type == nullptr) return nullptr;

  auto const inst_type_args = ParseValue(Retrieve(sexp, 3));
  if (inst_type_args == nullptr) return nullptr;

  auto const func_type_args = ParseValue(Retrieve(sexp, 4));
  if (func_type_args == nullptr) return nullptr;

  auto& dst_name = String::ZoneHandle(zone());
  auto const dst_name_sexp = Retrieve(sexp, "name");
  if (!ParseDartValue(dst_name_sexp, &dst_name)) return nullptr;

  auto kind = AssertAssignableInstr::Kind::kUnknown;
  if (auto const kind_sexp = CheckSymbol(sexp->ExtraLookupValue("kind"))) {
    if (!AssertAssignableInstr::ParseKind(kind_sexp->value(), &kind)) {
      StoreError(kind_sexp, "unknown AssertAssignable kind");
      return nullptr;
    }
  }

  return new (zone())
      AssertAssignableInstr(info.source, val, dst_type, inst_type_args,
                            func_type_args, dst_name, info.deopt_id, kind);
}

AssertBooleanInstr* FlowGraphDeserializer::DeserializeAssertBoolean(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const val = ParseValue(Retrieve(sexp, 1));
  if (val == nullptr) return nullptr;

  return new (zone()) AssertBooleanInstr(info.source, val, info.deopt_id);
}

BooleanNegateInstr* FlowGraphDeserializer::DeserializeBooleanNegate(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const value = ParseValue(Retrieve(sexp, 1));
  if (value == nullptr) return nullptr;

  return new (zone()) BooleanNegateInstr(value);
}

BranchInstr* FlowGraphDeserializer::DeserializeBranch(SExpList* sexp,
                                                      const InstrInfo& info) {
  auto const comp_sexp = CheckTaggedList(Retrieve(sexp, 1));
  auto const comp_inst = ParseInstruction(comp_sexp);
  if (comp_inst == nullptr) return nullptr;
  if (!comp_inst->IsComparison()) {
    StoreError(sexp->At(1), "expected comparison instruction");
    return nullptr;
  }
  auto const comparison = comp_inst->AsComparison();

  auto const true_block = FetchBlock(CheckSymbol(Retrieve(sexp, 2)));
  if (true_block == nullptr) return nullptr;
  if (!true_block->IsTargetEntry()) {
    StoreError(sexp->At(2), "true successor is not a target block");
    return nullptr;
  }

  auto const false_block = FetchBlock(CheckSymbol(Retrieve(sexp, 3)));
  if (false_block == nullptr) return nullptr;
  if (!false_block->IsTargetEntry()) {
    StoreError(sexp->At(3), "false successor is not a target block");
    return nullptr;
  }

  auto const branch = new (zone()) BranchInstr(comparison, info.deopt_id);
  *branch->true_successor_address() = true_block->AsTargetEntry();
  *branch->false_successor_address() = false_block->AsTargetEntry();
  return branch;
}

CheckNullInstr* FlowGraphDeserializer::DeserializeCheckNull(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const val = ParseValue(Retrieve(sexp, 1));
  if (val == nullptr) return nullptr;

  auto& func_name = String::ZoneHandle(zone());
  if (auto const name_sexp =
          CheckString(sexp->ExtraLookupValue("function_name"))) {
    func_name = String::New(name_sexp->value(), Heap::kOld);
  }

  return new (zone())
      CheckNullInstr(val, func_name, info.deopt_id, info.source);
}

CheckStackOverflowInstr* FlowGraphDeserializer::DeserializeCheckStackOverflow(
    SExpList* sexp,
    const InstrInfo& info) {
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
    ASSERT(kind_sexp->Equals("OsrOnly"));
    kind = CheckStackOverflowInstr::kOsrOnly;
  }

  return new (zone()) CheckStackOverflowInstr(info.source, stack_depth,
                                              loop_depth, info.deopt_id, kind);
}

ConstantInstr* FlowGraphDeserializer::DeserializeConstant(
    SExpList* sexp,
    const InstrInfo& info) {
  Object& obj = Object::ZoneHandle(zone());
  if (!ParseDartValue(Retrieve(sexp, 1), &obj)) return nullptr;
  return new (zone()) ConstantInstr(obj, info.source);
}

DebugStepCheckInstr* FlowGraphDeserializer::DeserializeDebugStepCheck(
    SExpList* sexp,
    const InstrInfo& info) {
  auto kind = PcDescriptorsLayout::kAnyKind;
  if (auto const kind_sexp = CheckSymbol(Retrieve(sexp, "stub_kind"))) {
    if (!PcDescriptorsLayout::ParseKind(kind_sexp->value(), &kind)) {
      StoreError(kind_sexp, "not a valid PcDescriptorsLayout::Kind name");
      return nullptr;
    }
  }
  return new (zone()) DebugStepCheckInstr(info.source, kind, info.deopt_id);
}

GotoInstr* FlowGraphDeserializer::DeserializeGoto(SExpList* sexp,
                                                  const InstrInfo& info) {
  auto const block = FetchBlock(CheckSymbol(Retrieve(sexp, 1)));
  if (block == nullptr) return nullptr;
  if (!block->IsJoinEntry()) {
    StoreError(sexp->At(1), "target of goto must be join entry");
    return nullptr;
  }
  return new (zone()) GotoInstr(block->AsJoinEntry(), info.deopt_id);
}

InstanceCallInstr* FlowGraphDeserializer::DeserializeInstanceCall(
    SExpList* sexp,
    const InstrInfo& info) {
  auto& interface_target = Function::ZoneHandle(zone());
  auto& tearoff_interface_target = Function::ZoneHandle(zone());
  if (!ParseDartValue(Retrieve(sexp, "interface_target"), &interface_target)) {
    return nullptr;
  }
  if (!ParseDartValue(Retrieve(sexp, "tearoff_interface_target"),
                      &tearoff_interface_target)) {
    return nullptr;
  }
  auto& function_name = String::ZoneHandle(zone());
  // If we have an explicit function_name value, then use that value. Otherwise,
  // if we have an non-null interface_target, use its name.
  if (auto const name_sexp = sexp->ExtraLookupValue("function_name")) {
    if (!ParseDartValue(name_sexp, &function_name)) return nullptr;
  } else if (!interface_target.IsNull()) {
    function_name = interface_target.name();
  } else if (!tearoff_interface_target.IsNull()) {
    function_name = tearoff_interface_target.name();
  }

  auto token_kind = Token::Kind::kILLEGAL;
  if (auto const kind_sexp =
          CheckSymbol(sexp->ExtraLookupValue("token_kind"))) {
    if (!Token::FromStr(kind_sexp->value(), &token_kind)) {
      StoreError(kind_sexp, "unexpected token kind");
      return nullptr;
    }
  }

  CallInfo call_info(zone());
  if (!ParseCallInfo(sexp, &call_info)) return nullptr;

  intptr_t checked_arg_count = 0;
  if (auto const checked_sexp =
          CheckInteger(sexp->ExtraLookupValue("checked_arg_count"))) {
    checked_arg_count = checked_sexp->value();
  }

  auto const inst = new (zone()) InstanceCallInstr(
      info.source, function_name, token_kind, call_info.inputs,
      call_info.type_args_len, call_info.argument_names, checked_arg_count,
      info.deopt_id, interface_target, tearoff_interface_target);

  if (call_info.result_type != nullptr) {
    inst->SetResultType(zone(), *call_info.result_type);
  }

  inst->set_entry_kind(call_info.entry_kind);

  if (auto const ic_data_sexp =
          CheckTaggedList(Retrieve(sexp, "ic_data"), "ICData")) {
    if (!CreateICData(ic_data_sexp, inst)) return nullptr;
  }

  return inst;
}

LoadClassIdInstr* FlowGraphDeserializer::DeserializeLoadClassId(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const val = ParseValue(Retrieve(sexp, 1));
  if (val == nullptr) return nullptr;

  return new (zone()) LoadClassIdInstr(val);
}

LoadFieldInstr* FlowGraphDeserializer::DeserializeLoadField(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const instance = ParseValue(Retrieve(sexp, 1));
  if (instance == nullptr) return nullptr;

  const Slot* slot;
  if (!ParseSlot(CheckTaggedList(Retrieve(sexp, 2)), &slot)) return nullptr;

  bool calls_initializer = false;
  if (auto const calls_initializer_sexp =
          CheckBool(sexp->ExtraLookupValue("calls_initializer"))) {
    calls_initializer = calls_initializer_sexp->value();
  }

  return new (zone()) LoadFieldInstr(instance, *slot, info.source,
                                     calls_initializer, info.deopt_id);
}

NativeCallInstr* FlowGraphDeserializer::DeserializeNativeCall(
    SExpList* sexp,
    const InstrInfo& info) {
  auto& function = Function::ZoneHandle(zone());
  if (!ParseDartValue(Retrieve(sexp, "function"), &function)) return nullptr;
  if (!function.IsFunction()) {
    StoreError(sexp->At(1), "expected a Function value");
    return nullptr;
  }

  auto const name_sexp = CheckString(Retrieve(sexp, "name"));
  if (name_sexp == nullptr) return nullptr;
  const auto& name =
      String::ZoneHandle(zone(), String::New(name_sexp->value()));

  bool link_lazily = false;
  if (auto const link_sexp = CheckBool(sexp->ExtraLookupValue("link_lazily"))) {
    link_lazily = link_sexp->value();
  }

  CallInfo call_info(zone());
  if (!ParseCallInfo(sexp, &call_info)) return nullptr;

  return new (zone()) NativeCallInstr(&name, &function, link_lazily,
                                      info.source, call_info.inputs);
}

ParameterInstr* FlowGraphDeserializer::DeserializeParameter(
    SExpList* sexp,
    const InstrInfo& info) {
  ASSERT(current_block_ != nullptr);
  if (auto const index_sexp = CheckInteger(Retrieve(sexp, 1))) {
    const auto param_offset_sexp =
        CheckInteger(sexp->ExtraLookupValue("param_offset"));
    ASSERT(param_offset_sexp != nullptr);
    const auto representation_sexp =
        CheckSymbol(sexp->ExtraLookupValue("representation"));
    Representation representation;
    if (!Location::ParseRepresentation(representation_sexp->value(),
                                       &representation)) {
      StoreError(representation_sexp, "unknown parameter representation");
    }
    return new (zone())
        ParameterInstr(index_sexp->value(), param_offset_sexp->value(),
                       current_block_, representation);
  }
  return nullptr;
}

ReturnInstr* FlowGraphDeserializer::DeserializeReturn(SExpList* list,
                                                      const InstrInfo& info) {
  Value* val = ParseValue(Retrieve(list, 1));
  if (val == nullptr) return nullptr;
  return new (zone()) ReturnInstr(info.source, val, info.deopt_id);
}

SpecialParameterInstr* FlowGraphDeserializer::DeserializeSpecialParameter(
    SExpList* sexp,
    const InstrInfo& info) {
  ASSERT(current_block_ != nullptr);
  auto const kind_sexp = CheckSymbol(Retrieve(sexp, 1));
  if (kind_sexp == nullptr) return nullptr;
  SpecialParameterInstr::SpecialParameterKind kind;
  if (!SpecialParameterInstr::ParseKind(kind_sexp->value(), &kind)) {
    StoreError(kind_sexp, "unknown special parameter kind");
    return nullptr;
  }
  return new (zone())
      SpecialParameterInstr(kind, info.deopt_id, current_block_);
}

StaticCallInstr* FlowGraphDeserializer::DeserializeStaticCall(
    SExpList* sexp,
    const InstrInfo& info) {
  auto& function = Function::ZoneHandle(zone());
  auto const function_sexp =
      CheckTaggedList(Retrieve(sexp, "function"), "Function");
  if (!ParseFunction(function_sexp, &function)) return nullptr;

  CallInfo call_info(zone());
  if (!ParseCallInfo(sexp, &call_info)) return nullptr;

  intptr_t call_count = 0;
  if (auto const call_count_sexp =
          CheckInteger(sexp->ExtraLookupValue("call_count"))) {
    call_count = call_count_sexp->value();
  }

  auto rebind_rule = ICData::kStatic;
  if (auto const rebind_sexp =
          CheckSymbol(sexp->ExtraLookupValue("rebind_rule"))) {
    if (!ICData::ParseRebindRule(rebind_sexp->value(), &rebind_rule)) {
      StoreError(rebind_sexp, "unknown rebind rule value");
      return nullptr;
    }
  }

  auto const inst = new (zone()) StaticCallInstr(
      info.source, function, call_info.type_args_len, call_info.argument_names,
      call_info.inputs, info.deopt_id, call_count, rebind_rule);

  if (call_info.result_type != nullptr) {
    inst->SetResultType(zone(), *call_info.result_type);
  }

  inst->set_entry_kind(call_info.entry_kind);

  if (auto const ic_data_sexp =
          CheckTaggedList(sexp->ExtraLookupValue("ic_data"), "ICData")) {
    if (!CreateICData(ic_data_sexp, inst)) return nullptr;
  }

  return inst;
}

StoreInstanceFieldInstr* FlowGraphDeserializer::DeserializeStoreInstanceField(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const instance = ParseValue(Retrieve(sexp, 1));
  if (instance == nullptr) return nullptr;

  const Slot* slot = nullptr;
  if (!ParseSlot(CheckTaggedList(Retrieve(sexp, 2), "Slot"), &slot)) {
    return nullptr;
  }

  auto const value = ParseValue(Retrieve(sexp, 3));
  if (value == nullptr) return nullptr;

  auto barrier_type = kNoStoreBarrier;
  if (auto const bar_sexp = CheckBool(sexp->ExtraLookupValue("emit_barrier"))) {
    if (bar_sexp->value()) barrier_type = kEmitStoreBarrier;
  }

  auto kind = StoreInstanceFieldInstr::Kind::kOther;
  if (auto const init_sexp = CheckBool(sexp->ExtraLookupValue("is_init"))) {
    if (init_sexp->value()) kind = StoreInstanceFieldInstr::Kind::kInitializing;
  }

  return new (zone()) StoreInstanceFieldInstr(*slot, instance, value,
                                              barrier_type, info.source, kind);
}

StrictCompareInstr* FlowGraphDeserializer::DeserializeStrictCompare(
    SExpList* sexp,
    const InstrInfo& info) {
  auto const token_sexp = CheckSymbol(Retrieve(sexp, 1));
  if (token_sexp == nullptr) return nullptr;
  Token::Kind kind;
  if (!Token::FromStr(token_sexp->value(), &kind)) return nullptr;

  auto const left = ParseValue(Retrieve(sexp, 2));
  if (left == nullptr) return nullptr;

  auto const right = ParseValue(Retrieve(sexp, 3));
  if (right == nullptr) return nullptr;

  bool needs_check = false;
  if (auto const check_sexp = CheckBool(Retrieve(sexp, "needs_check"))) {
    needs_check = check_sexp->value();
  }

  return new (zone()) StrictCompareInstr(info.source, kind, left, right,
                                         needs_check, info.deopt_id);
}

ThrowInstr* FlowGraphDeserializer::DeserializeThrow(SExpList* sexp,
                                                    const InstrInfo& info) {
  Value* exception = ParseValue(Retrieve(sexp, 1));
  if (exception == nullptr) return nullptr;
  return new (zone()) ThrowInstr(info.source, info.deopt_id, exception);
}

bool FlowGraphDeserializer::ParseCallInfo(SExpList* call,
                                          CallInfo* out,
                                          intptr_t num_extra_inputs) {
  ASSERT(out != nullptr);

  if (auto const len_sexp =
          CheckInteger(call->ExtraLookupValue("type_args_len"))) {
    out->type_args_len = len_sexp->value();
  }

  if (auto const arg_names_sexp =
          CheckList(call->ExtraLookupValue("arg_names"))) {
    out->argument_names = Array::New(arg_names_sexp->Length(), Heap::kOld);
    for (intptr_t i = 0, n = arg_names_sexp->Length(); i < n; i++) {
      auto name_sexp = CheckString(Retrieve(arg_names_sexp, i));
      if (name_sexp == nullptr) return false;
      tmp_string_ = String::New(name_sexp->value(), Heap::kOld);
      out->argument_names.SetAt(i, tmp_string_);
    }
  }

  if (auto const args_len_sexp =
          CheckInteger(call->ExtraLookupValue("args_len"))) {
    out->args_len = args_len_sexp->value();
  }

  if (auto const result_sexp = CheckTaggedList(
          call->ExtraLookupValue("result_type"), "CompileType")) {
    out->result_type = ParseCompileType(result_sexp);
  }

  if (auto const kind_sexp =
          CheckSymbol(call->ExtraLookupValue("entry_kind"))) {
    if (!Code::ParseEntryKind(kind_sexp->value(), &out->entry_kind))
      return false;
  }

  // Type arguments are wrapped in a TypeArguments array, so no matter how
  // many there are, they are contained in a single pushed argument.
  auto const all_args_len = (out->type_args_len > 0 ? 1 : 0) + out->args_len;

  const intptr_t num_inputs = all_args_len + num_extra_inputs;
  out->inputs = new (zone()) InputsArray(zone(), num_inputs);
  for (intptr_t i = 0; i < num_inputs; ++i) {
    auto const input = ParseValue(Retrieve(call, 1 + i));
    if (input == nullptr) return false;
    out->inputs->Add(input);
  }

  return true;
}

Value* FlowGraphDeserializer::ParseValue(SExpression* sexp,
                                         bool allow_pending) {
  CompileType* type = nullptr;
  bool inherit_type = false;
  auto name = sexp->AsSymbol();
  if (name == nullptr) {
    auto const list = CheckTaggedList(sexp, "value");
    name = CheckSymbol(Retrieve(list, 1));
    if (auto const type_sexp =
            CheckTaggedList(list->ExtraLookupValue("type"), "CompileType")) {
      type = ParseCompileType(type_sexp);
      if (type == nullptr) return nullptr;
    } else if (auto const inherit_sexp =
                   CheckBool(list->ExtraLookupValue("inherit_type"))) {
      inherit_type = inherit_sexp->value();
    } else {
      // We assume that the type should be inherited from the definition for
      // for (value ...) forms without an explicit type.
      inherit_type = true;
    }
  }
  intptr_t index;
  if (!ParseUse(name, &index)) return nullptr;
  auto const def = definition_map_.LookupValue(index);
  Value* val;
  if (def == nullptr) {
    if (!allow_pending) {
      StoreError(sexp, "found use prior to definition");
      return nullptr;
    }
    val = AddNewPendingValue(sexp, index, inherit_type);
  } else {
    val = new (zone()) Value(def);
    if (inherit_type) {
      if (def->HasType()) {
        val->reaching_type_ = def->Type();
      } else {
        StoreError(sexp, "value inherits type, but no type found");
        return nullptr;
      }
    }
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

  intptr_t cid = kIllegalCid;
  if (auto const cid_sexp = CheckInteger(sexp->ExtraLookupValue("cid"))) {
    // TODO(sstrickl): Check that the cid is a valid concrete cid, or a cid
    // otherwise found in CompileTypes like kIllegalCid or kDynamicCid.
    cid = cid_sexp->value();
  }

  AbstractType* type = nullptr;
  if (auto const type_sexp = sexp->ExtraLookupValue("type")) {
    auto& type_handle = AbstractType::ZoneHandle(zone());
    if (!ParseAbstractType(type_sexp, &type_handle)) return nullptr;
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

  ASSERT(parsed_function_ != nullptr);
  auto const env = new (zone()) Environment(list->Length(), fixed_param_count,
                                            *parsed_function_, outer_env);

  for (intptr_t i = 0; i < list->Length(); i++) {
    auto const elem_sexp = Retrieve(list, i);
    if (elem_sexp == nullptr) return nullptr;
    auto val = ParseValue(elem_sexp, /*allow_pending=*/false);
    if (val == nullptr) return nullptr;
    env->PushValue(val);
  }

  return env;
}

bool FlowGraphDeserializer::ParseDartValue(SExpression* sexp, Object* out) {
  ASSERT(out != nullptr);
  if (sexp == nullptr) return false;
  *out = Object::null();

  if (auto const sym = sexp->AsSymbol()) {
    // We'll use the null value in *out as a marker later, so go ahead and exit
    // early if we parse one.
    if (sym->Equals("null")) return true;
    if (sym->Equals("sentinel")) {
      *out = Object::sentinel().raw();
      return true;
    }

    // The only other symbols that should appear in Dart value position are
    // names of constant definitions.
    auto const val = ParseValue(sym, /*allow_pending=*/false);
    if (val == nullptr) return false;
    if (!val->BindsToConstant()) {
      StoreError(sym, "not a reference to a constant definition");
      return false;
    }
    *out = val->BoundConstant().raw();
    // Values used in constant definitions have already been canonicalized,
    // so just exit.
    return true;
  }

  // Other instance values may need to be canonicalized, so do that before
  // returning.
  if (auto const b = sexp->AsBool()) {
    *out = Bool::Get(b->value()).raw();
  } else if (auto const str = sexp->AsString()) {
    *out = String::New(str->value(), Heap::kOld);
  } else if (auto const i = sexp->AsInteger()) {
    *out = Integer::New(i->value(), Heap::kOld);
  } else if (auto const d = sexp->AsDouble()) {
    *out = Double::New(d->value(), Heap::kOld);
  } else if (auto const list = CheckTaggedList(sexp)) {
    auto const tag = list->Tag();
    if (tag->Equals("Class")) {
      return ParseClass(list, out);
    } else if (tag->Equals("Type")) {
      return ParseType(list, out);
    } else if (tag->Equals("TypeArguments")) {
      return ParseTypeArguments(list, out);
    } else if (tag->Equals("Field")) {
      return ParseField(list, out);
    } else if (tag->Equals("Function")) {
      return ParseFunction(list, out);
    } else if (tag->Equals("TypeParameter")) {
      return ParseTypeParameter(list, out);
    } else if (tag->Equals("ImmutableList")) {
      return ParseImmutableList(list, out);
    } else if (tag->Equals("Instance")) {
      return ParseInstance(list, out);
    } else if (tag->Equals("Closure")) {
      return ParseClosure(list, out);
    } else if (tag->Equals("TypeRef")) {
      return ParseTypeRef(list, out);
    }
  }

  // If we're here and still haven't gotten a non-null value, then something
  // went wrong. (Likely an unrecognized value.)
  if (out->IsNull()) {
    StoreError(sexp, "unhandled Dart value");
    return false;
  }

  if (!out->IsInstance()) return true;
  return CanonicalizeInstance(sexp, out);
}

bool FlowGraphDeserializer::CanonicalizeInstance(SExpression* sexp,
                                                 Object* out) {
  ASSERT(out != nullptr);
  if (!out->IsInstance()) return true;
  // Instance::Canonicalize uses the current zone for the passed in thread,
  // not an explicitly provided zone. This means we cannot be run in a context
  // where [thread()->zone()] does not match [zone()] (e.g., due to StackZone)
  // until this is addressed.
  *out = Instance::Cast(*out).Canonicalize(thread());
  return true;
}

bool FlowGraphDeserializer::ParseAbstractType(SExpression* sexp, Object* out) {
  ASSERT(out != nullptr);
  if (sexp == nullptr) return false;

  // If it's a symbol, it should be a reference to a constant definition, which
  // is handled in ParseType.
  if (auto const sym = sexp->AsSymbol()) {
    return ParseType(sexp, out);
  } else if (auto const list = CheckTaggedList(sexp)) {
    auto const tag = list->Tag();
    if (tag->Equals("Type")) {
      return ParseType(list, out);
    } else if (tag->Equals("TypeParameter")) {
      return ParseTypeParameter(list, out);
    } else if (tag->Equals("TypeRef")) {
      return ParseTypeRef(list, out);
    }
  }

  StoreError(sexp, "not an AbstractType");
  return false;
}

bool FlowGraphDeserializer::ParseClass(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  auto const ref_sexp = Retrieve(list, 1);
  if (ref_sexp == nullptr) return false;
  if (auto const cid_sexp = ref_sexp->AsInteger()) {
    ClassTable* table = thread()->isolate()->class_table();
    if (!table->HasValidClassAt(cid_sexp->value())) {
      StoreError(cid_sexp, "no valid class found for cid");
      return false;
    }
    *out = table->At(cid_sexp->value());
  } else if (auto const name_sexp = ref_sexp->AsSymbol()) {
    if (!ParseCanonicalName(name_sexp, out)) return false;
    if (!out->IsClass()) {
      StoreError(name_sexp, "expected the name of a class");
      return false;
    }
  }
  return true;
}

bool FlowGraphDeserializer::ParseClosure(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  auto& function = Function::ZoneHandle(zone());
  auto const function_sexp = CheckTaggedList(Retrieve(list, 1), "Function");
  if (!ParseFunction(function_sexp, &function)) return false;

  auto& context = Context::ZoneHandle(zone());
  if (list->ExtraLookupValue("context") != nullptr) {
    StoreError(list, "closures with contexts currently unhandled");
    return false;
  }

  auto& inst_type_args = TypeArguments::ZoneHandle(zone());
  if (auto const type_args_sexp = Retrieve(list, "inst_type_args")) {
    if (!ParseTypeArguments(type_args_sexp, &inst_type_args)) return false;
  }

  auto& func_type_args = TypeArguments::ZoneHandle(zone());
  if (auto const type_args_sexp = Retrieve(list, "func_type_args")) {
    if (!ParseTypeArguments(type_args_sexp, &func_type_args)) return false;
  }

  auto& delayed_type_args = TypeArguments::ZoneHandle(zone());
  if (auto const type_args_sexp = Retrieve(list, "delayed_type_args")) {
    if (!ParseTypeArguments(type_args_sexp, &delayed_type_args)) {
      return false;
    }
  }

  *out = Closure::New(inst_type_args, func_type_args, delayed_type_args,
                      function, context, Heap::kOld);
  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseField(SExpList* list, Object* out) {
  auto const name_sexp = CheckSymbol(Retrieve(list, 1));
  if (!ParseCanonicalName(name_sexp, out)) return false;
  if (!out->IsField()) {
    StoreError(list, "expected a Field name");
    return false;
  }
  return true;
}

bool FlowGraphDeserializer::ParseFunction(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  auto const name_sexp = CheckSymbol(Retrieve(list, 1));
  if (!ParseCanonicalName(name_sexp, out)) return false;
  if (!out->IsFunction()) {
    StoreError(list, "expected a Function name");
    return false;
  }
  auto& function = Function::Cast(*out);
  // Check the kind expected by the S-expression if one was specified.
  if (auto const kind_sexp = CheckSymbol(list->ExtraLookupValue("kind"))) {
    FunctionLayout::Kind kind;
    if (!FunctionLayout::ParseKind(kind_sexp->value(), &kind)) {
      StoreError(kind_sexp, "unexpected function kind");
      return false;
    }
    if (function.kind() != kind) {
      auto const kind_str = FunctionLayout::KindToCString(function.kind());
      StoreError(list, "retrieved function has kind %s", kind_str);
      return false;
    }
  }
  return true;
}

bool FlowGraphDeserializer::ParseImmutableList(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  *out = Array::New(list->Length() - 1, Heap::kOld);
  auto& arr = Array::Cast(*out);
  // Arrays may contain other arrays, so we'll need a new handle in which to
  // store elements.
  auto& elem = Object::Handle(zone());
  for (intptr_t i = 1; i < list->Length(); i++) {
    if (!ParseDartValue(Retrieve(list, i), &elem)) return false;
    arr.SetAt(i - 1, elem);
  }
  if (auto type_args_sexp = list->ExtraLookupValue("type_args")) {
    if (!ParseTypeArguments(type_args_sexp, &array_type_args_)) return false;
    arr.SetTypeArguments(array_type_args_);
  }
  arr.MakeImmutable();
  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseInstance(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;
  auto const cid_sexp = CheckInteger(Retrieve(list, 1));
  if (cid_sexp == nullptr) return false;

  auto const table = thread()->isolate()->class_table();
  if (!table->HasValidClassAt(cid_sexp->value())) {
    StoreError(cid_sexp, "cid is not valid");
    return false;
  }

  ASSERT(cid_sexp->value() != kNullCid);  // Must use canonical instances.
  ASSERT(cid_sexp->value() != kBoolCid);  // Must use canonical instances.
  instance_class_ = table->At(cid_sexp->value());
  *out = Instance::New(instance_class_, Heap::kOld);
  auto& instance = Instance::Cast(*out);

  if (auto const type_args = list->ExtraLookupValue("type_args")) {
    instance_type_args_ = TypeArguments::null();
    if (!ParseTypeArguments(type_args, &instance_type_args_)) return false;
    if (!instance_class_.IsGeneric()) {
      StoreError(list,
                 "type arguments provided for an instance of a "
                 "non-generic class");
      return false;
    }
    instance.SetTypeArguments(instance_type_args_);
  }

  // Pick out and store the final instance fields of the class, as values must
  // be provided for them. Error if there are any non-final instance fields.
  instance_fields_array_ = instance_class_.fields();
  auto const field_count = instance_fields_array_.Length();
  GrowableArray<const Field*> final_fields(zone(), field_count);
  for (intptr_t i = 0, n = field_count; i < n; i++) {
    instance_field_ = Field::RawCast(instance_fields_array_.At(i));
    if (!instance_field_.is_instance()) continue;
    if (!instance_field_.is_final()) {
      StoreError(list, "class for instance has non-final instance fields");
      return false;
    }
    auto& fresh_handle = Field::Handle(zone(), instance_field_.raw());
    final_fields.Add(&fresh_handle);
  }

  // If there is no (Fields...) sub-expression or it has no extra info, then
  // ensure there are no final fields before returning the canonicalized form.
  SExpList* fields_sexp = nullptr;
  bool fields_provided = list->Length() > 2;
  if (fields_provided) {
    fields_sexp = CheckTaggedList(Retrieve(list, 2), "Fields");
    if (fields_sexp == nullptr) return false;
    fields_provided = fields_sexp->ExtraLength() != 0;
  }
  if (!fields_provided) {
    if (!final_fields.is_empty()) {
      StoreError(list, "values not provided for final fields of instance");
      return false;
    }
    return CanonicalizeInstance(list, out);
  }

  // At this point, we have final instance field values to set on the new
  // instance before canonicalization. When setting instance fields, we may
  // cause field guards to be invalidated. Because of this, we must either be
  // running on the mutator thread or be at a safepoint when calling `SetField`.
  //
  // For IR round-trips, the constants we create have already existed before in
  // the VM heap, which means field invalidation cannot occur. Thus, we create a
  // closure that sets the fields of the instance and then conditionally run
  // that closure at a safepoint if not in the mutator thread.
  //
  // TODO(dartbug.com/36882): When deserializing IR that was not generated
  // during the RoundTripSerialization pass, we are no longer guaranteed that
  // deserialization of instances will not invalidate field guards. Thus, we may
  // need to support invalidating field guards on non-mutator threads or fall
  // back onto forcing the deserialization to happen on the mutator thread.
  auto set_instance_fields = [&]() {
    auto& inst = Instance::Cast(*out);
    // We'll need to allocate a handle for the parsed value as we may have
    // instances as field values and so this function may be re-entered.
    auto& value = Object::Handle(zone());
    for (auto field : final_fields) {
      tmp_string_ = field->UserVisibleName();
      auto const name = tmp_string_.ToCString();
      auto const value_sexp = Retrieve(fields_sexp, name);
      if (value_sexp == nullptr) {
        StoreError(list, "no value provided for final instance field %s", name);
        return false;
      }
      if (!ParseDartValue(value_sexp, &value)) return false;
      inst.SetField(*field, value);
    }
    return true;
  };

  auto const t = Thread::Current();
  if (!t->IsMutatorThread()) {
    SafepointOperationScope safepoint_scope(t);
    if (!set_instance_fields()) return false;
  } else {
    if (!set_instance_fields()) return false;
  }

  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseType(SExpression* sexp, Object* out) {
  ASSERT(out != nullptr);
  if (sexp == nullptr) return false;

  if (auto const sym = sexp->AsSymbol()) {
    auto const val = ParseValue(sexp, /*allow_pending=*/false);
    if (val == nullptr) {
      StoreError(sexp, "expected type or reference to constant definition");
      return false;
    }
    if (!val->BindsToConstant()) {
      StoreError(sexp, "reference to non-constant definition");
      return false;
    }
    *out = val->BoundConstant().raw();
    if (!out->IsType()) {
      StoreError(sexp, "expected Type constant");
      return false;
    }
    return true;
  }
  auto const list = CheckTaggedList(sexp, "Type");
  if (list == nullptr) return false;

  const auto hash_sexp = CheckInteger(list->ExtraLookupValue("hash"));
  const auto is_recursive = hash_sexp != nullptr;
  // This isn't necessary the hash value we will have in the new FlowGraph, but
  // it will be how this type is referred to by TypeRefs in the serialized one.
  auto const old_hash = is_recursive ? hash_sexp->value() : 0;
  ZoneGrowableArray<TypeRef*>* pending_typerefs = nullptr;
  if (is_recursive) {
    if (pending_typeref_map_.LookupValue(old_hash) != nullptr) {
      StoreError(sexp, "already parsing a type with hash %" Pd64 "",
                 hash_sexp->value());
      return false;
    }
    pending_typerefs = new (zone()) ZoneGrowableArray<TypeRef*>(zone(), 2);
    pending_typeref_map_.Insert(old_hash, pending_typerefs);
  }

  const auto cls_sexp = CheckTaggedList(Retrieve(list, 1), "Class");
  if (cls_sexp == nullptr) {
    // TODO(sstrickl): Handle types not derived from classes.
    StoreError(list, "non-class types not currently handled");
    return false;
  }
  TokenPosition token_pos = TokenPosition::kNoSource;
  if (const auto pos_sexp = CheckInteger(list->ExtraLookupValue("token_pos"))) {
    token_pos = TokenPosition::Deserialize(pos_sexp->value());
  }
  auto type_args_ptr = &Object::null_type_arguments();
  if (const auto ta_sexp = list->ExtraLookupValue("type_args")) {
    // ParseTypeArguments may re-enter ParseType after setting the contents of
    // the passed in handle, so we need to allocate a new handle here.
    auto& type_args = TypeArguments::Handle(zone());
    if (!ParseTypeArguments(ta_sexp, &type_args)) return false;
    type_args_ptr = &type_args;
  }
  // Guaranteed not to re-enter ParseType.
  if (!ParseClass(cls_sexp, &type_class_)) return false;
  const Nullability nullability =
      type_class_.IsNullClass() ? Nullability::kNullable : Nullability::kLegacy;
  *out = Type::New(type_class_, *type_args_ptr, token_pos, nullability);
  auto& type = Type::Cast(*out);
  if (auto const sig_sexp = list->ExtraLookupValue("signature")) {
    auto& function = Function::Handle(zone());
    if (!ParseDartValue(sig_sexp, &function)) return false;
    type.set_signature(function);
  }
  if (is_recursive) {
    while (!pending_typerefs->is_empty()) {
      auto const ref = pending_typerefs->RemoveLast();
      ASSERT(ref != nullptr);
      ref->set_type(type);
    }
    pending_typeref_map_.Remove(old_hash);

    // If there are still pending typerefs, we can't canonicalize yet until
    // an enclosing type where we have resolved them. This is a conservative
    // check, as we do not ensure that any of the still-pending typerefs are
    // found within this type.
    //
    // This is within the is_recursive check because if this type was
    // non-recursive, then even if there are pending type refs, we are
    // guaranteed that none of them are in this type.
    if (ArePendingTypeRefs()) return true;
  }

  // Need to set this for canonicalization. We ensure in the serializer
  // that only finalized types are successfully serialized.
  type.SetIsFinalized();
  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseTypeArguments(SExpression* sexp, Object* out) {
  ASSERT(out != nullptr);
  if (sexp == nullptr) return false;

  if (auto const sym = sexp->AsSymbol()) {
    auto const val = ParseValue(sexp, /*allow_pending=*/false);
    if (val == nullptr) {
      StoreError(sexp,
                 "expected type arguments or reference to constant definition");
      return false;
    }
    if (!val->BindsToConstant()) {
      StoreError(sexp, "reference to non-constant definition");
      return false;
    }
    *out = val->BoundConstant().raw();
    if (!out->IsTypeArguments()) {
      StoreError(sexp, "expected TypeArguments constant");
      return false;
    }
    return true;
  }
  auto const list = CheckTaggedList(sexp, "TypeArguments");
  if (list == nullptr) return false;

  *out = TypeArguments::New(list->Length() - 1, Heap::kOld);
  auto& type_args = TypeArguments::Cast(*out);
  // We may reenter ParseTypeArguments while parsing one of the elements, so we
  // need a fresh handle here.
  auto& elem = AbstractType::Handle(zone());
  for (intptr_t i = 1, n = list->Length(); i < n; i++) {
    if (!ParseAbstractType(Retrieve(list, i), &elem)) return false;
    type_args.SetTypeAt(i - 1, elem);
  }

  // If there are still pending typerefs, we can't canonicalize yet.
  if (ArePendingTypeRefs()) return true;

  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseTypeParameter(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  const Function* function = nullptr;
  const Class* cls = nullptr;
  if (auto const func_sexp = CheckSymbol(list->ExtraLookupValue("function"))) {
    if (!ParseCanonicalName(func_sexp, &type_param_function_)) return false;
    if (!type_param_function_.IsFunction() || type_param_function_.IsNull()) {
      StoreError(func_sexp, "not a function name");
      return false;
    }
    function = &type_param_function_;
  } else if (auto const class_sexp =
                 CheckInteger(list->ExtraLookupValue("class"))) {
    const intptr_t cid = class_sexp->value();
    auto const table = thread()->isolate()->class_table();
    if (!table->HasValidClassAt(cid)) {
      StoreError(class_sexp, "not a valid class id");
      return false;
    }
    type_param_class_ = table->At(cid);
    cls = &type_param_class_;
  } else {
    // If we weren't given an explicit source, check in the function for this
    // flow graph.
    ASSERT(parsed_function_ != nullptr);
    function = &parsed_function_->function();
  }

  auto const name_sexp = CheckSymbol(Retrieve(list, 1));
  if (name_sexp == nullptr) return false;
  tmp_string_ = String::New(name_sexp->value());

  *out = TypeParameter::null();
  if (function != nullptr) {
    *out = function->LookupTypeParameter(tmp_string_, nullptr);
  } else if (cls != nullptr) {
    *out = cls->LookupTypeParameter(tmp_string_);
  }
  if (out->IsNull()) {
    StoreError(name_sexp, "no type parameter found for name");
    return false;
  }
  return CanonicalizeInstance(list, out);
}

bool FlowGraphDeserializer::ParseTypeRef(SExpList* list, Object* out) {
  ASSERT(out != nullptr);
  if (list == nullptr) return false;

  const bool contains_type = list->Length() > 1;
  if (contains_type) {
    auto& type = Type::Handle(zone());
    if (!ParseAbstractType(Retrieve(list, 1), &type)) return false;
    *out = TypeRef::New(type);
    // If the TypeRef appears outside the referrent, then the referrent
    // should be already canonicalized. This serves as a double-check that
    // is the case.
    return CanonicalizeInstance(list, out);
  }
  // If there is no type in the body, then this must be a referrent to
  // a Type containing this TypeRef. That means we must have a hash value.
  auto const hash_sexp = CheckInteger(Retrieve(list, "hash"));
  if (hash_sexp == nullptr) return false;
  auto const old_hash = hash_sexp->value();
  auto const pending = pending_typeref_map_.LookupValue(old_hash);
  if (pending == nullptr) {
    StoreError(list, "reference to recursive type found outside type");
    return false;
  }
  *out = TypeRef::New(Object::null_abstract_type());
  pending->Add(static_cast<TypeRef*>(out));

  // We can only canonicalize TypeRefs appearing within their referrent
  // when its containing value is canonicalized.
  return true;
}

bool FlowGraphDeserializer::ParseCanonicalName(SExpSymbol* sym, Object* obj) {
  ASSERT(obj != nullptr);
  if (sym == nullptr) return false;
  auto const name = sym->value();
  // TODO(sstrickl): No library URL, handle this better.
  if (*name == ':') {
    StoreError(sym, "expected non-empty library");
    return false;
  }
  const char* lib_end = nullptr;
  if (auto const first = strchr(name, ':')) {
    lib_end = strchr(first + 1, ':');
    if (lib_end == nullptr) lib_end = strchr(first + 1, '\0');
  } else {
    StoreError(sym, "malformed library");
    return false;
  }
  tmp_string_ =
      String::FromUTF8(reinterpret_cast<const uint8_t*>(name), lib_end - name);
  name_library_ = Library::LookupLibrary(thread(), tmp_string_);
  if (*lib_end == '\0') {
    *obj = name_library_.raw();
    return true;
  }
  const char* const class_start = lib_end + 1;
  if (*class_start == '\0') {
    StoreError(sym, "no class found after colon");
    return false;
  }
  // If classes are followed by another part, it's either a function
  // (separated by ':') or a field (separated by '.').
  const char* class_end = strchr(class_start, ':');
  if (class_end == nullptr) class_end = strchr(class_start, '.');
  if (class_end == nullptr) class_end = strchr(class_start, '\0');
  const bool empty_name = class_end == class_start;
  name_class_ = Class::null();
  if (empty_name) {
    name_class_ = name_library_.toplevel_class();
  } else {
    tmp_string_ = String::FromUTF8(
        reinterpret_cast<const uint8_t*>(class_start), class_end - class_start);
    name_class_ = name_library_.LookupClassAllowPrivate(tmp_string_);
  }
  if (name_class_.IsNull()) {
    StoreError(sym, "failure looking up class %s in library %s",
               empty_name ? "at top level" : tmp_string_.ToCString(),
               name_library_.ToCString());
    return false;
  }
  if (*class_end == '\0') {
    *obj = name_class_.raw();
    return true;
  }
  if (*class_end == '.') {
    if (class_end[1] == '\0') {
      StoreError(sym, "no field name found after period");
      return false;
    }
    const char* const field_start = class_end + 1;
    const char* field_end = strchr(field_start, '\0');
    tmp_string_ = String::FromUTF8(
        reinterpret_cast<const uint8_t*>(field_start), field_end - field_start);
    name_field_ = name_class_.LookupFieldAllowPrivate(tmp_string_);
    if (name_field_.IsNull()) {
      StoreError(sym, "failure looking up field %s in class %s",
                 tmp_string_.ToCString(),
                 empty_name ? "at top level" : name_class_.ToCString());
      return false;
    }
    *obj = name_field_.raw();
    return true;
  }
  if (class_end[1] == '\0') {
    StoreError(sym, "no function name found after final colon");
    return false;
  }
  const char* func_start = class_end + 1;
  name_function_ = Function::null();
  while (true) {
    const char* func_end = strchr(func_start, ':');
    intptr_t name_len = func_end - func_start;
    bool is_forwarder = false;
    if (func_end != nullptr && name_len == 3) {
      // Special case for getters/setters, where they are prefixed with "get:"
      // or "set:", as those colons should not be used as separators.
      if (strncmp(func_start, "get", 3) == 0 ||
          strncmp(func_start, "set", 3) == 0) {
        func_end = strchr(func_end + 1, ':');
      } else if (strncmp(func_start, "dyn", 3) == 0) {
        // Dynamic invocation forwarders start with "dyn:" and we'll need to
        // look up the base function and then retrieve the forwarder from it.
        is_forwarder = true;
        func_start = func_end + 1;
        func_end = strchr(func_end + 1, ':');
      }
    }
    if (func_end == nullptr) func_end = strchr(func_start, '\0');
    name_len = func_end - func_start;

    // Check for tearoff names before we overwrite the contents of tmp_string_.
    if (!name_function_.IsNull()) {
      ASSERT(!tmp_string_.IsNull());
      auto const parent_name = tmp_string_.ToCString();
      // ImplicitClosureFunctions (tearoffs) have the same name as the Function
      // to which they are attached. We currently don't handle any other kinds
      // of local functions.
      if (name_function_.HasImplicitClosureFunction() && *func_end == '\0' &&
          strncmp(parent_name, func_start, name_len) == 0) {
        *obj = name_function_.ImplicitClosureFunction();
        return true;
      }
      StoreError(sym, "no handling for local functions");
      return false;
    }

    // Check for the prefix "<anonymous ..." in the name and fail if found,
    // since we can't resolve these.
    static auto const anon_prefix = "<anonymous ";
    static const intptr_t prefix_len = strlen(anon_prefix);
    if ((name_len > prefix_len) &&
        strncmp(anon_prefix, func_start, prefix_len) == 0) {
      StoreError(sym, "cannot resolve anonymous values");
      return false;
    }

    tmp_string_ = String::FromUTF8(reinterpret_cast<const uint8_t*>(func_start),
                                   name_len);
    name_function_ = name_class_.LookupFunctionAllowPrivate(tmp_string_);
    if (name_function_.IsNull()) {
      StoreError(sym, "failure looking up function %s in class %s",
                 tmp_string_.ToCString(), name_class_.ToCString());
      return false;
    }
    if (is_forwarder) {
      tmp_string_ = name_function_.name();
      tmp_string_ = Function::CreateDynamicInvocationForwarderName(tmp_string_);
      name_function_ =
          name_function_.GetDynamicInvocationForwarder(tmp_string_);
    }
    if (func_end[0] == '\0') break;
    if (func_end[1] == '\0') {
      StoreError(sym, "no function name found after final colon");
      return false;
    }
    func_start = func_end + 1;
  }
  *obj = name_function_.raw();
  return true;
}

bool FlowGraphDeserializer::ParseSlot(SExpList* list, const Slot** out) {
  ASSERT(out != nullptr);
  const auto offset_sexp = CheckInteger(Retrieve(list, 1));
  if (offset_sexp == nullptr) return false;
  const auto offset = offset_sexp->value();

  const auto kind_sexp = CheckSymbol(Retrieve(list, "kind"));
  if (kind_sexp == nullptr) return false;
  Slot::Kind kind;
  if (!Slot::ParseKind(kind_sexp->value(), &kind)) {
    StoreError(kind_sexp, "unknown Slot kind");
    return false;
  }

  switch (kind) {
    case Slot::Kind::kDartField: {
      auto& field = Field::ZoneHandle(zone());
      const auto field_sexp = CheckTaggedList(Retrieve(list, "field"), "Field");
      if (!ParseDartValue(field_sexp, &field)) return false;
      ASSERT(parsed_function_ != nullptr);
      *out =
          &Slot::Get(kernel::BaseFlowGraphBuilder::MayCloneField(zone(), field),
                     parsed_function_);
      break;
    }
    case Slot::Kind::kTypeArguments:
      *out = &Slot::GetTypeArgumentsSlotAt(thread(), offset);
      break;
    case Slot::Kind::kTypeArgumentsIndex:
      *out = &Slot::GetTypeArgumentsIndexSlot(thread(), offset);
      break;
    case Slot::Kind::kArrayElement:
      *out = &Slot::GetArrayElementSlot(thread(), offset);
      break;
    case Slot::Kind::kCapturedVariable:
      StoreError(kind_sexp, "unhandled Slot kind");
      return false;
    default:
      *out = &Slot::GetNativeSlot(kind);
      break;
  }
  return true;
}

bool FlowGraphDeserializer::ParseRange(SExpList* list, Range* out) {
  if (list == nullptr) return false;
  RangeBoundary min, max;
  if (!ParseRangeBoundary(Retrieve(list, 1), &min)) return false;
  if (list->Length() == 2) {
    max = min;
  } else {
    if (!ParseRangeBoundary(Retrieve(list, 2), &max)) return false;
  }
  out->min_ = min;
  out->max_ = max;
  return true;
}

bool FlowGraphDeserializer::ParseRangeBoundary(SExpression* sexp,
                                               RangeBoundary* out) {
  if (sexp == nullptr) return false;
  if (auto const int_sexp = sexp->AsInteger()) {
    out->kind_ = RangeBoundary::Kind::kConstant;
    out->value_ = int_sexp->value();
  } else if (auto const sym_sexp = sexp->AsSymbol()) {
    if (!RangeBoundary::ParseKind(sym_sexp->value(), &out->kind_)) return false;
  } else if (auto const list_sexp = sexp->AsList()) {
    intptr_t index;
    if (!ParseUse(CheckSymbol(Retrieve(list_sexp, 1)), &index)) return false;
    auto const def = definition_map_.LookupValue(index);
    if (def == nullptr) {
      StoreError(list_sexp, "no definition for symbolic range boundary");
      return false;
    }
    out->kind_ = RangeBoundary::Kind::kSymbol;
    out->value_ = reinterpret_cast<intptr_t>(def);
    if (auto const offset_sexp =
            CheckInteger(list_sexp->ExtraLookupValue("offset"))) {
      auto const offset = offset_sexp->value();
      if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
        StoreError(sexp, "invalid offset for symbolic range boundary");
        return false;
      }
      out->offset_ = offset;
    }
  } else {
    StoreError(sexp, "unexpected value for range boundary");
    return false;
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

bool FlowGraphDeserializer::ArePendingTypeRefs() const {
  // We'll do a deep check, because while there may be recursive types still
  // being parsed, if there are no pending type refs to those recursive types,
  // we're still good to canonicalize.
  if (pending_typeref_map_.IsEmpty()) return false;
  auto it = pending_typeref_map_.GetIterator();
  while (auto kv = it.Next()) {
    if (!kv->value->is_empty()) return true;
  }
  return false;
}

bool FlowGraphDeserializer::CreateICData(SExpList* list, Instruction* inst) {
  ASSERT(inst != nullptr);
  if (list == nullptr) return false;

  const String* function_name = nullptr;
  Array& arguments_descriptor = Array::Handle(zone());
  intptr_t num_args_checked;
  ICData::RebindRule rebind_rule;

  if (auto const call = inst->AsInstanceCall()) {
    function_name = &call->function_name();
    arguments_descriptor = call->GetArgumentsDescriptor();
    num_args_checked = call->checked_argument_count();
    rebind_rule = ICData::RebindRule::kInstance;
  } else if (auto const call = inst->AsStaticCall()) {
    function_name = &String::Handle(zone(), call->function().name());
    arguments_descriptor = call->GetArgumentsDescriptor();
    num_args_checked =
        MethodRecognizer::NumArgsCheckedForStaticCall(call->function());
    rebind_rule = ICData::RebindRule::kStatic;
  } else {
    StoreError(list, "unexpected instruction type for ICData");
    return false;
  }

  auto type_ptr = &Object::null_abstract_type();
  if (auto const type_sexp = list->ExtraLookupValue("receivers_static_type")) {
    auto& type = AbstractType::ZoneHandle(zone());
    if (!ParseAbstractType(type_sexp, &type)) return false;
    type_ptr = &type;
  }

  ASSERT(parsed_function_ != nullptr);
  auto& ic_data = ICData::ZoneHandle(
      zone(), ICData::New(parsed_function_->function(), *function_name,
                          arguments_descriptor, inst->deopt_id(),
                          num_args_checked, rebind_rule, *type_ptr));

  if (auto const is_mega_sexp =
          CheckBool(list->ExtraLookupValue("is_megamorphic"))) {
    ic_data.set_is_megamorphic(is_mega_sexp->value());
  }

  auto const class_table = thread()->isolate()->class_table();
  GrowableArray<intptr_t> class_ids(zone(), 2);
  for (intptr_t i = 1, n = list->Length(); i < n; i++) {
    auto const entry = CheckList(Retrieve(list, i));
    if (entry == nullptr) return false;
    ASSERT(ic_data.NumArgsTested() == entry->Length());

    intptr_t count = 0;
    if (auto const count_sexp =
            CheckInteger(entry->ExtraLookupValue("count"))) {
      count = count_sexp->value();
    }

    auto& target = Function::ZoneHandle(zone());
    if (!ParseDartValue(Retrieve(entry, "target"), &target)) return false;

    // We can't use AddCheck for NumArgsTested < 2. We'll handle 0 here, and
    // 1 after the for loop.
    if (entry->Length() == 0) {
      if (count != 0) {
        StoreError(entry, "expected a zero count for no checked args");
        return false;
      }
      ic_data = ICData::NewForStaticCall(parsed_function_->function(), target,
                                         arguments_descriptor, inst->deopt_id(),
                                         num_args_checked, rebind_rule);
      continue;
    }

    class_ids.Clear();
    for (intptr_t j = 0, num_cids = entry->Length(); j < num_cids; j++) {
      auto const cid_sexp = CheckInteger(Retrieve(entry, j));
      if (cid_sexp == nullptr) return false;
      const intptr_t cid = cid_sexp->value();
      // kObjectCid is a special case used for AddTarget() entries with
      // a non-zero number of checked arguments.
      if (cid != kObjectCid && !class_table->HasValidClassAt(cid)) {
        StoreError(cid_sexp, "cid is not a valid class");
        return false;
      }
      class_ids.Add(cid);
    }

    if (entry->Length() == 1) {
      ic_data.AddReceiverCheck(class_ids.At(0), target, count);
    } else {
      ic_data.AddCheck(class_ids, target, count);
    }
  }

  if (auto const call = inst->AsInstanceCall()) {
    call->set_ic_data(const_cast<const ICData*>(&ic_data));
  } else if (auto const call = inst->AsStaticCall()) {
    call->set_ic_data(&ic_data);
  }

  return true;
}

Value* FlowGraphDeserializer::AddNewPendingValue(SExpression* sexp,
                                                 intptr_t index,
                                                 bool inherit_type) {
  ASSERT(flow_graph_ != nullptr);
  auto const value = new (zone()) Value(flow_graph_->constant_null());
  ASSERT(!definition_map_.HasKey(index));
  auto list = values_map_.LookupValue(index);
  if (list == nullptr) {
    list = new (zone()) ZoneGrowableArray<PendingValue>(zone(), 2);
    values_map_.Insert(index, list);
  }
  list->Add({sexp, value, inherit_type});
  return value;
}

bool FlowGraphDeserializer::FixPendingValues(intptr_t index, Definition* def) {
  if (auto value_list = values_map_.LookupValue(index)) {
    for (intptr_t i = 0; i < value_list->length(); i++) {
      const auto& value_info = value_list->At(i);
      auto const value = value_info.value;
      const bool inherit_type = value_info.inherit_type;
      value->BindTo(def);
      if (!inherit_type) continue;
      if (def->HasType()) {
        value->reaching_type_ = def->Type();
      } else {
        StoreError(value_info.sexp, "value inherits type, but no type found");
        return false;
      }
    }
    values_map_.Remove(index);
  }
  return true;
}

BlockEntryInstr* FlowGraphDeserializer::FetchBlock(SExpSymbol* sym) {
  if (sym == nullptr) return nullptr;
  intptr_t block_id;
  if (!ParseBlockId(sym, &block_id)) return nullptr;
  auto const entry = block_map_.LookupValue(block_id);
  if (entry == nullptr) {
    StoreError(sym, "reference to undefined block");
    return nullptr;
  }
  return entry;
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
  if (label != nullptr && !sym->Equals(label)) {
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
