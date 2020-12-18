// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"
#include "vm/resolver.h"

namespace dart {

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
// Smi->Int32 widening pass is disabled due to dartbug.com/32619.
DEFINE_FLAG(bool, use_smi_widening, false, "Enable Smi->Int32 widening pass.");
DEFINE_FLAG(bool, trace_smi_widening, false, "Trace Smi->Int32 widening pass.");
#endif
DEFINE_FLAG(bool, prune_dead_locals, true, "optimize dead locals away");

// Quick access to the current zone.
#define Z (zone())

FlowGraph::FlowGraph(const ParsedFunction& parsed_function,
                     GraphEntryInstr* graph_entry,
                     intptr_t max_block_id,
                     PrologueInfo prologue_info)
    : thread_(Thread::Current()),
      parent_(),
      current_ssa_temp_index_(0),
      max_block_id_(max_block_id),
      parsed_function_(parsed_function),
      num_direct_parameters_(parsed_function.function().HasOptionalParameters()
                                 ? 0
                                 : parsed_function.function().NumParameters()),
      direct_parameters_size_(0),
      graph_entry_(graph_entry),
      preorder_(),
      postorder_(),
      reverse_postorder_(),
      optimized_block_order_(),
      constant_null_(nullptr),
      constant_dead_(nullptr),
      licm_allowed_(true),
      prologue_info_(prologue_info),
      loop_hierarchy_(nullptr),
      loop_invariant_loads_(nullptr),
      captured_parameters_(new (zone()) BitVector(zone(), variable_count())),
      inlining_id_(-1),
      should_print_(FlowGraphPrinter::ShouldPrint(parsed_function.function())) {
  direct_parameters_size_ = ParameterOffsetAt(
      function(), num_direct_parameters_, /*last_slot*/ false);
  DiscoverBlocks();
}

void FlowGraph::EnsureSSATempIndex(Definition* defn, Definition* replacement) {
  if ((replacement->ssa_temp_index() == -1) && (defn->ssa_temp_index() != -1)) {
    AllocateSSAIndexes(replacement);
  }
}

intptr_t FlowGraph::ParameterOffsetAt(const Function& function,
                                      intptr_t index,
                                      bool last_slot /*=true*/) {
  ASSERT(index <= function.NumParameters());
  intptr_t param_offset = 0;
  for (intptr_t i = 0; i < index; i++) {
    if (function.is_unboxed_integer_parameter_at(i)) {
      param_offset += compiler::target::kIntSpillFactor;
    } else if (function.is_unboxed_double_parameter_at(i)) {
      param_offset += compiler::target::kDoubleSpillFactor;
    } else {
      ASSERT(!function.is_unboxed_parameter_at(i));
      // Unboxed parameters always occupy one word
      param_offset++;
    }
  }
  if (last_slot) {
    ASSERT(index < function.NumParameters());
    if (function.is_unboxed_double_parameter_at(index) &&
        compiler::target::kDoubleSpillFactor > 1) {
      ASSERT(compiler::target::kDoubleSpillFactor == 2);
      param_offset++;
    } else if (function.is_unboxed_integer_parameter_at(index) &&
               compiler::target::kIntSpillFactor > 1) {
      ASSERT(compiler::target::kIntSpillFactor == 2);
      param_offset++;
    }
  }
  return param_offset;
}

Representation FlowGraph::ParameterRepresentationAt(const Function& function,
                                                    intptr_t index) {
  if (function.IsNull()) {
    return kTagged;
  }
  ASSERT(index < function.NumParameters());
  if (function.is_unboxed_integer_parameter_at(index)) {
    return kUnboxedInt64;
  } else if (function.is_unboxed_double_parameter_at(index)) {
    return kUnboxedDouble;
  } else {
    ASSERT(!function.is_unboxed_parameter_at(index));
    return kTagged;
  }
}

Representation FlowGraph::ReturnRepresentationOf(const Function& function) {
  if (function.IsNull()) {
    return kTagged;
  }
  if (function.has_unboxed_integer_return()) {
    return kUnboxedInt64;
  } else if (function.has_unboxed_double_return()) {
    return kUnboxedDouble;
  } else {
    ASSERT(!function.has_unboxed_return());
    return kTagged;
  }
}

Representation FlowGraph::UnboxedFieldRepresentationOf(const Field& field) {
  switch (field.UnboxedFieldCid()) {
    case kDoubleCid:
      return kUnboxedDouble;
    case kFloat32x4Cid:
      return kUnboxedFloat32x4;
    case kFloat64x2Cid:
      return kUnboxedFloat64x2;
    default:
      RELEASE_ASSERT(field.is_non_nullable_integer());
      return kUnboxedInt64;
  }
}

void FlowGraph::ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                          Instruction* current,
                                          Instruction* replacement) {
  Definition* current_defn = current->AsDefinition();
  if ((replacement != NULL) && (current_defn != NULL)) {
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != NULL);
    current_defn->ReplaceUsesWith(replacement_defn);
    EnsureSSATempIndex(current_defn, replacement_defn);

    if (FLAG_trace_optimization) {
      THR_Print("Replacing v%" Pd " with v%" Pd "\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    if (current_defn == NULL) {
      THR_Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      THR_Print("Removing v%" Pd ".\n", current_defn->ssa_temp_index());
    }
  }
  if (current->ArgumentCount() != 0) {
    ASSERT(!current->HasPushArguments());
  }
  iterator->RemoveCurrentFromGraph();
}

bool FlowGraph::ShouldReorderBlocks(const Function& function,
                                    bool is_optimized) {
  return is_optimized && FLAG_reorder_basic_blocks &&
         !function.is_intrinsic() && !function.IsFfiTrampoline();
}

GrowableArray<BlockEntryInstr*>* FlowGraph::CodegenBlockOrder(
    bool is_optimized) {
  return ShouldReorderBlocks(function(), is_optimized) ? &optimized_block_order_
                                                       : &reverse_postorder_;
}

ConstantInstr* FlowGraph::GetExistingConstant(const Object& object) const {
  return constant_instr_pool_.LookupValue(object);
}

ConstantInstr* FlowGraph::GetConstant(const Object& object) {
  ConstantInstr* constant = GetExistingConstant(object);
  if (constant == nullptr) {
    // Otherwise, allocate and add it to the pool.
    constant =
        new (zone()) ConstantInstr(Object::ZoneHandle(zone(), object.raw()));
    constant->set_ssa_temp_index(alloc_ssa_temp_index());
    if (NeedsPairLocation(constant->representation())) {
      alloc_ssa_temp_index();
    }
    AddToGraphInitialDefinitions(constant);
    constant_instr_pool_.Insert(constant);
  }
  return constant;
}

bool FlowGraph::IsConstantRepresentable(const Object& value,
                                        Representation target_rep,
                                        bool tagged_value_must_be_smi) {
  switch (target_rep) {
    case kTagged:
      return !tagged_value_must_be_smi || value.IsSmi();

    case kUnboxedInt32:
      if (value.IsInteger()) {
        return Utils::IsInt(32, Integer::Cast(value).AsInt64Value());
      }
      return false;

    case kUnboxedUint32:
      if (value.IsInteger()) {
        return Utils::IsUint(32, Integer::Cast(value).AsInt64Value());
      }
      return false;

    case kUnboxedInt64:
      return value.IsInteger();

    case kUnboxedDouble:
      return value.IsInteger() || value.IsDouble();

    default:
      return false;
  }
}

Definition* FlowGraph::TryCreateConstantReplacementFor(Definition* op,
                                                       const Object& value) {
  // Check that representation of the constant matches expected representation.
  if (!IsConstantRepresentable(
          value, op->representation(),
          /*tagged_value_must_be_smi=*/op->Type()->IsNullableSmi())) {
    return op;
  }

  Definition* result = GetConstant(value);
  if (op->representation() != kTagged) {
    // We checked above that constant can be safely unboxed.
    result = UnboxInstr::Create(op->representation(), new Value(result),
                                DeoptId::kNone, Instruction::kNotSpeculative);
    // If the current instruction is a phi we need to insert the replacement
    // into the block which contains this phi - because phis exist separately
    // from all other instructions.
    if (auto phi = op->AsPhi()) {
      InsertAfter(phi->GetBlock(), result, nullptr, FlowGraph::kValue);
    } else {
      InsertBefore(op, result, nullptr, FlowGraph::kValue);
    }
  }

  return result;
}

void FlowGraph::AddToGraphInitialDefinitions(Definition* defn) {
  defn->set_previous(graph_entry_);
  graph_entry_->initial_definitions()->Add(defn);
}

void FlowGraph::AddToInitialDefinitions(BlockEntryWithInitialDefs* entry,
                                        Definition* defn) {
  defn->set_previous(entry);
  if (auto par = defn->AsParameter()) {
    par->set_block(entry);  // set cached block
  }
  entry->initial_definitions()->Add(defn);
}

void FlowGraph::InsertBefore(Instruction* next,
                             Instruction* instr,
                             Environment* env,
                             UseKind use_kind) {
  InsertAfter(next->previous(), instr, env, use_kind);
}

void FlowGraph::InsertAfter(Instruction* prev,
                            Instruction* instr,
                            Environment* env,
                            UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndexes(instr->AsDefinition());
  }
  instr->InsertAfter(prev);
  ASSERT(instr->env() == NULL);
  if (env != NULL) {
    env->DeepCopyTo(zone(), instr);
  }
}

Instruction* FlowGraph::AppendTo(Instruction* prev,
                                 Instruction* instr,
                                 Environment* env,
                                 UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndexes(instr->AsDefinition());
  }
  ASSERT(instr->env() == NULL);
  if (env != NULL) {
    env->DeepCopyTo(zone(), instr);
  }
  return prev->AppendInstruction(instr);
}

// A wrapper around block entries including an index of the next successor to
// be read.
class BlockTraversalState {
 public:
  explicit BlockTraversalState(BlockEntryInstr* block)
      : block_(block),
        next_successor_ix_(block->last_instruction()->SuccessorCount() - 1) {}

  bool HasNextSuccessor() const { return next_successor_ix_ >= 0; }
  BlockEntryInstr* NextSuccessor() {
    ASSERT(HasNextSuccessor());
    return block_->last_instruction()->SuccessorAt(next_successor_ix_--);
  }

  BlockEntryInstr* block() const { return block_; }

 private:
  BlockEntryInstr* block_;
  intptr_t next_successor_ix_;

  DISALLOW_ALLOCATION();
};

void FlowGraph::DiscoverBlocks() {
  StackZone zone(thread());

  // Initialize state.
  preorder_.Clear();
  postorder_.Clear();
  reverse_postorder_.Clear();
  parent_.Clear();

  GrowableArray<BlockTraversalState> block_stack;
  graph_entry_->DiscoverBlock(NULL, &preorder_, &parent_);
  block_stack.Add(BlockTraversalState(graph_entry_));
  while (!block_stack.is_empty()) {
    BlockTraversalState& state = block_stack.Last();
    BlockEntryInstr* block = state.block();
    if (state.HasNextSuccessor()) {
      // Process successors one-by-one.
      BlockEntryInstr* succ = state.NextSuccessor();
      if (succ->DiscoverBlock(block, &preorder_, &parent_)) {
        block_stack.Add(BlockTraversalState(succ));
      }
    } else {
      // All successors have been processed, pop the current block entry node
      // and add it to the postorder list.
      block_stack.RemoveLast();
      block->set_postorder_number(postorder_.length());
      postorder_.Add(block);
    }
  }

  ASSERT(postorder_.length() == preorder_.length());

  // Create an array of blocks in reverse postorder.
  intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; ++i) {
    reverse_postorder_.Add(postorder_[block_count - i - 1]);
  }

  ResetLoopHierarchy();
}

