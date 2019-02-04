// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/scope_builder.h"

#include "vm/compiler/backend/il.h"  // For CompileType.
#include "vm/kernel.h"               // For IsFieldInitializer.

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

// Returns true if the given method can skip type checks for all arguments
// that are not covariant or generic covariant in its implementation.
bool MethodCanSkipTypeChecksForNonCovariantArguments(
    const Function& method,
    const ProcedureAttributesMetadata& attrs) {
  // Dart 2 type system at non-dynamic call sites statically guarantees that
  // argument values match declarated parameter types for all non-covariant
  // and non-generic-covariant parameters. The same applies to type parameters
  // bounds for type parameters of generic functions.
  //
  // In JIT mode we dynamically generate trampolines (dynamic invocation
  // forwarders) that perform type checks when arriving to a method from a
  // dynamic call-site.
  //
  // In AOT mode we don't dynamically generate such trampolines but instead rely
  // on a static analysis to discover which methods can be invoked dynamically,
  // and generate the necessary trampolines during precompilation.
  if (method.name() == Symbols::Call().raw()) {
    // Currently we consider all call methods to be invoked dynamically and
    // don't mangle their names.
    // TODO(vegorov) remove this once we also introduce special type checking
    // entry point for closures.
    return false;
  }
  return true;
}

ScopeBuilder::ScopeBuilder(ParsedFunction* parsed_function)
    : result_(NULL),
      parsed_function_(parsed_function),
      translation_helper_(Thread::Current()),
      zone_(translation_helper_.zone()),
      current_function_scope_(NULL),
      scope_(NULL),
      depth_(0),
      name_index_(0),
      needs_expr_temp_(false),
      helper_(
          zone_,
          &translation_helper_,
          Script::Handle(Z, parsed_function->function().script()),
          ExternalTypedData::Handle(Z,
                                    parsed_function->function().KernelData()),
          parsed_function->function().KernelDataProgramOffset()),
      inferred_type_metadata_helper_(&helper_),
      procedure_attributes_metadata_helper_(&helper_),
      type_translator_(&helper_,
                       &active_class_,
                       /*finalize=*/true) {
  H.InitFromScript(helper_.script());
  ASSERT(type_translator_.active_class_ == &active_class_);
}

