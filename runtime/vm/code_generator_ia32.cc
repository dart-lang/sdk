// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/code_generator.h"

#include "lib/error.h"
#include "vm/ast_printer.h"
#include "vm/class_finalizer.h"
#include "vm/code_descriptors.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/intrinsifier.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, print_ast);
DEFINE_FLAG(bool, print_scopes, false, "Print scopes of local variables.");
DEFINE_FLAG(bool, trace_functions, false, "Trace entry of each function.");
DEFINE_FLAG(bool, print_ic_in_optimized, false,
    "Debugging helper to identify potential performance pitfalls.");
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, trace_functions);


#define __ assembler_->


CodeGeneratorState::CodeGeneratorState(CodeGenerator* codegen)
    : StackResource(Isolate::Current()),
      codegen_(codegen),
      parent_(codegen->state()) {
  if (parent_ != NULL) {
    root_node_ = parent_->root_node_;
    current_try_index_ = parent_->current_try_index_;
  } else {
    root_node_ = NULL;
    current_try_index_ = CatchClauseNode::kInvalidTryIndex;
  }
  codegen_->set_state(this);
}


CodeGeneratorState::~CodeGeneratorState() {
  codegen_->set_state(parent_);
}


CodeGenerator::CodeGenerator(Assembler* assembler,
                             const ParsedFunction& parsed_function)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      locals_space_size_(-1),
      state_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_builder_(NULL),
      exception_handlers_list_(NULL),
      try_index_(CatchClauseNode::kInvalidTryIndex),
      context_level_(0) {
  ASSERT(assembler_ != NULL);
  ASSERT(parsed_function.node_sequence() != NULL);
  ASSERT(Isolate::Current()->long_jump_base()->IsSafeToJump());
  pc_descriptors_list_ = new DescriptorList();
  // We do not build any stack maps in the unoptimizing compiler.
  exception_handlers_list_ = new ExceptionHandlerList();
}


void CodeGenerator::IntrinsifyGetter() {
  // TOS: return address.
  // +1 : receiver.
  // Sequence node has one return node, its input is oad field node.
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


void CodeGenerator::IntrinsifySetter() {
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



bool CodeGenerator::TryIntrinsify() {
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
    return Intrinsifier::Intrinsify(parsed_function().function(), assembler_);
  }
  return false;
}


bool CodeGenerator::IsResultNeeded(AstNode* node) const {
  return !state()->IsRootNode(node);
}


// NOTE: First 5 bytes of the code may be patched with a jump instruction. Do
// not emit any objects in the first 5 bytes.
void CodeGenerator::GenerateCode() {
  CodeGeneratorState codegen_state(this);
  if (FLAG_print_scopes && FLAG_print_ast) {
    // Print the function scope before code generation.
    AstPrinter::PrintFunctionScope(parsed_function_);
  }
  if (FLAG_print_ast) {
    // Print the function ast before code generation.
    AstPrinter::PrintFunctionNodes(parsed_function_);
  }
  if (FLAG_trace_functions) {
    // Preserve ECX (ic-data array or object) and EDX (arguments descriptor).
    __ nop(2);  // Make sure the code is patchable.
    __ pushl(ECX);
    __ pushl(EDX);
    const Function& function =
        Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(EAX, function);
    __ pushl(EAX);
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kTraceFunctionEntryRuntimeEntry);
    __ popl(EAX);
    __ popl(EDX);
    __ popl(ECX);
  }

  const bool code_generation_finished = TryIntrinsify();
  // In some cases intrinsifier can generate all code and no AST based
  // code generation is needed. In some cases slow-paths (e.g., overflows) are
  // implemented by the AST based code generation and 'code_generation_finished'
  // is false.
  if (!code_generation_finished) {
    GeneratePreEntryCode();
    GenerateEntryCode();
    if (FLAG_print_scopes) {
      // Print the function scope (again) after generating the prologue in order
      // to see annotations such as allocation indices of locals.
      if (FLAG_print_ast) {
        // Second printing.
        OS::Print("Annotated ");
      }
      AstPrinter::PrintFunctionScope(parsed_function_);
    }
    parsed_function_.node_sequence()->Visit(this);
  }
  // End of code.
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


void CodeGenerator::GenerateDeferredCode() {
}


// Pre entry code is called before the frame has been constructed:
// - check for stack overflow.
// - optionally count function invocations.
// - optionally trigger optimizing compiler if invocation threshold has been
//   reached.
// Note that first 5 bytes may be patched with a jump.
// TODO(srdjan): Add check that no object is inlined in the first
// 5 bytes (length of a jump instruction).
void CodeGenerator::GeneratePreEntryCode() {
  // TODO(srdjan): Still needed?
  __ nop(5);
}


void CodeGenerator::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void CodeGenerator::FinalizeStackmaps(const Code& code) {
  if (stackmap_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_builder_->FinalizeStackmaps(code)));
  }
}


void CodeGenerator::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void CodeGenerator::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
}


void CodeGenerator::GenerateLoadVariable(Register dst,
                                         const LocalVariable& variable) {
  if (variable.is_captured()) {
    // The variable lives in the context.
    intptr_t delta = context_level() - variable.owner()->context_level();
    ASSERT(delta >= 0);
    Register base = CTX;
    while (delta-- > 0) {
      __ movl(dst, FieldAddress(base, Context::parent_offset()));
      base = dst;
    }
    __ movl(dst,
            FieldAddress(base, Context::variable_offset(variable.index())));
  } else {
    // The variable lives in the current stack frame.
    __ movl(dst, Address(EBP, variable.index() * kWordSize));
  }
}


void CodeGenerator::GenerateStoreVariable(const LocalVariable& variable,
                                          Register src,
                                          Register scratch) {
  if (variable.is_captured()) {
    // The variable lives in the context.
    intptr_t delta = context_level() - variable.owner()->context_level();
    ASSERT(delta >= 0);
    Register base = CTX;
    while (delta-- > 0) {
      __ movl(scratch, FieldAddress(base, Context::parent_offset()));
      base = scratch;
    }
    __ StoreIntoObject(
        base,
        FieldAddress(base, Context::variable_offset(variable.index())),
        src);
  } else {
    // The variable lives in the current stack frame.
    __ movl(Address(EBP, variable.index() * kWordSize), src);
  }
}


void CodeGenerator::GeneratePushVariable(const LocalVariable& variable,
                                         Register scratch) {
  if (variable.is_captured()) {
    // The variable lives in the context.
    intptr_t delta = context_level() - variable.owner()->context_level();
    ASSERT(delta >= 0);
    Register base = CTX;
    while (delta-- > 0) {
      __ movl(scratch, FieldAddress(base, Context::parent_offset()));
      base = scratch;
    }
    __ pushl(FieldAddress(base, Context::variable_offset(variable.index())));
  } else {
    // The variable lives in the current stack frame.
    __ pushl(Address(EBP, variable.index() * kWordSize));
  }
}


void CodeGenerator::GenerateInstanceCall(
    intptr_t node_id,
    intptr_t token_index,
    const String& function_name,
    int num_arguments,
    const Array& optional_arguments_names,
    intptr_t num_args_checked) {
  if (FLAG_print_ic_in_optimized && IsOptimizing()) {
    OS::Print("Generate IC in optimized code: id %d name: '%s'\n",
        node_id, function_name.ToCString());
  }
  ASSERT(num_args_checked > 0);  // At least receiver check is necessary.
  // Set up the function name and number of arguments (including the receiver)
  // to the InstanceCall stub which will resolve the correct entrypoint for
  // the operator and call it.
  ICData& ic_data = ICData::ZoneHandle();
  ic_data = ICData::New(parsed_function().function(),
                        function_name,
                        node_id,
                        num_args_checked);
  __ LoadObject(ECX, ic_data);
  __ LoadObject(EDX, ArgumentsDescriptor(num_arguments,
                                         optional_arguments_names));
  uword label_address = 0;
  switch (num_args_checked) {
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

  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kIcCall,
                       node_id,
                       token_index);
  __ addl(ESP, Immediate(num_arguments * kWordSize));
}


// Input parameters:
//   ESP : points to return address.
//   ESP + 4 : address of last argument (arg n-1).
//   ESP + 4*n : address of first argument (arg 0).
//   EDX : arguments descriptor array.
void CodeGenerator::GenerateEntryCode() {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  const Function& function = parsed_function_.function();

  // 1. Compute the frame size and enter the frame (reserving local space
  // for copied incoming and default arguments and stack-allocated local
  // variables).
  //
  // TODO(regis): We may give up reserving space on stack for args/locals
  // because pushes of initial values may be more effective than moves.
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  const int num_copied_params = parsed_function_.copied_parameter_count();
  const int stack_slot_count =
      num_copied_params + parsed_function_.stack_local_count();
  set_locals_space_size(stack_slot_count * kWordSize);
  __ EnterFrame(locals_space_size());

  // 2. Optionally check if the number of arguments matches.  We check the
  // number of passed arguments when we have to copy them due to the
  // presence of optional named parameters.  No such checking code is
  // generated if only fixed parameters are declared, unless we are in debug
  // mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
    ASSERT(num_opt_params == 0);
#if defined(DEBUG)
    const bool check_arguments = true;  // Always check arguments in debug mode.
#else
    // The number of arguments passed to closure functions must always be
    // checked here, because no resolving stub (normally responsible for the
    // check) is involved in closure calls.
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (EDX).
      __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
      __ cmpl(EAX, Immediate(Smi::RawValue(num_fixed_params)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        GenerateCallRuntime(AstNode::kNoId,
                            0,
                            kClosureArgumentMismatchRuntimeEntry);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
  } else {
    ASSERT(parsed_function_.first_parameter_index() == -1);
    // Copy positional arguments.
    // Check that no fewer than num_fixed_params positional arguments are passed
    // in and that no more than num_params arguments are passed in.
    // Passed argument i at fp[1 + argc - i] copied to fp[-1 - i].
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
    // fp[-1 - (num_pos_args - 1)].
    __ movl(EDI, EBP);
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
    __ leal(EBX, Address(EBP, EBX, TIMES_2, kWordSize));
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
          parsed_function_.default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(EAX, value);
      __ Bind(&assign_optional_parameter);
      // Assign EAX to fp[-1 - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const Address param_addr(EBP, (-1 - param_pos) * kWordSize);
      __ movl(param_addr, EAX);
      __ Bind(&next_parameter);
    }
    delete[] opt_param;
    delete[] opt_param_position;
    // Check that EDI now points to the null terminator in the array descriptor.
    Label all_arguments_processed;
    __ cmpl(Address(EDI, 0), raw_null);
    __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);

    __ Bind(&wrong_num_arguments);
    if (function.IsClosureFunction()) {
      GenerateCallRuntime(AstNode::kNoId,
                          0,
                          kClosureArgumentMismatchRuntimeEntry);
    } else {
      // Invoke noSuchMethod function.
      const int kNumArgsChecked = 1;
      ICData& ic_data = ICData::ZoneHandle();
      ic_data = ICData::New(parsed_function().function(),
                            String::Handle(function.name()),
                            AstNode::kNoId,
                            kNumArgsChecked);
      __ LoadObject(ECX, ic_data);
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

  // 3. Initialize (non-argument) stack-allocated locals to null.
  //
  // TODO(regis): For now, always unroll the init loop. Decide later above
  // which threshold to implement a loop.  Consider emitting pushes instead
  // of moves.
  const int base = parsed_function_.first_stack_local_index();
  for (int index = 0; index < parsed_function_.stack_local_count(); ++index) {
    if (index == 0) {
      __ movl(EAX, raw_null);
    }
    __ movl(Address(EBP, (base - index) * kWordSize), EAX);
  }

  // 4. Generate the stack overflow check.
  __ cmpl(ESP,
          Address::Absolute(Isolate::Current()->stack_limit_address()));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow);
  GenerateCallRuntime(AstNode::kNoId,
                      0,
                      kStackOverflowRuntimeEntry);
  __ Bind(&no_stack_overflow);
}


