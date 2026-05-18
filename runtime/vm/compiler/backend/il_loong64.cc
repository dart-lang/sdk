// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/locations.h"

namespace dart {

LocationSummary* Instruction::MakeCallSummary(Zone*,
                                              const Instruction*,
                                              LocationSummary*) {
  UNIMPLEMENTED();
  return nullptr;
}

DEFINE_UNIMPLEMENTED_INSTRUCTION(AllocateContextInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(AllocateObjectInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(AllocateUninitializedContextInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryDoubleOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt64OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinarySmiOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BitCastInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoolToIntInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BooleanNegateInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxInt64Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxInteger32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxLanesInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BranchInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CatchBlockEntryInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckArrayBoundInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckClassIdInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckEitherNonSmiInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckFieldImmutabilityInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckSmiInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckStackOverflowInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckWritableInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CloneContextInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(ClosureCallInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(ConstantInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CreateArrayInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(DartReturnInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(DoubleToFloatInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(DoubleToIntegerInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(DoubleToSmiInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(ExtractNthOutputInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(FfiCallInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(FloatCompareInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(FloatToDoubleInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(GotoInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldClassInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldLengthInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldTypeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(HashDoubleOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(HashIntegerOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(IfThenElseInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(IndirectGotoInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(InstanceOfInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(Int32ToDoubleInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(Int64ToDoubleInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(IntConverterInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(IntToBoolInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(InvokeMathCFunctionInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(LeafRuntimeCallInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(LoadCodeUnitsInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(LoadIndexedInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(LoadIndexedUnsafeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(LoadLocalInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(MathMinMaxInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(MoveArgumentInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(OneByteStringFromCharCodeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(SimdOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(SmiToDoubleInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(StoreIndexedInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(StoreIndexedUnsafeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(StoreLocalInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(StoreStaticFieldInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(StringToCharCodeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(TailCallInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(TruncDivModInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnaryDoubleOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnaryInt64OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnarySmiOpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxInteger32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxLaneInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxedConstantInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(Utf8ScanInstr)

LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone*,
                                                            bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

LocationSummary* CheckClassInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

void CheckClassInstr::EmitNullCheck(FlowGraphCompiler*, compiler::Label*) {
  UNIMPLEMENTED();
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler*,
                                  intptr_t,
                                  intptr_t,
                                  intptr_t,
                                  compiler::Label*) {
  UNIMPLEMENTED();
}

int CheckClassInstr::EmitCheckCid(FlowGraphCompiler*,
                                  int bias,
                                  intptr_t,
                                  intptr_t,
                                  bool,
                                  compiler::Label*,
                                  compiler::Label*,
                                  bool) {
  UNIMPLEMENTED();
  return bias;
}

void CheckNullInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

Condition DoubleTestOpInstr::EmitConditionCode(FlowGraphCompiler*,
                                               BranchLabels) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone*,
                                                           bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

Condition EqualityCompareInstr::EmitConditionCode(FlowGraphCompiler*,
                                                  BranchLabels) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

Condition RelationalOpInstr::EmitConditionCode(FlowGraphCompiler*,
                                               BranchLabels) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

LocationSummary* TestCidsInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

Condition TestCidsInstr::EmitConditionCode(FlowGraphCompiler*, BranchLabels) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

LocationSummary* TestIntInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

Condition TestIntInstr::EmitConditionCode(FlowGraphCompiler*, BranchLabels) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

void ConditionInstr::EmitNativeCode(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void ConditionInstr::EmitBranchCode(FlowGraphCompiler*, BranchInstr*) {
  UNIMPLEMENTED();
}

Condition StrictCompareInstr::EmitComparisonCodeRegConstant(
    FlowGraphCompiler*,
    BranchLabels,
    Register,
    const Object&) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

void MemoryCopyInstr::PrepareLengthRegForLoop(FlowGraphCompiler*,
                                              Register,
                                              compiler::Label*) {
  UNIMPLEMENTED();
}

void MemoryCopyInstr::EmitLoopCopy(FlowGraphCompiler*,
                                   Register,
                                   Register,
                                   Register,
                                   compiler::Label*,
                                   compiler::Label*) {
  UNIMPLEMENTED();
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler*,
                                              classid_t,
                                              Register,
                                              Register,
                                              Representation,
                                              Location) {
  UNIMPLEMENTED();
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone*, bool) const {
  UNIMPLEMENTED();
  return nullptr;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void UnboxInstr::EmitLoadInt32FromBoxOrSmi(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

void UnboxInstr::EmitSmiConversion(FlowGraphCompiler*) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
