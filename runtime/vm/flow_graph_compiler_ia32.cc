// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler_stats.h"
#include "vm/debugger.h"
#include "vm/il_printer.h"
#include "vm/intrinsifier.h"
#include "vm/locations.h"
#include "vm/longjump.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, compiler_stats);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, optimization_counter_threshold);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(bool, trace_functions);


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


void DeoptimizationStub::GenerateCode(FlowGraphCompiler* compiler) {
  Assembler* assem = compiler->assembler();
#define __ assem->
  __ Comment("Deopt stub for id %d", deopt_id_);
  __ Bind(entry_label());
  for (intptr_t i = 0; i < registers_.length(); i++) {
    __ pushl(registers_[i]);
  }
  __ movl(EAX, Immediate(Smi::RawValue(reason_)));
  __ call(&StubCode::DeoptimizeLabel());
  compiler->AddCurrentDescriptor(PcDescriptors::kOther,
                                 deopt_id_,
                                 deopt_token_index_,
                                 try_index_);
#undef __
}


FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>& block_order,
    bool is_optimizing)
    : FlowGraphVisitor(block_order),
      assembler_(assembler),
      parsed_function_(parsed_function),
      block_info_(block_order.length()),
      current_block_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_builder_(NULL),
      exception_handlers_list_(NULL),
      deopt_stubs_(),
      is_optimizing_(is_optimizing) {
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}


void FlowGraphCompiler::InitCompiler() {
  pc_descriptors_list_ = new DescriptorList();
  exception_handlers_list_ = new ExceptionHandlerList();
  block_info_.Clear();
  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s.";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t cid,
                                             intptr_t token_index,
                                             intptr_t try_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      cid,
                                      token_index,
                                      try_index);
}

#define __ assembler_->

void FlowGraphCompiler::IntrinsifyGetter() {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 1);
  ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
  const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
  ASSERT(return_node.value()->IsLoadInstanceFieldNode());
  const LoadInstanceFieldNode& load_node =
      *return_node.value()->AsLoadInstanceFieldNode();
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, load_node.field().Offset()));
  __ ret();
}


void FlowGraphCompiler::IntrinsifySetter() {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  // Sequence node has one store node and one return NULL node.
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  ASSERT(sequence_node.length() == 2);
  ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
  ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
  const StoreInstanceFieldNode& store_node =
      *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // Receiver.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX, FieldAddress(EAX, store_node.field().Offset()), EBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, raw_null);
  __ ret();
}


intptr_t FlowGraphCompiler::StackSize() const {
  return parsed_function_.stack_local_count() +
      parsed_function_.copied_parameter_count();
}


bool FlowGraphCompiler::CanOptimize() {
  return
      !FLAG_report_usage_count &&
      (FLAG_optimization_counter_threshold >= 0) &&
      !Isolate::Current()->debugger()->IsActive();
}


// Returns 'true' if code generation for this function is complete, i.e.,
// no fall-through to regular code is needed.
bool FlowGraphCompiler::TryIntrinsify() {
  if (!CanOptimize()) return false;
  // Intrinsification skips arguments checks, therefore disable if in checked
  // mode.
  if (FLAG_intrinsify && !FLAG_trace_functions && !FLAG_enable_type_checks) {
    if ((parsed_function_.function().kind() == RawFunction::kImplicitGetter)) {
      IntrinsifyGetter();
      return true;
    }
    if ((parsed_function_.function().kind() == RawFunction::kImplicitSetter)) {
      IntrinsifySetter();
      return true;
    }
  }
  // Even if an intrinsified version of the function was successfully
  // generated, it may fall through to the non-intrinsified method body.
  if (!FLAG_trace_functions) {
    return Intrinsifier::Intrinsify(parsed_function_.function(), assembler_);
  }
  return false;
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t cid,
                                            intptr_t token_index,
                                            intptr_t try_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntime(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, cid, token_index, try_index);
}


void FlowGraphCompiler::CopyParameters() {
  Bailout("Copy Parameters");
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    __ int3();
    __ jmp(&StubCode::FixCallersTargetLabel());
    return;
  }
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function_.function();

  const int parameter_count = function.num_fixed_parameters();
  const int num_copied_params = parsed_function_.copied_parameter_count();
  const int local_count = parsed_function_.stack_local_count();
  AssemblerMacros::EnterDartFrame(assembler_, (StackSize() * kWordSize));
  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional named parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
