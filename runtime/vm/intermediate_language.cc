// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"

#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/compiler.h"
#include "vm/constant_propagator.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/locations.h"
#include "vm/method_recognizer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/regexp_assembler_ir.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#include "vm/il_printer.h"

namespace dart {

DEFINE_FLAG(bool,
            propagate_ic_data,
            true,
            "Propagate IC data from unoptimized to optimized IC calls.");
DEFINE_FLAG(bool,
            two_args_smi_icd,
            true,
            "Generate special IC stubs for two args Smi operations");
DEFINE_FLAG(bool,
            unbox_numeric_fields,
            !USING_DBC,
            "Support unboxed double and float32x4 fields.");
DECLARE_FLAG(bool, eliminate_type_checks);
DECLARE_FLAG(bool, support_externalizable_strings);


#if defined(DEBUG)
void Instruction::CheckField(const Field& field) const {
  ASSERT(field.IsZoneHandle());
  ASSERT(!Compiler::IsBackgroundCompilation() || !field.IsOriginal());
}
#endif  // DEBUG


Definition::Definition(intptr_t deopt_id)
    : Instruction(deopt_id),
      range_(NULL),
      type_(NULL),
      temp_index_(-1),
      ssa_temp_index_(-1),
      input_use_list_(NULL),
      env_use_list_(NULL),
      constant_value_(NULL) {}


// A value in the constant propagation lattice.
//    - non-constant sentinel
//    - a constant (any non-sentinel value)
//    - unknown sentinel
Object& Definition::constant_value() {
  if (constant_value_ == NULL) {
    constant_value_ = &Object::ZoneHandle(ConstantPropagator::Unknown());
  }
  return *constant_value_;
}


Definition* Definition::OriginalDefinition() {
  Definition* defn = this;
  while (defn->IsRedefinition() || defn->IsAssertAssignable()) {
    if (defn->IsRedefinition()) {
      defn = defn->AsRedefinition()->value()->definition();
    } else {
      defn = defn->AsAssertAssignable()->value()->definition();
    }
  }
  return defn;
}


const ICData* Instruction::GetICData(
    const ZoneGrowableArray<const ICData*>& ic_data_array) const {
  // The deopt_id can be outside the range of the IC data array for
  // computations added in the optimizing compiler.
  ASSERT(deopt_id_ != Thread::kNoDeoptId);
  if (deopt_id_ < ic_data_array.length()) {
    const ICData* result = ic_data_array[deopt_id_];
#if defined(TAG_IC_DATA)
    if (result != NULL) {
      if (result->tag() == -1) {
        result->set_tag(tag());
      } else if (result->tag() != tag()) {
        FATAL("ICData tag mismatch");
      }
    }
#endif
    return result;
  }
  return NULL;
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


void Instruction::Unsupported(FlowGraphCompiler* compiler) {
  compiler->Bailout(ToCString());
  UNREACHABLE();
}


bool Value::Equals(Value* other) const {
  return definition() == other->definition();
}


static int LowestFirst(const intptr_t* a, const intptr_t* b) {
  return *a - *b;
}


CheckClassInstr::CheckClassInstr(Value* value,
                                 intptr_t deopt_id,
                                 const ICData& unary_checks,
                                 TokenPosition token_pos)
    : TemplateInstruction(deopt_id),
      unary_checks_(unary_checks),
      cids_(unary_checks.NumberOfChecks()),
      licm_hoisted_(false),
      is_dense_switch_(IsDenseCidRange(unary_checks)),
      token_pos_(token_pos) {
  ASSERT(unary_checks.IsZoneHandle());
  // Expected useful check data.
  ASSERT(!unary_checks_.IsNull());
  ASSERT(unary_checks_.NumberOfChecks() > 0);
  ASSERT(unary_checks_.NumArgsTested() == 1);
  SetInputAt(0, value);
  // Otherwise use CheckSmiInstr.
  ASSERT((unary_checks_.NumberOfChecks() != 1) ||
         (unary_checks_.GetReceiverClassIdAt(0) != kSmiCid));
  for (intptr_t i = 0; i < unary_checks.NumberOfChecks(); ++i) {
    cids_.Add(unary_checks.GetReceiverClassIdAt(i));
  }
  cids_.Sort(LowestFirst);
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


static bool AreAllChecksImmutable(const ICData& checks) {
  const intptr_t len = checks.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (checks.IsUsedAt(i)) {
      if (Field::IsExternalizableCid(checks.GetReceiverClassIdAt(i))) {
        return false;
      }
    }
  }
  return true;
}


EffectSet CheckClassInstr::Dependencies() const {
  // Externalization of strings via the API can change the class-id.
  return !AreAllChecksImmutable(unary_checks()) ? EffectSet::Externalization()
                                                : EffectSet::None();
}


EffectSet CheckClassIdInstr::Dependencies() const {
  // Externalization of strings via the API can change the class-id.
  return Field::IsExternalizableCid(cid_) ? EffectSet::Externalization()
                                          : EffectSet::None();
}


bool CheckClassInstr::DeoptIfNull() const {
  if (unary_checks().NumberOfChecks() != 1) {
    return false;
  }
  CompileType* in_type = value()->Type();
  const intptr_t cid = unary_checks().GetCidAt(0);
  // Performance check: use CheckSmiInstr instead.
  ASSERT(cid != kSmiCid);
  return in_type->is_nullable() && (in_type->ToNullableCid() == cid);
}


// Null object is a singleton of null-class (except for some sentinel,
// transitional temporaries). Instead of checking against the null class only
// we can check against null instance instead.
bool CheckClassInstr::DeoptIfNotNull() const {
  if (unary_checks().NumberOfChecks() != 1) {
    return false;
  }
  const intptr_t cid = unary_checks().GetCidAt(0);
  return cid == kNullCid;
}


bool CheckClassInstr::IsDenseCidRange(const ICData& unary_checks) {
  ASSERT(unary_checks.NumArgsTested() == 1);
  // TODO(fschneider): Support smis in dense cid checks.
  if (unary_checks.GetReceiverClassIdAt(0) == kSmiCid) return false;
  if (unary_checks.NumberOfChecks() <= 2) return false;
  intptr_t max = 0;
  intptr_t min = kIntptrMax;
  for (intptr_t i = 0; i < unary_checks.NumberOfChecks(); ++i) {
    intptr_t cid = unary_checks.GetCidAt(i);
    if (cid < min) min = cid;
    if (cid > max) max = cid;
  }
  return (max - min) < kBitsPerWord;
}


bool CheckClassInstr::IsDenseSwitch() const {
  return is_dense_switch_;
}


intptr_t CheckClassInstr::ComputeCidMask() const {
  ASSERT(IsDenseSwitch());
  intptr_t mask = 0;
  for (intptr_t i = 0; i < cids_.length(); ++i) {
    mask |= static_cast<intptr_t>(1) << (cids_[i] - cids_[0]);
  }
  return mask;
}


bool CheckClassInstr::IsDenseMask(intptr_t mask) {
  // Returns true if the mask is a continuos sequence of ones in its binary
  // representation (i.e. no holes)
  return mask == -1 || Utils::IsPowerOfTwo(mask + 1);
}


bool LoadFieldInstr::IsUnboxedLoad() const {
  return FLAG_unbox_numeric_fields && (field() != NULL) &&
         FlowGraphCompiler::IsUnboxedField(*field());
}


bool LoadFieldInstr::IsPotentialUnboxedLoad() const {
  return FLAG_unbox_numeric_fields && (field() != NULL) &&
         FlowGraphCompiler::IsPotentialUnboxedField(*field());
}


Representation LoadFieldInstr::representation() const {
  if (IsUnboxedLoad()) {
    const intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        return kUnboxedDouble;
      case kFloat32x4Cid:
        return kUnboxedFloat32x4;
      case kFloat64x2Cid:
        return kUnboxedFloat64x2;
      default:
        UNREACHABLE();
    }
  }
  return kTagged;
}


bool StoreInstanceFieldInstr::IsUnboxedStore() const {
  return FLAG_unbox_numeric_fields && !field().IsNull() &&
         FlowGraphCompiler::IsUnboxedField(field());
}


bool StoreInstanceFieldInstr::IsPotentialUnboxedStore() const {
  return FLAG_unbox_numeric_fields && !field().IsNull() &&
         FlowGraphCompiler::IsPotentialUnboxedField(field());
}


Representation StoreInstanceFieldInstr::RequiredInputRepresentation(
    intptr_t index) const {
  ASSERT((index == 0) || (index == 1));
  if ((index == 1) && IsUnboxedStore()) {
    const intptr_t cid = field().UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        return kUnboxedDouble;
      case kFloat32x4Cid:
        return kUnboxedFloat32x4;
      case kFloat64x2Cid:
        return kUnboxedFloat64x2;
      default:
        UNREACHABLE();
    }
  }
  return kTagged;
}


bool GuardFieldClassInstr::AttributesEqual(Instruction* other) const {
  return field().raw() == other->AsGuardFieldClass()->field().raw();
}


bool GuardFieldLengthInstr::AttributesEqual(Instruction* other) const {
  return field().raw() == other->AsGuardFieldLength()->field().raw();
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
  return ComparisonInstr::AttributesEqual(other) &&
         (needs_number_check() == other_op->needs_number_check());
}


bool MathMinMaxInstr::AttributesEqual(Instruction* other) const {
  MathMinMaxInstr* other_op = other->AsMathMinMax();
  ASSERT(other_op != NULL);
  return (op_kind() == other_op->op_kind()) &&
         (result_cid() == other_op->result_cid());
}


bool BinaryIntegerOpInstr::AttributesEqual(Instruction* other) const {
  ASSERT(other->tag() == tag());
  BinaryIntegerOpInstr* other_op = other->AsBinaryIntegerOp();
  return (op_kind() == other_op->op_kind()) &&
         (can_overflow() == other_op->can_overflow()) &&
         (is_truncating() == other_op->is_truncating());
}


EffectSet LoadFieldInstr::Dependencies() const {
  return immutable_ ? EffectSet::None() : EffectSet::All();
}


bool LoadFieldInstr::AttributesEqual(Instruction* other) const {
  LoadFieldInstr* other_load = other->AsLoadField();
  ASSERT(other_load != NULL);
  if (field() != NULL) {
    return (other_load->field() != NULL) &&
           (field()->raw() == other_load->field()->raw());
  }
  return (other_load->field() == NULL) &&
         (offset_in_bytes() == other_load->offset_in_bytes());
}


Instruction* InitStaticFieldInstr::Canonicalize(FlowGraph* flow_graph) {
  const bool is_initialized =
      (field_.StaticValue() != Object::sentinel().raw()) &&
      (field_.StaticValue() != Object::transition_sentinel().raw());
  // When precompiling, the fact that a field is currently initialized does not
  // make it safe to omit code that checks if the field needs initialization
  // because the field will be reset so it starts uninitialized in the process
  // running the precompiled code. We must be prepared to reinitialize fields.
  return is_initialized && !FLAG_fields_may_be_reset ? NULL : this;
}


EffectSet LoadStaticFieldInstr::Dependencies() const {
  return (StaticField().is_final() && !FLAG_fields_may_be_reset)
             ? EffectSet::None()
             : EffectSet::All();
}


bool LoadStaticFieldInstr::AttributesEqual(Instruction* other) const {
  LoadStaticFieldInstr* other_load = other->AsLoadStaticField();
  ASSERT(other_load != NULL);
  // Assert that the field is initialized.
  ASSERT(StaticField().StaticValue() != Object::sentinel().raw());
  ASSERT(StaticField().StaticValue() != Object::transition_sentinel().raw());
  return StaticField().raw() == other_load->StaticField().raw();
}


const Field& LoadStaticFieldInstr::StaticField() const {
  Field& field = Field::ZoneHandle();
  field ^= field_value()->BoundConstant().raw();
  return field;
}


ConstantInstr::ConstantInstr(const Object& value, TokenPosition token_pos)
    : value_(value), token_pos_(token_pos) {
  // Check that the value is not an incorrect Integer representation.
  ASSERT(!value.IsBigint() || !Bigint::Cast(value).FitsIntoSmi());
  ASSERT(!value.IsBigint() || !Bigint::Cast(value).FitsIntoInt64());
  ASSERT(!value.IsMint() || !Smi::IsValid(Mint::Cast(value).AsInt64Value()));
  ASSERT(!value.IsField() || Field::Cast(value).IsOriginal());
}


bool ConstantInstr::AttributesEqual(Instruction* other) const {
  ConstantInstr* other_constant = other->AsConstant();
  ASSERT(other_constant != NULL);
  return (value().raw() == other_constant->value().raw());
}


