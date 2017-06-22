// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/intermediate_language.h"

#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/instructions.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0.
LocationSummary* Instruction::MakeCallSummary(Zone* zone) {
  LocationSummary* result =
      new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(R0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::AnyOrConstant(value()));
  return locs;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where PushArgument is handled by BindInstr::EmitNativeCode.
  if (compiler->is_optimizing()) {
    Location value = locs()->in(0);
    if (value.IsRegister()) {
      __ Push(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      const intptr_t value_offset = value.ToStackSlotOffset();
      __ LoadFromOffset(kWord, IP, value.base_reg(), value_offset);
      __ Push(IP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->in(0).reg();
  ASSERT(result == R0);

  if (compiler->intrinsic_mode()) {
    // Intrinsics don't have a frame.
    __ Ret();
    return;
  }

#if defined(DEBUG)
  Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ sub(R2, SP, Operand(FP));
  __ CompareImmediate(R2, fp_sp_dist);
  __ b(&stack_ok, EQ);
  __ bkpt(0);
  __ Bind(&stack_ok);
#endif
  ASSERT(__ constant_pool_allowed());
  __ LeaveDartFrame();  // Disallows constant pool use.
  __ Ret();
  // This ReturnInstr may be emitted out of order by the optimizer. The next
  // block may be a target expecting a properly set constant pool pointer.
  __ set_constant_pool_allowed(true);
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQ:
      return NE;
    case NE:
      return EQ;
    case LT:
      return GE;
    case LE:
      return GT;
    case GT:
      return LE;
    case GE:
      return LT;
    case CC:
      return CS;
    case LS:
      return HI;
    case HI:
      return LS;
    case CS:
      return CC;
    case VC:
      return VS;
    case VS:
      return VC;
    default:
      UNREACHABLE();
      return EQ;
  }
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
  __ eor(result, result, Operand(result));

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
      true_condition = NegateCondition(true_condition);
    }
  } else {
    if (true_value == 0) {
      // Swap values so that false_value is zero.
      intptr_t temp = true_value;
      true_value = false_value;
      false_value = temp;
    } else {
      true_condition = NegateCondition(true_condition);
    }
  }

  __ mov(result, Operand(1), true_condition);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ Lsl(result, result, Operand(shift + kSmiTagSize));
  } else {
    __ sub(result, result, Operand(1));
    const int32_t val = Smi::RawValue(true_value) - Smi::RawValue(false_value);
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
  summary->set_in(0, Location::RegisterLocation(R0));  // Function.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
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
  __ ldr(CODE_REG, FieldAddress(R0, Function::code_offset()));
  __ ldr(R2, FieldAddress(R0, Function::entry_point_offset()));

  // R2: instructions entry point.
  // R9: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ LoadImmediate(R9, 0);
  __ blx(R2);
  compiler->RecordSafepoint(locs());
  compiler->EmitCatchEntryState();
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after);
  }
  // Add deoptimization continuation point after the call and before the
  // arguments are removed.
  // In optimized code this descriptor is needed for exception handling.
  compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after,
                                 token_pos());
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  __ LoadFromOffset(kWord, result, FP, local().index() * kWordSize);
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
  __ StoreToOffset(kWord, value, FP, local().index() * kWordSize);
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


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = (representation_ == kUnboxedInt32) ? 0 : 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation_ == kUnboxedInt32) {
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
    switch (representation_) {
      case kUnboxedDouble:
        if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0) &&
            TargetCPUFeatures::neon_supported()) {
          const QRegister dst = locs()->out(0).fpu_reg();
          __ veorq(dst, dst, dst);
        } else {
          const DRegister dst = EvenDRegisterOf(locs()->out(0).fpu_reg());
          const Register temp = locs()->temp(0).reg();
          __ LoadDImmediate(dst, Double::Cast(value()).value(), temp);
        }
        break;
      case kUnboxedInt32:
        __ LoadImmediate(locs()->out(0).reg(), Smi::Cast(value()).Value());
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Value.
  summary->set_in(1, Location::RegisterLocation(R2));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(R1));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


static void EmitAssertBoolean(Register reg,
                              TokenPosition token_pos,
                              intptr_t deopt_id,
                              LocationSummary* locs,
                              FlowGraphCompiler* compiler) {
  // Check that the type of the value is allowed in conditional context.
  // Call the runtime if the object is not bool::true or bool::false.
  ASSERT(locs->always_calls());
  Label done;

  if (Isolate::Current()->type_checks()) {
    __ CompareObject(reg, Bool::True());
    __ b(&done, EQ);
    __ CompareObject(reg, Bool::False());
    __ b(&done, EQ);
  } else {
    ASSERT(Isolate::Current()->asserts());
    __ CompareObject(reg, Object::null_instance());
    __ b(&done, NE);
  }

  __ Push(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos, deopt_id,
                                kNonBoolTypeErrorRuntimeEntry, 1, locs);
  // We should never return here.
  __ bkpt(0);
  __ Bind(&done);
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register obj = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
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
    locs->set_in(0, Location::RegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : Location::RegisterOrConstant(right()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  UNREACHABLE();
  return NULL;
}


static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         Label* value_is_smi = NULL) {
  if (value_is_smi == NULL) {
    __ mov(value_cid_reg, Operand(kSmiCid));
  }
  __ tst(value_reg, Operand(kSmiTagMask));
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
    Condition false_condition = NegateCondition(true_condition);
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
    __ cmp(left.reg(), Operand(right.reg()));
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
  __ cmp(left_lo, Operand(right_lo));
  // Compare upper if lower is equal.
  __ cmp(left_hi, Operand(right_hi), EQ);
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
  __ cmp(left_hi, Operand(right_hi));
  __ b(labels.true_label, hi_cond);
  __ b(labels.false_label, FlipCondition(hi_cond));

  // If higher words are equal, compare lower words.
  __ cmp(left_lo, Operand(right_lo));
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
  locs->set_in(1, Location::RegisterOrConstant(right()));
  return locs;
}


Condition TestSmiInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  const Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int32_t imm = reinterpret_cast<int32_t>(right.constant().raw());
    __ TestImmediate(left, imm);
  } else {
    __ tst(left, Operand(right.reg()));
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

  Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids,
                                   licm_hoisted_ ? ICData::kHoisted : 0)
          : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ tst(val_reg, Operand(kSmiTagMask));
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
    Label* target = result ? labels.false_label : labels.true_label;
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
  summary->set_in(0, Location::RegisterOrConstant(left()));
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  summary->set_in(1, summary->in(0).IsConstant()
                         ? Location::RequiresRegister()
                         : Location::RegisterOrConstant(right()));
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


LocationSummary* NativeCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return MakeCallSummary(zone);
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  const Register result = locs()->out(0).reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());
  // Pass a pointer to the first argument in R2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(
        R2, FP, (kParamEndSlotFromFp + function().NumParameters()) * kWordSize);
  } else {
    __ AddImmediate(R2, FP, kFirstLocalSlotFromFp * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry;
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const StubEntry* stub_entry;
  if (link_lazily()) {
    stub_entry = StubCode::CallBootstrapNative_entry();
    entry = NativeEntry::LinkNativeCallEntry();
  } else {
    entry = reinterpret_cast<uword>(native_c_function());
    if (is_bootstrap_native()) {
      stub_entry = StubCode::CallBootstrapNative_entry();
#if defined(USING_SIMULATOR)
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, NativeEntry::kNumArguments);
#endif
    } else if (is_auto_scope()) {
      // In the case of non bootstrap native methods the CallNativeCFunction
      // stub generates the redirection address when running under the simulator
      // and hence we do not change 'entry' here.
      stub_entry = StubCode::CallAutoScopeNative_entry();
    } else {
      // In the case of non bootstrap native methods the CallNativeCFunction
      // stub generates the redirection address when running under the simulator
      // and hence we do not change 'entry' here.
      stub_entry = StubCode::CallNoScopeNative_entry();
    }
  }
  __ LoadImmediate(R1, argc_tag);
  ExternalLabel label(entry);
  __ LoadNativeEntry(R9, &label, link_lazily() ? kPatchable : kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(token_pos(), *stub_entry,
                                    RawPcDescriptors::kOther, locs());
  } else {
    compiler->GenerateCall(token_pos(), *stub_entry, RawPcDescriptors::kOther,
                           locs());
  }
  __ Pop(result);
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

  __ ldr(result, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(result, Address(result, char_code, LSL, 1));  // Char code is a smi.
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
  __ ldr(result, FieldAddress(str, String::length_offset()));
  __ cmp(result, Operand(Smi::RawValue(1)));
  __ LoadImmediate(result, -1, NE);
  __ ldrb(result, FieldAddress(str, OneByteString::data_offset()), EQ);
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
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), token_pos(), CallFunction(),
                               args_info, locs(), ICData::Handle());
  ASSERT(locs()->out(0).reg() == R0);
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
    __ LoadFromOffset(kWord, result, obj, offset());
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ LoadFieldFromOffset(kWord, result, obj, offset());
  }
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register object = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  const AbstractType& value_type = *this->object()->Type()->ToAbstractType();
  if (CompileType::Smi().IsAssignableTo(value_type) ||
      value_type.IsTypeParameter()) {
    __ LoadTaggedClassIdMayBeSmi(result, object);
  } else {
    __ LoadClassId(result, object);
    __ SmiTag(result);
  }
}


CompileType LoadIndexedInstr::ComputeType() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
      return CompileType::Dynamic();

    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return CompileType::FromCid(kDoubleCid);
    case kTypedDataFloat32x4ArrayCid:
      return CompileType::FromCid(kFloat32x4Cid);
    case kTypedDataInt32x4ArrayCid:
      return CompileType::FromCid(kInt32x4Cid);
    case kTypedDataFloat64x2ArrayCid:
      return CompileType::FromCid(kFloat64x2Cid);

    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return CompileType::Int();

    default:
      UNREACHABLE();
      return CompileType::Dynamic();
  }
}


