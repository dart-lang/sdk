// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/compiler/backend/il.h"

#include "platform/memory_sanitizer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed location depending on
// the return value (R0, Location::Pair(R0, R1) or Q0).
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
    case kUnboxedInt64:
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
      locs->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
      locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
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
    case kTagged: {
      const auto out = locs()->out(0).reg();
      __ add(out, base_reg(), compiler::Operand(index, LSL, 1));
      __ LoadFromOffset(out, out, offset());
      break;
    }
    case kUnboxedInt64: {
      const auto out_lo = locs()->out(0).AsPairLocation()->At(0).reg();
      const auto out_hi = locs()->out(0).AsPairLocation()->At(1).reg();

      __ add(out_hi, base_reg(), compiler::Operand(index, LSL, 1));
      __ LoadFromOffset(out_lo, out_hi, offset());
      __ LoadFromOffset(out_hi, out_hi, offset() + compiler::target::kWordSize);
      break;
    }
    case kUnboxedDouble: {
      const auto tmp = locs()->temp(0).reg();
      const auto out = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ add(tmp, base_reg(), compiler::Operand(index, LSL, 1));
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
  __ add(TMP, instr->base_reg(), compiler::Operand(index, LSL, 1));
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

// TODO(http://dartbug.com/51229): We can use TMP for LDM/STM, which means we
// only need one additional temporary for 8-byte moves. For 16-byte moves,
// attempting to allocate three temporaries causes too much register pressure,
// so just use two 8-byte sized moves there per iteration.
static constexpr intptr_t kMaxMemoryCopyElementSize =
    2 * compiler::target::kWordSize;

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = element_size_ >= kMaxMemoryCopyElementSize ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::WritableRegister());
  locs->set_in(kDestPos, Location::WritableRegister());
  locs->set_in(kSrcStartPos, LocationRegisterOrConstant(src_start()));
  locs->set_in(kDestStartPos, LocationRegisterOrConstant(dest_start()));
  locs->set_in(kLengthPos,
               LocationWritableRegisterOrSmiConstant(length(), 0, 4));
  for (intptr_t i = 0; i < kNumTemps; i++) {
    locs->set_temp(i, Location::RequiresRegister());
  }
  return locs;
}

void MemoryCopyInstr::EmitUnrolledCopy(FlowGraphCompiler* compiler,
                                       Register dest_reg,
                                       Register src_reg,
                                       intptr_t num_elements,
                                       bool reversed) {
  const intptr_t num_bytes = num_elements * element_size_;
  // The amount moved in a single load/store pair.
  const intptr_t mov_size =
      Utils::Minimum(element_size_, kMaxMemoryCopyElementSize);
  const intptr_t mov_repeat = num_bytes / mov_size;
  ASSERT(num_bytes % mov_size == 0);
  // We can use TMP for all instructions below because element_size_ is
  // guaranteed to fit in the offset portion of the instruction in the
  // non-LDM/STM cases.

  if (mov_size == kMaxMemoryCopyElementSize) {
    RegList temp_regs = (1 << TMP);
    for (intptr_t i = 0; i < locs()->temp_count(); i++) {
      temp_regs |= 1 << locs()->temp(i).reg();
    }
    auto block_mode = BlockAddressMode::IA_W;
    if (reversed) {
      // When reversed, start the src and dest registers with the end addresses
      // and apply the negated offset prior to indexing.
      block_mode = BlockAddressMode::DB_W;
      __ AddImmediate(src_reg, num_bytes);
      __ AddImmediate(dest_reg, num_bytes);
    }
    for (intptr_t i = 0; i < mov_repeat; i++) {
      __ ldm(block_mode, src_reg, temp_regs);
      __ stm(block_mode, dest_reg, temp_regs);
    }
    return;
  }

  for (intptr_t i = 0; i < mov_repeat; i++) {
    const intptr_t byte_index =
        (reversed ? mov_repeat - (i + 1) : i) * mov_size;
    switch (mov_size) {
      case 1:
        __ ldrb(TMP, compiler::Address(src_reg, byte_index));
        __ strb(TMP, compiler::Address(dest_reg, byte_index));
        break;
      case 2:
        __ ldrh(TMP, compiler::Address(src_reg, byte_index));
        __ strh(TMP, compiler::Address(dest_reg, byte_index));
        break;
      case 4:
        __ ldr(TMP, compiler::Address(src_reg, byte_index));
        __ str(TMP, compiler::Address(dest_reg, byte_index));
        break;
      default:
        UNREACHABLE();
    }
  }
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
  auto const mode =
      reversed ? compiler::Address::NegPreIndex : compiler::Address::PostIndex;
  intptr_t tested_bits = 0;

  __ Comment("Copying until region is a multiple of word size");

  for (intptr_t bit = compiler::target::kWordSizeLog2 - 1; bit >= element_shift;
       bit--) {
    const intptr_t bytes = 1 << bit;
    const intptr_t tested_bit = bit + base_shift;
    tested_bits |= (1 << tested_bit);
    __ tst(length_reg, compiler::Operand(1 << tested_bit));
    auto const sz = OperandSizeFor(bytes);
    __ LoadFromOffset(TMP, compiler::Address(src_reg, bytes, mode), sz,
                      NOT_ZERO);
    __ StoreToOffset(TMP, compiler::Address(dest_reg, bytes, mode), sz,
                     NOT_ZERO);
  }

  __ bics(length_reg, length_reg, compiler::Operand(tested_bits));
  __ b(done, ZERO);
}

void MemoryCopyInstr::EmitLoopCopy(FlowGraphCompiler* compiler,
                                   Register dest_reg,
                                   Register src_reg,
                                   Register length_reg,
                                   compiler::Label* done,
                                   compiler::Label* copy_forwards) {
  const bool reversed = copy_forwards != nullptr;
  if (reversed) {
    // Verify that the overlap actually exists by checking to see if
    // dest_start < src_end.
    const intptr_t shift = Utils::ShiftForPowerOfTwo(element_size_) -
                           (unboxed_inputs() ? 0 : kSmiTagShift);
    if (shift < 0) {
      __ add(src_reg, src_reg, compiler::Operand(length_reg, ASR, -shift));
    } else {
      __ add(src_reg, src_reg, compiler::Operand(length_reg, LSL, shift));
    }
    __ CompareRegisters(dest_reg, src_reg);
    // If dest_reg >= src_reg, then set src_reg back to the start of the source
    // region before branching to the forwards-copying loop.
    if (shift < 0) {
      __ sub(src_reg, src_reg, compiler::Operand(length_reg, ASR, -shift),
             UNSIGNED_GREATER_EQUAL);
    } else {
      __ sub(src_reg, src_reg, compiler::Operand(length_reg, LSL, shift),
             UNSIGNED_GREATER_EQUAL);
    }
    __ b(copy_forwards, UNSIGNED_GREATER_EQUAL);
    // There is overlap, so adjust dest_reg now.
    if (shift < 0) {
      __ add(dest_reg, dest_reg, compiler::Operand(length_reg, ASR, -shift));
    } else {
      __ add(dest_reg, dest_reg, compiler::Operand(length_reg, LSL, shift));
    }
  }
  // We can use TMP for all instructions below because element_size_ is
  // guaranteed to fit in the offset portion of the instruction in the
  // non-LDM/STM cases.
  CopyUpToWordMultiple(compiler, dest_reg, src_reg, length_reg, element_size_,
                       unboxed_inputs_, reversed, done);
  // When reversed, the src and dest registers have been adjusted to start at
  // the end addresses, so apply the negated offset prior to indexing.
  const auto load_mode =
      reversed ? compiler::Address::NegPreIndex : compiler::Address::PostIndex;
  const auto load_multiple_mode =
      reversed ? BlockAddressMode::DB_W : BlockAddressMode::IA_W;
  // The size of the uncopied region is a multiple of the word size, so now we
  // copy the rest by word (unless the element size is larger).
  const intptr_t loop_subtract =
      Utils::Maximum<intptr_t>(1, compiler::target::kWordSize / element_size_)
      << (unboxed_inputs_ ? 0 : kSmiTagShift);
  // Used only for LDM/STM below.
  RegList temp_regs = (1 << TMP);
  for (intptr_t i = 0; i < locs()->temp_count(); i++) {
    temp_regs |= 1 << locs()->temp(i).reg();
  }
  __ Comment("Copying by multiples of word size");
  compiler::Label loop;
  __ Bind(&loop);
  switch (element_size_) {
    // Fall through for the sizes smaller than compiler::target::kWordSize.
    case 1:
    case 2:
    case 4:
      __ ldr(TMP, compiler::Address(src_reg, 4, load_mode));
      __ str(TMP, compiler::Address(dest_reg, 4, load_mode));
      break;
    case 8:
      COMPILE_ASSERT(8 == kMaxMemoryCopyElementSize);
      ASSERT_EQUAL(Utils::CountOneBitsWord(temp_regs), 2);
      __ ldm(load_multiple_mode, src_reg, temp_regs);
      __ stm(load_multiple_mode, dest_reg, temp_regs);
      break;
    case 16:
      COMPILE_ASSERT(16 > kMaxMemoryCopyElementSize);
      ASSERT_EQUAL(Utils::CountOneBitsWord(temp_regs), 2);
      __ ldm(load_multiple_mode, src_reg, temp_regs);
      __ stm(load_multiple_mode, dest_reg, temp_regs);
      __ ldm(load_multiple_mode, src_reg, temp_regs);
      __ stm(load_multiple_mode, dest_reg, temp_regs);
      break;
    default:
      UNREACHABLE();
      break;
  }
  __ subs(length_reg, length_reg, compiler::Operand(loop_subtract));
  __ b(&loop, NOT_ZERO);
}

void MemoryCopyInstr::EmitComputeStartPointer(FlowGraphCompiler* compiler,
                                              classid_t array_cid,
                                              Register array_reg,
                                              Location start_loc) {
  intptr_t offset;
  if (IsTypedDataBaseClassId(array_cid)) {
    __ ldr(array_reg,
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
        __ ldr(array_reg,
               compiler::FieldAddress(array_reg,
                                      compiler::target::ExternalOneByteString::
                                          external_data_offset()));
        offset = 0;
        break;
      case kExternalTwoByteStringCid:
        __ ldr(array_reg,
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
  if (shift < 0) {
    __ add(array_reg, array_reg, compiler::Operand(start_reg, ASR, -shift));
  } else {
    __ add(array_reg, array_reg, compiler::Operand(start_reg, LSL, shift));
  }
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
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
  } else {
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

// Buffers registers to use STMDB in order to store
// multiple registers at once.
class ArgumentsMover : public ValueObject {
 public:
  // Flush all buffered registers.
  void Flush(FlowGraphCompiler* compiler) {
    if (pending_regs_ != 0) {
      if (is_single_register_) {
        __ StoreToOffset(
            lowest_register_, SP,
            lowest_register_sp_relative_index_ * compiler::target::kWordSize);
      } else {
        if (lowest_register_sp_relative_index_ == 0) {
          __ stm(IA, SP, pending_regs_);
        } else {
          intptr_t offset =
              lowest_register_sp_relative_index_ * compiler::target::kWordSize;
          for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
            if (((1 << reg) & pending_regs_) != 0) {
              __ StoreToOffset(static_cast<Register>(reg), SP, offset);
              offset += compiler::target::kWordSize;
            }
          }
        }
      }
      pending_regs_ = 0;
      lowest_register_ = kNoRegister;
      is_single_register_ = false;
    }
  }

  // Buffer given register. May push previously buffered registers if needed.
  void MoveRegister(FlowGraphCompiler* compiler,
                    intptr_t sp_relative_index,
                    Register reg) {
    if (pending_regs_ != 0) {
      ASSERT(lowest_register_ != kNoRegister);
      // STMDB pushes higher registers first, so we can only buffer
      // lower registers.
      if (reg < lowest_register_) {
        ASSERT((sp_relative_index + 1) == lowest_register_sp_relative_index_);
        pending_regs_ |= (1 << reg);
        lowest_register_ = reg;
        is_single_register_ = false;
        lowest_register_sp_relative_index_ = sp_relative_index;
        return;
      }
      Flush(compiler);
    }
    pending_regs_ = (1 << reg);
    lowest_register_ = reg;
    is_single_register_ = true;
    lowest_register_sp_relative_index_ = sp_relative_index;
  }

  // Return a register which can be used to hold a value of an argument.
  Register FindFreeRegister(FlowGraphCompiler* compiler,
                            Instruction* move_arg) {
    // Dart calling conventions do not have callee-save registers,
    // so arguments pushing can clobber all allocatable registers
    // except registers used in arguments which were not pushed yet,
    // as well as ParallelMove and inputs of a call instruction.
    intptr_t busy = kReservedCpuRegisters;
    for (Instruction* instr = move_arg;; instr = instr->next()) {
      ASSERT(instr != nullptr);
      if (ParallelMoveInstr* parallel_move = instr->AsParallelMove()) {
        for (intptr_t i = 0, n = parallel_move->NumMoves(); i < n; ++i) {
          const auto src_loc = parallel_move->MoveOperandsAt(i)->src();
          if (src_loc.IsRegister()) {
            busy |= (1 << src_loc.reg());
          } else if (src_loc.IsPairLocation()) {
            busy |= (1 << src_loc.AsPairLocation()->At(0).reg());
            busy |= (1 << src_loc.AsPairLocation()->At(1).reg());
          }
        }
      } else {
        ASSERT(instr->IsMoveArgument() || (instr->ArgumentCount() > 0));
        for (intptr_t i = 0, n = instr->locs()->input_count(); i < n; ++i) {
          const auto in_loc = instr->locs()->in(i);
          if (in_loc.IsRegister()) {
            busy |= (1 << in_loc.reg());
          } else if (in_loc.IsPairLocation()) {
            const auto pair_location = in_loc.AsPairLocation();
            busy |= (1 << pair_location->At(0).reg());
            busy |= (1 << pair_location->At(1).reg());
          }
        }
        if (instr->ArgumentCount() > 0) {
          break;
        }
      }
    }
    if (pending_regs_ != 0) {
      // Find the highest available register which can be pushed along with
      // pending registers.
      Register reg = HighestAvailableRegister(busy, lowest_register_);
      if (reg != kNoRegister) {
        return reg;
      }
      Flush(compiler);
    }
    // At this point there are no pending buffered registers.
    // Use LR as it's the highest free register, it is not allocatable and
    // it is clobbered by the call.
    CLOBBERS_LR({
      static_assert(((1 << LR) & kDartAvailableCpuRegs) == 0,
                    "LR should not be allocatable");
      return LR;
    });
  }

 private:
  RegList pending_regs_ = 0;
  Register lowest_register_ = kNoRegister;
  intptr_t lowest_register_sp_relative_index_ = -1;
  bool is_single_register_ = false;

  Register HighestAvailableRegister(intptr_t busy, Register upper_bound) {
    for (intptr_t i = upper_bound - 1; i >= 0; --i) {
      if ((busy & (1 << i)) == 0) {
        return static_cast<Register>(i);
      }
    }
    return kNoRegister;
  }
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
    if (value.IsRegister()) {
      pusher.MoveRegister(compiler, move_arg->sp_relative_index(), value.reg());
    } else if (value.IsPairLocation()) {
      pusher.MoveRegister(compiler, move_arg->sp_relative_index() + 1,
                          value.AsPairLocation()->At(1).reg());
      pusher.MoveRegister(compiler, move_arg->sp_relative_index(),
                          value.AsPairLocation()->At(0).reg());
    } else if (value.IsFpuRegister()) {
      pusher.Flush(compiler);
      __ StoreDToOffset(
          EvenDRegisterOf(value.fpu_reg()), SP,
          move_arg->sp_relative_index() * compiler::target::kWordSize);
    } else {
      const Register reg = pusher.FindFreeRegister(compiler, move_arg);
      ASSERT(reg != kNoRegister);
      if (value.IsConstant()) {
        __ LoadObject(reg, value.constant());
      } else {
        ASSERT(value.IsStackSlot());
        const intptr_t value_offset = value.ToStackSlotOffset();
        __ LoadFromOffset(reg, value.base_reg(), value_offset);
      }
      pusher.MoveRegister(compiler, move_arg->sp_relative_index(), reg);
    }
  }
  pusher.Flush(compiler);
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
    case kUnboxedInt64:
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
    __ Ret();
    return;
  }

#if defined(DEBUG)
  compiler::Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (compiler::target::frame_layout.first_local_from_fp + 1 -
       compiler->StackSize()) *
      compiler::target::kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ sub(R2, SP, compiler::Operand(FP));
  __ CompareImmediate(R2, fp_sp_dist);
  __ b(&stack_ok, EQ);
  __ bkpt(0);
  __ Bind(&stack_ok);
#endif
  ASSERT(__ constant_pool_allowed());
  __ LeaveDartFrameAndReturn();  // Disallows constant pool use.
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

  // Clear out register.
  __ eor(result, result, compiler::Operand(result));

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

  __ mov(result, compiler::Operand(1), true_condition);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ Lsl(result, result, compiler::Operand(shift + kSmiTagSize));
  } else {
    __ sub(result, result, compiler::Operand(1));
    const int32_t val = compiler::target::ToRawSmi(true_value) -
                        compiler::target::ToRawSmi(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, compiler::target::ToRawSmi(false_value));
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
    __ ldr(R2, compiler::FieldAddress(
                   R0, compiler::target::Closure::entry_point_offset()));
  } else {
    ASSERT(locs()->in(0).reg() == FUNCTION_REG);
    // FUNCTION_REG: Function.
    __ ldr(CODE_REG,
           compiler::FieldAddress(FUNCTION_REG,
                                  compiler::target::Function::code_offset()));
    // Closure functions only have one entry point.
    __ ldr(R2,
           compiler::FieldAddress(
               FUNCTION_REG, compiler::target::Function::entry_point_offset()));
  }

  // ARGS_DESC_REG: Arguments descriptor array.
  // R2: instructions entry point.
  if (!FLAG_precompiled_mode) {
    // R9: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ LoadImmediate(IC_DATA_REG, 0);
  }
  __ blx(R2);
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
      __ LoadImmediate(destination.reg(), pair_index == 0
                                              ? Utils::Low32Bits(v)
                                              : Utils::High32Bits(v));
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
    if (representation() == kUnboxedFloat) {
      __ LoadSImmediate(EvenSRegisterOf(dst), Double::Cast(value_).value());
    } else {
      ASSERT(representation() == kUnboxedDouble);
      ASSERT(tmp != kNoRegister);
      __ LoadDImmediate(dst, Double::Cast(value_).value(), tmp);
    }
  } else if (destination.IsDoubleStackSlot()) {
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0) &&
        TargetCPUFeatures::neon_supported()) {
      __ veorq(QTMP, QTMP, QTMP);
    } else {
      ASSERT(tmp != kNoRegister);
      __ LoadDImmediate(DTMP, Double::Cast(value_).value(), tmp);
    }
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    __ StoreDToOffset(DTMP, destination.base_reg(), dest_offset);
  } else {
    ASSERT(destination.IsStackSlot());
    ASSERT(tmp != kNoRegister);
    const intptr_t dest_offset = destination.ToStackSlotOffset();
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      __ LoadImmediate(
          tmp, pair_index == 0 ? Utils::Low32Bits(v) : Utils::High32Bits(v));
    } else {
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
    ASSERT(representation_ == kUnboxedDouble);
    locs->set_out(0, Location::RequiresFpuRegister());
  }
  if (kNumTemps > 0) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}

