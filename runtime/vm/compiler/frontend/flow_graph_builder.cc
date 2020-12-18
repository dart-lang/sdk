// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/flow_graph_builder.h"

#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

// Quick access to the locally defined zone() method.
#define Z (zone())

// TODO(srdjan): Allow compiler to add constants as they are encountered in
// the compilation.
const double kCommonDoubleConstants[] = {
    -1.0, -0.5, -0.1, 0.0, 0.1, 0.5, 1.0, 2.0, 4.0, 5.0, 10.0, 20.0, 30.0, 64.0,
    255.0, NAN,
    // From dart:math
    2.718281828459045, 2.302585092994046, 0.6931471805599453,
    1.4426950408889634, 0.4342944819032518, 3.1415926535897932,
    0.7071067811865476, 1.4142135623730951};

uword FindDoubleConstant(double value) {
  intptr_t len = sizeof(kCommonDoubleConstants) / sizeof(double);  // NOLINT
  for (intptr_t i = 0; i < len; i++) {
    if (Utils::DoublesBitEqual(value, kCommonDoubleConstants[i])) {
      return reinterpret_cast<uword>(&kCommonDoubleConstants[i]);
    }
  }
  return 0;
}

void InlineExitCollector::PrepareGraphs(FlowGraph* callee_graph) {
  ASSERT(callee_graph->graph_entry()->SuccessorCount() == 1);
  ASSERT(callee_graph->max_block_id() > caller_graph_->max_block_id());
  ASSERT(callee_graph->max_virtual_register_number() >
         caller_graph_->max_virtual_register_number());

  // Adjust the caller's maximum block id and current SSA temp index.
  caller_graph_->set_max_block_id(callee_graph->max_block_id());
  caller_graph_->set_current_ssa_temp_index(
      callee_graph->max_virtual_register_number());

  // Attach the outer environment on each instruction in the callee graph.
  ASSERT(call_->env() != NULL);
  ASSERT(call_->deopt_id() != DeoptId::kNone);
  const intptr_t outer_deopt_id = call_->deopt_id();
  // Scale the edge weights by the call count for the inlined function.
  double scale_factor = 1.0;
  if (caller_graph_->graph_entry()->entry_count() != 0) {
    scale_factor =
        static_cast<double>(call_->CallCount()) /
        static_cast<double>(caller_graph_->graph_entry()->entry_count());
  }
  for (BlockIterator block_it = callee_graph->postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (block->IsTargetEntry()) {
      block->AsTargetEntry()->adjust_edge_weight(scale_factor);
    }
    Instruction* instr = block;
    if (block->env() != NULL) {
      call_->env()->DeepCopyToOuter(callee_graph->zone(), block,
                                    outer_deopt_id);
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      instr = it.Current();
      // TODO(zerny): Avoid creating unnecessary environments. Note that some
      // optimizations need deoptimization info for non-deoptable instructions,
      // eg, LICM on GOTOs.
      if (instr->env() != NULL) {
        call_->env()->DeepCopyToOuter(callee_graph->zone(), instr,
                                      outer_deopt_id);
      }
    }
    if (instr->IsGoto()) {
      instr->AsGoto()->adjust_edge_weight(scale_factor);
    }
  }

  RemoveUnreachableExits(callee_graph);
}

void InlineExitCollector::AddExit(ReturnInstr* exit) {
  Data data = {NULL, exit};
  exits_.Add(data);
}

void InlineExitCollector::Union(const InlineExitCollector* other) {
  // It doesn't make sense to combine different calls or calls from
  // different graphs.
  ASSERT(caller_graph_ == other->caller_graph_);
  ASSERT(call_ == other->call_);
  exits_.AddArray(other->exits_);
}

int InlineExitCollector::LowestBlockIdFirst(const Data* a, const Data* b) {
  return (a->exit_block->block_id() - b->exit_block->block_id());
}

