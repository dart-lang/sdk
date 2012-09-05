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


intptr_t Definition::Hashcode() const {
  intptr_t result = tag();
  for (intptr_t i = 0; i < InputCount(); ++i) {
    Value* value = InputAt(i);
    intptr_t j = value->definition()->ssa_temp_index();
    result = result * 31 + j;
  }
  return result;
}


bool Definition::Equals(Definition* other) const {
  if (tag() != other->tag()) return false;
  for (intptr_t i = 0; i < InputCount(); ++i) {
    if (!InputAt(i)->Equals(other->InputAt(i))) return false;
  }
  return AttributesEqual(other);
}


bool Value::Equals(Value* other) const {
  return definition() == other->definition();
}


bool CheckClassInstr::AttributesEqual(Definition* other) const {
  CheckClassInstr* other_check = other->AsCheckClass();
  ASSERT(other_check != NULL);
  if (unary_checks().NumberOfChecks() !=
      other_check->unary_checks().NumberOfChecks()) {
    return false;
  }
  for (intptr_t i = 0; i < unary_checks().NumberOfChecks(); ++i) {
    // TODO(fschneider): Make sure ic_data are sorted to hit more cases.
    if (unary_checks().GetReceiverClassIdAt(i) !=
        other_check->unary_checks().GetReceiverClassIdAt(i)) {
      return false;
    }
  }
  return true;
}


bool CheckArrayBoundInstr::AttributesEqual(Definition* other) const {
  CheckArrayBoundInstr* other_check = other->AsCheckArrayBound();
  ASSERT(other_check != NULL);
  return array_type() == other_check->array_type();
}


// Returns true if the value represents a constant.
bool Value::BindsToConstant() const {
  return definition()->IsConstant();
}


// Returns true if the value represents constant null.
bool Value::BindsToConstantNull() const {
  ConstantInstr* constant = definition()->AsConstant();
  return (constant != NULL) && constant->value().IsNull();
}


const Object& Value::BoundConstant() const {
  ASSERT(BindsToConstant());
  ConstantInstr* constant = definition()->AsConstant();
  ASSERT(constant != NULL);
  return constant->value();
}


bool ConstantInstr::AttributesEqual(Definition* other) const {
  ConstantInstr* other_constant = other->AsConstant();
  ASSERT(other_constant != NULL);
  return (value().raw() == other_constant->value().raw());
}


GraphEntryInstr::GraphEntryInstr(TargetEntryInstr* normal_entry)
    : BlockEntryInstr(CatchClauseNode::kInvalidTryIndex),
      normal_entry_(normal_entry),
      catch_entries_(),
      start_env_(NULL),
      constant_null_(new ConstantInstr(Object::ZoneHandle())),
      spill_slot_count_(0) {
}


