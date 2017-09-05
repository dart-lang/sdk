// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/flow_graph.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"

namespace dart {

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
DEFINE_FLAG(bool, trace_smi_widening, false, "Trace Smi->Int32 widening pass.");
#endif
DEFINE_FLAG(bool, prune_dead_locals, true, "optimize dead locals away");
DECLARE_FLAG(bool, verify_compiler);

FlowGraph::FlowGraph(const ParsedFunction& parsed_function,
                     GraphEntryInstr* graph_entry,
                     intptr_t max_block_id)
    : thread_(Thread::Current()),
      parent_(),
      current_ssa_temp_index_(0),
      max_block_id_(max_block_id),
      parsed_function_(parsed_function),
      num_copied_params_(parsed_function.num_copied_params()),
      num_non_copied_params_(parsed_function.num_non_copied_params()),
      graph_entry_(graph_entry),
      preorder_(),
      postorder_(),
      reverse_postorder_(),
      optimized_block_order_(),
      constant_null_(NULL),
      constant_dead_(NULL),
      constant_empty_context_(NULL),
      licm_allowed_(true),
      loop_headers_(NULL),
      loop_invariant_loads_(NULL),
      deferred_prefixes_(parsed_function.deferred_prefixes()),
      await_token_positions_(NULL),
      captured_parameters_(new (zone()) BitVector(zone(), variable_count())),
      inlining_id_(-1) {
  DiscoverBlocks();
}

void FlowGraph::EnsureSSATempIndex(Definition* defn, Definition* replacement) {
  if ((replacement->ssa_temp_index() == -1) && (defn->ssa_temp_index() != -1)) {
    AllocateSSAIndexes(replacement);
  }
}

void FlowGraph::ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                          Instruction* current,
                                          Instruction* replacement) {
  Definition* current_defn = current->AsDefinition();
  if ((replacement != NULL) && (current_defn != NULL)) {
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != NULL);
    current_defn->ReplaceUsesWith(replacement_defn);
    EnsureSSATempIndex(current_defn, replacement_defn);

    if (FLAG_trace_optimization) {
      THR_Print("Replacing v%" Pd " with v%" Pd "\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    if (current_defn == NULL) {
      THR_Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      THR_Print("Removing v%" Pd ".\n", current_defn->ssa_temp_index());
    }
  }
  if (current->ArgumentCount() != 0) {
    // Replacing a call instruction with something else.  Must remove
    // superfluous push arguments.
    for (intptr_t i = 0; i < current->ArgumentCount(); ++i) {
      PushArgumentInstr* push = current->PushArgumentAt(i);
      if (replacement == NULL || i >= replacement->ArgumentCount() ||
          replacement->PushArgumentAt(i) != push) {
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
    }
  }
  iterator->RemoveCurrentFromGraph();
}

void FlowGraph::AddToDeferredPrefixes(
    ZoneGrowableArray<const LibraryPrefix*>* from) {
  ZoneGrowableArray<const LibraryPrefix*>* to = deferred_prefixes();
  for (intptr_t i = 0; i < from->length(); i++) {
    const LibraryPrefix* prefix = (*from)[i];
    for (intptr_t j = 0; j < to->length(); j++) {
      if ((*to)[j]->raw() == prefix->raw()) {
        return;
      }
    }
    to->Add(prefix);
  }
}

bool FlowGraph::ShouldReorderBlocks(const Function& function,
                                    bool is_optimized) {
  return is_optimized && FLAG_reorder_basic_blocks && !function.is_intrinsic();
}

GrowableArray<BlockEntryInstr*>* FlowGraph::CodegenBlockOrder(
    bool is_optimized) {
  return ShouldReorderBlocks(function(), is_optimized) ? &optimized_block_order_
                                                       : &reverse_postorder_;
}

ConstantInstr* FlowGraph::GetConstant(const Object& object) {
  ConstantInstr* constant = constant_instr_pool_.LookupValue(object);
  if (constant == NULL) {
    // Otherwise, allocate and add it to the pool.
    constant =
        new (zone()) ConstantInstr(Object::ZoneHandle(zone(), object.raw()));
    constant->set_ssa_temp_index(alloc_ssa_temp_index());

    AddToInitialDefinitions(constant);
    constant_instr_pool_.Insert(constant);
  }
  return constant;
}

void FlowGraph::AddToInitialDefinitions(Definition* defn) {
  // TODO(zerny): Set previous to the graph entry so it is accessible by
  // GetBlock. Remove this once there is a direct pointer to the block.
  defn->set_previous(graph_entry_);
  graph_entry_->initial_definitions()->Add(defn);
}

void FlowGraph::InsertBefore(Instruction* next,
                             Instruction* instr,
                             Environment* env,
                             UseKind use_kind) {
  InsertAfter(next->previous(), instr, env, use_kind);
}

void FlowGraph::InsertAfter(Instruction* prev,
                            Instruction* instr,
                            Environment* env,
                            UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndexes(instr->AsDefinition());
  }
  instr->InsertAfter(prev);
  ASSERT(instr->env() == NULL);
  if (env != NULL) {
    env->DeepCopyTo(zone(), instr);
  }
}

Instruction* FlowGraph::AppendTo(Instruction* prev,
                                 Instruction* instr,
                                 Environment* env,
                                 UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndexes(instr->AsDefinition());
  }
  ASSERT(instr->env() == NULL);
  if (env != NULL) {
    env->DeepCopyTo(zone(), instr);
  }
  return prev->AppendInstruction(instr);
}

// A wrapper around block entries including an index of the next successor to
// be read.
class BlockTraversalState {
 public:
  explicit BlockTraversalState(BlockEntryInstr* block)
      : block_(block),
        next_successor_ix_(block->last_instruction()->SuccessorCount() - 1) {}

  bool HasNextSuccessor() const { return next_successor_ix_ >= 0; }
  BlockEntryInstr* NextSuccessor() {
    ASSERT(HasNextSuccessor());
    return block_->last_instruction()->SuccessorAt(next_successor_ix_--);
  }

  BlockEntryInstr* block() const { return block_; }

 private:
  BlockEntryInstr* block_;
  intptr_t next_successor_ix_;

  DISALLOW_ALLOCATION();
};

void FlowGraph::DiscoverBlocks() {
  StackZone zone(thread());

  // Initialize state.
  preorder_.Clear();
  postorder_.Clear();
  reverse_postorder_.Clear();
  parent_.Clear();

  GrowableArray<BlockTraversalState> block_stack;
  graph_entry_->DiscoverBlock(NULL, &preorder_, &parent_);
  block_stack.Add(BlockTraversalState(graph_entry_));
  while (!block_stack.is_empty()) {
    BlockTraversalState& state = block_stack.Last();
    BlockEntryInstr* block = state.block();
    if (state.HasNextSuccessor()) {
      // Process successors one-by-one.
      BlockEntryInstr* succ = state.NextSuccessor();
      if (succ->DiscoverBlock(block, &preorder_, &parent_)) {
        block_stack.Add(BlockTraversalState(succ));
      }
    } else {
      // All successors have been processed, pop the current block entry node
      // and add it to the postorder list.
      block_stack.RemoveLast();
      block->set_postorder_number(postorder_.length());
      postorder_.Add(block);
    }
  }

  ASSERT(postorder_.length() == preorder_.length());

  // Create an array of blocks in reverse postorder.
  intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; ++i) {
    reverse_postorder_.Add(postorder_[block_count - i - 1]);
  }

  loop_headers_ = NULL;
  loop_invariant_loads_ = NULL;
}

void FlowGraph::MergeBlocks() {
  bool changed = false;
  BitVector* merged = new (zone()) BitVector(zone(), postorder().length());
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (block->IsGraphEntry()) continue;
    if (merged->Contains(block->postorder_number())) continue;

    Instruction* last = block->last_instruction();
    BlockEntryInstr* successor = NULL;
    while ((!last->IsIndirectGoto()) && (last->SuccessorCount() == 1) &&
           (!last->SuccessorAt(0)->IsIndirectEntry()) &&
           (last->SuccessorAt(0)->PredecessorCount() == 1) &&
           (block->try_index() == last->SuccessorAt(0)->try_index())) {
      successor = last->SuccessorAt(0);
      ASSERT(last->IsGoto());

      // Remove environment uses and unlink goto and block entry.
      successor->UnuseAllInputs();
      last->previous()->LinkTo(successor->next());
      last->UnuseAllInputs();

      last = successor->last_instruction();
      merged->Add(successor->postorder_number());
      changed = true;
      if (FLAG_trace_optimization) {
        OS::Print("Merged blocks B%" Pd " and B%" Pd "\n", block->block_id(),
                  successor->block_id());
      }
    }
    // The new block inherits the block id of the last successor to maintain
    // the order of phi inputs at its successors consistent with block ids.
    if (successor != NULL) {
      block->set_block_id(successor->block_id());
    }
  }
  // Recompute block order after changes were made.
  if (changed) DiscoverBlocks();
}

// Debugging code to verify the construction of use lists.
static intptr_t MembershipCount(Value* use, Value* list) {
  intptr_t count = 0;
  while (list != NULL) {
    if (list == use) ++count;
    list = list->next_use();
  }
  return count;
}

