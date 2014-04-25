// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/il_printer.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(int, reoptimization_counter_threshold);

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


bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
}


bool FlowGraphCompiler::SupportsSinCos() {
  return false;
}


RawDeoptInfo* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                 DeoptInfoBuilder* builder,
                                                 const Array& deopt_table) {
  UNIMPLEMENTED();
  return NULL;
}


void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  UNIMPLEMENTED();
}


#define __ assembler()->


// Fall through if bool_register contains null.
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


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (is_optimizing()) {
    return;
  }
  Definition* defn = instr->AsDefinition();
  if ((defn != NULL) && defn->is_used()) {
    __ Push(defn->locs()->out(0).reg());
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
  Register new_pp = kNoRegister;
  if (CanOptimizeFunction() &&
      function.IsOptimizable() &&
      (!is_optimizing() || may_reoptimize())) {
    const Register function_reg = R6;
    new_pp = R13;

    // Set up pool pointer in new_pp.
    __ LoadPoolPointer(new_pp);

    // Load function object using the callee's pool pointer.
    __ LoadObject(function_reg, function, new_pp);

    // Patch point is after the eventually inlined function object.
    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
    intptr_t threshold = FLAG_optimization_counter_threshold;
    __ LoadFieldFromOffset(R7, function_reg, Function::usage_counter_offset());
    if (is_optimizing()) {
      // Reoptimization of an optimized function is triggered by counting in
      // IC stubs, but not at the entry of the function.
      threshold = FLAG_reoptimization_counter_threshold;
    } else {
      __ add(R7, R7, Operand(1));
      __ StoreFieldToOffset(R7, function_reg, Function::usage_counter_offset());
    }
    __ CompareImmediate(R7, threshold, new_pp);
    ASSERT(function_reg == R6);
    Label dont_optimize;
    __ b(&dont_optimize, LT);
    __ Branch(&StubCode::OptimizeFunctionLabel(), new_pp);
    __ Bind(&dont_optimize);
  } else if (!flow_graph().IsCompiledForOsr()) {
    // We have to load the PP here too because a load of an external label
    // may be patched at the AddCurrentDescriptor below.
    new_pp = R13;

    __ LoadPoolPointer(new_pp);

    AddCurrentDescriptor(PcDescriptors::kEntryPatch,
                         Isolate::kNoDeoptId,
                         0);  // No token position.
  }
  __ Comment("Enter frame");
  if (flow_graph().IsCompiledForOsr()) {
    intptr_t extra_slots = StackSize()
        - flow_graph().num_stack_locals()
        - flow_graph().num_copied_params();
    ASSERT(extra_slots >= 0);
    __ EnterOsrFrame(extra_slots * kWordSize, new_pp);
  } else {
    ASSERT(StackSize() >= 0);
    __ EnterDartFrameWithInfo(StackSize() * kWordSize, new_pp);
  }
}


// Input parameters:
//   LR: return address.
//   SP: address of last argument.
//   FP: caller's frame pointer.
//   PP: caller's pool pointer.
//   R5: ic-data.
//   R4: arguments descriptor array.
void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  TryIntrinsify();

  EmitFrameEntry();

  const Function& function = parsed_function().function();

  const int num_fixed_params = function.num_fixed_parameters();
  const int num_copied_params = parsed_function().num_copied_params();
  const int num_locals = parsed_function().num_stack_locals();

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are in debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
#ifdef DEBUG
    ASSERT(!parsed_function().function().HasOptionalParameters());
    const bool check_arguments = !flow_graph().IsCompiledForOsr();
#else
    const bool check_arguments =
        function.IsClosureFunction() && !flow_graph().IsCompiledForOsr();
