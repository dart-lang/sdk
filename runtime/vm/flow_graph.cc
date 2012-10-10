// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph.h"

#include "vm/bit_vector.h"
#include "vm/flow_graph_builder.h"
#include "vm/intermediate_language.h"
#include "vm/longjump.h"
#include "vm/growable_array.h"

namespace dart {

DECLARE_FLAG(bool, trace_optimization);
DECLARE_FLAG(bool, verify_compiler);

FlowGraph::FlowGraph(const FlowGraphBuilder& builder,
                     GraphEntryInstr* graph_entry,
                     intptr_t max_block_id)
  : parent_(),
    assigned_vars_(),
    current_ssa_temp_index_(0),
    max_block_id_(max_block_id),
    parsed_function_(builder.parsed_function()),
    num_copied_params_(builder.num_copied_params()),
    num_non_copied_params_(builder.num_non_copied_params()),
    num_stack_locals_(builder.num_stack_locals()),
    graph_entry_(graph_entry),
    preorder_(),
    postorder_(),
    reverse_postorder_(),
    exits_(NULL) {
  DiscoverBlocks();
}


void FlowGraph::DiscoverBlocks() {
  // Initialize state.
  preorder_.Clear();
  postorder_.Clear();
  reverse_postorder_.Clear();
  parent_.Clear();
  assigned_vars_.Clear();
  // Perform a depth-first traversal of the graph to build preorder and
  // postorder block orders.
  graph_entry_->DiscoverBlocks(NULL,  // Entry block predecessor.
                               &preorder_,
                               &postorder_,
                               &parent_,
                               &assigned_vars_,
                               variable_count(),
                               num_non_copied_params());
  // Create an array of blocks in reverse postorder.
  intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; ++i) {
    reverse_postorder_.Add(postorder_[block_count - i - 1]);
  }
}


#ifdef DEBUG
// Debugging code to verify the construction of use lists.

static intptr_t MembershipCount(Value* use, Value* list) {
  intptr_t count = 0;
  while (list != NULL) {
    if (list == use) ++count;
    list = list->next_use();
  }
  return count;
}


static void ResetUseListsInInstruction(Instruction* instr) {
  Definition* defn = instr->AsDefinition();
  if (defn != NULL) {
    defn->set_input_use_list(NULL);
    defn->set_env_use_list(NULL);
  }
  for (intptr_t i = 0; i < instr->InputCount(); ++i) {
    Value* use = instr->InputAt(i);
    use->set_instruction(NULL);
    use->set_use_index(-1);
    use->set_next_use(NULL);
  }
  if (instr->env() != NULL) {
    for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
      Value* use = it.CurrentValue();
      use->set_instruction(NULL);
      use->set_use_index(-1);
      use->set_next_use(NULL);
    }
  }
}


bool FlowGraph::ResetUseLists() {
  // Reset initial definitions.
  for (intptr_t i = 0; i < graph_entry_->initial_definitions()->length(); ++i) {
    ResetUseListsInInstruction((*graph_entry_->initial_definitions())[i]);
  }

  // Reset phis in join entries and the instructions in each block.
  for (intptr_t i = 0; i < preorder_.length(); ++i) {
    BlockEntryInstr* entry = preorder_[i];
    JoinEntryInstr* join = entry->AsJoinEntry();
    if (join != NULL && join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != NULL) ResetUseListsInInstruction(phi);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      ResetUseListsInInstruction(it.Current());
    }
  }
  return true;  // Return true so we can ASSERT the reset code.
}


static void ValidateUseListsInInstruction(Instruction* instr) {
  ASSERT(instr != NULL);
  ASSERT(!instr->IsJoinEntry());
  for (intptr_t i = 0; i < instr->InputCount(); ++i) {
    Value* use = instr->InputAt(i);
    ASSERT(use->use_index() == i);
    ASSERT(!FLAG_verify_compiler ||
           (1 == MembershipCount(use, use->definition()->input_use_list())));
  }
  if (instr->env() != NULL) {
    intptr_t use_index = 0;
    for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
      Value* use = it.CurrentValue();
      ASSERT(use->use_index() == use_index++);
      ASSERT(!FLAG_verify_compiler ||
             (1 == MembershipCount(use, use->definition()->env_use_list())));
    }
  }
  Definition* defn = instr->AsDefinition();
  if (defn != NULL) {
    for (Value* use = defn->input_use_list();
         use != NULL;
         use = use->next_use()) {
      ASSERT(defn == use->definition());
      ASSERT(use == use->instruction()->InputAt(use->use_index()));
    }
    for (Value* use = defn->env_use_list();
         use != NULL;
         use = use->next_use()) {
      ASSERT(defn == use->definition());
      ASSERT(use ==
             use->instruction()->env()->ValueAtUseIndex(use->use_index()));
    }
  }
}


