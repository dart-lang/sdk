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
#include "vm/intermediate_language.h"

namespace dart {

class Code;
class ExceptionHandlerList;
template <typename T> class GrowableArray;
class ParsedFunction;

class FlowGraphCompiler : public FlowGraphVisitor {
 public:
  FlowGraphCompiler(Assembler* assembler,
                    const ParsedFunction& parsed_function,
                    const GrowableArray<BlockEntryInstr*>& block_order,
                    bool is_optimizing);

  virtual ~FlowGraphCompiler();

  void CompileGraph();

  // Infrastructure copied from class CodeGenerator or stubbed out.
  void FinalizePcDescriptors(const Code& code);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);
  void FinalizeExceptionHandlers(const Code& code);
  void FinalizeComments(const Code& code);

 private:
  static const int kLocalsOffsetFromFP = (-1 * kWordSize);

  // Constructor is lighweight, major initialization work should occur here.
  // This makes it easier to measure time spent in the compiler.
  void InitCompiler();

  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }

    Label label;
  };

  BlockEntryInstr* current_block() const { return current_block_; }

  bool is_optimizing() const { return is_optimizing_; }

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
  void GenerateCallRuntime(intptr_t cid,
                           intptr_t token_index,
                           intptr_t try_index,
                           const RuntimeEntry& entry);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t cid,
                            intptr_t token_index,
                            intptr_t try_index);

  void GenerateInlineInstanceof(const AbstractType& type,
                                Label* is_instance,
                                Label* is_not_instance);

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

  intptr_t StackSize() const;

  bool TryIntrinsify();
  void IntrinsifyGetter();
  void IntrinsifySetter();
  static bool CanOptimize();

  Assembler* assembler_;
  const ParsedFunction& parsed_function_;

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  GrowableArray<BlockInfo*> block_info_;
  BlockEntryInstr* current_block_;
  DescriptorList* pc_descriptors_list_;
  ExceptionHandlerList* exception_handlers_list_;
  const bool is_optimizing_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_X64_H_