#endif
    if (check_arguments) {
      __ Comment("Check argument count");
      // Check that exactly num_fixed arguments are passed in.
      Label correct_num_arguments, wrong_num_arguments;
      __ LoadFieldFromOffset(R0, R4, ArgumentsDescriptor::count_offset());
      __ CompareImmediate(R0, Smi::RawValue(num_fixed_params), PP);
      __ b(&wrong_num_arguments, NE);
      __ LoadFieldFromOffset(R1, R4,
            ArgumentsDescriptor::positional_count_offset());
      __ CompareRegisters(R0, R1);
      __ b(&correct_num_arguments, EQ);
      __ Bind(&wrong_num_arguments);
      if (function.IsClosureFunction()) {
        // Invoke noSuchMethod function passing the original function name.
        // For closure functions, use "call" as the original name.
        const String& name =
            String::Handle(function.IsClosureFunction()
                             ? Symbols::Call().raw()
                             : function.name());
        const int kNumArgsChecked = 1;
        const ICData& ic_data = ICData::ZoneHandle(
            ICData::New(function, name, Object::empty_array(),
                        Isolate::kNoDeoptId, kNumArgsChecked));
        __ LoadObject(R5, ic_data, PP);
        __ LeaveDartFrame();  // The arguments are still on the stack.
        __ Branch(&StubCode::CallNoSuchMethodFunctionLabel(), PP);
        // The noSuchMethod call may return to the caller, but not here.
        __ hlt(0);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&correct_num_arguments);
    }
  } else if (!flow_graph().IsCompiledForOsr()) {
    CopyParameters();
  }

  // In unoptimized code, initialize (non-argument) stack allocated slots to
  // null.
  if (!is_optimizing() && (num_locals > 0)) {
    __ Comment("Initialize spill slots");
    const intptr_t slot_base = parsed_function().first_stack_local_index();
    __ LoadObject(R0, Object::null_object(), PP);
    for (intptr_t i = 0; i < num_locals; ++i) {
      // Subtract index i (locals lie at lower addresses than FP).
      __ StoreToOffset(R0, FP, (slot_base - i) * kWordSize);
    }
  }

  VisitBlocks();

  __ hlt(0);
  GenerateDeferredCode();
  // Emit function patching code. This will be swapped with the first 3
  // instructions at entry point.
  AddCurrentDescriptor(PcDescriptors::kPatchCode,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  // This is patched up to a point in FrameEntry where the PP for the
  // current function is in R13 instead of PP.
  __ BranchPatchable(&StubCode::FixCallersTargetLabel(), R13);

  AddCurrentDescriptor(PcDescriptors::kLazyDeoptJump,
                       Isolate::kNoDeoptId,
                       0);  // No token position.
  // TODO(zra): Can I use a normal BranchPatchable here? Probably have to change
  // the CodePatcher.
  __ BranchFixed(&StubCode::DeoptimizeLazyLabel());
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
  const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id);
  if (is_optimizing()) {
    AddDeoptIndexAtCall(deopt_id_after, token_pos);
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    AddCurrentDescriptor(PcDescriptors::kDeopt, deopt_id_after, token_pos);
  }
}


void FlowGraphCompiler::GenerateRuntimeCall(intptr_t token_pos,
                                            intptr_t deopt_id,
                                            const RuntimeEntry& entry,
                                            intptr_t argument_count,
                                            LocationSummary* locs) {
  __ CallRuntime(entry, argument_count);
  AddCurrentDescriptor(PcDescriptors::kOther, deopt_id, token_pos);
  RecordSafepoint(locs);
  if (deopt_id != Isolate::kNoDeoptId) {
    // Marks either the continuation point in unoptimized code or the
    // deoptimization point in optimized code, after call.
    const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id);
    if (is_optimizing()) {
      AddDeoptIndexAtCall(deopt_id_after, token_pos);
    } else {
      // Add deoptimization continuation point after the call and before the
      // arguments are removed.
      AddCurrentDescriptor(PcDescriptors::kDeopt, deopt_id_after, token_pos);
    }
  }
}


void FlowGraphCompiler::EmitEdgeCounter() {
  // We do not check for overflow when incrementing the edge counter.  The
  // function should normally be optimized long before the counter can
  // overflow; and though we do not reset the counters when we optimize or
  // deoptimize, there is a bound on the number of
  // optimization/deoptimization cycles we will attempt.
  const Array& counter = Array::ZoneHandle(Array::New(1, Heap::kOld));
  counter.SetAt(0, Smi::Handle(Smi::New(0)));
  __ Comment("Edge counter");
  __ LoadObject(R0, counter, PP);
  __ LoadFieldFromOffset(TMP, R0, Array::element_offset(0));
  __ add(TMP, TMP, Operand(Smi::RawValue(1)));
  __ StoreFieldToOffset(TMP, R0, Array::element_offset(0));
}


