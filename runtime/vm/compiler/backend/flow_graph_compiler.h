// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_COMPILER_H_
#define RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_COMPILER_H_

#include "vm/compiler/runtime_api.h"
#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <functional>

#include "vm/allocation.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/locations.h"
#include "vm/runtime_entry.h"

namespace dart {

// Forward declarations.
class CatchEntryMovesMapBuilder;
class Code;
class DeoptInfoBuilder;
class FlowGraph;
class FlowGraphCompiler;
class Function;
template <typename T>
class GrowableArray;
class ParsedFunction;
class SpeculativeInliningPolicy;

namespace compiler {
struct TableSelector;
}

// Used in methods which need conditional access to a temporary register.
// May only be used to allocate a single temporary register.
class TemporaryRegisterAllocator : public ValueObject {
 public:
  virtual ~TemporaryRegisterAllocator() {}
  virtual Register AllocateTemporary() = 0;
  virtual void ReleaseTemporary() = 0;
};

class ConstantTemporaryAllocator : public TemporaryRegisterAllocator {
 public:
  explicit ConstantTemporaryAllocator(Register tmp) : tmp_(tmp) {}

  Register AllocateTemporary() override { return tmp_; }
  void ReleaseTemporary() override {}

 private:
  Register const tmp_;
};

class NoTemporaryAllocator : public TemporaryRegisterAllocator {
 public:
  Register AllocateTemporary() override { UNREACHABLE(); }
  void ReleaseTemporary() override { UNREACHABLE(); }
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
    ASSERT(deopt_env != nullptr);
  }
  virtual ~CompilerDeoptInfo() {}

  TypedDataPtr CreateDeoptInfo(FlowGraphCompiler* compiler,
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

  void AllocateOutgoingArguments(Environment* env);

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

  compiler::Label* entry_label() { return &entry_label_; }

  // Implementation is in architecture specific file.
  virtual void GenerateCode(FlowGraphCompiler* compiler, intptr_t stub_ix);

  const char* Name() const {
    const char* kFormat = "Deopt stub for id %d, reason: %s";
    const intptr_t len = Utils::SNPrint(nullptr, 0, kFormat, deopt_id(),
                                        DeoptReasonToCString(reason())) +
                         1;
    char* chars = Thread::Current()->zone()->Alloc<char>(len);
    Utils::SNPrint(chars, len, kFormat, deopt_id(),
                   DeoptReasonToCString(reason()));
    return chars;
  }

 private:
  compiler::Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(CompilerDeoptInfoWithStub);
};

class SlowPathCode : public ZoneAllocated {
 public:
  explicit SlowPathCode(Instruction* instruction)
      : instruction_(instruction), entry_label_(), exit_label_() {}
  virtual ~SlowPathCode() {}

  Instruction* instruction() const { return instruction_; }
  compiler::Label* entry_label() { return &entry_label_; }
  compiler::Label* exit_label() { return &exit_label_; }

  void GenerateCode(FlowGraphCompiler* compiler) {
    EmitNativeCode(compiler);
    ASSERT(entry_label_.IsBound());
  }

 private:
  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

  Instruction* instruction_;
  compiler::Label entry_label_;
  compiler::Label exit_label_;

  DISALLOW_COPY_AND_ASSIGN(SlowPathCode);
};

template <typename T>
class TemplateSlowPathCode : public SlowPathCode {
 public:
  explicit TemplateSlowPathCode(T* instruction) : SlowPathCode(instruction) {}

  T* instruction() const {
    return static_cast<T*>(SlowPathCode::instruction());
  }
};

class BoxAllocationSlowPath : public TemplateSlowPathCode<Instruction> {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : TemplateSlowPathCode(instruction), cls_(cls), result_(result) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp);

 private:
  const Class& cls_;
  const Register result_;
};

class DoubleToIntegerSlowPath
    : public TemplateSlowPathCode<DoubleToIntegerInstr> {
 public:
  DoubleToIntegerSlowPath(DoubleToIntegerInstr* instruction,
                          FpuRegister value_reg)
      : TemplateSlowPathCode(instruction), value_reg_(value_reg) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

 private:
  FpuRegister value_reg_;
};

// Slow path code which calls runtime entry to throw an exception.
class ThrowErrorSlowPathCode : public TemplateSlowPathCode<Instruction> {
 public:
  ThrowErrorSlowPathCode(Instruction* instruction,
                         const RuntimeEntry& runtime_entry)
      : TemplateSlowPathCode(instruction), runtime_entry_(runtime_entry) {}

  // This name appears in disassembly.
  virtual const char* name() = 0;

  // Subclasses can override these methods to customize slow path code.
  virtual void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) {}
  virtual void AddMetadataForRuntimeCall(FlowGraphCompiler* compiler) {}
  virtual void PushArgumentsForRuntimeCall(FlowGraphCompiler* compiler) {}

  // Returns number of arguments for runtime call (if shared stub is not used).
  virtual intptr_t GetNumberOfArgumentsForRuntimeCall() { return 0; }

  virtual void EmitSharedStubCall(FlowGraphCompiler* compiler,
                                  bool save_fpu_registers) {
    UNREACHABLE();
  }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

 private:
  const RuntimeEntry& runtime_entry_;
};

class NullErrorSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit NullErrorSlowPath(CheckNullInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               GetRuntimeEntry(instruction->exception_type())) {
  }

  CheckNullInstr::ExceptionType exception_type() const {
    return instruction()->AsCheckNull()->exception_type();
  }

  const char* name() override;

  void EmitSharedStubCall(FlowGraphCompiler* compiler,
                          bool save_fpu_registers) override;

  void AddMetadataForRuntimeCall(FlowGraphCompiler* compiler) override {
    CheckNullInstr::AddMetadataForRuntimeCall(instruction()->AsCheckNull(),
                                              compiler);
  }

  static CodePtr GetStub(FlowGraphCompiler* compiler,
                         CheckNullInstr::ExceptionType exception_type,
                         bool save_fpu_registers);

 private:
  static const RuntimeEntry& GetRuntimeEntry(
      CheckNullInstr::ExceptionType exception_type);
};

class RangeErrorSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit RangeErrorSlowPath(GenericCheckBoundInstr* instruction)
      : ThrowErrorSlowPathCode(instruction, kRangeErrorRuntimeEntry) {}
  virtual const char* name() { return "check bound"; }

  virtual intptr_t GetNumberOfArgumentsForRuntimeCall() {
    return 2;  // length and index
  }

  virtual void PushArgumentsForRuntimeCall(FlowGraphCompiler* compiler);

  virtual void EmitSharedStubCall(FlowGraphCompiler* compiler,
                                  bool save_fpu_registers);
};

class WriteErrorSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit WriteErrorSlowPath(CheckWritableInstr* instruction)
      : ThrowErrorSlowPathCode(instruction, kWriteErrorRuntimeEntry) {}
  virtual const char* name() { return "check writable"; }

  virtual void EmitSharedStubCall(FlowGraphCompiler* compiler,
                                  bool save_fpu_registers);
};

class LateInitializationErrorSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit LateInitializationErrorSlowPath(Instruction* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kLateFieldNotInitializedErrorRuntimeEntry) {
    ASSERT(instruction->IsLoadField() || instruction->IsLoadStaticField());
  }
  virtual const char* name() { return "late initialization error"; }

  virtual intptr_t GetNumberOfArgumentsForRuntimeCall() {
    return 1;  // field
  }

  virtual void PushArgumentsForRuntimeCall(FlowGraphCompiler* compiler);

  virtual void EmitSharedStubCall(FlowGraphCompiler* compiler,
                                  bool save_fpu_registers);

 private:
  FieldPtr OriginalField() const {
    return instruction()->IsLoadField()
               ? instruction()->AsLoadField()->slot().field().Original()
               : instruction()->AsLoadStaticField()->field().Original();
  }
};

class FlowGraphCompiler : public ValueObject {
 private:
  class BlockInfo : public ZoneAllocated {
   public:
    BlockInfo()
        : block_label_(),
          jump_label_(&block_label_),
          next_nonempty_label_(nullptr),
          is_marked_(false) {}

    // The label to jump to when control is transferred to this block.  For
    // nonempty blocks it is the label of the block itself.  For empty
    // blocks it is the label of the first nonempty successor block.
    compiler::Label* jump_label() const { return jump_label_; }
    void set_jump_label(compiler::Label* label) { jump_label_ = label; }

    // The label of the first nonempty block after this one in the block
    // order, or nullptr if there is no nonempty block following this one.
    compiler::Label* next_nonempty_label() const {
      return next_nonempty_label_;
    }
    void set_next_nonempty_label(compiler::Label* label) {
      next_nonempty_label_ = label;
    }

    bool WasCompacted() const { return jump_label_ != &block_label_; }

    // Block compaction is recursive.  Block info for already-compacted
    // blocks is marked so as to avoid cycles in the graph.
    bool is_marked() const { return is_marked_; }
    void mark() { is_marked_ = true; }

   private:
    compiler::Label block_label_;

    compiler::Label* jump_label_;
    compiler::Label* next_nonempty_label_;

    bool is_marked_;
  };

 public:
  FlowGraphCompiler(compiler::Assembler* assembler,
                    FlowGraph* flow_graph,
                    const ParsedFunction& parsed_function,
                    bool is_optimizing,
                    SpeculativeInliningPolicy* speculative_policy,
                    const GrowableArray<const Function*>& inline_id_to_function,
                    const GrowableArray<TokenPosition>& inline_id_to_token_pos,
                    const GrowableArray<intptr_t>& caller_inline_id,
                    ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
                    CodeStatistics* stats = nullptr);

  void ArchSpecificInitialization();

  ~FlowGraphCompiler();

  static bool SupportsUnboxedDoubles();
  static bool SupportsUnboxedSimd128();
  static bool CanConvertInt64ToDouble();

  // Accessors.
  compiler::Assembler* assembler() const { return assembler_; }
  const ParsedFunction& parsed_function() const { return parsed_function_; }
  const Function& function() const { return parsed_function_.function(); }
  const GrowableArray<BlockEntryInstr*>& block_order() const {
    return block_order_;
  }
  const GrowableArray<const compiler::TableSelector*>&
  dispatch_table_call_targets() const {
    return dispatch_table_call_targets_;
  }

