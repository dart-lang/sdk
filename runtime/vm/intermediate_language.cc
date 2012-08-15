// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/bit_vector.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/scopes.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);

UseVal::UseVal(Definition* definition)
    : definition_(definition), next_use_(NULL), previous_use_(NULL) {
  AddToUseList();
}


void UseVal::SetDefinition(Definition* definition) {
  ASSERT(definition != NULL);
  RemoveFromUseList();
  definition_ = definition;
  AddToUseList();
}


void UseVal::RemoveFromUseList() {
  ASSERT(definition_ != NULL);
  if (next_use_ != NULL) {
    next_use_->previous_use_ = previous_use_;
  }
  if (previous_use_ != NULL) {
    previous_use_->next_use_ = next_use_;
  } else {
    // This is the head of the list.
    ASSERT(definition_->use_list() == this);
    definition_->set_use_list(next_use_);
  }
  previous_use_ = next_use_ = NULL;
  definition_ = NULL;
}


void UseVal::AddToUseList() {
  ASSERT(next_use_ == NULL && previous_use_ == NULL && definition_ != NULL);
  UseVal* head = definition_->use_list();
  if (head != NULL) {
    next_use_ = head;
    head->previous_use_ = this;
  }
  definition_->set_use_list(this);
}


MethodRecognizer::Kind MethodRecognizer::RecognizeKind(
    const Function& function) {
  // Only core library methods can be recognized.
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Library& core_impl_lib = Library::Handle(Library::CoreImplLibrary());
  const Class& function_class = Class::Handle(function.Owner());
  if ((function_class.library() != core_lib.raw()) &&
      (function_class.library() != core_impl_lib.raw())) {
    return kUnknown;
  }
  const String& recognize_name = String::Handle(function.name());
  const String& recognize_class = String::Handle(function_class.Name());
  String& test_function_name = String::Handle();
  String& test_class_name = String::Handle();
#define RECOGNIZE_FUNCTION(class_name, function_name, enum_name)               \
  test_function_name = Symbols::New(#function_name);                           \
  test_class_name = Symbols::New(#class_name);                                 \
  if (recognize_name.Equals(test_function_name) &&                             \
      recognize_class.Equals(test_class_name)) {                               \
    return k##enum_name;                                                       \
  }
RECOGNIZED_LIST(RECOGNIZE_FUNCTION)
#undef RECOGNIZE_FUNCTION
  return kUnknown;
}


const char* MethodRecognizer::KindToCString(Kind kind) {
#define KIND_TO_STRING(class_name, function_name, enum_name)                   \
  if (kind == k##enum_name) return #enum_name;
RECOGNIZED_LIST(KIND_TO_STRING)
#undef KIND_TO_STRING
  return "?";
}


// ==== Support for visiting flow graphs.
#define DEFINE_ACCEPT(ShortName, ClassName)                                    \
void ClassName::Accept(FlowGraphVisitor* visitor, BindInstr* instr) {          \
  visitor->Visit##ShortName(this, instr);                                      \
}

FOR_EACH_COMPUTATION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


#define DEFINE_ACCEPT(ShortName)                                               \
void ShortName##Instr::Accept(FlowGraphVisitor* visitor) {                     \
  visitor->Visit##ShortName(this);                                             \
}

FOR_EACH_INSTRUCTION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


Instruction* Instruction::RemoveFromGraph(bool return_previous) {
  ASSERT(!IsBlockEntry());
  ASSERT(!IsBranch());
  ASSERT(!IsThrow());
  ASSERT(!IsReturn());
  ASSERT(!IsReThrow());
  ASSERT(!IsGoto());
  ASSERT(previous() != NULL);
  Instruction* prev_instr = previous();
  Instruction* next_instr = next();
  ASSERT(next_instr != NULL);
  ASSERT(!next_instr->IsBlockEntry());
  prev_instr->set_next(next_instr);
  next_instr->set_previous(prev_instr);
  // Reset successor and previous instruction to indicate
  // that the instruction is removed from the graph.
  set_previous(NULL);
  set_next(NULL);
  return return_previous ? prev_instr : next_instr;
}


void ForwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(true);  // Set current_ to previous.
}


// Default implementation of visiting basic blocks.  Can be overridden.
void FlowGraphVisitor::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      it.Current()->Accept(this);
    }
  }
}


