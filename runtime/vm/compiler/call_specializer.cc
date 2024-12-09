// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/call_specializer.h"

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/compiler_timings.h"
#include "vm/cpu.h"

namespace dart {

DECLARE_FLAG(bool, enable_simd_inline);

// Quick access to the current isolate and zone.
#define IG (isolate_group())
#define Z (zone())

static void RefineUseTypes(Definition* instr) {
  CompileType* new_type = instr->Type();
  for (Value::Iterator it(instr->input_use_list()); !it.Done(); it.Advance()) {
    it.Current()->RefineReachingType(new_type);
  }
}

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}

static bool CanConvertInt64ToDouble() {
  return FlowGraphCompiler::CanConvertInt64ToDouble();
}

static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}

static bool ShouldSpecializeForDouble(const BinaryFeedback& binary_feedback) {
  // Unboxed double operation can't handle case of two smis.
  if (binary_feedback.IncludesOperands(kSmiCid)) {
    return false;
  }

  // Check that the call site has seen only smis and doubles.
  return binary_feedback.OperandsAreSmiOrDouble();
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
  ASSERT(current_iterator_ == nullptr);
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
      } else if (auto static_call = instr->AsStaticCall()) {
        // If TFA devirtualized instance calls to static calls we also want to
        // process them here.
        VisitStaticCall(static_call);
      } else if (instr->IsPolymorphicInstanceCall()) {
        SpecializePolymorphicInstanceCall(instr->AsPolymorphicInstanceCall());
      }
    }
    current_iterator_ = nullptr;
  }
}

