// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/backend/il.h"

#include "platform/assert.h"
#include "platform/memory_sanitizer.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/runtime_api.h"
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
#if defined(DART_COMPRESSED_POINTERS)
  // No addressing mode will ignore the upper bits. Cannot use the shorter `orl`
  // to clear the upper bits as this instructions uses negative indices as part
  // of FP-relative loads.
  // TODO(compressed-pointers): Can we guarantee the index is already
  // sign-extended if always comes for an args-descriptor load?
  __ movsxd(index, index);
#endif

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
#if defined(DART_COMPRESSED_POINTERS)
  // No addressing mode will ignore the upper bits. Cannot use the shorter `orl`
  // to clear the upper bits as this instructions uses negative indices as part
  // of FP-relative stores.
  // TODO(compressed-pointers): Can we guarantee the index is already
  // sign-extended if always comes for an args-descriptor load?
  __ movsxd(index, index);
#endif
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
  const bool needs_writable_inputs =
      (((element_size_ == 1) && !unboxed_inputs_) ||
       ((element_size_ == 16) && unboxed_inputs_));
  locs->set_in(kSrcStartPos,
               needs_writable_inputs
                   ? LocationWritableRegisterOrConstant(src_start())
                   : LocationRegisterOrConstant(src_start()));
  locs->set_in(kDestStartPos,
               needs_writable_inputs
                   ? LocationWritableRegisterOrConstant(dest_start())
                   : LocationRegisterOrConstant(dest_start()));
  if (length()->BindsToSmiConstant() && length()->BoundSmiConstant() <= 4) {
    locs->set_in(
        kLengthPos,
        Location::Constant(
            length()->definition()->OriginalDefinition()->AsConstant()));
  } else {
    locs->set_in(kLengthPos, Location::RegisterLocation(RCX));
  }
  return locs;
}

static inline intptr_t SizeOfMemoryCopyElements(intptr_t element_size) {
  return Utils::Minimum<intptr_t>(element_size, compiler::target::kWordSize);
}

void MemoryCopyInstr::PrepareLengthRegForLoop(FlowGraphCompiler* compiler,
                                              Register length_reg,
                                              compiler::Label* done) {
  const intptr_t mov_size = SizeOfMemoryCopyElements(element_size_);

  // We want to convert the value in length_reg to an unboxed length in
  // terms of mov_size-sized elements.
  const intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                         Utils::ShiftForPowerOfTwo(mov_size) -
                         (unboxed_inputs() ? 0 : kSmiTagShift);
  if (shift < 0) {
    ASSERT_EQUAL(shift, -kSmiTagShift);
    __ SmiUntag(length_reg);
  } else if (shift > 0) {
    __ OBJ(shl)(length_reg, compiler::Immediate(shift));
  } else {
    __ ExtendNonNegativeSmi(length_reg);
  }
}

void MemoryCopyInstr::EmitLoopCopy(FlowGraphCompiler* compiler,
                                   Register dest_reg,
                                   Register src_reg,
                                   Register length_reg,
                                   compiler::Label* done,
                                   compiler::Label* copy_forwards) {
  const intptr_t mov_size = SizeOfMemoryCopyElements(element_size_);
  const bool reversed = copy_forwards != nullptr;
  if (reversed) {
    // Avoid doing the extra work to prepare for the rep mov instructions
    // if the length to copy is zero.
    __ BranchIfZero(length_reg, done);
    // Verify that the overlap actually exists by checking to see if
    // the first element in dest <= the last element in src.
    const ScaleFactor scale = ToScaleFactor(mov_size, /*index_unboxed=*/true);
    __ leaq(TMP, compiler::Address(src_reg, length_reg, scale, -mov_size));
    __ CompareRegisters(dest_reg, TMP);
#if defined(USING_MEMORY_SANITIZER)
    const auto jump_distance = compiler::Assembler::kFarJump;
#else
    const auto jump_distance = compiler::Assembler::kNearJump;
#endif
    __ BranchIf(UNSIGNED_GREATER, copy_forwards, jump_distance);
    // The backwards move must be performed, so move TMP -> src_reg and do the
    // same adjustment for dest_reg.
    __ movq(src_reg, TMP);
    __ leaq(dest_reg,
            compiler::Address(dest_reg, length_reg, scale, -mov_size));
    __ std();
  }
#if defined(USING_MEMORY_SANITIZER)
  // The `rep` instruction sets `length_reg` to 0.
  __ movq(TMP, length_reg);
#endif
  switch (mov_size) {
    case 1:
      __ rep_movsb();
      break;
    case 2:
      __ rep_movsw();
      break;
    case 4:
      __ rep_movsd();
      break;
    case 8:
      __ rep_movsq();
      break;
    default:
      UNREACHABLE();
  }
  if (reversed) {
    __ cld();
  }

#if defined(USING_MEMORY_SANITIZER)
  RegisterSet kVolatileRegisterSet(CallingConventions::kVolatileCpuRegisters,
                                   CallingConventions::kVolatileXmmRegisters);
  __ PushRegisters(kVolatileRegisterSet);
  __ MulImmediate(TMP, mov_size);
  __ MsanUnpoison(dest_reg, TMP);
  __ PopRegisters(kVolatileRegisterSet);
#endif
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Location start_loc) {
  intptr_t offset;
  if (IsTypedDataBaseClassId(array_cid)) {
    __ movq(array_reg,
            compiler::FieldAddress(
                array_reg, compiler::target::PointerBase::data_offset()));
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
  ASSERT(start_loc.IsRegister() || start_loc.IsConstant());
  if (start_loc.IsConstant()) {
    const auto& constant = start_loc.constant();
    ASSERT(constant.IsInteger());
    const int64_t start_value = Integer::Cast(constant).AsInt64Value();
    const intptr_t add_value = Utils::AddWithWrapAround(
        Utils::MulWithWrapAround<intptr_t>(start_value, element_size_), offset);
    __ AddImmediate(array_reg, add_value);
    return;
  }
  // Note that start_reg must be writable in the special cases below.
  const Register start_reg = start_loc.reg();
  bool index_unboxed = unboxed_inputs_;
  // Both special cases below assume that Smis are only shifted one bit.
  COMPILE_ASSERT(kSmiTagShift == 1);
  if (element_size_ == 1 && !index_unboxed) {
    // Shift the value to the right by tagging it as a Smi.
    __ SmiUntag(start_reg);
    index_unboxed = true;
  } else if (element_size_ == 16 && index_unboxed) {
    // Can't use TIMES_16 on X86, so instead pre-shift the value to reduce the
    // scaling needed in the leaq instruction.
    __ SmiTag(start_reg);
    index_unboxed = false;
  } else if (!index_unboxed) {
    __ ExtendNonNegativeSmi(start_reg);
  }
  auto const scale = ToScaleFactor(element_size_, index_unboxed);
  __ leaq(array_reg, compiler::Address(array_reg, start_reg, scale, offset));
}

LocationSummary* MoveArgumentInstr::MakeLocationSummary(Zone* zone,
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

void MoveArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());

  const Location value = locs()->in(0);
  const compiler::Address dst(RSP, sp_relative_index() * kWordSize);
  if (value.IsRegister()) {
    __ movq(dst, value.reg());
  } else if (value.IsConstant()) {
    __ StoreObject(dst, value.constant());
  } else if (value.IsFpuRegister()) {
    __ movsd(dst, value.fpu_reg());
  } else {
    ASSERT(value.IsStackSlot());
    __ MoveMemoryToMemory(dst, LocationToStackSlotAddress(value));
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

// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (locs()->in(0).IsRegister()) {
    const Register result = locs()->in(0).reg();
    ASSERT(result == CallingConventions::kReturnReg);
  } else if (locs()->in(0).IsPairLocation()) {
    const Register result_lo = locs()->in(0).AsPairLocation()->At(0).reg();
    const Register result_hi = locs()->in(0).AsPairLocation()->At(1).reg();
    ASSERT(result_lo == CallingConventions::kReturnReg);
    ASSERT(result_hi == CallingConventions::kSecondReturnReg);
  } else {
    ASSERT(locs()->in(0).IsFpuRegister());
    const FpuRegister result = locs()->in(0).fpu_reg();
    ASSERT(result == CallingConventions::kReturnFpuReg);
  }

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

  // The trampoline that called us will enter the safepoint on our behalf.
  __ TransitionGeneratedToNative(vm_tag_reg, old_exit_frame_reg,
                                 old_exit_through_ffi_reg,
                                 /*enter_safepoint=*/false);

  // Restore C++ ABI callee-saved registers.
  __ PopRegisters(kCalleeSaveRegistersSet);

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
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
  // TODO(dartbug.com/30952) support conversion of Register to corresponding
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
  BranchLabels labels = {nullptr, nullptr, nullptr};
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
                                       Register tmp,
                                       intptr_t pair_index) {
  ASSERT(pair_index == 0);  // No pair representation needed on 64-bit.
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
    if (representation() == kUnboxedFloat) {
      __ LoadSImmediate(destination.fpu_reg(), Double::Cast(value_).value());
    } else {
      ASSERT(representation() == kUnboxedDouble);
      __ LoadDImmediate(destination.fpu_reg(), Double::Cast(value_).value());
    }
  } else if (destination.IsDoubleStackSlot()) {
    __ LoadDImmediate(FpuTMP, Double::Cast(value_).value());
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
  // not guaranteed to be preserved by the ABI.
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

void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->always_calls());

  auto object_store = compiler->isolate_group()->object_store();
  const auto& assert_boolean_stub =
      Code::ZoneHandle(compiler->zone(), object_store->assert_boolean_stub());

  compiler::Label done;
  __ testq(
      AssertBooleanABI::kObjectReg,
      compiler::Immediate(compiler::target::ObjectAlignment::kBoolVsNullMask));
  __ j(NOT_ZERO, &done, compiler::Assembler::kNearJump);
  compiler->GenerateStubCall(source(), assert_boolean_stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
  __ Bind(&done);
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
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid ||
      operation_cid() == kIntegerCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (is_null_aware()) {
      locs->set_in(0, Location::RequiresRegister());
      locs->set_in(1, Location::RequiresRegister());
    } else {
      locs->set_in(0, LocationRegisterOrConstant(left()));
      // Only one input can be a constant operand. The case of two constant
      // operands should be handled by constant propagation.
      // Only right can be a stack slot.
      locs->set_in(1, locs->in(0).IsConstant()
                          ? Location::RequiresRegister()
                          : LocationRegisterOrConstant(right()));
    }
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  UNREACHABLE();
  return nullptr;
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = nullptr) {
  compiler::Label done;
  if (value_is_smi == nullptr) {
    __ LoadImmediate(value_cid_reg, compiler::Immediate(kSmiCid));
  }
  __ testq(value_reg, compiler::Immediate(kSmiTagMask));
  if (value_is_smi == nullptr) {
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

static void EmitBranchOnCondition(
    FlowGraphCompiler* compiler,
    Condition true_condition,
    BranchLabels labels,
    compiler::Assembler::JumpDistance jump_distance =
        compiler::Assembler::kFarJump) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ j(true_condition, labels.true_label, jump_distance);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ j(false_condition, labels.false_label, jump_distance);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ jmp(labels.true_label, jump_distance);
    }
  }
}

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     const LocationSummary& locs,
                                     Token::Kind kind) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);
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
      __ OBJ(cmp)(left.reg(), compiler::Immediate(value));
    } else {
      ASSERT(constant->representation() == kTagged);
      __ CompareObject(left.reg(), right.constant());
    }
  } else if (right.IsStackSlot()) {
    __ OBJ(cmp)(left.reg(), LocationToStackSlotAddress(right));
  } else {
    __ OBJ(cmp)(left.reg(), right.reg());
  }
  return true_condition;
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
      __ cmpq(left.reg(), compiler::Immediate(value));
    } else {
      UNREACHABLE();
    }
  } else if (right.IsStackSlot()) {
    __ cmpq(left.reg(), LocationToStackSlotAddress(right));
  } else {
    __ cmpq(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition EmitNullAwareInt64ComparisonOp(FlowGraphCompiler* compiler,
                                                const LocationSummary& locs,
                                                Token::Kind kind,
                                                BranchLabels labels) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const Register left = locs.in(0).reg();
  const Register right = locs.in(1).reg();
  const Condition true_condition = TokenKindToIntCondition(kind);
  compiler::Label* equal_result =
      (true_condition == EQUAL) ? labels.true_label : labels.false_label;
  compiler::Label* not_equal_result =
      (true_condition == EQUAL) ? labels.false_label : labels.true_label;

  // Check if operands have the same value. If they don't, then they could
  // be equal only if both of them are Mints with the same value.
  __ OBJ(cmp)(left, right);
  __ j(EQUAL, equal_result);
  __ OBJ(mov)(TMP, left);
  __ OBJ (and)(TMP, right);
  __ BranchIfSmi(TMP, not_equal_result);
  __ CompareClassId(left, kMintCid);
  __ j(NOT_EQUAL, not_equal_result);
  __ CompareClassId(right, kMintCid);
  __ j(NOT_EQUAL, not_equal_result);
  __ movq(TMP, compiler::FieldAddress(left, Mint::value_offset()));
  __ cmpq(TMP, compiler::FieldAddress(right, Mint::value_offset()));
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
  if (is_null_aware()) {
    ASSERT(operation_cid() == kMintCid);
    return EmitNullAwareInt64ComparisonOp(compiler, *locs(), kind(), labels);
  }
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind());
  } else if (operation_cid() == kMintCid || operation_cid() == kIntegerCid) {
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

  Register result = locs()->out(0).reg();
  if (true_condition != kInvalidCondition) {
    EmitBranchOnCondition(compiler, true_condition, labels,
                          compiler::Assembler::kNearJump);
  }
  // Note: We use branches instead of setcc or cmov even when the branch labels
  // are otherwise unused, as this runs faster for the x86 processors tested on
  // our benchmarking server.
  compiler::Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ jmp(&done, compiler::Assembler::kNearJump);
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
    const int64_t imm = Smi::RawValue(Smi::Cast(right.constant()).Value());
    __ TestImmediate(left_reg, compiler::Immediate(imm),
                     compiler::kObjectBytes);
  } else {
    __ OBJ(test)(left_reg, right.reg());
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
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids)
          : nullptr;

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
  if (deopt == nullptr) {
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
  return nullptr;
}

Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind());
  } else if (operation_cid() == kMintCid) {
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

  // Pass a pointer to the first argument in R13 (we avoid using RAX here to
  // simplify the stub code that will call native code).
  __ leaq(R13, compiler::Address(RSP, (ArgumentCount() - 1) * kWordSize));

  __ LoadImmediate(R10, compiler::Immediate(argc_tag));
  const Code* stub;
  if (link_lazily()) {
    stub = &StubCode::CallBootstrapNative();
    compiler::ExternalLabel label(NativeEntry::LinkNativeCallEntry());
    __ LoadNativeEntry(RBX, &label,
                       compiler::ObjectPoolBuilderEntry::kPatchable);
    compiler->GeneratePatchableCall(source(), *stub,
                                    UntaggedPcDescriptors::kOther, locs());
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
    // We can never lazy-deopt here because natives are never optimized.
    ASSERT(!compiler->is_optimizing());
    compiler->GenerateNonLazyDeoptableStubCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs());
  }
  __ LoadFromOffset(result, RSP, 0);
  compiler->EmitDropArguments(ArgumentCount());  // Drop the arguments.
}

