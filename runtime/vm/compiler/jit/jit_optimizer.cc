// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef DART_PRECOMPILED_RUNTIME
#include "vm/compiler/jit/jit_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/hash_map.h"
#include "vm/object_store.h"
#include "vm/optimizer.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

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

// Optimize instance calls using ICData.
void JitOptimizer::ApplyICData() {
  VisitBlocks();
}

// Optimize instance calls using cid.  This is called after optimizer
// converted instance calls to instructions. Any remaining
// instance calls are either megamorphic calls, cannot be optimized or
// have no runtime type feedback collected.
// Attempts to convert an instance call (IC call) using propagated class-ids,
// e.g., receiver class id, guarded-cid, or by guessing cid-s.
void JitOptimizer::ApplyClassIds() {
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

// TODO(srdjan): Test/support other number types as well.
static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}

bool JitOptimizer::TryCreateICData(InstanceCallInstr* call) {
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
  if (Token::IsRelationalOperator(op_kind) ||
      Token::IsEqualityOperator(op_kind) || Token::IsBinaryOperator(op_kind)) {
    // Guess cid: if one of the inputs is a number assume that the other
    // is a number of same type.
    if (FLAG_guess_icdata_cid) {
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
    ArgumentsDescriptor args_desc(
        Array::Handle(Z, call->GetArgumentsDescriptor()));
    bool allow_add = false;
    const Function& function = Function::Handle(
        Z, Resolver::ResolveDynamicForReceiverClass(
               receiver_class, call->function_name(), args_desc, allow_add));
    if (function.IsNull()) {
      return false;
    }

    // Create new ICData, do not modify the one attached to the instruction
    // since it is attached to the assembly instruction itself.
    // TODO(srdjan): Prevent modification of ICData object that is
    // referenced in assembly code.
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

  // Check if getter or setter in function's class and class is currently leaf.
  if (FLAG_guess_icdata_cid && ((call->token_kind() == Token::kGET) ||
                                (call->token_kind() == Token::kSET))) {
    const Class& owner_class = Class::Handle(Z, function().Owner());
    if (!owner_class.is_abstract() && !CHA::HasSubclasses(owner_class) &&
        !CHA::IsImplemented(owner_class)) {
      const int kTypeArgsLen = 0;
      ASSERT(call->type_args_len() == kTypeArgsLen);
      const Array& args_desc_array = Array::Handle(
          Z, ArgumentsDescriptor::New(kTypeArgsLen, call->ArgumentCount(),
                                      call->argument_names()));
      ArgumentsDescriptor args_desc(args_desc_array);
      bool allow_add = false;
      const Function& function = Function::Handle(
          Z, Resolver::ResolveDynamicForReceiverClass(
                 owner_class, call->function_name(), args_desc, allow_add));
      if (!function.IsNull()) {
        const ICData& ic_data = ICData::ZoneHandle(
            Z, ICData::NewFrom(*call->ic_data(), class_ids.length()));
        ic_data.AddReceiverCheck(owner_class.id(), function);
        call->set_ic_data(&ic_data);
        return true;
      }
    }
  }

  return false;
}

void JitOptimizer::SpecializePolymorphicInstanceCall(
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

static bool HasOnlyTwoOf(const ICData& ic_data, intptr_t cid) {
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

void JitOptimizer::ReplaceCall(Definition* call, Definition* replacement) {
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  call->ReplaceWith(replacement, current_iterator());
}

void JitOptimizer::AddCheckSmi(Definition* to_check,
                               intptr_t deopt_id,
                               Environment* deopt_environment,
                               Instruction* insert_before) {
  if (to_check->Type()->ToCid() != kSmiCid) {
    InsertBefore(insert_before,
                 new (Z) CheckSmiInstr(new (Z) Value(to_check), deopt_id,
                                       insert_before->token_pos()),
                 deopt_environment, FlowGraph::kEffect);
  }
}

void JitOptimizer::AddCheckClass(Definition* to_check,
                                 const Cids& cids,
                                 intptr_t deopt_id,
                                 Environment* deopt_environment,
                                 Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = flow_graph_->CreateCheckClass(
      to_check, cids, deopt_id, insert_before->token_pos());
  InsertBefore(insert_before, check, deopt_environment, FlowGraph::kEffect);
}

void JitOptimizer::AddChecksForArgNr(InstanceCallInstr* call,
                                     Definition* instr,
                                     int argument_number) {
  const Cids* cids = Cids::Create(Z, *call->ic_data(), argument_number);
  AddCheckClass(instr, *cids, call->deopt_id(), call->env(), call);
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

bool JitOptimizer::TryReplaceWithIndexedOp(InstanceCallInstr* call) {
  // Check for monomorphic IC data.
  if (!call->HasICData()) return false;
  const ICData& ic_data =
      ICData::Handle(Z, call->ic_data()->AsUnaryClassChecks());
  if (!ic_data.NumberOfChecksIs(1)) {
    return false;
  }
  return FlowGraphInliner::TryReplaceInstanceCallWithInline(
      flow_graph_, current_iterator(), call);
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
// TODO(srdjan): Expand for two-byte and external strings.
bool JitOptimizer::TryStringLengthOneEquality(InstanceCallInstr* call,
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
      AddChecksForArgNr(call, right, 1);
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

bool JitOptimizer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
                                            Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
  if (HasOnlyTwoOf(ic_data, kOneByteStringCid)) {
    if (TryStringLengthOneEquality(call, op_kind)) {
      return true;
    } else {
      return false;
    }
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
      AddChecksForArgNr(call, left, 0);
      AddChecksForArgNr(call, right, 0);
      cid = kSmiCid;
    } else {
      // Shortcut for equality with null.
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

bool JitOptimizer::TryReplaceWithRelationalOp(InstanceCallInstr* call,
                                              Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

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

bool JitOptimizer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
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
  } else if (operands_type == kFloat32x4Cid) {
    return InlineFloat32x4BinaryOp(call, op_kind);
  } else if (operands_type == kInt32x4Cid) {
    return InlineInt32x4BinaryOp(call, op_kind);
  } else if (operands_type == kFloat64x2Cid) {
    return InlineFloat64x2BinaryOp(call, op_kind);
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

bool JitOptimizer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
                                         Token::Kind op_kind) {
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

// Using field class.
RawField* JitOptimizer::GetField(intptr_t class_id, const String& field_name) {
  Class& cls = Class::Handle(Z, isolate()->class_table()->At(class_id));
  Field& field = Field::Handle(Z);
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      if (Compiler::IsBackgroundCompilation() ||
          FLAG_force_clone_compiler_objects) {
        return field.CloneFromOriginal();
      } else {
        return field.raw();
      }
    }
    cls = cls.SuperClass();
  }
  return Field::null();
}

bool JitOptimizer::InlineImplicitInstanceGetter(InstanceCallInstr* call) {
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
    AddReceiverCheck(call);
  }
  LoadFieldInstr* load = new (Z)
      LoadFieldInstr(new (Z) Value(call->ArgumentAt(0)), &field,
                     AbstractType::ZoneHandle(Z, field.type()),
                     call->token_pos(), &flow_graph()->parsed_function());
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

bool JitOptimizer::InlineFloat32x4BinaryOp(InstanceCallInstr* call,
                                           Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left and right.
  AddChecksForArgNr(call, left, 0);
  AddChecksForArgNr(call, right, 1);
  // Replace call.
  BinaryFloat32x4OpInstr* float32x4_bin_op = new (Z) BinaryFloat32x4OpInstr(
      op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
  ReplaceCall(call, float32x4_bin_op);

  return true;
}

bool JitOptimizer::InlineInt32x4BinaryOp(InstanceCallInstr* call,
                                         Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left and right.
  AddChecksForArgNr(call, left, 0);
  AddChecksForArgNr(call, right, 1);
  // Replace call.
  BinaryInt32x4OpInstr* int32x4_bin_op = new (Z) BinaryInt32x4OpInstr(
      op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
  ReplaceCall(call, int32x4_bin_op);
  return true;
}

bool JitOptimizer::InlineFloat64x2BinaryOp(InstanceCallInstr* call,
                                           Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left and right.
  AddChecksForArgNr(call, left, 0);
  AddChecksForArgNr(call, right, 1);
  // Replace call.
  BinaryFloat64x2OpInstr* float64x2_bin_op = new (Z) BinaryFloat64x2OpInstr(
      op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
  ReplaceCall(call, float64x2_bin_op);
  return true;
}

// Only unique implicit instance getters can be currently handled.
bool JitOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call) {
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
  return InlineImplicitInstanceGetter(call);
}

void JitOptimizer::ReplaceWithMathCFunction(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
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
bool JitOptimizer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfUsedChecks() != 1) {
    // No type feedback collected or multiple targets found.
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
      flow_graph_, current_iterator(), call);
}

// If type tests specified by 'ic_data' do not depend on type arguments,
// return mapping cid->result in 'results' (i : cid; i + 1: result).
// If all tests yield the same result, return it otherwise return Bool::null.
// If no mapping is possible, 'results' is empty.
// An instance-of test returning all same results can be converted to a class
// check.
RawBool* JitOptimizer::InstanceOfAsBool(
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
bool JitOptimizer::TypeCheckAsClassEquality(const AbstractType& type) {
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

// TODO(srdjan): Use ICData to check if always true or false.
void JitOptimizer::ReplaceWithInstanceOf(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator_type_args = NULL;
  Definition* function_type_args = NULL;
  AbstractType& type = AbstractType::ZoneHandle(Z);
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

  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  const intptr_t number_of_checks = unary_checks.NumberOfChecks();
  if ((number_of_checks > 0) &&
      (number_of_checks <= FLAG_max_polymorphic_checks)) {
    ZoneGrowableArray<intptr_t>* results =
        new (Z) ZoneGrowableArray<intptr_t>(number_of_checks * 2);
    Bool& as_bool =
        Bool::ZoneHandle(Z, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.IsNull()) {
      if (results->length() == number_of_checks * 2) {
        const bool can_deopt =
            Optimizer::SpecializeTestCidsForNumericTypes(results, type);
        TestCidsInstr* test_cids = new (Z) TestCidsInstr(
            call->token_pos(), Token::kIS, new (Z) Value(left), *results,
            can_deopt ? call->deopt_id() : Thread::kNoDeoptId);
        // Remove type.
        ReplaceCall(call, test_cids);
        return;
      }
    } else {
      // TODO(srdjan): Use TestCidsInstr also for this case.
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

// TODO(srdjan): Apply optimizations as in ReplaceWithInstanceOf (TestCids).
void JitOptimizer::ReplaceWithTypeCast(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeCastOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator_type_args = call->ArgumentAt(1);
  Definition* function_type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  ASSERT(!type.IsMalformedOrMalbounded());
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  const intptr_t number_of_checks = unary_checks.NumberOfChecks();
  if ((number_of_checks > 0) &&
      (number_of_checks <= FLAG_max_polymorphic_checks)) {
    ZoneGrowableArray<intptr_t>* results =
        new (Z) ZoneGrowableArray<intptr_t>(number_of_checks * 2);
    const Bool& as_bool =
        Bool::ZoneHandle(Z, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.raw() == Bool::True().raw()) {
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

// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void JitOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (!instr->HasICData() || (instr->ic_data()->NumberOfUsedChecks() == 0)) {
    return;
  }
  const Token::Kind op_kind = instr->token_kind();

  // Type test is special as it always gets converted into inlined code.
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }

  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }

  const ICData& unary_checks =
      ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());

  if ((op_kind == Token::kASSIGN_INDEX) && TryReplaceWithIndexedOp(instr)) {
    return;
  }
  if ((op_kind == Token::kINDEX) && TryReplaceWithIndexedOp(instr)) {
    return;
  }

  if (op_kind == Token::kEQ && TryReplaceWithEqualityOp(instr, op_kind)) {
    return;
  }

  if (Token::IsRelationalOperator(op_kind) &&
      TryReplaceWithRelationalOp(instr, op_kind)) {
    return;
  }

  if (Token::IsBinaryOperator(op_kind) &&
      TryReplaceWithBinaryOp(instr, op_kind)) {
    return;
  }
  if (Token::IsUnaryOperator(op_kind) &&
      TryReplaceWithUnaryOp(instr, op_kind)) {
    return;
  }
  if ((op_kind == Token::kGET) && TryInlineInstanceGetter(instr)) {
    return;
  }
  if ((op_kind == Token::kSET) &&
      TryInlineInstanceSetter(instr, unary_checks)) {
    return;
  }
  if (TryInlineInstanceMethod(instr)) {
    return;
  }

  const CallTargets& targets = *CallTargets::CreateAndExpand(Z, unary_checks);

  bool has_one_target = targets.HasSingleTarget();

  if (has_one_target) {
    // Check if the single target is a polymorphic target, if it is,
    // we don't have one target.
    const Function& target = Function::Handle(Z, unary_checks.GetTargetAt(0));
    if (target.recognized_kind() == MethodRecognizer::kObjectRuntimeType) {
      has_one_target = PolymorphicInstanceCallInstr::ComputeRuntimeType(
                           targets) != Type::null();
    } else {
      const bool polymorphic_target =
          MethodRecognizer::PolymorphicTarget(target);
      has_one_target = !polymorphic_target;
    }
  }

  if (has_one_target) {
    const Function& target =
        Function::ZoneHandle(Z, unary_checks.GetTargetAt(0));
    const RawFunction::Kind function_kind = target.kind();
    if (!flow_graph()->InstanceCallNeedsClassCheck(instr, function_kind)) {
      StaticCallInstr* call = StaticCallInstr::FromCall(Z, instr, target);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  // If there is only one target we can make this into a deopting class check,
  // followed by a call instruction that does not check the class of the
  // receiver.  This enables a lot of optimizations because after the class
  // check we can probably inline the call and not worry about side effects.
  // However, this can fall down if new receiver classes arrive at this call
  // site after we generated optimized code.  This causes a deopt, and after a
  // few deopts we won't optimize this function any more at all.  Therefore for
  // very polymorphic sites we don't make this optimization, keeping it as a
  // regular checked PolymorphicInstanceCall, which falls back to the slow but
  // non-deopting megamorphic call stub when it sees new receiver classes.
  if (has_one_target && FLAG_polymorphic_with_deopt &&
      (!instr->ic_data()->HasDeoptReason(ICData::kDeoptCheckClass) ||
       unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks)) {
    // Type propagation has not run yet, we cannot eliminate the check.
    // TODO(erikcorry): The receiver check should use the off-heap targets
    // array, not the IC array.
    AddReceiverCheck(instr);
    // Call can still deoptimize, do not detach environment from instr.
    const Function& target =
        Function::ZoneHandle(Z, unary_checks.GetTargetAt(0));
    StaticCallInstr* call = StaticCallInstr::FromCall(Z, instr, target);
    instr->ReplaceWith(call, current_iterator());
  } else {
    PolymorphicInstanceCallInstr* call =
        new (Z) PolymorphicInstanceCallInstr(instr, targets,
                                             /* complete = */ false);
    instr->ReplaceWith(call, current_iterator());
  }
}

void JitOptimizer::VisitStaticCall(StaticCallInstr* call) {
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(call->function());
  switch (recognized_kind) {
    case MethodRecognizer::kObjectConstructor:
    case MethodRecognizer::kObjectArrayAllocate:
    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat32x4Splat:
    case MethodRecognizer::kFloat32x4Constructor:
    case MethodRecognizer::kFloat32x4FromFloat64x2:
    case MethodRecognizer::kFloat64x2Constructor:
    case MethodRecognizer::kFloat64x2Zero:
    case MethodRecognizer::kFloat64x2Splat:
    case MethodRecognizer::kFloat64x2FromFloat32x4:
    case MethodRecognizer::kInt32x4BoolConstructor:
    case MethodRecognizer::kInt32x4Constructor:
    case MethodRecognizer::kMathSqrt:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2:
      FlowGraphInliner::TryReplaceStaticCallWithInline(
          flow_graph_, current_iterator(), call);
      break;
    case MethodRecognizer::kMathMin:
    case MethodRecognizer::kMathMax: {
      // We can handle only monomorphic min/max call sites with both arguments
      // being either doubles or smis.
      if (CanUnboxDouble() && call->HasICData() &&
          call->ic_data()->NumberOfChecksIs(1)) {
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
              new (Z) Value(call->ArgumentAt(1)), call->deopt_id(), result_cid);
          const Cids* cids = Cids::Create(Z, ic_data, 0);
          AddCheckClass(min_max->left()->definition(), *cids, call->deopt_id(),
                        call->env(), call);
          AddCheckClass(min_max->right()->definition(), *cids, call->deopt_id(),
                        call->env(), call);
          ReplaceCall(call, min_max);
        }
      }
      break;
    }

    case MethodRecognizer::kDoubleFromInteger: {
      if (call->HasICData() && call->ic_data()->NumberOfChecksIs(1)) {
        const ICData& ic_data = *call->ic_data();
        if (CanUnboxDouble()) {
          if (ArgIsAlways(kSmiCid, ic_data, 1)) {
            Definition* arg = call->ArgumentAt(1);
            AddCheckSmi(arg, call->deopt_id(), call->env(), call);
            ReplaceCall(call, new (Z) SmiToDoubleInstr(new (Z) Value(arg),
                                                       call->token_pos()));
          } else if (ArgIsAlways(kMintCid, ic_data, 1) &&
                     CanConvertUnboxedMintToDouble()) {
            Definition* arg = call->ArgumentAt(1);
            ReplaceCall(call, new (Z) MintToDoubleInstr(new (Z) Value(arg),
                                                        call->deopt_id()));
          }
        }
      }
      break;
    }
    default:
      break;
  }
}

void JitOptimizer::VisitStoreInstanceField(StoreInstanceFieldInstr* instr) {
  if (instr->IsUnboxedStore()) {
    // Determine if this field should be unboxed based on the usage of getter
    // and setter functions: The heuristic requires that the setter has a
    // usage count of at least 1/kGetterSetterRatio of the getter usage count.
    // This is to avoid unboxing fields where the setter is never or rarely
    // executed.
    const Field& field = instr->field();
    const String& field_name = String::Handle(Z, field.name());
    const Class& owner = Class::Handle(Z, field.Owner());
    const Function& getter =
        Function::Handle(Z, owner.LookupGetterFunction(field_name));
    const Function& setter =
        Function::Handle(Z, owner.LookupSetterFunction(field_name));
    bool unboxed_field = false;
    if (!getter.IsNull() && !setter.IsNull()) {
      if (field.is_double_initialized()) {
        unboxed_field = true;
      } else if ((setter.usage_counter() > 0) &&
                 ((FLAG_getter_setter_ratio * setter.usage_counter()) >=
                  getter.usage_counter())) {
        unboxed_field = true;
      }
    }
    if (!unboxed_field) {
      // TODO(srdjan): Instead of aborting pass this field to the mutator thread
      // so that it can:
      // - set it to unboxed
      // - deoptimize dependent code.
      if (Compiler::IsBackgroundCompilation()) {
        isolate()->AddDeoptimizingBoxedField(field);
        Compiler::AbortBackgroundCompilation(
            Thread::kNoDeoptId, "Unboxing instance field while compiling");
        UNREACHABLE();
      }
      if (FLAG_trace_optimization || FLAG_trace_field_guards) {
        THR_Print("Disabling unboxing of %s\n", field.ToCString());
        if (!setter.IsNull()) {
          OS::Print("  setter usage count: %" Pd "\n", setter.usage_counter());
        }
        if (!getter.IsNull()) {
          OS::Print("  getter usage count: %" Pd "\n", getter.usage_counter());
        }
      }
      ASSERT(field.IsOriginal());
      field.set_is_unboxing_candidate(false);
      field.DeoptimizeDependentCode();
    } else {
      flow_graph()->parsed_function().AddToGuardedFields(&field);
    }
  }
}

void JitOptimizer::VisitAllocateContext(AllocateContextInstr* instr) {
  // Replace generic allocation with a sequence of inlined allocation and
  // explicit initializing stores.
  AllocateUninitializedContextInstr* replacement =
      new AllocateUninitializedContextInstr(instr->token_pos(),
                                            instr->num_context_variables());
  instr->ReplaceWith(replacement, current_iterator());

  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(Context::parent_offset(), new Value(replacement),
                              new Value(flow_graph_->constant_null()),
                              kNoStoreBarrier, instr->token_pos());
  // Storing into uninitialized memory; remember to prevent dead store
  // elimination and ensure proper GC barrier.
  store->set_is_initialization(true);
  flow_graph_->InsertAfter(replacement, store, NULL, FlowGraph::kEffect);
  Definition* cursor = store;
  for (intptr_t i = 0; i < instr->num_context_variables(); ++i) {
    store = new (Z) StoreInstanceFieldInstr(
        Context::variable_offset(i), new Value(replacement),
        new Value(flow_graph_->constant_null()), kNoStoreBarrier,
        instr->token_pos());
    // Storing into uninitialized memory; remember to prevent dead store
    // elimination and ensure proper GC barrier.
    store->set_is_initialization(true);
    flow_graph_->InsertAfter(cursor, store, NULL, FlowGraph::kEffect);
    cursor = store;
  }
}

void JitOptimizer::VisitLoadCodeUnits(LoadCodeUnitsInstr* instr) {
// TODO(zerny): Use kUnboxedUint32 once it is fully supported/optimized.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
  if (!instr->can_pack_into_smi()) instr->set_representation(kUnboxedInt64);
#endif
}

bool JitOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr,
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
    AddReceiverCheck(instr);
  }
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
    InsertBefore(instr,
                 new (Z)
                     GuardFieldLengthInstr(new (Z) Value(instr->ArgumentAt(1)),
                                           field, instr->deopt_id()),
                 instr->env(), FlowGraph::kEffect);
  }

  // Field guard was detached.
  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(field, new (Z) Value(instr->ArgumentAt(0)),
                              new (Z) Value(instr->ArgumentAt(1)),
                              kEmitStoreBarrier, instr->token_pos());

  if (store->IsUnboxedStore()) {
    flow_graph()->parsed_function().AddToGuardedFields(&field);
  }

  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCall(instr, store);
  return true;
}

}  // namespace dart
#endif  // DART_PRECOMPILED_RUNTIME
