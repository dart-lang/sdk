// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/type_testing_stubs.h"

#define __ (compiler->assembler())->
#define Z (compiler->zone())

namespace dart {

LocationSummary* Instruction::MakeCallSummary(Zone* zone,
                                              const Instruction* instr,
                                              LocationSummary* locs) {
  ASSERT(locs == nullptr || locs->always_calls());
  LocationSummary* result =
      ((locs == nullptr)
           ? (new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall))
           : locs);
  switch (instr->representation()) {
    case kTagged:
    case kUntagged:
    case kUnboxedUint32:
    case kUnboxedInt32:
    case kUnboxedInt64:
      result->set_out(
          0, Location::RegisterLocation(CallingConventions::kReturnReg));
      break;
    case kPairOfTagged:
      result->set_out(
          0, Location::Pair(
                 Location::RegisterLocation(CallingConventions::kReturnReg),
                 Location::RegisterLocation(
                     CallingConventions::kSecondReturnReg)));
      break;
    case kUnboxedDouble:
      result->set_out(
          0, Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg));
      break;
    default:
      UNREACHABLE();
      break;
  }
  return result;
}

// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.

static constexpr intptr_t kSimdSlot0Offset = 0;
static constexpr intptr_t kSimdSlot1Offset = kSimd128Size;
static constexpr intptr_t kSimdSlot2Offset = 2 * kSimd128Size;
static constexpr intptr_t kSimdResultOffset = 3 * kSimd128Size;
static constexpr intptr_t kSimdScratchSize = 4 * kSimd128Size;

static Location RequiredSimdInputLocation(Representation representation) {
  switch (representation) {
    case kTagged:
    case kUnboxedInt32:
      return Location::RequiresRegister();
    case kUnboxedDouble:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return Location::RequiresFpuRegister();
    default:
      UNREACHABLE();
      return Location::NoLocation();
  }
}

static Location SimdOutputLocation(Representation representation) {
  switch (representation) {
    case kTagged:
    case kUnboxedInt32:
      return Location::RequiresRegister();
    case kUnboxedDouble:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return Location::RequiresFpuRegister();
    default:
      UNREACHABLE();
      return Location::NoLocation();
  }
}

LocationSummary* SimdOpInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = InputCount();
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  for (intptr_t i = 0; i < kNumInputs; i++) {
    locs->set_in(i, RequiredSimdInputLocation(RequiredInputRepresentation(i)));
  }
  locs->set_out(0, SimdOutputLocation(representation()));
  return locs;
}

static void ReserveSimdScratch(FlowGraphCompiler* compiler) {
  __ AddImmediate(SP, SP, -kSimdScratchSize);
}

static void ReleaseSimdScratch(FlowGraphCompiler* compiler) {
  __ AddImmediate(SP, SP, kSimdScratchSize);
}

static compiler::Address SimdSlot(intptr_t offset) {
  return compiler::Address(SP, offset);
}

static intptr_t SimdLane32Offset(intptr_t base, intptr_t lane) {
  ASSERT((0 <= lane) && (lane < 4));
  return base + (lane * kInt32Size);
}

static intptr_t SimdLane64Offset(intptr_t base, intptr_t lane) {
  ASSERT((0 <= lane) && (lane < 2));
  return base + (lane * kDoubleSize);
}

static void CopySimdSlot(FlowGraphCompiler* compiler,
                         intptr_t dst_offset,
                         intptr_t src_offset) {
  __ Load(TMP, SimdSlot(src_offset), compiler::kEightBytes);
  __ Store(TMP, SimdSlot(dst_offset), compiler::kEightBytes);
  __ Load(TMP, SimdSlot(src_offset + kWordSize), compiler::kEightBytes);
  __ Store(TMP, SimdSlot(dst_offset + kWordSize), compiler::kEightBytes);
}

static void ClearSimdSlot(FlowGraphCompiler* compiler, intptr_t offset) {
  __ Store(ZR, SimdSlot(offset), compiler::kEightBytes);
  __ Store(ZR, SimdSlot(offset + kWordSize), compiler::kEightBytes);
}

static void LoadSimdResult(FlowGraphCompiler* compiler, FpuRegister out) {
  __ LoadQ(out, SimdSlot(kSimdResultOffset));
}

static intptr_t Float32x4LaneFromKind(SimdOpInstr::Kind kind,
                                      SimdOpInstr::Kind first_kind) {
  const intptr_t lane = kind - first_kind;
  ASSERT((0 <= lane) && (lane < 4));
  return lane;
}

static intptr_t Float64x2LaneFromKind(SimdOpInstr::Kind kind,
                                      SimdOpInstr::Kind first_kind) {
  const intptr_t lane = kind - first_kind;
  ASSERT((0 <= lane) && (lane < 2));
  return lane;
}

static void StoreBoolMask(FlowGraphCompiler* compiler,
                          Register flag,
                          intptr_t dst_offset) {
  compiler::Label store;
  __ LoadImmediate(TMP, 0);
  __ CompareObject(flag, Bool::True());
  __ BranchIf(NE, &store, compiler::Assembler::kNearJump);
  __ LoadImmediate(TMP, -1);
  __ Bind(&store);
  __ Store(TMP, SimdSlot(dst_offset), compiler::kFourBytes);
}