#define R(r) (1 << r)

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  // Use R10 as a temp. register. We can't use RDI, RSI, RDX, R8, R9 as they are
  // argument registers, and R11 is TMP.
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(CallingConventions::kSecondNonArgumentRegister) | R(R10) |
       R(CallingConventions::kFfiAnyNonAbiRegister)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register target_address = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves.
  const Register saved_fp = locs()->temp(0).reg();
  const Register temp = locs()->temp(1).reg();
  // For leaf calls, this holds the SP used to restore the pre-aligned SP after
  // the call.
  // Note: R12 doubles as CODE_REG, which gets clobbered during frame setup in
  // regular calls.
  const Register saved_sp = locs()->temp(2).reg();

  // Ensure these are callee-saved register and are preserved across the call.
  ASSERT(IsCalleeSavedRegister(saved_sp));
  ASSERT(IsCalleeSavedRegister(saved_fp));
  // Other temps don't need to be preserved.

  if (is_leaf_) {
    __ movq(saved_sp, SPREG);
  } else {
    __ movq(saved_fp, FPREG);
    // Make a space to put the return address.
    __ pushq(compiler::Immediate(0));

    // We need to create a dummy "exit frame". It will share the same pool
    // pointer but have a null code object.
    __ LoadObject(CODE_REG, Code::null_object());
    __ set_constant_pool_allowed(false);
    __ EnterDartFrame(0, PP);
  }

  // Reserve space for the arguments that go on the stack (if any), then align.
  intptr_t stack_space = marshaller_.RequiredStackSpaceInBytes();
  __ ReserveAlignedFrameSpace(stack_space);
#if defined(USING_MEMORY_SANITIZER)
  {
    RegisterSet kVolatileRegisterSet(CallingConventions::kVolatileCpuRegisters,
                                     CallingConventions::kVolatileXmmRegisters);
    __ movq(temp, RSP);
    __ PushRegisters(kVolatileRegisterSet);

    // Outgoing arguments passed on the stack to the foreign function.
    __ MsanUnpoison(temp, stack_space);

    // Incoming Dart arguments to this trampoline are potentially used as local
    // handles.
    __ MsanUnpoison(is_leaf_ ? FPREG : saved_fp,
                    (kParamEndSlotFromFp + InputCount()) * kWordSize);

    // Outgoing arguments passed by register to the foreign function.
    __ LoadImmediate(CallingConventions::kArg1Reg, InputCount());
    __ CallCFunction(compiler::Address(
        THR, kMsanUnpoisonParamRuntimeEntry.OffsetFromThread()));

    __ PopRegisters(kVolatileRegisterSet);
  }
