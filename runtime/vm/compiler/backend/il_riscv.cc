// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/compiler/backend/il.h"

#include "platform/memory_sanitizer.h"
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
// on the stack and return the result in a fixed register A0 (or FA0 if
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
    case kUnboxedInt64:
#if XLEN == 32
      result->set_out(
          0, Location::Pair(
                 Location::RegisterLocation(CallingConventions::kReturnReg),
                 Location::RegisterLocation(
                     CallingConventions::kSecondReturnReg)));
#else
      result->set_out(
          0, Location::RegisterLocation(CallingConventions::kReturnReg));
#endif
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
      locs->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
#if XLEN == 32
      locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
#else
      locs->set_out(0, Location::RequiresRegister());
#endif
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
    case kTagged: {
      const auto out = locs()->out(0).reg();
      __ AddShifted(TMP, base_reg(), index, kWordSizeLog2 - kSmiTagSize);
      __ LoadFromOffset(out, TMP, offset());
      break;
    }
    case kUnboxedInt64: {
#if XLEN == 32
      const auto out_lo = locs()->out(0).AsPairLocation()->At(0).reg();
      const auto out_hi = locs()->out(0).AsPairLocation()->At(1).reg();
      __ AddShifted(TMP, base_reg(), index, kWordSizeLog2 - kSmiTagSize);
      __ LoadFromOffset(out_lo, TMP, offset());
      __ LoadFromOffset(out_hi, TMP, offset() + compiler::target::kWordSize);
#else
      const auto out = locs()->out(0).reg();
      __ AddShifted(TMP, base_reg(), index, kWordSizeLog2 - kSmiTagSize);
      __ LoadFromOffset(out, TMP, offset());
#endif
      break;
    }
    case kUnboxedDouble: {
      const auto out = locs()->out(0).fpu_reg();
      __ AddShifted(TMP, base_reg(), index, kWordSizeLog2 - kSmiTagSize);
      __ LoadDFromOffset(out, TMP, offset());
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
  __ AddShifted(TMP, instr->base_reg(), index,
                compiler::target::kWordSizeLog2 - kSmiTagSize);
  __ sx(value, compiler::Address(TMP, instr->offset()));

  ASSERT(kSmiTag == 0);
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
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::WritableRegister());
  locs->set_in(kDestPos, Location::WritableRegister());
  locs->set_in(kSrcStartPos, LocationRegisterOrConstant(src_start()));
  locs->set_in(kDestStartPos, LocationRegisterOrConstant(dest_start()));
  locs->set_in(kLengthPos,
               LocationWritableRegisterOrSmiConstant(length(), 0, 4));
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
      return compiler::kByte;
    case 2:
      return compiler::kTwoBytes;
    case 4:
      return compiler::kFourBytes;
    case 8:
      return compiler::kEightBytes;
    default:
      UNREACHABLE();
      return compiler::kEightBytes;
  }
}

// Copies [count] bytes from the memory region pointed to by [dest_reg] to the
// memory region pointed to by [src_reg]. If [reversed] is true, then [dest_reg]
// and [src_reg] are assumed to point at the end of the respective region.
static void CopyBytes(FlowGraphCompiler* compiler,
                      Register dest_reg,
                      Register src_reg,
                      intptr_t count,
                      bool reversed) {
  COMPILE_ASSERT(XLEN <= 128);
  ASSERT(Utils::IsPowerOfTwo(count));

#if XLEN >= 128
  // Handled specially because there is no kSixteenBytes OperandSize.
  if (count == 16) {
    const intptr_t offset = (reversed ? -1 : 1) * count;
    const intptr_t initial = reversed ? offset : 0;
    __ lq(TMP, compiler::Address(src_reg, initial));
    __ addi(src_reg, src_reg, offset);
    __ sq(TMP, compiler::Address(dest_reg, initial));
    __ addi(dest_reg, dest_reg, offset);
    return;
  }
#endif

#if XLEN <= 32
  if (count == 4 * (XLEN / 8)) {
    auto const sz = OperandSizeFor(XLEN / 8);
    const intptr_t offset = (reversed ? -1 : 1) * (XLEN / 8);
    const intptr_t initial = reversed ? offset : 0;
    __ LoadFromOffset(TMP, compiler::Address(src_reg, initial), sz);
    __ LoadFromOffset(TMP2, compiler::Address(src_reg, initial + offset), sz);
    __ StoreToOffset(TMP, compiler::Address(dest_reg, initial), sz);
    __ StoreToOffset(TMP2, compiler::Address(dest_reg, initial + offset), sz);
    __ LoadFromOffset(TMP, compiler::Address(src_reg, initial + 2 * offset),
                      sz);
    __ LoadFromOffset(TMP2, compiler::Address(src_reg, initial + 3 * offset),
                      sz);
    __ addi(src_reg, src_reg, 4 * offset);
    __ StoreToOffset(TMP, compiler::Address(dest_reg, initial + 2 * offset),
                     sz);
    __ StoreToOffset(TMP2, compiler::Address(dest_reg, initial + 3 * offset),
                     sz);
    __ addi(dest_reg, dest_reg, 4 * offset);
    return;
  }
#endif

#if XLEN <= 64
  if (count == 2 * (XLEN / 8)) {
    auto const sz = OperandSizeFor(XLEN / 8);
    const intptr_t offset = (reversed ? -1 : 1) * (XLEN / 8);
    const intptr_t initial = reversed ? offset : 0;
    __ LoadFromOffset(TMP, compiler::Address(src_reg, initial), sz);
    __ LoadFromOffset(TMP2, compiler::Address(src_reg, initial + offset), sz);
    __ addi(src_reg, src_reg, 2 * offset);
    __ StoreToOffset(TMP, compiler::Address(dest_reg, initial), sz);
    __ StoreToOffset(TMP2, compiler::Address(dest_reg, initial + offset), sz);
    __ addi(dest_reg, dest_reg, 2 * offset);
    return;
  }
#endif

  ASSERT(count <= (XLEN / 8));
  auto const sz = OperandSizeFor(count);
  const intptr_t offset = (reversed ? -1 : 1) * count;
  const intptr_t initial = reversed ? offset : 0;
  __ LoadFromOffset(TMP, compiler::Address(src_reg, initial), sz);
  __ addi(src_reg, src_reg, offset);
  __ StoreToOffset(TMP, compiler::Address(dest_reg, initial), sz);
  __ addi(dest_reg, dest_reg, offset);
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

  COMPILE_ASSERT(XLEN <= 128);

  for (intptr_t bit = compiler::target::kWordSizeLog2 - 1; bit >= element_shift;
       bit--) {
    const intptr_t bytes = 1 << bit;
    const intptr_t tested_bit = bit + base_shift;
    tested_bits |= 1 << tested_bit;
    compiler::Label skip_copy;
    __ andi(TMP, length_reg, 1 << tested_bit);
    __ beqz(TMP, &skip_copy);
    CopyBytes(compiler, dest_reg, src_reg, bytes, reversed);
    __ Bind(&skip_copy);
  }

  ASSERT(tested_bits != 0);
  __ andi(length_reg, length_reg, ~tested_bits);
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
    // Verify that the overlap actually exists by checking to see if the start
    // of the destination region is after the end of the source region.
    const intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                           (unboxed_inputs() ? 0 : kSmiTagShift);
    if (shift == 0) {
      __ add(TMP, src_reg, length_reg);
    } else if (shift < 0) {
      __ srai(TMP, length_reg, -shift);
      __ add(TMP, src_reg, TMP);
    } else {
      __ slli(TMP, length_reg, shift);
      __ add(TMP, src_reg, TMP);
    }
    __ CompareRegisters(dest_reg, TMP);
    __ BranchIf(UNSIGNED_GREATER_EQUAL, copy_forwards);
    // Adjust dest_reg and src_reg to point at the end (i.e. one past the
    // last element) of their respective region.
    __ add(dest_reg, dest_reg, TMP);
    __ sub(dest_reg, dest_reg, src_reg);
    __ MoveRegister(src_reg, TMP);
  }
  CopyUpToWordMultiple(compiler, dest_reg, src_reg, length_reg, element_size_,
                       unboxed_inputs_, reversed, done);
  // The size of the uncopied region is a multiple of the word size, so now we
  // copy the rest by word.
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
#if XLEN <= 32
      CopyBytes(compiler, dest_reg, src_reg, 4, reversed);
      break;
#endif
    case 8:
#if XLEN <= 64
      CopyBytes(compiler, dest_reg, src_reg, 8, reversed);
      break;
#endif
    case 16:
      COMPILE_ASSERT(XLEN <= 128);
      CopyBytes(compiler, dest_reg, src_reg, 16, reversed);
      break;
    default:
      UNREACHABLE();
      break;
  }
  __ subi(length_reg, length_reg, loop_subtract);
  __ bnez(length_reg, &loop);
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Location start_loc) {
  intptr_t offset;
  if (IsTypedDataBaseClassId(array_cid)) {
    __ lx(array_reg,
          compiler::FieldAddress(array_reg,
                                 compiler::target::PointerBase::data_offset()));
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
        __ lx(array_reg,
              compiler::FieldAddress(array_reg,
                                     compiler::target::ExternalOneByteString::
                                         external_data_offset()));
        offset = 0;
        break;
      case kExternalTwoByteStringCid:
        __ lx(array_reg,
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
  __ AddImmediate(array_reg, offset);
  const Register start_reg = start_loc.reg();
  intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                   (unboxed_inputs() ? 0 : kSmiTagShift);
  __ AddShifted(array_reg, array_reg, start_reg, shift);
}

LocationSummary* MoveArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  ConstantInstr* constant = value()->definition()->AsConstant();
  if (constant != nullptr && constant->HasZeroRepresentation()) {
    locs->set_in(0, Location::Constant(constant));
  } else if (representation() == kUnboxedDouble) {
    locs->set_in(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedInt64) {
#if XLEN == 32
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
#else
    locs->set_in(0, Location::RequiresRegister());
#endif
  } else {
    ASSERT(representation() == kTagged);
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

void MoveArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());

  const Location value = compiler->RebaseIfImprovesAddressing(locs()->in(0));
  const intptr_t offset = sp_relative_index() * compiler::target::kWordSize;
  if (value.IsRegister()) {
    __ StoreToOffset(value.reg(), SP, offset);
#if XLEN == 32
  } else if (value.IsPairLocation()) {
    __ StoreToOffset(value.AsPairLocation()->At(1).reg(), SP,
                     offset + compiler::target::kWordSize);
    __ StoreToOffset(value.AsPairLocation()->At(0).reg(), SP, offset);
#endif
  } else if (value.IsConstant()) {
    if (representation() == kUnboxedDouble) {
      ASSERT(value.constant_instruction()->HasZeroRepresentation());
#if XLEN == 32
      __ StoreToOffset(ZR, SP, offset + compiler::target::kWordSize);
      __ StoreToOffset(ZR, SP, offset);
#else
      __ StoreToOffset(ZR, SP, offset);
#endif
    } else if (representation() == kUnboxedInt64) {
      ASSERT(value.constant_instruction()->HasZeroRepresentation());
#if XLEN == 32
      __ StoreToOffset(ZR, SP, offset + compiler::target::kWordSize);
      __ StoreToOffset(ZR, SP, offset);
#else
      __ StoreToOffset(ZR, SP, offset);
#endif
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
    const intptr_t value_offset = value.ToStackSlotOffset();
    __ LoadFromOffset(TMP, value.base_reg(), value_offset);
    __ StoreToOffset(TMP, SP, offset);
  } else {
    UNREACHABLE();
  }
}

LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  switch (representation()) {
    case kTagged:
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
    case kUnboxedInt64:
#if XLEN == 32
      locs->set_in(
          0, Location::Pair(
                 Location::RegisterLocation(CallingConventions::kReturnReg),
                 Location::RegisterLocation(
                     CallingConventions::kSecondReturnReg)));
#else
      locs->set_in(0,
                   Location::RegisterLocation(CallingConventions::kReturnReg));
#endif
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

  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      kWordSize;
  __ CheckFpSpDist(fp_sp_dist);
  ASSERT(__ constant_pool_allowed());
  __ LeaveDartFrame(fp_sp_dist);  // Disallows constant pool use.
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
  BranchLabels labels = {nullptr, nullptr, nullptr};
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

  __ SetIf(true_condition, result);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ slli(result, result, shift + kSmiTagSize);
  } else {
    __ subi(result, result, 1);
    const int64_t val = Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, Smi::RawValue(false_value));
    }
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
  // Load arguments descriptor in ARGS_DESC_REG.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);

  if (FLAG_precompiled_mode) {
    ASSERT(locs()->in(0).reg() == T0);
    // T0: Closure with a cached entry point.
    __ LoadFieldFromOffset(A1, T0,
                           compiler::target::Closure::entry_point_offset());
  } else {
    ASSERT(locs()->in(0).reg() == FUNCTION_REG);
    // FUNCTION_REG: Function.
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     compiler::target::Function::code_offset());
    // Closure functions only have one entry point.
    __ LoadFieldFromOffset(A1, FUNCTION_REG,
                           compiler::target::Function::entry_point_offset());
  }

  // FUNCTION_REG: Function (argument to lazy compile stub)
  // ARGS_DESC_REG: Arguments descriptor array.
  // A1: instructions entry point.
  if (!FLAG_precompiled_mode) {
    // S5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ LoadImmediate(IC_DATA_REG, 0);
  }
  __ jalr(A1);
  compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                 UntaggedPcDescriptors::kOther, locs(), env());
  compiler->EmitDropArguments(argument_count);
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
  // TODO(riscv): Using an SP-relative address instead of an FP-relative
  // address would allow for compressed instructions.
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
  // TODO(riscv): Using an SP-relative address instead of an FP-relative
  // address would allow for compressed instructions.
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
#if XLEN == 32
      __ LoadImmediate(destination.reg(), pair_index == 0
                                              ? Utils::Low32Bits(v)
                                              : Utils::High32Bits(v));
#else
      ASSERT(pair_index == 0);  // No pair representation needed on 64-bit.
      __ LoadImmediate(destination.reg(), v);
