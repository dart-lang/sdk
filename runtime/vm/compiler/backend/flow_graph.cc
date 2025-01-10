// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph.h"

#include <array>

#include "vm/bit_vector.h"
#include "vm/compiler/backend/dart_calling_conventions.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/compiler_timings.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"
#include "vm/resolver.h"

namespace dart {

DEFINE_FLAG(bool, prune_dead_locals, true, "optimize dead locals away");

// Quick access to the current zone.
#define Z (zone())

static bool ShouldReorderBlocks(const Function& function,
                                FlowGraph::CompilationMode mode) {
  return (mode == FlowGraph::CompilationMode::kOptimized) &&
         FLAG_reorder_basic_blocks && !function.IsFfiCallbackTrampoline();
}

static bool ShouldOmitCheckBoundsIn(const Function& function) {
  auto& state = CompilerState::Current();
  return state.is_aot() && state.PragmasOf(function).unsafe_no_bounds_checks;
}

FlowGraph::FlowGraph(const ParsedFunction& parsed_function,
                     GraphEntryInstr* graph_entry,
                     intptr_t max_block_id,
                     PrologueInfo prologue_info,
                     CompilationMode compilation_mode)
    : thread_(Thread::Current()),
      parent_(),
      current_ssa_temp_index_(0),
      max_block_id_(max_block_id),
      parsed_function_(parsed_function),
      num_direct_parameters_(parsed_function.function().MakesCopyOfParameters()
                                 ? 0
                                 : parsed_function.function().NumParameters()),
      direct_parameter_locations_(
          parsed_function.function().num_fixed_parameters()),
      graph_entry_(graph_entry),
      preorder_(),
      postorder_(),
      reverse_postorder_(),
      optimized_block_order_(),
      constant_null_(nullptr),
      constant_dead_(nullptr),
      licm_allowed_(true),
      should_reorder_blocks_(
          ShouldReorderBlocks(parsed_function.function(), compilation_mode)),
      prologue_info_(prologue_info),
      loop_hierarchy_(nullptr),
      loop_invariant_loads_(nullptr),
      inlining_id_(-1),
      inlining_info_(&parsed_function.function()),
      should_print_(false),
      should_omit_check_bounds_(
          dart::ShouldOmitCheckBoundsIn(parsed_function.function())) {
  should_print_ = FlowGraphPrinter::ShouldPrint(parsed_function.function(),
                                                &compiler_pass_filters_);
  ComputeLocationsOfFixedParameters(
      zone(), function(),
      /*should_assign_stack_locations=*/
      !parsed_function.function().MakesCopyOfParameters(),
      &direct_parameter_locations_);
  DiscoverBlocks();
}

void FlowGraph::EnsureSSATempIndex(Definition* defn, Definition* replacement) {
  if ((replacement->ssa_temp_index() == -1) && (defn->ssa_temp_index() != -1)) {
    AllocateSSAIndex(replacement);
  }
}

intptr_t FlowGraph::ComputeArgumentsSizeInWords(const Function& function,
                                                intptr_t argument_count) {
  ASSERT(function.num_fixed_parameters() <= argument_count);
  ASSERT(argument_count <= function.NumParameters());

  const intptr_t fixed_parameters_size_in_bytes =
      ComputeLocationsOfFixedParameters(Thread::Current()->zone(), function);

  // Currently we box all optional parameters.
  return fixed_parameters_size_in_bytes +
         (argument_count - function.num_fixed_parameters());
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
  } else if (function.has_unboxed_record_return()) {
    return kPairOfTagged;
  } else {
    ASSERT(!function.has_unboxed_return());
    return kTagged;
  }
}

void FlowGraph::ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                          Instruction* current,
                                          Instruction* replacement) {
  Definition* current_defn = current->AsDefinition();
  if ((replacement != nullptr) && (current_defn != nullptr)) {
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != nullptr);
    current_defn->ReplaceUsesWith(replacement_defn);
    EnsureSSATempIndex(current_defn, replacement_defn);

    if (FLAG_trace_optimization && should_print()) {
      THR_Print("Replacing v%" Pd " with v%" Pd "\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization && should_print()) {
    if (current_defn == nullptr) {
      THR_Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      THR_Print("Removing v%" Pd ".\n", current_defn->ssa_temp_index());
    }
  }
  if (current->ArgumentCount() != 0) {
    ASSERT(!current->HasMoveArguments());
  }
  iterator->RemoveCurrentFromGraph();
}

GrowableArray<BlockEntryInstr*>* FlowGraph::CodegenBlockOrder() {
  return should_reorder_blocks() ? &optimized_block_order_
                                 : &reverse_postorder_;
}

const GrowableArray<BlockEntryInstr*>* FlowGraph::CodegenBlockOrder() const {
  return should_reorder_blocks() ? &optimized_block_order_
                                 : &reverse_postorder_;
}

ConstantInstr* FlowGraph::GetExistingConstant(
    const Object& object,
    Representation representation) const {
  return constant_instr_pool_.LookupValue(
      ConstantAndRepresentation{object, representation});
}

ConstantInstr* FlowGraph::GetConstant(const Object& object,
                                      Representation representation) {
  ConstantInstr* constant = GetExistingConstant(object, representation);
  if (constant == nullptr) {
    // Otherwise, allocate and add it to the pool.
    const Object& zone_object = Object::ZoneHandle(zone(), object.ptr());
    if (representation == kTagged) {
      constant = new (zone()) ConstantInstr(zone_object);
    } else {
      constant = new (zone()) UnboxedConstantInstr(zone_object, representation);
    }
    AllocateSSAIndex(constant);
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
        return Utils::IsInt(32, Integer::Cast(value).Value());
      }
      return false;

    case kUnboxedUint32:
      if (value.IsInteger()) {
        return Utils::IsUint(32, Integer::Cast(value).Value());
      }
      return false;

    case kUnboxedInt64:
      return value.IsInteger();

    case kUnboxedFloat:
    case kUnboxedDouble:
      return value.IsInteger() || value.IsDouble();

    default:
      return false;
  }
}

Definition* FlowGraph::TryCreateConstantReplacementFor(Definition* op,
                                                       const Object& value) {
  // Check that representation of the constant matches expected representation.
  const auto representation = op->representation();
  if (!IsConstantRepresentable(
          value, representation,
          /*tagged_value_must_be_smi=*/op->Type()->IsNullableSmi())) {
    return op;
  }

  if (((representation == kUnboxedFloat) ||
       (representation == kUnboxedDouble)) &&
      value.IsInteger()) {
    // Convert the boxed constant from int to float/double.
    return GetConstant(
        Double::Handle(Double::NewCanonical(Integer::Cast(value).ToDouble())),
        representation);
  }

  return GetConstant(value, representation);
}

void FlowGraph::AddToGraphInitialDefinitions(Definition* defn) {
  defn->set_previous(graph_entry_);
  graph_entry_->initial_definitions()->Add(defn);
}

void FlowGraph::AddToInitialDefinitions(BlockEntryWithInitialDefs* entry,
                                        Definition* defn) {
  ASSERT(defn->previous() == nullptr);
  defn->set_previous(entry);
  if (auto par = defn->AsParameter()) {
    par->set_block(entry);  // set cached block
  }
  entry->initial_definitions()->Add(defn);
}

void FlowGraph::InsertAfter(Instruction* prev,
                            Instruction* instr,
                            Environment* env,
                            UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndex(instr->AsDefinition());
  }
  instr->InsertAfter(prev);
  ASSERT(instr->env() == nullptr);
  if (env != nullptr) {
    env->DeepCopyTo(zone(), instr);
  }
}

void FlowGraph::InsertSpeculativeAfter(Instruction* prev,
                                       Instruction* instr,
                                       Environment* env,
                                       UseKind use_kind) {
  InsertAfter(prev, instr, env, use_kind);
  if (instr->env() != nullptr) {
    instr->env()->MarkAsLazyDeoptToBeforeDeoptId();
  }
}