static void LoadBoolFromMask(FlowGraphCompiler* compiler,
                             Register out,
                             intptr_t src_offset) {
  compiler::Label is_true, done;
  __ Load(TMP, SimdSlot(src_offset), compiler::kFourBytes);
  __ CompareImmediate(TMP, 0);
  __ BranchIf(NE, &is_true, compiler::Assembler::kNearJump);
  __ LoadObject(out, Bool::False());
  __ b(&done, compiler::Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(out, Bool::True());
  __ Bind(&done);
}

static void EmitFloat32x4BinaryOp(FlowGraphCompiler* compiler,
                                  SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister left = instr->locs()->in(0).fpu_reg();
  const FpuRegister right = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(left, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(right, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)));
    __ LoadS(FpuTMP, SimdSlot(SimdLane32Offset(kSimdSlot1Offset, lane)));
    switch (instr->kind()) {
      case SimdOpInstr::kFloat32x4Add:
        __ fadd_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Sub:
        __ fsub_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Mul:
        __ fmul_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Div:
        __ fdiv_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Min:
        __ fmin_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Max:
        __ fmax_s(out, out, FpuTMP);
        __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
        break;
      case SimdOpInstr::kFloat32x4Equal:
        __ fcmp_ceq_s(out, FpuTMP);
        __ movcf2gr(TMP);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      case SimdOpInstr::kFloat32x4NotEqual:
        __ fcmp_ceq_s(out, FpuTMP);
        __ movcf2gr(TMP);
        __ xori(TMP, TMP, 1);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      case SimdOpInstr::kFloat32x4LessThan:
        __ fcmp_clt_s(out, FpuTMP);
        __ movcf2gr(TMP);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      case SimdOpInstr::kFloat32x4LessThanOrEqual:
        __ fcmp_cle_s(out, FpuTMP);
        __ movcf2gr(TMP);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      case SimdOpInstr::kFloat32x4GreaterThan:
        __ fcmp_clt_s(FpuTMP, out);
        __ movcf2gr(TMP);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      case SimdOpInstr::kFloat32x4GreaterThanOrEqual:
        __ fcmp_cle_s(FpuTMP, out);
        __ movcf2gr(TMP);
        __ sub_d(TMP, ZR, TMP);
        __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
                 compiler::kFourBytes);
        break;
      default:
        UNREACHABLE();
    }
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2BinaryOp(FlowGraphCompiler* compiler,
                                  SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister left = instr->locs()->in(0).fpu_reg();
  const FpuRegister right = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(left, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(right, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
    __ LoadD(FpuTMP, SimdSlot(SimdLane64Offset(kSimdSlot1Offset, lane)));
    switch (instr->kind()) {
      case SimdOpInstr::kFloat64x2Add:
        __ fadd_d(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat64x2Sub:
        __ fsub_d(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat64x2Mul:
        __ fmul_d(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat64x2Div:
        __ fdiv_d(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat64x2Min:
        __ fmin_d(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat64x2Max:
        __ fmax_d(out, out, FpuTMP);
        break;
      default:
        UNREACHABLE();
    }
    __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4BinaryOp(FlowGraphCompiler* compiler,
                                SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister left = instr->locs()->in(0).fpu_reg();
  const FpuRegister right = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(left, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(right, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ Load(TMP, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)),
            compiler::kFourBytes);
    __ Load(TMP2, SimdSlot(SimdLane32Offset(kSimdSlot1Offset, lane)),
            compiler::kFourBytes);
    switch (instr->kind()) {
      case SimdOpInstr::kInt32x4Add:
        __ add_d(TMP, TMP, TMP2);
        break;
      case SimdOpInstr::kInt32x4Sub:
        __ sub_d(TMP, TMP, TMP2);
        break;
      case SimdOpInstr::kInt32x4BitAnd:
        __ and_(TMP, TMP, TMP2);
        break;
      case SimdOpInstr::kInt32x4BitOr:
        __ or_(TMP, TMP, TMP2);
        break;
      case SimdOpInstr::kInt32x4BitXor:
        __ xor_(TMP, TMP, TMP2);
        break;
      default:
        UNREACHABLE();
    }
    __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4UnaryOp(FlowGraphCompiler* compiler,
                                 SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)));
    switch (instr->kind()) {
      case SimdOpInstr::kFloat32x4Sqrt:
        __ fsqrt_s(out, out);
        break;
      case SimdOpInstr::kFloat32x4Negate:
        __ fneg_s(out, out);
        break;
      case SimdOpInstr::kFloat32x4Abs:
        __ fabs_s(out, out);
        break;
      case SimdOpInstr::kFloat32x4Reciprocal:
        __ fmov_s(FpuTMP, out);
        __ LoadSImmediate(out, 1.0f);
        __ fdiv_s(out, out, FpuTMP);
        break;
      case SimdOpInstr::kFloat32x4ReciprocalSqrt:
        __ fsqrt_s(FpuTMP, out);
        __ LoadSImmediate(out, 1.0f);
        __ fdiv_s(out, out, FpuTMP);
        break;
      default:
        UNREACHABLE();
    }
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2UnaryOp(FlowGraphCompiler* compiler,
                                 SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
    switch (instr->kind()) {
      case SimdOpInstr::kFloat64x2Sqrt:
        __ fsqrt_d(out, out);
        break;
      case SimdOpInstr::kFloat64x2Negate:
        __ fneg_d(out, out);
        break;
      case SimdOpInstr::kFloat64x2Abs:
        __ fabs_d(out, out);
        break;
      default:
        UNREACHABLE();
    }
    __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4GetLane(FlowGraphCompiler* compiler,
                                 SimdOpInstr* instr) {
  const intptr_t lane =
      Float32x4LaneFromKind(instr->kind(), SimdOpInstr::kFloat32x4GetX);
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)));
  __ fcvt_d_s(out, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2GetLane(FlowGraphCompiler* compiler,
                                 SimdOpInstr* instr) {
  const intptr_t lane =
      Float64x2LaneFromKind(instr->kind(), SimdOpInstr::kFloat64x2GetX);
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4WithLane(FlowGraphCompiler* compiler,
                                  SimdOpInstr* instr) {
  const intptr_t lane =
      Float32x4LaneFromKind(instr->kind(), SimdOpInstr::kFloat32x4WithX);
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister replacement = instr->locs()->in(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreD(replacement, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(value, SimdSlot(kSimdSlot1Offset));
  CopySimdSlot(compiler, kSimdResultOffset, kSimdSlot1Offset);
  __ LoadD(out, SimdSlot(kSimdSlot0Offset));
  __ fcvt_s_d(out, out);
  __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2WithLane(FlowGraphCompiler* compiler,
                                  SimdOpInstr* instr) {
  const intptr_t lane =
      Float64x2LaneFromKind(instr->kind(), SimdOpInstr::kFloat64x2WithX);
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();
  const FpuRegister replacement = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  __ StoreD(replacement, SimdSlot(kSimdSlot1Offset));
  CopySimdSlot(compiler, kSimdResultOffset, kSimdSlot0Offset);
  __ LoadD(out, SimdSlot(kSimdSlot1Offset));
  __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4GetFlag(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const intptr_t lane =
      Float32x4LaneFromKind(instr->kind(), SimdOpInstr::kInt32x4GetFlagX);
  const Register out = instr->locs()->out(0).reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  LoadBoolFromMask(compiler, out, SimdLane32Offset(kSimdSlot0Offset, lane));
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4WithFlag(FlowGraphCompiler* compiler,
                                SimdOpInstr* instr) {
  const intptr_t lane =
      Float32x4LaneFromKind(instr->kind(), SimdOpInstr::kInt32x4WithFlagX);
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();
  const Register replacement = instr->locs()->in(1).reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  CopySimdSlot(compiler, kSimdResultOffset, kSimdSlot0Offset);
  StoreBoolMask(compiler, replacement,
                SimdLane32Offset(kSimdResultOffset, lane));
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitSimdShuffle(FlowGraphCompiler* compiler, SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();
  const intptr_t mask = instr->mask();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    const intptr_t src_lane = (mask >> (2 * lane)) & 0x3;
    __ Load(TMP, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, src_lane)),
            compiler::kFourBytes);
    __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitSimdShuffleMix(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister left = instr->locs()->in(0).fpu_reg();
  const FpuRegister right = instr->locs()->in(1).fpu_reg();
  const intptr_t mask = instr->mask();

  ReserveSimdScratch(compiler);
  __ StoreQ(left, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(right, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    const bool use_right = lane >= 2;
    const intptr_t src_base = use_right ? kSimdSlot1Offset : kSimdSlot0Offset;
    const intptr_t src_lane = (mask >> (2 * lane)) & 0x3;
    __ Load(TMP, SimdSlot(SimdLane32Offset(src_base, src_lane)),
            compiler::kFourBytes);
    __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4FromDoubles(FlowGraphCompiler* compiler,
                                     SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ StoreD(instr->locs()->in(lane).fpu_reg(),
              SimdSlot(kSimdSlot0Offset + (lane * kDoubleSize)));
  }
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadD(out, SimdSlot(kSimdSlot0Offset + (lane * kDoubleSize)));
    __ fcvt_s_d(out, out);
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2FromDoubles(FlowGraphCompiler* compiler,
                                     SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreD(instr->locs()->in(0).fpu_reg(), SimdSlot(kSimdResultOffset));
  __ StoreD(instr->locs()->in(1).fpu_reg(),
            SimdSlot(kSimdResultOffset + kDoubleSize));
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4FromInts(FlowGraphCompiler* compiler,
                                SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ Store(instr->locs()->in(lane).reg(),
             SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4FromBools(FlowGraphCompiler* compiler,
                                 SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  for (intptr_t lane = 0; lane < 4; lane++) {
    StoreBoolMask(compiler, instr->locs()->in(lane).reg(),
                  SimdLane32Offset(kSimdResultOffset, lane));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4Zero(FlowGraphCompiler* compiler, SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  ClearSimdSlot(compiler, kSimdResultOffset);
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2Zero(FlowGraphCompiler* compiler, SimdOpInstr* instr) {
  EmitFloat32x4Zero(compiler, instr);
}

static void EmitFloat32x4Splat(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreD(value, SimdSlot(kSimdSlot0Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadD(out, SimdSlot(kSimdSlot0Offset));
    __ fcvt_s_d(out, out);
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2Splat(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreD(value, SimdSlot(kSimdSlot0Offset));
  __ LoadD(out, SimdSlot(kSimdSlot0Offset));
  __ StoreD(out, SimdSlot(kSimdResultOffset));
  __ StoreD(out, SimdSlot(kSimdResultOffset + kDoubleSize));
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitSimdGetSignMask(FlowGraphCompiler* compiler,
                                SimdOpInstr* instr) {
  const Register out = instr->locs()->out(0).reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();
  const bool is_float64x2 =
      instr->kind() == SimdOpInstr::kFloat64x2GetSignMask;
  const intptr_t lane_count = is_float64x2 ? 2 : 4;

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  __ LoadImmediate(out, 0);
  for (intptr_t lane = 0; lane < lane_count; lane++) {
    if (is_float64x2) {
      __ Load(TMP, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)),
              compiler::kEightBytes);
    } else {
      __ Load(TMP, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)),
              compiler::kFourBytes);
    }
    __ srai_d(TMP, TMP, XLEN - 1);
    __ andi(TMP, TMP, 1);
    if (lane != 0) {
      __ slli_d(TMP, TMP, lane);
    }
    __ or_(out, out, TMP);
  }
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4Scale(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister scale = instr->locs()->in(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreD(scale, SimdSlot(kSimdSlot0Offset));
  __ StoreQ(value, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot1Offset, lane)));
    __ LoadD(FpuTMP, SimdSlot(kSimdSlot0Offset));
    __ fcvt_s_d(FpuTMP, FpuTMP);
    __ fmul_s(out, out, FpuTMP);
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2Scale(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();
  const FpuRegister scale = instr->locs()->in(1).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  __ StoreD(scale, SimdSlot(kSimdSlot1Offset));
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
    __ LoadD(FpuTMP, SimdSlot(kSimdSlot1Offset));
    __ fmul_d(out, out, FpuTMP);
    __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4Clamp(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(instr->locs()->in(0).fpu_reg(), SimdSlot(kSimdSlot0Offset));
  __ StoreQ(instr->locs()->in(1).fpu_reg(), SimdSlot(kSimdSlot1Offset));
  __ StoreQ(instr->locs()->in(2).fpu_reg(), SimdSlot(kSimdSlot2Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)));
    __ LoadS(FpuTMP, SimdSlot(SimdLane32Offset(kSimdSlot1Offset, lane)));
    __ fmax_s(out, out, FpuTMP);
    __ LoadS(FpuTMP, SimdSlot(SimdLane32Offset(kSimdSlot2Offset, lane)));
    __ fmin_s(out, out, FpuTMP);
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2Clamp(FlowGraphCompiler* compiler,
                               SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(instr->locs()->in(0).fpu_reg(), SimdSlot(kSimdSlot0Offset));
  __ StoreQ(instr->locs()->in(1).fpu_reg(), SimdSlot(kSimdSlot1Offset));
  __ StoreQ(instr->locs()->in(2).fpu_reg(), SimdSlot(kSimdSlot2Offset));
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
    __ LoadD(FpuTMP, SimdSlot(SimdLane64Offset(kSimdSlot1Offset, lane)));
    __ fmax_d(out, out, FpuTMP);
    __ LoadD(FpuTMP, SimdSlot(SimdLane64Offset(kSimdSlot2Offset, lane)));
    __ fmin_d(out, out, FpuTMP);
    __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitInt32x4Select(FlowGraphCompiler* compiler,
                              SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(instr->locs()->in(0).fpu_reg(), SimdSlot(kSimdSlot0Offset));
  __ StoreQ(instr->locs()->in(1).fpu_reg(), SimdSlot(kSimdSlot1Offset));
  __ StoreQ(instr->locs()->in(2).fpu_reg(), SimdSlot(kSimdSlot2Offset));
  for (intptr_t lane = 0; lane < 4; lane++) {
    __ Load(TMP, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)),
            compiler::kFourBytes);
    __ Load(TMP2, SimdSlot(SimdLane32Offset(kSimdSlot1Offset, lane)),
            compiler::kFourBytes);
    __ and_(TMP2, TMP2, TMP);
    __ Store(TMP2, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
    __ LoadImmediate(TMP2, -1);
    __ xor_(TMP, TMP, TMP2);
    __ Load(TMP2, SimdSlot(SimdLane32Offset(kSimdSlot2Offset, lane)),
            compiler::kFourBytes);
    __ and_(TMP, TMP, TMP2);
    __ Load(TMP2, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
            compiler::kFourBytes);
    __ or_(TMP, TMP, TMP2);
    __ Store(TMP, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)),
             compiler::kFourBytes);
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat32x4ToFloat64x2(FlowGraphCompiler* compiler,
                                     SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadS(out, SimdSlot(SimdLane32Offset(kSimdSlot0Offset, lane)));
    __ fcvt_d_s(out, out);
    __ StoreD(out, SimdSlot(SimdLane64Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

static void EmitFloat64x2ToFloat32x4(FlowGraphCompiler* compiler,
                                     SimdOpInstr* instr) {
  const FpuRegister out = instr->locs()->out(0).fpu_reg();
  const FpuRegister value = instr->locs()->in(0).fpu_reg();

  ReserveSimdScratch(compiler);
  __ StoreQ(value, SimdSlot(kSimdSlot0Offset));
  ClearSimdSlot(compiler, kSimdResultOffset);
  for (intptr_t lane = 0; lane < 2; lane++) {
    __ LoadD(out, SimdSlot(SimdLane64Offset(kSimdSlot0Offset, lane)));
    __ fcvt_s_d(out, out);
    __ StoreS(out, SimdSlot(SimdLane32Offset(kSimdResultOffset, lane)));
  }
  LoadSimdResult(compiler, out);
  ReleaseSimdScratch(compiler);
}

void SimdOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  switch (kind()) {
    case SimdOpInstr::kFloat32x4Add:
    case SimdOpInstr::kFloat32x4Sub:
    case SimdOpInstr::kFloat32x4Mul:
    case SimdOpInstr::kFloat32x4Div:
    case SimdOpInstr::kFloat32x4Min:
    case SimdOpInstr::kFloat32x4Max:
    case SimdOpInstr::kFloat32x4Equal:
    case SimdOpInstr::kFloat32x4NotEqual:
    case SimdOpInstr::kFloat32x4LessThan:
    case SimdOpInstr::kFloat32x4LessThanOrEqual:
    case SimdOpInstr::kFloat32x4GreaterThan:
    case SimdOpInstr::kFloat32x4GreaterThanOrEqual:
      EmitFloat32x4BinaryOp(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Add:
    case SimdOpInstr::kFloat64x2Sub:
    case SimdOpInstr::kFloat64x2Mul:
    case SimdOpInstr::kFloat64x2Div:
    case SimdOpInstr::kFloat64x2Min:
    case SimdOpInstr::kFloat64x2Max:
      EmitFloat64x2BinaryOp(compiler, this);
      break;
    case SimdOpInstr::kInt32x4Add:
    case SimdOpInstr::kInt32x4Sub:
    case SimdOpInstr::kInt32x4BitAnd:
    case SimdOpInstr::kInt32x4BitOr:
    case SimdOpInstr::kInt32x4BitXor:
      EmitInt32x4BinaryOp(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Sqrt:
    case SimdOpInstr::kFloat32x4Negate:
    case SimdOpInstr::kFloat32x4Abs:
    case SimdOpInstr::kFloat32x4Reciprocal:
    case SimdOpInstr::kFloat32x4ReciprocalSqrt:
      EmitFloat32x4UnaryOp(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Sqrt:
    case SimdOpInstr::kFloat64x2Negate:
    case SimdOpInstr::kFloat64x2Abs:
      EmitFloat64x2UnaryOp(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4GetX:
    case SimdOpInstr::kFloat32x4GetY:
    case SimdOpInstr::kFloat32x4GetZ:
    case SimdOpInstr::kFloat32x4GetW:
      EmitFloat32x4GetLane(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2GetX:
    case SimdOpInstr::kFloat64x2GetY:
      EmitFloat64x2GetLane(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4WithX:
    case SimdOpInstr::kFloat32x4WithY:
    case SimdOpInstr::kFloat32x4WithZ:
    case SimdOpInstr::kFloat32x4WithW:
      EmitFloat32x4WithLane(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2WithX:
    case SimdOpInstr::kFloat64x2WithY:
      EmitFloat64x2WithLane(compiler, this);
      break;
    case SimdOpInstr::kInt32x4GetFlagX:
    case SimdOpInstr::kInt32x4GetFlagY:
    case SimdOpInstr::kInt32x4GetFlagZ:
    case SimdOpInstr::kInt32x4GetFlagW:
      EmitInt32x4GetFlag(compiler, this);
      break;
    case SimdOpInstr::kInt32x4WithFlagX:
    case SimdOpInstr::kInt32x4WithFlagY:
    case SimdOpInstr::kInt32x4WithFlagZ:
    case SimdOpInstr::kInt32x4WithFlagW:
      EmitInt32x4WithFlag(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Shuffle:
    case SimdOpInstr::kInt32x4Shuffle:
      EmitSimdShuffle(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4ShuffleMix:
    case SimdOpInstr::kInt32x4ShuffleMix:
      EmitSimdShuffleMix(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4FromDoubles:
      EmitFloat32x4FromDoubles(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2FromDoubles:
      EmitFloat64x2FromDoubles(compiler, this);
      break;
    case SimdOpInstr::kInt32x4FromInts:
      EmitInt32x4FromInts(compiler, this);
      break;
    case SimdOpInstr::kInt32x4FromBools:
      EmitInt32x4FromBools(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Zero:
      EmitFloat32x4Zero(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Zero:
      EmitFloat64x2Zero(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Splat:
      EmitFloat32x4Splat(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Splat:
      EmitFloat64x2Splat(compiler, this);
      break;
    case SimdOpInstr::kInt32x4GetSignMask:
    case SimdOpInstr::kFloat32x4GetSignMask:
    case SimdOpInstr::kFloat64x2GetSignMask:
      EmitSimdGetSignMask(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Scale:
      EmitFloat32x4Scale(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Scale:
      EmitFloat64x2Scale(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4Clamp:
      EmitFloat32x4Clamp(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2Clamp:
      EmitFloat64x2Clamp(compiler, this);
      break;
    case SimdOpInstr::kInt32x4Select:
      EmitInt32x4Select(compiler, this);
      break;
    case SimdOpInstr::kFloat32x4ToFloat64x2:
      EmitFloat32x4ToFloat64x2(compiler, this);
      break;
    case SimdOpInstr::kFloat64x2ToFloat32x4:
      EmitFloat64x2ToFloat32x4(compiler, this);
      break;
    case SimdOpInstr::kInt32x4ToFloat32x4:
    case SimdOpInstr::kFloat32x4ToInt32x4:
      __ MoveUnboxedSimd128(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
      break;
    case SimdOpInstr::kIllegalSimdOp:
      UNREACHABLE();
      break;
  }
}
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.
// Implemented below.

static intptr_t SignExtendedLo12(intptr_t value) {
  const intptr_t lo12 = static_cast<uintptr_t>(value) & 0xfff;
  return (lo12 & 0x800) != 0 ? lo12 - 0x1000 : lo12;
}

static intptr_t PcAddHi20(intptr_t value) {
  const intptr_t lo12 = SignExtendedLo12(value);
  ASSERT(Utils::IsAligned(value - lo12, 1 << 12));
  return (value - lo12) / (1 << 12);
}

LocationSummary* MoveArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  ConstantInstr* constant = value()->definition()->AsConstant();
  if ((constant != nullptr) && constant->HasZeroRepresentation()) {
    locs->set_in(0, Location::Constant(constant));
  } else if (representation() == kUnboxedDouble) {
    locs->set_in(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedInt64) {
    locs->set_in(0, Location::RequiresRegister());
  } else {
    ASSERT(representation() == kTagged);
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

void MoveArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());

  const Location value = locs()->in(0);
  const intptr_t offset =
      location().stack_index() * compiler::target::kWordSize;
  if (value.IsRegister()) {
    __ StoreToOffset(value.reg(), SP, offset);
  } else if (value.IsConstant()) {
    if ((representation() == kUnboxedDouble) ||
        (representation() == kUnboxedInt64)) {
      ASSERT(value.constant_instruction()->HasZeroRepresentation());
      __ StoreToOffset(ZR, SP, offset);
    } else {
      ASSERT(representation() == kTagged);
      const Object& constant = value.constant();
      Register reg;
      if (constant.IsNull()) {
        reg = NULL_REG;
      } else if (constant.IsSmi() && Smi::Cast(constant).Value() == 0) {
        reg = ZR;
      } else {
        reg = TMP;
        __ LoadObject(TMP, constant);
      }
      __ StoreToOffset(reg, SP, offset);
    }
  } else if (value.IsFpuRegister()) {
    __ StoreDToOffset(value.fpu_reg(), SP, offset);
  } else if (value.IsStackSlot()) {
    __ LoadFromOffset(TMP, value.base_reg(), value.ToStackSlotOffset());
    __ StoreToOffset(TMP, SP, offset);
  } else {
    UNREACHABLE();
  }
}

LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool) const {
  auto const dst_type_loc =
      LocationFixedRegisterOrConstant(dst_type(), TypeTestABI::kDstTypeReg);

  const intptr_t kNonChangeableInputRegs =
      (1 << TypeTestABI::kInstanceReg) |
      ((dst_type_loc.IsRegister() ? 1 : 0) << TypeTestABI::kDstTypeReg) |
      (1 << TypeTestABI::kInstantiatorTypeArgumentsReg) |
      (1 << TypeTestABI::kFunctionTypeArgumentsReg);

  const intptr_t kNumInputs = 4;
  const intptr_t kCpuRegistersToPreserve =
      kDartAvailableCpuRegs & ~kNonChangeableInputRegs;
  const intptr_t kFpuRegistersToPreserve =
      Utils::NBitMask<intptr_t>(kNumberOfFpuRegisters) & ~(1l << FpuTMP);
  const intptr_t kNumTemps = (Utils::CountOneBits32(kCpuRegistersToPreserve) +
                              Utils::CountOneBits64(kFpuRegistersToPreserve));

  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallCalleeSafe);
  summary->set_in(kInstancePos,
                  Location::RegisterLocation(TypeTestABI::kInstanceReg));
  summary->set_in(kDstTypePos, dst_type_loc);
  summary->set_in(
      kInstantiatorTAVPos,
      Location::RegisterLocation(TypeTestABI::kInstantiatorTypeArgumentsReg));
  summary->set_in(kFunctionTAVPos, Location::RegisterLocation(
                                       TypeTestABI::kFunctionTypeArgumentsReg));
  summary->set_out(0, Location::SameAsFirstInput());

  intptr_t next_temp = 0;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    const bool should_preserve = ((1 << i) & kCpuRegistersToPreserve) != 0;
    if (should_preserve) {
      summary->set_temp(next_temp++,
                        Location::RegisterLocation(static_cast<Register>(i)));
    }
  }

  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    const bool should_preserve = ((1l << i) & kFpuRegistersToPreserve) != 0;
    if (should_preserve) {
      summary->set_temp(next_temp++, Location::FpuRegisterLocation(
                                         static_cast<FpuRegister>(i)));
    }
  }

  return summary;
}

// Should be kept in sync with runtime/lib/integers.cc Multiply64Hash.
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register value,
                                        const Register result) {
  ASSERT(value != TMP);
  ASSERT(value != TMP2);
  ASSERT(result != TMP);
  ASSERT(result != TMP2);

  __ LoadImmediate(TMP, 0x2d51);
  __ mulh_du(TMP2, TMP, value);
  __ mul_d(result, TMP, value);
  __ xor_(result, result, TMP2);
  __ srli_d(TMP2, result, 32);
  __ xor_(result, result, TMP2);
  __ AndImmediate(result, result, 0x3fffffff);
}

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 2;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister value = locs()->in(0).fpu_reg();
  const Register int_value = locs()->temp(0).reg();
  const FRegister temp_double = locs()->temp(1).fpu_reg();
  const Register result = locs()->out(0).reg();

  compiler::Label hash_double, done;
  __ movfr2gr_d(TMP, value);
  __ AndImmediate(TMP, TMP, 0x7FF0000000000000LL);
  __ CompareImmediate(TMP, 0x7FF0000000000000LL);
  __ BranchIf(EQ, &hash_double);

  __ ftintrz_l_d(temp_double, value);
  __ movfr2gr_d(int_value, temp_double);
  __ ffint_d_l(temp_double, temp_double);
  __ fcmp_ceq_d(value, temp_double);
  __ movcf2gr(TMP);
  __ CompareImmediate(TMP, 0);
  __ BranchIf(EQ, &hash_double);

  EmitHashIntegerCodeSequence(compiler, int_value, result);
  __ b(&done);

  __ Bind(&hash_double);
  __ movfr2gr_d(result, value);
  __ srli_d(TMP, result, 32);
  __ xor_(result, result, TMP);
  __ AndImmediate(result, result, compiler::target::kSmiMax);

  __ Bind(&done);
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::WritableRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value = locs()->in(0).reg();

  if (smi_) {
    __ SmiUntag(value);
  } else {
    __ LoadFieldFromOffset(value, value, Mint::value_offset());
  }
  EmitHashIntegerCodeSequence(compiler, value, result);
  __ SmiTag(result);
}

LocationSummary* IntConverterInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUntagged || to() == kUntagged) {
    ASSERT((from() == kUntagged && to() == kUnboxedIntPtr) ||
           (from() == kUnboxedIntPtr && to() == kUntagged));
  } else if (from() == kUnboxedInt64) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
  } else if (to() == kUnboxedInt64) {
    ASSERT(from() == kUnboxedInt32 || from() == kUnboxedUint32);
  } else {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    ASSERT(from() == kUnboxedUint32 || from() == kUnboxedInt32);
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void IntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(from() != to());

  const bool is_nop_conversion =
      (from() == kUntagged && to() == kUnboxedIntPtr) ||
      (from() == kUnboxedIntPtr && to() == kUntagged);
  if (is_nop_conversion) {
    ASSERT(locs()->in(0).reg() == locs()->out(0).reg());
    return;
  }

  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    __ ExtendValue(out, value, compiler::kUnsignedFourBytes);
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    __ ExtendValue(out, value, compiler::kFourBytes);
  } else if (from() == kUnboxedInt64) {
    if (to() == kUnboxedInt32) {
      __ ExtendValue(out, value, compiler::kFourBytes);
    } else {
      ASSERT(to() == kUnboxedUint32);
      __ ExtendValue(out, value, compiler::kUnsignedFourBytes);
    }
  } else if (to() == kUnboxedInt64) {
    if (from() == kUnboxedUint32) {
      __ ExtendValue(out, value, compiler::kUnsignedFourBytes);
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ ExtendValue(out, value, compiler::kFourBytes);
    }
  } else {
    UNREACHABLE();
  }
}

LocationSummary* BitCastInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, InputCount(),
                                 /*temp_count=*/0, LocationSummary::kNoCall);
  switch (from()) {
    case kUnboxedInt32:
    case kUnboxedInt64:
      summary->set_in(0, Location::RequiresRegister());
      break;
    case kUnboxedFloat:
    case kUnboxedDouble:
      summary->set_in(0, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
  }

  switch (to()) {
    case kUnboxedInt32:
    case kUnboxedInt64:
      summary->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedFloat:
    case kUnboxedDouble:
      summary->set_out(0, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
  }
  return summary;
}

void BitCastInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  switch (from()) {
    case kUnboxedFloat: {
      switch (to()) {
        case kUnboxedInt32:
        case kUnboxedInt64:
          __ movfr2gr_s(locs()->out(0).reg(), locs()->in(0).fpu_reg());
          break;
        default:
          UNREACHABLE();
      }
      break;
    }
    case kUnboxedDouble:
      ASSERT(to() == kUnboxedInt64);
      __ movfr2gr_d(locs()->out(0).reg(), locs()->in(0).fpu_reg());
      break;
    case kUnboxedInt64: {
      switch (to()) {
        case kUnboxedDouble:
          __ movgr2fr_d(locs()->out(0).fpu_reg(), locs()->in(0).reg());
          break;
        case kUnboxedFloat:
          __ movgr2fr_w(locs()->out(0).fpu_reg(), locs()->in(0).reg());
          break;
        default:
          UNREACHABLE();
      }
      break;
    }
    case kUnboxedInt32:
      ASSERT(to() == kUnboxedFloat);
      __ movgr2fr_w(locs()->out(0).fpu_reg(), locs()->in(0).reg());
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, CanDeoptimize() ? Location::RequiresRegister()
                                      : Location::MayBeSameAsFirstInput());
  return summary;
}

void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kNEGATE: {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ sub_d(result, ZR, value);
      ASSERT(result != value);
      __ beq(result, value, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ XorImmediate(result, value, -1);
      __ AndImmediate(result, result, ~kSmiTagMask);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* CheckClassInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const bool need_mask_temp = IsBitTest();
  const intptr_t kNumTemps = !IsNullCheck() ? (need_mask_temp ? 2 : 1) : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->set_temp(0, Location::RequiresRegister());
    if (need_mask_temp) {
      summary->set_temp(1, Location::RequiresRegister());
    }
  }
  return summary;
}

void CheckClassInstr::EmitNullCheck(FlowGraphCompiler* compiler,
                                    compiler::Label* deopt) {
  if (IsDeoptIfNull()) {
    __ beq(locs()->in(0).reg(), NULL_REG, deopt);
  } else if (IsDeoptIfNotNull()) {
    __ bne(locs()->in(0).reg(), NULL_REG, deopt);
  } else {
    UNREACHABLE();
  }
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  compiler::Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ AddImmediate(biased_cid, -min);
  __ CompareImmediate(biased_cid, max - min);
  __ BranchIf(HI, deopt);

  Register bit_reg = locs()->temp(1).reg();
  __ LoadImmediate(bit_reg, 1);
  __ sll_d(bit_reg, bit_reg, biased_cid);
  __ TestImmediate(bit_reg, mask);
  __ BranchIf(EQ, deopt);
}

int CheckClassInstr::EmitCheckCid(FlowGraphCompiler* compiler,
                                  int bias,
                                  intptr_t cid_start,
                                  intptr_t cid_end,
                                  bool is_last,
                                  compiler::Label* is_ok,
                                  compiler::Label* deopt,
                                  bool use_near_jump) {
  Register biased_cid = locs()->temp(0).reg();
  Condition no_match, match;
  if (cid_start == cid_end) {
    __ CompareImmediate(biased_cid, cid_start - bias);
    no_match = NE;
    match = EQ;
  } else {
    __ AddImmediate(biased_cid, bias - cid_start);
    bias = cid_start;
    __ CompareImmediate(biased_cid, cid_end - cid_start);
    no_match = HI;
    match = LS;
  }
  if (is_last) {
    __ BranchIf(no_match, deopt);
  } else {
    __ BranchIf(match, is_ok);
  }
  return bias;
}

void CheckNullInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ThrowErrorSlowPathCode* slow_path = new NullErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register value_reg = locs()->in(0).reg();
  __ CompareObject(value_reg, Object::null_object());
  __ BranchIf(EQ, slow_path->entry_label());
}

LocationSummary* CheckClassIdInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, cids_.IsSingleCid() ? Location::RequiresRegister()
                                         : Location::WritableRegister());
  return summary;
}

void CheckClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  if (cids_.IsSingleCid()) {
    __ CompareImmediate(value, Smi::RawValue(cids_.cid_start));
    __ BranchIf(NE, deopt);
  } else {
    __ AddImmediate(value, value, -Smi::RawValue(cids_.cid_start));
    __ CompareImmediate(value, Smi::RawValue(cids_.cid_end - cids_.cid_start));
    __ BranchIf(HI, deopt);
  }
}

LocationSummary* CheckSmiInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}

void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi);
  __ BranchIfNotSmi(value, deopt);
}

LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, LocationRegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, LocationRegisterOrSmiConstant(index()));
  return locs;
}

void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  uint32_t flags = generalized_ ? ICData::kGeneralized : 0;
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckArrayBound, flags);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);

  const intptr_t index_cid = index()->Type()->ToCid();
  if (length_loc.IsConstant() && index_loc.IsConstant()) {
    if ((Smi::Cast(length_loc.constant()).Value() >
         Smi::Cast(index_loc.constant()).Value()) &&
        (Smi::Cast(index_loc.constant()).Value() >= 0)) {
      return;
    }
    ASSERT((Smi::Cast(length_loc.constant()).Value() <=
            Smi::Cast(index_loc.constant()).Value()) ||
           (Smi::Cast(index_loc.constant()).Value() < 0));
    __ j(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareObject(length, index);
    __ BranchIf(LS, deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ CompareImmediate(index, 0);
      __ BranchIf(LT, deopt);
    } else {
      __ CompareObject(index, length);
      __ BranchIf(CS, deopt);
    }
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ CompareObjectRegisters(index, length);
    __ BranchIf(CS, deopt);
  }
}

LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = (type_arguments() != nullptr) ? 1 : 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  if (type_arguments() != nullptr) {
    locs->set_in(kTypeArgumentsPos, Location::RegisterLocation(
                                        AllocateObjectABI::kTypeArgumentsReg));
  }
  locs->set_out(0, Location::RegisterLocation(AllocateObjectABI::kResultReg));
  return locs;
}

void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (type_arguments() != nullptr) {
    TypeUsageInfo* type_usage_info = compiler->thread()->type_usage_info();
    if (type_usage_info != nullptr) {
      RegisterTypeArgumentsUse(compiler->function(), type_usage_info, cls_,
                               type_arguments()->definition());
    }
  }
  const Code& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForClass(cls()));
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = nullptr) {
  compiler::Label done;
  if (value_is_smi == nullptr) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ BranchIfSmi(value_reg, value_is_smi == nullptr ? &done : value_is_smi,
                 compiler::Assembler::kNearJump);
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}

LocationSummary* CheckFieldImmutabilityInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(
      0, Location::RegisterLocation(EnsureDeeplyImmutableStubABI::kValueReg));
  summary->set_temp(
      0, Location::RegisterLocation(EnsureDeeplyImmutableStubABI::kTempReg));
  return summary;
}

void CheckFieldImmutabilityInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  auto slow_path = new EnsureDeeplyImmutableSlowPath(this, value);
  compiler->AddSlowPathCode(slow_path);

  __ BranchIfSmi(value, slow_path->exit_label(),
                 compiler::Assembler::kNearJump);
  __ LoadFieldFromOffset(temp, value, compiler::target::Object::tags_offset(),
                         compiler::kUnsignedByte);
  __ AndImmediate(
      temp, temp,
      1 << compiler::target::UntaggedObject::kDeeplyImmutableBit);
  __ BranchIfZero(temp, slow_path->entry_label());
  __ Bind(slow_path->exit_label());
}

LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t left_cid = left()->Type()->ToCid();
  const intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}

void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp);
  const intptr_t left_cid = left()->Type()->ToCid();
  const intptr_t right_cid = right()->Type()->ToCid();
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ BranchIfSmi(left, deopt);
  } else if (left_cid == kSmiCid) {
    __ BranchIfSmi(right, deopt);
  } else if (right_cid == kSmiCid) {
    __ BranchIfSmi(left, deopt);
  } else {
    __ or_(TMP, left, right);
    __ BranchIfSmi(TMP, deopt);
  }
}

LocationSummary* InstanceOfInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(TypeTestABI::kInstanceReg));
  summary->set_in(1, Location::RegisterLocation(
                         TypeTestABI::kInstantiatorTypeArgumentsReg));
  summary->set_in(
      2, Location::RegisterLocation(TypeTestABI::kFunctionTypeArgumentsReg));
  summary->set_out(
      0, Location::RegisterLocation(TypeTestABI::kInstanceOfResultReg));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == TypeTestABI::kInstanceReg);
  ASSERT(locs()->in(1).reg() == TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs()->in(2).reg() == TypeTestABI::kFunctionTypeArgumentsReg);

  compiler->GenerateInstanceOf(source(), deopt_id(), env(), type(), locs());
  ASSERT(locs()->out(0).reg() == TypeTestABI::kInstanceOfResultReg);
}

LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();

  const bool emit_full_guard = !opt || (field_cid == kIllegalCid);
  const bool needs_value_cid_temp_reg =
      emit_full_guard || ((value_cid == kDynamicCid) && (field_cid != kSmiCid));
  const bool needs_field_temp_reg = emit_full_guard;

  intptr_t num_temps = 0;
  if (needs_value_cid_temp_reg) {
    num_temps++;
  }
  if (needs_field_temp_reg) {
    num_temps++;
  }

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  for (intptr_t i = 0; i < num_temps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }
  return summary;
}

void GuardFieldClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler::target::UntaggedObject::kClassIdTagSize == 20);
  ASSERT(sizeof(UntaggedField::guarded_cid_) == 4);
  ASSERT(sizeof(UntaggedField::is_nullable_) == 4);

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    return;
  }

  const bool emit_full_guard =
      !compiler->is_optimizing() || (field_cid == kIllegalCid);
  const bool needs_value_cid_temp_reg =
      emit_full_guard || ((value_cid == kDynamicCid) && (field_cid != kSmiCid));
  const bool needs_field_temp_reg = emit_full_guard;

  const Register value_reg = locs()->in(0).reg();
  const Register value_cid_reg =
      needs_value_cid_temp_reg ? locs()->temp(0).reg() : kNoRegister;
  const Register field_reg = needs_field_temp_reg
                                 ? locs()->temp(locs()->temp_count() - 1).reg()
                                 : kNoRegister;

  compiler::Label ok, fail_label;
  compiler::Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : nullptr;
  compiler::Label* fail = (deopt != nullptr) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    const compiler::FieldAddress field_cid_operand(
        field_reg, Field::guarded_cid_offset());
    const compiler::FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ Load(TMP, field_cid_operand, compiler::kFourBytes);
      __ CompareRegisters(value_cid_reg, TMP);
      __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);
      __ Load(TMP, field_nullability_operand, compiler::kFourBytes);
      __ CompareRegisters(value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ Load(value_cid_reg, field_nullability_operand, compiler::kFourBytes);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      __ Load(value_cid_reg, field_cid_operand, compiler::kFourBytes);
      __ CompareImmediate(value_cid_reg, value_cid);
    }
    __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

    if (!field().needs_length_check()) {
      __ Load(TMP, field_cid_operand, compiler::kFourBytes);
      __ CompareImmediate(TMP, kIllegalCid);
      __ BranchIf(NE, fail);

      if (value_cid == kDynamicCid) {
        __ Store(value_cid_reg, field_cid_operand, compiler::kFourBytes);
        __ Store(value_cid_reg, field_nullability_operand,
                 compiler::kFourBytes);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ Store(TMP, field_cid_operand, compiler::kFourBytes);
        __ Store(TMP, field_nullability_operand, compiler::kFourBytes);
      }

      __ j(&ok, compiler::Assembler::kNearJump);
    }

    if (deopt == nullptr) {
      __ Bind(fail);

      __ LoadFieldFromOffset(TMP, field_reg, Field::guarded_cid_offset(),
                             compiler::kUnsignedTwoBytes);
      __ CompareImmediate(TMP, kDynamicCid);
      __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

      __ PushRegisterPair(value_reg, field_reg);
      ASSERT(!compiler->is_optimizing());
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2, /*tsan_enter_exit=*/false);
      __ Drop(2);
    } else {
      __ j(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != nullptr);

    if (value_cid == kDynamicCid) {
      __ TestImmediate(value_reg, kSmiTagMask);

      if (field_cid != kSmiCid) {
        __ BranchIf(EQ, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, field_cid);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);
        __ CompareObject(value_reg, Object::null_object());
      }

      __ BranchIf(NE, fail);
    } else if (value_cid == field_cid) {
      // Already proven by the propagated value cid.
    } else {
      ASSERT(value_cid != nullability);
      __ j(fail);
    }
  }
  __ Bind(&ok);
}

LocationSummary* GuardFieldTypeInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}

void GuardFieldTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(field().static_type_exactness_state().IsTracking());
  if (!field().static_type_exactness_state().NeedsFieldGuard()) {
    return;
  }

  compiler::Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : nullptr;

  compiler::Label ok;
  const Register value_reg = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  if (!compiler->is_optimizing() || field().is_nullable()) {
    __ CompareObject(value_reg, Object::null_object());
    __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);
  }

  const Field& original =
      Field::ZoneHandle(compiler->zone(), field().Original());
  __ LoadObject(temp, original);
  __ Load(temp,
          compiler::FieldAddress(
              temp, Field::static_type_exactness_state_offset()),
          compiler::kByte);

  if (!compiler->is_optimizing()) {
    __ CompareImmediate(temp, StaticTypeExactnessState::kUninitialized);
    __ BranchIf(LT, &ok, compiler::Assembler::kNearJump);
  }

  compiler::Label call_runtime;
  if (field().static_type_exactness_state().IsUninitialized()) {
    __ CompareImmediate(temp, StaticTypeExactnessState::kUninitialized);
    __ BranchIf(EQ, compiler->is_optimizing() ? deopt : &call_runtime);
  }

  __ AddShifted(TMP, value_reg, temp, compiler::target::kCompressedWordSizeLog2);
  __ LoadCompressed(temp, compiler::Address(TMP, 0));
  __ CompareObject(
      temp,
      TypeArguments::ZoneHandle(
          compiler->zone(), Type::Cast(AbstractType::Handle(field().type()))
                                .GetInstanceTypeArguments(compiler->thread())));
  if (deopt != nullptr) {
    __ BranchIf(NE, deopt);
  } else {
    __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

    __ Bind(&call_runtime);
    __ LoadObject(temp, original);
    __ PushRegisterPair(value_reg, temp);
    ASSERT(!compiler->is_optimizing());
    __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2, /*tsan_enter_exit=*/false);
    __ Drop(2);
  }

  __ Bind(&ok);
}

LocationSummary* GuardFieldLengthInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  if (!opt || (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const intptr_t kNumTemps = 3;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, Location::RequiresRegister());
    return summary;
  } else {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
}

void GuardFieldLengthInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (field().guarded_list_length() == Field::kNoFixedLength) {
    return;
  }

  compiler::Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : nullptr;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();
    const Register offset_reg = locs()->temp(1).reg();
    const Register length_reg = locs()->temp(2).reg();

    compiler::Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));
    __ Load(offset_reg,
            compiler::FieldAddress(
                field_reg,
                Field::guarded_list_length_in_object_offset_offset()),
            compiler::kByte);
    __ LoadCompressed(
        length_reg,
        compiler::FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ CompareImmediate(offset_reg, 0);
    __ BranchIf(LT, &ok, compiler::Assembler::kNearJump);

    __ add_d(TMP, value_reg, offset_reg);
    __ lx(TMP, compiler::Address(TMP, 0));
    __ CompareObjectRegisters(length_reg, TMP);

    if (deopt == nullptr) {
      __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

      __ PushRegisterPair(value_reg, field_reg);
      ASSERT(!compiler->is_optimizing());
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2, /*tsan_enter_exit=*/false);
      __ Drop(2);
    } else {
      __ BranchIf(NE, deopt);
    }

    __ Bind(&ok);
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(field().guarded_list_length() >= 0);
    ASSERT(field().guarded_list_length_in_object_offset() !=
           Field::kUnknownLengthOffset);

    __ lx(TMP, compiler::FieldAddress(
                   value_reg, field().guarded_list_length_in_object_offset()));
    __ CompareImmediate(TMP, Smi::RawValue(field().guarded_list_length()));
    __ BranchIf(NE, deopt);
  }
}

LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(kTypeArgumentsPos,
               Location::RegisterLocation(AllocateArrayABI::kTypeArgumentsReg));
  locs->set_in(kLengthPos,
               Location::RegisterLocation(AllocateArrayABI::kLengthReg));
  locs->set_out(0, Location::RegisterLocation(AllocateArrayABI::kResultReg));
  return locs;
}

static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  compiler::Label* slow_path,
                                  compiler::Label* done) {
  const int kInlineArraySize = 12;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      AllocateArrayABI::kResultReg,
                      T3,  // End address.
                      T4, T5);

  __ StoreCompressedIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::type_arguments_offset()),
      AllocateArrayABI::kTypeArgumentsReg);

  __ StoreCompressedIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::length_offset()),
      AllocateArrayABI::kLengthReg);

  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(UntaggedArray);
    __ AddImmediate(T5, AllocateArrayABI::kResultReg,
                    sizeof(UntaggedArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kCompressedWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ StoreCompressedIntoObjectNoBarrier(
            AllocateArrayABI::kResultReg, compiler::Address(T5, current_offset),
            NULL_REG);
        current_offset += kCompressedWordSize;
      }
    } else {
      compiler::Label end_loop, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(T5, T3);
      __ BranchIf(CS, &end_loop, compiler::Assembler::kNearJump);
      __ StoreCompressedIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                            compiler::Address(T5, 0), NULL_REG);
      __ AddImmediate(T5, kCompressedWordSize);
      __ j(&init_loop, compiler::Assembler::kNearJump);
      __ Bind(&end_loop);
    }
  }
  __ j(done, compiler::Assembler::kNearJump);
}

void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  TypeUsageInfo* type_usage_info = compiler->thread()->type_usage_info();
  if (type_usage_info != nullptr) {
    const Class& list_class =
        Class::Handle(compiler->isolate_group()->class_table()->At(kArrayCid));
    RegisterTypeArgumentsUse(compiler->function(), type_usage_info, list_class,
                             type_arguments()->definition());
  }

  compiler::Label slow_path, done;
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    if (compiler->is_optimizing() && !FLAG_precompiled_mode &&
        num_elements()->BindsToConstant() &&
        num_elements()->BoundConstant().IsSmi()) {
      const intptr_t length =
          Smi::Cast(num_elements()->BoundConstant()).Value();
      if (Array::IsValidLength(length)) {
        InlineArrayAllocation(compiler, length, &slow_path, &done);
      }
    }
  }

  __ Bind(&slow_path);
  auto object_store = compiler->isolate_group()->object_store();
  const auto& allocate_array_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_array_stub());
  compiler->GenerateStubCall(source(), allocate_array_stub,
                             UntaggedPcDescriptors::kOther, locs(), deopt_id(),
                             env());
  __ Bind(&done);
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT(!IsTypedDataBaseClassId(class_id()) || opt);

  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  const bool can_be_constant =
      index()->BindsToConstant() &&
      compiler::Assembler::AddressCanHoldConstantIndex(
          index()->BoundConstant(), IsUntagged(), class_id(), index_scale());
  locs->set_in(1, can_be_constant
                      ? Location::Constant(index()->definition()->AsConstant())
                      : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());

  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  if (IsClampedTypedDataBaseClassId(class_id())) {
    ASSERT(rep == kUnboxedUint8);
    locs->set_in(2, LocationRegisterOrConstant(value()));
  } else if (RepresentationUtils::IsUnboxedInteger(rep)) {
    ConstantInstr* constant = value()->definition()->AsConstant();
    if (constant != nullptr && constant->HasZeroRepresentation()) {
      locs->set_in(2, Location::Constant(constant));
    } else {
      locs->set_in(2, Location::RequiresRegister());
    }
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    if (rep == kUnboxedFloat || rep == kUnboxedDouble) {
      ConstantInstr* constant = value()->definition()->AsConstant();
      if (constant != nullptr && constant->HasZeroRepresentation()) {
        locs->set_in(2, Location::Constant(constant));
      } else {
        locs->set_in(2, Location::RequiresFpuRegister());
      }
    } else {
      locs->set_in(2, Location::RequiresFpuRegister());
    }
  } else if (class_id() == kArrayCid) {
    locs->set_in(2, ShouldEmitStoreBarrier()
                        ? Location::RegisterLocation(kWriteBarrierValueReg)
                        : LocationRegisterOrConstant(value()));
    if (ShouldEmitStoreBarrier()) {
      locs->set_in(0, Location::RegisterLocation(kWriteBarrierObjectReg));
      locs->set_temp(0, Location::RegisterLocation(kWriteBarrierSlotReg));
    }
  } else {
    UNREACHABLE();
  }
  return locs;
}

void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register temp = locs()->temp(0).reg();
  compiler::Address element_address(TMP);
  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  ASSERT(RequiredInputRepresentation(2) == Boxing::NativeRepresentation(rep));

  if (!compiler->is_optimizing() && sanitize()) {
    EmitSanCallUnopt(compiler, this, [&]() -> const RuntimeEntry& {
      if (index.IsRegister()) {
        __ ComputeElementAddressForRegIndex(A0, IsUntagged(), class_id(),
                                            index_scale(), index_unboxed_,
                                            array, index.reg());
      } else {
        __ ComputeElementAddressForIntIndex(
            A0, IsUntagged(), class_id(), index_scale(), array,
            Smi::Cast(index.constant()).Value());
      }
      switch (RepresentationUtils::ValueSize(rep)) {
        case 1:
          return kSanWrite1RuntimeEntry;
        case 2:
          return kSanWrite2RuntimeEntry;
        case 4:
          return kSanWrite4RuntimeEntry;
        case 8:
          return kSanWrite8RuntimeEntry;
        case 16:
          return kSanWrite16RuntimeEntry;
        default:
          UNREACHABLE();
      }
    });
  }

  if (class_id() == kArrayCid && ShouldEmitStoreBarrier()) {
    if (index.IsRegister()) {
      __ ComputeElementAddressForRegIndex(temp, IsUntagged(), class_id(),
                                          index_scale(), index_unboxed_, array,
                                          index.reg());
    } else {
      __ ComputeElementAddressForIntIndex(temp, IsUntagged(), class_id(),
                                          index_scale(), array,
                                          Smi::Cast(index.constant()).Value());
    }
    const Register value = locs()->in(2).reg();
    __ StoreCompressedIntoArray(array, temp, value, CanValueBeSmi());
    return;
  }

  element_address = index.IsRegister()
                        ? __ ElementAddressForRegIndex(
                              IsUntagged(), class_id(), index_scale(),
                              index_unboxed_, array, index.reg(), temp)
                        : __ ElementAddressForIntIndex(
                              IsUntagged(), class_id(), index_scale(), array,
                              Smi::Cast(index.constant()).Value());

  if (IsClampedTypedDataBaseClassId(class_id())) {
    ASSERT(rep == kUnboxedUint8);
    if (locs()->in(2).IsConstant()) {
      const Smi& constant = Smi::Cast(locs()->in(2).constant());
      intptr_t value = constant.Value();
      if (value > 0xFF) {
        value = 0xFF;
      } else if (value < 0) {
        value = 0;
      }
      if (value == 0) {
        __ Store(ZR, element_address, compiler::kUnsignedByte);
      } else {
        __ LoadImmediate(TMP, static_cast<int8_t>(value));
        __ Store(TMP, element_address, compiler::kUnsignedByte);
      }
    } else {
      const Register value = locs()->in(2).reg();
      compiler::Label store_zero, store_ff, done;
      __ blt(value, ZR, &store_zero, compiler::Assembler::kNearJump);
      __ LoadImmediate(TMP, 0xFF);
      __ blt(TMP, value, &store_ff, compiler::Assembler::kNearJump);
      __ Store(value, element_address, compiler::kUnsignedByte);
      __ j(&done, compiler::Assembler::kNearJump);
      __ Bind(&store_zero);
      __ MoveRegister(TMP, ZR);
      __ Bind(&store_ff);
      __ Store(TMP, element_address, compiler::kUnsignedByte);
      __ Bind(&done);
    }
  } else if (RepresentationUtils::IsUnboxedInteger(rep)) {
    if (locs()->in(2).IsConstant()) {
      ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
      __ Store(ZR, element_address, RepresentationUtils::OperandSize(rep));
    } else {
      __ Store(locs()->in(2).reg(), element_address,
               RepresentationUtils::OperandSize(rep));
    }
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    if (rep == kUnboxedFloat) {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ Store(ZR, element_address, compiler::kFourBytes);
      } else {
        __ StoreS(locs()->in(2).fpu_reg(), element_address);
      }
    } else if (rep == kUnboxedDouble) {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ Store(ZR, element_address, compiler::kEightBytes);
      } else {
        __ StoreD(locs()->in(2).fpu_reg(), element_address);
      }
    } else {
      ASSERT(rep == kUnboxedInt32x4 || rep == kUnboxedFloat32x4 ||
             rep == kUnboxedFloat64x2);
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ StoreToOffset(ZR, element_address.base(), element_address.offset(),
                         compiler::kEightBytes);
        __ StoreToOffset(ZR, element_address.base(),
                         element_address.offset() + compiler::target::kWordSize,
                         compiler::kEightBytes);
      } else {
        __ StoreQ(locs()->in(2).fpu_reg(), element_address);
      }
    }
  } else if (class_id() == kArrayCid) {
    ASSERT(!ShouldEmitStoreBarrier());
    if (locs()->in(2).IsConstant()) {
      const Object& constant = locs()->in(2).constant();
      __ StoreCompressedObjectIntoObjectNoBarrier(array, element_address,
                                                  constant);
    } else {
      const Register value = locs()->in(2).reg();
      __ StoreCompressedIntoObjectNoBarrier(array, element_address, value);
    }
  } else {
    UNREACHABLE();
  }
}

LocationSummary* CheckWritableInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      UseSharedSlowPathStub(opt) ? LocationSummary::kCallOnSharedSlowPath
                                 : LocationSummary::kCallOnSlowPath);
  locs->set_in(kReceiver, Location::RequiresRegister());
  return locs;
}

void CheckWritableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  WriteErrorSlowPath* slow_path = new WriteErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  __ LoadFieldFromOffset(TMP, locs()->in(kReceiver).reg(),
                         compiler::target::Object::tags_offset(),
                         compiler::kUnsignedByte);
  ASSERT(compiler::target::UntaggedObject::kDeeplyImmutableBit < 8);
  ASSERT(compiler::target::UntaggedObject::kShallowImmutableBit < 8);
  __ AndImmediate(
      TMP, TMP,
      1 << compiler::target::UntaggedObject::kDeeplyImmutableBit |
          1 << compiler::target::UntaggedObject::kShallowImmutableBit);
  __ BranchIfNotZero(TMP, slow_path->entry_label());
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  ASSERT(!IsTypedDataBaseClassId(class_id()) || opt);

  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kArrayPos, Location::RequiresRegister());
  const bool can_be_constant =
      index()->BindsToConstant() &&
      compiler::Assembler::AddressCanHoldConstantIndex(
          index()->BoundConstant(), IsUntagged(), class_id(), index_scale());
  locs->set_in(kIndexPos,
               can_be_constant
                   ? Location::Constant(index()->definition()->AsConstant())
                   : Location::RequiresRegister());
  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    locs->set_out(0, Location::RequiresRegister());
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}