#endif
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const FRegister dst = destination.fpu_reg();
    __ LoadDImmediate(dst, Double::Cast(value_).value());
  } else if (destination.IsDoubleStackSlot()) {
    const intptr_t dest_offset = destination.ToStackSlotOffset();
#if XLEN == 32
    if (false) {
#else
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0)) {
#endif
      __ StoreToOffset(ZR, destination.base_reg(), dest_offset);
    } else {
      __ LoadDImmediate(FTMP, Double::Cast(value_).value());
      __ StoreDToOffset(FTMP, destination.base_reg(), dest_offset);
    }
  } else {
    ASSERT(destination.IsStackSlot());
    ASSERT(tmp != kNoRegister);
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t val = Integer::Cast(value_).AsInt64Value();
#if XLEN == 32
      val = pair_index == 0 ? Utils::Low32Bits(val) : Utils::High32Bits(val);
#else
      ASSERT(pair_index == 0);  // No pair representation needed on 64-bit.
#endif
      if (val == 0) {
        tmp = ZR;
      } else {
        __ LoadImmediate(tmp, val);
      }
    } else {
      ASSERT(representation() == kTagged);
      if (value_.IsNull()) {
        tmp = NULL_REG;
      } else if (value_.IsSmi() && Smi::Cast(value_).Value() == 0) {
        tmp = ZR;
      } else {
        __ LoadObject(tmp, value_);
      }
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
      Utils::NBitMask<intptr_t>(kNumberOfFpuRegisters) & ~(1l << FpuTMP);

  const intptr_t kNumTemps = (Utils::CountOneBits32(kCpuRegistersToPreserve) +
                              Utils::CountOneBits32(kFpuRegistersToPreserve));

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

void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->always_calls());

  auto object_store = compiler->isolate_group()->object_store();
  const auto& assert_boolean_stub =
      Code::ZoneHandle(compiler->zone(), object_store->assert_boolean_stub());

  compiler::Label done;
  __ andi(TMP, AssertBooleanABI::kObjectReg, 1 << kBoolVsNullBitPosition);
  __ bnez(TMP, &done, compiler::Assembler::kNearJump);
  compiler->GenerateStubCall(source(), assert_boolean_stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
  __ Bind(&done);
}

static Condition TokenKindToIntCondition(Token::Kind kind) {
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
    __ BranchIf(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor we will branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ BranchIf(false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ j(labels.true_label);
    }
  }
}

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     LocationSummary* locs,
                                     Token::Kind kind,
                                     BranchLabels labels) {
  Location left = locs->in(0);
  Location right = locs->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);
  if (left.IsConstant() || right.IsConstant()) {
    // Ensure constant is on the right.
    if (left.IsConstant()) {
      Location tmp = right;
      right = left;
      left = tmp;
      true_condition = FlipCondition(true_condition);
    }
    __ CompareObject(left.reg(), right.constant());
  } else {
    __ CompareObjectRegisters(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition EmitWordComparisonOp(FlowGraphCompiler* compiler,
                                      LocationSummary* locs,
                                      Token::Kind kind,
                                      BranchLabels labels) {
  Location left = locs->in(0);
  Location right = locs->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);
  if (left.IsConstant() || right.IsConstant()) {
    // Ensure constant is on the right.
    if (left.IsConstant()) {
      Location tmp = right;
      right = left;
      left = tmp;
      true_condition = FlipCondition(true_condition);
    }
    __ CompareImmediate(
        left.reg(),
        static_cast<uword>(Integer::Cast(right.constant()).AsInt64Value()));
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }
  return true_condition;
}

#if XLEN == 32
static Condition EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                           LocationSummary* locs,
                                           Token::Kind kind) {
  ASSERT(Token::IsEqualityOperator(kind));
  PairLocation* left_pair = locs->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();

  __ xor_(TMP, left_lo, right_lo);
  __ xor_(TMP2, left_hi, right_hi);
  __ or_(TMP, TMP, TMP2);
  __ CompareImmediate(TMP, 0);
  if (kind == Token::kEQ) {
    return EQUAL;
  } else if (kind == Token::kNE) {
    return NOT_EQUAL;
  }
  UNREACHABLE();
}

static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             LocationSummary* locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  PairLocation* left_pair = locs->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();

  switch (kind) {
    case Token::kEQ:
      __ bne(left_lo, right_lo, labels.false_label);
      __ CompareRegisters(left_hi, right_hi);
      return EQUAL;
    case Token::kNE:
      __ bne(left_lo, right_lo, labels.true_label);
      __ CompareRegisters(left_hi, right_hi);
      return NOT_EQUAL;
    case Token::kLT:
      __ blt(left_hi, right_hi, labels.true_label);
      __ bgt(left_hi, right_hi, labels.false_label);
      __ CompareRegisters(left_lo, right_lo);
      return UNSIGNED_LESS;
    case Token::kGT:
      __ bgt(left_hi, right_hi, labels.true_label);
      __ blt(left_hi, right_hi, labels.false_label);
      __ CompareRegisters(left_lo, right_lo);
      return UNSIGNED_GREATER;
    case Token::kLTE:
      __ blt(left_hi, right_hi, labels.true_label);
      __ bgt(left_hi, right_hi, labels.false_label);
      __ CompareRegisters(left_lo, right_lo);
      return UNSIGNED_LESS_EQUAL;
    case Token::kGTE:
      __ bgt(left_hi, right_hi, labels.true_label);
      __ blt(left_hi, right_hi, labels.false_label);
      __ CompareRegisters(left_lo, right_lo);
      return UNSIGNED_GREATER_EQUAL;
    default:
      UNREACHABLE();
  }
}
#else
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
      __ CompareImmediate(left.reg(), value);
    } else {
      UNREACHABLE();
    }
  } else {
    __ CompareRegisters(left.reg(), right.reg());
  }
  return true_condition;
}
#endif

static Condition EmitNullAwareInt64ComparisonOp(FlowGraphCompiler* compiler,
                                                LocationSummary* locs,
                                                Token::Kind kind,
                                                BranchLabels labels) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const Register left = locs->in(0).reg();
  const Register right = locs->in(1).reg();
  const Condition true_condition = TokenKindToIntCondition(kind);
  compiler::Label* equal_result =
      (true_condition == EQ) ? labels.true_label : labels.false_label;
  compiler::Label* not_equal_result =
      (true_condition == EQ) ? labels.false_label : labels.true_label;

  // Check if operands have the same value. If they don't, then they could
  // be equal only if both of them are Mints with the same value.
  __ CompareObjectRegisters(left, right);
  __ BranchIf(EQ, equal_result);
  __ and_(TMP, left, right);
  __ BranchIfSmi(TMP, not_equal_result);
  __ CompareClassId(left, kMintCid, TMP);
  __ BranchIf(NE, not_equal_result);
  __ CompareClassId(right, kMintCid, TMP);
  __ BranchIf(NE, not_equal_result);
#if XLEN == 32
  __ LoadFieldFromOffset(TMP, left, compiler::target::Mint::value_offset());
  __ LoadFieldFromOffset(TMP2, right, compiler::target::Mint::value_offset());
  __ bne(TMP, TMP2, not_equal_result);
  __ LoadFieldFromOffset(
      TMP, left,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize);
  __ LoadFieldFromOffset(
      TMP2, right,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize);
#else
  __ LoadFieldFromOffset(TMP, left, Mint::value_offset());
  __ LoadFieldFromOffset(TMP2, right, Mint::value_offset());
#endif
  __ CompareRegisters(TMP, TMP2);
  return true_condition;
}

LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (is_null_aware()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
#if XLEN == 32
  if (operation_cid() == kMintCid) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
#endif
  if (operation_cid() == kDoubleCid) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid || operation_cid() == kMintCid ||
      operation_cid() == kIntegerCid) {
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

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        LocationSummary* locs,
                                        BranchLabels labels,
                                        Token::Kind kind) {
  const FRegister left = locs->in(0).fpu_reg();
  const FRegister right = locs->in(1).fpu_reg();

  switch (kind) {
    case Token::kEQ:
      __ feqd(TMP, left, right);
      __ CompareImmediate(TMP, 0);
      return NE;
    case Token::kNE:
      __ feqd(TMP, left, right);
      __ CompareImmediate(TMP, 0);
      return EQ;
    case Token::kLT:
      __ fltd(TMP, left, right);
      __ CompareImmediate(TMP, 0);
      return NE;
    case Token::kGT:
      __ fltd(TMP, right, left);
      __ CompareImmediate(TMP, 0);
      return NE;
    case Token::kLTE:
      __ fled(TMP, left, right);
      __ CompareImmediate(TMP, 0);
      return NE;
    case Token::kGTE:
      __ fled(TMP, right, left);
      __ CompareImmediate(TMP, 0);
      return NE;
    default:
      UNREACHABLE();
  }
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (is_null_aware()) {
    ASSERT(operation_cid() == kMintCid);
    return EmitNullAwareInt64ComparisonOp(compiler, locs(), kind(), labels);
  }
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind(), labels);
  } else if (operation_cid() == kIntegerCid) {
    return EmitWordComparisonOp(compiler, locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
#if XLEN == 32
    return EmitUnboxedMintEqualityOp(compiler, locs(), kind());
#else
    return EmitInt64ComparisonOp(compiler, locs(), kind(), labels);
#endif
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
    const intx_t imm = static_cast<intx_t>(right.constant().ptr());
    __ TestImmediate(left, imm);
  } else {
    __ TestRegisters(left, right.reg());
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
  // No match found, deoptimize or default action.
  if (deopt == nullptr) {
    // If the cid is not in the list, jump to the opposite label from the cids
    // that are in the list.  These must be all the same (see asserts in the
    // constructor).
    compiler::Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ j(target);
    }
  } else {
    __ j(deopt);
  }
  // Dummy result as this method already did the jump, there's no need
  // for the caller to branch on a condition.
  return kInvalidCondition;
}

LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
#if XLEN == 32
  if (operation_cid() == kMintCid) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
#endif
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
    return EmitSmiComparisonOp(compiler, locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
#if XLEN == 32
    return EmitUnboxedMintComparisonOp(compiler, locs(), kind(), labels);
#else
    return EmitInt64ComparisonOp(compiler, locs(), kind(), labels);
#endif
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), labels, kind());
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // Pass a pointer to the first argument in R2.
  __ AddImmediate(T2, SP, (ArgumentCount() - 1) * kWordSize);

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
  __ LoadImmediate(T1, argc_tag);
  compiler::ExternalLabel label(entry);
  __ LoadNativeEntry(T5, &label,
                     link_lazily() ? ObjectPool::Patchability::kPatchable
                                   : ObjectPool::Patchability::kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(source(), *stub,
                                    UntaggedPcDescriptors::kOther, locs());
  } else {
    // We can never lazy-deopt here because natives are never optimized.
    ASSERT(!compiler->is_optimizing());
    compiler->GenerateNonLazyDeoptableStubCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs());
  }
  __ lx(result, compiler::Address(SP, 0));
  compiler->EmitDropArguments(ArgumentCount());
}

#define R(r) (1 << r)

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(CallingConventions::kSecondNonArgumentRegister) |
       R(CallingConventions::kFfiAnyNonAbiRegister) | R(CALLEE_SAVED_TEMP2)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register target = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  const Register temp1 = locs()->temp(0).reg();
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves.
  // For leaf calls, this holds the SP used to restore the pre-aligned SP after
  // the call.
  const Register saved_fp_or_sp = locs()->temp(1).reg();
  const Register temp2 = locs()->temp(2).reg();

  ASSERT(temp1 != target);
  ASSERT(temp2 != target);
  ASSERT(temp1 != saved_fp_or_sp);
  ASSERT(temp2 != saved_fp_or_sp);
  ASSERT(saved_fp_or_sp != target);

  // Ensure these are callee-saved register and are preserved across the call.
  ASSERT(IsCalleeSavedRegister(saved_fp_or_sp));
  // Other temps don't need to be preserved.

  __ mv(saved_fp_or_sp, is_leaf_ ? SPREG : FPREG);

  if (!is_leaf_) {
    // We need to create a dummy "exit frame".
    // This is EnterDartFrame without accessing A2=CODE_REG or A5=PP.
    if (FLAG_precompiled_mode) {
      __ subi(SP, SP, 2 * compiler::target::kWordSize);
      __ sx(RA, compiler::Address(SP, 1 * compiler::target::kWordSize));
      __ sx(FP, compiler::Address(SP, 0 * compiler::target::kWordSize));
      __ addi(FP, SP, 2 * compiler::target::kWordSize);
    } else {
      __ subi(SP, SP, 4 * compiler::target::kWordSize);
      __ sx(RA, compiler::Address(SP, 3 * compiler::target::kWordSize));
      __ sx(FP, compiler::Address(SP, 2 * compiler::target::kWordSize));
      __ sx(NULL_REG, compiler::Address(SP, 1 * compiler::target::kWordSize));
      __ sx(NULL_REG, compiler::Address(SP, 0 * compiler::target::kWordSize));
      __ addi(FP, SP, 4 * compiler::target::kWordSize);
    }
  }

  // Reserve space for the arguments that go on the stack (if any), then align.
  intptr_t stack_space = marshaller_.RequiredStackSpaceInBytes();
  __ ReserveAlignedFrameSpace(stack_space);
#if defined(USING_MEMORY_SANITIZER)
  {
    RegisterSet kVolatileRegisterSet(kAbiVolatileCpuRegs, kAbiVolatileFpuRegs);
    __ mv(temp1, SP);
    __ PushRegisters(kVolatileRegisterSet);

    // Outgoing arguments passed on the stack to the foreign function.
    __ mv(A0, temp1);
    __ LoadImmediate(A1, stack_space);
    __ CallCFunction(
        compiler::Address(THR, kMsanUnpoisonRuntimeEntry.OffsetFromThread()));

    // Incoming Dart arguments to this trampoline are potentially used as local
    // handles.
    __ mv(A0, is_leaf_ ? FPREG : saved_fp_or_sp);
    __ LoadImmediate(A1, (kParamEndSlotFromFp + InputCount()) * kWordSize);
    __ CallCFunction(
        compiler::Address(THR, kMsanUnpoisonRuntimeEntry.OffsetFromThread()));

    // Outgoing arguments passed by register to the foreign function.
    __ LoadImmediate(A0, InputCount());
    __ CallCFunction(compiler::Address(
        THR, kMsanUnpoisonParamRuntimeEntry.OffsetFromThread()));

    __ PopRegisters(kVolatileRegisterSet);
  }