static void VerifyUseListsInInstruction(Instruction* instr) {
  ASSERT(instr != NULL);
  ASSERT(!instr->IsJoinEntry());
  for (intptr_t i = 0; i < instr->InputCount(); ++i) {
    Value* use = instr->InputAt(i);
    ASSERT(use->definition() != NULL);
    ASSERT((use->definition() != instr) || use->definition()->IsPhi() ||
           use->definition()->IsMaterializeObject());
    ASSERT(use->instruction() == instr);
    ASSERT(use->use_index() == i);
    ASSERT(!FLAG_verify_compiler ||
           (1 == MembershipCount(use, use->definition()->input_use_list())));
  }
  if (instr->env() != NULL) {
    intptr_t use_index = 0;
    for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
      Value* use = it.CurrentValue();
      ASSERT(use->definition() != NULL);
      ASSERT((use->definition() != instr) || use->definition()->IsPhi());
      ASSERT(use->instruction() == instr);
      ASSERT(use->use_index() == use_index++);
      ASSERT(!FLAG_verify_compiler ||
             (1 == MembershipCount(use, use->definition()->env_use_list())));
    }
  }
  Definition* defn = instr->AsDefinition();
  if (defn != NULL) {
    // Used definitions must have an SSA name.  We use the name to index
    // into bit vectors during analyses.  Some definitions without SSA names
    // (e.g., PushArgument) have environment uses.
    ASSERT((defn->input_use_list() == NULL) || defn->HasSSATemp());
    Value* prev = NULL;
    Value* curr = defn->input_use_list();
    while (curr != NULL) {
      ASSERT(prev == curr->previous_use());
      ASSERT(defn == curr->definition());
      Instruction* instr = curr->instruction();
      // The instruction should not be removed from the graph.
      ASSERT((instr->IsPhi() && instr->AsPhi()->is_alive()) ||
             (instr->previous() != NULL));
      ASSERT(curr == instr->InputAt(curr->use_index()));
      prev = curr;
      curr = curr->next_use();
    }

    prev = NULL;
    curr = defn->env_use_list();
    while (curr != NULL) {
      ASSERT(prev == curr->previous_use());
      ASSERT(defn == curr->definition());
      Instruction* instr = curr->instruction();
      ASSERT(curr == instr->env()->ValueAtUseIndex(curr->use_index()));
      // BlockEntry instructions have environments attached to them but
      // have no reliable way to verify if they are still in the graph.
      // Thus we just assume they are.
      ASSERT(instr->IsBlockEntry() ||
             (instr->IsPhi() && instr->AsPhi()->is_alive()) ||
             (instr->previous() != NULL));
      prev = curr;
      curr = curr->next_use();
    }
  }
}

void FlowGraph::ComputeIsReceiverRecursive(
    PhiInstr* phi,
    GrowableArray<PhiInstr*>* unmark) const {
  if (phi->is_receiver() != PhiInstr::kUnknownReceiver) return;
  phi->set_is_receiver(PhiInstr::kReceiver);
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Definition* def = phi->InputAt(i)->definition();
    if (def->IsParameter() && (def->AsParameter()->index() == 0)) continue;
    if (!def->IsPhi()) {
      phi->set_is_receiver(PhiInstr::kNotReceiver);
      break;
    }
    ComputeIsReceiverRecursive(def->AsPhi(), unmark);
    if (def->AsPhi()->is_receiver() == PhiInstr::kNotReceiver) {
      phi->set_is_receiver(PhiInstr::kNotReceiver);
      break;
    }
  }

  if (phi->is_receiver() == PhiInstr::kNotReceiver) {
    unmark->Add(phi);
  }
}

void FlowGraph::ComputeIsReceiver(PhiInstr* phi) const {
  GrowableArray<PhiInstr*> unmark;
  ComputeIsReceiverRecursive(phi, &unmark);

  // Now drain unmark.
  while (!unmark.is_empty()) {
    PhiInstr* phi = unmark.RemoveLast();
    for (Value::Iterator it(phi->input_use_list()); !it.Done(); it.Advance()) {
      PhiInstr* use = it.Current()->instruction()->AsPhi();
      if ((use != NULL) && (use->is_receiver() == PhiInstr::kReceiver)) {
        use->set_is_receiver(PhiInstr::kNotReceiver);
        unmark.Add(use);
      }
    }
  }
}

bool FlowGraph::IsReceiver(Definition* def) const {
  def = def->OriginalDefinition();  // Could be redefined.
  if (def->IsParameter()) return (def->AsParameter()->index() == 0);
  if (!def->IsPhi() || graph_entry()->catch_entries().is_empty()) return false;
  PhiInstr* phi = def->AsPhi();
  if (phi->is_receiver() != PhiInstr::kUnknownReceiver) {
    return (phi->is_receiver() == PhiInstr::kReceiver);
  }
  // Not known if this phi is the receiver yet. Compute it now.
  ComputeIsReceiver(phi);
  return (phi->is_receiver() == PhiInstr::kReceiver);
}

// Use CHA to determine if the call needs a class check: if the callee's
// receiver is the same as the caller's receiver and there are no overridden
// callee functions, then no class check is needed.
bool FlowGraph::InstanceCallNeedsClassCheck(InstanceCallInstr* call,
                                            RawFunction::Kind kind) const {
  if (!FLAG_use_cha_deopt && !isolate()->all_classes_finalized()) {
    // Even if class or function are private, lazy class finalization
    // may later add overriding methods.
    return true;
  }
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  if (function().IsDynamicFunction() && IsReceiver(callee_receiver)) {
    const String& name =
        (kind == RawFunction::kMethodExtractor)
            ? String::Handle(zone(),
                             Field::NameFromGetter(call->function_name()))
            : call->function_name();
    const Class& cls = Class::Handle(zone(), function().Owner());
    intptr_t subclass_count = 0;
    if (!thread()->cha()->HasOverride(cls, name, &subclass_count)) {
      if (FLAG_trace_cha) {
        THR_Print(
            "  **(CHA) Instance call needs no check, "
            "no overrides of '%s' '%s'\n",
            name.ToCString(), cls.ToCString());
      }
      thread()->cha()->AddToGuardedClasses(cls, subclass_count);
      return false;
    }
  }
  return true;
}

Instruction* FlowGraph::CreateCheckClass(Definition* to_check,
                                         const Cids& cids,
                                         intptr_t deopt_id,
                                         TokenPosition token_pos) {
  if (cids.IsMonomorphic() && cids.MonomorphicReceiverCid() == kSmiCid) {
    return new (zone())
        CheckSmiInstr(new (zone()) Value(to_check), deopt_id, token_pos);
  }
  return new (zone())
      CheckClassInstr(new (zone()) Value(to_check), deopt_id, cids, token_pos);
}

bool FlowGraph::VerifyUseLists() {
  // Verify the initial definitions.
  for (intptr_t i = 0; i < graph_entry_->initial_definitions()->length(); ++i) {
    VerifyUseListsInInstruction((*graph_entry_->initial_definitions())[i]);
  }

  // Verify phis in join entries and the instructions in each block.
  for (intptr_t i = 0; i < preorder_.length(); ++i) {
    BlockEntryInstr* entry = preorder_[i];
    JoinEntryInstr* join = entry->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        VerifyUseListsInInstruction(phi);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      VerifyUseListsInInstruction(it.Current());
    }
  }

  return true;  // Return true so we can ASSERT validation.
}

// Verify that a redefinition dominates all uses of the redefined value.
bool FlowGraph::VerifyRedefinitions() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      RedefinitionInstr* redefinition = instr_it.Current()->AsRedefinition();
      if (redefinition != NULL) {
        Definition* original = redefinition->value()->definition();
        for (Value::Iterator it(original->input_use_list()); !it.Done();
             it.Advance()) {
          Value* original_use = it.Current();
          if (original_use->instruction() == redefinition) {
            continue;
          }
          if (original_use->instruction()->IsDominatedBy(redefinition)) {
            FlowGraphPrinter::PrintGraph("VerifyRedefinitions", this);
            THR_Print("%s\n", redefinition->ToCString());
            THR_Print("use=%s\n", original_use->instruction()->ToCString());
            return false;
          }
        }
      }
    }
  }
  return true;
}

LivenessAnalysis::LivenessAnalysis(
    intptr_t variable_count,
    const GrowableArray<BlockEntryInstr*>& postorder)
    : zone_(Thread::Current()->zone()),
      variable_count_(variable_count),
      postorder_(postorder),
      live_out_(postorder.length()),
      kill_(postorder.length()),
      live_in_(postorder.length()) {}

bool LivenessAnalysis::UpdateLiveOut(const BlockEntryInstr& block) {
  BitVector* live_out = live_out_[block.postorder_number()];
  bool changed = false;
  Instruction* last = block.last_instruction();
  ASSERT(last != NULL);
  for (intptr_t i = 0; i < last->SuccessorCount(); i++) {
    BlockEntryInstr* succ = last->SuccessorAt(i);
    ASSERT(succ != NULL);
    if (live_out->AddAll(live_in_[succ->postorder_number()])) {
      changed = true;
    }
  }
  return changed;
}

bool LivenessAnalysis::UpdateLiveIn(const BlockEntryInstr& block) {
  BitVector* live_out = live_out_[block.postorder_number()];
  BitVector* kill = kill_[block.postorder_number()];
  BitVector* live_in = live_in_[block.postorder_number()];
  return live_in->KillAndAdd(kill, live_out);
}