void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register array = locs()->in(kArrayPos).reg();
  const Location index = locs()->in(kIndexPos);
  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());

  if (!compiler->is_optimizing() && sanitize()) {
    EmitSanCallUnopt(compiler, this, [&]() -> const RuntimeEntry& {
      if (index.IsRegister()) {
        __ ComputeElementAddressForRegIndex(A0, IsUntagged(), class_id(),
                                            index_scale(), index_unboxed_,
                                            array, index.reg());
      } else {
        __ ComputeElementAddressForIntIndex(
            A0, IsUntagged(), class_id(), index_scale(), array,
            Smi::Cast(index.constant()).Value());
      }
      switch (RepresentationUtils::ValueSize(rep)) {
        case 1:
          return kSanRead1RuntimeEntry;
        case 2:
          return kSanRead2RuntimeEntry;
        case 4:
          return kSanRead4RuntimeEntry;
        case 8:
          return kSanRead8RuntimeEntry;
        case 16:
          return kSanRead16RuntimeEntry;
        default:
          UNREACHABLE();
      }
    });
  }

  compiler::Address element_address =
      index.IsRegister()
          ? __ ElementAddressForRegIndex(IsUntagged(), class_id(),
                                         index_scale(), index_unboxed_, array,
                                         index.reg(), TMP)
          : __ ElementAddressForIntIndex(
                IsUntagged(), class_id(), index_scale(), array,
                Smi::Cast(index.constant()).Value());

  ASSERT(representation() == Boxing::NativeRepresentation(rep));
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    const Register result = locs()->out(0).reg();
    __ Load(result, element_address, RepresentationUtils::OperandSize(rep));
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    const FRegister result = locs()->out(0).fpu_reg();
    if (rep == kUnboxedFloat) {
      __ LoadS(result, element_address);
    } else if (rep == kUnboxedDouble) {
      __ LoadD(result, element_address);
    } else {
      ASSERT(rep == kUnboxedInt32x4 || rep == kUnboxedFloat32x4 ||
             rep == kUnboxedFloat64x2);
      __ LoadQ(result, element_address);
    }
  } else {
    ASSERT(rep == kTagged);
    ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
           (class_id() == kTypeArgumentsCid) || (class_id() == kClosureCid) ||
           (class_id() == kRecordCid));
    const Register result = locs()->out(0).reg();
    __ Load(result, element_address);
  }
}

LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register str = locs()->in(0).reg();
  const Register index = locs()->in(1).reg();
  compiler::OperandSize sz = compiler::kByte;

  switch (class_id()) {
    case kOneByteStringCid:
      switch (element_count()) {
        case 1:
          sz = compiler::kUnsignedByte;
          break;
        case 2:
          sz = compiler::kUnsignedTwoBytes;
          break;
        case 4:
          sz = compiler::kUnsignedFourBytes;
          break;
        default:
          UNREACHABLE();
      }
      break;
    case kTwoByteStringCid:
      switch (element_count()) {
        case 1:
          sz = compiler::kUnsignedTwoBytes;
          break;
        case 2:
          sz = compiler::kUnsignedFourBytes;
          break;
        default:
          UNREACHABLE();
      }
      break;
    default:
      UNREACHABLE();
  }

  compiler::Address element_address = __ ElementAddressForRegIndex(
      IsExternal(), class_id(), index_scale(), /*index_unboxed=*/false, str,
      index, TMP);
  const Register result = locs()->out(0).reg();
  __ Load(result, element_address, sz);
  ASSERT(can_pack_into_smi());
  __ SmiTag(result);
}

LocationSummary* OneByteStringFromCharCodeInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void OneByteStringFromCharCodeInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  const Register char_code = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ Load(result,
          compiler::Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddShifted(TMP, result, char_code, kWordSizeLog2 - kSmiTagSize);
  __ Load(result,
          compiler::Address(TMP,
                            Symbols::kNullCharCodeSymbolOffset * kWordSize));
}

LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(cid_ == kOneByteStringCid);
  const Register str = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  compiler::Label is_one, done;

  __ LoadCompressedSmi(result,
                       compiler::FieldAddress(str, String::length_offset()));
  __ CompareImmediate(result, Smi::RawValue(1));
  __ BranchIf(EQ, &is_one, compiler::Assembler::kNearJump);
  __ LoadImmediate(result, Smi::RawValue(-1));
  __ j(&done, compiler::Assembler::kNearJump);

  __ Bind(&is_one);
  __ Load(result, compiler::FieldAddress(str, OneByteString::data_offset()),
          compiler::kUnsignedByte);
  __ SmiTag(result);
  __ Bind(&done);
}

LocationSummary* Utf8ScanInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Any());               // decoder
  summary->set_in(1, Location::WritableRegister());  // bytes
  summary->set_in(2, Location::WritableRegister());  // start
  summary->set_in(3, Location::WritableRegister());  // end
  summary->set_in(4, Location::WritableRegister());  // table
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void Utf8ScanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register bytes_reg = locs()->in(1).reg();
  const Register start_reg = locs()->in(2).reg();
  const Register end_reg = locs()->in(3).reg();
  const Register table_reg = locs()->in(4).reg();
  const Register size_reg = locs()->out(0).reg();

  const Register bytes_ptr_reg = start_reg;
  const Register bytes_end_reg = end_reg;
  const Register flags_reg = bytes_reg;
  const Register temp_reg = TMP;
  const Register decoder_temp_reg = start_reg;
  const Register flags_temp_reg = end_reg;

  const intptr_t kSizeMask = 0x03;
  const intptr_t kFlagsMask = 0x3C;

  compiler::Label loop, loop_in;

  __ LoadFromSlot(bytes_reg, bytes_reg, Slot::PointerBase_data());
  __ AddImmediate(
      table_reg, table_reg,
      compiler::target::OneByteString::data_offset() - kHeapObjectTag);

  __ add_d(bytes_ptr_reg, bytes_reg, start_reg);
  __ add_d(bytes_end_reg, bytes_reg, end_reg);

  __ LoadImmediate(size_reg, 0);
  __ LoadImmediate(flags_reg, 0);

  __ j(&loop_in, compiler::Assembler::kNearJump);
  __ Bind(&loop);

  __ Load(temp_reg, compiler::Address(bytes_ptr_reg, 0),
          compiler::kUnsignedByte);
  __ AddImmediate(bytes_ptr_reg, bytes_ptr_reg, 1);

  __ add_d(temp_reg, table_reg, temp_reg);
  __ Load(temp_reg, compiler::Address(temp_reg, 0), compiler::kUnsignedByte);
  __ or_(flags_reg, flags_reg, temp_reg);
  __ andi(temp_reg, temp_reg, kSizeMask);
  __ add_d(size_reg, size_reg, temp_reg);

  __ Bind(&loop_in);
  __ bltu(bytes_ptr_reg, bytes_end_reg, &loop,
          compiler::Assembler::kNearJump);

  __ AndImmediate(flags_reg, flags_reg, kFlagsMask);
  if (!IsScanFlagsUnboxed()) {
    __ SmiTag(flags_reg);
  }

  Register decoder_reg;
  const Location decoder_location = locs()->in(0);
  if (decoder_location.IsStackSlot()) {
    __ Load(decoder_temp_reg, LocationToStackSlotAddress(decoder_location));
    decoder_reg = decoder_temp_reg;
  } else {
    decoder_reg = decoder_location.reg();
  }

  const auto scan_flags_field_offset = scan_flags_field_.offset_in_bytes();
  if (scan_flags_field_.is_compressed() && !IsScanFlagsUnboxed()) {
    __ LoadCompressedSmiFieldFromOffset(flags_temp_reg, decoder_reg,
                                        scan_flags_field_offset);
    __ or_(flags_temp_reg, flags_temp_reg, flags_reg);
    __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset,
                          compiler::kObjectBytes);
  } else {
    __ LoadFieldFromOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
    __ or_(flags_temp_reg, flags_temp_reg, flags_reg);
    __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
  }
}

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const bool need_temp = FLAG_experimental_shared_data && field().is_shared() &&
                         !field().has_deeply_immutable_type();
  const intptr_t kNumTemps = need_temp ? 1 : 0;
  const bool can_call_to_throw = FLAG_experimental_shared_data;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      can_call_to_throw ? LocationSummary::kCallOnSlowPath
                                        : LocationSummary::kNoCall);
  locs->set_in(
      0, Location::RegisterLocation(CheckedStoreIntoSharedStubABI::kValueReg));
  if (need_temp) {
    locs->set_temp(0, Location::RegisterLocation(
                          CheckedStoreIntoSharedStubABI::kFieldReg));
  }
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();

  compiler->used_static_fields().Add(&field());

  CheckedStoreIntoSharedSlowPath* checked_store_into_shared_slow_path = nullptr;
  if (FLAG_experimental_shared_data) {
    if (!field().is_shared()) {
      ThrowErrorSlowPathCode* slow_path = new FieldAccessErrorSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ LoadIsolate(TMP);
      __ BranchIfZero(TMP, slow_path->entry_label());
    } else if (!field().has_deeply_immutable_type()) {
      const Register temp = locs()->temp(0).reg();

      checked_store_into_shared_slow_path =
          new CheckedStoreIntoSharedSlowPath(this, value);
      compiler->AddSlowPathCode(checked_store_into_shared_slow_path);

      compiler::Label allow_store;
      __ BranchIfSmi(value, &allow_store, compiler::Assembler::kNearJump);
      __ LoadFieldFromOffset(TMP, value,
                             compiler::target::Object::tags_offset(),
                             compiler::kUnsignedByte);
      __ AndImmediate(temp, TMP,
                      1 << compiler::target::UntaggedObject::kCanonicalBit);
      __ BranchIfNotZero(temp, &allow_store, compiler::Assembler::kNearJump);
      __ AndImmediate(
          temp, TMP,
          1 << compiler::target::UntaggedObject::kDeeplyImmutableBit);
      __ BranchIfZero(temp,
                      checked_store_into_shared_slow_path->entry_label());

      __ Bind(&allow_store);
    }
  }

  __ LoadFromOffset(
      TMP, THR,
      field().is_shared()
          ? compiler::target::Thread::shared_field_table_values_offset()
          : compiler::target::Thread::field_table_values_offset());
  if (field().is_shared()) {
    __ StoreRelease(value,
                    compiler::Address(
                        TMP, compiler::target::FieldTable::OffsetOf(field())));
  } else {
    __ StoreToOffset(value, TMP,
                     compiler::target::FieldTable::OffsetOf(field()));
  }

  if (FLAG_experimental_shared_data && field().is_shared() &&
      !field().has_deeply_immutable_type()) {
    __ Bind(checked_store_into_shared_slow_path->exit_label());
  }
}

LocationSummary* LoadIndexedUnsafeInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  switch (representation()) {
    case kTagged:
    case kUnboxedInt64:
      locs->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedDouble:
      locs->set_out(0, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
      break;
  }
  return locs;
}

void LoadIndexedUnsafeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(RequiredInputRepresentation(0) == kTagged);
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);

  const Register index = locs()->in(0).reg();
  __ AddShifted(TMP, base_reg(), index, kWordSizeLog2 - kSmiTagSize);
  switch (representation()) {
    case kTagged:
    case kUnboxedInt64:
      __ LoadFromOffset(locs()->out(0).reg(), TMP, offset());
      break;
    case kUnboxedDouble:
      __ LoadDFromOffset(locs()->out(0).fpu_reg(), TMP, offset());
      break;
    default:
      UNREACHABLE();
      break;
  }
}

DEFINE_BACKEND(StoreIndexedUnsafe,
               (NoLocation, Register index, Register value)) {
  ASSERT(instr->RequiredInputRepresentation(
             StoreIndexedUnsafeInstr::kIndexPos) == kTagged);  // It is a Smi.
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);

  __ AddShifted(TMP, instr->base_reg(), index,
                compiler::target::kWordSizeLog2 - kSmiTagSize);
  __ Store(value, compiler::Address(TMP, instr->offset()));
}

LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_out(0, Location::RegisterLocation(A0));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == T1);
  ASSERT(locs()->out(0).reg() == A0);

  auto object_store = compiler->isolate_group()->object_store();
  const auto& allocate_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_context_stub());
  __ LoadImmediate(T1, num_context_variables());
  compiler->GenerateStubCall(source(), allocate_context_stub,
                             UntaggedPcDescriptors::kOther, locs(), deopt_id(),
                             env());
}

LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T5));
  locs->set_out(0, Location::RegisterLocation(A0));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == T5);
  ASSERT(locs()->out(0).reg() == A0);

  auto object_store = compiler->isolate_group()->object_store();
  const auto& clone_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->clone_context_stub());
  compiler->GenerateStubCall(source(), clone_context_stub,
                             UntaggedPcDescriptors::kOther, locs(), deopt_id(),
                             env());
}

LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_temp(1, Location::RegisterLocation(T3));
  locs->set_temp(2, Location::RegisterLocation(T4));
  locs->set_out(0, Location::RegisterLocation(A0));
  return locs;
}

class AllocateContextSlowPath
    : public TemplateSlowPathCode<AllocateUninitializedContextInstr> {
 public:
  explicit AllocateContextSlowPath(
      AllocateUninitializedContextInstr* instruction)
      : TemplateSlowPathCode(instruction) {}

  void EmitNativeCode(FlowGraphCompiler* compiler) override {
    __ Bind(entry_label());

    LocationSummary* locs = instruction()->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);

    auto slow_path_env = compiler->SlowPathEnvironmentFor(
        instruction(), /*num_slow_path_args=*/0);
    ASSERT(slow_path_env != nullptr);

    auto object_store = compiler->isolate_group()->object_store();
    const auto& allocate_context_stub = Code::ZoneHandle(
        compiler->zone(), object_store->allocate_context_stub());

    __ LoadImmediate(T1, instruction()->num_context_variables());
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               UntaggedPcDescriptors::kOther, locs,
                               instruction()->deopt_id(), slow_path_env);
    ASSERT(locs->out(0).reg() == A0);

    compiler->RestoreLiveRegisters(locs);
    __ j(exit_label(), compiler::Assembler::kNearJump);
  }
};

void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  const Register end_address = locs()->temp(0).reg();
  const Register temp1 = locs()->temp(1).reg();
  const Register temp2 = locs()->temp(2).reg();

  AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    const intptr_t instance_size = Context::InstanceSize(num_context_variables());
    __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                        result, end_address, temp1, temp2);

    __ LoadImmediate(temp1, num_context_variables());
    __ StoreFieldToOffset(temp1, result, Context::num_variables_offset(),
                          compiler::kFourBytes);
  } else {
    __ j(slow_path->entry_label());
  }

  __ Bind(slow_path->exit_label());
}

LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}

void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(this);

  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
  }

  if (!compiler->is_optimizing()) {
    if (raw_exception_var_ != nullptr) {
      __ StoreToOffset(
          kExceptionObjectReg, FP,
          compiler::target::FrameOffsetInBytesForVariable(raw_exception_var_));
    }
    if (raw_stacktrace_var_ != nullptr) {
      __ StoreToOffset(
          kStackTraceObjectReg, FP,
          compiler::target::FrameOffsetInBytesForVariable(raw_stacktrace_var_));
    }
  }
}

void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#ifdef PRODUCT
  UNREACHABLE();
#else
  ASSERT(!compiler->is_optimizing());
  __ JumpAndLinkPatchable(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  const bool using_shared_stub = UseSharedSlowPathStub(opt);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      using_shared_stub ? LocationSummary::kCallOnSharedSlowPath
                                        : LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}

class CheckStackOverflowSlowPath
    : public TemplateSlowPathCode<CheckStackOverflowInstr> {
 public:
  static constexpr intptr_t kNumSlowPathArgs = 0;

  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : TemplateSlowPathCode(instruction) {}

  void EmitNativeCode(FlowGraphCompiler* compiler) override {
    auto locs = instruction()->locs();
    if (compiler->isolate_group()->use_osr() && osr_entry_label()->IsLinked()) {
      const Register value = locs->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(value, Thread::kOsrRequest);
      __ Store(value,
               compiler::Address(THR, Thread::stack_overflow_flags_offset()));
    }

    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    const bool using_shared_stub = locs->call_on_shared_slow_path();
    if (!using_shared_stub) {
      compiler->SaveLiveRegisters(locs);
    }

    ASSERT(compiler->pending_deoptimization_env_ == nullptr);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    const bool has_frame = compiler->flow_graph().graph_entry()->NeedsFrame();
    if (using_shared_stub) {
      if (!has_frame) {
        ASSERT(__ constant_pool_allowed());
        __ set_constant_pool_allowed(false);
        __ EnterDartFrame(0);
        if (FLAG_target_thread_sanitizer) {
          __ TsanFuncEntry();
        }
      }
      auto object_store = compiler->isolate_group()->object_store();
      const bool live_fpu_regs = locs->live_registers()->FpuRegisterCount() > 0;
      const auto& stub = Code::ZoneHandle(
          compiler->zone(),
          live_fpu_regs
              ? object_store->stack_overflow_stub_with_fpu_regs_stub()
              : object_store->stack_overflow_stub_without_fpu_regs_stub());

      if (compiler->CanPcRelativeCall(stub)) {
        __ GenerateUnRelocatedPcRelativeCall();
        compiler->AddPcRelativeCallStubTarget(stub);
      } else {
        const uword entry_point_offset =
            Thread::stack_overflow_shared_stub_entry_point_offset(
                live_fpu_regs);
        __ Call(compiler::Address(THR, entry_point_offset));
      }
      compiler->RecordSafepoint(locs, kNumSlowPathArgs);
      compiler->RecordCatchEntryMoves(env);
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOther,
                                     instruction()->deopt_id(),
                                     instruction()->source());
      if (!has_frame) {
        if (FLAG_target_thread_sanitizer) {
          __ TsanFuncExit();
        }
        __ LeaveDartFrame();
        __ set_constant_pool_allowed(true);
      }
    } else {
      ASSERT(has_frame);
      const bool tsan_enter_exit = false;
      __ CallRuntime(kInterruptOrStackOverflowRuntimeEntry, kNumSlowPathArgs,
                     tsan_enter_exit);
      compiler->EmitCallsiteMetadata(
          instruction()->source(), instruction()->deopt_id(),
          UntaggedPcDescriptors::kOther, instruction()->locs(), env);
    }

    if (compiler->isolate_group()->use_osr() && !compiler->is_optimizing() &&
        instruction()->in_loop()) {
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOsrEntry,
                                     instruction()->deopt_id(),
                                     InstructionSource());
    }
    compiler->pending_deoptimization_env_ = nullptr;
    if (!using_shared_stub) {
      compiler->RestoreLiveRegisters(locs);
    }
    __ j(exit_label());
  }

  compiler::Label* osr_entry_label() {
    ASSERT(IsolateGroup::Current()->use_osr());
    return &osr_entry_label_;
  }

 private:
  compiler::Label osr_entry_label_;
};

