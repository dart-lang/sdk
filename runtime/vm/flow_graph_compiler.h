// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#define VM_FLOW_GRAPH_COMPILER_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/intermediate_language.h"

namespace dart {

// Forward declarations.
class Code;
class DeoptInfoBuilder;
class FlowGraph;
class FlowGraphCompiler;
class Function;
template <typename T> class GrowableArray;
class ParsedFunction;


class ParallelMoveResolver : public ValueObject {
 public:
  explicit ParallelMoveResolver(FlowGraphCompiler* compiler);

  // Resolve a set of parallel moves, emitting assembler instructions.
  void EmitNativeCode(ParallelMoveInstr* parallel_move);

 private:
  class ScratchFpuRegisterScope : public ValueObject {
   public:
    ScratchFpuRegisterScope(ParallelMoveResolver* resolver,
                            FpuRegister blocked);
    ~ScratchFpuRegisterScope();

    FpuRegister reg() const { return reg_; }

   private:
    ParallelMoveResolver* resolver_;
    FpuRegister reg_;
    bool spilled_;
  };

  class ScratchRegisterScope : public ValueObject {
   public:
    ScratchRegisterScope(ParallelMoveResolver* resolver, Register blocked);
    ~ScratchRegisterScope();

    Register reg() const { return reg_; }

   private:
    ParallelMoveResolver* resolver_;
    Register reg_;
    bool spilled_;
  };


  bool IsScratchLocation(Location loc);
  intptr_t AllocateScratchRegister(Location::Kind kind,
                                   intptr_t blocked,
                                   intptr_t register_count,
                                   bool* spilled);

  void SpillScratch(Register reg);
  void RestoreScratch(Register reg);
  void SpillFpuScratch(FpuRegister reg);
  void RestoreFpuScratch(FpuRegister reg);

  // friend class ScratchXmmRegisterScope;

  // Build the initial list of moves.
  void BuildInitialMoveList(ParallelMoveInstr* parallel_move);

  // Perform the move at the moves_ index in question (possibly requiring
  // other moves to satisfy dependencies).
  void PerformMove(int index);

  // Emit a move and remove it from the move graph.
  void EmitMove(int index);

  // Execute a move by emitting a swap of two operands.  The move from
  // source to destination is removed from the move graph.
  void EmitSwap(int index);

  // Verify the move list before performing moves.
  void Verify();

  // Helpers for non-trivial source-destination combinations that cannot
  // be handled by a single instruction.
  void MoveMemoryToMemory(const Address& dst, const Address& src);
  void StoreObject(const Address& dst, const Object& obj);
  void Exchange(Register reg, const Address& mem);
  void Exchange(const Address& mem1, const Address& mem2);

  FlowGraphCompiler* compiler_;

  // List of moves not yet resolved.
  GrowableArray<MoveOperands*> moves_;
};


// Used for describing a deoptimization point after call (lazy deoptimization).
// For deoptimization before instruction use class CompilerDeoptInfoWithStub.
class CompilerDeoptInfo : public ZoneAllocated {
 public:
  CompilerDeoptInfo(intptr_t deopt_id, DeoptReasonId reason)
      : pc_offset_(-1),
        deopt_id_(deopt_id),
        reason_(reason),
        deoptimization_env_(NULL) {}

  RawDeoptInfo* CreateDeoptInfo(FlowGraphCompiler* compiler,
                                DeoptInfoBuilder* builder);

  void AllocateIncomingParametersRecursive(Environment* env,
                                           intptr_t* stack_height);

  // No code needs to be generated.
  virtual void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix) {}

  intptr_t pc_offset() const { return pc_offset_; }
  void set_pc_offset(intptr_t offset) { pc_offset_ = offset; }

  intptr_t deopt_id() const { return deopt_id_; }

  DeoptReasonId reason() const { return reason_; }

  const Environment* deoptimization_env() const { return deoptimization_env_; }
  void set_deoptimization_env(Environment* env) { deoptimization_env_ = env; }

 private:
  intptr_t pc_offset_;
  const intptr_t deopt_id_;
  const DeoptReasonId reason_;
  Environment* deoptimization_env_;

  DISALLOW_COPY_AND_ASSIGN(CompilerDeoptInfo);
};


class CompilerDeoptInfoWithStub : public CompilerDeoptInfo {
 public:
  CompilerDeoptInfoWithStub(intptr_t deopt_id,
                            DeoptReasonId reason)
      : CompilerDeoptInfo(deopt_id, reason), entry_label_() {
    ASSERT(reason != kDeoptAtCall);
  }

