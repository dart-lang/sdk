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

class Assembler;
class Code;
class DeoptimizationStub;
template <typename T> class GrowableArray;
class ParsedFunction;
class StackMapBuilder;

// Stubbed out implementation of graph compiler, bails out immediately if
// CompileGraph is called. The rest of the public API is UNIMPLEMENTED.
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

  Assembler* assembler() const { return assembler_; }

 private:
  friend class DeoptimizationStub;

  // Bail out of the flow graph compiler.  Does not return to the caller.
  void Bailout(const char* reason);

  virtual void VisitBlocks();

  BlockEntryInstr* current_block() const { return current_block_; }

  // Constructor is lighweight, major initialization work should occur here.
  // This makes it easier to measure time spent in the compiler.
  void InitCompiler();

  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }

    Label label;
  };

  void GenerateCallRuntime(intptr_t cid,
                           intptr_t token_index,
                           intptr_t try_index,
                           const RuntimeEntry& entry);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t cid,
                            intptr_t token_index,
                            intptr_t try_index);
  void CopyParameters();
  void EmitInstructionPrologue(Instruction* instr);

  intptr_t StackSize() const;

  bool CanOptimize();
  bool TryIntrinsify();
  void IntrinsifyGetter();
  void IntrinsifySetter();

  void GenerateDeferredCode();
  void EmitComment(Instruction* instr);
  void BailoutOnInstruction(Instruction* instr);

  Assembler* assembler_;
  const ParsedFunction& parsed_function_;

  // Compiler specific per-block state.  Indexed by postorder block number
  // for convenience.  This is not the block's index in the block order,
  // which is reverse postorder.
  GrowableArray<BlockInfo*> block_info_;
  BlockEntryInstr* current_block_;
  DescriptorList* pc_descriptors_list_;
  StackmapBuilder* stackmap_builder_;
  ExceptionHandlerList* exception_handlers_list_;
  GrowableArray<DeoptimizationStub*> deopt_stubs_;
  const bool is_optimizing_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompiler);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_COMPILER_IA32_H_
