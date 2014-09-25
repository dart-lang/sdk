// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/intermediate_language.h"

#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(bool, emit_edge_counters);
DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, throw_on_javascript_int_overflow);
DECLARE_FLAG(bool, use_osr);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register RAX.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(
      Isolate::Current(), 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(RAX));
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
      __ pushq(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant(), PP);
    } else {
      ASSERT(value.IsStackSlot());
      __ pushq(value.ToStackSlotAddress());
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Isolate* isolate,
                                                  bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == RAX);

  if (compiler->intrinsic_mode()) {
    // Intrinsics don't have a frame.
    __ ret();
    return;
  }

#if defined(DEBUG)
  __ Comment("Stack Check");
  Label done;
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ movq(RDI, RSP);
  __ subq(RDI, RBP);
  __ CompareImmediate(RDI, Immediate(fp_sp_dist), PP);
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ int3();
  __ Bind(&done);
#endif
  __ LeaveDartFrame();
  __ ret();
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQUAL:         return NOT_EQUAL;
    case NOT_EQUAL:     return EQUAL;
    case LESS:          return GREATER_EQUAL;
    case LESS_EQUAL:    return GREATER;
    case GREATER:       return LESS_EQUAL;
    case GREATER_EQUAL: return LESS;
    case BELOW:         return ABOVE_EQUAL;
    case BELOW_EQUAL:   return ABOVE;
    case ABOVE:         return BELOW_EQUAL;
    case ABOVE_EQUAL:   return BELOW;
    default:
      UNIMPLEMENTED();
      return EQUAL;
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
  // TODO(vegorov): support byte register constraints in the register allocator.
  comparison()->locs()->set_out(0, Location::RegisterLocation(RDX));
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out(0).reg() == RDX);

  // Clear upper part of the out register. We are going to use setcc on it
  // which is a byte move.
  __ xorq(RDX, RDX);

  // Emit comparison code. This must not overwrite the result register.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);

  const bool is_power_of_two_kind = IsPowerOfTwoKind(if_true_, if_false_);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if (is_power_of_two_kind) {
    if (true_value == 0) {
      // We need to have zero in RDX on true_condition.
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

  __ setcc(true_condition, DL);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ shlq(RDX, Immediate(shift + kSmiTagSize));
  } else {
    __ decq(RDX);
    __ AndImmediate(RDX,
        Immediate(Smi::RawValue(true_value) - Smi::RawValue(false_value)), PP);
    if (false_value != 0) {
      __ AddImmediate(RDX, Immediate(Smi::RawValue(false_value)), PP);
    }
  }
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t stack_index = (local().index() < 0)
      ? kFirstLocalSlotFromFp - local().index()
      : kParamEndSlotFromFp - local().index();
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::StackSlot(stack_index),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  // Nothing to do.
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movq(Address(RBP, local().index() * kWordSize), value);
}


LocationSummary* ConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  const intptr_t kNumInputs = 0;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    Register result = locs()->out(0).reg();
    __ LoadObject(result, value(), PP);
  }
}


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  switch (representation()) {
    case kUnboxedDouble:
      locs->set_out(0, Location::RequiresFpuRegister());
      break;
    case kUnboxedInt32:
      locs->set_out(0, Location::RequiresRegister());
      break;
    default:
      UNREACHABLE();
      break;
  }
  return locs;
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    switch (representation()) {
      case kUnboxedDouble: {
        XmmRegister result = locs()->out(0).fpu_reg();
        if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0)) {
          __ xorps(result, result);
        } else {
          __ LoadObject(TMP, value(), PP);
          __ movsd(result, FieldAddress(TMP, Double::value_offset()));
        }
        break;
      }
      case kUnboxedInt32:
        __ movl(locs()->out(0).reg(),
                Immediate(static_cast<int32_t>(Smi::Cast(value()).Value())));
        break;
      default:
        UNREACHABLE();
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RAX));  // Value.
  summary->set_in(1, Location::RegisterLocation(RCX));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(RDX));  // Type arguments.
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(0, Location::RegisterLocation(RAX));
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
  __ CompareObject(reg, Bool::True(), PP);
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ CompareObject(reg, Bool::False(), PP);
  __ j(EQUAL, &done, Assembler::kNearJump);

  __ pushq(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos,
                                deopt_id,
                                kNonBoolTypeErrorRuntimeEntry,
                                1,
                                locs);
  // We should never return here.
  __ int3();
  __ Bind(&done);
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}


static Condition TokenKindToSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQUAL;
    case Token::kNE: return NOT_EQUAL;
    case Token::kLT: return LESS;
    case Token::kGT: return GREATER;
    case Token::kLTE: return LESS_EQUAL;
    case Token::kGTE: return GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps =  0;
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


static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         Label* value_is_smi = NULL) {
  Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, Immediate(kSmiCid), PP);
  }
  __ testq(value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ j(ZERO, &done, Assembler::kNearJump);
  } else {
    __ j(ZERO, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}


static Condition FlipCondition(Condition condition) {
  switch (condition) {
    case EQUAL:         return EQUAL;
    case NOT_EQUAL:     return NOT_EQUAL;
    case LESS:          return GREATER;
    case LESS_EQUAL:    return GREATER_EQUAL;
    case GREATER:       return LESS;
    case GREATER_EQUAL: return LESS_EQUAL;
    case BELOW:         return ABOVE;
    case BELOW_EQUAL:   return ABOVE_EQUAL;
    case ABOVE:         return BELOW;
    case ABOVE_EQUAL:   return BELOW_EQUAL;
    default:
      UNIMPLEMENTED();
      return EQUAL;
  }
}


static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ j(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = NegateCondition(true_condition);
    __ j(false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ jmp(labels.true_label);
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

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(right.reg(), left.constant(), PP);
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant(), PP);
  } else if (right.IsStackSlot()) {
    __ cmpq(left.reg(), right.ToStackSlotAddress());
  } else {
    __ cmpq(left.reg(), right.reg());
  }
  return true_condition;
}


static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQUAL;
    case Token::kNE: return NOT_EQUAL;
    case Token::kLT: return BELOW;
    case Token::kGT: return ABOVE;
    case Token::kLTE: return BELOW_EQUAL;
    case Token::kGTE: return ABOVE_EQUAL;
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
  Label* nan_result = (true_condition == NOT_EQUAL)
      ? labels.true_label : labels.false_label;
  __ j(PARITY_EVEN, nan_result);
  return true_condition;
}


Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kEQ) || (kind() == Token::kNE));

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler,  true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False(), PP);
  __ jmp(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True(), PP);
  __ Bind(&done);
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
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
  Register left_reg = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int64_t imm =
        reinterpret_cast<int64_t>(right.constant().raw());
    __ TestImmediate(left_reg, Immediate(imm), PP);
  } else {
    __ testq(left_reg, right.reg());
  }
  Condition true_condition = (kind() == Token::kNE) ? NOT_ZERO : ZERO;
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
  Register val_reg = locs()->in(0).reg();
  Register cid_reg = locs()->temp(0).reg();

  Label* deopt = CanDeoptimize() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids) : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ testq(val_reg, Immediate(kSmiTagMask));
  __ j(ZERO, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ cmpq(cid_reg,  Immediate(test_cid));
    __ j(EQUAL, result ? labels.true_label : labels.false_label);
  }
  // No match found, deoptimize or false.
  if (deopt == NULL) {
    Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ jmp(target);
    }
  } else {
    __ jmp(deopt);
  }
  // Dummy result as the last instruction is a jump, any conditional
  // branch using the result will therefore be skipped.
  return ZERO;
}


void TestCidsInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                   BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  EmitComparisonCode(compiler, labels);
}


void TestCidsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result_reg = locs()->out(0).reg();
  Label is_true, is_false, done;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  EmitComparisonCode(compiler, labels);
  __ Bind(&is_false);
  __ LoadObject(result_reg, Bool::False(), PP);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True(), PP);
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
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
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False(), PP);
  __ jmp(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True(), PP);
  __ Bind(&done);
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* NativeCallInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(RAX));
  locs->set_temp(1, Location::RegisterLocation(RBX));
  locs->set_temp(2, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == RAX);
  ASSERT(locs()->temp(1).reg() == RBX);
  ASSERT(locs()->temp(2).reg() == R10);
  Register result = locs()->out(0).reg();
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const bool is_leaf_call =
    (argc_tag & NativeArguments::AutoSetupScopeMask()) == 0;
  StubCode* stub_code = compiler->isolate()->stub_code();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object(), PP);
  // Pass a pointer to the first argument in RAX.
  if (!function().HasOptionalParameters()) {
    __ leaq(RAX, Address(RBP, (kParamEndSlotFromFp +
                               function().NumParameters()) * kWordSize));
  } else {
    __ leaq(RAX,
            Address(RBP, kFirstLocalSlotFromFp * kWordSize));
  }
  __ LoadImmediate(
      RBX, Immediate(reinterpret_cast<uword>(native_c_function())), PP);
  __ LoadImmediate(
      R10, Immediate(argc_tag), PP);
  const ExternalLabel* stub_entry = (is_bootstrap_native() || is_leaf_call) ?
      &stub_code->CallBootstrapCFunctionLabel() :
      &stub_code->CallNativeCFunctionLabel();
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  __ popq(result);
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
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ LoadImmediate(result,
      Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())), PP);
  __ movq(result, Address(result,
                          char_code,
                          TIMES_HALF_WORD_SIZE,  // Char code is a smi.
                          Symbols::kNullCharCodeSymbolOffset * kWordSize));
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
  Register str = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Label is_one, done;
  __ movq(result, FieldAddress(str, String::length_offset()));
  __ cmpq(result, Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, Assembler::kNearJump);
  __ movq(result, Immediate(Smi::RawValue(-1)));
  __ jmp(&done);
  __ Bind(&is_one);
  __ movzxb(result, FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ pushq(array);
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               CallFunction(),
                               kNumberOfArguments,
                               kNoArgumentNames,
                               locs(),
                               ICData::Handle());
  ASSERT(locs()->out(0).reg() == RAX);
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
  Register object = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ movq(result, FieldAddress(object, offset()));
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
  Label load, done;

  // We don't use Assembler::LoadTaggedClassIdMayBeSmi() here---which uses
  // a conditional move instead---because it is slower, probably due to
  // branch prediction usually working just fine in this case.
  __ testq(object, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &load, Assembler::kNearJump);
  __ LoadImmediate(result, Immediate(Smi::RawValue(kSmiCid)), PP);
  __ jmp(&done);
  __ Bind(&load);
  __ LoadClassId(result, object);
  __ SmiTag(result);
  __ Bind(&done);
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
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return kTagged;
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


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  if (index_scale() == 1) {
    locs->set_in(1, CanBeImmediateIndex(index(), class_id())
                      ? Location::Constant(index()->definition()->AsConstant())
                      : Location::WritableRegister());
  } else {
    locs->set_in(1, CanBeImmediateIndex(index(), class_id())
                      ? Location::Constant(index()->definition()->AsConstant())
                      : Location::RequiresRegister());
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
      ? Assembler::ElementAddressForRegIndex(
            IsExternal(), class_id(), index_scale(), array, index.reg())
      : Assembler::ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());

  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
      (representation() == kUnboxedFloat64x2)) {
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }

    XmmRegister result = locs()->out(0).fpu_reg();
    if (class_id() == kTypedDataFloat32ArrayCid) {
      // Load single precision float.
      __ movss(result, element_address);
    } else if (class_id() == kTypedDataFloat64ArrayCid) {
      __ movsd(result, element_address);
    } else {
      ASSERT((class_id() == kTypedDataInt32x4ArrayCid)   ||
             (class_id() == kTypedDataFloat32x4ArrayCid) ||
             (class_id() == kTypedDataFloat64x2ArrayCid));
      __ movups(result, element_address);
    }
    return;
  }

  if ((index_scale() == 1) && index.IsRegister()) {
    __ SmiUntag(index.reg());
  }
  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      __ movsxb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
      __ movzxb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ movsxw(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
      __ movzxw(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt32ArrayCid:
      __ movsxd(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint32ArrayCid:
      __ movl(result, element_address);
      __ SmiTag(result);
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ movq(result, element_address);
      break;
  }
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  if (idx == 0) return kNoRepresentation;
  if (idx == 1) return kTagged;
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
      UNIMPLEMENTED();
      return kTagged;
  }
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  if (index_scale() == 1) {
    locs->set_in(1, CanBeImmediateIndex(index(), class_id())
                      ? Location::Constant(index()->definition()->AsConstant())
                      : Location::WritableRegister());
  } else {
    locs->set_in(1, CanBeImmediateIndex(index(), class_id())
                      ? Location::Constant(index()->definition()->AsConstant())
                      : Location::RequiresRegister());
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
      // TODO(fschneider): Add location constraint for byte registers (RAX,
      // RBX, RCX, RDX) instead of using a fixed register.
      locs->set_in(2, Location::FixedRegisterOrSmiConstant(value(), RAX));
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // Writable register because the value must be untagged before storing.
      locs->set_in(2, Location::WritableRegister());
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
      return NULL;
  }
  return locs;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = index.IsRegister()
      ? Assembler::ElementAddressForRegIndex(
            IsExternal(), class_id(), index_scale(), array, index.reg())
      : Assembler::ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());

  if ((index_scale() == 1) && index.IsRegister()) {
    __ SmiUntag(index.reg());
  }
  switch (class_id()) {
    case kArrayCid:
      if (ShouldEmitStoreBarrier()) {
        Register value = locs()->in(2).reg();
        __ StoreIntoObject(array, element_address, value);
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreObject(element_address, constant, PP);
      } else {
        Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, element_address, value);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kOneByteStringCid:
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ movb(element_address,
                Immediate(static_cast<int8_t>(constant.Value())));
      } else {
        ASSERT(locs()->in(2).reg() == RAX);
        __ SmiUntag(RAX);
        __ movb(element_address, RAX);
      }
      break;
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
        __ movb(element_address,
                Immediate(static_cast<int8_t>(value)));
      } else {
        ASSERT(locs()->in(2).reg() == RAX);
        Label store_value, store_0xff;
        __ SmiUntag(RAX);
        __ CompareImmediate(RAX, Immediate(0xFF), PP);
        __ j(BELOW_EQUAL, &store_value, Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorq(RAX, RAX);
        __ jmp(&store_value, Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ LoadImmediate(RAX, Immediate(0xFF), PP);
        __ Bind(&store_value);
        __ movb(element_address, RAX);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      Register value = locs()->in(2).reg();
      __ SmiUntag(value);
      __ movw(element_address, value);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      Register value = locs()->in(2).reg();
      __ movl(element_address, value);
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
}


LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Isolate* isolate,
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

  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));

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
    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()), PP);

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);

      __ cmpl(value_cid_reg, field_cid_operand);
      __ j(EQUAL, &ok);
      __ cmpl(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      __ cmpl(field_nullability_operand, Immediate(value_cid));
    } else {
      __ cmpl(field_cid_operand, Immediate(value_cid));
    }
    __ j(EQUAL, &ok);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ cmpl(field_cid_operand, Immediate(kIllegalCid));
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        __ movl(field_cid_operand, value_cid_reg);
        __ movl(field_nullability_operand, value_cid_reg);
      } else {
        ASSERT(field_reg != kNoRegister);
        __ movl(field_cid_operand, Immediate(value_cid));
        __ movl(field_nullability_operand, Immediate(value_cid));
      }

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ jmp(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ cmpl(FieldAddress(field_reg, Field::guarded_cid_offset()),
              Immediate(kDynamicCid));
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testq(value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, Immediate(field_cid), PP);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        __ CompareObject(value_reg, Object::null_object(), PP);
      }

      __ j(NOT_EQUAL, fail);
    } else {
      // Both value's and field's class id is known.
      ASSERT((value_cid != field_cid) && (value_cid != nullability));
      __ jmp(fail);
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
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, 0, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
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

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()), PP);

    __ movsxb(offset_reg, FieldAddress(field_reg,
        Field::guarded_list_length_in_object_offset_offset()));
    __ movq(length_reg, FieldAddress(field_reg,
        Field::guarded_list_length_offset()));

    __ cmpq(offset_reg, Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ cmpq(length_reg, Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == NULL) {
      __ j(EQUAL, &ok);

      __ pushq(field_reg);
      __ pushq(value_reg);
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
            FieldAddress(value_reg,
                         field().guarded_list_length_in_object_offset()),
            Immediate(Smi::RawValue(field().guarded_list_length())),
            PP);
    __ j(NOT_EQUAL, deopt);
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
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();

    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s",
                 instruction_->DebugName(),
                 String::Handle(cls_.PrettyName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub =
        Code::Handle(isolate, stub_code->GetAllocationStubForClass(cls_));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();

    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    __ MoveRegister(result_, RAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result) {
    if (compiler->intrinsic_mode()) {
      __ TryAllocate(cls,
                     compiler->intrinsic_slow_path_label(),
                     Assembler::kFarJump,
                     result,
                     PP);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls,
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     result,
                     PP);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
  Instruction* instruction_;
  const Class& cls_;
  const Register result_;
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
                             : Location::FpuRegisterLocation(XMM1));
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
  __ movq(box_reg, FieldAddress(instance_reg, offset));
  __ CompareObject(box_reg, Object::null_object(), PP);
  __ j(NOT_EQUAL, &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg);
  __ movq(temp, box_reg);
  __ StoreIntoObject(instance_reg,
                     FieldAddress(instance_reg, offset),
                     temp);

  __ Bind(&done);
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label skip_store;

  Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    XmmRegister value = locs()->in(1).fpu_reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
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

      BoxAllocationSlowPath::Allocate(compiler, this, *cls, temp);
      __ movq(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);
    } else {
      __ movq(temp, FieldAddress(instance_reg, offset_in_bytes_));
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ movsd(FieldAddress(temp, Double::value_offset()), value);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ movups(FieldAddress(temp, Float32x4::value_offset()), value);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ movups(FieldAddress(temp, Float64x2::value_offset()), value);
      break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if (IsPotentialUnboxedStore()) {
    Register value_reg = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    FpuRegister fpu_temp = locs()->temp(2).fpu_reg();

    if (ShouldEmitStoreBarrier()) {
      // Value input is a writable register and should be manually preserved
      // across allocation slow-path.
      locs()->live_registers()->Add(locs()->in(1), kTagged);
    }

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(field().raw()), PP);

    __ cmpl(FieldAddress(temp, Field::is_nullable_offset()),
            Immediate(kNullCid));
    __ j(EQUAL, &store_pointer);

    __ movzxb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ testq(temp2, Immediate(1 << Field::kUnboxingCandidateBit));
    __ j(ZERO, &store_pointer);

    __ cmpl(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kDoubleCid));
    __ j(EQUAL, &store_double);

    __ cmpl(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kFloat32x4Cid));
    __ j(EQUAL, &store_float32x4);

    __ cmpl(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kFloat64x2Cid));
    __ j(EQUAL, &store_float64x2);

    // Fall through.
    __ jmp(&store_pointer);

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
      __ movsd(fpu_temp, FieldAddress(value_reg, Double::value_offset()));
      __ movsd(FieldAddress(temp, Double::value_offset()), fpu_temp);
      __ jmp(&skip_store);
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
      __ movups(fpu_temp, FieldAddress(value_reg, Float32x4::value_offset()));
      __ movups(FieldAddress(temp, Float32x4::value_offset()), fpu_temp);
      __ jmp(&skip_store);
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
      __ movups(fpu_temp, FieldAddress(value_reg, Float64x2::value_offset()));
      __ movups(FieldAddress(temp, Float64x2::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObject(instance_reg,
                       FieldAddress(instance_reg, offset_in_bytes_),
                       value_reg,
                       CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreObject(FieldAddress(instance_reg, offset_in_bytes_),
                     locs()->in(1).constant(), PP);
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrier(instance_reg,
          FieldAddress(instance_reg, offset_in_bytes_), value_reg);
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
  Register field = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ movq(result, FieldAddress(field, Field::value_offset()));
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
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  __ LoadObject(temp, field(), PP);
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
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_in(1, Location::RegisterLocation(RCX));
  summary->set_in(2, Location::RegisterLocation(RDX));
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == RAX);  // Value.
  ASSERT(locs()->in(1).reg() == RCX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == RDX);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out(0).reg() == RAX);
}


