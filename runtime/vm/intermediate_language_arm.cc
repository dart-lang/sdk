// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/intermediate_language.h"

#include "vm/dart_entry.h"
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

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, use_osr);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register R0.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(R0));
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


LocationSummary* ReturnInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == R0);
#if defined(DEBUG)
  Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ sub(R2, SP, ShifterOperand(FP));
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


LocationSummary* IfThenElseInstr::MakeLocationSummary(bool opt) const {
  comparison()->InitializeLocationSummary(opt);
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out().reg();

  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  // Clear out register.
  __ eor(result, result, ShifterOperand(result));

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

  __ mov(result, ShifterOperand(1), true_condition);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ Lsl(result, result, shift + kSmiTagSize);
  } else {
    __ sub(result, result, ShifterOperand(1));
    const int32_t val =
        Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, Smi::RawValue(false_value));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(R0));
  result->set_temp(0, Location::RegisterLocation(R4));  // Arg. descriptor.
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
  ASSERT(temp_reg == R4);
  compiler->GenerateDartCall(deopt_id(),
                             token_pos(),
                             &StubCode::CallClosureFunctionLabel(),
                             PcDescriptors::kClosureCall,
                             locs());
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ LoadFromOffset(kWord, result, FP, local().index() * kWordSize);
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ str(value, Address(FP, local().index() * kWordSize));
}


LocationSummary* ConstantInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out().IsInvalid()) {
    Register result = locs()->out().reg();
    __ LoadObject(result, value());
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));  // Value.
  summary->set_in(1, Location::RegisterLocation(R2));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(R1));  // Type arguments.
  summary->set_out(Location::RegisterLocation(R0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(Location::RegisterLocation(R0));
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
  Register obj = locs()->in(0).reg();
  Register result = locs()->out().reg();

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
    __ mov(value_cid_reg, ShifterOperand(kSmiCid));
  }
  __ tst(value_reg, ShifterOperand(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ b(&done, EQ);
  } else {
    __ b(value_is_smi, EQ);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
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
    __ cmp(left.reg(), ShifterOperand(right.reg()));
  }
  return true_condition;
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
  QRegister left = locs->in(0).fpu_reg();
  QRegister right = locs->in(1).fpu_reg();
  DRegister dleft = EvenDRegisterOf(left);
  DRegister dright = EvenDRegisterOf(right);
  __ vcmpd(dleft, dright);
  __ vmstat();
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
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  Register result = locs()->out().reg();
  if (operation_cid() == kSmiCid) {
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
    __ TestImmediate(left, imm);
  } else {
    __ tst(left, ShifterOperand(right.reg()));
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
    return EmitSmiComparisonOp(compiler, locs(), kind());
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  Register result = locs()->out().reg();
  if (operation_cid() == kSmiCid) {
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


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);

  if (operation_cid() == kDoubleCid) {
    Label* nan_result = (true_condition == NE) ?
        labels.true_label : labels.false_label;
    __ b(nan_result, VS);
  }
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* NativeCallInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_temp(1, Location::RegisterLocation(R2));
  locs->set_temp(2, Location::RegisterLocation(R5));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->temp(1).reg() == R2);
  ASSERT(locs()->temp(2).reg() == R5);
  Register result = locs()->out().reg();

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
  const ExternalLabel* stub_entry;
  if (is_bootstrap_native()) {
    stub_entry = &StubCode::CallBootstrapCFunctionLabel();
#if defined(USING_SIMULATOR)
    entry = Simulator::RedirectExternalReference(
        entry, Simulator::kBootstrapNativeCall, function().NumParameters());
#endif
  } else {
    // In the case of non bootstrap native methods the CallNativeCFunction
    // stub generates the redirection address when running under the simulator
    // and hence we do not change 'entry' here.
    stub_entry = &StubCode::CallNativeCFunctionLabel();
#if defined(USING_SIMULATOR)
    if (!function().IsNativeAutoSetupScope()) {
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, function().NumParameters());
    }
#endif
  }
  __ LoadImmediate(R5, entry);
  __ LoadImmediate(R1, NativeArguments::ComputeArgcTag(function()));
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         PcDescriptors::kOther,
                         locs());
  __ Pop(result);
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
  __ LoadImmediate(result,
                   reinterpret_cast<uword>(Symbols::PredefinedAddress()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(result, Address(result, char_code, LSL, 1));  // Char code is a smi.
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
  __ ldr(result, FieldAddress(str, String::length_offset()));
  __ cmp(result, ShifterOperand(Smi::RawValue(1)));
  __ LoadImmediate(result, Smi::RawValue(-1), NE);
  __ ldrb(result, FieldAddress(str, OneByteString::data_offset()), EQ);
  __ SmiTag(result);
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_out(Location::RegisterLocation(R0));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ Push(array);
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               CallFunction(),
                               kNumberOfArguments,
                               kNoArgumentNames,
                               locs());
  ASSERT(locs()->out().reg() == R0);
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
  __ LoadFromOffset(kWord, result, object, offset() - kHeapObjectTag);
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
  __ tst(object, ShifterOperand(kSmiTagMask));
  __ b(&load, NE);
  __ LoadImmediate(result, Smi::RawValue(kSmiCid));
  __ b(&done);
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


LocationSummary* LoadIndexedInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  // TODO(regis): Revisit and see if the index can be immediate.
  locs->set_in(1, Location::WritableRegister());
  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
      (representation() == kUnboxedFloat64x2)) {
    if (class_id() == kTypedDataFloat32ArrayCid) {
      // Need register <= Q7 for float operations.
      // TODO(fschneider): Add a register policy to specify a subset of
      // registers.
      locs->set_out(Location::FpuRegisterLocation(Q7));
    } else {
      locs->set_out(Location::RequiresFpuRegister());
    }
  } else {
    locs->set_out(Location::RequiresRegister());
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  Location index = locs()->in(1);

  Address element_address(kNoRegister, 0);
  ASSERT(index.IsRegister());  // TODO(regis): Revisit.
  // Note that index is expected smi-tagged, (i.e, times 2) for all arrays
  // with index scale factor > 1. E.g., for Uint8Array and OneByteString the
  // index is expected to be untagged before accessing.
  ASSERT(kSmiTagShift == 1);
  switch (index_scale()) {
    case 1: {
      __ SmiUntag(index.reg());
      break;
    }
    case 2: {
      break;
    }
    case 4: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 1));
      break;
    }
    case 8: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 2));
      break;
    }
    case 16: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 3));
      break;
    }
    default:
      UNREACHABLE();
  }

  if (!IsExternal()) {
    ASSERT(this->array()->definition()->representation() == kTagged);
    __ AddImmediate(index.reg(),
        FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
  }
  element_address = Address(array, index.reg(), LSL, 0);

  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedMint)      ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)   ||
      (representation() == kUnboxedFloat64x2)) {
    QRegister result = locs()->out().fpu_reg();
    DRegister dresult0 = EvenDRegisterOf(result);
    DRegister dresult1 = OddDRegisterOf(result);
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataUint32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        // vldrs does not support indexed addressing.
        __ add(index.reg(), index.reg(), ShifterOperand(array));
        element_address = Address(index.reg(), 0);
        __ vldrs(EvenSRegisterOf(dresult0), element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        // vldrd does not support indexed addressing.
        __ add(index.reg(), index.reg(), ShifterOperand(array));
        element_address = Address(index.reg(), 0);
        __ vldrd(dresult0, element_address);
        break;
      case kTypedDataFloat64x2ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        __ add(index.reg(), index.reg(), ShifterOperand(array));
        // TODO(zra): Maybe use vldmd here.
        __ LoadDFromOffset(dresult0, index.reg(), 0);
        __ LoadDFromOffset(dresult1, index.reg(), 2 * kWordSize);
        break;
    }
    return;
  }

  Register result = locs()->out().reg();
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
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptInt32Load);
        __ ldr(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ CompareImmediate(result, 0xC0000000);
        __ b(deopt, MI);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptUint32Load);
        __ ldr(result, element_address);
        // Verify that the unsigned value in 'result' can fit inside a Smi.
        __ tst(result, ShifterOperand(0xC0000000));
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


