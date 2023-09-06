// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/compiler/backend/il.h"

#include "platform/memory_sanitizer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
LocationSummary* Instruction::MakeCallSummary(Zone* zone,
                                              const Instruction* instr,
                                              LocationSummary* locs) {
  // This is unused on ia32.
  ASSERT(locs == nullptr);
  ASSERT(instr->representation() == kTagged);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(EAX));
  return result;
}

DEFINE_BACKEND(LoadIndexedUnsafe, (Register out, Register index)) {
  ASSERT(instr->RequiredInputRepresentation(0) == kTagged);  // It is a Smi.
  ASSERT(instr->representation() == kTagged);
  __ movl(out, compiler::Address(instr->base_reg(), index, TIMES_2,
                                 instr->offset()));

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(StoreIndexedUnsafe,
               (NoLocation, Register index, Register value)) {
  ASSERT(instr->RequiredInputRepresentation(
             StoreIndexedUnsafeInstr::kIndexPos) == kTagged);  // It is a Smi.
  __ movl(compiler::Address(instr->base_reg(), index, TIMES_2, instr->offset()),
          value);

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(TailCall,
               (NoLocation,
                Fixed<Register, ARGS_DESC_REG>,
                Temp<Register> temp)) {
  __ LoadObject(CODE_REG, instr->code());
  __ LeaveFrame();  // The arguments are still on the stack.
  __ movl(temp, compiler::FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(temp);
}

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const bool remove_loop =
      length()->BindsToSmiConstant() && length()->BoundSmiConstant() <= 4;
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = remove_loop ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::WritableRegister());
  locs->set_in(kDestPos, Location::RegisterLocation(EDI));
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
  if (remove_loop) {
    locs->set_in(
        kLengthPos,
        Location::Constant(
            length()->definition()->OriginalDefinition()->AsConstant()));
    // Needs a valid ByteRegister for single byte moves, and a temp register
    // for more than one move. We could potentially optimize the 2 and 4 byte
    // single moves to overwrite the src_reg.
    locs->set_temp(0, Location::RegisterLocation(ECX));
  } else {
    locs->set_in(kLengthPos, Location::RegisterLocation(ECX));
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
    __ shll(length_reg, compiler::Immediate(shift));
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
    __ leal(ESI, compiler::Address(src_reg, length_reg, scale, -mov_size));
    __ CompareRegisters(dest_reg, ESI);
    __ BranchIf(UNSIGNED_GREATER, copy_forwards,
                compiler::Assembler::kNearJump);
    // ESI already has the right address, so we just need to adjust dest_reg
    // appropriately.
    __ leal(dest_reg,
            compiler::Address(dest_reg, length_reg, scale, -mov_size));
    __ std();
  } else {
    // Move the start of the src array into ESI before the string operation.
    __ movl(ESI, src_reg);
  }
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
    default:
      UNREACHABLE();
  }
  if (reversed) {
    __ cld();
  }
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Location start_loc) {
  intptr_t offset;
  if (IsTypedDataBaseClassId(array_cid)) {
    __ movl(array_reg,
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
        __ movl(array_reg,
                compiler::FieldAddress(array_reg,
                                       compiler::target::ExternalOneByteString::
                                           external_data_offset()));
        offset = 0;
        break;
      case kExternalTwoByteStringCid:
        __ movl(array_reg,
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
  }
  auto const scale = ToScaleFactor(element_size_, index_unboxed);
  __ leal(array_reg, compiler::Address(array_reg, start_reg, scale, offset));
}

LocationSummary* MoveArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  ASSERT(representation() == kTagged);
  locs->set_in(0, LocationRegisterOrConstant(value()));
  return locs;
}

void MoveArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());

  Location value = locs()->in(0);
  const compiler::Address dst(ESP, sp_relative_index() * kWordSize);
  if (value.IsConstant()) {
    __ StoreToOffset(value.constant(), dst);
  } else {
    ASSERT(value.IsRegister());
    __ StoreToOffset(value.reg(), dst);
  }
}

LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  ASSERT(representation() == kTagged);
  locs->set_in(0, Location::RegisterLocation(EAX));
  return locs;
}

// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == EAX);

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
  __ movl(EDI, ESP);
  __ subl(EDI, EBP);
  __ cmpl(EDI, compiler::Immediate(fp_sp_dist));
  __ j(EQUAL, &done, compiler::Assembler::kNearJump);
  __ int3();
  __ Bind(&done);
#endif
  __ LeaveDartFrame();
  __ ret();
}

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  bool return_in_st0 = false;
  if (marshaller_.Location(compiler::ffi::kResultIndex)
          .payload_type()
          .IsFloat()) {
    ASSERT(locs()->in(0).IsFpuRegister() && locs()->in(0).fpu_reg() == XMM0);
    return_in_st0 = true;
  }

  __ LeaveDartFrame();

  // EDI is the only sane choice for a temporary register here because:
  //
  // EDX is used for large return values.
  // ESI == THR.
  // Could be EBX or ECX, but that would make code below confusing.
  const Register tmp = EDI;

  // Pop dummy return address.
  __ popl(tmp);

  // Anything besides the return register(s!). Callee-saved registers will be
  // restored later.
  const Register vm_tag_reg = EBX;
  const Register old_exit_frame_reg = ECX;
  const Register old_exit_through_ffi_reg = tmp;

  __ popl(old_exit_frame_reg);
  __ popl(vm_tag_reg); /* old_exit_through_ffi, we still need to use tmp. */

  // Restore top_resource.
  __ popl(tmp);
  __ movl(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()),
      tmp);

  __ movl(old_exit_through_ffi_reg, vm_tag_reg);
  __ popl(vm_tag_reg);

  // Reset the exit frame info to old_exit_frame_reg *before* entering the
  // safepoint. The trampoline that called us will enter the safepoint on our
  // behalf.
  __ TransitionGeneratedToNative(vm_tag_reg, old_exit_frame_reg,
                                 old_exit_through_ffi_reg,
                                 /*enter_safepoint=*/false);

  // Move XMM0 into ST0 if needed.
  if (return_in_st0) {
    if (marshaller_.Location(compiler::ffi::kResultIndex)
            .payload_type()
            .SizeInBytes() == 8) {
      __ movsd(compiler::Address(SPREG, -8), XMM0);
      __ fldl(compiler::Address(SPREG, -8));
    } else {
      __ movss(compiler::Address(SPREG, -4), XMM0);
      __ flds(compiler::Address(SPREG, -4));
    }
  }

  // Restore C++ ABI callee-saved registers.
  __ popl(EDI);
  __ popl(ESI);
  __ popl(EBX);

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Leave the entry frame.
  __ LeaveFrame();

  // We deal with `ret 4` for structs in the JIT callback trampolines.
  __ ret();
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
  __ movl(compiler::Address(
              EBP, compiler::target::FrameOffsetInBytesForVariable(&local())),
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
    __ LoadObjectSafely(result, value());
  }
}

void ConstantInstr::EmitMoveToLocation(FlowGraphCompiler* compiler,
                                       const Location& destination,
                                       Register tmp,
                                       intptr_t pair_index) {
  if (destination.IsRegister()) {
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      if (value_.IsSmi() && RepresentationUtils::IsUnsigned(representation())) {
        // If the value is negative, then the sign bit was preserved during
        // Smi untagging, which means the resulting value may be unexpected.
        ASSERT(v >= 0);
      }
      __ movl(destination.reg(),
              compiler::Immediate(pair_index == 0 ? Utils::Low32Bits(v)
                                                  : Utils::High32Bits(v)));
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObjectSafely(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const double value_as_double = Double::Cast(value_).value();
    uword addr = FindDoubleConstant(value_as_double);
    if (addr == 0) {
      __ pushl(EAX);
      __ LoadObject(EAX, value_);
      __ movsd(destination.fpu_reg(),
               compiler::FieldAddress(EAX, Double::value_offset()));
      __ popl(EAX);
    } else if (Utils::DoublesBitEqual(value_as_double, 0.0)) {
      __ xorps(destination.fpu_reg(), destination.fpu_reg());
    } else {
      __ movsd(destination.fpu_reg(), compiler::Address::Absolute(addr));
    }
  } else if (destination.IsDoubleStackSlot()) {
    const double value_as_double = Double::Cast(value_).value();
    uword addr = FindDoubleConstant(value_as_double);
    if (addr == 0) {
      __ pushl(EAX);
      __ LoadObject(EAX, value_);
      __ movsd(FpuTMP, compiler::FieldAddress(EAX, Double::value_offset()));
      __ popl(EAX);
    } else if (Utils::DoublesBitEqual(value_as_double, 0.0)) {
      __ xorps(FpuTMP, FpuTMP);
    } else {
      __ movsd(FpuTMP, compiler::Address::Absolute(addr));
    }
    __ movsd(LocationToStackSlotAddress(destination), FpuTMP);
  } else {
    ASSERT(destination.IsStackSlot());
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      __ movl(LocationToStackSlotAddress(destination),
              compiler::Immediate(pair_index == 0 ? Utils::Low32Bits(v)
                                                  : Utils::High32Bits(v)));
    } else {
      if (compiler::Assembler::IsSafeSmi(value_) || value_.IsNull()) {
        __ movl(LocationToStackSlotAddress(destination),
                compiler::Immediate(static_cast<int32_t>(value_.ptr())));
      } else {
        __ pushl(EAX);
        __ LoadObjectSafely(EAX, value_);
        __ movl(LocationToStackSlotAddress(destination), EAX);
        __ popl(EAX);
      }
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
  const intptr_t kNumTemps =
      (constant_address() == 0) && !is_unboxed_int ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(is_unboxed_int);
    locs->set_out(0, Location::RequiresRegister());
  }
  if (kNumTemps == 1) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}

void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    EmitMoveToLocation(compiler, locs()->out(0));
  }
}

LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(kInstancePos,
                  Location::RegisterLocation(TypeTestABI::kInstanceReg));
  summary->set_in(kDstTypePos, LocationFixedRegisterOrConstant(
                                   dst_type(), TypeTestABI::kDstTypeReg));
  summary->set_in(
      kInstantiatorTAVPos,
      Location::RegisterLocation(TypeTestABI::kInstantiatorTypeArgumentsReg));
  summary->set_in(kFunctionTAVPos, Location::RegisterLocation(
                                       TypeTestABI::kFunctionTypeArgumentsReg));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->always_calls());

  auto object_store = compiler->isolate_group()->object_store();
  const auto& assert_boolean_stub =
      Code::ZoneHandle(compiler->zone(), object_store->assert_boolean_stub());

  compiler::Label done;
  __ testl(
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
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid || operation_cid() == kIntegerCid) {
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
  return nullptr;
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = nullptr) {
  compiler::Label done;
  if (value_is_smi == nullptr) {
    __ movl(value_cid_reg, compiler::Immediate(kSmiCid));
  }
  __ testl(value_reg, compiler::Immediate(kSmiTagMask));
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
                                     Token::Kind kind,
                                     BranchLabels labels) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant());
  } else if (right.IsStackSlot()) {
    __ cmpl(left.reg(), LocationToStackSlotAddress(right));
  } else {
    __ cmpl(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition EmitWordComparisonOp(FlowGraphCompiler* compiler,
                                      const LocationSummary& locs,
                                      Token::Kind kind,
                                      BranchLabels labels) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);

  if (left.IsConstant()) {
    __ CompareImmediate(
        right.reg(),
        static_cast<uword>(Integer::Cast(left.constant()).AsInt64Value()));
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareImmediate(
        left.reg(),
        static_cast<uword>(Integer::Cast(right.constant()).AsInt64Value()));
  } else if (right.IsStackSlot()) {
    __ cmpl(left.reg(), LocationToStackSlotAddress(right));
  } else {
    __ cmpl(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                           const LocationSummary& locs,
                                           Token::Kind kind,
                                           BranchLabels labels) {
  ASSERT(Token::IsEqualityOperator(kind));
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();
  compiler::Label done;
  // Compare lower.
  __ cmpl(left1, right1);
  __ j(NOT_EQUAL, &done);
  // Lower is equal, compare upper.
  __ cmpl(left2, right2);
  __ Bind(&done);
  Condition true_condition = TokenKindToIntCondition(kind);
  return true_condition;
}

static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             const LocationSummary& locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();

  Condition hi_cond = OVERFLOW, lo_cond = OVERFLOW;
  switch (kind) {
    case Token::kLT:
      hi_cond = LESS;
      lo_cond = BELOW;
      break;
    case Token::kGT:
      hi_cond = GREATER;
      lo_cond = ABOVE;
      break;
    case Token::kLTE:
      hi_cond = LESS;
      lo_cond = BELOW_EQUAL;
      break;
    case Token::kGTE:
      hi_cond = GREATER;
      lo_cond = ABOVE_EQUAL;
      break;
    default:
      break;
  }
  ASSERT(hi_cond != OVERFLOW && lo_cond != OVERFLOW);
  // Compare upper halves first.
  __ cmpl(left2, right2);
  __ j(hi_cond, labels.true_label);
  __ j(FlipCondition(hi_cond), labels.false_label);

  // If upper is equal, compare lower half.
  __ cmpl(left1, right1);
  return lo_cond;
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
    // Null-aware EqualityCompare instruction is only used in AOT.
    UNREACHABLE();
  }
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), labels);
  } else if (operation_cid() == kIntegerCid) {
    return EmitWordComparisonOp(compiler, *locs(), kind(), labels);
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
    EmitBranchOnCondition(compiler, true_condition, labels,
                          compiler::Assembler::kNearJump);
  }

  Register result = locs()->out(0).reg();
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
  Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int32_t imm = static_cast<int32_t>(right.constant().ptr());
    __ testl(left, compiler::Immediate(imm));
  } else {
    __ testl(left, right.reg());
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
  __ testl(val_reg, compiler::Immediate(kSmiTagMask));
  __ j(ZERO, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ cmpl(cid_reg, compiler::Immediate(test_cid));
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
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
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

Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  Register result = locs()->out(0).reg();
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());

  // Pass a pointer to the first argument in EAX.
  __ leal(EAX, compiler::Address(ESP, (ArgumentCount() - 1) * kWordSize));

  __ movl(EDX, compiler::Immediate(argc_tag));

  const Code* stub;

  // There is no lazy-linking support on ia32.
  ASSERT(!link_lazily());
  if (is_bootstrap_native()) {
    stub = &StubCode::CallBootstrapNative();
  } else if (is_auto_scope()) {
    stub = &StubCode::CallAutoScopeNative();
  } else {
    stub = &StubCode::CallNoScopeNative();
  }
  const compiler::ExternalLabel label(
      reinterpret_cast<uword>(native_c_function()));
  __ movl(ECX, compiler::Immediate(label.address()));
  // We can never lazy-deopt here because natives are never optimized.
  ASSERT(!compiler->is_optimizing());
  compiler->GenerateNonLazyDeoptableStubCall(
      source(), *stub, UntaggedPcDescriptors::kOther, locs());
  __ LoadFromOffset(result, ESP, 0);

  compiler->EmitDropArguments(ArgumentCount());  // Drop the arguments.
}

