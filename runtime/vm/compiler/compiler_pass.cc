// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/compiler_pass.h"

#ifndef DART_PRECOMPILED_RUNTIME

#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/constant_propagator.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/call_specializer.h"
#if defined(DART_PRECOMPILER)
#include "vm/compiler/aot/aot_call_specializer.h"
#endif
#include "vm/timeline.h"

#define COMPILER_PASS_REPEAT(Name, Body)                                       \
  class CompilerPass_##Name : public CompilerPass {                            \
   public:                                                                     \
    CompilerPass_##Name() : CompilerPass(k##Name, #Name) {}                    \
                                                                               \
    static bool Register() { return true; }                                    \
                                                                               \
   protected:                                                                  \
    virtual bool DoBody(CompilerPassState* state) const {                      \
      FlowGraph* flow_graph = state->flow_graph;                               \
      USE(flow_graph);                                                         \
      Body;                                                                    \
    }                                                                          \
  };                                                                           \
  static CompilerPass_##Name compiler_pass_##Name;

#define COMPILER_PASS(Name, Body)                                              \
  COMPILER_PASS_REPEAT(Name, {                                                 \
    Body;                                                                      \
    return false;                                                              \
  })

namespace dart {

CompilerPass* CompilerPass::passes_[CompilerPass::kNumPasses] = {NULL};

DEFINE_OPTION_HANDLER(CompilerPass::ParseFilters,
                      compiler_passes,
                      "List of comma separated compilation passes flags. "
                      "Use -Name to disable a pass, Name to print IL after it. "
                      "Do --compiler-passes=help for more information.");

static const char* kCompilerPassesUsage =
    "=== How to use --compiler-passes flag\n"
    "\n"
    "Pass the list of comma separated compiler pass filter flags.\n"
    "\n"
    "For the given pass Name the following flags are supported:\n"
    "\n"
    "     -Name          disable the pass\n"
    "     ]Name or Name  print IL after the pass\n"
    "     [Name          print IL before the pass\n"
    "     *Name          print IL before and after the pass\n"
    "     *              print IL after each pass.\n"
    "\n"
    " The flag can be followed by '+' which makes it sticky, e.g. Inlining+\n"
    " would cause IL to be printed after all passes that follow inlining and\n"
    " are not disabled.\n"
    "\n"
    "List of compiler passes:\n";

void CompilerPass::ParseFilters(const char* filter) {
  if (filter == NULL || *filter == 0) {
    return;
  }

  if (strcmp(filter, "help") == 0) {
    OS::PrintErr("%s", kCompilerPassesUsage);
    for (intptr_t i = 0; i < kNumPasses; i++) {
      if (passes_[i] != NULL) {
        OS::PrintErr("  %s\n", passes_[i]->name());
      }
    }
    return;
  }

  for (const char *start = filter, *end = filter; *end != 0;
       start = (end + 1)) {
    // Search forward until the separator ',' or the end of filter is reached.
    end = start;
    while (*end != ',' && *end != '\0') {
      end++;
    }
    if (start == end) {
      OS::PrintErr("Ignoring empty compiler pass flag\n");
      continue;
    }

    uint8_t flags = 0;
    if (*start == '-') {
      flags = kDisabled;
    } else if (*start == ']') {
      flags = kTraceAfter;
    } else if (*start == '[') {
      flags = kTraceBefore;
    } else if (*start == '*') {
      flags = kTraceBeforeOrAfter;
    }
    if (flags == 0) {
      flags |= kTraceAfter;
    } else {
      start++;  // Skip the modifier
    }

    size_t suffix = 0;
    if (end[-1] == '+') {
      if (start == (end - 1)) {
        OS::PrintErr("Sticky modifier '+' should follow pass name\n");
        continue;
      }
      flags |= kSticky;
      suffix = 1;
    }

    size_t length = (end - start) - suffix;
    if (length != 0) {
      char* pass_name = Utils::StrNDup(start, length);
      CompilerPass* pass = FindPassByName(pass_name);
      if (pass != NULL) {
        pass->flags_ |= flags;
      } else {
        OS::PrintErr("Unknown compiler pass: %s\n", pass_name);
      }
      free(pass_name);
    } else if (flags == kTraceBeforeOrAfter) {
      for (intptr_t i = 0; i < kNumPasses; i++) {
        if (passes_[i] != NULL) {
          passes_[i]->flags_ = kTraceAfter;
        }
      }
    }
  }
}

void CompilerPass::Run(CompilerPassState* state) const {
  if (IsFlagSet(kDisabled)) {
    return;
  }

  if ((flags() & kSticky) != 0) {
    state->sticky_flags |= flags();
  }

  const intptr_t kMaxRounds = 2;
  Thread* thread = state->thread;
  bool repeat = true;
  for (intptr_t round = 1; round <= kMaxRounds && repeat; round++) {
    if (round > 1) {
      Get(kCanonicalize)->Run(state);
    }

    PrintGraph(state, kTraceBefore, round);
    {
      NOT_IN_PRODUCT(
          TimelineDurationScope tds2(thread, state->compiler_timeline, name()));
      repeat = DoBody(state);
      DEBUG_ASSERT(state->flow_graph->VerifyUseLists());
      thread->CheckForSafepoint();
    }
    PrintGraph(state, kTraceAfter, round);
  }
}

void CompilerPass::PrintGraph(CompilerPassState* state,
                              Flag mask,
                              intptr_t round) const {
  const intptr_t current_flags = flags() | state->sticky_flags;
  FlowGraph* flow_graph = state->flow_graph;

  if (flow_graph->should_print() && ((current_flags & mask) != 0)) {
    Zone* zone = state->thread->zone();
    const char* when = mask == kTraceBefore ? "Before" : "After";
    const char* phase =
        round == 1
            ? zone->PrintToString("%s %s", when, name())
            : zone->PrintToString("%s %s (round %" Pd ")", when, name(), round);

    FlowGraphPrinter::PrintGraph(phase, flow_graph);
  }
}

#define INVOKE_PASS(Name)                                                      \
  CompilerPass::Get(CompilerPass::k##Name)->Run(pass_state);

void CompilerPass::RunPipeline(PipelineMode mode,
                               CompilerPassState* pass_state) {
  INVOKE_PASS(ComputeSSA);
#if defined(DART_PRECOMPILER)
  if (mode == kAOT) {
    INVOKE_PASS(ApplyClassIds);
    INVOKE_PASS(TypePropagation);
  }
#endif
  INVOKE_PASS(ApplyICData);
  INVOKE_PASS(TryOptimizePatterns);
  INVOKE_PASS(SetOuterInliningId);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyClassIds);
  INVOKE_PASS(Inlining);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyClassIds);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(BranchSimplify);
  INVOKE_PASS(IfConvert);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(ConstantPropagation);
  INVOKE_PASS(OptimisticallySpecializeSmiPhis);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(WidenSmiToInt32);
  INVOKE_PASS(SelectRepresentations);
  INVOKE_PASS(CSE);
  INVOKE_PASS(LICM);
  INVOKE_PASS(TryOptimizePatterns);
  INVOKE_PASS(DSE);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(RangeAnalysis);
  INVOKE_PASS(OptimizeBranches);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(TryCatchOptimization);
  INVOKE_PASS(EliminateEnvironments);
  INVOKE_PASS(EliminateDeadPhis);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(AllocationSinking_Sink);
  INVOKE_PASS(EliminateDeadPhis);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(SelectRepresentations);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(EliminateStackOverflowChecks);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(AllocationSinking_DetachMaterializations);
#if defined(DART_PRECOMPILER)
  if (mode == kAOT) {
    INVOKE_PASS(ReplaceArrayBoundChecksForAOT);
  }
#endif
  INVOKE_PASS(FinalizeGraph);
  INVOKE_PASS(AllocateRegisters);
  if (mode == kJIT) {
    INVOKE_PASS(ReorderBlocks);
  }
}

