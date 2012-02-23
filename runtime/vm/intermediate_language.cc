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


Instruction* DoInstr::Print() const {
  OS::Print("    ");
  computation_->Print();
  return successor_;
}


Instruction* BindInstr::Print() const {
  OS::Print("    t%d <-", temp_index_);
  computation_->Print();
  return successor_;
}


Instruction* ReturnInstr::Print() const {
  OS::Print("    return ");
  value_->Print();
  return NULL;
}


Instruction* BranchInstr::Print() const {
  OS::Print("    if ");
  value_->Print();
  OS::Print(" goto(%d, %d)", true_successor_->block_number(),
            false_successor_->block_number());
  return NULL;
}


Instruction* JoinEntryInstr::Print() const {
  OS::Print("%2d: [join]", block_number());
  return successor_;
}


Instruction* TargetEntryInstr::Print() const {
  OS::Print("%2d: [target]", block_number_);
  return successor_;
}


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