void LivenessAnalysis::ComputeLiveInAndLiveOutSets() {
  const intptr_t block_count = postorder_.length();
  bool changed;
  do {
    changed = false;

    for (intptr_t i = 0; i < block_count; i++) {
      const BlockEntryInstr& block = *postorder_[i];

      // Live-in set depends only on kill set which does not
      // change in this loop and live-out set.  If live-out
      // set does not change there is no need to recompute
      // live-in set.
      if (UpdateLiveOut(block) && UpdateLiveIn(block)) {
        changed = true;
      }
    }
  } while (changed);
}

void LivenessAnalysis::Analyze() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    live_out_.Add(new (zone()) BitVector(zone(), variable_count_));
    kill_.Add(new (zone()) BitVector(zone(), variable_count_));
    live_in_.Add(new (zone()) BitVector(zone(), variable_count_));
  }

  ComputeInitialSets();
  ComputeLiveInAndLiveOutSets();
}

static void PrintBitVector(const char* tag, BitVector* v) {
  OS::Print("%s:", tag);
  for (BitVector::Iterator it(v); !it.Done(); it.Advance()) {
    OS::Print(" %" Pd "", it.Current());
  }
  OS::Print("\n");
}

void LivenessAnalysis::Dump() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];
    OS::Print("block @%" Pd " -> ", block->block_id());

    Instruction* last = block->last_instruction();
    for (intptr_t j = 0; j < last->SuccessorCount(); j++) {
      BlockEntryInstr* succ = last->SuccessorAt(j);
      OS::Print(" @%" Pd "", succ->block_id());
    }
    OS::Print("\n");

    PrintBitVector("  live out", live_out_[i]);
    PrintBitVector("  kill", kill_[i]);
    PrintBitVector("  live in", live_in_[i]);
  }
}

// Computes liveness information for local variables.
class VariableLivenessAnalysis : public LivenessAnalysis {
 public:
  explicit VariableLivenessAnalysis(FlowGraph* flow_graph)
      : LivenessAnalysis(flow_graph->variable_count(), flow_graph->postorder()),
        flow_graph_(flow_graph),
        num_non_copied_params_(flow_graph->num_non_copied_params()),
        assigned_vars_() {}

  // For every block (in preorder) compute and return set of variables that
  // have new assigned values flowing out of that block.
  const GrowableArray<BitVector*>& ComputeAssignedVars() {
    // We can't directly return kill_ because it uses postorder numbering while
    // SSA construction uses preorder numbering internally.
    // We have to permute postorder into preorder.
    assigned_vars_.Clear();

    const intptr_t block_count = flow_graph_->preorder().length();
    for (intptr_t i = 0; i < block_count; i++) {
      BlockEntryInstr* block = flow_graph_->preorder()[i];
      // All locals are assigned inside a try{} block.
      // This is a safe approximation and workaround to force insertion of
      // phis for stores that appear non-live because of the way catch-blocks
      // are connected to the graph: They normally are dominated by the
      // try-entry, but are direct successors of the graph entry in our flow
      // graph.
      // TODO(fschneider): Improve this approximation by better modeling the
      // actual data flow to reduce the number of redundant phis.
      BitVector* kill = GetKillSet(block);
      if (block->InsideTryBlock()) {
        kill->SetAll();
      } else {
        kill->Intersect(GetLiveOutSet(block));
      }
      assigned_vars_.Add(kill);
    }

    return assigned_vars_;
  }

  // Returns true if the value set by the given store reaches any load from the
  // same local variable.
  bool IsStoreAlive(BlockEntryInstr* block, StoreLocalInstr* store) {
    if (store->local().Equals(*flow_graph_->CurrentContextVar())) {
      return true;
    }

    if (store->is_dead()) {
      return false;
    }
    if (store->is_last()) {
      const intptr_t index = store->local().BitIndexIn(num_non_copied_params_);
      return GetLiveOutSet(block)->Contains(index);
    }

    return true;
  }

  // Returns true if the given load is the last for the local and the value
  // of the local will not flow into another one.
  bool IsLastLoad(BlockEntryInstr* block, LoadLocalInstr* load) {
    if (load->local().Equals(*flow_graph_->CurrentContextVar())) {
      return false;
    }
    const intptr_t index = load->local().BitIndexIn(num_non_copied_params_);
    return load->is_last() && !GetLiveOutSet(block)->Contains(index);
  }

 private:
  virtual void ComputeInitialSets();

  const FlowGraph* flow_graph_;
  const intptr_t num_non_copied_params_;
  GrowableArray<BitVector*> assigned_vars_;
};

void VariableLivenessAnalysis::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();

  BitVector* last_loads = new (zone()) BitVector(zone(), variable_count_);
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];
    last_loads->Clear();

    // There is an implicit use (load-local) of every local variable at each
    // call inside a try{} block and every call has an implicit control-flow
    // to the catch entry. As an approximation we mark all locals as live
    // inside try{}.
    // TODO(fschneider): Improve this approximation, since not all local
    // variable stores actually reach a call.
    if (block->InsideTryBlock()) {
      live_in->SetAll();
      continue;
    }

    // Iterate backwards starting at the last instruction.
    for (BackwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      LoadLocalInstr* load = current->AsLoadLocal();
      if (load != NULL) {
        const intptr_t index = load->local().BitIndexIn(num_non_copied_params_);
        if (index >= live_in->length()) continue;  // Skip tmp_locals.
        live_in->Add(index);
        if (!last_loads->Contains(index)) {
          last_loads->Add(index);
          load->mark_last();
        }
        continue;
      }

      StoreLocalInstr* store = current->AsStoreLocal();
      if (store != NULL) {
        const intptr_t index =
            store->local().BitIndexIn(num_non_copied_params_);
        if (index >= live_in->length()) continue;  // Skip tmp_locals.
        if (kill->Contains(index)) {
          if (!live_in->Contains(index)) {
            store->mark_dead();
          }
        } else {
          if (!live_in->Contains(index)) {
            store->mark_last();
          }
          kill->Add(index);
        }
        live_in->Remove(index);
        continue;
      }
    }
  }
}

void FlowGraph::ComputeSSA(
    intptr_t next_virtual_register_number,
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  ASSERT((next_virtual_register_number == 0) || (inlining_parameters != NULL));
  current_ssa_temp_index_ = next_virtual_register_number;
  GrowableArray<BitVector*> dominance_frontier;
  ComputeDominators(&dominance_frontier);

  VariableLivenessAnalysis variable_liveness(this);
  variable_liveness.Analyze();

  GrowableArray<PhiInstr*> live_phis;

  InsertPhis(preorder_, variable_liveness.ComputeAssignedVars(),
             dominance_frontier, &live_phis);

  // Rename uses to reference inserted phis where appropriate.
  // Collect phis that reach a non-environment use.
  Rename(&live_phis, &variable_liveness, inlining_parameters);

  // Propagate alive mark transitively from alive phis and then remove
  // non-live ones.
  RemoveDeadPhis(&live_phis);
}

// Compute immediate dominators and the dominance frontier for each basic
// block.  As a side effect of the algorithm, sets the immediate dominator
// of each basic block.
//
// dominance_frontier: an output parameter encoding the dominance frontier.
//     The array maps the preorder block number of a block to the set of
//     (preorder block numbers of) blocks in the dominance frontier.
void FlowGraph::ComputeDominators(
    GrowableArray<BitVector*>* dominance_frontier) {
  // Use the SEMI-NCA algorithm to compute dominators.  This is a two-pass
  // version of the Lengauer-Tarjan algorithm (LT is normally three passes)
  // that eliminates a pass by using nearest-common ancestor (NCA) to
  // compute immediate dominators from semidominators.  It also removes a
  // level of indirection in the link-eval forest data structure.
  //
  // The algorithm is described in Georgiadis, Tarjan, and Werneck's
  // "Finding Dominators in Practice".
  // See http://www.cs.princeton.edu/~rwerneck/dominators/ .

  // All arrays are maps between preorder basic-block numbers.
  intptr_t size = parent_.length();
  GrowableArray<intptr_t> idom(size);   // Immediate dominator.
  GrowableArray<intptr_t> semi(size);   // Semidominator.
  GrowableArray<intptr_t> label(size);  // Label for link-eval forest.

  // 1. First pass: compute semidominators as in Lengauer-Tarjan.
  // Semidominators are computed from a depth-first spanning tree and are an
  // approximation of immediate dominators.

  // Use a link-eval data structure with path compression.  Implement path
  // compression in place by mutating the parent array.  Each block has a
  // label, which is the minimum block number on the compressed path.

  // Initialize idom, semi, and label used by SEMI-NCA.  Initialize the
  // dominance frontier output array.
  for (intptr_t i = 0; i < size; ++i) {
    idom.Add(parent_[i]);
    semi.Add(i);
    label.Add(i);
    dominance_frontier->Add(new (zone()) BitVector(zone(), size));
  }

  // Loop over the blocks in reverse preorder (not including the graph
  // entry).  Clear the dominated blocks in the graph entry in case
  // ComputeDominators is used to recompute them.
  preorder_[0]->ClearDominatedBlocks();
  for (intptr_t block_index = size - 1; block_index >= 1; --block_index) {
    // Loop over the predecessors.
    BlockEntryInstr* block = preorder_[block_index];
    // Clear the immediately dominated blocks in case ComputeDominators is
    // used to recompute them.
    block->ClearDominatedBlocks();
    for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ASSERT(pred != NULL);

      // Look for the semidominator by ascending the semidominator path
      // starting from pred.
      intptr_t pred_index = pred->preorder_number();
      intptr_t best = pred_index;
      if (pred_index > block_index) {
        CompressPath(block_index, pred_index, &parent_, &label);
        best = label[pred_index];
      }

      // Update the semidominator if we've found a better one.
      semi[block_index] = Utils::Minimum(semi[block_index], semi[best]);
    }

    // Now use label for the semidominator.
    label[block_index] = semi[block_index];
  }

  // 2. Compute the immediate dominators as the nearest common ancestor of
  // spanning tree parent and semidominator, for all blocks except the entry.
  for (intptr_t block_index = 1; block_index < size; ++block_index) {
    intptr_t dom_index = idom[block_index];
    while (dom_index > semi[block_index]) {
      dom_index = idom[dom_index];
    }
    idom[block_index] = dom_index;
    preorder_[dom_index]->AddDominatedBlock(preorder_[block_index]);
  }

  // 3. Now compute the dominance frontier for all blocks.  This is
  // algorithm in "A Simple, Fast Dominance Algorithm" (Figure 5), which is
  // attributed to a paper by Ferrante et al.  There is no bookkeeping
  // required to avoid adding a block twice to the same block's dominance
  // frontier because we use a set to represent the dominance frontier.
  for (intptr_t block_index = 0; block_index < size; ++block_index) {
    BlockEntryInstr* block = preorder_[block_index];
    intptr_t count = block->PredecessorCount();
    if (count <= 1) continue;
    for (intptr_t i = 0; i < count; ++i) {
      BlockEntryInstr* runner = block->PredecessorAt(i);
      while (runner != block->dominator()) {
        (*dominance_frontier)[runner->preorder_number()]->Add(block_index);
        runner = runner->dominator();
      }
    }
  }
}

