// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_ALLOCATOR_H_
#define VM_FLOW_GRAPH_ALLOCATOR_H_

#include "vm/growable_array.h"
#include "vm/intermediate_language.h"

namespace dart {

class FlowGraphAllocator : public ValueObject {
 public:
  explicit FlowGraphAllocator(const GrowableArray<BlockEntryInstr*>& blocks)
      : blocks_(blocks) { }

  void ResolveConstraints();

 private:
  const GrowableArray<BlockEntryInstr*>& blocks_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphAllocator);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_ALLOCATOR_H_