ScopeBuildingResult* ScopeBuilder::BuildScopes() {
  if (result_ != NULL) return result_;

  ASSERT(scope_ == NULL && depth_.loop_ == 0 && depth_.function_ == 0);
  result_ = new (Z) ScopeBuildingResult();

  const Function& function = parsed_function_->function();

  // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass = Class::Handle(zone_, function.Owner());

  Function& outermost_function =
      Function::Handle(Z, function.GetOutermostFunction());

  ActiveClassScope active_class_scope(&active_class_, &klass);
  ActiveMemberScope active_member(&active_class_, &outermost_function);
  ActiveTypeParametersScope active_type_params(&active_class_, function, Z);

  LocalScope* enclosing_scope = NULL;
  if (function.IsImplicitClosureFunction() && !function.is_static()) {
    // Create artificial enclosing scope for the tear-off that contains
    // captured receiver value. This ensure that AssertAssignable will correctly
    // load instantiator type arguments if they are needed.
    Class& klass = Class::Handle(Z, function.Owner());
    Type& klass_type = H.GetDeclarationType(klass);
    result_->this_variable =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::This(), klass_type);
    result_->this_variable->set_is_captured();
    enclosing_scope = new (Z) LocalScope(NULL, 0, 0);
    enclosing_scope->set_context_level(0);
    enclosing_scope->AddVariable(result_->this_variable);
    enclosing_scope->AddContextVariable(result_->this_variable);
  } else if (function.IsLocalFunction()) {
    enclosing_scope = LocalScope::RestoreOuterScope(
        ContextScope::Handle(Z, function.context_scope()));
  }
  current_function_scope_ = scope_ = new (Z) LocalScope(enclosing_scope, 0, 0);
  scope_->set_begin_token_pos(function.token_pos());
  scope_->set_end_token_pos(function.end_token_pos());

  // Add function type arguments variable before current context variable.
  if ((function.IsGeneric() || function.HasGenericParent())) {
    LocalVariable* type_args_var = MakeVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::FunctionTypeArgumentsVar(), AbstractType::dynamic_type());
    scope_->AddVariable(type_args_var);
    parsed_function_->set_function_type_arguments(type_args_var);
  }

  if (parsed_function_->has_arg_desc_var()) {
    needs_expr_temp_ = true;
    scope_->AddVariable(parsed_function_->arg_desc_var());
  }

  LocalVariable* context_var = parsed_function_->current_context_var();
  context_var->set_is_forced_stack();
  scope_->AddVariable(context_var);

  parsed_function_->SetNodeSequence(
      new SequenceNode(TokenPosition::kNoSource, scope_));

  helper_.SetOffset(function.kernel_offset());

  FunctionNodeHelper function_node_helper(&helper_);
  const ProcedureAttributesMetadata attrs =
      procedure_attributes_metadata_helper_.GetProcedureAttributes(
          function.kernel_offset());

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kImplicitClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor: {
      const Tag tag = helper_.PeekTag();
      helper_.ReadUntilFunctionNode();
      function_node_helper.ReadUntilExcluding(
          FunctionNodeHelper::kPositionalParameters);
      current_function_async_marker_ = function_node_helper.async_marker_;
      // NOTE: FunctionNode is read further below the if.

      intptr_t pos = 0;
      if (function.IsClosureFunction()) {
        LocalVariable* closure_parameter = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::ClosureParameter(), AbstractType::dynamic_type());
        closure_parameter->set_is_forced_stack();
        scope_->InsertParameterAt(pos++, closure_parameter);
      } else if (!function.is_static()) {
        // We use [is_static] instead of [IsStaticFunction] because the latter
        // returns `false` for constructors.
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetDeclarationType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;

        // We visit instance field initializers because they might contain
        // [Let] expressions and we need to have a mapping.
        if (tag == kConstructor) {
          Class& parent_class = Class::Handle(Z, function.Owner());
          Array& class_fields = Array::Handle(Z, parent_class.fields());
          Field& class_field = Field::Handle(Z);
          for (intptr_t i = 0; i < class_fields.Length(); ++i) {
            class_field ^= class_fields.At(i);
            if (!class_field.is_static()) {
              ExternalTypedData& kernel_data =
                  ExternalTypedData::Handle(Z, class_field.KernelData());
              ASSERT(!kernel_data.IsNull());
              intptr_t field_offset = class_field.kernel_offset();
              AlternativeReadingScope alt(&helper_.reader_, &kernel_data,
                                          field_offset);
              FieldHelper field_helper(&helper_);
              field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
              Tag initializer_tag =
                  helper_.ReadTag();  // read first part of initializer.
              if (initializer_tag == kSomething) {
                EnterScope(field_offset);
                VisitExpression();  // read initializer.
                ExitScope(field_helper.position_, field_helper.end_position_);
              }
            }
          }
        }
      } else if (function.IsFactory()) {
        LocalVariable* variable = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::TypeArgumentsParameter(), AbstractType::dynamic_type());
        scope_->InsertParameterAt(pos++, variable);
        result_->type_arguments_variable = variable;
      }

      ParameterTypeCheckMode type_check_mode = kTypeCheckAllParameters;
      if (function.IsNonImplicitClosureFunction()) {
        type_check_mode = kTypeCheckAllParameters;
      } else if (function.IsImplicitClosureFunction()) {
        if (MethodCanSkipTypeChecksForNonCovariantArguments(
                Function::Handle(Z, function.parent_function()), attrs)) {
          // This is a tear-off of an instance method that can not be reached
          // from any dynamic invocation. The method would not check any
          // parameters except covariant ones and those annotated with
          // generic-covariant-impl. Which means that we have to check
          // the rest in the tear-off itself.
          type_check_mode =
              kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod;
        }
      } else {
        if (function.is_static()) {
          // In static functions we don't check anything.
          type_check_mode = kTypeCheckForStaticFunction;
        } else if (MethodCanSkipTypeChecksForNonCovariantArguments(function,
                                                                   attrs)) {
          // If the current function is never a target of a dynamic invocation
          // and this parameter is not marked with generic-covariant-impl
          // (which means that among all super-interfaces no type parameters
          // ever occur at the position of this parameter) then we don't need
          // to check this parameter on the callee side, because strong mode
          // guarantees that it was checked at the caller side.
          type_check_mode = kTypeCheckForNonDynamicallyInvokedMethod;
        }
      }

      // Continue reading FunctionNode:
      // read positional_parameters and named_parameters.
      AddPositionalAndNamedParameters(pos, type_check_mode, attrs);

      // We generate a synthetic body for implicit closure functions - which
      // will forward the call to the real function.
      //     -> see BuildGraphOfImplicitClosureFunction
      if (!function.IsImplicitClosureFunction()) {
        helper_.SetOffset(function.kernel_offset());
        first_body_token_position_ = TokenPosition::kNoSource;
        VisitNode();

        // TODO(jensj): HACK: Push the begin token to after any parameters to
        // avoid crash when breaking on definition line of async method in
        // debugger. It seems that another scope needs to be added
        // in which captures are made, but I can't make that work.
        // This 'solution' doesn't crash, but I cannot see the parameters at
        // that particular breakpoint either.
        // Also push the end token to after the "}" to avoid crashing on
        // stepping past the last line (to the "}" character).
        if (first_body_token_position_.IsReal()) {
          scope_->set_begin_token_pos(first_body_token_position_);
        }
        if (scope_->end_token_pos().IsReal()) {
          scope_->set_end_token_pos(scope_->end_token_pos().Next());
        }
      }
      break;
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      ASSERT(helper_.PeekTag() == kField);
      if (IsFieldInitializer(function, Z)) {
        VisitNode();
        break;
      }
      const bool is_setter = function.IsImplicitSetterFunction();
      const bool is_method = !function.IsStaticFunction();
      intptr_t pos = 0;
      if (is_method) {
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetDeclarationType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;
      }
      if (is_setter) {
        result_->setter_value = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::Value(),
            AbstractType::ZoneHandle(Z, function.ParameterTypeAt(pos)));
        scope_->InsertParameterAt(pos++, result_->setter_value);

        if (is_method &&
            MethodCanSkipTypeChecksForNonCovariantArguments(function, attrs)) {
          FieldHelper field_helper(&helper_);
          field_helper.ReadUntilIncluding(FieldHelper::kFlags);

          if (field_helper.IsCovariant()) {
            result_->setter_value->set_is_explicit_covariant_parameter();
          } else if (!field_helper.IsGenericCovariantImpl() ||
                     (!attrs.has_non_this_uses && !attrs.has_tearoff_uses)) {
            result_->setter_value->set_type_check_mode(
                LocalVariable::kTypeCheckedByCaller);
          }
        }
      }
      break;
    }
    case RawFunction::kDynamicInvocationForwarder: {
      if (helper_.PeekTag() == kField) {
#ifdef DEBUG
        String& name = String::Handle(Z, function.name());
        ASSERT(Function::IsDynamicInvocationForwaderName(name));
        name = Function::DemangleDynamicInvocationForwarderName(name);
        ASSERT(Field::IsSetterName(name));
#endif
        // Create [this] variable.
        const Class& klass = Class::Handle(Z, function.Owner());
        result_->this_variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), H.GetDeclarationType(klass));
        scope_->InsertParameterAt(0, result_->this_variable);

        // Create setter value variable.
        result_->setter_value = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::Value(),
            AbstractType::ZoneHandle(Z, function.ParameterTypeAt(1)));
        scope_->InsertParameterAt(1, result_->setter_value);
      } else {
        helper_.ReadUntilFunctionNode();
        function_node_helper.ReadUntilExcluding(
            FunctionNodeHelper::kPositionalParameters);

        // Create [this] variable.
        intptr_t pos = 0;
        Class& klass = Class::Handle(Z, function.Owner());
        result_->this_variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), H.GetDeclarationType(klass));
        scope_->InsertParameterAt(pos++, result_->this_variable);

        // Create all positional and named parameters.
        AddPositionalAndNamedParameters(
            pos, kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod,
            attrs);
      }
      break;
    }
    case RawFunction::kMethodExtractor: {
      // Add a receiver parameter.  Though it is captured, we emit code to
      // explicitly copy it to a fixed offset in a freshly-allocated context
      // instead of using the generic code for regular functions.
      // Therefore, it isn't necessary to mark it as captured here.
      Class& klass = Class::Handle(Z, function.Owner());
      Type& klass_type = H.GetDeclarationType(klass);
      LocalVariable* variable =
          MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                       Symbols::This(), klass_type);
      scope_->InsertParameterAt(0, variable);
      result_->this_variable = variable;
      break;
    }
    case RawFunction::kNoSuchMethodDispatcher:
    case RawFunction::kInvokeFieldDispatcher:
      for (intptr_t i = 0; i < function.NumParameters(); ++i) {
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         String::ZoneHandle(Z, function.ParameterNameAt(i)),
                         AbstractType::dynamic_type());
        scope_->InsertParameterAt(i, variable);
      }
      break;
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      UNREACHABLE();
  }
  if (needs_expr_temp_) {
    scope_->AddVariable(parsed_function_->EnsureExpressionTemp());
  }
  if (parsed_function_->function().MayHaveUncheckedEntryPoint(I)) {
    scope_->AddVariable(parsed_function_->EnsureEntryPointsTemp());
  }
  parsed_function_->AllocateVariables();

  return result_;
}