Representation LoadIndexedInstr::representation() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return kTagged;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
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
  if ((constant == NULL) || !Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const intptr_t base_offset =
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset = index * scale + base_offset;
  if (!Utils::IsAbsoluteUint(12, offset)) {
    return false;
  }
  if (Address::CanHoldImmediateOffset(is_load, cid, offset)) {
    *needs_base = false;
    return true;
  }

  if (Address::CanHoldImmediateOffset(is_load, cid, offset - base_offset)) {
    *needs_base = true;
    return true;
  }

  return false;
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  intptr_t kNumTemps = 0;
  if (!aligned()) {
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
      // Need register <= Q7 for float operations.
      // TODO(fschneider): Add a register policy to specify a subset of
      // registers.
      locs->set_out(0, Location::FpuRegisterLocation(Q7));
    } else {
      locs->set_out(0, Location::RequiresFpuRegister());
    }
  } else if (representation() == kUnboxedUint32) {
    ASSERT(class_id() == kTypedDataUint32ArrayCid);
    locs->set_out(0, Location::RequiresRegister());
  } else if (representation() == kUnboxedInt32) {
    ASSERT(class_id() == kTypedDataInt32ArrayCid);
    locs->set_out(0, Location::RequiresRegister());
  } else {
    ASSERT(representation() == kTagged);
    locs->set_out(0, Location::RequiresRegister());
  }
  if (!aligned()) {
    locs->set_temp(0, Location::RequiresRegister());
    if (representation() == kUnboxedDouble) {
      locs->set_temp(1, Location::RequiresRegister());
    }
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register address = aligned() ? kNoRegister : locs()->temp(0).reg();

  Address element_address(kNoRegister);
  if (aligned()) {
    element_address = index.IsRegister()
                          ? __ ElementAddressForRegIndex(
                                true,  // Load.
                                IsExternal(), class_id(), index_scale(), array,
                                index.reg())
                          : __ ElementAddressForIntIndex(
                                true,  // Load.
                                IsExternal(), class_id(), index_scale(), array,
                                Smi::Cast(index.constant()).Value(),
                                IP);  // Temp register.
    // Warning: element_address may use register IP as base.
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(address,
                                       true,  // Load.
                                       IsExternal(), class_id(), index_scale(),
                                       array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(address,
                                       true,  // Load.
                                       IsExternal(), class_id(), index_scale(),
                                       array,
                                       Smi::Cast(index.constant()).Value());
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
          __ vmovsr(EvenSRegisterOf(dresult0), value);
          __ AddImmediate(address, address, 4);
          __ LoadWordUnaligned(value, address, TMP);
          __ vmovsr(OddSRegisterOf(dresult0), value);
        }
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        ASSERT(element_address.Equals(Address(IP)));
        ASSERT(aligned());
        __ vldmd(IA, IP, dresult0, 2);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if ((representation() == kUnboxedUint32) ||
      (representation() == kUnboxedInt32)) {
    Register result = locs()->out(0).reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        ASSERT(representation() == kUnboxedInt32);
        if (aligned()) {
          __ ldr(result, element_address);
        } else {
          __ LoadWordUnaligned(result, address, TMP);
        }
        break;
      case kTypedDataUint32ArrayCid:
        ASSERT(representation() == kUnboxedUint32);
        if (aligned()) {
          __ ldr(result, element_address);
        } else {
          __ LoadWordUnaligned(result, address, TMP);
        }
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  ASSERT(representation() == kTagged);

  const Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      ASSERT(aligned());
      __ ldrsb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(index_scale() == 1);
      ASSERT(aligned());
      __ ldrb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      if (aligned()) {
        __ ldrsh(result, element_address);
      } else {
        __ LoadHalfWordUnaligned(result, address, TMP);
      }
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      if (aligned()) {
        __ ldrh(result, element_address);
      } else {
        __ LoadHalfWordUnsignedUnaligned(result, address, TMP);
      }
      __ SmiTag(result);
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ ldr(result, element_address);
      break;
  }
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) return kTagged;            // Index is a smi.
  ASSERT(idx == 2);
  switch (class_id_) {
    case kArrayCid:
    case kOneByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      return kTagged;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
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
  LocationSummary* locs;

  bool needs_base = false;
  intptr_t kNumTemps = 0;
  if (CanBeImmediateIndex(index(), class_id(), IsExternal(),
                          false,  // Store.
                          &needs_base)) {
    if (!aligned()) {
      kNumTemps += 2;
    } else if (needs_base) {
      kNumTemps += 1;
    }

    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    if (!aligned()) {
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
                          ? Location::WritableRegister()
                          : Location::RegisterOrConstant(value()));
      break;
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataFloat32ArrayCid:
      // Need low register (<= Q7).
      locs->set_in(2, Location::FpuRegisterLocation(Q7));
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
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register temp =
      (locs()->temp_count() > 0) ? locs()->temp(0).reg() : kNoRegister;
  const Register temp2 =
      (locs()->temp_count() > 1) ? locs()->temp(1).reg() : kNoRegister;

  Address element_address(kNoRegister);
  if (aligned()) {
    element_address = index.IsRegister()
                          ? __ ElementAddressForRegIndex(
                                false,  // Store.
                                IsExternal(), class_id(), index_scale(), array,
                                index.reg())
                          : __ ElementAddressForIntIndex(
                                false,  // Store.
                                IsExternal(), class_id(), index_scale(), array,
                                Smi::Cast(index.constant()).Value(), temp);
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(temp,
                                       false,  // Store.
                                       IsExternal(), class_id(), index_scale(),
                                       array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(temp,
                                       false,  // Store.
                                       IsExternal(), class_id(), index_scale(),
                                       array,
                                       Smi::Cast(index.constant()).Value());
    }
  }

  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        const Register value = locs()->in(2).reg();
        __ StoreIntoObject(array, element_address, value);
      } else if (locs()->in(2).IsConstant()) {
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
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ LoadImmediate(IP, static_cast<int8_t>(constant.Value()));
        __ strb(IP, element_address);
      } else {
        const Register value = locs()->in(2).reg();
        __ SmiUntag(IP, value);
        __ strb(IP, element_address);
      }
      break;
    }
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        intptr_t value = constant.Value();
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
        __ LoadImmediate(IP, 0x1FE);  // Smi 0xFF.
        __ cmp(value, Operand(IP));   // Compare Smi value and smi 0xFF.
        // Clamp to 0x00 or 0xFF respectively.
        __ mov(IP, Operand(0), LE);      // IP = value <= 0x1FE ? 0 : 0x1FE.
        __ mov(IP, Operand(value), LS);  // IP = value in range ? value : IP.
        __ SmiUntag(IP);
        __ strb(IP, element_address);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      const Register value = locs()->in(2).reg();
      __ SmiUntag(IP, value);
      if (aligned()) {
        __ strh(IP, element_address);
      } else {
        __ StoreHalfWordUnaligned(IP, temp, temp2);
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
      ASSERT(element_address.Equals(Address(index.reg())));
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
  ASSERT(sizeof(classid_t) == kInt16Size);

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(
          deopt_id(),
          "GuardFieldClassInstr: field state changed while compiling");
    }
    ASSERT(!compiler->is_optimizing());
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

  Label ok, fail_label;

  Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(field_reg,
                                           Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ ldrh(IP, field_cid_operand);
      __ cmp(value_cid_reg, Operand(IP));
      __ b(&ok, EQ);
      __ ldrh(IP, field_nullability_operand);
      __ cmp(value_cid_reg, Operand(IP));
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

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ b(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ ldrh(IP, FieldAddress(field_reg, Field::guarded_cid_offset()));
      __ CompareImmediate(IP, kDynamicCid);
      __ b(&ok, EQ);

      __ Push(field_reg);
      __ Push(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Field's guarded class id is fixed by value's class id is not known.
      __ tst(value_reg, Operand(kSmiTagMask));

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
    } else {
      // Both value's and field's class id is known.
      ASSERT((value_cid != field_cid) && (value_cid != nullability));
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
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(
          deopt_id(),
          "GuardFieldLengthInstr: field state changed while compiling");
    }
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();
    const Register offset_reg = locs()->temp(1).reg();
    const Register length_reg = locs()->temp(2).reg();

    Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    __ ldrsb(
        offset_reg,
        FieldAddress(field_reg,
                     Field::guarded_list_length_in_object_offset_offset()));
    __ ldr(length_reg,
           FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ tst(offset_reg, Operand(offset_reg));
    __ b(&ok, MI);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ ldr(IP, Address(value_reg, offset_reg));
    __ cmp(length_reg, Operand(IP));

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
           FieldAddress(value_reg,
                        field().guarded_list_length_in_object_offset()));
    __ CompareImmediate(length_reg,
                        Smi::RawValue(field().guarded_list_length()));
    __ b(deopt, NE);
  }
}


class BoxAllocationSlowPath : public SlowPathCode {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : instruction_(instruction), cls_(cls), result_(result) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s", instruction_->DebugName(),
                 String::Handle(cls_.ScrubbedName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::GetAllocationStubForClass(cls_));
    const StubEntry stub_entry(stub);

    LocationSummary* locs = instruction_->locs();

    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(TokenPosition::kNoSource,  // No token position.
                           stub_entry, RawPcDescriptors::kOther, locs);
    compiler->AddStubCallTarget(stub);
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
  Instruction* instruction_;
  const Class& cls_;
  const Register result_;
};


LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const bool might_box = (representation() == kTagged) && !can_pack_into_smi();
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = might_box ? 1 : 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      might_box ? LocationSummary::kCallOnSlowPath : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());

  if (might_box) {
    summary->set_temp(0, Location::RequiresRegister());
  }

  if (representation() == kUnboxedMint) {
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

  Address element_address = __ ElementAddressForRegIndex(
      true, IsExternal(), class_id(), index_scale(), str, index.reg());
  // Warning: element_address may use register IP as base.

  if (representation() == kUnboxedMint) {
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
        __ eor(result2, result2, Operand(result2));
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        ASSERT(element_count() == 2);
        __ ldr(result1, element_address);
        __ eor(result2, result2, Operand(result2));
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

      Label done;
      __ TestImmediate(value, 0xC0000000);
      __ b(&done, EQ);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                      result, temp);
      __ eor(temp, temp, Operand(temp));
      __ StoreToOffset(kWord, value, result,
                       Mint::value_offset() - kHeapObjectTag);
      __ StoreToOffset(kWord, temp, result,
                       Mint::value_offset() - kHeapObjectTag + kWordSize);
      __ Bind(&done);
    }
  }
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (IsUnboxedStore() && opt) ? 2 : ((IsPotentialUnboxedStore()) ? 3 : 0);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      ((IsUnboxedStore() && opt && is_initialization()) ||
                       IsPotentialUnboxedStore())
                          ? LocationSummary::kCallOnSlowPath
                          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier() ? Location::WritableRegister()
                                                : Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, opt ? Location::RequiresFpuRegister()
                             : Location::FpuRegisterLocation(Q1));
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                           ? Location::WritableRegister()
                           : Location::RegisterOrConstant(value()));
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
  Label done;
  __ ldr(box_reg, FieldAddress(instance_reg, offset));
  __ CompareObject(box_reg, Object::null_object());
  __ b(&done, NE);

  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);

  __ MoveRegister(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp);
  __ Bind(&done);
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);

  Label skip_store;

  const Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    const DRegister value = EvenDRegisterOf(locs()->in(1).fpu_reg());
    const Register temp = locs()->temp(0).reg();
    const Register temp2 = locs()->temp(1).reg();
    const intptr_t cid = field().UnboxedFieldCid();

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
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
    } else {
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes_));
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ StoreDToOffset(value, temp, Double::value_offset() - kHeapObjectTag);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ StoreMultipleDToOffset(value, 2, temp,
                                  Float32x4::value_offset() - kHeapObjectTag);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ StoreMultipleDToOffset(value, 2, temp,
                                  Float64x2::value_offset() - kHeapObjectTag);
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

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));

    __ ldrh(temp2, FieldAddress(temp, Field::is_nullable_offset()));
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ ldrb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ tst(temp2, Operand(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ ldrh(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ ldrh(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

    __ ldrh(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
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
                       instance_reg, offset_in_bytes_, temp2);
      __ CopyDoubleField(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler, this, temp, compiler->float32x4_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ CopyFloat32x4Field(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler, this, temp, compiler->float64x2_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ CopyFloat64x2Field(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    const Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, value_reg,
                             CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes_,
                                        locs()->in(1).constant());
    } else {
      const Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes_,
                                        value_reg);
    }
  }
  __ Bind(&skip_store);
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


// When the parser is building an implicit static getter for optimization,
// it can generate a function body where deoptimization ids do not line up
// with the unoptimized code.
//
// This is safe only so long as LoadStaticFieldInstr cannot deoptimize.
void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register field = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadFieldFromOffset(kWord, result, field, Field::static_value_offset());
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  LocationSummary* locs =
      new (zone) LocationSummary(zone, 1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(temp, FieldAddress(temp, Field::static_value_offset()),
                       value, CanValueBeSmi());
  } else {
    __ StoreIntoObjectNoBarrier(
        temp, FieldAddress(temp, Field::static_value_offset()), value);
  }
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Instance.
  summary->set_in(1, Location::RegisterLocation(R2));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(R1));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R0);  // Value.
  ASSERT(locs()->in(1).reg() == R2);  // Instantiator type arguments.
  ASSERT(locs()->in(2).reg() == R1);  // Function type arguments.

  compiler->GenerateInstanceOf(token_pos(), deopt_id(), type(), locs());
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
                                  Label* slow_path,
                                  Label* done) {
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
      R0, FieldAddress(R0, Array::type_arguments_offset()), kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(R0, FieldAddress(R0, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R3: new object end address.
  // R6: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R8: null
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(RawArray);
    __ LoadObject(R8, Object::null_object());
    if (num_elements >= 2) {
      __ mov(R9, Operand(R8));
    } else {
#if defined(DEBUG)
      // Clobber R9 with an invalid pointer.
      __ LoadImmediate(R9, 0x1);
#endif  // DEBUG
    }
    __ AddImmediate(R6, R0, sizeof(RawArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kWordSize)) {
      __ InitializeFieldsNoBarrierUnrolled(R0, R6, 0, num_elements * kWordSize,
                                           R8, R9);
    } else {
      __ InitializeFieldsNoBarrier(R0, R6, R3, R8, R9);
    }
  }
  __ b(done);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register kLengthReg = R2;
  const Register kElemTypeReg = R1;
  const Register kResultReg = R0;

  ASSERT(locs()->in(kElementTypePos).reg() == kElemTypeReg);
  ASSERT(locs()->in(kLengthPos).reg() == kLengthReg);

  if (compiler->is_optimizing() && !FLAG_precompiled_mode &&
      num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object());  // Make room for the result.
      __ Push(kLengthReg);                   // length.
      __ Push(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                    kAllocateArrayRuntimeEntry, 2, locs());
      __ Drop(2);
      __ Pop(kResultReg);
      __ Bind(&done);
      return;
    }
  }
  const Code& stub = Code::ZoneHandle(compiler->zone(),
                                      StubCode::AllocateArray_entry()->code());
  compiler->AddStubCallTarget(stub);
  compiler->GenerateCallWithDeopt(token_pos(), deopt_id(),
                                  *StubCode::AllocateArray_entry(),
                                  RawPcDescriptors::kOther, locs());
  ASSERT(locs()->out(0).reg() == kResultReg);
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 : ((IsPotentialUnboxedLoad()) ? 3 : 0);

  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, (opt && !IsPotentialUnboxedLoad())
                                       ? LocationSummary::kNoCall
                                       : LocationSummary::kCallOnSlowPath);

  locs->set_in(0, Location::RequiresRegister());

  if (IsUnboxedLoad() && opt) {
    locs->set_temp(0, Location::RequiresRegister());
  } else if (IsPotentialUnboxedLoad()) {
    locs->set_temp(0, opt ? Location::RequiresFpuRegister()
                          : Location::FpuRegisterLocation(Q1));
    locs->set_temp(1, Location::RequiresRegister());
    locs->set_temp(2, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);

  const Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
    const Register temp = locs()->temp(0).reg();
    __ LoadFieldFromOffset(kWord, temp, instance_reg, offset_in_bytes());
    const intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ LoadDFromOffset(result, temp,
                           Double::value_offset() - kHeapObjectTag);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        __ LoadMultipleDFromOffset(result, 2, temp,
                                   Float32x4::value_offset() - kHeapObjectTag);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2LoadFieldInstr");
        __ LoadMultipleDFromOffset(result, 2, temp,
                                   Float64x2::value_offset() - kHeapObjectTag);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  const Register result_reg = locs()->out(0).reg();
  if (IsPotentialUnboxedLoad()) {
    const DRegister value = EvenDRegisterOf(locs()->temp(0).fpu_reg());
    const Register temp = locs()->temp(1).reg();
    const Register temp2 = locs()->temp(2).reg();

    Label load_pointer;
    Label load_double;
    Label load_float32x4;
    Label load_float64x2;

    __ LoadObject(result_reg, Field::ZoneHandle(field()->Original()));

    FieldAddress field_cid_operand(result_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result_reg,
                                           Field::is_nullable_offset());

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
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyDoubleField(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result_reg, temp);
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyFloat32x4Field(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result_reg, temp);
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyFloat64x2Field(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFieldFromOffset(kWord, result_reg, instance_reg, offset_in_bytes());
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R1));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(R0));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(R0));
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
  __ PushList((1 << instantiator_type_args_reg) |
              (1 << function_type_args_reg));
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeRuntimeEntry, 3, locs());
  __ Drop(3);          // Drop 2 type argument vectors and uninstantiated type.
  __ Pop(result_reg);  // Pop instantiated type.
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R1));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(R0));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Register instantiator_type_args_reg = locs()->in(0).reg();
  const Register function_type_args_reg = locs()->in(1).reg();
  const Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_type_args_reg == R1);
  ASSERT(function_type_args_reg == R0);

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If both the instantiator and function type arguments are null and if the
  // type argument vector instantiated from null becomes a vector of dynamic,
  // then use null as the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawWhenInstantiatedFromRaw(len)) {
    __ LoadObject(IP, Object::null_object());
    __ cmp(instantiator_type_args_reg, Operand(IP));
    __ cmp(function_type_args_reg, Operand(IP), EQ);
    __ b(&type_arguments_instantiated, EQ);
    ASSERT(function_type_args_reg == result_reg);
  }

  // Lookup cache before calling runtime.
  // TODO(regis): Consider moving this into a shared stub to reduce
  // generated code size.
  __ LoadObject(R3, type_arguments());
  __ ldr(R3, FieldAddress(R3, TypeArguments::instantiations_offset()));
  __ AddImmediate(R3, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, next, found, slow_case;
  __ Bind(&loop);
  __ ldr(R2, Address(R3, 0 * kWordSize));  // Cached instantiator type args.
  __ cmp(R2, Operand(instantiator_type_args_reg));
  __ b(&next, NE);
  __ ldr(IP, Address(R3, 1 * kWordSize));  // Cached function type args.
  __ cmp(IP, Operand(function_type_args_reg));
  __ b(&found, EQ);
  __ Bind(&next);
  __ AddImmediate(R3, StubCode::kInstantiationSizeInWords * kWordSize);
  __ CompareImmediate(R2, Smi::RawValue(StubCode::kNoInstantiator));
  __ b(&loop, NE);
  __ b(&slow_case);
  __ Bind(&found);
  __ ldr(result_reg, Address(R3, 2 * kWordSize));  // Cached instantiated args.
  __ b(&type_arguments_instantiated);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type_arguments());
  __ PushList((1 << instantiator_type_args_reg) |
              (1 << function_type_args_reg));
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry, 3,
                                locs());
  __ Drop(3);          // Drop 2 type argument vectors and uninstantiated args.
  __ Pop(result_reg);  // Pop instantiated type arguments.
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


