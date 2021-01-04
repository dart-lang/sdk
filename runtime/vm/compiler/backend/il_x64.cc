// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/backend/il.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register RAX (or XMM0 if
// the return type is double).
LocationSummary* Instruction::MakeCallSummary(Zone* zone,
                                              const Instruction* instr,
                                              LocationSummary* locs) {
  ASSERT(locs == nullptr || locs->always_calls());
  LocationSummary* result =
      ((locs == nullptr)
           ? (new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall))
           : locs);
  const auto representation = instr->representation();
  switch (representation) {
    case kTagged:
    case kUnboxedInt64:
      result->set_out(
          0, Location::RegisterLocation(CallingConventions::kReturnReg));
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
  ASSERT(RequiredInputRepresentation(0) == kTagged);  // It is a Smi.
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);

  const Register index = locs()->in(0).reg();

  switch (representation()) {
    case kTagged:
    case kUnboxedInt64: {
      const auto out = locs()->out(0).reg();
      __ movq(out, compiler::Address(base_reg(), index, TIMES_4, offset()));
      break;
    }
    case kUnboxedDouble: {
      const auto out = locs()->out(0).fpu_reg();
      __ movsd(out, compiler::Address(base_reg(), index, TIMES_4, offset()));
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}

DEFINE_BACKEND(StoreIndexedUnsafe,
               (NoLocation, Register index, Register value)) {
  ASSERT(instr->RequiredInputRepresentation(
             StoreIndexedUnsafeInstr::kIndexPos) == kTagged);  // It is a Smi.
  __ movq(compiler::Address(instr->base_reg(), index, TIMES_4, instr->offset()),
          value);

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(TailCall, (NoLocation, Fixed<Register, ARGS_DESC_REG>)) {
  compiler->EmitTailCallToStub(instr->code());

  // Even though the TailCallInstr will be the last instruction in a basic
  // block, the flow graph compiler will emit native code for other blocks after
  // the one containing this instruction and needs to be able to use the pool.
  // (The `LeaveDartFrame` above disables usages of the pool.)
  __ set_constant_pool_allowed(true);
}

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::RegisterLocation(RSI));
  locs->set_in(kDestPos, Location::RegisterLocation(RDI));
  locs->set_in(kSrcStartPos, Location::WritableRegister());
  locs->set_in(kDestStartPos, Location::WritableRegister());
  locs->set_in(kLengthPos, Location::RegisterLocation(RCX));
  return locs;
}

void MemoryCopyInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register src_start_reg = locs()->in(kSrcStartPos).reg();
  const Register dest_start_reg = locs()->in(kDestStartPos).reg();

  EmitComputeStartPointer(compiler, src_cid_, src_start(), RSI, src_start_reg);
  EmitComputeStartPointer(compiler, dest_cid_, dest_start(), RDI,
                          dest_start_reg);
  if (element_size_ <= 8) {
    __ SmiUntag(RCX);
  }
  switch (element_size_) {
    case 1:
      __ rep_movsb();
      break;
    case 2:
      __ rep_movsw();
      break;
    case 4:
      __ rep_movsl();
      break;
    case 8:
    case 16:
      __ rep_movsq();
      break;
  }
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Value* start,
                                              Register array_reg,
                                              Register start_reg) {
  intptr_t offset;
  if (IsTypedDataBaseClassId(array_cid)) {
    __ movq(
        array_reg,
        compiler::FieldAddress(
            array_reg, compiler::target::TypedDataBase::data_field_offset()));
    offset = 0;
  } else {
    switch (array_cid) {
      case kOneByteStringCid:
        offset =
            compiler::target::OneByteString::data_offset() - kHeapObjectTag;
        break;
      case kTwoByteStringCid:
        offset =
            compiler::target::TwoByteString::data_offset() - kHeapObjectTag;
        break;
      case kExternalOneByteStringCid:
        __ movq(array_reg,
                compiler::FieldAddress(array_reg,
                                       compiler::target::ExternalOneByteString::
                                           external_data_offset()));
        offset = 0;
        break;
      case kExternalTwoByteStringCid:
        __ movq(array_reg,
                compiler::FieldAddress(array_reg,
                                       compiler::target::ExternalTwoByteString::
                                           external_data_offset()));
        offset = 0;
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
  ScaleFactor scale;
  switch (element_size_) {
    case 1:
      __ SmiUntag(start_reg);
      scale = TIMES_1;
      break;
    case 2:
      scale = TIMES_1;
      break;
    case 4:
      scale = TIMES_2;
      break;
    case 8:
      scale = TIMES_4;
      break;
    case 16:
      scale = TIMES_8;
      break;
    default:
      UNREACHABLE();
      break;
  }
  __ leaq(array_reg, compiler::Address(array_reg, start_reg, scale, offset));
}

LocationSummary* PushArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    locs->set_in(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedInt64) {
    locs->set_in(0, Location::RequiresRegister());
  } else {
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where arguments are pushed by their definitions.
  if (compiler->is_optimizing()) {
    Location value = locs()->in(0);
    if (value.IsRegister()) {
      __ pushq(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else if (value.IsFpuRegister()) {
      __ AddImmediate(RSP, compiler::Immediate(-kDoubleSize));
      __ movsd(compiler::Address(RSP, 0), value.fpu_reg());
    } else {
      ASSERT(value.IsStackSlot());
      __ pushq(LocationToStackSlotAddress(value));
    }
  }
}

LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
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

// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (locs()->in(0).IsRegister()) {
    const Register result = locs()->in(0).reg();
    ASSERT(result == CallingConventions::kReturnReg);
  } else {
    ASSERT(locs()->in(0).IsFpuRegister());
    const FpuRegister result = locs()->in(0).fpu_reg();
    ASSERT(result == CallingConventions::kReturnFpuReg);
  }

  if (!compiler->flow_graph().graph_entry()->NeedsFrame()) {
    __ ret();
    return;
  }

#if defined(DEBUG)
  __ Comment("Stack Check");
  compiler::Label done;
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ movq(RDI, RSP);
  __ subq(RDI, RBP);
  __ CompareImmediate(RDI, compiler::Immediate(fp_sp_dist));
  __ j(EQUAL, &done, compiler::Assembler::kNearJump);
  __ int3();
  __ Bind(&done);
#endif
  ASSERT(__ constant_pool_allowed());
  if (yield_index() != PcDescriptorsLayout::kInvalidYieldIndex) {
    compiler->EmitYieldPositionMetadata(source(), yield_index());
  }
  __ LeaveDartFrame();  // Disallows constant pool use.
  __ ret();
  // This ReturnInstr may be emitted out of order by the optimizer. The next
  // block may be a target expecting a properly set constant pool pointer.
  __ set_constant_pool_allowed(true);
}

static const RegisterSet kCalleeSaveRegistersSet(
    CallingConventions::kCalleeSaveCpuRegisters,
    CallingConventions::kCalleeSaveXmmRegisters);

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  __ LeaveDartFrame();

  // Pop dummy return address.
  __ popq(TMP);

  // Anything besides the return register.
  const Register vm_tag_reg = RBX;
  const Register old_exit_frame_reg = RCX;
  const Register old_exit_through_ffi_reg = RDI;

  __ popq(old_exit_frame_reg);

  __ popq(old_exit_through_ffi_reg);

  // Restore top_resource.
  __ popq(TMP);
  __ movq(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()),
      TMP);

  __ popq(vm_tag_reg);

  // If we were called by a trampoline, it will enter the safepoint on our
  // behalf.
  __ TransitionGeneratedToNative(
      vm_tag_reg, old_exit_frame_reg, old_exit_through_ffi_reg,
      /*enter_safepoint=*/!NativeCallbackTrampolines::Enabled());

  // Restore C++ ABI callee-saved registers.
  __ PopRegisters(kCalleeSaveRegistersSet);

#if defined(TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Leave the entry frame.
  __ LeaveFrame();

  // Leave the dummy frame holding the pushed arguments.
  __ LeaveFrame();

  __ ret();

  // For following blocks.
  __ set_constant_pool_allowed(true);
}

// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}

LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // TODO(dartbug.com/30952) support convertion of Register to corresponding
  // least significant byte register (e.g. RAX -> AL, RSI -> SIL, r15 -> r15b).
  comparison()->locs()->set_out(0, Location::RegisterLocation(RDX));
  return comparison()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out(0).reg() == RDX);

  // Clear upper part of the out register. We are going to use setcc on it
  // which is a byte move.
  __ xorq(RDX, RDX);

  // Emit comparison code. This must not overwrite the result register.
  // IfThenElseInstr::Supports() should prevent EmitComparisonCode from using
  // the labels or returning an invalid condition.
  BranchLabels labels = {NULL, NULL, NULL};
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);

  const bool is_power_of_two_kind = IsPowerOfTwoKind(if_true_, if_false_);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if (is_power_of_two_kind) {
    if (true_value == 0) {
      // We need to have zero in RDX on true_condition.
      true_condition = InvertCondition(true_condition);
    }
  } else {
    if (true_value == 0) {
      // Swap values so that false_value is zero.
      intptr_t temp = true_value;
      true_value = false_value;
      false_value = temp;
    } else {
      true_condition = InvertCondition(true_condition);
    }
  }

  __ setcc(true_condition, DL);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ shlq(RDX, compiler::Immediate(shift + kSmiTagSize));
  } else {
    __ decq(RDX);
    __ AndImmediate(RDX, compiler::Immediate(Smi::RawValue(true_value) -
                                             Smi::RawValue(false_value)));
    if (false_value != 0) {
      __ AddImmediate(RDX, compiler::Immediate(Smi::RawValue(false_value)));
    }
  }
}

LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t stack_index =
      compiler::target::frame_layout.FrameSlotForVariable(&local());
  return LocationSummary::Make(zone, kNumInputs,
                               Location::StackSlot(stack_index, FPREG),
                               LocationSummary::kNoCall);
}

void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  // Nothing to do.
}

LocationSummary* StoreLocalInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movq(compiler::Address(
              RBP, compiler::target::FrameOffsetInBytesForVariable(&local())),
          value);
}

LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 0;
  return LocationSummary::Make(zone, kNumInputs,
                               compiler::Assembler::IsSafe(value())
                                   ? Location::Constant(this)
                                   : Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  Location out = locs()->out(0);
  ASSERT(out.IsRegister() || out.IsConstant() || out.IsInvalid());
  if (out.IsRegister()) {
    Register result = out.reg();
    __ LoadObject(result, value());
  }
}

void ConstantInstr::EmitMoveToLocation(FlowGraphCompiler* compiler,
                                       const Location& destination,
                                       Register tmp) {
  if (destination.IsRegister()) {
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      const int64_t value = Integer::Cast(value_).AsInt64Value();
      if (value == 0) {
        __ xorl(destination.reg(), destination.reg());
      } else {
        __ movq(destination.reg(), compiler::Immediate(value));
      }
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0)) {
      __ xorps(destination.fpu_reg(), destination.fpu_reg());
    } else {
      ASSERT(tmp != kNoRegister);
      __ LoadObject(tmp, value_);
      __ movsd(destination.fpu_reg(),
               compiler::FieldAddress(tmp, Double::value_offset()));
    }
  } else if (destination.IsDoubleStackSlot()) {
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0)) {
      __ xorps(FpuTMP, FpuTMP);
    } else {
      ASSERT(tmp != kNoRegister);
      __ LoadObject(tmp, value_);
      __ movsd(FpuTMP, compiler::FieldAddress(tmp, Double::value_offset()));
    }
    __ movsd(LocationToStackSlotAddress(destination), FpuTMP);
  } else {
    ASSERT(destination.IsStackSlot());
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      const int64_t value = Integer::Cast(value_).AsInt64Value();
      __ movq(LocationToStackSlotAddress(destination),
              compiler::Immediate(value));
    } else {
      ASSERT(representation() == kTagged);
      __ StoreObject(LocationToStackSlotAddress(destination), value_);
    }
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
        break;
    }
  }
  return locs;
}

void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    const Register scratch =
        RepresentationUtils::IsUnboxedInteger(representation())
            ? kNoRegister
            : locs()->temp(0).reg();
    EmitMoveToLocation(compiler, locs()->out(0), scratch);
  }
}

LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  auto const dst_type_loc =
      LocationFixedRegisterOrConstant(dst_type(), TypeTestABI::kDstTypeReg);

  // We want to prevent spilling of the inputs (e.g. function/instantiator tav),
  // since TTS preserves them. So we make this a `kNoCall` summary,
  // even though most other registers can be modified by the stub. To tell the
  // register allocator about it, we reserve all the other registers as
  // temporary registers.
  // TODO(http://dartbug.com/32788): Simplify this.

  const intptr_t kNonChangeableInputRegs =
      (1 << TypeTestABI::kInstanceReg) |
      ((dst_type_loc.IsRegister() ? 1 : 0) << TypeTestABI::kDstTypeReg) |
      (1 << TypeTestABI::kInstantiatorTypeArgumentsReg) |
      (1 << TypeTestABI::kFunctionTypeArgumentsReg);

  const intptr_t kNumInputs = 4;

  // We invoke a stub that can potentially clobber any CPU register
  // but can only clobber FPU registers on the slow path when
  // entering runtime. Preserve all FPU registers that are
  // not guarateed to be preserved by the ABI.
  const intptr_t kCpuRegistersToPreserve =
      kDartAvailableCpuRegs & ~kNonChangeableInputRegs;
  const intptr_t kFpuRegistersToPreserve =
      CallingConventions::kVolatileXmmRegisters & ~(1 << FpuTMP);

  const intptr_t kNumTemps = (Utils::CountOneBits64(kCpuRegistersToPreserve) +
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

  // Let's reserve all registers except for the input ones.
  intptr_t next_temp = 0;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    const bool should_preserve = ((1 << i) & kCpuRegistersToPreserve) != 0;
    if (should_preserve) {
      summary->set_temp(next_temp++,
                        Location::RegisterLocation(static_cast<Register>(i)));
    }
  }

  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    const bool should_preserve = ((1 << i) & kFpuRegistersToPreserve) != 0;
    if (should_preserve) {
      summary->set_temp(next_temp++, Location::FpuRegisterLocation(
                                         static_cast<FpuRegister>(i)));
    }
  }

  return summary;
}

static Condition TokenKindToIntCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return LESS;
    case Token::kGT:
      return GREATER;
    case Token::kLTE:
      return LESS_EQUAL;
    case Token::kGTE:
      return GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}

LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, LocationRegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    // Only right can be a stack slot.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : LocationRegisterOrConstant(right()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  UNREACHABLE();
  return NULL;
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = NULL) {
  compiler::Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, compiler::Immediate(kSmiCid));
  }
  __ testq(value_reg, compiler::Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ j(ZERO, &done, compiler::Assembler::kNearJump);
  } else {
    __ j(ZERO, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}

static Condition FlipCondition(Condition condition) {
  switch (condition) {
    case EQUAL:
      return EQUAL;
    case NOT_EQUAL:
      return NOT_EQUAL;
    case LESS:
      return GREATER;
    case LESS_EQUAL:
      return GREATER_EQUAL;
    case GREATER:
      return LESS;
    case GREATER_EQUAL:
      return LESS_EQUAL;
    case BELOW:
      return ABOVE;
    case BELOW_EQUAL:
      return ABOVE_EQUAL;
    case ABOVE:
      return BELOW;
    case ABOVE_EQUAL:
      return BELOW_EQUAL;
    default:
      UNIMPLEMENTED();
      return EQUAL;
  }
}

static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ j(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ j(false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ jmp(labels.true_label);
    }
  }
}

static Condition EmitInt64ComparisonOp(FlowGraphCompiler* compiler,
                                       const LocationSummary& locs,
                                       Token::Kind kind) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);
  if (left.IsConstant() || right.IsConstant()) {
    // Ensure constant is on the right.
    ConstantInstr* constant = NULL;
    if (left.IsConstant()) {
      constant = left.constant_instruction();
      Location tmp = right;
      right = left;
      left = tmp;
      true_condition = FlipCondition(true_condition);
    } else {
      constant = right.constant_instruction();
    }

    if (RepresentationUtils::IsUnboxedInteger(constant->representation())) {
      int64_t value;
      const bool ok = compiler::HasIntegerValue(constant->value(), &value);
      RELEASE_ASSERT(ok);
      __ cmpq(left.reg(), compiler::Immediate(value));
    } else {
      ASSERT(constant->representation() == kTagged);
      __ CompareObject(left.reg(), right.constant());
    }
  } else if (right.IsStackSlot()) {
    __ cmpq(left.reg(), LocationToStackSlotAddress(right));
  } else {
    __ cmpq(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return BELOW;
    case Token::kGT:
      return ABOVE;
    case Token::kLTE:
      return BELOW_EQUAL;
    case Token::kGTE:
      return ABOVE_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  XmmRegister left = locs.in(0).fpu_reg();
  XmmRegister right = locs.in(1).fpu_reg();

  __ comisd(left, right);

  Condition true_condition = TokenKindToDoubleCondition(kind);
  compiler::Label* nan_result =
      (true_condition == NOT_EQUAL) ? labels.true_label : labels.false_label;
  __ j(PARITY_EVEN, nan_result);
  return true_condition;
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if ((operation_cid() == kSmiCid) || (operation_cid() == kMintCid)) {
    return EmitInt64ComparisonOp(compiler, *locs(), kind());
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}

void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }

  Register result = locs()->out(0).reg();
  compiler::Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ jmp(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}

void ComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                     BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
}

LocationSummary* TestSmiInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  locs->set_in(1, LocationRegisterOrConstant(right()));
  return locs;
}

Condition TestSmiInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  Register left_reg = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int64_t imm = static_cast<int64_t>(right.constant().raw());
    __ TestImmediate(left_reg, compiler::Immediate(imm));
  } else {
    __ testq(left_reg, right.reg());
  }
  Condition true_condition = (kind() == Token::kNE) ? NOT_ZERO : ZERO;
  return true_condition;
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

Condition TestCidsInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                            BranchLabels labels) {
  ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
  Register val_reg = locs()->in(0).reg();
  Register cid_reg = locs()->temp(0).reg();

  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids,
                                   licm_hoisted_ ? ICData::kHoisted : 0)
          : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ testq(val_reg, compiler::Immediate(kSmiTagMask));
  __ j(ZERO, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ cmpq(cid_reg, compiler::Immediate(test_cid));
    __ j(EQUAL, result ? labels.true_label : labels.false_label);
  }
  // No match found, deoptimize or default action.
  if (deopt == NULL) {
    // If the cid is not in the list, jump to the opposite label from the cids
    // that are in the list.  These must be all the same (see asserts in the
    // constructor).
    compiler::Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ jmp(target);
    }
  } else {
    __ jmp(deopt);
  }
  // Dummy result as this method already did the jump, there's no need
  // for the caller to branch on a condition.
  return kInvalidCondition;
}

LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, LocationRegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    summary->set_in(1, summary->in(0).IsConstant()
                           ? Location::RequiresRegister()
                           : LocationRegisterOrConstant(right()));
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
  return NULL;
}

Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid) {
    return EmitInt64ComparisonOp(compiler, *locs(), kind());
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  Register result = locs()->out(0).reg();
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());

  // All arguments are already @RSP due to preceding PushArgument()s.
  ASSERT(ArgumentCount() ==
         function().NumParameters() + (function().IsGeneric() ? 1 : 0));

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());

  // Pass a pointer to the first argument in RAX.
  __ leaq(RAX, compiler::Address(RSP, ArgumentCount() * kWordSize));

  __ LoadImmediate(R10, compiler::Immediate(argc_tag));
  const Code* stub;
  if (link_lazily()) {
    stub = &StubCode::CallBootstrapNative();
    compiler::ExternalLabel label(NativeEntry::LinkNativeCallEntry());
    __ LoadNativeEntry(RBX, &label,
                       compiler::ObjectPoolBuilderEntry::kPatchable);
    compiler->GeneratePatchableCall(source(), *stub,
                                    PcDescriptorsLayout::kOther, locs());
  } else {
    if (is_bootstrap_native()) {
      stub = &StubCode::CallBootstrapNative();
    } else if (is_auto_scope()) {
      stub = &StubCode::CallAutoScopeNative();
    } else {
      stub = &StubCode::CallNoScopeNative();
    }
    const compiler::ExternalLabel label(
        reinterpret_cast<uword>(native_c_function()));
    __ LoadNativeEntry(RBX, &label,
                       compiler::ObjectPoolBuilderEntry::kNotPatchable);
    compiler->GenerateStubCall(source(), *stub, PcDescriptorsLayout::kOther,
                               locs());
  }
  __ popq(result);

  __ Drop(ArgumentCount());  // Drop the arguments.
}

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = locs()->temp(0).reg();
  const Register target_address = locs()->in(TargetAddressIndex()).reg();

  // Save frame pointer because we're going to update it when we enter the exit
  // frame.
  __ movq(saved_fp, FPREG);

  // Make a space to put the return address.
  __ pushq(compiler::Immediate(0));

  // We need to create a dummy "exit frame". It will share the same pool pointer
  // but have a null code object.
  __ LoadObject(CODE_REG, Object::null_object());
  __ set_constant_pool_allowed(false);
  __ EnterDartFrame(marshaller_.RequiredStackSpaceInBytes(), PP);

  // Align frame before entering C++ world.
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(SPREG, compiler::Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  EmitParamMoves(compiler);

  // We need to copy a dummy return address up into the dummy stack frame so the
  // stack walker will know which safepoint to use. RIP points to the *next*
  // instruction, so 'AddressRIPRelative' loads the address of the following
  // 'movq'.
  __ leaq(TMP, compiler::Address::AddressRIPRelative(0));
  compiler->EmitCallsiteMetadata(InstructionSource(), deopt_id(),
                                 PcDescriptorsLayout::Kind::kOther, locs());
  __ movq(compiler::Address(FPREG, kSavedCallerPcSlotFromFp * kWordSize), TMP);

  if (CanExecuteGeneratedCodeInSafepoint()) {
    // Update information in the thread object and enter a safepoint.
    __ movq(TMP,
            compiler::Immediate(compiler::target::Thread::exit_through_ffi()));
    __ TransitionGeneratedToNative(target_address, FPREG, TMP,
                                   /*enter_safepoint=*/true);

    __ CallCFunction(target_address, /*restore_rsp=*/true);

    // Update information in the thread object and leave the safepoint.
    __ TransitionNativeToGenerated(/*leave_safepoint=*/true);
  } else {
    // We cannot trust that this code will be executable within a safepoint.
    // Therefore we delegate the responsibility of entering/exiting the
    // safepoint to a stub which in the VM isolate's heap, which will never lose
    // execute permission.
    __ movq(TMP,
            compiler::Address(
                THR, compiler::target::Thread::
                         call_native_through_safepoint_entry_point_offset()));

    // Calls RBX within a safepoint.
    ASSERT(saved_fp == RBX);
    __ movq(RBX, target_address);
    __ call(TMP);
  }

  EmitReturnMoves(compiler);

  // Although PP is a callee-saved register, it may have been moved by the GC.
  __ LeaveDartFrame(compiler::kRestoreCallerPP);

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP, compiler::Address(THR, Thread::global_object_pool_offset()));
  }

  __ set_constant_pool_allowed(true);

  // Instead of returning to the "fake" return address, we just pop it.
  __ popq(TMP);
}

// Keep in sync with NativeReturnInstr::EmitNativeCode.
void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));

  // Create a dummy frame holding the pushed arguments. This simplifies
  // NativeReturnInstr::EmitNativeCode.
  __ EnterFrame(0);

#if defined(TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save the argument registers, in reverse order.
  SaveArguments(compiler);

  // Enter the entry frame. Push a dummy return address for consistency with
  // EnterFrame on ARM(64).
  __ PushImmediate(compiler::Immediate(0));
  __ EnterFrame(0);

  // Save a space for the code object.
  __ PushImmediate(compiler::Immediate(0));

  // InvokeDartCodeStub saves the arguments descriptor here. We don't have one,
  // but we need to follow the same frame layout for the stack walker.
  __ PushImmediate(compiler::Immediate(0));

  // Save ABI callee-saved registers.
  __ PushRegisters(kCalleeSaveRegistersSet);

  // Load the address of DLRT_GetThreadForNativeCallback without using Thread.
  if (FLAG_precompiled_mode) {
    compiler->LoadBSSEntry(BSS::Relocation::DRT_GetThreadForNativeCallback, RAX,
                           RCX);
  } else if (!NativeCallbackTrampolines::Enabled()) {
    // In JIT mode, we can just paste the address of the runtime entry into the
    // generated code directly. This is not a problem since we don't save
    // callbacks into JIT snapshots.
    __ movq(RAX, compiler::Immediate(reinterpret_cast<intptr_t>(
                     DLRT_GetThreadForNativeCallback)));
  }

  // Create another frame to align the frame before continuing in "native" code.
  // If we were called by a trampoline, it has already loaded the thread.
  if (!NativeCallbackTrampolines::Enabled()) {
    __ EnterFrame(0);
    __ ReserveAlignedFrameSpace(0);

    COMPILE_ASSERT(RAX != CallingConventions::kArg1Reg);
    __ movq(CallingConventions::kArg1Reg, compiler::Immediate(callback_id_));
    __ CallCFunction(RAX);
    __ movq(THR, RAX);

    __ LeaveFrame();
  }

  // Save the current VMTag on the stack.
  __ movq(RAX, compiler::Assembler::VMTagAddress());
  __ pushq(RAX);

  // Save top resource.
  __ pushq(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()));
  __ movq(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()),
      compiler::Immediate(0));

  __ pushq(compiler::Address(
      THR, compiler::target::Thread::exit_through_ffi_offset()));

  // Save top exit frame info. Stack walker expects it to be here.
  __ pushq(compiler::Address(
      THR, compiler::target::Thread::top_exit_frame_info_offset()));

  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // Either DLRT_GetThreadForNativeCallback or the callback trampoline (caller)
  // will leave the safepoint for us.
  __ TransitionNativeToGenerated(/*exit_safepoint=*/false);

  // Load the code object.
  __ movq(RAX, compiler::Address(
                   THR, compiler::target::Thread::callback_code_offset()));
  __ movq(RAX, compiler::FieldAddress(
                   RAX, compiler::target::GrowableObjectArray::data_offset()));
  __ movq(CODE_REG, compiler::FieldAddress(
                        RAX, compiler::target::Array::data_offset() +
                                 callback_id_ * compiler::target::kWordSize));

  // Put the code object in the reserved slot.
  __ movq(compiler::Address(FPREG,
                            kPcMarkerSlotFromFp * compiler::target::kWordSize),
          CODE_REG);

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ movq(PP,
            compiler::Address(
                THR, compiler::target::Thread::global_object_pool_offset()));
  } else {
    __ xorq(PP, PP);  // GC-safe value into PP.
  }

  // Load a GC-safe value for arguments descriptor (unused but tagged).
  __ xorq(ARGS_DESC_REG, ARGS_DESC_REG);

  // Push a dummy return address which suggests that we are inside of
  // InvokeDartCodeStub. This is how the stack walker detects an entry frame.
  __ movq(RAX,
          compiler::Address(
              THR, compiler::target::Thread::invoke_dart_code_stub_offset()));
  __ pushq(compiler::FieldAddress(
      RAX, compiler::target::Code::entry_point_offset()));

  // Continue with Dart frame setup.
  FunctionEntryInstr::EmitNativeCode(compiler);
}

static bool CanBeImmediateIndex(Value* index, intptr_t cid) {
  if (!index->definition()->IsConstant()) return false;
  const Object& constant = index->definition()->AsConstant()->value();
  if (!constant.IsSmi()) return false;
  const Smi& smi_const = Smi::Cast(constant);
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const intptr_t data_offset = Instance::DataOffsetFor(cid);
  const int64_t disp = smi_const.AsInt64Value() * scale + data_offset;
  return Utils::IsInt(32, disp);
}

LocationSummary* OneByteStringFromCharCodeInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void OneByteStringFromCharCodeInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ movq(result,
          compiler::Address(THR, Thread::predefined_symbols_address_offset()));
  __ movq(result,
          compiler::Address(result, char_code,
                            TIMES_HALF_WORD_SIZE,  // Char code is a smi.
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
  Register str = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  compiler::Label is_one, done;
  __ movq(result, compiler::FieldAddress(str, String::length_offset()));
  __ cmpq(result, compiler::Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, compiler::Assembler::kNearJump);
  __ movq(result, compiler::Immediate(Smi::RawValue(-1)));
  __ jmp(&done);
  __ Bind(&is_one);
  __ movzxb(result, compiler::FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
}

LocationSummary* StringInterpolateInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}

void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ pushq(array);
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  constexpr int kSizeOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kSizeOfArguments,
                          kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), source(), CallFunction(), args_info,
                               locs(), ICData::Handle(), ICData::kStatic);
  ASSERT(locs()->out(0).reg() == RAX);
}

LocationSummary* Utf8ScanInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Any());               // decoder
  summary->set_in(1, Location::WritableRegister());  // bytes
  summary->set_in(2, Location::WritableRegister());  // start
  summary->set_in(3, Location::WritableRegister());  // end
  summary->set_in(4, Location::RequiresRegister());  // table
  summary->set_temp(0, Location::RequiresRegister());
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
  const Register bytes_end_minus_16_reg = bytes_reg;
  const Register flags_reg = locs()->temp(0).reg();
  const Register temp_reg = TMP;
  const XmmRegister vector_reg = FpuTMP;

  static const intptr_t kSizeMask = 0x03;
  static const intptr_t kFlagsMask = 0x3C;

  compiler::Label scan_ascii, ascii_loop, ascii_loop_in, nonascii_loop;
  compiler::Label rest, rest_loop, rest_loop_in, done;

  // Address of input bytes.
  __ movq(bytes_reg,
          compiler::FieldAddress(
              bytes_reg, compiler::target::TypedDataBase::data_field_offset()));

  // Pointers to start, end and end-16.
  __ leaq(bytes_ptr_reg, compiler::Address(bytes_reg, start_reg, TIMES_1, 0));
  __ leaq(bytes_end_reg, compiler::Address(bytes_reg, end_reg, TIMES_1, 0));
  __ leaq(bytes_end_minus_16_reg, compiler::Address(bytes_end_reg, -16));

  // Initialize size and flags.
  __ xorq(size_reg, size_reg);
  __ xorq(flags_reg, flags_reg);

  __ jmp(&scan_ascii, compiler::Assembler::kNearJump);

  // Loop scanning through ASCII bytes one 16-byte vector at a time.
  // While scanning, the size register contains the size as it was at the start
  // of the current block of ASCII bytes, minus the address of the start of the
  // block. After the block, the end address of the block is added to update the
  // size to include the bytes in the block.
  __ Bind(&ascii_loop);
  __ addq(bytes_ptr_reg, compiler::Immediate(16));
  __ Bind(&ascii_loop_in);

  // Exit vectorized loop when there are less than 16 bytes left.
  __ cmpq(bytes_ptr_reg, bytes_end_minus_16_reg);
  __ j(UNSIGNED_GREATER, &rest, compiler::Assembler::kNearJump);

  // Find next non-ASCII byte within the next 16 bytes.
  // Note: In principle, we should use MOVDQU here, since the loaded value is
  // used as input to an integer instruction. In practice, according to Agner
  // Fog, there is no penalty for using the wrong kind of load.
  __ movups(vector_reg, compiler::Address(bytes_ptr_reg, 0));
  __ pmovmskb(temp_reg, vector_reg);
  __ bsfq(temp_reg, temp_reg);
  __ j(EQUAL, &ascii_loop, compiler::Assembler::kNearJump);

  // Point to non-ASCII byte and update size.
  __ addq(bytes_ptr_reg, temp_reg);
  __ addq(size_reg, bytes_ptr_reg);

  // Read first non-ASCII byte.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));

  // Loop over block of non-ASCII bytes.
  __ Bind(&nonascii_loop);
  __ addq(bytes_ptr_reg, compiler::Immediate(1));

  // Update size and flags based on byte value.
  __ movzxb(temp_reg, compiler::FieldAddress(
                          table_reg, temp_reg, TIMES_1,
                          compiler::target::OneByteString::data_offset()));
  __ orq(flags_reg, temp_reg);
  __ andq(temp_reg, compiler::Immediate(kSizeMask));
  __ addq(size_reg, temp_reg);

  // Stop if end is reached.
  __ cmpq(bytes_ptr_reg, bytes_end_reg);
  __ j(UNSIGNED_GREATER_EQUAL, &done, compiler::Assembler::kNearJump);

  // Go to ASCII scan if next byte is ASCII, otherwise loop.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));
  __ testq(temp_reg, compiler::Immediate(0x80));
  __ j(NOT_EQUAL, &nonascii_loop, compiler::Assembler::kNearJump);

  // Enter the ASCII scanning loop.
  __ Bind(&scan_ascii);
  __ subq(size_reg, bytes_ptr_reg);
  __ jmp(&ascii_loop_in);

  // Less than 16 bytes left. Process the remaining bytes individually.
  __ Bind(&rest);

  // Update size after ASCII scanning loop.
  __ addq(size_reg, bytes_ptr_reg);
  __ jmp(&rest_loop_in, compiler::Assembler::kNearJump);

  __ Bind(&rest_loop);

  // Read byte and increment pointer.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));
  __ addq(bytes_ptr_reg, compiler::Immediate(1));

  // Update size and flags based on byte value.
  __ movzxb(temp_reg, compiler::FieldAddress(
                          table_reg, temp_reg, TIMES_1,
                          compiler::target::OneByteString::data_offset()));
  __ orq(flags_reg, temp_reg);
  __ andq(temp_reg, compiler::Immediate(kSizeMask));
  __ addq(size_reg, temp_reg);

  // Stop if end is reached.
  __ Bind(&rest_loop_in);
  __ cmpq(bytes_ptr_reg, bytes_end_reg);
  __ j(UNSIGNED_LESS, &rest_loop, compiler::Assembler::kNearJump);
  __ Bind(&done);

  // Write flags to field.
  __ andq(flags_reg, compiler::Immediate(kFlagsMask));
  if (!IsScanFlagsUnboxed()) {
    __ SmiTag(flags_reg);
  }
  Register decoder_reg;
  const Location decoder_location = locs()->in(0);
  if (decoder_location.IsStackSlot()) {
    __ movq(temp_reg, LocationToStackSlotAddress(decoder_location));
    decoder_reg = temp_reg;
  } else {
    decoder_reg = decoder_location.reg();
  }
  const auto scan_flags_field_offset = scan_flags_field_.offset_in_bytes();
  __ orq(compiler::FieldAddress(decoder_reg, scan_flags_field_offset),
         flags_reg);
}

LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ movq(result, compiler::Address(obj, offset()));
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ movq(result, compiler::FieldAddress(obj, offset()));
  }
}

DEFINE_BACKEND(StoreUntagged, (NoLocation, Register obj, Register value)) {
  __ movq(compiler::Address(obj, instr->offset_from_tagged()), value);
}

class BoxAllocationSlowPath : public TemplateSlowPathCode<Instruction> {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : TemplateSlowPathCode(instruction), cls_(cls), result_(result) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler::Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s", instruction()->DebugName(),
                 String::Handle(cls_.ScrubbedName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::GetAllocationStubForClass(cls_));

    LocationSummary* locs = instruction()->locs();

    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateStubCall(InstructionSource(),  // No token position.
                               stub, PcDescriptorsLayout::kOther, locs);
    __ MoveRegister(result_, RAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp) {
    if (compiler->intrinsic_mode()) {
      __ TryAllocate(cls, compiler->intrinsic_slow_path_label(),
                     compiler::Assembler::kFarJump, result, temp);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls, slow_path->entry_label(),
                     compiler::Assembler::kFarJump, result, temp);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
  const Class& cls_;
  const Register result_;
};

Representation LoadIndexedInstr::representation() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypeArgumentsCid:
      return kTagged;
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnboxedIntPtr;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kUnboxedInt64;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // For tagged index with index_scale=1 as well as untagged index with
  // index_scale=16 we need a writable register due to assdressing mode
  // restrictions on X64.
  const bool need_writable_index_register =
      (index_scale() == 1 && !index_unboxed_) ||
      (index_scale() == 16 && index_unboxed_);
  locs->set_in(
      1, CanBeImmediateIndex(index(), class_id())
             ? Location::Constant(index()->definition()->AsConstant())
             : (need_writable_index_register ? Location::WritableRegister()
                                             : Location::RequiresRegister()));
  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}

void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  intptr_t index_scale = index_scale_;
  if (index.IsRegister()) {
    if (index_scale == 1 && !index_unboxed_) {
      __ SmiUntag(index.reg());
    } else if (index_scale == 16 && index_unboxed_) {
      // X64 does not support addressing mode using TIMES_16.
      __ SmiTag(index.reg());
      index_scale >>= 1;
    }
  } else {
    ASSERT(index.IsConstant());
  }

  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale,
                               index_unboxed_, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale, array,
                               Smi::Cast(index.constant()).Value());

  if (representation() == kUnboxedDouble ||
      representation() == kUnboxedFloat32x4 ||
      representation() == kUnboxedInt32x4 ||
      representation() == kUnboxedFloat64x2) {
    XmmRegister result = locs()->out(0).fpu_reg();
    if (class_id() == kTypedDataFloat32ArrayCid) {
      // Load single precision float.
      __ movss(result, element_address);
    } else if (class_id() == kTypedDataFloat64ArrayCid) {
      __ movsd(result, element_address);
    } else {
      ASSERT((class_id() == kTypedDataInt32x4ArrayCid) ||
             (class_id() == kTypedDataFloat32x4ArrayCid) ||
             (class_id() == kTypedDataFloat64x2ArrayCid));
      __ movups(result, element_address);
    }
    return;
  }

  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt32ArrayCid:
      ASSERT(representation() == kUnboxedInt32);
      __ movsxd(result, element_address);
      break;
    case kTypedDataUint32ArrayCid:
      ASSERT(representation() == kUnboxedUint32);
      __ movl(result, element_address);
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      ASSERT(representation() == kUnboxedInt64);
      __ movq(result, element_address);
      break;
    case kTypedDataInt8ArrayCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ movsxb(result, element_address);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ movzxb(result, element_address);
      break;
    case kTypedDataInt16ArrayCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ movsxw(result, element_address);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ movzxw(result, element_address);
      break;
    default:
      ASSERT(representation() == kTagged);
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
             (class_id() == kTypeArgumentsCid));
      __ movq(result, element_address);
      break;
  }
}

LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  summary->set_in(1, index_scale() == 1 ? Location::WritableRegister()
                                        : Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);

  compiler::Address element_address =
      compiler::Assembler::ElementAddressForRegIndex(
          IsExternal(), class_id(), index_scale(), /*index_unboxed=*/false, str,
          index.reg());

  if ((index_scale() == 1)) {
    __ SmiUntag(index.reg());
  }
  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      switch (element_count()) {
        case 1:
          __ movzxb(result, element_address);
          break;
        case 2:
          __ movzxw(result, element_address);
          break;
        case 4:
          __ movl(result, element_address);
          break;
        default:
          UNREACHABLE();
      }
      __ SmiTag(result);
      break;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      switch (element_count()) {
        case 1:
          __ movzxw(result, element_address);
          break;
        case 2:
          __ movl(result, element_address);
          break;
        default:
          UNREACHABLE();
      }
      __ SmiTag(result);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  if (idx == 0) return kNoRepresentation;
  if (idx == 1) {
    if (index_unboxed_) {
      return kUnboxedInt64;
    } else {
      return kTagged;  // Index is a smi.
    }
  }
  ASSERT(idx == 2);
  switch (class_id_) {
    case kArrayCid:
      return kTagged;
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnboxedIntPtr;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kUnboxedInt64;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps =
      class_id() == kArrayCid && ShouldEmitStoreBarrier() ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // For tagged index with index_scale=1 as well as untagged index with
  // index_scale=16 we need a writable register due to assdressing mode
  // restrictions on X64.
  const bool need_writable_index_register =
      (index_scale() == 1 && !index_unboxed_) ||
      (index_scale() == 16 && index_unboxed_);
  locs->set_in(
      1, CanBeImmediateIndex(index(), class_id())
             ? Location::Constant(index()->definition()->AsConstant())
             : (need_writable_index_register ? Location::WritableRegister()
                                             : Location::RequiresRegister()));
  switch (class_id()) {
    case kArrayCid:
      locs->set_in(2, ShouldEmitStoreBarrier()
                          ? Location::RegisterLocation(kWriteBarrierValueReg)
                          : LocationRegisterOrConstant(value()));
      if (ShouldEmitStoreBarrier()) {
        locs->set_in(0, Location::RegisterLocation(kWriteBarrierObjectReg));
        locs->set_temp(0, Location::RegisterLocation(kWriteBarrierSlotReg));
      }
      break;
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
      // TODO(fschneider): Add location constraint for byte registers (RAX,
      // RBX, RCX, RDX) instead of using a fixed register.
      locs->set_in(2, LocationFixedRegisterOrSmiConstant(value(), RAX));
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Writable register because the value must be untagged before storing.
      locs->set_in(2, Location::WritableRegister());
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      // TODO(srdjan): Support Float64 constants.
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
      return NULL;
  }
  return locs;
}

void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  intptr_t index_scale = index_scale_;
  if (index.IsRegister()) {
    if (index_scale == 1 && !index_unboxed_) {
      __ SmiUntag(index.reg());
    } else if (index_scale == 16 && index_unboxed_) {
      // X64 does not support addressing mode using TIMES_16.
      __ SmiTag(index.reg());
      index_scale >>= 1;
    }
  } else {
    ASSERT(index.IsConstant());
  }

  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale,
                               index_unboxed_, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale, array,
                               Smi::Cast(index.constant()).Value());

  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        Register value = locs()->in(2).reg();
        Register slot = locs()->temp(0).reg();
        __ leaq(slot, element_address);
        __ StoreIntoArray(array, slot, value, CanValueBeSmi());
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreIntoObjectNoBarrier(array, element_address, constant);
      } else {
        Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, element_address, value);
      }
      break;
    case kOneByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ movb(element_address,
                compiler::Immediate(static_cast<int8_t>(constant.Value())));
      } else {
        ASSERT(locs()->in(2).reg() == RAX);
        __ movb(element_address, RAX);
      }
      break;
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        intptr_t value = constant.Value();
        // Clamp to 0x0 or 0xFF respectively.
        if (value > 0xFF) {
          value = 0xFF;
        } else if (value < 0) {
          value = 0;
        }
        __ movb(element_address,
                compiler::Immediate(static_cast<int8_t>(value)));
      } else {
        ASSERT(locs()->in(2).reg() == RAX);
        compiler::Label store_value, store_0xff;
        __ CompareImmediate(RAX, compiler::Immediate(0xFF));
        __ j(BELOW_EQUAL, &store_value, compiler::Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorq(RAX, RAX);
        __ jmp(&store_value, compiler::Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ LoadImmediate(RAX, compiler::Immediate(0xFF));
        __ Bind(&store_value);
        __ movb(element_address, RAX);
      }
      break;
    }
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      Register value = locs()->in(2).reg();
      __ movw(element_address, value);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      Register value = locs()->in(2).reg();
      __ movl(element_address, value);
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      Register value = locs()->in(2).reg();
      __ movq(element_address, value);
      break;
    }
    case kTypedDataFloat32ArrayCid:
      __ movss(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataFloat64ArrayCid:
      __ movsd(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      __ movups(element_address, locs()->in(2).fpu_reg());
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();

  const bool emit_full_guard = !opt || (field_cid == kIllegalCid);
  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));
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
  ASSERT(compiler::target::ObjectLayout::kClassIdTagSize == 16);
  ASSERT(sizeof(FieldLayout::guarded_cid_) == 2);
  ASSERT(sizeof(FieldLayout::is_nullable_) == 2);

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    return;  // Nothing to emit.
  }

  const bool emit_full_guard =
      !compiler->is_optimizing() || (field_cid == kIllegalCid);

  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));

  const bool needs_field_temp_reg = emit_full_guard;

  const Register value_reg = locs()->in(0).reg();

  const Register value_cid_reg =
      needs_value_cid_temp_reg ? locs()->temp(0).reg() : kNoRegister;

  const Register field_reg = needs_field_temp_reg
                                 ? locs()->temp(locs()->temp_count() - 1).reg()
                                 : kNoRegister;

  compiler::Label ok, fail_label;

  compiler::Label* deopt = NULL;
  if (compiler->is_optimizing()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField);
  }

  compiler::Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    compiler::FieldAddress field_cid_operand(field_reg,
                                             Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);

      __ cmpw(value_cid_reg, field_cid_operand);
      __ j(EQUAL, &ok);
      __ cmpw(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      __ cmpw(field_nullability_operand, compiler::Immediate(value_cid));
    } else {
      __ cmpw(field_cid_operand, compiler::Immediate(value_cid));
    }
    __ j(EQUAL, &ok);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check or requires type arguments and
    // class hierarchy processing for exactness tracking then we fall through
    // into runtime which is responsible for computing offset of the length
    // field based on the class id.
    const bool is_complicated_field =
        field().needs_length_check() ||
        field().static_type_exactness_state().IsUninitialized();
    if (!is_complicated_field) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ cmpw(field_cid_operand, compiler::Immediate(kIllegalCid));
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        __ movw(field_cid_operand, value_cid_reg);
        __ movw(field_nullability_operand, value_cid_reg);
      } else {
        ASSERT(field_reg != kNoRegister);
        __ movw(field_cid_operand, compiler::Immediate(value_cid));
        __ movw(field_nullability_operand, compiler::Immediate(value_cid));
      }

      __ jmp(&ok);
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ cmpw(compiler::FieldAddress(field_reg, Field::guarded_cid_offset()),
              compiler::Immediate(kDynamicCid));
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ jmp(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testq(value_reg, compiler::Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, compiler::Immediate(field_cid));
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        __ CompareObject(value_reg, Object::null_object());
      }

      __ j(NOT_EQUAL, fail);
    } else if (value_cid == field_cid) {
      // This would normaly be caught by Canonicalize, but RemoveRedefinitions
      // may sometimes produce the situation after the last Canonicalize pass.
    } else {
      // Both value's and field's class id is known.
      ASSERT(value_cid != nullability);
      __ jmp(fail);
    }
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
    // We need temporaries for field object, length offset and expected length.
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
    return;  // Nothing to emit.
  }

  compiler::Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();
    const Register offset_reg = locs()->temp(1).reg();
    const Register length_reg = locs()->temp(2).reg();

    compiler::Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    __ movsxb(
        offset_reg,
        compiler::FieldAddress(
            field_reg, Field::guarded_list_length_in_object_offset_offset()));
    __ movq(length_reg, compiler::FieldAddress(
                            field_reg, Field::guarded_list_length_offset()));

    __ cmpq(offset_reg, compiler::Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ cmpq(length_reg, compiler::Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == NULL) {
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ j(NOT_EQUAL, deopt);
    }

    __ Bind(&ok);
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(field().guarded_list_length() >= 0);
    ASSERT(field().guarded_list_length_in_object_offset() !=
           Field::kUnknownLengthOffset);

    __ CompareImmediate(
        compiler::FieldAddress(value_reg,
                               field().guarded_list_length_in_object_offset()),
        compiler::Immediate(Smi::RawValue(field().guarded_list_length())));
    __ j(NOT_EQUAL, deopt);
  }
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
  // Should never emit GuardFieldType for fields that are marked as NotTracking.
  ASSERT(field().static_type_exactness_state().IsTracking());
  if (!field().static_type_exactness_state().NeedsFieldGuard()) {
    // Nothing to do: we only need to perform checks for trivially invariant
    // fields. If optimizing Canonicalize pass should have removed
    // this instruction.
    return;
  }

  compiler::Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  compiler::Label ok;

  const Register value_reg = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  // Skip null values for nullable fields.
  if (!compiler->is_optimizing() || field().is_nullable()) {
    __ CompareObject(value_reg, Object::Handle());
    __ j(EQUAL, &ok);
  }

  // Get the state.
  const Field& original =
      Field::ZoneHandle(compiler->zone(), field().Original());
  __ LoadObject(temp, original);
  __ movsxb(temp, compiler::FieldAddress(
                      temp, Field::static_type_exactness_state_offset()));

  if (!compiler->is_optimizing()) {
    // Check if field requires checking (it is in unitialized or trivially
    // exact state).
    __ cmpq(temp,
            compiler::Immediate(StaticTypeExactnessState::kUninitialized));
    __ j(LESS, &ok);
  }

  compiler::Label call_runtime;
  if (field().static_type_exactness_state().IsUninitialized()) {
    // Can't initialize the field state inline in optimized code.
    __ cmpq(temp,
            compiler::Immediate(StaticTypeExactnessState::kUninitialized));
    __ j(EQUAL, compiler->is_optimizing() ? deopt : &call_runtime);
  }

  // At this point temp is known to be type arguments offset in words.
  __ movq(temp, compiler::FieldAddress(value_reg, temp, TIMES_8, 0));
  __ CompareObject(temp, TypeArguments::ZoneHandle(
                             compiler->zone(),
                             AbstractType::Handle(field().type()).arguments()));
  if (deopt != nullptr) {
    __ j(NOT_EQUAL, deopt);
  } else {
    __ j(EQUAL, &ok);

    __ Bind(&call_runtime);
    __ PushObject(original);
    __ pushq(value_reg);
    __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
    __ Drop(2);
  }

  __ Bind(&ok);
}

LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (IsUnboxedStore() && opt)
                                 ? (FLAG_precompiled_mode ? 0 : 2)
                                 : (IsPotentialUnboxedStore() ? 3 : 0);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      (!FLAG_precompiled_mode &&
                       ((IsUnboxedStore() && opt && is_initialization()) ||
                        IsPotentialUnboxedStore()))
                          ? LocationSummary::kCallOnSlowPath
                          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    if (slot().field().is_non_nullable_integer()) {
      ASSERT(FLAG_precompiled_mode);
      summary->set_in(1, Location::RequiresRegister());
    } else {
      summary->set_in(1, Location::RequiresFpuRegister());
    }
    if (!FLAG_precompiled_mode) {
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_temp(1, Location::RequiresRegister());
    }
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier() ? Location::WritableRegister()
                                                : Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, opt ? Location::RequiresFpuRegister()
                             : Location::FpuRegisterLocation(XMM1));
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                           ? Location::RegisterLocation(kWriteBarrierValueReg)
                           : LocationRegisterOrConstant(value()));
  }
  return summary;
}

static void EnsureMutableBox(FlowGraphCompiler* compiler,
                             StoreInstanceFieldInstr* instruction,
                             Register box_reg,
                             const Class& cls,
                             Register instance_reg,
                             intptr_t offset,
                             Register temp) {
  compiler::Label done;
  __ movq(box_reg, compiler::FieldAddress(instance_reg, offset));
  __ CompareObject(box_reg, Object::null_object());
  __ j(NOT_EQUAL, &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ movq(temp, box_reg);
  __ StoreIntoObject(instance_reg, compiler::FieldAddress(instance_reg, offset),
                     temp, compiler::Assembler::kValueIsNotSmi);

  __ Bind(&done);
}

void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler::target::ObjectLayout::kClassIdTagSize == 16);
  ASSERT(sizeof(FieldLayout::guarded_cid_) == 2);
  ASSERT(sizeof(FieldLayout::is_nullable_) == 2);

  compiler::Label skip_store;

  const Register instance_reg = locs()->in(0).reg();
  const intptr_t offset_in_bytes = OffsetInBytes();
  ASSERT(offset_in_bytes > 0);  // Field is finalized and points after header.

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    if (slot().field().is_non_nullable_integer()) {
      const Register value = locs()->in(1).reg();
      __ Comment("UnboxedIntegerStoreInstanceFieldInstr");
      __ movq(compiler::FieldAddress(instance_reg, offset_in_bytes), value);
      return;
    }

    XmmRegister value = locs()->in(1).fpu_reg();
    const intptr_t cid = slot().field().UnboxedFieldCid();

    // Real unboxed field
    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
          __ movsd(compiler::FieldAddress(instance_reg, offset_in_bytes),
                   value);
          return;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
          __ movups(compiler::FieldAddress(instance_reg, offset_in_bytes),
                    value);
          return;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
          __ movups(compiler::FieldAddress(instance_reg, offset_in_bytes),
                    value);
          return;
        default:
          UNREACHABLE();
      }
    }

    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();

    if (is_initialization()) {
      const Class* cls = NULL;
      switch (cid) {
        case kDoubleCid:
          cls = &compiler->double_class();
          break;
        case kFloat32x4Cid:
          cls = &compiler->float32x4_class();
          break;
        case kFloat64x2Cid:
          cls = &compiler->float64x2_class();
          break;
        default:
          UNREACHABLE();
      }

      BoxAllocationSlowPath::Allocate(compiler, this, *cls, temp, temp2);
      __ movq(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         compiler::FieldAddress(instance_reg, offset_in_bytes),
                         temp2, compiler::Assembler::kValueIsNotSmi);
    } else {
      __ movq(temp, compiler::FieldAddress(instance_reg, offset_in_bytes));
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ movsd(compiler::FieldAddress(temp, Double::value_offset()), value);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ movups(compiler::FieldAddress(temp, Float32x4::value_offset()),
                  value);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ movups(compiler::FieldAddress(temp, Float64x2::value_offset()),
                  value);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if (IsPotentialUnboxedStore()) {
    Register value_reg = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    FpuRegister fpu_temp = locs()->temp(2).fpu_reg();

    if (ShouldEmitStoreBarrier()) {
      // Value input is a writable register and should be manually preserved
      // across allocation slow-path.
      locs()->live_registers()->Add(locs()->in(1), kTagged);
    }

    compiler::Label store_pointer;
    compiler::Label store_double;
    compiler::Label store_float32x4;
    compiler::Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(Z, slot().field().Original()));

    __ cmpw(compiler::FieldAddress(temp, Field::is_nullable_offset()),
            compiler::Immediate(kNullCid));
    __ j(EQUAL, &store_pointer);

    __ movzxb(temp2, compiler::FieldAddress(temp, Field::kind_bits_offset()));
    __ testq(temp2, compiler::Immediate(1 << Field::kUnboxingCandidateBit));
    __ j(ZERO, &store_pointer);

    __ cmpw(compiler::FieldAddress(temp, Field::guarded_cid_offset()),
            compiler::Immediate(kDoubleCid));
    __ j(EQUAL, &store_double);

    __ cmpw(compiler::FieldAddress(temp, Field::guarded_cid_offset()),
            compiler::Immediate(kFloat32x4Cid));
    __ j(EQUAL, &store_float32x4);

    __ cmpw(compiler::FieldAddress(temp, Field::guarded_cid_offset()),
            compiler::Immediate(kFloat64x2Cid));
    __ j(EQUAL, &store_float64x2);

    // Fall through.
    __ jmp(&store_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
      locs()->live_registers()->Add(locs()->in(1));
    }

    {
      __ Bind(&store_double);
      EnsureMutableBox(compiler, this, temp, compiler->double_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ movsd(fpu_temp,
               compiler::FieldAddress(value_reg, Double::value_offset()));
      __ movsd(compiler::FieldAddress(temp, Double::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler, this, temp, compiler->float32x4_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ movups(fpu_temp,
                compiler::FieldAddress(value_reg, Float32x4::value_offset()));
      __ movups(compiler::FieldAddress(temp, Float32x4::value_offset()),
                fpu_temp);
      __ jmp(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler, this, temp, compiler->float64x2_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ movups(fpu_temp,
                compiler::FieldAddress(value_reg, Float64x2::value_offset()));
      __ movups(compiler::FieldAddress(temp, Float64x2::value_offset()),
                fpu_temp);
      __ jmp(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObject(instance_reg,
                       compiler::FieldAddress(instance_reg, offset_in_bytes),
                       value_reg, CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrier(
          instance_reg, compiler::FieldAddress(instance_reg, offset_in_bytes),
          locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrier(
          instance_reg, compiler::FieldAddress(instance_reg, offset_in_bytes),
          value_reg);
    }
  }
  __ Bind(&skip_store);
}

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(kWriteBarrierValueReg));
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  compiler->used_static_fields().Add(&field());

  __ movq(temp,
          compiler::Address(
              THR, compiler::target::Thread::field_table_values_offset()));
  // Note: static fields ids won't be changed by hot-reload.
  __ movq(
      compiler::Address(temp, compiler::target::FieldTable::OffsetOf(field())),
      value);
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
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == TypeTestABI::kInstanceReg);
  ASSERT(locs()->in(1).reg() == TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs()->in(2).reg() == TypeTestABI::kFunctionTypeArgumentsReg);

  compiler->GenerateInstanceOf(source(), deopt_id(), type(), locs());
  ASSERT(locs()->out(0).reg() == RAX);
}

// TODO(srdjan): In case of constant inputs make CreateArray kNoCall and
// use slow path stub.
LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RBX));
  locs->set_in(1, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}

// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  compiler::Label* slow_path,
                                  compiler::Label* done) {
  const int kInlineArraySize = 12;  // Same as kInlineInstanceSize.
  const Register kLengthReg = R10;
  const Register kElemTypeReg = RBX;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      compiler::Assembler::kFarJump,
                      RAX,   // instance
                      RCX,   // end address
                      R13);  // temp

  // RAX: new object start as a tagged pointer.
  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      RAX, compiler::FieldAddress(RAX, Array::type_arguments_offset()),
      kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(
      RAX, compiler::FieldAddress(RAX, Array::length_offset()), kLengthReg);

  // Initialize all array elements to raw_null.
  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(ArrayLayout);
    __ LoadObject(R12, Object::null_object());
    __ leaq(RDI, compiler::FieldAddress(RAX, sizeof(ArrayLayout)));
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ StoreIntoObjectNoBarrier(RAX, compiler::Address(RDI, current_offset),
                                    R12);
        current_offset += kWordSize;
      }
    } else {
      compiler::Label init_loop;
      __ Bind(&init_loop);
      __ StoreIntoObjectNoBarrier(RAX, compiler::Address(RDI, 0), R12);
      __ addq(RDI, compiler::Immediate(kWordSize));
      __ cmpq(RDI, RCX);
      __ j(BELOW, &init_loop, compiler::Assembler::kNearJump);
    }
  }
  __ jmp(done, compiler::Assembler::kNearJump);
}

void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  TypeUsageInfo* type_usage_info = compiler->thread()->type_usage_info();
  if (type_usage_info != nullptr) {
    const Class& list_class = Class::Handle(
        compiler->thread()->isolate()->class_table()->At(kArrayCid));
    RegisterTypeArgumentsUse(compiler->function(), type_usage_info, list_class,
                             element_type()->definition());
  }

  // Allocate the array.  R10 = length, RBX = element type.
  const Register kLengthReg = R10;
  const Register kElemTypeReg = RBX;
  const Register kResultReg = RAX;
  ASSERT(locs()->in(0).reg() == kElemTypeReg);
  ASSERT(locs()->in(1).reg() == kLengthReg);

  compiler::Label slow_path, done;
  if (compiler->is_optimizing() && !FLAG_precompiled_mode &&
      num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if (Array::IsValidLength(length)) {
      InlineArrayAllocation(compiler, length, &slow_path, &done);
    }
  }

  __ Bind(&slow_path);
  auto object_store = compiler->isolate()->object_store();
  const auto& allocate_array_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_array_stub());
  compiler->GenerateStubCall(source(), allocate_array_stub,
                             PcDescriptorsLayout::kOther, locs(), deopt_id());
  __ Bind(&done);
  ASSERT(locs()->out(0).reg() == kResultReg);
}