bool FlowGraph::ValidateUseLists() {
  // Validate initial definitions.
  for (intptr_t i = 0; i < graph_entry_->initial_definitions()->length(); ++i) {
    ValidateUseListsInInstruction((*graph_entry_->initial_definitions())[i]);
  }

  // Validate phis in join entries and the instructions in each block.
  for (intptr_t i = 0; i < preorder_.length(); ++i) {
    BlockEntryInstr* entry = preorder_[i];
    JoinEntryInstr* join = entry->AsJoinEntry();
    if (join != NULL && join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != NULL) ValidateUseListsInInstruction(phi);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      ValidateUseListsInInstruction(it.Current());
    }
  }
  return true;  // Return true so we can ASSERT validation.
}
#endif  // DEBUG


static void ClearUseLists(Definition* defn) {
  ASSERT(defn != NULL);
  ASSERT(defn->input_use_list() == NULL);
  ASSERT(defn->env_use_list() == NULL);
  defn->set_input_use_list(NULL);
  defn->set_env_use_list(NULL);
}


static void RecordInputUses(Instruction* instr) {
  ASSERT(instr != NULL);
  for (intptr_t i = 0; i < instr->InputCount(); ++i) {
    Value* use = instr->InputAt(i);
    ASSERT(use->instruction() == NULL);
    ASSERT(use->use_index() == -1);
    ASSERT(use->next_use() == NULL);
    DEBUG_ASSERT(!FLAG_verify_compiler ||
        (0 == MembershipCount(use, use->definition()->input_use_list())));
    use->set_instruction(instr);
    use->set_use_index(i);
    use->AddToInputUseList();
  }
}


static void RecordEnvUses(Instruction* instr) {
  ASSERT(instr != NULL);
  if (instr->env() == NULL) return;
  intptr_t use_index = 0;
  for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    ASSERT(use->instruction() == NULL);
    ASSERT(use->use_index() == -1);
    ASSERT(use->next_use() == NULL);
    DEBUG_ASSERT(!FLAG_verify_compiler ||
        (0 == MembershipCount(use, use->definition()->env_use_list())));
    use->set_instruction(instr);
    use->set_use_index(use_index++);
    use->AddToEnvUseList();
  }
}


static void ComputeUseListsRecursive(BlockEntryInstr* block) {
  // Clear phi definitions.
  JoinEntryInstr* join = block->AsJoinEntry();
  if (join != NULL && join->phis() != NULL) {
    for (intptr_t i = 0; i < join->phis()->length(); ++i) {
      PhiInstr* phi = (*join->phis())[i];
      if (phi != NULL) ClearUseLists(phi);
    }
  }
  // Compute uses on normal instructions.
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instr = it.Current();
    if (instr->IsDefinition()) ClearUseLists(instr->AsDefinition());
    RecordInputUses(instr);
    RecordEnvUses(instr);
  }
  // Compute recursively on dominated blocks.
  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    ComputeUseListsRecursive(block->dominated_blocks()[i]);
  }
  // Add phi uses on successor edges.
  if (block->last_instruction()->SuccessorCount() == 1 &&
      block->last_instruction()->SuccessorAt(0)->IsJoinEntry()) {
    JoinEntryInstr* join =
        block->last_instruction()->SuccessorAt(0)->AsJoinEntry();
    intptr_t pred_index = join->IndexOfPredecessor(block);
    ASSERT(pred_index >= 0);
    if (join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi == NULL) continue;
        Value* use = phi->InputAt(pred_index);
        ASSERT(use->instruction() == NULL);
        ASSERT(use->use_index() == -1);
        ASSERT(use->next_use() == NULL);
        DEBUG_ASSERT(!FLAG_verify_compiler ||
            (0 == MembershipCount(use, use->definition()->input_use_list())));
        use->set_instruction(phi);
        use->set_use_index(pred_index);
        use->AddToInputUseList();
      }
    }
  }
}