void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    const Register scratch =
        locs()->temp_count() == 0 ? kNoRegister : locs()->temp(0).reg();
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
      Utils::NBitMask<intptr_t>(kNumberOfFpuRegisters) &
      ~(Utils::NBitMask<intptr_t>(kAbiPreservedFpuRegCount)
        << kAbiFirstPreservedFpuReg) &
      ~(1 << FpuTMP);

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
  __ tst(AssertBooleanABI::kObjectReg,
         compiler::Operand(compiler::target::ObjectAlignment::kBoolVsNullMask));
  __ b(&done, NOT_ZERO);
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

static bool CanBePairOfImmediateOperands(const dart::Object& constant,
                                         compiler::Operand* low,
                                         compiler::Operand* high) {
  int64_t imm;
  if (!compiler::HasIntegerValue(constant, &imm)) {
    return false;
  }
  return compiler::Operand::CanHold(Utils::Low32Bits(imm), low) &&
         compiler::Operand::CanHold(Utils::High32Bits(imm), high);
}

static bool CanBePairOfImmediateOperands(Value* value,
                                         compiler::Operand* low,
                                         compiler::Operand* high) {
  if (!value->BindsToConstant()) {
    return false;
  }
  return CanBePairOfImmediateOperands(value->BoundConstant(), low, high);
}

LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (is_null_aware()) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, Location::RequiresRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kMintCid) {
    compiler::Operand o;
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (CanBePairOfImmediateOperands(left(), &o, &o)) {
      locs->set_in(0, Location::Constant(left()->definition()->AsConstant()));
      locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
    } else if (CanBePairOfImmediateOperands(right(), &o, &o)) {
      locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      locs->set_in(1, Location::Constant(right()->definition()->AsConstant()));
    } else {
      locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
    }
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
  if (value_is_smi == nullptr) {
    __ mov(value_cid_reg, compiler::Operand(kSmiCid));
  }
  __ tst(value_reg, compiler::Operand(kSmiTagMask));
  if (value_is_smi == nullptr) {
    __ LoadClassId(value_cid_reg, value_reg, NE);
  } else {
    __ b(value_is_smi, EQ);
    __ LoadClassId(value_cid_reg, value_reg);
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

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     LocationSummary* locs,
                                     Token::Kind kind) {
  Location left = locs->in(0);
  Location right = locs->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToIntCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant());
  } else {
    __ cmp(left.reg(), compiler::Operand(right.reg()));
  }
  return true_condition;
}

static Condition EmitWordComparisonOp(FlowGraphCompiler* compiler,
                                      LocationSummary* locs,
                                      Token::Kind kind) {
  Location left = locs->in(0);
  Location right = locs->in(1);
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
  } else {
    __ cmp(left.reg(), compiler::Operand(right.reg()));
  }
  return true_condition;
}

static Condition EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                           LocationSummary* locs,
                                           Token::Kind kind) {
  ASSERT(Token::IsEqualityOperator(kind));
  PairLocation* left_pair;
  compiler::Operand right_lo, right_hi;
  if (locs->in(0).IsConstant()) {
    const bool ok = CanBePairOfImmediateOperands(locs->in(0).constant(),
                                                 &right_lo, &right_hi);
    RELEASE_ASSERT(ok);
    left_pair = locs->in(1).AsPairLocation();
  } else if (locs->in(1).IsConstant()) {
    const bool ok = CanBePairOfImmediateOperands(locs->in(1).constant(),
                                                 &right_lo, &right_hi);
    RELEASE_ASSERT(ok);
    left_pair = locs->in(0).AsPairLocation();
  } else {
    left_pair = locs->in(0).AsPairLocation();
    PairLocation* right_pair = locs->in(1).AsPairLocation();
    right_lo = compiler::Operand(right_pair->At(0).reg());
    right_hi = compiler::Operand(right_pair->At(1).reg());
  }
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  // Compare lower.
  __ cmp(left_lo, right_lo);
  // Compare upper if lower is equal.
  __ cmp(left_hi, right_hi, EQ);
  return TokenKindToIntCondition(kind);
}

static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             LocationSummary* locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  PairLocation* left_pair;
  compiler::Operand right_lo, right_hi;
  Condition true_condition = TokenKindToIntCondition(kind);
  if (locs->in(0).IsConstant()) {
    const bool ok = CanBePairOfImmediateOperands(locs->in(0).constant(),
                                                 &right_lo, &right_hi);
    RELEASE_ASSERT(ok);
    left_pair = locs->in(1).AsPairLocation();
    true_condition = FlipCondition(true_condition);
  } else if (locs->in(1).IsConstant()) {
    const bool ok = CanBePairOfImmediateOperands(locs->in(1).constant(),
                                                 &right_lo, &right_hi);
    RELEASE_ASSERT(ok);
    left_pair = locs->in(0).AsPairLocation();
  } else {
    left_pair = locs->in(0).AsPairLocation();
    PairLocation* right_pair = locs->in(1).AsPairLocation();
    right_lo = compiler::Operand(right_pair->At(0).reg());
    right_hi = compiler::Operand(right_pair->At(1).reg());
  }
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  // 64-bit comparison.
  Condition hi_cond, lo_cond;
  switch (true_condition) {
    case LT:
      hi_cond = LT;
      lo_cond = CC;
      break;
    case GT:
      hi_cond = GT;
      lo_cond = HI;
      break;
    case LE:
      hi_cond = LT;
      lo_cond = LS;
      break;
    case GE:
      hi_cond = GT;
      lo_cond = CS;
      break;
    default:
      UNREACHABLE();
      hi_cond = lo_cond = VS;
  }
  // Compare upper halves first.
  __ cmp(left_hi, right_hi);
  __ b(labels.true_label, hi_cond);
  __ b(labels.false_label, FlipCondition(hi_cond));

  // If higher words are equal, compare lower words.
  __ cmp(left_lo, right_lo);
  return lo_cond;
}

static Condition EmitNullAwareInt64ComparisonOp(FlowGraphCompiler* compiler,
                                                LocationSummary* locs,
                                                Token::Kind kind,
                                                BranchLabels labels) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const Register left = locs->in(0).reg();
  const Register right = locs->in(1).reg();
  const Register temp = locs->temp(0).reg();
  const Condition true_condition = TokenKindToIntCondition(kind);
  compiler::Label* equal_result =
      (true_condition == EQ) ? labels.true_label : labels.false_label;
  compiler::Label* not_equal_result =
      (true_condition == EQ) ? labels.false_label : labels.true_label;

  // Check if operands have the same value. If they don't, then they could
  // be equal only if both of them are Mints with the same value.
  __ cmp(left, compiler::Operand(right));
  __ b(equal_result, EQ);
  __ and_(temp, left, compiler::Operand(right));
  __ BranchIfSmi(temp, not_equal_result);
  __ CompareClassId(left, kMintCid, temp);
  __ b(not_equal_result, NE);
  __ CompareClassId(right, kMintCid, temp);
  __ b(not_equal_result, NE);
  __ LoadFieldFromOffset(temp, left, compiler::target::Mint::value_offset());
  __ LoadFieldFromOffset(TMP, right, compiler::target::Mint::value_offset());
  __ cmp(temp, compiler::Operand(TMP));
  __ LoadFieldFromOffset(
      temp, left,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize,
      compiler::kFourBytes, EQ);
  __ LoadFieldFromOffset(
      TMP, right,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize,
      compiler::kFourBytes, EQ);
  __ cmp(temp, compiler::Operand(TMP), EQ);
  return true_condition;
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
  const QRegister left = locs->in(0).fpu_reg();
  const QRegister right = locs->in(1).fpu_reg();
  const DRegister dleft = EvenDRegisterOf(left);
  const DRegister dright = EvenDRegisterOf(right);

  switch (kind) {
    case Token::kEQ:
      __ vcmpd(dleft, dright);
      __ vmstat();
      return EQ;
    case Token::kNE:
      __ vcmpd(dleft, dright);
      __ vmstat();
      return NE;
    case Token::kLT:
      __ vcmpd(dright, dleft);  // Flip to handle NaN.
      __ vmstat();
      return GT;
    case Token::kGT:
      __ vcmpd(dleft, dright);
      __ vmstat();
      return GT;
    case Token::kLTE:
      __ vcmpd(dright, dleft);  // Flip to handle NaN.
      __ vmstat();
      return GE;
    case Token::kGTE:
      __ vcmpd(dleft, dright);
      __ vmstat();
      return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (is_null_aware()) {
    ASSERT(operation_cid() == kMintCid);
    return EmitNullAwareInt64ComparisonOp(compiler, locs(), kind(), labels);
  }
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind());
  } else if (operation_cid() == kIntegerCid) {
    return EmitWordComparisonOp(compiler, locs(), kind());
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintEqualityOp(compiler, locs(), kind());
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
    ASSERT(compiler::target::IsSmi(right.constant()));
    const int32_t imm = compiler::target::ToRawSmi(right.constant());
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
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids)
          : nullptr;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ tst(val_reg, compiler::Operand(kSmiTagMask));
  __ b(result ? labels.true_label : labels.false_label, EQ);
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
  if (operation_cid() == kMintCid) {
    compiler::Operand o;
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (CanBePairOfImmediateOperands(left(), &o, &o)) {
      locs->set_in(0, Location::Constant(left()->definition()->AsConstant()));
      locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
    } else if (CanBePairOfImmediateOperands(right(), &o, &o)) {
      locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      locs->set_in(1, Location::Constant(right()->definition()->AsConstant()));
    } else {
      locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
    }
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
    return EmitSmiComparisonOp(compiler, locs(), kind());
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintComparisonOp(compiler, locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), labels, kind());
  }
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // Pass a pointer to the first argument in R2.
  __ add(
      R2, SP,
      compiler::Operand((ArgumentCount() - 1) * compiler::target::kWordSize));

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
  __ LoadNativeEntry(R9, &label,
                     link_lazily()
                         ? compiler::ObjectPoolBuilderEntry::kPatchable
                         : compiler::ObjectPoolBuilderEntry::kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(source(), *stub,
                                    UntaggedPcDescriptors::kOther, locs());
  } else {
    // We can never lazy-deopt here because natives are never optimized.
    ASSERT(!compiler->is_optimizing());
    compiler->GenerateNonLazyDeoptableStubCall(
        source(), *stub, UntaggedPcDescriptors::kOther, locs());
  }
  __ LoadFromOffset(result, SP, 0);

  compiler->EmitDropArguments(ArgumentCount());  // Drop the arguments.
}

#define R(r) (1 << r)

LocationSummary* FfiCallInstr::MakeLocationSummary(Zone* zone,
                                                   bool is_optimizing) const {
  return MakeLocationSummaryInternal(
      zone, is_optimizing,
      (R(R0) | R(CallingConventions::kFfiAnyNonAbiRegister) |
       R(CallingConventions::kSecondNonArgumentRegister)));
}

#undef R

void FfiCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register branch = locs()->in(TargetAddressIndex()).reg();

  // The temps are indexed according to their register number.
  const Register temp2 = locs()->temp(0).reg();
  // For regular calls, this holds the FP for rebasing the original locations
  // during EmitParamMoves.
  // For leaf calls, this holds the SP used to restore the pre-aligned SP after
  // the call.
  const Register saved_fp_or_sp = locs()->temp(1).reg();
  const Register temp1 = locs()->temp(2).reg();

  // Ensure these are callee-saved register and are preserved across the call.
  ASSERT(IsCalleeSavedRegister(saved_fp_or_sp));
  // Other temps don't need to be preserved.

  __ mov(saved_fp_or_sp,
         is_leaf_ ? compiler::Operand(SPREG) : compiler::Operand(FPREG));

  if (!is_leaf_) {
    // Make a space to put the return address.
    __ PushImmediate(0);

    // We need to create a dummy "exit frame". It will have a null code object.
    __ LoadObject(CODE_REG, Object::null_object());
    __ set_constant_pool_allowed(false);
    __ EnterDartFrame(0, /*load_pool_pointer=*/false);
  }

  // Reserve space for the arguments that go on the stack (if any), then align.
  __ ReserveAlignedFrameSpace(marshaller_.RequiredStackSpaceInBytes());
#if defined(USING_MEMORY_SANITIZER)
  UNIMPLEMENTED();
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
    __ StoreToOffset(branch, THR, compiler::target::Thread::vm_tag_offset());
#endif

    __ blx(branch);

#if !defined(PRODUCT)
    __ LoadImmediate(temp1, compiler::target::Thread::vm_tag_dart_id());
    __ StoreToOffset(temp1, THR, compiler::target::Thread::vm_tag_offset());
    __ LoadImmediate(temp1, 0);
    __ StoreToOffset(temp1, THR,
                     compiler::target::Thread::top_exit_frame_info_offset());
#endif
  } else {
    // We need to copy the return address up into the dummy stack frame so the
    // stack walker will know which safepoint to use.
    __ mov(temp1, compiler::Operand(PC));
    __ str(temp1, compiler::Address(FPREG, kSavedCallerPcSlotFromFp *
                                               compiler::target::kWordSize));

    // For historical reasons, the PC on ARM points 8 bytes past the current
    // instruction. Therefore we emit the metadata here, 8 bytes
    // (2 instructions) after the original mov.
    compiler->EmitCallsiteMetadata(InstructionSource(), deopt_id(),
                                   UntaggedPcDescriptors::Kind::kOther, locs(),
                                   env());

    // Update information in the thread object and enter a safepoint.
    // Outline state transition. In AOT, for code size. In JIT, because we
    // cannot trust that code will be executable.
    __ ldr(temp1,
           compiler::Address(
               THR, compiler::target::Thread::
                        call_native_through_safepoint_entry_point_offset()));

    // Calls R8 in a safepoint and clobbers R4 and NOTFP.
    ASSERT(branch == R8);
    static_assert((kReservedCpuRegisters & (1 << NOTFP)) != 0,
                  "NOTFP should be a reserved register");
    __ blx(temp1);

    if (marshaller_.IsHandle(compiler::ffi::kResultIndex)) {
      __ Comment("Check Dart_Handle for Error.");
      compiler::Label not_error;
      ASSERT(temp1 != CallingConventions::kReturnReg);
      ASSERT(saved_fp_or_sp != CallingConventions::kReturnReg);
      __ ldr(temp1,
             compiler::Address(CallingConventions::kReturnReg,
                               compiler::target::LocalHandle::ptr_offset()));
      __ BranchIfSmi(temp1, &not_error);
      __ LoadClassId(temp1, temp1);
      __ RangeCheck(temp1, saved_fp_or_sp, kFirstErrorCid, kLastErrorCid,
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
      __ blx(temp1);
#if defined(DEBUG)
      // We should never return with normal controlflow from this.
      __ bkpt(0);
#endif

      __ Bind(&not_error);
    }

    // Restore the global object pool after returning from runtime (old space is
    // moving, so the GOP could have been relocated).
    if (FLAG_precompiled_mode) {
      __ SetupGlobalPoolAndDispatchTable();
    }
  }

  EmitReturnMoves(compiler, temp1, temp2);

  if (is_leaf_) {
    // Restore the pre-aligned SP.
    __ mov(SPREG, compiler::Operand(saved_fp_or_sp));
  } else {
    // Leave dummy exit frame.
    __ LeaveDartFrame();
    __ set_constant_pool_allowed(true);

    // Instead of returning to the "fake" return address, we just pop it.
    __ PopRegister(temp1);
  }
}