void CodeGenerator::GenerateReturnEpilog(ReturnNode* node) {
  // Unchain the context(s) up to context level 0.
  intptr_t current_context_level = context_level();
  ASSERT(current_context_level >= 0);
  if (parsed_function_.saved_context_var() != NULL) {
    // CTX on entry was saved, but not linked as context parent.
    GenerateLoadVariable(CTX, *parsed_function_.saved_context_var());
  } else {
    while (current_context_level-- > 0) {
      __ movl(CTX, FieldAddress(CTX, Context::parent_offset()));
    }
  }
#ifdef DEBUG
  // Check that the entry stack size matches the exit stack size.
  __ movl(EDX, EBP);
  __ subl(EDX, ESP);
  ASSERT(locals_space_size() >= 0);
  __ cmpl(EDX, Immediate(locals_space_size()));
  Label wrong_stack;
  __ j(NOT_EQUAL, &wrong_stack, Assembler::kNearJump);
#endif  // DEBUG.

  if (!IsOptimizing()) {
    // Count only in unoptimized code.
    // TODO(srdjan): Replace the counting code with a type feedback
    // collection and counting stub.
    const Function& function =
          Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(EBX, function);
    __ incl(FieldAddress(EBX, Function::usage_counter_offset()));
    if (CodeGenerator::CanOptimize()) {
      // Do not optimize if usage count must be reported.
      __ cmpl(FieldAddress(EBX, Function::usage_counter_offset()),
          Immediate(FLAG_optimization_counter_threshold));
      Label not_yet_hot;
      __ j(LESS_EQUAL, &not_yet_hot);
      __ pushl(EAX);  // Preserve result.
      __ pushl(EBX);  // Argument for runtime: function to optimize.
      __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
      __ popl(EBX);  // Remove argument.
      __ popl(EAX);  // Restore result.
      __ Bind(&not_yet_hot);
    }
  }
  if (FLAG_trace_functions) {
    const Function& function =
        Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(EBX, function);
    __ pushl(EAX);  // Preserve result.
    __ pushl(EBX);
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kTraceFunctionExitRuntimeEntry);
    __ popl(EAX);  // Remove argument.
    __ popl(EAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();
  // Add a NOP to make return code pattern 5 bytes long for patching
  // in breakpoints during debugging.
  __ nop(1);
  AddCurrentDescriptor(PcDescriptors::kReturn,
                       node->id(),
                       node->token_index());

#ifdef DEBUG
  __ Bind(&wrong_stack);
  __ Stop("Exit stack size does not match the entry stack size.");
#endif  // DEBUG.
}


void CodeGenerator::VisitReturnNode(ReturnNode* node) {
  ASSERT(!IsResultNeeded(node));
  ASSERT(node->value() != NULL);

  if (!node->value()->IsLiteralNode()) {
    node->value()->Visit(this);
    // The result of the return value is now on top of the stack.
  }

  // Generate inlined code for all finally blocks as we are about to transfer
  // control out of the 'try' blocks if any.
  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    node->InlinedFinallyNodeAt(i)->Visit(this);
  }

  if (node->value()->IsLiteralNode()) {
    // Load literal value into EAX.
    const Object& literal = node->value()->AsLiteralNode()->literal();
    if (literal.IsSmi()) {
      __ movl(EAX, Immediate(reinterpret_cast<int32_t>(literal.raw())));
    } else {
      __ LoadObject(EAX, literal);
    }
  } else {
    // Pop the previously evaluated result value into EAX.
    __ popl(EAX);
  }

  // Generate type check.
  if (FLAG_enable_type_checks) {
    const RawFunction::Kind kind = parsed_function().function().kind();
    const bool is_implicit_getter =
        (kind == RawFunction::kImplicitGetter) ||
        (kind == RawFunction::kConstImplicitGetter);
    const bool is_static = parsed_function().function().is_static();
    // Implicit getters do not need a type check at return, unless they compute
    // the initial value of a static field.
    if (is_static || !is_implicit_getter) {
      GenerateAssertAssignable(
          node->id(),
          node->value()->token_index(),
          node->value(),
          AbstractType::ZoneHandle(parsed_function().function().result_type()),
          String::ZoneHandle(String::NewSymbol("function result")));
    }
  }
  GenerateReturnEpilog(node);
}


void CodeGenerator::VisitLiteralNode(LiteralNode* node) {
  if (!IsResultNeeded(node)) return;
  __ PushObject(node->literal());
}


void CodeGenerator::VisitTypeNode(TypeNode* node) {
  // Type nodes are handled specially by the code generator.
  UNREACHABLE();
}


void CodeGenerator::VisitAssignableNode(AssignableNode* node) {
  ASSERT(FLAG_enable_type_checks);
  node->expr()->Visit(this);
  __ popl(EAX);
  GenerateAssertAssignable(node->id(),
                           node->token_index(),
                           node->expr(),
                           node->type(),
                           node->dst_name());
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();
  if (function.IsNonImplicitClosureFunction()) {
    // The context scope may have already been set by the new non-optimizing
    // compiler.  If it was not, set it here.
    if (function.context_scope() == ContextScope::null()) {
      const intptr_t current_context_level = context_level();
      const ContextScope& context_scope = ContextScope::ZoneHandle(
          node->scope()->PreserveOuterScope(current_context_level));
      ASSERT(!function.HasCode());
      function.set_context_scope(context_scope);
    }
  } else if (function.IsImplicitInstanceClosureFunction()) {
    node->receiver()->Visit(this);
  }
  ASSERT(function.context_scope() != ContextScope::null());

  // The function type of a closure may have type arguments. In that case, pass
  // the type arguments of the instantiator.
  const Class& cls = Class::Handle(function.signature_class());
  ASSERT(!cls.IsNull());
  const bool requires_type_arguments = cls.HasTypeArguments();
  if (requires_type_arguments) {
    ASSERT(!function.IsImplicitStaticClosureFunction());
    GenerateInstantiatorTypeArguments(node->token_index());
  }
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(function));
  const ExternalLabel label(function.ToCString(), stub.EntryPoint());
  GenerateCall(node->token_index(), &label, PcDescriptors::kOther);
  if (requires_type_arguments) {
    __ popl(ECX);  // Pop type arguments.
  }
  if (function.IsImplicitInstanceClosureFunction()) {
    __ popl(ECX);  // Pop receiver.
  }
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitPrimaryNode(PrimaryNode* node) {
  // PrimaryNodes are temporary during parsing.
  UNREACHABLE();
}


void CodeGenerator::VisitCloneContextNode(CloneContextNode *node) {
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(CTX);
  GenerateCallRuntime(node->id(),
      node->token_index(), kCloneContextRuntimeEntry);
  __ popl(EAX);
  __ popl(CTX);  // result: cloned context. Set as current context.
}


void CodeGenerator::VisitSequenceNode(SequenceNode* node_sequence) {
  CodeGeneratorState codegen_state(this);
  LocalScope* scope = node_sequence->scope();
  const intptr_t num_context_variables =
      (scope != NULL) ? scope->num_context_variables() : 0;
  intptr_t previous_context_level = context_level();
  if (num_context_variables > 0) {
    // The loop local scope declares variables that are captured.
    // Allocate and chain a new context.
    __ movl(EDX, Immediate(num_context_variables));
    const ExternalLabel label("alloc_context",
                              StubCode::AllocateContextEntryPoint());
    GenerateCall(node_sequence->token_index(), &label, PcDescriptors::kOther);

    // If this node_sequence is the body of the function being compiled, and if
    // this function is not a closure, do not link the current context as the
    // parent of the newly allocated context, as it is not accessible. Instead,
    // save it in a pre-allocated variable and restore it on exit.
    if ((node_sequence == parsed_function_.node_sequence()) &&
        (parsed_function_.saved_context_var() != NULL)) {
      GenerateStoreVariable(
          *parsed_function_.saved_context_var(), CTX, kNoRegister);
      const Immediate raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(CTX, raw_null);
    }

    // Chain the new context in EAX to its parent in CTX.
    __ StoreIntoObject(EAX, FieldAddress(EAX, Context::parent_offset()), CTX);
    // Set new context as current context.
    __ movl(CTX, EAX);
    set_context_level(scope->context_level());

    // If this node_sequence is the body of the function being compiled, copy
    // the captured parameters from the frame into the context.
    if (node_sequence == parsed_function_.node_sequence()) {
      ASSERT(scope->context_level() == 1);
      const Immediate raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      const Function& function = parsed_function_.function();
      const int num_params = function.NumberOfParameters();
      int param_frame_index =
          (num_params == function.num_fixed_parameters()) ? 1 + num_params : -1;
      for (int pos = 0; pos < num_params; param_frame_index--, pos++) {
        LocalVariable* parameter = scope->VariableAt(pos);
        ASSERT(parameter->owner() == scope);
        if (parameter->is_captured()) {
          // Copy parameter from local frame to current context.
          const Address local_addr(EBP, param_frame_index * kWordSize);
          __ movl(EAX, local_addr);
          GenerateStoreVariable(*parameter, EAX, EDX);
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          __ movl(local_addr, raw_null);
        }
      }
    }
  }
  // If this node_sequence is the body of the function being compiled, generate
  // code checking the type of the actual arguments.
  if (FLAG_enable_type_checks &&
      (node_sequence == parsed_function_.node_sequence())) {
    GenerateArgumentTypeChecks();
  }
  for (int i = 0; i < node_sequence->length(); i++) {
    AstNode* child_node = node_sequence->NodeAt(i);
    state()->set_root_node(child_node);
    child_node->Visit(this);
  }

  // Unchain the previously allocated context.
  if ((node_sequence == parsed_function_.node_sequence()) &&
      (parsed_function_.saved_context_var() != NULL)) {
    ASSERT(num_context_variables > 0);
    GenerateLoadVariable(CTX, *parsed_function_.saved_context_var());
  } else if (num_context_variables > 0) {
    __ movl(CTX, FieldAddress(CTX, Context::parent_offset()));
  }

  // If this node sequence is labeled, a break out of the sequence will have
  // taken care of unchaining the context.
  if (node_sequence->label() != NULL) {
    __ Bind(node_sequence->label()->break_label());
    // Outermost sequence cannot have a label.
    ASSERT(node_sequence != parsed_function_.node_sequence());
  }
  set_context_level(previous_context_level);
}


void CodeGenerator::VisitArgumentListNode(ArgumentListNode* arguments) {
  for (int i = 0; i < arguments->length(); i++) {
    AstNode* argument = arguments->NodeAt(i);
    argument->Visit(this);
  }
}


