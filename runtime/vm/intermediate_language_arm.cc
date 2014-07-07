// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/intermediate_language.h"

#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(bool, emit_edge_counters);
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, use_osr);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0.
LocationSummary* Instruction::MakeCallSummary() {
  Isolate* isolate = Isolate::Current();
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(R0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps= 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      __ LoadFromOffset(kWord, IP, FP, value_offset);
      __ Push(IP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Isolate* isolate,
                                                  bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->in(0).reg();
  ASSERT(result == R0);
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
  __ LeaveDartFrame();
  __ Ret();
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQ: return NE;
    case NE: return EQ;
    case LT: return GE;
    case LE: return GT;
    case GT: return LE;
    case GE: return LT;
    case CC: return CS;
    case LS: return HI;
    case HI: return LS;
    case CS: return CC;
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


LocationSummary* IfThenElseInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(isolate, opt);
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
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);

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
    __ Lsl(result, result, shift + kSmiTagSize);
  } else {
    __ sub(result, result, Operand(1));
    const int32_t val =
        Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, Smi::RawValue(false_value));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Function.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor in R4.
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  __ LoadObject(R4, arguments_descriptor);

  // R4: Arguments descriptor.
  // R0: Function.
  ASSERT(locs()->in(0).reg() == R0);
  __ ldr(R2, FieldAddress(R0, Function::instructions_offset()));

  // R2: instructions.
  // R5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ LoadImmediate(R5, 0);
  __ AddImmediate(R2, Instructions::HeaderSize() - kHeapObjectTag);
  __ blx(R2);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kClosureCall,
                                 deopt_id(),
                                 token_pos());
  compiler->RecordSafepoint(locs());
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after, token_pos());
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   deopt_id_after,
                                   token_pos());
  }
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  __ LoadFromOffset(kWord, result, FP, local().index() * kWordSize);
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  return LocationSummary::Make(isolate,
                               1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ str(value, Address(FP, local().index() * kWordSize));
}


LocationSummary* ConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    const Register result = locs()->out(0).reg();
    __ LoadObject(result, value());
  }
}


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_out(0, Location::RequiresFpuRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0) &&
        TargetCPUFeatures::neon_supported()) {
      const QRegister dst = locs()->out(0).fpu_reg();
      __ veorq(dst, dst, dst);
    } else {
      const DRegister dst = EvenDRegisterOf(locs()->out(0).fpu_reg());
      const Register temp = locs()->temp(0).reg();
      __ LoadDImmediate(dst, Double::Cast(value()).value(), temp);
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Value.
  summary->set_in(1, Location::RegisterLocation(R2));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(R1));  // Type arguments.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


static void EmitAssertBoolean(Register reg,
                              intptr_t token_pos,
                              intptr_t deopt_id,
                              LocationSummary* locs,
                              FlowGraphCompiler* compiler) {
  // Check that the type of the value is allowed in conditional context.
  // Call the runtime if the object is not bool::true or bool::false.
  ASSERT(locs->always_calls());
  Label done;
  __ CompareObject(reg, Bool::True());
  __ b(&done, EQ);
  __ CompareObject(reg, Bool::False());
  __ b(&done, EQ);

  __ Push(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos,
                                deopt_id,
                                kNonBoolTypeErrorRuntimeEntry,
                                1,
                                locs);
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
    case Token::kEQ: return EQ;
    case Token::kNE: return NE;
    case Token::kLT: return LT;
    case Token::kGT: return GT;
    case Token::kLTE: return LE;
    case Token::kGTE: return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case EQ: return EQ;
    case NE: return NE;
    case LT: return GT;
    case LE: return GE;
    case GT: return LT;
    case GE: return LE;
    case CC: return HI;
    case LS: return CS;
    case HI: return CC;
    case CS: return LS;
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
    case Token::kEQ: return EQ;
    case Token::kNE: return NE;
    case Token::kLT: return LT;
    case Token::kGT: return GT;
    case Token::kLTE: return LE;
    case Token::kGTE: return GE;
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
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs->in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();

  // Compare lower.
  __ cmp(left1, Operand(right1));
  // Compare upper if lower is equal.
  __ cmp(left2, Operand(right2), EQ);
  return TokenKindToMintCondition(kind);
}


static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             LocationSummary* locs,
                                             Token::Kind kind) {
  PairLocation* left_pair = locs->in(0).AsPairLocation();
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs->in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();

  Register out = locs->temp(0).reg();

  // 64-bit comparison
  Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (kind) {
    case Token::kLT:
    case Token::kLTE:
      hi_true_cond = LT;
      hi_false_cond = GT;
      lo_false_cond = (kind == Token::kLT) ? CS : HI;
      break;
    case Token::kGT:
    case Token::kGTE:
      hi_true_cond = GT;
      hi_false_cond = LT;
      lo_false_cond = (kind == Token::kGT) ? LS : CC;
      break;
    default:
      UNREACHABLE();
      hi_true_cond = hi_false_cond = lo_false_cond = VS;
  }

  Label is_true, is_false, done;
  // Compare upper halves first.
  __ cmp(left2, Operand(right2));
  __ LoadImmediate(out, 0, hi_false_cond);
  __ LoadImmediate(out, 1, hi_true_cond);
  // If higher words aren't equal, skip comparing lower words.
  __ b(&done, NE);

  __ cmp(left1, Operand(right1));
  __ LoadImmediate(out, 1);
  __ LoadImmediate(out, 0, lo_false_cond);
  __ Bind(&done);

  return NegateCondition(lo_false_cond);
}


static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQ;
    case Token::kNE: return NE;
    case Token::kLT: return LT;
    case Token::kGT: return GT;
    case Token::kLTE: return LE;
    case Token::kGTE: return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}


static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        LocationSummary* locs,
                                        Token::Kind kind) {
  const QRegister left = locs->in(0).fpu_reg();
  const QRegister right = locs->in(1).fpu_reg();
  const DRegister dleft = EvenDRegisterOf(left);
  const DRegister dright = EvenDRegisterOf(right);
  __ vcmpd(dleft, dright);
  __ vmstat();
  Condition true_condition = TokenKindToDoubleCondition(kind);
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
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  const Register result = locs()->out(0).reg();
  if ((operation_cid() == kSmiCid) || (operation_cid() == kMintCid)) {
    __ LoadObject(result, Bool::True(), true_condition);
    __ LoadObject(result, Bool::False(), NegateCondition(true_condition));
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    Label done;
    __ LoadObject(result, Bool::False());
    if (true_condition != NE) {
      __ b(&done, VS);  // x == NaN -> false, x != NaN -> true.
    }
    __ LoadObject(result, Bool::True(), true_condition);
    __ Bind(&done);
  }
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);

  if (operation_cid() == kDoubleCid) {
    Label* nan_result = (true_condition == NE) ?
        labels.true_label : labels.false_label;
    __ b(nan_result, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                   bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    const int32_t imm =
        reinterpret_cast<int32_t>(right.constant().raw());
    __ TestImmediate(left, imm);
  } else {
    __ tst(left, Operand(right.reg()));
  }
  Condition true_condition = (kind() == Token::kNE) ? NE : EQ;
  return true_condition;
}


void TestSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Never emitted outside of the BranchInstr.
  UNREACHABLE();
}


void TestSmiInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                  BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestCidsInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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

  Label* deopt = CanDeoptimize() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids) : NULL;

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
  // No match found, deoptimize or false.
  if (deopt == NULL) {
    Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ b(target);
    }
  } else {
    __ b(deopt);
  }
  // Dummy result as the last instruction is a jump, any conditional
  // branch using the result will therefore be skipped.
  return EQ;
}


void TestCidsInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                   BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  EmitComparisonCode(compiler, labels);
}


void TestCidsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result_reg = locs()->out(0).reg();
  Label is_true, is_false, done;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  EmitComparisonCode(compiler, labels);
  __ Bind(&is_false);
  __ LoadObject(result_reg, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True());
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    return EmitUnboxedMintComparisonOp(compiler, locs(), kind());
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  const Register result = locs()->out(0).reg();
  if (operation_cid() == kSmiCid) {
    __ LoadObject(result, Bool::True(), true_condition);
    __ LoadObject(result, Bool::False(), NegateCondition(true_condition));
  } else if (operation_cid() == kMintCid) {
    const Register cr = locs()->temp(0).reg();
    __ LoadObject(result, Bool::True());
    __ CompareImmediate(cr, 1);
    __ LoadObject(result, Bool::False(), NE);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    Label done;
    __ LoadObject(result, Bool::False());
    if (true_condition != NE) {
      __ b(&done, VS);  // x == NaN -> false, x != NaN -> true.
    }
    __ LoadObject(result, Bool::True(), true_condition);
    __ Bind(&done);
  }
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);

  if (operation_cid() == kSmiCid) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  } else if (operation_cid() == kMintCid) {
    const Register result = locs()->temp(0).reg();
    __ CompareImmediate(result, 1);
    __ b(labels.true_label, EQ);
    __ b(labels.false_label, NE);
  } else if (operation_cid() == kDoubleCid) {
    Label* nan_result = (true_condition == NE) ?
        labels.true_label : labels.false_label;
    __ b(nan_result, VS);
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
}


LocationSummary* NativeCallInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_temp(1, Location::RegisterLocation(R2));
  locs->set_temp(2, Location::RegisterLocation(R5));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->temp(1).reg() == R2);
  ASSERT(locs()->temp(2).reg() == R5);
  const Register result = locs()->out(0).reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in R2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(R2, FP, (kParamEndSlotFromFp +
                             function().NumParameters()) * kWordSize);
  } else {
    __ AddImmediate(R2, FP, kFirstLocalSlotFromFp * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(native_c_function());
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const bool is_leaf_call =
    (argc_tag & NativeArguments::AutoSetupScopeMask()) == 0;
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel* stub_entry;
  if (is_bootstrap_native() || is_leaf_call) {
    stub_entry = &stub_code->CallBootstrapCFunctionLabel();
#if defined(USING_SIMULATOR)
    entry = Simulator::RedirectExternalReference(
        entry, Simulator::kBootstrapNativeCall, function().NumParameters());
#endif
  } else {
    // In the case of non bootstrap native methods the CallNativeCFunction
    // stub generates the redirection address when running under the simulator
    // and hence we do not change 'entry' here.
    stub_entry = &stub_code->CallNativeCFunctionLabel();
#if defined(USING_SIMULATOR)
    if (!function().IsNativeAutoSetupScope()) {
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, function().NumParameters());
    }
#endif
  }
  __ LoadImmediate(R5, entry);
  __ LoadImmediate(R1, argc_tag);
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register char_code = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadImmediate(result,
                   reinterpret_cast<uword>(Symbols::PredefinedAddress()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(result, Address(result, char_code, LSL, 1));  // Char code is a smi.
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
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


LocationSummary* StringInterpolateInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register array = locs()->in(0).reg();
  __ Push(array);
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               CallFunction(),
                               kNumberOfArguments,
                               kNoArgumentNames,
                               locs(),
                               ICData::Handle());
  ASSERT(locs()->out(0).reg() == R0);
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register object = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadFromOffset(kWord, result, object, offset() - kHeapObjectTag);
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register object = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadTaggedClassIdMayBeSmi(result, object);
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
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // Result can be Smi or Mint when boxed.
      // Instruction can deoptimize if we optimistically assumed that the result
      // fits into Smi.
      return CanDeoptimize() ? CompileType::FromCid(kSmiCid)
                             : CompileType::Int();

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
      return kTagged;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // Instruction can deoptimize if we optimistically assumed that the result
      // fits into Smi.
      return CanDeoptimize() ? kTagged : kUnboxedMint;
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


static bool CanHoldImmediateOffset(bool is_load, intptr_t cid, int64_t offset) {
  int32_t offset_mask = 0;
  if (is_load) {
    return Address::CanHoldLoadOffset(Address::OperandSizeFor(cid),
                                      offset,
                                      &offset_mask);
  } else {
    return Address::CanHoldStoreOffset(Address::OperandSizeFor(cid),
                                       offset,
                                       &offset_mask);
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
  if (CanHoldImmediateOffset(is_load, cid, offset)) {
    *needs_base = false;
    return true;
  }

  if (CanHoldImmediateOffset(is_load, cid, offset - base_offset)) {
    *needs_base = true;
    return true;
  }

  return false;
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  bool needs_base = false;
  if (CanBeImmediateIndex(index(), class_id(), IsExternal(),
                          true,  // Load.
                          &needs_base)) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->BoundConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
      (representation() == kUnboxedFloat64x2)) {
    if (class_id() == kTypedDataFloat32ArrayCid) {
      // Need register <= Q7 for float operations.
      // TODO(fschneider): Add a register policy to specify a subset of
      // registers.
      locs->set_out(0, Location::FpuRegisterLocation(Q7));
    } else {
      locs->set_out(0, Location::RequiresFpuRegister());
    }
  } else if (representation() == kUnboxedMint) {
    locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  } else {
    ASSERT(representation() == kTagged);
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}


static Address ElementAddressForIntIndex(Assembler* assembler,
                                         bool is_load,
                                         bool is_external,
                                         intptr_t cid,
                                         intptr_t index_scale,
                                         Register array,
                                         intptr_t index,
                                         Register temp) {
  const int64_t offset_base =
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset = offset_base +
      static_cast<int64_t>(index) * index_scale;
  ASSERT(Utils::IsInt(32, offset));

  if (CanHoldImmediateOffset(is_load, cid, offset)) {
    return Address(array, static_cast<int32_t>(offset));
  } else {
    ASSERT(CanHoldImmediateOffset(is_load, cid, offset - offset_base));
    assembler->AddImmediate(
        temp, array, static_cast<int32_t>(offset_base));
    return Address(temp, static_cast<int32_t>(offset - offset_base));
  }
}


static Address ElementAddressForRegIndex(Assembler* assembler,
                                         bool is_load,
                                         bool is_external,
                                         intptr_t cid,
                                         intptr_t index_scale,
                                         Register array,
                                         Register index) {
  // Note that index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) - kSmiTagShift;
  int32_t offset =
      is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag);
  const OperandSize size = Address::OperandSizeFor(cid);
  ASSERT(array != IP);
  ASSERT(index != IP);
  const Register base = is_load ? IP : index;
  if ((offset != 0) ||
      (size == kSWord) || (size == kDWord) || (size == kRegList)) {
    if (shift < 0) {
      ASSERT(shift == -1);
      assembler->add(base, array, Operand(index, ASR, 1));
    } else {
      assembler->add(base, array, Operand(index, LSL, shift));
    }
  } else {
    if (shift < 0) {
      ASSERT(shift == -1);
      return Address(array, index, ASR, 1);
    } else {
      return Address(array, index, LSL, shift);
    }
  }
  int32_t offset_mask = 0;
  if ((is_load && !Address::CanHoldLoadOffset(size,
                                              offset,
                                              &offset_mask)) ||
      (!is_load && !Address::CanHoldStoreOffset(size,
                                                offset,
                                                &offset_mask))) {
    assembler->AddImmediate(base, offset & ~offset_mask);
    offset = offset & offset_mask;
  }
  return Address(base, offset);
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = index.IsRegister()
      ? ElementAddressForRegIndex(compiler->assembler(),
                                  true,  // Load.
                                  IsExternal(), class_id(), index_scale(),
                                  array, index.reg())
      : ElementAddressForIntIndex(compiler->assembler(),
                                  true,  // Load.
                                  IsExternal(), class_id(), index_scale(),
                                  array, Smi::Cast(index.constant()).Value(),
                                  IP);  // Temp register.
  // Warning: element_address may use register IP as base.

  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
      (representation() == kUnboxedFloat64x2)) {
    const QRegister result = locs()->out(0).fpu_reg();
    const DRegister dresult0 = EvenDRegisterOf(result);
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        // vldrs does not support indexed addressing.
        __ vldrs(EvenSRegisterOf(dresult0), element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        // vldrd does not support indexed addressing.
        __ vldrd(dresult0, element_address);
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        ASSERT(element_address.Equals(Address(IP)));
        __ vldmd(IA, IP, dresult0, 2);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if (representation() == kUnboxedMint) {
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* result_pair = locs()->out(0).AsPairLocation();
    const Register result1 = result_pair->At(0).reg();
    const Register result2 = result_pair->At(1).reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        // Load low word.
        __ ldr(result1, element_address);
        // Sign extend into high word.
        __ SignFill(result2, result1);
        break;
      case kTypedDataUint32ArrayCid:
        // Load low word.
        __ ldr(result1, element_address);
        // Zero high word.
        __ eor(result2, result2, Operand(result2));
        break;
      default:
        UNREACHABLE();
        break;
    }
    return;
  }

  ASSERT(representation() == kTagged);

  const Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      __ ldrsb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ ldrb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ ldrsh(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
      __ ldrh(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptInt32Load);
        __ ldr(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ CompareImmediate(result, 0xC0000000);
        __ b(deopt, MI);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptUint32Load);
        __ ldr(result, element_address);
        // Verify that the unsigned value in 'result' can fit inside a Smi.
        __ TestImmediate(result, 0xC0000000);
        __ b(deopt, NE);
        __ SmiTag(result);
      }
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
  if (idx == 0)  return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) return kTagged;  // Index is a smi.
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
    case kTypedDataUint32ArrayCid:
      return value()->IsSmiValue() ? kTagged : kUnboxedMint;
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


LocationSummary* StoreIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  LocationSummary* locs;

  bool needs_base = false;
  if (CanBeImmediateIndex(index(), class_id(), IsExternal(),
                          false,  // Store.
                          &needs_base)) {
    const intptr_t kNumTemps = needs_base ? 1 : 0;
    locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);

    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->BoundConstant()));
    if (needs_base) {
      locs->set_temp(0, Location::RequiresRegister());
    }
  } else {
    const intptr_t kNumTemps = 0;
    locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);

    locs->set_in(1, Location::WritableRegister());
  }
  locs->set_in(0, Location::RequiresRegister());

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
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // Smis are untagged in TMP register. Mints are stored in register pairs.
      if (value()->IsSmiValue()) {
        locs->set_in(2, Location::RequiresRegister());
      } else {
        // We only move the lower 32-bits so we don't care where the high bits
        // are located.
        locs->set_in(2, Location::Pair(Location::RequiresRegister(),
                                       Location::Any()));
      }
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

  Address element_address = index.IsRegister()
      ? ElementAddressForRegIndex(compiler->assembler(),
                                  false,  // Store.
                                  IsExternal(), class_id(), index_scale(),
                                  array, index.reg())
      : ElementAddressForIntIndex(compiler->assembler(),
                                  false,  // Store.
                                  IsExternal(), class_id(), index_scale(),
                                  array, Smi::Cast(index.constant()).Value(),
                                  temp);

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
        __ cmp(value, Operand(IP));  // Compare Smi value and smi 0xFF.
        // Clamp to 0x00 or 0xFF respectively.
        __ mov(IP, Operand(0), LE);  // IP = value <= 0x1FE ? 0 : 0x1FE.
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
      __ strh(IP, element_address);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (value()->IsSmiValue()) {
        ASSERT(RequiredInputRepresentation(2) == kTagged);
        const Register value = locs()->in(2).reg();
        __ SmiUntag(IP, value);
        __ str(IP, element_address);
      } else {
        ASSERT(RequiredInputRepresentation(2) == kUnboxedMint);
        PairLocation* value_pair = locs()->in(2).AsPairLocation();
        Register value1 = value_pair->At(0).reg();
        __ str(value1, element_address);
      }
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      const SRegister value_reg =
          EvenSRegisterOf(EvenDRegisterOf(locs()->in(2).fpu_reg()));
      __ vstrs(value_reg, element_address);
      break;
    }
    case kTypedDataFloat64ArrayCid: {
      const DRegister value_reg = EvenDRegisterOf(locs()->in(2).fpu_reg());
      __ vstrd(value_reg, element_address);
      break;
    }
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid: {
      ASSERT(element_address.Equals(Address(index.reg())));
      const DRegister value_reg = EvenDRegisterOf(locs()->in(2).fpu_reg());
      __ vstmd(IA, index.reg(), value_reg, 2);
      break;
    }
    default:
      UNREACHABLE();
  }
}


LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();

  const bool emit_full_guard =
      !opt || (field_cid == kIllegalCid);

  const bool needs_value_cid_temp_reg = emit_full_guard ||
      ((value_cid == kDynamicCid) && (field_cid != kSmiCid));

  const bool needs_field_temp_reg = emit_full_guard;

  intptr_t num_temps = 0;
  if (needs_value_cid_temp_reg) {
    num_temps++;
  }
  if (needs_field_temp_reg) {
    num_temps++;
  }

  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());

  for (intptr_t i = 0; i < num_temps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }

  return summary;
}


void GuardFieldClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  const bool emit_full_guard =
      !compiler->is_optimizing() || (field_cid == kIllegalCid);

  const bool needs_value_cid_temp_reg = emit_full_guard ||
      ((value_cid == kDynamicCid) && (field_cid != kSmiCid));

  const bool needs_field_temp_reg = emit_full_guard;

  const Register value_reg = locs()->in(0).reg();

  const Register value_cid_reg = needs_value_cid_temp_reg ?
      locs()->temp(0).reg() : kNoRegister;

  const Register field_reg = needs_field_temp_reg ?
      locs()->temp(locs()->temp_count() - 1).reg() : kNoRegister;

  Label ok, fail_label;

  Label* deopt = compiler->is_optimizing() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField) : NULL;

  Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ ldr(IP, field_cid_operand);
      __ cmp(value_cid_reg, Operand(IP));
      __ b(&ok, EQ);
      __ ldr(IP, field_nullability_operand);
      __ cmp(value_cid_reg, Operand(IP));
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

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ b(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ ldr(IP, FieldAddress(field_reg, Field::guarded_cid_offset()));
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
          __ CompareImmediate(value_reg,
                              reinterpret_cast<intptr_t>(Object::null()));
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


LocationSummary* GuardFieldLengthInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  if (!opt || (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const intptr_t kNumTemps = 3;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
}


void GuardFieldLengthInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (field().guarded_list_length() == Field::kNoFixedLength) {
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  Label* deopt = compiler->is_optimizing() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField) : NULL;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();
    const Register offset_reg = locs()->temp(1).reg();
    const Register length_reg = locs()->temp(2).reg();

    Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    __ ldrsb(offset_reg, FieldAddress(field_reg,
        Field::guarded_list_length_in_object_offset_offset()));
    __ ldr(length_reg, FieldAddress(field_reg,
        Field::guarded_list_length_offset()));

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


class StoreInstanceFieldSlowPath : public SlowPathCode {
 public:
  StoreInstanceFieldSlowPath(StoreInstanceFieldInstr* instruction,
                             const Class& cls)
      : instruction_(instruction), cls_(cls) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();

    __ Comment("StoreInstanceFieldSlowPath");
    __ Bind(entry_label());

    const Code& stub =
        Code::Handle(isolate, stub_code->GetAllocationStubForClass(cls_));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->temp(0).reg(), R0);
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  StoreInstanceFieldInstr* instruction_;
  const Class& cls_;
};


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (IsUnboxedStore() && opt) ? 2 :
          ((IsPotentialUnboxedStore()) ? 3 : 0);
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps,
          ((IsUnboxedStore() && opt && is_initialization_) ||
           IsPotentialUnboxedStore())
          ? LocationSummary::kCallOnSlowPath
          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier()
        ? Location::WritableRegister()
        :  Location::RequiresRegister());
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


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label skip_store;

  const Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    const DRegister value = EvenDRegisterOf(locs()->in(1).fpu_reg());
    const Register temp = locs()->temp(0).reg();
    const Register temp2 = locs()->temp(1).reg();
    const intptr_t cid = field().UnboxedFieldCid();

    if (is_initialization_) {
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

      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, *cls);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(*cls,
                     slow_path->entry_label(),
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
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

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(field().raw()));

    __ ldr(temp2, FieldAddress(temp, Field::is_nullable_offset()));
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ ldrb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ tst(temp2, Operand(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ ldr(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ ldr(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

    __ ldr(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
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
      Label copy_double;
      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, compiler->double_class());
      compiler->AddSlowPathCode(slow_path);

      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes_));
      __ CompareImmediate(temp,
                          reinterpret_cast<intptr_t>(Object::null()));
      __ b(&copy_double, NE);

      __ TryAllocate(compiler->double_class(),
                     slow_path->entry_label(),
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ MoveRegister(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
      __ Bind(&copy_double);
      __ CopyDoubleField(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      Label copy_float32x4;
      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, compiler->float32x4_class());
      compiler->AddSlowPathCode(slow_path);

      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes_));
      __ CompareImmediate(temp,
                          reinterpret_cast<intptr_t>(Object::null()));
      __ b(&copy_float32x4, NE);

      __ TryAllocate(compiler->float32x4_class(),
                     slow_path->entry_label(),
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ MoveRegister(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
      __ Bind(&copy_float32x4);
      __ CopyFloat32x4Field(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      Label copy_float64x2;
      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, compiler->float64x2_class());
      compiler->AddSlowPathCode(slow_path);

      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes_));
      __ CompareImmediate(temp,
                          reinterpret_cast<intptr_t>(Object::null()));
      __ b(&copy_float64x2, NE);

      __ TryAllocate(compiler->float64x2_class(),
                     slow_path->entry_label(),
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ MoveRegister(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
      __ Bind(&copy_float64x2);
      __ CopyFloat64x2Field(temp, value_reg, TMP, temp2, fpu_temp);
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    const Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(instance_reg,
                             offset_in_bytes_,
                             value_reg,
                             CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrierOffset(
          instance_reg,
          offset_in_bytes_,
          locs()->in(1).constant());
    } else {
      const Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrierOffset(instance_reg,
                                        offset_in_bytes_,
                                        value_reg);
    }
  }
  __ Bind(&skip_store);
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  __ LoadFromOffset(kWord, result,
                    field, Field::value_offset() - kHeapObjectTag);
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, 1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();

  __ LoadObject(temp, field());
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(temp,
        FieldAddress(temp, Field::value_offset()), value, CanValueBeSmi());
  } else {
    __ StoreIntoObjectNoBarrier(
        temp, FieldAddress(temp, Field::value_offset()), value);
  }
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_in(1, Location::RegisterLocation(R2));
  summary->set_in(2, Location::RegisterLocation(R1));
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R0);  // Value.
  ASSERT(locs()->in(1).reg() == R2);  // Instantiator.
  ASSERT(locs()->in(2).reg() == R1);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out(0).reg() == R0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  const Register kLengthReg = R2;
  const Register kElemTypeReg = R1;
  const intptr_t kArraySize = Array::InstanceSize(num_elements);

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  __ LoadImmediate(R6, heap->TopAddress());
  __ ldr(R0, Address(R6, 0));  // Potential new object start.
  __ AddImmediate(R7, R0, kArraySize);  // Potential next object start.
  __ b(slow_path, VS);

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R7: potential next object start.
  __ LoadImmediate(R3, heap->EndAddress());
  __ ldr(R3, Address(R3, 0));
  __ cmp(R7, Operand(R3));
  __ b(slow_path, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ str(R7, Address(R6, 0));
  __ add(R0, R0, Operand(kHeapObjectTag));
  __ LoadImmediate(R8, heap->TopAddress());
  __ UpdateAllocationStatsWithSize(kArrayCid, R8, R4);


  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  {
    uword tags = 0;
    tags = RawObject::ClassIdTag::update(kArrayCid, tags);
    tags = RawObject::SizeTag::update(kArraySize, tags);
    __ LoadImmediate(R8, tags);
    __ str(R8, FieldAddress(R0, Array::tags_offset()));  // Store tags.
  }
  // R0: new object start as a tagged pointer.
  // R7: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(R0,
                              FieldAddress(R0, Array::type_arguments_offset()),
                              kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(R0,
                              FieldAddress(R0, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R7: new object end address.
  // R8: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R3: null
  __ LoadImmediate(R3, reinterpret_cast<intptr_t>(Object::null()));
  __ AddImmediate(R8, R0, sizeof(RawArray) - kHeapObjectTag);

  Label init_loop;
  __ Bind(&init_loop);
  __ cmp(R8, Operand(R7));
  __ str(R3, Address(R8, 0), CC);
  __ AddImmediate(R8, kWordSize, CC);
  __ b(&init_loop, CC);
  __ b(done);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register kLengthReg = R2;
  const Register kElemTypeReg = R1;
  const Register kResultReg = R0;

  ASSERT(locs()->in(kElementTypePos).reg() == kElemTypeReg);
  ASSERT(locs()->in(kLengthPos).reg() == kLengthReg);

  if (num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::ZoneHandle());  // Make room for the result.
      __ Push(kLengthReg);  // length.
      __ Push(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(),
                                    deopt_id(),
                                    kAllocateArrayRuntimeEntry,
                                    2,
                                    locs());
      __ Drop(2);
      __ Pop(kResultReg);
      __ Bind(&done);
      return;
    }
  }

  StubCode* stub_code = compiler->isolate()->stub_code();
  compiler->GenerateCall(token_pos(),
                         &stub_code->AllocateArrayLabel(),
                         RawPcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out(0).reg() == kResultReg);
}


class BoxDoubleSlowPath : public SlowPathCode {
 public:
  explicit BoxDoubleSlowPath(Instruction* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxDoubleSlowPath");
    __ Bind(entry_label());
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();
    const Class& double_class = compiler->double_class();
    const Code& stub =
        Code::Handle(isolate,
                     stub_code->GetAllocationStubForClass(double_class));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out(0).reg(), R0);
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  Instruction* instruction_;
};


class BoxFloat32x4SlowPath : public SlowPathCode {
 public:
  explicit BoxFloat32x4SlowPath(Instruction* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxFloat32x4SlowPath");
    __ Bind(entry_label());
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();
    const Class& float32x4_class = compiler->float32x4_class();
    const Code& stub =
        Code::Handle(isolate,
                     stub_code->GetAllocationStubForClass(float32x4_class));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ mov(locs->out(0).reg(), Operand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  Instruction* instruction_;
};


class BoxFloat64x2SlowPath : public SlowPathCode {
 public:
  explicit BoxFloat64x2SlowPath(Instruction* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxFloat64x2SlowPath");
    __ Bind(entry_label());
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();
    const Class& float64x2_class = compiler->float64x2_class();
    const Code& stub =
        Code::Handle(isolate,
                     stub_code->GetAllocationStubForClass(float64x2_class));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ mov(locs->out(0).reg(), Operand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  Instruction* instruction_;
};


LocationSummary* LoadFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 :
          ((IsPotentialUnboxedLoad()) ? 3 : 0);

  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps,
          (opt && !IsPotentialUnboxedLoad())
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
  const Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
    const Register temp = locs()->temp(0).reg();
    __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
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

    __ LoadObject(result_reg, Field::ZoneHandle(field()->raw()));

    FieldAddress field_cid_operand(result_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result_reg,
                                           Field::is_nullable_offset());

    __ ldr(temp, field_nullability_operand);
    __ CompareImmediate(temp, kNullCid);
    __ b(&load_pointer, EQ);

    __ ldr(temp, field_cid_operand);
    __ CompareImmediate(temp, kDoubleCid);
    __ b(&load_double, EQ);

    __ ldr(temp, field_cid_operand);
    __ CompareImmediate(temp, kFloat32x4Cid);
    __ b(&load_float32x4, EQ);

    __ ldr(temp, field_cid_operand);
    __ CompareImmediate(temp, kFloat64x2Cid);
    __ b(&load_float64x2, EQ);

    // Fall through.
    __ b(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(compiler->double_class(),
                     slow_path->entry_label(),
                     result_reg,
                     temp);
      __ Bind(slow_path->exit_label());
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyDoubleField(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxFloat32x4SlowPath* slow_path = new BoxFloat32x4SlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(compiler->float32x4_class(),
                     slow_path->entry_label(),
                     result_reg,
                     temp);
      __ Bind(slow_path->exit_label());
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyFloat32x4Field(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxFloat64x2SlowPath* slow_path = new BoxFloat64x2SlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(compiler->float64x2_class(),
                     slow_path->entry_label(),
                     result_reg,
                     temp);
      __ Bind(slow_path->exit_label());
      __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ CopyFloat64x2Field(result_reg, temp, TMP, temp2, value);
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFromOffset(kWord, result_reg,
                    instance_reg, offset_in_bytes() - kHeapObjectTag);
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register instantiator_reg = locs()->in(0).reg();
  const Register result_reg = locs()->out(0).reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(type());
  __ Push(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type.
  __ Pop(result_reg);  // Pop instantiated type.
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Register instantiator_reg = locs()->in(0).reg();
  const Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_reg == R0);
  ASSERT(instantiator_reg == result_reg);

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    __ LoadImmediate(IP, reinterpret_cast<intptr_t>(Object::null()));
    __ cmp(instantiator_reg, Operand(IP));
    __ b(&type_arguments_instantiated, EQ);
  }

  __ LoadObject(R2, type_arguments());
  __ ldr(R2, FieldAddress(R2, TypeArguments::instantiations_offset()));
  __ AddImmediate(R2, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, found, slow_case;
  __ Bind(&loop);
  __ ldr(R1, Address(R2, 0 * kWordSize));  // Cached instantiator.
  __ cmp(R1, Operand(R0));
  __ b(&found, EQ);
  __ AddImmediate(R2, 2 * kWordSize);
  __ CompareImmediate(R1, Smi::RawValue(StubCode::kNoInstantiator));
  __ b(&loop, NE);
  __ b(&slow_case);
  __ Bind(&found);
  __ ldr(R0, Address(R2, 1 * kWordSize));  // Cached instantiated args.
  __ b(&type_arguments_instantiated);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(type_arguments());
  __ Push(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ Pop(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->out(0).reg() == R0);

  __ LoadImmediate(R1, num_context_variables());
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel label(stub_code->AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register context_value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ Push(context_value);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ Drop(1);  // Remove argument.
  __ Pop(result);  // Get result (cloned context).
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNREACHABLE();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(),
                                try_index(),
                                compiler->assembler()->CodeSize(),
                                catch_handler_types_,
                                needs_stacktrace());

  // Restore the pool pointer.
  __ LoadPoolPointer();

  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

  // Restore stack and initialize the two exception variables:
  // exception and stack trace variables.
  __ StoreToOffset(kWord, kExceptionObjectReg,
                   FP, exception_var().index() * kWordSize);
  __ StoreToOffset(kWord, kStackTraceObjectReg,
                   FP, stacktrace_var().index() * kWordSize);
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (FLAG_use_osr) {
      uword flags_address = Isolate::Current()->stack_overflow_flags_address();
      const Register value = instruction_->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(IP, flags_address);
      __ LoadImmediate(value, Isolate::kOsrRequest);
      __ str(value, Address(IP));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  0,
                                  instruction_->locs());

    if (FLAG_use_osr && !compiler->is_optimizing() && instruction_->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     0);  // No token position.
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(FLAG_use_osr);
    return &osr_entry_label_;
  }

 private:
  CheckStackOverflowInstr* instruction_;
  Label osr_entry_label_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(IP, Isolate::Current()->stack_limit_address());
  __ ldr(IP, Address(IP));
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
  const bool is_truncating = shift_left->IsTruncating();
  const LocationSummary& locs = *shift_left->locs();
  const Register left = locs.in(0).reg();
  const Register result = locs.out(0).reg();
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), ICData::kDeoptBinarySmiOp)
      : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    if (value == 0) {
      __ MoveRegister(result, left);
    } else if ((value < 0) || (value >= kCountLimit)) {
      // This condition may not be known earlier in some cases because
      // of constant propagation, inlining, etc.
      if ((value >= kCountLimit) && is_truncating) {
        __ mov(result, Operand(0));
      } else {
        // Result is Mint or exception.
        __ b(deopt);
      }
    } else {
      if (!is_truncating) {
        // Check for overflow (preserve left).
        __ Lsl(IP, left, value);
        __ cmp(left, Operand(IP, ASR, value));
        __ b(deopt, NE);  // Overflow.
      }
      // Shift for result now we know there is no overflow.
      __ Lsl(result, left, value);
    }
    return;
  }

  // Right (locs.in(1)) is not constant.
  const Register right = locs.in(1).reg();
  Range* right_range = shift_left->right()->definition()->range();
  if (shift_left->left()->BindsToConstant() && !is_truncating) {
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
          (right_range == NULL) ||
          !right_range->IsWithin(0, max_right - 1);
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
      (right_range == NULL) || !right_range->IsWithin(0, (Smi::kBits - 1));
  if (is_truncating) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
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


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
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
  } else if (((op_kind() == Token::kSHL) && !IsTruncating()) ||
             (op_kind() == Token::kSHR)) {
    num_temps = 1;
  } else if ((op_kind() == Token::kMUL) &&
             (TargetCPUFeatures::arm_version() != ARMv7)) {
    num_temps = 1;
  }
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, num_temps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant->value()));
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
  if (((op_kind() == Token::kSHL) && !IsTruncating()) ||
      (op_kind() == Token::kSHR)) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (op_kind() == Token::kMUL) {
    if (TargetCPUFeatures::arm_version() != ARMv7) {
      summary->set_temp(0, Location::RequiresFpuRegister());
    }
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
          if (value == 2) {
            __ mov(result, Operand(left, LSL, 1));
          } else {
            __ LoadImmediate(IP, value);
            __ mul(result, left, IP);
          }
        } else {
          if (value == 2) {
            __ mov(IP, Operand(left, ASR, 31));  // IP = sign of left.
            __ mov(result, Operand(left, LSL, 1));
            // IP: result bits 32..63.
            __ cmp(IP, Operand(result, ASR, 31));
            __ b(deopt, NE);
          } else {
            if (TargetCPUFeatures::arm_version() == ARMv7) {
              __ LoadImmediate(IP, value);
              __ smull(result, IP, left, IP);
              // IP: result bits 32..63.
              __ cmp(IP, Operand(result, ASR, 31));
              __ b(deopt, NE);
            } else {
              const QRegister qtmp = locs()->temp(0).fpu_reg();
              const DRegister dtmp0 = EvenDRegisterOf(qtmp);
              const DRegister dtmp1 = OddDRegisterOf(qtmp);
              __ LoadImmediate(IP, value);
              __ CheckMultSignedOverflow(left, IP, result, dtmp0, dtmp1, deopt);
              __ mul(result, left, IP);
            }
          }
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 1) {
          __ MoveRegister(result, left);
          break;
        } else if (value == -1) {
          // Check the corner case of dividing the 'MIN_SMI' with -1, in which
          // case we cannot negate the result.
          __ CompareImmediate(left, 0x80000000);
          __ b(deopt, EQ);
          __ rsb(result, left, Operand(0));
          break;
        }
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

        if (value == 0) {
          // TODO(vegorov): should be handled outside.
          __ MoveRegister(result, left);
          break;
        } else if (value < 0) {
          // TODO(vegorov): should be handled outside.
          __ b(deopt);
          break;
        }

        value = value + kSmiTagSize;
        if (value >= kCountLimit) {
          value = kCountLimit;
        }

        __ Asr(result, left, value);
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
  Range* right_range = this->right()->definition()->range();
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
        if (TargetCPUFeatures::arm_version() == ARMv7) {
          __ smull(result, IP, IP, right);
          // IP: result bits 32..63.
          __ cmp(IP, Operand(result, ASR, 31));
          __ b(deopt, NE);
        } else {
          const QRegister qtmp = locs()->temp(0).fpu_reg();
          const DRegister dtmp0 = EvenDRegisterOf(qtmp);
          const DRegister dtmp1 = OddDRegisterOf(qtmp);
          __ CheckMultSignedOverflow(IP, right, result, dtmp0, dtmp1, deopt);
          __ mul(result, IP, right);
        }
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
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      if ((right_range == NULL) ||
          !right_range->OnlyLessThanOrEqualTo(kCountLimit)) {
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


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptBinaryDoubleOp);
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


LocationSummary* BoxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  const Register out_reg = locs()->out(0).reg();
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());

  __ TryAllocate(compiler->double_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());
  __ StoreDToOffset(value, out_reg, Double::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t value_cid = value()->Type()->ToCid();
  const bool needs_temp = ((value_cid != kSmiCid) && (value_cid != kDoubleCid));
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (needs_temp) summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CompileType* value_type = value()->Type();
  const intptr_t value_cid = value_type->ToCid();
  const Register value = locs()->in(0).reg();
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());

  if (value_cid == kDoubleCid) {
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(IP, value);
    __ vmovsr(STMP, IP);
    __ vcvtdi(result, STMP);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptBinaryDoubleOp);
    const Register temp = locs()->temp(0).reg();
    if (value_type->is_nullable() &&
        (value_type->ToNullableCid() == kDoubleCid)) {
      __ CompareImmediate(value, reinterpret_cast<intptr_t>(Object::null()));
      __ b(deopt, EQ);
      // It must be double now.
      __ LoadDFromOffset(result, value,
          Double::value_offset() - kHeapObjectTag);
    } else {
      Label is_smi, done;
      __ tst(value, Operand(kSmiTagMask));
      __ b(&is_smi, EQ);
      __ CompareClassId(value, kDoubleCid, temp);
      __ b(deopt, NE);
      __ LoadDFromOffset(result, value,
          Double::value_offset() - kHeapObjectTag);
      __ b(&done);
      __ Bind(&is_smi);
      __ SmiUntag(IP, value);
      __ vmovsr(STMP, IP);
      __ vcvtdi(result, STMP);
      __ Bind(&done);
    }
  }
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat32x4SlowPath* slow_path = new BoxFloat32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  const Register out_reg = locs()->out(0).reg();
  const QRegister value = locs()->in(0).fpu_reg();
  const DRegister dvalue0 = EvenDRegisterOf(value);

  __ TryAllocate(compiler->float32x4_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());

  __ StoreMultipleDToOffset(dvalue0, 2, out_reg,
      Float32x4::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kFloat32x4Cid ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const QRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ tst(value, Operand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kFloat32x4Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister dresult0 = EvenDRegisterOf(result);
  __ LoadMultipleDFromOffset(dresult0, 2, value,
      Float32x4::value_offset() - kHeapObjectTag);
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat64x2SlowPath* slow_path = new BoxFloat64x2SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  const Register out_reg = locs()->out(0).reg();
  const QRegister value = locs()->in(0).fpu_reg();
  const DRegister dvalue0 = EvenDRegisterOf(value);

  __ TryAllocate(compiler->float64x2_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());

  __ StoreMultipleDToOffset(dvalue0, 2, out_reg,
      Float64x2::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kFloat64x2Cid ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const QRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat64x2Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ tst(value, Operand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kFloat64x2Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister dresult0 = EvenDRegisterOf(result);
  __ LoadMultipleDFromOffset(dresult0, 2, value,
      Float64x2::value_offset() - kHeapObjectTag);
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


class BoxInt32x4SlowPath : public SlowPathCode {
 public:
  explicit BoxInt32x4SlowPath(BoxInt32x4Instr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxInt32x4SlowPath");
    __ Bind(entry_label());
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();
    const Class& int32x4_class = compiler->int32x4_class();
    const Code& stub =
        Code::Handle(isolate,
                     stub_code->GetAllocationStubForClass(int32x4_class));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ mov(locs->out(0).reg(), Operand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  BoxInt32x4Instr* instruction_;
};


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxInt32x4SlowPath* slow_path = new BoxInt32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  const Register out_reg = locs()->out(0).reg();
  const QRegister value = locs()->in(0).fpu_reg();
  const DRegister dvalue0 = EvenDRegisterOf(value);

  __ TryAllocate(compiler->int32x4_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());
  __ StoreMultipleDToOffset(dvalue0, 2, out_reg,
      Int32x4::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kInt32x4Cid ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const QRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kInt32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ tst(value, Operand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kInt32x4Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister dresult0 = EvenDRegisterOf(result);
  __ LoadMultipleDFromOffset(dresult0, 2, value,
      Int32x4::value_offset() - kHeapObjectTag);
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case Token::kADD: __ vaddd(result, left, right); break;
    case Token::kSUB: __ vsubd(result, left, right); break;
    case Token::kMUL: __ vmuld(result, left, right); break;
    case Token::kDIV: __ vdivd(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case Token::kADD: __ vaddqs(result, left, right); break;
    case Token::kSUB: __ vsubqs(result, left, right); break;
    case Token::kMUL: __ vmulqs(result, left, right); break;
    case Token::kDIV: __ Vdivqs(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      } else  if (mask_ == 0xFF) {
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
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  __ Lsr(out, out, 31);
  // Y lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue0));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, EvenSRegisterOf(dvalue1));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue1));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 3));
  // Tag.
  __ SmiTag(out);
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->out(0).fpu_reg();
  __ veorq(q, q, q);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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

    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister q = locs()->out(0).fpu_reg();
  __ veorq(q, q, q);
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);

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
    __ Lsr(out, out, 31);
    // Upper 32-bits of Y lane.
    __ vmovrs(TMP, OddSRegisterOf(dvalue1));
    __ Lsr(TMP, TMP, 31);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  // Low (< 7) Q register needed for the vmovsr instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
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
  const SRegister sresult0 = EvenSRegisterOf(dresult0);
  const SRegister sresult1 = OddSRegisterOf(dresult0);
  const SRegister sresult2 = EvenSRegisterOf(dresult1);
  const SRegister sresult3 = OddSRegisterOf(dresult1);

  __ veorq(result, result, result);
  __ LoadImmediate(temp, 0xffffffff);

  __ CompareObject(v0, Bool::True());
  __ vmovsr(sresult0, temp, EQ);

  __ CompareObject(v1, Bool::True());
  __ vmovsr(sresult1, temp, EQ);

  __ CompareObject(v2, Bool::True());
  __ vmovsr(sresult2, temp, EQ);

  __ CompareObject(v3, Bool::True());
  __ vmovsr(sresult3, temp, EQ);
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    default: UNREACHABLE();
  }

  __ tst(result, Operand(result));
  __ LoadObject(result, Bool::True(), NE);
  __ LoadObject(result, Bool::False(), EQ);
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  // Low (< 7) Q register needed for the vmovsr instruction.
  summary->set_out(0, Location::FpuRegisterLocation(Q6));
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const QRegister mask = locs()->in(0).fpu_reg();
  const Register flag = locs()->in(1).reg();
  const QRegister result = locs()->out(0).fpu_reg();

  const DRegister dresult0 = EvenDRegisterOf(result);
  const DRegister dresult1 = OddDRegisterOf(result);
  const SRegister sresult0 = EvenSRegisterOf(dresult0);
  const SRegister sresult1 = OddSRegisterOf(dresult0);
  const SRegister sresult2 = EvenSRegisterOf(dresult1);
  const SRegister sresult3 = OddSRegisterOf(dresult1);

  if (result != mask) {
    __ vmovq(result, mask);
  }

  __ CompareObject(flag, Bool::True());
  __ LoadImmediate(TMP, 0xffffffff, EQ);
  __ LoadImmediate(TMP, 0, NE);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4WithFlagX:
      __ vmovsr(sresult0, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagY:
      __ vmovsr(sresult1, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagZ:
      __ vmovsr(sresult2, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagW:
      __ vmovsr(sresult3, TMP);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case Token::kBIT_AND: __ vandq(result, left, right); break;
    case Token::kBIT_OR: __ vorrq(result, left, right); break;
    case Token::kBIT_XOR: __ veorq(result, left, right); break;
    case Token::kADD: __ vaddqi(kWord, result, left, right); break;
    case Token::kSUB: __ vsubqi(kWord, result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  if ((kind() == MathUnaryInstr::kSin) || (kind() == MathUnaryInstr::kCos)) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = TargetCPUFeatures::hardfp_supported() ? 0 : 4;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(Q0));
    summary->set_out(0, Location::FpuRegisterLocation(Q0));
    if (!TargetCPUFeatures::hardfp_supported()) {
      summary->set_temp(0, Location::RegisterLocation(R0));
      summary->set_temp(1, Location::RegisterLocation(R1));
      summary->set_temp(2, Location::RegisterLocation(R2));
      summary->set_temp(3, Location::RegisterLocation(R3));
    }
    return summary;
  }
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    ASSERT((kind() == MathUnaryInstr::kSin) ||
           (kind() == MathUnaryInstr::kCos));
    if (TargetCPUFeatures::hardfp_supported()) {
      __ CallRuntime(TargetFunction(), InputCount());
      } else {
      // If we aren't doing "hardfp", then we have to move the double arguments
      // to the integer registers, and take the results from the integer
      // registers.
      __ vmovrrd(R0, R1, D0);
      __ vmovrrd(R2, R3, D1);
      __ CallRuntime(TargetFunction(), InputCount());
      __ vmovdrr(D0, R0, R1);
      __ vmovdrr(D1, R2, R3);
    }
  }
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  __ vnegd(result, value);
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const DRegister result = EvenDRegisterOf(locs()->out(0).fpu_reg());
  __ SmiUntag(IP, value);
  __ vmovsr(STMP, IP);
  __ vcvtdi(result, STMP);
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  ASSERT((ic_data.NumberOfChecks() == 1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));

  const intptr_t kNumberOfArguments = 1;
  compiler->GenerateStaticCall(deopt_id(),
                               instance_call()->token_pos(),
                               target,
                               kNumberOfArguments,
                               Object::null_array(),  // No argument names.,
                               locs(),
                               ICData::Handle());
  __ Bind(&done);
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (TargetCPUFeatures::hardfp_supported()) ?
        ((recognized_kind() == MethodRecognizer::kMathDoublePow) ? 1 : 0) : 4;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, InputCount(), kNumTemps, LocationSummary::kCall);
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
  __ b(&skip_call, EQ);  // exp is 0.0, result is 1.0.

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
  __ b(&try_sqrt, VC);  // // Neither 'exp' nor 'base' is NaN.

  __ Bind(&return_nan);
  __ LoadDImmediate(result, NAN, temp);
  __ b(&skip_call);

  Label do_pow, return_zero;
  __ Bind(&try_sqrt);

  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadDImmediate(result, -INFINITY, temp);

  // base == -Infinity -> call pow;
  __ vcmpd(saved_base, result);
  __ b(&do_pow, EQ);

  // exponent == 0.5 ?
  __ LoadDImmediate(result, 0.5, temp);
  __ vcmpd(exp, result);
  __ b(&do_pow, NE);

  // base == 0 -> return 0;
  __ vcmpdz(saved_base);
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


LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  // Only use this instruction in optimized code.
  ASSERT(opt);
  const intptr_t kNumInputs = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, 0, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    if (index() == 0) {
      summary->set_in(0, Location::Pair(Location::RequiresFpuRegister(),
                                        Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(0, Location::Pair(Location::Any(),
                                        Location::RequiresFpuRegister()));
    }
    summary->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(representation() == kTagged);
    if (index() == 0) {
      summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                        Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(0, Location::Pair(Location::Any(),
                                        Location::RequiresRegister()));
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


LocationSummary* MergedMathInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 2;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresFpuRegister());
    // Output is a pair of registers.
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
    return summary;
  }
  UNIMPLEMENTED();
  return NULL;
}


void MergedMathInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const Register left = locs()->in(0).reg();
    const Register right = locs()->in(1).reg();
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* pair = locs()->out(0).AsPairLocation();
    const Register result_div = pair->At(0).reg();
    const Register result_mod = pair->At(1).reg();
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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

    return;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    UNIMPLEMENTED();
  }
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(
      deopt_id(), ICData::kDeoptPolymorphicInstanceCallTestFail);
  if (ic_data().NumberOfChecks() == 0) {
    __ b(deopt);
    return;
  }
  ASSERT(ic_data().NumArgsTested() == 1);
  if (!with_checks()) {
    ASSERT(ic_data().HasOneTarget());
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(deopt_id(),
                                 instance_call()->token_pos(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs(),
                                 ICData::Handle());
    return;
  }

  // Load receiver into R0.
  __ LoadFromOffset(kWord, R0, SP,
                    (instance_call()->ArgumentCount() - 1) * kWordSize);

  LoadValueCid(compiler, R2, R0,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            R2,  // Class id register.
                            instance_call()->ArgumentCount(),
                            instance_call()->argument_names(),
                            deopt,
                            deopt_id(),
                            instance_call()->token_pos(),
                            locs());
}


LocationSummary* BranchInstr::MakeLocationSummary(Isolate* isolate,
                                                  bool opt) const {
  comparison()->InitializeLocationSummary(isolate, opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = !IsNullCheck() ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData::DeoptReasonId deopt_reason = licm_hoisted_ ?
      ICData::kDeoptHoistedCheckClass : ICData::kDeoptCheckClass;
  if (IsNullCheck()) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
    __ CompareImmediate(locs()->in(0).reg(),
                        reinterpret_cast<intptr_t>(Object::null()));
    __ b(deopt, EQ);
    return;
  }

  ASSERT((unary_checks().GetReceiverClassIdAt(0) != kSmiCid) ||
         (unary_checks().NumberOfChecks() > 1));
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
  Label is_ok;
  intptr_t cix = 0;
  if (unary_checks().GetReceiverClassIdAt(cix) == kSmiCid) {
    __ tst(value, Operand(kSmiTagMask));
    __ b(&is_ok, EQ);
    cix++;  // Skip first check.
  } else {
    __ tst(value, Operand(kSmiTagMask));
    __ b(deopt, EQ);
  }
  __ LoadClassId(temp, value);
  const intptr_t num_checks = unary_checks().NumberOfChecks();
  for (intptr_t i = cix; i < num_checks; i++) {
    ASSERT(unary_checks().GetReceiverClassIdAt(i) != kSmiCid);
    __ CompareImmediate(temp, unary_checks().GetReceiverClassIdAt(i));
    if (i == (num_checks - 1)) {
      __ b(deopt, NE);
    } else {
      __ b(&is_ok, EQ);
    }
  }
  __ Bind(&is_ok);
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi);
  __ tst(value, Operand(kSmiTagMask));
  __ b(deopt, NE);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptCheckArrayBound);

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

  if (index_loc.IsConstant()) {
    const Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(length, reinterpret_cast<int32_t>(index.raw()));
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    const Register index = index_loc.reg();
    __ CompareImmediate(index, reinterpret_cast<int32_t>(length.raw()));
    __ b(deopt, CS);
  } else {
    const Register length = length_loc.reg();
    const Register index = index_loc.reg();
    __ cmp(index, Operand(length));
    __ b(deopt, CS);
  }
}


static void EmitJavascriptIntOverflowCheck(FlowGraphCompiler* compiler,
                                           Label* overflow,
                                           Register result_lo,
                                           Register result_hi) {
  // Compare upper half.
  Label check_lower;
  __ CompareImmediate(result_hi, 0x00200000);
  __ b(overflow, GT);
  __ b(&check_lower, NE);

  __ CompareImmediate(result_lo, 0);
  __ b(overflow, HI);

  __ Bind(&check_lower);
  __ CompareImmediate(result_hi, -0x00200000);
  __ b(overflow, LT);
  // Anything in the lower part would make the number bigger than the lower
  // bound, so we are done.
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0,  Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
  return summary;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  PairLocation* result_pair = locs()->out(0).AsPairLocation();
  Register result_lo = result_pair->At(0).reg();
  Register result_hi = result_pair->At(1).reg();
  ASSERT(value != result_lo);
  ASSERT(value != result_hi);

  __ Comment("UnboxIntegerInstr");
  if (value_cid == kMintCid) {
    // Load low word.
    __ LoadFromOffset(kWord,
                      result_lo,
                      value,
                      Mint::value_offset() - kHeapObjectTag);
    // Load high word.
    __ LoadFromOffset(kWord,
                      result_hi,
                      value,
                      Mint::value_offset() - kHeapObjectTag + kWordSize);
  } else if (value_cid == kSmiCid) {
    // Load Smi into result_lo.
    __ mov(result_lo, Operand(value));
    // Untag.
    __ SmiUntag(result_lo);
    __ SignFill(result_hi, result_lo);
  } else {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptUnboxInteger);
    Label is_smi, done;
    __ tst(value, Operand(kSmiTagMask));
    __ b(&is_smi, EQ);
    __ CompareClassId(value, kMintCid, temp);
    __ b(deopt, NE);

    // It's a Mint.
    // Load low word.
    __ LoadFromOffset(kWord,
                      result_lo,
                      value,
                      Mint::value_offset() - kHeapObjectTag);
    // Load high word.
    __ LoadFromOffset(kWord,
                      result_hi,
                      value,
                      Mint::value_offset() - kHeapObjectTag + kWordSize);
    __ b(&done);

    // It's a Smi.
    __ Bind(&is_smi);
    // Load Smi into result_lo.
    __ mov(result_lo, Operand(value));
    // Untag.
    __ SmiUntag(result_lo);
    // Sign extend result_lo into result_hi.
    __ SignFill(result_hi, result_lo);
    __ Bind(&done);
  }
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = is_smi() ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          is_smi()
                              ? LocationSummary::kNoCall
                              : LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  if (!is_smi()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


class BoxIntegerSlowPath : public SlowPathCode {
 public:
  explicit BoxIntegerSlowPath(BoxIntegerInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxIntegerSlowPath");
    __ Bind(entry_label());
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();
    const Class& mint_class =
        Class::ZoneHandle(isolate->object_store()->mint_class());
    const Code& stub =
        Code::Handle(isolate, stub_code->GetAllocationStubForClass(mint_class));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ mov(locs->out(0).reg(), Operand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  BoxIntegerInstr* instruction_;
};


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (is_smi()) {
    PairLocation* value_pair = locs()->in(0).AsPairLocation();
    Register value_lo = value_pair->At(0).reg();
    Register out_reg = locs()->out(0).reg();
    __ mov(out_reg, Operand(value_lo));
    __ SmiTag(out_reg);
    return;
  }

  BoxIntegerSlowPath* slow_path = new BoxIntegerSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register tmp = locs()->temp(0).reg();
  Register out_reg = locs()->out(0).reg();

  // Unboxed operations produce smis or mint-sized values.
  // Check if value fits into a smi.
  __ Comment("BoxIntegerInstr");
  Label not_smi, done, maybe_pos_smi, maybe_neg_smi, is_smi;
  // Check high word.
  __ CompareImmediate(value_hi, 0);
  __ b(&maybe_pos_smi, EQ);

  __ CompareImmediate(value_hi, -1);
  __ b(&maybe_neg_smi, EQ);
  __ b(&not_smi);

  __ Bind(&maybe_pos_smi);
  __ CompareImmediate(value_lo, kSmiMax);
  __ b(&is_smi, LS);  // unsigned lower or same.
  __ b(&not_smi);

  __ Bind(&maybe_neg_smi);
  __ CompareImmediate(value_lo, 0);
  __ b(&not_smi, GE);
  __ CompareImmediate(value_lo, kSmiMin);
  __ b(&not_smi, LT);

  // lo is a Smi. Tag it and return.
  __ Bind(&is_smi);
  __ mov(out_reg, Operand(value_lo));
  __ SmiTag(out_reg);
  __ b(&done);

  // Not a smi. Box it.
  __ Bind(&not_smi);
  __ TryAllocate(
      Class::ZoneHandle(Isolate::Current()->object_store()->mint_class()),
      slow_path->entry_label(),
      out_reg,
      tmp);
  __ Bind(slow_path->exit_label());
  __ StoreToOffset(kWord,
                   value_lo,
                   out_reg,
                   Mint::value_offset() - kHeapObjectTag);
  __ StoreToOffset(kWord,
                   value_hi,
                   out_reg,
                   Mint::value_offset() - kHeapObjectTag + kWordSize);
  __ Bind(&done);
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    }
    break;
    case Token::kBIT_OR: {
      __ orr(out_lo, left_lo, Operand(right_lo));
      __ orr(out_hi, left_hi, Operand(right_hi));
    }
    break;
    case Token::kBIT_XOR: {
     __ eor(out_lo, left_lo, Operand(right_lo));
     __ eor(out_hi, left_hi, Operand(right_hi));
    }
    break;
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
    default:
      UNREACHABLE();
    break;
  }
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, out_lo, out_hi);
  }
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::WritableRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


static const intptr_t kMintShiftCountLimit = 63;

bool ShiftMintOpInstr::has_shift_count_check() const {
  return (right()->definition()->range() == NULL)
      || !right()->definition()->range()->IsWithin(0, kMintShiftCountLimit);
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  Register shift = locs()->in(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  Register temp = locs()->temp(0).reg();

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptShiftMintOp);
  }
  __ mov(out_lo, Operand(left_lo));
  __ mov(out_hi, Operand(left_hi));

  // Untag shift count.
  __ SmiUntag(shift);

  // Deopt if shift is larger than 63 or less than 0.
  if (has_shift_count_check()) {
    __ CompareImmediate(shift, kMintShiftCountLimit);
    __ b(deopt, HI);
  }

  switch (op_kind()) {
    case Token::kSHR: {
      __ cmp(shift, Operand(32));

      __ mov(out_lo, Operand(out_hi), HI);
      __ Asr(out_hi, out_hi, 31, HI);
      __ sub(shift, shift, Operand(32), HI);

      __ rsb(temp, shift, Operand(32));
      __ mov(temp, Operand(out_hi, LSL, temp));
      __ orr(out_lo, temp, Operand(out_lo, LSR, shift));
      __ Asr(out_hi, out_hi, shift);
      break;
    }
    case Token::kSHL: {
      __ rsbs(temp, shift, Operand(32));
      __ sub(temp, shift, Operand(32), MI);
      __ mov(out_hi, Operand(out_lo, LSL, temp), MI);
      __ mov(out_hi, Operand(out_hi, LSL, shift), PL);
      __ orr(out_hi, out_hi, Operand(out_lo, LSR, temp), PL);
      __ mov(out_lo, Operand(out_lo, LSL, shift));

      // Check for overflow.
      if (can_overflow()) {
        // Copy high word from output.
        __ mov(temp, Operand(out_hi));
        // Shift copy right.
        __ Asr(temp, temp, shift);
        // Compare with high word from input.
        __ cmp(temp, Operand(left_hi));
        // Overflow if they aren't equal.
        __ b(deopt, NE);
      }
      break;
    }
    default:
      UNREACHABLE();
      break;
  }

  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, out_lo, out_hi);
  }
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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

  Label* deopt = NULL;

  if (FLAG_throw_on_javascript_int_overflow) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryMintOp);
  }
  __ mvn(out_lo, Operand(left_lo));
  __ mvn(out_hi, Operand(left_hi));
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, out_lo, out_hi);
  }
}


