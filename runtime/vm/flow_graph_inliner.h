// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_INLINER_H_
#define VM_FLOW_GRAPH_INLINER_H_

#include "vm/allocation.h"

namespace dart {

class Field;
class FlowGraph;
template <typename T> class GrowableArray;

class FlowGraphInliner : ValueObject {
 public:
  FlowGraphInliner(FlowGraph* flow_graph, GrowableArray<Field*>* guarded_fields)
      : flow_graph_(flow_graph), guarded_fields_(guarded_fields) {}

  // The flow graph is destructively updated upon inlining.
  void Inline();

  static void CollectGraphInfo(FlowGraph* flow_graph);

 private:
  FlowGraph* flow_graph_;
  GrowableArray<Field*>* guarded_fields_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphInliner);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_INLINER_H_
