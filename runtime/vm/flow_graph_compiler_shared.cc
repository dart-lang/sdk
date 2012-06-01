// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_compiler_shared.h"

#include "vm/intermediate_language.h"
#include "vm/parser.h"

namespace dart {

FlowGraphCompilerShared::FlowGraphCompilerShared(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>& block_order,
    bool is_optimizing)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      block_order_(block_order),
      current_block_(NULL),
      exception_handlers_list_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_builder_(NULL),
      block_info_(block_order.length()),
      deopt_stubs_(),
      is_optimizing_(is_optimizing) {
  ASSERT(assembler != NULL);
}


FlowGraphCompilerShared::~FlowGraphCompilerShared() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}

void FlowGraphCompilerShared::InitCompiler() {
  pc_descriptors_list_ = new DescriptorList();
  exception_handlers_list_ = new ExceptionHandlerList();
  block_info_.Clear();
  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


intptr_t FlowGraphCompilerShared::StackSize() const {
  return parsed_function_.stack_local_count() +
      parsed_function_.copied_parameter_count();
}


Label* FlowGraphCompilerShared::GetBlockLabel(
    BlockEntryInstr* block_entry) const {
  intptr_t block_index = block_entry->postorder_number();
  return &block_info_[block_index]->label;
}


bool FlowGraphCompilerShared::IsNextBlock(TargetEntryInstr* block_entry) const {
  intptr_t current_index = reverse_index(current_block()->postorder_number());
  return block_order_[current_index + 1] == block_entry;
}


void FlowGraphCompilerShared::AddExceptionHandler(intptr_t try_index,
                                                  intptr_t pc_offset) {
  exception_handlers_list_->AddHandler(try_index, pc_offset);
}


// Uses current pc position and try-index.
void FlowGraphCompilerShared::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                                   intptr_t cid,
                                                   intptr_t token_index,
                                                   intptr_t try_index) {
  pc_descriptors_list()->AddDescriptor(kind,
                                       assembler()->CodeSize(),
                                       cid,
                                       token_index,
                                       try_index);
}


Label* FlowGraphCompilerShared::AddDeoptStub(intptr_t deopt_id,
                                             intptr_t deopt_token_index,
                                             intptr_t try_index,
                                             DeoptReasonId reason,
                                             Register reg1,
                                             Register reg2) {
  DeoptimizationStub* stub =
      new DeoptimizationStub(deopt_id, deopt_token_index, try_index, reason);
  stub->Push(reg1);
  stub->Push(reg2);
  deopt_stubs_.Add(stub);
  return stub->entry_label();
}


void FlowGraphCompilerShared::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
}


void FlowGraphCompilerShared::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompilerShared::FinalizeStackmaps(const Code& code) {
  if (stackmap_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_builder_->FinalizeStackmaps(code)));
  }
}


void FlowGraphCompilerShared::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompilerShared::GenerateDeferredCode() {
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    deopt_stubs_[i]->GenerateCode(this);
  }
}


}  // namespace dart