LocationSummary* LoadFieldInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  LocationSummary* locs = nullptr;
  if (slot().representation() != kTagged) {
    ASSERT(!calls_initializer());
    ASSERT(RepresentationUtils::IsUnboxedInteger(slot().representation()));
    ASSERT(RepresentationUtils::ValueSize(slot().representation()) <=
           compiler::target::kWordSize);

    const intptr_t kNumTemps = 0;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());

  } else if (IsUnboxedDartFieldLoad() && opt) {
    ASSERT(!calls_initializer());
    ASSERT(!slot().field().is_non_nullable_integer());

    const intptr_t kNumTemps = FLAG_precompiled_mode ? 0 : 1;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    if (!FLAG_precompiled_mode) {
      locs->set_temp(0, Location::RequiresRegister());
    }
    locs->set_out(0, Location::RequiresFpuRegister());

  } else if (IsPotentialUnboxedDartFieldLoad()) {
    ASSERT(!calls_initializer());
    const intptr_t kNumTemps = 2;
    locs = new (zone) LocationSummary(zone, kNumInputs, kNumTemps,
                                      LocationSummary::kCallOnSlowPath);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_temp(0, opt ? Location::RequiresFpuRegister()
                          : Location::FpuRegisterLocation(XMM1));
    locs->set_temp(1, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());

  } else if (calls_initializer()) {
    if (throw_exception_on_initialization()) {
      const bool using_shared_stub = UseSharedSlowPathStub(opt);
      const intptr_t kNumTemps = using_shared_stub ? 1 : 0;
      locs = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps,
          using_shared_stub ? LocationSummary::kCallOnSharedSlowPath
                            : LocationSummary::kCallOnSlowPath);
      if (using_shared_stub) {
        locs->set_temp(0, Location::RegisterLocation(
                              LateInitializationErrorABI::kFieldReg));
      }
      locs->set_in(0, Location::RequiresRegister());
      locs->set_out(0, Location::RequiresRegister());
    } else {
      const intptr_t kNumTemps = 0;
      locs = new (zone)
          LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
      locs->set_in(
          0, Location::RegisterLocation(InitInstanceFieldABI::kInstanceReg));
      locs->set_out(
          0, Location::RegisterLocation(InitInstanceFieldABI::kResultReg));
    }
  } else {
    const intptr_t kNumTemps = 0;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}

void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler::target::ObjectLayout::kClassIdTagSize == 16);
  ASSERT(sizeof(FieldLayout::guarded_cid_) == 2);
  ASSERT(sizeof(FieldLayout::is_nullable_) == 2);

  const Register instance_reg = locs()->in(0).reg();
  if (slot().representation() != kTagged) {
    const Register result = locs()->out(0).reg();
    switch (slot().representation()) {
      case kUnboxedInt64:
        __ Comment("UnboxedInt64LoadFieldInstr");
        __ movq(result, compiler::FieldAddress(instance_reg, OffsetInBytes()));
        break;
      case kUnboxedUint32:
        __ Comment("UnboxedUint32LoadFieldInstr");
        __ movl(result, compiler::FieldAddress(instance_reg, OffsetInBytes()));
        break;
      case kUnboxedUint8: {
        __ Comment("UnboxedUint8LoadFieldInstr");
        __ movzxb(result,
                  compiler::FieldAddress(instance_reg, OffsetInBytes()));
        break;
      }
      default:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

  if (IsUnboxedDartFieldLoad() && compiler->is_optimizing()) {
    XmmRegister result = locs()->out(0).fpu_reg();
    const intptr_t cid = slot().field().UnboxedFieldCid();

    // Real unboxed field
    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleLoadFieldInstr");
          __ movsd(result,
                   compiler::FieldAddress(instance_reg, OffsetInBytes()));
          break;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4LoadFieldInstr");
          __ movups(result,
                    compiler::FieldAddress(instance_reg, OffsetInBytes()));
          break;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2LoadFieldInstr");
          __ movups(result,
                    compiler::FieldAddress(instance_reg, OffsetInBytes()));
          break;
        default:
          UNREACHABLE();
      }
      return;
    }

    Register temp = locs()->temp(0).reg();
    __ movq(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        __ movups(result,
                  compiler::FieldAddress(temp, Float32x4::value_offset()));
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2LoadFieldInstr");
        __ movups(result,
                  compiler::FieldAddress(temp, Float64x2::value_offset()));
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  compiler::Label done;
  const Register result = locs()->out(0).reg();
  if (IsPotentialUnboxedDartFieldLoad()) {
    Register temp = locs()->temp(1).reg();
    XmmRegister value = locs()->temp(0).fpu_reg();

    compiler::Label load_pointer;
    compiler::Label load_double;
    compiler::Label load_float32x4;
    compiler::Label load_float64x2;

    __ LoadObject(result, Field::ZoneHandle(slot().field().Original()));

    compiler::FieldAddress field_cid_operand(result,
                                             Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        result, Field::is_nullable_offset());

    __ cmpw(field_nullability_operand, compiler::Immediate(kNullCid));
    __ j(EQUAL, &load_pointer);

    __ cmpw(field_cid_operand, compiler::Immediate(kDoubleCid));
    __ j(EQUAL, &load_double);

    __ cmpw(field_cid_operand, compiler::Immediate(kFloat32x4Cid));
    __ j(EQUAL, &load_float32x4);

    __ cmpw(field_cid_operand, compiler::Immediate(kFloat64x2Cid));
    __ j(EQUAL, &load_float64x2);

    // Fall through.
    __ jmp(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->double_class(),
                                      result, temp);
      __ movq(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ movsd(value, compiler::FieldAddress(temp, Double::value_offset()));
      __ movsd(compiler::FieldAddress(result, Double::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result, temp);
      __ movq(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ movups(value, compiler::FieldAddress(temp, Float32x4::value_offset()));
      __ movups(compiler::FieldAddress(result, Float32x4::value_offset()),
                value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result, temp);
      __ movq(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ movups(value, compiler::FieldAddress(temp, Float64x2::value_offset()));
      __ movups(compiler::FieldAddress(result, Float64x2::value_offset()),
                value);
      __ jmp(&done);
    }

    __ Bind(&load_pointer);
  }

  __ movq(result, compiler::FieldAddress(instance_reg, OffsetInBytes()));

  if (calls_initializer()) {
    EmitNativeCodeForInitializerCall(compiler);
  }

  __ Bind(&done);
}

LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(
                      InstantiationABI::kInstantiatorTypeArgumentsReg));
  locs->set_in(1, Location::RegisterLocation(
                      InstantiationABI::kFunctionTypeArgumentsReg));
  locs->set_out(0,
                Location::RegisterLocation(InstantiationABI::kResultTypeReg));
  return locs;
}

void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_type_args_reg = locs()->in(0).reg();
  Register function_type_args_reg = locs()->in(1).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type());
  __ pushq(instantiator_type_args_reg);  // Push instantiator type arguments.
  __ pushq(function_type_args_reg);      // Push function type arguments.
  compiler->GenerateRuntimeCall(source(), deopt_id(),
                                kInstantiateTypeRuntimeEntry, 3, locs());
  __ Drop(3);           // Drop 2 type vectors, and uninstantiated type.
  __ popq(result_reg);  // Pop instantiated type.
}

LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(
                      InstantiationABI::kInstantiatorTypeArgumentsReg));
  locs->set_in(1, Location::RegisterLocation(
                      InstantiationABI::kFunctionTypeArgumentsReg));
  locs->set_in(2, Location::RegisterLocation(
                      InstantiationABI::kUninstantiatedTypeArgumentsReg));
  locs->set_out(
      0, Location::RegisterLocation(InstantiationABI::kResultTypeArgumentsReg));
  return locs;
}

void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  // We should never try and instantiate a TAV known at compile time to be null,
  // so we can use a null value below for the dynamic case.
  ASSERT(!type_arguments()->BindsToConstant() ||
         !type_arguments()->BoundConstant().IsNull());
  const auto& type_args =
      type_arguments()->BindsToConstant()
          ? TypeArguments::Cast(type_arguments()->BoundConstant())
          : Object::null_type_arguments();
  const intptr_t len = type_args.Length();
  const bool can_function_type_args_be_null =
      function_type_arguments()->CanBe(Object::null_object());

  compiler::Label type_arguments_instantiated;
  if (type_args.IsNull()) {
    // Currently we only create dynamic InstantiateTypeArguments instructions
    // in cases where we know the type argument is uninstantiated at runtime,
    // so there are no extra checks needed to call the stub successfully.
  } else if (type_args.IsRawWhenInstantiatedFromRaw(len) &&
             can_function_type_args_be_null) {
    // If both the instantiator and function type arguments are null and if the
    // type argument vector instantiated from null becomes a vector of dynamic,
    // then use null as the type arguments.
    compiler::Label non_null_type_args;
    // 'instantiator_type_args_reg' is a TypeArguments object (or null).
    // 'function_type_args_reg' is a TypeArguments object (or null).
    const Register instantiator_type_args_reg = locs()->in(0).reg();
    const Register function_type_args_reg = locs()->in(1).reg();
    const Register result_reg = locs()->out(0).reg();
    ASSERT(result_reg != instantiator_type_args_reg &&
           result_reg != function_type_args_reg);
    __ LoadObject(result_reg, Object::null_object());
    __ cmpq(instantiator_type_args_reg, result_reg);
    if (!function_type_arguments()->BindsToConstant()) {
      __ j(NOT_EQUAL, &non_null_type_args, compiler::Assembler::kNearJump);
      __ cmpq(function_type_args_reg, result_reg);
    }
    __ j(EQUAL, &type_arguments_instantiated, compiler::Assembler::kNearJump);
    __ Bind(&non_null_type_args);
  }
  // Lookup cache in stub before calling runtime.
  compiler->GenerateStubCall(source(), GetStub(), PcDescriptorsLayout::kOther,
                             locs());
  __ Bind(&type_arguments_instantiated);
}

LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 2;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(R10));
  locs->set_temp(1, Location::RegisterLocation(R13));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}

class AllocateContextSlowPath
    : public TemplateSlowPathCode<AllocateUninitializedContextInstr> {
 public:
  explicit AllocateContextSlowPath(
      AllocateUninitializedContextInstr* instruction)
      : TemplateSlowPathCode(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction()->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);

    auto object_store = compiler->isolate()->object_store();
    const auto& allocate_context_stub = Code::ZoneHandle(
        compiler->zone(), object_store->allocate_context_stub());

    __ LoadImmediate(
        R10, compiler::Immediate(instruction()->num_context_variables()));
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               PcDescriptorsLayout::kOther, locs);
    ASSERT(instruction()->locs()->out(0).reg() == RAX);
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ jmp(exit_label());
  }
};

void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  Register temp = locs()->temp(0).reg();
  Register result = locs()->out(0).reg();
  // Try allocate the object.
  AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  intptr_t instance_size = Context::InstanceSize(num_context_variables());

  __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                      compiler::Assembler::kFarJump,
                      result,  // instance
                      temp,    // end address
                      locs()->temp(1).reg());

  // Setup up number of context variables field.
  __ movq(compiler::FieldAddress(result, Context::num_variables_offset()),
          compiler::Immediate(num_context_variables()));

  __ Bind(slow_path->exit_label());
}

LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R10);
  ASSERT(locs()->out(0).reg() == RAX);

  auto object_store = compiler->isolate()->object_store();
  const auto& allocate_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_context_stub());

  __ LoadImmediate(R10, compiler::Immediate(num_context_variables()));
  compiler->GenerateStubCall(source(), allocate_context_stub,
                             PcDescriptorsLayout::kOther, locs());
}

LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R9));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R9);
  ASSERT(locs()->out(0).reg() == RAX);

  auto object_store = compiler->isolate()->object_store();
  const auto& clone_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->clone_context_stub());
  compiler->GenerateStubCall(source(), clone_context_stub,
                             /*kind=*/PcDescriptorsLayout::kOther, locs());
}

LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNREACHABLE();
  return NULL;
}

void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(
      catch_try_index(), try_index(), compiler->assembler()->CodeSize(),
      is_generated(), catch_handler_types_, needs_stacktrace());
  if (!FLAG_precompiled_mode) {
    // On lazy deoptimization we patch the optimized code here to enter the
    // deoptimization stub.
    const intptr_t deopt_id = DeoptId::ToDeoptAfter(GetDeoptId());
    if (compiler->is_optimizing()) {
      compiler->AddDeoptIndexAtCall(deopt_id);
    } else {
      compiler->AddCurrentDescriptor(PcDescriptorsLayout::kDeopt, deopt_id,
                                     InstructionSource());
    }
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore RSP from RBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ leaq(RSP, compiler::Address(RBP, fp_sp_dist));

  if (!compiler->is_optimizing()) {
    if (raw_exception_var_ != nullptr) {
      __ movq(compiler::Address(RBP,
                                compiler::target::FrameOffsetInBytesForVariable(
                                    raw_exception_var_)),
              kExceptionObjectReg);
    }
    if (raw_stacktrace_var_ != nullptr) {
      __ movq(compiler::Address(RBP,
                                compiler::target::FrameOffsetInBytesForVariable(
                                    raw_stacktrace_var_)),
              kStackTraceObjectReg);
    }
  }
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

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ movq(compiler::Address(THR, Thread::stack_overflow_flags_offset()),
              compiler::Immediate(Thread::kOsrRequest));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    const bool using_shared_stub =
        instruction()->locs()->call_on_shared_slow_path();
    if (!using_shared_stub) {
      compiler->SaveLiveRegisters(instruction()->locs());
    }
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    if (using_shared_stub) {
      const uword entry_point_offset =
          Thread::stack_overflow_shared_stub_entry_point_offset(
              instruction()->locs()->live_registers()->FpuRegisterCount() > 0);
      __ call(compiler::Address(THR, entry_point_offset));
      compiler->RecordSafepoint(instruction()->locs(), kNumSlowPathArgs);
      compiler->RecordCatchEntryMoves();
      compiler->AddDescriptor(
          PcDescriptorsLayout::kOther, compiler->assembler()->CodeSize(),
          instruction()->deopt_id(), instruction()->source(),
          compiler->CurrentTryIndex());
    } else {
      compiler->GenerateRuntimeCall(
          instruction()->source(), instruction()->deopt_id(),
          kStackOverflowRuntimeEntry, kNumSlowPathArgs, instruction()->locs());
    }

    if (compiler->isolate()->use_osr() && !compiler->is_optimizing() &&
        instruction()->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(PcDescriptorsLayout::kOsrEntry,
                                     instruction()->deopt_id(),
                                     InstructionSource());
    }
    compiler->pending_deoptimization_env_ = NULL;
    if (!using_shared_stub) {
      compiler->RestoreLiveRegisters(instruction()->locs());
    }
    __ jmp(exit_label());
  }

  compiler::Label* osr_entry_label() {
    ASSERT(Isolate::Current()->use_osr());
    return &osr_entry_label_;
  }

 private:
  compiler::Label osr_entry_label_;
};

void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register temp = locs()->temp(0).reg();
  // Generate stack overflow check.
  __ cmpq(RSP, compiler::Address(THR, Thread::stack_limit_offset()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    int32_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ incl(compiler::FieldAddress(temp, Function::usage_counter_offset()));
    __ cmpl(compiler::FieldAddress(temp, Function::usage_counter_offset()),
            compiler::Immediate(threshold));
    __ j(GREATER_EQUAL, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ jmp(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}

static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  ASSERT(left == result);
  compiler::Label* deopt =
      shift_left->CanDeoptimize()
          ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                   ICData::kDeoptBinarySmiOp)
          : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // shlq operation masks the count to 6 bits.
    const intptr_t kCountLimit = 0x3F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      if (value == 1) {
        // Use overflow flag.
        __ shlq(left, compiler::Immediate(1));
        __ j(OVERFLOW, deopt);
        return;
      }
      // Check for overflow.
      Register temp = locs.temp(0).reg();
      __ movq(temp, left);
      __ shlq(left, compiler::Immediate(value));
      __ sarq(left, compiler::Immediate(value));
      __ cmpq(left, temp);
      __ j(NOT_EQUAL, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ shlq(left, compiler::Immediate(value));
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ CompareImmediate(right, compiler::Immediate(0));
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ CompareImmediate(
            right,
            compiler::Immediate(static_cast<int64_t>(Smi::New(max_right))));
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ shlq(left, right);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  ASSERT(right == RCX);  // Count must be in RCX
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareImmediate(right, compiler::Immediate(0));
        __ j(NEGATIVE, deopt);
      }
      compiler::Label done, is_not_zero;
      __ CompareImmediate(
          right,
          compiler::Immediate(static_cast<int64_t>(Smi::New(Smi::kBits))));
      __ j(BELOW, &is_not_zero, compiler::Assembler::kNearJump);
      __ xorq(left, left);
      __ jmp(&done, compiler::Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(right);
      __ shlq(left, right);
      __ Bind(&done);
    } else {
      __ SmiUntag(right);
      __ shlq(left, right);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareImmediate(
          right,
          compiler::Immediate(static_cast<int64_t>(Smi::New(Smi::kBits))));
      __ j(ABOVE_EQUAL, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ movq(temp, left);
    __ SmiUntag(right);
    // Overflow test (preserve temp and right);
    __ shlq(left, right);
    __ sarq(left, right);
    __ cmpq(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ shlq(left, right);
  }
}

class CheckedSmiSlowPath : public TemplateSlowPathCode<CheckedSmiOpInstr> {
 public:
  CheckedSmiSlowPath(CheckedSmiOpInstr* instruction, intptr_t try_index)
      : TemplateSlowPathCode(instruction), try_index_(try_index) {}

  static constexpr intptr_t kNumSlowPathArgs = 2;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler::Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction()->locs();
    Register result = locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (instruction()->env() != NULL) {
      Environment* env =
          compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
      compiler->pending_deoptimization_env_ = env;
    }
    __ pushq(locs->in(0).reg());
    __ pushq(locs->in(1).reg());
    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));
    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ MoveRegister(result, RAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
    compiler->pending_deoptimization_env_ = NULL;
  }

 private:
  intptr_t try_index_;
};

LocationSummary* CheckedSmiOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  bool is_shift = (op_kind() == Token::kSHL) || (op_kind() == Token::kSHR);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = is_shift ? 1 : 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  switch (op_kind()) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kSHL:
    case Token::kSHR:
      summary->set_out(0, Location::RequiresRegister());
      break;
    case Token::kBIT_OR:
    case Token::kBIT_AND:
    case Token::kBIT_XOR:
      summary->set_out(0, Location::SameAsFirstInput());
      break;
    default:
      UNIMPLEMENTED();
  }
  if (is_shift) {
    summary->set_temp(0, Location::RegisterLocation(RCX));
  }
  return summary;
}

void CheckedSmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckedSmiSlowPath* slow_path =
      new CheckedSmiSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);
  // Test operands if necessary.

  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ testq(left, compiler::Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ testq(right, compiler::Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testq(left, compiler::Immediate(kSmiTagMask));
  } else {
    __ movq(TMP, left);
    __ orq(TMP, right);
    __ testq(TMP, compiler::Immediate(kSmiTagMask));
  }
  __ j(NOT_ZERO, slow_path->entry_label());
  Register result = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kADD:
      __ movq(result, left);
      __ addq(result, right);
      __ j(OVERFLOW, slow_path->entry_label());
      break;
    case Token::kSUB:
      __ movq(result, left);
      __ subq(result, right);
      __ j(OVERFLOW, slow_path->entry_label());
      break;
    case Token::kMUL:
      __ movq(result, left);
      __ SmiUntag(result);
      __ imulq(result, right);
      __ j(OVERFLOW, slow_path->entry_label());
      break;
    case Token::kBIT_OR:
      ASSERT(left == result);
      __ orq(result, right);
      break;
    case Token::kBIT_AND:
      ASSERT(left == result);
      __ andq(result, right);
      break;
    case Token::kBIT_XOR:
      ASSERT(left == result);
      __ xorq(result, right);
      break;
    case Token::kSHL:
      ASSERT(result != right);
      ASSERT(locs()->temp(0).reg() == RCX);
      __ cmpq(right, compiler::Immediate(Smi::RawValue(Smi::kBits)));
      __ j(ABOVE_EQUAL, slow_path->entry_label());

      __ movq(RCX, right);
      __ SmiUntag(RCX);
      __ movq(result, left);
      __ shlq(result, RCX);
      __ movq(TMP, result);
      __ sarq(TMP, RCX);
      __ cmpq(TMP, left);
      __ j(NOT_EQUAL, slow_path->entry_label());
      break;
    case Token::kSHR: {
      compiler::Label shift_count_ok;
      ASSERT(result != right);
      ASSERT(locs()->temp(0).reg() == RCX);
      __ cmpq(right, compiler::Immediate(Smi::RawValue(Smi::kBits)));
      __ j(ABOVE_EQUAL, slow_path->entry_label());

      __ movq(RCX, right);
      __ SmiUntag(RCX);
      __ movq(result, left);
      __ SmiUntag(result);
      __ sarq(result, RCX);
      __ SmiTag(result);
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  __ Bind(slow_path->exit_label());
}

class CheckedSmiComparisonSlowPath
    : public TemplateSlowPathCode<CheckedSmiComparisonInstr> {
 public:
  static constexpr intptr_t kNumSlowPathArgs = 2;

  CheckedSmiComparisonSlowPath(CheckedSmiComparisonInstr* instruction,
                               Environment* env,
                               intptr_t try_index,
                               BranchLabels labels,
                               bool merged)
      : TemplateSlowPathCode(instruction),
        try_index_(try_index),
        labels_(labels),
        merged_(merged),
        env_(env) {
    // The environment must either come from the comparison or the environment
    // was cleared from the comparison (and moved to a branch).
    ASSERT(env == instruction->env() ||
           (merged && instruction->env() == nullptr));
  }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler::Assembler::EmittingComments()) {
      __ Comment("slow path smi comparison");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction()->locs();
    Register result = merged_ ? locs->temp(0).reg() : locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (env_ != nullptr) {
      compiler->pending_deoptimization_env_ =
          compiler->SlowPathEnvironmentFor(env_, locs, kNumSlowPathArgs);
    }
    __ pushq(locs->in(0).reg());
    __ pushq(locs->in(1).reg());

    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));

    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ MoveRegister(result, RAX);
    compiler->RestoreLiveRegisters(locs);
    compiler->pending_deoptimization_env_ = nullptr;
    if (merged_) {
      __ CompareObject(result, Bool::True());
      __ j(EQUAL, instruction()->is_negated() ? labels_.false_label
                                              : labels_.true_label);
      __ jmp(instruction()->is_negated() ? labels_.true_label
                                         : labels_.false_label);
      ASSERT(exit_label()->IsUnused());
    } else {
      ASSERT(!instruction()->is_negated());
      __ jmp(exit_label());
    }
  }

 private:
  intptr_t try_index_;
  BranchLabels labels_;
  bool merged_;
  Environment* env_;
};

LocationSummary* CheckedSmiComparisonInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition CheckedSmiComparisonInstr::EmitComparisonCode(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  return EmitInt64ComparisonOp(compiler, *locs(), kind());
}

#define EMIT_SMI_CHECK                                                         \
  intptr_t left_cid = left()->Type()->ToCid();                                 \
  intptr_t right_cid = right()->Type()->ToCid();                               \
  Register left = locs()->in(0).reg();                                         \
  Register right = locs()->in(1).reg();                                        \
  if (this->left()->definition() == this->right()->definition()) {             \
    __ testq(left, compiler::Immediate(kSmiTagMask));                          \
  } else if (left_cid == kSmiCid) {                                            \
    __ testq(right, compiler::Immediate(kSmiTagMask));                         \
  } else if (right_cid == kSmiCid) {                                           \
    __ testq(left, compiler::Immediate(kSmiTagMask));                          \
  } else {                                                                     \
    __ movq(TMP, left);                                                        \
    __ orq(TMP, right);                                                        \
    __ testq(TMP, compiler::Immediate(kSmiTagMask));                           \
  }                                                                            \
  __ j(NOT_ZERO, slow_path->entry_label())

void CheckedSmiComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                               BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, branch->env(), compiler->CurrentTryIndex(), labels,
      /* merged = */ true);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);
  EmitBranchOnCondition(compiler, true_condition, labels);
  // No need to bind slow_path->exit_label() as slow path exits through
  // true/false branch labels.
}

void CheckedSmiComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Zone-allocate labels to pass them to slow-path which outlives local scope.
  compiler::Label* true_label = new (Z) compiler::Label();
  compiler::Label* false_label = new (Z) compiler::Label();
  compiler::Label done;
  BranchLabels labels = {true_label, false_label, false_label};
  // In case of negated comparison result of a slow path call should be negated.
  // For this purpose, 'merged' slow path is generated: it tests
  // result of a call and jumps directly to true or false label.
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, env(), compiler->CurrentTryIndex(), labels,
      /* merged = */ is_negated());
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);
  EmitBranchOnCondition(compiler, true_condition, labels);
  Register result = locs()->out(0).reg();
  __ Bind(false_label);
  __ LoadObject(result, Bool::False());
  __ jmp(&done);
  __ Bind(true_label);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
  // In case of negated comparison slow path exits through true/false labels.
  if (!is_negated()) {
    __ Bind(slow_path->exit_label());
  }
}

static bool CanBeImmediate(const Object& constant) {
  return constant.IsSmi() &&
         compiler::Immediate(static_cast<int64_t>(constant.raw())).is_int32();
}

static bool IsSmiValue(const Object& constant, intptr_t value) {
  return constant.IsSmi() && (Smi::Cast(constant).Value() == value);
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;

  ConstantInstr* right_constant = right()->definition()->AsConstant();
  if ((right_constant != NULL) && (op_kind() != Token::kTRUNCDIV) &&
      (op_kind() != Token::kSHL) && (op_kind() != Token::kMUL) &&
      (op_kind() != Token::kMOD) && CanBeImmediate(right_constant->value())) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::Constant(right_constant));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }

  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (RightIsPowerOfTwoConstant()) {
      summary->set_in(0, Location::RequiresRegister());
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant));
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_out(0, Location::SameAsFirstInput());
    } else {
      // Both inputs must be writable because they will be untagged.
      summary->set_in(0, Location::RegisterLocation(RAX));
      summary->set_in(1, Location::WritableRegister());
      summary->set_out(0, Location::SameAsFirstInput());
      // Will be used for sign extension and division.
      summary->set_temp(0, Location::RegisterLocation(RDX));
    }
    return summary;
  } else if (op_kind() == Token::kMOD) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(RDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(RAX));
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    // Shift-by-1 overflow checking can use flags, otherwise we need a temp.
    const bool shiftBy1 =
        (right_constant != NULL) && IsSmiValue(right_constant->value(), 1);
    const intptr_t kNumTemps = (can_overflow() && !shiftBy1) ? 1 : 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
    if (kNumTemps == 1) {
      summary->set_temp(0, Location::RequiresRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    ConstantInstr* constant = right()->definition()->AsConstant();
    if (constant != NULL) {
      summary->set_in(1, LocationRegisterOrSmiConstant(right()));
    } else {
      summary->set_in(1, Location::PrefersRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }
}

void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  Register left = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(left == result);
  compiler::Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int64_t imm = static_cast<int64_t>(constant.raw());
    switch (op_kind()) {
      case Token::kADD: {
        __ AddImmediate(left, compiler::Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ SubImmediate(left, compiler::Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ MulImmediate(left, compiler::Immediate(value));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        Register temp = locs()->temp(0).reg();
        __ movq(temp, left);
        __ sarq(temp, compiler::Immediate(63));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        __ shrq(temp, compiler::Immediate(64 - shift_count));
        __ addq(left, temp);
        ASSERT(shift_count > 0);
        __ sarq(left, compiler::Immediate(shift_count));
        if (value < 0) {
          __ negq(left);
        }
        __ SmiTag(left);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ AndImmediate(left, compiler::Immediate(imm));
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ OrImmediate(left, compiler::Immediate(imm));
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ XorImmediate(left, compiler::Immediate(imm));
        break;
      }

      case Token::kSHR: {
        // sarq operation masks the count to 6 bits.
        const intptr_t kCountLimit = 0x3F;
        const intptr_t value = Smi::Cast(constant).Value();
        __ sarq(left, compiler::Immediate(
                          Utils::Minimum(value + kSmiTagSize, kCountLimit)));
        __ SmiTag(left);
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // locs()->in(1).IsConstant().

  if (locs()->in(1).IsStackSlot()) {
    const compiler::Address& right = LocationToStackSlotAddress(locs()->in(1));
    switch (op_kind()) {
      case Token::kADD: {
        __ addq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ subq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(left);
        __ imulq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ andq(left, right);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ orq(left, right);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ xorq(left, right);
        break;
      }
      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // locs()->in(1).IsStackSlot().

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD: {
      __ addq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kSUB: {
      __ subq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ imulq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ andq(left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orq(left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xorq(left, right);
      break;
    }
    case Token::kTRUNCDIV: {
      compiler::Label not_32bit, done;

      Register temp = locs()->temp(0).reg();
      ASSERT(left == RAX);
      ASSERT((right != RDX) && (right != RAX));
      ASSERT(temp == RDX);
      ASSERT(result == RAX);
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testq(right, right);
        __ j(ZERO, deopt);
      }
      // Check if both operands fit into 32bits as idiv with 64bit operands
      // requires twice as many cycles and has much higher latency.
      // We are checking this before untagging them to avoid corner case
      // dividing INT_MAX by -1 that raises exception because quotient is
      // too large for 32bit register.
      __ movsxd(temp, left);
      __ cmpq(temp, left);
      __ j(NOT_EQUAL, &not_32bit);
      __ movsxd(temp, right);
      __ cmpq(temp, right);
      __ j(NOT_EQUAL, &not_32bit);

      // Both operands are 31bit smis. Divide using 32bit idiv.
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ cdq();
      __ idivl(right);
      __ movsxd(result, result);
      __ jmp(&done);

      // Divide using 64bit idiv.
      __ Bind(&not_32bit);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ cqo();         // Sign extend RAX -> RDX:RAX.
      __ idivq(right);  //  RAX: quotient, RDX: remainder.
      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ CompareImmediate(result, compiler::Immediate(0x4000000000000000));
        __ j(EQUAL, deopt);
      }
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      compiler::Label not_32bit, div_done;

      Register temp = locs()->temp(0).reg();
      ASSERT(left == RDX);
      ASSERT((right != RDX) && (right != RAX));
      ASSERT(temp == RAX);
      ASSERT(result == RDX);
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testq(right, right);
        __ j(ZERO, deopt);
      }
      // Check if both operands fit into 32bits as idiv with 64bit operands
      // requires twice as many cycles and has much higher latency.
      // We are checking this before untagging them to avoid corner case
      // dividing INT_MAX by -1 that raises exception because quotient is
      // too large for 32bit register.
      __ movsxd(temp, left);
      __ cmpq(temp, left);
      __ j(NOT_EQUAL, &not_32bit);
      __ movsxd(temp, right);
      __ cmpq(temp, right);
      __ j(NOT_EQUAL, &not_32bit);
      // Both operands are 31bit smis. Divide using 32bit idiv.
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movq(RAX, RDX);
      __ cdq();
      __ idivl(right);
      __ movsxd(result, result);
      __ jmp(&div_done);

      // Divide using 64bit idiv.
      __ Bind(&not_32bit);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movq(RAX, RDX);
      __ cqo();         // Sign extend RAX -> RDX:RAX.
      __ idivq(right);  //  RAX: quotient, RDX: remainder.
      __ Bind(&div_done);
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      compiler::Label all_done;
      __ cmpq(result, compiler::Immediate(0));
      __ j(GREATER_EQUAL, &all_done, compiler::Assembler::kNearJump);
      // Result is negative, adjust it.
      if (RangeUtils::Overlaps(right_range(), -1, 1)) {
        compiler::Label subtract;
        __ cmpq(right, compiler::Immediate(0));
        __ j(LESS, &subtract, compiler::Assembler::kNearJump);
        __ addq(result, right);
        __ jmp(&all_done, compiler::Assembler::kNearJump);
        __ Bind(&subtract);
        __ subq(result, right);
      } else if (right_range()->IsPositive()) {
        // Right is positive.
        __ addq(result, right);
      } else {
        // Right is negative.
        __ subq(result, right);
      }
      __ Bind(&all_done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, compiler::Immediate(0));
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarq operation masks the count to 6 bits.
      const intptr_t kCountLimit = 0x3F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ CompareImmediate(right, compiler::Immediate(kCountLimit));
        compiler::Label count_ok;
        __ j(LESS, &count_ok, compiler::Assembler::kNearJump);
        __ LoadImmediate(right, compiler::Immediate(kCountLimit));
        __ Bind(&count_ok);
      }
      ASSERT(right == RCX);  // Count must be in RCX
      __ SmiUntag(left);
      __ sarq(left, right);
      __ SmiTag(left);
      break;
    }
    case Token::kDIV: {
      // Dispatches to 'Double./'.
      // TODO(srdjan): Implement as conversion to double and double division.
      UNREACHABLE();
      break;
    }
    case Token::kOR:
    case Token::kAND: {
      // Flow graph builder has dissected this operation to guarantee correct
      // behavior (short-circuit evaluation).
      UNREACHABLE();
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const bool need_temp = (left()->definition() != right()->definition()) &&
                         (left_cid != kSmiCid) && (right_cid != kSmiCid);
  const intptr_t kNumTemps = need_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (need_temp) summary->set_temp(0, Location::RequiresRegister());
  return summary;
}

void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                             licm_hoisted_ ? ICData::kHoisted : 0);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ testq(left, compiler::Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ testq(right, compiler::Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testq(left, compiler::Immediate(kSmiTagMask));
  } else {
    Register temp = locs()->temp(0).reg();
    __ movq(temp, left);
    __ orq(temp, right);
    __ testq(temp, compiler::Immediate(kSmiTagMask));
  }
  __ j(ZERO, deopt);
}

LocationSummary* BoxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, temp);

  switch (from_representation()) {
    case kUnboxedDouble:
      __ movsd(compiler::FieldAddress(out_reg, ValueOffset()), value);
      break;
    case kUnboxedFloat: {
      __ cvtss2sd(FpuTMP, value);
      __ movsd(compiler::FieldAddress(out_reg, ValueOffset()), FpuTMP);
      break;
    }
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      __ movups(compiler::FieldAddress(out_reg, ValueOffset()), value);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  ASSERT(!RepresentationUtils::IsUnsigned(representation()));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  const bool needs_writable_input =
      (representation() != kUnboxedInt64) &&
      (value()->Type()->ToNullableCid() != BoxCid());
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, needs_writable_input ? Location::WritableRegister()
                                          : Location::RequiresRegister());
  if (RepresentationUtils::IsUnboxedInteger(representation())) {
    summary->set_out(0, Location::SameAsFirstInput());
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ movq(result, compiler::FieldAddress(box, ValueOffset()));
      break;
    }

    case kUnboxedDouble: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movsd(result, compiler::FieldAddress(box, ValueOffset()));
      break;
    }

    case kUnboxedFloat: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movsd(result, compiler::FieldAddress(box, ValueOffset()));
      __ cvtsd2ss(result, result);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movups(result, compiler::FieldAddress(box, ValueOffset()));
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}

void UnboxInstr::EmitSmiConversion(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt32:
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      ASSERT(result == box);
      __ SmiUntag(box);
      break;
    }

    case kUnboxedDouble: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(box);
      __ cvtsi2sdq(result, box);
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
  ASSERT(value == result);
  compiler::Label done;
  __ SmiUntag(value);
  __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
  __ movsxw(result, compiler::Address(value, TIMES_2, Mint::value_offset()));
  __ Bind(&done);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(value == result);
  compiler::Label done;
  __ SmiUntag(value);
  __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
  __ movq(value, compiler::Address(value, TIMES_2, Mint::value_offset()));
  __ Bind(&done);
}

LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = (!is_truncating() && CanDeoptimize()) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  if (kNumTemps > 0) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : NULL;
  ASSERT(value == locs()->out(0).reg());

  if (value_cid == kSmiCid) {
    __ SmiUntag(value);
  } else if (value_cid == kMintCid) {
    __ movq(value, compiler::FieldAddress(value, Mint::value_offset()));
  } else if (!CanDeoptimize()) {
    // Type information is not conclusive, but range analysis found
    // the value to be in int64 range. Therefore it must be a smi
    // or mint value.
    ASSERT(is_truncating());
    compiler::Label done;
    __ SmiUntag(value);
    __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
    __ movq(value, compiler::Address(value, TIMES_2, Mint::value_offset()));
    __ Bind(&done);
    return;
  } else {
    compiler::Label done;
    // Optimistically untag value.
    __ SmiUntagOrCheckClass(value, kMintCid, &done);
    __ j(NOT_EQUAL, deopt);
    // Undo untagging by multiplying value with 2.
    __ movq(value, compiler::Address(value, TIMES_2, Mint::value_offset()));
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != NULL)) {
    ASSERT(representation() == kUnboxedInt32);
    Register temp = locs()->temp(0).reg();
    __ movsxd(temp, value);
    __ cmpq(temp, value);
    __ j(NOT_EQUAL, deopt);
  }
}

LocationSummary* BoxUint8Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  ASSERT(from_representation() == kUnboxedUint8);
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxUint8Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(value != out);

  __ movzxb(out, value);
  __ SmiTag(out);
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
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(value != out);

  ASSERT(kSmiTagSize == 1);
  if (from_representation() == kUnboxedInt32) {
    __ movsxd(out, value);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ movl(out, value);
  }
  __ SmiTag(out);
}

LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  // Shared slow path is used in BoxInt64Instr::EmitNativeCode in
  // FLAG_use_bare_instructions mode and only after VM isolate stubs where
  // replaced with isolate-specific stubs.
  auto object_store = Isolate::Current()->object_store();
  const bool stubs_in_vm_isolate =
      object_store->allocate_mint_with_fpu_regs_stub()
          ->ptr()
          ->InVMIsolateHeap() ||
      object_store->allocate_mint_without_fpu_regs_stub()
          ->ptr()
          ->InVMIsolateHeap();
  const bool shared_slow_path_call = SlowPathSharingSupported(opt) &&
                                     FLAG_use_bare_instructions &&
                                     !stubs_in_vm_isolate;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      ValueFitsSmi()
          ? LocationSummary::kNoCall
          : ((shared_slow_path_call ? LocationSummary::kCallOnSharedSlowPath
                                    : LocationSummary::kCallOnSlowPath)));
  summary->set_in(0, Location::RequiresRegister());
  if (ValueFitsSmi()) {
    summary->set_out(0, Location::RequiresRegister());
  } else if (shared_slow_path_call) {
    summary->set_out(0,
                     Location::RegisterLocation(AllocateMintABI::kResultReg));
    summary->set_temp(0, Location::RegisterLocation(AllocateMintABI::kTempReg));
  } else {
    summary->set_out(0, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

void BoxInt64Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  __ MoveRegister(out, value);
  __ SmiTag(out);
  if (ValueFitsSmi()) {
    return;
  }
  // If the value doesn't fit in a smi, the tagging changes the sign,
  // which causes the overflow flag to be set.
  compiler::Label done;
  __ j(NO_OVERFLOW, &done);

  const Register temp = locs()->temp(0).reg();
  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out, temp);
  } else if (locs()->call_on_shared_slow_path()) {
    auto object_store = compiler->isolate()->object_store();
    const bool live_fpu_regs = locs()->live_registers()->FpuRegisterCount() > 0;
    const auto& stub = Code::ZoneHandle(
        compiler->zone(),
        live_fpu_regs ? object_store->allocate_mint_with_fpu_regs_stub()
                      : object_store->allocate_mint_without_fpu_regs_stub());

    ASSERT(!locs()->live_registers()->ContainsRegister(
        AllocateMintABI::kResultReg));
    auto extended_env = compiler->SlowPathEnvironmentFor(this, 0);
    compiler->GenerateStubCall(source(), stub, PcDescriptorsLayout::kOther,
                               locs(), DeoptId::kNone, extended_env);
  } else {
    BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                    temp);
  }

  __ movq(compiler::FieldAddress(out, Mint::value_offset()), value);
  __ Bind(&done);
}

LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD:
      __ addsd(left, right);
      break;
    case Token::kSUB:
      __ subsd(left, right);
      break;
    case Token::kMUL:
      __ mulsd(left, right);
      break;
    case Token::kDIV:
      __ divsd(left, right);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (op_kind() == MethodRecognizer::kDouble_getIsInfinite) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (op_kind() == MethodRecognizer::kDouble_getIsInfinite) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition DoubleTestOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const XmmRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    compiler::Label is_nan;
    __ comisd(value, value);
    return is_negated ? PARITY_ODD : PARITY_EVEN;
  } else {
    ASSERT(op_kind() == MethodRecognizer::kDouble_getIsInfinite);
    const Register temp = locs()->temp(0).reg();
    __ AddImmediate(RSP, compiler::Immediate(-kDoubleSize));
    __ movsd(compiler::Address(RSP, 0), value);
    __ movq(temp, compiler::Address(RSP, 0));
    __ AddImmediate(RSP, compiler::Immediate(kDoubleSize));
    // Mask off the sign.
    __ AndImmediate(temp, compiler::Immediate(0x7FFFFFFFFFFFFFFFLL));
    // Compare with +infinity.
    __ CompareImmediate(temp, compiler::Immediate(0x7FF0000000000000LL));
    return is_negated ? NOT_EQUAL : EQUAL;
  }
}

// SIMD

#define DEFINE_EMIT(Name, Args)                                                \
  static void Emit##Name(FlowGraphCompiler* compiler, SimdOpInstr* instr,      \
                         PP_APPLY(PP_UNPACK, Args))

#define SIMD_OP_FLOAT_ARITH(V, Name, op)                                       \
  V(Float32x4##Name, op##ps)                                                   \
  V(Float64x2##Name, op##pd)

#define SIMD_OP_SIMPLE_BINARY(V)                                               \
  SIMD_OP_FLOAT_ARITH(V, Add, add)                                             \
  SIMD_OP_FLOAT_ARITH(V, Sub, sub)                                             \
  SIMD_OP_FLOAT_ARITH(V, Mul, mul)                                             \
  SIMD_OP_FLOAT_ARITH(V, Div, div)                                             \
  SIMD_OP_FLOAT_ARITH(V, Min, min)                                             \
  SIMD_OP_FLOAT_ARITH(V, Max, max)                                             \
  V(Int32x4Add, addpl)                                                         \
  V(Int32x4Sub, subpl)                                                         \
  V(Int32x4BitAnd, andps)                                                      \
  V(Int32x4BitOr, orps)                                                        \
  V(Int32x4BitXor, xorps)                                                      \
  V(Float32x4Equal, cmppseq)                                                   \
  V(Float32x4NotEqual, cmppsneq)                                               \
  V(Float32x4GreaterThan, cmppsnle)                                            \
  V(Float32x4GreaterThanOrEqual, cmppsnlt)                                     \
  V(Float32x4LessThan, cmppslt)                                                \
  V(Float32x4LessThanOrEqual, cmppsle)

DEFINE_EMIT(SimdBinaryOp,
            (SameAsFirstInput, XmmRegister left, XmmRegister right)) {
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(left, right);                                                        \
    break;
    SIMD_OP_SIMPLE_BINARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4Scale:
      __ cvtsd2ss(left, left);
      __ shufps(left, left, compiler::Immediate(0x00));
      __ mulps(left, right);
      break;
    case SimdOpInstr::kFloat32x4ShuffleMix:
    case SimdOpInstr::kInt32x4ShuffleMix:
      __ shufps(left, right, compiler::Immediate(instr->mask()));
      break;
    case SimdOpInstr::kFloat64x2FromDoubles:
      // shufpd mask 0x0 results in:
      // Lower 64-bits of left = Lower 64-bits of left.
      // Upper 64-bits of left = Lower 64-bits of right.
      __ shufpd(left, right, compiler::Immediate(0x0));
      break;
    case SimdOpInstr::kFloat64x2Scale:
      __ shufpd(right, right, compiler::Immediate(0x00));
      __ mulpd(left, right);
      break;
    case SimdOpInstr::kFloat64x2WithX:
    case SimdOpInstr::kFloat64x2WithY: {
      // TODO(dartbug.com/30949) avoid transfer through memory.
      COMPILE_ASSERT(SimdOpInstr::kFloat64x2WithY ==
                     (SimdOpInstr::kFloat64x2WithX + 1));
      const intptr_t lane_index = instr->kind() - SimdOpInstr::kFloat64x2WithX;
      ASSERT(0 <= lane_index && lane_index < 2);

      __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
      __ movups(compiler::Address(RSP, 0), left);
      __ movsd(compiler::Address(RSP, lane_index * kDoubleSize), right);
      __ movups(left, compiler::Address(RSP, 0));
      __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
      break;
    }
    case SimdOpInstr::kFloat32x4WithX:
    case SimdOpInstr::kFloat32x4WithY:
    case SimdOpInstr::kFloat32x4WithZ:
    case SimdOpInstr::kFloat32x4WithW: {
      // TODO(dartbug.com/30949) avoid transfer through memory. SSE4.1 has
      // insertps. SSE2 these instructions can be implemented via a combination
      // of shufps/movss/movlhps.
      COMPILE_ASSERT(
          SimdOpInstr::kFloat32x4WithY == (SimdOpInstr::kFloat32x4WithX + 1) &&
          SimdOpInstr::kFloat32x4WithZ == (SimdOpInstr::kFloat32x4WithX + 2) &&
          SimdOpInstr::kFloat32x4WithW == (SimdOpInstr::kFloat32x4WithX + 3));
      const intptr_t lane_index = instr->kind() - SimdOpInstr::kFloat32x4WithX;
      ASSERT(0 <= lane_index && lane_index < 4);
      __ cvtsd2ss(left, left);
      __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
      __ movups(compiler::Address(RSP, 0), right);
      __ movss(compiler::Address(RSP, lane_index * kFloatSize), left);
      __ movups(left, compiler::Address(RSP, 0));
      __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
      break;
    }

    default:
      UNREACHABLE();
  }
}

#define SIMD_OP_SIMPLE_UNARY(V)                                                \
  SIMD_OP_FLOAT_ARITH(V, Sqrt, sqrt)                                           \
  SIMD_OP_FLOAT_ARITH(V, Negate, negate)                                       \
  SIMD_OP_FLOAT_ARITH(V, Abs, abs)                                             \
  V(Float32x4Reciprocal, rcpps)                                                \
  V(Float32x4ReciprocalSqrt, rsqrtps)

DEFINE_EMIT(SimdUnaryOp, (SameAsFirstInput, XmmRegister value)) {
  // TODO(dartbug.com/30949) select better register constraints to avoid
  // redundant move of input into a different register.
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(value, value);                                                       \
    break;
    SIMD_OP_SIMPLE_UNARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4ShuffleX:
      // Shuffle not necessary.
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleY:
      __ shufps(value, value, compiler::Immediate(0x55));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleZ:
      __ shufps(value, value, compiler::Immediate(0xAA));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleW:
      __ shufps(value, value, compiler::Immediate(0xFF));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4Shuffle:
    case SimdOpInstr::kInt32x4Shuffle:
      __ shufps(value, value, compiler::Immediate(instr->mask()));
      break;
    case SimdOpInstr::kFloat32x4Splat:
      // Convert to Float32.
      __ cvtsd2ss(value, value);
      // Splat across all lanes.
      __ shufps(value, value, compiler::Immediate(0x00));
      break;
    case SimdOpInstr::kFloat32x4ToFloat64x2:
      __ cvtps2pd(value, value);
      break;
    case SimdOpInstr::kFloat64x2ToFloat32x4:
      __ cvtpd2ps(value, value);
      break;
    case SimdOpInstr::kInt32x4ToFloat32x4:
    case SimdOpInstr::kFloat32x4ToInt32x4:
      // TODO(dartbug.com/30949) these operations are essentially nop and should
      // not generate any code. They should be removed from the graph before
      // code generation.
      break;
    case SimdOpInstr::kFloat64x2GetX:
      // NOP.
      break;
    case SimdOpInstr::kFloat64x2GetY:
      __ shufpd(value, value, compiler::Immediate(0x33));
      break;
    case SimdOpInstr::kFloat64x2Splat:
      __ shufpd(value, value, compiler::Immediate(0x0));
      break;
    default:
      UNREACHABLE();
      break;
  }
}

DEFINE_EMIT(SimdGetSignMask, (Register out, XmmRegister value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4GetSignMask:
    case SimdOpInstr::kInt32x4GetSignMask:
      __ movmskps(out, value);
      break;
    case SimdOpInstr::kFloat64x2GetSignMask:
      __ movmskpd(out, value);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

DEFINE_EMIT(
    Float32x4FromDoubles,
    (SameAsFirstInput, XmmRegister v0, XmmRegister, XmmRegister, XmmRegister)) {
  // TODO(dartbug.com/30949) avoid transfer through memory. SSE4.1 has
  // insertps, with SSE2 this instruction can be implemented through unpcklps.
  const XmmRegister out = v0;
  __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ cvtsd2ss(out, instr->locs()->in(i).fpu_reg());
    __ movss(compiler::Address(RSP, i * kFloatSize), out);
  }
  __ movups(out, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
}

DEFINE_EMIT(Float32x4Zero, (XmmRegister value)) {
  __ xorps(value, value);
}

DEFINE_EMIT(Float64x2Zero, (XmmRegister value)) {
  __ xorpd(value, value);
}

DEFINE_EMIT(Float32x4Clamp,
            (SameAsFirstInput,
             XmmRegister value,
             XmmRegister lower,
             XmmRegister upper)) {
  __ minps(value, upper);
  __ maxps(value, lower);
}

DEFINE_EMIT(Int32x4FromInts,
            (XmmRegister result, Register, Register, Register, Register)) {
  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ movl(compiler::Address(RSP, i * kInt32Size), instr->locs()->in(i).reg());
  }
  __ movups(result, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
}

DEFINE_EMIT(Int32x4FromBools,
            (XmmRegister result,
             Register,
             Register,
             Register,
             Register,
             Temp<Register> temp)) {
  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    compiler::Label done, load_false;
    __ xorq(temp, temp);
    __ CompareObject(instr->locs()->in(i).reg(), Bool::True());
    __ setcc(EQUAL, ByteRegisterOf(temp));
    __ negl(temp);  // temp = input ? -1 : 0
    __ movl(compiler::Address(RSP, kInt32Size * i), temp);
  }
  __ movups(result, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
}

static void EmitToBoolean(FlowGraphCompiler* compiler, Register out) {
  ASSERT_BOOL_FALSE_FOLLOWS_BOOL_TRUE();
  __ testl(out, out);
  __ setcc(ZERO, ByteRegisterOf(out));
  __ movzxb(out, out);
  __ movq(out,
          compiler::Address(THR, out, TIMES_8, Thread::bool_true_offset()));
}

DEFINE_EMIT(Int32x4GetFlagZorW,
            (Register out, XmmRegister value, Temp<XmmRegister> temp)) {
  __ movhlps(temp, value);  // extract upper half.
  __ movq(out, temp);
  if (instr->kind() == SimdOpInstr::kInt32x4GetFlagW) {
    __ shrq(out, compiler::Immediate(32));  // extract upper 32bits.
  }
  EmitToBoolean(compiler, out);
}

DEFINE_EMIT(Int32x4GetFlagXorY, (Register out, XmmRegister value)) {
  __ movq(out, value);
  if (instr->kind() == SimdOpInstr::kInt32x4GetFlagY) {
    __ shrq(out, compiler::Immediate(32));  // extract upper 32bits.
  }
  EmitToBoolean(compiler, out);
}

DEFINE_EMIT(
    Int32x4WithFlag,
    (SameAsFirstInput, XmmRegister mask, Register flag, Temp<Register> temp)) {
  // TODO(dartbug.com/30949) avoid transfer through memory.
  COMPILE_ASSERT(
      SimdOpInstr::kInt32x4WithFlagY == (SimdOpInstr::kInt32x4WithFlagX + 1) &&
      SimdOpInstr::kInt32x4WithFlagZ == (SimdOpInstr::kInt32x4WithFlagX + 2) &&
      SimdOpInstr::kInt32x4WithFlagW == (SimdOpInstr::kInt32x4WithFlagX + 3));
  const intptr_t lane_index = instr->kind() - SimdOpInstr::kInt32x4WithFlagX;
  ASSERT(0 <= lane_index && lane_index < 4);
  __ SubImmediate(RSP, compiler::Immediate(kSimd128Size));
  __ movups(compiler::Address(RSP, 0), mask);

  // temp = flag == true ? -1 : 0
  __ xorq(temp, temp);
  __ CompareObject(flag, Bool::True());
  __ setcc(EQUAL, ByteRegisterOf(temp));
  __ negl(temp);

  __ movl(compiler::Address(RSP, lane_index * kInt32Size), temp);
  __ movups(mask, compiler::Address(RSP, 0));
  __ AddImmediate(RSP, compiler::Immediate(kSimd128Size));
}

DEFINE_EMIT(Int32x4Select,
            (SameAsFirstInput,
             XmmRegister mask,
             XmmRegister trueValue,
             XmmRegister falseValue,
             Temp<XmmRegister> temp)) {
  // Copy mask.
  __ movaps(temp, mask);
  // Invert it.
  __ notps(temp, temp);
  // mask = mask & trueValue.
  __ andps(mask, trueValue);
  // temp = temp & falseValue.
  __ andps(temp, falseValue);
  // out = mask | temp.
  __ orps(mask, temp);
}

// Map SimdOpInstr::Kind-s to corresponding emit functions. Uses the following
// format:
//
//     CASE(OpA) CASE(OpB) ____(Emitter) - Emitter is used to emit OpA and OpB.
//     SIMPLE(OpA) - Emitter with name OpA is used to emit OpA.
//
#define SIMD_OP_VARIANTS(CASE, ____, SIMPLE)                                   \
  SIMD_OP_SIMPLE_BINARY(CASE)                                                  \
  CASE(Float32x4Scale)                                                         \
  CASE(Float32x4ShuffleMix)                                                    \
  CASE(Int32x4ShuffleMix)                                                      \
  CASE(Float64x2FromDoubles)                                                   \
  CASE(Float64x2Scale)                                                         \
  CASE(Float64x2WithX)                                                         \
  CASE(Float64x2WithY)                                                         \
  CASE(Float32x4WithX)                                                         \
  CASE(Float32x4WithY)                                                         \
  CASE(Float32x4WithZ)                                                         \
  CASE(Float32x4WithW)                                                         \
  ____(SimdBinaryOp)                                                           \
  SIMD_OP_SIMPLE_UNARY(CASE)                                                   \
  CASE(Float32x4ShuffleX)                                                      \
  CASE(Float32x4ShuffleY)                                                      \
  CASE(Float32x4ShuffleZ)                                                      \
  CASE(Float32x4ShuffleW)                                                      \
  CASE(Float32x4Shuffle)                                                       \
  CASE(Int32x4Shuffle)                                                         \
  CASE(Float32x4Splat)                                                         \
  CASE(Float32x4ToFloat64x2)                                                   \
  CASE(Float64x2ToFloat32x4)                                                   \
  CASE(Int32x4ToFloat32x4)                                                     \
  CASE(Float32x4ToInt32x4)                                                     \
  CASE(Float64x2GetX)                                                          \
  CASE(Float64x2GetY)                                                          \
  CASE(Float64x2Splat)                                                         \
  ____(SimdUnaryOp)                                                            \
  CASE(Float32x4GetSignMask)                                                   \
  CASE(Int32x4GetSignMask)                                                     \
  CASE(Float64x2GetSignMask)                                                   \
  ____(SimdGetSignMask)                                                        \
  SIMPLE(Float32x4FromDoubles)                                                 \
  SIMPLE(Int32x4FromInts)                                                      \
  SIMPLE(Int32x4FromBools)                                                     \
  SIMPLE(Float32x4Zero)                                                        \
  SIMPLE(Float64x2Zero)                                                        \
  SIMPLE(Float32x4Clamp)                                                       \
  CASE(Int32x4GetFlagX)                                                        \
  CASE(Int32x4GetFlagY)                                                        \
  ____(Int32x4GetFlagXorY)                                                     \
  CASE(Int32x4GetFlagZ)                                                        \
  CASE(Int32x4GetFlagW)                                                        \
  ____(Int32x4GetFlagZorW)                                                     \
  CASE(Int32x4WithFlagX)                                                       \
  CASE(Int32x4WithFlagY)                                                       \
  CASE(Int32x4WithFlagZ)                                                       \
  CASE(Int32x4WithFlagW)                                                       \
  ____(Int32x4WithFlag)                                                        \
  SIMPLE(Int32x4Select)

LocationSummary* SimdOpInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  switch (kind()) {
#define CASE(Name, ...) case k##Name:
#define EMIT(Name)                                                             \
  return MakeLocationSummaryFromEmitter(zone, this, &Emit##Name);
#define SIMPLE(Name) CASE(Name) EMIT(Name)
    SIMD_OP_VARIANTS(CASE, EMIT, SIMPLE)
#undef CASE
#undef EMIT
#undef SIMPLE
    case kIllegalSimdOp:
      break;
  }
  UNREACHABLE();
  return NULL;
}

void SimdOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  switch (kind()) {
#define CASE(Name, ...) case k##Name:
#define EMIT(Name)                                                             \
  InvokeEmitter(compiler, this, &Emit##Name);                                  \
  break;
#define SIMPLE(Name) CASE(Name) EMIT(Name)
    SIMD_OP_VARIANTS(CASE, EMIT, SIMPLE)
#undef CASE
#undef EMIT
#undef SIMPLE
    case kIllegalSimdOp:
      UNREACHABLE();
      break;
  }
}

#undef DEFINE_EMIT

LocationSummary* MathUnaryInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (kind() == MathUnaryInstr::kDoubleSquare) {
    summary->set_out(0, Location::SameAsFirstInput());
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}

void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (kind() == MathUnaryInstr::kSqrt) {
    __ sqrtsd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    XmmRegister value_reg = locs()->in(0).fpu_reg();
    __ mulsd(value_reg, value_reg);
    ASSERT(value_reg == locs()->out(0).fpu_reg());
  } else {
    UNREACHABLE();
  }
}

LocationSummary* CaseInsensitiveCompareInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(CallingConventions::kArg1Reg));
  summary->set_in(1, Location::RegisterLocation(CallingConventions::kArg2Reg));
  summary->set_in(2, Location::RegisterLocation(CallingConventions::kArg3Reg));
  summary->set_in(3, Location::RegisterLocation(CallingConventions::kArg4Reg));
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}

void CaseInsensitiveCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Save RSP. R13 is chosen because it is callee saved so we do not need to
  // back it up before calling into the runtime.
  static const Register kSavedSPReg = R13;
  __ movq(kSavedSPReg, RSP);
  __ ReserveAlignedFrameSpace(0);

  // Call the function. Parameters are already in their correct spots.
  __ CallRuntime(TargetFunction(), TargetFunction().argument_count());

  // Restore RSP.
  __ movq(RSP, kSavedSPReg);
}

LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out(0).reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ negq(value);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ notq(value);
      // Remove inverted smi-tag.
      __ AndImmediate(value, compiler::Immediate(~kSmiTagMask));
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(locs()->out(0).fpu_reg() == value);
  __ DoubleNegate(value, value);
}

