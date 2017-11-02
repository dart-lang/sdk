// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef DART_PRECOMPILED_RUNTIME
#include "vm/compiler/call_specializer.h"

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/cha.h"
#include "vm/cpu.h"

namespace dart {

// Quick access to the current isolate and zone.
#define I (isolate())
#define Z (zone())

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}

static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}

static bool CanConvertUnboxedMintToDouble() {
  return FlowGraphCompiler::CanConvertUnboxedMintToDouble();
}

static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}

static bool ClassIdIsOneOf(intptr_t class_id,
                           const GrowableArray<intptr_t>& class_ids) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    ASSERT(class_ids[i] != kIllegalCid);
    if (class_ids[i] == class_id) {
      return true;
    }
  }
  return false;
}

// Returns true if ICData tests two arguments and all ICData cids are in the
// required sets 'receiver_class_ids' or 'argument_class_ids', respectively.
static bool ICDataHasOnlyReceiverArgumentClassIds(
    const ICData& ic_data,
    const GrowableArray<intptr_t>& receiver_class_ids,
    const GrowableArray<intptr_t>& argument_class_ids) {
  if (ic_data.NumArgsTested() != 2) {
    return false;
  }
  const intptr_t len = ic_data.NumberOfChecks();
  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      ic_data.GetClassIdsAt(i, &class_ids);
      ASSERT(class_ids.length() == 2);
      if (!ClassIdIsOneOf(class_ids[0], receiver_class_ids) ||
          !ClassIdIsOneOf(class_ids[1], argument_class_ids)) {
        return false;
      }
    }
  }
  return true;
}

static bool ICDataHasReceiverArgumentClassIds(const ICData& ic_data,
                                              intptr_t receiver_class_id,
                                              intptr_t argument_class_id) {
  if (ic_data.NumArgsTested() != 2) {
    return false;
  }
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      GrowableArray<intptr_t> class_ids;
      ic_data.GetClassIdsAt(i, &class_ids);
      ASSERT(class_ids.length() == 2);
      if ((class_ids[0] == receiver_class_id) &&
          (class_ids[1] == argument_class_id)) {
        return true;
      }
    }
  }
  return false;
}

static bool HasOnlyOneSmi(const ICData& ic_data) {
  return (ic_data.NumberOfUsedChecks() == 1) &&
         ic_data.HasReceiverClassId(kSmiCid);
}

static bool HasOnlySmiOrMint(const ICData& ic_data) {
  if (ic_data.NumberOfUsedChecks() == 1) {
    return ic_data.HasReceiverClassId(kSmiCid) ||
           ic_data.HasReceiverClassId(kMintCid);
  }
  return (ic_data.NumberOfUsedChecks() == 2) &&
         ic_data.HasReceiverClassId(kSmiCid) &&
         ic_data.HasReceiverClassId(kMintCid);
}

bool CallSpecializer::HasOnlyTwoOf(const ICData& ic_data, intptr_t cid) {
  if (ic_data.NumberOfUsedChecks() != 1) {
    return false;
  }
  GrowableArray<intptr_t> first;
  GrowableArray<intptr_t> second;
  ic_data.GetUsedCidsForTwoArgs(&first, &second);
  return (first[0] == cid) && (second[0] == cid);
}

// Returns false if the ICData contains anything other than the 4 combinations
// of Mint and Smi for the receiver and argument classes.
static bool HasTwoMintOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> first;
  GrowableArray<intptr_t> second;
  ic_data.GetUsedCidsForTwoArgs(&first, &second);
  for (intptr_t i = 0; i < first.length(); i++) {
    if ((first[i] != kSmiCid) && (first[i] != kMintCid)) {
      return false;
    }
    if ((second[i] != kSmiCid) && (second[i] != kMintCid)) {
      return false;
    }
  }
  return true;
}

// Returns false if the ICData contains anything other than the 4 combinations
// of Double and Smi for the receiver and argument classes.
static bool HasTwoDoubleOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kDoubleCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}

static bool HasOnlyOneDouble(const ICData& ic_data) {
  return (ic_data.NumberOfUsedChecks() == 1) &&
         ic_data.HasReceiverClassId(kDoubleCid);
}

static bool ShouldSpecializeForDouble(const ICData& ic_data) {
  // Don't specialize for double if we can't unbox them.
  if (!CanUnboxDouble()) {
    return false;
  }

  // Unboxed double operation can't handle case of two smis.
  if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
    return false;
  }

  // Check that it have seen only smis and doubles.
  return HasTwoDoubleOrSmi(ic_data);
}

// Optimize instance calls using ICData.
void CallSpecializer::ApplyICData() {
  VisitBlocks();
}

// Optimize instance calls using cid.  This is called after optimizer
// converted instance calls to instructions. Any remaining
// instance calls are either megamorphic calls, cannot be optimized or
// have no runtime type feedback collected.
// Attempts to convert an instance call (IC call) using propagated class-ids,
// e.g., receiver class id, guarded-cid, or by guessing cid-s.
void CallSpecializer::ApplyClassIds() {
  ASSERT(current_iterator_ == NULL);
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    thread()->CheckForSafepoint();
    ForwardInstructionIterator it(block_it.Current());
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (call->HasICData()) {
          if (TryCreateICData(call)) {
            VisitInstanceCall(call);
          }
        }
      } else if (instr->IsPolymorphicInstanceCall()) {
        SpecializePolymorphicInstanceCall(instr->AsPolymorphicInstanceCall());
      }
    }
    current_iterator_ = NULL;
  }
}

