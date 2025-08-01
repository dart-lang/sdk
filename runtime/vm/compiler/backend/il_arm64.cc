// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

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
    case kUntagged:
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
#if !defined(DART_COMPRESSED_POINTERS)
      __ add(out, base_reg(), compiler::Operand(index, LSL, 2));
#else
      __ add(out, base_reg(), compiler::Operand(index, SXTW, 2));
#endif
      __ LoadFromOffset(out, out, offset());
      break;
    }
    case kUnboxedDouble: {
      const auto tmp = locs()->temp(0).reg();
      const auto out = locs()->out(0).fpu_reg();
#if !defined(DART_COMPRESSED_POINTERS)
      __ add(tmp, base_reg(), compiler::Operand(index, LSL, 2));
#else
      __ add(tmp, base_reg(), compiler::Operand(index, SXTW, 2));
#endif
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
#if !defined(DART_COMPRESSED_POINTERS)
  __ add(TMP, instr->base_reg(), compiler::Operand(index, LSL, 2));
#else
  __ add(TMP, instr->base_reg(), compiler::Operand(index, SXTW, 2));
#endif
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
  // The compiler must optimize any function that includes a MemoryCopy
  // instruction that uses typed data cids, since extracting the payload address
  // from views is done in a compiler pass after all code motion has happened.
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

static void CopyUpToMultipleOfChunkSize(FlowGraphCompiler* compiler,
                                        Register dest_reg,
                                        Register src_reg,
                                        Register length_reg,
                                        intptr_t element_size,
                                        bool unboxed_inputs,
                                        bool reversed,
                                        intptr_t chunk_size,
                                        compiler::Label* done) {
  ASSERT(Utils::IsPowerOfTwo(element_size));
  if (element_size >= chunk_size) return;

  const intptr_t element_shift = Utils::ShiftForPowerOfTwo(element_size);
  const intptr_t base_shift =
      (unboxed_inputs ? 0 : kSmiTagShift) - element_shift;
  const intptr_t offset_sign = reversed ? -1 : 1;
  auto const mode =
      reversed ? compiler::Address::PreIndex : compiler::Address::PostIndex;
  intptr_t tested_bits = 0;

  __ Comment("Copying until region size is a multiple of chunk size");

  for (intptr_t bit = Utils::ShiftForPowerOfTwo(chunk_size) - 1;
       bit >= element_shift; bit--) {
    const intptr_t bytes = 1 << bit;
    const intptr_t tested_bit = bit + base_shift;
    tested_bits |= (1 << tested_bit);
    const intptr_t offset = offset_sign * bytes;
    compiler::Label skip_copy;
    __ tbz(&skip_copy, length_reg, tested_bit);
    auto const sz = OperandSizeFor(bytes);
    __ ldr(TMP, compiler::Address(src_reg, offset, mode), sz);
    __ str(TMP, compiler::Address(dest_reg, offset, mode), sz);
    __ Bind(&skip_copy);
  }

  ASSERT(tested_bits != 0);
  __ andis(length_reg, length_reg, compiler::Immediate(~tested_bits),
           compiler::kObjectBytes);
  __ b(done, ZERO);
}

void MemoryCopyInstr::EmitLoopCopy(FlowGraphCompiler* compiler,
                                   Register dest_reg,
                                   Register src_reg,
                                   Register length_reg,
                                   compiler::Label* done,
                                   compiler::Label* copy_forwards) {
  const bool reversed = copy_forwards != nullptr;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                         (unboxed_inputs() ? 0 : kSmiTagShift);
  if (FLAG_target_memory_sanitizer) {
    __ Push(length_reg);
    if (!unboxed_inputs()) {
      __ ExtendNonNegativeSmi(length_reg);
    }
    if (shift < 0) {
      __ AsrImmediate(length_reg, length_reg, -shift);
    } else {
      __ LslImmediate(length_reg, length_reg, shift);
    }
    __ MsanUnpoison(dest_reg, length_reg);
    __ Pop(length_reg);
  }
  if (reversed) {
    // Verify that the overlap actually exists by checking to see if
    // dest_start < src_end.
    if (!unboxed_inputs()) {
      __ ExtendNonNegativeSmi(length_reg);
    }
    if (shift < 0) {
      __ add(TMP, src_reg, compiler::Operand(length_reg, ASR, -shift));
    } else {
      __ add(TMP, src_reg, compiler::Operand(length_reg, LSL, shift));
    }
    __ CompareRegisters(dest_reg, TMP);
    __ BranchIf(UNSIGNED_GREATER_EQUAL, copy_forwards);
    // There is overlap, so move TMP to src_reg and adjust dest_reg now.
    __ MoveRegister(src_reg, TMP);
    if (shift < 0) {
      __ add(dest_reg, dest_reg, compiler::Operand(length_reg, ASR, -shift));
    } else {
      __ add(dest_reg, dest_reg, compiler::Operand(length_reg, LSL, shift));
    }
  }
  const intptr_t kChunkSize = 16;
  ASSERT(kChunkSize >= element_size_);
  CopyUpToMultipleOfChunkSize(compiler, dest_reg, src_reg, length_reg,
                              element_size_, unboxed_inputs_, reversed,
                              kChunkSize, done);
  // The size of the uncopied region is now a multiple of the chunk size.
  const intptr_t loop_subtract = (kChunkSize / element_size_)
                                 << (unboxed_inputs_ ? 0 : kSmiTagShift);
  // When reversed, the src and dest registers are adjusted to start with the
  // end addresses, so apply the negated offset prior to indexing.
  const intptr_t offset = (reversed ? -1 : 1) * kChunkSize;
  const auto mode = reversed ? compiler::Address::PairPreIndex
                             : compiler::Address::PairPostIndex;
  __ Comment("Copying chunks at a time");
  compiler::Label loop;
  __ Bind(&loop);
  __ ldp(TMP, TMP2, compiler::Address(src_reg, offset, mode));
  __ stp(TMP, TMP2, compiler::Address(dest_reg, offset, mode));
  __ subs(length_reg, length_reg, compiler::Operand(loop_subtract),
          compiler::kObjectBytes);
  __ b(&loop, NOT_ZERO);
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Register payload_reg,
                                              Representation array_rep,
                                              Location start_loc) {
  intptr_t offset = 0;
  if (array_rep != kTagged) {
    // Do nothing, array_reg already contains the payload address.
  } else if (IsTypedDataBaseClassId(array_cid)) {
    // The incoming array must have been proven to be an internal typed data
    // object, where the payload is in the object and we can just offset.
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
    const intptr_t add_value = Utils::AddWithWrapAround(
        Utils::MulWithWrapAround<intptr_t>(start_value, element_size_), offset);
    __ AddImmediate(payload_reg, array_reg, add_value);
    return;
  }
  const Register start_reg = start_loc.reg();
  intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                   (unboxed_inputs() ? 0 : kSmiTagShift);
  if (shift < 0) {
    if (!unboxed_inputs()) {
      __ ExtendNonNegativeSmi(start_reg);
    }
    __ add(payload_reg, array_reg, compiler::Operand(start_reg, ASR, -shift));
#if defined(DART_COMPRESSED_POINTERS)
  } else if (!unboxed_inputs()) {
    __ add(payload_reg, array_reg, compiler::Operand(start_reg, SXTW, shift));
#endif
  } else {
    __ add(payload_reg, array_reg, compiler::Operand(start_reg, LSL, shift));
  }
  __ AddImmediate(payload_reg, offset);
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
    locs->set_in(0, Location::RequiresRegister());
  } else {
    ASSERT(representation() == kTagged);
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

// Buffers registers in order to use STP to move
// two registers at once.
class ArgumentsMover : public ValueObject {
 public:
  // Flush all buffered registers.
  void Flush(FlowGraphCompiler* compiler) {
    if (pending_register_ != kNoRegister) {
      __ StoreToOffset(pending_register_, SP,
                       pending_sp_relative_index_ * kWordSize);
      pending_sp_relative_index_ = -1;
      pending_register_ = kNoRegister;
    }
  }

  // Buffer given register. May push buffered registers if needed.
  void MoveRegister(FlowGraphCompiler* compiler,
                    intptr_t sp_relative_index,
                    Register reg) {
    if (pending_register_ != kNoRegister) {
      ASSERT((sp_relative_index + 1) == pending_sp_relative_index_);
      __ StorePairToOffset(reg, pending_register_, SP,
                           sp_relative_index * kWordSize);
      pending_register_ = kNoRegister;
      return;
    }
    pending_register_ = reg;
    pending_sp_relative_index_ = sp_relative_index;
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
  intptr_t pending_sp_relative_index_ = -1;
  Register pending_register_ = kNoRegister;
};

void MoveArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());

  if (previous()->IsMoveArgument()) {
    // Already generated by the first MoveArgument in the chain.
    return;
  }

  ArgumentsMover pusher;
  for (MoveArgumentInstr* move_arg = this; move_arg != nullptr;
       move_arg = move_arg->next()->AsMoveArgument()) {
    const Location value = move_arg->locs()->in(0);
    Register reg = kNoRegister;
    if (value.IsRegister()) {
      reg = value.reg();
    } else if (value.IsConstant()) {
      if (value.constant_instruction()->HasZeroRepresentation()) {
        reg = ZR;
      } else {
        ASSERT(move_arg->representation() == kTagged);
        const Object& constant = value.constant();
        if (constant.IsNull()) {
          reg = NULL_REG;
        } else {
          reg = pusher.GetFreeTempRegister(compiler);
          __ LoadObject(reg, value.constant());
        }
      }
    } else if (value.IsFpuRegister()) {
      pusher.Flush(compiler);
      __ StoreDToOffset(value.fpu_reg(), SP,
                        move_arg->location().stack_index() * kWordSize);
      continue;
    } else {
      ASSERT(value.IsStackSlot());
      const intptr_t value_offset = value.ToStackSlotOffset();
      reg = pusher.GetFreeTempRegister(compiler);
      __ LoadFromOffset(reg, value.base_reg(), value_offset);
    }
    pusher.MoveRegister(compiler, move_arg->location().stack_index(), reg);
  }
  pusher.Flush(compiler);
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

// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void DartReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
  __ LeaveDartFrame();  // Disallows constant pool use.
  __ ret();
  // This DartReturnInstr may be emitted out of order by the optimizer. The next
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
  condition()->InitializeLocationSummary(zone, opt);
  return condition()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  // Emit comparison code. This must not overwrite the result register.
  // IfThenElseInstr::Supports() should prevent EmitConditionCode from using
  // the labels or returning an invalid condition.
  BranchLabels labels = {nullptr, nullptr, nullptr};
  Condition true_condition = condition()->EmitConditionCode(compiler, labels);
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

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(
      0, Location::RegisterLocation(FLAG_precompiled_mode ? R0 : FUNCTION_REG));
  return MakeCallSummary(zone, this, summary);
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor in ARGS_DESC_REG.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(ARGS_DESC_REG, arguments_descriptor);

  if (FLAG_precompiled_mode) {
    ASSERT(locs()->in(0).reg() == R0);
    // R0: Closure with a cached entry point.
    __ LoadFieldFromOffset(R2, R0,
                           compiler::target::Closure::entry_point_offset());
#if defined(DART_DYNAMIC_MODULES)
    ASSERT(FUNCTION_REG != R2);
    __ LoadCompressedFieldFromOffset(
        FUNCTION_REG, R0, compiler::target::Closure::function_offset());
#endif
  } else {
    ASSERT(locs()->in(0).reg() == FUNCTION_REG);
    // FUNCTION_REG: Function.
    __ LoadCompressedFieldFromOffset(CODE_REG, FUNCTION_REG,
                                     compiler::target::Function::code_offset());
    // Closure functions only have one entry point.
    __ LoadFieldFromOffset(R2, FUNCTION_REG,
                           compiler::target::Function::entry_point_offset());
  }

  // ARGS_DESC_REG: Arguments descriptor array.
  // R2: instructions entry point.
  if (!FLAG_precompiled_mode) {
    // R5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ LoadImmediate(IC_DATA_REG, 0);
  }
  __ blr(R2);
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
                                       Register tmp,
                                       intptr_t pair_index) {
  ASSERT(pair_index == 0);  // No pair representation needed on 64-bit.
  if (destination.IsRegister()) {
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      const int64_t value = Integer::Cast(value_).Value();
      __ LoadImmediate(destination.reg(), value);
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    switch (representation()) {
      case kUnboxedFloat:
        __ LoadSImmediate(destination.fpu_reg(), Double::Cast(value_).value());
        break;
      case kUnboxedDouble:
        __ LoadDImmediate(destination.fpu_reg(), Double::Cast(value_).value());
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
    ASSERT(representation() == kUnboxedDouble);
    __ LoadDImmediate(VTMP, Double::Cast(value_).value());
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    __ StoreDToOffset(VTMP, destination.base_reg(), dest_offset);
  } else if (destination.IsQuadStackSlot()) {
    switch (representation()) {
      case kUnboxedFloat64x2:
        __ LoadQImmediate(VTMP, Float64x2::Cast(value_).value());
        break;
      case kUnboxedFloat32x4:
        __ LoadQImmediate(VTMP, Float32x4::Cast(value_).value());
        break;
      case kUnboxedInt32x4:
        __ LoadQImmediate(VTMP, Int32x4::Cast(value_).value());
        break;
      default:
        UNREACHABLE();
    }
  } else {
    ASSERT(destination.IsStackSlot());
    ASSERT(tmp != kNoRegister);
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    compiler::OperandSize operand_size = compiler::kWordBytes;
    if (representation() == kUnboxedInt32 ||
        representation() == kUnboxedUint32 ||
        representation() == kUnboxedInt64) {
      const int64_t value = Integer::Cast(value_).Value();
      if (value == 0) {
        tmp = ZR;
      } else {
        __ LoadImmediate(tmp, value);
      }
    } else if (representation() == kUnboxedFloat) {
      int32_t float_bits =
          bit_cast<int32_t, float>(Double::Cast(value_).value());
      __ LoadImmediate(tmp, float_bits);
      operand_size = compiler::kFourBytes;
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
    __ StoreToOffset(tmp, destination.base_reg(), dest_offset, operand_size);
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
  return !AreLabelsNull(labels) && __ CanGenerateCbzTbz(rn, cond);
}

static void EmitCbzTbz(Register reg,
                       FlowGraphCompiler* compiler,
                       Condition true_condition,
                       BranchLabels labels,
                       compiler::OperandSize sz) {
  ASSERT(CanUseCbzTbzForComparison(compiler, reg, true_condition, labels));
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor we will fall through to it.
    __ GenerateCbzTbz(reg, true_condition, labels.true_label, sz);
  } else {
    // If the next block is not the false successor we will branch to it.
    Condition false_condition = InvertCondition(true_condition);
    __ GenerateCbzTbz(reg, false_condition, labels.false_label, sz);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
}

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     const LocationSummary& locs,
                                     Token::Kind kind,
                                     BranchLabels labels) {
  Location left = locs.in(0);
  Location right = locs.in(1);

  Condition true_condition =
      TokenKindToIntCondition(kind, /*is_unsigned=*/false);
  if (right.IsConstant()) {
    int64_t value;
    if (compiler::HasIntegerValue(right.constant(), &value) && (value == 0) &&
        CanUseCbzTbzForComparison(compiler, left.reg(), true_condition,
                                  labels)) {
      EmitCbzTbz(left.reg(), compiler, true_condition, labels,
                 compiler::kObjectBytes);
      return kInvalidCondition;
    }
    __ CompareObject(left.reg(), right.constant());
  } else {
    __ CompareObjectRegisters(left.reg(), right.reg());
  }
  return true_condition;
}

// Similar to ConditionInstr::EmitConditionCode, may either:
//   - emit comparison code and return a valid condition in which case the
//     caller is expected to emit a branch to the true label based on that
//     condition (or a branch to the false label on the opposite condition).
//   - emit comparison code with a branch directly to the labels and return
//     kInvalidCondition.
static Condition EmitUnboxedIntComparisonOp(FlowGraphCompiler* compiler,
                                            const LocationSummary& locs,
                                            Token::Kind kind,
                                            Representation rep,
                                            BranchLabels labels) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT((rep == kUnboxedInt64) || (rep == kUnboxedInt32) ||
         (rep == kUnboxedUint32));
  const compiler::OperandSize size =
      (rep == kUnboxedInt64) ? compiler::kEightBytes : compiler::kFourBytes;

  Condition true_condition = TokenKindToIntCondition(
      kind, RepresentationUtils::IsUnsignedInteger(rep));
  if (right.IsConstant()) {
    int64_t value;
    const bool ok = compiler::HasIntegerValue(right.constant(), &value);
    RELEASE_ASSERT(ok);
    if (value == 0 && CanUseCbzTbzForComparison(compiler, left.reg(),
                                                true_condition, labels)) {
      EmitCbzTbz(left.reg(), compiler, true_condition, labels, size);
      return kInvalidCondition;
    }
    __ CompareImmediate(left.reg(), value, size);
  } else {
    ASSERT(left.reg() != CSP);
    __ cmp(left.reg(), compiler::Operand(right.reg()), size);
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
  const Condition true_condition =
      TokenKindToIntCondition(kind, /*is_unsigned=*/false);
  compiler::Label* equal_result =
      (true_condition == EQ) ? labels.true_label : labels.false_label;
  compiler::Label* not_equal_result =
      (true_condition == EQ) ? labels.false_label : labels.true_label;

  // Check if operands have the same value. If they don't, then they could
  // be equal only if both of them are Mints with the same value.
  __ CompareObjectRegisters(left, right);
  __ b(equal_result, EQ);
  __ and_(TMP, left, compiler::Operand(right), compiler::kObjectBytes);
  __ BranchIfSmi(TMP, not_equal_result);
  __ CompareClassId(left, kMintCid);
  __ b(not_equal_result, NE);
  __ CompareClassId(right, kMintCid);
  __ b(not_equal_result, NE);
  __ LoadFieldFromOffset(TMP, left, Mint::value_offset());
  __ LoadFieldFromOffset(TMP2, right, Mint::value_offset());
  __ CompareRegisters(TMP, TMP2);
  return true_condition;
}

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
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, LocationRegisterOrConstant(right()));
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  const VRegister left = locs.in(0).fpu_reg();
  const VRegister right = locs.in(1).fpu_reg();

  switch (kind) {
    case Token::kEQ:
      __ fcmpd(left, right);
      return EQ;
    case Token::kNE:
      __ fcmpd(left, right);
      return NE;
    case Token::kLT:
      __ fcmpd(right, left);  // Flip to handle NaN.
      return GT;
    case Token::kGT:
      __ fcmpd(left, right);
      return GT;
    case Token::kLTE:
      __ fcmpd(right, left);  // Flip to handle NaN.
      return GE;
    case Token::kGTE:
      __ fcmpd(left, right);
      return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}

Condition EqualityCompareInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                                  BranchLabels labels) {
  if (is_null_aware()) {
    return EmitNullAwareInt64ComparisonOp(compiler, *locs(), kind(), labels);
  }
  switch (input_representation()) {
    case kTagged:
      return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
    case kUnboxedInt64:
    case kUnboxedInt32:
    case kUnboxedUint32:
      return EmitUnboxedIntComparisonOp(compiler, *locs(), kind(),
                                        input_representation(), labels);
    case kUnboxedDouble:
      return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
    default:
      UNREACHABLE();
  }
}

LocationSummary* TestIntInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  locs->set_in(1, LocationRegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition TestIntInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                          BranchLabels labels) {
  const Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  const auto operand_size = representation_ == kTagged ? compiler::kObjectBytes
                                                       : compiler::kEightBytes;
  if (right.IsConstant()) {
    __ TestImmediate(left, ComputeImmediateMask(), operand_size);
  } else {
    __ tst(left, compiler::Operand(right.reg()), operand_size);
  }
  Condition true_condition = (kind() == Token::kNE) ? NE : EQ;
  return true_condition;
}

static bool IsSingleBitMask(Location mask, intptr_t* bit) {
  if (!mask.IsConstant()) {
    return false;
  }

  uint64_t mask_value =
      static_cast<uint64_t>(Integer::Cast(mask.constant()).Value());
  if (!Utils::IsPowerOfTwo(mask_value)) {
    return false;
  }

  *bit = Utils::CountTrailingZeros64(mask_value);
  return true;
}

void TestIntInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                  BranchInstr* branch) {
  // Check if this is a single bit test. In this case this branch can be
  // emitted as TBZ/TBNZ.
  intptr_t bit_index;
  if (IsSingleBitMask(locs()->in(1), &bit_index)) {
    BranchLabels labels = compiler->CreateBranchLabels(branch);
    const Register value = locs()->in(0).reg();

    bool branch_on_zero_bit;
    bool can_fallthrough;
    compiler::Label* target;
    if (labels.fall_through == labels.true_label) {
      target = labels.false_label;
      branch_on_zero_bit = (kind() == Token::kNE);
      can_fallthrough = true;
    } else {
      target = labels.true_label;
      branch_on_zero_bit = (kind() == Token::kEQ);
      can_fallthrough = (labels.fall_through == labels.false_label);
    }

    if (representation_ == kTagged) {
      bit_index = Utils::Minimum(kSmiBits, bit_index) + kSmiTagShift;
    }

    if (branch_on_zero_bit) {
      __ tbz(target, value, bit_index);
    } else {
      __ tbnz(target, value, bit_index);
    }
    if (!can_fallthrough) {
      __ b(labels.false_label);
    }

    return;
  }

  // Otherwise use shared implementation.
  ConditionInstr::EmitBranchCode(compiler, branch);
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
    __ b(result ? labels.true_label : labels.false_label, EQ);
  }
  // No match found, deoptimize or default action.
  if (deopt == nullptr) {
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
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (input_representation() == kUnboxedDouble) {
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
  } else {
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, LocationRegisterOrConstant(right()));
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition RelationalOpInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                               BranchLabels labels) {
  switch (input_representation()) {
    case kTagged:
      return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
    case kUnboxedInt64:
    case kUnboxedInt32:
    case kUnboxedUint32:
      return EmitUnboxedIntComparisonOp(compiler, *locs(), kind(),
                                        input_representation(), labels);
    case kUnboxedDouble:
      return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
    default:
      UNREACHABLE();
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // Pass a pointer to the first argument in R2.
  __ AddImmediate(R2, SP, (ArgumentCount() - 1) * kWordSize);

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
    compiler->GeneratePatchableCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs(),
        compiler::ObjectPoolBuilderEntry::kResetToBootstrapNative);
  } else {
    // We can never lazy-deopt here because natives are never optimized.
    ASSERT(!compiler->is_optimizing());
    compiler->GenerateNonLazyDeoptableStubCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs(),
        compiler::ObjectPoolBuilderEntry::kNotSnapshotable);
  }
  __ LoadFromOffset(result, SP, 0);

  compiler->EmitDropArguments(ArgumentCount());  // Drop the arguments.
}