// Returns true if the compile type of this value is more specific than the
// given dst_type.
// TODO(regis): Support a set of compile types for the given value.
bool Value::CompileTypeIsMoreSpecificThan(const AbstractType& dst_type) const {
  ASSERT(!dst_type.IsMalformed());  // Should be tested by caller.
  ASSERT(!dst_type.IsDynamicType());  // Should be tested by caller.
  ASSERT(!dst_type.IsObjectType());  // Should be tested by caller.

  // If the value is the null constant, its type (NullType) is more specific
  // than the destination type, even if the destination type is the void type,
  // since a void function is allowed to return null.
  if (IsConstant() && AsConstant()->value().IsNull()) {
    return true;
  }

  // Functions that do not explicitly return a value, implicitly return null,
  // except generative constructors, which return the object being constructed.
  // It is therefore acceptable for void functions to return null.
  // In case of a null constant, we have already returned true above, else we
  // return false here.
  if (dst_type.IsVoidType()) {
    return false;
  }

  // Consider the compile type of the value.
  const AbstractType& compile_type = AbstractType::Handle(CompileType());
  ASSERT(!compile_type.IsMalformed());

  // If the compile type of the value is void, we are type checking the result
  // of a void function, which was checked to be null at the return statement
  // inside the function.
  if (compile_type.IsVoidType()) {
    return true;
  }

  // If the compile type of the value is NullType, the type test is eliminated.
  // There are only three instances that can be of Class Null:
  // Object::null(), Object::sentinel(), and Object::transition_sentinel().
  // The inline code and run time code performing the type check will never
  // encounter the 2 sentinel values. The type check of a sentinel value
  // will always be eliminated here, because these sentinel values can only
  // be encountered as constants, never as actual value of a heap object
  // being type checked.
  if (compile_type.IsNullType()) {
    return true;
  }

  // The run time type of the value is guaranteed to be a subtype of the
  // compile time type of the value. However, establishing here that
  // the compile time type is a subtype of the destination type does not
  // guarantee that the run time type will also be a subtype of the destination
  // type, because the subtype relation is not transitive.
  // However, the 'more specific than' relation is transitive and is used
  // here. In other words, if the compile type of the value is more specific
  // than the destination type, the run time type of the value, which is
  // guaranteed to be a subtype of the compile type, is also guaranteed to be
  // a subtype of the destination type and the type check can therefore be
  // eliminated.
  return compile_type.IsMoreSpecificThan(dst_type, NULL);
}


RawAbstractType* PhiInstr::CompileType() const {
  ASSERT(!HasPropagatedType());
  // Since type propagation has not yet occured, we are reaching this phi via a
  // back edge phi input. Return null as compile type so that this input is
  // ignored in the first iteration of type propagation.
  return AbstractType::null();
}


RawAbstractType* PhiInstr::LeastSpecificInputType() const {
  AbstractType& least_specific_type = AbstractType::Handle();
  AbstractType& input_type = AbstractType::Handle();
  for (intptr_t i = 0; i < InputCount(); i++) {
    input_type = InputAt(i)->CompileType();
    if (input_type.IsNull()) {
      // This input is on a back edge and we are in the first iteration of type
      // propagation. Ignore it.
      continue;
    }
    ASSERT(!input_type.IsNull());
    if (least_specific_type.IsNull() ||
        least_specific_type.IsMoreSpecificThan(input_type, NULL)) {
      // Type input_type is less specific than the current least_specific_type.
      least_specific_type = input_type.raw();
    } else if (input_type.IsMoreSpecificThan(least_specific_type, NULL)) {
      // Type least_specific_type is less specific than input_type. No change.
    } else {
      // The types are unrelated. No need to continue.
      least_specific_type = Type::ObjectType();
      break;
    }
  }
  return least_specific_type.raw();
}


