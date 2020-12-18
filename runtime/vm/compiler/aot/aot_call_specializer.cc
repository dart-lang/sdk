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
#include "vm/compiler/compiler_state.h"
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
  UniqueFunctionsMap functions_map(
      isolate->object_store()->unique_dynamic_targets());
  ASSERT(fname.IsSymbol());
  *function = functions_map.GetOrNull(fname);
  ASSERT(functions_map.Release().raw() ==
         isolate->object_store()->unique_dynamic_targets());
}

AotCallSpecializer::AotCallSpecializer(
    Precompiler* precompiler,
    FlowGraph* flow_graph,
    SpeculativeInliningPolicy* speculative_policy)
    : CallSpecializer(flow_graph,
                      speculative_policy,
                      /* should_clone_fields=*/false),
      precompiler_(precompiler),
      has_unique_no_such_method_(false) {
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

  call->SetTargets(
      CallTargets::CreateMonomorphic(Z, cls.id(), target_function));
  ASSERT(call->Targets().IsMonomorphic());

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
    if (FlowGraph::NeedsPairLocation(redefinition->representation())) {
      flow_graph()->alloc_ssa_temp_index();
    }
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
  StaticCallInstr* static_call =
      StaticCallInstr::FromCall(Z, call, target, call->CallCount());
  static_call->SetResultType(Z, CompileType::FromCid(kTypeCid));
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
    TemplateDartCall<0>* call) {
  ASSERT((call->IsInstanceCall() &&
          (call->AsInstanceCall()->ic_data()->NumArgsTested() == 2)) ||
         call->IsStaticCall());
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

    InputsArray* args = new (Z) InputsArray(Z, 2);
    args->Add(left->ArgumentValueAt(0)->CopyWithType(Z));
    args->Add(right->ArgumentValueAt(0)->CopyWithType(Z));
    const intptr_t kTypeArgsLen = 0;
    StaticCallInstr* static_call = new (Z) StaticCallInstr(
        call->source(), have_same_runtime_type, kTypeArgsLen,
        Object::null_array(),  // argument_names
        args, call->deopt_id(), call->CallCount(), ICData::kOptimized);
    static_call->SetResultType(Z, CompileType::FromCid(kBoolCid));
    ReplaceCall(call, static_call);
    // ReplaceCall moved environment from 'call' to 'static_call'.
    // Update arguments of 'static_call' in the environment.
    Environment* env = static_call->env();
    env->ValueAt(env->Length() - 2)
        ->BindToEnvironment(static_call->ArgumentAt(0));
    env->ValueAt(env->Length() - 1)
        ->BindToEnvironment(static_call->ArgumentAt(1));
    return true;
  }

  return false;
}

static bool HasLikelySmiOperand(InstanceCallInstr* instr) {
  ASSERT(instr->type_args_len() == 0);

  // If Smi is not assignable to the interface target of the call, the receiver
  // is definitely not a Smi.
  if (!instr->CanReceiverBeSmiBasedOnInterfaceTarget(
          Thread::Current()->zone())) {
    return false;
  }

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
  if ((op_kind == Token::kSET) && TryInlineInstanceSetter(call)) {
    return true;
  }
  return false;
}

bool AotCallSpecializer::TryInlineFieldAccess(StaticCallInstr* call) {
  if (call->function().IsImplicitGetterFunction()) {
    Field& field = Field::ZoneHandle(call->function().accessor_field());
    if (field.is_late()) {
      // TODO(dartbug.com/40447): Inline implicit getters for late fields.
      return false;
    }
    if (should_clone_fields_) {
      field = field.CloneFromOriginal();
    }
    InlineImplicitInstanceGetter(call, field);
    return true;
  }

  return false;
}

bool AotCallSpecializer::IsSupportedIntOperandForStaticDoubleOp(
    CompileType* operand_type) {
  if (operand_type->IsNullableInt()) {
    if (operand_type->ToNullableCid() == kSmiCid) {
      return true;
    }

    if (FlowGraphCompiler::SupportsUnboxedInt64() &&
        FlowGraphCompiler::CanConvertInt64ToDouble()) {
      return true;
    }
  }

  return false;
}

