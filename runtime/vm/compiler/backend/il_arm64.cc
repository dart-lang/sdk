// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/compiler/backend/il.h"

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
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"

#define __ (compiler->assembler())->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0 (or V0 if
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
  const intptr_t kNumTemps = ((representation() == kUnboxedDouble) ? 1 : 0);
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  locs->set_in(0, Location::RequiresRegister());
  switch (representation()) {
    case kTagged:
    case kUnboxedInt64:
      locs->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedDouble:
      locs->set_temp(0, Location::RequiresRegister());
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
      __ add(out, base_reg(), compiler::Operand(index, LSL, 2));
      __ LoadFromOffset(out, out, offset());
      break;
    }
    case kUnboxedDouble: {
      const auto tmp = locs()->temp(0).reg();
      const auto out = locs()->out(0).fpu_reg();
      __ add(tmp, base_reg(), compiler::Operand(index, LSL, 2));
      __ LoadDFromOffset(out, tmp, offset());
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
  __ add(TMP, instr->base_reg(), compiler::Operand(index, LSL, 2));
  __ str(value, compiler::Address(TMP, instr->offset()));

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(TailCall,
               (NoLocation,
                Fixed<Register, ARGS_DESC_REG>,
                Temp<Register> temp)) {
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
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::WritableRegister());
  locs->set_in(kDestPos, Location::WritableRegister());
  locs->set_in(kSrcStartPos, Location::RequiresRegister());
  locs->set_in(kDestStartPos, Location::RequiresRegister());
  locs->set_in(kLengthPos, Location::WritableRegister());
  locs->set_temp(0, element_size_ == 16
                        ? Location::Pair(Location::RequiresRegister(),
                                         Location::RequiresRegister())
                        : Location::RequiresRegister());
  return locs;
}

void MemoryCopyInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register src_reg = locs()->in(kSrcPos).reg();
  const Register dest_reg = locs()->in(kDestPos).reg();
  const Register src_start_reg = locs()->in(kSrcStartPos).reg();
  const Register dest_start_reg = locs()->in(kDestStartPos).reg();
  const Register length_reg = locs()->in(kLengthPos).reg();

  Register temp_reg, temp_reg2;
  if (locs()->temp(0).IsPairLocation()) {
    PairLocation* pair = locs()->temp(0).AsPairLocation();
    temp_reg = pair->At(0).reg();
    temp_reg2 = pair->At(1).reg();
  } else {
    temp_reg = locs()->temp(0).reg();
    temp_reg2 = kNoRegister;
  }

  EmitComputeStartPointer(compiler, src_cid_, src_start(), src_reg,
                          src_start_reg);
  EmitComputeStartPointer(compiler, dest_cid_, dest_start(), dest_reg,
                          dest_start_reg);

  compiler::Label loop, done;

  compiler::Address src_address =
      compiler::Address(src_reg, element_size_, compiler::Address::PostIndex);
  compiler::Address dest_address =
      compiler::Address(dest_reg, element_size_, compiler::Address::PostIndex);

  // Untag length and skip copy if length is zero.
  __ adds(length_reg, ZR, compiler::Operand(length_reg, ASR, 1));
  __ b(&done, ZERO);

  __ Bind(&loop);
  switch (element_size_) {
    case 1:
      __ ldr(temp_reg, src_address, compiler::kUnsignedByte);
      __ str(temp_reg, dest_address, compiler::kUnsignedByte);
      break;
    case 2:
      __ ldr(temp_reg, src_address, compiler::kUnsignedTwoBytes);
      __ str(temp_reg, dest_address, compiler::kUnsignedTwoBytes);
      break;
    case 4:
      __ ldr(temp_reg, src_address, compiler::kUnsignedFourBytes);
      __ str(temp_reg, dest_address, compiler::kUnsignedFourBytes);
      break;
    case 8:
      __ ldr(temp_reg, src_address, compiler::kEightBytes);
      __ str(temp_reg, dest_address, compiler::kEightBytes);
      break;
    case 16:
      __ ldp(temp_reg, temp_reg2, src_address, compiler::kEightBytes);
      __ stp(temp_reg, temp_reg2, dest_address, compiler::kEightBytes);
      break;
  }
  __ subs(length_reg, length_reg, compiler::Operand(1));
  __ b(&loop, NOT_ZERO);
  __ Bind(&done);
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Value* start,
                                              Register array_reg,
                                              Register start_reg) {
  if (IsTypedDataBaseClassId(array_cid)) {
    __ ldr(
        array_reg,
        compiler::FieldAddress(
            array_reg, compiler::target::TypedDataBase::data_field_offset()));
  } else {
    switch (array_cid) {
      case kOneByteStringCid:
        __ add(
            array_reg, array_reg,
            compiler::Operand(compiler::target::OneByteString::data_offset() -
                              kHeapObjectTag));
        break;
      case kTwoByteStringCid:
        __ add(
            array_reg, array_reg,
            compiler::Operand(compiler::target::OneByteString::data_offset() -
                              kHeapObjectTag));
        break;
      case kExternalOneByteStringCid:
        __ ldr(array_reg,
               compiler::FieldAddress(array_reg,
                                      compiler::target::ExternalOneByteString::
                                          external_data_offset()));
        break;
      case kExternalTwoByteStringCid:
        __ ldr(array_reg,
               compiler::FieldAddress(array_reg,
                                      compiler::target::ExternalTwoByteString::
                                          external_data_offset()));
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
  intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) - 1;
  if (shift < 0) {
    __ add(array_reg, array_reg, compiler::Operand(start_reg, ASR, -shift));
  } else {
    __ add(array_reg, array_reg, compiler::Operand(start_reg, LSL, shift));
  }
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

// Buffers registers in order to use STP to push
// two registers at once.
class ArgumentsPusher : public ValueObject {
 public:
  ArgumentsPusher() {}

  // Flush all buffered registers.
  void Flush(FlowGraphCompiler* compiler) {
    if (pending_register_ != kNoRegister) {
      __ Push(pending_register_);
      pending_register_ = kNoRegister;
    }
  }

  // Buffer given register. May push buffered registers if needed.
  void PushRegister(FlowGraphCompiler* compiler, Register reg) {
    if (pending_register_ != kNoRegister) {
      __ PushPair(reg, pending_register_);
      pending_register_ = kNoRegister;
      return;
    }
    pending_register_ = reg;
  }

  // Returns free temp register to hold argument value.
  Register GetFreeTempRegister(FlowGraphCompiler* compiler) {
    CLOBBERS_LR({
      // While pushing arguments only Push, PushPair, LoadObject and
      // LoadFromOffset are used. They do not clobber TMP or LR.
      static_assert(((1 << LR) & kDartAvailableCpuRegs) == 0,
                    "LR should not be allocatable");
      static_assert(((1 << TMP) & kDartAvailableCpuRegs) == 0,
                    "TMP should not be allocatable");
      return (pending_register_ == TMP) ? LR : TMP;
    });
  }

 private:
  Register pending_register_ = kNoRegister;
};

void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where arguments are pushed by their definitions.
  if (compiler->is_optimizing()) {
    if (previous()->IsPushArgument()) {
      // Already generated.
      return;
    }
    ArgumentsPusher pusher;
    for (PushArgumentInstr* push_arg = this; push_arg != nullptr;
         push_arg = push_arg->next()->AsPushArgument()) {
      const Location value = push_arg->locs()->in(0);
      Register reg = kNoRegister;
      if (value.IsRegister()) {
        reg = value.reg();
      } else if (value.IsConstant()) {
        if (compiler::IsSameObject(compiler::NullObject(), value.constant())) {
          reg = NULL_REG;
        } else {
          reg = pusher.GetFreeTempRegister(compiler);
          __ LoadObject(reg, value.constant());
        }
      } else if (value.IsFpuRegister()) {
        pusher.Flush(compiler);
        __ PushDouble(value.fpu_reg());
        continue;
      } else {
        ASSERT(value.IsStackSlot());
        const intptr_t value_offset = value.ToStackSlotOffset();
        reg = pusher.GetFreeTempRegister(compiler);
        __ LoadFromOffset(reg, value.base_reg(), value_offset);
      }
      pusher.PushRegister(compiler, reg);
    }
    pusher.Flush(compiler);
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
// that will be overwritten by the patch instructions: a branch macro sequence.
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
  compiler::Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ sub(R2, SP, compiler::Operand(FP));
  __ CompareImmediate(R2, fp_sp_dist);
  __ b(&stack_ok, EQ);
  __ brk(0);
  __ Bind(&stack_ok);
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

// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}

LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  return comparison()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

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
      // We need to have zero in result on true_condition.
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

  __ cset(result, true_condition);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ LslImmediate(result, result, shift + kSmiTagSize);
  } else {
    __ sub(result, result, compiler::Operand(1));
    const int64_t val = Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, Smi::RawValue(false_value));
    }
  }
}

LocationSummary* DispatchTableCallInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // ClassId
  return MakeCallSummary(zone, this, summary);
}

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Function.
  return MakeCallSummary(zone, this, summary);
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor in R4.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(R4, arguments_descriptor);

  // R4: Arguments descriptor.
  // R0: Function.
  ASSERT(locs()->in(0).reg() == R0);
  if (!FLAG_precompiled_mode || !FLAG_use_bare_instructions) {
    __ LoadFieldFromOffset(CODE_REG, R0,
                           compiler::target::Function::code_offset());
  }
  __ LoadFieldFromOffset(
      R2, R0, compiler::target::Function::entry_point_offset(entry_kind()));

  // R2: instructions.
  if (!FLAG_precompiled_mode) {
    // R5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ LoadImmediate(R5, 0);
  }
  __ blr(R2);
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 PcDescriptorsLayout::kOther, locs());
  __ Drop(argument_count);
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
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ StoreToOffset(value, FP,
                   compiler::target::FrameOffsetInBytesForVariable(&local()));
}

LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    const Register result = locs()->out(0).reg();
    __ LoadObject(result, value());
  }
}

void ConstantInstr::EmitMoveToLocation(FlowGraphCompiler* compiler,
                                       const Location& destination,
                                       Register tmp) {
  if (destination.IsRegister()) {
    if (representation() == kUnboxedInt32 ||
        representation() == kUnboxedUint32 ||
        representation() == kUnboxedInt64) {
      const int64_t value = Integer::Cast(value_).AsInt64Value();
      __ LoadImmediate(destination.reg(), value);
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const VRegister dst = destination.fpu_reg();
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0)) {
      __ veor(dst, dst, dst);
    } else {
      __ LoadDImmediate(dst, Double::Cast(value_).value());
    }
  } else if (destination.IsDoubleStackSlot()) {
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0)) {
      __ veor(VTMP, VTMP, VTMP);
    } else {
      __ LoadDImmediate(VTMP, Double::Cast(value_).value());
    }
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    __ StoreDToOffset(VTMP, destination.base_reg(), dest_offset);
  } else {
    ASSERT(destination.IsStackSlot());
    ASSERT(tmp != kNoRegister);
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    if (representation() == kUnboxedInt32 ||
        representation() == kUnboxedUint32 ||
        representation() == kUnboxedInt64) {
      const int64_t value = Integer::Cast(value_).AsInt64Value();
      __ LoadImmediate(tmp, value);
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(tmp, value_);
    }
    __ StoreToOffset(tmp, destination.base_reg(), dest_offset);
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
  // entering runtime. ARM64 ABI only guarantees that lower
  // 64-bits of an V registers are preserved so we block all
  // of them except for FpuTMP.
  const intptr_t kCpuRegistersToPreserve =
      kDartAvailableCpuRegs & ~kNonChangeableInputRegs;
  const intptr_t kFpuRegistersToPreserve =
      Utils::SignedNBitMask(kNumberOfFpuRegisters) & ~(1l << FpuTMP);

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
    const bool should_preserve = ((1l << i) & kFpuRegistersToPreserve) != 0;
    if (should_preserve) {
      summary->set_temp(next_temp++, Location::FpuRegisterLocation(
                                         static_cast<FpuRegister>(i)));
    }
  }

  return summary;
}

static Condition TokenKindToSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQ;
    case Token::kNE:
      return NE;
    case Token::kLT:
      return LT;
    case Token::kGT:
      return GT;
    case Token::kLTE:
      return LE;
    case Token::kGTE:
      return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}

static Condition FlipCondition(Condition condition) {
  switch (condition) {
    case EQ:
      return EQ;
    case NE:
      return NE;
    case LT:
      return GT;
    case LE:
      return GE;
    case GT:
      return LT;
    case GE:
      return LE;
    case CC:
      return HI;
    case LS:
      return CS;
    case HI:
      return CC;
    case CS:
      return LS;
    default:
      UNREACHABLE();
      return EQ;
  }
}

static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor we will fall through to it.
    __ b(labels.true_label, true_condition);
  } else {
    // If the next block is not the false successor we will branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ b(labels.false_label, false_condition);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
}

static bool AreLabelsNull(BranchLabels labels) {
  return (labels.true_label == nullptr && labels.false_label == nullptr &&
          labels.fall_through == nullptr);
}

static bool CanUseCbzTbzForComparison(FlowGraphCompiler* compiler,
                                      Register rn,
                                      Condition cond,
                                      BranchLabels labels) {
  return !AreLabelsNull(labels) && __ CanGenerateXCbzTbz(rn, cond);
}

