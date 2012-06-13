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

  virtual void VisitStaticCall(StaticCallComp* comp);
  virtual void VisitInstanceCall(InstanceCallComp* comp);
  virtual void VisitInstanceSetter(InstanceSetterComp* comp);
  virtual void VisitLoadIndexed(LoadIndexedComp* comp);
  virtual void VisitStoreIndexed(StoreIndexedComp* comp);
  virtual void VisitRelationalOp(RelationalOpComp* comp);

  virtual void VisitStrictCompareComp(StrictCompareComp* comp);
  virtual void VisitEqualityCompare(EqualityCompareComp* comp);

  virtual void VisitDo(DoInstr* instr);
  virtual void VisitBind(BindInstr* instr);

 private:
  void VisitBlocks();

  void TryReplaceWithBinaryOp(InstanceCallComp* comp, Token::Kind op_kind);
  void TryReplaceWithUnaryOp(InstanceCallComp* comp, Token::Kind op_kind);

  void TryInlineInstanceGetter(InstanceCallComp* comp);
  void TryInlineInstanceSetter(InstanceSetterComp* comp);

  void TryInlineInstanceMethod(InstanceCallComp* comp);

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
