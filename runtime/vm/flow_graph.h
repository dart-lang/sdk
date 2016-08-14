// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_H_
#define VM_FLOW_GRAPH_H_

#include "vm/bit_vector.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/intermediate_language.h"
#include "vm/parser.h"
#include "vm/thread.h"

namespace dart {

class BlockEffects;
class FlowGraphBuilder;
class ValueInliningContext;
class VariableLivenessAnalysis;

class BlockIterator : public ValueObject {
 public:
  explicit BlockIterator(const GrowableArray<BlockEntryInstr*>& block_order)
      : block_order_(block_order), current_(0) { }

  BlockIterator(const BlockIterator& other)
      : ValueObject(),
        block_order_(other.block_order_),
        current_(other.current_) { }

  void Advance() {
    ASSERT(!Done());
    current_++;
  }

  bool Done() const { return current_ >= block_order_.length(); }

  BlockEntryInstr* Current() const { return block_order_[current_]; }

 private:
  const GrowableArray<BlockEntryInstr*>& block_order_;
  intptr_t current_;
};


struct ConstantPoolTrait {
  typedef ConstantInstr* Value;
  typedef const Object& Key;
  typedef ConstantInstr* Pair;

  static Key KeyOf(Pair kv) {
    return kv->value();
  }

  static Value ValueOf(Pair kv) {
    return kv;
  }

  static inline intptr_t Hashcode(Key key) {
    if (key.IsSmi()) {
      return Smi::Cast(key).Value();
    }
    if (key.IsDouble()) {
      return static_cast<intptr_t>(
          bit_cast<int32_t, float>(
              static_cast<float>(Double::Cast(key).value())));
    }
    if (key.IsMint()) {
      return static_cast<intptr_t>(Mint::Cast(key).value());
    }
    if (key.IsString()) {
      return String::Cast(key).Hash();
    }
    return key.GetClassId();
  }

  static inline bool IsKeyEqual(Pair kv, Key key) {
    return kv->value().raw() == key.raw();
  }
};


// Class to encapsulate the construction and manipulation of the flow graph.
class FlowGraph : public ZoneAllocated {
 public:
  FlowGraph(const ParsedFunction& parsed_function,
            GraphEntryInstr* graph_entry,
            intptr_t max_block_id);

  // Function properties.
  const ParsedFunction& parsed_function() const {
    return parsed_function_;
  }
  const Function& function() const {
    return parsed_function_.function();
  }
  intptr_t parameter_count() const {
    return num_copied_params_ + num_non_copied_params_;
  }
  intptr_t variable_count() const {
    return parameter_count() + parsed_function_.num_stack_locals();
  }
  intptr_t num_stack_locals() const {
    return parsed_function_.num_stack_locals();
  }
  intptr_t num_copied_params() const {
    return num_copied_params_;
  }
  intptr_t num_non_copied_params() const {
    return num_non_copied_params_;
  }
  bool IsIrregexpFunction() const {
    return function().IsIrregexpFunction();
  }

  LocalVariable* CurrentContextVar() const {
    return parsed_function().current_context_var();
  }

  intptr_t CurrentContextEnvIndex() const {
    return parsed_function().current_context_var()->BitIndexIn(
        num_non_copied_params_);
  }

  // Flow graph orders.
  const GrowableArray<BlockEntryInstr*>& preorder() const {
    return preorder_;
  }
  const GrowableArray<BlockEntryInstr*>& postorder() const {
    return postorder_;
  }
  const GrowableArray<BlockEntryInstr*>& reverse_postorder() const {
    return reverse_postorder_;
  }
  static bool ShouldReorderBlocks(const Function& function, bool is_optimized);
  GrowableArray<BlockEntryInstr*>* CodegenBlockOrder(bool is_optimized);

  // Iterators.
  BlockIterator reverse_postorder_iterator() const {
    return BlockIterator(reverse_postorder());
  }
  BlockIterator postorder_iterator() const {
    return BlockIterator(postorder());
  }

  void EnsureSSATempIndex(Definition* defn, Definition* replacement);

  void ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                 Instruction* current,
                                 Instruction* replacement);

  intptr_t current_ssa_temp_index() const { return current_ssa_temp_index_; }
  void set_current_ssa_temp_index(intptr_t index) {
    current_ssa_temp_index_ = index;
  }

