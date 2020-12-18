// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_H_
#define RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/bit_vector.h"
#include "vm/compiler/backend/il.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/parser.h"
#include "vm/thread.h"

namespace dart {

class LoopHierarchy;
class VariableLivenessAnalysis;

namespace compiler {
class GraphIntrinsifier;
}

class BlockIterator : public ValueObject {
 public:
  explicit BlockIterator(const GrowableArray<BlockEntryInstr*>& block_order)
      : block_order_(block_order), current_(0) {}

  BlockIterator(const BlockIterator& other)
      : ValueObject(),
        block_order_(other.block_order_),
        current_(other.current_) {}

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

  static Key KeyOf(Pair kv) { return kv->value(); }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    if (key.IsSmi()) {
      return Smi::Cast(key).Value();
    }
    if (key.IsDouble()) {
      return static_cast<intptr_t>(bit_cast<int32_t, float>(
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

struct PrologueInfo {
  // The first blockid used for prologue building.  This information can be used
  // by the inliner for budget calculations: The prologue code falls away when
  // inlining, so we should not include it in the budget.
  intptr_t min_block_id;

  // The last blockid used for prologue building.  This information can be used
  // by the inliner for budget calculations: The prologue code falls away when
  // inlining, so we should not include it in the budget.
  intptr_t max_block_id;

  PrologueInfo(intptr_t min, intptr_t max)
      : min_block_id(min), max_block_id(max) {}

  bool Contains(intptr_t block_id) const {
    return min_block_id <= block_id && block_id <= max_block_id;
  }
};

// Class to encapsulate the construction and manipulation of the flow graph.
class FlowGraph : public ZoneAllocated {
 public:
  FlowGraph(const ParsedFunction& parsed_function,
            GraphEntryInstr* graph_entry,
            intptr_t max_block_id,
            PrologueInfo prologue_info);

  // Function properties.
  const ParsedFunction& parsed_function() const { return parsed_function_; }
  const Function& function() const { return parsed_function_.function(); }

  // The number of directly accessable parameters (above the frame pointer).
  // All other parameters can only be indirectly loaded via metadata found in
  // the arguments descriptor.
  intptr_t num_direct_parameters() const { return num_direct_parameters_; }

  // The number of words on the stack used by the direct parameters.
  intptr_t direct_parameters_size() const { return direct_parameters_size_; }

  // The number of variables (or boxes) which code can load from / store to.
  // The SSA renaming will insert phi's for them (and only them - i.e. there
  // will be no phi insertion for [LocalVariable]s pointing to the expression
  // stack!).
  intptr_t variable_count() const {
    return num_direct_parameters_ + parsed_function_.num_stack_locals();
  }

  // The number of variables during OSR, which may include stack slots
  // that pass in initial contents for the expression stack.
  intptr_t osr_variable_count() const {
    ASSERT(IsCompiledForOsr());
    return variable_count() + graph_entry()->osr_entry()->stack_depth();
  }

  // This function returns the offset (in words) of the [index]th
  // parameter, relative to the first parameter.
  // If [last_slot] is true it gives the offset of the last slot of that
  // location, otherwise it returns the first one.
  static intptr_t ParameterOffsetAt(const Function& function,
                                    intptr_t index,
                                    bool last_slot = true);

  static Representation ParameterRepresentationAt(const Function& function,
                                                  intptr_t index);

  static Representation ReturnRepresentationOf(const Function& function);

  static Representation UnboxedFieldRepresentationOf(const Field& field);

  // The number of variables (or boxes) inside the functions frame - meaning
  // below the frame pointer.  This does not include the expression stack.
  intptr_t num_stack_locals() const {
    return parsed_function_.num_stack_locals();
  }

  bool IsIrregexpFunction() const { return function().IsIrregexpFunction(); }

  LocalVariable* CurrentContextVar() const {
    return parsed_function().current_context_var();
  }

  intptr_t CurrentContextEnvIndex() const {
    return EnvIndex(parsed_function().current_context_var());
  }

  intptr_t RawTypeArgumentEnvIndex() const {
    return EnvIndex(parsed_function().RawTypeArgumentsVariable());
  }

  intptr_t ArgumentDescriptorEnvIndex() const {
    return EnvIndex(parsed_function().arg_desc_var());
  }

  intptr_t EnvIndex(const LocalVariable* variable) const {
    ASSERT(!variable->is_captured());
    return num_direct_parameters_ - variable->index().value();
  }

  static bool NeedsPairLocation(Representation representation) {
    return representation == kUnboxedInt64 &&
           compiler::target::kIntSpillFactor == 2;
  }

  // Flow graph orders.
  const GrowableArray<BlockEntryInstr*>& preorder() const { return preorder_; }
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

  Instruction* CreateCheckClass(Definition* to_check,
                                const Cids& cids,
                                intptr_t deopt_id,
                                const InstructionSource& source);

  Definition* CreateCheckBound(Definition* length,
                               Definition* index,
                               intptr_t deopt_id);

  void AddExactnessGuard(InstanceCallInstr* call, intptr_t receiver_cid);

  intptr_t current_ssa_temp_index() const { return current_ssa_temp_index_; }
  void set_current_ssa_temp_index(intptr_t index) {
    current_ssa_temp_index_ = index;
  }

  intptr_t max_virtual_register_number() const {
    return current_ssa_temp_index();
  }

  enum class ToCheck { kNoCheck, kCheckNull, kCheckCid };

  // Uses CHA to determine if the called method can be overridden.
  // Return value indicates that the call needs no check at all,
  // just a null check, or a full class check.
  ToCheck CheckForInstanceCall(InstanceCallInstr* call,
                               FunctionLayout::Kind kind) const;

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread()->zone(); }
  Isolate* isolate() const { return thread()->isolate(); }

  intptr_t max_block_id() const { return max_block_id_; }
  void set_max_block_id(intptr_t id) { max_block_id_ = id; }
  intptr_t allocate_block_id() { return ++max_block_id_; }

  GraphEntryInstr* graph_entry() const { return graph_entry_; }

  ConstantInstr* constant_null() const { return constant_null_; }

  ConstantInstr* constant_dead() const { return constant_dead_; }

  intptr_t alloc_ssa_temp_index() { return current_ssa_temp_index_++; }

  void AllocateSSAIndexes(Definition* def) {
    ASSERT(def);
    def->set_ssa_temp_index(alloc_ssa_temp_index());
    // Always allocate a second index. This index is unused except
    // for Definitions with register pair outputs.
    alloc_ssa_temp_index();
  }

  intptr_t InstructionCount() const;

  // Returns the definition for the object from the constant pool if
  // one exists, otherwise returns nullptr.
  ConstantInstr* GetExistingConstant(const Object& object) const;

  // Always returns a definition for the object from the constant pool,
  // allocating one if it doesn't already exist.
  ConstantInstr* GetConstant(const Object& object);

  void AddToGraphInitialDefinitions(Definition* defn);
  void AddToInitialDefinitions(BlockEntryWithInitialDefs* entry,
                               Definition* defn);

  // Tries to create a constant definition with the given value which can be
  // used to replace the given operation. Ensures that the representation of
  // the replacement matches the representation of the original definition.
  // If the given value can't be represented using matching representation
  // then returns op itself.
  Definition* TryCreateConstantReplacementFor(Definition* op,
                                              const Object& value);

  // Returns true if the given constant value can be represented in the given
  // representation.
  static bool IsConstantRepresentable(const Object& value,
                                      Representation target_rep,
                                      bool tagged_value_must_be_smi);

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

  // Verification method for debugging.
  bool VerifyRedefinitions();

  void DiscoverBlocks();

  void MergeBlocks();

  // Insert a redefinition of an original definition after prev and rename all
  // dominated uses of the original.  If an equivalent redefinition is already
  // present, nothing is inserted.
  // Returns the redefinition, if a redefinition was inserted, NULL otherwise.
  RedefinitionInstr* EnsureRedefinition(Instruction* prev,
                                        Definition* original,
                                        CompileType compile_type);

  // Remove the redefinition instructions inserted to inhibit code motion.
  void RemoveRedefinitions(bool keep_checks = false);

  // Insert PushArgument instructions and remove explicit def-use
  // relations between calls and their arguments.
  void InsertPushArguments();

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

  PrologueInfo prologue_info() const { return prologue_info_; }

  // Computes the loop hierarchy of the flow graph on demand.
  const LoopHierarchy& GetLoopHierarchy() {
    if (loop_hierarchy_ == nullptr) {
      loop_hierarchy_ = ComputeLoops();
    }
    return loop_hierarchy();
  }

  const LoopHierarchy& loop_hierarchy() const { return *loop_hierarchy_; }

  // Resets the loop hierarchy of the flow graph. Use this to
  // force a recomputation of loop detection by the next call
  // to GetLoopHierarchy() (note that this does not immediately
  // reset the loop_info fields of block entries, although
  // these will be overwritten by that next call).
  void ResetLoopHierarchy() {
    loop_hierarchy_ = nullptr;
    loop_invariant_loads_ = nullptr;
  }

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

  BitVector* captured_parameters() const { return captured_parameters_; }

  intptr_t inlining_id() const { return inlining_id_; }
  void set_inlining_id(intptr_t value) { inlining_id_ = value; }

  // Returns true if any instructions were canonicalized away.
  bool Canonicalize();

  // Attaches new ICData's to static/instance calls which don't already have
  // them.
  void PopulateWithICData(const Function& function);

  void SelectRepresentations();

  void WidenSmiToInt32();

  // Remove environments from the instructions which do not deoptimize.
  void EliminateEnvironments();

  bool IsReceiver(Definition* def) const;

  // Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
  // shift can be a truncating Smi shift-left and result is always Smi.
  // Merge instructions (only per basic-block).
  void TryOptimizePatterns();

  // Replaces uses that are dominated by dom of 'def' with 'other'.
  // Note: uses that occur at instruction dom itself are not dominated by it.
  static void RenameDominatedUses(Definition* def,
                                  Instruction* dom,
                                  Definition* other);

  // Renames uses of redefined values to make sure that uses of redefined
  // values that are dominated by a redefinition are renamed.
  void RenameUsesDominatedByRedefinitions();

  bool should_print() const { return should_print_; }

  //
  // High-level utilities.
  //

  // Logical-AND (for use in short-circuit diamond).
  struct LogicalAnd {
    LogicalAnd(ComparisonInstr* x, ComparisonInstr* y) : oper1(x), oper2(y) {}
    ComparisonInstr* oper1;
    ComparisonInstr* oper2;
  };

  // Constructs a diamond control flow at the instruction, inheriting
  // properties from inherit and using the given compare. Returns the
  // join (and true/false blocks in out parameters). Updates dominance
  // relation, but not the succ/pred ordering on block.
  JoinEntryInstr* NewDiamond(Instruction* instruction,
                             Instruction* inherit,
                             ComparisonInstr* compare,
                             TargetEntryInstr** block_true,
                             TargetEntryInstr** block_false);

  // As above, but with a short-circuit on two comparisons.
  JoinEntryInstr* NewDiamond(Instruction* instruction,
                             Instruction* inherit,
                             const LogicalAnd& condition,
                             TargetEntryInstr** block_true,
                             TargetEntryInstr** block_false);

  // Adds a 2-way phi.
  PhiInstr* AddPhi(JoinEntryInstr* join, Definition* d1, Definition* d2);

  // SSA transformation methods and fields.
  void ComputeDominators(GrowableArray<BitVector*>* dominance_frontier);

  void CreateCommonConstants();

 private:
  friend class FlowGraphCompiler;  // TODO(ajcbik): restructure
  friend class FlowGraphChecker;
  friend class IfConverter;
  friend class BranchSimplifier;
  friend class ConstantPropagator;
  friend class DeadCodeElimination;
  friend class compiler::GraphIntrinsifier;

  void CompressPath(intptr_t start_index,
                    intptr_t current_index,
                    GrowableArray<intptr_t>* parent,
                    GrowableArray<intptr_t>* label);

  void AddSyntheticPhis(BlockEntryInstr* block);

  void Rename(GrowableArray<PhiInstr*>* live_phis,
              VariableLivenessAnalysis* variable_liveness,
              ZoneGrowableArray<Definition*>* inlining_parameters);
  void RenameRecursive(BlockEntryInstr* block_entry,
                       GrowableArray<Definition*>* env,
                       GrowableArray<PhiInstr*>* live_phis,
                       VariableLivenessAnalysis* variable_liveness,
                       ZoneGrowableArray<Definition*>* inlining_parameters);

  void PopulateEnvironmentFromFunctionEntry(
      FunctionEntryInstr* function_entry,
      GrowableArray<Definition*>* env,
      GrowableArray<PhiInstr*>* live_phis,
      VariableLivenessAnalysis* variable_liveness,
      ZoneGrowableArray<Definition*>* inlining_parameters);

  void PopulateEnvironmentFromOsrEntry(OsrEntryInstr* osr_entry,
                                       GrowableArray<Definition*>* env);

  void PopulateEnvironmentFromCatchEntry(CatchBlockEntryInstr* catch_entry,
                                         GrowableArray<Definition*>* env);

  void AttachEnvironment(Instruction* instr, GrowableArray<Definition*>* env);

  void InsertPhis(const GrowableArray<BlockEntryInstr*>& preorder,
                  const GrowableArray<BitVector*>& assigned_vars,
                  const GrowableArray<BitVector*>& dom_frontier,
                  GrowableArray<PhiInstr*>* live_phis);

  void RemoveDeadPhis(GrowableArray<PhiInstr*>* live_phis);

  void ReplacePredecessor(BlockEntryInstr* old_block,
                          BlockEntryInstr* new_block);

  // Finds the blocks in the natural loop for the back edge m->n. The
  // algorithm is described in "Advanced Compiler Design & Implementation"
  // (Muchnick) p192. Returns a BitVector indexed by block pre-order
  // number where each bit indicates membership in the loop.
  BitVector* FindLoopBlocks(BlockEntryInstr* m, BlockEntryInstr* n) const;

  // Finds the natural loops in the flow graph and attaches the loop
  // information to each entry block. Returns the loop hierarchy.
  LoopHierarchy* ComputeLoops() const;

  void InsertConversionsFor(Definition* def);
  void ConvertUse(Value* use, Representation from);
  void InsertConversion(Representation from,
                        Representation to,
                        Value* use,
                        bool is_environment_use);

  void ComputeIsReceiver(PhiInstr* phi) const;
  void ComputeIsReceiverRecursive(PhiInstr* phi,
                                  GrowableArray<PhiInstr*>* unmark) const;

  void OptimizeLeftShiftBitAndSmiOp(
      ForwardInstructionIterator* current_iterator,
      Definition* bit_and_instr,
      Definition* left_instr,
      Definition* right_instr);

  void TryMergeTruncDivMod(GrowableArray<BinarySmiOpInstr*>* merge_candidates);

  void AppendExtractNthOutputForMerged(Definition* instr,
                                       intptr_t ix,
                                       Representation rep,
                                       intptr_t cid);

  Thread* thread_;

  // DiscoverBlocks computes parent_ and assigned_vars_ which are then used
  // if/when computing SSA.
  GrowableArray<intptr_t> parent_;
  GrowableArray<BitVector*> assigned_vars_;

  intptr_t current_ssa_temp_index_;
  intptr_t max_block_id_;

  // Flow graph fields.
  const ParsedFunction& parsed_function_;
  intptr_t num_direct_parameters_;
  intptr_t direct_parameters_size_;
  GraphEntryInstr* graph_entry_;
  GrowableArray<BlockEntryInstr*> preorder_;
  GrowableArray<BlockEntryInstr*> postorder_;
  GrowableArray<BlockEntryInstr*> reverse_postorder_;
  GrowableArray<BlockEntryInstr*> optimized_block_order_;
  ConstantInstr* constant_null_;
  ConstantInstr* constant_dead_;

  bool licm_allowed_;

  const PrologueInfo prologue_info_;

  // Loop related fields.
  LoopHierarchy* loop_hierarchy_;
  ZoneGrowableArray<BitVector*>* loop_invariant_loads_;

  DirectChainedHashMap<ConstantPoolTrait> constant_instr_pool_;
  BitVector* captured_parameters_;

  intptr_t inlining_id_;
  bool should_print_;
};

class LivenessAnalysis : public ValueObject {
 public:
  LivenessAnalysis(intptr_t variable_count,
                   const GrowableArray<BlockEntryInstr*>& postorder);

  void Analyze();

  virtual ~LivenessAnalysis() {}

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

class DefinitionWorklist : public ValueObject {
 public:
  DefinitionWorklist(FlowGraph* flow_graph, intptr_t initial_capacity)
      : defs_(initial_capacity),
        contains_vector_(new BitVector(flow_graph->zone(),
                                       flow_graph->current_ssa_temp_index())) {}

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

  bool IsEmpty() const { return defs_.is_empty(); }

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

#endif  // RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_H_
