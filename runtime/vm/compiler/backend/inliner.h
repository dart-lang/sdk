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

class FlowGraphInliner : ValueObject {
 public:
  FlowGraphInliner(FlowGraph* flow_graph,
                   GrowableArray<const Function*>* inline_id_to_function,
                   GrowableArray<TokenPosition>* inline_id_to_token_pos,
                   GrowableArray<intptr_t>* caller_inline_id,
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

  static void SetInliningIdAndTryIndex(FlowGraph* flow_graph,
                                       intptr_t inlining_id,
                                       intptr_t caller_try_index);

  bool AlwaysInline(const Function& function);

  static bool FunctionHasPreferInlinePragma(const Function& function);
  static bool FunctionHasNeverInlinePragma(const Function& function);
  static bool FunctionHasAlwaysConsiderInliningPragma(const Function& function);

  FlowGraph* flow_graph() const { return flow_graph_; }
  intptr_t NextInlineId(const Function& function,
                        const InstructionSource& source);

  bool trace_inlining() const { return trace_inlining_; }

 private:
  friend class CallSiteInliner;

  FlowGraph* flow_graph_;
  GrowableArray<const Function*>* inline_id_to_function_;
  GrowableArray<TokenPosition>* inline_id_to_token_pos_;
  GrowableArray<intptr_t>* caller_inline_id_;
  const bool trace_inlining_;
  Precompiler* precompiler_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphInliner);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_INLINER_H_