#define R(r) (1 << r)

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(CallingConventions::kSecondNonArgumentRegister) |
       R(CallingConventions::kFfiAnyNonAbiRegister)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register branch = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  const Register temp = locs()->temp(0).reg();
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves.
  // For leaf calls, this holds the SP used to restore the pre-aligned SP after
  // the call.
  const Register saved_fp_or_sp = locs()->temp(1).reg();

  // Ensure these are callee-saved register and are preserved across the call.
  ASSERT(IsCalleeSavedRegister(saved_fp_or_sp));
  // Other temps don't need to be preserved.

  __ movl(saved_fp_or_sp, is_leaf_ ? SPREG : FPREG);

  intptr_t stack_required = marshaller_.RequiredStackSpaceInBytes();

  if (is_leaf_) {
    // For leaf calls we need to leave space at the bottom for the pre-align SP.
    stack_required += compiler::target::kWordSize;
  } else {
    // Make a space to put the return address.
    __ pushl(compiler::Immediate(0));

    // We need to create a dummy "exit frame". It will have a null code object.
    __ LoadObject(CODE_REG, Object::null_object());
    __ EnterDartFrame(0);
  }

  // Reserve space for the arguments that go on the stack (if any), then align.
  __ ReserveAlignedFrameSpace(stack_required);
#if defined(USING_MEMORY_SANITIZER)
  UNIMPLEMENTED();
#endif

  // No second temp: PointerToMemoryLocation is not used for arguments in ia32.
  EmitParamMoves(compiler, is_leaf_ ? FPREG : saved_fp_or_sp, temp,
                 kNoRegister);

  if (is_leaf_) {
    // We store the pre-align SP at a fixed offset from the final SP.
    // Pushing before alignment would mean its placement would vary with how
    // much the frame was unaligned.
    __ movl(compiler::Address(SPREG, marshaller_.RequiredStackSpaceInBytes()),
            saved_fp_or_sp);
  }

  if (compiler::Assembler::EmittingComments()) {
    __ Comment(is_leaf_ ? "Leaf Call" : "Call");
  }

  if (is_leaf_) {
#if !defined(PRODUCT)
    // Set the thread object's top_exit_frame_info and VMTag to enable the
    // profiler to determine that thread is no longer executing Dart code.
    __ movl(compiler::Address(
                THR, compiler::target::Thread::top_exit_frame_info_offset()),
            FPREG);
    __ movl(compiler::Assembler::VMTagAddress(), branch);
#endif

    __ call(branch);

#if !defined(PRODUCT)
    __ movl(compiler::Assembler::VMTagAddress(),
            compiler::Immediate(compiler::target::Thread::vm_tag_dart_id()));
    __ movl(compiler::Address(
                THR, compiler::target::Thread::top_exit_frame_info_offset()),
            compiler::Immediate(0));
#endif
  } else {
    // We need to copy a dummy return address up into the dummy stack frame so
    // the stack walker will know which safepoint to use. Unlike X64, there's no
    // PC-relative 'leaq' available, so we have do a trick with 'call'.
    compiler::Label get_pc;
    __ call(&get_pc);
    compiler->EmitCallsiteMetadata(InstructionSource(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());
    __ Bind(&get_pc);
    __ popl(temp);
    __ movl(compiler::Address(FPREG, kSavedCallerPcSlotFromFp * kWordSize),
            temp);

    ASSERT(!CanExecuteGeneratedCodeInSafepoint());
    // We cannot trust that this code will be executable within a safepoint.
    // Therefore we delegate the responsibility of entering/exiting the
    // safepoint to a stub which in the VM isolate's heap, which will never lose
    // execute permission.
    __ movl(temp,
            compiler::Address(
                THR, compiler::target::Thread::
                         call_native_through_safepoint_entry_point_offset()));

    // Calls EAX within a safepoint and clobbers EBX.
    ASSERT(branch == EAX);
    __ call(temp);

    if (marshaller_.IsHandle(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      compiler::Label not_error;
      __ movl(temp,
              compiler::Address(CallingConventions::kReturnReg,
                                compiler::target::LocalHandle::ptr_offset()));
      __ BranchIfSmi(temp, &not_error);
      __ LoadClassId(temp, temp);
      __ RangeCheck(temp, kNoRegister, kFirstErrorCid, kLastErrorCid,
                    compiler::AssemblerBase::kIfNotInRange, &not_error);

      // Slow path, use the stub to propagate error, to save on code-size.
      __ Comment("Slow path: call Dart_PropagateError through stub.");
      __ movl(temp,
              compiler::Address(
                  THR, compiler::target::Thread::
                           call_native_through_safepoint_entry_point_offset()));
      __ pushl(CallingConventions::kReturnReg);
      __ movl(EAX, compiler::Address(
                       THR, kPropagateErrorRuntimeEntry.OffsetFromThread()));
      __ call(temp);
#if defined(DEBUG)
      // We should never return with normal controlflow from this.
      __ int3();
#endif

      __ Bind(&not_error);
    }
  }

  // Restore the stack when a struct by value is returned into memory pointed
  // to by a pointer that is passed into the function.
  if (CallingConventions::kUsesRet4 &&
      marshaller_.Location(compiler::ffi::kResultIndex).IsPointerToMemory()) {
    // Callee uses `ret 4` instead of `ret` to return.
    // See: https://c9x.me/x86/html/file_module_x86_id_280.html
    // Caller does `sub esp, 4` immediately after return to balance stack.
    __ subl(SPREG, compiler::Immediate(compiler::target::kWordSize));
  }

  // The x86 calling convention requires floating point values to be returned
  // on the "floating-point stack" (aka. register ST0). We don't use the
  // floating-point stack in Dart, so we need to move the return value back
  // into an XMM register.
  if (representation() == kUnboxedDouble) {
    __ fstpl(compiler::Address(SPREG, -kDoubleSize));
    __ movsd(XMM0, compiler::Address(SPREG, -kDoubleSize));
  } else if (representation() == kUnboxedFloat) {
    __ fstps(compiler::Address(SPREG, -kFloatSize));
    __ movss(XMM0, compiler::Address(SPREG, -kFloatSize));
  }

  // Pass both registers for use as clobbered temp registers.
  EmitReturnMoves(compiler, saved_fp_or_sp, temp);

  if (is_leaf_) {
    // Restore pre-align SP. Was stored right before the first stack argument.
    __ movl(SPREG,
            compiler::Address(SPREG, marshaller_.RequiredStackSpaceInBytes()));
  } else {
    // Leave dummy exit frame.
    __ LeaveDartFrame();

    // Instead of returning to the "fake" return address, we just pop it.
    __ popl(temp);
  }
}

// Keep in sync with NativeReturnInstr::EmitNativeCode.
void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));

  // Enter the entry frame. NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  __ EnterFrame(0);

  // Save a space for the code object.
  __ xorl(EAX, EAX);
  __ pushl(EAX);

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Save ABI callee-saved registers.
  __ pushl(EBX);
  __ pushl(ESI);
  __ pushl(EDI);

  // Save the current VMTag on the stack.
  __ movl(ECX, compiler::Assembler::VMTagAddress());
  __ pushl(ECX);

  // Save top resource.
  __ pushl(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()));
  __ movl(
      compiler::Address(THR, compiler::target::Thread::top_resource_offset()),
      compiler::Immediate(0));

  __ pushl(compiler::Address(
      THR, compiler::target::Thread::exit_through_ffi_offset()));

  // Save top exit frame info. Stack walker expects it to be here.
  __ pushl(compiler::Address(
      THR, compiler::target::Thread::top_exit_frame_info_offset()));

  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // The callback trampoline (caller) has already left the safepoint for us.
  __ TransitionNativeToGenerated(EAX, /*exit_safepoint=*/false);

  // Now that the safepoint has ended, we can hold Dart objects with bare hands.

  // Load the code object.
  const Function& target_function = marshaller_.dart_signature();
  const intptr_t callback_id = target_function.FfiCallbackId();
  __ movl(EAX, compiler::Address(
                   THR, compiler::target::Thread::isolate_group_offset()));
  __ movl(EAX, compiler::Address(
                   EAX, compiler::target::IsolateGroup::object_store_offset()));
  __ movl(EAX,
          compiler::Address(
              EAX, compiler::target::ObjectStore::ffi_callback_code_offset()));
  __ movl(EAX, compiler::FieldAddress(
                   EAX, compiler::target::GrowableObjectArray::data_offset()));
  __ movl(CODE_REG, compiler::FieldAddress(
                        EAX, compiler::target::Array::data_offset() +
                                 callback_id * compiler::target::kWordSize));

  // Put the code object in the reserved slot.
  __ movl(compiler::Address(FPREG,
                            kPcMarkerSlotFromFp * compiler::target::kWordSize),
          CODE_REG);

  // Load a GC-safe value for the arguments descriptor (unused but tagged).
  __ xorl(ARGS_DESC_REG, ARGS_DESC_REG);

  // Push a dummy return address which suggests that we are inside of
  // InvokeDartCodeStub. This is how the stack walker detects an entry frame.
  __ movl(EAX,
          compiler::Address(
              THR, compiler::target::Thread::invoke_dart_code_stub_offset()));
  __ pushl(compiler::FieldAddress(
      EAX, compiler::target::Code::entry_point_offset()));

  // Continue with Dart frame setup.
  FunctionEntryInstr::EmitNativeCode(compiler);
}

#define R(r) (1 << r)

LocationSummary* CCallInstr::MakeLocationSummary(Zone* zone,
                                                 bool is_optimizing) const {
  constexpr Register saved_fp = CallingConventions::kSecondNonArgumentRegister;
  constexpr Register temp0 = CallingConventions::kFfiAnyNonAbiRegister;
  static_assert(saved_fp < temp0, "Unexpected ordering of registers in set.");
  return MakeLocationSummaryInternal(zone, (R(saved_fp) | R(temp0)));
}

#undef R

void CCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = locs()->temp(0).reg();
  const Register temp0 = locs()->temp(1).reg();

  __ MoveRegister(saved_fp, FPREG);
  const intptr_t frame_space = native_calling_convention_.StackTopInBytes();
  __ EnterCFrame(frame_space);

  EmitParamMoves(compiler, saved_fp, temp0);

  const Register target_address = locs()->in(TargetAddressIndex()).reg();
  __ CallCFunction(target_address);

  __ LeaveCFrame();
}