LocationSummary* MathMinMaxInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    // Reuse the left register so that code can be made shorter.
    summary->set_out(0, Location::SameAsFirstInput());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(result_cid() == kSmiCid);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  // Reuse the left register so that code can be made shorter.
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void MathMinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((op_kind() == MethodRecognizer::kMathMin) ||
         (op_kind() == MethodRecognizer::kMathMax));
  const bool is_min = op_kind() == MethodRecognizer::kMathMin;
  if (result_cid() == kDoubleCid) {
    compiler::Label done, returns_nan, are_equal;
    XmmRegister left = locs()->in(0).fpu_reg();
    XmmRegister right = locs()->in(1).fpu_reg();
    XmmRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ comisd(left, right);
    __ j(PARITY_EVEN, &returns_nan, compiler::Assembler::kNearJump);
    __ j(EQUAL, &are_equal, compiler::Assembler::kNearJump);
    const Condition double_condition =
        is_min ? TokenKindToDoubleCondition(Token::kLT)
               : TokenKindToDoubleCondition(Token::kGT);
    ASSERT(left == result);
    __ j(double_condition, &done, compiler::Assembler::kNearJump);
    __ movsd(result, right);
    __ jmp(&done, compiler::Assembler::kNearJump);

    __ Bind(&returns_nan);
    __ movq(temp, compiler::Address(THR, Thread::double_nan_address_offset()));
    __ movsd(result, compiler::Address(temp, 0));
    __ jmp(&done, compiler::Assembler::kNearJump);

    __ Bind(&are_equal);
    compiler::Label left_is_negative;
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ movmskpd(temp, left);
    __ testq(temp, compiler::Immediate(1));
    if (is_min) {
      ASSERT(left == result);
      __ j(NOT_ZERO, &done,
           compiler::Assembler::kNearJump);  // Negative -> return left.
    } else {
      ASSERT(left == result);
      __ j(ZERO, &done,
           compiler::Assembler::kNearJump);  // Positive -> return left.
    }
    __ movsd(result, right);
    __ Bind(&done);
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  __ cmpq(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgeq(result, right);
  } else {
    __ cmovlq(result, right);
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
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out(0).fpu_reg();
  __ cvtsi2sdl(result, value);
}

LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::WritableRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out(0).fpu_reg();
  __ SmiUntag(value);
  __ cvtsi2sdq(result, value);
}

DEFINE_BACKEND(Int64ToDouble, (FpuRegister result, Register value)) {
  __ cvtsi2sdq(result, value);
}

LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(RCX));
  result->set_out(0, Location::RegisterLocation(RAX));
  result->set_temp(0, Location::RegisterLocation(RBX));
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value_obj = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  XmmRegister value_double = FpuTMP;
  ASSERT(result == RAX);
  ASSERT(result != value_obj);
  ASSERT(result != temp);
  __ movsd(value_double,
           compiler::FieldAddress(value_obj, Double::value_offset()));
  __ cvttsd2siq(result, value_double);
  // Overflow is signalled with minint.
  compiler::Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ shlq(temp, compiler::Immediate(1));
  __ j(OVERFLOW, &do_call, compiler::Assembler::kNearJump);
  __ SmiTag(result);
  __ jmp(&done);
  __ Bind(&do_call);
  __ pushq(value_obj);
  ASSERT(instance_call()->HasICData());
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  constexpr int kSizeOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kSizeOfArguments,
                          kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), instance_call()->source(), target,
                               args_info, locs(), ICData::Handle(),
                               ICData::kStatic);
  __ Bind(&done);
}

LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  result->set_temp(0, Location::RequiresRegister());
  return result;
}

void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  Register result = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  Register temp = locs()->temp(0).reg();

  __ cvttsd2siq(result, value);
  // Overflow is signalled with minint.
  compiler::Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ shlq(temp, compiler::Immediate(1));
  __ j(OVERFLOW, deopt);
  __ SmiTag(result);
}

LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleTruncate:
      __ roundsd(result, value, compiler::Assembler::kRoundToZero);
      break;
    case MethodRecognizer::kDoubleFloor:
      __ roundsd(result, value, compiler::Assembler::kRoundDown);
      break;
    case MethodRecognizer::kDoubleCeil:
      __ roundsd(result, value, compiler::Assembler::kRoundUp);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}

void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtsd2ss(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
}

LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}

void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtss2sd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  // Calling convention on x64 uses XMM0 and XMM1 to pass the first two
  // double arguments and XMM0 to return the result.
  //
  // TODO(sjindel): allow XMM0 to be used. Requires refactoring InvokeDoublePow
  // to allow input 1/output register to be equal.
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 4 : 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  ASSERT(R13 != CALLEE_SAVED_TEMP);
  ASSERT(((1 << R13) & CallingConventions::kCalleeSaveCpuRegisters) != 0);
  result->set_temp(0, Location::RegisterLocation(R13));
  result->set_in(0, Location::FpuRegisterLocation(XMM2));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM1));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Temp index 1.
    result->set_temp(1, Location::RegisterLocation(RAX));
    // Temp index 2.
    result->set_temp(2, Location::FpuRegisterLocation(XMM4));
    // Block XMM0 for the calling convention.
    result->set_temp(3, Location::FpuRegisterLocation(XMM0));
  }
  result->set_out(0, Location::FpuRegisterLocation(XMM3));
  return result;
}

// Pseudo code:
// if (exponent == 0.0) return 1.0;
// // Speed up simple cases.
// if (exponent == 1.0) return base;
// if (exponent == 2.0) return base * base;
// if (exponent == 3.0) return base * base * base;
// if (base == 1.0) return 1.0;
// if (base.isNaN || exponent.isNaN) {
//    return double.NAN;
// }
// if (base != -Infinity && exponent == 0.5) {
//   if (base == 0.0) return 0.0;
//   return sqrt(value);
// }
// TODO(srdjan): Move into a stub?
static void InvokeDoublePow(FlowGraphCompiler* compiler,
                            InvokeMathCFunctionInstr* instr) {
  ASSERT(instr->recognized_kind() == MethodRecognizer::kMathDoublePow);
  const intptr_t kInputCount = 2;
  ASSERT(instr->InputCount() == kInputCount);
  LocationSummary* locs = instr->locs();

  XmmRegister base = locs->in(0).fpu_reg();
  XmmRegister exp = locs->in(1).fpu_reg();
  XmmRegister result = locs->out(0).fpu_reg();
  Register temp = locs->temp(InvokeMathCFunctionInstr::kObjectTempIndex).reg();
  XmmRegister zero_temp =
      locs->temp(InvokeMathCFunctionInstr::kDoubleTempIndex).fpu_reg();

  __ xorps(zero_temp, zero_temp);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1)));
  __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));

  compiler::Label check_base, skip_call;
  // exponent == 0.0 -> return 1.0;
  __ comisd(exp, zero_temp);
  __ j(PARITY_EVEN, &check_base, compiler::Assembler::kNearJump);
  __ j(EQUAL, &skip_call);  // 'result' is 1.0.

  // exponent == 1.0 ?
  __ comisd(exp, result);
  compiler::Label return_base;
  __ j(EQUAL, &return_base, compiler::Assembler::kNearJump);

  // exponent == 2.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(2.0)));
  __ movsd(XMM0, compiler::FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  compiler::Label return_base_times_2;
  __ j(EQUAL, &return_base_times_2, compiler::Assembler::kNearJump);

  // exponent == 3.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(3.0)));
  __ movsd(XMM0, compiler::FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  __ j(NOT_EQUAL, &check_base);

  // Base times 3.
  __ movsd(result, base);
  __ mulsd(result, base);
  __ mulsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&return_base);
  __ movsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&return_base_times_2);
  __ movsd(result, base);
  __ mulsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&check_base);
  // Note: 'exp' could be NaN.

  compiler::Label return_nan;
  // base == 1.0 -> return 1.0;
  __ comisd(base, result);
  __ j(PARITY_EVEN, &return_nan, compiler::Assembler::kNearJump);
  __ j(EQUAL, &skip_call, compiler::Assembler::kNearJump);
  // Note: 'base' could be NaN.
  __ comisd(exp, base);
  // Neither 'exp' nor 'base' is NaN.
  compiler::Label try_sqrt;
  __ j(PARITY_ODD, &try_sqrt, compiler::Assembler::kNearJump);
  // Return NaN.
  __ Bind(&return_nan);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(NAN)));
  __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));
  __ jmp(&skip_call);

  compiler::Label do_pow, return_zero;
  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(kNegInfinity)));
  __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));
  // base == -Infinity -> call pow;
  __ comisd(base, result);
  __ j(EQUAL, &do_pow, compiler::Assembler::kNearJump);

  // exponent == 0.5 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0.5)));
  __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, result);
  __ j(NOT_EQUAL, &do_pow, compiler::Assembler::kNearJump);

  // base == 0 -> return 0;
  __ comisd(base, zero_temp);
  __ j(EQUAL, &return_zero, compiler::Assembler::kNearJump);

  __ sqrtsd(result, base);
  __ jmp(&skip_call, compiler::Assembler::kNearJump);

  __ Bind(&return_zero);
  __ movsd(result, zero_temp);
  __ jmp(&skip_call);

  __ Bind(&do_pow);

  // Save RSP.
  __ movq(locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg(), RSP);
  __ ReserveAlignedFrameSpace(0);
  __ movaps(XMM0, locs->in(0).fpu_reg());
  ASSERT(locs->in(1).fpu_reg() == XMM1);

  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ movaps(locs->out(0).fpu_reg(), XMM0);
  // Restore RSP.
  __ movq(RSP, locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg());
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  // Save RSP.
  __ movq(locs()->temp(kSavedSpTempIndex).reg(), RSP);
  __ ReserveAlignedFrameSpace(0);
  __ movaps(XMM0, locs()->in(0).fpu_reg());
  if (InputCount() == 2) {
    ASSERT(locs()->in(1).fpu_reg() == XMM1);
  }

  __ CallRuntime(TargetFunction(), InputCount());
  __ movaps(locs()->out(0).fpu_reg(), XMM0);
  // Restore RSP.
  __ movq(RSP, locs()->temp(kSavedSpTempIndex).reg());
}

LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  // Only use this instruction in optimized code.
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
    XmmRegister out = locs()->out(0).fpu_reg();
    XmmRegister in = in_loc.fpu_reg();
    __ movaps(out, in);
  } else {
    ASSERT(representation() == kTagged);
    Register out = locs()->out(0).reg();
    Register in = in_loc.reg();
    __ movq(out, in);
  }
}

LocationSummary* TruncDivModInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Both inputs must be writable because they will be untagged.
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_in(1, Location::WritableRegister());
  summary->set_out(0, Location::Pair(Location::RegisterLocation(RAX),
                                     Location::RegisterLocation(RDX)));
  return summary;
}

void TruncDivModInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(CanDeoptimize());
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  ASSERT(locs()->out(0).IsPairLocation());
  PairLocation* pair = locs()->out(0).AsPairLocation();
  Register result1 = pair->At(0).reg();
  Register result2 = pair->At(1).reg();
  compiler::Label not_32bit, done;
  Register temp = RDX;
  ASSERT(left == RAX);
  ASSERT((right != RDX) && (right != RAX));
  ASSERT(result1 == RAX);
  ASSERT(result2 == RDX);
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ testq(right, right);
    __ j(ZERO, deopt);
  }
  // Check if both operands fit into 32bits as idiv with 64bit operands
  // requires twice as many cycles and has much higher latency.
  // We are checking this before untagging them to avoid corner case
  // dividing INT_MAX by -1 that raises exception because quotient is
  // too large for 32bit register.
  __ movsxd(temp, left);
  __ cmpq(temp, left);
  __ j(NOT_EQUAL, &not_32bit);
  __ movsxd(temp, right);
  __ cmpq(temp, right);
  __ j(NOT_EQUAL, &not_32bit);

  // Both operands are 31bit smis. Divide using 32bit idiv.
  __ SmiUntag(left);
  __ SmiUntag(right);
  __ cdq();
  __ idivl(right);
  __ movsxd(RAX, RAX);
  __ movsxd(RDX, RDX);
  __ jmp(&done);

  // Divide using 64bit idiv.
  __ Bind(&not_32bit);
  __ SmiUntag(left);
  __ SmiUntag(right);
  __ cqo();         // Sign extend RAX -> RDX:RAX.
  __ idivq(right);  //  RAX: quotient, RDX: remainder.
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  __ CompareImmediate(RAX, compiler::Immediate(0x4000000000000000));
  __ j(EQUAL, deopt);
  __ Bind(&done);

  // Modulo correction (RDX).
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  compiler::Label all_done;
  __ cmpq(RDX, compiler::Immediate(0));
  __ j(GREATER_EQUAL, &all_done, compiler::Assembler::kNearJump);
  // Result is negative, adjust it.
  if ((divisor_range() == NULL) || divisor_range()->Overlaps(-1, 1)) {
    compiler::Label subtract;
    __ cmpq(right, compiler::Immediate(0));
    __ j(LESS, &subtract, compiler::Assembler::kNearJump);
    __ addq(RDX, right);
    __ jmp(&all_done, compiler::Assembler::kNearJump);
    __ Bind(&subtract);
    __ subq(RDX, right);
  } else if (divisor_range()->IsPositive()) {
    // Right is positive.
    __ addq(RDX, right);
  } else {
    // Right is negative.
    __ subq(RDX, right);
  }
  __ Bind(&all_done);

  __ SmiTag(RAX);
  __ SmiTag(RDX);
  // Note that the result of an integer division/modulo of two
  // in-range arguments, cannot create out-of-range result.
}

LocationSummary* BranchInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}

void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
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
  __ CompareObject(locs()->in(0).reg(), Object::null_object());
  Condition cond = IsDeoptIfNull() ? EQUAL : NOT_EQUAL;
  __ j(cond, deopt);
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  compiler::Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ subq(biased_cid, compiler::Immediate(min));
  __ cmpq(biased_cid, compiler::Immediate(max - min));
  __ j(ABOVE, deopt);

  Register mask_reg = locs()->temp(1).reg();
  __ movq(mask_reg, compiler::Immediate(mask));
  __ btq(mask_reg, biased_cid);
  __ j(NOT_CARRY, deopt);
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
    __ cmpl(biased_cid, compiler::Immediate(cid_start - bias));
    no_match = NOT_EQUAL;
    match = EQUAL;
  } else {
    // For class ID ranges use a subtract followed by an unsigned
    // comparison to check both ends of the ranges with one comparison.
    __ addl(biased_cid, compiler::Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(biased_cid, compiler::Immediate(cid_end - cid_start));
    no_match = ABOVE;
    match = BELOW_EQUAL;
  }

  if (is_last) {
    __ j(no_match, deopt);
  } else {
    if (use_near_jump) {
      __ j(match, is_ok, compiler::Assembler::kNearJump);
    } else {
      __ j(match, is_ok);
    }
  }
  return bias;
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
  Register value = locs()->in(0).reg();
  compiler::Label* deopt = compiler->AddDeoptStub(
      deopt_id(), ICData::kDeoptCheckSmi, licm_hoisted_ ? ICData::kHoisted : 0);
  __ BranchIfNotSmi(value, deopt);
}

void CheckNullInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ThrowErrorSlowPathCode* slow_path =
      new NullErrorSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);

  Register value_reg = locs()->in(0).reg();
  // TODO(dartbug.com/30480): Consider passing `null` literal as an argument
  // in order to be able to allocate it on register.
  __ CompareObject(value_reg, Object::null_object());
  __ BranchIf(EQUAL, slow_path->entry_label());
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
    __ CompareImmediate(value,
                        compiler::Immediate(Smi::RawValue(cids_.cid_start)));
    __ j(NOT_ZERO, deopt);
  } else {
    __ AddImmediate(value,
                    compiler::Immediate(-Smi::RawValue(cids_.cid_start)));
    __ cmpq(value, compiler::Immediate(Smi::RawValue(cids_.Extent())));
    __ j(ABOVE, deopt);
  }
}

LocationSummary* CheckConditionInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}

void CheckConditionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label if_true;
  compiler::Label* if_false =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnknown);
  BranchLabels labels = {&if_true, if_false, &if_true};
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    __ j(InvertCondition(true_condition), if_false);
  }
  __ Bind(&if_true);
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
  flags |= licm_hoisted_ ? ICData::kHoisted : 0;
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckArrayBound, flags);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);

  if (length_loc.IsConstant() && index_loc.IsConstant()) {
    ASSERT((Smi::Cast(length_loc.constant()).Value() <=
            Smi::Cast(index_loc.constant()).Value()) ||
           (Smi::Cast(index_loc.constant()).Value() < 0));
    // Unconditionally deoptimize for constant bounds checks because they
    // only occur only when index is out-of-bounds.
    __ jmp(deopt);
    return;
  }

  const intptr_t index_cid = index()->Type()->ToCid();
  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(length,
                        compiler::Immediate(static_cast<int64_t>(index.raw())));
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ testq(index, index);
      __ j(NEGATIVE, deopt);
    } else {
      __ CompareImmediate(
          index, compiler::Immediate(static_cast<int64_t>(length.raw())));
      __ j(ABOVE_EQUAL, deopt);
    }
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmpq(index, length);
    __ j(ABOVE_EQUAL, deopt);
  }
}

class Int64DivideSlowPath : public ThrowErrorSlowPathCode {
 public:
  Int64DivideSlowPath(BinaryInt64OpInstr* instruction,
                      Register divisor,
                      Range* divisor_range,
                      intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kIntegerDivisionByZeroExceptionRuntimeEntry,
                               try_index),
        is_mod_(instruction->op_kind() == Token::kMOD),
        divisor_(divisor),
        divisor_range_(divisor_range),
        div_by_minus_one_label_(),
        adjust_sign_label_() {}

  void EmitNativeCode(FlowGraphCompiler* compiler) override {
    // Handle modulo/division by zero, if needed. Use superclass code.
    if (has_divide_by_zero()) {
      ThrowErrorSlowPathCode::EmitNativeCode(compiler);
    } else {
      __ Bind(entry_label());  // not used, but keeps destructor happy
      if (compiler::Assembler::EmittingComments()) {
        __ Comment("slow path %s operation (no throw)", name());
      }
    }
    // Handle modulo/division by minus one, if needed.
    // Note: an exact -1 divisor is best optimized prior to codegen.
    if (has_divide_by_minus_one()) {
      __ Bind(div_by_minus_one_label());
      if (is_mod_) {
        __ xorq(RDX, RDX);  // x % -1 =  0
      } else {
        __ negq(RAX);  // x / -1 = -x
      }
      __ jmp(exit_label());
    }
    // Adjust modulo for negative sign, optimized for known ranges.
    // if (divisor < 0)
    //   out -= divisor;
    // else
    //   out += divisor;
    if (has_adjust_sign()) {
      __ Bind(adjust_sign_label());
      if (RangeUtils::Overlaps(divisor_range_, -1, 1)) {
        // General case.
        compiler::Label subtract;
        __ testq(divisor_, divisor_);
        __ j(LESS, &subtract, compiler::Assembler::kNearJump);
        __ addq(RDX, divisor_);
        __ jmp(exit_label());
        __ Bind(&subtract);
        __ subq(RDX, divisor_);
      } else if (divisor_range_->IsPositive()) {
        // Always positive.
        __ addq(RDX, divisor_);
      } else {
        // Always negative.
        __ subq(RDX, divisor_);
      }
      __ jmp(exit_label());
    }
  }

  const char* name() override { return "int64 divide"; }

  bool has_divide_by_zero() { return RangeUtils::CanBeZero(divisor_range_); }

  bool has_divide_by_minus_one() {
    return RangeUtils::Overlaps(divisor_range_, -1, -1);
  }

  bool has_adjust_sign() { return is_mod_; }

  bool is_needed() {
    return has_divide_by_zero() || has_divide_by_minus_one() ||
           has_adjust_sign();
  }

  compiler::Label* div_by_minus_one_label() {
    ASSERT(has_divide_by_minus_one());
    return &div_by_minus_one_label_;
  }

  compiler::Label* adjust_sign_label() {
    ASSERT(has_adjust_sign());
    return &adjust_sign_label_;
  }

 private:
  bool is_mod_;
  Register divisor_;
  Range* divisor_range_;
  compiler::Label div_by_minus_one_label_;
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