Instruction* FlowGraph::AppendTo(Instruction* prev,
                                 Instruction* instr,
                                 Environment* env,
                                 UseKind use_kind) {
  if (use_kind == kValue) {
    ASSERT(instr->IsDefinition());
    AllocateSSAIndex(instr->AsDefinition());
  }
  ASSERT(instr->env() == nullptr);
  if (env != nullptr) {
    env->DeepCopyTo(zone(), instr);
  }
  return prev->AppendInstruction(instr);
}
Instruction* FlowGraph::AppendSpeculativeTo(Instruction* prev,
                                            Instruction* instr,
                                            Environment* env,
                                            UseKind use_kind) {
  auto result = AppendTo(prev, instr, env, use_kind);
  if (instr->env() != nullptr) {
    instr->env()->MarkAsLazyDeoptToBeforeDeoptId();
  }
  return result;
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
  COMPILER_TIMINGS_TIMER_SCOPE(thread(), DiscoverBlocks);

  StackZone zone(thread());

  // Initialize state.
  preorder_.Clear();
  postorder_.Clear();
  reverse_postorder_.Clear();
  parent_.Clear();
  try_entries_.Clear();
  max_try_index_ = -1;

  GrowableArray<BlockTraversalState> block_stack;
  graph_entry_->DiscoverBlock(nullptr, &preorder_, &parent_);
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
    auto block = postorder_[block_count - i - 1];
    reverse_postorder_.Add(block);

    if (auto try_entry = block->AsTryEntry()) {
      const intptr_t index = try_entry->try_index();
      // Try-entries are not coming in ascending order.
      // There might be gaps in try_index after optimizations
      try_entries_.EnsureLength(index + 1, nullptr);
      ASSERT(try_entries_[index] == nullptr);
      try_entries_[index] = try_entry;
    }
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
      if (successor->IsTryEntry()) break;
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
      if (FLAG_trace_optimization && should_print()) {
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
    if (def->IsParameter() && (def->AsParameter()->env_index() == 0)) continue;
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
      if ((use != nullptr) && (use->is_receiver() == PhiInstr::kReceiver)) {
        use->set_is_receiver(PhiInstr::kNotReceiver);
        unmark.Add(use);
      }
    }
  }
}

