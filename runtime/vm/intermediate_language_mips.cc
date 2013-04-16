// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/intermediate_language.h"

#include "lib/error.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, propagate_ic_data);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register V0.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(V0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary() const {
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
      __ lw(TMP, value.ToStackSlotAddress());
      __ Push(TMP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(V0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == V0);
#if defined(DEBUG)
  // TODO(srdjan): Fix for functions with finally clause.
  // A finally clause may leave a previously pushed return value if it
  // has its own return instruction. Method that have finally are currently
  // not optimized.
  if (!compiler->HasFinally()) {
    Label stack_ok;
    __ Comment("Stack Check");
    const int sp_fp_dist = compiler->StackSize() + (-kFirstLocalSlotIndex - 1);
    __ subu(T2, FP, SP);

    __ BranchEqual(T2, sp_fp_dist * kWordSize, &stack_ok);
    __ break_(0);

    __ Bind(&stack_ok);
  }
#endif
  __ LeaveDartFrame();
  __ Ret();

  // Generate 2 NOP instructions so that the debugger can patch the return
  // pattern (1 instruction) with a call to the debug stub (3 instructions).
  __ nop();
  __ nop();
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 Isolate::kNoDeoptId,
                                 token_pos());
}


bool IfThenElseInstr::IsSupported() {
  return false;
}


bool IfThenElseInstr::Supports(ComparisonInstr* comparison,
                               Value* v1,
                               Value* v2) {
  UNREACHABLE();
  return false;
}


LocationSummary* IfThenElseInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}


LocationSummary* ClosureCallInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


LocationSummary* LoadLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ lw(result, Address(FP, local().index() * kWordSize));
}


LocationSummary* StoreLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ sw(value, Address(FP, local().index() * kWordSize));
}


LocationSummary* ConstantInstr::MakeLocationSummary() const {
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


LocationSummary* AssertAssignableInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));  // Value.
  summary->set_in(1, Location::RegisterLocation(A1));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(A2));  // Type arguments.
  summary->set_out(Location::RegisterLocation(A0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_out(Location::RegisterLocation(A0));
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
  __ BranchEqual(reg, Bool::True(), &done);
  __ BranchEqual(reg, Bool::False(), &done);

  __ Push(reg);  // Push the source object.
  compiler->GenerateCallRuntime(token_pos,
                                deopt_id,
                                kConditionTypeErrorRuntimeEntry,
                                locs);
  // We should never return here.
  __ break_(0);
  __ Bind(&done);
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out().reg();

  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}


LocationSummary* ArgumentDefinitionTestInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ArgumentDefinitionTestInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const bool is_checked_strict_equal =
      HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  if (receiver_class_id() == kMintCid) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (receiver_class_id() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (receiver_class_id() == kSmiCid) {
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
  if (is_checked_strict_equal) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_in(1, Location::RequiresRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (IsPolymorphic()) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    UNIMPLEMENTED();  // TODO(regis): Verify register allocation.
    return locs;
  }
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A1));
  locs->set_in(1, Location::RegisterLocation(A0));
  locs->set_temp(0, Location::RegisterLocation(T0));
  locs->set_out(Location::RegisterLocation(V0));
  return locs;
}