static bool CanBeImmediateIndex(Value* value, intptr_t cid) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == nullptr) ||
      !compiler::Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const intptr_t offset = Instance::DataOffsetFor(cid);
  const int64_t displacement = index * scale + offset;
  return Utils::IsInt(32, displacement);
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
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ movl(result, compiler::Immediate(
                      reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(result,
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
  __ movl(result, compiler::FieldAddress(str, String::length_offset()));
  __ cmpl(result, compiler::Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, compiler::Assembler::kNearJump);
  __ movl(result, compiler::Immediate(Smi::RawValue(-1)));
  __ jmp(&done);
  __ Bind(&is_one);
  __ movzxb(result, compiler::FieldAddress(str, OneByteString::data_offset()));
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
  summary->set_in(4, Location::RequiresRegister());  // table
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
  const Register flags_reg = end_reg;
  const Register temp_reg = bytes_reg;
  const XmmRegister vector_reg = FpuTMP;

  const intptr_t kBytesEndTempOffset = 1 * compiler::target::kWordSize;
  const intptr_t kBytesEndMinus16TempOffset = 0 * compiler::target::kWordSize;

  const intptr_t kSizeMask = 0x03;
  const intptr_t kFlagsMask = 0x3C;

  compiler::Label scan_ascii, ascii_loop, ascii_loop_in, nonascii_loop;
  compiler::Label rest, rest_loop, rest_loop_in, done;

  // Address of input bytes.
  __ movl(bytes_reg,
          compiler::FieldAddress(bytes_reg,
                                 compiler::target::PointerBase::data_offset()));

  // Pointers to start, end and end-16.
  __ leal(bytes_ptr_reg, compiler::Address(bytes_reg, start_reg, TIMES_1, 0));
  __ leal(temp_reg, compiler::Address(bytes_reg, end_reg, TIMES_1, 0));
  __ pushl(temp_reg);
  __ leal(temp_reg, compiler::Address(temp_reg, -16));
  __ pushl(temp_reg);

  // Initialize size and flags.
  __ xorl(size_reg, size_reg);
  __ xorl(flags_reg, flags_reg);

  __ jmp(&scan_ascii, compiler::Assembler::kNearJump);

  // Loop scanning through ASCII bytes one 16-byte vector at a time.
  // While scanning, the size register contains the size as it was at the start
  // of the current block of ASCII bytes, minus the address of the start of the
  // block. After the block, the end address of the block is added to update the
  // size to include the bytes in the block.
  __ Bind(&ascii_loop);
  __ addl(bytes_ptr_reg, compiler::Immediate(16));
  __ Bind(&ascii_loop_in);

  // Exit vectorized loop when there are less than 16 bytes left.
  __ cmpl(bytes_ptr_reg, compiler::Address(ESP, kBytesEndMinus16TempOffset));
  __ j(UNSIGNED_GREATER, &rest, compiler::Assembler::kNearJump);

  // Find next non-ASCII byte within the next 16 bytes.
  // Note: In principle, we should use MOVDQU here, since the loaded value is
  // used as input to an integer instruction. In practice, according to Agner
  // Fog, there is no penalty for using the wrong kind of load.
  __ movups(vector_reg, compiler::Address(bytes_ptr_reg, 0));
  __ pmovmskb(temp_reg, vector_reg);
  __ bsfl(temp_reg, temp_reg);
  __ j(EQUAL, &ascii_loop, compiler::Assembler::kNearJump);

  // Point to non-ASCII byte and update size.
  __ addl(bytes_ptr_reg, temp_reg);
  __ addl(size_reg, bytes_ptr_reg);

  // Read first non-ASCII byte.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));

  // Loop over block of non-ASCII bytes.
  __ Bind(&nonascii_loop);
  __ addl(bytes_ptr_reg, compiler::Immediate(1));

  // Update size and flags based on byte value.
  __ movzxb(temp_reg, compiler::FieldAddress(
                          table_reg, temp_reg, TIMES_1,
                          compiler::target::OneByteString::data_offset()));
  __ orl(flags_reg, temp_reg);
  __ andl(temp_reg, compiler::Immediate(kSizeMask));
  __ addl(size_reg, temp_reg);

  // Stop if end is reached.
  __ cmpl(bytes_ptr_reg, compiler::Address(ESP, kBytesEndTempOffset));
  __ j(UNSIGNED_GREATER_EQUAL, &done, compiler::Assembler::kNearJump);

  // Go to ASCII scan if next byte is ASCII, otherwise loop.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));
  __ testl(temp_reg, compiler::Immediate(0x80));
  __ j(NOT_EQUAL, &nonascii_loop, compiler::Assembler::kNearJump);

  // Enter the ASCII scanning loop.
  __ Bind(&scan_ascii);
  __ subl(size_reg, bytes_ptr_reg);
  __ jmp(&ascii_loop_in);

  // Less than 16 bytes left. Process the remaining bytes individually.
  __ Bind(&rest);

  // Update size after ASCII scanning loop.
  __ addl(size_reg, bytes_ptr_reg);
  __ jmp(&rest_loop_in, compiler::Assembler::kNearJump);

  __ Bind(&rest_loop);

  // Read byte and increment pointer.
  __ movzxb(temp_reg, compiler::Address(bytes_ptr_reg, 0));
  __ addl(bytes_ptr_reg, compiler::Immediate(1));

  // Update size and flags based on byte value.
  __ movzxb(temp_reg, compiler::FieldAddress(
                          table_reg, temp_reg, TIMES_1,
                          compiler::target::OneByteString::data_offset()));
  __ orl(flags_reg, temp_reg);
  __ andl(temp_reg, compiler::Immediate(kSizeMask));
  __ addl(size_reg, temp_reg);

  // Stop if end is reached.
  __ Bind(&rest_loop_in);
  __ cmpl(bytes_ptr_reg, compiler::Address(ESP, kBytesEndTempOffset));
  __ j(UNSIGNED_LESS, &rest_loop, compiler::Assembler::kNearJump);
  __ Bind(&done);

  // Pop temporaries.
  __ addl(ESP, compiler::Immediate(2 * compiler::target::kWordSize));

  // Write flags to field.
  __ andl(flags_reg, compiler::Immediate(kFlagsMask));
  if (!IsScanFlagsUnboxed()) {
    __ SmiTag(flags_reg);
  }
  Register decoder_reg;
  const Location decoder_location = locs()->in(0);
  if (decoder_location.IsStackSlot()) {
    __ movl(temp_reg, LocationToStackSlotAddress(decoder_location));
    decoder_reg = temp_reg;
  } else {
    decoder_reg = decoder_location.reg();
  }
  const auto scan_flags_field_offset = scan_flags_field_.offset_in_bytes();
  __ orl(compiler::FieldAddress(decoder_reg, scan_flags_field_offset),
         flags_reg);
}

LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ movl(result, compiler::Address(obj, offset()));
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ movl(result, compiler::FieldAddress(obj, offset()));
  }
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                         : Location::RequiresRegister());
  }
  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedInt64) {
    ASSERT(class_id() == kTypedDataInt64ArrayCid ||
           class_id() == kTypedDataUint64ArrayCid);
    locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
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
  if (index_scale() == 1 && !index_unboxed) {
    if (index.IsRegister()) {
      __ SmiUntag(index.reg());
      index_unboxed = true;
    } else {
      ASSERT(index.IsConstant());
    }
  }

  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale(),
                               index_unboxed, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale(), array,
                               Smi::Cast(index.constant()).Value());

  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    XmmRegister result = locs()->out(0).fpu_reg();
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        __ movss(result, element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        __ movsd(result, element_address);
        break;
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataFloat64x2ArrayCid:
        __ movups(result, element_address);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  switch (class_id()) {
    case kTypedDataInt32ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedInt32);
      __ movl(result, element_address);
      break;
    }
    case kTypedDataUint32ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedUint32);
      __ movl(result, element_address);
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      ASSERT(representation() == kUnboxedInt64);
      ASSERT(locs()->out(0).IsPairLocation());
      PairLocation* result_pair = locs()->out(0).AsPairLocation();
      const Register result_lo = result_pair->At(0).reg();
      const Register result_hi = result_pair->At(1).reg();
      ASSERT(class_id() == kTypedDataInt64ArrayCid ||
             class_id() == kTypedDataUint64ArrayCid);
      __ movl(result_lo, element_address);
      element_address =
          index.IsRegister()
              ? compiler::Assembler::ElementAddressForRegIndex(
                    IsExternal(), class_id(), index_scale(), index_unboxed,
                    array, index.reg(), kWordSize)
              : compiler::Assembler::ElementAddressForIntIndex(
                    IsExternal(), class_id(), index_scale(), array,
                    Smi::Cast(index.constant()).Value(), kWordSize);
      __ movl(result_hi, element_address);
      break;
    }
    case kTypedDataInt8ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      __ movsxb(result, element_address);
      break;
    }
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      __ movzxb(result, element_address);
      break;
    }
    case kTypedDataInt16ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      __ movsxw(result, element_address);
      break;
    }
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      __ movzxw(result, element_address);
      break;
    }
    default: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kTagged);
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
             (class_id() == kTypeArgumentsCid) || (class_id() == kRecordCid));
      __ movl(result, element_address);
      break;
    }
  }
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps =
      class_id() == kArrayCid && ShouldEmitStoreBarrier() ? 2 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                         : Location::RequiresRegister());
  }
  switch (class_id()) {
    case kArrayCid:
      locs->set_in(2, LocationRegisterOrConstant(value()));
      if (ShouldEmitStoreBarrier()) {
        locs->set_in(0, Location::RegisterLocation(kWriteBarrierObjectReg));
        locs->set_in(2, Location::RegisterLocation(kWriteBarrierValueReg));
        locs->set_temp(0, Location::RegisterLocation(kWriteBarrierSlotReg));
        locs->set_temp(1, Location::RequiresRegister());
      }
      break;
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
      // TODO(fschneider): Add location constraint for byte registers (EAX,
      // EBX, ECX, EDX) instead of using a fixed register.
      locs->set_in(2, LocationFixedRegisterOrSmiConstant(value(), EAX));
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Writable register because the value must be untagged before storing.
      locs->set_in(2, Location::WritableRegister());
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      locs->set_in(2, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      // TODO(srdjan): Support Float64 constants.
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
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
  if ((index_scale() == 1) && index.IsRegister() && !index_unboxed) {
    __ SmiUntag(index.reg());
    index_unboxed = true;
  }
  compiler::Address element_address =
      index.IsRegister() ? compiler::Assembler::ElementAddressForRegIndex(
                               IsExternal(), class_id(), index_scale(),
                               index_unboxed, array, index.reg())
                         : compiler::Assembler::ElementAddressForIntIndex(
                               IsExternal(), class_id(), index_scale(), array,
                               Smi::Cast(index.constant()).Value());

  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        Register value = locs()->in(2).reg();
        Register slot = locs()->temp(0).reg();
        Register scratch = locs()->temp(1).reg();
        __ leal(slot, element_address);
        __ StoreIntoArray(array, slot, value, CanValueBeSmi(), scratch);
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreIntoObjectNoBarrier(array, element_address, constant);
      } else {
        Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, element_address, value);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kOneByteStringCid:
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ movb(element_address,
                compiler::Immediate(static_cast<int8_t>(constant.Value())));
      } else {
        ASSERT(locs()->in(2).reg() == EAX);
        __ movb(element_address, AL);
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
        ASSERT(locs()->in(2).reg() == EAX);
        compiler::Label store_value, store_0xff;
        __ cmpl(EAX, compiler::Immediate(0xFF));
        __ j(BELOW_EQUAL, &store_value, compiler::Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorl(EAX, EAX);
        __ jmp(&store_value, compiler::Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ movl(EAX, compiler::Immediate(0xFF));
        __ Bind(&store_value);
        __ movb(element_address, AL);
      }
      break;
    }
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      const Register value = locs()->in(2).reg();
      __ movw(element_address, value);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      __ movl(element_address, locs()->in(2).reg());
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      ASSERT(locs()->in(2).IsPairLocation());
      PairLocation* value_pair = locs()->in(2).AsPairLocation();
      const Register value_lo = value_pair->At(0).reg();
      const Register value_hi = value_pair->At(1).reg();
      __ movl(element_address, value_lo);
      element_address =
          index.IsRegister()
              ? compiler::Assembler::ElementAddressForRegIndex(
                    IsExternal(), class_id(), index_scale(), index_unboxed,
                    array, index.reg(), kWordSize)
              : compiler::Assembler::ElementAddressForIntIndex(
                    IsExternal(), class_id(), index_scale(), array,
                    Smi::Cast(index.constant()).Value(), kWordSize);
      __ movl(element_address, value_hi);
      break;
    }
    case kTypedDataFloat32ArrayCid:
      __ movss(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataFloat64ArrayCid:
      __ movsd(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
      __ movups(element_address, locs()->in(2).fpu_reg());
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldTypeInstr)

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
      // Value in graph known to be null.
      // Compare with null.
      __ cmpl(field_nullability_operand, compiler::Immediate(value_cid));
    } else {
      // Value in graph known to be non-null.
      // Compare class id with guard field class id.
      __ cmpl(field_cid_operand, compiler::Immediate(value_cid));
    }
    __ j(EQUAL, &ok);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    // Length guard will be emitted separately when needed via GuardFieldLength
    // instruction after GuardFieldClass.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ cmpl(field_cid_operand, compiler::Immediate(kIllegalCid));
      // Jump to failure path when guard field has been initialized and
      // the field and value class ids do not match.
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        // Do not know value's class id.
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

      __ pushl(field_reg);
      __ pushl(value_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ jmp(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != nullptr);
    ASSERT(fail == deopt);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testl(value_reg, compiler::Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ cmpl(value_cid_reg, compiler::Immediate(field_cid));
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        if (field_cid != kSmiCid) {
          __ cmpl(value_cid_reg, compiler::Immediate(kNullCid));
        } else {
          const compiler::Immediate& raw_null =
              compiler::Immediate(static_cast<intptr_t>(Object::null()));
          __ cmpl(value_reg, raw_null);
        }
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
    __ movl(length_reg, compiler::FieldAddress(
                            field_reg, Field::guarded_list_length_offset()));

    __ cmpl(offset_reg, compiler::Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ cmpl(length_reg, compiler::Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == nullptr) {
      __ j(EQUAL, &ok);

      __ pushl(field_reg);
      __ pushl(value_reg);
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

    __ cmpl(compiler::FieldAddress(
                value_reg, field().guarded_list_length_in_object_offset()),
            compiler::Immediate(Smi::RawValue(field().guarded_list_length())));
    __ j(NOT_EQUAL, deopt);
  }
}

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  LocationSummary* locs =
      new (zone) LocationSummary(zone, 1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsWriteBarrier() ? Location::WritableRegister()
                                               : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  compiler->used_static_fields().Add(&field());

  __ movl(temp,
          compiler::Address(
              THR, compiler::target::Thread::field_table_values_offset()));
  // Note: static fields ids won't be changed by hot-reload.
  __ movl(
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
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == TypeTestABI::kInstanceReg);
  ASSERT(locs()->in(1).reg() == TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs()->in(2).reg() == TypeTestABI::kFunctionTypeArgumentsReg);

  compiler->GenerateInstanceOf(source(), deopt_id(), env(), type(), locs());
  ASSERT(locs()->out(0).reg() == EAX);
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

  // Instance in AllocateArrayABI::kResultReg.
  // Object end address in EBX.
  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      compiler::Assembler::kFarJump,
                      AllocateArrayABI::kResultReg,  // instance
                      EBX,                           // end address
                      EDI);                          // temp

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::type_arguments_offset()),
      AllocateArrayABI::kTypeArgumentsReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             Array::length_offset()),
      AllocateArrayABI::kLengthReg);

  // Initialize all array elements to raw_null.
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(UntaggedArray);
    const compiler::Immediate& raw_null =
        compiler::Immediate(static_cast<intptr_t>(Object::null()));
    __ leal(EDI, compiler::FieldAddress(AllocateArrayABI::kResultReg,
                                        sizeof(UntaggedArray)));
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      __ movl(EBX, raw_null);
      while (current_offset < array_size) {
        __ StoreIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                    compiler::Address(EDI, current_offset),
                                    EBX);
        current_offset += kWordSize;
      }
    } else {
      compiler::Label init_loop;
      __ Bind(&init_loop);
      __ StoreIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                  compiler::Address(EDI, 0),
                                  Object::null_object());
      __ addl(EDI, compiler::Immediate(kWordSize));
      __ cmpl(EDI, EBX);
      __ j(BELOW, &init_loop, compiler::Assembler::kNearJump);
    }
  }
  __ jmp(done, compiler::Assembler::kNearJump);
}

