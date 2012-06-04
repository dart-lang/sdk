// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler_stats.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, compiler_stats);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, trace_functions);


void DeoptimizationStub::GenerateCode(FlowGraphCompilerShared* compiler) {
  Assembler* assem = compiler->assembler();
#define __ assem->
  __ Comment("Deopt stub for id %d", deopt_id_);
  __ Bind(entry_label());
  for (intptr_t i = 0; i < registers_.length(); i++) {
    if (registers_[i] != kNoRegister) {
      __ pushl(registers_[i]);
    }
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
    : FlowGraphCompilerShared(assembler,
                              parsed_function,
                              block_order,
                              is_optimizing) {}


#define __ assembler()->

void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is load field node.
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ movl(EAX, FieldAddress(EAX, offset));
  __ ret();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  // TOS: return address.
  // +1 : value
  // +2 : receiver.
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // Receiver.
  __ movl(EBX, Address(ESP, 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX, FieldAddress(EAX, offset), EBX);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(EAX, raw_null);
  __ ret();
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t cid,
                                            intptr_t token_index,
                                            intptr_t try_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntime(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, cid, token_index, try_index);
}


void FlowGraphCompiler::CopyParameters() {
  const Function& function = parsed_function().function();
  LocalScope* scope = parsed_function().node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  ASSERT(parsed_function().first_parameter_index() ==
         ParsedFunction::kFirstLocalSlotIndex);
  // Copy positional arguments.
  // Check that no fewer than num_fixed_params positional arguments are passed
  // in and that no more than num_params arguments are passed in.
  // Passed argument i at fp[1 + argc - i]
  // copied to fp[ParsedFunction::kFirstLocalSlotIndex - i].
  const int num_params = num_fixed_params + num_opt_params;

  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EBX, FieldAddress(EDX, Array::data_offset()));
  // Check that num_args <= num_params.
  Label wrong_num_arguments;
  __ cmpl(EBX, Immediate(Smi::RawValue(num_params)));
  __ j(GREATER, &wrong_num_arguments);
  // Number of positional args is the second Smi in descriptor array (EDX).
  __ movl(ECX, FieldAddress(EDX, Array::data_offset() + (1 * kWordSize)));
  // Check that num_pos_args >= num_fixed_params.
  __ cmpl(ECX, Immediate(Smi::RawValue(num_fixed_params)));
  __ j(LESS, &wrong_num_arguments);
  // Since EBX and ECX are Smi, use TIMES_2 instead of TIMES_4.
  // Let EBX point to the last passed positional argument, i.e. to
  // fp[1 + num_args - (num_pos_args - 1)].
  __ subl(EBX, ECX);
  __ leal(EBX, Address(EBP, EBX, TIMES_2, 2 * kWordSize));
  // Let EDI point to the last copied positional argument, i.e. to
  // fp[ParsedFunction::kFirstLocalSlotIndex - (num_pos_args - 1)].
  const int index = ParsedFunction::kFirstLocalSlotIndex + 1;
  __ leal(EDI, Address(EBP, (index * kWordSize)));
  __ subl(EDI, ECX);  // ECX is a Smi, subtract twice for TIMES_4 scaling.
  __ subl(EDI, ECX);
  __ SmiUntag(ECX);
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(EBX, ECX, TIMES_4, 0);
  const Address copy_addr(EDI, ECX, TIMES_4, 0);
  __ Bind(&loop);
  __ movl(EAX, argument_addr);
  __ movl(copy_addr, EAX);
  __ Bind(&loop_condition);
  __ decl(ECX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);

  // Copy or initialize optional named arguments.
  ASSERT(num_opt_params > 0);  // Or we would not have to copy arguments.
  // Start by alphabetically sorting the names of the optional parameters.
  LocalVariable** opt_param = new LocalVariable*[num_opt_params];
  int* opt_param_position = new int[num_opt_params];
  for (int pos = num_fixed_params; pos < num_params; pos++) {
    LocalVariable* parameter = scope->VariableAt(pos);
    const String& opt_param_name = parameter->name();
    int i = pos - num_fixed_params;
    while (--i >= 0) {
      LocalVariable* param_i = opt_param[i];
      const intptr_t result = opt_param_name.CompareTo(param_i->name());
      ASSERT(result != 0);
      if (result > 0) break;
      opt_param[i + 1] = opt_param[i];
      opt_param_position[i + 1] = opt_param_position[i];
    }
    opt_param[i + 1] = parameter;
    opt_param_position[i + 1] = pos;
  }
  // Generate code handling each optional parameter in alphabetical order.
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(EBX, FieldAddress(EDX, Array::data_offset()));
  // Number of positional args is the second Smi in descriptor array (EDX).
  __ movl(ECX, FieldAddress(EDX, Array::data_offset() + (1 * kWordSize)));
  __ SmiUntag(ECX);
  // Let EBX point to the first passed argument, i.e. to fp[1 + argc - 0].
  __ leal(EBX, Address(EBP, EBX, TIMES_2, kWordSize));  // EBX is Smi.
  // Let EDI point to the name/pos pair of the first named argument.
  __ leal(EDI, FieldAddress(EDX, Array::data_offset() + (2 * kWordSize)));
  for (int i = 0; i < num_opt_params; i++) {
    // Handle this optional parameter only if k or fewer positional arguments
    // have been passed, where k is the position of this optional parameter in
    // the formal parameter list.
    Label load_default_value, assign_optional_parameter, next_parameter;
    const int param_pos = opt_param_position[i];
    __ cmpl(ECX, Immediate(param_pos));
    __ j(GREATER, &next_parameter, Assembler::kNearJump);
    // Check if this named parameter was passed in.
    __ movl(EAX, Address(EDI, 0));  // Load EAX with the name of the argument.
    __ CompareObject(EAX, opt_param[i]->name());
    __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
    // Load EAX with passed-in argument at provided arg_pos, i.e. at
    // fp[1 + argc - arg_pos].
    __ movl(EAX, Address(EDI, kWordSize));  // EAX is arg_pos as Smi.
    __ addl(EDI, Immediate(2 * kWordSize));  // Point to next name/pos pair.
    __ negl(EAX);
    Address argument_addr(EBX, EAX, TIMES_2, 0);  // EAX is a negative Smi.
    __ movl(EAX, argument_addr);
    __ jmp(&assign_optional_parameter, Assembler::kNearJump);
    __ Bind(&load_default_value);
    // Load EAX with default argument at pos.
    const Object& value = Object::ZoneHandle(
        parsed_function().default_parameter_values().At(
            param_pos - num_fixed_params));
    __ LoadObject(EAX, value);
    __ Bind(&assign_optional_parameter);
    // Assign EAX to fp[ParsedFunction::kFirstLocalSlotIndex - param_pos].
    // We do not use the final allocation index of the variable here, i.e.
    // scope->VariableAt(i)->index(), because captured variables still need
    // to be copied to the context that is not yet allocated.
    const Address param_addr(
        EBP, (ParsedFunction::kFirstLocalSlotIndex - param_pos) * kWordSize);
    __ movl(param_addr, EAX);
    __ Bind(&next_parameter);
  }
  delete[] opt_param;
  delete[] opt_param_position;
  // Check that EDI now points to the null terminator in the array descriptor.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label all_arguments_processed;
  __ cmpl(Address(EDI, 0), raw_null);
  __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);

  __ Bind(&wrong_num_arguments);
  if (StackSize() != 0) {
    // We need to unwind the space we reserved for locals and copied parameters.
    // The NoSuchMethodFunction stub does not expect to see that area on the
    // stack.
    __ addl(ESP, Immediate(StackSize() * kWordSize));
  }
  if (function.IsClosureFunction()) {
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kClosureArgumentMismatchRuntimeEntry);
  } else {
    // Invoke noSuchMethod function.
    const int kNumArgsChecked = 1;
    ICData& ic_data = ICData::ZoneHandle();
    ic_data = ICData::New(function,
                          String::Handle(function.name()),
                          AstNode::kNoId,
                          kNumArgsChecked);
    __ LoadObject(ECX, ic_data);
    // EBP - 4 : PC marker, allows easy identification of RawInstruction obj.
    // EBP : points to previous frame pointer.
    // EBP + 4 : points to return address.
    // EBP + 8 : address of last argument (arg n-1).
    // ESP + 8 + 4*(n-1) : address of first argument (arg 0).
    // ECX : ic-data.
    // EDX : arguments descriptor array.
    __ call(&StubCode::CallNoSuchMethodFunctionLabel());
  }

  if (FLAG_trace_functions) {
    __ pushl(EAX);  // Preserve result.
    __ PushObject(Function::ZoneHandle(function.raw()));
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        CatchClauseNode::kInvalidTryIndex,
                        kTraceFunctionExitRuntimeEntry);
    __ popl(EAX);  // Remove argument.
    __ popl(EAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // EDX : arguments descriptor array.
  // Total number of args is the first Smi in args descriptor array (EDX).
  __ movl(ECX, FieldAddress(EDX, Array::data_offset()));
  __ SmiUntag(ECX);
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(EBP, ECX, TIMES_4, 2 * kWordSize);
  __ Bind(&null_args_loop);
  __ movl(original_argument_addr, raw_null);
  __ Bind(&null_args_loop_condition);
  __ decl(ECX);
  __ j(POSITIVE, &null_args_loop, Assembler::kNearJump);
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    __ int3();
    __ jmp(&StubCode::FixCallersTargetLabel());
    return;
  }
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function().function();

  const int parameter_count = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().copied_parameter_count();
  const int local_count = parsed_function().stack_local_count();
  AssemblerMacros::EnterDartFrame(assembler(), (StackSize() * kWordSize));
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
    const int base = parsed_function().first_stack_local_index();
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
    AstPrinter::PrintFunctionScope(parsed_function());
  }

  VisitBlocks();

  __ int3();
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kPatchCode,
                                      assembler()->CodeSize(),
                                      AstNode::kNoId,
                                      0,
                                      -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


