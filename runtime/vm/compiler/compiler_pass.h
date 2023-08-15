// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_PASS_H_
#define RUNTIME_VM_COMPILER_COMPILER_PASS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <initializer_list>

#include "vm/growable_array.h"
#include "vm/timer.h"
#include "vm/token_position.h"
#include "vm/zone.h"

namespace dart {

#define COMPILER_PASS_LIST(V)                                                  \
  V(AllocateRegisters)                                                         \
  V(AllocateRegistersForGraphIntrinsic)                                        \
  V(AllocationSinking_DetachMaterializations)                                  \
  V(AllocationSinking_Sink)                                                    \
  V(ApplyClassIds)                                                             \
  V(ApplyICData)                                                               \
  V(BranchSimplify)                                                            \
  V(CSE)                                                                       \
  V(Canonicalize)                                                              \
  V(ComputeSSA)                                                                \
  V(ConstantPropagation)                                                       \
  V(DCE)                                                                       \
  V(DelayAllocations)                                                          \
  V(DSE)                                                                       \
  V(EliminateDeadPhis)                                                         \
  V(EliminateEnvironments)                                                     \
  V(EliminateStackOverflowChecks)                                              \
  V(FinalizeGraph)                                                             \
  V(IfConvert)                                                                 \
  V(Inlining)                                                                  \
  V(LICM)                                                                      \
  V(OptimisticallySpecializeSmiPhis)                                           \
  V(OptimizeBranches)                                                          \
  V(OptimizeTypedDataAccesses)                                                 \
  V(RangeAnalysis)                                                             \
  V(ReorderBlocks)                                                             \
  V(SelectRepresentations)                                                     \
  V(SelectRepresentations_Final)                                               \
  V(SetOuterInliningId)                                                        \
  V(TryCatchOptimization)                                                      \
  V(TryOptimizePatterns)                                                       \
  V(TypePropagation)                                                           \
  V(UseTableDispatch)                                                          \
  V(WidenSmiToInt32)                                                           \
  V(EliminateWriteBarriers)                                                    \
  V(GenerateCode)

class AllocationSinking;
class BlockScheduler;
class CallSpecializer;
class FlowGraph;
class FlowGraphCompiler;
class Function;
class Precompiler;
class SpeculativeInliningPolicy;
class TimelineStream;
class Thread;

struct CompilerPassState {
  CompilerPassState(Thread* thread,
                    FlowGraph* flow_graph,
                    SpeculativeInliningPolicy* speculative_policy,
                    Precompiler* precompiler = nullptr);

  FlowGraph* flow_graph() const { return flow_graph_; }

  void set_flow_graph(FlowGraph* flow_graph);

  Thread* const thread;
  Precompiler* const precompiler;
  int inlining_depth;
  AllocationSinking* sinking;

  // Maps inline_id_to_function[inline_id] -> function. Top scope
  // function has inline_id 0. The map is populated by the inliner.
  GrowableArray<const Function*> inline_id_to_function;
  // Token position where inlining occurred.
  GrowableArray<TokenPosition> inline_id_to_token_pos;
  // For a given inlining-id(index) specifies the caller's inlining-id.
  GrowableArray<intptr_t> caller_inline_id;

  CallSpecializer* call_specializer;

  SpeculativeInliningPolicy* speculative_policy;

  bool reorder_blocks;

  intptr_t sticky_flags;

  FlowGraphCompiler* graph_compiler = nullptr;

 private:
  FlowGraph* flow_graph_;
};

class CompilerPass {
 public:
  enum Id {
#define DEF(name) k##name,
    COMPILER_PASS_LIST(DEF)
#undef DEF
  };

#define ADD_ONE(name) +1
  static constexpr intptr_t kNumPasses = 0 COMPILER_PASS_LIST(ADD_ONE);
#undef ADD_ONE

  CompilerPass(Id id, const char* name) : id_(id), name_(name) {
    ASSERT(passes_[id] == nullptr);
    passes_[id] = this;

    // By default print the final flow-graph after the register allocation.
    if (id == kAllocateRegisters) {
      flags_[id] = kTraceAfter;
    } else {
      flags_[id] = 0;
    }
  }
  virtual ~CompilerPass() {}

  enum Flag {
    kDisabled = 1 << 0,
    kTraceBefore = 1 << 1,
    kTraceAfter = 1 << 2,
    kSticky = 1 << 3,
    kTraceBeforeOrAfter = kTraceBefore | kTraceAfter,
  };

  void Run(CompilerPassState* state) const;

  uint8_t flags() const { return flags_[id()]; }
  const char* name() const { return name_; }
  Id id() const { return id_; }

  static CompilerPass* Get(Id id) { return passes_[id]; }

  static void ParseFiltersFromFlag(const char* filter);
  static uint8_t* ParseFiltersFromPragma(const char* filter);
  static void ParseFilters(const char* filter, uint8_t* flags);
  static void ParseOneFilter(const char* start,
                             const char* end,
                             uint8_t* flags);

  enum PipelineMode { kJIT, kAOT };

  static void GenerateCode(CompilerPassState* state) {
    CompilerPass::Get(CompilerPass::kGenerateCode)->Run(state);
  }

  static void RunGraphIntrinsicPipeline(CompilerPassState* state);

  static void RunInliningPipeline(PipelineMode mode, CompilerPassState* state);

  static void RunForceOptimizedInliningPipeline(CompilerPassState* state);
  // RunPipeline(WithPasses) may have the side effect of changing the FlowGraph
  // stored in the CompilerPassState. However, existing callers may depend on
  // the old invariant that the FlowGraph stored in the CompilerPassState was
  // always updated, never entirely replaced.
  //
  // To make sure callers are updated properly, these methods also return
  // the final FlowGraph and we add a check that callers use this result.
  DART_WARN_UNUSED_RESULT
  static FlowGraph* RunPipeline(PipelineMode mode, CompilerPassState* state);
  DART_WARN_UNUSED_RESULT
  static FlowGraph* RunPipelineWithPasses(
      CompilerPassState* state,
      std::initializer_list<CompilerPass::Id> passes);

  // Pipeline which is used for "force-optimized" functions.
  //
  // Must not include speculative or inter-procedural optimizations.
  DART_WARN_UNUSED_RESULT
  static FlowGraph* RunForceOptimizedPipeline(PipelineMode mode,
                                              CompilerPassState* state);

 protected:
  // This function executes the pass. If it returns true then
  // we will run Canonicalize on the graph and execute the pass
  // again.
  virtual bool DoBody(CompilerPassState* state) const = 0;

 private:
  static CompilerPass* FindPassByName(const char* name) {
    for (intptr_t i = 0; i < kNumPasses; i++) {
      if ((passes_[i] != nullptr) && (strcmp(passes_[i]->name_, name) == 0)) {
        return passes_[i];
      }
    }
    return nullptr;
  }

  void PrintGraph(CompilerPassState* state, Flag mask, intptr_t round) const;

  static CompilerPass* passes_[];
  static uint8_t flags_[];

  Id id_;
  const char* name_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_COMPILER_PASS_H_