RawAbstractType* ParameterInstr::CompileType() const {
  ASSERT(!HasPropagatedType());
  // Note that returning the declared type of the formal parameter would be
  // incorrect, because ParameterInstr is used as input to the type check
  // verifying the run time type of the passed-in parameter and this check would
  // always be wrongly eliminated.
  return Type::DynamicType();
}


RawAbstractType* PushArgumentInstr::CompileType() const {
  return AbstractType::null();
}


intptr_t JoinEntryInstr::IndexOfPredecessor(BlockEntryInstr* pred) const {
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (predecessors_[i] == pred) return i;
  }
  return -1;
}


// ==== Recording assigned variables.
void Computation::RecordAssignedVars(BitVector* assigned_vars,
                                     intptr_t fixed_parameter_count) {
  // Nothing to do for the base class.
}


void StoreLocalComp::RecordAssignedVars(BitVector* assigned_vars,
                                        intptr_t fixed_parameter_count) {
  if (!local().is_captured()) {
    assigned_vars->Add(local().BitIndexIn(fixed_parameter_count));
  }
}


void Instruction::RecordAssignedVars(BitVector* assigned_vars,
                                     intptr_t fixed_parameter_count) {
  // Nothing to do for the base class.
}


void Definition::ReplaceUsesWith(Definition* other) {
  UseVal* head = use_list();
  if (head == NULL) return;

  UseVal* current = head;
  while (current->next_use() != NULL) {
    current->definition_ = other;
    current = current->next_use();
  }
  current->definition_ = other;

  if (other->use_list() != NULL) {
    current->next_use_ = other->use_list();
    other->use_list()->previous_use_ = current;
  }
  other->set_use_list(head);
  set_use_list(NULL);
}


RawAbstractType* BindInstr::CompileType() const {
  ASSERT(!HasPropagatedType());
  // The compile type may be requested when building the flow graph, i.e. before
  // type propagation has occurred.
  return computation()->CompileType();
}


void BindInstr::RecordAssignedVars(BitVector* assigned_vars,
                                   intptr_t fixed_parameter_count) {
  computation()->RecordAssignedVars(assigned_vars, fixed_parameter_count);
}


