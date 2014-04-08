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

LocationSummary* Instruction::MakeCallSummary() {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReturnInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  UNIMPLEMENTED();
  return NULL;
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  UNIMPLEMENTED();
  return NULL;
}


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  UNIMPLEMENTED();
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