static void EmitCbzTbz(Register reg,
                       FlowGraphCompiler* compiler,
                       Condition true_condition,
                       BranchLabels labels) {
  ASSERT(CanUseCbzTbzForComparison(compiler, reg, true_condition, labels));
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor we will fall through to it.
    __ GenerateXCbzTbz(reg, true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor we will branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ GenerateXCbzTbz(reg, false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
}

// Similar to ComparisonInstr::EmitComparisonCode, may either:
//   - emit comparison code and return a valid condition in which case the
//     caller is expected to emit a branch to the true label based on that
//     condition (or a branch to the false label on the opposite condition).
//   - emit comparison code with a branch directly to the labels and return
//     kInvalidCondition.
static Condition EmitInt64ComparisonOp(FlowGraphCompiler* compiler,
                                       LocationSummary* locs,
                                       Token::Kind kind,
                                       BranchLabels labels) {
  Location left = locs->in(0);
  Location right = locs->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToSmiCondition(kind);
  if (left.IsConstant() || right.IsConstant()) {
    // Ensure constant is on the right.
    ConstantInstr* constant = nullptr;
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
      if (value == 0 && CanUseCbzTbzForComparison(compiler, left.reg(),
                                                  true_condition, labels)) {
        EmitCbzTbz(left.reg(), compiler, true_condition, labels);
        return kInvalidCondition;
      }
      __ CompareImmediate(left.reg(), value);
    } else {
      ASSERT(constant->representation() == kTagged);
      __ CompareObject(left.reg(), right.constant());
    }
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }
  return true_condition;
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

static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQ;
    case Token::kNE:
      return NE;
    case Token::kLT:
      return LT;
    case Token::kGT:
      return GT;
    case Token::kLTE:
      return LE;
    case Token::kGTE:
      return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        LocationSummary* locs,
                                        BranchLabels labels,
                                        Token::Kind kind) {
  const VRegister left = locs->in(0).fpu_reg();
  const VRegister right = locs->in(1).fpu_reg();
  __ fcmpd(left, right);
  Condition true_condition = TokenKindToDoubleCondition(kind);
  if (true_condition != NE) {
    // Special case for NaN comparison. Result is always false unless
    // relational operator is !=.
    __ b(labels.false_label, VS);
  }
  return true_condition;
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid) {
    return EmitInt64ComparisonOp(compiler, locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), labels, kind());
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
  const Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int64_t imm = static_cast<int64_t>(right.constant().raw());
    __ TestImmediate(left, imm);
  } else {
    __ tst(left, compiler::Operand(right.reg()));
  }
  Condition true_condition = (kind() == Token::kNE) ? NE : EQ;
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
  const Register val_reg = locs()->in(0).reg();
  const Register cid_reg = locs()->temp(0).reg();

  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids,
                                   licm_hoisted_ ? ICData::kHoisted : 0)
          : NULL;

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
    __ b(result ? labels.true_label : labels.false_label, EQ);
  }
  // No match found, deoptimize or default action.
  if (deopt == NULL) {
    // If the cid is not in the list, jump to the opposite label from the cids
    // that are in the list.  These must be all the same (see asserts in the
    // constructor).
    compiler::Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ b(target);
    }
  } else {
    __ b(deopt);
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
    return EmitInt64ComparisonOp(compiler, locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), labels, kind());
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // All arguments are already @SP due to preceding PushArgument()s.
  ASSERT(ArgumentCount() ==
         function().NumParameters() + (function().IsGeneric() ? 1 : 0));

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());

  // Pass a pointer to the first argument in R2.
  __ AddImmediate(R2, SP, ArgumentCount() * kWordSize);

  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
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
  __ LoadImmediate(R1, argc_tag);
  compiler::ExternalLabel label(entry);
  __ LoadNativeEntry(R5, &label,
                     link_lazily() ? ObjectPool::Patchability::kPatchable
                                   : ObjectPool::Patchability::kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(source(), *stub,
                                    PcDescriptorsLayout::kOther, locs());
  } else {
    compiler->GenerateStubCall(source(), *stub, PcDescriptorsLayout::kOther,
                               locs());
  }
  __ Pop(result);

  __ Drop(ArgumentCount());  // Drop the arguments.
}

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = locs()->temp(0).reg();
  const Register temp = locs()->temp(1).reg();
  const Register branch = locs()->in(TargetAddressIndex()).reg();

  // Save frame pointer because we're going to update it when we enter the exit
  // frame.
  __ mov(saved_fp, FPREG);

  // We need to create a dummy "exit frame". It will share the same pool pointer
  // but have a null code object.
  __ LoadObject(CODE_REG, Object::null_object());
  __ set_constant_pool_allowed(false);
  __ EnterDartFrame(0, PP);

  // Make space for arguments and align the frame.
  __ ReserveAlignedFrameSpace(marshaller_.RequiredStackSpaceInBytes());

  EmitParamMoves(compiler);

  if (compiler::Assembler::EmittingComments()) {
    __ Comment("Call");
  }
  // We need to copy a dummy return address up into the dummy stack frame so the
  // stack walker will know which safepoint to use.
  //
  // ADR loads relative to itself, so add kInstrSize to point to the next
  // instruction.
  __ adr(temp, compiler::Immediate(Instr::kInstrSize));
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 PcDescriptorsLayout::Kind::kOther, locs());

  __ StoreToOffset(temp, FPREG, kSavedCallerPcSlotFromFp * kWordSize);

  if (CanExecuteGeneratedCodeInSafepoint()) {
    // Update information in the thread object and enter a safepoint.
    __ LoadImmediate(temp, compiler::target::Thread::exit_through_ffi());
    __ TransitionGeneratedToNative(branch, FPREG, temp,
                                   /*enter_safepoint=*/true);

    // We are entering runtime code, so the C stack pointer must be restored
    // from the stack limit to the top of the stack.
    __ mov(R25, CSP);
    __ mov(CSP, SP);

    __ blr(branch);

    // Restore the Dart stack pointer.
    __ mov(SP, CSP);
    __ mov(CSP, R25);

    // Update information in the thread object and leave the safepoint.
    __ TransitionNativeToGenerated(temp, /*leave_safepoint=*/true);
  } else {
    // We cannot trust that this code will be executable within a safepoint.
    // Therefore we delegate the responsibility of entering/exiting the
    // safepoint to a stub which in the VM isolate's heap, which will never lose
    // execute permission.
    __ ldr(TMP,
           compiler::Address(
               THR, compiler::target::Thread::
                        call_native_through_safepoint_entry_point_offset()));

    // Calls R9 and clobbers R19 (along with volatile registers).
    ASSERT(branch == R9 && temp == R19);
    __ blr(TMP);
  }

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  EmitReturnMoves(compiler);

  // Although PP is a callee-saved register, it may have been moved by the GC.
  __ LeaveDartFrame(compiler::kRestoreCallerPP);

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  __ set_constant_pool_allowed(true);
}

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  __ LeaveDartFrame();

  // The dummy return address is in LR, no need to pop it as on Intel.

  // These can be anything besides the return registers (R0, R1) and THR (R26).
  const Register vm_tag_reg = R2;
  const Register old_exit_frame_reg = R3;
  const Register old_exit_through_ffi_reg = R4;
  const Register tmp = R5;

  __ PopPair(old_exit_frame_reg, old_exit_through_ffi_reg);

  // Restore top_resource.
  __ PopPair(tmp, vm_tag_reg);
  __ StoreToOffset(tmp, THR, compiler::target::Thread::top_resource_offset());

  // Reset the exit frame info to old_exit_frame_reg *before* entering the
  // safepoint.
  //
  // If we were called by a trampoline, it will enter the safepoint on our
  // behalf.
  __ TransitionGeneratedToNative(
      vm_tag_reg, old_exit_frame_reg, old_exit_through_ffi_reg,
      /*enter_safepoint=*/!NativeCallbackTrampolines::Enabled());

  __ PopNativeCalleeSavedRegisters();

  // Leave the entry frame.
  __ LeaveFrame();

  // Leave the dummy frame holding the pushed arguments.
  __ LeaveFrame();

  // Restore the actual stack pointer from SPREG.
  __ RestoreCSP();

  __ Ret();

  // For following blocks.
  __ set_constant_pool_allowed(true);
}

// Keep in sync with NativeReturnInstr::EmitNativeCode and ComputeInnerLRState.
void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Constant pool cannot be used until we enter the actual Dart frame.
  __ set_constant_pool_allowed(false);

  __ Bind(compiler->GetJumpLabel(this));

  // We don't use the regular stack pointer in ARM64, so we have to copy the
  // native stack pointer into the Dart stack pointer. This will also kick CSP
  // forward a bit, enough for the spills and leaf call below, until we can set
  // it properly after setting up THR.
  __ SetupDartSP();

  // Create a dummy frame holding the pushed arguments. This simplifies
  // NativeReturnInstr::EmitNativeCode.
  __ EnterFrame(0);

  // Save the argument registers, in reverse order.
  SaveArguments(compiler);

  // Enter the entry frame.
  __ EnterFrame(0);

  // Save a space for the code object.
  __ PushImmediate(0);

  __ PushNativeCalleeSavedRegisters();

  // Load the thread object. If we were called by a trampoline, the thread is
  // already loaded.
  if (FLAG_precompiled_mode) {
    compiler->LoadBSSEntry(BSS::Relocation::DRT_GetThreadForNativeCallback, R1,
                           R0);
  } else if (!NativeCallbackTrampolines::Enabled()) {
    // In JIT mode, we can just paste the address of the runtime entry into the
    // generated code directly. This is not a problem since we don't save
    // callbacks into JIT snapshots.
    __ LoadImmediate(
        R1, reinterpret_cast<int64_t>(DLRT_GetThreadForNativeCallback));
  }

  if (!NativeCallbackTrampolines::Enabled()) {
    // Create another frame to align the frame before continuing in "native"
    // code.
    __ EnterFrame(0);
    __ ReserveAlignedFrameSpace(0);

    __ LoadImmediate(R0, callback_id_);
    __ blr(R1);
    __ mov(THR, R0);

    __ LeaveFrame();
  }

  // Now that we have THR, we can set CSP.
  __ SetupCSPFromThread(THR);

#if defined(TARGET_OS_FUCHSIA)
  __ str(R18,
         compiler::Address(
             THR, compiler::target::Thread::saved_shadow_call_stack_offset()));
#elif defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Save the current VMTag on the stack.
  __ LoadFromOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());
  // Save the top resource.
  __ LoadFromOffset(R0, THR, compiler::target::Thread::top_resource_offset());
  __ PushPair(R0, TMP);

  __ StoreToOffset(ZR, THR, compiler::target::Thread::top_resource_offset());

  __ LoadFromOffset(R0, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ Push(R0);

  // Save the top exit frame info. We don't set it to 0 yet:
  // TransitionNativeToGenerated will handle that.
  __ LoadFromOffset(R0, THR,
                    compiler::target::Thread::top_exit_frame_info_offset());
  __ Push(R0);

  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // Either DLRT_GetThreadForNativeCallback or the callback trampoline (caller)
  // will leave the safepoint for us.
  __ TransitionNativeToGenerated(R0, /*exit_safepoint=*/false);

  // Now that the safepoint has ended, we can touch Dart objects without
  // handles.

  // Load the code object.
  __ LoadFromOffset(R0, THR, compiler::target::Thread::callback_code_offset());
  __ LoadFieldFromOffset(R0, R0,
                         compiler::target::GrowableObjectArray::data_offset());
  __ LoadFieldFromOffset(CODE_REG, R0,
                         compiler::target::Array::data_offset() +
                             callback_id_ * compiler::target::kWordSize);

  // Put the code object in the reserved slot.
  __ StoreToOffset(CODE_REG, FPREG,
                   kPcMarkerSlotFromFp * compiler::target::kWordSize);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    // We now load the pool pointer (PP) with a GC safe value as we are about to
    // invoke dart code. We don't need a real object pool here.
    // Smi zero does not work because ARM64 assumes PP to be untagged.
    __ LoadObject(PP, compiler::NullObject());
  }

  // Load a GC-safe value for the arguments descriptor (unused but tagged).
  __ mov(ARGS_DESC_REG, ZR);

  // Load a dummy return address which suggests that we are inside of
  // InvokeDartCodeStub. This is how the stack walker detects an entry frame.
  CLOBBERS_LR({
    __ LoadFromOffset(LR, THR,
                      compiler::target::Thread::invoke_dart_code_stub_offset());
    __ LoadFieldFromOffset(LR, LR,
                           compiler::target::Code::entry_point_offset());
  });

  FunctionEntryInstr::EmitNativeCode(compiler);
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
  const Register char_code = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ ldr(result,
         compiler::Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ SmiUntag(TMP, char_code);  // Untag to use scaled address mode.
  __ ldr(result,
         compiler::Address(result, TMP, UXTX, compiler::Address::Scaled));
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
  __ LoadFieldFromOffset(result, str, String::length_offset());
  __ ldr(TMP,
         compiler::FieldAddress(str, OneByteString::data_offset(),
                                compiler::kByte),
         compiler::kUnsignedByte);
  __ CompareImmediate(result, Smi::RawValue(1));
  __ LoadImmediate(result, -1);
  __ csel(result, TMP, result, EQ);
  __ SmiTag(result);
}

LocationSummary* StringInterpolateInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}

void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register array = locs()->in(0).reg();
  __ Push(array);
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  constexpr int kSizeOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kSizeOfArguments,
                          kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), source(), CallFunction(), args_info,
                               locs(), ICData::Handle(), ICData::kStatic);
  ASSERT(locs()->out(0).reg() == R0);
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

  static const intptr_t kSizeMask = 0x03;
  static const intptr_t kFlagsMask = 0x3C;

  compiler::Label loop, loop_in;

  // Address of input bytes.
  __ LoadFieldFromOffset(bytes_reg, bytes_reg,
                         compiler::target::TypedDataBase::data_field_offset());

  // Table.
  __ AddImmediate(
      table_reg, table_reg,
      compiler::target::OneByteString::data_offset() - kHeapObjectTag);

  // Pointers to start and end.
  __ add(bytes_ptr_reg, bytes_reg, compiler::Operand(start_reg));
  __ add(bytes_end_reg, bytes_reg, compiler::Operand(end_reg));

  // Initialize size and flags.
  __ mov(size_reg, ZR);
  __ mov(flags_reg, ZR);

  __ b(&loop_in);
  __ Bind(&loop);

  // Read byte and increment pointer.
  __ ldr(temp_reg,
         compiler::Address(bytes_ptr_reg, 1, compiler::Address::PostIndex),
         compiler::kUnsignedByte);

  // Update size and flags based on byte value.
  __ ldr(temp_reg, compiler::Address(table_reg, temp_reg),
         compiler::kUnsignedByte);
  __ orr(flags_reg, flags_reg, compiler::Operand(temp_reg));
  __ andi(temp_reg, temp_reg, compiler::Immediate(kSizeMask));
  __ add(size_reg, size_reg, compiler::Operand(temp_reg));

  // Stop if end is reached.
  __ Bind(&loop_in);
  __ cmp(bytes_ptr_reg, compiler::Operand(bytes_end_reg));
  __ b(&loop, UNSIGNED_LESS);

  // Write flags to field.
  __ AndImmediate(flags_reg, flags_reg, kFlagsMask);
  if (!IsScanFlagsUnboxed()) {
    __ SmiTag(flags_reg);
  }
  Register decoder_reg;
  const Location decoder_location = locs()->in(0);
  if (decoder_location.IsStackSlot()) {
    __ ldr(decoder_temp_reg, LocationToStackSlotAddress(decoder_location));
    decoder_reg = decoder_temp_reg;
  } else {
    decoder_reg = decoder_location.reg();
  }
  const auto scan_flags_field_offset = scan_flags_field_.offset_in_bytes();
  __ LoadFieldFromOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
  __ orr(flags_temp_reg, flags_temp_reg, compiler::Operand(flags_reg));
  __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
}

LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register obj = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ LoadFromOffset(result, obj, offset());
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ LoadFieldFromOffset(result, obj, offset());
  }
}

DEFINE_BACKEND(StoreUntagged, (NoLocation, Register obj, Register value)) {
  __ StoreToOffset(value, obj, instr->offset_from_tagged());
}

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

static bool CanBeImmediateIndex(Value* value, intptr_t cid, bool is_external) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == NULL) || !constant->value().IsSmi()) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const int64_t offset =
      index * scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  if (!Utils::IsInt(32, offset)) {
    return false;
  }
  return compiler::Address::CanHoldOffset(
      static_cast<int32_t>(offset), compiler::Address::Offset,
      compiler::Address::OperandSizeFor(cid));
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
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

  compiler::Address element_address(TMP);  // Bad address.
  element_address = index.IsRegister()
                        ? __ ElementAddressForRegIndex(
                              IsExternal(), class_id(), index_scale(),
                              index_unboxed_, array, index.reg(), TMP)
                        : __ ElementAddressForIntIndex(
                              IsExternal(), class_id(), index_scale(), array,
                              Smi::Cast(index.constant()).Value());
  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    const VRegister result = locs()->out(0).fpu_reg();
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        __ fldrs(result, element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        // Load double precision float.
        __ fldrd(result, element_address);
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        __ fldrq(result, element_address);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  const Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt32ArrayCid:
      ASSERT(representation() == kUnboxedInt32);
      __ ldr(result, element_address, compiler::kFourBytes);
      break;
    case kTypedDataUint32ArrayCid:
      ASSERT(representation() == kUnboxedUint32);
      __ ldr(result, element_address, compiler::kUnsignedFourBytes);
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      ASSERT(representation() == kUnboxedInt64);
      __ ldr(result, element_address, compiler::kEightBytes);
      break;
    case kTypedDataInt8ArrayCid:
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      __ ldr(result, element_address, compiler::kByte);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      __ ldr(result, element_address, compiler::kUnsignedByte);
      break;
    case kTypedDataInt16ArrayCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ ldr(result, element_address, compiler::kTwoBytes);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      ASSERT(representation() == kUnboxedIntPtr);
      __ ldr(result, element_address, compiler::kUnsignedTwoBytes);
      break;
    default:
      ASSERT(representation() == kTagged);
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
             (class_id() == kTypeArgumentsCid));
      __ ldr(result, element_address);
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
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);
  compiler::OperandSize sz = compiler::kByte;

  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
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
    case kExternalTwoByteStringCid:
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
      break;
  }
  // Warning: element_address may use register TMP as base.
  compiler::Address element_address = __ ElementAddressForRegIndexWithSize(
      IsExternal(), class_id(), sz, index_scale(), /*index_unboxed=*/false, str,
      index.reg(), TMP);
  __ ldr(result, element_address, sz);

  __ SmiTag(result);
}

Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) {
    if (index_unboxed_) {
      return kNoRepresentation;  // Index can be any unboxed representation.
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
      UNREACHABLE();
      return kTagged;
  }
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  locs->set_temp(0, Location::RequiresRegister());

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
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:  // TODO(srdjan): Support Float64 constants.
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
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
  const Register temp = locs()->temp(0).reg();
  compiler::Address element_address(TMP);  // Bad address.

  // Deal with a special case separately.
  if (class_id() == kArrayCid && ShouldEmitStoreBarrier()) {
    if (index.IsRegister()) {
      __ ComputeElementAddressForRegIndex(temp, IsExternal(), class_id(),
                                          index_scale(), index_unboxed_, array,
                                          index.reg());
    } else {
      __ ComputeElementAddressForIntIndex(temp, IsExternal(), class_id(),
                                          index_scale(), array,
                                          Smi::Cast(index.constant()).Value());
    }
    const Register value = locs()->in(2).reg();
    __ StoreIntoArray(array, temp, value, CanValueBeSmi());
    return;
  }

  element_address = index.IsRegister()
                        ? __ ElementAddressForRegIndex(
                              IsExternal(), class_id(), index_scale(),
                              index_unboxed_, array, index.reg(), temp)
                        : __ ElementAddressForIntIndex(
                              IsExternal(), class_id(), index_scale(), array,
                              Smi::Cast(index.constant()).Value());

  switch (class_id()) {
    case kArrayCid:
      ASSERT(!ShouldEmitStoreBarrier());  // Specially treated above.
      if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreIntoObjectNoBarrier(array, element_address, constant);
      } else {
        const Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, element_address, value);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kOneByteStringCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ LoadImmediate(TMP, static_cast<int8_t>(constant.Value()));
        __ str(TMP, element_address, compiler::kUnsignedByte);
      } else {
        const Register value = locs()->in(2).reg();
        __ str(value, element_address, compiler::kUnsignedByte);
      }
      break;
    }
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
        __ LoadImmediate(TMP, static_cast<int8_t>(value));
        __ str(TMP, element_address, compiler::kUnsignedByte);
      } else {
        const Register value = locs()->in(2).reg();
        // Clamp to 0x00 or 0xFF respectively.
        __ CompareImmediate(value, 0xFF);
        __ csetm(TMP, GT);             // TMP = value > 0xFF ? -1 : 0.
        __ csel(TMP, value, TMP, LS);  // TMP = value in range ? value : TMP.
        __ str(TMP, element_address, compiler::kUnsignedByte);
      }
      break;
    }
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      const Register value = locs()->in(2).reg();
      __ str(value, element_address, compiler::kUnsignedTwoBytes);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      const Register value = locs()->in(2).reg();
      __ str(value, element_address, compiler::kUnsignedFourBytes);
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      const Register value = locs()->in(2).reg();
      __ str(value, element_address, compiler::kEightBytes);
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      const VRegister value_reg = locs()->in(2).fpu_reg();
      __ fstrs(value_reg, element_address);
      break;
    }
    case kTypedDataFloat64ArrayCid: {
      const VRegister value_reg = locs()->in(2).fpu_reg();
      __ fstrd(value_reg, element_address);
      break;
    }
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid: {
      const VRegister value_reg = locs()->in(2).fpu_reg();
      __ fstrq(value_reg, element_address);
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = NULL) {
  compiler::Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ BranchIfSmi(value_reg, value_is_smi == NULL ? &done : value_is_smi);
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}

DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldTypeInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckConditionInstr)

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
          : NULL;

  compiler::Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle((field().Original())));

    compiler::FieldAddress field_cid_operand(
        field_reg, Field::guarded_cid_offset(), compiler::kUnsignedTwoBytes);
    compiler::FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset(), compiler::kUnsignedTwoBytes);

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      compiler::Label skip_length_check;
      __ ldr(TMP, field_cid_operand, compiler::kUnsignedTwoBytes);
      __ CompareRegisters(value_cid_reg, TMP);
      __ b(&ok, EQ);
      __ ldr(TMP, field_nullability_operand, compiler::kUnsignedTwoBytes);
      __ CompareRegisters(value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ ldr(value_cid_reg, field_nullability_operand,
             compiler::kUnsignedTwoBytes);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      compiler::Label skip_length_check;
      __ ldr(value_cid_reg, field_cid_operand, compiler::kUnsignedTwoBytes);
      __ CompareImmediate(value_cid_reg, value_cid);
    }
    __ b(&ok, EQ);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    // Length guard will be emitted separately when needed via GuardFieldLength
    // instruction after GuardFieldClass.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ ldr(TMP, field_cid_operand, compiler::kUnsignedTwoBytes);
      __ CompareImmediate(TMP, kIllegalCid);
      __ b(fail, NE);

      if (value_cid == kDynamicCid) {
        __ str(value_cid_reg, field_cid_operand, compiler::kUnsignedTwoBytes);
        __ str(value_cid_reg, field_nullability_operand,
               compiler::kUnsignedTwoBytes);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ str(TMP, field_cid_operand, compiler::kUnsignedTwoBytes);
        __ str(TMP, field_nullability_operand, compiler::kUnsignedTwoBytes);
      }

      __ b(&ok);
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ LoadFieldFromOffset(TMP, field_reg, Field::guarded_cid_offset(),
                             compiler::kUnsignedTwoBytes);
      __ CompareImmediate(TMP, kDynamicCid);
      __ b(&ok, EQ);

      __ PushPair(value_reg, field_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ b(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ tsti(value_reg, compiler::Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ b(fail, EQ);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, field_cid);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ b(&ok, EQ);
        __ CompareObject(value_reg, Object::null_object());
      }

      __ b(fail, NE);
    } else if (value_cid == field_cid) {
      // This would normaly be caught by Canonicalize, but RemoveRedefinitions
      // may sometimes produce the situation after the last Canonicalize pass.
    } else {
      // Both value's and field's class id is known.
      ASSERT(value_cid != nullability);
      __ b(fail);
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

    __ ldr(offset_reg,
           compiler::FieldAddress(
               field_reg, Field::guarded_list_length_in_object_offset_offset()),
           compiler::kByte);
    __ ldr(length_reg, compiler::FieldAddress(
                           field_reg, Field::guarded_list_length_offset()));

    __ tst(offset_reg, compiler::Operand(offset_reg));
    __ b(&ok, MI);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ ldr(TMP, compiler::Address(value_reg, offset_reg));
    __ CompareRegisters(length_reg, TMP);

    if (deopt == NULL) {
      __ b(&ok, EQ);

      __ PushPair(value_reg, field_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ b(deopt, NE);
    }

    __ Bind(&ok);
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(field().guarded_list_length() >= 0);
    ASSERT(field().guarded_list_length_in_object_offset() !=
           Field::kUnknownLengthOffset);

    __ ldr(TMP, compiler::FieldAddress(
                    value_reg, field().guarded_list_length_in_object_offset()));
    __ CompareImmediate(TMP, Smi::RawValue(field().guarded_list_length()));
    __ b(deopt, NE);
  }
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
    __ MoveRegister(result_, R0);
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp) {
    if (compiler->intrinsic_mode()) {
      __ TryAllocate(cls, compiler->intrinsic_slow_path_label(), result, temp);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls, slow_path->entry_label(), result, temp);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
  const Class& cls_;
  const Register result_;
};

static void EnsureMutableBox(FlowGraphCompiler* compiler,
                             StoreInstanceFieldInstr* instruction,
                             Register box_reg,
                             const Class& cls,
                             Register instance_reg,
                             intptr_t offset,
                             Register temp) {
  compiler::Label done;
  __ LoadFieldFromOffset(box_reg, instance_reg, offset);
  __ CompareObject(box_reg, Object::null_object());
  __ b(&done, NE);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ MoveRegister(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp,
                           compiler::Assembler::kValueIsNotSmi);
  __ Bind(&done);
}

LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (IsUnboxedStore() && opt)
                                 ? (FLAG_precompiled_mode ? 0 : 2)
                                 : (IsPotentialUnboxedStore() ? 2 : 0);
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
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                           ? Location::RegisterLocation(kWriteBarrierValueReg)
                           : LocationRegisterOrConstant(value()));
  }
  return summary;
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
      __ StoreFieldToOffset(value, instance_reg, offset_in_bytes);
      return;
    }

    const VRegister value = locs()->in(1).fpu_reg();
    const intptr_t cid = slot().field().UnboxedFieldCid();

    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
          __ StoreDFieldToOffset(value, instance_reg, offset_in_bytes);
          return;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
          __ StoreQFieldToOffset(value, instance_reg, offset_in_bytes);
          return;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
          __ StoreQFieldToOffset(value, instance_reg, offset_in_bytes);
          return;
        default:
          UNREACHABLE();
      }
    }

    const Register temp = locs()->temp(0).reg();
    const Register temp2 = locs()->temp(1).reg();

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
      __ MoveRegister(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes, temp2,
                               compiler::Assembler::kValueIsNotSmi);
    } else {
      __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes);
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ StoreDFieldToOffset(value, temp, Double::value_offset());
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ StoreQFieldToOffset(value, temp, Float32x4::value_offset());
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ StoreQFieldToOffset(value, temp, Float64x2::value_offset());
        break;
      default:
        UNREACHABLE();
    }

    return;
  }

  if (IsPotentialUnboxedStore()) {
    const Register value_reg = locs()->in(1).reg();
    const Register temp = locs()->temp(0).reg();
    const Register temp2 = locs()->temp(1).reg();

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

    __ LoadFieldFromOffset(temp2, temp, Field::is_nullable_offset(),
                           compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ LoadFromOffset(temp2, temp, Field::kind_bits_offset() - kHeapObjectTag,
                      compiler::kUnsignedByte);
    __ tsti(temp2, compiler::Immediate(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp2, kFloat64x2Cid);
    __ b(&store_float64x2, EQ);

    // Fall through.
    __ b(&store_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
      locs()->live_registers()->Add(locs()->in(1));
    }

    {
      __ Bind(&store_double);
      EnsureMutableBox(compiler, this, temp, compiler->double_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ LoadDFieldFromOffset(VTMP, value_reg, Double::value_offset());
      __ StoreDFieldToOffset(VTMP, temp, Double::value_offset());
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler, this, temp, compiler->float32x4_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ LoadQFieldFromOffset(VTMP, value_reg, Float32x4::value_offset());
      __ StoreQFieldToOffset(VTMP, temp, Float32x4::value_offset());
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler, this, temp, compiler->float64x2_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ LoadQFieldFromOffset(VTMP, value_reg, Float64x2::value_offset());
      __ StoreQFieldToOffset(VTMP, temp, Float64x2::value_offset());
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    const Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(instance_reg, offset_in_bytes, value_reg,
                             CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectOffsetNoBarrier(instance_reg, offset_in_bytes,
                                        locs()->in(1).constant());
    } else {
      const Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectOffsetNoBarrier(instance_reg, offset_in_bytes,
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
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  compiler->used_static_fields().Add(&field());

  __ LoadFromOffset(temp, THR,
                    compiler::target::Thread::field_table_values_offset());
  // Note: static fields ids won't be changed by hot-reload.
  __ StoreToOffset(value, temp,
                   compiler::target::FieldTable::OffsetOf(field()));
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
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == TypeTestABI::kInstanceReg);
  ASSERT(locs()->in(1).reg() == TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs()->in(2).reg() == TypeTestABI::kFunctionTypeArgumentsReg);

  compiler->GenerateInstanceOf(source(), deopt_id(), type(), locs());
  ASSERT(locs()->out(0).reg() == R0);
}

LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(kElementTypePos, Location::RegisterLocation(R1));
  locs->set_in(kLengthPos, Location::RegisterLocation(R2));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  compiler::Label* slow_path,
                                  compiler::Label* done) {
  const int kInlineArraySize = 12;  // Same as kInlineInstanceSize.
  const Register kLengthReg = R2;
  const Register kElemTypeReg = R1;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      R0,  // instance
                      R3,  // end address
                      R6, R8);
  // R0: new object start as a tagged pointer.
  // R3: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      R0, compiler::FieldAddress(R0, Array::type_arguments_offset()),
      kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(
      R0, compiler::FieldAddress(R0, Array::length_offset()), kLengthReg);

  // TODO(zra): Use stp once added.
  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R3: new object end address.
  // R8: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R6: null
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(ArrayLayout);
    __ LoadObject(R6, Object::null_object());
    __ AddImmediate(R8, R0, sizeof(ArrayLayout) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ str(R6, compiler::Address(R8, current_offset));
        current_offset += kWordSize;
      }
    } else {
      compiler::Label end_loop, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(R8, R3);
      __ b(&end_loop, CS);
      __ str(R6, compiler::Address(R8));
      __ AddImmediate(R8, kWordSize);
      __ b(&init_loop);
      __ Bind(&end_loop);
    }
  }
  __ b(done);
}

void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  TypeUsageInfo* type_usage_info = compiler->thread()->type_usage_info();
  if (type_usage_info != nullptr) {
    const Class& list_class = Class::Handle(
        compiler->thread()->isolate()->class_table()->At(kArrayCid));
    RegisterTypeArgumentsUse(compiler->function(), type_usage_info, list_class,
                             element_type()->definition());
  }

  const Register kLengthReg = R2;
  const Register kElemTypeReg = R1;
  const Register kResultReg = R0;

  ASSERT(locs()->in(kElementTypePos).reg() == kElemTypeReg);
  ASSERT(locs()->in(kLengthPos).reg() == kLengthReg);

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
  ASSERT(locs()->out(0).reg() == kResultReg);
  __ Bind(&done);
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
    const intptr_t kNumTemps = 1;
    locs = new (zone) LocationSummary(zone, kNumInputs, kNumTemps,
                                      LocationSummary::kCallOnSlowPath);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_temp(0, Location::RequiresRegister());
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
    const Register result_reg = locs()->out(0).reg();
    switch (slot().representation()) {
      case kUnboxedInt64:
        __ Comment("UnboxedInt64LoadFieldInstr");
        __ LoadFieldFromOffset(result_reg, instance_reg, OffsetInBytes());
        break;
      case kUnboxedUint32:
        __ Comment("UnboxedUint32LoadFieldInstr");
        __ LoadFieldFromOffset(result_reg, instance_reg, OffsetInBytes(),
                               compiler::kUnsignedFourBytes);
        break;
      case kUnboxedUint8:
        __ Comment("UnboxedUint8LoadFieldInstr");
        __ LoadFieldFromOffset(result_reg, instance_reg, OffsetInBytes(),
                               compiler::kUnsignedByte);
        break;
      default:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

  if (IsUnboxedDartFieldLoad() && compiler->is_optimizing()) {
    const VRegister result = locs()->out(0).fpu_reg();
    const intptr_t cid = slot().field().UnboxedFieldCid();

    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleLoadFieldInstr");
          __ LoadDFieldFromOffset(result, instance_reg, OffsetInBytes());
          return;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4LoadFieldInstr");
          __ LoadQFieldFromOffset(result, instance_reg, OffsetInBytes());
          return;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2LoadFieldInstr");
          __ LoadQFieldFromOffset(result, instance_reg, OffsetInBytes());
          return;
        default:
          UNREACHABLE();
      }
    }

    const Register temp = locs()->temp(0).reg();

    __ LoadFieldFromOffset(temp, instance_reg, OffsetInBytes());
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ LoadDFieldFromOffset(result, temp, Double::value_offset());
        break;
      case kFloat32x4Cid:
        __ LoadQFieldFromOffset(result, temp, Float32x4::value_offset());
        break;
      case kFloat64x2Cid:
        __ LoadQFieldFromOffset(result, temp, Float64x2::value_offset());
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  compiler::Label done;
  const Register result_reg = locs()->out(0).reg();
  if (IsPotentialUnboxedDartFieldLoad()) {
    const Register temp = locs()->temp(0).reg();

    compiler::Label load_pointer;
    compiler::Label load_double;
    compiler::Label load_float32x4;
    compiler::Label load_float64x2;

    __ LoadObject(result_reg, Field::ZoneHandle(slot().field().Original()));

    compiler::FieldAddress field_cid_operand(
        result_reg, Field::guarded_cid_offset(), compiler::kUnsignedTwoBytes);
    compiler::FieldAddress field_nullability_operand(
        result_reg, Field::is_nullable_offset(), compiler::kUnsignedTwoBytes);

    __ ldr(temp, field_nullability_operand, compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp, kNullCid);
    __ b(&load_pointer, EQ);

    __ ldr(temp, field_cid_operand, compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp, kDoubleCid);
    __ b(&load_double, EQ);

    __ ldr(temp, field_cid_operand, compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp, kFloat32x4Cid);
    __ b(&load_float32x4, EQ);

    __ ldr(temp, field_cid_operand, compiler::kUnsignedTwoBytes);
    __ CompareImmediate(temp, kFloat64x2Cid);
    __ b(&load_float64x2, EQ);

    // Fall through.
    __ b(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->double_class(),
                                      result_reg, temp);
      __ LoadFieldFromOffset(temp, instance_reg, OffsetInBytes());
      __ LoadDFieldFromOffset(VTMP, temp, Double::value_offset());
      __ StoreDFieldToOffset(VTMP, result_reg, Double::value_offset());
      __ b(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result_reg, temp);
      __ LoadFieldFromOffset(temp, instance_reg, OffsetInBytes());
      __ LoadQFieldFromOffset(VTMP, temp, Float32x4::value_offset());
      __ StoreQFieldToOffset(VTMP, result_reg, Float32x4::value_offset());
      __ b(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result_reg, temp);
      __ LoadFieldFromOffset(temp, instance_reg, OffsetInBytes());
      __ LoadQFieldFromOffset(VTMP, temp, Float64x2::value_offset());
      __ StoreQFieldToOffset(VTMP, result_reg, Float64x2::value_offset());
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }

  __ LoadFieldFromOffset(result_reg, instance_reg, OffsetInBytes());

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
  const Register instantiator_type_args_reg = locs()->in(0).reg();
  const Register function_type_args_reg = locs()->in(1).reg();
  const Register result_reg = locs()->out(0).reg();

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ LoadObject(TMP, type());
  __ PushPair(TMP, NULL_REG);
  __ PushPair(function_type_args_reg, instantiator_type_args_reg);
  compiler->GenerateRuntimeCall(source(), deopt_id(),
                                kInstantiateTypeRuntimeEntry, 3, locs());
  __ Drop(3);          // Drop 2 type vectors, and uninstantiated type.
  __ Pop(result_reg);  // Pop instantiated type.
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
    __ CompareRegisters(instantiator_type_args_reg, result_reg);
    if (!function_type_arguments()->BindsToConstant()) {
      __ b(&non_null_type_args, NE);
      __ CompareRegisters(function_type_args_reg, result_reg);
    }
    __ b(&type_arguments_instantiated, EQ);
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
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_temp(1, Location::RegisterLocation(R2));
  locs->set_temp(2, Location::RegisterLocation(R3));
  locs->set_out(0, Location::RegisterLocation(R0));
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

    __ LoadImmediate(R1, instruction()->num_context_variables());
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               PcDescriptorsLayout::kOther, locs);
    ASSERT(instruction()->locs()->out(0).reg() == R0);
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ b(exit_label());
  }
};

void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register temp0 = locs()->temp(0).reg();
  Register temp1 = locs()->temp(1).reg();
  Register temp2 = locs()->temp(2).reg();
  Register result = locs()->out(0).reg();
  // Try allocate the object.
  AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  intptr_t instance_size = Context::InstanceSize(num_context_variables());

  __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                      result,  // instance
                      temp0, temp1, temp2);

  // Setup up number of context variables field.
  __ LoadImmediate(temp0, num_context_variables());
  __ str(temp0,
         compiler::FieldAddress(result, Context::num_variables_offset()));

  __ Bind(slow_path->exit_label());
}

LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->out(0).reg() == R0);

  auto object_store = compiler->isolate()->object_store();
  const auto& allocate_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_context_stub());
  __ LoadImmediate(R1, num_context_variables());
  compiler->GenerateStubCall(source(), allocate_context_stub,
                             PcDescriptorsLayout::kOther, locs());
}

LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R5));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R5);
  ASSERT(locs()->out(0).reg() == R0);

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

  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

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
    auto locs = instruction()->locs();
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
      const Register value = locs->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(value, Thread::kOsrRequest);
      __ str(value,
             compiler::Address(THR, Thread::stack_overflow_flags_offset()));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    const bool using_shared_stub = locs->call_on_shared_slow_path();
    if (!using_shared_stub) {
      compiler->SaveLiveRegisters(locs);
    }
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    if (using_shared_stub) {
      auto object_store = compiler->isolate()->object_store();
      const bool live_fpu_regs = locs->live_registers()->FpuRegisterCount() > 0;
      const auto& stub = Code::ZoneHandle(
          compiler->zone(),
          live_fpu_regs
              ? object_store->stack_overflow_stub_with_fpu_regs_stub()
              : object_store->stack_overflow_stub_without_fpu_regs_stub());

      if (using_shared_stub && compiler->CanPcRelativeCall(stub)) {
        __ GenerateUnRelocatedPcRelativeCall();
        compiler->AddPcRelativeCallStubTarget(stub);
      } else {
        const uword entry_point_offset =
            Thread::stack_overflow_shared_stub_entry_point_offset(
                locs->live_registers()->FpuRegisterCount() > 0);
        __ Call(compiler::Address(THR, entry_point_offset));
      }
      compiler->RecordSafepoint(locs, kNumSlowPathArgs);
      compiler->RecordCatchEntryMoves();
      compiler->AddDescriptor(
          PcDescriptorsLayout::kOther, compiler->assembler()->CodeSize(),
          instruction()->deopt_id(), instruction()->source(),
          compiler->CurrentTryIndex());
    } else {
      compiler->GenerateRuntimeCall(
          instruction()->source(), instruction()->deopt_id(),
          kStackOverflowRuntimeEntry, kNumSlowPathArgs, locs);
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
      compiler->RestoreLiveRegisters(locs);
    }
    __ b(exit_label());
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

  __ ldr(TMP, compiler::Address(
                  THR, compiler::target::Thread::stack_limit_offset()));
  __ CompareRegisters(SP, TMP);
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register function = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(function, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ LoadFieldFromOffset(TMP, function, Function::usage_counter_offset(),
                           compiler::kFourBytes);
    __ add(TMP, TMP, compiler::Operand(1));
    __ StoreFieldToOffset(TMP, function, Function::usage_counter_offset(),
                          compiler::kFourBytes);
    __ CompareImmediate(TMP, threshold);
    __ b(slow_path->osr_entry_label(), GE);
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ b(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
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
          : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 6 bits for the count.
    const intptr_t kCountLimit = 0x3F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow (preserve left).
      __ LslImmediate(TMP, left, value);
      __ cmp(left, compiler::Operand(TMP, ASR, value));
      __ b(deopt, NE);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ LslImmediate(result, left, value);
    return;
  }

  // Right (locs.in(1)) is not constant.
  const Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ CompareRegisters(right, ZR);
        __ b(deopt, MI);
        __ mov(result, ZR);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ CompareImmediate(right, static_cast<int64_t>(Smi::New(max_right)));
        __ b(deopt, CS);
      }
      __ SmiUntag(TMP, right);
      __ lslv(result, left, TMP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareRegisters(right, ZR);
        __ b(deopt, MI);
      }

      __ CompareImmediate(right, static_cast<int64_t>(Smi::New(Smi::kBits)));
      __ csel(result, ZR, result, CS);
      __ SmiUntag(TMP, right);
      __ lslv(TMP, left, TMP);
      __ csel(result, TMP, result, CC);
    } else {
      __ SmiUntag(TMP, right);
      __ lslv(result, left, TMP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareImmediate(right, static_cast<int64_t>(Smi::New(Smi::kBits)));
      __ b(deopt, CS);
    }
    // Left is not a constant.
    // Check if count too large for handling it inlined.
    __ SmiUntag(TMP, right);
    // Overflow test (preserve left, right, and TMP);
    const Register temp = locs.temp(0).reg();
    __ lslv(temp, left, TMP);
    __ asrv(TMP2, temp, TMP);
    __ CompareRegisters(left, TMP2);
    __ b(deopt, NE);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ lslv(result, left, TMP);
  }
}

class CheckedSmiSlowPath : public TemplateSlowPathCode<CheckedSmiOpInstr> {
 public:
  static constexpr intptr_t kNumSlowPathArgs = 2;

  CheckedSmiSlowPath(CheckedSmiOpInstr* instruction, intptr_t try_index)
      : TemplateSlowPathCode(instruction), try_index_(try_index) {}

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
    __ PushPair(locs->in(1).reg(), locs->in(0).reg());
    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));
    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ mov(result, R0);
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
    compiler->pending_deoptimization_env_ = NULL;
  }

 private:
  intptr_t try_index_;
};