bool CallSpecializer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  if (call->ic_data()->NumberOfUsedChecks() > 0) {
    // This occurs when an instance call has too many checks, will be converted
    // to megamorphic call.
    return false;
  }

  const intptr_t receiver_index = call->FirstArgIndex();
  GrowableArray<intptr_t> class_ids(call->ic_data()->NumArgsTested());
  ASSERT(call->ic_data()->NumArgsTested() <=
         call->ArgumentCountWithoutTypeArgs());
  for (intptr_t i = 0; i < call->ic_data()->NumArgsTested(); i++) {
    class_ids.Add(
        call->PushArgumentAt(receiver_index + i)->value()->Type()->ToCid());
  }

  const Token::Kind op_kind = call->token_kind();
  if (FLAG_guess_icdata_cid) {
    if (FLAG_precompiled_mode) {
      // In precompiler speculate that both sides of bitwise operation
      // are Smi-s.
      if (Token::IsBinaryBitwiseOperator(op_kind)) {
        class_ids[0] = kSmiCid;
        class_ids[1] = kSmiCid;
      }
    }

    if (Token::IsRelationalOperator(op_kind) ||
        Token::IsEqualityOperator(op_kind) ||
        Token::IsBinaryOperator(op_kind)) {
      // Guess cid: if one of the inputs is a number assume that the other
      // is a number of same type.
      const intptr_t cid_0 = class_ids[0];
      const intptr_t cid_1 = class_ids[1];
      if ((cid_0 == kDynamicCid) && (IsNumberCid(cid_1))) {
        class_ids[0] = cid_1;
      } else if (IsNumberCid(cid_0) && (cid_1 == kDynamicCid)) {
        class_ids[1] = cid_0;
      }
    }
  }

  bool all_cids_known = true;
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    if (class_ids[i] == kDynamicCid) {
      // Not all cid-s known.
      all_cids_known = false;
      break;
    }
  }

  if (all_cids_known) {
    const Class& receiver_class =
        Class::Handle(Z, isolate()->class_table()->At(class_ids[0]));
    if (!receiver_class.is_finalized()) {
      // Do not eagerly finalize classes. ResolveDynamicForReceiverClass can
      // cause class finalization, since callee's receiver class may not be
      // finalized yet.
      return false;
    }
    const Function& function = Function::Handle(
        Z, call->ResolveForReceiverClass(receiver_class, /*allow_add=*/false));
    if (function.IsNull()) {
      return false;
    }

    // Create new ICData, do not modify the one attached to the instruction
    // since it is attached to the assembly instruction itself.
    const ICData& ic_data = ICData::ZoneHandle(
        Z, ICData::NewFrom(*call->ic_data(), class_ids.length()));
    if (class_ids.length() > 1) {
      ic_data.AddCheck(class_ids, function);
    } else {
      ASSERT(class_ids.length() == 1);
      ic_data.AddReceiverCheck(class_ids[0], function);
    }
    call->set_ic_data(&ic_data);
    return true;
  }

  return false;
}

void CallSpecializer::SpecializePolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  if (!FLAG_polymorphic_with_deopt) {
    // Specialization adds receiver checks which can lead to deoptimization.
    return;
  }

  const intptr_t receiver_cid =
      call->PushArgumentAt(0)->value()->Type()->ToCid();
  if (receiver_cid == kDynamicCid) {
    return;  // No information about receiver was infered.
  }

  const ICData& ic_data = *call->instance_call()->ic_data();

  const CallTargets* targets =
      FlowGraphCompiler::ResolveCallTargetsForReceiverCid(
          receiver_cid, String::Handle(zone(), ic_data.target_name()),
          Array::Handle(zone(), ic_data.arguments_descriptor()));
  if (targets == NULL) {
    // No specialization.
    return;
  }

  ASSERT(targets->HasSingleTarget());
  const Function& target = targets->FirstTarget();
  StaticCallInstr* specialized = StaticCallInstr::FromCall(Z, call, target);
  call->ReplaceWith(specialized, current_iterator());
}

void CallSpecializer::ReplaceCall(Definition* call, Definition* replacement) {
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  call->ReplaceWith(replacement, current_iterator());
}

void CallSpecializer::AddCheckSmi(Definition* to_check,
                                  intptr_t deopt_id,
                                  Environment* deopt_environment,
                                  Instruction* insert_before) {
  // TODO(alexmarkov): check reaching type instead of definition type
  if (to_check->Type()->ToCid() != kSmiCid) {
    InsertBefore(insert_before,
                 new (Z) CheckSmiInstr(new (Z) Value(to_check), deopt_id,
                                       insert_before->token_pos()),
                 deopt_environment, FlowGraph::kEffect);
  }
}

void CallSpecializer::AddCheckClass(Definition* to_check,
                                    const Cids& cids,
                                    intptr_t deopt_id,
                                    Environment* deopt_environment,
                                    Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = flow_graph_->CreateCheckClass(
      to_check, cids, deopt_id, insert_before->token_pos());
  InsertBefore(insert_before, check, deopt_environment, FlowGraph::kEffect);
}

void CallSpecializer::AddChecksForArgNr(InstanceCallInstr* call,
                                        Definition* instr,
                                        int argument_number) {
  const Cids* cids = Cids::Create(Z, *call->ic_data(), argument_number);
  AddCheckClass(instr, *cids, call->deopt_id(), call->env(), call);
}

void CallSpecializer::AddCheckNull(Value* to_check,
                                   intptr_t deopt_id,
                                   Environment* deopt_environment,
                                   Instruction* insert_before) {
  ASSERT(FLAG_experimental_strong_mode);
  if (to_check->Type()->is_nullable()) {
    CheckNullInstr* check_null = new (Z) CheckNullInstr(
        to_check->CopyWithType(Z), deopt_id, insert_before->token_pos());
    if (FLAG_trace_experimental_strong_mode) {
      THR_Print("[Strong mode] Inserted %s\n", check_null->ToCString());
    }
    InsertBefore(insert_before, check_null, deopt_environment,
                 FlowGraph::kEffect);
  }
}

static bool ArgIsAlways(intptr_t cid,
                        const ICData& ic_data,
                        intptr_t arg_number) {
  ASSERT(ic_data.NumArgsTested() > arg_number);
  if (ic_data.NumberOfUsedChecks() == 0) {
    return false;
  }
  const intptr_t num_checks = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < num_checks; i++) {
    if (ic_data.IsUsedAt(i) && ic_data.GetClassIdAt(i, arg_number) != cid) {
      return false;
    }
  }
  return true;
}

bool CallSpecializer::TryReplaceWithIndexedOp(InstanceCallInstr* call,
                                              const ICData* unary_checks) {
  // Check for monomorphic IC data.
  if (!unary_checks->NumberOfChecksIs(1)) {
    return false;
  }
  return FlowGraphInliner::TryReplaceInstanceCallWithInline(
      flow_graph_, current_iterator(), call, speculative_policy_);
}

// Return true if d is a string of length one (a constant or result from
// from string-from-char-code instruction.
static bool IsLengthOneString(Definition* d) {
  if (d->IsConstant()) {
    const Object& obj = d->AsConstant()->value();
    if (obj.IsString()) {
      return String::Cast(obj).Length() == 1;
    } else {
      return false;
    }
  } else {
    return d->IsOneByteStringFromCharCode();
  }
}

