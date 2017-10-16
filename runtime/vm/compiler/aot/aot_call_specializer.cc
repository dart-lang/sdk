// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/aot/aot_call_specializer.h"

#include "vm/bit_vector.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(int,
            max_exhaustive_polymorphic_checks,
            5,
            "If a call receiver is known to be of at most this many classes, "
            "generate exhaustive class tests instead of a megamorphic call");

// Quick access to the current isolate and zone.
#define I (isolate())
#define Z (zone())

#ifdef DART_PRECOMPILER

// Returns named function that is a unique dynamic target, i.e.,
// - the target is identified by its name alone, since it occurs only once.
// - target's class has no subclasses, and neither is subclassed, i.e.,
//   the receiver type can be only the function's class.
// Returns Function::null() if there is no unique dynamic target for
// given 'fname'. 'fname' must be a symbol.
static void GetUniqueDynamicTarget(Isolate* isolate,
                                   const String& fname,
                                   Object* function) {
  UniqueFunctionsSet functions_set(
      isolate->object_store()->unique_dynamic_targets());
  ASSERT(fname.IsSymbol());
  *function = functions_set.GetOrNull(fname);
  ASSERT(functions_set.Release().raw() ==
         isolate->object_store()->unique_dynamic_targets());
}

AotCallSpecializer::AotCallSpecializer(
    Precompiler* precompiler,
    FlowGraph* flow_graph,
    bool use_speculative_inlining,
    GrowableArray<intptr_t>* inlining_black_list)
    : CallSpecializer(flow_graph, /* should_clone_fields=*/false),
      precompiler_(precompiler),
      use_speculative_inlining_(use_speculative_inlining),
      inlining_black_list_(inlining_black_list),
      has_unique_no_such_method_(false) {
  ASSERT(!use_speculative_inlining || (inlining_black_list != NULL));
  Function& target_function = Function::Handle();
  if (isolate()->object_store()->unique_dynamic_targets() != Array::null()) {
    GetUniqueDynamicTarget(isolate(), Symbols::NoSuchMethod(),
                           &target_function);
    has_unique_no_such_method_ = !target_function.IsNull();
  }
}

bool AotCallSpecializer::TryCreateICDataForUniqueTarget(
    InstanceCallInstr* call) {
  if (isolate()->object_store()->unique_dynamic_targets() == Array::null()) {
    return false;
  }

  // Check if the target is unique.
  Function& target_function = Function::Handle(Z);
  GetUniqueDynamicTarget(isolate(), call->function_name(), &target_function);

  if (target_function.IsNull()) {
    return false;
  }

  // Calls passing named arguments and calls to a function taking named
  // arguments must be resolved/checked at runtime.
  // Calls passing a type argument vector and calls to a generic function must
  // be resolved/checked at runtime.
  if (target_function.HasOptionalNamedParameters() ||
      target_function.IsGeneric() ||
      !target_function.AreValidArgumentCounts(
          call->type_args_len(), call->ArgumentCountWithoutTypeArgs(),
          call->argument_names().IsNull() ? 0 : call->argument_names().Length(),
          /* error_message = */ NULL)) {
    return false;
  }

  const Class& cls = Class::Handle(Z, target_function.Owner());
  if (CHA::IsImplemented(cls) || CHA::HasSubclasses(cls)) {
    return false;
  }

  const ICData& ic_data =
      ICData::ZoneHandle(Z, ICData::NewFrom(*call->ic_data(), 1));
  ic_data.AddReceiverCheck(cls.id(), target_function);
  call->set_ic_data(&ic_data);

  // If we know that the only noSuchMethod is Object.noSuchMethod then
  // this call is guaranteed to either succeed or throw.
  if (has_unique_no_such_method_) {
    call->set_has_unique_selector(true);

    // Add redefinition of the receiver to prevent code motion across
    // this call.
    const intptr_t receiver_index = call->FirstArgIndex();
    RedefinitionInstr* redefinition = new (Z)
        RedefinitionInstr(new (Z) Value(call->ArgumentAt(receiver_index)));
    redefinition->set_ssa_temp_index(flow_graph()->alloc_ssa_temp_index());
    redefinition->InsertAfter(call);
    // Replace all uses of the receiver dominated by this call.
    FlowGraph::RenameDominatedUses(call->ArgumentAt(receiver_index),
                                   redefinition, redefinition);
    if (!redefinition->HasUses()) {
      redefinition->RemoveFromGraph();
    }
  }

  return true;
}

bool AotCallSpecializer::TryCreateICData(InstanceCallInstr* call) {
  if (TryCreateICDataForUniqueTarget(call)) {
    return true;
  }

  return CallSpecializer::TryCreateICData(call);
}