  // If 'ForcedOptimization()' returns 'true', we are compiling in optimized
  // mode for a function which cannot deoptimize. Certain optimizations, e.g.
  // speculative optimizations and call patching are disabled.
  bool ForcedOptimization() const { return function().ForceOptimize(); }

  const FlowGraph& flow_graph() const {
    return intrinsic_mode() ? *intrinsic_flow_graph_ : flow_graph_;
  }

  BlockEntryInstr* current_block() const { return current_block_; }
  void set_current_block(BlockEntryInstr* value) { current_block_ = value; }

  Instruction* current_instruction() const { return current_instruction_; }

  bool CanOptimize() const;
  bool CanOptimizeFunction() const;
  bool CanOSRFunction() const;
  bool is_optimizing() const { return is_optimizing_; }

  void InsertBSSRelocation(BSS::Relocation reloc);
  void LoadBSSEntry(BSS::Relocation relocation, Register dst, Register tmp);

  // The function was fully intrinsified, so the body is unreachable.
  //
  // We still need to compile the body in unoptimized mode because the
  // 'ICData's are added to the function's 'ic_data_array_' when instance
  // calls are compiled.
  bool skip_body_compilation() const {
    return fully_intrinsified_ && is_optimizing();
  }

  void EnterIntrinsicMode();
  void ExitIntrinsicMode();
  bool intrinsic_mode() const { return intrinsic_mode_; }

  void set_intrinsic_flow_graph(const FlowGraph& flow_graph) {
    intrinsic_flow_graph_ = &flow_graph;
  }

  void set_intrinsic_slow_path_label(compiler::Label* label) {
    ASSERT(intrinsic_slow_path_label_ == nullptr || label == nullptr);
    intrinsic_slow_path_label_ = label;
  }
  compiler::Label* intrinsic_slow_path_label() const {
    ASSERT(intrinsic_slow_path_label_ != nullptr);
    return intrinsic_slow_path_label_;
  }

  bool ForceSlowPathForStackOverflow() const;

  const GrowableArray<BlockInfo*>& block_info() const { return block_info_; }

  void StatsBegin(Instruction* instr) {
    if (stats_ != nullptr) stats_->Begin(instr);
  }

  void StatsEnd(Instruction* instr) {
    if (stats_ != nullptr) stats_->End(instr);
  }

  void SpecialStatsBegin(intptr_t tag) {
    if (stats_ != nullptr) stats_->SpecialBegin(tag);
  }

  void SpecialStatsEnd(intptr_t tag) {
    if (stats_ != nullptr) stats_->SpecialEnd(tag);
  }

  GrowableArray<const Field*>& used_static_fields() {
    return used_static_fields_;
  }

  // Constructor is lightweight, major initialization work should occur here.
  // This makes it easier to measure time spent in the compiler.
  void InitCompiler();

  void CompileGraph();

  void EmitPrologue();

  void VisitBlocks();

  void EmitFunctionEntrySourcePositionDescriptorIfNeeded();

  // Bail out of the flow graph compiler. Does not return to the caller.
  void Bailout(const char* reason);

  // Returns 'true' if regular code generation should be skipped.
  bool TryIntrinsify();

  // Emits code for a generic move from a location 'src' to a location 'dst'.
  //
  // Note that Location does not include a size (that can only be deduced from
  // a Representation), so these moves might overapproximate the size needed
  // to move. The maximal overapproximation is moving 8 bytes instead of 4 on
  // 64 bit architectures. This overapproximation is not a problem, because
  // the Dart calling convention only uses word-sized stack slots.
  //
  // TODO(dartbug.com/40400): Express this in terms of EmitMove(NativeLocation
  // NativeLocation) to remove code duplication.
  void EmitMove(Location dst, Location src, TemporaryRegisterAllocator* temp);

  // Emits code for a move from a location `src` to a location `dst`.
  //
  // Takes into account the payload and container representations of `dst` and
  // `src` to do the smallest move possible, and sign (or zero) extend or
  // truncate if needed.
  //
  // Makes use of TMP, FpuTMP, and `temp`.
  void EmitNativeMove(const compiler::ffi::NativeLocation& dst,
                      const compiler::ffi::NativeLocation& src,
                      TemporaryRegisterAllocator* temp);

  // Helper method to move from a Location to a NativeLocation.
  void EmitMoveToNative(const compiler::ffi::NativeLocation& dst,
                        Location src_loc,
                        Representation src_type,
                        TemporaryRegisterAllocator* temp);

  // Helper method to move from a NativeLocation to a Location.
  void EmitMoveFromNative(Location dst_loc,
                          Representation dst_type,
                          const compiler::ffi::NativeLocation& src,
                          TemporaryRegisterAllocator* temp);

  // Helper method to move a Dart const to a native location.
  void EmitMoveConst(const compiler::ffi::NativeLocation& dst,
                     Location src,
                     Representation src_type,
                     TemporaryRegisterAllocator* temp);

