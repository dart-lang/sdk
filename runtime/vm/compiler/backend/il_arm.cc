// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/compiler/backend/il.h"

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

LocationSummary* MemoryCopyInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps =
      element_size_ == 16 ? 4 : element_size_ == 8 ? 2 : 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kSrcPos, Location::WritableRegister());
  locs->set_in(kDestPos, Location::WritableRegister());
  locs->set_in(kSrcStartPos, Location::RequiresRegister());
  locs->set_in(kDestStartPos, Location::RequiresRegister());
  locs->set_in(kLengthPos, Location::WritableRegister());
  for (intptr_t i = 0; i < kNumTemps; i++) {
    locs->set_temp(i, Location::RequiresRegister());
  }
  return locs;
}

void MemoryCopyInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register src_reg = locs()->in(kSrcPos).reg();
  const Register dest_reg = locs()->in(kDestPos).reg();
  const Register src_start_reg = locs()->in(kSrcStartPos).reg();
  const Register dest_start_reg = locs()->in(kDestStartPos).reg();
  const Register length_reg = locs()->in(kLengthPos).reg();

  const Register temp_reg = locs()->temp(0).reg();
  RegList temp_regs = 0;
  for (intptr_t i = 0; i < locs()->temp_count(); i++) {
    temp_regs |= 1 << locs()->temp(i).reg();
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
  __ movs(length_reg, compiler::Operand(length_reg, ASR, 1));
  __ b(&done, ZERO);

  __ Bind(&loop);
  switch (element_size_) {
    case 1:
      __ ldrb(temp_reg, src_address);
      __ strb(temp_reg, dest_address);
      break;
    case 2:
      __ ldrh(temp_reg, src_address);
      __ strh(temp_reg, dest_address);
      break;
    case 4:
      __ ldr(temp_reg, src_address);
      __ str(temp_reg, dest_address);
      break;
    case 8:
    case 16:
      __ ldm(BlockAddressMode::IA_W, src_reg, temp_regs);
      __ stm(BlockAddressMode::IA_W, dest_reg, temp_regs);
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
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
  } else {
    locs->set_in(0, LocationAnyOrConstant(value()));
  }
  return locs;
}

// Buffers registers to use STMDB in order to push
// multiple registers at once.
class ArgumentsPusher : public ValueObject {
 public:
  ArgumentsPusher() {}

  // Flush all buffered registers.
  void Flush(FlowGraphCompiler* compiler) {
    if (pending_regs_ != 0) {
      if (is_single_register_) {
        __ Push(lowest_register_);
      } else {
        __ PushList(pending_regs_);
      }
      pending_regs_ = 0;
      lowest_register_ = kNoRegister;
      is_single_register_ = false;
    }
  }

  // Buffer given register. May push previously buffered registers if needed.
  void PushRegister(FlowGraphCompiler* compiler, Register reg) {
    if (pending_regs_ != 0) {
      ASSERT(lowest_register_ != kNoRegister);
      // STMDB pushes higher registers first, so we can only buffer
      // lower registers.
      if (reg < lowest_register_) {
        pending_regs_ |= (1 << reg);
        lowest_register_ = reg;
        is_single_register_ = false;
        return;
      }
      Flush(compiler);
    }
    pending_regs_ = (1 << reg);
    lowest_register_ = reg;
    is_single_register_ = true;
  }