void FlowGraph::MergeBlocks() {
  bool changed = false;
  BitVector* merged = new (zone()) BitVector(zone(), postorder().length());
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (block->IsGraphEntry()) continue;
    if (merged->Contains(block->postorder_number())) continue;

    Instruction* last = block->last_instruction();
    BlockEntryInstr* last_merged_block = nullptr;
    while (auto goto_instr = last->AsGoto()) {
      JoinEntryInstr* successor = goto_instr->successor();
      if (successor->PredecessorCount() > 1) break;
      if (block->try_index() != successor->try_index()) break;

      // Replace all phis with their arguments prior to removing successor.
      for (PhiIterator it(successor); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        Value* input = phi->InputAt(0);
        phi->ReplaceUsesWith(input->definition());
        input->RemoveFromUseList();
      }

      // Remove environment uses and unlink goto and block entry.
      successor->UnuseAllInputs();
      last->previous()->LinkTo(successor->next());
      last->UnuseAllInputs();

      last = successor->last_instruction();
      merged->Add(successor->postorder_number());
      last_merged_block = successor;
      changed = true;
      if (FLAG_trace_optimization) {
        THR_Print("Merged blocks B%" Pd " and B%" Pd "\n", block->block_id(),
                  successor->block_id());
      }
    }
    // The new block inherits the block id of the last successor to maintain
    // the order of phi inputs at its successors consistent with block ids.
    if (last_merged_block != nullptr) {
      block->set_block_id(last_merged_block->block_id());
    }
  }
  // Recompute block order after changes were made.
  if (changed) DiscoverBlocks();
}

void FlowGraph::ComputeIsReceiverRecursive(
    PhiInstr* phi,
    GrowableArray<PhiInstr*>* unmark) const {
  if (phi->is_receiver() != PhiInstr::kUnknownReceiver) return;
  phi->set_is_receiver(PhiInstr::kReceiver);
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Definition* def = phi->InputAt(i)->definition();
    if (def->IsParameter() && (def->AsParameter()->index() == 0)) continue;
    if (!def->IsPhi()) {
      phi->set_is_receiver(PhiInstr::kNotReceiver);
      break;
    }
    ComputeIsReceiverRecursive(def->AsPhi(), unmark);
    if (def->AsPhi()->is_receiver() == PhiInstr::kNotReceiver) {
      phi->set_is_receiver(PhiInstr::kNotReceiver);
      break;
    }
  }

  if (phi->is_receiver() == PhiInstr::kNotReceiver) {
    unmark->Add(phi);
  }
}

void FlowGraph::ComputeIsReceiver(PhiInstr* phi) const {
  GrowableArray<PhiInstr*> unmark;
  ComputeIsReceiverRecursive(phi, &unmark);

  // Now drain unmark.
  while (!unmark.is_empty()) {
    PhiInstr* phi = unmark.RemoveLast();
    for (Value::Iterator it(phi->input_use_list()); !it.Done(); it.Advance()) {
      PhiInstr* use = it.Current()->instruction()->AsPhi();
      if ((use != NULL) && (use->is_receiver() == PhiInstr::kReceiver)) {
        use->set_is_receiver(PhiInstr::kNotReceiver);
        unmark.Add(use);
      }
    }
  }
}

bool FlowGraph::IsReceiver(Definition* def) const {
  def = def->OriginalDefinition();  // Could be redefined.
  if (def->IsParameter()) return (def->AsParameter()->index() == 0);
  if (!def->IsPhi() || graph_entry()->HasSingleEntryPoint()) {
    return false;
  }
  PhiInstr* phi = def->AsPhi();
  if (phi->is_receiver() != PhiInstr::kUnknownReceiver) {
    return (phi->is_receiver() == PhiInstr::kReceiver);
  }
  // Not known if this phi is the receiver yet. Compute it now.
  ComputeIsReceiver(phi);
  return (phi->is_receiver() == PhiInstr::kReceiver);
}

FlowGraph::ToCheck FlowGraph::CheckForInstanceCall(
    InstanceCallInstr* call,
    FunctionLayout::Kind kind) const {
  if (!FLAG_use_cha_deopt && !isolate()->all_classes_finalized()) {
    // Even if class or function are private, lazy class finalization
    // may later add overriding methods.
    return ToCheck::kCheckCid;
  }

  // Best effort to get the receiver class.
  Value* receiver = call->Receiver();
  Class& receiver_class = Class::Handle(zone());
  bool receiver_maybe_null = false;
  if (function().IsDynamicFunction() && IsReceiver(receiver->definition())) {
    // Call receiver is callee receiver: calling "this.g()" in f().
    receiver_class = function().Owner();
  } else {
    // Get the receiver's compile type. Note that
    // we allow nullable types, which may result in just generating
    // a null check rather than the more elaborate class check
    CompileType* type = receiver->Type();
    const AbstractType* atype = type->ToAbstractType();
    if (atype->IsInstantiated() && atype->HasTypeClass() &&
        !atype->IsDynamicType()) {
      if (type->is_nullable()) {
        receiver_maybe_null = true;
      }
      receiver_class = atype->type_class();
      if (receiver_class.is_implemented()) {
        receiver_class = Class::null();
      }
    }
  }

  // Useful receiver class information?
  if (receiver_class.IsNull()) {
    return ToCheck::kCheckCid;
  } else if (call->HasICData()) {
    // If the static class type does not match information found in ICData
    // (which may be "guessed"), then bail, since subsequent code generation
    // (AOT and JIT) for inlining uses the latter.
    // TODO(ajcbik): improve this by using the static class.
    const intptr_t cid = receiver_class.id();
    const ICData* data = call->ic_data();
    bool match = false;
    Class& cls = Class::Handle(zone());
    Function& fun = Function::Handle(zone());
    for (intptr_t i = 0, len = data->NumberOfChecks(); i < len; i++) {
      if (!data->IsUsedAt(i)) {
        continue;  // do not consider
      }
      fun = data->GetTargetAt(i);
      cls = fun.Owner();
      if (data->GetReceiverClassIdAt(i) == cid || cls.id() == cid) {
        match = true;
        break;
      }
    }
    if (!match) {
      return ToCheck::kCheckCid;
    }
  }

  const String& method_name =
      (kind == FunctionLayout::kMethodExtractor)
          ? String::Handle(zone(), Field::NameFromGetter(call->function_name()))
          : call->function_name();

  // If the receiver can have the null value, exclude any method
  // that is actually valid on a null receiver.
  if (receiver_maybe_null) {
    const Class& null_class =
        Class::Handle(zone(), isolate()->object_store()->null_class());
    Function& target = Function::Handle(zone());
    if (null_class.EnsureIsFinalized(thread()) == Error::null()) {
      target = Resolver::ResolveDynamicAnyArgs(zone(), null_class, method_name);
    }
    if (!target.IsNull()) {
      return ToCheck::kCheckCid;
    }
  }

  // Use CHA to determine if the method is not overridden by any subclass
  // of the receiver class. Any methods that are valid when the receiver
  // has a null value are excluded above (to avoid throwing an exception
  // on something valid, like null.hashCode).
  intptr_t subclass_count = 0;
  CHA& cha = thread()->compiler_state().cha();
  if (!cha.HasOverride(receiver_class, method_name, &subclass_count)) {
    if (FLAG_trace_cha) {
      THR_Print(
          "  **(CHA) Instance call needs no class check since there "
          "are no overrides of method '%s' on '%s'\n",
          method_name.ToCString(), receiver_class.ToCString());
    }
    if (FLAG_use_cha_deopt) {
      cha.AddToGuardedClasses(receiver_class, subclass_count);
    }
    return receiver_maybe_null ? ToCheck::kCheckNull : ToCheck::kNoCheck;
  }
  return ToCheck::kCheckCid;
}

Instruction* FlowGraph::CreateCheckClass(Definition* to_check,
                                         const Cids& cids,
                                         intptr_t deopt_id,
                                         const InstructionSource& source) {
  if (cids.IsMonomorphic() && cids.MonomorphicReceiverCid() == kSmiCid) {
    return new (zone())
        CheckSmiInstr(new (zone()) Value(to_check), deopt_id, source);
  }
  return new (zone())
      CheckClassInstr(new (zone()) Value(to_check), deopt_id, cids, source);
}

Definition* FlowGraph::CreateCheckBound(Definition* length,
                                        Definition* index,
                                        intptr_t deopt_id) {
  Value* val1 = new (zone()) Value(length);
  Value* val2 = new (zone()) Value(index);
  if (CompilerState::Current().is_aot()) {
    return new (zone()) GenericCheckBoundInstr(val1, val2, deopt_id);
  }
  return new (zone()) CheckArrayBoundInstr(val1, val2, deopt_id);
}

void FlowGraph::AddExactnessGuard(InstanceCallInstr* call,
                                  intptr_t receiver_cid) {
  const Class& cls = Class::Handle(
      zone(), Isolate::Current()->class_table()->At(receiver_cid));

  Definition* load_type_args = new (zone()) LoadFieldInstr(
      call->Receiver()->CopyWithType(),
      Slot::GetTypeArgumentsSlotFor(thread(), cls), call->source());
  InsertBefore(call, load_type_args, call->env(), FlowGraph::kValue);

  const AbstractType& type =
      AbstractType::Handle(zone(), call->ic_data()->receivers_static_type());
  ASSERT(!type.IsNull());
  const TypeArguments& args = TypeArguments::Handle(zone(), type.arguments());
  Instruction* guard = new (zone()) CheckConditionInstr(
      new StrictCompareInstr(call->source(), Token::kEQ_STRICT,
                             new (zone()) Value(load_type_args),
                             new (zone()) Value(GetConstant(args)),
                             /*needs_number_check=*/false, call->deopt_id()),
      call->deopt_id());
  InsertBefore(call, guard, call->env(), FlowGraph::kEffect);
}

// Verify that a redefinition dominates all uses of the redefined value.
bool FlowGraph::VerifyRedefinitions() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      RedefinitionInstr* redefinition = instr_it.Current()->AsRedefinition();
      if (redefinition != NULL) {
        Definition* original = redefinition->value()->definition();
        for (Value::Iterator it(original->input_use_list()); !it.Done();
             it.Advance()) {
          Value* original_use = it.Current();
          if (original_use->instruction() == redefinition) {
            continue;
          }
          if (original_use->instruction()->IsDominatedBy(redefinition)) {
            FlowGraphPrinter::PrintGraph("VerifyRedefinitions", this);
            THR_Print("%s\n", redefinition->ToCString());
            THR_Print("use=%s\n", original_use->instruction()->ToCString());
            return false;
          }
        }
      }
    }
  }
  return true;
}

LivenessAnalysis::LivenessAnalysis(
    intptr_t variable_count,
    const GrowableArray<BlockEntryInstr*>& postorder)
    : zone_(Thread::Current()->zone()),
      variable_count_(variable_count),
      postorder_(postorder),
      live_out_(postorder.length()),
      kill_(postorder.length()),
      live_in_(postorder.length()) {}

bool LivenessAnalysis::UpdateLiveOut(const BlockEntryInstr& block) {
  BitVector* live_out = live_out_[block.postorder_number()];
  bool changed = false;
  Instruction* last = block.last_instruction();
  ASSERT(last != NULL);
  for (intptr_t i = 0; i < last->SuccessorCount(); i++) {
    BlockEntryInstr* succ = last->SuccessorAt(i);
    ASSERT(succ != NULL);
    if (live_out->AddAll(live_in_[succ->postorder_number()])) {
      changed = true;
    }
  }
  return changed;
}

bool LivenessAnalysis::UpdateLiveIn(const BlockEntryInstr& block) {
  BitVector* live_out = live_out_[block.postorder_number()];
  BitVector* kill = kill_[block.postorder_number()];
  BitVector* live_in = live_in_[block.postorder_number()];
  return live_in->KillAndAdd(kill, live_out);
}

void LivenessAnalysis::ComputeLiveInAndLiveOutSets() {
  const intptr_t block_count = postorder_.length();
  bool changed;
  do {
    changed = false;

    for (intptr_t i = 0; i < block_count; i++) {
      const BlockEntryInstr& block = *postorder_[i];

      // Live-in set depends only on kill set which does not
      // change in this loop and live-out set.  If live-out
      // set does not change there is no need to recompute
      // live-in set.
      if (UpdateLiveOut(block) && UpdateLiveIn(block)) {
        changed = true;
      }
    }
  } while (changed);
}

void LivenessAnalysis::Analyze() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    live_out_.Add(new (zone()) BitVector(zone(), variable_count_));
    kill_.Add(new (zone()) BitVector(zone(), variable_count_));
    live_in_.Add(new (zone()) BitVector(zone(), variable_count_));
  }

  ComputeInitialSets();
  ComputeLiveInAndLiveOutSets();
}

