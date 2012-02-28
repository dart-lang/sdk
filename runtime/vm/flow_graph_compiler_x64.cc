// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/code_generator.h"
#include "vm/disassembler.h"
#include "vm/longjump.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, trace_functions);

void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


#define __ assembler_->

void FlowGraphCompiler::LoadValue(Value* value) {
  if (value->IsConstant()) {
    ConstantVal* constant = value->AsConstant();
    if (constant->instance().IsSmi()) {
      int64_t imm = reinterpret_cast<int64_t>(constant->instance().raw());
      __ movq(RAX, Immediate(imm));
    } else {
      __ LoadObject(RAX, value->AsConstant()->instance());
    }
  } else {
    ASSERT(value->IsTemp());
    __ popq(RAX);
  }
}


void FlowGraphCompiler::VisitTemp(TempVal* val) {
  Bailout("TempVal");
}


void FlowGraphCompiler::VisitConstant(ConstantVal* val) {
  Bailout("ConstantVal");
}


void FlowGraphCompiler::VisitAssertAssignable(AssertAssignableComp* comp) {
  Bailout("AssertAssignableComp");
}


void FlowGraphCompiler::VisitInstanceCall(InstanceCallComp* comp) {
  Bailout("InstanceCallComp");
}


void FlowGraphCompiler::VisitStrictCompare(StrictCompareComp* comp) {
  Bailout("StrictCompareComp");
}



void FlowGraphCompiler::VisitStaticCall(StaticCallComp* comp) {
  Bailout("StaticCallComp");
}


void FlowGraphCompiler::VisitLoadLocal(LoadLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("load of context variable");
  }
  __ movq(RAX, Address(RBP, comp->local().index() * kWordSize));
}


void FlowGraphCompiler::VisitStoreLocal(StoreLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("store to context variable");
  }
  LoadValue(comp->value());
  __ movq(Address(RBP, comp->local().index() * kWordSize), RAX);
}


void FlowGraphCompiler::VisitJoinEntry(JoinEntryInstr* instr) {
  Bailout("JoinEntryInstr");
}


void FlowGraphCompiler::VisitTargetEntry(TargetEntryInstr* instr) {
  // Since we don't handle branching control flow yet, there is nothing to do.
}


void FlowGraphCompiler::VisitDo(DoInstr* instr) {
  instr->computation()->Accept(this);
}


void FlowGraphCompiler::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this);
  __ pushq(RAX);
}


void FlowGraphCompiler::VisitReturn(ReturnInstr* instr) {
  LoadValue(instr->value());

#ifdef DEBUG
  // Check that the entry stack size matches the exit stack size.
  __ movq(R10, RBP);
  __ subq(R10, RSP);
  __ cmpq(R10, Immediate(stack_local_count() * kWordSize));
  Label stack_ok;
  __ j(EQUAL, &stack_ok, Assembler::kNearJump);
  __ Stop("Exit stack size does not match the entry stack size.");
  __ Bind(&stack_ok);
#endif  // DEBUG.

  if (FLAG_trace_functions) {
    __ pushq(RAX);  // Preserve result.
    const Function& function =
        Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(RBX, function);
    __ pushq(RBX);
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kTraceFunctionExitRuntimeEntry);
    __ popq(RAX);  // Remove argument.
    __ popq(RAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  // Generate 8 bytes of NOPs so that the debugger can patch the
  // return pattern with a call to the debug stub.
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  AddCurrentDescriptor(PcDescriptors::kReturn,
                       AstNode::kNoId,
                       instr->token_index());
}


void FlowGraphCompiler::VisitBranch(BranchInstr* instr) {
  Bailout("BranchInstr");
}


void FlowGraphCompiler::CompileGraph() {
  const Function& function = parsed_function_.function();
  if ((function.num_optional_parameters() != 0)) {
    Bailout("function has optional parameters");
  }
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  LocalScope* context_owner = NULL;
  const int parameter_count = function.num_fixed_parameters();
  const int first_parameter_index = 1 + parameter_count;
  const int first_local_index = -1;
  int first_free_frame_index =
      scope->AllocateVariables(first_parameter_index,
                               parameter_count,
                               first_local_index,
                               scope,
                               &context_owner);
  set_stack_local_count(first_local_index - first_free_frame_index);

  if (blocks_->length() != 1) Bailout("more than 1 basic block");

  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  __ EnterFrame(stack_local_count() * kWordSize);
#ifdef DEBUG
  const bool check_arguments = true;
#else
  const bool check_arguments = function.IsClosureFunction();
#endif
  if (check_arguments) {
    // Check that num_fixed <= argc <= num_params.
    Label argc_in_range;
    // Total number of args is the first Smi in args descriptor array (R10).
    __ movq(RAX, FieldAddress(R10, Array::data_offset()));
    __ cmpq(RAX, Immediate(Smi::RawValue(parameter_count)));
    __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
    if (function.IsClosureFunction()) {
      GenerateCallRuntime(AstNode::kNoId,
                          function.token_index(),
                          kClosureArgumentMismatchRuntimeEntry);
    } else {
      __ Stop("Wrong number of arguments");
    }
    __ Bind(&argc_in_range);
  }

  // Initialize locals to null.
  if (stack_local_count() > 0) {
    __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(Object::null())));
    for (int i = 0; i < stack_local_count(); ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      __ movq(Address(RBP, (first_local_index - i) * kWordSize), RAX);
    }
  }

  // Generate stack overflow check.
  __ movq(TMP, Immediate(Isolate::Current()->stack_limit_address()));
  __ cmpq(RSP, Address(TMP, 0));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow, Assembler::kNearJump);
  GenerateCallRuntime(AstNode::kNoId,
                      function.token_index(),
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

  VisitBlocks(*blocks_);

  __ int3();
  // Emit function patching code. This will be swapped with the first 13 bytes
  // at entry point.
  pc_descriptors_list_->AddDescriptor(PcDescriptors::kPatchCode,
                                      assembler_->CodeSize(),
                                      AstNode::kNoId,
                                      0,
                                      -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


// Infrastructure copied from class CodeGenerator.
void FlowGraphCompiler::GenerateCallRuntime(intptr_t node_id,
                                            intptr_t token_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntimeFromDart(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t node_id,
                                             intptr_t token_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      node_id,
                                      token_index,
                                      CatchClauseNode::kInvalidTryIndex);
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  // We don't compile exception handlers yet.
  code.set_exception_handlers(
      ExceptionHandlers::Handle(ExceptionHandlers::New(0)));
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64