// TODO(srdjan): In case of constant inputs make CreateArray kNoCall and
// use slow path stub.
LocationSummary* CreateArrayInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RBX));
  locs->set_in(1, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                   intptr_t num_elements,
                                   Label* slow_path,
                                   Label* done) {
  const Register kLengthReg = R10;
  const Register kElemTypeReg = RBX;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path, Assembler::kFarJump,
                      RAX,  // instance
                      RCX);  // end address

  // RAX: new object start as a tagged pointer.
  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(RAX,
                              FieldAddress(RAX, Array::type_arguments_offset()),
                              kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(RAX,
                              FieldAddress(RAX, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    __ LoadObject(R12, Object::null_object(), PP);
    __ leaq(RDI, FieldAddress(RAX, sizeof(RawArray)));
    Label init_loop;
    __ Bind(&init_loop);
    __ movq(Address(RDI, 0), R12);
    __ addq(RDI, Immediate(kWordSize));
    __ cmpq(RDI, RCX);
    __ j(BELOW, &init_loop, Assembler::kNearJump);
  }
  __ jmp(done, Assembler::kNearJump);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  R10 = length, RBX = element type.
  const Register kLengthReg = R10;
  const Register kElemTypeReg = RBX;
  const Register kResultReg = RAX;
  ASSERT(locs()->in(0).reg() == kElemTypeReg);
  ASSERT(locs()->in(1).reg() == kLengthReg);

  Label slow_path, done;
  if (num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object(), PP);  // Make room for the result.
      __ pushq(kLengthReg);
      __ pushq(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(),
                                    deopt_id(),
                                    kAllocateArrayRuntimeEntry,
                                    2,
                                    locs());
      __ Drop(2);
      __ popq(kResultReg);
      __ Bind(&done);
      return;
    }
  }

  __ Bind(&slow_path);
  Isolate* isolate = compiler->isolate();
  const Code& stub = Code::Handle(
      isolate, isolate->stub_code()->GetAllocateArrayStub());
  const ExternalLabel label(stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
  __ Bind(&done);
  ASSERT(locs()->out(0).reg() == kResultReg);
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 :
          ((IsPotentialUnboxedLoad()) ? 2 : 0);
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
                          : Location::FpuRegisterLocation(XMM1));
    locs->set_temp(1, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    XmmRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ movq(temp, FieldAddress(instance_reg, offset_in_bytes()));
    intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ movsd(result, FieldAddress(temp, Double::value_offset()));
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        __ movups(result, FieldAddress(temp, Float32x4::value_offset()));
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2LoadFieldInstr");
        __ movups(result, FieldAddress(temp, Float64x2::value_offset()));
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  Register result = locs()->out(0).reg();
  if (IsPotentialUnboxedLoad()) {
    Register temp = locs()->temp(1).reg();
    XmmRegister value = locs()->temp(0).fpu_reg();

    Label load_pointer;
    Label load_double;
    Label load_float32x4;
    Label load_float64x2;

    __ LoadObject(result, Field::ZoneHandle(field()->raw()), PP);

    __ cmpl(FieldAddress(result, Field::is_nullable_offset()),
            Immediate(kNullCid));
    __ j(EQUAL, &load_pointer);

    __ cmpl(FieldAddress(result, Field::guarded_cid_offset()),
            Immediate(kDoubleCid));
    __ j(EQUAL, &load_double);

    __ cmpl(FieldAddress(result, Field::guarded_cid_offset()),
            Immediate(kFloat32x4Cid));
    __ j(EQUAL, &load_float32x4);

    __ cmpl(FieldAddress(result, Field::guarded_cid_offset()),
            Immediate(kFloat64x2Cid));
    __ j(EQUAL, &load_float64x2);

    // Fall through.
    __ jmp(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->double_class(), result);
      __ movq(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movsd(value, FieldAddress(temp, Double::value_offset()));
      __ movsd(FieldAddress(result, Double::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result);
      __ movq(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float32x4::value_offset()));
      __ movups(FieldAddress(result, Float32x4::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result);
      __ movq(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float64x2::value_offset()));
      __ movups(FieldAddress(result, Float64x2::value_offset()), value);
      __ jmp(&done);
    }

    __ Bind(&load_pointer);
  }
  __ movq(result, FieldAddress(instance_reg, offset_in_bytes()));
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::null_object(), PP);  // Make room for the result.
  __ PushObject(type(), PP);
  __ pushq(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type.
  __ popq(result_reg);  // Pop instantiated type.
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_reg == RAX);
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
    __ CompareObject(instantiator_reg, Object::null_object(), PP);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }

  // Lookup cache before calling runtime.
  // TODO(fschneider): Consider moving this into a shared stub to reduce
  // generated code size.
  __ LoadObject(RDI, type_arguments(), PP);
  __ movq(RDI, FieldAddress(RDI, TypeArguments::instantiations_offset()));
  __ leaq(RDI, FieldAddress(RDI, Array::data_offset()));
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, found, slow_case;
  __ Bind(&loop);
  __ movq(RDX, Address(RDI, 0 * kWordSize));  // Cached instantiator.
  __ cmpq(RDX, RAX);
  __ j(EQUAL, &found, Assembler::kNearJump);
  __ addq(RDI, Immediate(2 * kWordSize));
  __ cmpq(RDX, Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  __ jmp(&slow_case, Assembler::kNearJump);
  __ Bind(&found);
  __ movq(RAX, Address(RDI, 1 * kWordSize));  // Cached instantiated args.
  __ jmp(&type_arguments_instantiated, Assembler::kNearJump);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::null_object(), PP);  // Make room for the result.
  __ PushObject(type_arguments(), PP);
  __ pushq(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ popq(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Isolate* isolate,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
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

    __ LoadImmediate(R10, Immediate(instruction_->num_context_variables()), PP);
    StubCode* stub_code = compiler->isolate()->stub_code();
    const ExternalLabel label(stub_code->AllocateContextEntryPoint());
    compiler->GenerateCall(instruction_->token_pos(),
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    ASSERT(instruction_->locs()->out(0).reg() == RAX);
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ jmp(exit_label());
  }

 private:
  AllocateUninitializedContextInstr* instruction_;
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

  __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                      Assembler::kFarJump,
                      result,  // instance
                      temp);  // end address

  // Setup up number of context variables field.
  __ movq(FieldAddress(result, Context::num_variables_offset()),
          Immediate(num_context_variables()));

  // Setup isolate field.
  __ movq(FieldAddress(result, Context::isolate_offset()),
          Immediate(reinterpret_cast<intptr_t>(Isolate::Current())));

  __ Bind(slow_path->exit_label());
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R10));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R10);
  ASSERT(locs()->out(0).reg() == RAX);
  StubCode* stub_code = compiler->isolate()->stub_code();

  __ LoadImmediate(R10, Immediate(num_context_variables()), PP);
  const ExternalLabel label(stub_code->AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
}


LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_temp(0, Location::RegisterLocation(RCX));
  return locs;
}


void InitStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  Label call_runtime, no_call;

  __ movq(temp, FieldAddress(field, Field::value_offset()));
  __ CompareObject(temp, Object::sentinel(), PP);
  __ j(EQUAL, &call_runtime);

  __ CompareObject(temp, Object::transition_sentinel(), PP);
  __ j(NOT_EQUAL, &no_call);

  __ Bind(&call_runtime);
  __ PushObject(Object::null_object(), PP);  // Make room for (unused) result.
  __ pushq(field);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInitStaticFieldRuntimeEntry,
                                1,
                                locs());
  __ Drop(2);  // Remove argument and unused result.
  __ Bind(&no_call);
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(0, Location::RegisterLocation(RAX));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ PushObject(Object::null_object(), PP);  // Make room for the result.
  __ pushq(context_value);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ popq(result);  // Remove argument.
  __ popq(result);  // Get result (cloned context).
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
  __ LoadPoolPointer(PP);

  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore RSP from RBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ leaq(RSP, Address(RBP, fp_sp_dist));

  // Restore stack and initialize the two exception variables:
  // exception and stack trace variables.
  __ movq(Address(RBP, exception_var().index() * kWordSize),
          kExceptionObjectReg);
  __ movq(Address(RBP, stacktrace_var().index() * kWordSize),
          kStackTraceObjectReg);
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
      Register temp = instruction_->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(temp, Immediate(flags_address), PP);
      __ movq(Address(temp, 0), Immediate(Isolate::kOsrRequest));
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
    __ jmp(exit_label());
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

  Register temp = locs()->temp(0).reg();
  // Generate stack overflow check.
  __ LoadImmediate(
      temp, Immediate(Isolate::Current()->stack_limit_address()), PP);
  __ cmpq(RSP, Address(temp, 0));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function(), PP);
    int32_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ cmpl(FieldAddress(temp, Function::usage_counter_offset()),
            Immediate(threshold));
    __ j(GREATER_EQUAL, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ jmp(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}


static void EmitJavascriptOverflowCheck(FlowGraphCompiler* compiler,
                                        Range* range,
                                        Label* overflow,
                                        Register result) {
  if (!RangeUtils::IsWithin(range, -0x20000000000000LL, 0x20000000000000LL)) {
    ASSERT(overflow != NULL);
    // TODO(zra): This can be tightened to one compare/branch using:
    // overflow = (result + 2^52) > 2^53 with an unsigned comparison.
    __ CompareImmediate(result, Immediate(-0x20000000000000LL), PP);
    __ j(LESS, overflow);
    __ CompareImmediate(result, Immediate(0x20000000000000LL), PP);
    __ j(GREATER, overflow);
  }
}


static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  ASSERT(left == result);
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), ICData::kDeoptBinarySmiOp)
      : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // shlq operation masks the count to 6 bits.
    const intptr_t kCountLimit = 0x3F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow.
      Register temp = locs.temp(0).reg();
      __ movq(temp, left);
      __ shlq(left, Immediate(value));
      __ sarq(left, Immediate(value));
      __ cmpq(left, temp);
      __ j(NOT_EQUAL, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ shlq(left, Immediate(value));
    if (FLAG_throw_on_javascript_int_overflow) {
      EmitJavascriptOverflowCheck(compiler, shift_left->range(), deopt, result);
    }
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right()->definition()->range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ CompareImmediate(right, Immediate(0), PP);
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ CompareImmediate(right,
            Immediate(reinterpret_cast<int64_t>(Smi::New(max_right))), PP);
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ shlq(left, right);
    }
    if (FLAG_throw_on_javascript_int_overflow) {
      EmitJavascriptOverflowCheck(compiler, shift_left->range(), deopt, result);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  ASSERT(right == RCX);  // Count must be in RCX
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ CompareImmediate(right, Immediate(0), PP);
        __ j(NEGATIVE, deopt);
      }
      Label done, is_not_zero;
      __ CompareImmediate(right,
          Immediate(reinterpret_cast<int64_t>(Smi::New(Smi::kBits))), PP);
      __ j(BELOW, &is_not_zero, Assembler::kNearJump);
      __ xorq(left, left);
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(right);
      __ shlq(left, right);
      __ Bind(&done);
    } else {
      __ SmiUntag(right);
      __ shlq(left, right);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ CompareImmediate(right,
          Immediate(reinterpret_cast<int64_t>(Smi::New(Smi::kBits))), PP);
      __ j(ABOVE_EQUAL, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ movq(temp, left);
    __ SmiUntag(right);
    // Overflow test (preserve temp and right);
    __ shlq(left, right);
    __ sarq(left, right);
    __ cmpq(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ shlq(left, right);
  }
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptOverflowCheck(compiler, shift_left->range(), deopt, result);
  }
}


static bool CanBeImmediate(const Object& constant) {
  return constant.IsSmi() &&
    Immediate(reinterpret_cast<int64_t>(constant.raw())).is_int32();
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;

  ConstantInstr* right_constant = right()->definition()->AsConstant();
  if ((right_constant != NULL) &&
      (op_kind() != Token::kTRUNCDIV) &&
      (op_kind() != Token::kSHL) &&
      (op_kind() != Token::kMUL) &&
      (op_kind() != Token::kMOD) &&
      CanBeImmediate(right_constant->value())) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::Constant(right_constant));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }

  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(RDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(RAX));
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), RCX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    const intptr_t kNumTemps = can_overflow() ? 1 : 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), RCX));
    if (can_overflow()) {
      summary->set_temp(0, Location::RequiresRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    ConstantInstr* constant = right()->definition()->AsConstant();
    if (constant != NULL) {
      summary->set_in(1, Location::RegisterOrSmiConstant(right()));
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
        __ AddImmediate(left, Immediate(imm), PP);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ SubImmediate(left, Immediate(imm), PP);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ MulImmediate(left, Immediate(value), PP);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        Register temp = locs()->temp(0).reg();
        __ movq(temp, left);
        __ sarq(temp, Immediate(63));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        __ shrq(temp, Immediate(64 - shift_count));
        __ addq(left, temp);
        ASSERT(shift_count > 0);
        __ sarq(left, Immediate(shift_count));
        if (value < 0) {
          __ negq(left);
        }
        __ SmiTag(left);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ AndImmediate(left, Immediate(imm), PP);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ OrImmediate(left, Immediate(imm), PP);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ XorImmediate(left, Immediate(imm), PP);
        break;
      }

      case Token::kSHR: {
        // sarq operation masks the count to 6 bits.
        const intptr_t kCountLimit = 0x3F;
        const intptr_t value = Smi::Cast(constant).Value();
        __ sarq(left, Immediate(
            Utils::Minimum(value + kSmiTagSize, kCountLimit)));
        __ SmiTag(left);
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    if (FLAG_throw_on_javascript_int_overflow) {
      EmitJavascriptOverflowCheck(compiler, range(), deopt, result);
    }
    return;
  }  // locs()->in(1).IsConstant().


  if (locs()->in(1).IsStackSlot()) {
    const Address& right = locs()->in(1).ToStackSlotAddress();
    switch (op_kind()) {
      case Token::kADD: {
        __ addq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ subq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(left);
        __ imulq(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
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
    if (FLAG_throw_on_javascript_int_overflow) {
      EmitJavascriptOverflowCheck(compiler, range(), deopt, result);
    }
    return;
  }  // locs()->in(1).IsStackSlot().

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  Range* right_range = this->right()->definition()->range();
  switch (op_kind()) {
    case Token::kADD: {
      __ addq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kSUB: {
      __ subq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ imulq(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
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
      Label not_32bit, done;

      Register temp = locs()->temp(0).reg();
      ASSERT(left == RAX);
      ASSERT((right != RDX) && (right != RAX));
      ASSERT(temp == RDX);
      ASSERT(result == RAX);
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
        // Handle divide by zero in runtime.
        __ testq(right, right);
        __ j(ZERO, deopt);
      }
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
      __ cqo();  // Sign extend RAX -> RDX:RAX.
      __ idivq(right);  //  RAX: quotient, RDX: remainder.
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ CompareImmediate(result, Immediate(0x4000000000000000), PP);
      __ j(EQUAL, deopt);
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      Label not_32bit, div_done;

      Register temp = locs()->temp(0).reg();
      ASSERT(left == RDX);
      ASSERT((right != RDX) && (right != RAX));
      ASSERT(temp == RAX);
      ASSERT(result == RDX);
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
        // Handle divide by zero in runtime.
        __ testq(right, right);
        __ j(ZERO, deopt);
      }
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
      __ movq(RAX, RDX);
      __ cdq();
      __ idivl(right);
      __ movsxd(result, result);
      __ jmp(&div_done);

      // Divide using 64bit idiv.
      __ Bind(&not_32bit);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movq(RAX, RDX);
      __ cqo();  // Sign extend RAX -> RDX:RAX.
      __ idivq(right);  //  RAX: quotient, RDX: remainder.
      __ Bind(&div_done);
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      Label all_done;
      __ cmpq(result, Immediate(0));
      __ j(GREATER_EQUAL, &all_done, Assembler::kNearJump);
      // Result is negative, adjust it.
      if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
        Label subtract;
        __ cmpq(right, Immediate(0));
        __ j(LESS, &subtract, Assembler::kNearJump);
        __ addq(result, right);
        __ jmp(&all_done, Assembler::kNearJump);
        __ Bind(&subtract);
        __ subq(result, right);
      } else if (right_range->IsPositive()) {
        // Right is positive.
        __ addq(result, right);
      } else {
        // Right is negative.
        __ subq(result, right);
      }
      __ Bind(&all_done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, Immediate(0), PP);
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarq operation masks the count to 6 bits.
      const intptr_t kCountLimit = 0x3F;
      if ((right_range == NULL) ||
          !right_range->OnlyLessThanOrEqualTo(kCountLimit)) {
        __ CompareImmediate(right, Immediate(kCountLimit), PP);
        Label count_ok;
        __ j(LESS, &count_ok, Assembler::kNearJump);
        __ LoadImmediate(right, Immediate(kCountLimit), PP);
        __ Bind(&count_ok);
      }
      ASSERT(right == RCX);  // Count must be in RCX
      __ SmiUntag(left);
      __ sarq(left, right);
      __ SmiTag(left);
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
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptOverflowCheck(compiler, range(), deopt, result);
  }
}


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const bool need_temp = (left()->definition() != right()->definition())
                      && (left_cid != kSmiCid)
                      && (right_cid != kSmiCid);
  const intptr_t kNumTemps = need_temp ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
    isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (need_temp) summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptBinaryDoubleOp);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ testq(left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ testq(right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testq(left, Immediate(kSmiTagMask));
  } else {
    Register temp = locs()->temp(0).reg();
    __ movq(temp, left);
    __ orq(temp, right);
    __ testq(temp, Immediate(kSmiTagMask));
  }
  __ j(ZERO, deopt);
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->double_class(), out_reg);
  __ movsd(FieldAddress(out_reg, Double::value_offset()), value);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  const bool needs_writable_input = (value()->Type()->ToCid() != kDoubleCid);
  summary->set_in(0, needs_writable_input
                     ? Location::WritableRegister()
                     : Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CompileType* value_type = value()->Type();
  const intptr_t value_cid = value_type->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid == kDoubleCid) {
    __ movsd(result, FieldAddress(value, Double::value_offset()));
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ cvtsi2sd(result, value);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptBinaryDoubleOp);
    if (value_type->is_nullable() &&
        (value_type->ToNullableCid() == kDoubleCid)) {
      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ cmpq(value, raw_null);
      __ j(EQUAL, deopt);
      // It must be double now.
      __ movsd(result, FieldAddress(value, Double::value_offset()));
    } else {
      Label is_smi, done;
      __ testq(value, Immediate(kSmiTagMask));
      __ j(ZERO, &is_smi);
      __ CompareClassId(value, kDoubleCid);
      __ j(NOT_EQUAL, deopt);
      __ movsd(result, FieldAddress(value, Double::value_offset()));
      __ jmp(&done);
      __ Bind(&is_smi);
      __ SmiUntag(value);
      __ cvtsi2sd(result, value);
      __ Bind(&done);
    }
  }
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->float32x4_class(), out_reg);
  __ movups(FieldAddress(out_reg, Float32x4::value_offset()), value);
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresFpuRegister(),
                               LocationSummary::kNoCall);
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat32x4Cid) {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testq(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat32x4Cid);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Float32x4::value_offset()));
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->float64x2_class(), out_reg);
  __ movups(FieldAddress(out_reg, Float64x2::value_offset()), value);
}