static void PrintBitVector(const char* tag, BitVector* v) {
  THR_Print("%s:", tag);
  for (BitVector::Iterator it(v); !it.Done(); it.Advance()) {
    THR_Print(" %" Pd "", it.Current());
  }
  THR_Print("\n");
}

void LivenessAnalysis::Dump() {
  const intptr_t block_count = postorder_.length();
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];
    THR_Print("block @%" Pd " -> ", block->block_id());

    Instruction* last = block->last_instruction();
    for (intptr_t j = 0; j < last->SuccessorCount(); j++) {
      BlockEntryInstr* succ = last->SuccessorAt(j);
      THR_Print(" @%" Pd "", succ->block_id());
    }
    THR_Print("\n");

    PrintBitVector("  live out", live_out_[i]);
    PrintBitVector("  kill", kill_[i]);
    PrintBitVector("  live in", live_in_[i]);
  }
}

// Computes liveness information for local variables.
class VariableLivenessAnalysis : public LivenessAnalysis {
 public:
  explicit VariableLivenessAnalysis(FlowGraph* flow_graph)
      : LivenessAnalysis(flow_graph->variable_count(), flow_graph->postorder()),
        flow_graph_(flow_graph),
        assigned_vars_() {}

  // For every block (in preorder) compute and return set of variables that
  // have new assigned values flowing out of that block.
  const GrowableArray<BitVector*>& ComputeAssignedVars() {
    // We can't directly return kill_ because it uses postorder numbering while
    // SSA construction uses preorder numbering internally.
    // We have to permute postorder into preorder.
    assigned_vars_.Clear();

    const intptr_t block_count = flow_graph_->preorder().length();
    for (intptr_t i = 0; i < block_count; i++) {
      BlockEntryInstr* block = flow_graph_->preorder()[i];
      // All locals are assigned inside a try{} block.
      // This is a safe approximation and workaround to force insertion of
      // phis for stores that appear non-live because of the way catch-blocks
      // are connected to the graph: They normally are dominated by the
      // try-entry, but are direct successors of the graph entry in our flow
      // graph.
      // TODO(fschneider): Improve this approximation by better modeling the
      // actual data flow to reduce the number of redundant phis.
      BitVector* kill = GetKillSet(block);
      if (block->InsideTryBlock()) {
        kill->SetAll();
      } else {
        kill->Intersect(GetLiveOutSet(block));
      }
      assigned_vars_.Add(kill);
    }

    return assigned_vars_;
  }

  // Returns true if the value set by the given store reaches any load from the
  // same local variable.
  bool IsStoreAlive(BlockEntryInstr* block, StoreLocalInstr* store) {
    if (store->local().Equals(*flow_graph_->CurrentContextVar())) {
      return true;
    }

    if (store->is_dead()) {
      return false;
    }
    if (store->is_last()) {
      const intptr_t index = flow_graph_->EnvIndex(&store->local());
      return GetLiveOutSet(block)->Contains(index);
    }

    return true;
  }

  // Returns true if the given load is the last for the local and the value
  // of the local will not flow into another one.
  bool IsLastLoad(BlockEntryInstr* block, LoadLocalInstr* load) {
    if (load->local().Equals(*flow_graph_->CurrentContextVar())) {
      return false;
    }
    const intptr_t index = flow_graph_->EnvIndex(&load->local());
    return load->is_last() && !GetLiveOutSet(block)->Contains(index);
  }

 private:
  virtual void ComputeInitialSets();

  const FlowGraph* flow_graph_;
  GrowableArray<BitVector*> assigned_vars_;
};

void VariableLivenessAnalysis::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();

  BitVector* last_loads = new (zone()) BitVector(zone(), variable_count_);
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];
    last_loads->Clear();

    // There is an implicit use (load-local) of every local variable at each
    // call inside a try{} block and every call has an implicit control-flow
    // to the catch entry. As an approximation we mark all locals as live
    // inside try{}.
    // TODO(fschneider): Improve this approximation, since not all local
    // variable stores actually reach a call.
    if (block->InsideTryBlock()) {
      live_in->SetAll();
      continue;
    }

    // Iterate backwards starting at the last instruction.
    for (BackwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      LoadLocalInstr* load = current->AsLoadLocal();
      if (load != NULL) {
        const intptr_t index = flow_graph_->EnvIndex(&load->local());
        if (index >= live_in->length()) continue;  // Skip tmp_locals.
        live_in->Add(index);
        if (!last_loads->Contains(index)) {
          last_loads->Add(index);
          load->mark_last();
        }
        continue;
      }

      StoreLocalInstr* store = current->AsStoreLocal();
      if (store != NULL) {
        const intptr_t index = flow_graph_->EnvIndex(&store->local());
        if (index >= live_in->length()) continue;  // Skip tmp_locals.
        if (kill->Contains(index)) {
          if (!live_in->Contains(index)) {
            store->mark_dead();
          }
        } else {
          if (!live_in->Contains(index)) {
            store->mark_last();
          }
          kill->Add(index);
        }
        live_in->Remove(index);
        continue;
      }
    }

    // For blocks with parameter or special parameter instructions we add them
    // to the kill set.
    const bool is_function_entry = block->IsFunctionEntry();
    const bool is_osr_entry = block->IsOsrEntry();
    const bool is_catch_block_entry = block->IsCatchBlockEntry();
    if (is_function_entry || is_osr_entry || is_catch_block_entry) {
      const intptr_t parameter_count =
          (is_osr_entry || is_catch_block_entry)
              ? flow_graph_->variable_count()
              : flow_graph_->num_direct_parameters();
      for (intptr_t i = 0; i < parameter_count; ++i) {
        live_in->Remove(i);
        kill->Add(i);
      }
    }
    if (is_function_entry) {
      if (flow_graph_->parsed_function().has_arg_desc_var()) {
        const auto index = flow_graph_->ArgumentDescriptorEnvIndex();
        live_in->Remove(index);
        kill->Add(index);
      }
    }
  }
}

void FlowGraph::ComputeSSA(
    intptr_t next_virtual_register_number,
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  ASSERT((next_virtual_register_number == 0) || (inlining_parameters != NULL));
  current_ssa_temp_index_ = next_virtual_register_number;
  GrowableArray<BitVector*> dominance_frontier;
  GrowableArray<intptr_t> idom;

  ComputeDominators(&dominance_frontier);

  VariableLivenessAnalysis variable_liveness(this);
  variable_liveness.Analyze();

  GrowableArray<PhiInstr*> live_phis;

  InsertPhis(preorder_, variable_liveness.ComputeAssignedVars(),
             dominance_frontier, &live_phis);

  // Rename uses to reference inserted phis where appropriate.
  // Collect phis that reach a non-environment use.
  Rename(&live_phis, &variable_liveness, inlining_parameters);

  // Propagate alive mark transitively from alive phis and then remove
  // non-live ones.
  RemoveDeadPhis(&live_phis);
}

// Compute immediate dominators and the dominance frontier for each basic
// block.  As a side effect of the algorithm, sets the immediate dominator
// of each basic block.
//
// dominance_frontier: an output parameter encoding the dominance frontier.
//     The array maps the preorder block number of a block to the set of
//     (preorder block numbers of) blocks in the dominance frontier.
void FlowGraph::ComputeDominators(
    GrowableArray<BitVector*>* dominance_frontier) {
  // Use the SEMI-NCA algorithm to compute dominators.  This is a two-pass
  // version of the Lengauer-Tarjan algorithm (LT is normally three passes)
  // that eliminates a pass by using nearest-common ancestor (NCA) to
  // compute immediate dominators from semidominators.  It also removes a
  // level of indirection in the link-eval forest data structure.
  //
  // The algorithm is described in Georgiadis, Tarjan, and Werneck's
  // "Finding Dominators in Practice".
  // See http://www.cs.princeton.edu/~rwerneck/dominators/ .

  // All arrays are maps between preorder basic-block numbers.
  intptr_t size = parent_.length();
  GrowableArray<intptr_t> idom(size);   // Immediate dominator.
  GrowableArray<intptr_t> semi(size);   // Semidominator.
  GrowableArray<intptr_t> label(size);  // Label for link-eval forest.

  // 1. First pass: compute semidominators as in Lengauer-Tarjan.
  // Semidominators are computed from a depth-first spanning tree and are an
  // approximation of immediate dominators.

  // Use a link-eval data structure with path compression.  Implement path
  // compression in place by mutating the parent array.  Each block has a
  // label, which is the minimum block number on the compressed path.

  // Initialize idom, semi, and label used by SEMI-NCA.  Initialize the
  // dominance frontier output array.
  for (intptr_t i = 0; i < size; ++i) {
    idom.Add(parent_[i]);
    semi.Add(i);
    label.Add(i);
    dominance_frontier->Add(new (zone()) BitVector(zone(), size));
  }

  // Loop over the blocks in reverse preorder (not including the graph
  // entry).  Clear the dominated blocks in the graph entry in case
  // ComputeDominators is used to recompute them.
  preorder_[0]->ClearDominatedBlocks();
  for (intptr_t block_index = size - 1; block_index >= 1; --block_index) {
    // Loop over the predecessors.
    BlockEntryInstr* block = preorder_[block_index];
    // Clear the immediately dominated blocks in case ComputeDominators is
    // used to recompute them.
    block->ClearDominatedBlocks();
    for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ASSERT(pred != NULL);

      // Look for the semidominator by ascending the semidominator path
      // starting from pred.
      intptr_t pred_index = pred->preorder_number();
      intptr_t best = pred_index;
      if (pred_index > block_index) {
        CompressPath(block_index, pred_index, &parent_, &label);
        best = label[pred_index];
      }

      // Update the semidominator if we've found a better one.
      semi[block_index] = Utils::Minimum(semi[block_index], semi[best]);
    }

    // Now use label for the semidominator.
    label[block_index] = semi[block_index];
  }

  // 2. Compute the immediate dominators as the nearest common ancestor of
  // spanning tree parent and semidominator, for all blocks except the entry.
  for (intptr_t block_index = 1; block_index < size; ++block_index) {
    intptr_t dom_index = idom[block_index];
    while (dom_index > semi[block_index]) {
      dom_index = idom[dom_index];
    }
    idom[block_index] = dom_index;
    preorder_[dom_index]->AddDominatedBlock(preorder_[block_index]);
  }

  // 3. Now compute the dominance frontier for all blocks.  This is
  // algorithm in "A Simple, Fast Dominance Algorithm" (Figure 5), which is
  // attributed to a paper by Ferrante et al.  There is no bookkeeping
  // required to avoid adding a block twice to the same block's dominance
  // frontier because we use a set to represent the dominance frontier.
  for (intptr_t block_index = 0; block_index < size; ++block_index) {
    BlockEntryInstr* block = preorder_[block_index];
    intptr_t count = block->PredecessorCount();
    if (count <= 1) continue;
    for (intptr_t i = 0; i < count; ++i) {
      BlockEntryInstr* runner = block->PredecessorAt(i);
      while (runner != block->dominator()) {
        (*dominance_frontier)[runner->preorder_number()]->Add(block_index);
        runner = runner->dominator();
      }
    }
  }
}

void FlowGraph::CompressPath(intptr_t start_index,
                             intptr_t current_index,
                             GrowableArray<intptr_t>* parent,
                             GrowableArray<intptr_t>* label) {
  intptr_t next_index = (*parent)[current_index];
  if (next_index > start_index) {
    CompressPath(start_index, next_index, parent, label);
    (*label)[current_index] =
        Utils::Minimum((*label)[current_index], (*label)[next_index]);
    (*parent)[current_index] = (*parent)[next_index];
  }
}

