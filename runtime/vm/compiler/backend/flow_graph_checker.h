// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_
#define RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DEBUG)

namespace dart {

// Forward.
class FlowGraph;
class BlockEntryInstr;

// Class responsible for performing sanity checks on the flow graph.
// The intended use is running the checks after each compiler pass
// in debug mode in order to detect graph inconsistencies as soon
// as possible. This way, culprit passes are more easily identified.
//
// All important assumptions on the flow graph structure that can be
// verified in reasonable time should be made explicit in this pass
// so that we no longer rely on asserts that are dispersed throughout
// the passes or, worse, unwritten assumptions once agreed upon but
// so easily forgotten. Since the graph checker runs only in debug
// mode, it is acceptable to perform slightly elaborate tests.
class FlowGraphChecker {
 public:
  explicit FlowGraphChecker(FlowGraph* flow_graph);

  // Performs a sanity check on the flow graph.
  void Check();

 private:
  void CheckBasicBlocks();
  void CheckInstructions(BlockEntryInstr* block);

  FlowGraph* const flow_graph_;
};

}  // namespace dart

#endif  // defined(DEBUG)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#endif  // RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_