// Keep in sync with NativeEntryInstr::EmitNativeCode.
void NativeReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  EmitReturnMoves(compiler);

  __ LeaveDartFrame();

  // The dummy return address is in LR, no need to pop it as on Intel.

  // These can be anything besides the return registers (R0 and R1) and THR
  // (R10).
  const Register vm_tag_reg = R2;
  const Register old_exit_frame_reg = R3;
  const Register old_exit_through_ffi_reg = R4;
  const Register tmp = R5;

  __ Pop(old_exit_frame_reg);
  __ Pop(old_exit_through_ffi_reg);

  // Restore top_resource.
  __ Pop(tmp);
  __ StoreToOffset(tmp, THR, compiler::target::Thread::top_resource_offset());

  __ Pop(vm_tag_reg);

  // The trampoline that called us will enter the safepoint on our behalf.
  __ TransitionGeneratedToNative(vm_tag_reg, old_exit_frame_reg,
                                 old_exit_through_ffi_reg, tmp,
                                 /*enter_safepoint=*/false);

  __ PopNativeCalleeSavedRegisters();

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  // Leave the entry frame.
  RESTORES_LR_FROM_FRAME(__ LeaveFrame(1 << LR | 1 << FP));

  // Leave the dummy frame holding the pushed arguments.
  RESTORES_LR_FROM_FRAME(__ LeaveFrame(1 << LR | 1 << FP));

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
  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));

  // Save the argument registers, in reverse order.
  SaveArguments(compiler);

  // Enter the entry frame. NativeParameterInstr expects this frame has size
  // -exit_link_slot_from_entry_fp, verified below.
  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));

  // Save a space for the code object.
  __ PushImmediate(0);

#if defined(DART_TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

  __ PushNativeCalleeSavedRegisters();

  // Save the current VMTag on the stack.
  __ LoadFromOffset(R0, THR, compiler::target::Thread::vm_tag_offset());
  __ Push(R0);

  // Save top resource.
  const intptr_t top_resource_offset =
      compiler::target::Thread::top_resource_offset();
  __ LoadFromOffset(R0, THR, top_resource_offset);
  __ Push(R0);
  __ LoadImmediate(R0, 0);
  __ StoreToOffset(R0, THR, top_resource_offset);

  __ LoadFromOffset(R0, THR,
                    compiler::target::Thread::exit_through_ffi_offset());
  __ Push(R0);

  // Save top exit frame info. Don't set it to 0 yet,
  // TransitionNativeToGenerated will handle that.
  __ LoadFromOffset(R0, THR,
                    compiler::target::Thread::top_exit_frame_info_offset());
  __ Push(R0);

  __ EmitEntryFrameVerification(R0);

  // The callback trampoline (caller) has already left the safepoint for us.
  __ TransitionNativeToGenerated(/*scratch0=*/R0, /*scratch1=*/R1,
                                 /*exit_safepoint=*/false);

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
  __ LoadFieldFromOffset(R0, R0,
                         compiler::target::GrowableObjectArray::data_offset());
  __ LoadFieldFromOffset(CODE_REG, R0,
                         compiler::target::Array::data_offset() +
                             callback_id * compiler::target::kWordSize);

  // Put the code object in the reserved slot.
  __ StoreToOffset(CODE_REG, FPREG,
                   kPcMarkerSlotFromFp * compiler::target::kWordSize);
  if (FLAG_precompiled_mode) {
    __ SetupGlobalPoolAndDispatchTable();
  } else {
    __ LoadImmediate(PP, 0);  // GC safe value into PP.
  }

  // Load a GC-safe value for the arguments descriptor (unused but tagged).
  __ LoadImmediate(ARGS_DESC_REG, 0);

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

  __ MoveRegister(saved_fp, FPREG);

  const intptr_t frame_space = native_calling_convention_.StackTopInBytes();
  __ EnterCFrame(frame_space);

  EmitParamMoves(compiler, saved_fp, temp0);

  const Register target_address = locs()->in(TargetAddressIndex()).reg();
  __ CallCFunction(target_address);

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

  __ ldr(
      result,
      compiler::Address(
          THR, compiler::target::Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      result, Symbols::kNullCharCodeSymbolOffset * compiler::target::kWordSize);
  __ ldr(result,
         compiler::Address(result, char_code, LSL, 1));  // Char code is a smi.
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
  __ ldr(result, compiler::FieldAddress(
                     str, compiler::target::String::length_offset()));
  __ cmp(result, compiler::Operand(compiler::target::ToRawSmi(1)));
  __ LoadImmediate(result, -1, NE);
  __ ldrb(result,
          compiler::FieldAddress(
              str, compiler::target::OneByteString::data_offset()),
          EQ);
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
  __ LoadFieldFromOffset(bytes_reg, bytes_reg,
                         compiler::target::PointerBase::data_offset());

  // Table.
  __ AddImmediate(
      table_reg, table_reg,
      compiler::target::OneByteString::data_offset() - kHeapObjectTag);

  // Pointers to start and end.
  __ add(bytes_ptr_reg, bytes_reg, compiler::Operand(start_reg));
  __ add(bytes_end_reg, bytes_reg, compiler::Operand(end_reg));

  // Initialize size and flags.
  __ LoadImmediate(size_reg, 0);
  __ LoadImmediate(flags_reg, 0);

  __ b(&loop_in);
  __ Bind(&loop);

  // Read byte and increment pointer.
  __ ldrb(temp_reg,
          compiler::Address(bytes_ptr_reg, 1, compiler::Address::PostIndex));

  // Update size and flags based on byte value.
  __ ldrb(temp_reg, compiler::Address(table_reg, temp_reg));
  __ orr(flags_reg, flags_reg, compiler::Operand(temp_reg));
  __ and_(temp_reg, temp_reg, compiler::Operand(kSizeMask));
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

static bool CanBeImmediateIndex(Value* value,
                                intptr_t cid,
                                bool is_external,
                                bool is_load,
                                bool* needs_base) {
  if ((cid == kTypedDataInt32x4ArrayCid) ||
      (cid == kTypedDataFloat32x4ArrayCid) ||
      (cid == kTypedDataFloat64x2ArrayCid)) {
    // We are using vldmd/vstmd which do not support offset.
    return false;
  }

  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == nullptr) ||
      !compiler::Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = compiler::target::SmiValue(constant->value());
  const intptr_t scale = compiler::target::Instance::ElementSizeFor(cid);
  const intptr_t base_offset =
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset = index * scale + base_offset;
  if (!Utils::MagnitudeIsUint(12, offset)) {
    return false;
  }
  if (compiler::Address::CanHoldImmediateOffset(is_load, cid, offset)) {
    *needs_base = false;
    return true;
  }

  if (compiler::Address::CanHoldImmediateOffset(is_load, cid,
                                                offset - base_offset)) {
    *needs_base = true;
    return true;
  }

  return false;
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const bool directly_addressable =
      aligned() && representation() != kUnboxedInt64;
  const intptr_t kNumInputs = 2;
  intptr_t kNumTemps = 0;

  if (!directly_addressable) {
    kNumTemps += 1;
    if ((representation() == kUnboxedFloat) ||
        (representation() == kUnboxedDouble)) {
      kNumTemps += 1;
    }
  }
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  bool needs_base = false;
  if (CanBeImmediateIndex(index(), class_id(), IsExternal(),
                          true,  // Load.
                          &needs_base)) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    if (class_id() == kTypedDataFloat32ArrayCid) {
      // Need register < Q7 for float operations.
      // TODO(30953): Support register range constraints in the regalloc.
      locs->set_out(0, Location::FpuRegisterLocation(Q6));
    } else {
      locs->set_out(0, Location::RequiresFpuRegister());
    }
  } else if (representation() == kUnboxedInt64) {
    ASSERT(class_id() == kTypedDataInt64ArrayCid ||
           class_id() == kTypedDataUint64ArrayCid);
    locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  } else {
    locs->set_out(0, Location::RequiresRegister());
  }
  if (!directly_addressable) {
    locs->set_temp(0, Location::RequiresRegister());
    if ((representation() == kUnboxedFloat) ||
        (representation() == kUnboxedDouble)) {
      locs->set_temp(1, Location::RequiresRegister());
    }
  }
  return locs;
}

