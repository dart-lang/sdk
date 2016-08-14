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
                                   uword blocked_mask,
                                   intptr_t first_free_register,
                                   intptr_t last_free_register,
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
  void Exchange(Register reg, Register base_reg, intptr_t stack_offset);
  void Exchange(Register base_reg1,
                intptr_t stack_offset1,
                Register base_reg2,
                intptr_t stack_offset2);

  FlowGraphCompiler* compiler_;

  // List of moves not yet resolved.
  GrowableArray<MoveOperands*> moves_;
};


// Used for describing a deoptimization point after call (lazy deoptimization).
// For deoptimization before instruction use class CompilerDeoptInfoWithStub.
class CompilerDeoptInfo : public ZoneAllocated {
 public:
  CompilerDeoptInfo(intptr_t deopt_id,
                    ICData::DeoptReasonId reason,
                    uint32_t flags,
                    Environment* deopt_env)
      : pc_offset_(-1),
        deopt_id_(deopt_id),
        reason_(reason),
        flags_(flags),
        deopt_env_(deopt_env) {
    ASSERT(deopt_env != NULL);
  }
  virtual ~CompilerDeoptInfo() { }

  RawTypedData* CreateDeoptInfo(FlowGraphCompiler* compiler,
                                DeoptInfoBuilder* builder,
                                const Array& deopt_table);


  // No code needs to be generated.
  virtual void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix) {}

  intptr_t pc_offset() const { return pc_offset_; }
  void set_pc_offset(intptr_t offset) { pc_offset_ = offset; }

  intptr_t deopt_id() const { return deopt_id_; }
  ICData::DeoptReasonId reason() const { return reason_; }
  uint32_t flags() const { return flags_; }
  const Environment* deopt_env() const { return deopt_env_; }

 private:
  void EmitMaterializations(Environment* env, DeoptInfoBuilder* builder);

  void AllocateIncomingParametersRecursive(Environment* env,
                                           intptr_t* stack_height);

  intptr_t pc_offset_;
  const intptr_t deopt_id_;
  const ICData::DeoptReasonId reason_;
  const uint32_t flags_;
  Environment* deopt_env_;

  DISALLOW_COPY_AND_ASSIGN(CompilerDeoptInfo);
};


class CompilerDeoptInfoWithStub : public CompilerDeoptInfo {
 public:
  CompilerDeoptInfoWithStub(intptr_t deopt_id,
                            ICData::DeoptReasonId reason,
                            uint32_t flags,
                            Environment* deopt_env)
      : CompilerDeoptInfo(deopt_id, reason, flags, deopt_env), entry_label_() {
    ASSERT(reason != ICData::kDeoptAtCall);
  }

  Label* entry_label() { return &entry_label_; }

  // Implementation is in architecture specific file.
  virtual void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix);

  const char* Name() const {
    const char* kFormat = "Deopt stub for id %d, reason: %s";
    const intptr_t len = OS::SNPrint(NULL, 0, kFormat,
        deopt_id(), DeoptReasonToCString(reason())) + 1;
    char* chars = Thread::Current()->zone()->Alloc<char>(len);
    OS::SNPrint(chars, len, kFormat,
        deopt_id(), DeoptReasonToCString(reason()));
    return chars;
  }

 private:
  Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(CompilerDeoptInfoWithStub);
};


class SlowPathCode : public ZoneAllocated {
 public:
  SlowPathCode() : entry_label_(), exit_label_() { }
  virtual ~SlowPathCode() { }

  Label* entry_label() { return &entry_label_; }
  Label* exit_label() { return &exit_label_; }

  void GenerateCode(FlowGraphCompiler* compiler) {
    EmitNativeCode(compiler);
    ASSERT(entry_label_.IsBound());
  }

 private:
  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

  Label entry_label_;
  Label exit_label_;

  DISALLOW_COPY_AND_ASSIGN(SlowPathCode);
};


class MegamorphicSlowPath : public SlowPathCode {
 public:
  MegamorphicSlowPath(const ICData& ic_data,
                      intptr_t argument_count,
                      intptr_t deopt_id,
                      TokenPosition token_pos,
                      LocationSummary* locs,
                      intptr_t try_index)
    : SlowPathCode(),
      ic_data_(ic_data),
      argument_count_(argument_count),
      deopt_id_(deopt_id),
      token_pos_(token_pos),
      locs_(locs),
      try_index_(try_index) {}
  virtual ~MegamorphicSlowPath() {}