  intptr_t max_virtual_register_number() const {
    return current_ssa_temp_index();
  }

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call,
                                   RawFunction::Kind kind) const;

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread()->zone(); }
  Isolate* isolate() const { return thread()->isolate(); }

  intptr_t max_block_id() const { return max_block_id_; }
  void set_max_block_id(intptr_t id) { max_block_id_ = id; }
  intptr_t allocate_block_id() { return ++max_block_id_; }

  GraphEntryInstr* graph_entry() const {
    return graph_entry_;
  }

  ConstantInstr* constant_null() const {
    return constant_null_;
  }

  ConstantInstr* constant_dead() const {
    return constant_dead_;
  }

  ConstantInstr* constant_empty_context() const {
    return constant_empty_context_;
  }

  intptr_t alloc_ssa_temp_index() { return current_ssa_temp_index_++; }

  void AllocateSSAIndexes(Definition* def) {
    ASSERT(def);
    def->set_ssa_temp_index(alloc_ssa_temp_index());
    // Always allocate a second index. This index is unused except
    // for Definitions with register pair outputs.
    alloc_ssa_temp_index();
  }

  intptr_t InstructionCount() const;

  ConstantInstr* GetConstant(const Object& object);
  void AddToInitialDefinitions(Definition* defn);

  enum UseKind { kEffect, kValue };

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    UseKind use_kind);
  void InsertAfter(Instruction* prev,
                   Instruction* instr,
                   Environment* env,
                   UseKind use_kind);
  Instruction* AppendTo(Instruction* prev,
                        Instruction* instr,
                        Environment* env,
                        UseKind use_kind);

  // Operations on the flow graph.
  void ComputeSSA(intptr_t next_virtual_register_number,
                  ZoneGrowableArray<Definition*>* inlining_parameters);

  // Verification methods for debugging.
  bool VerifyUseLists();

  void DiscoverBlocks();

  void MergeBlocks();

  // Compute information about effects occuring in different blocks and
  // discover side-effect free paths.
  void ComputeBlockEffects();
  BlockEffects* block_effects() const { return block_effects_; }

  // Remove the redefinition instructions inserted to inhibit code motion.
  void RemoveRedefinitions();

  // Copy deoptimization target from one instruction to another if we still
  // have to keep deoptimization environment at gotos for LICM purposes.
  void CopyDeoptTarget(Instruction* to, Instruction* from) {
    if (is_licm_allowed()) {
      to->InheritDeoptTarget(zone(), from);
    }
  }

  // Returns true if every Goto in the graph is expected to have a
  // deoptimization environment and can be used as deoptimization target
  // for hoisted instructions.
  bool is_licm_allowed() const { return licm_allowed_; }

  // Stop preserving environments on Goto instructions. LICM is not allowed
  // after this point.
  void disallow_licm() { licm_allowed_ = false; }

  const ZoneGrowableArray<BlockEntryInstr*>& LoopHeaders() {
    if (loop_headers_ == NULL) {
      loop_headers_ = ComputeLoops();
    }
    return *loop_headers_;
  }

  const ZoneGrowableArray<BlockEntryInstr*>* loop_headers() const {
    return loop_headers_;
  }

  // Finds natural loops in the flow graph and attaches a list of loop
  // body blocks for each loop header.
  ZoneGrowableArray<BlockEntryInstr*>* ComputeLoops() const;

  // Per loop header invariant loads sets. Each set contains load id for
  // those loads that are not affected by anything in the loop and can be
  // hoisted out. Sets are computed by LoadOptimizer.
  ZoneGrowableArray<BitVector*>* loop_invariant_loads() const {
    return loop_invariant_loads_;
  }
  void set_loop_invariant_loads(
      ZoneGrowableArray<BitVector*>* loop_invariant_loads) {
    loop_invariant_loads_ = loop_invariant_loads;
  }

  bool IsCompiledForOsr() const { return graph_entry()->IsCompiledForOsr(); }

  void AddToDeferredPrefixes(ZoneGrowableArray<const LibraryPrefix*>* from);

  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes() const {
    return deferred_prefixes_;
  }

  BitVector* captured_parameters() const {
    return captured_parameters_;
  }

  intptr_t inlining_id() const { return inlining_id_; }
  void set_inlining_id(intptr_t value) { inlining_id_ = value; }

  // Returns true if any instructions were canonicalized away.
  bool Canonicalize();

  void SelectRepresentations();

  void WidenSmiToInt32();

  // Remove environments from the instructions which do not deoptimize.
  void EliminateEnvironments();

  bool IsReceiver(Definition* def) const;

 private:
  friend class IfConverter;
  friend class BranchSimplifier;
  friend class ConstantPropagator;
  friend class DeadCodeElimination;

  // SSA transformation methods and fields.
  void ComputeDominators(GrowableArray<BitVector*>* dominance_frontier);

  void CompressPath(
      intptr_t start_index,
      intptr_t current_index,
      GrowableArray<intptr_t>* parent,
      GrowableArray<intptr_t>* label);

  void Rename(GrowableArray<PhiInstr*>* live_phis,
              VariableLivenessAnalysis* variable_liveness,
              ZoneGrowableArray<Definition*>* inlining_parameters);
  void RenameRecursive(
      BlockEntryInstr* block_entry,
      GrowableArray<Definition*>* env,
      GrowableArray<PhiInstr*>* live_phis,
      VariableLivenessAnalysis* variable_liveness);

  void AttachEnvironment(Instruction* instr, GrowableArray<Definition*>* env);

  void InsertPhis(
      const GrowableArray<BlockEntryInstr*>& preorder,
      const GrowableArray<BitVector*>& assigned_vars,
      const GrowableArray<BitVector*>& dom_frontier,
      GrowableArray<PhiInstr*>* live_phis);

  void RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis);

  void ReplacePredecessor(BlockEntryInstr* old_block,
                          BlockEntryInstr* new_block);

  // Find the natural loop for the back edge m->n and attach loop
  // information to block n (loop header). The algorithm is described in
  // "Advanced Compiler Design & Implementation" (Muchnick) p192.
  // Returns a BitVector indexed by block pre-order number where each bit
  // indicates membership in the loop.
  BitVector* FindLoop(BlockEntryInstr* m, BlockEntryInstr* n) const;

  void InsertConversionsFor(Definition* def);
  void ConvertUse(Value* use, Representation from);
  void ConvertEnvironmentUse(Value* use, Representation from);
  void InsertConversion(Representation from,
                        Representation to,
                        Value* use,
                        bool is_environment_use);

  void ComputeIsReceiver(PhiInstr* phi) const;
  void ComputeIsReceiverRecursive(PhiInstr* phi,
                                  GrowableArray<PhiInstr*>* unmark) const;

  Thread* thread_;

  // DiscoverBlocks computes parent_ and assigned_vars_ which are then used
  // if/when computing SSA.
  GrowableArray<intptr_t> parent_;
  GrowableArray<BitVector*> assigned_vars_;

  intptr_t current_ssa_temp_index_;
  intptr_t max_block_id_;

  // Flow graph fields.
  const ParsedFunction& parsed_function_;
  const intptr_t num_copied_params_;
  const intptr_t num_non_copied_params_;
  GraphEntryInstr* graph_entry_;
  GrowableArray<BlockEntryInstr*> preorder_;
  GrowableArray<BlockEntryInstr*> postorder_;
  GrowableArray<BlockEntryInstr*> reverse_postorder_;
  GrowableArray<BlockEntryInstr*> optimized_block_order_;
  ConstantInstr* constant_null_;
  ConstantInstr* constant_dead_;
  ConstantInstr* constant_empty_context_;

  BlockEffects* block_effects_;
  bool licm_allowed_;

  ZoneGrowableArray<BlockEntryInstr*>* loop_headers_;
  ZoneGrowableArray<BitVector*>* loop_invariant_loads_;
  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes_;
  DirectChainedHashMap<ConstantPoolTrait> constant_instr_pool_;
  BitVector* captured_parameters_;

  intptr_t inlining_id_;
};