#ifdef DEBUG
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (EDX).
      __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
      __ cmpl(EAX, Immediate(Smi::RawValue(parameter_count)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        GenerateCallRuntime(AstNode::kNoId,
                            function.token_index(),
                            CatchClauseNode::kInvalidTryIndex,
                            kClosureArgumentMismatchRuntimeEntry);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
  } else {
    CopyParameters();
  }
  // Initialize (non-argument) stack allocated locals to null.
  if (local_count > 0) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movl(EAX, raw_null);
    const int base = parsed_function_.first_stack_local_index();
    for (int i = 0; i < local_count; ++i) {
      // Subtract index i (locals lie at lower addresses than EBP).
      __ movl(Address(EBP, (base - i) * kWordSize), EAX);
    }
  }

  // Generate stack overflow check.
  __ cmpl(ESP,
          Address::Absolute(Isolate::Current()->stack_limit_address()));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow, Assembler::kNearJump);
  GenerateCallRuntime(AstNode::kNoId,
                      function.token_index(),
                      CatchClauseNode::kInvalidTryIndex,
                      kStackOverflowRuntimeEntry);
  __ Bind(&no_stack_overflow);

  if (FLAG_print_scopes) {
    // Print the function scope (again) after generating the prologue in order
    // to see annotations such as allocation indices of locals.
    if (FLAG_print_ast) {
      // Second printing.
      OS::Print("Annotated ");
    }
    AstPrinter::PrintFunctionScope(parsed_function_);
  }

  VisitBlocks();

  __ int3();
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  pc_descriptors_list_->AddDescriptor(PcDescriptors::kPatchCode,
                                      assembler_->CodeSize(),
                                      AstNode::kNoId,
                                      0,
                                      -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


void FlowGraphCompiler::GenerateDeferredCode() {
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    deopt_stubs_[i]->GenerateCode(this);
  }
}


void FlowGraphCompiler::EmitComment(Instruction* instr) {
  char buffer[80];
  BufferFormatter f(buffer, sizeof(buffer));
  instr->PrintTo(&f);
  __ Comment("@%d: %s", instr->cid(), buffer);
}


void FlowGraphCompiler::BailoutOnInstruction(Instruction* instr) {
  char buffer[80];
  BufferFormatter f(buffer, sizeof(buffer));
  instr->PrintTo(&f);
  Bailout(buffer);
}


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  LocationSummary* locs = instr->locs();
  ASSERT(locs != NULL);

  locs->AllocateRegisters();

  // Load instruction inputs into allocated registers.
  for (intptr_t i = locs->input_count() - 1; i >= 0; i--) {
    Location loc = locs->in(i);
    ASSERT(loc.kind() == Location::kRegister);
    __ popl(loc.reg());
  }
}


void FlowGraphCompiler::VisitBlocks() {
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    __ Comment("B%d", i);
    // Compile the block entry.
    current_block_ = block_order_[i];
    Instruction* instr = current_block()->Accept(this);
    // Compile all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      if (FLAG_code_comments) EmitComment(instr);
      if (instr->locs() == NULL) {
        BailoutOnInstruction(instr);
      } else {
        EmitInstructionPrologue(instr);
        instr->EmitNativeCode(this);
        instr = instr->StraightLineSuccessor();
      }
    }
    BlockEntryInstr* successor =
        (instr == NULL) ? NULL : instr->AsBlockEntry();
    if (successor != NULL) {
      // Block ended with a "goto".  We can fall through if it is the
      // next block in the list.  Otherwise, we need a jump.
      if ((i == block_order_.length() - 1) ||
          (block_order_[i + 1] != successor)) {
        __ jmp(&block_info_[successor->postorder_number()]->label);
      }
    }
  }
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  if (stackmap_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_builder_->FinalizeStackmaps(code)));
  }
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
}


void FlowGraphCompiler::FinalizeComments(const Code& code) {
  code.set_comments(assembler_->GetCodeComments());
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