void ScopeBuilder::ReportUnexpectedTag(const char* variant, Tag tag) {
  H.ReportError(helper_.script(), TokenPosition::kNoSource,
                "Unexpected tag %d (%s) in %s, expected %s", tag,
                Reader::TagName(tag),
                parsed_function_->function().ToQualifiedCString(), variant);
}

void ScopeBuilder::VisitNode() {
  Tag tag = helper_.PeekTag();
  switch (tag) {
    case kConstructor:
      VisitConstructor();
      return;
    case kProcedure:
      VisitProcedure();
      return;
    case kField:
      VisitField();
      return;
    case kFunctionNode:
      VisitFunctionNode();
      return;
    default:
      UNIMPLEMENTED();
      return;
  }
}

void ScopeBuilder::VisitConstructor() {
  // Field initializers that come from non-static field declarations are
  // compiled as if they appear in the constructor initializer list.  This is
  // important for closure-valued field initializers because the VM expects the
  // corresponding closure functions to appear as if they were nested inside the
  // constructor.
  ConstructorHelper constructor_helper(&helper_);
  constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);
  {
    const Function& function = parsed_function_->function();
    Class& parent_class = Class::Handle(Z, function.Owner());
    Array& class_fields = Array::Handle(Z, parent_class.fields());
    Field& class_field = Field::Handle(Z);
    for (intptr_t i = 0; i < class_fields.Length(); ++i) {
      class_field ^= class_fields.At(i);
      if (!class_field.is_static()) {
        ExternalTypedData& kernel_data =
            ExternalTypedData::Handle(Z, class_field.KernelData());
        ASSERT(!kernel_data.IsNull());
        intptr_t field_offset = class_field.kernel_offset();
        AlternativeReadingScope alt(&helper_.reader_, &kernel_data,
                                    field_offset);
        FieldHelper field_helper(&helper_);
        field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
        Tag initializer_tag = helper_.ReadTag();
        if (initializer_tag == kSomething) {
          VisitExpression();  // read initializer.
        }
      }
    }
  }

  // Visit children (note that there's no reason to visit the name).
  VisitFunctionNode();
  intptr_t list_length =
      helper_.ReadListLength();  // read initializers list length.
  for (intptr_t i = 0; i < list_length; i++) {
    VisitInitializer();
  }
}

void ScopeBuilder::VisitProcedure() {
  ProcedureHelper procedure_helper(&helper_);
  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
  if (helper_.ReadTag() == kSomething) {
    VisitFunctionNode();
  }
}

void ScopeBuilder::VisitField() {
  FieldHelper field_helper(&helper_);
  field_helper.ReadUntilExcluding(FieldHelper::kType);
  VisitDartType();              // read type.
  Tag tag = helper_.ReadTag();  // read initializer (part 1).
  if (tag == kSomething) {
    VisitExpression();  // read initializer (part 2).
  }
}