class LivenessAnalysis : public ValueObject {
 public:
  LivenessAnalysis(intptr_t variable_count,
                   const GrowableArray<BlockEntryInstr*>& postorder);

  void Analyze();

  virtual ~LivenessAnalysis() { }

  BitVector* GetLiveInSetAt(intptr_t postorder_number) const {
    return live_in_[postorder_number];
  }

  BitVector* GetLiveOutSetAt(intptr_t postorder_number) const {
    return live_out_[postorder_number];
  }

  BitVector* GetLiveInSet(BlockEntryInstr* block) const {
    return GetLiveInSetAt(block->postorder_number());
  }

  BitVector* GetKillSet(BlockEntryInstr* block) const {
    return kill_[block->postorder_number()];
  }

  BitVector* GetLiveOutSet(BlockEntryInstr* block) const {
    return GetLiveOutSetAt(block->postorder_number());
  }

  // Print results of liveness analysis.
  void Dump();

 protected:
  // Compute initial values for live-out, kill and live-in sets.
  virtual void ComputeInitialSets() = 0;

  // Update live-out set for the given block: live-out should contain
  // all values that are live-in for block's successors.
  // Returns true if live-out set was changed.
  bool UpdateLiveOut(const BlockEntryInstr& instr);

  // Update live-in set for the given block: live-in should contain
  // all values that are live-out from the block and are not defined
  // by this block.
  // Returns true if live-in set was changed.
  bool UpdateLiveIn(const BlockEntryInstr& instr);