LocationSummary* StoreIndexedInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  // TODO(regis): Revisit and see if the index can be immediate.
  locs->set_in(1, Location::WritableRegister());
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
      locs->set_in(2, Location::WritableRegister());
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
  Register array = locs()->in(0).reg();
  Location index = locs()->in(1);

  Address element_address(kNoRegister, 0);
  ASSERT(index.IsRegister());  // TODO(regis): Revisit.
  // Note that index is expected smi-tagged, (i.e, times 2) for all arrays
  // with index scale factor > 1. E.g., for Uint8Array and OneByteString the
  // index is expected to be untagged before accessing.
  ASSERT(kSmiTagShift == 1);
  switch (index_scale()) {
    case 1: {
      __ SmiUntag(index.reg());
      break;
    }
    case 2: {
      break;
    }
    case 4: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 1));
      break;
    }
    case 8: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 2));
      break;
    }
    case 16: {
      __ mov(index.reg(), ShifterOperand(index.reg(), LSL, 3));
      break;
    }
    default:
      UNREACHABLE();
  }
  if (!IsExternal()) {
    ASSERT(this->array()->definition()->representation() == kTagged);
    __ AddImmediate(index.reg(),
        FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
  }
  element_address = Address(array, index.reg(), LSL, 0);

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
    case kOneByteStringCid: {
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ LoadImmediate(IP, static_cast<int8_t>(constant.Value()));
        __ strb(IP, element_address);
      } else {
        Register value = locs()->in(2).reg();
        __ SmiUntag(value);
        __ strb(value, element_address);
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
        Register value = locs()->in(2).reg();
        Label store_value;
        __ SmiUntag(value);
        __ cmp(value, ShifterOperand(0xFF));
        // Clamp to 0x00 or 0xFF respectively.
        __ b(&store_value, LS);
        __ mov(value, ShifterOperand(0x00), LE);
        __ mov(value, ShifterOperand(0xFF), GT);
        __ Bind(&store_value);
        __ strb(value, element_address);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      Register value = locs()->in(2).reg();
      __ SmiUntag(value);
      __ strh(value, element_address);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (value()->IsSmiValue()) {
        ASSERT(RequiredInputRepresentation(2) == kTagged);
        Register value = locs()->in(2).reg();
        __ SmiUntag(value);
        __ str(value, element_address);
      } else {
        UNIMPLEMENTED();
      }
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      SRegister value =
          EvenSRegisterOf(EvenDRegisterOf(locs()->in(2).fpu_reg()));
      __ add(index.reg(), index.reg(), ShifterOperand(array));
      __ StoreSToOffset(value, index.reg(), 0);
      break;
    }
    case kTypedDataFloat64ArrayCid: {
      DRegister in2 = EvenDRegisterOf(locs()->in(2).fpu_reg());
      __ add(index.reg(), index.reg(), ShifterOperand(array));
      __ StoreDToOffset(in2, index.reg(), 0);
      break;
    }
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid: {
      QRegister in = locs()->in(2).fpu_reg();
      DRegister din0 = EvenDRegisterOf(in);
      DRegister din1 = OddDRegisterOf(in);
      __ add(index.reg(), index.reg(), ShifterOperand(array));
      __ StoreDToOffset(din0, index.reg(), 0);
      __ StoreDToOffset(din1, index.reg(), 2 * kWordSize);
      break;
    }
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
  summary->AddTemp(Location::RequiresRegister());
  summary->AddTemp(Location::RequiresRegister());
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

  Register value_cid_reg = locs()->temp(0).reg();

  Register temp_reg = locs()->temp(1).reg();

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
      field_reg = R2;
      ASSERT((field_reg != value_reg) && (field_reg != value_cid_reg));
    }

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());
    FieldAddress field_length_operand(
        field_reg, Field::guarded_list_length_offset());

    ASSERT(value_cid_reg != kNoRegister);
    ASSERT((value_cid_reg != value_reg) && (field_reg != value_cid_reg));

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);
      Label skip_length_check;
      __ ldr(IP, field_cid_operand);
      __ cmp(value_cid_reg, ShifterOperand(IP));
      __ b(&skip_length_check, NE);
      if (field_has_length) {
        ASSERT(temp_reg != kNoRegister);
        // Field guard may have remembered list length, check it.
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          __ ldr(temp_reg,
                 FieldAddress(value_reg, Array::length_offset()));
          __ CompareImmediate(temp_reg, Smi::RawValue(field_length));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          __ ldr(temp_reg,
                 FieldAddress(value_reg, TypedData::length_offset()));
          __ CompareImmediate(temp_reg, Smi::RawValue(field_length));
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
          __ ldr(IP, field_length_operand);
          __ CompareImmediate(IP, 0);
          __ b(&skip_length_check, LT);
          __ CompareImmediate(value_cid_reg, kNullCid);
          __ b(&no_fixed_length, EQ);
          // Check for typed data array.
          __ CompareImmediate(value_cid_reg, kTypedDataInt32x4ArrayCid);
          __ b(&no_fixed_length, GT);
          __ CompareImmediate(value_cid_reg, kTypedDataInt8ArrayCid);
          // Could still be a regular array.
          __ b(&check_array, LT);
          __ ldr(temp_reg,
                 FieldAddress(value_reg, TypedData::length_offset()));
          __ ldr(IP, field_length_operand);
          __ cmp(temp_reg, ShifterOperand(IP));
          __ b(&length_compared);
          // Check for regular array.
          __ Bind(&check_array);
          __ CompareImmediate(value_cid_reg, kImmutableArrayCid);
          __ b(&no_fixed_length, GT);
          __ CompareImmediate(value_cid_reg, kArrayCid);
          __ b(&no_fixed_length, LT);
          __ ldr(temp_reg,
                 FieldAddress(value_reg, Array::length_offset()));
          __ ldr(IP, field_length_operand);
          __ cmp(temp_reg, ShifterOperand(IP));
          __ b(&length_compared);
          __ Bind(&no_fixed_length);
          __ b(fail);
          __ Bind(&length_compared);
          // Following branch cannot not occur, fall through.
        }
        __ b(fail, NE);
      }
      __ Bind(&skip_length_check);
      __ ldr(IP, field_nullability_operand);
      __ cmp(value_cid_reg, ShifterOperand(IP));
    } else if (value_cid == kNullCid) {
      __ ldr(value_cid_reg, field_nullability_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
    } else {
      Label skip_length_check;
      __ ldr(value_cid_reg, field_cid_operand);
      __ CompareImmediate(value_cid_reg, value_cid);
      __ b(&skip_length_check, NE);
      if (field_has_length) {
        ASSERT(value_cid_reg != kNoRegister);
        ASSERT(temp_reg != kNoRegister);
        if ((value_cid == kArrayCid) || (value_cid == kImmutableArrayCid)) {
          __ ldr(temp_reg,
                  FieldAddress(value_reg, Array::length_offset()));
          __ CompareImmediate(temp_reg, Smi::RawValue(field_length));
        } else if (RawObject::IsTypedDataClassId(value_cid)) {
          __ ldr(temp_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
          __ CompareImmediate(temp_reg, Smi::RawValue(field_length));
        } else if (field_cid != kIllegalCid) {
          ASSERT(field_cid != value_cid);
          ASSERT(field_length >= 0);
          // Field has a known class id and length. At compile time it is
          // known that the value's class id is not a fixed length list.
          __ b(fail);
        } else {
          ASSERT(field_cid == kIllegalCid);
          ASSERT(field_length == Field::kUnknownFixedLength);
          // Following jump cannot not occur, fall through.
        }
        __ b(fail, NE);
      }
      // Not identical, possibly null.
      __ Bind(&skip_length_check);
    }
    __ b(&ok, EQ);

    __ ldr(IP, field_cid_operand);
    __ CompareImmediate(IP, kIllegalCid);
    __ b(fail, NE);

    if (value_cid == kDynamicCid) {
      __ str(value_cid_reg, field_cid_operand);
      __ str(value_cid_reg, field_nullability_operand);
      if (field_has_length) {
        Label check_array, length_set, no_fixed_length;
        __ CompareImmediate(value_cid_reg, kNullCid);
        __ b(&no_fixed_length, EQ);
        // Check for typed data array.
        __ CompareImmediate(value_cid_reg, kTypedDataInt32x4ArrayCid);
        __ b(&no_fixed_length, GT);
        __ CompareImmediate(value_cid_reg, kTypedDataInt8ArrayCid);
        // Could still be a regular array.
        __ b(&check_array, LT);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ ldr(value_cid_reg,
               FieldAddress(value_reg, TypedData::length_offset()));
        __ str(value_cid_reg, field_length_operand);
        __ b(&length_set);  // Updated field length typed data array.
        // Check for regular array.
        __ Bind(&check_array);
        __ CompareImmediate(value_cid_reg, kImmutableArrayCid);
        __ b(&no_fixed_length, GT);
        __ CompareImmediate(value_cid_reg, kArrayCid);
        __ b(&no_fixed_length, LT);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ ldr(value_cid_reg,
               FieldAddress(value_reg, Array::length_offset()));
        __ str(value_cid_reg, field_length_operand);
        // Updated field length from regular array.
        __ b(&length_set);
        __ Bind(&no_fixed_length);
        __ LoadImmediate(IP, Smi::RawValue(Field::kNoFixedLength));
        __ str(IP, field_length_operand);
        __ Bind(&length_set);
      }
    } else {
      __ LoadImmediate(IP, value_cid);
      __ str(IP, field_cid_operand);
      __ str(IP, field_nullability_operand);
      if (field_has_length) {
        if ((value_cid == kArrayCid) || (value_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                 FieldAddress(value_reg, Array::length_offset()));
          __ str(value_cid_reg, field_length_operand);
        } else if (RawObject::IsTypedDataClassId(value_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                  FieldAddress(value_reg, TypedData::length_offset()));
          __ str(value_cid_reg, field_length_operand);
        } else {
          __ LoadImmediate(IP, Smi::RawValue(Field::kNoFixedLength));
          __ str(IP, field_length_operand);
        }
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ b(&ok);
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
    if (field_reg != kNoRegister) {
      __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));
    }
    if (value_cid == kDynamicCid) {
      // Field's guarded class id is fixed by value's class id is not known.
      __ tst(value_reg, ShifterOperand(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ b(fail, EQ);
        __ LoadClassId(value_cid_reg, value_reg);
        __ CompareImmediate(value_cid_reg, field_cid);
      }

      if (field_has_length) {
        __ b(fail, NE);
        // Classes are same, perform guarded list length check.
        ASSERT(field_reg != kNoRegister);
        ASSERT(value_cid_reg != kNoRegister);
        FieldAddress field_length_operand(
            field_reg, Field::guarded_list_length_offset());
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                 FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                 FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ ldr(IP, field_length_operand);
        __ cmp(value_cid_reg, ShifterOperand(IP));
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ b(&ok, EQ);
        __ CompareImmediate(value_reg,
                            reinterpret_cast<intptr_t>(Object::null()));
      }
      __ b(fail, NE);
    } else {
      // Both value's and field's class id is known.
      if ((value_cid != field_cid) && (value_cid != nullability)) {
        __ b(fail);
      } else if (field_has_length && (value_cid == field_cid)) {
        ASSERT(value_cid_reg != kNoRegister);
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                 FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ ldr(value_cid_reg,
                 FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ CompareImmediate(value_cid_reg, field_length);
        __ b(fail, NE);
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
    __ MoveRegister(locs->temp(0).reg(), R0);
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
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

  Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    DRegister value = EvenDRegisterOf(locs()->in(1).fpu_reg());
    DRegister value_odd = OddDRegisterOf(locs()->in(1).fpu_reg());
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
                     temp,
                     temp2);
      __ Bind(slow_path->exit_label());
      __ MoveRegister(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);
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
        __ StoreDToOffset(value, temp,
            Float32x4::value_offset() - kHeapObjectTag);
        __ StoreDToOffset(value_odd, temp,
            Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
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
    DRegister fpu_temp = EvenDRegisterOf(locs()->temp(2).fpu_reg());
    DRegister fpu_temp_odd = OddDRegisterOf(locs()->temp(2).fpu_reg());

    Label store_pointer;
    Label store_double;
    Label store_float32x4;

    __ LoadObject(temp, Field::ZoneHandle(field().raw()));

    __ ldr(temp2, FieldAddress(temp, Field::is_nullable_offset()));
    __ CompareImmediate(temp2, kNullCid);
    __ b(&store_pointer, EQ);

    __ ldrb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ tst(temp2, ShifterOperand(1 << Field::kUnboxingCandidateBit));
    __ b(&store_pointer, EQ);

    __ ldr(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kDoubleCid);
    __ b(&store_double, EQ);

    __ ldr(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ CompareImmediate(temp2, kFloat32x4Cid);
    __ b(&store_float32x4, EQ);

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
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);
      __ Bind(&copy_double);
      __ LoadDFromOffset(fpu_temp,
                         value_reg,
                         Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(fpu_temp,
                        temp,
                        Double::value_offset() - kHeapObjectTag);
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
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_),
                         temp2);
      __ Bind(&copy_float32x4);
      // TODO(zra): Maybe use vldmd here.
      __ LoadDFromOffset(fpu_temp, value_reg,
          Float32x4::value_offset() - kHeapObjectTag);
      __ LoadDFromOffset(fpu_temp_odd, value_reg,
          Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
      __ StoreDToOffset(fpu_temp, temp,
          Float32x4::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(fpu_temp_odd, temp,
          Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
      __ b(&skip_store);
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
  summary->set_out(Location::RequiresRegister());
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
  __ LoadFromOffset(kWord, result,
                    field, Field::value_offset() - kHeapObjectTag);
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
  summary->set_in(0, Location::RegisterLocation(R0));
  summary->set_in(1, Location::RegisterLocation(R2));
  summary->set_in(2, Location::RegisterLocation(R1));
  summary->set_out(Location::RegisterLocation(R0));
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
  ASSERT(locs()->out().reg() == R0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(kElementTypePos, Location::RegisterLocation(R1));
  locs->set_in(kLengthPos, Location::RegisterLocation(R2));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  R2 = length, R1 = element type.
  ASSERT(locs()->in(kElementTypePos).reg() == R1);
  ASSERT(locs()->in(kLengthPos).reg() == R2);
  compiler->GenerateCall(token_pos(),
                         &StubCode::AllocateArrayLabel(),
                         PcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out().reg() == R0);
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
    __ MoveRegister(locs->out().reg(), R0);
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
    __ mov(locs->out().reg(), ShifterOperand(R0));
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
    __ mov(locs->out().reg(), ShifterOperand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
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
                      : Location::FpuRegisterLocation(Q1));
    locs->AddTemp(Location::RequiresRegister());
  }
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
    DRegister result_odd = OddDRegisterOf(locs()->out().fpu_reg());
    Register temp = locs()->temp(0).reg();
    __ ldr(temp, FieldAddress(instance_reg, offset_in_bytes()));
    intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ LoadDFromOffset(result, temp,
                           Double::value_offset() - kHeapObjectTag);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        // TODO(zra): Maybe use vldmd here.
        __ LoadDFromOffset(result, temp,
            Float32x4::value_offset() - kHeapObjectTag);
        __ LoadDFromOffset(result_odd, temp,
            Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  Register result_reg = locs()->out().reg();
  if (IsPotentialUnboxedLoad()) {
    Register temp = locs()->temp(1).reg();
    DRegister value = EvenDRegisterOf(locs()->temp(0).fpu_reg());
    DRegister value_odd = OddDRegisterOf(locs()->temp(0).fpu_reg());

    Label load_pointer;
    Label load_double;
    Label load_float32x4;

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
      __ LoadDFromOffset(value, temp, Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(value,
                        result_reg,
                        Double::value_offset() - kHeapObjectTag);
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
      // TODO(zra): Maybe use vldmd here.
      __ LoadDFromOffset(value, temp,
          Float32x4::value_offset() - kHeapObjectTag);
      __ LoadDFromOffset(value_odd, temp,
          Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
      __ StoreDToOffset(value, result_reg,
          Float32x4::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(value_odd, result_reg,
          Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFromOffset(kWord, result_reg,
                    instance_reg, offset_in_bytes() - kHeapObjectTag);
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

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
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
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
    __ cmp(instantiator_reg, ShifterOperand(IP));
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
  __ cmp(R1, ShifterOperand(R0));
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


LocationSummary* AllocateContextInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R1));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R1);
  ASSERT(locs()->out().reg() == R0);

  __ LoadImmediate(R1, num_context_variables());
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
  locs->set_in(0, Location::RegisterLocation(R0));
  locs->set_out(Location::RegisterLocation(R0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

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


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
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
    __ b(exit_label());
  }

 private:
  CheckStackOverflowInstr* instruction_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(IP, Isolate::Current()->stack_limit_address());
  __ ldr(IP, Address(IP));
  __ cmp(SP, ShifterOperand(IP));
  __ b(slow_path->entry_label(), LS);
  if (compiler->CanOSRFunction() && in_loop()) {
    Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ ldr(temp, FieldAddress(temp, Function::usage_counter_offset()));
    __ CompareImmediate(temp, threshold);
    __ b(slow_path->entry_label(), GE);
  }
  __ Bind(slow_path->exit_label());
}


static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const bool is_truncating = shift_left->is_truncating();
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out().reg();
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), kDeoptBinarySmiOp) : NULL;
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
        __ mov(result, ShifterOperand(0));
      } else {
        // Result is Mint or exception.
        __ b(deopt);
      }
    } else {
      if (!is_truncating) {
        // Check for overflow (preserve left).
        __ Lsl(IP, left, value);
        __ cmp(left, ShifterOperand(IP, ASR, value));
        __ b(deopt, NE);  // Overflow.
      }
      // Shift for result now we know there is no overflow.
      __ Lsl(result, left, value);
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
        __ cmp(right, ShifterOperand(0));
        __ b(deopt, MI);
        __ mov(result, ShifterOperand(0));
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          (right_range == NULL) ||
          !right_range->IsWithin(0, max_right - 1);
      if (right_needs_check) {
        __ cmp(right,
               ShifterOperand(reinterpret_cast<int32_t>(Smi::New(max_right))));
        __ b(deopt, CS);
      }
      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
      __ Lsl(result, left, IP);
    }
    return;
  }

  const bool right_needs_check =
      (right_range == NULL) || !right_range->IsWithin(0, (Smi::kBits - 1));
  if (is_truncating) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) ||
          !right_range->IsWithin(0, RangeBoundary::kPlusInfinity);
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmp(right, ShifterOperand(0));
        __ b(deopt, MI);
      }

      __ cmp(right,
             ShifterOperand(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ mov(result, ShifterOperand(0), CS);
      __ Asr(IP, right, kSmiTagSize, CC);  // SmiUntag right into IP if CC.
      __ Lsl(result, left, IP, CC);
    } else {
      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
      __ Lsl(result, left, IP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ cmp(right,
             ShifterOperand(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ b(deopt, CS);
    }
    // Left is not a constant.
    // Check if count too large for handling it inlined.
    __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
    // Overflow test (preserve left, right, and IP);
    Register temp = locs.temp(0).reg();
    __ Lsl(temp, left, IP);
    __ cmp(left, ShifterOperand(temp, ASR, IP));
    __ b(deopt, NE);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ Lsl(result, left, IP);
  }
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant->value()));
      summary->AddTemp(Location::RequiresRegister());
    } else {
      summary->set_in(1, Location::RequiresRegister());
      summary->AddTemp(Location::RequiresRegister());
      summary->AddTemp(Location::RequiresFpuRegister());
    }
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  if (op_kind() == Token::kMOD) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->AddTemp(Location::RequiresRegister());
    summary->AddTemp(Location::RequiresFpuRegister());
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
  if (((op_kind() == Token::kSHL) && !is_truncating()) ||
      (op_kind() == Token::kSHR)) {
    summary->AddTemp(Location::RequiresRegister());
  }
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  ASSERT(!is_truncating());
  Register left = locs()->in(0).reg();
  Register result = locs()->out().reg();
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    int32_t imm = reinterpret_cast<int32_t>(constant.raw());
    switch (op_kind()) {
      case Token::kSUB: {
        imm = -imm;  // TODO(regis): What if deopt != NULL && imm == 0x80000000?
        // Fall through.
      }
      case Token::kADD: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, imm);
        } else {
          __ AddImmediateSetFlags(result, left, imm);
          __ b(deopt, VS);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        if (deopt == NULL) {
          if (value == 2) {
            __ mov(result, ShifterOperand(left, LSL, 1));
          } else {
            __ LoadImmediate(IP, value);
            __ mul(result, left, IP);
          }
        } else {
          if (value == 2) {
            __ mov(IP, ShifterOperand(left, ASR, 31));  // IP = sign of left.
            __ mov(result, ShifterOperand(left, LSL, 1));
          } else {
            __ LoadImmediate(IP, value);
            __ smull(result, IP, left, IP);
          }
          // IP: result bits 32..63.
          __ cmp(IP, ShifterOperand(result, ASR, 31));
          __ b(deopt, NE);
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
          __ rsb(result, left, ShifterOperand(0));
          break;
        }
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ mov(IP, ShifterOperand(left, ASR, 31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        Register temp = locs()->temp(0).reg();
        __ add(temp, left, ShifterOperand(IP, LSR, 32 - shift_count));
        ASSERT(shift_count > 0);
        __ mov(result, ShifterOperand(temp, ASR, shift_count));
        if (value < 0) {
          __ rsb(result, result, ShifterOperand(0));
        }
        __ SmiTag(result);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        ShifterOperand shifter_op;
        if (ShifterOperand::CanHold(imm, &shifter_op)) {
          __ and_(result, left, shifter_op);
        } else {
          // TODO(regis): Try to use bic.
          __ LoadImmediate(IP, imm);
          __ and_(result, left, ShifterOperand(IP));
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        ShifterOperand shifter_op;
        if (ShifterOperand::CanHold(imm, &shifter_op)) {
          __ orr(result, left, shifter_op);
        } else {
          // TODO(regis): Try to use orn.
          __ LoadImmediate(IP, imm);
          __ orr(result, left, ShifterOperand(IP));
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        ShifterOperand shifter_op;
        if (ShifterOperand::CanHold(imm, &shifter_op)) {
          __ eor(result, left, shifter_op);
        } else {
          __ LoadImmediate(IP, imm);
          __ eor(result, left, ShifterOperand(IP));
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
        if (value >= kCountLimit) value = kCountLimit;

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

  Register right = locs()->in(1).reg();
  Range* right_range = this->right()->definition()->range();
  switch (op_kind()) {
    case Token::kADD: {
      if (deopt == NULL) {
        __ add(result, left, ShifterOperand(right));
      } else {
        __ adds(result, left, ShifterOperand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == NULL) {
        __ sub(result, left, ShifterOperand(right));
      } else {
        __ subs(result, left, ShifterOperand(right));
        __ b(deopt, VS);
      }
      break;
    }
    case Token::kMUL: {
      __ Asr(IP, left, kSmiTagSize);  // SmiUntag left into IP.
      if (deopt == NULL) {
        __ mul(result, IP, right);
      } else {
        __ smull(result, IP, IP, right);
        // IP: result bits 32..63.
        __ cmp(IP, ShifterOperand(result, ASR, 31));
        __ b(deopt, NE);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, ShifterOperand(right));
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ orr(result, left, ShifterOperand(right));
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ eor(result, left, ShifterOperand(right));
      break;
    }
    case Token::kTRUNCDIV: {
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
        // Handle divide by zero in runtime.
        __ cmp(right, ShifterOperand(0));
        __ b(deopt, EQ);
      }
      Register temp = locs()->temp(0).reg();
      DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
      __ Asr(temp, left, kSmiTagSize);  // SmiUntag left into temp.
      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.

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
        __ cmp(right, ShifterOperand(0));
        __ b(deopt, EQ);
      }
      Register temp = locs()->temp(0).reg();
      DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
      __ Asr(temp, left, kSmiTagSize);  // SmiUntag left into temp.
      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.

      __ IntegerDivide(result, temp, IP, dtemp, DTMP);

      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
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
      __ cmp(result, ShifterOperand(0));
      __ b(&done, GE);
      // Result is negative, adjust it.
      __ cmp(right, ShifterOperand(0));
      __ sub(result, result, ShifterOperand(right), LT);
      __ add(result, result, ShifterOperand(right), GE);
      __ Bind(&done);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ CompareImmediate(right, 0);
        __ b(deopt, LT);
      }
      __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
      // sarl operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if ((right_range == NULL) ||
          !right_range->IsWithin(RangeBoundary::kMinusInfinity, kCountLimit)) {
        __ CompareImmediate(IP, kCountLimit);
        __ LoadImmediate(IP, kCountLimit, GT);
      }
      Register temp = locs()->temp(0).reg();
      __ Asr(temp, left, kSmiTagSize);  // SmiUntag left into temp.
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


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
    new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinaryDoubleOp);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (left_cid == kSmiCid) {
    __ tst(right, ShifterOperand(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ tst(left, ShifterOperand(kSmiTagMask));
  } else {
    __ orr(IP, left, ShifterOperand(right));
    __ tst(IP, ShifterOperand(kSmiTagMask));
  }
  __ b(deopt, EQ);
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  const Register out_reg = locs()->out().reg();
  const DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());

  __ TryAllocate(compiler->double_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());
  __ StoreDToOffset(value, out_reg, Double::value_offset() - kHeapObjectTag);
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
  const DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());

  if (value_cid == kDoubleCid) {
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ vmovsr(STMP, value);
    __ vcvtdi(result, STMP);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptBinaryDoubleOp);
    Register temp = locs()->temp(0).reg();
    Label is_smi, done;
    __ tst(value, ShifterOperand(kSmiTagMask));
    __ b(&is_smi, EQ);
    __ CompareClassId(value, kDoubleCid, temp);
    __ b(deopt, NE);
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
    __ b(&done);
    __ Bind(&is_smi);
    // TODO(regis): Why do we preserve value here but not above?
    __ mov(IP, ShifterOperand(value, ASR, 1));  // Copy and untag.
    __ vmovsr(STMP, IP);
    __ vcvtdi(result, STMP);
    __ Bind(&done);
  }
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat32x4SlowPath* slow_path = new BoxFloat32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  QRegister value = locs()->in(0).fpu_reg();
  DRegister value_even = EvenDRegisterOf(value);
  DRegister value_odd = OddDRegisterOf(value);

  __ TryAllocate(compiler->float32x4_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());

  __ StoreDToOffset(value_even, out_reg,
      Float32x4::value_offset() - kHeapObjectTag);
  __ StoreDToOffset(value_odd, out_reg,
      Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
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
  const QRegister result = locs()->out().fpu_reg();

  if (value_cid != kFloat32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ tst(value, ShifterOperand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kFloat32x4Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister result_even = EvenDRegisterOf(result);
  const DRegister result_odd = OddDRegisterOf(result);
  // TODO(zra): Maybe use vldmd here.
  __ LoadDFromOffset(result_even, value,
      Float32x4::value_offset() - kHeapObjectTag);
  __ LoadDFromOffset(result_odd, value,
      Float32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxFloat64x2SlowPath* slow_path = new BoxFloat64x2SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  QRegister value = locs()->in(0).fpu_reg();
  DRegister value_even = EvenDRegisterOf(value);
  DRegister value_odd = OddDRegisterOf(value);

  __ TryAllocate(compiler->float64x2_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());

  __ StoreDToOffset(value_even, out_reg,
      Float64x2::value_offset() - kHeapObjectTag);
  __ StoreDToOffset(value_odd, out_reg,
      Float64x2::value_offset() + 2 * kWordSize - kHeapObjectTag);
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
  const QRegister result = locs()->out().fpu_reg();

  if (value_cid != kFloat64x2Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ tst(value, ShifterOperand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kFloat64x2Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister result_even = EvenDRegisterOf(result);
  const DRegister result_odd = OddDRegisterOf(result);
  // TODO(zra): Maybe use vldmd here.
  __ LoadDFromOffset(result_even, value,
      Float64x2::value_offset() - kHeapObjectTag);
  __ LoadDFromOffset(result_odd, value,
      Float64x2::value_offset() + 2 * kWordSize - kHeapObjectTag);
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
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
    __ mov(locs->out().reg(), ShifterOperand(R0));
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  BoxInt32x4Instr* instruction_;
};


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxInt32x4SlowPath* slow_path = new BoxInt32x4SlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  QRegister value = locs()->in(0).fpu_reg();
  DRegister value_even = EvenDRegisterOf(value);
  DRegister value_odd = OddDRegisterOf(value);

  __ TryAllocate(compiler->int32x4_class(),
                 slow_path->entry_label(),
                 out_reg,
                 locs()->temp(0).reg());
  __ Bind(slow_path->exit_label());
  __ StoreDToOffset(value_even, out_reg,
      Int32x4::value_offset() - kHeapObjectTag);
  __ StoreDToOffset(value_odd, out_reg,
      Int32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
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
  const QRegister result = locs()->out().fpu_reg();

  if (value_cid != kInt32x4Cid) {
    const Register temp = locs()->temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptCheckClass);
    __ tst(value, ShifterOperand(kSmiTagMask));
    __ b(deopt, EQ);
    __ CompareClassId(value, kInt32x4Cid, temp);
    __ b(deopt, NE);
  }

  const DRegister result_even = EvenDRegisterOf(result);
  const DRegister result_odd = OddDRegisterOf(result);
  // TODO(zra): Maybe use vldmd here.
  __ LoadDFromOffset(result_even, value,
      Int32x4::value_offset() - kHeapObjectTag);
  __ LoadDFromOffset(result_odd, value,
      Int32x4::value_offset() + 2 * kWordSize - kHeapObjectTag);
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister left = EvenDRegisterOf(locs()->in(0).fpu_reg());
  DRegister right = EvenDRegisterOf(locs()->in(1).fpu_reg());
  DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
  switch (op_kind()) {
    case Token::kADD: __ vaddd(result, left, right); break;
    case Token::kSUB: __ vsubd(result, left, right); break;
    case Token::kMUL: __ vmuld(result, left, right); break;
    case Token::kDIV: __ vdivd(result, left, right); break;
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
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  switch (op_kind()) {
    case Token::kADD: __ vaddqs(result, left, right); break;
    case Token::kSUB: __ vsubqs(result, left, right); break;
    case Token::kMUL: __ vmulqs(result, left, right); break;
    case Token::kDIV: __ Vdivqs(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
  summary->set_in(0, Location::FpuRegisterLocation(Q5));
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();
  DRegister dresult0 = EvenDRegisterOf(result);
  DRegister dresult1 = OddDRegisterOf(result);
  SRegister sresult0 = EvenSRegisterOf(dresult0);
  SRegister sresult1 = OddSRegisterOf(dresult0);
  SRegister sresult2 = EvenSRegisterOf(dresult1);
  SRegister sresult3 = OddSRegisterOf(dresult1);

  DRegister dvalue0 = EvenDRegisterOf(value);
  DRegister dvalue1 = OddDRegisterOf(value);

  DRegister dtemp0 = DTMP;
  DRegister dtemp1 = OddDRegisterOf(QTMP);

  // For some cases the vdup instruction requires fewer
  // instructions. For arbitrary shuffles, use vtbl.

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4ShuffleX:
      __ vdup(kWord, result, dvalue0, 0);
      __ vcvtds(dresult0, sresult0);
      break;
    case MethodRecognizer::kFloat32x4ShuffleY:
      __ vdup(kWord, result, dvalue0, 1);
      __ vcvtds(dresult0, sresult0);
      break;
    case MethodRecognizer::kFloat32x4ShuffleZ:
      __ vdup(kWord, result, dvalue1, 0);
      __ vcvtds(dresult0, sresult0);
      break;
    case MethodRecognizer::kFloat32x4ShuffleW:
      __ vdup(kWord, result, dvalue1, 1);
      __ vcvtds(dresult0, sresult0);
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


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< Q7) Q registers are needed for the vcvtds and vmovs instructions.
  summary->set_in(0, Location::FpuRegisterLocation(Q4));
  summary->set_in(1, Location::FpuRegisterLocation(Q5));
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  DRegister dresult0 = EvenDRegisterOf(result);
  DRegister dresult1 = OddDRegisterOf(result);
  SRegister sresult0 = EvenSRegisterOf(dresult0);
  SRegister sresult1 = OddSRegisterOf(dresult0);
  SRegister sresult2 = EvenSRegisterOf(dresult1);
  SRegister sresult3 = OddSRegisterOf(dresult1);

  DRegister dleft0 = EvenDRegisterOf(left);
  DRegister dleft1 = OddDRegisterOf(left);
  DRegister dright0 = EvenDRegisterOf(right);
  DRegister dright1 = OddDRegisterOf(right);

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


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::FpuRegisterLocation(Q5));
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  DRegister dvalue0 = EvenDRegisterOf(value);
  DRegister dvalue1 = OddDRegisterOf(value);

  Register out = locs()->out().reg();
  Register temp = locs()->temp(0).reg();

  // X lane.
  __ vmovrs(out, EvenSRegisterOf(dvalue0));
  __ Lsr(out, out, 31);
  // Y lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue0));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, ShifterOperand(temp, LSL, 1));
  // Z lane.
  __ vmovrs(temp, EvenSRegisterOf(dvalue1));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, ShifterOperand(temp, LSL, 2));
  // W lane.
  __ vmovrs(temp, OddSRegisterOf(dvalue1));
  __ Lsr(temp, temp, 31);
  __ orr(out, out, ShifterOperand(temp, LSL, 3));
  // Tag.
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
  // Low (< 7) Q registers are needed for the vcvtsd instruction.
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister q0 = locs()->in(0).fpu_reg();
  QRegister q1 = locs()->in(1).fpu_reg();
  QRegister q2 = locs()->in(2).fpu_reg();
  QRegister q3 = locs()->in(3).fpu_reg();
  QRegister r = locs()->out().fpu_reg();

  DRegister dr0 = EvenDRegisterOf(r);
  DRegister dr1 = OddDRegisterOf(r);

  __ vcvtsd(EvenSRegisterOf(dr0), EvenDRegisterOf(q0));
  __ vcvtsd(OddSRegisterOf(dr0), EvenDRegisterOf(q1));
  __ vcvtsd(EvenSRegisterOf(dr1), EvenDRegisterOf(q2));
  __ vcvtsd(OddSRegisterOf(dr1), EvenDRegisterOf(q3));
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
  QRegister q = locs()->out().fpu_reg();
  __ veorq(q, q, q);
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  DRegister dvalue0 = EvenDRegisterOf(value);

  // Convert to Float32.
  __ vcvtsd(STMP, dvalue0);

  // Splat across all lanes.
  __ vdup(kWord, result, DTMP, 0);
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Equal:
      __ vceqqs(result, left, right);
      break;
    case MethodRecognizer::kFloat32x4NotEqual:
      __ vceqqs(result, left, right);
      // Invert the result.
      __ veorq(QTMP, QTMP, QTMP);  // QTMP <- 0.
      __ vornq(result, QTMP, result);  // result <- ~result.
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


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

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


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  return summary;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();
  QRegister temp = locs()->temp(0).fpu_reg();

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


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  switch (op_kind()) {
    case MethodRecognizer::kFloat32x4Scale:
      __ vcvtsd(STMP, EvenDRegisterOf(left));
      __ vdup(kWord, result, DTMP, 0);
      __ vmulqs(result, result, right);
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
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

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


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_in(2, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister lower = locs()->in(1).fpu_reg();
  QRegister upper = locs()->in(2).fpu_reg();
  QRegister result = locs()->out().fpu_reg();
  __ vminqs(result, left, upper);
  __ vmaxqs(result, result, lower);
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  // Low (< 7) Q registers are needed for the vmovs instruction.
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister replacement = locs()->in(0).fpu_reg();
  QRegister value = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  DRegister dresult0 = EvenDRegisterOf(result);
  DRegister dresult1 = OddDRegisterOf(result);
  SRegister sresult0 = EvenSRegisterOf(dresult0);
  SRegister sresult1 = OddSRegisterOf(dresult0);
  SRegister sresult2 = EvenSRegisterOf(dresult1);
  SRegister sresult3 = OddSRegisterOf(dresult1);

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


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  if (value != result) {
    __ vmovq(result, value);
  }
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    bool opt) const {
  const intptr_t kNumInputs = 4;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_in(2, Location::RequiresRegister());
  summary->set_in(3, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  // Low (< 7) Q register needed for the vmovsr instruction.
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register v0 = locs()->in(0).reg();
  Register v1 = locs()->in(1).reg();
  Register v2 = locs()->in(2).reg();
  Register v3 = locs()->in(3).reg();
  Register temp = locs()->temp(0).reg();
  QRegister result = locs()->out().fpu_reg();
  DRegister dresult0 = EvenDRegisterOf(result);
  DRegister dresult1 = OddDRegisterOf(result);
  SRegister sresult0 = EvenSRegisterOf(dresult0);
  SRegister sresult1 = OddSRegisterOf(dresult0);
  SRegister sresult2 = EvenSRegisterOf(dresult1);
  SRegister sresult3 = OddSRegisterOf(dresult1);

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


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (< 7) Q registers are needed for the vmovrs instruction.
  summary->set_in(0, Location::FpuRegisterLocation(Q6));
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  Register result = locs()->out().reg();

  DRegister dvalue0 = EvenDRegisterOf(value);
  DRegister dvalue1 = OddDRegisterOf(value);
  SRegister svalue0 = EvenSRegisterOf(dvalue0);
  SRegister svalue1 = OddSRegisterOf(dvalue0);
  SRegister svalue2 = EvenSRegisterOf(dvalue1);
  SRegister svalue3 = OddSRegisterOf(dvalue1);

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

  __ tst(result, ShifterOperand(result));
  __ LoadObject(result, Bool::True(), NE);
  __ LoadObject(result, Bool::False(), EQ);
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
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister mask = locs()->in(0).fpu_reg();
  QRegister trueValue = locs()->in(1).fpu_reg();
  QRegister falseValue = locs()->in(2).fpu_reg();
  QRegister out = locs()->out().fpu_reg();
  QRegister temp = locs()->temp(0).fpu_reg();

  // Copy mask.
  __ vmovq(temp, mask);
  // Invert it.
  __ veorq(QTMP, QTMP, QTMP);  // QTMP <- 0.
  __ vornq(temp, QTMP, temp);  //  temp <- ~temp.
  // mask = mask & trueValue.
  __ vandq(mask, mask, trueValue);
  // temp = temp & falseValue.
  __ vandq(temp, temp, falseValue);
  // out = mask | temp.
  __ vorrq(out, mask, temp);
}


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresRegister());
  // Low (< 7) Q register needed for the vmovsr instruction.
  summary->set_out(Location::FpuRegisterLocation(Q6));
  return summary;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister mask = locs()->in(0).fpu_reg();
  Register flag = locs()->in(1).reg();
  QRegister result = locs()->out().fpu_reg();

  DRegister dresult0 = EvenDRegisterOf(result);
  DRegister dresult1 = OddDRegisterOf(result);
  SRegister sresult0 = EvenSRegisterOf(dresult0);
  SRegister sresult1 = OddSRegisterOf(dresult0);
  SRegister sresult2 = EvenSRegisterOf(dresult1);
  SRegister sresult3 = OddSRegisterOf(dresult1);

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


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister value = locs()->in(0).fpu_reg();
  QRegister result = locs()->out().fpu_reg();

  if (value != result) {
    __ vmovq(result, value);
  }
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  QRegister left = locs()->in(0).fpu_reg();
  QRegister right = locs()->in(1).fpu_reg();
  QRegister result = locs()->out().fpu_reg();
  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ vandq(result, left, right);
      break;
    }
    case Token::kBIT_OR: {
      __ vorrq(result, left, right);
      break;
    }
    case Token::kBIT_XOR: {
      __ veorq(result, left, right);
      break;
    }
    case Token::kADD:
      __ vaddqi(kWord, result, left, right);
      break;
    case Token::kSUB:
      __ vsubqi(kWord, result, left, right);
      break;
    default: UNREACHABLE();
  }
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(bool opt) const {
  if ((kind() == MethodRecognizer::kMathSin) ||
      (kind() == MethodRecognizer::kMathCos)) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(Q0));
    summary->set_out(Location::FpuRegisterLocation(Q0));
#if !defined(ARM_FLOAT_ABI_HARD)
    summary->AddTemp(Location::RegisterLocation(R0));
    summary->AddTemp(Location::RegisterLocation(R1));
    summary->AddTemp(Location::RegisterLocation(R2));
    summary->AddTemp(Location::RegisterLocation(R3));
#endif
    return summary;
  }
  // Sqrt.
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
    DRegister val = EvenDRegisterOf(locs()->in(0).fpu_reg());
    DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
    __ vsqrtd(result, val);
  } else {
#if defined(ARM_FLOAT_ABI_HARD)
    __ CallRuntime(TargetFunction(), InputCount());
#else
    // If we aren't doing "hardfp", then we have to move the double arguments
    // to the integer registers, and take the results from the integer
    // registers.
    __ vmovrrd(R0, R1, D0);
    __ vmovrrd(R2, R3, D1);
    __ CallRuntime(TargetFunction(), InputCount());
    __ vmovdrr(D0, R0, R1);
    __ vmovdrr(D1, R2, R3);
#endif
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
    DRegister left = EvenDRegisterOf(locs()->in(0).fpu_reg());
    DRegister right = EvenDRegisterOf(locs()->in(1).fpu_reg());
    DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
    Register temp = locs()->temp(0).reg();
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
    __ cmp(temp, ShifterOperand(0));
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
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();
  __ cmp(left, ShifterOperand(right));
  ASSERT(result == left);
  if (is_min) {
    __ mov(result, ShifterOperand(right), GT);
  } else {
    __ mov(result, ShifterOperand(right), LT);
  }
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                            kDeoptUnaryOp);
      __ rsbs(result, value, ShifterOperand(0));
      __ b(deopt, VS);
      break;
    }
    case Token::kBIT_NOT:
      __ mvn(result, ShifterOperand(value));
      // Remove inverted smi-tag.
      __ bic(result, result, ShifterOperand(kSmiTagMask));
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
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
  DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  __ vnegd(result, value);
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
  DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
  __ SmiUntag(value);
  __ vmovsr(STMP, value);
  __ vcvtdi(result, STMP);
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(R1));
  result->set_out(Location::RegisterLocation(R0));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  Register value_obj = locs()->in(0).reg();
  ASSERT(result == R0);
  ASSERT(result != value_obj);
  __ LoadDFromOffset(DTMP, value_obj, Double::value_offset() - kHeapObjectTag);

  Label do_call, done;
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
  DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
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


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (<= Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(Location::FpuRegisterLocation(Q7));
  return result;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister value = EvenDRegisterOf(locs()->in(0).fpu_reg());
  SRegister result = EvenSRegisterOf(EvenDRegisterOf(locs()->out().fpu_reg()));
  __ vcvtsd(result, value);
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Low (<= Q7) Q registers are needed for the conversion instructions.
  result->set_in(0, Location::FpuRegisterLocation(Q7));
  result->set_out(Location::RequiresFpuRegister());
  return result;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SRegister value = EvenSRegisterOf(EvenDRegisterOf(locs()->in(0).fpu_reg()));
  DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
  __ vcvtds(result, value);
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(Q0));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(Q1));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    result->AddTemp(Location::RegisterLocation(R2));
    result->AddTemp(Location::FpuRegisterLocation(Q2));
  }
#if !defined(ARM_FLOAT_ABI_HARD)
  result->AddTemp(Location::RegisterLocation(R0));
  result->AddTemp(Location::RegisterLocation(R1));
  // Check if R2 is already added.
  if (recognized_kind() != MethodRecognizer::kMathDoublePow) {
    result->AddTemp(Location::RegisterLocation(R2));
  }
  result->AddTemp(Location::RegisterLocation(R3));
#endif
  result->set_out(Location::FpuRegisterLocation(Q0));
  return result;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // For pow-function return NaN if exponent is NaN.
  Label do_call, skip_call;
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Pseudo code:
    // if (exponent == 0.0) return 0.0;
    // if (base == 1.0) return 1.0;
    // if (base.isNaN || exponent.isNaN) {
    //    return double.NAN;
    // }
    DRegister base = EvenDRegisterOf(locs()->in(0).fpu_reg());
    DRegister exp = EvenDRegisterOf(locs()->in(1).fpu_reg());
    DRegister result = EvenDRegisterOf(locs()->out().fpu_reg());
    Register temp = locs()->temp(0).reg();
    DRegister saved_base = EvenDRegisterOf(locs()->temp(1).fpu_reg());
    ASSERT((base == result) && (result != saved_base));
    Label check_base_is_one;
    // Check if exponent is 0.0 -> return 1.0;
    __ vmovd(saved_base, base);
    __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0)));
    __ LoadDFromOffset(DTMP, temp, Double::value_offset() - kHeapObjectTag);
    __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1)));
    __ LoadDFromOffset(result, temp, Double::value_offset() - kHeapObjectTag);
    __ vcmpd(exp, DTMP);
    __ vmstat();
    __ b(&check_base_is_one, VS);  // NaN -> not zero.
    __ b(&skip_call, EQ);  // exp is 0.0, result is 1.0.

    __ Bind(&check_base_is_one);
    __ vcmpd(saved_base, result);
    __ vmstat();
    __ vmovd(result, saved_base, VS);  // base is NaN, return NaN.
    __ b(&skip_call, VS);
    __ b(&skip_call, EQ);  // base and result are 1.0.
    __ vmovd(base, saved_base);  // Restore base.
  }
  __ Bind(&do_call);
  if (InputCount() == 2) {
    // Args must be in D0 and D1, so move arg from Q1(== D3:D2) to D1.
    __ vmovd(D1, D2);
  }
