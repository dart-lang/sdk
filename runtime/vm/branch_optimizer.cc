// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/branch_optimizer.h"

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

// Returns true if the given phi has a single input use and
// is used in the environments either at the corresponding block entry or
// at the same instruction where input use is.
static bool PhiHasSingleUse(PhiInstr* phi, Value* use) {
  if ((use->next_use() != NULL) || (phi->input_use_list() != use)) {
    return false;
  }

  BlockEntryInstr* block = phi->block();
  for (Value* env_use = phi->env_use_list(); env_use != NULL;
       env_use = env_use->next_use()) {
    if ((env_use->instruction() != block) &&
        (env_use->instruction() != use->instruction())) {
      return false;
    }
  }

  return true;
}

bool BranchSimplifier::Match(JoinEntryInstr* block) {
  // Match the pattern of a branch on a comparison whose left operand is a
  // phi from the same block, and whose right operand is a constant.
  //
  //   Branch(Comparison(kind, Phi, Constant))
  //
  // These are the branches produced by inlining in a test context.  Also,
  // the phi has no other uses so they can simply be eliminated.  The block
  // has no other phis and no instructions intervening between the phi and
  // branch so the block can simply be eliminated.
  BranchInstr* branch = block->last_instruction()->AsBranch();
  ASSERT(branch != NULL);
  ComparisonInstr* comparison = branch->comparison();
  if (comparison->InputCount() != 2) {
    return false;
  }
  if (comparison->CanDeoptimize() || comparison->MayThrow()) {
    return false;
  }
  Value* left = comparison->left();
  PhiInstr* phi = left->definition()->AsPhi();
  Value* right = comparison->right();
  ConstantInstr* constant =
      (right == NULL) ? NULL : right->definition()->AsConstant();
  return (phi != NULL) && (constant != NULL) && (phi->GetBlock() == block) &&
         PhiHasSingleUse(phi, left) && (block->next() == branch) &&
         (block->phis()->length() == 1);
}

JoinEntryInstr* BranchSimplifier::ToJoinEntry(Zone* zone,
                                              TargetEntryInstr* target) {
  // Convert a target block into a join block.  Branches will be duplicated
  // so the former true and false targets become joins of the control flows
  // from all the duplicated branches.
  JoinEntryInstr* join = new (zone) JoinEntryInstr(
      target->block_id(), target->try_index(), Thread::kNoDeoptId);
  join->InheritDeoptTarget(zone, target);
  join->LinkTo(target->next());
  join->set_last_instruction(target->last_instruction());
  target->UnuseAllInputs();
  return join;
}

BranchInstr* BranchSimplifier::CloneBranch(Zone* zone,
                                           BranchInstr* branch,
                                           Value* new_left,
                                           Value* new_right) {
  ComparisonInstr* comparison = branch->comparison();
  ComparisonInstr* new_comparison =
      comparison->CopyWithNewOperands(new_left, new_right);
  BranchInstr* new_branch =
      new (zone) BranchInstr(new_comparison, Thread::kNoDeoptId);
  return new_branch;
}