void CodeGenerator::VisitArrayNode(ArrayNode* node) {
  // Evaluate the array elements.
  for (int i = 0; i < node->length(); i++) {
    AstNode* element = node->ElementAt(i);
    element->Visit(this);
  }

  // Allocate the array.
  //   EDX : Array length as Smi.
  //   ECX : element type for the array.
  __ movl(EDX, Immediate(Smi::RawValue(node->length())));
  const AbstractTypeArguments& element_type = node->type_arguments();
  ASSERT(element_type.IsNull() || element_type.IsInstantiated());
  __ LoadObject(ECX, element_type);
  GenerateCall(node->token_index(),
               &StubCode::AllocateArrayLabel(),
               PcDescriptors::kOther);

  // Pop the element values from the stack into the array.
  __ leal(ECX, FieldAddress(EAX, Array::data_offset()));
  for (int i = node->length() - 1; i >= 0; i--) {
    __ popl(Address(ECX, i * kWordSize));
  }

  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitLoadLocalNode(LoadLocalNode* node) {
  if (node->HasPseudo()) {
    node->pseudo()->Visit(this);
    __ popl(EAX);  // Discard result.
  }
  // Load the value of the local variable and push it onto the expression stack.
  if (IsResultNeeded(node)) {
    GeneratePushVariable(node->local(), EAX);
  }
}


void CodeGenerator::VisitStoreLocalNode(StoreLocalNode* node) {
  node->value()->Visit(this);
  __ popl(EAX);
  if (FLAG_enable_type_checks) {
    GenerateAssertAssignable(node->id(),
                             node->value()->token_index(),
                             node->value(),
                             node->local().type(),
                             node->local().name());
  }
  GenerateStoreVariable(node->local(), EAX, EDX);
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitLoadInstanceFieldNode(LoadInstanceFieldNode* node) {
  node->instance()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  __ popl(EAX);  // Instance.
  __ movl(EAX, FieldAddress(EAX, node->field().Offset()));
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitStoreInstanceFieldNode(StoreInstanceFieldNode* node) {
  node->instance()->Visit(this);
  node->value()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  __ popl(EAX);  // Value.
  if (FLAG_enable_type_checks) {
    GenerateAssertAssignable(node->id(),
                             node->value()->token_index(),
                             node->value(),
                             AbstractType::ZoneHandle(node->field().type()),
                             String::ZoneHandle(node->field().name()));
  }
  __ popl(EDX);  // Instance.
  __ StoreIntoObject(EDX, FieldAddress(EDX, node->field().Offset()), EAX);
  ASSERT(!IsResultNeeded(node));
}


// Expects array and index on stack and returns result in EAX.
void CodeGenerator::GenerateLoadIndexed(intptr_t node_id,
                                        intptr_t token_index) {
  // Invoke the [] operator on the receiver object with the index as argument.
  const String& operator_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));
  const int kNumArguments = 2;  // Receiver and index.
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node_id,
                       token_index,
                       operator_name,
                       kNumArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
}


void CodeGenerator::VisitLoadIndexedNode(LoadIndexedNode* node) {
  node->array()->Visit(this);
  // Now compute the index.
  node->index_expr()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  GenerateLoadIndexed(node->id(), node->token_index());
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Expected arguments.
// TOS(0): value.
// TOS(1): index.
// TOS(2): array.
void CodeGenerator::GenerateStoreIndexed(intptr_t node_id,
                                         intptr_t token_index,
                                         bool preserve_value) {
  // It is not necessary to generate a type test of the assigned value here,
  // because the []= operator will check the type of its incoming arguments.
  if (preserve_value) {
    __ popl(EAX);
    __ popl(EDX);
    __ popl(ECX);
    __ pushl(EAX);  // Preserve stored value.
    __ pushl(ECX);  // Restore arguments.
    __ pushl(EDX);
    __ pushl(EAX);
  }
  // Invoke the []= operator on the receiver object with index and
  // value as arguments.
  const String& operator_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kASSIGN_INDEX)));
  const int kNumArguments = 3;  // Receiver, index and value.
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node_id,
                       token_index,
                       operator_name,
                       kNumArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
}


void CodeGenerator::VisitStoreIndexedNode(StoreIndexedNode* node) {
  // Compute the receiver object and pass as first argument to call.
  node->array()->Visit(this);
  // Now compute the index.
  node->index_expr()->Visit(this);
  // Finally compute the value to assign.
  node->value()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  GenerateStoreIndexed(node->id(), node->token_index(), IsResultNeeded(node));
}


void CodeGenerator::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  MarkDeoptPoint(node->id(), node->token_index());
  __ LoadObject(EDX, node->field());
  __ movl(EAX, FieldAddress(EDX, Field::value_offset()));
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  node->value()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  __ popl(EAX);  // Value.
  if (FLAG_enable_type_checks) {
    GenerateAssertAssignable(node->id(),
                             node->value()->token_index(),
                             node->value(),
                             AbstractType::ZoneHandle(node->field().type()),
                             String::ZoneHandle(node->field().name()));
  }
  __ LoadObject(EDX, node->field());
  __ StoreIntoObject(EDX, FieldAddress(EDX, Field::value_offset()), EAX);
  if (IsResultNeeded(node)) {
    // The result is the input value.
    __ pushl(EAX);
  }
}


void CodeGenerator::GenerateLogicalNotOp(UnaryOpNode* node) {
  // Generate false if operand is true, otherwise generate true.
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  node->operand()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  Label done;
  GenerateConditionTypeCheck(node->id(), node->operand()->token_index());
  __ popl(EDX);
  __ LoadObject(EAX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(EAX, bool_false);
  __ Bind(&done);
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitUnaryOpNode(UnaryOpNode* node) {
  if (node->kind() == Token::kNOT) {
    // "!" cannot be overloaded, therefore inline it.
    GenerateLogicalNotOp(node);
    return;
  }
  node->operand()->Visit(this);
  if (node->kind() == Token::kADD) {
    // TODO(srdjan): Remove this as it is not part of Dart language any longer.
    // Unary operator '+' does not exist, it's a NOP, skip it.
    if (!IsResultNeeded(node)) {
      __ popl(EAX);
    }
    return;
  }
  MarkDeoptPoint(node->id(), node->token_index());
  String& operator_name = String::ZoneHandle();
  if (node->kind() == Token::kSUB) {
    operator_name = String::NewSymbol(Token::Str(Token::kNEGATE));
  } else {
    operator_name = String::NewSymbol(node->Name());
  }
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node->id(),
                       node->token_index(),
                       operator_name,
                       kNumberOfArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  node->receiver()->Visit(this);
  __ pushl(Address(ESP, 0));  // Duplicate receiver (preserve for setter).
  MarkDeoptPoint(node->getter_id(), node->token_index());
  GenerateInstanceGetterCall(node->getter_id(),
                             node->token_index(),
                             node->field_name());
  // result is in EAX.
  __ popl(EDX);   // Get receiver.
  if (!node->prefix() && IsResultNeeded(node)) {
    // Preserve as result.
    __ pushl(EAX);  // Preserve value as result.
  }
  const char* operator_name = (node->kind() == Token::kINCR) ? "+" : "-";
  // EAX: Value.
  // EDX: Receiver.
  __ pushl(EDX);  // Preserve receiver.
  __ pushl(EAX);  // Left operand.
  __ pushl(Immediate(Smi::RawValue(1)));  // Right operand.
  GenerateBinaryOperatorCall(node->operator_id(),
                             node->token_index(),
                             operator_name);
  __ popl(EDX);  // Restore receiver.
  if (IsResultNeeded(node) && node->prefix()) {
    // Value stored into field is the result.
    __ pushl(EAX);
  }
  __ pushl(EDX);  // Receiver.
  __ pushl(EAX);  // Value.
  // It is not necessary to generate a type test of the assigned value here,
  // because the setter will check the type of its incoming arguments.
  GenerateInstanceSetterCall(node->setter_id(),
                             node->token_index(),
                             node->field_name());
}


void CodeGenerator::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  node->array()->Visit(this);
  node->index()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  // Preserve array and index for GenerateStoreIndex.
  __ pushl(Address(ESP, kWordSize));  // Copy array.
  __ pushl(Address(ESP, kWordSize));  // Copy index.
  GenerateLoadIndexed(node->load_id(), node->token_index());
  // Result is in EAX.
  if (!node->prefix() && IsResultNeeded(node)) {
    // Preserve EAX as result.
    __ popl(EDX);  // Preserved index -> EDX.
    __ popl(ECX);  // Preserved array -> ECX.
    __ pushl(EAX);  // Preserve original value from indexed load.
    __ pushl(ECX);  // Array.
    __ pushl(EDX);  // Index.
  }
  const char* operator_name = (node->kind() == Token::kINCR) ? "+" : "-";
  __ pushl(EAX);    // Left operand.
  __ pushl(Immediate(Smi::RawValue(1)));  // Right operand.
  GenerateBinaryOperatorCall(node->operator_id(),
                             node->token_index(),
                             operator_name);
  __ pushl(EAX);
  // TOS(0): value, TOS(1): index, TOS(2): array.
  GenerateStoreIndexed(node->store_id(),
                       node->token_index(),
                       node->prefix() && IsResultNeeded(node));
}


static const Class* CoreClass(const char* c_name) {
  const String& class_name = String::Handle(String::NewSymbol(c_name));
  const Class& cls = Class::ZoneHandle(Library::Handle(
      Library::CoreImplLibrary()).LookupClass(class_name));
  ASSERT(!cls.IsNull());
  return &cls;
}


// Instance to test is in EAX. Test if its class is in subtype test cache array
// and use the result in the array to jump to one of the labels. Fall through
// if the instance is not in the cache array.
// TODO(srdjan): Implement a quicker subtype check, as type test
// arrays can grow too high, but they may be useful when optimizing
// code (type-feedback).
RawSubtypeTestCache* CodeGenerator::GenerateSubtype1TestCacheLookup(
    intptr_t node_id,
    intptr_t token_index,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label loop, found_in_cache, runtime_call;
  // Check immediate equality.
  __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
  // ECX: instance class.
  __ CompareObject(ECX, type_class);
  __ j(EQUAL, is_instance_lbl);

  // Check immediate superclass equality.
  __ movl(EDI, FieldAddress(ECX, Class::super_type_offset()));
  __ movl(EDI, FieldAddress(EDI, Type::type_class_offset()));
  __ CompareObject(EDI, type_class);
  __ j(EQUAL, is_instance_lbl);

  __ LoadObject(EDX, type_test_cache);
  __ pushl(EDX);  // Cache array.
  __ pushl(EAX);  // Instance.
  __ pushl(raw_null);  // Unused
  __ call(&StubCode::Subtype1TestCacheLabel());
  __ popl(EAX);  // Discard.
  __ popl(EAX);  // Restore receiver.
  __ popl(EDX);  // Discard.
  // Result is in ECX: null -> not found, otherwise Bool::True or Bool::False.

  __ cmpl(ECX, raw_null);
  __ j(EQUAL, &runtime_call, Assembler::kNearJump);
  __ CompareObject(ECX, bool_true);
  __ j(EQUAL, is_instance_lbl);
  __ jmp(is_not_instance_lbl);
  __ Bind(&runtime_call);
  return type_test_cache.raw();
}


// Inline tests according to the 'type' being tested. Jump to labels
// if we can compute the type-test, otherwise fallthrough.
// EAX: instance to be tested, must be preserved.
// Clobbers many registers.
RawSubtypeTestCache* CodeGenerator::GenerateInlineInstanceof(
    intptr_t node_id,
    intptr_t token_index,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  if (type.IsInstantiated()) {
    const Class& type_class = Class::ZoneHandle(type.type_class());
    // A Smi object cannot be the instance of a parameterized class.
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class or with a raw dst type of a parameterized class.
    if (type_class.HasTypeArguments()) {
      return GenerateInstantiatedTypeWithArgumentsTest(node_id,
                                                       token_index,
                                                       type,
                                                       is_instance_lbl,
                                                       is_not_instance_lbl);
      // Fall through to runtime call.
    } else {
      GenerateInstantiatedTypeNoArgumentsTest(node_id,
                                              token_index,
                                              type,
                                              is_instance_lbl,
                                              is_not_instance_lbl);
      // If test non-conclusive so far, try the inlined type-test cache.
      // 'type' is known at compile time.
      return GenerateSubtype1TestCacheLookup(
          node_id, token_index, type_class,
          is_instance_lbl, is_not_instance_lbl);
    }
  } else {
    GenerateUninstantiatedTypeTest(type,
                                   token_index,
                                   is_instance_lbl);
  }
  return SubtypeTestCache::null();
}


// If instanceof type test cannot be performed successfully at compile time and
// therefore eliminated, optimize it by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - EAX: object.
// Destroys ECX.
// Returns:
// - true or false on stack.
void CodeGenerator::GenerateInstanceOf(intptr_t node_id,
                                       intptr_t token_index,
                                       AstNode* value,
                                       const AbstractType& type,
                                       bool negate_result) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  // All objects are instances of type T if Object type is a subtype of type T.
  const Type& object_type =
      Type::Handle(Isolate::Current()->object_store()->object_type());
  Error& malformed_error = Error::Handle();
  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, &malformed_error)) {
    __ PushObject(negate_result ? bool_false : bool_true);
    return;
  }

  // Eliminate the test if it can be performed successfully at compile time.
  if ((value != NULL) && value->IsLiteralNode() && type.IsInstantiated()) {
    const Instance& literal_value = value->AsLiteralNode()->literal();
    const Class& cls = Class::Handle(literal_value.clazz());
    if (cls.IsNullClass()) {
      ASSERT(literal_value.IsNull() ||
             (literal_value.raw() == Object::sentinel()) ||
             (literal_value.raw() == Object::transition_sentinel()));
      // A null object is only an instance of Object and Dynamic, which has
      // already been checked above (if the type is instantiated). So we can
      // return false here if the instance is null (and if the type is
      // instantiated).
      __ PushObject(negate_result ? bool_true : bool_false);
    } else {
      Error& malformed_error = Error::Handle();
      if (literal_value.IsInstanceOf(type,
                                     TypeArguments::Handle(),
                                     &malformed_error)) {
        __ PushObject(negate_result ? bool_false : bool_true);
      } else {
        ASSERT(malformed_error.IsNull());
        __ PushObject(negate_result ? bool_true : bool_false);
      }
    }
    return;
  }

  Label is_instance_of, is_not_instance_of;
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done;
  // If type is instantiated and non-parameterized, we can inline code
  // checking whether the tested instance is a Smi.
  if (type.IsInstantiated()) {
    // A null object is only an instance of Object and Dynamic, which has
    // already been checked above (if the type is instantiated). So we can
    // return false here if the instance is null (and if the type is
    // instantiated).
    // We can only inline this null check if the type is instantiated at compile
    // time, since an uninstantiated type at compile time could be Object or
    // Dynamic at run time.
    Label non_null;
    __ cmpl(EAX, raw_null);
    __ j(NOT_EQUAL, &non_null, Assembler::kNearJump);
    __ PushObject(negate_result ? bool_true : bool_false);
    __ jmp(&done);
    __ Bind(&non_null);
  }
  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(node_id, token_index, type,
                                        &is_instance_of, &is_not_instance_of);

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  const Immediate location = Immediate(Smi::RawValue(token_index));
  const Immediate node_id_as_smi = Immediate(Smi::RawValue(node_id));
  __ pushl(location);  // Push the source location.
  __ pushl(node_id_as_smi);  // node-id.
  __ pushl(EAX);  // Push the instance.
  __ PushObject(type);  // Push the type.
  if (!type.IsInstantiated()) {
    GenerateInstantiatorTypeArguments(token_index);
  } else {
    __ pushl(raw_null);  // Null instantiator.
  }
  __ LoadObject(EAX, test_cache);
  __ pushl(EAX);
  GenerateCallRuntime(node_id, token_index, kInstanceofRuntimeEntry);
  // Pop the two parameters supplied to the runtime entry. The result of the
  // instanceof runtime call will be left as the result of the operation.
  __ addl(ESP, Immediate(6 * kWordSize));
  if (negate_result) {
    __ popl(EDX);
    __ CompareObject(EDX, bool_false);
    __ j(EQUAL, &is_not_instance_of, Assembler::kNearJump);
    // Fall through to is_instance_of.
  } else {
    __ jmp(&done);
  }

  __ Bind(&is_instance_of);
  __ PushObject(negate_result ? bool_false: bool_true);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_not_instance_of);
  __ PushObject(negate_result ? bool_true: bool_false);
  __ Bind(&done);
}


