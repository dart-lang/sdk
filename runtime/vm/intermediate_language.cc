// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/bit_vector.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/scopes.h"

namespace dart {

// ==== Support for visiting flow graphs.
#define DEFINE_ACCEPT(ShortName, ClassName)                                    \
void ClassName::Accept(FlowGraphVisitor* visitor) {                            \
  visitor->Visit##ShortName(this);                                             \
}

FOR_EACH_COMPUTATION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


#define DEFINE_ACCEPT(ShortName)                                               \
Instruction* ShortName##Instr::Accept(FlowGraphVisitor* visitor) {             \
  visitor->Visit##ShortName(this);                                             \
  return StraightLineSuccessor();                                              \
}

FOR_EACH_INSTRUCTION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


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


intptr_t GraphEntryInstr::InputCount() const {
  return 0;
}


intptr_t TargetEntryInstr::InputCount() const {
  return 0;
}


intptr_t JoinEntryInstr::InputCount() const {
  return 0;
}


// ==== Recording assigned variables.
void Computation::RecordAssignedVars(BitVector* assigned_vars) {
  // Nothing to do for the base class.
}


void StoreLocalComp::RecordAssignedVars(BitVector* assigned_vars) {
  if (!local().is_captured()) {
    assigned_vars->Add(local().BitIndexIn(assigned_vars));
  }
}


void Instruction::RecordAssignedVars(BitVector* assigned_vars) {
  // Nothing to do for the base class.
}


void DoInstr::RecordAssignedVars(BitVector* assigned_vars) {
  computation()->RecordAssignedVars(assigned_vars);
}


void BindInstr::RecordAssignedVars(BitVector* assigned_vars) {
  computation()->RecordAssignedVars(assigned_vars);
}


// ==== Postorder graph traversal.
void GraphEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* assigned_vars,
    intptr_t variable_count) {
  // We only visit this block once, first of all blocks.
  ASSERT(preorder_number() == -1);
  ASSERT(current_block == NULL);
  ASSERT(preorder->is_empty());
  ASSERT(postorder->is_empty());
  ASSERT(parent->is_empty());

  // This node has no parent, indicated by -1.  The preorder number is 0.
  parent->Add(-1);
  set_preorder_number(0);
  preorder->Add(this);
  BitVector* vars =
      (variable_count == 0) ? NULL : new BitVector(variable_count);
  assigned_vars->Add(vars);

  // Iteratively traverse all successors.  In the unoptimized code, we will
  // enter the function at the first successor in reverse postorder, so we
  // must visit the normal entry last.
  for (intptr_t i = catch_entries_.length() - 1; i >= 0; --i) {
    catch_entries_[i]->DiscoverBlocks(this, preorder, postorder, parent,
                                      assigned_vars, variable_count);
  }
  normal_entry_->DiscoverBlocks(this, preorder, postorder, parent,
                                assigned_vars, variable_count);

  // Assign postorder number.
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


// Base class implementation used for JoinEntry and TargetEntry.
void BlockEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* assigned_vars,
    intptr_t variable_count) {
  // We have already visited the graph entry, so we can assume current_block
  // is non-null and preorder array is non-empty.
  ASSERT(current_block != NULL);
  ASSERT(!preorder->is_empty());

  // 1. Record control-flow-graph basic-block predecessors.
  AddPredecessor(current_block);

  // 2. If the block has already been reached by the traversal, we are
  // done.  Blocks with a single predecessor cannot have been reached
  // before.
  ASSERT(!IsTargetEntry() || (preorder_number() == -1));
  if (preorder_number() >= 0) return;

  // 3. The last entry in the preorder array is the spanning-tree parent.
  intptr_t parent_number = preorder->length() - 1;
  parent->Add(parent_number);

  // 4. Assign preorder number and add the block entry to the list.
  // Allocate an empty set of assigned variables for the block.
  set_preorder_number(parent_number + 1);
  preorder->Add(this);
  BitVector* vars =
      (variable_count == 0) ? NULL : new BitVector(variable_count);
  assigned_vars->Add(vars);
  // The preorder, parent, and assigned_vars arrays are all indexed by
  // preorder block number, so they should stay in lockstep.
  ASSERT(preorder->length() == parent->length());
  ASSERT(preorder->length() == assigned_vars->length());

  // 5. Iterate straight-line successors until a branch instruction or
  // another basic block entry instruction, and visit that instruction.
  ASSERT(StraightLineSuccessor() != NULL);
  Instruction* next = StraightLineSuccessor();
  if (next->IsBlockEntry()) {
    set_last_instruction(this);
  } else {
    while ((next != NULL) && !next->IsBlockEntry() && !next->IsBranch()) {
      if (vars != NULL) next->RecordAssignedVars(vars);
      set_last_instruction(next);
      next = next->StraightLineSuccessor();
    }
  }
  if (next != NULL) {
    next->DiscoverBlocks(this, preorder, postorder, parent, assigned_vars,
                         variable_count);
  }

  // 6. Assign postorder number and add the block entry to the list.
  set_postorder_number(postorder->length());
  postorder->Add(this);
}


void BranchInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* assigned_vars,
    intptr_t variable_count) {
  current_block->set_last_instruction(this);
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder used as the block ordering in the
  // nonoptimizing compiler.
  ASSERT(true_successor_ != NULL);
  ASSERT(false_successor_ != NULL);
  false_successor_->DiscoverBlocks(current_block, preorder, postorder, parent,
                                   assigned_vars, variable_count);
  true_successor_->DiscoverBlocks(current_block, preorder, postorder, parent,
                                  assigned_vars, variable_count);
}


// ==== Support for propagating static type.
RawAbstractType* ConstantVal::StaticType() const {
  if (value().IsInstance()) {
    Instance& instance = Instance::Handle();
    instance ^= value().raw();
    return instance.GetType();
  } else {
    UNREACHABLE();
    return AbstractType::null();
  }
}


RawAbstractType* UseVal::StaticType() const {
  return definition()->StaticType();
}


RawAbstractType* AssertAssignableComp::StaticType() const {
  return dst_type().raw();
}


RawAbstractType* AssertBooleanComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* CurrentContextComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* StoreContextComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* ClosureCallComp::StaticType() const {
  // The closure is the first argument to the call.
  const AbstractType& function_type =
      AbstractType::Handle(ArgumentAt(0)->StaticType());
  if (function_type.IsDynamicType() || function_type.IsFunctionInterface()) {
    // The function type is not statically known or simply Function.
    return Type::DynamicType();
  }
  const Class& signature_class = Class::Handle(function_type.type_class());
  ASSERT(signature_class.IsSignatureClass());
  const Function& signature_function =
      Function::Handle(signature_class.signature_function());
  // TODO(regis): The result type may be generic.
  return signature_function.result_type();
}


RawAbstractType* InstanceCallComp::StaticType() const {
  return Type::DynamicType();
}


RawAbstractType* StaticCallComp::StaticType() const {
  return function().result_type();
}


RawAbstractType* LoadLocalComp::StaticType() const {
  return local().type().raw();
}


RawAbstractType* StoreLocalComp::StaticType() const {
  const AbstractType& assigned_value_type =
      AbstractType::Handle(value()->StaticType());
  if (assigned_value_type.IsDynamicType()) {
    // Static type of assigned value is unknown, return static type of local.
    return local().type().raw();
  }
  return assigned_value_type.raw();
}


RawAbstractType* StrictCompareComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* EqualityCompareComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* NativeCallComp::StaticType() const {
  // The result type of the native function is identical to the result type of
  // the enclosing native Dart function.
  // TODO(regis): Can we trust it or should we check anyway? Check for now.
  return Type::DynamicType();
}


RawAbstractType* StoreIndexedComp::StaticType() const {
  return value()->StaticType();
}


RawAbstractType* InstanceSetterComp::StaticType() const {
  // TODO(regis): Would it be correct to return value()->StaticType()?
  return Type::DynamicType();
}


RawAbstractType* StaticSetterComp::StaticType() const {
  // TODO(regis): Would it be correct/better to return value()->StaticType()?
  return setter_function().result_type();
}


RawAbstractType* LoadInstanceFieldComp::StaticType() const {
  return field().type();
}


RawAbstractType* StoreInstanceFieldComp::StaticType() const {
  const AbstractType& assigned_value_type =
      AbstractType::Handle(value()->StaticType());
  if (assigned_value_type.IsDynamicType()) {
    // Static type of assigned value is unknown, return static type of field.
    return field().type();
  }
  return assigned_value_type.raw();
}


RawAbstractType* LoadStaticFieldComp::StaticType() const {
  return field().type();
}


RawAbstractType* StoreStaticFieldComp::StaticType() const {
  const AbstractType& assigned_value_type =
      AbstractType::Handle(value()->StaticType());
  if (assigned_value_type.IsDynamicType()) {
    // Static type of assigned value is unknown, return static type of field.
    return field().type();
  }
  return assigned_value_type.raw();
}


RawAbstractType* BooleanNegateComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* InstanceOfComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* CreateArrayComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* CreateClosureComp::StaticType() const {
  const Function& fun = function();
  const Class& signature_class = Class::Handle(fun.signature_class());
  // TODO(regis): Can we take (constant) type_arguments() into consideration?
  // For now, we return Dynamic (no type test elimination) if the signature
  // class is parameterized, or a non-parameterized finalized type otherwise.
  if (signature_class.HasTypeArguments()) {
    return Type::DynamicType();
  }
  // Make sure we use the canonical signature class.
  const Type& type = Type::Handle(signature_class.SignatureType());
  const Class& canonical_signature_class = Class::Handle(type.type_class());
  return Type::NewNonParameterizedType(canonical_signature_class);
}


RawAbstractType* AllocateObjectComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* AllocateObjectWithBoundsCheckComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* NativeLoadFieldComp::StaticType() const {
  ASSERT(!type().IsNull());
  return type().raw();
}


RawAbstractType* NativeStoreFieldComp::StaticType() const {
  return value()->StaticType();
}


RawAbstractType* InstantiateTypeArgumentsComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorTypeArgumentsComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorInstantiatorComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* AllocateContextComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* ChainContextComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* CloneContextComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* CatchEntryComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


}  // namespace dart