LocationSummary* ThrowInstr::MakeLocationSummary(Isolate* isolate,
                                                 bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kCall);
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kThrowRuntimeEntry,
                                1,
                                locs());
  __ bkpt(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary(Isolate* isolate,
                                                   bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStacktrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kReThrowRuntimeEntry,
                                2,
                                locs());
  __ bkpt(0);
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
  }
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter();
    }
    // Add an edge counter.
    // On ARM the deoptimization descriptor points after the edge counter
    // code so that we can reuse the same pattern matching code as at call
    // sites, which matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   deopt_id_,
                                   Scanner::kNoSourcePos);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(Isolate* isolate,
                                                bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->is_optimizing()) {
    if (FLAG_emit_edge_counters) {
      compiler->EmitEdgeCounter();
    }
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.  On ARM this descriptor
    // points after the edge counter code so that we can reuse the same
    // pattern matching code as at call sites, which matches backwards from
    // the end of the pattern.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   GetDeoptId(),
                                   Scanner::kNoSourcePos);
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


LocationSummary* CurrentContextInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ mov(locs()->out(0).reg(), Operand(CTX));
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(R0));
    locs->set_in(1, Location::RegisterLocation(R1));
    locs->set_out(0, Location::RegisterLocation(R0));
    return locs;
  }
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterOrConstant(left()));
  // Only one of the inputs can be a constant. Choose register if the first one
  // is a constant.
  locs->set_in(1, locs->in(0).IsConstant()
                      ? Location::RequiresRegister()
                      : Location::RegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(),
                                          left.constant(),
                                          needs_number_check(),
                                          token_pos());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(),
                                          right.constant(),
                                          needs_number_check(),
                                          token_pos());
  } else {
    compiler->EmitEqualityRegRegCompare(left.reg(),
                                       right.reg(),
                                       needs_number_check(),
                                       token_pos());
  }
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQ : NE;
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  const Register result = locs()->out(0).reg();
  __ LoadObject(result, Bool::True(), true_condition);
  __ LoadObject(result, Bool::False(), NegateCondition(true_condition));
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  return LocationSummary::Make(isolate,
                               1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ LoadObject(result, Bool::True());
  __ cmp(result, Operand(value));
  __ LoadObject(result, Bool::False(), EQ);
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Isolate* isolate = compiler->isolate();
  StubCode* stub_code = isolate->stub_code();
  const Code& stub = Code::Handle(isolate,
                                  stub_code->GetAllocationStubForClass(cls()));
  const ExternalLabel label(stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel label(stub_code->DebugStepCheckEntryPoint());
  __ LoadImmediate(R4, 0);
  __ LoadImmediate(R5, 0);
  compiler->GenerateCall(token_pos(), &label, stub_kind_, locs());
#if defined(DEBUG)
  __ LoadImmediate(R4, kInvalidObjectPointer);
  __ LoadImmediate(R5, kInvalidObjectPointer);
#endif
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
