// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

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
  __ TraceSimMsg("PushArgumentInstr");
  if (compiler->is_optimizing()) {
    Location value = locs()->in(0);
    if (value.IsRegister()) {
      __ Push(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      const intptr_t value_offset = value.ToStackSlotOffset();
      __ LoadFromOffset(TMP, FP, value_offset);
      __ Push(TMP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(V0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("ReturnInstr");
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
    __ TraceSimMsg("Stack Check");
    const intptr_t fp_sp_dist =
        (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
    ASSERT(fp_sp_dist <= 0);
    __ subu(CMPRES1, SP, FP);

    __ BranchEqual(CMPRES1, fp_sp_dist, &stack_ok);
    __ break_(0);

    __ Bind(&stack_ok);
  }
#endif
  // This sequence is patched by a debugger breakpoint. There is no need for
  // extra NOP instructions here because the sequence patched in for a
  // breakpoint is shorter than the sequence here.
  __ LeaveDartFrameAndReturn();
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
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(V0));
  result->set_temp(0, Location::RegisterLocation(S4));  // Arg. descriptor.
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
  ASSERT(temp_reg == S4);
  __ LoadObject(temp_reg, arguments_descriptor);
  compiler->GenerateDartCall(deopt_id(),
                             token_pos(),
                             &StubCode::CallClosureFunctionLabel(),
                             PcDescriptors::kClosureCall,
                             locs());
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("LoadLocalInstr");
  Register result = locs()->out().reg();
  __ lw(result, Address(FP, local().index() * kWordSize));
}


LocationSummary* StoreLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StoreLocalInstr");
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
    __ TraceSimMsg("ConstantInstr");
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
  summary->set_in(1, Location::RegisterLocation(A2));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(A1));  // Type arguments.
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

  __ TraceSimMsg("AssertBooleanInstr");
  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary() const {
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
  if (IsCheckedStrictEqual()) {
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
    locs->set_in(0, Location::RegisterLocation(A1));
    locs->set_in(1, Location::RegisterLocation(A0));
    locs->set_temp(0, Location::RegisterLocation(T0));
    locs->set_out(Location::RegisterLocation(V0));
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
  const Array& kNoArgumentNames = Object::null_array();
  const int kNumArgumentsChecked = 2;

  __ TraceSimMsg("EmitEqualityAsInstanceCall");
  __ Comment("EmitEqualityAsInstanceCall");
  Label check_identity;
  __ lw(A1, Address(SP, 1 * kWordSize));
  __ lw(A0, Address(SP, 0 * kWordSize));
  __ LoadImmediate(CMPRES1, reinterpret_cast<int32_t>(Object::null()));
  __ beq(A1, CMPRES1, &check_identity);
  __ beq(A0, CMPRES1, &check_identity);

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
    const Array& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::New(kNumberOfArguments,
                                               kNoArgumentNames));
    equality_ic_data = ICData::New(compiler->parsed_function().function(),
                                   Symbols::EqualOperator(),
                                   arguments_descriptor,
                                   deopt_id,
                                   kNumArgumentsChecked);
  }
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
    __ lw(A1, Address(SP, 1 * kWordSize));
    __ lw(A0, Address(SP, 0 * kWordSize));
    __ addiu(SP, SP, Immediate(2 * kWordSize));
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
                           PcDescriptors::kRuntimeCall,
                           locs);
    __ Drop(2);
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
  __ TraceSimMsg("LoadValueCid");
  Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ andi(CMPRES1, value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ beq(CMPRES1, ZR, &done);
  } else {
    __ beq(CMPRES1, ZR, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
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


// Branches on condition c assuming comparison results in CMPRES and CMPRES2.
static void EmitBranchAfterCompare(
    FlowGraphCompiler* compiler, Condition c, Label* is_true) {
  switch (c) {
    case EQ: __ beq(CMPRES1, CMPRES2, is_true); break;
    case NE: __ bne(CMPRES1, CMPRES2, is_true); break;
    case GT: __ bne(CMPRES2, ZR, is_true); break;
    case GE: __ beq(CMPRES1, ZR, is_true); break;
    case LT: __ bne(CMPRES1, ZR, is_true); break;
    case LE: __ beq(CMPRES2, ZR, is_true); break;
    default:
      UNREACHABLE();
      break;
  }
}


// A1: left, also on stack.
// A0: right, also on stack.
static void EmitEqualityAsPolymorphicCall(FlowGraphCompiler* compiler,
                                          const ICData& orig_ic_data,
                                          LocationSummary* locs,
                                          BranchInstr* branch,
                                          Token::Kind kind,
                                          intptr_t deopt_id,
                                          intptr_t token_pos) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const ICData& ic_data = ICData::Handle(orig_ic_data.AsUnaryClassChecks());
  ASSERT(ic_data.NumberOfChecks() > 0);
  ASSERT(ic_data.num_args_tested() == 1);
  Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptEquality);
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  ASSERT(left == A1);
  ASSERT(right == A0);
  Register temp = locs->temp(0).reg();

  __ TraceSimMsg("EmitEqualityAsPolymorphicCall");
  __ Comment("EmitEqualityAsPolymorphicCall");

  LoadValueCid(compiler, temp, left,
               (ic_data.GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);
  // 'temp' contains class-id of the left argument.
  ObjectStore* object_store = Isolate::Current()->object_store();
  Condition cond = TokenKindToSmiCondition(kind);
  Label done;
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    // Assert that the Smi is at position 0, if at all.
    ASSERT((ic_data.GetReceiverClassIdAt(i) != kSmiCid) || (i == 0));
    Label next_test;
    if (i < len - 1) {
      __ BranchNotEqual(temp, ic_data.GetReceiverClassIdAt(i), &next_test);
    } else {
      __ BranchNotEqual(temp, ic_data.GetReceiverClassIdAt(i), deopt);
    }
    const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(i));
    if (target.Owner() == object_store->object_class()) {
      // Object.== is same as ===.
      __ Drop(2);
      __ slt(CMPRES1, left, right);
      __ slt(CMPRES2, right, left);
      if (branch != NULL) {
        branch->EmitBranchOnCondition(compiler, cond);
      } else {
        Register result = locs->out().reg();
        Label load_true;
        EmitBranchAfterCompare(compiler, cond, &load_true);
        __ LoadObject(result, Bool::False());
        __ b(&done);
        __ Bind(&load_true);
        __ LoadObject(result, Bool::True());
      }
    } else {
      const int kNumberOfArguments = 2;
      const Array& kNoArgumentNames = Object::null_array();
      compiler->GenerateStaticCall(deopt_id,
                                   token_pos,
                                   target,
                                   kNumberOfArguments,
                                   kNoArgumentNames,
                                   locs);
      if (branch == NULL) {
        if (kind == Token::kNE) {
          Label is_true;
          __ CompareObject(CMPRES1, CMPRES2, V0, Bool::True());
          __ beq(CMPRES, CMPRES2, &is_true);
          __ LoadObject(V0, Bool::True());
          __ b(&done);
          __ Bind(&is_true);
          __ LoadObject(V0, Bool::False());
        }
      } else {
        if (branch->is_checked()) {
          EmitAssertBoolean(V0, token_pos, deopt_id, locs, compiler);
        }
        __ CompareObject(CMPRES1, CMPRES2, V0, Bool::True());
        branch->EmitBranchOnCondition(compiler, cond);
      }
    }
    if (i < len - 1) {
      __ b(&done);
      __ Bind(&next_test);
    }
  }
  __ Bind(&done);
}