void FlowGraph::CompressPath(intptr_t start_index,
                             intptr_t current_index,
                             GrowableArray<intptr_t>* parent,
                             GrowableArray<intptr_t>* label) {
  intptr_t next_index = (*parent)[current_index];
  if (next_index > start_index) {
    CompressPath(start_index, next_index, parent, label);
    (*label)[current_index] =
        Utils::Minimum((*label)[current_index], (*label)[next_index]);
    (*parent)[current_index] = (*parent)[next_index];
  }
}

void FlowGraph::InsertPhis(const GrowableArray<BlockEntryInstr*>& preorder,
                           const GrowableArray<BitVector*>& assigned_vars,
                           const GrowableArray<BitVector*>& dom_frontier,
                           GrowableArray<PhiInstr*>* live_phis) {
  const intptr_t block_count = preorder.length();
  // Map preorder block number to the highest variable index that has a phi
  // in that block.  Use it to avoid inserting multiple phis for the same
  // variable.
  GrowableArray<intptr_t> has_already(block_count);
  // Map preorder block number to the highest variable index for which the
  // block went on the worklist.  Use it to avoid adding the same block to
  // the worklist more than once for the same variable.
  GrowableArray<intptr_t> work(block_count);

  // Initialize has_already and work.
  for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
    has_already.Add(-1);
    work.Add(-1);
  }

  // Insert phis for each variable in turn.
  GrowableArray<BlockEntryInstr*> worklist;
  for (intptr_t var_index = 0; var_index < variable_count(); ++var_index) {
    const bool always_live =
        !FLAG_prune_dead_locals || (var_index == CurrentContextEnvIndex());
    // Add to the worklist each block containing an assignment.
    for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
      if (assigned_vars[block_index]->Contains(var_index)) {
        work[block_index] = var_index;
        worklist.Add(preorder[block_index]);
      }
    }

    while (!worklist.is_empty()) {
      BlockEntryInstr* current = worklist.RemoveLast();
      // Ensure a phi for each block in the dominance frontier of current.
      for (BitVector::Iterator it(dom_frontier[current->preorder_number()]);
           !it.Done(); it.Advance()) {
        int index = it.Current();
        if (has_already[index] < var_index) {
          BlockEntryInstr* block = preorder[index];
          ASSERT(block->IsJoinEntry());
          PhiInstr* phi =
              block->AsJoinEntry()->InsertPhi(var_index, variable_count());
          if (always_live) {
            phi->mark_alive();
            live_phis->Add(phi);
          }
          has_already[index] = var_index;
          if (work[index] < var_index) {
            work[index] = var_index;
            worklist.Add(block);
          }
        }
      }
    }
  }
}

void FlowGraph::Rename(GrowableArray<PhiInstr*>* live_phis,
                       VariableLivenessAnalysis* variable_liveness,
                       ZoneGrowableArray<Definition*>* inlining_parameters) {
  GraphEntryInstr* entry = graph_entry();

  // Initial renaming environment.
  GrowableArray<Definition*> env(variable_count());

  // Add global constants to the initial definitions.
  constant_null_ = GetConstant(Object::ZoneHandle());
  constant_dead_ = GetConstant(Symbols::OptimizedOut());
  constant_empty_context_ = GetConstant(Object::empty_context());

  // Check if inlining_parameters include a type argument vector parameter.
  const intptr_t inlined_type_args_param =
      (FLAG_reify_generic_functions && (inlining_parameters != NULL) &&
       function().IsGeneric())
          ? 1
          : 0;

  // Add parameters to the initial definitions and renaming environment.
  if (inlining_parameters != NULL) {
    // Use known parameters.
    ASSERT(inlined_type_args_param + parameter_count() ==
           inlining_parameters->length());
    for (intptr_t i = 0; i < parameter_count(); ++i) {
      // If inlined_type_args_param == 1, then (*inlining_parameters)[0]
      // is the passed-in type args. We do not add it to env[0] but to
      // env[parameter_count()] below.
      Definition* defn = (*inlining_parameters)[inlined_type_args_param + i];
      AllocateSSAIndexes(defn);
      AddToInitialDefinitions(defn);
      env.Add(defn);
    }
  } else {
    // Create new parameters.  For functions compiled for OSR, the locals
    // are unknown and so treated like parameters.
    intptr_t count = IsCompiledForOsr() ? variable_count() : parameter_count();
    for (intptr_t i = 0; i < count; ++i) {
      ParameterInstr* param = new (zone()) ParameterInstr(i, entry);
      param->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
      AddToInitialDefinitions(param);
      env.Add(param);
    }
  }

  // Initialize all locals in the renaming environment  For OSR, the locals have
  // already been handled as parameters.
  if (!IsCompiledForOsr()) {
    intptr_t i = parameter_count();
    if (FLAG_reify_generic_functions && function().IsGeneric()) {
      // The first local is the slot holding the copied passed-in type args.
      // TODO(regis): Do we need the SpecialParameterInstr if the type_args_var
      // is not needed? Add an assert for now:
      ASSERT(parsed_function().function_type_arguments() != NULL);
      Definition* defn;
      if (inlining_parameters == NULL) {
        defn = new SpecialParameterInstr(SpecialParameterInstr::kTypeArgs,
                                         Thread::kNoDeoptId);
      } else {
        defn = (*inlining_parameters)[0];
      }
      AllocateSSAIndexes(defn);
      AddToInitialDefinitions(defn);
      env.Add(defn);
      ++i;
    }
    for (; i < variable_count(); ++i) {
      if (i == CurrentContextEnvIndex()) {
        if (function().IsClosureFunction()) {
          SpecialParameterInstr* context = new SpecialParameterInstr(
              SpecialParameterInstr::kContext, Thread::kNoDeoptId);
          context->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
          AddToInitialDefinitions(context);
          env.Add(context);
        } else {
          env.Add(constant_empty_context());
        }
      } else {
        env.Add(constant_null());
      }
    }
  }

  if (entry->SuccessorCount() > 1) {
    // Functions with try-catch have a fixed area of stack slots reserved
    // so that all local variables are stored at a known location when
    // on entry to the catch.
    entry->set_fixed_slot_count(num_stack_locals() + num_copied_params());
  }
  RenameRecursive(entry, &env, live_phis, variable_liveness);
}

void FlowGraph::AttachEnvironment(Instruction* instr,
                                  GrowableArray<Definition*>* env) {
  Environment* deopt_env =
      Environment::From(zone(), *env, num_non_copied_params_, parsed_function_);
  if (instr->IsClosureCall()) {
    deopt_env =
        deopt_env->DeepCopy(zone(), deopt_env->Length() - instr->InputCount());
  }
  instr->SetEnvironment(deopt_env);
  for (Environment::DeepIterator it(deopt_env); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    use->definition()->AddEnvUse(use);
  }
  if (instr->ComputeCanDeoptimize()) {
    instr->env()->set_deopt_id(instr->deopt_id());
  }
}

