// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/bit_vector.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_optimizer.h"
#include "vm/locations.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/scopes.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, propagate_ic_data, true,
    "Propagate IC data from unoptimized to optimized IC calls.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(int, max_polymorphic_checks);

Definition::Definition()
    : range_(NULL),
      temp_index_(-1),
      ssa_temp_index_(-1),
      propagated_type_(AbstractType::Handle()),
      propagated_cid_(kIllegalCid),
      input_use_list_(NULL),
      env_use_list_(NULL),
      use_kind_(kValue),  // Phis and parameters rely on this default.
      constant_value_(Object::ZoneHandle(ConstantPropagator::Unknown())) {
}


intptr_t Instruction::Hashcode() const {
  intptr_t result = tag();
  for (intptr_t i = 0; i < InputCount(); ++i) {
    Value* value = InputAt(i);
    intptr_t j = value->definition()->ssa_temp_index();
    result = result * 31 + j;
  }
  return result;
}


bool Instruction::Equals(Instruction* other) const {
  if (tag() != other->tag()) return false;
  for (intptr_t i = 0; i < InputCount(); ++i) {
    if (!InputAt(i)->Equals(other->InputAt(i))) return false;
  }
  return AttributesEqual(other);
}


bool Value::Equals(Value* other) const {
  return definition() == other->definition();
}



CheckClassInstr::CheckClassInstr(Value* value,
                                 intptr_t deopt_id,
                                 const ICData& unary_checks)
    : unary_checks_(unary_checks) {
  ASSERT(value != NULL);
  ASSERT(unary_checks.IsZoneHandle());
  // Expected useful check data.
  ASSERT(!unary_checks_.IsNull() &&
         (unary_checks_.NumberOfChecks() > 0) &&
         (unary_checks_.num_args_tested() == 1));
  inputs_[0] = value;
  deopt_id_ = deopt_id;
  // Otherwise use CheckSmiInstr.
  ASSERT((unary_checks_.NumberOfChecks() != 1) ||
         (unary_checks_.GetReceiverClassIdAt(0) != kSmiCid));
}