void InlineExitCollector::RemoveUnreachableExits(FlowGraph* callee_graph) {
  const GrowableArray<BlockEntryInstr*>& postorder = callee_graph->postorder();
  int j = 0;
  for (int i = 0; i < exits_.length(); ++i) {
    BlockEntryInstr* block = exits_[i].exit_return->GetBlock();
    if ((block != NULL) && (0 <= block->postorder_number()) &&
        (block->postorder_number() < postorder.length()) &&
        (postorder[block->postorder_number()] == block)) {
      if (i != j) {
        exits_[j] = exits_[i];
      }
      j++;
    }
  }
  exits_.TruncateTo(j);
}

void InlineExitCollector::SortExits() {
  // Assign block entries here because we did not necessarily know them when
  // the return exit was added to the array.
  for (int i = 0; i < exits_.length(); ++i) {
    exits_[i].exit_block = exits_[i].exit_return->GetBlock();
  }
  exits_.Sort(LowestBlockIdFirst);
}

Definition* InlineExitCollector::JoinReturns(BlockEntryInstr** exit_block,
                                             Instruction** last_instruction,
                                             intptr_t try_index) {
  // First sort the list of exits by block id (caching return instruction
  // block entries as a side effect).
  SortExits();
  intptr_t num_exits = exits_.length();
  if (num_exits == 1) {
    ReturnAt(0)->UnuseAllInputs();
    *exit_block = ExitBlockAt(0);
    *last_instruction = LastInstructionAt(0);
    return call_->HasUses() ? ValueAt(0)->definition() : NULL;
  } else {
    ASSERT(num_exits > 1);
    // Create a join of the returns.
    intptr_t join_id = caller_graph_->max_block_id() + 1;
    caller_graph_->set_max_block_id(join_id);
    JoinEntryInstr* join = new (Z) JoinEntryInstr(
        join_id, try_index, CompilerState::Current().GetNextDeoptId());

    // The dominator set of the join is the intersection of the dominator
    // sets of all the predecessors.  If we keep the dominator sets ordered
    // by height in the dominator tree, we can also get the immediate
    // dominator of the join node from the intersection.
    //
    // block_dominators is the dominator set for each block, ordered from
    // the immediate dominator to the root of the dominator tree.  This is
    // the order we collect them in (adding at the end).
    //
    // join_dominators is the join's dominators ordered from the root of the
    // dominator tree to the immediate dominator.  This order supports
    // removing during intersection by truncating the list.
    GrowableArray<BlockEntryInstr*> block_dominators;
    GrowableArray<BlockEntryInstr*> join_dominators;
    for (intptr_t i = 0; i < num_exits; ++i) {
      // Add the control-flow edge.
      GotoInstr* goto_instr =
          new (Z) GotoInstr(join, CompilerState::Current().GetNextDeoptId());
      goto_instr->InheritDeoptTarget(zone(), ReturnAt(i));
      LastInstructionAt(i)->LinkTo(goto_instr);
      ExitBlockAt(i)->set_last_instruction(LastInstructionAt(i)->next());
      join->predecessors_.Add(ExitBlockAt(i));

      // Collect the block's dominators.
      block_dominators.Clear();
      BlockEntryInstr* dominator = ExitBlockAt(i)->dominator();
      while (dominator != NULL) {
        block_dominators.Add(dominator);
        dominator = dominator->dominator();
      }

      if (i == 0) {
        // The initial dominator set is the first predecessor's dominator
        // set.  Reverse it.
        for (intptr_t j = block_dominators.length() - 1; j >= 0; --j) {
          join_dominators.Add(block_dominators[j]);
        }
      } else {
        // Intersect the block's dominators with the join's dominators so far.
        intptr_t last = block_dominators.length() - 1;
        for (intptr_t j = 0; j < join_dominators.length(); ++j) {
          intptr_t k = last - j;  // Corresponding index in block_dominators.
          if ((k < 0) || (join_dominators[j] != block_dominators[k])) {
            // We either exhausted the dominators for this block before
            // exhausting the current intersection, or else we found a block
            // on the path from the root of the tree that is not in common.
            // I.e., there cannot be an empty set of dominators.
            ASSERT(j > 0);
            join_dominators.TruncateTo(j);
            break;
          }
        }
      }
    }
    // The immediate dominator of the join is the last one in the ordered
    // intersection.
    join_dominators.Last()->AddDominatedBlock(join);
    *exit_block = join;
    *last_instruction = join;

    // If the call has uses, create a phi of the returns.
    if (call_->HasUses()) {
      // Add a phi of the return values.
      PhiInstr* phi = new (Z) PhiInstr(join, num_exits);
      caller_graph_->AllocateSSAIndexes(phi);
      phi->mark_alive();
      for (intptr_t i = 0; i < num_exits; ++i) {
        ReturnAt(i)->RemoveEnvironment();
        phi->SetInputAt(i, ValueAt(i));
      }
      join->InsertPhi(phi);
      join->InheritDeoptTargetAfter(caller_graph_, call_, phi);
      return phi;
    } else {
      // In the case that the result is unused, remove the return value uses
      // from their definition's use list.
      for (intptr_t i = 0; i < num_exits; ++i) {
        ReturnAt(i)->UnuseAllInputs();
      }
      join->InheritDeoptTargetAfter(caller_graph_, call_, NULL);
      return NULL;
    }
  }
}