#endif

  EmitParamMoves(compiler, is_leaf_ ? FPREG : saved_fp_or_sp, temp1, temp2);

  if (compiler::Assembler::EmittingComments()) {
    __ Comment(is_leaf_ ? "Leaf Call" : "Call");
  }

  if (is_leaf_) {
#if !defined(PRODUCT)
    // Set the thread object's top_exit_frame_info and VMTag to enable the
    // profiler to determine that thread is no longer executing Dart code.
    __ StoreToOffset(FPREG, THR,
                     compiler::target::Thread::top_exit_frame_info_offset());
    __ StoreToOffset(target, THR, compiler::target::Thread::vm_tag_offset());
#endif

    __ mv(A3, T3);  // TODO(rmacnak): Only when needed.
    __ mv(A4, T4);
    __ mv(A5, T5);
    __ jalr(target);

#if !defined(PRODUCT)
    __ LoadImmediate(temp1, compiler::target::Thread::vm_tag_dart_id());
    __ StoreToOffset(temp1, THR, compiler::target::Thread::vm_tag_offset());
    __ StoreToOffset(ZR, THR,
                     compiler::target::Thread::top_exit_frame_info_offset());
#endif
  } else {
    // We need to copy a dummy return address up into the dummy stack frame so
    // the stack walker will know which safepoint to use.
    //
    // AUIPC loads relative to itself.
    compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());
    __ auipc(temp1, 0);
    __ StoreToOffset(temp1, FPREG, kSavedCallerPcSlotFromFp * kWordSize);

    if (CanExecuteGeneratedCodeInSafepoint()) {
      // Update information in the thread object and enter a safepoint.
      __ LoadImmediate(temp1, compiler::target::Thread::exit_through_ffi());
      __ TransitionGeneratedToNative(target, FPREG, temp1,
                                     /*enter_safepoint=*/true);

      __ mv(A3, T3);  // TODO(rmacnak): Only when needed.
      __ mv(A4, T4);
      __ mv(A5, T5);
      __ jalr(target);

      // Update information in the thread object and leave the safepoint.
      __ TransitionNativeToGenerated(temp1, /*leave_safepoint=*/true);
    } else {
      // We cannot trust that this code will be executable within a safepoint.
      // Therefore we delegate the responsibility of entering/exiting the
      // safepoint to a stub which in the VM isolate's heap, which will never
      // lose execute permission.
      __ lx(temp1,
            compiler::Address(
                THR, compiler::target::Thread::
                         call_native_through_safepoint_entry_point_offset()));

      // Calls T0 and clobbers R19 (along with volatile registers).
      ASSERT(target == T0);
      __ mv(A3, T3);  // TODO(rmacnak): Only when needed.
      __ mv(A4, T4);
      __ mv(A5, T5);
      __ jalr(temp1);
    }

    if (marshaller_.IsHandle(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      ASSERT(temp1 != CallingConventions::kReturnReg);
      ASSERT(temp2 != CallingConventions::kReturnReg);
      compiler::Label not_error;
      __ LoadFromOffset(
          temp1,
          compiler::Address(CallingConventions::kReturnReg,
                            compiler::target::LocalHandle::ptr_offset()));
      __ BranchIfSmi(temp1, &not_error);
      __ LoadClassId(temp1, temp1);
      __ RangeCheck(temp1, temp2, kFirstErrorCid, kLastErrorCid,
                    compiler::AssemblerBase::kIfNotInRange, &not_error);

      // Slow path, use the stub to propagate error, to save on code-size.
      __ Comment("Slow path: call Dart_PropagateError through stub.");
      ASSERT(CallingConventions::ArgumentRegisters[0] ==
             CallingConventions::kReturnReg);
      __ lx(temp1,
            compiler::Address(
                THR, compiler::target::Thread::
                         call_native_through_safepoint_entry_point_offset()));
      __ lx(target, compiler::Address(
                        THR, kPropagateErrorRuntimeEntry.OffsetFromThread()));
      __ jalr(temp1);
#if defined(DEBUG)
      // We should never return with normal controlflow from this.
      __ ebreak();
#endif

      __ Bind(&not_error);
    }

    // Refresh pinned registers values (inc. write barrier mask and null
    // object).
    __ RestorePinnedRegisters();
  }

  EmitReturnMoves(compiler, temp1, temp2);

  if (is_leaf_) {
    // Restore the pre-aligned SP.
    __ mv(SPREG, saved_fp_or_sp);
  } else {
    __ LeaveDartFrame();

    // Restore the global object pool after returning from runtime (old space is
    // moving, so the GOP could have been relocated).
    if (FLAG_precompiled_mode) {
      __ SetupGlobalPoolAndDispatchTable();
    }
  }

  // PP is a volatile register, so it must be restored even for leaf FFI calls.
  __ RestorePoolPointer();
  __ set_constant_pool_allowed(true);
}

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  __ LeaveDartFrame();

  // The dummy return address is in RA, no need to pop it as on Intel.

  // These can be anything besides the return registers (A0, A1) and THR (S1).
  const Register vm_tag_reg = T2;
  const Register old_exit_frame_reg = T3;
  const Register old_exit_through_ffi_reg = T4;
  const Register tmp = T5;

  __ PopRegisterPair(old_exit_frame_reg, old_exit_through_ffi_reg);

  // Restore top_resource.
  __ PopRegisterPair(tmp, vm_tag_reg);
  __ StoreToOffset(tmp, THR, compiler::target::Thread::top_resource_offset());

  // Reset the exit frame info to old_exit_frame_reg *before* entering the
  // safepoint. The trampoline that called us will enter the safepoint on our
  // behalf.
  __ TransitionGeneratedToNative(vm_tag_reg, old_exit_frame_reg,
                                 old_exit_through_ffi_reg,
                                 /*enter_safepoint=*/false);

  __ PopNativeCalleeSavedRegisters();

  // Leave the entry frame.
  __ LeaveFrame();

  // Leave the dummy frame holding the pushed arguments.
  __ LeaveFrame();

  __ Ret();

  // For following blocks.
  __ set_constant_pool_allowed(true);
}

// Keep in sync with NativeReturnInstr::EmitNativeCode and ComputeInnerLRState.
void NativeEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Constant pool cannot be used until we enter the actual Dart frame.
  __ set_constant_pool_allowed(false);

  __ Bind(compiler->GetJumpLabel(this));

  // Create a dummy frame holding the pushed arguments. This simplifies
  // NativeReturnInstr::EmitNativeCode.
  __ EnterFrame(0);

  // Save the argument registers, in reverse order.
  __ mv(T3, A3);  // TODO(rmacnak): Only when needed.
  __ mv(T4, A4);
  __ mv(T5, A5);
  SaveArguments(compiler);

  // Enter the entry frame. NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  __ EnterFrame(0);

  // Save a space for the code object.
  __ PushImmediate(0);

  __ PushNativeCalleeSavedRegisters();

#if defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Refresh pinned registers values (inc. write barrier mask and null object).
  __ RestorePinnedRegisters();

  // Save the current VMTag on the stack.
  __ LoadFromOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());
  // Save the top resource.
  __ LoadFromOffset(A0, THR, compiler::target::Thread::top_resource_offset());
  __ PushRegisterPair(A0, TMP);

  __ StoreToOffset(ZR, THR, compiler::target::Thread::top_resource_offset());

  __ LoadFromOffset(A0, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ PushRegister(A0);

  // Save the top exit frame info. We don't set it to 0 yet:
  // TransitionNativeToGenerated will handle that.
  __ LoadFromOffset(A0, THR,
                    compiler::target::Thread::top_exit_frame_info_offset());
  __ PushRegister(A0);

  // In debug mode, verify that we've pushed the top exit frame info at the
  // correct offset from FP.
  __ EmitEntryFrameVerification();

  // The callback trampoline (caller) has already left the safepoint for us.
  __ TransitionNativeToGenerated(A0, /*exit_safepoint=*/false);

  // Now that the safepoint has ended, we can touch Dart objects without
  // handles.

  // Load the code object.
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

  // Put the code object in the reserved slot.
  __ StoreToOffset(CODE_REG, FPREG,
                   kPcMarkerSlotFromFp * compiler::target::kWordSize);
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    // We now load the pool pointer (PP) with a GC safe value as we are about to
    // invoke dart code. We don't need a real object pool here.
    // Smi zero does not work because ARM64 assumes PP to be untagged.
    __ LoadObject(PP, compiler::NullObject());
  }

  // Load a GC-safe value for the arguments descriptor (unused but tagged).
  __ mv(ARGS_DESC_REG, ZR);

  // Load a dummy return address which suggests that we are inside of
  // InvokeDartCodeStub. This is how the stack walker detects an entry frame.
  __ LoadFromOffset(RA, THR,
                    compiler::target::Thread::invoke_dart_code_stub_offset());
  __ LoadFieldFromOffset(RA, RA, compiler::target::Code::entry_point_offset());

  FunctionEntryInstr::EmitNativeCode(compiler);
}

#define R(r) (1 << r)

LocationSummary* CCallInstr::MakeLocationSummary(Zone* zone,
                                                 bool is_optimizing) const {
  constexpr Register saved_fp = CallingConventions::kSecondNonArgumentRegister;
  constexpr Register temp0 = CallingConventions::kFfiAnyNonAbiRegister;
  static_assert(saved_fp < temp0, "Unexpected ordering of registers in set.");
  LocationSummary* summary =
      MakeLocationSummaryInternal(zone, (R(saved_fp) | R(temp0)));
  return summary;
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
  // I.e., no use of A3/A4/A5.
  RELEASE_ASSERT(native_calling_convention_.argument_locations().length() < 4);
  __ CallCFunction(target_address);

  __ LeaveCFrame();  // Also restores PP=A5.
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
  __ lx(result,
        compiler::Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddShifted(TMP, result, char_code, kWordSizeLog2 - kSmiTagSize);
  __ lx(result,
        compiler::Address(TMP, Symbols::kNullCharCodeSymbolOffset * kWordSize));
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
  __ CompareImmediate(result, Smi::RawValue(1));
  __ BranchIf(EQUAL, &is_one, compiler::Assembler::kNearJump);
  __ li(result, Smi::RawValue(-1));
  __ j(&done, compiler::Assembler::kNearJump);
  __ Bind(&is_one);
  __ lbu(result, compiler::FieldAddress(str, OneByteString::data_offset()));
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

  // Address of input bytes.
  __ LoadFieldFromOffset(bytes_reg, bytes_reg,
                         compiler::target::PointerBase::data_offset());

  // Table.
  __ AddImmediate(
      table_reg, table_reg,
      compiler::target::OneByteString::data_offset() - kHeapObjectTag);

  // Pointers to start and end.
  __ add(bytes_ptr_reg, bytes_reg, start_reg);
  __ add(bytes_end_reg, bytes_reg, end_reg);

  // Initialize size and flags.
  __ li(size_reg, 0);
  __ li(flags_reg, 0);

  __ j(&loop_in, compiler::Assembler::kNearJump);
  __ Bind(&loop);

  // Read byte and increment pointer.
  __ lbu(temp_reg, compiler::Address(bytes_ptr_reg, 0));
  __ addi(bytes_ptr_reg, bytes_ptr_reg, 1);

  // Update size and flags based on byte value.
  __ add(temp_reg, table_reg, temp_reg);
  __ lbu(temp_reg, compiler::Address(temp_reg));
  __ or_(flags_reg, flags_reg, temp_reg);
  __ andi(temp_reg, temp_reg, kSizeMask);
  __ add(size_reg, size_reg, temp_reg);

  // Stop if end is reached.
  __ Bind(&loop_in);
  __ bltu(bytes_ptr_reg, bytes_end_reg, &loop, compiler::Assembler::kNearJump);

  // Write flags to field.
  __ AndImmediate(flags_reg, flags_reg, kFlagsMask);
  if (!IsScanFlagsUnboxed()) {
    __ SmiTag(flags_reg);
  }
  Register decoder_reg;
  const Location decoder_location = locs()->in(0);
  if (decoder_location.IsStackSlot()) {
    __ lx(decoder_temp_reg, LocationToStackSlotAddress(decoder_location));
    decoder_reg = decoder_temp_reg;
  } else {
    decoder_reg = decoder_location.reg();
  }
  const auto scan_flags_field_offset = scan_flags_field_.offset_in_bytes();
  if (scan_flags_field_.is_compressed() && !IsScanFlagsUnboxed()) {
    UNIMPLEMENTED();
  } else {
    __ LoadFieldFromOffset(flags_temp_reg, decoder_reg,
                           scan_flags_field_offset);
    __ or_(flags_temp_reg, flags_temp_reg, flags_reg);
    __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
  }
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

static bool CanBeImmediateIndex(Value* value, intptr_t cid, bool is_external) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == nullptr) || !constant->value().IsSmi()) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const int64_t offset =
      index * scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  if (IsITypeImm(offset)) {
    ASSERT(IsSTypeImm(offset));
    return true;
  }
  return false;
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
  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    locs->set_out(0, Location::RequiresFpuRegister());
#if XLEN == 32
  } else if (representation() == kUnboxedInt64) {
    ASSERT(class_id() == kTypedDataInt64ArrayCid ||
           class_id() == kTypedDataUint64ArrayCid);
    locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
#endif
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
  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    const FRegister result = locs()->out(0).fpu_reg();
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        __ flw(result, element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        // Load double precision float.
        __ fld(result, element_address);
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        UNIMPLEMENTED();
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  switch (class_id()) {
    case kTypedDataInt32ArrayCid: {
      ASSERT(representation() == kUnboxedInt32);
      const Register result = locs()->out(0).reg();
      __ lw(result, element_address);
      break;
    }
    case kTypedDataUint32ArrayCid: {
      ASSERT(representation() == kUnboxedUint32);
      const Register result = locs()->out(0).reg();
#if XLEN == 32
      __ lw(result, element_address);
#else
      __ lwu(result, element_address);
#endif
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      ASSERT(representation() == kUnboxedInt64);
#if XLEN == 32
      ASSERT(locs()->out(0).IsPairLocation());
      PairLocation* result_pair = locs()->out(0).AsPairLocation();
      const Register result_lo = result_pair->At(0).reg();
      const Register result_hi = result_pair->At(1).reg();
      __ lw(result_lo, element_address);
      __ lw(result_hi, compiler::Address(element_address.base(),
                                         element_address.offset() + 4));
#else
      const Register result = locs()->out(0).reg();
      __ ld(result, element_address);
#endif
      break;
    }
    case kTypedDataInt8ArrayCid: {
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      const Register result = locs()->out(0).reg();
      __ lb(result, element_address);
      break;
    }
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid: {
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      const Register result = locs()->out(0).reg();
      __ lbu(result, element_address);
      break;
    }
    case kTypedDataInt16ArrayCid: {
      ASSERT(representation() == kUnboxedIntPtr);
      const Register result = locs()->out(0).reg();
      __ lh(result, element_address);
      break;
    }
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid: {
      ASSERT(representation() == kUnboxedIntPtr);
      const Register result = locs()->out(0).reg();
      __ lhu(result, element_address);
      break;
    }
    default: {
      ASSERT(representation() == kTagged);
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
             (class_id() == kTypeArgumentsCid) || (class_id() == kRecordCid));
      const Register result = locs()->out(0).reg();
      __ lx(result, element_address);
      break;
    }
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
#if XLEN == 32
  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT(representation() == kTagged);
    summary->set_out(0, Location::RequiresRegister());
  }
#else
  summary->set_out(0, Location::RequiresRegister());
#endif
  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);
  compiler::OperandSize sz = compiler::kByte;