// A1: left.
// A0: right.
// Uses T0 to load ic_call_data.
// Result in V0.
static void EmitEqualityAsInstanceCall(FlowGraphCompiler* compiler,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       Token::Kind kind,
                                       LocationSummary* locs,
                                       const ICData& original_ic_data) {
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                   deopt_id,
                                   token_pos);
  }
  const int kNumberOfArguments = 2;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 2;

  Label check_identity;
  __ LoadImmediate(TMP1, reinterpret_cast<intptr_t>(Object::null()));
  __ beq(A1, TMP1, &check_identity);
  __ beq(A0, TMP1, &check_identity);

  ICData& equality_ic_data = ICData::ZoneHandle();
  if (compiler->is_optimizing() && FLAG_propagate_ic_data) {
    ASSERT(!original_ic_data.IsNull());
    if (original_ic_data.NumberOfChecks() == 0) {
      // IC call for reoptimization populates original ICData.
      equality_ic_data = original_ic_data.raw();
    } else {
      // Megamorphic call.
      equality_ic_data = original_ic_data.AsUnaryClassChecks();
    }
  } else {
    equality_ic_data = ICData::New(compiler->parsed_function().function(),
                                   Symbols::EqualOperator(),
                                   deopt_id,
                                   kNumArgumentsChecked);
  }
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  compiler->GenerateInstanceCall(deopt_id,
                                 token_pos,
                                 kNumberOfArguments,
                                 kNoArgumentNames,
                                 locs,
                                 equality_ic_data);
  Label check_ne;
  __ b(&check_ne);

  __ Bind(&check_identity);
  Label equality_done;
  if (compiler->is_optimizing()) {
    // No need to update IC data.
    Label is_true;
    __ beq(A1, A0, &is_true);
    __ LoadObject(V0, (kind == Token::kEQ) ? Bool::False() : Bool::True());
    __ b(&equality_done);
    __ Bind(&is_true);
    __ LoadObject(V0, (kind == Token::kEQ) ? Bool::True() : Bool::False());
    if (kind == Token::kNE) {
      // Skip not-equal result conversion.
      __ b(&equality_done);
    }
  } else {
    // Call stub, load IC data in register. The stub will update ICData if
    // necessary.
    Register ic_data_reg = locs->temp(0).reg();
    ASSERT(ic_data_reg == T0);  // Stub depends on it.
    __ LoadObject(ic_data_reg, equality_ic_data);
    // Pass left in A1 and right in A0.
    compiler->GenerateCall(token_pos,
                           &StubCode::EqualityWithNullArgLabel(),
                           PcDescriptors::kOther,
                           locs);
  }
  __ Bind(&check_ne);
  if (kind == Token::kNE) {
    Label true_label, done;
    // Negate the condition: true label returns false and vice versa.
    __ BranchEqual(V0, Bool::True(), &true_label);
    __ LoadObject(V0, Bool::True());
    __ b(&done);
    __ Bind(&true_label);
    __ LoadObject(V0, Bool::False());
    __ Bind(&done);
  }
  __ Bind(&equality_done);
}


static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         Label* value_is_smi = NULL) {
  Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ andi(TMP1, value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ beq(TMP1, ZR, &done);
  } else {
    __ beq(TMP1, ZR, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}


// Emit code when ICData's targets are all Object == (which is ===).
static void EmitCheckedStrictEqual(FlowGraphCompiler* compiler,
                                   const ICData& ic_data,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch,
                                   intptr_t deopt_id) {
  UNIMPLEMENTED();
}


// First test if receiver is NULL, in which case === is applied.
// If type feedback was provided (lists of <class-id, target>), do a
// type by type check (either === or static call to the operator.
static void EmitGenericEqualityCompare(FlowGraphCompiler* compiler,
                                       LocationSummary* locs,
                                       Token::Kind kind,
                                       BranchInstr* branch,
                                       const ICData& ic_data,
                                       intptr_t deopt_id,
                                       intptr_t token_pos) {
  UNIMPLEMENTED();
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


static void EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                const LocationSummary& locs,
                                Token::Kind kind,
                                BranchInstr* branch) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(CMPRES, right.reg(), left.constant());
    true_condition = FlowGraphCompiler::FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(CMPRES, left.reg(), right.constant());
  } else {
    __ subu(CMPRES, left.reg(), right.reg());
  }

  if (branch != NULL) {
    branch->EmitBranchOnCondition(compiler, true_condition);
  } else {
    Register result = locs.out().reg();
    Label done, is_true;
    switch (true_condition) {
      case EQ: __ beq(CMPRES, ZR, &is_true); break;
      case NE: __ bne(CMPRES, ZR, &is_true); break;
      case GT: __ bgtz(CMPRES, &is_true); break;
      case GE: __ bgez(CMPRES, &is_true); break;
      case LT: __ bltz(CMPRES, &is_true); break;
      case LE: __ blez(CMPRES, &is_true); break;
      default:
        UNREACHABLE();
        break;
    }
    __ LoadObject(result, Bool::False());
    __ b(&done);
    __ Bind(&is_true);
    __ LoadObject(result, Bool::True());
    __ Bind(&done);
  }
}


static void EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                      const LocationSummary& locs,
                                      Token::Kind kind,
                                      BranchInstr* branch) {
  UNIMPLEMENTED();
}


static void EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchInstr* branch) {
  UNIMPLEMENTED();
}