void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const bool directly_addressable =
      aligned() && representation() != kUnboxedInt64;
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register address =
      directly_addressable ? kNoRegister : locs()->temp(0).reg();

  compiler::Address element_address(kNoRegister);
  if (directly_addressable) {
    element_address =
        index.IsRegister()
            ? __ ElementAddressForRegIndex(true,  // Load.
                                           IsExternal(), class_id(),
                                           index_scale(), index_unboxed_, array,
                                           index.reg())
            : __ ElementAddressForIntIndex(
                  true,  // Load.
                  IsExternal(), class_id(), index_scale(), array,
                  compiler::target::SmiValue(index.constant()),
                  IP);  // Temp register.
    // Warning: element_address may use register IP as base.
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(address,
                                       true,  // Load.
                                       IsExternal(), class_id(), index_scale(),
                                       index_unboxed_, array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(
          address,
          true,  // Load.
          IsExternal(), class_id(), index_scale(), array,
          compiler::target::SmiValue(index.constant()));
    }
  }

  if ((representation() == kUnboxedFloat) ||
      (representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    const QRegister result = locs()->out(0).fpu_reg();
    const DRegister dresult0 = EvenDRegisterOf(result);
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        // vldrs does not support indexed addressing.
        if (aligned()) {
          __ vldrs(EvenSRegisterOf(dresult0), element_address);
        } else {
          const Register value = locs()->temp(1).reg();
          __ LoadWordUnaligned(value, address, TMP);
          __ vmovsr(EvenSRegisterOf(dresult0), value);
        }
        break;
      case kTypedDataFloat64ArrayCid:
        // vldrd does not support indexed addressing.
        if (aligned()) {
          __ vldrd(dresult0, element_address);
        } else {
          const Register value = locs()->temp(1).reg();
          __ LoadWordUnaligned(value, address, TMP);
          __ vmovdr(dresult0, 0, value);
          __ AddImmediate(address, address, 4);
          __ LoadWordUnaligned(value, address, TMP);
          __ vmovdr(dresult0, 1, value);
        }
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        ASSERT(element_address.Equals(compiler::Address(IP)));
        ASSERT(aligned());
        __ vldmd(IA, IP, dresult0, 2);
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
      if (aligned()) {
        __ ldr(result, element_address);
      } else {
        __ LoadWordUnaligned(result, address, TMP);
      }
      break;
    }
    case kTypedDataUint32ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedUint32);
      if (aligned()) {
        __ ldr(result, element_address);
      } else {
        __ LoadWordUnaligned(result, address, TMP);
      }
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      ASSERT(representation() == kUnboxedInt64);
      ASSERT(!directly_addressable);  // need to add to register
      ASSERT(locs()->out(0).IsPairLocation());
      PairLocation* result_pair = locs()->out(0).AsPairLocation();
      const Register result_lo = result_pair->At(0).reg();
      const Register result_hi = result_pair->At(1).reg();
      if (aligned()) {
        __ ldr(result_lo, compiler::Address(address));
        __ ldr(result_hi,
               compiler::Address(address, compiler::target::kWordSize));
      } else {
        __ LoadWordUnaligned(result_lo, address, TMP);
        __ AddImmediate(address, address, compiler::target::kWordSize);
        __ LoadWordUnaligned(result_hi, address, TMP);
      }
      break;
    }
    case kTypedDataInt8ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      ASSERT(index_scale() == 1);
      ASSERT(aligned());
      __ ldrsb(result, element_address);
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
      ASSERT(aligned());
      __ ldrb(result, element_address);
      break;
    }
    case kTypedDataInt16ArrayCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      if (aligned()) {
        __ ldrsh(result, element_address);
      } else {
        __ LoadHalfWordUnaligned(result, address, TMP);
      }
      break;
    }
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kUnboxedIntPtr);
      if (aligned()) {
        __ ldrh(result, element_address);
      } else {
        __ LoadHalfWordUnsignedUnaligned(result, address, TMP);
      }
      break;
    }
    default: {
      const Register result = locs()->out(0).reg();
      ASSERT(representation() == kTagged);
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid) ||
             (class_id() == kTypeArgumentsCid) || (class_id() == kRecordCid));
      __ ldr(result, element_address);
      break;
    }
  }
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const bool directly_addressable =
      aligned() && class_id() != kTypedDataInt64ArrayCid &&
      class_id() != kTypedDataUint64ArrayCid && class_id() != kArrayCid;
  const intptr_t kNumInputs = 3;
  LocationSummary* locs;

  bool needs_base = false;
  intptr_t kNumTemps = 0;
  if (CanBeImmediateIndex(index(), class_id(), IsExternal(),
                          false,  // Store.
                          &needs_base)) {
    if (!directly_addressable) {
      kNumTemps += 2;
    } else if (needs_base) {
      kNumTemps += 1;
    }

    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    if (!directly_addressable) {
      kNumTemps += 2;
    }

    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

    locs->set_in(1, Location::WritableRegister());
  }
  locs->set_in(0, Location::RequiresRegister());
  for (intptr_t i = 0; i < kNumTemps; i++) {
    locs->set_temp(i, Location::RequiresRegister());
  }

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
    case kTypedDataUint32ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      locs->set_in(2, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
      break;
    case kTypedDataFloat32ArrayCid:
      // Need low register (< Q7).
      locs->set_in(2, Location::FpuRegisterLocation(Q6));
      break;
    case kTypedDataFloat64ArrayCid:  // TODO(srdjan): Support Float64 constants.
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
  const bool directly_addressable =
      aligned() && class_id() != kTypedDataInt64ArrayCid &&
      class_id() != kTypedDataUint64ArrayCid && class_id() != kArrayCid;
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register temp =
      (locs()->temp_count() > 0) ? locs()->temp(0).reg() : kNoRegister;
  const Register temp2 =
      (locs()->temp_count() > 1) ? locs()->temp(1).reg() : kNoRegister;

  compiler::Address element_address(kNoRegister);
  if (directly_addressable) {
    element_address =
        index.IsRegister()
            ? __ ElementAddressForRegIndex(false,  // Store.
                                           IsExternal(), class_id(),
                                           index_scale(), index_unboxed_, array,
                                           index.reg())
            : __ ElementAddressForIntIndex(
                  false,  // Store.
                  IsExternal(), class_id(), index_scale(), array,
                  compiler::target::SmiValue(index.constant()), temp);
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(temp,
                                       false,  // Store.
                                       IsExternal(), class_id(), index_scale(),
                                       index_unboxed_, array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(
          temp,
          false,  // Store.
          IsExternal(), class_id(), index_scale(), array,
          compiler::target::SmiValue(index.constant()));
    }
  }

  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        const Register value = locs()->in(2).reg();
        __ StoreIntoArray(array, temp, value, CanValueBeSmi());
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreIntoObjectNoBarrier(array, compiler::Address(temp), constant);
      } else {
        const Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, compiler::Address(temp), value);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kOneByteStringCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        __ LoadImmediate(IP,
                         compiler::target::SmiValue(locs()->in(2).constant()));
        __ strb(IP, element_address);
      } else {
        const Register value = locs()->in(2).reg();
        __ strb(value, element_address);
      }
      break;
    }
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      if (locs()->in(2).IsConstant()) {
        intptr_t value = compiler::target::SmiValue(locs()->in(2).constant());
        // Clamp to 0x0 or 0xFF respectively.
        if (value > 0xFF) {
          value = 0xFF;
        } else if (value < 0) {
          value = 0;
        }
        __ LoadImmediate(IP, static_cast<int8_t>(value));
        __ strb(IP, element_address);
      } else {
        const Register value = locs()->in(2).reg();
        // Clamp to 0x00 or 0xFF respectively.
        __ LoadImmediate(IP, 0xFF);
        __ cmp(value,
               compiler::Operand(IP));  // Compare Smi value and smi 0xFF.
        __ mov(IP, compiler::Operand(0), LE);  // IP = value <= 0xFF ? 0 : 0xFF.
        __ mov(IP, compiler::Operand(value),
               LS);  // IP = value in range ? value : IP.
        __ strb(IP, element_address);
      }
      break;
    }
    case kTwoByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      ASSERT(RequiredInputRepresentation(2) == kUnboxedIntPtr);
      const Register value = locs()->in(2).reg();
      if (aligned()) {
        __ strh(value, element_address);
      } else {
        __ StoreHalfWordUnaligned(value, temp, temp2);
      }
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      const Register value = locs()->in(2).reg();
      if (aligned()) {
        __ str(value, element_address);
      } else {
        __ StoreWordUnaligned(value, temp, temp2);
      }
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      ASSERT(!directly_addressable);  // need to add to register
      ASSERT(locs()->in(2).IsPairLocation());
      PairLocation* value_pair = locs()->in(2).AsPairLocation();
      Register value_lo = value_pair->At(0).reg();
      Register value_hi = value_pair->At(1).reg();
      if (aligned()) {
        __ str(value_lo, compiler::Address(temp));
        __ str(value_hi, compiler::Address(temp, compiler::target::kWordSize));
      } else {
        __ StoreWordUnaligned(value_lo, temp, temp2);
        __ AddImmediate(temp, temp, compiler::target::kWordSize);
        __ StoreWordUnaligned(value_hi, temp, temp2);
      }
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      const SRegister value_reg =
          EvenSRegisterOf(EvenDRegisterOf(locs()->in(2).fpu_reg()));
      if (aligned()) {
        __ vstrs(value_reg, element_address);
      } else {
        const Register address = temp;
        const Register value = temp2;
        __ vmovrs(value, value_reg);
        __ StoreWordUnaligned(value, address, TMP);
      }
      break;
    }
    case kTypedDataFloat64ArrayCid: {
      const DRegister value_reg = EvenDRegisterOf(locs()->in(2).fpu_reg());
      if (aligned()) {
        __ vstrd(value_reg, element_address);
      } else {
        const Register address = temp;
        const Register value = temp2;
        __ vmovrs(value, EvenSRegisterOf(value_reg));
        __ StoreWordUnaligned(value, address, TMP);
        __ AddImmediate(address, address, 4);
        __ vmovrs(value, OddSRegisterOf(value_reg));
        __ StoreWordUnaligned(value, address, TMP);
      }
      break;
    }
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid: {
      ASSERT(element_address.Equals(compiler::Address(index.reg())));
      ASSERT(aligned());
      const DRegister value_reg = EvenDRegisterOf(locs()->in(2).fpu_reg());
      __ vstmd(IA, index.reg(), value_reg, 2);
      break;
    }
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
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    compiler::FieldAddress field_cid_operand(
        field_reg, compiler::target::Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        field_reg, compiler::target::Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ ldr(IP, field_cid_operand);
      __ cmp(value_cid_reg, compiler::Operand(IP));
      __ b(&ok, EQ);
      __ ldr(IP, field_nullability_operand);
      __ cmp(value_cid_reg, compiler::Operand(IP));
    } else if (value_cid == kNullCid) {
      __ ldr(value_cid_reg, field_nullability_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      __ ldr(value_cid_reg, field_cid_operand);
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
      __ ldr(IP, field_cid_operand);
      __ CompareImmediate(IP, kIllegalCid);
      __ b(fail, NE);

      if (value_cid == kDynamicCid) {
        __ str(value_cid_reg, field_cid_operand);
        __ str(value_cid_reg, field_nullability_operand);
      } else {
        __ LoadImmediate(IP, value_cid);
        __ str(IP, field_cid_operand);
        __ str(IP, field_nullability_operand);
      }

      __ b(&ok);
    }

    if (deopt == nullptr) {
      __ Bind(fail);

      __ ldr(IP, compiler::FieldAddress(
                     field_reg, compiler::target::Field::guarded_cid_offset()));
      __ CompareImmediate(IP, kDynamicCid);
      __ b(&ok, EQ);

      __ Push(field_reg);
      __ Push(value_reg);
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
      // Field's guarded class id is fixed by value's class id is not known.
      __ tst(value_reg, compiler::Operand(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ b(fail, EQ);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, field_cid);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ b(&ok, EQ);
        if (field_cid != kSmiCid) {
          __ CompareImmediate(value_cid_reg, kNullCid);
        } else {
          __ CompareObject(value_reg, Object::null_object());
        }
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
    // TODO(vegorov): can use TMP when length is small enough to fit into
    // immediate.
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
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

    __ ldrsb(offset_reg,
             compiler::FieldAddress(
                 field_reg, compiler::target::Field::
                                guarded_list_length_in_object_offset_offset()));
    __ ldr(
        length_reg,
        compiler::FieldAddress(
            field_reg, compiler::target::Field::guarded_list_length_offset()));

    __ tst(offset_reg, compiler::Operand(offset_reg));
    __ b(&ok, MI);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ ldr(IP, compiler::Address(value_reg, offset_reg));
    __ cmp(length_reg, compiler::Operand(IP));

    if (deopt == nullptr) {
      __ b(&ok, EQ);

      __ Push(field_reg);
      __ Push(value_reg);
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

    const Register length_reg = locs()->temp(0).reg();

    __ ldr(length_reg,
           compiler::FieldAddress(
               value_reg, field().guarded_list_length_in_object_offset()));
    __ CompareImmediate(
        length_reg, compiler::target::ToRawSmi(field().guarded_list_length()));
    __ b(deopt, NE);
  }
}

DEFINE_UNIMPLEMENTED_INSTRUCTION(GuardFieldTypeInstr)

LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const bool might_box = (representation() == kTagged) && !can_pack_into_smi();
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = might_box ? 2 : 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      might_box ? LocationSummary::kCallOnSlowPath : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());

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

  compiler::Address element_address = __ ElementAddressForRegIndex(
      true, IsExternal(), class_id(), index_scale(), /*index_unboxed=*/false,
      str, index.reg());
  // Warning: element_address may use register IP as base.

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
        __ ldr(result1, element_address);
        __ eor(result2, result2, compiler::Operand(result2));
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        ASSERT(element_count() == 2);
        __ ldr(result1, element_address);
        __ eor(result2, result2, compiler::Operand(result2));
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
            __ ldrb(result, element_address);
            break;
          case 2:
            __ ldrh(result, element_address);
            break;
          case 4:
            __ ldr(result, element_address);
            break;
          default:
            UNREACHABLE();
        }
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        switch (element_count()) {
          case 1:
            __ ldrh(result, element_address);
            break;
          case 2:
            __ ldr(result, element_address);
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
      Register value = locs()->temp(0).reg();
      Register temp = locs()->temp(1).reg();
      // Value register needs to be manually preserved on allocation slow-path.
      locs()->live_registers()->Add(locs()->temp(0), kUnboxedInt32);

      ASSERT(result != value);
      __ MoveRegister(value, result);
      __ SmiTag(result);

      compiler::Label done;
      __ TestImmediate(value, 0xC0000000);
      __ b(&done, EQ);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                      result, temp);
      __ eor(temp, temp, compiler::Operand(temp));
      __ StoreFieldToOffset(value, result,
                            compiler::target::Mint::value_offset());
      __ StoreFieldToOffset(
          temp, result,
          compiler::target::Mint::value_offset() + compiler::target::kWordSize);
      __ Bind(&done);
    }
  }
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
                      R8, R6);
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // R3: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             compiler::target::Array::type_arguments_offset()),
      AllocateArrayABI::kTypeArgumentsReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(
      AllocateArrayABI::kResultReg,
      compiler::FieldAddress(AllocateArrayABI::kResultReg,
                             compiler::target::Array::length_offset()),
      AllocateArrayABI::kLengthReg);

  // Initialize all array elements to raw_null.
  // AllocateArrayABI::kResultReg: new object start as a tagged pointer.
  // R3: new object end address.
  // R6: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R8: null
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(UntaggedArray);
    __ LoadObject(R8, Object::null_object());
    if (num_elements >= 2) {
      __ mov(R9, compiler::Operand(R8));
    } else {
#if defined(DEBUG)
      // Clobber R9 with an invalid pointer.
      __ LoadImmediate(R9, 0x1);
#endif  // DEBUG
    }
    __ AddImmediate(R6, AllocateArrayABI::kResultReg,
                    sizeof(UntaggedArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * compiler::target::kWordSize)) {
      __ InitializeFieldsNoBarrierUnrolled(
          AllocateArrayABI::kResultReg, R6, 0,
          num_elements * compiler::target::kWordSize, R8, R9);
    } else {
      __ InitializeFieldsNoBarrier(AllocateArrayABI::kResultReg, R6, R3, R8,
                                   R9);
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
        compiler::target::IsSmi(num_elements()->BoundConstant())) {
      const intptr_t length =
          compiler::target::SmiValue(num_elements()->BoundConstant());
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
           compiler::FieldAddress(
               result, compiler::target::Context::num_variables_offset()));
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
  locs->set_in(0, Location::RegisterLocation(R4));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R4);
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
      compiler::target::kWordSize;
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
  const intptr_t kNumTemps = 2;
  const bool using_shared_stub = UseSharedSlowPathStub(opt);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      using_shared_stub ? LocationSummary::kCallOnSharedSlowPath
                                        : LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RequiresRegister());
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
      const Register value = instruction()->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(value, Thread::kOsrRequest);
      __ str(value,
             compiler::Address(
                 THR, compiler::target::Thread::stack_overflow_flags_offset()));
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
      const uword entry_point_offset = compiler::target::Thread::
          stack_overflow_shared_stub_entry_point_offset(
              instruction()->locs()->live_registers()->FpuRegisterCount() > 0);
      __ Call(compiler::Address(THR, entry_point_offset));
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
  __ ldr(IP, compiler::Address(THR,
                               compiler::target::Thread::stack_limit_offset()));
  __ cmp(SP, compiler::Operand(IP));

  auto object_store = compiler->isolate_group()->object_store();
  const bool live_fpu_regs = locs()->live_registers()->FpuRegisterCount() > 0;
  const auto& stub = Code::ZoneHandle(
      compiler->zone(),
      live_fpu_regs
          ? object_store->stack_overflow_stub_with_fpu_regs_stub()
          : object_store->stack_overflow_stub_without_fpu_regs_stub());
  const bool using_shared_stub = locs()->call_on_shared_slow_path();
  if (using_shared_stub && compiler->CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeCall(LS);
    compiler->AddPcRelativeCallStubTarget(stub);

    // We use the "extended" environment which has the locations updated to
    // reflect live registers being saved in the shared spilling stubs (see
    // the stub above).
    auto extended_env = compiler->SlowPathEnvironmentFor(this, 0);
    compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                   UntaggedPcDescriptors::kOther, locs(),
                                   extended_env);
    return;
  }

  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register function = locs()->temp(0).reg();
    const Register count = locs()->temp(1).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(function, compiler->parsed_function().function());
    const intptr_t configured_optimization_counter_threshold =
        compiler->thread()->isolate_group()->optimization_counter_threshold();
    const int32_t threshold =
        configured_optimization_counter_threshold * (loop_depth() + 1);
    __ ldr(count,
           compiler::FieldAddress(
               function, compiler::target::Function::usage_counter_offset()));
    __ add(count, count, compiler::Operand(1));
    __ str(count,
           compiler::FieldAddress(
               function, compiler::target::Function::usage_counter_offset()));
    __ CompareImmediate(count, threshold);
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
    ASSERT(compiler::target::IsSmi(constant));
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = compiler::target::SmiValue(constant);
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow (preserve left).
      __ Lsl(IP, left, compiler::Operand(value));
      __ cmp(left, compiler::Operand(IP, ASR, value));
      __ b(deopt, NE);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ Lsl(result, left, compiler::Operand(value));
    return;
  }

  // Right (locs.in(1)) is not constant.
  const Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (compiler::target::IsSmi(obj)) {
      const intptr_t left_int = compiler::target::SmiValue(obj);
      if (left_int == 0) {
        __ cmp(right, compiler::Operand(0));
        __ b(deopt, MI);
        __ mov(result, compiler::Operand(0));
        return;
      }
      const intptr_t max_right =
          compiler::target::kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ cmp(right, compiler::Operand(compiler::target::ToRawSmi(max_right)));
        __ b(deopt, CS);
      }
      __ SmiUntag(IP, right);
      __ Lsl(result, left, IP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (compiler::target::kSmiBits - 1));
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmp(right, compiler::Operand(0));
        __ b(deopt, MI);
      }

      __ cmp(right, compiler::Operand(compiler::target::ToRawSmi(
                        compiler::target::kSmiBits)));
      __ mov(result, compiler::Operand(0), CS);
      __ SmiUntag(IP, right, CC);  // SmiUntag right into IP if CC.
      __ Lsl(result, left, IP, CC);
    } else {
      __ SmiUntag(IP, right);
      __ Lsl(result, left, IP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ cmp(right, compiler::Operand(compiler::target::ToRawSmi(
                        compiler::target::kSmiBits)));
      __ b(deopt, CS);
    }
    // Left is not a constant.
    // Check if count too large for handling it inlined.
    __ SmiUntag(IP, right);
    // Overflow test (preserve left, right, and IP);
    const Register temp = locs.temp(0).reg();
    __ Lsl(temp, left, IP);
    __ cmp(left, compiler::Operand(temp, ASR, IP));
    __ b(deopt, NE);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ Lsl(result, left, IP);
  }
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  // Calculate number of temporaries.
  intptr_t num_temps = 0;
  if (op_kind() == Token::kTRUNCDIV) {
    if (RightIsPowerOfTwoConstant()) {
      num_temps = 1;
    } else {
      num_temps = 2;
    }
  } else if (op_kind() == Token::kMOD) {
    num_temps = 2;
  } else if (((op_kind() == Token::kSHL) && can_overflow()) ||
             (op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR)) {
    num_temps = 1;
  }
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant));
      summary->set_temp(0, Location::RequiresRegister());
    } else {
      summary->set_in(1, Location::RequiresRegister());
      summary->set_temp(0, Location::RequiresRegister());
      // Request register that overlaps with S0..S31.
      summary->set_temp(1, Location::FpuRegisterLocation(Q0));
    }
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  if (op_kind() == Token::kMOD) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    // Request register that overlaps with S0..S31.
    summary->set_temp(1, Location::FpuRegisterLocation(Q0));
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
    ASSERT(compiler::target::IsSmi(constant));
    const int32_t imm = compiler::target::ToRawSmi(constant);
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, imm);
        } else {
          __ AddImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, -imm);
        } else {
          // Negating imm and using AddImmediateSetFlags would not detect the
          // overflow when imm == kMinInt32.
          __ SubImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = compiler::target::SmiValue(constant);
        if (deopt == nullptr) {
          __ LoadImmediate(IP, value);
          __ mul(result, left, IP);
        } else {
          __ LoadImmediate(IP, value);
          __ smull(result, IP, left, IP);
          // IP: result bits 32..63.
          __ cmp(IP, compiler::Operand(result, ASR, 31));
          __ b(deopt, NE);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = compiler::target::SmiValue(constant);
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ mov(IP, compiler::Operand(left, ASR, 31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = locs()->temp(0).reg();
        __ add(temp, left, compiler::Operand(IP, LSR, 32 - shift_count));
        ASSERT(shift_count > 0);
        __ mov(result, compiler::Operand(temp, ASR, shift_count));
        if (value < 0) {
          __ rsb(result, result, compiler::Operand(0));
        }
        __ SmiTag(result);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(imm, &o)) {
          __ and_(result, left, o);
        } else if (compiler::Operand::CanHold(~imm, &o)) {
          __ bic(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ and_(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(imm, &o)) {
          __ orr(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ orr(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(imm, &o)) {
          __ eor(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ eor(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        intptr_t value = compiler::target::SmiValue(constant);
        __ Asr(result, left,
               compiler::Operand(
                   Utils::Minimum(value + kSmiTagSize, kCountLimit)));
        __ SmiTag(result);
        break;
      }
      case Token::kUSHR: {
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
            __ CompareImmediate(left, 0);
            __ b(deopt, LT);
          } else {
            // Operation cannot overflow only if left value is always
            // non-negative.
            ASSERT(!can_overflow());
          }
          // At this point left operand is non-negative, so unsigned shift
          // can't overflow.
          if (value >= compiler::target::kSmiBits) {
            __ LoadImmediate(result, 0);
          } else {
            __ Lsr(result, left, compiler::Operand(value + kSmiTagSize));
            __ SmiTag(result);
          }
        } else {
          // Shift amount > 32, and the result is guaranteed to fit into Smi.
          // Low (Smi) part of the left operand is shifted out.
          // High part is filled with sign bits.
          __ Asr(result, left, compiler::Operand(31));
          __ Lsr(result, result, compiler::Operand(value - 32));
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
        __ add(result, left, compiler::Operand(right));
      } else {
        __ adds(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == nullptr) {
        __ sub(result, left, compiler::Operand(right));
      } else {
        __ subs(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(IP, left);
      if (deopt == nullptr) {
        __ mul(result, IP, right);
      } else {
        __ smull(result, IP, IP, right);
        // IP: result bits 32..63.
        __ cmp(IP, compiler::Operand(result, ASR, 31));
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
        __ cmp(right, compiler::Operand(0));
        __ b(deopt, EQ);
      }
      const Register temp = locs()->temp(0).reg();
      const DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
      __ SmiUntag(temp, left);
      __ SmiUntag(IP, right);
      __ IntegerDivide(result, temp, IP, dtemp, DTMP);

      if (RangeUtils::Overlaps(right_range(), -1, -1)) {
        // Check the corner case of dividing the 'MIN_SMI' with -1, in which
        // case we cannot tag the result.
        __ CompareImmediate(result, 0x40000000);
        __ b(deopt, EQ);
      }
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ cmp(right, compiler::Operand(0));
        __ b(deopt, EQ);
      }
      const Register temp = locs()->temp(0).reg();
      const DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
      __ SmiUntag(temp, left);
      __ SmiUntag(IP, right);
      __ IntegerDivide(result, temp, IP, dtemp, DTMP);
      __ SmiUntag(IP, right);
      __ mls(result, IP, result, temp);  // result <- left - right * result
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
      __ cmp(result, compiler::Operand(0));
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ cmp(right, compiler::Operand(0));
      __ sub(result, result, compiler::Operand(right), LT);
      __ add(result, result, compiler::Operand(right), GE);
      __ Bind(&done);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, 0);
        __ b(deopt, LT);
      }
      __ SmiUntag(IP, right);
      // sarl operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ CompareImmediate(IP, kCountLimit);
        __ LoadImmediate(IP, kCountLimit, GT);
      }
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ Asr(result, temp, IP);
      __ SmiTag(result);
      break;
    }
    case Token::kUSHR: {
      compiler::Label done;
      __ SmiUntag(IP, right);
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
          __ CompareImmediate(IP, kBitsPerInt64);
          // If shift amount >= 64, then result is 0.
          __ LoadImmediate(result, 0, GE);
          __ b(&done, GE);
        }
        __ CompareImmediate(IP, 64 - compiler::target::kSmiBits);
        // Shift amount >= 64 - kSmiBits > 32, but < 64.
        // Result is guaranteed to fit into Smi range.
        // Low (Smi) part of the left operand is shifted out.
        // High part is filled with sign bits.
        __ sub(IP, IP, compiler::Operand(32), GE);
        __ Asr(result, left, compiler::Operand(31), GE);
        __ Lsr(result, result, IP, GE);
        __ SmiTag(result, GE);
        __ b(&done, GE);
      }
      // Shift amount < 64 - kSmiBits.
      // If left is negative, then result will not fit into Smi range.
      // Also deopt in case of negative shift amount.
      if (deopt != nullptr) {
        __ tst(left, compiler::Operand(left));
        __ tst(right, compiler::Operand(right), PL);
        __ b(deopt, MI);
      } else {
        ASSERT(!can_overflow());
      }
      // At this point left operand is non-negative, so unsigned shift
      // can't overflow.
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(),
                                             compiler::target::kSmiBits - 1)) {
        __ CompareImmediate(IP, compiler::target::kSmiBits);
        // Left operand >= 0, shift amount >= kSmiBits. Result is 0.
        __ LoadImmediate(result, 0, GE);
        __ b(&done, GE);
      }
      // Left operand >= 0, shift amount < kSmiBits < 32.
      const Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ Lsr(result, temp, IP);
      __ SmiTag(result);
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
  if (shift_left->can_overflow()) {
    // Check for overflow (preserve left).
    __ Lsl(IP, left, compiler::Operand(value));
    __ cmp(left, compiler::Operand(IP, ASR, value));
    __ b(deopt, NE);  // Overflow.
  }
  // Shift for result now we know there is no overflow.
  __ Lsl(result, left, compiler::Operand(value));
}

LocationSummary* BinaryInt32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  // Calculate number of temporaries.
  intptr_t num_temps = 0;
  if (((op_kind() == Token::kSHL) && can_overflow()) ||
      (op_kind() == Token::kSHR) || (op_kind() == Token::kUSHR)) {
    num_temps = 1;
  }
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
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
          __ AddImmediateSetFlags(result, left, value);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == nullptr) {
          __ AddImmediate(result, left, -value);
        } else {
          // Negating value and using AddImmediateSetFlags would not detect the
          // overflow when value == kMinInt32.
          __ SubImmediateSetFlags(result, left, value);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        if (deopt == nullptr) {
          __ LoadImmediate(IP, value);
          __ mul(result, left, IP);
        } else {
          __ LoadImmediate(IP, value);
          __ smull(result, IP, left, IP);
          // IP: result bits 32..63.
          __ cmp(IP, compiler::Operand(result, ASR, 31));
          __ b(deopt, NE);
        }
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(value, &o)) {
          __ and_(result, left, o);
        } else if (compiler::Operand::CanHold(~value, &o)) {
          __ bic(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ and_(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(value, &o)) {
          __ orr(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ orr(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        compiler::Operand o;
        if (compiler::Operand::CanHold(value, &o)) {
          __ eor(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ eor(result, left, compiler::Operand(IP));
        }
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ Asr(result, left,
               compiler::Operand(Utils::Minimum(value, kCountLimit)));
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
            __ tst(left, compiler::Operand(left));
            __ b(deopt, MI);
          } else {
            // Operation cannot overflow only if left value is always
            // non-negative.
            ASSERT(!can_overflow());
          }
          // At this point left operand is non-negative, so unsigned shift
          // can't overflow.
          if (value == 32) {
            __ LoadImmediate(result, 0);
          } else {
            __ Lsr(result, left, compiler::Operand(value));
          }
        } else {
          // Shift amount > 32.
          // Low (Int32) part of the left operand is shifted out.
          // Shift high part which is filled with sign bits.
          __ Asr(result, left, compiler::Operand(31));
          __ Lsr(result, result, compiler::Operand(value - 32));
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
        __ add(result, left, compiler::Operand(right));
      } else {
        __ adds(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == nullptr) {
        __ sub(result, left, compiler::Operand(right));
      } else {
        __ subs(result, left, compiler::Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      if (deopt == nullptr) {
        __ mul(result, left, right);
      } else {
        __ smull(result, IP, left, right);
        // IP: result bits 32..63.
        __ cmp(IP, compiler::Operand(result, ASR, 31));
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
    __ tst(left, compiler::Operand(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tst(right, compiler::Operand(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tst(left, compiler::Operand(kSmiTagMask));
  } else {
    __ orr(IP, left, compiler::Operand(right));
    __ tst(IP, compiler::Operand(kSmiTagMask));
  }
  __ b(deopt, EQ);
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
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, locs()->temp(0).reg());

  switch (from_representation()) {
    case kUnboxedDouble:
      __ StoreDToOffset(value, out_reg, ValueOffset() - kHeapObjectTag);
      break;
    case kUnboxedFloat:
      __ vcvtds(DTMP, EvenSRegisterOf(value));
      __ StoreDToOffset(EvenDRegisterOf(FpuTMP), out_reg,
                        ValueOffset() - kHeapObjectTag);
      break;
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      __ StoreMultipleDToOffset(value, 2, out_reg,
                                ValueOffset() - kHeapObjectTag);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  ASSERT(BoxCid() != kSmiCid);
  const bool needs_temp = CanDeoptimize();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (needs_temp) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else if (representation() == kUnboxedInt32) {
    summary->set_out(0, Location::RequiresRegister());
  } else if (representation() == kUnboxedFloat) {
    // Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
    // TODO(30953): Support register range constraints in the regalloc.
    summary->set_out(0, Location::FpuRegisterLocation(Q6));
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
      __ LoadFieldFromOffset(result->At(0).reg(), box, ValueOffset());
      __ LoadFieldFromOffset(result->At(1).reg(), box,
                             ValueOffset() + compiler::target::kWordSize);
      break;
    }

    case kUnboxedDouble: {
      const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ LoadDFromOffset(result, box, ValueOffset() - kHeapObjectTag);
      break;
    }

    case kUnboxedFloat: {
      // Should only be <= Q7, because >= Q8 cannot be addressed as S register.
      const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ LoadDFromOffset(result, box, ValueOffset() - kHeapObjectTag);
      __ vcvtsd(EvenSRegisterOf(result), result);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ LoadMultipleDFromOffset(result, 2, box,
                                 ValueOffset() - kHeapObjectTag);
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
      __ SmiUntag(result->At(0).reg(), box);
      __ SignFill(result->At(1).reg(), result->At(0).reg());
      break;
    }

    case kUnboxedDouble: {
      const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ SmiUntag(IP, box);
      __ vmovdr(DTMP, 0, IP);
      __ vcvtdi(result, STMP);
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
  const Register box = locs()->in(0).reg();
  PairLocation* result = locs()->out(0).AsPairLocation();
  ASSERT(result->At(0).reg() != box);
  ASSERT(result->At(1).reg() != box);
  compiler::Label done;
  __ SignFill(result->At(1).reg(), box);
  __ SmiUntag(result->At(0).reg(), box, &done);
  EmitLoadFromBox(compiler);
  __ Bind(&done);
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      ValueFitsSmi() ? LocationSummary::kNoCall
                                     : LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  if (!ValueFitsSmi()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

  __ SmiTag(out, value);
  if (!ValueFitsSmi()) {
    Register temp = locs()->temp(0).reg();
    compiler::Label done;
    if (from_representation() == kUnboxedInt32) {
      __ cmp(value, compiler::Operand(out, ASR, 1));
    } else {
      ASSERT(from_representation() == kUnboxedUint32);
      // Note: better to test upper bits instead of comparing with
      // kSmiMax as kSmiMax does not fit into immediate operand.
      __ TestImmediate(value, 0xC0000000);
    }
    __ b(&done, EQ);
    BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                    temp);
    if (from_representation() == kUnboxedInt32) {
      __ Asr(temp, value,
             compiler::Operand(compiler::target::kBitsPerWord - 1));
    } else {
      ASSERT(from_representation() == kUnboxedUint32);
      __ eor(temp, temp, compiler::Operand(temp));
    }
    __ StoreFieldToOffset(value, out, compiler::target::Mint::value_offset());
    __ StoreFieldToOffset(
        temp, out,
        compiler::target::Mint::value_offset() + compiler::target::kWordSize);
    __ Bind(&done);
  }
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
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
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
  Register tmp = locs()->temp(0).reg();
  Register out_reg = locs()->out(0).reg();

  compiler::Label done;
  __ SmiTag(out_reg, value_lo);
  __ cmp(value_lo, compiler::Operand(out_reg, ASR, kSmiTagSize));
  __ cmp(value_hi, compiler::Operand(out_reg, ASR, 31), EQ);
  __ b(&done, EQ);

  if (compiler->intrinsic_mode()) {
    __ TryAllocate(compiler->mint_class(),
                   compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kNearJump, out_reg, tmp);
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
                                    out_reg, tmp);
  }

  __ StoreFieldToOffset(value_lo, out_reg,
                        compiler::target::Mint::value_offset());
  __ StoreFieldToOffset(
      value_hi, out_reg,
      compiler::target::Mint::value_offset() + compiler::target::kWordSize);
  __ Bind(&done);
}

static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register mint,
                              Register result,
                              Register temp,
                              compiler::Label* deopt) {
  __ LoadFieldFromOffset(result, mint, compiler::target::Mint::value_offset());
  if (deopt != nullptr) {
    __ LoadFieldFromOffset(
        temp, mint,
        compiler::target::Mint::value_offset() + compiler::target::kWordSize);
    __ cmp(temp,
           compiler::Operand(result, ASR, compiler::target::kBitsPerWord - 1));
    __ b(deopt, NE);
  }
}

LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  ASSERT((representation() == kUnboxedInt32) ||
         (representation() == kUnboxedUint32));
  ASSERT((representation() != kUnboxedUint32) || is_truncating());
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = CanDeoptimize() ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  const Register temp = CanDeoptimize() ? locs()->temp(0).reg() : kNoRegister;
  compiler::Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : nullptr;
  compiler::Label* out_of_range = !is_truncating() ? deopt : nullptr;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    LoadInt32FromMint(compiler, value, out, temp, out_of_range);
  } else if (!CanDeoptimize()) {
    compiler::Label done;
    __ SmiUntag(out, value, &done);
    LoadInt32FromMint(compiler, value, out, kNoRegister, nullptr);
    __ Bind(&done);
  } else {
    compiler::Label done;
    __ SmiUntag(out, value, &done);
    __ CompareClassId(value, kMintCid, temp);
    __ b(deopt, NE);
    LoadInt32FromMint(compiler, value, out, temp, out_of_range);
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
  const DRegister left = EvenDRegisterOf(locs()->in(0).fpu_reg());
  const DRegister right = EvenDRegisterOf(locs()->in(1).fpu_reg());
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  switch (op_kind()) {
    case Token::kADD:
      __ vaddd(result, left, right);
      break;
    case Token::kSUB:
      __ vsubd(result, left, right);
      break;
    case Token::kMUL:
      __ vmuld(result, left, right);
      break;
    case Token::kDIV:
      __ vdivd(result, left, right);
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
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  const bool is_negated = kind() != Token::kEQ;
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    __ vcmpd(value, value);
    __ vmstat();
    return is_negated ? VC : VS;
  } else {
    ASSERT(op_kind() == MethodRecognizer::kDouble_getIsInfinite);
    const Register temp = locs()->temp(0).reg();
    compiler::Label done;
    // TMP <- value[0:31], result <- value[32:63]
    __ vmovrrd(TMP, temp, value);
    __ cmp(TMP, compiler::Operand(0));
    __ b(is_negated ? labels.true_label : labels.false_label, NE);

    // Mask off the sign bit.
    __ AndImmediate(temp, temp, 0x7FFFFFFF);
    // Compare with +infinity.
    __ CompareImmediate(temp, 0x7FF00000);
    return is_negated ? NE : EQ;
  }
}

// SIMD

#define DEFINE_EMIT(Name, Args)                                                \
  static void Emit##Name(FlowGraphCompiler* compiler, SimdOpInstr* instr,      \
                         PP_APPLY(PP_UNPACK, Args))

DEFINE_EMIT(Simd32x4BinaryOp,
            (QRegister result, QRegister left, QRegister right)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4Add:
      __ vaddqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Sub:
      __ vsubqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Mul:
      __ vmulqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Div:
      __ Vdivqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Equal:
      __ vceqqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4NotEqual:
      __ vceqqs(result, left, right);
      // Invert the result.
      __ vmvnq(result, result);
      break;
    case SimdOpInstr::kFloat32x4GreaterThan:
      __ vcgtqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4GreaterThanOrEqual:
      __ vcgeqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4LessThan:
      __ vcgtqs(result, right, left);
      break;
    case SimdOpInstr::kFloat32x4LessThanOrEqual:
      __ vcgeqs(result, right, left);
      break;
    case SimdOpInstr::kFloat32x4Min:
      __ vminqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Max:
      __ vmaxqs(result, left, right);
      break;
    case SimdOpInstr::kFloat32x4Scale:
      __ vcvtsd(STMP, EvenDRegisterOf(left));
      __ vdup(compiler::kFourBytes, result, DTMP, 0);
      __ vmulqs(result, result, right);
      break;
    case SimdOpInstr::kInt32x4BitAnd:
      __ vandq(result, left, right);
      break;
    case SimdOpInstr::kInt32x4BitOr:
      __ vorrq(result, left, right);
      break;
    case SimdOpInstr::kInt32x4BitXor:
      __ veorq(result, left, right);
      break;
    case SimdOpInstr::kInt32x4Add:
      __ vaddqi(compiler::kFourBytes, result, left, right);
      break;
    case SimdOpInstr::kInt32x4Sub:
      __ vsubqi(compiler::kFourBytes, result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Float64x2BinaryOp,
            (QRegisterView result, QRegisterView left, QRegisterView right)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat64x2Add:
      __ vaddd(result.d(0), left.d(0), right.d(0));
      __ vaddd(result.d(1), left.d(1), right.d(1));
      break;
    case SimdOpInstr::kFloat64x2Sub:
      __ vsubd(result.d(0), left.d(0), right.d(0));
      __ vsubd(result.d(1), left.d(1), right.d(1));
      break;
    case SimdOpInstr::kFloat64x2Mul:
      __ vmuld(result.d(0), left.d(0), right.d(0));
      __ vmuld(result.d(1), left.d(1), right.d(1));
      break;
    case SimdOpInstr::kFloat64x2Div:
      __ vdivd(result.d(0), left.d(0), right.d(0));
      __ vdivd(result.d(1), left.d(1), right.d(1));
      break;
    default:
      UNREACHABLE();
  }
}

// Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Simd32x4Shuffle,
            (FixedQRegisterView<Q6> result, FixedQRegisterView<Q5> value)) {
  // For some cases the vdup instruction requires fewer
  // instructions. For arbitrary shuffles, use vtbl.

  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4GetX:
      __ vcvtds(result.d(0), value.s(0));
      break;
    case SimdOpInstr::kFloat32x4GetY:
      __ vcvtds(result.d(0), value.s(1));
      break;
    case SimdOpInstr::kFloat32x4GetZ:
      __ vcvtds(result.d(0), value.s(2));
      break;
    case SimdOpInstr::kFloat32x4GetW:
      __ vcvtds(result.d(0), value.s(3));
      break;
    case SimdOpInstr::kInt32x4Shuffle:
    case SimdOpInstr::kFloat32x4Shuffle: {
      if (instr->mask() == 0x00) {
        __ vdup(compiler::kFourBytes, result, value.d(0), 0);
      } else if (instr->mask() == 0x55) {
        __ vdup(compiler::kFourBytes, result, value.d(0), 1);
      } else if (instr->mask() == 0xAA) {
        __ vdup(compiler::kFourBytes, result, value.d(1), 0);
      } else if (instr->mask() == 0xFF) {
        __ vdup(compiler::kFourBytes, result, value.d(1), 1);
      } else {
        // TODO(zra): Investigate better instruction sequences for other
        // shuffle masks.
        QRegisterView temp(QTMP);

        __ vmovq(temp, value);
        for (intptr_t i = 0; i < 4; i++) {
          __ vmovs(result.s(i), temp.s((instr->mask() >> (2 * i)) & 0x3));
        }
      }
      break;
    }
    default:
      UNREACHABLE();
  }
}

// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Simd32x4ShuffleMix,
            (FixedQRegisterView<Q6> result,
             FixedQRegisterView<Q4> left,
             FixedQRegisterView<Q5> right)) {
  // TODO(zra): Investigate better instruction sequences for shuffle masks.
  __ vmovs(result.s(0), left.s((instr->mask() >> 0) & 0x3));
  __ vmovs(result.s(1), left.s((instr->mask() >> 2) & 0x3));
  __ vmovs(result.s(2), right.s((instr->mask() >> 4) & 0x3));
  __ vmovs(result.s(3), right.s((instr->mask() >> 6) & 0x3));
}

// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Simd32x4GetSignMask,
            (Register out, FixedQRegisterView<Q5> value, Temp<Register> temp)) {
  // X lane.
  __ vmovrs(out, value.s(0));
  __ Lsr(out, out, compiler::Operand(31));
  // Y lane.
  __ vmovrs(temp, value.s(1));
  __ Lsr(temp, temp, compiler::Operand(31));
  __ orr(out, out, compiler::Operand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, value.s(2));
  __ Lsr(temp, temp, compiler::Operand(31));
  __ orr(out, out, compiler::Operand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, value.s(3));
  __ Lsr(temp, temp, compiler::Operand(31));
  __ orr(out, out, compiler::Operand(temp, LSL, 3));
}

// Low (< 7) Q registers are needed for the vcvtsd instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float32x4FromDoubles,
            (FixedQRegisterView<Q6> out,
             QRegisterView q0,
             QRegisterView q1,
             QRegisterView q2,
             QRegisterView q3)) {
  __ vcvtsd(out.s(0), q0.d(0));
  __ vcvtsd(out.s(1), q1.d(0));
  __ vcvtsd(out.s(2), q2.d(0));
  __ vcvtsd(out.s(3), q3.d(0));
}

DEFINE_EMIT(Float32x4Zero, (QRegister out)) {
  __ veorq(out, out, out);
}

DEFINE_EMIT(Float32x4Splat, (QRegister result, QRegisterView value)) {
  // Convert to Float32.
  __ vcvtsd(STMP, value.d(0));

  // Splat across all lanes.
  __ vdup(compiler::kFourBytes, result, DTMP, 0);
}

DEFINE_EMIT(Float32x4Sqrt,
            (QRegister result, QRegister left, Temp<QRegister> temp)) {
  __ Vsqrtqs(result, left, temp);
}

DEFINE_EMIT(Float32x4Unary, (QRegister result, QRegister left)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4Negate:
      __ vnegqs(result, left);
      break;
    case SimdOpInstr::kFloat32x4Abs:
      __ vabsqs(result, left);
      break;
    case SimdOpInstr::kFloat32x4Reciprocal:
      __ Vreciprocalqs(result, left);
      break;
    case SimdOpInstr::kFloat32x4ReciprocalSqrt:
      __ VreciprocalSqrtqs(result, left);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Simd32x4ToSimd32x4Conversion, (SameAsFirstInput, QRegister left)) {
  // TODO(dartbug.com/30949) these operations are essentially nop and should
  // not generate any code. They should be removed from the graph before
  // code generation.
}

DEFINE_EMIT(
    Float32x4Clamp,
    (QRegister result, QRegister left, QRegister lower, QRegister upper)) {
  __ vminqs(result, left, upper);
  __ vmaxqs(result, result, lower);
}

DEFINE_EMIT(Float64x2Clamp,
            (QRegisterView result,
             QRegisterView left,
             QRegisterView lower,
             QRegisterView upper)) {
  compiler::Label done0, done1;
  // result = max(min(left, upper), lower) |
  //          lower if (upper is NaN || left is NaN) |
  //          upper if lower is NaN
  __ vcmpd(left.d(0), upper.d(0));
  __ vmstat();
  __ vmovd(result.d(0), upper.d(0), GE);
  __ vmovd(result.d(0), left.d(0), LT);  // less than or unordered(NaN)
  __ b(&done0, VS);                      // at least one argument was NaN
  __ vcmpd(result.d(0), lower.d(0));
  __ vmstat();
  __ vmovd(result.d(0), lower.d(0), LE);
  __ Bind(&done0);

  __ vcmpd(left.d(1), upper.d(1));
  __ vmstat();
  __ vmovd(result.d(1), upper.d(1), GE);
  __ vmovd(result.d(1), left.d(1), LT);  // less than or unordered(NaN)
  __ b(&done1, VS);                      // at least one argument was NaN
  __ vcmpd(result.d(1), lower.d(1));
  __ vmstat();
  __ vmovd(result.d(1), lower.d(1), LE);
  __ Bind(&done1);
}

// Low (< 7) Q registers are needed for the vmovs instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float32x4With,
            (FixedQRegisterView<Q6> result,
             QRegisterView replacement,
             QRegister value)) {
  __ vcvtsd(STMP, replacement.d(0));
  __ vmovq(result, value);
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4WithX:
      __ vmovs(result.s(0), STMP);
      break;
    case SimdOpInstr::kFloat32x4WithY:
      __ vmovs(result.s(1), STMP);
      break;
    case SimdOpInstr::kFloat32x4WithZ:
      __ vmovs(result.s(2), STMP);
      break;
    case SimdOpInstr::kFloat32x4WithW:
      __ vmovs(result.s(3), STMP);
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Simd64x2Shuffle, (QRegisterView result, QRegisterView value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat64x2GetX:
      __ vmovd(result.d(0), value.d(0));
      break;
    case SimdOpInstr::kFloat64x2GetY:
      __ vmovd(result.d(0), value.d(1));
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Float64x2Zero, (QRegister q)) {
  __ veorq(q, q, q);
}

DEFINE_EMIT(Float64x2Splat, (QRegisterView result, QRegisterView value)) {
  // Splat across all lanes.
  __ vmovd(result.d(0), value.d(0));
  __ vmovd(result.d(1), value.d(0));
}

DEFINE_EMIT(Float64x2FromDoubles,
            (QRegisterView r, QRegisterView q0, QRegisterView q1)) {
  __ vmovd(r.d(0), q0.d(0));
  __ vmovd(r.d(1), q1.d(0));
}

// Low (< 7) Q registers are needed for the vcvtsd instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float64x2ToFloat32x4, (FixedQRegisterView<Q6> r, QRegisterView q)) {
  __ veorq(r, r, r);
  // Set X lane.
  __ vcvtsd(r.s(0), q.d(0));
  // Set Y lane.
  __ vcvtsd(r.s(1), q.d(1));
}

// Low (< 7) Q registers are needed for the vcvtds instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float32x4ToFloat64x2, (QRegisterView r, FixedQRegisterView<Q6> q)) {
  // Set X.
  __ vcvtds(r.d(0), q.s(0));
  // Set Y.
  __ vcvtds(r.d(1), q.s(1));
}

// Grabbing the S components means we need a low (< 7) Q.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float64x2GetSignMask,
            (Register out, FixedQRegisterView<Q6> value)) {
  // Upper 32-bits of X lane.
  __ vmovrs(out, value.s(1));
  __ Lsr(out, out, compiler::Operand(31));
  // Upper 32-bits of Y lane.
  __ vmovrs(TMP, value.s(3));
  __ Lsr(TMP, TMP, compiler::Operand(31));
  __ orr(out, out, compiler::Operand(TMP, LSL, 1));
}