LocationSummary* CheckedSmiOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void CheckedSmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckedSmiSlowPath* slow_path =
      new CheckedSmiSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);
  // Test operands if necessary.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  intptr_t left_cid = this->left()->Type()->ToCid();
  intptr_t right_cid = this->right()->Type()->ToCid();
  bool combined_smi_check = false;
  if (this->left()->definition() == this->right()->definition()) {
    __ BranchIfNotSmi(left, slow_path->entry_label());
  } else if (left_cid == kSmiCid) {
    __ BranchIfNotSmi(right, slow_path->entry_label());
  } else if (right_cid == kSmiCid) {
    __ BranchIfNotSmi(left, slow_path->entry_label());
  } else {
    combined_smi_check = true;
    __ orr(result, left, compiler::Operand(right));
    __ BranchIfNotSmi(result, slow_path->entry_label());
  }

  switch (op_kind()) {
    case Token::kADD:
      __ adds(result, left, compiler::Operand(right));
      __ b(slow_path->entry_label(), VS);
      break;
    case Token::kSUB:
      __ subs(result, left, compiler::Operand(right));
      __ b(slow_path->entry_label(), VS);
      break;
    case Token::kMUL:
      __ SmiUntag(TMP, left);
      __ mul(result, TMP, right);
      __ smulh(TMP, TMP, right);
      // TMP: result bits 64..127.
      __ cmp(TMP, compiler::Operand(result, ASR, 63));
      __ b(slow_path->entry_label(), NE);
      break;
    case Token::kBIT_OR:
      // Operation may be part of combined smi check.
      if (!combined_smi_check) {
        __ orr(result, left, compiler::Operand(right));
      }
      break;
    case Token::kBIT_AND:
      __ and_(result, left, compiler::Operand(right));
      break;
    case Token::kBIT_XOR:
      __ eor(result, left, compiler::Operand(right));
      break;
    case Token::kSHL:
      ASSERT(result != left);
      ASSERT(result != right);
      __ CompareImmediate(right, static_cast<int64_t>(Smi::New(Smi::kBits)));
      __ b(slow_path->entry_label(), CS);

      __ SmiUntag(TMP, right);
      __ lslv(result, left, TMP);
      __ asrv(TMP2, result, TMP);
      __ CompareRegisters(left, TMP2);
      __ b(slow_path->entry_label(), NE);  // Overflow.
      break;
    case Token::kSHR:
      ASSERT(result != left);
      ASSERT(result != right);
      __ CompareImmediate(right, static_cast<int64_t>(Smi::New(Smi::kBits)));
      __ b(slow_path->entry_label(), CS);

      __ SmiUntag(result, right);
      __ SmiUntag(TMP, left);
      __ asrv(result, TMP, result);
      __ SmiTag(result);
      break;
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
      __ Comment("slow path smi operation");
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
    __ PushPair(locs->in(1).reg(), locs->in(0).reg());
    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));
    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ mov(result, R0);
    compiler->RestoreLiveRegisters(locs);
    compiler->pending_deoptimization_env_ = nullptr;
    if (merged_) {
      __ CompareObject(result, Bool::True());
      __ b(instruction()->is_negated() ? labels_.false_label
                                       : labels_.true_label,
           EQ);
      __ b(instruction()->is_negated() ? labels_.true_label
                                       : labels_.false_label);
      ASSERT(exit_label()->IsUnused());
    } else {
      ASSERT(!instruction()->is_negated());
      __ b(exit_label());
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
  return EmitInt64ComparisonOp(compiler, locs(), kind(), labels);
}

#define EMIT_SMI_CHECK                                                         \
  Register left = locs()->in(0).reg();                                         \
  Register right = locs()->in(1).reg();                                        \
  Register temp = locs()->temp(0).reg();                                       \
  intptr_t left_cid = this->left()->Type()->ToCid();                           \
  intptr_t right_cid = this->right()->Type()->ToCid();                         \
  if (this->left()->definition() == this->right()->definition()) {             \
    __ BranchIfNotSmi(left, slow_path->entry_label());                         \
  } else if (left_cid == kSmiCid) {                                            \
    __ BranchIfNotSmi(right, slow_path->entry_label());                        \
  } else if (right_cid == kSmiCid) {                                           \
    __ BranchIfNotSmi(left, slow_path->entry_label());                         \
  } else {                                                                     \
    __ orr(temp, left, compiler::Operand(right));                              \
    __ BranchIfNotSmi(temp, slow_path->entry_label());                         \
  }

void CheckedSmiComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                               BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, branch->env(), compiler->CurrentTryIndex(), labels,
      /* merged = */ true);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
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
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
  Register result = locs()->out(0).reg();
  __ Bind(false_label);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(true_label);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
  // In case of negated comparison slow path exits through true/false labels.
  if (!is_negated()) {
    __ Bind(slow_path->exit_label());
  }
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (((op_kind() == Token::kSHL) && can_overflow()) ||
                              (op_kind() == Token::kSHR))
                                 ? 1
                                 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant));
    } else {
      summary->set_in(1, Location::RequiresRegister());
    }
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  if (op_kind() == Token::kMOD) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  if (((op_kind() == Token::kSHL) && can_overflow()) ||
      (op_kind() == Token::kSHR)) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  const Register left = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
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
        if (deopt == NULL) {
          __ AddImmediate(result, left, imm);
        } else {
          __ AddImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, -imm);
        } else {
          // Negating imm and using AddImmediateSetFlags would not detect the
          // overflow when imm == kMinInt64.
          __ SubImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ LoadImmediate(TMP, value);
        __ mul(result, left, TMP);
        if (deopt != NULL) {
          __ smulh(TMP, left, TMP);
          // TMP: result bits 64..127.
          __ cmp(TMP, compiler::Operand(result, ASR, 63));
          __ b(deopt, NE);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ AsrImmediate(TMP, left, 63);
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = TMP2;
        __ add(temp, left, compiler::Operand(TMP, LSR, 64 - shift_count));
        ASSERT(shift_count > 0);
        __ AsrImmediate(result, temp, shift_count);
        if (value < 0) {
          __ sub(result, ZR, compiler::Operand(result));
        }
        __ SmiTag(result);
        break;
      }
      case Token::kBIT_AND:
        // No overflow check.
        __ AndImmediate(result, left, imm);
        break;
      case Token::kBIT_OR:
        // No overflow check.
        __ OrImmediate(result, left, imm);
        break;
      case Token::kBIT_XOR:
        // No overflow check.
        __ XorImmediate(result, left, imm);
        break;
      case Token::kSHR: {
        // Asr operation masks the count to 6 bits.
        const intptr_t kCountLimit = 0x3F;
        intptr_t value = Smi::Cast(constant).Value();
        __ AsrImmediate(result, left,
                        Utils::Minimum(value + kSmiTagSize, kCountLimit));
        __ SmiTag(result);
        break;
      }
      default:
        UNREACHABLE();
        break;
    }
    return;
  }

  const Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD: {
      if (deopt == NULL) {
        __ add(result, left, compiler::Operand(right));
      } else {
        __ adds(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == NULL) {
        __ sub(result, left, compiler::Operand(right));
      } else {
        __ subs(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(TMP, left);
      if (deopt == NULL) {
        __ mul(result, TMP, right);
      } else {
        __ mul(result, TMP, right);
        __ smulh(TMP, TMP, right);
        // TMP: result bits 64..127.
        __ cmp(TMP, compiler::Operand(result, ASR, 63));
        __ b(deopt, NE);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, compiler::Operand(right));
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orr(result, left, compiler::Operand(right));
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ eor(result, left, compiler::Operand(right));
      break;
    }
    case Token::kTRUNCDIV: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ CompareRegisters(right, ZR);
        __ b(deopt, EQ);
      }
      const Register temp = TMP2;
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);

      __ sdiv(result, temp, TMP);
      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ CompareImmediate(result, 0x4000000000000000LL);
        __ b(deopt, EQ);
      }
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ CompareRegisters(right, ZR);
        __ b(deopt, EQ);
      }
      const Register temp = TMP2;
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);

      __ sdiv(result, temp, TMP);

      __ SmiUntag(TMP, right);
      __ msub(result, TMP, result, temp);  // result <- left - right * result
      __ SmiTag(result);
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      compiler::Label done;
      __ CompareRegisters(result, ZR);
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ CompareRegisters(right, ZR);
      __ sub(TMP, result, compiler::Operand(right));
      __ add(result, result, compiler::Operand(right));
      __ csel(result, TMP, result, LT);
      __ Bind(&done);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareRegisters(right, ZR);
        __ b(deopt, LT);
      }
      __ SmiUntag(TMP, right);
      // sarl operation masks the count to 6 bits.
      const intptr_t kCountLimit = 0x3F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ LoadImmediate(TMP2, kCountLimit);
        __ CompareRegisters(TMP, TMP2);
        __ csel(TMP, TMP2, TMP, GT);
      }
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ asrv(result, temp, TMP);
      __ SmiTag(result);
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
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}

void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                             licm_hoisted_ ? ICData::kHoisted : 0);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ BranchIfSmi(left, deopt);
  } else if (left_cid == kSmiCid) {
    __ BranchIfSmi(right, deopt);
  } else if (right_cid == kSmiCid) {
    __ BranchIfSmi(left, deopt);
  } else {
    __ orr(TMP, left, compiler::Operand(right));
    __ BranchIfSmi(TMP, deopt);
  }
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
  const Register out_reg = locs()->out(0).reg();
  const Register temp_reg = locs()->temp(0).reg();
  const VRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, temp_reg);

  switch (from_representation()) {
    case kUnboxedDouble:
      __ StoreDFieldToOffset(value, out_reg, ValueOffset());
      break;
    case kUnboxedFloat:
      __ fcvtds(FpuTMP, value);
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

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  ASSERT(!RepresentationUtils::IsUnsigned(representation()));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  const bool is_floating_point =
      !RepresentationUtils::IsUnboxedInteger(representation());
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, is_floating_point ? Location::RequiresFpuRegister()
                                        : Location::RequiresRegister());
  return summary;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ ldr(result, compiler::FieldAddress(box, ValueOffset()));
      break;
    }

    case kUnboxedDouble: {
      const VRegister result = locs()->out(0).fpu_reg();
      __ LoadDFieldFromOffset(result, box, ValueOffset());
      break;
    }

    case kUnboxedFloat: {
      const VRegister result = locs()->out(0).fpu_reg();
      __ LoadDFieldFromOffset(result, box, ValueOffset());
      __ fcvtsd(result, result);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      const VRegister result = locs()->out(0).fpu_reg();
      __ LoadQFieldFromOffset(result, box, ValueOffset());
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
      __ SmiUntag(result, box);
      break;
    }

    case kUnboxedDouble: {
      const VRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(TMP, box);
      __ scvtfdx(result, TMP);
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
  ASSERT(value != result);
  compiler::Label done;
  __ SmiUntag(result, value);
  __ BranchIfSmi(value, &done);
  __ ldr(
      result,
      compiler::FieldAddress(value, Mint::value_offset(), compiler::kFourBytes),
      compiler::kFourBytes);
  __ LoadFieldFromOffset(result, value, Mint::value_offset());
  __ Bind(&done);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(value != result);
  compiler::Label done;
  __ SmiUntag(result, value);
  __ BranchIfSmi(value, &done);
  __ LoadFieldFromOffset(result, value, Mint::value_offset());
  __ Bind(&done);
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

  ASSERT(kSmiTagSize == 1);
  const intptr_t shift = kBitsPerWord - kBitsPerByte;
  // TODO(vegorov) implement and use UBFM/SBFM for this.
  __ LslImmediate(out, value, shift);
  __ LsrImmediate(out, out, shift - kSmiTagSize);
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

  ASSERT(kSmiTagSize == 1);
  // TODO(vegorov) implement and use UBFM/SBFM for this.
  __ LslImmediate(out, value, 32);
  if (from_representation() == kUnboxedInt32) {
    __ AsrImmediate(out, out, 32 - kSmiTagSize);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ LsrImmediate(out, out, 32 - kSmiTagSize);
  }
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
          : shared_slow_path_call ? LocationSummary::kCallOnSharedSlowPath
                                  : LocationSummary::kCallOnSlowPath);
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
  Register in = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  if (ValueFitsSmi()) {
    __ SmiTag(out, in);
    return;
  }
  ASSERT(kSmiTag == 0);
  __ adds(out, in, compiler::Operand(in));  // SmiTag
  compiler::Label done;
  // If the value doesn't fit in a smi, the tagging changes the sign,
  // which causes the overflow flag to be set.
  __ b(&done, NO_OVERFLOW);

  Register temp = locs()->temp(0).reg();
  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(), out, temp);
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

  __ StoreToOffset(in, out, Mint::value_offset() - kHeapObjectTag);
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
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : NULL;

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
  } else if (!CanDeoptimize()) {
    // Type information is not conclusive, but range analysis found
    // the value to be in int64 range. Therefore it must be a smi
    // or mint value.
    ASSERT(is_truncating());
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  } else {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done);
    __ CompareClassId(value, kMintCid);
    __ b(deopt, NE);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != NULL)) {
    ASSERT(representation() == kUnboxedInt32);
    __ cmp(out, compiler::Operand(out, SXTW, 0));
    __ b(deopt, NE);
  }
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
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  switch (op_kind()) {
    case Token::kADD:
      __ faddd(result, left, right);
      break;
    case Token::kSUB:
      __ fsubd(result, left, right);
      break;
    case Token::kMUL:
      __ fmuld(result, left, right);
      break;
    case Token::kDIV:
      __ fdivd(result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      op_kind() == MethodRecognizer::kDouble_getIsInfinite ? 1 : 0;
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
  const VRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    __ fcmpd(value, value);
    return is_negated ? VC : VS;
  } else {
    ASSERT(op_kind() == MethodRecognizer::kDouble_getIsInfinite);
    const Register temp = locs()->temp(0).reg();
    __ vmovrd(temp, value, 0);
    // Mask off the sign.
    __ AndImmediate(temp, temp, 0x7FFFFFFFFFFFFFFFLL);
    // Compare with +infinity.
    __ CompareImmediate(temp, 0x7FF0000000000000LL);
    return is_negated ? NE : EQ;
  }
}

// SIMD

#define DEFINE_EMIT(Name, Args)                                                \
  static void Emit##Name(FlowGraphCompiler* compiler, SimdOpInstr* instr,      \
                         PP_APPLY(PP_UNPACK, Args))