void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label slow_path, done;
  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    if (compiler->is_optimizing() && num_elements()->BindsToConstant() &&
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
  locs->set_temp(0, Location::RegisterLocation(ECX));
  locs->set_temp(1, Location::RegisterLocation(EDI));
  locs->set_out(0, Location::RegisterLocation(EAX));
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
    ASSERT(!locs->live_registers()->Contains(locs->out(0)));

    compiler->SaveLiveRegisters(locs);

    auto slow_path_env = compiler->SlowPathEnvironmentFor(
        instruction(), /*num_slow_path_args=*/0);
    ASSERT(slow_path_env != nullptr);

    __ movl(EDX, compiler::Immediate(instruction()->num_context_variables()));
    compiler->GenerateStubCall(instruction()->source(),
                               StubCode::AllocateContext(),
                               UntaggedPcDescriptors::kOther, locs,
                               instruction()->deopt_id(), slow_path_env);
    ASSERT(instruction()->locs()->out(0).reg() == EAX);
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ jmp(exit_label());
  }
};

void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  Register temp = locs()->temp(0).reg();
  Register temp2 = locs()->temp(1).reg();
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
                        temp2);  // temp

    // Setup up number of context variables field.
    __ movl(compiler::FieldAddress(result, Context::num_variables_offset()),
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
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EDX);
  ASSERT(locs()->out(0).reg() == EAX);

  __ movl(EDX, compiler::Immediate(num_context_variables()));
  compiler->GenerateStubCall(source(), StubCode::AllocateContext(),
                             UntaggedPcDescriptors::kOther, locs(), deopt_id(),
                             env());
}

LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == ECX);
  ASSERT(locs()->out(0).reg() == EAX);

  compiler->GenerateStubCall(source(), StubCode::CloneContext(),
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

  // Restore ESP from EBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ leal(ESP, compiler::Address(EBP, fp_sp_dist));

  if (!compiler->is_optimizing()) {
    if (raw_exception_var_ != nullptr) {
      __ movl(compiler::Address(EBP,
                                compiler::target::FrameOffsetInBytesForVariable(
                                    raw_exception_var_)),
              kExceptionObjectReg);
    }
    if (raw_stacktrace_var_ != nullptr) {
      __ movl(compiler::Address(EBP,
                                compiler::target::FrameOffsetInBytesForVariable(
                                    raw_stacktrace_var_)),
              kStackTraceObjectReg);
    }
  }
}

LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = opt ? 0 : 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  if (!opt) {
    summary->set_temp(0, Location::RequiresRegister());
  }
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
      __ movl(compiler::Address(THR, Thread::stack_overflow_flags_offset()),
              compiler::Immediate(Thread::kOsrRequest));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction()->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == nullptr);
    Environment* env = compiler->SlowPathEnvironmentFor(
        instruction(), /*num_slow_path_args=*/0);
    compiler->pending_deoptimization_env_ = env;

    __ CallRuntime(kInterruptOrStackOverflowRuntimeEntry, kNumSlowPathArgs);
    compiler->EmitCallsiteMetadata(
        instruction()->source(), instruction()->deopt_id(),
        UntaggedPcDescriptors::kOther, instruction()->locs(), env);

    if (compiler->isolate_group()->use_osr() && !compiler->is_optimizing() &&
        instruction()->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOsrEntry,
                                     instruction()->deopt_id(),
                                     InstructionSource());
    }
    compiler->pending_deoptimization_env_ = nullptr;
    compiler->RestoreLiveRegisters(instruction()->locs());
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

  __ cmpl(ESP, compiler::Address(THR, Thread::stack_limit_offset()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(EDI, compiler->parsed_function().function());
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
    __ incl(compiler::FieldAddress(EDI, Function::usage_counter_offset()));
    __ cmpl(compiler::FieldAddress(EDI, Function::usage_counter_offset()),
            compiler::Immediate(threshold));
    __ j(GREATER_EQUAL, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    // TODO(turnidge): Implement stack overflow count in assembly to
    // make --stacktrace-every and --deoptimize-every faster.
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
    // shll operation masks the count to 5 bits.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      if (value == 1) {
        // Use overflow flag.
        __ shll(left, compiler::Immediate(1));
        __ j(OVERFLOW, deopt);
        return;
      }
      // Check for overflow.
      Register temp = locs.temp(0).reg();
      __ movl(temp, left);
      __ shll(left, compiler::Immediate(value));
      __ sarl(left, compiler::Immediate(value));
      __ cmpl(left, temp);
      __ j(NOT_EQUAL, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ shll(left, compiler::Immediate(value));
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for can_overflow().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ cmpl(right, compiler::Immediate(0));
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ cmpl(right,
                compiler::Immediate(static_cast<int32_t>(Smi::New(max_right))));
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ shll(left, right);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  ASSERT(right == ECX);  // Count must be in ECX
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmpl(right, compiler::Immediate(0));
        __ j(NEGATIVE, deopt);
      }
      compiler::Label done, is_not_zero;
      __ cmpl(right,
              compiler::Immediate(static_cast<int32_t>(Smi::New(Smi::kBits))));
      __ j(BELOW, &is_not_zero, compiler::Assembler::kNearJump);
      __ xorl(left, left);
      __ jmp(&done, compiler::Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(right);
      __ shll(left, right);
      __ Bind(&done);
    } else {
      __ SmiUntag(right);
      __ shll(left, right);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ cmpl(right,
              compiler::Immediate(static_cast<int32_t>(Smi::New(Smi::kBits))));
      __ j(ABOVE_EQUAL, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ movl(temp, left);
    __ SmiUntag(right);
    // Overflow test (preserve temp and right);
    __ shll(left, right);
    __ sarl(left, right);
    __ cmpl(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ shll(left, right);
  }
}

static bool IsSmiValue(const Object& constant, intptr_t value) {
  return constant.IsSmi() && (Smi::Cast(constant).Value() == value);
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (RightIsPowerOfTwoConstant()) {
      summary->set_in(0, Location::RequiresRegister());
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      // The programmer only controls one bit, so the constant is safe.
      summary->set_in(1, Location::Constant(right_constant));
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_out(0, Location::SameAsFirstInput());
    } else {
      // Both inputs must be writable because they will be untagged.
      summary->set_in(0, Location::RegisterLocation(EAX));
      summary->set_in(1, Location::WritableRegister());
      summary->set_out(0, Location::SameAsFirstInput());
      // Will be used for sign extension and division.
      summary->set_temp(0, Location::RegisterLocation(EDX));
    }
    return summary;
  } else if (op_kind() == Token::kMOD) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(EDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(EAX));
    return summary;
  } else if ((op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR)) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    ConstantInstr* right_constant = right()->definition()->AsConstant();
    // Shift-by-1 overflow checking can use flags, otherwise we need a temp.
    const bool shiftBy1 =
        (right_constant != nullptr) && IsSmiValue(right_constant->value(), 1);
    const intptr_t kNumTemps = (can_overflow() && !shiftBy1) ? 1 : 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
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

template <typename OperandType>
static void EmitIntegerArithmetic(FlowGraphCompiler* compiler,
                                  Token::Kind op_kind,
                                  Register left,
                                  const OperandType& right,
                                  compiler::Label* deopt) {
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
  if (deopt != nullptr) __ j(OVERFLOW, deopt);
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
    const intptr_t value = Smi::Cast(constant).Value();
    switch (op_kind()) {
      case Token::kADD:
      case Token::kSUB:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
      case Token::kMUL: {
        const intptr_t imm =
            (op_kind() == Token::kMUL) ? value : Smi::RawValue(value);
        EmitIntegerArithmetic(compiler, op_kind(), left,
                              compiler::Immediate(imm), deopt);
        break;
      }

      case Token::kTRUNCDIV: {
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        Register temp = locs()->temp(0).reg();
        __ movl(temp, left);
        __ sarl(temp, compiler::Immediate(31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        __ shrl(temp, compiler::Immediate(32 - shift_count));
        __ addl(left, temp);
        ASSERT(shift_count > 0);
        __ sarl(left, compiler::Immediate(shift_count));
        if (value < 0) {
          __ negl(left);
        }
        __ SmiTag(left);
        break;
      }

      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ sarl(left, compiler::Immediate(
                          Utils::Minimum(value + kSmiTagSize, kCountLimit)));
        __ SmiTag(left);
        break;
      }

      case Token::kUSHR: {
        ASSERT((value > 0) && (value < 64));
        COMPILE_ASSERT(compiler::target::kSmiBits < 32);
        // 64-bit representation of left operand value:
        //
        //       ss...sssss  s  s  xxxxxxxxxxxxx
        //       |        |  |  |  |           |
        //       63      32  31 30 kSmiBits-1  0
        //
        // Where 's' is a sign bit.
        //
        // If left operand is negative (sign bit is set), then
        // result will fit into Smi range if and only if
        // the shift amount >= 64 - kSmiBits.
        //
        // If left operand is non-negative, the result always
        // fits into Smi range.
        //
        if (value < (64 - compiler::target::kSmiBits)) {
          if (deopt != nullptr) {
            __ testl(left, left);
            __ j(LESS, deopt);
          } else {
            // Operation cannot overflow only if left value is always
            // non-negative.
            ASSERT(!can_overflow());
          }
          // At this point left operand is non-negative, so unsigned shift
          // can't overflow.
          if (value >= compiler::target::kSmiBits) {
            __ xorl(left, left);
          } else {
            __ shrl(left, compiler::Immediate(value + kSmiTagSize));
            __ SmiTag(left);
          }
        } else {
          // Shift amount > 32, and the result is guaranteed to fit into Smi.
          // Low (Smi) part of the left operand is shifted out.
          // High part is filled with sign bits.
          __ sarl(left, compiler::Immediate(31));
          __ shrl(left, compiler::Immediate(value - 32));
          __ SmiTag(left);
        }
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // if locs()->in(1).IsConstant()

  if (locs()->in(1).IsStackSlot()) {
    const compiler::Address& right = LocationToStackSlotAddress(locs()->in(1));
    if (op_kind() == Token::kMUL) {
      __ SmiUntag(left);
    }
    EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
    return;
  }

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kMUL:
      if (op_kind() == Token::kMUL) {
        __ SmiUntag(left);
      }
      EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
      break;

    case Token::kTRUNCDIV: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testl(right, right);
        __ j(ZERO, deopt);
      }
      ASSERT(left == EAX);
      ASSERT((right != EDX) && (right != EAX));
      ASSERT(locs()->temp(0).reg() == EDX);
      ASSERT(result == EAX);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ cdq();         // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ cmpl(result, compiler::Immediate(0x40000000));
        __ j(EQUAL, deopt);
      }
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testl(right, right);
        __ j(ZERO, deopt);
      }
      ASSERT(left == EDX);
      ASSERT((right != EDX) && (right != EAX));
      ASSERT(locs()->temp(0).reg() == EAX);
      ASSERT(result == EDX);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movl(EAX, EDX);
      __ cdq();         // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      compiler::Label done;
      __ cmpl(result, compiler::Immediate(0));
      __ j(GREATER_EQUAL, &done, compiler::Assembler::kNearJump);
      // Result is negative, adjust it.
      if (RangeUtils::Overlaps(right_range(), -1, 1)) {
        // Right can be positive and negative.
        compiler::Label subtract;
        __ cmpl(right, compiler::Immediate(0));
        __ j(LESS, &subtract, compiler::Assembler::kNearJump);
        __ addl(result, right);
        __ jmp(&done, compiler::Assembler::kNearJump);
        __ Bind(&subtract);
        __ subl(result, right);
      } else if (right_range()->IsPositive()) {
        // Right is positive.
        __ addl(result, right);
      } else {
        // Right is negative.
        __ subl(result, right);
      }
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ cmpl(right, compiler::Immediate(0));
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarl operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ cmpl(right, compiler::Immediate(kCountLimit));
        compiler::Label count_ok;
        __ j(LESS, &count_ok, compiler::Assembler::kNearJump);
        __ movl(right, compiler::Immediate(kCountLimit));
        __ Bind(&count_ok);
      }
      ASSERT(right == ECX);  // Count must be in ECX
      __ SmiUntag(left);
      __ sarl(left, right);
      __ SmiTag(left);
      break;
    }
    case Token::kUSHR: {
      compiler::Label done;
      __ SmiUntag(right);
      // 64-bit representation of left operand value:
      //
      //       ss...sssss  s  s  xxxxxxxxxxxxx
      //       |        |  |  |  |           |
      //       63      32  31 30 kSmiBits-1  0
      //
      // Where 's' is a sign bit.
      //
      // If left operand is negative (sign bit is set), then
      // result will fit into Smi range if and only if
      // the shift amount >= 64 - kSmiBits.
      //
      // If left operand is non-negative, the result always
      // fits into Smi range.
      //
      if (!RangeUtils::OnlyLessThanOrEqualTo(
              right_range(), 64 - compiler::target::kSmiBits - 1)) {
        __ cmpl(right, compiler::Immediate(64 - compiler::target::kSmiBits));
        compiler::Label shift_less_34;
        __ j(LESS, &shift_less_34, compiler::Assembler::kNearJump);
        if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(),
                                               kBitsPerInt64 - 1)) {
          __ cmpl(right, compiler::Immediate(kBitsPerInt64));
          compiler::Label shift_less_64;
          __ j(LESS, &shift_less_64, compiler::Assembler::kNearJump);
          // Shift amount >= 64. Result is 0.
          __ xorl(left, left);
          __ jmp(&done, compiler::Assembler::kNearJump);
          __ Bind(&shift_less_64);
        }
        // Shift amount >= 64 - kSmiBits > 32, but < 64.
        // Result is guaranteed to fit into Smi range.
        // Low (Smi) part of the left operand is shifted out.
        // High part is filled with sign bits.
        ASSERT(right == ECX);  // Count must be in ECX
        __ subl(right, compiler::Immediate(32));
        __ sarl(left, compiler::Immediate(31));
        __ shrl(left, right);
        __ SmiTag(left);
        __ jmp(&done, compiler::Assembler::kNearJump);
        __ Bind(&shift_less_34);
      }
      // Shift amount < 64 - kSmiBits.
      // If left is negative, then result will not fit into Smi range.
      // Also deopt in case of negative shift amount.
      if (deopt != nullptr) {
        __ testl(left, left);
        __ j(LESS, deopt);
        __ testl(right, right);
        __ j(LESS, deopt);
      } else {
        ASSERT(!can_overflow());
      }
      // At this point left operand is non-negative, so unsigned shift
      // can't overflow.
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(),
                                             compiler::target::kSmiBits - 1)) {
        __ cmpl(right, compiler::Immediate(compiler::target::kSmiBits));
        compiler::Label shift_less_30;
        __ j(LESS, &shift_less_30, compiler::Assembler::kNearJump);
        // Left operand >= 0, shift amount >= kSmiBits. Result is 0.
        __ xorl(left, left);
        __ jmp(&done, compiler::Assembler::kNearJump);
        __ Bind(&shift_less_30);
      }
      // Left operand >= 0, shift amount < kSmiBits < 32.
      ASSERT(right == ECX);  // Count must be in ECX
      __ SmiUntag(left);
      __ shrl(left, right);
      __ SmiTag(left);
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

