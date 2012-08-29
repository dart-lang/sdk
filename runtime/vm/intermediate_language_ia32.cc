// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

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
// on the stack and return the result in a fixed register EAX.
LocationSummary* Computation::MakeCallSummary() {
  LocationSummary* result = new LocationSummary(0, 0, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(EAX));
  return result;
}


void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  computation()->EmitNativeCode(compiler);
  if (is_used() && !compiler->is_optimizing()) {
    __ pushl(locs()->out().reg());
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(result == EAX);
  if (!compiler->is_optimizing()) {
    // Count only in unoptimized code.
    // TODO(srdjan): Replace the counting code with a type feedback
    // collection and counting stub.
    const Function& function =
          Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ incl(FieldAddress(temp, Function::usage_counter_offset()));
    if (FlowGraphCompiler::CanOptimize()) {
      // Do not optimize if usage count must be reported.
      __ cmpl(FieldAddress(temp, Function::usage_counter_offset()),
          Immediate(FLAG_optimization_counter_threshold));
      Label not_yet_hot, already_optimized;
      __ j(LESS, &not_yet_hot, Assembler::kNearJump);
      __ j(GREATER, &already_optimized, Assembler::kNearJump);
      __ pushl(result);  // Preserve result.
      __ pushl(temp);  // Argument for runtime: function to optimize.
      __ CallRuntime(kOptimizeInvokedFunctionRuntimeEntry);
      __ popl(temp);  // Remove argument.
      __ popl(result);  // Restore result.
      __ Bind(&not_yet_hot);
      __ Bind(&already_optimized);
    }
  }
  if (FLAG_trace_functions) {
    const Function& function =
        Function::ZoneHandle(compiler->parsed_function().function().raw());
    __ LoadObject(temp, function);
    __ pushl(result);  // Preserve result.
    __ pushl(temp);
    compiler->GenerateCallRuntime(Isolate::kNoDeoptId,
                                  0,
                                  CatchClauseNode::kInvalidTryIndex,
                                  kTraceFunctionExitRuntimeEntry,
                                  locs());
    __ popl(temp);  // Remove argument.
    __ popl(result);  // Restore result.
  }
#if defined(DEBUG)
  // TODO(srdjan): Fix for functions with finally clause.
  // A finally clause may leave a previously pushed return value if it
  // has its own return instruction. Method that have finally are currently
  // not optimized.
  if (!compiler->HasFinally()) {
    Label done;
    __ movl(EDI, EBP);
    __ subl(EDI, ESP);
    // + 1 for Pc marker.
    __ cmpl(EDI, Immediate((compiler->StackSize() + 1) * kWordSize));
    __ j(EQUAL, &done, Assembler::kNearJump);
    __ int3();
    __ Bind(&done);
  }
#endif
  __ LeaveFrame();
  __ ret();

  // Generate 1 byte NOP so that the debugger can patch the
  // return pattern with a call to the debug stub.
  __ nop(1);
  compiler->AddCurrentDescriptor(PcDescriptors::kReturn,
                                 deopt_id(),
                                 token_pos(),
                                 CatchClauseNode::kInvalidTryIndex);
}


LocationSummary* ClosureCallComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* result =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(Location::RegisterLocation(EAX));
  result->set_temp(0, Location::RegisterLocation(EDX));  // Arg. descriptor.
  return result;
}


LocationSummary* LoadLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ movl(result, Address(EBP, local().index() * kWordSize));
}


LocationSummary* StoreLocalComp::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movl(Address(EBP, local().index() * kWordSize), value);
}


LocationSummary* ConstantComp::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ LoadObject(result, value());
}


LocationSummary* AssertAssignableComp::MakeLocationSummary() const {
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


LocationSummary* AssertBooleanComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void AssertBooleanComp::EmitNativeCode(FlowGraphCompiler* compiler) {
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

    __ pushl(obj);  // Push the source object.
    compiler->GenerateCallRuntime(deopt_id(),
                                  token_pos(),
                                  try_index(),
                                  kConditionTypeErrorRuntimeEntry,
                                  locs());
    // We should never return here.
    __ int3();
    __ Bind(&done);
  }
  ASSERT(obj == result);
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


LocationSummary* EqualityCompareComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const bool is_checked_strict_equal =
      HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  if ((receiver_class_id() == kSmiCid) ||
      (receiver_class_id() == kDoubleCid) ||
      is_checked_strict_equal) {
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
    locs->set_in(0, Location::RegisterLocation(ECX));
    locs->set_in(1, Location::RegisterLocation(EDX));
    locs->set_temp(0, Location::RegisterLocation(EBX));
    locs->set_out(Location::RegisterLocation(EAX));
    return locs;
  }
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_in(1, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


static void EmitEqualityAsInstanceCall(FlowGraphCompiler* compiler,
                                       intptr_t deopt_id,
                                       intptr_t token_pos,
                                       intptr_t try_index,
                                       Token::Kind kind,
                                       LocationSummary* locs) {
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 deopt_id,
                                 token_pos,
                                 try_index);
  const String& operator_name = String::ZoneHandle(Symbols::New("=="));
  const int kNumberOfArguments = 2;
  const Array& kNoArgumentNames = Array::Handle();
  const int kNumArgumentsChecked = 2;

  Label done, false_label, true_label;
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  __ popl(right);
  __ popl(left);
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label check_identity, instance_call;
  __ cmpl(right, raw_null);
  __ j(EQUAL, &check_identity, Assembler::kNearJump);
  __ cmpl(left, raw_null);
  __ j(NOT_EQUAL, &instance_call, Assembler::kNearJump);

  __ Bind(&check_identity);
  __ cmpl(left, right);
  __ j(EQUAL, &true_label);
  if (kind == Token::kEQ) {
    __ LoadObject(EAX, compiler->bool_false());
    __ jmp(&done);
    __ Bind(&true_label);
    __ LoadObject(EAX, compiler->bool_true());
    __ jmp(&done);
  } else {
    ASSERT(kind == Token::kNE);
    __ jmp(&false_label);
  }

  __ Bind(&instance_call);
  __ pushl(left);
  __ pushl(right);
  compiler->GenerateInstanceCall(deopt_id,
                                 token_pos,
                                 try_index,
                                 operator_name,
                                 kNumberOfArguments,
                                 kNoArgumentNames,
                                 kNumArgumentsChecked,
                                 locs);
  if (kind == Token::kNE) {
    // Negate the condition: true label returns false and vice versa.
    __ CompareObject(EAX, compiler->bool_true());
    __ j(EQUAL, &true_label, Assembler::kNearJump);
    __ Bind(&false_label);
    __ LoadObject(EAX, compiler->bool_true());
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&true_label);
    __ LoadObject(EAX, compiler->bool_false());
  }
  __ Bind(&done);
}


