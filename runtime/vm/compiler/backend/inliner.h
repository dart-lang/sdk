// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_INLINER_H_
#define RUNTIME_VM_COMPILER_BACKEND_INLINER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/token_position.h"

namespace dart {

class Definition;
class Field;
class FlowGraph;
class ForwardInstructionIterator;
class Function;
class FunctionEntryInstr;
class GraphEntryInstr;
class ICData;
class InstanceCallInstr;
class Instruction;
struct InstructionSource;
class Precompiler;
class StaticCallInstr;
class TargetEntryInstr;

class SpeculativeInliningPolicy {
 public:
  explicit SpeculativeInliningPolicy(bool enable_suppression,
                                     intptr_t limit = -1)
      : enable_suppression_(enable_suppression), remaining_(limit) {}

  bool AllowsSpeculativeInlining() const {
    return !enable_suppression_ || remaining_ > 0;
  }

  bool IsAllowedForInlining(intptr_t call_deopt_id) const {
    // If we are not supressing, we always enable optimistic inlining.
    if (!enable_suppression_) {
      return true;
    }

    // If we have already suppressed the deopt-id we don't allow inlining it.
    if (IsSuppressed(call_deopt_id)) {
      return false;
    }

    // Allow it if we can bailout at least one more time.
    return remaining_ > 0;
  }

  bool AddBlockedDeoptId(intptr_t id) {
    ASSERT(enable_suppression_);
#if defined(DEBUG)
    ASSERT(!IsSuppressed(id));
#endif

    // If we exhausted the number of suppression entries there is no point
    // in adding entries to the list.
    if (remaining_ <= 0) return false;

    inlining_suppressions_.Add(id);
    remaining_ -= 1;
    return true;
  }

  intptr_t length() const { return inlining_suppressions_.length(); }

 private:
  bool IsSuppressed(intptr_t id) const {
    for (intptr_t i = 0; i < inlining_suppressions_.length(); ++i) {
      if (inlining_suppressions_[i] == id) return true;
    }
    return false;
  }

  // Whether we enable supressing inlining at specific deopt-ids.
  const bool enable_suppression_;

  // After we reach [remaining_] number of deopt-ids in [inlining_suppressions_]
  // list, we'll disable speculative inlining entirely.
  intptr_t remaining_;
  GrowableArray<intptr_t> inlining_suppressions_;
};

class FlowGraphInliner : ValueObject {
 public:
  FlowGraphInliner(FlowGraph* flow_graph,
                   GrowableArray<const Function*>* inline_id_to_function,
                   GrowableArray<TokenPosition>* inline_id_to_token_pos,
                   GrowableArray<intptr_t>* caller_inline_id,
                   SpeculativeInliningPolicy* speculative_policy,
                   Precompiler* precompiler);

  // The flow graph is destructively updated upon inlining.  Returns the max
  // depth that we inlined.
  int Inline();

  // Computes graph information (instruction and call site count).
  // For the non-specialized cases (num_constants_args == 0), the
  // method uses a cache to avoid recomputing the counts (the cached
  // value may still be approximate but close). The 'force' flag is
  // used to update the cached value at the end of running the full pipeline
  // on non-specialized cases. Specialized cases (num_constants_args > 0)
  // always recompute the counts without caching.
  //
  // TODO(ajcbik): cache for specific constant argument combinations too?
  static void CollectGraphInfo(FlowGraph* flow_graph,
                               intptr_t num_constant_args,
                               bool force,
                               intptr_t* instruction_count,
                               intptr_t* call_site_count);

  static void SetInliningId(FlowGraph* flow_graph, intptr_t inlining_id);

  bool AlwaysInline(const Function& function);

  static bool FunctionHasPreferInlinePragma(const Function& function);
  static bool FunctionHasNeverInlinePragma(const Function& function);

  FlowGraph* flow_graph() const { return flow_graph_; }
  intptr_t NextInlineId(const Function& function,
                        const InstructionSource& source);

  bool trace_inlining() const { return trace_inlining_; }

  SpeculativeInliningPolicy* speculative_policy() {
    return speculative_policy_;
  }

  struct ExactnessInfo {
    const bool is_exact;
    bool emit_exactness_guard;
  };

  static bool TryReplaceInstanceCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      InstanceCallInstr* call,
      SpeculativeInliningPolicy* policy);

  static bool TryReplaceStaticCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      StaticCallInstr* call,
      SpeculativeInliningPolicy* policy);

  static bool TryInlineRecognizedMethod(FlowGraph* flow_graph,
                                        intptr_t receiver_cid,
                                        const Function& target,
                                        Definition* call,
                                        Definition* receiver,
                                        const InstructionSource& source,
                                        const ICData* ic_data,
                                        GraphEntryInstr* graph_entry,
                                        FunctionEntryInstr** entry,
                                        Instruction** last,
                                        Definition** result,
                                        SpeculativeInliningPolicy* policy,
                                        ExactnessInfo* exactness = nullptr);

 private:
  friend class CallSiteInliner;

  FlowGraph* flow_graph_;
  GrowableArray<const Function*>* inline_id_to_function_;
  GrowableArray<TokenPosition>* inline_id_to_token_pos_;
  GrowableArray<intptr_t>* caller_inline_id_;
  const bool trace_inlining_;
  SpeculativeInliningPolicy* speculative_policy_;
  Precompiler* precompiler_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphInliner);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_INLINER_H_