LocationSummary* BinaryInt32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    UNREACHABLE();
    return nullptr;
  } else if (op_kind() == Token::kMOD) {
    UNREACHABLE();
    return nullptr;
  } else if ((op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR)) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    const intptr_t kNumTemps = can_overflow() ? 1 : 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
    if (can_overflow()) {
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

static void EmitInt32ShiftLeft(FlowGraphCompiler* compiler,
                               BinaryInt32OpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  ASSERT(left == result);
  compiler::Label* deopt =
      shift_left->CanDeoptimize()
          ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                   ICData::kDeoptBinarySmiOp)
          : nullptr;
  ASSERT(locs.in(1).IsConstant());

  const Object& constant = locs.in(1).constant();
  ASSERT(constant.IsSmi());
  // shll operation masks the count to 5 bits.
  const intptr_t kCountLimit = 0x1F;
  const intptr_t value = Smi::Cast(constant).Value();
  ASSERT((0 < value) && (value < kCountLimit));
  if (shift_left->can_overflow()) {
    // Check for overflow.
    Register temp = locs.temp(0).reg();
    __ movl(temp, left);
    __ shll(left, compiler::Immediate(value));
    __ sarl(left, compiler::Immediate(value));
    __ cmpl(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
  }
  // Shift for result now we know there is no overflow.
  __ shll(left, compiler::Immediate(value));
}

void BinaryInt32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitInt32ShiftLeft(compiler, this);
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
    const intptr_t value = Smi::Cast(constant).Value();
    switch (op_kind()) {
      case Token::kADD:
      case Token::kSUB:
      case Token::kMUL:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        EmitIntegerArithmetic(compiler, op_kind(), left,
                              compiler::Immediate(value), deopt);
        break;

      case Token::kTRUNCDIV: {
        UNREACHABLE();
        break;
      }

      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ sarl(left, compiler::Immediate(Utils::Minimum(value, kCountLimit)));
        break;
      }

      case Token::kUSHR: {
        ASSERT((value > 0) && (value < 64));
        // 64-bit representation of left operand value:
        //
        //       ss...sssss  s  xxxxxxxxxxxxx
        //       |        |  |  |           |
        //       63      32  31 30          0
        //
        // Where 's' is a sign bit.
        //
        // If left operand is negative (sign bit is set), then
        // result will fit into Int32 range if and only if
        // the shift amount > 32.
        //
        if (value <= 32) {
          if (deopt != nullptr) {
            __ testl(left, left);
            __ j(LESS, deopt);
          } else {
            // Operation cannot overflow only if left value is always
            // non-negative.
            ASSERT(!can_overflow());
          }
          // At this point left operand is non-negative, so unsigned shift
          // can't overflow.
          if (value == 32) {
            __ xorl(left, left);
          } else {
            __ shrl(left, compiler::Immediate(value));
          }
        } else {
          // Shift amount > 32.
          // Low (Int32) part of the left operand is shifted out.
          // Shift high part which is filled with sign bits.
          __ sarl(left, compiler::Immediate(31));
          __ shrl(left, compiler::Immediate(value - 32));
        }
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // if locs()->in(1).IsConstant()

  if (locs()->in(1).IsStackSlot()) {
    const compiler::Address& right = LocationToStackSlotAddress(locs()->in(1));
    EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
    return;
  }  // if locs()->in(1).IsStackSlot.

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
      break;

    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kMUL) {
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_temp(0, Location::RegisterLocation(EDX));
  } else {
    summary->set_in(0, Location::RequiresRegister());
  }
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
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
      EmitIntegerArithmetic(compiler, op_kind(), left, right, nullptr);
      return;

    case Token::kMUL:
      __ mull(right);  // Result in EDX:EAX.
      ASSERT(out == EAX);
      ASSERT(locs()->temp(0).reg() == EDX);
      break;
    default:
      UNREACHABLE();
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
    __ testl(left, compiler::Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ testl(right, compiler::Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testl(left, compiler::Immediate(kSmiTagMask));
  } else {
    Register temp = locs()->temp(0).reg();
    __ movl(temp, left);
    __ orl(temp, right);
    __ testl(temp, compiler::Immediate(kSmiTagMask));
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
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, locs()->temp(0).reg());

  switch (from_representation()) {
    case kUnboxedDouble:
      __ movsd(compiler::FieldAddress(out_reg, ValueOffset()), value);
      break;
    case kUnboxedFloat:
      __ cvtss2sd(FpuTMP, value);
      __ movsd(compiler::FieldAddress(out_reg, ValueOffset()), FpuTMP);
      break;
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
  ASSERT(BoxCid() != kSmiCid);
  const bool needs_temp =
      CanDeoptimize() ||
      (CanConvertSmi() && (value()->Type()->ToCid() == kSmiCid));

  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (needs_temp) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                       Location::RegisterLocation(EDX)));
  } else if (representation() == kUnboxedInt32) {
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
      PairLocation* result = locs()->out(0).AsPairLocation();
      ASSERT(result->At(0).reg() != box);
      __ movl(result->At(0).reg(), compiler::FieldAddress(box, ValueOffset()));
      __ movl(result->At(1).reg(),
              compiler::FieldAddress(box, ValueOffset() + kWordSize));
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
    case kUnboxedInt64: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      ASSERT(result->At(0).reg() == EAX);
      ASSERT(result->At(1).reg() == EDX);
      __ movl(EAX, box);
      __ SmiUntag(EAX);
      __ cdq();
      break;
    }

    case kUnboxedDouble: {
      const Register temp = locs()->temp(0).reg();
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movl(temp, box);
      __ SmiUntag(temp);
      __ cvtsi2sd(result, temp);
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
  __ SmiUntag(value);  // Leaves CF after SmiUntag.
  __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
  __ movl(result, compiler::FieldAddress(value, Mint::value_offset()));
  __ Bind(&done);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();
  PairLocation* result = locs()->out(0).AsPairLocation();
  ASSERT(result->At(0).reg() != box);
  ASSERT(result->At(1).reg() != box);
  compiler::Label done;
  EmitSmiConversion(compiler);  // Leaves CF after SmiUntag.
  __ j(NOT_CARRY, &done, compiler::Assembler::kNearJump);
  EmitLoadFromBox(compiler);
  __ Bind(&done);
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  if (ValueFitsSmi()) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Same regs, can overwrite input.
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    LocationSummary* summary = new (zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
    // Guaranteed different regs.  In the signed case we are going to use the
    // input for sign extension of any Mint.
    const bool needs_writable_input = (from_representation() == kUnboxedInt32);
    summary->set_in(0, needs_writable_input ? Location::WritableRegister()
                                            : Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();

  if (ValueFitsSmi()) {
    ASSERT(value == out);
    ASSERT(kSmiTag == 0);
    __ shll(out, compiler::Immediate(kSmiTagSize));
    return;
  }

  __ movl(out, value);
  __ shll(out, compiler::Immediate(kSmiTagSize));
  compiler::Label done;
  if (from_representation() == kUnboxedInt32) {
    __ j(NO_OVERFLOW, &done);
  } else {
    ASSERT(value != out);  // Value was not overwritten.
    __ testl(value, compiler::Immediate(0xC0000000));
    __ j(ZERO, &done);
  }

  // Allocate a Mint.
  if (from_representation() == kUnboxedInt32) {
    // Value input is a writable register and should be manually preserved
    // across allocation slow-path.  Add it to live_registers set which
    // determines which registers to preserve.
    locs()->live_registers()->Add(locs()->in(0), kUnboxedInt32);
  }
  ASSERT(value != out);  // We need the value after the allocation.
  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  locs()->temp(0).reg());
  __ movl(compiler::FieldAddress(out, Mint::value_offset()), value);
  if (from_representation() == kUnboxedInt32) {
    // In the signed may-overflow case we asked for the input (value) to be
    // writable so we can use it as a temp to put the sign extension bits in.
    __ sarl(value, compiler::Immediate(31));  // Sign extend the Mint.
    __ movl(compiler::FieldAddress(out, Mint::value_offset() + kWordSize),
            value);
  } else {
    __ movl(compiler::FieldAddress(out, Mint::value_offset() + kWordSize),
            compiler::Immediate(0));  // Zero extend the Mint.
  }
  __ Bind(&done);
}

LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      ValueFitsSmi() ? LocationSummary::kNoCall
                                     : LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  if (!ValueFitsSmi()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInt64Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (ValueFitsSmi()) {
    PairLocation* value_pair = locs()->in(0).AsPairLocation();
    Register value_lo = value_pair->At(0).reg();
    Register out_reg = locs()->out(0).reg();
    __ movl(out_reg, value_lo);
    __ SmiTag(out_reg);
    return;
  }

  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register out_reg = locs()->out(0).reg();

  // Copy value_hi into out_reg as a temporary.
  // We modify value_lo but restore it before using it.
  __ movl(out_reg, value_hi);

  // Unboxed operations produce smis or mint-sized values.
  // Check if value fits into a smi.
  compiler::Label not_smi, done;

  // 1. Compute (x + -kMinSmi) which has to be in the range
  //    0 .. -kMinSmi+kMaxSmi for x to fit into a smi.
  __ addl(value_lo, compiler::Immediate(0x40000000));
  __ adcl(out_reg, compiler::Immediate(0));
  // 2. Unsigned compare to -kMinSmi+kMaxSmi.
  __ cmpl(value_lo, compiler::Immediate(0x80000000));
  __ sbbl(out_reg, compiler::Immediate(0));
  __ j(ABOVE_EQUAL, &not_smi);
  // 3. Restore lower half if result is a smi.
  __ subl(value_lo, compiler::Immediate(0x40000000));
  __ movl(out_reg, value_lo);
  __ SmiTag(out_reg);
  __ jmp(&done);
  __ Bind(&not_smi);
  // 3. Restore lower half of input before using it.
  __ subl(value_lo, compiler::Immediate(0x40000000));

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                  out_reg, locs()->temp(0).reg());
  __ movl(compiler::FieldAddress(out_reg, Mint::value_offset()), value_lo);
  __ movl(compiler::FieldAddress(out_reg, Mint::value_offset() + kWordSize),
          value_hi);
  __ Bind(&done);
}

LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  intptr_t kNumTemps = 0;

  if (CanDeoptimize()) {
    if ((value_cid != kSmiCid) && (value_cid != kMintCid) && !is_truncating()) {
      kNumTemps = 2;
    } else {
      kNumTemps = 1;
    }
  }

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  for (int i = 0; i < kNumTemps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }
  summary->set_out(0, ((value_cid == kSmiCid) || (value_cid != kMintCid))
                          ? Location::SameAsFirstInput()
                          : Location::RequiresRegister());
  return summary;
}

static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register result,
                              const compiler::Address& lo,
                              const compiler::Address& hi,
                              Register temp,
                              compiler::Label* deopt) {
  __ movl(result, lo);
  if (deopt != nullptr) {
    ASSERT(temp != result);
    __ movl(temp, result);
    __ sarl(temp, compiler::Immediate(31));
    __ cmpl(temp, hi);
    __ j(NOT_EQUAL, deopt);
  }
}

void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  const Register temp = CanDeoptimize() ? locs()->temp(0).reg() : kNoRegister;
  compiler::Label* deopt = nullptr;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger);
  }
  compiler::Label* out_of_range = !is_truncating() ? deopt : nullptr;

  const intptr_t lo_offset = Mint::value_offset();
  const intptr_t hi_offset = Mint::value_offset() + kWordSize;

  if (value_cid == kSmiCid) {
    ASSERT(value == result);
    __ SmiUntag(value);
  } else if (value_cid == kMintCid) {
    ASSERT((value != result) || (out_of_range == nullptr));
    LoadInt32FromMint(
        compiler, result, compiler::FieldAddress(value, lo_offset),
        compiler::FieldAddress(value, hi_offset), temp, out_of_range);
  } else if (!CanDeoptimize()) {
    ASSERT(value == result);
    compiler::Label done;
    __ SmiUntag(value);
    __ j(NOT_CARRY, &done);
    __ movl(value, compiler::Address(value, TIMES_2, lo_offset));
    __ Bind(&done);
  } else {
    ASSERT(value == result);
    compiler::Label done;
    __ SmiUntagOrCheckClass(value, kMintCid, temp, &done);
    __ j(NOT_EQUAL, deopt);
    if (out_of_range != nullptr) {
      Register value_temp = locs()->temp(1).reg();
      __ movl(value_temp, value);
      value = value_temp;
    }
    LoadInt32FromMint(
        compiler, result, compiler::Address(value, TIMES_2, lo_offset),
        compiler::Address(value, TIMES_2, hi_offset), temp, out_of_range);
    __ Bind(&done);
  }
}

LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const bool might_box = (representation() == kTagged) && !can_pack_into_smi();
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = might_box ? 2 : 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      might_box ? LocationSummary::kCallOnSlowPath : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  summary->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                          : Location::RequiresRegister());
  if (might_box) {
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  }

  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT(representation() == kTagged);
    summary->set_out(0, Location::RequiresRegister());
  }

  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);

  bool index_unboxed = false;
  if ((index_scale() == 1)) {
    __ SmiUntag(index.reg());
    index_unboxed = true;
  }
  compiler::Address element_address =
      compiler::Assembler::ElementAddressForRegIndex(
          IsExternal(), class_id(), index_scale(), index_unboxed, str,
          index.reg());

  if (representation() == kUnboxedInt64) {
    ASSERT(compiler->is_optimizing());
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* result_pair = locs()->out(0).AsPairLocation();
    Register result1 = result_pair->At(0).reg();
    Register result2 = result_pair->At(1).reg();

    switch (class_id()) {
      case kOneByteStringCid:
      case kExternalOneByteStringCid:
        ASSERT(element_count() == 4);
        __ movl(result1, element_address);
        __ xorl(result2, result2);
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        ASSERT(element_count() == 2);
        __ movl(result1, element_address);
        __ xorl(result2, result2);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    ASSERT(representation() == kTagged);
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
        break;
      default:
        UNREACHABLE();
        break;
    }
    if (can_pack_into_smi()) {
      __ SmiTag(result);
    } else {
      // If the value cannot fit in a smi then allocate a mint box for it.
      Register temp = locs()->temp(0).reg();
      Register temp2 = locs()->temp(1).reg();
      // Temp register needs to be manually preserved on allocation slow-path.
      // Add it to live_registers set which determines which registers to
      // preserve.
      locs()->live_registers()->Add(locs()->temp(0), kUnboxedInt32);

      ASSERT(temp != result);
      __ MoveRegister(temp, result);
      __ SmiTag(result);

      compiler::Label done;
      __ testl(temp, compiler::Immediate(0xC0000000));
      __ j(ZERO, &done);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                      result, temp2);
      __ movl(compiler::FieldAddress(result, Mint::value_offset()), temp);
      __ movl(compiler::FieldAddress(result, Mint::value_offset() + kWordSize),
              compiler::Immediate(0));
      __ Bind(&done);
    }
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
    compiler::Label check_upper;
    __ AddImmediate(ESP, compiler::Immediate(-kDoubleSize));
    __ movsd(compiler::Address(ESP, 0), value);
    __ movl(temp, compiler::Address(ESP, 0));
    // If the low word isn't zero, then it isn't infinity.
    __ cmpl(temp, compiler::Immediate(0));
    __ j(EQUAL, &check_upper, compiler::Assembler::kNearJump);
    __ AddImmediate(ESP, compiler::Immediate(kDoubleSize));
    __ jmp(is_negated ? labels.true_label : labels.false_label);
    __ Bind(&check_upper);
    // Check the high word.
    __ movl(temp, compiler::Address(ESP, kWordSize));
    __ AddImmediate(ESP, compiler::Immediate(kDoubleSize));
    // Mask off sign bit.
    __ andl(temp, compiler::Immediate(0x7FFFFFFF));
    // Compare with +infinity.
    __ cmpl(temp, compiler::Immediate(0x7FF00000));
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
      // TODO(dartbug.com/30949) avoid transfer through memory
      COMPILE_ASSERT(SimdOpInstr::kFloat64x2WithY ==
                     (SimdOpInstr::kFloat64x2WithX + 1));
      const intptr_t lane_index = instr->kind() - SimdOpInstr::kFloat64x2WithX;
      ASSERT(0 <= lane_index && lane_index < 2);
      __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
      __ movups(compiler::Address(ESP, 0), left);
      __ movsd(compiler::Address(ESP, lane_index * kDoubleSize), right);
      __ movups(left, compiler::Address(ESP, 0));
      __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
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
      __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
      __ movups(compiler::Address(ESP, 0), right);
      __ movss(compiler::Address(ESP, lane_index * kFloatSize), left);
      __ movups(left, compiler::Address(ESP, 0));
      __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
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
  V(Float32x4Reciprocal, reciprocalps)                                         \
  V(Float32x4ReciprocalSqrt, rsqrtps)

DEFINE_EMIT(SimdUnaryOp, (SameAsFirstInput, XmmRegister value)) {
  // TODO(dartbug.com/30949) select better register constraints to avoid
  // redundant move of input into a different register because all instructions
  // below support two operand forms.
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(value);                                                              \
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
    case SimdOpInstr::kFloat64x2ToFloat32x4:
      __ cvtpd2ps(value, value);
      break;
    case SimdOpInstr::kFloat32x4ToFloat64x2:
      __ cvtps2pd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ToInt32x4:
    case SimdOpInstr::kInt32x4ToFloat32x4:
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
  __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ cvtsd2ss(out, instr->locs()->in(i).fpu_reg());
    __ movss(compiler::Address(ESP, i * kFloatSize), out);
  }
  __ movups(out, compiler::Address(ESP, 0));
  __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
}

DEFINE_EMIT(Float32x4Zero, (XmmRegister out)) {
  __ xorps(out, out);
}

DEFINE_EMIT(Float64x2Zero, (XmmRegister value)) {
  __ xorpd(value, value);
}

DEFINE_EMIT(Float32x4Clamp,
            (SameAsFirstInput,
             XmmRegister left,
             XmmRegister lower,
             XmmRegister upper)) {
  __ minps(left, upper);
  __ maxps(left, lower);
}

DEFINE_EMIT(Float64x2Clamp,
            (SameAsFirstInput,
             XmmRegister left,
             XmmRegister lower,
             XmmRegister upper)) {
  __ minpd(left, upper);
  __ maxpd(left, lower);
}

DEFINE_EMIT(Int32x4FromInts,
            (XmmRegister result, Register, Register, Register, Register)) {
  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ movl(compiler::Address(ESP, i * kInt32Size), instr->locs()->in(i).reg());
  }
  __ movups(result, compiler::Address(ESP, 0));
  __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
}

DEFINE_EMIT(Int32x4FromBools,
            (XmmRegister result, Register, Register, Register, Register)) {
  // TODO(dartbug.com/30949) avoid transfer through memory and branches.
  __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    compiler::Label store_false, done;
    __ CompareObject(instr->locs()->in(i).reg(), Bool::True());
    __ j(NOT_EQUAL, &store_false);
    __ movl(compiler::Address(ESP, kInt32Size * i),
            compiler::Immediate(0xFFFFFFFF));
    __ jmp(&done);
    __ Bind(&store_false);
    __ movl(compiler::Address(ESP, kInt32Size * i), compiler::Immediate(0x0));
    __ Bind(&done);
  }
  __ movups(result, compiler::Address(ESP, 0));
  __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
}

// TODO(dartbug.com/30953) need register with a byte component for setcc.
DEFINE_EMIT(Int32x4GetFlag, (Fixed<Register, EDX> result, XmmRegister value)) {
  COMPILE_ASSERT(
      SimdOpInstr::kInt32x4GetFlagY == (SimdOpInstr::kInt32x4GetFlagX + 1) &&
      SimdOpInstr::kInt32x4GetFlagZ == (SimdOpInstr::kInt32x4GetFlagX + 2) &&
      SimdOpInstr::kInt32x4GetFlagW == (SimdOpInstr::kInt32x4GetFlagX + 3));
  const intptr_t lane_index = instr->kind() - SimdOpInstr::kInt32x4GetFlagX;
  ASSERT(0 <= lane_index && lane_index < 4);

  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
  __ movups(compiler::Address(ESP, 0), value);
  __ movl(EDX, compiler::Address(ESP, lane_index * kInt32Size));
  __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));

  // EDX = EDX != 0 ? 0 : 1
  __ testl(EDX, EDX);
  __ setcc(ZERO, DL);
  __ movzxb(EDX, DL);

  ASSERT_BOOL_FALSE_FOLLOWS_BOOL_TRUE();
  __ movl(EDX,
          compiler::Address(THR, EDX, TIMES_4, Thread::bool_true_offset()));
}

// TODO(dartbug.com/30953) need register with a byte component for setcc.
DEFINE_EMIT(Int32x4WithFlag,
            (SameAsFirstInput,
             XmmRegister mask,
             Register flag,
             Temp<Fixed<Register, EDX> > temp)) {
  COMPILE_ASSERT(
      SimdOpInstr::kInt32x4WithFlagY == (SimdOpInstr::kInt32x4WithFlagX + 1) &&
      SimdOpInstr::kInt32x4WithFlagZ == (SimdOpInstr::kInt32x4WithFlagX + 2) &&
      SimdOpInstr::kInt32x4WithFlagW == (SimdOpInstr::kInt32x4WithFlagX + 3));
  const intptr_t lane_index = instr->kind() - SimdOpInstr::kInt32x4WithFlagX;
  ASSERT(0 <= lane_index && lane_index < 4);

  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, compiler::Immediate(kSimd128Size));
  __ movups(compiler::Address(ESP, 0), mask);

  // EDX = flag == true ? -1 : 0
  __ xorl(EDX, EDX);
  __ CompareObject(flag, Bool::True());
  __ setcc(EQUAL, DL);
  __ negl(EDX);

  __ movl(compiler::Address(ESP, lane_index * kInt32Size), EDX);

  // Copy mask back to register.
  __ movups(mask, compiler::Address(ESP, 0));
  __ AddImmediate(ESP, compiler::Immediate(kSimd128Size));
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
  __ notps(temp);
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
  CASE(Int32x4GetFlagZ)                                                        \
  CASE(Int32x4GetFlagW)                                                        \
  ____(Int32x4GetFlag)                                                         \
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
      UNREACHABLE();
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
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_in(3, Location::RegisterLocation(EBX));
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void CaseInsensitiveCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/4 * compiler::target::kWordSize,
                                /*preserve_registers=*/false);
  __ movl(compiler::Address(ESP, +0 * kWordSize), locs()->in(0).reg());
  __ movl(compiler::Address(ESP, +1 * kWordSize), locs()->in(1).reg());
  __ movl(compiler::Address(ESP, +2 * kWordSize), locs()->in(2).reg());
  __ movl(compiler::Address(ESP, +3 * kWordSize), locs()->in(3).reg());
  rt.Call(TargetFunction(), 4);
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
  const bool is_min = (op_kind() == MethodRecognizer::kMathMin);
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
    static double kNaN = NAN;
    __ movsd(result,
             compiler::Address::Absolute(reinterpret_cast<uword>(&kNaN)));
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
    __ testl(temp, compiler::Immediate(1));
    ASSERT(left == result);
    if (is_min) {
      __ j(NOT_ZERO, &done,
           compiler::Assembler::kNearJump);  // Negative -> return left.
    } else {
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
  __ cmpl(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgel(result, right);
  } else {
    __ cmovlessl(result, right);
  }
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
      __ negl(value);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ notl(value);
      __ andl(value,
              compiler::Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
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
  __ DoubleNegate(value);
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
  __ cvtsi2sd(result, value);
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
  __ cvtsi2sd(result, value);
}

LocationSummary* Int64ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* pair = locs()->in(0).AsPairLocation();
  Register in_lo = pair->At(0).reg();
  Register in_hi = pair->At(1).reg();

  FpuRegister result = locs()->out(0).fpu_reg();

  // Push hi.
  __ pushl(in_hi);
  // Push lo.
  __ pushl(in_lo);
  // Perform conversion from Mint to double.
  __ fildl(compiler::Address(ESP, 0));
  // Pop FPU stack onto regular stack.
  __ fstpl(compiler::Address(ESP, 0));
  // Copy into result.
  __ movsd(result, compiler::Address(ESP, 0));
  // Pop args.
  __ addl(ESP, compiler::Immediate(2 * kWordSize));
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
  ASSERT(recognized_kind() == MethodRecognizer::kDoubleToInteger);
  const Register result = locs()->out(0).reg();
  const XmmRegister value_double = locs()->in(0).fpu_reg();

  DoubleToIntegerSlowPath* slow_path =
      new DoubleToIntegerSlowPath(this, value_double);
  compiler->AddSlowPathCode(slow_path);

  __ cvttsd2si(result, value_double);
  // Overflow is signalled with minint.
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, compiler::Immediate(0xC0000000));
  __ j(NEGATIVE, slow_path->entry_label());
  __ SmiTag(result);
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
  Register result = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  __ cvttsd2si(result, value);
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, compiler::Immediate(0xC0000000));
  __ j(NEGATIVE, deopt);
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
    case MethodRecognizer::kDoubleTruncateToDouble:
      __ roundsd(result, value, compiler::Assembler::kRoundToZero);
      break;
    case MethodRecognizer::kDoubleFloorToDouble:
      __ roundsd(result, value, compiler::Assembler::kRoundDown);
      break;
    case MethodRecognizer::kDoubleCeilToDouble:
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
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 4 : 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  // EDI is chosen because it is callee saved so we do not need to back it
  // up before calling into the runtime.
  result->set_temp(0, Location::RegisterLocation(EDI));
  result->set_in(0, Location::FpuRegisterLocation(XMM1));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM2));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Temp index 1.
    result->set_temp(1, Location::RegisterLocation(EAX));
    // Temp index 2.
    result->set_temp(2, Location::FpuRegisterLocation(XMM4));
    // We need to block XMM0 for the floating-point calling convention.
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

  __ xorps(zero_temp, zero_temp);  // 0.0.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1.0)));
  __ movsd(result, compiler::FieldAddress(temp, Double::value_offset()));

  compiler::Label check_base, skip_call;
  // exponent == 0.0 -> return 1.0;
  __ comisd(exp, zero_temp);
  __ j(PARITY_EVEN, &check_base);
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

  // base == 1.0 -> return 1.0;
  __ comisd(base, result);
  compiler::Label return_nan;
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
  {
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/kDoubleSize * kInputCount,
                                  /*preserve_registers=*/false);
    for (intptr_t i = 0; i < kInputCount; i++) {
      __ movsd(compiler::Address(ESP, kDoubleSize * i), locs->in(i).fpu_reg());
    }
    rt.Call(instr->TargetFunction(), kInputCount);
    __ fstpl(compiler::Address(ESP, 0));
    __ movsd(locs->out(0).fpu_reg(), compiler::Address(ESP, 0));
  }
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }

  {
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/kDoubleSize * InputCount(),
                                  /*preserve_registers=*/false);
    for (intptr_t i = 0; i < InputCount(); i++) {
      __ movsd(compiler::Address(ESP, kDoubleSize * i),
               locs()->in(i).fpu_reg());
    }
    rt.Call(TargetFunction(), InputCount());
    __ fstpl(compiler::Address(ESP, 0));
    __ movsd(locs()->out(0).fpu_reg(), compiler::Address(ESP, 0));
  }
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
    __ movl(out, in);
  }
}