#if XLEN == 32
  if (representation() == kUnboxedInt64) {
    ASSERT(compiler->is_optimizing());
    ASSERT(locs()->out(0).IsPairLocation());
    UNIMPLEMENTED();
  }
#endif

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
  switch (sz) {
    case compiler::kUnsignedByte:
      __ lbu(result, element_address);
      break;
    case compiler::kUnsignedTwoBytes:
      __ lhu(result, element_address);
      break;
    case compiler::kUnsignedFourBytes:
#if XLEN == 32
      __ lw(result, element_address);
#else
      __ lwu(result, element_address);
#endif
      break;
    default:
      UNREACHABLE();
  }

  ASSERT(can_pack_into_smi());
  __ SmiTag(result);
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
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataUint8ClampedArrayCid:
      locs->set_in(2, LocationRegisterOrConstant(value()));
      break;
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      ConstantInstr* constant = value()->definition()->AsConstant();
      if (constant != nullptr && constant->HasZeroRepresentation()) {
        locs->set_in(2, Location::Constant(constant));
      } else {
        locs->set_in(2, Location::RequiresRegister());
      }
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
#if XLEN == 32
      locs->set_in(2, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
#else
      ConstantInstr* constant = value()->definition()->AsConstant();
      if (constant != nullptr && constant->HasZeroRepresentation()) {
        locs->set_in(2, Location::Constant(constant));
      } else {
        locs->set_in(2, Location::RequiresRegister());
      }
#endif
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      ConstantInstr* constant = value()->definition()->AsConstant();
      if (constant != nullptr && constant->HasZeroRepresentation()) {
        locs->set_in(2, Location::Constant(constant));
      } else {
        locs->set_in(2, Location::RequiresFpuRegister());
      }
      break;
    }
    case kTypedDataFloat64ArrayCid: {
#if XLEN == 32
      locs->set_in(2, Location::RequiresFpuRegister());
#else
      ConstantInstr* constant = value()->definition()->AsConstant();
      if (constant != nullptr && constant->HasZeroRepresentation()) {
        locs->set_in(2, Location::Constant(constant));
      } else {
        locs->set_in(2, Location::RequiresFpuRegister());
      }
#endif
      break;
    }
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
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sb(ZR, element_address);
      } else {
        const Register value = locs()->in(2).reg();
        __ sb(value, element_address);
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
        if (value == 0) {
          __ sb(ZR, element_address);
        } else {
          __ LoadImmediate(TMP, static_cast<int8_t>(value));
          __ sb(TMP, element_address);
        }
      } else {
        const Register value = locs()->in(2).reg();

        compiler::Label store_zero, store_ff, done;
        __ blt(value, ZR, &store_zero, compiler::Assembler::kNearJump);

        __ li(TMP, 0xFF);
        __ bgt(value, TMP, &store_ff, compiler::Assembler::kNearJump);

        __ sb(value, element_address);
        __ j(&done, compiler::Assembler::kNearJump);

        __ Bind(&store_zero);
        __ mv(TMP, ZR);

        __ Bind(&store_ff);
        __ sb(TMP, element_address);

        __ Bind(&done);
      }
      break;
    }
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sh(ZR, element_address);
      } else {
        __ sh(locs()->in(2).reg(), element_address);
      }
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sw(ZR, element_address);
      } else {
        __ sw(locs()->in(2).reg(), element_address);
      }
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
#if XLEN >= 64
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sd(ZR, element_address);
      } else {
        __ sd(locs()->in(2).reg(), element_address);
      }
#else
      PairLocation* value_pair = locs()->in(2).AsPairLocation();
      Register value_lo = value_pair->At(0).reg();
      Register value_hi = value_pair->At(1).reg();
      __ sw(value_lo, element_address);
      __ sw(value_hi, compiler::Address(element_address.base(),
                                        element_address.offset() + 4));
#endif
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sw(ZR, element_address);
      } else {
        __ fsw(locs()->in(2).fpu_reg(), element_address);
      }
      break;
    }
    case kTypedDataFloat64ArrayCid: {
#if XLEN >= 64
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ sd(ZR, element_address);
      } else {
        __ fsd(locs()->in(2).fpu_reg(), element_address);
      }
#else
      __ fsd(locs()->in(2).fpu_reg(), element_address);
#endif
      break;
    }
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid: {
      UNIMPLEMENTED();
      break;
    }
    default:
      UNREACHABLE();
  }
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

DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldTypeInstr)

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
          : nullptr;

  compiler::Label* fail = (deopt != nullptr) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle((field().Original())));

    compiler::FieldAddress field_cid_operand(field_reg,
                                             Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      compiler::Label skip_length_check;
      __ lw(TMP, field_cid_operand);
      __ CompareRegisters(value_cid_reg, TMP);
      __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);
      __ lw(TMP, field_nullability_operand);
      __ CompareRegisters(value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ lw(value_cid_reg, field_nullability_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      compiler::Label skip_length_check;
      __ lw(value_cid_reg, field_cid_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
    }
    __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    // Length guard will be emitted separately when needed via GuardFieldLength
    // instruction after GuardFieldClass.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ lw(TMP, field_cid_operand);
      __ CompareImmediate(TMP, kIllegalCid);
      __ BranchIf(NE, fail);

      if (value_cid == kDynamicCid) {
        __ sw(value_cid_reg, field_cid_operand);
        __ sw(value_cid_reg, field_nullability_operand);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ sw(TMP, field_cid_operand);
        __ sw(TMP, field_nullability_operand);
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
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ j(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != nullptr);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
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
      // This would normally be caught by Canonicalize, but RemoveRedefinitions
      // may sometimes produce the situation after the last Canonicalize pass.
    } else {
      // Both value's and field's class id is known.
      ASSERT(value_cid != nullability);
      __ j(fail);
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

    __ lb(offset_reg,
          compiler::FieldAddress(
              field_reg, Field::guarded_list_length_in_object_offset_offset()));
    __ LoadCompressed(
        length_reg,
        compiler::FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ bltz(offset_reg, &ok, compiler::Assembler::kNearJump);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ add(TMP, value_reg, offset_reg);
    __ lx(TMP, compiler::Address(TMP, 0));
    __ CompareObjectRegisters(length_reg, TMP);

    if (deopt == nullptr) {
      __ BranchIf(EQ, &ok, compiler::Assembler::kNearJump);

      __ PushRegisterPair(value_reg, field_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
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

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();

  compiler->used_static_fields().Add(&field());

  __ LoadFromOffset(TMP, THR,
                    compiler::target::Thread::field_table_values_offset());
  // Note: static fields ids won't be changed by hot-reload.
  __ StoreToOffset(value, TMP, compiler::target::FieldTable::OffsetOf(field()));
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
                      AllocateArrayABI::kResultReg,  // instance
                      T3,                            // end address
                      T4, T5);
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // R3: new object end address.

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
  // T3: new object end address.
  // T5: iterator which initially points to the start of the variable
  // data area to be initialized.
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
      __ j(&init_loop);
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

LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_temp(1, Location::RegisterLocation(T2));
  locs->set_temp(2, Location::RegisterLocation(T3));
  locs->set_out(0, Location::RegisterLocation(A0));
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

    __ LoadImmediate(T1, instruction()->num_context_variables());
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               UntaggedPcDescriptors::kOther, locs,
                               instruction()->deopt_id(), slow_path_env);
    ASSERT(instruction()->locs()->out(0).reg() == A0);
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ j(exit_label());
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

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                        result,  // instance
                        temp0, temp1, temp2);

    // Setup up number of context variables field (int32_t).
    __ LoadImmediate(temp0, num_context_variables());
    __ sw(temp0,
          compiler::FieldAddress(result, Context::num_variables_offset()));
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
    if (compiler->isolate_group()->use_osr() && osr_entry_label()->IsLinked()) {
      const Register value = locs->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ li(value, Thread::kOsrRequest);
      __ sx(value,
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
    ASSERT(compiler->pending_deoptimization_env_ == nullptr);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    if (using_shared_stub) {
      auto object_store = compiler->isolate_group()->object_store();
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

  __ lx(TMP,
        compiler::Address(THR, compiler::target::Thread::stack_limit_offset()));
  __ bleu(SP, TMP, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register function = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(function, compiler->parsed_function().function());
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
    __ LoadFieldFromOffset(TMP, function, Function::usage_counter_offset(),
                           compiler::kFourBytes);
    __ addi(TMP, TMP, 1);
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
    // Immediate shift operation takes 6/5 bits for the count.
    const intptr_t kCountLimit = XLEN - 1;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    __ slli(result, left, value);
    if (shift_left->can_overflow()) {
      ASSERT(result != left);
      __ srai(TMP2, result, value);
      __ bne(left, TMP2, deopt);  // Overflow.
    }
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
        __ bltz(right, deopt);
        __ mv(result, ZR);
        return;
      }
      const intptr_t max_right =
          compiler::target::kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ CompareObject(right, Smi::ZoneHandle(Smi::New(max_right)));
        __ BranchIf(CS, deopt);
      }
      __ SmiUntag(TMP, right);
      __ sll(result, left, TMP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ bltz(right, deopt);
      }

      compiler::Label done, is_not_zero;
      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ BranchIf(LESS, &is_not_zero, compiler::Assembler::kNearJump);
      __ li(result, 0);
      __ j(&done, compiler::Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(TMP, right);
      __ sll(result, left, TMP);
      __ Bind(&done);
    } else {
      __ SmiUntag(TMP, right);
      __ sll(result, left, TMP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ BranchIf(CS, deopt);
    }
    __ SmiUntag(TMP, right);
    ASSERT(result != left);
    __ sll(result, left, TMP);
    __ sra(TMP, result, TMP);
    __ bne(left, TMP, deopt);  // Overflow.
  }
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      ((op_kind() == Token::kUSHR) || (op_kind() == Token::kMUL)) ? 1 : 0;
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
  if (kNumTemps == 1) {
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
  compiler::Label* deopt = nullptr;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intx_t imm = static_cast<intx_t>(constant.ptr());
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, imm);
        } else {
          __ AddImmediateBranchOverflow(result, left, imm, deopt);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, -imm);
        } else {
          // Negating imm and using AddImmediateSetFlags would not detect the
          // overflow when imm == kMinInt64.
          __ SubtractImmediateBranchOverflow(result, left, imm, deopt);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        if (deopt == nullptr) {
          __ LoadImmediate(TMP, value);
          __ mul(result, left, TMP);
        } else {
          __ MultiplyImmediateBranchOverflow(result, left, value, deopt);
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
        __ srai(TMP, left, XLEN - 1);
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = TMP2;
        __ srli(TMP, TMP, XLEN - shift_count);
        __ add(temp, left, TMP);
        ASSERT(shift_count > 0);
        __ srai(result, temp, shift_count);
        if (value < 0) {
          __ neg(result, result);
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
        // Asr operation masks the count to 6/5 bits.
        const intptr_t kCountLimit = XLEN - 1;
        intptr_t value = Smi::Cast(constant).Value();
        __ srai(result, left, Utils::Minimum(value + kSmiTagSize, kCountLimit));
        __ SmiTag(result);
        break;
      }
      case Token::kUSHR: {
#if XLEN == 32
        const intptr_t value = compiler::target::SmiValue(constant);
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
            __ bltz(left, deopt);
          } else {
            // Operation cannot overflow only if left value is always
            // non-negative.
            ASSERT(!can_overflow());
          }
          // At this point left operand is non-negative, so unsigned shift
          // can't overflow.
          if (value >= compiler::target::kSmiBits) {
            __ li(result, 0);
          } else {
            __ srli(result, left, value + kSmiTagSize);
            __ SmiTag(result);
          }
        } else {
          // Shift amount > 32, and the result is guaranteed to fit into Smi.
          // Low (Smi) part of the left operand is shifted out.
          // High part is filled with sign bits.
          __ srai(result, left, 31);
          __ srli(result, result, value - 32);
          __ SmiTag(result);
        }
#else
        // Lsr operation masks the count to 6 bits, but
        // unsigned shifts by >= kBitsPerInt64 are eliminated by
        // BinaryIntegerOpInstr::Canonicalize.
        const intptr_t kCountLimit = XLEN - 1;
        intptr_t value = Smi::Cast(constant).Value();
        ASSERT((value >= 0) && (value <= kCountLimit));
        __ SmiUntag(TMP, left);
        __ srli(TMP, TMP, value);
        __ SmiTag(result, TMP);
        if (deopt != nullptr) {
          __ SmiUntag(TMP2, result);
          __ bne(TMP, TMP2, deopt);
        }
#endif
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
      if (deopt == nullptr) {
        __ add(result, left, right);
      } else if (RangeUtils::IsPositive(right_range())) {
        ASSERT(result != left);
        __ add(result, left, right);
        __ blt(result, left, deopt);
      } else if (RangeUtils::IsNegative(right_range())) {
        ASSERT(result != left);
        __ add(result, left, right);
        __ bgt(result, left, deopt);
      } else {
        __ AddBranchOverflow(result, left, right, deopt);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == nullptr) {
        __ sub(result, left, right);
      } else if (RangeUtils::IsPositive(right_range())) {
        ASSERT(result != left);
        __ sub(result, left, right);
        __ bgt(result, left, deopt);
      } else if (RangeUtils::IsNegative(right_range())) {
        ASSERT(result != left);
        __ sub(result, left, right);
        __ blt(result, left, deopt);
      } else {
        __ SubtractBranchOverflow(result, left, right, deopt);
      }
      break;
    }
    case Token::kMUL: {
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      if (deopt == nullptr) {
        __ mul(result, temp, right);
      } else {
        __ MultiplyBranchOverflow(result, temp, right, deopt);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ or_(result, left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xor_(result, left, right);
      break;
    }
    case Token::kTRUNCDIV: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ beqz(right, deopt);
      }
      __ SmiUntag(TMP, left);
      __ SmiUntag(TMP2, right);
      __ div(TMP, TMP, TMP2);
      __ SmiTag(result, TMP);

      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ SmiUntag(TMP2, result);
        __ bne(TMP, TMP2, deopt);
      }
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ beqz(right, deopt);
      }
      __ SmiUntag(TMP, left);
      __ SmiUntag(TMP2, right);

      __ rem(result, TMP, TMP2);

      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      compiler::Label done, adjust;
      __ bgez(result, &done, compiler::Assembler::kNearJump);
      // Result is negative, adjust it.
      __ bgez(right, &adjust, compiler::Assembler::kNearJump);
      __ sub(result, result, TMP2);
      __ j(&done, compiler::Assembler::kNearJump);
      __ Bind(&adjust);
      __ add(result, result, TMP2);
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ bltz(right, deopt);
      }
      __ SmiUntag(TMP, right);
      // asrv[w] operation masks the count to 6/5 bits.
      const intptr_t kCountLimit = XLEN - 1;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ LoadImmediate(TMP2, kCountLimit);
        compiler::Label shift_in_bounds;
        __ ble(TMP, TMP2, &shift_in_bounds, compiler::Assembler::kNearJump);
        __ mv(TMP, TMP2);
        __ Bind(&shift_in_bounds);
      }
      __ SmiUntag(TMP2, left);
      __ sra(result, TMP2, TMP);
      __ SmiTag(result);
      break;
    }
    case Token::kUSHR: {
#if XLEN == 32
      compiler::Label done;
      __ SmiUntag(TMP, right);
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
        if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(),
                                               kBitsPerInt64 - 1)) {
          ASSERT(result != left);
          ASSERT(result != right);
          __ li(result, 0);
          __ CompareImmediate(TMP, kBitsPerInt64);
          // If shift amount >= 64, then result is 0.
          __ BranchIf(GE, &done, compiler::Assembler::kNearJump);
        }
        __ CompareImmediate(TMP, 64 - compiler::target::kSmiBits);
        // Shift amount >= 64 - kSmiBits > 32, but < 64.
        // Result is guaranteed to fit into Smi range.
        // Low (Smi) part of the left operand is shifted out.
        // High part is filled with sign bits.
        compiler::Label next;
        __ BranchIf(LT, &next, compiler::Assembler::kNearJump);
        __ subi(TMP, TMP, 32);
        __ srai(result, left, 31);
        __ srl(result, result, TMP);
        __ SmiTag(result);
        __ j(&done, compiler::Assembler::kNearJump);
        __ Bind(&next);
      }
      // Shift amount < 64 - kSmiBits.
      // If left is negative, then result will not fit into Smi range.
      // Also deopt in case of negative shift amount.
      if (deopt != nullptr) {
        __ bltz(left, deopt);
        __ bltz(right, deopt);
      } else {
        ASSERT(!can_overflow());
      }
      // At this point left operand is non-negative, so unsigned shift
      // can't overflow.
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(),
                                             compiler::target::kSmiBits - 1)) {
        ASSERT(result != left);
        ASSERT(result != right);
        __ li(result, 0);
        __ CompareImmediate(TMP, compiler::target::kSmiBits);
        // Left operand >= 0, shift amount >= kSmiBits. Result is 0.
        __ BranchIf(GE, &done, compiler::Assembler::kNearJump);
      }
      // Left operand >= 0, shift amount < kSmiBits < 32.
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ srl(result, temp, TMP);
      __ SmiTag(result);
      __ Bind(&done);
