// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class StreamingFlowGraphBuilder {
 public:
  StreamingFlowGraphBuilder(FlowGraphBuilder* flowGraph_builder,
                            const uint8_t* buffer,
                            intptr_t buffer_length)
      : flow_graph_builder_(flowGraph_builder),
        reader_(new kernel::Reader(buffer, buffer_length)) {}

  virtual ~StreamingFlowGraphBuilder() { delete reader_; }

  Fragment BuildAt(intptr_t kernel_offset);

 private:
  TokenPosition ReadPosition(bool record = true);

  CatchBlock* catch_block();

  Fragment DebugStepCheck(TokenPosition position);
  Fragment LoadLocal(LocalVariable* variable);
  Fragment PushArgument();
  Fragment RethrowException(TokenPosition position, int catch_try_index);

  Fragment BuildRethrow();

  FlowGraphBuilder* flow_graph_builder_;
  kernel::Reader* reader_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