// ==== Postorder graph traversal.
void GraphEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* assigned_vars,
    intptr_t variable_count,
    intptr_t fixed_parameter_count) {
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
                                      parent, assigned_vars,
                                      variable_count, fixed_parameter_count);
  }
  normal_entry_->DiscoverBlocks(this, preorder, postorder,
                                parent, assigned_vars,
                                variable_count, fixed_parameter_count);

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
    intptr_t variable_count,
    intptr_t fixed_parameter_count) {
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

  // 3. The current block is the spanning-tree parent.
  parent->Add(current_block->preorder_number());

  // 4. Assign preorder number and add the block entry to the list.
  // Allocate an empty set of assigned variables for the block.
  set_preorder_number(preorder->length());
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
  ASSERT(next() != NULL);
  ASSERT(!next()->IsBlockEntry());
  Instruction* next_instr = next();
  while ((next_instr != NULL) &&
         !next_instr->IsBlockEntry() &&
         !next_instr->IsBranch()) {
    if (vars != NULL) {
      next_instr->RecordAssignedVars(vars, fixed_parameter_count);
    }
    set_last_instruction(next_instr);
    GotoInstr* goto_instr = next_instr->AsGoto();
    next_instr =
        (goto_instr != NULL) ? goto_instr->successor() : next_instr->next();
  }
  if (next_instr != NULL) {
    next_instr->DiscoverBlocks(this, preorder, postorder,
                               parent, assigned_vars,
                               variable_count, fixed_parameter_count);
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
    intptr_t variable_count,
    intptr_t fixed_parameter_count) {
  current_block->set_last_instruction(this);
  // Visit the false successor before the true successor so they appear in
  // true/false order in reverse postorder used as the block ordering in the
  // nonoptimizing compiler.
  ASSERT(true_successor_ != NULL);
  ASSERT(false_successor_ != NULL);
  false_successor_->DiscoverBlocks(current_block, preorder, postorder,
                                   parent, assigned_vars,
                                   variable_count, fixed_parameter_count);
  true_successor_->DiscoverBlocks(current_block, preorder, postorder,
                                  parent, assigned_vars,
                                  variable_count, fixed_parameter_count);
}


void JoinEntryInstr::InsertPhi(intptr_t var_index, intptr_t var_count) {
  // Lazily initialize the array of phis.
  // Currently, phis are stored in a sparse array that holds the phi
  // for variable with index i at position i.
  // TODO(fschneider): Store phis in a more compact way.
  if (phis_ == NULL) {
    phis_ = new ZoneGrowableArray<PhiInstr*>(var_count);
    for (intptr_t i = 0; i < var_count; i++) {
      phis_->Add(NULL);
    }
  }
  ASSERT((*phis_)[var_index] == NULL);
  (*phis_)[var_index] = new PhiInstr(PredecessorCount());
  phi_count_++;
}


void JoinEntryInstr::RemoveDeadPhis() {
  if (phis_ == NULL) return;

  for (intptr_t i = 0; i < phis_->length(); i++) {
    PhiInstr* phi = (*phis_)[i];
    if ((phi != NULL) && !phi->is_alive()) {
      (*phis_)[i] = NULL;
      phi_count_--;
    }
  }

  // Check if we removed all phis.
  if (phi_count_ == 0) phis_ = NULL;
}


intptr_t Instruction::SuccessorCount() const {
  return 0;
}


BlockEntryInstr* Instruction::SuccessorAt(intptr_t index) const {
  // Called only if index is in range.  Only control-transfer instructions
  // can have non-zero successor counts and they override this function.
  UNREACHABLE();
  return NULL;
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


intptr_t GotoInstr::SuccessorCount() const {
  return 1;
}


BlockEntryInstr* GotoInstr::SuccessorAt(intptr_t index) const {
  ASSERT(index == 0);
  return successor();
}


void Instruction::Goto(JoinEntryInstr* entry) {
  set_next(new GotoInstr(entry));
}


RawAbstractType* ConstantVal::CompileType() const {
  if (value().IsNull()) {
    return Type::NullType();
  }
  if (value().IsInstance()) {
    return Instance::Cast(value()).GetType();
  } else {
    ASSERT(value().IsAbstractTypeArguments());
    return AbstractType::null();
  }
}


RawAbstractType* UseVal::CompileType() const {
  if (definition()->HasPropagatedType()) {
    return definition()->PropagatedType();
  }
  // The compile type may be requested when building the flow graph, i.e. before
  // type propagation has occurred. To avoid repeatedly computing the compile
  // type of the definition, we store it as initial propagated type.
  AbstractType& type = AbstractType::Handle(definition()->CompileType());
  definition()->SetPropagatedType(type);
  return type.raw();
}


RawAbstractType* AssertAssignableComp::CompileType() const {
  const AbstractType& value_compile_type =
      AbstractType::Handle(value()->CompileType());
  if (!value_compile_type.IsNull() &&
      value_compile_type.IsMoreSpecificThan(dst_type(), NULL)) {
    return value_compile_type.raw();
  }
  return dst_type().raw();
}


RawAbstractType* AssertBooleanComp::CompileType() const {
  return Type::BoolInterface();
}


RawAbstractType* CurrentContextComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* StoreContextComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ClosureCallComp::CompileType() const {
  // Because of function subtyping rules, the declared return type of a closure
  // call cannot be relied upon for compile type analysis. For example, a
  // function returning Dynamic can be assigned to a closure variable declared
  // to return int and may actually return a double at run-time.
  return Type::DynamicType();
}


RawAbstractType* InstanceCallComp::CompileType() const {
  // TODO(regis): Return a more specific type than Dynamic for recognized
  // combinations of receiver type and method name.
  return Type::DynamicType();
}


RawAbstractType* PolymorphicInstanceCallComp::CompileType() const {
  return Type::DynamicType();
}


RawAbstractType* StaticCallComp::CompileType() const {
  return function().result_type();
}


RawAbstractType* LoadLocalComp::CompileType() const {
  if (FLAG_enable_type_checks) {
    return local().type().raw();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreLocalComp::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* StrictCompareComp::CompileType() const {
  return Type::BoolInterface();
}


// Only known == targets return a Boolean.
RawAbstractType* EqualityCompareComp::CompileType() const {
  if ((receiver_class_id() == kSmiCid) ||
      (receiver_class_id() == kDoubleCid) ||
      (receiver_class_id() == kNumberCid)) {
    return Type::BoolInterface();
  }
  if (HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid)) {
    return Type::BoolInterface();
  }
  return Type::DynamicType();
}


RawAbstractType* RelationalOpComp::CompileType() const {
  if ((operands_class_id() == kSmiCid) ||
      (operands_class_id() == kDoubleCid) ||
      (operands_class_id() == kNumberCid)) {
    return Type::BoolInterface();
  }
  return Type::DynamicType();
}


RawAbstractType* NativeCallComp::CompileType() const {
  // The result type of the native function is identical to the result type of
  // the enclosing native Dart function. However, we prefer to check the type
  // of the value returned from the native call.
  return Type::DynamicType();
}


RawAbstractType* LoadIndexedComp::CompileType() const {
  return Type::DynamicType();
}


RawAbstractType* StoreIndexedComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* LoadInstanceFieldComp::CompileType() const {
  if (FLAG_enable_type_checks) {
    return field().type();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreInstanceFieldComp::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* LoadStaticFieldComp::CompileType() const {
  if (FLAG_enable_type_checks) {
    return field().type();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreStaticFieldComp::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* BooleanNegateComp::CompileType() const {
  return Type::BoolInterface();
}


RawAbstractType* InstanceOfComp::CompileType() const {
  return Type::BoolInterface();
}


RawAbstractType* CreateArrayComp::CompileType() const {
  // TODO(regis): Be more specific.
  return Type::DynamicType();
}


RawAbstractType* CreateClosureComp::CompileType() const {
  const Function& fun = function();
  const Class& signature_class = Class::Handle(fun.signature_class());
  return signature_class.SignatureType();
}


RawAbstractType* AllocateObjectComp::CompileType() const {
  // TODO(regis): Be more specific.
  return Type::DynamicType();
}


RawAbstractType* AllocateObjectWithBoundsCheckComp::CompileType() const {
  // TODO(regis): Be more specific.
  return Type::DynamicType();
}


RawAbstractType* LoadVMFieldComp::CompileType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  return type().raw();
}


RawAbstractType* StoreVMFieldComp::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* InstantiateTypeArgumentsComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorTypeArgumentsComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorInstantiatorComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* AllocateContextComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ChainContextComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CloneContextComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CatchEntryComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CheckStackOverflowComp::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* BinaryOpComp::CompileType() const {
  // TODO(srdjan): Convert to use with class-ids instead of types.
  if (operands_type() == kMintOperands) {
    return Isolate::Current()->object_store()->mint_type();
  } else if (op_kind() == Token::kSHL) {
    return Type::IntInterface();
  } else {
    ASSERT(operands_type() == kSmiOperands);
    return Isolate::Current()->object_store()->smi_type();
  }
}


RawAbstractType* DoubleBinaryOpComp::CompileType() const {
  return Type::DoubleInterface();
}


RawAbstractType* UnarySmiOpComp::CompileType() const {
  return Type::IntInterface();
}


RawAbstractType* NumberNegateComp::CompileType() const {
  return Type::NumberInterface();
}


RawAbstractType* DoubleToDoubleComp::CompileType() const {
  return Type::DoubleInterface();
}


RawAbstractType* SmiToDoubleComp::CompileType() const {
  return Type::DoubleInterface();
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
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


void TargetEntryInstr::PrepareEntry(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetBlockLabel(this));
  if (HasTryIndex()) {
    compiler->AddExceptionHandler(try_index(),
                                  compiler->assembler()->CodeSize());
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t num_temps = HasICData() ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (HasICData()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register value_reg = locs()->in(1).reg();

  if (HasICData()) {
    ASSERT(original() != NULL);
    Label* deopt = compiler->AddDeoptStub(original()->deopt_id(),
                                          original()->try_index(),
                                          kDeoptInstanceGetterSameTarget,
                                          instance_reg,
                                          value_reg);
    // Smis do not have instance fields (Smi class is always first).
    Register temp_reg = locs()->temp(0).reg();
    ASSERT(temp_reg != instance_reg);
    ASSERT(temp_reg != value_reg);
    ASSERT(ic_data() != NULL);
    compiler->EmitClassChecksNoSmi(*ic_data(), instance_reg, temp_reg, deopt);
  }
  __ StoreIntoObject(instance_reg, FieldAddress(instance_reg, field().Offset()),
                     value_reg);
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(deopt_id(),
                                token_pos(),
                                try_index(),
                                kThrowRuntimeEntry,
                                locs()->stack_bitmap());
  __ int3();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(deopt_id(),
                                token_pos(),
                                try_index(),
                                kReThrowRuntimeEntry,
                                locs()->stack_bitmap());
  __ int3();
}


LocationSummary* GotoInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // We can fall through if the successor is the next block in the list.
  // Otherwise, we need a jump.
  if (!compiler->IsNextBlock(successor())) {
    __ jmp(compiler->GetBlockLabel(successor()));
  }
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQUAL:         return NOT_EQUAL;
    case NOT_EQUAL:     return EQUAL;
    case LESS:          return GREATER_EQUAL;
    case LESS_EQUAL:    return GREATER;
    case GREATER:       return LESS_EQUAL;
    case GREATER_EQUAL: return LESS;
    case BELOW:         return ABOVE_EQUAL;
    case BELOW_EQUAL:   return ABOVE;
    case ABOVE:         return BELOW_EQUAL;
    case ABOVE_EQUAL:   return BELOW;
    default:
      OS::Print("Error %d\n", condition);
      UNIMPLEMENTED();
      return EQUAL;
  }
}


void BranchInstr::EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                        Condition true_condition) {
  if (compiler->IsNextBlock(false_successor())) {
    // If the next block is the false successor we will fall through to it.
    __ j(true_condition, compiler->GetBlockLabel(true_successor()));
  } else {
    // If the next block is the true successor we negate comparison and fall
    // through to it.
    ASSERT(compiler->IsNextBlock(true_successor()));
    Condition false_condition = NegateCondition(true_condition);
    __ j(false_condition, compiler->GetBlockLabel(false_successor()));
  }
}


LocationSummary* CurrentContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ MoveRegister(locs()->out().reg(), CTX);
}


LocationSummary* StoreContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterLocation(CTX));
  return summary;
}


void StoreContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Nothing to do.  Context register were loaded by register allocator.
  ASSERT(locs()->in(0).reg() == CTX);
}


Definition* StrictCompareComp::TryReplace(BindInstr* instr) {
  // TODO(srdjan): Do not use CompileType for class check elimination.
  return NULL;
  UseVal* left_use = left()->AsUse();
  UseVal* right_use = right()->AsUse();
  if ((right_use == NULL) || (left_use == NULL)) return NULL;
  Definition* left = left_use->definition();
  BindInstr* right = right_use->definition()->AsBind();
  if (right == NULL) return NULL;
  ConstantVal* right_constant = right->computation()->AsConstant();
  if (right_constant == NULL) return NULL;
  // TODO(fschneider): Handle other cases: e === false and e !== true/false.
  // Handles e === true.
  if ((kind() == Token::kEQ_STRICT) &&
      (right_constant->value().raw() == Bool::True()) &&
      left_use->CompileTypeIsMoreSpecificThan(
          Type::Handle(Type::BoolInterface()))) {
    // Remove the constant from the graph.
    right->RemoveFromGraph();
    // Return left subexpression as the replacement for this instruction.
    return left;
  }
  return NULL;
}


LocationSummary* StrictCompareComp::MakeLocationSummary() const {
  return LocationSummary::Make(2,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();

  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQUAL : NOT_EQUAL;
  __ CompareRegisters(left, right);

  Register result = locs()->out().reg();
  Label load_true, done;
  __ j(true_condition, &load_true, Assembler::kNearJump);
  __ LoadObject(result, compiler->bool_false());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(result, compiler->bool_true());
  __ Bind(&done);
}


void ClosureCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  Register temp_reg = locs()->temp(0).reg();
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count - 1,
                                         argument_names());
  __ LoadObject(temp_reg, arguments_descriptor);

  compiler->GenerateCall(token_pos(),
                         try_index(),
                         &StubCode::CallClosureFunctionLabel(),
                         PcDescriptors::kOther,
                         locs()->stack_bitmap());
  __ Drop(argument_count);
}