#define R(r) (1 << r)

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(CallingConventions::kSecondNonArgumentRegister) | R(R11) |
       R(CallingConventions::kFfiAnyNonAbiRegister) | R(R25)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register branch = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  const Register temp1 = locs()->temp(0).reg();
  const Register temp2 = locs()->temp(1).reg();
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves.
  // For leaf calls, this holds the SP used to restore the pre-aligned SP after
  // the call.
  const Register saved_fp_or_sp = locs()->temp(2).reg();
  const Register temp_csp = locs()->temp(3).reg();

  // Ensure these are callee-saved register and are preserved across the call.
  ASSERT(IsCalleeSavedRegister(saved_fp_or_sp));
  ASSERT(IsCalleeSavedRegister(temp_csp));
  // Other temps don't need to be preserved.

  __ mov(saved_fp_or_sp, is_leaf_ ? SPREG : FPREG);

  if (!is_leaf_) {
    // We need to create a dummy "exit frame". It will share the same pool
    // pointer but have a null code object.
    __ LoadObject(CODE_REG, Object::null_object());
    __ set_constant_pool_allowed(false);
    __ EnterDartFrame(0, PP);
  }

  // Reserve space for the arguments that go on the stack (if any), then align.
  intptr_t stack_space = marshaller_.RequiredStackSpaceInBytes();
  __ ReserveAlignedFrameSpace(stack_space);
  if (FLAG_target_memory_sanitizer) {
    RegisterSet kVolatileRegisterSet(kAbiVolatileCpuRegs & ~(1 << SP),
                                     kAbiVolatileFpuRegs);
    __ mov(temp1, SP);
    SPILLS_LR_TO_FRAME(__ PushRegisters(kVolatileRegisterSet));

    // Unpoison everything from SP to FP: this covers both space we have
    // reserved for outgoing arguments and the spills which might have
    // been generated by the register allocator. Some of these spill slots
    // can be used as handles passed down to the runtime.
    __ sub(R1, is_leaf_ ? FPREG : saved_fp_or_sp, compiler::Operand(temp1));
    __ MsanUnpoison(temp1, R1);

    // Incoming Dart arguments to this trampoline are potentially used as local
    // handles.
    __ MsanUnpoison(is_leaf_ ? FPREG : saved_fp_or_sp,
                    (kParamEndSlotFromFp + InputCount()) * kWordSize);

    // Outgoing arguments passed by register to the foreign function.
    __ LoadImmediate(R0, InputCount());
    __ CallCFunction(compiler::Address(
        THR, kMsanUnpoisonParamRuntimeEntry.OffsetFromThread()));

    RESTORES_LR_FROM_FRAME(__ PopRegisters(kVolatileRegisterSet));
  }

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
    __ StoreToOffset(branch, THR, compiler::target::Thread::vm_tag_offset());