#endif

  if (is_leaf_) {
    EmitParamMoves(compiler, FPREG, saved_fp, TMP);
  } else {
    EmitParamMoves(compiler, saved_fp, saved_sp, TMP);
  }

  if (compiler::Assembler::EmittingComments()) {
    __ Comment(is_leaf_ ? "Leaf Call" : "Call");
  }

  if (is_leaf_) {
#if !defined(PRODUCT)
    // Set the thread object's top_exit_frame_info and VMTag to enable the
    // profiler to determine that thread is no longer executing Dart code.
    __ movq(compiler::Address(
                THR, compiler::target::Thread::top_exit_frame_info_offset()),
            FPREG);
    __ movq(compiler::Assembler::VMTagAddress(), target_address);
#endif

    if (marshaller_.contains_varargs() &&
        CallingConventions::kVarArgFpuRegisterCount != kNoRegister) {
      // TODO(http://dartbug.com/38578): Use the number of used FPU registers.
      __ LoadImmediate(CallingConventions::kVarArgFpuRegisterCount,
                       CallingConventions::kFpuArgumentRegisters);
    }
    __ CallCFunction(target_address, /*restore_rsp=*/true);

#if !defined(PRODUCT)
    __ movq(compiler::Assembler::VMTagAddress(),
            compiler::Immediate(compiler::target::Thread::vm_tag_dart_id()));
    __ movq(compiler::Address(
                THR, compiler::target::Thread::top_exit_frame_info_offset()),
            compiler::Immediate(0));
#endif
  } else {
    // We need to copy a dummy return address up into the dummy stack frame so
    // the stack walker will know which safepoint to use. RIP points to the
    // *next* instruction, so 'AddressRIPRelative' loads the address of the
    // following 'movq'.
    __ leaq(temp, compiler::Address::AddressRIPRelative(0));
    compiler->EmitCallsiteMetadata(InstructionSource(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());
    __ movq(compiler::Address(FPREG, kSavedCallerPcSlotFromFp * kWordSize),
            temp);

    if (CanExecuteGeneratedCodeInSafepoint()) {
      // Update information in the thread object and enter a safepoint.
      __ movq(temp, compiler::Immediate(
                        compiler::target::Thread::exit_through_ffi()));

      __ TransitionGeneratedToNative(target_address, FPREG, temp,
                                     /*enter_safepoint=*/true);

      if (marshaller_.contains_varargs() &&
          CallingConventions::kVarArgFpuRegisterCount != kNoRegister) {
        __ LoadImmediate(CallingConventions::kVarArgFpuRegisterCount, 8);
      }
      __ CallCFunction(target_address, /*restore_rsp=*/true);

      // Update information in the thread object and leave the safepoint.
      __ TransitionNativeToGenerated(/*leave_safepoint=*/true);
    } else {
      // We cannot trust that this code will be executable within a safepoint.
      // Therefore we delegate the responsibility of entering/exiting the
      // safepoint to a stub which is in the VM isolate's heap, which will never
      // lose execute permission.
      __ movq(temp,
              compiler::Address(
                  THR, compiler::target::Thread::
                           call_native_through_safepoint_entry_point_offset()));

      // Calls RBX within a safepoint. RBX and R12 are clobbered.
      __ movq(RBX, target_address);
      if (marshaller_.contains_varargs() &&
          CallingConventions::kVarArgFpuRegisterCount != kNoRegister) {
        __ LoadImmediate(CallingConventions::kVarArgFpuRegisterCount, 8);
      }
      __ call(temp);
    }

    if (marshaller_.IsHandle(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      compiler::Label not_error;
      __ movq(temp,
              compiler::Address(CallingConventions::kReturnReg,
                                compiler::target::LocalHandle::ptr_offset()));
      __ BranchIfSmi(temp, &not_error);
      __ LoadClassId(temp, temp);
      __ RangeCheck(temp, kNoRegister, kFirstErrorCid, kLastErrorCid,
                    compiler::AssemblerBase::kIfNotInRange, &not_error);

      // Slow path, use the stub to propagate error, to save on code-size.
      __ Comment("Slow path: call Dart_PropagateError through stub.");
      __ movq(temp,
              compiler::Address(
                  THR, compiler::target::Thread::
                           call_native_through_safepoint_entry_point_offset()));
      __ movq(RBX, compiler::Address(
                       THR, kPropagateErrorRuntimeEntry.OffsetFromThread()));
      __ movq(CallingConventions::kArg1Reg, CallingConventions::kReturnReg);
      __ call(temp);
#if defined(DEBUG)
      // We should never return with normal controlflow from this.
      __ int3();
#endif

      __ Bind(&not_error);
    }
  }

  // Pass the `saved_fp` reg. as a temp to clobber since we're done with it.
  EmitReturnMoves(compiler, temp, saved_fp);

  if (is_leaf_) {
    // Restore the pre-aligned SP.
    __ movq(SPREG, saved_sp);
  } else {
    __ LeaveDartFrame();
    // Restore the global object pool after returning from runtime (old space is
    // moving, so the GOP could have been relocated).
    if (FLAG_precompiled_mode) {
      __ movq(PP, compiler::Address(THR, Thread::global_object_pool_offset()));
    }
    __ set_constant_pool_allowed(true);

    // Instead of returning to the "fake" return address, we just pop it.
    __ popq(temp);
  }
}

// Keep in sync with NativeReturnInstr::EmitNativeCode.
void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));

  // Create a dummy frame holding the pushed arguments. This simplifies
  // NativeReturnInstr::EmitNativeCode.
  __ EnterFrame(0);

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save the argument registers, in reverse order.
  SaveArguments(compiler);

  // Enter the entry frame. Push a dummy return address for consistency with
  // EnterFrame on ARM(64). NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  __ PushImmediate(compiler::Immediate(0));
  __ EnterFrame(0);

  // Save a space for the code object.
  __ PushImmediate(compiler::Immediate(0));

  // InvokeDartCodeStub saves the arguments descriptor here. We don't have one,
  // but we need to follow the same frame layout for the stack walker.
  __ PushImmediate(compiler::Immediate(0));

  // Save ABI callee-saved registers.
  __ PushRegisters(kCalleeSaveRegistersSet);

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

  // The callback trampoline (caller) has already left the safepoint for us.
  __ TransitionNativeToGenerated(/*exit_safepoint=*/false);

  // Load the code object.
  const Function& target_function = marshaller_.dart_signature();
  const intptr_t callback_id = target_function.FfiCallbackId();
  __ movq(RAX, compiler::Address(
                   THR, compiler::target::Thread::isolate_group_offset()));
  __ movq(RAX, compiler::Address(
                   RAX, compiler::target::IsolateGroup::object_store_offset()));
  __ movq(RAX,
          compiler::Address(
              RAX, compiler::target::ObjectStore::ffi_callback_code_offset()));
  __ LoadCompressed(
      RAX, compiler::FieldAddress(
               RAX, compiler::target::GrowableObjectArray::data_offset()));
  __ LoadCompressed(
      CODE_REG,
      compiler::FieldAddress(
          RAX, compiler::target::Array::data_offset() +
                   callback_id * compiler::target::kCompressedWordSize));

  // Put the code object in the reserved slot.
  __ movq(compiler::Address(FPREG,
                            kPcMarkerSlotFromFp * compiler::target::kWordSize),
          CODE_REG);

  if (FLAG_precompiled_mode) {
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

#define R(r) (1 << r)

LocationSummary* CCallInstr::MakeLocationSummary(Zone* zone,
                                                 bool is_optimizing) const {
  constexpr Register saved_fp = CallingConventions::kSecondNonArgumentRegister;
  return MakeLocationSummaryInternal(zone, (R(saved_fp)));
}

#undef R

void CCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = locs()->temp(0).reg();
  const Register temp0 = TMP;

  // TODO(http://dartbug.com/47778): If we knew whether the stack was aligned
  // at this point, we could omit having a frame.
  __ MoveRegister(saved_fp, FPREG);

  const intptr_t frame_space = native_calling_convention_.StackTopInBytes();
  __ EnterCFrame(frame_space);

  EmitParamMoves(compiler, saved_fp, temp0);
  const Register target_address = locs()->in(TargetAddressIndex()).reg();
  __ CallCFunction(target_address);

  __ LeaveCFrame();
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

  // Note: we don't bother to ensure char_code is a writable input because any
  // other instructions using it must also not rely on the upper bits when
  // compressed.
  __ ExtendNonNegativeSmi(char_code);
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
  __ LoadCompressedSmi(result,
                       compiler::FieldAddress(str, String::length_offset()));
  __ cmpq(result, compiler::Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, compiler::Assembler::kNearJump);
  __ movq(result, compiler::Immediate(Smi::RawValue(-1)));
  __ jmp(&done);
  __ Bind(&is_one);
  __ movzxb(result, compiler::FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
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

  const intptr_t kSizeMask = 0x03;
  const intptr_t kFlagsMask = 0x3C;

  compiler::Label scan_ascii, ascii_loop, ascii_loop_in, nonascii_loop;
  compiler::Label rest, rest_loop, rest_loop_in, done;

  // Address of input bytes.
  __ movq(bytes_reg,
          compiler::FieldAddress(bytes_reg,
                                 compiler::target::PointerBase::data_offset()));

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
  if (scan_flags_field_.is_compressed() && !IsScanFlagsUnboxed()) {
    __ OBJ(or)(compiler::FieldAddress(decoder_reg, scan_flags_field_offset),
               flags_reg);
  } else {
    __ orq(compiler::FieldAddress(decoder_reg, scan_flags_field_offset),
           flags_reg);
  }
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

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // For tagged index with index_scale=1 as well as untagged index with
  // index_scale=16 we need a writable register due to addressing mode
  // restrictions on X64.
  const bool need_writable_index_register =
      (index_scale() == 1 && !index_unboxed_) ||
      (index_scale() == 16 && index_unboxed_);
  locs->set_in(
      1, CanBeImmediateIndex(index(), class_id())
             ? Location::Constant(index()->definition()->AsConstant())
             : (need_writable_index_register ? Location::WritableRegister()
                                             : Location::RequiresRegister()));
  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
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

  bool index_unboxed = index_unboxed_;
  if (index.IsRegister()) {
    if (index_scale_ == 1 && !index_unboxed) {
      __ SmiUntag(index.reg());
      index_unboxed = true;
    } else if (index_scale_ == 16 && index_unboxed) {
      // X64 does not support addressing mode using TIMES_16.
      __ SmiTag(index.reg());
      index_unboxed = false;
    } else if (!index_unboxed) {
      // Note: we don't bother to ensure index is a writable input because any
      // other instructions using it must also not rely on the upper bits
      // when compressed.
      __ ExtendNonNegativeSmi(index.reg());
    }
  } else {
    ASSERT(index.IsConstant());
  }

  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale_,
                               index_unboxed, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale_, array,
                               Smi::Cast(index.constant()).Value());

  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
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
             (class_id() == kTypeArgumentsCid) || (class_id() == kRecordCid));
      __ LoadCompressed(result, element_address);
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
  const Register index = locs()->in(1).reg();

  bool index_unboxed = false;
  if ((index_scale() == 1)) {
    __ SmiUntag(index);
    index_unboxed = true;
  } else {
    __ ExtendNonNegativeSmi(index);
  }
  compiler::Address element_address =
      compiler::Assembler::ElementAddressForRegIndex(
          IsExternal(), class_id(), index_scale(), index_unboxed, str, index);

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
      ASSERT(can_pack_into_smi());
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
      ASSERT(can_pack_into_smi());
      __ SmiTag(result);
      break;
    default:
      UNREACHABLE();
      break;
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
  // index_scale=16 we need a writable register due to addressing mode
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
      return nullptr;
  }
  return locs;
}