bool CheckClassInstr::AttributesEqual(Instruction* other) const {
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


bool CheckArrayBoundInstr::AttributesEqual(Instruction* other) const {
  CheckArrayBoundInstr* other_check = other->AsCheckArrayBound();
  ASSERT(other_check != NULL);
  return array_type() == other_check->array_type();
}


bool AssertAssignableInstr::AttributesEqual(Instruction* other) const {
  AssertAssignableInstr* other_assert = other->AsAssertAssignable();
  ASSERT(other_assert != NULL);
  // This predicate has to be commutative for DominatorBasedCSE to work.
  // TODO(fschneider): Eliminate more asserts with subtype relation.
  return dst_type().raw() == other_assert->dst_type().raw();
}


bool StrictCompareInstr::AttributesEqual(Instruction* other) const {
  StrictCompareInstr* other_op = other->AsStrictCompare();
  ASSERT(other_op != NULL);
  return kind() == other_op->kind();
}


bool BinarySmiOpInstr::AttributesEqual(Instruction* other) const {
  BinarySmiOpInstr* other_op = other->AsBinarySmiOp();
  ASSERT(other_op != NULL);
  return (op_kind() == other_op->op_kind()) &&
      (overflow_ == other_op->overflow_);
}


bool LoadFieldInstr::AttributesEqual(Instruction* other) const {
  LoadFieldInstr* other_load = other->AsLoadField();
  ASSERT(other_load != NULL);
  ASSERT((offset_in_bytes() != other_load->offset_in_bytes()) ||
         ((immutable_ == other_load->immutable_) &&
          ((ResultCid() == other_load->ResultCid()) ||
           (ResultCid() == kDynamicCid) ||
           (other_load->ResultCid() == kDynamicCid))));
  return offset_in_bytes() == other_load->offset_in_bytes();
}


bool LoadStaticFieldInstr::AttributesEqual(Instruction* other) const {
  LoadStaticFieldInstr* other_load = other->AsLoadStaticField();
  ASSERT(other_load != NULL);
  // Assert that the field is initialized.
  ASSERT(field().value() != Object::sentinel());
  ASSERT(field().value() != Object::transition_sentinel());
  return field().raw() == other_load->field().raw();
}


bool LoadIndexedInstr::AttributesEqual(Instruction* other) const {
  LoadIndexedInstr* other_load = other->AsLoadIndexed();
  ASSERT(other_load != NULL);
  return class_id() == other_load->class_id();
}


bool ConstantInstr::AttributesEqual(Instruction* other) const {
  ConstantInstr* other_constant = other->AsConstant();
  ASSERT(other_constant != NULL);
  return (value().raw() == other_constant->value().raw());
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


GraphEntryInstr::GraphEntryInstr(TargetEntryInstr* normal_entry)
    : BlockEntryInstr(0, CatchClauseNode::kInvalidTryIndex),
      normal_entry_(normal_entry),
      catch_entries_(),
      initial_definitions_(),
      spill_slot_count_(0) {
}


ConstantInstr* GraphEntryInstr::constant_null() {
  ASSERT(initial_definitions_.length() > 0);
  for (intptr_t i = 0; i < initial_definitions_.length(); ++i) {
    ConstantInstr* defn = initial_definitions_[i]->AsConstant();
    if (defn != NULL && defn->value().IsNull()) return defn;
  }
  UNREACHABLE();
  return NULL;
}


static bool CompareNames(const Library& lib,
                         const char* test_name,
                         const String& name) {
  // If both names are private mangle test_name before comparison.
  if ((name.CharAt(0) == '_') && (test_name[0] == '_')) {
    const String& test_name_symbol = String::Handle(Symbols::New(test_name));
    return String::Handle(lib.PrivateName(test_name_symbol)).Equals(name);
  }
  return name.Equals(test_name);
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
  const Library& lib = Library::Handle(function_class.library());
  const String& function_name = String::Handle(function.name());
  const String& class_name = String::Handle(function_class.Name());

#define RECOGNIZE_FUNCTION(test_class_name, test_function_name, enum_name)     \
  if (CompareNames(lib, #test_function_name, function_name) &&                 \
      CompareNames(lib, #test_class_name, class_name)) {                       \
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
  prev_instr->LinkTo(next_instr);
  // Reset successor and previous instruction to indicate
  // that the instruction is removed from the graph.
  set_previous(NULL);
  set_next(NULL);
  return return_previous ? prev_instr : next_instr;
}


void Instruction::InsertBefore(Instruction* next) {
  ASSERT(previous_ == NULL);
  ASSERT(next_ == NULL);
  next_ = next;
  previous_ = next->previous_;
  next->previous_ = this;
  previous_->next_ = this;
}


void Instruction::InsertAfter(Instruction* prev) {
  ASSERT(previous_ == NULL);
  ASSERT(next_ == NULL);
  previous_ = prev;
  next_ = prev->next_;
  next_->previous_ = this;
  previous_->next_ = this;
}


BlockEntryInstr* Instruction::GetBlock() const {
  // TODO(fschneider): Implement a faster way to get the block of an
  // instruction.
  ASSERT(previous() != NULL);
  Instruction* result = previous();
  while (!result->IsBlockEntry()) result = result->previous();
  return result->AsBlockEntry();
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


// TODO(regis): Support a set of compile types for the given value.
bool Value::CanComputeIsNull(bool* is_null) const {
  ASSERT(is_null != NULL);
  // For now, we can only return a meaningful result if the value is constant.
  if (!BindsToConstant()) {
    return false;
  }

  // Return true if the constant value is Object::null.
  if (BindsToConstantNull()) {
    *is_null = true;
    return true;
  }

  // Consider the compile type of the value to check for sentinels, which are
  // also treated as null.
  const AbstractType& compile_type = AbstractType::Handle(CompileType());
  ASSERT(!compile_type.IsMalformed());
  ASSERT(!compile_type.IsVoidType());

  // There are only three instances that can be of type Null:
  // Object::null(), Object::sentinel(), and Object::transition_sentinel().
  // The inline code and run time code performing the type check will only
  // encounter the 2 sentinel values if type check elimination was disabled.
  // Otherwise, the type check of a sentinel value will be eliminated here,
  // because these sentinel values can only be encountered as constants, never
  // as actual value of a heap object being type checked.
  if (compile_type.IsNullType()) {
    *is_null = true;
    return true;
  }

  return false;
}


// TODO(regis): Support a set of compile types for the given value.
bool Value::CanComputeIsInstanceOf(const AbstractType& type,
                                   bool* is_instance) const {
  ASSERT(is_instance != NULL);
  // We cannot give an answer if the given type is malformed.
  if (type.IsMalformed()) {
    return false;
  }

  // We should never test for an instance of null.
  ASSERT(!type.IsNullType());

  // Consider the compile type of the value.
  const AbstractType& compile_type = AbstractType::Handle(CompileType());
  if (compile_type.IsMalformed()) {
    return false;
  }

  // If the compile type of the value is void, we are type checking the result
  // of a void function, which was checked to be null at the return statement
  // inside the function.
  if (compile_type.IsVoidType()) {
    ASSERT(FLAG_enable_type_checks);
    *is_instance = true;
    return true;
  }

  // The Null type is only a subtype of Object and of dynamic.
  // Functions that do not explicitly return a value, implicitly return null,
  // except generative constructors, which return the object being constructed.
  // It is therefore acceptable for void functions to return null.
  if (compile_type.IsNullType()) {
    *is_instance =
        type.IsObjectType() || type.IsDynamicType() || type.IsVoidType();
    return true;
  }

  // Until we support a set of compile types, we can only give answers for
  // constant values. Indeed, a variable of the proper compile time type may
  // still hold null at run time and therefore fail the test.
  if (!BindsToConstant()) {
    return false;
  }

  // A non-null constant is not an instance of void.
  if (type.IsVoidType()) {
    *is_instance = false;
    return true;
  }

  // Since the value is a constant, its type is instantiated.
  ASSERT(compile_type.IsInstantiated());

  // The run time type of the value is guaranteed to be a subtype of the
  // compile time type of the value. However, establishing here that the
  // compile time type is a subtype of the given type does not guarantee that
  // the run time type will also be a subtype of the given type, because the
  // subtype relation is not transitive when an uninstantiated type is
  // involved.
  Error& malformed_error = Error::Handle();
  if (type.IsInstantiated()) {
    // Perform the test on the compile-time type and provide the answer, unless
    // the type test produced a malformed error (e.g. an upper bound error).
    *is_instance = compile_type.IsSubtypeOf(type, &malformed_error);
  } else {
    // However, the 'more specific than' relation is transitive and used here.
    // In other words, if the compile type of the value is more specific than
    // the given type, the run time type of the value, which is guaranteed to be
    // a subtype of the compile type, is also guaranteed to be a subtype of the
    // given type.
    *is_instance = compile_type.IsMoreSpecificThan(type, &malformed_error);
  }
  return malformed_error.IsNull();
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


void JoinEntryInstr::AddPredecessor(BlockEntryInstr* predecessor) {
  // Require the predecessors to be sorted by block_id to make managing
  // their corresponding phi inputs simpler.
  intptr_t pred_id = predecessor->block_id();
  intptr_t index = 0;
  while ((index < predecessors_.length()) &&
         (predecessors_[index]->block_id() < pred_id)) {
    ++index;
  }
#if defined(DEBUG)
  for (intptr_t i = index; i < predecessors_.length(); ++i) {
    ASSERT(predecessors_[i]->block_id() != pred_id);
  }
#endif
  predecessors_.InsertAt(index, predecessor);
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


void Value::RemoveFromInputUseList() {
  if (definition_->input_use_list() == this) {
    definition_->set_input_use_list(next_use_);
    return;
  }

  Value* prev = definition_->input_use_list();
  while (prev->next_use_ != this) {
    prev = prev->next_use_;
  }
  prev->next_use_ = next_use_;
  definition_ = NULL;
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
  if ((iterator != NULL) && (this == iterator->Current())) {
    iterator->ReplaceCurrentWith(other);
  } else {
    ReplaceUsesWith(other);
    ASSERT(other->env() == NULL);
    other->set_env(env());
    set_env(NULL);
    ASSERT(!other->HasSSATemp());
    if (HasSSATemp()) other->set_ssa_temp_index(ssa_temp_index());

    previous()->LinkTo(other);
    other->LinkTo(next());

    set_previous(NULL);
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


intptr_t AssertAssignableInstr::GetPropagatedCid() {
  return propagated_cid();
}


// ==== Postorder graph traversal.
static bool IsMarked(BlockEntryInstr* block,
                     GrowableArray<BlockEntryInstr*>* preorder) {
  // Detect that a block has been visited as part of the current
  // DiscoverBlocks (we can call DiscoverBlocks multiple times).  The block
  // will be 'marked' by (1) having a preorder number in the range of the
  // preorder array and (2) being in the preorder array at that index.
  intptr_t i = block->preorder_number();
  return (i >= 0) && (i < preorder->length()) && ((*preorder)[i] == block);
}


void GraphEntryInstr::DiscoverBlocks(
    BlockEntryInstr* current_block,
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<BlockEntryInstr*>* postorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* assigned_vars,
    intptr_t variable_count,
    intptr_t fixed_parameter_count) {
  // We only visit this block once, first of all blocks.
  ASSERT(!IsMarked(this, preorder));
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
  // Blocks with a single predecessor cannot have been reached before.
  ASSERT(!IsTargetEntry() || !IsMarked(this, preorder));

  // 1. If the block has already been reached, add current_block as a
  // basic-block predecessor and we are done.
  if (IsMarked(this, preorder)) {
    AddPredecessor(current_block);
    return;
  }

  // 2. Otherwise, clear the predecessors which might have been computed on
  // some earlier call to DiscoverBlocks and record this predecessor.  For
  // joins save the original predecessors, if any, so we can garbage collect
  // phi inputs from unreachable predecessors without recomputing SSA.
  ClearPredecessors();
  AddPredecessor(current_block);

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


bool BlockEntryInstr::Dominates(BlockEntryInstr* other) const {
  // TODO(fschneider): Make this faster by e.g. storing dominators for each
  // block while computing the dominator tree.
  ASSERT(other != NULL);
  BlockEntryInstr* current = other;
  while (current != NULL && current != this) {
    current = current->dominator();
  }
  return current == this;
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
  LinkTo(new GotoInstr(entry));
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
  if (reaching_cid() == kIllegalCid) {
    return definition()->GetPropagatedCid();
  }
  return reaching_cid();
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
  // function returning dynamic can be assigned to a closure variable declared
  // to return int and may actually return a double at run-time.
  return Type::DynamicType();
}


RawAbstractType* InstanceCallInstr::CompileType() const {
  // TODO(regis): Return a more specific type than dynamic for recognized
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


bool EqualityCompareInstr::IsPolymorphic() const {
  return HasICData() &&
      (ic_data()->NumberOfChecks() > 0) &&
      (ic_data()->NumberOfChecks() <= FLAG_max_polymorphic_checks);
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
  switch (class_id_) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid:
      return Type::DynamicType();
    case kFloat32ArrayCid :
    case kFloat64ArrayCid :
      return Type::Double();
    default:
      UNIMPLEMENTED();
      return Type::IntType();
  }
}


intptr_t LoadIndexedInstr::ResultCid() const {
  switch (class_id_) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid:
      return kDynamicCid;
    case kFloat32ArrayCid :
    case kFloat64ArrayCid :
      return kDoubleCid;
    default:
      UNIMPLEMENTED();
      return kSmiCid;
  }
}


Representation LoadIndexedInstr::representation() const {
  switch (class_id_) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid:
      return kTagged;
    case kFloat32ArrayCid :
    case kFloat64ArrayCid :
      return kUnboxedDouble;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}


RawAbstractType* StoreIndexedInstr::CompileType() const {
  return AbstractType::null();
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  if ((idx == 0) || (idx == 1)) return kTagged;
  ASSERT(idx == 2);
  switch (class_id_) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid:
      return kTagged;
    case kFloat32ArrayCid :
    case kFloat64ArrayCid :
      return kUnboxedDouble;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
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


RawAbstractType* LoadFieldInstr::CompileType() const {
  // Type may be null if the field is a VM field, e.g. context parent.
  // Keep it as null for debug purposes and do not return dynamic in production
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
  return (op_kind() == Token::kSHL) ? Type::IntType() : Type::SmiType();
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
      return overflow_;
  }
}


RawAbstractType* BinaryMintOpInstr::CompileType() const {
  return Type::IntType();
}


intptr_t BinaryMintOpInstr::ResultCid() const {
  return kDynamicCid;
}


RawAbstractType* ShiftMintOpInstr::CompileType() const {
  return Type::IntType();
}


intptr_t ShiftMintOpInstr::ResultCid() const {
  return kDynamicCid;
}


RawAbstractType* UnaryMintOpInstr::CompileType() const {
  return Type::IntType();
}


intptr_t UnaryMintOpInstr::ResultCid() const {
  return kDynamicCid;
}


RawAbstractType* BinaryDoubleOpInstr::CompileType() const {
  return Type::Double();
}


intptr_t BinaryDoubleOpInstr::ResultCid() const {
  // The output is not an instance but when it is boxed it becomes double.
  return kDoubleCid;
}


RawAbstractType* MathSqrtInstr::CompileType() const {
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


intptr_t BoxIntegerInstr::ResultCid() const {
  return kDynamicCid;
}


RawAbstractType* BoxIntegerInstr::CompileType() const {
  return Type::IntType();
}


intptr_t UnboxIntegerInstr::ResultCid() const {
  return kDynamicCid;
}


RawAbstractType* UnboxIntegerInstr::CompileType() const {
  return Type::null();
}


RawAbstractType* UnarySmiOpInstr::CompileType() const {
  return Type::SmiType();
}


RawAbstractType* SmiToDoubleInstr::CompileType() const {
  return Type::Double();
}


RawAbstractType* DoubleToIntegerInstr::CompileType() const {
  return Type::IntType();
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


// Optimizations that eliminate or simplify individual instructions.
Instruction* Instruction::Canonicalize() {
  return this;
}


Definition* Definition::Canonicalize() {
  return this;
}


Definition* AssertBooleanInstr::Canonicalize() {
  const intptr_t value_cid = value()->ResultCid();
  return (value_cid == kBoolCid) ? value()->definition() : this;
}


Definition* AssertAssignableInstr::Canonicalize() {
  // (1) Replace the assert with its input if the input has a known compatible
  // class-id. The class-ids handled here are those that are known to be
  // results of IL instructions.
  intptr_t cid = value()->ResultCid();
  bool is_redundant = false;
  if (dst_type().IsIntType()) {
    is_redundant = (cid == kSmiCid) || (cid == kMintCid);
  } else if (dst_type().IsDoubleType()) {
    is_redundant = (cid == kDoubleCid);
  } else if (dst_type().IsBoolType()) {
    is_redundant = (cid == kBoolCid);
  }
  if (is_redundant) return value()->definition();

  // (2) Replace the assert with its input if the input is the result of a
  // compatible assert itself.
  AssertAssignableInstr* check = value()->definition()->AsAssertAssignable();
  if ((check != NULL) && (check->dst_type().raw() == dst_type().raw())) {
    // TODO(fschneider): Propagate type-assertions across phi-nodes.
    // TODO(fschneider): Eliminate more asserts with subtype relation.
    return check;
  }
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
    // Return left subexpression as the replacement for this instruction.
    return left_defn;
  }
  return this;
}


Instruction* CheckClassInstr::Canonicalize() {
  const intptr_t value_cid = value()->ResultCid();
  const intptr_t num_checks = unary_checks().NumberOfChecks();
  if ((num_checks == 1) &&
      (value_cid == unary_checks().GetReceiverClassIdAt(0))) {
    // No checks needed.
    return NULL;
  }
  return this;
}


Instruction* CheckSmiInstr::Canonicalize() {
  return (value()->ResultCid() == kSmiCid) ?  NULL : this;
}


Instruction* CheckEitherNonSmiInstr::Canonicalize() {
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


LocationSummary* ConstraintInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void ConstraintInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
  // Add deoptimization descriptor for deoptimizing instructions
  // that may be inserted before this instruction.
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                                   GetDeoptId(),
                                   0);  // No token position.
  }

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


void ControlInstruction::EmitBranchOnValue(FlowGraphCompiler* compiler,
                                           bool value) {
  if (value && compiler->IsNextBlock(false_successor())) {
    __ jmp(compiler->GetBlockLabel(true_successor()));
  } else if (!value && compiler->IsNextBlock(true_successor())) {
    __ jmp(compiler->GetBlockLabel(false_successor()));
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
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterOrConstant(left()));
  locs->set_in(1, Location::RegisterOrConstant(right()));
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  if (left.IsConstant() && right.IsConstant()) {
    // TODO(vegorov): should be eliminated earlier by constant propagation.
    const bool result = (kind() == Token::kEQ_STRICT) ?
        left.constant().raw() == right.constant().raw() :
        left.constant().raw() != right.constant().raw();
    __ LoadObject(locs()->out().reg(), result ? compiler->bool_true() :
                                                compiler->bool_false());
    return;
  }
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(), left.constant());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(), right.constant());
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }

  Register result = locs()->out().reg();
  Label load_true, done;
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQUAL : NOT_EQUAL;
  __ j(true_condition, &load_true, Assembler::kNearJump);
  __ LoadObject(result, compiler->bool_false());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(result, compiler->bool_true());
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  if (left.IsConstant() && right.IsConstant()) {
    // TODO(vegorov): should be eliminated earlier by constant propagation.
    const bool result = (kind() == Token::kEQ_STRICT) ?
        left.constant().raw() == right.constant().raw() :
        left.constant().raw() != right.constant().raw();
    branch->EmitBranchOnValue(compiler, result);
    return;
  }
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(), left.constant());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(), right.constant());
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }

  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQUAL : NOT_EQUAL;
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
  ICData& call_ic_data = ICData::ZoneHandle(ic_data()->raw());
  if (!FLAG_propagate_ic_data || !compiler->is_optimizing()) {
    call_ic_data = ICData::New(compiler->parsed_function().function(),
                               function_name(),
                               deopt_id(),
                               checked_argument_count());
  }
  if (compiler->is_optimizing()) {
    if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
      const ICData& unary_ic_data =
          ICData::ZoneHandle(ic_data()->AsUnaryClassChecks());
      compiler->GenerateInstanceCall(deopt_id(),
                                     token_pos(),
                                     ArgumentCount(),
                                     argument_names(),
                                     locs(),
                                     unary_ic_data);
    } else {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), kDeoptInstanceCallNoICData);
      __ jmp(deopt);
    }
  } else {
    ASSERT(!HasICData());
    compiler->AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                                   deopt_id(),
                                   token_pos());
    compiler->GenerateInstanceCall(deopt_id(),
                                   token_pos(),
                                   ArgumentCount(),
                                   argument_names(),
                                   locs(),
                                   call_ic_data);
  }
}