UnboxedConstantInstr::UnboxedConstantInstr(const Object& value,
                                           Representation representation)
    : ConstantInstr(value),
      representation_(representation),
      constant_address_(0) {
  if (representation_ == kUnboxedDouble) {
    ASSERT(value.IsDouble());
    constant_address_ =
        FlowGraphBuilder::FindDoubleConstant(Double::Cast(value).value());
  }
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


GraphEntryInstr::GraphEntryInstr(const ParsedFunction& parsed_function,
                                 TargetEntryInstr* normal_entry,
                                 intptr_t osr_id)
    : BlockEntryInstr(0, CatchClauseNode::kInvalidTryIndex),
      parsed_function_(parsed_function),
      normal_entry_(normal_entry),
      catch_entries_(),
      indirect_entries_(),
      initial_definitions_(),
      osr_id_(osr_id),
      entry_count_(0),
      spill_slot_count_(0),
      fixed_slot_count_(0) {}


ConstantInstr* GraphEntryInstr::constant_null() {
  ASSERT(initial_definitions_.length() > 0);
  for (intptr_t i = 0; i < initial_definitions_.length(); ++i) {
    ConstantInstr* defn = initial_definitions_[i]->AsConstant();
    if (defn != NULL && defn->value().IsNull()) return defn;
  }
  UNREACHABLE();
  return NULL;
}


CatchBlockEntryInstr* GraphEntryInstr::GetCatchEntry(intptr_t index) {
  // TODO(fschneider): Sort the catch entries by catch_try_index to avoid
  // searching.
  for (intptr_t i = 0; i < catch_entries_.length(); ++i) {
    if (catch_entries_[i]->catch_try_index() == index) return catch_entries_[i];
  }
  return NULL;
}


bool GraphEntryInstr::IsCompiledForOsr() const {
  return osr_id_ != Compiler::kNoOSRDeoptId;
}


// ==== Support for visiting flow graphs.

#define DEFINE_ACCEPT(ShortName)                                               \
  void ShortName##Instr::Accept(FlowGraphVisitor* visitor) {                   \
    visitor->Visit##ShortName(this);                                           \
  }

FOR_EACH_INSTRUCTION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT


void Instruction::SetEnvironment(Environment* deopt_env) {
  intptr_t use_index = 0;
  for (Environment::DeepIterator it(deopt_env); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    use->set_instruction(this);
    use->set_use_index(use_index++);
  }
  env_ = deopt_env;
}


void Instruction::RemoveEnvironment() {
  for (Environment::DeepIterator it(env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }
  env_ = NULL;
}


Instruction* Instruction::RemoveFromGraph(bool return_previous) {
  ASSERT(!IsBlockEntry());
  ASSERT(!IsBranch());
  ASSERT(!IsThrow());
  ASSERT(!IsReturn());
  ASSERT(!IsReThrow());
  ASSERT(!IsGoto());
  ASSERT(previous() != NULL);
  // We cannot assert that the instruction, if it is a definition, has no
  // uses.  This function is used to remove instructions from the graph and
  // reinsert them elsewhere (e.g., hoisting).
  Instruction* prev_instr = previous();
  Instruction* next_instr = next();
  ASSERT(next_instr != NULL);
  ASSERT(!next_instr->IsBlockEntry());
  prev_instr->LinkTo(next_instr);
  UnuseAllInputs();
  // Reset the successor and previous instruction to indicate that the
  // instruction is removed from the graph.
  set_previous(NULL);
  set_next(NULL);
  return return_previous ? prev_instr : next_instr;
}


void Instruction::InsertAfter(Instruction* prev) {
  ASSERT(previous_ == NULL);
  ASSERT(next_ == NULL);
  previous_ = prev;
  next_ = prev->next_;
  next_->previous_ = this;
  previous_->next_ = this;

  // Update def-use chains whenever instructions are added to the graph
  // after initial graph construction.
  for (intptr_t i = InputCount() - 1; i >= 0; --i) {
    Value* input = InputAt(i);
    input->definition()->AddInputUse(input);
  }
}


Instruction* Instruction::AppendInstruction(Instruction* tail) {
  LinkTo(tail);
  // Update def-use chains whenever instructions are added to the graph
  // after initial graph construction.
  for (intptr_t i = tail->InputCount() - 1; i >= 0; --i) {
    Value* input = tail->InputAt(i);
    input->definition()->AddInputUse(input);
  }
  return tail;
}


BlockEntryInstr* Instruction::GetBlock() {
  // TODO(fschneider): Implement a faster way to get the block of an
  // instruction.
  ASSERT(previous() != NULL);
  Instruction* result = previous();
  while (!result->IsBlockEntry())
    result = result->previous();
  return result->AsBlockEntry();
}


void ForwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(true);  // Set current_ to previous.
}


void BackwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(false);  // Set current_ to next.
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


bool Value::NeedsStoreBuffer() {
  if (Type()->IsNull() || (Type()->ToNullableCid() == kSmiCid) ||
      (Type()->ToNullableCid() == kBoolCid)) {
    return false;
  }

  return !BindsToConstant();
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


void Value::AddToList(Value* value, Value** list) {
  Value* next = *list;
  *list = value;
  value->set_next_use(next);
  value->set_previous_use(NULL);
  if (next != NULL) next->set_previous_use(value);
}


void Value::RemoveFromUseList() {
  Definition* def = definition();
  Value* next = next_use();
  if (this == def->input_use_list()) {
    def->set_input_use_list(next);
    if (next != NULL) next->set_previous_use(NULL);
  } else if (this == def->env_use_list()) {
    def->set_env_use_list(next);
    if (next != NULL) next->set_previous_use(NULL);
  } else {
    Value* prev = previous_use();
    prev->set_next_use(next);
    if (next != NULL) next->set_previous_use(prev);
  }

  set_previous_use(NULL);
  set_next_use(NULL);
}


// True if the definition has a single input use and is used only in
// environments at the same instruction as that input use.
bool Definition::HasOnlyUse(Value* use) const {
  if (!HasOnlyInputUse(use)) {
    return false;
  }

  Instruction* target = use->instruction();
  for (Value::Iterator it(env_use_list()); !it.Done(); it.Advance()) {
    if (it.Current()->instruction() != target) return false;
  }
  return true;
}


bool Definition::HasOnlyInputUse(Value* use) const {
  return (input_use_list() == use) && (use->next_use() == NULL);
}


void Definition::ReplaceUsesWith(Definition* other) {
  ASSERT(other != NULL);
  ASSERT(this != other);

  Value* current = NULL;
  Value* next = input_use_list();
  if (next != NULL) {
    // Change all the definitions.
    while (next != NULL) {
      current = next;
      current->set_definition(other);
      next = current->next_use();
    }

    // Concatenate the lists.
    next = other->input_use_list();
    current->set_next_use(next);
    if (next != NULL) next->set_previous_use(current);
    other->set_input_use_list(input_use_list());
    set_input_use_list(NULL);
  }

  // Repeat for environment uses.
  current = NULL;
  next = env_use_list();
  if (next != NULL) {
    while (next != NULL) {
      current = next;
      current->set_definition(other);
      next = current->next_use();
    }
    next = other->env_use_list();
    current->set_next_use(next);
    if (next != NULL) next->set_previous_use(current);
    other->set_env_use_list(env_use_list());
    set_env_use_list(NULL);
  }
}


void Instruction::UnuseAllInputs() {
  for (intptr_t i = InputCount() - 1; i >= 0; --i) {
    InputAt(i)->RemoveFromUseList();
  }
  for (Environment::DeepIterator it(env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }
}


void Instruction::InheritDeoptTargetAfter(FlowGraph* flow_graph,
                                          Definition* call,
                                          Definition* result) {
  ASSERT(call->env() != NULL);
  deopt_id_ = Thread::ToDeoptAfter(call->deopt_id_);
  call->env()->DeepCopyAfterTo(
      flow_graph->zone(), this, call->ArgumentCount(),
      flow_graph->constant_dead(),
      result != NULL ? result : flow_graph->constant_dead());
  env()->set_deopt_id(deopt_id_);
}


void Instruction::InheritDeoptTarget(Zone* zone, Instruction* other) {
  ASSERT(other->env() != NULL);
  CopyDeoptIdFrom(*other);
  other->env()->DeepCopyTo(zone, this);
  env()->set_deopt_id(deopt_id_);
}


void BranchInstr::InheritDeoptTarget(Zone* zone, Instruction* other) {
  ASSERT(env() == NULL);
  Instruction::InheritDeoptTarget(zone, other);
  comparison()->SetDeoptId(*this);
}


bool Instruction::IsDominatedBy(Instruction* dom) {
  BlockEntryInstr* block = GetBlock();
  BlockEntryInstr* dom_block = dom->GetBlock();

  if (dom->IsPhi()) {
    dom = dom_block;
  }

  if (block == dom_block) {
    if ((block == dom) || (this == block->last_instruction())) {
      return true;
    }

    if (IsPhi()) {
      return false;
    }

    for (Instruction* curr = dom->next(); curr != NULL; curr = curr->next()) {
      if (curr == this) return true;
    }

    return false;
  }

  return dom_block->Dominates(block);
}


bool Instruction::HasUnmatchedInputRepresentations() const {
  for (intptr_t i = 0; i < InputCount(); i++) {
    Definition* input = InputAt(i)->definition();
    if (RequiredInputRepresentation(i) != input->representation()) {
      return true;
    }
  }

  return false;
}


void Definition::ReplaceWith(Definition* other,
                             ForwardInstructionIterator* iterator) {
  // Record other's input uses.
  for (intptr_t i = other->InputCount() - 1; i >= 0; --i) {
    Value* input = other->InputAt(i);
    input->definition()->AddInputUse(input);
  }
  // Take other's environment from this definition.
  ASSERT(other->env() == NULL);
  other->SetEnvironment(env());
  ClearEnv();
  // Replace all uses of this definition with other.
  ReplaceUsesWith(other);
  // Reuse this instruction's SSA name for other.
  ASSERT(!other->HasSSATemp());
  if (HasSSATemp()) {
    other->set_ssa_temp_index(ssa_temp_index());
  }

  // Finally insert the other definition in place of this one in the graph.
  previous()->LinkTo(other);
  if ((iterator != NULL) && (this == iterator->Current())) {
    // Remove through the iterator.
    other->LinkTo(this);
    iterator->RemoveCurrentFromGraph();
  } else {
    other->LinkTo(next());
    // Remove this definition's input uses.
    UnuseAllInputs();
  }
  set_previous(NULL);
  set_next(NULL);
}


void BranchInstr::SetComparison(ComparisonInstr* new_comparison) {
  for (intptr_t i = new_comparison->InputCount() - 1; i >= 0; --i) {
    Value* input = new_comparison->InputAt(i);
    input->definition()->AddInputUse(input);
    input->set_instruction(this);
  }
  // There should be no need to copy or unuse an environment.
  ASSERT(comparison()->env() == NULL);
  ASSERT(new_comparison->env() == NULL);
  // Remove the current comparison's input uses.
  comparison()->UnuseAllInputs();
  ASSERT(!new_comparison->HasUses());
  comparison_ = new_comparison;
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


// Base class implementation used for JoinEntry and TargetEntry.
bool BlockEntryInstr::DiscoverBlock(BlockEntryInstr* predecessor,
                                    GrowableArray<BlockEntryInstr*>* preorder,
                                    GrowableArray<intptr_t>* parent) {
  // If this block has a predecessor (i.e., is not the graph entry) we can
  // assume the preorder array is non-empty.
  ASSERT((predecessor == NULL) || !preorder->is_empty());
  // Blocks with a single predecessor cannot have been reached before.
  ASSERT(IsJoinEntry() || !IsMarked(this, preorder));

  // 1. If the block has already been reached, add current_block as a
  // basic-block predecessor and we are done.
  if (IsMarked(this, preorder)) {
    ASSERT(predecessor != NULL);
    AddPredecessor(predecessor);
    return false;
  }

  // 2. Otherwise, clear the predecessors which might have been computed on
  // some earlier call to DiscoverBlocks and record this predecessor.
  ClearPredecessors();
  if (predecessor != NULL) AddPredecessor(predecessor);

  // 3. The predecessor is the spanning-tree parent.  The graph entry has no
  // parent, indicated by -1.
  intptr_t parent_number =
      (predecessor == NULL) ? -1 : predecessor->preorder_number();
  parent->Add(parent_number);

  // 4. Assign the preorder number and add the block entry to the list.
  set_preorder_number(preorder->length());
  preorder->Add(this);

  // The preorder and parent arrays are indexed by
  // preorder block number, so they should stay in lockstep.
  ASSERT(preorder->length() == parent->length());

  // 5. Iterate straight-line successors to record assigned variables and
  // find the last instruction in the block.  The graph entry block consists
  // of only the entry instruction, so that is the last instruction in the
  // block.
  Instruction* last = this;
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    last = it.Current();
  }
  set_last_instruction(last);
  if (last->IsGoto()) last->AsGoto()->set_block(this);

  return true;
}


bool BlockEntryInstr::PruneUnreachable(GraphEntryInstr* graph_entry,
                                       Instruction* parent,
                                       intptr_t osr_id,
                                       BitVector* block_marks) {
  // Search for the instruction with the OSR id.  Use a depth first search
  // because basic blocks have not been discovered yet.  Prune unreachable
  // blocks by replacing the normal entry with a jump to the block
  // containing the OSR entry point.

  // Do not visit blocks more than once.
  if (block_marks->Contains(block_id())) return false;
  block_marks->Add(block_id());

  // Search this block for the OSR id.
  Instruction* instr = this;
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    instr = it.Current();
    if (instr->GetDeoptId() == osr_id) {
      // Sanity check that we found a stack check instruction.
      ASSERT(instr->IsCheckStackOverflow());
      // Loop stack check checks are always in join blocks so that they can
      // be the target of a goto.
      ASSERT(IsJoinEntry());
      // The instruction should be the first instruction in the block so
      // we can simply jump to the beginning of the block.
      ASSERT(instr->previous() == this);

      GotoInstr* goto_join = new GotoInstr(AsJoinEntry());
      goto_join->CopyDeoptIdFrom(*parent);
      graph_entry->normal_entry()->LinkTo(goto_join);
      return true;
    }
  }

  // Recursively search the successors.
  for (intptr_t i = instr->SuccessorCount() - 1; i >= 0; --i) {
    if (instr->SuccessorAt(i)->PruneUnreachable(graph_entry, instr, osr_id,
                                                block_marks)) {
      return true;
    }
  }
  return false;
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


BlockEntryInstr* BlockEntryInstr::ImmediateDominator() const {
  Instruction* last = dominator()->last_instruction();
  if ((last->SuccessorCount() == 1) && (last->SuccessorAt(0) == this)) {
    return dominator();
  }
  return NULL;
}


// Helper to mutate the graph during inlining. This block should be
// replaced with new_block as a predecessor of all of this block's
// successors.  For each successor, the predecessors will be reordered
// to preserve block-order sorting of the predecessors as well as the
// phis if the successor is a join.
void BlockEntryInstr::ReplaceAsPredecessorWith(BlockEntryInstr* new_block) {
  // Set the last instruction of the new block to that of the old block.
  Instruction* last = last_instruction();
  new_block->set_last_instruction(last);
  // For each successor, update the predecessors.
  for (intptr_t sidx = 0; sidx < last->SuccessorCount(); ++sidx) {
    // If the successor is a target, update its predecessor.
    TargetEntryInstr* target = last->SuccessorAt(sidx)->AsTargetEntry();
    if (target != NULL) {
      target->predecessor_ = new_block;
      continue;
    }
    // If the successor is a join, update each predecessor and the phis.
    JoinEntryInstr* join = last->SuccessorAt(sidx)->AsJoinEntry();
    ASSERT(join != NULL);
    // Find the old predecessor index.
    intptr_t old_index = join->IndexOfPredecessor(this);
    intptr_t pred_count = join->PredecessorCount();
    ASSERT(old_index >= 0);
    ASSERT(old_index < pred_count);
    // Find the new predecessor index while reordering the predecessors.
    intptr_t new_id = new_block->block_id();
    intptr_t new_index = old_index;
    if (block_id() < new_id) {
      // Search upwards, bubbling down intermediate predecessors.
      for (; new_index < pred_count - 1; ++new_index) {
        if (join->predecessors_[new_index + 1]->block_id() > new_id) break;
        join->predecessors_[new_index] = join->predecessors_[new_index + 1];
      }
    } else {
      // Search downwards, bubbling up intermediate predecessors.
      for (; new_index > 0; --new_index) {
        if (join->predecessors_[new_index - 1]->block_id() < new_id) break;
        join->predecessors_[new_index] = join->predecessors_[new_index - 1];
      }
    }
    join->predecessors_[new_index] = new_block;
    // If the new and old predecessor index match there is nothing to update.
    if ((join->phis() == NULL) || (old_index == new_index)) return;
    // Otherwise, reorder the predecessor uses in each phi.
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      ASSERT(phi != NULL);
      ASSERT(pred_count == phi->InputCount());
      // Save the predecessor use.
      Value* pred_use = phi->InputAt(old_index);
      // Move uses between old and new.
      intptr_t step = (old_index < new_index) ? 1 : -1;
      for (intptr_t use_idx = old_index; use_idx != new_index;
           use_idx += step) {
        phi->SetInputAt(use_idx, phi->InputAt(use_idx + step));
      }
      // Write the predecessor use.
      phi->SetInputAt(new_index, pred_use);
    }
  }
}


void BlockEntryInstr::ClearAllInstructions() {
  JoinEntryInstr* join = this->AsJoinEntry();
  if (join != NULL) {
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      it.Current()->UnuseAllInputs();
    }
  }
  UnuseAllInputs();
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    it.Current()->UnuseAllInputs();
  }
}


