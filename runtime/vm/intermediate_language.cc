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


// ==== Support for visiting instructions.
Instruction* JoinEntryInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitJoinEntry(this);
  return successor_;
}


Instruction* TargetEntryInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitTargetEntry(this);
  return successor_;
}


Instruction* DoInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitDo(this);
  return successor_;
}


Instruction* BindInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitBind(this);
  return successor_;
}


Instruction* ReturnInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitReturn(this);
  return NULL;
}


Instruction* BranchInstr::Accept(InstructionVisitor* visitor) {
  visitor->VisitBranch(this);
  return NULL;
}


// Default implementation of visiting basic blocks.  Can be overridden.
void InstructionVisitor::VisitBlocks(
    const GrowableArray<BlockEntryInstr*>& block_order) {
  for (intptr_t i = block_order.length() - 1; i >= 0; --i) {
    Instruction* current = block_order[i]->Accept(this);
    while ((current != NULL) && !current->IsBlockEntry()) {
      current = current->Accept(this);
    }
  }
}


// ==== Postorder graph traversal.
void DoInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void BindInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void ReturnInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
}


void BranchInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder.
  if (false_successor_->mark() != mark()) {
    false_successor_->Postorder(block_entries);
  }
  if (true_successor_->mark() != mark()) {
    true_successor_->Postorder(block_entries);
  }
}


void JoinEntryInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
  block_entries->Add(this);
}


void TargetEntryInstr::Postorder(
    GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
  block_entries->Add(this);
}


}  // namespace dart