// Emit code when ICData's targets are all Object == (which is ===).
static void EmitCheckedStrictEqual(FlowGraphCompiler* compiler,
                                   const ICData& orig_ic_data,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch,
                                   intptr_t deopt_id) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  Register left = locs.in(0).reg();
  Register right = locs.in(1).reg();
  Register temp = locs.temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptEquality);

  __ Comment("CheckedStrictEqual");

  __ andi(CMPRES, left, Immediate(kSmiTagMask));
  __ beq(CMPRES, ZR, deopt);
  // 'left' is not Smi.
  Label identity_compare;
  __ LoadImmediate(CMPRES1, reinterpret_cast<int32_t>(Object::null()));
  __ beq(right, CMPRES1, &identity_compare);
  __ beq(left, CMPRES1, &identity_compare);

  __ LoadClassId(temp, left);
  const ICData& ic_data = ICData::Handle(orig_ic_data.AsUnaryClassChecks());
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (i == (len - 1)) {
      __ BranchNotEqual(temp, ic_data.GetReceiverClassIdAt(i), deopt);
    } else {
      __ BranchEqual(temp, ic_data.GetReceiverClassIdAt(i), &identity_compare);
    }
  }
  __ Bind(&identity_compare);
  __ subu(CMPRES1, left, right);
  if (branch == NULL) {
    Label done, is_equal;
    Register result = locs.out().reg();
    __ beq(CMPRES, ZR, &is_equal);
    // Not equal.
    __ LoadObject(result,
                  (kind == Token::kEQ) ? Bool::False() : Bool::True());
    __ b(&done);
    __ Bind(&is_equal);
    __ LoadObject(result,
                  (kind == Token::kEQ) ? Bool::True() : Bool::False());
    __ Bind(&done);

  } else {
    Condition cond = TokenKindToSmiCondition(kind);
    __ mov(CMPRES2, ZR);
    branch->EmitBranchOnCondition(compiler, cond);
  }
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
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  ASSERT(!ic_data.IsNull() && (ic_data.NumberOfChecks() > 0));
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  Label done, identity_compare, non_null_compare;
  __ TraceSimMsg("EmitGenericEqualityCompare");
  __ Comment("EmitGenericEqualityCompare");
  __ LoadImmediate(CMPRES1, reinterpret_cast<int32_t>(Object::null()));
  __ beq(right, CMPRES1, &identity_compare);
  __ bne(left, CMPRES1, &non_null_compare);

  // Comparison with NULL is "===".
  __ Bind(&identity_compare);
  Condition cond = TokenKindToSmiCondition(kind);
  __ slt(CMPRES1, left, right);
  __ slt(CMPRES2, right, left);
  if (branch != NULL) {
    branch->EmitBranchOnCondition(compiler, cond);
  } else {
    Register result = locs->out().reg();
    Label load_true;
    EmitBranchAfterCompare(compiler, cond, &load_true);
    __ LoadObject(result, Bool::False());
    __ b(&done);
    __ Bind(&load_true);
    __ LoadObject(result, Bool::True());
  }
  __ b(&done);
  __ Bind(&non_null_compare);  // Receiver is not null.
  ASSERT(left == A1);
  ASSERT(right == A0);
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
  EmitEqualityAsPolymorphicCall(compiler, ic_data, locs, branch, kind,
                                deopt_id, token_pos);
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
    default:
      UNREACHABLE();
      return EQ;
  }
}