void FlowGraph::InsertPhis(const GrowableArray<BlockEntryInstr*>& preorder,
                           const GrowableArray<BitVector*>& assigned_vars,
                           const GrowableArray<BitVector*>& dom_frontier,
                           GrowableArray<PhiInstr*>* live_phis) {
  const intptr_t block_count = preorder.length();
  // Map preorder block number to the highest variable index that has a phi
  // in that block.  Use it to avoid inserting multiple phis for the same
  // variable.
  GrowableArray<intptr_t> has_already(block_count);
  // Map preorder block number to the highest variable index for which the
  // block went on the worklist.  Use it to avoid adding the same block to
  // the worklist more than once for the same variable.
  GrowableArray<intptr_t> work(block_count);

  // Initialize has_already and work.
  for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
    has_already.Add(-1);
    work.Add(-1);
  }

  // Insert phis for each variable in turn.
  GrowableArray<BlockEntryInstr*> worklist;
  for (intptr_t var_index = 0; var_index < variable_count(); ++var_index) {
    const bool always_live =
        !FLAG_prune_dead_locals || (var_index == CurrentContextEnvIndex());
    // Add to the worklist each block containing an assignment.
    for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
      if (assigned_vars[block_index]->Contains(var_index)) {
        work[block_index] = var_index;
        worklist.Add(preorder[block_index]);
      }
    }

    while (!worklist.is_empty()) {
      BlockEntryInstr* current = worklist.RemoveLast();
      // Ensure a phi for each block in the dominance frontier of current.
      for (BitVector::Iterator it(dom_frontier[current->preorder_number()]);
           !it.Done(); it.Advance()) {
        int index = it.Current();
        if (has_already[index] < var_index) {
          JoinEntryInstr* join = preorder[index]->AsJoinEntry();
          ASSERT(join != nullptr);
          PhiInstr* phi = join->InsertPhi(
              var_index, variable_count() + join->stack_depth());
          if (always_live) {
            phi->mark_alive();
            live_phis->Add(phi);
          }
          has_already[index] = var_index;
          if (work[index] < var_index) {
            work[index] = var_index;
            worklist.Add(join);
          }
        }
      }
    }
  }
}

void FlowGraph::CreateCommonConstants() {
  constant_null_ = GetConstant(Object::ZoneHandle());
  constant_dead_ = GetConstant(Symbols::OptimizedOut());
}

void FlowGraph::AddSyntheticPhis(BlockEntryInstr* block) {
  ASSERT(IsCompiledForOsr());
  if (auto join = block->AsJoinEntry()) {
    const intptr_t local_phi_count = variable_count() + join->stack_depth();
    for (intptr_t i = variable_count(); i < local_phi_count; ++i) {
      if (join->phis() == nullptr || (*join->phis())[i] == nullptr) {
        join->InsertPhi(i, local_phi_count)->mark_alive();
      }
    }
  }
}

void FlowGraph::Rename(GrowableArray<PhiInstr*>* live_phis,
                       VariableLivenessAnalysis* variable_liveness,
                       ZoneGrowableArray<Definition*>* inlining_parameters) {
  GraphEntryInstr* entry = graph_entry();

  // Add global constants to the initial definitions.
  CreateCommonConstants();

  // Initial renaming environment.
  GrowableArray<Definition*> env(variable_count());
  env.FillWith(constant_dead(), 0, num_direct_parameters());
  env.FillWith(constant_null(), num_direct_parameters(), num_stack_locals());

  if (entry->catch_entries().length() > 0) {
    // Functions with try-catch have a fixed area of stack slots reserved
    // so that all local variables are stored at a known location when
    // on entry to the catch.
    entry->set_fixed_slot_count(num_stack_locals());
  } else {
    ASSERT(entry->unchecked_entry() != nullptr ? entry->SuccessorCount() == 2
                                               : entry->SuccessorCount() == 1);
  }

  // For OSR on a non-empty stack, insert synthetic phis on every joining entry.
  // These phis are synthetic since they are not driven by live variable
  // analysis, but merely serve the purpose of merging stack slots from
  // parameters and other predecessors at the block in which OSR occurred.
  if (IsCompiledForOsr()) {
    AddSyntheticPhis(entry->osr_entry()->last_instruction()->SuccessorAt(0));
    for (intptr_t i = 0, n = entry->dominated_blocks().length(); i < n; ++i) {
      AddSyntheticPhis(entry->dominated_blocks()[i]);
    }
  }

  RenameRecursive(entry, &env, live_phis, variable_liveness,
                  inlining_parameters);
}

void FlowGraph::PopulateEnvironmentFromFunctionEntry(
    FunctionEntryInstr* function_entry,
    GrowableArray<Definition*>* env,
    GrowableArray<PhiInstr*>* live_phis,
    VariableLivenessAnalysis* variable_liveness,
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  ASSERT(!IsCompiledForOsr());
  const intptr_t direct_parameter_count = num_direct_parameters_;

  // Check if inlining_parameters include a type argument vector parameter.
  const intptr_t inlined_type_args_param =
      ((inlining_parameters != NULL) && function().IsGeneric()) ? 1 : 0;

  ASSERT(variable_count() == env->length());
  ASSERT(direct_parameter_count <= env->length());
  intptr_t param_offset = 0;
  for (intptr_t i = 0; i < direct_parameter_count; i++) {
    ASSERT(FLAG_precompiled_mode || !function().is_unboxed_parameter_at(i));
    ParameterInstr* param;

    const intptr_t index = (function().IsFactory() ? (i - 1) : i);

    if (index >= 0 && function().is_unboxed_integer_parameter_at(index)) {
      constexpr intptr_t kCorrection = compiler::target::kIntSpillFactor - 1;
      param = new (zone()) ParameterInstr(i, param_offset + kCorrection,
                                          function_entry, kUnboxedInt64);
      param_offset += compiler::target::kIntSpillFactor;
    } else if (index >= 0 && function().is_unboxed_double_parameter_at(index)) {
      constexpr intptr_t kCorrection = compiler::target::kDoubleSpillFactor - 1;
      param = new (zone()) ParameterInstr(i, param_offset + kCorrection,
                                          function_entry, kUnboxedDouble);
      param_offset += compiler::target::kDoubleSpillFactor;
    } else {
      ASSERT(index < 0 || !function().is_unboxed_parameter_at(index));
      param =
          new (zone()) ParameterInstr(i, param_offset, function_entry, kTagged);
      param_offset++;
    }
    param->set_ssa_temp_index(alloc_ssa_temp_index());
    if (NeedsPairLocation(param->representation())) alloc_ssa_temp_index();
    AddToInitialDefinitions(function_entry, param);
    (*env)[i] = param;
  }

  // Override the entries in the renaming environment which are special (i.e.
  // inlining arguments, type parameter, args descriptor, context, ...)
  {
    // Replace parameter slots with inlining definitions coming in.
    if (inlining_parameters != NULL) {
      for (intptr_t i = 0; i < function().NumParameters(); ++i) {
        Definition* defn = (*inlining_parameters)[inlined_type_args_param + i];
        AllocateSSAIndexes(defn);
        AddToInitialDefinitions(function_entry, defn);

        intptr_t index = EnvIndex(parsed_function_.RawParameterVariable(i));
        (*env)[index] = defn;
      }
    }

    // Replace the type arguments slot with a special parameter.
    const bool reify_generic_argument = function().IsGeneric();
    if (reify_generic_argument) {
      ASSERT(parsed_function().function_type_arguments() != NULL);
      Definition* defn;
      if (inlining_parameters == NULL) {
        // Note: If we are not inlining, then the prologue builder will
        // take care of checking that we got the correct reified type
        // arguments.  This includes checking the argument descriptor in order
        // to even find out if the parameter was passed or not.
        defn = constant_dead();
      } else {
        defn = (*inlining_parameters)[0];
      }
      AllocateSSAIndexes(defn);
      AddToInitialDefinitions(function_entry, defn);
      (*env)[RawTypeArgumentEnvIndex()] = defn;
    }

    // Replace the argument descriptor slot with a special parameter.
    if (parsed_function().has_arg_desc_var()) {
      Definition* defn =
          new (Z) SpecialParameterInstr(SpecialParameterInstr::kArgDescriptor,
                                        DeoptId::kNone, function_entry);
      AllocateSSAIndexes(defn);
      AddToInitialDefinitions(function_entry, defn);
      (*env)[ArgumentDescriptorEnvIndex()] = defn;
    }
  }
}

void FlowGraph::PopulateEnvironmentFromOsrEntry(
    OsrEntryInstr* osr_entry,
    GrowableArray<Definition*>* env) {
  ASSERT(IsCompiledForOsr());
  // During OSR, all variables and possibly a non-empty stack are
  // passed as parameters. The latter mimics the incoming expression
  // stack that was set up prior to triggering OSR.
  const intptr_t parameter_count = osr_variable_count();
  ASSERT(parameter_count == env->length());
  for (intptr_t i = 0; i < parameter_count; i++) {
    ParameterInstr* param =
        new (zone()) ParameterInstr(i, i, osr_entry, kTagged);
    param->set_ssa_temp_index(alloc_ssa_temp_index());
    AddToInitialDefinitions(osr_entry, param);
    (*env)[i] = param;
  }
}

void FlowGraph::PopulateEnvironmentFromCatchEntry(
    CatchBlockEntryInstr* catch_entry,
    GrowableArray<Definition*>* env) {
  const intptr_t raw_exception_var_envindex =
      catch_entry->raw_exception_var() != nullptr
          ? EnvIndex(catch_entry->raw_exception_var())
          : -1;
  const intptr_t raw_stacktrace_var_envindex =
      catch_entry->raw_stacktrace_var() != nullptr
          ? EnvIndex(catch_entry->raw_stacktrace_var())
          : -1;

  // Add real definitions for all locals and parameters.
  ASSERT(variable_count() == env->length());
  for (intptr_t i = 0, n = variable_count(); i < n; ++i) {
    // Replace usages of the raw exception/stacktrace variables with
    // [SpecialParameterInstr]s.
    Definition* param = nullptr;
    if (raw_exception_var_envindex == i) {
      param = new (Z) SpecialParameterInstr(SpecialParameterInstr::kException,
                                            DeoptId::kNone, catch_entry);
    } else if (raw_stacktrace_var_envindex == i) {
      param = new (Z) SpecialParameterInstr(SpecialParameterInstr::kStackTrace,
                                            DeoptId::kNone, catch_entry);
    } else {
      param = new (Z) ParameterInstr(i, i, catch_entry, kTagged);
    }

    param->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
    (*env)[i] = param;
    AddToInitialDefinitions(catch_entry, param);
  }
}

void FlowGraph::AttachEnvironment(Instruction* instr,
                                  GrowableArray<Definition*>* env) {
  Environment* deopt_env =
      Environment::From(zone(), *env, num_direct_parameters_, parsed_function_);
  if (instr->IsClosureCall() || instr->IsLoadField()) {
    // Trim extra inputs of ClosureCall and LoadField instructions from
    // the environment. Inputs of those instructions are not pushed onto
    // the stack at the point where deoptimization can occur.
    // Note that in case of LoadField there can be two possible situations,
    // the code here handles LoadField to LoadField lazy deoptimization in
    // which we are transitioning from position after the call to initialization
    // stub in optimized code to a similar position after the call to
    // initialization stub in unoptimized code. There is another variant
    // (LoadField deoptimizing into a position after a getter call) which is
    // handled in a different way (see
    // CallSpecializer::InlineImplicitInstanceGetter).
    deopt_env =
        deopt_env->DeepCopy(zone(), deopt_env->Length() - instr->InputCount() +
                                        instr->ArgumentCount());
  }
  instr->SetEnvironment(deopt_env);
  for (Environment::DeepIterator it(deopt_env); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    use->definition()->AddEnvUse(use);
  }
}

