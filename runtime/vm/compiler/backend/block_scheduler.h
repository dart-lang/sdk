// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_
#define RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"

namespace dart {

class FlowGraph;

class BlockScheduler : public AllStatic {
 public:
  static void AssignEdgeWeights(FlowGraph* flow_graph);
  static void ReorderBlocks(FlowGraph* flow_graph);

 private:
  static void ReorderBlocksAOT(FlowGraph* flow_graph);
  static void ReorderBlocksJIT(FlowGraph* flow_graph);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_BLOCK_SCHEDULER_H_