void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  bool index_unboxed = index_unboxed_;
  if (index.IsRegister()) {
    if (index_scale_ == 1 && !index_unboxed) {
      __ SmiUntag(index.reg());
      index_unboxed = true;
    } else if (index_scale_ == 16 && index_unboxed) {
      // X64 does not support addressing mode using TIMES_16.
      __ SmiTag(index.reg());
      index_unboxed = false;
    } else if (!index_unboxed) {
      // Note: we don't bother to ensure index is a writable input because any
      // other instructions using it must also not rely on the upper bits
      // when compressed.
      __ ExtendNonNegativeSmi(index.reg());
    }
  } else {
    ASSERT(index.IsConstant());
  }

  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale_,
                               index_unboxed, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale_, array,
                               Smi::Cast(index.constant()).Value());

  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        Register value = locs()->in(2).reg();
        Register slot = locs()->temp(0).reg();
        __ leaq(slot, element_address);
        __ StoreCompressedIntoArray(array, slot, value, CanValueBeSmi());
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreCompressedIntoObjectNoBarrier(array, element_address, constant);
      } else {
        Register value = locs()->in(2).reg();
        __ StoreCompressedIntoObjectNoBarrier(array, element_address, value);
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
        __ movb(element_address, ByteRegisterOf(locs()->in(2).reg()));
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
        const Register storedValueReg = locs()->in(2).reg();
        compiler::Label store_value, store_0xff;
        __ CompareImmediate(storedValueReg, compiler::Immediate(0xFF));
        __ j(BELOW_EQUAL, &store_value, compiler::Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorq(storedValueReg, storedValueReg);
        __ jmp(&store_value, compiler::Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ LoadImmediate(storedValueReg, compiler::Immediate(0xFF));
        __ Bind(&store_value);
        __ movb(element_address, ByteRegisterOf(storedValueReg));
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

#if defined(USING_MEMORY_SANITIZER)
  RegisterSet kVolatileRegisterSet(CallingConventions::kVolatileCpuRegisters,
                                   CallingConventions::kVolatileXmmRegisters);
  __ PushRegisters(kVolatileRegisterSet);
  const Register base = CallingConventions::kArg1Reg;
  __ leaq(base, element_address);
  intptr_t length_in_bytes;
  if (IsTypedDataBaseClassId(class_id_)) {
    length_in_bytes = compiler::TypedDataElementSizeInBytes(class_id_);
  } else {
    switch (class_id_) {
      case kArrayCid:
        length_in_bytes = compiler::target::kWordSize;
        break;
      case kOneByteStringCid:
        length_in_bytes = 1;
        break;
      case kTwoByteStringCid:
        length_in_bytes = 2;
        break;
      default:
        FATAL("Unknown cid: %" Pd, class_id_);
    }
  }
  __ MsanUnpoison(base, length_in_bytes);
  __ PopRegisters(kVolatileRegisterSet);
#endif
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
  ASSERT(compiler::target::UntaggedObject::kClassIdTagSize == 20);
  ASSERT(sizeof(UntaggedField::guarded_cid_) == 4);
  ASSERT(sizeof(UntaggedField::is_nullable_) == 4);

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

  compiler::Label* deopt = nullptr;
  if (compiler->is_optimizing()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField);
  }

  compiler::Label* fail = (deopt != nullptr) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    compiler::FieldAddress field_cid_operand(field_reg,
                                             Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);

      __ cmpl(value_cid_reg, field_cid_operand);
      __ j(EQUAL, &ok);
      __ cmpl(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      __ cmpl(field_nullability_operand, compiler::Immediate(value_cid));
    } else {
      __ cmpl(field_cid_operand, compiler::Immediate(value_cid));
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
      __ cmpl(field_cid_operand, compiler::Immediate(kIllegalCid));
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        __ movl(field_cid_operand, value_cid_reg);
        __ movl(field_nullability_operand, value_cid_reg);
      } else {
        ASSERT(field_reg != kNoRegister);
        __ movl(field_cid_operand, compiler::Immediate(value_cid));
        __ movl(field_nullability_operand, compiler::Immediate(value_cid));
      }

      __ jmp(&ok);
    }

    if (deopt == nullptr) {
      __ Bind(fail);

      __ cmpl(compiler::FieldAddress(field_reg, Field::guarded_cid_offset()),
              compiler::Immediate(kDynamicCid));
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ jmp(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != nullptr);

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
      // This would normally be caught by Canonicalize, but RemoveRedefinitions
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
          : nullptr;

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
    __ LoadCompressedSmi(
        length_reg,
        compiler::FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ cmpq(offset_reg, compiler::Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ OBJ(cmp)(length_reg,
                compiler::Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == nullptr) {
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
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
          : nullptr;

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
  __ movq(temp, compiler::FieldAddress(value_reg, temp,
                                       TIMES_COMPRESSED_WORD_SIZE, 0));
  __ CompareObject(
      temp,
      TypeArguments::ZoneHandle(
          compiler->zone(), Type::Cast(AbstractType::Handle(field().type()))
                                .GetInstanceTypeArguments(compiler->thread())));
  if (deopt != nullptr) {
    __ j(NOT_EQUAL, deopt);
  } else {
    __ j(EQUAL, &ok);

    __ Bind(&call_runtime);
    __ PushObject(original);
    __ pushq(value_reg);
    ASSERT(!compiler->is_optimizing());  // No deopt info needed.
    __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
    __ Drop(2);
  }

  __ Bind(&ok);
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

  compiler->GenerateInstanceOf(source(), deopt_id(), env(), type(), locs());
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
  locs->set_in(kTypeArgumentsPos,
               Location::RegisterLocation(AllocateArrayABI::kTypeArgumentsReg));
  locs->set_in(kLengthPos,
               Location::RegisterLocation(AllocateArrayABI::kLengthReg));
  locs->set_out(0, Location::RegisterLocation(AllocateArrayABI::kResultReg));
  return locs;
}

// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  compiler::Label* slow_path,
                                  compiler::Label* done) {
  const int kInlineArraySize = 12;  // Same as kInlineInstanceSize.
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      compiler::Assembler::kFarJump,
                      AllocateArrayABI::kResultReg,  // instance
                      RCX,                           // end address
                      R13);                          // temp

  // RAX: new object start as a tagged pointer.
  // Store the type argument field.
  __ StoreCompressedIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::type_arguments_offset()),
      AllocateArrayABI::kTypeArgumentsReg);

  // Set the length field.
  __ StoreCompressedIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::length_offset()),
      AllocateArrayABI::kLengthReg);

  // Initialize all array elements to raw_null.
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(UntaggedArray);
    __ LoadObject(R12, Object::null_object());
    __ leaq(RDI, compiler::FieldAddress(AllocateArrayABI::kResultReg,
                                        sizeof(UntaggedArray)));
    if (array_size < (kInlineArraySize * kCompressedWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ StoreCompressedIntoObjectNoBarrier(
            AllocateArrayABI::kResultReg,
            compiler::Address(RDI, current_offset), R12);
        current_offset += kCompressedWordSize;
      }
    } else {
      compiler::Label init_loop;
      __ Bind(&init_loop);
      __ StoreCompressedIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                            compiler::Address(RDI, 0), R12);
      __ addq(RDI, compiler::Immediate(kCompressedWordSize));
      __ cmpq(RDI, RCX);
      __ j(BELOW, &init_loop, compiler::Assembler::kNearJump);
    }
  }
  __ jmp(done, compiler::Assembler::kNearJump);
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

    auto slow_path_env = compiler->SlowPathEnvironmentFor(
        instruction(), /*num_slow_path_args=*/0);
    ASSERT(slow_path_env != nullptr);

    auto object_store = compiler->isolate_group()->object_store();
    const auto& allocate_context_stub = Code::ZoneHandle(
        compiler->zone(), object_store->allocate_context_stub());

    __ LoadImmediate(
        R10, compiler::Immediate(instruction()->num_context_variables()));
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               UntaggedPcDescriptors::kOther, locs,
                               instruction()->deopt_id(), slow_path_env);
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

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                        compiler::Assembler::kFarJump,
                        result,  // instance
                        temp,    // end address
                        locs()->temp(1).reg());

    // Setup up number of context variables field.
    __ movq(compiler::FieldAddress(result, Context::num_variables_offset()),
            compiler::Immediate(num_context_variables()));
  } else {
    __ Jump(slow_path->entry_label());
  }

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

  auto object_store = compiler->isolate_group()->object_store();
  const auto& allocate_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_context_stub());

  __ LoadImmediate(R10, compiler::Immediate(num_context_variables()));
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
  locs->set_in(0, Location::RegisterLocation(R9));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R9);
  ASSERT(locs()->out(0).reg() == RAX);

  auto object_store = compiler->isolate_group()->object_store();
  const auto& clone_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->clone_context_stub());
  compiler->GenerateStubCall(source(), clone_context_stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
}

LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}

void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(this);
  if (!FLAG_precompiled_mode) {
    // On lazy deoptimization we patch the optimized code here to enter the
    // deoptimization stub.
    const intptr_t deopt_id = DeoptId::ToDeoptAfter(GetDeoptId());
    if (compiler->is_optimizing()) {
      compiler->AddDeoptIndexAtCall(deopt_id, env());
    } else {
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, deopt_id,
                                     InstructionSource());
    }
  }
  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
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
    if (compiler->isolate_group()->use_osr() && osr_entry_label()->IsLinked()) {
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
    ASSERT(compiler->pending_deoptimization_env_ == nullptr);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    if (using_shared_stub) {
      const uword entry_point_offset =
          Thread::stack_overflow_shared_stub_entry_point_offset(
              instruction()->locs()->live_registers()->FpuRegisterCount() > 0);
      __ call(compiler::Address(THR, entry_point_offset));
      compiler->RecordSafepoint(instruction()->locs(), kNumSlowPathArgs);
      compiler->RecordCatchEntryMoves(env);
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOther,
                                     instruction()->deopt_id(),
                                     instruction()->source());
    } else {
      __ CallRuntime(kInterruptOrStackOverflowRuntimeEntry, kNumSlowPathArgs);
      compiler->EmitCallsiteMetadata(
          instruction()->source(), instruction()->deopt_id(),
          UntaggedPcDescriptors::kOther, instruction()->locs(), env);
    }

    if (compiler->isolate_group()->use_osr() && !compiler->is_optimizing() &&
        instruction()->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOsrEntry,
                                     instruction()->deopt_id(),
                                     InstructionSource());
    }
    compiler->pending_deoptimization_env_ = nullptr;
    if (!using_shared_stub) {
      compiler->RestoreLiveRegisters(instruction()->locs());
    }
    __ jmp(exit_label());
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

  Register temp = locs()->temp(0).reg();
  // Generate stack overflow check.
  __ cmpq(RSP, compiler::Address(THR, Thread::stack_limit_offset()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
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
          : nullptr;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // shlq operation masks the count to 6 bits.
#if !defined(DART_COMPRESSED_POINTERS)
    const intptr_t kCountLimit = 0x3F;
#else
    const intptr_t kCountLimit = 0x1F;
#endif
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      if (value == 1) {
        // Use overflow flag.
        __ OBJ(shl)(left, compiler::Immediate(1));
        __ j(OVERFLOW, deopt);
        return;
      }
      // Check for overflow.
      Register temp = locs.temp(0).reg();
      __ OBJ(mov)(temp, left);
      __ OBJ(shl)(left, compiler::Immediate(value));
      __ OBJ(sar)(left, compiler::Immediate(value));
      __ OBJ(cmp)(left, temp);
      __ j(NOT_EQUAL, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ OBJ(shl)(left, compiler::Immediate(value));
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
        __ CompareImmediate(right, compiler::Immediate(0),
                            compiler::kObjectBytes);
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ CompareObject(right, Smi::ZoneHandle(Smi::New(max_right)));
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ OBJ(shl)(left, right);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  ASSERT(right == RCX);  // Count must be in RCX
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == nullptr) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareImmediate(right, compiler::Immediate(0),
                            compiler::kObjectBytes);
        __ j(NEGATIVE, deopt);
      }
      compiler::Label done, is_not_zero;
      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ j(BELOW, &is_not_zero, compiler::Assembler::kNearJump);
      __ xorq(left, left);
      __ jmp(&done, compiler::Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(right);
      __ OBJ(shl)(left, right);
      __ Bind(&done);
    } else {
      __ SmiUntag(right);
      __ OBJ(shl)(left, right);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ j(ABOVE_EQUAL, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ OBJ(mov)(temp, left);
    __ SmiUntag(right);
    // Overflow test (preserve temp and right);
    __ OBJ(shl)(left, right);
    __ OBJ(sar)(left, right);
    __ OBJ(cmp)(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ OBJ(shl)(left, right);
    ASSERT(!shift_left->is_truncating());
  }
}

static bool CanBeImmediate(const Object& constant) {
  return constant.IsSmi() &&
         compiler::Immediate(Smi::RawValue(Smi::Cast(constant).Value()))
             .is_int32();
}

static bool IsSmiValue(const Object& constant, intptr_t value) {
  return constant.IsSmi() && (Smi::Cast(constant).Value() == value);
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;

  ConstantInstr* right_constant = right()->definition()->AsConstant();
  if ((right_constant != nullptr) && (op_kind() != Token::kTRUNCDIV) &&
      (op_kind() != Token::kSHL) &&
#if defined(DART_COMPRESSED_POINTERS)
      (op_kind() != Token::kUSHR) &&
#endif
      (op_kind() != Token::kMUL) && (op_kind() != Token::kMOD) &&
      CanBeImmediate(right_constant->value())) {
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
  } else if ((op_kind() == Token::kSHR)
#if !defined(DART_COMPRESSED_POINTERS)
             || (op_kind() == Token::kUSHR)
#endif  // !defined(DART_COMPRESSED_POINTERS)
  ) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
#if defined(DART_COMPRESSED_POINTERS)
  } else if (op_kind() == Token::kUSHR) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    if ((right_constant != nullptr) &&
        CanBeImmediate(right_constant->value())) {
      summary->set_in(1, Location::Constant(right_constant));
    } else {
      summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), RCX));
    }
    summary->set_out(0, Location::SameAsFirstInput());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
