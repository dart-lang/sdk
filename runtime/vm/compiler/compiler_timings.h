// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_TIMINGS_H_
#define RUNTIME_VM_COMPILER_COMPILER_TIMINGS_H_

#include <memory>

#include "platform/allocation.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/thread.h"
#include "vm/timer.h"

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#define PRECOMPILER_TIMERS_LIST(V)                                             \
  V(CompileAll)                                                                \
  V(Iterate)                                                                   \
  V(CompileFunction)                                                           \
  V(AddCalleesOf)                                                              \
  V(CheckForNewDynamicFunctions)                                               \
  V(CollectCallbackFields)                                                     \
  V(PrecompileConstructors)                                                    \
  V(AttachOptimizedTypeTestingStub)                                            \
  V(TraceForRetainedFunctions)                                                 \
  V(FinalizeDispatchTable)                                                     \
  V(ReplaceFunctionStaticCallEntries)                                          \
  V(Drop)                                                                      \
  V(Obfuscate)                                                                 \
  V(Dedup)                                                                     \
  V(SymbolsCompact)

#define INLINING_TIMERS_LIST(V)                                                \
  V(CollectGraphInfo)                                                          \
  V(PopulateWithICData)                                                        \
  V(FindCallSites)                                                             \
  V(SetInliningId)                                                             \
  V(MakeInliningDecision)                                                      \
  V(CheckForPragma)                                                            \
  V(InlineCall)                                                                \
  V(InlineRecognizedMethod)                                                    \
  V(DiscoverBlocks)                                                            \
  V(BuildDecisionGraph)                                                        \
  V(PrepareGraphs)

// Note: COMPILER_PASS_LIST must be the first element of the list below because
// we expect that pass ids are the same as ids of corresponding timers.
#define COMPILER_TIMERS_LIST(V)                                                \
  COMPILER_PASS_LIST(V)                                                        \
  PRECOMPILER_TIMERS_LIST(V)                                                   \
  INLINING_TIMERS_LIST(V)                                                      \
  V(BuildGraph)                                                                \
  V(EmitCode)                                                                  \
  V(FinalizeCode)

namespace dart {

// |CompilerTimings| provides a way to track time taken by various compiler
// passes via a fixed number of timers (specified in |COMPILER_TIMERS_LIST|).
//
// It supports arbitrary nesting of timers e.g. if |DiscoverBlocks| is invoked
// within two different compiler passes like |IfConvert| and |BranchSimplify|
// then |CompilerTimings| will separate these two invocations and measure each
// separately.
class CompilerTimings : public MallocAllocated {
 private:
#define INC(Name) +1
  static constexpr intptr_t kNumTimers = 0 COMPILER_TIMERS_LIST(INC);
#undef INC

  struct Timers : public MallocAllocated {
    Timer timers_[kNumTimers];
    std::unique_ptr<Timers> nested_[kNumTimers];
  };

 public:
  enum TimerId {
#define DECLARE_TIMER_ID(Name) k##Name,
    COMPILER_TIMERS_LIST(DECLARE_TIMER_ID)
#undef DECLARE_TIMER_ID
  };

  // Timing scope which starts and stop the timer with the given |id|.
  class Scope : public StackResource {
   public:
    Scope(Thread* thread, TimerId id)
        : StackResource(thread), stats_(thread->compiler_timings()) {
      if (stats_ != nullptr) {
        outer_nested_ = stats_->nested_;
        if (*outer_nested_ == nullptr) {
          // Created array of nested timers if we don't have one yet.
          *outer_nested_ = std::make_unique<Timers>();
        }

        timer_ = &(*outer_nested_)->timers_[id];
        stats_->nested_ = &(*outer_nested_)->nested_[id];

        timer_->Start();
      }
    }

    ~Scope() {
      if (stats_ != nullptr) {
        timer_->Stop();
        stats_->nested_ = outer_nested_;
      }
    }

   private:
    CompilerTimings* const stats_;
    Timer* timer_;
    std::unique_ptr<Timers>* outer_nested_;
  };

  CompilerTimings() { total_.Start(); }

  void RecordInliningStatsByOutcome(bool success, const Timer& timer) {
    if (success) {
      try_inlining_success_.AddTotal(timer);
    } else {
      try_inlining_failure_.AddTotal(timer);
    }
  }

  void Print();

 private:
  void PrintTimers(Zone* zone,
                   const std::unique_ptr<CompilerTimings::Timers>& timers,
                   const Timer& total,
                   intptr_t level);

  Timer total_;
  std::unique_ptr<Timers> root_ = std::make_unique<Timers>();

  // Timers nested under the currently running timer(s).
  std::unique_ptr<Timers>* nested_ = &root_;

  Timer try_inlining_success_;
  Timer try_inlining_failure_;
};

#define TIMER_SCOPE_NAME2(counter) timer_scope_##counter
#define TIMER_SCOPE_NAME(counter) TIMER_SCOPE_NAME2(counter)

#define COMPILER_TIMINGS_TIMER_SCOPE(thread, timer_id)                         \
  CompilerTimings::Scope TIMER_SCOPE_NAME(__COUNTER__)(                        \
      thread, CompilerTimings::k##timer_id)

#define COMPILER_TIMINGS_PASS_TIMER_SCOPE(thread, pass_id)                     \
  CompilerTimings::Scope TIMER_SCOPE_NAME(__COUNTER__)(                        \
      thread, static_cast<CompilerTimings::TimerId>(pass_id))

#define PRECOMPILER_TIMER_SCOPE(precompiler, timer_id)                         \
  CompilerTimings::Scope TIMER_SCOPE_NAME(__COUNTER__)(                        \
      (precompiler)->thread(), CompilerTimings::k##timer_id)

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_COMPILER_TIMINGS_H_