LocationSummary* StaticCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label skip_call;
  if (function().name() == Symbols::EqualOperator()) {
    compiler->EmitSuperEqualityCallPrologue(locs()->out().reg(), &skip_call);
  }
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               function(),
                               ArgumentCount(),
                               argument_names(),
                               locs());
  __ Bind(&skip_call);
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
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_in(1, Location::RequiresRegister());
  return locs;
}


void StoreVMFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value_reg = locs()->in(0).reg();
  Register dest_reg = locs()->in(1).reg();

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


Environment* Environment::From(const GrowableArray<Definition*>& definitions,
                               intptr_t fixed_parameter_count,
                               const Function& function) {
  Environment* env =
      new Environment(definitions.length(),
                      fixed_parameter_count,
                      Isolate::kNoDeoptId,
                      function,
                      NULL);
  for (intptr_t i = 0; i < definitions.length(); ++i) {
    env->values_.Add(new Value(definitions[i]));
  }
  return env;
}


Environment* Environment::DeepCopy() const {
  Environment* copy =
      new Environment(values_.length(),
                      fixed_parameter_count_,
                      deopt_id_,
                      function_,
                      (outer_ == NULL) ? NULL : outer_->DeepCopy());
  for (intptr_t i = 0; i < values_.length(); ++i) {
    copy->values_.Add(values_[i]->Copy());
  }
  return copy;
}


