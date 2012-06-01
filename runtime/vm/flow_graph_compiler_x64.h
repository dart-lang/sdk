// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_X64_H_
#define VM_FLOW_GRAPH_COMPILER_X64_H_

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#error Include flow_graph_compiler.h instead of flow_graph_compiler_x64.h.
#endif

#include "vm/assembler.h"
#include "vm/assembler_macros.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/flow_graph_compiler_shared.h"
#include "vm/intermediate_language.h"

namespace dart {

class Code;
class DeoptimizationStub;
class ExceptionHandlerList;
template <typename T> class GrowableArray;
class ParsedFunction;

class FlowGraphCompiler : public FlowGraphCompilerShared {
 public:
  FlowGraphCompiler(Assembler* assembler,
                    const ParsedFunction& parsed_function,
                    const GrowableArray<BlockEntryInstr*>& block_order,
                    bool is_optimizing);

  void CompileGraph();

  void FinalizeComments(const Code& code);

  void GenerateCallRuntime(intptr_t cid,
                           intptr_t token_index,
                           intptr_t try_index,
                           const RuntimeEntry& entry);

 private:
  friend class DeoptimizationStub;

  // TODO(fschneider): Clean up friend-class declarations once all code
  // generator templates have been moved to intermediate_language_x64.cc.
#define DECLARE_FRIEND(ShortName, ClassName) friend class ClassName;
  FOR_EACH_COMPUTATION(DECLARE_FRIEND)
#undef DECLARE_FRIEND

  static const int kLocalsOffsetFromFP = (-1 * kWordSize);

  // Bail out of the flow graph compiler.  Does not return to the caller.
  void Bailout(const char* reason);

  virtual void VisitBlocks();

  void EmitInstructionPrologue(Instruction* instr);

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  void EmitComment(Instruction* instr);

  // Emit an instance call.
  void EmitInstanceCall(intptr_t cid,
                        intptr_t token_index,
                        intptr_t try_index,
                        const String& function_name,
                        intptr_t argument_count,
                        const Array& argument_names,
                        intptr_t checked_argument_count);

  // Emit a static call.
  void EmitStaticCall(intptr_t token_index,
                      intptr_t try_index,
                      const Function& function,
                      intptr_t argument_count,
                      const Array& argument_names);

  // Infrastructure copied from class CodeGenerator.
  void GenerateCall(intptr_t token_index,
                    intptr_t try_index,
                    const ExternalLabel* label,
                    PcDescriptors::Kind kind);

  // Type checking helper methods.
  void CheckClassIds(const GrowableArray<intptr_t>& class_ids,
                    Label* is_instance_lbl,
                    Label* is_not_instance_lbl);
  RawSubtypeTestCache* GenerateInlineInstanceof(intptr_t cid,
                                                intptr_t token_index,
                                                const AbstractType& type,
                                                Label* is_instance,
                                                Label* is_not_instance);

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
      const AbstractType& dst_type,
      intptr_t cid,
      intptr_t token_index,
      Label* is_instance_lbl,
      Label* is_not_instance_label);

  RawSubtypeTestCache* GenerateSubtype1TestCacheLookup(
      intptr_t cid,
      intptr_t token_index,
      const Class& type_class,
      Label* is_instance_lbl,
      Label* is_not_instance_lbl);

  void GenerateAssertAssignable(intptr_t cid,
                                intptr_t token_index,
                                intptr_t try_index,
                                const AbstractType& dst_type,
                                const String& dst_name);

  void GenerateInstanceOf(intptr_t cid,
                          intptr_t token_index,
                          intptr_t try_index,
                          const AbstractType& type,
                          bool negate_result);

  void CopyParameters();

  bool TryIntrinsify();
  void IntrinsifyGetter();
  void IntrinsifySetter();
  static bool CanOptimize();

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_X64_H_