class AllocateContextSlowPath : public SlowPathCode {
 public:
  explicit AllocateContextSlowPath(
      AllocateUninitializedContextInstr* instruction)
      : instruction_(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);

    __ LoadImmediate(R1, instruction_->num_context_variables());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::AllocateContext_entry()->code());
    compiler->AddStubCallTarget(stub);
    compiler->GenerateCall(instruction_->token_pos(),
                           *StubCode::AllocateContext_entry(),
                           RawPcDescriptors::kOther, locs);
    ASSERT(instruction_->locs()->out(0).reg() == R0);
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

 private:
  AllocateUninitializedContextInstr* instruction_;
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
  __ str(temp0, FieldAddress(result, Context::num_variables_offset()));

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

  __ LoadImmediate(R1, num_context_variables());
  compiler->GenerateCall(token_pos(), *StubCode::AllocateContext_entry(),
                         RawPcDescriptors::kOther, locs());
}


LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_temp(0, Location::RegisterLocation(R1));
  return locs;
}


void InitStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label call_runtime, no_call;

  __ ldr(temp, FieldAddress(field, Field::static_value_offset()));
  __ CompareObject(temp, Object::sentinel());
  __ b(&call_runtime, EQ);

  __ CompareObject(temp, Object::transition_sentinel());
  __ b(&no_call, NE);

  __ Bind(&call_runtime);
  __ PushObject(Object::null_object());  // Make room for (unused) result.
  __ Push(field);
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInitStaticFieldRuntimeEntry, 1, locs());
  __ Drop(2);  // Remove argument and result placeholder.
  __ Bind(&no_call);
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register context_value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ PushObject(Object::null_object());  // Make room for the result.
  __ Push(context_value);
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kCloneContextRuntimeEntry, 1, locs());
  __ Drop(1);      // Remove argument.
  __ Pop(result);  // Get result (cloned context).
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNREACHABLE();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(), try_index(),
                                compiler->assembler()->CodeSize(),
                                handler_token_pos(), is_generated(),
                                catch_handler_types_, needs_stacktrace());
  // On lazy deoptimization we patch the optimized code here to enter the
  // deoptimization stub.
  const intptr_t deopt_id = Thread::ToDeoptAfter(GetDeoptId());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id);
  } else {
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id,
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

  // Auxiliary variables introduced by the try catch can be captured if we are
  // inside a function with yield/resume points. In this case we first need
  // to restore the context to match the context at entry into the closure.
  if (should_restore_closure_context()) {
    const ParsedFunction& parsed_function = compiler->parsed_function();
    ASSERT(parsed_function.function().IsClosureFunction());
    LocalScope* scope = parsed_function.node_sequence()->scope();

    LocalVariable* closure_parameter = scope->VariableAt(0);
    ASSERT(!closure_parameter->is_captured());
    __ LoadFromOffset(kWord, CTX, FP, closure_parameter->index() * kWordSize);
    __ LoadFieldFromOffset(kWord, CTX, CTX, Closure::context_offset());

    const intptr_t context_index =
        parsed_function.current_context_var()->index();
    __ StoreToOffset(kWord, CTX, FP, context_index * kWordSize);
  }

  // Initialize exception and stack trace variables.
  if (exception_var().is_captured()) {
    ASSERT(stacktrace_var().is_captured());
    __ StoreIntoObjectOffset(CTX,
                             Context::variable_offset(exception_var().index()),
                             kExceptionObjectReg);
    __ StoreIntoObjectOffset(CTX,
                             Context::variable_offset(stacktrace_var().index()),
                             kStackTraceObjectReg);
  } else {
    __ StoreToOffset(kWord, kExceptionObjectReg, FP,
                     exception_var().index() * kWordSize);
    __ StoreToOffset(kWord, kStackTraceObjectReg, FP,
                     stacktrace_var().index() * kWordSize);
  }
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
      const Register value = instruction_->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(value, Thread::kOsrRequest);
      __ str(value, Address(THR, Thread::stack_overflow_flags_offset()));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(
        instruction_->token_pos(), instruction_->deopt_id(),
        kStackOverflowRuntimeEntry, 0, instruction_->locs());

    if (compiler->isolate()->use_osr() && !compiler->is_optimizing() &&
        instruction_->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     TokenPosition::kNoSource);
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(Isolate::Current()->use_osr());
    return &osr_entry_label_;
  }

 private:
  CheckStackOverflowInstr* instruction_;
  Label osr_entry_label_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ ldr(IP, Address(THR, Thread::stack_limit_offset()));
  __ cmp(SP, Operand(IP));
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ ldr(temp, FieldAddress(temp, Function::usage_counter_offset()));
    __ CompareImmediate(temp, threshold);
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
  Label* deopt = shift_left->CanDeoptimize()
                     ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                              ICData::kDeoptBinarySmiOp)
                     : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow (preserve left).
      __ Lsl(IP, left, Operand(value));
      __ cmp(left, Operand(IP, ASR, value));
      __ b(deopt, NE);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ Lsl(result, left, Operand(value));
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
        __ cmp(right, Operand(0));
        __ b(deopt, MI);
        __ mov(result, Operand(0));
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ cmp(right, Operand(reinterpret_cast<int32_t>(Smi::New(max_right))));
        __ b(deopt, CS);
      }
      __ SmiUntag(IP, right);
      __ Lsl(result, left, IP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmp(right, Operand(0));
        __ b(deopt, MI);
      }

      __ cmp(right, Operand(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ mov(result, Operand(0), CS);
      __ SmiUntag(IP, right, CC);  // SmiUntag right into IP if CC.
      __ Lsl(result, left, IP, CC);
    } else {
      __ SmiUntag(IP, right);
      __ Lsl(result, left, IP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ cmp(right, Operand(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ b(deopt, CS);
    }
    // Left is not a constant.
    // Check if count too large for handling it inlined.
    __ SmiUntag(IP, right);
    // Overflow test (preserve left, right, and IP);
    const Register temp = locs.temp(0).reg();
    __ Lsl(temp, left, IP);
    __ cmp(left, Operand(temp, ASR, IP));
    __ b(deopt, NE);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ Lsl(result, left, IP);
  }
}


class CheckedSmiSlowPath : public SlowPathCode {
 public:
  CheckedSmiSlowPath(CheckedSmiOpInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    Register result = locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (instruction_->env() != NULL) {
      Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
      compiler->pending_deoptimization_env_ = env;
    }
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    const String& selector =
        String::Handle(instruction_->call()->ic_data()->target_name());
    const Array& argument_names =
        Array::Handle(instruction_->call()->ic_data()->arguments_descriptor());
    compiler->EmitMegamorphicInstanceCall(
        selector, argument_names, instruction_->call()->ArgumentCount(),
        instruction_->call()->deopt_id(), instruction_->call()->token_pos(),
        locs, try_index_,
        /* slow_path_argument_count = */ 2);
    __ mov(result, Operand(R0));
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
    compiler->pending_deoptimization_env_ = NULL;
  }

 private:
  CheckedSmiOpInstr* instruction_;
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
    __ tst(left, Operand(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tst(right, Operand(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tst(left, Operand(kSmiTagMask));
  } else {
    combined_smi_check = true;
    __ orr(result, left, Operand(right));
    __ tst(result, Operand(kSmiTagMask));
  }
  __ b(slow_path->entry_label(), NE);
  switch (op_kind()) {
    case Token::kADD:
      __ adds(result, left, Operand(right));
      __ b(slow_path->entry_label(), VS);
      break;
    case Token::kSUB:
      __ subs(result, left, Operand(right));
      __ b(slow_path->entry_label(), VS);
      break;
    case Token::kMUL:
      __ SmiUntag(IP, left);
      __ smull(result, IP, IP, right);
      // IP: result bits 32..63.
      __ cmp(IP, Operand(result, ASR, 31));
      __ b(slow_path->entry_label(), NE);
      break;
    case Token::kBIT_OR:
      // Operation may be part of combined smi check.
      if (!combined_smi_check) {
        __ orr(result, left, Operand(right));
      }
      break;
    case Token::kBIT_AND:
      __ and_(result, left, Operand(right));
      break;
    case Token::kBIT_XOR:
      __ eor(result, left, Operand(right));
      break;
    case Token::kSHL:
      ASSERT(result != left);
      ASSERT(result != right);
      __ CompareImmediate(right, Smi::RawValue(Smi::kBits));
      __ b(slow_path->entry_label(), HI);

      __ SmiUntag(TMP, right);
      // Check for overflow by shifting left and shifting back arithmetically.
      // If the result is different from the original, there was overflow.
      __ Lsl(result, left, TMP);
      __ cmp(left, Operand(result, ASR, TMP));
      __ b(slow_path->entry_label(), NE);
      break;
    case Token::kSHR:
      ASSERT(result != left);
      ASSERT(result != right);
      __ CompareImmediate(right, Smi::RawValue(Smi::kBits));
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


class CheckedSmiComparisonSlowPath : public SlowPathCode {
 public:
  CheckedSmiComparisonSlowPath(CheckedSmiComparisonInstr* instruction,
                               intptr_t try_index,
                               BranchLabels labels,
                               bool merged)
      : instruction_(instruction),
        try_index_(try_index),
        labels_(labels),
        merged_(merged) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    Register result = merged_ ? locs->temp(0).reg() : locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (instruction_->env() != NULL) {
      Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
      compiler->pending_deoptimization_env_ = env;
    }
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    String& selector =
        String::Handle(instruction_->call()->ic_data()->target_name());
    Array& argument_names =
        Array::Handle(instruction_->call()->ic_data()->arguments_descriptor());
    compiler->EmitMegamorphicInstanceCall(
        selector, argument_names, instruction_->call()->ArgumentCount(),
        instruction_->call()->deopt_id(), instruction_->call()->token_pos(),
        locs, try_index_,
        /* slow_path_argument_count = */ 2);
    __ mov(result, Operand(R0));
    compiler->RestoreLiveRegisters(locs);
    compiler->pending_deoptimization_env_ = NULL;
    if (merged_) {
      __ CompareObject(result, Bool::True());
      __ b(
          instruction_->is_negated() ? labels_.false_label : labels_.true_label,
          EQ);
      __ b(instruction_->is_negated() ? labels_.true_label
                                      : labels_.false_label);
    } else {
      __ b(exit_label());
    }
  }

 private:
  CheckedSmiComparisonInstr* instruction_;
  intptr_t try_index_;
  BranchLabels labels_;
  bool merged_;
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
    __ tst(left, Operand(kSmiTagMask));                                        \
  } else if (left_cid == kSmiCid) {                                            \
    __ tst(right, Operand(kSmiTagMask));                                       \
  } else if (right_cid == kSmiCid) {                                           \
    __ tst(left, Operand(kSmiTagMask));                                        \
  } else {                                                                     \
    __ orr(temp, left, Operand(right));                                        \
    __ tst(temp, Operand(kSmiTagMask));                                        \
  }                                                                            \
  __ b(slow_path->entry_label(), NE)


void CheckedSmiComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                               BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, compiler->CurrentTryIndex(), labels,
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
      this, compiler->CurrentTryIndex(), labels,
      /* merged = */ false);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != kInvalidCondition);
  Register result = locs()->out(0).reg();
  __ LoadObject(result, Bool::True(), true_condition);
  __ LoadObject(result, Bool::False(), NegateCondition(true_condition));
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
      summary->set_temp(1, Location::RequiresFpuRegister());
    }
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  if (op_kind() == Token::kMOD) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
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
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int32_t imm = reinterpret_cast<int32_t>(constant.raw());
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
        const intptr_t value = Smi::Cast(constant).Value();
        if (deopt == NULL) {
          __ LoadImmediate(IP, value);
          __ mul(result, left, IP);
        } else {
          __ LoadImmediate(IP, value);
          __ smull(result, IP, left, IP);
          // IP: result bits 32..63.
          __ cmp(IP, Operand(result, ASR, 31));
          __ b(deopt, NE);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ mov(IP, Operand(left, ASR, 31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = locs()->temp(0).reg();
        __ add(temp, left, Operand(IP, LSR, 32 - shift_count));
        ASSERT(shift_count > 0);
        __ mov(result, Operand(temp, ASR, shift_count));
        if (value < 0) {
          __ rsb(result, result, Operand(0));
        }
        __ SmiTag(result);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(imm, &o)) {
          __ and_(result, left, o);
        } else if (Operand::CanHold(~imm, &o)) {
          __ bic(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ and_(result, left, Operand(IP));
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(imm, &o)) {
          __ orr(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ orr(result, left, Operand(IP));
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(imm, &o)) {
          __ eor(result, left, o);
        } else {
          __ LoadImmediate(IP, imm);
          __ eor(result, left, Operand(IP));
        }
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        intptr_t value = Smi::Cast(constant).Value();
        __ Asr(result, left,
               Operand(Utils::Minimum(value + kSmiTagSize, kCountLimit)));
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
        __ add(result, left, Operand(right));
      } else {
        __ adds(result, left, Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == NULL) {
        __ sub(result, left, Operand(right));
      } else {
        __ subs(result, left, Operand(right));
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
        __ cmp(IP, Operand(result, ASR, 31));
        __ b(deopt, NE);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, Operand(right));
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orr(result, left, Operand(right));
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ eor(result, left, Operand(right));
      break;
    }
    case Token::kTRUNCDIV: {
      ASSERT(TargetCPUFeatures::can_divide());
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ cmp(right, Operand(0));
        __ b(deopt, EQ);
      }
      const Register temp = locs()->temp(0).reg();
      const DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
      __ SmiUntag(temp, left);
      __ SmiUntag(IP, right);
      __ IntegerDivide(result, temp, IP, dtemp, DTMP);

      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ CompareImmediate(result, 0x40000000);
      __ b(deopt, EQ);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      ASSERT(TargetCPUFeatures::can_divide());
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ cmp(right, Operand(0));
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
      Label done;
      __ cmp(result, Operand(0));
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ cmp(right, Operand(0));
      __ sub(result, result, Operand(right), LT);
      __ add(result, result, Operand(right), GE);
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
  Label* deopt = shift_left->CanDeoptimize()
                     ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                              ICData::kDeoptBinarySmiOp)
                     : NULL;
  ASSERT(locs.in(1).IsConstant());
  const Object& constant = locs.in(1).constant();
  ASSERT(constant.IsSmi());
  // Immediate shift operation takes 5 bits for the count.
  const intptr_t kCountLimit = 0x1F;
  const intptr_t value = Smi::Cast(constant).Value();
  ASSERT((0 < value) && (value < kCountLimit));
  if (shift_left->can_overflow()) {
    // Check for overflow (preserve left).
    __ Lsl(IP, left, Operand(value));
    __ cmp(left, Operand(IP, ASR, value));
    __ b(deopt, NE);  // Overflow.
  }
  // Shift for result now we know there is no overflow.
  __ Lsl(result, left, Operand(value));
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
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
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
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t value = Smi::Cast(constant).Value();
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
          __ cmp(IP, Operand(result, ASR, 31));
          __ b(deopt, NE);
        }
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(value, &o)) {
          __ and_(result, left, o);
        } else if (Operand::CanHold(~value, &o)) {
          __ bic(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ and_(result, left, Operand(IP));
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(value, &o)) {
          __ orr(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ orr(result, left, Operand(IP));
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        Operand o;
        if (Operand::CanHold(value, &o)) {
          __ eor(result, left, o);
        } else {
          __ LoadImmediate(IP, value);
          __ eor(result, left, Operand(IP));
        }
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ Asr(result, left, Operand(Utils::Minimum(value, kCountLimit)));
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
        __ add(result, left, Operand(right));
      } else {
        __ adds(result, left, Operand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == NULL) {
        __ sub(result, left, Operand(right));
      } else {
        __ subs(result, left, Operand(right));
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
        __ cmp(IP, Operand(result, ASR, 31));
        __ b(deopt, NE);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, Operand(right));
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orr(result, left, Operand(right));
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ eor(result, left, Operand(right));
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
  Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                             licm_hoisted_ ? ICData::kHoisted : 0);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ tst(left, Operand(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tst(right, Operand(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tst(left, Operand(kSmiTagMask));
  } else {
    __ orr(IP, left, Operand(right));
    __ tst(IP, Operand(kSmiTagMask));
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
  const bool needs_temp = CanDeoptimize();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (needs_temp) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (representation() == kUnboxedMint) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}


void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedMint: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      __ LoadFieldFromOffset(kWord, result->At(0).reg(), box, ValueOffset());
      __ LoadFieldFromOffset(kWord, result->At(1).reg(), box,
                             ValueOffset() + kWordSize);
      break;
    }

    case kUnboxedDouble: {
      const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
      __ LoadDFromOffset(result, box, ValueOffset() - kHeapObjectTag);
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
    case kUnboxedMint: {
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


void UnboxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t box_cid = BoxCid();

  if (value_cid == box_cid) {
    EmitLoadFromBox(compiler);
  } else if (CanConvertSmi() && (value_cid == kSmiCid)) {
    EmitSmiConversion(compiler);
  } else {
    const Register box = locs()->in(0).reg();
    const Register temp = locs()->temp(0).reg();
    Label* deopt =
        compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptCheckClass);
    Label is_smi;

    if ((value()->Type()->ToNullableCid() == box_cid) &&
        value()->Type()->is_nullable()) {
      __ CompareObject(box, Object::null_object());
      __ b(deopt, EQ);
    } else {
      __ tst(box, Operand(kSmiTagMask));
      __ b(CanConvertSmi() ? &is_smi : deopt, EQ);
      __ CompareClassId(box, box_cid, temp);
      __ b(deopt, NE);
    }

    EmitLoadFromBox(compiler);

    if (is_smi.IsLinked()) {
      Label done;
      __ b(&done);
      __ Bind(&is_smi);
      EmitSmiConversion(compiler);
      __ Bind(&done);
    }
  }
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
    Label done;
    if (from_representation() == kUnboxedInt32) {
      __ cmp(value, Operand(out, ASR, 1));
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
      __ Asr(temp, value, Operand(kBitsPerWord - 1));
    } else {
      ASSERT(from_representation() == kUnboxedUint32);
      __ eor(temp, temp, Operand(temp));
    }
    __ StoreToOffset(kWord, value, out, Mint::value_offset() - kHeapObjectTag);
    __ StoreToOffset(kWord, temp, out,
                     Mint::value_offset() - kHeapObjectTag + kWordSize);
    __ Bind(&done);
  }
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
    __ SmiTag(out_reg, value_lo);
    return;
  }

  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register tmp = locs()->temp(0).reg();
  Register out_reg = locs()->out(0).reg();

  Label done;
  __ SmiTag(out_reg, value_lo);
  __ cmp(value_lo, Operand(out_reg, ASR, kSmiTagSize));
  __ cmp(value_hi, Operand(out_reg, ASR, 31), EQ);
  __ b(&done, EQ);

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                  out_reg, tmp);
  __ StoreToOffset(kWord, value_lo, out_reg,
                   Mint::value_offset() - kHeapObjectTag);
  __ StoreToOffset(kWord, value_hi, out_reg,
                   Mint::value_offset() - kHeapObjectTag + kWordSize);
  __ Bind(&done);
}


static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register mint,
                              Register result,
                              Register temp,
                              Label* deopt) {
  __ LoadFieldFromOffset(kWord, result, mint, Mint::value_offset());
  if (deopt != NULL) {
    __ LoadFieldFromOffset(kWord, temp, mint, Mint::value_offset() + kWordSize);
    __ cmp(temp, Operand(result, ASR, kBitsPerWord - 1));
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
  Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : NULL;
  Label* out_of_range = !is_truncating() ? deopt : NULL;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    LoadInt32FromMint(compiler, value, out, temp, out_of_range);
  } else if (!CanDeoptimize()) {
    Label done;
    __ SmiUntag(out, value, &done);
    LoadInt32FromMint(compiler, value, out, kNoRegister, NULL);
    __ Bind(&done);
  } else {
    Label done;
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
    Label done;
    // TMP <- value[0:31], result <- value[32:63]
    __ vmovrrd(TMP, temp, value);
    __ cmp(TMP, Operand(0));
    __ b(is_negated ? labels.true_label : labels.false_label, NE);

    // Mask off the sign bit.
    __ AndImmediate(temp, temp, 0x7FFFFFFF);
    // Compare with +infinity.
    __ CompareImmediate(temp, 0x7FF00000);
    return is_negated ? NE : EQ;
  }
}

LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(Zone* zone,
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


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case Token::kADD:
      __ vaddqs(result, left, right);
      break;
    case Token::kSUB:
      __ vsubqs(result, left, right);
      break;
    case Token::kMUL:
      __ vmulqs(result, left, right);
      break;
    case Token::kDIV:
      __ Vdivqs(result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(Zone* zone,
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


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister left0 = EvenDRegisterOf(left);
  const DRegister left1 = OddDRegisterOf(left);

  const DRegister right0 = EvenDRegisterOf(right);
  const DRegister right1 = OddDRegisterOf(right);

  const DRegister result0 = EvenDRegisterOf(result);
  const DRegister result1 = OddDRegisterOf(result);

  switch (op_kind()) {
    case Token::kADD:
      __ vaddd(result0, left0, right0);
      __ vaddd(result1, left1, right1);
      break;
    case Token::kSUB:
      __ vsubd(result0, left0, right0);
      __ vsubd(result1, left1, right1);
      break;
    case Token::kMUL:
      __ vmuld(result0, left0, right0);
      __ vmuld(result1, left1, right1);
      break;
    case Token::kDIV:
      __ vdivd(result0, left0, right0);
      __ vdivd(result1, left1, right1);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
  summary->set_in(0, Location::FpuRegisterLocation(Q5));
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();
  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);
  const SRegister sresult0 = EvenSRegisterOf(dresult0);
  const SRegister sresult1 = OddSRegisterOf(dresult0);
  const SRegister sresult2 = EvenSRegisterOf(dresult1);
  const SRegister sresult3 = OddSRegisterOf(dresult1);

  const DRegister dvalue0 = EvenDRegisterOf(value);
  const DRegister dvalue1 = OddDRegisterOf(value);
  const SRegister svalue0 = EvenSRegisterOf(dvalue0);
  const SRegister svalue1 = OddSRegisterOf(dvalue0);
  const SRegister svalue2 = EvenSRegisterOf(dvalue1);
  const SRegister svalue3 = OddSRegisterOf(dvalue1);

  const DRegister dtemp0 = DTMP;
  const DRegister dtemp1 = OddDRegisterOf(QTMP);

  // For some cases the vdup instruction requires fewer
  // instructions. For arbitrary shuffles, use vtbl.

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleX:
      __ vcvtds(dresult0, svalue0);
      break;
    case MethodRecognizer::kFloat32x4ShuffleY:
      __ vcvtds(dresult0, svalue1);
      break;
    case MethodRecognizer::kFloat32x4ShuffleZ:
      __ vcvtds(dresult0, svalue2);
      break;
    case MethodRecognizer::kFloat32x4ShuffleW:
      __ vcvtds(dresult0, svalue3);
      break;
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kFloat32x4Shuffle:
      if (mask_ == 0x00) {
        __ vdup(kWord, result, dvalue0, 0);
      } else if (mask_ == 0x55) {
        __ vdup(kWord, result, dvalue0, 1);
      } else if (mask_ == 0xAA) {
        __ vdup(kWord, result, dvalue1, 0);
      } else if (mask_ == 0xFF) {
        __ vdup(kWord, result, dvalue1, 1);
      } else {
        // TODO(zra): Investigate better instruction sequences for other
        // shuffle masks.
        SRegister svalues[4];

        svalues[0] = EvenSRegisterOf(dtemp0);
        svalues[1] = OddSRegisterOf(dtemp0);
        svalues[2] = EvenSRegisterOf(dtemp1);
        svalues[3] = OddSRegisterOf(dtemp1);

        __ vmovq(QTMP, value);
        __ vmovs(sresult0, svalues[mask_ & 0x3]);
        __ vmovs(sresult1, svalues[(mask_ >> 2) & 0x3]);
        __ vmovs(sresult2, svalues[(mask_ >> 4) & 0x3]);
        __ vmovs(sresult3, svalues[(mask_ >> 6) & 0x3]);
      }
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
  summary->set_in(0, Location::FpuRegisterLocation(Q4));
  summary->set_in(1, Location::FpuRegisterLocation(Q5));
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);
  const SRegister sresult0 = EvenSRegisterOf(dresult0);
  const SRegister sresult1 = OddSRegisterOf(dresult0);
  const SRegister sresult2 = EvenSRegisterOf(dresult1);
  const SRegister sresult3 = OddSRegisterOf(dresult1);

  const DRegister dleft0 = EvenDRegisterOf(left);
  const DRegister dleft1 = OddDRegisterOf(left);
  const DRegister dright0 = EvenDRegisterOf(right);
  const DRegister dright1 = OddDRegisterOf(right);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
      // TODO(zra): Investigate better instruction sequences for shuffle masks.
      SRegister left_svalues[4];
      SRegister right_svalues[4];

      left_svalues[0] = EvenSRegisterOf(dleft0);
      left_svalues[1] = OddSRegisterOf(dleft0);
      left_svalues[2] = EvenSRegisterOf(dleft1);
      left_svalues[3] = OddSRegisterOf(dleft1);
      right_svalues[0] = EvenSRegisterOf(dright0);
      right_svalues[1] = OddSRegisterOf(dright0);
      right_svalues[2] = EvenSRegisterOf(dright1);
      right_svalues[3] = OddSRegisterOf(dright1);

      __ vmovs(sresult0, left_svalues[mask_ & 0x3]);
      __ vmovs(sresult1, left_svalues[(mask_ >> 2) & 0x3]);
      __ vmovs(sresult2, right_svalues[(mask_ >> 4) & 0x3]);
      __ vmovs(sresult3, right_svalues[(mask_ >> 6) & 0x3]);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::FpuRegisterLocation(Q5));
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const DRegister dvalue0 = EvenDRegisterOf(value);
  const DRegister dvalue1 = OddDRegisterOf(value);

  const Register out = locs()->out(0).reg();
  const Register temp = locs()->temp(0).reg();

  // X lane.
  __ vmovrs(out, EvenSRegisterOf(dvalue0));
  __ Lsr(out, out, Operand(31));
  // Y lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue0));
  __ Lsr(temp, temp, Operand(31));
  __ orr(out, out, Operand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, EvenSRegisterOf(dvalue1));
  __ Lsr(temp, temp, Operand(31));
  __ orr(out, out, Operand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue1));
  __ Lsr(temp, temp, Operand(31));
  __ orr(out, out, Operand(temp, LSL, 3));
  // Tag.
  __ SmiTag(out);
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_in(3, Location::RequiresFpuRegister());
  // Low (< 7) Q registers are needed for the vcvtsd instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q0 = locs()->in(0).fpu_reg();
  const QRegister q1 = locs()->in(1).fpu_reg();
  const QRegister q2 = locs()->in(2).fpu_reg();
  const QRegister q3 = locs()->in(3).fpu_reg();
  const QRegister r = locs()->out(0).fpu_reg();

  const DRegister dr0 = EvenDRegisterOf(r);
  const DRegister dr1 = OddDRegisterOf(r);

  __ vcvtsd(EvenSRegisterOf(dr0), EvenDRegisterOf(q0));
  __ vcvtsd(OddSRegisterOf(dr0), EvenDRegisterOf(q1));
  __ vcvtsd(EvenSRegisterOf(dr1), EvenDRegisterOf(q2));
  __ vcvtsd(OddSRegisterOf(dr1), EvenDRegisterOf(q3));
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->out(0).fpu_reg();
  __ veorq(q, q, q);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dvalue0 = EvenDRegisterOf(value);

  // Convert to Float32.
  __ vcvtsd(STMP, dvalue0);

  // Splat across all lanes.
  __ vdup(kWord, result, DTMP, 0);
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Zone* zone,
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


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Equal:
      __ vceqqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4NotEqual:
      __ vceqqs(result, left, right);
      // Invert the result.
      __ vmvnq(result, result);
      break;
    case MethodRecognizer::kFloat32x4GreaterThan:
      __ vcgtqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
      __ vcgeqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4LessThan:
      __ vcgtqs(result, right, left);
      break;
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
      __ vcgeqs(result, right, left);
      break;

    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(Zone* zone,
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


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Min:
      __ vminqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4Max:
      __ vmaxqs(result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();
  const QRegister temp = locs()->temp(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Sqrt:
      __ Vsqrtqs(result, left, temp);
      break;
    case MethodRecognizer::kFloat32x4Reciprocal:
      __ Vreciprocalqs(result, left);
      break;
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
      __ VreciprocalSqrtqs(result, left);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(Zone* zone,
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


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Scale:
      __ vcvtsd(STMP, EvenDRegisterOf(left));
      __ vdup(kWord, result, DTMP, 0);
      __ vmulqs(result, result, right);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Negate:
      __ vnegqs(result, left);
      break;
    case MethodRecognizer::kFloat32x4Absolute:
      __ vabsqs(result, left);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister lower = locs()->in(1).fpu_reg();
  const QRegister upper = locs()->in(2).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();
  __ vminqs(result, left, upper);
  __ vmaxqs(result, result, lower);
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  // Low (< 7) Q registers are needed for the vmovs instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister replacement = locs()->in(0).fpu_reg();
  const QRegister value = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);
  const SRegister sresult0 = EvenSRegisterOf(dresult0);
  const SRegister sresult1 = OddSRegisterOf(dresult0);
  const SRegister sresult2 = EvenSRegisterOf(dresult1);
  const SRegister sresult3 = OddSRegisterOf(dresult1);

  __ vcvtsd(STMP, EvenDRegisterOf(replacement));
  if (result != value) {
    __ vmovq(result, value);
  }

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4WithX:
      __ vmovs(sresult0, STMP);
      break;
    case MethodRecognizer::kFloat32x4WithY:
      __ vmovs(sresult1, STMP);
      break;
    case MethodRecognizer::kFloat32x4WithZ:
      __ vmovs(sresult2, STMP);
      break;
    case MethodRecognizer::kFloat32x4WithW:
      __ vmovs(sresult3, STMP);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  if (value != result) {
    __ vmovq(result, value);
  }
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();

  const DRegister dvalue0 = EvenDRegisterOf(value);
  const DRegister dvalue1 = OddDRegisterOf(value);

  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2GetX:
      __ vmovd(dresult0, dvalue0);
      break;
    case MethodRecognizer::kFloat64x2GetY:
      __ vmovd(dresult0, dvalue1);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->out(0).fpu_reg();
  __ veorq(q, q, q);
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();

  const DRegister dvalue = EvenDRegisterOf(value);

  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);

  // Splat across all lanes.
  __ vmovd(dresult0, dvalue);
  __ vmovd(dresult1, dvalue);
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    Zone* zone,
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


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q0 = locs()->in(0).fpu_reg();
  const QRegister q1 = locs()->in(1).fpu_reg();
  const QRegister r = locs()->out(0).fpu_reg();

  const DRegister d0 = EvenDRegisterOf(q0);
  const DRegister d1 = EvenDRegisterOf(q1);

  const DRegister dr0 = EvenDRegisterOf(r);
  const DRegister dr1 = OddDRegisterOf(r);

  __ vmovd(dr0, d0);
  __ vmovd(dr1, d1);
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  // Low (< 7) Q registers are needed for the vcvtsd instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->in(0).fpu_reg();
  const QRegister r = locs()->out(0).fpu_reg();

  const DRegister dq0 = EvenDRegisterOf(q);
  const DRegister dq1 = OddDRegisterOf(q);

  const DRegister dr0 = EvenDRegisterOf(r);

  // Zero register.
  __ veorq(r, r, r);
  // Set X lane.
  __ vcvtsd(EvenSRegisterOf(dr0), dq0);
  // Set Y lane.
  __ vcvtsd(OddSRegisterOf(dr0), dq1);
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  // Low (< 7) Q registers are needed for the vcvtsd instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->in(0).fpu_reg();
  const QRegister r = locs()->out(0).fpu_reg();

  const DRegister dq0 = EvenDRegisterOf(q);

  const DRegister dr0 = EvenDRegisterOf(r);
  const DRegister dr1 = OddDRegisterOf(r);

  // Set X.
  __ vcvtds(dr0, EvenSRegisterOf(dq0));
  // Set Y.
  __ vcvtds(dr1, OddSRegisterOf(dq0));
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  if (representation() == kTagged) {
    ASSERT(op_kind() == MethodRecognizer::kFloat64x2GetSignMask);
    // Grabbing the S components means we need a low (< 7) Q.
    summary->set_in(0, Location::FpuRegisterLocation(Q6));
    summary->set_out(0, Location::RequiresRegister());
  } else {
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->in(0).fpu_reg();

  if ((op_kind() == MethodRecognizer::kFloat64x2GetSignMask)) {
    const DRegister dvalue0 = EvenDRegisterOf(q);
    const DRegister dvalue1 = OddDRegisterOf(q);

    const Register out = locs()->out(0).reg();

    // Upper 32-bits of X lane.
    __ vmovrs(out, OddSRegisterOf(dvalue0));
    __ Lsr(out, out, Operand(31));
    // Upper 32-bits of Y lane.
    __ vmovrs(TMP, OddSRegisterOf(dvalue1));
    __ Lsr(TMP, TMP, Operand(31));
    __ orr(out, out, Operand(TMP, LSL, 1));
    // Tag.
    __ SmiTag(out);
    return;
  }
  ASSERT(representation() == kUnboxedFloat64x2);
  const QRegister r = locs()->out(0).fpu_reg();

  const DRegister dvalue0 = EvenDRegisterOf(q);
  const DRegister dvalue1 = OddDRegisterOf(q);
  const DRegister dresult0 = EvenDRegisterOf(r);
  const DRegister dresult1 = OddDRegisterOf(r);

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Negate:
      __ vnegd(dresult0, dvalue0);
      __ vnegd(dresult1, dvalue1);
      break;
    case MethodRecognizer::kFloat64x2Abs:
      __ vabsd(dresult0, dvalue0);
      __ vabsd(dresult1, dvalue1);
      break;
    case MethodRecognizer::kFloat64x2Sqrt:
      __ vsqrtd(dresult0, dvalue0);
      __ vsqrtd(dresult1, dvalue1);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(Zone* zone,
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


void Float64x2OneArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const DRegister left0 = EvenDRegisterOf(left);
  const DRegister left1 = OddDRegisterOf(left);
  const QRegister right = locs()->in(1).fpu_reg();
  const DRegister right0 = EvenDRegisterOf(right);
  const DRegister right1 = OddDRegisterOf(right);
  const QRegister out = locs()->out(0).fpu_reg();
  ASSERT(left == out);

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Scale:
      __ vmuld(left0, left0, right0);
      __ vmuld(left1, left1, right0);
      break;
    case MethodRecognizer::kFloat64x2WithX:
      __ vmovd(left0, right0);
      break;
    case MethodRecognizer::kFloat64x2WithY:
      __ vmovd(left1, right0);
      break;
    case MethodRecognizer::kFloat64x2Min: {
      // X lane.
      Label l0;
      __ vcmpd(left0, right0);
      __ vmstat();
      __ b(&l0, LT);
      __ vmovd(left0, right0);
      __ Bind(&l0);
      // Y lane.
      Label l1;
      __ vcmpd(left1, right1);
      __ vmstat();
      __ b(&l1, LT);
      __ vmovd(left1, right1);
      __ Bind(&l1);
      break;
    }
    case MethodRecognizer::kFloat64x2Max: {
      // X lane.
      Label g0;
      __ vcmpd(left0, right0);
      __ vmstat();
      __ b(&g0, GT);
      __ vmovd(left0, right0);
      __ Bind(&g0);
      // Y lane.
      Label g1;
      __ vcmpd(left1, right1);
      __ vmstat();
      __ b(&g1, GT);
      __ vmovd(left1, right1);
      __ Bind(&g1);
      break;
    }
    default:
      UNREACHABLE();
  }
}


LocationSummary* Int32x4ConstructorInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Int32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register v0 = locs()->in(0).reg();
  const Register v1 = locs()->in(1).reg();
  const Register v2 = locs()->in(2).reg();
  const Register v3 = locs()->in(3).reg();
  const QRegister result = locs()->out(0).fpu_reg();
  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);
  __ veorq(result, result, result);
  __ vmovdrr(dresult0, v0, v1);
  __ vmovdrr(dresult1, v2, v3);
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register v0 = locs()->in(0).reg();
  const Register v1 = locs()->in(1).reg();
  const Register v2 = locs()->in(2).reg();
  const Register v3 = locs()->in(3).reg();
  const Register temp = locs()->temp(0).reg();
  const QRegister result = locs()->out(0).fpu_reg();
  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);

  __ veorq(result, result, result);
  __ LoadImmediate(temp, 0xffffffff);

  __ LoadObject(IP, Bool::True());
  __ cmp(v0, Operand(IP));
  __ vmovdr(dresult0, 0, temp, EQ);

  __ cmp(v1, Operand(IP));
  __ vmovdr(dresult0, 1, temp, EQ);

  __ cmp(v2, Operand(IP));
  __ vmovdr(dresult1, 0, temp, EQ);

  __ cmp(v3, Operand(IP));
  __ vmovdr(dresult1, 1, temp, EQ);
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< 7) Q registers are needed for the vmovrs instruction.
  summary->set_in(0, Location::FpuRegisterLocation(Q6));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const Register result = locs()->out(0).reg();

  const DRegister dvalue0 = EvenDRegisterOf(value);
  const DRegister dvalue1 = OddDRegisterOf(value);
  const SRegister svalue0 = EvenSRegisterOf(dvalue0);
  const SRegister svalue1 = OddSRegisterOf(dvalue0);
  const SRegister svalue2 = EvenSRegisterOf(dvalue1);
  const SRegister svalue3 = OddSRegisterOf(dvalue1);

  switch (op_kind()) {
    case MethodRecognizer::kInt32x4GetFlagX:
      __ vmovrs(result, svalue0);
      break;
    case MethodRecognizer::kInt32x4GetFlagY:
      __ vmovrs(result, svalue1);
      break;
    case MethodRecognizer::kInt32x4GetFlagZ:
      __ vmovrs(result, svalue2);
      break;
    case MethodRecognizer::kInt32x4GetFlagW:
      __ vmovrs(result, svalue3);
      break;
    default:
      UNREACHABLE();
  }

  __ tst(result, Operand(result));
  __ LoadObject(result, Bool::True(), NE);
  __ LoadObject(result, Bool::False(), EQ);
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister mask = locs()->in(0).fpu_reg();
  const QRegister trueValue = locs()->in(1).fpu_reg();
  const QRegister falseValue = locs()->in(2).fpu_reg();
  const QRegister out = locs()->out(0).fpu_reg();
  const QRegister temp = locs()->temp(0).fpu_reg();

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


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister mask = locs()->in(0).fpu_reg();
  const Register flag = locs()->in(1).reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);

  if (result != mask) {
    __ vmovq(result, mask);
  }

  __ CompareObject(flag, Bool::True());
  __ LoadImmediate(TMP, 0xffffffff, EQ);
  __ LoadImmediate(TMP, 0, NE);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4WithFlagX:
      __ vmovdr(dresult0, 0, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagY:
      __ vmovdr(dresult0, 1, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagZ:
      __ vmovdr(dresult1, 0, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagW:
      __ vmovdr(dresult1, 1, TMP);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister value = locs()->in(0).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();

  if (value != result) {
    __ vmovq(result, value);
  }
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Zone* zone,
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


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister left = locs()->in(0).fpu_reg();
  const QRegister right = locs()->in(1).fpu_reg();
  const QRegister result = locs()->out(0).fpu_reg();
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ vandq(result, left, right);
      break;
    case Token::kBIT_OR:
      __ vorrq(result, left, right);
      break;
    case Token::kBIT_XOR:
      __ veorq(result, left, right);
      break;
    case Token::kADD:
      __ vaddqi(kWord, result, left, right);
      break;
    case Token::kSUB:
      __ vsubqi(kWord, result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}


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


LocationSummary* CaseInsensitiveCompareUC16Instr::MakeLocationSummary(
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


void CaseInsensitiveCompareUC16Instr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
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
    Label done, returns_nan, are_equal;
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
    __ cmp(temp, Operand(0));
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
  __ cmp(left, Operand(right));
  ASSERT(result == left);
  if (is_min) {
    __ mov(result, Operand(right), GT);
  } else {
    __ mov(result, Operand(right), LT);
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
      Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ rsbs(result, value, Operand(0));
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn(result, Operand(value));
      // Remove inverted smi-tag.
      __ bic(result, result, Operand(kSmiTagMask));
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


LocationSummary* MintToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MintToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
  __ LoadDFromOffset(DTMP, value_obj, Double::value_offset() - kHeapObjectTag);

  Label done, do_call;
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
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), instance_call()->token_pos(), target,
                               args_info, locs(), ICData::Handle());
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
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
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
  // Low (<= Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::FpuRegisterLocation(Q7));
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
  // Low (<= Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::FpuRegisterLocation(Q7));
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

  Label skip_call, try_sqrt, check_base, return_nan;
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
  Label return_base;
  __ b(&return_base, EQ);

  // exponent == 2.0 ?
  __ LoadDImmediate(DTMP, 2.0, temp);
  __ vcmpd(exp, DTMP);
  __ vmstat();
  Label return_base_times_2;
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

  Label do_pow, return_zero;
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
    __ mov(out, Operand(in));
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
  summary->set_temp(1, Location::RequiresFpuRegister());
  // Output is a pair of registers.
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void TruncDivModInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(CanDeoptimize());
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);

  ASSERT(TargetCPUFeatures::can_divide());
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  ASSERT(locs()->out(0).IsPairLocation());
  PairLocation* pair = locs()->out(0).AsPairLocation();
  const Register result_div = pair->At(0).reg();
  const Register result_mod = pair->At(1).reg();
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ cmp(right, Operand(0));
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
  Label done;
  __ cmp(result_mod, Operand(0));
  __ b(&done, GE);
  // Result is negative, adjust it.
  __ cmp(right, Operand(0));
  __ sub(result_mod, result_mod, Operand(right), LT);
  __ add(result_mod, result_mod, Operand(right), GE);
  __ Bind(&done);
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  return MakeCallSummary(zone);
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


void CheckClassInstr::EmitNullCheck(FlowGraphCompiler* compiler, Label* deopt) {
  __ CompareObject(locs()->in(0).reg(), Object::null_object());
  ASSERT(IsDeoptIfNull() || IsDeoptIfNotNull());
  Condition cond = IsDeoptIfNull() ? EQ : NE;
  __ b(deopt, cond);
}


void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  Label* deopt) {
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
                                  Label* is_ok,
                                  Label* deopt,
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
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi,
                                        licm_hoisted_ ? ICData::kHoisted : 0);
  __ BranchIfNotSmi(value, deopt);
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
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  if (cids_.IsSingleCid()) {
    __ CompareImmediate(value, Smi::RawValue(cids_.cid_start));
    __ b(deopt, NE);
  } else {
    __ AddImmediate(value, -Smi::RawValue(cids_.cid_start));
    __ CompareImmediate(value, Smi::RawValue(cids_.Extent()));
    __ b(deopt, HI);  // Unsigned higher.
  }
}


LocationSummary* GenericCheckBoundInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_in(kLengthPos, Location::RequiresRegister());
  locs->set_in(kIndexPos, Location::RequiresRegister());
  return locs;
}