// Copies the environment and updates the environment use lists.
void Environment::DeepCopyTo(Instruction* instr) const {
  Environment* copy = DeepCopy();
  intptr_t use_index = 0;
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->set_instruction(instr);
    value->set_use_index(use_index++);
    value->AddToEnvUseList();
  }
  instr->set_env(copy);
}


// Copies the environment as outer on an inlined instruction and updates the
// environment use lists.
void Environment::DeepCopyToOuter(Instruction* instr) const {
  ASSERT(instr->env()->outer() == NULL);
  // Create a deep copy removing caller arguments from the environment.
  intptr_t argument_count = instr->env()->fixed_parameter_count();
  Environment* copy =
      new Environment(values_.length() - argument_count,
                      fixed_parameter_count_,
                      deopt_id_,
                      function_,
                      (outer_ == NULL) ? NULL : outer_->DeepCopy());
  for (intptr_t i = 0; i < values_.length() - argument_count; ++i) {
    copy->values_.Add(values_[i]->Copy());
  }
  intptr_t use_index = instr->env()->Length();  // Start index after inner.
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->set_instruction(instr);
    value->set_use_index(use_index++);
    value->AddToEnvUseList();
  }
  instr->env()->outer_ = copy;
}


RangeBoundary RangeBoundary::FromDefinition(Definition* defn, intptr_t offs) {
  if (defn->IsConstant() && defn->AsConstant()->value().IsSmi()) {
    return FromConstant(Smi::Cast(defn->AsConstant()->value()).Value() + offs);
  }
  return RangeBoundary(kSymbol, reinterpret_cast<intptr_t>(defn), offs);
}