void FlowGraph::RenameRecursive(BlockEntryInstr* block_entry,
                                GrowableArray<Definition*>* env,
                                GrowableArray<PhiInstr*>* live_phis,
                                VariableLivenessAnalysis* variable_liveness) {
  // 1. Process phis first.
  if (block_entry->IsJoinEntry()) {
    JoinEntryInstr* join = block_entry->AsJoinEntry();
    if (join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != NULL) {
          (*env)[i] = phi;
          AllocateSSAIndexes(phi);  // New SSA temp.
          if (block_entry->InsideTryBlock() && !phi->is_alive()) {
            // This is a safe approximation.  Inside try{} all locals are
            // used at every call implicitly, so we mark all phis as live
            // from the start.
            // TODO(fschneider): Improve this approximation to eliminate
            // more redundant phis.
            phi->mark_alive();
            live_phis->Add(phi);
          }
        }
      }
    }
  } else if (block_entry->IsCatchBlockEntry()) {
    // Add real definitions for all locals and parameters.
    for (intptr_t i = 0; i < env->length(); ++i) {
      ParameterInstr* param = new (zone()) ParameterInstr(i, block_entry);
      param->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
      (*env)[i] = param;
      block_entry->AsCatchBlockEntry()->initial_definitions()->Add(param);
    }
  }

  // Prune non-live variables at block entry by replacing their environment
  // slots with null.
  BitVector* live_in = variable_liveness->GetLiveInSet(block_entry);
  for (intptr_t i = 0; i < variable_count(); i++) {
    // TODO(fschneider): Make sure that live_in always contains the
    // CurrentContext variable to avoid the special case here.
    if (FLAG_prune_dead_locals && !live_in->Contains(i) &&
        (i != CurrentContextEnvIndex())) {
      (*env)[i] = constant_dead();
    }
  }

  // Attach environment to the block entry.
  AttachEnvironment(block_entry, env);

  // 2. Process normal instructions.
  for (ForwardInstructionIterator it(block_entry); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();

    // Attach current environment to the instructions that need it.
    if (current->NeedsEnvironment()) {
      AttachEnvironment(current, env);
    }

    // 2a. Handle uses:
    // Update the expression stack renaming environment for each use by
    // removing the renamed value.
    // For each use of a LoadLocal, StoreLocal, DropTemps or Constant: Replace
    // it with the renamed value.
    for (intptr_t i = current->InputCount() - 1; i >= 0; --i) {
      Value* v = current->InputAt(i);
      // Update expression stack.
      ASSERT(env->length() > variable_count());

      Definition* reaching_defn = env->RemoveLast();
      Definition* input_defn = v->definition();
      if (input_defn != reaching_defn) {
        ASSERT(input_defn->IsLoadLocal() || input_defn->IsStoreLocal() ||
               input_defn->IsDropTemps() || input_defn->IsConstant());
        // Assert we are not referencing nulls in the initial environment.
        ASSERT(reaching_defn->ssa_temp_index() != -1);
        v->set_definition(reaching_defn);
        input_defn = reaching_defn;
      }
      input_defn->AddInputUse(v);
    }

    // Drop pushed arguments for calls.
    for (intptr_t j = 0; j < current->ArgumentCount(); j++) {
      env->RemoveLast();
    }

    // 2b. Handle LoadLocal, StoreLocal, DropTemps and Constant.
    Definition* definition = current->AsDefinition();
    if (definition != NULL) {
      LoadLocalInstr* load = definition->AsLoadLocal();
      StoreLocalInstr* store = definition->AsStoreLocal();
      DropTempsInstr* drop = definition->AsDropTemps();
      ConstantInstr* constant = definition->AsConstant();
      if ((load != NULL) || (store != NULL) || (drop != NULL) ||
          (constant != NULL)) {
        Definition* result = NULL;
        if (store != NULL) {
          // Update renaming environment.
          intptr_t index = store->local().BitIndexIn(num_non_copied_params_);
          result = store->value()->definition();

          if (!FLAG_prune_dead_locals ||
              variable_liveness->IsStoreAlive(block_entry, store)) {
            (*env)[index] = result;
          } else {
            (*env)[index] = constant_dead();
          }
        } else if (load != NULL) {
          // The graph construction ensures we do not have an unused LoadLocal
          // computation.
          ASSERT(definition->HasTemp());
          intptr_t index = load->local().BitIndexIn(num_non_copied_params_);
          result = (*env)[index];

          PhiInstr* phi = result->AsPhi();
          if ((phi != NULL) && !phi->is_alive()) {
            phi->mark_alive();
            live_phis->Add(phi);
          }

          if (FLAG_prune_dead_locals &&
              variable_liveness->IsLastLoad(block_entry, load)) {
            (*env)[index] = constant_dead();
          }

          // Record captured parameters so that they can be skipped when
          // emitting sync code inside optimized try-blocks.
          if (load->local().is_captured_parameter()) {
            intptr_t index = load->local().BitIndexIn(num_non_copied_params_);
            captured_parameters_->Add(index);
          }
        } else if (drop != NULL) {
          // Drop temps from the environment.
          for (intptr_t j = 0; j < drop->num_temps(); j++) {
            env->RemoveLast();
          }
          if (drop->value() != NULL) {
            result = drop->value()->definition();
          }
          ASSERT((drop->value() != NULL) || !drop->HasTemp());
        } else {
          if (definition->HasTemp()) {
            result = GetConstant(constant->value());
          }
        }
        // Update expression stack or remove from graph.
        if (definition->HasTemp()) {
          ASSERT(result != NULL);
          env->Add(result);
        }
        it.RemoveCurrentFromGraph();
      } else {
        // Not a load, store, drop or constant.
        if (definition->HasTemp()) {
          // Assign fresh SSA temporary and update expression stack.
          AllocateSSAIndexes(definition);
          env->Add(definition);
        }
      }
    }

    // 2c. Handle pushed argument.
    PushArgumentInstr* push = current->AsPushArgument();
    if (push != NULL) {
      env->Add(push);
    }
  }

  // 3. Process dominated blocks.
  for (intptr_t i = 0; i < block_entry->dominated_blocks().length(); ++i) {
    BlockEntryInstr* block = block_entry->dominated_blocks()[i];
    GrowableArray<Definition*> new_env(env->length());
    new_env.AddArray(*env);
    RenameRecursive(block, &new_env, live_phis, variable_liveness);
  }

  // 4. Process successor block. We have edge-split form, so that only blocks
  // with one successor can have a join block as successor.
  if ((block_entry->last_instruction()->SuccessorCount() == 1) &&
      block_entry->last_instruction()->SuccessorAt(0)->IsJoinEntry()) {
    JoinEntryInstr* successor =
        block_entry->last_instruction()->SuccessorAt(0)->AsJoinEntry();
    intptr_t pred_index = successor->IndexOfPredecessor(block_entry);
    ASSERT(pred_index >= 0);
    if (successor->phis() != NULL) {
      for (intptr_t i = 0; i < successor->phis()->length(); ++i) {
        PhiInstr* phi = (*successor->phis())[i];
        if (phi != NULL) {
          // Rename input operand.
          Value* use = new (zone()) Value((*env)[i]);
          phi->SetInputAt(pred_index, use);
        }
      }
    }
  }
}

void FlowGraph::RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis) {
  // Augment live_phis with those that have implicit real used at
  // potentially throwing instructions if there is a try-catch in this graph.
  if (graph_entry()->SuccessorCount() > 1) {
    for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
      JoinEntryInstr* join = it.Current()->AsJoinEntry();
      if (join == NULL) continue;
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* phi = phi_it.Current();
        if (phi == NULL || phi->is_alive() || (phi->input_use_list() != NULL) ||
            (phi->env_use_list() == NULL)) {
          continue;
        }
        for (Value::Iterator it(phi->env_use_list()); !it.Done();
             it.Advance()) {
          Value* use = it.Current();
          if (use->instruction()->MayThrow() &&
              use->instruction()->GetBlock()->InsideTryBlock()) {
            live_phis->Add(phi);
            phi->mark_alive();
            break;
          }
        }
      }
    }
  }

  while (!live_phis->is_empty()) {
    PhiInstr* phi = live_phis->RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      PhiInstr* used_phi = val->definition()->AsPhi();
      if ((used_phi != NULL) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis->Add(used_phi);
      }
    }
  }

  for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
    JoinEntryInstr* join = it.Current()->AsJoinEntry();
    if (join != NULL) join->RemoveDeadPhis(constant_dead());
  }
}

RedefinitionInstr* FlowGraph::EnsureRedefinition(Instruction* prev,
                                                 Definition* original,
                                                 CompileType compile_type) {
  RedefinitionInstr* first = prev->next()->AsRedefinition();
  if (first != NULL && (first->constrained_type() != NULL)) {
    if ((first->value()->definition() == original) &&
        first->constrained_type()->IsEqualTo(&compile_type)) {
      // Already redefined. Do nothing.
      return NULL;
    }
  }
  RedefinitionInstr* redef = new RedefinitionInstr(new Value(original));
  redef->set_constrained_type(new CompileType(compile_type));
  InsertAfter(prev, redef, NULL, FlowGraph::kValue);
  RenameDominatedUses(original, redef, redef);
  return redef;
}

void FlowGraph::RemoveRedefinitions() {
  // Remove redefinition instructions inserted to inhibit hoisting.
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    thread()->CheckForSafepoint();
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      RedefinitionInstr* redefinition = instr_it.Current()->AsRedefinition();
      if (redefinition != NULL) {
        Definition* original;
        do {
          original = redefinition->value()->definition();
        } while (original->IsRedefinition());
        redefinition->ReplaceUsesWith(original);
        instr_it.RemoveCurrentFromGraph();
      }
    }
  }
}