// EAX: instance to test.
// Clobbers: ECX.
// Jumps to labels 'is_instance' or 'is_not_instance' respectively, if
// type test is conclusive, otherwise fallthrough if a type test could not
// be completed.
RawSubtypeTestCache* CodeGenerator::GenerateInstantiatedTypeWithArgumentsTest(
    intptr_t node_id,
    intptr_t token_index,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT(type_class.HasTypeArguments());
  // A Smi object cannot be the instance of a parameterized class.
  // A class equality check is only applicable with a dst type of a
  // non-parameterized class or with a raw dst type of a parameterized class.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, is_not_instance_lbl);
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::ZoneHandle(type.arguments());
  const bool is_raw_type = type_arguments.IsNull() ||
      type_arguments.IsRaw(type_arguments.Length());
  if (is_raw_type) {
    // Dynamic type argument, check only classes.
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    if (type.IsListInterface()) {
      // TODO(srdjan) also accept List<Object>.
      __ CompareObject(ECX, *CoreClass("ObjectArray"));
      __ j(EQUAL, is_instance_lbl);
      __ CompareObject(ECX, *CoreClass("GrowableObjectArray"));
      __ j(EQUAL, is_instance_lbl);
    }
    return
        GenerateSubtype1TestCacheLookup(node_id, token_index, type_class,
                                        is_instance_lbl, is_not_instance_lbl);
  }
  // Note that the test below must be synced with the tests in
  // CodeGenerator::UpdateTestCache.
  // Inline checks for one type argument only.
  if (type_arguments.Length() != 1) {
    return SubtypeTestCache::null();
  }
  const AbstractType& tp_argument =
      AbstractType::ZoneHandle(type_arguments.TypeAt(0));
  if (!tp_argument.IsType()) {
    // E.g., it is a TypeParameter.
    return SubtypeTestCache::null();
  }
  // Malformed type has been caught in the caller chain of this function.
  ASSERT(tp_argument.HasResolvedTypeClass());
  // Check if type argument is dynamic or Object.
  const Type& object_type =
      Type::Handle(Isolate::Current()->object_store()->object_type());
  Error& malformed_error = Error::Handle();
  if (object_type.IsSubtypeOf(tp_argument, &malformed_error)) {
    // Instance class test only necessary.
    return GenerateSubtype1TestCacheLookup(
        node_id, token_index, type_class, is_instance_lbl, is_not_instance_lbl);
  }
  const SubtypeTestCache& type_test_cache =
      SubtypeTestCache::ZoneHandle(SubtypeTestCache::New());
  Label inlined_check, fall_through;
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ LoadObject(EDX, type_test_cache);
  __ pushl(EDX);  // Cache array.
  __ pushl(EAX);  // Instance.
  __ pushl(raw_null);  // Unused.
  __ call(&StubCode::Subtype2TestCacheLabel());
  __ popl(EAX);  // Discard.
  __ popl(EAX);  // Restore receiver.
  __ popl(EDX);  // Discard.
  // Result is in ECX: null -> not found, otherwise Bool::True or Bool::False.

  __ cmpl(ECX, raw_null);
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  __ CompareObject(ECX, bool_true);
  __ j(EQUAL, is_instance_lbl);
  __ jmp(is_not_instance_lbl);
  __ Bind(&fall_through);
  return type_test_cache.raw();
}


// EAX: instance to test.
// Clobbers: EBX, ECX, EDX.
void CodeGenerator::GenerateInstantiatedTypeNoArgumentsTest(
    intptr_t node_id,
    intptr_t token_index,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  ASSERT(type.IsInstantiated());
  const Class& type_class = Class::ZoneHandle(type.type_class());
  ASSERT(!type_class.HasTypeArguments());

  Label compare_classes;
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &compare_classes, Assembler::kNearJump);
  // Instance is Smi, check directly.
  const Class& smi_class = Class::Handle(Smi::Class());
  // TODO(regis): We should introduce a SmiType.
  Error& malformed_error = Error::Handle();
  if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                            type_class,
                            TypeArguments::Handle(),
                            &malformed_error)) {
    __ jmp(is_instance_lbl);
  } else {
    __ jmp(is_not_instance_lbl);
  }
  // Compare if the classes are equal.
  __ Bind(&compare_classes);

  // Checking against interface.
  // However, for specific core library interfaces, we can check for
  // specific core library classes.
  if (type.IsBoolInterface()) {
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    const Class& bool_class = Class::ZoneHandle(
        Isolate::Current()->object_store()->bool_class());
    __ CompareObject(ECX, bool_class);
    __ j(EQUAL, is_instance_lbl);
    return;
  }
  // If type is an interface, we can skip the class equality check,
  // because instances cannot be of an interface type.
  if (!type_class.is_interface()) {
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    __ CompareObject(ECX, type_class);
    __ j(EQUAL, is_instance_lbl);
  }
  if (type.IsSubtypeOf(
        Type::Handle(Type::NumberInterface()), &malformed_error)) {
    // Custom checking for numbers (Smi, Mint, Bigint and Double)
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    if (type.IsIntInterface() || type.IsNumberInterface()) {
      // We already checked for Smi above.
      const Class& mint_class = Class::ZoneHandle(
          Isolate::Current()->object_store()->mint_class());
      const Class& bigint_class = Class::ZoneHandle(
          Isolate::Current()->object_store()->bigint_class());
      __ CompareObject(ECX, mint_class);
      __ j(EQUAL, is_instance_lbl);
      __ CompareObject(ECX, bigint_class);
      __ j(EQUAL, is_instance_lbl);
    }
    if (type.IsDoubleInterface() || type.IsNumberInterface()) {
      const Class& double_class = Class::ZoneHandle(
          Isolate::Current()->object_store()->double_class());
      __ CompareObject(ECX, double_class);
      __ j(EQUAL, is_instance_lbl);
    }
  } else if (type.IsStringInterface()) {
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    const Class& one_byte_string_class = Class::ZoneHandle(
        Isolate::Current()->object_store()->one_byte_string_class());
    const Class& two_byte_string_class = Class::ZoneHandle(
        Isolate::Current()->object_store()->two_byte_string_class());
    const Class& four_byte_string_class = Class::ZoneHandle(
        Isolate::Current()->object_store()->four_byte_string_class());
    __ CompareObject(ECX, one_byte_string_class);
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(ECX, two_byte_string_class);
    __ j(EQUAL, is_instance_lbl);
    __ CompareObject(ECX, four_byte_string_class);
    __ j(EQUAL, is_instance_lbl);
  } else if (type.IsFunctionInterface()) {
    // Check if instance is a closure.
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    __ movl(ECX, FieldAddress(ECX, Class::signature_function_offset()));
    __ cmpl(ECX, raw_null);
    __ j(NOT_EQUAL, is_instance_lbl);
  }
  // Otherwise fallthrough.
}


