// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_INLINER_H_
#define VM_FLOW_GRAPH_INLINER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

class Field;
class FlowGraph;
class Function;

class FlowGraphInliner : ValueObject {
 public:
  FlowGraphInliner(FlowGraph* flow_graph,
                   GrowableArray<const Function*>* inline_id_to_function,
                   GrowableArray<intptr_t>* caller_inline_id);

  // The flow graph is destructively updated upon inlining.
  void Inline();

  // Compute graph info if it was not already computed or if 'force' is true.
  static void CollectGraphInfo(FlowGraph* flow_graph, bool force = false);
  static void SetInliningId(FlowGraph* flow_graph, intptr_t inlining_id);

  bool AlwaysInline(const Function& function);

  FlowGraph* flow_graph() const { return flow_graph_; }
  intptr_t NextInlineId(const Function& function, intptr_t caller_id);

  bool trace_inlining() const { return trace_inlining_; }

 private:
  friend class CallSiteInliner;

  FlowGraph* flow_graph_;
  GrowableArray<const Function*>* inline_id_to_function_;
  GrowableArray<intptr_t>* caller_inline_id_;
  const bool trace_inlining_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphInliner);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_INLINER_H_
