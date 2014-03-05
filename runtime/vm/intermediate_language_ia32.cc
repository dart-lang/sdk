// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/intermediate_language.h"

#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, use_osr);
DECLARE_FLAG(bool, throw_on_javascript_int_overflow);
DECLARE_FLAG(bool, use_slow_path);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(EAX));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps= 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* ReturnInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* LoadLocalInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t stack_index = (local().index() < 0)
      ? kFirstLocalSlotFromFp - local().index()
      : kParamEndSlotFromFp - local().index();
  return LocationSummary::Make(kNumInputs,
                               Location::StackSlot(stack_index),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  // Nothing to do.
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movl(Address(EBP, local().index() * kWordSize), value);
}


LocationSummary* ConstantInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out().IsInvalid()) {
    Register result = locs()->out().reg();
    __ LoadObjectSafely(result, value());
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));  // Value.
  summary->set_in(1, Location::RegisterLocation(ECX));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(EDX));  // Type arguments.
  summary->set_out(Location::RegisterLocation(EAX));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
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
  Register result = locs()->out().reg();

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


LocationSummary* EqualityCompareInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    // Only right can be a stack slot.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : Location::RegisterOrConstant(right()));
    locs->set_out(Location::RequiresRegister());
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
                                           XmmRegister result,
                                           Register tmp) {
  // Compare upper half.
  Label check_lower, done;
  __ pextrd(tmp, result, Immediate(1));
  __ cmpl(tmp, Immediate(0x00200000));
  __ j(GREATER, overflow);
  __ j(NOT_EQUAL, &check_lower);

  __ pextrd(tmp, result, Immediate(0));
  __ cmpl(tmp, Immediate(0));
  __ j(ABOVE, overflow);

  __ Bind(&check_lower);
  __ pextrd(tmp, result, Immediate(1));
  __ cmpl(tmp, Immediate(-0x00200000));
  __ j(LESS, overflow);
  // Anything in the lower part would make the number bigger than the lower
  // bound, so we are done.

  __ Bind(&done);
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
  XmmRegister left = locs.in(0).fpu_reg();
  XmmRegister right = locs.in(1).fpu_reg();
  Register temp = locs.temp(0).reg();
  __ movaps(XMM0, left);
  __ pcmpeqq(XMM0, right);
  __ movd(temp, XMM0);

  Condition true_condition = TokenKindToMintCondition(kind);
  __ cmpl(temp, Immediate(-1));
  return true_condition;
}


static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             const LocationSummary& locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  XmmRegister left = locs.in(0).fpu_reg();
  XmmRegister right = locs.in(1).fpu_reg();
  Register left_tmp = locs.temp(0).reg();
  Register right_tmp = locs.temp(1).reg();

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
  __ pextrd(left_tmp, left, Immediate(1));
  __ pextrd(right_tmp, right, Immediate(1));
  __ cmpl(left_tmp, right_tmp);
  __ j(hi_cond, labels.true_label);
  __ j(FlipCondition(hi_cond), labels.false_label);

  // If upper is equal, compare lower half.
  __ pextrd(left_tmp, left, Immediate(0));
  __ pextrd(right_tmp, right, Immediate(0));
  __ cmpl(left_tmp, right_tmp);
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

  Register result = locs()->out().reg();
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


LocationSummary* TestSmiInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* RelationalOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 2;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_temp(1, Location::RequiresRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterOrConstant(left()));
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  summary->set_in(1, summary->in(0).IsConstant()
                         ? Location::RequiresRegister()
                         : Location::RegisterOrConstant(right()));
  summary->set_out(Location::RequiresRegister());
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

  Register result = locs()->out().reg();
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


LocationSummary* NativeCallInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(EAX));
  locs->set_temp(1, Location::RegisterLocation(ECX));
  locs->set_temp(2, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EAX);
  ASSERT(locs()->temp(1).reg() == ECX);
  ASSERT(locs()->temp(2).reg() == EDX);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in EAX.
  if (!function().HasOptionalParameters()) {
    __ leal(EAX, Address(EBP, (kParamEndSlotFromFp +
                               function().NumParameters()) * kWordSize));
  } else {
    __ leal(EAX, Address(EBP, kFirstLocalSlotFromFp * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movl(EDX, Immediate(NativeArguments::ComputeArgcTag(function())));
  const ExternalLabel* stub_entry =
      (is_bootstrap_native()) ? &StubCode::CallBootstrapCFunctionLabel() :
                                &StubCode::CallNativeCFunctionLabel();
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         PcDescriptors::kOther,
                         locs());
  __ popl(result);
}


static bool CanBeImmediateIndex(Value* value, intptr_t cid) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == NULL) || !Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = FlowGraphCompiler::ElementSizeFor(cid);
  const intptr_t offset = FlowGraphCompiler::DataOffsetFor(cid);
  const int64_t displacement = index * scale + offset;
  return Utils::IsInt(32, displacement);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out().reg();
  __ movl(result,
          Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(result, Address(result,
                          char_code,
                          TIMES_HALF_WORD_SIZE,  // Char code is a smi.
                          Symbols::kNullCharCodeSymbolOffset * kWordSize));
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(cid_ == kOneByteStringCid);
  Register str = locs()->in(0).reg();
  Register result = locs()->out().reg();
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


LocationSummary* StringInterpolateInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_out(Location::RegisterLocation(EAX));
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
                               locs());
  ASSERT(locs()->out().reg() == EAX);
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out().reg();
  __ movl(result, FieldAddress(object, offset()));
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out().reg();
  Label load, done;
  __ testl(object, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &load, Assembler::kNearJump);
  __ movl(result, Immediate(Smi::RawValue(kSmiCid)));
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
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // Result can be Smi or Mint when boxed.
      // Instruction can deoptimize if we optimistically assumed that the result
      // fits into Smi.
      return CanDeoptimize() ? CompileType::FromCid(kSmiCid)
                             : CompileType::Int();

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
      // Instruction can deoptimize if we optimistically assumed that the result
      // fits into Smi.
      return CanDeoptimize() ? kTagged : kUnboxedMint;
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


LocationSummary* LoadIndexedInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    locs->set_out(Location::RequiresFpuRegister());
  } else {
    locs->set_out(Location::RequiresRegister());
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  Location index = locs()->in(1);

  Address element_address(kNoRegister, 0);
  if (IsExternal()) {
    element_address = index.IsRegister()
        ? FlowGraphCompiler::ExternalElementAddressForRegIndex(
            index_scale(), array, index.reg())
        : FlowGraphCompiler::ExternalElementAddressForIntIndex(
            index_scale(), array, Smi::Cast(index.constant()).Value());
  } else {
    ASSERT(this->array()->definition()->representation() == kTagged);
    element_address = index.IsRegister()
        ? FlowGraphCompiler::ElementAddressForRegIndex(
            class_id(), index_scale(), array, index.reg())
        : FlowGraphCompiler::ElementAddressForIntIndex(
            class_id(), index_scale(), array,
            Smi::Cast(index.constant()).Value());
  }

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedMint) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    XmmRegister result = locs()->out().fpu_reg();
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        __ movss(result, element_address);
        __ pmovsxdq(result, result);
        break;
      case kTypedDataUint32ArrayCid:
        __ xorpd(result, result);
        __ movss(result, element_address);
        break;
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
    }
    return;
  }

  Register result = locs()->out().reg();
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
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptInt32Load);
        __ movl(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ cmpl(result, Immediate(0xC0000000));
        __ j(NEGATIVE, deopt);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptUint32Load);
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