// Returns true if the string comparison was converted into char-code
// comparison. Conversion is only possible for strings of length one.
// E.g., detect str[x] == "x"; and use an integer comparison of char-codes.
bool CallSpecializer::TryStringLengthOneEquality(InstanceCallInstr* call,
                                                 Token::Kind op_kind) {
  ASSERT(HasOnlyTwoOf(*call->ic_data(), kOneByteStringCid));
  // Check that left and right are length one strings (either string constants
  // or results of string-from-char-code.
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  Value* left_val = NULL;
  Definition* to_remove_left = NULL;
  if (IsLengthOneString(right)) {
    // Swap, since we know that both arguments are strings
    Definition* temp = left;
    left = right;
    right = temp;
  }
  if (IsLengthOneString(left)) {
    // Optimize if left is a string with length one (either constant or
    // result of string-from-char-code.
    if (left->IsConstant()) {
      ConstantInstr* left_const = left->AsConstant();
      const String& str = String::Cast(left_const->value());
      ASSERT(str.Length() == 1);
      ConstantInstr* char_code_left = flow_graph()->GetConstant(
          Smi::ZoneHandle(Z, Smi::New(static_cast<intptr_t>(str.CharAt(0)))));
      left_val = new (Z) Value(char_code_left);
    } else if (left->IsOneByteStringFromCharCode()) {
      // Use input of string-from-charcode as left value.
      OneByteStringFromCharCodeInstr* instr =
          left->AsOneByteStringFromCharCode();
      left_val = new (Z) Value(instr->char_code()->definition());
      to_remove_left = instr;
    } else {
      // IsLengthOneString(left) should have been false.
      UNREACHABLE();
    }

    Definition* to_remove_right = NULL;
    Value* right_val = NULL;
    if (right->IsOneByteStringFromCharCode()) {
      // Skip string-from-char-code, and use its input as right value.
      OneByteStringFromCharCodeInstr* right_instr =
          right->AsOneByteStringFromCharCode();
      right_val = new (Z) Value(right_instr->char_code()->definition());
      to_remove_right = right_instr;
    } else {
      AddChecksForArgNr(call, right, /* arg_number = */ 1);
      // String-to-char-code instructions returns -1 (illegal charcode) if
      // string is not of length one.
      StringToCharCodeInstr* char_code_right = new (Z)
          StringToCharCodeInstr(new (Z) Value(right), kOneByteStringCid);
      InsertBefore(call, char_code_right, call->env(), FlowGraph::kValue);
      right_val = new (Z) Value(char_code_right);
    }

    // Comparing char-codes instead of strings.
    EqualityCompareInstr* comp =
        new (Z) EqualityCompareInstr(call->token_pos(), op_kind, left_val,
                                     right_val, kSmiCid, call->deopt_id());
    ReplaceCall(call, comp);

    // Remove dead instructions.
    if ((to_remove_left != NULL) &&
        (to_remove_left->input_use_list() == NULL)) {
      to_remove_left->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_left->RemoveFromGraph();
    }
    if ((to_remove_right != NULL) &&
        (to_remove_right->input_use_list() == NULL)) {
      to_remove_right->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_right->RemoveFromGraph();
    }
    return true;
  }
  return false;
}

static bool SmiFitsInDouble() {
  return kSmiBits < 53;
}

bool CallSpecializer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* const left = call->ArgumentAt(0);
  Definition* const right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
  if (HasOnlyTwoOf(ic_data, kOneByteStringCid)) {
    return TryStringLengthOneEquality(call, op_kind);
  } else if (HasOnlyTwoOf(ic_data, kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(left), call->deopt_id(),
                                       call->token_pos()),
                 call->env(), FlowGraph::kEffect);
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(right), call->deopt_id(),
                                       call->token_pos()),
                 call->env(), FlowGraph::kEffect);
    cid = kSmiCid;
  } else if (HasTwoMintOrSmi(ic_data) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    cid = kMintCid;
  } else if (HasTwoDoubleOrSmi(ic_data) && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
      if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(
            call,
            new (Z) CheckEitherNonSmiInstr(
                new (Z) Value(left), new (Z) Value(right), call->deopt_id()),
            call->env(), FlowGraph::kEffect);
        cid = kDoubleCid;
      }
    }
  } else {
    // Check if ICDData contains checks with Smi/Null combinations. In that case
    // we can still emit the optimized Smi equality operation but need to add
    // checks for null or Smi.
    GrowableArray<intptr_t> smi_or_null(2);
    smi_or_null.Add(kSmiCid);
    smi_or_null.Add(kNullCid);
    if (ICDataHasOnlyReceiverArgumentClassIds(ic_data, smi_or_null,
                                              smi_or_null)) {
      AddChecksForArgNr(call, left, /* arg_number = */ 0);
      AddChecksForArgNr(call, right, /* arg_number = */ 1);

      cid = kSmiCid;
    } else {
      // Shortcut for equality with null.
      // TODO(vegorov): this optimization is not speculative and should
      // be hoisted out of this function.
      ConstantInstr* right_const = right->AsConstant();
      ConstantInstr* left_const = left->AsConstant();
      if ((right_const != NULL && right_const->value().IsNull()) ||
          (left_const != NULL && left_const->value().IsNull())) {
        StrictCompareInstr* comp = new (Z)
            StrictCompareInstr(call->token_pos(), Token::kEQ_STRICT,
                               new (Z) Value(left), new (Z) Value(right),
                               /* number_check = */ false, Thread::kNoDeoptId);
        ReplaceCall(call, comp);
        return true;
      }
      return false;
    }
  }
  ASSERT(cid != kIllegalCid);
  EqualityCompareInstr* comp = new (Z)
      EqualityCompareInstr(call->token_pos(), op_kind, new (Z) Value(left),
                           new (Z) Value(right), cid, call->deopt_id());
  ReplaceCall(call, comp);
  return true;
}

bool CallSpecializer::TryReplaceWithRelationalOp(InstanceCallInstr* call,
                                                 Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
  if (HasOnlyTwoOf(ic_data, kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(left), call->deopt_id(),
                                       call->token_pos()),
                 call->env(), FlowGraph::kEffect);
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(right), call->deopt_id(),
                                       call->token_pos()),
                 call->env(), FlowGraph::kEffect);
    cid = kSmiCid;
  } else if (HasTwoMintOrSmi(ic_data) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    cid = kMintCid;
  } else if (HasTwoDoubleOrSmi(ic_data) && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
      if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(
            call,
            new (Z) CheckEitherNonSmiInstr(
                new (Z) Value(left), new (Z) Value(right), call->deopt_id()),
            call->env(), FlowGraph::kEffect);
        cid = kDoubleCid;
      }
    }
  } else {
    return false;
  }
  ASSERT(cid != kIllegalCid);
  RelationalOpInstr* comp =
      new (Z) RelationalOpInstr(call->token_pos(), op_kind, new (Z) Value(left),
                                new (Z) Value(right), cid, call->deopt_id());
  ReplaceCall(call, comp);
  return true;
}