#endif  // defined(DART_COMPRESSED_POINTERS)
  } else if (op_kind() == Token::kSHL) {
    // Shift-by-1 overflow checking can use flags, otherwise we need a temp.
    const bool shiftBy1 =
        (right_constant != nullptr) && IsSmiValue(right_constant->value(), 1);
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
    if (constant != nullptr) {
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
  compiler::Label* deopt = nullptr;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int64_t imm = Smi::RawValue(Smi::Cast(constant).Value());
    switch (op_kind()) {
      case Token::kADD: {
        __ AddImmediate(left, compiler::Immediate(imm), compiler::kObjectBytes);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ SubImmediate(left, compiler::Immediate(imm), compiler::kObjectBytes);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ MulImmediate(left, compiler::Immediate(value),
                        compiler::kObjectBytes);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
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
#if !defined(DART_COMPRESSED_POINTERS)
        __ sarq(temp, compiler::Immediate(63));
#else
        __ sarl(temp, compiler::Immediate(31));
#endif
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
#if !defined(DART_COMPRESSED_POINTERS)
        __ shrq(temp, compiler::Immediate(64 - shift_count));
#else
        __ shrl(temp, compiler::Immediate(32 - shift_count));
#endif
        __ OBJ(add)(left, temp);
        ASSERT(shift_count > 0);
        __ OBJ(sar)(left, compiler::Immediate(shift_count));
        if (value < 0) {
          __ OBJ(neg)(left);
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
        // sarq/l operation masks the count to 6/5 bits.
#if !defined(DART_COMPRESSED_POINTERS)
        const intptr_t kCountLimit = 0x3F;
#else
        const intptr_t kCountLimit = 0x1F;
#endif
        const intptr_t value = Smi::Cast(constant).Value();
        __ OBJ(sar)(left, compiler::Immediate(Utils::Minimum(
                              value + kSmiTagSize, kCountLimit)));
        __ SmiTag(left);
        break;
      }

      case Token::kUSHR: {
        // shrq operation masks the count to 6 bits, but
        // unsigned shifts by >= kBitsPerInt64 are eliminated by
        // BinaryIntegerOpInstr::Canonicalize.
        const intptr_t kCountLimit = 0x3F;
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT((value >= 0) && (value <= kCountLimit));
        __ SmiUntagAndSignExtend(left);
        __ shrq(left, compiler::Immediate(value));
        __ shlq(left, compiler::Immediate(1));  // SmiTag, keep hi bits.
        if (deopt != nullptr) {
          __ j(OVERFLOW, deopt);
#if defined(DART_COMPRESSED_POINTERS)
          const Register temp = locs()->temp(0).reg();
          __ movsxd(temp, left);
          __ cmpq(temp, left);
          __ j(NOT_EQUAL, deopt);
#endif  // defined(DART_COMPRESSED_POINTERS)
        }
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
        __ OBJ(add)(left, right);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ OBJ(sub)(left, right);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(left);
        __ OBJ(imul)(left, right);
        if (deopt != nullptr) __ j(OVERFLOW, deopt);
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
      __ OBJ(add)(left, right);
      if (deopt != nullptr) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kSUB: {
      __ OBJ(sub)(left, right);
      if (deopt != nullptr) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ OBJ(imul)(left, right);
      if (deopt != nullptr) __ j(OVERFLOW, deopt);
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
        __ OBJ(test)(right, right);
        __ j(ZERO, deopt);
      }
#if !defined(DART_COMPRESSED_POINTERS)
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
#else
      // Both operands are 31bit smis. Divide using 32bit idiv.
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ cdq();
      __ idivl(right);

      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ cmpl(result, compiler::Immediate(0x40000000));
        __ j(EQUAL, deopt);
      }
      __ movsxd(result, result);
#endif
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
        __ OBJ(test)(right, right);
        __ j(ZERO, deopt);
      }
#if !defined(DART_COMPRESSED_POINTERS)
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
#endif
      // Both operands are 31bit smis. Divide using 32bit idiv.
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movq(RAX, RDX);
      __ cdq();
      __ idivl(right);
      __ movsxd(result, result);
#if !defined(DART_COMPRESSED_POINTERS)
      __ jmp(&div_done);

      // Divide using 64bit idiv.
      __ Bind(&not_32bit);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movq(RAX, RDX);
      __ cqo();         // Sign extend RAX -> RDX:RAX.
      __ idivq(right);  //  RAX: quotient, RDX: remainder.
      __ Bind(&div_done);
#endif
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      compiler::Label all_done;
      __ OBJ(cmp)(result, compiler::Immediate(0));
      __ j(GREATER_EQUAL, &all_done, compiler::Assembler::kNearJump);
      // Result is negative, adjust it.
      if (RangeUtils::Overlaps(right_range(), -1, 1)) {
        compiler::Label subtract;
        __ OBJ(cmp)(right, compiler::Immediate(0));
        __ j(LESS, &subtract, compiler::Assembler::kNearJump);
        __ OBJ(add)(result, right);
        __ jmp(&all_done, compiler::Assembler::kNearJump);
        __ Bind(&subtract);
        __ OBJ(sub)(result, right);
      } else if (right_range()->IsPositive()) {
        // Right is positive.
        __ OBJ(add)(result, right);
      } else {
        // Right is negative.
        __ OBJ(sub)(result, right);
      }
      __ Bind(&all_done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, compiler::Immediate(0),
                            compiler::kObjectBytes);
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarq/l operation masks the count to 6/5 bits.
#if !defined(DART_COMPRESSED_POINTERS)
      const intptr_t kCountLimit = 0x3F;
#else
      const intptr_t kCountLimit = 0x1F;
#endif
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ CompareImmediate(right, compiler::Immediate(kCountLimit));
        compiler::Label count_ok;
        __ j(LESS, &count_ok, compiler::Assembler::kNearJump);
        __ LoadImmediate(right, compiler::Immediate(kCountLimit));
        __ Bind(&count_ok);
      }
      ASSERT(right == RCX);  // Count must be in RCX
      __ SmiUntag(left);
      __ OBJ(sar)(left, right);
      __ SmiTag(left);
      break;
    }
    case Token::kUSHR: {
      if (deopt != nullptr) {
        __ CompareImmediate(right, compiler::Immediate(0),
                            compiler::kObjectBytes);
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // shrq operation masks the count to 6 bits.
      const intptr_t kCountLimit = 0x3F;
      COMPILE_ASSERT(kCountLimit + 1 == kBitsPerInt64);
      compiler::Label done;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ CompareImmediate(right, compiler::Immediate(kCountLimit),
                            compiler::kObjectBytes);
        compiler::Label count_ok;
        __ j(LESS_EQUAL, &count_ok, compiler::Assembler::kNearJump);
        __ xorq(left, left);
        __ jmp(&done, compiler::Assembler::kNearJump);
        __ Bind(&count_ok);
      }
      ASSERT(right == RCX);  // Count must be in RCX
      __ SmiUntagAndSignExtend(left);
      __ shrq(left, right);
      __ shlq(left, compiler::Immediate(1));  // SmiTag, keep hi bits.
      if (deopt != nullptr) {
        __ j(OVERFLOW, deopt);
#if defined(DART_COMPRESSED_POINTERS)
        const Register temp = locs()->temp(0).reg();
        __ movsxd(temp, left);
        __ cmpq(temp, left);
        __ j(NOT_EQUAL, deopt);
#endif  // defined(DART_COMPRESSED_POINTERS)
      }
      __ Bind(&done);
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
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp);
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
#if !defined(DART_COMPRESSED_POINTERS)
    summary->set_out(0, Location::SameAsFirstInput());
#else
    summary->set_out(0, Location::RequiresRegister());
#endif
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
    case kUnboxedInt32: {
      const Register result = locs()->out(0).reg();
      __ SmiUntag(result, box);
      break;
    }
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ SmiUntagAndSignExtend(result, box);
      break;
    }
    case kUnboxedDouble: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(box);
      __ OBJ(cvtsi2sd)(result, box);
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
          : nullptr;
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
#if !defined(DART_COMPRESSED_POINTERS)
    // Optimistically untag value.
    __ SmiUntag(value);
    __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
    // Undo untagging by multiplying value by 2.
    // [reg + reg + disp8] has a shorter encoding than [reg*2 + disp32]
    __ movq(value,
            compiler::Address(value, value, TIMES_1, Mint::value_offset()));
#else
    // Cannot speculatively untag because it erases the upper bits needed to
    // dereference when it is a Mint.
    compiler::Label not_smi;
    __ BranchIfNotSmi(value, &not_smi, compiler::Assembler::kNearJump);
    __ SmiUntagAndSignExtend(value);
    __ jmp(&done, compiler::Assembler::kNearJump);
    __ Bind(&not_smi);
    __ movq(value, compiler::FieldAddress(value, Mint::value_offset()));
#endif
    __ Bind(&done);
    return;
  } else {
    compiler::Label done;
#if !defined(DART_COMPRESSED_POINTERS)
    // Optimistically untag value.
    __ SmiUntagOrCheckClass(value, kMintCid, &done);
    __ j(NOT_EQUAL, deopt);
    // Undo untagging by multiplying value by 2.
    // [reg + reg + disp8] has a shorter encoding than [reg*2 + disp32]
    __ movq(value,
            compiler::Address(value, value, TIMES_1, Mint::value_offset()));
#else
    // Cannot speculatively untag because it erases the upper bits needed to
    // dereference when it is a Mint.
    compiler::Label not_smi;
    __ BranchIfNotSmi(value, &not_smi, compiler::Assembler::kNearJump);
    __ SmiUntagAndSignExtend(value);
    __ jmp(&done, compiler::Assembler::kNearJump);
    __ Bind(&not_smi);
    __ CompareClassId(value, kMintCid);
    __ j(NOT_EQUAL, deopt);
    __ movq(value, compiler::FieldAddress(value, Mint::value_offset()));
#endif
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != nullptr)) {
    ASSERT(representation() == kUnboxedInt32);
    Register temp = locs()->temp(0).reg();
    __ movsxd(temp, value);
    __ cmpq(temp, value);
    __ j(NOT_EQUAL, deopt);
  }
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
#if !defined(DART_COMPRESSED_POINTERS)
  // ValueFitsSmi() may be overly conservative and false because we only
  // perform range analysis during optimized compilation.
  const bool kMayAllocateMint = false;
#else
  const bool kMayAllocateMint = !ValueFitsSmi();
#endif
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = kMayAllocateMint ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      kMayAllocateMint ? LocationSummary::kCallOnSlowPath
                                       : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  if (kMayAllocateMint) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(value != out);

#if !defined(DART_COMPRESSED_POINTERS)
  ASSERT(kSmiTagSize == 1);
  if (from_representation() == kUnboxedInt32) {
    __ movsxd(out, value);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ movl(out, value);
  }
  __ SmiTag(out);
#else
  compiler::Label done;
  if (from_representation() == kUnboxedInt32) {
    __ MoveRegister(out, value);
    __ addl(out, out);
    __ movsxd(out, out);  // Does not affect flags.
    if (ValueFitsSmi()) {
      return;
    }
    __ j(NO_OVERFLOW, &done);
  } else {
    __ movl(out, value);
    __ SmiTag(out);
    if (ValueFitsSmi()) {
      return;
    }
    __ TestImmediate(value, compiler::Immediate(0xC0000000LL));
    __ j(ZERO, &done);
  }
  // Allocate a mint.
  // Value input is a writable register and we have to inform the compiler of
  // the type so it can be preserved untagged on the slow path
  locs()->live_registers()->Add(locs()->in(0), from_representation());
  const Register temp = locs()->temp(0).reg();
  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  temp);
  if (from_representation() == kUnboxedInt32) {
    __ movsxd(temp, value);  // Sign-extend.
  } else {
    __ movl(temp, value);  // Zero-extend.
  }
  __ movq(compiler::FieldAddress(out, Mint::value_offset()), temp);
  __ Bind(&done);
