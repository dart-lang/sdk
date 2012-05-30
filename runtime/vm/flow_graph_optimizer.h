// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_OPTIMIZER_H_
#define VM_FLOW_GRAPH_OPTIMIZER_H_

#include "vm/intermediate_language.h"

namespace dart {

template <typename T> class GrowableArray;

class FlowGraphOptimizer : public FlowGraphVisitor {
 public:
  explicit FlowGraphOptimizer(const GrowableArray<BlockEntryInstr*>& blocks)
      : FlowGraphVisitor(blocks) {}
  virtual ~FlowGraphOptimizer() {}

  void ApplyICData();

  virtual void VisitInstanceCall(InstanceCallComp* comp);

  virtual void VisitDo(DoInstr* instr);
  virtual void VisitBind(BindInstr* instr);

 private:
  void VisitBlocks();

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