#define SIMD_OP_FLOAT_ARITH(V, Name, op)                                       \
  V(Float32x4##Name, op##s)                                                    \
  V(Float64x2##Name, op##d)

#define SIMD_OP_SIMPLE_BINARY(V)                                               \
  SIMD_OP_FLOAT_ARITH(V, Add, vadd)                                            \
  SIMD_OP_FLOAT_ARITH(V, Sub, vsub)                                            \
  SIMD_OP_FLOAT_ARITH(V, Mul, vmul)                                            \
  SIMD_OP_FLOAT_ARITH(V, Div, vdiv)                                            \
  SIMD_OP_FLOAT_ARITH(V, Min, vmin)                                            \
  SIMD_OP_FLOAT_ARITH(V, Max, vmax)                                            \
  V(Int32x4Add, vaddw)                                                         \
  V(Int32x4Sub, vsubw)                                                         \
  V(Int32x4BitAnd, vand)                                                       \
  V(Int32x4BitOr, vorr)                                                        \
  V(Int32x4BitXor, veor)                                                       \
  V(Float32x4Equal, vceqs)                                                     \
  V(Float32x4GreaterThan, vcgts)                                               \
  V(Float32x4GreaterThanOrEqual, vcges)

DEFINE_EMIT(SimdBinaryOp, (VRegister result, VRegister left, VRegister right)) {
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(result, left, right);                                                \
    break;
    SIMD_OP_SIMPLE_BINARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4ShuffleMix:
    case SimdOpInstr::kInt32x4ShuffleMix: {
      const intptr_t mask = instr->mask();
      __ vinss(result, 0, left, (mask >> 0) & 0x3);
      __ vinss(result, 1, left, (mask >> 2) & 0x3);
      __ vinss(result, 2, right, (mask >> 4) & 0x3);
      __ vinss(result, 3, right, (mask >> 6) & 0x3);
      break;
    }
    case SimdOpInstr::kFloat32x4NotEqual:
      __ vceqs(result, left, right);
      // Invert the result.
      __ vnot(result, result);
      break;
    case SimdOpInstr::kFloat32x4LessThan:
      __ vcgts(result, right, left);
      break;
    case SimdOpInstr::kFloat32x4LessThanOrEqual:
      __ vcges(result, right, left);
      break;
    case SimdOpInstr::kFloat32x4Scale:
      __ fcvtsd(VTMP, left);
      __ vdups(result, VTMP, 0);
      __ vmuls(result, result, right);
      break;
    case SimdOpInstr::kFloat64x2FromDoubles:
      __ vinsd(result, 0, left, 0);
      __ vinsd(result, 1, right, 0);
      break;
    case SimdOpInstr::kFloat64x2Scale:
      __ vdupd(VTMP, right, 0);
      __ vmuld(result, left, VTMP);
      break;
    default:
      UNREACHABLE();
  }
}

#define SIMD_OP_SIMPLE_UNARY(V)                                                \
  SIMD_OP_FLOAT_ARITH(V, Sqrt, vsqrt)                                          \
  SIMD_OP_FLOAT_ARITH(V, Negate, vneg)                                         \
  SIMD_OP_FLOAT_ARITH(V, Abs, vabs)                                            \
  V(Float32x4Reciprocal, VRecps)                                               \
  V(Float32x4ReciprocalSqrt, VRSqrts)

DEFINE_EMIT(SimdUnaryOp, (VRegister result, VRegister value)) {
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(result, value);                                                      \
    break;
    SIMD_OP_SIMPLE_UNARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4ShuffleX:
      __ vinss(result, 0, value, 0);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4ShuffleY:
      __ vinss(result, 0, value, 1);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4ShuffleZ:
      __ vinss(result, 0, value, 2);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4ShuffleW:
      __ vinss(result, 0, value, 3);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kInt32x4Shuffle:
    case SimdOpInstr::kFloat32x4Shuffle: {
      const intptr_t mask = instr->mask();
      if (mask == 0x00) {
        __ vdups(result, value, 0);
      } else if (mask == 0x55) {
        __ vdups(result, value, 1);
      } else if (mask == 0xAA) {
        __ vdups(result, value, 2);
      } else if (mask == 0xFF) {
        __ vdups(result, value, 3);
      } else {
        for (intptr_t i = 0; i < 4; i++) {
          __ vinss(result, i, value, (mask >> (2 * i)) & 0x3);
        }
      }
      break;
    }
    case SimdOpInstr::kFloat32x4Splat:
      // Convert to Float32.
      __ fcvtsd(VTMP, value);
      // Splat across all lanes.
      __ vdups(result, VTMP, 0);
      break;
    case SimdOpInstr::kFloat64x2GetX:
      __ vinsd(result, 0, value, 0);
      break;
    case SimdOpInstr::kFloat64x2GetY:
      __ vinsd(result, 0, value, 1);
      break;
    case SimdOpInstr::kFloat64x2Splat:
      __ vdupd(result, value, 0);
      break;
    case SimdOpInstr::kFloat64x2ToFloat32x4:
      // Zero register.
      __ veor(result, result, result);
      // Set X lane.
      __ vinsd(VTMP, 0, value, 0);
      __ fcvtsd(VTMP, VTMP);
      __ vinss(result, 0, VTMP, 0);
      // Set Y lane.
      __ vinsd(VTMP, 0, value, 1);
      __ fcvtsd(VTMP, VTMP);
      __ vinss(result, 1, VTMP, 0);
      break;
    case SimdOpInstr::kFloat32x4ToFloat64x2:
      // Set X.
      __ vinss(VTMP, 0, value, 0);
      __ fcvtds(VTMP, VTMP);
      __ vinsd(result, 0, VTMP, 0);
      // Set Y.
      __ vinss(VTMP, 0, value, 1);
      __ fcvtds(VTMP, VTMP);
      __ vinsd(result, 1, VTMP, 0);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Simd32x4GetSignMask,
            (Register out, VRegister value, Temp<Register> temp)) {
  // X lane.
  __ vmovrs(out, value, 0);
  __ LsrImmediate(out, out, 31);
  // Y lane.
  __ vmovrs(temp, value, 1);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, compiler::Operand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, value, 2);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, compiler::Operand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, value, 3);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, compiler::Operand(temp, LSL, 3));
}

DEFINE_EMIT(
    Float32x4FromDoubles,
    (VRegister r, VRegister v0, VRegister v1, VRegister v2, VRegister v3)) {
  __ fcvtsd(VTMP, v0);
  __ vinss(r, 0, VTMP, 0);
  __ fcvtsd(VTMP, v1);
  __ vinss(r, 1, VTMP, 0);
  __ fcvtsd(VTMP, v2);
  __ vinss(r, 2, VTMP, 0);
  __ fcvtsd(VTMP, v3);
  __ vinss(r, 3, VTMP, 0);
}

DEFINE_EMIT(
    Float32x4Clamp,
    (VRegister result, VRegister value, VRegister lower, VRegister upper)) {
  __ vmins(result, value, upper);
  __ vmaxs(result, result, lower);
}

DEFINE_EMIT(Float32x4With,
            (VRegister result, VRegister replacement, VRegister value)) {
  __ fcvtsd(VTMP, replacement);
  __ vmov(result, value);
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4WithX:
      __ vinss(result, 0, VTMP, 0);
      break;
    case SimdOpInstr::kFloat32x4WithY:
      __ vinss(result, 1, VTMP, 0);
      break;
    case SimdOpInstr::kFloat32x4WithZ:
      __ vinss(result, 2, VTMP, 0);
      break;
    case SimdOpInstr::kFloat32x4WithW:
      __ vinss(result, 3, VTMP, 0);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Simd32x4ToSimd32x4, (SameAsFirstInput, VRegister value)) {
  // TODO(dartbug.com/30949) these operations are essentially nop and should
  // not generate any code. They should be removed from the graph before
  // code generation.
}

DEFINE_EMIT(SimdZero, (VRegister v)) {
  __ veor(v, v, v);
}

DEFINE_EMIT(Float64x2GetSignMask, (Register out, VRegister value)) {
  // Bits of X lane.
  __ vmovrd(out, value, 0);
  __ LsrImmediate(out, out, 63);
  // Bits of Y lane.
  __ vmovrd(TMP, value, 1);
  __ LsrImmediate(TMP, TMP, 63);
  __ orr(out, out, compiler::Operand(TMP, LSL, 1));
}

DEFINE_EMIT(Float64x2With,
            (SameAsFirstInput, VRegister left, VRegister right)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat64x2WithX:
      __ vinsd(left, 0, right, 0);
      break;
    case SimdOpInstr::kFloat64x2WithY:
      __ vinsd(left, 1, right, 0);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(
    Int32x4FromInts,
    (VRegister result, Register v0, Register v1, Register v2, Register v3)) {
  __ veor(result, result, result);
  __ vinsw(result, 0, v0);
  __ vinsw(result, 1, v1);
  __ vinsw(result, 2, v2);
  __ vinsw(result, 3, v3);
}

DEFINE_EMIT(Int32x4FromBools,
            (VRegister result,
             Register v0,
             Register v1,
             Register v2,
             Register v3,
             Temp<Register> temp)) {
  __ veor(result, result, result);
  __ LoadImmediate(temp, 0xffffffff);
  __ LoadObject(TMP2, Bool::True());

  const Register vs[] = {v0, v1, v2, v3};
  for (intptr_t i = 0; i < 4; i++) {
    __ CompareRegisters(vs[i], TMP2);
    __ csel(TMP, temp, ZR, EQ);
    __ vinsw(result, i, TMP);
  }
}

DEFINE_EMIT(Int32x4GetFlag, (Register result, VRegister value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kInt32x4GetFlagX:
      __ vmovrs(result, value, 0);
      break;
    case SimdOpInstr::kInt32x4GetFlagY:
      __ vmovrs(result, value, 1);
      break;
    case SimdOpInstr::kInt32x4GetFlagZ:
      __ vmovrs(result, value, 2);
      break;
    case SimdOpInstr::kInt32x4GetFlagW:
      __ vmovrs(result, value, 3);
      break;
    default:
      UNREACHABLE();
  }

  __ tst(result, compiler::Operand(result));
  __ LoadObject(result, Bool::True());
  __ LoadObject(TMP, Bool::False());
  __ csel(result, TMP, result, EQ);
}

DEFINE_EMIT(Int32x4Select,
            (VRegister out,
             VRegister mask,
             VRegister trueValue,
             VRegister falseValue,
             Temp<VRegister> temp)) {
  // Copy mask.
  __ vmov(temp, mask);
  // Invert it.
  __ vnot(temp, temp);
  // mask = mask & trueValue.
  __ vand(mask, mask, trueValue);
  // temp = temp & falseValue.
  __ vand(temp, temp, falseValue);
  // out = mask | temp.
  __ vorr(out, mask, temp);
}

DEFINE_EMIT(Int32x4WithFlag,
            (SameAsFirstInput, VRegister mask, Register flag)) {
  const VRegister result = mask;
  __ CompareObject(flag, Bool::True());
  __ LoadImmediate(TMP, 0xffffffff);
  __ csel(TMP, TMP, ZR, EQ);
  switch (instr->kind()) {
    case SimdOpInstr::kInt32x4WithFlagX:
      __ vinsw(result, 0, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagY:
      __ vinsw(result, 1, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagZ:
      __ vinsw(result, 2, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagW:
      __ vinsw(result, 3, TMP);
      break;
    default:
      UNREACHABLE();
  }
}

// Map SimdOpInstr::Kind-s to corresponding emit functions. Uses the following
// format:
//
//     CASE(OpA) CASE(OpB) ____(Emitter) - Emitter is used to emit OpA and OpB.
//     SIMPLE(OpA) - Emitter with name OpA is used to emit OpA.
//
#define SIMD_OP_VARIANTS(CASE, ____)                                           \
  SIMD_OP_SIMPLE_BINARY(CASE)                                                  \
  CASE(Float32x4ShuffleMix)                                                    \
  CASE(Int32x4ShuffleMix)                                                      \
  CASE(Float32x4NotEqual)                                                      \
  CASE(Float32x4LessThan)                                                      \
  CASE(Float32x4LessThanOrEqual)                                               \
  CASE(Float32x4Scale)                                                         \
  CASE(Float64x2FromDoubles)                                                   \
  CASE(Float64x2Scale)                                                         \
  ____(SimdBinaryOp)                                                           \
  SIMD_OP_SIMPLE_UNARY(CASE)                                                   \
  CASE(Float32x4ShuffleX)                                                      \
  CASE(Float32x4ShuffleY)                                                      \
  CASE(Float32x4ShuffleZ)                                                      \
  CASE(Float32x4ShuffleW)                                                      \
  CASE(Int32x4Shuffle)                                                         \
  CASE(Float32x4Shuffle)                                                       \
  CASE(Float32x4Splat)                                                         \
  CASE(Float64x2GetX)                                                          \
  CASE(Float64x2GetY)                                                          \
  CASE(Float64x2Splat)                                                         \
  CASE(Float64x2ToFloat32x4)                                                   \
  CASE(Float32x4ToFloat64x2)                                                   \
  ____(SimdUnaryOp)                                                            \
  CASE(Float32x4GetSignMask)                                                   \
  CASE(Int32x4GetSignMask)                                                     \
  ____(Simd32x4GetSignMask)                                                    \
  CASE(Float32x4FromDoubles)                                                   \
  ____(Float32x4FromDoubles)                                                   \
  CASE(Float32x4Zero)                                                          \
  CASE(Float64x2Zero)                                                          \
  ____(SimdZero)                                                               \
  CASE(Float32x4Clamp)                                                         \
  ____(Float32x4Clamp)                                                         \
  CASE(Float32x4WithX)                                                         \
  CASE(Float32x4WithY)                                                         \
  CASE(Float32x4WithZ)                                                         \
  CASE(Float32x4WithW)                                                         \
  ____(Float32x4With)                                                          \
  CASE(Float32x4ToInt32x4)                                                     \
  CASE(Int32x4ToFloat32x4)                                                     \
  ____(Simd32x4ToSimd32x4)                                                     \
  CASE(Float64x2GetSignMask)                                                   \
  ____(Float64x2GetSignMask)                                                   \
  CASE(Float64x2WithX)                                                         \
  CASE(Float64x2WithY)                                                         \
  ____(Float64x2With)                                                          \
  CASE(Int32x4FromInts)                                                        \
  ____(Int32x4FromInts)                                                        \
  CASE(Int32x4FromBools)                                                       \
  ____(Int32x4FromBools)                                                       \
  CASE(Int32x4GetFlagX)                                                        \
  CASE(Int32x4GetFlagY)                                                        \
  CASE(Int32x4GetFlagZ)                                                        \
  CASE(Int32x4GetFlagW)                                                        \
  ____(Int32x4GetFlag)                                                         \
  CASE(Int32x4Select)                                                          \
  ____(Int32x4Select)                                                          \
  CASE(Int32x4WithFlagX)                                                       \
  CASE(Int32x4WithFlagY)                                                       \
  CASE(Int32x4WithFlagZ)                                                       \
  CASE(Int32x4WithFlagW)                                                       \
  ____(Int32x4WithFlag)

LocationSummary* SimdOpInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  switch (kind()) {
#define CASE(Name, ...) case k##Name:
#define EMIT(Name)                                                             \
  return MakeLocationSummaryFromEmitter(zone, this, &Emit##Name);
    SIMD_OP_VARIANTS(CASE, EMIT)
#undef CASE
#undef EMIT
    case kIllegalSimdOp:
      UNREACHABLE();
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
    SIMD_OP_VARIANTS(CASE, EMIT)
#undef CASE
#undef EMIT
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
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}

void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (kind() == MathUnaryInstr::kSqrt) {
    const VRegister val = locs()->in(0).fpu_reg();
    const VRegister result = locs()->out(0).fpu_reg();
    __ fsqrtd(result, val);
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    const VRegister val = locs()->in(0).fpu_reg();
    const VRegister result = locs()->out(0).fpu_reg();
    __ fmuld(result, val, val);
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
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_in(1, Location::RegisterLocation(R1));
  summary->set_in(2, Location::RegisterLocation(R2));
  summary->set_in(3, Location::RegisterLocation(R3));
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}

void CaseInsensitiveCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Call the function.
  __ CallRuntime(TargetFunction(), TargetFunction().argument_count());
}

LocationSummary* MathMinMaxInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    // Reuse the left register so that code can be made shorter.
    summary->set_out(0, Location::SameAsFirstInput());
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
  const intptr_t is_min = (op_kind() == MethodRecognizer::kMathMin);
  if (result_cid() == kDoubleCid) {
    compiler::Label done, returns_nan, are_equal;
    const VRegister left = locs()->in(0).fpu_reg();
    const VRegister right = locs()->in(1).fpu_reg();
    const VRegister result = locs()->out(0).fpu_reg();
    __ fcmpd(left, right);
    __ b(&returns_nan, VS);
    __ b(&are_equal, EQ);
    const Condition double_condition =
        is_min ? TokenKindToDoubleCondition(Token::kLTE)
               : TokenKindToDoubleCondition(Token::kGTE);
    ASSERT(left == result);
    __ b(&done, double_condition);
    __ fmovdd(result, right);
    __ b(&done);

    __ Bind(&returns_nan);
    __ LoadDImmediate(result, NAN);
    __ b(&done);

    __ Bind(&are_equal);
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ fmovrd(TMP, left);  // Sign bit is in bit 63 of TMP.
    __ CompareImmediate(TMP, 0);
    if (is_min) {
      ASSERT(left == result);
      __ b(&done, LT);
      __ fmovdd(result, right);
    } else {
      __ b(&done, GE);
      __ fmovdd(result, right);
      ASSERT(left == result);
    }
    __ Bind(&done);
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  __ CompareRegisters(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ csel(result, right, left, GT);
  } else {
    __ csel(result, right, left, LT);
  }
}

LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kNEGATE: {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ subs(result, ZR, compiler::Operand(value));
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn(result, value);
      // Remove inverted smi-tag.
      __ andi(result, result, compiler::Immediate(~kSmiTagMask));
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
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}

void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister result = locs()->out(0).fpu_reg();
  const VRegister value = locs()->in(0).fpu_reg();
  __ fnegd(result, value);
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
  const VRegister result = locs()->out(0).fpu_reg();
  __ scvtfdw(result, value);
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
  const VRegister result = locs()->out(0).fpu_reg();
  __ SmiUntag(TMP, value);
  __ scvtfdx(result, TMP);
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
  const VRegister result = locs()->out(0).fpu_reg();
  __ scvtfdx(result, value);
}

LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(R1));
  result->set_out(0, Location::RegisterLocation(R0));
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  const Register value_obj = locs()->in(0).reg();
  ASSERT(result == R0);
  ASSERT(result != value_obj);
  __ LoadDFieldFromOffset(VTMP, value_obj, Double::value_offset());

  compiler::Label do_call, done;
  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM64 because fcvtzds gives 0 for NaN.
  __ fcmpd(VTMP, VTMP);
  __ b(&do_call, VS);

  __ fcvtzds(result, VTMP);
  // Overflow is signaled with minint.

  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC000000000000000);
  __ b(&do_call, MI);
  __ SmiTag(result);
  __ b(&done);
  __ Bind(&do_call);
  __ Push(value_obj);
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
  const Register result = locs()->out(0).reg();
  const VRegister value = locs()->in(0).fpu_reg();
  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM64 because fcvtzds gives 0 for NaN.
  // TODO(zra): Check spec that this is true.
  __ fcmpd(value, value);
  __ b(deopt, VS);

  __ fcvtzds(result, value);
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC000000000000000);
  __ b(deopt, MI);
  __ SmiTag(result);
}

LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}

void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  __ fcvtsd(result, value);
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
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  __ fcvtds(result, value);
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 1 : 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(V0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(V1));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    result->set_temp(0, Location::FpuRegisterLocation(V30));
  }
  result->set_out(0, Location::FpuRegisterLocation(V0));
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

  const VRegister base = locs->in(0).fpu_reg();
  const VRegister exp = locs->in(1).fpu_reg();
  const VRegister result = locs->out(0).fpu_reg();
  const VRegister saved_base = locs->temp(0).fpu_reg();
  ASSERT((base == result) && (result != saved_base));

  compiler::Label skip_call, try_sqrt, check_base, return_nan, do_pow;
  __ fmovdd(saved_base, base);
  __ LoadDImmediate(result, 1.0);
  // exponent == 0.0 -> return 1.0;
  __ fcmpdz(exp);
  __ b(&check_base, VS);  // NaN -> check base.
  __ b(&skip_call, EQ);   // exp is 0.0, result is 1.0.

  // exponent == 1.0 ?
  __ fcmpd(exp, result);
  compiler::Label return_base;
  __ b(&return_base, EQ);

  // exponent == 2.0 ?
  __ LoadDImmediate(VTMP, 2.0);
  __ fcmpd(exp, VTMP);
  compiler::Label return_base_times_2;
  __ b(&return_base_times_2, EQ);

  // exponent == 3.0 ?
  __ LoadDImmediate(VTMP, 3.0);
  __ fcmpd(exp, VTMP);
  __ b(&check_base, NE);

  // base_times_3.
  __ fmuld(result, saved_base, saved_base);
  __ fmuld(result, result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_base);
  __ fmovdd(result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_base_times_2);
  __ fmuld(result, saved_base, saved_base);
  __ b(&skip_call);

  __ Bind(&check_base);
  // Note: 'exp' could be NaN.
  // base == 1.0 -> return 1.0;
  __ fcmpd(saved_base, result);
  __ b(&return_nan, VS);
  __ b(&skip_call, EQ);  // base is 1.0, result is 1.0.

  __ fcmpd(saved_base, exp);
  __ b(&try_sqrt, VC);  // // Neither 'exp' nor 'base' is NaN.

  __ Bind(&return_nan);
  __ LoadDImmediate(result, NAN);
  __ b(&skip_call);

  compiler::Label return_zero;
  __ Bind(&try_sqrt);

  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadDImmediate(result, kNegInfinity);

  // base == -Infinity -> call pow;
  __ fcmpd(saved_base, result);
  __ b(&do_pow, EQ);

  // exponent == 0.5 ?
  __ LoadDImmediate(result, 0.5);
  __ fcmpd(exp, result);
  __ b(&do_pow, NE);

  // base == 0 -> return 0;
  __ fcmpdz(saved_base);
  __ b(&return_zero, EQ);

  __ fsqrtd(result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_zero);
  __ LoadDImmediate(result, 0.0);
  __ b(&skip_call);

  __ Bind(&do_pow);
  __ fmovdd(base, saved_base);  // Restore base.

  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  __ CallRuntime(TargetFunction(), InputCount());
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
    const VRegister out = locs()->out(0).fpu_reg();
    const VRegister in = in_loc.fpu_reg();
    __ fmovdd(out, in);
  } else {
    ASSERT(representation() == kTagged);
    const Register out = locs()->out(0).reg();
    const Register in = in_loc.reg();
    __ mov(out, in);
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
  // Output is a pair of registers.
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
    // Handle divide by zero in runtime.
    __ CompareRegisters(right, ZR);
    __ b(deopt, EQ);
  }

  __ SmiUntag(result_mod, left);
  __ SmiUntag(TMP, right);

  __ sdiv(result_div, result_mod, TMP);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  __ CompareImmediate(result_div, 0x4000000000000000);
  __ b(deopt, EQ);
  // result_mod <- left - right * result_div.
  __ msub(result_mod, TMP, result_div, result_mod);
  __ SmiTag(result_div);
  __ SmiTag(result_mod);
  // Correct MOD result:
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  compiler::Label done;
  __ CompareRegisters(result_mod, ZR);
  __ b(&done, GE);
  // Result is negative, adjust it.
  __ CompareRegisters(right, ZR);
  __ sub(TMP2, result_mod, compiler::Operand(right));
  __ add(TMP, result_mod, compiler::Operand(right));
  __ csel(result_mod, TMP, TMP2, GE);
  __ Bind(&done);
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
  ASSERT(IsDeoptIfNull() || IsDeoptIfNotNull());
  Condition cond = IsDeoptIfNull() ? EQ : NE;
  __ b(deopt, cond);
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  compiler::Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ AddImmediate(biased_cid, -min);
  __ CompareImmediate(biased_cid, max - min);
  __ b(deopt, HI);

  Register bit_reg = locs()->temp(1).reg();
  __ LoadImmediate(bit_reg, 1);
  __ lslv(bit_reg, bit_reg, biased_cid);
  __ TestImmediate(bit_reg, mask);
  __ b(deopt, EQ);
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
    // For class ID ranges use a subtract followed by an unsigned
    // comparison to check both ends of the ranges with one comparison.
    __ AddImmediate(biased_cid, bias - cid_start);
    bias = cid_start;
    __ CompareImmediate(biased_cid, cid_end - cid_start);
    no_match = HI;  // Unsigned higher.
    match = LS;     // Unsigned lower or same.
  }
  if (is_last) {
    __ b(deopt, no_match);
  } else {
    __ b(is_ok, match);
  }
  return bias;
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
    __ b(deopt, NE);
  } else {
    __ AddImmediate(value, -Smi::RawValue(cids_.cid_start));
    __ CompareImmediate(value, Smi::RawValue(cids_.cid_end - cids_.cid_start));
    __ b(deopt, HI);  // Unsigned higher.
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

  const intptr_t index_cid = index()->Type()->ToCid();
  if (length_loc.IsConstant() && index_loc.IsConstant()) {
    // TODO(srdjan): remove this code once failures are fixed.
    if ((Smi::Cast(length_loc.constant()).Value() >
         Smi::Cast(index_loc.constant()).Value()) &&
        (Smi::Cast(index_loc.constant()).Value() >= 0)) {
      // This CheckArrayBoundInstr should have been eliminated.
      return;
    }
    ASSERT((Smi::Cast(length_loc.constant()).Value() <=
            Smi::Cast(index_loc.constant()).Value()) ||
           (Smi::Cast(index_loc.constant()).Value() < 0));
    // Unconditionally deoptimize for constant bounds checks because they
    // only occur only when index is out-of-bounds.
    __ b(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(length, static_cast<int64_t>(index.raw()));
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ tst(index, compiler::Operand(index));
      __ b(deopt, MI);
    } else {
      __ CompareImmediate(index, static_cast<int64_t>(length.raw()));
      __ b(deopt, CS);
    }
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ CompareRegisters(index, length);
    __ b(deopt, CS);
  }
}

