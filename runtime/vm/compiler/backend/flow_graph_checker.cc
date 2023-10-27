// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

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

#define ASSERT1(cond, ctxt1)                                                   \
  do {                                                                         \
    if (!(cond))                                                               \
      dart::Assert(__FILE__, __LINE__)                                         \
          .Fail("expected: %s (%s=%s)", #cond, #ctxt1, (ctxt1)->ToCString());  \
  } while (false)

#define ASSERT2(cond, ctxt1, ctxt2)                                            \
  do {                                                                         \
    if (!(cond))                                                               \
      dart::Assert(__FILE__, __LINE__)                                         \
          .Fail("expected: %s (%s=%s, %s=%s)", #cond, #ctxt1,                  \
                (ctxt1)->ToCString(), #ctxt2, (ctxt2)->ToCString());           \
  } while (false)

// Returns true for the "optimized out" and "null" constant.
// Such constants may have a lot of uses and checking them could be too slow.
static bool IsCommonConstant(Definition* def) {
  if (auto c = def->AsConstant()) {
    return c->value().ptr() == Object::optimized_out().ptr() ||
           c->value().ptr() == Object::null();
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
    ASSERT1(block->block_id() <= max_block_id, block);
    // Make sure ordering is consistent.
    ASSERT1(block->preorder_number() <= block_count, block);
    ASSERT1(block->postorder_number() <= block_count, block);
    ASSERT1(preorder[block->preorder_number()] == block, block);
    ASSERT1(postorder[block->postorder_number()] == block, block);
    // Make sure predecessors and successors agree.
    Instruction* last = block->last_instruction();
    for (intptr_t i = 0, n = last->SuccessorCount(); i < n; ++i) {
      ASSERT1(IsPred(block, last->SuccessorAt(i)), block);
    }
    for (intptr_t i = 0, n = block->PredecessorCount(); i < n; ++i) {
      ASSERT1(IsSucc(block, block->PredecessorAt(i)), block);
    }
    // Make sure dominance relations agree.
    for (intptr_t i = 0, n = block->dominated_blocks().length(); i < n; ++i) {
      ASSERT1(block->dominated_blocks()[i]->dominator() == block, block);
    }
    if (block->dominator() != nullptr) {
      ASSERT1(IsDirectlyDominated(block, block->dominator()), block);
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
      ASSERT1(
          def->IsConstant() || def->IsParameter() || def->IsSpecialParameter(),
          def);
      // Make sure block lookup agrees.
      ASSERT1(def->GetBlock() == entry, def);
      // Initial definitions are partially linked into graph.
      ASSERT1(def->next() == nullptr, def);
      ASSERT1(def->previous() == entry, def);
      // Skip common constants as checking them could be slow.
      if (IsCommonConstant(def)) continue;
      // Visit the initial definition as instruction.
      VisitInstruction(def);
    }
  }
  // Visit phis in join.
  if (auto entry = block->AsJoinEntry()) {
    for (PhiIterator it(entry); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      // Make sure block lookup agrees.
      ASSERT1(phi->GetBlock() == entry, phi);
      // Phis are never linked into graph.
      ASSERT1(phi->next() == nullptr, phi);
      ASSERT1(phi->previous() == nullptr, phi);
      // Visit the phi as instruction.
      VisitInstruction(phi);
    }
  }
  // Visit regular instructions.
  Instruction* last = block->last_instruction();
  ASSERT1((last == block) == block->IsGraphEntry(), block);
  Instruction* prev = block;
  ASSERT(prev->previous() == nullptr);
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* instruction = it.Current();
    // Make sure block lookup agrees (scan in scan).
    ASSERT1(instruction->GetBlock() == block, instruction);
    // Make sure linked list agrees.
    ASSERT1(prev->next() == instruction, instruction);
    ASSERT1(instruction->previous() == prev, instruction);
    prev = instruction;
    // Make sure control flow makes sense.
    ASSERT1(IsControlFlow(instruction) == (instruction == last), instruction);
    ASSERT1(!instruction->IsPhi(), instruction);
    // Visit the instruction.
    VisitInstruction(instruction);
  }
  ASSERT(prev->next() == nullptr);
  ASSERT(prev == last);
  // Make sure loop information, when up-to-date, agrees.
  if (flow_graph_->loop_hierarchy_ != nullptr) {
    for (LoopInfo* loop = block->loop_info(); loop != nullptr;
         loop = loop->outer()) {
      ASSERT1(loop->Contains(block), block);
    }
  }
}

void FlowGraphChecker::VisitInstruction(Instruction* instruction) {
  ASSERT1(!instruction->IsBlockEntry(), instruction);

#if !defined(DART_PRECOMPILER)
  // In JIT mode, any instruction which may throw must have a deopt-id, except
  // tail-call because it replaces the stack frame.
  ASSERT1(!instruction->MayThrow() ||
              !instruction->GetBlock()->InsideTryBlock() ||
              instruction->IsTailCall() ||
              instruction->deopt_id() != DeoptId::kNone,
          instruction);

  // Any instruction that can eagerly deopt cannot come from a force-optimized
  // function.
  if (instruction->ComputeCanDeoptimize()) {
    ASSERT2(!flow_graph_->function().ForceOptimize(), instruction,
            &flow_graph_->function());
  }

#endif  // !defined(DART_PRECOMPILER)

  // If checking token positions and the flow graph has an inlining ID,
  // check the inlining ID and token position for instructions with real or
  // synthetic token positions.
  if (FLAG_check_token_positions && flow_graph_->inlining_id() >= 0) {
    const TokenPosition& pos = instruction->token_pos();
    if (pos.IsReal() || pos.IsSynthetic()) {
      ASSERT1(instruction->has_inlining_id(), instruction);
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
  ASSERT1(flow_graph_->unmatched_representations_allowed() ||
              !instruction->HasUnmatchedInputRepresentations(),
          instruction);

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
    ASSERT1(def->ssa_temp_index() < flow_graph_->current_ssa_temp_index(), def);
  } else {
    ASSERT1(def->input_use_list() == nullptr, def);
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
  ASSERT2(use->instruction() == instruction, use, instruction);
  ASSERT1(use->use_index() == index, use);
  // Get definition.
  Definition* def = use->definition();
  ASSERT(def != nullptr);
  ASSERT1(def != instruction || def->IsPhi() || def->IsMaterializeObject(),
          def);
  // Make sure each input is properly defined in the graph by something
  // that dominates the input (note that the proper dominance relation
  // on the input values of Phis is checked by the Phi visitor below).
  if (def->IsPhi()) {
    ASSERT1(def->GetBlock()->IsJoinEntry(), def);
    // Phis are never linked into graph.
    ASSERT1(def->next() == nullptr, def);
    ASSERT1(def->previous() == nullptr, def);
  } else if (def->IsConstant() || def->IsParameter() ||
             def->IsSpecialParameter()) {
    // Initial definitions are partially linked into graph, but some
    // constants are fully linked into graph (so no next() assert).
    ASSERT1(def->previous() != nullptr, def);
    // Skip checks below for common constants as checking them could be slow.
    if (IsCommonConstant(def)) return;
  } else if (def->IsMaterializeObject()) {
    // Materializations can be both linked into graph and detached.
    if (def->next() != nullptr) {
      ASSERT1(def->previous() != nullptr, def);
    } else {
      ASSERT1(def->previous() == nullptr, def);
    }
  } else {
    // Others are fully linked into graph.
    ASSERT1(def->next() != nullptr, def);
    ASSERT1(def->previous() != nullptr, def);
  }
  if (def->HasSSATemp()) {
    ASSERT2(DefDominatesUse(def, instruction), def, instruction);
    ASSERT2(IsInUseList(is_env ? def->env_use_list() : def->input_use_list(),
                        instruction),
            def, instruction);
  }
}

void FlowGraphChecker::VisitDefUse(Definition* def,
                                   Value* use,
                                   Value* prev,
                                   bool is_env) {
  ASSERT2(use->definition() == def, use, def);
  ASSERT1(use->previous_use() == prev, use);
  // Get using instruction.
  Instruction* instruction = use->instruction();
  ASSERT(instruction != nullptr);
  ASSERT1(def != instruction || def->IsPhi() || def->IsMaterializeObject(),
          def);
  if (is_env) {
    ASSERT2(instruction->env()->ValueAtUseIndex(use->use_index()) == use,
            instruction, use);
  } else {
    ASSERT2(instruction->InputAt(use->use_index()) == use, instruction, use);
  }
  // Make sure the reaching type, if any, has an owner consistent with this use.
  if (auto const type = use->reaching_type()) {
    ASSERT1(type->owner() == nullptr || type->owner() == def, use);
  }
  // Make sure each use appears in the graph and is properly dominated
  // by the definition (note that the proper dominance relation on the
  // input values of Phis is checked by the Phi visitor below).
  if (instruction->IsPhi()) {
    ASSERT1(instruction->AsPhi()->is_alive(), instruction);
    ASSERT1(instruction->GetBlock()->IsJoinEntry(), instruction);
    // Phis are never linked into graph.
    ASSERT1(instruction->next() == nullptr, instruction);
    ASSERT1(instruction->previous() == nullptr, instruction);
  } else if (instruction->IsBlockEntry()) {
    // BlockEntry instructions have environments attached to them but
    // have no reliable way to verify if they are still in the graph.
    ASSERT1(is_env, instruction);
    ASSERT1(instruction->IsGraphEntry() || instruction->next() != nullptr,
            instruction);
    ASSERT2(DefDominatesUse(def, instruction), def, instruction);
  } else if (instruction->IsMaterializeObject()) {
    // Materializations can be both linked into graph and detached.
    if (instruction->next() != nullptr) {
      ASSERT1(instruction->previous() != nullptr, instruction);
      ASSERT2(DefDominatesUse(def, instruction), def, instruction);
    } else {
      ASSERT1(instruction->previous() == nullptr, instruction);
    }
  } else {
    // Others are fully linked into graph.
    ASSERT1(IsControlFlow(instruction) || instruction->next() != nullptr,
            instruction);
    ASSERT1(instruction->previous() != nullptr, instruction);
    ASSERT2(!def->HasSSATemp() || DefDominatesUse(def, instruction), def,
            instruction);
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
  ASSERT1(phi->InputCount() == current_block_->PredecessorCount(), phi);
  for (intptr_t i = 0, n = phi->InputCount(); i < n; ++i) {
    Definition* def = phi->InputAt(i)->definition();
    ASSERT1(def->HasSSATemp(), def);  // phis have SSA defs
    BlockEntryInstr* edge = current_block_->PredecessorAt(i);
    ASSERT1(DefDominatesUse(def, edge->last_instruction()), def);
  }
}

void FlowGraphChecker::VisitGoto(GotoInstr* jmp) {
  ASSERT1(jmp->SuccessorCount() == 1, jmp);
}

void FlowGraphChecker::VisitIndirectGoto(IndirectGotoInstr* jmp) {
  ASSERT1(jmp->SuccessorCount() >= 1, jmp);
}

void FlowGraphChecker::VisitBranch(BranchInstr* branch) {
  ASSERT1(branch->SuccessorCount() == 2, branch);
}

void FlowGraphChecker::VisitRedefinition(RedefinitionInstr* def) {
  ASSERT1(def->value()->definition() != def, def);
}

// Asserts that arguments appear in environment at the right place.
void FlowGraphChecker::AssertArgumentsInEnv(Definition* call) {
  const auto& function = flow_graph_->function();
  Environment* env = call->env();
  if (env == nullptr) {
    // Environments can be removed by EliminateEnvironments pass and
    // are not present before SSA.
  } else if (function.IsIrregexpFunction()) {
    // TODO(dartbug.com/38577): cleanup regexp pipeline too....
  } else {
    // Otherwise, the trailing environment entries must
    // correspond directly with the arguments.
    const intptr_t env_count = env->Length();
    const intptr_t arg_count = call->ArgumentCount();
    // Some calls (e.g. closure calls) have more inputs than actual arguments.
    // Those extra inputs will be consumed from the stack before the call.
    const intptr_t after_args_input_count = call->env()->LazyDeoptPruneCount();
    ASSERT1((arg_count + after_args_input_count) <= env_count, call);
    const intptr_t env_base = env_count - arg_count - after_args_input_count;
    for (intptr_t i = 0; i < arg_count; i++) {
      if (call->HasMoveArguments()) {
        ASSERT1(call->ArgumentAt(i) == env->ValueAt(env_base + i)
                                           ->definition()
                                           ->AsMoveArgument()
                                           ->value()
                                           ->definition(),
                call);
      } else {
        if (env->LazyDeoptToBeforeDeoptId()) {
          // The deoptimization environment attached to this [call] instruction
          // may no longer target the same call in unoptimized code. It may
          // target anything.
          //
          // As a result, we cannot assume the arguments we pass to the call
          // will also be in the deopt environment.
          //
          // This currently can happen in inlined force-optimized instructions.
          ASSERT(call->inlining_id() > 0);
          const auto& function = *inline_id_to_function_[call->inlining_id()];
          ASSERT(function.ForceOptimize());
          return;
        }

        // Redefinition instructions and boxing/unboxing are inserted
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
        ASSERT2((arg_def == env_def) ||
                    (arg_def->IsConstant() && env_def->IsConstant() &&
                     arg_def->AsConstant()->value().ptr() ==
                         env_def->AsConstant()->value().ptr()),
                arg_def, env_def);
      }
    }
  }
}

void FlowGraphChecker::VisitClosureCall(ClosureCallInstr* call) {
  AssertArgumentsInEnv(call);
}

void FlowGraphChecker::VisitStaticCall(StaticCallInstr* call) {
  AssertArgumentsInEnv(call);
}

void FlowGraphChecker::VisitInstanceCall(InstanceCallInstr* call) {
  AssertArgumentsInEnv(call);
  // Force-optimized functions may not have instance calls inside them because
  // we do not reset ICData for these.
  ASSERT(!flow_graph_->function().ForceOptimize());
}

void FlowGraphChecker::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  AssertArgumentsInEnv(call);
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