void FlowGraph::RenameRecursive(
    BlockEntryInstr* block_entry,
    GrowableArray<Definition*>* env,
    GrowableArray<PhiInstr*>* live_phis,
    VariableLivenessAnalysis* variable_liveness,
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  // 1. Process phis first.
  if (auto join = block_entry->AsJoinEntry()) {
    if (join->phis() != nullptr) {
      const intptr_t local_phi_count = variable_count() + join->stack_depth();
      ASSERT(join->phis()->length() == local_phi_count);
      for (intptr_t i = 0; i < local_phi_count; ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != nullptr) {
          (*env)[i] = phi;
          AllocateSSAIndexes(phi);  // New SSA temp.
          if (block_entry->InsideTryBlock() && !phi->is_alive()) {
            // This is a safe approximation.  Inside try{} all locals are
            // used at every call implicitly, so we mark all phis as live
            // from the start.
            // TODO(fschneider): Improve this approximation to eliminate
            // more redundant phis.
            phi->mark_alive();
            live_phis->Add(phi);
          }
        }
      }
    }
  } else if (auto osr_entry = block_entry->AsOsrEntry()) {
    PopulateEnvironmentFromOsrEntry(osr_entry, env);
  } else if (auto function_entry = block_entry->AsFunctionEntry()) {
    ASSERT(!IsCompiledForOsr());
    PopulateEnvironmentFromFunctionEntry(
        function_entry, env, live_phis, variable_liveness, inlining_parameters);
  } else if (auto catch_entry = block_entry->AsCatchBlockEntry()) {
    PopulateEnvironmentFromCatchEntry(catch_entry, env);
  }

  if (!block_entry->IsGraphEntry() &&
      !block_entry->IsBlockEntryWithInitialDefs()) {
    // Prune non-live variables at block entry by replacing their environment
    // slots with null.
    BitVector* live_in = variable_liveness->GetLiveInSet(block_entry);
    for (intptr_t i = 0; i < variable_count(); i++) {
      // TODO(fschneider): Make sure that live_in always contains the
      // CurrentContext variable to avoid the special case here.
      if (FLAG_prune_dead_locals && !live_in->Contains(i) &&
          (i != CurrentContextEnvIndex())) {
        (*env)[i] = constant_dead();
      }
    }
  }

  // Attach environment to the block entry.
  AttachEnvironment(block_entry, env);

  // 2. Process normal instructions.
  for (ForwardInstructionIterator it(block_entry); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();

    // Attach current environment to the instructions that need it.
    if (current->NeedsEnvironment()) {
      AttachEnvironment(current, env);
    }

    // 2a. Handle uses:
    // Update the expression stack renaming environment for each use by
    // removing the renamed value. For each use of a LoadLocal, StoreLocal,
    // MakeTemp, DropTemps or Constant (or any expression under OSR),
    // replace it with the renamed value.
    for (intptr_t i = current->InputCount() - 1; i >= 0; --i) {
      Value* v = current->InputAt(i);
      // Update expression stack.
      ASSERT(env->length() > variable_count());
      Definition* reaching_defn = env->RemoveLast();
      Definition* input_defn = v->definition();
      if (input_defn != reaching_defn) {
        // Inspect the replacing definition before making the change.
        if (IsCompiledForOsr()) {
          // Under OSR, constants can reside on the expression stack. Just
          // generate the constant rather than going through a synthetic phi.
          if (input_defn->IsConstant() && reaching_defn->IsPhi()) {
            ASSERT(env->length() < osr_variable_count());
            auto constant = GetConstant(input_defn->AsConstant()->value());
            current->ReplaceInEnvironment(reaching_defn, constant);
            reaching_defn = constant;
          }
        } else {
          // Note: constants can only be replaced with other constants.
          ASSERT(input_defn->IsLoadLocal() || input_defn->IsStoreLocal() ||
                 input_defn->IsDropTemps() || input_defn->IsMakeTemp() ||
                 (input_defn->IsConstant() && reaching_defn->IsConstant()));
        }
        // Assert we are not referencing nulls in the initial environment.
        ASSERT(reaching_defn->ssa_temp_index() != -1);
        // Replace the definition.
        v->set_definition(reaching_defn);
        input_defn = reaching_defn;
      }
      input_defn->AddInputUse(v);
    }

    // 2b. Handle LoadLocal/StoreLocal/MakeTemp/DropTemps/Constant specially.
    // Other definitions are just pushed to the environment directly.
    Definition* result = NULL;
    switch (current->tag()) {
      case Instruction::kLoadLocal: {
        LoadLocalInstr* load = current->Cast<LoadLocalInstr>();

        // The graph construction ensures we do not have an unused LoadLocal
        // computation.
        ASSERT(load->HasTemp());
        const intptr_t index = EnvIndex(&load->local());
        result = (*env)[index];

        PhiInstr* phi = result->AsPhi();
        if ((phi != NULL) && !phi->is_alive()) {
          phi->mark_alive();
          live_phis->Add(phi);
        }

        if (FLAG_prune_dead_locals &&
            variable_liveness->IsLastLoad(block_entry, load)) {
          (*env)[index] = constant_dead();
        }

        // Record captured parameters so that they can be skipped when
        // emitting sync code inside optimized try-blocks.
        if (load->local().is_captured_parameter()) {
          captured_parameters_->Add(index);
        }

        if (phi != nullptr) {
          // Assign type to Phi if it doesn't have a type yet.
          // For a Phi to appear in the local variable it either was placed
          // there as incoming value by renaming or it was stored there by
          // StoreLocal which took this Phi from another local via LoadLocal,
          // to which this reasoning applies recursively.
          //
          // This means that we are guaranteed to process LoadLocal for a
          // matching variable first, unless there was an OSR with a non-empty
          // expression stack. In the latter case, Phi inserted by
          // FlowGraph::AddSyntheticPhis for expression temp will not have an
          // assigned type and may be accessed by StoreLocal and subsequent
          // LoadLocal.
          //
          if (!phi->HasType()) {
            // Check if phi corresponds to the same slot.
            auto* phis = phi->block()->phis();
            if ((index < phis->length()) && (*phis)[index] == phi) {
              phi->UpdateType(
                  CompileType::FromAbstractType(load->local().type()));
            } else {
              ASSERT(IsCompiledForOsr() && (phi->block()->stack_depth() > 0));
            }
          }
        }
        break;
      }

      case Instruction::kStoreLocal: {
        StoreLocalInstr* store = current->Cast<StoreLocalInstr>();
        const intptr_t index = EnvIndex(&store->local());
        result = store->value()->definition();

        if (!FLAG_prune_dead_locals ||
            variable_liveness->IsStoreAlive(block_entry, store)) {
          (*env)[index] = result;
        } else {
          (*env)[index] = constant_dead();
        }
        break;
      }

      case Instruction::kDropTemps: {
        // Drop temps from the environment.
        DropTempsInstr* drop = current->Cast<DropTempsInstr>();
        for (intptr_t j = 0; j < drop->num_temps(); j++) {
          env->RemoveLast();
        }
        if (drop->value() != NULL) {
          result = drop->value()->definition();
        }
        ASSERT((drop->value() != NULL) || !drop->HasTemp());
        break;
      }

      case Instruction::kConstant: {
        ConstantInstr* constant = current->Cast<ConstantInstr>();
        if (constant->HasTemp()) {
          result = GetConstant(constant->value());
        }
        break;
      }

      case Instruction::kMakeTemp: {
        // Simply push a #null value to the expression stack.
        result = constant_null_;
        break;
      }

      case Instruction::kPushArgument:
        UNREACHABLE();
        break;

      case Instruction::kCheckStackOverflow:
        // Assert environment integrity at checkpoints.
        ASSERT((variable_count() +
                current->AsCheckStackOverflow()->stack_depth()) ==
               env->length());
        continue;

      default:
        // Other definitions directly go into the environment.
        if (Definition* definition = current->AsDefinition()) {
          if (definition->HasTemp()) {
            // Assign fresh SSA temporary and update expression stack.
            AllocateSSAIndexes(definition);
            env->Add(definition);
          }
        }
        continue;
    }

    // Update expression stack and remove current instruction from the graph.
    Definition* definition = current->Cast<Definition>();
    if (definition->HasTemp()) {
      ASSERT(result != nullptr);
      env->Add(result);
    }
    it.RemoveCurrentFromGraph();
  }

  // 3. Process dominated blocks.
  const bool set_stack = (block_entry == graph_entry()) && IsCompiledForOsr();
  for (intptr_t i = 0; i < block_entry->dominated_blocks().length(); ++i) {
    BlockEntryInstr* block = block_entry->dominated_blocks()[i];
    GrowableArray<Definition*> new_env(env->length());
    new_env.AddArray(*env);
    // During OSR, when traversing from the graph entry directly any block
    // (which may be a non-entry), we must adjust the environment to mimic
    // a non-empty incoming expression stack to ensure temporaries refer to
    // the right stack items.
    const intptr_t stack_depth = block->stack_depth();
    ASSERT(stack_depth >= 0);
    if (set_stack) {
      ASSERT(variable_count() == new_env.length());
      new_env.FillWith(constant_dead(), variable_count(), stack_depth);
    } else if (!block->last_instruction()->IsTailCall()) {
      // Assert environment integrity otherwise.
      ASSERT((variable_count() + stack_depth) == new_env.length());
    }
    RenameRecursive(block, &new_env, live_phis, variable_liveness,
                    inlining_parameters);
  }

  // 4. Process successor block. We have edge-split form, so that only blocks
  // with one successor can have a join block as successor.
  if ((block_entry->last_instruction()->SuccessorCount() == 1) &&
      block_entry->last_instruction()->SuccessorAt(0)->IsJoinEntry()) {
    JoinEntryInstr* successor =
        block_entry->last_instruction()->SuccessorAt(0)->AsJoinEntry();
    intptr_t pred_index = successor->IndexOfPredecessor(block_entry);
    ASSERT(pred_index >= 0);
    if (successor->phis() != NULL) {
      for (intptr_t i = 0; i < successor->phis()->length(); ++i) {
        PhiInstr* phi = (*successor->phis())[i];
        if (phi != nullptr) {
          // Rename input operand.
          Definition* input = (*env)[i];
          ASSERT(input != nullptr);
          ASSERT(!input->IsPushArgument());
          Value* use = new (zone()) Value(input);
          phi->SetInputAt(pred_index, use);
        }
      }
    }
  }
}

void FlowGraph::RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis) {
  // Augment live_phis with those that have implicit real used at
  // potentially throwing instructions if there is a try-catch in this graph.
  if (!graph_entry()->catch_entries().is_empty()) {
    for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
      JoinEntryInstr* join = it.Current()->AsJoinEntry();
      if (join == NULL) continue;
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* phi = phi_it.Current();
        if (phi == NULL || phi->is_alive() || (phi->input_use_list() != NULL) ||
            (phi->env_use_list() == NULL)) {
          continue;
        }
        for (Value::Iterator it(phi->env_use_list()); !it.Done();
             it.Advance()) {
          Value* use = it.Current();
          if (use->instruction()->MayThrow() &&
              use->instruction()->GetBlock()->InsideTryBlock()) {
            live_phis->Add(phi);
            phi->mark_alive();
            break;
          }
        }
      }
    }
  }

  while (!live_phis->is_empty()) {
    PhiInstr* phi = live_phis->RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      PhiInstr* used_phi = val->definition()->AsPhi();
      if ((used_phi != NULL) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis->Add(used_phi);
      }
    }
  }

  for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
    JoinEntryInstr* join = it.Current()->AsJoinEntry();
    if (join != NULL) join->RemoveDeadPhis(constant_dead());
  }
}

RedefinitionInstr* FlowGraph::EnsureRedefinition(Instruction* prev,
                                                 Definition* original,
                                                 CompileType compile_type) {
  RedefinitionInstr* first = prev->next()->AsRedefinition();
  if (first != nullptr && (first->constrained_type() != nullptr)) {
    if ((first->value()->definition() == original) &&
        first->constrained_type()->IsEqualTo(&compile_type)) {
      // Already redefined. Do nothing.
      return nullptr;
    }
  }
  RedefinitionInstr* redef = new RedefinitionInstr(new Value(original));

  // Don't set the constrained type when the type is None(), which denotes an
  // unreachable value (e.g. using value null after some form of null check).
  if (!compile_type.IsNone()) {
    redef->set_constrained_type(new CompileType(compile_type));
  }

  InsertAfter(prev, redef, nullptr, FlowGraph::kValue);
  RenameDominatedUses(original, redef, redef);

  if (redef->input_use_list() == nullptr) {
    // There are no dominated uses, so the newly added Redefinition is useless.
    // Remove Redefinition to avoid interfering with
    // BranchSimplifier::Simplify which needs empty blocks.
    redef->RemoveFromGraph();
    return nullptr;
  }

  return redef;
}

