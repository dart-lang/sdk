// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/intermediate_language.h"

#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(R0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      __ LoadFromOffset(TMP, value.base_reg(), value_offset);
      __ Push(TMP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone,
                                                  bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    __ ret();
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
  __ brk(0);
  __ Bind(&stack_ok);
#endif
  ASSERT(__ constant_pool_allowed());
  __ LeaveDartFrame();  // Disallows constant pool use.
  __ ret();
  // This ReturnInstr may be emitted out of order by the optimizer. The next
  // block may be a target expecting a properly set constant pool pointer.
  __ set_constant_pool_allowed(true);
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

  __ cset(result, true_condition);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ LslImmediate(result, result, shift + kSmiTagSize);
  } else {
    __ sub(result, result, Operand(1));
    const int64_t val =
        Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, result, Smi::RawValue(false_value));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  __ LoadFieldFromOffset(CODE_REG, R0, Function::code_offset());
  __ LoadFieldFromOffset(R2, R0, Function::entry_point_offset());

  // R2: instructions.
  // R5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ LoadImmediate(R5, 0);
  //??
  __ blr(R2);
  compiler->RecordSafepoint(locs());
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after, token_pos());
  }
  // Add deoptimization continuation point after the call and before the
  // arguments are removed.
  // In optimized code this descriptor is needed for exception handling.
  compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                 deopt_id_after,
                                 token_pos());
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();
  __ LoadFromOffset(result, FP, local().index() * kWordSize);
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return LocationSummary::Make(zone,
                               1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ StoreToOffset(value, FP, local().index() * kWordSize);
}


LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  return LocationSummary::Make(zone,
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


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const Location out = (representation_ == kUnboxedInt32) ?
      Location::RequiresRegister() : Location::RequiresFpuRegister();
  return LocationSummary::Make(zone,
                               kNumInputs,
                               out,
                               LocationSummary::kNoCall);
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!locs()->out(0).IsInvalid()) {
    switch (representation_) {
      case kUnboxedDouble:
        if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0)) {
          const VRegister dst = locs()->out(0).fpu_reg();
          __ veor(dst, dst, dst);
        } else {
          const VRegister dst = locs()->out(0).fpu_reg();
          __ LoadDImmediate(dst, Double::Cast(value()).value());
        }
        break;
      case kUnboxedInt32:
        __ LoadImmediate(locs()->out(0).reg(),
                         static_cast<int32_t>(Smi::Cast(value()).Value()));
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Value.
  summary->set_in(1, Location::RegisterLocation(R1));  // Type arguments.
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  compiler->GenerateRuntimeCall(token_pos,
                                deopt_id,
                                kNonBoolTypeErrorRuntimeEntry,
                                1,
                                locs);
  // We should never return here.
  __ brk(0);
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
    __ CompareRegisters(left.reg(), right.reg());
  }
  return true_condition;
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps =  0;
    LocationSummary* locs = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    // Only right can be a stack slot.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : Location::RegisterOrConstant(right()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  UNREACHABLE();
  return NULL;
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
  const VRegister left = locs->in(0).fpu_reg();
  const VRegister right = locs->in(1).fpu_reg();
  __ fcmpd(left, right);
  Condition true_condition = TokenKindToDoubleCondition(kind);
  return true_condition;
}


Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind());
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kEQ) || (kind() == Token::kNE));
  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if ((operation_cid() == kDoubleCid) && (true_condition != NE)) {
    // Special case for NaN comparison. Result is always false unless
    // relational operator is !=.
    __ b(&is_false, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
  // TODO(zra): instead of branching, use the csel instruction to get
  // True or False into result.
  const Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if ((operation_cid() == kDoubleCid) && (true_condition != NE)) {
    // Special case for NaN comparison. Result is always false unless
    // relational operator is !=.
    __ b(labels.false_label, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestSmiInstr::MakeLocationSummary(Zone* zone,
                                                   bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    const int64_t imm =
        reinterpret_cast<int64_t>(right.constant().raw());
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


LocationSummary* TestCidsInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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

  Label* deopt = CanDeoptimize()
      ? compiler->AddDeoptStub(deopt_id(),
                               ICData::kDeoptTestCids,
                               licm_hoisted_ ? ICData::kHoisted : 0)
      : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ tsti(val_reg, Immediate(kSmiTagMask));
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
  // TODO(zra): instead of branching, use the csel instruction to get
  // True or False into result.
  __ Bind(&is_false);
  __ LoadObject(result_reg, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True());
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if ((operation_cid() == kDoubleCid) && (true_condition != NE)) {
    // Special case for NaN comparison. Result is always false unless
    // relational operator is !=.
    __ b(&is_false, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
  // TODO(zra): instead of branching, use the csel instruction to get
  // True or False into result.
  const Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if ((operation_cid() == kDoubleCid) && (true_condition != NE)) {
    // Special case for NaN comparison. Result is always false unless
    // relational operator is !=.
    __ b(labels.false_label, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
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
    __ AddImmediate(R2, FP, (kParamEndSlotFromFp +
                             function().NumParameters()) * kWordSize);
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
    stub_entry = StubCode::CallBootstrapCFunction_entry();
    entry = NativeEntry::LinkNativeCallEntry();
  } else {
    entry = reinterpret_cast<uword>(native_c_function());
    if (is_bootstrap_native()) {
      stub_entry = StubCode::CallBootstrapCFunction_entry();
#if defined(USING_SIMULATOR)
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, NativeEntry::kNumArguments);
#endif
    } else {
      // In the case of non bootstrap native methods the CallNativeCFunction
      // stub generates the redirection address when running under the simulator
      // and hence we do not change 'entry' here.
      stub_entry = StubCode::CallNativeCFunction_entry();
    }
  }
  __ LoadImmediate(R1, argc_tag);
  ExternalLabel label(entry);
  __ LoadNativeEntry(R5, &label);
  compiler->GenerateCall(token_pos(),
                         *stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* OneByteStringFromCharCodeInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(zone,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void OneByteStringFromCharCodeInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  const Register char_code = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ ldr(result, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      result, result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ SmiUntag(TMP, char_code);  // Untag to use scaled adress mode.
  __ ldr(result, Address(result, TMP, UXTX, Address::Scaled));
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(cid_ == kOneByteStringCid);
  const Register str = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ LoadFieldFromOffset(result, str, String::length_offset());
  __ ldr(TMP, FieldAddress(str, OneByteString::data_offset()), kUnsignedByte);
  __ CompareImmediate(result, Smi::RawValue(1));
  __ LoadImmediate(result, -1);
  __ csel(result, TMP, result, EQ);
  __ SmiTag(result);
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone,
                               kNumInputs,
                               Location::RequiresRegister(),
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


LocationSummary* LoadClassIdInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone,
                               kNumInputs,
                               Location::RequiresRegister(),
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
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return CompileType::FromCid(kSmiCid);

    default:
      UNIMPLEMENTED();
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
  const int64_t offset = index * scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  if (!Utils::IsInt(32, offset)) {
    return false;
  }
  return Address::CanHoldOffset(static_cast<int32_t>(offset),
                                Address::Offset,
                                Address::OperandSizeFor(cid));
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
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

  Address element_address = index.IsRegister()
      ? __ ElementAddressForRegIndex(true,  // Load.
                                     IsExternal(), class_id(), index_scale(),
                                     array, index.reg())
      : __ ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());
  // Warning: element_address may use register TMP as base.

  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
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

  if ((representation() == kUnboxedInt32) ||
      (representation() == kUnboxedUint32)) {
    const Register result = locs()->out(0).reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        ASSERT(representation() == kUnboxedInt32);
        __ ldr(result, element_address, kWord);
        break;
      case kTypedDataUint32ArrayCid:
        ASSERT(representation() == kUnboxedUint32);
        __ ldr(result, element_address, kUnsignedWord);
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
      __ ldr(result, element_address, kByte);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ ldr(result, element_address, kUnsignedByte);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ ldr(result, element_address, kHalfword);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      __ ldr(result, element_address, kUnsignedHalfword);
      __ SmiTag(result);
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ ldr(result, element_address);
      break;
  }
}


LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = __ ElementAddressForRegIndex(
        true,  IsExternal(), class_id(), index_scale(), str, index.reg());
  // Warning: element_address may use register TMP as base.

  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      switch (element_count()) {
        case 1: __ ldr(result, element_address, kUnsignedByte); break;
        case 2: __ ldr(result, element_address, kUnsignedHalfword); break;
        case 4: __ ldr(result, element_address, kUnsignedWord); break;
        default: UNREACHABLE();
      }
      __ SmiTag(result);
      break;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      switch (element_count()) {
        case 1: __ ldr(result, element_address, kUnsignedHalfword); break;
        case 2: __ ldr(result, element_address, kUnsignedWord); break;
        default: UNREACHABLE();
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
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::WritableRegister());
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

  Address element_address = index.IsRegister()
      ? __ ElementAddressForRegIndex(false,  // Store.
                                     IsExternal(), class_id(), index_scale(),
                                     array, index.reg())
      : __ ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());

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
        __ LoadImmediate(TMP, static_cast<int8_t>(constant.Value()));
        __ str(TMP, element_address, kUnsignedByte);
      } else {
        const Register value = locs()->in(2).reg();
        __ SmiUntag(TMP, value);
        __ str(TMP, element_address, kUnsignedByte);
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
        __ LoadImmediate(TMP, static_cast<int8_t>(value));
        __ str(TMP, element_address, kUnsignedByte);
      } else {
        const Register value = locs()->in(2).reg();
        __ CompareImmediate(value, 0x1FE);  // Smi value and smi 0xFF.
        // Clamp to 0x00 or 0xFF respectively.
        __ csetm(TMP, GT);  // TMP = value > 0x1FE ? -1 : 0.
        __ csel(TMP, value, TMP, LS);  // TMP = value in range ? value : TMP.
        __ SmiUntag(TMP);
        __ str(TMP, element_address, kUnsignedByte);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      const Register value = locs()->in(2).reg();
      __ SmiUntag(TMP, value);
      __ str(TMP, element_address, kUnsignedHalfword);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      const Register value = locs()->in(2).reg();
      __ str(value, element_address, kUnsignedWord);
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
                         Label* value_is_smi = NULL) {
  Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ tsti(value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ b(&done, EQ);
  } else {
    __ b(value_is_smi, EQ);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}


LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Zone* zone,
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

  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());

  for (intptr_t i = 0; i < num_temps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }

  return summary;
}


void GuardFieldClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt32Size);
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(deopt_id(),
          "GuardFieldClassInstr: field state changed while compiling");
    }
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
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    FieldAddress field_cid_operand(
        field_reg, Field::guarded_cid_offset(), kUnsignedWord);
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset(), kUnsignedWord);

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      Label skip_length_check;
      __ ldr(TMP, field_cid_operand, kUnsignedWord);
      __ CompareRegisters(value_cid_reg, TMP);
      __ b(&ok, EQ);
      __ ldr(TMP, field_nullability_operand, kUnsignedWord);
      __ CompareRegisters(value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ ldr(value_cid_reg, field_nullability_operand, kUnsignedWord);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      Label skip_length_check;
      __ ldr(value_cid_reg, field_cid_operand, kUnsignedWord);
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
      __ ldr(TMP, field_cid_operand, kUnsignedWord);
      __ CompareImmediate(TMP, kIllegalCid);
      __ b(fail, NE);

      if (value_cid == kDynamicCid) {
        __ str(value_cid_reg, field_cid_operand, kUnsignedWord);
        __ str(value_cid_reg, field_nullability_operand, kUnsignedWord);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ str(TMP, field_cid_operand, kUnsignedWord);
        __ str(TMP, field_nullability_operand, kUnsignedWord);
      }

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ b(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ LoadFieldFromOffset(
          TMP, field_reg, Field::guarded_cid_offset(), kUnsignedWord);
      __ CompareImmediate(TMP, kDynamicCid);
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
      // Value's class id is not known.
      __ tsti(value_reg, Immediate(kSmiTagMask));

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
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    // We need temporaries for field object, length offset and expected length.
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, Location::RequiresRegister());
    return summary;
  } else {
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, 0, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
}


void GuardFieldLengthInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (field().guarded_list_length() == Field::kNoFixedLength) {
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(deopt_id(),
          "GuardFieldLengthInstr: field state changed while compiling");
    }
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

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    __ ldr(offset_reg,
           FieldAddress(field_reg,
                        Field::guarded_list_length_in_object_offset_offset()),
           kByte);
    __ ldr(length_reg, FieldAddress(field_reg,
        Field::guarded_list_length_offset()));

    __ tst(offset_reg, Operand(offset_reg));
    __ b(&ok, MI);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ ldr(TMP, Address(value_reg, offset_reg));
    __ CompareRegisters(length_reg, TMP);

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

    __ ldr(TMP, FieldAddress(value_reg,
                            field().guarded_list_length_in_object_offset()));
    __ CompareImmediate(TMP, Smi::RawValue(field().guarded_list_length()));
    __ b(deopt, NE);
  }
}