PhiInstr* JoinEntryInstr::InsertPhi(intptr_t var_index, intptr_t var_count) {
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
  return (*phis_)[var_index] = new PhiInstr(this, PredecessorCount());
}


void JoinEntryInstr::InsertPhi(PhiInstr* phi) {
  // Lazily initialize the array of phis.
  if (phis_ == NULL) {
    phis_ = new ZoneGrowableArray<PhiInstr*>(1);
  }
  phis_->Add(phi);
}

void JoinEntryInstr::RemovePhi(PhiInstr* phi) {
  ASSERT(phis_ != NULL);
  for (intptr_t index = 0; index < phis_->length(); ++index) {
    if (phi == (*phis_)[index]) {
      (*phis_)[index] = phis_->Last();
      phis_->RemoveLast();
      return;
    }
  }
}

void JoinEntryInstr::RemoveDeadPhis(Definition* replacement) {
  if (phis_ == NULL) return;

  intptr_t to_index = 0;
  for (intptr_t from_index = 0; from_index < phis_->length(); ++from_index) {
    PhiInstr* phi = (*phis_)[from_index];
    if (phi != NULL) {
      if (phi->is_alive()) {
        (*phis_)[to_index++] = phi;
        for (intptr_t i = phi->InputCount() - 1; i >= 0; --i) {
          Value* input = phi->InputAt(i);
          input->definition()->AddInputUse(input);
        }
      } else {
        phi->ReplaceUsesWith(replacement);
      }
    }
  }
  if (to_index == 0) {
    phis_ = NULL;
  } else {
    phis_->TruncateTo(to_index);
  }
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
  LinkTo(new GotoInstr(entry));
}


bool UnboxedIntConverterInstr::CanDeoptimize() const {
  return (to() == kUnboxedInt32) && !is_truncating() &&
         !RangeUtils::Fits(value()->definition()->range(),
                           RangeBoundary::kRangeBoundaryInt32);
}


bool UnboxInt32Instr::CanDeoptimize() const {
  const intptr_t value_cid = value()->Type()->ToCid();
  if (value_cid == kSmiCid) {
    return (kSmiBits > 32) && !is_truncating() &&
           !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else if (value_cid == kMintCid) {
    return !is_truncating() &&
           !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else if (is_truncating() && value()->definition()->IsBoxInteger()) {
    return false;
  } else if ((kSmiBits < 32) && value()->Type()->IsInt()) {
    // Note: we don't support truncation of Bigint values.
    return !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else {
    return true;
  }
}


bool UnboxUint32Instr::CanDeoptimize() const {
  ASSERT(is_truncating());
  if ((value()->Type()->ToCid() == kSmiCid) ||
      (value()->Type()->ToCid() == kMintCid)) {
    return false;
  }
  // Check input value's range.
  Range* value_range = value()->definition()->range();
  return !RangeUtils::Fits(value_range, RangeBoundary::kRangeBoundaryInt64);
}


bool BinaryInt32OpInstr::CanDeoptimize() const {
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return false;

    case Token::kSHR:
      return false;

    case Token::kSHL:
      return can_overflow() ||
             !RangeUtils::IsPositive(right()->definition()->range());

    case Token::kMOD: {
      UNREACHABLE();
    }

    default:
      return can_overflow();
  }
}


bool BinarySmiOpInstr::CanDeoptimize() const {
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return false;

    case Token::kSHR:
      return !RangeUtils::IsPositive(right()->definition()->range());

    case Token::kSHL:
      return can_overflow() ||
             !RangeUtils::IsPositive(right()->definition()->range());

    case Token::kMOD: {
      Range* right_range = this->right()->definition()->range();
      return (right_range == NULL) || right_range->Overlaps(0, 0);
    }
    default:
      return can_overflow();
  }
}


bool BinaryIntegerOpInstr::RightIsPowerOfTwoConstant() const {
  if (!right()->definition()->IsConstant()) return false;
  const Object& constant = right()->definition()->AsConstant()->value();
  if (!constant.IsSmi()) return false;
  const intptr_t int_value = Smi::Cast(constant).Value();
  return Utils::IsPowerOfTwo(Utils::Abs(int_value));
}


static intptr_t RepresentationBits(Representation r) {
  switch (r) {
    case kTagged:
      return kBitsPerWord - 1;
    case kUnboxedInt32:
    case kUnboxedUint32:
      return 32;
    case kUnboxedMint:
      return 64;
    default:
      UNREACHABLE();
      return 0;
  }
}


static int64_t RepresentationMask(Representation r) {
  return static_cast<int64_t>(static_cast<uint64_t>(-1) >>
                              (64 - RepresentationBits(r)));
}


static bool ToIntegerConstant(Value* value, int64_t* result) {
  if (!value->BindsToConstant()) {
    UnboxInstr* unbox = value->definition()->AsUnbox();
    if (unbox != NULL) {
      switch (unbox->representation()) {
        case kUnboxedDouble:
        case kUnboxedMint:
          return ToIntegerConstant(unbox->value(), result);

        case kUnboxedUint32:
          if (ToIntegerConstant(unbox->value(), result)) {
            *result &= RepresentationMask(kUnboxedUint32);
            return true;
          }
          break;

        // No need to handle Unbox<Int32>(Constant(C)) because it gets
        // canonicalized to UnboxedConstant<Int32>(C).
        case kUnboxedInt32:
        default:
          break;
      }
    }
    return false;
  }

  const Object& constant = value->BoundConstant();
  if (constant.IsDouble()) {
    const Double& double_constant = Double::Cast(constant);
    *result = static_cast<int64_t>(double_constant.value());
    return (static_cast<double>(*result) == double_constant.value());
  } else if (constant.IsSmi()) {
    *result = Smi::Cast(constant).Value();
    return true;
  } else if (constant.IsMint()) {
    *result = Mint::Cast(constant).value();
    return true;
  }

  return false;
}


static Definition* CanonicalizeCommutativeDoubleArithmetic(Token::Kind op,
                                                           Value* left,
                                                           Value* right) {
  int64_t left_value;
  if (!ToIntegerConstant(left, &left_value)) {
    return NULL;
  }

  // Can't apply 0.0 * x -> 0.0 equivalence to double operation because
  // 0.0 * NaN is NaN not 0.0.
  // Can't apply 0.0 + x -> x to double because 0.0 + (-0.0) is 0.0 not -0.0.
  switch (op) {
    case Token::kMUL:
      if (left_value == 1) {
        if (right->definition()->representation() != kUnboxedDouble) {
          // Can't yet apply the equivalence because representation selection
          // did not run yet. We need it to guarantee that right value is
          // correctly coerced to double. The second canonicalization pass
          // will apply this equivalence.
          return NULL;
        } else {
          return right->definition();
        }
      }
      break;
    default:
      break;
  }

  return NULL;
}


Definition* DoubleToFloatInstr::Canonicalize(FlowGraph* flow_graph) {
#ifdef DEBUG
  // Must only be used in Float32 StoreIndexedInstr or FloatToDoubleInstr or
  // Phis introduce by load forwarding.
  ASSERT(env_use_list() == NULL);
  for (Value* use = input_use_list(); use != NULL; use = use->next_use()) {
    ASSERT(use->instruction()->IsPhi() ||
           use->instruction()->IsFloatToDouble() ||
           (use->instruction()->IsStoreIndexed() &&
            (use->instruction()->AsStoreIndexed()->class_id() ==
             kTypedDataFloat32ArrayCid)));
  }
#endif
  if (!HasUses()) return NULL;
  if (value()->definition()->IsFloatToDouble()) {
    // F2D(D2F(v)) == v.
    return value()->definition()->AsFloatToDouble()->value()->definition();
  }
  return this;
}


Definition* FloatToDoubleInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : NULL;
}


Definition* BinaryDoubleOpInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return NULL;

  Definition* result = NULL;

  result = CanonicalizeCommutativeDoubleArithmetic(op_kind(), left(), right());
  if (result != NULL) {
    return result;
  }

  result = CanonicalizeCommutativeDoubleArithmetic(op_kind(), right(), left());
  if (result != NULL) {
    return result;
  }

  if ((op_kind() == Token::kMUL) &&
      (left()->definition() == right()->definition())) {
    MathUnaryInstr* math_unary = new MathUnaryInstr(
        MathUnaryInstr::kDoubleSquare, new Value(left()->definition()),
        DeoptimizationTarget());
    flow_graph->InsertBefore(this, math_unary, env(), FlowGraph::kValue);
    return math_unary;
  }

  return this;
}


Definition* DoubleTestOpInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : NULL;
}


static bool IsCommutative(Token::Kind op) {
  switch (op) {
    case Token::kMUL:
    case Token::kADD:
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return true;
    default:
      return false;
  }
}


UnaryIntegerOpInstr* UnaryIntegerOpInstr::Make(Representation representation,
                                               Token::Kind op_kind,
                                               Value* value,
                                               intptr_t deopt_id,
                                               Range* range) {
  UnaryIntegerOpInstr* op = NULL;
  switch (representation) {
    case kTagged:
      op = new UnarySmiOpInstr(op_kind, value, deopt_id);
      break;
    case kUnboxedInt32:
      return NULL;
    case kUnboxedUint32:
      op = new UnaryUint32OpInstr(op_kind, value, deopt_id);
      break;
    case kUnboxedMint:
      op = new UnaryMintOpInstr(op_kind, value, deopt_id);
      break;
    default:
      UNREACHABLE();
      return NULL;
  }

  if (op == NULL) {
    return op;
  }

  if (!Range::IsUnknown(range)) {
    op->set_range(*range);
  }

  ASSERT(op->representation() == representation);
  return op;
}