void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ Load(TMP, compiler::Address(
                   THR, compiler::target::Thread::stack_limit_offset()));
  __ bleu(SP, TMP, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register function = locs()->temp(0).reg();
    __ LoadObject(function, compiler->parsed_function().function());
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
    __ LoadFieldFromOffset(TMP, function, Function::usage_counter_offset(),
                           compiler::kFourBytes);
    __ AddImmediate(TMP, TMP, 1);
    __ StoreFieldToOffset(TMP, function, Function::usage_counter_offset(),
                          compiler::kFourBytes);
    __ CompareImmediate(TMP, threshold);
    __ BranchIf(GE, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ j(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}

static void BranchIfAddOverflow(FlowGraphCompiler* compiler,
                                Register result,
                                Register left,
                                Register right,
                                compiler::Label* deopt) {
  __ xor_(TMP, left, result);
  __ xor_(TMP2, right, result);
  __ and_(TMP, TMP, TMP2);
  __ blt(TMP, ZR, deopt);
}

static void BranchIfSubOverflow(FlowGraphCompiler* compiler,
                                Register result,
                                Register left,
                                Register right,
                                compiler::Label* deopt) {
  __ xor_(TMP, left, right);
  __ xor_(TMP2, left, result);
  __ and_(TMP, TMP, TMP2);
  __ blt(TMP, ZR, deopt);
}

static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  const Register left = locs.in(0).reg();
  const Register result = locs.out(0).reg();
  compiler::Label* deopt =
      shift_left->CanDeoptimize()
          ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                   ICData::kDeoptBinarySmiOp)
          : nullptr;

  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT(value >= 0);
    if (shift_left->can_overflow()) {
      ASSERT(deopt != nullptr);
      if (result == left) {
        __ MoveRegister(TMP2, left);
        __ slli_d(result, left, Utils::Minimum<intptr_t>(value, 63));
        __ srai_d(TMP, result, Utils::Minimum<intptr_t>(value, 63));
        __ bne(TMP2, TMP, deopt);
      } else {
        __ slli_d(result, left, Utils::Minimum<intptr_t>(value, 63));
        __ srai_d(TMP2, result, Utils::Minimum<intptr_t>(value, 63));
        __ bne(left, TMP2, deopt);
      }
    } else {
      __ slli_d(result, left, Utils::Minimum<intptr_t>(value, 63));
    }
    return;
  }

  const Register right = locs.in(1).reg();
  if (shift_left->CanDeoptimize()) {
    __ CompareImmediate(right, 0);
    __ BranchIf(LT, deopt);
    __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
    __ BranchIf(CS, deopt);
  }
  __ SmiUntag(TMP, right);
  if (shift_left->can_overflow()) {
    if (result == left) {
      __ MoveRegister(TMP2, left);
      __ sll_d(result, left, TMP);
      __ sra_d(TMP, result, TMP);
      __ bne(TMP2, TMP, deopt);
    } else {
      __ sll_d(result, left, TMP);
      __ sra_d(TMP2, result, TMP);
      __ bne(left, TMP2, deopt);
    }
  } else {
    __ sll_d(result, left, TMP);
  }
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      ((op_kind() == Token::kUSHR) || (op_kind() == Token::kMUL)) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if ((op_kind() == Token::kTRUNCDIV) || (op_kind() == Token::kMOD)) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, op_kind() == Token::kTRUNCDIV &&
                            RightOperandIsPowerOfTwoConstant()
                        ? Location::Constant(
                              right()->definition()->AsConstant())
                        : Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  if (kNumTemps == 1) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (CanDeoptimize() || (op_kind() == Token::kUSHR)) {
    summary->set_out(0, Location::RequiresRegister());
  } else {
    summary->set_out(0, Location::MayBeSameAsFirstInput());
  }
  return summary;
}

void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  const Register left = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  compiler::Label* deopt = nullptr;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intx_t raw = static_cast<intx_t>(constant.ptr());
    const intptr_t value = Smi::Cast(constant).Value();
    switch (op_kind()) {
      case Token::kADD:
        __ AddImmediate(result, left, raw);
        if (deopt != nullptr) {
          __ LoadImmediate(TMP2, raw);
          BranchIfAddOverflow(compiler, result, left, TMP2, deopt);
        }
        break;
      case Token::kSUB:
        __ AddImmediate(result, left, -raw);
        if (deopt != nullptr) {
          __ LoadImmediate(TMP2, raw);
          BranchIfSubOverflow(compiler, result, left, TMP2, deopt);
        }
        break;
      case Token::kMUL:
        if (deopt == nullptr) {
          __ LoadImmediate(TMP, value);
          __ mul_d(result, left, TMP);
        } else {
          __ MultiplyImmediateBranchOverflow(result, left, value, deopt);
        }
        break;
      case Token::kBIT_AND:
        __ AndImmediate(result, left, raw);
        break;
      case Token::kBIT_OR:
        __ OrImmediate(result, left, raw);
        break;
      case Token::kBIT_XOR:
        __ XorImmediate(result, left, raw);
        break;
      case Token::kSHR:
        __ srai_d(result, left, Utils::Minimum<intptr_t>(value + kSmiTagSize,
                                                        63));
        __ SmiTag(result);
        break;
      case Token::kUSHR:
        ASSERT(value >= 0);
        __ SmiUntag(TMP, left);
        __ srli_d(TMP, TMP, Utils::Minimum<intptr_t>(value, 63));
        __ SmiTag(result, TMP);
        if (deopt != nullptr) {
          __ SmiUntag(TMP2, result);
          __ bne(TMP, TMP2, deopt);
        }
        break;
      case Token::kTRUNCDIV:
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        {
          const intptr_t shift_count =
              Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
          ASSERT(kSmiTagSize == 1);
          ASSERT(shift_count > 1);  // 1, -1 case handled earlier.
          __ srai_d(TMP, left, XLEN - 1);
          __ srli_d(TMP, TMP, XLEN - shift_count);
          __ add_d(TMP2, left, TMP);
          __ srai_d(result, TMP2, shift_count);
          if (value < 0) {
            __ sub_d(result, ZR, result);
          }
          __ SmiTag(result);
        }
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  const Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
      __ add_d(result, left, right);
      if (deopt != nullptr) {
        BranchIfAddOverflow(compiler, result, left, right, deopt);
      }
      break;
    case Token::kSUB:
      __ sub_d(result, left, right);
      if (deopt != nullptr) {
        BranchIfSubOverflow(compiler, result, left, right, deopt);
      }
      break;
    case Token::kMUL: {
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      if (deopt == nullptr) {
        __ mul_d(result, temp, right);
      } else {
        __ MultiplyBranchOverflow(result, temp, right, deopt);
      }
      break;
    }
    case Token::kBIT_AND:
      __ and_(result, left, right);
      break;
    case Token::kBIT_OR:
      __ or_(result, left, right);
      break;
    case Token::kBIT_XOR:
      __ xor_(result, left, right);
      break;
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, 0);
        __ BranchIf(LT, deopt);
      }
      __ SmiUntag(TMP, right);
      compiler::Label shift_in_bounds;
      __ CompareImmediate(TMP, 63);
      __ BranchIf(LE, &shift_in_bounds, compiler::Assembler::kNearJump);
      __ LoadImmediate(TMP, 63);
      __ Bind(&shift_in_bounds);
      __ SmiUntag(TMP2, left);
      __ sra_d(result, TMP2, TMP);
      __ SmiTag(result);
      break;
    }
    case Token::kUSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, 0);
        __ BranchIf(LT, deopt);
      }
      __ SmiUntag(TMP, right);
      compiler::Label done, shift_in_bounds;
      __ CompareImmediate(TMP, 63);
      __ BranchIf(LE, &shift_in_bounds, compiler::Assembler::kNearJump);
      __ LoadImmediate(result, 0);
      __ j(&done, compiler::Assembler::kNearJump);
      __ Bind(&shift_in_bounds);
      __ SmiUntag(TMP2, left);
      __ srl_d(TMP, TMP2, TMP);
      __ SmiTag(result, TMP);
      if (deopt != nullptr) {
        __ SmiUntag(TMP2, result);
        __ bne(TMP, TMP2, deopt);
      }
      __ Bind(&done);
      break;
    }
    case Token::kTRUNCDIV: {
      if (RightOperandCanBeZero()) {
        __ beqz(right, deopt);
      }
      __ SmiUntag(TMP, left);
      __ SmiUntag(TMP2, right);
      __ div_d(TMP, TMP, TMP2);
      __ SmiTag(result, TMP);

      if (RightOperandCanBeMinusOne()) {
        __ SmiUntag(TMP2, result);
        __ bne(TMP, TMP2, deopt);
      }
      break;
    }
    case Token::kMOD: {
      if (RightOperandCanBeZero()) {
        __ beqz(right, deopt);
      }
      __ SmiUntag(TMP, left);
      __ SmiUntag(TMP2, right);
      __ mod_d(result, TMP, TMP2);

      compiler::Label done, adjust;
      __ bge(result, ZR, &done, compiler::Assembler::kNearJump);
      ASSERT(result != right);
      __ bge(right, ZR, &adjust, compiler::Assembler::kNearJump);
      __ sub_d(result, result, TMP2);
      __ j(&done, compiler::Assembler::kNearJump);
      __ Bind(&adjust);
      __ add_d(result, result, TMP2);
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    default:
      UNREACHABLE();
  }
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  switch (op_kind()) {
    case Token::kMOD:
    case Token::kTRUNCDIV: {
      const intptr_t kNumTemps = (op_kind() == Token::kMOD) ? 1 : 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, Location::RequiresRegister());
      summary->set_out(0, Location::RequiresRegister());
      if (kNumTemps == 1) {
        summary->set_temp(0, Location::RequiresRegister());
      }
      return summary;
    }
    case Token::kSHL:
    case Token::kSHR:
    case Token::kUSHR: {
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, 0, LocationSummary::kCallOnSlowPath);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, RightOperandIsPositive()
                             ? LocationRegisterOrConstant(right())
                             : Location::RequiresRegister());
      summary->set_out(0, Location::RequiresRegister());
      return summary;
    }
    default: {
      LocationSummary* summary = new (zone)
          LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, LocationRegisterOrConstant(right()));
      summary->set_out(0, Location::MayBeSameAsFirstInput());
      return summary;
    }
  }
}

class Int64DivideSlowPath : public ThrowErrorSlowPathCode {
 public:
  Int64DivideSlowPath(BinaryInt64OpInstr* instruction,
                      Register divisor,
                      Register tmp,
                      Register out)
      : ThrowErrorSlowPathCode(instruction,
                               kIntegerDivisionByZeroExceptionRuntimeEntry),
        is_mod_(instruction->op_kind() == Token::kMOD),
        divisor_(divisor),
        tmp_(tmp),
        out_(out),
        adjust_sign_label_() {}

  void EmitNativeCode(FlowGraphCompiler* compiler) override {
    if (has_divide_by_zero()) {
      ThrowErrorSlowPathCode::EmitNativeCode(compiler);
    } else {
      __ Bind(entry_label());
      if (compiler::Assembler::EmittingComments()) {
        __ Comment("slow path %s operation (no throw)", name());
      }
    }

    if (has_adjust_sign()) {
      __ Bind(adjust_sign_label());
      if (instruction()->AsBinaryInt64Op()->RightOperandIsPositive()) {
        __ add_d(out_, out_, divisor_);
      } else if (instruction()->AsBinaryInt64Op()->RightOperandIsNegative()) {
        __ sub_d(out_, out_, divisor_);
      } else {
        compiler::Label adjust, done;
        __ bge(divisor_, ZR, &adjust, compiler::Assembler::kNearJump);
        __ sub_d(out_, out_, divisor_);
        __ j(&done, compiler::Assembler::kNearJump);
        __ Bind(&adjust);
        __ add_d(out_, out_, divisor_);
        __ Bind(&done);
      }
      __ j(exit_label());
    }
  }

  const char* name() override { return "int64 divide"; }

  bool has_divide_by_zero() {
    return instruction()->AsBinaryInt64Op()->RightOperandCanBeZero();
  }

  bool has_adjust_sign() { return is_mod_; }

  bool is_needed() { return has_divide_by_zero() || has_adjust_sign(); }

  compiler::Label* adjust_sign_label() {
    ASSERT(has_adjust_sign());
    return &adjust_sign_label_;
  }

 private:
  bool is_mod_;
  Register divisor_;
  Register tmp_;
  Register out_;
  compiler::Label adjust_sign_label_;
};

static void EmitInt64ModTruncDiv(FlowGraphCompiler* compiler,
                                 BinaryInt64OpInstr* instruction,
                                 Token::Kind op_kind,
                                 Register left,
                                 Register right,
                                 Register tmp,
                                 Register out) {
  ASSERT(op_kind == Token::kMOD || op_kind == Token::kTRUNCDIV);

  Int64DivideSlowPath* slow_path =
      new (Z) Int64DivideSlowPath(instruction, right, tmp, out);

  if (slow_path->has_divide_by_zero()) {
    __ beqz(right, slow_path->entry_label());
  }

  if (op_kind == Token::kMOD) {
    __ mod_d(out, left, right);
    __ blt(out, ZR, slow_path->adjust_sign_label());
  } else {
    __ div_d(out, left, right);
  }

  if (slow_path->is_needed()) {
    __ Bind(slow_path->exit_label());
    compiler->AddSlowPathCode(slow_path);
  }
}

static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out,
                                     Register left,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).Value();
  if (shift < 0) {
    __ Stop("Unreachable shift");
    return;
  }

  switch (op_kind) {
    case Token::kSHR:
      __ srai_d(out, left, Utils::Minimum<int64_t>(shift, XLEN - 1));
      break;
    case Token::kUSHR:
      ASSERT(shift < 64);
      __ srli_d(out, left, shift);
      break;
    case Token::kSHL:
      ASSERT(shift < 64);
      __ slli_d(out, left, shift);
      break;
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByRegister(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out,
                                     Register left,
                                     Register right) {
  switch (op_kind) {
    case Token::kSHR:
      __ sra_d(out, left, right);
      break;
    case Token::kUSHR:
      __ srl_d(out, left, right);
      break;
    case Token::kSHL:
      __ sll_d(out, left, right);
      break;
    default:
      UNREACHABLE();
  }
}

class ShiftInt64OpSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit ShiftInt64OpSlowPath(BinaryInt64OpInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry) {}

  const char* name() override { return "int64 shift"; }

  void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) override {
    const Register left = instruction()->locs()->in(0).reg();
    const Register right = instruction()->locs()->in(1).reg();
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT((out != left) && (out != right));

    compiler::Label throw_error;
    __ blt(right, ZR, &throw_error);

    switch (instruction()->AsBinaryInt64Op()->op_kind()) {
      case Token::kSHR:
        __ srai_d(out, left, XLEN - 1);
        break;
      case Token::kUSHR:
      case Token::kSHL:
        __ mv(out, ZR);
        break;
      default:
        UNREACHABLE();
    }
    __ j(exit_label());

    __ Bind(&throw_error);
    __ StoreToOffset(right, THR,
                     compiler::target::Thread::unboxed_runtime_arg_offset());
  }
};

void BinaryInt64OpInstr::EmitShiftInt64(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), out, left,
                             locs()->in(1).constant());
  } else {
    const Register shift = locs()->in(1).reg();

    ShiftInt64OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange()) {
      slow_path = new (Z) ShiftInt64OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);
      __ CompareImmediate(shift, kShiftCountLimit);
      __ BranchIf(HI, slow_path->entry_label());
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out, left, shift);

    if (slow_path != nullptr) {
      __ Bind(slow_path->exit_label());
    }
  }
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!can_overflow());
  if ((op_kind() == Token::kSHL) || (op_kind() == Token::kSHR) ||
      (op_kind() == Token::kUSHR)) {
    EmitShiftInt64(compiler);
    return;
  }

  ASSERT(!CanDeoptimize());
  const Register left = locs()->in(0).reg();
  const Location right = locs()->in(1);
  const Register out = locs()->out(0).reg();

  if ((op_kind() == Token::kMOD) || (op_kind() == Token::kTRUNCDIV)) {
    const Register tmp =
        (op_kind() == Token::kMOD) ? locs()->temp(0).reg() : kNoRegister;
    EmitInt64ModTruncDiv(compiler, this, op_kind(), left, right.reg(), tmp,
                         out);
    return;
  }

  if (right.IsConstant()) {
    int64_t value;
    RELEASE_ASSERT(compiler::HasIntegerValue(right.constant(), &value));
    switch (op_kind()) {
      case Token::kADD:
        __ LoadImmediate(TMP, value);
        __ add_d(out, left, TMP);
        break;
      case Token::kSUB:
        __ LoadImmediate(TMP, value);
        __ sub_d(out, left, TMP);
        break;
      case Token::kMUL:
        __ LoadImmediate(TMP, value);
        __ mul_d(out, left, TMP);
        break;
      case Token::kBIT_AND:
        __ AndImmediate(out, left, value);
        break;
      case Token::kBIT_OR:
        __ OrImmediate(out, left, value);
        break;
      case Token::kBIT_XOR:
        __ XorImmediate(out, left, value);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    const Register right_reg = right.reg();
    switch (op_kind()) {
      case Token::kADD:
        __ add_d(out, left, right_reg);
        break;
      case Token::kSUB:
        __ sub_d(out, left, right_reg);
        break;
      case Token::kMUL:
        __ mul_d(out, left, right_reg);
        break;
      case Token::kBIT_AND:
        __ and_(out, left, right_reg);
        break;
      case Token::kBIT_OR:
        __ or_(out, left, right_reg);
        break;
      case Token::kBIT_XOR:
        __ xor_(out, left, right_reg);
        break;
      default:
        UNREACHABLE();
    }
  }
}

LocationSummary* UnaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::MayBeSameAsFirstInput());
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ XorImmediate(out, left, -1);
      break;
    case Token::kNEGATE:
      __ sub_d(out, ZR, left);
      break;
    default:
      UNREACHABLE();
  }
}

static void EmitInt32Result(FlowGraphCompiler* compiler,
                            Register result,
                            compiler::Label* deopt) {
  if (deopt == nullptr) {
    __ ExtendValue(result, result, compiler::kFourBytes);
  } else {
    __ ExtendValue(TMP, result, compiler::kFourBytes);
    __ bne(TMP, result, deopt);
  }
}

LocationSummary* BinaryInt32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BinaryInt32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp)
          : nullptr;

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(compiler::target::IsSmi(constant));
    const intptr_t value = compiler::target::SmiValue(constant);
    switch (op_kind()) {
      case Token::kADD:
        __ LoadImmediate(TMP, value);
        __ add_d(result, left, TMP);
        EmitInt32Result(compiler, result, deopt);
        break;
      case Token::kSUB:
        __ LoadImmediate(TMP, value);
        __ sub_d(result, left, TMP);
        EmitInt32Result(compiler, result, deopt);
        break;
      case Token::kMUL:
        __ LoadImmediate(TMP, value);
        __ mul_d(result, left, TMP);
        EmitInt32Result(compiler, result, deopt);
        break;
      case Token::kBIT_AND:
        __ AndImmediate(result, left, value);
        EmitInt32Result(compiler, result, nullptr);
        break;
      case Token::kBIT_OR:
        __ OrImmediate(result, left, value);
        EmitInt32Result(compiler, result, nullptr);
        break;
      case Token::kBIT_XOR:
        __ XorImmediate(result, left, value);
        EmitInt32Result(compiler, result, nullptr);
        break;
      case Token::kSHL:
        ASSERT(0 <= value && value < kBitsPerInt32);
        __ slli_d(result, left, value);
        EmitInt32Result(compiler, result, deopt);
        break;
      case Token::kSHR:
        ASSERT(0 <= value && value < kBitsPerInt32);
        __ srai_d(result, left, value);
        break;
      case Token::kUSHR:
        ASSERT(0 <= value && value < kBitsPerInt32);
        __ ExtendValue(TMP, left, compiler::kUnsignedFourBytes);
        __ srli_d(result, TMP, value);
        EmitInt32Result(compiler, result, nullptr);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  const Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
      __ add_d(result, left, right);
      EmitInt32Result(compiler, result, deopt);
      break;
    case Token::kSUB:
      __ sub_d(result, left, right);
      EmitInt32Result(compiler, result, deopt);
      break;
    case Token::kMUL:
      __ mul_d(result, left, right);
      EmitInt32Result(compiler, result, deopt);
      break;
    case Token::kBIT_AND:
      __ and_(result, left, right);
      EmitInt32Result(compiler, result, nullptr);
      break;
    case Token::kBIT_OR:
      __ or_(result, left, right);
      EmitInt32Result(compiler, result, nullptr);
      break;
    case Token::kBIT_XOR:
      __ xor_(result, left, right);
      EmitInt32Result(compiler, result, nullptr);
      break;
    default:
      UNREACHABLE();
  }
}

static void EmitShiftUint32ByConstant(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register out,
                                      Register left,
                                      const Object& right) {
  const int64_t shift = Integer::Cast(right).Value();
  if (shift < 0) {
    __ Stop("Unreachable shift");
    return;
  }

  if (shift >= 32) {
    __ mv(out, ZR);
    return;
  }

  __ ExtendValue(out, left, compiler::kUnsignedFourBytes);
  switch (op_kind) {
    case Token::kSHR:
    case Token::kUSHR:
      __ srli_d(out, out, shift);
      break;
    case Token::kSHL:
      __ slli_d(out, out, shift);
      __ ExtendValue(out, out, compiler::kUnsignedFourBytes);
      break;
    default:
      UNREACHABLE();
  }
}

static void EmitShiftUint32ByRegister(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register out,
                                      Register left,
                                      Register right) {
  __ ExtendValue(out, left, compiler::kUnsignedFourBytes);
  switch (op_kind) {
    case Token::kSHR:
    case Token::kUSHR:
      __ srl_d(out, out, right);
      break;
    case Token::kSHL:
      __ sll_d(out, out, right);
      __ ExtendValue(out, out, compiler::kUnsignedFourBytes);
      break;
    default:
      UNREACHABLE();
  }
}