bool FlowGraph::IsReceiver(Definition* def) const {
  def = def->OriginalDefinition();  // Could be redefined.
  if (def->IsParameter()) return (def->AsParameter()->env_index() == 0);
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
    UntaggedFunction::Kind kind) const {
  if (!FLAG_use_cha_deopt && !isolate_group()->all_classes_finalized()) {
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
    const intptr_t receiver_cid = type->ToNullableCid();
    if (receiver_cid != kDynamicCid) {
      receiver_class = isolate_group()->class_table()->At(receiver_cid);
      receiver_maybe_null = type->is_nullable();
    } else {
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
  }

  // Useful receiver class information?
  if (receiver_class.IsNull() ||
      receiver_class.has_dynamically_extendable_subtypes()) {
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
      (kind == UntaggedFunction::kMethodExtractor)
          ? String::Handle(zone(), Field::NameFromGetter(call->function_name()))
          : call->function_name();

  // If the receiver can have the null value, exclude any method
  // that is actually valid on a null receiver.
  if (receiver_maybe_null) {
    const Class& null_class =
        Class::Handle(zone(), isolate_group()->object_store()->null_class());
    Function& target = Function::Handle(zone());
    if (null_class.EnsureIsFinalized(thread()) == Error::null()) {
      target = Resolver::ResolveDynamicAnyArgs(zone(), null_class, method_name,
                                               /*allow_add=*/true);
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
      cha.AddToGuardedClassesForSubclassCount(receiver_class, subclass_count);
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

bool FlowGraph::ShouldOmitCheckBoundsIn(const Function& caller) {
  if (caller.ptr() == function().ptr()) {
    return should_omit_check_bounds();
  }

  return dart::ShouldOmitCheckBoundsIn(caller);
}

static Definition* CreateCheckBound(Zone* zone,
                                    Definition* length,
                                    Definition* index,
                                    intptr_t deopt_id,
                                    bool omit_check) {
  Value* val1 = new (zone) Value(length);
  Value* val2 = new (zone) Value(index);
  if (CompilerState::Current().is_aot()) {
    return new (zone) GenericCheckBoundInstr(
        val1, val2, deopt_id,
        omit_check ? GenericCheckBoundInstr::Mode::kPhantom
                   : GenericCheckBoundInstr::Mode::kReal);
  }
  return new (zone) CheckArrayBoundInstr(val1, val2, deopt_id);
}

Instruction* FlowGraph::AppendCheckBound(Instruction* cursor,
                                         Definition* length,
                                         Definition** index,
                                         intptr_t deopt_id,
                                         Environment* env) {
  *index = CreateCheckBound(zone(), length, *index, deopt_id,
                            ShouldOmitCheckBoundsIn(env->function()));
  cursor = AppendTo(cursor, *index, env, FlowGraph::kValue);
  return cursor;
}

void FlowGraph::AddExactnessGuard(InstanceCallInstr* call,
                                  intptr_t receiver_cid) {
  const Class& cls =
      Class::Handle(zone(), isolate_group()->class_table()->At(receiver_cid));

  Definition* load_type_args = new (zone()) LoadFieldInstr(
      call->Receiver()->CopyWithType(),
      Slot::GetTypeArgumentsSlotFor(thread(), cls), call->source());
  InsertBefore(call, load_type_args, call->env(), FlowGraph::kValue);

  const AbstractType& type =
      AbstractType::Handle(zone(), call->ic_data()->receivers_static_type());
  ASSERT(!type.IsNull());
  const TypeArguments& args = TypeArguments::Handle(
      zone(), Type::Cast(type).GetInstanceTypeArguments(thread()));
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
      if (redefinition != nullptr) {
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
  ASSERT(last != nullptr);
  for (intptr_t i = 0; i < last->SuccessorCount(); i++) {
    BlockEntryInstr* succ = last->SuccessorAt(i);
    ASSERT(succ != nullptr);
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

    BitVector* temp = new (zone()) BitVector(zone(), variable_count_);
    const intptr_t block_count = flow_graph_->preorder().length();
    for (intptr_t i = 0; i < block_count; i++) {
      BlockEntryInstr* block = flow_graph_->preorder()[i];
      BitVector* kill = GetKillSet(block);
      BitVector* live_assignments = GetLiveOutSet(block);
      if (block->InsideTryBlock()) {
        // For blocks inside try we also need to consider variables
        // which are live in for the corresponding catch block due
        // to an implicit edge.
        temp->CopyFrom(live_assignments);
        auto catch_block =
            flow_graph_->GetCatchBlockByTryIndex(block->try_index());
        temp->AddAll(GetLiveInSet(catch_block));
        live_assignments = temp;
      }

      if (auto block_with_initial_defs = block->AsBlockEntryWithInitialDefs()) {
        for (auto initial_def :
             *block_with_initial_defs->initial_definitions()) {
          if (auto initial_def_param = initial_def->AsParameter()) {
            kill->Add(initial_def_param->env_index());
          }
        }
      }

      kill->Intersect(live_assignments);
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
  virtual bool UpdateLiveOut(const BlockEntryInstr& block);
  virtual bool UpdateLiveIn(const BlockEntryInstr& block);

  const FlowGraph* flow_graph_;
  GrowableArray<BitVector*> assigned_vars_;
};

void VariableLivenessAnalysis::ComputeInitialSets() {
  const intptr_t block_count = postorder_.length();

  BitVector* last_loads = new (zone()) BitVector(zone(), variable_count_);
  for (intptr_t i = 0; i < block_count; i++) {
    BlockEntryInstr* block = postorder_[i];
    const bool inside_try = block->InsideTryBlock();

    BitVector* kill = kill_[i];
    BitVector* live_in = live_in_[i];
    last_loads->Clear();

    // Iterate backwards starting at the last instruction.
    for (BackwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      LoadLocalInstr* load = current->AsLoadLocal();
      if (load != nullptr) {
        const intptr_t index = flow_graph_->EnvIndex(&load->local());
        if (index >= live_in->length()) continue;  // Skip tmp_locals.
        live_in->Add(index);
        if (!inside_try && !last_loads->Contains(index)) {
          last_loads->Add(index);
          load->mark_last();
        }
        continue;
      }

      StoreLocalInstr* store = current->AsStoreLocal();
      if (store != nullptr) {
        const intptr_t index = flow_graph_->EnvIndex(&store->local());
        if (index >= live_in->length()) continue;  // Skip tmp_locals.

        if (kill->Contains(index)) {
          if (!live_in->Contains(index)) {
            // Not marking dead if it potentially flows into catch block.
            if (!inside_try) {
              store->mark_dead();
            }
          }
        } else {
          if (!live_in->Contains(index)) {
            // Not marking stores as last in try-blocks so that they
            // won't be eliminated based on live-in/live-out information
            // for try blocks and catch blocks.
            if (!inside_try) {
              store->mark_last();
            }
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
    if (is_function_entry || is_osr_entry) {
      const intptr_t parameter_count =
          is_osr_entry ? flow_graph_->variable_count()
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

bool VariableLivenessAnalysis::UpdateLiveIn(const BlockEntryInstr& block) {
  bool changed = LivenessAnalysis::UpdateLiveIn(block);
  if (block.InsideTryBlock()) {
    BitVector* live_in = live_in_[block.postorder_number()];
    CatchBlockEntryInstr* catch_block =
        flow_graph_->GetCatchBlockByTryIndex(block.try_index());
    auto catch_live_in = live_in_[catch_block->postorder_number()];
    if (live_in->AddAll(catch_live_in)) {
      changed = true;
    }
  }
  return changed;
}

bool VariableLivenessAnalysis::UpdateLiveOut(const BlockEntryInstr& block) {
  return LivenessAnalysis::UpdateLiveOut(block) || block.InsideTryBlock();
}

void FlowGraph::ComputeSSA(
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  GrowableArray<BitVector*> dominance_frontier;
  GrowableArray<intptr_t> idom;

#ifdef DEBUG
  if (inlining_parameters != nullptr) {
    for (intptr_t i = 0, n = inlining_parameters->length(); i < n; ++i) {
      Definition* defn = (*inlining_parameters)[i];
      if (defn->IsConstant()) {
        ASSERT(defn->previous() == graph_entry_);
        ASSERT(defn->HasSSATemp());
        ASSERT(defn->ssa_temp_index() < current_ssa_temp_index());
      } else {
        ASSERT(defn->previous() == nullptr);
        ASSERT(!defn->HasSSATemp());
      }
    }
  } else {
    ASSERT(current_ssa_temp_index() == 0);
  }
#endif

  ComputeDominators(&dominance_frontier);

  VariableLivenessAnalysis variable_liveness(this);
  variable_liveness.Analyze();

  GrowableArray<PhiInstr*> live_phis;

  InsertCatchBlockParams(preorder_, variable_liveness);
  // Inserted catch block parameters add to the set of assigned variables.
  InsertPhis(preorder_, variable_liveness, dominance_frontier, &live_phis);

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
  // https://renatowerneck.files.wordpress.com/2016/06/gtw06-dominators.pdf

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
      ASSERT(pred != nullptr);

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
                           VariableLivenessAnalysis& variable_liveness,
                           const GrowableArray<BitVector*>& dom_frontier,
                           GrowableArray<PhiInstr*>* live_phis) {
  const auto& assigned_vars = variable_liveness.ComputeAssignedVars();

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
        !FLAG_prune_dead_locals || IsImmortalVariable(var_index);
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
          if (!always_live && !variable_liveness.GetLiveInSet(preorder[index])
                                   ->Contains(var_index)) {
            // Avoid inserting Phis for variables which are not
            // live into the join block. Such Phis instructions can not
            // have real uses: they correspond to dead variables which can
            // be pruned from the environment (e.g. by RenameRecursive).
            continue;
          }
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

static Location EnvIndexToStackLocation(intptr_t num_direct_parameters,
                                        intptr_t env_index) {
  return Location::StackSlot(
      compiler::target::frame_layout.FrameSlotForVariableIndex(
          num_direct_parameters - env_index),
      FPREG);
}

void FlowGraph::AddCatchEntryParameter(intptr_t var_index,
                                       CatchBlockEntryInstr* catch_entry) {
  Location loc;
  Representation param_rep = kTagged;
  const intptr_t raw_exception_var_envindex =
      catch_entry->raw_exception_var() != nullptr
          ? EnvIndex(catch_entry->raw_exception_var())
          : -1;
  const intptr_t raw_stacktrace_var_envindex =
      catch_entry->raw_stacktrace_var() != nullptr
          ? EnvIndex(catch_entry->raw_stacktrace_var())
          : -1;

  if (raw_exception_var_envindex == var_index) {
    loc = LocationExceptionLocation();
  } else if (raw_stacktrace_var_envindex == var_index) {
    loc = LocationStackTraceLocation();
  } else {
    // Catch params will get their own stack slots separate
    // from parameters and spill slots.
    // All catch entries are reusing same stack slots.
    loc = EnvIndexToStackLocation(
        num_direct_parameters(),
        variable_count() + catch_entry->initial_definitions()->length());
  }
  auto param = new (Z) ParameterInstr(
      catch_entry, /*env_index=*/var_index,
      /*param_index=*/ParameterInstr::kNotFunctionParameter, loc, param_rep);
  AddToInitialDefinitions(catch_entry, param);
}

void FlowGraph::InsertCatchBlockParams(
    const GrowableArray<BlockEntryInstr*>& preorder,
    VariableLivenessAnalysis& variable_liveness) {
  // Parameters at CatchBlockEntry serve the same function as Phis at Joins.
  //
  // They represent a merge between versions of a variable which arrive on
  // different control flow edges. For Joins these are explicit control flow
  // edges between blocks, for CatchBlockEntry these are implicit edges
  // from throwing instructions covered by this catch block.
  // Consider two blocks A and B. If the block A has an assignment into a
  // variable V and there is a path from A to B: B0 = A, B1, B2, ..., Bn = B
  // such that B{i+1} is a successor of B{i} and B{i} does not dominate B{i+1}
  // then B needs a Phi function or Parameter corresponding
  // to the variable V. (for the purposes of shortening the definition we
  // consider catch entry to be an immediate successor of a block
  // that it covers).
  //
  // Now let us consider two distinct cases:
  // 1) normal flow graph for a function
  // 2) OSR relinked flow graph.
  //
  // In the first case we have the property that if a path B0, ..., Bn ends up
  // in the CatchEntry and none of Bi is CatchEntry then this path either fully
  // contained within the corresponding try block or crosses into the try
  // block via TryEntry. This property means that if a block A contains an
  // assignment to a variable V then this assignment can only induce
  // a Parameter instruction in the surrounding catches (if any).
  //
  // This property does hold for the OSR relinked graph because all TryEntry
  // blocks are lifted up to the graph entry. That means there can exist paths
  // from a block with an assignment to a variable which itself is not
  // covered by a try/catch to the catch block which do not cross through
  // the try entry. This means when inserting Parameter instructions for OSR
  // relinked graph we can't limit insertion using a list of variables assigned
  // inside blocks covered by catch and instead we should insert parameters for
  // all live variables.
  //
  // Note: if we computed dominance frontier treating catch block entries as
  // successors to blocks they cover then we could combine Parameter and Phi
  // insertion into a single pass algorithm and remove distinction between
  // OSR and non-OSR case.
  intptr_t fixed_slot_count = Utils::Maximum(
      graph_entry_->fixed_slot_count(),
      (IsCompiledForOsr() ? osr_variable_count() : variable_count()) -
          num_direct_parameters());
  if (IsCompiledForOsr()) {
    for (auto try_entry : try_entries_) {
      if (try_entry == nullptr) {
        continue;
      }
      auto catch_entry = try_entry->catch_target();
      const auto exception_var_index =
          EnvIndex(catch_entry->raw_exception_var());
      const auto stacktrace_var_index =
          EnvIndex(catch_entry->raw_stacktrace_var());
      for (intptr_t var_index = 0, n = variable_count(); var_index < n;
           ++var_index) {
        const bool always_live = !FLAG_prune_dead_locals ||
                                 IsImmortalVariable(var_index) ||
                                 var_index == exception_var_index ||
                                 var_index == stacktrace_var_index;

        if (!always_live &&
            !variable_liveness.GetLiveInSet(catch_entry)->Contains(var_index)) {
          // Avoid inserting Parameter for variables which are not
          // live into the catch block. Such Parameter instructions can not
          // have real uses: they correspond to dead variables which can
          // be pruned from the environment (e.g. by RenameRecursive).
          continue;
        }
        AddCatchEntryParameter(var_index, catch_entry);
      }
    }
  } else {
    const auto& assigned_vars = variable_liveness.ComputeAssignedVars();

    const intptr_t block_count = preorder.length();
    // Map preorder block number to the highest variable index that has an
    // assignment in that block.  Use it to avoid inserting multiple parameters
    // for the same variable.
    GrowableArray<intptr_t> has_already(block_count);
    // Map preorder block number to the highest variable index for which the
    // block went on the worklist.  Use it to avoid adding the same block to
    // the worklist more than once for the same variable.
    GrowableArray<intptr_t> work(block_count);

    // Initialize has_already and work.
    has_already.EnsureLength(block_count, -1);
    work.EnsureLength(block_count, -1);

    for (auto try_entry : try_entries_) {
      if (try_entry == nullptr) {
        continue;
      }
      auto catch_block = try_entry->catch_target();

      AddCatchEntryParameter(EnvIndex(catch_block->raw_exception_var()),
                             catch_block);
      AddCatchEntryParameter(EnvIndex(catch_block->raw_stacktrace_var()),
                             catch_block);
    }

    if (try_entries_.length() == 0) {
      return;
    }

    GrowableArray<BlockEntryInstr*> worklist;
    // Look at every variable in turn.
    for (intptr_t var_index = 0; var_index < variable_count(); ++var_index) {
      const bool always_live =
          !FLAG_prune_dead_locals || IsImmortalVariable(var_index);

      // Add to the worklist each block containing an assignment to this
      // variable.
      for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
        if (assigned_vars[block_index]->Contains(var_index)) {
          work[block_index] = var_index;
          worklist.Add(preorder[block_index]);
        }
      }

      while (!worklist.is_empty()) {
        BlockEntryInstr* current = worklist.RemoveLast();
        if (current->InsideTryBlock()) {
          intptr_t try_index = current->try_index();
          CatchBlockEntryInstr* catch_entry =
              GetCatchBlockByTryIndex(try_index);
          intptr_t catch_entry_index = catch_entry->preorder_number();
          if (has_already[catch_entry_index] < var_index) {
            if (!always_live && !variable_liveness.GetLiveInSet(catch_entry)
                                     ->Contains(var_index)) {
              // Avoid inserting Parameter for variables which are not
              // live into the catch block. Such Parameter instructions can not
              // have real uses: they correspond to dead variables which can
              // be pruned from the environment (e.g. by RenameRecursive).
              continue;
            }
            AddCatchEntryParameter(var_index, catch_entry);
            has_already[catch_entry_index] = var_index;
            if (work[catch_entry_index] < var_index) {
              work[catch_entry_index] = var_index;
              worklist.Add(catch_entry);
            }
          }
        }
      }
    }
  }

  // Count how many catch parameter slots are needed across the whole program.
  int catch_entries_slots = 0;
  for (intptr_t i = 0; i < try_entries_.length(); i++) {
    if (try_entries_[i] == nullptr) {
      continue;
    }
    CatchBlockEntryInstr* catch_entry = try_entries_[i]->catch_target();
    if (catch_entry->initial_definitions()->length() > catch_entries_slots) {
      catch_entries_slots = catch_entry->initial_definitions()->length();
    }
  }
  graph_entry_->set_fixed_slot_count(fixed_slot_count + catch_entries_slots);
}

void FlowGraph::CreateCommonConstants() {
  constant_null_ = GetConstant(Object::ZoneHandle());
  constant_dead_ = GetConstant(Object::optimized_out());
}

void FlowGraph::AddSyntheticPhis(BlockEntryInstr* block) {
  ASSERT(IsCompiledForOsr());
  if (auto join = block->AsJoinEntry()) {
    const intptr_t local_phi_count = variable_count() + join->stack_depth();
    // Never insert more phi's than that we had osr variables.
    const intptr_t osr_phi_count =
        Utils::Minimum(local_phi_count, osr_variable_count());
    for (intptr_t i = variable_count(); i < osr_phi_count; ++i) {
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

  ASSERT(entry->unchecked_entry() != nullptr ? entry->SuccessorCount() == 2
                                             : entry->SuccessorCount() == 1);

  // For OSR on a non-empty stack, insert synthetic phis on every joining entry.
  // These phis are synthetic since they are not driven by live variable
  // analysis, but merely serve the purpose of merging stack slots from
  // parameters and other predecessors at the block in which OSR occurred.
  // The original definition could flow into a join via multiple predecessors
  // but with the same definition, not requiring a phi. However, with an OSR
  // entry in a different block, phis are required to merge the OSR variable
  // and original definition where there was no phi. Therefore, we need
  // synthetic phis in all (reachable) blocks, not just in the first join.
  if (IsCompiledForOsr()) {
    for (intptr_t i = 0, n = preorder().length(); i < n; ++i) {
      AddSyntheticPhis(preorder()[i]);
    }
  }

  RenameRecursive(entry, &env, live_phis, variable_liveness,
                  inlining_parameters);

#if defined(DEBUG)
  ValidatePhis();
#endif  // defined(DEBUG)
}

intptr_t FlowGraph::ComputeLocationsOfFixedParameters(
    Zone* zone,
    const Function& function,
    bool should_assign_stack_locations /* = false */,
    compiler::ParameterInfoArray* parameter_info /* = nullptr */) {
  return compiler::ComputeCallingConvention(
      zone, function, function.num_fixed_parameters(),
      [&](intptr_t i) {
        const intptr_t index = (function.IsFactory() ? (i - 1) : i);
        return index >= 0 ? ParameterRepresentationAt(function, index)
                          : kTagged;
      },
      should_assign_stack_locations, parameter_info);
}

void FlowGraph::PopulateEnvironmentFromFunctionEntry(
    FunctionEntryInstr* function_entry,
    GrowableArray<Definition*>* env,
    GrowableArray<PhiInstr*>* live_phis,
    VariableLivenessAnalysis* variable_liveness,
    ZoneGrowableArray<Definition*>* inlining_parameters) {
  ASSERT(!IsCompiledForOsr());

  // Check if inlining_parameters include a type argument vector parameter.
  const intptr_t inlined_type_args_param =
      ((inlining_parameters != nullptr) && function().IsGeneric()) ? 1 : 0;

  ASSERT(variable_count() == env->length());
  ASSERT(function().num_fixed_parameters() <= env->length());

  const bool copies_parameters = function().MakesCopyOfParameters();
  for (intptr_t i = 0; i < function().num_fixed_parameters(); i++) {
    const auto& [location, representation] = direct_parameter_locations_[i];
    if (location.IsInvalid()) {
      ASSERT(function().MakesCopyOfParameters());
      continue;
    }

    const intptr_t env_index =
        copies_parameters ? EnvIndex(parsed_function_.RawParameterVariable(i))
                          : i;

    auto param = new (zone())
        ParameterInstr(function_entry,
                       /*env_index=*/env_index,
                       /*param_index=*/i, location, representation);

    AllocateSSAIndex(param);
    AddToInitialDefinitions(function_entry, param);
    (*env)[env_index] = param;
  }

  // Override the entries in the renaming environment which are special (i.e.
  // inlining arguments, type parameter, args descriptor, context, ...)
  {
    // Replace parameter slots with inlining definitions coming in.
    if (inlining_parameters != nullptr) {
      for (intptr_t i = 0; i < function().NumParameters(); ++i) {
        Definition* defn = (*inlining_parameters)[inlined_type_args_param + i];
        if (defn->IsConstant()) {
          ASSERT(defn->previous() == graph_entry_);
          ASSERT(defn->HasSSATemp());
        } else {
          ASSERT(defn->previous() == nullptr);
          AllocateSSAIndex(defn);
          AddToInitialDefinitions(function_entry, defn);
        }
        intptr_t index = EnvIndex(parsed_function_.RawParameterVariable(i));
        (*env)[index] = defn;
      }
    }

    // Replace the type arguments slot with a special parameter.
    const bool reify_generic_argument = function().IsGeneric();
    if (reify_generic_argument) {
      ASSERT(parsed_function().function_type_arguments() != nullptr);
      Definition* defn;
      if (inlining_parameters == nullptr) {
        // Note: If we are not inlining, then the prologue builder will
        // take care of checking that we got the correct reified type
        // arguments.  This includes checking the argument descriptor in order
        // to even find out if the parameter was passed or not.
        defn = constant_dead();
      } else {
        defn = (*inlining_parameters)[0];
      }
      if (defn->IsConstant()) {
        ASSERT(defn->previous() == graph_entry_);
        ASSERT(defn->HasSSATemp());
      } else {
        ASSERT(defn->previous() == nullptr);
        AllocateSSAIndex(defn);
        AddToInitialDefinitions(function_entry, defn);
      }
      (*env)[RawTypeArgumentEnvIndex()] = defn;
    }

    // Replace the argument descriptor slot with a special parameter.
    if (parsed_function().has_arg_desc_var()) {
      auto defn = new (Z)
          ParameterInstr(function_entry, ArgumentDescriptorEnvIndex(),
                         ParameterInstr::kNotFunctionParameter,
                         Location::RegisterLocation(ARGS_DESC_REG), kTagged);
      AllocateSSAIndex(defn);
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
    const intptr_t param_index = (i < num_direct_parameters())
                                     ? i
                                     : ParameterInstr::kNotFunctionParameter;
    ParameterInstr* param = new (zone()) ParameterInstr(
        osr_entry, /*env_index=*/i, param_index,
        EnvIndexToStackLocation(num_direct_parameters(), i), kTagged);
    AllocateSSAIndex(param);
    AddToInitialDefinitions(osr_entry, param);
    (*env)[i] = param;
  }
}

void FlowGraph::PopulateEnvironmentFromCatchEntry(
    CatchBlockEntryInstr* catch_entry,
    GrowableArray<Definition*>* env) {
  for (auto initial_def : *catch_entry->initial_definitions()) {
    auto initial_def_param = initial_def->AsParameter();
    ASSERT(initial_def_param != nullptr);
    AllocateSSAIndex(initial_def_param);
    (*env)[initial_def_param->env_index()] = initial_def_param;
  }
}

void FlowGraph::AttachEnvironment(Instruction* instr,
                                  GrowableArray<Definition*>* env) {
  auto deopt_env = Environment::From(zone(), *env, num_direct_parameters_,
                                     instr->NumberOfInputsConsumedBeforeCall(),
                                     parsed_function_);
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
          AllocateSSAIndex(phi);  // New SSA temp.
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

  if (FLAG_prune_dead_locals) {
    if (!block_entry->IsBlockEntryWithInitialDefs() ||
        block_entry->IsCatchBlockEntry()) {
      // Prune non-live variables at block entry by replacing their environment
      // slots with null.
      BitVector* live_in = variable_liveness->GetLiveInSet(block_entry);
      for (intptr_t i = 0; i < variable_count(); i++) {
        // TODO(fschneider): Make sure that live_in always contains the
        // CurrentContext variable to avoid the special case here.
        if (!live_in->Contains(i) && !IsImmortalVariable(i)) {
          (*env)[i] = constant_dead();
        }
      }
    }
  }

  if (!block_entry->IsCatchBlockEntry()) {
    // Attach environment to the block entry.
    // No environment is needed for catch entry.
    AttachEnvironment(block_entry, env);
  }

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
    Definition* result = nullptr;
    switch (current->tag()) {
      case Instruction::kLoadLocal: {
        LoadLocalInstr* load = current->Cast<LoadLocalInstr>();

        // The graph construction ensures we do not have an unused LoadLocal
        // computation.
        ASSERT(load->HasTemp());
        const intptr_t index = EnvIndex(&load->local());
        result = (*env)[index];

        PhiInstr* phi = result->AsPhi();
        if ((phi != nullptr) && !phi->is_alive()) {
          phi->mark_alive();
          live_phis->Add(phi);
        }

        if (FLAG_prune_dead_locals &&
            variable_liveness->IsLastLoad(block_entry, load)) {
          (*env)[index] = constant_dead();
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
              phi->UpdateType(*load->local().inferred_type());
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
        if (drop->value() != nullptr) {
          result = drop->value()->definition();
        }
        ASSERT((drop->value() != nullptr) || !drop->HasTemp());
        break;
      }

      case Instruction::kConstant:
      case Instruction::kUnboxedConstant: {
        ConstantInstr* constant = current->Cast<ConstantInstr>();
        if (constant->HasTemp()) {
          result = GetConstant(constant->value(), constant->representation());
        }
        break;
      }

      case Instruction::kMakeTemp: {
        // Simply push a #null value to the expression stack.
        result = constant_null_;
        break;
      }

      case Instruction::kMoveArgument:
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
            AllocateSSAIndex(definition);
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
    if (block->IsCatchBlockEntry()) {
      // Truncate stack-temporary variables from the environment.
      // Such temps won't be available in the catch block because
      // no catch-moves are generated for them, they should not be used inside
      // catch-block or after it.
      // When [try] and [catch] flow merges we make provisions (few lines below)
      // to adjust environment for possible expression stack differences.
      new_env.SetLength(variable_count());
    }
    if (set_stack) {
      ASSERT(variable_count() == new_env.length());
      new_env.FillWith(constant_dead(), variable_count(), stack_depth);
    } else if (!block->last_instruction()->IsTailCall()) {
      if (IsCompiledForOsr() && block_entry->IsTryEntry() &&
          block_entry->stack_depth() > 0 && stack_depth == 0) {
        // Allow control flow merges with empty expression stack
        // after try blocks in case of OSR.
        new_env.SetLength(variable_count());
      }

      ASSERT((variable_count() + stack_depth) == new_env.length());
    }
    RenameRecursive(block, &new_env, live_phis, variable_liveness,
                    inlining_parameters);
  }

  // 4. Process successor block. We have edge-split form, so that join block
  // can be the only successor for a block. Blocks with more than one successor
  // can't have joins among those successors.
  // Only exception is TryEntry, which has two successors, but catch_entry is
  // special successor, never a join.
  if (((block_entry->last_instruction()->SuccessorCount() == 1) &&
       block_entry->last_instruction()->SuccessorAt(0)->IsJoinEntry()) ||
      block_entry->IsTryEntry()) {
    JoinEntryInstr* successor =
        block_entry->IsTryEntry()
            ? block_entry->AsTryEntry()->try_body()
            : (block_entry->last_instruction()->SuccessorAt(0)->AsJoinEntry());
    intptr_t pred_index = successor->IndexOfPredecessor(block_entry);
    ASSERT(pred_index >= 0);
    if (successor->phis() != nullptr) {
      for (intptr_t i = 0; i < successor->phis()->length(); ++i) {
        PhiInstr* phi = (*successor->phis())[i];
        if (phi != nullptr) {
          // Rename input operand.
          Definition* input = (*env)[i];
          ASSERT(input != nullptr);
          ASSERT(!input->IsMoveArgument());
          Value* use = new (zone()) Value(input);
          phi->SetInputAt(pred_index, use);
        }
      }
    }
  }
}

#if defined(DEBUG)
void FlowGraph::ValidatePhis() {
  if (!FLAG_prune_dead_locals) {
    // We can only check if dead locals are pruned.
    return;
  }

  for (intptr_t i = 0, n = preorder().length(); i < n; ++i) {
    BlockEntryInstr* block_entry = preorder()[i];
    Instruction* last_instruction = block_entry->last_instruction();

    if ((last_instruction->SuccessorCount() == 1) &&
        last_instruction->SuccessorAt(0)->IsJoinEntry()) {
      JoinEntryInstr* successor =
          last_instruction->SuccessorAt(0)->AsJoinEntry();
      if (successor->phis() != nullptr) {
        for (intptr_t j = 0; j < successor->phis()->length(); ++j) {
          PhiInstr* phi = (*successor->phis())[j];
          if (phi == nullptr && !IsImmortalVariable(j)) {
            // We have no phi node for the this variable.
            // Double check we do not have a different value in our env.
            // If we do, we would have needed a phi-node in the successor.
            ASSERT(last_instruction->env() != nullptr);
            Definition* current_definition =
                last_instruction->env()->ValueAt(j)->definition();
            ASSERT(successor->env() != nullptr);
            Definition* successor_definition =
                successor->env()->ValueAt(j)->definition();
            if (!current_definition->IsConstant() &&
                !successor_definition->IsConstant()) {
              ASSERT(current_definition == successor_definition);
            }
          }
        }
      }
    }
  }
}
#endif  // defined(DEBUG)

void FlowGraph::RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis) {
  // Augment live_phis with those that have implicit real used at
  // potentially throwing instructions if there is a try-catch in this graph.
  if (!try_entries().is_empty()) {
    for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
      JoinEntryInstr* join = it.Current()->AsJoinEntry();
      if (join == nullptr) continue;
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* phi = phi_it.Current();
        if (phi == nullptr || phi->is_alive() ||
            (phi->input_use_list() != nullptr) ||
            (phi->env_use_list() == nullptr)) {
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
      if ((used_phi != nullptr) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis->Add(used_phi);
      }
    }
  }

  for (BlockIterator it(postorder_iterator()); !it.Done(); it.Advance()) {
    JoinEntryInstr* join = it.Current()->AsJoinEntry();
    if (join != nullptr) join->RemoveDeadPhis(constant_dead());
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
  return new (zone()) LoopHierarchy(loop_headers, preorder_, should_print());
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

static bool CanConvertInt64ToDouble() {
  return FlowGraphCompiler::CanConvertInt64ToDouble();
}

void FlowGraph::InsertConversion(Representation from,
                                 Representation to,
                                 Value* use,
                                 bool is_environment_use) {
  ASSERT(from != to);
  Instruction* insert_before;
  PhiInstr* phi = use->instruction()->AsPhi();
  if (phi != nullptr) {
    ASSERT(phi->is_alive());
    // For phis conversions have to be inserted in the predecessor.
    auto predecessor = phi->block()->PredecessorAt(use->use_index());
    insert_before = predecessor->last_instruction();
    ASSERT(insert_before->GetBlock() == predecessor);
  } else {
    insert_before = use->instruction();
  }

  Definition* converted = nullptr;
  if (IsUnboxedInteger(from) && IsUnboxedInteger(to)) {
    converted = new (Z) IntConverterInstr(from, to, use->CopyWithType());
  } else if ((from == kUnboxedInt32) && (to == kUnboxedDouble)) {
    converted = new Int32ToDoubleInstr(use->CopyWithType());
  } else if ((from == kUnboxedInt64) && (to == kUnboxedDouble) &&
             CanConvertInt64ToDouble()) {
    converted = new Int64ToDoubleInstr(use->CopyWithType(), DeoptId::kNone);
  } else if ((from == kTagged) && Boxing::Supports(to)) {
    converted = UnboxInstr::Create(to, use->CopyWithType(), DeoptId::kNone,
                                   UnboxInstr::ValueMode::kHasValidType);
  } else if ((to == kTagged) && Boxing::Supports(from)) {
    converted = BoxInstr::Create(from, use->CopyWithType());
  } else if ((to == kPairOfTagged) && (from == kTagged)) {
    // Insert conversion to an unboxed record, which can be only used
    // in Return instruction.
    ASSERT(use->instruction()->IsDartReturn());
    Definition* x = new (Z)
        LoadFieldInstr(use->CopyWithType(),
                       Slot::GetRecordFieldSlot(
                           thread(), compiler::target::Record::field_offset(0)),
                       InstructionSource());
    InsertBefore(insert_before, x, nullptr, FlowGraph::kValue);
    Definition* y = new (Z)
        LoadFieldInstr(use->CopyWithType(),
                       Slot::GetRecordFieldSlot(
                           thread(), compiler::target::Record::field_offset(1)),
                       InstructionSource());
    InsertBefore(insert_before, y, nullptr, FlowGraph::kValue);
    converted = new (Z) MakePairInstr(new (Z) Value(x), new (Z) Value(y));
  } else if ((to == kTagged) && (from == kPairOfTagged)) {
    // Handled in FlowGraph::InsertRecordBoxing.
    UNREACHABLE();
  } else {
    // We have failed to find a suitable conversion instruction. If either
    // representations is not boxable, then fail immediately.
    if (!Boxing::Supports(from) || !Boxing::Supports(to)) {
      if (FLAG_support_il_printer) {
        FATAL("Illegal conversion %s->%s for the use of %s at %s\n",
              RepresentationUtils::ToCString(from),
              RepresentationUtils::ToCString(to),
              use->definition()->ToCString(), use->instruction()->ToCString());
      } else {
        FATAL("Illegal conversion %s->%s for a use of v%" Pd "\n",
              RepresentationUtils::ToCString(from),
              RepresentationUtils::ToCString(to),
              use->definition()->ssa_temp_index());
      }
    }
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    // If the use is not speculative, then this code should be unreachable.
    // Insert Stop for a graceful error and aid unreachable code elimination.
    StopInstr* stop = new (Z) StopInstr("Incompatible conversion.");
    InsertBefore(insert_before, stop, nullptr, FlowGraph::kEffect);
    Definition* boxed = BoxInstr::Create(from, use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, nullptr, FlowGraph::kValue);
    converted = UnboxInstr::Create(to, new (Z) Value(boxed), DeoptId::kNone,
                                   UnboxInstr::ValueMode::kHasValidType);
  }
  ASSERT(converted != nullptr);
  InsertBefore(insert_before, converted, nullptr, FlowGraph::kValue);
  if (is_environment_use) {
    use->BindToEnvironment(converted);
  } else {
    use->BindTo(converted);
  }
}

static bool NeedsRecordBoxing(Definition* def) {
  if (def->env_use_list() != nullptr) return true;
  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    if (use->instruction()->RequiredInputRepresentation(use->use_index()) !=
        kPairOfTagged) {
      return true;
    }
  }
  return false;
}

void FlowGraph::InsertRecordBoxing(Definition* def) {
  // Insert conversion from unboxed record, which can be only returned
  // by a Dart call with a known interface/direct target.
  const Function* target = nullptr;
  if (auto* call = def->AsStaticCall()) {
    target = &(call->function());
  } else if (auto* call = def->AsInstanceCallBase()) {
    target = &(call->interface_target());
  } else if (auto* call = def->AsDispatchTableCall()) {
    target = &(call->interface_target());
  } else {
    UNREACHABLE();
  }
  ASSERT(target != nullptr && !target->IsNull());

  kernel::UnboxingInfoMetadata* unboxing_metadata =
      kernel::UnboxingInfoMetadataOf(*target, Z);
  ASSERT(unboxing_metadata != nullptr);
  const RecordShape shape = unboxing_metadata->return_info.record_shape;
  ASSERT(shape.num_fields() == 2);

  auto* x = new (Z)
      ExtractNthOutputInstr(new (Z) Value(def), 0, kTagged, kDynamicCid);
  auto* y = new (Z)
      ExtractNthOutputInstr(new (Z) Value(def), 1, kTagged, kDynamicCid);
  auto* alloc = new (Z)
      AllocateSmallRecordInstr(InstructionSource(), shape, new (Z) Value(x),
                               new (Z) Value(y), nullptr, def->deopt_id());
  def->ReplaceUsesWith(alloc);
  // Uses of 'def' in 'x' and 'y' should not be replaced as 'x' and 'y'
  // are not added to the flow graph yet.
  ASSERT(x->value()->definition() == def);
  ASSERT(y->value()->definition() == def);
  Instruction* insert_before = def->next();
  ASSERT(insert_before != nullptr);
  InsertBefore(insert_before, x, nullptr, FlowGraph::kValue);
  InsertBefore(insert_before, y, nullptr, FlowGraph::kValue);
  InsertBefore(insert_before, alloc, def->env(), FlowGraph::kValue);
}

void FlowGraph::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  // Insert boxing of a record once after the definition (if needed)
  // in order to avoid multiple allocations.
  if (from_rep == kPairOfTagged) {
    if (NeedsRecordBoxing(def)) {
      InsertRecordBoxing(def);
    }
    return;
  }

  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    ConvertUse(it.Current(), from_rep);
  }
}

namespace {
class PhiUnboxingHeuristic : public ValueObject {
 public:
  explicit PhiUnboxingHeuristic(FlowGraph* flow_graph)
      : worklist_(flow_graph, 10) {}

  void Process(PhiInstr* phi) {
    auto new_representation = phi->representation();
    switch (phi->Type()->ToCid()) {
      case kDoubleCid:
        new_representation = DetermineIfAnyIncomingUnboxedFloats(phi)
                                 ? kUnboxedFloat
                                 : kUnboxedDouble;
#if defined(DEBUG)
        if (new_representation == kUnboxedFloat) {
          for (auto input : phi->inputs()) {
            ASSERT(input->representation() != kUnboxedDouble);
          }
        }
#endif
        break;
      case kFloat32x4Cid:
        if (ShouldInlineSimd()) {
          new_representation = kUnboxedFloat32x4;
        }
        break;
      case kInt32x4Cid:
        if (ShouldInlineSimd()) {
          new_representation = kUnboxedInt32x4;
        }
        break;
      case kFloat64x2Cid:
        if (ShouldInlineSimd()) {
          new_representation = kUnboxedFloat64x2;
        }
        break;
    }

    if (new_representation == kTagged && phi->Type()->IsInt()) {
      // Check to see if all the (non-self) inputs are unboxed integers. If so,
      // mark the phi as an unboxed integer that can hold the possible values
      // that flow into the phi.
      for (auto input : phi->inputs()) {
        if (input == phi) continue;

        if (!IsUnboxedInteger(input->representation())) {
          new_representation = kTagged;  // Reset to a boxed phi.
          break;
        }

        if (new_representation == kTagged) {
          new_representation = input->representation();
        } else if (new_representation != input->representation()) {
          // Don't allow mixing of untagged and unboxed values.
          ASSERT(IsUnboxedInteger(input->representation()));
          // It's unclear which representation to use yet, so use
          // kNoRepresentation as a "unknown but unboxed int" marker for now.
          new_representation = kNoRepresentation;
        }
      }

      if (new_representation == kNoRepresentation) {
        // If all the inputs are unboxed integers but with different
        // representations, then pick a representation based on the range
        // of values that flow into the phi node.
        new_representation = Range::Fits(phi->range(), kUnboxedInt32)
                                 ? kUnboxedInt32
                                 : kUnboxedInt64;
      }

      // Decide if it is worth to unbox an boxed integer phi.
      if (new_representation == kTagged && !phi->Type()->can_be_sentinel()) {
#if defined(TARGET_ARCH_IS_64_BIT)
        // In AOT mode on 64-bit platforms always unbox integer typed phis
        // (similar to how we treat doubles and other boxed numeric types).
        // In JIT mode only unbox phis which are not fully known to be Smi.
        if (is_aot_ || phi->Type()->ToCid() != kSmiCid) {
          new_representation = kUnboxedInt64;
        }
#else
        // If we are on a 32-bit platform check if there are unboxed values
        // flowing into the phi and the phi value itself is flowing into an
        // unboxed operation prefer to keep it unboxed.
        // We use this heuristic instead of eagerly unboxing all the phis
        // because we are concerned about the code size and register pressure.
        const bool has_unboxed_incoming_value = HasUnboxedIncomingValue(phi);
        const bool flows_into_unboxed_use = FlowsIntoUnboxedUse(phi);

        if (has_unboxed_incoming_value && flows_into_unboxed_use) {
          new_representation = Range::Fits(phi->range(), kUnboxedInt32)
                                   ? kUnboxedInt32
                                   : kUnboxedInt64;
        }
#endif
      }
    }

    // If any non-self input of the phi node is untagged, then the phi node
    // should only have untagged inputs and thus is marked as untagged.
    //
    // Note: we can't assert that all inputs are untagged at this point because
    // one of the inputs might be a different unvisited phi node. If this
    // assumption is broken, then fail later in the SelectRepresentations pass.
    for (auto input : phi->inputs()) {
      if (input != phi && input->representation() == kUntagged) {
        new_representation = kUntagged;
        break;
      }
    }

    phi->set_representation(new_representation);
  }

 private:
  // Returns [true] if there are UnboxedFloats representation flowing into
  // the |phi|.
  // This function looks through phis.
  bool DetermineIfAnyIncomingUnboxedFloats(PhiInstr* phi) {
    worklist_.Clear();
    worklist_.Add(phi);
    for (intptr_t i = 0; i < worklist_.definitions().length(); i++) {
      const auto defn = worklist_.definitions()[i];
      for (auto input : defn->inputs()) {
        if (input->representation() == kUnboxedFloat) {
          return true;
        }
        if (input->IsPhi()) {
          worklist_.Add(input);
        }
      }
    }
    return false;
  }

  // Returns |true| iff there is an unboxed definition among all potential
  // definitions that can flow into the |phi|.
  // This function looks through phis.
  bool HasUnboxedIncomingValue(PhiInstr* phi) {
    worklist_.Clear();
    worklist_.Add(phi);
    for (intptr_t i = 0; i < worklist_.definitions().length(); i++) {
      const auto defn = worklist_.definitions()[i];
      for (auto input : defn->inputs()) {
        if (IsUnboxedInteger(input->representation()) || input->IsBox()) {
          return true;
        } else if (input->IsPhi()) {
          worklist_.Add(input);
        }
      }
    }
    return false;
  }

  // Returns |true| iff |phi| potentially flows into an unboxed use.
  // This function looks through phis.
  bool FlowsIntoUnboxedUse(PhiInstr* phi) {
    worklist_.Clear();
    worklist_.Add(phi);
    for (intptr_t i = 0; i < worklist_.definitions().length(); i++) {
      const auto defn = worklist_.definitions()[i];
      for (auto use : defn->input_uses()) {
        if (IsUnboxedInteger(use->instruction()->RequiredInputRepresentation(
                use->use_index())) ||
            use->instruction()->IsUnbox()) {
          return true;
        } else if (auto phi_use = use->instruction()->AsPhi()) {
          worklist_.Add(phi_use);
        }
      }
    }
    return false;
  }

  const bool is_aot_ = CompilerState::Current().is_aot();
  DefinitionWorklist worklist_;
};
}  // namespace

void FlowGraph::SelectRepresentations() {
  // First we decide for each phi if it is beneficial to unbox it. If so, we
  // change it's `phi->representation()`
  PhiUnboxingHeuristic phi_unboxing_heuristic(this);
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    JoinEntryInstr* join_entry = block_it.Current()->AsJoinEntry();
    if (join_entry != nullptr) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        phi_unboxing_heuristic.Process(phi);
      }
    }
  }

  // Process all initial definitions and insert conversions when needed (depends
  // on phi unboxing decision above).
  for (intptr_t i = 0; i < graph_entry()->initial_definitions()->length();
       i++) {
    InsertConversionsFor((*graph_entry()->initial_definitions())[i]);
  }

  // Process all normal definitions and insert conversions when needed (depends
  // on phi unboxing decision above).
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();
    if (JoinEntryInstr* join_entry = entry->AsJoinEntry()) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != nullptr);
        ASSERT(phi->is_alive());
        InsertConversionsFor(phi);
      }
    }
    if (auto entry_with_initial_defs = entry->AsBlockEntryWithInitialDefs()) {
      auto& initial_definitions =
          *entry_with_initial_defs->initial_definitions();
      for (intptr_t j = 0; j < initial_definitions.length(); j++) {
        InsertConversionsFor(initial_definitions[j]);
      }
    }

    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* def = it.Current()->AsDefinition();
      if (def != nullptr) {
        InsertConversionsFor(def);
      }
    }
  }
}

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
      // This check is inconsistent with the flow graph checker. The flow graph
      // checker does not allow for not having an env if the block is not
      // inside a try-catch.
      // See FlowGraphChecker::VisitInstruction.
      if (!current->ComputeCanDeoptimize() &&
          !current->ComputeCanDeoptimizeAfterCall() &&
          (!current->MayThrow() || !block->InsideTryBlock())) {
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

void FlowGraph::ExtractUntaggedPayload(Instruction* instr,
                                       Value* array,
                                       const Slot& slot,
                                       InnerPointerAccess access) {
  auto* const untag_payload = new (Z)
      LoadFieldInstr(array->CopyWithType(Z), slot, access, instr->source());
  InsertBefore(instr, untag_payload, instr->env(), FlowGraph::kValue);
  array->BindTo(untag_payload);
  ASSERT_EQUAL(array->definition()->representation(), kUntagged);
}

bool FlowGraph::ExtractExternalUntaggedPayload(Instruction* instr,
                                               Value* array,
                                               classid_t cid) {
  ASSERT(array->instruction() == instr);
  // Nothing to do if already untagged.
  if (array->definition()->representation() != kTagged) return false;
  // If we've determined at compile time that this is an object that has an
  // external payload, use the cid of the compile type instead.
  if (IsExternalPayloadClassId(array->Type()->ToCid())) {
    cid = array->Type()->ToCid();
  } else if (!IsExternalPayloadClassId(cid)) {
    // Can't extract the payload address if it points to GC-managed memory.
    return false;
  }

  const Slot* slot = nullptr;
  if (cid == kPointerCid || IsExternalTypedDataClassId(cid)) {
    slot = &Slot::PointerBase_data();
  } else {
    UNREACHABLE();
  }

  ExtractUntaggedPayload(instr, array, *slot,
                         InnerPointerAccess::kCannotBeInnerPointer);
  return true;
}

void FlowGraph::ExtractNonInternalTypedDataPayload(Instruction* instr,
                                                   Value* array,
                                                   classid_t cid) {
  ASSERT(array->instruction() == instr);
  // Skip if the array payload has already been extracted.
  if (array->definition()->representation() == kUntagged) return;
  if (!IsTypedDataBaseClassId(cid)) return;
  auto const type_cid = array->Type()->ToCid();
  // For external PointerBase objects, the payload should have already been
  // extracted during canonicalization.
  ASSERT(!IsExternalPayloadClassId(cid) && !IsExternalPayloadClassId(type_cid));
  // Extract payload for typed data view instructions even if array is
  // an internal typed data (could happen in the unreachable code),
  // as code generation handles direct accesses only for internal typed data.
  //
  // For internal typed data instructions (which are also used for
  // non-internal typed data arrays), don't extract payload if the array is
  // an internal typed data object.
  if (IsTypedDataViewClassId(cid) || !IsTypedDataClassId(type_cid)) {
    ExtractUntaggedPayload(instr, array, Slot::PointerBase_data(),
                           InnerPointerAccess::kMayBeInnerPointer);
  }
}

void FlowGraph::ExtractNonInternalTypedDataPayloads() {
  for (BlockIterator block_it = reverse_postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (auto* const load_indexed = current->AsLoadIndexed()) {
        ExtractNonInternalTypedDataPayload(load_indexed, load_indexed->array(),
                                           load_indexed->class_id());
      } else if (auto* const store_indexed = current->AsStoreIndexed()) {
        ExtractNonInternalTypedDataPayload(
            store_indexed, store_indexed->array(), store_indexed->class_id());
      } else if (auto* const memory_copy = current->AsMemoryCopy()) {
        ExtractNonInternalTypedDataPayload(memory_copy, memory_copy->src(),
                                           memory_copy->src_cid());
        ExtractNonInternalTypedDataPayload(memory_copy, memory_copy->dest(),
                                           memory_copy->dest_cid());
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
        Definition* replacement = current->Canonicalize(this);
        ASSERT(replacement != nullptr);
        RELEASE_ASSERT(unmatched_representations_allowed() ||
                       !replacement->HasUnmatchedInputRepresentations());
        if (replacement != current) {
          current->ReplaceUsesWith(replacement);
          it.RemoveCurrentFromGraph();
          changed = true;
        }
      }
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      Instruction* replacement = current->Canonicalize(this);

      if (replacement != current) {
        // For non-definitions Canonicalize should return either nullptr or
        // this.
        if (replacement != nullptr) {
          ASSERT(current->IsDefinition());
          if (!unmatched_representations_allowed()) {
            RELEASE_ASSERT(!replacement->HasUnmatchedInputRepresentations());
            if ((replacement->representation() != current->representation()) &&
                current->AsDefinition()->HasUses()) {
              // Can't canonicalize this instruction as unmatched
              // representations are not allowed at this point, but
              // replacement has a different representation.
              continue;
            }
          }
        }
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
  if (phi != nullptr) {
    return dom_block->Dominates(phi->block()->PredecessorAt(use->use_index()));
  }

  BlockEntryInstr* use_block = instr->GetBlock();
  if (use_block == dom_block) {
    // Fast path for the case of block entry.
    if (dom_block == dom) return true;

    for (Instruction* curr = dom->next(); curr != nullptr;
         curr = curr->next()) {
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
      if (definition != nullptr && !definition->IsCheckArrayBound() &&
          !definition->IsGenericCheckBound()) {
        Value* redefined = definition->RedefinedValue();
        if (redefined != nullptr) {
          if (!definition->HasSSATemp()) {
            AllocateSSAIndex(definition);
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
  if ((const_instr != nullptr) && (const_instr->value().IsSmi())) {
    return Smi::Cast(const_instr->value()).Value() >= 0;
  }
  return false;
}

static BinarySmiOpInstr* AsSmiShiftLeftInstruction(Definition* d) {
  BinarySmiOpInstr* instr = d->AsBinarySmiOp();
  if ((instr != nullptr) && (instr->op_kind() == Token::kSHL)) {
    return instr;
  }
  return nullptr;
}

void FlowGraph::OptimizeLeftShiftBitAndSmiOp(
    ForwardInstructionIterator* current_iterator,
    Definition* bit_and_instr,
    Definition* left_instr,
    Definition* right_instr) {
  ASSERT(bit_and_instr != nullptr);
  ASSERT((left_instr != nullptr) && (right_instr != nullptr));

  // Check for pattern, smi_shift_left must be single-use.
  bool is_positive_or_zero = IsPositiveOrZeroSmiConst(left_instr);
  if (!is_positive_or_zero) {
    is_positive_or_zero = IsPositiveOrZeroSmiConst(right_instr);
  }
  if (!is_positive_or_zero) return;

  BinarySmiOpInstr* smi_shift_left = nullptr;
  if (bit_and_instr->InputAt(0)->IsSingleUse()) {
    smi_shift_left = AsSmiShiftLeftInstruction(left_instr);
  }
  if ((smi_shift_left == nullptr) &&
      (bit_and_instr->InputAt(1)->IsSingleUse())) {
    smi_shift_left = AsSmiShiftLeftInstruction(right_instr);
  }
  if (smi_shift_left == nullptr) return;

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
    if (curr_instr == nullptr) {
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
      // 'other_binop' can be nullptr if it was already merged.
      if ((other_binop != nullptr) && (other_binop->op_kind() == other_kind) &&
          (other_binop->left()->definition() == left_def) &&
          (other_binop->right()->definition() == right_def)) {
        (*merge_candidates)[k] = nullptr;  // Clear it.
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
        TruncDivModInstr* div_mod =
            new (Z) TruncDivModInstr(curr_instr->left()->CopyWithType(),
                                     curr_instr->right()->CopyWithType(),
                                     curr_instr->DeoptimizationTarget());
        curr_instr->ReplaceWith(div_mod, nullptr);
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
  InsertAfter(instr, extract, nullptr, FlowGraph::kValue);
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
                              ConditionInstr* cond,
                              Instruction* inherit) {
  BranchInstr* bra = new (graph->zone()) BranchInstr(cond, DeoptId::kNone);
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
                                      ConditionInstr* condition,
                                      TargetEntryInstr** b_true,
                                      TargetEntryInstr** b_false) {
  BlockEntryInstr* entry = instruction->GetBlock();

  TargetEntryInstr* bt = NewTarget(this, inherit);
  TargetEntryInstr* bf = NewTarget(this, inherit);
  JoinEntryInstr* join = NewJoin(this, inherit);
  GotoInstr* gotot = NewGoto(this, join, inherit);
  GotoInstr* gotof = NewGoto(this, join, inherit);
  BranchInstr* bra = NewBranch(this, condition, inherit);

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
  AllocateSSAIndex(condition.oper2);
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

  AllocateSSAIndex(phi);

  phi->mark_alive();
  phi->SetInputAt(0, v1);
  phi->SetInputAt(1, v2);
  d1->AddInputUse(v1);
  d2->AddInputUse(v2);
  join->InsertPhi(phi);

  return phi;
}

void FlowGraph::InsertMoveArguments() {
  compiler::ParameterInfoArray argument_locations;

  intptr_t max_argument_slot_count = 0;
  auto& target = Function::Handle();

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

      target = Function::null();
      if (auto static_call = instruction->AsStaticCall()) {
        target = static_call->function().ptr();
      } else if (auto instance_call = instruction->AsInstanceCallBase()) {
        target = instance_call->interface_target().ptr();
      } else if (auto dispatch_call = instruction->AsDispatchTableCall()) {
        target = dispatch_call->interface_target().ptr();
      } else if (auto cachable_call = instruction->AsCachableIdempotentCall()) {
        target = cachable_call->function().ptr();
      }

      MoveArgumentsArray* arguments =
          new (Z) MoveArgumentsArray(zone(), arg_count);
      arguments->EnsureLength(arg_count, nullptr);

      const intptr_t stack_arguments_size_in_words =
          compiler::ComputeCallingConvention(
              zone(), target, arg_count,
              [&](intptr_t i) {
                return instruction->RequiredInputRepresentation(i);
              },
              /*should_assign_stack_locations=*/true, &argument_locations);

      for (intptr_t i = 0; i < arg_count; ++i) {
        const auto& [location, rep] = argument_locations[i];
        Value* arg = instruction->ArgumentValueAt(i);
        (*arguments)[i] = new (Z) MoveArgumentInstr(
            arg->CopyWithType(Z), rep, location.ToCallerSpRelative());
      }
      max_argument_slot_count = Utils::Maximum(max_argument_slot_count,
                                               stack_arguments_size_in_words);

      for (auto move_arg : *arguments) {
        // Insert all MoveArgument instructions immediately before call.
        // MoveArgumentInstr::EmitNativeCode may generate more efficient
        // code for subsequent MoveArgument instructions (ARM, ARM64).
        if (!move_arg->is_register_move()) {
          InsertBefore(instruction, move_arg, /*env=*/nullptr, kEffect);
        }
      }
      instruction->ReplaceInputsWithMoveArguments(arguments);
      if (instruction->env() != nullptr) {
        instruction->RepairArgumentUsesInEnvironment();
      }
    }
  }
  set_max_argument_slot_count(max_argument_slot_count);
}

void FlowGraph::Print(const char* phase) {
  FlowGraphPrinter::PrintGraph(phase, this);
}

class SSACompactor : public ValueObject {
 public:
  SSACompactor(intptr_t num_blocks,
               intptr_t num_ssa_vars,
               ZoneGrowableArray<Definition*>* detached_defs)
      : block_num_(num_blocks),
        ssa_num_(num_ssa_vars),
        detached_defs_(detached_defs) {
    block_num_.EnsureLength(num_blocks, -1);
    ssa_num_.EnsureLength(num_ssa_vars, -1);
  }

  void RenumberGraph(FlowGraph* graph) {
    for (auto block : graph->reverse_postorder()) {
      block_num_[block->block_id()] = 1;
      CollectDetachedMaterializations(block->env());

      if (auto* block_with_idefs = block->AsBlockEntryWithInitialDefs()) {
        for (Definition* def : *block_with_idefs->initial_definitions()) {
          RenumberDefinition(def);
          CollectDetachedMaterializations(def->env());
        }
      }
      if (auto* join = block->AsJoinEntry()) {
        for (PhiIterator it(join); !it.Done(); it.Advance()) {
          RenumberDefinition(it.Current());
        }
      }
      for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
        Instruction* instr = it.Current();
        if (Definition* def = instr->AsDefinition()) {
          RenumberDefinition(def);
        }
        CollectDetachedMaterializations(instr->env());
      }
    }
    for (auto* def : (*detached_defs_)) {
      RenumberDefinition(def);
    }
    graph->set_current_ssa_temp_index(current_ssa_index_);

    // Preserve order between block ids to as predecessors are sorted
    // by block ids.
    intptr_t current_block_index = 0;
    for (intptr_t i = 0, n = block_num_.length(); i < n; ++i) {
      if (block_num_[i] >= 0) {
        block_num_[i] = current_block_index++;
      }
    }
    for (auto block : graph->reverse_postorder()) {
      block->set_block_id(block_num_[block->block_id()]);
    }
    graph->set_max_block_id(current_block_index - 1);
  }

 private:
  void RenumberDefinition(Definition* def) {
    if (def->HasSSATemp()) {
      const intptr_t old_index = def->ssa_temp_index();
      intptr_t new_index = ssa_num_[old_index];
      if (new_index < 0) {
        ssa_num_[old_index] = new_index = current_ssa_index_++;
      }
      def->set_ssa_temp_index(new_index);
    }
  }

  bool IsDetachedDefinition(Definition* def) {
    return def->IsMaterializeObject() && (def->next() == nullptr);
  }

  void AddDetachedDefinition(Definition* def) {
    for (intptr_t i = 0, n = detached_defs_->length(); i < n; ++i) {
      if ((*detached_defs_)[i] == def) {
        return;
      }
    }
    detached_defs_->Add(def);
    // Follow inputs as detached definitions can reference other
    // detached definitions.
    for (intptr_t i = 0, n = def->InputCount(); i < n; ++i) {
      Definition* input = def->InputAt(i)->definition();
      if (IsDetachedDefinition(input)) {
        AddDetachedDefinition(input);
      }
    }
    ASSERT(def->env() == nullptr);
  }

  void CollectDetachedMaterializations(Environment* env) {
    if (env == nullptr) {
      return;
    }
    for (Environment::DeepIterator it(env); !it.Done(); it.Advance()) {
      Definition* def = it.CurrentValue()->definition();
      if (IsDetachedDefinition(def)) {
        AddDetachedDefinition(def);
      }
    }
  }

  GrowableArray<intptr_t> block_num_;
  GrowableArray<intptr_t> ssa_num_;
  intptr_t current_ssa_index_ = 0;
  ZoneGrowableArray<Definition*>* detached_defs_;
};

void FlowGraph::CompactSSA(ZoneGrowableArray<Definition*>* detached_defs) {
  if (detached_defs == nullptr) {
    detached_defs = new (Z) ZoneGrowableArray<Definition*>(Z, 0);
  }
  SSACompactor compactor(max_block_id() + 1, current_ssa_temp_index(),
                         detached_defs);
  compactor.RenumberGraph(this);
}

}  // namespace dart