static void EmitEqualityAsPolymorphicCall(FlowGraphCompiler* compiler,
                                          const ICData& orig_ic_data,
                                          LocationSummary* locs,
                                          BranchInstr* branch,
                                          Token::Kind kind,
                                          intptr_t deopt_id,
                                          intptr_t token_pos,
                                          intptr_t try_index) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  const ICData& ic_data = ICData::Handle(orig_ic_data.AsUnaryClassChecks());
  ASSERT(ic_data.NumberOfChecks() > 0);
  ASSERT(ic_data.num_args_tested() == 1);
  Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptEquality);
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  __ testl(left, Immediate(kSmiTagMask));
  Register temp = locs->temp(0).reg();
  if (ic_data.GetReceiverClassIdAt(0) == kSmiCid) {
    Label done, load_class_id;
    __ j(NOT_ZERO, &load_class_id, Assembler::kNearJump);
    __ movl(temp, Immediate(kSmiCid));
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
    __ cmpl(temp, Immediate(ic_data.GetReceiverClassIdAt(i)));
    __ j(NOT_EQUAL, &next_test);
    const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(i));
    if (target.Owner() == object_store->object_class()) {
      // Object.== is same as ===.
      __ Drop(2);
      __ cmpl(left, right);
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
    } else {
      const int kNumberOfArguments = 2;
      const Array& kNoArgumentNames = Array::Handle();
      compiler->GenerateStaticCall(deopt_id,
                                   token_pos,
                                   try_index,
                                   target,
                                   kNumberOfArguments,
                                   kNoArgumentNames,
                                   locs);
      if (branch == NULL) {
        if (kind == Token::kNE) {
          Label false_label;
          __ CompareObject(EAX, compiler->bool_true());
          __ j(EQUAL, &false_label, Assembler::kNearJump);
          __ LoadObject(EAX, compiler->bool_true());
          __ jmp(&done);
          __ Bind(&false_label);
          __ LoadObject(EAX, compiler->bool_false());
          __ jmp(&done);
        }
      } else {
        __ CompareObject(EAX, compiler->bool_true());
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
  __ testl(left, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
  // 'left' is not Smi.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label identity_compare;
  __ cmpl(right, raw_null);
  __ j(EQUAL, &identity_compare);
  __ cmpl(left, raw_null);
  __ j(EQUAL, &identity_compare);

  __ LoadClassId(temp, left);
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    __ cmpl(temp, Immediate(ic_data.GetReceiverClassIdAt(i)));
    if (i == (ic_data.NumberOfChecks() - 1)) {
      __ j(NOT_EQUAL, deopt);
    } else {
      __ j(EQUAL, &identity_compare);
    }
  }
  __ Bind(&identity_compare);
  __ cmpl(left, right);
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
                                       intptr_t token_pos,
                                       intptr_t try_index) {
  ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  ASSERT(!ic_data.IsNull() && (ic_data.NumberOfChecks() > 0));
  Register left = locs->in(0).reg();
  Register right = locs->in(1).reg();
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done, identity_compare, non_null_compare;
  __ cmpl(right, raw_null);
  __ j(EQUAL, &identity_compare, Assembler::kNearJump);
  __ cmpl(left, raw_null);
  __ j(NOT_EQUAL, &non_null_compare, Assembler::kNearJump);
  // Comparison with NULL is "===".
  __ Bind(&identity_compare);
  __ cmpl(left, right);
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
  __ pushl(left);
  __ pushl(right);
  EmitEqualityAsPolymorphicCall(compiler, ic_data, locs, branch, kind,
                                deopt_id, token_pos, try_index);
  __ Bind(&done);
}


static void EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                const LocationSummary& locs,
                                Token::Kind kind,
                                BranchInstr* branch,
                                intptr_t deopt_id) {
  Register left = locs.in(0).reg();
  Register right = locs.in(1).reg();
  const bool left_is_smi = (branch == NULL) ?
      false : (branch->computation()->left()->ResultCid() == kSmiCid);
  const bool right_is_smi = (branch == NULL) ?
      false : (branch->computation()->right()->ResultCid() == kSmiCid);
  // TODO(fschneider): Move smi smi checks outside this instruction.
  if (!left_is_smi || !right_is_smi) {
    Register temp = locs.temp(0).reg();
    Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptSmiCompareSmi);
    __ movl(temp, left);
    __ orl(temp, right);
    __ testl(temp, Immediate(kSmiTagMask));
    __ j(NOT_ZERO, deopt);
  }

  Condition true_condition = TokenKindToSmiCondition(kind);
  __ cmpl(left, right);

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
                                   BranchInstr* branch,
                                   intptr_t deopt_id) {
  Register left = locs.in(0).reg();
  Register right = locs.in(1).reg();
  // TODO(srdjan): temp is only needed if a conversion Smi->Double occurs.
  Register temp = locs.temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id, kDeoptDoubleComparison);
  compiler->LoadDoubleOrSmiToXmm(XMM0, left, temp, deopt);
  compiler->LoadDoubleOrSmiToXmm(XMM1, right, temp, deopt);

  Condition true_condition = TokenKindToDoubleCondition(kind);
  if (branch != NULL) {
    compiler->EmitDoubleCompareBranch(
        true_condition, XMM0, XMM1, branch);
  } else {
    compiler->EmitDoubleCompareBool(
        true_condition, XMM0, XMM1, locs.out().reg());
  }
}


void EqualityCompareComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  BranchInstr* kNoBranch = NULL;
  if (receiver_class_id() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), kNoBranch, deopt_id());
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    // Deoptimizes if both arguments are Smi, or if none is Double or Smi.
    EmitDoubleComparisonOp(compiler, *locs(), kind(), kNoBranch, deopt_id());
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
                               deopt_id(), token_pos(), try_index());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushl(left);
  __ pushl(right);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             try_index(),
                             kind(),
                             locs());
  ASSERT(locs()->out().reg() == EAX);
}


void EqualityCompareComp::EmitBranchCode(FlowGraphCompiler* compiler,
                                         BranchInstr* branch) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  if (receiver_class_id() == kSmiCid) {
    // Deoptimizes if both arguments not Smi.
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch, deopt_id());
    return;
  }
  if (receiver_class_id() == kDoubleCid) {
    // Deoptimizes if both arguments are Smi, or if none is Double or Smi.
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch, deopt_id());
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
                               deopt_id(), token_pos(), try_index());
    return;
  }
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushl(left);
  __ pushl(right);
  EmitEqualityAsInstanceCall(compiler,
                             deopt_id(),
                             token_pos(),
                             try_index(),
                             Token::kEQ,  // kNE reverse occurs at branch.
                             locs());
  Condition branch_condition = (kind() == Token::kNE) ? NOT_EQUAL : EQUAL;
  __ CompareObject(EAX, compiler->bool_true());
  branch->EmitBranchOnCondition(compiler, branch_condition);
}


LocationSummary* RelationalOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  if ((operands_class_id() == kSmiCid) || (operands_class_id() == kDoubleCid)) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_out(Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  // Pick arbitrary fixed input registers because this is a call.
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_in(1, Location::RegisterLocation(ECX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void RelationalOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), NULL, deopt_id());
    return;
  }
  if (operands_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), NULL, deopt_id());
    return;
  }

  // Push arguments for the call.
  // TODO(fschneider): Split this instruction into different types to avoid
  // explicitly pushing arguments to the call here.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ pushl(left);
  __ pushl(right);
  if (HasICData() && (ic_data()->NumberOfChecks() > 0)) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), kDeoptRelationalOp);
    // Load class into EDI. Since this is a call, any register except
    // the fixed input registers would be ok.
    ASSERT((left != EDI) && (right != EDI));
    Label done;
    const intptr_t kNumArguments = 2;
    __ movl(EDI, Immediate(kSmiCid));
    __ testl(left, Immediate(kSmiTagMask));
    __ j(ZERO, &done);
    __ LoadClassId(EDI, left);
    __ Bind(&done);
    compiler->EmitTestAndCall(ICData::Handle(ic_data()->AsUnaryClassChecks()),
                              EDI,  // Class id register.
                              kNumArguments,
                              Array::Handle(),  // No named arguments.
                              deopt,  // Deoptimize target.
                              deopt_id(),
                              token_pos(),
                              try_index(),
                              locs());
    return;
  }
  const String& function_name =
      String::ZoneHandle(Symbols::New(Token::Str(kind())));
  compiler->AddCurrentDescriptor(PcDescriptors::kDeopt,
                                 deopt_id(),
                                 token_pos(),
                                 try_index());
  const intptr_t kNumArguments = 2;
  const intptr_t kNumArgsChecked = 2;  // Type-feedback.
  compiler->GenerateInstanceCall(deopt_id(),
                                 token_pos(),
                                 try_index(),
                                 function_name,
                                 kNumArguments,
                                 Array::ZoneHandle(),  // No optional arguments.
                                 kNumArgsChecked,
                                 locs());
}


void RelationalOpComp::EmitBranchCode(FlowGraphCompiler* compiler,
                                      BranchInstr* branch) {
  if (operands_class_id() == kSmiCid) {
    EmitSmiComparisonOp(compiler, *locs(), kind(), branch, deopt_id());
    return;
  }
  if (operands_class_id() == kDoubleCid) {
    EmitDoubleComparisonOp(compiler, *locs(), kind(), branch, deopt_id());
    return;
  }
  EmitNativeCode(compiler);
  __ CompareObject(EAX, compiler->bool_true());
  branch->EmitBranchOnCondition(compiler, EQUAL);
}


LocationSummary* NativeCallComp::MakeLocationSummary() const {
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


void NativeCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EAX);
  ASSERT(locs()->temp(1).reg() == ECX);
  ASSERT(locs()->temp(2).reg() == EDX);
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in EAX.
  intptr_t arg_count = argument_count();
  if (is_native_instance_closure()) {
    arg_count += 1;
  }
  if (!has_optional_parameters() && !is_native_instance_closure()) {
    __ leal(EAX, Address(EBP, (1 + arg_count) * kWordSize));
  } else {
    __ leal(EAX,
            Address(EBP, ParsedFunction::kFirstLocalSlotIndex * kWordSize));
  }
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_c_function())));
  __ movl(EDX, Immediate(arg_count));
  compiler->GenerateCall(token_pos(),
                         try_index(),
                         &StubCode::CallNativeCFunctionLabel(),
                         PcDescriptors::kOther,
                         locs());
  __ popl(result);
}