bool CallSpecializer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
                                             Token::Kind op_kind) {
  intptr_t operands_type = kIllegalCid;
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        operands_type = ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)
                            ? kMintCid
                            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 FlowGraphCompiler::SupportsUnboxedMints()) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryInt64Op)) return false;
        operands_type = kMintCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoOf(ic_data, kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kInt32x4Cid)) {
        ASSERT(op_kind != Token::kMUL);  // Int32x4 doesn't have a multiply op.
        operands_type = kInt32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
      if (ShouldSpecializeForDouble(ic_data) ||
          HasOnlyTwoOf(ic_data, kSmiCid)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoOf(ic_data, kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        operands_type = kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data)) {
        operands_type = kMintCid;
      } else if (HasOnlyTwoOf(ic_data, kInt32x4Cid)) {
        operands_type = kInt32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kSHR:
    case Token::kSHL:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        // Left shift may overflow from smi into mint or big ints.
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryInt64Op)) {
          return false;
        }
        operands_type = ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)
                            ? kMintCid
                            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 HasOnlyOneSmi(ICData::Handle(
                     Z, ic_data.AsUnaryClassChecksForArgNr(1)))) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryInt64Op)) {
          return false;
        }
        // Check for smi/mint << smi or smi/mint >> smi.
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kMOD:
    case Token::kTRUNCDIV:
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        if (ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)) {
          return false;
        }
        operands_type = kSmiCid;
      } else {
        return false;
      }
      break;
    default:
      UNREACHABLE();
  }

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  if (operands_type == kDoubleCid) {
    if (!CanUnboxDouble()) {
      return false;
    }
    // Check that either left or right are not a smi.  Result of a
    // binary operation with two smis is a smi not a double, except '/' which
    // returns a double for two smis.
    if (op_kind != Token::kDIV) {
      InsertBefore(
          call,
          new (Z) CheckEitherNonSmiInstr(
              new (Z) Value(left), new (Z) Value(right), call->deopt_id()),
          call->env(), FlowGraph::kEffect);
    }

    BinaryDoubleOpInstr* double_bin_op = new (Z)
        BinaryDoubleOpInstr(op_kind, new (Z) Value(left), new (Z) Value(right),
                            call->deopt_id(), call->token_pos());
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    if (!FlowGraphCompiler::SupportsUnboxedMints()) return false;
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      ShiftInt64OpInstr* shift_op = new (Z) ShiftInt64OpInstr(
          op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      ReplaceCall(call, shift_op);
    } else {
      BinaryInt64OpInstr* bin_op = new (Z) BinaryInt64OpInstr(
          op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      ReplaceCall(call, bin_op);
    }
  } else if ((operands_type == kFloat32x4Cid) ||
             (operands_type == kInt32x4Cid) ||
             (operands_type == kFloat64x2Cid)) {
    return InlineSimdBinaryOp(call, operands_type, op_kind);
  } else if (op_kind == Token::kMOD) {
    ASSERT(operands_type == kSmiCid);
    if (right->IsConstant()) {
      const Object& obj = right->AsConstant()->value();
      if (obj.IsSmi() && Utils::IsPowerOfTwo(Smi::Cast(obj).Value())) {
        // Insert smi check and attach a copy of the original environment
        // because the smi operation can still deoptimize.
        InsertBefore(call,
                     new (Z) CheckSmiInstr(new (Z) Value(left),
                                           call->deopt_id(), call->token_pos()),
                     call->env(), FlowGraph::kEffect);
        ConstantInstr* constant = flow_graph()->GetConstant(
            Smi::Handle(Z, Smi::New(Smi::Cast(obj).Value() - 1)));
        BinarySmiOpInstr* bin_op =
            new (Z) BinarySmiOpInstr(Token::kBIT_AND, new (Z) Value(left),
                                     new (Z) Value(constant), call->deopt_id());
        ReplaceCall(call, bin_op);
        return true;
      }
    }
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    BinarySmiOpInstr* bin_op = new (Z) BinarySmiOpInstr(
        op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
    ReplaceCall(call, bin_op);
  } else {
    ASSERT(operands_type == kSmiCid);
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    if (left->IsConstant() &&
        ((op_kind == Token::kADD) || (op_kind == Token::kMUL))) {
      // Constant should be on the right side.
      Definition* temp = left;
      left = right;
      right = temp;
    }
    BinarySmiOpInstr* bin_op = new (Z) BinarySmiOpInstr(
        op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
    ReplaceCall(call, bin_op);
  }
  return true;
}

bool CallSpecializer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
                                            Token::Kind op_kind) {
  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 1);
  Definition* input = call->ArgumentAt(0);
  Definition* unary_op = NULL;
  if (HasOnlyOneSmi(*call->ic_data())) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(input), call->deopt_id(),
                                       call->token_pos()),
                 call->env(), FlowGraph::kEffect);
    unary_op = new (Z)
        UnarySmiOpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if ((op_kind == Token::kBIT_NOT) &&
             HasOnlySmiOrMint(*call->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    unary_op = new (Z)
        UnaryInt64OpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if (HasOnlyOneDouble(*call->ic_data()) &&
             (op_kind == Token::kNEGATE) && CanUnboxDouble()) {
    AddReceiverCheck(call);
    unary_op = new (Z) UnaryDoubleOpInstr(Token::kNEGATE, new (Z) Value(input),
                                          call->deopt_id());
  } else {
    return false;
  }
  ASSERT(unary_op != NULL);
  ReplaceCall(call, unary_op);
  return true;
}

// Lookup field with the given name in the given class.
RawField* CallSpecializer::GetField(intptr_t class_id,
                                    const String& field_name) {
  Class& cls = Class::Handle(Z, isolate()->class_table()->At(class_id));
  Field& field = Field::Handle(Z);
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      return should_clone_fields_ ? field.CloneFromOriginal() : field.raw();
    }
    cls = cls.SuperClass();
  }
  return Field::null();
}

bool CallSpecializer::TryInlineImplicitInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.HasOneTarget());
  GrowableArray<intptr_t> class_ids;
  ic_data.GetClassIdsAt(0, &class_ids);
  ASSERT(class_ids.length() == 1);
  // Inline implicit instance getter.
  const String& field_name =
      String::Handle(Z, Field::NameFromGetter(call->function_name()));
  const Field& field = Field::ZoneHandle(Z, GetField(class_ids[0], field_name));
  ASSERT(!field.IsNull());

  if (flow_graph()->InstanceCallNeedsClassCheck(call,
                                                RawFunction::kImplicitGetter)) {
    if (FLAG_precompiled_mode) {
      return false;
    }

    AddReceiverCheck(call);
  }
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      new (Z) Value(call->ArgumentAt(0)), &field,
      AbstractType::ZoneHandle(Z, field.type()), call->token_pos(),
      FLAG_use_field_guards ? &flow_graph()->parsed_function() : NULL);
  load->set_is_immutable(field.is_final());

  // Discard the environment from the original instruction because the load
  // can't deoptimize.
  call->RemoveEnvironment();
  ReplaceCall(call, load);

  if (load->result_cid() != kDynamicCid) {
    // Reset value types if guarded_cid was used.
    for (Value::Iterator it(load->input_use_list()); !it.Done(); it.Advance()) {
      it.Current()->SetReachingType(NULL);
    }
  }
  return true;
}

