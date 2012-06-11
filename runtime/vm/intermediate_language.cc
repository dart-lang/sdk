// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/bit_vector.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/scopes.h"
#include "vm/stub_code.h"

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


// Truee iff. the v2 is above v1 on stack, or one of them is constant.
static bool VerifyValues(Value* v1, Value* v2) {
  ASSERT(v1->IsUse() && v2->IsUse());
  return (v1->AsUse()->definition()->temp_index() + 1) ==
     v2->AsUse()->definition()->temp_index();
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


intptr_t InstanceCallComp::InputCount() const {
  return ArgumentCount();
}


intptr_t StaticCallComp::InputCount() const {
  return ArgumentCount();
}


intptr_t ClosureCallComp::InputCount() const {
  return ArgumentCount();
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

  // The graph entry consists of only one instruction.
  set_last_instruction(this);

  // Iteratively traverse all successors.  In the unoptimized code, we will
  // enter the function at the first successor in reverse postorder, so we
  // must visit the normal entry last.
  for (intptr_t i = catch_entries_.length() - 1; i >= 0; --i) {
    catch_entries_[i]->DiscoverBlocks(this, preorder, postorder,
                                      parent, assigned_vars, variable_count);
  }
  normal_entry_->DiscoverBlocks(this, preorder, postorder,
                                parent, assigned_vars, variable_count);

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
    next->DiscoverBlocks(this, preorder, postorder,
                         parent, assigned_vars, variable_count);
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
  false_successor_->DiscoverBlocks(current_block, preorder, postorder,
                                   parent, assigned_vars, variable_count);
  true_successor_->DiscoverBlocks(current_block, preorder, postorder,
                                  parent, assigned_vars, variable_count);
}


intptr_t Instruction::SuccessorCount() const {
  ASSERT(!IsBranch());
  ASSERT(!IsGraphEntry());
  ASSERT(StraightLineSuccessor() == NULL ||
         StraightLineSuccessor()->IsBlockEntry());
  return StraightLineSuccessor() != NULL ? 1 : 0;
}


BlockEntryInstr* Instruction::SuccessorAt(intptr_t index) const {
  return StraightLineSuccessor()->AsBlockEntry();
}


intptr_t GraphEntryInstr::SuccessorCount() const {
  return 1 + catch_entries_.length();
}


BlockEntryInstr* GraphEntryInstr::SuccessorAt(intptr_t index) const {
  if (index == 0) return normal_entry_;
  return catch_entries_[index - 1];
}


intptr_t BranchInstr::SuccessorCount() const {
  return 2;
}


BlockEntryInstr* BranchInstr::SuccessorAt(intptr_t index) const {
  if (index == 0) return true_successor_;
  if (index == 1) return false_successor_;
  UNREACHABLE();
  return NULL;
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
  // TODO(regis): The result type may be generic. Consider upper bounds.
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


RawAbstractType* RelationalOpComp::StaticType() const {
  return Type::BoolInterface();
}


RawAbstractType* NativeCallComp::StaticType() const {
  // The result type of the native function is identical to the result type of
  // the enclosing native Dart function. However, we prefer to check the type
  // of the value returned from the native call.
  return Type::DynamicType();
}


RawAbstractType* LoadIndexedComp::StaticType() const {
  return Type::DynamicType();
}


RawAbstractType* StoreIndexedComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* InstanceSetterComp::StaticType() const {
  return value()->StaticType();
}


RawAbstractType* StaticSetterComp::StaticType() const {
  const AbstractType& assigned_value_type =
      AbstractType::Handle(value()->StaticType());
  if (assigned_value_type.IsDynamicType()) {
    // Static type of assigned value is unknown, return static type of setter
    // value parameter.
    return setter_function().ParameterTypeAt(0);
  }
  return assigned_value_type.raw();
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
  // TODO(regis): The signature type may be generic. Consider upper bounds.
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


RawAbstractType* LoadVMFieldComp::StaticType() const {
  ASSERT(!type().IsNull());
  return type().raw();
}


RawAbstractType* StoreVMFieldComp::StaticType() const {
  ASSERT(!type().IsNull());
  const AbstractType& assigned_value_type =
      AbstractType::Handle(value()->StaticType());
  if (assigned_value_type.IsDynamicType()) {
    // Static type of assigned value is unknown, return static type of field.
    return type().raw();
  }
  return assigned_value_type.raw();
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


RawAbstractType* CheckStackOverflowComp::StaticType() const {
  UNREACHABLE();
  return AbstractType::null();
}


RawAbstractType* BinaryOpComp::StaticType() const {
  // TODO(srdjan): Compute based on input types (ICData).
  return Type::DynamicType();
}


RawAbstractType* UnarySmiOpComp::StaticType() const {
  return Type::IntInterface();
}


RawAbstractType* NumberNegateComp::StaticType() const {
  return Type::NumberInterface();
}


// Shared code generation methods (EmitNativeCode, MakeLocationSummary, and
// PrepareEntry). Only assembly code that can be shared across all architectures
// can be used. Machine specific register allocation and code generation
// is located in intermediate_language_<arch>.cc


// True iff. the arguments to a call will be properly pushed and can
// be popped after the call.
template <typename T> static bool VerifyCallComputation(T* comp) {
  // Argument values should be consecutive temps.
  //
  // TODO(kmillikin): implement stack height tracking so we can also assert
  // they are on top of the stack.
  intptr_t previous = -1;
  for (int i = 0; i < comp->ArgumentCount(); ++i) {
    Value* val = comp->ArgumentAt(i);
    if (!val->IsUse()) return false;
    intptr_t current = val->AsUse()->definition()->temp_index();
    if (i != 0) {
      if (current != (previous + 1)) return false;
    }
    previous = current;
  }
  return true;
}


#define __ compiler->assembler()->

void GraphEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  // Nothing to do.
}


void JoinEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetBlockLabel(this));
}


void TargetEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetBlockLabel(this));
  if (HasTryIndex()) {
    compiler->AddExceptionHandler(try_index(),
                                  compiler->assembler()->CodeSize());
  }
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  intptr_t num_temps = (class_ids() == NULL) ? 0 : 1;
  LocationSummary* summary = new LocationSummary(kNumInputs, num_temps);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (class_ids() != NULL) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyValues(instance(), value()));
  Register instance = locs()->in(0).reg();
  Register value = locs()->in(1).reg();

  if (class_ids() != NULL) {
    ASSERT(original() != NULL);
    Label* deopt = compiler->AddDeoptStub(original()->cid(),
                                          original()->token_index(),
                                          original()->try_index(),
                                          kDeoptInstanceGetterSameTarget,
                                          instance,
                                          value);
    // Smis do not have instance fields (Smi class is always first).
    Register temp = locs()->temp(0).reg();
    ASSERT(temp != instance);
    ASSERT(temp != value);
    compiler->EmitClassChecksNoSmi(*class_ids(), instance, temp, deopt);
  }
  __ StoreIntoObject(instance, FieldAddress(instance, field().Offset()),
                     value);
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  const int kNumInputs = 0;
  const int kNumTemps = 0;
  return new LocationSummary(kNumInputs, kNumTemps);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(exception()->IsUse());
  compiler->GenerateCallRuntime(cid(),
                                token_index(),
                                try_index(),
                                kThrowRuntimeEntry);
  __ int3();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  const int kNumInputs = 0;
  const int kNumTemps = 0;
  return new LocationSummary(kNumInputs, kNumTemps);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(exception()->IsUse());
  ASSERT(stack_trace()->IsUse());
  compiler->GenerateCallRuntime(cid(),
                                token_index(),
                                try_index(),
                                kReThrowRuntimeEntry);
  __ int3();
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  const int kNumInputs = 1;
  const int kNumTemps = 0;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  __ CompareObject(value,  Bool::ZoneHandle(Bool::True()));
  if (compiler->IsNextBlock(false_successor())) {
    // If the next block is the false successor we will fall through to it if
    // comparison with true fails.
    __ j(EQUAL, compiler->GetBlockLabel(true_successor()));
  } else {
    ASSERT(compiler->IsNextBlock(true_successor()));
    // If the next block is the true successor we negate comparison and fall
    // through to it.
    __ j(NOT_EQUAL, compiler->GetBlockLabel(false_successor()));
  }
}