#elif XLEN == 64
      if (CanDeoptimize()) {
        __ bltz(right, deopt);
      }
      __ SmiUntag(TMP, right);
      // lsrv operation masks the count to 6 bits.
      const intptr_t kCountLimit = XLEN - 1;
      COMPILE_ASSERT(kCountLimit + 1 == kBitsPerInt64);
      compiler::Label done;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ LoadImmediate(TMP2, kCountLimit);
        compiler::Label shift_in_bounds;
        __ ble(TMP, TMP2, &shift_in_bounds, compiler::Assembler::kNearJump);
        __ mv(result, ZR);
        __ j(&done, compiler::Assembler::kNearJump);
        __ Bind(&shift_in_bounds);
      }
      __ SmiUntag(TMP2, left);
      __ srl(TMP, TMP2, TMP);
      __ SmiTag(result, TMP);
      if (deopt != nullptr) {
        __ SmiUntag(TMP2, result);
        __ bne(TMP, TMP2, deopt);
      }
      __ Bind(&done);
#else
      UNIMPLEMENTED();
#endif
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
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp);
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
    __ or_(TMP, left, right);
    __ BranchIfSmi(TMP, deopt);
  }
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
      __ fcvtds(FpuTMP, value);
      __ StoreDFieldToOffset(FpuTMP, out_reg, ValueOffset());
      break;
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      UNIMPLEMENTED();
      break;
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  ASSERT(!RepresentationUtils::IsUnsigned(representation()));
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
#if XLEN == 32
  } else if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
#endif
  } else {
    summary->set_out(0, Location::RequiresRegister());
  }
  return summary;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt64: {
#if XLEN == 32
      PairLocation* result = locs()->out(0).AsPairLocation();
      ASSERT(result->At(0).reg() != box);
      __ LoadFieldFromOffset(result->At(0).reg(), box, ValueOffset());
      __ LoadFieldFromOffset(result->At(1).reg(), box,
                             ValueOffset() + compiler::target::kWordSize);
#elif XLEN == 64
      const Register result = locs()->out(0).reg();
      __ ld(result, compiler::FieldAddress(box, ValueOffset()));
#endif
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
      __ fcvtsd(result, result);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      UNIMPLEMENTED();
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
#if XLEN == 32
    case kUnboxedInt64: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      __ SmiUntag(result->At(0).reg(), box);
      __ srai(result->At(1).reg(), box, XLEN - 1);  // SignFill.
      break;
    }
#elif XLEN == 64
    case kUnboxedInt32:
    case kUnboxedInt64: {
      const Register result = locs()->out(0).reg();
      __ SmiUntag(result, box);
      break;
    }
#endif

    case kUnboxedDouble: {
      const FRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(TMP, box);
#if XLEN == 32
      __ fcvtdw(result, TMP);
#elif XLEN == 64
      __ fcvtdl(result, TMP);
#endif
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
  __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
  __ LoadFieldFromOffset(result, value, Mint::value_offset(),
                         compiler::kFourBytes);
  __ Bind(&done);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
#if XLEN == 32
  const Register box = locs()->in(0).reg();
  PairLocation* result = locs()->out(0).AsPairLocation();
  ASSERT(result->At(0).reg() != box);
  ASSERT(result->At(1).reg() != box);
  compiler::Label done;
  __ srai(result->At(1).reg(), box, XLEN - 1);  // SignFill
  __ SmiUntag(result->At(0).reg(), box);
  __ BranchIfSmi(box, &done, compiler::Assembler::kNearJump);
  EmitLoadFromBox(compiler);
  __ Bind(&done);
#else
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(value != result);
  compiler::Label done;
  __ SmiUntag(result, value);
  __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
  __ LoadFieldFromOffset(result, value, Mint::value_offset());
  __ Bind(&done);
#endif
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
#if XLEN > 32
  // ValueFitsSmi() may be overly conservative and false because we only
  // perform range analysis during optimized compilation.
  const bool kMayAllocateMint = false;
#else
  const bool kMayAllocateMint = !ValueFitsSmi();
#endif
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      kMayAllocateMint ? LocationSummary::kCallOnSlowPath
                                       : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

#if XLEN > 32
  ASSERT(compiler::target::kSmiBits >= 32);
  __ slli(out, value, XLEN - 32);
  if (from_representation() == kUnboxedInt32) {
    __ srai(out, out, XLEN - 32 - kSmiTagShift);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ srli(out, out, XLEN - 32 - kSmiTagShift);
  }
#elif XLEN == 32
  __ slli(out, value, 1);
  if (ValueFitsSmi()) {
    return;
  }
  compiler::Label done;
  if (from_representation() == kUnboxedInt32) {
    __ srai(TMP, out, 1);
    __ beq(TMP, value, &done);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ srli(TMP, value, 30);
    __ beqz(TMP, &done);
  }

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  TMP);
  __ StoreFieldToOffset(value, out, compiler::target::Mint::value_offset());
  if (from_representation() == kUnboxedInt32) {
    __ srai(TMP, value, 31);
    __ StoreFieldToOffset(
        TMP, out,
        compiler::target::Mint::value_offset() + compiler::target::kWordSize);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ StoreFieldToOffset(
        ZR, out,
        compiler::target::Mint::value_offset() + compiler::target::kWordSize);
  }
  __ Bind(&done);
#endif
}

LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  // Shared slow path is used in BoxInt64Instr::EmitNativeCode in
  // FLAG_use_bare_instructions mode and only after VM isolate stubs where
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
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      ValueFitsSmi()
          ? LocationSummary::kNoCall
          : ((shared_slow_path_call ? LocationSummary::kCallOnSharedSlowPath
                                    : LocationSummary::kCallOnSlowPath)));
#if XLEN == 32
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
#else
  summary->set_in(0, Location::RequiresRegister());
#endif
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
#if XLEN == 32
  if (ValueFitsSmi()) {
    PairLocation* value_pair = locs()->in(0).AsPairLocation();
    Register value_lo = value_pair->At(0).reg();
    Register out_reg = locs()->out(0).reg();
    __ SmiTag(out_reg, value_lo);
    return;
  }

  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register out_reg = locs()->out(0).reg();

  compiler::Label overflow, done;
  __ SmiTag(out_reg, value_lo);
  __ srai(TMP, out_reg, kSmiTagSize);
  __ bne(value_lo, TMP, &overflow, compiler::Assembler::kNearJump);
  __ srai(TMP, out_reg, XLEN - 1);  // SignFill
  __ beq(value_hi, TMP, &done, compiler::Assembler::kNearJump);

  __ Bind(&overflow);
  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out_reg, TMP);
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
    BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                    out_reg, TMP);
  }

  __ StoreFieldToOffset(value_lo, out_reg,
                        compiler::target::Mint::value_offset());
  __ StoreFieldToOffset(
      value_hi, out_reg,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize);
  __ Bind(&done);
#else
  Register in = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  if (ValueFitsSmi()) {
    __ SmiTag(out, in);
    return;
  }
  ASSERT(kSmiTag == 0);
  compiler::Label done;

  ASSERT(out != in);
  __ SmiTag(out, in);
  __ SmiUntag(TMP, out);
  __ beq(in, TMP, &done);  // No overflow.

  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out, TMP);
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
                                    TMP);
  }

  __ StoreToOffset(in, out, Mint::value_offset() - kHeapObjectTag);
  __ Bind(&done);
#endif
}

#if XLEN == 32
static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register mint,
                              Register result,
                              compiler::Label* deopt) {
  __ LoadFieldFromOffset(result, mint, compiler::target::Mint::value_offset());
  if (deopt != nullptr) {
    __ LoadFieldFromOffset(
        TMP, mint,
        compiler::target::Mint::value_offset() + compiler::target::kWordSize);
    __ srai(TMP2, result, XLEN - 1);
    __ bne(TMP, TMP2, deopt);
  }
}
#endif

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
#if XLEN == 32
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : nullptr;
  compiler::Label* out_of_range = !is_truncating() ? deopt : nullptr;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    LoadInt32FromMint(compiler, value, out, out_of_range);
  } else if (!CanDeoptimize()) {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    LoadInt32FromMint(compiler, value, out, nullptr);
    __ Bind(&done);
  } else {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    __ CompareClassId(value, kMintCid, TMP);
    __ BranchIf(NE, deopt);
    LoadInt32FromMint(compiler, value, out, out_of_range);
    __ Bind(&done);
  }
#elif XLEN == 64
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : nullptr;

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
    __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  } else {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    __ CompareClassId(value, kMintCid, TMP);
    __ BranchIf(NE, deopt);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != nullptr)) {
    ASSERT(representation() == kUnboxedInt32);
    __ sextw(TMP, out);
    __ bne(TMP, out, deopt);
  }
#endif
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
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition DoubleTestOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const FRegister value = locs()->in(0).fpu_reg();

  __ fclassd(TMP, value);
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    __ TestImmediate(TMP, kFClassSignallingNan | kFClassQuietNan);
  } else if (op_kind() == MethodRecognizer::kDouble_getIsInfinite) {
    __ TestImmediate(TMP, kFClassNegInfinity | kFClassPosInfinity);
  } else {
    UNREACHABLE();
  }
  return kind() == Token::kEQ ? NOT_ZERO : ZERO;
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

DEFINE_EMIT(SimdBinaryOp, (FRegister result, FRegister left, FRegister right)) {
  UNIMPLEMENTED();
}

#define SIMD_OP_SIMPLE_UNARY(V)                                                \
  SIMD_OP_FLOAT_ARITH(V, Sqrt, vsqrt)                                          \
  SIMD_OP_FLOAT_ARITH(V, Negate, vneg)                                         \
  SIMD_OP_FLOAT_ARITH(V, Abs, vabs)                                            \
  V(Float32x4Reciprocal, VRecps)                                               \
  V(Float32x4ReciprocalSqrt, VRSqrts)