// EAX: instance to test.
// Clobbers: EBX, EDX, ECX.
void CodeGenerator::GenerateUninstantiatedTypeTest(
    const AbstractType& type,
    intptr_t token_index,
    Label* is_instance_lbl) {
  ASSERT(!type.IsInstantiated());
  // Skip check if destination is a dynamic type.
  if (type.IsTypeParameter()) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    // EAX must be preserved!
    Label fall_through;
    GenerateInstantiatorTypeArguments(token_index);
    // Type arguments are on stack.
    __ popl(EBX);
    // Check if type argument is dynamic.
    __ cmpl(EBX, raw_null);
    __ j(EQUAL, is_instance_lbl);

    // For now handle only TypeArguments and bail out if InstantiatedTypeArgs.
    __ movl(EDX, FieldAddress(EBX, Object::class_offset()));
    __ CompareObject(EDX, Object::ZoneHandle(Object::type_arguments_class()));
    __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);

    // EBX: Instance of TypeArguments.
    __ movl(EDX,
        FieldAddress(EBX, TypeArguments::type_at_offset(type.Index())));
    // EDX: concrete type of type.
    // Check if type argument is dynamic.
    __ CompareObject(EDX, Type::ZoneHandle(Type::DynamicType()));
    __ j(EQUAL,  is_instance_lbl);

    // Check if the type has type parameters, if not do the class comparison.
    Label not_smi;
    __ testl(EAX, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
    // For Smi check quickly against int and num interfaces.
    __ CompareObject(EDX, Type::ZoneHandle(Type::IntInterface()));
    __ j(EQUAL,  is_instance_lbl);
    __ CompareObject(EDX, Type::ZoneHandle(Type::NumberInterface()));
    __ j(EQUAL,  is_instance_lbl);
    __ jmp(&fall_through);

    __ Bind(&not_smi);
    // The instantiated type parameter may not be a Type, but could be an
    // InstantiatedType. It is therefore necessary to check its class.
    __ movl(ECX, FieldAddress(EDX, Object::class_offset()));
    __ CompareObject(ECX, Object::ZoneHandle(Object::type_class()));
    __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);

    __ movl(EDX, FieldAddress(EDX, Type::type_class_offset()));
    __ movl(ECX, FieldAddress(EDX, Class::type_parameters_offset()));
    // Check that class of type has no type parameters.
    __ cmpl(ECX, raw_null);
    __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);
    // EAX has non-parameterized class.
    // Check class equality
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    __ movl(ECX, FieldAddress(ECX, Type::type_class_offset()));
    __ cmpl(ECX, EDX);
    __ j(EQUAL, is_instance_lbl);

    // We have a non-parameterized class in EDX, compare with class of
    // value in EAX. EAX, EDX are preserved in stub.
    __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
    __ call(&StubCode::IsRawSubTypeLabel());
    // Result in EBX: 1 is raw subtype.
    __ cmpl(EBX, Immediate(1));
    __ j(EQUAL, is_instance_lbl);

    // Test not conclusive.
    __ Bind(&fall_through);
  }
}


// If type check cannot be performed successfully at compile time and therefore
// eliminated, optimize it by adding inlined tests for:
// - NULL -> return NULL.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - EAX: object.
// Destroys ECX and EDX.
// Returns:
// - object in EAX for successful assignable check (or throws TypeError).
// Performance notes: positive checks must be quick, negative checks can be slow
// as they throw an exception.
void CodeGenerator::GenerateAssertAssignable(intptr_t node_id,
                                             intptr_t token_index,
                                             AstNode* value,
                                             const AbstractType& dst_type,
                                             const String& dst_name) {
  ASSERT(FLAG_enable_type_checks);
  ASSERT(token_index >= 0);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());

  // Any expression is assignable to the Dynamic type and to the Object type.
  // Skip the test.
  if (!dst_type.IsMalformed() &&
      (dst_type.IsDynamicType() || dst_type.IsObjectType())) {
    return;
  }

  // It is a compile-time error to explicitly return a value (including null)
  // from a void function. However, functions that do not explicitly return a
  // value, implicitly return null. This includes void functions. Therefore, we
  // skip the type test here and trust the parser to only return null in void
  // function.
  if (dst_type.IsVoidType()) {
    return;
  }

  // Eliminate the test if it can be performed successfully at compile time.
  if ((value != NULL) && value->IsLiteralNode()) {
    const Instance& literal_value = value->AsLiteralNode()->literal();
    const Class& cls = Class::Handle(literal_value.clazz());
    if (cls.IsNullClass()) {
      ASSERT(literal_value.IsNull() ||
             (literal_value.raw() == Object::sentinel()) ||
             (literal_value.raw() == Object::transition_sentinel()));
      return;
    }
    Error& malformed_error = Error::Handle();
    if (!dst_type.IsMalformed() &&
        dst_type.IsInstantiated() &&
        literal_value.IsInstanceOf(dst_type,
                                   TypeArguments::Handle(),
                                   &malformed_error)) {
      return;
    }
  }

  // A null object is always assignable and is returned as result.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done, runtime_call;
  __ cmpl(EAX, raw_null);
  __ j(EQUAL, &done);

  // Generate throw new TypeError() if the type is malformed.
  if (dst_type.IsMalformed()) {
    const Error& error = Error::Handle(dst_type.malformed_error());
    const String& error_message = String::ZoneHandle(
        String::NewSymbol(error.ToErrorCString()));
    __ PushObject(Object::ZoneHandle());  // Make room for the result.
    __ pushl(Immediate(Smi::RawValue(token_index)));  // Source location.
    __ pushl(EAX);  // Push the source object.
    __ PushObject(dst_name);  // Push the name of the destination.
    __ PushObject(error_message);
    GenerateCallRuntime(node_id, token_index, kMalformedTypeErrorRuntimeEntry);
    // We should never return here.
    __ int3();

    __ Bind(&done);  // For a null object.
    return;
  }

  SubtypeTestCache& test_cache = SubtypeTestCache::ZoneHandle();
  test_cache = GenerateInlineInstanceof(node_id, token_index, dst_type,
                                        &done, &runtime_call);

  __ Bind(&runtime_call);
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(Immediate(Smi::RawValue(token_index)));  // Source location.
  __ pushl(Immediate(Smi::RawValue(node_id)));  // node-id.
  __ pushl(EAX);  // Push the source object.
  __ PushObject(dst_type);  // Push the type of the destination.
  if (dst_type.IsInstantiated()) {
    __ pushl(raw_null);  // Null instantiator.
  } else {
    GenerateInstantiatorTypeArguments(token_index);
  }
  __ PushObject(dst_name);  // Push the name of the destination.
  __ LoadObject(EAX, test_cache);
  __ pushl(EAX);
  GenerateCallRuntime(node_id, token_index, kTypeCheckRuntimeEntry);
  // Pop the parameters supplied to the runtime entry. The result of the
  // type check runtime call is the checked value.
  __ addl(ESP, Immediate(7 * kWordSize));
  __ popl(EAX);

  // EAX: value.
  __ Bind(&done);
}


void CodeGenerator::GenerateArgumentTypeChecks() {
  const Function& function = parsed_function_.function();
  const SequenceNode& sequence_node = *parsed_function_.node_sequence();
  LocalScope* scope = sequence_node.scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  ASSERT(num_fixed_params + num_opt_params <= scope->num_variables());
  for (intptr_t i = 0; i < num_fixed_params + num_opt_params; i++) {
    LocalVariable* parameter = scope->VariableAt(i);
    GenerateLoadVariable(EAX, *parameter);
    GenerateAssertAssignable(sequence_node.ParameterIdAt(i),
                             parameter->token_index(),
                             NULL,
                             parameter->type(),
                             parameter->name());
  }
}


void CodeGenerator::GenerateConditionTypeCheck(intptr_t node_id,
                                               intptr_t token_index) {
  if (!FLAG_enable_type_checks) {
    return;
  }

  // Check that the type of the object on the stack is allowed in conditional
  // context.
  // Call the runtime if the object is null or not of type bool.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label runtime_call, done;
  __ movl(EAX, Address(ESP, 0));
  __ cmpl(EAX, raw_null);
  __ j(EQUAL, &runtime_call, Assembler::kNearJump);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, &runtime_call, Assembler::kNearJump);  // Call runtime for Smi.
  // This check should pass if the receiver's class implements the interface
  // 'bool'. Check only class 'Bool' since it is the only legal implementation
  // of the interface 'bool'.
  const Class& bool_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->bool_class());
  __ movl(ECX, FieldAddress(EAX, Object::class_offset()));
  __ CompareObject(ECX, bool_class);
  __ j(EQUAL, &done, Assembler::kNearJump);

  __ Bind(&runtime_call);
  __ pushl(Immediate(Smi::RawValue(token_index)));  // Source location.
  __ pushl(EAX);  // Push the source object.
  GenerateCallRuntime(node_id, token_index, kConditionTypeErrorRuntimeEntry);
  // We should never return here.
  __ int3();

  __ Bind(&done);
}