#endif
}

LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  // Shared slow path is used in BoxInt64Instr::EmitNativeCode in
  // precompiled mode and only after VM isolate stubs where
  // replaced with isolate-specific stubs.
  auto object_store = IsolateGroup::Current()->object_store();
  const bool stubs_in_vm_isolate =
      object_store->allocate_mint_with_fpu_regs_stub()
          ->untag()
          ->InVMIsolateHeap() ||
      object_store->allocate_mint_without_fpu_regs_stub()
          ->untag()
          ->InVMIsolateHeap();
  const bool shared_slow_path_call =
      SlowPathSharingSupported(opt) && !stubs_in_vm_isolate;
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
#if !defined(DART_COMPRESSED_POINTERS)
  __ MoveRegister(out, value);
  __ SmiTag(out);
  if (ValueFitsSmi()) {
    return;
  }
  // If the value doesn't fit in a smi, the tagging changes the sign,
  // which causes the overflow flag to be set.
  compiler::Label done;
  const Register temp = locs()->temp(0).reg();
  __ j(NO_OVERFLOW, &done);
#else
  __ leaq(out, compiler::Address(value, value, TIMES_1, 0));
  if (ValueFitsSmi()) {
    return;
  }
  compiler::Label done;
  const Register temp = locs()->temp(0).reg();
  __ movq(temp, value);
  __ sarq(temp, compiler::Immediate(30));
  __ addq(temp, compiler::Immediate(1));
  __ cmpq(temp, compiler::Immediate(2));
  __ j(BELOW, &done);
#endif

  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out, temp);
  } else if (locs()->call_on_shared_slow_path()) {
    auto object_store = compiler->isolate_group()->object_store();
    const bool live_fpu_regs = locs()->live_registers()->FpuRegisterCount() > 0;
    const auto& stub = Code::ZoneHandle(
        compiler->zone(),
        live_fpu_regs ? object_store->allocate_mint_with_fpu_regs_stub()
                      : object_store->allocate_mint_without_fpu_regs_stub());

    ASSERT(!locs()->live_registers()->ContainsRegister(
        AllocateMintABI::kResultReg));
    auto extended_env = compiler->SlowPathEnvironmentFor(this, 0);
    compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
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
    case SimdOpInstr::kFloat32x4GetX:
      // Shuffle not necessary.
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4GetY:
      __ shufps(value, value, compiler::Immediate(0x55));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4GetZ:
      __ shufps(value, value, compiler::Immediate(0xAA));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4GetW:
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

DEFINE_EMIT(Float64x2Clamp,
            (SameAsFirstInput,
             XmmRegister value,
             XmmRegister lower,
             XmmRegister upper)) {
  __ minpd(value, upper);
  __ maxpd(value, lower);
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
  CASE(Float32x4GetX)                                                          \
  CASE(Float32x4GetY)                                                          \
  CASE(Float32x4GetZ)                                                          \
  CASE(Float32x4GetW)                                                          \
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
  SIMPLE(Float64x2Clamp)                                                       \
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
  return nullptr;
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
  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/0,
                                /*preserve_registers=*/false);
  // Call the function. Parameters are already in their correct spots.
  rt.Call(TargetFunction(), TargetFunction().argument_count());
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
      __ OBJ(neg)(value);
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
  if (op_kind() == Token::kSQUARE) {
    summary->set_out(0, Location::SameAsFirstInput());
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}

void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(representation() == kUnboxedDouble);
  XmmRegister result = locs()->out(0).fpu_reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  switch (op_kind()) {
    case Token::kNEGATE:
      __ DoubleNegate(result, value);
      break;
    case Token::kSQRT:
      __ sqrtsd(result, value);
      break;
    case Token::kSQUARE:
      ASSERT(result == value);
      __ mulsd(result, value);
      break;
    case Token::kTRUNCATE:
      __ roundsd(result, value, compiler::Assembler::kRoundToZero);
      break;
    case Token::kFLOOR:
      __ roundsd(result, value, compiler::Assembler::kRoundDown);
      break;
    case Token::kCEILING:
      __ roundsd(result, value, compiler::Assembler::kRoundUp);
      break;
    default:
      UNREACHABLE();
  }
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
  __ OBJ(cmp)(left, right);
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
  __ OBJ(cvtsi2sd)(result, value);
}

DEFINE_BACKEND(Int64ToDouble, (FpuRegister result, Register value)) {
  __ cvtsi2sdq(result, value);
}

LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  result->set_temp(0, Location::RequiresRegister());
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  const Register temp = locs()->temp(0).reg();
  XmmRegister value_double = locs()->in(0).fpu_reg();
  ASSERT(result != temp);

  DoubleToIntegerSlowPath* slow_path =
      new DoubleToIntegerSlowPath(this, value_double);
  compiler->AddSlowPathCode(slow_path);

  if (recognized_kind() != MethodRecognizer::kDoubleToInteger) {
    // In JIT mode without --target-unknown-cpu VM knows target CPU features
    // at compile time and can pick more optimal representation
    // for DoubleToDouble conversion. In AOT mode and with
    // --target-unknown-cpu we test if roundsd instruction is available
    // at run time and fall back to stub if it isn't.
    ASSERT(CompilerState::Current().is_aot() || FLAG_target_unknown_cpu);
    if (FLAG_use_slow_path) {
      __ jmp(slow_path->entry_label());
      __ Bind(slow_path->exit_label());
      return;
    }
    __ cmpb(
        compiler::Address(
            THR,
            compiler::target::Thread::double_truncate_round_supported_offset()),
        compiler::Immediate(0));
    __ j(EQUAL, slow_path->entry_label());

    __ xorps(FpuTMP, FpuTMP);
    switch (recognized_kind()) {
      case MethodRecognizer::kDoubleFloorToInt:
        __ roundsd(FpuTMP, value_double, compiler::Assembler::kRoundDown);
        break;
      case MethodRecognizer::kDoubleCeilToInt:
        __ roundsd(FpuTMP, value_double, compiler::Assembler::kRoundUp);
        break;
      default:
        UNREACHABLE();
    }
    value_double = FpuTMP;
  }

  __ OBJ(cvttsd2si)(result, value_double);
  // Overflow is signalled with minint.
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ OBJ(shl)(temp, compiler::Immediate(1));
  __ j(OVERFLOW, slow_path->entry_label());
  __ SmiTag(result);
  __ Bind(slow_path->exit_label());
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

  __ OBJ(cvttsd2si)(result, value);
  // Overflow is signalled with minint.
  compiler::Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ OBJ(shl)(temp, compiler::Immediate(1));
  __ j(OVERFLOW, deopt);
  __ SmiTag(result);
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

LocationSummary* FloatCompareInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  UNREACHABLE();
  return NULL;
}

void FloatCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  // Calling convention on x64 uses XMM0 and XMM1 to pass the first two
  // double arguments and XMM0 to return the result.
  ASSERT(R13 != CALLEE_SAVED_TEMP);
  ASSERT(IsCalleeSavedRegister(R13));

  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    ASSERT(InputCount() == 2);
    const intptr_t kNumTemps = 4;
    LocationSummary* result = new (zone)
        LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
    result->set_in(0, Location::FpuRegisterLocation(XMM2));
    result->set_in(1, Location::FpuRegisterLocation(XMM1));
    result->set_temp(0, Location::RegisterLocation(R13));
    // Temp index 1.
    result->set_temp(1, Location::RegisterLocation(RAX));
    // Temp index 2.
    result->set_temp(2, Location::FpuRegisterLocation(XMM4));
    // Block XMM0 for the calling convention.
    result->set_temp(3, Location::FpuRegisterLocation(XMM0));
    result->set_out(0, Location::FpuRegisterLocation(XMM3));
    return result;
  }
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_temp(0, Location::RegisterLocation(R13));
  result->set_in(0, Location::FpuRegisterLocation(XMM0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM1));
  }
  result->set_out(0, Location::FpuRegisterLocation(XMM0));
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
  XmmRegister zero_temp =
      locs->temp(InvokeMathCFunctionInstr::kDoubleTempIndex).fpu_reg();

  __ xorps(zero_temp, zero_temp);
  __ LoadDImmediate(result, 1.0);

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
  __ LoadDImmediate(XMM0, 2.0);
  __ comisd(exp, XMM0);
  compiler::Label return_base_times_2;
  __ j(EQUAL, &return_base_times_2, compiler::Assembler::kNearJump);

  // exponent == 3.0 ?
  __ LoadDImmediate(XMM0, 3.0);
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
  __ LoadDImmediate(result, NAN);
  __ jmp(&skip_call);

  compiler::Label do_pow, return_zero;
  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadDImmediate(result, kNegInfinity);
  // base == -Infinity -> call pow;
  __ comisd(base, result);
  __ j(EQUAL, &do_pow, compiler::Assembler::kNearJump);

  // exponent == 0.5 ?
  __ LoadDImmediate(result, 0.5);
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
  {
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    __ movaps(XMM0, locs->in(0).fpu_reg());
    ASSERT(locs->in(1).fpu_reg() == XMM1);
    rt.Call(instr->TargetFunction(), kInputCount);
    __ movaps(locs->out(0).fpu_reg(), XMM0);
  }
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }

  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/0,
                                /*preserve_registers=*/false);
  ASSERT(locs()->in(0).fpu_reg() == XMM0);
  if (InputCount() == 2) {
    ASSERT(locs()->in(1).fpu_reg() == XMM1);
  }
  rt.Call(TargetFunction(), InputCount());
  ASSERT(locs()->out(0).fpu_reg() == XMM0);
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

