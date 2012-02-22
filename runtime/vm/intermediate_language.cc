// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/object.h"
#include "vm/os.h"
#include "vm/scopes.h"

namespace dart {

// ==== Printing support.
void AssertAssignableComp::Print() const {
  OS::Print("AssertAssignable(");
  value_->Print();
  OS::Print(", %s)", type_.ToCString());
}


void InstanceCallComp::Print() const {
  OS::Print("InstanceCall(%s", name_);
  for (intptr_t i = 0; i < arguments_->length(); ++i) {
    OS::Print(", ");
    (*arguments_)[i]->Print();
  }
  OS::Print(")");
}


void StaticCallComp::Print() const {
  OS::Print("StaticCall(%s", String::Handle(function_.name()).ToCString());
  for (intptr_t i = 0; i < arguments_->length(); ++i) {
    OS::Print(", ");
    (*arguments_)[i]->Print();
  }
  OS::Print(")");
}


void LoadLocalComp::Print() const {
  OS::Print("LoadLocal(%s)", local_.name().ToCString());
}


void StoreLocalComp::Print() const {
  OS::Print("StoreLocal(%s, ", local_.name().ToCString());
  value_->Print();
  OS::Print(")");
}


void TempValue::Print() const {
  OS::Print("t%d", index_);
}


void ConstantValue::Print() const {
  OS::Print("#%s", instance_.ToCString());
}


void Instruction::PrintGotoSuccessor(
    Instruction* successor,
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  if ((instruction_index == 0) ||
      (instruction_list[instruction_index - 1] != successor)) {
    // Linear search of the instruction list for the successor's index.
    for (intptr_t i = 0; i < instruction_list.length(); ++i) {
      if (instruction_list[i] == successor) {
        intptr_t instruction_number = instruction_list.length() - i;
        OS::Print(" goto %d", instruction_number);
        break;
      }
    }
  }
}


void DoInstr::Print(intptr_t instruction_index,
                    const GrowableArray<Instruction*>& instruction_list) const {
  computation_->Print();
  PrintGotoSuccessor(successor_, instruction_index, instruction_list);
}


void BindInstr::Print(
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  OS::Print("t%d <-", temp_index_);
  computation_->Print();
  PrintGotoSuccessor(successor_, instruction_index, instruction_list);
}


void ReturnInstr::Print(
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  OS::Print("return ");
  value_->Print();
}


void BranchInstr::Print(
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  OS::Print("if ");
  value_->Print();
  // Linear search for the instruction numbers of the successors.
  intptr_t true_successor_number = -1;
  intptr_t false_successor_number = -1;
  for (intptr_t i = 0; i < instruction_list.length(); ++i) {
    if (instruction_list[i] == true_successor_) {
      true_successor_number = instruction_list.length() - i;
      if (false_successor_number >= 0) break;
    }
    if (instruction_list[i] == false_successor_) {
      false_successor_number = instruction_list.length() - i;
      if (true_successor_number >= 0) break;
    }
  }
  OS::Print(" goto(%d, %d)", true_successor_number, false_successor_number);
}


void JoinEntryInstr::Print(
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  OS::Print("[join]");
  PrintGotoSuccessor(successor_, instruction_index, instruction_list);
}


void TargetEntryInstr::Print(
    intptr_t instruction_index,
    const GrowableArray<Instruction*>& instruction_list) const {
  OS::Print("[target]");
  PrintGotoSuccessor(successor_, instruction_index, instruction_list);
}


void DoInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(visited);
  visited->Add(this);
}


void BindInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(visited);
  visited->Add(this);
}


void ReturnInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  visited->Add(this);
}


void BranchInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder.
  if (false_successor_->mark() != mark()) {
    false_successor_->Postorder(visited);
  }
  if (true_successor_->mark() != mark()) {
    true_successor_->Postorder(visited);
  }
  visited->Add(this);
}


void JoinEntryInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(visited);
  visited->Add(this);
}


void TargetEntryInstr::Postorder(GrowableArray<Instruction*>* visited) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(visited);
  visited->Add(this);
}


}  // namespace dart