bool CallSpecializer::TryInlineInstanceSetter(InstanceCallInstr* instr,
                                              const ICData& unary_ic_data) {
  ASSERT(!unary_ic_data.NumberOfChecksIs(0) &&
         (unary_ic_data.NumArgsTested() == 1));
  if (I->type_checks()) {
    // Checked mode setters are inlined like normal methods by conventional
    // inlining.
    return false;
  }

  ASSERT(instr->HasICData());
  if (unary_ic_data.NumberOfChecksIs(0)) {
    // No type feedback collected.
    return false;
  }
  if (!unary_ic_data.HasOneTarget()) {
    // Polymorphic sites are inlined like normal method calls by conventional
    // inlining.
    return false;
  }
  Function& target = Function::Handle(Z);
  intptr_t class_id;
  unary_ic_data.GetOneClassCheckAt(0, &class_id, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Non-implicit setter are inlined like normal method calls.
    return false;
  }
  // Inline implicit instance setter.
  const String& field_name =
      String::Handle(Z, Field::NameFromSetter(instr->function_name()));
  const Field& field = Field::ZoneHandle(Z, GetField(class_id, field_name));
  ASSERT(!field.IsNull());

  if (flow_graph()->InstanceCallNeedsClassCheck(instr,
                                                RawFunction::kImplicitSetter)) {
    if (FLAG_precompiled_mode) {
      return false;
    }

    AddReceiverCheck(instr);
  }

  if (FLAG_use_field_guards) {
    if (field.guarded_cid() != kDynamicCid) {
      ASSERT(I->use_field_guards());
      InsertBefore(instr,
                   new (Z)
                       GuardFieldClassInstr(new (Z) Value(instr->ArgumentAt(1)),
                                            field, instr->deopt_id()),
                   instr->env(), FlowGraph::kEffect);
    }

    if (field.needs_length_check()) {
      ASSERT(I->use_field_guards());
      InsertBefore(
          instr,
          new (Z) GuardFieldLengthInstr(new (Z) Value(instr->ArgumentAt(1)),
                                        field, instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }
  }

  // Field guard was detached.
  ASSERT(instr->FirstArgIndex() == 0);
  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(field, new (Z) Value(instr->ArgumentAt(0)),
                              new (Z) Value(instr->ArgumentAt(1)),
                              kEmitStoreBarrier, instr->token_pos());

  ASSERT(FLAG_use_field_guards || !store->IsUnboxedStore());
  if (FLAG_use_field_guards && store->IsUnboxedStore()) {
    flow_graph()->parsed_function().AddToGuardedFields(&field);
  }

  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCall(instr, store);
  return true;
}

bool CallSpecializer::InlineSimdBinaryOp(InstanceCallInstr* call,
                                         intptr_t cid,
                                         Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* const left = call->ArgumentAt(0);
  Definition* const right = call->ArgumentAt(1);
  // Type check left and right.
  AddChecksForArgNr(call, left, /* arg_number = */ 0);
  AddChecksForArgNr(call, right, /* arg_number = */ 1);
  // Replace call.
  SimdOpInstr* op = SimdOpInstr::Create(
      SimdOpInstr::KindForOperator(cid, op_kind), new (Z) Value(left),
      new (Z) Value(right), call->deopt_id());
  ReplaceCall(call, op);

  return true;
}

// Only unique implicit instance getters can be currently handled.
bool CallSpecializer::TryInlineInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfUsedChecks() == 0) {
    // No type feedback collected.
    return false;
  }

  if (!ic_data.HasOneTarget()) {
    // Polymorphic sites are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }

  const Function& target = Function::Handle(Z, ic_data.GetTargetAt(0));
  if (target.kind() != RawFunction::kImplicitGetter) {
    // Non-implicit getters are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }
  return TryInlineImplicitInstanceGetter(call);
}

void CallSpecializer::ReplaceWithMathCFunction(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  ASSERT(call->type_args_len() == 0);
  AddReceiverCheck(call);
  ZoneGrowableArray<Value*>* args =
      new (Z) ZoneGrowableArray<Value*>(call->ArgumentCount());
  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    args->Add(new (Z) Value(call->ArgumentAt(i)));
  }
  InvokeMathCFunctionInstr* invoke = new (Z) InvokeMathCFunctionInstr(
      args, call->deopt_id(), recognized_kind, call->token_pos());
  ReplaceCall(call, invoke);
}

// Inline only simple, frequently called core library methods.
bool CallSpecializer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfUsedChecks() != 1) {
    // No type feedback collected or multiple receivers/targets found.
    return false;
  }

  Function& target = Function::Handle(Z);
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  if (CanUnboxDouble() &&
      (recognized_kind == MethodRecognizer::kIntegerToDouble)) {
    if (class_ids[0] == kSmiCid) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new (Z) SmiToDoubleInstr(new (Z) Value(call->ArgumentAt(0)),
                                           call->token_pos()));
      return true;
    } else if ((class_ids[0] == kMintCid) && CanConvertUnboxedMintToDouble()) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new (Z) MintToDoubleInstr(new (Z) Value(call->ArgumentAt(0)),
                                            call->deopt_id()));
      return true;
    }
  }

  if (class_ids[0] == kDoubleCid) {
    if (!CanUnboxDouble()) {
      return false;
    }
    switch (recognized_kind) {
      case MethodRecognizer::kDoubleToInteger: {
        AddReceiverCheck(call);
        ASSERT(call->HasICData());
        const ICData& ic_data = *call->ic_data();
        Definition* input = call->ArgumentAt(0);
        Definition* d2i_instr = NULL;
        if (ic_data.HasDeoptReason(ICData::kDeoptDoubleToSmi)) {
          // Do not repeatedly deoptimize because result didn't fit into Smi.
          d2i_instr = new (Z) DoubleToIntegerInstr(new (Z) Value(input), call);
        } else {
          // Optimistically assume result fits into Smi.
          d2i_instr =
              new (Z) DoubleToSmiInstr(new (Z) Value(input), call->deopt_id());
        }
        ReplaceCall(call, d2i_instr);
        return true;
      }
      case MethodRecognizer::kDoubleMod:
      case MethodRecognizer::kDoubleRound:
        ReplaceWithMathCFunction(call, recognized_kind);
        return true;
      case MethodRecognizer::kDoubleTruncate:
      case MethodRecognizer::kDoubleFloor:
      case MethodRecognizer::kDoubleCeil:
        if (!TargetCPUFeatures::double_truncate_round_supported()) {
          ReplaceWithMathCFunction(call, recognized_kind);
        } else {
          AddReceiverCheck(call);
          DoubleToDoubleInstr* d2d_instr =
              new (Z) DoubleToDoubleInstr(new (Z) Value(call->ArgumentAt(0)),
                                          recognized_kind, call->deopt_id());
          ReplaceCall(call, d2d_instr);
        }
        return true;
      default:
        break;
    }
  }

  return FlowGraphInliner::TryReplaceInstanceCallWithInline(
      flow_graph_, current_iterator(), call, speculative_policy_);
}

