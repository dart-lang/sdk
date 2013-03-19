// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/intermediate_language.h"

#include "lib/error.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(R0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == R0);
#if defined(DEBUG)
  // TODO(srdjan): Fix for functions with finally clause.
  // A finally clause may leave a previously pushed return value if it
  // has its own return instruction. Method that have finally are currently
  // not optimized.
  if (!compiler->HasFinally()) {
    __ Comment("Stack Check");
    const int sp_fp_dist = compiler->StackSize() + (-kFirstLocalSlotIndex - 1);
    __ sub(R2, FP, ShifterOperand(SP));
    __ CompareImmediate(R2, sp_fp_dist * kWordSize);
    __ bkpt(0, NE);
  }
#endif
  __ LeaveDartFrame();
  __ Ret();

  // Generate 2 NOP instructions so that the debugger can patch the return
  // pattern (1 instruction) with a call to the debug stub (3 instructions).
  __ nop();
  __ nop();
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 Isolate::kNoDeoptId,
                                 token_pos());
}


LocationSummary* ClosureCallInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* LoadLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ LoadFromOffset(kLoadWord, result, FP, local().index() * kWordSize);
}


LocationSummary* StoreLocalInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ConstantInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out().IsInvalid()) {
    Register result = locs()->out().reg();
    __ LoadObject(result, value());
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ArgumentDefinitionTestInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ArgumentDefinitionTestInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* RelationalOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* NativeCallInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_temp(1, Location::RegisterLocation(R2));
  locs->set_temp(2, Location::RegisterLocation(R5));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->temp(1).reg() == R2);
  ASSERT(locs()->temp(2).reg() == R5);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in R2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(R2, FP, (kLastParamSlotIndex +
                             function().NumParameters() - 1) * kWordSize);
  } else {
    __ AddImmediate(R2, FP, kFirstLocalSlotIndex * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(native_c_function());
#if defined(USING_SIMULATOR)
  entry = Simulator::RedirectExternalReference(entry, Simulator::kNativeCall);
#endif
  __ LoadImmediate(R5, entry);
  __ LoadImmediate(R1, NativeArguments::ComputeArgcTag(function()));
  compiler->GenerateCall(token_pos(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


CompileType LoadIndexedInstr::ComputeType() const {
  UNIMPLEMENTED();
  return CompileType::Dynamic();
}


Representation LoadIndexedInstr::representation() const {
  UNIMPLEMENTED();
  return kTagged;
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  UNIMPLEMENTED();
  return kTagged;
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* GuardFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void GuardFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateArrayInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
AllocateObjectWithBoundsCheckInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateObjectWithBoundsCheckInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorTypeArgumentsInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ExtractConstructorTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorInstantiatorInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ExtractConstructorInstantiatorInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CloneContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CatchEntryInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CatchEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    compiler->pending_deoptimization_env_ = instruction_->env();
    compiler->GenerateCallRuntime(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  instruction_->locs());
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

 private:
  CheckStackOverflowInstr* instruction_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(IP, Isolate::Current()->stack_limit_address());
  __ ldr(IP, Address(IP));
  __ cmp(SP, ShifterOperand(IP));
  __ b(slow_path->entry_label(), LS);
  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathSqrtInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void MathSqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckClassInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckSmiInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* GotoInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void ControlInstruction::EmitBranchOnValue(FlowGraphCompiler* compiler,
                                           bool value) {
  UNIMPLEMENTED();
}


void ControlInstruction::EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                               Condition true_condition) {
  UNIMPLEMENTED();
}


LocationSummary* CurrentContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StrictCompareInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  UNIMPLEMENTED();
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ChainContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ChainContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreVMFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreVMFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateClosureInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CreateClosureInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

