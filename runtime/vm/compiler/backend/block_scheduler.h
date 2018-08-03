// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_
#define RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_

#include "vm/allocation.h"

namespace dart {

class FlowGraph;

class BlockScheduler : public ValueObject {
 public:
  explicit BlockScheduler(FlowGraph* flow_graph) : flow_graph_(flow_graph) {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  void AssignEdgeWeights() const;

  void ReorderBlocks() const;

 private:
  FlowGraph* const flow_graph_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_