static void EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch) {
  UNIMPLEMENTED();
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  BranchInstr* kNoBranch = NULL;
  if (receiver_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (receiver_class_id() == kMintCid) {
    EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  const bool is_checked_strict_equal =
      HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  if (is_checked_strict_equal) {
    EmitCheckedStrictEqual(compiler, *ic_data(), *locs(), kind(), kNoBranch,
                           deopt_id());
    return;
  }
  if (IsPolymorphic()) {
    EmitGenericEqualityCompare(compiler, locs(), kind(), kNoBranch, *ic_data(),
                               deopt_id(), token_pos());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  ASSERT(left == A1);
  ASSERT(right == A0);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             kind(),
                             locs(),
                             *ic_data());
  ASSERT(locs()->out().reg() == V0);
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  if (receiver_class_id() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (receiver_class_id() == kMintCid) {
    EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  const bool is_checked_strict_equal =
      HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  if (is_checked_strict_equal) {
    EmitCheckedStrictEqual(compiler, *ic_data(), *locs(), kind(), branch,
                           deopt_id());
    return;
  }
  if (IsPolymorphic()) {
    EmitGenericEqualityCompare(compiler, locs(), kind(), branch, *ic_data(),
                               deopt_id(), token_pos());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  ASSERT(left == A1);
  ASSERT(right == A0);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             Token::kEQ,  // kNE reverse occurs at branch.
                             locs(),
                             *ic_data());
  if (branch->is_checked()) {
    EmitAssertBoolean(V0, token_pos(), deopt_id(), locs(), compiler);
  }
  Condition branch_condition = (kind() == Token::kNE) ? NE : EQ;
  __ CompareObject(CMPRES, V0, Bool::True());
  branch->EmitBranchOnCondition(compiler, branch_condition);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operands_class_id() == kMintCid) {
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
  if (operands_class_id() == kDoubleCid) {
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(Location::RequiresRegister());
    return summary;
  } else if (operands_class_id() == kSmiCid) {
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
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  // Pick arbitrary fixed input registers because this is a call.
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_in(1, Location::RegisterLocation(A1));
  locs->set_out(Location::RegisterLocation(V0));
  return locs;
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }
  if (operands_class_id() == kMintCid) {
    EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }
  if (operands_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }

  // Push arguments for the call.
  // TODO(fschneider): Split this instruction into different types to avoid
  // explicitly pushing arguments to the call here.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ Push(left);
  __ Push(right);
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptRelationalOp);
    // Load class into A2.
    const intptr_t kNumArguments = 2;
    LoadValueCid(compiler, A2, left);
    compiler->EmitTestAndCall(ICData::Handle(ic_data()->AsUnaryClassChecks()),
                              A2,  // Class id register.
                              kNumArguments,
                              Array::Handle(),  // No named arguments.
                              deopt,  // Deoptimize target.
                              deopt_id(),
                              token_pos(),
                              locs());
    return;
  }
  const String& function_name =
      String::ZoneHandle(Symbols::New(Token::Str(kind())));
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                   deopt_id(),
                                   token_pos());
  }
  const intptr_t kNumArguments = 2;
  const intptr_t kNumArgsChecked = 2;  // Type-feedback.
  ICData& relational_ic_data = ICData::ZoneHandle(ic_data()->raw());
  if (compiler->is_optimizing() && FLAG_propagate_ic_data) {
    ASSERT(!ic_data()->IsNull());
    if (ic_data()->NumberOfChecks() == 0) {
      // IC call for reoptimization populates original ICData.
      relational_ic_data = ic_data()->raw();
    } else {
      // Megamorphic call.
      relational_ic_data = ic_data()->AsUnaryClassChecks();
    }
  } else {
    relational_ic_data = ICData::New(compiler->parsed_function().function(),
                                     function_name,
                                     deopt_id(),
                                     kNumArgsChecked);
  }
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 kNumArguments,
                                 Array::ZoneHandle(),  // No optional arguments.
                                 locs(),
                                 relational_ic_data);
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operands_class_id() == kMintCid) {
    EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operands_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  EmitNativeCode(compiler);
  __ CompareObject(CMPRES, V0, Bool::True());
  branch->EmitBranchOnCondition(compiler, EQ);
}