LocationSummary* InstanceCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void InstanceCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 deopt_id(),
                                 token_pos(),
                                 try_index());
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 try_index(),
                                 function_name(),
                                 ArgumentCount(),
                                 argument_names(),
                                 checked_argument_count(),
                                 locs()->stack_bitmap());
}


LocationSummary* StaticCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label done;
  if (recognized() == MethodRecognizer::kMathSqrt) {
    compiler->GenerateInlinedMathSqrt(&done);
    // Falls through to static call when operand type is not double or smi.
  }
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               try_index(),
                               function(),
                               ArgumentCount(),
                               argument_names(),
                               locs()->stack_bitmap());
  __ Bind(&done);
}


LocationSummary* UseVal::MakeLocationSummary() const {
  return NULL;
}


void UseVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void AssertAssignableComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!is_eliminated()) {
    compiler->GenerateAssertAssignable(deopt_id(),
                                       token_pos(),
                                       try_index(),
                                       dst_type(),
                                       dst_name(),
                                       locs()->stack_bitmap());
  }
  ASSERT(locs()->in(0).reg() == locs()->out().reg());
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(1, 1, LocationSummary::kNoCall);
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
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Label done;
  __ LoadObject(result, compiler->bool_true());
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, compiler->bool_false());
  __ Bind(&done);
}


