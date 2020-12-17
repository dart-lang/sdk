// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/compiler_pass.h"

#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/constant_propagator.h"
#include "vm/compiler/backend/flow_graph_checker.h"
#include "vm/compiler/backend/il_deserializer.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_serializer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/write_barrier_elimination.h"
#if defined(DART_PRECOMPILER)
#include "vm/compiler/aot/aot_call_specializer.h"
#include "vm/compiler/aot/precompiler.h"
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
      FlowGraph* flow_graph = state->flow_graph();                             \
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

CompilerPassState::CompilerPassState(
    Thread* thread,
    FlowGraph* flow_graph,
    SpeculativeInliningPolicy* speculative_policy,
    Precompiler* precompiler)
    : thread(thread),
      precompiler(precompiler),
      inlining_depth(0),
      sinking(NULL),
      call_specializer(NULL),
      speculative_policy(speculative_policy),
      reorder_blocks(false),
      sticky_flags(0),
      flow_graph_(flow_graph) {
  // Top scope function is at inlining id 0.
  inline_id_to_function.Add(&flow_graph->parsed_function().function());
  // Top scope function has no caller (-1).
  caller_inline_id.Add(-1);
  // We do not add a token position for the top scope function to
  // |inline_id_to_token_pos| because it is not (currently) inlined into
  // another graph at a given token position. A side effect of this is that
  // the length of |inline_id_to_function| and |caller_inline_id| is always
  // larger than the length of |inline_id_to_token_pos| by one.
}

CompilerPass* CompilerPass::passes_[CompilerPass::kNumPasses] = {NULL};

DEFINE_OPTION_HANDLER(CompilerPass::ParseFilters,
                      compiler_passes,
                      "List of comma separated compilation passes flags. "
                      "Use -Name to disable a pass, Name to print IL after it. "
                      "Do --compiler-passes=help for more information.");
DEFINE_FLAG(bool,
            early_round_trip_serialization,
            false,
            "Perform early round trip serialization compiler pass.");
DEFINE_FLAG(bool,
            late_round_trip_serialization,
            false,
            "Perform late round trip serialization compiler pass.");
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);

void CompilerPassState::set_flow_graph(FlowGraph* flow_graph) {
  flow_graph_ = flow_graph;
  if (call_specializer != nullptr) {
    call_specializer->set_flow_graph(flow_graph);
  }
}

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

  // Clear all flags.
  for (intptr_t i = 0; i < kNumPasses; i++) {
    if (passes_[i] != NULL) {
      passes_[i]->flags_ = 0;
    }
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
      TIMELINE_DURATION(thread, CompilerVerbose, name());
      repeat = DoBody(state);
      thread->CheckForSafepoint();
    }
    PrintGraph(state, kTraceAfter, round);
#if defined(DEBUG)
    FlowGraphChecker(state->flow_graph(), state->inline_id_to_function)
        .Check(name());
#endif
  }
}