LocationSummary* StoreIndexedInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
      // Mints are stored in XMM registers. For smis, use a writable register
      // because the value must be untagged before storing.
      locs->set_in(2, value()->IsSmiValue()
                      ? Location::WritableRegister()
                      : Location::RequiresFpuRegister());
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
  Register array = locs()->in(0).reg();
  Location index = locs()->in(1);

  Address element_address(kNoRegister, 0);
  if (IsExternal()) {
    element_address = index.IsRegister()
        ? FlowGraphCompiler::ExternalElementAddressForRegIndex(
            index_scale(), array, index.reg())
        : FlowGraphCompiler::ExternalElementAddressForIntIndex(
            index_scale(), array, Smi::Cast(index.constant()).Value());
  } else {
    ASSERT(this->array()->definition()->representation() == kTagged);
    element_address = index.IsRegister()
        ? FlowGraphCompiler::ElementAddressForRegIndex(
          class_id(), index_scale(), array, index.reg())
        : FlowGraphCompiler::ElementAddressForIntIndex(
          class_id(), index_scale(), array,
          Smi::Cast(index.constant()).Value());
  }

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
      __ movss(element_address, locs()->in(2).fpu_reg());
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


LocationSummary* GuardFieldInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, 0, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  const bool field_has_length = field().needs_length_check();
  const bool need_value_temp_reg =
      (field_has_length || ((value()->Type()->ToCid() == kDynamicCid) &&
                            (field().guarded_cid() != kSmiCid)));
  if (need_value_temp_reg) {
    summary->AddTemp(Location::RequiresRegister());
  }
  const bool need_field_temp_reg =
      field_has_length || (field().guarded_cid() == kIllegalCid);
  if (need_field_temp_reg) {
    summary->AddTemp(Location::RequiresRegister());
  }
  return summary;
}


void GuardFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;
  const intptr_t field_length = field().guarded_list_length();
  const bool field_has_length = field().needs_length_check();
  const bool needs_value_temp_reg =
      (field_has_length || ((value()->Type()->ToCid() == kDynamicCid) &&
                            (field().guarded_cid() != kSmiCid)));
  const bool needs_field_temp_reg =
      field_has_length || (field().guarded_cid() == kIllegalCid);
  if (field_has_length) {
    // Currently, we should only see final fields that remember length.
    ASSERT(field().is_final());
  }

  if (field_cid == kDynamicCid) {
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }
  const intptr_t value_cid = value()->Type()->ToCid();

  Register value_reg = locs()->in(0).reg();

  Register value_cid_reg = needs_value_temp_reg ?
      locs()->temp(0).reg() : kNoRegister;

  Register field_reg = needs_field_temp_reg ?
      locs()->temp(locs()->temp_count() - 1).reg() : kNoRegister;

  Label ok, fail_label;

  Label* deopt = compiler->is_optimizing() ?
      compiler->AddDeoptStub(deopt_id(), kDeoptGuardField) : NULL;

  Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (!compiler->is_optimizing() || (field_cid == kIllegalCid)) {
    if (!compiler->is_optimizing() && (field_reg == kNoRegister)) {
      // Currently we can't have different location summaries for optimized
      // and non-optimized code. So instead we manually pick up a register
      // that is known to be free because we know how non-optimizing compiler
      // allocates registers.
      field_reg = EBX;
      ASSERT((field_reg != value_reg) && (field_reg != value_cid_reg));
    }

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());
    FieldAddress field_length_operand(
        field_reg, Field::guarded_list_length_offset());

    if (value_cid == kDynamicCid) {
      if (value_cid_reg == kNoRegister) {
        ASSERT(!compiler->is_optimizing());
        value_cid_reg = EDX;
        ASSERT((value_cid_reg != value_reg) && (field_reg != value_cid_reg));
      }

      LoadValueCid(compiler, value_cid_reg, value_reg);
      Label skip_length_check;
      __ cmpl(value_cid_reg, field_cid_operand);
      // Value CID != Field guard CID, skip length check.
      __ j(NOT_EQUAL, &skip_length_check);
      if (field_has_length) {
        // Field guard may have remembered list length, check it.
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          __ pushl(value_cid_reg);
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, Array::length_offset()));
          __ cmpl(value_cid_reg, Immediate(Smi::RawValue(field_length)));
          __ popl(value_cid_reg);
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          __ pushl(value_cid_reg);
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
          __ cmpl(value_cid_reg, Immediate(Smi::RawValue(field_length)));
          __ popl(value_cid_reg);
        } else {
          ASSERT(field_cid == kIllegalCid);
          ASSERT(field_length == Field::kUnknownFixedLength);
          // At compile time we do not know the type of the field nor its
          // length. At execution time we may have set the class id and
          // list length so we compare the guarded length with the
          // list length here, without this check the list length could change
          // without triggering a deoptimization.
          Label check_array, length_compared, no_fixed_length;
          // If length is negative the length guard is either disabled or
          // has not been initialized, either way it is safe to skip the
          // length check.
          __ cmpl(field_length_operand, Immediate(Smi::RawValue(0)));
          __ j(LESS, &skip_length_check);
          __ cmpl(value_cid_reg, Immediate(kNullCid));
          __ j(EQUAL, &no_fixed_length, Assembler::kNearJump);
          // Check for typed data array.
          __ cmpl(value_cid_reg, Immediate(kTypedDataInt32x4ArrayCid));
          // Not a typed array or a regular array.
          __ j(GREATER, &no_fixed_length, Assembler::kNearJump);
          __ cmpl(value_cid_reg, Immediate(kTypedDataInt8ArrayCid));
          // Could still be a regular array.
          __ j(LESS, &check_array, Assembler::kNearJump);
          __ pushl(value_cid_reg);
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
          __ cmpl(field_length_operand, value_cid_reg);
          __ popl(value_cid_reg);
          __ jmp(&length_compared, Assembler::kNearJump);
          // Check for regular array.
          __ Bind(&check_array);
          __ cmpl(value_cid_reg, Immediate(kImmutableArrayCid));
          __ j(GREATER, &no_fixed_length, Assembler::kNearJump);
          __ cmpl(value_cid_reg, Immediate(kArrayCid));
          __ j(LESS, &no_fixed_length, Assembler::kNearJump);
          __ pushl(value_cid_reg);
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, Array::length_offset()));
          __ cmpl(field_length_operand, value_cid_reg);
          __ popl(value_cid_reg);
          __ jmp(&length_compared, Assembler::kNearJump);
          __ Bind(&no_fixed_length);
          __ jmp(fail);
          __ Bind(&length_compared);
        }
        __ j(NOT_EQUAL, fail);
      }
      __ Bind(&skip_length_check);
      __ cmpl(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      // Value in graph known to be null.
      // Compare with null.
      __ cmpl(field_nullability_operand, Immediate(value_cid));
    } else {
      // Value in graph known to be non-null.
      Label skip_length_check;
      // Compare class id with guard field class id.
      __ cmpl(field_cid_operand, Immediate(value_cid));
      // If not equal, skip over length check.
      __ j(NOT_EQUAL, &skip_length_check);
      // Insert length check.
      if (field_has_length) {
        ASSERT(value_cid_reg != kNoRegister);
        if ((value_cid == kArrayCid) || (value_cid == kImmutableArrayCid)) {
          __ cmpl(FieldAddress(value_reg, Array::length_offset()),
                  Immediate(Smi::RawValue(field_length)));
        } else if (RawObject::IsTypedDataClassId(value_cid)) {
          __ cmpl(FieldAddress(value_reg, TypedData::length_offset()),
                  Immediate(Smi::RawValue(field_length)));
        } else if (field_cid != kIllegalCid) {
          ASSERT(field_cid != value_cid);
          ASSERT(field_length >= 0);
          // Field has a known class id and length. At compile time it is
          // known that the value's class id is not a fixed length list.
          __ jmp(fail);
        } else {
          ASSERT(field_cid == kIllegalCid);
          ASSERT(field_length == Field::kUnknownFixedLength);
          // Following jump cannot not occur, fall through.
        }
        __ j(NOT_EQUAL, fail);
      }
      // Not identical, possibly null.
      __ Bind(&skip_length_check);
    }
    // Jump when class id guard and list length guard are okay.
    __ j(EQUAL, &ok);

    // Check if guard field is uninitialized.
    __ cmpl(field_cid_operand, Immediate(kIllegalCid));
    // Jump to failure path when guard field has been initialized and
    // the field and value class ids do not not match.
    __ j(NOT_EQUAL, fail);

    // At this point the field guard is being initialized for the first time.
    if (value_cid == kDynamicCid) {
      // Do not know value's class id.
      __ movl(field_cid_operand, value_cid_reg);
      __ movl(field_nullability_operand, value_cid_reg);
      if (field_has_length) {
        Label check_array, length_set, no_fixed_length;
        __ cmpl(value_cid_reg, Immediate(kNullCid));
        __ j(EQUAL, &no_fixed_length, Assembler::kNearJump);
        // Check for typed data array.
        __ cmpl(value_cid_reg, Immediate(kTypedDataInt32x4ArrayCid));
        // Not a typed array or a regular array.
        __ j(GREATER, &no_fixed_length, Assembler::kNearJump);
        __ cmpl(value_cid_reg, Immediate(kTypedDataInt8ArrayCid));
        // Could still be a regular array.
        __ j(LESS, &check_array, Assembler::kNearJump);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ movl(value_cid_reg,
                FieldAddress(value_reg, TypedData::length_offset()));
        __ movl(field_length_operand, value_cid_reg);
        // Updated field length typed data array.
        __ jmp(&length_set, Assembler::kNearJump);
        // Check for regular array.
        __ Bind(&check_array);
        __ cmpl(value_cid_reg, Immediate(kImmutableArrayCid));
        __ j(GREATER, &no_fixed_length, Assembler::kNearJump);
        __ cmpl(value_cid_reg, Immediate(kArrayCid));
        __ j(LESS, &no_fixed_length, Assembler::kNearJump);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ movl(value_cid_reg,
                FieldAddress(value_reg, Array::length_offset()));
        __ movl(field_length_operand, value_cid_reg);
        // Updated field length from regular array.
        __ jmp(&length_set, Assembler::kNearJump);
        __ Bind(&no_fixed_length);
        __ movl(field_length_operand,
                Immediate(Smi::RawValue(Field::kNoFixedLength)));
        __ Bind(&length_set);
      }
    } else {
      ASSERT(field_reg != kNoRegister);
      __ movl(field_cid_operand, Immediate(value_cid));
      __ movl(field_nullability_operand, Immediate(value_cid));
      if (field_has_length) {
        ASSERT(value_cid_reg != kNoRegister);
        if ((value_cid == kArrayCid) || (value_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, Array::length_offset()));
          __ movl(field_length_operand, value_cid_reg);
        } else if (RawObject::IsTypedDataClassId(value_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
          __ movl(field_length_operand, value_cid_reg);
        } else {
          __ movl(field_length_operand,
                  Immediate(Smi::RawValue(Field::kNoFixedLength)));
        }
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ jmp(&ok);
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
    // Field guard class has been initialized and is known.
    if (field_reg != kNoRegister) {
      __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));
    }

    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testl(value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ cmpl(value_cid_reg, Immediate(field_cid));
      }

      if (field_has_length) {
        // Jump when Value CID != Field guard CID
        __ j(NOT_EQUAL, fail);

        // Classes are same, perform guarded list length check.
        ASSERT(field_reg != kNoRegister);
        ASSERT(value_cid_reg != kNoRegister);
        FieldAddress field_length_operand(
            field_reg, Field::guarded_list_length_offset());
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ cmpl(value_cid_reg, field_length_operand);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        const Immediate& raw_null =
            Immediate(reinterpret_cast<intptr_t>(Object::null()));
        __ cmpl(value_reg, raw_null);
      }
      __ j(NOT_EQUAL, fail);
    } else {
      // Both value's and field's class id is known.
      if ((value_cid != field_cid) && (value_cid != nullability)) {
        __ jmp(fail);
      } else if (field_has_length && (value_cid == field_cid)) {
        ASSERT(value_cid_reg != kNoRegister);
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ movl(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ cmpl(value_cid_reg, Immediate(Smi::RawValue(field_length)));
        __ j(NOT_EQUAL, fail);
      } else {
        UNREACHABLE();
      }
    }
  }
  __ Bind(&ok);
}