void CodeGenerator::VisitComparisonNode(ComparisonNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  node->left()->Visit(this);

  // The instanceof operator needs special handling.
  if (Token::IsInstanceofOperator(node->kind())) {
    __ popl(EAX);  // Left operand.
    ASSERT(node->right()->IsTypeNode());
    GenerateInstanceOf(node->id(),
                       node->token_index(),
                       node->left(),
                       node->right()->AsTypeNode()->type(),
                       (node->kind() == Token::kISNOT));
    if (!IsResultNeeded(node)) {
      __ popl(EAX);  // Pop the result of the instanceof operation.
    }
    return;
  }

  node->right()->Visit(this);
  // Both left and right values on stack.

  // '===' and '!==' are not overloadable.
  if ((node->kind() == Token::kEQ_STRICT) ||
      (node->kind() == Token::kNE_STRICT)) {
    __ popl(EDX);  // Right operand.
    __ popl(EAX);  // Left operand.
    if (!IsResultNeeded(node)) {
      return;
    }
    Label load_true, done;
    __ cmpl(EAX, EDX);
    if (node->kind() == Token::kEQ_STRICT) {
      __ j(EQUAL, &load_true, Assembler::kNearJump);
    } else {
      __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
    }
    __ LoadObject(EAX, bool_false);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&load_true);
    __ LoadObject(EAX, bool_true);
    __ Bind(&done);
    // Result is in EAX.
    __ pushl(EAX);
    return;
  }

  MarkDeoptPoint(node->id(), node->token_index());

  // '!=' not overloadable, always implements negation of '=='.
  // Call operator for '=='.
  if ((node->kind() == Token::kEQ) || (node->kind() == Token::kNE)) {
    // Null is a special receiver with a special type and frequently used on
    // operators "==" and "!=". Emit inlined code for null so that it does not
    // pollute type information at call site.
    Label null_done;
    {
      const Immediate raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      Label non_null_compare, load_true;
      // Check if left argument is null.
      __ cmpl(Address(ESP, 1 * kWordSize), raw_null);
      __ j(NOT_EQUAL, &non_null_compare, Assembler::kNearJump);
      // Comparison with NULL is "===".
      // Load/remove arguments.
      __ popl(EDX);
      __ popl(EAX);
      __ cmpl(EAX, EDX);
      if (node->kind() == Token::kEQ) {
        __ j(EQUAL, &load_true, Assembler::kNearJump);
      } else {
        __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
      }
      __ LoadObject(EAX, bool_false);
      __ jmp(&null_done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(EAX, bool_true);
      __ jmp(&null_done, Assembler::kNearJump);
      __ Bind(&non_null_compare);
    }
    // Do '==' first then negate if necessary,
    const String& operator_name = String::ZoneHandle(String::NewSymbol("=="));
    const int kNumberOfArguments = 2;
    const Array& kNoArgumentNames = Array::Handle();
    const int kNumArgumentsChecked = 1;
    GenerateInstanceCall(node->id(),
                         node->token_index(),
                         operator_name,
                         kNumberOfArguments,
                         kNoArgumentNames,
                         kNumArgumentsChecked);

    // Result is in EAX. No need to negate if result is not needed.
    if ((node->kind() == Token::kNE) && IsResultNeeded(node)) {
      // Negate result.
      Label load_true, done;
      __ LoadObject(EDX, bool_false);
      __ cmpl(EAX, EDX);
      __ j(EQUAL, &load_true, Assembler::kNearJump);
      __ movl(EAX, EDX);  // false.
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&load_true);
      __ LoadObject(EAX, bool_true);
      __ Bind(&done);
    }
    __ Bind(&null_done);
    // Result is in EAX.
    if (IsResultNeeded(node)) {
      __ pushl(EAX);
    }
    return;
  }

  // Call operator.
  GenerateBinaryOperatorCall(node->id(), node->token_index(), node->Name());
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::HandleBackwardBranch(
    intptr_t loop_id, intptr_t token_index) {
  // Use stack overflow check to eventually stop execution of loops.
  // This is necessary only if a loop does not have calls.
  __ cmpl(ESP,
          Address::Absolute(Isolate::Current()->stack_limit_address()));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow);
  GenerateCallRuntime(loop_id,
                      token_index,
                      kStackOverflowRuntimeEntry);
  __ Bind(&no_stack_overflow);
}


void CodeGenerator::VisitWhileNode(WhileNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  SourceLabel* label = node->label();
  __ Bind(label->continue_label());
  node->condition()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->condition()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(NOT_EQUAL, label->break_label());
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ jmp(label->continue_label());
  __ Bind(label->break_label());
}


void CodeGenerator::VisitDoWhileNode(DoWhileNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  SourceLabel* label = node->label();
  Label loop;
  __ Bind(&loop);
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ Bind(label->continue_label());
  node->condition()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->condition()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(EQUAL, &loop);
  __ Bind(label->break_label());
}


void CodeGenerator::VisitForNode(ForNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  node->initializer()->Visit(this);
  SourceLabel* label = node->label();
  Label loop;
  __ Bind(&loop);
  if (node->condition() != NULL) {
    node->condition()->Visit(this);
    GenerateConditionTypeCheck(node->id(), node->condition()->token_index());
    __ popl(EAX);
    __ LoadObject(EDX, bool_true);
    __ cmpl(EAX, EDX);
    __ j(NOT_EQUAL, label->break_label());
  }
  node->body()->Visit(this);
  HandleBackwardBranch(node->id(), node->token_index());
  __ Bind(label->continue_label());
  node->increment()->Visit(this);
  __ jmp(&loop);
  __ Bind(label->break_label());
}


void CodeGenerator::VisitJumpNode(JumpNode* node) {
  SourceLabel* label = node->label();

  // Generate inlined code for all finally blocks as we may transfer
  // control out of the 'try' blocks if any.
  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    node->InlinedFinallyNodeAt(i)->Visit(this);
  }

  // Unchain the context(s) up to the outer context level of the scope which
  // contains the destination label.
  ASSERT(label->owner() != NULL);
  intptr_t target_context_level = 0;
  LocalScope* target_scope = label->owner();
  if (target_scope->num_context_variables() > 0) {
    // The scope of the target label allocates a context, therefore its outer
    // scope is at a lower context level.
    target_context_level = target_scope->context_level() - 1;
  } else {
    // The scope of the target label does not allocate a context, so its outer
    // scope is at the same context level. Find it.
    while ((target_scope != NULL) &&
           (target_scope->num_context_variables() == 0)) {
      target_scope = target_scope->parent();
    }
    if (target_scope != NULL) {
      target_context_level = target_scope->context_level();
    }
  }
  ASSERT(target_context_level >= 0);
  int current_context_level = context_level();
  ASSERT(current_context_level >= target_context_level);
  while (current_context_level-- > target_context_level) {
    __ movl(CTX, FieldAddress(CTX, Context::parent_offset()));
  }

  if (node->kind() == Token::kBREAK) {
    __ jmp(label->break_label());
  } else {
    __ jmp(label->continue_label());
  }
}


void CodeGenerator::VisitConditionalExprNode(ConditionalExprNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Label false_label, done;
  node->condition()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->condition()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(NOT_EQUAL, &false_label);
  node->true_expr()->Visit(this);
  __ jmp(&done);
  __ Bind(&false_label);
  node->false_expr()->Visit(this);
  __ Bind(&done);
  if (!IsResultNeeded(node)) {
    __ popl(EAX);
  }
}


void CodeGenerator::VisitSwitchNode(SwitchNode *node) {
  SourceLabel* label = node->label();
  node->body()->Visit(this);
  __ Bind(label->break_label());
}


void CodeGenerator::VisitCaseNode(CaseNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Label case_statements, end_case;

  for (int i = 0; i < node->case_expressions()->length(); i++) {
    // Load case expression onto stack.
    AstNode* case_expr = node->case_expressions()->NodeAt(i);
    case_expr->Visit(this);
    __ popl(EAX);
    __ CompareObject(EAX, bool_true);
    // Jump to case clause code if case expression equals switch expression
    __ j(EQUAL, &case_statements);
  }
  // If this case clause contains the default label, fall through to
  // case clause code, else skip this clause.
  if (!node->contains_default()) {
    __ jmp(&end_case);
  }

  // If there is a label associated with this case clause, bind it.
  if (node->label() != NULL) {
    __ Bind(node->label()->continue_label());
  }

  // Generate code for case clause statements. The parser guarantees that
  // the code contains a jump, so we should never fall through the end
  // of the statements.
  __ Bind(&case_statements);
  node->statements()->Visit(this);
  __ Bind(&end_case);
}


void CodeGenerator::VisitIfNode(IfNode* node) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Label false_label;
  node->condition()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->condition()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(NOT_EQUAL, &false_label);
  node->true_branch()->Visit(this);
  if (node->false_branch() != NULL) {
    Label done;
    __ jmp(&done);
    __ Bind(&false_label);
    node->false_branch()->Visit(this);
    __ Bind(&done);
  } else {
    __ Bind(&false_label);
  }
}