LocationSummary* UnboxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kFloat64x2Cid ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat64x2Cid) {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testq(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat64x2Cid);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Float64x2::value_offset()));
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->int32x4_class(), out_reg);
  __ movups(FieldAddress(out_reg, Int32x4::value_offset()), value);
}


LocationSummary* UnboxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kInt32x4Cid) {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testq(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kInt32x4Cid);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Int32x4::value_offset()));
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Isolate* isolate,
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


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addsd(left, right); break;
    case Token::kSUB: __ subsd(left, right); break;
    case Token::kMUL: __ mulsd(left, right); break;
    case Token::kDIV: __ divsd(left, right); break;
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addps(left, right); break;
    case Token::kSUB: __ subps(left, right); break;
    case Token::kMUL: __ mulps(left, right); break;
    case Token::kDIV: __ divps(left, right); break;
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addpd(left, right); break;
    case Token::kSUB: __ subpd(left, right); break;
    case Token::kMUL: __ mulpd(left, right); break;
    case Token::kDIV: __ divpd(left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == value);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleX:
      // Shuffle not necessary.
      __ cvtss2sd(value, value);
      break;
    case MethodRecognizer::kFloat32x4ShuffleY:
      __ shufps(value, value, Immediate(0x55));
      __ cvtss2sd(value, value);
      break;
    case MethodRecognizer::kFloat32x4ShuffleZ:
      __ shufps(value, value, Immediate(0xAA));
      __ cvtss2sd(value, value);
      break;
    case MethodRecognizer::kFloat32x4ShuffleW:
      __ shufps(value, value, Immediate(0xFF));
      __ cvtss2sd(value, value);
      break;
    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kInt32x4Shuffle:
      __ shufps(value, value, Immediate(mask_));
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
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);
  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
      __ shufps(left, right, Immediate(mask_));
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  Register out = locs()->out(0).reg();

  __ movmskps(out, value);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister v0 = locs()->in(0).fpu_reg();
  XmmRegister v1 = locs()->in(1).fpu_reg();
  XmmRegister v2 = locs()->in(2).fpu_reg();
  XmmRegister v3 = locs()->in(3).fpu_reg();
  ASSERT(v0 == locs()->out(0).fpu_reg());
  __ AddImmediate(RSP, Immediate(-16), PP);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(RSP, 0), v0);
  __ movsd(v0, v1);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(RSP, 4), v0);
  __ movsd(v0, v2);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(RSP, 8), v0);
  __ movsd(v0, v3);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(RSP, 12), v0);
  __ movups(v0, Address(RSP, 0));
  __ AddImmediate(RSP, Immediate(16), PP);
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
  XmmRegister value = locs()->out(0).fpu_reg();
  __ xorps(value, value);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out(0).fpu_reg();
  ASSERT(locs()->in(0).fpu_reg() == locs()->out(0).fpu_reg());
  // Convert to Float32.
  __ cvtsd2ss(value, value);
  // Splat across all lanes.
  __ shufps(value, value, Immediate(0x00));
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Isolate* isolate,
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


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Equal:
      __ cmppseq(left, right);
      break;
    case MethodRecognizer::kFloat32x4NotEqual:
      __ cmppsneq(left, right);
      break;
    case MethodRecognizer::kFloat32x4GreaterThan:
      __ cmppsnle(left, right);
      break;
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
      __ cmppsnlt(left, right);
      break;
    case MethodRecognizer::kFloat32x4LessThan:
      __ cmppslt(left, right);
      break;
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
      __ cmppsle(left, right);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Min:
      __ minps(left, right);
      break;
    case MethodRecognizer::kFloat32x4Max:
      __ maxps(left, right);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Scale:
      __ cvtsd2ss(left, left);
      __ shufps(left, left, Immediate(0x00));
      __ mulps(left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Sqrt:
      __ sqrtps(left);
      break;
    case MethodRecognizer::kFloat32x4Reciprocal:
      __ reciprocalps(left);
      break;
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
      __ rsqrtps(left);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);
  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Negate:
      __ negateps(left);
      break;
    case MethodRecognizer::kFloat32x4Absolute:
      __ absps(left);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister lower = locs()->in(1).fpu_reg();
  XmmRegister upper = locs()->in(2).fpu_reg();
  ASSERT(locs()->out(0).fpu_reg() == left);
  __ minps(left, upper);
  __ maxps(left, lower);
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Isolate* isolate,
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


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister replacement = locs()->in(0).fpu_reg();
  XmmRegister value = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == replacement);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4WithX:
      __ cvtsd2ss(replacement, replacement);
      __ AddImmediate(RSP, Immediate(-16), PP);
      // Move value to stack.
      __ movups(Address(RSP, 0), value);
      // Write over X value.
      __ movss(Address(RSP, 0), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(RSP, 0));
      __ AddImmediate(RSP, Immediate(16), PP);
      break;
    case MethodRecognizer::kFloat32x4WithY:
      __ cvtsd2ss(replacement, replacement);
      __ AddImmediate(RSP, Immediate(-16), PP);
      // Move value to stack.
      __ movups(Address(RSP, 0), value);
      // Write over Y value.
      __ movss(Address(RSP, 4), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(RSP, 0));
      __ AddImmediate(RSP, Immediate(16), PP);
      break;
    case MethodRecognizer::kFloat32x4WithZ:
      __ cvtsd2ss(replacement, replacement);
      __ AddImmediate(RSP, Immediate(-16), PP);
      // Move value to stack.
      __ movups(Address(RSP, 0), value);
      // Write over Z value.
      __ movss(Address(RSP, 8), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(RSP, 0));
      __ AddImmediate(RSP, Immediate(16), PP);
      break;
    case MethodRecognizer::kFloat32x4WithW:
      __ cvtsd2ss(replacement, replacement);
      __ AddImmediate(RSP, Immediate(-16), PP);
      // Move value to stack.
      __ movups(Address(RSP, 0), value);
      // Write over W value.
      __ movss(Address(RSP, 12), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(RSP, 0));
      __ AddImmediate(RSP, Immediate(16), PP);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // NOP.
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == value);
  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2GetX:
      // nop.
      break;
    case MethodRecognizer::kFloat64x2GetY:
      __ shufpd(value, value, Immediate(0x33));
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
  XmmRegister value = locs()->out(0).fpu_reg();
  __ xorpd(value, value);
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out(0).fpu_reg();
  __ shufpd(value, value, Immediate(0x0));
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister v0 = locs()->in(0).fpu_reg();
  XmmRegister v1 = locs()->in(1).fpu_reg();
  ASSERT(v0 == locs()->out(0).fpu_reg());
  // shufpd mask 0x0 results in:
  // Lower 64-bits of v0 = Lower 64-bits of v0.
  // Upper 64-bits of v0 = Lower 64-bits of v1.
  __ shufpd(v0, v1, Immediate(0x0));
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out(0).fpu_reg();
  __ cvtpd2ps(value, value);
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out(0).fpu_reg();
  __ cvtps2pd(value, value);
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (representation() == kTagged) {
    ASSERT(op_kind() == MethodRecognizer::kFloat64x2GetSignMask);
    summary->set_out(0, Location::RequiresRegister());
  } else {
    ASSERT(representation() == kUnboxedFloat64x2);
    summary->set_out(0, Location::SameAsFirstInput());
  }
  return summary;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();

  ASSERT((op_kind() == MethodRecognizer::kFloat64x2GetSignMask) ||
         (locs()->out(0).fpu_reg() == left));

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Negate:
      __ negatepd(left);
      break;
    case MethodRecognizer::kFloat64x2Abs:
      __ abspd(left);
      break;
    case MethodRecognizer::kFloat64x2Sqrt:
      __ sqrtpd(left);
      break;
    case MethodRecognizer::kFloat64x2GetSignMask:
      __ movmskpd(locs()->out(0).reg(), left);
      __ SmiTag(locs()->out(0).reg());
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
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();
  ASSERT((locs()->out(0).fpu_reg() == left));

  switch (op_kind()) {
    case MethodRecognizer::kFloat64x2Scale:
      __ shufpd(right, right, Immediate(0x00));
      __ mulpd(left, right);
      break;
    case MethodRecognizer::kFloat64x2WithX:
      __ subq(RSP, Immediate(16));
      // Move value to stack.
      __ movups(Address(RSP, 0), left);
      // Write over X value.
      __ movsd(Address(RSP, 0), right);
      // Move updated value into output register.
      __ movups(left, Address(RSP, 0));
      __ addq(RSP, Immediate(16));
      break;
    case MethodRecognizer::kFloat64x2WithY:
      __ subq(RSP, Immediate(16));
      // Move value to stack.
      __ movups(Address(RSP, 0), left);
      // Write over Y value.
      __ movsd(Address(RSP, 8), right);
      // Move updated value into output register.
      __ movups(left, Address(RSP, 0));
      __ addq(RSP, Immediate(16));
      break;
    case MethodRecognizer::kFloat64x2Min:
      __ minpd(left, right);
      break;
    case MethodRecognizer::kFloat64x2Max:
      __ maxpd(left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Int32x4ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register v0 = locs()->in(0).reg();
  Register v1 = locs()->in(1).reg();
  Register v2 = locs()->in(2).reg();
  Register v3 = locs()->in(3).reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  __ AddImmediate(RSP, Immediate(-4 * kInt32Size), PP);
  __ movl(Address(RSP, 0 * kInt32Size), v0);
  __ movl(Address(RSP, 1 * kInt32Size), v1);
  __ movl(Address(RSP, 2 * kInt32Size), v2);
  __ movl(Address(RSP, 3 * kInt32Size), v3);
  __ movups(result, Address(RSP, 0));
  __ AddImmediate(RSP, Immediate(4 * kInt32Size), PP);
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
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register v0 = locs()->in(0).reg();
  Register v1 = locs()->in(1).reg();
  Register v2 = locs()->in(2).reg();
  Register v3 = locs()->in(3).reg();
  Register temp = locs()->temp(0).reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  Label x_false, x_done;
  Label y_false, y_done;
  Label z_false, z_done;
  Label w_false, w_done;
  __ AddImmediate(RSP, Immediate(-16), PP);

  __ CompareObject(v0, Bool::True(), PP);
  __ j(NOT_EQUAL, &x_false);
  __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
  __ jmp(&x_done);
  __ Bind(&x_false);
  __ LoadImmediate(temp, Immediate(0x0), PP);
  __ Bind(&x_done);
  __ movl(Address(RSP, 0), temp);

  __ CompareObject(v1, Bool::True(), PP);
  __ j(NOT_EQUAL, &y_false);
  __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
  __ jmp(&y_done);
  __ Bind(&y_false);
  __ LoadImmediate(temp, Immediate(0x0), PP);
  __ Bind(&y_done);
  __ movl(Address(RSP, 4), temp);

  __ CompareObject(v2, Bool::True(), PP);
  __ j(NOT_EQUAL, &z_false);
  __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
  __ jmp(&z_done);
  __ Bind(&z_false);
  __ LoadImmediate(temp, Immediate(0x0), PP);
  __ Bind(&z_done);
  __ movl(Address(RSP, 8), temp);

  __ CompareObject(v3, Bool::True(), PP);
  __ j(NOT_EQUAL, &w_false);
  __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
  __ jmp(&w_done);
  __ Bind(&w_false);
  __ LoadImmediate(temp, Immediate(0x0), PP);
  __ Bind(&w_done);
  __ movl(Address(RSP, 12), temp);

  __ movups(result, Address(RSP, 0));
  __ AddImmediate(RSP, Immediate(16), PP);
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  Register result = locs()->out(0).reg();
  Label done;
  Label non_zero;
  __ AddImmediate(RSP, Immediate(-16), PP);
  // Move value to stack.
  __ movups(Address(RSP, 0), value);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4GetFlagX:
      __ movl(result, Address(RSP, 0));
      break;
    case MethodRecognizer::kInt32x4GetFlagY:
      __ movl(result, Address(RSP, 4));
      break;
    case MethodRecognizer::kInt32x4GetFlagZ:
      __ movl(result, Address(RSP, 8));
      break;
    case MethodRecognizer::kInt32x4GetFlagW:
      __ movl(result, Address(RSP, 12));
      break;
    default: UNREACHABLE();
  }
  __ AddImmediate(RSP, Immediate(16), PP);
  __ testl(result, result);
  __ j(NOT_ZERO, &non_zero, Assembler::kNearJump);
  __ LoadObject(result, Bool::False(), PP);
  __ jmp(&done);
  __ Bind(&non_zero);
  __ LoadObject(result, Bool::True(), PP);
  __ Bind(&done);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister mask = locs()->in(0).fpu_reg();
  XmmRegister trueValue = locs()->in(1).fpu_reg();
  XmmRegister falseValue = locs()->in(2).fpu_reg();
  XmmRegister out = locs()->out(0).fpu_reg();
  XmmRegister temp = locs()->temp(0).fpu_reg();
  ASSERT(out == mask);
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


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister mask = locs()->in(0).fpu_reg();
  Register flag = locs()->in(1).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(mask == locs()->out(0).fpu_reg());
  __ AddImmediate(RSP, Immediate(-16), PP);
  // Copy mask to stack.
  __ movups(Address(RSP, 0), mask);
  Label falsePath, exitPath;
  __ CompareObject(flag, Bool::True(), PP);
  __ j(NOT_EQUAL, &falsePath);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4WithFlagX:
      __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
      __ movl(Address(RSP, 0), temp);
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ LoadImmediate(temp, Immediate(0x0), PP);
      __ movl(Address(RSP, 0), temp);
    break;
    case MethodRecognizer::kInt32x4WithFlagY:
      __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
      __ movl(Address(RSP, 4), temp);
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ LoadImmediate(temp, Immediate(0x0), PP);
      __ movl(Address(RSP, 4), temp);
    break;
    case MethodRecognizer::kInt32x4WithFlagZ:
      __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
      __ movl(Address(RSP, 8), temp);
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ LoadImmediate(temp, Immediate(0x0), PP);
      __ movl(Address(RSP, 8), temp);
    break;
    case MethodRecognizer::kInt32x4WithFlagW:
      __ LoadImmediate(temp, Immediate(0xFFFFFFFF), PP);
      __ movl(Address(RSP, 12), temp);
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ LoadImmediate(temp, Immediate(0x0), PP);
      __ movl(Address(RSP, 12), temp);
    break;
    default: UNREACHABLE();
  }
  __ Bind(&exitPath);
  // Copy mask back to register.
  __ movups(mask, Address(RSP, 0));
  __ AddImmediate(RSP, Immediate(16), PP);
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // NOP.
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Isolate* isolate,
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


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();
  ASSERT(left == locs()->out(0).fpu_reg());
  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ andps(left, right);
      break;
    }
    case Token::kBIT_OR: {
      __ orps(left, right);
      break;
    }
    case Token::kBIT_XOR: {
      __ xorps(left, right);
      break;
    }
    case Token::kADD:
      __ addpl(left, right);
      break;
    case Token::kSUB:
      __ subpl(left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  if ((kind() == MathUnaryInstr::kSin) || (kind() == MathUnaryInstr::kCos)) {
    // Calling convention on x64 uses XMM0 and XMM1 to pass the first two
    // double arguments and XMM0 to return the result. Unfortunately
    // currently we can't specify these registers because ParallelMoveResolver
    // assumes that XMM0 is free at all times.
    // TODO(vegorov): allow XMM0 to be used.
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, InputCount(), kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(XMM1));
    // R13 is chosen because it is callee saved so we do not need to back it
    // up before calling into the runtime.
    summary->set_temp(0, Location::RegisterLocation(R13));
    summary->set_out(0, Location::FpuRegisterLocation(XMM1));
    return summary;
  }
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    ASSERT((kind() == MathUnaryInstr::kSin) ||
           (kind() == MathUnaryInstr::kCos));
    // Save RSP.
    __ movq(locs()->temp(0).reg(), RSP);
    __ ReserveAlignedFrameSpace(0);
    __ movaps(XMM0, locs()->in(0).fpu_reg());
    __ CallRuntime(TargetFunction(), InputCount());
    __ movaps(locs()->out(0).fpu_reg(), XMM0);
    // Restore RSP.
    __ movq(RSP, locs()->temp(0).reg());
  }
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out(0).reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ negq(value);
      __ j(OVERFLOW, deopt);
      if (FLAG_throw_on_javascript_int_overflow) {
        EmitJavascriptOverflowCheck(compiler, range(), deopt, value);
      }
      break;
    }
    case Token::kBIT_NOT:
      __ notq(value);
      // Remove inverted smi-tag.
      __ AndImmediate(value, Immediate(~kSmiTagMask), PP);
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(locs()->out(0).fpu_reg() == value);
  __ DoubleNegate(value);
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
    XmmRegister left = locs()->in(0).fpu_reg();
    XmmRegister right = locs()->in(1).fpu_reg();
    XmmRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ comisd(left, right);
    __ j(PARITY_EVEN, &returns_nan, Assembler::kNearJump);
    __ j(EQUAL, &are_equal, Assembler::kNearJump);
    const Condition double_condition =
        is_min ? TokenKindToDoubleCondition(Token::kLT)
               : TokenKindToDoubleCondition(Token::kGT);
    ASSERT(left == result);
    __ j(double_condition, &done, Assembler::kNearJump);
    __ movsd(result, right);
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&returns_nan);
    static double kNaN = NAN;
    __ LoadImmediate(temp, Immediate(reinterpret_cast<intptr_t>(&kNaN)), PP);
    __ movsd(result, Address(temp, 0));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&are_equal);
    Label left_is_negative;
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ movmskpd(temp, left);
    __ testq(temp, Immediate(1));
    if (is_min) {
      ASSERT(left == result);
      __ j(NOT_ZERO, &done, Assembler::kNearJump);  // Negative -> return left.
    } else {
      ASSERT(left == result);
      __ j(ZERO, &done, Assembler::kNearJump);  // Positive -> return left.
    }
    __ movsd(result, right);
    __ Bind(&done);
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  __ cmpq(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgeq(result, right);
  } else {
    __ cmovlessq(result, right);
  }
}