class StoreInstanceFieldSlowPath : public SlowPathCode {
 public:
  StoreInstanceFieldSlowPath(StoreInstanceFieldInstr* instruction,
                             const Class& cls)
      : instruction_(instruction), cls_(cls) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("StoreInstanceFieldSlowPath");
    __ Bind(entry_label());
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(cls_));
    const ExternalLabel label(cls_.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());
    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->temp(0).reg(), EAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
  }

 private:
  StoreInstanceFieldInstr* instruction_;
  const Class& cls_;
};


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps,
          !field().IsNull() &&
          ((field().guarded_cid() == kIllegalCid) || is_initialization_)
          ? LocationSummary::kCallOnSlowPath
          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->AddTemp(Location::RequiresRegister());
    summary->AddTemp(Location::RequiresRegister());
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier()
        ? Location::WritableRegister()
        :  Location::RequiresRegister());
    summary->AddTemp(Location::RequiresRegister());
    summary->AddTemp(Location::RequiresRegister());
    summary->AddTemp(opt ? Location::RequiresFpuRegister()
                         : Location::FpuRegisterLocation(XMM1));
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                       ? Location::WritableRegister()
                       : Location::RegisterOrConstant(value()));
  }
  return summary;
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
        default:
          UNREACHABLE();
      }

      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, *cls);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(*cls,
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
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

    Label store_pointer;
    Label store_double;
    Label store_float32x4;

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

    // Fall through.
    __ jmp(&store_pointer);


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

      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes_));
      __ cmpl(temp, raw_null);
      __ j(NOT_EQUAL, &copy_double);

      __ TryAllocate(compiler->double_class(),
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ movl(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);

      __ Bind(&copy_double);
      __ movsd(fpu_temp, FieldAddress(value_reg, Double::value_offset()));
      __ movsd(FieldAddress(temp, Double::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      Label copy_float32x4;

      StoreInstanceFieldSlowPath* slow_path =
          new StoreInstanceFieldSlowPath(this, compiler->float32x4_class());
      compiler->AddSlowPathCode(slow_path);

      const Immediate& raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes_));
      __ cmpl(temp, raw_null);
      __ j(NOT_EQUAL, &copy_float32x4);

      __ TryAllocate(compiler->float32x4_class(),
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ movl(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);

      __ Bind(&copy_float32x4);
      __ movups(fpu_temp, FieldAddress(value_reg, Float32x4::value_offset()));
      __ movups(FieldAddress(temp, Float32x4::value_offset()), fpu_temp);
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


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // By specifying same register as input, our simple register allocator can
  // generate better code.
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


// When the parser is building an implicit static getter for optimization,
// it can generate a function body where deoptimization ids do not line up
// with the unoptimized code.
//
// This is safe only so long as LoadStaticFieldInstr cannot deoptimize.
void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register result = locs()->out().reg();
  __ movl(result, FieldAddress(field, Field::value_offset()));
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(bool opt) const {
  LocationSummary* locs = new LocationSummary(1, 1, LocationSummary::kNoCall);
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


LocationSummary* InstanceOfInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_out(Location::RegisterLocation(EAX));
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
  ASSERT(locs()->out().reg() == EAX);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_in(1, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  EDX = length, ECX = element type.
  ASSERT(locs()->in(0).reg() == ECX);
  ASSERT(locs()->in(1).reg() == EDX);
  compiler->GenerateCall(token_pos(),
                         &StubCode::AllocateArrayLabel(),
                         PcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out().reg() == EAX);
}


class BoxDoubleSlowPath : public SlowPathCode {
 public:
  explicit BoxDoubleSlowPath(Instruction* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxDoubleSlowPath");
    __ Bind(entry_label());
    const Class& double_class = compiler->double_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class));
    const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
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
    const Class& float32x4_class = compiler->float32x4_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(float32x4_class));
    const ExternalLabel label(float32x4_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
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
    const Class& float64x2_class = compiler->float64x2_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(float64x2_class));
    const ExternalLabel label(float64x2_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
  }

 private:
  Instruction* instruction_;
};


LocationSummary* LoadFieldInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(
          kNumInputs, kNumTemps,
          (opt && !IsPotentialUnboxedLoad())
          ? LocationSummary::kNoCall
          : LocationSummary::kCallOnSlowPath);

  locs->set_in(0, Location::RequiresRegister());

  if (IsUnboxedLoad() && opt) {
    locs->AddTemp(Location::RequiresRegister());
  } else if (IsPotentialUnboxedLoad()) {
    locs->AddTemp(opt ? Location::RequiresFpuRegister()
                      : Location::FpuRegisterLocation(XMM1));
    locs->AddTemp(Location::RequiresRegister());
  }
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    XmmRegister result = locs()->out().fpu_reg();
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
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  Register result = locs()->out().reg();
  if (IsPotentialUnboxedLoad()) {
    Register temp = locs()->temp(1).reg();
    XmmRegister value = locs()->temp(0).fpu_reg();


    Label load_pointer;
    Label load_double;
    Label load_float32x4;

    __ LoadObject(result, Field::ZoneHandle(field()->raw()));

    FieldAddress field_cid_operand(result, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result, Field::is_nullable_offset());

    __ cmpl(field_nullability_operand, Immediate(kNullCid));
    __ j(EQUAL, &load_pointer);

    __ cmpl(field_cid_operand, Immediate(kDoubleCid));
    __ j(EQUAL, &load_double);

    __ cmpl(field_cid_operand, Immediate(kFloat32x4Cid));
    __ j(EQUAL, &load_float32x4);

    // Fall through.
    __ jmp(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(compiler->double_class(),
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     result,
                     temp);
      __ Bind(slow_path->exit_label());
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movsd(value, FieldAddress(temp, Double::value_offset()));
      __ movsd(FieldAddress(result, Double::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float32x4);

      BoxFloat32x4SlowPath* slow_path = new BoxFloat32x4SlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(compiler->float32x4_class(),
                     slow_path->entry_label(),
                     Assembler::kFarJump,
                     result,
                     temp);
      __ Bind(slow_path->exit_label());
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float32x4::value_offset()));
      __ movups(FieldAddress(result, Float32x4::value_offset()), value);
      __ jmp(&done);
    }

    __ Bind(&load_pointer);
  }
  __ movl(result, FieldAddress(instance_reg, offset_in_bytes()));
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
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
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
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
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
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


