// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

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
    ASSERT(!block_info_[i]->label.IsLinked());
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


void FlowGraphCompiler::CopyParameters() {
  UNIMPLEMENTED();
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
    const Register function_reg = R6;
    if (can_optimize) {
      __ LoadObject(function_reg, function);
    }
    // Patch point is after the eventually inlined function object.
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
    if (can_optimize) {
      // Reoptimization of optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      if (!is_optimizing()) {
        __ ldr(R7, FieldAddress(function_reg,
                                Function::usage_counter_offset()));
        __ add(R7, R7, ShifterOperand(1));
        __ str(R7, FieldAddress(function_reg,
                                Function::usage_counter_offset()));
      } else {
        __ ldr(R7, FieldAddress(function_reg,
                                Function::usage_counter_offset()));
      }
      __ CompareImmediate(R7, FLAG_optimization_counter_threshold);
      ASSERT(function_reg == R6);
      __ Branch(&StubCode::OptimizeFunctionLabel(), GE);
    }
  } else {
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  }
  __ Comment("Enter frame");
  __ EnterDartFrame((StackSize() * kWordSize));
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();
  if (TryIntrinsify()) {
    // Although this intrinsified code will never be patched, it must satisfy
    // CodePatcher::CodeIsPatchable, which verifies that this code has a minimum
    // code size.
    __ bkpt(0);
    __ Branch(&StubCode::FixCallersTargetLabel());
    return;
  }

  EmitFrameEntry();

  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();

  // For optimized code, keep a bitmap of the frame in order to build
  // stackmaps for GC safepoints in the prologue.
  LocationSummary* prologue_locs = NULL;
  if (is_optimizing()) {
    // Spill slots are allocated but not initialized.
    prologue_locs = new LocationSummary(0, 0, LocationSummary::kCall);
    prologue_locs->stack_bitmap()->SetLength(StackSize());
  }

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
      __ ldr(R0, FieldAddress(R4, ArgumentsDescriptor::count_offset()));
      __ CompareImmediate(R0, Smi::RawValue(num_fixed_params));
      __ b(&wrong_num_arguments, NE);
      __ ldr(R1, FieldAddress(R4,
                              ArgumentsDescriptor::positional_count_offset()));
      __ cmp(R0, ShifterOperand(R1));
      __ b(&correct_num_arguments, EQ);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        if (StackSize() != 0) {
          // We need to unwind the space we reserved for locals and copied
          // parameters. The NoSuchMethodFunction stub does not expect to see
          // that area on the stack.
          __ AddImmediate(SP, StackSize() * kWordSize);
        }
        // The call below has an empty stackmap because we have just
        // dropped the spill slots.
        BitmapBuilder* empty_stack_bitmap = new BitmapBuilder();

        // Invoke noSuchMethod function passing "call" as the function name.
        const int kNumArgsChecked = 1;
        const ICData& ic_data = ICData::ZoneHandle(
            ICData::New(function, Symbols::Call(),
                        Isolate::kNoDeoptId, kNumArgsChecked));
        __ LoadObject(R5, ic_data);
        // FP - 4 : saved PP, object pool pointer of caller.
        // FP + 0 : previous frame pointer.
        // FP + 4 : return address.
        // FP + 8 : PC marker, for easy identification of RawInstruction obj.
        // FP + 12: last argument (arg n-1).
        // SP + 0 : saved PP.
        // SP + 16 + 4*(n-1) : first argument (arg 0).
        // R5 : ic-data.
        // R4 : arguments descriptor array.
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
      const Register kArgumentsDescriptorReg = R4;
      // The saved_args_desc_var is allocated one slot before the first local.
      const intptr_t slot = parsed_function().first_stack_local_index() + 1;
      // If the saved_args_desc_var is captured, it is first moved to the stack
      // and later to the context, once the context is allocated.
      ASSERT(saved_args_desc_var->is_captured() ||
             (saved_args_desc_var->index() == slot));
      __ str(kArgumentsDescriptorReg, Address(FP, slot * kWordSize));
    }
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null. This does not cover the saved_args_desc_var slot.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    __ LoadImmediate(R0, reinterpret_cast<intptr_t>(Object::null()));
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      __ str(R0, Address(FP, (slot_base - i) * kWordSize));
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

  __ bkpt(0);
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
  UNIMPLEMENTED();
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
  UNIMPLEMENTED();
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
  __ LoadObject(R4, arguments_descriptor);
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
  __ PushList(cpu_registers);
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the lowest register number at the
  // lowest address.
  const intptr_t cpu_registers = locs->live_registers()->cpu_registers();
  ASSERT((cpu_registers & ~kAllCpuRegistersList) == 0);
  __ PopList(cpu_registers);

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
    intptr_t cid,
    intptr_t index_scale,
    Register array,
    intptr_t index) {
  UNIMPLEMENTED();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForRegIndex(
    intptr_t cid,
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

#endif  // defined TARGET_ARCH_ARM