Value* AotCallSpecializer::PrepareStaticOpInput(Value* input,
                                                intptr_t cid,
                                                Instruction* call) {
  ASSERT((cid == kDoubleCid) || (cid == kMintCid));

  if (input->Type()->is_nullable()) {
    const String& function_name =
        (call->IsInstanceCall()
             ? call->AsInstanceCall()->function_name()
             : String::ZoneHandle(Z, call->AsStaticCall()->function().name()));
    AddCheckNull(input, function_name, call->deopt_id(), call->env(), call);
  }

  input = input->CopyWithType(Z);

  if (cid == kDoubleCid && input->Type()->IsNullableInt()) {
    Definition* conversion = NULL;

    if (input->Type()->ToNullableCid() == kSmiCid) {
      conversion = new (Z) SmiToDoubleInstr(input, call->source());
    } else if (FlowGraphCompiler::SupportsUnboxedInt64() &&
               FlowGraphCompiler::CanConvertInt64ToDouble()) {
      conversion = new (Z) Int64ToDoubleInstr(input, DeoptId::kNone,
                                              Instruction::kNotSpeculative);
    } else {
      UNREACHABLE();
    }

    if (FLAG_trace_strong_mode_types) {
      THR_Print("[Strong mode] Inserted %s\n", conversion->ToCString());
    }
    InsertBefore(call, conversion, /* env = */ NULL, FlowGraph::kValue);
    return new (Z) Value(conversion);
  }

  return input;
}

CompileType AotCallSpecializer::BuildStrengthenedReceiverType(Value* input,
                                                              intptr_t cid) {
  CompileType* old_type = input->Type();
  CompileType* refined_type = old_type;

  CompileType type = CompileType::None();
  if (cid == kSmiCid) {
    type = CompileType::NullableSmi();
    refined_type = CompileType::ComputeRefinedType(old_type, &type);
  } else if (cid == kMintCid) {
    type = CompileType::NullableMint();
    refined_type = CompileType::ComputeRefinedType(old_type, &type);
  } else if (cid == kIntegerCid && !input->Type()->IsNullableInt()) {
    type = CompileType::NullableInt();
    refined_type = CompileType::ComputeRefinedType(old_type, &type);
  } else if (cid == kDoubleCid && !input->Type()->IsNullableDouble()) {
    type = CompileType::NullableDouble();
    refined_type = CompileType::ComputeRefinedType(old_type, &type);
  }

  if (refined_type != old_type) {
    return *refined_type;
  }
  return CompileType::None();
}

// After replacing a call with a specialized instruction, make sure to
// update types at all uses, as specialized instruction can provide a more
// specific type.
static void RefineUseTypes(Definition* instr) {
  CompileType* new_type = instr->Type();
  for (Value::Iterator it(instr->input_use_list()); !it.Done(); it.Advance()) {
    it.Current()->RefineReachingType(new_type);
  }
}

bool AotCallSpecializer::TryOptimizeInstanceCallUsingStaticTypes(
    InstanceCallInstr* instr) {
  const Token::Kind op_kind = instr->token_kind();
  return TryOptimizeIntegerOperation(instr, op_kind) ||
         TryOptimizeDoubleOperation(instr, op_kind);
}

bool AotCallSpecializer::TryOptimizeStaticCallUsingStaticTypes(
    StaticCallInstr* instr) {
  const String& name = String::Handle(Z, instr->function().name());
  const Token::Kind op_kind = MethodTokenRecognizer::RecognizeTokenKind(name);

  if (op_kind == Token::kEQ && TryReplaceWithHaveSameRuntimeType(instr)) {
    return true;
  }

  // We only specialize instance methods for int/double operations.
  const auto& target = instr->function();
  if (!target.IsDynamicFunction()) {
    return false;
  }

  // For de-virtualized instance calls, we strengthen the type here manually
  // because it might not be attached to the receiver.
  // See http://dartbug.com/35179 for preserving the receiver type information.
  const Class& owner = Class::Handle(Z, target.Owner());
  const intptr_t cid = owner.id();
  if (cid == kSmiCid || cid == kMintCid || cid == kIntegerCid ||
      cid == kDoubleCid) {
    // Sometimes TFA de-virtualizes instance calls to static calls.  In such
    // cases the VM might have a looser type on the receiver, so we explicitly
    // tighten it (this is safe since it was proven that the receiver is either
    // null or will end up with that target).
    const intptr_t receiver_index = instr->FirstArgIndex();
    const intptr_t argument_count = instr->ArgumentCountWithoutTypeArgs();
    if (argument_count >= 1) {
      auto receiver_value = instr->ArgumentValueAt(receiver_index);
      auto receiver = receiver_value->definition();
      auto type = BuildStrengthenedReceiverType(receiver_value, cid);
      if (!type.IsNone()) {
        auto redefinition =
            flow_graph()->EnsureRedefinition(instr->previous(), receiver, type);
        if (redefinition != nullptr) {
          RefineUseTypes(redefinition);
        }
      }
    }
  }

  return TryOptimizeIntegerOperation(instr, op_kind) ||
         TryOptimizeDoubleOperation(instr, op_kind);
}