LocationSummary* AllocateContextInstr::MakeLocationSummary(bool opt) const {
  if (opt) {
    const intptr_t kNumInputs = 0;
    const intptr_t kNumTemps = 2;
    LocationSummary* locs = new LocationSummary(
        kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
    locs->set_temp(0, Location::RegisterLocation(ECX));
    locs->set_temp(1, Location::RegisterLocation(EBX));
    locs->set_out(Location::RegisterLocation(EAX));
    return locs;
  }
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
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
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);

    __ movl(EDX, Immediate(instruction_->num_context_variables()));
    const ExternalLabel label("alloc_context",
                              StubCode::AllocateContextEntryPoint());
    compiler->GenerateCall(instruction_->token_pos(),
                           &label,
                           PcDescriptors::kOther,
                           locs);
    ASSERT(instruction_->locs()->out().reg() == EAX);
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
    Register result = locs()->out().reg();
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
        ? 0 : instance_size << (RawObject::kSizeTagBit - kObjectAlignmentLog2);

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
  ASSERT(locs()->out().reg() == EAX);

  __ movl(EDX, Immediate(num_context_variables()));
  const ExternalLabel label("alloc_context",
                            StubCode::AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
}


LocationSummary* CloneContextInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(context_value);
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ popl(result);  // Remove argument.
  __ popl(result);  // Get result (cloned context).
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(bool opt) const {
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


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
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
      compiler->AddCurrentDescriptor(PcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     0);  // No token position.
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ jmp(exit_label());
  }

 private:
  CheckStackOverflowInstr* instruction_;
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
    __ j(GREATER_EQUAL, slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}


static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const bool is_truncating = shift_left->is_truncating();
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out().reg();
  ASSERT(left == result);
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), kDeoptBinarySmiOp) : NULL;
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
      if ((value >=kCountLimit) && is_truncating) {
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
          (right_range == NULL) ||
          !right_range->IsWithin(0, RangeBoundary::kPlusInfinity);
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


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (RightIsPowerOfTwoConstant()) {
      summary->set_in(0, Location::RequiresRegister());
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      // The programmer only controls one bit, so the constant is safe.
      summary->set_in(1, Location::Constant(right_constant->value()));
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_out(Location::SameAsFirstInput());
    } else {
      // Both inputs must be writable because they will be untagged.
      summary->set_in(0, Location::RegisterLocation(EAX));
      summary->set_in(1, Location::WritableRegister());
      summary->set_out(Location::SameAsFirstInput());
      // Will be used for sign extension and division.
      summary->set_temp(0, Location::RegisterLocation(EDX));
    }
    return summary;
  } else if (op_kind() == Token::kMOD) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(EDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(EAX));
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    if (!is_truncating()) {
      summary->AddTemp(Location::RequiresRegister());
    }
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    ConstantInstr* constant = right()->definition()->AsConstant();
    if (constant != NULL) {
      summary->set_in(1, Location::RegisterOrSmiConstant(right()));
    } else {
      summary->set_in(1, Location::PrefersRegister());
    }
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  }
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  ASSERT(!is_truncating());
  Register left = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(left == result);
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt  = compiler->AddDeoptStub(deopt_id(), kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int32_t imm =
        reinterpret_cast<int32_t>(constant.raw());
    switch (op_kind()) {
      case Token::kADD:
        __ addl(left, Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      case Token::kSUB: {
        __ subl(left, Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
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
      } else if (right_range->IsWithin(0, RangeBoundary::kPlusInfinity)) {
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
          !right_range->IsWithin(RangeBoundary::kMinusInfinity, kCountLimit)) {
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


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const bool need_temp = (left_cid != kSmiCid) && (right_cid != kSmiCid);
  const intptr_t kNumTemps = need_temp ? 1 : 0;
  LocationSummary* summary =
    new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (need_temp) summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinaryDoubleOp);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (left_cid == kSmiCid) {
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





LocationSummary* BoxDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  __ TryAllocate(compiler->double_class(),
                 slow_path->entry_label(),
                 Assembler::kFarJump,
                 out_reg,
                 kNoRegister);
  __ Bind(slow_path->exit_label());
  __ movsd(FieldAddress(out_reg, Double::value_offset()), value);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t value_cid = value()->Type()->ToCid();
  const bool needs_temp = ((value_cid != kSmiCid) && (value_cid != kDoubleCid));
  const bool needs_writable_input = (value_cid == kSmiCid);
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, needs_writable_input
                     ? Location::WritableRegister()
                     : Location::RequiresRegister());
  if (needs_temp) summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().fpu_reg();

  if (value_cid == kDoubleCid) {
    __ movsd(result, FieldAddress(value, Double::value_offset()));
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ cvtsi2sd(result, value);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptBinaryDoubleOp);
    Register temp = locs()->temp(0).reg();
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


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat32x4SlowPath* slow_path = new BoxFloat32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  __ TryAllocate(compiler->float32x4_class(),
                 slow_path->entry_label(),
                 Assembler::kFarJump,
                 out_reg,
                 kNoRegister);
  __ Bind(slow_path->exit_label());
  __ movups(FieldAddress(out_reg, Float32x4::value_offset()), value);
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kFloat32x4Cid ? 0 : 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().fpu_reg();

  if (value_cid != kFloat32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat32x4Cid, temp);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Float32x4::value_offset()));
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat64x2SlowPath* slow_path = new BoxFloat64x2SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  __ TryAllocate(compiler->float64x2_class(),
                 slow_path->entry_label(),
                 Assembler::kFarJump,
                 out_reg,
                 kNoRegister);
  __ Bind(slow_path->exit_label());
  __ movups(FieldAddress(out_reg, Float64x2::value_offset()), value);
}


LocationSummary* UnboxFloat64x2Instr::MakeLocationSummary(bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kFloat64x2Cid ? 0 : 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().fpu_reg();

  if (value_cid != kFloat64x2Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kFloat64x2Cid, temp);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Float64x2::value_offset()));
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


