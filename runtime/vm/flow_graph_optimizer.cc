// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/flow_graph_builder.h"
#include "vm/il_printer.h"
#include "vm/object_store.h"

namespace dart {

DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, trace_optimization);

void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
  if (FLAG_print_flow_graph) {
    OS::Print("After Optimizations:\n");
    FlowGraphPrinter printer(Function::Handle(), block_order_);
    printer.PrintBlocks();
  }
}


void FlowGraphOptimizer::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    Instruction* instr = block_order_[i]->Accept(this);
    // Compile all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      instr = instr->Accept(this);
    }
  }
}


static bool ICDataHasTwoReceiverClasses(const ICData& ic_data,
                                        const Class& cls1,
                                        const Class& cls2) {
  ASSERT(!cls1.IsNull() && !cls2.IsNull());
  if (ic_data.num_args_tested() != 2) {
    return false;
  }
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<const Class*> classes;
    Function& target = Function::Handle();
    ic_data.GetCheckAt(i, &classes, &target);
    ASSERT(classes.length() == 2);
    if (classes[0]->raw() == cls1.raw()) {
      if (classes[1]->raw() == cls2.raw()) {
        return true;
      }
    }
  }
  return false;
}


static bool HasTwoSmi(const ICData& ic_data) {
  const Class& smi_class =
      Class::Handle(Isolate::Current()->object_store()->smi_class());
  return ICDataHasTwoReceiverClasses(ic_data, smi_class, smi_class);
}


void FlowGraphOptimizer::VisitInstanceCall(InstanceCallComp* comp) {
  if ((comp->ic_data() != NULL) && (!comp->ic_data()->IsNull())) {
    Token::Kind op_kind = Token::GetBinaryOp(comp->function_name());
    if (op_kind == Token::kILLEGAL) {
      // Not a recognized binary operation.
      return;
    }
    if (comp->ic_data()->NumberOfChecks() != 1) {
      // TODO(srdjan): Not yet supported.
      return;
    }
    if (!HasTwoSmi(*comp->ic_data())) {
      // TODO(srdjan): Not yet supported.
      return;
    }
    ASSERT(comp->instr() != NULL);
    ASSERT(comp->InputCount() == 2);
    BinaryOpComp* bin_op =
        new BinaryOpComp(op_kind, comp, comp->InputAt(0), comp->InputAt(1));
    ASSERT(bin_op->ic_data() == NULL);
    bin_op->set_ic_data(comp->ic_data());
    bin_op->set_instr(comp->instr());
    comp->instr()->replace_computation(bin_op);
  }
}


void FlowGraphOptimizer::VisitDo(DoInstr* instr) {
  instr->computation()->Accept(this);
}


void FlowGraphOptimizer::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this);
}


}  // namespace dart