void FlowGraph::ComputeUseLists() {
  DEBUG_ASSERT(ResetUseLists());
  // Clear initial definitions.
  for (intptr_t i = 0; i < graph_entry_->initial_definitions()->length(); ++i) {
    ClearUseLists((*graph_entry_->initial_definitions())[i]);
  }
  ComputeUseListsRecursive(graph_entry_);
  DEBUG_ASSERT(!FLAG_verify_compiler || ValidateUseLists());
}


void FlowGraph::ComputeSSA(intptr_t next_virtual_register_number) {
  current_ssa_temp_index_ = next_virtual_register_number;
  GrowableArray<BitVector*> dominance_frontier;
  ComputeDominators(&dominance_frontier);
  InsertPhis(preorder_, assigned_vars_, dominance_frontier);
  GrowableArray<PhiInstr*> live_phis;
  // Rename uses to reference inserted phis where appropriate.
  // Collect phis that reach a non-environment use.
  Rename(&live_phis);
  // Propagate alive mark transitively from alive phis.
  MarkLivePhis(&live_phis);
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
  GrowableArray<intptr_t> idom(size);  // Immediate dominator.
  GrowableArray<intptr_t> semi(size);  // Semidominator.
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
    dominance_frontier->Add(new BitVector(size));
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
    preorder_[block_index]->set_dominator(preorder_[dom_index]);
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


void FlowGraph::InsertPhis(
    const GrowableArray<BlockEntryInstr*>& preorder,
    const GrowableArray<BitVector*>& assigned_vars,
    const GrowableArray<BitVector*>& dom_frontier) {
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
    // Add to the worklist each block containing an assignment.
    for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
      if (assigned_vars[block_index]->Contains(var_index)) {
        work[block_index] = var_index;
        worklist.Add(preorder[block_index]);
      }
    }

    while (!worklist.is_empty()) {
      BlockEntryInstr* current = worklist.Last();
      worklist.RemoveLast();
      // Ensure a phi for each block in the dominance frontier of current.
      for (BitVector::Iterator it(dom_frontier[current->preorder_number()]);
           !it.Done();
           it.Advance()) {
        int index = it.Current();
        if (has_already[index] < var_index) {
          BlockEntryInstr* block = preorder[index];
          ASSERT(block->IsJoinEntry());
          block->AsJoinEntry()->InsertPhi(var_index, variable_count());
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


void FlowGraph::Rename(GrowableArray<PhiInstr*>* live_phis) {
  // TODO(fschneider): Support catch-entry.
  if (graph_entry_->SuccessorCount() > 1) {
    Bailout("Catch-entry support in SSA.");
  }

  // Initial renaming environment.
  GrowableArray<Definition*> env(variable_count());

  // Add global constants to the initial definitions.
  ConstantInstr* constant_null = new ConstantInstr(Object::ZoneHandle());
  constant_null->set_ssa_temp_index(alloc_ssa_temp_index());
  graph_entry_->initial_definitions()->Add(constant_null);

  // Add incoming parameters to the initial definitions and the renaming
  // environment.
  for (intptr_t i = 0; i < parameter_count(); ++i) {
    ParameterInstr* param = new ParameterInstr(i, graph_entry_);
    param->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
    graph_entry_->initial_definitions()->Add(param);
    env.Add(param);
  }

  // Initialize all locals with #null in the renaming environment.
  for (intptr_t i = parameter_count(); i < variable_count(); ++i) {
    env.Add(constant_null);
  }

  BlockEntryInstr* normal_entry = graph_entry_->SuccessorAt(0);
  ASSERT(normal_entry != NULL);  // Must have entry.
  RenameRecursive(normal_entry, &env, live_phis);
}


void FlowGraph::RenameRecursive(BlockEntryInstr* block_entry,
                                GrowableArray<Definition*>* env,
                                GrowableArray<PhiInstr*>* live_phis) {
  // 1. Process phis first.
  if (block_entry->IsJoinEntry()) {
    JoinEntryInstr* join = block_entry->AsJoinEntry();
    if (join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != NULL) {
          (*env)[i] = phi;
          phi->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
        }
      }
    }
  }

  // 2. Process normal instructions.
  for (ForwardInstructionIterator it(block_entry); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    // Attach current environment to the instruction. First, each instruction
    // gets a full copy of the environment. Later we optimize this by
    // eliminating unnecessary environments.
    // TODO(zerny): Avoid creating unnecessary environments. Note that some
    // optimizations need deoptimization info for non-deoptable instructions,
    // eg, LICM on GOTOs.
    current->set_env(Environment::From(*env,
                                       num_non_copied_params_,
                                       parsed_function_.function()));
    if (current->CanDeoptimize()) {
      current->env()->set_deopt_id(current->deopt_id());
    }

    // 2a. Handle uses:
    // Update expression stack environment for each use.
    // For each use of a LoadLocal or StoreLocal: Replace it with the value
    // from the environment.
    for (intptr_t i = current->InputCount() - 1; i >= 0; --i) {
      Value* v = current->InputAt(i);
      // Update expression stack.
      ASSERT(env->length() > variable_count());

      Definition* reaching_defn = env->Last();
      env->RemoveLast();

      Definition* input_defn = v->definition();
      if (input_defn->IsLoadLocal() || input_defn->IsStoreLocal()) {
        // Remove the load/store from the graph.
        input_defn->RemoveFromGraph();
        // Assert we are not referencing nulls in the initial environment.
        ASSERT(reaching_defn->ssa_temp_index() != -1);
        current->SetInputAt(i, new Value(reaching_defn));
      }
    }

    // Drop pushed arguments for calls.
    for (intptr_t j = 0; j < current->ArgumentCount(); j++) {
      env->RemoveLast();
    }

    // 2b. Handle LoadLocal and StoreLocal.
    // For each LoadLocal: Remove it from the graph.
    // For each StoreLocal: Remove it from the graph and update the environment.
    Definition* definition = current->AsDefinition();
    if (definition != NULL) {
      LoadLocalInstr* load = definition->AsLoadLocal();
      StoreLocalInstr* store = definition->AsStoreLocal();
      if ((load != NULL) || (store != NULL)) {
        intptr_t index;
        if (store != NULL) {
          index = store->local().BitIndexIn(num_non_copied_params_);
          // Update renaming environment.
          (*env)[index] = store->value()->definition();
        } else {
          // The graph construction ensures we do not have an unused LoadLocal
          // computation.
          ASSERT(definition->is_used());
          index = load->local().BitIndexIn(num_non_copied_params_);

          PhiInstr* phi = (*env)[index]->AsPhi();
          if ((phi != NULL) && !phi->is_alive()) {
            phi->mark_alive();
            live_phis->Add(phi);
          }
        }
        // Update expression stack or remove from graph.
        if (definition->is_used()) {
          env->Add((*env)[index]);
          // We remove load/store instructions when we find their use in 2a.
        } else {
          it.RemoveCurrentFromGraph();
        }
      } else {
        // Not a load or store.
        if (definition->is_used()) {
          // Assign fresh SSA temporary and update expression stack.
          definition->set_ssa_temp_index(alloc_ssa_temp_index());
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
    RenameRecursive(block, &new_env, live_phis);
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
          phi->SetInputAt(pred_index, new Value((*env)[i]));
        }
      }
    }
  }
}


void FlowGraph::MarkLivePhis(GrowableArray<PhiInstr*>* live_phis) {
  while (!live_phis->is_empty()) {
    PhiInstr* phi = live_phis->Last();
    live_phis->RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      PhiInstr* used_phi = val->definition()->AsPhi();
      if ((used_phi != NULL) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis->Add(used_phi);
      }
    }
  }
}


// Find the natural loop for the back edge m->n and attach loop information
// to block n (loop header). The algorithm is described in "Advanced Compiler
// Design & Implementation" (Muchnick) p192.
static void FindLoop(BlockEntryInstr* m,
                     BlockEntryInstr* n,
                     intptr_t num_blocks) {
  GrowableArray<BlockEntryInstr*> stack;
  BitVector* loop = new BitVector(num_blocks);

  loop->Add(n->preorder_number());
  if (n != m) {
    loop->Add(m->preorder_number());
    stack.Add(m);
  }

  while (!stack.is_empty()) {
    BlockEntryInstr* p = stack.Last();
    stack.RemoveLast();
    for (intptr_t i = 0; i < p->PredecessorCount(); ++i) {
      BlockEntryInstr* q = p->PredecessorAt(i);
      if (!loop->Contains(q->preorder_number())) {
        loop->Add(q->preorder_number());
        stack.Add(q);
      }
    }
  }
  n->set_loop_info(loop);
  if (FLAG_trace_optimization) {
    for (BitVector::Iterator it(loop); !it.Done(); it.Advance()) {
      OS::Print("  B%"Pd"\n", it.Current());
    }
  }
}


void FlowGraph::ComputeLoops(GrowableArray<BlockEntryInstr*>* loop_headers) {
  ASSERT(loop_headers->is_empty());
  for (BlockIterator it = postorder_iterator();
       !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (block->Dominates(pred)) {
        if (FLAG_trace_optimization) {
          OS::Print("Back edge B%"Pd" -> B%"Pd"\n", pred->block_id(),
                    block->block_id());
        }
        FindLoop(pred, block, preorder_.length());
        loop_headers->Add(block);
      }
    }
  }
}