class BoxInt32x4SlowPath : public SlowPathCode {
 public:
  explicit BoxInt32x4SlowPath(BoxInt32x4Instr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxInt32x4SlowPath");
    __ Bind(entry_label());
    const Class& int32x4_class = compiler->int32x4_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(int32x4_class));
    const ExternalLabel label(int32x4_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
  }

 private:
  BoxInt32x4Instr* instruction_;
};


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxInt32x4SlowPath* slow_path = new BoxInt32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  __ TryAllocate(compiler->int32x4_class(),
                 slow_path->entry_label(),
                 Assembler::kFarJump,
                 out_reg,
                 kNoRegister);
  __ Bind(slow_path->exit_label());
  __ movups(FieldAddress(out_reg, Int32x4::value_offset()), value);
}


LocationSummary* UnboxInt32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = value_cid == kInt32x4Cid ? 0 : 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (kNumTemps > 0) {
    ASSERT(kNumTemps == 1);
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().fpu_reg();

  if (value_cid != kInt32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
    __ CompareClassId(value, kInt32x4Cid, temp);
    __ j(NOT_EQUAL, deopt);
  }
  __ movups(result, FieldAddress(value, Int32x4::value_offset()));
}



LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addsd(left, right); break;
    case Token::kSUB: __ subsd(left, right); break;
    case Token::kMUL: __ mulsd(left, right); break;
    case Token::kDIV: __ divsd(left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addps(left, right); break;
    case Token::kSUB: __ subps(left, right); break;
    case Token::kMUL: __ mulps(left, right); break;
    case Token::kDIV: __ divps(left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == value);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleX:
      __ shufps(value, value, Immediate(0x00));
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


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);
  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
      __ shufps(left, right, Immediate(mask_));
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  Register out = locs()->out().reg();

  __ movmskps(out, value);
  __ SmiTag(out);
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_in(3, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister v0 = locs()->in(0).fpu_reg();
  XmmRegister v1 = locs()->in(1).fpu_reg();
  XmmRegister v2 = locs()->in(2).fpu_reg();
  XmmRegister v3 = locs()->in(3).fpu_reg();
  ASSERT(v0 == locs()->out().fpu_reg());
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


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out().fpu_reg();
  __ xorps(value, value);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->out().fpu_reg();
  ASSERT(locs()->in(0).fpu_reg() == locs()->out().fpu_reg());
  // Convert to Float32.
  __ cvtsd2ss(value, value);
  // Splat across all lanes.
  __ shufps(value, value, Immediate(0x00));
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

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


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

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


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Scale:
      __ cvtsd2ss(left, left);
      __ shufps(left, left, Immediate(0x00));
      __ mulps(left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

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


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);
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


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister lower = locs()->in(1).fpu_reg();
  XmmRegister upper = locs()->in(2).fpu_reg();
  ASSERT(locs()->out().fpu_reg() == left);
  __ minps(left, upper);
  __ maxps(left, lower);
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister replacement = locs()->in(0).fpu_reg();
  XmmRegister value = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == replacement);

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


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // NOP.
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register v0 = locs()->in(0).reg();
  Register v1 = locs()->in(1).reg();
  Register v2 = locs()->in(2).reg();
  Register v3 = locs()->in(3).reg();
  XmmRegister result = locs()->out().fpu_reg();
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


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  Register result = locs()->out().reg();
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


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister mask = locs()->in(0).fpu_reg();
  XmmRegister trueValue = locs()->in(1).fpu_reg();
  XmmRegister falseValue = locs()->in(2).fpu_reg();
  XmmRegister out = locs()->out().fpu_reg();
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


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister mask = locs()->in(0).fpu_reg();
  Register flag = locs()->in(1).reg();
  ASSERT(mask == locs()->out().fpu_reg());
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


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // NOP.
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();
  ASSERT(left == locs()->out().fpu_reg());
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