intptr_t FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                             const ICData& ic_data,
                                             const Array& arguments_descriptor,
                                             intptr_t argument_count) {
  __ LoadObject(ECX, ic_data);
  __ LoadObject(EDX, arguments_descriptor);

  __ call(target_label);
  const intptr_t descr_offset = assembler()->CodeSize();
  __ Drop(argument_count);
  return descr_offset;
}


intptr_t FlowGraphCompiler::EmitStaticCall(const Function& function,
                                           const Array& arguments_descriptor,
                                           intptr_t argument_count) {
  __ LoadObject(ECX, function);
  __ LoadObject(EDX, arguments_descriptor);
  __ call(&StubCode::CallStaticFunctionLabel());
  const intptr_t descr_offset = assembler()->CodeSize();
  __ Drop(argument_count);
  return descr_offset;
}


void FlowGraphCompiler::GenerateCall(intptr_t token_index,
                                     intptr_t try_index,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind) {
  __ call(label);
  AddCurrentDescriptor(kind, AstNode::kNoId, token_index, try_index);
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
  for (intptr_t i = 0; i < block_order().length(); ++i) {
    __ Comment("B%d", i);
    // Compile the block entry.
    set_current_block(block_order()[i]);
    current_block()->PrepareEntry(this);
    Instruction* instr = current_block()->StraightLineSuccessor();
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
      if ((i == block_order().length() - 1) ||
          (block_order()[i + 1] != successor)) {
        __ jmp(GetBlockLabel(successor));
      }
    }
  }
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