BinaryIntegerOpInstr* BinaryIntegerOpInstr::Make(Representation representation,
                                                 Token::Kind op_kind,
                                                 Value* left,
                                                 Value* right,
                                                 intptr_t deopt_id,
                                                 bool can_overflow,
                                                 bool is_truncating,
                                                 Range* range) {
  BinaryIntegerOpInstr* op = NULL;
  switch (representation) {
    case kTagged:
      op = new BinarySmiOpInstr(op_kind, left, right, deopt_id);
      break;
    case kUnboxedInt32:
      if (!BinaryInt32OpInstr::IsSupported(op_kind, left, right)) {
        return NULL;
      }
      op = new BinaryInt32OpInstr(op_kind, left, right, deopt_id);
      break;
    case kUnboxedUint32:
      if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
        op = new ShiftUint32OpInstr(op_kind, left, right, deopt_id);
      } else {
        op = new BinaryUint32OpInstr(op_kind, left, right, deopt_id);
      }
      break;
    case kUnboxedMint:
      if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
        op = new ShiftMintOpInstr(op_kind, left, right, deopt_id);
      } else {
        op = new BinaryMintOpInstr(op_kind, left, right, deopt_id);
      }
      break;
    default:
      UNREACHABLE();
      return NULL;
  }

  if (!Range::IsUnknown(range)) {
    op->set_range(*range);
  }

  op->set_can_overflow(can_overflow);
  if (is_truncating) {
    op->mark_truncating();
  }

  ASSERT(op->representation() == representation);
  return op;
}


static bool IsRepresentable(const Integer& value, Representation rep) {
  switch (rep) {
    case kTagged:  // Smi case.
      return value.IsSmi();

    case kUnboxedInt32:
      if (value.IsSmi() || value.IsMint()) {
        return Utils::IsInt(32, value.AsInt64Value());
      }
      return false;

    case kUnboxedMint:
      return value.IsSmi() || value.IsMint();

    case kUnboxedUint32:  // Only truncating Uint32 arithmetic is supported.
    default:
      UNREACHABLE();
  }

  return false;
}


RawInteger* UnaryIntegerOpInstr::Evaluate(const Integer& value) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Integer& result = Integer::Handle(zone);

  switch (op_kind()) {
    case Token::kNEGATE:
      result = value.ArithmeticOp(Token::kMUL, Smi::Handle(zone, Smi::New(-1)),
                                  Heap::kOld);
      break;

    case Token::kBIT_NOT:
      if (value.IsSmi()) {
        result = Integer::New(~Smi::Cast(value).Value());
      } else if (value.IsMint()) {
        result = Integer::New(~Mint::Cast(value).value());
      }
      break;

    default:
      UNREACHABLE();
  }

  if (!result.IsNull()) {
    if (!IsRepresentable(result, representation())) {
      // If this operation is not truncating it would deoptimize on overflow.
      // Check that we match this behavior and don't produce a value that is
      // larger than something this operation can produce. We could have
      // specialized instructions that use this value under this assumption.
      return Integer::null();
    }
    result ^= result.CheckAndCanonicalize(thread, NULL);
  }

  return result.raw();
}


RawInteger* BinaryIntegerOpInstr::Evaluate(const Integer& left,
                                           const Integer& right) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Integer& result = Integer::Handle(zone);

  switch (op_kind()) {
    case Token::kTRUNCDIV:
    case Token::kMOD:
      // Check right value for zero.
      if (right.IsSmi() && right.AsInt64Value() == 0) {
        break;  // Will throw.
      }
    // Fall through.
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL: {
      result = left.ArithmeticOp(op_kind(), right, Heap::kOld);
      break;
    }
    case Token::kSHL:
    case Token::kSHR:
      if (left.IsSmi() && right.IsSmi() && (Smi::Cast(right).Value() >= 0)) {
        result =
            Smi::Cast(left).ShiftOp(op_kind(), Smi::Cast(right), Heap::kOld);
      }
      break;
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR: {
      result = left.BitOp(op_kind(), right, Heap::kOld);
      break;
    }
    case Token::kDIV:
      break;
    default:
      UNREACHABLE();
  }

  if (!result.IsNull()) {
    if (is_truncating()) {
      int64_t truncated = result.AsTruncatedInt64Value();
      truncated &= RepresentationMask(representation());
      result = Integer::New(truncated);
      ASSERT(IsRepresentable(result, representation()));
    } else if (!IsRepresentable(result, representation())) {
      // If this operation is not truncating it would deoptimize on overflow.
      // Check that we match this behavior and don't produce a value that is
      // larger than something this operation can produce. We could have
      // specialized instructions that use this value under this assumption.
      return Integer::null();
    }
    result ^= result.CheckAndCanonicalize(thread, NULL);
  }

  return result.raw();
}


Definition* BinaryIntegerOpInstr::CreateConstantResult(FlowGraph* flow_graph,
                                                       const Integer& result) {
  Definition* result_defn = flow_graph->GetConstant(result);
  if (representation() != kTagged) {
    result_defn = UnboxInstr::Create(representation(), new Value(result_defn),
                                     GetDeoptId());
    flow_graph->InsertBefore(this, result_defn, env(), FlowGraph::kValue);
  }
  return result_defn;
}


Definition* CheckedSmiOpInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((left()->Type()->ToCid() == kSmiCid) &&
      (right()->Type()->ToCid() == kSmiCid)) {
    Definition* replacement = NULL;
    // Operations that can't deoptimize are specialized here: These include
    // bit-wise operators and comparisons. Other arithmetic operations can
    // overflow or divide by 0 and can't be specialized unless we have extra
    // range information.
    switch (op_kind()) {
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        replacement = new BinarySmiOpInstr(
            op_kind(), new Value(left()->definition()),
            new Value(right()->definition()), Thread::kNoDeoptId);
      default:
        break;
    }
    if (replacement != NULL) {
      flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
      return replacement;
    }
  }
  return this;
}


ComparisonInstr* CheckedSmiComparisonInstr::CopyWithNewOperands(Value* left,
                                                                Value* right) {
  UNREACHABLE();
  return NULL;
}


Definition* CheckedSmiComparisonInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((left()->Type()->ToCid() == kSmiCid) &&
      (right()->Type()->ToCid() == kSmiCid)) {
    Definition* replacement = NULL;
    if (Token::IsRelationalOperator(kind())) {
      replacement = new RelationalOpInstr(
          token_pos(), kind(), new Value(left()->definition()),
          new Value(right()->definition()), kSmiCid, Thread::kNoDeoptId);
    } else if (Token::IsEqualityOperator(kind())) {
      replacement = new EqualityCompareInstr(
          token_pos(), kind(), new Value(left()->definition()),
          new Value(right()->definition()), kSmiCid, Thread::kNoDeoptId);
    }
    if (replacement != NULL) {
      flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
      return replacement;
    }
  }
  return this;
}


Definition* BinaryIntegerOpInstr::Canonicalize(FlowGraph* flow_graph) {
  // If both operands are constants evaluate this expression. Might
  // occur due to load forwarding after constant propagation pass
  // have already been run.
  if (left()->BindsToConstant() && left()->BoundConstant().IsInteger() &&
      right()->BindsToConstant() && right()->BoundConstant().IsInteger()) {
    const Integer& result =
        Integer::Handle(Evaluate(Integer::Cast(left()->BoundConstant()),
                                 Integer::Cast(right()->BoundConstant())));
    if (!result.IsNull()) {
      return CreateConstantResult(flow_graph, result);
    }
  }

  if (left()->BindsToConstant() && !right()->BindsToConstant() &&
      IsCommutative(op_kind())) {
    Value* l = left();
    Value* r = right();
    SetInputAt(0, r);
    SetInputAt(1, l);
  }

  int64_t rhs;
  if (!ToIntegerConstant(right(), &rhs)) {
    return this;
  }

  const int64_t range_mask = RepresentationMask(representation());
  if (is_truncating()) {
    switch (op_kind()) {
      case Token::kMUL:
      case Token::kSUB:
      case Token::kADD:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        rhs = (rhs & range_mask);
        break;
      default:
        break;
    }
  }

  switch (op_kind()) {
    case Token::kMUL:
      if (rhs == 1) {
        return left()->definition();
      } else if (rhs == 0) {
        return right()->definition();
      } else if (rhs == 2) {
        ConstantInstr* constant_1 =
            flow_graph->GetConstant(Smi::Handle(Smi::New(1)));
        BinaryIntegerOpInstr* shift = BinaryIntegerOpInstr::Make(
            representation(), Token::kSHL, left()->CopyWithType(),
            new Value(constant_1), GetDeoptId(), can_overflow(),
            is_truncating(), range());
        if (shift != NULL) {
          flow_graph->InsertBefore(this, shift, env(), FlowGraph::kValue);
          return shift;
        }
      }

      break;
    case Token::kADD:
      if (rhs == 0) {
        return left()->definition();
      }
      break;
    case Token::kBIT_AND:
      if (rhs == 0) {
        return right()->definition();
      } else if (rhs == range_mask) {
        return left()->definition();
      }
      break;
    case Token::kBIT_OR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs == range_mask) {
        return right()->definition();
      }
      break;
    case Token::kBIT_XOR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs == range_mask) {
        UnaryIntegerOpInstr* bit_not = UnaryIntegerOpInstr::Make(
            representation(), Token::kBIT_NOT, left()->CopyWithType(),
            GetDeoptId(), range());
        if (bit_not != NULL) {
          flow_graph->InsertBefore(this, bit_not, env(), FlowGraph::kValue);
          return bit_not;
        }
      }
      break;

    case Token::kSUB:
      if (rhs == 0) {
        return left()->definition();
      }
      break;

    case Token::kTRUNCDIV:
      if (rhs == 1) {
        return left()->definition();
      } else if (rhs == -1) {
        UnaryIntegerOpInstr* negation = UnaryIntegerOpInstr::Make(
            representation(), Token::kNEGATE, left()->CopyWithType(),
            GetDeoptId(), range());
        if (negation != NULL) {
          flow_graph->InsertBefore(this, negation, env(), FlowGraph::kValue);
          return negation;
        }
      }
      break;

    case Token::kSHR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs < 0) {
        DeoptimizeInstr* deopt =
            new DeoptimizeInstr(ICData::kDeoptBinarySmiOp, GetDeoptId());
        flow_graph->InsertBefore(this, deopt, env(), FlowGraph::kEffect);
        return CreateConstantResult(flow_graph, Integer::Handle(Smi::New(0)));
      }
      break;

    case Token::kSHL: {
      const intptr_t kMaxShift = RepresentationBits(representation()) - 1;
      if (rhs == 0) {
        return left()->definition();
      } else if ((rhs < 0) || (rhs >= kMaxShift)) {
        if ((rhs < 0) || !is_truncating()) {
          DeoptimizeInstr* deopt =
              new DeoptimizeInstr(ICData::kDeoptBinarySmiOp, GetDeoptId());
          flow_graph->InsertBefore(this, deopt, env(), FlowGraph::kEffect);
        }
        return CreateConstantResult(flow_graph, Integer::Handle(Smi::New(0)));
      }
      break;
    }

    default:
      break;
  }

  return this;
}


// Optimizations that eliminate or simplify individual instructions.
Instruction* Instruction::Canonicalize(FlowGraph* flow_graph) {
  return this;
}


Definition* Definition::Canonicalize(FlowGraph* flow_graph) {
  return this;
}


bool LoadFieldInstr::IsImmutableLengthLoad() const {
  switch (recognized_kind()) {
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
    case MethodRecognizer::kTypedDataLength:
    case MethodRecognizer::kStringBaseLength:
      return true;
    default:
      return false;
  }
}


MethodRecognizer::Kind LoadFieldInstr::RecognizedKindFromArrayCid(
    intptr_t cid) {
  if (RawObject::IsTypedDataClassId(cid) ||
      RawObject::IsExternalTypedDataClassId(cid)) {
    return MethodRecognizer::kTypedDataLength;
  }
  switch (cid) {
    case kArrayCid:
      return MethodRecognizer::kObjectArrayLength;
    case kImmutableArrayCid:
      return MethodRecognizer::kImmutableArrayLength;
    case kGrowableObjectArrayCid:
      return MethodRecognizer::kGrowableArrayLength;
    default:
      UNREACHABLE();
      return MethodRecognizer::kUnknown;
  }
}


bool LoadFieldInstr::IsFixedLengthArrayCid(intptr_t cid) {
  if (RawObject::IsTypedDataClassId(cid) ||
      RawObject::IsExternalTypedDataClassId(cid)) {
    return true;
  }

  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return true;
    default:
      return false;
  }
}


Definition* ConstantInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : NULL;
}


// A math unary instruction has a side effect (exception
// thrown) if the argument is not a number.
// TODO(srdjan): eliminate if has no uses and input is guaranteed to be number.
Definition* MathUnaryInstr::Canonicalize(FlowGraph* flow_graph) {
  return this;
}


Definition* LoadFieldInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return NULL;
  if (!IsImmutableLengthLoad()) return this;

  // For fixed length arrays if the array is the result of a known constructor
  // call we can replace the length load with the length argument passed to
  // the constructor.
  StaticCallInstr* call =
      instance()->definition()->OriginalDefinition()->AsStaticCall();
  if (call != NULL) {
    if (call->is_known_list_constructor() &&
        IsFixedLengthArrayCid(call->Type()->ToCid())) {
      return call->ArgumentAt(1);
    }
  }

  CreateArrayInstr* create_array =
      instance()->definition()->OriginalDefinition()->AsCreateArray();
  if ((create_array != NULL) &&
      (recognized_kind() == MethodRecognizer::kObjectArrayLength)) {
    return create_array->num_elements()->definition();
  }

  // For arrays with guarded lengths, replace the length load
  // with a constant.
  LoadFieldInstr* load_array =
      instance()->definition()->OriginalDefinition()->AsLoadField();
  if (load_array != NULL) {
    const Field* field = load_array->field();
    if ((field != NULL) && (field->guarded_list_length() >= 0)) {
      return flow_graph->GetConstant(
          Smi::Handle(Smi::New(field->guarded_list_length())));
    }
  }
  return this;
}