void ScopeBuilder::VisitFunctionNode() {
  FunctionNodeHelper function_node_helper(&helper_);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);

  intptr_t list_length =
      helper_.ReadListLength();  // read type_parameters list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    TypeParameterHelper helper(&helper_);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);
    VisitDartType();  // read ith bound.
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kDefaultType);
    if (helper_.ReadTag() == kSomething) {
      VisitDartType();  // read ith default type.
    }
    helper.Finish();
  }
  function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);

  if (FLAG_causal_async_stacks &&
      (function_node_helper.dart_async_marker_ == FunctionNodeHelper::kAsync ||
       function_node_helper.dart_async_marker_ ==
           FunctionNodeHelper::kAsyncStar)) {
    LocalVariable* asyncStackTraceVar = MakeVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::AsyncStackTraceVar(), AbstractType::dynamic_type());
    scope_->AddVariable(asyncStackTraceVar);
  }

  if (function_node_helper.async_marker_ == FunctionNodeHelper::kSyncYielding) {
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    intptr_t offset = parsed_function_->function().num_fixed_parameters();
    for (intptr_t i = 0;
         i < parsed_function_->function().NumOptionalPositionalParameters();
         i++) {
      scope->VariableAt(offset + i)->set_is_forced_stack();
    }
  }

  // Read (but don't visit) the positional and named parameters, because they've
  // already been added to the scope.
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kBody);

  if (helper_.ReadTag() == kSomething) {
    PositionScope scope(&helper_.reader_);
    VisitStatement();  // Read body
    first_body_token_position_ = helper_.reader_.min_position();
  }

  // Ensure that :await_jump_var, :await_ctx_var, :async_op,
  // :async_completer and :async_stack_trace are captured.
  if (function_node_helper.async_marker_ == FunctionNodeHelper::kSyncYielding) {
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_jump_variable : &temp,
          Symbols::AwaitJumpVar());
    }
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_context_variable : &temp,
          Symbols::AwaitContextVar());
    }
    {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::AsyncOperation(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
    {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::AsyncCompleter(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
    {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::ControllerStream(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
    if (FLAG_causal_async_stacks) {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::AsyncStackTraceVar(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
  }
}

void ScopeBuilder::VisitInitializer() {
  Tag tag = helper_.ReadTag();
  helper_.ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      helper_.SkipCanonicalNameReference();  // read field_reference.
      VisitExpression();                     // read value.
      return;
    case kSuperInitializer:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                      // read arguments.
      return;
    case kRedirectingInitializer:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                      // read arguments.
      return;
    case kLocalInitializer:
      VisitVariableDeclaration();  // read variable.
      return;
    case kAssertInitializer:
      VisitStatement();
      return;
    default:
      ReportUnexpectedTag("initializer", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitExpression() {
  uint8_t payload = 0;
  Tag tag = helper_.ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      helper_.ReadPosition();
      helper_.SkipStringReference();
      return;
    case kVariableGet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();          // read kernel position.
      helper_.ReadUInt();              // read relative variable index.
      helper_.SkipOptionalDartType();  // read promoted type.
      LookupVariable(variable_kernel_offset);
      return;
    }
    case kSpecializedVariableGet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();  // read kernel position.
      LookupVariable(variable_kernel_offset);
      return;
    }
    case kVariableSet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();  // read kernel position.
      helper_.ReadUInt();      // read relative variable index.
      LookupVariable(variable_kernel_offset);
      VisitExpression();  // read expression.
      return;
    }
    case kSpecializedVariableSet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();  // read kernel position.
      LookupVariable(variable_kernel_offset);
      VisitExpression();  // read expression.
      return;
    }
    case kPropertyGet:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      // read interface_target_reference.
      helper_.SkipCanonicalNameReference();
      return;
    case kPropertySet:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitExpression();       // read value.
      // read interface_target_reference.
      helper_.SkipCanonicalNameReference();
      return;
    case kDirectPropertyGet:
      helper_.ReadPosition();                // read position.
      VisitExpression();                     // read receiver.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      return;
    case kDirectPropertySet:
      helper_.ReadPosition();                // read position.
      VisitExpression();                     // read receiver.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitExpression();                     // read value·
      return;
    case kSuperPropertyGet:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      helper_.ReadPosition();                // read position.
      helper_.SkipName();                    // read name.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      return;
    case kSuperPropertySet:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      helper_.ReadPosition();                // read position.
      helper_.SkipName();                    // read name.
      VisitExpression();                     // read value.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticGet:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticSet:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitExpression();                     // read expression.
      return;
    case kMethodInvocation:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitArguments();        // read arguments.
      // read interface_target_reference.
      helper_.SkipCanonicalNameReference();
      return;
    case kDirectMethodInvocation:
      helper_.ReadPosition();                // read position.
      VisitExpression();                     // read receiver.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                      // read arguments.
      return;
    case kSuperMethodInvocation:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      helper_.ReadPosition();  // read position.
      helper_.SkipName();      // read name.
      VisitArguments();        // read arguments.
      // read interface_target_reference.
      helper_.SkipCanonicalNameReference();
      return;
    case kStaticInvocation:
    case kConstStaticInvocation:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read procedure_reference.
      VisitArguments();                      // read arguments.
      return;
    case kConstructorInvocation:
    case kConstConstructorInvocation:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                      // read arguments.
      return;
    case kNot:
      VisitExpression();  // read expression.
      return;
    case kLogicalExpression:
      needs_expr_temp_ = true;
      VisitExpression();     // read left.
      helper_.SkipBytes(1);  // read operator.
      VisitExpression();     // read right.
      return;
    case kConditionalExpression: {
      needs_expr_temp_ = true;
      VisitExpression();               // read condition.
      VisitExpression();               // read then.
      VisitExpression();               // read otherwise.
      helper_.SkipOptionalDartType();  // read unused static type.
      return;
    }
    case kStringConcatenation: {
      helper_.ReadPosition();                           // read position.
      intptr_t list_length = helper_.ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith expression.
      }
      return;
    }
    case kIsExpression:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read operand.
      VisitDartType();         // read type.
      return;
    case kAsExpression:
      helper_.ReadPosition();  // read position.
      helper_.ReadFlags();     // read flags.
      VisitExpression();       // read operand.
      VisitDartType();         // read type.
      return;
    case kSymbolLiteral:
      helper_.SkipStringReference();  // read index into string table.
      return;
    case kTypeLiteral:
      VisitDartType();  // read type.
      return;
    case kThisExpression:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      return;
    case kRethrow:
      helper_.ReadPosition();  // read position.
      return;
    case kThrow:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kListLiteral:
    case kConstListLiteral: {
      helper_.ReadPosition();                           // read position.
      VisitDartType();                                  // read type.
      intptr_t list_length = helper_.ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith expression.
      }
      return;
    }
    case kSetLiteral:
    case kConstSetLiteral: {
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      return;
    }
    case kMapLiteral:
    case kConstMapLiteral: {
      helper_.ReadPosition();                           // read position.
      VisitDartType();                                  // read key type.
      VisitDartType();                                  // read value type.
      intptr_t list_length = helper_.ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith key.
        VisitExpression();  // read ith value.
      }
      return;
    }
    case kFunctionExpression: {
      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.
      helper_.ReadPosition();                        // read position.
      HandleLocalFunction(offset);                   // read function node.
      return;
    }
    case kLet: {
      PositionScope scope(&helper_.reader_);
      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.

      EnterScope(offset);

      VisitVariableDeclaration();  // read variable declaration.
      VisitExpression();           // read expression.

      ExitScope(helper_.reader_.min_position(), helper_.reader_.max_position());
      return;
    }
    case kBigIntLiteral:
      helper_.SkipStringReference();  // read string reference.
      return;
    case kStringLiteral:
      helper_.SkipStringReference();  // read string reference.
      return;
    case kSpecializedIntLiteral:
      return;
    case kNegativeIntLiteral:
      helper_.ReadUInt();  // read value.
      return;
    case kPositiveIntLiteral:
      helper_.ReadUInt();  // read value.
      return;
    case kDoubleLiteral:
      helper_.ReadDouble();  // read value.
      return;
    case kTrueLiteral:
      return;
    case kFalseLiteral:
      return;
    case kNullLiteral:
      return;
    case kConstantExpression: {
      helper_.SkipConstantReference();
      return;
    }
    case kInstantiation: {
      VisitExpression();
      const intptr_t list_length =
          helper_.ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitDartType();  // read ith type.
      }
      return;
    }
    case kLoadLibrary:
    case kCheckLibraryIsLoaded:
      helper_.ReadUInt();  // library index
      break;
    default:
      ReportUnexpectedTag("expression", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitStatement() {
  Tag tag = helper_.ReadTag();  // read tag.
  switch (tag) {
    case kExpressionStatement:
      VisitExpression();  // read expression.
      return;
    case kBlock: {
      PositionScope scope(&helper_.reader_);
      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.

      EnterScope(offset);

      intptr_t list_length =
          helper_.ReadListLength();  // read number of statements.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitStatement();  // read ith statement.
      }

      ExitScope(helper_.reader_.min_position(), helper_.reader_.max_position());
      return;
    }
    case kEmptyStatement:
      return;
    case kAssertBlock:
      if (I->asserts()) {
        PositionScope scope(&helper_.reader_);
        intptr_t offset =
            helper_.ReaderOffset() - 1;  // -1 to include tag byte.

        EnterScope(offset);

        intptr_t list_length =
            helper_.ReadListLength();  // read number of statements.
        for (intptr_t i = 0; i < list_length; ++i) {
          VisitStatement();  // read ith statement.
        }

        ExitScope(helper_.reader_.min_position(),
                  helper_.reader_.max_position());
      } else {
        helper_.SkipStatementList();
      }
      return;
    case kAssertStatement:
      if (I->asserts()) {
        VisitExpression();            // Read condition.
        helper_.ReadPosition();       // read condition start offset.
        helper_.ReadPosition();       // read condition end offset.
        Tag tag = helper_.ReadTag();  // read (first part of) message.
        if (tag == kSomething) {
          VisitExpression();  // read (rest of) message.
        }
      } else {
        helper_.SkipExpression();     // Read condition.
        helper_.ReadPosition();       // read condition start offset.
        helper_.ReadPosition();       // read condition end offset.
        Tag tag = helper_.ReadTag();  // read (first part of) message.
        if (tag == kSomething) {
          helper_.SkipExpression();  // read (rest of) message.
        }
      }
      return;
    case kLabeledStatement:
      VisitStatement();  // read body.
      return;
    case kBreakStatement:
      helper_.ReadPosition();  // read position.
      helper_.ReadUInt();      // read target_index.
      return;
    case kWhileStatement:
      ++depth_.loop_;
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read condition.
      VisitStatement();        // read body.
      --depth_.loop_;
      return;
    case kDoStatement:
      ++depth_.loop_;
      helper_.ReadPosition();  // read position.
      VisitStatement();        // read body.
      VisitExpression();       // read condition.
      --depth_.loop_;
      return;
    case kForStatement: {
      PositionScope scope(&helper_.reader_);

      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.

      ++depth_.loop_;
      EnterScope(offset);

      TokenPosition position = helper_.ReadPosition();  // read position.
      intptr_t list_length =
          helper_.ReadListLength();  // read number of variables.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitVariableDeclaration();  // read ith variable.
      }

      Tag tag = helper_.ReadTag();  // Read first part of condition.
      if (tag == kSomething) {
        VisitExpression();  // read rest of condition.
      }
      list_length = helper_.ReadListLength();  // read number of updates.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith update.
      }
      VisitStatement();  // read body.

      ExitScope(position, helper_.reader_.max_position());
      --depth_.loop_;
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement: {
      PositionScope scope(&helper_.reader_);

      intptr_t start_offset =
          helper_.ReaderOffset() - 1;  // -1 to include tag byte.

      helper_.ReadPosition();  // read position.
      TokenPosition body_position =
          helper_.ReadPosition();  // read body position.

      // Notice the ordering: We skip the variable, read the iterable, go back,
      // re-read the variable, go forward to after having read the iterable.
      intptr_t offset = helper_.ReaderOffset();
      helper_.SkipVariableDeclaration();  // read variable.
      VisitExpression();                  // read iterable.

      ++depth_.for_in_;
      AddIteratorVariable();
      ++depth_.loop_;
      EnterScope(start_offset);

      {
        AlternativeReadingScope alt(&helper_.reader_, offset);
        VisitVariableDeclaration();  // read variable.
      }
      VisitStatement();  // read body.

      if (!body_position.IsReal()) {
        body_position = helper_.reader_.min_position();
      }
      // TODO(jensj): From kernel_binary.cc
      // forinstmt->variable_->set_end_position(forinstmt->position_);
      ExitScope(body_position, helper_.reader_.max_position());
      --depth_.loop_;
      --depth_.for_in_;
      return;
    }
    case kSwitchStatement: {
      AddSwitchVariable();
      helper_.ReadPosition();                     // read position.
      VisitExpression();                          // read condition.
      int case_count = helper_.ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        int expression_count =
            helper_.ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < expression_count; ++j) {
          helper_.ReadPosition();  // read jth position.
          VisitExpression();       // read jth expression.
        }
        helper_.ReadBool();  // read is_default.
        VisitStatement();    // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      helper_.ReadPosition();  // read position.
      helper_.ReadUInt();      // read target_index.
      return;
    case kIfStatement:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read condition.
      VisitStatement();        // read then.
      VisitStatement();        // read otherwise.
      return;
    case kReturnStatement: {
      if ((depth_.function_ == 0) && (depth_.finally_ > 0) &&
          (result_->finally_return_variable == NULL)) {
        const String& name = Symbols::TryFinallyReturnValue();
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         name, AbstractType::dynamic_type());
        current_function_scope_->AddVariable(variable);
        result_->finally_return_variable = variable;
      }

      helper_.ReadPosition();       // read position
      Tag tag = helper_.ReadTag();  // read (first part of) expression.
      if (tag == kSomething) {
        VisitExpression();  // read (rest of) expression.
      }
      return;
    }
    case kTryCatch: {
      ++depth_.try_;
      AddTryVariables();
      VisitStatement();  // read body.
      --depth_.try_;

      ++depth_.catch_;
      AddCatchVariables();

      helper_.ReadByte();  // read flags
      intptr_t catch_count =
          helper_.ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < catch_count; ++i) {
        PositionScope scope(&helper_.reader_);
        intptr_t offset = helper_.ReaderOffset();  // Catch has no tag.

        EnterScope(offset);

        helper_.ReadPosition();   // read position.
        VisitDartType();          // Read the guard.
        tag = helper_.ReadTag();  // read first part of exception.
        if (tag == kSomething) {
          VisitVariableDeclaration();  // read exception.
        }
        tag = helper_.ReadTag();  // read first part of stack trace.
        if (tag == kSomething) {
          VisitVariableDeclaration();  // read stack trace.
        }
        VisitStatement();  // read body.

        ExitScope(helper_.reader_.min_position(),
                  helper_.reader_.max_position());
      }

      FinalizeCatchVariables();

      --depth_.catch_;
      return;
    }
    case kTryFinally: {
      ++depth_.try_;
      ++depth_.finally_;
      AddTryVariables();

      VisitStatement();  // read body.

      --depth_.finally_;
      --depth_.try_;
      ++depth_.catch_;
      AddCatchVariables();

      VisitStatement();  // read finalizer.

      FinalizeCatchVariables();

      --depth_.catch_;
      return;
    }
    case kYieldStatement: {
      helper_.ReadPosition();           // read position.
      word flags = helper_.ReadByte();  // read flags.
      VisitExpression();                // read expression.

      ASSERT(flags == kNativeYieldFlags);
      if (depth_.function_ == 0) {
        AddSwitchVariable();
        // Promote all currently visible local variables into the context.
        // TODO(27590) CaptureLocalVariables promotes to many variables into
        // the scope. Mark those variables as stack_local.
        // TODO(27590) we don't need to promote those variables that are
        // not used across yields.
        scope_->CaptureLocalVariables(current_function_scope_);
      }
      return;
    }
    case kVariableDeclaration:
      VisitVariableDeclaration();  // read variable declaration.
      return;
    case kFunctionDeclaration: {
      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.
      helper_.ReadPosition();                        // read position.
      VisitVariableDeclaration();   // read variable declaration.
      HandleLocalFunction(offset);  // read function node.
      return;
    }
    default:
      ReportUnexpectedTag("declaration", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitArguments() {
  helper_.ReadUInt();  // read argument_count.

  // Types
  intptr_t list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitDartType();  // read ith type.
  }

  // Positional.
  list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitExpression();  // read ith positional.
  }

  // Named.
  list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    helper_.SkipStringReference();  // read ith name index.
    VisitExpression();              // read ith expression.
  }
}

