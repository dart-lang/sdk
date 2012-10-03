// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/intermediate_language.h"

#include "lib/error.h"
#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, trace_functions);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register RAX.
LocationSummary* Instruction::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(RAX));
  return result;
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(result == RAX);
  if (!compiler->is_optimizing()) {
    __ Comment("Check function counter");
    // Count only in unoptimized code.
    // TODO(srdjan): Replace the counting code with a type feedback
    // collection and counting stub.
    const Function& function =
          Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ incq(FieldAddress(temp, Function::usage_counter_offset()));
    if (FlowGraphCompiler::CanOptimize() &&
        compiler->parsed_function().function().is_optimizable()) {
      // Do not optimize if usage count must be reported.
      __ cmpq(FieldAddress(temp, Function::usage_counter_offset()),
          Immediate(FLAG_optimization_counter_threshold));
      Label not_yet_hot, already_optimized;
      __ j(LESS, &not_yet_hot, Assembler::kNearJump);
      __ j(GREATER, &already_optimized, Assembler::kNearJump);
      __ pushq(result);  // Preserve result.
      __ pushq(temp);  // Argument for runtime: function to optimize.
      __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
      __ popq(temp);  // Remove argument.
      __ popq(result);  // Restore result.
      __ Bind(&not_yet_hot);
      __ Bind(&already_optimized);
    }
  }
  if (FLAG_trace_functions) {
    const Function& function =
        Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ pushq(result);  // Preserve result.
    __ pushq(temp);
    compiler->GenerateCallRuntime(0,
                                  kTraceFunctionExitRuntimeEntry,
                                  NULL);
    __ popq(temp);  // Remove argument.
    __ popq(result);  // Restore result.
  }
#if defined(DEBUG)
  // TODO(srdjan): Fix for functions with finally clause.
  // A finally clause may leave a previously pushed return value if it
  // has its own return instruction. Method that have finally are currently
  // not optimized.
  if (!compiler->HasFinally()) {
    Label done;
    __ movq(RDI, RBP);
    __ subq(RDI, RSP);
    // + 1 for Pc marker.
    __ cmpq(RDI, Immediate((compiler->StackSize() + 1) * kWordSize));
    __ j(EQUAL, &done, Assembler::kNearJump);
    __ int3();
    __ Bind(&done);
  }
#endif
  __ LeaveFrame();
  __ ret();

  // Generate 8 bytes of NOPs so that the debugger can patch the
  // return pattern with a call to the debug stub.
  // Note that the nop(8) byte pattern is not recognized by the debugger.
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 Isolate::kNoDeoptId,
                                 token_pos());
}


LocationSummary* ClosureCallInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(RAX));
  result->set_temp(0, Location::RegisterLocation(R10));  // Arg. descriptor.
  return result;
}


LocationSummary* LoadLocalInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ movq(result, Address(RBP, local().index() * kWordSize));
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
  __ movq(Address(RBP, local().index() * kWordSize), value);
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
  summary->set_in(0, Location::RegisterLocation(RAX));  // Value.
  summary->set_in(1, Location::RegisterLocation(RCX));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(RDX));  // Type arguments.
  summary->set_out(Location::RegisterLocation(RAX));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out().reg();

  if (!is_eliminated()) {
    // Check that the type of the value is allowed in conditional context.
    // Call the runtime if the object is not bool::true or bool::false.
    Label done;
    __ CompareObject(obj, compiler->bool_true());
    __ j(EQUAL, &done, Assembler::kNearJump);
    __ CompareObject(obj, compiler->bool_false());
    __ j(EQUAL, &done, Assembler::kNearJump);

    __ pushq(obj);  // Push the source object.
    compiler->GenerateCallRuntime(token_pos(),
                                  kConditionTypeErrorRuntimeEntry,
                                  locs());
    // We should never return here.
    __ int3();
    __ Bind(&done);
  }
  ASSERT(obj == result);
}


LocationSummary* ArgumentDefinitionTestInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void ArgumentDefinitionTestInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register saved_args_desc = locs()->in(0).reg();
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  __ pushq(Immediate(Smi::RawValue(formal_parameter_index())));
  __ PushObject(formal_parameter_name());
  __ pushq(saved_args_desc);
  compiler->GenerateCallRuntime(token_pos(),
                                kArgumentDefinitionTestRuntimeEntry,
                                locs());
  __ Drop(3);
  __ popq(result);  // Pop bool result.
}