void FlowGraph::RemoveRedefinitions(bool keep_checks) {
  // Remove redefinition and check instructions that were inserted
  // to make a control dependence explicit with a data dependence,
  // for example, to inhibit hoisting.
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    thread()->CheckForSafepoint();
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      Instruction* instruction = instr_it.Current();
      if (auto redef = instruction->AsRedefinition()) {
        redef->ReplaceUsesWith(redef->value()->definition());
        instr_it.RemoveCurrentFromGraph();
      } else if (keep_checks) {
        continue;
      } else if (auto def = instruction->AsDefinition()) {
        Value* value = def->RedefinedValue();
        if (value != nullptr) {
          def->ReplaceUsesWith(value->definition());
          def->ClearSSATempIndex();
        }
      }
    }
  }
}

BitVector* FlowGraph::FindLoopBlocks(BlockEntryInstr* m,
                                     BlockEntryInstr* n) const {
  GrowableArray<BlockEntryInstr*> stack;
  BitVector* loop_blocks = new (zone()) BitVector(zone(), preorder_.length());

  loop_blocks->Add(n->preorder_number());
  if (n != m) {
    loop_blocks->Add(m->preorder_number());
    stack.Add(m);
  }

  while (!stack.is_empty()) {
    BlockEntryInstr* p = stack.RemoveLast();
    for (intptr_t i = 0; i < p->PredecessorCount(); ++i) {
      BlockEntryInstr* q = p->PredecessorAt(i);
      if (!loop_blocks->Contains(q->preorder_number())) {
        loop_blocks->Add(q->preorder_number());
        stack.Add(q);
      }
    }
  }
  return loop_blocks;
}

LoopHierarchy* FlowGraph::ComputeLoops() const {
  // Iterate over all entry blocks in the flow graph to attach
  // loop information to each loop header.
  ZoneGrowableArray<BlockEntryInstr*>* loop_headers =
      new (zone()) ZoneGrowableArray<BlockEntryInstr*>();
  for (BlockIterator it = postorder_iterator(); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    // Reset loop information on every entry block (since this method
    // may recompute loop information on a modified flow graph).
    block->set_loop_info(nullptr);
    // Iterate over predecessors to find back edges.
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (block->Dominates(pred)) {
        // Identify the block as a loop header and add the blocks in the
        // loop to the loop information. Loops that share the same loop
        // header are treated as one loop by merging these blocks.
        BitVector* loop_blocks = FindLoopBlocks(pred, block);
        if (block->loop_info() == nullptr) {
          intptr_t id = loop_headers->length();
          block->set_loop_info(new (zone()) LoopInfo(id, block, loop_blocks));
          loop_headers->Add(block);
        } else {
          ASSERT(block->loop_info()->header() == block);
          block->loop_info()->AddBlocks(loop_blocks);
        }
        block->loop_info()->AddBackEdge(pred);
      }
    }
  }

  // Build the loop hierarchy and link every entry block to
  // the closest enveloping loop in loop hierarchy.
  return new (zone()) LoopHierarchy(loop_headers, preorder_);
}

intptr_t FlowGraph::InstructionCount() const {
  intptr_t size = 0;
  // Iterate each block, skipping the graph entry.
  for (intptr_t i = 1; i < preorder_.length(); ++i) {
    BlockEntryInstr* block = preorder_[i];

    // Skip any blocks from the prologue to make them not count towards the
    // inlining instruction budget.
    const intptr_t block_id = block->block_id();
    if (prologue_info_.Contains(block_id)) {
      continue;
    }

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      ++size;
    }
  }
  return size;
}

void FlowGraph::ConvertUse(Value* use, Representation from_rep) {
  const Representation to_rep =
      use->instruction()->RequiredInputRepresentation(use->use_index());
  if (from_rep == to_rep || to_rep == kNoRepresentation) {
    return;
  }
  InsertConversion(from_rep, to_rep, use, /*is_environment_use=*/false);
}

static bool IsUnboxedInteger(Representation rep) {
  return (rep == kUnboxedInt32) || (rep == kUnboxedUint32) ||
         (rep == kUnboxedInt64);
}

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}

static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}

static bool CanConvertInt64ToDouble() {
  return FlowGraphCompiler::CanConvertInt64ToDouble();
}

void FlowGraph::InsertConversion(Representation from,
                                 Representation to,
                                 Value* use,
                                 bool is_environment_use) {
  Instruction* insert_before;
  Instruction* deopt_target;
  PhiInstr* phi = use->instruction()->AsPhi();
  if (phi != NULL) {
    ASSERT(phi->is_alive());
    // For phis conversions have to be inserted in the predecessor.
    auto predecessor = phi->block()->PredecessorAt(use->use_index());
    insert_before = predecessor->last_instruction();
    ASSERT(insert_before->GetBlock() == predecessor);
    deopt_target = NULL;
  } else {
    deopt_target = insert_before = use->instruction();
  }

  Definition* converted = NULL;
  if (IsUnboxedInteger(from) && IsUnboxedInteger(to)) {
    const intptr_t deopt_id = (to == kUnboxedInt32) && (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : DeoptId::kNone;
    converted =
        new (Z) IntConverterInstr(from, to, use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedInt32) && (to == kUnboxedDouble)) {
    converted = new Int32ToDoubleInstr(use->CopyWithType());
  } else if ((from == kUnboxedInt64) && (to == kUnboxedDouble) &&
             CanConvertInt64ToDouble()) {
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : DeoptId::kNone;
    ASSERT(CanUnboxDouble());
    converted = new Int64ToDoubleInstr(use->CopyWithType(), deopt_id);
  } else if ((from == kTagged) && Boxing::Supports(to)) {
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : DeoptId::kNone;
    converted = UnboxInstr::Create(
        to, use->CopyWithType(), deopt_id,
        use->instruction()->SpeculativeModeOfInput(use->use_index()));
  } else if ((to == kTagged) && Boxing::Supports(from)) {
    converted = BoxInstr::Create(from, use->CopyWithType());
  } else {
    // We have failed to find a suitable conversion instruction.
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    const intptr_t deopt_id = (deopt_target != NULL)
                                  ? deopt_target->DeoptimizationTarget()
                                  : DeoptId::kNone;
    ASSERT(Boxing::Supports(from));
    ASSERT(Boxing::Supports(to));
    Definition* boxed = BoxInstr::Create(from, use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, FlowGraph::kValue);
    converted = UnboxInstr::Create(to, new (Z) Value(boxed), deopt_id);
  }
  ASSERT(converted != NULL);
  InsertBefore(insert_before, converted, use->instruction()->env(),
               FlowGraph::kValue);
  if (is_environment_use) {
    use->BindToEnvironment(converted);
  } else {
    use->BindTo(converted);
  }

  if ((to == kUnboxedInt32) && (phi != NULL)) {
    // Int32 phis are unboxed optimistically. Ensure that unboxing
    // has deoptimization target attached from the goto instruction.
    CopyDeoptTarget(converted, insert_before);
  }
}

void FlowGraph::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    ConvertUse(it.Current(), from_rep);
  }
}

static void UnboxPhi(PhiInstr* phi) {
  Representation unboxed = phi->representation();

  switch (phi->Type()->ToCid()) {
    case kDoubleCid:
      if (CanUnboxDouble()) {
        unboxed = kUnboxedDouble;
      }
      break;
    case kFloat32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat32x4;
      }
      break;
    case kInt32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedInt32x4;
      }
      break;
    case kFloat64x2Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat64x2;
      }
      break;
  }

  // If all the inputs are unboxed, leave the Phi unboxed.
  if ((unboxed == kTagged) && phi->Type()->IsInt()) {
    bool should_unbox = true;
    Representation new_representation = kTagged;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->representation() != kUnboxedInt64 &&
          input->representation() != kUnboxedInt32 &&
          input->representation() != kUnboxedUint32 && !(input == phi)) {
        should_unbox = false;
        break;
      }

      if (new_representation == kTagged) {
        new_representation = input->representation();
      } else if (new_representation != input->representation()) {
        new_representation = kNoRepresentation;
      }
    }
    if (should_unbox) {
      unboxed = new_representation != kNoRepresentation
                    ? new_representation
                    : RangeUtils::Fits(phi->range(),
                                       RangeBoundary::kRangeBoundaryInt32)
                          ? kUnboxedInt32
                          : kUnboxedInt64;
    }
  }

  if ((unboxed == kTagged) && phi->Type()->IsInt()) {
    // Conservatively unbox phis that:
    //   - are proven to be of type Int;
    //   - fit into 64bits range;
    //   - have either constants or Box() operations as inputs;
    //   - have at least one Box() operation as an input;
    //   - are used in at least 1 Unbox() operation.
    bool should_unbox = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsBox()) {
        should_unbox = true;
      } else if (!input->IsConstant()) {
        should_unbox = false;
        break;
      }
    }

    if (should_unbox) {
      // We checked inputs. Check if phi is used in at least one unbox
      // operation.
      bool has_unboxed_use = false;
      for (Value* use = phi->input_use_list(); use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        if (instr->IsUnbox()) {
          has_unboxed_use = true;
          break;
        } else if (IsUnboxedInteger(
                       instr->RequiredInputRepresentation(use->use_index()))) {
          has_unboxed_use = true;
          break;
        }
      }

      if (!has_unboxed_use) {
        should_unbox = false;
      }
    }

    if (should_unbox) {
      unboxed =
          RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt32)
              ? kUnboxedInt32
              : kUnboxedInt64;
    }
  }

  phi->set_representation(unboxed);
}

void FlowGraph::SelectRepresentations() {
  // First we decide for each phi if it is beneficial to unbox it. If so, we
  // change it's `phi->representation()`
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    JoinEntryInstr* join_entry = block_it.Current()->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        UnboxPhi(phi);
      }
    }
  }

  // Process all initial definitions and insert conversions when needed (depends
  // on phi unboxing decision above).
  for (intptr_t i = 0; i < graph_entry()->initial_definitions()->length();
       i++) {
    InsertConversionsFor((*graph_entry()->initial_definitions())[i]);
  }
  for (intptr_t i = 0; i < graph_entry()->SuccessorCount(); ++i) {
    auto successor = graph_entry()->SuccessorAt(i);
    if (auto entry = successor->AsBlockEntryWithInitialDefs()) {
      auto& initial_definitions = *entry->initial_definitions();
      for (intptr_t j = 0; j < initial_definitions.length(); j++) {
        InsertConversionsFor(initial_definitions[j]);
      }
    }
  }

  // Process all normal definitions and insert conversions when needed (depends
  // on phi unboxing decision above).
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();
    if (JoinEntryInstr* join_entry = entry->AsJoinEntry()) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        ASSERT(phi->is_alive());
        InsertConversionsFor(phi);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* def = it.Current()->AsDefinition();
      if (def != NULL) {
        InsertConversionsFor(def);
      }
    }
  }
}

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
// Smi widening pass is only meaningful on platforms where Smi
// is smaller than 32bit. For now only support it on ARM and ia32.
static bool CanBeWidened(BinarySmiOpInstr* smi_op) {
  return BinaryInt32OpInstr::IsSupported(smi_op->op_kind(), smi_op->left(),
                                         smi_op->right());
}

static bool BenefitsFromWidening(BinarySmiOpInstr* smi_op) {
  // TODO(vegorov): when shifts with non-constants shift count are supported
  // add them here as we save untagging for the count.
  switch (smi_op->op_kind()) {
    case Token::kMUL:
    case Token::kSHR:
      // For kMUL we save untagging of the argument for kSHR
      // we save tagging of the result.
      return true;

    default:
      return false;
  }
}

// Maps an entry block to its closest enveloping loop id, or -1 if none.
static intptr_t LoopId(BlockEntryInstr* block) {
  LoopInfo* loop = block->loop_info();
  if (loop != nullptr) {
    return loop->id();
  }
  return -1;
}