LocationSummary* TruncDivModInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Both inputs must be writable because they will be untagged.
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::WritableRegister());
  // Output is a pair of registers.
  summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                     Location::RegisterLocation(EDX)));
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
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ testl(right, right);
    __ j(ZERO, deopt);
  }
  ASSERT(left == EAX);
  ASSERT((right != EDX) && (right != EAX));
  ASSERT(result1 == EAX);
  ASSERT(result2 == EDX);
  __ SmiUntag(left);
  __ SmiUntag(right);
  __ cdq();         // Sign extend EAX -> EDX:EAX.
  __ idivl(right);  //  EAX: quotient, EDX: remainder.
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  // TODO(srdjan): We could store instead untagged intermediate results in a
  // typed array, but then the load indexed instructions would need to be
  // able to deoptimize.
  __ cmpl(EAX, compiler::Immediate(0x40000000));
  __ j(EQUAL, deopt);
  // Modulo result (EDX) correction:
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  compiler::Label done;
  __ cmpl(EDX, compiler::Immediate(0));
  __ j(GREATER_EQUAL, &done, compiler::Assembler::kNearJump);
  // Result is negative, adjust it.
  if (RangeUtils::Overlaps(divisor_range(), -1, 1)) {
    compiler::Label subtract;
    __ cmpl(right, compiler::Immediate(0));
    __ j(LESS, &subtract, compiler::Assembler::kNearJump);
    __ addl(EDX, right);
    __ jmp(&done, compiler::Assembler::kNearJump);
    __ Bind(&subtract);
    __ subl(EDX, right);
  } else if (divisor_range()->IsPositive()) {
    // Right is positive.
    __ addl(EDX, right);
  } else {
    // Right is negative.
    __ subl(EDX, right);
  }
  __ Bind(&done);

  __ SmiTag(EAX);
  __ SmiTag(EDX);
}

// Should be kept in sync with integers.cc Multiply64Hash
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register value_lo,
                                        const Register value_hi,
                                        const Register temp) {
  __ movl(EDX, compiler::Immediate(0x2d51));
  __ mull(EDX);  // EAX = lo32(value_lo*0x2d51), EDX = carry(value_lo * 0x2d51)
  __ movl(temp, EAX);      // save prod_lo32
  __ movl(EAX, value_hi);  // get saved value_hi
  __ movl(value_hi, EDX);  // save carry
  __ movl(EDX, compiler::Immediate(0x2d51));
  __ mull(EDX);  // EAX = lo32(value_hi * 0x2d51, EDX = carry(value_hi * 0x2d51)
  __ addl(EAX, value_hi);  // EAX has prod_hi32, EDX has prod_hi64_lo32

  __ xorl(EAX, EDX);   // EAX = prod_hi32 ^ prod_hi64_lo32
  __ xorl(EAX, temp);  // result = prod_hi32 ^ prod_hi64_lo32 ^ prod_lo32
  __ andl(EAX, compiler::Immediate(0x3fffffff));
}

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 4;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RegisterLocation(EBX));
  summary->set_temp(2, Location::RegisterLocation(EDX));
  summary->set_temp(3, Location::RequiresFpuRegister());
  summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                     Location::RegisterLocation(EDX)));
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const XmmRegister value = locs()->in(0).fpu_reg();
  const Register temp = locs()->temp(0).reg();
  ASSERT(locs()->temp(1).reg() == EBX);
  ASSERT(locs()->temp(2).reg() == EDX);
  const XmmRegister temp_double = locs()->temp(3).fpu_reg();
  PairLocation* result_pair = locs()->out(0).AsPairLocation();
  ASSERT(result_pair->At(0).reg() == EAX);
  ASSERT(result_pair->At(1).reg() == EDX);

  // If either nan or infinity, do hash double
  compiler::Label hash_double, try_convert;

  // extract high 32-bits out of double value.
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ pextrd(temp, value, compiler::Immediate(1));
  } else {
    __ SubImmediate(ESP, compiler::Immediate(kDoubleSize));
    __ movsd(compiler::Address(ESP, 0), value);
    __ movl(temp, compiler::Address(ESP, kWordSize));
    __ AddImmediate(ESP, compiler::Immediate(kDoubleSize));
  }
  __ andl(temp, compiler::Immediate(0x7FF00000));
  __ cmpl(temp, compiler::Immediate(0x7FF00000));
  __ j(EQUAL, &hash_double);  // is infinity or nan

  compiler::Label slow_path;
  __ Bind(&try_convert);
  __ cvttsd2si(EAX, value);
  // Overflow is signaled with minint.
  __ cmpl(EAX, compiler::Immediate(0x80000000));
  __ j(EQUAL, &slow_path);
  __ cvtsi2sd(temp_double, EAX);
  __ comisd(value, temp_double);
  __ j(NOT_EQUAL, &hash_double);
  __ cdq();  // sign-extend EAX to EDX
  __ movl(temp, EDX);

  compiler::Label hash_integer, done;
  // integer hash for (temp:EAX)
  __ Bind(&hash_integer);
  EmitHashIntegerCodeSequence(compiler, EAX, temp, EBX);
  __ jmp(&done);

  __ Bind(&slow_path);
  // double value is potentially doesn't fit into Smi range, so
  // do the double->int64->double via runtime call.
  __ StoreUnboxedDouble(value, THR,
                        compiler::target::Thread::unboxed_runtime_arg_offset());
  {
    compiler::LeafRuntimeScope rt(
        compiler->assembler(),
        /*frame_size=*/1 * compiler::target::kWordSize,
        /*preserve_registers=*/true);
    __ movl(compiler::Address(ESP, 0 * compiler::target::kWordSize), THR);
    // Check if double can be represented as int64, load it into (temp:EAX) if
    // it can.
    rt.Call(kTryDoubleAsIntegerRuntimeEntry, 1);
    __ movl(EBX, EAX);  // use non-volatile register to carry value out.
  }
  __ orl(EBX, EBX);
  __ j(ZERO, &hash_double);
  __ movl(EAX,
          compiler::Address(
              THR, compiler::target::Thread::unboxed_runtime_arg_offset()));
  __ movl(temp,
          compiler::Address(
              THR, compiler::target::Thread::unboxed_runtime_arg_offset() +
                       kWordSize));
  __ jmp(&hash_integer);

  __ Bind(&hash_double);
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ pextrd(EAX, value, compiler::Immediate(0));
    __ pextrd(temp, value, compiler::Immediate(1));
  } else {
    __ SubImmediate(ESP, compiler::Immediate(kDoubleSize));
    __ movsd(compiler::Address(ESP, 0), value);
    __ movl(EAX, compiler::Address(ESP, 0));
    __ movl(temp, compiler::Address(ESP, kWordSize));
    __ AddImmediate(ESP, compiler::Immediate(kDoubleSize));
  }
  __ xorl(EAX, temp);
  __ andl(EAX, compiler::Immediate(compiler::target::kSmiMax));

  __ Bind(&done);
  __ xorl(EDX, EDX);
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 3;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_out(0, Location::SameAsFirstInput());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresRegister());
  summary->set_temp(2, Location::RegisterLocation(EDX));
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();
  Register temp1 = locs()->temp(1).reg();
  ASSERT(value == EAX);
  ASSERT(result == EAX);

  if (smi_) {
    __ SmiUntag(EAX);
    __ cdq();  // sign-extend EAX to EDX
    __ movl(temp, EDX);
  } else {
    __ LoadFieldFromOffset(temp, EAX,
                           Mint::value_offset() + compiler::target::kWordSize);
    __ LoadFieldFromOffset(EAX, EAX, Mint::value_offset());
  }

  // value = value_hi << 32 + value_lo
  //
  // value * 0x2d51 = (value_hi * 0x2d51) << 32 + value_lo * 0x2d51
  // prod_lo32 = value_lo * 0x2d51
  // prod_hi32 = carry(value_lo * 0x2d51) + value_hi * 0x2d51
  // prod_lo64 = prod_hi32 << 32 + prod_lo32
  // prod_hi64_lo32 = carry(value_hi * 0x2d51)
  // result = prod_lo32 ^ prod_hi32 ^ prod_hi64_lo32
  // return result & 0x3fffffff

  // EAX has value_lo
  EmitHashIntegerCodeSequence(compiler, EAX, temp, temp1);
  __ SmiTag(EAX);
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
  const compiler::Immediate& raw_null =
      compiler::Immediate(static_cast<intptr_t>(Object::null()));
  __ cmpl(locs()->in(0).reg(), raw_null);
  ASSERT(IsDeoptIfNull() || IsDeoptIfNotNull());
  Condition cond = IsDeoptIfNull() ? EQUAL : NOT_EQUAL;
  __ j(cond, deopt);
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  compiler::Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ subl(biased_cid, compiler::Immediate(min));
  __ cmpl(biased_cid, compiler::Immediate(max - min));
  __ j(ABOVE, deopt);

  Register mask_reg = locs()->temp(1).reg();
  __ movl(mask_reg, compiler::Immediate(mask));
  __ bt(mask_reg, biased_cid);
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
    __ cmpl(value, compiler::Immediate(Smi::RawValue(cids_.cid_start)));
    __ j(NOT_ZERO, deopt);
  } else {
    __ AddImmediate(value,
                    compiler::Immediate(-Smi::RawValue(cids_.cid_start)));
    __ cmpl(value, compiler::Immediate(Smi::RawValue(cids_.Extent())));
    __ j(ABOVE, deopt);
  }
}

