// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/flow_graph_compiler.h"

#include "lib/error.h"
#include "vm/ast_printer.h"
#include "vm/dart_entry.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, enable_type_checks);


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}


bool FlowGraphCompiler::SupportsUnboxedMints() {
  return false;
}


void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  UNIMPLEMENTED();
}


#define __ assembler()->


void FlowGraphCompiler::GenerateBoolToJump(Register bool_register,
                                           Label* is_true,
                                           Label* is_false) {
  UNIMPLEMENTED();
}


RawSubtypeTestCache* FlowGraphCompiler::GenerateCallSubtypeTestStub(
    TypeTestStubKind test_kind,
    Register instance_reg,
    Register type_arguments_reg,
    Register temp_reg,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


RawSubtypeTestCache*
FlowGraphCompiler::GenerateInstantiatedTypeWithArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


void FlowGraphCompiler::CheckClassIds(Register class_id_reg,
                                      const GrowableArray<intptr_t>& class_ids,
                                      Label* is_equal_lbl,
                                      Label* is_not_equal_lbl) {
  UNIMPLEMENTED();
}


bool FlowGraphCompiler::GenerateInstantiatedTypeNoArgumentsTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return false;
}


RawSubtypeTestCache* FlowGraphCompiler::GenerateSubtype1TestCacheLookup(
    intptr_t token_pos,
    const Class& type_class,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


RawSubtypeTestCache* FlowGraphCompiler::GenerateUninstantiatedTypeTest(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


RawSubtypeTestCache* FlowGraphCompiler::GenerateInlineInstanceof(
    intptr_t token_pos,
    const AbstractType& type,
    Label* is_instance_lbl,
    Label* is_not_instance_lbl) {
  UNIMPLEMENTED();
  return NULL;
}


void FlowGraphCompiler::GenerateInstanceOf(intptr_t token_pos,
                                           intptr_t deopt_id,
                                           const AbstractType& type,
                                           bool negate_result,
                                           LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::GenerateAssertAssignable(intptr_t token_pos,
                                                 intptr_t deopt_id,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitInstructionPrologue(Instruction* instr) {
  if (!is_optimizing()) {
    if (FLAG_enable_type_checks && instr->IsAssertAssignable()) {
      AssertAssignableInstr* assert = instr->AsAssertAssignable();
      AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                           assert->deopt_id(),
                           assert->token_pos());
    }
    AllocateRegistersLocally(instr);
  }
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) return;
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->is_used()) {
    __ Push(defn->locs()->out().reg());
  }
}


// Input parameters:
//   S4: arguments descriptor array.
void FlowGraphCompiler::CopyParameters() {
  __ Comment("Copy parameters");
  const Function& function = parsed_function().function();
  LocalScope* scope = parsed_function().node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_pos_params = function.NumOptionalPositionalParameters();
  const int num_opt_named_params = function.NumOptionalNamedParameters();
  const int num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  ASSERT(function.NumParameters() == num_params);
  ASSERT(parsed_function().first_parameter_index() == kFirstLocalSlotIndex);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;
  const int max_num_pos_args = num_fixed_params + num_opt_pos_params;

  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
  // Check that min_num_pos_args <= num_pos_args.
  Label wrong_num_arguments;
  __ addiu(T3, T2, Immediate(-Smi::RawValue(min_num_pos_args)));
  __ bltz(T3, &wrong_num_arguments);

  // Check that num_pos_args <= max_num_pos_args.
  __ addiu(T3, T2, Immediate(-Smi::RawValue(max_num_pos_args)));
  __ bgtz(T3, &wrong_num_arguments);

  // Copy positional arguments.
  // Argument i passed at fp[kLastParamSlotIndex + num_args - 1 - i] is copied
  // to fp[kFirstLocalSlotIndex - i].

  __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  // Since T1 and T2 are Smi, use LSL 1 instead of LSL 2.
  // Let T1 point to the last passed positional argument, i.e. to
  // fp[kLastParamSlotIndex + num_args - 1 - (num_pos_args - 1)].
  __ subu(T1, T1, T2);
  __ sll(T1, T1, 1);
  __ addu(T1, FP, T1);
  __ addiu(T1, T1, Immediate(kLastParamSlotIndex * kWordSize));

  // Let T0 point to the last copied positional argument, i.e. to
  // fp[kFirstLocalSlotIndex - (num_pos_args - 1)].
  __ addiu(T0, FP, Immediate((kFirstLocalSlotIndex + 1) * kWordSize));
  __ sll(T3, T2, 1);  // T2 is a Smi.
  __ subu(T0, T0, T3);

  Label loop, loop_condition;
  __ b(&loop_condition);
  __ delay_slot()->SmiUntag(T2);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  __ Bind(&loop);
  __ addu(T4, T1, T2);
  __ addu(T5, T0, T2);
  __ lw(TMP, Address(T4));
  __ sw(TMP, Address(T5));
  __ Bind(&loop_condition);
  __ addiu(T2, T2, Immediate(-4));
  __ bgez(T2, &loop);

  // Copy or initialize optional named arguments.
  Label all_arguments_processed;
  if (num_opt_named_params > 0) {
    // Start by alphabetically sorting the names of the optional parameters.
    LocalVariable** opt_param = new LocalVariable*[num_opt_named_params];
    int* opt_param_position = new int[num_opt_named_params];
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
    __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
    __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    // Let T1 point to the first passed argument, i.e. to
    // fp[kLastParamSlotIndex + num_args - 1 - 0]; num_args (T1) is Smi.
    __ sll(T3, T1, 1);
    __ addu(T1, FP, T3);
    __ addiu(T1, T1, Immediate((kLastParamSlotIndex - 1) * kWordSize));
    // Let T0 point to the entry of the first named argument.
    __ addiu(T0, S4, Immediate(
        ArgumentsDescriptor::first_named_entry_offset() - kHeapObjectTag));
    for (int i = 0; i < num_opt_named_params; i++) {
      Label load_default_value, assign_optional_parameter;
      const int param_pos = opt_param_position[i];
      // Check if this named parameter was passed in.
      // Load T3 with the name of the argument.
      __ lw(T3, Address(T0, ArgumentsDescriptor::name_offset()));
      ASSERT(opt_param[i]->name().IsSymbol());
      __ LoadObject(T4, opt_param[i]->name());
      __ bne(T3, T4, &load_default_value);

      // Load T3 with passed-in argument at provided arg_pos, i.e. at
      // fp[kLastParamSlotIndex + num_args - 1 - arg_pos].
      __ lw(T3, Address(T0, ArgumentsDescriptor::position_offset()));
      // T3 is arg_pos as Smi.
      // Point to next named entry.
      __ addiu(T0, T0, Immediate(ArgumentsDescriptor::named_entry_size()));
      __ subu(T3, ZR, T3);
      __ sll(T3, T3, 1);
      __ addu(T3, T1, T3);
      __ b(&assign_optional_parameter);
      __ delay_slot()->lw(T3, Address(T3));

      __ Bind(&load_default_value);
      // Load T3 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(
              param_pos - num_fixed_params));
      __ LoadObject(T3, value);
      __ Bind(&assign_optional_parameter);
      // Assign T3 to fp[kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotIndex - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
    }
    delete[] opt_param;
    delete[] opt_param_position;
    // Check that T0 now points to the null terminator in the array descriptor.
    __ lw(T3, Address(T0));
    __ LoadImmediate(T4, reinterpret_cast<int32_t>(Object::null()));
    __ beq(T3, T4, &all_arguments_processed);
  } else {
    ASSERT(num_opt_pos_params > 0);
    __ lw(T2,
          FieldAddress(S4, ArgumentsDescriptor::positional_count_offset()));
    __ SmiUntag(T2);
    for (int i = 0; i < num_opt_pos_params; i++) {
      Label next_parameter;
      // Handle this optional positional parameter only if k or fewer positional
      // arguments have been passed, where k is param_pos, the position of this
      // optional parameter in the formal parameter list.
      const int param_pos = num_fixed_params + i;
      __ addiu(T3, T2, Immediate(-param_pos));
      __ bgtz(T3, &next_parameter);
      // Load T3 with default argument.
      const Object& value = Object::ZoneHandle(
          parsed_function().default_parameter_values().At(i));
      __ LoadObject(T3, value);
      // Assign T3 to fp[kFirstLocalSlotIndex - param_pos].
      // We do not use the final allocation index of the variable here, i.e.
      // scope->VariableAt(i)->index(), because captured variables still need
      // to be copied to the context that is not yet allocated.
      const intptr_t computed_param_pos = kFirstLocalSlotIndex - param_pos;
      __ sw(T3, Address(FP, computed_param_pos * kWordSize));
      __ Bind(&next_parameter);
    }
    __ lw(T1, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
    __ SmiUntag(T1);
    // Check that T2 equals T1, i.e. no named arguments passed.
    __ beq(T2, T2, &all_arguments_processed);
  }

  __ Bind(&wrong_num_arguments);
  if (StackSize() != 0) {
    // We need to unwind the space we reserved for locals and copied parameters.
    // The NoSuchMethodFunction stub does not expect to see that area on the
    // stack.
    __ addiu(SP, SP, Immediate(StackSize() * kWordSize));
  }
  // The call below has an empty stackmap because we have just
  // dropped the spill slots.
  BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();

  // Invoke noSuchMethod function passing the original name of the function.
  // If the function is a closure function, use "call" as the original name.
  const String& name = String::Handle(
      function.IsClosureFunction() ? Symbols::Call().raw() : function.name());
  const int kNumArgsChecked = 1;
  const ICData& ic_data = ICData::ZoneHandle(
      ICData::New(function, name, Isolate::kNoDeoptId, kNumArgsChecked));
  __ LoadObject(S5, ic_data);
  // FP - 4 : saved PP, object pool pointer of caller.
  // FP + 0 : previous frame pointer.
  // FP + 4 : return address.
  // FP + 8 : PC marker, for easy identification of RawInstruction obj.
  // FP + 12: last argument (arg n-1).
  // SP + 0 : saved PP.
  // SP + 16 + 4*(n-1) : first argument (arg 0).
  // S5 : ic-data.
  // S4 : arguments descriptor array.
  __ BranchLink(&StubCode::CallNoSuchMethodFunctionLabel());
  if (is_optimizing()) {
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                      empty_stack_bitmap,
                                      0);  // No registers.
  }
  // The noSuchMethod call may return.
  __ LeaveDartFrame();
  __ Ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // S4 : arguments descriptor array.
  __ lw(T2, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
  __ SmiUntag(T2);

  __ LoadImmediate(TMP, reinterpret_cast<intptr_t>(Object::null()));
  Label null_args_loop, null_args_loop_condition;
  __ b(&null_args_loop_condition);
  __ delay_slot()->addiu(T1, FP, Immediate(kLastParamSlotIndex * kWordSize));
  __ Bind(&null_args_loop);
  __ addu(T3, T1, T2);
  __ sw(TMP, Address(T3));
  __ Bind(&null_args_loop_condition);
  __ addiu(T2, T2, Immediate(-4));
  __ bgez(T2, &null_args_loop);
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  if (CanOptimizeFunction() && function.is_optimizable()) {
    const bool can_optimize = !is_optimizing() || may_reoptimize();
    const Register function_reg = T0;
    if (can_optimize) {
      Label next;
      // The pool pointer is not setup before entering the Dart frame.

      __ mov(TMP, RA);  // Save RA.
      __ bal(&next);  // Branch and link to next instruction to get PC in RA.
      __ delay_slot()->mov(T2, RA);  // Save PC of the following mov.

      // Calculate offset of pool pointer from the PC.
      const intptr_t object_pool_pc_dist =
         Instructions::HeaderSize() - Instructions::object_pool_offset() +
         assembler()->CodeSize();

      __ Bind(&next);
      __ mov(RA, TMP);  // Restore RA.

      // Preserve PP of caller.
      __ mov(T1, PP);

      // Temporarily setup pool pointer for this dart function.
      __ lw(PP, Address(T2, -object_pool_pc_dist));

      // Load function object from object pool.
      __ LoadObject(function_reg, function);  // Uses PP.

      // Restore PP of caller.
      __ mov(PP, T1);
    }
    // Patch point is after the eventually inlined function object.
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
    if (can_optimize) {
      // Reoptimization of optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ lw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
        __ addiu(T1, T1, Immediate(1));
        __ sw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
      } else {
        __ lw(T1, FieldAddress(function_reg,
                               Function::usage_counter_offset()));
      }

      // Skip Branch if T1 is less than the threshold.
      Label dont_branch;
      __ LoadImmediate(T2, FLAG_optimization_counter_threshold);
      __ sltu(T2, T1, T2);
      __ bgtz(T2, &dont_branch);

      ASSERT(function_reg == T0);
      __ Branch(&StubCode::OptimizeFunctionLabel());

      __ Bind(&dont_branch);
    }
  } else {
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  }
  __ Comment("Enter frame");
  __ EnterDartFrame((StackSize() * kWordSize));
}