#endif

    // We are entering runtime code, so the C stack pointer must be restored
    // from the stack limit to the top of the stack.
    __ mov(temp_csp, CSP);
    __ mov(CSP, SP);

#if defined(SIMULATOR_FFI)
    if (FLAG_use_simulator) {
      __ Emit(Instr::kSimulatorFfiRedirectInstruction);
      ASSERT(branch == R9);
    }
#endif
    __ blr(branch);

    // Restore the Dart stack pointer.
    __ mov(SP, CSP);
    __ mov(CSP, temp_csp);

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
    // ADR loads relative to itself, so add kInstrSize to point to the next
    // instruction.
    __ adr(temp1, compiler::Immediate(Instr::kInstrSize));
    compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());

    __ StoreToOffset(temp1, FPREG, kSavedCallerPcSlotFromFp * kWordSize);

    // Update information in the thread object and enter a safepoint.
    // Outline state transition. In AOT, for code size. In JIT, because we
    // cannot trust that code will be executable.
    __ ldr(temp1,
           compiler::Address(
               THR, compiler::target::Thread::
                        call_native_through_safepoint_entry_point_offset()));

    // Calls R9 and clobbers R19 (along with volatile registers).
    ASSERT(branch == R9);
    __ blr(temp1);

    if (marshaller_.IsHandleCType(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      compiler::Label not_error;
      __ ldr(temp1,
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
      __ ldr(temp1,
             compiler::Address(
                 THR, compiler::target::Thread::
                          call_native_through_safepoint_entry_point_offset()));
      __ ldr(branch, compiler::Address(
                         THR, kPropagateErrorRuntimeEntry.OffsetFromThread()));
      __ blr(temp1);
#if defined(DEBUG)
      // We should never return with normal controlflow from this.
      __ brk(0);
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
    __ mov(SPREG, saved_fp_or_sp);
  } else {
    __ LeaveDartFrame();

    // Restore the global object pool after returning from runtime (old space is
    // moving, so the GOP could have been relocated).
    if (FLAG_precompiled_mode) {
      __ SetupGlobalPoolAndDispatchTable();
    }

    __ set_constant_pool_allowed(true);
  }
}

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  // Restore tag before the profiler's stack walker will no longer see the
  // InvokeDartCode return address.
  __ LoadFromOffset(TMP, FP, NativeEntryInstr::kVMTagOffsetFromFp);
  __ StoreToOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());

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

  // Enter the entry frame. NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  __ EnterFrame(0);

  // Save a space for the code object.
  __ PushImmediate(0);

  __ PushNativeCalleeSavedRegisters();

  // Now that we have THR, we can set CSP.
  __ SetupCSPFromThread(THR);