static Condition TokenKindToSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQUAL;
    case Token::kNE: return NOT_EQUAL;
    case Token::kLT: return LESS;
    case Token::kGT: return GREATER;
    case Token::kLTE: return LESS_EQUAL;
    case Token::kGTE: return  GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const bool is_checked_strict_equal =
      HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  if (receiver_class_id() == kDoubleCid) {
    const intptr_t kNumTemps =  0;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresXmmRegister());
    locs->set_in(1, Location::RequiresXmmRegister());
    locs->set_out(Location::RequiresRegister());
    return locs;
  }
  if (receiver_class_id() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RegisterOrConstant(left()));
    locs->set_in(1, Location::RegisterOrConstant(right()));
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
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(RCX));
    locs->set_in(1, Location::RegisterLocation(RDX));
    locs->set_temp(0, Location::RegisterLocation(RBX));
    locs->set_out(Location::RegisterLocation(RAX));
    return locs;
  }
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RCX));
  locs->set_in(1, Location::RegisterLocation(RDX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


static void EmitEqualityAsInstanceCall(FlowGraphCompiler* compiler,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       Token::Kind kind,
                                       LocationSummary* locs) {
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                                   deopt_id,
                                   token_pos);
  }
  const String& operator_name = String::ZoneHandle(Symbols::New("=="));
  const int kNumberOfArguments = 2;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 2;

  Label done, false_label, true_label;
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  __ popq(right);
  __ popq(left);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label check_identity, instance_call;
  __ cmpq(right, raw_null);
  __ j(EQUAL, &check_identity, Assembler::kNearJump);
  __ cmpq(left, raw_null);
  __ j(NOT_EQUAL, &instance_call, Assembler::kNearJump);

  __ Bind(&check_identity);
  __ cmpq(left, right);
  __ j(EQUAL, &true_label);
  if (kind == Token::kEQ) {
    __ LoadObject(RAX, compiler->bool_false());
    __ jmp(&done);
    __ Bind(&true_label);
    __ LoadObject(RAX, compiler->bool_true());
    __ jmp(&done);
  } else {
    ASSERT(kind == Token::kNE);
    __ jmp(&false_label);
  }

  __ Bind(&instance_call);
  __ pushq(left);
  __ pushq(right);
  compiler->GenerateInstanceCall(deopt_id,
                                 token_pos,
                                 operator_name,
                                 kNumberOfArguments,
                                 kNoArgumentNames,
                                 kNumArgumentsChecked,
                                 locs);
  if (kind == Token::kNE) {
    // Negate the condition: true label returns false and vice versa.
    __ CompareObject(RAX, compiler->bool_true());
    __ j(EQUAL, &true_label, Assembler::kNearJump);
    __ Bind(&false_label);
    __ LoadObject(RAX, compiler->bool_true());
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&true_label);
    __ LoadObject(RAX, compiler->bool_false());
  }
  __ Bind(&done);
}


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
  __ testq(left, Immediate(kSmiTagMask));
  Register temp = locs->temp(0).reg();
  if (ic_data.GetReceiverClassIdAt(0) == kSmiCid) {
    Label done, load_class_id;
    __ j(NOT_ZERO, &load_class_id, Assembler::kNearJump);
    __ movq(temp, Immediate(kSmiCid));
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&load_class_id);
    __ LoadClassId(temp, left);
    __ Bind(&done);
  } else {
    __ j(ZERO, deopt);  // Smi deopts.
    __ LoadClassId(temp, left);
  }
  // 'temp' contains class-id of the left argument.
  ObjectStore* object_store = Isolate::Current()->object_store();
  Condition cond = TokenKindToSmiCondition(kind);
  Label done;
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    // Assert that the Smi is at position 0, if at all.
    ASSERT((ic_data.GetReceiverClassIdAt(i) != kSmiCid) || (i == 0));
    Label next_test;
    __ cmpq(temp, Immediate(ic_data.GetReceiverClassIdAt(i)));
    __ j(NOT_EQUAL, &next_test);
    const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(i));
    if (target.Owner() == object_store->object_class()) {
      // Object.== is same as ===.
      __ Drop(2);
      __ cmpq(left, right);
      if (branch != NULL) {
        branch->EmitBranchOnCondition(compiler, cond);
      } else {
        // This case should be rare.
        Register result = locs->out().reg();
        Label load_true;
        __ j(cond, &load_true, Assembler::kNearJump);
        __ LoadObject(result, compiler->bool_false());
        __ jmp(&done);
        __ Bind(&load_true);
        __ LoadObject(result, compiler->bool_true());
      }
    } else {
      const int kNumberOfArguments = 2;
      const Array& kNoArgumentNames = Array::Handle();
      compiler->GenerateStaticCall(deopt_id,
                                   token_pos,
                                   target,
                                   kNumberOfArguments,
                                   kNoArgumentNames,
                                   locs);
      if (branch == NULL) {
        if (kind == Token::kNE) {
          Label false_label;
          __ CompareObject(RAX, compiler->bool_true());
          __ j(EQUAL, &false_label, Assembler::kNearJump);
          __ LoadObject(RAX, compiler->bool_true());
          __ jmp(&done);
          __ Bind(&false_label);
          __ LoadObject(RAX, compiler->bool_false());
          __ jmp(&done);
        }
      } else {
        __ CompareObject(RAX, compiler->bool_true());
        branch->EmitBranchOnCondition(compiler, cond);
      }
    }
    __ jmp(&done);
    __ Bind(&next_test);
  }
  // Fall through leads to deoptimization
  __ jmp(deopt);
  __ Bind(&done);
}