LocationSummary* MathUnaryInstr::MakeLocationSummary(bool opt) const {
  if ((kind() == MethodRecognizer::kMathSin) ||
      (kind() == MethodRecognizer::kMathCos)) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(XMM1));
    // EDI is chosen because it is callee saved so we do not need to back it
    // up before calling into the runtime.
    summary->set_temp(0, Location::RegisterLocation(EDI));
    summary->set_out(Location::FpuRegisterLocation(XMM1));
    return summary;
  }
  ASSERT(kind() == MethodRecognizer::kMathSqrt);
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (kind() == MethodRecognizer::kMathSqrt) {
    __ sqrtsd(locs()->out().fpu_reg(), locs()->in(0).fpu_reg());
  } else {
    ASSERT((kind() == MethodRecognizer::kMathSin) ||
           (kind() == MethodRecognizer::kMathCos));
    // Save ESP.
    __ movl(locs()->temp(0).reg(), ESP);
    __ ReserveAlignedFrameSpace(kDoubleSize * InputCount());
    __ movsd(Address(ESP, 0), locs()->in(0).fpu_reg());
    __ CallRuntime(TargetFunction(), InputCount());
    __ fstpl(Address(ESP, 0));
    __ movsd(locs()->out().fpu_reg(), Address(ESP, 0));
    // Restore ESP.
    __ movl(ESP, locs()->temp(0).reg());
  }
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary(bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    // Reuse the left register so that code can be made shorter.
    summary->set_out(Location::SameAsFirstInput());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }

  ASSERT(result_cid() == kSmiCid);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  // Reuse the left register so that code can be made shorter.
  summary->set_out(Location::SameAsFirstInput());
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
    XmmRegister result = locs()->out().fpu_reg();
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
  Register result = locs()->out().reg();
  __ cmpl(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgel(result, right);
  } else {
    __ cmovlessl(result, right);
  }
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out().reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                            kDeoptUnaryOp);
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


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(locs()->out().fpu_reg() == value);
  __ DoubleNegate(value);
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::WritableRegister());
  result->set_out(Location::RequiresFpuRegister());
  return result;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out().fpu_reg();
  __ SmiUntag(value);
  __ cvtsi2sd(result, value);
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(ECX));
  result->set_out(Location::RegisterLocation(EAX));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
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
                               Object::null_array(),  // No argument names.,
                               locs());
  __ Bind(&done);
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new LocationSummary(
      kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptDoubleToSmi);
  Register result = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();
  __ cvttsd2si(result, value);
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, Immediate(0xC0000000));
  __ j(NEGATIVE, deopt);
  __ SmiTag(result);
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(Location::RequiresFpuRegister());
  return result;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  XmmRegister result = locs()->out().fpu_reg();
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


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(Location::SameAsFirstInput());
  return result;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtsd2ss(locs()->out().fpu_reg(), locs()->in(0).fpu_reg());
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(Location::SameAsFirstInput());
  return result;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ cvtss2sd(locs()->out().fpu_reg(), locs()->in(0).fpu_reg());
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(InputCount(), kNumTemps, LocationSummary::kCall);
  // EDI is chosen because it is callee saved so we do not need to back it
  // up before calling into the runtime.
  result->set_temp(0, Location::RegisterLocation(EDI));
  result->set_in(0, Location::FpuRegisterLocation(XMM1));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM2));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Temp index 1.
    result->AddTemp(Location::RegisterLocation(EAX));
    // Temp index 2.
    result->AddTemp(Location::FpuRegisterLocation(XMM4));
  }
  result->set_out(Location::FpuRegisterLocation(XMM3));
  return result;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Save ESP.
  __ movl(locs()->temp(kSavedSpTempIndex).reg(), ESP);
  __ ReserveAlignedFrameSpace(kDoubleSize * InputCount());
  for (intptr_t i = 0; i < InputCount(); i++) {
    __ movsd(Address(ESP, kDoubleSize * i), locs()->in(i).fpu_reg());
  }
  Label do_call, skip_call;
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Pseudo code:
    // if (exponent == 0.0) return 1.0;
    // if (base == 1.0) return 1.0;
    // if (base.isNaN || exponent.isNaN) {
    //    return double.NAN;
    // }
    XmmRegister base = locs()->in(0).fpu_reg();
    XmmRegister exp = locs()->in(1).fpu_reg();
    XmmRegister result = locs()->out().fpu_reg();
    Register temp = locs()->temp(kObjectTempIndex).reg();
    XmmRegister zero_temp = locs()->temp(kDoubleTempIndex).fpu_reg();

    Label check_base_is_one;
    // Check if exponent is 0.0 -> return 1.0;
    __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0)));
    __ movsd(zero_temp, FieldAddress(temp, Double::value_offset()));
    __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1)));
    __ movsd(result, FieldAddress(temp, Double::value_offset()));
    // 'result' contains 1.0.
    __ comisd(exp, zero_temp);
    __ j(PARITY_EVEN, &check_base_is_one, Assembler::kNearJump);  // NaN.
    __ j(EQUAL, &skip_call, Assembler::kNearJump);  // exp is 0, result is 1.0.

    Label base_is_nan;
    __ Bind(&check_base_is_one);
    __ comisd(base, result);
    __ j(PARITY_EVEN, &base_is_nan, Assembler::kNearJump);
    __ j(EQUAL, &skip_call, Assembler::kNearJump);  // base and result are 1.0
    __ jmp(&do_call, Assembler::kNearJump);

    __ Bind(&base_is_nan);
    // Returns NaN.
    __ movsd(result, base);
    __ jmp(&skip_call, Assembler::kNearJump);
    // exp is Nan case is handled correctly in the C-library.
  }
  __ Bind(&do_call);
  __ CallRuntime(TargetFunction(), InputCount());
  __ fstpl(Address(ESP, 0));
  __ movsd(locs()->out().fpu_reg(), Address(ESP, 0));
  __ Bind(&skip_call);
  // Restore ESP.
  __ movl(ESP, locs()->temp(kSavedSpTempIndex).reg());
}