Definition* AssertBooleanInstr::Canonicalize(FlowGraph* flow_graph) {
  if (FLAG_eliminate_type_checks && (value()->Type()->ToCid() == kBoolCid)) {
    return value()->definition();
  }

  return this;
}


Definition* AssertAssignableInstr::Canonicalize(FlowGraph* flow_graph) {
  if (FLAG_eliminate_type_checks &&
      value()->Type()->IsAssignableTo(dst_type())) {
    return value()->definition();
  }

  // For uninstantiated target types: If the instantiator type arguments
  // are constant, instantiate the target type here.
  if (dst_type().IsInstantiated()) return this;

  ConstantInstr* constant_type_args =
      instantiator_type_arguments()->definition()->AsConstant();
  if (constant_type_args != NULL && !constant_type_args->value().IsNull() &&
      constant_type_args->value().IsTypeArguments()) {
    const TypeArguments& instantiator_type_args =
        TypeArguments::Cast(constant_type_args->value());
    Error& bound_error = Error::Handle();
    AbstractType& new_dst_type =
        AbstractType::Handle(dst_type().InstantiateFrom(
            instantiator_type_args, &bound_error, NULL, NULL, Heap::kOld));
    if (new_dst_type.IsMalformedOrMalbounded() || !bound_error.IsNull()) {
      return this;
    }
    if (new_dst_type.IsTypeRef()) {
      new_dst_type = TypeRef::Cast(new_dst_type).type();
    }
    new_dst_type = new_dst_type.Canonicalize();
    set_dst_type(new_dst_type);

    if (new_dst_type.IsDynamicType() || new_dst_type.IsObjectType() ||
        (FLAG_eliminate_type_checks &&
         value()->Type()->IsAssignableTo(new_dst_type))) {
      return value()->definition();
    }

    ConstantInstr* null_constant = flow_graph->constant_null();
    instantiator_type_arguments()->BindTo(null_constant);
  }
  return this;
}


Definition* InstantiateTypeArgumentsInstr::Canonicalize(FlowGraph* flow_graph) {
  return (Isolate::Current()->type_checks() || HasUses()) ? this : NULL;
}


LocationSummary* DebugStepCheckInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  return locs;
}


Instruction* DebugStepCheckInstr::Canonicalize(FlowGraph* flow_graph) {
  return NULL;
}


static bool HasTryBlockUse(Value* use_list) {
  for (Value::Iterator it(use_list); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    if (use->instruction()->MayThrow() &&
        use->instruction()->GetBlock()->InsideTryBlock()) {
      return true;
    }
  }
  return false;
}


Definition* BoxInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((input_use_list() == NULL) && !HasTryBlockUse(env_use_list())) {
    // Environments can accomodate any representation. No need to box.
    return value()->definition();
  }

  // Fold away Box<rep>(Unbox<rep>(v)) if value is known to be of the
  // right class.
  UnboxInstr* unbox_defn = value()->definition()->AsUnbox();
  if ((unbox_defn != NULL) &&
      (unbox_defn->representation() == from_representation()) &&
      (unbox_defn->value()->Type()->ToCid() == Type()->ToCid())) {
    return unbox_defn->value()->definition();
  }

  return this;
}


bool BoxIntegerInstr::ValueFitsSmi() const {
  Range* range = value()->definition()->range();
  return RangeUtils::Fits(range, RangeBoundary::kRangeBoundarySmi);
}


Definition* BoxIntegerInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((input_use_list() == NULL) && !HasTryBlockUse(env_use_list())) {
    // Environments can accomodate any representation. No need to box.
    return value()->definition();
  }

  return this;
}


Definition* BoxInt64Instr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = BoxIntegerInstr::Canonicalize(flow_graph);
  if (replacement != this) {
    return replacement;
  }

  UnboxedIntConverterInstr* conv =
      value()->definition()->AsUnboxedIntConverter();
  if (conv != NULL) {
    Definition* replacement = this;

    switch (conv->from()) {
      case kUnboxedInt32:
        replacement = new BoxInt32Instr(conv->value()->CopyWithType());
        break;
      case kUnboxedUint32:
        replacement = new BoxUint32Instr(conv->value()->CopyWithType());
        break;
      default:
        UNREACHABLE();
        break;
    }

    if (replacement != this) {
      flow_graph->InsertBefore(this, replacement, NULL, FlowGraph::kValue);
    }

    return replacement;
  }

  return this;
}


Definition* UnboxInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses() && !CanDeoptimize()) return NULL;

  // Fold away Unbox<rep>(Box<rep>(v)).
  BoxInstr* box_defn = value()->definition()->AsBox();
  if ((box_defn != NULL) &&
      (box_defn->from_representation() == representation())) {
    return box_defn->value()->definition();
  }

  if ((representation() == kUnboxedDouble) && value()->BindsToConstant()) {
    UnboxedConstantInstr* uc = NULL;

    const Object& val = value()->BoundConstant();
    if (val.IsSmi()) {
      const Double& double_val = Double::ZoneHandle(
          flow_graph->zone(),
          Double::NewCanonical(Smi::Cast(val).AsDoubleValue()));
      uc = new UnboxedConstantInstr(double_val, kUnboxedDouble);
    } else if (val.IsDouble()) {
      uc = new UnboxedConstantInstr(val, kUnboxedDouble);
    }

    if (uc != NULL) {
      flow_graph->InsertBefore(this, uc, NULL, FlowGraph::kValue);
      return uc;
    }
  }

  return this;
}


Definition* UnboxIntegerInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses() && !CanDeoptimize()) return NULL;

  // Fold away UnboxInteger<rep_to>(BoxInteger<rep_from>(v)).
  BoxIntegerInstr* box_defn = value()->definition()->AsBoxInteger();
  if (box_defn != NULL) {
    Representation from_representation =
        box_defn->value()->definition()->representation();
    if (from_representation == representation()) {
      return box_defn->value()->definition();
    } else {
      UnboxedIntConverterInstr* converter = new UnboxedIntConverterInstr(
          from_representation, representation(),
          box_defn->value()->CopyWithType(),
          (representation() == kUnboxedInt32) ? GetDeoptId()
                                              : Thread::kNoDeoptId);
      // TODO(vegorov): marking resulting converter as truncating when
      // unboxing can't deoptimize is a workaround for the missing
      // deoptimization environment when we insert converter after
      // EliminateEnvironments and there is a mismatch between predicates
      // UnboxIntConverterInstr::CanDeoptimize and UnboxInt32::CanDeoptimize.
      if ((representation() == kUnboxedInt32) &&
          (is_truncating() || !CanDeoptimize())) {
        converter->mark_truncating();
      }
      flow_graph->InsertBefore(this, converter, env(), FlowGraph::kValue);
      return converter;
    }
  }

  return this;
}


Definition* UnboxInt32Instr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = UnboxIntegerInstr::Canonicalize(flow_graph);
  if (replacement != this) {
    return replacement;
  }

  ConstantInstr* c = value()->definition()->AsConstant();
  if ((c != NULL) && c->value().IsSmi()) {
    if (!is_truncating() && (kSmiBits > 32)) {
      // Check that constant fits into 32-bit integer.
      const int64_t value = static_cast<int64_t>(Smi::Cast(c->value()).Value());
      if (!Utils::IsInt(32, value)) {
        return this;
      }
    }

    UnboxedConstantInstr* uc =
        new UnboxedConstantInstr(c->value(), kUnboxedInt32);
    if (c->range() != NULL) {
      uc->set_range(*c->range());
    }
    flow_graph->InsertBefore(this, uc, NULL, FlowGraph::kValue);
    return uc;
  }

  return this;
}


Definition* UnboxedIntConverterInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return NULL;

  UnboxedIntConverterInstr* box_defn =
      value()->definition()->AsUnboxedIntConverter();
  if ((box_defn != NULL) && (box_defn->representation() == from())) {
    if (box_defn->from() == to()) {
      return box_defn->value()->definition();
    }

    UnboxedIntConverterInstr* converter = new UnboxedIntConverterInstr(
        box_defn->from(), representation(), box_defn->value()->CopyWithType(),
        (to() == kUnboxedInt32) ? GetDeoptId() : Thread::kNoDeoptId);
    if ((representation() == kUnboxedInt32) && is_truncating()) {
      converter->mark_truncating();
    }
    flow_graph->InsertBefore(this, converter, env(), FlowGraph::kValue);
    return converter;
  }

  UnboxInt64Instr* unbox_defn = value()->definition()->AsUnboxInt64();
  if (unbox_defn != NULL && (from() == kUnboxedMint) &&
      (to() == kUnboxedInt32) && unbox_defn->HasOnlyInputUse(value())) {
    // TODO(vegorov): there is a duplication of code between UnboxedIntCoverter
    // and code path that unboxes Mint into Int32. We should just schedule
    // these instructions close to each other instead of fusing them.
    Definition* replacement =
        new UnboxInt32Instr(is_truncating() ? UnboxInt32Instr::kTruncate
                                            : UnboxInt32Instr::kNoTruncation,
                            unbox_defn->value()->CopyWithType(), GetDeoptId());
    flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
    return replacement;
  }

  return this;
}


Definition* BooleanNegateInstr::Canonicalize(FlowGraph* flow_graph) {
  Definition* defn = value()->definition();
  if (defn->IsComparison() && defn->HasOnlyUse(value()) &&
      defn->Type()->ToCid() == kBoolCid) {
    defn->AsComparison()->NegateComparison();
    return defn;
  }
  return this;
}


static bool MayBeBoxableNumber(intptr_t cid) {
  return (cid == kDynamicCid) || (cid == kMintCid) || (cid == kBigintCid) ||
         (cid == kDoubleCid);
}


static bool MaybeNumber(CompileType* type) {
  ASSERT(Type::Handle(Type::Number())
             .IsMoreSpecificThan(Type::Handle(Type::Number()), NULL, NULL,
                                 Heap::kOld));
  return type->ToAbstractType()->IsDynamicType() ||
         type->ToAbstractType()->IsObjectType() ||
         type->ToAbstractType()->IsTypeParameter() ||
         type->IsMoreSpecificThan(Type::Handle(Type::Number()));
}


// Returns a replacement for a strict comparison and signals if the result has
// to be negated.
static Definition* CanonicalizeStrictCompare(StrictCompareInstr* compare,
                                             bool* negated,
                                             bool is_branch) {
  // Use propagated cid and type information to eliminate number checks.
  // If one of the inputs is not a boxable number (Mint, Double, Bigint), or
  // is not a subtype of num, no need for number checks.
  if (compare->needs_number_check()) {
    if (!MayBeBoxableNumber(compare->left()->Type()->ToCid()) ||
        !MayBeBoxableNumber(compare->right()->Type()->ToCid())) {
      compare->set_needs_number_check(false);
    } else if (!MaybeNumber(compare->left()->Type()) ||
               !MaybeNumber(compare->right()->Type())) {
      compare->set_needs_number_check(false);
    }
  }
  *negated = false;
  PassiveObject& constant = PassiveObject::Handle();
  Value* other = NULL;
  if (compare->right()->BindsToConstant()) {
    constant = compare->right()->BoundConstant().raw();
    other = compare->left();
  } else if (compare->left()->BindsToConstant()) {
    constant = compare->left()->BoundConstant().raw();
    other = compare->right();
  } else {
    return compare;
  }

  const bool can_merge = is_branch || (other->Type()->ToCid() == kBoolCid);
  Definition* other_defn = other->definition();
  Token::Kind kind = compare->kind();
  // Handle e === true.
  if ((kind == Token::kEQ_STRICT) && (constant.raw() == Bool::True().raw()) &&
      can_merge) {
    return other_defn;
  }
  // Handle e !== false.
  if ((kind == Token::kNE_STRICT) && (constant.raw() == Bool::False().raw()) &&
      can_merge) {
    return other_defn;
  }
  // Handle e !== true.
  if ((kind == Token::kNE_STRICT) && (constant.raw() == Bool::True().raw()) &&
      other_defn->IsComparison() && can_merge &&
      other_defn->HasOnlyUse(other)) {
    *negated = true;
    return other_defn;
  }
  // Handle e === false.
  if ((kind == Token::kEQ_STRICT) && (constant.raw() == Bool::False().raw()) &&
      other_defn->IsComparison() && can_merge &&
      other_defn->HasOnlyUse(other)) {
    *negated = true;
    return other_defn;
  }
  return compare;
}


static bool BindsToGivenConstant(Value* v, intptr_t expected) {
  return v->BindsToConstant() && v->BoundConstant().IsSmi() &&
         (Smi::Cast(v->BoundConstant()).Value() == expected);
}


// Recognize patterns (a & b) == 0 and (a & 2^n) != 2^n.
static bool RecognizeTestPattern(Value* left, Value* right, bool* negate) {
  if (!right->BindsToConstant() || !right->BoundConstant().IsSmi()) {
    return false;
  }

  const intptr_t value = Smi::Cast(right->BoundConstant()).Value();
  if ((value != 0) && !Utils::IsPowerOfTwo(value)) {
    return false;
  }


  BinarySmiOpInstr* mask_op = left->definition()->AsBinarySmiOp();
  if ((mask_op == NULL) || (mask_op->op_kind() != Token::kBIT_AND) ||
      !mask_op->HasOnlyUse(left)) {
    return false;
  }

  if (value == 0) {
    // Recognized (a & b) == 0 pattern.
    *negate = false;
    return true;
  }

  // Recognize
  if (BindsToGivenConstant(mask_op->left(), value) ||
      BindsToGivenConstant(mask_op->right(), value)) {
    // Recognized (a & 2^n) == 2^n pattern. It's equivalent to (a & 2^n) != 0
    // so we need to negate original comparison.
    *negate = true;
    return true;
  }

  return false;
}