  // Perform fix-point iteration updating live-out and live-in sets
  // for blocks until they stop changing.
  void ComputeLiveInAndLiveOutSets();

  Zone* zone() const { return zone_; }

  Zone* zone_;

  const intptr_t variable_count_;

  const GrowableArray<BlockEntryInstr*>& postorder_;

  // Live-out sets for each block.  They contain indices of variables
  // that are live out from this block: that is values that were either
  // defined in this block or live into it and that are used in some
  // successor block.
  GrowableArray<BitVector*> live_out_;

  // Kill sets for each block.  They contain indices of variables that
  // are defined by this block.
  GrowableArray<BitVector*> kill_;

  // Live-in sets for each block.  They contain indices of variables
  // that are used by this block or its successors.
  GrowableArray<BitVector*> live_in_;
};


// Information about side effect free paths between blocks.
class BlockEffects : public ZoneAllocated {
 public:
  explicit BlockEffects(FlowGraph* flow_graph);

  // Return true if the given instruction is not affected by anything between
  // its current block and target block. Used by CSE to determine if
  // a computation is available in the given block.
  bool IsAvailableAt(Instruction* instr, BlockEntryInstr* block) const;

  // Return true if the given instruction is not affected by anything between
  // the given block and its current block. Used by LICM to determine if
  // a computation can be moved to loop's preheader and remain available at
  // its current location.
  bool CanBeMovedTo(Instruction* instr, BlockEntryInstr* block) const;

 private:
  // Returns true if from dominates to and all paths between from and to are
  // free of side effects.
  bool IsSideEffectFreePath(BlockEntryInstr* from, BlockEntryInstr* to) const;

  // Per block sets of available blocks. Block A is available at the block B if
  // and only if A dominates B and all paths from A to B are free of side
  // effects.
  GrowableArray<BitVector*> available_at_;
};


class DefinitionWorklist : public ValueObject {
 public:
  DefinitionWorklist(FlowGraph* flow_graph,
                     intptr_t initial_capacity)
      : defs_(initial_capacity),
        contains_vector_(
            new BitVector(flow_graph->zone(),
                          flow_graph->current_ssa_temp_index())) {
  }

  void Add(Definition* defn) {
    if (!Contains(defn)) {
      defs_.Add(defn);
      contains_vector_->Add(defn->ssa_temp_index());
    }
  }

  bool Contains(Definition* defn) const {
    return (defn->ssa_temp_index() >= 0) &&
        contains_vector_->Contains(defn->ssa_temp_index());
  }

  bool IsEmpty() const {
    return defs_.is_empty();
  }

  Definition* RemoveLast() {
    Definition* defn = defs_.RemoveLast();
    contains_vector_->Remove(defn->ssa_temp_index());
    return defn;
  }

  const GrowableArray<Definition*>& definitions() const { return defs_; }
  BitVector* contains_vector() const { return contains_vector_; }

  void Clear() {
    defs_.TruncateTo(0);
    contains_vector_->Clear();
  }

 private:
  GrowableArray<Definition*> defs_;
  BitVector* contains_vector_;
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_H_