// Length: register or constant.
// Index: register, constant or stack slot.
LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (length()->definition()->IsConstant()) {
    locs->set_in(kLengthPos, LocationRegisterOrSmiConstant(length()));
  } else {
    locs->set_in(kLengthPos, Location::PrefersRegister());
  }
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
  if (length_loc.IsConstant()) {
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    const Smi& length = Smi::Cast(length_loc.constant());
    if (length.Value() == Smi::kMaxValue) {
      __ testl(index, index);
      __ j(NEGATIVE, deopt);
    } else {
      __ cmpl(index, compiler::Immediate(static_cast<int32_t>(length.ptr())));
      __ j(ABOVE_EQUAL, deopt);
    }
  } else if (index_loc.IsConstant()) {
    const Smi& index = Smi::Cast(index_loc.constant());
    if (length_loc.IsStackSlot()) {
      const compiler::Address& length = LocationToStackSlotAddress(length_loc);
      __ cmpl(length, compiler::Immediate(static_cast<int32_t>(index.ptr())));
    } else {
      Register length = length_loc.reg();
      __ cmpl(length, compiler::Immediate(static_cast<int32_t>(index.ptr())));
    }
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsStackSlot()) {
    Register index = index_loc.reg();
    const compiler::Address& length = LocationToStackSlotAddress(length_loc);
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmpl(index, length);
    __ j(ABOVE_EQUAL, deopt);
  } else {
    Register index = index_loc.reg();
    Register length = length_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmpl(length, index);
    __ j(BELOW_EQUAL, deopt);
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
  __ movl(TMP, compiler::FieldAddress(locs()->in(0).reg(),
                                      compiler::target::Object::tags_offset()));
  __ testl(TMP, compiler::Immediate(
                    1 << compiler::target::UntaggedObject::kImmutableBit));
  __ j(NOT_ZERO, slow_path->entry_label());
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kADD:
    case Token::kSUB: {
      const intptr_t kNumTemps = 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      summary->set_out(0, Location::SameAsFirstInput());
      return summary;
    }
    case Token::kMUL: {
      const intptr_t kNumTemps = 1;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::Pair(Location::RegisterLocation(EAX),
                                        Location::RegisterLocation(EDX)));
      summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      summary->set_out(0, Location::SameAsFirstInput());
      summary->set_temp(0, Location::RequiresRegister());
      return summary;
    }
    default:
      UNREACHABLE();
      return nullptr;
  }
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs()->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);
  ASSERT(!can_overflow());
  ASSERT(!CanDeoptimize());

  switch (op_kind()) {
    case Token::kBIT_AND:
      __ andl(left_lo, right_lo);
      __ andl(left_hi, right_hi);
      break;
    case Token::kBIT_OR:
      __ orl(left_lo, right_lo);
      __ orl(left_hi, right_hi);
      break;
    case Token::kBIT_XOR:
      __ xorl(left_lo, right_lo);
      __ xorl(left_hi, right_hi);
      break;
    case Token::kADD:
    case Token::kSUB: {
      if (op_kind() == Token::kADD) {
        __ addl(left_lo, right_lo);
        __ adcl(left_hi, right_hi);
      } else {
        __ subl(left_lo, right_lo);
        __ sbbl(left_hi, right_hi);
      }
      break;
    }
    case Token::kMUL: {
      // Compute 64-bit a * b as:
      //     a_l * b_l + (a_h * b_l + a_l * b_h) << 32
      // Since we requested EDX:EAX for in and out,
      // we can use these as scratch registers once
      // input has been consumed.
      Register temp = locs()->temp(0).reg();
      __ movl(temp, left_lo);
      __ imull(left_hi, right_lo);  // a_h * b_l
      __ imull(temp, right_hi);     // a_l * b_h
      __ addl(temp, left_hi);       // sum_high
      ASSERT(left_lo == EAX);
      __ mull(right_lo);   // a_l * b_l in EDX:EAX
      __ addl(EDX, temp);  // add sum_high
      ASSERT(out_lo == EAX);
      ASSERT(out_hi == EDX);
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register left_lo,
                                     Register left_hi,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  switch (op_kind) {
    case Token::kSHR: {
      if (shift > 31) {
        __ movl(left_lo, left_hi);                  // Shift by 32.
        __ sarl(left_hi, compiler::Immediate(31));  // Sign extend left hi.
        if (shift > 32) {
          __ sarl(left_lo, compiler::Immediate(shift > 63 ? 31 : shift - 32));
        }
      } else {
        __ shrdl(left_lo, left_hi, compiler::Immediate(shift));
        __ sarl(left_hi, compiler::Immediate(shift));
      }
      break;
    }
    case Token::kUSHR: {
      ASSERT(shift < 64);
      if (shift > 31) {
        __ movl(left_lo, left_hi);  // Shift by 32.
        __ xorl(left_hi, left_hi);  // Zero extend left hi.
        if (shift > 32) {
          __ shrl(left_lo, compiler::Immediate(shift - 32));
        }
      } else {
        __ shrdl(left_lo, left_hi, compiler::Immediate(shift));
        __ shrl(left_hi, compiler::Immediate(shift));
      }
      break;
    }
    case Token::kSHL: {
      ASSERT(shift < 64);
      if (shift > 31) {
        __ movl(left_hi, left_lo);  // Shift by 32.
        __ xorl(left_lo, left_lo);  // Zero left_lo.
        if (shift > 32) {
          __ shll(left_hi, compiler::Immediate(shift - 32));
        }
      } else {
        __ shldl(left_hi, left_lo, compiler::Immediate(shift));
        __ shll(left_lo, compiler::Immediate(shift));
      }
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByECX(FlowGraphCompiler* compiler,
                                Token::Kind op_kind,
                                Register left_lo,
                                Register left_hi) {
  // sarl operation masks the count to 5 bits and
  // shrdl is undefined with count > operand size (32)
  compiler::Label done, large_shift;
  switch (op_kind) {
    case Token::kSHR: {
      __ cmpl(ECX, compiler::Immediate(31));
      __ j(ABOVE, &large_shift);

      __ shrdl(left_lo, left_hi, ECX);  // Shift count in CL.
      __ sarl(left_hi, ECX);            // Shift count in CL.
      __ jmp(&done, compiler::Assembler::kNearJump);

      __ Bind(&large_shift);
      // No need to subtract 32 from CL, only 5 bits used by sarl.
      __ movl(left_lo, left_hi);                  // Shift by 32.
      __ sarl(left_hi, compiler::Immediate(31));  // Sign extend left hi.
      __ sarl(left_lo, ECX);                      // Shift count: CL % 32.
      break;
    }
    case Token::kUSHR: {
      __ cmpl(ECX, compiler::Immediate(31));
      __ j(ABOVE, &large_shift);

      __ shrdl(left_lo, left_hi, ECX);  // Shift count in CL.
      __ shrl(left_hi, ECX);            // Shift count in CL.
      __ jmp(&done, compiler::Assembler::kNearJump);

      __ Bind(&large_shift);
      // No need to subtract 32 from CL, only 5 bits used by sarl.
      __ movl(left_lo, left_hi);  // Shift by 32.
      __ xorl(left_hi, left_hi);  // Zero extend left hi.
      __ shrl(left_lo, ECX);      // Shift count: CL % 32.
      break;
    }
    case Token::kSHL: {
      __ cmpl(ECX, compiler::Immediate(31));
      __ j(ABOVE, &large_shift);

      __ shldl(left_hi, left_lo, ECX);  // Shift count in CL.
      __ shll(left_lo, ECX);            // Shift count in CL.
      __ jmp(&done, compiler::Assembler::kNearJump);

      __ Bind(&large_shift);
      // No need to subtract 32 from CL, only 5 bits used by shll.
      __ movl(left_hi, left_lo);  // Shift by 32.
      __ xorl(left_lo, left_lo);  // Zero left_lo.
      __ shll(left_hi, ECX);      // Shift count: CL % 32.
      break;
    }
    default:
      UNREACHABLE();
  }
  __ Bind(&done);
}

static void EmitShiftUint32ByConstant(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register left,
                                      const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
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

static void EmitShiftUint32ByECX(FlowGraphCompiler* compiler,
                                 Token::Kind op_kind,
                                 Register left) {
  switch (op_kind) {
    case Token::kSHR:
    case Token::kUSHR: {
      __ shrl(left, ECX);
      break;
    }
    case Token::kSHL: {
      __ shll(left, ECX);
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
    PairLocation* right_pair = instruction()->locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();
    PairLocation* out_pair = instruction()->locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
#if defined(DEBUG)
    PairLocation* left_pair = instruction()->locs()->in(0).AsPairLocation();
    Register left_lo = left_pair->At(0).reg();
    Register left_hi = left_pair->At(1).reg();
    ASSERT(out_lo == left_lo);
    ASSERT(out_hi == left_hi);
#endif  // defined(DEBUG)

    compiler::Label throw_error;
    __ testl(right_hi, right_hi);
    __ j(NEGATIVE, &throw_error);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ sarl(out_hi, compiler::Immediate(31));
        __ movl(out_lo, out_hi);
        break;
      case Token::kUSHR:
      case Token::kSHL: {
        __ xorl(out_lo, out_lo);
        __ xorl(out_hi, out_hi);
        break;
      }
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
    __ movl(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset()),
            right_lo);
    __ movl(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset() +
                         kWordSize),
            right_hi);
  }
};

LocationSummary* ShiftInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  if (RangeUtils::IsPositive(shift_range()) &&
      right()->definition()->IsConstant()) {
    ConstantInstr* constant = right()->definition()->AsConstant();
    summary->set_in(1, Location::Constant(constant));
  } else {
    summary->set_in(1, Location::Pair(Location::RegisterLocation(ECX),
                                      Location::RequiresRegister()));
  }
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), left_lo, left_hi,
                             locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    ASSERT(locs()->in(1).AsPairLocation()->At(0).reg() == ECX);
    Register right_hi = locs()->in(1).AsPairLocation()->At(1).reg();

    // Jump to a slow path if shift count is > 63 or negative.
    ShiftInt64OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange()) {
      slow_path = new (Z) ShiftInt64OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);
      __ testl(right_hi, right_hi);
      __ j(NOT_ZERO, slow_path->entry_label());
      __ cmpl(ECX, compiler::Immediate(kShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftInt64ByECX(compiler, op_kind(), left_lo, left_hi);

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
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void SpeculativeShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), left_lo, left_hi,
                             locs()->in(1).constant());
  } else {
    ASSERT(locs()->in(1).reg() == ECX);
    __ SmiUntag(ECX);

    // Deoptimize if shift count is > 63 or negative (or not a smi).
    if (!IsShiftCountInRange()) {
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);
      __ cmpl(ECX, compiler::Immediate(kShiftCountLimit));
      __ j(ABOVE, deopt);
    }

    EmitShiftInt64ByECX(compiler, op_kind(), left_lo, left_hi);
  }
}

class ShiftUint32OpSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit ShiftUint32OpSlowPath(ShiftUint32OpInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry) {}

  const char* name() override { return "uint32 shift"; }

  void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) override {
    PairLocation* right_pair = instruction()->locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT(out == instruction()->locs()->in(0).reg());

    compiler::Label throw_error;
    __ testl(right_hi, right_hi);
    __ j(NEGATIVE, &throw_error);

    __ xorl(out, out);
    __ jmp(exit_label());

    __ Bind(&throw_error);

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ movl(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset()),
            right_lo);
    __ movl(compiler::Address(
                THR, compiler::target::Thread::unboxed_runtime_arg_offset() +
                         kWordSize),
            right_hi);
  }
};

LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  if (RangeUtils::IsPositive(shift_range()) &&
      right()->definition()->IsConstant()) {
    ConstantInstr* constant = right()->definition()->AsConstant();
    summary->set_in(1, Location::Constant(constant));
  } else {
    summary->set_in(1, Location::Pair(Location::RegisterLocation(ECX),
                                      Location::RequiresRegister()));
  }
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
    ASSERT(locs()->in(1).AsPairLocation()->At(0).reg() == ECX);
    Register right_hi = locs()->in(1).AsPairLocation()->At(1).reg();

    // Jump to a slow path if shift count is > 31 or negative.
    ShiftUint32OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      slow_path = new (Z) ShiftUint32OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ testl(right_hi, right_hi);
      __ j(NOT_ZERO, slow_path->entry_label());
      __ cmpl(ECX, compiler::Immediate(kUint32ShiftCountLimit));
      __ j(ABOVE, slow_path->entry_label());
    }

    EmitShiftUint32ByECX(compiler, op_kind(), left);

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
  summary->set_in(1, LocationFixedRegisterOrSmiConstant(right(), ECX));
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
    ASSERT(locs()->in(1).reg() == ECX);
    __ SmiUntag(ECX);

    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      if (!IsShiftCountInRange()) {
        // Deoptimize if shift count is negative.
        ASSERT(CanDeoptimize());
        compiler::Label* deopt =
            compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

        __ testl(ECX, ECX);
        __ j(LESS, deopt);
      }

      compiler::Label cont;
      __ cmpl(ECX, compiler::Immediate(kUint32ShiftCountLimit));
      __ j(LESS_EQUAL, &cont);

      __ xorl(left, left);

      __ Bind(&cont);
    }

    EmitShiftUint32ByECX(compiler, op_kind(), left);
  }
}

LocationSummary* UnaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);
  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ notl(left_lo);
      __ notl(left_hi);
      break;
    case Token::kNEGATE:
      __ negl(left_lo);
      __ adcl(left_hi, compiler::Immediate(0));
      __ negl(left_hi);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out = locs()->out(0).reg();
  ASSERT(locs()->in(0).reg() == out);

  ASSERT(op_kind() == Token::kBIT_NOT);

  __ notl(out);
}

LocationSummary* IntConverterInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  if (from() == kUntagged || to() == kUntagged) {
    ASSERT((from() == kUntagged && to() == kUnboxedInt32) ||
           (from() == kUntagged && to() == kUnboxedUint32) ||
           (from() == kUnboxedInt32 && to() == kUntagged) ||
           (from() == kUnboxedUint32 && to() == kUntagged));
    ASSERT(!CanDeoptimize());
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  } else if ((from() == kUnboxedInt32 || from() == kUnboxedUint32) &&
             (to() == kUnboxedInt32 || to() == kUnboxedUint32)) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  } else if (from() == kUnboxedInt64) {
    summary->set_in(
        0, Location::Pair(CanDeoptimize() ? Location::WritableRegister()
                                          : Location::RequiresRegister(),
                          Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else if (from() == kUnboxedUint32) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else if (from() == kUnboxedInt32) {
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                       Location::RegisterLocation(EDX)));
  }

  return summary;
}

void IntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const bool is_nop_conversion =
      (from() == kUntagged && to() == kUnboxedInt32) ||
      (from() == kUntagged && to() == kUnboxedUint32) ||
      (from() == kUnboxedInt32 && to() == kUntagged) ||
      (from() == kUnboxedUint32 && to() == kUntagged);
  if (is_nop_conversion) {
    ASSERT(locs()->in(0).reg() == locs()->out(0).reg());
    return;
  }

  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    // Representations are bitwise equivalent.
    ASSERT(locs()->out(0).reg() == locs()->in(0).reg());
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    // Representations are bitwise equivalent.
    ASSERT(locs()->out(0).reg() == locs()->in(0).reg());
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ testl(locs()->out(0).reg(), locs()->out(0).reg());
      __ j(NEGATIVE, deopt);
    }
  } else if (from() == kUnboxedInt64) {
    // TODO(vegorov) kUnboxedInt64 -> kInt32 conversion is currently usually
    // dominated by a CheckSmi(BoxInt64(val)) which is an artifact of ordering
    // of optimization passes and the way we check smi-ness of values.
    // Optimize it away.
    ASSERT(to() == kUnboxedInt32 || to() == kUnboxedUint32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ movl(out, in_lo);
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ sarl(in_lo, compiler::Immediate(31));
      __ cmpl(in_lo, in_hi);
      __ j(NOT_EQUAL, deopt);
    }
  } else if (from() == kUnboxedUint32) {
    ASSERT(to() == kUnboxedInt64);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ movl(out_lo, in);
    // Zero upper word.
    __ xorl(out_hi, out_hi);
  } else if (from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedInt64);
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    ASSERT(locs()->in(0).reg() == EAX);
    ASSERT(out_lo == EAX && out_hi == EDX);
    __ cdq();
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
  const intptr_t kNumTemps = 2;

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresRegister());

  return summary;
}

void IndirectGotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register index_reg = locs()->in(0).reg();
  Register target_reg = locs()->temp(0).reg();
  Register offset = locs()->temp(1).reg();

  ASSERT(RequiredInputRepresentation(0) == kTagged);
  __ LoadObject(offset, offsets_);
  __ movl(offset, compiler::Assembler::ElementAddressForRegIndex(
                      /*is_external=*/false, kTypedDataInt32ArrayCid,
                      /*index_scale=*/4,
                      /*index_unboxed=*/false, offset, index_reg));

  // Load code object from frame.
  __ movl(target_reg,
          compiler::Address(
              EBP, compiler::target::frame_layout.code_from_fp * kWordSize));
  // Load instructions object (active_instructions and Code::entry_point() may
  // not point to this instruction object any more; see Code::DisableDartCode).
  __ movl(target_reg,
          compiler::FieldAddress(target_reg, Code::instructions_offset()));
  __ addl(target_reg,
          compiler::Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ addl(target_reg, offset);

  // Jump to the absolute address.
  __ jmp(target_reg);
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(EAX));
    locs->set_in(1, Location::RegisterLocation(ECX));
    locs->set_out(0, Location::RegisterLocation(EAX));
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

// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}

LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // TODO(dartbug.com/30953): support byte register constraints in the
  // register allocator.
  comparison()->locs()->set_out(0, Location::RegisterLocation(EDX));
  return comparison()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out(0).reg() == EDX);

  // Clear upper part of the out register. We are going to use setcc on it
  // which is a byte move.
  __ xorl(EDX, EDX);

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
      // We need to have zero in EDX on true_condition.
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
    __ shll(EDX, compiler::Immediate(shift + kSmiTagSize));
  } else {
    __ decl(EDX);
    __ andl(EDX, compiler::Immediate(Smi::RawValue(true_value) -
                                     Smi::RawValue(false_value)));
    if (false_value != 0) {
      __ addl(EDX, compiler::Immediate(Smi::RawValue(false_value)));
    }
  }
}

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(FUNCTION_REG));  // Function.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);

  // EBX: Code (compiled code or lazy compile stub).
  ASSERT(locs()->in(0).reg() == FUNCTION_REG);
  __ movl(EBX,
          compiler::FieldAddress(FUNCTION_REG, Function::entry_point_offset()));

  // FUNCTION_REG: Function.
  // ARGS_DESC_REG: Arguments descriptor array.
  // ECX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ xorl(IC_DATA_REG, IC_DATA_REG);
  __ call(EBX);
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
  __ xorl(result, compiler::Immediate(
                      compiler::target::ObjectAlignment::kBoolValueMask));
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
  __ Call(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

}  // namespace dart

#undef __

#endif  // defined(TARGET_ARCH_IA32)