static void EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                const LocationSummary& locs,
                                Token::Kind kind,
                                BranchInstr* branch) {
  __ TraceSimMsg("EmitSmiComparisonOp");
  __ Comment("EmitSmiComparisonOp");
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(CMPRES1, CMPRES2, right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(CMPRES1, CMPRES2, left.reg(), right.constant());
  } else {
    __ slt(CMPRES1, left.reg(), right.reg());
    __ slt(CMPRES2, right.reg(), left.reg());
  }

  if (branch != NULL) {
    branch->EmitBranchOnCondition(compiler, true_condition);
  } else {
    Register result = locs.out().reg();
    Label done, is_true;
    EmitBranchAfterCompare(compiler, true_condition, &is_true);
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


static void EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch) {
  DRegister left = locs.in(0).fpu_reg();
  DRegister right = locs.in(1).fpu_reg();

  __ Comment("DoubleComparisonOp(left=%d, right=%d)", left, right);

  Condition true_condition = TokenKindToDoubleCondition(kind);
  if (branch != NULL) {
    compiler->EmitDoubleCompareBranch(
        true_condition, left, right, branch);
  } else {
    compiler->EmitDoubleCompareBool(
        true_condition, left, right, locs.out().reg());
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  BranchInstr* kNoBranch = NULL;
  __ Comment("EqualityCompareInstr");
  if (operation_cid() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (operation_cid() == kMintCid) {
    EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (operation_cid() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (IsCheckedStrictEqual()) {
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
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
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
  __ TraceSimMsg("EqualityCompareInstr");
  __ Comment("EqualityCompareInstr:BranchCode");
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  if (operation_cid() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operation_cid() == kMintCid) {
    EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operation_cid() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (IsCheckedStrictEqual()) {
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
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(A1, Address(SP, 1 * kWordSize));
  __ sw(A0, Address(SP, 0 * kWordSize));
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
  __ CompareObject(CMPRES1, CMPRES2, V0, Bool::True());
  branch->EmitBranchOnCondition(compiler, branch_condition);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary() const {
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
  } else if (operation_cid() == kSmiCid) {
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
  __ TraceSimMsg("RelationalOpInstr");
  if (operation_cid() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }
  if (operation_cid() == kMintCid) {
    EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }
  if (operation_cid() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), NULL);
    return;
  }

  // Push arguments for the call.
  // TODO(fschneider): Split this instruction into different types to avoid
  // explicitly pushing arguments to the call here.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(left, Address(SP, 1 * kWordSize));
  __ sw(right, Address(SP, 0 * kWordSize));
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptRelationalOp);
    // Load class into A2.
    const intptr_t kNumArguments = 2;
    LoadValueCid(compiler, A2, left);
    compiler->EmitTestAndCall(ICData::Handle(ic_data()->AsUnaryClassChecks()),
                              A2,  // Class id register.
                              kNumArguments,
                              Object::null_array(),  // No named arguments.
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
    const Array& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::New(kNumArguments,
                                               Object::null_array()));
    relational_ic_data = ICData::New(compiler->parsed_function().function(),
                                     function_name,
                                     arguments_descriptor,
                                     deopt_id(),
                                     kNumArgsChecked);
  }
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 kNumArguments,
                                 Object::null_array(),  // No optional args.
                                 locs(),
                                 relational_ic_data);
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  __ TraceSimMsg("RelationalOpInstr");
  if (operation_cid() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operation_cid() == kMintCid) {
    EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operation_cid() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  EmitNativeCode(compiler);
  __ CompareObject(CMPRES1, CMPRES2, V0, Bool::True());
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
  __ TraceSimMsg("NativeCallInstr");
  ASSERT(locs()->temp(0).reg() == A1);
  ASSERT(locs()->temp(1).reg() == A2);
  ASSERT(locs()->temp(2).reg() == T5);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in A2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(A2, FP, (kParamEndSlotFromFp +
                             function().NumParameters()) * kWordSize);
  } else {
    __ AddImmediate(A2, FP, kFirstLocalSlotFromFp * kWordSize);
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
  }
  __ LoadImmediate(T5, entry);
  __ LoadImmediate(A1, NativeArguments::ComputeArgcTag(function()));
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         PcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ TraceSimMsg("StringFromCharCodeInstr");

  __ LoadImmediate(result,
                   reinterpret_cast<uword>(Symbols::PredefinedAddress()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ sll(TMP1, char_code, 1);  // Char code is a smi.
  __ addu(TMP1, TMP1, result);
  __ lw(result, Address(TMP1));
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out().reg();
  __ LoadFromOffset(result, object, offset() - kHeapObjectTag);
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out().reg();
  Label load, done;
  __ andi(CMPRES, object, Immediate(kSmiTagMask));
  __ bne(CMPRES, ZR, &load);
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
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  // TODO(regis): Revisit and see if the index can be immediate.
  locs->set_in(1, Location::WritableRegister());
  if (representation() == kUnboxedDouble) {
    locs->set_out(Location::RequiresFpuRegister());
  } else {
    locs->set_out(Location::RequiresRegister());
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("LoadIndexedInstr");
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
      __ sll(index.reg(), index.reg(), 1);
      break;
    }
    case 8: {
      __ sll(index.reg(), index.reg(), 2);
      break;
    }
    case 16: {
      __ sll(index.reg(), index.reg(), 3);
      break;
    }
    default:
      UNREACHABLE();
  }
  __ addu(index.reg(), array, index.reg());

  if (IsExternal()) {
    element_address = Address(index.reg(), 0);
  } else {
    ASSERT(this->array()->definition()->representation() == kTagged);
    // If the data offset doesn't fit into the 18 bits we get for the addressing
    // mode, then we must load the offset into a register and add it to the
    // index.
    element_address = Address(index.reg(),
        FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
  }

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedMint) ||
      (representation() == kUnboxedFloat32x4)) {
    DRegister result = locs()->out().fpu_reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataUint32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataFloat32ArrayCid:
        // Load single precision float and promote to double.
        __ lwc1(STMP1, element_address);
        __ cvtds(result, STMP1);
        break;
      case kTypedDataFloat64ArrayCid:
        __ LoadDFromOffset(result, index.reg(),
            FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
        break;
      case kTypedDataFloat32x4ArrayCid:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

  Register result = locs()->out().reg();
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      __ lb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ lbu(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ lh(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
      __ lhu(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptInt32Load);
        __ lw(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ BranchSignedLess(result, 0xC0000000, deopt);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptUint32Load);
        __ lw(result, element_address);
        // Verify that the unsigned value in 'result' can fit inside a Smi.
        __ LoadImmediate(TMP1, 0xC0000000);
        __ and_(CMPRES, result, TMP1);
        __ bne(CMPRES, ZR, deopt);
        __ SmiTag(result);
      }
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ lw(result, element_address);
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
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary() const {
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
      // TODO(regis): Verify.
      // Need temp register for float-to-double conversion.
      locs->AddTemp(Location::RequiresFpuRegister());
      // Fall through.
    case kTypedDataFloat64ArrayCid:  // TODO(srdjan): Support Float64 constants.
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
  __ TraceSimMsg("StoreIndexedInstr");
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
      __ sll(index.reg(), index.reg(), 1);
      break;
    }
    case 8: {
      __ sll(index.reg(), index.reg(), 2);
      break;
    }
    case 16: {
      __ sll(index.reg(), index.reg(), 3);
      break;
    }
    default:
      UNREACHABLE();
  }
  __ addu(index.reg(), array, index.reg());

  if (IsExternal()) {
    element_address = Address(index.reg(), 0);
  } else {
    ASSERT(this->array()->definition()->representation() == kTagged);
    element_address = Address(index.reg(),
        FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
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
    case kOneByteStringCid: {
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ LoadImmediate(TMP, static_cast<int8_t>(constant.Value()));
        __ sb(TMP, element_address);
      } else {
        Register value = locs()->in(2).reg();
        __ SmiUntag(value);
        __ sb(value, element_address);
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
        __ sb(TMP, element_address);
      } else {
        Register value = locs()->in(2).reg();
        Label store_value, bigger, smaller;
        __ SmiUntag(value);
        __ BranchUnsignedLess(value, 0xFF + 1, &store_value);
        __ LoadImmediate(TMP, 0xFF);
        __ slti(CMPRES, value, Immediate(1));
        __ movn(TMP, ZR, CMPRES);
        __ mov(value, TMP);
        __ Bind(&store_value);
        __ sb(value, element_address);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      Register value = locs()->in(2).reg();
      __ SmiUntag(value);
      __ sh(value, element_address);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (value()->IsSmiValue()) {
        ASSERT(RequiredInputRepresentation(2) == kTagged);
        Register value = locs()->in(2).reg();
        __ SmiUntag(value);
        __ sw(value, element_address);
      } else {
        UNIMPLEMENTED();
      }
      break;
    }
    case kTypedDataFloat32ArrayCid:
      // Convert to single precision.
      __ cvtsd(STMP1, locs()->in(2).fpu_reg());
      // Store.
      __ swc1(STMP1, element_address);
      break;
    case kTypedDataFloat64ArrayCid:
      __ StoreDToOffset(locs()->in(2).fpu_reg(), index.reg(),
          FlowGraphCompiler::DataOffsetFor(class_id()) - kHeapObjectTag);
      break;
    case kTypedDataFloat32x4ArrayCid:
      UNIMPLEMENTED();
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* GuardFieldInstr::MakeLocationSummary() const {
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
  __ TraceSimMsg("GuardFieldInstr");
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

  const bool ok_is_fall_through = (deopt != NULL);

  if (!compiler->is_optimizing() || (field_cid == kIllegalCid)) {
    if (!compiler->is_optimizing() && (field_reg == kNoRegister)) {
      // Currently we can't have different location summaries for optimized
      // and non-optimized code. So instead we manually pick up a register
      // that is known to be free because we know how non-optimizing compiler
      // allocates registers.
      field_reg = A0;
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
        value_cid_reg = A1;
        ASSERT((value_cid_reg != value_reg) && (field_reg != value_cid_reg));
      }

      LoadValueCid(compiler, value_cid_reg, value_reg);

      Label skip_length_check;

      __ lw(CMPRES1, field_cid_operand);
      __ bne(value_cid_reg, CMPRES1, &skip_length_check);
      if (field_has_length) {
        // Field guard may have remembered list length, check it.
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          __ lw(TMP, FieldAddress(value_reg, Array::length_offset()));
          __ LoadImmediate(CMPRES1, field_length);
          __ subu(CMPRES1, TMP, CMPRES1);
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          __ lw(TMP, FieldAddress(value_reg, TypedData::length_offset()));
          __ LoadImmediate(CMPRES1, field_length);
          __ subu(CMPRES1, TMP, CMPRES1);
        } else {
          ASSERT(field_cid == kIllegalCid);
          __ LoadImmediate(CMPRES1, 0x1);
        }
        __ bne(CMPRES1, ZR, fail);
      }
      __ Bind(&skip_length_check);
      __ lw(TMP1, field_nullability_operand);
      __ subu(CMPRES, value_cid_reg, TMP1);
    } else if (value_cid == kNullCid) {
      // TODO(regis): TMP1 may conflict. Revisit.
      __ lw(TMP1, field_nullability_operand);
      __ LoadImmediate(CMPRES, value_cid);
      __ subu(CMPRES, TMP1, CMPRES);
    } else {
      Label skip_length_check;
      // TODO(regis): TMP1 may conflict. Revisit.
      __ lw(TMP1, field_cid_operand);
      __ LoadImmediate(CMPRES, value_cid);
      __ subu(CMPRES, TMP1, CMPRES);
      __ bne(CMPRES, ZR, &skip_length_check);
      // Insert length check.
      if (field_has_length) {
        if (value_cid_reg == kNoRegister) {
          ASSERT(!compiler->is_optimizing());
          value_cid_reg = A1;
          ASSERT((value_cid_reg != value_reg) && (field_reg != value_cid_reg));
        }
        ASSERT(value_cid_reg != kNoRegister);
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          __ lw(TMP, FieldAddress(value_reg, Array::length_offset()));
          __ LoadImmediate(CMPRES, field_length);
          __ subu(CMPRES, TMP, CMPRES);
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          __ lw(TMP, FieldAddress(value_reg, TypedData::length_offset()));
          __ LoadImmediate(CMPRES, field_length);
          __ subu(CMPRES, TMP, CMPRES);
        } else {
          ASSERT(field_cid == kIllegalCid);
          __ LoadImmediate(CMPRES, 0x1);
        }
      }
      __ Bind(&skip_length_check);
    }
    __ beq(CMPRES, ZR, &ok);

    __ lw(CMPRES1, field_cid_operand);
    __ BranchNotEqual(CMPRES1, kIllegalCid, fail);

    if (value_cid == kDynamicCid) {
      __ sw(value_cid_reg, field_cid_operand);
      __ sw(value_cid_reg, field_nullability_operand);
      if (field_has_length) {
        Label check_array, local_exit, local_fail;
        __ BranchEqual(value_cid_reg, kNullCid, &local_fail);
        // Check for typed data array.
        __ BranchSignedGreater(value_cid_reg, kTypedDataFloat32x4ArrayCid,
                               &local_fail);
        __ BranchSignedLess(value_cid_reg, kTypedDataInt8ArrayCid,
                            &check_array);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ lw(value_cid_reg,
              FieldAddress(value_reg, TypedData::length_offset()));
        __ sw(value_cid_reg, field_length_operand);
        __ b(&local_exit);  // Updated field length typed data array.
        // Check for regular array.
        __ Bind(&check_array);
        __ BranchSignedGreater(value_cid_reg, kImmutableArrayCid,
                               &local_fail);
        __ BranchSignedLess(value_cid_reg, kArrayCid, &local_fail);
        // Destroy value_cid_reg (safe because we are finished with it).
        __ lw(value_cid_reg,
                FieldAddress(value_reg, Array::length_offset()));
        __ sw(value_cid_reg, field_length_operand);
        __ b(&local_exit);  // Updated field length from regular array.

        __ Bind(&local_fail);
        // TODO(regis): TMP1 may conflict. Revisit.
        __ LoadImmediate(TMP1, Field::kNoFixedLength);
        __ sw(TMP1, field_length_operand);

        __ Bind(&local_exit);
      }
    } else {
      if (value_cid_reg == kNoRegister) {
        ASSERT(!compiler->is_optimizing());
        value_cid_reg = A1;
        ASSERT((value_cid_reg != value_reg) && (field_reg != value_cid_reg));
      }
      ASSERT(value_cid_reg != kNoRegister);
      ASSERT(field_reg != kNoRegister);
      __ LoadImmediate(TMP1, value_cid);
      __ sw(TMP1, field_cid_operand);
      __ sw(TMP1, field_nullability_operand);
      if ((value_cid == kArrayCid) || (value_cid == kImmutableArrayCid)) {
        // Destroy value_cid_reg (safe because we are finished with it).
        __ lw(value_cid_reg,
              FieldAddress(value_reg, Array::length_offset()));
        __ sw(value_cid_reg, field_length_operand);
      } else if (RawObject::IsTypedDataClassId(value_cid)) {
        // Destroy value_cid_reg (safe because we are finished with it).
        __ lw(value_cid_reg,
              FieldAddress(value_reg, TypedData::length_offset()));
        __ sw(value_cid_reg, field_length_operand);
      } else {
        // Destroy value_cid_reg (safe because we are finished with it).
        __ LoadImmediate(value_cid_reg, Field::kNoFixedLength);
        __ sw(value_cid_reg, field_length_operand);
      }
    }

    if (!ok_is_fall_through) {
      __ b(&ok);
    }
  } else {
    if (field_reg != kNoRegister) {
      __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));
    }
    if (value_cid == kDynamicCid) {
      // Field's guarded class id is fixed by value's class id is not known.
      __ andi(CMPRES, value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ beq(CMPRES, ZR, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ LoadImmediate(TMP1, field_cid);
        __ subu(CMPRES, value_cid_reg, TMP1);
      }

      if (field_has_length) {
        // Jump when Value CID != Field guard CID
        __ bne(CMPRES, ZR, fail);
        // Classes are same, perform guarded list length check.
        ASSERT(field_reg != kNoRegister);
        ASSERT(value_cid_reg != kNoRegister);
        FieldAddress field_length_operand(
            field_reg, Field::guarded_list_length_offset());
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ lw(value_cid_reg,
                FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ lw(value_cid_reg,
                FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ lw(TMP1, field_length_operand);
        __ subu(CMPRES, value_cid_reg, TMP1);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ beq(CMPRES, ZR, &ok);
        __ LoadImmediate(TMP, reinterpret_cast<int32_t>(Object::null()));
        __ subu(CMPRES, value_reg, TMP);
      }

      if (ok_is_fall_through) {
        __ bne(CMPRES, ZR, fail);
      } else {
        __ beq(CMPRES, ZR, &ok);
      }
    } else {
      // Both value's and field's class id is known.
      if ((value_cid != field_cid) && (value_cid != nullability)) {
        if (ok_is_fall_through) {
          __ b(fail);
        }
      } else if (field_has_length && (value_cid == field_cid)) {
        ASSERT(value_cid_reg != kNoRegister);
        if ((field_cid == kArrayCid) || (field_cid == kImmutableArrayCid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ lw(value_cid_reg,
                FieldAddress(value_reg, Array::length_offset()));
        } else if (RawObject::IsTypedDataClassId(field_cid)) {
          // Destroy value_cid_reg (safe because we are finished with it).
          __ lw(value_cid_reg,
                FieldAddress(value_reg, TypedData::length_offset()));
        }
        __ LoadImmediate(TMP1, field_length);
        __ subu(CMPRES, value_cid_reg, TMP1);
        if (ok_is_fall_through) {
          __ bne(CMPRES, ZR, fail);
        }
      } else {
        // Nothing to emit.
        ASSERT(!compiler->is_optimizing());
        return;
      }
    }
  }

  if (deopt == NULL) {
    ASSERT(!compiler->is_optimizing());
    __ Bind(fail);

    __ lw(CMPRES1, FieldAddress(field_reg, Field::guarded_cid_offset()));
    __ BranchEqual(CMPRES1, kDynamicCid, &ok);

    __ addiu(SP, SP, Immediate(-2 * kWordSize));
    __ sw(field_reg, Address(SP, 1 * kWordSize));
    __ sw(value_reg, Address(SP, 0 * kWordSize));
    __ CallRuntime(kUpdateFieldCidRuntimeEntry);
    __ Drop(2);  // Drop the field and the value.
  }

  __ Bind(&ok);
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, ShouldEmitStoreBarrier()
                       ? Location::WritableRegister()
                       : Location::RegisterOrConstant(value()));
  return summary;
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObject(instance_reg,
                       FieldAddress(instance_reg, field().Offset()),
                       value_reg,
                       CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrier(
          instance_reg,
          FieldAddress(instance_reg, field().Offset()),
          locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrier(instance_reg,
          FieldAddress(instance_reg, field().Offset()), value_reg);
    }
  }
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary() const {
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
  __ TraceSimMsg("LoadStaticFieldInstr");
  Register field = locs()->in(0).reg();
  Register result = locs()->out().reg();
  __ lw(result, FieldAddress(field, Field::value_offset()));
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StoreStaticFieldInstr");
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


LocationSummary* InstanceOfInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_in(1, Location::RegisterLocation(A2));
  summary->set_in(2, Location::RegisterLocation(A1));
  summary->set_out(Location::RegisterLocation(V0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == A0);  // Value.
  ASSERT(locs()->in(1).reg() == A2);  // Instantiator.
  ASSERT(locs()->in(2).reg() == A1);  // Instantiator type arguments.

  __ Comment("InstanceOfInstr");
  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out().reg() == V0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_out(Location::RegisterLocation(V0));
  return locs;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("CreateArrayInstr");
  // Allocate the array.  A1 = length, A0 = element type.
  ASSERT(locs()->in(0).reg() == A0);
  __ LoadImmediate(A1, Smi::RawValue(num_elements()));
  compiler->GenerateCall(token_pos(),
                         &StubCode::AllocateArrayLabel(),
                         PcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out().reg() == V0);
}


LocationSummary*
AllocateObjectWithBoundsCheckInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectWithBoundsCheckInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kAllocateObjectWithBoundsCheckRuntimeEntry,
                                locs());
  __ Drop(3);
  ASSERT(locs()->out().reg() == V0);
  __ Pop(V0);  // Pop new instance.
}


LocationSummary* LoadFieldInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  __ lw(result_reg, Address(instance_reg, offset_in_bytes() - kHeapObjectTag));
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("InstantiateTypeInstr");
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  // 'instantiator_reg' is the instantiator AbstractTypeArguments object
  // (or null).
  // A runtime call to instantiate the type is required.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ LoadObject(TMP1, Object::ZoneHandle());
  __ sw(TMP1, Address(SP, 2 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP1, type());
  __ sw(TMP1, Address(SP, 1 * kWordSize));
  // Push instantiator type arguments.
  __ sw(instantiator_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kInstantiateTypeRuntimeEntry,
                                locs());
  // Pop instantiated type.
  __ lw(result_reg, Address(SP, 2 * kWordSize));
  // Drop instantiator and uninstantiated type.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  __ TraceSimMsg("InstantiateTypeArgumentsInstr");
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  // 'instantiator_reg' is the instantiator AbstractTypeArguments object
  // (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    __ BranchEqual(instantiator_reg, reinterpret_cast<int32_t>(Object::null()),
                   &type_arguments_instantiated);
  }
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ LoadObject(TMP1, Object::ZoneHandle());
  __ sw(TMP1, Address(SP, 2 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP1, type_arguments());
  __ sw(TMP1, Address(SP, 1 * kWordSize));
  // Push instantiator type arguments.
  __ sw(instantiator_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                locs());
  // Pop instantiated type arguments.
  __ lw(result_reg, Address(SP, 2 * kWordSize));
  // Drop instantiator and uninstantiated type arguments.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ Bind(&type_arguments_instantiated);
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary*
ExtractConstructorTypeArgumentsInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void ExtractConstructorTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
  ASSERT(instantiator_reg == result_reg);

  // instantiator_reg is the instantiator type argument vector, i.e. an
  // AbstractTypeArguments object (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  ASSERT(type_arguments().IsRawInstantiatedRaw(type_arguments().Length()));
  __ BranchEqual(instantiator_reg, reinterpret_cast<int32_t>(Object::null()),
                 &type_arguments_instantiated);
  // Instantiate non-null type arguments.
  // In the non-factory case, we rely on the allocation stub to
  // instantiate the type arguments.
  __ LoadObject(result_reg, type_arguments());
  // result_reg: uninstantiated type arguments.
  __ Bind(&type_arguments_instantiated);

  // result_reg: uninstantiated or instantiated type arguments.
}


LocationSummary*
ExtractConstructorInstantiatorInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void ExtractConstructorInstantiatorInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  ASSERT(locs()->out().reg() == instantiator_reg);

  // instantiator_reg is the instantiator AbstractTypeArguments object
  // (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));

  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of dynamic, then use null as
  // the type arguments and do not pass the instantiator.
  ASSERT(type_arguments().IsRawInstantiatedRaw(type_arguments().Length()));
  Label instantiator_not_null;
  __ BranchNotEqual(instantiator_reg, reinterpret_cast<int32_t>(Object::null()),
                    &instantiator_not_null);
  // Null was used in VisitExtractConstructorTypeArguments as the
  // instantiated type arguments, no proper instantiator needed.
  __ LoadImmediate(instantiator_reg,
                   Smi::RawValue(StubCode::kNoInstantiator));
  __ Bind(&instantiator_not_null);
  // instantiator_reg: instantiator or kNoInstantiator.
}


LocationSummary* AllocateContextInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_out(Location::RegisterLocation(V0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register temp = T1;
  ASSERT(locs()->temp(0).reg() == temp);
  ASSERT(locs()->out().reg() == V0);

  __ TraceSimMsg("AllocateContextInstr");
  __ LoadImmediate(temp, num_context_variables());
  const ExternalLabel label("alloc_context",
                            StubCode::AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
}


LocationSummary* CloneContextInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(Location::RegisterLocation(T0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ TraceSimMsg("CloneContextInstr");

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP1, Object::ZoneHandle());  // Make room for the result.
  __ sw(TMP1, Address(SP, 1 * kWordSize));
  __ sw(context_value, Address(SP, 0 * kWordSize));

  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                locs());
  __ lw(result, Address(SP, 1 * kWordSize));  // Get result (cloned context).
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(),
                                try_index(),
                                compiler->assembler()->CodeSize(),
                                catch_handler_types_);
  // Restore pool pointer.
  __ GetNextPC(CMPRES, TMP);
  const intptr_t object_pool_pc_dist =
     Instructions::HeaderSize() - Instructions::object_pool_offset() +
     compiler->assembler()->CodeSize() - 1 * Instr::kInstrSize;
  __ LoadFromOffset(PP, CMPRES, -object_pool_pc_dist);

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
  __ sw(kExceptionObjectReg,
        Address(FP, exception_var().index() * kWordSize));
  __ sw(kStackTraceObjectReg,
        Address(FP, stacktrace_var().index() * kWordSize));
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary() const {
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
    __ TraceSimMsg("CheckStackOverflowSlowPath");
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
  __ TraceSimMsg("CheckStackOverflowInstr");
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(TMP1, Isolate::Current()->stack_limit_address());

  __ lw(CMPRES1, Address(TMP1));
  __ BranchUnsignedLessEqual(SP, CMPRES1, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ lw(temp, FieldAddress(temp, Function::usage_counter_offset()));
    __ BranchSignedGreaterEqual(temp, threshold, slow_path->entry_label());
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

  __ TraceSimMsg("EmitSmiShiftLeft");

  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    if (value == 0) {
      if (result != left) {
        __ mov(result, left);
      }
    } else if ((value < 0) || (value >= kCountLimit)) {
      // This condition may not be known earlier in some cases because
      // of constant propagation, inlining, etc.
      if ((value >= kCountLimit) && is_truncating) {
        __ mov(result, ZR);
      } else {
        // Result is Mint or exception.
        __ b(deopt);
      }
    } else {
      if (!is_truncating) {
        // Check for overflow (preserve left).
        __ sll(TMP1, left, value);
        __ sra(CMPRES1, TMP1, value);
        __ bne(CMPRES1, left, deopt);  // Overflow.
      }
      // Shift for result now we know there is no overflow.
      __ sll(result, left, value);
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
        __ bltz(right, deopt);
        __ mov(result, ZR);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          (right_range == NULL) ||
          !right_range->IsWithin(0, max_right - 1);
      if (right_needs_check) {
        __ BranchUnsignedGreaterEqual(
            right, reinterpret_cast<int32_t>(Smi::New(max_right)), deopt);
      }
      __ sra(TMP, right, kSmiTagMask);  // SmiUntag right into TMP.
      __ sllv(result, left, TMP);
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
        __ bltz(right, deopt);
      }
      Label done, is_not_zero;

      __ sltiu(CMPRES,
          right, Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ movz(result, ZR, CMPRES);  // result = right >= kBits ? 0 : result.
      __ sra(TMP1, right, kSmiTagSize);
      __ sllv(TMP1, left, TMP1);
      // result = right < kBits ? left << right : result.
      __ movn(result, TMP1, CMPRES);
    } else {
      __ sra(TMP, right, kSmiTagSize);
      __ sllv(result, left, TMP);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ BranchUnsignedGreaterEqual(
          right, reinterpret_cast<int32_t>(Smi::New(Smi::kBits)), deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ sra(temp, right, kSmiTagSize);  // SmiUntag right into temp.
    // Overflow test (preserve left, right, and temp);
    __ sllv(CMPRES1, left, temp);
    __ srav(CMPRES1, CMPRES1, temp);
    __ bne(CMPRES1, left, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ sllv(result, left, temp);
  }
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = op_kind() == Token::kADD ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant->value()));
    } else {
      summary->set_in(1, Location::RequiresRegister());
    }
    summary->AddTemp(Location::RequiresRegister());
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
  if (((op_kind() == Token::kSHL) && !is_truncating()) ||
      (op_kind() == Token::kSHR)) {
    summary->AddTemp(Location::RequiresRegister());
  } else if (op_kind() == Token::kADD) {
    // Need an extra temp for the overflow detection code.
    summary->set_temp(0, Location::RequiresRegister());
  }
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(Location::RequiresRegister());
  return summary;
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("BinarySmiOpInstr");
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
        __ TraceSimMsg("kSUB imm");
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
          Register temp = locs()->temp(0).reg();
          __ AddImmediateDetectOverflow(result, left, imm, CMPRES, temp);
          __ bltz(CMPRES, deopt);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        if (deopt == NULL) {
          if (value == 2) {
            __ sll(result, left, 1);
          } else {
            __ LoadImmediate(TMP1, value);
            __ mult(left, TMP1);
            __ mflo(result);
          }
        } else {
          if (value == 2) {
            __ sra(CMPRES2, left, 31);  // CMPRES2 = sign of left.
            __ sll(result, left, 1);
          } else {
            __ LoadImmediate(TMP1, value);
            __ mult(left, TMP1);
            __ mflo(result);
            __ mfhi(CMPRES2);
          }
          __ sra(CMPRES, result, 31);
          __ bne(CMPRES1, CMPRES2, deopt);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 1) {
          if (result != left) {
            __ mov(result, left);
          }
          break;
        } else if (value == -1) {
          // Check the corner case of dividing the 'MIN_SMI' with -1, in which
          // case we cannot negate the result.
          __ BranchEqual(left, 0x80000000, deopt);
          __ subu(result, ZR, left);
          break;
        }
        ASSERT((value != 0) && Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ sra(TMP, left, 31);
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        Register temp = locs()->temp(0).reg();
        __ srl(TMP, TMP, 32 - shift_count);
        __ addu(temp, left, TMP);
        ASSERT(shift_count > 0);
        __ sra(result, temp, shift_count);
        if (value < 0) {
          __ subu(result, ZR, result);
        }
        __ SmiTag(result);
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
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        intptr_t value = Smi::Cast(constant).Value();

        __ TraceSimMsg("kSHR");

        if (value == 0) {
          // TODO(vegorov): should be handled outside.
          if (result != left) {
            __ mov(result, left);
          }
          break;
        } else if (value < 0) {
          // TODO(vegorov): should be handled outside.
          __ b(deopt);
          break;
        }

        value = value + kSmiTagSize;
        if (value >= kCountLimit) value = kCountLimit;

        __ sra(result, left, value);
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
  switch (op_kind()) {
    case Token::kADD: {
      if (deopt == NULL) {
        __ addu(result, left, right);
      } else {
        Register temp = locs()->temp(0).reg();
        __ AdduDetectOverflow(result, left, right, CMPRES, temp);
        __ bltz(CMPRES, deopt);
      }
      break;
    }
    case Token::kSUB: {
      __ TraceSimMsg("kSUB");
      if (deopt == NULL) {
        __ subu(result, left, right);
      } else {
        __ SubuDetectOverflow(result, left, right, CMPRES);
        __ bltz(CMPRES, deopt);
      }
      break;
    }
    case Token::kMUL: {
      __ TraceSimMsg("kMUL");
      __ sra(TMP, left, kSmiTagSize);
      __ mult(TMP, right);
      __ mflo(result);
      if (deopt != NULL) {
        __ mfhi(CMPRES2);
        __ sra(CMPRES1, result, 31);
        __ bne(CMPRES1, CMPRES2, deopt);
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
      // Handle divide by zero in runtime.
      __ beq(right, ZR, deopt);
      Register temp = locs()->temp(0).reg();
      __ sra(temp, left, kSmiTagSize);  // SmiUntag left into temp.
      __ sra(TMP, right, kSmiTagSize);  // SmiUntag right into TMP.
      __ div(temp, TMP);
      __ mflo(result);
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ BranchEqual(result, 0x40000000, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      Register temp = locs()->temp(0).reg();
      if (CanDeoptimize()) {
        __ bltz(right, deopt);
      }
      __ sra(temp, right, kSmiTagSize);  // SmiUntag right into temp.
      // sra operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      Range* right_range = this->right()->definition()->range();
      if ((right_range == NULL) ||
          !right_range->IsWithin(RangeBoundary::kMinusInfinity, kCountLimit)) {
        Label ok;
        __ BranchSignedLessEqual(temp, kCountLimit, &ok);
        __ LoadImmediate(temp, kCountLimit);
        __ Bind(&ok);
      }

      __ sra(CMPRES1, left, kSmiTagSize);  // SmiUntag left into CMPRES1.
      __ srav(result, CMPRES1, temp);
      __ SmiTag(result);
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
    __ andi(CMPRES, right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ andi(CMPRES, left, Immediate(kSmiTagMask));
  } else {
    __ or_(TMP, left, right);
    __ andi(CMPRES, TMP, Immediate(kSmiTagMask));
  }
  __ beq(CMPRES, ZR, deopt);
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary() const {
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


class BoxDoubleSlowPath : public SlowPathCode {
 public:
  explicit BoxDoubleSlowPath(BoxDoubleInstr* instruction)
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
    compiler->GenerateCall(Scanner::kDummyTokenIndex,  // No token position.
                           &label,
                           PcDescriptors::kOther,
                           locs);
    if (locs->out().reg() != V0) {
      __ mov(locs->out().reg(), V0);
    }
    compiler->RestoreLiveRegisters(locs);

    __ b(exit_label());
  }

 private:
  BoxDoubleInstr* instruction_;
};


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  DRegister value = locs()->in(0).fpu_reg();

  __ TryAllocate(compiler->double_class(),
                 slow_path->entry_label(),
                 out_reg);
  __ Bind(slow_path->exit_label());
  __ StoreDToOffset(value, out_reg, Double::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t value_cid = value()->Type()->ToCid();
  const bool needs_writable_input = (value_cid == kSmiCid);
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, needs_writable_input
                     ? Location::WritableRegister()
                     : Location::RequiresRegister());
  summary->set_out(Location::RequiresFpuRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const DRegister result = locs()->out().fpu_reg();

  if (value_cid == kDoubleCid) {
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ mtc1(value, STMP1);
    __ cvtdw(result, STMP1);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptBinaryDoubleOp);
    Label is_smi, done;

    __ andi(CMPRES, value, Immediate(kSmiTagMask));
    __ beq(CMPRES, ZR, &is_smi);
    __ LoadClassId(CMPRES1, value);
    __ BranchNotEqual(CMPRES1, kDoubleCid, deopt);
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
    __ b(&done);
    __ Bind(&is_smi);
    // TODO(regis): Why do we preserve value here but not above?
    __ sra(TMP, value, 1);
    __ mtc1(TMP, STMP1);
    __ cvtdw(result, STMP1);
    __ Bind(&done);
  }
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


LocationSummary* BoxUint32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxUint32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxUint32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxUint32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary() const {
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
  DRegister left = locs()->in(0).fpu_reg();
  DRegister right = locs()->in(1).fpu_reg();
  DRegister result = locs()->out().fpu_reg();
  switch (op_kind()) {
    case Token::kADD: __ addd(result, left, right); break;
    case Token::kSUB: __ subd(result, left, right); break;
    case Token::kMUL: __ muld(result, left, right); break;
    case Token::kDIV: __ divd(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ShuffleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToUint32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToUint32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4TwoArgShuffleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4TwoArgShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Uint32x4BoolConstructorInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Uint32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Uint32x4GetFlagInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Uint32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Uint32x4SelectInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Uint32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Uint32x4SetFlagInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Uint32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Uint32x4ToFloat32x4Instr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void Uint32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryUint32x4OpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryUint32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathUnaryInstr::MakeLocationSummary() const {
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
    __ sqrtd(locs()->out().fpu_reg(), locs()->in(0).fpu_reg());
  } else {
    UNIMPLEMENTED();
  }
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary() const {
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
    DRegister left = locs()->in(0).fpu_reg();
    DRegister right = locs()->in(1).fpu_reg();
    DRegister result = locs()->out().fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ cund(left, right);
    __ bc1t(&returns_nan);
    __ ceqd(left, right);
    __ bc1t(&are_equal);
    if (is_min) {
      __ coltd(left, right);
    } else {
      __ coltd(right, left);
    }
    // TODO(zra): Add conditional moves.
    ASSERT(left == result);
    __ bc1t(&done);
    __ movd(result, right);
    __ b(&done);

    __ Bind(&returns_nan);
    __ LoadImmediate(result, NAN);
    __ b(&done);

    __ Bind(&are_equal);
    Label left_is_negative;
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ mfc1(temp, OddFRegisterOf(left));  // Moves bits 32...63 of left to temp.
    if (is_min) {
      ASSERT(left == result);
      __ bltz(temp, &done);  // Left is negative.
    } else {
      __ bgez(temp, &done);  // Left is positive.
    }
    __ movd(result, right);
    __ Bind(&done);
    return;
  }

  Label done;
  ASSERT(result_cid() == kSmiCid);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();
  ASSERT(result == left);
  if (is_min) {
    __ BranchSignedLessEqual(left, right, &done);
  } else {
    __ BranchSignedGreaterEqual(left, right, &done);
  }
  __ mov(result, right);
  __ Bind(&done);
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary() const {
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
      __ SubuDetectOverflow(result, ZR, value, CMPRES);
      __ bltz(CMPRES, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ nor(result, value, ZR);
      __ addiu(result, result, Immediate(-1));  // Remove inverted smi-tag.
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(zra): Implement vneg.
  const Double& minus_one = Double::ZoneHandle(Double::NewCanonical(-1));
  __ LoadObject(TMP, minus_one);
  FpuRegister result = locs()->out().fpu_reg();
  FpuRegister value = locs()->in(0).fpu_reg();
  FpuRegister temp_fp = locs()->temp(0).fpu_reg();
  __ LoadDFromOffset(temp_fp, TMP, Double::value_offset() - kHeapObjectTag);
  __ muld(result, value, temp_fp);
}



LocationSummary* SmiToDoubleInstr::MakeLocationSummary() const {
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
  __ mtc1(value, STMP1);
  __ cvtdw(result, STMP1);
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(T1));
  result->set_out(Location::RegisterLocation(V0));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  Register value_obj = locs()->in(0).reg();
  ASSERT(result == V0);
  ASSERT(result != value_obj);
  __ LoadDFromOffset(DTMP, value_obj, Double::value_offset() - kHeapObjectTag);
  __ cvtwd(STMP1, DTMP);
  __ mfc1(result, STMP1);

  // Overflow is signaled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES, result, TMP);
  __ bltz(CMPRES, &do_call);
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


LocationSummary* DoubleToSmiInstr::MakeLocationSummary() const {
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
  DRegister value = locs()->in(0).fpu_reg();
  __ cvtwd(STMP1, value);
  __ mfc1(result, STMP1);

  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES, result, TMP);
  __ bltz(CMPRES, deopt);
  __ SmiTag(result);
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary() const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result =
      new LocationSummary(InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(D6));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(D7));
  }
  result->set_out(Location::FpuRegisterLocation(D0));
  return result;
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // For pow-function return NaN if exponent is NaN.
  Label do_call, skip_call;
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    DRegister exp = locs()->in(1).fpu_reg();
    __ cund(exp, exp);
    __ bc1f(&do_call);
    // Exponent is NaN, return NaN.
    __ movd(locs()->out().fpu_reg(), exp);
    __ b(&skip_call);
  }
  __ Bind(&do_call);
  // double values are passed and returned in vfp registers.
  __ CallRuntime(TargetFunction());
  __ Bind(&skip_call);
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptPolymorphicInstanceCallTestFail);
  __ TraceSimMsg("PolymorphicInstanceCallInstr");
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

  // Load receiver into T0.
  __ lw(T0, Address(SP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  LoadValueCid(compiler, T2, T0,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            T2,  // Class id register.
                            instance_call()->ArgumentCount(),
                            instance_call()->argument_names(),
                            deopt,
                            deopt_id(),
                            instance_call()->token_pos(),
                            locs());
}


LocationSummary* BranchInstr::MakeLocationSummary() const {
  UNREACHABLE();
  return NULL;
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("BranchInstr");
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary() const {
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
  if (IsNullCheck()) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                          kDeoptCheckClass);
    __ BranchEqual(locs()->in(0).reg(),
        reinterpret_cast<int32_t>(Object::null()), deopt);
    return;
  }

  ASSERT((unary_checks().GetReceiverClassIdAt(0) != kSmiCid) ||
         (unary_checks().NumberOfChecks() > 1));
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckClass);
  Label is_ok;
  intptr_t cix = 0;
  if (unary_checks().GetReceiverClassIdAt(cix) == kSmiCid) {
    __ andi(CMPRES, value, Immediate(kSmiTagMask));
    __ beq(CMPRES, ZR, &is_ok);
    cix++;  // Skip first check.
  } else {
    __ andi(CMPRES, value, Immediate(kSmiTagMask));
    __ beq(CMPRES, ZR, deopt);
  }
  __ LoadClassId(temp, value);
  const intptr_t num_checks = unary_checks().NumberOfChecks();
  for (intptr_t i = cix; i < num_checks; i++) {
    ASSERT(unary_checks().GetReceiverClassIdAt(i) != kSmiCid);
    __ LoadImmediate(TMP1, unary_checks().GetReceiverClassIdAt(i));
    __ subu(CMPRES, temp, TMP1);
    if (i == (num_checks - 1)) {
      __ bne(CMPRES, ZR, deopt);
    } else {
      __ beq(CMPRES, ZR, &is_ok);
    }
  }
  __ Bind(&is_ok);
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
  __ TraceSimMsg("CheckSmiInstr");
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckSmi);
  __ andi(CMPRES1, value, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, deopt);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary() const {
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
    __ BranchUnsignedLessEqual(
        length, reinterpret_cast<int32_t>(index.raw()), deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    __ BranchUnsignedGreaterEqual(
        index, reinterpret_cast<int32_t>(length.raw()), deopt);
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    __ BranchUnsignedGreaterEqual(index, length, deopt);
  }
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
  return new LocationSummary(0, 0, LocationSummary::kCall);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kThrowRuntimeEntry,
                                locs());
  __ break_(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateCallRuntime(token_pos(),
                                deopt_id(),
                                kReThrowRuntimeEntry,
                                locs());
  __ break_(0);
}


LocationSummary* GotoInstr::MakeLocationSummary() const {
  return new LocationSummary(0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("GotoInstr");
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
  __ TraceSimMsg("ControlInstruction::EmitBranchOnValue");
  if (value && !compiler->CanFallThroughTo(true_successor())) {
    __ b(compiler->GetJumpLabel(true_successor()));
  } else if (!value && !compiler->CanFallThroughTo(false_successor())) {
    __ b(compiler->GetJumpLabel(false_successor()));
  }
}


// The comparison result is in CMPRES.
void ControlInstruction::EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                               Condition true_condition) {
  __ TraceSimMsg("ControlInstruction::EmitBranchOnCondition");
  if (compiler->CanFallThroughTo(false_successor())) {
    // If the next block is the false successor we will fall through to it.
    Label* label = compiler->GetJumpLabel(true_successor());
    EmitBranchAfterCompare(compiler, true_condition, label);
  } else {
    // If the next block is the true successor we negate comparison and fall
    // through to it.
    Condition false_condition = NegateCondition(true_condition);
    Label* label = compiler->GetJumpLabel(false_successor());
    EmitBranchAfterCompare(compiler, false_condition, label);
    // Fall through or jump to the true successor.
    if (!compiler->CanFallThroughTo(true_successor())) {
      __ b(compiler->GetJumpLabel(true_successor()));
    }
  }
}


LocationSummary* CurrentContextInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ mov(locs()->out().reg(), CTX);
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
  __ TraceSimMsg("StrictCompareInstr");
  __ Comment("StrictCompareInstr");
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

  Register result = locs()->out().reg();
  Label load_true, done;
  if (kind() == Token::kEQ_STRICT) {
    __ beq(CMPRES1, CMPRES2, &load_true);
  } else {
    ASSERT(kind() == Token::kNE_STRICT);
    __ bne(CMPRES1, CMPRES2, &load_true);
  }
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&load_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  __ TraceSimMsg("StrictCompareInstr::EmitBranchCode");
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
  branch->EmitBranchOnCondition(compiler, true_condition);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ LoadObject(result, Bool::True());
  __ LoadObject(TMP1, Bool::False());
  __ subu(CMPRES, value, result);
  __ movz(result, TMP1, CMPRES);  // If value is True, move False into result.
}


LocationSummary* StoreVMFieldInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_in(1, Location::RequiresRegister());
  return locs;
}


void StoreVMFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value_reg = locs()->in(0).reg();
  Register dest_reg = locs()->in(1).reg();

  if (value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(dest_reg,
        FieldAddress(dest_reg, offset_in_bytes()), value_reg);
  } else {
    __ StoreIntoObjectNoBarrier(dest_reg,
        FieldAddress(dest_reg, offset_in_bytes()), value_reg);
  }
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("AllocateObjectInstr");
  __ Comment("AllocateObjectInstr");
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls()));
  const ExternalLabel label(cls().ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}


LocationSummary* CreateClosureInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void CreateClosureInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("CreateClosureInstr");
  const Function& closure_function = function();
  ASSERT(!closure_function.IsImplicitStaticClosureFunction());
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(closure_function));
  const ExternalLabel label(closure_function.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  __ Drop(2);  // Discard type arguments and receiver.
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