// Emit code when ICData's targets are all Object == (which is ===).
static void EmitCheckedStrictEqual(FlowGraphCompiler* compiler,
                                   const ICData& ic_data,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch,
                                   intptr_t deopt_id) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  Register left = locs.in(0).reg();
  Register right = locs.in(1).reg();
  Register temp = locs.temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptEquality);
  __ testq(left, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
  // 'left' is not Smi.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label identity_compare;
  __ cmpq(right, raw_null);
  __ j(EQUAL, &identity_compare);
  __ cmpq(left, raw_null);
  __ j(EQUAL, &identity_compare);

  __ LoadClassId(temp, left);
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    __ cmpq(temp, Immediate(ic_data.GetReceiverClassIdAt(i)));
    if (i == (ic_data.NumberOfChecks() - 1)) {
      __ j(NOT_EQUAL, deopt);
    } else {
      __ j(EQUAL, &identity_compare);
    }
  }
  __ Bind(&identity_compare);
  __ cmpq(left, right);
  if (branch == NULL) {
    Label done, is_equal;
    Register result = locs.out().reg();
    __ j(EQUAL, &is_equal, Assembler::kNearJump);
    // Not equal.
    __ LoadObject(result, (kind == Token::kEQ) ? compiler->bool_false()
                                               : compiler->bool_true());
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&is_equal);
    __ LoadObject(result, (kind == Token::kEQ) ? compiler->bool_true()
                                               : compiler->bool_false());
    __ Bind(&done);
  } else {
    Condition cond = TokenKindToSmiCondition(kind);
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
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done, identity_compare, non_null_compare;
  __ cmpq(right, raw_null);
  __ j(EQUAL, &identity_compare, Assembler::kNearJump);
  __ cmpq(left, raw_null);
  __ j(NOT_EQUAL, &non_null_compare, Assembler::kNearJump);
  // Comparison with NULL is "===".
  __ Bind(&identity_compare);
  __ cmpq(left, right);
  Condition cond = TokenKindToSmiCondition(kind);
  if (branch != NULL) {
    branch->EmitBranchOnCondition(compiler, cond);
  } else {
    Register result = locs->out().reg();
    Label load_true;
    __ j(cond, &load_true, Assembler::kNearJump);
    __ LoadObject(result, compiler->bool_false());
    __ jmp(&done);
    __ Bind(&load_true);
    __ LoadObject(result, compiler->bool_true());
  }
  __ jmp(&done);
  __ Bind(&non_null_compare);  // Receiver is not null.
  __ pushq(left);
  __ pushq(right);
  EmitEqualityAsPolymorphicCall(compiler, ic_data, locs, branch, kind,
                                deopt_id, token_pos);
  __ Bind(&done);
}


static void EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                const LocationSummary& locs,
                                Token::Kind kind,
                                BranchInstr* branch) {
  Location left = locs.in(0);
  Location right = locs.in(1);

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant() && right.IsConstant()) {
    // TODO(vegorov): should be eliminated earlier by constant propagation.
    const bool result = FlowGraphCompiler::EvaluateCondition(
        true_condition,
        Smi::Cast(left.constant()).Value(),
        Smi::Cast(right.constant()).Value());

    if (branch != NULL) {
      branch->EmitBranchOnValue(compiler, result);
    } else {
      __ LoadObject(locs.out().reg(), result ? compiler->bool_true()
                                             : compiler->bool_false());
    }

    return;
  }

  if (left.IsConstant()) {
    __ CompareObject(right.reg(), left.constant());
    true_condition = FlowGraphCompiler::FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant());
  } else {
    __ cmpq(left.reg(), right.reg());
  }

  if (branch != NULL) {
    branch->EmitBranchOnCondition(compiler, true_condition);
  } else {
    Register result = locs.out().reg();
    Label done, is_true;
    __ j(true_condition, &is_true);
    __ LoadObject(result, compiler->bool_false());
    __ jmp(&done);
    __ Bind(&is_true);
    __ LoadObject(result, compiler->bool_true());
    __ Bind(&done);
  }
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