DEFINE_UNIMPLEMENTED_INSTRUCTION(Int32ToDoubleInstr)


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* MintToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MintToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(RCX));
  result->set_out(0, Location::RegisterLocation(RAX));
  result->set_temp(0, Location::RegisterLocation(RBX));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value_obj = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  XmmRegister value_double = XMM0;
  ASSERT(result == RAX);
  ASSERT(result != value_obj);
  ASSERT(result != temp);
  __ movsd(value_double, FieldAddress(value_obj, Double::value_offset()));
  __ cvttsd2siq(result, value_double);
  // Overflow is signalled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ shlq(temp, Immediate(1));
  __ j(OVERFLOW, &do_call, Assembler::kNearJump);
  __ SmiTag(result);
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptOverflowCheck(compiler, range(), &do_call, result);
  }
  __ jmp(&done);
  __ Bind(&do_call);
  ASSERT(instance_call()->HasICData());
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT((ic_data.NumberOfChecks() == 1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));

  const intptr_t kNumberOfArguments = 1;
  __ pushq(value_obj);
  compiler->GenerateStaticCall(deopt_id(),
                               instance_call()->token_pos(),
                               target,
                               kNumberOfArguments,
                               Object::null_array(),  // No argument names.
                               locs(),
                               ICData::Handle());
  __ Bind(&done);
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  result->set_temp(0, Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  Register result = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  Register temp = locs()->temp(0).reg();

  __ cvttsd2siq(result, value);
  // Overflow is signalled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ movq(temp, result);
  __ shlq(temp, Immediate(1));
  __ j(OVERFLOW, deopt);
  __ SmiTag(result);
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptOverflowCheck(compiler, range(), deopt, result);
  }
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleTruncate:
      __ roundsd(result, value,  Assembler::kRoundToZero);
      break;
    case MethodRecognizer::kDoubleFloor:
      __ roundsd(result, value,  Assembler::kRoundDown);
      break;
    case MethodRecognizer::kDoubleCeil:
      __ roundsd(result, value,  Assembler::kRoundUp);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtsd2ss(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtss2sd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  // Calling convention on x64 uses XMM0 and XMM1 to pass the first two
  // double arguments and XMM0 to return the result. Unfortunately
  // currently we can't specify these registers because ParallelMoveResolver
  // assumes that XMM0 is free at all times.
  // TODO(vegorov): allow XMM0 to be used.
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 3 : 1;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_temp(0, Location::RegisterLocation(R13));
  result->set_in(0, Location::FpuRegisterLocation(XMM2));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM1));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Temp index 1.
    result->set_temp(1, Location::RegisterLocation(RAX));
    // Temp index 2.
    result->set_temp(2, Location::FpuRegisterLocation(XMM4));
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
  Register temp =
      locs->temp(InvokeMathCFunctionInstr::kObjectTempIndex).reg();
  XmmRegister zero_temp =
      locs->temp(InvokeMathCFunctionInstr::kDoubleTempIndex).fpu_reg();

  __ xorps(zero_temp, zero_temp);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1)), PP);
  __ movsd(result, FieldAddress(temp, Double::value_offset()));

  Label check_base, skip_call;
  // exponent == 0.0 -> return 1.0;
  __ comisd(exp, zero_temp);
  __ j(PARITY_EVEN, &check_base, Assembler::kNearJump);
  __ j(EQUAL, &skip_call);  // 'result' is 1.0.

  // exponent == 1.0 ?
  __ comisd(exp, result);
  Label return_base;
  __ j(EQUAL, &return_base, Assembler::kNearJump);

  // exponent == 2.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(2.0)), PP);
  __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  Label return_base_times_2;
  __ j(EQUAL, &return_base_times_2, Assembler::kNearJump);

  // exponent == 3.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(3.0)), PP);
  __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
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

  Label return_nan;
  // base == 1.0 -> return 1.0;
  __ comisd(base, result);
  __ j(PARITY_EVEN, &return_nan, Assembler::kNearJump);
  __ j(EQUAL, &skip_call, Assembler::kNearJump);
  // Note: 'base' could be NaN.
  __ comisd(exp, base);
  // Neither 'exp' nor 'base' is NaN.
  Label try_sqrt;
  __ j(PARITY_ODD, &try_sqrt, Assembler::kNearJump);
  // Return NaN.
  __ Bind(&return_nan);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(NAN)), PP);
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  __ jmp(&skip_call);

  Label do_pow, return_zero;
  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadObject(temp,
      Double::ZoneHandle(Double::NewCanonical(kNegInfinity)), PP);
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  // base == -Infinity -> call pow;
  __ comisd(base, result);
  __ j(EQUAL, &do_pow, Assembler::kNearJump);

  // exponent == 0.5 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0.5)), PP);
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, result);
  __ j(NOT_EQUAL, &do_pow, Assembler::kNearJump);

  // base == 0 -> return 0;
  __ comisd(base, zero_temp);
  __ j(EQUAL, &return_zero, Assembler::kNearJump);

  __ sqrtsd(result, base);
  __ jmp(&skip_call, Assembler::kNearJump);

  __ Bind(&return_zero);
  __ movsd(result, zero_temp);
  __ jmp(&skip_call);

  __ Bind(&do_pow);

  // Save RSP.
  __ movq(locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg(), RSP);
  __ ReserveAlignedFrameSpace(0);
  __ movaps(XMM0, locs->in(0).fpu_reg());
  ASSERT(locs->in(1).fpu_reg() == XMM1);

  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ movaps(locs->out(0).fpu_reg(), XMM0);
  // Restore RSP.
  __ movq(RSP, locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg());
  __ Bind(&skip_call);
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  // Save RSP.
  __ movq(locs()->temp(kSavedSpTempIndex).reg(), RSP);
  __ ReserveAlignedFrameSpace(0);
  __ movaps(XMM0, locs()->in(0).fpu_reg());
  if (InputCount() == 2) {
    ASSERT(locs()->in(1).fpu_reg() == XMM1);
  }

  __ CallRuntime(TargetFunction(), InputCount());
  __ movaps(locs()->out(0).fpu_reg(), XMM0);
  // Restore RSP.
  __ movq(RSP, locs()->temp(kSavedSpTempIndex).reg());
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