void CompilerPass::PrintGraph(CompilerPassState* state,
                              Flag mask,
                              intptr_t round) const {
  const intptr_t current_flags = flags() | state->sticky_flags;
  FlowGraph* flow_graph = state->flow_graph();

  if ((FLAG_print_flow_graph || FLAG_print_flow_graph_optimized) &&
      flow_graph->should_print() && ((current_flags & mask) != 0)) {
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

#if defined(DART_PRECOMPILER)
#define INVOKE_PASS_AOT(Name)                                                  \
  if (mode == kAOT) {                                                          \
    INVOKE_PASS(Name);                                                         \
  }
#else
#define INVOKE_PASS_AOT(Name)
#endif

void CompilerPass::RunGraphIntrinsicPipeline(CompilerPassState* pass_state) {
  INVOKE_PASS(AllocateRegistersForGraphIntrinsic);
}

void CompilerPass::RunInliningPipeline(PipelineMode mode,
                                       CompilerPassState* pass_state) {
  INVOKE_PASS(ApplyClassIds);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyICData);
  INVOKE_PASS(Canonicalize);
  // Run constant propagation to make sure we specialize for
  // (optional) constant arguments passed into the inlined method.
  INVOKE_PASS(ConstantPropagation);
  // Constant propagation removes unreachable basic blocks and
  // may open more opportunities for call specialization.
  // Call specialization during inlining may cause more call
  // sites to be discovered and more functions inlined.
  INVOKE_PASS_AOT(ApplyClassIds);
  // Optimize (a << b) & c patterns, merge instructions. Must occur
  // before 'SelectRepresentations' which inserts conversion nodes.
  INVOKE_PASS(TryOptimizePatterns);
}

FlowGraph* CompilerPass::RunForceOptimizedPipeline(
    PipelineMode mode,
    CompilerPassState* pass_state) {
  INVOKE_PASS(ComputeSSA);
  if (FLAG_early_round_trip_serialization) {
    INVOKE_PASS(RoundTripSerialization);
  }
  INVOKE_PASS(SetOuterInliningId);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(BranchSimplify);
  INVOKE_PASS(IfConvert);
  INVOKE_PASS(ConstantPropagation);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(WidenSmiToInt32);
  INVOKE_PASS(SelectRepresentations);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(TryCatchOptimization);
  INVOKE_PASS(EliminateEnvironments);
  INVOKE_PASS(EliminateDeadPhis);
  // Currently DCE assumes that EliminateEnvironments has already been run,
  // so it should not be lifted earlier than that pass.
  INVOKE_PASS(DCE);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS_AOT(DelayAllocations);
  INVOKE_PASS(EliminateWriteBarriers);
  INVOKE_PASS(FinalizeGraph);
  INVOKE_PASS_AOT(SerializeGraph);
  if (FLAG_late_round_trip_serialization) {
    INVOKE_PASS(RoundTripSerialization);
  }
  INVOKE_PASS(AllocateRegisters);
  INVOKE_PASS(ReorderBlocks);
  return pass_state->flow_graph();
}

FlowGraph* CompilerPass::RunPipeline(PipelineMode mode,
                                     CompilerPassState* pass_state) {
  INVOKE_PASS(ComputeSSA);
  if (FLAG_early_round_trip_serialization) {
    INVOKE_PASS(RoundTripSerialization);
  }
  INVOKE_PASS_AOT(ApplyClassIds);
  INVOKE_PASS_AOT(TypePropagation);
  INVOKE_PASS(ApplyICData);
  INVOKE_PASS(TryOptimizePatterns);
  INVOKE_PASS(SetOuterInliningId);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyClassIds);
  INVOKE_PASS(Inlining);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyClassIds);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(ApplyICData);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(BranchSimplify);
  INVOKE_PASS(IfConvert);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(ConstantPropagation);
  INVOKE_PASS(OptimisticallySpecializeSmiPhis);
  INVOKE_PASS(TypePropagation);
  // The extra call specialization pass in AOT is able to specialize more
  // calls after ConstantPropagation, which removes unreachable code, and
  // TypePropagation, which can infer more accurate types after removing
  // unreachable code.
  INVOKE_PASS_AOT(ApplyICData);
  INVOKE_PASS_AOT(OptimizeTypedDataAccesses);
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
  // Currently DCE assumes that EliminateEnvironments has already been run,
  // so it should not be lifted earlier than that pass.
  INVOKE_PASS(DCE);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS_AOT(DelayAllocations);
  // Repeat branches optimization after DCE, as it could make more
  // empty blocks.
  INVOKE_PASS(OptimizeBranches);
  INVOKE_PASS(AllocationSinking_Sink);
  INVOKE_PASS(EliminateDeadPhis);
  INVOKE_PASS(DCE);
  INVOKE_PASS(TypePropagation);
  INVOKE_PASS(SelectRepresentations);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(UseTableDispatch);
  INVOKE_PASS(EliminateStackOverflowChecks);
  INVOKE_PASS(Canonicalize);
  INVOKE_PASS(AllocationSinking_DetachMaterializations);
  INVOKE_PASS(EliminateWriteBarriers);
  INVOKE_PASS(FinalizeGraph);
  // If we are serializing the flow graph, do it now before we start
  // doing register allocation.
  INVOKE_PASS_AOT(SerializeGraph);
  if (FLAG_late_round_trip_serialization) {
    INVOKE_PASS(RoundTripSerialization);
  }
  INVOKE_PASS(AllocateRegisters);
  INVOKE_PASS(ReorderBlocks);
  return pass_state->flow_graph();
}

FlowGraph* CompilerPass::RunPipelineWithPasses(
    CompilerPassState* state,
    std::initializer_list<CompilerPass::Id> passes) {
  for (auto pass_id : passes) {
    passes_[pass_id]->Run(state);
  }
  return state->flow_graph();
}