class RangeErrorSlowPath : public SlowPathCode {
 public:
  RangeErrorSlowPath(GenericCheckBoundInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path check bound operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    compiler->SaveLiveRegisters(locs);
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    __ CallRuntime(kRangeErrorRuntimeEntry, 2);
    compiler->AddDescriptor(
        RawPcDescriptors::kOther, compiler->assembler()->CodeSize(),
        instruction_->deopt_id(), instruction_->token_pos(), try_index_);
    compiler->RecordSafepoint(locs, 2);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->EmitCatchEntryState(env, try_index_);
    __ bkpt(0);
  }

 private:
  GenericCheckBoundInstr* instruction_;
  intptr_t try_index_;
};


void GenericCheckBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  RangeErrorSlowPath* slow_path =
      new RangeErrorSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);
  Register length = length_loc.reg();
  Register index = index_loc.reg();
  const intptr_t index_cid = this->index()->Type()->ToCid();
  if (index_cid != kSmiCid) {
    __ BranchIfNotSmi(index, slow_path->entry_label());
  }
  __ cmp(index, Operand(length));
  __ b(slow_path->entry_label(), CS);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  uint32_t flags = generalized_ ? ICData::kGeneralized : 0;
  flags |= licm_hoisted_ ? ICData::kHoisted : 0;
  Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckArrayBound, flags);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);

  if (length_loc.IsConstant() && index_loc.IsConstant()) {
    ASSERT((Smi::Cast(length_loc.constant()).Value() <=
            Smi::Cast(index_loc.constant()).Value()) ||
           (Smi::Cast(index_loc.constant()).Value() < 0));
    // Unconditionally deoptimize for constant bounds checks because they
    // only occur only when index is out-of-bounds.
    __ b(deopt);
    return;
  }

  const intptr_t index_cid = index()->Type()->ToCid();
  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(length, reinterpret_cast<int32_t>(index.raw()));
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ tst(index, Operand(index));
      __ b(deopt, MI);
    } else {
      __ CompareImmediate(index, reinterpret_cast<int32_t>(length.raw()));
      __ b(deopt, CS);
    }
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmp(index, Operand(length));
    __ b(deopt, CS);
  }
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
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
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs()->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);
  }
  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ and_(out_lo, left_lo, Operand(right_lo));
      __ and_(out_hi, left_hi, Operand(right_hi));
      break;
    }
    case Token::kBIT_OR: {
      __ orr(out_lo, left_lo, Operand(right_lo));
      __ orr(out_hi, left_hi, Operand(right_hi));
      break;
    }
    case Token::kBIT_XOR: {
      __ eor(out_lo, left_lo, Operand(right_lo));
      __ eor(out_hi, left_hi, Operand(right_hi));
      break;
    }
    case Token::kADD:
    case Token::kSUB: {
      if (op_kind() == Token::kADD) {
        __ adds(out_lo, left_lo, Operand(right_lo));
        __ adcs(out_hi, left_hi, Operand(right_hi));
      } else {
        ASSERT(op_kind() == Token::kSUB);
        __ subs(out_lo, left_lo, Operand(right_lo));
        __ sbcs(out_hi, left_hi, Operand(right_hi));
      }
      if (can_overflow()) {
        // Deopt on overflow.
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      // The product of two signed 32-bit integers fits in a signed 64-bit
      // result without causing overflow.
      // We deopt on larger inputs.
      // TODO(regis): Range analysis may eliminate the deopt check.
      __ cmp(left_hi, Operand(left_lo, ASR, 31));
      __ cmp(right_hi, Operand(right_lo, ASR, 31), EQ);
      __ b(deopt, NE);
      __ smull(out_lo, out_hi, left_lo, right_lo);
      break;
    }
    default:
      UNREACHABLE();
  }
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::WritableRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);
  }
  if (locs()->in(1).IsConstant()) {
    // Code for a constant shift amount.
    ASSERT(locs()->in(1).constant().IsSmi());
    const int32_t shift =
        reinterpret_cast<int32_t>(locs()->in(1).constant().raw()) >> 1;
    switch (op_kind()) {
      case Token::kSHR: {
        if (shift < 32) {
          __ Lsl(out_lo, left_hi, Operand(32 - shift));
          __ orr(out_lo, out_lo, Operand(left_lo, LSR, shift));
          __ Asr(out_hi, left_hi, Operand(shift));
        } else {
          if (shift == 32) {
            __ mov(out_lo, Operand(left_hi));
          } else if (shift < 64) {
            __ Asr(out_lo, left_hi, Operand(shift - 32));
          } else {
            __ Asr(out_lo, left_hi, Operand(31));
          }
          __ Asr(out_hi, left_hi, Operand(31));
        }
        break;
      }
      case Token::kSHL: {
        ASSERT(shift < 64);
        if (shift < 32) {
          __ Lsr(out_hi, left_lo, Operand(32 - shift));
          __ orr(out_hi, out_hi, Operand(left_hi, LSL, shift));
          __ Lsl(out_lo, left_lo, Operand(shift));
        } else {
          if (shift == 32) {
            __ mov(out_hi, Operand(left_lo));
          } else {
            __ Lsl(out_hi, left_lo, Operand(shift - 32));
          }
          __ mov(out_lo, Operand(0));
        }
        // Check for overflow.
        if (can_overflow()) {
          // Compare high word from input with shifted high word from output.
          // If shift > 32, also compare low word from input with high word from
          // output shifted back shift - 32.
          if (shift > 32) {
            __ cmp(left_lo, Operand(out_hi, ASR, shift - 32));
            __ cmp(left_hi, Operand(out_hi, ASR, 31), EQ);
          } else if (shift == 32) {
            __ cmp(left_hi, Operand(out_hi, ASR, 31));
          } else {
            __ cmp(left_hi, Operand(out_hi, ASR, shift));
          }
          // Overflow if they aren't equal.
          __ b(deopt, NE);
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  } else {
    // Code for a variable shift amount.
    Register shift = locs()->in(1).reg();

    // Untag shift count.
    __ SmiUntag(shift);

    // Deopt if shift is larger than 63 or less than 0.
    if (has_shift_count_check()) {
      __ CompareImmediate(shift, kMintShiftCountLimit);
      __ b(deopt, HI);
    }

    switch (op_kind()) {
      case Token::kSHR: {
        __ rsbs(IP, shift, Operand(32));
        __ sub(IP, shift, Operand(32), MI);
        __ mov(out_lo, Operand(left_hi, ASR, IP), MI);
        __ mov(out_lo, Operand(left_lo, LSR, shift), PL);
        __ orr(out_lo, out_lo, Operand(left_hi, LSL, IP), PL);
        __ mov(out_hi, Operand(left_hi, ASR, shift));
        break;
      }
      case Token::kSHL: {
        __ rsbs(IP, shift, Operand(32));
        __ sub(IP, shift, Operand(32), MI);
        __ mov(out_hi, Operand(left_lo, LSL, IP), MI);
        __ mov(out_hi, Operand(left_hi, LSL, shift), PL);
        __ orr(out_hi, out_hi, Operand(left_lo, LSR, IP), PL);
        __ mov(out_lo, Operand(left_lo, LSL, shift));

        // Check for overflow.
        if (can_overflow()) {
          // If shift > 32, compare low word from input with high word from
          // output shifted back shift - 32.
          __ mov(IP, Operand(out_hi, ASR, IP), MI);
          __ mov(IP, Operand(left_lo), PL);  // No test if shift <= 32.
          __ cmp(left_lo, Operand(IP));
          // Compare high word from input with shifted high word from output.
          __ cmp(left_hi, Operand(out_hi, ASR, shift), EQ);
          // Overflow if they aren't equal.
          __ b(deopt, NE);
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  }
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Zone* zone,
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


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(op_kind() == Token::kBIT_NOT);
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  __ mvn(out_lo, Operand(left_lo));
  __ mvn(out_hi, Operand(left_hi));
}


CompileType BinaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType ShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType UnaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
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
      __ and_(out, left, Operand(right));
      break;
    case Token::kBIT_OR:
      __ orr(out, left, Operand(right));
      break;
    case Token::kBIT_XOR:
      __ eor(out, left, Operand(right));
      break;
    case Token::kADD:
      __ add(out, left, Operand(right));
      break;
    case Token::kSUB:
      __ sub(out, left, Operand(right));
      break;
    case Token::kMUL:
      __ mul(out, left, right);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t kShifterLimit = 31;

  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();

  ASSERT(left != out);

  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);

  if (locs()->in(1).IsConstant()) {
    // Shifter is constant.

    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t shift_value = Smi::Cast(constant).Value();

    // Do the shift: (shift_value > 0) && (shift_value <= kShifterLimit).
    switch (op_kind()) {
      case Token::kSHR:
        __ Lsr(out, left, Operand(shift_value));
        break;
      case Token::kSHL:
        __ Lsl(out, left, Operand(shift_value));
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  // Non constant shift value.
  Register shifter = locs()->in(1).reg();

  __ SmiUntag(temp, shifter);
  __ CompareImmediate(temp, 0);
  // If shift value is < 0, deoptimize.
  __ b(deopt, LT);
  __ CompareImmediate(temp, kShifterLimit);
  // > kShifterLimit, result is 0.
  __ eor(out, out, Operand(out), HI);
  // Do the shift.
  switch (op_kind()) {
    case Token::kSHR:
      __ Lsr(out, left, temp, LS);
      break;
    case Token::kSHL:
      __ Lsl(out, left, temp, LS);
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

  __ mvn(out, Operand(left));
}


LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUnboxedMint) {
    ASSERT((to() == kUnboxedUint32) || (to() == kUnboxedInt32));
    summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else if (to() == kUnboxedMint) {
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT((to() == kUnboxedUint32) || (to() == kUnboxedInt32));
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  }
  return summary;
}


void UnboxedIntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ tst(out, Operand(out));
      __ b(deopt, MI);
    }
  } else if (from() == kUnboxedMint) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ mov(out, Operand(in_lo));
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      ASSERT(to() == kUnboxedInt32);
      __ cmp(in_hi, Operand(in_lo, ASR, kBitsPerWord - 1));
      __ b(deopt, NE);
    }
  } else if (from() == kUnboxedUint32 || from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedMint);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ mov(out_lo, Operand(in));
    if (from() == kUnboxedUint32) {
      __ eor(out_hi, out_hi, Operand(out_hi));
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ mov(out_hi, Operand(in, ASR, kBitsPerWord - 1));
    }
  } else {
    UNREACHABLE();
  }
}