RangeBoundary RangeBoundary::LowerBound() const {
  if (IsConstant()) return *this;
  if (symbol()->range() == NULL) return MinSmi();
  return Add(symbol()->range()->min().LowerBound(),
             RangeBoundary::FromConstant(offset_),
             MinSmi());
}


RangeBoundary RangeBoundary::UpperBound() const {
  if (IsConstant()) return *this;
  if (symbol()->range() == NULL) return MaxSmi();
  return Add(symbol()->range()->max().UpperBound(),
             RangeBoundary::FromConstant(offset_),
             MaxSmi());
}


static bool AreEqualDefinitions(Definition* a, Definition* b) {
  return (a == b) || (!a->AffectedBySideEffect() && a->Equals(b));
}


// Returns true if two range boundaries refer to the same symbol.
static bool DependOnSameSymbol(const RangeBoundary& a, const RangeBoundary& b) {
  return a.IsSymbol() && b.IsSymbol() &&
      AreEqualDefinitions(a.symbol(), b.symbol());
}


// Returns true if range has a least specific minimum value.
static bool IsMinSmi(Range* range) {
  return (range == NULL) ||
      (range->min().IsConstant() &&
       (range->min().value() <= Smi::kMinValue));
}


// Returns true if range has a least specific maximium value.
static bool IsMaxSmi(Range* range) {
  return (range == NULL) ||
      (range->max().IsConstant() &&
       (range->max().value() >= Smi::kMaxValue));
}