DEFINE_EMIT(Float64x2Unary, (QRegisterView result, QRegisterView value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat64x2Negate:
      __ vnegd(result.d(0), value.d(0));
      __ vnegd(result.d(1), value.d(1));
      break;
    case SimdOpInstr::kFloat64x2Abs:
      __ vabsd(result.d(0), value.d(0));
      __ vabsd(result.d(1), value.d(1));
      break;
    case SimdOpInstr::kFloat64x2Sqrt:
      __ vsqrtd(result.d(0), value.d(0));
      __ vsqrtd(result.d(1), value.d(1));
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Float64x2Binary,
            (SameAsFirstInput, QRegisterView left, QRegisterView right)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat64x2Scale:
      __ vmuld(left.d(0), left.d(0), right.d(0));
      __ vmuld(left.d(1), left.d(1), right.d(0));
      break;
    case SimdOpInstr::kFloat64x2WithX:
      __ vmovd(left.d(0), right.d(0));
      break;
    case SimdOpInstr::kFloat64x2WithY:
      __ vmovd(left.d(1), right.d(0));
      break;
    case SimdOpInstr::kFloat64x2Min: {
      // X lane.
      __ vcmpd(left.d(0), right.d(0));
      __ vmstat();
      __ vmovd(left.d(0), right.d(0), GE);
      // Y lane.
      __ vcmpd(left.d(1), right.d(1));
      __ vmstat();
      __ vmovd(left.d(1), right.d(1), GE);
      break;
    }
    case SimdOpInstr::kFloat64x2Max: {
      // X lane.
      __ vcmpd(left.d(0), right.d(0));
      __ vmstat();
      __ vmovd(left.d(0), right.d(0), LE);
      // Y lane.
      __ vcmpd(left.d(1), right.d(1));
      __ vmstat();
      __ vmovd(left.d(1), right.d(1), LE);
      break;
    }
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(Int32x4FromInts,
            (QRegisterView result,
             Register v0,
             Register v1,
             Register v2,
             Register v3)) {
  __ veorq(result, result, result);
  __ vmovdrr(result.d(0), v0, v1);
  __ vmovdrr(result.d(1), v2, v3);
}

DEFINE_EMIT(Int32x4FromBools,
            (QRegisterView result,
             Register v0,
             Register v1,
             Register v2,
             Register v3,
             Temp<Register> temp)) {
  __ veorq(result, result, result);
  __ LoadImmediate(temp, 0xffffffff);

  __ LoadObject(IP, Bool::True());
  __ cmp(v0, compiler::Operand(IP));
  __ vmovdr(result.d(0), 0, temp, EQ);

  __ cmp(v1, compiler::Operand(IP));
  __ vmovdr(result.d(0), 1, temp, EQ);

  __ cmp(v2, compiler::Operand(IP));
  __ vmovdr(result.d(1), 0, temp, EQ);

  __ cmp(v3, compiler::Operand(IP));
  __ vmovdr(result.d(1), 1, temp, EQ);
}

// Low (< 7) Q registers are needed for the vmovrs instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Int32x4GetFlag, (Register result, FixedQRegisterView<Q6> value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kInt32x4GetFlagX:
      __ vmovrs(result, value.s(0));
      break;
    case SimdOpInstr::kInt32x4GetFlagY:
      __ vmovrs(result, value.s(1));
      break;
    case SimdOpInstr::kInt32x4GetFlagZ:
      __ vmovrs(result, value.s(2));
      break;
    case SimdOpInstr::kInt32x4GetFlagW:
      __ vmovrs(result, value.s(3));
      break;
    default:
      UNREACHABLE();
  }

  __ tst(result, compiler::Operand(result));
  __ LoadObject(result, Bool::True(), NE);
  __ LoadObject(result, Bool::False(), EQ);
}

