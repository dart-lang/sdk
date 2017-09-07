// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef DART_PRECOMPILED_RUNTIME
#include "vm/compiler/jit/jit_call_specializer.h"

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
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

// Quick access to the current isolate and zone.
#define I (isolate())
#define Z (zone())

static bool ShouldCloneFields() {
  return Compiler::IsBackgroundCompilation() ||
         FLAG_force_clone_compiler_objects;
}

JitCallSpecializer::JitCallSpecializer(FlowGraph* flow_graph)
    : CallSpecializer(flow_graph, ShouldCloneFields()) {}

bool JitCallSpecializer::IsAllowedForInlining(intptr_t deopt_id) const {
  return true;
}

// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
// TODO(dartbug.com/30635) Evaluate how much this can be shared with
// AotCallSpecializer.
void JitCallSpecializer::VisitInstanceCall(InstanceCallInstr* instr) {
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

  if ((op_kind == Token::kASSIGN_INDEX) &&
      TryReplaceWithIndexedOp(instr, &unary_checks)) {
    return;
  }
  if ((op_kind == Token::kINDEX) &&
      TryReplaceWithIndexedOp(instr, &unary_checks)) {
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

void JitCallSpecializer::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {
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

void JitCallSpecializer::VisitAllocateContext(AllocateContextInstr* instr) {
  // Replace generic allocation with a sequence of inlined allocation and
  // explicit initializing stores.
  AllocateUninitializedContextInstr* replacement =
      new AllocateUninitializedContextInstr(instr->token_pos(),
                                            instr->num_context_variables());
  instr->ReplaceWith(replacement, current_iterator());

  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(Context::parent_offset(), new Value(replacement),
                              new Value(flow_graph()->constant_null()),
                              kNoStoreBarrier, instr->token_pos());
  // Storing into uninitialized memory; remember to prevent dead store
  // elimination and ensure proper GC barrier.
  store->set_is_initialization(true);
  flow_graph()->InsertAfter(replacement, store, NULL, FlowGraph::kEffect);
  Definition* cursor = store;
  for (intptr_t i = 0; i < instr->num_context_variables(); ++i) {
    store = new (Z) StoreInstanceFieldInstr(
        Context::variable_offset(i), new Value(replacement),
        new Value(flow_graph()->constant_null()), kNoStoreBarrier,
        instr->token_pos());
    // Storing into uninitialized memory; remember to prevent dead store
    // elimination and ensure proper GC barrier.
    store->set_is_initialization(true);
    flow_graph()->InsertAfter(cursor, store, NULL, FlowGraph::kEffect);
    cursor = store;
  }
}

}  // namespace dart
#endif  // DART_PRECOMPILED_RUNTIME