static void EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                   const LocationSummary& locs,
                                   Token::Kind kind,
                                   BranchInstr* branch) {
  XmmRegister left = locs.in(0).xmm_reg();
  XmmRegister right = locs.in(1).xmm_reg();

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
  ASSERT((kind() == Token::kEQ) || (kind() == Token::kNE));
  BranchInstr* kNoBranch = NULL;
  if (receiver_class_id() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), kNoBranch);
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    // Deoptimizes if both arguments are Smi, or if none is Double or Smi.
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
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    EmitGenericEqualityCompare(compiler, locs(), kind(), kNoBranch, *ic_data(),
                               deopt_id(), token_pos());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushq(left);
  __ pushq(right);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             kind(),
                             locs());
  ASSERT(locs()->out().reg() == RAX);
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  if (receiver_class_id() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    // Deoptimizes if both arguments are Smi, or if none is Double or Smi.
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
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    EmitGenericEqualityCompare(compiler, locs(), kind(), branch, *ic_data(),
                               deopt_id(), token_pos());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushq(left);
  __ pushq(right);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             Token::kEQ,  // kNE reverse occurs at branch.
                             locs());
  Condition branch_condition = (kind() == Token::kNE) ? NOT_EQUAL : EQUAL;
  __ CompareObject(RAX, compiler->bool_true());
  branch->EmitBranchOnCondition(compiler, branch_condition);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operands_class_id() == kDoubleCid) {
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresXmmRegister());
    summary->set_in(1, Location::RequiresXmmRegister());
    summary->set_out(Location::RequiresRegister());
    return summary;
  } else if (operands_class_id() == kSmiCid) {
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RegisterOrConstant(left()));
    summary->set_in(1, Location::RegisterOrConstant(right()));
    summary->set_out(Location::RequiresRegister());
    return summary;
  }
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  // Pick arbitrary fixed input registers because this is a call.
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_in(1, Location::RegisterLocation(RCX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), NULL);
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
  __ pushq(left);
  __ pushq(right);
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptRelationalOp);

    // Load class into RDI. Since this is a call, any register except
    // the fixed input registers would be ok.
    ASSERT((left != RDI) && (right != RDI));
    Label done;
    __ movq(RDI, Immediate(kSmiCid));
    __ testq(left, Immediate(kSmiTagMask));
    __ j(ZERO, &done);
    __ LoadClassId(RDI, left);
    __ Bind(&done);
    const intptr_t kNumArguments = 2;
    compiler->EmitTestAndCall(ICData::Handle(ic_data()->AsUnaryClassChecks()),
                              RDI,  // Class id register.
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
    compiler->AddCurrentDescriptor(PcDescriptors::kDeoptBefore,
                                   deopt_id(),
                                   token_pos());
  }
  const intptr_t kNumArguments = 2;
  const intptr_t kNumArgsChecked = 2;  // Type-feedback.
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 function_name,
                                 kNumArguments,
                                 Array::ZoneHandle(),  // No optional arguments.
                                 kNumArgsChecked,
                                 locs());
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  if (operands_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch);
    return;
  }
  EmitNativeCode(compiler);
  __ CompareObject(RAX, compiler->bool_true());
  branch->EmitBranchOnCondition(compiler, EQUAL);
}


