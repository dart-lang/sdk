// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

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
DECLARE_FLAG(bool, use_osr);
DECLARE_FLAG(bool, throw_on_javascript_int_overflow);
DECLARE_FLAG(bool, use_slow_path);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
LocationSummary* Instruction::MakeCallSummary() {
  Isolate* isolate = Isolate::Current();
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(EAX));
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
      __ pushl(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      __ pushl(value.ToStackSlotAddress());
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Isolate* isolate,
                                                  bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == EAX);
#if defined(DEBUG)
  __ Comment("Stack Check");
  Label done;
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ movl(EDI, ESP);
  __ subl(EDI, EBP);
  __ cmpl(EDI, Immediate(fp_sp_dist));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ int3();
  __ Bind(&done);
#endif
  __ LeaveFrame();
  __ ret();
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
  __ movl(Address(EBP, local().index() * kWordSize), value);
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
    __ LoadObjectSafely(result, value());
  }
}


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = (constant_address() == 0) ? 1 : 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_out(0, Location::RequiresFpuRegister());
  if (kNumTemps == 1) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
     XmmRegister result = locs()->out(0).fpu_reg();
    if (constant_address() == 0) {
      Register boxed = locs()->temp(0).reg();
      __ LoadObjectSafely(boxed, value());
      __ movsd(result, FieldAddress(boxed, Double::value_offset()));
    } else if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0)) {
      __ xorps(result, result);
    } else {
      __ movsd(result, Address::Absolute(constant_address()));
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));  // Value.
  summary->set_in(1, Location::RegisterLocation(ECX));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(EDX));  // Type arguments.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
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
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ CompareObject(reg, Bool::False());
  __ j(EQUAL, &done, Assembler::kNearJump);

  __ pushl(reg);  // Push the source object.
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
    __ movl(value_cid_reg, Immediate(kSmiCid));
  }
  __ testl(value_reg, Immediate(kSmiTagMask));
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
    __ CompareObject(right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant());
  } else if (right.IsStackSlot()) {
    __ cmpl(left.reg(), right.ToStackSlotAddress());
  } else {
    __ cmpl(left.reg(), right.reg());
  }
  return true_condition;
}


static void EmitJavascriptIntOverflowCheck(FlowGraphCompiler* compiler,
                                           Label* overflow,
                                           Register result_lo,
                                           Register result_hi) {
  // Compare upper half.
  Label check_lower;
  __ cmpl(result_hi, Immediate(0x00200000));
  __ j(GREATER, overflow);
  __ j(NOT_EQUAL, &check_lower);

  __ cmpl(result_lo, Immediate(0));
  __ j(ABOVE, overflow);

  __ Bind(&check_lower);
  __ cmpl(result_hi, Immediate(-0x00200000));
  __ j(LESS, overflow);
  // Anything in the lower part would make the number bigger than the lower
  // bound, so we are done.
}


