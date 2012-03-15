// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/object.h"
#include "vm/os.h"
#include "vm/scopes.h"

namespace dart {

// ==== Support for visiting flow graphs.
#define DEFINE_ACCEPT(ShortName, ClassName)                                    \
  void ClassName::Accept(FlowGraphVisitor* visitor) {                          \
    visitor->Visit##ShortName(this);                                           \
  }

FOR_EACH_COMPUTATION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


Instruction* JoinEntryInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitJoinEntry(this);
  return successor_;
}


Instruction* TargetEntryInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitTargetEntry(this);
  return successor_;
}


Instruction* PickTempInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitPickTemp(this);
  return successor_;
}


Instruction* TuckTempInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitTuckTemp(this);
  return successor_;
}


Instruction* DoInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitDo(this);
  return successor_;
}


Instruction* BindInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitBind(this);
  return successor_;
}


Instruction* ReturnInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitReturn(this);
  return NULL;
}


Instruction* ThrowInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitThrow(this);
  return NULL;
}


Instruction* ReThrowInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitReThrow(this);
  return NULL;
}


Instruction* BranchInstr::Accept(FlowGraphVisitor* visitor) {
  visitor->VisitBranch(this);
  return NULL;
}


// Default implementation of visiting basic blocks.  Can be overridden.
void FlowGraphVisitor::VisitBlocks(
    const GrowableArray<BlockEntryInstr*>& block_order) {
  for (intptr_t i = block_order.length() - 1; i >= 0; --i) {
    Instruction* current = block_order[i]->Accept(this);
    while ((current != NULL) && !current->IsBlockEntry()) {
      current = current->Accept(this);
    }
  }
}


// ==== Postorder graph traversal.
void JoinEntryInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
  block_entries->Add(this);
}


void TargetEntryInstr::Postorder(
    GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
  block_entries->Add(this);
}


void PickTempInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void TuckTempInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void DoInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void BindInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  ASSERT(successor_ != NULL);
  if (successor_->mark() != mark()) successor_->Postorder(block_entries);
}


void ReturnInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
}


void ThrowInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
}


void ReThrowInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
}


void BranchInstr::Postorder(GrowableArray<BlockEntryInstr*>* block_entries) {
  flip_mark();
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder.
  ASSERT(false_successor_ != NULL);
  ASSERT(true_successor_ != NULL);
  if (false_successor_->mark() != mark()) {
    false_successor_->Postorder(block_entries);
  }
  if (true_successor_->mark() != mark()) {
    true_successor_->Postorder(block_entries);
  }
}


}  // namespace dart