// If type tests specified by 'ic_data' do not depend on type arguments,
// return mapping cid->result in 'results' (i : cid; i + 1: result).
// If all tests yield the same result, return it otherwise return Bool::null.
// If no mapping is possible, 'results' has less than
// (ic_data.NumberOfChecks() * 2) entries
// An instance-of test returning all same results can be converted to a class
// check.
RawBool* CallSpecializer::InstanceOfAsBool(
    const ICData& ic_data,
    const AbstractType& type,
    ZoneGrowableArray<intptr_t>* results) const {
  ASSERT(results->is_empty());
  ASSERT(ic_data.NumArgsTested() == 1);  // Unary checks only.
  if (type.IsFunctionType() || type.IsDartFunctionType() ||
      !type.IsInstantiated() || type.IsMalformedOrMalbounded()) {
    return Bool::null();
  }
  const Class& type_class = Class::Handle(Z, type.type_class());
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const intptr_t num_type_params = type_class.NumTypeParameters();
    const intptr_t from_index = num_type_args - num_type_params;
    const TypeArguments& type_arguments =
        TypeArguments::Handle(Z, type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
                             type_arguments.IsRaw(from_index, num_type_params);
    if (!is_raw_type) {
      // Unknown result.
      return Bool::null();
    }
  }

  const ClassTable& class_table = *isolate()->class_table();
  Bool& prev = Bool::Handle(Z);
  Class& cls = Class::Handle(Z);

  bool results_differ = false;
  const intptr_t number_of_checks = ic_data.NumberOfChecks();
  for (int i = 0; i < number_of_checks; i++) {
    cls = class_table.At(ic_data.GetReceiverClassIdAt(i));
    if (cls.NumTypeArguments() > 0) {
      return Bool::null();
    }
    // As of Dart 1.5, the Null type is a subtype of (and is more specific than)
    // any type. However, we are checking instances here and not types. The
    // null instance is only an instance of Null, Object, and dynamic.
    const bool is_subtype =
        cls.IsNullClass()
            ? (type_class.IsNullClass() || type_class.IsObjectClass() ||
               type_class.IsDynamicClass())
            : cls.IsSubtypeOf(Object::null_type_arguments(), type_class,
                              Object::null_type_arguments(), NULL, NULL,
                              Heap::kOld);
    results->Add(cls.id());
    results->Add(is_subtype);
    if (prev.IsNull()) {
      prev = Bool::Get(is_subtype).raw();
    } else {
      if (is_subtype != prev.value()) {
        results_differ = true;
      }
    }
  }
  return results_differ ? Bool::null() : prev.raw();
}

// Returns true if checking against this type is a direct class id comparison.
bool CallSpecializer::TypeCheckAsClassEquality(const AbstractType& type) {
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  // Requires CHA.
  if (!type.IsInstantiated()) return false;
  // Function types have different type checking rules.
  if (type.IsFunctionType()) return false;
  const Class& type_class = Class::Handle(type.type_class());
  // Could be an interface check?
  if (CHA::IsImplemented(type_class)) return false;
  // Check if there are subclasses.
  if (CHA::HasSubclasses(type_class)) {
    return false;
  }

  // Private classes cannot be subclassed by later loaded libs.
  if (!type_class.IsPrivate()) {
    // In AOT mode we can't use CHA deoptimizations.
    ASSERT(!FLAG_precompiled_mode || !FLAG_use_cha_deopt);
    if (FLAG_use_cha_deopt || isolate()->all_classes_finalized()) {
      if (FLAG_trace_cha) {
        THR_Print(
            "  **(CHA) Typecheck as class equality since no "
            "subclasses: %s\n",
            type_class.ToCString());
      }
      if (FLAG_use_cha_deopt) {
        thread()->cha()->AddToGuardedClasses(type_class, /*subclass_count=*/0);
      }
    } else {
      return false;
    }
  }
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const intptr_t num_type_params = type_class.NumTypeParameters();
    const intptr_t from_index = num_type_args - num_type_params;
    const TypeArguments& type_arguments =
        TypeArguments::Handle(type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
                             type_arguments.IsRaw(from_index, num_type_params);
    return is_raw_type;
  }
  return true;
}

bool CallSpecializer::TryReplaceInstanceOfWithRangeCheck(
    InstanceCallInstr* call,
    const AbstractType& type) {
  // TODO(dartbug.com/30632) does this optimization make sense in JIT?
  return false;
}

bool CallSpecializer::TryOptimizeInstanceOfUsingStaticTypes(
    InstanceCallInstr* call,
    const AbstractType& type) {
  ASSERT(FLAG_experimental_strong_mode);
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));

  if (type.IsDynamicType() || type.IsObjectType() || !type.IsInstantiated()) {
    return false;
  }

  const intptr_t receiver_index = call->FirstArgIndex();
  Value* left_value = call->PushArgumentAt(receiver_index)->value();

  if (left_value->Type()->IsMoreSpecificThan(type)) {
    Definition* replacement = new (Z) StrictCompareInstr(
        call->token_pos(),
        type.IsNullType() ? Token::kEQ_STRICT : Token::kNE_STRICT,
        left_value->CopyWithType(Z),
        new (Z) Value(flow_graph()->constant_null()),
        /* number_check = */ false, Thread::kNoDeoptId);
    if (FLAG_trace_experimental_strong_mode) {
      THR_Print("[Strong mode] replacing %s with %s (%s < %s)\n",
                call->ToCString(), replacement->ToCString(),
                left_value->Type()->ToAbstractType()->ToCString(),
                type.ToCString());
    }
    ReplaceCall(call, replacement);
    return true;
  }

  return false;
}