#if defined(DART_TARGET_OS_FUCHSIA)
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
  ASSERT(kVMTagOffsetFromFp == 5 * compiler::target::kWordSize);

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

  // The callback trampoline (caller) has already left the safepoint for us.
  __ TransitionNativeToGenerated(R0, /*exit_safepoint=*/false,
                                 /*set_tag=*/false);

  // Now that the safepoint has ended, we can touch Dart objects without
  // handles.

  // Load the code object.
  const Function& target_function = marshaller_.dart_signature();
  const intptr_t callback_id = target_function.FfiCallbackId();
  __ LoadFromOffset(R0, THR, compiler::target::Thread::isolate_group_offset());
  __ LoadFromOffset(R0, R0,
                    compiler::target::IsolateGroup::object_store_offset());
  __ LoadFromOffset(R0, R0,
                    compiler::target::ObjectStore::ffi_callback_code_offset());
  __ LoadCompressedFieldFromOffset(
      R0, R0, compiler::target::GrowableObjectArray::data_offset());
  __ LoadCompressedFieldFromOffset(
      CODE_REG, R0,
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

  // Delay setting the tag until the profiler's stack walker will see the
  // InvokeDartCode return address.
  __ LoadImmediate(TMP, compiler::target::Thread::vm_tag_dart_id());
  __ StoreToOffset(TMP, THR, compiler::target::Thread::vm_tag_offset());
}

#define R(r) (1 << r)

LocationSummary* LeafRuntimeCallInstr::MakeLocationSummary(
    Zone* zone,
    bool is_optimizing) const {
  // Compare FfiCallInstr's use of kFfiAnyNonAbiRegister.
  constexpr Register saved_csp = CallingConventions::kFfiAnyNonAbiRegister;
  ASSERT(IsAbiPreservedRegister(saved_csp));
  return MakeLocationSummaryInternal(zone, (R(saved_csp)));
}

#undef R

void LeafRuntimeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register saved_fp = TMP2;
  const Register temp0 = TMP;
  const Register saved_csp = locs()->temp(0).reg();

  __ MoveRegister(saved_fp, FPREG);

  const intptr_t frame_space = native_calling_convention_.StackTopInBytes();
  __ EnterCFrame(frame_space);
  ASSERT(IsAbiPreservedRegister(saved_csp));
  __ mov(saved_csp, CSP);
  __ mov(CSP, SP);

  EmitParamMoves(compiler, saved_fp, temp0);

  const Register target_address = locs()->in(TargetAddressIndex()).reg();
  __ str(target_address,
         compiler::Address(THR, compiler::target::Thread::vm_tag_offset()));
  __ CallCFunction(target_address);
  __ LoadImmediate(temp0, VMTag::kDartTagId);
  __ str(temp0,
         compiler::Address(THR, compiler::target::Thread::vm_tag_offset()));

  // We don't use the DartSP, we leave the frame after this immediately.
  // However, we need set CSP to a 16 byte aligned value far above the SP.
  __ mov(CSP, saved_csp);
  __ LeaveCFrame();
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
  __ LoadCompressedSmi(result,
                       compiler::FieldAddress(str, String::length_offset()));
  __ ldr(TMP, compiler::FieldAddress(str, OneByteString::data_offset()),
         compiler::kUnsignedByte);
  __ CompareImmediate(result, Smi::RawValue(1));
  __ LoadImmediate(result, -1);
  __ csel(result, TMP, result, EQ);
  __ SmiTag(result);
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
  __ LoadFromSlot(bytes_reg, bytes_reg, Slot::PointerBase_data());

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
  if (scan_flags_field_.is_compressed() && !IsScanFlagsUnboxed()) {
    __ LoadCompressedSmiFieldFromOffset(flags_temp_reg, decoder_reg,
                                        scan_flags_field_offset);
    __ orr(flags_temp_reg, flags_temp_reg, compiler::Operand(flags_reg),
           compiler::kObjectBytes);
    __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset,
                          compiler::kObjectBytes);
  } else {
    __ LoadFieldFromOffset(flags_temp_reg, decoder_reg,
                           scan_flags_field_offset);
    __ orr(flags_temp_reg, flags_temp_reg, compiler::Operand(flags_reg));
    __ StoreFieldToOffset(flags_temp_reg, decoder_reg, scan_flags_field_offset);
  }
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  // The compiler must optimize any function that includes a LoadIndexed
  // instruction that uses typed data cids, since extracting the payload address
  // from views is done in a compiler pass after all code motion has happened.
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
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(kArrayPos).reg();
  const Location index = locs()->in(kIndexPos);

  compiler::Address element_address(TMP);  // Bad address.
  element_address = index.IsRegister()
                        ? __ ElementAddressForRegIndex(
                              IsUntagged(), class_id(), index_scale(),
                              index_unboxed_, array, index.reg(), TMP)
                        : __ ElementAddressForIntIndex(
                              IsUntagged(), class_id(), index_scale(), array,
                              Smi::Cast(index.constant()).Value());
  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  ASSERT(representation() == Boxing::NativeRepresentation(rep));
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    const Register result = locs()->out(0).reg();
    __ ldr(result, element_address, RepresentationUtils::OperandSize(rep));
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    const VRegister result = locs()->out(0).fpu_reg();
    if (rep == kUnboxedFloat) {
      // Load single precision float.
      __ fldrs(result, element_address);
    } else if (rep == kUnboxedDouble) {
      // Load double precision float.
      __ fldrd(result, element_address);
    } else {
      ASSERT(rep == kUnboxedInt32x4 || rep == kUnboxedFloat32x4 ||
             rep == kUnboxedFloat64x2);
      __ fldrq(result, element_address);
    }
  } else {
    const Register result = locs()->out(0).reg();
    ASSERT(representation() == kTagged);
    ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
           (class_id() == kTypeArgumentsCid) || (class_id() == kRecordCid));
    __ LoadCompressed(result, element_address);
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
      break;
  }
  // Warning: element_address may use register TMP as base.
  compiler::Address element_address = __ ElementAddressForRegIndexWithSize(
      IsExternal(), class_id(), sz, index_scale(), /*index_unboxed=*/false, str,
      index.reg(), TMP);
  __ ldr(result, element_address, sz);

  ASSERT(can_pack_into_smi());
  __ SmiTag(result);
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  // The compiler must optimize any function that includes a StoreIndexed
  // instruction that uses typed data cids, since extracting the payload address
  // from views is done in a compiler pass after all code motion has happened.
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
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register temp = locs()->temp(0).reg();
  compiler::Address element_address(TMP);  // Bad address.

  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  ASSERT(RequiredInputRepresentation(2) == Boxing::NativeRepresentation(rep));

  // Deal with a special case separately.
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
      // Clamp to 0x0 or 0xFF respectively.
      if (value > 0xFF) {
        value = 0xFF;
      } else if (value < 0) {
        value = 0;
      }
      if (value == 0) {
        __ str(ZR, element_address, compiler::kUnsignedByte);
      } else {
        __ LoadImmediate(TMP, static_cast<int8_t>(value));
        __ str(TMP, element_address, compiler::kUnsignedByte);
      }
    } else {
      const Register value = locs()->in(2).reg();
      // Clamp to 0x00 or 0xFF respectively.
      __ CompareImmediate(value, 0xFF);
      __ csetm(TMP, GT);             // TMP = value > 0xFF ? -1 : 0.
      __ csel(TMP, value, TMP, LS);  // TMP = value in range ? value : TMP.
      __ str(TMP, element_address, compiler::kUnsignedByte);
    }
  } else if (RepresentationUtils::IsUnboxedInteger(rep)) {
    if (locs()->in(2).IsConstant()) {
      ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
      __ str(ZR, element_address, RepresentationUtils::OperandSize(rep));
    } else {
      __ str(locs()->in(2).reg(), element_address,
             RepresentationUtils::OperandSize(rep));
    }
  } else if (RepresentationUtils::IsUnboxed(rep)) {
    if (rep == kUnboxedFloat) {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ str(ZR, element_address, compiler::kFourBytes);
      } else {
        __ fstrs(locs()->in(2).fpu_reg(), element_address);
      }
    } else if (rep == kUnboxedDouble) {
      if (locs()->in(2).IsConstant()) {
        ASSERT(locs()->in(2).constant_instruction()->HasZeroRepresentation());
        __ str(ZR, element_address, compiler::kEightBytes);
      } else {
        __ fstrd(locs()->in(2).fpu_reg(), element_address);
      }
    } else {
      ASSERT(rep == kUnboxedInt32x4 || rep == kUnboxedFloat32x4 ||
             rep == kUnboxedFloat64x2);
      const VRegister value_reg = locs()->in(2).fpu_reg();
      __ fstrq(value_reg, element_address);
    }
  } else if (class_id() == kArrayCid) {
    ASSERT(!ShouldEmitStoreBarrier());  // Specially treated above.
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

  if (FLAG_target_memory_sanitizer) {
    if (index.IsRegister()) {
      __ ComputeElementAddressForRegIndex(TMP, IsUntagged(), class_id(),
                                          index_scale(), index_unboxed_, array,
                                          index.reg());
    } else {
      __ ComputeElementAddressForIntIndex(TMP, IsUntagged(), class_id(),
                                          index_scale(), array,
                                          Smi::Cast(index.constant()).Value());
    }
    const intptr_t length_in_bytes = RepresentationUtils::ValueSize(
        RepresentationUtils::RepresentationOfArrayElement(class_id()));
    __ MsanUnpoison(TMP, length_in_bytes);
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
  __ BranchIfSmi(value_reg, value_is_smi == nullptr ? &done : value_is_smi);
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
      __ ldr(TMP, field_cid_operand, compiler::kUnsignedFourBytes);
      __ CompareRegisters(value_cid_reg, TMP);
      __ b(&ok, EQ);
      __ ldr(TMP, field_nullability_operand, compiler::kUnsignedFourBytes);
      __ CompareRegisters(value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ ldr(value_cid_reg, field_nullability_operand,
             compiler::kUnsignedFourBytes);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      compiler::Label skip_length_check;
      __ ldr(value_cid_reg, field_cid_operand, compiler::kUnsignedFourBytes);
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
      __ ldr(TMP, field_cid_operand, compiler::kUnsignedFourBytes);
      __ CompareImmediate(TMP, kIllegalCid);
      __ b(fail, NE);

      if (value_cid == kDynamicCid) {
        __ str(value_cid_reg, field_cid_operand, compiler::kUnsignedFourBytes);
        __ str(value_cid_reg, field_nullability_operand,
               compiler::kUnsignedFourBytes);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ str(TMP, field_cid_operand, compiler::kUnsignedFourBytes);
        __ str(TMP, field_nullability_operand, compiler::kUnsignedFourBytes);
      }

      __ b(&ok);
    }

    if (deopt == nullptr) {
      __ Bind(fail);

      __ LoadFieldFromOffset(TMP, field_reg, Field::guarded_cid_offset(),
                             compiler::kUnsignedFourBytes);
      __ CompareImmediate(TMP, kDynamicCid);
      __ b(&ok, EQ);

      __ PushPair(value_reg, field_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ b(fail);
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != nullptr);

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
      // This would normally be caught by Canonicalize, but RemoveRedefinitions
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
          : nullptr;

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
    __ LoadCompressedSmi(
        length_reg,
        compiler::FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ tst(offset_reg, compiler::Operand(offset_reg));
    __ b(&ok, MI);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ LoadCompressedSmi(TMP, compiler::Address(value_reg, offset_reg));
    __ CompareObjectRegisters(length_reg, TMP);

    if (deopt == nullptr) {
      __ b(&ok, EQ);

      __ PushPair(value_reg, field_reg);
      ASSERT(!compiler->is_optimizing());  // No deopt info needed.
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

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  const bool can_call_to_throw = FLAG_experimental_shared_data;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      can_call_to_throw ? LocationSummary::kCallOnSlowPath
                                        : LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  compiler->used_static_fields().Add(&field());

  if (FLAG_experimental_shared_data) {
    if (!field().is_shared()) {
      auto slow_path = new FieldAccessErrorSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ LoadIsolate(temp);
      __ BranchIfZero(temp, slow_path->entry_label());
    } else {
      // TODO(dartbug.com/61078): use field static type information to decide
      // whether the following value check is needed or not.
      auto throw_if_cant_be_shared_slow_path =
          new ThrowIfValueCantBeSharedSlowPath(this, value);
      compiler->AddSlowPathCode(throw_if_cant_be_shared_slow_path);

      compiler::Label allow_store;
      __ BranchIfSmi(value, &allow_store, compiler::Assembler::kNearJump);
      __ ldr(temp,
             compiler::FieldAddress(value,
                                    compiler::target::Object::tags_offset()),
             compiler::kUnsignedByte);
      __ tbnz(&allow_store, temp,
              compiler::target::UntaggedObject::kImmutableBit);

      // Allow TypedData because they contain non-structural mutable state.
      __ LoadClassId(temp, value);
      __ CompareImmediate(temp, kFirstTypedDataCid);
      __ b(throw_if_cant_be_shared_slow_path->entry_label(), UNSIGNED_LESS);
      __ CompareImmediate(temp, kLastTypedDataCid);
      __ b(throw_if_cant_be_shared_slow_path->entry_label(), UNSIGNED_GREATER);

      __ Bind(&allow_store);
    }
  }

  __ LoadFromOffset(
      temp, THR,
      field().is_shared()
          ? compiler::target::Thread::shared_field_table_values_offset()
          : compiler::target::Thread::field_table_values_offset());
  // Note: static fields ids won't be changed by hot-reload.
  if (field().is_shared()) {
    __ StoreRelease(value,
                    compiler::Address(
                        temp, compiler::target::FieldTable::OffsetOf(field())));
  } else {
    __ StoreToOffset(value, temp,
                     compiler::target::FieldTable::OffsetOf(field()));
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
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == TypeTestABI::kInstanceReg);
  ASSERT(locs()->in(1).reg() == TypeTestABI::kInstantiatorTypeArgumentsReg);
  ASSERT(locs()->in(2).reg() == TypeTestABI::kFunctionTypeArgumentsReg);

  compiler->GenerateInstanceOf(source(), deopt_id(), env(), type(), locs());
  ASSERT(locs()->out(0).reg() == R0);
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
                      R3,                            // end address
                      R6, R8);
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

  // TODO(zra): Use stp once added.
  // Initialize all array elements to raw_null.
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // R3: new object end address.
  // R8: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(UntaggedArray);
    __ AddImmediate(R8, AllocateArrayABI::kResultReg,
                    sizeof(UntaggedArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kCompressedWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ StoreCompressedIntoObjectNoBarrier(
            AllocateArrayABI::kResultReg, compiler::Address(R8, current_offset),
            NULL_REG);
        current_offset += kCompressedWordSize;
      }
    } else {
      compiler::Label end_loop, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(R8, R3);
      __ b(&end_loop, CS);
      __ StoreCompressedIntoObjectNoBarrier(AllocateArrayABI::kResultReg,
                                            compiler::Address(R8, 0), NULL_REG);
      __ AddImmediate(R8, kCompressedWordSize);
      __ b(&init_loop);
      __ Bind(&end_loop);
    }
  }
  __ b(done);
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

    auto slow_path_env = compiler->SlowPathEnvironmentFor(
        instruction(), /*num_slow_path_args=*/0);
    ASSERT(slow_path_env != nullptr);

    auto object_store = compiler->isolate_group()->object_store();
    const auto& allocate_context_stub = Code::ZoneHandle(
        compiler->zone(), object_store->allocate_context_stub());

    __ LoadImmediate(R1, instruction()->num_context_variables());
    compiler->GenerateStubCall(instruction()->source(), allocate_context_stub,
                               UntaggedPcDescriptors::kOther, locs,
                               instruction()->deopt_id(), slow_path_env);
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

  if (!FLAG_use_slow_path && FLAG_inline_alloc) {
    __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                        result,  // instance
                        temp0, temp1, temp2);

    // Setup up number of context variables field.
    __ LoadImmediate(temp0, num_context_variables());
    __ str(temp0,
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
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->out(0).reg() == R0);

  auto object_store = compiler->isolate_group()->object_store();
  const auto& allocate_context_stub =
      Code::ZoneHandle(compiler->zone(), object_store->allocate_context_stub());
  __ LoadImmediate(R1, num_context_variables());
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
  locs->set_in(0, Location::RegisterLocation(R5));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R5);
  ASSERT(locs()->out(0).reg() == R0);

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
  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
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
                locs->live_registers()->FpuRegisterCount() > 0);
        __ Call(compiler::Address(THR, entry_point_offset));
      }
      compiler->RecordSafepoint(locs, kNumSlowPathArgs);
      compiler->RecordCatchEntryMoves(env);
      compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kOther,
                                     instruction()->deopt_id(),
                                     instruction()->source());
      if (!has_frame) {
        __ LeaveDartFrame();
        __ set_constant_pool_allowed(true);
      }
    } else {
      ASSERT(has_frame);
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
    __ b(exit_label());
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
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
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
          : nullptr;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 6 bits for the count.
#if !defined(DART_COMPRESSED_POINTERS)
    const intptr_t kCountLimit = 0x3F;
#else
    const intptr_t kCountLimit = 0x1F;
#endif
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow (preserve left).
      __ LslImmediate(TMP, left, value, compiler::kObjectBytes);
      __ cmp(left, compiler::Operand(TMP, ASR, value), compiler::kObjectBytes);
      __ b(deopt, NE);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ LslImmediate(result, left, value, compiler::kObjectBytes);
    return;
  }

  // Right (locs.in(1)) is not constant.
  const Register right = locs.in(1).reg();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ CompareObjectRegisters(right, ZR);
        __ b(deopt, MI);
        __ mov(result, ZR);
        return;
      }
      const intptr_t max_right =
          compiler::target::kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !shift_left->IsShiftCountInRange(max_right - 1);
      if (right_needs_check) {
        __ CompareObject(right, Smi::ZoneHandle(Smi::New(max_right)));
        __ b(deopt, CS);
      }
      __ SmiUntag(TMP, right);
      __ lslv(result, left, TMP, compiler::kObjectBytes);
    }
    return;
  }

  const bool right_needs_check =
      !shift_left->IsShiftCountInRange(Smi::kBits - 1);
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!shift_left->RightOperandIsPositive()) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareObjectRegisters(right, ZR);
        __ b(deopt, MI);
      }

      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ csel(result, ZR, result, CS);
      __ SmiUntag(TMP, right);
      __ lslv(TMP, left, TMP, compiler::kObjectBytes);
      __ csel(result, TMP, result, CC);
    } else {
      __ SmiUntag(TMP, right);
      __ lslv(result, left, TMP, compiler::kObjectBytes);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareObject(right, Smi::ZoneHandle(Smi::New(Smi::kBits)));
      __ b(deopt, CS);
    }
    // Left is not a constant.
    // Check if count too large for handling it inlined.
    __ SmiUntag(TMP, right);
    // Overflow test (preserve left, right, and TMP);
    const Register temp = locs.temp(0).reg();
    __ lslv(temp, left, TMP, compiler::kObjectBytes);
    __ asrv(TMP2, temp, TMP, compiler::kObjectBytes);
    __ cmp(left, compiler::Operand(TMP2), compiler::kObjectBytes);
    __ b(deopt, NE);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ lslv(result, left, TMP, compiler::kObjectBytes);
  }
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (((op_kind() == Token::kSHL) && can_overflow()) ||
       (op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR))
          ? 1
          : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightOperandIsPowerOfTwoConstant()) {
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
      (op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR)) {
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
    const int64_t imm = Smi::RawValue(Smi::Cast(constant).Value());
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, imm, compiler::kObjectBytes);
        } else {
          __ AddImmediateSetFlags(result, left, imm, compiler::kObjectBytes);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, -imm);
        } else {
          // Negating imm and using AddImmediateSetFlags would not detect the
          // overflow when imm == kMinInt64.
          __ SubImmediateSetFlags(result, left, imm, compiler::kObjectBytes);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ LoadImmediate(TMP, value);
#if !defined(DART_COMPRESSED_POINTERS)
        __ mul(result, left, TMP);
#else
        __ smull(result, left, TMP);
#endif
        if (deopt != nullptr) {
#if !defined(DART_COMPRESSED_POINTERS)
          __ smulh(TMP, left, TMP);
          // TMP: result bits 64..127.
#else
          __ AsrImmediate(TMP, result, 31);
          // TMP: result bits 32..63.
#endif
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
#if !defined(DART_COMPRESSED_POINTERS)
        __ AsrImmediate(TMP, left, 63);
#else
        __ AsrImmediate(TMP, left, 31, compiler::kFourBytes);
#endif
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = TMP2;
#if !defined(DART_COMPRESSED_POINTERS)
        __ add(temp, left, compiler::Operand(TMP, LSR, 64 - shift_count));
#else
        __ addw(temp, left, compiler::Operand(TMP, LSR, 32 - shift_count));
#endif
        ASSERT(shift_count > 0);
        __ AsrImmediate(result, temp, shift_count, compiler::kObjectBytes);
        if (value < 0) {
          __ sub(result, ZR, compiler::Operand(result), compiler::kObjectBytes);
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
#if !defined(DART_COMPRESSED_POINTERS)
        const intptr_t kCountLimit = 0x3F;
#else
        const intptr_t kCountLimit = 0x1F;
#endif
        intptr_t value = Smi::Cast(constant).Value();
        __ AsrImmediate(result, left,
                        Utils::Minimum(value + kSmiTagSize, kCountLimit),
                        compiler::kObjectBytes);
        __ SmiTag(result);
        // BOGUS: this could be one sbfiz
        break;
      }
      case Token::kUSHR: {
        // Lsr operation masks the count to 6 bits, but
        // unsigned shifts by >= kBitsPerInt64 are eliminated by
        // BinaryIntegerOpInstr::Canonicalize.
        const intptr_t kCountLimit = 0x3F;
        intptr_t value = Smi::Cast(constant).Value();
        ASSERT((value >= 0) && (value <= kCountLimit));
        __ SmiUntag(result, left);
        __ LsrImmediate(result, result, value);
        if (deopt != nullptr) {
          __ SmiTagAndBranchIfOverflow(result, deopt);
        } else {
          __ SmiTag(result);
        }
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
        __ add(result, left, compiler::Operand(right), compiler::kObjectBytes);
      } else {
        __ adds(result, left, compiler::Operand(right), compiler::kObjectBytes);
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == nullptr) {
        __ sub(result, left, compiler::Operand(right), compiler::kObjectBytes);
      } else {
        __ subs(result, left, compiler::Operand(right), compiler::kObjectBytes);
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(TMP, left);
#if !defined(DART_COMPRESSED_POINTERS)
      __ mul(result, TMP, right);
#else
      __ smull(result, TMP, right);
#endif
      if (deopt != nullptr) {
#if !defined(DART_COMPRESSED_POINTERS)
        __ smulh(TMP, TMP, right);
        // TMP: result bits 64..127.
#else
        __ AsrImmediate(TMP, result, 31);
        // TMP: result bits 32..63.
#endif
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
      if (RightOperandCanBeZero()) {
        // Handle divide by zero in runtime.
        __ cbz(deopt, right, compiler::kObjectBytes);
      }
      const Register temp = TMP2;
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);

      __ sdiv(result, temp, TMP, compiler::kObjectBytes);
      if (RightOperandCanBeMinusOne()) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
#if !defined(DART_COMPRESSED_POINTERS)
        __ CompareImmediate(result, 0x4000000000000000LL);
#else
        __ CompareImmediate(result, 0x40000000LL, compiler::kFourBytes);
#endif
        __ b(deopt, EQ);
      }
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RightOperandCanBeZero()) {
        // Handle divide by zero in runtime.
        __ cbz(deopt, right, compiler::kObjectBytes);
      }
      const Register temp = TMP2;
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);

      __ sdiv(result, temp, TMP, compiler::kObjectBytes);

      __ SmiUntag(TMP, right);
      __ msub(result, TMP, result, temp,
              compiler::kObjectBytes);  // result <- left - right * result
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
      __ CompareObjectRegisters(result, ZR);
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ CompareObjectRegisters(right, ZR);
      __ sub(TMP, result, compiler::Operand(right), compiler::kObjectBytes);
      __ add(result, result, compiler::Operand(right), compiler::kObjectBytes);
      __ csel(result, TMP, result, LT);
      __ Bind(&done);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ tbnz(deopt, right, compiler::target::kSmiBits + kSmiTagSize);
      }
      __ SmiUntag(TMP, right);
      // asrv[w] operation masks the count to 6/5 bits.