class BoxAllocationSlowPath : public SlowPathCode {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : instruction_(instruction),
        cls_(cls),
        result_(result) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s",
                 instruction_->DebugName(),
                 String::Handle(cls_.ScrubbedName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub = Code::ZoneHandle(compiler->zone(),
        StubCode::GetAllocationStubForClass(cls_));
    const StubEntry stub_entry(stub);

    LocationSummary* locs = instruction_->locs();

    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(TokenPosition::kNoSource,  // No token position.
                           stub_entry,
                           RawPcDescriptors::kOther,
                           locs);
    compiler->AddStubCallTarget(stub);
    __ mov(result_, R0);
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


static void EnsureMutableBox(FlowGraphCompiler* compiler,
                             StoreInstanceFieldInstr* instruction,
                             Register box_reg,
                             const Class& cls,
                             Register instance_reg,
                             intptr_t offset,
                             Register temp) {
  Label done;
  __ LoadFieldFromOffset(box_reg, instance_reg, offset);
  __ CompareObject(box_reg, Object::null_object());
  __ b(&done, NE);
  BoxAllocationSlowPath::Allocate(
      compiler, instruction, cls, box_reg, temp);
  __ mov(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp);
  __ Bind(&done);
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (IsUnboxedStore() && opt) ? 2 :
          ((IsPotentialUnboxedStore()) ? 2 : 0);
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
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
      summary->set_in(1, ShouldEmitStoreBarrier()
          ? Location::WritableRegister()
          :  Location::RequiresRegister());
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_temp(1, Location::RequiresRegister());
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                       ? Location::WritableRegister()
                       : Location::RegisterOrConstant(value()));
  }
  return summary;
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt32Size);
  Label skip_store;

  const Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    const VRegister value = locs()->in(1).fpu_reg();
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
      __ mov(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
    } else {
      __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes_);
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

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));

    __ LoadFieldFromOffset(temp2, temp, Field::is_nullable_offset(),
                           kUnsignedWord);
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ LoadFromOffset(
        temp2, temp, Field::kind_bits_offset() - kHeapObjectTag,
        kUnsignedByte);
    __ tsti(temp2, Immediate(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           kUnsignedWord);
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           kUnsignedWord);
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

    __ LoadFieldFromOffset(temp2, temp, Field::guarded_cid_offset(),
                           kUnsignedWord);
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
      EnsureMutableBox(compiler,
                       this,
                       temp,
                       compiler->double_class(),
                       instance_reg,
                       offset_in_bytes_,
                       temp2);
      __ LoadDFieldFromOffset(VTMP, value_reg, Double::value_offset());
      __ StoreDFieldToOffset(VTMP, temp, Double::value_offset());
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler,
                       this,
                       temp,
                       compiler->float32x4_class(),
                       instance_reg,
                       offset_in_bytes_,
                       temp2);
      __ LoadQFieldFromOffset(VTMP, value_reg, Float32x4::value_offset());
      __ StoreQFieldToOffset(VTMP, temp, Float32x4::value_offset());
      __ b(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler,
                       this,
                       temp,
                       compiler->float64x2_class(),
                       instance_reg,
                       offset_in_bytes_,
                       temp2);
      __ LoadQFieldFromOffset(VTMP, value_reg, Float64x2::value_offset());
      __ StoreQFieldToOffset(VTMP, temp, Float64x2::value_offset());
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    const Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(
        instance_reg, offset_in_bytes_, value_reg, CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectOffsetNoBarrier(
          instance_reg, offset_in_bytes_, locs()->in(1).constant());
    } else {
      const Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectOffsetNoBarrier(
          instance_reg, offset_in_bytes_, value_reg);
    }
  }
  __ Bind(&skip_store);
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  __ LoadFieldFromOffset(result, field, Field::static_value_offset());
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  LocationSummary* locs = new(zone) LocationSummary(
      zone, 1, 1, LocationSummary::kNoCall);
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
    __ StoreIntoObjectOffset(
        temp, Field::static_value_offset(), value, CanValueBeSmi());
  } else {
    __ StoreIntoObjectOffsetNoBarrier(temp,
                                      Field::static_value_offset(),
                                      value);
  }
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_in(1, Location::RegisterLocation(R1));
  summary->set_out(0, Location::RegisterLocation(R0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == R0);  // Value.
  ASSERT(locs()->in(1).reg() == R1);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out(0).reg() == R0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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
                      R6,
                      R8);
  // R0: new object start as a tagged pointer.
  // R3: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(R0,
                              FieldAddress(R0, Array::type_arguments_offset()),
                              kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(R0,
                              FieldAddress(R0, Array::length_offset()),
                              kLengthReg);

  // TODO(zra): Use stp once added.
  // Initialize all array elements to raw_null.
  // R0: new object start as a tagged pointer.
  // R3: new object end address.
  // R8: iterator which initially points to the start of the variable
  // data area to be initialized.
  // R6: null
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(RawArray);
    __ LoadObject(R6, Object::null_object());
    __ AddImmediate(R8, R0, sizeof(RawArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ str(R6, Address(R8, current_offset));
        current_offset += kWordSize;
      }
    } else {
      Label end_loop, init_loop;
      __ Bind(&init_loop);
      __ CompareRegisters(R8, R3);
      __ b(&end_loop, CS);
      __ str(R6, Address(R8));
      __ AddImmediate(R8, R8, kWordSize);
      __ b(&init_loop);
      __ Bind(&end_loop);
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

  if (compiler->is_optimizing() &&
      !FLAG_precompiled_mode &&
      num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object());  // Make room for the result.
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
  const Code& stub = Code::ZoneHandle(compiler->zone(),
                                      StubCode::AllocateArray_entry()->code());
  compiler->AddStubCallTarget(stub);
  compiler->GenerateCall(token_pos(),
                         *StubCode::AllocateArray_entry(),
                         RawPcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out(0).reg() == kResultReg);
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 :
          ((IsPotentialUnboxedLoad()) ? 1 : 0);
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      (opt && !IsPotentialUnboxedLoad())
          ? LocationSummary::kNoCall
          : LocationSummary::kCallOnSlowPath);

  locs->set_in(0, Location::RequiresRegister());

  if (IsUnboxedLoad() && opt) {
    locs->set_temp(0, Location::RequiresRegister());
  } else if (IsPotentialUnboxedLoad()) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt32Size);
  const Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    const VRegister result = locs()->out(0).fpu_reg();
    const Register temp = locs()->temp(0).reg();
    __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes());
    const intptr_t cid = field()->UnboxedFieldCid();
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

  Label done;
  const Register result_reg = locs()->out(0).reg();
  if (IsPotentialUnboxedLoad()) {
    const Register temp = locs()->temp(0).reg();

    Label load_pointer;
    Label load_double;
    Label load_float32x4;
    Label load_float64x2;

    __ LoadObject(result_reg, Field::ZoneHandle(field()->Original()));

    FieldAddress field_cid_operand(
        result_reg, Field::guarded_cid_offset(), kUnsignedWord);
    FieldAddress field_nullability_operand(
        result_reg, Field::is_nullable_offset(), kUnsignedWord);

    __ ldr(temp, field_nullability_operand, kUnsignedWord);
    __ CompareImmediate(temp, kNullCid);
    __ b(&load_pointer, EQ);

    __ ldr(temp, field_cid_operand, kUnsignedWord);
    __ CompareImmediate(temp, kDoubleCid);
    __ b(&load_double, EQ);

    __ ldr(temp, field_cid_operand, kUnsignedWord);
    __ CompareImmediate(temp, kFloat32x4Cid);
    __ b(&load_float32x4, EQ);

    __ ldr(temp, field_cid_operand, kUnsignedWord);
    __ CompareImmediate(temp, kFloat64x2Cid);
    __ b(&load_float64x2, EQ);

    // Fall through.
    __ b(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(compiler,
                                      this,
                                      compiler->double_class(),
                                      result_reg,
                                      temp);
      __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes());
      __ LoadDFieldFromOffset(VTMP, temp, Double::value_offset());
      __ StoreDFieldToOffset(VTMP, result_reg, Double::value_offset());
      __ b(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(compiler,
                                      this,
                                      compiler->float32x4_class(),
                                      result_reg,
                                      temp);
      __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes());
      __ LoadQFieldFromOffset(VTMP, temp, Float32x4::value_offset());
      __ StoreQFieldToOffset(VTMP, result_reg, Float32x4::value_offset());
      __ b(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(compiler,
                                      this,
                                      compiler->float64x2_class(),
                                      result_reg,
                                      temp);
      __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes());
      __ LoadQFieldFromOffset(VTMP, temp, Float64x2::value_offset());
      __ StoreQFieldToOffset(VTMP, result_reg, Float64x2::value_offset());
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFieldFromOffset(result_reg, instance_reg, offset_in_bytes());
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register instantiator_reg = locs()->in(0).reg();
  const Register result_reg = locs()->out(0).reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::null_object());  // Make room for the result.
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
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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
    __ CompareObject(instantiator_reg, Object::null_object());
    __ b(&type_arguments_instantiated, EQ);
  }

  __ LoadObject(R2, type_arguments());
  __ LoadFieldFromOffset(R2, R2, TypeArguments::instantiations_offset());
  __ AddImmediate(R2, R2, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, found, slow_case;
  __ Bind(&loop);
  __ LoadFromOffset(R1, R2, 0 * kWordSize);  // Cached instantiator.
  __ CompareRegisters(R1, R0);
  __ b(&found, EQ);
  __ AddImmediate(R2, R2, 2 * kWordSize);
  __ CompareImmediate(R1, Smi::RawValue(StubCode::kNoInstantiator));
  __ b(&loop, NE);
  __ b(&slow_case);
  __ Bind(&found);
  __ LoadFromOffset(R0, R2, 1 * kWordSize);  // Cached instantiated args.
  __ b(&type_arguments_instantiated);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::null_object());  // Make room for the result.
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


LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new(zone) LocationSummary(
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
      : instruction_(instruction) { }

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
                           RawPcDescriptors::kOther,
                           locs);
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
                      temp0,
                      temp1,
                      temp2);

  // Setup up number of context variables field.
  __ LoadImmediate(temp0, num_context_variables());
  __ str(temp0, FieldAddress(result, Context::num_variables_offset()));

  __ Bind(slow_path->exit_label());
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->out(0).reg() == R0);

  __ LoadImmediate(R1, num_context_variables());
  compiler->GenerateCall(token_pos(),
                         *StubCode::AllocateContext_entry(),
                         RawPcDescriptors::kOther,
                         locs());
}

LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInitStaticFieldRuntimeEntry,
                                1,
                                locs());
  __ Drop(2);  // Remove argument and result placeholder.
  __ Bind(&no_call);
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register context_value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ PushObject(Object::null_object());  // Make room for the result.
  __ Push(context_value);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ Drop(1);  // Remove argument.
  __ Pop(result);  // Get result (cloned context).
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
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
  __ RestoreCodePointer();
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
  __ StoreToOffset(kExceptionObjectReg,
                   FP, exception_var().index() * kWordSize);
  __ StoreToOffset(kStackTraceObjectReg,
                   FP, stacktrace_var().index() * kWordSize);
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (FLAG_use_osr && osr_entry_label()->IsLinked()) {
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
    compiler->GenerateRuntimeCall(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  0,
                                  instruction_->locs());

    if (FLAG_use_osr && !compiler->is_optimizing() && instruction_->in_loop()) {
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

  __ ldr(TMP, Address(THR, Thread::stack_limit_offset()));
  // Compare to CSP not SP because CSP is closer to the stack limit. See
  // Assembler::EnterFrame.
  __ CompareRegisters(CSP, TMP);
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    const Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ LoadFieldFromOffset(
        temp, temp, Function::usage_counter_offset(), kWord);
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
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), ICData::kDeoptBinarySmiOp)
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
      __ cmp(left, Operand(TMP, ASR, value));
      __ b(deopt, NE);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ LslImmediate(result, left, value);
    return;
  }

  // Right (locs.in(1)) is not constant.
  const Register right = locs.in(1).reg();
  Range* right_range = shift_left->right()->definition()->range();
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
        __ CompareImmediate(right,
            reinterpret_cast<int64_t>(Smi::New(max_right)));
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
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareRegisters(right, ZR);
        __ b(deopt, MI);
      }

      __ CompareImmediate(
          right, reinterpret_cast<int64_t>(Smi::New(Smi::kBits)));
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
      __ CompareImmediate(
          right, reinterpret_cast<int64_t>(Smi::New(Smi::kBits)));
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


class CheckedSmiSlowPath : public SlowPathCode {
 public:
  CheckedSmiSlowPath(CheckedSmiOpInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    Register result = locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    compiler->EmitMegamorphicInstanceCall(
        *instruction_->call()->ic_data(),
        instruction_->call()->ArgumentCount(),
        instruction_->call()->deopt_id(),
        instruction_->call()->token_pos(),
        locs,
        try_index_,
        /* slow_path_argument_count = */ 2);
    __ mov(result, R0);
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
  }

 private:
  CheckedSmiOpInstr* instruction_;
  intptr_t try_index_;
};