  bool CheckAssertAssignableTypeTestingABILocations(
      const LocationSummary& locs);

  void GenerateAssertAssignable(CompileType* receiver_type,
                                const InstructionSource& source,
                                intptr_t deopt_id,
                                Environment* env,
                                const String& dst_name,
                                LocationSummary* locs);

#if !defined(TARGET_ARCH_IA32)
  void GenerateCallerChecksForAssertAssignable(CompileType* receiver_type,
                                               const AbstractType& dst_type,
                                               compiler::Label* done);

  void GenerateTTSCall(const InstructionSource& source,
                       intptr_t deopt_id,
                       Environment* env,
                       Register reg_with_type,
                       const AbstractType& dst_type,
                       const String& dst_name,
                       LocationSummary* locs);

  static void GenerateIndirectTTSCall(compiler::Assembler* assembler,
                                      Register reg_with_type,
                                      intptr_t sub_type_cache_index);
#endif

  void GenerateStubCall(const InstructionSource& source,
                        const Code& stub,
                        UntaggedPcDescriptors::Kind kind,
                        LocationSummary* locs,
                        intptr_t deopt_id,
                        Environment* env);

  void GenerateNonLazyDeoptableStubCall(
      const InstructionSource& source,
      const Code& stub,
      UntaggedPcDescriptors::Kind kind,
      LocationSummary* locs,
      ObjectPool::SnapshotBehavior snapshot_behavior =
          compiler::ObjectPoolBuilderEntry::kSnapshotable);

  void GeneratePatchableCall(
      const InstructionSource& source,
      const Code& stub,
      UntaggedPcDescriptors::Kind kind,
      LocationSummary* locs,
      ObjectPool::SnapshotBehavior snapshot_behavior =
          compiler::ObjectPoolBuilderEntry::kSnapshotable);