void BinaryUint32OpInstr::EmitShiftUint32(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
    return;
  }

  const Register right = locs()->in(1).reg();
  EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

  if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
    compiler::Label done;
    __ CompareImmediate(right, kUint32ShiftCountLimit);
    __ BranchIf(LS, &done, compiler::Assembler::kNearJump);
    __ mv(out, ZR);
    __ Bind(&done);
  }
}

LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BinaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if ((op_kind() == Token::kSHL) || (op_kind() == Token::kSHR) ||
      (op_kind() == Token::kUSHR)) {
    EmitShiftUint32(compiler);
    return;
  }

  const Register left = locs()->in(0).reg();
  const Location right = locs()->in(1);
  const Register out = locs()->out(0).reg();

  if (right.IsConstant()) {
    int64_t value;
    RELEASE_ASSERT(compiler::HasIntegerValue(right.constant(), &value));
    switch (op_kind()) {
      case Token::kADD:
        __ LoadImmediate(TMP, value);
        __ add_d(out, left, TMP);
        break;
      case Token::kSUB:
        __ LoadImmediate(TMP, value);
        __ sub_d(out, left, TMP);
        break;
      case Token::kMUL:
        __ LoadImmediate(TMP, value);
        __ mul_d(out, left, TMP);
        break;
      case Token::kBIT_AND:
        __ AndImmediate(out, left, value);
        break;
      case Token::kBIT_OR:
        __ OrImmediate(out, left, value);
        break;
      case Token::kBIT_XOR:
        __ XorImmediate(out, left, value);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    const Register right_reg = right.reg();
    switch (op_kind()) {
      case Token::kADD:
        __ add_d(out, left, right_reg);
        break;
      case Token::kSUB:
        __ sub_d(out, left, right_reg);
        break;
      case Token::kMUL:
        __ mul_d(out, left, right_reg);
        break;
      case Token::kBIT_AND:
        __ and_(out, left, right_reg);
        break;
      case Token::kBIT_OR:
        __ or_(out, left, right_reg);
        break;
      case Token::kBIT_XOR:
        __ xor_(out, left, right_reg);
        break;
      default:
        UNREACHABLE();
    }
  }
  __ ExtendValue(out, out, compiler::kUnsignedFourBytes);
}

LocationSummary* UnaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void UnaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();

  ASSERT(op_kind() == Token::kBIT_NOT);
  __ XorImmediate(out, left, -1);
  __ ExtendValue(out, out, compiler::kUnsignedFourBytes);
}

LocationSummary* DartReturnInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  switch (representation()) {
    case kTagged:
    case kUnboxedInt64:
      locs->set_in(0,
                   Location::RegisterLocation(CallingConventions::kReturnReg));
      break;
    case kPairOfTagged:
      locs->set_in(
          0, Location::Pair(
                 Location::RegisterLocation(CallingConventions::kReturnReg),
                 Location::RegisterLocation(
                     CallingConventions::kSecondReturnReg)));
      break;
    case kUnboxedDouble:
      locs->set_in(
          0, Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg));
      break;
    default:
      UNREACHABLE();
      break;
  }
  return locs;
}

void DartReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler->parsed_function().function().IsAsyncFunction() ||
      compiler->parsed_function().function().IsAsyncGenerator()) {
    ASSERT(compiler->flow_graph().graph_entry()->NeedsFrame());
    const Code& stub = GetReturnStub(compiler);
    compiler->EmitJumpToStub(stub);
    return;
  }

  if (!compiler->flow_graph().graph_entry()->NeedsFrame()) {
    __ ret();
    return;
  }

  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  __ CheckFpSpDist(fp_sp_dist);
  ASSERT(__ constant_pool_allowed());
  __ LeaveDartFrame(fp_sp_dist);
  __ ret();
  __ set_constant_pool_allowed(true);
}

LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  condition()->InitializeLocationSummary(zone, opt);
  return condition()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  BranchLabels labels = {nullptr, nullptr, nullptr};
  Condition true_condition = condition()->EmitConditionCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if ((true_value == 0) || Utils::IsPowerOfTwo(false_value - true_value)) {
    const intptr_t temp = true_value;
    true_value = false_value;
    false_value = temp;
    true_condition = InvertCondition(true_condition);
  }

  const int64_t val = Smi::RawValue(true_value) - Smi::RawValue(false_value);
  if (Utils::IsPowerOfTwo(val)) {
    __ SetIf(true_condition, result);
    __ slli_d(result, result, Utils::ShiftForPowerOfTwo(val));
  } else {
    __ SetIf(InvertCondition(true_condition), result);
    __ AddImmediate(result, result, -1);
    __ AndImmediate(result, result, val);
  }
  if (false_value != 0) {
    __ AddImmediate(result, result, Smi::RawValue(false_value));
  }
}

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(
      0, Location::RegisterLocation(FLAG_precompiled_mode ? T0 : FUNCTION_REG));
  return MakeCallSummary(zone, this, summary);
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);

  if (FLAG_precompiled_mode) {
    ASSERT(locs()->in(0).reg() == T0);
    __ LoadFieldFromOffset(A1, T0,
                           compiler::target::Closure::entry_point_offset());
#if defined(DART_DYNAMIC_MODULES)
    ASSERT(FUNCTION_REG != A1);
    __ LoadCompressedFieldFromOffset(
        FUNCTION_REG, T0, compiler::target::Closure::function_offset());
#endif
  } else {
    ASSERT(locs()->in(0).reg() == FUNCTION_REG);
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     compiler::target::Function::code_offset());
    __ LoadFieldFromOffset(A1, FUNCTION_REG,
                           compiler::target::Function::entry_point_offset());
  }

  if (!FLAG_precompiled_mode) {
    __ LoadImmediate(IC_DATA_REG, 0);
  }
  __ Call(A1);
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 UntaggedPcDescriptors::kOther, locs(), env());
  compiler->EmitDropArguments(argument_count);
}

LocationSummary* TailCallInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, 1, 1, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterLocation(ARGS_DESC_REG));
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}

void TailCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->EmitTailCallToStub(code());

  // Tail calls leave the current Dart frame before jumping to the target stub.
  // Re-enable pool usage for blocks emitted later in this compilation unit.
  __ set_constant_pool_allowed(true);
}

#define R(r) (static_cast<RegList>(1) << (r))

LocationSummary* LeafRuntimeCallInstr::MakeLocationSummary(
    Zone* zone,
    bool is_optimizing) const {
  constexpr Register saved_fp = CallingConventions::kSecondNonArgumentRegister;
  constexpr Register temp0 = CallingConventions::kFfiAnyNonAbiRegister;
  static_assert(saved_fp < temp0, "Unexpected ordering of registers in set.");
  return MakeLocationSummaryInternal(zone, (R(saved_fp) | R(temp0)));
}

#undef R

void LeafRuntimeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = locs()->temp(0).reg();
  const Register temp0 = locs()->temp(1).reg();

  __ MoveRegister(saved_fp, FPREG);

  const intptr_t frame_space = native_calling_convention_.StackTopInBytes();
  __ EnterCFrame(frame_space);

  EmitParamMoves(compiler, saved_fp, temp0);

  const Register target_address = locs()->in(TargetAddressIndex()).reg();
  RELEASE_ASSERT(native_calling_convention_.argument_locations().length() < 4);
  __ Store(target_address,
           compiler::Address(THR, compiler::target::Thread::vm_tag_offset()));
  __ CallCFunction(target_address);
  __ LoadImmediate(temp0, VMTag::kDartTagId);
  __ Store(temp0,
           compiler::Address(THR, compiler::target::Thread::vm_tag_offset()));

  __ LeaveCFrame();
}

LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  __ LoadFromOffset(result, FP,
                    compiler::target::FrameOffsetInBytesForVariable(&local()));
}

LocationSummary* StoreLocalInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return LocationSummary::Make(zone, 1, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(result == value);
  __ StoreToOffset(value, FP,
                   compiler::target::FrameOffsetInBytesForVariable(&local()));
}

LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!locs()->out(0).IsInvalid()) {
    const Register result = locs()->out(0).reg();
    __ LoadObject(result, value());
  }
}

void ConstantInstr::EmitMoveToLocation(FlowGraphCompiler* compiler,
                                       const Location& destination,
                                       Register tmp,
                                       intptr_t pair_index) {
  USE(pair_index);
  if (destination.IsRegister()) {
    const Register dst = destination.reg();
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      __ LoadImmediate(dst, v);
    } else {
      __ LoadObject(dst, value());
    }
  } else if (destination.IsFpuRegister()) {
    switch (representation()) {
      case kUnboxedFloat:
        __ LoadSImmediate(destination.fpu_reg(),
                          compiler::target::DoubleValue(value()));
        break;
      case kUnboxedDouble:
        __ LoadDImmediate(destination.fpu_reg(),
                          compiler::target::DoubleValue(value()));
        break;
      case kUnboxedFloat64x2:
        __ LoadQImmediate(destination.fpu_reg(),
                          Float64x2::Cast(value_).value());
        break;
      case kUnboxedFloat32x4:
        __ LoadQImmediate(destination.fpu_reg(),
                          Float32x4::Cast(value_).value());
        break;
      case kUnboxedInt32x4:
        __ LoadQImmediate(destination.fpu_reg(), Int32x4::Cast(value_).value());
        break;
      default:
        UNREACHABLE();
    }
  } else if (destination.IsDoubleStackSlot()) {
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    if (Utils::DoublesBitEqual(compiler::target::DoubleValue(value()), 0.0)) {
      __ StoreToOffset(ZR, destination.base_reg(), dest_offset);
    } else {
      __ LoadDImmediate(FpuTMP, compiler::target::DoubleValue(value()));
      __ StoreDToOffset(FpuTMP, destination.base_reg(), dest_offset);
    }
  } else if (destination.IsStackSlot()) {
    const Register scratch = tmp == kNoRegister ? TMP : tmp;
    compiler::OperandSize operand_size = compiler::kWordBytes;
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      if (v == 0) {
        __ StoreToOffset(ZR, destination.base_reg(),
                         destination.ToStackSlotOffset(), operand_size);
        return;
      }
      __ LoadImmediate(scratch, v);
    } else if (representation() == kUnboxedFloat) {
      const int32_t float_bits =
          bit_cast<int32_t, float>(compiler::target::DoubleValue(value()));
      __ LoadImmediate(scratch, float_bits);
      operand_size = compiler::kFourBytes;
    } else {
      ASSERT(representation() == kTagged);
      if (value_.IsNull()) {
        __ StoreToOffset(NULL_REG, destination.base_reg(),
                         destination.ToStackSlotOffset(), operand_size);
        return;
      }
      if (value_.IsSmi() && Smi::Cast(value_).Value() == 0) {
        __ StoreToOffset(ZR, destination.base_reg(),
                         destination.ToStackSlotOffset(), operand_size);
        return;
      }
      __ LoadObject(scratch, value_);
    }
    __ StoreToOffset(scratch, destination.base_reg(),
                     destination.ToStackSlotOffset(), operand_size);
  } else {
    ASSERT(destination.IsQuadStackSlot());
    switch (representation()) {
      case kUnboxedFloat64x2:
        __ LoadQImmediate(FpuTMP, Float64x2::Cast(value_).value());
        break;
      case kUnboxedFloat32x4:
        __ LoadQImmediate(FpuTMP, Float32x4::Cast(value_).value());
        break;
      case kUnboxedInt32x4:
        __ LoadQImmediate(FpuTMP, Int32x4::Cast(value_).value());
        break;
      default:
        UNREACHABLE();
    }
    __ StoreQToOffset(FpuTMP, destination.base_reg(),
                      destination.ToStackSlotOffset());
  }
}

LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const bool is_unboxed_int =
      RepresentationUtils::IsUnboxedInteger(representation());
  ASSERT(!is_unboxed_int || RepresentationUtils::ValueSize(representation()) <=
                                compiler::target::kWordSize);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = is_unboxed_int ? 0 : 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (is_unboxed_int) {
    locs->set_out(0, Location::RequiresRegister());
  } else {
    switch (representation()) {
      case kUnboxedDouble:
        locs->set_out(0, Location::RequiresFpuRegister());
        locs->set_temp(0, Location::RequiresRegister());
        break;
      default:
        UNREACHABLE();
    }
  }
  return locs;
}

void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!locs()->out(0).IsInvalid()) {
    const Register scratch =
        RepresentationUtils::IsUnboxedInteger(representation())
            ? kNoRegister
            : locs()->temp(0).reg();
    EmitMoveToLocation(compiler, locs()->out(0), scratch);
  }
}

void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BlockEntryInstr* entry = normal_entry();
  if (entry != nullptr) {
    if (!compiler->CanFallThroughTo(entry)) {
      FATAL("Checked function entry must have no offset");
    }
  } else {
    entry = osr_entry();
    if (!compiler->CanFallThroughTo(entry)) {
      __ j(compiler->GetJumpLabel(entry));
    }
  }
}

LocationSummary* GotoInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}

void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->is_optimizing()) {
    if (FLAG_reorder_basic_blocks) {
      compiler->EmitEdgeCounter(block()->preorder_number());
    }
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
  }
  if (!compiler->CanFallThroughTo(successor())) {
    __ j(compiler->GetJumpLabel(successor()));
  }
}

LocationSummary* IndirectGotoInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 2;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresRegister());
  return summary;
}

void IndirectGotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(RequiredInputRepresentation(0) == kTagged);
  const Register index_reg = locs()->in(0).reg();
  const Register target_address_reg = locs()->temp(0).reg();
  const Register offset_reg = locs()->temp(1).reg();

  __ LoadObject(offset_reg, offsets_);
  const auto element_address = __ ElementAddressForRegIndex(
      /*is_external=*/false, kTypedDataInt32ArrayCid,
      /*index_scale=*/4,
      /*index_unboxed=*/false, offset_reg, index_reg, TMP);
  __ Load(offset_reg, element_address, compiler::kFourBytes);

  const intptr_t entry_offset = __ CodeSize();
  const intptr_t entry_delta = -entry_offset;
  const intptr_t hi20 = PcAddHi20(entry_delta);
  const intptr_t lo12 = SignExtendedLo12(entry_delta);
  ASSERT(Utils::IsInt(20, hi20));
  ASSERT(Utils::IsInt(12, lo12));
  __ pcaddu12i(target_address_reg, hi20);
  __ AddImmediate(target_address_reg, target_address_reg, lo12);
  __ add_d(target_address_reg, target_address_reg, offset_reg);
  __ jr(target_address_reg);
}

LocationSummary* BranchInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  condition()->InitializeLocationSummary(zone, opt);
  // Branches don't produce a result.
  condition()->locs()->set_out(0, Location::NoLocation());
  return condition()->locs();
}

void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  condition()->EmitBranchCode(compiler, this);
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // Pass a pointer to the first argument to the native-call wrapper stub.
  __ AddImmediate(T6, SP, (ArgumentCount() - 1) * kWordSize);

  uword entry;
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const Code* stub;
  if (link_lazily()) {
    stub = &StubCode::CallBootstrapNative();
    entry = NativeEntry::LinkNativeCallEntry();
  } else {
    entry = reinterpret_cast<uword>(native_c_function());
    if (is_bootstrap_native()) {
      stub = &StubCode::CallBootstrapNative();
    } else if (is_auto_scope()) {
      stub = &StubCode::CallAutoScopeNative();
    } else {
      stub = &StubCode::CallNoScopeNative();
    }
  }

  __ LoadImmediate(T1, argc_tag);
  compiler::ExternalLabel label(entry);
  __ LoadNativeEntry(T5, &label,
                     link_lazily() ? ObjectPool::Patchability::kPatchable
                                   : ObjectPool::Patchability::kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs(),
        compiler::ObjectPoolBuilderEntry::kResetToBootstrapNative);
  } else {
    ASSERT(!compiler->is_optimizing());
    compiler->GenerateNonLazyDeoptableStubCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs(),
        compiler::ObjectPoolBuilderEntry::kNotSnapshotable);
  }
  __ LoadFromOffset(result, SP, 0);
  compiler->EmitDropArguments(ArgumentCount());
}

#define R(r) (static_cast<RegList>(1) << (r))

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(CallingConventions::kSecondNonArgumentRegister) |
       R(CallingConventions::kFfiAnyNonAbiRegister) | R(CALLEE_SAVED_TEMP)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register target = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  const Register temp1 = locs()->temp(0).reg();
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves. For leaf calls, this holds the pre-aligned SP.
  const Register saved_fp_or_sp = locs()->temp(1).reg();
  const Register temp2 = locs()->temp(2).reg();

  ASSERT(temp1 != target);
  ASSERT(temp2 != target);
  ASSERT(temp1 != saved_fp_or_sp);
  ASSERT(temp2 != saved_fp_or_sp);
  ASSERT(saved_fp_or_sp != target);
  ASSERT(IsCalleeSavedRegister(saved_fp_or_sp));

  __ MoveRegister(saved_fp_or_sp, is_leaf_ ? SPREG : FPREG);

  if (!is_leaf_) {
    if (FLAG_precompiled_mode) {
      __ AddImmediate(SP, SP, -2 * compiler::target::kWordSize);
      __ Store(RA, compiler::Address(SP, 1 * compiler::target::kWordSize));
      __ Store(FP, compiler::Address(SP, 0 * compiler::target::kWordSize));
      __ AddImmediate(FP, SP, 2 * compiler::target::kWordSize);
    } else {
      __ AddImmediate(SP, SP, -4 * compiler::target::kWordSize);
      __ Store(RA, compiler::Address(SP, 3 * compiler::target::kWordSize));
      __ Store(FP, compiler::Address(SP, 2 * compiler::target::kWordSize));
      __ Store(NULL_REG,
               compiler::Address(SP, 1 * compiler::target::kWordSize));
      __ Store(NULL_REG,
               compiler::Address(SP, 0 * compiler::target::kWordSize));
      __ AddImmediate(FP, SP, 4 * compiler::target::kWordSize);
    }
  }

  const intptr_t stack_space = marshaller_.RequiredStackSpaceInBytes();
  __ ReserveAlignedFrameSpace(stack_space);
  if (FLAG_target_memory_sanitizer) {
    RegisterSet volatile_registers(kAbiVolatileCpuRegs, kAbiVolatileFpuRegs);
    __ MoveRegister(temp1, SP);
    __ PushRegisters(volatile_registers);

    __ MoveRegister(A0, temp1);
    __ LoadImmediate(A1, stack_space);
    __ CallCFunction(
        compiler::Address(THR, kMsanUnpoisonRuntimeEntry.OffsetFromThread()));

    __ MoveRegister(A0, is_leaf_ ? FPREG : saved_fp_or_sp);
    __ LoadImmediate(A1, (kParamEndSlotFromFp + InputCount()) * kWordSize);
    __ CallCFunction(
        compiler::Address(THR, kMsanUnpoisonRuntimeEntry.OffsetFromThread()));

    __ LoadImmediate(A0, InputCount());
    __ CallCFunction(compiler::Address(
        THR, kMsanUnpoisonParamRuntimeEntry.OffsetFromThread()));

    __ PopRegisters(volatile_registers);
  }

  EmitParamMoves(compiler, is_leaf_ ? FPREG : saved_fp_or_sp, temp1, temp2);

  if (compiler::Assembler::EmittingComments()) {
    __ Comment(is_leaf_ ? "Leaf Call" : "Call");
  }

  if (is_leaf_) {
#if !defined(PRODUCT)
    __ StoreToOffset(FPREG, THR,
                     compiler::target::Thread::top_exit_frame_info_offset());
    __ StoreToOffset(target, THR,
                     compiler::target::Thread::vm_tag_offset());
#endif

    __ MoveRegister(A3, T3);
    __ MoveRegister(A4, T4);
    __ MoveRegister(A5, T5);
    __ Call(target);

#if !defined(PRODUCT)
    __ LoadImmediate(temp1, compiler::target::Thread::vm_tag_dart_id());
    __ StoreToOffset(temp1, THR,
                     compiler::target::Thread::vm_tag_offset());
    __ StoreToOffset(ZR, THR,
                     compiler::target::Thread::top_exit_frame_info_offset());
#endif
  } else {
    compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());
    __ pcaddu12i(temp1, 0);
    __ StoreToOffset(temp1, FPREG, kSavedCallerPcSlotFromFp * kWordSize);

    if (CanExecuteGeneratedCodeInSafepoint()) {
      __ LoadImmediate(temp1, compiler::target::Thread::exit_through_ffi());
      __ TransitionGeneratedToNative(target, FPREG, temp1,
                                     /*enter_safepoint=*/true);

      __ MoveRegister(A3, T3);
      __ MoveRegister(A4, T4);
      __ MoveRegister(A5, T5);
      __ Call(target);

      __ TransitionNativeToGenerated(temp1, /*exit_safepoint=*/true);
    } else {
      __ Load(temp1,
              compiler::Address(
                  THR, compiler::target::Thread::
                           call_native_through_safepoint_entry_point_offset()));

      ASSERT(target == T0);
      __ MoveRegister(A3, T3);
      __ MoveRegister(A4, T4);
      __ MoveRegister(A5, T5);
      __ Call(temp1);
    }

    if (marshaller_.IsHandleCType(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      ASSERT(temp1 != CallingConventions::kReturnReg);
      ASSERT(temp2 != CallingConventions::kReturnReg);
      compiler::Label not_error;
      __ LoadFromOffset(temp1, CallingConventions::kReturnReg,
                        compiler::target::LocalHandle::ptr_offset());
      __ BranchIfSmi(temp1, &not_error);
      __ LoadClassId(temp1, temp1);
      __ RangeCheck(temp1, temp2, kFirstErrorCid, kLastErrorCid,
                    compiler::AssemblerBase::kIfNotInRange, &not_error);

      __ Comment("Slow path: call Dart_PropagateError through stub.");
      ASSERT(CallingConventions::ArgumentRegisters[0] ==
             CallingConventions::kReturnReg);
      __ Load(temp1,
              compiler::Address(
                  THR, compiler::target::Thread::
                           call_native_through_safepoint_entry_point_offset()));
      __ Load(target, compiler::Address(
                          THR, kPropagateErrorRuntimeEntry.OffsetFromThread()));
      __ Call(temp1);
#if defined(DEBUG)
      __ Breakpoint();
#endif

      __ Bind(&not_error);
    }

    __ RestorePinnedRegisters();
  }

  EmitReturnMoves(compiler, temp1, temp2);

  if (is_leaf_) {
    __ MoveRegister(SPREG, saved_fp_or_sp);
  } else {
    __ LeaveDartFrame();

    if (FLAG_precompiled_mode) {
      __ SetupGlobalPoolAndDispatchTable();
    }
  }

  __ RestorePoolPointer();
  __ set_constant_pool_allowed(true);
}