LocationSummary* UnboxLaneInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  UNREACHABLE();
  return NULL;
}

void UnboxLaneInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* BoxLanesInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  UNREACHABLE();
  return NULL;
}

void BoxLanesInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
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
    __ OBJ(test)(right, right);
    __ j(ZERO, deopt);
  }
#if !defined(DART_COMPRESSED_POINTERS)
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
#else
  USE(temp);
  // Both operands are 31bit smis. Divide using 32bit idiv.
  __ SmiUntag(left);
  __ SmiUntag(right);
  __ cdq();
  __ idivl(right);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  __ cmpl(RAX, compiler::Immediate(0x40000000));
  __ j(EQUAL, deopt);
  __ movsxd(RAX, RAX);
  __ movsxd(RDX, RDX);
#endif

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
  if ((divisor_range() == nullptr) || divisor_range()->Overlaps(-1, 1)) {
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

// Should be kept in sync with integers.cc Multiply64Hash
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler) {
  __ movq(RDX, compiler::Immediate(0x2d51));
  __ mulq(RDX);
  __ xorq(RAX, RDX);  // RAX = xor(hi64, lo64)
  __ movq(RDX, RAX);
  __ shrq(RDX, compiler::Immediate(32));
  __ xorq(RAX, RDX);
  __ andq(RAX, compiler::Immediate(0x3fffffff));
}

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 2;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RegisterLocation(RDX));
  summary->set_temp(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(locs()->out(0).reg() == RAX);
  ASSERT(locs()->temp(0).reg() == RDX);
  const FpuRegister temp_fpu_reg = locs()->temp(1).fpu_reg();

  compiler::Label hash_double;

  __ cvttsd2siq(RAX, value);
  __ cvtsi2sdq(temp_fpu_reg, RAX);
  __ comisd(value, temp_fpu_reg);
  __ j(PARITY_EVEN, &hash_double);  // one of the arguments is NaN
  __ j(NOT_EQUAL, &hash_double);

  // RAX has int64 value
  EmitHashIntegerCodeSequence(compiler);

  compiler::Label done;
  __ jmp(&done);

  __ Bind(&hash_double);
  // Convert the double bits to a hash code that fits in a Smi.
  __ movq(RAX, value);
  __ movq(RDX, RAX);
  __ shrq(RDX, compiler::Immediate(32));
  __ xorq(RAX, RDX);
  __ andq(RAX, compiler::Immediate(compiler::target::kSmiMax));

  __ Bind(&done);
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_out(0, Location::SameAsFirstInput());
  summary->set_temp(0, Location::RegisterLocation(RDX));
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(value == RAX);
  ASSERT(result == RAX);
  ASSERT(temp == RDX);

  if (smi_) {
    __ SmiUntagAndSignExtend(RAX);
  } else {
    __ LoadFieldFromOffset(RAX, RAX, Mint::value_offset());
  }

  EmitHashIntegerCodeSequence(compiler);
  __ SmiTag(RAX);
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
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi);
  __ BranchIfNotSmi(value, deopt);
}

void CheckNullInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ThrowErrorSlowPathCode* slow_path = new NullErrorSlowPath(this);
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
    __ CompareObject(length, index);
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ OBJ(test)(index, index);
      __ j(NEGATIVE, deopt);
    } else {
      __ CompareObject(index, length);
      __ j(ABOVE_EQUAL, deopt);
    }
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ OBJ(cmp)(index, length);
    __ j(ABOVE_EQUAL, deopt);
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
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}

void CheckWritableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  WriteErrorSlowPath* slow_path = new WriteErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  __ movq(TMP, compiler::FieldAddress(locs()->in(0).reg(),
                                      compiler::target::Object::tags_offset()));
  __ testq(TMP, compiler::Immediate(
                    1 << compiler::target::UntaggedObject::kImmutableBit));
  __ j(NOT_ZERO, slow_path->entry_label());
}

class Int64DivideSlowPath : public ThrowErrorSlowPathCode {
 public:
  Int64DivideSlowPath(BinaryInt64OpInstr* instruction,
                      Register divisor,
                      Range* divisor_range)
      : ThrowErrorSlowPathCode(instruction,
                               kIntegerDivisionByZeroExceptionRuntimeEntry),
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
  Int64DivideSlowPath* slow_path =
      new (Z) Int64DivideSlowPath(instruction, right, right_range);

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
    case Token::kUSHR:
      ASSERT(shift < 64);
      __ shrq(left, compiler::Immediate(shift));
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
    case Token::kUSHR: {
      __ shrq(left, RCX);
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
      case Token::kSHR:
      case Token::kUSHR: {
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
    case Token::kSHR:
    case Token::kUSHR: {
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
  explicit ShiftInt64OpSlowPath(ShiftInt64OpInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry) {}

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
      case Token::kUSHR:
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
    __ movq(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset()),
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
    ShiftInt64OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange()) {
      slow_path = new (Z) ShiftInt64OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ cmpq(RCX, compiler::Immediate(kShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftInt64ByRCX(compiler, op_kind(), left);

    if (slow_path != nullptr) {
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
  explicit ShiftUint32OpSlowPath(ShiftUint32OpInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry) {}

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
    __ movq(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset()),
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
    ShiftUint32OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      slow_path = new (Z) ShiftUint32OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ cmpq(RCX, compiler::Immediate(kUint32ShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftUint32ByRCX(compiler, op_kind(), left);

    if (slow_path != nullptr) {
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

        __ OBJ(test)(RCX, RCX);
        __ j(LESS, deopt);
      }

      compiler::Label cont;
      __ OBJ(cmp)(RCX, compiler::Immediate(kUint32ShiftCountLimit));
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
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
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
  Register index_reg = locs()->in(0).reg();
  Register offset_reg = locs()->temp(0).reg();

  ASSERT(RequiredInputRepresentation(0) == kTagged);
  // Note: we don't bother to ensure index is a writable input because any
  // other instructions using it must also not rely on the upper bits
  // when compressed.
  __ ExtendNonNegativeSmi(index_reg);
  __ LoadObject(offset_reg, offsets_);
  __ movsxd(offset_reg, compiler::Assembler::ElementAddressForRegIndex(
                            /*is_external=*/false, kTypedDataInt32ArrayCid,
                            /*index_scale=*/4,
                            /*index_unboxed=*/false, offset_reg, index_reg));

  {
    const intptr_t kRIPRelativeLeaqSize = 7;
    const intptr_t entry_to_rip_offset = __ CodeSize() + kRIPRelativeLeaqSize;
    __ leaq(TMP, compiler::Address::AddressRIPRelative(-entry_to_rip_offset));
    ASSERT(__ CodeSize() == entry_to_rip_offset);
  }

  __ addq(TMP, offset_reg);

  // Jump to the absolute address.
  __ jmp(TMP);
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

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(
                         FLAG_precompiled_mode ? RAX : FUNCTION_REG));
  return MakeCallSummary(zone, this, summary);
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Arguments descriptor is expected in ARGS_DESC_REG.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);

  if (FLAG_precompiled_mode) {
    ASSERT(locs()->in(0).reg() == RAX);
    // RAX: Closure with cached entry point.
    __ movq(RCX, compiler::FieldAddress(
                     RAX, compiler::target::Closure::entry_point_offset()));
  } else {
    ASSERT(locs()->in(0).reg() == FUNCTION_REG);
    // FUNCTION_REG: Function.
    __ LoadCompressed(
        CODE_REG, compiler::FieldAddress(
                      FUNCTION_REG, compiler::target::Function::code_offset()));
    // Closure functions only have one entry point.
    __ movq(RCX, compiler::FieldAddress(
                     FUNCTION_REG,
                     compiler::target::Function::entry_point_offset()));
  }

  // ARGS_DESC_REG: Arguments descriptor array.
  // RCX: instructions entry point.
  if (!FLAG_precompiled_mode) {
    // RBX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ xorq(IC_DATA_REG, IC_DATA_REG);
  }
  __ call(RCX);
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 UntaggedPcDescriptors::kOther, locs(), env());
  compiler->EmitDropArguments(argument_count);
}

LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register input = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(input == result);
  __ xorq(result, compiler::Immediate(
                      compiler::target::ObjectAlignment::kBoolValueMask));
}

LocationSummary* BoolToIntInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  UNREACHABLE();
  return NULL;
}

void BoolToIntInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* IntToBoolInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  UNREACHABLE();
  return NULL;
}

void IntToBoolInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
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