LocationSummary* NativeCallInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(RAX));
  locs->set_temp(1, Location::RegisterLocation(RBX));
  locs->set_temp(2, Location::RegisterLocation(R10));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == RAX);
  ASSERT(locs()->temp(1).reg() == RBX);
  ASSERT(locs()->temp(2).reg() == R10);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in RAX.
  intptr_t arg_count = argument_count();
  if (is_native_instance_closure()) {
    arg_count += 1;
  }
  if (!has_optional_parameters() && !is_native_instance_closure()) {
    __ leaq(RAX, Address(RBP, (1 + arg_count) * kWordSize));
  } else {
    __ leaq(RAX,
            Address(RBP, ParsedFunction::kFirstLocalSlotIndex * kWordSize));
  }
  __ movq(RBX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movq(R10, Immediate(arg_count));
  compiler->GenerateCall(token_pos(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther,
                         locs());
  __ popq(result);
}


static bool CanBeImmediateIndex(Value* index) {
  if (!index->definition()->IsConstant()) return false;
  const Object& constant = index->definition()->AsConstant()->value();
  const Smi& smi_const = Smi::Cast(constant);
  int64_t disp = smi_const.AsInt64Value() * kWordSize + sizeof(RawArray);
  return Utils::IsInt(32, disp);
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, CanBeImmediateIndex(index())
                    ? Location::RegisterOrConstant(index())
                    : Location::RequiresRegister());
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Location index = locs()->in(1);
  if (index.IsRegister()) {
    // Note that index is Smi, i.e, times 4.
    ASSERT(kSmiTagShift == 1);
    __ movq(result,
            FieldAddress(array, index.reg(), TIMES_4, sizeof(RawArray)));
  } else {
    const int64_t disp =
        Smi::Cast(index.constant()).Value() * kWordSize + sizeof(RawArray);
    ASSERT(Utils::IsInt(32, disp));
    __ movq(result, FieldAddress(array, static_cast<int32_t>(disp)));
  }
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, CanBeImmediateIndex(index())
                    ? Location::RegisterOrConstant(index())
                    : Location::RequiresRegister());
  locs->set_in(2, ShouldEmitStoreBarrier()
                    ? Location::WritableRegister()
                    : Location::RegisterOrConstant(value()));
  return locs;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();

  // Note that index is Smi, i.e, times 4.
  ASSERT(kSmiTagShift == 1);
  Location index = locs()->in(1);
  FieldAddress field_address = index.IsConstant()
      ? FieldAddress(
          array,
          static_cast<int32_t>(
            Smi::Cast(index.constant()).Value() * kWordSize + sizeof(RawArray)))
      : FieldAddress(array, index.reg(), TIMES_4, sizeof(RawArray));

  if (ShouldEmitStoreBarrier()) {
      Register value = locs()->in(2).reg();
    __ StoreIntoObject(array, field_address, value);
  } else {
    if (locs()->in(2).IsConstant()) {
      const Object& constant = locs()->in(2).constant();
      __ StoreObject(field_address, constant);
    } else {
      Register value = locs()->in(2).reg();
      __ StoreIntoObjectNoBarrier(array, field_address, value);
    }
  }
}


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t num_temps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, num_temps, LocationSummary::kNoCall);
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
        FieldAddress(instance_reg, field().Offset()), value_reg);
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreObject(FieldAddress(instance_reg, field().Offset()),
                     locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrier(instance_reg,
          FieldAddress(instance_reg, field().Offset()), value_reg);
    }
  }
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ LoadObject(result, field());
  __ movq(result, FieldAddress(result, Field::value_offset()));
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary() const {
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
    __ StoreIntoObject(temp, FieldAddress(temp, Field::value_offset()), value);
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
  summary->set_in(0, Location::RegisterLocation(RAX));
  summary->set_in(1, Location::RegisterLocation(RCX));
  summary->set_in(2, Location::RegisterLocation(RDX));
  summary->set_out(Location::RegisterLocation(RAX));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == RAX);  // Value.
  ASSERT(locs()->in(1).reg() == RCX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == RDX);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(token_pos(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out().reg() == RAX);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RBX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  R10 = length, RBX = element type.
  ASSERT(locs()->in(0).reg() == RBX);
  __ movq(R10, Immediate(Smi::RawValue(ArgumentCount())));
  compiler->GenerateCall(token_pos(),
                         &StubCode::AllocateArrayLabel(),
                         PcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out().reg() == RAX);

  // Pop the element values from the stack into the array.
  __ leaq(R10, FieldAddress(RAX, Array::data_offset()));
  for (int i = ArgumentCount() - 1; i >= 0; --i) {
    __ popq(Address(R10, i * kWordSize));
  }
}


LocationSummary*
AllocateObjectWithBoundsCheckInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_in(1, Location::RegisterLocation(RCX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void AllocateObjectWithBoundsCheckInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().Owner());
  Register type_arguments = locs()->in(0).reg();
  Register instantiator_type_arguments = locs()->in(1).reg();
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  __ PushObject(cls);
  __ pushq(type_arguments);
  __ pushq(instantiator_type_arguments);
  compiler->GenerateCallRuntime(token_pos(),
                                kAllocateObjectWithBoundsCheckRuntimeEntry,
                                locs());
  // Pop instantiator type arguments, type arguments, and class.
  __ Drop(3);
  __ popq(result);  // Pop new instance.
}


LocationSummary* LoadFieldInstr::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  __ movq(result_reg, FieldAddress(instance_reg, offset_in_bytes()));
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();

  // 'instantiator_reg' is the instantiator AbstractTypeArguments object
  // (or null).
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpq(instantiator_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check the instantiator ('instantiator_reg') for null here,
    // because a null instantiator will have the wrong class (Null instead of
    // TypeArguments).
    Label type_arguments_uninstantiated;
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid);
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    __ cmpq(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
            Immediate(Smi::RawValue(len)));
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(type_arguments());
  __ pushq(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateCallRuntime(token_pos(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ popq(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  ASSERT(instantiator_reg == result_reg);
  // 'result_reg': Instantiated type arguments.
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
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpq(instantiator_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check instantiator_reg for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    Label type_arguments_uninstantiated;
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid);
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length =
        Immediate(Smi::RawValue(type_arguments().Length()));
    __ cmpq(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
        arguments_length);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
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
  // (or null).  If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of Dynamic, then use null as
  // the type arguments and do not pass the instantiator.
  Label done;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    const Immediate raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    Label instantiator_not_null;
    __ cmpq(instantiator_reg, raw_null);
    __ j(NOT_EQUAL, &instantiator_not_null, Assembler::kNearJump);
    // Null was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movq(instantiator_reg,
            Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
    __ jmp(&done);
    __ Bind(&instantiator_not_null);
  }
  // Instantiate non-null type arguments.
  if (type_arguments().IsUninstantiatedIdentity()) {
    // TODO(regis): The following emitted code is duplicated in
    // VisitExtractConstructorTypeArguments above. The reason is that the code
    // is split between two computations, so that each one produces a
    // single value, rather than producing a pair of values.
    // If this becomes an issue, we should expose these tests at the IL level.

    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check the instantiator (RAX) for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    Immediate arguments_length =
        Immediate(Smi::RawValue(type_arguments().Length()));
    __ cmpq(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
        arguments_length);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    // The instantiator was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movq(instantiator_reg,
            Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  }
  __ Bind(&done);
  // instantiator_reg: instantiator or kNoInstantiator.
}


LocationSummary* AllocateContextInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(R10));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == R10);
  ASSERT(locs()->out().reg() == RAX);

  __ movq(R10, Immediate(num_context_variables()));
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
  locs->set_in(0, Location::RegisterLocation(RAX));
  locs->set_out(Location::RegisterLocation(RAX));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushq(context_value);
  compiler->GenerateCallRuntime(token_pos(),
                                kCloneContextRuntimeEntry,
                                locs());
  __ popq(result);  // Remove argument.
  __ popq(result);  // Get result (cloned context).
}