void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ set_constant_pool_allowed(false);

  __ Bind(compiler->GetJumpLabel(this));

  // Create a dummy frame holding the pushed arguments. This simplifies
  // NativeReturnInstr::EmitNativeCode.
  __ EnterFrame(0);

  __ MoveRegister(T3, A3);
  __ MoveRegister(T4, A4);
  __ MoveRegister(T5, A5);
  SaveArguments(compiler);

  // Enter the entry frame. NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  __ EnterFrame(0);

  __ PushImmediate(0);
  __ PushNativeCalleeSavedRegisters();

  __ RestorePinnedRegisters();

  __ LoadFromOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());
  __ LoadFromOffset(A0, THR, compiler::target::Thread::top_resource_offset());
  __ PushRegisterPair(A0, TMP);
  ASSERT(kVMTagOffsetFromFp == 5 * compiler::target::kWordSize);

  __ StoreToOffset(ZR, THR,
                   compiler::target::Thread::top_resource_offset());

  __ LoadFromOffset(A0, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ PushRegister(A0);

  __ LoadFromOffset(A0, THR,
                    compiler::target::Thread::top_exit_frame_info_offset());
  __ PushRegister(A0);

  __ EmitEntryFrameVerification();

  // The callback trampoline has already left the safepoint for us.
  __ TransitionNativeToGenerated(A0, /*exit_safepoint=*/false,
                                 /*set_tag=*/false);

  const Function& target_function = marshaller_.dart_signature();
  const intptr_t callback_id = target_function.FfiCallbackId();
  __ LoadFromOffset(A0, THR, compiler::target::Thread::isolate_group_offset());
  __ LoadFromOffset(A0, A0,
                    compiler::target::IsolateGroup::object_store_offset());
  __ LoadFromOffset(A0, A0,
                    compiler::target::ObjectStore::ffi_callback_code_offset());
  __ LoadCompressedFieldFromOffset(
      A0, A0, compiler::target::GrowableObjectArray::data_offset());
  __ LoadCompressedFieldFromOffset(
      CODE_REG, A0,
      compiler::target::Array::data_offset() +
          callback_id * compiler::target::kCompressedWordSize);

  __ StoreToOffset(CODE_REG, FPREG,
                   kPcMarkerSlotFromFp * compiler::target::kWordSize);
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadObject(PP, compiler::NullObject());
  }

  __ MoveRegister(ARGS_DESC_REG, ZR);

  __ LoadFromOffset(RA, THR,
                    compiler::target::Thread::invoke_dart_code_stub_offset());
  __ LoadFieldFromOffset(RA, RA,
                         compiler::target::Code::entry_point_offset());

  FunctionEntryInstr::EmitNativeCode(compiler);

  __ LoadImmediate(TMP, compiler::target::Thread::vm_tag_dart_id());
  __ StoreToOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());
}

void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  __ LoadFromOffset(TMP, FP, NativeEntryInstr::kVMTagOffsetFromFp);
  __ StoreToOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());

  __ LeaveDartFrame();

  const Register vm_tag_reg = T6;
  const Register old_exit_frame_reg = T3;
  const Register old_exit_through_ffi_reg = T4;
  const Register tmp = T5;

  __ PopRegisterPair(old_exit_frame_reg, old_exit_through_ffi_reg);

  __ PopRegisterPair(tmp, vm_tag_reg);
  __ StoreToOffset(tmp, THR, compiler::target::Thread::top_resource_offset());

  __ TransitionGeneratedToNative(vm_tag_reg, old_exit_frame_reg,
                                 old_exit_through_ffi_reg,
                                 /*enter_safepoint=*/false);

  __ PopNativeCalleeSavedRegisters();

  __ LeaveFrame();
  __ LeaveFrame();
  __ Ret();

  __ set_constant_pool_allowed(true);
}

LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition DoubleTestOpInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                               BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const FRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;

  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      __ fcmp_ceq_d(value, value);
      __ movcf2gr(TMP);
      __ CompareImmediate(TMP, 0);
      return is_negated ? NE : EQ;
    case MethodRecognizer::kDouble_getIsInfinite:
      __ movfr2gr_d(TMP, value);
      __ slli_d(TMP, TMP, 1);
      __ srli_d(TMP, TMP, 1);
      __ CompareImmediate(TMP, 0x7FF0000000000000LL);
      return is_negated ? NE : EQ;
    case MethodRecognizer::kDouble_getIsNegative:
      __ fcmp_ceq_d(value, value);
      __ movcf2gr(TMP);
      __ CompareImmediate(TMP, 0);
      __ BranchIf(EQ, is_negated ? labels.true_label : labels.false_label);
      __ movfr2gr_d(TMP, value);
      __ CompareImmediate(TMP, 0);
      return is_negated ? GE : LT;
    default:
      UNREACHABLE();
  }
}

static Condition EmitIntegerComparisonOp(FlowGraphCompiler* compiler,
                                         const LocationSummary& locs,
                                         Token::Kind kind,
                                         Representation representation);

LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (is_null_aware()) {
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, Location::RequiresRegister());
  } else if (input_representation() == kUnboxedDouble) {
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
  } else {
    ASSERT((input_representation() == kTagged) ||
           (input_representation() == kUnboxedInt64) ||
           (input_representation() == kUnboxedInt32) ||
           (input_representation() == kUnboxedUint32));
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, LocationRegisterOrConstant(right()));
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ SmiUntag(TMP, value);
  __ movgr2fr_d(FpuTMP, TMP);
  __ ffint_d_l(result, FpuTMP);
}

LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}

void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister left = locs()->in(0).fpu_reg();
  const FRegister right = locs()->in(1).fpu_reg();
  const FRegister result = locs()->out(0).fpu_reg();
  if (representation() == kUnboxedDouble) {
    switch (op_kind()) {
      case Token::kADD:
        __ fadd_d(result, left, right);
        break;
      case Token::kSUB:
        __ fsub_d(result, left, right);
        break;
      case Token::kMUL:
        __ fmul_d(result, left, right);
        break;
      case Token::kDIV:
        __ fdiv_d(result, left, right);
        break;
      case Token::kMIN:
        __ fmin_d(result, left, right);
        break;
      case Token::kMAX:
        __ fmax_d(result, left, right);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    ASSERT(representation() == kUnboxedFloat);
    switch (op_kind()) {
      case Token::kADD:
        __ fadd_s(result, left, right);
        break;
      case Token::kSUB:
        __ fsub_s(result, left, right);
        break;
      case Token::kMUL:
        __ fmul_s(result, left, right);
        break;
      case Token::kDIV:
        __ fdiv_s(result, left, right);
        break;
      case Token::kMIN:
        __ fmin_s(result, left, right);
        break;
      case Token::kMAX:
        __ fmax_s(result, left, right);
        break;
      default:
        UNREACHABLE();
    }
  }
}

LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}

void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister result = locs()->out(0).fpu_reg();
  const FRegister value = locs()->in(0).fpu_reg();
  if (representation() == kUnboxedDouble) {
    switch (op_kind()) {
      case Token::kABS:
        __ fabs_d(result, value);
        break;
      case Token::kNEGATE:
        __ fneg_d(result, value);
        break;
      case Token::kSQRT:
        __ fsqrt_d(result, value);
        break;
      case Token::kSQUARE:
        __ fmul_d(result, value, value);
        break;
      case Token::kTRUNCATE:
        __ ftintrz_l_d(FpuTMP, value);
        __ ffint_d_l(result, FpuTMP);
        break;
      case Token::kFLOOR:
        __ ftintrm_l_d(FpuTMP, value);
        __ ffint_d_l(result, FpuTMP);
        break;
      case Token::kCEILING:
        __ ftintrp_l_d(FpuTMP, value);
        __ ffint_d_l(result, FpuTMP);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    ASSERT(representation() == kUnboxedFloat);
    switch (op_kind()) {
      case Token::kABS:
        __ fabs_s(result, value);
        break;
      case Token::kNEGATE:
        __ fneg_s(result, value);
        break;
      case Token::kRECIPROCAL:
        __ LoadImmediate(TMP, 1);
        __ movgr2fr_d(FpuTMP, TMP);
        __ ffint_s_l(FpuTMP, FpuTMP);
        __ fdiv_s(result, FpuTMP, value);
        break;
      case Token::kRECIPROCAL_SQRT:
        __ LoadImmediate(TMP, 1);
        __ movgr2fr_d(FpuTMP, TMP);
        __ ffint_s_l(FpuTMP, FpuTMP);
        __ fdiv_s(result, FpuTMP, value);
        __ fsqrt_s(result, result);
        break;
      case Token::kSQRT:
        __ fsqrt_s(result, value);
        break;
      case Token::kSQUARE:
        __ fmul_s(result, value, value);
        break;
      case Token::kTRUNCATE:
        __ ftintrz_l_s(FpuTMP, value);
        __ ffint_s_l(result, FpuTMP);
        break;
      case Token::kFLOOR:
        __ ftintrm_l_s(FpuTMP, value);
        __ ffint_s_l(result, FpuTMP);
        break;
      case Token::kCEILING:
        __ ftintrp_l_s(FpuTMP, value);
        __ ffint_s_l(result, FpuTMP);
        break;
      default:
        UNREACHABLE();
    }
  }
}

LocationSummary* Int32ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void Int32ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ movgr2fr_d(FpuTMP, value);
  __ ffint_d_w(result, FpuTMP);
}

LocationSummary* Int64ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ movgr2fr_d(FpuTMP, value);
  __ ffint_d_l(result, FpuTMP);
}

LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister value = locs()->in(0).fpu_reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ fcvt_s_d(result, value);
}

LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister value = locs()->in(0).fpu_reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ fcvt_d_s(result, value);
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone) LocationSummary(
      zone, InputCount(), kNumTemps, LocationSummary::kNativeLeafCall);
  result->set_in(0, Location::FpuRegisterLocation(FA0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(FA1));
  }
  result->set_out(0, Location::FpuRegisterLocation(FA0));
  return result;
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const bool preserve_intrinsic_registers = compiler->intrinsic_mode();
  if (preserve_intrinsic_registers) {
    __ PushRegister(CODE_REG);
    __ PushRegister(ARGS_DESC_REG);
  }

  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/0,
                                /*preserve_registers=*/false);
  ASSERT(locs()->in(0).fpu_reg() == FA0);
  if (InputCount() == 2) {
    ASSERT(locs()->in(1).fpu_reg() == FA1);
  }
  rt.Call(TargetFunction(), InputCount());
  ASSERT(locs()->out(0).fpu_reg() == FA0);

  if (preserve_intrinsic_registers) {
    __ PopRegister(ARGS_DESC_REG);
    __ PopRegister(CODE_REG);
  }
}

LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 1;
  LocationSummary* summary =
      new (zone) LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    if (index() == 0) {
      summary->set_in(
          0, Location::Pair(Location::RequiresFpuRegister(), Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(
          0, Location::Pair(Location::Any(), Location::RequiresFpuRegister()));
    }
    summary->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(representation() == kTagged);
    if (index() == 0) {
      summary->set_in(
          0, Location::Pair(Location::RequiresRegister(), Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(
          0, Location::Pair(Location::Any(), Location::RequiresRegister()));
    }
    summary->set_out(0, Location::RequiresRegister());
  }
  return summary;
}

void ExtractNthOutputInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).IsPairLocation());
  PairLocation* pair = locs()->in(0).AsPairLocation();
  Location in_loc = pair->At(index());
  if (representation() == kUnboxedDouble) {
    const FRegister out = locs()->out(0).fpu_reg();
    const FRegister in = in_loc.fpu_reg();
    __ fmov_d(out, in);
  } else {
    ASSERT(representation() == kTagged);
    const Register out = locs()->out(0).reg();
    const Register in = in_loc.reg();
    __ MoveRegister(out, in);
  }
}

LocationSummary* TruncDivModInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}

void TruncDivModInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(CanDeoptimize());
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  ASSERT(locs()->out(0).IsPairLocation());
  const PairLocation* pair = locs()->out(0).AsPairLocation();
  const Register result_div = pair->At(0).reg();
  const Register result_mod = pair->At(1).reg();

  if (RangeUtils::CanBeZero(divisor_range())) {
    __ beqz(right, deopt);
  }

  __ SmiUntag(TMP, left);
  __ SmiUntag(TMP2, right);
  __ div_d(result_div, TMP, TMP2);
  __ mod_d(result_mod, TMP, TMP2);

  compiler::Label done, adjust;
  __ CompareObjectRegisters(result_mod, ZR);
  __ BranchIf(GE, &done, compiler::Assembler::kNearJump);
  if (RangeUtils::IsNegative(divisor_range())) {
    __ sub_d(result_mod, result_mod, TMP2);
  } else if (RangeUtils::IsPositive(divisor_range())) {
    __ add_d(result_mod, result_mod, TMP2);
  } else {
    __ CompareObjectRegisters(TMP2, ZR);
    __ BranchIf(GE, &adjust, compiler::Assembler::kNearJump);
    __ sub_d(result_mod, result_mod, TMP2);
    __ j(&done, compiler::Assembler::kNearJump);
    __ Bind(&adjust);
    __ add_d(result_mod, result_mod, TMP2);
  }
  __ Bind(&done);

  if (RangeUtils::Overlaps(divisor_range(), -1, -1)) {
    __ MoveRegister(TMP, result_div);
    __ SmiTag(result_div);
    __ SmiTag(result_mod);
    __ SmiUntag(TMP2, result_div);
    __ bne(TMP, TMP2, deopt);
  } else {
    __ SmiTag(result_div);
    __ SmiTag(result_mod);
  }
}

static void EmitDoubleToIntegerConversion(FlowGraphCompiler* compiler,
                                          MethodRecognizer::Kind kind,
                                          FRegister value,
                                          Register result,
                                          compiler::Label* failure) {
  __ fcmp_ceq_d(value, value);
  __ movcf2gr(TMP);
  __ CompareImmediate(TMP, 0);
  __ BranchIf(EQ, failure);

  switch (kind) {
    case MethodRecognizer::kDoubleToInteger:
      __ ftintrz_l_d(FpuTMP, value);
      break;
    case MethodRecognizer::kDoubleFloorToInt:
      __ ftintrm_l_d(FpuTMP, value);
      break;
    case MethodRecognizer::kDoubleCeilToInt:
      __ ftintrp_l_d(FpuTMP, value);
      break;
    default:
      UNREACHABLE();
  }

  __ movfr2gr_d(TMP, FpuTMP);
  __ SmiTag(result, TMP);
  __ SmiUntag(TMP2, result);
  __ bne(TMP, TMP2, failure);
}

LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister value = locs()->in(0).fpu_reg();
  const Register result = locs()->out(0).reg();
  DoubleToIntegerSlowPath* slow_path = new DoubleToIntegerSlowPath(this, value);
  compiler->AddSlowPathCode(slow_path);
  EmitDoubleToIntegerConversion(compiler, recognized_kind(), value, result,
                                slow_path->entry_label());
  __ Bind(slow_path->exit_label());
}

LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}

void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  const FRegister value = locs()->in(0).fpu_reg();
  const Register result = locs()->out(0).reg();
  EmitDoubleToIntegerConversion(compiler, MethodRecognizer::kDoubleToInteger,
                                value, result, deopt);
}

LocationSummary* FloatCompareInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_in(1, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}

void FloatCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FRegister lhs = locs()->in(0).fpu_reg();
  const FRegister rhs = locs()->in(1).fpu_reg();
  const Register result = locs()->out(0).reg();

  switch (op_kind()) {
    case Token::kEQ:
      __ fcmp_ceq_s(lhs, rhs);
      break;
    case Token::kLT:
      __ fcmp_clt_s(lhs, rhs);
      break;
    case Token::kLTE:
      __ fcmp_cle_s(lhs, rhs);
      break;
    case Token::kGT:
      __ fcmp_clt_s(rhs, lhs);
      break;
    case Token::kGTE:
      __ fcmp_cle_s(rhs, lhs);
      break;
    default:
      UNREACHABLE();
  }
  __ movcf2gr(result);
  __ sub_d(result, ZR, result);
}

LocationSummary* MathMinMaxInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresFpuRegister());
    return summary;
  }

  ASSERT(representation() == kUnboxedInt64);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void MathMinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((op_kind() == MethodRecognizer::kMathMin) ||
         (op_kind() == MethodRecognizer::kMathMax));
  const bool is_min = (op_kind() == MethodRecognizer::kMathMin);
  if (representation() == kUnboxedDouble) {
    const FRegister left = locs()->in(0).fpu_reg();
    const FRegister right = locs()->in(1).fpu_reg();
    const FRegister result = locs()->out(0).fpu_reg();
    compiler::Label return_nan, done;
    __ fcmp_ceq_d(left, left);
    __ movcf2gr(TMP);
    __ beq(TMP, ZR, &return_nan, compiler::Assembler::kNearJump);
    __ fcmp_ceq_d(right, right);
    __ movcf2gr(TMP);
    __ beq(TMP, ZR, &return_nan, compiler::Assembler::kNearJump);
    if (is_min) {
      __ fmin_d(result, left, right);
    } else {
      __ fmax_d(result, left, right);
    }
    __ j(&done, compiler::Assembler::kNearJump);
    __ Bind(&return_nan);
    __ LoadDImmediate(result, NAN);
    __ Bind(&done);
    return;
  }

  ASSERT(representation() == kUnboxedInt64);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(result == left);
  compiler::Label done;
  if (is_min) {
    __ blt(left, right, &done, compiler::Assembler::kNearJump);
  } else {
    __ blt(right, left, &done, compiler::Assembler::kNearJump);
  }
  __ MoveRegister(result, right);
  __ Bind(&done);
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  USE(labels);
  const FRegister left = locs.in(0).fpu_reg();
  const FRegister right = locs.in(1).fpu_reg();

  Condition true_condition = NE;
  switch (kind) {
    case Token::kEQ:
      __ fcmp_ceq_d(left, right);
      break;
    case Token::kNE:
      __ fcmp_ceq_d(left, right);
      true_condition = EQ;
      break;
    case Token::kLT:
      __ fcmp_clt_d(left, right);
      break;
    case Token::kGT:
      __ fcmp_clt_d(right, left);
      break;
    case Token::kLTE:
      __ fcmp_cle_d(left, right);
      break;
    case Token::kGTE:
      __ fcmp_cle_d(right, left);
      break;
    default:
      UNREACHABLE();
  }

  __ movcf2gr(TMP);
  __ CompareImmediate(TMP, 0);
  return true_condition;
}

