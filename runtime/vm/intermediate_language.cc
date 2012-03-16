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
void FlowGraphVisitor::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    Instruction* current = block_order_[i]->Accept(this);
    while ((current != NULL) && !current->IsBlockEntry()) {
      current = current->Accept(this);
    }
  }
}


// ==== Postorder graph traversal.
void JoinEntryInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  // JoinEntryInstr is the only instruction that can have more than one
  // predecessor, so it is the only one that could be reached more than once
  // during the traversal.
  //
  // Use the presence of a preorder number to indicate that it has already
  // been reached.
  if (preorder_number() >= 0) return;
  set_preorder_number(preorder->length());
  preorder->Add(this);
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


void TargetEntryInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  ASSERT(preorder_number() == -1);
  set_preorder_number(preorder->length());
  preorder->Add(this);
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


void PickTempInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
}


void TuckTempInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
}


void DoInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
}


void BindInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  ASSERT(successor_ != NULL);
  successor_->DepthFirstSearch(preorder, postorder);
}


void ReturnInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
}


void ThrowInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
}


void ReThrowInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
}


void BranchInstr::DepthFirstSearch(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder) {
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder used as the block ordering in the
  // nonoptimizing compiler.
  ASSERT(true_successor_ != NULL);
  ASSERT(false_successor_ != NULL);
  false_successor_->DepthFirstSearch(preorder, postorder);
  true_successor_->DepthFirstSearch(preorder, postorder);
}


}  // namespace dart