// Modulo against a constant power-of-two can be optimized into a mask.
// x % y -> x & (|y| - 1)  for smi masks only
Definition* AotCallSpecializer::TryOptimizeMod(TemplateDartCall<0>* instr,
                                               Token::Kind op_kind,
                                               Value* left_value,
                                               Value* right_value) {
  if (!right_value->BindsToConstant()) {
    return nullptr;
  }

  const Object& rhs = right_value->BoundConstant();
  const int64_t value = Integer::Cast(rhs).AsInt64Value();  // smi and mint
  if (value == kMinInt64) {
    return nullptr;  // non-smi mask
  }
  const int64_t modulus = Utils::Abs(value);
  if (!Utils::IsPowerOfTwo(modulus) || !compiler::target::IsSmi(modulus - 1)) {
    return nullptr;
  }

  left_value = PrepareStaticOpInput(left_value, kMintCid, instr);

#if defined(TARGET_ARCH_ARM)
  Definition* right_definition = new (Z) UnboxedConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(modulus - 1)), kUnboxedInt32);
  InsertBefore(instr, right_definition, /*env=*/NULL, FlowGraph::kValue);
  right_definition = new (Z)
      IntConverterInstr(kUnboxedInt32, kUnboxedInt64,
                        new (Z) Value(right_definition), DeoptId::kNone);
#else
  Definition* right_definition = new (Z) UnboxedConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(modulus - 1)), kUnboxedInt64);
#endif
  if (modulus == 1) return right_definition;
  InsertBefore(instr, right_definition, /*env=*/NULL, FlowGraph::kValue);
  right_value = new (Z) Value(right_definition);
  return new (Z)
      BinaryInt64OpInstr(Token::kBIT_AND, left_value, right_value,
                         DeoptId::kNone, Instruction::kNotSpeculative);
}