  Label* entry_label() { return &entry_label_; }

  // Implementation is in architecture specific file.
  virtual void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix);

 private:
  Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(CompilerDeoptInfoWithStub);
};


class SlowPathCode : public ZoneAllocated {
 public:
  SlowPathCode() : entry_label_(), exit_label_() { }

  Label* entry_label() { return &entry_label_; }
  Label* exit_label() { return &exit_label_; }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

 private:
  Label entry_label_;
  Label exit_label_;

  DISALLOW_COPY_AND_ASSIGN(SlowPathCode);
};


struct CidTarget {
  intptr_t cid;
  Function* target;
  intptr_t count;
  CidTarget(intptr_t cid_arg,
            Function* target_arg,
            intptr_t count_arg)
      : cid(cid_arg), target(target_arg), count(count_arg) {}
};


class FlowGraphCompiler : public ValueObject {
 private:
  class BlockInfo : public ZoneAllocated {
   public:
    BlockInfo()
        : jump_label_(&block_label_),
          block_label_(),
          fallthrough_label_(NULL),
          is_marked_(false) {}

    Label* jump_label() const { return jump_label_; }
    void set_jump_label(Label* label) { jump_label_ = label; }

    // Label of the block that will follow this block in the generated code.
    // Can be NULL if the block is the last block.
    Label* fallthrough_label() const { return fallthrough_label_; }
    void set_fallthrough_label(Label* fallthrough_label) {
      fallthrough_label_ = fallthrough_label;
    }

    bool WasCompacted() const {
      return jump_label_ != &block_label_;
    }

    bool is_marked() const { return is_marked_; }
    void mark() { is_marked_ = true; }

   private:
    Label* jump_label_;
    Label block_label_;

    Label* fallthrough_label_;

    bool is_marked_;
  };

 public:
  FlowGraphCompiler(Assembler* assembler,
                    const FlowGraph& flow_graph,
                    bool is_optimizing);

  ~FlowGraphCompiler();

  static bool SupportsUnboxedMints();

  // Accessors.
  Assembler* assembler() const { return assembler_; }
  const ParsedFunction& parsed_function() const { return parsed_function_; }
  const GrowableArray<BlockEntryInstr*>& block_order() const {
    return block_order_;
  }
  DescriptorList* pc_descriptors_list() const {
    return pc_descriptors_list_;
  }
  BlockEntryInstr* current_block() const { return current_block_; }
  void set_current_block(BlockEntryInstr* value) {
    current_block_ = value;
  }
  static bool CanOptimize();
  bool CanOptimizeFunction() const;
  bool is_optimizing() const { return is_optimizing_; }

  const GrowableArray<BlockInfo*>& block_info() const { return block_info_; }
  ParallelMoveResolver* parallel_move_resolver() {
    return &parallel_move_resolver_;
  }

  // Constructor is lighweight, major initialization work should occur here.
  // This makes it easier to measure time spent in the compiler.
  void InitCompiler();

  void CompileGraph();

  void VisitBlocks();

  // Bail out of the flow graph compiler. Does not return to the caller.
  void Bailout(const char* reason);

  // Returns 'true' if code generation for this function is complete, i.e.,
  // no fall-through to regular code is needed.
  bool TryIntrinsify();

  void GenerateCallRuntime(intptr_t token_pos,
                           intptr_t deopt_id,
                           const RuntimeEntry& entry,
                           LocationSummary* locs);

  void GenerateCall(intptr_t token_pos,
                    const ExternalLabel* label,
                    PcDescriptors::Kind kind,
                    LocationSummary* locs);

  void GenerateDartCall(intptr_t deopt_id,
                        intptr_t token_pos,
                        const ExternalLabel* label,
                        PcDescriptors::Kind kind,
                        LocationSummary* locs);

  void GenerateAssertAssignable(intptr_t token_pos,
                                intptr_t deopt_id,
                                const AbstractType& dst_type,
                                const String& dst_name,
                                LocationSummary* locs);

  void GenerateInstanceOf(intptr_t token_pos,
                          intptr_t deopt_id,
                          const AbstractType& type,
                          bool negate_result,
                          LocationSummary* locs);

  void GenerateInstanceCall(intptr_t deopt_id,
                            intptr_t token_pos,
                            intptr_t argument_count,
                            const Array& argument_names,
                            LocationSummary* locs,
                            const ICData& ic_data);