#if !defined(DART_COMPRESSED_POINTERS)
      const intptr_t kCountLimit = 0x3F;
#else
      const intptr_t kCountLimit = 0x1F;
#endif
      if (!IsShiftCountInRange(kCountLimit)) {
        __ LoadImmediate(TMP2, kCountLimit);
        __ CompareObjectRegisters(TMP, TMP2);
        __ csel(TMP, TMP2, TMP, GT);
      }
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ asrv(result, temp, TMP, compiler::kObjectBytes);
      __ SmiTag(result);
      break;
    }
    case Token::kUSHR: {
      if (CanDeoptimize()) {
        __ tbnz(deopt, right, compiler::target::kSmiBits + kSmiTagSize);
      }
      __ SmiUntag(TMP, right);
      // lsrv operation masks the count to 6 bits.
      const intptr_t kCountLimit = 0x3F;
      COMPILE_ASSERT(kCountLimit + 1 == kBitsPerInt64);
      compiler::Label done;
      if (!IsShiftCountInRange(kCountLimit)) {
        __ LoadImmediate(TMP2, kCountLimit);
        __ CompareRegisters(TMP, TMP2);
        __ csel(result, ZR, result, GT);
        __ b(&done, GT);
      }
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ lsrv(result, temp, TMP);
      if (deopt != nullptr) {
        __ SmiTagAndBranchIfOverflow(result, deopt);
      } else {
        __ SmiTag(result);
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
  ASSERT(!RepresentationUtils::IsUnsignedInteger(representation()));
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
#if !defined(DART_COMPRESSED_POINTERS)
      __ scvtfdx(result, TMP);
#else
      __ scvtfdw(result, TMP);
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
  __ LoadInt32FromBoxOrSmi(result, value);
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadInt64FromBoxOrSmi(result, value);
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
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

#if !defined(DART_COMPRESSED_POINTERS)
  ASSERT(compiler::target::kSmiBits >= 32);
  if (from_representation() == kUnboxedInt32) {
    __ sbfiz(out, value, kSmiTagSize, 32);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ ubfiz(out, value, kSmiTagSize, 32);
  }
#else
  compiler::Label done;
  if (from_representation() == kUnboxedInt32) {
    ASSERT(kSmiTag == 0);
    // Signed Bitfield Insert in Zero instruction extracts the 31 significant
    // bits from a Smi.
    __ sbfiz(out, value, kSmiTagSize, 32 - kSmiTagSize);
    if (ValueFitsSmi()) {
      return;
    }
    __ cmpw(value, compiler::Operand(out, ASR, 1));
    __ b(&done, EQ);  // Jump if the sbfiz instruction didn't lose info.
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    // A 32 bit positive Smi has one tag bit and one unused sign bit,
    // leaving only 30 bits for the payload.
    __ LslImmediate(out, value, kSmiTagSize, compiler::kFourBytes);
    if (ValueFitsSmi()) {
      return;
    }
    __ TestImmediate(value, 0xC0000000);
    __ b(&done, EQ);  // Jump if both bits are zero.
  }

  Register temp = locs()->temp(0).reg();
  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  temp);
  if (from_representation() == kUnboxedInt32) {
    __ sxtw(temp, value);  // Sign-extend.
  } else {
    __ uxtw(temp, value);  // Zero-extend.
  }
  __ StoreToOffset(temp, out, Mint::value_offset() - kHeapObjectTag);
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
      ValueFitsSmi()          ? LocationSummary::kNoCall
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
  compiler::Label done;
#if !defined(DART_COMPRESSED_POINTERS)
  __ adds(out, in, compiler::Operand(in));  // SmiTag
  // If the value doesn't fit in a smi, the tagging changes the sign,
  // which causes the overflow flag to be set.
  __ b(&done, NO_OVERFLOW);
#else
  __ sbfiz(out, in, kSmiTagSize, 31);  // SmiTag + sign-extend.
  __ cmp(in, compiler::Operand(out, ASR, kSmiTagSize));
  __ b(&done, EQ);
#endif

  Register temp = locs()->temp(0).reg();
  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out, temp);
  } else if (locs()->call_on_shared_slow_path()) {
    const bool has_frame = compiler->flow_graph().graph_entry()->NeedsFrame();
    if (!has_frame) {
      ASSERT(__ constant_pool_allowed());
      __ set_constant_pool_allowed(false);
      __ EnterDartFrame(0);
    }
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
    if (!has_frame) {
      __ LeaveDartFrame();
      __ set_constant_pool_allowed(true);
    }
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
          : nullptr;

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
  } else {
    compiler::Label done;
    __ SmiUntag(out, value);
    __ BranchIfSmi(value, &done);
    if (CanDeoptimize()) {
      __ CompareClassId(value, kMintCid);
      __ b(deopt, NE);
    }
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
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
  const bool needs_temp = op_kind() != MethodRecognizer::kDouble_getIsNaN;
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (needs_temp) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition DoubleTestOpInstr::EmitConditionCode(FlowGraphCompiler* compiler,
                                               BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const VRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;

  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN: {
      __ fcmpd(value, value);
      return is_negated ? VC : VS;
    }
    case MethodRecognizer::kDouble_getIsInfinite: {
      const Register temp = locs()->temp(0).reg();
      __ vmovrd(temp, value, 0);
      // Mask off the sign.
      __ AndImmediate(temp, temp, 0x7FFFFFFFFFFFFFFFLL);
      // Compare with +infinity.
      __ CompareImmediate(temp, 0x7FF0000000000000LL);
      return is_negated ? NE : EQ;
    }
    case MethodRecognizer::kDouble_getIsNegative: {
      const Register temp = locs()->temp(0).reg();
      compiler::Label not_zero;
      __ fcmpdz(value);
      // If it's NaN, it's not negative.
      __ b(is_negated ? labels.true_label : labels.false_label, VS);
      __ b(&not_zero, NOT_EQUAL);
      // Check for negative zero with a signed comparison.
      __ fmovrd(temp, value);
      __ CompareImmediate(temp, 0);
      __ Bind(&not_zero);
      return is_negated ? GE : LT;
    }
    default:
      UNREACHABLE();
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
    case SimdOpInstr::kFloat32x4GetX:
      __ vinss(result, 0, value, 0);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4GetY:
      __ vinss(result, 0, value, 1);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4GetZ:
      __ vinss(result, 0, value, 2);
      __ fcvtds(result, result);
      break;
    case SimdOpInstr::kFloat32x4GetW:
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

DEFINE_EMIT(
    Float64x2Clamp,
    (VRegister result, VRegister value, VRegister lower, VRegister upper)) {
  __ vmind(result, value, upper);
  __ vmaxd(result, result, lower);
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
    __ CompareObjectRegisters(vs[i], TMP2);
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
  compiler::LeafRuntimeScope rt(compiler->assembler(),
                                /*frame_size=*/0,
                                /*preserve_registers=*/false);
  // Call the function. Parameters are already in their correct spots.
  rt.Call(TargetFunction(), TargetFunction().argument_count());
}

LocationSummary* MathMinMaxInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  if (representation() == kUnboxedDouble) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresFpuRegister());
    return summary;
  }
  ASSERT(representation() == kUnboxedInt64);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void MathMinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((op_kind() == MethodRecognizer::kMathMin) ||
         (op_kind() == MethodRecognizer::kMathMax));
  const bool is_min = (op_kind() == MethodRecognizer::kMathMin);
  if (representation() == kUnboxedDouble) {
    const VRegister left = locs()->in(0).fpu_reg();
    const VRegister right = locs()->in(1).fpu_reg();
    const VRegister result = locs()->out(0).fpu_reg();
    if (is_min) {
      __ vmind(result, left, right);
    } else {
      __ vmaxd(result, left, right);
    }
    return;
  }

  ASSERT(representation() == kUnboxedInt64);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  __ CompareRegisters(left, right);
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
      __ subs(result, ZR, compiler::Operand(value), compiler::kObjectBytes);
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn_(result, value);
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
  ASSERT(representation() == kUnboxedDouble);
  const VRegister result = locs()->out(0).fpu_reg();
  const VRegister value = locs()->in(0).fpu_reg();
  switch (op_kind()) {
    case Token::kNEGATE:
      __ fnegd(result, value);
      break;
    case Token::kSQRT:
      __ fsqrtd(result, value);
      break;
    case Token::kSQUARE:
      __ fmuld(result, value, value);
      break;
    default:
      UNREACHABLE();
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
#if !defined(DART_COMPRESSED_POINTERS)
  __ scvtfdx(result, TMP);
#else
  __ scvtfdw(result, TMP);
#endif
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
  LocationSummary* result = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  const VRegister value_double = locs()->in(0).fpu_reg();

  DoubleToIntegerSlowPath* slow_path =
      new DoubleToIntegerSlowPath(this, value_double);
  compiler->AddSlowPathCode(slow_path);

  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM64 because fcvtzs gives 0 for NaN.
  __ fcmpd(value_double, value_double);
  __ b(slow_path->entry_label(), VS);

  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleToInteger:
      __ fcvtzsxd(result, value_double);
      break;
    case MethodRecognizer::kDoubleFloorToInt:
      __ fcvtmsxd(result, value_double);
      break;
    case MethodRecognizer::kDoubleCeilToInt:
      __ fcvtpsxd(result, value_double);
      break;
    default:
      UNREACHABLE();
  }
    // Overflow is signaled with minint.