void BranchSimplifier::Simplify(FlowGraph* flow_graph) {
  // Optimize some branches that test the value of a phi.  When it is safe
  // to do so, push the branch to each of the predecessor blocks.  This is
  // an optimization when (a) it can avoid materializing a boolean object at
  // the phi only to test its value, and (b) it can expose opportunities for
  // constant propagation and unreachable code elimination.  This
  // optimization is intended to run after inlining which creates
  // opportunities for optimization (a) and before constant folding which
  // can perform optimization (b).

  // Begin with a worklist of join blocks ending in branches.  They are
  // candidates for the pattern below.
  Zone* zone = flow_graph->zone();
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  GrowableArray<BlockEntryInstr*> worklist(postorder.length());
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    if (block->IsJoinEntry() && block->last_instruction()->IsBranch()) {
      worklist.Add(block);
    }
  }

  // Rewrite until no more instance of the pattern exists.
  bool changed = false;
  while (!worklist.is_empty()) {
    // All blocks in the worklist are join blocks (ending with a branch).
    JoinEntryInstr* block = worklist.RemoveLast()->AsJoinEntry();
    ASSERT(block != NULL);

    if (Match(block)) {
      changed = true;

      // The branch will be copied and pushed to all the join's
      // predecessors.  Convert the true and false target blocks into join
      // blocks to join the control flows from all of the true
      // (respectively, false) targets of the copied branches.
      //
      // The converted join block will have no phis, so it cannot be another
      // instance of the pattern.  There is thus no need to add it to the
      // worklist.
      BranchInstr* branch = block->last_instruction()->AsBranch();
      ASSERT(branch != NULL);
      JoinEntryInstr* join_true = ToJoinEntry(zone, branch->true_successor());
      JoinEntryInstr* join_false = ToJoinEntry(zone, branch->false_successor());

      ComparisonInstr* comparison = branch->comparison();
      PhiInstr* phi = comparison->left()->definition()->AsPhi();
      ConstantInstr* constant = comparison->right()->definition()->AsConstant();
      ASSERT(constant != NULL);
      // Copy the constant and branch and push it to all the predecessors.
      for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
        GotoInstr* old_goto =
            block->PredecessorAt(i)->last_instruction()->AsGoto();
        ASSERT(old_goto != NULL);

        // Replace the goto in each predecessor with a rewritten branch,
        // rewritten to use the corresponding phi input instead of the phi.
        Value* new_left = phi->InputAt(i)->Copy(zone);
        Value* new_right = new (zone) Value(constant);
        BranchInstr* new_branch =
            CloneBranch(zone, branch, new_left, new_right);
        if (branch->env() == NULL) {
          new_branch->InheritDeoptTarget(zone, old_goto);
        } else {
          // Take the environment from the branch if it has one.
          new_branch->InheritDeoptTarget(zone, branch);
          // InheritDeoptTarget gave the new branch's comparison the same
          // deopt id that it gave the new branch.  The id should be the
          // deopt id of the original comparison.
          new_branch->comparison()->SetDeoptId(*comparison);
          // The phi can be used in the branch's environment.  Rename such
          // uses.
          for (Environment::DeepIterator it(new_branch->env()); !it.Done();
               it.Advance()) {
            Value* use = it.CurrentValue();
            if (use->definition() == phi) {
              Definition* replacement = phi->InputAt(i)->definition();
              use->RemoveFromUseList();
              use->set_definition(replacement);
              replacement->AddEnvUse(use);
            }
          }
        }

        new_branch->InsertBefore(old_goto);
        new_branch->set_next(NULL);  // Detaching the goto from the graph.
        old_goto->UnuseAllInputs();

        // Update the predecessor block.  We may have created another
        // instance of the pattern so add it to the worklist if necessary.
        BlockEntryInstr* branch_block = new_branch->GetBlock();
        branch_block->set_last_instruction(new_branch);
        if (branch_block->IsJoinEntry()) worklist.Add(branch_block);

        // Connect the branch to the true and false joins, via empty target
        // blocks.
        TargetEntryInstr* true_target =
            new (zone) TargetEntryInstr(flow_graph->max_block_id() + 1,
                                        block->try_index(), Thread::kNoDeoptId);
        true_target->InheritDeoptTarget(zone, join_true);
        TargetEntryInstr* false_target =
            new (zone) TargetEntryInstr(flow_graph->max_block_id() + 2,
                                        block->try_index(), Thread::kNoDeoptId);
        false_target->InheritDeoptTarget(zone, join_false);
        flow_graph->set_max_block_id(flow_graph->max_block_id() + 2);
        *new_branch->true_successor_address() = true_target;
        *new_branch->false_successor_address() = false_target;
        GotoInstr* goto_true =
            new (zone) GotoInstr(join_true, Thread::kNoDeoptId);
        goto_true->InheritDeoptTarget(zone, join_true);
        true_target->LinkTo(goto_true);
        true_target->set_last_instruction(goto_true);
        GotoInstr* goto_false =
            new (zone) GotoInstr(join_false, Thread::kNoDeoptId);
        goto_false->InheritDeoptTarget(zone, join_false);
        false_target->LinkTo(goto_false);
        false_target->set_last_instruction(goto_false);
      }
      // When all predecessors have been rewritten, the original block is
      // unreachable from the graph.
      phi->UnuseAllInputs();
      branch->UnuseAllInputs();
      block->UnuseAllInputs();
      ASSERT(!phi->HasUses());
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}

