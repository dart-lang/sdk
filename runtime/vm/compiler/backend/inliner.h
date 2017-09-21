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

class FlowGraphInliner : ValueObject {
 public:
  FlowGraphInliner(FlowGraph* flow_graph,
                   GrowableArray<const Function*>* inline_id_to_function,
                   GrowableArray<TokenPosition>* inline_id_to_token_pos,
                   GrowableArray<intptr_t>* caller_inline_id,
                   bool use_speculative_inlining,
                   GrowableArray<intptr_t>* inlining_black_list,
                   Precompiler* precompiler);

  // The flow graph is destructively updated upon inlining.
  void Inline();

  // Compute graph info if it was not already computed or if 'force' is true.
  static void CollectGraphInfo(FlowGraph* flow_graph, bool force = false);
  static void SetInliningId(FlowGraph* flow_graph, intptr_t inlining_id);

  bool AlwaysInline(const Function& function);

  FlowGraph* flow_graph() const { return flow_graph_; }
  intptr_t NextInlineId(const Function& function,
                        TokenPosition tp,
                        intptr_t caller_id);

  bool trace_inlining() const { return trace_inlining_; }

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

  bool use_speculative_inlining() const { return use_speculative_inlining_; }

 private:
  friend class CallSiteInliner;

  FlowGraph* flow_graph_;
  GrowableArray<const Function*>* inline_id_to_function_;
  GrowableArray<TokenPosition>* inline_id_to_token_pos_;
  GrowableArray<intptr_t>* caller_inline_id_;
  const bool trace_inlining_;
  const bool use_speculative_inlining_;
  GrowableArray<intptr_t>* inlining_black_list_;
  Precompiler* precompiler_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphInliner);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_INLINER_H_