DEFINE_EMIT(SimdUnaryOp, (FRegister result, FRegister value)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Simd32x4GetSignMask,
            (Register out, FRegister value, Temp<Register> temp)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(
    Float32x4FromDoubles,
    (FRegister r, FRegister v0, FRegister v1, FRegister v2, FRegister v3)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(
    Float32x4Clamp,
    (FRegister result, FRegister value, FRegister lower, FRegister upper)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(
    Float64x2Clamp,
    (FRegister result, FRegister value, FRegister lower, FRegister upper)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Float32x4With,
            (FRegister result, FRegister replacement, FRegister value)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Simd32x4ToSimd32x4, (SameAsFirstInput, FRegister value)) {
  // TODO(dartbug.com/30949) these operations are essentially nop and should
  // not generate any code. They should be removed from the graph before
  // code generation.
}

DEFINE_EMIT(SimdZero, (FRegister v)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Float64x2GetSignMask, (Register out, FRegister value)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Float64x2With,
            (SameAsFirstInput, FRegister left, FRegister right)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(
    Int32x4FromInts,
    (FRegister result, Register v0, Register v1, Register v2, Register v3)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Int32x4FromBools,
            (FRegister result,
             Register v0,
             Register v1,
             Register v2,
             Register v3,
             Temp<Register> temp)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Int32x4GetFlag, (Register result, FRegister value)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Int32x4Select,
            (FRegister out,
             FRegister mask,
             FRegister trueValue,
             FRegister falseValue,
             Temp<FRegister> temp)) {
  UNIMPLEMENTED();
}

DEFINE_EMIT(Int32x4WithFlag,
            (SameAsFirstInput, FRegister mask, Register flag)) {
  UNIMPLEMENTED();
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
  CASE(Float32x4GetX)                                                          \
  CASE(Float32x4GetY)                                                          \
  CASE(Float32x4GetZ)                                                          \
  CASE(Float32x4GetW)                                                          \
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
  CASE(Float64x2Clamp)                                                         \
  ____(Float64x2Clamp)                                                         \
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
  return nullptr;
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
    const FRegister val = locs()->in(0).fpu_reg();
    const FRegister result = locs()->out(0).fpu_reg();
    __ fsqrtd(result, val);
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    const FRegister val = locs()->in(0).fpu_reg();
    const FRegister result = locs()->out(0).fpu_reg();
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
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_in(1, Location::RegisterLocation(A1));
  summary->set_in(2, Location::RegisterLocation(A2));
  // Can't specify A3 because it is blocked in register allocation as TMP.
  summary->set_in(3, Location::Any());
  summary->set_out(0, Location::RegisterLocation(A0));
  return summary;
}

void CaseInsensitiveCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler->intrinsic_mode()) {
    // Would also need to preserve CODE_REG and ARGS_DESC_REG.
    UNIMPLEMENTED();
  }

  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/0,
                                /*preserve_registers=*/false);
  if (locs()->in(3).IsRegister()) {
    __ mv(A3, locs()->in(3).reg());
  } else if (locs()->in(3).IsStackSlot()) {
    __ lx(A3, LocationToStackSlotAddress(locs()->in(3)));
  } else {
    UNIMPLEMENTED();
  }
  rt.Call(TargetFunction(), TargetFunction().argument_count());
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
  const bool is_min = (op_kind() == MethodRecognizer::kMathMin);
  if (result_cid() == kDoubleCid) {
    compiler::Label done, returns_nan, are_equal;
    const FRegister left = locs()->in(0).fpu_reg();
    const FRegister right = locs()->in(1).fpu_reg();
    const FRegister result = locs()->out(0).fpu_reg();
    if (is_min) {
      __ fmind(result, left, right);
    } else {
      __ fmaxd(result, left, right);
    }
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  compiler::Label choose_right, done;
  if (is_min) {
    __ bgt(left, right, &choose_right, compiler::Assembler::kNearJump);
  } else {
    __ blt(left, right, &choose_right, compiler::Assembler::kNearJump);
  }
  __ mv(result, left);
  __ j(&done, compiler::Assembler::kNearJump);
  __ Bind(&choose_right);
  __ mv(result, right);
  __ Bind(&done);
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
      __ neg(result, value);
      ASSERT(result != value);
      __ beq(result, value, deopt);  // Overflow.
      break;
    }
    case Token::kBIT_NOT:
      __ not_(result, value);
      __ andi(result, result, ~kSmiTagMask);  // Remove inverted smi-tag.
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
  const FRegister result = locs()->out(0).fpu_reg();
  const FRegister value = locs()->in(0).fpu_reg();
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
  const FRegister result = locs()->out(0).fpu_reg();
  __ fcvtdw(result, value);
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
#if XLEN == 32
  __ fcvtdw(result, TMP);
#else
  __ fcvtdl(result, TMP);
#endif
}

LocationSummary* Int64ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
#if XLEN == 32
  UNIMPLEMENTED();
  return nullptr;
#else
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
#endif
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  UNIMPLEMENTED();
#else
  const Register value = locs()->in(0).reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ fcvtdl(result, value);
#endif
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
  const Register result = locs()->out(0).reg();
  const FRegister value_double = locs()->in(0).fpu_reg();

  DoubleToIntegerSlowPath* slow_path =
      new DoubleToIntegerSlowPath(this, value_double);
  compiler->AddSlowPathCode(slow_path);

  RoundingMode rounding;
  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleToInteger:
      rounding = RTZ;
      break;
    case MethodRecognizer::kDoubleFloorToInt:
      rounding = RDN;
      break;
    case MethodRecognizer::kDoubleCeilToInt:
      rounding = RUP;
      break;
    default:
      UNREACHABLE();
  }

#if XLEN == 32
  __ fcvtwd(TMP, value_double, rounding);
#else
  __ fcvtld(TMP, value_double, rounding);
#endif
  // Underflow -> minint -> Smi tagging fails
  // Overflow, NaN -> maxint -> Smi tagging fails

  // Check for overflow and that it fits into Smi.
  __ SmiTag(result, TMP);
  __ SmiUntag(TMP2, result);
  __ bne(TMP, TMP2, slow_path->entry_label());
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
  const Register result = locs()->out(0).reg();
  const FRegister value = locs()->in(0).fpu_reg();

#if XLEN == 32
  __ fcvtwd(TMP, value, RTZ);  // Round To Zero (truncation).
#else
  __ fcvtld(TMP, value, RTZ);  // Round To Zero (truncation).
#endif
  // Underflow -> minint -> Smi tagging fails
  // Overflow, NaN -> maxint -> Smi tagging fails

  // Check for overflow and that it fits into Smi.
  __ SmiTag(result, TMP);
  __ SmiUntag(TMP2, result);
  __ bne(TMP, TMP2, deopt);
}

LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return nullptr;
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
  const FRegister value = locs()->in(0).fpu_reg();
  const FRegister result = locs()->out(0).fpu_reg();
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
  const FRegister value = locs()->in(0).fpu_reg();
  const FRegister result = locs()->out(0).fpu_reg();
  __ fcvtds(result, value);
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(FA0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(FA1));
  }
  result->set_out(0, Location::FpuRegisterLocation(FA0));
  return result;
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler->intrinsic_mode()) {
    // Would also need to preserve CODE_REG and ARGS_DESC_REG.
    UNIMPLEMENTED();
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

  // TODO(riscv): Special case pow?
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
    const FRegister out = locs()->out(0).fpu_reg();
    const FRegister in = in_loc.fpu_reg();
    __ fmvd(out, in);
  } else {
    ASSERT(representation() == kTagged);
    const Register out = locs()->out(0).reg();
    const Register in = in_loc.reg();
    __ mv(out, in);
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
    __ beqz(right, deopt);
  }

  __ SmiUntag(TMP, left);
  __ SmiUntag(TMP2, right);

  // Macro-op fusion: DIV immediately before REM.
  __ div(result_div, TMP, TMP2);
  __ rem(result_mod, TMP, TMP2);

  // Correct MOD result:
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  compiler::Label done, adjust;
  __ bgez(result_mod, &done, compiler::Assembler::kNearJump);
  // Result is negative, adjust it.
  if (RangeUtils::IsNegative(divisor_range())) {
    __ sub(result_mod, result_mod, TMP2);
  } else if (RangeUtils::IsPositive(divisor_range())) {
    __ add(result_mod, result_mod, TMP2);
  } else {
    __ bgez(right, &adjust, compiler::Assembler::kNearJump);
    __ sub(result_mod, result_mod, TMP2);
    __ j(&done, compiler::Assembler::kNearJump);
    __ Bind(&adjust);
    __ add(result_mod, result_mod, TMP2);
  }
  __ Bind(&done);

  if (RangeUtils::Overlaps(divisor_range(), -1, -1)) {
    // Check the corner case of dividing the 'MIN_SMI' with -1, in which
    // case we cannot tag the result.
    __ mv(TMP, result_div);
    __ SmiTag(result_div);
    __ SmiTag(result_mod);
    __ SmiUntag(TMP2, result_div);
    __ bne(TMP, TMP2, deopt);
  } else {
    __ SmiTag(result_div);
    __ SmiTag(result_mod);
  }
}

// Should be kept in sync with integers.cc Multiply64Hash
#if XLEN == 32
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register value_lo,
                                        const Register value_hi,
                                        const Register result) {
  ASSERT(value_lo != TMP);
  ASSERT(value_lo != TMP2);
  ASSERT(value_hi != TMP);
  ASSERT(value_hi != TMP2);
  ASSERT(result != TMP);
  ASSERT(result != TMP2);

  __ LoadImmediate(TMP, 0x2d51);
  // (value_hi:value_lo) * (0:TMP) =
  //   value_lo * TMP + (value_hi * TMP) * 2^32 =
  //   lo32(value_lo * TMP) +
  //     (hi32(value_lo * TMP) + lo32(value_hi * TMP) * 2^32 +
  //     hi32(value_hi * TMP) * 2^64
  __ mulhu(TMP2, value_lo, TMP);
  __ mul(result, value_lo, TMP);  // (TMP2:result) = lo32 * 0x2d51
  __ mulhu(value_lo, value_hi, TMP);
  __ mul(TMP, value_hi, TMP);  // (value_lo:TMP) = hi32 * 0x2d51
  __ add(TMP, TMP, TMP2);
  //  (0:value_lo:TMP:result) is 128-bit product
  __ xor_(result, value_lo, result);
  __ xor_(result, TMP, result);
  __ AndImmediate(result, result, 0x3fffffff);
}

#else
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register value,
                                        const Register result) {
  ASSERT(value != TMP);
  ASSERT(result != TMP);
  __ LoadImmediate(TMP, 0x2d51);
  __ mul(result, TMP, value);
  __ mulhu(TMP, TMP, value);
  __ xor_(result, result, TMP);
  __ srai(TMP, result, 32);
  __ xor_(result, result, TMP);
  __ AndImmediate(result, result, 0x3fffffff);
}

#endif

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 3;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNativeLeafCall);

  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresRegister());
  summary->set_temp(2, Location::RequiresFpuRegister());
#if XLEN == 32
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
#else
  summary->set_out(0, Location::RequiresRegister());
#endif
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const FpuRegister value = locs()->in(0).fpu_reg();
#if XLEN == 32
  const PairLocation* out_pair = locs()->out(0).AsPairLocation();
  const Register result = out_pair->At(0).reg();
  const Register result_hi = out_pair->At(1).reg();
#else
  const Register result = locs()->out(0).reg();
#endif
  const Register temp = locs()->temp(0).reg();
  const Register temp1 = locs()->temp(1).reg();
  const FpuRegister temp_double = locs()->temp(2).fpu_reg();

  compiler::Label hash_double, hash_double_value, hash_integer;
  compiler::Label slow_path, done;
  __ fclassd(temp, value);
  __ TestImmediate(temp, kFClassSignallingNan | kFClassQuietNan |
                             kFClassNegInfinity | kFClassPosInfinity);
  __ BranchIf(NOT_ZERO, &hash_double_value);
#if XLEN == 32
  __ fcvtwd(temp1, value, RTZ);
  __ fcvtdw(temp_double, temp1);
#else
  __ fcvtld(temp1, value, RTZ);
  __ fcvtdl(temp_double, temp1);
#endif
  __ feqd(temp, value, temp_double);
  __ CompareImmediate(temp, 1);
  __ BranchIf(NE, &hash_double_value);
#if XLEN == 32
  // integer hash of (0:temp1)
  __ srai(temp, temp1, XLEN - 1);  // SignFill
  __ Bind(&hash_integer);
  // integer hash of (temp, temp1)
  EmitHashIntegerCodeSequence(compiler, temp1, temp, result);
#else
  // integer hash of temp1
  __ Bind(&hash_integer);
  EmitHashIntegerCodeSequence(compiler, temp1, result);