  // Special case 64-bit div/mod by compile-time constant. Note that various
  // special constants (such as powers of two) should have been optimized
  // earlier in the pipeline. Div or mod by zero falls into general code
  // to implement the exception.
  if (auto c = instruction->right()->definition()->AsConstant()) {
    if (c->value().IsInteger()) {
      const int64_t divisor = Integer::Cast(c->value()).AsInt64Value();
      if (divisor <= -2 || divisor >= 2) {
        // For x DIV c or x MOD c: use magic operations.
        compiler::Label pos;
        int64_t magic = 0;
        int64_t shift = 0;
        Utils::CalculateMagicAndShiftForDivRem(divisor, &magic, &shift);
        // RDX:RAX = magic * numerator.
        ASSERT(left == RAX);
        __ MoveRegister(TMP, RAX);  // save numerator
        __ LoadImmediate(RAX, compiler::Immediate(magic));
        __ imulq(TMP);
        // RDX +/-= numerator.
        if (divisor > 0 && magic < 0) {
          __ addq(RDX, TMP);
        } else if (divisor < 0 && magic > 0) {
          __ subq(RDX, TMP);
        }
        // Shift if needed.
        if (shift != 0) {
          __ sarq(RDX, compiler::Immediate(shift));
        }
        // RDX += 1 if RDX < 0.
        __ movq(RAX, RDX);
        __ shrq(RDX, compiler::Immediate(63));
        __ addq(RDX, RAX);
        // Finalize DIV or MOD.
        if (op_kind == Token::kTRUNCDIV) {
          ASSERT(out == RAX && tmp == RDX);
          __ movq(RAX, RDX);
        } else {
          ASSERT(out == RDX && tmp == RAX);
          __ movq(RAX, TMP);
          __ LoadImmediate(TMP, compiler::Immediate(divisor));
          __ imulq(RDX, TMP);
          __ subq(RAX, RDX);
          // Compensate for Dart's Euclidean view of MOD.
          __ testq(RAX, RAX);
          __ j(GREATER_EQUAL, &pos);
          if (divisor > 0) {
            __ addq(RAX, TMP);
          } else {
            __ subq(RAX, TMP);
          }
          __ Bind(&pos);
          __ movq(RDX, RAX);
        }
        return;
      }
    }
  }

  // Prepare a slow path.
  Range* right_range = instruction->right()->definition()->range();
  Int64DivideSlowPath* slow_path = new (Z) Int64DivideSlowPath(
      instruction, right, right_range, compiler->CurrentTryIndex());

  // Handle modulo/division by zero exception on slow path.
  if (slow_path->has_divide_by_zero()) {
    __ testq(right, right);
    __ j(EQUAL, slow_path->entry_label());
  }

  // Handle modulo/division by minus one explicitly on slow path
  // (to avoid arithmetic exception on 0x8000000000000000 / -1).
  if (slow_path->has_divide_by_minus_one()) {
    __ cmpq(right, compiler::Immediate(-1));
    __ j(EQUAL, slow_path->div_by_minus_one_label());
  }

  // Perform actual operation
  //   out = left % right
  // or
  //   out = left / right.
  //
  // Note that since 64-bit division requires twice as many cycles
  // and has much higher latency compared to the 32-bit division,
  // even for this non-speculative 64-bit path we add a "fast path".
  // Integers are untagged at this stage, so testing if sign extending
  // the lower half of each operand equals the full operand, effectively
  // tests if the values fit in 32-bit operands (and the slightly
  // dangerous division by -1 has been handled above already).
  ASSERT(left == RAX);
  ASSERT(right != RDX);  // available at this stage
  compiler::Label div_64;
  compiler::Label div_merge;
  __ movsxd(RDX, left);
  __ cmpq(RDX, left);
  __ j(NOT_EQUAL, &div_64, compiler::Assembler::kNearJump);
  __ movsxd(RDX, right);
  __ cmpq(RDX, right);
  __ j(NOT_EQUAL, &div_64, compiler::Assembler::kNearJump);
  __ cdq();         // sign-ext eax into edx:eax
  __ idivl(right);  // quotient eax, remainder edx
  __ movsxd(out, out);
  __ jmp(&div_merge, compiler::Assembler::kNearJump);
  __ Bind(&div_64);
  __ cqo();         // sign-ext rax into rdx:rax
  __ idivq(right);  // quotient rax, remainder rdx
  __ Bind(&div_merge);
  if (op_kind == Token::kMOD) {
    ASSERT(out == RDX);
    ASSERT(tmp == RAX);
    // For the % operator, again the idiv instruction does
    // not quite do what we want. Adjust for sign on slow path.
    __ testq(out, out);
    __ j(LESS, slow_path->adjust_sign_label());
  } else {
    ASSERT(out == RAX);
    ASSERT(tmp == RDX);
  }

  if (slow_path->is_needed()) {
    __ Bind(slow_path->exit_label());
    compiler->AddSlowPathCode(slow_path);
  }
}

template <typename OperandType>
static void EmitInt64Arithmetic(FlowGraphCompiler* compiler,
                                Token::Kind op_kind,
                                Register left,
                                const OperandType& right) {
  switch (op_kind) {
    case Token::kADD:
      __ addq(left, right);
      break;
    case Token::kSUB:
      __ subq(left, right);
      break;
    case Token::kBIT_AND:
      __ andq(left, right);
      break;
    case Token::kBIT_OR:
      __ orq(left, right);
      break;
    case Token::kBIT_XOR:
      __ xorq(left, right);
      break;
    case Token::kMUL:
      __ imulq(left, right);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  switch (op_kind()) {
    case Token::kMOD:
    case Token::kTRUNCDIV: {
      const intptr_t kNumInputs = 2;
      const intptr_t kNumTemps = 1;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
      summary->set_in(0, Location::RegisterLocation(RAX));
      summary->set_in(1, Location::RequiresRegister());
      // Intel uses rdx:rax with quotient rax and remainder rdx. Pick the
      // appropriate one for output and reserve the other as temp.
      summary->set_out(
          0, Location::RegisterLocation(op_kind() == Token::kMOD ? RDX : RAX));
      summary->set_temp(
          0, Location::RegisterLocation(op_kind() == Token::kMOD ? RAX : RDX));
      return summary;
    }
    default: {
      const intptr_t kNumInputs = 2;
      const intptr_t kNumTemps = 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, LocationRegisterOrConstant(right()));
      summary->set_out(0, Location::SameAsFirstInput());
      return summary;
    }
  }
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Location left = locs()->in(0);
  const Location right = locs()->in(1);
  const Location out = locs()->out(0);
  ASSERT(!can_overflow());
  ASSERT(!CanDeoptimize());

  if (op_kind() == Token::kMOD || op_kind() == Token::kTRUNCDIV) {
    const Location temp = locs()->temp(0);
    EmitInt64ModTruncDiv(compiler, this, op_kind(), left.reg(), right.reg(),
                         temp.reg(), out.reg());
  } else if (right.IsConstant()) {
    ASSERT(out.reg() == left.reg());
    int64_t value;
    const bool ok = compiler::HasIntegerValue(right.constant(), &value);
    RELEASE_ASSERT(ok);
    EmitInt64Arithmetic(compiler, op_kind(), left.reg(),
                        compiler::Immediate(value));
  } else {
    ASSERT(out.reg() == left.reg());
    EmitInt64Arithmetic(compiler, op_kind(), left.reg(), right.reg());
  }
}

LocationSummary* UnaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(out == left);
  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ notq(left);
      break;
    case Token::kNEGATE:
      __ negq(left);
      break;
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register left,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  switch (op_kind) {
    case Token::kSHR:
      __ sarq(left, compiler::Immediate(
                        Utils::Minimum<int64_t>(shift, kBitsPerWord - 1)));
      break;
    case Token::kSHL: {
      ASSERT(shift < 64);
      __ shlq(left, compiler::Immediate(shift));
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByRCX(FlowGraphCompiler* compiler,
                                Token::Kind op_kind,
                                Register left) {
  switch (op_kind) {
    case Token::kSHR: {
      __ sarq(left, RCX);
      break;
    }
    case Token::kSHL: {
      __ shlq(left, RCX);
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftUint32ByConstant(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register left,
                                      const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  if (shift >= 32) {
    __ xorl(left, left);
  } else {
    switch (op_kind) {
      case Token::kSHR: {
        __ shrl(left, compiler::Immediate(shift));
        break;
      }
      case Token::kSHL: {
        __ shll(left, compiler::Immediate(shift));
        break;
      }
      default:
        UNREACHABLE();
    }
  }
}

static void EmitShiftUint32ByRCX(FlowGraphCompiler* compiler,
                                 Token::Kind op_kind,
                                 Register left) {
  switch (op_kind) {
    case Token::kSHR: {
      __ shrl(left, RCX);
      break;
    }
    case Token::kSHL: {
      __ shll(left, RCX);
      break;
    }
    default:
      UNREACHABLE();
  }
}

class ShiftInt64OpSlowPath : public ThrowErrorSlowPathCode {
 public:
  ShiftInt64OpSlowPath(ShiftInt64OpInstr* instruction, intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry,
                               try_index) {}

  const char* name() override { return "int64 shift"; }

  void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) override {
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT(out == instruction()->locs()->in(0).reg());

    compiler::Label throw_error;
    __ testq(RCX, RCX);
    __ j(LESS, &throw_error);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ sarq(out, compiler::Immediate(kBitsPerInt64 - 1));
        break;
      case Token::kSHL:
        __ xorq(out, out);
        break;
      default:
        UNREACHABLE();
    }
    __ jmp(exit_label());

    __ Bind(&throw_error);

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ movq(compiler::Address(THR, Thread::unboxed_int64_runtime_arg_offset()),
            RCX);
  }
};

LocationSummary* ShiftInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, RangeUtils::IsPositive(shift_range())
                         ? LocationFixedRegisterOrConstant(right(), RCX)
                         : Location::RegisterLocation(RCX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(left == out);
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), left,
                             locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    ASSERT(locs()->in(1).reg() == RCX);

    // Jump to a slow path if shift count is > 63 or negative.
    ShiftInt64OpSlowPath* slow_path = NULL;
    if (!IsShiftCountInRange()) {
      slow_path =
          new (Z) ShiftInt64OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);

      __ cmpq(RCX, compiler::Immediate(kShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftInt64ByRCX(compiler, op_kind(), left);

    if (slow_path != NULL) {
      __ Bind(slow_path->exit_label());
    }
  }
}

LocationSummary* SpeculativeShiftInt64OpInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void SpeculativeShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(left == out);
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), left,
                             locs()->in(1).constant());
  } else {
    ASSERT(locs()->in(1).reg() == RCX);
    __ SmiUntag(RCX);

    // Deoptimize if shift count is > 63 or negative (or not a smi).
    if (!IsShiftCountInRange()) {
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

      __ cmpq(RCX, compiler::Immediate(kShiftCountLimit));
      __ j(ABOVE, deopt);
    }

    EmitShiftInt64ByRCX(compiler, op_kind(), left);
  }
}

class ShiftUint32OpSlowPath : public ThrowErrorSlowPathCode {
 public:
  ShiftUint32OpSlowPath(ShiftUint32OpInstr* instruction, intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry,
                               try_index) {}

  const char* name() override { return "uint32 shift"; }

  void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) override {
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT(out == instruction()->locs()->in(0).reg());

    compiler::Label throw_error;
    __ testq(RCX, RCX);
    __ j(LESS, &throw_error);

    __ xorl(out, out);
    __ jmp(exit_label());

    __ Bind(&throw_error);

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ movq(compiler::Address(THR, Thread::unboxed_int64_runtime_arg_offset()),
            RCX);
  }
};

LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, RangeUtils::IsPositive(shift_range())
                         ? LocationFixedRegisterOrConstant(right(), RCX)
                         : Location::RegisterLocation(RCX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(left == out);

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), left,
                              locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    ASSERT(locs()->in(1).reg() == RCX);

    // Jump to a slow path if shift count is > 31 or negative.
    ShiftUint32OpSlowPath* slow_path = NULL;
    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      slow_path =
          new (Z) ShiftUint32OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);

      __ cmpq(RCX, compiler::Immediate(kUint32ShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftUint32ByRCX(compiler, op_kind(), left);

    if (slow_path != NULL) {
      __ Bind(slow_path->exit_label());
    }
  }
}

LocationSummary* SpeculativeShiftUint32OpInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void SpeculativeShiftUint32OpInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(left == out);

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), left,
                              locs()->in(1).constant());
  } else {
    ASSERT(locs()->in(1).reg() == RCX);
    __ SmiUntag(RCX);

    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      if (!IsShiftCountInRange()) {
        // Deoptimize if shift count is negative.
        ASSERT(CanDeoptimize());
        compiler::Label* deopt =
            compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

        __ testq(RCX, RCX);
        __ j(LESS, deopt);
      }

      compiler::Label cont;
      __ cmpq(RCX, compiler::Immediate(kUint32ShiftCountLimit));
      __ j(LESS_EQUAL, &cont);

      __ xorl(left, left);

      __ Bind(&cont);
    }

    EmitShiftUint32ByRCX(compiler, op_kind(), left);
  }
}

LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

template <typename OperandType>
static void EmitIntegerArithmetic(FlowGraphCompiler* compiler,
                                  Token::Kind op_kind,
                                  Register left,
                                  const OperandType& right) {
  switch (op_kind) {
    case Token::kADD:
      __ addl(left, right);
      break;
    case Token::kSUB:
      __ subl(left, right);
      break;
    case Token::kBIT_AND:
      __ andl(left, right);
      break;
    case Token::kBIT_OR:
      __ orl(left, right);
      break;
    case Token::kBIT_XOR:
      __ xorl(left, right);
      break;
    case Token::kMUL:
      __ imull(left, right);
      break;
    default:
      UNREACHABLE();
  }
}

void BinaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register out = locs()->out(0).reg();
  ASSERT(out == left);
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
      EmitIntegerArithmetic(compiler, op_kind(), left, right);
      return;
    default:
      UNREACHABLE();
  }
}

DEFINE_BACKEND(UnaryUint32Op, (SameAsFirstInput, Register value)) {
  ASSERT(instr->op_kind() == Token::kBIT_NOT);
  __ notl(value);
}

DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)

LocationSummary* IntConverterInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUntagged || to() == kUntagged) {
    ASSERT((from() == kUntagged && to() == kUnboxedIntPtr) ||
           (from() == kUnboxedIntPtr && to() == kUntagged));
    ASSERT(!CanDeoptimize());
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
  const bool is_nop_conversion =
      (from() == kUntagged && to() == kUnboxedIntPtr) ||
      (from() == kUnboxedIntPtr && to() == kUntagged);
  if (is_nop_conversion) {
    ASSERT(locs()->in(0).reg() == locs()->out(0).reg());
    return;
  }

  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent but we want to normalize
    // upperbits for safety reasons.
    // TODO(vegorov) if we ensure that we never use upperbits we could
    // avoid this.
    __ movl(out, value);
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    // Representations are bitwise equivalent.
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    __ movsxd(out, value);
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ testl(out, out);
      __ j(NEGATIVE, deopt);
    }
  } else if (from() == kUnboxedInt64) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    if (!CanDeoptimize()) {
      // Copy low.
      __ movl(out, value);
    } else {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      // Sign extend.
      __ movsxd(out, value);
      // Compare with original value.
      __ cmpq(out, value);
      // Value cannot be held in Int32, deopt.
      __ j(NOT_EQUAL, deopt);
    }
  } else if (to() == kUnboxedInt64) {
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    if (from() == kUnboxedUint32) {
      // Zero extend.
      __ movl(out, value);
    } else {
      // Sign extend.
      ASSERT(from() == kUnboxedInt32);
      __ movsxd(out, value);
    }
  } else {
    UNREACHABLE();
  }
}

LocationSummary* StopInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}

void StopInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Stop(message());
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
      __ jmp(compiler->GetJumpLabel(entry));
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
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.
    compiler->AddCurrentDescriptor(PcDescriptorsLayout::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // We can fall through if the successor is the next block in the list.
  // Otherwise, we need a jump.
  if (!compiler->CanFallThroughTo(successor())) {
    __ jmp(compiler->GetJumpLabel(successor()));
  }
}

LocationSummary* IndirectGotoInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());

  return summary;
}

void IndirectGotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register offset_reg = locs()->in(0).reg();
  Register target_address_reg = locs()->temp(0).reg();

  {
    const intptr_t kRIPRelativeLeaqSize = 7;
    const intptr_t entry_to_rip_offset = __ CodeSize() + kRIPRelativeLeaqSize;
    __ leaq(target_address_reg,
            compiler::Address::AddressRIPRelative(-entry_to_rip_offset));
    ASSERT(__ CodeSize() == entry_to_rip_offset);
  }

  // Load from FP+compiler::target::frame_layout.code_from_fp.

  // Calculate the final absolute address.
  if (offset()->definition()->representation() == kTagged) {
    __ SmiUntag(offset_reg);
  }
  __ addq(target_address_reg, offset_reg);

  // Jump to the absolute address.
  __ jmp(target_address_reg);
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(RAX));
    locs->set_in(1, Location::RegisterLocation(RCX));
    locs->set_out(0, Location::RegisterLocation(RAX));
    return locs;
  }
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, LocationRegisterOrConstant(left()));
  // Only one of the inputs can be a constant. Choose register if the first one
  // is a constant.
  locs->set_in(1, locs->in(0).IsConstant()
                      ? Location::RequiresRegister()
                      : LocationRegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition StrictCompareInstr::EmitComparisonCodeRegConstant(
    FlowGraphCompiler* compiler,
    BranchLabels labels,
    Register reg,
    const Object& obj) {
  return compiler->EmitEqualityRegConstCompare(reg, obj, needs_number_check(),
                                               source(), deopt_id());
}

LocationSummary* DispatchTableCallInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RCX));  // ClassId
  return MakeCallSummary(zone, this, summary);
}

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RAX));  // Function.
  return MakeCallSummary(zone, this, summary);
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Arguments descriptor is expected in R10.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(R10, arguments_descriptor);

  // Function in RAX.
  ASSERT(locs()->in(0).reg() == RAX);
  if (!FLAG_precompiled_mode || !FLAG_use_bare_instructions) {
    __ movq(CODE_REG, compiler::FieldAddress(
                          RAX, compiler::target::Function::code_offset()));
  }
  __ movq(
      RCX,
      compiler::FieldAddress(
          RAX, compiler::target::Function::entry_point_offset(entry_kind())));

  // RAX: Function.
  // R10: Arguments descriptor array.
  if (!FLAG_precompiled_mode) {
    // RBX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ xorq(RBX, RBX);
  }
  __ call(RCX);
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 PcDescriptorsLayout::kOther, locs());
  __ Drop(argument_count);
}

LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1,
                               value()->Type()->ToCid() == kBoolCid
                                   ? Location::SameAsFirstInput()
                                   : Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register input = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  if (value()->Type()->ToCid() == kBoolCid) {
    ASSERT(input == result);
    __ xorq(result, compiler::Immediate(
                        compiler::target::ObjectAlignment::kBoolValueMask));
  } else {
    ASSERT(input != result);
    compiler::Label done;
    __ LoadObject(result, Bool::True());
    __ CompareRegisters(result, input);
    __ j(NOT_EQUAL, &done, compiler::Assembler::kNearJump);
    __ LoadObject(result, Bool::False());
    __ Bind(&done);
  }
}

LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = (type_arguments() != nullptr) ? 1 : 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  if (type_arguments() != nullptr) {
    locs->set_in(0,
                 Location::RegisterLocation(kAllocationStubTypeArgumentsReg));
  }
  locs->set_out(0, Location::RegisterLocation(RAX));
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
  compiler->GenerateStubCall(source(), stub, PcDescriptorsLayout::kOther,
                             locs());
}

void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#ifdef PRODUCT
  UNREACHABLE();
#else
  ASSERT(!compiler->is_optimizing());
  __ CallPatchable(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

}  // namespace dart

#undef __

#endif  // defined(TARGET_ARCH_X64)
