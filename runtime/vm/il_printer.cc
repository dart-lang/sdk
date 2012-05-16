// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/il_printer.h"

#include "vm/intermediate_language.h"
#include "vm/os.h"

namespace dart {


void FlowGraphPrinter::VisitBlocks() {
  OS::Print("==== %s\n", function_.ToFullyQualifiedCString());

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Print the block entry.
    Instruction* current = block_order_[i]->Accept(this);
    // And all the successors until an exit, branch, or a block entry.
    while ((current != NULL) && !current->IsBlockEntry()) {
      OS::Print("\n");
      current = current->Accept(this);
    }
    BlockEntryInstr* successor =
        (current == NULL) ? NULL : current->AsBlockEntry();
    if (successor != NULL) {
      // For readability label blocks with their reverse postorder index,
      // not their postorder block number, so the first block is 0 (not
      // n-1).
      OS::Print(" goto %d", reverse_index(successor->postorder_number()));
    }
    OS::Print("\n");
  }
}


void FlowGraphPrinter::VisitUse(UseVal* val) {
  OS::Print("t%d", val->definition()->temp_index());
}


void FlowGraphPrinter::VisitConstant(ConstantVal* val) {
  OS::Print("#%s", val->value().ToCString());
}


void FlowGraphPrinter::VisitAssertAssignable(AssertAssignableComp* comp) {
  OS::Print("AssertAssignable(");
  comp->value()->Accept(this);
  OS::Print(", %s, '%s'",
            String::Handle(comp->dst_type().Name()).ToCString(),
            comp->dst_name().ToCString());
  if (comp->instantiator_type_arguments() != NULL) {
    OS::Print(" (instantiator:");
    comp->instantiator_type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitAssertBoolean(AssertBooleanComp* comp) {
  OS::Print("AssertBoolean(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCurrentContext(CurrentContextComp* comp) {
  OS::Print("CurrentContext");
}


void FlowGraphPrinter::VisitClosureCall(ClosureCallComp* comp) {
  OS::Print("ClosureCall(");
  comp->context()->Accept(this);
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitInstanceCall(InstanceCallComp* comp) {
  OS::Print("InstanceCall(%s", comp->function_name().ToCString());
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitStrictCompare(StrictCompareComp* comp) {
  OS::Print("StrictCompare(%s, ", Token::Str(comp->kind()));
  comp->left()->Accept(this);
  OS::Print(", ");
  comp->right()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitEqualityCompare(EqualityCompareComp* comp) {
  comp->left()->Accept(this);
  OS::Print(" == ");
  comp->right()->Accept(this);
}


void FlowGraphPrinter::VisitStaticCall(StaticCallComp* comp) {
  OS::Print("StaticCall(%s",
            String::Handle(comp->function().name()).ToCString());
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitLoadLocal(LoadLocalComp* comp) {
  OS::Print("LoadLocal(%s lvl:%d)",
      comp->local().name().ToCString(), comp->context_level());
}


void FlowGraphPrinter::VisitStoreLocal(StoreLocalComp* comp) {
  OS::Print("StoreLocal(%s, ", comp->local().name().ToCString());
  comp->value()->Accept(this);
  OS::Print(", lvl: %d)", comp->context_level());
}


void FlowGraphPrinter::VisitNativeCall(NativeCallComp* comp) {
  OS::Print("NativeCall(%s)", comp->native_name().ToCString());
}


void FlowGraphPrinter::VisitLoadInstanceField(LoadInstanceFieldComp* comp) {
  OS::Print("LoadInstanceField(%s, ",
      String::Handle(comp->field().name()).ToCString());
  comp->instance()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStoreInstanceField(StoreInstanceFieldComp* comp) {
  OS::Print("StoreInstanceField(%s, ",
            String::Handle(comp->field().name()).ToCString());
  comp->instance()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitLoadStaticField(LoadStaticFieldComp* comp) {
  OS::Print("LoadStaticField(%s)",
            String::Handle(comp->field().name()).ToCString());
}


void FlowGraphPrinter::VisitStoreStaticField(StoreStaticFieldComp* comp) {
  OS::Print("StoreStaticField(%s, ",
            String::Handle(comp->field().name()).ToCString());
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStoreIndexed(StoreIndexedComp* comp) {
  OS::Print("StoreIndexed(");
  comp->array()->Accept(this);
  OS::Print(", ");
  comp->index()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitInstanceSetter(InstanceSetterComp* comp) {
  OS::Print("InstanceSetter(");
  comp->receiver()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStaticSetter(StaticSetterComp* comp) {
  OS::Print("StaticSetter(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitBooleanNegate(BooleanNegateComp* comp) {
  OS::Print("! ");
  comp->value()->Accept(this);
}


void FlowGraphPrinter::VisitInstanceOf(InstanceOfComp* comp) {
  comp->value()->Accept(this);
  OS::Print(" %s %s",
            comp->negate_result() ? "ISNOT" : "IS",
            String::Handle(comp->type().Name()).ToCString());
  if (comp->type_arguments() != NULL) {
    OS::Print(" (type-arg:");
    comp->type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitAllocateObject(AllocateObjectComp* comp) {
  OS::Print("AllocateObject(%s",
            Class::Handle(comp->constructor().owner()).ToCString());
  for (intptr_t i = 0; i < comp->arguments().length(); i++) {
    OS::Print(", ");
    comp->arguments()[i]->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitAllocateObjectWithBoundsCheck(
    AllocateObjectWithBoundsCheckComp* comp) {
  OS::Print("AllocateObjectWithBoundsCheck(%s",
            Class::Handle(comp->constructor().owner()).ToCString());
  for (intptr_t i = 0; i < comp->arguments().length(); i++) {
    OS::Print(", ");
    comp->arguments()[i]->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitCreateArray(CreateArrayComp* comp) {
  OS::Print("CreateArray(");
  for (int i = 0; i < comp->ElementCount(); ++i) {
    if (i != 0) OS::Print(", ");
    comp->ElementAt(i)->Accept(this);
  }
  if (comp->ElementCount() > 0) OS::Print(", ");
  comp->element_type()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCreateClosure(CreateClosureComp* comp) {
  OS::Print("CreateClosure(%s", comp->function().ToCString());
  if (comp->type_arguments() != NULL) {
    OS::Print(", ");
    comp->type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitNativeLoadField(NativeLoadFieldComp* comp) {
  OS::Print("NativeLoadField(");
  comp->value()->Accept(this);
  OS::Print(", %d)", comp->offset_in_bytes());
}


void FlowGraphPrinter::VisitNativeStoreField(NativeStoreFieldComp* comp) {
  OS::Print("NativeStoreField(");
  comp->dest()->Accept(this);
  OS::Print(", %d, ", comp->offset_in_bytes());
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsComp* comp) {
  const String& type_args = String::Handle(comp->type_arguments().Name());
  OS::Print("InstantiateTypeArguments(%s, ", type_args.ToCString());
  comp->instantiator()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitExtractConstructorTypeArguments(
    ExtractConstructorTypeArgumentsComp* comp) {
  const String& type_args = String::Handle(comp->type_arguments().Name());
  OS::Print("ExtractConstructorTypeArguments(%s, ", type_args.ToCString());
  comp->instantiator()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitExtractConstructorInstantiator(
    ExtractConstructorInstantiatorComp* comp) {
  OS::Print("ExtractConstructorInstantiator(");
  comp->instantiator()->Accept(this);
  OS::Print(", ");
  comp->discard_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitAllocateContext(AllocateContextComp* comp) {
  OS::Print("AllocateContext(%d)", comp->num_context_variables());
}


void FlowGraphPrinter::VisitChainContext(ChainContextComp* comp) {
  OS::Print("ChainContext(");
  comp->context_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCloneContext(CloneContextComp* comp) {
  OS::Print("CloneContext(");
  comp->context_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCatchEntry(CatchEntryComp* comp) {
  OS::Print("CatchEntry(%s, %s)",
            comp->exception_var().name().ToCString(),
            comp->stacktrace_var().name().ToCString());
}


void FlowGraphPrinter::VisitStoreContext(StoreContextComp* comp) {
  OS::Print("StoreContext(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitGraphEntry(GraphEntryInstr* instr) {
  OS::Print("%2d: [graph]", reverse_index(instr->postorder_number()));
}


void FlowGraphPrinter::VisitJoinEntry(JoinEntryInstr* instr) {
  OS::Print("%2d: [join]", reverse_index(instr->postorder_number()));
}


void FlowGraphPrinter::VisitTargetEntry(TargetEntryInstr* instr) {
  OS::Print("%2d: [target", reverse_index(instr->postorder_number()));
  if (instr->HasTryIndex()) {
    OS::Print(" catch %d]", instr->try_index());
  } else {
    OS::Print("]");
  }
}


void FlowGraphPrinter::VisitDo(DoInstr* instr) {
  OS::Print("    ");
  instr->computation()->Accept(this);
}


void FlowGraphPrinter::VisitBind(BindInstr* instr) {
  OS::Print("    t%d <- ", instr->temp_index());
  instr->computation()->Accept(this);
}


void FlowGraphPrinter::VisitReturn(ReturnInstr* instr) {
  OS::Print("    return ");
  instr->value()->Accept(this);
}


void FlowGraphPrinter::VisitThrow(ThrowInstr* instr) {
  OS::Print("    throw ");
  instr->exception()->Accept(this);
}


void FlowGraphPrinter::VisitReThrow(ReThrowInstr* instr) {
  OS::Print("    rethrow (");
  instr->exception()->Accept(this);
  OS::Print(", ");
  instr->stack_trace()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitBranch(BranchInstr* instr) {
  OS::Print("    if ");
  instr->value()->Accept(this);
  OS::Print(" goto (%d, %d)",
            reverse_index(instr->true_successor()->postorder_number()),
            reverse_index(instr->false_successor()->postorder_number()));
}


}  // namespace dart