static Condition TokenKindToMintCondition(Token::Kind kind) {
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
  Label done;
  // Compare lower.
  __ cmpl(left1, right1);
  __ j(NOT_EQUAL, &done);
  // Lower is equal, compare upper.
  __ cmpl(left2, right2);
  __ Bind(&done);
  Condition true_condition = TokenKindToMintCondition(kind);
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
  Label is_true, is_false;
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
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler,  true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
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
  Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int32_t imm =
        reinterpret_cast<int32_t>(right.constant().raw());
    __ testl(left, Immediate(imm));
  } else {
    __ testl(left, right.reg());
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
  __ testl(val_reg, Immediate(kSmiTagMask));
  __ j(ZERO, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ cmpl(cid_reg,  Immediate(test_cid));
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
  __ LoadObject(result_reg, Bool::False());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True());
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
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
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), labels);
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
  __ LoadObject(result, Bool::False());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
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
  locs->set_temp(0, Location::RegisterLocation(EAX));
  locs->set_temp(1, Location::RegisterLocation(ECX));
  locs->set_temp(2, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EAX);
  ASSERT(locs()->temp(1).reg() == ECX);
  ASSERT(locs()->temp(2).reg() == EDX);
  Register result = locs()->out(0).reg();
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const bool is_leaf_call =
      (argc_tag & NativeArguments::AutoSetupScopeMask()) == 0;
  StubCode* stub_code = compiler->isolate()->stub_code();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());
  // Pass a pointer to the first argument in EAX.
  if (!function().HasOptionalParameters()) {
    __ leal(EAX, Address(EBP, (kParamEndSlotFromFp +
                               function().NumParameters()) * kWordSize));
  } else {
    __ leal(EAX, Address(EBP, kFirstLocalSlotFromFp * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movl(EDX, Immediate(argc_tag));
  const ExternalLabel* stub_entry = (is_bootstrap_native() || is_leaf_call) ?
      &stub_code->CallBootstrapCFunctionLabel() :
      &stub_code->CallNativeCFunctionLabel();
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  __ popl(result);
}


static bool CanBeImmediateIndex(Value* value, intptr_t cid) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == NULL) || !Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const intptr_t offset = Instance::DataOffsetFor(cid);
  const int64_t displacement = index * scale + offset;
  return Utils::IsInt(32, displacement);
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
  __ movl(result,
          Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(result, Address(result,
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
  __ movl(result, FieldAddress(str, String::length_offset()));
  __ cmpl(result, Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, Assembler::kNearJump);
  __ movl(result, Immediate(Smi::RawValue(-1)));
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
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ pushl(array);
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               CallFunction(),
                               kNumberOfArguments,
                               kNoArgumentNames,
                               locs(),
                               ICData::Handle());
  ASSERT(locs()->out(0).reg() == EAX);
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
  __ movl(result, FieldAddress(object, offset()));
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
  Label done;

  // We don't use Assembler::LoadTaggedClassIdMayBeSmi() here---which uses
  // a conditional move instead, and requires an additional register---because
  // it is slower, probably due to branch prediction usually working just fine
  // in this case.
  ASSERT(result != object);
  __ movl(result, Immediate(kSmiCid << 1));
  __ testl(object, Immediate(kSmiTagMask));
  __ j(EQUAL, &done, Assembler::kNearJump);
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
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return Typed32BitIsSmi() ? CompileType::FromCid(kSmiCid)
                               : CompileType::FromCid(kMintCid);

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
      return kTagged;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return Typed32BitIsSmi() ? kTagged : kUnboxedMint;
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


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->BoundConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1)
                        ? Location::WritableRegister()
                        : Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedMint) {
    if (class_id() == kTypedDataInt32ArrayCid) {
      locs->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                      Location::RegisterLocation(EDX)));
    } else {
      ASSERT(class_id() == kTypedDataUint32ArrayCid);
      locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    }
  } else {
    ASSERT(representation() == kTagged);
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

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    XmmRegister result = locs()->out(0).fpu_reg();
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }
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

  if (representation() == kUnboxedMint) {
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* result_pair = locs()->out(0).AsPairLocation();
    Register result1 = result_pair->At(0).reg();
    Register result2 = result_pair->At(1).reg();
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        ASSERT(result1 == EAX);
        ASSERT(result2 == EDX);
        __ movl(result1, element_address);
        __ cdq();
        break;
      case kTypedDataUint32ArrayCid:
        __ movl(result1, element_address);
        __ xorl(result2, result2);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  ASSERT(representation() == kTagged);

  Register result = locs()->out(0).reg();
  if ((index_scale() == 1) && index.IsRegister()) {
    __ SmiUntag(index.reg());
  }
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      __ movsxb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
      ASSERT(index_scale() == 1);
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
    case kTypedDataInt32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptInt32Load);
        __ movl(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ cmpl(result, Immediate(0xC0000000));
        __ j(NEGATIVE, deopt);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptUint32Load);
        __ movl(result, element_address);
        // Verify that the unsigned value in 'result' can fit inside a Smi.
        __ testl(result, Immediate(0xC0000000));
        __ j(NOT_ZERO, deopt);
        __ SmiTag(result);
      }
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ movl(result, element_address);
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
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->BoundConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1)
                        ? Location::WritableRegister()
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
      // TODO(fschneider): Add location constraint for byte registers (EAX,
      // EBX, ECX, EDX) instead of using a fixed register.
      locs->set_in(2, Location::FixedRegisterOrSmiConstant(value(), EAX));
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Writable register because the value must be untagged before storing.
      locs->set_in(2, Location::WritableRegister());
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // For smis, use a writable register because the value must be untagged
      // before storing. Mints are stored in registers pairs.
      if (value()->IsSmiValue()) {
        locs->set_in(2, Location::WritableRegister());
      } else {
        // We only move the lower 32-bits so we don't care where the high bits
        // are located.
        locs->set_in(2, Location::Pair(Location::RequiresRegister(),
                                       Location::Any()));
      }
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
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ movb(element_address,
                Immediate(static_cast<int8_t>(constant.Value())));
      } else {
        ASSERT(locs()->in(2).reg() == EAX);
        __ SmiUntag(EAX);
        __ movb(element_address, AL);
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
        ASSERT(locs()->in(2).reg() == EAX);
        Label store_value, store_0xff;
        __ SmiUntag(EAX);
        __ cmpl(EAX, Immediate(0xFF));
        __ j(BELOW_EQUAL, &store_value, Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorl(EAX, EAX);
        __ jmp(&store_value, Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ movl(EAX, Immediate(0xFF));
        __ Bind(&store_value);
        __ movb(element_address, AL);
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
    case kTypedDataUint32ArrayCid:
      if (value()->IsSmiValue()) {
        ASSERT(RequiredInputRepresentation(2) == kTagged);
        Register value = locs()->in(2).reg();
        __ SmiUntag(value);
        __ movl(element_address, value);
      } else {
        ASSERT(RequiredInputRepresentation(2) == kUnboxedMint);
        PairLocation* value_pair = locs()->in(2).AsPairLocation();
        Register value1 = value_pair->At(0).reg();
        __ movl(element_address, value1);
      }
      break;
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
    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      __ cmpl(value_cid_reg, field_cid_operand);
      __ j(EQUAL, &ok);
      __ cmpl(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      // Value in graph known to be null.
      // Compare with null.
      __ cmpl(field_nullability_operand, Immediate(value_cid));
    } else {
      // Value in graph known to be non-null.
      // Compare class id with guard field class id.
      __ cmpl(field_cid_operand, Immediate(value_cid));
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
      __ cmpl(field_cid_operand, Immediate(kIllegalCid));
      // Jump to failure path when guard field has been initialized and
      // the field and value class ids do not not match.
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        // Do not know value's class id.
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

      __ pushl(field_reg);
      __ pushl(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);
    ASSERT(fail == deopt);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testl(value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ cmpl(value_cid_reg, Immediate(field_cid));
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        if (field_cid != kSmiCid) {
          __ cmpl(value_cid_reg, Immediate(kNullCid));
        } else {
          const Immediate& raw_null =
              Immediate(reinterpret_cast<intptr_t>(Object::null()));
          __ cmpl(value_reg, raw_null);
        }
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

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    __ movsxb(offset_reg, FieldAddress(field_reg,
        Field::guarded_list_length_in_object_offset_offset()));
    __ movl(length_reg, FieldAddress(field_reg,
        Field::guarded_list_length_offset()));

    __ cmpl(offset_reg, Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ cmpl(length_reg, Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == NULL) {
      __ j(EQUAL, &ok);

      __ pushl(field_reg);
      __ pushl(value_reg);
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

    __ cmpl(FieldAddress(value_reg,
                         field().guarded_list_length_in_object_offset()),
            Immediate(Smi::RawValue(field().guarded_list_length())));
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
    __ MoveRegister(result_, EAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp) {
    BoxAllocationSlowPath* slow_path =
        new BoxAllocationSlowPath(instruction, cls, result);
    compiler->AddSlowPathCode(slow_path);

    __ TryAllocate(cls,
                   slow_path->entry_label(),
                   Assembler::kFarJump,
                   result,
                   temp);
    __ Bind(slow_path->exit_label());
  }

 private:
  Instruction* instruction_;
  const Class& cls_;
  Register result_;
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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(box_reg, FieldAddress(instance_reg, offset));
  __ cmpl(box_reg, raw_null);
  __ j(NOT_EQUAL, &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ movl(temp, box_reg);
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

      BoxAllocationSlowPath::Allocate(compiler, this, *cls, temp, temp2);
      __ movl(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);
    } else {
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes_));
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
    __ Comment("PotentialUnboxedStore");
    Register value_reg = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    FpuRegister fpu_temp = locs()->temp(2).fpu_reg();

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(field().raw()));

    __ cmpl(FieldAddress(temp, Field::is_nullable_offset()),
            Immediate(kNullCid));
    __ j(EQUAL, &store_pointer);

    __ movzxb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ testl(temp2, Immediate(1 << Field::kUnboxingCandidateBit));
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
      __ StoreIntoObjectNoBarrier(
          instance_reg,
          FieldAddress(instance_reg, offset_in_bytes_),
          locs()->in(1).constant());
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
  // By specifying same register as input, our simple register allocator can
  // generate better code.
  summary->set_out(0, Location::SameAsFirstInput());
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
  __ movl(result, FieldAddress(field, Field::value_offset()));
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
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == EAX);  // Value.
  ASSERT(locs()->in(1).reg() == ECX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == EDX);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out(0).reg() == EAX);
}


// TODO(srdjan): In case of constant inputs make CreateArray kNoCall and
// use slow path stub.
LocationSummary* CreateArrayInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_in(1, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                   intptr_t num_elements,
                                   Label* slow_path,
                                   Label* done) {
  const Register kLengthReg = EDX;
  const Register kElemTypeReg = ECX;
  const intptr_t kArraySize = Array::InstanceSize(num_elements);
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  __ movl(EAX, Address::Absolute(heap->TopAddress()));
  __ movl(EBX, EAX);

  __ addl(EBX, Immediate(kArraySize));
  __ j(CARRY, slow_path);

  // Check if the allocation fits into the remaining space.
  // EAX: potential new object start.
  // EBX: potential next object start.
  __ cmpl(EBX, Address::Absolute(heap->EndAddress()));
  __ j(ABOVE_EQUAL, slow_path);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movl(Address::Absolute(heap->TopAddress()), EBX);
  __ addl(EAX, Immediate(kHeapObjectTag));
  __ UpdateAllocationStatsWithSize(kArrayCid, kArraySize, kNoRegister);

  // Initialize the tags.
  // EAX: new object start as a tagged pointer.
  {
    uword tags = 0;
    tags = RawObject::ClassIdTag::update(kArrayCid, tags);
    tags = RawObject::SizeTag::update(kArraySize, tags);
    __ movl(FieldAddress(EAX, Array::tags_offset()), Immediate(tags));
  }

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(EAX,
                              FieldAddress(EAX, Array::type_arguments_offset()),
                              kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(EAX,
                              FieldAddress(EAX, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ leal(EDI, FieldAddress(EAX, sizeof(RawArray)));
  Label init_loop;
  __ Bind(&init_loop);
  __ cmpl(EDI, EBX);
  __ j(ABOVE_EQUAL, done, Assembler::kNearJump);
  __ movl(Address(EDI, 0), raw_null);
  __ addl(EDI, Immediate(kWordSize));
  __ jmp(&init_loop, Assembler::kNearJump);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  EDX = length, ECX = element type.
  const Register kLengthReg = EDX;
  const Register kElemTypeReg = ECX;
  const Register kResultReg = EAX;
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
      __ PushObject(Object::null_object());  // Make room for the result.
      __ pushl(kLengthReg);
      __ pushl(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(),
                                    deopt_id(),
                                    kAllocateArrayRuntimeEntry,
                                    2,
                                    locs());
      __ Drop(2);
      __ popl(kResultReg);
      __ Bind(&done);
      return;
    }
  }

  __ Bind(&slow_path);
  StubCode* stub_code = compiler->isolate()->stub_code();
  compiler->GenerateCall(token_pos(),
                         &stub_code->AllocateArrayLabel(),
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
    __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
    const intptr_t cid = field()->UnboxedFieldCid();
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

    __ LoadObject(result, Field::ZoneHandle(field()->raw()));

    FieldAddress field_cid_operand(result, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result, Field::is_nullable_offset());

    __ cmpl(field_nullability_operand, Immediate(kNullCid));
    __ j(EQUAL, &load_pointer);

    __ cmpl(field_cid_operand, Immediate(kDoubleCid));
    __ j(EQUAL, &load_double);

    __ cmpl(field_cid_operand, Immediate(kFloat32x4Cid));
    __ j(EQUAL, &load_float32x4);

    __ cmpl(field_cid_operand, Immediate(kFloat64x2Cid));
    __ j(EQUAL, &load_float64x2);

    // Fall through.
    __ jmp(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->double_class(), result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movsd(value, FieldAddress(temp, Double::value_offset()));
      __ movsd(FieldAddress(result, Double::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float32x4::value_offset()));
      __ movups(FieldAddress(result, Float32x4::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float64x2::value_offset()));
      __ movups(FieldAddress(result, Float64x2::value_offset()), value);
      __ jmp(&done);
    }

    __ Bind(&load_pointer);
  }
  __ movl(result, FieldAddress(instance_reg, offset_in_bytes()));
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type());
  __ pushl(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type.
  __ popl(result_reg);  // Pop instantiated type.
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_reg == EAX);
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
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(instantiator_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Lookup cache before calling runtime.
  // TODO(fschneider): Consider moving this into a shared stub to reduce
  // generated code size.
  __ LoadObject(EDI, type_arguments());
  __ movl(EDI, FieldAddress(EDI, TypeArguments::instantiations_offset()));
  __ leal(EDI, FieldAddress(EDI, Array::data_offset()));
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, found, slow_case;
  __ Bind(&loop);
  __ movl(EDX, Address(EDI, 0 * kWordSize));  // Cached instantiator.
  __ cmpl(EDX, EAX);
  __ j(EQUAL, &found, Assembler::kNearJump);
  __ addl(EDI, Immediate(2 * kWordSize));
  __ cmpl(EDX, Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  __ jmp(&slow_case, Assembler::kNearJump);
  __ Bind(&found);
  __ movl(EAX, Address(EDI, 1 * kWordSize));  // Cached instantiated args.
  __ jmp(&type_arguments_instantiated, Assembler::kNearJump);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type_arguments());
  __ pushl(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                2,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ popl(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  if (opt) {
    const intptr_t kNumInputs = 0;
    const intptr_t kNumTemps = 2;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
    locs->set_temp(0, Location::RegisterLocation(ECX));
    locs->set_temp(1, Location::RegisterLocation(EBX));
    locs->set_out(0, Location::RegisterLocation(EAX));
    return locs;
  }
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


class AllocateContextSlowPath : public SlowPathCode {
 public:
  explicit AllocateContextSlowPath(AllocateContextInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction_->locs();
    ASSERT(!locs->live_registers()->Contains(locs->out(0)));

    compiler->SaveLiveRegisters(locs);

    __ movl(EDX, Immediate(instruction_->num_context_variables()));
    StubCode* stub_code = compiler->isolate()->stub_code();
    const ExternalLabel label(stub_code->AllocateContextEntryPoint());
    compiler->GenerateCall(instruction_->token_pos(),
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
    ASSERT(instruction_->locs()->out(0).reg() == EAX);
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ jmp(exit_label());
  }

 private:
  AllocateContextInstr* instruction_;
};



void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler->is_optimizing()) {
    Register temp0 = locs()->temp(0).reg();
    Register temp1 = locs()->temp(1).reg();
    Register result = locs()->out(0).reg();
    // Try allocate the object.
    AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
    compiler->AddSlowPathCode(slow_path);
    intptr_t instance_size = Context::InstanceSize(num_context_variables());
    __ movl(temp1, Immediate(instance_size));
    Isolate* isolate = Isolate::Current();
    Heap* heap = isolate->heap();
    __ movl(result, Address::Absolute(heap->TopAddress()));
    __ addl(temp1, result);
    // Check if the allocation fits into the remaining space.
    // EAX: potential new object.
    // EBX: potential next object start.
    __ cmpl(temp1, Address::Absolute(heap->EndAddress()));
    if (FLAG_use_slow_path) {
      __ jmp(slow_path->entry_label());
    } else {
      __ j(ABOVE_EQUAL, slow_path->entry_label());
    }

    // Successfully allocated the object, now update top to point to
    // next object start and initialize the object.
    // EAX: new object.
    // EBX: next object start.
    // EDX: number of context variables.
    __ movl(Address::Absolute(heap->TopAddress()), temp1);
    __ addl(result, Immediate(kHeapObjectTag));
    __ UpdateAllocationStatsWithSize(kContextCid, instance_size, kNoRegister);

    // Calculate the size tag and write tags.
    intptr_t size_tag = (instance_size > RawObject::SizeTag::kMaxSizeTag)
        ? 0 : instance_size << (RawObject::kSizeTagPos - kObjectAlignmentLog2);

    intptr_t tags = size_tag | RawObject::ClassIdTag::encode(kContextCid);
    __ movl(FieldAddress(result, Context::tags_offset()), Immediate(tags));

    // Setup up number of context variables field.
    // EAX: new object.
    __ movl(FieldAddress(result, Context::num_variables_offset()),
            Immediate(num_context_variables()));

    // Setup isolate field.
    __ movl(FieldAddress(result, Context::isolate_offset()),
            Immediate(reinterpret_cast<int32_t>(isolate)));

    // Setup the parent field.
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ movl(FieldAddress(result, Context::parent_offset()), raw_null);

    // Initialize the context variables.
    // EAX: new object.
    if (num_context_variables() > 0) {
      Label loop;
      __ leal(temp1, FieldAddress(result, Context::variable_offset(0)));
      __ movl(temp0, Immediate(num_context_variables()));
      __ Bind(&loop);
      __ decl(temp0);
      __ movl(Address(temp1, temp0, TIMES_4, 0), raw_null);
      __ j(NOT_ZERO, &loop, Assembler::kNearJump);
    }
    // EAX: new object.
    __ Bind(slow_path->exit_label());
    return;
  }

  ASSERT(locs()->temp(0).reg() == EDX);
  ASSERT(locs()->out(0).reg() == EAX);

  __ movl(EDX, Immediate(num_context_variables()));
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
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushl(context_value);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ popl(result);  // Remove argument.
  __ popl(result);  // Get result (cloned context).
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
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore ESP from EBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ leal(ESP, Address(EBP, fp_sp_dist));

  // Restore stack and initialize the two exception variables:
  // exception and stack trace variables.
  __ movl(Address(EBP, exception_var().index() * kWordSize),
          kExceptionObjectReg);
  __ movl(Address(EBP, stacktrace_var().index() * kWordSize),
          kStackTraceObjectReg);
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (FLAG_use_osr) {
      uword flags_address = Isolate::Current()->stack_overflow_flags_address();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ movl(Address::Absolute(flags_address),
              Immediate(Isolate::kOsrRequest));
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

  __ cmpl(ESP,
          Address::Absolute(Isolate::Current()->stack_limit_address()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(EDI, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ cmpl(FieldAddress(EDI, Function::usage_counter_offset()),
            Immediate(threshold));
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
  const bool is_truncating = shift_left->IsTruncating();
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
    // shll operation masks the count to 5 bits.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    if (value == 0) {
      // No code needed.
    } else if ((value < 0) || (value >= kCountLimit)) {
      // This condition may not be known earlier in some cases because
      // of constant propagation, inlining, etc.
      if ((value >= kCountLimit) && is_truncating) {
        __ xorl(result, result);
      } else {
        // Result is Mint or exception.
        __ jmp(deopt);
      }
    } else {
      if (!is_truncating) {
        // Check for overflow.
        Register temp = locs.temp(0).reg();
        __ movl(temp, left);
        __ shll(left, Immediate(value));
        __ sarl(left, Immediate(value));
        __ cmpl(left, temp);
        __ j(NOT_EQUAL, deopt);  // Overflow.
      }
      // Shift for result now we know there is no overflow.
      __ shll(left, Immediate(value));
    }
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right()->definition()->range();
  if (shift_left->left()->BindsToConstant() && !is_truncating) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ cmpl(right, Immediate(0));
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          (right_range == NULL) ||
          !right_range->IsWithin(0, max_right - 1);
      if (right_needs_check) {
        __ cmpl(right,
            Immediate(reinterpret_cast<int32_t>(Smi::New(max_right))));
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ shll(left, right);
    }
    return;
  }

  const bool right_needs_check =
      (right_range == NULL) || !right_range->IsWithin(0, (Smi::kBits - 1));
  ASSERT(right == ECX);  // Count must be in ECX
  if (is_truncating) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmpl(right, Immediate(0));
        __ j(NEGATIVE, deopt);
      }
      Label done, is_not_zero;
      __ cmpl(right,
          Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ j(BELOW, &is_not_zero, Assembler::kNearJump);
      __ xorl(left, left);
      __ jmp(&done, Assembler::kNearJump);
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
        Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
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


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (RightIsPowerOfTwoConstant()) {
      summary->set_in(0, Location::RequiresRegister());
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      // The programmer only controls one bit, so the constant is safe.
      summary->set_in(1, Location::Constant(right_constant->value()));
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
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(EDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(EAX));
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    const intptr_t kNumTemps = !IsTruncating() ? 1 : 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    if (!IsTruncating()) {
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
    deopt  = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int32_t imm = reinterpret_cast<int32_t>(constant.raw());
    switch (op_kind()) {
    case Token::kADD:
        if (imm != 0) {
          // Checking overflow without emitting an instruction would be wrong.
          __ addl(left, Immediate(imm));
          if (deopt != NULL) __ j(OVERFLOW, deopt);
        }
        break;
      case Token::kSUB: {
        if (imm != 0) {
          // Checking overflow without emitting an instruction would be wrong.
          __ subl(left, Immediate(imm));
          if (deopt != NULL) __ j(OVERFLOW, deopt);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 2) {
          __ shll(left, Immediate(1));
        } else {
          __ imull(left, Immediate(value));
        }
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 1) {
          // Do nothing.
          break;
        } else if (value == -1) {
          // Check the corner case of dividing the 'MIN_SMI' with -1, in which
          // case we cannot negate the result.
          __ cmpl(left, Immediate(0x80000000));
          __ j(EQUAL, deopt);
          __ negl(left);
          break;
        }
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        Register temp = locs()->temp(0).reg();
        __ movl(temp, left);
        __ sarl(temp, Immediate(31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        __ shrl(temp, Immediate(32 - shift_count));
        __ addl(left, temp);
        ASSERT(shift_count > 0);
        __ sarl(left, Immediate(shift_count));
        if (value < 0) {
          __ negl(left);
        }
        __ SmiTag(left);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ andl(left, Immediate(imm));
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ orl(left, Immediate(imm));
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ xorl(left, Immediate(imm));
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        intptr_t value = Smi::Cast(constant).Value();

        if (value == 0) {
          // TODO(vegorov): should be handled outside.
          break;
        } else if (value < 0) {
          // TODO(vegorov): should be handled outside.
          __ jmp(deopt);
          break;
        }

        value = value + kSmiTagSize;
        if (value >= kCountLimit) value = kCountLimit;

        __ sarl(left, Immediate(value));
        __ SmiTag(left);
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // if locs()->in(1).IsConstant()

  if (locs()->in(1).IsStackSlot()) {
    const Address& right = locs()->in(1).ToStackSlotAddress();
    switch (op_kind()) {
      case Token::kADD: {
        __ addl(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ subl(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kMUL: {
        __ SmiUntag(left);
        __ imull(left, right);
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ andl(left, right);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ orl(left, right);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ xorl(left, right);
        break;
      }
      default:
        UNREACHABLE();
    }
    return;
  }  // if locs()->in(1).IsStackSlot.

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  Range* right_range = this->right()->definition()->range();
  switch (op_kind()) {
    case Token::kADD: {
      __ addl(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kSUB: {
      __ subl(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ imull(left, right);
      if (deopt != NULL) __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ andl(left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orl(left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xorl(left, right);
      break;
    }
    case Token::kTRUNCDIV: {
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      __ cdq();  // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ cmpl(result, Immediate(0x40000000));
      __ j(EQUAL, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      __ cdq();  // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      Label done;
      __ cmpl(result, Immediate(0));
      __ j(GREATER_EQUAL, &done, Assembler::kNearJump);
      // Result is negative, adjust it.
      if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
        // Right can be positive and negative.
        Label subtract;
        __ cmpl(right, Immediate(0));
        __ j(LESS, &subtract, Assembler::kNearJump);
        __ addl(result, right);
        __ jmp(&done, Assembler::kNearJump);
        __ Bind(&subtract);
        __ subl(result, right);
      } else if (right_range->IsPositive()) {
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
        __ cmpl(right, Immediate(0));
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarl operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if ((right_range == NULL) ||
          !right_range->OnlyLessThanOrEqualTo(kCountLimit)) {
        __ cmpl(right, Immediate(kCountLimit));
        Label count_ok;
        __ j(LESS, &count_ok, Assembler::kNearJump);
        __ movl(right, Immediate(kCountLimit));
        __ Bind(&count_ok);
      }
      ASSERT(right == ECX);  // Count must be in ECX
      __ SmiUntag(left);
      __ sarl(left, right);
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
    __ testl(left, Immediate(kSmiTagMask));
  } else  if (left_cid == kSmiCid) {
    __ testl(right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testl(left, Immediate(kSmiTagMask));
  } else {
    Register temp = locs()->temp(0).reg();
    __ movl(temp, left);
    __ orl(temp, right);
    __ testl(temp, Immediate(kSmiTagMask));
  }
  __ j(ZERO, deopt);
}





LocationSummary* BoxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->double_class(), out_reg, kNoRegister);
  __ movsd(FieldAddress(out_reg, Double::value_offset()), value);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t value_cid = value()->Type()->ToCid();
  const bool needs_temp = ((value_cid != kSmiCid) && (value_cid != kDoubleCid));
  const bool needs_writable_input = (value_cid == kSmiCid);
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, needs_writable_input
                     ? Location::WritableRegister()
                     : Location::RequiresRegister());
  if (needs_temp) summary->set_temp(0, Location::RequiresRegister());
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
    Register temp = locs()->temp(0).reg();
    if (value_type->is_nullable() &&
        (value_type->ToNullableCid() == kDoubleCid)) {
      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ cmpl(value, raw_null);
      __ j(EQUAL, deopt);
      // It must be double now.
      __ movsd(result, FieldAddress(value, Double::value_offset()));
    } else {
      Label is_smi, done;
      __ testl(value, Immediate(kSmiTagMask));
      __ j(ZERO, &is_smi);
      __ CompareClassId(value, kDoubleCid, temp);
      __ j(NOT_EQUAL, deopt);
      __ movsd(result, FieldAddress(value, Double::value_offset()));
      __ jmp(&done);
      __ Bind(&is_smi);
      __ movl(temp, value);
      __ SmiUntag(temp);
      __ cvtsi2sd(result, temp);
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
      compiler, this, compiler->float32x4_class(), out_reg, kNoRegister);
  __ movups(FieldAddress(out_reg, Float32x4::value_offset()), value);
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
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat32x4Cid, temp);
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
      compiler, this, compiler->float64x2_class(), out_reg, kNoRegister);
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
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kFloat64x2Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat64x2Cid, temp);
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
      compiler, this, compiler->int32x4_class(), out_reg, kNoRegister);
  __ movups(FieldAddress(out_reg, Int32x4::value_offset()), value);
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
  const XmmRegister result = locs()->out(0).fpu_reg();

  if (value_cid != kInt32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, ICData::kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kInt32x4Cid, temp);
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
  __ subl(ESP, Immediate(16));
  __ cvtsd2ss(v0, v0);
  __ movss(Address(ESP, 0), v0);
  __ movsd(v0, v1);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(ESP, 4), v0);
  __ movsd(v0, v2);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(ESP, 8), v0);
  __ movsd(v0, v3);
  __ cvtsd2ss(v0, v0);
  __ movss(Address(ESP, 12), v0);
  __ movups(v0, Address(ESP, 0));
  __ addl(ESP, Immediate(16));
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
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), value);
      // Write over X value.
      __ movss(Address(ESP, 0), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
      break;
    case MethodRecognizer::kFloat32x4WithY:
      __ cvtsd2ss(replacement, replacement);
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), value);
      // Write over Y value.
      __ movss(Address(ESP, 4), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
      break;
    case MethodRecognizer::kFloat32x4WithZ:
      __ cvtsd2ss(replacement, replacement);
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), value);
      // Write over Z value.
      __ movss(Address(ESP, 8), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
      break;
    case MethodRecognizer::kFloat32x4WithW:
      __ cvtsd2ss(replacement, replacement);
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), value);
      // Write over W value.
      __ movss(Address(ESP, 12), replacement);
      // Move updated value into output register.
      __ movups(replacement, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
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
  __ subl(ESP, Immediate(16));
  __ movsd(Address(ESP, 0), v0);
  __ movsd(Address(ESP, 8), v1);
  __ movups(v0, Address(ESP, 0));
  __ addl(ESP, Immediate(16));
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
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), left);
      // Write over X value.
      __ movsd(Address(ESP, 0), right);
      // Move updated value into output register.
      __ movups(left, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
      break;
    case MethodRecognizer::kFloat64x2WithY:
      __ subl(ESP, Immediate(16));
      // Move value to stack.
      __ movups(Address(ESP, 0), left);
      // Write over Y value.
      __ movsd(Address(ESP, 8), right);
      // Move updated value into output register.
      __ movups(left, Address(ESP, 0));
      __ addl(ESP, Immediate(16));
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


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
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


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register v0 = locs()->in(0).reg();
  Register v1 = locs()->in(1).reg();
  Register v2 = locs()->in(2).reg();
  Register v3 = locs()->in(3).reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  Label x_false, x_done;
  Label y_false, y_done;
  Label z_false, z_done;
  Label w_false, w_done;
  __ subl(ESP, Immediate(16));
  __ CompareObject(v0, Bool::True());
  __ j(NOT_EQUAL, &x_false);
  __ movl(Address(ESP, 0), Immediate(0xFFFFFFFF));
  __ jmp(&x_done);
  __ Bind(&x_false);
  __ movl(Address(ESP, 0), Immediate(0x0));
  __ Bind(&x_done);

  __ CompareObject(v1, Bool::True());
  __ j(NOT_EQUAL, &y_false);
  __ movl(Address(ESP, 4), Immediate(0xFFFFFFFF));
  __ jmp(&y_done);
  __ Bind(&y_false);
  __ movl(Address(ESP, 4), Immediate(0x0));
  __ Bind(&y_done);

  __ CompareObject(v2, Bool::True());
  __ j(NOT_EQUAL, &z_false);
  __ movl(Address(ESP, 8), Immediate(0xFFFFFFFF));
  __ jmp(&z_done);
  __ Bind(&z_false);
  __ movl(Address(ESP, 8), Immediate(0x0));
  __ Bind(&z_done);

  __ CompareObject(v3, Bool::True());
  __ j(NOT_EQUAL, &w_false);
  __ movl(Address(ESP, 12), Immediate(0xFFFFFFFF));
  __ jmp(&w_done);
  __ Bind(&w_false);
  __ movl(Address(ESP, 12), Immediate(0x0));
  __ Bind(&w_done);

  __ movups(result, Address(ESP, 0));
  __ addl(ESP, Immediate(16));
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
  __ subl(ESP, Immediate(16));
  // Move value to stack.
  __ movups(Address(ESP, 0), value);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4GetFlagX:
      __ movl(result, Address(ESP, 0));
      break;
    case MethodRecognizer::kInt32x4GetFlagY:
      __ movl(result, Address(ESP, 4));
      break;
    case MethodRecognizer::kInt32x4GetFlagZ:
      __ movl(result, Address(ESP, 8));
      break;
    case MethodRecognizer::kInt32x4GetFlagW:
      __ movl(result, Address(ESP, 12));
      break;
    default: UNREACHABLE();
  }
  __ addl(ESP, Immediate(16));
  __ testl(result, result);
  __ j(NOT_ZERO, &non_zero, Assembler::kNearJump);
  __ LoadObject(result, Bool::False());
  __ jmp(&done);
  __ Bind(&non_zero);
  __ LoadObject(result, Bool::True());
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
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister mask = locs()->in(0).fpu_reg();
  Register flag = locs()->in(1).reg();
  ASSERT(mask == locs()->out(0).fpu_reg());
  __ subl(ESP, Immediate(16));
  // Copy mask to stack.
  __ movups(Address(ESP, 0), mask);
  Label falsePath, exitPath;
  __ CompareObject(flag, Bool::True());
  __ j(NOT_EQUAL, &falsePath);
  switch (op_kind()) {
    case MethodRecognizer::kInt32x4WithFlagX:
      __ movl(Address(ESP, 0), Immediate(0xFFFFFFFF));
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ movl(Address(ESP, 0), Immediate(0x0));
    break;
    case MethodRecognizer::kInt32x4WithFlagY:
      __ movl(Address(ESP, 4), Immediate(0xFFFFFFFF));
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ movl(Address(ESP, 4), Immediate(0x0));
    break;
    case MethodRecognizer::kInt32x4WithFlagZ:
      __ movl(Address(ESP, 8), Immediate(0xFFFFFFFF));
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ movl(Address(ESP, 8), Immediate(0x0));
    break;
    case MethodRecognizer::kInt32x4WithFlagW:
      __ movl(Address(ESP, 12), Immediate(0xFFFFFFFF));
      __ jmp(&exitPath);
      __ Bind(&falsePath);
      __ movl(Address(ESP, 12), Immediate(0x0));
    break;
    default: UNREACHABLE();
  }
  __ Bind(&exitPath);
  // Copy mask back to register.
  __ movups(mask, Address(ESP, 0));
  __ addl(ESP, Immediate(16));
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
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(XMM1));
    // EDI is chosen because it is callee saved so we do not need to back it
    // up before calling into the runtime.
    summary->set_temp(0, Location::RegisterLocation(EDI));
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
    // Save ESP.
    __ movl(locs()->temp(0).reg(), ESP);
    __ ReserveAlignedFrameSpace(kDoubleSize * InputCount());
    __ movsd(Address(ESP, 0), locs()->in(0).fpu_reg());
    __ CallRuntime(TargetFunction(), InputCount());
    __ fstpl(Address(ESP, 0));
    __ movsd(locs()->out(0).fpu_reg(), Address(ESP, 0));
    // Restore ESP.
    __ movl(ESP, locs()->temp(0).reg());
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
    __ movsd(result, Address::Absolute(reinterpret_cast<uword>(&kNaN)));
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
    __ testl(temp, Immediate(1));
    ASSERT(left == result);
    if (is_min) {
      __ j(NOT_ZERO, &done, Assembler::kNearJump);  // Negative -> return left.
    } else {
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
  __ cmpl(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgel(result, right);
  } else {
    __ cmovlessl(result, right);
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
      __ negl(value);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ notl(value);
      __ andl(value, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
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


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(ECX));
  result->set_out(0, Location::RegisterLocation(EAX));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value_obj = locs()->in(0).reg();
  XmmRegister value_double = XMM0;
  ASSERT(result == EAX);
  ASSERT(result != value_obj);
  __ movsd(value_double, FieldAddress(value_obj, Double::value_offset()));
  __ cvttsd2si(result, value_double);
  // Overflow is signalled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, Immediate(0xC0000000));
  __ j(NEGATIVE, &do_call, Assembler::kNearJump);
  __ SmiTag(result);
  __ jmp(&done);
  __ Bind(&do_call);
  __ pushl(value_obj);
  ASSERT(instance_call()->HasICData());
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT((ic_data.NumberOfChecks() == 1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));

  const intptr_t kNumberOfArguments = 1;
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
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  Register result = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  __ cvttsd2si(result, value);
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, Immediate(0xC0000000));
  __ j(NEGATIVE, deopt);
  __ SmiTag(result);
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
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 3 : 1;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, InputCount(), kNumTemps, LocationSummary::kCall);
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

  __ xorps(zero_temp, zero_temp);   // 0.0.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1.0)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));

  Label check_base, skip_call;
  // exponent == 0.0 -> return 1.0;
  __ comisd(exp, zero_temp);
  __ j(PARITY_EVEN, &check_base);
  __ j(EQUAL, &skip_call);  // 'result' is 1.0.

  // exponent == 1.0 ?
  __ comisd(exp, result);
  Label return_base;
  __ j(EQUAL, &return_base, Assembler::kNearJump);

  // exponent == 2.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(2.0)));
  __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  Label return_base_times_2;
  __ j(EQUAL, &return_base_times_2, Assembler::kNearJump);

  // exponent == 3.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(3.0)));
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

  // base == 1.0 -> return 1.0;
  __ comisd(base, result);
  Label return_nan;
  __ j(PARITY_EVEN, &return_nan, Assembler::kNearJump);
  __ j(EQUAL, &skip_call, Assembler::kNearJump);
  // Note: 'base' could be NaN.
  __ comisd(exp, base);
  // Neither 'exp' nor 'base' is NaN.
  Label try_sqrt;
  __ j(PARITY_ODD, &try_sqrt, Assembler::kNearJump);
  // Return NaN.
  __ Bind(&return_nan);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(NAN)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  __ jmp(&skip_call);

  Label do_pow, return_zero;
  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(-INFINITY)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  // base == -Infinity -> call pow;
  __ comisd(base, result);
  __ j(EQUAL, &do_pow, Assembler::kNearJump);

  // exponent == 0.5 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0.5)));
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
  // Save ESP.
  __ movl(locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg(), ESP);
  __ ReserveAlignedFrameSpace(kDoubleSize * kInputCount);
  for (intptr_t i = 0; i < kInputCount; i++) {
    __ movsd(Address(ESP, kDoubleSize * i), locs->in(i).fpu_reg());
  }
  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ fstpl(Address(ESP, 0));
  __ movsd(locs->out(0).fpu_reg(), Address(ESP, 0));
  // Restore ESP.
  __ movl(ESP, locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg());
  __ Bind(&skip_call);
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  // Save ESP.
  __ movl(locs()->temp(kSavedSpTempIndex).reg(), ESP);
  __ ReserveAlignedFrameSpace(kDoubleSize * InputCount());
  for (intptr_t i = 0; i < InputCount(); i++) {
    __ movsd(Address(ESP, kDoubleSize * i), locs()->in(i).fpu_reg());
  }

  __ CallRuntime(TargetFunction(), InputCount());
  __ fstpl(Address(ESP, 0));
  __ movsd(locs()->out(0).fpu_reg(), Address(ESP, 0));
  // Restore ESP.
  __ movl(ESP, locs()->temp(kSavedSpTempIndex).reg());
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
    __ movl(out, in);
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
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_in(1, Location::WritableRegister());
    // Output is a pair of registers.
    summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                       Location::RegisterLocation(EDX)));
    return summary;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_out(0, Location::Pair(Location::RequiresFpuRegister(),
                                       Location::RequiresFpuRegister()));
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
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
    __ cdq();  // Sign extend EAX -> EDX:EAX.
    __ idivl(right);  //  EAX: quotient, EDX: remainder.
    // Check the corner case of dividing the 'MIN_SMI' with -1, in which
    // case we cannot tag the result.
    // TODO(srdjan): We could store instead untagged intermediate results in a
    // typed array, but then the load indexed instructions would need to be
    // able to deoptimize.
    __ cmpl(EAX, Immediate(0x40000000));
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
    Label done;
    __ cmpl(EDX, Immediate(0));
    __ j(GREATER_EQUAL, &done, Assembler::kNearJump);
    // Result is negative, adjust it.
    if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
      Label subtract;
      __ cmpl(right, Immediate(0));
      __ j(LESS, &subtract, Assembler::kNearJump);
      __ addl(EDX, right);
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&subtract);
      __ subl(EDX, right);
    } else if (right_range->IsPositive()) {
      // Right is positive.
      __ addl(EDX, right);
    } else {
      // Right is negative.
      __ subl(EDX, right);
    }
    __ Bind(&done);

    __ SmiTag(EAX);
    __ SmiTag(EDX);
    return;
  }

  if (kind() == MergedMathInstr::kSinCos) {
    XmmRegister in = locs()->in(0).fpu_reg();
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* pair = locs()->out(0).AsPairLocation();
    XmmRegister out1 = pair->At(0).fpu_reg();
    XmmRegister out2 = pair->At(1).fpu_reg();

    // Do x87 sincos, since the ia32 compilers may not fuse sin/cos into
    // sincos.
    __ pushl(EAX);
    __ pushl(EAX);
    __ movsd(Address(ESP, 0), in);
    __ fldl(Address(ESP, 0));
    __ fsincos();
    __ fstpl(Address(ESP, 0));
    __ movsd(out1, Address(ESP, 0));
    __ fstpl(Address(ESP, 0));
    __ movsd(out2, Address(ESP, 0));
    __ addl(ESP, Immediate(2 * kWordSize));
    return;
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
    __ jmp(deopt);
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

  // Load receiver into EAX.
  __ movl(EAX,
      Address(ESP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  LoadValueCid(compiler, EDI, EAX,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            EDI,  // Class id register.
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
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(locs()->in(0).reg(), raw_null);
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
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, &is_ok);
    cix++;  // Skip first check.
  } else {
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
  }
  __ LoadClassId(temp, value);

  if (IsDenseSwitch()) {
    ASSERT(cids_[0] < cids_[cids_.length() - 1]);
    __ subl(temp, Immediate(cids_[0]));
    __ cmpl(temp, Immediate(cids_[cids_.length() - 1] - cids_[0]));
    __ j(ABOVE, deopt);

    intptr_t mask = ComputeCidMask();
    if (!IsDenseMask(mask)) {
      // Only need mask if there are missing numbers in the range.
      ASSERT(cids_.length() > 2);
      Register mask_reg = locs()->temp(1).reg();
      __ movl(mask_reg, Immediate(mask));
      __ bt(mask_reg, temp);
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
  __ testl(value, Immediate(kSmiTagMask));
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
  __ cmpl(value, Immediate(Smi::RawValue(cid_)));
  __ j(NOT_ZERO, deopt);
}


// Length: register or constant.
// Index: register, constant or stack slot.
LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  ConstantInstr* index_constant = index()->definition()->AsConstant();
  if (index_constant != NULL) {
    locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  } else {
    locs->set_in(kIndexPos, Location::PrefersRegister());
  }
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
    __ cmpl(length, Immediate(reinterpret_cast<int32_t>(index.raw())));
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    if (index_loc.IsStackSlot()) {
      const Address& index = index_loc.ToStackSlotAddress();
      __ cmpl(index, Immediate(reinterpret_cast<int32_t>(length.raw())));
    } else {
      Register index = index_loc.reg();
      __ cmpl(index, Immediate(reinterpret_cast<int32_t>(length.raw())));
    }
    __ j(ABOVE_EQUAL, deopt);
  } else if (index_loc.IsStackSlot()) {
    Register length = length_loc.reg();
    const Address& index = index_loc.ToStackSlotAddress();
    __ cmpl(length, index);
    __ j(BELOW_EQUAL, deopt);
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    __ cmpl(index, length);
    __ j(ABOVE_EQUAL, deopt);
  }
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                     Location::RegisterLocation(EDX)));
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
  ASSERT(result_lo == EAX);
  ASSERT(result_hi == EDX);

  if (value_cid == kMintCid) {
    __ movl(result_lo, FieldAddress(value, Mint::value_offset()));
    __ movl(result_hi, FieldAddress(value, Mint::value_offset() + kWordSize));
  } else if (value_cid == kSmiCid) {
    __ movl(result_lo, value);
    __ SmiUntag(result_lo);
    // Sign extend into result_hi.
    __ cdq();
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptUnboxInteger);
    Label is_smi, done;
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, &is_smi);
    __ CompareClassId(value, kMintCid, result_lo);
    __ j(NOT_EQUAL, deopt);
    __ movl(result_lo, FieldAddress(value, Mint::value_offset()));
    __ movl(result_hi, FieldAddress(value, Mint::value_offset() + kWordSize));
    __ jmp(&done);
    __ Bind(&is_smi);
    __ movl(result_lo, value);
    __ SmiUntag(result_lo);
    // Sign extend into result_hi.
    __ cdq();
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


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (is_smi()) {
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
  Label not_smi, done;

  // 1. Compute (x + -kMinSmi) which has to be in the range
  //    0 .. -kMinSmi+kMaxSmi for x to fit into a smi.
  __ addl(value_lo, Immediate(0x40000000));
  __ adcl(out_reg, Immediate(0));
  // 2. Unsigned compare to -kMinSmi+kMaxSmi.
  __ cmpl(value_lo, Immediate(0x80000000));
  __ sbbl(out_reg, Immediate(0));
  __ j(ABOVE_EQUAL, &not_smi);
  // 3. Restore lower half if result is a smi.
  __ subl(value_lo, Immediate(0x40000000));
  __ movl(out_reg, value_lo);
  __ SmiTag(out_reg);
  __ jmp(&done);
  __ Bind(&not_smi);
  // 3. Restore lower half of input before using it.
  __ subl(value_lo, Immediate(0x40000000));

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->mint_class(), out_reg, kNoRegister);
  __ movl(FieldAddress(out_reg, Mint::value_offset()), value_lo);
  __ movl(FieldAddress(out_reg, Mint::value_offset() + kWordSize), value_hi);
  __ Bind(&done);
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL: {
      const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
      LocationSummary* summary = new(isolate) LocationSummary(
          isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, (op_kind() == Token::kMUL)
          ? Location::Pair(Location::RegisterLocation(EAX),
                           Location::RegisterLocation(EDX))
          : Location::Pair(Location::RequiresRegister(),
                           Location::RequiresRegister()));
      summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      summary->set_out(0, Location::SameAsFirstInput());
      if (kNumTemps > 0) {
        summary->set_temp(0, Location::RequiresRegister());
      }
      return summary;
    }
    default:
      UNREACHABLE();
      return NULL;
  }
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
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);
  }
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
      if (can_overflow()) {
        __ j(OVERFLOW, deopt);
      }
      break;
    }
    case Token::kMUL: {
      // The product of two signed 32-bit integers fits in a signed 64-bit
      // result without causing overflow.
      // We deopt on larger inputs.
      // TODO(regis): Range analysis may eliminate the deopt check.
      Register temp = locs()->temp(0).reg();
      __ movl(temp, left_lo);
      __ sarl(temp, Immediate(31));
      __ cmpl(temp, left_hi);
      __ j(NOT_EQUAL, deopt);
      __ movl(temp, right_lo);
      __ sarl(temp, Immediate(31));
      __ cmpl(temp, right_hi);
      __ j(NOT_EQUAL, deopt);
      ASSERT(left_lo == EAX);
      __ imull(right_lo);  // Result in EDX:EAX.
      ASSERT(out_lo == EAX);
      ASSERT(out_hi == EDX);
      break;
    }
    default:
      UNREACHABLE();
  }
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, left_lo, left_hi);
  }
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (op_kind() == Token::kSHL) && CanDeoptimize() ? 2 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
  if ((op_kind() == Token::kSHL) && CanDeoptimize()) {
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  }
  summary->set_out(0, Location::SameAsFirstInput());
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
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptShiftMintOp);
  }
  if (locs()->in(1).IsConstant()) {
    // Code for a constant shift amount.
    ASSERT(locs()->in(1).constant().IsSmi());
    const int32_t shift =
        reinterpret_cast<int32_t>(locs()->in(1).constant().raw()) >> 1;
    if ((shift < 0) || (shift > kMintShiftCountLimit)) {
      __ jmp(deopt);
      return;
    } else if (shift == 0) {
      // Nothing to do for zero shift amount.
      return;
    }
    switch (op_kind()) {
      case Token::kSHR: {
        if (shift > 31) {
          __ movl(left_lo, left_hi);  // Shift by 32.
          __ sarl(left_hi, Immediate(31));  // Sign extend left hi.
          if (shift > 32) {
            __ sarl(left_lo, Immediate(shift - 32));
          }
        } else {
          __ shrd(left_lo, left_hi, Immediate(shift));
          __ sarl(left_hi, Immediate(shift));
        }
        break;
      }
      case Token::kSHL: {
        if (can_overflow()) {
          Register temp1 = locs()->temp(0).reg();
          Register temp2 = locs()->temp(1).reg();
          __ movl(temp1, left_hi);  // Preserve high 32 bits.
          if (shift > 31) {
            __ movl(left_hi, left_lo);  // Shift by 32.
            __ xorl(left_lo, left_lo);  // Zero left_lo.
            if (shift > 32) {
              __ shll(left_hi, Immediate(shift - 32));
            }
            // Check for overflow by sign extending the high 32 bits
            // and comparing with the input.
            __ movl(temp2, left_hi);
            __ sarl(temp2, Immediate(31));
            __ cmpl(temp1, temp2);
            __ j(NOT_EQUAL, deopt);
          } else {
            __ shld(left_hi, left_lo, Immediate(shift));
            __ shll(left_lo, Immediate(shift));
            // Check for overflow by shifting back the high 32 bits
            // and comparing with the input.
            __ movl(temp2, left_hi);
            __ sarl(temp2, Immediate(shift));
            __ cmpl(temp1, temp2);
            __ j(NOT_EQUAL, deopt);
          }
        } else {
          if (shift > 31) {
            __ movl(left_hi, left_lo);  // Shift by 32.
            __ xorl(left_lo, left_lo);  // Zero left_lo.
            if (shift > 32) {
              __ shll(left_hi, Immediate(shift - 32));
            }
          } else {
            __ shld(left_hi, left_lo, Immediate(shift));
            __ shll(left_lo, Immediate(shift));
          }
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  } else {
    // Code for a variable shift amount.
    // Deoptimize if shift count is > 63.
    // sarl operation masks the count to 5 bits and
    // shrd is undefined with count > operand size (32)
    __ SmiUntag(ECX);
    if (has_shift_count_check()) {
      __ cmpl(ECX, Immediate(kMintShiftCountLimit));
      __ j(ABOVE, deopt);
    }
    Label done, large_shift;
    switch (op_kind()) {
      case Token::kSHR: {
        __ cmpl(ECX, Immediate(31));
        __ j(ABOVE, &large_shift);

        __ shrd(left_lo, left_hi);  // Shift count in CL.
        __ sarl(left_hi, ECX);  // Shift count in CL.
        __ jmp(&done, Assembler::kNearJump);

        __ Bind(&large_shift);
        // No need to subtract 32 from CL, only 5 bits used by sarl.
        __ movl(left_lo, left_hi);  // Shift by 32.
        __ sarl(left_hi, Immediate(31));  // Sign extend left hi.
        __ sarl(left_lo, ECX);  // Shift count: CL % 32.
        break;
      }
      case Token::kSHL: {
        if (can_overflow()) {
          Register temp1 = locs()->temp(0).reg();
          Register temp2 = locs()->temp(1).reg();
          __ movl(temp1, left_hi);  // Preserve high 32 bits.
          __ cmpl(ECX, Immediate(31));
          __ j(ABOVE, &large_shift);

          __ shld(left_hi, left_lo);  // Shift count in CL.
          __ shll(left_lo, ECX);  // Shift count in CL.
          // Check for overflow by shifting back the high 32 bits
          // and comparing with the input.
          __ movl(temp2, left_hi);
          __ sarl(temp2, ECX);
          __ cmpl(temp1, temp2);
          __ j(NOT_EQUAL, deopt);
          __ jmp(&done, Assembler::kNearJump);

          __ Bind(&large_shift);
          // No need to subtract 32 from CL, only 5 bits used by shll.
          __ movl(left_hi, left_lo);  // Shift by 32.
          __ xorl(left_lo, left_lo);  // Zero left_lo.
          __ shll(left_hi, ECX);  // Shift count: CL % 32.
          // Check for overflow by sign extending the high 32 bits
          // and comparing with the input.
          __ movl(temp2, left_hi);
          __ sarl(temp2, Immediate(31));
          __ cmpl(temp1, temp2);
          __ j(NOT_EQUAL, deopt);
        } else {
          __ cmpl(ECX, Immediate(31));
          __ j(ABOVE, &large_shift);

          __ shld(left_hi, left_lo);  // Shift count in CL.
          __ shll(left_lo, ECX);  // Shift count in CL.
          __ jmp(&done, Assembler::kNearJump);

          __ Bind(&large_shift);
          // No need to subtract 32 from CL, only 5 bits used by shll.
          __ movl(left_hi, left_lo);  // Shift by 32.
          __ xorl(left_lo, left_lo);  // Zero left_lo.
          __ shll(left_hi, ECX);  // Shift count: CL % 32.
        }
        break;
      }
      default:
        UNREACHABLE();
    }
    __ Bind(&done);
  }
  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, left_lo, left_hi);
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
  summary->set_out(0, Location::SameAsFirstInput());
  if (FLAG_throw_on_javascript_int_overflow) {
    summary->set_temp(0, Location::RequiresRegister());
  }
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
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);

  Label* deopt = NULL;
  if (FLAG_throw_on_javascript_int_overflow) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryMintOp);
  }

  __ notl(left_lo);
  __ notl(left_hi);

  if (FLAG_throw_on_javascript_int_overflow) {
    EmitJavascriptIntOverflowCheck(compiler, deopt, left_lo, left_hi);
  }
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