bool AotCallSpecializer::TryOptimizeIntegerOperation(TemplateDartCall<0>* instr,
                                                     Token::Kind op_kind) {
  if (instr->type_args_len() != 0) {
    // Arithmetic operations don't have type arguments.
    return false;
  }

  Definition* replacement = NULL;
  if (instr->ArgumentCount() == 2) {
    Value* left_value = instr->ArgumentValueAt(0);
    Value* right_value = instr->ArgumentValueAt(1);
    CompileType* left_type = left_value->Type();
    CompileType* right_type = right_value->Type();

    const bool is_equality_op = Token::IsEqualityOperator(op_kind);
    bool has_nullable_int_args =
        left_type->IsNullableInt() && right_type->IsNullableInt();

    if (auto* call = instr->AsInstanceCall()) {
      if (!call->CanReceiverBeSmiBasedOnInterfaceTarget(zone())) {
        has_nullable_int_args = false;
      }
    }

    // NOTE: We cannot use strict comparisons if the receiver has an overridden
    // == operator or if either side can be a double, since 1.0 == 1.
    const bool can_use_strict_compare =
        is_equality_op && has_nullable_int_args &&
        (left_type->IsNullableSmi() || right_type->IsNullableSmi());

    // We only support binary operations if both operands are nullable integers
    // or when we can use a cheap strict comparison operation.
    if (!has_nullable_int_args) {
      return false;
    }

    switch (op_kind) {
      case Token::kEQ:
      case Token::kNE:
      case Token::kLT:
      case Token::kLTE:
      case Token::kGT:
      case Token::kGTE: {
        const bool supports_unboxed_int =
            FlowGraphCompiler::SupportsUnboxedInt64();
        const bool can_use_equality_compare =
            supports_unboxed_int && is_equality_op && left_type->IsInt() &&
            right_type->IsInt();

        // We prefer equality compare, since it doesn't require boxing.
        if (!can_use_equality_compare && can_use_strict_compare) {
          replacement = new (Z) StrictCompareInstr(
              instr->source(),
              (op_kind == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
              left_value->CopyWithType(Z), right_value->CopyWithType(Z),
              /*needs_number_check=*/false, DeoptId::kNone);
          break;
        }

        if (supports_unboxed_int) {
          if (can_use_equality_compare) {
            replacement = new (Z) EqualityCompareInstr(
                instr->source(), op_kind, left_value->CopyWithType(Z),
                right_value->CopyWithType(Z), kMintCid, DeoptId::kNone,
                Instruction::kNotSpeculative);
            break;
          } else if (Token::IsRelationalOperator(op_kind)) {
            left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
            right_value = PrepareStaticOpInput(right_value, kMintCid, instr);
            replacement = new (Z) RelationalOpInstr(
                instr->source(), op_kind, left_value, right_value, kMintCid,
                DeoptId::kNone, Instruction::kNotSpeculative);
            break;
          } else {
            // TODO(dartbug.com/30480): Figure out how to handle null in
            // equality comparisons.
            replacement = new (Z)
                CheckedSmiComparisonInstr(op_kind, left_value->CopyWithType(Z),
                                          right_value->CopyWithType(Z), instr);
            break;
          }
        } else {
          replacement = new (Z)
              CheckedSmiComparisonInstr(op_kind, left_value->CopyWithType(Z),
                                        right_value->CopyWithType(Z), instr);
          break;
        }
        break;
      }
      case Token::kMOD:
        replacement = TryOptimizeMod(instr, op_kind, left_value, right_value);
        if (replacement != nullptr) break;
        FALL_THROUGH;
      case Token::kTRUNCDIV:
#if !defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64)
        // TODO(ajcbik): 32-bit archs too?
        break;
#else
        FALL_THROUGH;
#endif
      case Token::kSHL:
        FALL_THROUGH;
      case Token::kSHR:
        FALL_THROUGH;
      case Token::kBIT_OR:
        FALL_THROUGH;
      case Token::kBIT_XOR:
        FALL_THROUGH;
      case Token::kBIT_AND:
        FALL_THROUGH;
      case Token::kADD:
        FALL_THROUGH;
      case Token::kSUB:
        FALL_THROUGH;
      case Token::kMUL: {
        if (FlowGraphCompiler::SupportsUnboxedInt64()) {
          if (op_kind == Token::kSHR || op_kind == Token::kSHL) {
            left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
            right_value = PrepareStaticOpInput(right_value, kMintCid, instr);
            replacement = new (Z) ShiftInt64OpInstr(
                op_kind, left_value, right_value, DeoptId::kNone);
            break;
          } else {
            left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
            right_value = PrepareStaticOpInput(right_value, kMintCid, instr);
            replacement = new (Z) BinaryInt64OpInstr(
                op_kind, left_value, right_value, DeoptId::kNone,
                Instruction::kNotSpeculative);
            break;
          }
        }
        if (op_kind != Token::kMOD && op_kind != Token::kTRUNCDIV) {
          replacement =
              new (Z) CheckedSmiOpInstr(op_kind, left_value->CopyWithType(Z),
                                        right_value->CopyWithType(Z), instr);
          break;
        }
        break;
      }

      default:
        break;
    }
  } else if (instr->ArgumentCount() == 1) {
    Value* left_value = instr->ArgumentValueAt(0);
    CompileType* left_type = left_value->Type();

    // We only support unary operations on nullable integers.
    if (!left_type->IsNullableInt()) {
      return false;
    }

    if (FlowGraphCompiler::SupportsUnboxedInt64()) {
      if (op_kind == Token::kNEGATE || op_kind == Token::kBIT_NOT) {
        left_value = PrepareStaticOpInput(left_value, kMintCid, instr);
        replacement = new (Z) UnaryInt64OpInstr(
            op_kind, left_value, DeoptId::kNone, Instruction::kNotSpeculative);
      }
    }
  }

  if (replacement != nullptr && !replacement->ComputeCanDeoptimize()) {
    if (FLAG_trace_strong_mode_types) {
      THR_Print("[Strong mode] Optimization: replacing %s with %s\n",
                instr->ToCString(), replacement->ToCString());
    }
    ReplaceCall(instr, replacement);
    RefineUseTypes(replacement);
    return true;
  }

  return false;
}

bool AotCallSpecializer::TryOptimizeDoubleOperation(TemplateDartCall<0>* instr,
                                                    Token::Kind op_kind) {
  if (instr->type_args_len() != 0) {
    // Arithmetic operations don't have type arguments.
    return false;
  }

  if (!FlowGraphCompiler::SupportsUnboxedDoubles()) {
    return false;
  }

  Definition* replacement = NULL;

  if (instr->ArgumentCount() == 2) {
    Value* left_value = instr->ArgumentValueAt(0);
    Value* right_value = instr->ArgumentValueAt(1);
    CompileType* left_type = left_value->Type();
    CompileType* right_type = right_value->Type();

    if (!left_type->IsNullableDouble() &&
        !IsSupportedIntOperandForStaticDoubleOp(left_type)) {
      return false;
    }
    if (!right_type->IsNullableDouble() &&
        !IsSupportedIntOperandForStaticDoubleOp(right_type)) {
      return false;
    }

    switch (op_kind) {
      case Token::kEQ:
        FALL_THROUGH;
      case Token::kNE: {
        // TODO(dartbug.com/32166): Support EQ, NE for nullable doubles.
        // (requires null-aware comparison instruction).
        if (left_type->IsDouble() && right_type->IsDouble()) {
          left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
          right_value = PrepareStaticOpInput(right_value, kDoubleCid, instr);
          replacement = new (Z) EqualityCompareInstr(
              instr->source(), op_kind, left_value, right_value, kDoubleCid,
              DeoptId::kNone, Instruction::kNotSpeculative);
          break;
        }
        break;
      }
      case Token::kLT:
        FALL_THROUGH;
      case Token::kLTE:
        FALL_THROUGH;
      case Token::kGT:
        FALL_THROUGH;
      case Token::kGTE: {
        left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
        right_value = PrepareStaticOpInput(right_value, kDoubleCid, instr);
        replacement = new (Z) RelationalOpInstr(
            instr->source(), op_kind, left_value, right_value, kDoubleCid,
            DeoptId::kNone, Instruction::kNotSpeculative);
        break;
      }
      case Token::kADD:
        FALL_THROUGH;
      case Token::kSUB:
        FALL_THROUGH;
      case Token::kMUL:
        FALL_THROUGH;
      case Token::kDIV: {
        if (op_kind == Token::kDIV &&
            !FlowGraphCompiler::SupportsHardwareDivision()) {
          return false;
        }
        left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
        right_value = PrepareStaticOpInput(right_value, kDoubleCid, instr);
        replacement = new (Z) BinaryDoubleOpInstr(
            op_kind, left_value, right_value, DeoptId::kNone, instr->source(),
            Instruction::kNotSpeculative);
        break;
      }

      case Token::kBIT_OR:
        FALL_THROUGH;
      case Token::kBIT_XOR:
        FALL_THROUGH;
      case Token::kBIT_AND:
        FALL_THROUGH;
      case Token::kMOD:
        FALL_THROUGH;
      case Token::kTRUNCDIV:
        FALL_THROUGH;
      default:
        break;
    }
  } else if (instr->ArgumentCount() == 1) {
    Value* left_value = instr->ArgumentValueAt(0);
    CompileType* left_type = left_value->Type();

    // We only support unary operations on nullable doubles.
    if (!left_type->IsNullableDouble()) {
      return false;
    }

    if (op_kind == Token::kNEGATE) {
      left_value = PrepareStaticOpInput(left_value, kDoubleCid, instr);
      replacement = new (Z)
          UnaryDoubleOpInstr(Token::kNEGATE, left_value, instr->deopt_id(),
                             Instruction::kNotSpeculative);
    }
  }

  if (replacement != NULL && !replacement->ComputeCanDeoptimize()) {
    if (FLAG_trace_strong_mode_types) {
      THR_Print("[Strong mode] Optimization: replacing %s with %s\n",
                instr->ToCString(), replacement->ToCString());
    }
    ReplaceCall(instr, replacement);
    RefineUseTypes(replacement);
    return true;
  }

  return false;
}

static void EnsureICData(Zone* zone,
                         const Function& function,
                         InstanceCallInstr* call) {
  if (!call->HasICData()) {
    const Array& arguments_descriptor =
        Array::Handle(zone, call->GetArgumentsDescriptor());
    const ICData& ic_data = ICData::ZoneHandle(
        zone, ICData::New(function, call->function_name(), arguments_descriptor,
                          call->deopt_id(), call->checked_argument_count(),
                          ICData::kInstance));
    call->set_ic_data(&ic_data);
  }
}

// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
// TODO(dartbug.com/30635) Evaluate how much this can be shared with
// JitCallSpecializer.
void AotCallSpecializer::VisitInstanceCall(InstanceCallInstr* instr) {
  // Type test is special as it always gets converted into inlined code.
  const Token::Kind op_kind = instr->token_kind();
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
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

  const CallTargets& targets = instr->Targets();
  const intptr_t receiver_idx = instr->FirstArgIndex();

  if (TryOptimizeInstanceCallUsingStaticTypes(instr)) {
    return;
  }

  bool has_one_target = targets.HasSingleTarget();
  if (has_one_target) {
    // Check if the single target is a polymorphic target, if it is,
    // we don't have one target.
    const Function& target = targets.FirstTarget();
    has_one_target = !target.is_polymorphic_target();
  }

  if (has_one_target) {
    const Function& target = targets.FirstTarget();
    FunctionLayout::Kind function_kind = target.kind();
    if (flow_graph()->CheckForInstanceCall(instr, function_kind) ==
        FlowGraph::ToCheck::kNoCheck) {
      StaticCallInstr* call = StaticCallInstr::FromCall(
          Z, instr, target, targets.AggregateCallCount());
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
      if (instr->BinaryFeedback().OperandsAre(kSmiCid) ||
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
      if (instr->BinaryFeedback().OperandsAre(kSmiCid) ||
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
      instr->ArgumentValueAt(receiver_idx)->Type()->ToCid();
  if (receiver_cid != kDynamicCid) {
    const Class& receiver_class =
        Class::Handle(Z, isolate()->class_table()->At(receiver_cid));
    const Function& function =
        Function::Handle(Z, instr->ResolveForReceiverClass(receiver_class));
    if (!function.IsNull()) {
      const Function& target = Function::ZoneHandle(Z, function.raw());
      StaticCallInstr* call =
          StaticCallInstr::FromCall(Z, instr, target, instr->CallCount());
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  // Check for x == y, where x has type T?, there are no subtypes of T, and
  // T does not override ==. Replace with StrictCompare.
  if (instr->token_kind() == Token::kEQ || instr->token_kind() == Token::kNE) {
    GrowableArray<intptr_t> class_ids(6);
    if (instr->ArgumentValueAt(receiver_idx)->Type()->Specialize(&class_ids)) {
      bool is_object_eq = true;
      for (intptr_t i = 0; i < class_ids.length(); i++) {
        const intptr_t cid = class_ids[i];
        // Skip sentinel cid. It may appear in the unreachable code after
        // inlining a method which doesn't return.
        if (cid == kNeverCid) continue;
        const Class& cls = Class::Handle(Z, isolate()->class_table()->At(cid));
        const Function& target =
            Function::Handle(Z, instr->ResolveForReceiverClass(cls));
        if (target.recognized_kind() != MethodRecognizer::kObjectEquals) {
          is_object_eq = false;
          break;
        }
      }
      if (is_object_eq) {
        auto* replacement = new (Z) StrictCompareInstr(
            instr->source(),
            (instr->token_kind() == Token::kEQ) ? Token::kEQ_STRICT
                                                : Token::kNE_STRICT,
            instr->ArgumentValueAt(0)->CopyWithType(Z),
            instr->ArgumentValueAt(1)->CopyWithType(Z),
            /*needs_number_check=*/false, DeoptId::kNone);
        ReplaceCall(instr, replacement);
        RefineUseTypes(replacement);
        return;
      }
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
    if (thread()->compiler_state().cha().ConcreteSubclasses(receiver_class,
                                                            &class_ids)) {
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
        ASSERT(target.IsNull() || !target.IsInvokeFieldDispatcher());
        if (target.IsNull()) {
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
                                args_desc_array, DeoptId::kNone,
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
                          args_desc_array, DeoptId::kNone,
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
        StaticCallInstr* call =
            StaticCallInstr::FromCall(Z, instr, target, instr->CallCount());
        instr->ReplaceWith(call, current_iterator());
        return;
      } else if ((ic_data.raw() != ICData::null()) &&
                 !ic_data.NumberOfChecksIs(0)) {
        const CallTargets* targets = CallTargets::Create(Z, ic_data);
        ASSERT(!targets->is_empty());
        PolymorphicInstanceCallInstr* call =
            PolymorphicInstanceCallInstr::FromCall(Z, instr, *targets,
                                                   /* complete = */ true);
        instr->ReplaceWith(call, current_iterator());
        return;
      }
    }

    // Detect if o.m(...) is a call through a getter and expand it
    // into o.get:m().call(...).
    if (TryExpandCallThroughGetter(receiver_class, instr)) {
      return;
    }
  }

  // More than one target. Generate generic polymorphic call without
  // deoptimization.
  if (targets.length() > 0) {
    ASSERT(!FLAG_polymorphic_with_deopt);
    // OK to use checks with PolymorphicInstanceCallInstr since no
    // deoptimization is allowed.
    PolymorphicInstanceCallInstr* call =
        PolymorphicInstanceCallInstr::FromCall(Z, instr, targets,
                                               /* complete = */ false);
    instr->ReplaceWith(call, current_iterator());
    return;
  }
}

void AotCallSpecializer::VisitStaticCall(StaticCallInstr* instr) {
  if (TryInlineFieldAccess(instr)) {
    return;
  }
  CallSpecializer::VisitStaticCall(instr);
}

bool AotCallSpecializer::TryExpandCallThroughGetter(const Class& receiver_class,
                                                    InstanceCallInstr* call) {
  // If it's an accessor call it can't be a call through getter.
  if (call->token_kind() == Token::kGET || call->token_kind() == Token::kSET) {
    return false;
  }

  // Ignore callsites like f.call() for now. Those need to be handled
  // specially if f is a closure.
  if (call->function_name().raw() == Symbols::Call().raw()) {
    return false;
  }

  Function& target = Function::Handle(Z);

  const String& getter_name = String::ZoneHandle(
      Z, Symbols::LookupFromGet(thread(), call->function_name()));
  if (getter_name.IsNull()) {
    return false;
  }

  const Array& args_desc_array = Array::Handle(
      Z,
      ArgumentsDescriptor::NewBoxed(/*type_args_len=*/0, /*num_arguments=*/1));
  ArgumentsDescriptor args_desc(args_desc_array);
  target = Resolver::ResolveDynamicForReceiverClass(
      receiver_class, getter_name, args_desc, /*allow_add=*/false);
  if (target.raw() == Function::null() || target.IsMethodExtractor()) {
    return false;
  }

  // We found a getter with the same name as the method this
  // call tries to invoke. This implies call through getter
  // because methods can't override getters. Build
  // o.get:m().call(...) sequence and replace o.m(...) invocation.

  const intptr_t receiver_idx = call->type_args_len() > 0 ? 1 : 0;

  InputsArray* get_arguments = new (Z) InputsArray(Z, 1);
  get_arguments->Add(call->ArgumentValueAt(receiver_idx)->CopyWithType(Z));
  InstanceCallInstr* invoke_get = new (Z)
      InstanceCallInstr(call->source(), getter_name, Token::kGET, get_arguments,
                        /*type_args_len=*/0,
                        /*argument_names=*/Object::empty_array(),
                        /*checked_argument_count=*/1,
                        thread()->compiler_state().GetNextDeoptId());

  // Arguments to the .call() are the same as arguments to the
  // original call (including type arguments), but receiver
  // is replaced with the result of the get.
  InputsArray* call_arguments = new (Z) InputsArray(Z, call->ArgumentCount());
  if (call->type_args_len() > 0) {
    call_arguments->Add(call->ArgumentValueAt(0)->CopyWithType(Z));
  }
  call_arguments->Add(new (Z) Value(invoke_get));
  for (intptr_t i = receiver_idx + 1; i < call->ArgumentCount(); i++) {
    call_arguments->Add(call->ArgumentValueAt(i)->CopyWithType(Z));
  }

  InstanceCallInstr* invoke_call = new (Z) InstanceCallInstr(
      call->source(), Symbols::Call(), Token::kILLEGAL, call_arguments,
      call->type_args_len(), call->argument_names(),
      /*checked_argument_count=*/1,
      thread()->compiler_state().GetNextDeoptId());

  // Create environment and insert 'invoke_get'.
  Environment* get_env =
      call->env()->DeepCopy(Z, call->env()->Length() - call->ArgumentCount());
  for (intptr_t i = 0, n = invoke_get->ArgumentCount(); i < n; i++) {
    get_env->PushValue(new (Z) Value(invoke_get->ArgumentAt(i)));
  }
  InsertBefore(call, invoke_get, get_env, FlowGraph::kValue);

  // Replace original call with .call(...) invocation.
  call->ReplaceWith(invoke_call, current_iterator());

  // ReplaceWith moved environment from 'call' to 'invoke_call'.
  // Update receiver argument in the environment.
  Environment* invoke_env = invoke_call->env();
  invoke_env
      ->ValueAt(invoke_env->Length() - invoke_call->ArgumentCount() +
                receiver_idx)
      ->BindToEnvironment(invoke_get);

  // AOT compiler expects all calls to have an ICData.
  EnsureICData(Z, flow_graph()->function(), invoke_get);
  EnsureICData(Z, flow_graph()->function(), invoke_call);

  // Specialize newly inserted calls.
  TryCreateICData(invoke_get);
  VisitInstanceCall(invoke_get);
  TryCreateICData(invoke_call);
  VisitInstanceCall(invoke_call);

  // Success.
  return true;
}

void AotCallSpecializer::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  const intptr_t receiver_idx = call->type_args_len() > 0 ? 1 : 0;
  const intptr_t receiver_cid =
      call->ArgumentValueAt(receiver_idx)->Type()->ToCid();
  if (receiver_cid != kDynamicCid) {
    const Class& receiver_class =
        Class::Handle(Z, isolate()->class_table()->At(receiver_cid));
    const Function& function =
        Function::ZoneHandle(Z, call->ResolveForReceiverClass(receiver_class));
    if (!function.IsNull()) {
      // Only one target. Replace by static call.
      StaticCallInstr* new_call =
          StaticCallInstr::FromCall(Z, call, function, call->CallCount());
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

  HierarchyInfo* hi = thread()->hierarchy_info();
  if (hi == NULL) {
    return false;
  }

  intptr_t lower_limit, upper_limit;
  if (!hi->InstanceOfHasClassRange(type, &lower_limit, &upper_limit)) {
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
        StrictCompareInstr(call->source(), Token::kEQ_STRICT,
                           new (Z) Value(left_cid), new (Z) Value(lower_cid),
                           /* number_check = */ false, DeoptId::kNone);
    ReplaceCall(call, check_cid);
    return true;
  }

  ConstantInstr* upper_cid =
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(upper_limit)));

  InputsArray* args = new (Z) InputsArray(Z, 3);
  args->Add(new (Z) Value(left_cid));
  args->Add(new (Z) Value(lower_cid));
  args->Add(new (Z) Value(upper_cid));

  const Library& dart_internal = Library::Handle(Z, Library::InternalLibrary());
  const String& target_name = Symbols::_classRangeCheck();
  const Function& target = Function::ZoneHandle(
      Z, dart_internal.LookupFunctionAllowPrivate(target_name));
  ASSERT(!target.IsNull());
  ASSERT(target.IsRecognized());
  ASSERT(FlowGraphInliner::FunctionHasPreferInlinePragma(target));

  const intptr_t kTypeArgsLen = 0;
  StaticCallInstr* new_call = new (Z) StaticCallInstr(
      call->source(), target, kTypeArgsLen,
      Object::null_array(),  // argument_names
      args, call->deopt_id(), call->CallCount(), ICData::kOptimized);
  Environment* copy =
      call->env()->DeepCopy(Z, call->env()->Length() - call->ArgumentCount());
  for (intptr_t i = 0; i < args->length(); ++i) {
    copy->PushValue(new (Z) Value(new_call->ArgumentAt(i)));
  }
  call->RemoveEnvironment();
  ReplaceCall(call, new_call);
  copy->DeepCopyTo(Z, new_call);
  return true;
}

void AotCallSpecializer::ReplaceInstanceCallsWithDispatchTableCalls() {
  ASSERT(current_iterator_ == nullptr);
  for (BlockIterator block_it = flow_graph()->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (auto call = instr->AsInstanceCall()) {
        TryReplaceWithDispatchTableCall(call);
      } else if (auto call = instr->AsPolymorphicInstanceCall()) {
        TryReplaceWithDispatchTableCall(call);
      }
    }
    current_iterator_ = nullptr;
  }
}

const Function& AotCallSpecializer::InterfaceTargetForTableDispatch(
    InstanceCallBaseInstr* call) {
  const Function& interface_target = call->interface_target();
  if (!interface_target.IsNull()) {
    return interface_target;
  }

  // Dynamic call or tearoff.
  const Function& tearoff_interface_target = call->tearoff_interface_target();
  if (!tearoff_interface_target.IsNull()) {
    // Tearoff.
    return Function::ZoneHandle(
        Z, tearoff_interface_target.GetMethodExtractor(call->function_name()));
  }

  // Dynamic call.
  return Function::null_function();
}

void AotCallSpecializer::TryReplaceWithDispatchTableCall(
    InstanceCallBaseInstr* call) {
  const Function& interface_target = InterfaceTargetForTableDispatch(call);
  if (interface_target.IsNull()) {
    // Dynamic call.
    return;
  }

  Value* receiver = call->ArgumentValueAt(call->FirstArgIndex());
  const compiler::TableSelector* selector =
      precompiler_->selector_map()->GetSelector(interface_target);

  if (selector == nullptr) {
    // Target functions were removed by tree shaking. This call is dead code,
    // or the receiver is always null.
#if defined(DEBUG)
    AddCheckNull(receiver->CopyWithType(Z), call->function_name(),
                 DeoptId::kNone, call->env(), call);
    StopInstr* stop = new (Z) StopInstr("Dead instance call executed.");
    InsertBefore(call, stop, call->env(), FlowGraph::kEffect);
#endif
    return;
  }

  const bool receiver_can_be_smi =
      call->CanReceiverBeSmiBasedOnInterfaceTarget(zone());
  auto load_cid = new (Z) LoadClassIdInstr(receiver->CopyWithType(Z), kUntagged,
                                           receiver_can_be_smi);
  InsertBefore(call, load_cid, call->env(), FlowGraph::kValue);

  auto dispatch_table_call = DispatchTableCallInstr::FromCall(
      Z, call, new (Z) Value(load_cid), interface_target, selector);
  call->ReplaceWith(dispatch_table_call, current_iterator());
}

#endif  // DART_PRECOMPILER

}  // namespace dart