MethodRecognizer::Kind MethodRecognizer::RecognizeKind(
    const Function& function) {
  // Only core and math library methods can be recognized.
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Library& core_impl_lib = Library::Handle(Library::CoreImplLibrary());
  const Library& math_lib = Library::Handle(Library::MathLibrary());
  const Class& function_class = Class::Handle(function.Owner());
  if ((function_class.library() != core_lib.raw()) &&
      (function_class.library() != core_impl_lib.raw()) &&
      (function_class.library() != math_lib.raw())) {
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
#define DEFINE_ACCEPT(ShortName)                                               \
void ShortName##Instr::Accept(FlowGraphVisitor* visitor) {                     \
  visitor->Visit##ShortName(this);                                             \
}

FOR_EACH_INSTRUCTION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


Instruction* Instruction::RemoveFromGraph(bool return_previous) {
  ASSERT(!IsBlockEntry());
  ASSERT(!IsControl());
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


void Definition::InsertBefore(Instruction* next) {
  ASSERT(previous_ == NULL);
  ASSERT(next_ == NULL);
  next_ = next;
  previous_ = next->previous_;
  next->previous_ = this;
  previous_->next_ = this;
}


void Definition::InsertAfter(Instruction* prev) {
  ASSERT(previous_ == NULL);
  ASSERT(next_ == NULL);
  previous_ = prev;
  next_ = prev->next_;
  next_->previous_ = this;
  previous_->next_ = this;
}


void ForwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(true);  // Set current_ to previous.
}


void ForwardInstructionIterator::ReplaceCurrentWith(Definition* other) {
  Definition* defn = current_->AsDefinition();
  ASSERT(defn != NULL);
  defn->ReplaceUsesWith(other);
  ASSERT(other->env() == NULL);
  other->set_env(defn->env());
  defn->set_env(NULL);
  ASSERT(!other->HasSSATemp());
  if (defn->HasSSATemp()) other->set_ssa_temp_index(defn->ssa_temp_index());

  other->InsertBefore(current_);  // So other will be current.
  RemoveCurrentFromGraph();
}


// Default implementation of visiting basic blocks.  Can be overridden.
void FlowGraphVisitor::VisitBlocks() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    entry->Accept(this);
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      it.Current()->Accept(this);
    }
    current_iterator_ = NULL;
  }
}