  // Return a register which can be used to hold a value of an argument.
  Register FindFreeRegister(FlowGraphCompiler* compiler,
                            Instruction* push_arg) {
    // Dart calling conventions do not have callee-save registers,
    // so arguments pushing can clobber all allocatable registers
    // except registers used in arguments which were not pushed yet,
    // as well as ParallelMove and inputs of a call instruction.
    intptr_t busy = kReservedCpuRegisters;
    for (Instruction* instr = push_arg;; instr = instr->next()) {
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
        ASSERT(instr->IsPushArgument() || (instr->ArgumentCount() > 0));
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
      if (value.IsRegister()) {
        pusher.PushRegister(compiler, value.reg());
      } else if (value.IsPairLocation()) {
        pusher.PushRegister(compiler, value.AsPairLocation()->At(1).reg());
        pusher.PushRegister(compiler, value.AsPairLocation()->At(0).reg());
      } else if (value.IsFpuRegister()) {
        pusher.Flush(compiler);
        __ vstmd(DB_W, SP, EvenDRegisterOf(value.fpu_reg()), 1);
      } else {
        const Register reg = pusher.FindFreeRegister(compiler, push_arg);
        ASSERT(reg != kNoRegister);
        if (value.IsConstant()) {
          __ LoadObject(reg, value.constant());
        } else {
          ASSERT(value.IsStackSlot());
          const intptr_t value_offset = value.ToStackSlotOffset();
          __ LoadFromOffset(reg, value.base_reg(), value_offset);
        }
        pusher.PushRegister(compiler, reg);
      }
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
      locs->set_in(0,
                   Location::RegisterLocation(CallingConventions::kReturnReg));
      break;
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
  if (yield_index() != PcDescriptorsLayout::kInvalidYieldIndex) {
    compiler->EmitYieldPositionMetadata(source(), yield_index());
  }
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
    __ ldr(CODE_REG, compiler::FieldAddress(
                         R0, compiler::target::Function::code_offset()));
  }
  __ ldr(R2,
         compiler::FieldAddress(
             R0, compiler::target::Function::entry_point_offset(entry_kind())));

  // R2: instructions entry point.
  if (!FLAG_precompiled_mode) {
    // R9: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
    __ LoadImmediate(R9, 0);
  }
  __ blx(R2);
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
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      int64_t v;
      const bool ok = compiler::HasIntegerValue(value_, &v);
      RELEASE_ASSERT(ok);
      if (value_.IsSmi() && RepresentationUtils::IsUnsigned(representation())) {
        // If the value is negative, then the sign bit was preserved during
        // Smi untagging, which means the resulting value may be unexpected.
        ASSERT(v >= 0);
      }
      __ LoadImmediate(destination.reg(), v);
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObject(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const DRegister dst = EvenDRegisterOf(destination.fpu_reg());
    if (Utils::DoublesBitEqual(Double::Cast(value_).value(), 0.0) &&
        TargetCPUFeatures::neon_supported()) {
      QRegister qdst = destination.fpu_reg();
      __ veorq(qdst, qdst, qdst);
    } else {
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
      __ LoadImmediate(tmp, v);
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
  // not guarateed to be preserved by the ABI.
  const intptr_t kCpuRegistersToPreserve =
      kDartAvailableCpuRegs & ~kNonChangeableInputRegs;
  const intptr_t kFpuRegistersToPreserve =
      Utils::SignedNBitMask(kNumberOfFpuRegisters) &
      ~(Utils::SignedNBitMask(kAbiPreservedFpuRegCount)
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
  if (operation_cid() == kSmiCid) {
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
  return NULL;
}

static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         compiler::Label* value_is_smi = NULL) {
  if (value_is_smi == NULL) {
    __ mov(value_cid_reg, compiler::Operand(kSmiCid));
  }
  __ tst(value_reg, compiler::Operand(kSmiTagMask));
  if (value_is_smi == NULL) {
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

  Condition true_condition = TokenKindToSmiCondition(kind);

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

static Condition TokenKindToMintCondition(Token::Kind kind) {
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

  // Compare lower.
  __ cmp(left_lo, compiler::Operand(right_lo));
  // Compare upper if lower is equal.
  __ cmp(left_hi, compiler::Operand(right_hi), EQ);
  return TokenKindToMintCondition(kind);
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

  // 64-bit comparison.
  Condition hi_cond, lo_cond;
  switch (kind) {
    case Token::kLT:
      hi_cond = LT;
      lo_cond = CC;
      break;
    case Token::kGT:
      hi_cond = GT;
      lo_cond = HI;
      break;
    case Token::kLTE:
      hi_cond = LT;
      lo_cond = LS;
      break;
    case Token::kGTE:
      hi_cond = GT;
      lo_cond = CS;
      break;
    default:
      UNREACHABLE();
      hi_cond = lo_cond = VS;
  }
  // Compare upper halves first.
  __ cmp(left_hi, compiler::Operand(right_hi));
  __ b(labels.true_label, hi_cond);
  __ b(labels.false_label, FlipCondition(hi_cond));

  // If higher words are equal, compare lower words.
  __ cmp(left_lo, compiler::Operand(right_lo));
  return lo_cond;
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
  __ vcmpd(dleft, dright);
  __ vmstat();
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
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind());
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
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids,
                                   licm_hoisted_ ? ICData::kHoisted : 0)
          : NULL;

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

  // All arguments are already @SP due to preceding PushArgument()s.
  ASSERT(ArgumentCount() ==
         function().NumParameters() + (function().IsGeneric() ? 1 : 0));

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());

  // Pass a pointer to the first argument in R2.
  __ add(R2, SP,
         compiler::Operand(ArgumentCount() * compiler::target::kWordSize));

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
  __ mov(saved_fp, compiler::Operand(FPREG));

  // Make a space to put the return address.
  __ PushImmediate(0);

  // We need to create a dummy "exit frame". It will have a null code object.
  __ LoadObject(CODE_REG, Object::null_object());
  __ set_constant_pool_allowed(false);
  __ EnterDartFrame(0, /*load_pool_pointer=*/false);

  // Reserve space for arguments and align frame before entering C++ world.
  __ ReserveAlignedFrameSpace(marshaller_.RequiredStackSpaceInBytes());

  EmitParamMoves(compiler);

  if (compiler::Assembler::EmittingComments()) {
    __ Comment("Call");
  }
  // We need to copy the return address up into the dummy stack frame so the
  // stack walker will know which safepoint to use.
  __ mov(TMP, compiler::Operand(PC));
  __ str(TMP, compiler::Address(FPREG, kSavedCallerPcSlotFromFp *
                                           compiler::target::kWordSize));

  // For historical reasons, the PC on ARM points 8 bytes past the current
  // instruction. Therefore we emit the metadata here, 8 bytes (2 instructions)
  // after the original mov.
  compiler->EmitCallsiteMetadata(InstructionSource(), deopt_id(),
                                 PcDescriptorsLayout::Kind::kOther, locs());

  // Update information in the thread object and enter a safepoint.
  if (CanExecuteGeneratedCodeInSafepoint()) {
    __ LoadImmediate(temp, compiler::target::Thread::exit_through_ffi());
    __ TransitionGeneratedToNative(branch, FPREG, temp, saved_fp,
                                   /*enter_safepoint=*/true);

    __ blx(branch);

    // Update information in the thread object and leave the safepoint.
    __ TransitionNativeToGenerated(saved_fp, temp, /*leave_safepoint=*/true);
  } else {
    // We cannot trust that this code will be executable within a safepoint.
    // Therefore we delegate the responsibility of entering/exiting the
    // safepoint to a stub which in the VM isolate's heap, which will never lose
    // execute permission.
    __ ldr(TMP,
           compiler::Address(
               THR, compiler::target::Thread::
                        call_native_through_safepoint_entry_point_offset()));

    // Calls R8 in a safepoint and clobbers R4 and NOTFP.
    ASSERT(branch == R8 && temp == R4);
    static_assert((kReservedCpuRegisters & (1 << NOTFP)) != 0,
                  "NOTFP should be a reserved register");
    __ blx(TMP);
  }

  // Restore the global object pool after returning from runtime (old space is
  // moving, so the GOP could have been relocated).
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    __ SetupGlobalPoolAndDispatchTable();
  }

  EmitReturnMoves(compiler);

  // Leave dummy exit frame.
  __ LeaveDartFrame();
  __ set_constant_pool_allowed(true);

  // Instead of returning to the "fake" return address, we just pop it.
  __ PopRegister(TMP);
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

  // If we were called by a trampoline, it will enter the safepoint on our
  // behalf.
  __ TransitionGeneratedToNative(
      vm_tag_reg, old_exit_frame_reg, old_exit_through_ffi_reg, tmp,
      /*enter_safepoint=*/!NativeCallbackTrampolines::Enabled());

  __ PopNativeCalleeSavedRegisters();

#if defined(TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
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

  // Enter the entry frame.
  SPILLS_LR_TO_FRAME(__ EnterFrame((1 << FP) | (1 << LR), 0));

  // Save a space for the code object.
  __ PushImmediate(0);

#if defined(TARGET_OS_FUCHSIA) && defined(USING_SHADOW_CALL_STACK)
#error Unimplemented
#endif

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
    ASSERT(kWordSize == compiler::target::kWordSize);
    __ LoadImmediate(
        R1, static_cast<compiler::target::uword>(
                reinterpret_cast<uword>(DLRT_GetThreadForNativeCallback)));
  }

  // Load the thread object. If we were called by a trampoline, the thread is
  // already loaded.
  if (!NativeCallbackTrampolines::Enabled()) {
    // Create another frame to align the frame before continuing in "native"
    // code.
    __ EnterFrame(1 << FP, 0);
    __ ReserveAlignedFrameSpace(0);

    __ LoadImmediate(R0, callback_id_);
    __ blx(R1);
    __ mov(THR, compiler::Operand(R0));

    __ LeaveFrame(1 << FP);
  }

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

  // Either DLRT_GetThreadForNativeCallback or the callback trampoline (caller)
  // will leave the safepoint for us.
  __ TransitionNativeToGenerated(/*scratch0=*/R0, /*scratch1=*/R1,
                                 /*exit_safepoint=*/false);

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
      UNREACHABLE();
      return kTagged;
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
  if ((constant == NULL) ||
      !compiler::Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = compiler::target::SmiValue(constant->value());
  const intptr_t scale = compiler::target::Instance::ElementSizeFor(cid);
  const intptr_t base_offset =
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset = index * scale + base_offset;
  if (!Utils::IsAbsoluteUint(12, offset)) {
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
    if (representation() == kUnboxedDouble) {
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
  if ((representation() == kUnboxedDouble) ||
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
    if (representation() == kUnboxedDouble) {
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

  if ((representation() == kUnboxedDouble) ||
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
             (class_id() == kTypeArgumentsCid));
      __ ldr(result, element_address);
      break;
    }
  }
}

Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) {
    if (index_unboxed_) {
      // TODO(dartbug.com/39432): kUnboxedInt32 || kUnboxedUint32.
      return kNoRepresentation;
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
      return NULL;
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
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    compiler::FieldAddress field_cid_operand(
        field_reg, compiler::target::Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        field_reg, compiler::target::Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ ldrh(IP, field_cid_operand);
      __ cmp(value_cid_reg, compiler::Operand(IP));
      __ b(&ok, EQ);
      __ ldrh(IP, field_nullability_operand);
      __ cmp(value_cid_reg, compiler::Operand(IP));
    } else if (value_cid == kNullCid) {
      __ ldrh(value_cid_reg, field_nullability_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      __ ldrh(value_cid_reg, field_cid_operand);
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
      __ ldrh(IP, field_cid_operand);
      __ CompareImmediate(IP, kIllegalCid);
      __ b(fail, NE);

      if (value_cid == kDynamicCid) {
        __ strh(value_cid_reg, field_cid_operand);
        __ strh(value_cid_reg, field_nullability_operand);
      } else {
        __ LoadImmediate(IP, value_cid);
        __ strh(IP, field_cid_operand);
        __ strh(IP, field_nullability_operand);
      }

      __ b(&ok);
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ ldrh(IP,
              compiler::FieldAddress(
                  field_reg, compiler::target::Field::guarded_cid_offset()));
      __ CompareImmediate(IP, kDynamicCid);
      __ b(&ok, EQ);

      __ Push(field_reg);
      __ Push(value_reg);
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
          : NULL;

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

    if (deopt == NULL) {
      __ b(&ok, EQ);

      __ Push(field_reg);
      __ Push(value_reg);
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
DEFINE_UNIMPLEMENTED_INSTRUCTION(CheckConditionInstr)

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

LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      ((IsUnboxedStore() && opt) ? (FLAG_precompiled_mode ? 0 : 2)
                                 : (IsPotentialUnboxedStore() ? 3 : 0));
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
      summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
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
                             : Location::FpuRegisterLocation(Q1));
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
  __ ldr(box_reg, compiler::FieldAddress(instance_reg, offset));
  __ CompareObject(box_reg, Object::null_object());
  __ b(&done, NE);

  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);

  __ MoveRegister(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp,
                           compiler::Assembler::kValueIsNotSmi);
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
      const PairLocation* value_pair = locs()->in(1).AsPairLocation();
      const Register value_lo = value_pair->At(0).reg();
      const Register value_hi = value_pair->At(1).reg();
      __ Comment("UnboxedIntegerStoreInstanceFieldInstr");
      __ StoreFieldToOffset(value_lo, instance_reg, offset_in_bytes);
      __ StoreFieldToOffset(value_hi, instance_reg,
                            offset_in_bytes + compiler::target::kWordSize);
      return;
    }

    const intptr_t cid = slot().field().UnboxedFieldCid();
    const DRegister value = EvenDRegisterOf(locs()->in(1).fpu_reg());

    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
          __ StoreDToOffset(value, instance_reg,
                            offset_in_bytes - kHeapObjectTag);
          return;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
          __ StoreMultipleDToOffset(value, 2, instance_reg,
                                    offset_in_bytes - kHeapObjectTag);
          return;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
          __ StoreMultipleDToOffset(value, 2, instance_reg,
                                    offset_in_bytes - kHeapObjectTag);
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
      __ ldr(temp, compiler::FieldAddress(instance_reg, offset_in_bytes));
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ StoreDToOffset(
            value, temp,
            compiler::target::Double::value_offset() - kHeapObjectTag);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ StoreMultipleDToOffset(
            value, 2, temp,
            compiler::target::Float32x4::value_offset() - kHeapObjectTag);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ StoreMultipleDToOffset(
            value, 2, temp,
            compiler::target::Float64x2::value_offset() - kHeapObjectTag);
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
    const DRegister fpu_temp = EvenDRegisterOf(locs()->temp(2).fpu_reg());

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

    __ ldrh(temp2, compiler::FieldAddress(
                       temp, compiler::target::Field::is_nullable_offset()));
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ ldrb(temp2, compiler::FieldAddress(
                       temp, compiler::target::Field::kind_bits_offset()));
    __ tst(temp2, compiler::Operand(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ ldrh(temp2, compiler::FieldAddress(
                       temp, compiler::target::Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ ldrh(temp2, compiler::FieldAddress(
                       temp, compiler::target::Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

    __ ldrh(temp2, compiler::FieldAddress(
                       temp, compiler::target::Field::guarded_cid_offset()));
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
      __ CopyDoubleField(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler, this, temp, compiler->float32x4_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ CopyFloat32x4Field(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler, this, temp, compiler->float64x2_class(),
                       instance_reg, offset_in_bytes, temp2);
      __ CopyFloat64x2Field(temp, value_reg, TMP, temp2, fpu_temp);
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
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes,
                                        locs()->in(1).constant());
    } else {
      const Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes,
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
                      R8, R6);
  // R0: new object start as a tagged pointer.
  // R3: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      R0,
      compiler::FieldAddress(R0,
                             compiler::target::Array::type_arguments_offset()),
      kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(
      R0, compiler::FieldAddress(R0, compiler::target::Array::length_offset()),
      kLengthReg);

  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R3: new object end address.
  // R6: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R8: null
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(ArrayLayout);
    __ LoadObject(R8, Object::null_object());
    if (num_elements >= 2) {
      __ mov(R9, compiler::Operand(R8));
    } else {
#if defined(DEBUG)
      // Clobber R9 with an invalid pointer.
      __ LoadImmediate(R9, 0x1);
#endif  // DEBUG
    }
    __ AddImmediate(R6, R0, sizeof(ArrayLayout) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * compiler::target::kWordSize)) {
      __ InitializeFieldsNoBarrierUnrolled(
          R0, R6, 0, num_elements * compiler::target::kWordSize, R8, R9);
    } else {
      __ InitializeFieldsNoBarrier(R0, R6, R3, R8, R9);
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
      compiler::target::IsSmi(num_elements()->BoundConstant())) {
    const intptr_t length =
        compiler::target::SmiValue(num_elements()->BoundConstant());
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
    const size_t value_size =
        RepresentationUtils::ValueSize(slot().representation());

    const intptr_t kNumTemps = 0;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    if (value_size <= compiler::target::kWordSize) {
      locs->set_out(0, Location::RequiresRegister());
    } else {
      ASSERT(value_size <= 2 * compiler::target::kWordSize);
      locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    }

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
    const intptr_t kNumTemps = 3;
    locs = new (zone) LocationSummary(zone, kNumInputs, kNumTemps,
                                      LocationSummary::kCallOnSlowPath);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_temp(0, opt ? Location::RequiresFpuRegister()
                          : Location::FpuRegisterLocation(Q1));
    locs->set_temp(1, Location::RequiresRegister());
    locs->set_temp(2, Location::RequiresRegister());
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
    ASSERT(!calls_initializer());
    switch (slot().representation()) {
      case kUnboxedInt64: {
        auto const out_pair = locs()->out(0).AsPairLocation();
        const Register out_lo = out_pair->At(0).reg();
        const Register out_hi = out_pair->At(1).reg();
        const intptr_t offset_lo = OffsetInBytes() - kHeapObjectTag;
        const intptr_t offset_hi = offset_lo + compiler::target::kWordSize;
        __ Comment("UnboxedInt64LoadFieldInstr");
        __ LoadFromOffset(out_lo, instance_reg, offset_lo);
        __ LoadFromOffset(out_hi, instance_reg, offset_hi);
        break;
      }
      case kUnboxedUint32: {
        const Register result = locs()->out(0).reg();
        __ Comment("UnboxedUint32LoadFieldInstr");
        __ LoadFieldFromOffset(result, instance_reg, OffsetInBytes());
        break;
      }
      case kUnboxedUint8: {
        const Register result = locs()->out(0).reg();
        __ Comment("UnboxedUint8LoadFieldInstr");
        __ LoadFieldFromOffset(result, instance_reg, OffsetInBytes(),
                               compiler::kUnsignedByte);
        break;
      }
      default:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

  if (IsUnboxedDartFieldLoad() && compiler->is_optimizing()) {
    ASSERT_EQUAL(slot().representation(), kTagged);
    ASSERT(!calls_initializer());
    ASSERT(!slot().field().is_non_nullable_integer());
    const intptr_t cid = slot().field().UnboxedFieldCid();
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());

    if (FLAG_precompiled_mode) {
      switch (cid) {
        case kDoubleCid:
          __ Comment("UnboxedDoubleLoadFieldInstr");
          __ LoadDFromOffset(result, instance_reg,
                             OffsetInBytes() - kHeapObjectTag);
          return;
        case kFloat32x4Cid:
          __ Comment("UnboxedFloat32x4LoadFieldInstr");
          __ LoadMultipleDFromOffset(result, 2, instance_reg,
                                     OffsetInBytes() - kHeapObjectTag);
          return;
        case kFloat64x2Cid:
          __ Comment("UnboxedFloat64x2LoadFieldInstr");
          __ LoadMultipleDFromOffset(result, 2, instance_reg,
                                     OffsetInBytes() - kHeapObjectTag);
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
        __ LoadDFromOffset(
            result, temp,
            compiler::target::Double::value_offset() - kHeapObjectTag);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        __ LoadMultipleDFromOffset(
            result, 2, temp,
            compiler::target::Float32x4::value_offset() - kHeapObjectTag);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2LoadFieldInstr");
        __ LoadMultipleDFromOffset(
            result, 2, temp,
            compiler::target::Float64x2::value_offset() - kHeapObjectTag);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  compiler::Label done;
  const Register result_reg = locs()->out(0).reg();
  if (IsPotentialUnboxedDartFieldLoad()) {
    ASSERT_EQUAL(slot().representation(), kTagged);
    ASSERT(!calls_initializer());
    const DRegister value = EvenDRegisterOf(locs()->temp(0).fpu_reg());
    const Register temp = locs()->temp(1).reg();
    const Register temp2 = locs()->temp(2).reg();

    compiler::Label load_pointer;
    compiler::Label load_double;
    compiler::Label load_float32x4;
    compiler::Label load_float64x2;

    __ LoadObject(result_reg, Field::ZoneHandle(slot().field().Original()));

    compiler::FieldAddress field_cid_operand(
        result_reg, compiler::target::Field::guarded_cid_offset());
    compiler::FieldAddress field_nullability_operand(
        result_reg, compiler::target::Field::is_nullable_offset());

    __ ldrh(temp, field_nullability_operand);
    __ CompareImmediate(temp, kNullCid);
    __ b(&load_pointer, EQ);

    __ ldrh(temp, field_cid_operand);
    __ CompareImmediate(temp, kDoubleCid);
    __ b(&load_double, EQ);

    __ ldrh(temp, field_cid_operand);
    __ CompareImmediate(temp, kFloat32x4Cid);
    __ b(&load_float32x4, EQ);

    __ ldrh(temp, field_cid_operand);
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
      __ ldr(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ CopyDoubleField(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result_reg, temp);
      __ ldr(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ CopyFloat32x4Field(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result_reg, temp);
      __ ldr(temp, compiler::FieldAddress(instance_reg, OffsetInBytes()));
      __ CopyFloat64x2Field(result_reg, temp, TMP, temp2, value);
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
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type());
  static_assert(InstantiationABI::kFunctionTypeArgumentsReg <
                    InstantiationABI::kInstantiatorTypeArgumentsReg,
                "Should be ordered to push arguments with one instruction");
  __ PushList((1 << instantiator_type_args_reg) |
              (1 << function_type_args_reg));
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
    //
    // 'instantiator_type_args_reg' is a TypeArguments object (or null).
    // 'function_type_args_reg' is a TypeArguments object (or null).
    const Register instantiator_type_args_reg = locs()->in(0).reg();
    const Register function_type_args_reg = locs()->in(1).reg();
    const Register result_reg = locs()->out(0).reg();
    ASSERT(result_reg != instantiator_type_args_reg &&
           result_reg != function_type_args_reg);
    __ LoadObject(result_reg, Object::null_object());
    __ cmp(instantiator_type_args_reg, compiler::Operand(result_reg));
    if (!function_type_arguments()->BindsToConstant()) {
      __ cmp(function_type_args_reg, compiler::Operand(result_reg), EQ);
    }
    __ b(&type_arguments_instantiated, EQ);
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
  __ str(temp0, compiler::FieldAddress(
                    result, compiler::target::Context::num_variables_offset()));

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
  locs->set_in(0, Location::RegisterLocation(R4));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R4);
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
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
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
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env =
        compiler->SlowPathEnvironmentFor(instruction(), kNumSlowPathArgs);
    compiler->pending_deoptimization_env_ = env;

    if (using_shared_stub) {
      const uword entry_point_offset = compiler::target::Thread::
          stack_overflow_shared_stub_entry_point_offset(
              instruction()->locs()->live_registers()->FpuRegisterCount() > 0);
      __ Call(compiler::Address(THR, entry_point_offset));
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
  __ ldr(IP, compiler::Address(THR,
                               compiler::target::Thread::stack_limit_offset()));
  __ cmp(SP, compiler::Operand(IP));

  auto object_store = compiler->isolate()->object_store();
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
                                   PcDescriptorsLayout::kOther, locs(),
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
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
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
          : NULL;
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
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));
    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ mov(result, compiler::Operand(R0));
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
    __ tst(left, compiler::Operand(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tst(right, compiler::Operand(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tst(left, compiler::Operand(kSmiTagMask));
  } else {
    combined_smi_check = true;
    __ orr(result, left, compiler::Operand(right));
    __ tst(result, compiler::Operand(kSmiTagMask));
  }
  __ b(slow_path->entry_label(), NE);
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
      __ SmiUntag(IP, left);
      __ smull(result, IP, IP, right);
      // IP: result bits 32..63.
      __ cmp(IP, compiler::Operand(result, ASR, 31));
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
      __ CompareImmediate(
          right, compiler::target::ToRawSmi(compiler::target::kSmiBits));
      __ b(slow_path->entry_label(), HI);

      __ SmiUntag(TMP, right);
      // Check for overflow by shifting left and shifting back arithmetically.
      // If the result is different from the original, there was overflow.
      __ Lsl(result, left, TMP);
      __ cmp(left, compiler::Operand(result, ASR, TMP));
      __ b(slow_path->entry_label(), NE);
      break;
    case Token::kSHR:
      ASSERT(result != left);
      ASSERT(result != right);
      __ CompareImmediate(
          right, compiler::target::ToRawSmi(compiler::target::kSmiBits));
      __ b(slow_path->entry_label(), HI);

      __ SmiUntag(result, right);
      __ SmiUntag(TMP, left);
      __ Asr(result, TMP, result);
      __ SmiTag(result);
      break;
    default:
      UNREACHABLE();
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
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    const auto& selector = String::Handle(instruction()->call()->Selector());
    const auto& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::NewBoxed(
            /*type_args_len=*/0, /*num_arguments=*/2));
    compiler->EmitMegamorphicInstanceCall(
        selector, arguments_descriptor, instruction()->call()->deopt_id(),
        instruction()->source(), locs, try_index_, kNumSlowPathArgs);
    __ mov(result, compiler::Operand(R0));
    compiler->RestoreLiveRegisters(locs);
    compiler->pending_deoptimization_env_ = nullptr;
    if (merged_) {
      __ CompareObject(result, Bool::True());
      __ b(instruction()->is_negated() ? labels_.false_label
                                       : labels_.true_label,
           EQ);
      __ b(instruction()->is_negated() ? labels_.true_label
                                       : labels_.false_label);
    } else {
      if (instruction()->is_negated()) {
        // Need to negate the result of slow path call.
        __ CompareObject(result, Bool::True());
        __ LoadObject(result, Bool::True(), NE);
        __ LoadObject(result, Bool::False(), EQ);
      }
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
  return EmitSmiComparisonOp(compiler, locs(), kind());
}

#define EMIT_SMI_CHECK                                                         \
  Register left = locs()->in(0).reg();                                         \
  Register right = locs()->in(1).reg();                                        \
  Register temp = locs()->temp(0).reg();                                       \
  intptr_t left_cid = this->left()->Type()->ToCid();                           \
  intptr_t right_cid = this->right()->Type()->ToCid();                         \
  if (this->left()->definition() == this->right()->definition()) {             \
    __ tst(left, compiler::Operand(kSmiTagMask));                              \
  } else if (left_cid == kSmiCid) {                                            \
    __ tst(right, compiler::Operand(kSmiTagMask));                             \
  } else if (right_cid == kSmiCid) {                                           \
    __ tst(left, compiler::Operand(kSmiTagMask));                              \
  } else {                                                                     \
    __ orr(temp, left, compiler::Operand(right));                              \
    __ tst(temp, compiler::Operand(kSmiTagMask));                              \
  }                                                                            \
  __ b(slow_path->entry_label(), NE)

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
  __ Bind(slow_path->exit_label());
}

void CheckedSmiComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BranchLabels labels = {NULL, NULL, NULL};
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, env(), compiler->CurrentTryIndex(), labels,
      /* merged = */ false);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);
  Register result = locs()->out(0).reg();
  __ LoadObject(result, Bool::True(), true_condition);
  __ LoadObject(result, Bool::False(), InvertCondition(true_condition));
  __ Bind(slow_path->exit_label());
}
#undef EMIT_SMI_CHECK

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
             (op_kind() == Token::kSHR)) {
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
    ASSERT(compiler::target::IsSmi(constant));
    const int32_t imm = compiler::target::ToRawSmi(constant);
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
          // overflow when imm == kMinInt32.
          __ SubImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = compiler::target::SmiValue(constant);
        if (deopt == NULL) {
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
      __ SmiUntag(IP, left);
      if (deopt == NULL) {
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
      ASSERT(TargetCPUFeatures::can_divide());
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
      ASSERT(TargetCPUFeatures::can_divide());
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
          : NULL;
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
      (op_kind() == Token::kSHR)) {
    num_temps = 1;
  }
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
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

void BinaryInt32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitInt32ShiftLeft(compiler, this);
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
    ASSERT(compiler::target::IsSmi(constant));
    const intptr_t value = compiler::target::SmiValue(constant);
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, value);
        } else {
          __ AddImmediateSetFlags(result, left, value);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kSUB: {
        if (deopt == NULL) {
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
        if (deopt == NULL) {
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
      if (deopt == NULL) {
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
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                             licm_hoisted_ ? ICData::kHoisted : 0);
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
  compiler::Label done;
  __ SmiUntag(result, value, &done);
  __ LoadFieldFromOffset(result, value, compiler::target::Mint::value_offset());
  __ Bind(&done);
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

  __ AndImmediate(out, value, 0xff);
  __ SmiTag(out);
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
                   compiler->intrinsic_slow_path_label(), out_reg, tmp);
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
  if (deopt != NULL) {
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
          : NULL;
  compiler::Label* out_of_range = !is_truncating() ? deopt : NULL;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    LoadInt32FromMint(compiler, value, out, temp, out_of_range);
  } else if (!CanDeoptimize()) {
    compiler::Label done;
    __ SmiUntag(out, value, &done);
    LoadInt32FromMint(compiler, value, out, kNoRegister, NULL);
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
    case SimdOpInstr::kFloat32x4ShuffleX:
      __ vcvtds(result.d(0), value.s(0));
      break;
    case SimdOpInstr::kFloat32x4ShuffleY:
      __ vcvtds(result.d(0), value.s(1));
      break;
    case SimdOpInstr::kFloat32x4ShuffleZ:
      __ vcvtds(result.d(0), value.s(2));
      break;
    case SimdOpInstr::kFloat32x4ShuffleW:
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

DEFINE_EMIT(Simd32x4ToSimd32x4Convertion, (SameAsFirstInput, QRegister left)) {
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

// Low (< 7) Q registers are needed for the vcvtsd instruction.
// TODO(dartbug.com/30953) support register range constraints in the regalloc.
DEFINE_EMIT(Float32x4ToFloat64x2, (FixedQRegisterView<Q6> r, QRegisterView q)) {
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
  CASE(Float32x4ShuffleX)                                                      \
  CASE(Float32x4ShuffleY)                                                      \
  CASE(Float32x4ShuffleZ)                                                      \
  CASE(Float32x4ShuffleW)                                                      \
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
  ____(Simd32x4ToSimd32x4Convertion)                                           \
  SIMPLE(Float32x4Clamp)                                                       \
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
  return NULL;
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
    const DRegister val = EvenDRegisterOf(locs()->in(0).fpu_reg());
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
    __ vsqrtd(result, val);
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    const DRegister val = EvenDRegisterOf(locs()->in(0).fpu_reg());
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
    __ vmuld(result, val, val);
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
  const intptr_t is_min = (op_kind() == MethodRecognizer::kMathMin);
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
      __ mvn(result, compiler::Operand(value));
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
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  __ vnegd(result, value);
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
  return NULL;
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  __ LoadDFromOffset(DTMP, value_obj,
                     compiler::target::Double::value_offset() - kHeapObjectTag);

  compiler::Label done, do_call;
  // First check for NaN. Checking for minint after the conversion doesn't work
  // on ARM because vcvtid gives 0 for NaN.
  __ vcmpd(DTMP, DTMP);
  __ vmstat();
  __ b(&do_call, VS);

  __ vcvtid(STMP, DTMP);
  __ vmovrs(result, STMP);
  // Overflow is signaled with minint.

  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(result, 0xC0000000);
  __ SmiTag(result, PL);
  __ b(&done, PL);

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
    __ CallRuntime(instr->TargetFunction(), kInputCount);
  } else {
    // If the ABI is not "hardfp", then we have to move the double arguments
    // to the integer registers, and take the results from the integer
    // registers.
    __ vmovrrd(R0, R1, D0);
    __ vmovrrd(R2, R3, D1);
    __ CallRuntime(instr->TargetFunction(), kInputCount);
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
    __ CallRuntime(TargetFunction(), InputCount());
  } else {
    // If the ABI is not "hardfp", then we have to move the double arguments
    // to the integer registers, and take the results from the integer
    // registers.
    __ vmovrrd(R0, R1, D0);
    __ vmovrrd(R2, R3, D1);
    __ CallRuntime(TargetFunction(), InputCount());
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

  ASSERT(TargetCPUFeatures::can_divide());
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
  compiler::Label* deopt = compiler->AddDeoptStub(
      deopt_id(), ICData::kDeoptCheckSmi, licm_hoisted_ ? ICData::kHoisted : 0);
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
                                   PcDescriptorsLayout::kOther, locs(),
                                   extended_env);
    CheckNullInstr::AddMetadataForRuntimeCall(this, compiler);
    return;
  }

  ThrowErrorSlowPathCode* slow_path =
      new NullErrorSlowPath(this, compiler->CurrentTryIndex());
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
  flags |= licm_hoisted_ ? ICData::kHoisted : 0;
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

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
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
      // Compute 64-bit a * b as:
      //     a_l * b_l + (a_h * b_l + a_l * b_h) << 32
      Register temp = locs()->temp(0).reg();
      __ mul(temp, left_lo, right_hi);
      __ mla(out_hi, left_hi, right_lo, temp);
      __ umull(out_lo, temp, left_lo, right_lo);
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
  ShiftInt64OpSlowPath(ShiftInt64OpInstr* instruction, intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry,
                               try_index) {}

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
    __ StoreToOffset(
        right_lo, THR,
        compiler::target::Thread::unboxed_int64_runtime_arg_offset());
    __ StoreToOffset(
        right_hi, THR,
        compiler::target::Thread::unboxed_int64_runtime_arg_offset() +
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
    ShiftInt64OpSlowPath* slow_path = NULL;
    if (!IsShiftCountInRange()) {
      slow_path =
          new (Z) ShiftInt64OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);
      __ CompareImmediate(right_hi, 0);
      __ b(slow_path->entry_label(), NE);
      __ CompareImmediate(right_lo, kShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftInt64ByRegister(compiler, op_kind(), out_lo, out_hi, left_lo,
                             left_hi, right_lo);

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
  ShiftUint32OpSlowPath(ShiftUint32OpInstr* instruction, intptr_t try_index)
      : ThrowErrorSlowPathCode(instruction,
                               kArgumentErrorUnboxedInt64RuntimeEntry,
                               try_index) {}

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
    __ StoreToOffset(
        right_lo, THR,
        compiler::target::Thread::unboxed_int64_runtime_arg_offset());
    __ StoreToOffset(
        right_hi, THR,
        compiler::target::Thread::unboxed_int64_runtime_arg_offset() +
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
    ShiftUint32OpSlowPath* slow_path = NULL;
    if (!IsShiftCountInRange(kUint32ShiftCountLimit)) {
      slow_path =
          new (Z) ShiftUint32OpSlowPath(this, compiler->CurrentTryIndex());
      compiler->AddSlowPathCode(slow_path);

      __ CompareImmediate(right_hi, 0);
      __ b(slow_path->entry_label(), NE);
      __ CompareImmediate(right_lo, kUint32ShiftCountLimit);
      __ b(slow_path->entry_label(), HI);
    }

    EmitShiftUint32ByRegister(compiler, op_kind(), out, left, right_lo);

    if (slow_path != NULL) {
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
      __ mvn(out_lo, compiler::Operand(left_lo));
      __ mvn(out_hi, compiler::Operand(left_hi));
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

  __ mvn(out, compiler::Operand(left));
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

  // Offset is relative to entry pc.
  const intptr_t entry_to_pc_offset = __ CodeSize() + Instr::kPCReadOffset;
  __ mov(target_address_reg, compiler::Operand(PC));
  __ AddImmediate(target_address_reg, -entry_to_pc_offset);
  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  compiler::Operand offset_opr =
      (offset()->definition()->representation() == kTagged)
          ? compiler::Operand(offset_reg, ASR, kSmiTagSize)
          : compiler::Operand(offset_reg);
  __ add(target_address_reg, target_address_reg, offset_opr);

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
  if ((constant != NULL) && !left()->IsSingleUse()) {
    locs->set_in(0, Location::RequiresRegister());
  } else {
    locs->set_in(0, LocationRegisterOrConstant(left()));
  }

  constant = right()->definition()->AsConstant();
  if ((constant != NULL) && !right()->IsSingleUse()) {
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

  if (value()->Type()->ToCid() == kBoolCid) {
    __ eor(
        result, input,
        compiler::Operand(compiler::target::ObjectAlignment::kBoolValueMask));
  } else {
    __ LoadObject(result, Bool::True());
    __ cmp(result, compiler::Operand(input));
    __ LoadObject(result, Bool::False(), EQ);
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

#endif  // defined(TARGET_ARCH_ARM)