bool AotCallSpecializer::RecognizeRuntimeTypeGetter(InstanceCallInstr* call) {
  if ((precompiler_ == NULL) || !precompiler_->get_runtime_type_is_unique()) {
    return false;
  }

  if (call->function_name().raw() != Symbols::GetRuntimeType().raw()) {
    return false;
  }

  // There is only a single function Object.get:runtimeType that can be invoked
  // by this call. Convert dynamic invocation to a static one.
  const Class& cls = Class::Handle(Z, I->object_store()->object_class());
  const Function& function =
      Function::Handle(Z, call->ResolveForReceiverClass(cls));
  ASSERT(!function.IsNull());
  const Function& target = Function::ZoneHandle(Z, function.raw());
  StaticCallInstr* static_call = StaticCallInstr::FromCall(Z, call, target);
  static_call->set_result_cid(kTypeCid);
  call->ReplaceWith(static_call, current_iterator());
  return true;
}

static bool IsGetRuntimeType(Definition* defn) {
  StaticCallInstr* call = defn->AsStaticCall();
  return (call != NULL) && (call->function().recognized_kind() ==
                            MethodRecognizer::kObjectRuntimeType);
}

// Recognize a.runtimeType == b.runtimeType and fold it into
// Object._haveSameRuntimeType(a, b).
// Note: this optimization is not speculative.
bool AotCallSpecializer::TryReplaceWithHaveSameRuntimeType(
    InstanceCallInstr* call) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->type_args_len() == 0);
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  if (IsGetRuntimeType(left) && left->input_use_list()->IsSingleUse() &&
      IsGetRuntimeType(right) && right->input_use_list()->IsSingleUse()) {
    const Class& cls = Class::Handle(Z, I->object_store()->object_class());
    const Function& have_same_runtime_type = Function::ZoneHandle(
        Z,
        cls.LookupStaticFunctionAllowPrivate(Symbols::HaveSameRuntimeType()));
    ASSERT(!have_same_runtime_type.IsNull());

    ZoneGrowableArray<PushArgumentInstr*>* args =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
    PushArgumentInstr* arg =
        new (Z) PushArgumentInstr(new (Z) Value(left->ArgumentAt(0)));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    arg = new (Z) PushArgumentInstr(new (Z) Value(right->ArgumentAt(0)));
    InsertBefore(call, arg, NULL, FlowGraph::kEffect);
    args->Add(arg);
    const intptr_t kTypeArgsLen = 0;
    ASSERT(call->type_args_len() == kTypeArgsLen);
    StaticCallInstr* static_call = new (Z) StaticCallInstr(
        call->token_pos(), have_same_runtime_type, kTypeArgsLen,
        Object::null_array(),  // argument_names
        args, call->deopt_id(), call->CallCount(), ICData::kOptimized);
    static_call->set_result_cid(kBoolCid);
    ReplaceCall(call, static_call);
    return true;
  }

  return false;
}

bool AotCallSpecializer::IsAllowedForInlining(intptr_t call_deopt_id) const {
  if (!use_speculative_inlining_) return false;
  for (intptr_t i = 0; i < inlining_black_list_->length(); ++i) {
    if ((*inlining_black_list_)[i] == call_deopt_id) return false;
  }
  return true;
}

static bool HasLikelySmiOperand(InstanceCallInstr* instr) {
  ASSERT(instr->type_args_len() == 0);
  // Phis with at least one known smi are // guessed to be likely smi as well.
  for (intptr_t i = 0; i < instr->ArgumentCount(); ++i) {
    PhiInstr* phi = instr->ArgumentAt(i)->AsPhi();
    if (phi != NULL) {
      for (intptr_t j = 0; j < phi->InputCount(); ++j) {
        if (phi->InputAt(j)->Type()->ToCid() == kSmiCid) return true;
      }
    }
  }
  // If all of the inputs are known smis or the result of CheckedSmiOp,
  // we guess the operand to be likely smi.
  for (intptr_t i = 0; i < instr->ArgumentCount(); ++i) {
    if (!instr->ArgumentAt(i)->IsCheckedSmiOp()) return false;
  }
  return true;
}

bool AotCallSpecializer::TryInlineFieldAccess(InstanceCallInstr* call) {
  const Token::Kind op_kind = call->token_kind();
  if ((op_kind == Token::kGET) && TryInlineInstanceGetter(call)) {
    return true;
  }

  const ICData& unary_checks =
      ICData::Handle(Z, call->ic_data()->AsUnaryClassChecks());
  if (!unary_checks.NumberOfChecksIs(0) && (op_kind == Token::kSET) &&
      TryInlineInstanceSetter(call, unary_checks)) {
    return true;
  }

  return false;
}