static Condition EmitNullAwareInt64ComparisonOp(FlowGraphCompiler* compiler,
                                                const LocationSummary& locs,
                                                Token::Kind kind,
                                                BranchLabels labels) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const Register left = locs.in(0).reg();
  const Register right = locs.in(1).reg();
  const Condition true_condition =
      TokenKindToIntCondition(kind, /*is_unsigned=*/false);
  compiler::Label* equal_result =
      (true_condition == EQ) ? labels.true_label : labels.false_label;
  compiler::Label* not_equal_result =
      (true_condition == EQ) ? labels.false_label : labels.true_label;

  __ CompareObjectRegisters(left, right);
  __ BranchIf(EQ, equal_result);
  __ and_(TMP, left, right);
  __ BranchIfSmi(TMP, not_equal_result);
  __ CompareClassId(left, kMintCid, TMP);
  __ BranchIf(NE, not_equal_result);
  __ CompareClassId(right, kMintCid, TMP);
  __ BranchIf(NE, not_equal_result);
  __ LoadFieldFromOffset(TMP, left, Mint::value_offset());
  __ LoadFieldFromOffset(TMP2, right, Mint::value_offset());
  __ CompareRegisters(TMP, TMP2);
  return true_condition;
}

Condition EqualityCompareInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                                  BranchLabels labels) {
  if (is_null_aware()) {
    return EmitNullAwareInt64ComparisonOp(compiler, *locs(), kind(), labels);
  }
  switch (input_representation()) {
    case kTagged:
    case kUnboxedInt64:
    case kUnboxedInt32:
    case kUnboxedUint32:
      return EmitIntegerComparisonOp(compiler, *locs(), kind(),
                                     input_representation());
    case kUnboxedDouble:
      return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
    default:
      UNREACHABLE();
  }
}

static Condition EmitIntegerComparisonOp(FlowGraphCompiler* compiler,
                                         const LocationSummary& locs,
                                         Token::Kind kind,
                                         Representation representation) {
  const bool is_unsigned = representation == kUnboxedUint32;
  const Condition true_condition = TokenKindToIntCondition(kind, is_unsigned);
  const Location left = locs.in(0);
  const Location right = locs.in(1);
  if (right.IsConstant()) {
    if (representation == kTagged) {
      __ CompareObject(left.reg(), right.constant());
    } else {
      int64_t value = 0;
      RELEASE_ASSERT(compiler::HasIntegerValue(right.constant(), &value));
      __ CompareImmediate(left.reg(), value);
    }
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }
  return true_condition;
}

LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (input_representation() == kUnboxedDouble) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  ASSERT((input_representation() == kTagged) ||
         (input_representation() == kUnboxedInt64) ||
         (input_representation() == kUnboxedInt32) ||
         (input_representation() == kUnboxedUint32));
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, LocationRegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition RelationalOpInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                               BranchLabels labels) {
  USE(labels);
  switch (input_representation()) {
    case kTagged:
    case kUnboxedInt64:
    case kUnboxedInt32:
    case kUnboxedUint32:
      return EmitIntegerComparisonOp(compiler, *locs(), kind(),
                                     input_representation());
    case kUnboxedDouble:
      return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
    default:
      UNREACHABLE();
  }
}

LocationSummary* TestCidsInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition TestCidsInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
  const Register val_reg = locs()->in(0).reg();
  const Register cid_reg = locs()->temp(0).reg();

  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids)
          : nullptr;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ BranchIfSmi(val_reg, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);

  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ CompareImmediate(cid_reg, test_cid);
    __ BranchIf(EQ, result ? labels.true_label : labels.false_label);
  }

  if (deopt == nullptr) {
    compiler::Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ j(target);
    }
  } else {
    __ j(deopt);
  }
  return kInvalidCondition;
}

LocationSummary* TestIntInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, LocationRegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition TestIntInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                          BranchLabels labels) {
  const Register left = locs()->in(0).reg();
  const Location right = locs()->in(1);
  if (right.IsConstant()) {
    __ TestImmediate(left, ComputeImmediateMask());
  } else {
    __ TestRegisters(left, right.reg());
  }
  return (kind() == Token::kNE) ? NE : EQ;
}

static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor we will fall through to it.
    __ BranchIf(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor we will branch to it.
    const Condition false_condition = InvertCondition(true_condition);
    __ BranchIf(false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ j(labels.true_label);
    }
  }
}

void ConditionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  const Condition true_condition = EmitConditionCode(compiler, labels);

  const Register result = locs()->out(0).reg();
  if (is_true.IsLinked() || is_false.IsLinked()) {
    if (true_condition != kInvalidCondition) {
      EmitBranchOnCondition(compiler, true_condition, labels);
    }
    compiler::Label done;
    __ Bind(&is_false);
    __ LoadObject(result, Bool::False());
    __ j(&done, compiler::Assembler::kNearJump);
    __ Bind(&is_true);
    __ LoadObject(result, Bool::True());
    __ Bind(&done);
  } else {
    ASSERT(true_condition != kInvalidCondition);
    EmitBranchOnCondition(compiler, true_condition, labels);
    compiler::Label done;
    __ Bind(&is_false);
    __ LoadObject(result, Bool::False());
    __ j(&done, compiler::Assembler::kNearJump);
    __ Bind(&is_true);
    __ LoadObject(result, Bool::True());
    __ Bind(&done);
  }
}

void ConditionInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                    BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  const Condition true_condition = EmitConditionCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
}

LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register input = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ xori(result, input, compiler::target::ObjectAlignment::kBoolValueMask);
}

LocationSummary* BoolToIntInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void BoolToIntInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register input = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadObject(TMP, Bool::True());
  __ CompareObjectRegisters(input, TMP);
  __ SetIf(EQ, result);
  __ sub_d(result, ZR, result);
}

LocationSummary* IntToBoolInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void IntToBoolInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register input = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  compiler::Label is_false, done;
  __ CompareImmediate(input, 0);
  __ BranchIf(NE, &is_false, compiler::Assembler::kNearJump);
  __ LoadObject(result, Bool::True());
  __ j(&done, compiler::Assembler::kNearJump);
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ Bind(&done);
}

Condition StrictCompareInstr::EmitComparisonCodeRegConstant(
    FlowGraphCompiler* compiler,
    BranchLabels labels,
    Register reg,
    const Object& obj) {
  USE(labels);
  return compiler->EmitEqualityRegConstCompare(reg, obj, needs_number_check(),
                                               source(), deopt_id());
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(A0));
    locs->set_in(1, Location::RegisterLocation(A1));
    locs->set_out(0, Location::RegisterLocation(A0));
    return locs;
  }
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, LocationRegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  ASSERT((!IsTypedDataBaseClassId(src_cid_) &&
          !IsTypedDataBaseClassId(dest_cid_)) ||
         opt);
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = 2;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::RequiresRegister());
  locs->set_in(kDestPos, Location::RequiresRegister());
  locs->set_in(kSrcStartPos, LocationRegisterOrSmiConstant(src_start()));
  locs->set_in(kDestStartPos, LocationRegisterOrSmiConstant(dest_start()));
  locs->set_in(kLengthPos,
               LocationWritableRegisterOrSmiConstant(length(), 0, 4));
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_temp(1, Location::RequiresRegister());
  return locs;
}

void MemoryCopyInstr::PrepareLengthRegForLoop(FlowGraphCompiler* compiler,
                                              Register length_reg,
                                              compiler::Label* done) {
  __ BranchIfZero(length_reg, done);
}

static compiler::OperandSize OperandSizeFor(intptr_t bytes) {
  ASSERT(Utils::IsPowerOfTwo(bytes));
  switch (bytes) {
    case 1:
      return compiler::kUnsignedByte;
    case 2:
      return compiler::kUnsignedTwoBytes;
    case 4:
      return compiler::kUnsignedFourBytes;
    case 8:
      return compiler::kEightBytes;
    default:
      UNREACHABLE();
      return compiler::kEightBytes;
  }
}

static void CopyBytes(FlowGraphCompiler* compiler,
                      Register dest_reg,
                      Register src_reg,
                      intptr_t count,
                      bool reversed) {
  ASSERT(Utils::IsPowerOfTwo(count));
  if (count == 2 * (XLEN / 8)) {
    auto const sz = OperandSizeFor(XLEN / 8);
    const intptr_t offset = (reversed ? -1 : 1) * (XLEN / 8);
    const intptr_t initial = reversed ? offset : 0;
    __ LoadFromOffset(TMP, src_reg, initial, sz);
    __ LoadFromOffset(TMP2, src_reg, initial + offset, sz);
    __ AddImmediate(src_reg, src_reg, 2 * offset);
    __ StoreToOffset(TMP, dest_reg, initial, sz);
    __ StoreToOffset(TMP2, dest_reg, initial + offset, sz);
    __ AddImmediate(dest_reg, dest_reg, 2 * offset);
    return;
  }

  ASSERT(count <= (XLEN / 8));
  auto const sz = OperandSizeFor(count);
  const intptr_t offset = (reversed ? -1 : 1) * count;
  const intptr_t initial = reversed ? offset : 0;
  __ LoadFromOffset(TMP, src_reg, initial, sz);
  __ AddImmediate(src_reg, src_reg, offset);
  __ StoreToOffset(TMP, dest_reg, initial, sz);
  __ AddImmediate(dest_reg, dest_reg, offset);
}

static void CopyUpToWordMultiple(FlowGraphCompiler* compiler,
                                 Register dest_reg,
                                 Register src_reg,
                                 Register length_reg,
                                 intptr_t element_size,
                                 bool unboxed_inputs,
                                 bool reversed,
                                 compiler::Label* done) {
  ASSERT(Utils::IsPowerOfTwo(element_size));
  if (element_size >= compiler::target::kWordSize) return;

  const intptr_t element_shift = Utils::ShiftForPowerOfTwo(element_size);
  const intptr_t base_shift =
      (unboxed_inputs ? 0 : kSmiTagShift) - element_shift;
  intptr_t tested_bits = 0;

  __ Comment("Copying until region is a multiple of word size");
  for (intptr_t bit = compiler::target::kWordSizeLog2 - 1; bit >= element_shift;
       bit--) {
    const intptr_t bytes = 1 << bit;
    const intptr_t tested_bit = bit + base_shift;
    tested_bits |= 1 << tested_bit;
    compiler::Label skip_copy;
    __ AndImmediate(TMP, length_reg, 1 << tested_bit);
    __ beqz(TMP, &skip_copy);
    CopyBytes(compiler, dest_reg, src_reg, bytes, reversed);
    __ Bind(&skip_copy);
  }

  ASSERT(tested_bits != 0);
  __ AndImmediate(length_reg, length_reg, ~tested_bits);
  __ beqz(length_reg, done);
}

void MemoryCopyInstr::EmitLoopCopy(FlowGraphCompiler* compiler,
                                   Register dest_reg,
                                   Register src_reg,
                                   Register length_reg,
                                   compiler::Label* done,
                                   compiler::Label* copy_forwards) {
  const bool reversed = copy_forwards != nullptr;
  if (reversed) {
    const intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                           (unboxed_inputs() ? 0 : kSmiTagShift);
    if (shift == 0) {
      __ add_d(TMP, src_reg, length_reg);
    } else if (shift < 0) {
      __ srai_d(TMP, length_reg, -shift);
      __ add_d(TMP, src_reg, TMP);
    } else {
      __ slli_d(TMP, length_reg, shift);
      __ add_d(TMP, src_reg, TMP);
    }
    __ CompareRegisters(dest_reg, TMP);
    __ BranchIf(UNSIGNED_GREATER_EQUAL, copy_forwards);
    __ add_d(dest_reg, dest_reg, TMP);
    __ sub_d(dest_reg, dest_reg, src_reg);
    __ MoveRegister(src_reg, TMP);
  }

  CopyUpToWordMultiple(compiler, dest_reg, src_reg, length_reg, element_size_,
                       unboxed_inputs_, reversed, done);
  const intptr_t loop_subtract =
      Utils::Maximum<intptr_t>(1, (XLEN / 8) / element_size_)
      << (unboxed_inputs_ ? 0 : kSmiTagShift);
  __ Comment("Copying by multiples of word size");
  compiler::Label loop;
  __ Bind(&loop);
  switch (element_size_) {
    case 1:
    case 2:
    case 4:
    case 8:
      CopyBytes(compiler, dest_reg, src_reg, 8, reversed);
      break;
    case 16:
      CopyBytes(compiler, dest_reg, src_reg, 16, reversed);
      break;
    default:
      UNREACHABLE();
      break;
  }
  __ AddImmediate(length_reg, length_reg, -loop_subtract);
  __ bnez(length_reg, &loop);
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Register payload_reg,
                                              Representation array_rep,
                                              Location start_loc) {
  intptr_t offset = 0;
  if (array_rep != kTagged) {
  } else if (IsTypedDataBaseClassId(array_cid)) {
    ASSERT_EQUAL(array_rep, kTagged);
    offset = compiler::target::TypedData::payload_offset() - kHeapObjectTag;
  } else {
    ASSERT_EQUAL(array_rep, kTagged);
    ASSERT(!IsExternalPayloadClassId(array_cid));
    switch (array_cid) {
      case kOneByteStringCid:
        offset =
            compiler::target::OneByteString::data_offset() - kHeapObjectTag;
        break;
      case kTwoByteStringCid:
        offset =
            compiler::target::TwoByteString::data_offset() - kHeapObjectTag;
        break;
      default:
        UNREACHABLE();
        break;
    }
  }

  ASSERT(start_loc.IsRegister() || start_loc.IsConstant());
  if (start_loc.IsConstant()) {
    const auto& constant = start_loc.constant();
    ASSERT(constant.IsInteger());
    const int64_t start_value = Integer::Cast(constant).Value();
    const intx_t add_value = Utils::AddWithWrapAround<intx_t>(
        Utils::MulWithWrapAround<intx_t>(start_value, element_size_), offset);
    __ AddImmediate(payload_reg, array_reg, add_value);
    return;
  }

  const Register start_reg = start_loc.reg();
  intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                   (unboxed_inputs() ? 0 : kSmiTagShift);
  __ AddShifted(payload_reg, array_reg, start_reg, shift);
  __ AddImmediate(payload_reg, offset);
}

LocationSummary* BoxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register out_reg = locs()->out(0).reg();
  const FRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, TMP);

  switch (from_representation()) {
    case kUnboxedDouble:
      __ StoreDFieldToOffset(value, out_reg, ValueOffset());
      break;
    case kUnboxedFloat:
      __ fcvt_d_s(FpuTMP, value);
      __ StoreDFieldToOffset(FpuTMP, out_reg, ValueOffset());
      break;
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      __ StoreQFieldToOffset(value, out_reg, ValueOffset());
      break;
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* UnboxLaneInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  LocationSummary* summary =
      new (zone) LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  switch (representation()) {
    case kUnboxedDouble:
    case kUnboxedFloat:
      summary->set_out(0, Location::RequiresFpuRegister());
      break;
    case kUnboxedInt32:
      summary->set_out(0, Location::RequiresRegister());
      break;
    default:
      UNREACHABLE();
  }
  return summary;
}

void UnboxLaneInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register in = locs()->in(0).reg();
  switch (representation()) {
    case kUnboxedDouble:
      __ LoadDFieldFromOffset(
          locs()->out(0).fpu_reg(), in,
          compiler::target::Float64x2::value_offset() + lane() * sizeof(double));
      break;
    case kUnboxedFloat:
      __ LoadSFieldFromOffset(
          locs()->out(0).fpu_reg(), in,
          compiler::target::Float32x4::value_offset() + lane() * sizeof(float));
      break;
    case kUnboxedInt32:
      __ LoadFieldFromOffset(
          locs()->out(0).reg(), in,
          compiler::target::Int32x4::value_offset() + lane() * sizeof(int32_t),
          compiler::kFourBytes);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* BoxLanesInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = InputCount();
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, 0, LocationSummary::kCallOnSlowPath);
  switch (from_representation()) {
    case kUnboxedDouble:
      summary->set_in(0, Location::RequiresFpuRegister());
      summary->set_in(1, Location::RequiresFpuRegister());
      break;
    case kUnboxedFloat:
      summary->set_in(0, Location::RequiresFpuRegister());
      summary->set_in(1, Location::RequiresFpuRegister());
      summary->set_in(2, Location::RequiresFpuRegister());
      summary->set_in(3, Location::RequiresFpuRegister());
      break;
    case kUnboxedInt32:
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, Location::RequiresRegister());
      summary->set_in(2, Location::RequiresRegister());
      summary->set_in(3, Location::RequiresRegister());
      break;
    default:
      UNREACHABLE();
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxLanesInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  switch (from_representation()) {
    case kUnboxedDouble:
      BoxAllocationSlowPath::Allocate(compiler, this,
                                      compiler->float64x2_class(), result, TMP);
      for (intptr_t i = 0; i < 2; i++) {
        __ StoreDFieldToOffset(
            locs()->in(i).fpu_reg(), result,
            compiler::target::Float64x2::value_offset() + i * sizeof(double));
      }
      break;
    case kUnboxedFloat:
      BoxAllocationSlowPath::Allocate(compiler, this,
                                      compiler->float32x4_class(), result, TMP);
      for (intptr_t i = 0; i < 4; i++) {
        __ StoreSFieldToOffset(
            locs()->in(i).fpu_reg(), result,
            compiler::target::Float32x4::value_offset() + i * sizeof(float));
      }
      break;
    case kUnboxedInt32:
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->int32x4_class(),
                                      result, TMP);
      for (intptr_t i = 0; i < 4; i++) {
        __ Store(locs()->in(i).reg(),
                 compiler::FieldAddress(
                     result, compiler::target::Int32x4::value_offset() +
                                 i * sizeof(int32_t)),
                 compiler::kFourBytes);
      }
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

  ASSERT(compiler::target::kSmiBits >= 32);
  __ slli_d(out, value, XLEN - 32);
  if (from_representation() == kUnboxedInt32) {
    __ srai_d(out, out, XLEN - 32 - kSmiTagShift);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ srli_d(out, out, XLEN - 32 - kSmiTagShift);
  }
}

LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      ValueFitsSmi() ? LocationSummary::kNoCall
                     : LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  if (!ValueFitsSmi()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

void BoxInt64Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register in = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  if (ValueFitsSmi()) {
    __ SmiTag(out, in);
    return;
  }

  ASSERT(kSmiTag == 0);
  ASSERT(out != in);
  compiler::Label done;
  __ SmiTag(out, in);
  __ SmiUntag(TMP, out);
  __ beq(in, TMP, &done, compiler::Assembler::kNearJump);

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  TMP);
  __ StoreToOffset(in, out,
                   compiler::target::Mint::value_offset() - kHeapObjectTag);
  __ Bind(&done);
}

LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : nullptr;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    __ LoadFieldFromOffset(out, value, compiler::target::Mint::value_offset());
  } else {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    if (CanDeoptimize()) {
      __ CompareClassId(value, kMintCid, TMP);
      __ BranchIf(NE, deopt);
    }
    __ LoadFieldFromOffset(out, value, compiler::target::Mint::value_offset());
    __ Bind(&done);
  }
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool) const {
  ASSERT(!RepresentationUtils::IsUnsignedInteger(representation()));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  const bool is_floating_point =
      !RepresentationUtils::IsUnboxedInteger(representation());
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());

  if (is_floating_point) {
    summary->set_out(0, Location::RequiresFpuRegister());
  } else {
    summary->set_out(0, Location::RequiresRegister());
  }
  return summary;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ LoadFieldFromOffset(result, box, ValueOffset());
      break;
    }

    case kUnboxedDouble: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ LoadDFieldFromOffset(result, box, ValueOffset());
      break;
    }

    case kUnboxedFloat: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ LoadDFieldFromOffset(result, box, ValueOffset());
      __ fcvt_s_d(result, result);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ LoadQFieldFromOffset(result, box, ValueOffset());
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}

void UnboxInstr::EmitLoadInt32FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadInt32FromBoxOrSmi(result, value);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadInt64FromBoxOrSmi(result, value);
}

void UnboxInstr::EmitSmiConversion(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt32:
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ SmiUntag(result, box);
      break;
    }

    case kUnboxedFloat: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(TMP, box);
      __ movgr2fr_d(FpuTMP, TMP);
      __ ffint_s_l(result, FpuTMP);
      break;
    }

    case kUnboxedDouble: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(TMP, box);
      __ movgr2fr_d(FpuTMP, TMP);
      __ ffint_d_l(result, FpuTMP);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      UNREACHABLE();
      break;

    default:
      UNREACHABLE();
      break;
  }
}

#undef Z
#undef __

}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