LocationSummary* MergedMathInstr::MakeLocationSummary(bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(Location::RequiresRegister());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(EDX));
    return summary;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(XMM1));
    summary->set_out(Location::RegisterLocation(EAX));
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
    deopt  = compiler->AddDeoptStub(deopt_id(), kDeoptBinarySmiOp);
  }

  if (kind() == MergedMathInstr::kTruncDivMod) {
    Register left = locs()->in(0).reg();
    Register right = locs()->in(1).reg();
    Register result = locs()->out().reg();
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
      // Handle divide by zero in runtime.
      __ testl(right, right);
      __ j(ZERO, deopt);
    }
    ASSERT(left == EAX);
    ASSERT((right != EDX) && (right != EAX));
    ASSERT(locs()->temp(0).reg() == EDX);
    ASSERT((result != EDX) && (result != EAX));
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
    } else if (right_range->IsWithin(0, RangeBoundary::kPlusInfinity)) {
      // Right is positive.
      __ addl(EDX, right);
    } else {
      // Right is negative.
      __ subl(EDX, right);
    }
    __ Bind(&done);

    __ LoadObject(result, Array::ZoneHandle(Array::New(2, Heap::kOld)));
    const intptr_t index_scale = FlowGraphCompiler::ElementSizeFor(kArrayCid);
    Address trunc_div_address(
        FlowGraphCompiler::ElementAddressForIntIndex(
            kArrayCid, index_scale, result,
            MergedMathInstr::ResultIndexOf(Token::kTRUNCDIV)));
    Address mod_address(
        FlowGraphCompiler::ElementAddressForIntIndex(
            kArrayCid, index_scale, result,
            MergedMathInstr::ResultIndexOf(Token::kMOD)));
    __ SmiTag(EAX);
    __ SmiTag(EDX);
    __ StoreIntoObjectNoBarrier(result, trunc_div_address, EAX);
    __ StoreIntoObjectNoBarrier(result, mod_address, EDX);
    return;
  }

  if (kind() == MergedMathInstr::kSinCos) {
    // Do x87 sincos, since the ia32 compilers may not fuse sin/cos into
    // sincos.
    __ pushl(EAX);
    __ pushl(EAX);
    __ movsd(Address(ESP, 0), locs()->in(0).fpu_reg());
    __ fldl(Address(ESP, 0));
    __ fsincos();
    __ fstpl(Address(ESP, 0));
    __ movsd(XMM1, Address(ESP, 0));
    __ fstpl(Address(ESP, 0));
    __ movsd(XMM0, Address(ESP, 0));
    __ addl(ESP, Immediate(2 * kWordSize));

    Register result = locs()->out().reg();
    const TypedData& res_array = TypedData::ZoneHandle(
      TypedData::New(kTypedDataFloat64ArrayCid, 2, Heap::kOld));
    __ LoadObject(result, res_array);
    const intptr_t index_scale =
        FlowGraphCompiler::ElementSizeFor(kTypedDataFloat64ArrayCid);
    Address sin_address(
        FlowGraphCompiler::ElementAddressForIntIndex(
            kTypedDataFloat64ArrayCid, index_scale, result,
            MergedMathInstr::ResultIndexOf(MethodRecognizer::kMathSin)));
    Address cos_address(
        FlowGraphCompiler::ElementAddressForIntIndex(
            kTypedDataFloat64ArrayCid, index_scale, result,
            MergedMathInstr::ResultIndexOf(MethodRecognizer::kMathCos)));
    __ movsd(sin_address, XMM0);
    __ movsd(cos_address, XMM1);
    return;
  }

  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    bool opt) const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptPolymorphicInstanceCallTestFail);
  if (ic_data().NumberOfChecks() == 0) {
    __ jmp(deopt);
    return;
  }
  ASSERT(ic_data().num_args_tested() == 1);
  if (!with_checks()) {
    ASSERT(ic_data().HasOneTarget());
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(deopt_id(),
                                 instance_call()->token_pos(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs());
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


LocationSummary* BranchInstr::MakeLocationSummary(bool opt) const {
  comparison()->InitializeLocationSummary(opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(Location::NoLocation());
  return comparison()->locs();
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->AddTemp(Location::RequiresRegister());
  }
  return summary;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const DeoptReasonId deopt_reason =
      licm_hoisted_ ? kDeoptHoistedCheckClass : kDeoptCheckClass;
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
  __ Bind(&is_ok);
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckSmi);
  __ testl(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);
}


// Length: register or constant.
// Index: register, constant or stack slot.
LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptCheckArrayBound);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);

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
    __ jmp(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Object& index = Smi::Cast(index_loc.constant());
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


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t value_cid = value()->Type()->ToCid();
  const bool needs_temp = ((value_cid != kSmiCid) && (value_cid != kMintCid));
  const bool needs_writable_input = (value_cid == kSmiCid);
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, needs_writable_input
                     ? Location::WritableRegister()
                     : Location::RequiresRegister());
  if (needs_temp) summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().fpu_reg();

  if (value_cid == kMintCid) {
    __ movsd(result, FieldAddress(value, Mint::value_offset()));
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ movd(result, value);
    __ pmovsxdq(result, result);
  } else {
    Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptUnboxInteger);
    Label is_smi, done;
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, &is_smi);
    __ CompareClassId(value, kMintCid, temp);
    __ j(NOT_EQUAL, deopt);
    __ movsd(result, FieldAddress(value, Mint::value_offset()));
    __ jmp(&done);
    __ Bind(&is_smi);
    __ movl(temp, value);
    __ SmiUntag(temp);
    __ movd(result, temp);
    __ pmovsxdq(result, result);
    __ Bind(&done);
  }
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 2;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RegisterLocation(EAX));
  summary->set_temp(1, Location::RegisterLocation(EDX));
  // TODO(fschneider): Save one temp by using result register as a temp.
  summary->set_out(Location::RequiresRegister());
  return summary;
}


class BoxIntegerSlowPath : public SlowPathCode {
 public:
  explicit BoxIntegerSlowPath(BoxIntegerInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("BoxIntegerSlowPath");
    __ Bind(entry_label());
    const Class& mint_class =
        Class::ZoneHandle(Isolate::Current()->object_store()->mint_class());
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(mint_class));
    const ExternalLabel label(mint_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    __ MoveRegister(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
  }

 private:
  BoxIntegerInstr* instruction_;
};


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxIntegerSlowPath* slow_path = new BoxIntegerSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  // Unboxed operations produce smis or mint-sized values.
  // Check if value fits into a smi.
  Label not_smi, done;
  __ pextrd(EDX, value, Immediate(1));  // Upper half.
  __ pextrd(EAX, value, Immediate(0));  // Lower half.
  // 1. Compute (x + -kMinSmi) which has to be in the range
  //    0 .. -kMinSmi+kMaxSmi for x to fit into a smi.
  __ addl(EAX, Immediate(0x40000000));
  __ adcl(EDX, Immediate(0));
  // 2. Unsigned compare to -kMinSmi+kMaxSmi.
  __ cmpl(EAX, Immediate(0x80000000));
  __ sbbl(EDX, Immediate(0));
  __ j(ABOVE_EQUAL, &not_smi);
  // 3. Restore lower half if result is a smi.
  __ subl(EAX, Immediate(0x40000000));

  __ SmiTag(EAX);
  __ movl(out_reg, EAX);
  __ jmp(&done);