void ScopeBuilder::VisitVariableDeclaration() {
  PositionScope scope(&helper_.reader_);

  intptr_t kernel_offset_no_tag = helper_.ReaderOffset();
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  AbstractType& type = BuildAndVisitVariableType();

  // In case `declaration->IsConst()` the flow graph building will take care of
  // evaluating the constant and setting it via
  // `declaration->SetConstantValue()`.
  const String& name = (H.StringSize(helper.name_index_) == 0)
                           ? GenerateName(":var", name_index_++)
                           : H.DartSymbolObfuscate(helper.name_index_);

  Tag tag = helper_.ReadTag();  // read (first part of) initializer.
  if (tag == kSomething) {
    VisitExpression();  // read (actual) initializer.
  }

  // Go to next token position so it ends *after* the last potentially
  // debuggable position in the initializer.
  TokenPosition end_position = helper_.reader_.max_position();
  if (end_position.IsReal()) {
    end_position.Next();
  }
  LocalVariable* variable =
      MakeVariable(helper.position_, end_position, name, type);
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  scope_->AddVariable(variable);
  result_->locals.Insert(helper_.data_program_offset_ + kernel_offset_no_tag,
                         variable);
}

AbstractType& ScopeBuilder::BuildAndVisitVariableType() {
  const intptr_t offset = helper_.ReaderOffset();
  AbstractType& type = T.BuildType();
  helper_.SetOffset(offset);  // rewind
  VisitDartType();
  return type;
}