// Returns true if two range boundaries can be proven to be equal.
static bool IsEqual(const RangeBoundary& a, const RangeBoundary& b) {
  if (a.IsConstant() && b.IsConstant()) {
    return a.value() == b.value();
  } else if (a.IsSymbol() && b.IsSymbol()) {
    return (a.offset() == b.offset()) && DependOnSameSymbol(a, b);
  } else {
    return false;
  }
}


static RangeBoundary CanonicalizeBoundary(const RangeBoundary& a,
                                          const RangeBoundary& overflow) {
  if (a.IsConstant()) return a;

  intptr_t offset = a.offset();
  Definition* symbol = a.symbol();

  bool changed;
  do {
    changed = false;
    if (symbol->IsConstraint()) {
      symbol = symbol->AsConstraint()->value()->definition();
      changed = true;
    } else if (symbol->IsBinarySmiOp()) {
      BinarySmiOpInstr* op = symbol->AsBinarySmiOp();
      Definition* left = op->left()->definition();
      Definition* right = op->right()->definition();
      switch (op->op_kind()) {
        case Token::kADD:
          if (right->IsConstant()) {
            offset += Smi::Cast(right->AsConstant()->value()).Value();
            symbol = left;
            changed = true;
          } else if (left->IsConstant()) {
            offset += Smi::Cast(left->AsConstant()->value()).Value();
            symbol = right;
            changed = true;
          }
          break;

        case Token::kSUB:
          if (right->IsConstant()) {
            offset -= Smi::Cast(right->AsConstant()->value()).Value();
            symbol = left;
            changed = true;
          }
          break;

        default:
          break;
      }
    }

    if (!Smi::IsValid(offset)) return overflow;
  } while (changed);

  return RangeBoundary::FromDefinition(symbol, offset);
}


static bool CanonicalizeMaxBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == NULL) || !range->max().IsSymbol()) return false;

  const intptr_t offset = range->max().offset() + a->offset();

  if (!Smi::IsValid(offset)) {
    *a = RangeBoundary::OverflowedMaxSmi();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->max().symbol(), offset),
      RangeBoundary::OverflowedMaxSmi());

  return true;
}


static bool CanonicalizeMinBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == NULL) || !range->min().IsSymbol()) return false;

  const intptr_t offset = range->min().offset() + a->offset();
  if (!Smi::IsValid(offset)) {
    *a = RangeBoundary::OverflowedMinSmi();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->min().symbol(), offset),
      RangeBoundary::OverflowedMinSmi());

  return true;
}


RangeBoundary RangeBoundary::Min(RangeBoundary a, RangeBoundary b) {
  if (DependOnSameSymbol(a, b)) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const intptr_t min_a = a.LowerBound().value();
  const intptr_t min_b = b.LowerBound().value();

  return RangeBoundary::FromConstant(Utils::Minimum(min_a, min_b));
}