Instruction* BranchInstr::Canonicalize(FlowGraph* flow_graph) {
  Zone* zone = flow_graph->zone();
  // Only handle strict-compares.
  if (comparison()->IsStrictCompare()) {
    bool negated = false;
    Definition* replacement = CanonicalizeStrictCompare(
        comparison()->AsStrictCompare(), &negated, /* is_branch = */ true);
    if (replacement == comparison()) {
      return this;
    }
    ComparisonInstr* comp = replacement->AsComparison();
    if ((comp == NULL) || comp->CanDeoptimize() ||
        comp->HasUnmatchedInputRepresentations()) {
      return this;
    }

    // Replace the comparison if the replacement is used at this branch,
    // and has exactly one use.
    Value* use = comp->input_use_list();
    if ((use->instruction() == this) && comp->HasOnlyUse(use)) {
      if (negated) {
        comp->NegateComparison();
      }
      RemoveEnvironment();
      flow_graph->CopyDeoptTarget(this, comp);
      // Unlink environment from the comparison since it is copied to the
      // branch instruction.
      comp->RemoveEnvironment();

      comp->RemoveFromGraph();
      SetComparison(comp);
      if (FLAG_trace_optimization) {
        OS::Print("Merging comparison v%" Pd "\n", comp->ssa_temp_index());
      }
      // Clear the comparison's temp index and ssa temp index since the
      // value of the comparison is not used outside the branch anymore.
      ASSERT(comp->input_use_list() == NULL);
      comp->ClearSSATempIndex();
      comp->ClearTempIndex();
    }
  } else if (comparison()->IsEqualityCompare() &&
             comparison()->operation_cid() == kSmiCid) {
    BinarySmiOpInstr* bit_and = NULL;
    bool negate = false;
    if (RecognizeTestPattern(comparison()->left(), comparison()->right(),
                             &negate)) {
      bit_and = comparison()->left()->definition()->AsBinarySmiOp();
    } else if (RecognizeTestPattern(comparison()->right(), comparison()->left(),
                                    &negate)) {
      bit_and = comparison()->right()->definition()->AsBinarySmiOp();
    }
    if (bit_and != NULL) {
      if (FLAG_trace_optimization) {
        OS::Print("Merging test smi v%" Pd "\n", bit_and->ssa_temp_index());
      }
      TestSmiInstr* test = new TestSmiInstr(
          comparison()->token_pos(),
          negate ? Token::NegateComparison(comparison()->kind())
                 : comparison()->kind(),
          bit_and->left()->Copy(zone), bit_and->right()->Copy(zone));
      ASSERT(!CanDeoptimize());
      RemoveEnvironment();
      flow_graph->CopyDeoptTarget(this, bit_and);
      SetComparison(test);
      bit_and->RemoveFromGraph();
    }
  }
  return this;
}


Definition* StrictCompareInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return NULL;
  bool negated = false;
  Definition* replacement = CanonicalizeStrictCompare(this, &negated,
                                                      /* is_branch = */ false);
  if (negated && replacement->IsComparison()) {
    ASSERT(replacement != this);
    replacement->AsComparison()->NegateComparison();
  }
  return replacement;
}


Instruction* CheckClassInstr::Canonicalize(FlowGraph* flow_graph) {
  const intptr_t value_cid = value()->Type()->ToCid();
  if (value_cid == kDynamicCid) {
    return this;
  }

  return unary_checks().HasReceiverClassId(value_cid) ? NULL : this;
}


Instruction* CheckClassIdInstr::Canonicalize(FlowGraph* flow_graph) {
  if (value()->BindsToConstant()) {
    const Object& constant_value = value()->BoundConstant();
    if (constant_value.IsSmi() && Smi::Cast(constant_value).Value() == cid_) {
      return NULL;
    }
  }
  return this;
}


Definition* TestCidsInstr::Canonicalize(FlowGraph* flow_graph) {
  CompileType* in_type = left()->Type();
  intptr_t cid = in_type->ToCid();
  if (cid == kDynamicCid) return this;

  const ZoneGrowableArray<intptr_t>& data = cid_results();
  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  for (intptr_t i = 0; i < data.length(); i += 2) {
    if (data[i] == cid) {
      return (data[i + 1] == true_result)
                 ? flow_graph->GetConstant(Bool::True())
                 : flow_graph->GetConstant(Bool::False());
    }
  }

  // TODO(sra): Handle misses if the instruction is not deoptimizing.
  // TODO(sra): Handle nullable input, possibly canonicalizing to a compare
  // against `null`.
  return this;
}


Instruction* GuardFieldClassInstr::Canonicalize(FlowGraph* flow_graph) {
  if (field().guarded_cid() == kDynamicCid) {
    return NULL;  // Nothing to guard.
  }

  if (field().is_nullable() && value()->Type()->IsNull()) {
    return NULL;
  }

  const intptr_t cid = field().is_nullable() ? value()->Type()->ToNullableCid()
                                             : value()->Type()->ToCid();
  if (field().guarded_cid() == cid) {
    return NULL;  // Value is guaranteed to have this cid.
  }

  return this;
}


Instruction* GuardFieldLengthInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!field().needs_length_check()) {
    return NULL;  // Nothing to guard.
  }

  const intptr_t expected_length = field().guarded_list_length();
  if (expected_length == Field::kUnknownFixedLength) {
    return this;
  }

  // Check if length is statically known.
  StaticCallInstr* call = value()->definition()->AsStaticCall();
  if (call == NULL) {
    return this;
  }

  ConstantInstr* length = NULL;
  if (call->is_known_list_constructor() &&
      LoadFieldInstr::IsFixedLengthArrayCid(call->Type()->ToCid())) {
    length = call->ArgumentAt(1)->AsConstant();
  }
  if ((length != NULL) && length->value().IsSmi() &&
      Smi::Cast(length->value()).Value() == expected_length) {
    return NULL;  // Expected length matched.
  }

  return this;
}


Instruction* CheckSmiInstr::Canonicalize(FlowGraph* flow_graph) {
  return (value()->Type()->ToCid() == kSmiCid) ? NULL : this;
}


Instruction* CheckEitherNonSmiInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((left()->Type()->ToCid() == kDoubleCid) ||
      (right()->Type()->ToCid() == kDoubleCid)) {
    return NULL;  // Remove from the graph.
  }
  return this;
}


BoxInstr* BoxInstr::Create(Representation from, Value* value) {
  switch (from) {
    case kUnboxedInt32:
      return new BoxInt32Instr(value);

    case kUnboxedUint32:
      return new BoxUint32Instr(value);

    case kUnboxedMint:
      return new BoxInt64Instr(value);

    case kUnboxedDouble:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return new BoxInstr(from, value);

    default:
      UNREACHABLE();
      return NULL;
  }
}


UnboxInstr* UnboxInstr::Create(Representation to,
                               Value* value,
                               intptr_t deopt_id) {
  switch (to) {
    case kUnboxedInt32:
      return new UnboxInt32Instr(UnboxInt32Instr::kNoTruncation, value,
                                 deopt_id);

    case kUnboxedUint32:
      return new UnboxUint32Instr(value, deopt_id);

    case kUnboxedMint:
      return new UnboxInt64Instr(value, deopt_id);

    case kUnboxedDouble:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return new UnboxInstr(to, value, deopt_id);

    default:
      UNREACHABLE();
      return NULL;
  }
}


bool UnboxInstr::CanConvertSmi() const {
  switch (representation()) {
    case kUnboxedDouble:
    case kUnboxedMint:
      return true;

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return false;

    default:
      UNREACHABLE();
      return false;
  }
}


// Shared code generation methods (EmitNativeCode and
// MakeLocationSummary). Only assembly code that can be shared across all
// architectures can be used. Machine specific register allocation and code
// generation is located in intermediate_language_<arch>.cc

#define __ compiler->assembler()->

LocationSummary* GraphEntryInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


LocationSummary* JoinEntryInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void JoinEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, GetDeoptId(),
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* TargetEntryInstr::MakeLocationSummary(Zone* zone,
                                                       bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
#if !defined(TARGET_ARCH_DBC)
    // TODO(vegorov) re-enable edge counters on DBC if we consider them
    // beneficial for the quality of the optimized bytecode.
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter(preorder_number());
    }
#endif

    // The deoptimization descriptor points after the edge counter code for
    // uniformity with ARM and MIPS, where we can reuse pattern matching
    // code that matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, GetDeoptId(),
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


void IndirectGotoInstr::ComputeOffsetTable() {
  if (GetBlock()->offset() < 0) {
    // Don't generate a table when contained in an unreachable block.
    return;
  }
  ASSERT(SuccessorCount() == offsets_.Length());
  intptr_t element_size = offsets_.ElementSizeInBytes();
  for (intptr_t i = 0; i < SuccessorCount(); i++) {
    TargetEntryInstr* target = SuccessorAt(i);
    intptr_t offset = target->offset();

    // The intermediate block might be compacted, if so, use the indirect entry.
    if (offset < 0) {
      // Optimizations might have modified the immediate target block, but it
      // must end with a goto to the indirect entry. Also, we can't use
      // last_instruction because 'target' is compacted/unreachable.
      Instruction* last = target->next();
      while (last != NULL && !last->IsGoto()) {
        last = last->next();
      }
      ASSERT(last);
      IndirectEntryInstr* ientry =
          last->AsGoto()->successor()->AsIndirectEntry();
      ASSERT(ientry != NULL);
      ASSERT(ientry->indirect_id() == i);
      offset = ientry->offset();
    }

    ASSERT(offset > 0);
    offsets_.SetInt32(i * element_size, offset);
  }
}


LocationSummary* IndirectEntryInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  return JoinEntryInstr::MakeLocationSummary(zone, optimizing);
}


void IndirectEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  JoinEntryInstr::EmitNativeCode(compiler);
}


LocationSummary* PhiInstr::MakeLocationSummary(Zone* zone,
                                               bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void PhiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* RedefinitionInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void RedefinitionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ParameterInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void ParameterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


bool ParallelMoveInstr::IsRedundant() const {
  for (intptr_t i = 0; i < moves_.length(); i++) {
    if (!moves_[i]->IsRedundant()) {
      return false;
    }
  }
  return true;
}


LocationSummary* ParallelMoveInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  return NULL;
}


void ParallelMoveInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ConstraintInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void ConstraintInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* MaterializeObjectInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  UNREACHABLE();
  return NULL;
}


void MaterializeObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


// This function should be kept in sync with
// FlowGraphCompiler::SlowPathEnvironmentFor().
void MaterializeObjectInstr::RemapRegisters(intptr_t* cpu_reg_slots,
                                            intptr_t* fpu_reg_slots) {
  if (registers_remapped_) {
    return;
  }
  registers_remapped_ = true;

  for (intptr_t i = 0; i < InputCount(); i++) {
    locations_[i] = LocationAt(i).RemapForSlowPath(
        InputAt(i)->definition(), cpu_reg_slots, fpu_reg_slots);
  }
}


LocationSummary* CurrentContextInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  // Only appears in initial definitions, never in normal code.
  UNREACHABLE();
  return NULL;
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Only appears in initial definitions, never in normal code.
  UNREACHABLE();
}


LocationSummary* DropTempsInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  return (InputCount() == 1)
             ? LocationSummary::Make(zone, 1, Location::SameAsFirstInput(),
                                     LocationSummary::kNoCall)
             : LocationSummary::Make(zone, 0, Location::NoLocation(),
                                     LocationSummary::kNoCall);
}


void DropTempsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if defined(TARGET_ARCH_DBC)
  // On DBC the action of poping the TOS value and then pushing it
  // after all intermediates are poped is folded into a special
  // bytecode (DropR). On other architectures this is handled by
  // instruction prologue/epilogues.
  ASSERT(!compiler->is_optimizing());
  if ((InputCount() != 0) && HasTemp()) {
    __ DropR(num_temps());
  } else {
    __ Drop(num_temps() + ((InputCount() != 0) ? 1 : 0));
  }
#else
  ASSERT(!compiler->is_optimizing());
  // Assert that register assignment is correct.
  ASSERT((InputCount() == 0) || (locs()->out(0).reg() == locs()->in(0).reg()));
  __ Drop(num_temps());
#endif  // defined(TARGET_ARCH_DBC)
}


StrictCompareInstr::StrictCompareInstr(TokenPosition token_pos,
                                       Token::Kind kind,
                                       Value* left,
                                       Value* right,
                                       bool needs_number_check)
    : TemplateComparison(token_pos, kind, Thread::Current()->GetNextDeoptId()),
      needs_number_check_(needs_number_check) {
  ASSERT((kind == Token::kEQ_STRICT) || (kind == Token::kNE_STRICT));
  SetInputAt(0, left);
  SetInputAt(1, right);
}


LocationSummary* InstanceCallInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  return MakeCallSummary(zone);
}


