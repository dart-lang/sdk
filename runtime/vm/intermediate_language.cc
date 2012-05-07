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


// ==== Per-instruction input counts.
intptr_t AssertAssignableComp::InputCount() const {
  // Value and optional instantiator type arguments.
  return (instantiator_type_arguments() == NULL) ? 1 : 2;
}


intptr_t InstanceOfComp::InputCount() const {
  // Value and optional type_arguments.
  return (type_arguments() == NULL) ? 1 : 2;
}


intptr_t CreateClosureComp::InputCount() const {
  // Optional type arguments.
  return (type_arguments() == NULL) ? 0 : 1;
}


intptr_t InstanceCallComp::InputCount() const {
  return ArgumentCount();
}


intptr_t StaticCallComp::InputCount() const {
  return ArgumentCount();
}


intptr_t ClosureCallComp::InputCount() const {
  // Context and arguments.
  return 1 + ArgumentCount();
}


intptr_t AllocateObjectComp::InputCount() const {
  return arguments().length();
}


intptr_t AllocateObjectWithBoundsCheckComp::InputCount() const {
  return arguments().length();
}


intptr_t CreateArrayComp::InputCount() const {
  return ElementCount() + 1;
}


intptr_t BranchInstr::InputCount() const {
  return 1;
}


intptr_t ReThrowInstr::InputCount() const {
  return 2;
}


intptr_t ThrowInstr::InputCount() const {
  return 1;
}


intptr_t ReturnInstr::InputCount() const {
  return 1;
}


intptr_t BindInstr::InputCount() const {
  return computation()->InputCount();
}


intptr_t DoInstr::InputCount() const {
  return computation()->InputCount();
}


intptr_t TuckTempInstr::InputCount() const {
  return 0;
}


intptr_t PickTempInstr::InputCount() const {
  return 0;
}


intptr_t TargetEntryInstr::InputCount() const {
  return 0;
}


intptr_t JoinEntryInstr::InputCount() const {
  return 0;
}


// ==== Postorder graph traversal.
void JoinEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent) {
  // The global graph entry is a TargetEntryInstr, so we can assume
  // current_block is non-null and preorder array is non-empty.
  ASSERT(current_block != NULL);
  ASSERT(!preorder->is_empty());

  // 1. Record control-flow-graph basic-block predecessors.
  predecessors_.Add(current_block);

  // 2. If the block has already been reached by the traversal, we are done.
  if (preorder_number() >= 0) return;

  // 3. The last entry in the preorder array is the spanning-tree parent.
  intptr_t parent_number = preorder->length() - 1;
  parent->Add(parent_number);

  // 4. Assign preorder number and add the block entry to the list.
  set_preorder_number(parent_number + 1);
  preorder->Add(this);
  // The preorder and parent arrays are both indexed by preorder block
  // number, so they should stay in lockstep.
  ASSERT(preorder->length() == parent->length());

  // 5. Iterate straight-line successors until a branch instruction or
  // another basic block entry instruction, and visit that instruction.
  ASSERT(successor_ != NULL);
  Instruction* next = successor_;
  while ((next != NULL) && !next->IsBlockEntry() && !next->IsBranch()) {
    set_last_instruction(next);
    next = next->StraightLineSuccessor();
  }
  if (next != NULL) {
    next->DiscoverBlocks(this, preorder, postorder, parent);
  }

  // 6. Assign postorder number and add the block entry to the list.
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


void TargetEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent) {
  // 1. Record control-flow-graph basic-block predecessors.
  ASSERT(predecessor_ == NULL);
  predecessor_ = current_block;  // Might be NULL (for the graph entry).

  // 2. There is a single predecessor, so we should only reach this block once.
  ASSERT(preorder_number() == -1);

  // 3. The last entry in the preorder array is the spanning-tree parent.
  // The global graph entry has no parent, indicated by -1.
  intptr_t parent_number = preorder->length() - 1;
  parent->Add(parent_number);

  // 4. Assign preorder number and add the block entry to the list.
  set_preorder_number(parent_number + 1);
  preorder->Add(this);
  // The preorder and parent arrays are indexed by preorder block number, so
  // they should stay in lockstep.
  ASSERT(preorder->length() == parent->length());

  // 5. Iterate straight-line successors until a branch instruction or
  // another basic block entry instruction, and visit that instruction.
  ASSERT(successor_ != NULL);
  Instruction* next = successor_;
  while ((next != NULL) && !next->IsBlockEntry() && !next->IsBranch()) {
    set_last_instruction(next);
    next = next->StraightLineSuccessor();
  }
  if (next != NULL) {
    next->DiscoverBlocks(this, preorder, postorder, parent);
  }

  // 6. Assign postorder number and add the block entry to the list.
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


void BranchInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent) {
  current_block->set_last_instruction(this);
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder used as the block ordering in the
  // nonoptimizing compiler.
  ASSERT(true_successor_ != NULL);
  ASSERT(false_successor_ != NULL);
  false_successor_->DiscoverBlocks(current_block, preorder, postorder, parent);
  true_successor_->DiscoverBlocks(current_block, preorder, postorder, parent);
}


}  // namespace dart
