// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_INLINER_H_
#define RUNTIME_VM_COMPILER_BACKEND_INLINER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

class Definition;
class Field;
class FlowGraph;
class ForwardInstructionIterator;
class Function;
class ICData;
class InstanceCallInstr;
class Instruction;
class Precompiler;
class StaticCallInstr;
class TargetEntryInstr;

class SpeculativeInliningPolicy {
 public:
  explicit SpeculativeInliningPolicy(bool enable_blacklist, intptr_t limit = -1)
      : enable_blacklist_(enable_blacklist), remaining_(limit) {}

  bool AllowsSpeculativeInlining() const {
    return !enable_blacklist_ || remaining_ > 0;
  }

  bool IsAllowedForInlining(intptr_t call_deopt_id) const {
    // If we are not blacklisting, we always enable optimistic inlining.
    if (!enable_blacklist_) {
      return true;
    }

    // If we have already blacklisted the deopt-id we don't allow inlining it.
    if (IsBlacklisted(call_deopt_id)) {
      return false;
    }

    // Allow it if we can bailout at least one more time.
    return remaining_ > 0;
  }

  bool AddBlockedDeoptId(intptr_t id) {
    ASSERT(enable_blacklist_);
#if defined(DEBUG)
    ASSERT(!IsBlacklisted(id));
#endif

    // If we exhausted the number of blacklist entries there is no point
    // in adding entries to the blacklist.
    if (remaining_ <= 0) return false;

    inlining_blacklist_.Add(id);
    remaining_ -= 1;
    return true;
  }

  intptr_t length() const { return inlining_blacklist_.length(); }

 private:
  bool IsBlacklisted(intptr_t id) const {
    for (intptr_t i = 0; i < inlining_blacklist_.length(); ++i) {
      if (inlining_blacklist_[i] != id) return true;
    }
    return false;
  }

  // Whether we enable blacklisting deopt-ids.
  const bool enable_blacklist_;

  // After we reach [remaining_] number of deopt-ids in [inlining_blacklist_]
  // in the black list, we'll disable speculative inlining entirely.
  intptr_t remaining_;
  GrowableArray<intptr_t> inlining_blacklist_;
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

  // Compute graph info if it was not already computed or if 'force' is true.
  static void CollectGraphInfo(FlowGraph* flow_graph, bool force = false);
  static void SetInliningId(FlowGraph* flow_graph, intptr_t inlining_id);

  bool AlwaysInline(const Function& function);

  FlowGraph* flow_graph() const { return flow_graph_; }
  intptr_t NextInlineId(const Function& function,
                        TokenPosition tp,
                        intptr_t caller_id);

  bool trace_inlining() const { return trace_inlining_; }

  SpeculativeInliningPolicy* speculative_policy() {
    return speculative_policy_;
  }

  static bool TryReplaceInstanceCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      InstanceCallInstr* call);

  static bool TryReplaceStaticCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      StaticCallInstr* call);

  static bool TryInlineRecognizedMethod(FlowGraph* flow_graph,
                                        intptr_t receiver_cid,
                                        const Function& target,
                                        Definition* call,
                                        Definition* receiver,
                                        TokenPosition token_pos,
                                        const ICData& ic_data,
                                        TargetEntryInstr** entry,
                                        Definition** last);

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