// DBC does not use specialized inline cache stubs for smi operations.
#if !defined(TARGET_ARCH_DBC)
static const StubEntry* TwoArgsSmiOpInlineCacheEntry(Token::Kind kind) {
  if (!FLAG_two_args_smi_icd) {
    return 0;
  }
  switch (kind) {
    case Token::kADD:
      return StubCode::SmiAddInlineCache_entry();
    case Token::kSUB:
      return StubCode::SmiSubInlineCache_entry();
    case Token::kEQ:
      return StubCode::SmiEqualInlineCache_entry();
    default:
      return NULL;
  }
}
#else
static void TryFastPathSmiOp(FlowGraphCompiler* compiler,
                             ICData* call_ic_data,
                             const String& name) {
  if (!FLAG_two_args_smi_icd) {
    return;
  }
  if (name.raw() == Symbols::Plus().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ AddTOS();
    }
  } else if (name.raw() == Symbols::Minus().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ SubTOS();
    }
  } else if (name.raw() == Symbols::EqualOperator().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ EqualTOS();
    }
  } else if (name.raw() == Symbols::LAngleBracket().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ LessThanTOS();
    }
  } else if (name.raw() == Symbols::RAngleBracket().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ GreaterThanTOS();
    }
  } else if (name.raw() == Symbols::BitAnd().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ BitAndTOS();
    }
  } else if (name.raw() == Symbols::BitOr().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ BitOrTOS();
    }
  } else if (name.raw() == Symbols::Star().raw()) {
    if (call_ic_data->AddSmiSmiCheckForFastSmiStubs()) {
      __ MulTOS();
    }
  }
}
#endif


void InstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Zone* zone = compiler->zone();
  const ICData* call_ic_data = NULL;
  if (!FLAG_propagate_ic_data || !compiler->is_optimizing() ||
      (ic_data() == NULL)) {
    const Array& arguments_descriptor = Array::Handle(
        zone, ArgumentsDescriptor::New(ArgumentCount(), argument_names()));
    call_ic_data = compiler->GetOrAddInstanceCallICData(
        deopt_id(), function_name(), arguments_descriptor,
        checked_argument_count());
  } else {
    call_ic_data = &ICData::ZoneHandle(zone, ic_data()->raw());
  }

#if !defined(TARGET_ARCH_DBC)
  if (compiler->is_optimizing() && HasICData()) {
    ASSERT(HasICData());
    if (ic_data()->NumberOfUsedChecks() > 0) {
      const ICData& unary_ic_data =
          ICData::ZoneHandle(zone, ic_data()->AsUnaryClassChecks());
      compiler->GenerateInstanceCall(deopt_id(), token_pos(), ArgumentCount(),
                                     locs(), unary_ic_data);
    } else {
      // Call was not visited yet, use original ICData in order to populate it.
      compiler->GenerateInstanceCall(deopt_id(), token_pos(), ArgumentCount(),
                                     locs(), *call_ic_data);
    }
  } else {
    // Unoptimized code.
    ASSERT(!HasICData());
    bool is_smi_two_args_op = false;
    const StubEntry* stub_entry = TwoArgsSmiOpInlineCacheEntry(token_kind());
    if (stub_entry != NULL) {
      // We have a dedicated inline cache stub for this operation, add an
      // an initial Smi/Smi check with count 0.
      is_smi_two_args_op = call_ic_data->AddSmiSmiCheckForFastSmiStubs();
    }
    if (is_smi_two_args_op) {
      ASSERT(ArgumentCount() == 2);
      compiler->EmitInstanceCall(*stub_entry, *call_ic_data, ArgumentCount(),
                                 deopt_id(), token_pos(), locs());
    } else {
      compiler->GenerateInstanceCall(deopt_id(), token_pos(), ArgumentCount(),
                                     locs(), *call_ic_data);
    }
  }
#else
  ICData* original_ic_data = &ICData::ZoneHandle(call_ic_data->Original());

  // Emit smi fast path instruction. If fast-path succeeds it skips the next
  // instruction otherwise it falls through. Only attempt in unoptimized code
  // because TryFastPathSmiOp will update original_ic_data.
  if (!compiler->is_optimizing()) {
    TryFastPathSmiOp(compiler, original_ic_data, function_name());
  }

  const intptr_t call_ic_data_kidx = __ AddConstant(*original_ic_data);
  switch (original_ic_data->NumArgsTested()) {
    case 1:
      if (compiler->is_optimizing()) {
        __ InstanceCall1Opt(ArgumentCount(), call_ic_data_kidx);
      } else {
        __ InstanceCall1(ArgumentCount(), call_ic_data_kidx);
      }
      break;
    case 2:
      if (compiler->is_optimizing()) {
        __ InstanceCall2Opt(ArgumentCount(), call_ic_data_kidx);
      } else {
        __ InstanceCall2(ArgumentCount(), call_ic_data_kidx);
      }
      break;
    default:
      UNIMPLEMENTED();
      break;
  }
  compiler->AddCurrentDescriptor(RawPcDescriptors::kIcCall, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this);

  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
#endif  // !defined(TARGET_ARCH_DBC)
}


bool PolymorphicInstanceCallInstr::HasSingleRecognizedTarget() const {
  if (FLAG_precompiled_mode && with_checks()) return false;

  return ic_data().HasOneTarget() &&
         (MethodRecognizer::RecognizeKind(Function::Handle(
              ic_data().GetTargetAt(0))) != MethodRecognizer::kUnknown);
}


// DBC does not support optimizing compiler and thus doesn't emit
// PolymorphicInstanceCallInstr.
#if !defined(TARGET_ARCH_DBC)
void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(ic_data().NumArgsTested() == 1);
  if (!with_checks()) {
    ASSERT(ic_data().HasOneTarget());
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(deopt_id(), instance_call()->token_pos(),
                                 target, instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(), locs(),
                                 ICData::Handle());
    return;
  }

  compiler->EmitPolymorphicInstanceCall(
      ic_data(), instance_call()->ArgumentCount(),
      instance_call()->argument_names(), deopt_id(),
      instance_call()->token_pos(), locs(), complete());
}
#endif


RawType* PolymorphicInstanceCallInstr::ComputeRuntimeType(
    const ICData& ic_data) {
  bool is_string = true;
  bool is_integer = true;
  bool is_double = true;

  const intptr_t num_checks = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < num_checks; i++) {
    const intptr_t cid = ic_data.GetReceiverClassIdAt(i);
    is_string = is_string && RawObject::IsStringClassId(cid);
    is_integer = is_integer && RawObject::IsIntegerClassId(cid);
    is_double = is_double && (cid == kDoubleCid);
  }

  if (is_string) {
    return Type::StringType();
  } else if (is_integer) {
    return Type::IntType();
  } else if (is_double) {
    return Type::Double();
  }

  return Type::null();
}


Definition* PolymorphicInstanceCallInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasSingleRecognizedTarget() || with_checks()) {
    return this;
  }

  const Function& target = Function::Handle(ic_data().GetTargetAt(0));
  if (target.recognized_kind() == MethodRecognizer::kObjectRuntimeType) {
    const AbstractType& type =
        AbstractType::Handle(ComputeRuntimeType(ic_data()));
    if (!type.IsNull()) {
      return flow_graph->GetConstant(type);
    }
  }

  return this;
}


Definition* StaticCallInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!FLAG_precompiled_mode) {
    return this;
  }

  if (function().recognized_kind() == MethodRecognizer::kObjectRuntimeType) {
    if (input_use_list() == NULL) {
      // This function has only environment uses. In precompiled mode it is
      // fine to remove it - because we will never deoptimize.
      return flow_graph->constant_dead();
    }
  }

  return this;
}


LocationSummary* StaticCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  return MakeCallSummary(zone);
}


void StaticCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData* call_ic_data = NULL;
  if (!FLAG_propagate_ic_data || !compiler->is_optimizing() ||
      (ic_data() == NULL)) {
    const Array& arguments_descriptor = Array::Handle(
        ArgumentsDescriptor::New(ArgumentCount(), argument_names()));
    MethodRecognizer::Kind recognized_kind =
        MethodRecognizer::RecognizeKind(function());
    int num_args_checked = 0;
    switch (recognized_kind) {
      case MethodRecognizer::kDoubleFromInteger:
      case MethodRecognizer::kMathMin:
      case MethodRecognizer::kMathMax:
        num_args_checked = 2;
        break;
      default:
        break;
    }
    call_ic_data = compiler->GetOrAddStaticCallICData(
        deopt_id(), function(), arguments_descriptor, num_args_checked);
  } else {
    call_ic_data = &ICData::ZoneHandle(ic_data()->raw());
  }

#if !defined(TARGET_ARCH_DBC)
  compiler->GenerateStaticCall(deopt_id(), token_pos(), function(),
                               ArgumentCount(), argument_names(), locs(),
                               *call_ic_data);
#else
  const Array& arguments_descriptor =
      (ic_data() == NULL) ? Array::Handle(ArgumentsDescriptor::New(
                                ArgumentCount(), argument_names()))
                          : Array::Handle(ic_data()->arguments_descriptor());
  const intptr_t argdesc_kidx = __ AddConstant(arguments_descriptor);

  if (compiler->is_optimizing()) {
    __ PushConstant(function());
    __ StaticCall(ArgumentCount(), argdesc_kidx);
    compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                   token_pos());
    compiler->RecordAfterCall(this);
    __ PopLocal(locs()->out(0).reg());
  } else {
    const intptr_t ic_data_kidx = __ AddConstant(*call_ic_data);
    __ PushConstant(ic_data_kidx);
    __ IndirectStaticCall(ArgumentCount(), argdesc_kidx);
    compiler->AddCurrentDescriptor(RawPcDescriptors::kUnoptStaticCall,
                                   deopt_id(), token_pos());
    compiler->RecordAfterCall(this);
  }
#endif  // !defined(TARGET_ARCH_DBC)
}


void AssertAssignableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateAssertAssignable(token_pos(), deopt_id(), dst_type(),
                                     dst_name(), locs());

// DBC does not use LocationSummaries in the same way as other architectures.
#if !defined(TARGET_ARCH_DBC)
  ASSERT(locs()->in(0).reg() == locs()->out(0).reg());
#endif  // !defined(TARGET_ARCH_DBC)
}


LocationSummary* DeoptimizeInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void DeoptimizeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if !defined(TARGET_ARCH_DBC)
  __ Jump(compiler->AddDeoptStub(deopt_id(), deopt_reason_));
#else
  compiler->EmitDeopt(deopt_id(), deopt_reason_);
#endif
}


Environment* Environment::From(Zone* zone,
                               const GrowableArray<Definition*>& definitions,
                               intptr_t fixed_parameter_count,
                               const ParsedFunction& parsed_function) {
  Environment* env =
      new (zone) Environment(definitions.length(), fixed_parameter_count,
                             Thread::kNoDeoptId, parsed_function, NULL);
  for (intptr_t i = 0; i < definitions.length(); ++i) {
    env->values_.Add(new (zone) Value(definitions[i]));
  }
  return env;
}


Environment* Environment::DeepCopy(Zone* zone, intptr_t length) const {
  ASSERT(length <= values_.length());
  Environment* copy = new (zone)
      Environment(length, fixed_parameter_count_, deopt_id_, parsed_function_,
                  (outer_ == NULL) ? NULL : outer_->DeepCopy(zone));
  if (locations_ != NULL) {
    Location* new_locations = zone->Alloc<Location>(length);
    copy->set_locations(new_locations);
  }
  for (intptr_t i = 0; i < length; ++i) {
    copy->values_.Add(values_[i]->Copy(zone));
    if (locations_ != NULL) {
      copy->locations_[i] = locations_[i].Copy();
    }
  }
  return copy;
}


// Copies the environment and updates the environment use lists.
void Environment::DeepCopyTo(Zone* zone, Instruction* instr) const {
  for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }

  Environment* copy = DeepCopy(zone);
  instr->SetEnvironment(copy);
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->definition()->AddEnvUse(value);
  }
}


void Environment::DeepCopyAfterTo(Zone* zone,
                                  Instruction* instr,
                                  intptr_t argc,
                                  Definition* dead,
                                  Definition* result) const {
  for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }

  Environment* copy = DeepCopy(zone, values_.length() - argc);
  for (intptr_t i = 0; i < argc; i++) {
    copy->values_.Add(new (zone) Value(dead));
  }
  copy->values_.Add(new (zone) Value(result));

  instr->SetEnvironment(copy);
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->definition()->AddEnvUse(value);
  }
}


// Copies the environment as outer on an inlined instruction and updates the
// environment use lists.
void Environment::DeepCopyToOuter(Zone* zone, Instruction* instr) const {
  // Create a deep copy removing caller arguments from the environment.
  ASSERT(this != NULL);
  ASSERT(instr->env()->outer() == NULL);
  intptr_t argument_count = instr->env()->fixed_parameter_count();
  Environment* copy = DeepCopy(zone, values_.length() - argument_count);
  instr->env()->outer_ = copy;
  intptr_t use_index = instr->env()->Length();  // Start index after inner.
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->set_instruction(instr);
    value->set_use_index(use_index++);
    value->definition()->AddEnvUse(value);
  }
}


ComparisonInstr* DoubleTestOpInstr::CopyWithNewOperands(Value* new_left,
                                                        Value* new_right) {
  UNREACHABLE();
  return NULL;
}


ComparisonInstr* EqualityCompareInstr::CopyWithNewOperands(Value* new_left,
                                                           Value* new_right) {
  return new EqualityCompareInstr(token_pos(), kind(), new_left, new_right,
                                  operation_cid(), deopt_id());
}


ComparisonInstr* RelationalOpInstr::CopyWithNewOperands(Value* new_left,
                                                        Value* new_right) {
  return new RelationalOpInstr(token_pos(), kind(), new_left, new_right,
                               operation_cid(), deopt_id());
}


ComparisonInstr* StrictCompareInstr::CopyWithNewOperands(Value* new_left,
                                                         Value* new_right) {
  return new StrictCompareInstr(token_pos(), kind(), new_left, new_right,
                                needs_number_check());
}