CompileType BoxUint32Instr::ComputeType() const {
  return CompileType::Int();
}


CompileType UnboxUint32Instr::ComputeType() const {
  return CompileType::Int();
}


LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      __ andl(out, right);
      break;
    case Token::kBIT_OR:
      __ orl(out, right);
      break;
    case Token::kBIT_XOR:
      __ xorl(out, right);
      break;
    case Token::kADD:
      __ addl(out, right);
      break;
    case Token::kSUB:
      __ subl(out, right);
      break;
    case Token::kMUL:
      __ mull(right);  // Result in EDX:EAX.
      ASSERT(out == EAX);
      ASSERT(locs()->temp(0).reg() == EDX);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t kShifterLimit = 31;

  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(left == out);


  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptShiftMintOp);

  if (locs()->in(1).IsConstant()) {
    // Shifter is constant.

    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t shift_value = Smi::Cast(constant).Value();

    // Check constant shift value.
    if (shift_value == 0) {
      // Nothing to do.
    } else if (shift_value < 0) {
      // Invalid shift value.
      __ jmp(deopt);
    } else if (shift_value > kShifterLimit) {
      // Result is 0.
      __ xorl(left, left);
    } else {
      // Do the shift: (shift_value > 0) && (shift_value <= kShifterLimit).
      switch (op_kind()) {
        case Token::kSHR:
          __ shrl(left, Immediate(shift_value));
        break;
        case Token::kSHL:
          __ shll(left, Immediate(shift_value));
        break;
        default:
          UNREACHABLE();
      }
    }
    return;
  }

  // Non constant shift value.

  Register shifter = locs()->in(1).reg();
  ASSERT(shifter == ECX);

  Label done;
  Label zero;

  // TODO(johnmccutchan): Use range information to avoid these checks.
  __ SmiUntag(shifter);
  __ cmpl(shifter, Immediate(0));
  // If shift value is < 0, deoptimize.
  __ j(NEGATIVE, deopt);
  __ cmpl(shifter, Immediate(kShifterLimit));
  // If shift value is >= 32, return zero.
  __ j(ABOVE, &zero);

  // Do the shift.
  switch (op_kind()) {
    case Token::kSHR:
      __ shrl(left, shifter);
      __ jmp(&done);
    break;
    case Token::kSHL:
      __ shll(left, shifter);
      __ jmp(&done);
    break;
    default:
      UNREACHABLE();
  }

  __ Bind(&zero);
  // Shift was greater than 31 bits, just return zero.
  __ xorl(left, left);

  // Exit path.
  __ Bind(&done);
}