// Operators '&&' and '||' are not overloadabled, inline them.
void CodeGenerator::GenerateLogicalAndOrOp(BinaryOpNode* node) {
  // Generate true if (left == true) op (right == true), otherwise generate
  // false, with op being either || or &&.
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  Label load_false, done;
  node->left()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->left()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  if (node->kind() == Token::kAND) {
    __ j(NOT_EQUAL, &load_false);
  } else {
    ASSERT(node->kind() == Token::kOR);
    __ j(EQUAL, &done);
  }
  node->right()->Visit(this);
  GenerateConditionTypeCheck(node->id(), node->right()->token_index());
  __ popl(EAX);
  __ LoadObject(EDX, bool_true);
  __ cmpl(EAX, EDX);
  __ j(EQUAL, &done);
  __ Bind(&load_false);
  __ LoadObject(EAX, bool_false);
  __ Bind(&done);
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Expect receiver(left operand) and right operand on stack.
// Return result in EAX.
void CodeGenerator::GenerateBinaryOperatorCall(intptr_t node_id,
                                               intptr_t token_index,
                                               const char* name) {
  const String& operator_name = String::ZoneHandle(String::NewSymbol(name));
  const int kNumberOfArguments = 2;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 2;
  GenerateInstanceCall(node_id,
                       token_index,
                       operator_name,
                       kNumberOfArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
}


void CodeGenerator::VisitBinaryOpNode(BinaryOpNode* node) {
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // Operators "&&" and "||" cannot be overloaded, therefore inline them
    // instead of calling the operator.
    GenerateLogicalAndOrOp(node);
    return;
  }
  node->left()->Visit(this);
  node->right()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  GenerateBinaryOperatorCall(node->id(), node->token_index(), node->Name());
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitStringConcatNode(StringConcatNode* node) {
  const String& cls_name = String::Handle(String::NewSymbol("StringBase"));
  const Library& core_lib = Library::Handle(
      Isolate::Current()->object_store()->core_library());
  const Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  const String& func_name = String::Handle(String::NewSymbol("_interpolate"));
  const int number_of_parameters = 1;
  const Function& interpol_func = Function::ZoneHandle(
      Resolver::ResolveStatic(cls, func_name,
                              number_of_parameters,
                              Array::Handle(),
                              Resolver::kIsQualified));
  ASSERT(!interpol_func.IsNull());

  // First try to concatenate and canonicalize the values at compile time.
  bool compile_time_interpolation = true;
  Array& literals = Array::Handle(Array::New(node->values()->length()));
  for (int i = 0; i < node->values()->length(); i++) {
    if (node->values()->ElementAt(i)->IsLiteralNode()) {
      LiteralNode* lit = node->values()->ElementAt(i)->AsLiteralNode();
      literals.SetAt(i, lit->literal());
    } else {
      compile_time_interpolation = false;
      break;
    }
  }
  if (compile_time_interpolation) {
    if (!IsResultNeeded(node)) {
      return;
    }
    // Build argument array to pass to the interpolation function.
    GrowableArray<const Object*> interpolate_arg;
    interpolate_arg.Add(&literals);
    const Array& kNoArgumentNames = Array::Handle();
    // Call the interpolation function.
    String& concatenated = String::ZoneHandle();
    concatenated ^= DartEntry::InvokeStatic(interpol_func,
                                            interpolate_arg,
                                            kNoArgumentNames);
    if (concatenated.IsUnhandledException()) {
      // TODO(hausner): Shouldn't we generate a throw?
      // Then remove unused CodeGenerator::ErrorMsg().
      ErrorMsg(node->token_index(),
          "Exception thrown in CodeGenerator::VisitStringConcatNode");
    }
    ASSERT(!concatenated.IsNull());
    concatenated = String::NewSymbol(concatenated);

    __ LoadObject(EAX, concatenated);
    __ pushl(EAX);
    return;
  }

  // Could not concatenate at compile time, generate a call to
  // interpolation function.
  ArgumentListNode* interpol_arg = new ArgumentListNode(node->token_index());
  interpol_arg->Add(node->values());
  node->values()->Visit(this);
  __ LoadObject(ECX, interpol_func);
  __ LoadObject(EDX, ArgumentsDescriptor(interpol_arg->length(),
                                         interpol_arg->names()));
  GenerateCall(node->token_index(),
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addl(ESP, Immediate(interpol_arg->length() * kWordSize));
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitInstanceCallNode(InstanceCallNode* node) {
  const int number_of_arguments = node->arguments()->length() + 1;
  // Compute the receiver object and pass it as first argument to call.
  node->receiver()->Visit(this);
  // Now compute rest of the arguments to the call.
  node->arguments()->Visit(this);
  // Some method may be inlined using type feedback, therefore this may be a
  // deoptimization point.
  MarkDeoptPoint(node->id(), node->token_index());
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node->id(),
                       node->token_index(),
                       node->function_name(),
                       number_of_arguments,
                       node->arguments()->names(),
                       kNumArgumentsChecked);
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitStaticCallNode(StaticCallNode* node) {
  node->arguments()->Visit(this);
  __ LoadObject(ECX, node->function());
  __ LoadObject(EDX, ArgumentsDescriptor(node->arguments()->length(),
                                         node->arguments()->names()));
  GenerateCall(node->token_index(),
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addl(ESP, Immediate(node->arguments()->length() * kWordSize));
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


void CodeGenerator::VisitClosureCallNode(ClosureCallNode* node) {
  // The spec states that the closure is evaluated before the arguments.
  // Preserve the current context, since it will be overridden by the closure
  // context during the call.
  __ pushl(CTX);
  // Compute the closure object and pass it as first argument to the stub.
  node->closure()->Visit(this);
  // Now compute the arguments to the call.
  node->arguments()->Visit(this);
  // Set up the number of arguments (excluding the closure) to the ClosureCall
  // stub which will setup the closure context and jump to the entrypoint of the
  // closure function (the function will be compiled if it has not already been
  // compiled).
  // NOTE: The stub accesses the closure before the parameter list.
  __ LoadObject(EDX, ArgumentsDescriptor(node->arguments()->length(),
                                         node->arguments()->names()));
  GenerateCall(node->token_index(),
               &StubCode::CallClosureFunctionLabel(),
               PcDescriptors::kOther);
  __ addl(ESP, Immediate((node->arguments()->length() + 1) * kWordSize));
  // Restore the context.
  __ popl(CTX);
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Pushes the type arguments of the instantiator on the stack.
// Destroys EBX.
void CodeGenerator::GenerateInstantiatorTypeArguments(intptr_t token_index) {
  const Class& instantiator_class = Class::Handle(
      parsed_function().function().owner());
  if (instantiator_class.NumTypeParameters() == 0) {
    // The type arguments are compile time constants.
    AbstractTypeArguments& type_arguments = AbstractTypeArguments::ZoneHandle();
    // TODO(regis): Temporary type should be allocated in new gen heap.
    Type& type = Type::Handle(
        Type::New(instantiator_class, type_arguments, token_index));
    type ^= ClassFinalizer::FinalizeType(
        instantiator_class, type, ClassFinalizer::kFinalizeWellFormed);
    type_arguments = type.arguments();
    __ PushObject(type_arguments);
  } else {
    ASSERT(parsed_function().instantiator() != NULL);
    parsed_function().instantiator()->Visit(this);
    Function& outer_function =
        Function::Handle(parsed_function().function().raw());
    while (outer_function.IsLocalFunction()) {
      outer_function = outer_function.parent_function();
    }
    if (!outer_function.IsFactory()) {
      __ popl(EBX);  // Pop instantiator.
      // The instantiator is the receiver of the caller, which is not a factory.
      // The receiver cannot be null; extract its AbstractTypeArguments object.
      // Note that in the factory case, the instantiator is the first parameter
      // of the factory, i.e. already an AbstractTypeArguments object.
      intptr_t type_arguments_instance_field_offset =
          instantiator_class.type_arguments_instance_field_offset();
      ASSERT(type_arguments_instance_field_offset != Class::kNoTypeArguments);
      __ movl(EBX, FieldAddress(EBX, type_arguments_instance_field_offset));
      __ pushl(EBX);
    }
  }
}


// Pushes the type arguments on the stack in preparation of a constructor or
// factory call.
// For a factory call, instantiates (possibly requiring an additional run time
// call) and pushes the type argument vector that will be passed as implicit
// first parameter to the factory.
// For a constructor call allocating an object of a parameterized class, pushes
// the type arguments and the type arguments of the instantiator, without ever
// generating an additional run time call.
// Does nothing for a constructor call allocating an object of a non
// parameterized class.
// Note that a class without proper type parameters may still be parameterized,
// e.g. class A extends Array<int>.
void CodeGenerator::GenerateTypeArguments(ConstructorCallNode* node,
                                          bool requires_type_arguments) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  // Instantiate the type arguments if necessary.
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    if (requires_type_arguments) {
      // A factory requires the type arguments as first parameter.
      __ PushObject(node->type_arguments());
      if (!node->constructor().IsFactory()) {
        // The non-factory allocator additionally requires the instantiator
        // type arguments which are not needed here, since the type arguments
        // are instantiated.
        __ pushl(Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
      }
    }
  } else {
    // The type arguments are uninstantiated.
    ASSERT(requires_type_arguments);
    GenerateInstantiatorTypeArguments(node->token_index());
    __ popl(EAX);  // Pop instantiator.
    // EAX is the instantiator AbstractTypeArguments object (or null).
    // If the instantiator is null and if the type argument vector
    // instantiated from null becomes a vector of Dynamic, then use null as
    // the type arguments.
    Label type_arguments_instantiated;
    const intptr_t len = node->type_arguments().Length();
    if (node->type_arguments().IsRawInstantiatedRaw(len)) {
      __ cmpl(EAX, raw_null);
      __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    }
    // Instantiate non-null type arguments.
    if (node->type_arguments().IsUninstantiatedIdentity()) {
      // Check if the instantiator type argument vector is a TypeArguments of a
      // matching length and, if so, use it as the instantiated type_arguments.
      // No need to check RAX for null (again), because a null instance will
      // have the wrong class (Null instead of TypeArguments).
      Label type_arguments_uninstantiated;
      __ LoadObject(ECX, Class::ZoneHandle(Object::type_arguments_class()));
      __ cmpl(ECX, FieldAddress(EAX, Object::class_offset()));
      __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
      Immediate arguments_length =
          Immediate(Smi::RawValue(node->type_arguments().Length()));
      __ cmpl(FieldAddress(EAX, TypeArguments::length_offset()),
          arguments_length);
      __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
      __ Bind(&type_arguments_uninstantiated);
    }
    if (node->constructor().IsFactory()) {
      // A runtime call to instantiate the type arguments is required before
      // calling the factory.
      __ PushObject(Object::ZoneHandle());  // Make room for the result.
      __ PushObject(node->type_arguments());
      __ pushl(EAX);  // Push instantiator type arguments.
      GenerateCallRuntime(node->id(),
                          node->token_index(),
                          kInstantiateTypeArgumentsRuntimeEntry);
      __ popl(EAX);  // Pop instantiator type arguments.
      __ popl(EAX);  // Pop uninstantiated type arguments.
      __ popl(EAX);  // Pop instantiated type arguments.
      __ Bind(&type_arguments_instantiated);
      __ pushl(EAX);  // Instantiated type arguments.
    } else {
      // In the non-factory case, we rely on the allocation stub to
      // instantiate the type arguments.
      __ PushObject(node->type_arguments());
      __ pushl(EAX);  // Instantiator type arguments.
      Label type_arguments_pushed;
      __ jmp(&type_arguments_pushed, Assembler::kNearJump);

      __ Bind(&type_arguments_instantiated);
      __ pushl(EAX);  // Instantiated type arguments.
      __ pushl(Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
      __ Bind(&type_arguments_pushed);
    }
  }
}


void CodeGenerator::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    const bool requires_type_arguments = true;  // Always first arg to factory.
    GenerateTypeArguments(node, requires_type_arguments);
    // The top of stack is an instantiated AbstractTypeArguments object
    // (or null).
    int num_args = node->arguments()->length() + 1;  // +1 to include type args.
    node->arguments()->Visit(this);
    // Call the factory.
    __ LoadObject(ECX, node->constructor());
    __ LoadObject(EDX, ArgumentsDescriptor(num_args,
                                           node->arguments()->names()));
    GenerateCall(node->token_index(),
                 &StubCode::CallStaticFunctionLabel(),
                 PcDescriptors::kFuncCall);
    // Factory constructor returns object in EAX.
    __ addl(ESP, Immediate(num_args * kWordSize));
    if (IsResultNeeded(node)) {
      __ pushl(EAX);
    }
    return;
  }

  const Class& cls = Class::ZoneHandle(node->constructor().owner());
  const bool requires_type_arguments = cls.HasTypeArguments();
  GenerateTypeArguments(node, requires_type_arguments);

  // If cls is parameterized, the type arguments and the instantiator's
  // type arguments are on the stack.
  // In checked mode, if the type arguments are uninstantiated, they may need to
  // be checked against declared bounds at run time.
  Error& malformed_error = Error::Handle();
  if (FLAG_enable_type_checks &&
      requires_type_arguments &&
      !node->type_arguments().IsNull() &&
      !node->type_arguments().IsInstantiated() &&
      !node->type_arguments().IsWithinBoundsOf(cls,
                                               node->type_arguments(),
                                               &malformed_error)) {
    // The uninstantiated type arguments cannot be verified to be within their
    // bounds at compile time, so verify them at runtime.
    // Although the type arguments may be uninstantiated at compile time, they
    // may represent the identity vector and may be replaced by the instantiated
    // type arguments of the instantiator at run time.
    __ popl(ECX);  // Pop instantiator type arguments.
    __ popl(EAX);  // Pop type arguments.

    // Push the result place holder initialized to NULL.
    __ PushObject(Object::ZoneHandle());
    __ pushl(Immediate(Smi::RawValue(node->token_index())));
    __ PushObject(cls);
    __ pushl(EAX);  // Push type arguments.
    __ pushl(ECX);  // Push instantiator type arguments.
    GenerateCallRuntime(node->id(),
                        node->token_index(),
                        kAllocateObjectWithBoundsCheckRuntimeEntry);
    __ popl(ECX);  // Pop instantiator type arguments.
    __ popl(ECX);  // Pop type arguments.
    __ popl(ECX);  // Pop class.
    __ popl(ECX);  // Pop source location.
    __ popl(EAX);  // Pop new instance.
  } else {
    const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
    const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
    GenerateCall(node->token_index(), &label, PcDescriptors::kOther);
    if (requires_type_arguments) {
      __ popl(ECX);  // Pop instantiator type arguments.
      __ popl(ECX);  // Pop type arguments.
    }
  }

  if (IsResultNeeded(node)) {
    __ pushl(EAX);  // Set up return value from allocate.
  }

  // First argument(this) for constructor call which follows.
  __ pushl(EAX);
  // Second argument is the implicit construction phase parameter.
  // Run both the constructor initializer list and the constructor body.
  __ pushl(Immediate(Smi::RawValue(Function::kCtorPhaseAll)));

  // Now setup rest of the arguments for the constructor call.
  node->arguments()->Visit(this);

  // Call the constructor.
  // +2 to include implicit receiver and phase arguments.
  int num_args = node->arguments()->length() + 2;
  __ LoadObject(ECX, node->constructor());
  __ LoadObject(EDX, ArgumentsDescriptor(num_args, node->arguments()->names()));
  GenerateCall(node->token_index(),
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  // Constructors do not return any value.

  // Pop out all the other arguments on the stack.
  __ addl(ESP, Immediate(num_args * kWordSize));
}


// Expects receiver on stack, returns result in EAX..
void CodeGenerator::GenerateInstanceGetterCall(intptr_t node_id,
                                               intptr_t token_index,
                                               const String& field_name) {
  const String& getter_name =
      String::ZoneHandle(Field::GetterSymbol(field_name));
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node_id,
                       token_index,
                       getter_name,
                       kNumberOfArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
}


// Call to the instance getter.
void CodeGenerator::VisitInstanceGetterNode(InstanceGetterNode* node) {
  node->receiver()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  GenerateInstanceGetterCall(node->id(),
                             node->token_index(),
                             node->field_name());
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Expects receiver and value on stack.
void CodeGenerator::GenerateInstanceSetterCall(intptr_t node_id,
                                               intptr_t token_index,
                                               const String& field_name) {
  const String& setter_name =
      String::ZoneHandle(Field::SetterSymbol(field_name));
  const int kNumberOfArguments = 2;  // receiver + value.
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 1;
  GenerateInstanceCall(node_id,
                       token_index,
                       setter_name,
                       kNumberOfArguments,
                       kNoArgumentNames,
                       kNumArgumentsChecked);
}


// The call to the instance setter implements the assignment to a field.
// The result of the assignment to a field is the value being stored.
void CodeGenerator::VisitInstanceSetterNode(InstanceSetterNode* node) {
  // Compute the receiver object and pass it as first argument to call.
  node->receiver()->Visit(this);
  node->value()->Visit(this);
  MarkDeoptPoint(node->id(), node->token_index());
  if (IsResultNeeded(node)) {
    __ popl(EAX);   // value.
    __ popl(EDX);   // receiver.
    __ pushl(EAX);  // Preserve value.
    __ pushl(EDX);  // arg0: receiver.
    __ pushl(EAX);  // arg1: value.
  }
  // It is not necessary to generate a type test of the assigned value here,
  // because the setter will check the type of its incoming arguments.
  GenerateInstanceSetterCall(node->id(),
                             node->token_index(),
                             node->field_name());
}


// Return result in EAX.
void CodeGenerator::GenerateStaticGetterCall(intptr_t token_index,
                                             const Class& field_class,
                                             const String& field_name) {
  const String& getter_name = String::Handle(Field::GetterName(field_name));
  const Function& function =
      Function::ZoneHandle(field_class.LookupStaticFunction(getter_name));
  ASSERT(!function.IsNull());
  __ LoadObject(ECX, function);
  const int kNumberOfArguments = 0;
  const Array& kNoArgumentNames = Array::Handle();
  __ LoadObject(EDX, ArgumentsDescriptor(kNumberOfArguments, kNoArgumentNames));
  GenerateCall(token_index,
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  // No arguments were pushed, hence nothing to pop.
}


// Call to static getter.
void CodeGenerator::VisitStaticGetterNode(StaticGetterNode* node) {
  GenerateStaticGetterCall(node->token_index(),
                           node->cls(),
                           node->field_name());
  // Result is in EAX.
  if (IsResultNeeded(node)) {
    __ pushl(EAX);
  }
}


// Expects value on stack.
void CodeGenerator::GenerateStaticSetterCall(intptr_t token_index,
                                             const Class& field_class,
                                             const String& field_name) {
  const String& setter_name = String::Handle(Field::SetterName(field_name));
  const Function& function =
      Function::ZoneHandle(field_class.LookupStaticFunction(setter_name));
  ASSERT(!function.IsNull());
  __ LoadObject(ECX, function);
  const int kNumberOfArguments = 1;  // value.
  const Array& kNoArgumentNames = Array::Handle();
  __ LoadObject(EDX, ArgumentsDescriptor(kNumberOfArguments, kNoArgumentNames));
  GenerateCall(token_index,
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addl(ESP, Immediate(kNumberOfArguments * kWordSize));
}


// The call to static setter implements assignment to a static field.
// The result of the assignment is the value being stored.
void CodeGenerator::VisitStaticSetterNode(StaticSetterNode* node) {
  node->value()->Visit(this);
  if (IsResultNeeded(node)) {
    // Preserve the original value when returning from setter.
    __ movl(EAX, Address(ESP, 0));
    __ pushl(EAX);  // arg0: value.
  }
  // It is not necessary to generate a type test of the assigned value here,
  // because the setter will check the type of its incoming arguments.
  GenerateStaticSetterCall(node->token_index(),
                           node->cls(),
                           node->field_name());
}


void CodeGenerator::VisitNativeBodyNode(NativeBodyNode* node) {
  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in EAX.
  if (!node->has_optional_parameters()) {
    __ leal(EAX, Address(EBP, (1 + node->argument_count()) * kWordSize));
  } else {
    __ leal(EAX, Address(EBP, -1 * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(node->native_c_function())));
  __ movl(EDX, Immediate(node->argument_count()));
  GenerateCall(node->token_index(),
               &StubCode::CallNativeCFunctionLabel(),
               PcDescriptors::kOther);
  // Result is on the stack.
  if (!IsResultNeeded(node)) {
    __ popl(EAX);
  }
}


void CodeGenerator::VisitCatchClauseNode(CatchClauseNode* node) {
  // NOTE: The implicit variables ':saved_context', ':exception_var'
  // and ':stacktrace_var' can never be captured variables.
  // Restore CTX from local variable ':saved_context'.
  GenerateLoadVariable(CTX, node->context_var());

  // Restore ESP from EBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  ASSERT(locals_space_size() >= 0);
  if (locals_space_size() == 0) {
    __ movl(ESP, EBP);
  } else {
    __ leal(ESP, Address(EBP, -locals_space_size()));
  }

  // The JumpToExceptionHandler trampoline code sets up
  // - the exception object in EAX (kExceptionObjectReg)
  // - the stacktrace object in register EDX (kStackTraceObjectReg)
  // We now setup the exception object and the trace object
  // so that the handler code has access to these objects.
  GenerateStoreVariable(node->exception_var(),
                        kExceptionObjectReg,
                        kNoRegister);
  GenerateStoreVariable(node->stacktrace_var(),
                        kStackTraceObjectReg,
                        kNoRegister);

  // Now generate code for the catch handler block.
  node->VisitChildren(this);
}


void CodeGenerator::VisitTryCatchNode(TryCatchNode* node) {
  CodeGeneratorState codegen_state(this);
  int outer_try_index = state()->try_index();
  // We are about to generate code for a new try block, generate an
  // unique 'try index' for this block and set that try index in
  // the code generator state.
  int try_index = generate_next_try_index();
  state()->set_try_index(try_index);
  exception_handlers_list_->AddHandler(try_index, -1);

  // Preserve CTX into local variable '%saved_context'.
  GenerateStoreVariable(node->context_var(), CTX, kNoRegister);

  node->try_block()->Visit(this);

  // We are done generating code for the try block.
  ASSERT(state()->try_index() > CatchClauseNode::kInvalidTryIndex);
  ASSERT(try_index == state()->try_index());
  state()->set_try_index(outer_try_index);

  CatchClauseNode* catch_block = node->catch_block();
  if (catch_block != NULL) {
    // Jump over the catch handler block, when exceptions are thrown we
    // will end up at the next instruction.
    __ jmp(node->end_catch_label()->continue_label());

    // Set the corresponding try index for this catch block so
    // that we can set the appropriate handler pc when we generate
    // code for this catch block.
    catch_block->set_try_index(try_index);

    // Set the handler pc for this try index in the exception handler
    // table.
    exception_handlers_list_->SetPcOffset(try_index, assembler_->CodeSize());

    // Generate code for the catch block.
    catch_block->Visit(this);

    // Bind the end of catch blocks label here.
    __ Bind(node->end_catch_label()->continue_label());
  }

  // Generate code for the finally block if one exists.
  if (node->finally_block() != NULL) {
    node->finally_block()->Visit(this);
  }
}


void CodeGenerator::VisitThrowNode(ThrowNode* node) {
  node->exception()->Visit(this);
  // Exception object is on TOS.
  if (node->stacktrace() != NULL) {
    node->stacktrace()->Visit(this);
    GenerateCallRuntime(node->id(), node->token_index(), kReThrowRuntimeEntry);
  } else {
    GenerateCallRuntime(node->id(), node->token_index(), kThrowRuntimeEntry);
  }
  // We should never return here.
  __ int3();
}


void CodeGenerator::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  int try_index = state()->try_index();
  if (try_index >= 0) {
    // We are about to generate code for an inlined finally block. Exceptions
    // thrown in this block of code should be treated as though they are
    // thrown not from the current try block but the outer try block if any.
    // the code generator state.
    state()->set_try_index((try_index - 1));
  }

  // Restore CTX from local variable ':saved_context'.
  GenerateLoadVariable(CTX, node->context_var());
  node->finally_block()->Visit(this);

  if (try_index >= 0) {
    state()->set_try_index(try_index);
  }
}


void CodeGenerator::GenerateCall(intptr_t token_index,
                                 const ExternalLabel* ext_label,
                                 PcDescriptors::Kind desc_kind) {
  __ call(ext_label);
  AddCurrentDescriptor(desc_kind, AstNode::kNoId, token_index);
}


void CodeGenerator::GenerateCallRuntime(intptr_t node_id,
                                        intptr_t token_index,
                                        const RuntimeEntry& entry) {
  __ CallRuntime(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
}


void CodeGenerator::MarkDeoptPoint(intptr_t node_id,
                                   intptr_t token_index) {
  ASSERT(node_id != AstNode::kNoId);
  AddCurrentDescriptor(PcDescriptors::kDeopt, node_id, token_index);
}


// Uses current pc position and try-index.
void CodeGenerator::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                         intptr_t node_id,
                                         intptr_t token_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      node_id,
                                      token_index,
                                      state()->try_index());
}


void CodeGenerator::ErrorMsg(intptr_t token_index, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Class& cls = Class::Handle(parsed_function_.function().owner());
  const Script& script = Script::Handle(cls.script());
  const Error& error = Error::Handle(
      Parser::FormatError(script, token_index, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