static bool IsTrivialBlock(BlockEntryInstr* block, Definition* defn) {
  return (block->IsTargetEntry() && (block->PredecessorCount() == 1)) &&
         ((block->next() == block->last_instruction()) ||
          ((block->next() == defn) &&
           (defn->next() == block->last_instruction())));
}

static void EliminateTrivialBlock(BlockEntryInstr* block,
                                  Definition* instr,
                                  IfThenElseInstr* before) {
  block->UnuseAllInputs();
  block->last_instruction()->UnuseAllInputs();

  if ((block->next() == instr) &&
      (instr->next() == block->last_instruction())) {
    before->previous()->LinkTo(instr);
    instr->LinkTo(before);
  }
}

void IfConverter::Simplify(FlowGraph* flow_graph) {
  Zone* zone = flow_graph->zone();
  bool changed = false;

  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    JoinEntryInstr* join = block->AsJoinEntry();

    // Detect diamond control flow pattern which materializes a value depending
    // on the result of the comparison:
    //
    // B_pred:
    //   ...
    //   Branch if COMP goto (B_pred1, B_pred2)
    // B_pred1: -- trivial block that contains at most one definition
    //   v1 = Constant(...)
    //   goto B_block
    // B_pred2: -- trivial block that contains at most one definition
    //   v2 = Constant(...)
    //   goto B_block
    // B_block:
    //   v3 = phi(v1, v2) -- single phi
    //
    // and replace it with
    //
    // Ba:
    //   v3 = IfThenElse(COMP ? v1 : v2)
    //
    if ((join != NULL) && (join->phis() != NULL) &&
        (join->phis()->length() == 1) && (block->PredecessorCount() == 2)) {
      BlockEntryInstr* pred1 = block->PredecessorAt(0);
      BlockEntryInstr* pred2 = block->PredecessorAt(1);

      PhiInstr* phi = (*join->phis())[0];
      Value* v1 = phi->InputAt(0);
      Value* v2 = phi->InputAt(1);

      if (IsTrivialBlock(pred1, v1->definition()) &&
          IsTrivialBlock(pred2, v2->definition()) &&
          (pred1->PredecessorAt(0) == pred2->PredecessorAt(0))) {
        BlockEntryInstr* pred = pred1->PredecessorAt(0);
        BranchInstr* branch = pred->last_instruction()->AsBranch();
        ComparisonInstr* comparison = branch->comparison();

        // Check if the platform supports efficient branchless IfThenElseInstr
        // for the given combination of comparison and values flowing from
        // false and true paths.
        if (IfThenElseInstr::Supports(comparison, v1, v2)) {
          Value* if_true = (pred1 == branch->true_successor()) ? v1 : v2;
          Value* if_false = (pred2 == branch->true_successor()) ? v1 : v2;

          ComparisonInstr* new_comparison = comparison->CopyWithNewOperands(
              comparison->left()->Copy(zone), comparison->right()->Copy(zone));
          IfThenElseInstr* if_then_else = new (zone)
              IfThenElseInstr(new_comparison, if_true->Copy(zone),
                              if_false->Copy(zone), Thread::kNoDeoptId);
          flow_graph->InsertBefore(branch, if_then_else, NULL,
                                   FlowGraph::kValue);

          phi->ReplaceUsesWith(if_then_else);

          // Connect IfThenElseInstr to the first instruction in the merge block
          // effectively eliminating diamond control flow.
          // Current block as well as pred1 and pred2 blocks are no longer in
          // the graph at this point.
          if_then_else->LinkTo(join->next());
          pred->set_last_instruction(join->last_instruction());

          // Resulting block must inherit block id from the eliminated current
          // block to guarantee that ordering of phi operands in its successor
          // stays consistent.
          pred->set_block_id(block->block_id());

          // If v1 and v2 were defined inside eliminated blocks pred1/pred2
          // move them out to the place before inserted IfThenElse instruction.
          EliminateTrivialBlock(pred1, v1->definition(), if_then_else);
          EliminateTrivialBlock(pred2, v2->definition(), if_then_else);

          // Update use lists to reflect changes in the graph.
          phi->UnuseAllInputs();
          branch->UnuseAllInputs();
          block->UnuseAllInputs();

          // The graph has changed. Recompute dominators and block orders after
          // this pass is finished.
          changed = true;
        }
      }
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