LocationSummary* LoadIndexedComp::MakeLocationSummary() const {
  ASSERT((receiver_type() == kGrowableObjectArrayCid) ||
         (receiver_type() == kArrayCid) ||
         (receiver_type() == kImmutableArrayCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = receiver_type() == kGrowableObjectArrayCid ? 1 : 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, Location::RequiresRegister());
  if (receiver_type() == kGrowableObjectArrayCid) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  locs->set_out(Location::RequiresRegister());
  return locs;
}


void LoadIndexedComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register receiver = locs()->in(0).reg();
  Register index = locs()->in(1).reg();
  Register result = locs()->out().reg();

  switch (receiver_type()) {
    case kArrayCid:
    case kImmutableArrayCid:
      // Note that index is Smi, i.e, times 2.
      ASSERT(kSmiTagShift == 1);
      __ movl(result, FieldAddress(receiver, index, TIMES_2, sizeof(RawArray)));
      break;

    case kGrowableObjectArrayCid: {
      Register temp = locs()->temp(0).reg();
      __ movl(temp, FieldAddress(receiver, GrowableObjectArray::data_offset()));
      // Note that index is Smi, i.e, times 2.
      ASSERT(kSmiTagShift == 1);
      __ movl(result, FieldAddress(temp, index, TIMES_2, sizeof(RawArray)));
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}


LocationSummary* StoreIndexedComp::MakeLocationSummary() const {
  ASSERT((receiver_type() == kGrowableObjectArrayCid) ||
         (receiver_type() == kArrayCid));
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = receiver_type() == kGrowableObjectArrayCid ? 1 : 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_in(1, Location::RequiresRegister());
  locs->set_in(2, Location::RequiresRegister());
  if (receiver_type() == kGrowableObjectArrayCid) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}


void StoreIndexedComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register receiver = locs()->in(0).reg();
  Register index = locs()->in(1).reg();
  Register value = locs()->in(2).reg();

  switch (receiver_type()) {
    case kArrayCid:
    case kImmutableArrayCid:
      // Note that index is Smi, i.e, times 2.
      ASSERT(kSmiTagShift == 1);
      if (this->value()->NeedsStoreBuffer()) {
        __ StoreIntoObject(receiver,
            FieldAddress(receiver, index, TIMES_2, sizeof(RawArray)),
            value);
      } else {
        __ StoreIntoObjectNoBarrier(receiver,
            FieldAddress(receiver, index, TIMES_2, sizeof(RawArray)),
            value);
      }
      break;

    case kGrowableObjectArrayCid: {
      Register temp = locs()->temp(0).reg();
      __ movl(temp, FieldAddress(receiver, GrowableObjectArray::data_offset()));
      // Note that index is Smi, i.e, times 2.
      ASSERT(kSmiTagShift == 1);
      if (this->value()->NeedsStoreBuffer()) {
        __ StoreIntoObject(temp,
            FieldAddress(temp, index, TIMES_2, sizeof(RawArray)),
            value);
      } else {
        __ StoreIntoObjectNoBarrier(temp,
            FieldAddress(temp, index, TIMES_2, sizeof(RawArray)),
            value);
      }
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}


LocationSummary* LoadInstanceFieldComp::MakeLocationSummary() const {
  // TODO(fschneider): For this instruction the input register may be
  // reused for the result (but is not required to) because the input
  // is not used after the result is defined.  We should consider adding
  // this information to the input policy.
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
  __ movl(result_reg, FieldAddress(instance_reg, field().Offset()));
}


LocationSummary* StoreInstanceFieldComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t num_temps =  0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void StoreInstanceFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register value_reg = locs()->in(1).reg();
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(instance_reg,
        FieldAddress(instance_reg, field().Offset()), value_reg);
  } else {
    __ StoreIntoObjectNoBarrier(instance_reg,
        FieldAddress(instance_reg, field().Offset()), value_reg);
  }
}


LocationSummary* LoadStaticFieldComp::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();
  __ LoadObject(result, field());
  __ movl(result, FieldAddress(result, Field::value_offset()));
}


LocationSummary* StoreStaticFieldComp::MakeLocationSummary() const {
  LocationSummary* locs = new LocationSummary(1, 1, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void StoreStaticFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(locs()->out().reg() == value);

  __ LoadObject(temp, field());
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(temp, FieldAddress(temp, Field::value_offset()), value);
  } else {
    __ StoreIntoObjectNoBarrier(
        temp, FieldAddress(temp, Field::value_offset()), value);
  }
}


LocationSummary* InstanceOfComp::MakeLocationSummary() const {
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


void InstanceOfComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == EAX);  // Value.
  ASSERT(locs()->in(1).reg() == ECX);  // Instantiator.
  ASSERT(locs()->in(2).reg() == EDX);  // Instantiator type arguments.

  compiler->GenerateInstanceOf(deopt_id(),
                               token_pos(),
                               try_index(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out().reg() == EAX);
}


LocationSummary* CreateArrayComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void CreateArrayComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  EDX = length, ECX = element type.
  ASSERT(locs()->in(0).reg() == ECX);
  __ movl(EDX,  Immediate(Smi::RawValue(ArgumentCount())));
  compiler->GenerateCall(token_pos(),
                         try_index(),
                         &StubCode::AllocateArrayLabel(),
                         PcDescriptors::kOther,
                         locs());
  ASSERT(locs()->out().reg() == EAX);

  // Pop the element values from the stack into the array.
  __ leal(EDX, FieldAddress(EAX, Array::data_offset()));
  for (int i = ArgumentCount() - 1; i >= 0; --i) {
    ASSERT(ArgumentAt(i)->value()->IsUse());
    __ popl(Address(EDX, i * kWordSize));
  }
}