LocationSummary* ThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(), kThrowRuntimeEntry, 1,
                                locs());
  __ bkpt(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStackTrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(), kReThrowRuntimeEntry,
                                2, locs());
  __ bkpt(0);
}


LocationSummary* StopInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void StopInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Stop(message());
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
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
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, GetDeoptId(),
                                   TokenPosition::kNoSource);
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
  __ mov(target_address_reg, Operand(PC));
  __ AddImmediate(target_address_reg, -entry_to_pc_offset);
  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  Operand offset_opr = (offset()->definition()->representation() == kTagged)
                           ? Operand(offset_reg, ASR, kSmiTagSize)
                           : Operand(offset_reg);
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
    locs->set_in(0, Location::RegisterOrConstant(left()));
  }

  constant = right()->definition()->AsConstant();
  if ((constant != NULL) && !right()->IsSingleUse()) {
    locs->set_in(1, Location::RequiresRegister());
  } else {
    // Only one of the inputs can be a constant. Choose register if the first
    // one is a constant.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : Location::RegisterOrConstant(right()));
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());
  Condition true_condition;
  if (left.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(
        right.reg(), left.constant(), needs_number_check(), token_pos(),
        deopt_id_);
  } else if (right.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(
        left.reg(), right.constant(), needs_number_check(), token_pos(),
        deopt_id_);
  } else {
    true_condition = compiler->EmitEqualityRegRegCompare(
        left.reg(), right.reg(), needs_number_check(), token_pos(), deopt_id_);
  }
  if (kind() != Token::kEQ_STRICT) {
    ASSERT(kind() == Token::kNE_STRICT);
    true_condition = NegateCondition(true_condition);
  }
  return true_condition;
}


void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The ARM code may not use true- and false-labels here.
  Label is_true, is_false, done;
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
    __ LoadObject(result, Bool::False(), NegateCondition(true_condition));
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
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ LoadObject(result, Bool::True());
  __ cmp(result, Operand(value));
  __ LoadObject(result, Bool::False(), EQ);
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  return MakeCallSummary(zone);
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForClass(cls()));
  const StubEntry stub_entry(stub);
  compiler->GenerateCall(token_pos(), stub_entry, RawPcDescriptors::kOther,
                         locs());
  compiler->AddStubCallTarget(stub);
  __ Drop(ArgumentCount());  // Discard arguments.
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  __ BranchLinkPatchable(*StubCode::DebugStepCheck_entry());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, token_pos());
  compiler->RecordSafepoint(locs());
}


LocationSummary* GrowRegExpStackInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void GrowRegExpStackInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register typed_data = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ PushObject(Object::null_object());
  __ Push(typed_data);
  compiler->GenerateRuntimeCall(TokenPosition::kNoSource, deopt_id(),
                                kGrowRegExpStackRuntimeEntry, 1, locs());
  __ Drop(1);
  __ Pop(result);
}


}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