#if defined(ARM_FLOAT_ABI_HARD)
  __ CallRuntime(TargetFunction(), InputCount());
#else
  // If the ABI is not "hardfp", then we have to move the double arguments
  // to the integer registers, and take the results from the integer
  // registers.
  __ vmovrrd(R0, R1, D0);
  __ vmovrrd(R2, R3, D1);
  __ CallRuntime(TargetFunction(), InputCount());
  __ vmovdrr(D0, R0, R1);
  __ vmovdrr(D1, R2, R3);
#endif
  __ Bind(&skip_call);
}


LocationSummary* MergedMathInstr::MakeLocationSummary(bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 4;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresFpuRegister());
    summary->set_temp(2, Location::RequiresRegister());  // result_div.
    summary->set_temp(3, Location::RequiresRegister());  // result_mod.
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  UNIMPLEMENTED();
  return NULL;
}


void MergedMathInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinarySmiOp);
  }
  if (kind() == MergedMathInstr::kTruncDivMod) {
    Register left = locs()->in(0).reg();
    Register right = locs()->in(1).reg();
    Register result = locs()->out().reg();
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
      // Handle divide by zero in runtime.
      __ cmp(right, ShifterOperand(0));
      __ b(deopt, EQ);
    }
    Register temp = locs()->temp(0).reg();
    DRegister dtemp = EvenDRegisterOf(locs()->temp(1).fpu_reg());
    Register result_div = locs()->temp(2).reg();
    Register result_mod = locs()->temp(3).reg();
    __ Asr(temp, left, kSmiTagSize);  // SmiUntag left into temp.
    __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.

    __ IntegerDivide(result_div, temp, IP, dtemp, DTMP);

    // Check the corner case of dividing the 'MIN_SMI' with -1, in which
    // case we cannot tag the result.
    __ CompareImmediate(result_div, 0x40000000);
    __ b(deopt, EQ);
    __ Asr(IP, right, kSmiTagSize);  // SmiUntag right into IP.
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
    __ cmp(result_mod, ShifterOperand(0));
    __ b(&done, GE);
    // Result is negative, adjust it.
    __ cmp(right, ShifterOperand(0));
    __ sub(result_mod, result_mod, ShifterOperand(right), LT);
    __ add(result_mod, result_mod, ShifterOperand(right), GE);
    __ Bind(&done);

    __ LoadObject(result, Array::ZoneHandle(Array::New(2, Heap::kOld)));
    // Note that index is expected smi-tagged, (i.e, times 2) for all arrays.
    // [0]: divide resut, [1]: mod result.
    __ mov(temp, ShifterOperand(0 +
        FlowGraphCompiler::DataOffsetFor(kArrayCid) - kHeapObjectTag));
    Address store_address(result, temp, LSL, 0);
    __ StoreIntoObjectNoBarrier(result, store_address, result_div);
    __ add(temp, temp, ShifterOperand(kWordSize));
    __ StoreIntoObjectNoBarrier(result, store_address, result_mod);
    return;
  }
  if (kind() == MergedMathInstr::kSinCos) {
    UNIMPLEMENTED();
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
    __ b(deopt);
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
    __ CompareImmediate(locs()->in(0).reg(),
                        reinterpret_cast<intptr_t>(Object::null()));
    __ b(deopt, EQ);
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
    __ tst(value, ShifterOperand(kSmiTagMask));
    __ b(&is_ok, EQ);
    cix++;  // Skip first check.
  } else {
    __ tst(value, ShifterOperand(kSmiTagMask));
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
  __ tst(value, ShifterOperand(kSmiTagMask));
  __ b(deopt, NE);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
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
    __ b(deopt);
    return;
  }

  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ CompareImmediate(length, reinterpret_cast<int32_t>(index.raw()));
    __ b(deopt, LS);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    __ CompareImmediate(index, reinterpret_cast<int32_t>(length.raw()));
    __ b(deopt, CS);
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    __ cmp(index, ShifterOperand(length));
    __ b(deopt, CS);
  }
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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
  __ bkpt(0);
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
    compiler->EmitEdgeCounter();
    // Add an edge counter.
    // On ARM the deoptimization descriptor points after the edge counter
    // code so that we can reuse the same pattern matching code as at call
    // sites, which matches backwards from the end of the pattern.
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
    // may be inserted before this instruction.  On ARM this descriptor
    // points after the edge counter code so that we can reuse the same
    // pattern matching code as at call sites, which matches backwards from
    // the end of the pattern.
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
    __ b(compiler->GetJumpLabel(successor()));
  }
}


LocationSummary* CurrentContextInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ mov(locs()->out().reg(), ShifterOperand(CTX));
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(R0));
    locs->set_in(1, Location::RegisterLocation(R1));
    locs->set_out(Location::RegisterLocation(R0));
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
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQ : NE;
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  // The ARM code does not use true- and false-labels here.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = EmitComparisonCode(compiler, labels);

  Register result = locs()->out().reg();
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


LocationSummary* BooleanNegateInstr::MakeLocationSummary(bool opt) const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ LoadObject(result, Bool::True());
  __ cmp(result, ShifterOperand(value));
  __ LoadObject(result, Bool::False(), EQ);
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

#endif  // defined TARGET_ARCH_ARM