void CallSpecializer::ReplaceWithInstanceOf(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator_type_args = NULL;
  Definition* function_type_args = NULL;
  AbstractType& type = AbstractType::ZoneHandle(Z);
  ASSERT(call->type_args_len() == 0);
  if (call->ArgumentCount() == 2) {
    instantiator_type_args = flow_graph()->constant_null();
    function_type_args = flow_graph()->constant_null();
    ASSERT(call->MatchesCoreName(Symbols::_simpleInstanceOf()));
    type = AbstractType::Cast(call->ArgumentAt(1)->AsConstant()->value()).raw();
  } else {
    instantiator_type_args = call->ArgumentAt(1);
    function_type_args = call->ArgumentAt(2);
    type = AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value()).raw();
  }

  if (FLAG_experimental_strong_mode &&
      TryOptimizeInstanceOfUsingStaticTypes(call, type)) {
    return;
  }

  if (TypeCheckAsClassEquality(type)) {
    LoadClassIdInstr* left_cid = new (Z) LoadClassIdInstr(new (Z) Value(left));
    InsertBefore(call, left_cid, NULL, FlowGraph::kValue);
    const intptr_t type_cid = Class::Handle(Z, type.type_class()).id();
    ConstantInstr* cid =
        flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(type_cid)));

    StrictCompareInstr* check_cid = new (Z) StrictCompareInstr(
        call->token_pos(), Token::kEQ_STRICT, new (Z) Value(left_cid),
        new (Z) Value(cid), /* number_check = */ false, Thread::kNoDeoptId);
    ReplaceCall(call, check_cid);
    return;
  }

  if (TryReplaceInstanceOfWithRangeCheck(call, type)) {
    return;
  }

  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  const intptr_t number_of_checks = unary_checks.NumberOfChecks();
  if (number_of_checks > 0 && number_of_checks <= FLAG_max_polymorphic_checks) {
    ZoneGrowableArray<intptr_t>* results =
        new (Z) ZoneGrowableArray<intptr_t>(number_of_checks * 2);
    const Bool& as_bool =
        Bool::ZoneHandle(Z, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.IsNull() || FLAG_precompiled_mode) {
      if (results->length() == number_of_checks * 2) {
        const bool can_deopt = SpecializeTestCidsForNumericTypes(results, type);
        if (can_deopt &&
            !speculative_policy_->IsAllowedForInlining(call->deopt_id())) {
          // Guard against repeated speculative inlining.
          return;
        }
        TestCidsInstr* test_cids = new (Z) TestCidsInstr(
            call->token_pos(), Token::kIS, new (Z) Value(left), *results,
            can_deopt ? call->deopt_id() : Thread::kNoDeoptId);
        // Remove type.
        ReplaceCall(call, test_cids);
        return;
      }
    } else {
      // One result only.
      AddReceiverCheck(call);
      ConstantInstr* bool_const = flow_graph()->GetConstant(as_bool);
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->PushArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
      call->ReplaceUsesWith(bool_const);
      ASSERT(current_iterator()->Current() == call);
      current_iterator()->RemoveCurrentFromGraph();
      return;
    }
  }

  InstanceOfInstr* instance_of = new (Z) InstanceOfInstr(
      call->token_pos(), new (Z) Value(left),
      new (Z) Value(instantiator_type_args), new (Z) Value(function_type_args),
      type, call->deopt_id());
  ReplaceCall(call, instance_of);
}

bool CallSpecializer::TryReplaceTypeCastWithRangeCheck(
    InstanceCallInstr* call,
    const AbstractType& type) {
  // TODO(dartbug.com/30632) does this optimization make sense in JIT?
  return false;
}

void CallSpecializer::ReplaceWithTypeCast(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeCastOperator(call->token_kind()));
  ASSERT(call->type_args_len() == 0);
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator_type_args = call->ArgumentAt(1);
  Definition* function_type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  ASSERT(!type.IsMalformedOrMalbounded());

  // TODO(dartbug.com/30632) does this optimization make sense in JIT?
  if (FLAG_precompiled_mode && TypeCheckAsClassEquality(type)) {
    LoadClassIdInstr* left_cid = new (Z) LoadClassIdInstr(new (Z) Value(left));
    InsertBefore(call, left_cid, NULL, FlowGraph::kValue);
    const intptr_t type_cid = Class::ZoneHandle(Z, type.type_class()).id();
    ConstantInstr* cid =
        flow_graph()->GetConstant(Smi::ZoneHandle(Z, Smi::New(type_cid)));
    ConstantInstr* pos = flow_graph()->GetConstant(
        Smi::ZoneHandle(Z, Smi::New(call->token_pos().Pos())));

    ZoneGrowableArray<PushArgumentInstr*>* args =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(5);
    PushArgumentInstr* arg = new (Z) PushArgumentInstr(new (Z) Value(pos));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    arg = new (Z) PushArgumentInstr(new (Z) Value(left));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    arg = new (Z)
        PushArgumentInstr(new (Z) Value(flow_graph()->GetConstant(type)));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    arg = new (Z) PushArgumentInstr(new (Z) Value(left_cid));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    arg = new (Z) PushArgumentInstr(new (Z) Value(cid));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);

    const Library& dart_internal = Library::Handle(Z, Library::CoreLibrary());
    const String& target_name = Symbols::_classIdEqualsAssert();
    const Function& target = Function::ZoneHandle(
        Z, dart_internal.LookupFunctionAllowPrivate(target_name));
    ASSERT(!target.IsNull());
    ASSERT(target.IsRecognized());
    ASSERT(target.always_inline());

    const intptr_t kTypeArgsLen = 0;
    StaticCallInstr* new_call = new (Z) StaticCallInstr(
        call->token_pos(), target, kTypeArgsLen,
        Object::null_array(),  // argument_names
        args, call->deopt_id(), call->CallCount(), ICData::kStatic);
    Environment* copy =
        call->env()->DeepCopy(Z, call->env()->Length() - call->ArgumentCount());
    for (intptr_t i = 0; i < args->length(); ++i) {
      copy->PushValue(new (Z) Value((*args)[i]->value()->definition()));
    }
    call->RemoveEnvironment();
    ReplaceCall(call, new_call);
    copy->DeepCopyTo(Z, new_call);
    return;
  }

  if (TryReplaceTypeCastWithRangeCheck(call, type)) {
    return;
  }

  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  const intptr_t number_of_checks = unary_checks.NumberOfChecks();
  if (number_of_checks > 0 && number_of_checks <= FLAG_max_polymorphic_checks) {
    ZoneGrowableArray<intptr_t>* results =
        new (Z) ZoneGrowableArray<intptr_t>(number_of_checks * 2);
    const Bool& as_bool =
        Bool::ZoneHandle(Z, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.raw() == Bool::True().raw()) {
      // Guard against repeated speculative inlining.
      if (!speculative_policy_->IsAllowedForInlining(call->deopt_id())) {
        return;
      }

      AddReceiverCheck(call);
      // Remove the original push arguments.
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->PushArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
      // Remove call, replace it with 'left'.
      call->ReplaceUsesWith(left);
      ASSERT(current_iterator()->Current() == call);
      current_iterator()->RemoveCurrentFromGraph();
      return;
    }
  }
  AssertAssignableInstr* assert_as = new (Z) AssertAssignableInstr(
      call->token_pos(), new (Z) Value(left),
      new (Z) Value(instantiator_type_args), new (Z) Value(function_type_args),
      type, Symbols::InTypeCast(), call->deopt_id());
  ReplaceCall(call, assert_as);
}

