// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/intermediate_language.h"

#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/stub_code.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, trace_functions);

// True iff. the arguments to a call will be properly pushed and can
// be popped after the call.
template <typename T> static bool VerifyCallComputation(T* comp) {
  // Argument values should be consecutive temps.
  //
  // TODO(kmillikin): implement stack height tracking so we can also assert
  // they are on top of the stack.
  intptr_t previous = -1;
  for (int i = 0; i < comp->ArgumentCount(); ++i) {
    Value* val = comp->ArgumentAt(i);
    if (!val->IsUse()) return false;
    intptr_t current = val->AsUse()->definition()->temp_index();
    if (i != 0) {
      if (current != (previous + 1)) return false;
    }
    previous = current;
  }
  return true;
}


// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
static LocationSummary* MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0);
  result->set_out(Location::RegisterLocation(EAX));
  return result;
}


void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  computation()->EmitNativeCode(compiler);
  __ pushl(locs()->out().reg());
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new LocationSummary(kNumInputs, kNumTemps);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(result == EAX);
  if (!compiler->is_optimizing()) {
    // Count only in unoptimized code.
    // TODO(srdjan): Replace the counting code with a type feedback
    // collection and counting stub.
    const Function& function =
          Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ incl(FieldAddress(temp, Function::usage_counter_offset()));
    if (CodeGenerator::CanOptimize()) {
      // Do not optimize if usage count must be reported.
      __ cmpl(FieldAddress(temp, Function::usage_counter_offset()),
          Immediate(FLAG_optimization_counter_threshold));
      Label not_yet_hot;
      __ j(LESS_EQUAL, &not_yet_hot, Assembler::kNearJump);
      __ pushl(result);  // Preserve result.
      __ pushl(temp);  // Argument for runtime: function to optimize.
      __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
      __ popl(temp);  // Remove argument.
      __ popl(result);  // Restore result.
      __ Bind(&not_yet_hot);
    }
  }
  if (FLAG_trace_functions) {
    const Function& function =
        Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ pushl(result);  // Preserve result.
    __ pushl(temp);
    compiler->GenerateCallRuntime(AstNode::kNoId,
                                  0,
                                  CatchClauseNode::kInvalidTryIndex,
                                  kTraceFunctionExitRuntimeEntry);
    __ popl(temp);  // Remove argument.
    __ popl(result);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();
  // Add a NOP to make return code pattern 5 bytes long for patching
  // in breakpoints during debugging.
  __ nop(1);
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 cid(),
                                 token_index(),
                                 CatchClauseNode::kInvalidTryIndex);
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  return NULL;
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  return NULL;
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  return NULL;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CurrentContextComp::MakeLocationSummary() const {
  return NULL;
}


void CurrentContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreContextComp::MakeLocationSummary() const {
  return NULL;
}


void StoreContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StrictCompareComp::MakeLocationSummary() const {
  return NULL;
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ClosureCallComp::MakeLocationSummary() const {
  return NULL;
}


void ClosureCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void InstanceCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 cid(),
                                 token_index(),
                                 try_index());
  compiler->EmitInstanceCall(cid(),
                             token_index(),
                             try_index(),
                             function_name(),
                             ArgumentCount(),
                             argument_names(),
                             checked_argument_count());
}


LocationSummary* StaticCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void StaticCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(VerifyCallComputation(this));
  compiler->EmitStaticCall(token_index(),
                           try_index(),
                           function(),
                           ArgumentCount(),
                           argument_names());
}


LocationSummary* LoadLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void LoadLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ movl(result, Address(EBP, local().index() * kWordSize));
}


LocationSummary* StoreLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(1, Location::SameAsFirstInput());
}


void StoreLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movl(Address(EBP, local().index() * kWordSize), value);
}


LocationSummary* ConstantVal::MakeLocationSummary() const {
  return LocationSummary::Make(0, Location::RequiresRegister());
}


void ConstantVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  if (value().IsSmi()) {
    int32_t imm = reinterpret_cast<int32_t>(value().raw());
    __ movl(result, Immediate(imm));
  } else {
    __ LoadObject(result, value());
  }
}


LocationSummary* UseVal::MakeLocationSummary() const {
  return NULL;
}


void UseVal::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AssertAssignableComp::MakeLocationSummary() const {
  return NULL;
}


void AssertAssignableComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AssertBooleanComp::MakeLocationSummary() const {
  return NULL;
}


void AssertBooleanComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareComp::MakeLocationSummary() const {
  return NULL;
}


void EqualityCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* NativeCallComp::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(0, 3);
  locs->set_temp(0, Location::RegisterLocation(EAX));
  locs->set_temp(1, Location::RegisterLocation(ECX));
  locs->set_temp(2, Location::RegisterLocation(EDX));
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void NativeCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EAX);
  ASSERT(locs()->temp(1).reg() == ECX);
  ASSERT(locs()->temp(2).reg() == EDX);
  Register result = locs()->out().reg();
  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in EAX.
  if (!has_optional_parameters()) {
    __ leal(EAX, Address(EBP, (1 + argument_count()) * kWordSize));
  } else {
    __ leal(EAX,
            Address(EBP, ParsedFunction::kFirstLocalSlotIndex * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movl(EDX, Immediate(argument_count()));
  compiler->GenerateCall(token_index(),
                         try_index(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther);
  __ popl(result);
}


LocationSummary* StoreIndexedComp::MakeLocationSummary() const {
  return NULL;
}


void StoreIndexedComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceSetterComp::MakeLocationSummary() const {
  return NULL;
}


void InstanceSetterComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StaticSetterComp::MakeLocationSummary() const {
  return NULL;
}


void StaticSetterComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateComp::MakeLocationSummary() const {
  return NULL;
}


void BooleanNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfComp::MakeLocationSummary() const {
  return NULL;
}


void InstanceOfComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateArrayComp::MakeLocationSummary() const {
  return NULL;
}


void CreateArrayComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateClosureComp::MakeLocationSummary() const {
  return NULL;
}


void CreateClosureComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateObjectComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateObjectComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
AllocateObjectWithBoundsCheckComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateObjectWithBoundsCheckComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadVMFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreVMFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeArgumentsComp::MakeLocationSummary() const {
  return NULL;
}


void InstantiateTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorTypeArgumentsComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorInstantiatorComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorInstantiatorComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ChainContextComp::MakeLocationSummary() const {
  return NULL;
}


void ChainContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CloneContextComp::MakeLocationSummary() const {
  return NULL;
}


void CloneContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CatchEntryComp::MakeLocationSummary() const {
  return NULL;
}


void CatchEntryComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(kNumInputs, kNumTemps);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void BinaryOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(srdjan): Remove this code once BinaryOpComp has been implemeneted
  // for all intended operations.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushl(left);
  __ pushl(right);
  InstanceCallComp* instance_call_comp = instance_call();
  instance_call_comp->EmitNativeCode(compiler);
  if (locs()->out().reg() != EAX) {
    __ movl(locs()->out().reg(), EAX);
  }
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