Value* AotCallSpecializer::PrepareStaticOpInput(Value* input,
                                                intptr_t cid,
                                                Instruction* call) {
  ASSERT(FLAG_experimental_strong_mode);
  ASSERT((cid == kDoubleCid) ||
         (FLAG_limit_ints_to_64_bits && (cid == kMintCid)));

  AddCheckNull(input, call->deopt_id(), call->env(), call);

  input = input->CopyWithType(Z);

  if ((cid == kDoubleCid) && (input->Type()->ToNullableCid() == kSmiCid)) {
    Definition* conversion = new (Z) SmiToDoubleInstr(input, call->token_pos());

    if (FLAG_trace_experimental_strong_mode) {
      THR_Print("[Strong mode] Inserted %s\n", conversion->ToCString());
    }
    InsertBefore(call, conversion, /* env = */ NULL, FlowGraph::kValue);
    return new (Z) Value(conversion);
  }

  return input;
}

Value* AotCallSpecializer::PrepareReceiverOfDevirtualizedCall(Value* input,
                                                              intptr_t cid) {
  ASSERT(FLAG_experimental_strong_mode);
  ASSERT(cid == kDoubleCid);

  // Can't assert !input->Type()->is_nullable() here as PushArgument receives
  // value prior to a CheckNull in case of devirtualized call.

  input = input->CopyWithType(Z);

  // Make sure type of the input is double.
  // It is necessary as VM has limited knowledge of generic types
  // and may not accurately infer type of the receiver if it is a
  // generic type.
  // TODO(dartbug.com/30480): improve type inference for generic types
  if (!input->Type()->IsNullableDouble()) {
    input->SetReachingType(new (Z) CompileType(CompileType::Double()));
  }

  return input;
}