void FlowGraph::WidenSmiToInt32() {
  if (!FLAG_use_smi_widening) {
    return;
  }

  GrowableArray<BinarySmiOpInstr*> candidates;

  // Step 1. Collect all instructions that potentially benefit from widening of
  // their operands (or their result) into int32 range.
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      BinarySmiOpInstr* smi_op = instr_it.Current()->AsBinarySmiOp();
      if ((smi_op != NULL) && smi_op->HasSSATemp() &&
          BenefitsFromWidening(smi_op) && CanBeWidened(smi_op)) {
        candidates.Add(smi_op);
      }
    }
  }

  if (candidates.is_empty()) {
    return;
  }

  // Step 2. For each block in the graph compute which loop it belongs to.
  // We will use this information later during computation of the widening's
  // gain: we are going to assume that only conversion occurring inside the
  // same loop should be counted against the gain, all other conversions
  // can be hoisted and thus cost nothing compared to the loop cost itself.
  GetLoopHierarchy();

  // Step 3. For each candidate transitively collect all other BinarySmiOpInstr
  // and PhiInstr that depend on it and that it depends on and count amount of
  // untagging operations that we save in assumption that this whole graph of
  // values is using kUnboxedInt32 representation instead of kTagged.
  // Convert those graphs that have positive gain to kUnboxedInt32.

  // BitVector containing SSA indexes of all processed definitions. Used to skip
  // those candidates that belong to dependency graph of another candidate.
  BitVector* processed = new (Z) BitVector(Z, current_ssa_temp_index());

  // Worklist used to collect dependency graph.
  DefinitionWorklist worklist(this, candidates.length());
  for (intptr_t i = 0; i < candidates.length(); i++) {
    BinarySmiOpInstr* op = candidates[i];
    if (op->WasEliminated() || processed->Contains(op->ssa_temp_index())) {
      continue;
    }

    if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
      THR_Print("analysing candidate: %s\n", op->ToCString());
    }
    worklist.Clear();
    worklist.Add(op);

    // Collect dependency graph. Note: more items are added to worklist
    // inside this loop.
    intptr_t gain = 0;
    for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
      Definition* defn = worklist.definitions()[j];

      if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
        THR_Print("> %s\n", defn->ToCString());
      }

      if (defn->IsBinarySmiOp() &&
          BenefitsFromWidening(defn->AsBinarySmiOp())) {
        gain++;
        if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
          THR_Print("^ [%" Pd "] (o) %s\n", gain, defn->ToCString());
        }
      }

      const intptr_t defn_loop = LoopId(defn->GetBlock());

      // Process all inputs.
      for (intptr_t k = 0; k < defn->InputCount(); k++) {
        Definition* input = defn->InputAt(k)->definition();
        if (input->IsBinarySmiOp() && CanBeWidened(input->AsBinarySmiOp())) {
          worklist.Add(input);
        } else if (input->IsPhi() && (input->Type()->ToCid() == kSmiCid)) {
          worklist.Add(input);
        } else if (input->IsBinaryInt64Op()) {
          // Mint operation produces untagged result. We avoid tagging.
          gain++;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("^ [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        } else if (defn_loop == LoopId(input->GetBlock()) &&
                   (input->Type()->ToCid() == kSmiCid)) {
          // Input comes from the same loop, is known to be smi and requires
          // untagging.
          // TODO(vegorov) this heuristic assumes that values that are not
          // known to be smi have to be checked and this check can be
          // coalesced with untagging. Start coalescing them.
          gain--;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("v [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        }
      }

      // Process all uses.
      for (Value* use = defn->input_use_list(); use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        Definition* use_defn = instr->AsDefinition();
        if (use_defn == NULL) {
          // We assume that tagging before returning or pushing argument costs
          // very little compared to the cost of the return/call itself.
          ASSERT(!instr->IsPushArgument());
          if (!instr->IsReturn() &&
              (use->use_index() >= instr->ArgumentCount())) {
            gain--;
            if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
              THR_Print("v [%" Pd "] (u) %s\n", gain,
                        use->instruction()->ToCString());
            }
          }
          continue;
        } else if (use_defn->IsBinarySmiOp() &&
                   CanBeWidened(use_defn->AsBinarySmiOp())) {
          worklist.Add(use_defn);
        } else if (use_defn->IsPhi() &&
                   use_defn->AsPhi()->Type()->ToCid() == kSmiCid) {
          worklist.Add(use_defn);
        } else if (use_defn->IsBinaryInt64Op()) {
          // BinaryInt64Op requires untagging of its inputs.
          // Converting kUnboxedInt32 to kUnboxedInt64 is essentially zero cost
          // sign extension operation.
          gain++;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("^ [%" Pd "] (u) %s\n", gain,
                      use->instruction()->ToCString());
          }
        } else if (defn_loop == LoopId(instr->GetBlock())) {
          gain--;
          if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
            THR_Print("v [%" Pd "] (u) %s\n", gain,
                      use->instruction()->ToCString());
          }
        }
      }
    }

    processed->AddAll(worklist.contains_vector());

    if (FLAG_support_il_printer && FLAG_trace_smi_widening) {
      THR_Print("~ %s gain %" Pd "\n", op->ToCString(), gain);
    }

    if (gain > 0) {
      // We have positive gain from widening. Convert all BinarySmiOpInstr into
      // BinaryInt32OpInstr and set representation of all phis to kUnboxedInt32.
      for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
        Definition* defn = worklist.definitions()[j];
        ASSERT(defn->IsPhi() || defn->IsBinarySmiOp());

        // Since we widen the integer representation we've to clear out type
        // propagation information (e.g. it might no longer be a _Smi).
        for (Value::Iterator it(defn->input_use_list()); !it.Done();
             it.Advance()) {
          it.Current()->SetReachingType(nullptr);
        }

        if (defn->IsBinarySmiOp()) {
          BinarySmiOpInstr* smi_op = defn->AsBinarySmiOp();
          BinaryInt32OpInstr* int32_op = new (Z) BinaryInt32OpInstr(
              smi_op->op_kind(), smi_op->left()->CopyWithType(),
              smi_op->right()->CopyWithType(), smi_op->DeoptimizationTarget());

          smi_op->ReplaceWith(int32_op, NULL);
        } else if (defn->IsPhi()) {
          defn->AsPhi()->set_representation(kUnboxedInt32);
          ASSERT(defn->Type()->IsInt());
        }
      }
    }
  }
}
#else
void FlowGraph::WidenSmiToInt32() {
  // TODO(vegorov) ideally on 64-bit platforms we would like to narrow smi
  // operations to 32-bit where it saves tagging and untagging and allows
  // to use shorted (and faster) instructions. But we currently don't
  // save enough range information in the ICData to drive this decision.
}
#endif

void FlowGraph::EliminateEnvironments() {
  // After this pass we can no longer perform LICM and hoist instructions
  // that can deoptimize.

  disallow_licm();
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (!block->IsCatchBlockEntry()) {
      block->RemoveEnvironment();
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (!current->ComputeCanDeoptimize() &&
          (!current->MayThrow() || !current->GetBlock()->InsideTryBlock())) {
        // Instructions that can throw need an environment for optimized
        // try-catch.
        // TODO(srdjan): --source-lines needs deopt environments to get at
        // the code for this instruction, however, leaving the environment
        // changes code.
        current->RemoveEnvironment();
      }
    }
  }
}

bool FlowGraph::Canonicalize() {
  bool changed = false;

  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* const block = block_it.Current();
    if (auto join = block->AsJoinEntry()) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* current = it.Current();
        if (current->HasUnmatchedInputRepresentations()) {
          // Can't canonicalize this instruction until all conversions for its
          // inputs are inserted.
          continue;
        }

        Definition* replacement = current->Canonicalize(this);
        ASSERT(replacement != nullptr);
        if (replacement != current) {
          current->ReplaceUsesWith(replacement);
          it.RemoveCurrentFromGraph();
          changed = true;
        }
      }
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (current->HasUnmatchedInputRepresentations()) {
        // Can't canonicalize this instruction until all conversions for its
        // inputs are inserted.
        continue;
      }

      Instruction* replacement = current->Canonicalize(this);

      if (replacement != current) {
        // For non-definitions Canonicalize should return either NULL or
        // this.
        ASSERT((replacement == NULL) || current->IsDefinition());
        ReplaceCurrentInstruction(&it, current, replacement);
        changed = true;
      }
    }
  }
  return changed;
}

void FlowGraph::PopulateWithICData(const Function& function) {
  Zone* zone = Thread::Current()->zone();

  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (!call->HasICData()) {
          const Array& arguments_descriptor =
              Array::Handle(zone, call->GetArgumentsDescriptor());
          const ICData& ic_data = ICData::ZoneHandle(
              zone,
              ICData::New(function, call->function_name(), arguments_descriptor,
                          call->deopt_id(), call->checked_argument_count(),
                          ICData::kInstance));
          call->set_ic_data(&ic_data);
        }
      } else if (instr->IsStaticCall()) {
        StaticCallInstr* call = instr->AsStaticCall();
        if (!call->HasICData()) {
          const Array& arguments_descriptor =
              Array::Handle(zone, call->GetArgumentsDescriptor());
          const Function& target = call->function();
          int num_args_checked =
              MethodRecognizer::NumArgsCheckedForStaticCall(target);
          const ICData& ic_data = ICData::ZoneHandle(
              zone, ICData::NewForStaticCall(
                        function, target, arguments_descriptor,
                        call->deopt_id(), num_args_checked, ICData::kStatic));
          call->set_ic_data(&ic_data);
        }
      }
    }
  }
}

// Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
// shift can be a truncating Smi shift-left and result is always Smi.
// Merging occurs only per basic-block.
void FlowGraph::TryOptimizePatterns() {
  if (!FLAG_truncating_left_shift) return;
  GrowableArray<BinarySmiOpInstr*> div_mod_merge;
  GrowableArray<InvokeMathCFunctionInstr*> sin_cos_merge;
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    // Merging only per basic-block.
    div_mod_merge.Clear();
    sin_cos_merge.Clear();
    ForwardInstructionIterator it(block_it.Current());
    for (; !it.Done(); it.Advance()) {
      if (it.Current()->IsBinarySmiOp()) {
        BinarySmiOpInstr* binop = it.Current()->AsBinarySmiOp();
        if (binop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(&it, binop, binop->left()->definition(),
                                       binop->right()->definition());
        } else if ((binop->op_kind() == Token::kTRUNCDIV) ||
                   (binop->op_kind() == Token::kMOD)) {
          if (binop->HasUses()) {
            div_mod_merge.Add(binop);
          }
        }
      } else if (it.Current()->IsBinaryInt64Op()) {
        BinaryInt64OpInstr* mintop = it.Current()->AsBinaryInt64Op();
        if (mintop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(&it, mintop,
                                       mintop->left()->definition(),
                                       mintop->right()->definition());
        }
      } else if (it.Current()->IsInvokeMathCFunction()) {
        InvokeMathCFunctionInstr* math_unary =
            it.Current()->AsInvokeMathCFunction();
        if ((math_unary->recognized_kind() == MethodRecognizer::kMathSin) ||
            (math_unary->recognized_kind() == MethodRecognizer::kMathCos)) {
          if (math_unary->HasUses()) {
            sin_cos_merge.Add(math_unary);
          }
        }
      }
    }
    TryMergeTruncDivMod(&div_mod_merge);
  }
}

// Returns true if use is dominated by the given instruction.
// Note: uses that occur at instruction itself are not dominated by it.
static bool IsDominatedUse(Instruction* dom, Value* use) {
  BlockEntryInstr* dom_block = dom->GetBlock();

  Instruction* instr = use->instruction();

  PhiInstr* phi = instr->AsPhi();
  if (phi != NULL) {
    return dom_block->Dominates(phi->block()->PredecessorAt(use->use_index()));
  }

  BlockEntryInstr* use_block = instr->GetBlock();
  if (use_block == dom_block) {
    // Fast path for the case of block entry.
    if (dom_block == dom) return true;

    for (Instruction* curr = dom->next(); curr != NULL; curr = curr->next()) {
      if (curr == instr) return true;
    }

    return false;
  }

  return dom_block->Dominates(use_block);
}

void FlowGraph::RenameDominatedUses(Definition* def,
                                    Instruction* dom,
                                    Definition* other) {
  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    if (IsDominatedUse(dom, use)) {
      use->BindTo(other);
    }
  }
}

void FlowGraph::RenameUsesDominatedByRedefinitions() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      Definition* definition = instr_it.Current()->AsDefinition();
      // CheckArrayBound instructions have their own mechanism for ensuring
      // proper dependencies, so we don't rewrite those here.
      if (definition != nullptr && !definition->IsCheckArrayBound()) {
        Value* redefined = definition->RedefinedValue();
        if (redefined != nullptr) {
          if (!definition->HasSSATemp()) {
            AllocateSSAIndexes(definition);
          }
          Definition* original = redefined->definition();
          RenameDominatedUses(original, definition, definition);
        }
      }
    }
  }
}