LocationSummary* CatchEntryInstr::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::NoLocation(),
                               LocationSummary::kNoCall);
}


// Restore stack and initialize the two exception variables:
// exception and stack trace variables.
void CatchEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Restore RSP from RBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t locals_space_size = compiler->StackSize() * kWordSize;
  ASSERT(locals_space_size >= 0);
  const intptr_t offset_size =
      -locals_space_size + FlowGraphCompiler::kLocalsOffsetFromFP;
  __ leaq(RSP, Address(RBP, offset_size));

  ASSERT(!exception_var().is_captured());
  ASSERT(!stacktrace_var().is_captured());
  __ movq(Address(RBP, exception_var().index() * kWordSize),
          kExceptionObjectReg);
  __ movq(Address(RBP, stacktrace_var().index() * kWordSize),
          kStackTraceObjectReg);
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
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    compiler->GenerateCallRuntime(instruction_->token_pos(),
                                  kStackOverflowRuntimeEntry,
                                  instruction_->locs());
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ jmp(exit_label());
  }

 private:
  CheckStackOverflowInstr* instruction_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register temp = locs()->temp(0).reg();
  // Generate stack overflow check.
  __ movq(temp, Immediate(Isolate::Current()->stack_limit_address()));
  __ cmpq(RSP, Address(temp, 0));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  __ Bind(slow_path->exit_label());
}


