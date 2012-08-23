// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_X64_H_
#define VM_FLOW_GRAPH_COMPILER_X64_H_

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#error Include flow_graph_compiler.h instead of flow_graph_compiler_x64.h.
#endif

namespace dart {

class Code;
class DeoptimizationStub;
class FlowGraph;
template <typename T> class GrowableArray;
class ParsedFunction;

class FlowGraphCompiler : public ValueObject {
 private:
  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }
    Label label;
  };

 public:
  FlowGraphCompiler(Assembler* assembler,
                    const FlowGraph& flow_graph,
                    bool is_optimizing,
                    bool is_leaf);

  ~FlowGraphCompiler();

  // Accessors.
  Assembler* assembler() const { return assembler_; }
  const ParsedFunction& parsed_function() const { return parsed_function_; }
  const GrowableArray<BlockEntryInstr*>& block_order() const {
    return block_order_;
  }
  DescriptorList* pc_descriptors_list() const {
    return pc_descriptors_list_;
  }
  const GrowableObjectArray& object_table() {
    return object_table_;
  }
  BlockEntryInstr* current_block() const { return current_block_; }
  void set_current_block(BlockEntryInstr* value) {
    current_block_ = value;
  }
  static bool CanOptimize();
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

  void LoadDoubleOrSmiToXmm(XmmRegister result,
                            Register reg,
                            Register temp,
                            Label* not_double_or_smi);

  // Returns 'true' if code generation for this function is complete, i.e.,
  // no fall-through to regular code is needed.
  bool TryIntrinsify();

  void GenerateCallRuntime(intptr_t deopt_id,
                           intptr_t token_pos,
                           intptr_t try_index,
                           const RuntimeEntry& entry,
                           LocationSummary* locs);

  void GenerateCall(intptr_t token_pos,
                    intptr_t try_index,
                    const ExternalLabel* label,
                    PcDescriptors::Kind kind,
                    LocationSummary* locs);

  void GenerateAssertAssignable(intptr_t deopt_id,
                                intptr_t token_pos,
                                intptr_t try_index,
                                const AbstractType& dst_type,
                                const String& dst_name,
                                LocationSummary* locs);

  void GenerateInstanceOf(intptr_t deopt_id,
                          intptr_t token_pos,
                          intptr_t try_index,
                          const AbstractType& type,
                          bool negate_result,
                          LocationSummary* locs);

  void GenerateInstanceCall(intptr_t deopt_id,
                            intptr_t token_pos,
                            intptr_t try_index,
                            const String& function_name,
                            intptr_t argument_count,
                            const Array& argument_names,
                            intptr_t checked_argument_count,
                            LocationSummary* locs);

  void GenerateStaticCall(intptr_t deopt_id,
                          intptr_t token_pos,
                          intptr_t try_index,
                          const Function& function,
                          intptr_t argument_count,
                          const Array& argument_names,
                          LocationSummary* locs);

  void GenerateInlinedMathSqrt(Label* done);

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

  void EmitClassChecksNoSmi(const ICData& ic_data,
                            Register instance_reg,
                            Register temp_reg,
                            Label* deopt);

  void EmitInstanceCall(ExternalLabel* target_label,
                        const ICData& ic_data,
                        const Array& arguments_descriptor,
                        intptr_t argument_count,
                        intptr_t deopt_id,
                        intptr_t token_pos,
                        intptr_t try_index,
                        LocationSummary* locs);

  void EmitTestAndCall(const ICData& ic_data,
                       Register class_id_reg,
                       intptr_t arg_count,
                       const Array& arg_names,
                       Label* deopt,
                       Label* done,  // Can be NULL, which means fallthrough.
                       intptr_t deopt_id,
                       intptr_t token_index,
                       intptr_t try_index,
                       LocationSummary* locs);

  void EmitDoubleCompareBranch(Condition true_condition,
                               XmmRegister left,
                               XmmRegister right,
                               BranchInstr* branch);
  void EmitDoubleCompareBool(Condition true_condition,
                             XmmRegister left,
                             XmmRegister right,
                             Register result);

  intptr_t StackSize() const;

  // Returns assembler label associated with the given block entry.
  Label* GetBlockLabel(BlockEntryInstr* block_entry) const;

  // Returns true if there is a next block after the current one in
  // the block order and if it is the given block.
  bool IsNextBlock(BlockEntryInstr* block_entry) const;

  void AddExceptionHandler(intptr_t try_index, intptr_t pc_offset);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t deopt_id,
                            intptr_t token_pos,
                            intptr_t try_index);

  void RecordSafepoint(LocationSummary* locs);

  Label* AddDeoptStub(intptr_t deopt_id,
                      intptr_t try_index_,
                      DeoptReasonId reason);

  void AddSlowPathCode(SlowPathCode* slow_path);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  void FinalizeDeoptInfo(const Code& code);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeComments(const Code& code);

  const Bool& bool_true() const { return bool_true_; }
  const Bool& bool_false() const { return bool_false_; }
  const Class& double_class() const { return double_class_; }

  // Returns true if the compiled function has a finally clause.
  bool HasFinally() const;

  static const int kLocalsOffsetFromFP = (-1 * kWordSize);

  void SaveLiveRegisters(LocationSummary* locs);
  void RestoreLiveRegisters(LocationSummary* locs);

 private:
  friend class DeoptimizationStub;

  void GenerateDeferredCode();

  void EmitInstructionPrologue(Instruction* instr);

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  void EmitStaticCall(const Function& function,
                      const Array& arguments_descriptor,
                      intptr_t argument_count,
                      intptr_t deopt_id,
                      intptr_t token_pos,
                      intptr_t try_index,
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

  void GenerateBoolToJump(Register bool_reg, Label* is_true, Label* is_false);

  void CopyParameters();

  void GenerateInlinedGetter(intptr_t offset);
  void GenerateInlinedSetter(intptr_t offset);

  // Map a block number in a forward iteration into the block number in the
  // corresponding reverse iteration.  Used to obtain an index into
  // block_order for reverse iterations.
  intptr_t reverse_index(intptr_t index) const {
    return block_order_.length() - index - 1;
  }

  // Perform a greedy local register allocation.  Consider all registers free.
  void AllocateRegistersLocally(Instruction* instr);

  // Returns true if the generated code does not call other Dart code or
  // runtime. Only deoptimization is allowed to occur. Closures are not leaf.
  bool IsLeaf() const;

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
  GrowableArray<DeoptimizationStub*> deopt_stubs_;
  GrowableArray<SlowPathCode*> slow_path_code_;
  const GrowableObjectArray& object_table_;
  const bool is_optimizing_;
  const bool is_dart_leaf_;

  const Bool& bool_true_;
  const Bool& bool_false_;
  const Class& double_class_;

  ParallelMoveResolver parallel_move_resolver_;

  // Currently instructions generate deopt stubs internally by
  // calling AddDeoptStub.  To communicate deoptimization environment
  // that should be used when deoptimizing we store it in this variable.
  // In future AddDeoptStub should be moved out of the instruction template.
  Environment* pending_deoptimization_env_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_X64_H_