RangeBoundary RangeBoundary::Max(RangeBoundary a, RangeBoundary b) {
  if (DependOnSameSymbol(a, b)) {
    return (a.offset() >= b.offset()) ? a : b;
  }

  const intptr_t max_a = a.UpperBound().value();
  const intptr_t max_b = b.UpperBound().value();

  return RangeBoundary::FromConstant(Utils::Maximum(max_a, max_b));
}


void Definition::InferRange() {
  ASSERT(GetPropagatedCid() == kSmiCid);  // Has meaning only for smis.
  if (range_ == NULL) {
    range_ = Range::Unknown();
  }
}


void ConstantInstr::InferRange() {
  ASSERT(value_.IsSmi());
  if (range_ == NULL) {
    intptr_t value = Smi::Cast(value_).Value();
    range_ = new Range(RangeBoundary::FromConstant(value),
                       RangeBoundary::FromConstant(value));
  }
}


void ConstraintInstr::InferRange() {
  Range* value_range = value()->definition()->range();

  RangeBoundary min;
  RangeBoundary max;

  if (IsMinSmi(value_range) && !IsMinSmi(constraint())) {
    min = constraint()->min();
  } else if (IsMinSmi(constraint()) && !IsMinSmi(value_range)) {
    min = value_range->min();
  } else if ((value_range != NULL) &&
             IsEqual(constraint()->min(), value_range->min())) {
    min = constraint()->min();
  } else {
    if (value_range != NULL) {
      RangeBoundary canonical_a =
          CanonicalizeBoundary(constraint()->min(),
                               RangeBoundary::OverflowedMinSmi());
      RangeBoundary canonical_b =
          CanonicalizeBoundary(value_range->min(),
                               RangeBoundary::OverflowedMinSmi());

      do {
        if (DependOnSameSymbol(canonical_a, canonical_b)) {
          min = (canonical_a.offset() <= canonical_b.offset()) ? canonical_b
                                                               : canonical_a;
        }
      } while (CanonicalizeMinBoundary(&canonical_a) ||
               CanonicalizeMinBoundary(&canonical_b));
    }

    if (min.IsUnknown()) {
      min = RangeBoundary::Max(Range::ConstantMin(value_range),
                               Range::ConstantMin(constraint()));
    }
  }

  if (IsMaxSmi(value_range) && !IsMaxSmi(constraint())) {
    max = constraint()->max();
  } else if (IsMaxSmi(constraint()) && !IsMaxSmi(value_range)) {
    max = value_range->max();
  } else if ((value_range != NULL) &&
             IsEqual(constraint()->max(), value_range->max())) {
    max = constraint()->max();
  } else {
    if (value_range != NULL) {
      RangeBoundary canonical_b =
          CanonicalizeBoundary(value_range->max(),
                               RangeBoundary::OverflowedMaxSmi());
      RangeBoundary canonical_a =
          CanonicalizeBoundary(constraint()->max(),
                               RangeBoundary::OverflowedMaxSmi());

      do {
        if (DependOnSameSymbol(canonical_a, canonical_b)) {
          max = (canonical_a.offset() <= canonical_b.offset()) ? canonical_a
                                                               : canonical_b;
          break;
        }
      } while (CanonicalizeMaxBoundary(&canonical_a) ||
               CanonicalizeMaxBoundary(&canonical_b));
    }

    if (max.IsUnknown()) {
      max = RangeBoundary::Min(Range::ConstantMax(value_range),
                               Range::ConstantMax(constraint()));
    }
  }

  range_ = new Range(min, max);
}


void LoadFieldInstr::InferRange() {
  if ((range_ == NULL) &&
      ((recognized_kind() == MethodRecognizer::kObjectArrayLength) ||
       (recognized_kind() == MethodRecognizer::kImmutableArrayLength))) {
    range_ = new Range(RangeBoundary::FromConstant(0),
                       RangeBoundary::FromConstant(Array::kMaxElements));
    return;
  }
  Definition::InferRange();
}


void PhiInstr::InferRange() {
  RangeBoundary new_min;
  RangeBoundary new_max;

  for (intptr_t i = 0; i < InputCount(); i++) {
    Range* input_range = InputAt(i)->definition()->range();
    if (input_range == NULL) {
      range_ = Range::Unknown();
      return;
    }

    if (new_min.IsUnknown()) {
      new_min = Range::ConstantMin(input_range);
    } else {
      new_min = RangeBoundary::Min(new_min, Range::ConstantMin(input_range));
    }

    if (new_max.IsUnknown()) {
      new_max = Range::ConstantMax(input_range);
    } else {
      new_max = RangeBoundary::Max(new_max, Range::ConstantMax(input_range));
    }
  }

  ASSERT(new_min.IsUnknown() == new_max.IsUnknown());
  if (new_min.IsUnknown()) {
    range_ = Range::Unknown();
    return;
  }

  range_ = new Range(new_min, new_max);
}


static bool SymbolicSub(const RangeBoundary& a,
                        const RangeBoundary& b,
                        RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant() && !b.Overflowed()) {
    const intptr_t offset = a.offset() - b.value();
    if (!Smi::IsValid(offset)) return false;

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  }
  return false;
}