LocationSummary*
    AllocateObjectWithBoundsCheckComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_in(1, Location::RegisterLocation(ECX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void AllocateObjectWithBoundsCheckComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  const Class& cls = Class::ZoneHandle(constructor().Owner());
  Register type_arguments = locs()->in(0).reg();
  Register instantiator_type_arguments = locs()->in(1).reg();
  Register result = locs()->out().reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  __ PushObject(cls);
  __ pushl(type_arguments);
  __ pushl(instantiator_type_arguments);
  compiler->GenerateCallRuntime(deopt_id(),
                                token_pos(),
                                try_index(),
                                kAllocateObjectWithBoundsCheckRuntimeEntry,
                                locs());
  // Pop instantiator type arguments, type arguments, and class.
  // source location.
  __ Drop(3);
  __ popl(result);  // Pop new instance.
}


LocationSummary* LoadVMFieldComp::MakeLocationSummary() const {
  return LocationSummary::Make(1,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadVMFieldComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instance_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
  if (HasICData()) {
    ASSERT(original() != NULL);
    Label* deopt = compiler->AddDeoptStub(original()->deopt_id(),
                                          kDeoptInstanceGetterSameTarget);
    // Smis do not have instance fields (Smi class is always first).
    // Use 'result' as temporary register.
    ASSERT(result_reg != instance_reg);
    ASSERT(ic_data() != NULL);
    compiler->EmitClassChecksNoSmi(*ic_data(), instance_reg, result_reg, deopt);
  }

  __ movl(result_reg, FieldAddress(instance_reg, offset_in_bytes()));
}


LocationSummary* InstantiateTypeArgumentsComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_temp(0, Location::RegisterLocation(ECX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void InstantiateTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
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
    __ cmpl(instantiator_reg, raw_null);
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
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid, temp);
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    __ cmpl(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
            Immediate(Smi::RawValue(len)));
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&type_arguments_uninstantiated);
  }
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(type_arguments());
  __ pushl(instantiator_reg);  // Push instantiator type arguments.
  compiler->GenerateCallRuntime(deopt_id(),
                                token_pos(),
                                try_index(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                locs());
  __ Drop(2);  // Drop instantiator and uninstantiated type arguments.
  __ popl(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  ASSERT(instantiator_reg == result_reg);
  // 'result_reg': Instantiated type arguments.
}


LocationSummary*
    ExtractConstructorTypeArgumentsComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ExtractConstructorTypeArgumentsComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out().reg();
  ASSERT(instantiator_reg == result_reg);
  Register temp_reg = locs()->temp(0).reg();

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
    __ cmpl(instantiator_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  // Instantiate non-null type arguments.
  if (type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    // No need to check instantiator_reg for null here, because a null
    // instantiator will have the wrong class (Null instead of TypeArguments).
    Label type_arguments_uninstantiated;
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid, temp_reg);
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length =
        Immediate(Smi::RawValue(type_arguments().Length()));
    __ cmpl(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
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
    ExtractConstructorInstantiatorComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void ExtractConstructorInstantiatorComp::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(instantiator()->IsUse());
  Register instantiator_reg = locs()->in(0).reg();
  ASSERT(locs()->out().reg() == instantiator_reg);
  Register temp_reg = locs()->temp(0).reg();

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
    __ cmpl(instantiator_reg, raw_null);
    __ j(NOT_EQUAL, &instantiator_not_null, Assembler::kNearJump);
    // Null was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movl(instantiator_reg,
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
    __ CompareClassId(instantiator_reg, kTypeArgumentsCid, temp_reg);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    Immediate arguments_length =
        Immediate(Smi::RawValue(type_arguments().Length()));
    __ cmpl(FieldAddress(instantiator_reg, TypeArguments::length_offset()),
        arguments_length);
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
    // The instantiator was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, no proper instantiator needed.
    __ movl(instantiator_reg,
            Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  }
  __ Bind(&done);
  // instantiator_reg: instantiator or kNoInstantiator.
}


LocationSummary* AllocateContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void AllocateContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EDX);
  ASSERT(locs()->out().reg() == EAX);

  __ movl(EDX, Immediate(num_context_variables()));
  const ExternalLabel label("alloc_context",
                            StubCode::AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         try_index(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
}


LocationSummary* CloneContextComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(Location::RegisterLocation(EAX));
  return locs;
}


void CloneContextComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ pushl(context_value);
  compiler->GenerateCallRuntime(deopt_id(),
                                token_pos(),
                                try_index(),
                                kCloneContextRuntimeEntry,
                                locs());
  __ popl(result);  // Remove argument.
  __ popl(result);  // Get result (cloned context).
}


LocationSummary* CatchEntryComp::MakeLocationSummary() const {
  return LocationSummary::Make(0,
                               Location::NoLocation(),
                               LocationSummary::kNoCall);
}


// Restore stack and initialize the two exception variables:
// exception and stack trace variables.
void CatchEntryComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Restore RSP from RBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t locals_space_size = compiler->StackSize() * kWordSize;
  ASSERT(locals_space_size >= 0);
  const intptr_t offset_size =
      -locals_space_size + FlowGraphCompiler::kLocalsOffsetFromFP;
  __ leal(ESP, Address(EBP, offset_size));

  ASSERT(!exception_var().is_captured());
  ASSERT(!stacktrace_var().is_captured());
  __ movl(Address(EBP, exception_var().index() * kWordSize),
          kExceptionObjectReg);
  __ movl(Address(EBP, stacktrace_var().index() * kWordSize),
          kStackTraceObjectReg);
}


LocationSummary* CheckStackOverflowComp::MakeLocationSummary() const {
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
  explicit CheckStackOverflowSlowPath(CheckStackOverflowComp* computation)
      : computation_(computation) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(computation_->locs());
    compiler->GenerateCallRuntime(computation_->deopt_id(),
                                  computation_->token_pos(),
                                  computation_->try_index(),
                                  kStackOverflowRuntimeEntry,
                                  computation_->locs());
    compiler->RestoreLiveRegisters(computation_->locs());
    __ jmp(exit_label());
  }

 private:
  CheckStackOverflowComp* computation_;
};


void CheckStackOverflowComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ cmpl(ESP,
          Address::Absolute(Isolate::Current()->stack_limit_address()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 3;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_in(1, Location::RegisterLocation(ECX));
    summary->set_out(Location::SameAsFirstInput());
    summary->set_temp(0, Location::RegisterLocation(EBX));
    // Will be used for for sign extension.
    summary->set_temp(1, Location::RegisterLocation(EDX));
    summary->set_temp(2, Location::RequiresRegister());
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RegisterLocation(ECX));
    summary->set_out(Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    // Two Smi operands can easily overflow into Mint.
    const intptr_t kNumTemps = 2;
    LocationSummary* summary =
        new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_in(1, Location::RegisterLocation(EDX));
    summary->set_temp(0, Location::RegisterLocation(EBX));
    summary->set_temp(1, Location::RegisterLocation(ECX));
    summary->set_out(Location::RegisterLocation(EAX));
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


void BinarySmiOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();
  ASSERT(left == result);
  Label* deopt = NULL;
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      // Can't deoptimize. Arguments are already checked for smi.
      break;
    default:
      deopt  = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                      kDeoptBinarySmiOp);
  }

  switch (op_kind()) {
    case Token::kADD: {
      __ addl(left, right);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kSUB: {
      __ subl(left, right);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kMUL: {
      __ SmiUntag(left);
      __ imull(left, right);
      __ j(OVERFLOW, deopt);
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
      Register temp = locs()->temp(0).reg();
      // Handle divide by zero in runtime.
      // Deoptimization requires that temp and right are preserved.
      __ testl(right, right);
      __ j(ZERO, deopt);
      ASSERT(left == EAX);
      ASSERT((right != EDX) && (right != EAX));
      ASSERT((temp != EDX) && (temp != EAX));
      ASSERT(locs()->temp(1).reg() == EDX);
      ASSERT(result == EAX);
      Register right_temp = locs()->temp(2).reg();
      __ movl(right_temp, right);
      __ SmiUntag(left);
      __ SmiUntag(right_temp);
      __ cdq();  // Sign extend EAX -> EDX:EAX.
      __ idivl(right_temp);  //  EAX: quotient, EDX: remainder.
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ cmpl(result, Immediate(0x40000000));
      __ j(EQUAL, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      // sarl operation masks the count to 5 bits.
      const Immediate kCountLimit = Immediate(0x1F);
      __ cmpl(right, Immediate(0));
      __ j(LESS, deopt);
      __ SmiUntag(right);
      __ cmpl(right, kCountLimit);
      Label count_ok;
      __ j(LESS, &count_ok, Assembler::kNearJump);
      __ movl(right, kCountLimit);
      __ Bind(&count_ok);
      ASSERT(right == ECX);  // Count must be in ECX
      __ SmiUntag(left);
      __ sarl(left, right);
      __ SmiTag(left);
      break;
    }
    case Token::kSHL: {
      Register temp = locs()->temp(0).reg();
      Label call_method, done;
      // Check if count too large for handling it inlined.
      __ movl(temp, left);
      __ cmpl(right,
          Immediate(reinterpret_cast<int64_t>(Smi::New(Smi::kBits))));
      __ j(ABOVE_EQUAL, &call_method, Assembler::kNearJump);
      Register right_temp = locs()->temp(1).reg();
      ASSERT(right_temp == ECX);  // Count must be in ECX
      __ movl(right_temp, right);
      __ SmiUntag(right_temp);
      // Overflow test (preserve temp and right);
      __ shll(left, right_temp);
      __ sarl(left, right_temp);
      __ cmpl(left, temp);
      __ j(NOT_EQUAL, &call_method, Assembler::kNearJump);  // Overflow.
      // Shift for result now we know there is no overflow.
      __ shll(left, right_temp);
      __ jmp(&done);
      {
        __ Bind(&call_method);
        Function& target = Function::ZoneHandle(
            ic_data()->GetTargetForReceiverClassId(kSmiCid));
        ASSERT(!target.IsNull());
        const intptr_t kArgumentCount = 2;
        __ pushl(temp);
        __ pushl(right);
        compiler->GenerateStaticCall(
            instance_call()->deopt_id(),
            instance_call()->token_pos(),
            instance_call()->try_index(),
            target,
            kArgumentCount,
            Array::Handle(),  // No argument names.
            locs());
        ASSERT(result == EAX);
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


LocationSummary* BinaryMintOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  ASSERT(op_kind() == Token::kBIT_AND);
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_temp(0, Location::RegisterLocation(EDX));
  summary->set_out(Location::RegisterLocation(EAX));
  return summary;
}


void BinaryMintOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(regis): For now, we only support Token::kBIT_AND for a Mint or Smi
  // receiver and a Mint or Smi argument. We fall back to the run time call if
  // both receiver and argument are Mint or if one of them is Mint and the other
  // is a negative Smi.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out().reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(left == result);
  ASSERT(op_kind() == Token::kBIT_AND);
  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptBinaryMintOp);
  Label mint_static_call, smi_static_call, non_smi, smi_smi, done;
  __ testl(left, Immediate(kSmiTagMask));  // Is receiver Smi?
  __ j(NOT_ZERO, &non_smi);
  __ testl(right, Immediate(kSmiTagMask));  // Is argument Smi?
  __ j(ZERO, &smi_smi);
  __ CompareClassId(right, kMintCid, temp);  // Is argument Mint?
  __ j(NOT_EQUAL, deopt);  // Argument neither Smi nor Mint.
  __ cmpl(left, Immediate(0));
  __ j(LESS, &smi_static_call);  // Negative Smi receiver, Mint argument.

  // Positive Smi receiver, Mint argument.
  // Load lower argument Mint word, convert to Smi. It is OK to loose bits.
  __ movl(right, FieldAddress(right, Mint::value_offset()));
  __ SmiTag(right);
  __ andl(result, right);
  __ jmp(&done);

  __ Bind(&non_smi);  // Receiver is non-Smi.
  __ CompareClassId(left, kMintCid, temp);  // Is receiver Mint?
  __ j(NOT_EQUAL, deopt);  // Receiver neither Smi nor Mint.
  __ testl(right, Immediate(kSmiTagMask));  // Is argument Smi?
  __ j(NOT_ZERO, &mint_static_call);  // Mint receiver, non-Smi argument.
  __ cmpl(right, Immediate(0));
  __ j(LESS, &mint_static_call);  // Mint receiver, negative Smi argument.

  // Mint receiver, positive Smi argument.
  // Load lower receiver Mint word, convert to Smi. It is OK to loose bits.
  __ movl(result, FieldAddress(left, Mint::value_offset()));
  __ SmiTag(result);
  __ Bind(&smi_smi);
  __ andl(result, right);
  __ jmp(&done);

  __ Bind(&smi_static_call);
  {
    Function& target = Function::ZoneHandle(
        ic_data()->GetTargetForReceiverClassId(kSmiCid));
    if (target.IsNull()) {
      __ jmp(deopt);
    } else {
      __ pushl(left);
      __ pushl(right);
      compiler->GenerateStaticCall(
          instance_call()->deopt_id(),
          instance_call()->token_pos(),
          instance_call()->try_index(),
          target,
          instance_call()->ArgumentCount(),
          instance_call()->argument_names(),
          locs());
      ASSERT(result == EAX);
      __ jmp(&done);
    }
  }

  __ Bind(&mint_static_call);
  {
    Function& target = Function::ZoneHandle(
        ic_data()->GetTargetForReceiverClassId(kMintCid));
    if (target.IsNull()) {
      __ jmp(deopt);
    } else {
      __ pushl(left);
      __ pushl(right);
      compiler->GenerateStaticCall(
          instance_call()->deopt_id(),
          instance_call()->token_pos(),
          instance_call()->try_index(),
          target,
          instance_call()->ArgumentCount(),
          instance_call()->argument_names(),
          locs());
      ASSERT(result == EAX);
    }
  }
  __ Bind(&done);
}


LocationSummary* BinaryDoubleOpComp::MakeLocationSummary() const {
  return MakeCallSummary();  // Calls into a stub for allocation.
}


void BinaryDoubleOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = EBX;
  Register right = ECX;
  Register temp = EDX;
  Register result = locs()->out().reg();

  const Class& double_class = compiler->double_class();
  const Code& stub =
    Code::Handle(StubCode::GetAllocationStubForClass(double_class));
  const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());
  compiler->GenerateCall(instance_call()->token_pos(),
                         instance_call()->try_index(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  // Newly allocated object is now in the result register (RAX).
  ASSERT(result == EAX);
  __ movl(right, Address(ESP, 0));
  __ movl(left, Address(ESP, kWordSize));

  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptBinaryDoubleOp);

  // Binary operation of two Smi's produces a Smi not a double.
  __ movl(temp, left);
  __ orl(temp, right);
  __ testl(temp, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);

  compiler->LoadDoubleOrSmiToXmm(XMM0, left, temp, deopt);
  compiler->LoadDoubleOrSmiToXmm(XMM1, right, temp, deopt);

  switch (op_kind()) {
    case Token::kADD: __ addsd(XMM0, XMM1); break;
    case Token::kSUB: __ subsd(XMM0, XMM1); break;
    case Token::kMUL: __ mulsd(XMM0, XMM1); break;
    case Token::kDIV: __ divsd(XMM0, XMM1); break;
    default: UNREACHABLE();
  }

  __ movsd(FieldAddress(result, Double::value_offset()), XMM0);

  __ Drop(2);
}


LocationSummary* CheckEitherNonSmiComp::MakeLocationSummary() const {
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


void CheckEitherNonSmiComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(instance_call_->deopt_id(),
                                        kDeoptBinaryDoubleOp);

  Register temp = locs()->temp(0).reg();
  __ movl(temp, locs()->in(0).reg());
  __ orl(temp, locs()->in(1).reg());
  __ testl(temp, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
}


LocationSummary* BoxDoubleComp::MakeLocationSummary() const {
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
  explicit BoxDoubleSlowPath(BoxDoubleComp* computation)
      : computation_(computation) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Bind(entry_label());
    const Class& double_class = compiler->double_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class));
    const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());

    // TODO(vegorov): here stack map needs to be set up correctly to skip
    // double registers.
    LocationSummary* locs = computation_->locs();
    locs->live_registers()->Remove(locs->out());

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(computation_->instance_call()->token_pos(),
                           computation_->instance_call()->try_index(),
                           &label,
                           PcDescriptors::kOther,
                           locs);
    if (EAX != locs->out().reg()) __ movl(locs->out().reg(), EAX);
    compiler->RestoreLiveRegisters(locs);

    __ jmp(exit_label());
  }

 private:
  BoxDoubleComp* computation_;
};


