// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_compiler_shared.h"

#include "vm/debugger.h"
#include "vm/intermediate_language.h"
#include "vm/intrinsifier.h"
#include "vm/longjump.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, trace_functions);
DECLARE_FLAG(bool, report_usage_count);

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


void FlowGraphCompilerShared::FinalizeComments(const Code& code) {
  code.set_comments(assembler()->GetCodeComments());
}


void FlowGraphCompilerShared::GenerateDeferredCode() {
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    deopt_stubs_[i]->GenerateCode(this);
  }
}


void FlowGraphCompilerShared::GenerateInstanceCall(
    intptr_t cid,
    intptr_t token_index,
    intptr_t try_index,
    const String& function_name,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t checked_argument_count) {
  ICData& ic_data =
      ICData::ZoneHandle(ICData::New(parsed_function().function(),
                                     function_name,
                                     cid,
                                     checked_argument_count));
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  uword label_address = 0;
  switch (checked_argument_count) {
    case 1:
      label_address = StubCode::OneArgCheckInlineCacheEntryPoint();
      break;
    case 2:
      label_address = StubCode::TwoArgsCheckInlineCacheEntryPoint();
      break;
    default:
      UNIMPLEMENTED();
  }
  ExternalLabel target_label("InlineCache", label_address);

  const intptr_t descr_offset = EmitInstanceCall(&target_label,
                                                 ic_data,
                                                 arguments_descriptor,
                                                 argument_count);
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kIcCall,
                                       descr_offset,
                                       cid,
                                       token_index,
                                       try_index);
}


void FlowGraphCompilerShared::GenerateStaticCall(intptr_t cid,
                                                 intptr_t token_index,
                                                 intptr_t try_index,
                                                 const Function& function,
                                                 intptr_t argument_count,
                                                 const Array& argument_names) {
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  const intptr_t descr_offset = EmitStaticCall(function,
                                               arguments_descriptor,
                                               argument_count);
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kFuncCall,
                                       descr_offset,
                                       cid,
                                       token_index,
                                       try_index);
}


void FlowGraphCompilerShared::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function().function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


static bool CanOptimize() {
  return !FLAG_report_usage_count &&
         (FLAG_optimization_counter_threshold >= 0) &&
         !Isolate::Current()->debugger()->IsActive();
}


// Returns 'true' if code generation for this function is complete, i.e.,
// no fall-through to regular code is needed.
bool FlowGraphCompilerShared::TryIntrinsify() {
  if (!CanOptimize()) return false;
  // Intrinsification skips arguments checks, therefore disable if in checked
  // mode.
  if (FLAG_intrinsify && !FLAG_trace_functions && !FLAG_enable_type_checks) {
    if ((parsed_function().function().kind() == RawFunction::kImplicitGetter)) {
      // An implicit getter must have a specific AST structure.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 1);
      ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
      const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
      ASSERT(return_node.value()->IsLoadInstanceFieldNode());
      const LoadInstanceFieldNode& load_node =
          *return_node.value()->AsLoadInstanceFieldNode();
      GenerateInlinedGetter(load_node.field().Offset());
      return true;
    }
    if ((parsed_function().function().kind() == RawFunction::kImplicitSetter)) {
      // An implicit setter must have a specific AST structure.
      // Sequence node has one store node and one return NULL node.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 2);
      ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
      ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
      const StoreInstanceFieldNode& store_node =
          *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
      GenerateInlinedSetter(store_node.field().Offset());
      return true;
    }
  }
  // Even if an intrinsified version of the function was successfully
  // generated, it may fall through to the non-intrinsified method body.
  if (!FLAG_trace_functions) {
    return Intrinsifier::Intrinsify(parsed_function().function(), assembler());
  }
  return false;
}

}  // namespace dart