// Find the natural loop for the back edge m->n and attach loop information
// to block n (loop header). The algorithm is described in "Advanced Compiler
// Design & Implementation" (Muchnick) p192.
BitVector* FlowGraph::FindLoop(BlockEntryInstr* m, BlockEntryInstr* n) const {
  GrowableArray<BlockEntryInstr*> stack;
  BitVector* loop = new (zone()) BitVector(zone(), preorder_.length());

  loop->Add(n->preorder_number());
  if (n != m) {
    loop->Add(m->preorder_number());
    stack.Add(m);
  }

  while (!stack.is_empty()) {
    BlockEntryInstr* p = stack.RemoveLast();
    for (intptr_t i = 0; i < p->PredecessorCount(); ++i) {
      BlockEntryInstr* q = p->PredecessorAt(i);
      if (!loop->Contains(q->preorder_number())) {
        loop->Add(q->preorder_number());
        stack.Add(q);
      }
    }
  }
  return loop;
}

ZoneGrowableArray<BlockEntryInstr*>* FlowGraph::ComputeLoops() const {
  ZoneGrowableArray<BlockEntryInstr*>* loop_headers =
      new (zone()) ZoneGrowableArray<BlockEntryInstr*>();

  for (BlockIterator it = postorder_iterator(); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (block->Dominates(pred)) {
        if (FLAG_trace_optimization) {
          OS::Print("Back edge B%" Pd " -> B%" Pd "\n", pred->block_id(),
                    block->block_id());
        }
        BitVector* loop_info = FindLoop(pred, block);
        // Loops that share the same loop header are treated as one loop.
        BlockEntryInstr* header = NULL;
        for (intptr_t i = 0; i < loop_headers->length(); ++i) {
          if ((*loop_headers)[i] == block) {
            header = (*loop_headers)[i];
            break;
          }
        }
        if (header != NULL) {
          header->loop_info()->AddAll(loop_info);
        } else {
          block->set_loop_info(loop_info);
          loop_headers->Add(block);
        }
      }
    }
  }
  if (FLAG_trace_optimization) {
    for (intptr_t i = 0; i < loop_headers->length(); ++i) {
      BlockEntryInstr* header = (*loop_headers)[i];
      OS::Print("Loop header B%" Pd "\n", header->block_id());
      for (BitVector::Iterator it(header->loop_info()); !it.Done();
           it.Advance()) {
        OS::Print("  B%" Pd "\n", preorder_[it.Current()]->block_id());
      }
    }
  }
  return loop_headers;
}

intptr_t FlowGraph::InstructionCount() const {
  intptr_t size = 0;
  // Iterate each block, skipping the graph entry.
  for (intptr_t i = 1; i < preorder_.length(); ++i) {
    for (ForwardInstructionIterator it(preorder_[i]); !it.Done();
         it.Advance()) {
      ++size;
    }
  }
  return size;
}

// Quick access to the current zone.
#define Z (zone())

void FlowGraph::ConvertUse(Value* use, Representation from_rep) {
  const Representation to_rep =
      use->instruction()->RequiredInputRepresentation(use->use_index());
  if (from_rep == to_rep || to_rep == kNoRepresentation) {
    return;
  }
  InsertConversion(from_rep, to_rep, use, /*is_environment_use=*/false);
}

static bool IsUnboxedInteger(Representation rep) {
  return (rep == kUnboxedInt32) || (rep == kUnboxedUint32) ||
         (rep == kUnboxedInt64);
}

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}

static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}

static bool CanConvertUnboxedMintToDouble() {
  return FlowGraphCompiler::CanConvertUnboxedMintToDouble();
}

void FlowGraph::InsertConversion(Representation from,
                                 Representation to,
                                 Value* use,
                                 bool is_environment_use) {
  Instruction* insert_before;
  Instruction* deopt_target;
  PhiInstr* phi = use->instruction()->AsPhi();
  if (phi != NULL) {
    ASSERT(phi->is_alive());
    // For phis conversions have to be inserted in the predecessor.
    insert_before =
        phi->block()->PredecessorAt(use->use_index())->last_instruction();
    deopt_target = NULL;
  } else {
    deopt_target = insert_before = use->instruction();
  }

  Definition* converted = NULL;
  if (IsUnboxedInteger(from) && IsUnboxedInteger(to)) {
    const intptr_t deopt_id = (to == kUnboxedInt32) && (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : Thread::kNoDeoptId;
    converted = new (Z)
        UnboxedIntConverterInstr(from, to, use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedInt32) && (to == kUnboxedDouble)) {
    converted = new Int32ToDoubleInstr(use->CopyWithType());
  } else if ((from == kUnboxedInt64) && (to == kUnboxedDouble) &&
             CanConvertUnboxedMintToDouble()) {
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : Thread::kNoDeoptId;
    ASSERT(CanUnboxDouble());
    converted = new MintToDoubleInstr(use->CopyWithType(), deopt_id);
  } else if ((from == kTagged) && Boxing::Supports(to)) {
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : Thread::kNoDeoptId;
    converted = UnboxInstr::Create(to, use->CopyWithType(), deopt_id);
  } else if ((to == kTagged) && Boxing::Supports(from)) {
    converted = BoxInstr::Create(from, use->CopyWithType());
  } else {
    // We have failed to find a suitable conversion instruction.
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : Thread::kNoDeoptId;
    ASSERT(Boxing::Supports(from));
    ASSERT(Boxing::Supports(to));
    Definition* boxed = BoxInstr::Create(from, use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, FlowGraph::kValue);
    converted = UnboxInstr::Create(to, new (Z) Value(boxed), deopt_id);
  }
  ASSERT(converted != NULL);
  InsertBefore(insert_before, converted, use->instruction()->env(),
               FlowGraph::kValue);
  if (is_environment_use) {
    use->BindToEnvironment(converted);
  } else {
    use->BindTo(converted);
  }

  if ((to == kUnboxedInt32) && (phi != NULL)) {
    // Int32 phis are unboxed optimistically. Ensure that unboxing
    // has deoptimization target attached from the goto instruction.
    CopyDeoptTarget(converted, insert_before);
  }
}

void FlowGraph::ConvertEnvironmentUse(Value* use, Representation from_rep) {
  const Representation to_rep = kTagged;
  if (from_rep == to_rep) {
    return;
  }
  InsertConversion(from_rep, to_rep, use, /*is_environment_use=*/true);
}

void FlowGraph::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    ConvertUse(it.Current(), from_rep);
  }

  if (graph_entry()->SuccessorCount() > 1) {
    for (Value::Iterator it(def->env_use_list()); !it.Done(); it.Advance()) {
      Value* use = it.Current();
      if (use->instruction()->MayThrow() &&
          use->instruction()->GetBlock()->InsideTryBlock()) {
        // Environment uses at calls inside try-blocks must be converted to
        // tagged representation.
        ConvertEnvironmentUse(it.Current(), from_rep);
      }
    }
  }
}

static void UnboxPhi(PhiInstr* phi) {
  Representation unboxed = phi->representation();

  switch (phi->Type()->ToCid()) {
    case kDoubleCid:
      if (CanUnboxDouble()) {
        unboxed = kUnboxedDouble;
      }
      break;
    case kFloat32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat32x4;
      }
      break;
    case kInt32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedInt32x4;
      }
      break;
    case kFloat64x2Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat64x2;
      }
      break;
  }

  if ((kSmiBits < 32) && (unboxed == kTagged) && phi->Type()->IsInt() &&
      RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt64)) {
    // On 32-bit platforms conservatively unbox phis that:
    //   - are proven to be of type Int;
    //   - fit into 64bits range;
    //   - have either constants or Box() operations as inputs;
    //   - have at least one Box() operation as an input;
    //   - are used in at least 1 Unbox() operation.
    bool should_unbox = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsBox() &&
          RangeUtils::Fits(input->range(),
                           RangeBoundary::kRangeBoundaryInt64)) {
        should_unbox = true;
      } else if (!input->IsConstant()) {
        should_unbox = false;
        break;
      }
    }

    if (should_unbox) {
      // We checked inputs. Check if phi is used in at least one unbox
      // operation.
      bool has_unboxed_use = false;
      for (Value* use = phi->input_use_list(); use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        if (instr->IsUnbox()) {
          has_unboxed_use = true;
          break;
        } else if (IsUnboxedInteger(
                       instr->RequiredInputRepresentation(use->use_index()))) {
          has_unboxed_use = true;
          break;
        }
      }

      if (!has_unboxed_use) {
        should_unbox = false;
      }
    }

    if (should_unbox) {
      unboxed =
          RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt32)
              ? kUnboxedInt32
              : kUnboxedInt64;
    }
  }

  phi->set_representation(unboxed);
}