// Returns true if the compile type of this value is more specific than the
// given dst_type.
// TODO(regis): Support a set of compile types for the given value.
bool Value::CompileTypeIsMoreSpecificThan(const AbstractType& dst_type) const {
  // No type is more specific than a malformed type.
  if (dst_type.IsMalformed()) {
    return false;
  }

  // If the value is the null constant, its type (NullType) is more specific
  // than the destination type, even if the destination type is the void type,
  // since a void function is allowed to return null.
  if (BindsToConstantNull()) {
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


bool Value::NeedsStoreBuffer() const {
  const intptr_t cid = ResultCid();
  if ((cid == kSmiCid) || (cid == kBoolCid) || (cid == kNullCid)) {
    return false;
  }
  return !BindsToConstant();
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
void Definition::RecordAssignedVars(BitVector* assigned_vars,
                                    intptr_t fixed_parameter_count) {
  // Nothing to do for the base class.
}


void StoreLocalInstr::RecordAssignedVars(BitVector* assigned_vars,
                                         intptr_t fixed_parameter_count) {
  if (!local().is_captured()) {
    assigned_vars->Add(local().BitIndexIn(fixed_parameter_count));
  }
}


void Instruction::RecordAssignedVars(BitVector* assigned_vars,
                                     intptr_t fixed_parameter_count) {
  // Nothing to do for the base class.
}


void Value::AddToInputUseList() {
  set_next_use(definition()->input_use_list());
  definition()->set_input_use_list(this);
}


void Value::AddToEnvUseList() {
  set_next_use(definition()->env_use_list());
  definition()->set_env_use_list(this);
}


void Definition::ReplaceUsesWith(Definition* other) {
  ASSERT(other != NULL);
  ASSERT(this != other);
  while (input_use_list_ != NULL) {
    Value* current = input_use_list_;
    input_use_list_ = input_use_list_->next_use();
    current->set_definition(other);
    current->AddToInputUseList();
  }
  while (env_use_list_ != NULL) {
    Value* current = env_use_list_;
    env_use_list_ = env_use_list_->next_use();
    current->set_definition(other);
    current->AddToEnvUseList();
  }
}


void Definition::ReplaceWith(Definition* other,
                             ForwardInstructionIterator* iterator) {
  if ((iterator != NULL) && (other == iterator->Current())) {
    iterator->ReplaceCurrentWith(other);
  } else {
    ReplaceUsesWith(other);
    ASSERT(other->env() == NULL);
    other->set_env(env());
    set_env(NULL);
    ASSERT(!other->HasSSATemp());
    if (HasSSATemp()) other->set_ssa_temp_index(ssa_temp_index());

    other->set_previous(previous());
    previous()->set_next(other);
    set_previous(NULL);

    other->set_next(next());
    next()->set_previous(other);
    set_next(NULL);
  }
}


bool Definition::SetPropagatedCid(intptr_t cid) {
  if (cid == kIllegalCid) {
    return false;
  }
  if (propagated_cid_ == kIllegalCid) {
    // First setting, nothing has changed.
    propagated_cid_ = cid;
    return false;
  }
  bool has_changed = (propagated_cid_ != cid);
  propagated_cid_ = cid;
  return has_changed;
}


intptr_t Definition::GetPropagatedCid() {
  if (has_propagated_cid()) return propagated_cid();
  intptr_t cid = ResultCid();
  ASSERT(cid != kIllegalCid);
  SetPropagatedCid(cid);
  return cid;
}


intptr_t PhiInstr::GetPropagatedCid() {
  return propagated_cid();
}


intptr_t ParameterInstr::GetPropagatedCid() {
  return propagated_cid();
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
         !next_instr->IsControl()) {
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


void ControlInstruction::DiscoverBlocks(
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
  (*phis_)[var_index] = new PhiInstr(this, PredecessorCount());
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


intptr_t ControlInstruction::SuccessorCount() const {
  return 2;
}


BlockEntryInstr* ControlInstruction::SuccessorAt(intptr_t index) const {
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


RawAbstractType* Value::CompileType() const {
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


intptr_t Value::ResultCid() const {
  return definition()->GetPropagatedCid();
}



RawAbstractType* ConstantInstr::CompileType() const {
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


intptr_t ConstantInstr::ResultCid() const {
  if (value().IsNull()) {
    return kNullCid;
  }
  if (value().IsInstance()) {
    return Class::Handle(value().clazz()).id();
  } else {
    ASSERT(value().IsAbstractTypeArguments());
    return kDynamicCid;
  }
}


RawAbstractType* AssertAssignableInstr::CompileType() const {
  const AbstractType& value_compile_type =
      AbstractType::Handle(value()->CompileType());
  if (!value_compile_type.IsNull() &&
      value_compile_type.IsMoreSpecificThan(dst_type(), NULL)) {
    return value_compile_type.raw();
  }
  return dst_type().raw();
}


RawAbstractType* AssertBooleanInstr::CompileType() const {
  return Type::BoolType();
}


RawAbstractType* ArgumentDefinitionTestInstr::CompileType() const {
  return Type::BoolType();
}


RawAbstractType* CurrentContextInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* StoreContextInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ClosureCallInstr::CompileType() const {
  // Because of function subtyping rules, the declared return type of a closure
  // call cannot be relied upon for compile type analysis. For example, a
  // function returning Dynamic can be assigned to a closure variable declared
  // to return int and may actually return a double at run-time.
  return Type::DynamicType();
}


RawAbstractType* InstanceCallInstr::CompileType() const {
  // TODO(regis): Return a more specific type than Dynamic for recognized
  // combinations of receiver type and method name.
  return Type::DynamicType();
}


RawAbstractType* PolymorphicInstanceCallInstr::CompileType() const {
  return Type::DynamicType();
}


RawAbstractType* StaticCallInstr::CompileType() const {
  if (FLAG_enable_type_checks) {
    return function().result_type();
  }
  return Type::DynamicType();
}


RawAbstractType* LoadLocalInstr::CompileType() const {
  if (FLAG_enable_type_checks) {
    return local().type().raw();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreLocalInstr::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* StrictCompareInstr::CompileType() const {
  return Type::BoolType();
}


// Only known == targets return a Boolean.
RawAbstractType* EqualityCompareInstr::CompileType() const {
  if ((receiver_class_id() == kSmiCid) ||
      (receiver_class_id() == kDoubleCid) ||
      (receiver_class_id() == kNumberCid)) {
    return Type::BoolType();
  }
  return Type::DynamicType();
}


intptr_t EqualityCompareInstr::ResultCid() const {
  if ((receiver_class_id() == kSmiCid) ||
      (receiver_class_id() == kDoubleCid) ||
      (receiver_class_id() == kNumberCid)) {
    // Known/library equalities that are guaranteed to return Boolean.
    return kBoolCid;
  }
  return kDynamicCid;
}


RawAbstractType* RelationalOpInstr::CompileType() const {
  if ((operands_class_id() == kSmiCid) ||
      (operands_class_id() == kDoubleCid) ||
      (operands_class_id() == kNumberCid)) {
    // Known/library relational ops that are guaranteed to return Boolean.
    return Type::BoolType();
  }
  return Type::DynamicType();
}


intptr_t RelationalOpInstr::ResultCid() const {
  if ((operands_class_id() == kSmiCid) ||
      (operands_class_id() == kDoubleCid) ||
      (operands_class_id() == kNumberCid)) {
    // Known/library relational ops that are guaranteed to return Boolean.
    return kBoolCid;
  }
  return kDynamicCid;
}


RawAbstractType* NativeCallInstr::CompileType() const {
  // The result type of the native function is identical to the result type of
  // the enclosing native Dart function. However, we prefer to check the type
  // of the value returned from the native call.
  return Type::DynamicType();
}


RawAbstractType* LoadIndexedInstr::CompileType() const {
  return Type::DynamicType();
}


RawAbstractType* StoreIndexedInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* LoadInstanceFieldInstr::CompileType() const {
  if (FLAG_enable_type_checks) {
    return field().type();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreInstanceFieldInstr::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* LoadStaticFieldInstr::CompileType() const {
  if (FLAG_enable_type_checks) {
    return field().type();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreStaticFieldInstr::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* BooleanNegateInstr::CompileType() const {
  return Type::BoolType();
}


RawAbstractType* InstanceOfInstr::CompileType() const {
  return Type::BoolType();
}


RawAbstractType* CreateArrayInstr::CompileType() const {
  return type().raw();
}


RawAbstractType* CreateClosureInstr::CompileType() const {
  const Function& fun = function();
  const Class& signature_class = Class::Handle(fun.signature_class());
  return signature_class.SignatureType();
}


RawAbstractType* AllocateObjectInstr::CompileType() const {
  // TODO(regis): Be more specific.
  return Type::DynamicType();
}


RawAbstractType* AllocateObjectWithBoundsCheckInstr::CompileType() const {
  // TODO(regis): Be more specific.
  return Type::DynamicType();
}


RawAbstractType* LoadVMFieldInstr::CompileType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  // Keep it as null for debug purposes and do not return Dynamic in production
  // mode, since misuse of the type would remain undetected.
  if (type().IsNull()) {
    return AbstractType::null();
  }
  if (FLAG_enable_type_checks) {
    return type().raw();
  }
  return Type::DynamicType();
}


RawAbstractType* StoreVMFieldInstr::CompileType() const {
  return value()->CompileType();
}


RawAbstractType* InstantiateTypeArgumentsInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorTypeArgumentsInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ExtractConstructorInstantiatorInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* AllocateContextInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* ChainContextInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CloneContextInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CatchEntryInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CheckStackOverflowInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* BinarySmiOpInstr::CompileType() const {
  return (op_kind() == Token::kSHL) ? Type::IntInterface() : Type::SmiType();
}


intptr_t BinarySmiOpInstr::ResultCid() const {
  return (op_kind() == Token::kSHL) ? kDynamicCid : kSmiCid;
}


bool BinarySmiOpInstr::CanDeoptimize() const {
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return false;
    default:
      return true;
  }
}


RawAbstractType* BinaryMintOpInstr::CompileType() const {
  return Type::MintType();
}


intptr_t BinaryMintOpInstr::ResultCid() const {
  return kMintCid;
}


RawAbstractType* UnboxedDoubleBinaryOpInstr::CompileType() const {
  return Type::Double();
}


RawAbstractType* UnboxDoubleInstr::CompileType() const {
  return Type::null();
}


intptr_t BoxDoubleInstr::ResultCid() const {
  return kDoubleCid;
}


RawAbstractType* BoxDoubleInstr::CompileType() const {
  return Type::Double();
}


RawAbstractType* UnarySmiOpInstr::CompileType() const {
  return Type::SmiType();
}


RawAbstractType* NumberNegateInstr::CompileType() const {
  // Implemented only for doubles.
  return Type::Double();
}


RawAbstractType* DoubleToDoubleInstr::CompileType() const {
  return Type::Double();
}


RawAbstractType* SmiToDoubleInstr::CompileType() const {
  return Type::Double();
}


RawAbstractType* CheckClassInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CheckSmiInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CheckArrayBoundInstr::CompileType() const {
  return AbstractType::null();
}


RawAbstractType* CheckEitherNonSmiInstr::CompileType() const {
  return AbstractType::null();
}


// Optimizations that eliminate or simplify individual computations.
Definition* Definition::Canonicalize() {
  return this;
}


Definition* StrictCompareInstr::Canonicalize() {
  if (!right()->BindsToConstant()) return this;
  const Object& right_constant = right()->BoundConstant();
  Definition* left_defn = left()->definition();
  // TODO(fschneider): Handle other cases: e === false and e !== true/false.
  // Handles e === true.
  if ((kind() == Token::kEQ_STRICT) &&
      (right_constant.raw() == Bool::True()) &&
      (left()->ResultCid() == kBoolCid)) {
    // Remove the constant from the graph.
    Definition* right_defn = right()->definition();
    right_defn->RemoveFromGraph();
    // Return left subexpression as the replacement for this instruction.
    return left_defn;
  }
  return this;
}


Definition* CheckClassInstr::Canonicalize() {
  const intptr_t v_cid = value()->ResultCid();
  const intptr_t num_checks = unary_checks().NumberOfChecks();
  if ((num_checks == 1) &&
      (v_cid == unary_checks().GetReceiverClassIdAt(0))) {
    // No checks needed.
    return NULL;
  }
  return this;
}


Definition* CheckSmiInstr::Canonicalize() {
  return (value()->ResultCid() == kSmiCid) ?  NULL : this;
}


Definition* CheckEitherNonSmiInstr::Canonicalize() {
  if ((left()->ResultCid() == kDoubleCid) ||
      (right()->ResultCid() == kDoubleCid)) {
    return NULL;  // Remove from the graph.
  }
  return this;
}


// Shared code generation methods (EmitNativeCode, MakeLocationSummary, and
// PrepareEntry). Only assembly code that can be shared across all architectures
// can be used. Machine specific register allocation and code generation
// is located in intermediate_language_<arch>.cc

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
  if (IsCatchEntry()) {
    compiler->AddExceptionHandler(catch_try_index(),
                                  compiler->assembler()->CodeSize());
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* GraphEntryInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* JoinEntryInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void JoinEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* TargetEntryInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* PhiInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void PhiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ParameterInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void ParameterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ParallelMoveInstr::MakeLocationSummary() const {
  return NULL;
}


void ParallelMoveInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(token_pos(),
                                kThrowRuntimeEntry,
                                locs());
  __ int3();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(token_pos(),
                                kReThrowRuntimeEntry,
                                locs());
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


void ControlInstruction::EmitBranchOnCondition(FlowGraphCompiler* compiler,
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


LocationSummary* CurrentContextInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ MoveRegister(locs()->out().reg(), CTX);
}


LocationSummary* StoreContextInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterLocation(CTX));
  return summary;
}


void StoreContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Nothing to do.  Context register were loaded by register allocator.
  ASSERT(locs()->in(0).reg() == CTX);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary() const {
  return LocationSummary::Make(2,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQUAL : NOT_EQUAL;
  __ CompareRegisters(left, right);
  branch->EmitBranchOnCondition(compiler, true_condition);
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  Register temp_reg = locs()->temp(0).reg();
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count - 1,
                                         argument_names());
  __ LoadObject(temp_reg, arguments_descriptor);
  compiler->GenerateDartCall(deopt_id(),
                             token_pos(),
                             &StubCode::CallClosureFunctionLabel(),
                             PcDescriptors::kOther,
                             locs());
  __ Drop(argument_count);
}


LocationSummary* InstanceCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void InstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                                 deopt_id(),
                                 token_pos());
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 function_name(),
                                 ArgumentCount(),
                                 argument_names(),
                                 checked_argument_count(),
                                 locs());
}


LocationSummary* StaticCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label done;
  if (recognized() == MethodRecognizer::kMathSqrt) {
    compiler->GenerateInlinedMathSqrt(&done);
    // Falls through to static call when operand type is not double or smi.
  }
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               function(),
                               ArgumentCount(),
                               argument_names(),
                               locs());
  __ Bind(&done);
}


void AssertAssignableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!is_eliminated()) {
    compiler->GenerateAssertAssignable(token_pos(),
                                       dst_type(),
                                       dst_name(),
                                       locs());
  }
  ASSERT(locs()->in(0).reg() == locs()->out().reg());
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Label done;
  __ LoadObject(result, compiler->bool_true());
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, compiler->bool_false());
  __ Bind(&done);
}


LocationSummary* ChainContextInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::NoLocation(),
                               LocationSummary::kNoCall);
}


void ChainContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();

  // Chain the new context in context_value to its parent in CTX.
  __ StoreIntoObject(context_value,
                     FieldAddress(context_value, Context::parent_offset()),
                     CTX);
  // Set new context as current context.
  __ MoveRegister(CTX, context_value);
}