LocationSummary* NativeCallInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(A1));
  locs->set_temp(1, Location::RegisterLocation(A2));
  locs->set_temp(2, Location::RegisterLocation(T5));
  locs->set_out(Location::RegisterLocation(V0));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == A1);
  ASSERT(locs()->temp(1).reg() == A2);
  ASSERT(locs()->temp(2).reg() == T5);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in A2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(A2, FP, (kLastParamSlotIndex +
                             function().NumParameters() - 1) * kWordSize);
  } else {
    __ AddImmediate(A2, FP, kFirstLocalSlotIndex * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(native_c_function());
#if defined(USING_SIMULATOR)
  entry = Simulator::RedirectExternalReference(entry, Simulator::kNativeCall);
#endif
  __ LoadImmediate(T5, entry);
  __ LoadImmediate(A1, NativeArguments::ComputeArgcTag(function()));
  compiler->GenerateCall(token_pos(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


CompileType LoadIndexedInstr::ComputeType() const {
  UNIMPLEMENTED();
  return CompileType::Dynamic();
}


Representation LoadIndexedInstr::representation() const {
  UNIMPLEMENTED();
  return kTagged;
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  UNIMPLEMENTED();
  return kTagged;
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* GuardFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void GuardFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstanceOfInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CreateArrayInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
AllocateObjectWithBoundsCheckInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateObjectWithBoundsCheckInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* LoadFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorTypeArgumentsInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ExtractConstructorTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary*
ExtractConstructorInstantiatorInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ExtractConstructorInstantiatorInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CloneContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CatchEntryInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CatchEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary() const {
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
    compiler->pending_deoptimization_env_ = instruction_->env();
    compiler->GenerateCallRuntime(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  instruction_->locs());
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

  __ LoadImmediate(TMP1, Isolate::Current()->stack_limit_address());

  __ lw(TMP1, Address(TMP1));
  __ BranchLessEqual(SP, TMP1, slow_path->entry_label());

  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    UNIMPLEMENTED();
    return NULL;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RegisterOrSmiConstant(right()));
    // We make use of 3-operand instructions by not requiring result register
    // to be identical to first input register as on Intel.
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    UNIMPLEMENTED();
    return;
  }

  ASSERT(!is_truncating());
  Register left = locs()->in(0).reg();
  Register result = locs()->out().reg();
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt  = compiler->AddDeoptStub(deopt_id(), kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    int32_t imm = reinterpret_cast<int32_t>(constant.raw());
    switch (op_kind()) {
      case Token::kSUB: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, -imm);
        } else {
          __ SubImmediateDetectOverflow(result, left, imm, CMPRES);
          __ bltz(CMPRES, deopt);
        }
        break;
      }
      case Token::kADD: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, imm);
        } else {
          __ AddImmediateDetectOverflow(result, left, imm, CMPRES);
          __ bltz(CMPRES, deopt);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 2) {
          __ sll(result, left, 1);
        } else {
          __ LoadImmediate(TMP1, value);
          __ mult(left, TMP1);
          __ mflo(result);
        }
        if (deopt != NULL) {
          UNIMPLEMENTED();
        }
        break;
      }
      case Token::kTRUNCDIV: {
        UNIMPLEMENTED();
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        if (Utils::IsUint(kImmBits, imm)) {
          __ andi(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP1, imm);
          __ and_(result, left, TMP1);
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        if (Utils::IsUint(kImmBits, imm)) {
          __ ori(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP1, imm);
          __ or_(result, left, TMP1);
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        if (Utils::IsUint(kImmBits, imm)) {
          __ xori(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP1, imm);
          __ xor_(result, left, TMP1);
        }
        break;
      }
      case Token::kSHR: {
        UNIMPLEMENTED();
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }

  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD: {
      if (deopt == NULL) {
        __ addu(result, left, right);
      } else {
        __ AdduDetectOverflow(result, left, right, CMPRES);
        __ bltz(CMPRES, deopt);
      }
      break;
    }
    case Token::kSUB: {
      if (deopt == NULL) {
        __ subu(result, left, right);
      } else {
        __ SubuDetectOverflow(result, left, right, CMPRES);
        __ bltz(CMPRES, deopt);
      }
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ mult(left, right);
      __ mflo(result);
      if (deopt != NULL) {
        UNIMPLEMENTED();
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ or_(result, left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xor_(result, left, right);
      break;
    }
    case Token::kTRUNCDIV: {
      UNIMPLEMENTED();
      break;
    }
    case Token::kSHR: {
      UNIMPLEMENTED();
      break;
    }
    case Token::kDIV: {
      // Dispatches to 'Double./'.
      // TODO(srdjan): Implement as conversion to double and double division.
      UNREACHABLE();
      break;
    }
    case Token::kMOD: {
      // TODO(srdjan): Implement.
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


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathSqrtInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void MathSqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptPolymorphicInstanceCallTestFail);
  if (ic_data().NumberOfChecks() == 0) {
    __ b(deopt);
    return;
  }
  ASSERT(ic_data().num_args_tested() == 1);
  if (!with_checks()) {
    ASSERT(ic_data().HasOneTarget());
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(instance_call()->deopt_id(),
                                 instance_call()->token_pos(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs());
    return;
  }

  // Load receiver into R0.
  __ lw(T0, Address(SP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  LoadValueCid(compiler, T2, T0,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            T2,  // Class id register.
                            instance_call()->ArgumentCount(),
                            instance_call()->argument_names(),
                            deopt,
                            instance_call()->deopt_id(),
                            instance_call()->token_pos(),
                            locs());
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* CheckSmiInstr::MakeLocationSummary() const {
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
  __ andi(TMP1, value, Immediate(kSmiTagMask));
  __ bne(TMP1, ZR, deopt);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ThrowInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* GotoInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Add deoptimization descriptor for deoptimizing instructions
  // that may be inserted before this instruction.
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                   GetDeoptId(),
                                   0);  // No token position.
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


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQ: return NE;
    case NE: return EQ;
    case LT: return GE;
    case LE: return GT;
    case GT: return LE;
    case GE: return LT;
    default:
      OS::Print("Error: Condition not recognized: %d\n", condition);
      UNIMPLEMENTED();
      return EQ;
  }
}


void ControlInstruction::EmitBranchOnValue(FlowGraphCompiler* compiler,
                                           bool value) {
  if (value && !compiler->CanFallThroughTo(true_successor())) {
    __ b(compiler->GetJumpLabel(true_successor()));
  } else if (!value && !compiler->CanFallThroughTo(false_successor())) {
    __ b(compiler->GetJumpLabel(false_successor()));
  }
}


// The comparison result is in CMPRES.
void ControlInstruction::EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                               Condition true_condition) {
  if (compiler->CanFallThroughTo(false_successor())) {
    // If the next block is the false successor we will fall through to it.
    Label* label = compiler->GetJumpLabel(true_successor());
    switch (true_condition) {
      case EQ: __ beq(CMPRES, ZR, label); break;
      case NE: __ bne(CMPRES, ZR, label); break;
      case GT: __ bgtz(CMPRES, label); break;
      case GE: __ bgez(CMPRES, label); break;
      case LT: __ bltz(CMPRES, label); break;
      case LE: __ blez(CMPRES, label); break;
      default:
        UNREACHABLE();
        break;
    }
  } else {
    // If the next block is the true successor we negate comparison and fall
    // through to it.
    Condition false_condition = NegateCondition(true_condition);
    Label* label = compiler->GetJumpLabel(false_successor());
    switch (false_condition) {
      case EQ: __ beq(CMPRES, ZR, label); break;
      case NE: __ bne(CMPRES, ZR, label); break;
      case GT: __ bgtz(CMPRES, label); break;
      case GE: __ bgez(CMPRES, label); break;
      case LT: __ bltz(CMPRES, label); break;
      case LE: __ blez(CMPRES, label); break;
      default:
        UNREACHABLE();
        break;
    }
    // Fall through or jump to the true successor.
    if (!compiler->CanFallThroughTo(true_successor())) {
      __ b(compiler->GetJumpLabel(true_successor()));
    }
  }
}


LocationSummary* CurrentContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StrictCompareInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterOrConstant(left()));
  locs->set_in(1, Location::RegisterOrConstant(right()));
  locs->set_out(Location::RequiresRegister());
  return locs;
}


// Special code for numbers (compare values instead of references.)
void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  if (left.IsConstant() && right.IsConstant()) {
    // TODO(vegorov): should be eliminated earlier by constant propagation.
    const bool result = (kind() == Token::kEQ_STRICT) ?
        left.constant().raw() == right.constant().raw() :
        left.constant().raw() != right.constant().raw();
    __ LoadObject(locs()->out().reg(), result ? Bool::True() : Bool::False());
    return;
  }
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(),
                                          left.constant(),
                                          needs_number_check());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(),
                                          right.constant(),
                                          needs_number_check());
  } else {
    compiler->EmitEqualityRegRegCompare(left.reg(),
                                       right.reg(),
                                       needs_number_check());
  }

  Register result = locs()->out().reg();
  Label load_true, done;
  if (kind() == Token::kEQ_STRICT) {
    __ beq(CMPRES, ZR, &load_true);
  } else {
    ASSERT(kind() == Token::kNE_STRICT);
    __ bne(CMPRES, ZR, &load_true);
  }
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&load_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  if (left.IsConstant() && right.IsConstant()) {
    // TODO(vegorov): should be eliminated earlier by constant propagation.
    const bool result = (kind() == Token::kEQ_STRICT) ?
        left.constant().raw() == right.constant().raw() :
        left.constant().raw() != right.constant().raw();
    branch->EmitBranchOnValue(compiler, result);
    return;
  }
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(),
                                          left.constant(),
                                          needs_number_check());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(),
                                          right.constant(),
                                          needs_number_check());
  } else {
    compiler->EmitEqualityRegRegCompare(left.reg(),
                                        right.reg(),
                                        needs_number_check());
  }

  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQ : NE;
  branch->EmitBranchOnCondition(compiler, true_condition);
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* ChainContextInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void ChainContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* StoreVMFieldInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void StoreVMFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().Owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}


LocationSummary* CreateClosureInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void CreateClosureInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