void ScopeBuilder::VisitDartType() {
  Tag tag = helper_.ReadTag();
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
    case kVoidType:
    case kBottomType:
      // those contain nothing.
      return;
    case kInterfaceType:
      VisitInterfaceType(false);
      return;
    case kSimpleInterfaceType:
      VisitInterfaceType(true);
      return;
    case kFunctionType:
      VisitFunctionType(false);
      return;
    case kSimpleFunctionType:
      VisitFunctionType(true);
      return;
    case kTypeParameterType:
      VisitTypeParameterType();
      return;
    default:
      ReportUnexpectedTag("type", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitInterfaceType(bool simple) {
  helper_.ReadUInt();  // read klass_name.
  if (!simple) {
    intptr_t length = helper_.ReadListLength();  // read number of types.
    for (intptr_t i = 0; i < length; ++i) {
      VisitDartType();  // read the ith type.
    }
  }
}

void ScopeBuilder::VisitFunctionType(bool simple) {
  if (!simple) {
    intptr_t list_length =
        helper_.ReadListLength();  // read type_parameters list length.
    for (int i = 0; i < list_length; ++i) {
      TypeParameterHelper helper(&helper_);
      helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);
      VisitDartType();  // read bound.
      helper.ReadUntilExcludingAndSetJustRead(
          TypeParameterHelper::kDefaultType);
      if (helper_.ReadTag() == kSomething) {
        VisitDartType();  // read default type.
      }
      helper.Finish();
    }
    helper_.ReadUInt();  // read required parameter count.
    helper_.ReadUInt();  // read total parameter count.
  }

  const intptr_t positional_count =
      helper_.ReadListLength();  // read positional_parameters list length.
  for (intptr_t i = 0; i < positional_count; ++i) {
    VisitDartType();  // read ith positional parameter.
  }

  if (!simple) {
    const intptr_t named_count =
        helper_.ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      helper_.SkipStringReference();
      VisitDartType();  // read named_parameters[i].type.
    }
  }

  if (!simple) {
    helper_.SkipOptionalDartType();  // read typedef reference.
  }

  VisitDartType();  // read return type.
}

void ScopeBuilder::VisitTypeParameterType() {
  Function& function = Function::Handle(Z, parsed_function_->function().raw());
  while (function.IsClosureFunction()) {
    function = function.parent_function();
  }

  // The index here is the index identifying the type parameter binding site
  // inside the DILL file, which uses a different indexing system than the VM
  // uses for its 'TypeParameter's internally. This index includes both class
  // and function type parameters.

  intptr_t index = helper_.ReadUInt();  // read index for parameter.

  if (function.IsFactory()) {
    // The type argument vector is passed as the very first argument to the
    // factory constructor function.
    HandleSpecialLoad(&result_->type_arguments_variable,
                      Symbols::TypeArgumentsParameter());
  } else {
    // If the type parameter is a parameter to this or an enclosing function, we
    // can read it directly from the function type arguments vector later.
    // Otherwise, the type arguments vector we need is stored on the instance
    // object, so we need to capture 'this'.
    Class& parent_class = Class::Handle(Z, function.Owner());
    if (index < parent_class.NumTypeParameters()) {
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
    }
  }

  helper_.SkipOptionalDartType();  // read bound bound.
}