LocationSummary* ChainContextComp::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::NoLocation(),
                               LocationSummary::kNoCall);
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
  return LocationSummary::Make(2,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
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
  const Class& cls = Class::ZoneHandle(constructor().Owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         try_index(),
                         &label,
                         PcDescriptors::kOther,
                         locs()->stack_bitmap());
  __ Drop(ArgumentCount());  // Discard arguments.
}


LocationSummary* CreateClosureComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void CreateClosureComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Function& closure_function = function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(closure_function));
  const ExternalLabel label(closure_function.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(), try_index(), &label,
                         PcDescriptors::kOther,
                         locs()->stack_bitmap());
  __ Drop(2);  // Discard type arguments and receiver.
}


LocationSummary* PushArgumentInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps= 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // TODO(fschneider): Use Any() once it is supported by all code generators.
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where PushArgument is handled in FrameRegisterAllocator::AllocateRegisters.
  // Instead of popping the value it is left alone on the simulated frame
  // and materialized on the physical stack before the call.
  // TODO(fschneider): Avoid special-casing for SSA mode here.
  if (compiler->is_ssa()) {
    ASSERT(locs()->in(0).IsRegister());
    __ PushRegister(locs()->in(0).reg());
  }
}


#undef __

}  // namespace dart