#endif
  __ j(&done);

  __ Bind(&slow_path);
  // double value is potentially doesn't fit into Smi range, so
  // do the double->int64->double via runtime call.
  __ StoreDToOffset(value, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  {
    compiler::LeafRuntimeScope rt(compiler->assembler(), /*frame_size=*/0,
                                  /*preserve_registers=*/true);
    __ mv(A0, THR);
    // Check if double can be represented as int64, load it into (temp:EAX) if
    // it can.
    rt.Call(kTryDoubleAsIntegerRuntimeEntry, 1);
    __ mv(TMP, A0);
  }
#if XLEN == 32
  __ LoadFromOffset(temp1, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  __ LoadFromOffset(temp, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset() +
                        compiler::target::kWordSize);
#else
  __ fmvxd(temp1, value);
  __ srli(temp, temp1, 32);
#endif
  __ CompareImmediate(TMP, 0);
  __ BranchIf(NE, &hash_integer);
  __ j(&hash_double);

#if XLEN == 32
  __ Bind(&hash_double_value);
  __ StoreDToOffset(value, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  __ LoadFromOffset(temp1, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  __ LoadFromOffset(temp, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset() +
                        compiler::target::kWordSize);
#else
  __ Bind(&hash_double_value);
  __ fmvxd(temp1, value);
  __ srli(temp, temp1, 32);
#endif

  // double hi/lo words are in (temp:temp1)
  __ Bind(&hash_double);
  __ xor_(result, temp1, temp);
  __ AndImmediate(result, result, compiler::target::kSmiMax);

  __ Bind(&done);
#if XLEN == 32
  __ xor_(result_hi, result_hi, result_hi);
#endif
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
#if XLEN == 32
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_temp(0, Location::RequiresRegister());
#else
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
#endif
  summary->set_in(0, Location::WritableRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value = locs()->in(0).reg();

#if XLEN == 32
  Register value_hi = locs()->temp(0).reg();

  if (smi_) {
    __ SmiUntag(value);
    __ srai(value_hi, value, XLEN - 1);  // SignFill
  } else {
    __ LoadFieldFromOffset(value_hi, value,
                           Mint::value_offset() + compiler::target::kWordSize);
    __ LoadFieldFromOffset(value, value, Mint::value_offset());
  }
  EmitHashIntegerCodeSequence(compiler, value, value_hi, result);
#else
  if (smi_) {
    __ SmiUntag(value);
  } else {
    __ LoadFieldFromOffset(value, value, Mint::value_offset());
  }
  EmitHashIntegerCodeSequence(compiler, value, result);
#endif
  __ SmiTag(result);
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
  __ sll(bit_reg, bit_reg, biased_cid);
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
    // For class ID ranges use a subtract followed by an unsigned
    // comparison to check both ends of the ranges with one comparison.
    __ AddImmediate(biased_cid, bias - cid_start);
    bias = cid_start;
    __ CompareImmediate(biased_cid, cid_end - cid_start);
    no_match = HI;  // Unsigned higher.
    match = LS;     // Unsigned lower or same.
  }
  if (is_last) {
    __ BranchIf(no_match, deopt);
  } else {
    __ BranchIf(match, is_ok);
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
    __ BranchIf(NE, deopt);
  } else {
    __ AddImmediate(value, -Smi::RawValue(cids_.cid_start));
    __ CompareImmediate(value, Smi::RawValue(cids_.cid_end - cids_.cid_start));
    __ BranchIf(HI, deopt);  // Unsigned higher.
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

void CheckNullInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ThrowErrorSlowPathCode* slow_path = new NullErrorSlowPath(this);
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
      __ bltz(index, deopt);
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
  __ lbu(TMP, compiler::FieldAddress(locs()->in(0).reg(),
                                     compiler::target::Object::tags_offset()));
  // In the first byte.
  ASSERT(compiler::target::UntaggedObject::kImmutableBit < 8);
  __ andi(TMP, TMP, 1 << compiler::target::UntaggedObject::kImmutableBit);
  __ bnez(TMP, slow_path->entry_label());
}

class Int64DivideSlowPath : public ThrowErrorSlowPathCode {
 public:
  Int64DivideSlowPath(BinaryInt64OpInstr* instruction,
                      Register divisor,
                      Range* divisor_range,
                      Register tmp,
                      Register out)
      : ThrowErrorSlowPathCode(instruction,
                               kIntegerDivisionByZeroExceptionRuntimeEntry),
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
        compiler::Label adjust, done;
        __ bgez(divisor_, &adjust, compiler::Assembler::kNearJump);
        __ sub(out_, out_, divisor_);
        __ j(&done, compiler::Assembler::kNearJump);
        __ Bind(&adjust);
        __ add(out_, out_, divisor_);
        __ Bind(&done);
      } else if (divisor_range_->IsPositive()) {
        // Always positive.
        __ add(out_, out_, divisor_);
      } else {
        // Always negative.
        __ sub(out_, out_, divisor_);
      }
      __ j(exit_label());
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

#if XLEN == 64
static void EmitInt64ModTruncDiv(FlowGraphCompiler* compiler,
                                 BinaryInt64OpInstr* instruction,
                                 Token::Kind op_kind,
                                 Register left,
                                 Register right,
                                 Register tmp,
                                 Register out) {
  ASSERT(op_kind == Token::kMOD || op_kind == Token::kTRUNCDIV);

  // TODO(riscv): Is it worth copying the magic constant optimization from the
  // other architectures?

  // Prepare a slow path.
  Range* right_range = instruction->right()->definition()->range();
  Int64DivideSlowPath* slow_path =
      new (Z) Int64DivideSlowPath(instruction, right, right_range, tmp, out);

  // Handle modulo/division by zero exception on slow path.
  if (slow_path->has_divide_by_zero()) {
    __ beqz(right, slow_path->entry_label());
  }

  // Perform actual operation
  //   out = left % right
  // or
  //   out = left / right.
  if (op_kind == Token::kMOD) {
    __ rem(out, left, right);
    // For the % operator, the rem instruction does not
    // quite do what we want. Adjust for sign on slow path.
    __ bltz(out, slow_path->adjust_sign_label());
  } else {
    __ div(out, left, right);
  }

  if (slow_path->is_needed()) {
    __ Bind(slow_path->exit_label());
    compiler->AddSlowPathCode(slow_path);
  }
}
#endif

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
#if XLEN == 32
  // TODO(riscv): Allow constants for the RHS of bitwise operators if both
  // hi and lo components are IType immediates.
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
#else
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
#endif
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs()->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(!can_overflow());
  ASSERT(!CanDeoptimize());

  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ and_(out_lo, left_lo, right_lo);
      __ and_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kBIT_OR: {
      __ or_(out_lo, left_lo, right_lo);
      __ or_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kBIT_XOR: {
      __ xor_(out_lo, left_lo, right_lo);
      __ xor_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kADD: {
      __ add(out_hi, left_hi, right_hi);
      __ add(out_lo, left_lo, right_lo);
      __ sltu(TMP, out_lo, right_lo);  // Carry
      __ add(out_hi, out_hi, TMP);
      break;
    }
    case Token::kSUB: {
      __ sltu(TMP, left_lo, right_lo);  // Borrow
      __ sub(out_hi, left_hi, right_hi);
      __ sub(out_hi, out_hi, TMP);
      __ sub(out_lo, left_lo, right_lo);
      break;
    }
    case Token::kMUL: {
      // TODO(riscv): Fix ordering for macro-op fusion.
      __ mul(out_lo, right_lo, left_hi);
      __ mulhu(out_hi, right_lo, left_lo);
      __ add(out_lo, out_lo, out_hi);
      __ mul(out_hi, right_hi, left_lo);
      __ add(out_hi, out_hi, out_lo);
      __ mul(out_lo, right_lo, left_lo);
      break;
    }
    default:
      UNREACHABLE();
  }
#else
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
    switch (op_kind()) {
      case Token::kADD:
        __ add(out, left, right.reg());
        break;
      case Token::kSUB:
        __ sub(out, left, right.reg());
        break;
      case Token::kBIT_AND:
        __ and_(out, left, right.reg());
        break;
      case Token::kBIT_OR:
        __ or_(out, left, right.reg());
        break;
      case Token::kBIT_XOR:
        __ xor_(out, left, right.reg());
        break;
      default:
        UNREACHABLE();
    }
  }
#endif
}

#if XLEN == 32
static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out_lo,
                                     Register out_hi,
                                     Register left_lo,
                                     Register left_hi,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);

  switch (op_kind) {
    case Token::kSHR: {
      if (shift < 32) {
        __ slli(out_lo, left_hi, 32 - shift);
        __ srli(TMP, left_lo, shift);
        __ or_(out_lo, out_lo, TMP);
        __ srai(out_hi, left_hi, shift);
      } else {
        if (shift == 32) {
          __ mv(out_lo, left_hi);
        } else if (shift < 64) {
          __ srai(out_lo, left_hi, shift - 32);
        } else {
          __ srai(out_lo, left_hi, 31);
        }
        __ srai(out_hi, left_hi, 31);
      }
      break;
    }
    case Token::kUSHR: {
      ASSERT(shift < 64);
      if (shift < 32) {
        __ slli(out_lo, left_hi, 32 - shift);
        __ srli(TMP, left_lo, shift);
        __ or_(out_lo, out_lo, TMP);
        __ srli(out_hi, left_hi, shift);
      } else {
        if (shift == 32) {
          __ mv(out_lo, left_hi);
        } else {
          __ srli(out_lo, left_hi, shift - 32);
        }
        __ li(out_hi, 0);
      }
      break;
    }
    case Token::kSHL: {
      ASSERT(shift >= 0);
      ASSERT(shift < 64);
      if (shift < 32) {
        __ srli(out_hi, left_lo, 32 - shift);
        __ slli(TMP, left_hi, shift);
        __ or_(out_hi, out_hi, TMP);
        __ slli(out_lo, left_lo, shift);
      } else {
        if (shift == 32) {
          __ mv(out_hi, left_lo);
        } else {
          __ slli(out_hi, left_lo, shift - 32);
        }
        __ li(out_lo, 0);
      }
      break;
    }
    default:
      UNREACHABLE();
  }
}
#else
static void EmitShiftInt64ByConstant(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out,
                                     Register left,
                                     const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  switch (op_kind) {
    case Token::kSHR: {
      __ srai(out, left, Utils::Minimum<int64_t>(shift, XLEN - 1));
      break;
    }
    case Token::kUSHR: {
      ASSERT(shift < 64);
      __ srli(out, left, shift);
      break;
    }
    case Token::kSHL: {
      ASSERT(shift < 64);
      __ slli(out, left, shift);
      break;
    }
    default:
      UNREACHABLE();
  }
}
#endif

#if XLEN == 32
static void EmitShiftInt64ByRegister(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out_lo,
                                     Register out_hi,
                                     Register left_lo,
                                     Register left_hi,
                                     Register right) {
  // TODO(riscv): Review.
  switch (op_kind) {
    case Token::kSHR: {
      compiler::Label big_shift, done;
      __ li(TMP, 32);
      __ bge(right, TMP, &big_shift, compiler::Assembler::kNearJump);

      // 0 <= right < 32
      __ srl(out_lo, left_lo, right);
      __ sra(out_hi, left_hi, right);
      __ beqz(right, &done, compiler::Assembler::kNearJump);
      __ sub(TMP, TMP, right);
      __ sll(TMP2, left_hi, TMP);
      __ or_(out_lo, out_lo, TMP2);
      __ j(&done, compiler::Assembler::kNearJump);

      // 32 <= right < 64
      __ Bind(&big_shift);
      __ sub(TMP, right, TMP);
      __ sra(out_lo, left_hi, TMP);
      __ srai(out_hi, left_hi, XLEN - 1);  // SignFill
      __ Bind(&done);
      break;
    }
    case Token::kUSHR: {
      compiler::Label big_shift, done;
      __ li(TMP, 32);
      __ bge(right, TMP, &big_shift, compiler::Assembler::kNearJump);

      // 0 <= right < 32
      __ srl(out_lo, left_lo, right);
      __ srl(out_hi, left_hi, right);
      __ beqz(right, &done, compiler::Assembler::kNearJump);
      __ sub(TMP, TMP, right);
      __ sll(TMP2, left_hi, TMP);
      __ or_(out_lo, out_lo, TMP2);
      __ j(&done, compiler::Assembler::kNearJump);

      // 32 <= right < 64
      __ Bind(&big_shift);
      __ sub(TMP, right, TMP);
      __ srl(out_lo, left_hi, TMP);
      __ li(out_hi, 0);
      __ Bind(&done);
      break;
    }
    case Token::kSHL: {
      compiler::Label big_shift, done;
      __ li(TMP, 32);
      __ bge(right, TMP, &big_shift, compiler::Assembler::kNearJump);

      // 0 <= right < 32
      __ sll(out_lo, left_lo, right);
      __ sll(out_hi, left_hi, right);
      __ beqz(right, &done, compiler::Assembler::kNearJump);
      __ sub(TMP, TMP, right);
      __ srl(TMP2, left_lo, TMP);
      __ or_(out_hi, out_hi, TMP2);
      __ j(&done, compiler::Assembler::kNearJump);

      // 32 <= right < 64
      __ Bind(&big_shift);
      __ sub(TMP, right, TMP);
      __ sll(out_hi, left_lo, TMP);
      __ li(out_lo, 0);
      __ Bind(&done);
      break;
    }
    default:
      UNREACHABLE();
  }
}
#else
static void EmitShiftInt64ByRegister(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out,
                                     Register left,
                                     Register right) {
  switch (op_kind) {
    case Token::kSHR: {
      __ sra(out, left, right);
      break;
    }
    case Token::kUSHR: {
      __ srl(out, left, right);
      break;
    }
    case Token::kSHL: {
      __ sll(out, left, right);
      break;
    }
    default:
      UNREACHABLE();
  }
}
#endif

static void EmitShiftUint32ByConstant(FlowGraphCompiler* compiler,
                                      Token::Kind op_kind,
                                      Register out,
                                      Register left,
                                      const Object& right) {
  const int64_t shift = Integer::Cast(right).AsInt64Value();
  ASSERT(shift >= 0);
  if (shift >= 32) {
    __ li(out, 0);
  } else {
    switch (op_kind) {
      case Token::kSHR:
      case Token::kUSHR:
#if XLEN == 32
        __ srli(out, left, shift);
#else
        __ srliw(out, left, shift);
#endif
        break;
      case Token::kSHL:
#if XLEN == 32
        __ slli(out, left, shift);
#else
        __ slliw(out, left, shift);
#endif
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
    case Token::kUSHR:
#if XLEN == 32
      __ srl(out, left, right);
#else
      __ srlw(out, left, right);
#endif
      break;
    case Token::kSHL:
#if XLEN == 32
      __ sll(out, left, right);
#else
      __ sllw(out, left, right);
#endif
      break;
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
#if XLEN == 32
    PairLocation* left_pair = instruction()->locs()->in(0).AsPairLocation();
    Register left_hi = left_pair->At(1).reg();
    PairLocation* right_pair = instruction()->locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();
    PairLocation* out_pair = instruction()->locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();

    compiler::Label throw_error;
    __ bltz(right_hi, &throw_error);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ srai(out_hi, left_hi, compiler::target::kBitsPerWord - 1);
        __ mv(out_lo, out_hi);
        break;
      case Token::kUSHR:
      case Token::kSHL: {
        __ li(out_lo, 0);
        __ li(out_hi, 0);
        break;
      }
      default:
        UNREACHABLE();
    }

    __ j(exit_label());

    __ Bind(&throw_error);

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ StoreToOffset(right_lo, THR,
                     compiler::target::Thread::unboxed_runtime_arg_offset());
    __ StoreToOffset(right_hi, THR,
                     compiler::target::Thread::unboxed_runtime_arg_offset() +
                         compiler::target::kWordSize);
#else
    const Register left = instruction()->locs()->in(0).reg();
    const Register right = instruction()->locs()->in(1).reg();
    const Register out = instruction()->locs()->out(0).reg();
    ASSERT((out != left) && (out != right));

    compiler::Label throw_error;
    __ bltz(right, &throw_error);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ srai(out, left, XLEN - 1);
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

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ sx(right,
          compiler::Address(
              THR, compiler::target::Thread::unboxed_runtime_arg_offset()));
#endif
  }
};

LocationSummary* ShiftInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
#if XLEN == 32
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  if (RangeUtils::IsPositive(shift_range()) &&
      right()->definition()->IsConstant()) {
    ConstantInstr* constant = right()->definition()->AsConstant();
    summary->set_in(1, Location::Constant(constant));
  } else {
    summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
  }
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
#else
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, RangeUtils::IsPositive(shift_range())
                         ? LocationRegisterOrConstant(right())
                         : Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
#endif
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    PairLocation* right_pair = locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();

    // Jump to a slow path if shift is larger than 63 or less than 0.
    ShiftInt64OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange()) {
      slow_path = new (Z) ShiftInt64OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);
      __ CompareImmediate(right_hi, 0);
      __ BranchIf(NE, slow_path->entry_label());
      __ CompareImmediate(right_lo, kShiftCountLimit);
      __ BranchIf(HI, slow_path->entry_label());
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, right_lo);

    if (slow_path != nullptr) {
      __ Bind(slow_path->exit_label());
    }
  }
#else
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
#endif
}

LocationSummary* SpeculativeShiftInt64OpInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
#if XLEN == 32
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, LocationWritableRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
#else
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
#endif
  return summary;
}

void SpeculativeShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(!can_overflow());

  if (locs()->in(1).IsConstant()) {
    EmitShiftInt64ByConstant(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, locs()->in(1).constant());
  } else {
    // Code for a variable shift amount.
    Register shift = locs()->in(1).reg();
    __ SmiUntag(shift);

    // Deopt if shift is larger than 63 or less than 0 (or not a smi).
    if (!IsShiftCountInRange()) {
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

      __ CompareImmediate(shift, kShiftCountLimit);
      __ BranchIf(HI, deopt);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, shift);
  }
#else
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
      __ BranchIf(HI, deopt);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out, left, shift);
  }
#endif
}