class Int64DivideSlowPath : public ThrowErrorSlowPathCode {
 public:
  Int64DivideSlowPath(BinaryInt64OpInstr* instruction,
                      Register divisor,
                      Range* divisor_range,
                      Register tmp,
                      Register out,
                      intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kIntegerDivisionByZeroExceptionRuntimeEntry,
                               try_index),
        is_mod_(instruction->op_kind() == Token::kMOD),
        divisor_(divisor),
        divisor_range_(divisor_range),
        tmp_(tmp),
        out_(out),
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
    // Adjust modulo for negative sign, optimized for known ranges.
    // if (divisor < 0)
    //   out -= divisor;
    // else
    //   out += divisor;
    if (has_adjust_sign()) {
      __ Bind(adjust_sign_label());
      if (RangeUtils::Overlaps(divisor_range_, -1, 1)) {
        // General case.
        __ CompareRegisters(divisor_, ZR);
        __ sub(tmp_, out_, compiler::Operand(divisor_));
        __ add(out_, out_, compiler::Operand(divisor_));
        __ csel(out_, tmp_, out_, LT);
      } else if (divisor_range_->IsPositive()) {
        // Always positive.
        __ add(out_, out_, compiler::Operand(divisor_));
      } else {
        // Always negative.
        __ sub(out_, out_, compiler::Operand(divisor_));
      }
      __ b(exit_label());
    }
  }

  const char* name() override { return "int64 divide"; }

  bool has_divide_by_zero() { return RangeUtils::CanBeZero(divisor_range_); }

  bool has_adjust_sign() { return is_mod_; }

  bool is_needed() { return has_divide_by_zero() || has_adjust_sign(); }

  compiler::Label* adjust_sign_label() {
    ASSERT(has_adjust_sign());
    return &adjust_sign_label_;
  }

 private:
  bool is_mod_;
  Register divisor_;
  Range* divisor_range_;
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

  // Special case 64-bit div/mod by compile-time constant. Note that various
  // special constants (such as powers of two) should have been optimized
  // earlier in the pipeline. Div or mod by zero falls into general code
  // to implement the exception.
  if (FLAG_optimization_level <= 2) {
    // We only consider magic operations under O3.
  } else if (auto c = instruction->right()->definition()->AsConstant()) {
    if (c->value().IsInteger()) {
      const int64_t divisor = Integer::Cast(c->value()).AsInt64Value();
      if (divisor <= -2 || divisor >= 2) {
        // For x DIV c or x MOD c: use magic operations.
        compiler::Label pos;
        int64_t magic = 0;
        int64_t shift = 0;
        Utils::CalculateMagicAndShiftForDivRem(divisor, &magic, &shift);
        // Compute tmp = high(magic * numerator).
        __ LoadImmediate(TMP2, magic);
        __ smulh(TMP2, TMP2, left);
        // Compute tmp +/-= numerator.
        if (divisor > 0 && magic < 0) {
          __ add(TMP2, TMP2, compiler::Operand(left));
        } else if (divisor < 0 && magic > 0) {
          __ sub(TMP2, TMP2, compiler::Operand(left));
        }
        // Shift if needed.
        if (shift != 0) {
          __ add(TMP2, ZR, compiler::Operand(TMP2, ASR, shift));
        }
        // Finalize DIV or MOD.
        if (op_kind == Token::kTRUNCDIV) {
          __ sub(out, TMP2, compiler::Operand(TMP2, ASR, 63));
        } else {
          __ sub(TMP2, TMP2, compiler::Operand(TMP2, ASR, 63));
          __ LoadImmediate(TMP, divisor);
          __ msub(out, TMP2, TMP, left);
          // Compensate for Dart's Euclidean view of MOD.
          __ CompareRegisters(out, ZR);
          if (divisor > 0) {
            __ add(TMP2, out, compiler::Operand(TMP));
          } else {
            __ sub(TMP2, out, compiler::Operand(TMP));
          }
          __ csel(out, TMP2, out, LT);
        }
        return;
      }
    }
  }

  // Prepare a slow path.
  Range* right_range = instruction->right()->definition()->range();
  Int64DivideSlowPath* slow_path = new (Z) Int64DivideSlowPath(
      instruction, right, right_range, tmp, out, compiler->CurrentTryIndex());

  // Handle modulo/division by zero exception on slow path.
  if (slow_path->has_divide_by_zero()) {
    __ CompareRegisters(right, ZR);
    __ b(slow_path->entry_label(), EQ);
  }

  // Perform actual operation
  //   out = left % right
  // or
  //   out = left / right.
  if (op_kind == Token::kMOD) {
    __ sdiv(tmp, left, right);
    __ msub(out, tmp, right, left);
    // For the % operator, the sdiv instruction does not
    // quite do what we want. Adjust for sign on slow path.
    __ CompareRegisters(out, ZR);
    __ b(slow_path->adjust_sign_label(), LT);
  } else {
    __ sdiv(out, left, right);
  }

  if (slow_path->is_needed()) {
    __ Bind(slow_path->exit_label());
    compiler->AddSlowPathCode(slow_path);
  }
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  switch (op_kind()) {
    case Token::kMOD:
    case Token::kTRUNCDIV: {
      const intptr_t kNumInputs = 2;
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
    default: {
      const intptr_t kNumInputs = 2;
      const intptr_t kNumTemps = 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, LocationRegisterOrConstant(right()));
      summary->set_out(0, Location::RequiresRegister());
      return summary;
    }
  }
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!can_overflow());
  ASSERT(!CanDeoptimize());

  const Register left = locs()->in(0).reg();
  const Location right = locs()->in(1);
  const Register out = locs()->out(0).reg();

  if (op_kind() == Token::kMOD || op_kind() == Token::kTRUNCDIV) {
    Register tmp =
        (op_kind() == Token::kMOD) ? locs()->temp(0).reg() : kNoRegister;
    EmitInt64ModTruncDiv(compiler, this, op_kind(), left, right.reg(), tmp,
                         out);
    return;
  } else if (op_kind() == Token::kMUL) {
    Register r = TMP;
    if (right.IsConstant()) {
      int64_t value;
      const bool ok = compiler::HasIntegerValue(right.constant(), &value);
      RELEASE_ASSERT(ok);
      __ LoadImmediate(r, value);
    } else {
      r = right.reg();
    }
    __ mul(out, left, r);
    return;
  }

  if (right.IsConstant()) {
    int64_t value;
    const bool ok = compiler::HasIntegerValue(right.constant(), &value);
    RELEASE_ASSERT(ok);
    switch (op_kind()) {
      case Token::kADD:
        __ AddImmediate(out, left, value);
        break;
      case Token::kSUB:
        __ AddImmediate(out, left, -value);
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
    compiler::Operand r = compiler::Operand(right.reg());
    switch (op_kind()) {
      case Token::kADD:
        __ add(out, left, r);
        break;
      case Token::kSUB:
        __ sub(out, left, r);
        break;
      case Token::kBIT_AND:
        __ and_(out, left, r);
        break;
      case Token::kBIT_OR:
        __ orr(out, left, r);
        break;
      case Token::kBIT_XOR:
        __ eor(out, left, r);
        break;
      default:
        UNREACHABLE();
    }
  }
}

static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out,
                                     Register left,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  switch (op_kind) {
    case Token::kSHR: {
      __ AsrImmediate(out, left,
                      Utils::Minimum<int64_t>(shift, kBitsPerWord - 1));
      break;
    }
    case Token::kSHL: {
      ASSERT(shift < 64);
      __ LslImmediate(out, left, shift);
      break;
    }
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
    case Token::kSHR: {
      __ asrv(out, left, right);
      break;
    }
    case Token::kSHL: {
      __ lslv(out, left, right);
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftUint32ByConstant(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register out,
                                      Register left,
                                      const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  if (shift >= 32) {
    __ LoadImmediate(out, 0);
  } else {
    switch (op_kind) {
      case Token::kSHR:
        __ LsrImmediate(out, left, shift, compiler::kFourBytes);
        break;
      case Token::kSHL:
        __ LslImmediate(out, left, shift, compiler::kFourBytes);
        break;
      default:
        UNREACHABLE();
    }
  }
}

static void EmitShiftUint32ByRegister(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register out,
                                      Register left,
                                      Register right) {
  switch (op_kind) {
    case Token::kSHR:
      __ lsrvw(out, left, right);
      break;
    case Token::kSHL:
      __ lslvw(out, left, right);
      break;
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
    const Register left = instruction()->locs()->in(0).reg();
    const Register right = instruction()->locs()->in(1).reg();
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT((out != left) && (out != right));

    compiler::Label throw_error;
    __ tbnz(&throw_error, right, kBitsPerWord - 1);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ AsrImmediate(out, left, kBitsPerWord - 1);
        break;
      case Token::kSHL:
        __ mov(out, ZR);
        break;
      default:
        UNREACHABLE();
    }
    __ b(exit_label());

    __ Bind(&throw_error);

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ str(right,
           compiler::Address(THR, Thread::unboxed_int64_runtime_arg_offset()));
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
                         ? LocationRegisterOrConstant(right())
                         : Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), out, left,
                             locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    Register shift = locs()->in(1).reg();

    // Jump to a slow path if shift is larger than 63 or less than 0.
    ShiftInt64OpSlowPath* slow_path = NULL;
    if (!IsShiftCountInRange()) {
      slow_path =
          new (Z) ShiftInt64OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);
      __ CompareImmediate(shift, kShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out, left, shift);

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
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void SpeculativeShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), out, left,
                             locs()->in(1).constant());
  } else {
    // Code for a variable shift amount.
    Register shift = locs()->in(1).reg();

    // Untag shift count.
    __ SmiUntag(TMP, shift);
    shift = TMP;

    // Deopt if shift is larger than 63 or less than 0 (or not a smi).
    if (!IsShiftCountInRange()) {
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

      __ CompareImmediate(shift, kShiftCountLimit);
      __ b(deopt, HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out, left, shift);
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
    const Register right = instruction()->locs()->in(1).reg();

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ str(right,
           compiler::Address(THR, Thread::unboxed_int64_runtime_arg_offset()));
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
                         ? LocationRegisterOrConstant(right())
                         : Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    const Register right = locs()->in(1).reg();
    const bool shift_count_in_range =
        IsShiftCountInRange(kUint32ShiftCountLimit);

    // Jump to a slow path if shift count is negative.
    if (!shift_count_in_range) {
      ShiftUint32OpSlowPath* slow_path =
          new (Z) ShiftUint32OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);

      __ tbnz(slow_path->entry_label(), right, kBitsPerWord - 1);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!shift_count_in_range) {
      // If shift value is > 31, return zero.
      __ CompareImmediate(right, 31);
      __ csel(out, out, ZR, LE);
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
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void SpeculativeShiftUint32OpInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
  } else {
    Register right = locs()->in(1).reg();
    const bool shift_count_in_range =
        IsShiftCountInRange(kUint32ShiftCountLimit);

    __ SmiUntag(TMP, right);
    right = TMP;

    // Jump to a slow path if shift count is negative.
    if (!shift_count_in_range) {
      // Deoptimize if shift count is negative.
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

      __ tbnz(deopt, right, kBitsPerWord - 1);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!shift_count_in_range) {
      // If shift value is > 31, return zero.
      __ CompareImmediate(right, 31);
      __ csel(out, out, ZR, LE);
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
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ mvn(out, left);
      break;
    case Token::kNEGATE:
      __ sub(out, ZR, compiler::Operand(left));
      break;
    default:
      UNREACHABLE();
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
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BinaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  compiler::Operand r = compiler::Operand(right);
  Register out = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ and_(out, left, r);
      break;
    case Token::kBIT_OR:
      __ orr(out, left, r);
      break;
    case Token::kBIT_XOR:
      __ eor(out, left, r);
      break;
    case Token::kADD:
      __ addw(out, left, r);
      break;
    case Token::kSUB:
      __ subw(out, left, r);
      break;
    case Token::kMUL:
      __ mulw(out, left, right);
      break;
    default:
      UNREACHABLE();
  }
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
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();

  ASSERT(op_kind() == Token::kBIT_NOT);
  __ mvnw(out, left);
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
  if (CanDeoptimize()) {
    summary->set_out(0, Location::RequiresRegister());
  } else {
    summary->set_out(0, Location::SameAsFirstInput());
  }
  return summary;
}

void IntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(from() != to());  // We don't convert from a representation to itself.

  const bool is_nop_conversion =
      (from() == kUntagged && to() == kUnboxedIntPtr) ||
      (from() == kUnboxedIntPtr && to() == kUntagged);
  if (is_nop_conversion) {
    ASSERT(locs()->in(0).reg() == locs()->out(0).reg());
    return;
  }

  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  compiler::Label* deopt =
      !CanDeoptimize()
          ? NULL
          : compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    if (CanDeoptimize()) {
      __ tbnz(deopt, value,
              31);  // If sign bit is set it won't fit in a uint32.
    }
    if (out != value) {
      __ mov(out, value);  // For positive values the bits are the same.
    }
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    if (CanDeoptimize()) {
      __ tbnz(deopt, value,
              31);  // If high bit is set it won't fit in an int32.
    }
    if (out != value) {
      __ mov(out, value);  // For 31 bit values the bits are the same.
    }
  } else if (from() == kUnboxedInt64) {
    if (to() == kUnboxedInt32) {
      if (is_truncating() || out != value) {
        __ sxtw(out, value);  // Signed extension 64->32.
      }
    } else {
      ASSERT(to() == kUnboxedUint32);
      if (is_truncating() || out != value) {
        __ uxtw(out, value);  // Unsigned extension 64->32.
      }
    }
    if (CanDeoptimize()) {
      ASSERT(to() == kUnboxedInt32);
      __ cmp(out, compiler::Operand(value));
      __ b(deopt, NE);  // Value cannot be held in Int32, deopt.
    }
  } else if (to() == kUnboxedInt64) {
    if (from() == kUnboxedUint32) {
      __ uxtw(out, value);
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ sxtw(out, value);  // Signed extension 32->64.
    }
  } else {
    UNREACHABLE();
  }
}

LocationSummary* BitCastInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, /*num_inputs=*/InputCount(),
                                 /*num_temps=*/0, LocationSummary::kNoCall);
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
    case kUnboxedInt32: {
      ASSERT(to() == kUnboxedFloat);
      const Register from_reg = locs()->in(0).reg();
      const FpuRegister to_reg = locs()->out(0).fpu_reg();
      __ fmovsr(to_reg, from_reg);
      break;
    }
    case kUnboxedFloat: {
      ASSERT(to() == kUnboxedInt32);
      const FpuRegister from_reg = locs()->in(0).fpu_reg();
      const Register to_reg = locs()->out(0).reg();
      __ fmovrs(to_reg, from_reg);
      break;
    }
    case kUnboxedInt64: {
      ASSERT(to() == kUnboxedDouble);

      const Register from_reg = locs()->in(0).reg();
      const FpuRegister to_reg = locs()->out(0).fpu_reg();
      __ fmovdr(to_reg, from_reg);
      break;
    }
    case kUnboxedDouble: {
      ASSERT(to() == kUnboxedInt64);
      const FpuRegister from_reg = locs()->in(0).fpu_reg();
      const Register to_reg = locs()->out(0).reg();
      __ fmovrd(to_reg, from_reg);
      break;
    }
    default:
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
      __ b(compiler->GetJumpLabel(entry));
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
    __ b(compiler->GetJumpLabel(successor()));
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
  Register target_address_reg = locs()->temp_slot(0)->reg();

  // Load code entry point.
  const intptr_t entry_offset = __ CodeSize();
  if (Utils::IsInt(21, -entry_offset)) {
    __ adr(target_address_reg, compiler::Immediate(-entry_offset));
  } else {
    __ adr(target_address_reg, compiler::Immediate(0));
    __ AddImmediate(target_address_reg, -entry_offset);
  }

  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  compiler::Operand offset_opr =
      (offset()->definition()->representation() == kTagged)
          ? compiler::Operand(offset_reg, ASR, kSmiTagSize)
          : compiler::Operand(offset_reg);
  __ add(target_address_reg, target_address_reg, offset_opr);

  // Jump to the absolute address.
  __ br(target_address_reg);
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(R0));
    locs->set_in(1, Location::RegisterLocation(R1));
    locs->set_out(0, Location::RegisterLocation(R0));
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
  Condition orig_cond = (kind() == Token::kEQ_STRICT) ? EQ : NE;
  if (!needs_number_check() && compiler::target::IsSmi(obj) &&
      compiler::target::ToRawSmi(obj) == 0 &&
      CanUseCbzTbzForComparison(compiler, reg, orig_cond, labels)) {
    EmitCbzTbz(reg, compiler, orig_cond, labels);
    return kInvalidCondition;
  } else {
    return compiler->EmitEqualityRegConstCompare(reg, obj, needs_number_check(),
                                                 source(), deopt_id());
  }
}

void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  const Register result = this->locs()->out(0).reg();

  // TODO(dartbug.com/29908): Use csel here for better branch prediction?
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
  compiler::Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
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

LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register input = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  if (value()->Type()->ToCid() == kBoolCid) {
    __ eori(
        result, input,
        compiler::Immediate(compiler::target::ObjectAlignment::kBoolValueMask));
  } else {
    __ LoadObject(result, Bool::True());
    __ LoadObject(TMP, Bool::False());
    __ CompareRegisters(result, input);
    __ csel(result, TMP, result, EQ);
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
  locs->set_out(0, Location::RegisterLocation(R0));
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
  __ BranchLinkPatchable(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