LocationSummary* MergedMathInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(RAX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::Pair(Location::RegisterLocation(RAX),
                                       Location::RegisterLocation(RDX)));
    return summary;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    // Because we always call into the runtime (LocationSummary::kCall) we
    // must specify each input, temp, and output register explicitly.
    summary->set_in(0, Location::FpuRegisterLocation(XMM1));
    // R13 is chosen because it is callee saved so we do not need to back it
    // up before calling into the runtime.
    summary->set_temp(0, Location::RegisterLocation(R13));
    summary->set_out(0, Location::Pair(Location::FpuRegisterLocation(XMM2),
                                       Location::FpuRegisterLocation(XMM3)));
    return summary;
  }
  UNIMPLEMENTED();
  return NULL;
}



typedef void (*SinCosCFunction) (double x, double* res_sin, double* res_cos);

extern const RuntimeEntry kSinCosRuntimeEntry(
    "libc_sincos", reinterpret_cast<RuntimeFunction>(
        static_cast<SinCosCFunction>(&SinCos)), 1, true, true);


void MergedMathInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt  = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }
  if (kind() == MergedMathInstr::kTruncDivMod) {
    Register left = locs()->in(0).reg();
    Register right = locs()->in(1).reg();
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* pair = locs()->out(0).AsPairLocation();
    Register result1 = pair->At(0).reg();
    Register result2 = pair->At(1).reg();
    Label not_32bit, done;
    Register temp = RDX;
    ASSERT(left == RAX);
    ASSERT((right != RDX) && (right != RAX));
    ASSERT(result1 == RAX);
    ASSERT(result2 == RDX);
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
      // Handle divide by zero in runtime.
      __ testq(right, right);
      __ j(ZERO, deopt);
    }
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
    __ cqo();  // Sign extend RAX -> RDX:RAX.
    __ idivq(right);  //  RAX: quotient, RDX: remainder.
    // Check the corner case of dividing the 'MIN_SMI' with -1, in which
    // case we cannot tag the result.
    __ CompareImmediate(RAX, Immediate(0x4000000000000000), PP);
    __ j(EQUAL, deopt);
    __ Bind(&done);

    // Modulo correction (RDX).
    //  res = left % right;
    //  if (res < 0) {
    //    if (right < 0) {
    //      res = res - right;
    //    } else {
    //      res = res + right;
    //    }
    //  }
    Label all_done;
    __ cmpq(RDX, Immediate(0));
    __ j(GREATER_EQUAL, &all_done, Assembler::kNearJump);
    // Result is negative, adjust it.
    if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
      Label subtract;
      __ cmpq(right, Immediate(0));
      __ j(LESS, &subtract, Assembler::kNearJump);
      __ addq(RDX, right);
      __ jmp(&all_done, Assembler::kNearJump);
      __ Bind(&subtract);
      __ subq(RDX, right);
    } else if (right_range->IsPositive()) {
      // Right is positive.
      __ addq(RDX, right);
    } else {
      // Right is negative.
      __ subq(RDX, right);
    }
    __ Bind(&all_done);

    __ SmiTag(RAX);
    __ SmiTag(RDX);
    // FLAG_throw_on_javascript_int_overflow: not needed.
    // Note that the result of an integer division/modulo of two
    // in-range arguments, cannot create out-of-range result.
    return;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* pair = locs()->out(0).AsPairLocation();
    XmmRegister out1 = pair->At(0).fpu_reg();
    XmmRegister out2 = pair->At(1).fpu_reg();

    // Save RSP.
    __ movq(locs()->temp(0).reg(), RSP);
    // +-------------------------------+
    // | double-argument               |  <- TOS
    // +-------------------------------+
    // | address-cos-result            |  +8
    // +-------------------------------+
    // | address-sin-result            |  +16
    // +-------------------------------+
    // | double-storage-for-cos-result |  +24
    // +-------------------------------+
    // | double-storage-for-sin-result |  +32
    // +-------------------------------+
    // ....
    __ ReserveAlignedFrameSpace(kDoubleSize * 3 + kWordSize * 2);
    __ movsd(Address(RSP, 0), locs()->in(0).fpu_reg());

    __ leaq(RDI, Address(RSP, 2 * kWordSize + kDoubleSize));
    __ leaq(RSI, Address(RSP, 2 * kWordSize + 2 * kDoubleSize));
    __ movaps(XMM0, locs()->in(0).fpu_reg());

    __ CallRuntime(kSinCosRuntimeEntry, InputCount());
    __ movsd(out2, Address(RSP, 2 * kWordSize + kDoubleSize * 2));  // sin.
    __ movsd(out1, Address(RSP, 2 * kWordSize + kDoubleSize));  // cos.
    // Restore RSP.
    __ movq(RSP, locs()->temp(0).reg());

    return;
  }
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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

  // Load receiver into RAX.
  __ movq(RAX,
      Address(RSP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  Label* deopt = compiler->AddDeoptStub(
      deopt_id(), ICData::kDeoptPolymorphicInstanceCallTestFail);
  LoadValueCid(compiler, RDI, RAX,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            RDI,  // Class id register.
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
  const bool need_mask_temp = IsDenseSwitch() && !IsDenseMask(ComputeCidMask());
  const intptr_t kNumTemps = !IsNullCheck() ? (need_mask_temp ? 2 : 1) : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  const ICData::DeoptReasonId deopt_reason = licm_hoisted_ ?
      ICData::kDeoptHoistedCheckClass : ICData::kDeoptCheckClass;
  if (IsNullCheck()) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
    __ CompareObject(locs()->in(0).reg(),
                     Object::null_object(), PP);
    __ j(EQUAL, deopt);
    return;
  }

  ASSERT((unary_checks().GetReceiverClassIdAt(0) != kSmiCid) ||
         (unary_checks().NumberOfChecks() > 1));
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
  Label is_ok;
  intptr_t cix = 0;
  if (unary_checks().GetReceiverClassIdAt(cix) == kSmiCid) {
    __ testq(value, Immediate(kSmiTagMask));
    __ j(ZERO, &is_ok);
    cix++;  // Skip first check.
  } else {
    __ testq(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
  }
  __ LoadClassId(temp, value);

  if (IsDenseSwitch()) {
    ASSERT(cids_[0] < cids_[cids_.length() - 1]);
    __ subq(temp, Immediate(cids_[0]));
    __ cmpq(temp, Immediate(cids_[cids_.length() - 1] - cids_[0]));
    __ j(ABOVE, deopt);

    intptr_t mask = ComputeCidMask();
    if (!IsDenseMask(mask)) {
      // Only need mask if there are missing numbers in the range.
      ASSERT(cids_.length() > 2);
      Register mask_reg = locs()->temp(1).reg();
      __ movq(mask_reg, Immediate(mask));
      __ btq(mask_reg, temp);
      __ j(NOT_CARRY, deopt);
    }
  } else {
    const intptr_t num_checks = unary_checks().NumberOfChecks();
    const bool use_near_jump = num_checks < 5;
    for (intptr_t i = cix; i < num_checks; i++) {
      ASSERT(unary_checks().GetReceiverClassIdAt(i) != kSmiCid);
      __ cmpl(temp, Immediate(unary_checks().GetReceiverClassIdAt(i)));
      if (i == (num_checks - 1)) {
        __ j(NOT_EQUAL, deopt);
      } else {
        if (use_near_jump) {
          __ j(EQUAL, &is_ok, Assembler::kNearJump);
        } else {
          __ j(EQUAL, &is_ok);
        }
      }
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
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi);
  __ testq(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);
}


LocationSummary* CheckClassIdInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  __ CompareImmediate(value, Immediate(Smi::RawValue(cid_)), PP);
  __ j(NOT_ZERO, deopt);
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
    __ jmp(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(
        length, Immediate(reinterpret_cast<int64_t>(index.raw())), PP);
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    __ CompareImmediate(
        index, Immediate(reinterpret_cast<int64_t>(length.raw())), PP);
    __ j(ABOVE_EQUAL, deopt);
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    __ cmpq(index, length);
    __ j(ABOVE_EQUAL, deopt);
  }
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


bool ShiftMintOpInstr::has_shift_count_check() const {
  UNREACHABLE();
  return false;
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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


LocationSummary* UnboxIntNInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = (!is_truncating() && CanDeoptimize()) ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  if (kNumTemps > 0) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}


void UnboxIntNInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  Label* deopt = CanDeoptimize() ?
      compiler->AddDeoptStub(deopt_id_, ICData::kDeoptUnboxInteger) : NULL;
  ASSERT(value == locs()->out(0).reg());

  if (value_cid == kSmiCid) {
    __ SmiUntag(value);
  } else if (value_cid == kMintCid) {
    __ movq(value, FieldAddress(value, Mint::value_offset()));
  } else {
    Label done;
    // Optimistically untag value.
    __ SmiUntagOrCheckClass(value, kMintCid, &done);
    __ j(NOT_EQUAL, deopt);
    // Undo untagging by multiplying value with 2.
    __ movq(value, Address(value, TIMES_2, Mint::value_offset()));
    __ Bind(&done);
  }

  // TODO(vegorov): as it is implemented right now truncating unboxing would
  // leave "garbage" in the higher word.
  if (!is_truncating() && (deopt != NULL)) {
    ASSERT(representation() == kUnboxedInt32);
    Register temp = locs()->temp(0).reg();
    __ movsxd(temp, value);
    __ cmpq(temp, value);
    __ j(NOT_EQUAL, deopt);
  }
}


LocationSummary* BoxIntNInstr::MakeLocationSummary(Isolate* isolate,
                                                   bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate,
      kNumInputs,
      kNumTemps,
      LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxIntNInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(value != out);

  ASSERT(kSmiTagSize == 1);
  if (from_representation() == kUnboxedInt32) {
    __ movsxd(out, value);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ movl(out, value);
  }
  __ SmiTag(out);
}


LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUnboxedMint) {
    UNREACHABLE();
  } else if (to() == kUnboxedMint) {
    UNREACHABLE();
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
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ testl(out, out);
      __ j(NEGATIVE, deopt);
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
  __ int3();
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
  __ int3();
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ jmp(compiler->GetJumpLabel(normal_entry()));
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
    // may be inserted before this instruction.  This descriptor points
    // after the edge counter for uniformity with ARM and MIPS, where we can
    // reuse pattern matching that matches backwards from the end of the
    // pattern.
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
    __ jmp(compiler->GetJumpLabel(successor()));
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
  __ MoveRegister(locs()->out(0).reg(), CTX);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(RAX));
    locs->set_in(1, Location::RegisterLocation(RCX));
    locs->set_out(0, Location::RegisterLocation(RAX));
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

  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQUAL : NOT_EQUAL;
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };

  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False(), PP);
  __ jmp(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True(), PP);
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(RAX));  // Function.
  summary->set_out(0, Location::RegisterLocation(RAX));
  return summary;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Arguments descriptor is expected in R10.
  intptr_t argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  __ LoadObject(R10, arguments_descriptor, PP);

  // Function in RAX.
  ASSERT(locs()->in(0).reg() == RAX);
  __ movq(RCX, FieldAddress(RAX, Function::instructions_offset()));

  // RAX: Function.
  // R10: Arguments descriptor array.
  // RBX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ xorq(RBX, RBX);
  __ addq(RCX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ call(RCX);
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


LocationSummary* BooleanNegateInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  return LocationSummary::Make(isolate,
                               1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  Label done;
  __ LoadObject(result, Bool::True(), PP);
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, Bool::False(), PP);
  __ Bind(&done);
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
  compiler->GenerateCall(token_pos(), &label, stub_kind_, locs());
#if defined(DEBUG)
  __ movq(R10, Immediate(kInvalidObjectPointer));
  __ movq(RBX, Immediate(kInvalidObjectPointer));
#endif
}

}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