LocationSummary* CurrentContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void CurrentContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ MoveRegister(locs()->out().reg(), CTX);
}


LocationSummary* StoreContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RegisterLocation(CTX));
  return summary;
}


void StoreContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Nothing to do.  Context register were loaded by register allocator.
  ASSERT(locs()->in(0).reg() == CTX);
}


LocationSummary* StrictCompareComp::MakeLocationSummary() const {
  return LocationSummary::Make(2, Location::SameAsFirstInput());
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();

  __ CompareRegisters(left, right);
  Label load_true, done;
  if (kind() == Token::kEQ_STRICT) {
    __ j(EQUAL, &load_true, Assembler::kNearJump);
  } else {
    ASSERT(kind() == Token::kNE_STRICT);
    __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
  }
  __ LoadObject(result, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(result, bool_true);
  __ Bind(&done);
}


void ClosureCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  Register temp_reg = locs()->temp(0).reg();
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count - 1,
                                         argument_names());
  __ LoadObject(temp_reg, arguments_descriptor);

  compiler->GenerateCall(token_index(),
                         try_index(),
                         &StubCode::CallClosureFunctionLabel(),
                         PcDescriptors::kOther);
  __ Drop(argument_count);
}


LocationSummary* InstanceCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void InstanceCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 cid(),
                                 token_index(),
                                 try_index());
  compiler->GenerateInstanceCall(cid(),
                                 token_index(),
                                 try_index(),
                                 function_name(),
                                 ArgumentCount(),
                                 argument_names(),
                                 checked_argument_count());
}