  __ Bind(&not_smi);
  __ TryAllocate(
      Class::ZoneHandle(Isolate::Current()->object_store()->mint_class()),
      slow_path->entry_label(),
      Assembler::kFarJump,
      out_reg,
      kNoRegister);
  __ Bind(slow_path->exit_label());
  __ movsd(FieldAddress(out_reg, Mint::value_offset()), value);
  __ Bind(&done);
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR: {
      const intptr_t kNumTemps =
          FLAG_throw_on_javascript_int_overflow ? 1 : 0;
      LocationSummary* summary =
          new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::RequiresFpuRegister());
      summary->set_in(1, Location::RequiresFpuRegister());
      if (FLAG_throw_on_javascript_int_overflow) {
        summary->set_temp(0, Location::RequiresRegister());
      }
      summary->set_out(Location::SameAsFirstInput());
      return summary;
    }
    case Token::kADD:
    case Token::kSUB: {
      const intptr_t kNumTemps = 2;
      LocationSummary* summary =
          new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, Location::RequiresFpuRegister());
      summary->set_in(1, Location::RequiresFpuRegister());
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_temp(1, Location::RequiresRegister());
      summary->set_out(Location::SameAsFirstInput());
      return summary;
    }
    default:
      UNREACHABLE();
      return NULL;
  }
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out().fpu_reg() == left);

  Label* deopt = NULL;
  if (FLAG_throw_on_javascript_int_overflow) {
    deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinaryMintOp);
  }
  switch (op_kind()) {
    case Token::kBIT_AND: __ andpd(left, right); break;
    case Token::kBIT_OR:  __ orpd(left, right); break;
    case Token::kBIT_XOR: __ xorpd(left, right); break;
    case Token::kADD:
    case Token::kSUB: {
      Register lo = locs()->temp(0).reg();
      Register hi = locs()->temp(1).reg();
      if (!FLAG_throw_on_javascript_int_overflow) {
        deopt  = compiler->AddDeoptStub(deopt_id(), kDeoptBinaryMintOp);
      }

      Label done, overflow;
      __ pextrd(lo, right, Immediate(0));  // Lower half
      __ pextrd(hi, right, Immediate(1));  // Upper half
      __ subl(ESP, Immediate(2 * kWordSize));
      __ movq(Address(ESP, 0), left);
      if (op_kind() == Token::kADD) {
        __ addl(Address(ESP, 0), lo);
        __ adcl(Address(ESP, 1 * kWordSize), hi);
      } else {
        __ subl(Address(ESP, 0), lo);
        __ sbbl(Address(ESP, 1 * kWordSize), hi);
      }
      __ j(OVERFLOW, &overflow);
      __ movq(left, Address(ESP, 0));
      __ addl(ESP, Immediate(2 * kWordSize));
      __ jmp(&done);
      __ Bind(&overflow);
      __ addl(ESP, Immediate(2 * kWordSize));
      __ jmp(deopt);
      __ Bind(&done);
      break;
    }
    default: UNREACHABLE();
  }
  if (FLAG_throw_on_javascript_int_overflow) {
    Register tmp = locs()->temp(0).reg();
    EmitJavascriptIntOverflowCheck(compiler, deopt, left, tmp);
  }
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = op_kind() == Token::kSHL ? 2 : 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_temp(0, Location::RequiresRegister());
  if (op_kind() == Token::kSHL) {
    summary->set_temp(1, Location::RequiresRegister());
  }
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  ASSERT(locs()->in(1).reg() == ECX);
  ASSERT(locs()->out().fpu_reg() == left);

  Label* deopt  = compiler->AddDeoptStub(deopt_id(),
                                         kDeoptShiftMintOp);
  Label done;
  __ testl(ECX, ECX);
  __ j(ZERO, &done);  // Shift by 0 is a nop.
  __ subl(ESP, Immediate(2 * kWordSize));
  __ movq(Address(ESP, 0), left);
  // Deoptimize if shift count is > 31.
  // sarl operation masks the count to 5 bits and
  // shrd is undefined with count > operand size (32)
  // TODO(fschneider): Support shift counts > 31 without deoptimization.
  __ SmiUntag(ECX);
  const Immediate& kCountLimit = Immediate(31);
  __ cmpl(ECX, kCountLimit);
  __ j(ABOVE, deopt);
  switch (op_kind()) {
    case Token::kSHR: {
      Register temp = locs()->temp(0).reg();
      __ movl(temp, Address(ESP, 1 * kWordSize));  // High half.
      __ shrd(Address(ESP, 0), temp);  // Shift count in CL.
      __ sarl(Address(ESP, 1 * kWordSize), ECX);  // Shift count in CL.
      break;
    }
    case Token::kSHL: {
      Register temp1 = locs()->temp(0).reg();
      Register temp2 = locs()->temp(1).reg();
      __ movl(temp1, Address(ESP, 0 * kWordSize));  // Low 32 bits.
      __ movl(temp2, Address(ESP, 1 * kWordSize));  // High 32 bits.
      __ shll(Address(ESP, 0 * kWordSize), ECX);  // Shift count in CL.
      __ shld(Address(ESP, 1 * kWordSize), temp1);  // Shift count in CL.
      // Check for overflow by shifting back the high 32 bits
      // and comparing with the input.
      __ movl(temp1, temp2);
      __ movl(temp2, Address(ESP, 1 * kWordSize));
      __ sarl(temp2, ECX);
      __ cmpl(temp1, temp2);
      __ j(NOT_EQUAL, deopt);
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
  __ movq(left, Address(ESP, 0));
  __ addl(ESP, Immediate(2 * kWordSize));
  __ Bind(&done);
  if (FLAG_throw_on_javascript_int_overflow) {
    Register tmp = locs()->temp(0).reg();
    EmitJavascriptIntOverflowCheck(compiler, deopt, left, tmp);
  }
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      FLAG_throw_on_javascript_int_overflow ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::SameAsFirstInput());
  if (FLAG_throw_on_javascript_int_overflow) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(op_kind() == Token::kBIT_NOT);
  XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(value == locs()->out().fpu_reg());
  Label* deopt = NULL;
  if (FLAG_throw_on_javascript_int_overflow) {
    deopt = compiler->AddDeoptStub(deopt_id(),
                                   kDeoptUnaryMintOp);
  }
  __ pcmpeqq(XMM0, XMM0);  // Generate all 1's.
  __ pxor(value, XMM0);
  if (FLAG_throw_on_javascript_int_overflow) {
    Register tmp = locs()->temp(0).reg();
    EmitJavascriptIntOverflowCheck(compiler, deopt, value, tmp);
  }
}


LocationSummary* ThrowInstr::MakeLocationSummary(bool opt) const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kThrowRuntimeEntry,
                                1,
                                locs());
  __ int3();
}


LocationSummary* ReThrowInstr::MakeLocationSummary(bool opt) const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
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
    compiler->EmitEdgeCounter();
    // The deoptimization descriptor points after the edge counter code for
    // uniformity with ARM and MIPS, where we can reuse pattern matching
    // code that matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                   deopt_id_,
                                   Scanner::kNoSourcePos);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(bool opt) const {
  return new LocationSummary(0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->is_optimizing()) {
    compiler->EmitEdgeCounter();
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.  This descriptor points
    // after the edge counter for uniformity with ARM and MIPS, where we can
    // reuse pattern matching that matches backwards from the end of the
    // pattern.
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
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


LocationSummary* CurrentContextInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ MoveRegister(locs()->out().reg(), CTX);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(EAX));
    locs->set_in(1, Location::RegisterLocation(ECX));
    locs->set_out(Location::RegisterLocation(EAX));
    return locs;
  }
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterOrConstant(left()));
  // Only one of the inputs can be a constant. Choose register if the first one
  // is a constant.
  locs->set_in(1, locs->in(0).IsConstant()
                      ? Location::RequiresRegister()
                      : Location::RegisterOrConstant(right()));
  locs->set_out(Location::RequiresRegister());
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

  Register result = locs()->out().reg();
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


LocationSummary* IfThenElseInstr::MakeLocationSummary(bool opt) const {
  comparison()->InitializeLocationSummary(opt);
  // TODO(vegorov): support byte register constraints in the register allocator.
  comparison()->locs()->set_out(Location::RegisterLocation(EDX));
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out().reg() == EDX);

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
    __ subl(EDX, Immediate(1));
    __ andl(EDX, Immediate(
        Smi::RawValue(true_value) - Smi::RawValue(false_value)));
    if (false_value != 0) {
      __ addl(EDX, Immediate(Smi::RawValue(false_value)));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(EAX));
  result->set_temp(0, Location::RegisterLocation(EDX));  // Arg. descriptor.
  return result;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The arguments to the stub include the closure, as does the arguments
  // descriptor.
  Register temp_reg = locs()->temp(0).reg();
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  __ LoadObject(temp_reg, arguments_descriptor);
  ASSERT(temp_reg == EDX);
  compiler->GenerateDartCall(deopt_id(),
                             token_pos(),
                             &StubCode::CallClosureFunctionLabel(),
                             PcDescriptors::kClosureCall,
                             locs());
  __ Drop(argument_count);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Label done;
  __ LoadObject(result, Bool::True());
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, Bool::False());
  __ Bind(&done);
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(bool opt) const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls()));
  const ExternalLabel label(cls().ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}

}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_IA32