class ShiftUint32OpSlowPath : public ThrowErrorSlowPathCode {
 public:
  explicit ShiftUint32OpSlowPath(ShiftUint32OpInstr* instruction)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry) {}

  const char* name() override { return "uint32 shift"; }

  void EmitCodeAtSlowPathEntry(FlowGraphCompiler* compiler) override {
#if XLEN == 32
    PairLocation* right_pair = instruction()->locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();
    Register out = instruction()->locs()->out(0).reg();

    compiler::Label throw_error;
    __ bltz(right_hi, &throw_error, compiler::Assembler::kNearJump);
    __ li(out, 0);
    __ j(exit_label());

    __ Bind(&throw_error);
    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ StoreToOffset(right_lo, THR,
                     compiler::target::Thread::unboxed_runtime_arg_offset());
    __ StoreToOffset(right_hi, THR,
                     compiler::target::Thread::unboxed_runtime_arg_offset() +
                         compiler::target::kWordSize);
#else
    const Register right = instruction()->locs()->in(1).reg();

    // Can't pass unboxed int64 value directly to runtime call, as all
    // arguments are expected to be tagged (boxed).
    // The unboxed int64 argument is passed through a dedicated slot in Thread.
    // TODO(dartbug.com/33549): Clean this up when unboxed values
    // could be passed as arguments.
    __ sx(right,
          compiler::Address(
              THR, compiler::target::Thread::unboxed_runtime_arg_offset()));
#endif
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
#if XLEN == 32
    summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
#else
    summary->set_in(1, Location::RequiresRegister());
#endif
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();

  ASSERT(left != out);

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
  } else {
    // Code for a variable shift amount (or constant that throws).
    PairLocation* right_pair = locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();

    // Jump to a slow path if shift count is > 31 or negative.
    ShiftUint32OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      slow_path = new (Z) ShiftUint32OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ CompareImmediate(right_hi, 0);
      __ BranchIf(NE, slow_path->entry_label());
      __ CompareImmediate(right_lo, kUint32ShiftCountLimit);
      __ BranchIf(HI, slow_path->entry_label());
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right_lo);

    if (slow_path != nullptr) {
      __ Bind(slow_path->exit_label());
    }
  }
#else
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
      ShiftUint32OpSlowPath* slow_path = new (Z) ShiftUint32OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ bltz(right, slow_path->entry_label());
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!shift_count_in_range) {
      // If shift value is > 31, return zero.
      compiler::Label done;
      __ CompareImmediate(right, 31);
      __ BranchIf(LE, &done, compiler::Assembler::kNearJump);
      __ li(out, 0);
      __ Bind(&done);
    }
  }
#endif
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

      __ bltz(right, deopt);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!shift_count_in_range) {
      // If shift value is > 31, return zero.
      compiler::Label done;
      __ CompareImmediate(right, 31);
      __ BranchIf(LE, &done, compiler::Assembler::kNearJump);
      __ li(out, 0);
      __ Bind(&done);
    }
  }
}

LocationSummary* UnaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
#if XLEN == 32
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
#else
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
#endif
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ not_(out_lo, left_lo);
      __ not_(out_hi, left_hi);
      break;
    case Token::kNEGATE:
      __ snez(TMP, left_lo);  // Borrow
      __ neg(out_lo, left_lo);
      __ neg(out_hi, left_hi);
      __ sub(out_hi, out_hi, TMP);
      break;
    default:
      UNREACHABLE();
  }
#else
  const Register left = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ not_(out, left);
      break;
    case Token::kNEGATE:
      __ neg(out, left);
      break;
    default:
      UNREACHABLE();
  }
#endif
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
  Register out = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ and_(out, left, right);
      break;
    case Token::kBIT_OR:
      __ or_(out, left, right);
      break;
    case Token::kBIT_XOR:
      __ xor_(out, left, right);
      break;
    case Token::kADD:
#if XLEN == 32
      __ add(out, left, right);
#elif XLEN > 32
      __ addw(out, left, right);
#endif
      break;
    case Token::kSUB:
#if XLEN == 32
      __ sub(out, left, right);
#elif XLEN > 32
      __ subw(out, left, right);
#endif
      break;
    case Token::kMUL:
      __ mul(out, left, right);
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
  __ not_(out, left);
}

#if XLEN == 32
static void EmitInt32ShiftLeft(FlowGraphCompiler* compiler,
                               BinaryInt32OpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  const Register left = locs.in(0).reg();
  const Register result = locs.out(0).reg();
  compiler::Label* deopt =
      shift_left->CanDeoptimize()
          ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                   ICData::kDeoptBinarySmiOp)
          : nullptr;
  ASSERT(locs.in(1).IsConstant());
  const Object& constant = locs.in(1).constant();
  ASSERT(compiler::target::IsSmi(constant));
  // Immediate shift operation takes 5 bits for the count.
  const intptr_t kCountLimit = 0x1F;
  const intptr_t value = compiler::target::SmiValue(constant);
  ASSERT((0 < value) && (value < kCountLimit));
  __ slli(result, left, value);
  if (shift_left->can_overflow()) {
    __ srai(TMP, result, value);
    __ bne(TMP, left, deopt);  // Overflow.
  }
}

LocationSummary* BinaryInt32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  // Calculate number of temporaries.
  intptr_t num_temps = 0;
  if (((op_kind() == Token::kSHL) && can_overflow()) ||
      (op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR) ||
      (op_kind() == Token::kMUL)) {
    num_temps = 1;
  }
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  if (num_temps == 1) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BinaryInt32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitInt32ShiftLeft(compiler, this);
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
    ASSERT(compiler::target::IsSmi(constant));
    const intptr_t value = compiler::target::SmiValue(constant);
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, value);
        } else {
          __ AddImmediateBranchOverflow(result, left, value, deopt);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, -value);
        } else {
          // Negating value and using AddImmediateSetFlags would not detect the
          // overflow when value == kMinInt32.
          __ SubtractImmediateBranchOverflow(result, left, value, deopt);
        }
        break;
      }
      case Token::kMUL: {
        const Register right = locs()->temp(0).reg();
        __ LoadImmediate(right, value);
        if (deopt == nullptr) {
          __ mul(result, left, right);
        } else {
          __ MultiplyBranchOverflow(result, left, right, deopt);
        }
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ AndImmediate(result, left, value);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ OrImmediate(result, left, value);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ XorImmediate(result, left, value);
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ srai(result, left, Utils::Minimum(value, kCountLimit));
        break;
      }
      case Token::kUSHR: {
        UNIMPLEMENTED();
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
      if (deopt == nullptr) {
        __ add(result, left, right);
      } else {
        __ AddBranchOverflow(result, left, right, deopt);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == nullptr) {
        __ sub(result, left, right);
      } else {
        __ SubtractBranchOverflow(result, left, right, deopt);
      }
      break;
    }
    case Token::kMUL: {
      if (deopt == nullptr) {
        __ mul(result, left, right);
      } else {
        __ MultiplyBranchOverflow(result, left, right, deopt);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ or_(result, left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xor_(result, left, right);
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}
#else
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)
#endif

LocationSummary* IntConverterInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
#if XLEN == 32
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
  } else if (from() == kUnboxedInt64) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else if (to() == kUnboxedInt64) {
    ASSERT(from() == kUnboxedUint32 || from() == kUnboxedInt32);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    ASSERT(from() == kUnboxedUint32 || from() == kUnboxedInt32);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  }
  return summary;
#else
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
#endif
}

void IntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if XLEN == 32
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
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ bltz(out, deopt);
    }
  } else if (from() == kUnboxedInt64) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ mv(out, in_lo);
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      ASSERT(to() == kUnboxedInt32);
      __ srai(TMP, in_lo, XLEN - 1);
      __ bne(in_hi, TMP, deopt);
    }
  } else if (from() == kUnboxedUint32 || from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedInt64);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ mv(out_lo, in);
    if (from() == kUnboxedUint32) {
      __ li(out_hi, 0);
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ srai(out_hi, in, XLEN - 1);
    }
  } else {
    UNREACHABLE();
  }
#else
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
          ? nullptr
          : compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    if (CanDeoptimize()) {
      __ slli(TMP, value, 32);
      __ bltz(TMP, deopt);  // If sign bit is set it won't fit in a uint32.
    }
    if (out != value) {
      __ mv(out, value);  // For positive values the bits are the same.
    }
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    if (CanDeoptimize()) {
      __ slli(TMP, value, 32);
      __ bltz(TMP, deopt);  // If high bit is set it won't fit in an int32.
    }
    if (out != value) {
      __ mv(out, value);  // For 31 bit values the bits are the same.
    }
  } else if (from() == kUnboxedInt64) {
    if (to() == kUnboxedInt32) {
      if (is_truncating() || out != value) {
        __ sextw(out, value);  // Signed extension 64->32.
      }
    } else {
      ASSERT(to() == kUnboxedUint32);
      if (is_truncating() || out != value) {
        // Unsigned extension 64->32.
        // TODO(riscv): Might be a shorter way to do this.
        __ slli(out, value, 32);
        __ srli(out, out, 32);
      }
    }
    if (CanDeoptimize()) {
      ASSERT(to() == kUnboxedInt32);
      __ CompareRegisters(out, value);
      __ BranchIf(NE, deopt);  // Value cannot be held in Int32, deopt.
    }
  } else if (to() == kUnboxedInt64) {
    if (from() == kUnboxedUint32) {
      // TODO(riscv): Might be a shorter way to do this.
      __ slli(out, value, 32);
      __ srli(out, out, 32);
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ sextw(out, value);  // Signed extension 32->64.
    }
  } else {
    UNREACHABLE();
  }
#endif
}

LocationSummary* BitCastInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, /*num_inputs=*/InputCount(),
                                 /*num_temps=*/0, LocationSummary::kNoCall);
  switch (from()) {
    case kUnboxedInt32:
      summary->set_in(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
#if XLEN == 32
      summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
#else
      summary->set_in(0, Location::RequiresRegister());
#endif
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
      summary->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
#if XLEN == 32
      summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                         Location::RequiresRegister()));
#else
      summary->set_out(0, Location::RequiresRegister());
#endif
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
        case kUnboxedInt32: {
          const FpuRegister src = locs()->in(0).fpu_reg();
          const Register dst = locs()->out(0).reg();
          __ fmvxw(dst, src);
          break;
        }
        case kUnboxedInt64: {
          const FpuRegister src = locs()->in(0).fpu_reg();
#if XLEN == 32
          const Register dst0 = locs()->out(0).AsPairLocation()->At(0).reg();
          const Register dst1 = locs()->out(0).AsPairLocation()->At(1).reg();
          __ fmvxw(dst0, src);
          __ li(dst1, 0);
#else
          const Register dst = locs()->out(0).reg();
          __ fmvxw(dst, src);
#endif
          break;
        }
        default:
          UNREACHABLE();
      }
      break;
    }
    case kUnboxedDouble: {
      ASSERT(to() == kUnboxedInt64);
      const FpuRegister src = locs()->in(0).fpu_reg();
#if XLEN == 32
      const Register dst0 = locs()->out(0).AsPairLocation()->At(0).reg();
      const Register dst1 = locs()->out(0).AsPairLocation()->At(1).reg();
      __ subi(SP, SP, 16);
      __ fsd(src, compiler::Address(SP, 0));
      __ lw(dst0, compiler::Address(SP, 0));
      __ lw(dst1, compiler::Address(SP, 4));
      __ addi(SP, SP, 16);
#else
      const Register dst = locs()->out(0).reg();
      __ fmvxd(dst, src);
#endif
      break;
    }
    case kUnboxedInt64: {
      switch (to()) {
        case kUnboxedDouble: {
          const FpuRegister dst = locs()->out(0).fpu_reg();
#if XLEN == 32
          const Register src0 = locs()->in(0).AsPairLocation()->At(0).reg();
          const Register src1 = locs()->in(0).AsPairLocation()->At(1).reg();
          __ subi(SP, SP, 16);
          __ sw(src0, compiler::Address(SP, 0));
          __ sw(src1, compiler::Address(SP, 4));
          __ fld(dst, compiler::Address(SP, 0));
          __ addi(SP, SP, 16);
#else
          const Register src = locs()->in(0).reg();
          __ fmvdx(dst, src);
#endif
          break;
        }
        case kUnboxedFloat: {
          const FpuRegister dst = locs()->out(0).fpu_reg();
#if XLEN == 32
          const Register src0 = locs()->in(0).AsPairLocation()->At(0).reg();
          __ fmvwx(dst, src0);
#else
          const Register src = locs()->in(0).reg();
          __ fmvwx(dst, src);
#endif
          break;
        }
        default:
          UNREACHABLE();
      }
      break;
    }
    case kUnboxedInt32: {
      ASSERT(to() == kUnboxedFloat);
      const Register src = locs()->in(0).reg();
      const FpuRegister dst = locs()->out(0).fpu_reg();
      __ fmvwx(dst, src);
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
  Register index_reg = locs()->in(0).reg();
  Register target_address_reg = locs()->temp(0).reg();
  Register offset_reg = locs()->temp(1).reg();

  ASSERT(RequiredInputRepresentation(0) == kTagged);
  __ LoadObject(offset_reg, offsets_);
  const auto element_address = __ ElementAddressForRegIndex(
      /*is_external=*/false, kTypedDataInt32ArrayCid,
      /*index_scale=*/4,
      /*index_unboxed=*/false, offset_reg, index_reg, TMP);
  __ lw(offset_reg, element_address);

  const intptr_t entry_offset = __ CodeSize();
  intx_t imm = -entry_offset;
  intx_t lo = ImmLo(imm);
  intx_t hi = ImmHi(imm);
  __ auipc(target_address_reg, hi);
  __ add(target_address_reg, target_address_reg, offset_reg);
  __ jr(target_address_reg, lo);
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

void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);

  Register result = locs()->out(0).reg();
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
    // If EmitComparisonCode did not use the labels and just returned
    // a condition we can avoid the branch and use slt to generate the
    // offsets to true or false.
    ASSERT(kTrueOffsetFromNull + (1 << kBoolValueBitPosition) ==
           kFalseOffsetFromNull);
    ASSERT(((kTrueOffsetFromNull >> kBoolValueBitPosition)
            << kBoolValueBitPosition) == kTrueOffsetFromNull);
    __ SetIf(InvertCondition(true_condition), result);
    __ addi(result, result, kTrueOffsetFromNull >> kBoolValueBitPosition);
    __ slli(result, result, kBoolValueBitPosition);
    __ add(result, result, NULL_REG);
  }
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
  __ xori(result, input, compiler::target::ObjectAlignment::kBoolValueMask);
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
  __ JumpAndLinkPatchable(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
