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
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);

LocationSummary* Instruction::MakeCallSummary() {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ClosureCallInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* LoadLocalInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreLocalInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ConstantInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  UNIMPLEMENTED();
  return NULL;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


intptr_t LoadIndexedInstr::ResultCid() const {
  UNIMPLEMENTED();
  return kDynamicCid;
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
  UNIMPLEMENTED();
  return NULL;
}


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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