static bool IsPositiveOrZeroSmiConst(Definition* d) {
  ConstantInstr* const_instr = d->AsConstant();
  if ((const_instr != NULL) && (const_instr->value().IsSmi())) {
    return Smi::Cast(const_instr->value()).Value() >= 0;
  }
  return false;
}

static BinarySmiOpInstr* AsSmiShiftLeftInstruction(Definition* d) {
  BinarySmiOpInstr* instr = d->AsBinarySmiOp();
  if ((instr != NULL) && (instr->op_kind() == Token::kSHL)) {
    return instr;
  }
  return NULL;
}

void FlowGraph::OptimizeLeftShiftBitAndSmiOp(
    ForwardInstructionIterator* current_iterator,
    Definition* bit_and_instr,
    Definition* left_instr,
    Definition* right_instr) {
  ASSERT(bit_and_instr != NULL);
  ASSERT((left_instr != NULL) && (right_instr != NULL));

  // Check for pattern, smi_shift_left must be single-use.
  bool is_positive_or_zero = IsPositiveOrZeroSmiConst(left_instr);
  if (!is_positive_or_zero) {
    is_positive_or_zero = IsPositiveOrZeroSmiConst(right_instr);
  }
  if (!is_positive_or_zero) return;

  BinarySmiOpInstr* smi_shift_left = NULL;
  if (bit_and_instr->InputAt(0)->IsSingleUse()) {
    smi_shift_left = AsSmiShiftLeftInstruction(left_instr);
  }
  if ((smi_shift_left == NULL) && (bit_and_instr->InputAt(1)->IsSingleUse())) {
    smi_shift_left = AsSmiShiftLeftInstruction(right_instr);
  }
  if (smi_shift_left == NULL) return;

  // Pattern recognized.
  smi_shift_left->mark_truncating();
  ASSERT(bit_and_instr->IsBinarySmiOp() || bit_and_instr->IsBinaryInt64Op());
  if (bit_and_instr->IsBinaryInt64Op()) {
    // Replace Mint op with Smi op.
    BinarySmiOpInstr* smi_op = new (Z) BinarySmiOpInstr(
        Token::kBIT_AND, new (Z) Value(left_instr), new (Z) Value(right_instr),
        DeoptId::kNone);  // BIT_AND cannot deoptimize.
    bit_and_instr->ReplaceWith(smi_op, current_iterator);
  }
}

// Dart:
//  var x = d % 10;
//  var y = d ~/ 10;
//  var z = x + y;
//
// IL:
//  v4 <- %(v2, v3)
//  v5 <- ~/(v2, v3)
//  v6 <- +(v4, v5)
//
// IL optimized:
//  v4 <- DIVMOD(v2, v3);
//  v5 <- LoadIndexed(v4, 0); // ~/ result
//  v6 <- LoadIndexed(v4, 1); // % result
//  v7 <- +(v5, v6)
// Because of the environment it is important that merged instruction replaces
// first original instruction encountered.
void FlowGraph::TryMergeTruncDivMod(
    GrowableArray<BinarySmiOpInstr*>* merge_candidates) {
  if (merge_candidates->length() < 2) {
    // Need at least a TRUNCDIV and a MOD.
    return;
  }
  for (intptr_t i = 0; i < merge_candidates->length(); i++) {
    BinarySmiOpInstr* curr_instr = (*merge_candidates)[i];
    if (curr_instr == NULL) {
      // Instruction was merged already.
      continue;
    }
    ASSERT((curr_instr->op_kind() == Token::kTRUNCDIV) ||
           (curr_instr->op_kind() == Token::kMOD));
    // Check if there is kMOD/kTRUNDIV binop with same inputs.
    const Token::Kind other_kind = (curr_instr->op_kind() == Token::kTRUNCDIV)
                                       ? Token::kMOD
                                       : Token::kTRUNCDIV;
    Definition* left_def = curr_instr->left()->definition();
    Definition* right_def = curr_instr->right()->definition();
    for (intptr_t k = i + 1; k < merge_candidates->length(); k++) {
      BinarySmiOpInstr* other_binop = (*merge_candidates)[k];
      // 'other_binop' can be NULL if it was already merged.
      if ((other_binop != NULL) && (other_binop->op_kind() == other_kind) &&
          (other_binop->left()->definition() == left_def) &&
          (other_binop->right()->definition() == right_def)) {
        (*merge_candidates)[k] = NULL;  // Clear it.
        ASSERT(curr_instr->HasUses());
        AppendExtractNthOutputForMerged(
            curr_instr, TruncDivModInstr::OutputIndexOf(curr_instr->op_kind()),
            kTagged, kSmiCid);
        ASSERT(other_binop->HasUses());
        AppendExtractNthOutputForMerged(
            other_binop,
            TruncDivModInstr::OutputIndexOf(other_binop->op_kind()), kTagged,
            kSmiCid);

        // Replace with TruncDivMod.
        TruncDivModInstr* div_mod = new (Z) TruncDivModInstr(
            curr_instr->left()->CopyWithType(),
            curr_instr->right()->CopyWithType(), curr_instr->deopt_id());
        curr_instr->ReplaceWith(div_mod, NULL);
        other_binop->ReplaceUsesWith(div_mod);
        other_binop->RemoveFromGraph();
        // Only one merge possible. Because canonicalization happens later,
        // more candidates are possible.
        // TODO(srdjan): Allow merging of trunc-div/mod into truncDivMod.
        break;
      }
    }
  }
}

void FlowGraph::AppendExtractNthOutputForMerged(Definition* instr,
                                                intptr_t index,
                                                Representation rep,
                                                intptr_t cid) {
  ExtractNthOutputInstr* extract =
      new (Z) ExtractNthOutputInstr(new (Z) Value(instr), index, rep, cid);
  instr->ReplaceUsesWith(extract);
  InsertAfter(instr, extract, NULL, FlowGraph::kValue);
}

//
// Static helpers for the flow graph utilities.
//

static TargetEntryInstr* NewTarget(FlowGraph* graph, Instruction* inherit) {
  TargetEntryInstr* target = new (graph->zone())
      TargetEntryInstr(graph->allocate_block_id(),
                       inherit->GetBlock()->try_index(), DeoptId::kNone);
  target->InheritDeoptTarget(graph->zone(), inherit);
  return target;
}

static JoinEntryInstr* NewJoin(FlowGraph* graph, Instruction* inherit) {
  JoinEntryInstr* join = new (graph->zone())
      JoinEntryInstr(graph->allocate_block_id(),
                     inherit->GetBlock()->try_index(), DeoptId::kNone);
  join->InheritDeoptTarget(graph->zone(), inherit);
  return join;
}

static GotoInstr* NewGoto(FlowGraph* graph,
                          JoinEntryInstr* target,
                          Instruction* inherit) {
  GotoInstr* got = new (graph->zone()) GotoInstr(target, DeoptId::kNone);
  got->InheritDeoptTarget(graph->zone(), inherit);
  return got;
}

static BranchInstr* NewBranch(FlowGraph* graph,
                              ComparisonInstr* cmp,
                              Instruction* inherit) {
  BranchInstr* bra = new (graph->zone()) BranchInstr(cmp, DeoptId::kNone);
  bra->InheritDeoptTarget(graph->zone(), inherit);
  return bra;
}

//
// Flow graph utilities.
//

// Constructs new diamond decision at the given instruction.
//
//               ENTRY
//             instruction
//            if (compare)
//              /   \
//           B_TRUE B_FALSE
//              \   /
//               JOIN
//
JoinEntryInstr* FlowGraph::NewDiamond(Instruction* instruction,
                                      Instruction* inherit,
                                      ComparisonInstr* compare,
                                      TargetEntryInstr** b_true,
                                      TargetEntryInstr** b_false) {
  BlockEntryInstr* entry = instruction->GetBlock();

  TargetEntryInstr* bt = NewTarget(this, inherit);
  TargetEntryInstr* bf = NewTarget(this, inherit);
  JoinEntryInstr* join = NewJoin(this, inherit);
  GotoInstr* gotot = NewGoto(this, join, inherit);
  GotoInstr* gotof = NewGoto(this, join, inherit);
  BranchInstr* bra = NewBranch(this, compare, inherit);

  instruction->AppendInstruction(bra);
  entry->set_last_instruction(bra);

  *bra->true_successor_address() = bt;
  *bra->false_successor_address() = bf;

  bt->AppendInstruction(gotot);
  bt->set_last_instruction(gotot);

  bf->AppendInstruction(gotof);
  bf->set_last_instruction(gotof);

  // Update dominance relation incrementally.
  for (intptr_t i = 0, n = entry->dominated_blocks().length(); i < n; ++i) {
    join->AddDominatedBlock(entry->dominated_blocks()[i]);
  }
  entry->ClearDominatedBlocks();
  entry->AddDominatedBlock(bt);
  entry->AddDominatedBlock(bf);
  entry->AddDominatedBlock(join);

  // TODO(ajcbik): update pred/succ/ordering incrementally too.

  // Return new blocks.
  *b_true = bt;
  *b_false = bf;
  return join;
}

JoinEntryInstr* FlowGraph::NewDiamond(Instruction* instruction,
                                      Instruction* inherit,
                                      const LogicalAnd& condition,
                                      TargetEntryInstr** b_true,
                                      TargetEntryInstr** b_false) {
  // First diamond for first comparison.
  TargetEntryInstr* bt = nullptr;
  TargetEntryInstr* bf = nullptr;
  JoinEntryInstr* mid_point =
      NewDiamond(instruction, inherit, condition.oper1, &bt, &bf);

  // Short-circuit second comparison and connect through phi.
  condition.oper2->InsertAfter(bt);
  AllocateSSAIndexes(condition.oper2);
  condition.oper2->InheritDeoptTarget(zone(), inherit);  // must inherit
  PhiInstr* phi =
      AddPhi(mid_point, condition.oper2, GetConstant(Bool::False()));
  StrictCompareInstr* circuit = new (zone()) StrictCompareInstr(
      inherit->source(), Token::kEQ_STRICT, new (zone()) Value(phi),
      new (zone()) Value(GetConstant(Bool::True())), false,
      DeoptId::kNone);  // don't inherit

  // Return new blocks through the second diamond.
  return NewDiamond(mid_point, inherit, circuit, b_true, b_false);
}

PhiInstr* FlowGraph::AddPhi(JoinEntryInstr* join,
                            Definition* d1,
                            Definition* d2) {
  PhiInstr* phi = new (zone()) PhiInstr(join, 2);
  Value* v1 = new (zone()) Value(d1);
  Value* v2 = new (zone()) Value(d2);

  AllocateSSAIndexes(phi);

  phi->mark_alive();
  phi->SetInputAt(0, v1);
  phi->SetInputAt(1, v2);
  d1->AddInputUse(v1);
  d2->AddInputUse(v2);
  join->InsertPhi(phi);

  return phi;
}

void FlowGraph::InsertPushArguments() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    thread()->CheckForSafepoint();
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done(); instr_it.Advance()) {
      Instruction* instruction = instr_it.Current();
      const intptr_t arg_count = instruction->ArgumentCount();
      if (arg_count == 0) {
        continue;
      }
      PushArgumentsArray* arguments =
          new (Z) PushArgumentsArray(zone(), arg_count);
      for (intptr_t i = 0; i < arg_count; ++i) {
        Value* arg = instruction->ArgumentValueAt(i);
        PushArgumentInstr* push_arg = new (Z) PushArgumentInstr(
            arg->CopyWithType(Z), instruction->RequiredInputRepresentation(i));
        arguments->Add(push_arg);
        // Insert all PushArgument instructions immediately before call.
        // PushArgumentInstr::EmitNativeCode may generate more efficient
        // code for subsequent PushArgument instructions (ARM, ARM64).
        InsertBefore(instruction, push_arg, /*env=*/nullptr, kEffect);
      }
      instruction->ReplaceInputsWithPushArguments(arguments);
      if (instruction->env() != nullptr) {
        instruction->RepairPushArgsInEnvironment();
      }
    }
  }
}

}  // namespace dart
