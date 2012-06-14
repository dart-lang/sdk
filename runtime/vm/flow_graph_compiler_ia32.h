// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_IA32_H_
#define VM_FLOW_GRAPH_COMPILER_IA32_H_

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#error Include flow_graph_compiler.h instead of flow_graph_compiler_ia32.h.
#endif

#include "vm/assembler.h"
#include "vm/assembler_macros.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/intermediate_language.h"

namespace dart {

class AbstractType;
class Assembler;
class Code;
class DeoptimizationStub;
template <typename T> class GrowableArray;
class ParsedFunction;
class StackMapBuilder;

// Stubbed out implementation of graph compiler, bails out immediately if
// CompileGraph is called. The rest of the public API is UNIMPLEMENTED.
class FlowGraphCompiler : public ValueObject {
 private:
  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }
    Label label;
  };

 public:
  FlowGraphCompiler(Assembler* assembler,
                    const ParsedFunction& parsed_function,
                    const GrowableArray<BlockEntryInstr*>& block_order,
                    bool is_optimizing);

  virtual ~FlowGraphCompiler();

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
  bool is_optimizing() const { return is_optimizing_; }
  const GrowableArray<BlockInfo*>& block_info() const { return block_info_; }

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

  virtual void GenerateCallRuntime(intptr_t cid,
                                   intptr_t token_index,
                                   intptr_t try_index,
                                   const RuntimeEntry& entry);

  // Returns pc-offset (in bytes) of the pc after the call, can be used to emit
  // pc-descriptor information.
  virtual intptr_t EmitStaticCall(const Function& function,
                                  const Array& arguments_descriptor,
                                  intptr_t argument_count);

  virtual void GenerateCall(intptr_t token_index,
                            intptr_t try_index,
                            const ExternalLabel* label,
                            PcDescriptors::Kind kind);
  virtual void GenerateInstanceOf(intptr_t cid,
                                  intptr_t token_index,
                                  intptr_t try_index,
                                  const AbstractType& type,
                                  bool negate_result);
  virtual void GenerateAssertAssignable(intptr_t cid,
                                        intptr_t token_index,
                                        intptr_t try_index,
                                        const AbstractType& dst_type,
                                        const String& dst_name);

  void GenerateInstanceCall(intptr_t cid,
                            intptr_t token_index,
                            intptr_t try_index,
                            const String& function_name,
                            intptr_t argument_count,
                            const Array& argument_names,
                            intptr_t checked_argument_count);

  void GenerateStaticCall(intptr_t cid,
                          intptr_t token_index,
                          intptr_t try_index,
                          const Function& function,
                          intptr_t argument_count,
                          const Array& argument_names);

  void GenerateNumberTypeCheck(Register kClassIdReg,
                               const AbstractType& type,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateStringTypeCheck(Register kClassIdReg,
                               Label* is_instance_lbl,
                               Label* is_not_instance_lbl);
  void GenerateListTypeCheck(Register kClassIdReg,
                             Label* is_instance_lbl);

  // Returns pc-offset (in bytes) of the pc after the call, can be used to emit
  // pc-descriptor information.
  intptr_t EmitInstanceCall(ExternalLabel* target_label,
                            const ICData& ic_data,
                            const Array& arguments_descriptor,
                            intptr_t argument_count);

  void EmitLoadIndexedGeneric(LoadIndexedComp* comp);

  void EmitComment(Instruction* instr);

  void EmitClassChecksNoSmi(const ZoneGrowableArray<intptr_t>& class_ids,
                            Register instance_reg,
                            Register temp_reg,
                            Label* deopt);

  intptr_t StackSize() const;

  // Returns assembler label associated with the given block entry.
  Label* GetBlockLabel(BlockEntryInstr* block_entry) const;

  // Returns true if the next block after current in the current block order
  // is the given block.
  bool IsNextBlock(TargetEntryInstr* block_entry) const;

  void AddExceptionHandler(intptr_t try_index, intptr_t pc_offset);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t cid,
                            intptr_t token_index,
                            intptr_t try_index);
  Label* AddDeoptStub(intptr_t deopt_id,
                      intptr_t deopt_token_index,
                      intptr_t try_index_,
                      DeoptReasonId reason,
                      Register reg1 = kNoRegister,
                      Register reg2 = kNoRegister,
                      Register reg3 = kNoRegister);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeComments(const Code& code);

  static const int kLocalsOffsetFromFP = (-1 * kWordSize);

  const Bool& bool_true() const { return bool_true_; }
  const Bool& bool_false() const { return bool_false_; }

 private:
  friend class DeoptimizationStub;

  void GenerateDeferredCode();

  void CopyParameters();
  virtual void EmitInstructionPrologue(Instruction* instr);

  virtual void GenerateInlinedGetter(intptr_t offset);
  virtual void GenerateInlinedSetter(intptr_t offset);

  RawSubtypeTestCache* GenerateInlineInstanceof(intptr_t cid,
                                                intptr_t token_index,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateInstantiatedTypeWithArgumentsTest(
      intptr_t cid,
      intptr_t token_index,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_lbl);

  void GenerateInstantiatedTypeNoArgumentsTest(intptr_t cid,
                                               intptr_t token_index,
                                               const AbstractType& dst_type,
                                               Label* is_instance_lbl,
                                               Label* is_not_instance_lbl);

  RawSubtypeTestCache* GenerateUninstantiatedTypeTest(
      intptr_t cid,
      intptr_t token_index,
      const AbstractType& dst_type,
      Label* is_instance_lbl,
      Label* is_not_instance_label);

  RawSubtypeTestCache* GenerateSubtype1TestCacheLookup(
      intptr_t cid,
      intptr_t token_index,
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

  virtual void CheckClassIds(Register class_id_reg,
                             const GrowableArray<intptr_t>& class_ids,
                             Label* is_equal_lbl,
                             Label* is_not_equal_lbl);


  // Map a block number in a forward iteration into the block number in the
  // corresponding reverse iteration.  Used to obtain an index into
  // block_order for reverse iterations.
  intptr_t reverse_index(intptr_t index) const {
    return block_order_.length() - index - 1;
  }

  class Assembler* assembler_;
  const ParsedFunction& parsed_function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  BlockEntryInstr* current_block_;
  ExceptionHandlerList* exception_handlers_list_;
  DescriptorList* pc_descriptors_list_;
  StackmapBuilder* stackmap_builder_;
  GrowableArray<BlockInfo*> block_info_;
  GrowableArray<DeoptimizationStub*> deopt_stubs_;
  const bool is_optimizing_;

  const Bool& bool_true_;
  const Bool& bool_false_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};


class DeoptimizationStub : public ZoneAllocated {
 public:
  DeoptimizationStub(intptr_t deopt_id,
                     intptr_t deopt_token_index,
                     intptr_t try_index,
                     DeoptReasonId reason)
      : deopt_id_(deopt_id),
        deopt_token_index_(deopt_token_index),
        try_index_(try_index),
        reason_(reason),
        registers_(2),
        entry_label_() {}

  void Push(Register reg) { registers_.Add(reg); }
  Label* entry_label() { return &entry_label_; }

  // Implementation is in architecture specific file.
  void GenerateCode(FlowGraphCompiler* compiler);

 private:
  const intptr_t deopt_id_;
  const intptr_t deopt_token_index_;
  const intptr_t try_index_;
  const DeoptReasonId reason_;
  GrowableArray<Register> registers_;
  Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationStub);
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_IA32_H_