void FlowGraphCompiler::EmitOptimizedInstanceCall(
    ExternalLabel* target_label,
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitInstanceCall(ExternalLabel* target_label,
                                         const ICData& ic_data,
                                         intptr_t argument_count,
                                         intptr_t deopt_id,
                                         intptr_t token_pos,
                                         LocationSummary* locs) {
  __ LoadObject(R5, ic_data, PP);
  GenerateDartCall(deopt_id,
                   token_pos,
                   target_label,
                   PcDescriptors::kIcCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitMegamorphicInstanceCall(
    const ICData& ic_data,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitUnoptimizedStaticCall(
    const Function& target_function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  // TODO(srdjan): Improve performance of function recognition.
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target_function);
  int num_args_checked = 0;
  if ((recognized_kind == MethodRecognizer::kMathMin) ||
      (recognized_kind == MethodRecognizer::kMathMax)) {
    num_args_checked = 2;
  }
  const ICData& ic_data = ICData::ZoneHandle(
      ICData::New(parsed_function().function(),  // Caller function.
                  String::Handle(target_function.name()),
                  arguments_descriptor,
                  deopt_id,
                  num_args_checked));  // No arguments checked.
  ic_data.AddTarget(target_function);
  uword label_address = 0;
  if (ic_data.num_args_tested() == 0) {
    label_address = StubCode::ZeroArgsUnoptimizedStaticCallEntryPoint();
  } else if (ic_data.num_args_tested() == 2) {
    label_address = StubCode::TwoArgsUnoptimizedStaticCallEntryPoint();
  } else {
    UNIMPLEMENTED();
  }
  ExternalLabel target_label("StaticCallICStub", label_address);
  __ LoadObject(R5, ic_data, PP);
  GenerateDartCall(deopt_id,
                   token_pos,
                   &target_label,
                   PcDescriptors::kUnoptStaticCall,
                   locs);
  __ Drop(argument_count);
}


void FlowGraphCompiler::EmitOptimizedStaticCall(
    const Function& function,
    const Array& arguments_descriptor,
    intptr_t argument_count,
    intptr_t deopt_id,
    intptr_t token_pos,
    LocationSummary* locs) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegConstCompare(Register reg,
                                                    const Object& obj,
                                                    bool needs_number_check,
                                                    intptr_t token_pos) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::EmitEqualityRegRegCompare(Register left,
                                                  Register right,
                                                  bool needs_number_check,
                                                  intptr_t token_pos) {
  if (needs_number_check) {
    __ Push(left);
    __ Push(right);
    if (is_optimizing()) {
      __ BranchLinkPatchable(
          &StubCode::OptimizedIdenticalWithNumberCheckLabel());
    } else {
      __ BranchLinkPatchable(
          &StubCode::UnoptimizedIdenticalWithNumberCheckLabel());
    }
    if (token_pos != Scanner::kNoSourcePos) {
      AddCurrentDescriptor(PcDescriptors::kRuntimeCall,
                           Isolate::kNoDeoptId,
                           token_pos);
    }
    // Stub returns result in flags (result of a cmpl, we need ZF computed).
    __ Pop(right);
    __ Pop(left);
  } else {
    __ CompareRegisters(left, right);
  }
}


// This function must be in sync with FlowGraphCompiler::RecordSafepoint and
// FlowGraphCompiler::SlowPathEnvironmentFor.
void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(zra): Save live FPU Registers.

  // Store general purpose registers with the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfCpuRegisters; ++reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ Push(reg);
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  // General purpose registers have the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = kNumberOfCpuRegisters - 1; reg_idx >= 0; --reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->ContainsRegister(reg)) {
      __ Pop(reg);
    }
  }

  // TODO(zra): Restore live FPU registers.
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  UNIMPLEMENTED();
}


// Do not implement or use this function.
FieldAddress FlowGraphCompiler::ElementAddressForIntIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          intptr_t index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


// Do not implement or use this function.
FieldAddress FlowGraphCompiler::ElementAddressForRegIndex(intptr_t cid,
                                                          intptr_t index_scale,
                                                          Register array,
                                                          Register index) {
  UNREACHABLE();  // No register indexed with offset addressing mode on ARM.
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForIntIndex(
    intptr_t index_scale,
    Register array,
    intptr_t index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


Address FlowGraphCompiler::ExternalElementAddressForRegIndex(
    intptr_t index_scale,
    Register array,
    Register index) {
  UNREACHABLE();
  return FieldAddress(array, index);
}


#undef __
#define __ compiler_->assembler()->


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


// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  UNREACHABLE();
}


// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  UNREACHABLE();
}


void ParallelMoveResolver::Exchange(Register reg, intptr_t stack_offset) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::Exchange(intptr_t stack_offset1,
                                    intptr_t stack_offset2) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
