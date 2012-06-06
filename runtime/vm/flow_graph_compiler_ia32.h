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
#include "vm/flow_graph_compiler_shared.h"
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
class FlowGraphCompiler : public FlowGraphCompilerShared {
 public:
  FlowGraphCompiler(Assembler* assembler,
                    const ParsedFunction& parsed_function,
                    const GrowableArray<BlockEntryInstr*>& block_order,
                    bool is_optimizing);

  void CompileGraph();

  void GenerateCallRuntime(intptr_t cid,
                           intptr_t token_index,
                           intptr_t try_index,
                           const RuntimeEntry& entry);

  // Returns pc-offset (in bytes) of the pc after the call, can be used to emit
  // pc-descriptor information.
  virtual intptr_t EmitInstanceCall(ExternalLabel* target_label,
                                    const ICData& ic_data,
                                    const Array& arguments_descriptor,
                                    intptr_t argument_count);

  // Returns pc-offset (in bytes) of the pc after the call, can be used to emit
  // pc-descriptor information.
  virtual intptr_t EmitStaticCall(const Function& function,
                                  const Array& arguments_descriptor,
                                  intptr_t argument_count);

  void GenerateCall(intptr_t token_index,
                    intptr_t try_index,
                    const ExternalLabel* label,
                    PcDescriptors::Kind kind);
  void GenerateInstanceOf(intptr_t cid,
                          intptr_t token_index,
                          intptr_t try_index,
                          const AbstractType& type,
                          bool negate_result);
  void GenerateAssertAssignable(intptr_t cid,
                                intptr_t token_index,
                                intptr_t try_index,
                                const AbstractType& dst_type,
                                const String& dst_name);

 private:
  friend class DeoptimizationStub;

  virtual void VisitBlocks();

  void CopyParameters();
  void EmitInstructionPrologue(Instruction* instr);

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

  void EmitComment(Instruction* instr);
  void BailoutOnInstruction(Instruction* instr);

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_IA32_H_
