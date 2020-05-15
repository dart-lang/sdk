// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_scope_builder.h"

#include "vm/compiler/frontend/bytecode_reader.h"

namespace dart {
namespace kernel {

#define Z (zone_)

BytecodeScopeBuilder::BytecodeScopeBuilder(ParsedFunction* parsed_function)
    : parsed_function_(parsed_function),
      zone_(parsed_function->zone()),
      scope_(nullptr) {}

void BytecodeScopeBuilder::BuildScopes() {
  if (parsed_function_->scope() != nullptr) {
    return;  // Scopes are already built.
  }

  const Function& function = parsed_function_->function();

  LocalScope* enclosing_scope = nullptr;
  if (function.IsImplicitClosureFunction() && !function.is_static()) {
    // Create artificial enclosing scope for the tear-off that contains
    // captured receiver value. This ensure that AssertAssignable will correctly
    // load instantiator type arguments if they are needed.
    LocalVariable* receiver_variable =
        MakeReceiverVariable(/* is_parameter = */ false);
    receiver_variable->set_is_captured();
    enclosing_scope = new (Z) LocalScope(NULL, 0, 0);
    enclosing_scope->set_context_level(0);
    enclosing_scope->AddVariable(receiver_variable);
    enclosing_scope->AddContextVariable(receiver_variable);
  }
  scope_ = new (Z) LocalScope(enclosing_scope, 0, 0);
  scope_->set_begin_token_pos(function.token_pos());
  scope_->set_end_token_pos(function.end_token_pos());

  // Add function type arguments variable before current context variable.
  if ((function.IsGeneric() || function.HasGenericParent())) {
    LocalVariable* type_args_var = MakeVariable(
        Symbols::FunctionTypeArgumentsVar(), AbstractType::dynamic_type());
    scope_->AddVariable(type_args_var);
    parsed_function_->set_function_type_arguments(type_args_var);
  }

  bool needs_expr_temp = false;
  if (parsed_function_->has_arg_desc_var()) {
    needs_expr_temp = true;
    scope_->AddVariable(parsed_function_->arg_desc_var());
  }

  LocalVariable* context_var = parsed_function_->current_context_var();
  context_var->set_is_forced_stack();
  scope_->AddVariable(context_var);

  parsed_function_->set_scope(scope_);

  switch (function.kind()) {
    case FunctionLayout::kImplicitClosureFunction: {
      ASSERT(function.NumImplicitParameters() == 1);

      LocalVariable* closure_parameter = MakeVariable(
          Symbols::ClosureParameter(), AbstractType::dynamic_type());
      closure_parameter->set_is_forced_stack();
      scope_->InsertParameterAt(0, closure_parameter);

      // Type check all parameters by default.
      // This may be overridden with parameter flags in
      // BytecodeReaderHelper::ParseForwarderFunction.
      AddParameters(function, LocalVariable::kDoTypeCheck);
      break;
    }

    case FunctionLayout::kImplicitGetter:
    case FunctionLayout::kImplicitSetter: {
      const bool is_setter = function.IsImplicitSetterFunction();
      const bool is_method = !function.IsStaticFunction();
      const Field& field = Field::Handle(Z, function.accessor_field());
      intptr_t pos = 0;
      if (is_method) {
        MakeReceiverVariable(/* is_parameter = */ true);
        ++pos;
      }
      if (is_setter) {
        LocalVariable* setter_value = MakeVariable(
            Symbols::Value(),
            AbstractType::ZoneHandle(Z, function.ParameterTypeAt(pos)));
        scope_->InsertParameterAt(pos++, setter_value);

        if (is_method) {
          if (field.is_covariant()) {
            setter_value->set_is_explicit_covariant_parameter();
          } else {
            const bool needs_type_check =
                field.is_generic_covariant_impl() &&
                kernel::ProcedureAttributesOf(field, Z).has_non_this_uses;
            if (!needs_type_check) {
              setter_value->set_type_check_mode(
                  LocalVariable::kTypeCheckedByCaller);
            }
          }
        }
      }
      break;
    }
    case FunctionLayout::kImplicitStaticGetter: {
      ASSERT(!IsStaticFieldGetterGeneratedAsInitializer(function, Z));
      break;
    }
    case FunctionLayout::kDynamicInvocationForwarder: {
      // Create [this] variable.
      MakeReceiverVariable(/* is_parameter = */ true);

      // Type check all parameters by default.
      // This may be overridden with parameter flags in
      // BytecodeReaderHelper::ParseForwarderFunction.
      AddParameters(function, LocalVariable::kDoTypeCheck);
      break;
    }
    case FunctionLayout::kMethodExtractor: {
      // Add a receiver parameter.  Though it is captured, we emit code to
      // explicitly copy it to a fixed offset in a freshly-allocated context
      // instead of using the generic code for regular functions.
      // Therefore, it isn't necessary to mark it as captured here.
      MakeReceiverVariable(/* is_parameter = */ true);
      break;
    }
    default:
      UNREACHABLE();
  }

  if (needs_expr_temp) {
    scope_->AddVariable(parsed_function_->EnsureExpressionTemp());
  }
  if (parsed_function_->function().MayHaveUncheckedEntryPoint()) {
    scope_->AddVariable(parsed_function_->EnsureEntryPointsTemp());
  }
  parsed_function_->AllocateVariables();
}

// TODO(alexmarkov): pass bitvectors of parameter covariance to set type
// check mode before AllocateVariables.
void BytecodeScopeBuilder::AddParameters(const Function& function,
                                         LocalVariable::TypeCheckMode mode) {
  for (intptr_t i = function.NumImplicitParameters(),
                n = function.NumParameters();
       i < n; ++i) {
    // LocalVariable caches handles, so new handles are created for each
    // parameter.
    String& name = String::ZoneHandle(Z, function.ParameterNameAt(i));
    AbstractType& type =
        AbstractType::ZoneHandle(Z, function.ParameterTypeAt(i));

    LocalVariable* variable = MakeVariable(name, type);
    variable->set_type_check_mode(mode);
    scope_->InsertParameterAt(i, variable);
  }
}

LocalVariable* BytecodeScopeBuilder::MakeVariable(const String& name,
                                                  const AbstractType& type) {
  return new (Z) LocalVariable(TokenPosition::kNoSource,
                               TokenPosition::kNoSource, name, type, nullptr);
}

LocalVariable* BytecodeScopeBuilder::MakeReceiverVariable(bool is_parameter) {
  const auto& cls = Class::Handle(Z, parsed_function_->function().Owner());
  const auto& type = Type::ZoneHandle(Z, cls.DeclarationType());
  LocalVariable* receiver_variable = MakeVariable(Symbols::This(), type);
  parsed_function_->set_receiver_var(receiver_variable);
  if (is_parameter) {
    scope_->InsertParameterAt(0, receiver_variable);
  }
  return receiver_variable;
}

}  // namespace kernel
}  // namespace dart