void ScopeBuilder::HandleLocalFunction(intptr_t parent_kernel_offset) {
  // "Peek" ahead into the function node
  intptr_t offset = helper_.ReaderOffset();

  FunctionNodeHelper function_node_helper(&helper_);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);

  LocalScope* saved_function_scope = current_function_scope_;
  FunctionNodeHelper::AsyncMarker saved_function_async_marker =
      current_function_async_marker_;
  DepthState saved_depth_state = depth_;
  depth_ = DepthState(depth_.function_ + 1);
  EnterScope(parent_kernel_offset);
  current_function_scope_ = scope_;
  current_function_async_marker_ = function_node_helper.async_marker_;
  if (depth_.function_ == 1) {
    FunctionScope function_scope = {offset, scope_};
    result_->function_scopes.Add(function_scope);
  }

  int num_type_params = 0;
  {
    AlternativeReadingScope _(&helper_.reader_);
    num_type_params = helper_.ReadListLength();
  }
  // Adding this scope here informs the type translator the type parameters of
  // this function are now in scope, although they are not defined and will be
  // filled in with dynamic. This is OK, since their definitions are not needed
  // for scope building of the enclosing function.
  TypeTranslator::TypeParameterScope scope(&type_translator_, num_type_params);

  // read positional_parameters and named_parameters.
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);

  ProcedureAttributesMetadata default_attrs;
  AddPositionalAndNamedParameters(0, kTypeCheckAllParameters, default_attrs);

  // "Peek" is now done.
  helper_.SetOffset(offset);

  VisitFunctionNode();  // read function node.

  ExitScope(function_node_helper.position_, function_node_helper.end_position_);
  depth_ = saved_depth_state;
  current_function_scope_ = saved_function_scope;
  current_function_async_marker_ = saved_function_async_marker;
}

void ScopeBuilder::EnterScope(intptr_t kernel_offset) {
  scope_ = new (Z) LocalScope(scope_, depth_.function_, depth_.loop_);
  ASSERT(kernel_offset >= 0);
  result_->scopes.Insert(kernel_offset, scope_);
}

void ScopeBuilder::ExitScope(TokenPosition start_position,
                             TokenPosition end_position) {
  scope_->set_begin_token_pos(start_position);
  scope_->set_end_token_pos(end_position);
  scope_ = scope_->parent();
}

void ScopeBuilder::AddPositionalAndNamedParameters(
    intptr_t pos,
    ParameterTypeCheckMode type_check_mode /* = kTypeCheckAllParameters*/,
    const ProcedureAttributesMetadata& attrs) {
  // List of positional.
  intptr_t list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    AddVariableDeclarationParameter(pos++, type_check_mode, attrs);
  }

  // List of named.
  list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    AddVariableDeclarationParameter(pos++, type_check_mode, attrs);
  }
}

void ScopeBuilder::AddVariableDeclarationParameter(
    intptr_t pos,
    ParameterTypeCheckMode type_check_mode,
    const ProcedureAttributesMetadata& attrs) {
  intptr_t kernel_offset = helper_.ReaderOffset();  // no tag.
  const InferredTypeMetadata parameter_type =
      inferred_type_metadata_helper_.GetInferredType(kernel_offset);
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  String& name = H.DartSymbolObfuscate(helper.name_index_);
  AbstractType& type = BuildAndVisitVariableType();  // read type.
  helper.SetJustRead(VariableDeclarationHelper::kType);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);

  LocalVariable* variable = MakeVariable(helper.position_, helper.position_,
                                         name, type, &parameter_type);
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  if (helper.IsCovariant()) {
    variable->set_is_explicit_covariant_parameter();
  }
  if (variable->name().raw() == Symbols::IteratorParameter().raw()) {
    variable->set_is_forced_stack();
  }

  const bool needs_covariant_check_in_method =
      helper.IsCovariant() ||
      (helper.IsGenericCovariantImpl() &&
       (attrs.has_non_this_uses || attrs.has_tearoff_uses));

  switch (type_check_mode) {
    case kTypeCheckAllParameters:
      variable->set_type_check_mode(LocalVariable::kDoTypeCheck);
      break;
    case kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod:
      if (needs_covariant_check_in_method) {
        // Don't type check covariant parameters - they will be checked by
        // a function we forward to. Their types however are not known.
        variable->set_type_check_mode(LocalVariable::kSkipTypeCheck);
      } else {
        variable->set_type_check_mode(LocalVariable::kDoTypeCheck);
      }
      break;
    case kTypeCheckForNonDynamicallyInvokedMethod:
      if (needs_covariant_check_in_method) {
        variable->set_type_check_mode(LocalVariable::kDoTypeCheck);
      } else {
        // Types of non-covariant parameters are guaranteed to match by
        // front-end enforcing strong mode types at call site.
        variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
      }
      break;
    case kTypeCheckForStaticFunction:
      variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
      break;
  }

  // TODO(sjindel): We can also skip these checks on dynamic invocations as
  // well.
  if (parameter_type.IsSkipCheck()) {
    variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  }

  scope_->InsertParameterAt(pos, variable);
  result_->locals.Insert(helper_.data_program_offset_ + kernel_offset,
                         variable);

  // The default value may contain 'let' bindings for which the constant
  // evaluator needs scope bindings.
  Tag tag = helper_.ReadTag();
  if (tag == kSomething) {
    VisitExpression();  // read initializer.
  }
}

LocalVariable* ScopeBuilder::MakeVariable(
    TokenPosition declaration_pos,
    TokenPosition token_pos,
    const String& name,
    const AbstractType& type,
    const InferredTypeMetadata* param_type_md /* = NULL */) {
  CompileType* param_type = NULL;
  if ((param_type_md != NULL) && !param_type_md->IsTrivial()) {
    param_type = new (Z) CompileType(param_type_md->ToCompileType(Z));
  }
  return new (Z)
      LocalVariable(declaration_pos, token_pos, name, type, param_type);
}

void ScopeBuilder::AddExceptionVariable(
    GrowableArray<LocalVariable*>* variables,
    const char* prefix,
    intptr_t nesting_depth) {
  LocalVariable* v = NULL;

  // If we are inside a function with yield points then Kernel transformer
  // could have lifted some of the auxiliary exception variables into the
  // context to preserve them across yield points because they might
  // be needed for rethrow.
  // Check if it did and capture such variables instead of introducing
  // new local ones.
  // Note: function that wrap kSyncYielding function does not contain
  // its own try/catches.
  if (current_function_async_marker_ == FunctionNodeHelper::kSyncYielding) {
    ASSERT(current_function_scope_->parent() != NULL);
    v = current_function_scope_->parent()->LocalLookupVariable(
        GenerateName(prefix, nesting_depth - 1));
    if (v != NULL) {
      scope_->CaptureVariable(v);
    }
  }

  // No need to create variables for try/catch-statements inside
  // nested functions.
  if (depth_.function_ > 0) return;
  if (variables->length() >= nesting_depth) return;

  // If variable was not lifted by the transformer introduce a new
  // one into the current function scope.
  if (v == NULL) {
    v = MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     GenerateName(prefix, nesting_depth - 1),
                     AbstractType::dynamic_type());

    // If transformer did not lift the variable then there is no need
    // to lift it into the context when we encouter a YieldStatement.
    v->set_is_forced_stack();
    current_function_scope_->AddVariable(v);
  }

  variables->Add(v);
}