  void GenerateDartCall(intptr_t deopt_id,
                        const InstructionSource& source,
                        const Code& stub,
                        UntaggedPcDescriptors::Kind kind,
                        LocationSummary* locs,
                        Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  void GenerateStaticDartCall(
      intptr_t deopt_id,
      const InstructionSource& source,
      UntaggedPcDescriptors::Kind kind,
      LocationSummary* locs,
      const Function& target,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  void GenerateInstanceOf(const InstructionSource& source,
                          intptr_t deopt_id,
                          Environment* env,
                          const AbstractType& type,
                          LocationSummary* locs);

  void GenerateInstanceCall(intptr_t deopt_id,
                            const InstructionSource& source,
                            LocationSummary* locs,
                            const ICData& ic_data,
                            Code::EntryKind entry_kind,
                            bool receiver_can_be_smi);

  void GenerateStaticCall(
      intptr_t deopt_id,
      const InstructionSource& source,
      const Function& function,
      ArgumentsInfo args_info,
      LocationSummary* locs,
      const ICData& ic_data_in,
      ICData::RebindRule rebind_rule,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  void GenerateNumberTypeCheck(Register kClassIdReg,
                               const AbstractType& type,
                               compiler::Label* is_instance_lbl,
                               compiler::Label* is_not_instance_lbl);
  void GenerateStringTypeCheck(Register kClassIdReg,
                               compiler::Label* is_instance_lbl,
                               compiler::Label* is_not_instance_lbl);
  void GenerateListTypeCheck(Register kClassIdReg,
                             compiler::Label* is_instance_lbl);

  // Returns true if no further checks are necessary but the code coming after
  // the emitted code here is still required do a runtime call (for the negative
  // case of throwing an exception).
  bool GenerateSubtypeRangeCheck(Register class_id_reg,
                                 const Class& type_class,
                                 compiler::Label* is_subtype_lbl);

  // We test up to 4 different cid ranges, if we would need to test more in
  // order to get a definite answer we fall back to the old mechanism (namely
  // of going into the subtyping cache)
  static constexpr intptr_t kMaxNumberOfCidRangesToTest = 4;

  // If [fall_through_if_inside] is `true`, then [outside_range_lbl] must be
  // supplied, since it will be jumped to in the last case if the cid is outside
  // the range.
  //
  // Returns whether [class_id_reg] is clobbered by the check.
  static bool GenerateCidRangesCheck(
      compiler::Assembler* assembler,
      Register class_id_reg,
      const CidRangeVector& cid_ranges,
      compiler::Label* inside_range_lbl,
      compiler::Label* outside_range_lbl = nullptr,
      bool fall_through_if_inside = false);

  void EmitOptimizedInstanceCall(
      const Code& stub,
      const ICData& ic_data,
      intptr_t deopt_id,
      const InstructionSource& source,
      LocationSummary* locs,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  void EmitInstanceCallJIT(const Code& stub,
                           const ICData& ic_data,
                           intptr_t deopt_id,
                           const InstructionSource& source,
                           LocationSummary* locs,
                           Code::EntryKind entry_kind);

  void EmitPolymorphicInstanceCall(const PolymorphicInstanceCallInstr* call,
                                   const CallTargets& targets,
                                   ArgumentsInfo args_info,
                                   intptr_t deopt_id,
                                   const InstructionSource& source,
                                   LocationSummary* locs,
                                   bool complete,
                                   intptr_t total_call_count,
                                   bool receiver_can_be_smi = true);

  void EmitMegamorphicInstanceCall(const ICData& icdata,
                                   intptr_t deopt_id,
                                   const InstructionSource& source,
                                   LocationSummary* locs) {
    const String& name = String::Handle(icdata.target_name());
    const Array& arguments_descriptor =
        Array::Handle(icdata.arguments_descriptor());
    EmitMegamorphicInstanceCall(name, arguments_descriptor, deopt_id, source,
                                locs);
  }

  void EmitMegamorphicInstanceCall(const String& function_name,
                                   const Array& arguments_descriptor,
                                   intptr_t deopt_id,
                                   const InstructionSource& source,
                                   LocationSummary* locs);

  void EmitInstanceCallAOT(
      const ICData& ic_data,
      intptr_t deopt_id,
      const InstructionSource& source,
      LocationSummary* locs,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal,
      bool receiver_can_be_smi = true);

  void EmitTestAndCall(const CallTargets& targets,
                       const String& function_name,
                       ArgumentsInfo args_info,
                       compiler::Label* failed,
                       compiler::Label* match_found,
                       intptr_t deopt_id,
                       const InstructionSource& source_index,
                       LocationSummary* locs,
                       bool complete,
                       intptr_t total_ic_calls,
                       Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  void EmitDispatchTableCall(int32_t selector_offset,
                             const Array& arguments_descriptor);

  Condition EmitEqualityRegConstCompare(Register reg,
                                        const Object& obj,
                                        bool needs_number_check,
                                        const InstructionSource& source,
                                        intptr_t deopt_id);
  Condition EmitEqualityRegRegCompare(Register left,
                                      Register right,
                                      bool needs_number_check,
                                      const InstructionSource& source,
                                      intptr_t deopt_id);
  Condition EmitBoolTest(Register value, BranchLabels labels, bool invert);

  bool NeedsEdgeCounter(BlockEntryInstr* block);

  void EmitEdgeCounter(intptr_t edge_id);

  void RecordCatchEntryMoves(Environment* env);

  void EmitCallToStub(const Code& stub,
                      ObjectPool::SnapshotBehavior snapshot_behavior =
                          compiler::ObjectPoolBuilderEntry::kSnapshotable);
  void EmitJumpToStub(const Code& stub);
  void EmitTailCallToStub(const Code& stub);

  void EmitDropArguments(intptr_t count);

  // Emits the following metadata for the current PC:
  //
  //   * Attaches current try index
  //   * Attaches stackmaps
  //   * Attaches catch entry moves (in AOT)
  //   * Deoptimization information (in JIT)
  //
  // If [env] is not `nullptr` it will be used instead of the
  // `pending_deoptimization_env`.
  void EmitCallsiteMetadata(const InstructionSource& source,
                            intptr_t deopt_id,
                            UntaggedPcDescriptors::Kind kind,
                            LocationSummary* locs,
                            Environment* env);

  void EmitYieldPositionMetadata(const InstructionSource& source,
                                 intptr_t yield_index);

  void EmitComment(Instruction* instr);

  // Returns stack size (number of variables on stack for unoptimized
  // code, or number of spill slots for optimized code).
  intptr_t StackSize() const;

  // Returns the number of extra stack slots used during an Osr entry
  // (values for all [ParameterInstr]s, representing local variables
  // and expression stack values, are already on the stack).
  intptr_t ExtraStackSlotsOnOsrEntry() const;

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
  // Changes the base register of this Location if this allows us to utilize
  // a better addressing mode. For RISC-V, this is the wider range of compressed
  // instructions available for SP-relative load compared to FP-relative loads.
  // Assumes `StackSize` accounts for everything at the point of use.
  Location RebaseIfImprovesAddressing(Location loc) const;
#endif  // defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

  // Returns assembler label associated with the given block entry.
  compiler::Label* GetJumpLabel(BlockEntryInstr* block_entry) const;
  bool WasCompacted(BlockEntryInstr* block_entry) const;

  // Returns the label of the fall-through of the current block.
  compiler::Label* NextNonEmptyLabel() const;

  // Returns true if there is a next block after the current one in
  // the block order and if it is the given block.
  bool CanFallThroughTo(BlockEntryInstr* block_entry) const;

  // Return true-, false- and fall-through label for a branch instruction.
  BranchLabels CreateBranchLabels(BranchInstr* branch) const;

  void AddExceptionHandler(CatchBlockEntryInstr* entry);
  void SetNeedsStackTrace(intptr_t try_index);
  void AddCurrentDescriptor(UntaggedPcDescriptors::Kind kind,
                            intptr_t deopt_id,
                            const InstructionSource& source);
  void AddDescriptor(
      UntaggedPcDescriptors::Kind kind,
      intptr_t pc_offset,
      intptr_t deopt_id,
      const InstructionSource& source,
      intptr_t try_index,
      intptr_t yield_index = UntaggedPcDescriptors::kInvalidYieldIndex);

  // Add NullCheck information for the current PC.
  void AddNullCheck(const InstructionSource& source, const String& name);

  void RecordSafepoint(LocationSummary* locs,
                       intptr_t slow_path_argument_count = 0);

  compiler::Label* AddDeoptStub(intptr_t deopt_id,
                                ICData::DeoptReasonId reason,
                                uint32_t flags = 0);

  CompilerDeoptInfo* AddDeoptIndexAtCall(intptr_t deopt_id, Environment* env);
  CompilerDeoptInfo* AddSlowPathDeoptInfo(intptr_t deopt_id, Environment* env);

  void AddSlowPathCode(SlowPathCode* slow_path);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  ArrayPtr CreateDeoptInfo(compiler::Assembler* assembler);
  void FinalizeStackMaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeCatchEntryMovesMap(const Code& code);
  void FinalizeStaticCallTargetsTable(const Code& code);
  void FinalizeCodeSourceMap(const Code& code);

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

  // Returns a new environment based on [env] which accounts for the new
  // locations of values in the slow path call.
  Environment* SlowPathEnvironmentFor(Instruction* inst,
                                      intptr_t num_slow_path_args) {
    if (inst->env() == nullptr && is_optimizing()) {
      if (pending_deoptimization_env_ == nullptr) {
        return nullptr;
      }
      return SlowPathEnvironmentFor(pending_deoptimization_env_, inst->locs(),
                                    num_slow_path_args);
    }
    return SlowPathEnvironmentFor(inst->env(), inst->locs(),
                                  num_slow_path_args);
  }

  Environment* SlowPathEnvironmentFor(Environment* env,
                                      LocationSummary* locs,
                                      intptr_t num_slow_path_args);

  intptr_t CurrentTryIndex() const {
    if (current_block_ == nullptr) {
      return kInvalidTryIndex;
    }
    return current_block_->try_index();
  }

  bool may_reoptimize() const { return may_reoptimize_; }

  // Use in unoptimized compilation to preserve/reuse ICData.
  //
  // If [binary_smi_target] is non-null and we have to create the ICData, the
  // ICData will get an (kSmiCid, kSmiCid, binary_smi_target) entry.
  const ICData* GetOrAddInstanceCallICData(intptr_t deopt_id,
                                           const String& target_name,
                                           const Array& arguments_descriptor,
                                           intptr_t num_args_tested,
                                           const AbstractType& receiver_type,
                                           const Function& binary_smi_target);

  const ICData* GetOrAddStaticCallICData(intptr_t deopt_id,
                                         const Function& target,
                                         const Array& arguments_descriptor,
                                         intptr_t num_args_tested,
                                         ICData::RebindRule rebind_rule);

  static const CallTargets* ResolveCallTargetsForReceiverCid(
      intptr_t cid,
      const String& selector,
      const Array& args_desc_array);

  const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data() const {
    return *deopt_id_to_ic_data_;
  }

  Thread* thread() const { return thread_; }
  IsolateGroup* isolate_group() const { return thread_->isolate_group(); }
  Zone* zone() const { return zone_; }

  void AddStubCallTarget(const Code& code);
  void AddDispatchTableCallTarget(const compiler::TableSelector* selector);

  ArrayPtr edge_counters_array() const { return edge_counters_array_.ptr(); }

  ArrayPtr InliningIdToFunction() const;

  void BeginCodeSourceRange(const InstructionSource& source);
  void EndCodeSourceRange(const InstructionSource& source);

  static bool LookupMethodFor(int class_id,
                              const String& name,
                              const ArgumentsDescriptor& args_desc,
                              Function* fn_return,
                              bool* class_is_abstract_return = nullptr);

  // Returns new class-id bias.
  //
  // TODO(kustermann): We should move this code out of the [FlowGraphCompiler]!
  static int EmitTestAndCallCheckCid(compiler::Assembler* assembler,
                                     compiler::Label* label,
                                     Register class_id_reg,
                                     const CidRangeValue& range,
                                     int bias,
                                     bool jump_on_miss = true);

  bool IsEmptyBlock(BlockEntryInstr* block) const;

  void EmitOptimizedStaticCall(
      const Function& function,
      const Array& arguments_descriptor,
      intptr_t size_with_type_args,
      intptr_t deopt_id,
      const InstructionSource& source,
      LocationSummary* locs,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal);

 private:
  friend class BoxInt64Instr;            // For AddPcRelativeCallStubTarget().
  friend class CheckNullInstr;           // For AddPcRelativeCallStubTarget().
  friend class NullErrorSlowPath;        // For AddPcRelativeCallStubTarget().
  friend class CheckStackOverflowInstr;  // For AddPcRelativeCallStubTarget().
  friend class StoreIndexedInstr;        // For AddPcRelativeCallStubTarget().
  friend class StoreFieldInstr;          // For AddPcRelativeCallStubTarget().
  friend class CheckStackOverflowSlowPath;  // For pending_deoptimization_env_.
  friend class GraphIntrinsicCodeGenScope;  // For optimizing_.

  // Architecture specific implementation of simple native moves.
  void EmitNativeMoveArchitecture(const compiler::ffi::NativeLocation& dst,
                                  const compiler::ffi::NativeLocation& src);

  void EmitFrameEntry();

  bool TryIntrinsifyHelper();
  void AddPcRelativeCallTarget(const Function& function,
                               Code::EntryKind entry_kind);
  void AddPcRelativeCallStubTarget(const Code& stub_code);
  void AddPcRelativeTailCallStubTarget(const Code& stub_code);
  void AddPcRelativeTTSCallTypeTarget(const AbstractType& type);
  void AddStaticCallTarget(const Function& function,
                           Code::EntryKind entry_kind);

  void GenerateDeferredCode();

  void EmitInstructionPrologue(Instruction* instr);
  void EmitInstructionEpilogue(Instruction* instr);

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  void EmitUnoptimizedStaticCall(
      intptr_t size_with_type_args,
      intptr_t deopt_id,
      const InstructionSource& source,
      LocationSummary* locs,
      const ICData& ic_data,
      Code::EntryKind entry_kind = Code::EntryKind::kNormal);

  // Helper for TestAndCall that calculates a good bias that
  // allows more compact instructions to be emitted.
  intptr_t ComputeGoodBiasForCidComparison(const CallTargets& sorted,
                                           intptr_t max_immediate);

  // More helpers for EmitTestAndCall.

  static Register EmitTestCidRegister();

  void EmitTestAndCallLoadReceiver(intptr_t count_without_type_args,
                                   const Array& arguments_descriptor);

  void EmitTestAndCallSmiBranch(compiler::Label* label, bool jump_if_smi);

  void EmitTestAndCallLoadCid(Register class_id_reg);

  // Type checking helper methods.
  void CheckClassIds(Register class_id_reg,
                     const GrowableArray<intptr_t>& class_ids,
                     compiler::Label* is_instance_lbl,
                     compiler::Label* is_not_instance_lbl);

  SubtypeTestCachePtr GenerateInlineInstanceof(
      const InstructionSource& source,
      const AbstractType& type,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_lbl);

  SubtypeTestCachePtr GenerateInstantiatedTypeWithArgumentsTest(
      const InstructionSource& source,
      const AbstractType& dst_type,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_lbl);

  bool GenerateInstantiatedTypeNoArgumentsTest(
      const InstructionSource& source,
      const AbstractType& dst_type,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_lbl);

  SubtypeTestCachePtr GenerateUninstantiatedTypeTest(
      const InstructionSource& source,
      const AbstractType& dst_type,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_label);

  SubtypeTestCachePtr GenerateFunctionTypeTest(
      const InstructionSource& source,
      const AbstractType& dst_type,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_label);

  SubtypeTestCachePtr GenerateSubtype1TestCacheLookup(
      const InstructionSource& source,
      const Class& type_class,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_lbl);

  enum class TypeTestStubKind {
    // Just check the instance cid (no closures).
    kTestTypeOneArg = 1,
    // Also check the instance type arguments.
    kTestTypeTwoArgs = 2,
    // Also check the instantiator type arguments for the destination type.
    kTestTypeThreeArgs = 3,
    // Also check the function type arguments for the destination type.
    kTestTypeFourArgs = 4,
    // Also check the parent function and delayed type arguments for a closure.
    kTestTypeSixArgs = 6,
    // Also check the destination type, as it is not known at compile time.
    kTestTypeSevenArgs = 7,
  };

  static_assert(static_cast<intptr_t>(TypeTestStubKind::kTestTypeSevenArgs) ==
                    SubtypeTestCache::kMaxInputs,
                "Need to adjust kTestTypeMaxArgs");
  static constexpr TypeTestStubKind kTestTypeMaxArgs =
      TypeTestStubKind::kTestTypeSevenArgs;

  // Returns the number of used inputs for a given type test stub kind.
  intptr_t UsedInputsForTTSKind(TypeTestStubKind kind) {
    return static_cast<intptr_t>(kind);
  }

  // Returns type test stub kind for a type test against type parameter type.
  TypeTestStubKind GetTypeTestStubKindForTypeParameter(
      const TypeParameter& type_param);

  // Takes input from TypeTestABI registers (or stack on IA32), see
  // StubCodeCompiler::GenerateSubtypeNTestCacheStub for caller-save registers.
  SubtypeTestCachePtr GenerateCallSubtypeTestStub(
      TypeTestStubKind test_kind,
      compiler::Label* is_instance_lbl,
      compiler::Label* is_not_instance_lbl);

  void GenerateBoolToJump(Register bool_reg,
                          compiler::Label* is_true,
                          compiler::Label* is_false);

  void GenerateMethodExtractorIntrinsic(const Function& extracted_method,
                                        intptr_t type_arguments_field_offset);

  void GenerateGetterIntrinsic(const Function& accessor, const Field& field);

  // Perform a greedy local register allocation.  Consider all registers free.
  void AllocateRegistersLocally(Instruction* instr);

  // Map a block number in a forward iteration into the block number in the
  // corresponding reverse iteration.  Used to obtain an index into
  // block_order for reverse iterations.
  intptr_t reverse_index(intptr_t index) const {
    return block_order_.length() - index - 1;
  }

  void set_current_instruction(Instruction* current_instruction) {
    current_instruction_ = current_instruction;
  }

  void CompactBlock(BlockEntryInstr* block);
  void CompactBlocks();

  bool IsListClass(const Class& cls) const {
    return cls.ptr() == list_class_.ptr();
  }

  void EmitSourceLine(Instruction* instr);

  intptr_t GetOptimizationThreshold() const;

#if defined(DEBUG)
  void FrameStateUpdateWith(Instruction* instr);
  void FrameStatePush(Definition* defn);
  void FrameStatePop(intptr_t count);
  bool FrameStateIsSafeToCall();
  void FrameStateClear();
#endif

  // Returns true if instruction lookahead (window size one)
  // is amenable to a peephole optimization.
  bool IsPeephole(Instruction* instr) const;

#if defined(DEBUG)
  bool CanCallDart() const {
    return current_instruction_ == nullptr ||
           current_instruction_->CanCallDart();
  }
#else
  bool CanCallDart() const { return true; }
#endif

  bool CanPcRelativeCall(const Function& target) const;
  bool CanPcRelativeCall(const Code& target) const;
  bool CanPcRelativeCall(const AbstractType& target) const;

  // This struct contains either function or code, the other one being nullptr.
  class StaticCallsStruct : public ZoneAllocated {
   public:
    Code::CallKind call_kind;
    Code::CallEntryPoint entry_point;
    const intptr_t offset;
    const Function* function;      // Can be nullptr.
    const Code* code;              // Can be nullptr.
    const AbstractType* dst_type;  // Can be nullptr.
    StaticCallsStruct(Code::CallKind call_kind,
                      Code::CallEntryPoint entry_point,
                      intptr_t offset_arg,
                      const Function* function_arg,
                      const Code* code_arg,
                      const AbstractType* dst_type)
        : call_kind(call_kind),
          entry_point(entry_point),
          offset(offset_arg),
          function(function_arg),
          code(code_arg),
          dst_type(dst_type) {
      DEBUG_ASSERT(function == nullptr ||
                   function->IsNotTemporaryScopedHandle());
      DEBUG_ASSERT(code == nullptr || code->IsNotTemporaryScopedHandle());
      DEBUG_ASSERT(dst_type == nullptr ||
                   dst_type->IsNotTemporaryScopedHandle());
      ASSERT(code == nullptr || dst_type == nullptr);
    }

   private:
    DISALLOW_COPY_AND_ASSIGN(StaticCallsStruct);
  };

  Thread* thread_;
  Zone* zone_;
  compiler::Assembler* assembler_;
  const ParsedFunction& parsed_function_;
  const FlowGraph& flow_graph_;
  const FlowGraph* intrinsic_flow_graph_ = nullptr;
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
  CompressedStackMapsBuilder* compressed_stackmaps_builder_;
  CodeSourceMapBuilder* code_source_map_builder_;
  CatchEntryMovesMapBuilder* catch_entry_moves_maps_builder_;
  GrowableArray<BlockInfo*> block_info_;
  GrowableArray<CompilerDeoptInfo*> deopt_infos_;
  GrowableArray<SlowPathCode*> slow_path_code_;
  // Fields that were referenced by generated code.
  // This list is needed by precompiler to ensure they are retained.
  GrowableArray<const Field*> used_static_fields_;
  // Stores static call targets as well as stub targets.
  // TODO(srdjan): Evaluate if we should store allocation stub targets into a
  // separate table?
  GrowableArray<StaticCallsStruct*> static_calls_target_table_;
  // The table selectors of all dispatch table calls in the current function.
  GrowableArray<const compiler::TableSelector*> dispatch_table_call_targets_;
  GrowableArray<IndirectGotoInstr*> indirect_gotos_;
  bool is_optimizing_;
  SpeculativeInliningPolicy* speculative_policy_;
  // Set to true if optimized code has IC calls.
  bool may_reoptimize_;
  // True while emitting intrinsic code.
  bool intrinsic_mode_;
  compiler::Label* intrinsic_slow_path_label_ = nullptr;
  bool fully_intrinsified_ = false;
  CodeStatistics* stats_;

  // The definition whose value is supposed to be at the top of the
  // expression stack. Used by peephole optimization (window size one)
  // to eliminate redundant push/pop pairs.
  Definition* top_of_stack_ = nullptr;

  const Class& double_class_;
  const Class& mint_class_;
  const Class& float32x4_class_;
  const Class& float64x2_class_;
  const Class& int32x4_class_;
  const Class& list_class_;

  // Currently instructions generate deopt stubs internally by
  // calling AddDeoptStub.  To communicate deoptimization environment
  // that should be used when deoptimizing we store it in this variable.
  // In future AddDeoptStub should be moved out of the instruction template.
  Environment* pending_deoptimization_env_;

  ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data_;
  Array& edge_counters_array_;

  // Instruction currently running EmitNativeCode().
  Instruction* current_instruction_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_FLOW_GRAPH_COMPILER_H_