void FlowGraph::Bailout(const char* reason) const {
  const char* kFormat = "FlowGraph Bailout: %s %s";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


// Helper to reorder phis after splitting a block.  The last instruction(s) of
// the split block will now have a larger block id than any previously known
// blocks. If the last instruction jumps to a join, we must reorder phi inputs
// according to the block order, ie, we move this predecessor to the end.
static void ReorderPhis(BlockEntryInstr* block) {
  GotoInstr* jump = block->last_instruction()->AsGoto();
  if (jump == NULL) return;
  JoinEntryInstr* join = jump->successor();
  intptr_t pred_index = join->IndexOfPredecessor(block);
  intptr_t pred_count = join->PredecessorCount();
  ASSERT(pred_index >= 0);
  ASSERT(pred_index < pred_count);
  // If the predecessor index is the last index there is nothing to update.
  if ((join->phis() == NULL) || (pred_index + 1 == pred_count)) return;
  // Otherwise, move the predecessor use to the end in each phi.
  for (intptr_t i = 0; i < join->phis()->length(); ++i) {
    PhiInstr* phi = (*join->phis())[i];
    if (phi == NULL) continue;
    ASSERT(pred_count == phi->InputCount());
    // Save the predecessor use.
    Value* pred_use = phi->InputAt(pred_index);
    // Move each of the following uses back by one.
    ASSERT(pred_index < pred_count - 1);  // Will move at least one index.
    for (intptr_t i = pred_index; i < pred_count - 1; ++i) {
      Value* use = phi->InputAt(i + 1);
      phi->SetInputAt(i, use);
      use->set_use_index(i);
    }
    // Write the predecessor use at the end.
    phi->SetInputAt(pred_count - 1, pred_use);
    pred_use->set_use_index(pred_count - 1);
  }
}


// Helper to sort a list of blocks.
static int LowestBlockIdFirst(BlockEntryInstr* const* a,
                              BlockEntryInstr* const* b) {
  return (*a)->block_id() - (*b)->block_id();
}


// Inline a flow graph at a call site.
//
// Assumes the callee graph was computed by BuildGraph with an inlining context
// and transformed to SSA with ComputeSSA with a correct virtual register
// number, and that the use lists have been correctly computed.
//
// After inlining the caller graph will correctly have adjusted the pre/post
// orders, the dominator tree and the use lists.
void FlowGraph::InlineCall(Definition* call, FlowGraph* callee_graph) {
  ASSERT(call->previous() != NULL);
  ASSERT(call->next() != NULL);
  ASSERT(callee_graph->exits() != NULL);
  ASSERT(callee_graph->graph_entry()->SuccessorCount() == 1);
  ASSERT(callee_graph->max_block_id() > max_block_id());
  ASSERT(callee_graph->max_virtual_register_number() >
         max_virtual_register_number());

  // Adjust the max block id to the max block id of the callee graph.
  max_block_id_ = callee_graph->max_block_id();

  // Adjust the SSA temp index by the callee graph's index.
  current_ssa_temp_index_ = callee_graph->max_virtual_register_number();

  BlockEntryInstr* caller_entry = call->GetBlock();
  TargetEntryInstr* callee_entry = callee_graph->graph_entry()->normal_entry();
  ZoneGrowableArray<ReturnInstr*>* callee_exits = callee_graph->exits();

  // Attach the outer environment on each instruction in the callee graph.
  for (BlockIterator block_it = callee_graph->postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current());
         !it.Done();
         it.Advance()) {
      Instruction* instr = it.Current();
      // TODO(zerny): Avoid creating unnecessary environments. Note that some
      // optimizations need deoptimization info for non-deoptable instructions,
      // eg, LICM on GOTOs.
      if (instr->env() != NULL) call->env()->DeepCopyToOuter(instr);
    }
  }

  // Insert the callee graph into the caller graph.
  if (callee_exits->is_empty()) {
    // TODO(zerny): Add support for non-local exits, such as throw.
    UNREACHABLE();
  } else if (callee_exits->length() == 1) {
    ReturnInstr* exit = (*callee_exits)[0];
    ASSERT(exit->previous() != NULL);
    // For just one exit, replace the uses and remove the call from the graph.
    call->ReplaceUsesWith(exit->value()->definition());
    call->previous()->LinkTo(callee_entry->next());
    exit->previous()->LinkTo(call->next());
    // In case of control flow, locally update the dominator tree.
    if (callee_graph->preorder().length() > 2) {
      // The caller block is split and the new block id is that of the exit
      // block. If the caller block had outgoing edges, reorder the phis so they
      // are still ordered by block id.
      ReorderPhis(caller_entry);
      // The callee return is now the immediate dominator of blocks whose
      // immediate dominator was the caller entry.
      BlockEntryInstr* exit_block = exit->GetBlock();
      ASSERT(exit_block->dominated_blocks().is_empty());
      for (intptr_t i = 0; i < caller_entry->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = caller_entry->dominated_blocks()[i];
        block->set_dominator(exit_block);
        exit_block->AddDominatedBlock(block);
      }
      // The caller entry is now the immediate dominator of blocks whose
      // immediate dominator was the callee entry.
      caller_entry->ClearDominatedBlocks();
      for (intptr_t i = 0; i < callee_entry->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = callee_entry->dominated_blocks()[i];
        block->set_dominator(caller_entry);
        caller_entry->AddDominatedBlock(block);
      }
      // Recompute the block orders.
      DiscoverBlocks();
    }
  } else {
    // Sort the list of exits by block id.
    GrowableArray<BlockEntryInstr*> exits(callee_exits->length());
    for (intptr_t i = 0; i < callee_exits->length(); ++i) {
      exits.Add((*callee_exits)[i]->GetBlock());
    }
    exits.Sort(LowestBlockIdFirst);
    // Create a join of the returns.
    JoinEntryInstr* join =
        new JoinEntryInstr(++max_block_id_, CatchClauseNode::kInvalidTryIndex);
    for (intptr_t i = 0; i < exits.length(); ++i) {
      ReturnInstr* exit_instr = exits[i]->last_instruction()->AsReturn();
      ASSERT(exit_instr != NULL);
      exit_instr->previous()->Goto(join);
      // Directly add the predecessors of the join in ascending block id order.
      join->predecessors_.Add(exits[i]);
    }
    // If the call has uses, create a phi of the returns.
    if ((call->input_use_list() != NULL) ||
        (call->env_use_list() != NULL)) {
      // Environment count: length before call - argument count (+ return)
      intptr_t env_count = call->env()->Length() - call->ArgumentCount();
      // Add a phi of the return values.
      join->InsertPhi(env_count, env_count + 1);
      PhiInstr* phi = join->phis()->Last();
      phi->set_ssa_temp_index(alloc_ssa_temp_index());
      phi->mark_alive();
      for (intptr_t i = 0; i < exits.length(); ++i) {
        ReturnInstr* exit_instr = exits[i]->last_instruction()->AsReturn();
        ASSERT(exit_instr != NULL);
        Value* use = exit_instr->value();
        phi->SetInputAt(i, use);
        use->set_instruction(phi);
        use->set_use_index(i);
      }
      // Replace uses of the call with the phi.
      call->ReplaceUsesWith(phi);
    }
    //  Remove the call from the graph.
    call->previous()->LinkTo(callee_entry->next());
    join->LinkTo(call->next());
    // The caller block is split and the new block id is that of the join
    // block. If the caller block had outgoing edges, reorder the phis so they
    // are still ordered by block id.
    ReorderPhis(caller_entry);
    // Adjust pre/post orders and update the dominator tree.
    DiscoverBlocks();
    // TODO(zerny): Compute the dominator frontier locally.
    GrowableArray<BitVector*> dominance_frontier;
    ComputeDominators(&dominance_frontier);
  }
}


intptr_t FlowGraph::InstructionCount() const {
  intptr_t size = 0;
  // Iterate each block, skipping the graph entry.
  for (intptr_t i = 1; i < preorder_.length(); ++i) {
    for (ForwardInstructionIterator it(preorder_[i]);
         !it.Done();
         it.Advance()) {
      ++size;
    }
  }
  return size;
}


}  // namespace dart