static bool SymbolicAdd(const RangeBoundary& a,
                        const RangeBoundary& b,
                        RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant() && !b.Overflowed()) {
    const intptr_t offset = a.offset() + b.value();
    if (!Smi::IsValid(offset)) return false;

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  } else if (b.IsSymbol() && a.IsConstant() && !a.Overflowed()) {
    const intptr_t offset = b.offset() + a.value();
    if (!Smi::IsValid(offset)) return false;

    *result = RangeBoundary::FromDefinition(b.symbol(), offset);
    return true;
  }
  return false;
}


static bool IsArrayLength(Definition* defn) {
  LoadFieldInstr* load = defn->AsLoadField();
  return (load != NULL) &&
      ((load->recognized_kind() == MethodRecognizer::kObjectArrayLength) ||
       (load->recognized_kind() == MethodRecognizer::kImmutableArrayLength));
}


void BinarySmiOpInstr::InferRange() {
  // TODO(vegorov): canonicalize BinarySmiOp to always have constant on the
  // right and a non-constant on the left.
  Definition* left_defn = left()->definition();

  Range* left_range = left_defn->range();
  Range* right_range = right()->definition()->range();

  if ((left_range == NULL) || (right_range == NULL)) {
    range_ = new Range(RangeBoundary::MinSmi(), RangeBoundary::MaxSmi());
    return;
  }


  // If left is a l
  RangeBoundary left_min =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->min();

  RangeBoundary left_max =
    IsArrayLength(left_defn) ?
        RangeBoundary::FromDefinition(left_defn) : left_range->max();

  RangeBoundary min;
  RangeBoundary max;
  switch (op_kind()) {
    case Token::kADD:
      if (!SymbolicAdd(left_min, right_range->min(), &min)) {
        min =
          RangeBoundary::Add(Range::ConstantMin(left_range),
                             Range::ConstantMin(right_range),
                             RangeBoundary::OverflowedMinSmi());
      }

      if (!SymbolicAdd(left_max, right_range->max(), &max)) {
        max =
          RangeBoundary::Add(Range::ConstantMax(right_range),
                             Range::ConstantMax(left_range),
                             RangeBoundary::OverflowedMaxSmi());
      }
      break;

    case Token::kSUB:
      if (!SymbolicSub(left_min, right_range->max(), &min)) {
        min =
          RangeBoundary::Sub(Range::ConstantMin(left_range),
                             Range::ConstantMax(right_range),
                             RangeBoundary::OverflowedMinSmi());
      }

      if (!SymbolicSub(left_max, right_range->min(), &max)) {
        max =
          RangeBoundary::Sub(Range::ConstantMax(left_range),
                             Range::ConstantMin(right_range),
                             RangeBoundary::OverflowedMaxSmi());
      }
      break;

    case Token::kBIT_AND:
      if (Range::ConstantMin(right_range).value() >= 0) {
        min = RangeBoundary::FromConstant(0);
        max = Range::ConstantMax(right_range);
        break;
      }
      if (Range::ConstantMin(left_range).value() >= 0) {
        min = RangeBoundary::FromConstant(0);
        max = Range::ConstantMax(left_range);
        break;
      }

      if (range_ == NULL) {
        range_ = Range::Unknown();
      }
      return;

    default:
      if (range_ == NULL) {
        range_ = Range::Unknown();
      }
      return;
  }

  ASSERT(!min.IsUnknown() && !max.IsUnknown());
  set_overflow(min.LowerBound().Overflowed() || max.UpperBound().Overflowed());

  if (min.IsConstant()) min.Clamp();
  if (max.IsConstant()) max.Clamp();

  range_ = new Range(min, max);
}


// Inclusive.
bool Range::IsWithin(intptr_t min_int, intptr_t max_int) const {
  if (min().LowerBound().value() < min_int) return false;
  if (max().UpperBound().value() > max_int) return false;
  return true;
}


bool CheckArrayBoundInstr::IsRedundant(RangeBoundary length) {
  // Check that array has an immutable length.
  if ((array_type() != kArrayCid) && (array_type() != kImmutableArrayCid)) {
    return false;
  }

  Range* index_range = index()->definition()->range();

  // Range of the index is unknown can't decide if the check is redundant.
  if (index_range == NULL) return false;

  // Range of the index is not positive. Check can't be redundant.
  if (Range::ConstantMin(index_range).value() < 0) return false;

  RangeBoundary max = CanonicalizeBoundary(index_range->max(),
                                           RangeBoundary::OverflowedMaxSmi());

  if (max.Overflowed()) return false;

  // Try to compare constant boundaries.
  if (max.UpperBound().value() < length.LowerBound().value()) {
    return true;
  }

  length = CanonicalizeBoundary(length, RangeBoundary::OverflowedMaxSmi());
  if (length.Overflowed()) return false;

  // Try symbolic comparison.
  do {
    if (DependOnSameSymbol(max, length)) return max.offset() < length.offset();
  } while (CanonicalizeMaxBoundary(&max) || CanonicalizeMinBoundary(&length));

  // Failed to prove that maximum is bounded with array length.
  return false;
}


#undef __

}  // namespace dart