COMPILER_PASS(ComputeSSA, {
  CSTAT_TIMER_SCOPE(state->thread, ssa_timer);
  // Transform to SSA (virtual register 0 and no inlining arguments).
  flow_graph->ComputeSSA(0, NULL);
});

COMPILER_PASS(ApplyICData, { state->call_specializer->ApplyICData(); });

COMPILER_PASS(TryOptimizePatterns, { flow_graph->TryOptimizePatterns(); });

COMPILER_PASS(SetOuterInliningId,
              { FlowGraphInliner::SetInliningId(flow_graph, 0); });

COMPILER_PASS(Inlining, {
  CSTAT_TIMER_SCOPE(state->thread, graphinliner_timer);
  FlowGraphInliner inliner(
      flow_graph, &state->inline_id_to_function, &state->inline_id_to_token_pos,
      &state->caller_inline_id, state->speculative_policy, state->precompiler);
  state->inlining_depth = inliner.Inline();
});

COMPILER_PASS(TypePropagation,
              { FlowGraphTypePropagator::Propagate(flow_graph); });

COMPILER_PASS(ApplyClassIds, { state->call_specializer->ApplyClassIds(); });

COMPILER_PASS(EliminateStackOverflowChecks, {
  if (!flow_graph->IsCompiledForOsr()) {
    CheckStackOverflowElimination::EliminateStackOverflow(flow_graph);
  }
});

