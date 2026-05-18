// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/compiler/backend/flow_graph_compiler.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/parallel_move_resolver.h"
#include "vm/object.h"

namespace dart {

void FlowGraphCompiler::ArchSpecificInitialization() {}

FlowGraphCompiler::~FlowGraphCompiler() {
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}

bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
}

bool FlowGraphCompiler::CanConvertInt64ToDouble() {
  return true;
}

void FlowGraphCompiler::EnterIntrinsicMode() {
  ASSERT(!intrinsic_mode());
  intrinsic_mode_ = true;
  ASSERT(!assembler()->constant_pool_allowed());
}

void FlowGraphCompiler::ExitIntrinsicMode() {
  ASSERT(intrinsic_mode());
  intrinsic_mode_ = false;
}

TypedDataPtr CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler*,
                                                DeoptInfoBuilder*,
                                                const Array&) {
  UNIMPLEMENTED();
  return TypedData::null();
}

void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler*, intptr_t) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::GenerateIndirectTTSCall(compiler::Assembler*,
                                                Register,
                                                intptr_t) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitPrologue() {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitCallToStub(
    const Code&,
    ObjectPool::SnapshotBehavior) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::GenerateStaticDartCall(
    intptr_t,
    const InstructionSource&,
    UntaggedPcDescriptors::Kind,
    LocationSummary*,
    const Function&,
    Code::EntryKind) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitEdgeCounter(intptr_t) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitOptimizedInstanceCall(const Code&,
                                                  const ICData&,
                                                  intptr_t,
                                                  const InstructionSource&,
                                                  LocationSummary*,
                                                  Code::EntryKind) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitInstanceCallJIT(const Code&,
                                            const ICData&,
                                            intptr_t,
                                            const InstructionSource&,
                                            LocationSummary*,
                                            Code::EntryKind) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitMegamorphicInstanceCall(const String&,
                                                    const Array&,
                                                    intptr_t,
                                                    const InstructionSource&,
                                                    LocationSummary*) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitInstanceCallAOT(const ICData&,
                                            intptr_t,
                                            const InstructionSource&,
                                            LocationSummary*,
                                            Code::EntryKind,
                                            bool) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitUnoptimizedStaticCall(intptr_t,
                                                  intptr_t,
                                                  const InstructionSource&,
                                                  LocationSummary*,
                                                  const ICData&,
                                                  Code::EntryKind) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitOptimizedStaticCall(const Function&,
                                                const Array&,
                                                intptr_t,
                                                intptr_t,
                                                const InstructionSource&,
                                                LocationSummary*,
                                                Code::EntryKind) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitDispatchTableCall(int32_t, const Array&) {
  UNIMPLEMENTED();
}

Condition FlowGraphCompiler::EmitEqualityRegRegCompare(
    Register,
    Register,
    bool,
    const InstructionSource&,
    intptr_t) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

Condition FlowGraphCompiler::EmitEqualityRegConstCompare(
    Register,
    const Object&,
    bool,
    const InstructionSource&,
    intptr_t) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

Condition FlowGraphCompiler::EmitBoolTest(Register, BranchLabels, bool) {
  UNIMPLEMENTED();
  return kInvalidCondition;
}

void FlowGraphCompiler::SaveLiveRegisters(LocationSummary*) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary*) {
  UNIMPLEMENTED();
}

#if defined(DEBUG)
void FlowGraphCompiler::ClobberDeadTempRegisters(LocationSummary*) {
  UNIMPLEMENTED();
}
#endif

Register FlowGraphCompiler::EmitTestCidRegister() {
  UNIMPLEMENTED();
  return kNoRegister;
}

void FlowGraphCompiler::EmitTestAndCallLoadReceiver(intptr_t, const Array&) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitTestAndCallSmiBranch(compiler::Label*, bool) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitTestAndCallLoadCid(Register) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitMove(Location,
                                 Location,
                                 TemporaryRegisterAllocator*) {
  UNIMPLEMENTED();
}

void FlowGraphCompiler::EmitNativeMoveArchitecture(
    const compiler::ffi::NativeLocation&,
    const compiler::ffi::NativeLocation&) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::EmitSwap(const MoveOperands&) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::MoveMemoryToMemory(const compiler::Address&,
                                             const compiler::Address&) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::Exchange(Register, const compiler::Address&) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::Exchange(const compiler::Address&,
                                   const compiler::Address&) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::Exchange(Register, Register, intptr_t) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::Exchange(Register,
                                   intptr_t,
                                   Register,
                                   intptr_t) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::SpillScratch(Register) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::RestoreScratch(Register) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::SpillFpuScratch(FpuRegister) {
  UNIMPLEMENTED();
}

void ParallelMoveEmitter::RestoreFpuScratch(FpuRegister) {
  UNIMPLEMENTED();
}

namespace compiler {

LeafRuntimeScope::LeafRuntimeScope(Assembler* assembler,
                                   intptr_t,
                                   bool preserve_registers)
    : assembler_(assembler), preserve_registers_(preserve_registers) {}

LeafRuntimeScope::~LeafRuntimeScope() {}

void LeafRuntimeScope::Call(const RuntimeEntry&, intptr_t) {}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