#if !defined(DART_COMPRESSED_POINTERS)
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC000000000000000);
  __ b(slow_path->entry_label(), MI);
#else
  // Check for overflow and that it fits into Smi.
  __ AsrImmediate(TMP, result, 30);
  __ cmp(TMP, compiler::Operand(result, ASR, 63));
  __ b(slow_path->entry_label(), NE);
#endif
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
  const Register result = locs()->out(0).reg();
  const VRegister value = locs()->in(0).fpu_reg();
  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM64 because fcvtzs gives 0 for NaN.
  // TODO(zra): Check spec that this is true.
  __ fcmpd(value, value);
  __ b(deopt, VS);

  __ fcvtzsxd(result, value);

#if !defined(DART_COMPRESSED_POINTERS)
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC000000000000000);
  __ b(deopt, MI);
#else
  // Check for overflow and that it fits into Smi.
  __ AsrImmediate(TMP, result, 30);
  __ cmp(TMP, compiler::Operand(result, ASR, 63));
  __ b(deopt, NE);
#endif
  __ SmiTag(result);
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
  {
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    ASSERT(base == V0);
    ASSERT(exp == V1);
    rt.Call(instr->TargetFunction(), kInputCount);
    ASSERT(result == V0);
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
  ASSERT(locs()->in(0).fpu_reg() == V0);
  if (InputCount() == 2) {
    ASSERT(locs()->in(1).fpu_reg() == V1);
  }
  rt.Call(TargetFunction(), InputCount());
  ASSERT(locs()->out(0).fpu_reg() == V0);
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
    __ CompareObjectRegisters(right, ZR);
    __ b(deopt, EQ);
  }

  __ SmiUntag(result_mod, left);
  __ SmiUntag(TMP, right);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
#if !defined(DART_COMPRESSED_POINTERS)
  __ sdiv(result_div, result_mod, TMP);
  __ CompareImmediate(result_div, 0x4000000000000000);
#else
  __ sdivw(result_div, result_mod, TMP);
  __ CompareImmediate(result_div, 0x40000000, compiler::kFourBytes);
#endif
  __ b(deopt, EQ);
  // result_mod <- left - right * result_div.
  __ msub(result_mod, TMP, result_div, result_mod, compiler::kObjectBytes);
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
  __ CompareObjectRegisters(result_mod, ZR);
  __ b(&done, GE);
  // Result is negative, adjust it.
  if (RangeUtils::IsNegative(divisor_range())) {
    __ sub(result_mod, result_mod, compiler::Operand(right));
  } else if (RangeUtils::IsPositive(divisor_range())) {
    __ add(result_mod, result_mod, compiler::Operand(right));
  } else {
    __ CompareObjectRegisters(right, ZR);
    __ sub(TMP2, result_mod, compiler::Operand(right), compiler::kObjectBytes);
    __ add(TMP, result_mod, compiler::Operand(right), compiler::kObjectBytes);
    __ csel(result_mod, TMP, TMP2, GE);
  }
  __ Bind(&done);
}