void InlineExitCollector::ReplaceCall(BlockEntryInstr* callee_entry) {
  ASSERT(call_->previous() != NULL);
  ASSERT(call_->next() != NULL);
  BlockEntryInstr* call_block = call_->GetBlock();

  // Insert the callee graph into the caller graph.
  BlockEntryInstr* callee_exit = NULL;
  Instruction* callee_last_instruction = NULL;

  if (exits_.length() == 0) {
    // Handle the case when there are no normal return exits from the callee
    // (i.e. the callee unconditionally throws) by inserting an artificial
    // branch (true === true).
    // The true successor is the inlined body, the false successor
    // goes to the rest of the caller graph. It is removed as unreachable code
    // by the constant propagation.
    TargetEntryInstr* false_block = new (Z) TargetEntryInstr(
        caller_graph_->allocate_block_id(), call_block->try_index(),
        CompilerState::Current().GetNextDeoptId());
    false_block->InheritDeoptTargetAfter(caller_graph_, call_, NULL);
    false_block->LinkTo(call_->next());
    call_block->ReplaceAsPredecessorWith(false_block);

    ConstantInstr* true_const = caller_graph_->GetConstant(Bool::True());
    BranchInstr* branch = new (Z) BranchInstr(
        new (Z) StrictCompareInstr(InstructionSource(), Token::kEQ_STRICT,
                                   new (Z) Value(true_const),
                                   new (Z) Value(true_const), false,
                                   CompilerState::Current().GetNextDeoptId()),
        CompilerState::Current().GetNextDeoptId());  // No number check.
    branch->InheritDeoptTarget(zone(), call_);

    auto true_target = BranchSimplifier::ToTargetEntry(zone(), callee_entry);
    callee_entry->ReplaceAsPredecessorWith(true_target);

    *branch->true_successor_address() = true_target;
    *branch->false_successor_address() = false_block;

    call_->previous()->AppendInstruction(branch);
    call_block->set_last_instruction(branch);

    // Replace uses of the return value with sentinel constant to maintain
    // valid SSA form - even though the rest of the caller is unreachable.
    call_->ReplaceUsesWith(caller_graph_->GetConstant(Object::sentinel()));

    // Update dominator tree.
    for (intptr_t i = 0, n = callee_entry->dominated_blocks().length(); i < n;
         i++) {
      BlockEntryInstr* block = callee_entry->dominated_blocks()[i];
      true_target->AddDominatedBlock(block);
    }
    for (intptr_t i = 0, n = call_block->dominated_blocks().length(); i < n;
         i++) {
      BlockEntryInstr* block = call_block->dominated_blocks()[i];
      false_block->AddDominatedBlock(block);
    }
    call_block->ClearDominatedBlocks();
    call_block->AddDominatedBlock(true_target);
    call_block->AddDominatedBlock(false_block);

  } else {
    Definition* callee_result = JoinReturns(
        &callee_exit, &callee_last_instruction, call_block->try_index());
    if (callee_result != NULL) {
      call_->ReplaceUsesWith(callee_result);
    }
    if (callee_last_instruction == callee_entry) {
      // There are no instructions in the inlined function (e.g., it might be
      // a return of a parameter or a return of a constant defined in the
      // initial definitions).
      call_->previous()->LinkTo(call_->next());
    } else {
      call_->previous()->LinkTo(callee_entry->next());
      callee_last_instruction->LinkTo(call_->next());
    }
    if (callee_exit != callee_entry) {
      // In case of control flow, locally update the predecessors, phis and
      // dominator tree.
      //
      // Pictorially, the graph structure is:
      //
      //   Bc : call_block      Bi : callee_entry
      //     before_call          inlined_head
      //     call               ... other blocks ...
      //     after_call         Be : callee_exit
      //                          inlined_foot
      // And becomes:
      //
      //   Bc : call_block
      //     before_call
      //     inlined_head
      //   ... other blocks ...
      //   Be : callee_exit
      //    inlined_foot
      //    after_call
      //
      // For successors of 'after_call', the call block (Bc) is replaced as a
      // predecessor by the callee exit (Be).
      call_block->ReplaceAsPredecessorWith(callee_exit);
      // For successors of 'inlined_head', the callee entry (Bi) is replaced
      // as a predecessor by the call block (Bc).
      callee_entry->ReplaceAsPredecessorWith(call_block);

      // The callee exit is now the immediate dominator of blocks whose
      // immediate dominator was the call block.
      ASSERT(callee_exit->dominated_blocks().is_empty());
      for (intptr_t i = 0; i < call_block->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = call_block->dominated_blocks()[i];
        callee_exit->AddDominatedBlock(block);
      }
      // The call block is now the immediate dominator of blocks whose
      // immediate dominator was the callee entry.
      call_block->ClearDominatedBlocks();
      for (intptr_t i = 0; i < callee_entry->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = callee_entry->dominated_blocks()[i];
        call_block->AddDominatedBlock(block);
      }
    }

    // Callee entry in not in the graph anymore. Remove it from use lists.
    callee_entry->UnuseAllInputs();
  }
  // Neither call nor the graph entry (if present) are in the
  // graph at this point. Remove them from use lists.
  if (callee_entry->PredecessorCount() > 0) {
    callee_entry->PredecessorAt(0)->AsGraphEntry()->UnuseAllInputs();
  }
  call_->UnuseAllInputs();
}

bool SimpleInstanceOfType(const AbstractType& type) {
  // Bail if the type is still uninstantiated at compile time.
  if (!type.IsInstantiated()) return false;

  // Bail if the type is a function or a Dart Function type.
  if (type.IsFunctionType() || type.IsDartFunctionType()) return false;

  ASSERT(type.HasTypeClass());
  const Class& type_class = Class::Handle(type.type_class());

  // Bail if the type has any type parameters.
  if (type_class.IsGeneric()) {
    // If the interface type we check against is generic but has all-dynamic
    // type arguments, then we can still use the _simpleInstanceOf
    // implementation (see also runtime/lib/object.cc:Object_SimpleInstanceOf).
    const auto& rare_type = AbstractType::Handle(type_class.RareType());
    // TODO(regis): Revisit the usage of TypeEquality::kSyntactical when
    // implementing strong mode.
    return rare_type.IsEquivalent(type, TypeEquality::kSyntactical);
  }

  // Finally a simple class for instance of checking.
  return true;
}

}  // namespace dart
