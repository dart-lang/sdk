// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/il_printer.h"

#include "vm/intermediate_language.h"
#include "vm/os.h"

namespace dart {


void BufferFormatter::Print(const char* format, ...) {
  intptr_t available = size_ - position_;
  if (available <= 0) return;
  va_list args;
  va_start(args, format);
  intptr_t written =
      OS::VSNPrint(buffer_ + position_, available, format, args);
  if (written >= 0) {
    position_ += (available <= written) ? available : written;
  }
  va_end(args);
}


void FlowGraphPrinter::PrintBlocks() {
  OS::Print("==== %s\n", function_.ToFullyQualifiedCString());

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Print the block entry.
    Print(block_order_[i]);
    Instruction* current = block_order_[i]->StraightLineSuccessor();
    // And all the successors until an exit, branch, or a block entry.
    while ((current != NULL) && !current->IsBlockEntry()) {
      OS::Print("\n");
      Print(current);
      current = current->StraightLineSuccessor();
    }
    BlockEntryInstr* successor =
        (current == NULL) ? NULL : current->AsBlockEntry();
    if (successor != NULL) {
      OS::Print(" goto %d", successor->block_id());
    }
    OS::Print("\n");
  }
}


void FlowGraphPrinter::Print(Instruction* instr) {
  char str[80];
  BufferFormatter f(str, sizeof(str));
  instr->PrintTo(&f);
  OS::Print("%s", str);
}


void Computation::PrintTo(BufferFormatter* f) const {
  f->Print("%s(", DebugName());
  PrintOperandsTo(f);
  f->Print(")");
}


void Computation::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < InputCount(); ++i) {
    if (i > 0) f->Print(", ");
    if (InputAt(i) != NULL) InputAt(i)->PrintTo(f);
    OS::Print(")");
  }
}


void UseVal::PrintTo(BufferFormatter* f) const {
  f->Print("t%d", definition()->temp_index());
}


void ConstantVal::PrintTo(BufferFormatter* f) const {
  f->Print("#%s", value().ToCString());
}


void AssertAssignableComp::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %s, '%s'",
            String::Handle(dst_type().Name()).ToCString(),
            dst_name().ToCString());
  if (instantiator() != NULL) {
    OS::Print(" (instantiator:");
    instantiator()->PrintTo(f);
    OS::Print(")");
  }
  if (instantiator_type_arguments() != NULL) {
    f->Print(" (instantiator:");
    instantiator_type_arguments()->PrintTo(f);
    f->Print(")");
  }
}


void ClosureCallComp::PrintOperandsTo(BufferFormatter* f) const {
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    if (i == 0) f->Print(", ");
    ArgumentAt(i)->PrintTo(f);
  }
}


void InstanceCallComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", function_name().ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentAt(i)->PrintTo(f);
  }
}


void StrictCompareComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", Token::Str(kind()));
  left()->PrintTo(f);
  f->Print(", ");
  right()->PrintTo(f);
}


void EqualityCompareComp::PrintOperandsTo(BufferFormatter* f) const {
  left()->PrintTo(f);
  f->Print(" == ");
  right()->PrintTo(f);
}


void StaticCallComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(function().name()).ToCString());
  for (intptr_t i = 0; i < ArgumentCount(); ++i) {
    f->Print(", ");
    ArgumentAt(i)->PrintTo(f);
  }
}


void LoadLocalComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s lvl:%d", local().name().ToCString(), context_level());
}


void StoreLocalComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", local().name().ToCString());
  value()->PrintTo(f);
  f->Print(", lvl: %d", context_level());
}


void NativeCallComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", native_name().ToCString());
}


void LoadInstanceFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  instance()->PrintTo(f);
}


void StoreInstanceFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  instance()->PrintTo(f);
  f->Print(", ");
  value()->PrintTo(f);
}


void LoadStaticFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", String::Handle(field().name()).ToCString());
}


void StoreStaticFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, ", String::Handle(field().name()).ToCString());
  value()->PrintTo(f);
}


void InstanceOfComp::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(" %s %s",
            negate_result() ? "ISNOT" : "IS",
            String::Handle(type().Name()).ToCString());
  if (instantiator() != NULL) {
    OS::Print(" (instantiator:");
    instantiator()->PrintTo(f);
    OS::Print(")");
  }
  if (type_arguments() != NULL) {
    f->Print(" (type-arg:");
    type_arguments()->PrintTo(f);
  }
}


void AllocateObjectComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", Class::Handle(constructor().owner()).ToCString());
  for (intptr_t i = 0; i < arguments().length(); i++) {
    f->Print(", ");
    arguments()[i]->PrintTo(f);
  }
}


void AllocateObjectWithBoundsCheckComp::PrintOperandsTo(
    BufferFormatter* f) const {
  f->Print("%s", Class::Handle(constructor().owner()).ToCString());
  for (intptr_t i = 0; i < arguments().length(); i++) {
    f->Print(", ");
    arguments()[i]->PrintTo(f);
  }
}


void CreateArrayComp::PrintOperandsTo(BufferFormatter* f) const {
  for (int i = 0; i < ElementCount(); ++i) {
    if (i != 0) f->Print(", ");
    ElementAt(i)->PrintTo(f);
  }
  if (ElementCount() > 0) f->Print(", ");
  element_type()->PrintTo(f);
}


void CreateClosureComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s", function().ToCString());
  if (type_arguments() != NULL) {
    f->Print(", ");
    type_arguments()->PrintTo(f);
  }
}


void LoadVMFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  value()->PrintTo(f);
  f->Print(", %d", offset_in_bytes());
}


void StoreVMFieldComp::PrintOperandsTo(BufferFormatter* f) const {
  dest()->PrintTo(f);
  f->Print(", %d, ", offset_in_bytes());
  value()->PrintTo(f);
}


void InstantiateTypeArgumentsComp::PrintOperandsTo(BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s, ", type_args.ToCString());
  instantiator()->PrintTo(f);
}


void ExtractConstructorTypeArgumentsComp::PrintOperandsTo(
    BufferFormatter* f) const {
  const String& type_args = String::Handle(type_arguments().Name());
  f->Print("%s, ", type_args.ToCString());
  instantiator()->PrintTo(f);
}


void AllocateContextComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%d", num_context_variables());
}


void CatchEntryComp::PrintOperandsTo(BufferFormatter* f) const {
  f->Print("%s, %s",
           exception_var().name().ToCString(),
           stacktrace_var().name().ToCString());
}


void GraphEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%2d: [graph]", block_id());
}


void JoinEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%2d: [join]", block_id());
}


void TargetEntryInstr::PrintTo(BufferFormatter* f) const {
  f->Print("%2d: [target", block_id());
  if (HasTryIndex()) {
    f->Print(" catch %d]", try_index());
  } else {
    f->Print("]");
  }
}


void DoInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    ");
  computation()->PrintTo(f);
}


void BindInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    t%d <- ", temp_index());
  computation()->PrintTo(f);
}


void ReturnInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  value()->PrintTo(f);
}


void ThrowInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  exception()->PrintTo(f);
}


void ReThrowInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  exception()->PrintTo(f);
  f->Print(", ");
  stack_trace()->PrintTo(f);
}


void BranchInstr::PrintTo(BufferFormatter* f) const {
  f->Print("    %s ", DebugName());
  f->Print("if ");
  value()->PrintTo(f);
  f->Print(" goto (%d, %d)",
            true_successor()->block_id(),
            false_successor()->block_id());
}


}  // namespace dart
