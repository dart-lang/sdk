// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_PASS_H_
#define RUNTIME_VM_COMPILER_COMPILER_PASS_H_

#ifndef DART_PRECOMPILED_RUNTIME

#include "vm/growable_array.h"
#include "vm/token_position.h"
#include "vm/zone.h"

namespace dart {

#define COMPILER_PASS_LIST(V)                                                  \
  V(AllocateRegisters)                                                         \
  V(AllocationSinking_DetachMaterializations)                                  \
  V(AllocationSinking_Sink)                                                    \
  V(ApplyClassIds)                                                             \
  V(ApplyICData)                                                               \
  V(BranchSimplify)                                                            \
  V(CSE)                                                                       \
  V(Canonicalize)                                                              \
  V(ComputeSSA)                                                                \
  V(ConstantPropagation)                                                       \
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
  V(RangeAnalysis)                                                             \
  V(ReorderBlocks)                                                             \
  V(ReplaceArrayBoundChecksForAOT)                                             \
  V(SelectRepresentations)                                                     \
  V(SetOuterInliningId)                                                        \
  V(TryCatchOptimization)                                                      \
  V(TryOptimizePatterns)                                                       \
  V(TypePropagation)                                                           \
  V(WidenSmiToInt32)

class AllocationSinking;
class BlockScheduler;
class CallSpecializer;
class FlowGraph;
class Function;
class Precompiler;
class SpeculativeInliningPolicy;

struct CompilerPassState {
  CompilerPassState(Thread* thread,
                    FlowGraph* flow_graph,
                    SpeculativeInliningPolicy* speculative_policy,
                    Precompiler* precompiler = NULL)
      : thread(thread),
        flow_graph(flow_graph),
        precompiler(precompiler),
        inlining_depth(0),
        sinking(NULL),
#ifndef PRODUCT
        compiler_timeline(NULL),
#endif
        call_specializer(NULL),
        speculative_policy(speculative_policy),
        reorder_blocks(false),
        block_scheduler(NULL),
        sticky_flags(0) {
  }

  Thread* const thread;
  FlowGraph* const flow_graph;
  Precompiler* const precompiler;
  int inlining_depth;
  AllocationSinking* sinking;

  NOT_IN_PRODUCT(TimelineStream* compiler_timeline);

  // Maps inline_id_to_function[inline_id] -> function. Top scope
  // function has inline_id 0. The map is populated by the inliner.
  GrowableArray<const Function*> inline_id_to_function;
  // Token position where inlining occured.
  GrowableArray<TokenPosition> inline_id_to_token_pos;
  // For a given inlining-id(index) specifies the caller's inlining-id.
  GrowableArray<intptr_t> caller_inline_id;

  CallSpecializer* call_specializer;

  SpeculativeInliningPolicy* speculative_policy;

  bool reorder_blocks;
  BlockScheduler* block_scheduler;

  intptr_t sticky_flags;
};

class CompilerPass {
 public:
  enum Id {
#define DEF(name) k##name,
    COMPILER_PASS_LIST(DEF)
#undef DEF
  };

#define ADD_ONE(name) +1
  static const intptr_t kNumPasses = 0 COMPILER_PASS_LIST(ADD_ONE);
#undef ADD_ONE

  CompilerPass(Id id, const char* name) : name_(name), flags_(0) {
    ASSERT(passes_[id] == NULL);
    passes_[id] = this;
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

  intptr_t flags() const { return flags_; }
  const char* name() const { return name_; }

  bool IsFlagSet(Flag flag) const { return (flags() & flag) != 0; }

  static CompilerPass* Get(Id id) { return passes_[id]; }

  static void ParseFilters(const char* filter);

  enum PipelineMode { kJIT, kAOT };

  static void RunPipeline(PipelineMode mode, CompilerPassState* state);

 protected:
  // This function executes the pass. If it returns true then
  // we will run Canonicalize on the graph and execute the pass
  // again.
  virtual bool DoBody(CompilerPassState* state) const = 0;

 private:
  static CompilerPass* FindPassByName(const char* name) {
    for (intptr_t i = 0; i < kNumPasses; i++) {
      if ((passes_[i] != NULL) && (strcmp(passes_[i]->name_, name) == 0)) {
        return passes_[i];
      }
    }
    return NULL;
  }

  void PrintGraph(CompilerPassState* state, Flag mask, intptr_t round) const;

  static CompilerPass* passes_[];

  const char* name_;
  intptr_t flags_;
};

}  // namespace dart

#endif

#endif  // RUNTIME_VM_COMPILER_COMPILER_PASS_H_