  void GenerateStaticCall(intptr_t deopt_id,
                          intptr_t token_pos,
                          const Function& function,
                          intptr_t argument_count,
                          const Array& argument_names,
                          LocationSummary* locs);

  void GenerateNumberTypeCheck(Register kClassIdReg,
                               const AbstractType& type,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateStringTypeCheck(Register kClassIdReg,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateListTypeCheck(Register kClassIdReg,
                             Label* is_instance_lbl);

  void EmitComment(Instruction* instr);

  void EmitOptimizedInstanceCall(ExternalLabel* target_label,
                                 const ICData& ic_data,
                                 const Array& arguments_descriptor,
                                 intptr_t argument_count,
                                 intptr_t deopt_id,
                                 intptr_t token_pos,
                                 LocationSummary* locs);

  void EmitInstanceCall(ExternalLabel* target_label,
                        const ICData& ic_data,
                        const Array& arguments_descriptor,
                        intptr_t argument_count,
                        intptr_t deopt_id,
                        intptr_t token_pos,
                        LocationSummary* locs);

  void EmitMegamorphicInstanceCall(const ICData& ic_data,
                                   const Array& arguments_descriptor,
                                   intptr_t argument_count,
                                   intptr_t deopt_id,
                                   intptr_t token_pos,
                                   LocationSummary* locs);

  void EmitTestAndCall(const ICData& ic_data,
                       Register class_id_reg,
                       intptr_t arg_count,
                       const Array& arg_names,
                       Label* deopt,
                       intptr_t deopt_id,
                       intptr_t token_index,
                       LocationSummary* locs);

  void EmitDoubleCompareBranch(Condition true_condition,
                               FpuRegister left,
                               FpuRegister right,
                               BranchInstr* branch);
  void EmitDoubleCompareBool(Condition true_condition,
                             FpuRegister left,
                             FpuRegister right,
                             Register result);

  void EmitEqualityRegConstCompare(Register reg,
                                   const Object& obj,
                                   bool needs_number_check);
  void EmitEqualityRegRegCompare(Register left,
                                 Register right,
                                 bool needs_number_check);
  // Implement equality: if any of the arguments is null do identity check.
  // Fallthrough calls super equality.
  void EmitSuperEqualityCallPrologue(Register result, Label* skip_call);

  intptr_t StackSize() const;

  // Returns assembler label associated with the given block entry.
  Label* GetJumpLabel(BlockEntryInstr* block_entry) const;
  bool WasCompacted(BlockEntryInstr* block_entry) const;

  // Returns true if there is a next block after the current one in
  // the block order and if it is the given block.
  bool CanFallThroughTo(BlockEntryInstr* block_entry) const;

  void AddExceptionHandler(intptr_t try_index,
                           intptr_t outer_try_index,
                           intptr_t pc_offset,
                           const Array& handler_types);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t deopt_id,
                            intptr_t token_pos);

  void RecordSafepoint(LocationSummary* locs);

  Label* AddDeoptStub(intptr_t deopt_id, DeoptReasonId reason);

  void AddDeoptIndexAtCall(intptr_t deopt_id, intptr_t token_pos);

  void AddSlowPathCode(SlowPathCode* slow_path);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  void FinalizeDeoptInfo(const Code& code);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeComments(const Code& code);
  void FinalizeStaticCallTargetsTable(const Code& code);

  const Class& double_class() const { return double_class_; }
  const Class& float32x4_class() const { return float32x4_class_; }

  void SaveLiveRegisters(LocationSummary* locs);
  void RestoreLiveRegisters(LocationSummary* locs);

  // Returns true if the compiled function has a finally clause.
  bool HasFinally() const;

  intptr_t CurrentTryIndex() const {
    if (current_block_ == NULL) {
      return CatchClauseNode::kInvalidTryIndex;
    }
    return current_block_->try_index();
  }

  bool may_reoptimize() const { return may_reoptimize_; }

  static const int kLocalsOffsetFromFP = (-1 * kWordSize);

  static Condition FlipCondition(Condition condition);

  static bool EvaluateCondition(Condition condition, intptr_t l, intptr_t r);

  // Array/list element address computations.
  static intptr_t DataOffsetFor(intptr_t cid);
  static intptr_t ElementSizeFor(intptr_t cid);
  static FieldAddress ElementAddressForIntIndex(intptr_t cid,
                                                intptr_t index_scale,
                                                Register array,
                                                intptr_t offset);
  static FieldAddress ElementAddressForRegIndex(intptr_t cid,
                                                intptr_t index_scale,
                                                Register array,
                                                Register index);
  static Address ExternalElementAddressForIntIndex(intptr_t index_scale,
                                                   Register array,
                                                   intptr_t offset);
  static Address ExternalElementAddressForRegIndex(intptr_t index_scale,
                                                   Register array,
                                                   Register index);

 private:
  friend class CheckStackOverflowSlowPath;  // For pending_deoptimization_env_.

  void EmitFrameEntry();

  void AddStaticCallTarget(const Function& function);

  void GenerateDeferredCode();

  void EmitInstructionPrologue(Instruction* instr);
  void EmitInstructionEpilogue(Instruction* instr);

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  void EmitStaticCall(const Function& function,
                      const Array& arguments_descriptor,
                      intptr_t argument_count,
                      intptr_t deopt_id,
                      intptr_t token_pos,
                      LocationSummary* locs);

  // Type checking helper methods.
  void CheckClassIds(Register class_id_reg,
                     const GrowableArray<intptr_t>& class_ids,
                     Label* is_instance_lbl,
                     Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateInlineInstanceof(intptr_t token_pos,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateInstantiatedTypeWithArgumentsTest(
      intptr_t token_pos,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_lbl);

  bool GenerateInstantiatedTypeNoArgumentsTest(intptr_t token_pos,
                                               const AbstractType& dst_type,
                                               Label* is_instance_lbl,
                                               Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateUninstantiatedTypeTest(
      intptr_t token_pos,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_label);

  RawSubtypeTestCache* GenerateSubtype1TestCacheLookup(
      intptr_t token_pos,
      const Class& type_class,
      Label* is_instance_lbl,
      Label* is_not_instance_lbl);

  enum TypeTestStubKind {
    kTestTypeOneArg,
    kTestTypeTwoArgs,
    kTestTypeThreeArgs,
  };

  RawSubtypeTestCache* GenerateCallSubtypeTestStub(TypeTestStubKind test_kind,
                                                   Register instance_reg,
                                                   Register type_arguments_reg,
                                                   Register temp_reg,
                                                   Label* is_instance_lbl,
                                                   Label* is_not_instance_lbl);

  // Returns true if checking against this type is a direct class id comparison.
  bool TypeCheckAsClassEquality(const AbstractType& type);

  void GenerateBoolToJump(Register bool_reg, Label* is_true, Label* is_false);

  void CopyParameters();

  void GenerateInlinedGetter(intptr_t offset);
  void GenerateInlinedSetter(intptr_t offset);

  // Perform a greedy local register allocation.  Consider all registers free.
  void AllocateRegistersLocally(Instruction* instr);

  // Map a block number in a forward iteration into the block number in the
  // corresponding reverse iteration.  Used to obtain an index into
  // block_order for reverse iterations.
  intptr_t reverse_index(intptr_t index) const {
    return block_order_.length() - index - 1;
  }

  // Returns 'sorted' array in decreasing count order.
  // The expected number of elements to sort is less than 10.
  static void SortICDataByCount(const ICData& ic_data,
                                GrowableArray<CidTarget>* sorted);

  void CompactBlock(BlockEntryInstr* block);
  void CompactBlocks();

  class Assembler* assembler_;
  const ParsedFunction& parsed_function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  BlockEntryInstr* current_block_;
  ExceptionHandlerList* exception_handlers_list_;
  DescriptorList* pc_descriptors_list_;
  StackmapTableBuilder* stackmap_table_builder_;
  GrowableArray<BlockInfo*> block_info_;
  GrowableArray<CompilerDeoptInfo*> deopt_infos_;
  GrowableArray<SlowPathCode*> slow_path_code_;
  // Stores: [code offset, function, null(code)].
  const GrowableObjectArray& static_calls_target_table_;
  const bool is_optimizing_;
  // Set to true if optimized code has IC calls.
  bool may_reoptimize_;

  const Class& double_class_;
  const Class& float32x4_class_;

  ParallelMoveResolver parallel_move_resolver_;

  // Currently instructions generate deopt stubs internally by
  // calling AddDeoptStub.  To communicate deoptimization environment
  // that should be used when deoptimizing we store it in this variable.
  // In future AddDeoptStub should be moved out of the instruction template.
  Environment* pending_deoptimization_env_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_H_