LocationSummary* CheckedSmiOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
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
    __ tsti(left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tsti(right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tsti(left, Immediate(kSmiTagMask));
  } else {
    combined_smi_check = true;
    __ orr(result, left, Operand(right));
    __ tsti(result, Immediate(kSmiTagMask));
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
      __ SmiUntag(TMP, left);
      __ mul(result, TMP, right);
      __ smulh(TMP, TMP, right);
      // TMP: result bits 64..127.
      __ cmp(TMP, Operand(result, ASR, 63));
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
    case Token::kEQ:
    case Token::kLT:
    case Token::kLTE:
    case Token::kGT:
    case Token::kGTE: {
      Label true_label, false_label, done;
      BranchLabels labels = { &true_label, &false_label, &false_label };
      Condition true_condition =
          EmitSmiComparisonOp(compiler, locs(), op_kind());
      EmitBranchOnCondition(compiler, true_condition, labels);
      __ Bind(&false_label);
      __ LoadObject(result, Bool::False());
      __ b(&done);
      __ Bind(&true_label);
      __ LoadObject(result, Bool::True());
      __ Bind(&done);
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (((op_kind() == Token::kSHL) && can_overflow()) ||
       (op_kind() == Token::kSHR)) ? 1 : 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    const int64_t imm = reinterpret_cast<int64_t>(constant.raw());
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
          __ cmp(TMP, Operand(result, ASR, 63));
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
        __ AsrImmediate(TMP, left, 63);
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        const Register temp = TMP2;
        __ add(temp, left, Operand(TMP, LSR, 64 - shift_count));
        ASSERT(shift_count > 0);
        __ AsrImmediate(result, temp, shift_count);
        if (value < 0) {
          __ sub(result, ZR, Operand(result));
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
        __ AsrImmediate(
            result, left, Utils::Minimum(value + kSmiTagSize, kCountLimit));
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
      __ SmiUntag(TMP, left);
      if (deopt == NULL) {
        __ mul(result, TMP, right);
      } else {
          __ mul(result, TMP, right);
          __ smulh(TMP, TMP, right);
          // TMP: result bits 64..127.
          __ cmp(TMP, Operand(result, ASR, 63));
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
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
        // Handle divide by zero in runtime.
        __ CompareRegisters(right, ZR);
        __ b(deopt, EQ);
      }
      const Register temp = TMP2;
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);

      __ sdiv(result, temp, TMP);

      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ CompareImmediate(result, 0x4000000000000000LL);
      __ b(deopt, EQ);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      Label done;
      __ CompareRegisters(result, ZR);
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ CompareRegisters(right, ZR);
      __ sub(TMP, result, Operand(right));
      __ add(result, result, Operand(right));
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
      if ((right_range == NULL) ||
          !right_range->OnlyLessThanOrEqualTo(kCountLimit)) {
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
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptBinaryDoubleOp,
                                        licm_hoisted_ ? ICData::kHoisted : 0);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ tsti(left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ tsti(right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tsti(left, Immediate(kSmiTagMask));
  } else {
    __ orr(TMP, left, Operand(right));
    __ tsti(TMP, Immediate(kSmiTagMask));
  }
  __ b(deopt, EQ);
}


LocationSummary* BoxInstr::MakeLocationSummary(Zone* zone,
                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(zone) LocationSummary(
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

  BoxAllocationSlowPath::Allocate(
      compiler,
      this,
      compiler->BoxClassFor(from_representation()),
      out_reg,
      temp_reg);

  switch (from_representation()) {
    case kUnboxedDouble:
      __ StoreDFieldToOffset(value, out_reg, ValueOffset());
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


LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone,
                                                 bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedMint: {
      UNIMPLEMENTED();
      break;
    }

    case kUnboxedDouble: {
      const VRegister result = locs()->out(0).fpu_reg();
      __ LoadDFieldFromOffset(result, box, ValueOffset());
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
    case kUnboxedMint: {
      UNIMPLEMENTED();
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


void UnboxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t box_cid = BoxCid();

  if (value_cid == box_cid) {
    EmitLoadFromBox(compiler);
  } else if (CanConvertSmi() && (value_cid == kSmiCid)) {
    EmitSmiConversion(compiler);
  } else {
    const Register box = locs()->in(0).reg();
    Label* deopt = compiler->AddDeoptStub(GetDeoptId(),
                                          ICData::kDeoptCheckClass);
    Label is_smi;

    if ((value()->Type()->ToNullableCid() == box_cid) &&
        value()->Type()->is_nullable()) {
      __ CompareObject(box, Object::null_object());
      __ b(deopt, EQ);
    } else {
      __ tsti(box, Immediate(kSmiTagMask));
      __ b(CanConvertSmi() ? &is_smi : deopt, EQ);
      __ CompareClassId(box, box_cid);
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
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone,
      kNumInputs,
      kNumTemps,
      LocationSummary::kNoCall);
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


DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxInt64Instr)


LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  Label* deopt = CanDeoptimize() ?
      compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger) : NULL;

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
  } else if (!CanDeoptimize()) {
    // Type information is not conclusive, but range analysis found
    // the value to be in int64 range. Therefore it must be a smi
    // or mint value.
    ASSERT(is_truncating());
    Label done;
    __ SmiUntag(out, value);
    __ TestImmediate(value, kSmiTagMask);
    __ b(&done, EQ);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  } else {
    Label done;
    __ SmiUntag(out, value);
    __ TestImmediate(value, kSmiTagMask);
    __ b(&done, EQ);
    __ CompareClassId(value, kMintCid);
    __ b(deopt, NE);
    __ LoadFieldFromOffset(out, value, Mint::value_offset());
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != NULL)) {
    ASSERT(representation() == kUnboxedInt32);
    __ cmp(out, Operand(out, SXTW, 0));
    __ b(deopt, NE);
  }
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case Token::kADD: __ faddd(result, left, right); break;
    case Token::kSUB: __ fsubd(result, left, right); break;
    case Token::kMUL: __ fmuld(result, left, right); break;
    case Token::kDIV: __ fdivd(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case Token::kADD: __ vadds(result, left, right); break;
    case Token::kSUB: __ vsubs(result, left, right); break;
    case Token::kMUL: __ vmuls(result, left, right); break;
    case Token::kDIV: __ vdivs(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case Token::kADD: __ vaddd(result, left, right); break;
    case Token::kSUB: __ vsubd(result, left, right); break;
    case Token::kMUL: __ vmuld(result, left, right); break;
    case Token::kDIV: __ vdivd(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleX:
      __ vinss(result, 0, value, 0);
      __ fcvtds(result, result);
      break;
    case MethodRecognizer::kFloat32x4ShuffleY:
      __ vinss(result, 0, value, 1);
      __ fcvtds(result, result);
      break;
    case MethodRecognizer::kFloat32x4ShuffleZ:
      __ vinss(result, 0, value, 2);
      __ fcvtds(result, result);
      break;
    case MethodRecognizer::kFloat32x4ShuffleW:
      __ vinss(result, 0, value, 3);
      __ fcvtds(result, result);
      break;
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kFloat32x4Shuffle:
      if (mask_ == 0x00) {
        __ vdups(result, value, 0);
      } else if (mask_ == 0x55) {
        __ vdups(result, value, 1);
      } else if (mask_ == 0xAA) {
        __ vdups(result, value, 2);
      } else  if (mask_ == 0xFF) {
        __ vdups(result, value, 3);
      } else {
        __ vinss(result, 0, value, mask_ & 0x3);
        __ vinss(result, 1, value, (mask_ >> 2) & 0x3);
        __ vinss(result, 2, value, (mask_ >> 4) & 0x3);
        __ vinss(result, 3, value, (mask_ >> 6) & 0x3);
      }
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
      __ vinss(result, 0, left, mask_ & 0x3);
      __ vinss(result, 1, left, (mask_ >> 2) & 0x3);
      __ vinss(result, 2, right, (mask_ >> 4) & 0x3);
      __ vinss(result, 3, right, (mask_ >> 6) & 0x3);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =  new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const Register out = locs()->out(0).reg();
  const Register temp = locs()->temp(0).reg();

  // X lane.
  __ vmovrs(out, value, 0);
  __ LsrImmediate(out, out, 31);
  // Y lane.
  __ vmovrs(temp, value, 1);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, value, 2);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, value, 3);
  __ LsrImmediate(temp, temp, 31);
  __ orr(out, out, Operand(temp, LSL, 3));
  // Tag.
  __ SmiTag(out);
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_in(3, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister v0 = locs()->in(0).fpu_reg();
  const VRegister v1 = locs()->in(1).fpu_reg();
  const VRegister v2 = locs()->in(2).fpu_reg();
  const VRegister v3 = locs()->in(3).fpu_reg();
  const VRegister r = locs()->out(0).fpu_reg();

  __ fcvtsd(VTMP, v0);
  __ vinss(r, 0, VTMP, 0);
  __ fcvtsd(VTMP, v1);
  __ vinss(r, 1, VTMP, 0);
  __ fcvtsd(VTMP, v2);
  __ vinss(r, 2, VTMP, 0);
  __ fcvtsd(VTMP, v3);
  __ vinss(r, 3, VTMP, 0);
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister v = locs()->out(0).fpu_reg();
  __ veor(v, v, v);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  // Convert to Float32.
  __ fcvtsd(VTMP, value);

  // Splat across all lanes.
  __ vdups(result, VTMP, 0);
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Equal:
      __ vceqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4NotEqual:
      __ vceqs(result, left, right);
      // Invert the result.
      __ vnot(result, result);
      break;
    case MethodRecognizer::kFloat32x4GreaterThan:
      __ vcgts(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
      __ vcges(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4LessThan:
      __ vcgts(result, right, left);
      break;
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
      __ vcges(result, right, left);
      break;

    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Min:
      __ vmins(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4Max:
      __ vmaxs(result, left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Sqrt:
      __ vsqrts(result, left);
      break;
    case MethodRecognizer::kFloat32x4Reciprocal:
      __ VRecps(result, left);
      break;
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
      __ VRSqrts(result, left);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Scale:
      __ fcvtsd(VTMP, left);
      __ vdups(result, VTMP, 0);
      __ vmuls(result, result, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Negate:
      __ vnegs(result, left);
      break;
    case MethodRecognizer::kFloat32x4Absolute:
      __ vabss(result, left);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister lower = locs()->in(1).fpu_reg();
  const VRegister upper = locs()->in(2).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  __ vmins(result, left, upper);
  __ vmaxs(result, result, lower);
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister replacement = locs()->in(0).fpu_reg();
  const VRegister value = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  __ fcvtsd(VTMP, replacement);
  if (result != value) {
    __ vmov(result, value);
  }

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4WithX:
      __ vinss(result, 0, VTMP, 0);
      break;
    case MethodRecognizer::kFloat32x4WithY:
      __ vinss(result, 1, VTMP, 0);
      break;
    case MethodRecognizer::kFloat32x4WithZ:
      __ vinss(result, 2, VTMP, 0);
      break;
    case MethodRecognizer::kFloat32x4WithW:
      __ vinss(result, 3, VTMP, 0);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  if (value != result) {
    __ vmov(result, value);
  }
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2GetX:
      __ vinsd(result, 0, value, 0);
      break;
    case MethodRecognizer::kFloat64x2GetY:
      __ vinsd(result, 0, value, 1);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister v = locs()->out(0).fpu_reg();
  __ veor(v, v, v);
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  __ vdupd(result, value, 0);
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister v0 = locs()->in(0).fpu_reg();
  const VRegister v1 = locs()->in(1).fpu_reg();
  const VRegister r = locs()->out(0).fpu_reg();
  __ vinsd(r, 0, v0, 0);
  __ vinsd(r, 1, v1, 0);
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister q = locs()->in(0).fpu_reg();
  const VRegister r = locs()->out(0).fpu_reg();

  // Zero register.
  __ veor(r, r, r);
  // Set X lane.
  __ vinsd(VTMP, 0, q, 0);
  __ fcvtsd(VTMP, VTMP);
  __ vinss(r, 0, VTMP, 0);
  // Set Y lane.
  __ vinsd(VTMP, 0, q, 1);
  __ fcvtsd(VTMP, VTMP);
  __ vinss(r, 1, VTMP, 0);
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister q = locs()->in(0).fpu_reg();
  const VRegister r = locs()->out(0).fpu_reg();

  // Set X.
  __ vinss(VTMP, 0, q, 0);
  __ fcvtds(VTMP, VTMP);
  __ vinsd(r, 0, VTMP, 0);
  // Set Y.
  __ vinss(VTMP, 0, q, 1);
  __ fcvtds(VTMP, VTMP);
  __ vinsd(r, 1, VTMP, 0);
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  if (representation() == kTagged) {
    ASSERT(op_kind() == MethodRecognizer::kFloat64x2GetSignMask);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
  } else {
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();

  if ((op_kind() == MethodRecognizer::kFloat64x2GetSignMask)) {
    const Register out = locs()->out(0).reg();

    // Bits of X lane.
    __ vmovrd(out, value, 0);
    __ LsrImmediate(out, out, 63);
    // Bits of Y lane.
    __ vmovrd(TMP, value, 1);
    __ LsrImmediate(TMP, TMP, 63);
    __ orr(out, out, Operand(TMP, LSL, 1));
    // Tag.
    __ SmiTag(out);
    return;
  }
  ASSERT(representation() == kUnboxedFloat64x2);
  const VRegister result = locs()->out(0).fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Negate:
      __ vnegd(result, value);
      break;
    case MethodRecognizer::kFloat64x2Abs:
      __ vabsd(result, value);
      break;
    case MethodRecognizer::kFloat64x2Sqrt:
      __ vsqrtd(result, value);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float64x2OneArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister out = locs()->out(0).fpu_reg();
  ASSERT(left == out);

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Scale:
      __ vdupd(VTMP, right, 0);
      __ vmuld(out, left, VTMP);
      break;
    case MethodRecognizer::kFloat64x2WithX:
      __ vinsd(out, 0, right, 0);
      break;
    case MethodRecognizer::kFloat64x2WithY:
      __ vinsd(out, 1, right, 0);
      break;
    case MethodRecognizer::kFloat64x2Min:
      __ vmind(out, left, right);
      break;
    case MethodRecognizer::kFloat64x2Max:
      __ vmaxd(out, left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Int32x4ConstructorInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register v0 = locs()->in(0).reg();
  const Register v1 = locs()->in(1).reg();
  const Register v2 = locs()->in(2).reg();
  const Register v3 = locs()->in(3).reg();
  const VRegister result = locs()->out(0).fpu_reg();
  __ veor(result, result, result);
  __ vinsw(result, 0, v0);
  __ vinsw(result, 1, v1);
  __ vinsw(result, 2, v2);
  __ vinsw(result, 3, v3);
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register v0 = locs()->in(0).reg();
  const Register v1 = locs()->in(1).reg();
  const Register v2 = locs()->in(2).reg();
  const Register v3 = locs()->in(3).reg();
  const Register temp = locs()->temp(0).reg();
  const VRegister result = locs()->out(0).fpu_reg();

  __ veor(result, result, result);
  __ LoadImmediate(temp, 0xffffffff);
  __ LoadObject(TMP2, Bool::True());

  // __ CompareObject(v0, Bool::True());
  __ CompareRegisters(v0, TMP2);
  __ csel(TMP, temp, ZR, EQ);
  __ vinsw(result, 0, TMP);

  // __ CompareObject(v1, Bool::True());
  __ CompareRegisters(v1, TMP2);
  __ csel(TMP, temp, ZR, EQ);
  __ vinsw(result, 1, TMP);

  // __ CompareObject(v2, Bool::True());
  __ CompareRegisters(v2, TMP2);
  __ csel(TMP, temp, ZR, EQ);
  __ vinsw(result, 2, TMP);

  // __ CompareObject(v3, Bool::True());
  __ CompareRegisters(v3, TMP2);
  __ csel(TMP, temp, ZR, EQ);
  __ vinsw(result, 3, TMP);
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const Register result = locs()->out(0).reg();

  switch (op_kind()) {
    case MethodRecognizer::kInt32x4GetFlagX:
      __ vmovrs(result, value, 0);
      break;
    case MethodRecognizer::kInt32x4GetFlagY:
      __ vmovrs(result, value, 1);
      break;
    case MethodRecognizer::kInt32x4GetFlagZ:
      __ vmovrs(result, value, 2);
      break;
    case MethodRecognizer::kInt32x4GetFlagW:
      __ vmovrs(result, value, 3);
      break;
    default: UNREACHABLE();
  }

  __ tst(result, Operand(result));
  __ LoadObject(result, Bool::True());
  __ LoadObject(TMP, Bool::False());
  __ csel(result, TMP, result, EQ);
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister mask = locs()->in(0).fpu_reg();
  const VRegister trueValue = locs()->in(1).fpu_reg();
  const VRegister falseValue = locs()->in(2).fpu_reg();
  const VRegister out = locs()->out(0).fpu_reg();
  const VRegister temp = locs()->temp(0).fpu_reg();

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


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister mask = locs()->in(0).fpu_reg();
  const Register flag = locs()->in(1).reg();
  const VRegister result = locs()->out(0).fpu_reg();

  if (result != mask) {
    __ vmov(result, mask);
  }

  __ CompareObject(flag, Bool::True());
  __ LoadImmediate(TMP, 0xffffffff);
  __ csel(TMP, TMP, ZR, EQ);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4WithFlagX:
      __ vinsw(result, 0, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagY:
      __ vinsw(result, 1, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagZ:
      __ vinsw(result, 2, TMP);
      break;
    case MethodRecognizer::kInt32x4WithFlagW:
      __ vinsw(result, 3, TMP);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister value = locs()->in(0).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();

  if (value != result) {
    __ vmov(result, value);
  }
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const VRegister left = locs()->in(0).fpu_reg();
  const VRegister right = locs()->in(1).fpu_reg();
  const VRegister result = locs()->out(0).fpu_reg();
  switch (op_kind()) {
    case Token::kBIT_AND: __ vand(result, left, right); break;
    case Token::kBIT_OR: __ vorr(result, left, right); break;
    case Token::kBIT_XOR: __ veor(result, left, right); break;
    case Token::kADD: __ vaddw(result, left, right); break;
    case Token::kSUB: __ vsubw(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  if ((kind() == MathUnaryInstr::kSin) || (kind() == MathUnaryInstr::kCos)) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(V0));
    summary->set_out(0, Location::FpuRegisterLocation(V0));
    return summary;
  }
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    ASSERT((kind() == MathUnaryInstr::kSin) ||
           (kind() == MathUnaryInstr::kCos));
    __ CallRuntime(TargetFunction(), InputCount());
  }
}


LocationSummary* CaseInsensitiveCompareUC16Instr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, InputCount(), kNumTemps, LocationSummary::kCall);
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
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    // Reuse the left register so that code can be made shorter.
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }
  ASSERT(result_cid() == kSmiCid);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      __ subs(result, ZR, Operand(value));
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn(result, value);
      // Remove inverted smi-tag.
      __ andi(result, result, Immediate(~kSmiTagMask));
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
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

  Label do_call, done;
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


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* result = new(zone) LocationSummary(
      zone, InputCount(), kNumTemps, LocationSummary::kCall);
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

  Label skip_call, try_sqrt, check_base, return_nan, do_pow;
  __ fmovdd(saved_base, base);
  __ LoadDImmediate(result, 1.0);
  // exponent == 0.0 -> return 1.0;
  __ fcmpdz(exp);
  __ b(&check_base, VS);  // NaN -> check base.
  __ b(&skip_call, EQ);  // exp is 0.0, result is 1.0.

  // exponent == 1.0 ?
  __ fcmpd(exp, result);
  Label return_base;
  __ b(&return_base, EQ);

  // exponent == 2.0 ?
  __ LoadDImmediate(VTMP, 2.0);
  __ fcmpd(exp, VTMP);
  Label return_base_times_2;
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

  Label return_zero;
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
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, 0, LocationSummary::kNoCall);
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


LocationSummary* MergedMathInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
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
    const PairLocation* pair = locs()->out(0).AsPairLocation();
    const Register result_div = pair->At(0).reg();
    const Register result_mod = pair->At(1).reg();
    const Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
    Label done;
    __ CompareRegisters(result_mod, ZR);;
    __ b(&done, GE);
    // Result is negative, adjust it.
    __ CompareRegisters(right, ZR);
    __ sub(TMP2, result_mod, Operand(right));
    __ add(TMP, result_mod, Operand(right));
    __ csel(result_mod, TMP, TMP2, GE);
    __ Bind(&done);
    return;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    UNIMPLEMENTED();
  }
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  return MakeCallSummary(zone);
}


LocationSummary* BranchInstr::MakeLocationSummary(Zone* zone,
                                                  bool opt) const {
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
  const bool need_mask_temp = IsDenseSwitch() && !IsDenseMask(ComputeCidMask());
  const intptr_t kNumTemps = !IsNullCheck() ? (need_mask_temp ? 2 : 1) : 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->set_temp(0, Location::RequiresRegister());
    if (need_mask_temp) {
      summary->set_temp(1, Location::RequiresRegister());
    }
  }
  return summary;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptCheckClass,
                                        licm_hoisted_ ? ICData::kHoisted : 0);
  if (IsNullCheck()) {
    __ CompareObject(locs()->in(0).reg(), Object::null_object());
    ASSERT(DeoptIfNull() || DeoptIfNotNull());
    Condition cond = DeoptIfNull() ? EQ : NE;
    __ b(deopt, cond);
    return;
  }

  ASSERT((unary_checks().GetReceiverClassIdAt(0) != kSmiCid) ||
         (unary_checks().NumberOfChecks() > 1));
  const Register value = locs()->in(0).reg();
  const Register temp = locs()->temp(0).reg();
  Label is_ok;
  if (unary_checks().GetReceiverClassIdAt(0) == kSmiCid) {
    __ tsti(value, Immediate(kSmiTagMask));
    __ b(&is_ok, EQ);
  } else {
    __ tsti(value, Immediate(kSmiTagMask));
    __ b(deopt, EQ);
  }
  __ LoadClassId(temp, value);

  if (IsDenseSwitch()) {
    ASSERT(cids_[0] < cids_[cids_.length() - 1]);
    __ AddImmediate(temp, temp, -cids_[0]);
    __ CompareImmediate(temp, cids_[cids_.length() - 1] - cids_[0]);
    __ b(deopt, HI);

    intptr_t mask = ComputeCidMask();
    if (!IsDenseMask(mask)) {
      // Only need mask if there are missing numbers in the range.
      ASSERT(cids_.length() > 2);
      Register mask_reg = locs()->temp(1).reg();
      __ LoadImmediate(mask_reg, 1);
      __ lslv(mask_reg, mask_reg, temp);
      __ TestImmediate(mask_reg, mask);
      __ b(deopt, EQ);
    }

  } else {
    GrowableArray<CidTarget> sorted_ic_data;
    FlowGraphCompiler::SortICDataByCount(unary_checks(),
                                         &sorted_ic_data,
                                         /* drop_smi = */ true);
    const intptr_t num_checks = sorted_ic_data.length();
    for (intptr_t i = 0; i < num_checks; i++) {
      const intptr_t cid = sorted_ic_data[i].cid;
      ASSERT(cid != kSmiCid);
      __ CompareImmediate(temp, cid);
      if (i == (num_checks - 1)) {
        __ b(deopt, NE);
      } else {
        __ b(&is_ok, EQ);
      }
    }
  }
  __ Bind(&is_ok);
}


LocationSummary* CheckClassIdInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  __ CompareImmediate(value, Smi::RawValue(cid_));
  __ b(deopt, NE);
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptCheckSmi,
                                        licm_hoisted_ ? ICData::kHoisted : 0);
  __ BranchIfNotSmi(value, deopt);
}



LocationSummary* GenericCheckBoundInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_in(kLengthPos, Location::RequiresRegister());
  locs->set_in(kIndexPos, Location::RequiresRegister());
  return locs;
}


class RangeErrorSlowPath : public SlowPathCode {
 public:
  RangeErrorSlowPath(GenericCheckBoundInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path check bound operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    __ CallRuntime(kRangeErrorRuntimeEntry, 2);
    compiler->pc_descriptors_list()->AddDescriptor(
        RawPcDescriptors::kOther,
        compiler->assembler()->CodeSize(),
        instruction_->deopt_id(),
        instruction_->token_pos(),
        try_index_);
    compiler->RecordSafepoint(locs, 2);
    __ brk(0);
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
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  uint32_t flags = generalized_ ? ICData::kGeneralized : 0;
  flags |= licm_hoisted_ ? ICData::kHoisted : 0;
  Label* deopt = compiler->AddDeoptStub(
      deopt_id(),
      ICData::kDeoptCheckArrayBound,
      flags);

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
    __ CompareImmediate(length, reinterpret_cast<int64_t>(index.raw()));
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
      __ CompareImmediate(index, reinterpret_cast<int64_t>(length.raw()));
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


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


bool ShiftMintOpInstr::has_shift_count_check() const {
  UNREACHABLE();
  return false;
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


CompileType BinaryUint32OpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType ShiftUint32OpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


CompileType UnaryUint32OpInstr::ComputeType() const {
  return CompileType::FromCid(kSmiCid);
}


DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(ShiftUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)


LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUnboxedMint) {
    UNREACHABLE();
  } else if (to() == kUnboxedMint) {
    UNREACHABLE();
  } else {
    ASSERT((to() == kUnboxedUint32) || (to() == kUnboxedInt32));
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
  }
  return summary;
}


void UnboxedIntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent but we want to normalize
    // upperbits for safety reasons.
    // TODO(vegorov) if we ensure that we never use kDoubleWord size
    // with it then we could avoid this.
    // TODO(vegorov) implement and use UBFM for zero extension.
    __ LslImmediate(out, value, 32);
    __ LsrImmediate(out, out, 32);
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    // Representations are bitwise equivalent.
    // TODO(vegorov) if we ensure that we never use kDoubleWord size
    // with it then we could avoid this.
    // TODO(vegorov) implement and use SBFM for sign extension.
    const Register value = locs()->in(0).reg();
    const Register out = locs()->out(0).reg();
    __ LslImmediate(out, value, 32);
    __ AsrImmediate(out, out, 32);
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ cmp(out, Operand(value, UXTW, 0));
      __ b(deopt, NE);
    }
  } else if (from() == kUnboxedMint) {
    UNREACHABLE();
  } else if (to() == kUnboxedMint) {
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    UNREACHABLE();
  } else {
    UNREACHABLE();
  }
}


LocationSummary* ThrowInstr::MakeLocationSummary(Zone* zone,
                                                 bool opt) const {
  return new(zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kThrowRuntimeEntry,
                                1,
                                locs());
  __ brk(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary(Zone* zone,
                                                   bool opt) const {
  return new(zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStacktrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kReThrowRuntimeEntry,
                                2,
                                locs());
  __ brk(0);
}


LocationSummary* StopInstr::MakeLocationSummary(Zone* zone,
                                                bool opt) const {
  return new(zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void StopInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Stop(message());
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(Zone* zone,
                                                bool opt) const {
  return new(zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->is_optimizing()) {
    if (FLAG_reorder_basic_blocks) {
      compiler->EmitEdgeCounter(block()->preorder_number());
    }
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   GetDeoptId(),
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

  LocationSummary* summary = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());

  return summary;
}


void IndirectGotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register target_address_reg = locs()->temp_slot(0)->reg();

  // Load code entry point.
  const intptr_t entry_offset = __ CodeSize();
  if (Utils::IsInt(21, -entry_offset)) {
    __ adr(target_address_reg, Immediate(-entry_offset));
  } else {
    __ adr(target_address_reg, Immediate(0));
    __ AddImmediate(target_address_reg, target_address_reg, -entry_offset);
  }

  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  Operand offset_opr =
      (offset()->definition()->representation() == kTagged) ?
      Operand(offset_reg, ASR, kSmiTagSize) :
      Operand(offset_reg);
  __ add(target_address_reg, target_address_reg, offset_opr);

  // Jump to the absolute address.
  __ br(target_address_reg);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new(zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(R0));
    locs->set_in(1, Location::RegisterLocation(R1));
    locs->set_out(0, Location::RegisterLocation(R0));
    return locs;
  }
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  Condition true_condition;
  if (left.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(right.reg(),
                                                           left.constant(),
                                                           needs_number_check(),
                                                           token_pos());
  } else if (right.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(left.reg(),
                                                           right.constant(),
                                                           needs_number_check(),
                                                           token_pos());
  } else {
    true_condition = compiler->EmitEqualityRegRegCompare(left.reg(),
                                                         right.reg(),
                                                         needs_number_check(),
                                                         token_pos());
  }
  if (kind() != Token::kEQ_STRICT) {
    ASSERT(kind() == Token::kNE_STRICT);
    true_condition = NegateCondition(true_condition);
  }
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StrictCompareInstr");
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  const Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone,
                               1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();

  __ LoadObject(result, Bool::True());
  __ LoadObject(TMP, Bool::False());
  __ CompareRegisters(result, value);
  __ csel(result, TMP, result, EQ);
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  return MakeCallSummary(zone);
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForClass(cls()));
  const StubEntry stub_entry(stub);
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  compiler->AddStubCallTarget(stub);
  __ Drop(ArgumentCount());  // Discard arguments.
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  compiler->GenerateCall(
      token_pos(), *StubCode::DebugStepCheck_entry(), stub_kind_, locs());
}


LocationSummary* GrowRegExpStackInstr::MakeLocationSummary(
    Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(0, Location::RegisterLocation(R0));
  return locs;
}


void GrowRegExpStackInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register typed_data = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ PushObject(Object::null_object());
  __ Push(typed_data);
  compiler->GenerateRuntimeCall(TokenPosition::kNoSource,
                                deopt_id(),
                                kGrowRegExpStackRuntimeEntry,
                                1,
                                locs());
  __ Drop(1);
  __ Pop(result);
}


}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