LocationSummary* StoreVMFieldInstr::MakeLocationSummary() const {
  return LocationSummary::Make(2,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreVMFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value_reg = locs()->in(0).reg();
  Register dest_reg = locs()->in(1).reg();
  ASSERT(value_reg == locs()->out().reg());

  if (value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(dest_reg, FieldAddress(dest_reg, offset_in_bytes()),
                       value_reg);
  } else {
    __ StoreIntoObjectNoBarrier(
        dest_reg, FieldAddress(dest_reg, offset_in_bytes()), value_reg);
  }
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().Owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}


LocationSummary* CreateClosureInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void CreateClosureInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Function& closure_function = function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(closure_function));
  const ExternalLabel label(closure_function.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
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
  // where PushArgument is handled by BindInstr::EmitNativeCode.
  // TODO(fschneider): Avoid special-casing for SSA mode here.
  if (compiler->is_optimizing()) {
    ASSERT(locs()->in(0).IsRegister());
    __ PushRegister(locs()->in(0).reg());
  }
}


Environment::Environment(const GrowableArray<Definition*>& definitions,
                         intptr_t fixed_parameter_count)
    : values_(definitions.length()),
      locations_(NULL),
      fixed_parameter_count_(fixed_parameter_count) {
  for (intptr_t i = 0; i < definitions.length(); ++i) {
    values_.Add(new Value(definitions[i]));
  }
}


// Copies the environment and updates the environment use lists.
void Environment::CopyTo(Instruction* instr) const {
  Environment* copy = new Environment(values().length(),
                                      fixed_parameter_count());
  GrowableArray<Value*>* values_copy = copy->values_ptr();
  for (intptr_t i = 0; i < values().length(); ++i) {
    Value* value = values()[i]->Copy();
    values_copy->Add(value);
    value->set_instruction(instr);
    value->set_use_index(i);
    value->AddToEnvUseList();
  }
  instr->set_env(copy);
}


#undef __

}  // namespace dart