// Should be kept in sync with integers.cc Multiply64Hash
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register value,
                                        const Register result) {
  ASSERT(value != TMP2);
  ASSERT(result != TMP2);
  ASSERT(value != result);
  __ LoadImmediate(TMP2, compiler::Immediate(0x2d51));
  __ mul(result, value, TMP2);
  __ umulh(value, value, TMP2);
  __ eor(result, result, compiler::Operand(value));
  __ eor(result, result, compiler::Operand(result, LSR, 32));
}

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister temp_double = locs()->temp(0).fpu_reg();
  const Register result = locs()->out(0).reg();

  compiler::Label done, hash_double;
  __ vmovrd(TMP, value, 0);
  __ AndImmediate(TMP, TMP, 0x7FF0000000000000LL);
  __ CompareImmediate(TMP, 0x7FF0000000000000LL);
  __ b(&hash_double, EQ);  // is_infinity or nan

  __ fcvtzsxd(TMP, value);
  __ scvtfdx(temp_double, TMP);
  __ fcmpd(temp_double, value);
  __ b(&hash_double, NE);

  EmitHashIntegerCodeSequence(compiler, TMP, result);
  __ AndImmediate(result, result, 0x3fffffff);
  __ b(&done);

  __ Bind(&hash_double);
  __ fmovrd(result, value);
  __ eor(result, result, compiler::Operand(result, LSR, 32));
  __ AndImmediate(result, result, compiler::target::kSmiMax);

  __ Bind(&done);
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  if (smi_) {
    __ SmiUntag(TMP, value);
  } else {
    __ LoadFieldFromOffset(TMP, value, Mint::value_offset());
  }

  EmitHashIntegerCodeSequence(compiler, TMP, result);
  __ ubfm(result, result, 63, 29);  // SmiTag(result & 0x3fffffff)
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
    __ b(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareObject(length, index);
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ tst(index, compiler::Operand(index), compiler::kObjectBytes);
      __ b(deopt, MI);
    } else {
      __ CompareObject(index, length);
      __ b(deopt, CS);
    }
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ CompareObjectRegisters(index, length);
    __ b(deopt, CS);
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
  __ ldr(TMP,
         compiler::FieldAddress(locs()->in(0).reg(),
                                compiler::target::Object::tags_offset()),
         compiler::kUnsignedByte);
  // In the first byte.
  ASSERT(compiler::target::UntaggedObject::kImmutableBit < 8);
  __ tbnz(slow_path->entry_label(), TMP,
          compiler::target::UntaggedObject::kImmutableBit);
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
      if (instruction()->AsBinaryInt64Op()->RightOperandIsPositive()) {
        // Always positive.
        __ add(out_, out_, compiler::Operand(divisor_));
      } else if (instruction()->AsBinaryInt64Op()->RightOperandIsNegative()) {
        // Always negative.
        __ sub(out_, out_, compiler::Operand(divisor_));
      } else {
        // General case.
        __ CompareRegisters(divisor_, ZR);
        __ sub(tmp_, out_, compiler::Operand(divisor_));
        __ add(out_, out_, compiler::Operand(divisor_));
        __ csel(out_, tmp_, out_, LT);
      }
      __ b(exit_label());
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

  // Special case 64-bit div/mod by compile-time constant. Note that various
  // special constants (such as powers of two) should have been optimized
  // earlier in the pipeline. Div or mod by zero falls into general code
  // to implement the exception.
  if (FLAG_optimization_level <= 2) {
    // We only consider magic operations under O3.
  } else if (auto c = instruction->right()->definition()->AsConstant()) {
    if (c->value().IsInteger()) {
      const int64_t divisor = Integer::Cast(c->value()).Value();
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
  Int64DivideSlowPath* slow_path =
      new (Z) Int64DivideSlowPath(instruction, right, tmp, out);

  // Handle modulo/division by zero exception on slow path.
  if (slow_path->has_divide_by_zero()) {
    __ cbz(slow_path->entry_label(), right);
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
      const intptr_t kNumTemps = 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
      summary->set_in(0, Location::RequiresRegister());
      summary->set_in(1, RightOperandIsPositive()
                             ? LocationRegisterOrConstant(right())
                             : Location::RequiresRegister());
      summary->set_out(0, Location::RequiresRegister());
      return summary;
    }
    default: {
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
  if ((op_kind() == Token::kSHL) || (op_kind() == Token::kSHR) ||
      (op_kind() == Token::kUSHR)) {
    EmitShiftInt64(compiler);
    return;
  }

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
  const int64_t shift = Integer::Cast(right).Value();
  if (shift < 0) {
    // The compiler sometimes fails to eliminate unreachable code.
    __ Stop("Unreachable shift");
    return;
  }

  switch (op_kind) {
    case Token::kSHR: {
      __ AsrImmediate(out, left,
                      Utils::Minimum<int64_t>(shift, kBitsPerWord - 1));
      break;
    }
    case Token::kUSHR: {
      ASSERT(shift < 64);
      __ LsrImmediate(out, left, shift);
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
    case Token::kUSHR: {
      __ lsrv(out, left, right);
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
  const int64_t shift = Integer::Cast(right).Value();
  if (shift < 0) {
    // The compiler sometimes fails to eliminate unreachable code.
    __ Stop("Unreachable shift");
    return;
  }

  if (shift >= 32) {
    __ LoadImmediate(out, 0);
  } else {
    switch (op_kind) {
      case Token::kSHR:
      case Token::kUSHR:
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
    case Token::kUSHR:
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
    __ tbnz(&throw_error, right, kBitsPerWord - 1);

    switch (instruction()->AsBinaryInt64Op()->op_kind()) {
      case Token::kSHR:
        __ AsrImmediate(out, left, kBitsPerWord - 1);
        break;
      case Token::kUSHR:
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
           compiler::Address(
               THR, compiler::target::Thread::unboxed_runtime_arg_offset()));
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
    // Code for a variable shift amount (or constant that throws).
    Register shift = locs()->in(1).reg();

    // Jump to a slow path if shift is larger than 63 or less than 0.
    ShiftInt64OpSlowPath* slow_path = nullptr;
    if (!IsShiftCountInRange()) {
      slow_path = new (Z) ShiftInt64OpSlowPath(this);
      compiler->AddSlowPathCode(slow_path);
      __ CompareImmediate(shift, kShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out, left, shift);

    if (slow_path != nullptr) {
      __ Bind(slow_path->exit_label());
    }
  }
}

void BinaryUint32OpInstr::EmitShiftUint32(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
  } else {
    // Code for a variable shift amount.
    const Register right = locs()->in(1).reg();

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      // If shift value is > 31, return zero.
      __ CompareImmediate(right, 31, compiler::kFourBytes);
      __ csel(out, out, ZR, UNSIGNED_LESS_EQUAL);
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
      __ mvn_(out, left);
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
  Register out = locs()->out(0).reg();
  Register left = locs()->in(0).reg();
  if (locs()->in(1).IsConstant()) {
    int64_t right;
    const bool ok = compiler::HasIntegerValue(locs()->in(1).constant(), &right);
    RELEASE_ASSERT(ok);
    switch (op_kind()) {
      case Token::kBIT_AND:
        __ AndImmediate(out, left, right, compiler::kFourBytes);
        break;
      case Token::kBIT_OR:
        __ OrImmediate(out, left, right, compiler::kFourBytes);
        break;
      case Token::kBIT_XOR:
        __ XorImmediate(out, left, right, compiler::kFourBytes);
        break;
      case Token::kADD:
        __ AddImmediate(out, left, right, compiler::kFourBytes);
        break;
      case Token::kSUB:
        __ AddImmediate(out, left, -right, compiler::kFourBytes);
        break;
      case Token::kMUL:
        __ MulImmediate(out, left, right, compiler::kFourBytes);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    Register right = locs()->in(1).reg();
    compiler::Operand r = compiler::Operand(right);
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
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    if (out != value) {
      __ mov(out, value);  // For positive values the bits are the same.
    }
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    if (out != value) {
      __ mov(out, value);  // For 31 bit values the bits are the same.
    }
  } else if (from() == kUnboxedInt64) {
    if (to() == kUnboxedInt32) {
      __ sxtw(out, value);  // Signed extension 64->32.
    } else {
      ASSERT(to() == kUnboxedUint32);
      __ uxtw(out, value);  // Unsigned extension 64->32.
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
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
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
  __ ldr(offset_reg, element_address, compiler::kFourBytes);

  // Load code entry point.
  const intptr_t entry_offset = __ CodeSize();
  if (Utils::IsInt(21, -entry_offset)) {
    __ adr(target_address_reg, compiler::Immediate(-entry_offset));
  } else {
    __ adr(target_address_reg, compiler::Immediate(0));
    __ AddImmediate(target_address_reg, -entry_offset);
  }

  __ add(target_address_reg, target_address_reg, compiler::Operand(offset_reg));

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
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, LocationRegisterOrConstant(right()));
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
    EmitCbzTbz(reg, compiler, orig_cond, labels, compiler::kObjectBytes);
    return kInvalidCondition;
  } else {
    return compiler->EmitEqualityRegConstCompare(reg, obj, needs_number_check(),
                                                 source(), deopt_id());
  }
}

void ConditionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitConditionCode(compiler, labels);

  const Register result = this->locs()->out(0).reg();
  if (is_true.IsLinked() || is_false.IsLinked()) {
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
  } else {
    // If EmitConditionCode did not use the labels and just returned
    // a condition we can avoid the branch and use conditional loads.
    ASSERT(true_condition != kInvalidCondition);
    __ LoadObject(TMP, Bool::True());
    __ LoadObject(TMP2, Bool::False());
    __ csel(result, TMP, TMP2, true_condition);
  }
}

void ConditionInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                    BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitConditionCode(compiler, labels);
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
  __ eori(
      result, input,
      compiler::Immediate(compiler::target::ObjectAlignment::kBoolValueMask));
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
  __ BranchLinkPatchable(StubCode::DebugStepCheck());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, source());
  compiler->RecordSafepoint(locs());
#endif
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