void CallSpecializer::VisitStaticCall(StaticCallInstr* call) {
  if (FlowGraphInliner::TryReplaceStaticCallWithInline(
          flow_graph_, current_iterator(), call, speculative_policy_)) {
    return;
  }

  if (speculative_policy_->IsAllowedForInlining(call->deopt_id())) {
    // Only if speculative inlining is enabled.

    MethodRecognizer::Kind recognized_kind =
        MethodRecognizer::RecognizeKind(call->function());

    switch (recognized_kind) {
      case MethodRecognizer::kMathMin:
      case MethodRecognizer::kMathMax: {
        // We can handle only monomorphic min/max call sites with both arguments
        // being either doubles or smis.
        if (CanUnboxDouble() && call->HasICData() &&
            call->ic_data()->NumberOfChecksIs(1) &&
            (call->FirstArgIndex() == 0)) {
          const ICData& ic_data = *call->ic_data();
          intptr_t result_cid = kIllegalCid;
          if (ICDataHasReceiverArgumentClassIds(ic_data, kDoubleCid,
                                                kDoubleCid)) {
            result_cid = kDoubleCid;
          } else if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid,
                                                       kSmiCid)) {
            result_cid = kSmiCid;
          }
          if (result_cid != kIllegalCid) {
            MathMinMaxInstr* min_max = new (Z) MathMinMaxInstr(
                recognized_kind, new (Z) Value(call->ArgumentAt(0)),
                new (Z) Value(call->ArgumentAt(1)), call->deopt_id(),
                result_cid);
            const Cids* cids =
                Cids::Create(Z, ic_data, /* argument_number =*/0);
            AddCheckClass(min_max->left()->definition(), *cids,
                          call->deopt_id(), call->env(), call);
            AddCheckClass(min_max->right()->definition(), *cids,
                          call->deopt_id(), call->env(), call);
            ReplaceCall(call, min_max);
            return;
          }
        }
        break;
      }
      case MethodRecognizer::kDoubleFromInteger: {
        if (call->HasICData() && call->ic_data()->NumberOfChecksIs(1) &&
            (call->FirstArgIndex() == 0)) {
          const ICData& ic_data = *call->ic_data();
          if (CanUnboxDouble()) {
            if (ArgIsAlways(kSmiCid, ic_data, 1)) {
              Definition* arg = call->ArgumentAt(1);
              AddCheckSmi(arg, call->deopt_id(), call->env(), call);
              ReplaceCall(call, new (Z) SmiToDoubleInstr(new (Z) Value(arg),
                                                         call->token_pos()));
              return;
            } else if (ArgIsAlways(kMintCid, ic_data, 1) &&
                       CanConvertUnboxedMintToDouble()) {
              Definition* arg = call->ArgumentAt(1);
              ReplaceCall(call, new (Z) MintToDoubleInstr(new (Z) Value(arg),
                                                          call->deopt_id()));
              return;
            }
          }
        }
        break;
      }

      default:
        break;
    }
  }

  if (FLAG_experimental_strong_mode &&
      TryOptimizeStaticCallUsingStaticTypes(call)) {
    return;
  }
}

void CallSpecializer::VisitLoadCodeUnits(LoadCodeUnitsInstr* instr) {
// TODO(zerny): Use kUnboxedUint32 once it is fully supported/optimized.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
  if (!instr->can_pack_into_smi()) instr->set_representation(kUnboxedInt64);
#endif
}

static bool CidTestResultsContains(const ZoneGrowableArray<intptr_t>& results,
                                   intptr_t test_cid) {
  for (intptr_t i = 0; i < results.length(); i += 2) {
    if (results[i] == test_cid) return true;
  }
  return false;
}

static void TryAddTest(ZoneGrowableArray<intptr_t>* results,
                       intptr_t test_cid,
                       bool result) {
  if (!CidTestResultsContains(*results, test_cid)) {
    results->Add(test_cid);
    results->Add(result);
  }
}

// Used when we only need the positive result because we return false by
// default.
static void PurgeNegativeTestCidsEntries(ZoneGrowableArray<intptr_t>* results) {
  // We can't purge the Smi entry at the beginning since it is used in the
  // Smi check before the Cid is loaded.
  int dest = 2;
  for (intptr_t i = 2; i < results->length(); i += 2) {
    if (results->At(i + 1) != 0) {
      (*results)[dest++] = results->At(i);
      (*results)[dest++] = results->At(i + 1);
    }
  }
  results->SetLength(dest);
}

bool CallSpecializer::SpecializeTestCidsForNumericTypes(
    ZoneGrowableArray<intptr_t>* results,
    const AbstractType& type) {
  ASSERT(results->length() >= 2);  // At least on entry.
  const ClassTable& class_table = *Isolate::Current()->class_table();
  if ((*results)[0] != kSmiCid) {
    const Class& cls = Class::Handle(class_table.At(kSmiCid));
    const Class& type_class = Class::Handle(type.type_class());
    const bool smi_is_subtype =
        cls.IsSubtypeOf(Object::null_type_arguments(), type_class,
                        Object::null_type_arguments(), NULL, NULL, Heap::kOld);
    results->Add((*results)[results->length() - 2]);
    results->Add((*results)[results->length() - 2]);
    for (intptr_t i = results->length() - 3; i > 1; --i) {
      (*results)[i] = (*results)[i - 2];
    }
    (*results)[0] = kSmiCid;
    (*results)[1] = smi_is_subtype;
  }

  ASSERT(type.IsInstantiated() && !type.IsMalformedOrMalbounded());
  ASSERT(results->length() >= 2);
  if (type.IsSmiType()) {
    ASSERT((*results)[0] == kSmiCid);
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsIntType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    TryAddTest(results, kBigintCid, true);
    // Cannot deoptimize since all tests returning true have been added.
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsNumberType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    TryAddTest(results, kBigintCid, true);
    TryAddTest(results, kDoubleCid, true);
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsDoubleType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kDoubleCid, true);
    PurgeNegativeTestCidsEntries(results);
    return false;
  }
  return true;  // May deoptimize since we have not identified all 'true' tests.
}

}  // namespace dart
#endif  // DART_PRECOMPILED_RUNTIME