 private:
  virtual void EmitNativeCode(FlowGraphCompiler* comp);

  const ICData& ic_data_;
  intptr_t argument_count_;
  intptr_t deopt_id_;
  TokenPosition token_pos_;
  LocationSummary* locs_;
  const intptr_t try_index_;  // For try/catch ranges.

  DISALLOW_COPY_AND_ASSIGN(MegamorphicSlowPath);
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
        : block_label_(),
          jump_label_(&block_label_),
          next_nonempty_label_(NULL),
          is_marked_(false) {}

    // The label to jump to when control is transferred to this block.  For
    // nonempty blocks it is the label of the block itself.  For empty
    // blocks it is the label of the first nonempty successor block.
    Label* jump_label() const { return jump_label_; }
    void set_jump_label(Label* label) { jump_label_ = label; }

    // The label of the first nonempty block after this one in the block
    // order, or NULL if there is no nonempty block following this one.
    Label* next_nonempty_label() const { return next_nonempty_label_; }
    void set_next_nonempty_label(Label* label) { next_nonempty_label_ = label; }

    bool WasCompacted() const {
      return jump_label_ != &block_label_;
    }

    // Block compaction is recursive.  Block info for already-compacted
    // blocks is marked so as to avoid cycles in the graph.
    bool is_marked() const { return is_marked_; }
    void mark() { is_marked_ = true; }

   private:
    Label block_label_;

    Label* jump_label_;
    Label* next_nonempty_label_;

    bool is_marked_;
  };

 public:
  FlowGraphCompiler(
      Assembler* assembler,
      FlowGraph* flow_graph,
      const ParsedFunction& parsed_function,
      bool is_optimizing,
      const GrowableArray<const Function*>& inline_id_to_function,
      const GrowableArray<TokenPosition>& inline_id_to_token_pos,
      const GrowableArray<intptr_t>& caller_inline_id);

  ~FlowGraphCompiler();

  static bool SupportsUnboxedDoubles();
  static bool SupportsUnboxedMints();
  static bool SupportsSinCos();
  static bool SupportsUnboxedSimd128();
  static bool SupportsHardwareDivision();
  static bool CanConvertUnboxedMintToDouble();

  static bool IsUnboxedField(const Field& field);
  static bool IsPotentialUnboxedField(const Field& field);

  // Accessors.
  Assembler* assembler() const { return assembler_; }
  const ParsedFunction& parsed_function() const { return parsed_function_; }
  const GrowableArray<BlockEntryInstr*>& block_order() const {
    return block_order_;
  }

  const FlowGraph& flow_graph() const { return flow_graph_; }

  DescriptorList* pc_descriptors_list() const {
    return pc_descriptors_list_;
  }
  BlockEntryInstr* current_block() const { return current_block_; }
  void set_current_block(BlockEntryInstr* value) {
    current_block_ = value;
  }
  static bool CanOptimize();
  bool CanOptimizeFunction() const;
  bool CanOSRFunction() const;
  bool is_optimizing() const { return is_optimizing_; }

  void EnterIntrinsicMode();
  void ExitIntrinsicMode();
  bool intrinsic_mode() const { return intrinsic_mode_; }

  Label* intrinsic_slow_path_label() {
    return &intrinsic_slow_path_label_;
  }

  bool ForceSlowPathForStackOverflow() const;

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

  // Returns 'true' if regular code generation should be skipped.
  bool TryIntrinsify();

  void GenerateAssertAssignable(TokenPosition token_pos,
                                intptr_t deopt_id,
                                const AbstractType& dst_type,
                                const String& dst_name,
                                LocationSummary* locs);

  // DBC emits calls very differently from all other architectures due to its
  // interpreted nature.