bool CallSpecializer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());

  if (call->Targets().length() > 0) {
    // This occurs when an instance call has too many checks, will be converted
    // to megamorphic call.
    return false;
  }

  const intptr_t receiver_index = call->FirstArgIndex();
  GrowableArray<intptr_t> class_ids(call->ic_data()->NumArgsTested());
  ASSERT(call->ic_data()->NumArgsTested() <=
         call->ArgumentCountWithoutTypeArgs());
  for (intptr_t i = 0; i < call->ic_data()->NumArgsTested(); i++) {
    class_ids.Add(call->ArgumentValueAt(receiver_index + i)->Type()->ToCid());
  }

  const Token::Kind op_kind = call->token_kind();
  if (FLAG_guess_icdata_cid && !CompilerState::Current().is_aot()) {
    if (Token::IsRelationalOperator(op_kind) ||
        Token::IsEqualityOperator(op_kind) ||
        Token::IsBinaryOperator(op_kind)) {
      // Guess cid: if one of the inputs is a number assume that the other
      // is a number of same type, unless the interface target tells us this
      // is impossible.
      if (call->CanReceiverBeSmiBasedOnInterfaceTarget(zone())) {
        const intptr_t cid_0 = class_ids[0];
        const intptr_t cid_1 = class_ids[1];
        if ((cid_0 == kDynamicCid) && (IsNumberCid(cid_1))) {
          class_ids[0] = cid_1;
        } else if (IsNumberCid(cid_0) && (cid_1 == kDynamicCid)) {
          class_ids[1] = cid_0;
        }
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
    const intptr_t receiver_cid = class_ids[0];
    if (receiver_cid == kSentinelCid) {
      // Unreachable call.
      return false;
    }
    const Class& receiver_class =
        Class::Handle(Z, IG->class_table()->At(receiver_cid));
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
    ASSERT(!function.IsInvokeFieldDispatcher());

    // Update the CallTargets attached to the instruction with our speculative
    // target. The next round of CallSpecializer::VisitInstanceCall will make
    // use of this.
    call->SetTargets(CallTargets::CreateMonomorphic(Z, class_ids[0], function));
    if (class_ids.length() == 2) {
      call->SetBinaryFeedback(
          BinaryFeedback::CreateMonomorphic(Z, class_ids[0], class_ids[1]));
    }
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

  const intptr_t receiver_cid = call->Receiver()->Type()->ToCid();
  if (receiver_cid == kDynamicCid) {
    return;  // No information about receiver was inferred.
  }

  const ICData& ic_data = *call->ic_data();

  const CallTargets* targets =
      FlowGraphCompiler::ResolveCallTargetsForReceiverCid(
          receiver_cid, String::Handle(zone(), ic_data.target_name()),
          Array::Handle(zone(), ic_data.arguments_descriptor()));
  if (targets == nullptr) {
    // No specialization.
    return;
  }

  ASSERT(targets->HasSingleTarget());
  const Function& target = targets->FirstTarget();
  StaticCallInstr* specialized =
      StaticCallInstr::FromCall(Z, call, target, targets->AggregateCallCount());
  call->ReplaceWith(specialized, current_iterator());
}

void CallSpecializer::ReplaceCallWithResult(Definition* call,
                                            Instruction* replacement,
                                            Definition* result) {
  ASSERT(!call->HasMoveArguments());
  if (result == nullptr) {
    ASSERT(replacement->IsDefinition());
    call->ReplaceWith(replacement->AsDefinition(), current_iterator());
  } else {
    call->ReplaceWithResult(replacement, result, current_iterator());
  }
}

void CallSpecializer::ReplaceCall(Definition* call, Definition* replacement) {
  ReplaceCallWithResult(call, replacement, nullptr);
}

void CallSpecializer::AddCheckSmi(Definition* to_check,
                                  intptr_t deopt_id,
                                  Environment* deopt_environment,
                                  Instruction* insert_before) {
  // TODO(alexmarkov): check reaching type instead of definition type
  if (to_check->Type()->ToCid() != kSmiCid) {
    InsertBefore(insert_before,
                 new (Z) CheckSmiInstr(new (Z) Value(to_check), deopt_id,
                                       insert_before->source()),
                 deopt_environment, FlowGraph::kEffect);
  }
}

void CallSpecializer::AddCheckClass(Definition* to_check,
                                    const Cids& cids,
                                    intptr_t deopt_id,
                                    Environment* deopt_environment,
                                    Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = flow_graph_->CreateCheckClass(to_check, cids, deopt_id,
                                                     insert_before->source());
  InsertBefore(insert_before, check, deopt_environment, FlowGraph::kEffect);
}

void CallSpecializer::AddChecksForArgNr(InstanceCallInstr* call,
                                        Definition* argument,
                                        int argument_number) {
  const Cids* cids =
      Cids::CreateForArgument(zone(), call->BinaryFeedback(), argument_number);
  AddCheckClass(argument, *cids, call->deopt_id(), call->env(), call);
}

void CallSpecializer::AddCheckNull(Value* to_check,
                                   const String& function_name,
                                   intptr_t deopt_id,
                                   Environment* deopt_environment,
                                   Instruction* insert_before) {
  if (to_check->Type()->is_nullable()) {
    CheckNullInstr* check_null =
        new (Z) CheckNullInstr(to_check->CopyWithType(Z), function_name,
                               deopt_id, insert_before->source());
    if (FLAG_trace_strong_mode_types) {
      THR_Print("[Strong mode] Inserted %s\n", check_null->ToCString());
    }
    InsertBefore(insert_before, check_null, deopt_environment,
                 FlowGraph::kEffect);
  }
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
  ASSERT(call->BinaryFeedback().OperandsAre(kOneByteStringCid));
  // Check that left and right are length one strings (either string constants
  // or results of string-from-char-code.
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  Value* left_val = nullptr;
  Definition* to_remove_left = nullptr;
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

    Definition* to_remove_right = nullptr;
    Value* right_val = nullptr;
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
    EqualityCompareInstr* comp = new (Z) EqualityCompareInstr(
        call->source(), op_kind, left_val, right_val, kTagged, call->deopt_id(),
        /*null_aware=*/false);
    ReplaceCall(call, comp);

    // Remove dead instructions.
    if ((to_remove_left != nullptr) &&
        (to_remove_left->input_use_list() == nullptr)) {
      to_remove_left->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_left->RemoveFromGraph();
    }
    if ((to_remove_right != nullptr) &&
        (to_remove_right->input_use_list() == nullptr)) {
      to_remove_right->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_right->RemoveFromGraph();
    }
    return true;
  }
  return false;
}

static bool SmiFitsInDouble() {
  return compiler::target::kSmiBits < 53;
}

bool CallSpecializer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  const BinaryFeedback& binary_feedback = call->BinaryFeedback();

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  Representation representation = kNoRepresentation;
  if (binary_feedback.OperandsAre(kOneByteStringCid)) {
    return TryStringLengthOneEquality(call, op_kind);
  } else if (binary_feedback.OperandsAre(kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(left), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(right), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    representation = kTagged;
  } else if (binary_feedback.OperandsAreSmiOrMint()) {
    left =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(left), call->deopt_id(),
                           UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    representation = kUnboxedInt64;
  } else if (binary_feedback.OperandsAreSmiOrDouble()) {
    // Use double comparison.
    if (!SmiFitsInDouble()) {
      if (binary_feedback.IncludesOperands(kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(
            call,
            new (Z) CheckEitherNonSmiInstr(
                new (Z) Value(left), new (Z) Value(right), call->deopt_id()),
            call->env(), FlowGraph::kEffect);
      }
    }
    left =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(left),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    representation = kUnboxedDouble;
  } else {
    // Check if ICDData contains checks with Smi/Null combinations. In that case
    // we can still emit the optimized Smi equality operation but need to add
    // checks for null or Smi.
    if (binary_feedback.OperandsAreSmiOrNull()) {
      AddChecksForArgNr(call, left, /* arg_number = */ 0);
      AddChecksForArgNr(call, right, /* arg_number = */ 1);

      representation = kTagged;
    } else {
      // Shortcut for equality with null.
      // TODO(vegorov): this optimization is not speculative and should
      // be hoisted out of this function.
      ConstantInstr* right_const = right->AsConstant();
      ConstantInstr* left_const = left->AsConstant();
      if ((right_const != nullptr && right_const->value().IsNull()) ||
          (left_const != nullptr && left_const->value().IsNull())) {
        StrictCompareInstr* comp = new (Z)
            StrictCompareInstr(call->source(), Token::kEQ_STRICT,
                               new (Z) Value(left), new (Z) Value(right),
                               /* number_check = */ false, DeoptId::kNone);
        ReplaceCall(call, comp);
        return true;
      }
      return false;
    }
  }
  ASSERT(representation != kNoRepresentation);
  EqualityCompareInstr* comp = new (Z) EqualityCompareInstr(
      call->source(), op_kind, new (Z) Value(left), new (Z) Value(right),
      representation, call->deopt_id(), /*null_aware=*/false);
  ReplaceCall(call, comp);
  return true;
}

bool CallSpecializer::TryReplaceWithRelationalOp(InstanceCallInstr* call,
                                                 Token::Kind op_kind) {
  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);

  const BinaryFeedback& binary_feedback = call->BinaryFeedback();
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  Representation representation = kNoRepresentation;
  if (binary_feedback.OperandsAre(kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(left), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(right), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    representation = kTagged;
  } else if (binary_feedback.OperandsAreSmiOrMint()) {
    left =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(left), call->deopt_id(),
                           UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    representation = kUnboxedInt64;
  } else if (binary_feedback.OperandsAreSmiOrDouble()) {
    // Use double comparison.
    if (!SmiFitsInDouble()) {
      if (binary_feedback.IncludesOperands(kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(
            call,
            new (Z) CheckEitherNonSmiInstr(
                new (Z) Value(left), new (Z) Value(right), call->deopt_id()),
            call->env(), FlowGraph::kEffect);
      }
    }
    left =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(left),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    representation = kUnboxedDouble;
  } else {
    return false;
  }
  ASSERT(representation != kNoRepresentation);
  RelationalOpInstr* comp = new (Z)
      RelationalOpInstr(call->source(), op_kind, new (Z) Value(left),
                        new (Z) Value(right), representation, call->deopt_id());
  ReplaceCall(call, comp);
  return true;
}

bool CallSpecializer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
                                             Token::Kind op_kind) {
  intptr_t operands_type = kIllegalCid;
  ASSERT(call->HasICData());
  const BinaryFeedback& binary_feedback = call->BinaryFeedback();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
      if (binary_feedback.OperandsAre(kSmiCid)) {
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        operands_type =
            call->ic_data()->HasDeoptReason(ICData::kDeoptBinarySmiOp)
                ? kMintCid
                : kSmiCid;
      } else if (binary_feedback.OperandsAreSmiOrMint()) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (call->ic_data()->HasDeoptReason(ICData::kDeoptBinaryInt64Op))
          return false;
        operands_type = kMintCid;
      } else if (ShouldSpecializeForDouble(binary_feedback)) {
        operands_type = kDoubleCid;
      } else if (binary_feedback.OperandsAre(kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (binary_feedback.OperandsAre(kInt32x4Cid)) {
        ASSERT(op_kind != Token::kMUL);  // Int32x4 doesn't have a multiply op.
        operands_type = kInt32x4Cid;
      } else if (binary_feedback.OperandsAre(kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (ShouldSpecializeForDouble(binary_feedback) ||
          binary_feedback.OperandsAre(kSmiCid)) {
        operands_type = kDoubleCid;
      } else if (binary_feedback.OperandsAre(kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (binary_feedback.OperandsAre(kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      if (binary_feedback.OperandsAre(kSmiCid)) {
        operands_type = kSmiCid;
      } else if (binary_feedback.OperandsAreSmiOrMint()) {
        operands_type = kMintCid;
      } else if (binary_feedback.OperandsAre(kInt32x4Cid)) {
        operands_type = kInt32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kSHL:
    case Token::kSHR:
    case Token::kUSHR:
      if (binary_feedback.OperandsAre(kSmiCid)) {
        // Left shift may overflow from smi into mint.
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        if (call->ic_data()->HasDeoptReason(ICData::kDeoptBinaryInt64Op)) {
          return false;
        }
        operands_type =
            call->ic_data()->HasDeoptReason(ICData::kDeoptBinarySmiOp)
                ? kMintCid
                : kSmiCid;
      } else if (binary_feedback.OperandsAreSmiOrMint() &&
                 binary_feedback.ArgumentIs(kSmiCid)) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (call->ic_data()->HasDeoptReason(ICData::kDeoptBinaryInt64Op)) {
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
      if (binary_feedback.OperandsAre(kSmiCid)) {
        if (call->ic_data()->HasDeoptReason(ICData::kDeoptBinarySmiOp)) {
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
    left =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(left),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    BinaryDoubleOpInstr* double_bin_op = new (Z)
        BinaryDoubleOpInstr(op_kind, new (Z) Value(left), new (Z) Value(right),
                            call->deopt_id(), call->source());
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    left =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(left), call->deopt_id(),
                           UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, left, call->env(), FlowGraph::kValue);
    right =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, right, call->env(), FlowGraph::kValue);
    BinaryIntegerOpInstr* bin_op = new (Z) BinaryInt64OpInstr(
        op_kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
    ReplaceCall(call, bin_op);
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
                                           call->deopt_id(), call->source()),
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
  Definition* unary_op = nullptr;
  if (call->Targets().ReceiverIs(kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(input), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    unary_op = new (Z)
        UnarySmiOpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if ((op_kind == Token::kBIT_NOT) &&
             call->Targets().ReceiverIsSmiOrMint()) {
    input =
        UnboxInstr::Create(kUnboxedInt64, new (Z) Value(input),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, input, call->env(), FlowGraph::kValue);
    unary_op = new (Z)
        UnaryInt64OpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if (call->Targets().ReceiverIs(kDoubleCid) &&
             (op_kind == Token::kNEGATE)) {
    AddReceiverCheck(call);
    input =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(input),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    InsertBefore(call, input, call->env(), FlowGraph::kValue);
    unary_op = new (Z) UnaryDoubleOpInstr(Token::kNEGATE, new (Z) Value(input),
                                          call->deopt_id());
  } else {
    return false;
  }
  ASSERT(unary_op != nullptr);
  ReplaceCall(call, unary_op);
  return true;
}

bool CallSpecializer::TryInlineImplicitInstanceGetter(InstanceCallInstr* call) {
  const CallTargets& targets = call->Targets();
  ASSERT(targets.HasSingleTarget());

  // Inline implicit instance getter.
  Field& field = Field::ZoneHandle(Z, targets.FirstTarget().accessor_field());
  ASSERT(!field.IsNull());
  if (field.needs_load_guard()) {
    return false;
  }
  if (should_clone_fields_) {
    field = field.CloneFromOriginal();
  }

  switch (flow_graph()->CheckForInstanceCall(
      call, UntaggedFunction::kImplicitGetter)) {
    case FlowGraph::ToCheck::kCheckNull:
      AddCheckNull(call->Receiver(), call->function_name(), call->deopt_id(),
                   call->env(), call);
      break;
    case FlowGraph::ToCheck::kCheckCid:
      if (CompilerState::Current().is_aot()) {
        return false;  // AOT cannot class check
      }
      AddReceiverCheck(call);
      break;
    case FlowGraph::ToCheck::kNoCheck:
      break;
  }
  InlineImplicitInstanceGetter(call, field);
  return true;
}

void CallSpecializer::InlineImplicitInstanceGetter(Definition* call,
                                                   const Field& field) {
  ASSERT(field.is_instance());
  Definition* receiver = call->ArgumentAt(0);

  const bool calls_initializer = field.NeedsInitializationCheckOnLoad();
  const Slot& slot = Slot::Get(field, &flow_graph()->parsed_function());
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      new (Z) Value(receiver), slot, call->source(), calls_initializer,
      calls_initializer ? call->deopt_id() : DeoptId::kNone);

  // Note that this is a case of LoadField -> InstanceCall lazy deopt.
  // Which means that we don't need to remove arguments from the environment
  // because normal getter call expects receiver pushed (unlike the case
  // of LoadField -> LoadField deoptimization handled by
  // FlowGraph::AttachEnvironment).
  if (!calls_initializer) {
    // If we don't call initializer then we don't need an environment.
    call->RemoveEnvironment();
  }
  ReplaceCall(call, load);

  if (load->slot().type().ToNullableCid() != kDynamicCid) {
    // Reset value types if we know concrete cid.
    for (Value::Iterator it(load->input_use_list()); !it.Done(); it.Advance()) {
      it.Current()->SetReachingType(nullptr);
    }
  }
}

bool CallSpecializer::TryInlineInstanceSetter(InstanceCallInstr* instr) {
  const CallTargets& targets = instr->Targets();
  if (!targets.HasSingleTarget()) {
    // Polymorphic sites are inlined like normal method calls by conventional
    // inlining.
    return false;
  }
  const Function& target = targets.FirstTarget();
  if (target.kind() != UntaggedFunction::kImplicitSetter) {
    // Non-implicit setter are inlined like normal method calls.
    return false;
  }
  if (!CompilerState::Current().is_aot() && !target.WasCompiled()) {
    return false;
  }
  Field& field = Field::ZoneHandle(Z, target.accessor_field());
  ASSERT(!field.IsNull());
  if (should_clone_fields_) {
    field = field.CloneFromOriginal();
  }
  if (field.is_late() && field.is_final()) {
    return false;
  }

  switch (flow_graph()->CheckForInstanceCall(
      instr, UntaggedFunction::kImplicitSetter)) {
    case FlowGraph::ToCheck::kCheckNull:
      AddCheckNull(instr->Receiver(), instr->function_name(), instr->deopt_id(),
                   instr->env(), instr);
      break;
    case FlowGraph::ToCheck::kCheckCid:
      if (CompilerState::Current().is_aot()) {
        return false;  // AOT cannot class check
      }
      AddReceiverCheck(instr);
      break;
    case FlowGraph::ToCheck::kNoCheck:
      break;
  }

  // True if we can use unchecked entry into the setter.
  bool is_unchecked_call = false;
  if (!CompilerState::Current().is_aot()) {
    if (targets.IsMonomorphic() && targets.MonomorphicExactness().IsExact()) {
      if (targets.MonomorphicExactness().IsTriviallyExact()) {
        flow_graph()->AddExactnessGuard(instr,
                                        targets.MonomorphicReceiverCid());
      }
      is_unchecked_call = true;
    }
  }

  if (IG->use_field_guards()) {
    if (field.guarded_cid() != kDynamicCid) {
      InsertSpeculativeBefore(
          instr,
          new (Z) GuardFieldClassInstr(new (Z) Value(instr->ArgumentAt(1)),
                                       field, instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }

    if (field.needs_length_check()) {
      InsertSpeculativeBefore(
          instr,
          new (Z) GuardFieldLengthInstr(new (Z) Value(instr->ArgumentAt(1)),
                                        field, instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }

    if (field.static_type_exactness_state().NeedsFieldGuard()) {
      InsertSpeculativeBefore(
          instr,
          new (Z) GuardFieldTypeInstr(new (Z) Value(instr->ArgumentAt(1)),
                                      field, instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }
  }

  // Build an AssertAssignable if necessary.
  const AbstractType& dst_type = AbstractType::ZoneHandle(zone(), field.type());
  if (!dst_type.IsTopTypeForSubtyping()) {
    // Compute if we need to type check the value. Always type check if
    // at a dynamic invocation.
    bool needs_check = true;
    if (!instr->interface_target().IsNull()) {
      if (field.is_covariant()) {
        // Always type check covariant fields.
        needs_check = true;
      } else if (field.is_generic_covariant_impl()) {
        // If field is generic covariant then we don't need to check it
        // if the invocation was marked as unchecked (e.g. receiver of
        // the invocation is also the receiver of the surrounding method).
        // Note: we can't use flow_graph()->IsReceiver() for this optimization
        // because strong mode only gives static guarantees at the AST level
        // not at the SSA level.
        needs_check = !(is_unchecked_call ||
                        (instr->entry_kind() == Code::EntryKind::kUnchecked));
      } else {
        // The rest of the stores are checked statically (we are not at
        // a dynamic invocation).
        needs_check = false;
      }
    }

    if (needs_check) {
      Definition* instantiator_type_args = flow_graph_->constant_null();
      Definition* function_type_args = flow_graph_->constant_null();
      if (!dst_type.IsInstantiated()) {
        const Class& owner = Class::Handle(Z, field.Owner());
        if (owner.NumTypeArguments() > 0) {
          instantiator_type_args = new (Z) LoadFieldInstr(
              new (Z) Value(instr->ArgumentAt(0)),
              Slot::GetTypeArgumentsSlotFor(thread(), owner), instr->source());
          InsertSpeculativeBefore(instr, instantiator_type_args, instr->env(),
                                  FlowGraph::kValue);
        }
      }

      auto assert_assignable = new (Z) AssertAssignableInstr(
          instr->source(), new (Z) Value(instr->ArgumentAt(1)),
          new (Z) Value(flow_graph_->GetConstant(dst_type)),
          new (Z) Value(instantiator_type_args),
          new (Z) Value(function_type_args),
          String::ZoneHandle(zone(), field.name()), instr->deopt_id());
      InsertSpeculativeBefore(instr, assert_assignable, instr->env(),
                              FlowGraph::kEffect);
    }
  }

  // Field guard was detached.
  ASSERT(instr->FirstArgIndex() == 0);
  StoreFieldInstr* store = new (Z)
      StoreFieldInstr(field, new (Z) Value(instr->ArgumentAt(0)),
                      new (Z) Value(instr->ArgumentAt(1)), kEmitStoreBarrier,
                      instr->source(), &flow_graph()->parsed_function());

  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCallWithResult(instr, store, flow_graph()->constant_null());
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
  const CallTargets& targets = call->Targets();
  if (!targets.HasSingleTarget()) {
    // Polymorphic sites are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }
  const Function& target = targets.FirstTarget();
  if (target.kind() != UntaggedFunction::kImplicitGetter) {
    // Non-implicit getters are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }
  if (!CompilerState::Current().is_aot() && !target.WasCompiled()) {
    return false;
  }
  return TryInlineImplicitInstanceGetter(call);
}

// Inline only simple, frequently called core library methods.
bool CallSpecializer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  const CallTargets& targets = call->Targets();
  if (!targets.IsMonomorphic()) {
    // No type feedback collected or multiple receivers/targets found.
    return false;
  }

  const Function& target = targets.FirstTarget();
  intptr_t receiver_cid = targets.MonomorphicReceiverCid();
  MethodRecognizer::Kind recognized_kind = target.recognized_kind();

  if (recognized_kind == MethodRecognizer::kIntegerToDouble) {
    Definition* input = call->ArgumentAt(0);
    if (receiver_cid == kSmiCid) {
      AddReceiverCheck(call);
      ReplaceCall(
          call, new (Z) SmiToDoubleInstr(new (Z) Value(input), call->source()));
      return true;
    } else if ((receiver_cid == kMintCid) && CanConvertInt64ToDouble()) {
      AddReceiverCheck(call);
      input = UnboxInstr::Create(kUnboxedInt64, new (Z) Value(input),
                                 call->deopt_id(),
                                 UnboxInstr::ValueMode::kCheckType);
      InsertBefore(call, input, call->env(), FlowGraph::kValue);
      ReplaceCall(call, new (Z) Int64ToDoubleInstr(new (Z) Value(input),
                                                   call->deopt_id()));
      return true;
    }
  }

  if (receiver_cid == kDoubleCid) {
    switch (recognized_kind) {
      case MethodRecognizer::kDoubleToInteger: {
        AddReceiverCheck(call);
        ASSERT(call->HasICData());
        const ICData& ic_data = *call->ic_data();
        Definition* input = call->ArgumentAt(0);
        Definition* d2i_instr = nullptr;
        if (ic_data.HasDeoptReason(ICData::kDeoptDoubleToSmi)) {
          // Do not repeatedly deoptimize because result didn't fit into Smi.
          d2i_instr = new (Z) DoubleToIntegerInstr(
              new (Z) Value(input), recognized_kind, call->deopt_id());
        } else {
          // Optimistically assume result fits into Smi.
          d2i_instr =
              new (Z) DoubleToSmiInstr(new (Z) Value(input), call->deopt_id());
        }
        ReplaceCall(call, d2i_instr);
        return true;
      }
      default:
        break;
    }
  }

  return TryReplaceInstanceCallWithInline(flow_graph_, current_iterator(),
                                          call);
}

// If type tests specified by 'ic_data' do not depend on type arguments,
// return mapping cid->result in 'results' (i : cid; i + 1: result).
// If all tests yield the same result, return it otherwise return Bool::null.
// If no mapping is possible, 'results' has less than
// (ic_data.NumberOfChecks() * 2) entries
// An instance-of test returning all same results can be converted to a class
// check.
BoolPtr CallSpecializer::InstanceOfAsBool(
    const ICData& ic_data,
    const AbstractType& type,
    ZoneGrowableArray<intptr_t>* results) const {
  ASSERT(results->is_empty());
  ASSERT(ic_data.NumArgsTested() == 1);  // Unary checks only.
  if (type.IsFunctionType() || type.IsDartFunctionType() ||
      type.IsRecordType() || !type.IsInstantiated()) {
    return Bool::null();
  }
  const Class& type_class = Class::Handle(Z, type.type_class());
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const TypeArguments& type_arguments =
        TypeArguments::Handle(Z, Type::Cast(type).arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
                             type_arguments.IsRaw(0, type_arguments.Length());
    if (!is_raw_type) {
      // Unknown result.
      return Bool::null();
    }
  }

  const ClassTable& class_table = *IG->class_table();
  Bool& prev = Bool::Handle(Z);
  Class& cls = Class::Handle(Z);

  bool results_differ = false;
  const intptr_t number_of_checks = ic_data.NumberOfChecks();
  for (int i = 0; i < number_of_checks; i++) {
    cls = class_table.At(ic_data.GetReceiverClassIdAt(i));
    if (cls.NumTypeArguments() > 0) {
      return Bool::null();
    }
    bool is_subtype = false;
    if (cls.IsNullClass()) {
      // 'null' is an instance of Null, Object*, Never*, void, and dynamic.
      // In addition, 'null' is an instance of any nullable type.
      // It is also an instance of FutureOr<T> if it is an instance of T.
      const AbstractType& unwrapped_type =
          AbstractType::Handle(type.UnwrapFutureOr());
      ASSERT(unwrapped_type.IsInstantiated());
      is_subtype = unwrapped_type.IsTopTypeForInstanceOf() ||
                   unwrapped_type.IsNullable();
    } else {
      is_subtype =
          Class::IsSubtypeOf(cls, Object::null_type_arguments(),
                             Nullability::kNonNullable, type, Heap::kOld);
    }
    results->Add(cls.id());
    results->Add(static_cast<intptr_t>(is_subtype));
    if (prev.IsNull()) {
      prev = Bool::Get(is_subtype).ptr();
    } else {
      if (is_subtype != prev.value()) {
        results_differ = true;
      }
    }
  }
  return results_differ ? Bool::null() : prev.ptr();
}

// Returns true if checking against this type is a direct class id comparison.
bool CallSpecializer::TypeCheckAsClassEquality(const AbstractType& type,
                                               intptr_t* type_cid) {
  *type_cid = kIllegalCid;
  ASSERT(type.IsFinalized());
  // Requires CHA.
  if (!type.IsInstantiated()) return false;
  // Function and record types have different type checking rules.
  if (type.IsFunctionType() || type.IsRecordType()) return false;

  const Class& type_class = Class::Handle(type.type_class());
  if (!CHA::HasSingleConcreteImplementation(type_class, type_cid)) {
    return false;
  }

  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const TypeArguments& type_arguments =
        TypeArguments::Handle(Type::Cast(type).arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
                             type_arguments.IsRaw(0, type_arguments.Length());
    if (!is_raw_type) {
      return false;
    }
  }
  if (type.IsNullable() || type.IsTopTypeForInstanceOf() ||
      type.IsNeverType()) {
    // A class id check is not sufficient, since a null instance also satisfies
    // the test against a nullable type.
    // TODO(regis): Add a null check in addition to the class id check?
    return false;
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
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));
  if (!type.IsInstantiated()) {
    return false;
  }

  Value* left_value = call->Receiver();
  if (left_value->Type()->IsInstanceOf(type)) {
    ConstantInstr* replacement = flow_graph()->GetConstant(Bool::True());
    call->ReplaceUsesWith(replacement);
    ASSERT(current_iterator()->Current() == call);
    current_iterator()->RemoveCurrentFromGraph();
    return true;
  }

  // The goal is to emit code that will determine the result of 'x is type'
  // depending solely on the fact that x == null or not.
  // Checking whether the receiver is null can only help if the tested type is
  // non-nullable or legacy (including Never*) or the Null type.
  // Also, testing receiver for null cannot help with FutureOr.
  if ((type.IsNullable() && !type.IsNullType()) || type.IsFutureOrType()) {
    return false;
  }

  // If type is Null or the static type of the receiver is a
  // subtype of the tested type, replace 'receiver is type' with
  //  - 'receiver == null' if type is Null,
  //  - 'receiver != null' otherwise.
  if (type.IsNullType() || left_value->Type()->IsSubtypeOf(type)) {
    Definition* replacement = new (Z) StrictCompareInstr(
        call->source(),
        type.IsNullType() ? Token::kEQ_STRICT : Token::kNE_STRICT,
        left_value->CopyWithType(Z),
        new (Z) Value(flow_graph()->constant_null()),
        /* number_check = */ false, DeoptId::kNone);
    if (FLAG_trace_strong_mode_types) {
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
  Definition* instantiator_type_args = nullptr;
  Definition* function_type_args = nullptr;
  AbstractType& type = AbstractType::ZoneHandle(Z);
  ASSERT(call->type_args_len() == 0);
  if (call->ArgumentCount() == 2) {
    instantiator_type_args = flow_graph()->constant_null();
    function_type_args = flow_graph()->constant_null();
    ASSERT(call->MatchesCoreName(Symbols::_simpleInstanceOf()));
    type = AbstractType::Cast(call->ArgumentAt(1)->AsConstant()->value()).ptr();
  } else {
    ASSERT(call->ArgumentCount() == 4);
    instantiator_type_args = call->ArgumentAt(1);
    function_type_args = call->ArgumentAt(2);
    type = AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value()).ptr();
  }

  if (TryOptimizeInstanceOfUsingStaticTypes(call, type)) {
    return;
  }

  intptr_t type_cid;
  if (TypeCheckAsClassEquality(type, &type_cid)) {
    LoadClassIdInstr* load_cid =
        new (Z) LoadClassIdInstr(new (Z) Value(left), kUnboxedUword);
    InsertBefore(call, load_cid, nullptr, FlowGraph::kValue);
    ConstantInstr* constant_cid = flow_graph()->GetConstant(
        Smi::Handle(Z, Smi::New(type_cid)), kUnboxedUword);
    EqualityCompareInstr* check_cid = new (Z)
        EqualityCompareInstr(call->source(), Token::kEQ, new Value(load_cid),
                             new Value(constant_cid), kUnboxedUword,
                             DeoptId::kNone, /*null_aware=*/false);
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
    if (as_bool.IsNull() || CompilerState::Current().is_aot()) {
      if (results->length() == number_of_checks * 2) {
        const bool can_deopt = SpecializeTestCidsForNumericTypes(results, type);
        if (can_deopt && CompilerState::Current().is_aot()) {
          // Guard against speculative inlining.
          return;
        }
        TestCidsInstr* test_cids = new (Z) TestCidsInstr(
            call->source(), Token::kIS, new (Z) Value(left), *results,
            can_deopt ? call->deopt_id() : DeoptId::kNone);
        // Remove type.
        ReplaceCall(call, test_cids);
        return;
      }
    } else {
      // One result only.
      AddReceiverCheck(call);
      ConstantInstr* bool_const = flow_graph()->GetConstant(as_bool);
      ASSERT(!call->HasMoveArguments());
      call->ReplaceUsesWith(bool_const);
      ASSERT(current_iterator()->Current() == call);
      current_iterator()->RemoveCurrentFromGraph();
      return;
    }
  }

  InstanceOfInstr* instance_of = new (Z) InstanceOfInstr(
      call->source(), new (Z) Value(left),
      new (Z) Value(instantiator_type_args), new (Z) Value(function_type_args),
      type, call->deopt_id());
  ReplaceCall(call, instance_of);
}

void CallSpecializer::VisitStaticCall(StaticCallInstr* call) {
  if (TryReplaceStaticCallWithInline(flow_graph_, current_iterator(), call)) {
    return;
  }

  if (!CompilerState::Current().is_aot()) {
    // Only if speculative inlining is enabled.

    MethodRecognizer::Kind recognized_kind = call->function().recognized_kind();
    const CallTargets& targets = call->Targets();
    const BinaryFeedback& binary_feedback = call->BinaryFeedback();

    switch (recognized_kind) {
      case MethodRecognizer::kDoubleFromInteger: {
        if (call->HasICData() && targets.IsMonomorphic() &&
            (call->FirstArgIndex() == 0)) {
          if (binary_feedback.ArgumentIs(kSmiCid)) {
            Definition* arg = call->ArgumentAt(1);
            AddCheckSmi(arg, call->deopt_id(), call->env(), call);
            ReplaceCall(call, new (Z) SmiToDoubleInstr(new (Z) Value(arg),
                                                       call->source()));
            return;
          } else if (binary_feedback.ArgumentIs(kMintCid) &&
                     CanConvertInt64ToDouble()) {
            Definition* arg = call->ArgumentAt(1);
            ReplaceCall(call, new (Z) Int64ToDoubleInstr(new (Z) Value(arg),
                                                         call->deopt_id()));
            return;
          }
        }
        break;
      }

      default:
        break;
    }
  }

  if (TryOptimizeStaticCallUsingStaticTypes(call)) {
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
    results->Add(static_cast<intptr_t>(result));
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
  const ClassTable& class_table = *IsolateGroup::Current()->class_table();
  if ((*results)[0] != kSmiCid) {
    const Class& smi_class = Class::Handle(class_table.At(kSmiCid));
    const bool smi_is_subtype =
        Class::IsSubtypeOf(smi_class, Object::null_type_arguments(),
                           Nullability::kNonNullable, type, Heap::kOld);
    results->Add((*results)[results->length() - 2]);
    results->Add((*results)[results->length() - 2]);
    for (intptr_t i = results->length() - 3; i > 1; --i) {
      (*results)[i] = (*results)[i - 2];
    }
    (*results)[0] = kSmiCid;
    (*results)[1] = static_cast<intptr_t>(smi_is_subtype);
  }

  ASSERT(type.IsInstantiated());
  ASSERT(results->length() >= 2);
  if (type.IsSmiType()) {
    ASSERT((*results)[0] == kSmiCid);
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsIntType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    // Cannot deoptimize since all tests returning true have been added.
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsNumberType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
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

void TypedDataSpecializer::Optimize(FlowGraph* flow_graph) {
  TypedDataSpecializer optimizer(flow_graph);
  optimizer.VisitBlocks();
}

void TypedDataSpecializer::EnsureIsInitialized() {
  if (initialized_) return;

  initialized_ = true;

  int_type_ = Type::IntType();
  double_type_ = Type::Double();
  float32x4_type_ = Type::Float32x4();
  int32x4_type_ = Type::Int32x4();
  float64x2_type_ = Type::Float64x2();

  const auto& typed_data = Library::Handle(
      Z, Library::LookupLibrary(thread_, Symbols::DartTypedData()));

  auto& td_class = Class::Handle(Z);
  auto& direct_implementors = GrowableObjectArray::Handle(Z);
  SafepointReadRwLocker ml(thread_, thread_->isolate_group()->program_lock());

#define INIT_HANDLE(iface, type, cid)                                          \
  td_class = typed_data.LookupClass(Symbols::iface());                         \
  ASSERT(!td_class.IsNull());                                                  \
  direct_implementors = td_class.direct_implementors();                        \
  typed_data_variants_[k##iface##Index].array_type = td_class.RareType();      \
  typed_data_variants_[k##iface##Index].array_cid = cid;                       \
  typed_data_variants_[k##iface##Index].element_type = type.ptr();

  PUBLIC_TYPED_DATA_CLASS_LIST(INIT_HANDLE)
#undef INIT_HANDLE
}

void TypedDataSpecializer::VisitInstanceCall(InstanceCallInstr* call) {
  TryInlineCall(call);
}

void TypedDataSpecializer::VisitStaticCall(StaticCallInstr* call) {
  const Function& function = call->function();
  if (!function.is_static()) {
    ASSERT(call->ArgumentCount() > 0);
    TryInlineCall(call);
  }
}

void TypedDataSpecializer::TryInlineCall(TemplateDartCall<0>* call) {
  const bool is_length_getter = call->Selector() == Symbols::GetLength().ptr();
  const bool is_index_get = call->Selector() == Symbols::IndexToken().ptr();
  const bool is_index_set =
      call->Selector() == Symbols::AssignIndexToken().ptr();

  if (!(is_length_getter || is_index_get || is_index_set)) {
    return;
  }

  EnsureIsInitialized();

  const intptr_t receiver_index = call->FirstArgIndex();

  CompileType* receiver_type =
      call->ArgumentValueAt(receiver_index + 0)->Type();

  CompileType* index_type = nullptr;
  if (is_index_get || is_index_set) {
    index_type = call->ArgumentValueAt(receiver_index + 1)->Type();
  }

  CompileType* value_type = nullptr;
  if (is_index_set) {
    value_type = call->ArgumentValueAt(receiver_index + 2)->Type();
  }

  auto& type_class = Class::Handle(zone_);
  for (auto& variant : typed_data_variants_) {
    if (!receiver_type->IsAssignableTo(variant.array_type)) {
      continue;
    }

    if (is_length_getter) {
      type_class = variant.array_type.type_class();
      ReplaceWithLengthGetter(call);
      return;
    }

    auto const rep =
        RepresentationUtils::RepresentationOfArrayElement(variant.array_cid);
    const bool is_simd_access = rep == kUnboxedInt32x4 ||
                                rep == kUnboxedFloat32x4 ||
                                rep == kUnboxedFloat64x2;

    if (is_simd_access && !FlowGraphCompiler::SupportsUnboxedSimd128()) {
      return;
    }

    if (!index_type->IsNullableInt()) {
      return;
    }

    if (is_index_get) {
      type_class = variant.array_type.type_class();
      ReplaceWithIndexGet(call, variant.array_cid);
    } else {
      if (!value_type->IsAssignableTo(variant.element_type)) {
        return;
      }
      type_class = variant.array_type.type_class();
      ReplaceWithIndexSet(call, variant.array_cid);
    }

    return;
  }
}

void TypedDataSpecializer::ReplaceWithLengthGetter(TemplateDartCall<0>* call) {
  const intptr_t receiver_idx = call->FirstArgIndex();
  auto array = call->ArgumentAt(receiver_idx + 0);

  if (array->Type()->is_nullable()) {
    AppendNullCheck(call, &array);
  }
  Definition* length = AppendLoadLength(call, array);
  flow_graph_->ReplaceCurrentInstruction(current_iterator(), call, length);
  RefineUseTypes(length);
}

void TypedDataSpecializer::ReplaceWithIndexGet(TemplateDartCall<0>* call,
                                               classid_t cid) {
  const intptr_t receiver_idx = call->FirstArgIndex();
  auto array = call->ArgumentAt(receiver_idx + 0);
  auto index = call->ArgumentAt(receiver_idx + 1);

  if (array->Type()->is_nullable()) {
    AppendNullCheck(call, &array);
  }
  if (index->Type()->is_nullable()) {
    AppendNullCheck(call, &index);
  }
  AppendBoundsCheck(call, array, &index);
  Definition* value = AppendLoadIndexed(call, array, index, cid);
  flow_graph_->ReplaceCurrentInstruction(current_iterator(), call, value);
  RefineUseTypes(value);
}

void TypedDataSpecializer::ReplaceWithIndexSet(TemplateDartCall<0>* call,
                                               classid_t cid) {
  const intptr_t receiver_idx = call->FirstArgIndex();
  auto array = call->ArgumentAt(receiver_idx + 0);
  auto index = call->ArgumentAt(receiver_idx + 1);
  auto value = call->ArgumentAt(receiver_idx + 2);

  if (array->Type()->is_nullable()) {
    AppendNullCheck(call, &array);
  }
  if (index->Type()->is_nullable()) {
    AppendNullCheck(call, &index);
  }
  if (value->Type()->is_nullable()) {
    AppendNullCheck(call, &value);
  }
  AppendMutableCheck(call, &array);
  AppendBoundsCheck(call, array, &index);
  AppendStoreIndexed(call, array, index, value, cid);

  RELEASE_ASSERT(!call->HasUses());
  flow_graph_->ReplaceCurrentInstruction(current_iterator(), call, nullptr);
}

void TypedDataSpecializer::AppendNullCheck(TemplateDartCall<0>* call,
                                           Definition** value) {
  auto check =
      new (Z) CheckNullInstr(new (Z) Value(*value), Symbols::OptimizedOut(),
                             call->deopt_id(), call->source());
  flow_graph_->InsertBefore(call, check, call->env(), FlowGraph::kValue);

  // Use data dependency as control dependency.
  *value = check;
}

void TypedDataSpecializer::AppendMutableCheck(TemplateDartCall<0>* call,
                                              Definition** value) {
  auto check = new (Z) CheckWritableInstr(new (Z) Value(*value),
                                          call->deopt_id(), call->source());
  flow_graph_->InsertBefore(call, check, call->env(), FlowGraph::kValue);

  // Use data dependency as control dependency.
  *value = check;
}

void TypedDataSpecializer::AppendBoundsCheck(TemplateDartCall<0>* call,
                                             Definition* array,
                                             Definition** index) {
  auto omit_check =
      flow_graph_->ShouldOmitCheckBoundsIn(call->env()->function());

  auto length = new (Z) LoadFieldInstr(
      new (Z) Value(array), Slot::TypedDataBase_length(), call->source());
  flow_graph_->InsertBefore(call, length, call->env(), FlowGraph::kValue);

  auto check = new (Z) GenericCheckBoundInstr(
      new (Z) Value(length), new (Z) Value(*index), DeoptId::kNone,
      omit_check ? GenericCheckBoundInstr::Mode::kPhantom
                 : GenericCheckBoundInstr::Mode::kReal);
  flow_graph_->InsertBefore(call, check, call->env(), FlowGraph::kValue);

  // Use data dependency as control dependency.
  *index = check;
}

Definition* TypedDataSpecializer::AppendLoadLength(TemplateDartCall<0>* call,
                                                   Definition* array) {
  auto length = new (Z) LoadFieldInstr(
      new (Z) Value(array), Slot::TypedDataBase_length(), call->source());
  flow_graph_->InsertBefore(call, length, call->env(), FlowGraph::kValue);
  return length;
}

Definition* TypedDataSpecializer::AppendLoadIndexed(TemplateDartCall<0>* call,
                                                    Definition* array,
                                                    Definition* index,
                                                    classid_t cid) {
  const intptr_t element_size = TypedDataBase::ElementSizeFor(cid);
  const intptr_t index_scale = element_size;
  auto const rep = LoadIndexedInstr::ReturnRepresentation(cid);

  Definition* load = new (Z) LoadIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), /*index_unboxed=*/false,
      index_scale, cid, kAlignedAccess, call->deopt_id(), call->source());
  flow_graph_->InsertBefore(call, load, call->env(), FlowGraph::kValue);

  if (rep == kUnboxedFloat) {
    load = new (Z) FloatToDoubleInstr(new (Z) Value(load), call->deopt_id());
    flow_graph_->InsertBefore(call, load, call->env(), FlowGraph::kValue);
  }

  return load;
}

void TypedDataSpecializer::AppendStoreIndexed(TemplateDartCall<0>* call,
                                              Definition* array,
                                              Definition* index,
                                              Definition* value,
                                              classid_t cid) {
  const intptr_t element_size = TypedDataBase::ElementSizeFor(cid);
  const intptr_t index_scale = element_size;
  auto const rep = StoreIndexedInstr::ValueRepresentation(cid);

  const auto deopt_id = call->deopt_id();

  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    // Insert explicit unboxing instructions with truncation to avoid relying
    // on [SelectRepresentations] which doesn't mark them as truncating.
    value = UnboxInstr::Create(rep, new (Z) Value(value), deopt_id,
                               UnboxInstr::ValueMode::kHasValidType);
    flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
  } else if (rep == kUnboxedFloat) {
    value = new (Z) DoubleToFloatInstr(new (Z) Value(value), deopt_id);
    flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
  }

  auto store = new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(value),
      kNoStoreBarrier, /*index_unboxed=*/false, index_scale, cid,
      kAlignedAccess, DeoptId::kNone, call->source());
  flow_graph_->InsertBefore(call, store, call->env(), FlowGraph::kEffect);
}

void CallSpecializer::ReplaceInstanceCallsWithDispatchTableCalls() {
  // Only implemented for AOT.
}

// Test and obtain Smi value.
static bool IsSmiValue(Value* val, intptr_t* int_val) {
  if (val->BindsToConstant() && val->BoundConstant().IsSmi()) {
    *int_val = Smi::Cast(val->BoundConstant()).Value();
    return true;
  }
  return false;
}

// Helper to get result type from call (or nullptr otherwise).
static CompileType* ResultType(Definition* call) {
  if (auto static_call = call->AsStaticCall()) {
    return static_call->result_type();
  } else if (auto instance_call = call->AsInstanceCall()) {
    return instance_call->result_type();
  }
  return nullptr;
}

// Quick access to the current one.
#undef Z
#define Z (flow_graph->zone())

static bool InlineTypedDataIndexCheck(FlowGraph* flow_graph,
                                      Instruction* call,
                                      Definition* receiver,
                                      GraphEntryInstr* graph_entry,
                                      FunctionEntryInstr** entry,
                                      Instruction** last,
                                      Definition** result,
                                      const String& symbol) {
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  Definition* index = call->ArgumentAt(1);
  Definition* length = call->ArgumentAt(2);

  if (CompilerState::Current().is_aot()) {
    // Add a null-check in case the index argument is known to be compatible
    // but possibly nullable. We don't need to do the same for length
    // because all callers in typed_data_patch.dart retrieve the length
    // from the typed data object.
    auto* const null_check =
        new (Z) CheckNullInstr(new (Z) Value(index), symbol, call->deopt_id(),
                               call->source(), CheckNullInstr::kArgumentError);
    cursor = flow_graph->AppendTo(cursor, null_check, call->env(),
                                  FlowGraph::kEffect);
  }
  cursor = flow_graph->AppendCheckBound(cursor, length, &index,
                                        call->deopt_id(), call->env());

  *last = cursor;
  *result = index;
  return true;
}

static intptr_t PrepareInlineIndexedOp(FlowGraph* flow_graph,
                                       Instruction* call,
                                       intptr_t array_cid,
                                       Definition** array,
                                       Definition** index,
                                       Instruction** cursor) {
  // Insert array length load and bounds check.
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(*array), Slot::GetLengthFieldForArrayCid(array_cid),
      call->source());
  *cursor = flow_graph->AppendTo(*cursor, length, nullptr, FlowGraph::kValue);
  *cursor = flow_graph->AppendCheckBound(*cursor, length, index,
                                         call->deopt_id(), call->env());

  if (array_cid == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements = new (Z)
        LoadFieldInstr(new (Z) Value(*array), Slot::GrowableObjectArray_data(),
                       call->source());
    *cursor =
        flow_graph->AppendTo(*cursor, elements, nullptr, FlowGraph::kValue);
    // Load from the data from backing store which is a fixed-length array.
    *array = elements;
    array_cid = kArrayCid;
  } else if (IsExternalTypedDataClassId(array_cid)) {
    auto* const elements = new (Z) LoadFieldInstr(
        new (Z) Value(*array), Slot::PointerBase_data(),
        InnerPointerAccess::kCannotBeInnerPointer, call->source());
    *cursor =
        flow_graph->AppendTo(*cursor, elements, nullptr, FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}

static bool InlineGetIndexed(FlowGraph* flow_graph,
                             bool can_speculate,
                             bool is_dynamic_call,
                             MethodRecognizer::Kind kind,
                             Definition* call,
                             Definition* receiver,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);

  if (!can_speculate && is_dynamic_call && !index->Type()->IsInt()) {
    return false;
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  *last = *entry;

  array_cid =
      PrepareInlineIndexedOp(flow_graph, call, array_cid, &array, &index, last);

  // Array load and return.
  intptr_t index_scale = compiler::target::Instance::ElementSizeFor(array_cid);
  *result = new (Z) LoadIndexedInstr(
      new (Z) Value(array), new (Z) Value(index),
      /*index_unboxed=*/false, index_scale, array_cid, kAlignedAccess,
      call->deopt_id(), call->source(), ResultType(call));
  *last = flow_graph->AppendTo(*last, *result, call->env(), FlowGraph::kValue);

  if (LoadIndexedInstr::ReturnRepresentation(array_cid) == kUnboxedFloat) {
    *result =
        new (Z) FloatToDoubleInstr(new (Z) Value(*result), call->deopt_id());
    *last =
        flow_graph->AppendTo(*last, *result, call->env(), FlowGraph::kValue);
  }

  return true;
}

static bool InlineSetIndexed(FlowGraph* flow_graph,
                             MethodRecognizer::Kind kind,
                             const Function& target,
                             Instruction* call,
                             Definition* receiver,
                             const InstructionSource& source,
                             CallSpecializer::ExactnessInfo* exactness,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);
  auto const rep = StoreIndexedInstr::ValueRepresentation(array_cid);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  *last = *entry;

  bool is_unchecked_call = false;
  if (StaticCallInstr* static_call = call->AsStaticCall()) {
    is_unchecked_call =
        static_call->entry_kind() == Code::EntryKind::kUnchecked;
  } else if (InstanceCallInstr* instance_call = call->AsInstanceCall()) {
    is_unchecked_call =
        instance_call->entry_kind() == Code::EntryKind::kUnchecked;
  } else if (PolymorphicInstanceCallInstr* instance_call =
                 call->AsPolymorphicInstanceCall()) {
    is_unchecked_call =
        instance_call->entry_kind() == Code::EntryKind::kUnchecked;
  }

  if (!is_unchecked_call &&
      (kind != MethodRecognizer::kObjectArraySetIndexedUnchecked &&
       kind != MethodRecognizer::kGrowableArraySetIndexedUnchecked)) {
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const AbstractType& value_type =
        AbstractType::ZoneHandle(Z, target.ParameterTypeAt(2));
    Definition* type_args = nullptr;
    if (rep == kTagged) {
      const Class& instantiator_class = Class::Handle(Z, target.Owner());
      LoadFieldInstr* load_type_args =
          new (Z) LoadFieldInstr(new (Z) Value(array),
                                 Slot::GetTypeArgumentsSlotFor(
                                     flow_graph->thread(), instantiator_class),
                                 call->source());
      *last = flow_graph->AppendTo(*last, load_type_args, call->env(),
                                   FlowGraph::kValue);
      type_args = load_type_args;
    } else if (!RepresentationUtils::IsUnboxed(rep)) {
      UNREACHABLE();
    } else {
      type_args = flow_graph->constant_null();
      ASSERT(value_type.IsInstantiated());
#if defined(DEBUG)
      if (rep == kUnboxedFloat || rep == kUnboxedDouble) {
        ASSERT(value_type.IsDoubleType());
      } else if (rep == kUnboxedFloat32x4) {
        ASSERT(value_type.IsFloat32x4Type());
      } else if (rep == kUnboxedInt32x4) {
        ASSERT(value_type.IsInt32x4Type());
      } else if (rep == kUnboxedFloat64x2) {
        ASSERT(value_type.IsFloat64x2Type());
      } else {
        ASSERT(RepresentationUtils::IsUnboxedInteger(rep));
        ASSERT(value_type.IsIntType());
      }
#endif
    }

    if (exactness != nullptr && exactness->is_exact) {
      exactness->emit_exactness_guard = true;
    } else {
      auto const function_type_args = flow_graph->constant_null();
      auto const dst_type = flow_graph->GetConstant(value_type);
      AssertAssignableInstr* assert_value = new (Z) AssertAssignableInstr(
          source, new (Z) Value(stored_value), new (Z) Value(dst_type),
          new (Z) Value(type_args), new (Z) Value(function_type_args),
          Symbols::Value(), call->deopt_id());
      *last = flow_graph->AppendSpeculativeTo(*last, assert_value, call->env(),
                                              FlowGraph::kValue);
    }
  }

  array_cid =
      PrepareInlineIndexedOp(flow_graph, call, array_cid, &array, &index, last);

  const bool is_typed_data_store = IsTypedDataBaseClassId(array_cid);

  // Check if store barrier is needed. Byte arrays don't need a store barrier.
  StoreBarrierType needs_store_barrier =
      is_typed_data_store ? kNoStoreBarrier : kEmitStoreBarrier;

  if (rep == kUnboxedFloat) {
    stored_value = new (Z)
        DoubleToFloatInstr(new (Z) Value(stored_value), call->deopt_id());
    *last = flow_graph->AppendTo(*last, stored_value, call->env(),
                                 FlowGraph::kValue);
  } else if (RepresentationUtils::IsUnboxedInteger(rep)) {
    // Insert explicit unboxing instructions with truncation to avoid relying
    // on [SelectRepresentations] which doesn't mark them as truncating.
    stored_value =
        UnboxInstr::Create(rep, new (Z) Value(stored_value), call->deopt_id(),
                           UnboxInstr::ValueMode::kHasValidType);
    *last = flow_graph->AppendTo(*last, stored_value, call->env(),
                                 FlowGraph::kValue);
  }

  const intptr_t index_scale =
      compiler::target::Instance::ElementSizeFor(array_cid);
  auto* const store = new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(stored_value),
      needs_store_barrier, /*index_unboxed=*/false, index_scale, array_cid,
      kAlignedAccess, call->deopt_id(), call->source());
  *last = flow_graph->AppendTo(*last, store, call->env(), FlowGraph::kEffect);
  // We need a return value to replace uses of the original definition. However,
  // the final instruction is a use of 'void operator[]=()', so we use null.
  *result = flow_graph->constant_null();
  return true;
}

static bool InlineDoubleOp(FlowGraph* flow_graph,
                           Token::Kind op_kind,
                           Instruction* call,
                           Definition* receiver,
                           GraphEntryInstr* graph_entry,
                           FunctionEntryInstr** entry,
                           Instruction** last,
                           Definition** result) {
  Definition* left = receiver;
  Definition* right = call->ArgumentAt(1);

  if (CompilerState::Current().is_aot()) {
    if (!left->Type()->IsDouble() || !right->Type()->IsDouble()) {
      return false;
    }
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  if (!left->Type()->IsDouble()) {
    left =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(left),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    flow_graph->InsertBefore(call, left, call->env(), FlowGraph::kValue);
  }
  if (!right->Type()->IsDouble()) {
    right =
        UnboxInstr::Create(kUnboxedDouble, new (Z) Value(right),
                           call->deopt_id(), UnboxInstr::ValueMode::kCheckType);
    flow_graph->InsertBefore(call, right, call->env(), FlowGraph::kValue);
  }
  BinaryDoubleOpInstr* double_bin_op = new (Z)
      BinaryDoubleOpInstr(op_kind, new (Z) Value(left), new (Z) Value(right),
                          call->deopt_id(), call->source());
  flow_graph->AppendTo(*entry, double_bin_op, call->env(), FlowGraph::kValue);
  *last = double_bin_op;
  *result = double_bin_op->AsDefinition();

  return true;
}

static bool InlineDoubleTestOp(FlowGraph* flow_graph,
                               Instruction* call,
                               Definition* receiver,
                               MethodRecognizer::Kind kind,
                               GraphEntryInstr* graph_entry,
                               FunctionEntryInstr** entry,
                               Instruction** last,
                               Definition** result) {
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.

  DoubleTestOpInstr* double_test_op = new (Z) DoubleTestOpInstr(
      kind, new (Z) Value(receiver), call->deopt_id(), call->source());
  flow_graph->AppendTo(*entry, double_test_op, call->env(), FlowGraph::kValue);
  *last = double_test_op;
  *result = double_test_op->AsDefinition();

  return true;
}

static bool InlineGrowableArraySetter(FlowGraph* flow_graph,
                                      const Slot& field,
                                      StoreBarrierType store_barrier_type,
                                      Instruction* call,
                                      Definition* receiver,
                                      GraphEntryInstr* graph_entry,
                                      FunctionEntryInstr** entry,
                                      Instruction** last,
                                      Definition** result) {
  Definition* array = receiver;
  Definition* value = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  // This is an internal method, no need to check argument types.
  StoreFieldInstr* store =
      new (Z) StoreFieldInstr(field, new (Z) Value(array), new (Z) Value(value),
                              store_barrier_type, call->source());
  flow_graph->AppendTo(*entry, store, call->env(), FlowGraph::kEffect);
  *last = store;
  // We need a return value to replace uses of the original definition. However,
  // the last instruction is a field setter, which returns void, so we use null.
  *result = flow_graph->constant_null();

  return true;
}

static bool InlineLoadClassId(FlowGraph* flow_graph,
                              Instruction* call,
                              GraphEntryInstr* graph_entry,
                              FunctionEntryInstr** entry,
                              Instruction** last,
                              Definition** result) {
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  auto load_cid =
      new (Z) LoadClassIdInstr(call->ArgumentValueAt(0)->CopyWithType(Z));
  flow_graph->InsertBefore(call, load_cid, nullptr, FlowGraph::kValue);
  *last = load_cid;
  *result = load_cid->AsDefinition();
  return true;
}

// Returns the LoadIndexedInstr.
static Definition* PrepareInlineStringIndexOp(FlowGraph* flow_graph,
                                              Instruction* call,
                                              intptr_t cid,
                                              Definition* str,
                                              Definition* index,
                                              Instruction* cursor) {
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(str), Slot::GetLengthFieldForArrayCid(cid), str->source());
  cursor = flow_graph->AppendTo(cursor, length, nullptr, FlowGraph::kValue);

  // Bounds check.
  if (CompilerState::Current().is_aot()) {
    // Add a null-check in case the index argument is known to be compatible
    // but possibly nullable. By inserting the null-check, we can allow the
    // unbox instruction later inserted to be non-speculative.
    auto* const null_check = new (Z)
        CheckNullInstr(new (Z) Value(index), Symbols::Index(), call->deopt_id(),
                       call->source(), CheckNullInstr::kArgumentError);
    cursor = flow_graph->AppendTo(cursor, null_check, call->env(),
                                  FlowGraph::kEffect);
  }
  cursor = flow_graph->AppendCheckBound(cursor, length, &index,
                                        call->deopt_id(), call->env());

  LoadIndexedInstr* load_indexed = new (Z) LoadIndexedInstr(
      new (Z) Value(str), new (Z) Value(index), /*index_unboxed=*/false,
      compiler::target::Instance::ElementSizeFor(cid), cid, kAlignedAccess,
      call->deopt_id(), call->source());
  cursor =
      flow_graph->AppendTo(cursor, load_indexed, nullptr, FlowGraph::kValue);

  auto box = BoxInstr::Create(kUnboxedIntPtr, new Value(load_indexed));
  cursor = flow_graph->AppendTo(cursor, box, nullptr, FlowGraph::kValue);

  ASSERT(box == cursor);
  return box;
}

static bool InlineStringBaseCharAt(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   intptr_t cid,
                                   GraphEntryInstr* graph_entry,
                                   FunctionEntryInstr** entry,
                                   Instruction** last,
                                   Definition** result) {
  if (cid != kOneByteStringCid) {
    return false;
  }
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);

  OneByteStringFromCharCodeInstr* char_at = new (Z)
      OneByteStringFromCharCodeInstr(new (Z) Value((*last)->AsDefinition()));

  flow_graph->AppendTo(*last, char_at, nullptr, FlowGraph::kValue);
  *last = char_at;
  *result = char_at->AsDefinition();

  return true;
}

static bool InlineStringBaseCodeUnitAt(FlowGraph* flow_graph,
                                       Instruction* call,
                                       Definition* receiver,
                                       intptr_t cid,
                                       GraphEntryInstr* graph_entry,
                                       FunctionEntryInstr** entry,
                                       Instruction** last,
                                       Definition** result) {
  if (cid == kDynamicCid) {
    ASSERT(call->IsStaticCall());
    return false;
  } else if ((cid != kOneByteStringCid) && (cid != kTwoByteStringCid)) {
    return false;
  }
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);
  *result = (*last)->AsDefinition();

  return true;
}

// Only used for monomorphic calls.
bool CallSpecializer::TryReplaceInstanceCallWithInline(
    FlowGraph* flow_graph,
    ForwardInstructionIterator* iterator,
    InstanceCallInstr* call) {
  const CallTargets& targets = call->Targets();
  ASSERT(targets.IsMonomorphic());
  const intptr_t receiver_cid = targets.MonomorphicReceiverCid();
  const Function& target = targets.FirstTarget();
  const auto exactness = targets.MonomorphicExactness();
  ExactnessInfo exactness_info{exactness.IsExact(), false};

  FunctionEntryInstr* entry = nullptr;
  Instruction* last = nullptr;
  Definition* result = nullptr;
  if (CallSpecializer::TryInlineRecognizedMethod(
          flow_graph, receiver_cid, target, call,
          call->Receiver()->definition(), call->source(), call->ic_data(),
          /*graph_entry=*/nullptr, &entry, &last, &result, &exactness_info)) {
    // The empty Object constructor is the only case where the inlined body is
    // empty and there is no result.
    ASSERT((last != nullptr && result != nullptr) ||
           (target.recognized_kind() == MethodRecognizer::kObjectConstructor));
    // Determine if inlining instance methods needs a check.
    // StringBase.codeUnitAt is monomorphic but its implementation is selected
    // based on the receiver cid.
    FlowGraph::ToCheck check = FlowGraph::ToCheck::kNoCheck;
    if (target.is_polymorphic_target() ||
        (target.recognized_kind() == MethodRecognizer::kStringBaseCodeUnitAt)) {
      check = FlowGraph::ToCheck::kCheckCid;
    } else {
      check = flow_graph->CheckForInstanceCall(call, target.kind());
    }

    // Insert receiver class or null check if needed.
    switch (check) {
      case FlowGraph::ToCheck::kCheckCid: {
        Instruction* check_class = flow_graph->CreateCheckClass(
            call->Receiver()->definition(), targets, call->deopt_id(),
            call->source());
        flow_graph->InsertBefore(call, check_class, call->env(),
                                 FlowGraph::kEffect);
        break;
      }
      case FlowGraph::ToCheck::kCheckNull: {
        Instruction* check_null = new (Z) CheckNullInstr(
            call->Receiver()->CopyWithType(Z), call->function_name(),
            call->deopt_id(), call->source());
        flow_graph->InsertBefore(call, check_null, call->env(),
                                 FlowGraph::kEffect);
        break;
      }
      case FlowGraph::ToCheck::kNoCheck:
        break;
    }

    if (exactness_info.emit_exactness_guard && exactness.IsTriviallyExact()) {
      flow_graph->AddExactnessGuard(call, receiver_cid);
    }

    ASSERT(!call->HasMoveArguments());

    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      ASSERT(result != nullptr && result->HasSSATemp());
      call->ReplaceUsesWith(result);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry->next() != nullptr) {
      call->previous()->LinkTo(entry->next());
    }
    entry->UnuseAllInputs();  // Entry block is not in the graph.
    if (last != nullptr) {
      ASSERT(call->GetBlock() == last->GetBlock());
      last->LinkTo(call);
    }
    // Remove through the iterator.
    ASSERT(iterator->Current() == call);
    iterator->RemoveCurrentFromGraph();
    call->set_previous(nullptr);
    call->set_next(nullptr);
    return true;
  }
  return false;
}

bool CallSpecializer::TryReplaceStaticCallWithInline(
    FlowGraph* flow_graph,
    ForwardInstructionIterator* iterator,
    StaticCallInstr* call) {
  FunctionEntryInstr* entry = nullptr;
  Instruction* last = nullptr;
  Definition* result = nullptr;
  Definition* receiver = nullptr;
  intptr_t receiver_cid = kIllegalCid;
  if (!call->function().is_static()) {
    receiver = call->Receiver()->definition();
    receiver_cid = call->Receiver()->Type()->ToCid();
  }
  if (CallSpecializer::TryInlineRecognizedMethod(
          flow_graph, receiver_cid, call->function(), call, receiver,
          call->source(), call->ic_data(), /*graph_entry=*/nullptr, &entry,
          &last, &result)) {
    // The empty Object constructor is the only case where the inlined body is
    // empty and there is no result.
    ASSERT((last != nullptr && result != nullptr) ||
           (call->function().recognized_kind() ==
            MethodRecognizer::kObjectConstructor));
    ASSERT(!call->HasMoveArguments());
    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      ASSERT(result->HasSSATemp());
      call->ReplaceUsesWith(result);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry != nullptr) {
      if (entry->next() != nullptr) {
        call->previous()->LinkTo(entry->next());
      }
      entry->UnuseAllInputs();  // Entry block is not in the graph.
      if (last != nullptr) {
        BlockEntryInstr* link = call->GetBlock();
        BlockEntryInstr* exit = last->GetBlock();
        if (link != exit) {
          // Dominance relation and SSA are updated incrementally when
          // conditionals are inserted. But succ/pred and ordering needs
          // to be redone. TODO(ajcbik): do this incrementally too.
          for (intptr_t i = 0, n = link->dominated_blocks().length(); i < n;
               ++i) {
            exit->AddDominatedBlock(link->dominated_blocks()[i]);
          }
          link->ClearDominatedBlocks();
          for (intptr_t i = 0, n = entry->dominated_blocks().length(); i < n;
               ++i) {
            link->AddDominatedBlock(entry->dominated_blocks()[i]);
          }
          Instruction* scan = exit;
          while (scan->next() != nullptr) {
            scan = scan->next();
          }
          scan->LinkTo(call);
          flow_graph->DiscoverBlocks();
        } else {
          last->LinkTo(call);
        }
      }
    }
    // Remove through the iterator.
    if (iterator != nullptr) {
      ASSERT(iterator->Current() == call);
      iterator->RemoveCurrentFromGraph();
    } else {
      call->RemoveFromGraph();
    }
    return true;
  }
  return false;
}

static bool CheckMask(Definition* definition, intptr_t* mask_ptr) {
  if (!definition->IsConstant()) return false;
  ConstantInstr* constant_instruction = definition->AsConstant();
  const Object& constant_mask = constant_instruction->value();
  if (!constant_mask.IsSmi()) return false;
  const intptr_t mask = Smi::Cast(constant_mask).Value();
  if ((mask < 0) || (mask > 255)) {
    return false;  // Not a valid mask.
  }
  *mask_ptr = mask;
  return true;
}

class SimdLowering : public ValueObject {
 public:
  SimdLowering(FlowGraph* flow_graph,
               Instruction* call,
               GraphEntryInstr* graph_entry,
               FunctionEntryInstr** entry,
               Instruction** last,
               Definition** result)
      : flow_graph_(flow_graph),
        call_(call),
        graph_entry_(graph_entry),
        entry_(entry),
        last_(last),
        result_(result) {
    *entry_ = new (zone())
        FunctionEntryInstr(graph_entry_, flow_graph_->allocate_block_id(),
                           call_->GetBlock()->try_index(), call_->deopt_id());
    *last = *entry_;
  }

  bool TryInline(MethodRecognizer::Kind kind) {
    switch (kind) {
      // ==== Int32x4 ====
      case MethodRecognizer::kInt32x4FromInts:
        UnboxScalar(0, kUnboxedInt32, 4);
        UnboxScalar(1, kUnboxedInt32, 4);
        UnboxScalar(2, kUnboxedInt32, 4);
        UnboxScalar(3, kUnboxedInt32, 4);
        Gather(4);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4FromBools:
        UnboxBool(0, 4);
        UnboxBool(1, 4);
        UnboxBool(2, 4);
        UnboxBool(3, 4);
        Gather(4);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4GetFlagX:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        IntToBool();
        Return(0);
        return true;
      case MethodRecognizer::kInt32x4GetFlagY:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        IntToBool();
        Return(1);
        return true;
      case MethodRecognizer::kInt32x4GetFlagZ:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        IntToBool();
        Return(2);
        return true;
      case MethodRecognizer::kInt32x4GetFlagW:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        IntToBool();
        Return(3);
        return true;
      case MethodRecognizer::kInt32x4WithFlagX:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        UnboxBool(1, 4);
        With(0);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4WithFlagY:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        UnboxBool(1, 4);
        With(1);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4WithFlagZ:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        UnboxBool(1, 4);
        With(2);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4WithFlagW:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        UnboxBool(1, 4);
        With(3);
        BoxVector(kUnboxedInt32, 4);
        return true;
      case MethodRecognizer::kInt32x4Shuffle: {
        Definition* mask_definition =
            call_->ArgumentAt(call_->ArgumentCount() - 1);
        intptr_t mask = 0;
        if (!CheckMask(mask_definition, &mask)) {
          return false;
        }
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        Shuffle(mask);
        BoxVector(kUnboxedInt32, 4);
        return true;
      }
      case MethodRecognizer::kInt32x4ShuffleMix: {
        Definition* mask_definition =
            call_->ArgumentAt(call_->ArgumentCount() - 1);
        intptr_t mask = 0;
        if (!CheckMask(mask_definition, &mask)) {
          return false;
        }
        UnboxVector(0, kUnboxedInt32, kMintCid, 4);
        UnboxVector(1, kUnboxedInt32, kMintCid, 4);
        ShuffleMix(mask);
        BoxVector(kUnboxedInt32, 4);
        return true;
      }
      case MethodRecognizer::kInt32x4GetSignMask:
      case MethodRecognizer::kInt32x4Select:
        // TODO(riscv)
        return false;

      // ==== Float32x4 ====
      case MethodRecognizer::kFloat32x4Abs:
        Float32x4Unary(Token::kABS);
        return true;
      case MethodRecognizer::kFloat32x4Negate:
        Float32x4Unary(Token::kNEGATE);
        return true;
      case MethodRecognizer::kFloat32x4Sqrt:
        Float32x4Unary(Token::kSQRT);
        return true;
      case MethodRecognizer::kFloat32x4Reciprocal:
        Float32x4Unary(Token::kRECIPROCAL);
        return true;
      case MethodRecognizer::kFloat32x4ReciprocalSqrt:
        Float32x4Unary(Token::kRECIPROCAL_SQRT);
        return true;
      case MethodRecognizer::kFloat32x4GetSignMask:
        // TODO(riscv)
        return false;
      case MethodRecognizer::kFloat32x4Equal:
        Float32x4Compare(Token::kEQ);
        return true;
      case MethodRecognizer::kFloat32x4GreaterThan:
        Float32x4Compare(Token::kGT);
        return true;
      case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
        Float32x4Compare(Token::kGTE);
        return true;
      case MethodRecognizer::kFloat32x4LessThan:
        Float32x4Compare(Token::kLT);
        return true;
      case MethodRecognizer::kFloat32x4LessThanOrEqual:
        Float32x4Compare(Token::kLTE);
        return true;
      case MethodRecognizer::kFloat32x4Add:
        Float32x4Binary(Token::kADD);
        return true;
      case MethodRecognizer::kFloat32x4Sub:
        Float32x4Binary(Token::kSUB);
        return true;
      case MethodRecognizer::kFloat32x4Mul:
        Float32x4Binary(Token::kMUL);
        return true;
      case MethodRecognizer::kFloat32x4Div:
        Float32x4Binary(Token::kDIV);
        return true;
      case MethodRecognizer::kFloat32x4Min:
        Float32x4Binary(Token::kMIN);
        return true;
      case MethodRecognizer::kFloat32x4Max:
        Float32x4Binary(Token::kMAX);
        return true;
      case MethodRecognizer::kFloat32x4Scale:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        BinaryDoubleOp(Token::kMUL, kUnboxedFloat, 4);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4Splat:
        UnboxScalar(0, kUnboxedFloat, 4);
        Splat(4);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4WithX:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        With(0);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4WithY:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        With(1);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4WithZ:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        With(2);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4WithW:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        With(3);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4Zero:
        UnboxDoubleZero(kUnboxedFloat, 4);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4FromDoubles:
        UnboxScalar(0, kUnboxedFloat, 4);
        UnboxScalar(1, kUnboxedFloat, 4);
        UnboxScalar(2, kUnboxedFloat, 4);
        UnboxScalar(3, kUnboxedFloat, 4);
        Gather(4);
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4GetX:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        BoxScalar(0, kUnboxedFloat);
        return true;
      case MethodRecognizer::kFloat32x4GetY:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        BoxScalar(1, kUnboxedFloat);
        return true;
      case MethodRecognizer::kFloat32x4GetZ:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        BoxScalar(2, kUnboxedFloat);
        return true;
      case MethodRecognizer::kFloat32x4GetW:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        BoxScalar(3, kUnboxedFloat);
        return true;
      case MethodRecognizer::kFloat32x4Shuffle: {
        Definition* mask_definition =
            call_->ArgumentAt(call_->ArgumentCount() - 1);
        intptr_t mask = 0;
        if (!CheckMask(mask_definition, &mask)) {
          return false;
        }
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        Shuffle(mask);
        BoxVector(kUnboxedFloat, 4);
        return true;
      }
      case MethodRecognizer::kFloat32x4ShuffleMix: {
        Definition* mask_definition =
            call_->ArgumentAt(call_->ArgumentCount() - 1);
        intptr_t mask = 0;
        if (!CheckMask(mask_definition, &mask)) {
          return false;
        }
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
        UnboxVector(1, kUnboxedFloat, kDoubleCid, 4);
        ShuffleMix(mask);
        BoxVector(kUnboxedFloat, 4);
        return true;
      }

      // ==== Float64x2 ====
      case MethodRecognizer::kFloat64x2Abs:
        Float64x2Unary(Token::kABS);
        return true;
      case MethodRecognizer::kFloat64x2Negate:
        Float64x2Unary(Token::kNEGATE);
        return true;
      case MethodRecognizer::kFloat64x2Sqrt:
        Float64x2Unary(Token::kSQRT);
        return true;
      case MethodRecognizer::kFloat64x2Add:
        Float64x2Binary(Token::kADD);
        return true;
      case MethodRecognizer::kFloat64x2Sub:
        Float64x2Binary(Token::kSUB);
        return true;
      case MethodRecognizer::kFloat64x2Mul:
        Float64x2Binary(Token::kMUL);
        return true;
      case MethodRecognizer::kFloat64x2Div:
        Float64x2Binary(Token::kDIV);
        return true;
      case MethodRecognizer::kFloat64x2Min:
        Float64x2Binary(Token::kMIN);
        return true;
      case MethodRecognizer::kFloat64x2Max:
        Float64x2Binary(Token::kMAX);
        return true;
      case MethodRecognizer::kFloat64x2Scale:
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
        UnboxScalar(1, kUnboxedDouble, 2);
        BinaryDoubleOp(Token::kMUL, kUnboxedDouble, 2);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2Splat:
        UnboxScalar(0, kUnboxedDouble, 2);
        Splat(2);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2WithX:
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
        UnboxScalar(1, kUnboxedDouble, 2);
        With(0);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2WithY:
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
        UnboxScalar(1, kUnboxedDouble, 2);
        With(1);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2Zero:
        UnboxDoubleZero(kUnboxedDouble, 2);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2FromDoubles:
        UnboxScalar(0, kUnboxedDouble, 2);
        UnboxScalar(1, kUnboxedDouble, 2);
        Gather(2);
        BoxVector(kUnboxedDouble, 2);
        return true;
      case MethodRecognizer::kFloat64x2GetX:
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
        BoxScalar(0, kUnboxedDouble);
        return true;
      case MethodRecognizer::kFloat64x2GetY:
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
        BoxScalar(1, kUnboxedDouble);
        return true;

      // Mixed
      case MethodRecognizer::kFloat32x4ToFloat64x2: {
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4, 1);
        Float32x4ToFloat64x2();
        BoxVector(kUnboxedDouble, 2);
        return true;
      }
      case MethodRecognizer::kFloat64x2ToFloat32x4: {
        UnboxVector(0, kUnboxedDouble, kDoubleCid, 2, 1);
        Float64x2ToFloat32x4();
        BoxVector(kUnboxedFloat, 4);
        return true;
      }
      case MethodRecognizer::kInt32x4ToFloat32x4:
        UnboxVector(0, kUnboxedInt32, kMintCid, 4, 1);
        Int32x4ToFloat32x4();
        BoxVector(kUnboxedFloat, 4);
        return true;
      case MethodRecognizer::kFloat32x4ToInt32x4:
        UnboxVector(0, kUnboxedFloat, kDoubleCid, 4, 1);
        Float32x4ToInt32x4();
        BoxVector(kUnboxedInt32, 4);
        return true;
      default:
        return false;
    }
  }

 private:
  void Float32x4Unary(Token::Kind op) {
    UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
    UnaryDoubleOp(op, kUnboxedFloat, 4);
    BoxVector(kUnboxedFloat, 4);
  }
  void Float32x4Binary(Token::Kind op) {
    UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
    UnboxVector(1, kUnboxedFloat, kDoubleCid, 4);
    BinaryDoubleOp(op, kUnboxedFloat, 4);
    BoxVector(kUnboxedFloat, 4);
  }
  void Float32x4Compare(Token::Kind op) {
    UnboxVector(0, kUnboxedFloat, kDoubleCid, 4);
    UnboxVector(1, kUnboxedFloat, kDoubleCid, 4);
    FloatCompare(op);
    BoxVector(kUnboxedInt32, 4);
  }
  void Float64x2Unary(Token::Kind op) {
    UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
    UnaryDoubleOp(op, kUnboxedDouble, 2);
    BoxVector(kUnboxedDouble, 2);
  }
  void Float64x2Binary(Token::Kind op) {
    UnboxVector(0, kUnboxedDouble, kDoubleCid, 2);
    UnboxVector(1, kUnboxedDouble, kDoubleCid, 2);
    BinaryDoubleOp(op, kUnboxedDouble, 2);
    BoxVector(kUnboxedDouble, 2);
  }

  void UnboxVector(intptr_t i,
                   Representation rep,
                   intptr_t cid,
                   intptr_t n,
                   intptr_t type_args = 0) {
    Definition* arg = call_->ArgumentAt(i + type_args);
    if (CompilerState::Current().is_aot()) {
      // Add null-checks in case of the arguments are known to be compatible
      // but they are possibly nullable.
      // By inserting the null-check, we can allow the unbox instruction later
      // inserted to be non-speculative.
      arg = AddDefinition(new (zone()) CheckNullInstr(
          new (zone()) Value(arg), Symbols::SecondArg(), call_->deopt_id(),
          call_->source(), CheckNullInstr::kArgumentError));
    }
    for (intptr_t lane = 0; lane < n; lane++) {
      in_[i][lane] = AddDefinition(
          new (zone()) UnboxLaneInstr(new (zone()) Value(arg), lane, rep, cid));
    }
  }

  void UnboxScalar(intptr_t i,
                   Representation rep,
                   intptr_t n,
                   intptr_t type_args = 0) {
    Definition* arg = call_->ArgumentAt(i + type_args);
    if (CompilerState::Current().is_aot()) {
      // Add null-checks in case of the arguments are known to be compatible
      // but they are possibly nullable.
      // By inserting the null-check, we can allow the unbox instruction later
      // inserted to be non-speculative.
      arg = AddDefinition(new (zone()) CheckNullInstr(
          new (zone()) Value(arg), Symbols::SecondArg(), call_->deopt_id(),
          call_->source(), CheckNullInstr::kArgumentError));
    }
    Definition* unbox = AddDefinition(
        UnboxInstr::Create(rep, new (zone()) Value(arg), DeoptId::kNone,
                           UnboxInstr::ValueMode::kHasValidType));
    for (intptr_t lane = 0; lane < n; lane++) {
      in_[i][lane] = unbox;
    }
  }

  void UnboxBool(intptr_t i, intptr_t n) {
    Definition* unbox = AddDefinition(new (zone()) BoolToIntInstr(
        call_->ArgumentValueAt(i)->CopyWithType(zone())));
    for (intptr_t lane = 0; lane < n; lane++) {
      in_[i][lane] = unbox;
    }
  }

  void UnboxDoubleZero(Representation rep, intptr_t n) {
    Definition* zero = flow_graph_->GetConstant(
        Double::ZoneHandle(Double::NewCanonical(0.0)), rep);
    for (intptr_t lane = 0; lane < n; lane++) {
      op_[lane] = zero;
    }
  }

  void UnaryDoubleOp(Token::Kind op, Representation rep, intptr_t n) {
    for (intptr_t lane = 0; lane < n; lane++) {
      op_[lane] = AddDefinition(new (zone()) UnaryDoubleOpInstr(
          op, new (zone()) Value(in_[0][lane]), call_->deopt_id(), rep));
    }
  }

  void BinaryDoubleOp(Token::Kind op, Representation rep, intptr_t n) {
    for (intptr_t lane = 0; lane < n; lane++) {
      op_[lane] = AddDefinition(new (zone()) BinaryDoubleOpInstr(
          op, new (zone()) Value(in_[0][lane]),
          new (zone()) Value(in_[1][lane]), call_->deopt_id(), call_->source(),
          rep));
    }
  }

  void FloatCompare(Token::Kind op) {
    for (intptr_t lane = 0; lane < 4; lane++) {
      op_[lane] = AddDefinition(
          new (zone()) FloatCompareInstr(op, new (zone()) Value(in_[0][lane]),
                                         new (zone()) Value(in_[1][lane])));
    }
  }

  void With(intptr_t i) {
    for (intptr_t lane = 0; lane < 4; lane++) {
      op_[lane] = in_[0][lane];
    }
    op_[i] = in_[1][0];
  }
  void Splat(intptr_t n) {
    for (intptr_t lane = 0; lane < n; lane++) {
      op_[lane] = in_[0][0];
    }
  }
  void Gather(intptr_t n) {
    for (intptr_t lane = 0; lane < n; lane++) {
      op_[lane] = in_[lane][0];
    }
  }
  void Shuffle(intptr_t mask) {
    op_[0] = in_[0][(mask >> 0) & 3];
    op_[1] = in_[0][(mask >> 2) & 3];
    op_[2] = in_[0][(mask >> 4) & 3];
    op_[3] = in_[0][(mask >> 6) & 3];
  }
  void ShuffleMix(intptr_t mask) {
    op_[0] = in_[0][(mask >> 0) & 3];
    op_[1] = in_[0][(mask >> 2) & 3];
    op_[2] = in_[1][(mask >> 4) & 3];
    op_[3] = in_[1][(mask >> 6) & 3];
  }
  void Float32x4ToFloat64x2() {
    for (intptr_t lane = 0; lane < 2; lane++) {
      op_[lane] = AddDefinition(new (zone()) FloatToDoubleInstr(
          new (zone()) Value(in_[0][lane]), DeoptId::kNone));
    }
  }
  void Float64x2ToFloat32x4() {
    for (intptr_t lane = 0; lane < 2; lane++) {
      op_[lane] = AddDefinition(new (zone()) DoubleToFloatInstr(
          new (zone()) Value(in_[0][lane]), DeoptId::kNone));
    }
    Definition* zero = flow_graph_->GetConstant(
        Double::ZoneHandle(Double::NewCanonical(0.0)), kUnboxedFloat);
    op_[2] = zero;
    op_[3] = zero;
  }
  void Int32x4ToFloat32x4() {
    for (intptr_t lane = 0; lane < 4; lane++) {
      op_[lane] = AddDefinition(new (zone()) BitCastInstr(
          kUnboxedInt32, kUnboxedFloat, new (zone()) Value(in_[0][lane])));
    }
  }
  void Float32x4ToInt32x4() {
    for (intptr_t lane = 0; lane < 4; lane++) {
      op_[lane] = AddDefinition(new (zone()) BitCastInstr(
          kUnboxedFloat, kUnboxedInt32, new (zone()) Value(in_[0][lane])));
    }
  }
  void IntToBool() {
    for (intptr_t lane = 0; lane < 4; lane++) {
      op_[lane] = AddDefinition(
          new (zone()) IntToBoolInstr(new (zone()) Value(in_[0][lane])));
    }
  }

  void BoxVector(Representation rep, intptr_t n) {
    Definition* box;
    if (n == 2) {
      box = new (zone()) BoxLanesInstr(rep, new (zone()) Value(op_[0]),
                                       new (zone()) Value(op_[1]));
    } else {
      ASSERT(n == 4);
      box = new (zone()) BoxLanesInstr(
          rep, new (zone()) Value(op_[0]), new (zone()) Value(op_[1]),
          new (zone()) Value(op_[2]), new (zone()) Value(op_[3]));
    }
    Done(AddDefinition(box));
  }

  void BoxScalar(intptr_t lane, Representation rep) {
    Definition* box = BoxInstr::Create(rep, new (zone()) Value(in_[0][lane]));
    Done(AddDefinition(box));
  }

  void Return(intptr_t lane) { Done(op_[lane]); }

  void Done(Definition* result) {
    // InheritDeoptTarget also inherits environment (which may add 'entry' into
    // env_use_list()), so InheritDeoptTarget should be done only after decided
    // to inline.
    (*entry_)->InheritDeoptTarget(zone(), call_);
    *result_ = result;
  }

  Definition* AddDefinition(Definition* def) {
    *last_ = flow_graph_->AppendTo(
        *last_, def, call_->deopt_id() != DeoptId::kNone ? call_->env() : NULL,
        FlowGraph::kValue);
    return def;
  }
  Zone* zone() { return flow_graph_->zone(); }

  FlowGraph* flow_graph_;
  Instruction* call_;
  GraphEntryInstr* graph_entry_;
  FunctionEntryInstr** entry_;
  Instruction** last_;
  Definition** result_;

  // First index is the argment number, second index is the lane number.
  Definition* in_[4][4];
  // Index is the lane number.
  Definition* op_[4];
};

static bool InlineSimdOp(FlowGraph* flow_graph,
                         bool is_dynamic_call,
                         Instruction* call,
                         Definition* receiver,
                         MethodRecognizer::Kind kind,
                         GraphEntryInstr* graph_entry,
                         FunctionEntryInstr** entry,
                         Instruction** last,
                         Definition** result) {
  if (is_dynamic_call && call->ArgumentCount() > 1) {
    // Issue(dartbug.com/37737): Dynamic invocation forwarders have the
    // same recognized kind as the method they are forwarding to.
    // That causes us to inline the recognized method and not the
    // dyn: forwarder itself.
    // This is only safe if all arguments are checked in the flow graph we
    // build.
    // For double/int arguments speculative unboxing instructions should ensure
    // to bailout in AOT (or deoptimize in JIT) if the incoming values are not
    // correct. Though for user-implementable types, like
    // operator+(Float32x4 other), this is not safe and we therefore bailout.
    return false;
  }

  if (!FLAG_enable_simd_inline) {
    return false;
  }

  if (!FlowGraphCompiler::SupportsUnboxedSimd128()) {
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
    SimdLowering lowering(flow_graph, call, graph_entry, entry, last, result);
    return lowering.TryInline(kind);
#else
    return false;
#endif
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kInt32x4ShuffleMix:
    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kFloat32x4ShuffleMix: {
      Definition* mask_definition = call->ArgumentAt(call->ArgumentCount() - 1);
      intptr_t mask = 0;
      if (!CheckMask(mask_definition, &mask)) {
        return false;
      }
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call, mask);
      break;
    }

    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4WithW:
    case MethodRecognizer::kFloat32x4Scale: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      // Note: left and right values are swapped when handed to the instruction,
      // this is done so that the double value is loaded into the output
      // register and can be destroyed.
      // TODO(dartbug.com/31035) this swapping is only needed because register
      // allocator has SameAsFirstInput policy and not SameAsNthInput(n).
      *last = SimdOpInstr::Create(kind, new (Z) Value(right),
                                  new (Z) Value(left), call->deopt_id());
      break;
    }

    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat32x4ToFloat64x2:
    case MethodRecognizer::kFloat64x2ToFloat32x4:
    case MethodRecognizer::kFloat32x4ToInt32x4:
    case MethodRecognizer::kInt32x4ToFloat32x4:
    case MethodRecognizer::kFloat64x2Zero:
      *last = SimdOpInstr::CreateFromFactoryCall(Z, kind, call);
      break;
    case MethodRecognizer::kFloat32x4Mul:
    case MethodRecognizer::kFloat32x4Div:
    case MethodRecognizer::kFloat32x4Add:
    case MethodRecognizer::kFloat32x4Sub:
    case MethodRecognizer::kFloat64x2Mul:
    case MethodRecognizer::kFloat64x2Div:
    case MethodRecognizer::kFloat64x2Add:
    case MethodRecognizer::kFloat64x2Sub:
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call);
      if (CompilerState::Current().is_aot()) {
        // Add null-checks in case of the arguments are known to be compatible
        // but they are possibly nullable.
        // By inserting the null-check, we can allow the unbox instruction later
        // inserted to be non-speculative.
        CheckNullInstr* check1 =
            new (Z) CheckNullInstr(new (Z) Value(receiver), Symbols::FirstArg(),
                                   call->deopt_id(), call->source());

        CheckNullInstr* check2 = new (Z) CheckNullInstr(
            new (Z) Value(call->ArgumentAt(1)), Symbols::SecondArg(),
            call->deopt_id(), call->source(), CheckNullInstr::kArgumentError);

        (*last)->SetInputAt(0, new (Z) Value(check1));
        (*last)->SetInputAt(1, new (Z) Value(check2));

        flow_graph->InsertBefore(call, check1, call->env(), FlowGraph::kValue);
        flow_graph->InsertBefore(call, check2, call->env(), FlowGraph::kValue);
      }
      break;
    default:
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call);
      break;
  }
  // InheritDeoptTarget also inherits environment (which may add 'entry' into
  // env_use_list()), so InheritDeoptTarget should be done only after decided
  // to inline.
  (*entry)->InheritDeoptTarget(Z, call);
  flow_graph->AppendTo(
      cursor, *last, call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
      FlowGraph::kValue);
  *result = (*last)->AsDefinition();
  return true;
}

static Instruction* InlineMul(FlowGraph* flow_graph,
                              Instruction* cursor,
                              Definition* x,
                              Definition* y) {
  BinaryInt64OpInstr* mul = new (Z) BinaryInt64OpInstr(
      Token::kMUL, new (Z) Value(x), new (Z) Value(y), DeoptId::kNone);
  return flow_graph->AppendTo(cursor, mul, nullptr, FlowGraph::kValue);
}

static bool InlineMathIntPow(FlowGraph* flow_graph,
                             Instruction* call,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  // Invoking the _intPow(x, y) implies that both:
  // (1) x, y are int
  // (2) y >= 0.
  // Thus, try to inline some very obvious cases.
  // TODO(ajcbik): useful to generalize?
  intptr_t val = 0;
  Value* x = call->ArgumentValueAt(0);
  Value* y = call->ArgumentValueAt(1);
  // Use x^0 == 1, x^1 == x, and x^c == x * .. * x for small c.
  const intptr_t small_exponent = 5;
  if (IsSmiValue(y, &val)) {
    if (val == 0) {
      *last = flow_graph->GetConstant(Smi::ZoneHandle(Smi::New(1)));
      *result = (*last)->AsDefinition();
      return true;
    } else if (val == 1) {
      *last = x->definition();
      *result = (*last)->AsDefinition();
      return true;
    } else if (1 < val && val <= small_exponent) {
      // Lazily construct entry only in this case.
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      Definition* x_def = x->definition();
      Definition* square =
          InlineMul(flow_graph, *entry, x_def, x_def)->AsDefinition();
      *last = square;
      *result = square;
      switch (val) {
        case 2:
          return true;
        case 3:
          *last = InlineMul(flow_graph, *last, x_def, square);
          *result = (*last)->AsDefinition();
          return true;
        case 4:
          *last = InlineMul(flow_graph, *last, square, square);
          *result = (*last)->AsDefinition();
          return true;
        case 5:
          *last = InlineMul(flow_graph, *last, square, square);
          *last = InlineMul(flow_graph, *last, x_def, (*last)->AsDefinition());
          *result = (*last)->AsDefinition();
          return true;
      }
    }
  }
  // Use 0^y == 0 (only for y != 0) and 1^y == 1.
  if (IsSmiValue(x, &val)) {
    if (val == 1) {
      *last = x->definition();
      *result = x->definition();
      return true;
    }
  }
  return false;
}

static bool InlineMathMinMax(MethodRecognizer::Kind kind,
                             FlowGraph* flow_graph,
                             Instruction* call,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  intptr_t i = call->AsStaticCall()->FirstArgIndex();
  if (call->ArgumentValueAt(i + 0)->Type()->IsDouble() &&
      call->ArgumentValueAt(i + 1)->Type()->IsDouble()) {
    *last = *entry = new (Z)
        FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                           call->GetBlock()->try_index(), DeoptId::kNone);
    *result = new (Z) MathMinMaxInstr(
        kind, new (Z) Value(call->ArgumentAt(i + 0)),
        new (Z) Value(call->ArgumentAt(i + 1)), DeoptId::kNone, kUnboxedDouble);
    flow_graph->AppendTo(
        *last, *result,
        call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
        FlowGraph::kValue);
    *last = *result;
    return true;
  }
#if defined(TARGET_ARCH_IS_64_BIT)
  if (call->ArgumentValueAt(i + 0)->Type()->IsInt() &&
      call->ArgumentValueAt(i + 1)->Type()->IsInt()) {
    *last = *entry = new (Z)
        FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                           call->GetBlock()->try_index(), DeoptId::kNone);
    *result = new (Z) MathMinMaxInstr(
        kind, new (Z) Value(call->ArgumentAt(i + 0)),
        new (Z) Value(call->ArgumentAt(i + 1)), DeoptId::kNone, kUnboxedInt64);
    flow_graph->AppendTo(
        *last, *result,
        call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
        FlowGraph::kValue);
    *last = *result;
    return true;
  }
#endif
  return false;
}

bool CallSpecializer::TryInlineRecognizedMethod(
    FlowGraph* flow_graph,
    intptr_t receiver_cid,
    const Function& target,
    Definition* call,
    Definition* receiver,
    const InstructionSource& source,
    const ICData* ic_data,
    GraphEntryInstr* graph_entry,
    FunctionEntryInstr** entry,
    Instruction** last,
    Definition** result,
    CallSpecializer::ExactnessInfo* exactness) {
  COMPILER_TIMINGS_TIMER_SCOPE(flow_graph->thread(), InlineRecognizedMethod);

  if (receiver_cid == kSentinelCid) {
    // Receiver was defined in dead code and was replaced by the sentinel.
    // Original receiver cid is lost, so don't try to inline recognized
    // methods.
    return false;
  }

  const bool can_speculate = !CompilerState::Current().is_aot() ||
                             (receiver == nullptr) ||
                             (receiver->Type()->ToCid() == receiver_cid);
  const bool is_dynamic_call = Function::IsDynamicInvocationForwarderName(
      String::Handle(flow_graph->zone(), target.name()));

  const MethodRecognizer::Kind kind = target.recognized_kind();
  switch (kind) {
    case MethodRecognizer::kTypedDataIndexCheck:
      return InlineTypedDataIndexCheck(flow_graph, call, receiver, graph_entry,
                                       entry, last, result, Symbols::Index());
    case MethodRecognizer::kByteDataByteOffsetCheck:
      return InlineTypedDataIndexCheck(flow_graph, call, receiver, graph_entry,
                                       entry, last, result,
                                       Symbols::byteOffset());
    // Recognized [] operators.
    case MethodRecognizer::kObjectArrayGetIndexed:
    case MethodRecognizer::kGrowableArrayGetIndexed:
    case MethodRecognizer::kInt8ArrayGetIndexed:
    case MethodRecognizer::kUint8ArrayGetIndexed:
    case MethodRecognizer::kUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kInt16ArrayGetIndexed:
    case MethodRecognizer::kUint16ArrayGetIndexed:
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArrayGetIndexed:
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArrayGetIndexed:
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kInt64ArrayGetIndexed:
    case MethodRecognizer::kUint64ArrayGetIndexed:
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kClassIDgetID:
      return InlineLoadClassId(flow_graph, call, graph_entry, entry, last,
                               result);
    case MethodRecognizer::kMathMin:
    case MethodRecognizer::kMathMax:
      return InlineMathMinMax(kind, flow_graph, call, graph_entry, entry, last,
                              result);
    default:
      break;
  }

  // The following ones need to speculate.
  if (!can_speculate) {
    return false;
  }

  switch (kind) {
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
      // These require clamping. Just inline normal body instead which
      // contains necessary clamping code.
      return false;

    // Recognized []= operators.
    case MethodRecognizer::kObjectArraySetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
    case MethodRecognizer::kObjectArraySetIndexedUnchecked:
    case MethodRecognizer::kGrowableArraySetIndexedUnchecked:
    case MethodRecognizer::kInt8ArraySetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed:
    case MethodRecognizer::kInt32ArraySetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed:
    case MethodRecognizer::kInt64ArraySetIndexed:
    case MethodRecognizer::kUint64ArraySetIndexed:
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              exactness, graph_entry, entry, last, result);

    case MethodRecognizer::kFloat32ArraySetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed: {
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              exactness, graph_entry, entry, last, result);
    }
    case MethodRecognizer::kFloat32x4ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              exactness, graph_entry, entry, last, result);
    }
    case MethodRecognizer::kFloat64x2ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              exactness, graph_entry, entry, last, result);
    }
    case MethodRecognizer::kStringBaseCodeUnitAt:
      return InlineStringBaseCodeUnitAt(flow_graph, call, receiver,
                                        receiver_cid, graph_entry, entry, last,
                                        result);
    case MethodRecognizer::kStringBaseCharAt:
      return InlineStringBaseCharAt(flow_graph, call, receiver, receiver_cid,
                                    graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleAdd:
      return InlineDoubleOp(flow_graph, Token::kADD, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleSub:
      return InlineDoubleOp(flow_graph, Token::kSUB, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleMul:
      return InlineDoubleOp(flow_graph, Token::kMUL, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleDiv:
      return InlineDoubleOp(flow_graph, Token::kDIV, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDouble_getIsNaN:
    case MethodRecognizer::kDouble_getIsInfinite:
    case MethodRecognizer::kDouble_getIsNegative:
      return InlineDoubleTestOp(flow_graph, call, receiver, kind, graph_entry,
                                entry, last, result);
    case MethodRecognizer::kGrowableArraySetData:
      ASSERT((receiver_cid == kGrowableObjectArrayCid) ||
             ((receiver_cid == kDynamicCid) && call->IsStaticCall()));
      return InlineGrowableArraySetter(
          flow_graph, Slot::GrowableObjectArray_data(), kEmitStoreBarrier, call,
          receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kGrowableArraySetLength:
      ASSERT((receiver_cid == kGrowableObjectArrayCid) ||
             ((receiver_cid == kDynamicCid) && call->IsStaticCall()));
      return InlineGrowableArraySetter(
          flow_graph, Slot::GrowableObjectArray_length(), kNoStoreBarrier, call,
          receiver, graph_entry, entry, last, result);

    case MethodRecognizer::kFloat32x4Abs:
    case MethodRecognizer::kFloat32x4Clamp:
    case MethodRecognizer::kFloat32x4FromDoubles:
    case MethodRecognizer::kFloat32x4Equal:
    case MethodRecognizer::kFloat32x4GetSignMask:
    case MethodRecognizer::kFloat32x4GreaterThan:
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
    case MethodRecognizer::kFloat32x4LessThan:
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
    case MethodRecognizer::kFloat32x4Max:
    case MethodRecognizer::kFloat32x4Min:
    case MethodRecognizer::kFloat32x4Negate:
    case MethodRecognizer::kFloat32x4NotEqual:
    case MethodRecognizer::kFloat32x4Reciprocal:
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
    case MethodRecognizer::kFloat32x4Scale:
    case MethodRecognizer::kFloat32x4GetW:
    case MethodRecognizer::kFloat32x4GetX:
    case MethodRecognizer::kFloat32x4GetY:
    case MethodRecognizer::kFloat32x4GetZ:
    case MethodRecognizer::kFloat32x4Splat:
    case MethodRecognizer::kFloat32x4Sqrt:
    case MethodRecognizer::kFloat32x4ToFloat64x2:
    case MethodRecognizer::kFloat32x4ToInt32x4:
    case MethodRecognizer::kFloat32x4WithW:
    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat64x2Abs:
    case MethodRecognizer::kFloat64x2Clamp:
    case MethodRecognizer::kFloat64x2FromDoubles:
    case MethodRecognizer::kFloat64x2GetSignMask:
    case MethodRecognizer::kFloat64x2GetX:
    case MethodRecognizer::kFloat64x2GetY:
    case MethodRecognizer::kFloat64x2Max:
    case MethodRecognizer::kFloat64x2Min:
    case MethodRecognizer::kFloat64x2Negate:
    case MethodRecognizer::kFloat64x2Scale:
    case MethodRecognizer::kFloat64x2Splat:
    case MethodRecognizer::kFloat64x2Sqrt:
    case MethodRecognizer::kFloat64x2ToFloat32x4:
    case MethodRecognizer::kFloat64x2WithX:
    case MethodRecognizer::kFloat64x2WithY:
    case MethodRecognizer::kFloat64x2Zero:
    case MethodRecognizer::kInt32x4FromBools:
    case MethodRecognizer::kInt32x4FromInts:
    case MethodRecognizer::kInt32x4GetFlagW:
    case MethodRecognizer::kInt32x4GetFlagX:
    case MethodRecognizer::kInt32x4GetFlagY:
    case MethodRecognizer::kInt32x4GetFlagZ:
    case MethodRecognizer::kInt32x4GetSignMask:
    case MethodRecognizer::kInt32x4Select:
    case MethodRecognizer::kInt32x4ToFloat32x4:
    case MethodRecognizer::kInt32x4WithFlagW:
    case MethodRecognizer::kInt32x4WithFlagX:
    case MethodRecognizer::kInt32x4WithFlagY:
    case MethodRecognizer::kInt32x4WithFlagZ:
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kFloat32x4Mul:
    case MethodRecognizer::kFloat32x4Div:
    case MethodRecognizer::kFloat32x4Add:
    case MethodRecognizer::kFloat32x4Sub:
    case MethodRecognizer::kFloat64x2Mul:
    case MethodRecognizer::kFloat64x2Div:
    case MethodRecognizer::kFloat64x2Add:
    case MethodRecognizer::kFloat64x2Sub:
      return InlineSimdOp(flow_graph, is_dynamic_call, call, receiver, kind,
                          graph_entry, entry, last, result);

    case MethodRecognizer::kMathIntPow:
      return InlineMathIntPow(flow_graph, call, graph_entry, entry, last,
                              result);

    case MethodRecognizer::kObjectConstructor: {
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      ASSERT(!call->HasUses());
      *last = nullptr;  // Empty body.
      *result =
          nullptr;  // Since no uses of original call, result will be unused.
      return true;
    }

    case MethodRecognizer::kObjectArrayAllocate: {
      Value* num_elements = new (Z) Value(call->ArgumentAt(1));
      intptr_t length = 0;
      if (IsSmiValue(num_elements, &length)) {
        if (Array::IsValidLength(length)) {
          Value* type = new (Z) Value(call->ArgumentAt(0));
          *entry = new (Z)
              FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
          (*entry)->InheritDeoptTarget(Z, call);
          *last = new (Z) CreateArrayInstr(call->source(), type, num_elements,
                                           call->deopt_id());
          flow_graph->AppendTo(
              *entry, *last,
              call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
              FlowGraph::kValue);
          *result = (*last)->AsDefinition();
          return true;
        }
      }
      return false;
    }

    case MethodRecognizer::kObjectRuntimeType: {
      Type& type = Type::ZoneHandle(Z);
      if (receiver_cid == kDynamicCid) {
        return false;
      } else if (IsStringClassId(receiver_cid)) {
        type = Type::StringType();
      } else if (receiver_cid == kDoubleCid) {
        type = Type::Double();
      } else if (IsIntegerClassId(receiver_cid)) {
        type = Type::IntType();
      } else if (IsTypeClassId(receiver_cid)) {
        type = Type::DartTypeType();
      } else if ((receiver_cid != kClosureCid) &&
                 (receiver_cid != kRecordCid)) {
        const Class& cls = Class::Handle(
            Z, flow_graph->isolate_group()->class_table()->At(receiver_cid));
        if (!cls.IsGeneric()) {
          type = cls.DeclarationType();
        }
      }

      if (!type.IsNull()) {
        *entry = new (Z)
            FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                               call->GetBlock()->try_index(), DeoptId::kNone);
        (*entry)->InheritDeoptTarget(Z, call);
        ConstantInstr* ctype = flow_graph->GetConstant(type);
        // Create a synthetic (re)definition for return to flag insertion.
        // TODO(ajcbik): avoid this mechanism altogether
        RedefinitionInstr* redef =
            new (Z) RedefinitionInstr(new (Z) Value(ctype));
        flow_graph->AppendTo(
            *entry, redef,
            call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
            FlowGraph::kValue);
        *last = *result = redef;
        return true;
      }
      return false;
    }

    case MethodRecognizer::kWriteIntoOneByteString:
    case MethodRecognizer::kWriteIntoTwoByteString: {
      // This is an internal method, no need to check argument types nor
      // range.
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      Definition* str = call->ArgumentAt(0);
      Definition* index = call->ArgumentAt(1);
      Definition* value = call->ArgumentAt(2);

      const bool is_onebyte = kind == MethodRecognizer::kWriteIntoOneByteString;
      const intptr_t index_scale = is_onebyte ? 1 : 2;
      const intptr_t cid = is_onebyte ? kOneByteStringCid : kTwoByteStringCid;

      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value = UnboxInstr::Create(StoreIndexedInstr::ValueRepresentation(cid),
                                 new (Z) Value(value), call->deopt_id(),
                                 UnboxInstr::ValueMode::kHasValidType);
      flow_graph->AppendTo(*entry, value, call->env(), FlowGraph::kValue);

      *last = new (Z) StoreIndexedInstr(
          new (Z) Value(str), new (Z) Value(index), new (Z) Value(value),
          kNoStoreBarrier, /*index_unboxed=*/false, index_scale, cid,
          kAlignedAccess, call->deopt_id(), call->source());
      flow_graph->AppendTo(value, *last, call->env(), FlowGraph::kEffect);

      // We need a return value to replace uses of the original definition.
      // The final instruction is a use of 'void operator[]=()', so we use null.
      *result = flow_graph->constant_null();
      return true;
    }

    default:
      return false;
  }
}

}  // namespace dart