static bool CanBeImmediate(const Object& constant) {
  return constant.IsSmi() &&
    Immediate(reinterpret_cast<int64_t>(constant.raw())).is_int32();
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;

  ConstantInstr* right_constant = right()->definition()->AsConstant();
  if ((right_constant != NULL) &&
      (op_kind() != Token::kTRUNCDIV) &&
      (op_kind() != Token::kSHL) &&
      (op_kind() != Token::kMUL) &&
      CanBeImmediate(right_constant->value())) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::Constant(right_constant->value()));
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  }

  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 3;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RegisterLocation(RAX));
    summary->set_in(1, Location::RegisterLocation(RCX));
    summary->set_out(Location::SameAsFirstInput());
    summary->set_temp(0, Location::RegisterLocation(RBX));
    // Will be used for for sign extension.
    summary->set_temp(1, Location::RegisterLocation(RDX));
    summary->set_temp(2, Location::RequiresRegister());
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RegisterLocation(RCX));
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    // Two Smi operands can easily overflow into Mint.
    const intptr_t kNumTemps = 2;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::RegisterLocation(RAX));
    summary->set_in(1, Location::RegisterLocation(RDX));
    summary->set_out(Location::RegisterLocation(RAX));
    summary->set_temp(0, Location::RegisterLocation(RBX));
    summary->set_temp(1, Location::RegisterLocation(RCX));
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  }
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(left == result);
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                   kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int64_t imm =
        reinterpret_cast<int64_t>(constant.raw());
    switch (op_kind()) {
      case Token::kADD: {
        __ addq(left, Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kSUB: {
        __ subq(left, Immediate(imm));
        if (deopt != NULL) __ j(OVERFLOW, deopt);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ andq(left, Immediate(imm));
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ orq(left, Immediate(imm));
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ xorq(left, Immediate(imm));
        break;
      }

      case Token::kSHR: {
        // sarq operation masks the count to 6 bits.
        const intptr_t kCountLimit = 0x3F;
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

        __ sarq(left, Immediate(value));
        __ SmiTag(left);
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
      Register temp = locs()->temp(0).reg();
      // Handle divide by zero in runtime.
      // Deoptimization requires that temp and right are preserved.
      __ testq(right, right);
      __ j(ZERO, deopt);
      ASSERT(left == RAX);
      ASSERT((right != RDX) && (right != RAX));
      ASSERT((temp != RDX) && (temp != RAX));
      ASSERT(locs()->temp(1).reg() == RDX);
      ASSERT(result == RAX);
      Register right_temp = locs()->temp(2).reg();
      __ movq(right_temp, right);
      __ SmiUntag(left);
      __ SmiUntag(right_temp);
      __ cqo();  // Sign extend RAX -> RDX:RAX.
      __ idivq(right_temp);  //  RAX: quotient, RDX: remainder.
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ cmpq(result, Immediate(0x4000000000000000));
      __ j(EQUAL, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      // sarq operation masks the count to 6 bits.
      const Immediate kCountLimit = Immediate(0x3F);
      __ cmpq(right, Immediate(0));
      __ j(LESS, deopt);
      __ SmiUntag(right);
      __ cmpq(right, kCountLimit);
      Label count_ok;
      __ j(LESS, &count_ok, Assembler::kNearJump);
      __ movq(right, kCountLimit);
      __ Bind(&count_ok);
      ASSERT(right == RCX);  // Count must be in RCX
      __ SmiUntag(left);
      __ sarq(left, right);
      __ SmiTag(left);
      break;
    }
    case Token::kSHL: {
      Register temp = locs()->temp(0).reg();
      Label call_method, done;
      // Check if count too large for handling it inlined.
      __ movq(temp, left);
      __ cmpq(right,
          Immediate(reinterpret_cast<int64_t>(Smi::New(Smi::kBits))));
      __ j(ABOVE_EQUAL, &call_method, Assembler::kNearJump);
      Register right_temp = locs()->temp(1).reg();
      ASSERT(right_temp == RCX);  // Count must be in RCX
      __ movq(right_temp, right);
      __ SmiUntag(right_temp);
      // Overflow test (preserve temp and right);
      __ shlq(left, right_temp);
      __ sarq(left, right_temp);
      __ cmpq(left, temp);
      __ j(NOT_EQUAL, &call_method, Assembler::kNearJump);  // Overflow.
      // Shift for result now we know there is no overflow.
      __ shlq(left, right_temp);
      __ jmp(&done);
      {
        __ Bind(&call_method);
        Function& target = Function::ZoneHandle(
            ic_data()->GetTargetForReceiverClassId(kSmiCid));
        ASSERT(!target.IsNull());
        const intptr_t kArgumentCount = 2;
        __ pushq(temp);
        __ pushq(right);
        compiler->GenerateStaticCall(
            instance_call()->deopt_id(),
            instance_call()->token_pos(),
            target,
            kArgumentCount,
            Array::Handle(),  // No argument names.
            locs());
        ASSERT(result == RAX);
      }
      __ Bind(&done);
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
  ASSERT((left()->ResultCid() != kDoubleCid) &&
         (right()->ResultCid() != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
    new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptBinaryDoubleOp);
  Register temp = locs()->temp(0).reg();
  __ movq(temp, locs()->in(0).reg());
  __ orq(temp, locs()->in(1).reg());
  __ testl(temp, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
}


LocationSummary* BoxDoubleInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresXmmRegister());
  summary->set_out(Location::RequiresRegister());
  return summary;
}


class BoxDoubleSlowPath : public SlowPathCode {
 public:
  explicit BoxDoubleSlowPath(BoxDoubleInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Bind(entry_label());
    const Class& double_class = compiler->double_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class));
    const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(instruction_->token_pos(),
                           &label,
                           PcDescriptors::kOther,
                           locs);
    if (RAX != locs->out().reg()) __ movq(locs->out().reg(), RAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
  }

 private:
  BoxDoubleInstr* instruction_;
};


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BoxDoubleSlowPath* slow_path = new BoxDoubleSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  Register out_reg = locs()->out().reg();
  XmmRegister value = locs()->in(0).xmm_reg();

  AssemblerMacros::TryAllocate(compiler->assembler(),
                               compiler->double_class(),
                               slow_path->entry_label(),
                               Assembler::kFarJump,
                               out_reg);
  __ Bind(slow_path->exit_label());
  __ movsd(FieldAddress(out_reg, Double::value_offset()), value);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = CanDeoptimize() ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (CanDeoptimize()) summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresXmmRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->ResultCid();
  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().xmm_reg();

  if (value_cid == kDoubleCid) {
    __ movsd(result, FieldAddress(value, Double::value_offset()));
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(value);  // Untag input before conversion.
    __ cvtsi2sd(result, value);
    __ SmiTag(value);  // Restore input register.
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_, kDeoptBinaryDoubleOp);
    compiler->LoadDoubleOrSmiToXmm(result,
                                   value,
                                   locs()->temp(0).reg(),
                                   deopt);
  }
}


LocationSummary* UnboxedDoubleBinaryOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresXmmRegister());
  summary->set_in(1, Location::RequiresXmmRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnboxedDoubleBinaryOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).xmm_reg();
  XmmRegister right = locs()->in(1).xmm_reg();

  ASSERT(locs()->out().xmm_reg() == left);

  switch (op_kind()) {
    case Token::kADD: __ addsd(left, right); break;
    case Token::kSUB: __ subsd(left, right); break;
    case Token::kMUL: __ mulsd(left, right); break;
    case Token::kDIV: __ divsd(left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* MathSqrtInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresXmmRegister());
  summary->set_out(Location::RequiresXmmRegister());
  return summary;
}


void MathSqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ sqrtsd(locs()->out().xmm_reg(), locs()->in(0).xmm_reg());
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out().reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                            kDeoptUnaryOp);
      __ negq(value);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ notq(value);
      __ andq(value, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptDoubleToDouble);

  __ testq(value, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);  // Deoptimize if Smi.
  __ CompareClassId(value, kDoubleCid);
  __ j(NOT_EQUAL, deopt);  // Deoptimize if not Double.
  ASSERT(value == result);
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary() const {
  return MakeCallSummary();  // Calls a stub to allocate result.
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();

  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptIntegerToDouble);

  const Class& double_class = compiler->double_class();
  const Code& stub =
    Code::Handle(StubCode::GetAllocationStubForClass(double_class));
  const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());

  // TODO(fschneider): Inline new-space allocation and move the call into
  // deferred code.
  compiler->GenerateCall(instance_call()->token_pos(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  ASSERT(result == RAX);
  Register value = RBX;
  // Preserve argument on the stack until after the deoptimization point.
  __ movq(value, Address(RSP, 0));

  __ testq(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);  // Deoptimize if not Smi.
  __ SmiUntag(value);
  __ cvtsi2sd(XMM0, value);
  __ movsd(FieldAddress(result, Double::value_offset()), XMM0);
  __ Drop(1);
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary() const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptPolymorphicInstanceCallTestFail);
  if (ic_data().NumberOfChecks() == 0) {
    __ jmp(deopt);
    return;
  }
  ASSERT(ic_data().num_args_tested() == 1);
  if (!with_checks()) {
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(instance_call()->deopt_id(),
                                 instance_call()->token_pos(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs());
    return;
  }

  // Load receiver into RAX.
  __ movq(RAX,
      Address(RSP, (instance_call()->ArgumentCount() - 1) * kWordSize));
  Label done;
  if (ic_data().GetReceiverClassIdAt(0) == kSmiCid) {
    __ movq(RDI, Immediate(kSmiCid));
    __ testq(RAX, Immediate(kSmiTagMask));
    __ j(ZERO, &done, Assembler::kNearJump);
  } else {
    __ testq(RAX, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);
  }
  __ LoadClassId(RDI, RAX);
  __ Bind(&done);
  compiler->EmitTestAndCall(ic_data(),
                            RDI,  // Class id register.
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
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckClass);
  ASSERT(unary_checks().GetReceiverClassIdAt(0) != kSmiCid);
  __ testq(value, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
  __ LoadClassId(temp, value);
  Label is_ok;
  const intptr_t num_checks = unary_checks().NumberOfChecks();
  const bool use_near_jump = num_checks < 5;
  for (intptr_t i = 0; i < num_checks; i++) {
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


LocationSummary* CheckSmiInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(srdjan): Check if we can remove this by reordering CSE and LICM.
  if (value()->ResultCid() == kSmiCid) return;
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckSmi);
  __ testq(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, Location::RegisterOrConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const DeoptReasonId deopt_reason =
      (array_type() == kGrowableObjectArrayCid) ?
      kDeoptLoadIndexedGrowableArray : kDeoptLoadIndexedFixedArray;
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        deopt_reason);
  ASSERT(array_type() == kArrayCid ||
         array_type() == kImmutableArrayCid ||
         array_type() == kGrowableObjectArrayCid);
  intptr_t length_offset = (array_type() == kGrowableObjectArrayCid)
      ? GrowableObjectArray::length_offset()
      : Array::length_offset();

  // This case should not have created a bound check instruction.
  ASSERT(!(locs()->in(0).IsConstant() && locs()->in(1).IsConstant()));

  if (locs()->in(1).IsConstant()) {
    Register receiver = locs()->in(0).reg();
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int64_t imm =
        reinterpret_cast<int64_t>(constant.raw());
    __ cmpq(FieldAddress(receiver, length_offset), Immediate(imm));
    __ j(BELOW_EQUAL, deopt);
  } else if (locs()->in(0).IsConstant()) {
    const Object& constant = locs()->in(0).constant();
    ASSERT(constant.IsArray());
    const Array& array =  Array::Cast(constant);
    Register index = locs()->in(1).reg();
    __ cmpq(index,
        Immediate(reinterpret_cast<int64_t>(Smi::New(array.Length()))));
    __ j(ABOVE_EQUAL, deopt);
  } else {
    Register receiver = locs()->in(0).reg();
    Register index = locs()->in(1).reg();
    __ cmpq(index, FieldAddress(receiver, length_offset));
    __ j(ABOVE_EQUAL, deopt);
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


LocationSummary* UnboxedMintBinaryOpInstr::MakeLocationSummary() const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxedMintBinaryOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
