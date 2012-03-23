// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_X64_H_
#define VM_FLOW_GRAPH_COMPILER_X64_H_

#ifndef VM_FLOW_GRAPH_COMPILER_H_
#error Include flow_graph_compiler.h instead of flow_graph_compiler_x64.h.
#endif

#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/intermediate_language.h"

namespace dart {

class Code;
template <typename T> class GrowableArray;
class ParsedFunction;

class FlowGraphCompiler : public FlowGraphVisitor {
 public:
  FlowGraphCompiler(Assembler* assembler,
                    const ParsedFunction& parsed_function,
                    const GrowableArray<BlockEntryInstr*>& block_order);

  virtual ~FlowGraphCompiler();

  void CompileGraph();

  // Infrastructure copied from class CodeGenerator or stubbed out.
  void FinalizePcDescriptors(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeExceptionHandlers(const Code& code);

 private:
  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }

    Label label;
  };

  BlockEntryInstr* current_block() const { return current_block_; }

  // Bail out of the flow graph compiler.  Does not return to the caller.
  void Bailout(const char* reason);

  virtual void VisitBlocks();

  // Emit code to perform a computation, leaving its value in RAX.
#define DECLARE_VISIT_COMPUTATION(ShortName, ClassName)                        \
  virtual void Visit##ShortName(ClassName* comp);

  // Each visit function compiles a type of instruction.
#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr);

  FOR_EACH_COMPUTATION(DECLARE_VISIT_COMPUTATION)
  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_COMPUTATION
#undef DECLARE_VISIT_INSTRUCTION

  // Emit code to load a Value into register 'dst'.
  void LoadValue(Register dst, Value* value);

  // Emit an instance call.
  void EmitInstanceCall(intptr_t node_id,
                        intptr_t token_index,
                        const String& function_name,
                        intptr_t argument_count,
                        const Array& argument_names,
                        intptr_t checked_argument_count);

  // Emit a static call.
  void EmitStaticCall(intptr_t token_index,
                      const Function& function,
                      intptr_t argument_count,
                      const Array& argument_names);

  // Infrastructure copied from class CodeGenerator.
  void GenerateCall(intptr_t token_index,
                    const ExternalLabel* label,
                    PcDescriptors::Kind kind);
  void GenerateCallRuntime(intptr_t node_id,
                           intptr_t token_index,
                           const RuntimeEntry& entry);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t node_id,
                            intptr_t token_index);

  void GenerateAssertAssignable(intptr_t node_id,
                                intptr_t token_index,
                                const AbstractType& dst_type,
                                const String& dst_name);

  void GenerateInstanceOf(intptr_t node_id,
                          intptr_t token_index,
                          const AbstractType& type,
                          bool negate_result);

  void GenerateInstantiatorTypeArguments(intptr_t token_index);

  void CopyParameters();

  intptr_t StackSize() const;

  Assembler* assembler_;
  const ParsedFunction& parsed_function_;

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  GrowableArray<BlockInfo*> block_info_;

  BlockEntryInstr* current_block_;

  DescriptorList* pc_descriptors_list_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_X64_H_
