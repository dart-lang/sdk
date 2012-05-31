// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"

#define __ compiler->assembler()->

namespace dart {


void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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


void CurrentContextComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreContextComp::MakeLocationSummary() const {
  return NULL;
}


void StoreContextComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StrictCompareComp::MakeLocationSummary() const {
  return NULL;
}


void StrictCompareComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* ClosureCallComp::MakeLocationSummary() const {
  return NULL;
}


void ClosureCallComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceCallComp::MakeLocationSummary() const {
  return NULL;
}


void InstanceCallComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StaticCallComp::MakeLocationSummary() const {
  return NULL;
}


void StaticCallComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* LoadLocalComp::MakeLocationSummary() const {
  return NULL;
}


void LoadLocalComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreLocalComp::MakeLocationSummary() const {
  return NULL;
}


void StoreLocalComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* ConstantVal::MakeLocationSummary() const {
  return NULL;
}


void ConstantVal::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* UseVal::MakeLocationSummary() const {
  return NULL;
}


void UseVal::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* AssertAssignableComp::MakeLocationSummary() const {
  return NULL;
}


void AssertAssignableComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* AssertBooleanComp::MakeLocationSummary() const {
  return NULL;
}


void AssertBooleanComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareComp::MakeLocationSummary() const {
  return NULL;
}


void EqualityCompareComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* NativeCallComp::MakeLocationSummary() const {
  return NULL;
}


void NativeCallComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreIndexedComp::MakeLocationSummary() const {
  return NULL;
}


void StoreIndexedComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceSetterComp::MakeLocationSummary() const {
  return NULL;
}


void InstanceSetterComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StaticSetterComp::MakeLocationSummary() const {
  return NULL;
}


void StaticSetterComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* LoadInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateComp::MakeLocationSummary() const {
  return NULL;
}


void BooleanNegateComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfComp::MakeLocationSummary() const {
  return NULL;
}


void InstanceOfComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* CreateArrayComp::MakeLocationSummary() const {
  return NULL;
}


void CreateArrayComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* CreateClosureComp::MakeLocationSummary() const {
  return NULL;
}


void CreateClosureComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateObjectComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateObjectComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary*
AllocateObjectWithBoundsCheckComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateObjectWithBoundsCheckComp::EmitNativeCode(
    FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* LoadVMFieldComp::MakeLocationSummary() const {
  return NULL;
}


void LoadVMFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* StoreVMFieldComp::MakeLocationSummary() const {
  return NULL;
}


void StoreVMFieldComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeArgumentsComp::MakeLocationSummary() const {
  return NULL;
}


void InstantiateTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorTypeArgumentsComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorInstantiatorComp::MakeLocationSummary() const {
  return NULL;
}


void ExtractConstructorInstantiatorComp::EmitNativeCode(
    FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextComp::MakeLocationSummary() const {
  return NULL;
}


void AllocateContextComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* ChainContextComp::MakeLocationSummary() const {
  return NULL;
}


void ChainContextComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* CloneContextComp::MakeLocationSummary() const {
  return NULL;
}


void CloneContextComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* CatchEntryComp::MakeLocationSummary() const {
  return NULL;
}


void CatchEntryComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryOpComp::MakeLocationSummary() const {
  return NULL;
}


void BinaryOpComp::EmitNativeCode(FlowGraphCompiler* compile) {
  UNIMPLEMENTED();
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
