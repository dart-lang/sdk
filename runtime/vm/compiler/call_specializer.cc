// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/call_specializer.h"

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_state.h"
#include "vm/cpu.h"

namespace dart {

// Quick access to the current isolate and zone.
#define I (isolate())
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

static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}

static bool CanConvertInt64ToDouble() {
  return FlowGraphCompiler::CanConvertInt64ToDouble();
}

static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}

static bool ShouldSpecializeForDouble(const BinaryFeedback& binary_feedback) {
  // Don't specialize for double if we can't unbox them.
  if (!CanUnboxDouble()) {
    return false;
  }

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
      } else if (auto static_call = instr->AsStaticCall()) {
        // If TFA devirtualized instance calls to static calls we also want to
        // process them here.
        VisitStaticCall(static_call);
      } else if (instr->IsPolymorphicInstanceCall()) {
        SpecializePolymorphicInstanceCall(instr->AsPolymorphicInstanceCall());
      }
    }
    current_iterator_ = NULL;
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
  if (FLAG_guess_icdata_cid) {
    if (CompilerState::Current().is_aot()) {
      // In precompiler speculate that both sides of bitwise operation
      // are Smi-s.
      if (Token::IsBinaryBitwiseOperator(op_kind) &&
          call->CanReceiverBeSmiBasedOnInterfaceTarget(zone())) {
        class_ids[0] = kSmiCid;
        class_ids[1] = kSmiCid;
      }
    }
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
    return;  // No information about receiver was infered.
  }

  const ICData& ic_data = *call->ic_data();

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
  StaticCallInstr* specialized =
      StaticCallInstr::FromCall(Z, call, target, targets->AggregateCallCount());
  call->ReplaceWith(specialized, current_iterator());
}