bool AotCallSpecializer::TryOptimizeInstanceCallUsingStaticTypes(
    InstanceCallInstr* instr) {
  ASSERT(FLAG_experimental_strong_mode);

  const intptr_t receiver_index = instr->FirstArgIndex();
  const Token::Kind op_kind = instr->token_kind();
  Definition* replacement = NULL;

  switch (op_kind) {
    case Token::kEQ:
    case Token::kNE:
    case Token::kLT:
    case Token::kLTE:
    case Token::kGT:
    case Token::kGTE: {
      Value* left_value = instr->PushArgumentAt(receiver_index)->value();
      Value* right_value = instr->PushArgumentAt(receiver_index + 1)->value();
      CompileType* left_type = left_value->Type();
      CompileType* right_type = right_value->Type();
      if (left_type->IsNullableInt() && right_type->IsNullableInt()) {
        if (FLAG_limit_ints_to_64_bits &&
            FlowGraphCompiler::SupportsUnboxedMints()) {
          if (Token::IsRelationalOperator(op_kind)) {
            left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
            right_value = PrepareStaticOpInput(right_value, kMintCid, instr);
            replacement = new (Z)
                RelationalOpInstr(instr->token_pos(), op_kind, left_value,
                                  right_value, kMintCid, Thread::kNoDeoptId);

          } else {
            // TODO(dartbug.com/30480): Figure out how to handle null in
            // equality comparisons.
            replacement = new (Z) EqualityCompareInstr(
                instr->token_pos(), op_kind, left_value->CopyWithType(Z),
                right_value->CopyWithType(Z), kMintCid, Thread::kNoDeoptId);
          }
          // TODO(dartbug.com/30480): Enable comparisons with Smi.
        } else if (false &&
                   ((op_kind == Token::kEQ) || (op_kind == Token::kNE)) &&
                   ((left_type->ToCid() == kSmiCid) ||
                    (right_type->ToCid() == kSmiCid))) {
          replacement = new (Z) StrictCompareInstr(
              instr->token_pos(),
              (op_kind == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
              left_value->CopyWithType(Z), right_value->CopyWithType(Z),
              /* number_check = */ false, Thread::kNoDeoptId);
        } else {
          replacement = new (Z) CheckedSmiComparisonInstr(
              instr->token_kind(), left_value->CopyWithType(Z),
              right_value->CopyWithType(Z), instr);
        }
      } else if (FlowGraphCompiler::SupportsUnboxedDoubles() &&
                 (left_type->IsNullableDouble() ||
                  (left_type->ToNullableCid() == kSmiCid)) &&
                 (right_type->IsNullableDouble() ||
                  (right_type->ToNullableCid() == kSmiCid))) {
        // TODO(dartbug.com/30480): Extend double/int mixed cases from Smi to
        // AbstractInt (it requires corresponding conversions).
        ASSERT(left_type->IsNullableDouble() || right_type->IsNullableDouble());
        // TODO(dartbug.com/30480): Support == and != for doubles.
        if ((op_kind == Token::kLT) || (op_kind == Token::kLTE) ||
            (op_kind == Token::kGT) || (op_kind == Token::kGTE)) {
          left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
          right_value = PrepareStaticOpInput(right_value, kDoubleCid, instr);
          replacement = new (Z)
              RelationalOpInstr(instr->token_pos(), op_kind, left_value,
                                right_value, kDoubleCid, Thread::kNoDeoptId);
        }
      }
      break;
    }
    case Token::kSHL:
    case Token::kSHR:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kDIV: {
      if ((op_kind == Token::kDIV) &&
          !FlowGraphCompiler::SupportsHardwareDivision()) {
        return false;
      }
      Value* left_value = instr->PushArgumentAt(receiver_index)->value();
      Value* right_value = instr->PushArgumentAt(receiver_index + 1)->value();
      CompileType* left_type = left_value->Type();
      CompileType* right_type = right_value->Type();
      if (left_type->IsNullableInt() && right_type->IsNullableInt()) {
        if (FLAG_limit_ints_to_64_bits &&
            FlowGraphCompiler::SupportsUnboxedMints()) {
          if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
            // TODO(dartbug.com/30480): Enable 64-bit integer shifts.
            // replacement = new ShiftInt64OpInstr(
            //     op_kind, left_value->CopyWithType(Z),
            //     right_value->CopyWithType(Z), Thread::kNoDeoptId);
            replacement =
                new (Z) CheckedSmiOpInstr(op_kind, left_value->CopyWithType(Z),
                                          right_value->CopyWithType(Z), instr);
          } else {
            left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
            right_value = PrepareStaticOpInput(right_value, kMintCid, instr);
            replacement = new BinaryInt64OpInstr(
                op_kind, left_value, right_value, Thread::kNoDeoptId);
          }
        } else if (op_kind != Token::kDIV) {
          replacement =
              new (Z) CheckedSmiOpInstr(op_kind, left_value->CopyWithType(Z),
                                        right_value->CopyWithType(Z), instr);
        }
      } else if (FlowGraphCompiler::SupportsUnboxedDoubles() &&
                 (left_type->IsNullableDouble() ||
                  (left_type->ToNullableCid() == kSmiCid)) &&
                 (right_type->IsNullableDouble() ||
                  (right_type->ToNullableCid() == kSmiCid))) {
        // TODO(dartbug.com/30480): Extend double/int mixed cases from Smi to
        // AbstractInt (it requires corresponding conversions).
        ASSERT(left_type->IsNullableDouble() || right_type->IsNullableDouble());
        if ((op_kind == Token::kADD) || (op_kind == Token::kSUB) ||
            (op_kind == Token::kMUL) || (op_kind == Token::kDIV)) {
          left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
          right_value = PrepareStaticOpInput(right_value, kDoubleCid, instr);
          replacement = new (Z)
              BinaryDoubleOpInstr(op_kind, left_value, right_value,
                                  Thread::kNoDeoptId, instr->token_pos());
        }
      }
      break;
    }

    default:
      break;
  }

  if (replacement != NULL) {
    if (FLAG_trace_experimental_strong_mode) {
      THR_Print("[Strong mode] Optimization: replacing %s with %s\n",
                instr->ToCString(), replacement->ToCString());
    }
    ReplaceCall(instr, replacement);
    return true;
  }

  return false;
}