DEFINE_EMIT(Int32x4Select,
            (QRegister out,
             QRegister mask,
             QRegister trueValue,
             QRegister falseValue,
             Temp<QRegister> temp)) {
  // Copy mask.
  __ vmovq(temp, mask);
  // Invert it.
  __ vmvnq(temp, temp);
  // mask = mask & trueValue.
  __ vandq(mask, mask, trueValue);
  // temp = temp & falseValue.
  __ vandq(temp, temp, falseValue);
  // out = mask | temp.
  __ vorrq(out, mask, temp);
}

DEFINE_EMIT(Int32x4WithFlag,
            (QRegisterView result, QRegister mask, Register flag)) {
  __ vmovq(result, mask);
  __ CompareObject(flag, Bool::True());
  __ LoadImmediate(TMP, 0xffffffff, EQ);
  __ LoadImmediate(TMP, 0, NE);
  switch (instr->kind()) {
    case SimdOpInstr::kInt32x4WithFlagX:
      __ vmovdr(result.d(0), 0, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagY:
      __ vmovdr(result.d(0), 1, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagZ:
      __ vmovdr(result.d(1), 0, TMP);
      break;
    case SimdOpInstr::kInt32x4WithFlagW:
      __ vmovdr(result.d(1), 1, TMP);
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
#define SIMD_OP_VARIANTS(CASE, ____, SIMPLE)                                   \
  CASE(Float32x4Add)                                                           \
  CASE(Float32x4Sub)                                                           \
  CASE(Float32x4Mul)                                                           \
  CASE(Float32x4Div)                                                           \
  CASE(Float32x4Equal)                                                         \
  CASE(Float32x4NotEqual)                                                      \
  CASE(Float32x4GreaterThan)                                                   \
  CASE(Float32x4GreaterThanOrEqual)                                            \
  CASE(Float32x4LessThan)                                                      \
  CASE(Float32x4LessThanOrEqual)                                               \
  CASE(Float32x4Min)                                                           \
  CASE(Float32x4Max)                                                           \
  CASE(Float32x4Scale)                                                         \
  CASE(Int32x4BitAnd)                                                          \
  CASE(Int32x4BitOr)                                                           \
  CASE(Int32x4BitXor)                                                          \
  CASE(Int32x4Add)                                                             \
  CASE(Int32x4Sub)                                                             \
  ____(Simd32x4BinaryOp)                                                       \
  CASE(Float64x2Add)                                                           \
  CASE(Float64x2Sub)                                                           \
  CASE(Float64x2Mul)                                                           \
  CASE(Float64x2Div)                                                           \
  ____(Float64x2BinaryOp)                                                      \
  CASE(Float32x4GetX)                                                          \
  CASE(Float32x4GetY)                                                          \
  CASE(Float32x4GetZ)                                                          \
  CASE(Float32x4GetW)                                                          \
  CASE(Int32x4Shuffle)                                                         \
  CASE(Float32x4Shuffle)                                                       \
  ____(Simd32x4Shuffle)                                                        \
  CASE(Float32x4ShuffleMix)                                                    \
  CASE(Int32x4ShuffleMix)                                                      \
  ____(Simd32x4ShuffleMix)                                                     \
  CASE(Float32x4GetSignMask)                                                   \
  CASE(Int32x4GetSignMask)                                                     \
  ____(Simd32x4GetSignMask)                                                    \
  SIMPLE(Float32x4FromDoubles)                                                 \
  SIMPLE(Float32x4Zero)                                                        \
  SIMPLE(Float32x4Splat)                                                       \
  SIMPLE(Float32x4Sqrt)                                                        \
  CASE(Float32x4Negate)                                                        \
  CASE(Float32x4Abs)                                                           \
  CASE(Float32x4Reciprocal)                                                    \
  CASE(Float32x4ReciprocalSqrt)                                                \
  ____(Float32x4Unary)                                                         \
  CASE(Float32x4ToInt32x4)                                                     \
  CASE(Int32x4ToFloat32x4)                                                     \
  ____(Simd32x4ToSimd32x4Conversion)                                           \
  SIMPLE(Float32x4Clamp)                                                       \
  SIMPLE(Float64x2Clamp)                                                       \
  CASE(Float32x4WithX)                                                         \
  CASE(Float32x4WithY)                                                         \
  CASE(Float32x4WithZ)                                                         \
  CASE(Float32x4WithW)                                                         \
  ____(Float32x4With)                                                          \
  CASE(Float64x2GetX)                                                          \
  CASE(Float64x2GetY)                                                          \
  ____(Simd64x2Shuffle)                                                        \
  SIMPLE(Float64x2Zero)                                                        \
  SIMPLE(Float64x2Splat)                                                       \
  SIMPLE(Float64x2FromDoubles)                                                 \
  SIMPLE(Float64x2ToFloat32x4)                                                 \
  SIMPLE(Float32x4ToFloat64x2)                                                 \
  SIMPLE(Float64x2GetSignMask)                                                 \
  CASE(Float64x2Negate)                                                        \
  CASE(Float64x2Abs)                                                           \
  CASE(Float64x2Sqrt)                                                          \
  ____(Float64x2Unary)                                                         \
  CASE(Float64x2Scale)                                                         \
  CASE(Float64x2WithX)                                                         \
  CASE(Float64x2WithY)                                                         \
  CASE(Float64x2Min)                                                           \
  CASE(Float64x2Max)                                                           \
  ____(Float64x2Binary)                                                        \
  SIMPLE(Int32x4FromInts)                                                      \
  SIMPLE(Int32x4FromBools)                                                     \
  CASE(Int32x4GetFlagX)                                                        \
  CASE(Int32x4GetFlagY)                                                        \
  CASE(Int32x4GetFlagZ)                                                        \
  CASE(Int32x4GetFlagW)                                                        \
  ____(Int32x4GetFlag)                                                         \
  SIMPLE(Int32x4Select)                                                        \
  CASE(Int32x4WithFlagX)                                                       \
  CASE(Int32x4WithFlagY)                                                       \
  CASE(Int32x4WithFlagZ)                                                       \
  CASE(Int32x4WithFlagW)                                                       \
  ____(Int32x4WithFlag)

LocationSummary* SimdOpInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  switch (kind()) {
#define CASE(Name) case k##Name:
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
#define CASE(Name) case k##Name:
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
    const DRegister left = EvenDRegisterOf(locs()->in(0).fpu_reg());
    const DRegister right = EvenDRegisterOf(locs()->in(1).fpu_reg());
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
    const Register temp = locs()->temp(0).reg();
    __ vcmpd(left, right);
    __ vmstat();
    __ b(&returns_nan, VS);
    __ b(&are_equal, EQ);
    const Condition neg_double_condition =
        is_min ? TokenKindToDoubleCondition(Token::kGTE)
               : TokenKindToDoubleCondition(Token::kLTE);
    ASSERT(left == result);
    __ vmovd(result, right, neg_double_condition);
    __ b(&done);

    __ Bind(&returns_nan);
    __ LoadDImmediate(result, NAN, temp);
    __ b(&done);

    __ Bind(&are_equal);
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ vmovrrd(IP, temp, left);  // Sign bit is in bit 31 of temp.
    __ cmp(temp, compiler::Operand(0));
    if (is_min) {
      ASSERT(left == result);
      __ vmovd(result, right, GE);
    } else {
      __ vmovd(result, right, LT);
      ASSERT(left == result);
    }
    __ Bind(&done);
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  __ cmp(left, compiler::Operand(right));
  ASSERT(result == left);
  if (is_min) {
    __ mov(result, compiler::Operand(right), GT);
  } else {
    __ mov(result, compiler::Operand(right), LT);
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
      __ rsbs(result, value, compiler::Operand(0));
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn_(result, compiler::Operand(value));
      // Remove inverted smi-tag.
      __ bic(result, result, compiler::Operand(kSmiTagMask));
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
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  switch (op_kind()) {
    case Token::kNEGATE:
      __ vnegd(result, value);
      break;
    case Token::kSQRT:
      __ vsqrtd(result, value);
      break;
    case Token::kSQUARE:
      __ vmuld(result, value, value);
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
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  __ vmovdr(DTMP, 0, value);
  __ vcvtdi(result, STMP);
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
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  __ SmiUntag(IP, value);
  __ vmovdr(DTMP, 0, IP);
  __ vcvtdi(result, STMP);
}

LocationSummary* Int64ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return nullptr;
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  const DRegister value_double = EvenDRegisterOf(locs()->in(0).fpu_reg());

  DoubleToIntegerSlowPath* slow_path =
      new DoubleToIntegerSlowPath(this, locs()->in(0).fpu_reg());
  compiler->AddSlowPathCode(slow_path);

  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM because vcvtid gives 0 for NaN.
  __ vcmpd(value_double, value_double);
  __ vmstat();
  __ b(slow_path->entry_label(), VS);

  __ vcvtid(STMP, value_double);
  __ vmovrs(result, STMP);
  // Overflow is signaled with minint.
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC0000000);
  __ b(slow_path->entry_label(), MI);
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
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM because vcvtid gives 0 for NaN.
  __ vcmpd(value, value);
  __ vmstat();
  __ b(deopt, VS);

  __ vcvtid(STMP, value);
  __ vmovrs(result, STMP);
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC0000000);
  __ b(deopt, MI);
  __ SmiTag(result);
}

LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::FpuRegisterLocation(Q6));
  return result;
}

void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  const SRegister result =
      EvenSRegisterOf(EvenDRegisterOf(locs()->out(0).fpu_reg()));
  __ vcvtsd(result, value);
}

LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::FpuRegisterLocation(Q6));
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const SRegister value =
      EvenSRegisterOf(EvenDRegisterOf(locs()->in(0).fpu_reg()));
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  __ vcvtds(result, value);
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
      (TargetCPUFeatures::hardfp_supported())
          ? ((recognized_kind() == MethodRecognizer::kMathDoublePow) ? 1 : 0)
          : 4;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(Q0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(Q1));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    result->set_temp(0, Location::RegisterLocation(R2));
    if (!TargetCPUFeatures::hardfp_supported()) {
      result->set_temp(1, Location::RegisterLocation(R0));
      result->set_temp(2, Location::RegisterLocation(R1));
      result->set_temp(3, Location::RegisterLocation(R3));
    }
  } else if (!TargetCPUFeatures::hardfp_supported()) {
    result->set_temp(0, Location::RegisterLocation(R0));
    result->set_temp(1, Location::RegisterLocation(R1));
    result->set_temp(2, Location::RegisterLocation(R2));
    result->set_temp(3, Location::RegisterLocation(R3));
  }
  result->set_out(0, Location::FpuRegisterLocation(Q0));
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

  const DRegister base = EvenDRegisterOf(locs->in(0).fpu_reg());
  const DRegister exp = EvenDRegisterOf(locs->in(1).fpu_reg());
  const DRegister result = EvenDRegisterOf(locs->out(0).fpu_reg());
  const Register temp = locs->temp(0).reg();
  const DRegister saved_base = OddDRegisterOf(locs->in(0).fpu_reg());
  ASSERT((base == result) && (result != saved_base));

  compiler::Label skip_call, try_sqrt, check_base, return_nan;
  __ vmovd(saved_base, base);
  __ LoadDImmediate(result, 1.0, temp);
  // exponent == 0.0 -> return 1.0;
  __ vcmpdz(exp);
  __ vmstat();
  __ b(&check_base, VS);  // NaN -> check base.
  __ b(&skip_call, EQ);   // exp is 0.0, result is 1.0.

  // exponent == 1.0 ?
  __ vcmpd(exp, result);
  __ vmstat();
  compiler::Label return_base;
  __ b(&return_base, EQ);

  // exponent == 2.0 ?
  __ LoadDImmediate(DTMP, 2.0, temp);
  __ vcmpd(exp, DTMP);
  __ vmstat();
  compiler::Label return_base_times_2;
  __ b(&return_base_times_2, EQ);

  // exponent == 3.0 ?
  __ LoadDImmediate(DTMP, 3.0, temp);
  __ vcmpd(exp, DTMP);
  __ vmstat();
  __ b(&check_base, NE);

  // base_times_3.
  __ vmuld(result, saved_base, saved_base);
  __ vmuld(result, result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_base);
  __ vmovd(result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_base_times_2);
  __ vmuld(result, saved_base, saved_base);
  __ b(&skip_call);

  __ Bind(&check_base);
  // Note: 'exp' could be NaN.
  // base == 1.0 -> return 1.0;
  __ vcmpd(saved_base, result);
  __ vmstat();
  __ b(&return_nan, VS);
  __ b(&skip_call, EQ);  // base is 1.0, result is 1.0.

  __ vcmpd(saved_base, exp);
  __ vmstat();
  __ b(&try_sqrt, VC);  // // Neither 'exp' nor 'base' is NaN.

  __ Bind(&return_nan);
  __ LoadDImmediate(result, NAN, temp);
  __ b(&skip_call);

  compiler::Label do_pow, return_zero;
  __ Bind(&try_sqrt);

  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadDImmediate(result, kNegInfinity, temp);

  // base == -Infinity -> call pow;
  __ vcmpd(saved_base, result);
  __ vmstat();
  __ b(&do_pow, EQ);

  // exponent == 0.5 ?
  __ LoadDImmediate(result, 0.5, temp);
  __ vcmpd(exp, result);
  __ vmstat();
  __ b(&do_pow, NE);

  // base == 0 -> return 0;
  __ vcmpdz(saved_base);
  __ vmstat();
  __ b(&return_zero, EQ);

  __ vsqrtd(result, saved_base);
  __ b(&skip_call);

  __ Bind(&return_zero);
  __ LoadDImmediate(result, 0.0, temp);
  __ b(&skip_call);

  __ Bind(&do_pow);
  __ vmovd(base, saved_base);  // Restore base.

  // Args must be in D0 and D1, so move arg from Q1(== D3:D2) to D1.
  __ vmovd(D1, D2);
  if (TargetCPUFeatures::hardfp_supported()) {
    ASSERT(instr->TargetFunction().is_leaf());  // No deopt info needed.
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    rt.Call(instr->TargetFunction(), kInputCount);
  } else {
    // If the ABI is not "hardfp", then we have to move the double arguments
    // to the integer registers, and take the results from the integer
    // registers.
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    __ vmovrrd(R0, R1, D0);
    __ vmovrrd(R2, R3, D1);
    rt.Call(instr->TargetFunction(), kInputCount);
    __ vmovdrr(D0, R0, R1);
    __ vmovdrr(D1, R2, R3);
  }
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }

  if (InputCount() == 2) {
    // Args must be in D0 and D1, so move arg from Q1(== D3:D2) to D1.
    __ vmovd(D1, D2);
  }
  if (TargetCPUFeatures::hardfp_supported()) {
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    rt.Call(TargetFunction(), TargetFunction().argument_count());
  } else {
    // If the ABI is not "hardfp", then we have to move the double arguments
    // to the integer registers, and take the results from the integer
    // registers.
    compiler::LeafRuntimeScope rt(compiler->assembler(),
                                  /*frame_size=*/0,
                                  /*preserve_registers=*/false);
    __ vmovrrd(R0, R1, D0);
    __ vmovrrd(R2, R3, D1);
    rt.Call(TargetFunction(), TargetFunction().argument_count());
    __ vmovdrr(D0, R0, R1);
    __ vmovdrr(D1, R2, R3);
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
    const QRegister out = locs()->out(0).fpu_reg();
    const QRegister in = in_loc.fpu_reg();
    __ vmovq(out, in);
  } else {
    ASSERT(representation() == kTagged);
    const Register out = locs()->out(0).reg();
    const Register in = in_loc.reg();
    __ mov(out, compiler::Operand(in));
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
  const intptr_t kNumTemps = 2;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  // Request register that overlaps with S0..S31.
  summary->set_temp(1, Location::FpuRegisterLocation(Q0));
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
  PairLocation* pair = locs()->out(0).AsPairLocation();
  const Register result_div = pair->At(0).reg();
  const Register result_mod = pair->At(1).reg();
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ cmp(right, compiler::Operand(0));
    __ b(deopt, EQ);
  }
  const Register temp = locs()->temp(0).reg();
  const DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
  __ SmiUntag(temp, left);
  __ SmiUntag(IP, right);
  __ IntegerDivide(result_div, temp, IP, dtemp, DTMP);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  __ CompareImmediate(result_div, 0x40000000);
  __ b(deopt, EQ);
  __ SmiUntag(IP, right);
  // result_mod <- left - right * result_div.
  __ mls(result_mod, IP, result_div, temp);
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
  __ cmp(result_mod, compiler::Operand(0));
  __ b(&done, GE);
  // Result is negative, adjust it.
  __ cmp(right, compiler::Operand(0));
  __ sub(result_mod, result_mod, compiler::Operand(right), LT);
  __ add(result_mod, result_mod, compiler::Operand(right), GE);
  __ Bind(&done);
}

// Should be kept in sync with integers.cc Multiply64Hash
static void EmitHashIntegerCodeSequence(FlowGraphCompiler* compiler,
                                        const Register result,
                                        const Register value_lo,
                                        const Register value_hi) {
  __ LoadImmediate(TMP, compiler::Immediate(0x2d51));
  __ umull(result, value_lo, value_lo, TMP);  // (lo:result) = lo32 * 0x2d51
  __ umull(TMP, value_hi, value_hi, TMP);     // (hi:TMP) = hi32 * 0x2d51
  __ add(TMP, TMP, compiler::Operand(value_lo));
  //  (0:hi:TMP:result) is 128-bit product
  __ eor(result, value_hi, compiler::Operand(result));
  __ eor(result, TMP, compiler::Operand(result));
  __ AndImmediate(result, result, 0x3fffffff);
}

LocationSummary* HashDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 4;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNativeLeafCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_temp(1, Location::RegisterLocation(R1));
  summary->set_temp(2, Location::RequiresFpuRegister());
  summary->set_temp(3, Location::RegisterLocation(R4));
  summary->set_out(0, Location::Pair(Location::RegisterLocation(R0),
                                     Location::RegisterLocation(R1)));
  return summary;
}

void HashDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  const Register temp = locs()->temp(0).reg();
  const Register temp1 = locs()->temp(1).reg();
  ASSERT(temp1 == R1);
  const DRegister temp_double = EvenDRegisterOf(locs()->temp(2).fpu_reg());
  ASSERT(locs()->temp(3).reg() == R4);
  const PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register result = out_pair->At(0).reg();
  ASSERT(result == R0);
  ASSERT(out_pair->At(1).reg() == R1);

  compiler::Label hash_double, hash_double_value, try_convert;

  __ vmovrrd(TMP, temp, value);
  __ AndImmediate(temp, temp, 0x7FF00000);
  __ CompareImmediate(temp, 0x7FF00000);
  __ b(&hash_double_value, EQ);  // is_infinity or nan

  compiler::Label slow_path;
  __ Bind(&try_convert);
  // value -> temp1 -> temp_double
  __ vcvtid(STMP, value);
  __ vmovrs(temp1, STMP);
  // Checks whether temp1 is INT_MAX or INT_MIN which indicates failed vcvt
  __ CompareImmediate(temp1, 0xC0000000);
  __ b(&slow_path, MI);
  __ vmovdr(DTMP, 0, temp1);
  __ vcvtdi(temp_double, STMP);

  // value != temp_double, then go to hash_double_value
  __ vcmpd(value, temp_double);
  __ vmstat();
  __ b(&hash_double_value, NE);
  // Sign-extend 32-bit [temp1] value to 64-bit pair of (temp:temp1), which
  // is used by integer hash code sequence.
  __ SignFill(temp, temp1);

  compiler::Label hash_integer, done;
  {
    __ Bind(&hash_integer);
    // integer hash of (temp:temp1)
    EmitHashIntegerCodeSequence(compiler, result, temp1, temp);
    __ b(&done);
  }

  __ Bind(&slow_path);
  // double value is potentially doesn't fit into Smi range, so
  // do the double->int64->double via runtime call.
  __ StoreDToOffset(value, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  {
    compiler::LeafRuntimeScope rt(compiler->assembler(), /*frame_size=*/0,
                                  /*preserve_registers=*/true);
    __ mov(R0, compiler::Operand(THR));
    // Check if double can be represented as int64, load it into (temp:EAX) if
    // it can.
    rt.Call(kTryDoubleAsIntegerRuntimeEntry, 1);
    __ mov(R4, compiler::Operand(R0));
  }
  __ LoadFromOffset(temp1, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset());
  __ LoadFromOffset(temp, THR,
                    compiler::target::Thread::unboxed_runtime_arg_offset() +
                        compiler::target::kWordSize);
  __ cmp(R4, compiler::Operand(0));
  __ b(&hash_integer, NE);
  __ b(&hash_double);

  __ Bind(&hash_double_value);
  __ vmovrrd(temp, temp1, value);

  __ Bind(&hash_double);
  // Convert the double bits (temp:temp1) to a hash code that fits in a Smi.
  __ eor(result, temp1, compiler::Operand(temp));
  __ AndImmediate(result, result, compiler::target::kSmiMax);

  __ Bind(&done);
  __ mov(R1, compiler::Operand(0));
}

LocationSummary* HashIntegerOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::WritableRegister());
  summary->set_out(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}

void HashIntegerOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();

  if (smi_) {
    __ SmiUntag(value);
    __ SignFill(temp, value);
  } else {
    __ LoadFieldFromOffset(temp, value,
                           Mint::value_offset() + compiler::target::kWordSize);
    __ LoadFieldFromOffset(value, value, Mint::value_offset());
  }
  EmitHashIntegerCodeSequence(compiler, result, value, temp);
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
  __ Lsl(bit_reg, bit_reg, biased_cid);
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
  Register value_reg = locs()->in(0).reg();
  // TODO(dartbug.com/30480): Consider passing `null` literal as an argument
  // in order to be able to allocate it on register.
  __ CompareObject(value_reg, Object::null_object());

  const bool live_fpu_regs = locs()->live_registers()->FpuRegisterCount() > 0;
  Code& stub = Code::ZoneHandle(
      compiler->zone(),
      NullErrorSlowPath::GetStub(compiler, exception_type(), live_fpu_regs));
  const bool using_shared_stub = locs()->call_on_shared_slow_path();

  if (using_shared_stub && compiler->CanPcRelativeCall(stub)) {
    __ GenerateUnRelocatedPcRelativeCall(EQUAL);
    compiler->AddPcRelativeCallStubTarget(stub);

    // We use the "extended" environment which has the locations updated to
    // reflect live registers being saved in the shared spilling stubs (see
    // the stub above).
    auto extended_env = compiler->SlowPathEnvironmentFor(this, 0);
    compiler->EmitCallsiteMetadata(source(), deopt_id(),
                                   UntaggedPcDescriptors::kOther, locs(),
                                   extended_env);
    CheckNullInstr::AddMetadataForRuntimeCall(this, compiler);
    return;
  }

  ThrowErrorSlowPathCode* slow_path = new NullErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

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
    __ CompareImmediate(value, compiler::target::ToRawSmi(cids_.cid_start));
    __ b(deopt, NE);
  } else {
    __ AddImmediate(value, -compiler::target::ToRawSmi(cids_.cid_start));
    __ CompareImmediate(value, compiler::target::ToRawSmi(cids_.Extent()));
    __ b(deopt, HI);  // Unsigned higher.
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
#ifdef DEBUG
    const int32_t length = compiler::target::SmiValue(length_loc.constant());
    const int32_t index = compiler::target::SmiValue(index_loc.constant());
    ASSERT((length <= index) || (index < 0));
#endif
    // Unconditionally deoptimize for constant bounds checks because they
    // only occur only when index is out-of-bounds.
    __ b(deopt);
    return;
  }

  const intptr_t index_cid = index()->Type()->ToCid();
  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    __ CompareImmediate(length,
                        compiler::target::ToRawSmi(index_loc.constant()));
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (compiler::target::SmiValue(length_loc.constant()) ==
        compiler::target::kSmiMax) {
      __ tst(index, compiler::Operand(index));
      __ b(deopt, MI);
    } else {
      __ CompareImmediate(index,
                          compiler::target::ToRawSmi(length_loc.constant()));
      __ b(deopt, CS);
    }
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmp(index, compiler::Operand(length));
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
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}

void CheckWritableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  WriteErrorSlowPath* slow_path = new WriteErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  __ ldrb(TMP, compiler::FieldAddress(locs()->in(0).reg(),
                                      compiler::target::Object::tags_offset()));
  // In the first byte.
  ASSERT(compiler::target::UntaggedObject::kImmutableBit < 8);
  __ TestImmediate(TMP, 1 << compiler::target::UntaggedObject::kImmutableBit);
  __ b(slow_path->entry_label(), NOT_ZERO);
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));

  compiler::Operand o;
  if (CanBePairOfImmediateOperands(right(), &o, &o) &&
      (op_kind() == Token::kBIT_AND || op_kind() == Token::kBIT_OR ||
       op_kind() == Token::kBIT_XOR || op_kind() == Token::kADD ||
       op_kind() == Token::kSUB)) {
    summary->set_in(1, Location::Constant(right()->definition()->AsConstant()));
  } else {
    summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
  }
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  if (op_kind() == Token::kMUL) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(!can_overflow());
  ASSERT(!CanDeoptimize());

  compiler::Operand right_lo, right_hi;
  if (locs()->in(1).IsConstant()) {
    const bool ok = CanBePairOfImmediateOperands(locs()->in(1).constant(),
                                                 &right_lo, &right_hi);
    RELEASE_ASSERT(ok);
  } else {
    PairLocation* right_pair = locs()->in(1).AsPairLocation();
    right_lo = compiler::Operand(right_pair->At(0).reg());
    right_hi = compiler::Operand(right_pair->At(1).reg());
  }

  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ and_(out_lo, left_lo, compiler::Operand(right_lo));
      __ and_(out_hi, left_hi, compiler::Operand(right_hi));
      break;
    }
    case Token::kBIT_OR: {
      __ orr(out_lo, left_lo, compiler::Operand(right_lo));
      __ orr(out_hi, left_hi, compiler::Operand(right_hi));
      break;
    }
    case Token::kBIT_XOR: {
      __ eor(out_lo, left_lo, compiler::Operand(right_lo));
      __ eor(out_hi, left_hi, compiler::Operand(right_hi));
      break;
    }
    case Token::kADD: {
      __ adds(out_lo, left_lo, compiler::Operand(right_lo));
      __ adcs(out_hi, left_hi, compiler::Operand(right_hi));
      break;
    }
    case Token::kSUB: {
      __ subs(out_lo, left_lo, compiler::Operand(right_lo));
      __ sbcs(out_hi, left_hi, compiler::Operand(right_hi));
      break;
    }
    case Token::kMUL: {
      PairLocation* right_pair = locs()->in(1).AsPairLocation();
      Register right_lo_reg = right_pair->At(0).reg();
      Register right_hi_reg = right_pair->At(1).reg();
      // Compute 64-bit a * b as:
      //     a_l * b_l + (a_h * b_l + a_l * b_h) << 32
      Register temp = locs()->temp(0).reg();
      __ mul(temp, left_lo, right_hi_reg);
      __ mla(out_hi, left_hi, right_lo_reg, temp);
      __ umull(out_lo, temp, left_lo, right_lo_reg);
      __ add(out_hi, out_hi, compiler::Operand(temp));
      break;
    }
    default:
      UNREACHABLE();
  }
}

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
        __ Lsl(out_lo, left_hi, compiler::Operand(32 - shift));
        __ orr(out_lo, out_lo, compiler::Operand(left_lo, LSR, shift));
        __ Asr(out_hi, left_hi, compiler::Operand(shift));
      } else {
        if (shift == 32) {
          __ mov(out_lo, compiler::Operand(left_hi));
        } else if (shift < 64) {
          __ Asr(out_lo, left_hi, compiler::Operand(shift - 32));
        } else {
          __ Asr(out_lo, left_hi, compiler::Operand(31));
        }
        __ Asr(out_hi, left_hi, compiler::Operand(31));
      }
      break;
    }
    case Token::kUSHR: {
      ASSERT(shift < 64);
      if (shift < 32) {
        __ Lsl(out_lo, left_hi, compiler::Operand(32 - shift));
        __ orr(out_lo, out_lo, compiler::Operand(left_lo, LSR, shift));
        __ Lsr(out_hi, left_hi, compiler::Operand(shift));
      } else {
        if (shift == 32) {
          __ mov(out_lo, compiler::Operand(left_hi));
        } else {
          __ Lsr(out_lo, left_hi, compiler::Operand(shift - 32));
        }
        __ mov(out_hi, compiler::Operand(0));
      }
      break;
    }
    case Token::kSHL: {
      ASSERT(shift < 64);
      if (shift < 32) {
        __ Lsr(out_hi, left_lo, compiler::Operand(32 - shift));
        __ orr(out_hi, out_hi, compiler::Operand(left_hi, LSL, shift));
        __ Lsl(out_lo, left_lo, compiler::Operand(shift));
      } else {
        if (shift == 32) {
          __ mov(out_hi, compiler::Operand(left_lo));
        } else {
          __ Lsl(out_hi, left_lo, compiler::Operand(shift - 32));
        }
        __ mov(out_lo, compiler::Operand(0));
      }
      break;
    }
    default:
      UNREACHABLE();
  }
}

static void EmitShiftInt64ByRegister(FlowGraphCompiler* compiler,
                                     Token::Kind op_kind,
                                     Register out_lo,
                                     Register out_hi,
                                     Register left_lo,
                                     Register left_hi,
                                     Register right) {
  switch (op_kind) {
    case Token::kSHR: {
      __ rsbs(IP, right, compiler::Operand(32));
      __ sub(IP, right, compiler::Operand(32), MI);
      __ mov(out_lo, compiler::Operand(left_hi, ASR, IP), MI);
      __ mov(out_lo, compiler::Operand(left_lo, LSR, right), PL);
      __ orr(out_lo, out_lo, compiler::Operand(left_hi, LSL, IP), PL);
      __ mov(out_hi, compiler::Operand(left_hi, ASR, right));
      break;
    }
    case Token::kUSHR: {
      __ rsbs(IP, right, compiler::Operand(32));
      __ sub(IP, right, compiler::Operand(32), MI);
      __ mov(out_lo, compiler::Operand(left_hi, LSR, IP), MI);
      __ mov(out_lo, compiler::Operand(left_lo, LSR, right), PL);
      __ orr(out_lo, out_lo, compiler::Operand(left_hi, LSL, IP), PL);
      __ mov(out_hi, compiler::Operand(left_hi, LSR, right));
      break;
    }
    case Token::kSHL: {
      __ rsbs(IP, right, compiler::Operand(32));
      __ sub(IP, right, compiler::Operand(32), MI);
      __ mov(out_hi, compiler::Operand(left_lo, LSL, IP), MI);
      __ mov(out_hi, compiler::Operand(left_hi, LSL, right), PL);
      __ orr(out_hi, out_hi, compiler::Operand(left_lo, LSR, IP), PL);
      __ mov(out_lo, compiler::Operand(left_lo, LSL, right));
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
      case Token::kUSHR:
        __ Lsr(out, left, compiler::Operand(shift));
        break;
      case Token::kSHL:
        __ Lsl(out, left, compiler::Operand(shift));
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
      __ Lsr(out, left, right);
      break;
    case Token::kSHL:
      __ Lsl(out, left, right);
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
    PairLocation* left_pair = instruction()->locs()->in(0).AsPairLocation();
    Register left_hi = left_pair->At(1).reg();
    PairLocation* right_pair = instruction()->locs()->in(1).AsPairLocation();
    Register right_lo = right_pair->At(0).reg();
    Register right_hi = right_pair->At(1).reg();
    PairLocation* out_pair = instruction()->locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();

    __ CompareImmediate(right_hi, 0);

    switch (instruction()->AsShiftInt64Op()->op_kind()) {
      case Token::kSHR:
        __ Asr(out_hi, left_hi,
               compiler::Operand(compiler::target::kBitsPerWord - 1), GE);
        __ mov(out_lo, compiler::Operand(out_hi), GE);
        break;
      case Token::kUSHR:
      case Token::kSHL: {
        __ LoadImmediate(out_lo, 0, GE);
        __ LoadImmediate(out_hi, 0, GE);
        break;
      }
      default:
        UNREACHABLE();
    }

    __ b(exit_label(), GE);

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
    summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
  }
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
      __ b(slow_path->entry_label(), NE);
      __ CompareImmediate(right_lo, kShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, right_lo);

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
  summary->set_in(1, LocationWritableRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}

void SpeculativeShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
      __ b(deopt, HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, shift);
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
    Register out = instruction()->locs()->out(0).reg();

    __ CompareImmediate(right_hi, 0);
    __ LoadImmediate(out, 0, GE);
    __ b(exit_label(), GE);

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
    summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
      __ b(slow_path->entry_label(), NE);
      __ CompareImmediate(right_lo, kUint32ShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right_lo);

    if (slow_path != nullptr) {
      __ Bind(slow_path->exit_label());
    }
  }
}

LocationSummary* SpeculativeShiftUint32OpInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, LocationRegisterOrSmiConstant(right()));
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void SpeculativeShiftUint32OpInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(left != out);

  if (locs()->in(1).IsConstant()) {
    EmitShiftUint32ByConstant(compiler, op_kind(), out, left,
                              locs()->in(1).constant());
  } else {
    Register right = locs()->in(1).reg();
    const bool shift_count_in_range =
        IsShiftCountInRange(kUint32ShiftCountLimit);

    __ SmiUntag(temp, right);
    right = temp;

    // Deopt if shift count is negative.
    if (!shift_count_in_range) {
      ASSERT(CanDeoptimize());
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

      __ CompareImmediate(right, 0);
      __ b(deopt, LT);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right);

    if (!shift_count_in_range) {
      __ CompareImmediate(right, kUint32ShiftCountLimit);
      __ LoadImmediate(out, 0, HI);
    }
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
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  switch (op_kind()) {
    case Token::kBIT_NOT:
      __ mvn_(out_lo, compiler::Operand(left_lo));
      __ mvn_(out_hi, compiler::Operand(left_hi));
      break;
    case Token::kNEGATE:
      __ rsbs(out_lo, left_lo, compiler::Operand(0));
      __ sbc(out_hi, out_hi, compiler::Operand(out_hi));
      __ sub(out_hi, out_hi, compiler::Operand(left_hi));
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
  Register out = locs()->out(0).reg();
  ASSERT(out != left);
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ and_(out, left, compiler::Operand(right));
      break;
    case Token::kBIT_OR:
      __ orr(out, left, compiler::Operand(right));
      break;
    case Token::kBIT_XOR:
      __ eor(out, left, compiler::Operand(right));
      break;
    case Token::kADD:
      __ add(out, left, compiler::Operand(right));
      break;
    case Token::kSUB:
      __ sub(out, left, compiler::Operand(right));
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
  ASSERT(left != out);

  ASSERT(op_kind() == Token::kBIT_NOT);

  __ mvn_(out, compiler::Operand(left));
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
      __ tst(out, compiler::Operand(out));
      __ b(deopt, MI);
    }
  } else if (from() == kUnboxedInt64) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ mov(out, compiler::Operand(in_lo));
    if (CanDeoptimize()) {
      compiler::Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      ASSERT(to() == kUnboxedInt32);
      __ cmp(in_hi,
             compiler::Operand(in_lo, ASR, compiler::target::kBitsPerWord - 1));
      __ b(deopt, NE);
    }
  } else if (from() == kUnboxedUint32 || from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedInt64);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ mov(out_lo, compiler::Operand(in));
    if (from() == kUnboxedUint32) {
      __ eor(out_hi, out_hi, compiler::Operand(out_hi));
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ mov(out_hi,
             compiler::Operand(in, ASR, compiler::target::kBitsPerWord - 1));
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
      summary->set_in(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
      summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      break;
    case kUnboxedFloat:
    case kUnboxedDouble:
      // Choose an FPU register with corresponding D and S registers.
      summary->set_in(0, Location::FpuRegisterLocation(Q0));
      break;
    default:
      UNREACHABLE();
  }

  switch (to()) {
    case kUnboxedInt32:
      summary->set_out(0, Location::RequiresRegister());
      break;
    case kUnboxedInt64:
      summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                         Location::RequiresRegister()));
      break;
    case kUnboxedFloat:
    case kUnboxedDouble:
      // Choose an FPU register with corresponding D and S registers.
      summary->set_out(0, Location::FpuRegisterLocation(Q0));
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
      __ vmovsr(EvenSRegisterOf(EvenDRegisterOf(to_reg)), from_reg);
      break;
    }
    case kUnboxedFloat: {
      ASSERT(to() == kUnboxedInt32);
      const FpuRegister from_reg = locs()->in(0).fpu_reg();
      const Register to_reg = locs()->out(0).reg();
      __ vmovrs(to_reg, EvenSRegisterOf(EvenDRegisterOf(from_reg)));
      break;
    }
    case kUnboxedInt64: {
      ASSERT(to() == kUnboxedDouble);
      const Register from_lo = locs()->in(0).AsPairLocation()->At(0).reg();
      const Register from_hi = locs()->in(0).AsPairLocation()->At(1).reg();
      const FpuRegister to_reg = locs()->out(0).fpu_reg();
      __ vmovsr(EvenSRegisterOf(EvenDRegisterOf(to_reg)), from_lo);
      __ vmovsr(OddSRegisterOf(EvenDRegisterOf(to_reg)), from_hi);
      break;
    }
    case kUnboxedDouble: {
      ASSERT(to() == kUnboxedInt64);
      const FpuRegister from_reg = locs()->in(0).fpu_reg();
      const Register to_lo = locs()->out(0).AsPairLocation()->At(0).reg();
      const Register to_hi = locs()->out(0).AsPairLocation()->At(1).reg();
      __ vmovrs(to_lo, EvenSRegisterOf(EvenDRegisterOf(from_reg)));
      __ vmovrs(to_hi, OddSRegisterOf(EvenDRegisterOf(from_reg)));
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
      /*is_load=*/true,
      /*is_external=*/false, kTypedDataInt32ArrayCid,
      /*index_scale=*/4,
      /*index_unboxed=*/false, offset_reg, index_reg);
  __ ldr(offset_reg, element_address);

  // Offset is relative to entry pc.
  const intptr_t entry_to_pc_offset = __ CodeSize() + Instr::kPCReadOffset;
  __ mov(target_address_reg, compiler::Operand(PC));
  __ AddImmediate(target_address_reg, -entry_to_pc_offset);

  __ add(target_address_reg, target_address_reg, compiler::Operand(offset_reg));

  // Jump to the absolute address.
  __ bx(target_address_reg);
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

  // If a constant has more than one use, make sure it is loaded in register
  // so that multiple immediate loads can be avoided.
  ConstantInstr* constant = left()->definition()->AsConstant();
  if ((constant != nullptr) && !left()->IsSingleUse()) {
    locs->set_in(0, Location::RequiresRegister());
  } else {
    locs->set_in(0, LocationRegisterOrConstant(left()));
  }

  constant = right()->definition()->AsConstant();
  if ((constant != nullptr) && !right()->IsSingleUse()) {
    locs->set_in(1, Location::RequiresRegister());
  } else {
    // Only one of the inputs can be a constant. Choose register if the first
    // one is a constant.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : LocationRegisterOrConstant(right()));
  }
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
  // The ARM code may not use true- and false-labels here.
  compiler::Label is_true, is_false, done;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);

  const Register result = this->locs()->out(0).reg();
  if (is_false.IsLinked() || is_true.IsLinked()) {
    if (true_condition != kInvalidCondition) {
      EmitBranchOnCondition(compiler, true_condition, labels);
    }
    __ Bind(&is_false);
    __ LoadObject(result, Bool::False());
    __ b(&done);
    __ Bind(&is_true);
    __ LoadObject(result, Bool::True());
    __ Bind(&done);
  } else {
    // If EmitComparisonCode did not use the labels and just returned
    // a condition we can avoid the branch and use conditional loads.
    ASSERT(true_condition != kInvalidCondition);
    __ LoadObject(result, Bool::True(), true_condition);
    __ LoadObject(result, Bool::False(), InvertCondition(true_condition));
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
  __ eor(result, input,
         compiler::Operand(compiler::target::ObjectAlignment::kBoolValueMask));
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

#endif  // defined(TARGET_ARCH_ARM)
