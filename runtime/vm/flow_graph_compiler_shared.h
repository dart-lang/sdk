// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_COMPILER_SHARED_H_
#define VM_FLOW_GRAPH_COMPILER_SHARED_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/growable_array.h"

namespace dart {

class BlockEntryInstr;
class ExceptionHandlerList;
class FlowGraphCompilerShared;
class ParsedFunction;
class TargetEntryInstr;

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
  void GenerateCode(FlowGraphCompilerShared* compiler);

 private:
  const intptr_t deopt_id_;
  const intptr_t deopt_token_index_;
  const intptr_t try_index_;
  const DeoptReasonId reason_;
  GrowableArray<Register> registers_;
  Label entry_label_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizationStub);
};


class FlowGraphCompilerShared : public ValueObject {
 public:
  FlowGraphCompilerShared(Assembler* assembler,
                          const ParsedFunction& parsed_function,
                          const GrowableArray<BlockEntryInstr*>& block_order,
                          bool is_optimizing);

  virtual ~FlowGraphCompilerShared();

  // Constructor is lighweight, major initialization work should occur here.
  // This makes it easier to measure time spent in the compiler.
  void InitCompiler();

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
                      Register reg1,
                      Register reg2);

  void FinalizeExceptionHandlers(const Code& code);
  void FinalizePcDescriptors(const Code& code);
  void FinalizeStackmaps(const Code& code);
  void FinalizeVarDescriptors(const Code& code);

  void GenerateDeferredCode();

  struct BlockInfo : public ZoneAllocated {
   public:
    BlockInfo() : label() { }

    Label label;
  };

  const GrowableArray<BlockInfo*>& block_info() const { return block_info_; }

 private:
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

  DISALLOW_COPY_AND_ASSIGN(FlowGraphCompilerShared);
};


}  // namespace dart


#endif  // VM_FLOW_GRAPH_COMPILER_SHARED_H_
