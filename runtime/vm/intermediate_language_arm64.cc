// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/intermediate_language.h"

#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, use_osr);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(R0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReturnInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  // UXTX 0 on a 64-bit register (FP) is a nop, but forces R31 to be
  // interpreted as SP.
  __ sub(R2, SP, Operand(FP, UXTX, 0));
  __ CompareImmediate(R2, fp_sp_dist, PP);
  __ b(&stack_ok, EQ);
  __ hlt(0);
  __ Bind(&stack_ok);
#endif
  __ LeaveDartFrame();
  __ ret();
}


LocationSummary* IfThenElseInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ConstantInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    Register result = locs()->out(0).reg();
    __ LoadObject(result, value(), PP);
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  UNIMPLEMENTED();
  return VS;
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* TestSmiInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


Condition TestSmiInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  UNIMPLEMENTED();
  return VS;
}

void TestSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void TestSmiInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                  BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  UNIMPLEMENTED();
  return VS;
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* NativeCallInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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


LocationSummary* LoadIndexedInstr::MakeLocationSummary(bool opt) const {
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


LocationSummary* StoreIndexedInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* GuardFieldInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void GuardFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CloneContextInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (FLAG_use_osr) {
      uword flags_address = Isolate::Current()->stack_overflow_flags_address();
      Register value = instruction_->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(TMP, flags_address, PP);
      __ LoadImmediate(value, Isolate::kOsrRequest, PP);
      __ str(value, Address(TMP));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  0,
                                  instruction_->locs());

    if (FLAG_use_osr && !compiler->is_optimizing() && instruction_->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(PcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     0);  // No token position.
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(FLAG_use_osr);
    return &osr_entry_label_;
  }

 private:
  CheckStackOverflowInstr* instruction_;
  Label osr_entry_label_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(TMP, Isolate::Current()->stack_limit_address(), PP);
  __ ldr(TMP, Address(TMP));
  __ CompareRegisters(SP, TMP);
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function(), PP);
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ LoadFieldFromOffset(temp, temp, Function::usage_counter_offset());
    __ CompareImmediate(temp, threshold, PP);
    __ b(slow_path->osr_entry_label(), GE);
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ b(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxFloat64x2Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxInt32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2OneArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MathMinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ExtractNthOutputInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MergedMathInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MergedMathInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BranchInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckClassInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ThrowInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReThrowInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
  }
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    compiler->EmitEdgeCounter();
    // Add an edge counter.
    // On ARM64 the deoptimization descriptor points after the edge counter
    // code so that we can reuse the same pattern matching code as at call
    // sites, which matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                   deopt_id_,
                                   Scanner::kNoSourcePos);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CurrentContextInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  UNIMPLEMENTED();
  return VS;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