COMPILER_PASS(Canonicalize, {
  // Do optimizations that depend on the propagated type information.
  if (flow_graph->Canonicalize()) {
    flow_graph->Canonicalize();
  }
});

COMPILER_PASS(BranchSimplify, { BranchSimplifier::Simplify(flow_graph); });

COMPILER_PASS(IfConvert, { IfConverter::Simplify(flow_graph); });

COMPILER_PASS_REPEAT(ConstantPropagation, {
  ConstantPropagator::Optimize(flow_graph);
  return true;
});

// Optimistically convert loop phis that have a single non-smi input
// coming from the loop pre-header into smi-phis.
COMPILER_PASS(OptimisticallySpecializeSmiPhis, {
  LICM licm(flow_graph);
  licm.OptimisticallySpecializeSmiPhis();
});

COMPILER_PASS(WidenSmiToInt32, {
  // Where beneficial convert Smi operations into Int32 operations.
  // Only meanigful for 32bit platforms right now.
  flow_graph->WidenSmiToInt32();
});

COMPILER_PASS(SelectRepresentations, {
  // Unbox doubles. Performed after constant propagation to minimize
  // interference from phis merging double values and tagged
  // values coming from dead paths.
  flow_graph->SelectRepresentations();
});

COMPILER_PASS_REPEAT(CSE, { return DominatorBasedCSE::Optimize(flow_graph); });

COMPILER_PASS(LICM, {
  flow_graph->RenameUsesDominatedByRedefinitions();
  DEBUG_ASSERT(flow_graph->VerifyRedefinitions());
  LICM licm(flow_graph);
  licm.Optimize();
  flow_graph->RemoveRedefinitions();
});

COMPILER_PASS(DSE, { DeadStoreElimination::Optimize(flow_graph); });

COMPILER_PASS(RangeAnalysis, {
  // We have to perform range analysis after LICM because it
  // optimistically moves CheckSmi through phis into loop preheaders
  // making some phis smi.
  RangeAnalysis range_analysis(flow_graph);
  range_analysis.Analyze();
});

COMPILER_PASS(OptimizeBranches, {
  // Constant propagation can use information from range analysis to
  // find unreachable branch targets and eliminate branches that have
  // the same true- and false-target.
  ConstantPropagator::OptimizeBranches(flow_graph);
});

COMPILER_PASS(TryCatchOptimization,
              { TryCatchAnalyzer::Optimize(flow_graph); });

COMPILER_PASS(EliminateEnvironments, { flow_graph->EliminateEnvironments(); });

COMPILER_PASS(EliminateDeadPhis,
              { DeadCodeElimination::EliminateDeadPhis(flow_graph); });

COMPILER_PASS(AllocationSinking_Sink, {
  // TODO(vegorov): Support allocation sinking with try-catch.
  if (flow_graph->graph_entry()->SuccessorCount() == 1) {
    state->sinking = new AllocationSinking(flow_graph);
    state->sinking->Optimize();
  }
});

COMPILER_PASS(AllocationSinking_DetachMaterializations, {
  if (state->sinking != NULL) {
    // Remove all MaterializeObject instructions inserted by allocation
    // sinking from the flow graph and let them float on the side
    // referenced only from environments. Register allocator will consider
    // them as part of a deoptimization environment.
    state->sinking->DetachMaterializations();
  }
});

COMPILER_PASS(AllocateRegisters, {
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*flow_graph);
  allocator.AllocateRegisters();
});

COMPILER_PASS(ReorderBlocks, {
  if (state->reorder_blocks) {
    state->block_scheduler->ReorderBlocks();
  }
});

COMPILER_PASS(FinalizeGraph, {
  // Compute and store graph informations (call & instruction counts)
  // to be later used by the inliner.
  FlowGraphInliner::CollectGraphInfo(flow_graph, true);
  flow_graph->function().set_inlining_depth(state->inlining_depth);
  flow_graph->RemoveRedefinitions();
});

#if defined(DART_PRECOMPILER)
COMPILER_PASS(ReplaceArrayBoundChecksForAOT,
              { AotCallSpecializer::ReplaceArrayBoundChecks(flow_graph); })
#endif

}  // namespace dart

#endif  // DART_PRECOMPILED_RUNTIME