bool AotCallSpecializer::TryOptimizeStaticCallUsingStaticTypes(
    StaticCallInstr* call) {
  ASSERT(FLAG_experimental_strong_mode);
  Definition* replacement = NULL;

  if (FlowGraphCompiler::SupportsUnboxedDoubles()) {
    const Class& owner = Class::Handle(Z, call->function().Owner());
    // Recognize double operators here as devirtualization can convert
    // instance calls of double operators into static calls.
    if (owner.id() == kDoubleCid) {
      const String& name = String::Handle(Z, call->function().name());
      Token::Kind op_kind = MethodTokenRecognizer::RecognizeTokenKind(name);
      // TODO(dartbug.com/30480): Handle more double operations.
      if ((op_kind == Token::kADD) || (op_kind == Token::kSUB) ||
          (op_kind == Token::kMUL) || (op_kind == Token::kDIV)) {
        ASSERT(call->FirstArgIndex() == 0);
        Value* left_value = call->PushArgumentAt(0)->value();
        Value* right_value = call->PushArgumentAt(1)->value();
        if (right_value->Type()->IsNullableDouble() ||
            (right_value->Type()->ToNullableCid() == kSmiCid)) {
          left_value =
              PrepareReceiverOfDevirtualizedCall(left_value, kDoubleCid);
          right_value = PrepareStaticOpInput(right_value, kDoubleCid, call);
          replacement = new (Z)
              BinaryDoubleOpInstr(op_kind, left_value, right_value,
                                  Thread::kNoDeoptId, call->token_pos());
        }
      } else if ((op_kind == Token::kLT) || (op_kind == Token::kLTE) ||
                 (op_kind == Token::kGT) || (op_kind == Token::kGTE)) {
        ASSERT(call->FirstArgIndex() == 0);
        Value* left_value = call->PushArgumentAt(0)->value();
        Value* right_value = call->PushArgumentAt(1)->value();
        if (right_value->Type()->IsNullableDouble() ||
            (right_value->Type()->ToNullableCid() == kSmiCid)) {
          left_value =
              PrepareReceiverOfDevirtualizedCall(left_value, kDoubleCid);
          right_value = PrepareStaticOpInput(right_value, kDoubleCid, call);
          replacement = new (Z)
              RelationalOpInstr(call->token_pos(), op_kind, left_value,
                                right_value, kDoubleCid, Thread::kNoDeoptId);
        }
      } else if (op_kind == Token::kNEGATE) {
        ASSERT(call->FirstArgIndex() == 0);
        Value* left_value = call->PushArgumentAt(0)->value();
        left_value = PrepareReceiverOfDevirtualizedCall(left_value, kDoubleCid);
        replacement = new (Z)
            UnaryDoubleOpInstr(Token::kNEGATE, left_value, call->deopt_id());
      }
    }
  }

  if (replacement != NULL) {
    if (FLAG_trace_experimental_strong_mode) {
      THR_Print("[Strong mode] Optimization: replacing %s with %s\n",
                call->ToCString(), replacement->ToCString());
    }
    ReplaceCall(call, replacement);
    return true;
  }

  return false;
}

// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
// TODO(dartbug.com/30635) Evaluate how much this can be shared with
// JitCallSpecializer.
void AotCallSpecializer::VisitInstanceCall(InstanceCallInstr* instr) {
  ASSERT(FLAG_precompiled_mode);

  // Type test is special as it always gets converted into inlined code.
  const Token::Kind op_kind = instr->token_kind();
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }
  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }

  if (TryInlineFieldAccess(instr)) {
    return;
  }

  if (RecognizeRuntimeTypeGetter(instr)) {
    return;
  }

  if ((op_kind == Token::kEQ) && TryReplaceWithHaveSameRuntimeType(instr)) {
    return;
  }

  const intptr_t receiver_idx = instr->FirstArgIndex();
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());
  const intptr_t number_of_checks = unary_checks.NumberOfChecks();
  if (IsAllowedForInlining(instr->deopt_id()) && number_of_checks > 0) {
    if ((op_kind == Token::kINDEX) &&
        TryReplaceWithIndexedOp(instr, &unary_checks)) {
      return;
    }
    if ((op_kind == Token::kASSIGN_INDEX) &&
        TryReplaceWithIndexedOp(instr, &unary_checks)) {
      return;
    }
    if ((op_kind == Token::kEQ) && TryReplaceWithEqualityOp(instr, op_kind)) {
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

    if (TryInlineInstanceMethod(instr)) {
      return;
    }
  }

  if (FLAG_experimental_strong_mode &&
      TryOptimizeInstanceCallUsingStaticTypes(instr)) {
    return;
  }

  bool has_one_target = number_of_checks > 0 && unary_checks.HasOneTarget();
  if (has_one_target) {
    // Check if the single target is a polymorphic target, if it is,
    // we don't have one target.
    const Function& target = Function::Handle(Z, unary_checks.GetTargetAt(0));
    const bool polymorphic_target = MethodRecognizer::PolymorphicTarget(target);
    has_one_target = !polymorphic_target;
  }

  if (has_one_target) {
    RawFunction::Kind function_kind =
        Function::Handle(Z, unary_checks.GetTargetAt(0)).kind();
    if (!flow_graph()->InstanceCallNeedsClassCheck(instr, function_kind)) {
      CallTargets* targets = CallTargets::Create(Z, unary_checks);
      ASSERT(targets->HasSingleTarget());
      const Function& target = targets->FirstTarget();
      StaticCallInstr* call = StaticCallInstr::FromCall(Z, instr, target);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  switch (instr->token_kind()) {
    case Token::kEQ:
    case Token::kNE:
    case Token::kLT:
    case Token::kLTE:
    case Token::kGT:
    case Token::kGTE: {
      if (HasOnlyTwoOf(*instr->ic_data(), kSmiCid) ||
          HasLikelySmiOperand(instr)) {
        ASSERT(receiver_idx == 0);
        Definition* left = instr->ArgumentAt(0);
        Definition* right = instr->ArgumentAt(1);
        CheckedSmiComparisonInstr* smi_op = new (Z)
            CheckedSmiComparisonInstr(instr->token_kind(), new (Z) Value(left),
                                      new (Z) Value(right), instr);
        ReplaceCall(instr, smi_op);
        return;
      }
      break;
    }
    case Token::kSHL:
    case Token::kSHR:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL: {
      if (HasOnlyTwoOf(*instr->ic_data(), kSmiCid) ||
          HasLikelySmiOperand(instr)) {
        ASSERT(receiver_idx == 0);
        Definition* left = instr->ArgumentAt(0);
        Definition* right = instr->ArgumentAt(1);
        CheckedSmiOpInstr* smi_op =
            new (Z) CheckedSmiOpInstr(instr->token_kind(), new (Z) Value(left),
                                      new (Z) Value(right), instr);

        ReplaceCall(instr, smi_op);
        return;
      }
      break;
    }
    default:
      break;
  }

  // No IC data checks. Try resolve target using the propagated cid.
  const intptr_t receiver_cid =
      instr->PushArgumentAt(receiver_idx)->value()->Type()->ToCid();
  if (receiver_cid != kDynamicCid) {
    const Class& receiver_class =
        Class::Handle(Z, isolate()->class_table()->At(receiver_cid));
    const Function& function =
        Function::Handle(Z, instr->ResolveForReceiverClass(receiver_class));
    if (!function.IsNull()) {
      const Function& target = Function::ZoneHandle(Z, function.raw());
      StaticCallInstr* call = StaticCallInstr::FromCall(Z, instr, target);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  Definition* callee_receiver = instr->ArgumentAt(receiver_idx);
  const Function& function = flow_graph()->function();
  Class& receiver_class = Class::Handle(Z);

  if (function.IsDynamicFunction() &&
      flow_graph()->IsReceiver(callee_receiver)) {
    // Call receiver is method receiver.
    receiver_class = function.Owner();
  } else {
    // Check if we have an non-nullable compile type for the receiver.
    CompileType* type = instr->ArgumentAt(receiver_idx)->Type();
    if (type->ToAbstractType()->IsType() &&
        !type->ToAbstractType()->IsDynamicType() && !type->is_nullable()) {
      receiver_class = type->ToAbstractType()->type_class();
      if (receiver_class.is_implemented()) {
        receiver_class = Class::null();
      }
    }
  }
  if (!receiver_class.IsNull()) {
    GrowableArray<intptr_t> class_ids(6);
    if (thread()->cha()->ConcreteSubclasses(receiver_class, &class_ids)) {
      // First check if all subclasses end up calling the same method.
      // If this is the case we will replace instance call with a direct
      // static call.
      // Otherwise we will try to create ICData that contains all possible
      // targets with appropriate checks.
      Function& single_target = Function::Handle(Z);
      ICData& ic_data = ICData::Handle(Z);
      const Array& args_desc_array =
          Array::Handle(Z, instr->GetArgumentsDescriptor());
      Function& target = Function::Handle(Z);
      Class& cls = Class::Handle(Z);
      for (intptr_t i = 0; i < class_ids.length(); i++) {
        const intptr_t cid = class_ids[i];
        cls = isolate()->class_table()->At(cid);
        target = instr->ResolveForReceiverClass(cls);
        if (target.IsNull()) {
          // Can't resolve the target. It might be a noSuchMethod,
          // call through getter or closurization.
          single_target = Function::null();
          ic_data = ICData::null();
          break;
        } else if (ic_data.IsNull()) {
          // First we are trying to compute a single target for all subclasses.
          if (single_target.IsNull()) {
            ASSERT(i == 0);
            single_target = target.raw();
            continue;
          } else if (single_target.raw() == target.raw()) {
            continue;
          }

          // The call does not resolve to a single target within the hierarchy.
          // If we have too many subclasses abort the optimization.
          if (class_ids.length() > FLAG_max_exhaustive_polymorphic_checks) {
            single_target = Function::null();
            break;
          }

          // Create an ICData and map all previously seen classes (< i) to
          // the computed single_target.
          ic_data = ICData::New(function, instr->function_name(),
                                args_desc_array, Thread::kNoDeoptId,
                                /* args_tested = */ 1, ICData::kOptimized);
          for (intptr_t j = 0; j < i; j++) {
            ic_data.AddReceiverCheck(class_ids[j], single_target);
          }

          single_target = Function::null();
        }

        ASSERT(ic_data.raw() != ICData::null());
        ASSERT(single_target.raw() == Function::null());
        ic_data.AddReceiverCheck(cid, target);
      }

      if (single_target.raw() != Function::null()) {
        // If this is a getter or setter invocation try inlining it right away
        // instead of replacing it with a static call.
        if ((op_kind == Token::kGET) || (op_kind == Token::kSET)) {
          // Create fake IC data with the resolved target.
          const ICData& ic_data = ICData::Handle(
              ICData::New(flow_graph()->function(), instr->function_name(),
                          args_desc_array, Thread::kNoDeoptId,
                          /* args_tested = */ 1, ICData::kOptimized));
          cls = single_target.Owner();
          ic_data.AddReceiverCheck(cls.id(), single_target);
          instr->set_ic_data(&ic_data);

          if (TryInlineFieldAccess(instr)) {
            return;
          }
        }

        // We have computed that there is only a single target for this call
        // within the whole hierarchy. Replace InstanceCall with StaticCall.
        const Function& target = Function::ZoneHandle(Z, single_target.raw());
        StaticCallInstr* call = StaticCallInstr::FromCall(Z, instr, target);
        instr->ReplaceWith(call, current_iterator());
        return;
      } else if ((ic_data.raw() != ICData::null()) &&
                 !ic_data.NumberOfChecksIs(0)) {
        CallTargets* targets = CallTargets::Create(Z, ic_data);
        PolymorphicInstanceCallInstr* call =
            new (Z) PolymorphicInstanceCallInstr(instr, *targets,
                                                 /* complete = */ true);
        instr->ReplaceWith(call, current_iterator());
        return;
      }
    }
  }

  // More than one target. Generate generic polymorphic call without
  // deoptimization.
  if (instr->ic_data()->NumberOfUsedChecks() > 0) {
    ASSERT(!FLAG_polymorphic_with_deopt);
    // OK to use checks with PolymorphicInstanceCallInstr since no
    // deoptimization is allowed.
    CallTargets* targets = CallTargets::Create(Z, *instr->ic_data());
    PolymorphicInstanceCallInstr* call =
        new (Z) PolymorphicInstanceCallInstr(instr, *targets,
                                             /* complete = */ false);
    instr->ReplaceWith(call, current_iterator());
    return;
  }
}

void AotCallSpecializer::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  const intptr_t receiver_idx = call->type_args_len() > 0 ? 1 : 0;
  const intptr_t receiver_cid =
      call->PushArgumentAt(receiver_idx)->value()->Type()->ToCid();
  if (receiver_cid != kDynamicCid) {
    const Class& receiver_class =
        Class::Handle(Z, isolate()->class_table()->At(receiver_cid));
    const Function& function = Function::ZoneHandle(
        Z, call->instance_call()->ResolveForReceiverClass(receiver_class));
    if (!function.IsNull()) {
      // Only one target. Replace by static call.
      StaticCallInstr* new_call = StaticCallInstr::FromCall(Z, call, function);
      call->ReplaceWith(new_call, current_iterator());
    }
  }
}

bool AotCallSpecializer::TryReplaceInstanceOfWithRangeCheck(
    InstanceCallInstr* call,
    const AbstractType& type) {
  if (precompiler_ == NULL) {
    // Loading not complete, can't do CHA yet.
    return false;
  }

  TypeRangeCache* cache = precompiler_->type_range_cache();
  if (cache == NULL) {
    return false;
  }

  intptr_t lower_limit, upper_limit;
  if (!cache->InstanceOfHasClassRange(type, &lower_limit, &upper_limit)) {
    return false;
  }

  Definition* left = call->ArgumentAt(0);

  // left.instanceof(type) =>
  //     _classRangeCheck(left.cid, lower_limit, upper_limit)
  LoadClassIdInstr* left_cid = new (Z) LoadClassIdInstr(new (Z) Value(left));
  InsertBefore(call, left_cid, NULL, FlowGraph::kValue);
  ConstantInstr* lower_cid =
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(lower_limit)));

  if (lower_limit == upper_limit) {
    StrictCompareInstr* check_cid = new (Z)
        StrictCompareInstr(call->token_pos(), Token::kEQ_STRICT,
                           new (Z) Value(left_cid), new (Z) Value(lower_cid),
                           /* number_check = */ false, Thread::kNoDeoptId);
    ReplaceCall(call, check_cid);
    return true;
  }

  ConstantInstr* upper_cid =
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(upper_limit)));

  ZoneGrowableArray<PushArgumentInstr*>* args =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(3);
  PushArgumentInstr* arg = new (Z) PushArgumentInstr(new (Z) Value(left_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(lower_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(upper_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);

  const Library& dart_internal = Library::Handle(Z, Library::InternalLibrary());
  const String& target_name = Symbols::_classRangeCheck();
  const Function& target = Function::ZoneHandle(
      Z, dart_internal.LookupFunctionAllowPrivate(target_name));
  ASSERT(!target.IsNull());
  ASSERT(target.IsRecognized() && target.always_inline());

  const intptr_t kTypeArgsLen = 0;
  StaticCallInstr* new_call = new (Z) StaticCallInstr(
      call->token_pos(), target, kTypeArgsLen,
      Object::null_array(),  // argument_names
      args, call->deopt_id(), call->CallCount(), ICData::kOptimized);
  Environment* copy =
      call->env()->DeepCopy(Z, call->env()->Length() - call->ArgumentCount());
  for (intptr_t i = 0; i < args->length(); ++i) {
    copy->PushValue(new (Z) Value((*args)[i]->value()->definition()));
  }
  call->RemoveEnvironment();
  ReplaceCall(call, new_call);
  copy->DeepCopyTo(Z, new_call);
  return true;
}

bool AotCallSpecializer::TryReplaceTypeCastWithRangeCheck(
    InstanceCallInstr* call,
    const AbstractType& type) {
  if (precompiler_ == NULL) {
    // Loading not complete, can't do CHA yet.
    return false;
  }

  TypeRangeCache* cache = precompiler_->type_range_cache();
  if (cache == NULL) {
    return false;
  }

  intptr_t lower_limit, upper_limit;
  if (!cache->InstanceOfHasClassRange(type, &lower_limit, &upper_limit)) {
    return false;
  }

  Definition* left = call->ArgumentAt(0);

  // left as type =>
  //     _classRangeCheck(pos, left, type, left.cid, lower_limit, upper_limit)
  LoadClassIdInstr* left_cid = new (Z) LoadClassIdInstr(new (Z) Value(left));
  InsertBefore(call, left_cid, NULL, FlowGraph::kValue);
  ConstantInstr* lower_cid =
      flow_graph()->GetConstant(Smi::ZoneHandle(Z, Smi::New(lower_limit)));
  ConstantInstr* upper_cid =
      flow_graph()->GetConstant(Smi::ZoneHandle(Z, Smi::New(upper_limit)));
  ConstantInstr* pos = flow_graph()->GetConstant(
      Smi::ZoneHandle(Z, Smi::New(call->token_pos().Pos())));

  ZoneGrowableArray<PushArgumentInstr*>* args =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(6);
  PushArgumentInstr* arg = new (Z) PushArgumentInstr(new (Z) Value(pos));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(left));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg =
      new (Z) PushArgumentInstr(new (Z) Value(flow_graph()->GetConstant(type)));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(left_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(lower_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);
  arg = new (Z) PushArgumentInstr(new (Z) Value(upper_cid));
  InsertBefore(call, arg, NULL, FlowGraph::kEffect);
  args->Add(arg);

  const Library& dart_internal = Library::Handle(Z, Library::CoreLibrary());
  const String& target_name = Symbols::_classRangeAssert();
  const Function& target = Function::ZoneHandle(
      Z, dart_internal.LookupFunctionAllowPrivate(target_name));
  ASSERT(!target.IsNull());
  ASSERT(target.IsRecognized());
  ASSERT(target.always_inline());

  const intptr_t kTypeArgsLen = 0;
  StaticCallInstr* new_call = new (Z) StaticCallInstr(
      call->token_pos(), target, kTypeArgsLen,
      Object::null_array(),  // argument_names
      args, call->deopt_id(), call->CallCount(), ICData::kOptimized);
  Environment* copy =
      call->env()->DeepCopy(Z, call->env()->Length() - call->ArgumentCount());
  for (intptr_t i = 0; i < args->length(); ++i) {
    copy->PushValue(new (Z) Value((*args)[i]->value()->definition()));
  }
  call->RemoveEnvironment();
  ReplaceCall(call, new_call);
  copy->DeepCopyTo(Z, new_call);
  return true;
}

void AotCallSpecializer::ReplaceArrayBoundChecks() {
  for (BlockIterator block_it = flow_graph()->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      CheckArrayBoundInstr* check = it.Current()->AsCheckArrayBound();
      if (check != NULL) {
        GenericCheckBoundInstr* new_check = new (Z) GenericCheckBoundInstr(
            new (Z) Value(check->length()->definition()),
            new (Z) Value(check->index()->definition()), check->deopt_id());
        flow_graph()->InsertBefore(check, new_check, check->env(),
                                   FlowGraph::kEffect);
        current_iterator()->RemoveCurrentFromGraph();
      }
    }
  }
}

#endif  // DART_PRECOMPILER

}  // namespace dart
