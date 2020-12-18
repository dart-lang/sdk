// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DEBUG)

#include "vm/compiler/backend/flow_graph_checker.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/loops.h"

namespace dart {

DECLARE_FLAG(bool, trace_compiler);

DEFINE_FLAG(int,
            verify_definitions_threshold,
            250,
            "Definition count threshold for extensive instruction checks");

// Returns true for the "optimized out" and "null" constant.
// Such constants reside outside the IR in the sense that
// succ/pred/block links are not maintained.
static bool IsSpecialConstant(Definition* def) {
  if (auto c = def->AsConstant()) {
    return c->value().raw() == Symbols::OptimizedOut().raw() ||
           c->value().raw() == Object::ZoneHandle().raw();
  }
  return false;
}

// Returns true if block is a predecessor of succ.
static bool IsPred(BlockEntryInstr* block, BlockEntryInstr* succ) {
  for (intptr_t i = 0, n = succ->PredecessorCount(); i < n; ++i) {
    if (succ->PredecessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

// Returns true if block is a successor of pred.
static bool IsSucc(BlockEntryInstr* block, BlockEntryInstr* pred) {
  Instruction* last = pred->last_instruction();
  for (intptr_t i = 0, n = last->SuccessorCount(); i < n; ++i) {
    if (last->SuccessorAt(i) == block) {
      return true;
    }
  }
  return false;
}

// Returns true if dom directly dominates block.
static bool IsDirectlyDominated(BlockEntryInstr* block, BlockEntryInstr* dom) {
  for (intptr_t i = 0, n = dom->dominated_blocks().length(); i < n; ++i) {
    if (dom->dominated_blocks()[i] == block) {
      return true;
    }
  }
  return false;
}

// Returns true if instruction appears in use list.
static bool IsInUseList(Value* use, Instruction* instruction) {
  for (; use != nullptr; use = use->next_use()) {
    if (use->instruction() == instruction) {
      return true;
    }
  }
  return false;
}

// Returns true if definition dominates instruction. Note that this
// helper is required to account for some situations that are not
// accounted for in the IR methods that compute dominance.
static bool DefDominatesUse(Definition* def, Instruction* instruction) {
  if (instruction->IsPhi()) {
    // A phi use is not necessarily dominated by a definition.
    // Proper dominance relation on the input values of Phis is
    // checked by the Phi visitor below.
    return true;
  } else if (def->IsMaterializeObject() || instruction->IsMaterializeObject()) {
    // These instructions reside outside the IR.
    return true;
  } else if (auto entry =
                 instruction->GetBlock()->AsBlockEntryWithInitialDefs()) {
    // An initial definition in the same block.
    // TODO(ajcbik): use an initial def too?
    for (auto idef : *entry->initial_definitions()) {
      if (idef == def) {
        return true;
      }
    }
  }
  // Use the standard IR method for dominance.
  return instruction->IsDominatedBy(def);
}

// Returns true if instruction forces control flow.
static bool IsControlFlow(Instruction* instruction) {
  return instruction->IsBranch() || instruction->IsGoto() ||
         instruction->IsIndirectGoto() || instruction->IsReturn() ||
         instruction->IsThrow() || instruction->IsReThrow() ||
         instruction->IsTailCall();
}

// Asserts that arguments appear in environment at the right place.
static void AssertArgumentsInEnv(FlowGraph* flow_graph, Definition* call) {
  Environment* env = call->env();
  if (env == nullptr) {
    // Environments can be removed by EliminateEnvironments pass and
    // are not present before SSA.
  } else if (flow_graph->function().IsIrregexpFunction()) {
    // TODO(dartbug.com/38577): cleanup regexp pipeline too....
  } else {
    // Otherwise, the trailing environment entries must
    // correspond directly with the arguments.
    const intptr_t env_count = env->Length();
    const intptr_t arg_count = call->ArgumentCount();
    ASSERT(arg_count <= env_count);
    const intptr_t env_base = env_count - arg_count;
    for (intptr_t i = 0; i < arg_count; i++) {
      if (call->HasPushArguments()) {
        ASSERT(call->ArgumentAt(i) == env->ValueAt(env_base + i)
                                          ->definition()
                                          ->AsPushArgument()
                                          ->value()
                                          ->definition());
      } else {
        // Redefintion instructions and boxing/unboxing are inserted
        // without updating environment uses (FlowGraph::RenameDominatedUses,
        // FlowGraph::InsertConversionsFor).
        // Also, constants may belong to different blocks (e.g. function entry
        // and graph entry).
        Definition* arg_def =
            call->ArgumentAt(i)->OriginalDefinitionIgnoreBoxingAndConstraints();
        Definition* env_def =
            env->ValueAt(env_base + i)
                ->definition()
                ->OriginalDefinitionIgnoreBoxingAndConstraints();
        ASSERT((arg_def == env_def) ||
               (arg_def->IsConstant() && env_def->IsConstant() &&
                arg_def->AsConstant()->value().raw() ==
                    env_def->AsConstant()->value().raw()));
      }
    }
  }
}

void FlowGraphChecker::VisitBlocks() {
  const GrowableArray<BlockEntryInstr*>& preorder = flow_graph_->preorder();
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph_->postorder();
  const GrowableArray<BlockEntryInstr*>& rev_postorder =
      flow_graph_->reverse_postorder();

  // Make sure lengths match.
  const intptr_t block_count = preorder.length();
  ASSERT(block_count == postorder.length());
  ASSERT(block_count == rev_postorder.length());

  // Make sure postorder has true reverse.
  for (intptr_t i = 0; i < block_count; ++i) {
    ASSERT(postorder[i] == rev_postorder[block_count - i - 1]);
  }

  // Iterate over all basic blocks.
  const intptr_t max_block_id = flow_graph_->max_block_id();
  for (BlockIterator it = flow_graph_->reverse_postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    ASSERT(block->block_id() <= max_block_id);
    // Make sure ordering is consistent.
    ASSERT(block->preorder_number() <= block_count);
    ASSERT(block->postorder_number() <= block_count);
    ASSERT(preorder[block->preorder_number()] == block);
    ASSERT(postorder[block->postorder_number()] == block);
    // Make sure predecessors and successors agree.
    Instruction* last = block->last_instruction();
    for (intptr_t i = 0, n = last->SuccessorCount(); i < n; ++i) {
      ASSERT(IsPred(block, last->SuccessorAt(i)));
    }
    for (intptr_t i = 0, n = block->PredecessorCount(); i < n; ++i) {
      ASSERT(IsSucc(block, block->PredecessorAt(i)));
    }
    // Make sure dominance relations agree.
    for (intptr_t i = 0, n = block->dominated_blocks().length(); i < n; ++i) {
      ASSERT(block->dominated_blocks()[i]->dominator() == block);
    }
    if (block->dominator() != nullptr) {
      ASSERT(IsDirectlyDominated(block, block->dominator()));
    }
    // Visit all instructions in this block.
    VisitInstructions(block);
  }
}

void FlowGraphChecker::VisitInstructions(BlockEntryInstr* block) {
  // To avoid excessive runtimes, skip the instructions check if there
  // are many definitions (as happens in e.g. an initialization block).
  if (flow_graph_->current_ssa_temp_index() >
      FLAG_verify_definitions_threshold) {
    return;
  }
  // Give all visitors quick access.
  current_block_ = block;
  // Visit initial definitions.
  if (auto entry = block->AsBlockEntryWithInitialDefs()) {
    for (auto def : *entry->initial_definitions()) {
      ASSERT(def != nullptr);
      ASSERT(def->IsConstant() || def->IsParameter() ||
             def->IsSpecialParameter());
      // Special constants reside outside the IR.
      if (IsSpecialConstant(def)) continue;
      // Make sure block lookup agrees.
      ASSERT(def->GetBlock() == entry);
      // Initial definitions are partially linked into graph.
      ASSERT(def->next() == nullptr);
      ASSERT(def->previous() == entry);
      // Visit the initial definition as instruction.
      VisitInstruction(def);
    }
  }
  // Visit phis in join.
  if (auto entry = block->AsJoinEntry()) {
    for (PhiIterator it(entry); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      // Make sure block lookup agrees.
      ASSERT(phi->GetBlock() == entry);
      // Phis are never linked into graph.
      ASSERT(phi->next() == nullptr);
      ASSERT(phi->previous() == nullptr);
      // Visit the phi as instruction.
      VisitInstruction(phi);
    }
  }
  // Visit regular instructions.
  Instruction* last = block->last_instruction();
  ASSERT((last == block) == block->IsGraphEntry());
  Instruction* prev = block;
  ASSERT(prev->previous() == nullptr);
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instruction = it.Current();
    // Make sure block lookup agrees (scan in scan).
    ASSERT(instruction->GetBlock() == block);
    // Make sure linked list agrees.
    ASSERT(prev->next() == instruction);
    ASSERT(instruction->previous() == prev);
    prev = instruction;
    // Make sure control flow makes sense.
    ASSERT(IsControlFlow(instruction) == (instruction == last));
    ASSERT(!instruction->IsPhi());
    // Visit the instruction.
    VisitInstruction(instruction);
  }
  ASSERT(prev->next() == nullptr);
  ASSERT(prev == last);
  // Make sure loop information, when up-to-date, agrees.
  if (flow_graph_->loop_hierarchy_ != nullptr) {
    for (LoopInfo* loop = block->loop_info(); loop != nullptr;
         loop = loop->outer()) {
      ASSERT(loop->Contains(block));
    }
  }
}

void FlowGraphChecker::VisitInstruction(Instruction* instruction) {
  ASSERT(!instruction->IsBlockEntry());

#if !defined(DART_PRECOMPILER)
  // In JIT mode, any instruction which may throw must have a deopt-id, except
  // tail-call because it replaces the stack frame.
  ASSERT(!instruction->MayThrow() || instruction->IsTailCall() ||
         instruction->deopt_id() != DeoptId::kNone);
#endif  // !defined(DART_PRECOMPILER)

  // If checking token positions and the flow graph has an inlining ID,
  // check the inlining ID and token position for instructions with real or
  // synthetic token positions.
  if (FLAG_check_token_positions && flow_graph_->inlining_id() >= 0) {
    const TokenPosition& pos = instruction->token_pos();
    if (pos.IsReal() || pos.IsSynthetic()) {
      ASSERT(instruction->has_inlining_id());
      const intptr_t inlining_id = instruction->inlining_id();
      const auto& function = *inline_id_to_function_[inlining_id];
      if (function.end_token_pos().IsReal() &&
          !pos.IsWithin(function.token_pos(), function.end_token_pos())) {
        TextBuffer buffer(256);
        buffer.Printf("Token position %s is invalid for function %s (%s, %s)",
                      pos.ToCString(), function.ToFullyQualifiedCString(),
                      function.token_pos().ToCString(),
                      function.end_token_pos().ToCString());
        if (inlining_id > 0) {
          buffer.Printf(" while compiling function %s",
                        inline_id_to_function_[0]->ToFullyQualifiedCString());
        }
        FATAL("%s", buffer.buffer());
      }
      script_ = function.script();
      if (!script_.IsNull() && !script_.IsValidTokenPosition(pos)) {
        TextBuffer buffer(256);
        buffer.Printf(
            "Token position %s is invalid for script %s of function %s",
            pos.ToCString(), script_.ToCString(),
            function.ToFullyQualifiedCString());
        if (inlining_id > 0) {
          buffer.Printf(" while compiling function %s",
                        inline_id_to_function_[0]->ToFullyQualifiedCString());
        }
        FATAL("%s", buffer.buffer());
      }
    }
  }

  // Check all regular inputs.
  for (intptr_t i = 0, n = instruction->InputCount(); i < n; ++i) {
    VisitUseDef(instruction, instruction->InputAt(i), i, /*is_env*/ false);
  }
  // Check all environment inputs (including outer ones).
  intptr_t i = 0;
  for (Environment::DeepIterator it(instruction->env()); !it.Done();
       it.Advance()) {
    VisitUseDef(instruction, it.CurrentValue(), i++, /*is_env*/ true);
  }
  // Visit specific instructions (definitions and anything with Visit()).
  if (auto def = instruction->AsDefinition()) {
    VisitDefinition(def);
  }
  instruction->Accept(this);
}

void FlowGraphChecker::VisitDefinition(Definition* def) {
  // Used definitions must have an SSA name, and the SSA name must
  // be less than the current_ssa_temp_index.
  if (def->HasSSATemp()) {
    ASSERT(def->ssa_temp_index() < flow_graph_->current_ssa_temp_index());
  } else {
    ASSERT(def->input_use_list() == nullptr);
  }
  // Check all regular uses.
  Value* prev = nullptr;
  for (Value* use = def->input_use_list(); use != nullptr;
       use = use->next_use()) {
    VisitDefUse(def, use, prev, /*is_env*/ false);
    prev = use;
  }
  // Check all environment uses.
  prev = nullptr;
  for (Value* use = def->env_use_list(); use != nullptr;
       use = use->next_use()) {
    VisitDefUse(def, use, prev, /*is_env*/ true);
    prev = use;
  }
}

void FlowGraphChecker::VisitUseDef(Instruction* instruction,
                                   Value* use,
                                   intptr_t index,
                                   bool is_env) {
  ASSERT(use->instruction() == instruction);
  ASSERT(use->use_index() == index);
  // Get definition.
  Definition* def = use->definition();
  ASSERT(def != nullptr);
  ASSERT(def != instruction || def->IsPhi() || def->IsMaterializeObject());
  // Make sure each input is properly defined in the graph by something
  // that dominates the input (note that the proper dominance relation
  // on the input values of Phis is checked by the Phi visitor below).
  if (def->IsPhi()) {
    ASSERT(def->GetBlock()->IsJoinEntry());
    // Phis are never linked into graph.
    ASSERT(def->next() == nullptr);
    ASSERT(def->previous() == nullptr);
  } else if (def->IsConstant() || def->IsParameter() ||
             def->IsSpecialParameter()) {
    // Special constants reside outside the IR.
    if (IsSpecialConstant(def)) return;
    // Initial definitions are partially linked into graph, but some
    // constants are fully linked into graph (so no next() assert).
    ASSERT(def->previous() != nullptr);
  } else {
    // Others are fully linked into graph.
    ASSERT(def->next() != nullptr);
    ASSERT(def->previous() != nullptr);
  }
  if (def->HasSSATemp()) {
    ASSERT(DefDominatesUse(def, instruction));
    ASSERT(IsInUseList(is_env ? def->env_use_list() : def->input_use_list(),
                       instruction));
  }
}

void FlowGraphChecker::VisitDefUse(Definition* def,
                                   Value* use,
                                   Value* prev,
                                   bool is_env) {
  ASSERT(use->definition() == def);
  ASSERT(use->previous_use() == prev);
  // Get using instruction.
  Instruction* instruction = use->instruction();
  ASSERT(instruction != nullptr);
  ASSERT(def != instruction || def->IsPhi() || def->IsMaterializeObject());
  if (is_env) {
    ASSERT(instruction->env()->ValueAtUseIndex(use->use_index()) == use);
  } else {
    ASSERT(instruction->InputAt(use->use_index()) == use);
  }
  // Make sure the reaching type, if any, has an owner consistent with this use.
  if (auto const type = use->reaching_type()) {
    ASSERT(type->owner() == nullptr || type->owner() == def);
  }
  // Make sure each use appears in the graph and is properly dominated
  // by the definition (note that the proper dominance relation on the
  // input values of Phis is checked by the Phi visitor below).
  if (instruction->IsPhi()) {
    ASSERT(instruction->AsPhi()->is_alive());
    ASSERT(instruction->GetBlock()->IsJoinEntry());
    // Phis are never linked into graph.
    ASSERT(instruction->next() == nullptr);
    ASSERT(instruction->previous() == nullptr);
  } else if (instruction->IsBlockEntry()) {
    // BlockEntry instructions have environments attached to them but
    // have no reliable way to verify if they are still in the graph.
    ASSERT(is_env);
    ASSERT(instruction->next() != nullptr);
    ASSERT(DefDominatesUse(def, instruction));
  } else {
    // Others are fully linked into graph.
    ASSERT(IsControlFlow(instruction) || instruction->next() != nullptr);
    ASSERT(instruction->previous() != nullptr);
    ASSERT(!def->HasSSATemp() || DefDominatesUse(def, instruction));
  }
}

void FlowGraphChecker::VisitConstant(ConstantInstr* constant) {
  // Range check on smi.
  const Object& value = constant->value();
  if (value.IsSmi()) {
    const int64_t smi_value = Integer::Cast(value).AsInt64Value();
    ASSERT(compiler::target::kSmiMin <= smi_value);
    ASSERT(smi_value <= compiler::target::kSmiMax);
  }
  // Any constant involved in SSA should appear in the entry (making it more
  // likely it was inserted by the utility that avoids duplication).
  //
  // TODO(dartbug.com/36894)
  //
  // ASSERT(constant->GetBlock() == flow_graph_->graph_entry());
}

void FlowGraphChecker::VisitPhi(PhiInstr* phi) {
  // Make sure the definition of each input value of a Phi dominates
  // the corresponding incoming edge, as defined by order.
  ASSERT(phi->InputCount() == current_block_->PredecessorCount());
  for (intptr_t i = 0, n = phi->InputCount(); i < n; ++i) {
    Definition* def = phi->InputAt(i)->definition();
    ASSERT(def->HasSSATemp());  // phis have SSA defs
    BlockEntryInstr* edge = current_block_->PredecessorAt(i);
    ASSERT(DefDominatesUse(def, edge->last_instruction()));
  }
}

void FlowGraphChecker::VisitGoto(GotoInstr* jmp) {
  ASSERT(jmp->SuccessorCount() == 1);
}

void FlowGraphChecker::VisitIndirectGoto(IndirectGotoInstr* jmp) {
  ASSERT(jmp->SuccessorCount() >= 1);
}

void FlowGraphChecker::VisitBranch(BranchInstr* branch) {
  ASSERT(branch->SuccessorCount() == 2);
}

void FlowGraphChecker::VisitRedefinition(RedefinitionInstr* def) {
  ASSERT(def->value()->definition() != def);
}

void FlowGraphChecker::VisitClosureCall(ClosureCallInstr* call) {
  AssertArgumentsInEnv(flow_graph_, call);
}

void FlowGraphChecker::VisitStaticCall(StaticCallInstr* call) {
  AssertArgumentsInEnv(flow_graph_, call);
}

void FlowGraphChecker::VisitInstanceCall(InstanceCallInstr* call) {
  AssertArgumentsInEnv(flow_graph_, call);
  // Force-optimized functions may not have instance calls inside them because
  // we do not reset ICData for these.
  ASSERT(!flow_graph_->function().ForceOptimize());
}

void FlowGraphChecker::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  AssertArgumentsInEnv(flow_graph_, call);
  // Force-optimized functions may not have instance calls inside them because
  // we do not reset ICData for these.
  ASSERT(!flow_graph_->function().ForceOptimize());
}

// Main entry point of graph checker.
void FlowGraphChecker::Check(const char* pass_name) {
  if (FLAG_trace_compiler) {
    THR_Print("Running checker after %s\n", pass_name);
  }
  ASSERT(flow_graph_ != nullptr);
  VisitBlocks();
}

}  // namespace dart

#endif  // defined(DEBUG)