#if !defined(TARGET_ARCH_DBC)
  void GenerateRuntimeCall(TokenPosition token_pos,
                           intptr_t deopt_id,
                           const RuntimeEntry& entry,
                           intptr_t argument_count,
                           LocationSummary* locs);

  void GenerateCall(TokenPosition token_pos,
                    const StubEntry& stub_entry,
                    RawPcDescriptors::Kind kind,
                    LocationSummary* locs);

  void GenerateDartCall(intptr_t deopt_id,
                        TokenPosition token_pos,
                        const StubEntry& stub_entry,
                        RawPcDescriptors::Kind kind,
                        LocationSummary* locs);
  void GenerateStaticDartCall(intptr_t deopt_id,
                              TokenPosition token_pos,
                              const StubEntry& stub_entry,
                              RawPcDescriptors::Kind kind,
                              LocationSummary* locs,
                              const Function& target);

  void GenerateInstanceOf(TokenPosition token_pos,
                          intptr_t deopt_id,
                          const AbstractType& type,
                          bool negate_result,
                          LocationSummary* locs);

  void GenerateInstanceCall(intptr_t deopt_id,
                            TokenPosition token_pos,
                            intptr_t argument_count,
                            LocationSummary* locs,
                            const ICData& ic_data);

  void GenerateStaticCall(intptr_t deopt_id,
                          TokenPosition token_pos,
                          const Function& function,
                          intptr_t argument_count,
                          const Array& argument_names,
                          LocationSummary* locs,
                          const ICData& ic_data);

  void GenerateNumberTypeCheck(Register kClassIdReg,
                               const AbstractType& type,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateStringTypeCheck(Register kClassIdReg,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateListTypeCheck(Register kClassIdReg,
                             Label* is_instance_lbl);

  void EmitOptimizedInstanceCall(const StubEntry& stub_entry,
                                 const ICData& ic_data,
                                 intptr_t argument_count,
                                 intptr_t deopt_id,
                                 TokenPosition token_pos,
                                 LocationSummary* locs);

  void EmitInstanceCall(const StubEntry& stub_entry,
                        const ICData& ic_data,
                        intptr_t argument_count,
                        intptr_t deopt_id,
                        TokenPosition token_pos,
                        LocationSummary* locs);

  void EmitPolymorphicInstanceCall(const ICData& ic_data,
                                   intptr_t argument_count,
                                   const Array& argument_names,
                                   intptr_t deopt_id,
                                   TokenPosition token_pos,
                                   LocationSummary* locs,
                                   bool complete);

  // Pass a value for try-index where block is not available (e.g. slow path).
  void EmitMegamorphicInstanceCall(
      const ICData& ic_data,
      intptr_t argument_count,
      intptr_t deopt_id,
      TokenPosition token_pos,
      LocationSummary* locs,
      intptr_t try_index,
      intptr_t slow_path_argument_count = 0);

  void EmitSwitchableInstanceCall(const ICData& ic_data,
                                  intptr_t argument_count,
                                  intptr_t deopt_id,
                                  TokenPosition token_pos,
                                  LocationSummary* locs);

  void EmitTestAndCall(const ICData& ic_data,
                       intptr_t arg_count,
                       const Array& arg_names,
                       Label* failed,
                       Label* match_found,
                       intptr_t deopt_id,
                       TokenPosition token_index,
                       LocationSummary* locs,
                       bool complete);

  Condition EmitEqualityRegConstCompare(Register reg,
                                        const Object& obj,
                                        bool needs_number_check,
                                        TokenPosition token_pos);
  Condition EmitEqualityRegRegCompare(Register left,
                                      Register right,
                                      bool needs_number_check,
                                      TokenPosition token_pos);

  bool NeedsEdgeCounter(TargetEntryInstr* block);

  void EmitEdgeCounter(intptr_t edge_id);
#endif  // !defined(TARGET_ARCH_DBC)

  void EmitTrySync(Instruction* instr, intptr_t try_index);

  void EmitComment(Instruction* instr);

  intptr_t StackSize() const;

  // Returns assembler label associated with the given block entry.
  Label* GetJumpLabel(BlockEntryInstr* block_entry) const;
  bool WasCompacted(BlockEntryInstr* block_entry) const;

  // Returns the label of the fall-through of the current block.
  Label* NextNonEmptyLabel() const;

  // Returns true if there is a next block after the current one in
  // the block order and if it is the given block.
  bool CanFallThroughTo(BlockEntryInstr* block_entry) const;

  // Return true-, false- and fall-through label for a branch instruction.
  BranchLabels CreateBranchLabels(BranchInstr* branch) const;

  void AddExceptionHandler(intptr_t try_index,
                           intptr_t outer_try_index,
                           intptr_t pc_offset,
                           const Array& handler_types,
                           bool needs_stacktrace);
  void SetNeedsStacktrace(intptr_t try_index);
  void AddCurrentDescriptor(RawPcDescriptors::Kind kind,
                            intptr_t deopt_id,
                            TokenPosition token_pos);

  void RecordSafepoint(LocationSummary* locs,
                       intptr_t slow_path_argument_count = 0);

  Label* AddDeoptStub(intptr_t deopt_id,
                      ICData::DeoptReasonId reason,
                      uint32_t flags = 0);

#if defined(TARGET_ARCH_DBC)
  void EmitDeopt(intptr_t deopt_id,
                 ICData::DeoptReasonId reason,
                 uint32_t flags = 0);

  // If the cid does not fit in 16 bits, then this will cause a bailout.
  uint16_t ToEmbeddableCid(intptr_t cid, Instruction* instruction);
#endif  // defined(TARGET_ARCH_DBC)

  void AddDeoptIndexAtCall(intptr_t deopt_id, TokenPosition token_pos);

  void AddSlowPathCode(SlowPathCode* slow_path);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  RawArray* CreateDeoptInfo(Assembler* assembler);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeStaticCallTargetsTable(const Code& code);

  const Class& double_class() const { return double_class_; }
  const Class& mint_class() const { return mint_class_; }
  const Class& float32x4_class() const { return float32x4_class_; }
  const Class& float64x2_class() const { return float64x2_class_; }
  const Class& int32x4_class() const { return int32x4_class_; }

  const Class& BoxClassFor(Representation rep);

  void SaveLiveRegisters(LocationSummary* locs);
  void RestoreLiveRegisters(LocationSummary* locs);
#if defined(DEBUG)
  void ClobberDeadTempRegisters(LocationSummary* locs);
#endif

  Environment* SlowPathEnvironmentFor(Instruction* instruction);

  intptr_t CurrentTryIndex() const {
    if (current_block_ == NULL) {
      return CatchClauseNode::kInvalidTryIndex;
    }
    return current_block_->try_index();
  }

  bool may_reoptimize() const { return may_reoptimize_; }

  // Returns 'sorted' array in decreasing count order.
  static void SortICDataByCount(const ICData& ic_data,
                                GrowableArray<CidTarget>* sorted,
                                bool drop_smi);

  // Use in unoptimized compilation to preserve/reuse ICData.
  const ICData* GetOrAddInstanceCallICData(intptr_t deopt_id,
                                           const String& target_name,
                                           const Array& arguments_descriptor,
                                           intptr_t num_args_tested);

  const ICData* GetOrAddStaticCallICData(intptr_t deopt_id,
                                         const Function& target,
                                         const Array& arguments_descriptor,
                                         intptr_t num_args_tested);

  const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data() const {
    return *deopt_id_to_ic_data_;
  }

  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return thread_->isolate(); }
  Zone* zone() const { return zone_; }

  void AddStubCallTarget(const Code& code);

  const Array& inlined_code_intervals() const {
    return inlined_code_intervals_;
  }

  RawArray* edge_counters_array() const {
    return edge_counters_array_.raw();
  }

  RawArray* InliningIdToFunction() const;
  RawArray* InliningIdToTokenPos() const;
  RawArray* CallerInliningIdMap() const;

  CodeSourceMapBuilder* code_source_map_builder() {
    if (code_source_map_builder_ == NULL) {
      code_source_map_builder_ = new CodeSourceMapBuilder();
    }
    ASSERT(code_source_map_builder_ != NULL);
    return code_source_map_builder_;
  }

  void BeginCodeSourceRange();
  bool EndCodeSourceRange(TokenPosition token_pos);

#if defined(TARGET_ARCH_DBC)
  void RecordAfterCall(Instruction* instr);
#endif

 private:
  friend class CheckStackOverflowSlowPath;  // For pending_deoptimization_env_.

  static bool ShouldInlineSmiStringHashCode(const ICData& ic_data);

  void EmitFrameEntry();

  void AddStaticCallTarget(const Function& function);

  void GenerateDeferredCode();

  void EmitInstructionPrologue(Instruction* instr);
  void EmitInstructionEpilogue(Instruction* instr);

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  void EmitOptimizedStaticCall(const Function& function,
                               const Array& arguments_descriptor,
                               intptr_t argument_count,
                               intptr_t deopt_id,
                               TokenPosition token_pos,
                               LocationSummary* locs);

  void EmitUnoptimizedStaticCall(intptr_t argument_count,
                                 intptr_t deopt_id,
                                 TokenPosition token_pos,
                                 LocationSummary* locs,
                                 const ICData& ic_data);

  // DBC handles type tests differently from all other architectures due
  // to its interpreted nature.
#if !defined(TARGET_ARCH_DBC)
  // Type checking helper methods.
  void CheckClassIds(Register class_id_reg,
                     const GrowableArray<intptr_t>& class_ids,
                     Label* is_instance_lbl,
                     Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateInlineInstanceof(TokenPosition token_pos,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateInstantiatedTypeWithArgumentsTest(
      TokenPosition token_pos,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_lbl);

  bool GenerateInstantiatedTypeNoArgumentsTest(TokenPosition token_pos,
                                               const AbstractType& dst_type,
                                               Label* is_instance_lbl,
                                               Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateUninstantiatedTypeTest(
      TokenPosition token_pos,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_label);

  RawSubtypeTestCache* GenerateSubtype1TestCacheLookup(
      TokenPosition token_pos,
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
#endif  // !defined(TARGET_ARCH_DBC)

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

  void CompactBlock(BlockEntryInstr* block);
  void CompactBlocks();

  bool IsListClass(const Class& cls) const {
    return cls.raw() == list_class_.raw();
  }

  void EmitSourceLine(Instruction* instr);

  intptr_t GetOptimizationThreshold() const;

  StackmapTableBuilder* stackmap_table_builder() {
    if (stackmap_table_builder_ == NULL) {
      stackmap_table_builder_ = new StackmapTableBuilder();
    }
    return stackmap_table_builder_;
  }

  // TODO(vegorov) re-enable frame state tracking on DBC. It is
  // currently disabled because it relies on LocationSummaries and
  // we don't use them during unoptimized compilation on DBC.
#if defined(DEBUG) && !defined(TARGET_ARCH_DBC)
  void FrameStateUpdateWith(Instruction* instr);
  void FrameStatePush(Definition* defn);
  void FrameStatePop(intptr_t count);
  bool FrameStateIsSafeToCall();
  void FrameStateClear();
#endif

  // This struct contains either function or code, the other one being NULL.
  class StaticCallsStruct : public ZoneAllocated {
   public:
    const intptr_t offset;
    const Function* function;  // Can be NULL.
    const Code* code;          // Can be NULL.
    StaticCallsStruct(intptr_t offset_arg,
                      const Function* function_arg,
                      const Code* code_arg)
        : offset(offset_arg), function(function_arg), code(code_arg) {
      ASSERT((function == NULL) || function->IsZoneHandle());
      ASSERT((code == NULL) || code->IsZoneHandle());
    }

   private:
    DISALLOW_COPY_AND_ASSIGN(StaticCallsStruct);
  };

  Thread* thread_;
  Zone* zone_;
  Assembler* assembler_;
  const ParsedFunction& parsed_function_;
  const FlowGraph& flow_graph_;
  const GrowableArray<BlockEntryInstr*>& block_order_;

#if defined(DEBUG)
  GrowableArray<Representation> frame_state_;
#endif

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  BlockEntryInstr* current_block_;
  ExceptionHandlerList* exception_handlers_list_;
  DescriptorList* pc_descriptors_list_;
  StackmapTableBuilder* stackmap_table_builder_;
  CodeSourceMapBuilder* code_source_map_builder_;
  intptr_t saved_code_size_;
  GrowableArray<BlockInfo*> block_info_;
  GrowableArray<CompilerDeoptInfo*> deopt_infos_;
  GrowableArray<SlowPathCode*> slow_path_code_;
  // Stores static call targets as well as stub targets.
  // TODO(srdjan): Evaluate if we should store allocation stub targets into a
  // separate table?
  GrowableArray<StaticCallsStruct*> static_calls_target_table_;
  const bool is_optimizing_;
  // Set to true if optimized code has IC calls.
  bool may_reoptimize_;
  // True while emitting intrinsic code.
  bool intrinsic_mode_;
  Label intrinsic_slow_path_label_;

  const Class& double_class_;
  const Class& mint_class_;
  const Class& float32x4_class_;
  const Class& float64x2_class_;
  const Class& int32x4_class_;
  const Class& list_class_;

  ParallelMoveResolver parallel_move_resolver_;

  // Currently instructions generate deopt stubs internally by
  // calling AddDeoptStub.  To communicate deoptimization environment
  // that should be used when deoptimizing we store it in this variable.
  // In future AddDeoptStub should be moved out of the instruction template.
  Environment* pending_deoptimization_env_;

  intptr_t lazy_deopt_pc_offset_;

  ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data_;

  Array& edge_counters_array_;

  Array& inlined_code_intervals_;
  const GrowableArray<const Function*>& inline_id_to_function_;
  const GrowableArray<TokenPosition>& inline_id_to_token_pos_;
  const GrowableArray<intptr_t>& caller_inline_id_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_H_