void CallSpecializer::ReplaceCallWithResult(Definition* call,
                                            Instruction* replacement,
                                            Definition* result) {
  ASSERT(!call->HasPushArguments());
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

bool CallSpecializer::TryReplaceWithIndexedOp(InstanceCallInstr* call) {
  if (call->Targets().IsMonomorphic()) {
    return FlowGraphInliner::TryReplaceInstanceCallWithInline(
        flow_graph_, current_iterator(), call, speculative_policy_);
  }
  return false;
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
        new (Z) EqualityCompareInstr(call->source(), op_kind, left_val,
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
  return compiler::target::kSmiBits < 53;
}

bool CallSpecializer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  const BinaryFeedback& binary_feedback = call->BinaryFeedback();

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* const left = call->ArgumentAt(0);
  Definition* const right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
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
    cid = kSmiCid;
  } else if (binary_feedback.OperandsAreSmiOrMint() &&
             FlowGraphCompiler::SupportsUnboxedInt64()) {
    cid = kMintCid;
  } else if (binary_feedback.OperandsAreSmiOrDouble() && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
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
        cid = kDoubleCid;
      }
    }
  } else {
    // Check if ICDData contains checks with Smi/Null combinations. In that case
    // we can still emit the optimized Smi equality operation but need to add
    // checks for null or Smi.
    if (binary_feedback.OperandsAreSmiOrNull()) {
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
            StrictCompareInstr(call->source(), Token::kEQ_STRICT,
                               new (Z) Value(left), new (Z) Value(right),
                               /* number_check = */ false, DeoptId::kNone);
        ReplaceCall(call, comp);
        return true;
      }
      return false;
    }
  }
  ASSERT(cid != kIllegalCid);
  EqualityCompareInstr* comp =
      new (Z) EqualityCompareInstr(call->source(), op_kind, new (Z) Value(left),
                                   new (Z) Value(right), cid, call->deopt_id());
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

  intptr_t cid = kIllegalCid;
  if (binary_feedback.OperandsAre(kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(left), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(right), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    cid = kSmiCid;
  } else if (binary_feedback.OperandsAreSmiOrMint() &&
             FlowGraphCompiler::SupportsUnboxedInt64()) {
    cid = kMintCid;
  } else if (binary_feedback.OperandsAreSmiOrDouble() && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
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
        cid = kDoubleCid;
      }
    }
  } else {
    return false;
  }
  ASSERT(cid != kIllegalCid);
  RelationalOpInstr* comp =
      new (Z) RelationalOpInstr(call->source(), op_kind, new (Z) Value(left),
                                new (Z) Value(right), cid, call->deopt_id());
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
      } else if (binary_feedback.OperandsAreSmiOrMint() &&
                 FlowGraphCompiler::SupportsUnboxedInt64()) {
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
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
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
    case Token::kSHR:
    case Token::kSHL:
      if (binary_feedback.OperandsAre(kSmiCid)) {
        // Left shift may overflow from smi into mint or big ints.
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
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
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
                            call->deopt_id(), call->source());
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    if (!FlowGraphCompiler::SupportsUnboxedInt64()) return false;
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      SpeculativeShiftInt64OpInstr* shift_op = new (Z)
          SpeculativeShiftInt64OpInstr(op_kind, new (Z) Value(left),
                                       new (Z) Value(right), call->deopt_id());
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
  Definition* unary_op = NULL;
  if (call->Targets().ReceiverIs(kSmiCid)) {
    InsertBefore(call,
                 new (Z) CheckSmiInstr(new (Z) Value(input), call->deopt_id(),
                                       call->source()),
                 call->env(), FlowGraph::kEffect);
    unary_op = new (Z)
        UnarySmiOpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if ((op_kind == Token::kBIT_NOT) &&
             call->Targets().ReceiverIsSmiOrMint() &&
             FlowGraphCompiler::SupportsUnboxedInt64()) {
    unary_op = new (Z)
        UnaryInt64OpInstr(op_kind, new (Z) Value(input), call->deopt_id());
  } else if (call->Targets().ReceiverIs(kDoubleCid) &&
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

  switch (flow_graph()->CheckForInstanceCall(call,
                                             FunctionLayout::kImplicitGetter)) {
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

  if (load->slot().nullable_cid() != kDynamicCid) {
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
  if (target.kind() != FunctionLayout::kImplicitSetter) {
    // Non-implicit setter are inlined like normal method calls.
    return false;
  }
  Field& field = Field::ZoneHandle(Z, target.accessor_field());
  ASSERT(!field.IsNull());
  if (should_clone_fields_) {
    field = field.CloneFromOriginal();
  }

  switch (flow_graph()->CheckForInstanceCall(instr,
                                             FunctionLayout::kImplicitSetter)) {
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

  if (I->use_field_guards()) {
    if (field.guarded_cid() != kDynamicCid) {
      InsertBefore(instr,
                   new (Z)
                       GuardFieldClassInstr(new (Z) Value(instr->ArgumentAt(1)),
                                            field, instr->deopt_id()),
                   instr->env(), FlowGraph::kEffect);
    }

    if (field.needs_length_check()) {
      InsertBefore(
          instr,
          new (Z) GuardFieldLengthInstr(new (Z) Value(instr->ArgumentAt(1)),
                                        field, instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }

    if (field.static_type_exactness_state().NeedsFieldGuard()) {
      InsertBefore(instr,
                   new (Z)
                       GuardFieldTypeInstr(new (Z) Value(instr->ArgumentAt(1)),
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
          InsertBefore(instr, instantiator_type_args, instr->env(),
                       FlowGraph::kValue);
        }
      }

      InsertBefore(
          instr,
          new (Z) AssertAssignableInstr(
              instr->source(), new (Z) Value(instr->ArgumentAt(1)),
              new (Z) Value(flow_graph_->GetConstant(dst_type)),
              new (Z) Value(instantiator_type_args),
              new (Z) Value(function_type_args),
              String::ZoneHandle(zone(), field.name()), instr->deopt_id()),
          instr->env(), FlowGraph::kEffect);
    }
  }

  // Field guard was detached.
  ASSERT(instr->FirstArgIndex() == 0);
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      field, new (Z) Value(instr->ArgumentAt(0)),
      new (Z) Value(instr->ArgumentAt(1)), kEmitStoreBarrier, instr->source(),
      &flow_graph()->parsed_function());

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
  if (target.kind() != FunctionLayout::kImplicitGetter) {
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
      args, call->deopt_id(), recognized_kind, call->source());
  ReplaceCall(call, invoke);
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

  if (CanUnboxDouble() &&
      (recognized_kind == MethodRecognizer::kIntegerToDouble)) {
    if (receiver_cid == kSmiCid) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new (Z) SmiToDoubleInstr(new (Z) Value(call->ArgumentAt(0)),
                                           call->source()));
      return true;
    } else if ((receiver_cid == kMintCid) && CanConvertInt64ToDouble()) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new (Z) Int64ToDoubleInstr(new (Z) Value(call->ArgumentAt(0)),
                                             call->deopt_id()));
      return true;
    }
  }

  if (receiver_cid == kDoubleCid) {
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
BoolPtr CallSpecializer::InstanceOfAsBool(
    const ICData& ic_data,
    const AbstractType& type,
    ZoneGrowableArray<intptr_t>* results) const {
  ASSERT(results->is_empty());
  ASSERT(ic_data.NumArgsTested() == 1);  // Unary checks only.
  if (type.IsFunctionType() || type.IsDartFunctionType() ||
      !type.IsInstantiated()) {
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
    bool is_subtype = false;
    if (cls.IsNullClass()) {
      // 'null' is an instance of Null, Object*, Never*, void, and dynamic.
      // In addition, 'null' is an instance of any nullable type.
      // It is also an instance of FutureOr<T> if it is an instance of T.
      const AbstractType& unwrapped_type =
          AbstractType::Handle(type.UnwrapFutureOr());
      ASSERT(unwrapped_type.IsInstantiated());
      is_subtype = unwrapped_type.IsTopTypeForInstanceOf() ||
                   unwrapped_type.IsNullable() ||
                   (unwrapped_type.IsLegacy() && unwrapped_type.IsNeverType());
    } else {
      is_subtype =
          Class::IsSubtypeOf(cls, Object::null_type_arguments(),
                             Nullability::kNonNullable, type, Heap::kOld);
    }
    results->Add(cls.id());
    results->Add(static_cast<intptr_t>(is_subtype));
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
  ASSERT(type.IsFinalized());
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
    ASSERT(!CompilerState::Current().is_aot() || !FLAG_use_cha_deopt);
    if (FLAG_use_cha_deopt || isolate()->all_classes_finalized()) {
      if (FLAG_trace_cha) {
        THR_Print(
            "  **(CHA) Typecheck as class equality since no "
            "subclasses: %s\n",
            type_class.ToCString());
      }
      if (FLAG_use_cha_deopt) {
        thread()->compiler_state().cha().AddToGuardedClasses(
            type_class, /*subclass_count=*/0);
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

  // If type is Null or Never*, or the static type of the receiver is a
  // subtype of the tested type, replace 'receiver is type' with
  //  - 'receiver == null' if type is Null or Never*,
  //  - 'receiver != null' otherwise.
  if (type.IsNullType() || (type.IsNeverType() && type.IsLegacy()) ||
      left_value->Type()->IsSubtypeOf(type)) {
    Definition* replacement = new (Z) StrictCompareInstr(
        call->source(),
        (type.IsNullType() || (type.IsNeverType() && type.IsLegacy()))
            ? Token::kEQ_STRICT
            : Token::kNE_STRICT,
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
    ASSERT(call->ArgumentCount() == 4);
    instantiator_type_args = call->ArgumentAt(1);
    function_type_args = call->ArgumentAt(2);
    type = AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value()).raw();
  }

  if (TryOptimizeInstanceOfUsingStaticTypes(call, type)) {
    return;
  }

  if (TypeCheckAsClassEquality(type)) {
    LoadClassIdInstr* left_cid = new (Z) LoadClassIdInstr(new (Z) Value(left));
    InsertBefore(call, left_cid, NULL, FlowGraph::kValue);
    const intptr_t type_cid = Class::Handle(Z, type.type_class()).id();
    ConstantInstr* cid =
        flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(type_cid)));

    StrictCompareInstr* check_cid = new (Z) StrictCompareInstr(
        call->source(), Token::kEQ_STRICT, new (Z) Value(left_cid),
        new (Z) Value(cid), /* number_check = */ false, DeoptId::kNone);
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
        if (can_deopt &&
            !speculative_policy_->IsAllowedForInlining(call->deopt_id())) {
          // Guard against repeated speculative inlining.
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
      ASSERT(!call->HasPushArguments());
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
  if (FlowGraphInliner::TryReplaceStaticCallWithInline(
          flow_graph_, current_iterator(), call, speculative_policy_)) {
    return;
  }

  if (speculative_policy_->IsAllowedForInlining(call->deopt_id())) {
    // Only if speculative inlining is enabled.

    MethodRecognizer::Kind recognized_kind = call->function().recognized_kind();
    const CallTargets& targets = call->Targets();
    const BinaryFeedback& binary_feedback = call->BinaryFeedback();

    switch (recognized_kind) {
      case MethodRecognizer::kMathMin:
      case MethodRecognizer::kMathMax: {
        // We can handle only monomorphic min/max call sites with both arguments
        // being either doubles or smis.
        if (CanUnboxDouble() && targets.IsMonomorphic() &&
            (call->FirstArgIndex() == 0)) {
          intptr_t result_cid = kIllegalCid;
          if (binary_feedback.IncludesOperands(kDoubleCid)) {
            result_cid = kDoubleCid;
          } else if (binary_feedback.IncludesOperands(kSmiCid)) {
            result_cid = kSmiCid;
          }
          if (result_cid != kIllegalCid) {
            MathMinMaxInstr* min_max = new (Z) MathMinMaxInstr(
                recognized_kind, new (Z) Value(call->ArgumentAt(0)),
                new (Z) Value(call->ArgumentAt(1)), call->deopt_id(),
                result_cid);
            const Cids* cids = Cids::CreateMonomorphic(Z, result_cid);
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
        if (call->HasICData() && targets.IsMonomorphic() &&
            (call->FirstArgIndex() == 0)) {
          if (CanUnboxDouble()) {
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
  const ClassTable& class_table = *Isolate::Current()->class_table();
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

  const auto& typed_data = Library::Handle(
      Z, Library::LookupLibrary(thread_, Symbols::DartTypedData()));

  auto& td_class = Class::Handle(Z);
  auto& direct_implementors = GrowableObjectArray::Handle(Z);
  SafepointReadRwLocker ml(thread_, thread_->isolate_group()->program_lock());

#define INIT_HANDLE(iface, member_name, type, cid)                             \
  td_class = typed_data.LookupClass(Symbols::iface());                         \
  ASSERT(!td_class.IsNull());                                                  \
  direct_implementors = td_class.direct_implementors();                        \
  if (!HasThirdPartyImplementor(direct_implementors)) {                        \
    member_name = td_class.RareType();                                         \
  }

  PUBLIC_TYPED_DATA_CLASS_LIST(INIT_HANDLE)
#undef INIT_HANDLE
}

bool TypedDataSpecializer::HasThirdPartyImplementor(
    const GrowableObjectArray& direct_implementors) {
  // Check if there are non internal/external/view implementors.
  for (intptr_t i = 0; i < direct_implementors.Length(); ++i) {
    implementor_ ^= direct_implementors.At(i);

    // We only consider [implementor_] a 3rd party implementor if it was
    // finalized by the class finalizer, since only then can we have concrete
    // instances of the [implementor_].
    if (implementor_.is_finalized()) {
      const classid_t cid = implementor_.id();
      if (!IsTypedDataClassId(cid) && !IsTypedDataViewClassId(cid) &&
          !IsExternalTypedDataClassId(cid)) {
        return true;
      }
    }
  }
  return false;
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
  const bool is_length_getter = call->Selector() == Symbols::GetLength().raw();
  const bool is_index_get = call->Selector() == Symbols::IndexToken().raw();
  const bool is_index_set =
      call->Selector() == Symbols::AssignIndexToken().raw();

  if (is_length_getter || is_index_get || is_index_set) {
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
#define TRY_INLINE(iface, member_name, type, cid)                              \
  if (!member_name.IsNull()) {                                                 \
    const bool is_float_access =                                               \
        cid == kTypedDataFloat32ArrayCid || cid == kTypedDataFloat64ArrayCid;  \
    if (receiver_type->IsAssignableTo(member_name)) {                          \
      if (is_length_getter) {                                                  \
        type_class = member_name.type_class();                                 \
        ReplaceWithLengthGetter(call);                                         \
      } else if (is_index_get) {                                               \
        if (is_float_access && !FlowGraphCompiler::SupportsUnboxedDoubles()) { \
          return;                                                              \
        }                                                                      \
        if (!index_type->IsNullableInt()) return;                              \
        type_class = member_name.type_class();                                 \
        ReplaceWithIndexGet(call, cid);                                        \
      } else {                                                                 \
        if (is_float_access && !FlowGraphCompiler::SupportsUnboxedDoubles()) { \
          return;                                                              \
        }                                                                      \
        if (!index_type->IsNullableInt()) return;                              \
        if (!value_type->IsAssignableTo(type)) return;                         \
        type_class = member_name.type_class();                                 \
        ReplaceWithIndexSet(call, cid);                                        \
      }                                                                        \
      return;                                                                  \
    }                                                                          \
  }
    PUBLIC_TYPED_DATA_CLASS_LIST(TRY_INLINE)
#undef INIT_HANDLE
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

void TypedDataSpecializer::AppendBoundsCheck(TemplateDartCall<0>* call,
                                             Definition* array,
                                             Definition** index) {
  auto length = new (Z) LoadFieldInstr(
      new (Z) Value(array), Slot::TypedDataBase_length(), call->source());
  flow_graph_->InsertBefore(call, length, call->env(), FlowGraph::kValue);

  auto check = new (Z) GenericCheckBoundInstr(
      new (Z) Value(length), new (Z) Value(*index), DeoptId::kNone);
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

  auto data = new (Z)
      LoadUntaggedInstr(new (Z) Value(array),
                        compiler::target::TypedDataBase::data_field_offset());
  flow_graph_->InsertBefore(call, data, call->env(), FlowGraph::kValue);

  Definition* load = new (Z) LoadIndexedInstr(
      new (Z) Value(data), new (Z) Value(index), /*index_unboxed=*/false,
      index_scale, cid, kAlignedAccess, DeoptId::kNone, call->source());
  flow_graph_->InsertBefore(call, load, call->env(), FlowGraph::kValue);

  if (cid == kTypedDataFloat32ArrayCid) {
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

  const auto deopt_id = call->deopt_id();

  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value = UnboxInstr::Create(kUnboxedIntPtr, new (Z) Value(value), deopt_id,
                                 Instruction::kNotSpeculative);
      flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
      break;
    }
    case kTypedDataInt32ArrayCid: {
      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value = UnboxInstr::Create(kUnboxedInt32, new (Z) Value(value), deopt_id,
                                 Instruction::kNotSpeculative);
      flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
      break;
    }
    case kTypedDataUint32ArrayCid: {
      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value = UnboxInstr::Create(kUnboxedUint32, new (Z) Value(value), deopt_id,
                                 Instruction::kNotSpeculative);
      flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
      break;
    }
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid: {
      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value = UnboxInstr::Create(kUnboxedInt64, new (Z) Value(value),
                                 DeoptId::kNone, Instruction::kNotSpeculative);
      flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      value = new (Z) DoubleToFloatInstr(new (Z) Value(value), deopt_id,
                                         Instruction::kNotSpeculative);
      flow_graph_->InsertBefore(call, value, call->env(), FlowGraph::kValue);
      break;
    }
    default:
      break;
  }

  auto data = new (Z)
      LoadUntaggedInstr(new (Z) Value(array),
                        compiler::target::TypedDataBase::data_field_offset());
  flow_graph_->InsertBefore(call, data, call->env(), FlowGraph::kValue);

  auto store = new (Z) StoreIndexedInstr(
      new (Z) Value(data), new (Z) Value(index), new (Z) Value(value),
      kNoStoreBarrier, /*index_unboxed=*/false, index_scale, cid,
      kAlignedAccess, DeoptId::kNone, call->source(),
      Instruction::kNotSpeculative);
  flow_graph_->InsertBefore(call, store, call->env(), FlowGraph::kEffect);
}

void CallSpecializer::ReplaceInstanceCallsWithDispatchTableCalls() {
  // Only implemented for AOT.
}

}  // namespace dart