LocationSummary* UnaryUint32OpInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* BoxUint32Instr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxUint32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

  Label not_smi, done;

  // TODO(johnmccutchan): Use range information to fast path smi / mint boxing.
  // Test if this value is <= kSmiMax.
  __ cmpl(value, Immediate(kSmiMax));
  __ j(ABOVE, &not_smi);
  // Smi.
  __ movl(out, value);
  __ SmiTag(out);
  __ jmp(&done);
  __ Bind(&not_smi);
  // Allocate a mint.
  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->mint_class(), out, kNoRegister);
  // Copy low word into mint.
  __ movl(FieldAddress(out, Mint::value_offset()), value);
  // Zero high word.
  __ movl(FieldAddress(out, Mint::value_offset() + kWordSize), Immediate(0));
  __ Bind(&done);
}


LocationSummary* UnboxUint32Instr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      ((value_cid == kMintCid) || (value_cid == kSmiCid)) ? 0 : 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void UnboxUint32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out(0).reg());

  // TODO(johnmccutchan): Emit better code for constant inputs.
  if (value_cid == kMintCid) {
    __ movl(value, FieldAddress(value, Mint::value_offset()));
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);
  } else {
    Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptUnboxInteger);
    Label is_smi, done;
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, &is_smi);
    __ CompareClassId(value, kMintCid, temp);
    __ j(NOT_EQUAL, deopt);
    __ movl(value, FieldAddress(value, Mint::value_offset()));
    __ jmp(&done);
    __ Bind(&is_smi);
    __ SmiUntag(value);
    __ Bind(&done);
  }
}


LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUnboxedMint) {
    summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else {
    ASSERT(from() == kUnboxedUint32);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  }
  return summary;
}


void UnboxedIntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (from() == kUnboxedMint) {
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ movl(out, in_lo);
  } else {
    ASSERT(from() == kUnboxedUint32);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ movl(out_lo, in);
    // Zero upper word.
    __ xorl(out_hi, out_hi);
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


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter();
    }
    // The deoptimization descriptor points after the edge counter code for
    // uniformity with ARM and MIPS, where we can reuse pattern matching
    // code that matches backwards from the end of the pattern.
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
    locs->set_in(0, Location::RegisterLocation(EAX));
    locs->set_in(1, Location::RegisterLocation(ECX));
    locs->set_out(0, Location::RegisterLocation(EAX));
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
  __ LoadObject(result, Bool::False());
  __ jmp(&done, Assembler::kNearJump);
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


// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}


LocationSummary* IfThenElseInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(isolate, opt);
  // TODO(vegorov): support byte register constraints in the register allocator.
  comparison()->locs()->set_out(0, Location::RegisterLocation(EDX));
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out(0).reg() == EDX);

  // Clear upper part of the out register. We are going to use setcc on it
  // which is a byte move.
  __ xorl(EDX, EDX);

  // Emit comparison code. This must not overwrite the result register.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);

  const bool is_power_of_two_kind = IsPowerOfTwoKind(if_true_, if_false_);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if (is_power_of_two_kind) {
    if (true_value == 0) {
      // We need to have zero in EDX on true_condition.
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
    __ shll(EDX, Immediate(shift + kSmiTagSize));
  } else {
    __ decl(EDX);
    __ andl(EDX, Immediate(
        Smi::RawValue(true_value) - Smi::RawValue(false_value)));
    if (false_value != 0) {
      __ addl(EDX, Immediate(Smi::RawValue(false_value)));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));  // Function.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptors.
  intptr_t argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  __ LoadObject(EDX, arguments_descriptor);

  // EBX: Code (compiled code or lazy compile stub).
  ASSERT(locs()->in(0).reg() == EAX);
  __ movl(EBX, FieldAddress(EAX, Function::instructions_offset()));

  // EAX: Function.
  // EDX: Arguments descriptor array.
  // ECX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ xorl(ECX, ECX);
  __ addl(EBX, Immediate(Instructions::HeaderSize() - kHeapObjectTag));
  __ call(EBX);
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
  __ LoadObject(result, Bool::True());
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, Bool::False());
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
  __ movl(EDX, Immediate(kInvalidObjectPointer));
  __ movl(EDX, Immediate(kInvalidObjectPointer));
#endif
}

}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_IA32