void FlowGraph::SelectRepresentations() {
  // Conservatively unbox all phis that were proven to be of Double,
  // Float32x4, or Int32x4 type.
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    JoinEntryInstr* join_entry = block_it.Current()->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        UnboxPhi(phi);
      }
    }
  }

  // Process all instructions and insert conversions where needed.
  // Visit incoming parameters and constants.
  for (intptr_t i = 0; i < graph_entry()->initial_definitions()->length();
       i++) {
    InsertConversionsFor((*graph_entry()->initial_definitions())[i]);
  }

  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();
    JoinEntryInstr* join_entry = entry->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        ASSERT(phi->is_alive());
        InsertConversionsFor(phi);
      }
    }
    CatchBlockEntryInstr* catch_entry = entry->AsCatchBlockEntry();
    if (catch_entry != NULL) {
      for (intptr_t i = 0; i < catch_entry->initial_definitions()->length();
           i++) {
        InsertConversionsFor((*catch_entry->initial_definitions())[i]);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* def = it.Current()->AsDefinition();
      if (def != NULL) {
        InsertConversionsFor(def);
      }
    }
  }
}

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
// Smi widening pass is only meaningful on platforms where Smi
// is smaller than 32bit. For now only support it on ARM and ia32.
static bool CanBeWidened(BinarySmiOpInstr* smi_op) {
  return BinaryInt32OpInstr::IsSupported(smi_op->op_kind(), smi_op->left(),
                                         smi_op->right());
}

static bool BenefitsFromWidening(BinarySmiOpInstr* smi_op) {
  // TODO(vegorov): when shifts with non-constants shift count are supported
  // add them here as we save untagging for the count.
  switch (smi_op->op_kind()) {
    case Token::kMUL:
    case Token::kSHR:
      // For kMUL we save untagging of the argument for kSHR
      // we save tagging of the result.
      return true;

    default:
      return false;
  }
}

void FlowGraph::WidenSmiToInt32() {
  GrowableArray<BinarySmiOpInstr*> candidates;

  // Step 1. Collect all instructions that potentially benefit from widening of
  // their operands (or their result) into int32 range.
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      BinarySmiOpInstr* smi_op = instr_it.Current()->AsBinarySmiOp();
      if ((smi_op != NULL) && smi_op->HasSSATemp() &&
          BenefitsFromWidening(smi_op) && CanBeWidened(smi_op)) {
        candidates.Add(smi_op);
      }
    }
  }

  if (candidates.is_empty()) {
    return;
  }

  // Step 2. For each block in the graph compute which loop it belongs to.
  // We will use this information later during computation of the widening's
  // gain: we are going to assume that only conversion occurring inside the
  // same loop should be counted against the gain, all other conversions
  // can be hoisted and thus cost nothing compared to the loop cost itself.
  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers = LoopHeaders();

  GrowableArray<intptr_t> loops(preorder().length());
  for (intptr_t i = 0; i < preorder().length(); i++) {
    loops.Add(-1);
  }

  for (intptr_t loop_id = 0; loop_id < loop_headers.length(); ++loop_id) {
    for (BitVector::Iterator loop_it(loop_headers[loop_id]->loop_info());
         !loop_it.Done(); loop_it.Advance()) {
      loops[loop_it.Current()] = loop_id;
    }
  }

  // Step 3. For each candidate transitively collect all other BinarySmiOpInstr
  // and PhiInstr that depend on it and that it depends on and count amount of
  // untagging operations that we save in assumption that this whole graph of
  // values is using kUnboxedInt32 representation instead of kTagged.
  // Convert those graphs that have positive gain to kUnboxedInt32.

  // BitVector containing SSA indexes of all processed definitions. Used to skip
  // those candidates that belong to dependency graph of another candidate.
  BitVector* processed = new (Z) BitVector(Z, current_ssa_temp_index());

  // Worklist used to collect dependency graph.
  DefinitionWorklist worklist(this, candidates.length());
  for (intptr_t i = 0; i < candidates.length(); i++) {
    BinarySmiOpInstr* op = candidates[i];
    if (op->WasEliminated() || processed->Contains(op->ssa_temp_index())) {
      continue;
    }

    if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
      THR_Print("analysing candidate: %s\n", op->ToCString());
    }
    worklist.Clear();
    worklist.Add(op);

    // Collect dependency graph. Note: more items are added to worklist
    // inside this loop.
    intptr_t gain = 0;
    for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
      Definition* defn = worklist.definitions()[j];

      if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
        THR_Print("> %s\n", defn->ToCString());
      }

      if (defn->IsBinarySmiOp() &&
          BenefitsFromWidening(defn->AsBinarySmiOp())) {
        gain++;
        if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
          THR_Print("^ [%" Pd "] (o) %s\n", gain, defn->ToCString());
        }
      }

      const intptr_t defn_loop = loops[defn->GetBlock()->preorder_number()];

      // Process all inputs.
      for (intptr_t k = 0; k < defn->InputCount(); k++) {
        Definition* input = defn->InputAt(k)->definition();
        if (input->IsBinarySmiOp() && CanBeWidened(input->AsBinarySmiOp())) {
          worklist.Add(input);
        } else if (input->IsPhi() && (input->Type()->ToCid() == kSmiCid)) {
          worklist.Add(input);
        } else if (input->IsBinaryInt64Op()) {
          // Mint operation produces untagged result. We avoid tagging.
          gain++;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("^ [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        } else if (defn_loop == loops[input->GetBlock()->preorder_number()] &&
                   (input->Type()->ToCid() == kSmiCid)) {
          // Input comes from the same loop, is known to be smi and requires
          // untagging.
          // TODO(vegorov) this heuristic assumes that values that are not
          // known to be smi have to be checked and this check can be
          // coalesced with untagging. Start coalescing them.
          gain--;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("v [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        }
      }

      // Process all uses.
      for (Value* use = defn->input_use_list(); use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        Definition* use_defn = instr->AsDefinition();
        if (use_defn == NULL) {
          // We assume that tagging before returning or pushing argument costs
          // very little compared to the cost of the return/call itself.
          if (!instr->IsReturn() && !instr->IsPushArgument()) {
            gain--;
            if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
              THR_Print("v [%" Pd "] (u) %s\n", gain,
                        use->instruction()->ToCString());
            }
          }
          continue;
        } else if (use_defn->IsBinarySmiOp() &&
                   CanBeWidened(use_defn->AsBinarySmiOp())) {
          worklist.Add(use_defn);
        } else if (use_defn->IsPhi() &&
                   use_defn->AsPhi()->Type()->ToCid() == kSmiCid) {
          worklist.Add(use_defn);
        } else if (use_defn->IsBinaryInt64Op()) {
          // BinaryInt64Op requires untagging of its inputs.
          // Converting kUnboxedInt32 to kUnboxedInt64 is essentially zero cost
          // sign extension operation.
          gain++;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("^ [%" Pd "] (u) %s\n", gain,
                      use->instruction()->ToCString());
          }
        } else if (defn_loop == loops[instr->GetBlock()->preorder_number()]) {
          gain--;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("v [%" Pd "] (u) %s\n", gain,
                      use->instruction()->ToCString());
          }
        }
      }
    }

    processed->AddAll(worklist.contains_vector());

    if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
      THR_Print("~ %s gain %" Pd "\n", op->ToCString(), gain);
    }

    if (gain > 0) {
      // We have positive gain from widening. Convert all BinarySmiOpInstr into
      // BinaryInt32OpInstr and set representation of all phis to kUnboxedInt32.
      for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
        Definition* defn = worklist.definitions()[j];
        ASSERT(defn->IsPhi() || defn->IsBinarySmiOp());

        if (defn->IsBinarySmiOp()) {
          BinarySmiOpInstr* smi_op = defn->AsBinarySmiOp();
          BinaryInt32OpInstr* int32_op = new (Z) BinaryInt32OpInstr(
              smi_op->op_kind(), smi_op->left()->CopyWithType(),
              smi_op->right()->CopyWithType(), smi_op->DeoptimizationTarget());

          smi_op->ReplaceWith(int32_op, NULL);
        } else if (defn->IsPhi()) {
          defn->AsPhi()->set_representation(kUnboxedInt32);
          ASSERT(defn->Type()->IsInt());
        }
      }
    }
  }
}
#else
void FlowGraph::WidenSmiToInt32() {
  // TODO(vegorov) ideally on 64-bit platforms we would like to narrow smi
  // operations to 32-bit where it saves tagging and untagging and allows
  // to use shorted (and faster) instructions. But we currently don't
  // save enough range information in the ICData to drive this decision.
}
#endif

void FlowGraph::EliminateEnvironments() {
  // After this pass we can no longer perform LICM and hoist instructions
  // that can deoptimize.

  disallow_licm();
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (!block->IsCatchBlockEntry()) {
      block->RemoveEnvironment();
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (!current->ComputeCanDeoptimize() &&
          (!current->MayThrow() || !current->GetBlock()->InsideTryBlock())) {
        // Instructions that can throw need an environment for optimized
        // try-catch.
        // TODO(srdjan): --source-lines needs deopt environments to get at
        // the code for this instruction, however, leaving the environment
        // changes code.
        current->RemoveEnvironment();
      }
    }
  }
}

bool FlowGraph::Canonicalize() {
  bool changed = false;

  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      Instruction* current = it.Current();
      if (current->HasUnmatchedInputRepresentations()) {
        // Can't canonicalize this instruction until all conversions for its
        // inputs are inserted.
        continue;
      }

      Instruction* replacement = current->Canonicalize(this);

      if (replacement != current) {
        // For non-definitions Canonicalize should return either NULL or
        // this.
        ASSERT((replacement == NULL) || current->IsDefinition());
        ReplaceCurrentInstruction(&it, current, replacement);
        changed = true;
      }
    }
  }
  return changed;
}

// Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
// shift can be a truncating Smi shift-left and result is always Smi.
// Merging occurs only per basic-block.
void FlowGraph::TryOptimizePatterns() {
  if (!FLAG_truncating_left_shift) return;
  GrowableArray<BinarySmiOpInstr*> div_mod_merge;
  GrowableArray<InvokeMathCFunctionInstr*> sin_cos_merge;
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    // Merging only per basic-block.
    div_mod_merge.Clear();
    sin_cos_merge.Clear();
    ForwardInstructionIterator it(block_it.Current());
    for (; !it.Done(); it.Advance()) {
      if (it.Current()->IsBinarySmiOp()) {
        BinarySmiOpInstr* binop = it.Current()->AsBinarySmiOp();
        if (binop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(&it, binop, binop->left()->definition(),
                                       binop->right()->definition());
        } else if ((binop->op_kind() == Token::kTRUNCDIV) ||
                   (binop->op_kind() == Token::kMOD)) {
          if (binop->HasUses()) {
            div_mod_merge.Add(binop);
          }
        }
      } else if (it.Current()->IsBinaryInt64Op()) {
        BinaryInt64OpInstr* mintop = it.Current()->AsBinaryInt64Op();
        if (mintop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(&it, mintop,
                                       mintop->left()->definition(),
                                       mintop->right()->definition());
        }
      } else if (it.Current()->IsInvokeMathCFunction()) {
        InvokeMathCFunctionInstr* math_unary =
            it.Current()->AsInvokeMathCFunction();
        if ((math_unary->recognized_kind() == MethodRecognizer::kMathSin) ||
            (math_unary->recognized_kind() == MethodRecognizer::kMathCos)) {
          if (math_unary->HasUses()) {
            sin_cos_merge.Add(math_unary);
          }
        }
      }
    }
    TryMergeTruncDivMod(&div_mod_merge);
  }
}

// Returns true if use is dominated by the given instruction.
// Note: uses that occur at instruction itself are not dominated by it.
static bool IsDominatedUse(Instruction* dom, Value* use) {
  BlockEntryInstr* dom_block = dom->GetBlock();

  Instruction* instr = use->instruction();

  PhiInstr* phi = instr->AsPhi();
  if (phi != NULL) {
    return dom_block->Dominates(phi->block()->PredecessorAt(use->use_index()));
  }

  BlockEntryInstr* use_block = instr->GetBlock();
  if (use_block == dom_block) {
    // Fast path for the case of block entry.
    if (dom_block == dom) return true;

    for (Instruction* curr = dom->next(); curr != NULL; curr = curr->next()) {
      if (curr == instr) return true;
    }

    return false;
  }

  return dom_block->Dominates(use_block);
}

void FlowGraph::RenameDominatedUses(Definition* def,
                                    Instruction* dom,
                                    Definition* other) {
  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    if (IsDominatedUse(dom, use)) {
      use->BindTo(other);
    }
  }
}

void FlowGraph::RenameUsesDominatedByRedefinitions() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      RedefinitionInstr* redefinition = instr_it.Current()->AsRedefinition();
      if (redefinition != NULL) {
        Definition* original = redefinition->value()->definition();
        RenameDominatedUses(original, redefinition, redefinition);
      }
    }
  }
}

static bool IsPositiveOrZeroSmiConst(Definition* d) {
  ConstantInstr* const_instr = d->AsConstant();
  if ((const_instr != NULL) && (const_instr->value().IsSmi())) {
    return Smi::Cast(const_instr->value()).Value() >= 0;
  }
  return false;
}

static BinarySmiOpInstr* AsSmiShiftLeftInstruction(Definition* d) {
  BinarySmiOpInstr* instr = d->AsBinarySmiOp();
  if ((instr != NULL) && (instr->op_kind() == Token::kSHL)) {
    return instr;
  }
  return NULL;
}

void FlowGraph::OptimizeLeftShiftBitAndSmiOp(
    ForwardInstructionIterator* current_iterator,
    Definition* bit_and_instr,
    Definition* left_instr,
    Definition* right_instr) {
  ASSERT(bit_and_instr != NULL);
  ASSERT((left_instr != NULL) && (right_instr != NULL));

  // Check for pattern, smi_shift_left must be single-use.
  bool is_positive_or_zero = IsPositiveOrZeroSmiConst(left_instr);
  if (!is_positive_or_zero) {
    is_positive_or_zero = IsPositiveOrZeroSmiConst(right_instr);
  }
  if (!is_positive_or_zero) return;

  BinarySmiOpInstr* smi_shift_left = NULL;
  if (bit_and_instr->InputAt(0)->IsSingleUse()) {
    smi_shift_left = AsSmiShiftLeftInstruction(left_instr);
  }
  if ((smi_shift_left == NULL) && (bit_and_instr->InputAt(1)->IsSingleUse())) {
    smi_shift_left = AsSmiShiftLeftInstruction(right_instr);
  }
  if (smi_shift_left == NULL) return;

  // Pattern recognized.
  smi_shift_left->mark_truncating();
  ASSERT(bit_and_instr->IsBinarySmiOp() || bit_and_instr->IsBinaryInt64Op());
  if (bit_and_instr->IsBinaryInt64Op()) {
    // Replace Mint op with Smi op.
    BinarySmiOpInstr* smi_op = new (Z) BinarySmiOpInstr(
        Token::kBIT_AND, new (Z) Value(left_instr), new (Z) Value(right_instr),
        Thread::kNoDeoptId);  // BIT_AND cannot deoptimize.
    bit_and_instr->ReplaceWith(smi_op, current_iterator);
  }
}

// Dart:
//  var x = d % 10;
//  var y = d ~/ 10;
//  var z = x + y;
//
// IL:
//  v4 <- %(v2, v3)
//  v5 <- ~/(v2, v3)
//  v6 <- +(v4, v5)
//
// IL optimized:
//  v4 <- DIVMOD(v2, v3);
//  v5 <- LoadIndexed(v4, 0); // ~/ result
//  v6 <- LoadIndexed(v4, 1); // % result
//  v7 <- +(v5, v6)
// Because of the environment it is important that merged instruction replaces
// first original instruction encountered.
void FlowGraph::TryMergeTruncDivMod(
    GrowableArray<BinarySmiOpInstr*>* merge_candidates) {
  if (merge_candidates->length() < 2) {
    // Need at least a TRUNCDIV and a MOD.
    return;
  }
  for (intptr_t i = 0; i < merge_candidates->length(); i++) {
    BinarySmiOpInstr* curr_instr = (*merge_candidates)[i];
    if (curr_instr == NULL) {
      // Instruction was merged already.
      continue;
    }
    ASSERT((curr_instr->op_kind() == Token::kTRUNCDIV) ||
           (curr_instr->op_kind() == Token::kMOD));
    // Check if there is kMOD/kTRUNDIV binop with same inputs.
    const Token::Kind other_kind = (curr_instr->op_kind() == Token::kTRUNCDIV)
                                       ? Token::kMOD
                                       : Token::kTRUNCDIV;
    Definition* left_def = curr_instr->left()->definition();
    Definition* right_def = curr_instr->right()->definition();
    for (intptr_t k = i + 1; k < merge_candidates->length(); k++) {
      BinarySmiOpInstr* other_binop = (*merge_candidates)[k];
      // 'other_binop' can be NULL if it was already merged.
      if ((other_binop != NULL) && (other_binop->op_kind() == other_kind) &&
          (other_binop->left()->definition() == left_def) &&
          (other_binop->right()->definition() == right_def)) {
        (*merge_candidates)[k] = NULL;  // Clear it.
        ASSERT(curr_instr->HasUses());
        AppendExtractNthOutputForMerged(
            curr_instr, TruncDivModInstr::OutputIndexOf(curr_instr->op_kind()),
            kTagged, kSmiCid);
        ASSERT(other_binop->HasUses());
        AppendExtractNthOutputForMerged(
            other_binop,
            TruncDivModInstr::OutputIndexOf(other_binop->op_kind()), kTagged,
            kSmiCid);

        // Replace with TruncDivMod.
        TruncDivModInstr* div_mod = new (Z) TruncDivModInstr(
            curr_instr->left()->CopyWithType(),
            curr_instr->right()->CopyWithType(), curr_instr->deopt_id());
        curr_instr->ReplaceWith(div_mod, NULL);
        other_binop->ReplaceUsesWith(div_mod);
        other_binop->RemoveFromGraph();
        // Only one merge possible. Because canonicalization happens later,
        // more candidates are possible.
        // TODO(srdjan): Allow merging of trunc-div/mod into truncDivMod.
        break;
      }
    }
  }
}

void FlowGraph::AppendExtractNthOutputForMerged(Definition* instr,
                                                intptr_t index,
                                                Representation rep,
                                                intptr_t cid) {
  ExtractNthOutputInstr* extract =
      new (Z) ExtractNthOutputInstr(new (Z) Value(instr), index, rep, cid);
  instr->ReplaceUsesWith(extract);
  InsertAfter(instr, extract, NULL, FlowGraph::kValue);
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