// Input parameters:
//   RA: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   S5: ic-data.
//   S4: arguments descriptor array.
void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    // Although this intrinsified code will never be patched, it must satisfy
    // CodePatcher::CodeIsPatchable, which verifies that this code has a minimum
    // code size.
    __ break_(0);
    __ Branch(&StubCode::FixCallersTargetLabel());
    return;
  }

  EmitFrameEntry();

  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are in debug mode or unless we are compiling a closure.
  LocalVariable* saved_args_desc_var =
      parsed_function().GetSavedArgumentsDescriptorVar();
  if (num_copied_params == 0) {
#ifdef DEBUG
    ASSERT(!parsed_function().function().HasOptionalParameters());
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ lw(T0, FieldAddress(S4, ArgumentsDescriptor::count_offset()));
      __ LoadImmediate(T1, Smi::RawValue(num_fixed_params));
      __ bne(T0, T1, &wrong_num_arguments);

      __ lw(T1, FieldAddress(S4,
                             ArgumentsDescriptor::positional_count_offset()));
      __ beq(T0, T1, &correct_num_arguments);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        if (StackSize() != 0) {
          // We need to unwind the space we reserved for locals and copied
          // parameters. The NoSuchMethodFunction stub does not expect to see
          // that area on the stack.
          __ addiu(SP, SP, Immediate(StackSize() * kWordSize));
        }
        // The call below has an empty stackmap because we have just
        // dropped the spill slots.
        BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();

        // Invoke noSuchMethod function passing "call" as the function name.
        const int kNumArgsChecked = 1;
        const ICData& ic_data = ICData::ZoneHandle(
            ICData::New(function, Symbols::Call(),
                        Isolate::kNoDeoptId, kNumArgsChecked));
        __ LoadObject(S5, ic_data);
        // FP - 4 : saved PP, object pool pointer of caller.
        // FP + 0 : previous frame pointer.
        // FP + 4 : return address.
        // FP + 8 : PC marker, for easy identification of RawInstruction obj.
        // FP + 12: last argument (arg n-1).
        // SP + 0 : saved PP.
        // SP + 16 + 4*(n-1) : first argument (arg 0).
        // S5 : ic-data.
        // S4 : arguments descriptor array.
        __ BranchLink(&StubCode::CallNoSuchMethodFunctionLabel());
        if (is_optimizing()) {
          stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                            empty_stack_bitmap,
                                            0);  // No registers.
        }
        // The noSuchMethod call may return.
        __ LeaveDartFrame();
        __ Ret();
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&correct_num_arguments);
    }
    // The arguments descriptor is never saved in the absence of optional
    // parameters, since any argument definition test would always yield true.
    ASSERT(saved_args_desc_var == NULL);
  } else {
    if (saved_args_desc_var != NULL) {
      __ Comment("Save arguments descriptor");
      const Register kArgumentsDescriptorReg = S4;
      // The saved_args_desc_var is allocated one slot before the first local.
      const intptr_t slot = parsed_function().first_stack_local_index() + 1;
      // If the saved_args_desc_var is captured, it is first moved to the stack
      // and later to the context, once the context is allocated.
      ASSERT(saved_args_desc_var->is_captured() ||
             (saved_args_desc_var->index() == slot));
      __ sw(kArgumentsDescriptorReg, Address(FP, slot * kWordSize));
    }
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null. This does not cover the saved_args_desc_var slot.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    __ LoadImmediate(T0, reinterpret_cast<intptr_t>(Object::null()));
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      __ sw(T0, Address(FP, (slot_base - i) * kWordSize));
    }
  }

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

  __ break_(0);
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 5 bytes
  // at entry point.
  AddCurrentDescriptor(PcDescriptors::kPatchCode,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ Branch(&StubCode::FixCallersTargetLabel());
  AddCurrentDescriptor(PcDescriptors::kLazyDeoptJump,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  __ Branch(&StubCode::DeoptimizeLazyLabel());
}


void FlowGraphCompiler::GenerateCall(intptr_t token_pos,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind,
                                     LocationSummary* locs) {
  __ BranchLinkPatchable(label);
  AddCurrentDescriptor(kind, Isolate::kNoDeoptId, token_pos);
  RecordSafepoint(locs);
}


void FlowGraphCompiler::GenerateDartCall(intptr_t deopt_id,
                                         intptr_t token_pos,
                                         const ExternalLabel* label,
                                         PcDescriptors::Kind kind,
                                         LocationSummary* locs) {
  __ BranchLinkPatchable(label);
  AddCurrentDescriptor(kind, deopt_id, token_pos);
  RecordSafepoint(locs);
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id, token_pos);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(PcDescriptors::kDeoptAfter,
                         deopt_id,
                         token_pos);
  }
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            LocationSummary* locs) {
  __ Unimplemented("call runtime");
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         const Array& arguments_descriptor,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  __ LoadObject(S4, arguments_descriptor);
  __ LoadObject(S5, ic_data);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitStaticCall(const Function& function,
                                       const Array& arguments_descriptor,
                                       intptr_t argument_count,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       LocationSummary* locs) {
  __ LoadObject(S4, arguments_descriptor);
  // Do not use the code from the function, but let the code be patched so that
  // we can record the outgoing edges to other code.
  GenerateDartCall(deopt_id,
                   token_pos,
                   &StubCode::CallStaticFunctionLabel(),
                   PcDescriptors::kFuncCall,
                   locs);
  AddStaticCallTarget(function);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitEqualityRegConstCompare(Register reg,
                                                    const Object& obj,
                                                    bool needs_number_check) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                  Register right,
                                                  bool needs_number_check) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitSuperEqualityCallPrologue(Register result,
                                                      Label* skip_call) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  const intptr_t fpu_registers = locs->live_registers()->fpu_registers();
  if (fpu_registers > 0) {
    UNIMPLEMENTED();
  }

  // Store general purpose registers with the lowest register number at the
  // lowest address.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  int registers_pushed = 0;

  __ addiu(SP, SP, Immediate(-register_count * kWordSize));
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    Register r = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(r)) {
      __ sw(r, Address(SP, registers_pushed * kWordSize));
      registers_pushed++;
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the lowest register number at the
  // lowest address.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  const int register_count = Utils::CountOneBits(cpu_registers);
  int registers_popped = 0;

  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    Register r = static_cast<Register>(i);
    if (locs->live_registers()->ContainsRegister(r)) {
      __ lw(r, Address(SP, registers_popped * kWordSize));
      registers_popped++;
    }
  }
  __ addiu(SP, SP, Immediate(register_count * kWordSize));

  const intptr_t fpu_registers = locs->live_registers()->fpu_registers();
  if (fpu_registers > 0) {
    UNIMPLEMENTED();
  }
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t arg_count,
                                        const Array& arg_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitDoubleCompareBranch(Condition true_condition,
                                                FpuRegister left,
                                                FpuRegister right,
                                                BranchInstr* branch) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitDoubleCompareBool(Condition true_condition,
                                              FpuRegister left,
                                              FpuRegister right,
                                              Register result) {
  UNIMPLEMENTED();
}


Condition FlowGraphCompiler::FlipCondition(Condition condition) {
  UNIMPLEMENTED();
  return condition;
}


bool FlowGraphCompiler::EvaluateCondition(Condition condition,
                                          intptr_t left,
                                          intptr_t right) {
  UNIMPLEMENTED();
  return false;
}


FieldAddress FlowGraphCompiler::ElementAddressForIntIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          intptr_t index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


FieldAddress FlowGraphCompiler::ElementAddressForRegIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          Register index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForIntIndex(
    intptr_t index_scale,
    Register array,
    intptr_t index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForRegIndex(
    intptr_t index_scale,
    Register array,
    Register index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


void ParallelMoveResolver::EmitMove(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::EmitSwap(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::MoveMemoryToMemory(const Address& dst,
                                              const Address& src) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  UNIMPLEMENTED();
}


}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