ComparisonInstr* TestSmiInstr::CopyWithNewOperands(Value* new_left,
                                                   Value* new_right) {
  return new TestSmiInstr(token_pos(), kind(), new_left, new_right);
}


ComparisonInstr* TestCidsInstr::CopyWithNewOperands(Value* new_left,
                                                    Value* new_right) {
  return new TestCidsInstr(token_pos(), kind(), new_left, cid_results(),
                           deopt_id());
}


bool TestCidsInstr::AttributesEqual(Instruction* other) const {
  TestCidsInstr* other_instr = other->AsTestCids();
  if (!ComparisonInstr::AttributesEqual(other)) {
    return false;
  }
  if (cid_results().length() != other_instr->cid_results().length()) {
    return false;
  }
  for (intptr_t i = 0; i < cid_results().length(); i++) {
    if (cid_results()[i] != other_instr->cid_results()[i]) {
      return false;
    }
  }
  return true;
}


#if !defined(TARGET_ARCH_DBC)
static bool BindsToSmiConstant(Value* value) {
  return value->BindsToConstant() && value->BoundConstant().IsSmi();
}
#endif


bool IfThenElseInstr::Supports(ComparisonInstr* comparison,
                               Value* v1,
                               Value* v2) {
#if !defined(TARGET_ARCH_DBC)
  bool is_smi_result = BindsToSmiConstant(v1) && BindsToSmiConstant(v2);
  if (comparison->IsStrictCompare()) {
    // Strict comparison with number checks calls a stub and is not supported
    // by if-conversion.
    return is_smi_result &&
           !comparison->AsStrictCompare()->needs_number_check();
  }
  if (comparison->operation_cid() != kSmiCid) {
    // Non-smi comparisons are not supported by if-conversion.
    return false;
  }
  return is_smi_result;
#else
  return false;
#endif  // !defined(TARGET_ARCH_DBC)
}


bool PhiInstr::IsRedundant() const {
  ASSERT(InputCount() > 1);
  Definition* first = InputAt(0)->definition();
  for (intptr_t i = 1; i < InputCount(); ++i) {
    Definition* def = InputAt(i)->definition();
    if (def != first) return false;
  }
  return true;
}


bool CheckArrayBoundInstr::IsFixedLengthArrayType(intptr_t cid) {
  return LoadFieldInstr::IsFixedLengthArrayCid(cid);
}


Instruction* CheckArrayBoundInstr::Canonicalize(FlowGraph* flow_graph) {
  return IsRedundant(RangeBoundary::FromDefinition(length()->definition()))
             ? NULL
             : this;
}


intptr_t CheckArrayBoundInstr::LengthOffsetFor(intptr_t class_id) {
  if (RawObject::IsExternalTypedDataClassId(class_id)) {
    return ExternalTypedData::length_offset();
  }
  if (RawObject::IsTypedDataClassId(class_id)) {
    return TypedData::length_offset();
  }
  switch (class_id) {
    case kGrowableObjectArrayCid:
      return GrowableObjectArray::length_offset();
    case kOneByteStringCid:
    case kTwoByteStringCid:
      return String::length_offset();
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::length_offset();
    default:
      UNREACHABLE();
      return -1;
  }
}


const Function& StringInterpolateInstr::CallFunction() const {
  if (function_.IsNull()) {
    const int kNumberOfArguments = 1;
    const Array& kNoArgumentNames = Object::null_array();
    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    function_ = Resolver::ResolveStatic(
        cls, Library::PrivateCoreLibName(Symbols::Interpolate()),
        kNumberOfArguments, kNoArgumentNames);
  }
  ASSERT(!function_.IsNull());
  return function_;
}


// Replace StringInterpolateInstr with a constant string if all inputs are
// constant of [string, number, boolean, null].
// Leave the CreateArrayInstr and StoreIndexedInstr in the stream in case
// deoptimization occurs.
Definition* StringInterpolateInstr::Canonicalize(FlowGraph* flow_graph) {
  // The following graph structure is generated by the graph builder:
  //   v2 <- CreateArray(v0)
  //   StoreIndexed(v2, v3, v4)   -- v3:constant index, v4: value.
  //   ..
  //   v8 <- StringInterpolate(v2)

  // Don't compile-time fold when optimizing the interpolation function itself.
  if (flow_graph->function().raw() == CallFunction().raw()) {
    return this;
  }

  CreateArrayInstr* create_array = value()->definition()->AsCreateArray();
  ASSERT(create_array != NULL);
  // Check if the string interpolation has only constant inputs.
  Value* num_elements = create_array->num_elements();
  if (!num_elements->BindsToConstant() ||
      !num_elements->BoundConstant().IsSmi()) {
    return this;
  }
  const intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, length);
  for (intptr_t i = 0; i < length; i++) {
    pieces.Add(Object::null_string());
  }

  for (Value::Iterator it(create_array->input_use_list()); !it.Done();
       it.Advance()) {
    Instruction* curr = it.Current()->instruction();
    if (curr == this) continue;

    StoreIndexedInstr* store = curr->AsStoreIndexed();
    if (!store->index()->BindsToConstant() ||
        !store->index()->BoundConstant().IsSmi()) {
      return this;
    }
    intptr_t store_index = Smi::Cast(store->index()->BoundConstant()).Value();
    ASSERT(store_index < length);
    ASSERT(store != NULL);
    if (store->value()->definition()->IsConstant()) {
      ASSERT(store->index()->BindsToConstant());
      const Object& obj = store->value()->definition()->AsConstant()->value();
      // TODO(srdjan): Verify if any other types should be converted as well.
      if (obj.IsString()) {
        pieces.SetAt(store_index, String::Cast(obj));
      } else if (obj.IsSmi()) {
        const char* cstr = obj.ToCString();
        pieces.SetAt(store_index,
                     String::Handle(zone, String::New(cstr, Heap::kOld)));
      } else if (obj.IsBool()) {
        pieces.SetAt(store_index, Bool::Cast(obj).value() ? Symbols::True()
                                                          : Symbols::False());
      } else if (obj.IsNull()) {
        pieces.SetAt(store_index, Symbols::Null());
      } else {
        return this;
      }
    } else {
      return this;
    }
  }

  const String& concatenated =
      String::ZoneHandle(zone, Symbols::FromConcatAll(thread, pieces));
  return flow_graph->GetConstant(concatenated);
}


static AlignmentType StrengthenAlignment(intptr_t cid,
                                         AlignmentType alignment) {
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      // Don't need to worry about alignment for accessing bytes.
      return kAlignedAccess;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      // TODO(rmacnak): Investigate alignment requirements of floating point
      // loads.
      return kAlignedAccess;
  }

  return alignment;
}


LoadIndexedInstr::LoadIndexedInstr(Value* array,
                                   Value* index,
                                   intptr_t index_scale,
                                   intptr_t class_id,
                                   AlignmentType alignment,
                                   intptr_t deopt_id,
                                   TokenPosition token_pos)
    : TemplateDefinition(deopt_id),
      index_scale_(index_scale),
      class_id_(class_id),
      alignment_(StrengthenAlignment(class_id, alignment)),
      token_pos_(token_pos) {
  SetInputAt(0, array);
  SetInputAt(1, index);
}


StoreIndexedInstr::StoreIndexedInstr(Value* array,
                                     Value* index,
                                     Value* value,
                                     StoreBarrierType emit_store_barrier,
                                     intptr_t index_scale,
                                     intptr_t class_id,
                                     AlignmentType alignment,
                                     intptr_t deopt_id,
                                     TokenPosition token_pos)
    : TemplateDefinition(deopt_id),
      emit_store_barrier_(emit_store_barrier),
      index_scale_(index_scale),
      class_id_(class_id),
      alignment_(StrengthenAlignment(class_id, alignment)),
      token_pos_(token_pos) {
  SetInputAt(kArrayPos, array);
  SetInputAt(kIndexPos, index);
  SetInputAt(kValuePos, value);
}


InvokeMathCFunctionInstr::InvokeMathCFunctionInstr(
    ZoneGrowableArray<Value*>* inputs,
    intptr_t deopt_id,
    MethodRecognizer::Kind recognized_kind,
    TokenPosition token_pos)
    : PureDefinition(deopt_id),
      inputs_(inputs),
      recognized_kind_(recognized_kind),
      token_pos_(token_pos) {
  ASSERT(inputs_->length() == ArgumentCountFor(recognized_kind_));
  for (intptr_t i = 0; i < inputs_->length(); ++i) {
    ASSERT((*inputs)[i] != NULL);
    (*inputs)[i]->set_instruction(this);
    (*inputs)[i]->set_use_index(i);
  }
}


intptr_t InvokeMathCFunctionInstr::ArgumentCountFor(
    MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kDoubleTruncate:
    case MethodRecognizer::kDoubleFloor:
    case MethodRecognizer::kDoubleCeil: {
      ASSERT(!TargetCPUFeatures::double_truncate_round_supported());
      return 1;
    }
    case MethodRecognizer::kDoubleRound:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
      return 1;
    case MethodRecognizer::kDoubleMod:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathAtan2:
      return 2;
    default:
      UNREACHABLE();
  }
  return 0;
}

// Use expected function signatures to help MSVC compiler resolve overloading.
typedef double (*UnaryMathCFunction)(double x);
typedef double (*BinaryMathCFunction)(double x, double y);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcPow,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<BinaryMathCFunction>(&pow)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    DartModulo,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&DartModulo)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan2,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&atan2_ieee)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcFloor,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&floor)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCeil,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&ceil)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTrunc,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&trunc)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcRound,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&round)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&cos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcSin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&sin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAsin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&asin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAcos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&acos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&tan)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&atan)));


const RuntimeEntry& InvokeMathCFunctionInstr::TargetFunction() const {
  switch (recognized_kind_) {
    case MethodRecognizer::kDoubleTruncate:
      return kLibcTruncRuntimeEntry;
    case MethodRecognizer::kDoubleRound:
      return kLibcRoundRuntimeEntry;
    case MethodRecognizer::kDoubleFloor:
      return kLibcFloorRuntimeEntry;
    case MethodRecognizer::kDoubleCeil:
      return kLibcCeilRuntimeEntry;
    case MethodRecognizer::kMathDoublePow:
      return kLibcPowRuntimeEntry;
    case MethodRecognizer::kDoubleMod:
      return kDartModuloRuntimeEntry;
    case MethodRecognizer::kMathTan:
      return kLibcTanRuntimeEntry;
    case MethodRecognizer::kMathAsin:
      return kLibcAsinRuntimeEntry;
    case MethodRecognizer::kMathSin:
      return kLibcSinRuntimeEntry;
    case MethodRecognizer::kMathCos:
      return kLibcCosRuntimeEntry;
    case MethodRecognizer::kMathAcos:
      return kLibcAcosRuntimeEntry;
    case MethodRecognizer::kMathAtan:
      return kLibcAtanRuntimeEntry;
    case MethodRecognizer::kMathAtan2:
      return kLibcAtan2RuntimeEntry;
    default:
      UNREACHABLE();
  }
  return kLibcPowRuntimeEntry;
}


const char* MathUnaryInstr::KindToCString(MathUnaryKind kind) {
  switch (kind) {
    case kIllegal:
      return "illegal";
    case kSqrt:
      return "sqrt";
    case kDoubleSquare:
      return "double-square";
  }
  UNREACHABLE();
  return "";
}


const RuntimeEntry& CaseInsensitiveCompareUC16Instr::TargetFunction() const {
  return kCaseInsensitiveCompareUC16RuntimeEntry;
}


MergedMathInstr::MergedMathInstr(ZoneGrowableArray<Value*>* inputs,
                                 intptr_t deopt_id,
                                 MergedMathInstr::Kind kind)
    : PureDefinition(deopt_id), inputs_(inputs), kind_(kind) {
  ASSERT(inputs_->length() == InputCountFor(kind_));
  for (intptr_t i = 0; i < inputs_->length(); ++i) {
    ASSERT((*inputs)[i] != NULL);
    (*inputs)[i]->set_instruction(this);
    (*inputs)[i]->set_use_index(i);
  }
}


intptr_t MergedMathInstr::OutputIndexOf(MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kMathSin:
      return 1;
    case MethodRecognizer::kMathCos:
      return 0;
    default:
      UNIMPLEMENTED();
      return -1;
  }
}


intptr_t MergedMathInstr::OutputIndexOf(Token::Kind token) {
  switch (token) {
    case Token::kTRUNCDIV:
      return 0;
    case Token::kMOD:
      return 1;
    default:
      UNIMPLEMENTED();
      return -1;
  }
}


void NativeCallInstr::SetupNative() {
  Zone* zone = Thread::Current()->zone();
  const Class& cls = Class::Handle(zone, function().Owner());
  const Library& library = Library::Handle(zone, cls.library());
  const int num_params =
      NativeArguments::ParameterCountForResolution(function());
  bool auto_setup_scope = true;
  NativeFunction native_function = NativeEntry::ResolveNative(
      library, native_name(), num_params, &auto_setup_scope);
  if (native_function == NULL) {
    Report::MessageF(Report::kError, Script::Handle(function().script()),
                     function().token_pos(), Report::AtLocation,
                     "native function '%s' (%" Pd " arguments) cannot be found",
                     native_name().ToCString(), function().NumParameters());
  }
  set_native_c_function(native_function);
  function().SetIsNativeAutoSetupScope(auto_setup_scope);
  Dart_NativeEntryResolver resolver = library.native_entry_resolver();
  bool is_bootstrap_native = Bootstrap::IsBootstapResolver(resolver);
  set_is_bootstrap_native(is_bootstrap_native);
}

#undef __

}  // namespace dart