LocationSummary* StaticCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->GenerateStaticCall(cid(),
                               token_index(),
                               try_index(),
                               function(),
                               ArgumentCount(),
                               argument_names());
}


LocationSummary* UseVal::MakeLocationSummary() const {
  return NULL;
}


void UseVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void AssertAssignableComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateAssertAssignable(cid(),
                                     token_index(),
                                     try_index(),
                                     dst_type(),
                                     dst_name());
  ASSERT(locs()->in(0).reg() == locs()->out().reg());
}


LocationSummary* AssertBooleanComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::SameAsFirstInput());
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(1, 1);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void StoreStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(locs()->out().reg() == value);

  __ LoadObject(temp, field());
  __ StoreIntoObject(temp, FieldAddress(temp, Field::value_offset()), value);
}


LocationSummary* BooleanNegateComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::RequiresRegister());
}


void BooleanNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  Label done;
  __ LoadObject(result, bool_true);
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, bool_false);
  __ Bind(&done);
}


LocationSummary* ChainContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::NoLocation());
}


void ChainContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();

  // Chain the new context in context_value to its parent in CTX.
  __ StoreIntoObject(context_value,
                     FieldAddress(context_value, Context::parent_offset()),
                     CTX);
  // Set new context as current context.
  __ MoveRegister(CTX, context_value);
}


LocationSummary* StoreVMFieldComp::MakeLocationSummary() const {
  return LocationSummary::Make(2, Location::SameAsFirstInput());
}


void StoreVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value_reg = locs()->in(0).reg();
  Register dest_reg = locs()->in(1).reg();
  ASSERT(value_reg == locs()->out().reg());

  __ StoreIntoObject(dest_reg, FieldAddress(dest_reg, offset_in_bytes()),
                     value_reg);
}


LocationSummary* AllocateObjectComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &label,
                         PcDescriptors::kOther);
  __ Drop(arguments().length());  // Discard arguments.
}


LocationSummary* CreateClosureComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void CreateClosureComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Function& closure_function = function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(closure_function));
  const ExternalLabel label(closure_function.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_index(), try_index(), &label,
                         PcDescriptors::kOther);
  __ Drop(2);  // Discard type arguments and receiver.
}

#undef __

}  // namespace dart