COMPILER_PASS(ComputeSSA, {
  // Transform to SSA (virtual register 0 and no inlining arguments).
  flow_graph->ComputeSSA(0, NULL);
});

COMPILER_PASS(ApplyICData, { state->call_specializer->ApplyICData(); });

COMPILER_PASS(TryOptimizePatterns, { flow_graph->TryOptimizePatterns(); });

COMPILER_PASS(SetOuterInliningId,
              { FlowGraphInliner::SetInliningId(flow_graph, 0); });

COMPILER_PASS(Inlining, {
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

COMPILER_PASS(UseTableDispatch, {
  if (FLAG_use_bare_instructions && FLAG_use_table_dispatch) {
    state->call_specializer->ReplaceInstanceCallsWithDispatchTableCalls();
  }
});

COMPILER_PASS_REPEAT(CSE, { return DominatorBasedCSE::Optimize(flow_graph); });

COMPILER_PASS(LICM, {
  flow_graph->RenameUsesDominatedByRedefinitions();
  DEBUG_ASSERT(flow_graph->VerifyRedefinitions());
  LICM licm(flow_graph);
  licm.Optimize();
  flow_graph->RemoveRedefinitions(/*keep_checks*/ true);
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

COMPILER_PASS(OptimizeTypedDataAccesses,
              { TypedDataSpecializer::Optimize(flow_graph); });

COMPILER_PASS(TryCatchOptimization, {
  OptimizeCatchEntryStates(flow_graph,
                           /*is_aot=*/CompilerState::Current().is_aot());
});

COMPILER_PASS(EliminateEnvironments, { flow_graph->EliminateEnvironments(); });

COMPILER_PASS(EliminateDeadPhis,
              { DeadCodeElimination::EliminateDeadPhis(flow_graph); });

COMPILER_PASS(DCE, { DeadCodeElimination::EliminateDeadCode(flow_graph); });

COMPILER_PASS(DelayAllocations, { DelayAllocations::Optimize(flow_graph); });

COMPILER_PASS(AllocationSinking_Sink, {
  // TODO(vegorov): Support allocation sinking with try-catch.
  if (flow_graph->graph_entry()->catch_entries().is_empty()) {
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
  flow_graph->InsertPushArguments();
  // Ensure loop hierarchy has been computed.
  flow_graph->GetLoopHierarchy();
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*flow_graph);
  allocator.AllocateRegisters();
});

COMPILER_PASS(AllocateRegistersForGraphIntrinsic, {
  // Ensure loop hierarchy has been computed.
  flow_graph->GetLoopHierarchy();
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*flow_graph, /*intrinsic_mode=*/true);
  allocator.AllocateRegisters();
});

COMPILER_PASS(ReorderBlocks, {
  if (state->reorder_blocks) {
    BlockScheduler::ReorderBlocks(flow_graph);
  }
});

COMPILER_PASS(EliminateWriteBarriers, { EliminateWriteBarriers(flow_graph); });

COMPILER_PASS(FinalizeGraph, {
  // At the end of the pipeline, force recomputing and caching graph
  // information (instruction and call site counts) for the (assumed)
  // non-specialized case with better values, for future inlining.
  intptr_t instruction_count = 0;
  intptr_t call_site_count = 0;
  FlowGraphInliner::CollectGraphInfo(flow_graph,
                                     /*constants_count*/ 0,
                                     /*force*/ true, &instruction_count,
                                     &call_site_count);
  flow_graph->function().set_inlining_depth(state->inlining_depth);
  // Remove redefinitions for the rest of the pipeline.
  flow_graph->RemoveRedefinitions();
});

#if defined(DART_PRECOMPILER)
COMPILER_PASS(SerializeGraph, {
  if (state->precompiler == nullptr) return false;
  if (auto stream = state->precompiler->il_serialization_stream()) {
    auto file_write = Dart::file_write_callback();
    ASSERT(file_write != nullptr);

    const intptr_t kInitialBufferSize = 1 * MB;
    TextBuffer buffer(kInitialBufferSize);
    StackZone stack_zone(Thread::Current());
    FlowGraphSerializer::SerializeToBuffer(stack_zone.GetZone(), flow_graph,
                                           &buffer);

    file_write(buffer.buffer(), buffer.length(), stream);
  }
});
#endif

COMPILER_PASS(RoundTripSerialization, {
  FlowGraphDeserializer::RoundTripSerialization(state);
  ASSERT(state->flow_graph() != nullptr);
})

}  // namespace dart
