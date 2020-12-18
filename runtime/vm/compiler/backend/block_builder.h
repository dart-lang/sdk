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
  BlockBuilder(FlowGraph* flow_graph, BlockEntryInstr* entry)
      : flow_graph_(flow_graph),
        source_(InstructionSource(flow_graph_->function().token_pos(),
                                  flow_graph->inlining_id())),
        entry_(entry),
        current_(entry),
        dummy_env_(
            new Environment(0, 0, flow_graph->parsed_function(), nullptr)) {
    // Some graph transformations use environments from block entries.
    entry->SetEnvironment(dummy_env_);
  }

  Definition* AddToInitialDefinitions(Definition* def) {
    def->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    if (FlowGraph::NeedsPairLocation(def->representation())) {
      flow_graph_->alloc_ssa_temp_index();
    }
    auto normal_entry = flow_graph_->graph_entry()->normal_entry();
    flow_graph_->AddToInitialDefinitions(normal_entry, def);
    return def;
  }

  template <typename T>
  T* AddDefinition(T* def) {
    flow_graph_->AllocateSSAIndexes(def);
    AddInstruction(def);
    return def;
  }

  template <typename T>
  T* AddInstruction(T* instr) {
    if (instr->ComputeCanDeoptimize() ||
        instr->CanBecomeDeoptimizationTarget()) {
      // All instructions that can deoptimize must have an environment attached
      // to them.
      instr->SetEnvironment(dummy_env_);
    }
    current_ = current_->AppendInstruction(instr);
    return instr;
  }

  const Function& function() const { return flow_graph_->function(); }

  ReturnInstr* AddReturn(Value* value) {
    const auto& function = flow_graph_->function();
    const auto representation = FlowGraph::ReturnRepresentationOf(function);
    ReturnInstr* instr = new ReturnInstr(
        Source(), value, CompilerState::Current().GetNextDeoptId(),
        PcDescriptorsLayout::kInvalidYieldIndex, representation);
    AddInstruction(instr);
    entry_->set_last_instruction(instr);
    return instr;
  }

  Definition* AddParameter(intptr_t index, bool with_frame) {
    const auto& function = flow_graph_->function();
    const intptr_t param_offset = FlowGraph::ParameterOffsetAt(function, index);
    const auto representation =
        FlowGraph::ParameterRepresentationAt(function, index);
    return AddParameter(index, param_offset, with_frame, representation);
  }

  Definition* AddParameter(intptr_t index,
                           intptr_t param_offset,
                           bool with_frame,
                           Representation representation) {
    auto normal_entry = flow_graph_->graph_entry()->normal_entry();
    return AddToInitialDefinitions(
        new ParameterInstr(index, param_offset, normal_entry, representation,
                           with_frame ? FPREG : SPREG));
  }

  TokenPosition TokenPos() const { return source_.token_pos; }
  const InstructionSource& Source() const { return source_; }

  Definition* AddNullDefinition() {
    return flow_graph_->GetConstant(Object::ZoneHandle());
  }

  Definition* AddUnboxInstr(Representation rep, Value* value, bool is_checked) {
    Definition* unboxed_value =
        AddDefinition(UnboxInstr::Create(rep, value, DeoptId::kNone));
    if (is_checked) {
      // The type of |value| has already been checked and it is safe to
      // adjust reaching type. This is done manually because there is no type
      // propagation when building intrinsics.
      unboxed_value->AsUnbox()->value()->SetReachingType(
          TypeForRepresentation(rep));
    }
    return unboxed_value;
  }

  Definition* AddUnboxInstr(Representation rep,
                            Definition* boxed,
                            bool is_checked) {
    return AddUnboxInstr(rep, new Value(boxed), is_checked);
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
    phi->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
    if (FlowGraph::NeedsPairLocation(phi->representation())) {
      flow_graph_->alloc_ssa_temp_index();
    }
    phi->mark_alive();
    entry_->AsJoinEntry()->InsertPhi(phi);
  }

 private:
  static CompileType* TypeForRepresentation(Representation rep) {
    switch (rep) {
      case kUnboxedDouble:
        return new CompileType(CompileType::FromCid(kDoubleCid));
      case kUnboxedFloat32x4:
        return new CompileType(CompileType::FromCid(kFloat32x4Cid));
      case kUnboxedInt32x4:
        return new CompileType(CompileType::FromCid(kInt32x4Cid));
      case kUnboxedFloat64x2:
        return new CompileType(CompileType::FromCid(kFloat64x2Cid));
      case kUnboxedUint32:
      case kUnboxedInt64:
        return new CompileType(CompileType::Int());
      default:
        UNREACHABLE();
        return nullptr;
    }
  }

  FlowGraph* const flow_graph_;
  const InstructionSource source_;
  BlockEntryInstr* entry_;
  Instruction* current_;
  Environment* dummy_env_;
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_BLOCK_BUILDER_H_