void BoxDoubleComp::EmitNativeCode(FlowGraphCompiler* compiler) {
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


LocationSummary* UnboxDoubleComp::MakeLocationSummary() const {
  const intptr_t v_cid = value()->ResultCid();

  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = (v_cid != kDoubleCid) ? 1 : 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (v_cid != kDoubleCid) summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(Location::RequiresXmmRegister());
  return summary;
}


void UnboxDoubleComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t v_cid = value()->ResultCid();

  const Register value = locs()->in(0).reg();
  const XmmRegister result = locs()->out().xmm_reg();
  if (v_cid != kDoubleCid) {
    Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                          kDeoptBinaryDoubleOp);
    compiler->LoadDoubleOrSmiToXmm(result,
                                   value,
                                   locs()->temp(0).reg(),
                                   deopt);
  } else {
    __ movsd(result, FieldAddress(value, Double::value_offset()));
  }
}


LocationSummary* UnboxedDoubleBinaryOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresXmmRegister());
  summary->set_in(1, Location::RequiresXmmRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnboxedDoubleBinaryOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
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


LocationSummary* UnarySmiOpComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(Location::SameAsFirstInput());
  return summary;
}


void UnarySmiOpComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out().reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
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


LocationSummary* NumberNegateComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;  // Needed for doubles.
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_temp(0, Location::RegisterLocation(ECX));
  summary->set_out(Location::RegisterLocation(EAX));
  return summary;
}


void NumberNegateComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(!ic_data.IsNull());
  ASSERT(ic_data.num_args_tested() == 1);

  // TODO(srdjan): Implement for more checks.
  ASSERT(ic_data.NumberOfChecks() == 1);
  intptr_t test_class_id;
  Function& target = Function::Handle();
  ic_data.GetOneClassCheckAt(0, &test_class_id, &target);

  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();
  ASSERT(value == result);
  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptUnaryOp);
  if (test_class_id == kDoubleCid) {
    Register temp = locs()->temp(0).reg();
    __ testl(value, Immediate(kSmiTagMask));
    __ j(ZERO, deopt);  // Smi.
    __ CompareClassId(value, kDoubleCid, temp);
    __ j(NOT_EQUAL, deopt);
    // Allocate result object.
    const Class& double_class = compiler->double_class();
    const Code& stub =
        Code::Handle(StubCode::GetAllocationStubForClass(double_class));
    const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());
    __ pushl(value);
    compiler->GenerateCall(instance_call()->token_pos(),
                           instance_call()->try_index(),
                           &label,
                           PcDescriptors::kOther,
                           locs());
    // Result is in EAX.
    ASSERT(result != temp);
    __ movl(result, EAX);
    __ popl(temp);
    __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
    __ DoubleNegate(XMM0);
    __ movsd(FieldAddress(result, Double::value_offset()), XMM0);
  } else {
    UNREACHABLE();
  }
  ASSERT(ResultCid() == kDoubleCid);
}


LocationSummary* DoubleToDoubleComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(Location::SameAsFirstInput());
  return locs;
}


void DoubleToDoubleComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out().reg();

  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptDoubleToDouble);
  Register temp = locs()->temp(0).reg();
  __ testl(value, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);  // Deoptimize if Smi.
  __ CompareClassId(value, kDoubleCid, temp);
  __ j(NOT_EQUAL, deopt);  // Deoptimize if not Double.
  ASSERT(value == result);
}


LocationSummary* SmiToDoubleComp::MakeLocationSummary() const {
  return MakeCallSummary();  // Calls a stub to allocate result.
}


void SmiToDoubleComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out().reg();

  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptIntegerToDouble);

  const Class& double_class = compiler->double_class();
  const Code& stub =
    Code::Handle(StubCode::GetAllocationStubForClass(double_class));
  const ExternalLabel label(double_class.ToCString(), stub.EntryPoint());

  // TODO(vegorov): allocate box in the driver loop to avoid spilling.
  compiler->GenerateCall(instance_call()->token_pos(),
                         instance_call()->try_index(),
                         &label,
                         PcDescriptors::kOther,
                         locs());
  ASSERT(result == EAX);
  Register value = EBX;
  // Preserve argument on the stack until after the deoptimization point.
  __ movl(value, Address(ESP, 0));

  __ testl(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);  // Deoptimize if not Smi.
  __ SmiUntag(value);
  __ cvtsi2sd(XMM0, value);
  __ movsd(FieldAddress(result, Double::value_offset()), XMM0);
  __ Drop(1);
}


LocationSummary* PolymorphicInstanceCallComp::MakeLocationSummary() const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(instance_call()->deopt_id(),
                                        kDeoptPolymorphicInstanceCallTestFail);
  if (!HasICData() || (ic_data()->NumberOfChecks() == 0)) {
    __ jmp(deopt);
    return;
  }
  ASSERT(HasICData());
  ASSERT(ic_data()->num_args_tested() == 1);
  if (!with_checks()) {
    const Function& target = Function::ZoneHandle(ic_data()->GetTargetAt(0));
    compiler->GenerateStaticCall(instance_call()->deopt_id(),
                                 instance_call()->token_pos(),
                                 instance_call()->try_index(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs());
    return;
  }

  // Load receiver into EAX.
  __ movl(EAX,
      Address(ESP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  Label done;
  __ movl(EDI, Immediate(kSmiCid));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, &done);
  __ LoadClassId(EDI, EAX);
  __ Bind(&done);

  compiler->EmitTestAndCall(*ic_data(),
                            EDI,  // Class id register.
                            instance_call()->ArgumentCount(),
                            instance_call()->argument_names(),
                            deopt,
                            instance_call()->deopt_id(),
                            instance_call()->token_pos(),
                            instance_call()->try_index(),
                            locs());
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  computation()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


void CheckClassComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckClass);
  ASSERT(ic_data()->GetReceiverClassIdAt(0) != kSmiCid);
  __ testl(value, Immediate(kSmiTagMask));
  __ j(ZERO, deopt);
  __ LoadClassId(temp, value);
  Label is_ok;
  const intptr_t num_checks = ic_data()->NumberOfChecks();
  const bool use_near_jump = num_checks < 5;
  for (intptr_t i = 0; i < num_checks; i++) {
    __ cmpl(temp, Immediate(ic_data()->GetReceiverClassIdAt(i)));
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


LocationSummary* CheckSmiComp::MakeLocationSummary() const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary =
      new LocationSummary(kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        kDeoptCheckSmi);
  __ testl(value, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, deopt);
}


LocationSummary* CheckArrayBoundComp::MakeLocationSummary() const {
  return LocationSummary::Make(2,
                               Location::NoLocation(),
                               LocationSummary::kNoCall);
}


void CheckArrayBoundComp::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register receiver = locs()->in(0).reg();
  Register index = locs()->in(1).reg();

  const DeoptReasonId deopt_reason =
      (array_type() == kGrowableObjectArrayCid) ?
      kDeoptLoadIndexedGrowableArray : kDeoptLoadIndexedFixedArray;
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        deopt_reason);
  switch (array_type()) {
    case kArrayCid:
    case kImmutableArrayCid:
      __ cmpl(index, FieldAddress(receiver, Array::length_offset()));
      break;
    case kGrowableObjectArrayCid:
      __ cmpl(index,
              FieldAddress(receiver, GrowableObjectArray::length_offset()));
      break;
  }
  __ j(ABOVE_EQUAL, deopt);
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
