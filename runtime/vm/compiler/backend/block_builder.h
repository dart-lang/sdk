// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_BLOCK_BUILDER_H_
#define RUNTIME_VM_COMPILER_BACKEND_BLOCK_BUILDER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {
namespace compiler {

// Helper class for building basic blocks in SSA form.
class BlockBuilder : public ValueObject {
 public:
  BlockBuilder(FlowGraph* flow_graph,
               BlockEntryInstr* entry,
               bool with_frame = true)
      : flow_graph_(flow_graph),
        source_(InstructionSource(flow_graph_->function().token_pos(),
                                  flow_graph->inlining_id())),
        entry_(entry),
        current_(entry),
        dummy_env_(new Environment(0, 0, 0, flow_graph->function(), nullptr)),
        with_frame_(with_frame) {
    // Some graph transformations use environments from block entries.
    entry->SetEnvironment(dummy_env_);
  }

  Definition* AddToInitialDefinitions(Definition* def) {
    flow_graph_->AllocateSSAIndex(def);
    auto normal_entry = flow_graph_->graph_entry()->normal_entry();
    flow_graph_->AddToInitialDefinitions(normal_entry, def);
    return def;
  }

  template <typename T>
  T* AddDefinition(T* def) {
    flow_graph_->AllocateSSAIndex(def);
    AddInstruction(def);
    return def;
  }

  template <typename T>
  T* AddInstruction(T* instr) {
    if (instr->ComputeCanDeoptimize() ||
        instr->ComputeCanDeoptimizeAfterCall() ||
        instr->CanBecomeDeoptimizationTarget()) {
      // All instructions that can deoptimize must have an environment attached
      // to them.
      instr->SetEnvironment(dummy_env_);
    }
    current_ = current_->AppendInstruction(instr);
    return instr;
  }

  const Function& function() const { return flow_graph_->function(); }

  DartReturnInstr* AddReturn(Value* value) {
    const auto& function = flow_graph_->function();
    const auto representation = FlowGraph::ReturnRepresentationOf(function);
    return AddReturn(value, representation);
  }

  DartReturnInstr* AddReturn(Value* value, Representation representation) {
    DartReturnInstr* instr = new DartReturnInstr(
        Source(), value, CompilerState::Current().GetNextDeoptId(),
        representation);
    AddInstruction(instr);
    entry_->set_last_instruction(instr);
    return instr;
  }

  Definition* AddParameter(intptr_t index) {
    const auto [location, representation] =
        flow_graph_->GetDirectParameterInfoAt(index);
    return AddParameter(index, representation,
                        with_frame_ ? location : location.ToEntrySpRelative());
  }

  Definition* AddParameter(intptr_t index,
                           Representation representation,
                           Location location = Location()) {
    auto normal_entry = flow_graph_->graph_entry()->normal_entry();
    return AddToInitialDefinitions(
        new ParameterInstr(normal_entry,
                           /*env_index=*/index,
                           /*param_index=*/index, location, representation));
  }

  TokenPosition TokenPos() const { return source_.token_pos; }
  const InstructionSource& Source() const { return source_; }

  Definition* AddNullDefinition() {
    return flow_graph_->GetConstant(Object::ZoneHandle());
  }

  Definition* AddUnboxInstr(Representation rep,
                            Value* value,
                            UnboxInstr::ValueMode value_mode) {
    // Unbox floats by first unboxing a double then converting it to a float.
    auto const unbox_rep = rep == kUnboxedFloat
                               ? kUnboxedDouble
                               : Boxing::NativeRepresentation(rep);
    Definition* unboxed_value = AddDefinition(
        UnboxInstr::Create(unbox_rep, value, DeoptId::kNone, value_mode));
    if (rep != unbox_rep && unboxed_value->IsUnboxInteger()) {
      ASSERT(RepresentationUtils::ValueSize(rep) <
             RepresentationUtils::ValueSize(unbox_rep));
      // Mark unboxing of small unboxed integer representations as truncating.
      unboxed_value->AsUnboxInteger()->mark_truncating();
    }
    if (value_mode == UnboxInstr::ValueMode::kHasValidType) {
      // The type of |value| has already been checked and it is safe to
      // adjust reaching type. This is done manually because there is no type
      // propagation when building intrinsics.
      unboxed_value->AsUnbox()->value()->SetReachingType(
          new CompileType(CompileType::FromUnboxedRepresentation(rep)));
    }
    if (rep == kUnboxedFloat) {
      unboxed_value = AddDefinition(
          new DoubleToFloatInstr(new Value(unboxed_value), DeoptId::kNone));
    }
    return unboxed_value;
  }

  Definition* AddUnboxInstr(Representation rep,
                            Definition* boxed,
                            UnboxInstr::ValueMode value_mode) {
    return AddUnboxInstr(rep, new Value(boxed), value_mode);
  }

  BranchInstr* AddBranch(ComparisonInstr* comp,
                         TargetEntryInstr* true_successor,
                         TargetEntryInstr* false_successor) {
    auto branch =
        new BranchInstr(comp, CompilerState::Current().GetNextDeoptId());
    // Some graph transformations use environments from branches.
    branch->SetEnvironment(dummy_env_);
    current_->AppendInstruction(branch);
    current_ = nullptr;

    *branch->true_successor_address() = true_successor;
    *branch->false_successor_address() = false_successor;

    return branch;
  }

  void AddPhi(PhiInstr* phi) {
    flow_graph_->AllocateSSAIndex(phi);
    phi->mark_alive();
    entry_->AsJoinEntry()->InsertPhi(phi);
  }

  Instruction* last() const { return current_; }

 private:
  FlowGraph* const flow_graph_;
  const InstructionSource source_;
  BlockEntryInstr* entry_;
  Instruction* current_;
  Environment* dummy_env_;
  const bool with_frame_;
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_BLOCK_BUILDER_H_
