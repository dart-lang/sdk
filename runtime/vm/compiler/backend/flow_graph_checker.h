// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_
#define RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DEBUG)

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

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
class FlowGraphChecker : public FlowGraphVisitor {
 public:
  // Constructs graph checker. The checker uses some custom-made
  // visitation to perform additional checks, and uses the
  // FlowGraphVisitor structure for anything else.
  FlowGraphChecker(FlowGraph* flow_graph,
                   const GrowableArray<const Function*>& inline_id_to_function)
      : FlowGraphVisitor(flow_graph->preorder()),
        flow_graph_(flow_graph),
        inline_id_to_function_(inline_id_to_function),
        script_(Script::Handle(flow_graph_->zone())),
        current_block_(nullptr) {}

  // Performs a sanity check on the flow graph.
  void Check(const char* pass_name);

 private:
  // Custom-made visitors.
  void VisitBlocks() override;
  void VisitInstructions(BlockEntryInstr* block);
  void VisitInstruction(Instruction* instruction);
  void VisitDefinition(Definition* def);
  void VisitUseDef(Instruction* instruction,
                   Value* use,
                   intptr_t index,
                   bool is_env);
  void VisitDefUse(Definition* def, Value* use, Value* prev, bool is_env);

  // Instruction visitors.
  void VisitConstant(ConstantInstr* constant) override;
  void VisitPhi(PhiInstr* phi) override;
  void VisitGoto(GotoInstr* jmp) override;
  void VisitIndirectGoto(IndirectGotoInstr* jmp) override;
  void VisitBranch(BranchInstr* branch) override;
  void VisitRedefinition(RedefinitionInstr* def) override;
  void VisitClosureCall(ClosureCallInstr* call) override;
  void VisitStaticCall(StaticCallInstr* call) override;
  void VisitInstanceCall(InstanceCallInstr* call) override;
  void VisitPolymorphicInstanceCall(
      PolymorphicInstanceCallInstr* call) override;

  FlowGraph* const flow_graph_;
  const GrowableArray<const Function*>& inline_id_to_function_;
  Script& script_;
  BlockEntryInstr* current_block_;
};

}  // namespace dart

#endif  // defined(DEBUG)

#endif  // RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_CHECKER_H_