void ScopeBuilder::FinalizeExceptionVariable(
    GrowableArray<LocalVariable*>* variables,
    GrowableArray<LocalVariable*>* raw_variables,
    const String& symbol,
    intptr_t nesting_depth) {
  // No need to create variables for try/catch-statements inside
  // nested functions.
  if (depth_.function_ > 0) return;

  LocalVariable* variable = (*variables)[nesting_depth - 1];
  LocalVariable* raw_variable;
  if (variable->is_captured()) {
    raw_variable =
        new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                          symbol, AbstractType::dynamic_type());
    const bool ok = scope_->AddVariable(raw_variable);
    ASSERT(ok);
  } else {
    raw_variable = variable;
  }
  raw_variables->EnsureLength(nesting_depth, nullptr);
  (*raw_variables)[nesting_depth - 1] = raw_variable;
}

void ScopeBuilder::AddTryVariables() {
  AddExceptionVariable(&result_->catch_context_variables,
                       ":saved_try_context_var", depth_.try_);
}

void ScopeBuilder::AddCatchVariables() {
  AddExceptionVariable(&result_->exception_variables, ":exception",
                       depth_.catch_);
  AddExceptionVariable(&result_->stack_trace_variables, ":stack_trace",
                       depth_.catch_);
}

void ScopeBuilder::FinalizeCatchVariables() {
  const intptr_t unique_id = result_->raw_variable_counter_++;
  FinalizeExceptionVariable(
      &result_->exception_variables, &result_->raw_exception_variables,
      GenerateName(":raw_exception", unique_id), depth_.catch_);
  FinalizeExceptionVariable(
      &result_->stack_trace_variables, &result_->raw_stack_trace_variables,
      GenerateName(":raw_stacktrace", unique_id), depth_.catch_);
}

void ScopeBuilder::AddIteratorVariable() {
  if (depth_.function_ > 0) return;
  if (result_->iterator_variables.length() >= depth_.for_in_) return;

  ASSERT(result_->iterator_variables.length() == depth_.for_in_ - 1);
  LocalVariable* iterator =
      MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                   GenerateName(":iterator", depth_.for_in_ - 1),
                   AbstractType::dynamic_type());
  current_function_scope_->AddVariable(iterator);
  result_->iterator_variables.Add(iterator);
}

void ScopeBuilder::AddSwitchVariable() {
  if ((depth_.function_ == 0) && (result_->switch_variable == NULL)) {
    LocalVariable* variable =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::SwitchExpr(), AbstractType::dynamic_type());
    variable->set_is_forced_stack();
    current_function_scope_->AddVariable(variable);
    result_->switch_variable = variable;
  }
}

void ScopeBuilder::LookupVariable(intptr_t declaration_binary_offset) {
  LocalVariable* variable = result_->locals.Lookup(declaration_binary_offset);
  if (variable == NULL) {
    // We have not seen a declaration of the variable, so it must be the
    // case that we are compiling a nested function and the variable is
    // declared in an outer scope.  In that case, look it up in the scope by
    // name and add it to the variable map to simplify later lookup.
    ASSERT(current_function_scope_->parent() != NULL);
    StringIndex var_name = GetNameFromVariableDeclaration(
        declaration_binary_offset - helper_.data_program_offset_,
        parsed_function_->function());

    const String& name = H.DartSymbolObfuscate(var_name);
    variable = current_function_scope_->parent()->LookupVariable(name, true);
    ASSERT(variable != NULL);
    result_->locals.Insert(declaration_binary_offset, variable);
  }

  if (variable->owner()->function_level() < scope_->function_level()) {
    // We call `LocalScope->CaptureVariable(variable)` in two scenarios for two
    // different reasons:
    //   Scenario 1:
    //       We need to know which variables defined in this function
    //       are closed over by nested closures in order to ensure we will
    //       create a [Context] object of appropriate size and store captured
    //       variables there instead of the stack.
    //   Scenario 2:
    //       We need to find out which variables defined in enclosing functions
    //       are closed over by this function/closure or nested closures. This
    //       is necessary in order to build a fat flattened [ContextScope]
    //       object.
    scope_->CaptureVariable(variable);
  } else {
    ASSERT(variable->owner()->function_level() == scope_->function_level());
  }
}

StringIndex ScopeBuilder::GetNameFromVariableDeclaration(
    intptr_t kernel_offset,
    const Function& function) {
  ExternalTypedData& kernel_data =
      ExternalTypedData::Handle(Z, function.KernelData());
  ASSERT(!kernel_data.IsNull());

  // Temporarily go to the variable declaration, read the name.
  AlternativeReadingScope alt(&helper_.reader_, &kernel_data, kernel_offset);
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilIncluding(VariableDeclarationHelper::kNameIndex);
  return helper.name_index_;
}

const String& ScopeBuilder::GenerateName(const char* prefix, intptr_t suffix) {
  char name[64];
  Utils::SNPrint(name, 64, "%s%" Pd "", prefix, suffix);
  return H.DartSymbolObfuscate(name);
}

void ScopeBuilder::HandleSpecialLoad(LocalVariable** variable,
                                     const String& symbol) {
  if (current_function_scope_->parent() != NULL) {
    // We are building the scope tree of a closure function and saw [node]. We
    // lazily populate the variable using the parent function scope.
    if (*variable == NULL) {
      *variable =
          current_function_scope_->parent()->LookupVariable(symbol, true);
      ASSERT(*variable != NULL);
    }
  }

  if ((current_function_scope_->parent() != NULL) ||
      (scope_->function_level() > 0)) {
    // Every scope we use the [variable] from needs to be notified of the usage
    // in order to ensure that preserving the context scope on that particular
    // use-site also includes the [variable].
    scope_->CaptureVariable(*variable);
  }
}

void ScopeBuilder::LookupCapturedVariableByName(LocalVariable** variable,
                                                const String& name) {
  if (*variable == NULL) {
    *variable = scope_->LookupVariable(name, true);
    ASSERT(*variable != NULL);
    scope_->CaptureVariable(*variable);
  }
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
