// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/scope_builder.h"

#include "vm/compiler/backend/il.h"  // For CompileType.
#include "vm/compiler/frontend/kernel_translation_helper.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()
#define IG IsolateGroup::Current()

ScopeBuilder::ScopeBuilder(ParsedFunction* parsed_function)
    : result_(nullptr),
      parsed_function_(parsed_function),
      translation_helper_(Thread::Current()),
      zone_(translation_helper_.zone()),
      current_function_scope_(nullptr),
      scope_(nullptr),
      depth_(0),
      name_index_(0),
      needs_expr_temp_(false),
      helper_(
          zone_,
          &translation_helper_,
          TypedDataView::Handle(Z, parsed_function->function().KernelLibrary()),
          parsed_function->function().KernelLibraryOffset()),
      constant_reader_(&helper_, &active_class_),
      inferred_type_metadata_helper_(&helper_, &constant_reader_),
      inferred_arg_type_metadata_helper_(
          &helper_,
          &constant_reader_,
          InferredTypeMetadataHelper::Kind::ArgType),
      procedure_attributes_metadata_helper_(&helper_),
      type_translator_(&helper_,
                       &constant_reader_,
                       &active_class_,
                       /*finalize=*/true) {
  const auto& kernel_program_info = KernelProgramInfo::Handle(
      Z, parsed_function->function().KernelProgramInfo());
  H.InitFromKernelProgramInfo(kernel_program_info);
  ASSERT(type_translator_.active_class_ == &active_class_);
}

ScopeBuildingResult* ScopeBuilder::BuildScopes() {
  if (result_ != nullptr) return result_;

  ASSERT(scope_ == nullptr && depth_.loop_ == 0 && depth_.function_ == 0);
  result_ = new (Z) ScopeBuildingResult();

  const Function& function = parsed_function_->function();

  // Setup an [ActiveClassScope] and an [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass = Class::Handle(Z, function.Owner());

  Function& outermost_function =
      Function::Handle(Z, function.GetOutermostFunction());

  ActiveClassScope active_class_scope(&active_class_, &klass);
  ActiveMemberScope active_member(&active_class_, &outermost_function);
  FunctionType& signature = FunctionType::Handle(Z, function.signature());
  ActiveTypeParametersScope active_type_params(&active_class_, function,
                                               &signature, Z);

  LocalScope* enclosing_scope = nullptr;
  if (function.IsImplicitClosureFunction() && !function.is_static()) {
    // Create artificial enclosing scope for the tear-off that contains
    // captured receiver value. This ensure that AssertAssignable will correctly
    // load instantiator type arguments if they are needed.
    Class& klass = Class::Handle(Z, function.Owner());
    Type& klass_type = H.GetDeclarationType(klass);
    LocalVariable* receiver_variable =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::This(), klass_type);
    parsed_function_->set_receiver_var(receiver_variable);
    receiver_variable->set_is_captured();
    enclosing_scope = new (Z) LocalScope(nullptr, 0, 0);
    enclosing_scope->set_context_level(0);
    enclosing_scope->AddVariable(receiver_variable);
    enclosing_scope->AddContextVariable(receiver_variable);
  } else if (function.HasParent()) {
    enclosing_scope = LocalScope::RestoreOuterScope(
        ContextScope::Handle(Z, function.context_scope()));
  }
  current_function_scope_ = scope_ = new (Z) LocalScope(enclosing_scope, 0, 0);
  scope_->set_begin_token_pos(function.token_pos());
  scope_->set_end_token_pos(function.end_token_pos());

  if (function.IsSuspendableFunction()) {
    LocalVariable* suspend_state_var =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::SuspendStateVar(), AbstractType::dynamic_type());
    suspend_state_var->set_is_forced_stack();
    suspend_state_var->set_invisible(true);
    scope_->AddVariable(suspend_state_var);
    parsed_function_->set_suspend_state_var(suspend_state_var);
  }

  // Add function type arguments variable before current context variable.
  if (function.IsGeneric() || function.HasGenericParent()) {
    LocalVariable* type_args_var = MakeVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::FunctionTypeArgumentsVar(), AbstractType::dynamic_type());
    scope_->AddVariable(type_args_var);
    parsed_function_->set_function_type_arguments(type_args_var);
  }

  if (parsed_function_->has_arg_desc_var()) {
    scope_->AddVariable(parsed_function_->arg_desc_var());
  }

  LocalVariable* context_var = parsed_function_->current_context_var();
  context_var->set_is_forced_stack();
  scope_->AddVariable(context_var);

  parsed_function_->set_scope(scope_);

  helper_.SetOffset(function.kernel_offset());

  FunctionNodeHelper function_node_helper(&helper_);
  const ProcedureAttributesMetadata attrs =
      procedure_attributes_metadata_helper_.GetProcedureAttributes(
          function.kernel_offset());

  switch (function.kind()) {
    case UntaggedFunction::kImplicitClosureFunction: {
      const auto& parent = Function::Handle(Z, function.parent_function());
      const auto& target =
          Function::Handle(Z, function.ImplicitClosureTarget(Z));

      // For BuildGraphOfNoSuchMethodForwarder, since closures no longer
      // require arg_desc_var in all cases.
      if (target.IsNull() ||
          (parent.num_fixed_parameters() != target.num_fixed_parameters())) {
        needs_expr_temp_ = true;
      }
    }
      FALL_THROUGH;
    case UntaggedFunction::kClosureFunction:
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kConstructor: {
      const Tag tag = helper_.PeekTag();
      helper_.ReadUntilFunctionNode();
      function_node_helper.ReadUntilExcluding(
          FunctionNodeHelper::kPositionalParameters);
      // NOTE: FunctionNode is read further below the if.

      intptr_t pos = 0;
      if (function.is_ffi_native()) {
        needs_expr_temp_ = true;
        // Calls with handles need try/catch variables.
        if (function.FfiCSignatureContainsHandles()) {
          ++depth_.try_;
          AddTryVariables();
          --depth_.try_;
          ++depth_.catch_;
          AddCatchVariables();
          FinalizeCatchVariables();
          --depth_.catch_;
        }
      } else if (function.IsClosureFunction()) {
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
        parsed_function_->set_receiver_var(variable);

        // We visit instance field initializers because they might contain
        // [Let] expressions and we need to have a mapping.
        if (tag == kConstructor) {
          Class& parent_class = Class::Handle(Z, function.Owner());
          Array& class_fields = Array::Handle(Z, parent_class.fields());
          Field& class_field = Field::Handle(Z);
          for (intptr_t i = 0; i < class_fields.Length(); ++i) {
            class_field ^= class_fields.At(i);
            if (!class_field.is_static()) {
              const auto& kernel_data =
                  TypedDataView::Handle(Z, class_field.KernelLibrary());
              ASSERT(!kernel_data.IsNull());
              intptr_t field_offset = class_field.kernel_offset();
              AlternativeReadingScopeWithNewData alt(
                  &helper_.reader_, &kernel_data, field_offset);
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

      ParameterTypeCheckMode type_check_mode =
          kTypeCheckForNonDynamicallyInvokedMethod;
      if (function.is_static()) {
        // In static functions we don't check anything.
        type_check_mode = kTypeCheckForStaticFunction;
      } else if (function.IsImplicitClosureFunction()) {
        // All non-covariant checks are either performed by the type system,
        // or by a dynamic closure call dispatcher/mirror if dynamically
        // invoked. For covariant checks, static targets never have covariant
        // arguments and dynamic targets do their own covariant checking.
        // Thus, implicit closure functions perform no checking internally.
        type_check_mode = kTypeCheckForImplicitClosureFunction;
      }

      // Continue reading FunctionNode:
      // read positional_parameters and named_parameters.
      AddPositionalAndNamedParameters(pos, type_check_mode, attrs);

      if (function.IsSuspendableFunction()) {
        // Read return type which is used to create a result of
        // async/async*/sync* function. It may reference receiver or type
        // arguments of the enclosing function which need to be captured.
        VisitDartType();
      }

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
    case UntaggedFunction::kImplicitGetter:
    case UntaggedFunction::kImplicitSetter: {
      ASSERT(helper_.PeekTag() == kField);
      const bool is_setter = function.IsImplicitSetterFunction();
      const bool is_method = !function.IsStaticFunction();
      const auto& field = Field::Handle(Z, function.accessor_field());
      intptr_t pos = 0;
      if (is_method) {
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetDeclarationType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        parsed_function_->set_receiver_var(variable);
      }
      if (is_setter) {
        if (CompilerState::Current().is_aot()) {
          const intptr_t kernel_offset = field.kernel_offset();
          const InferredTypeMetadata parameter_type =
              inferred_type_metadata_helper_.GetInferredType(kernel_offset);
          result_->setter_value = MakeVariable(
              TokenPosition::kNoSource, TokenPosition::kNoSource,
              Symbols::Value(),
              AbstractType::ZoneHandle(Z, function.ParameterTypeAt(pos)),
              LocalVariable::kNoKernelOffset, /*is_late=*/false,
              /*inferred_type=*/nullptr,
              /*inferred_arg_type=*/&parameter_type);
        } else {
          result_->setter_value = MakeVariable(
              TokenPosition::kNoSource, TokenPosition::kNoSource,
              Symbols::Value(),
              AbstractType::ZoneHandle(Z, function.ParameterTypeAt(pos)));
        }
        scope_->InsertParameterAt(pos++, result_->setter_value);

        if (is_method) {
          if (field.is_covariant()) {
            result_->setter_value->set_is_explicit_covariant_parameter();
          } else if (!field.is_generic_covariant_impl() ||
                     (!attrs.has_non_this_uses && !attrs.has_tearoff_uses)) {
            result_->setter_value->set_type_check_mode(
                LocalVariable::kTypeCheckedByCaller);
          }
        }
      }
      break;
    }
    case UntaggedFunction::kImplicitStaticGetter: {
      ASSERT(helper_.PeekTag() == kField);
      ASSERT(function.IsStaticFunction());
      // In addition to static field initializers, scopes/local variables
      // are needed for implicit getters of static const fields, in order to
      // be able to evaluate their initializers in constant evaluator.
      if (Field::Handle(Z, function.accessor_field()).is_const()) {
        VisitNode();
      }
      break;
    }
    case UntaggedFunction::kFieldInitializer: {
      ASSERT(helper_.PeekTag() == kField);
      if (!function.is_static()) {
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetDeclarationType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(0, variable);
        parsed_function_->set_receiver_var(variable);
      }
      VisitNode();
      break;
    }
    case UntaggedFunction::kDynamicInvocationForwarder: {
      const String& name = String::Handle(Z, function.name());
      ASSERT(Function::IsDynamicInvocationForwarderName(name));

      const auto& target = Function::ZoneHandle(Z, function.ForwardingTarget());
      ASSERT(!target.IsNull());

      if (helper_.PeekTag() == kField) {
        // Create [this] variable.
        const Class& klass = Class::Handle(Z, function.Owner());
        parsed_function_->set_receiver_var(
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), H.GetDeclarationType(klass)));
        scope_->InsertParameterAt(0, parsed_function_->receiver_var());

        // Create setter value variable.
        if (target.IsImplicitSetterFunction()) {
          result_->setter_value = MakeVariable(
              TokenPosition::kNoSource, TokenPosition::kNoSource,
              Symbols::Value(),
              AbstractType::ZoneHandle(Z, function.ParameterTypeAt(1)));
          scope_->InsertParameterAt(1, result_->setter_value);
        }
        break;
      }

      // We do not create dyn:* forwarders for method extractors, since those
      // can never return unboxed values (they return a closure).
      ASSERT(!target.IsMethodExtractor());

      helper_.ReadUntilFunctionNode();
      function_node_helper.ReadUntilExcluding(
          FunctionNodeHelper::kPositionalParameters);

      // Create [this] variable.
      intptr_t pos = 0;
      Class& klass = Class::Handle(Z, function.Owner());
      parsed_function_->set_receiver_var(
          MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                       Symbols::This(), H.GetDeclarationType(klass)));
      scope_->InsertParameterAt(pos++, parsed_function_->receiver_var());

      // Create all positional and named parameters.
      AddPositionalAndNamedParameters(
          pos, kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod,
          attrs);
      break;
    }
    case UntaggedFunction::kMethodExtractor: {
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
      parsed_function_->set_receiver_var(variable);
      break;
    }
    case UntaggedFunction::kFfiTrampoline: {
      needs_expr_temp_ = true;
      // Callbacks and calls with handles need try/catch variables.
      if ((function.GetFfiFunctionKind() != FfiFunctionKind::kCall ||
           function.FfiCSignatureContainsHandles())) {
        ++depth_.try_;
        AddTryVariables();
        --depth_.try_;
        ++depth_.catch_;
        AddCatchVariables();
        FinalizeCatchVariables();
        --depth_.catch_;
      }
      FALL_THROUGH;
    }
    case UntaggedFunction::kInvokeFieldDispatcher: {
      if (function.IsDynamicClosureCallDispatcher()) {
        auto const vars = parsed_function_->EnsureDynamicClosureCallVars();
        ASSERT(vars != nullptr);
#define ADD_VAR(Name, _, __) scope_->AddVariable(vars->Name);
        FOR_EACH_DYNAMIC_CLOSURE_CALL_VARIABLE(ADD_VAR);
#undef ADD_VAR
        for (auto const& v : vars->named_argument_parameter_indices) {
          scope_->AddVariable(v);
        }
      }
    }
      FALL_THROUGH;
    case UntaggedFunction::kNoSuchMethodDispatcher: {
      for (intptr_t i = 0; i < function.NumParameters(); ++i) {
        LocalVariable* variable = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            String::ZoneHandle(Z, function.ParameterNameAt(i)),
            AbstractType::ZoneHandle(Z, function.IsFfiTrampoline()
                                            ? function.ParameterTypeAt(i)
                                            : Object::dynamic_type().ptr()));
        bool added = scope_->InsertParameterAt(i, variable);
        ASSERT(added);
      }
      break;
    }
    case UntaggedFunction::kRecordFieldGetter: {
      needs_expr_temp_ = true;
      // Add a receiver parameter.
      Class& klass = Class::Handle(Z, function.Owner());
      parsed_function_->set_receiver_var(
          MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                       Symbols::This(), H.GetDeclarationType(klass)));
      scope_->InsertParameterAt(0, parsed_function_->receiver_var());
      break;
    }
    case UntaggedFunction::kIrregexpFunction:
      UNREACHABLE();
  }
  if (needs_expr_temp_) {
    parsed_function_->EnsureExpressionTemp();
  }
  if (parsed_function_->has_expression_temp_var()) {
    scope_->AddVariable(parsed_function_->expression_temp_var());
  }
  if (parsed_function_->function().MayHaveUncheckedEntryPoint()) {
    scope_->AddVariable(parsed_function_->EnsureEntryPointsTemp());
  }

  parsed_function_->AllocateVariables();

  // :suspend_state variable should be allocated to a fixed location in
  // the stack frame.
  RELEASE_ASSERT((parsed_function_->suspend_state_var() == nullptr) ||
                 (parsed_function_->suspend_state_var()->index().value() ==
                  SuspendState::kSuspendStateVarIndex));

  return result_;
}

void ScopeBuilder::ReportUnexpectedTag(const char* variant, Tag tag) {
  const auto& script = Script::Handle(Z, Script());
  H.ReportError(script, TokenPosition::kNoSource,
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
        const auto& kernel_data =
            TypedDataView::Handle(Z, class_field.KernelLibrary());
        ASSERT(!kernel_data.IsNull());
        intptr_t field_offset = class_field.kernel_offset();
        AlternativeReadingScopeWithNewData alt(&helper_.reader_, &kernel_data,
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
  VisitFunctionNode();
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
    VisitDartType();  // read ith default type.
    helper.Finish();
  }
  function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);

  // Read (but don't visit) the positional and named parameters, because they've
  // already been added to the scope.
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kBody);

  if (helper_.ReadTag() == kSomething) {
    PositionScope scope(&helper_.reader_);
    VisitStatement();  // Read body
    first_body_token_position_ = helper_.reader_.min_position();
  }
}

void ScopeBuilder::VisitInitializer() {
  Tag tag = helper_.ReadTag();
  helper_.ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      helper_.ReadPosition();                // read position.
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
      if (helper_.ReadTag() == kSomething) {
        VisitExpression();  // read expression.
      }
      return;
    case kVariableGet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();          // read kernel position.
      helper_.ReadUInt();              // read relative variable index.
      helper_.SkipOptionalDartType();  // read promoted type.
      VisitVariableGet(variable_kernel_offset);
      return;
    }
    case kSpecializedVariableGet: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();  // read kernel position.
      VisitVariableGet(variable_kernel_offset);
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
    case kInstanceGet:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      helper_.SkipDartType();  // read result_type.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kDynamicGet:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      return;
    case kInstanceTearOff:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      helper_.SkipDartType();  // read result_type.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kFunctionTearOff:
      // Removed by lowering kernel transformation.
      UNREACHABLE();
      break;
    case kInstanceSet:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitExpression();       // read value.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kDynamicSet:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitExpression();       // read value.
      return;
    case kAbstractSuperPropertyGet:
      // Abstract super property getters must be converted into super property
      // getters during mixin transformation.
      UNREACHABLE();
      break;
    case kAbstractSuperPropertySet:
      // Abstract super property setters must be converted into super property
      // setters during mixin transformation.
      UNREACHABLE();
      break;
    case kSuperPropertyGet:
      HandleLoadReceiver();
      helper_.ReadPosition();                      // read position.
      helper_.SkipName();                          // read name.
      helper_.SkipInterfaceMemberNameReference();  // read target_reference.
      return;
    case kSuperPropertySet:
      HandleLoadReceiver();
      helper_.ReadPosition();                      // read position.
      helper_.SkipName();                          // read name.
      VisitExpression();                           // read value.
      helper_.SkipInterfaceMemberNameReference();  // read target_reference.
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
    case kInstanceInvocation:
      helper_.ReadByte();      // read kind.
      helper_.ReadFlags();     // read flags.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitArguments();        // read arguments.
      helper_.SkipDartType();  // read function_type.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kDynamicInvocation:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipName();      // read name.
      VisitArguments();        // read arguments.
      return;
    case kLocalFunctionInvocation: {
      helper_.ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          helper_.ReadUInt();  // read variable kernel position.
      helper_.ReadUInt();      // read relative variable index.
      VisitArguments();        // read arguments.
      helper_.SkipDartType();  // read function_type.
      VisitVariableGet(variable_kernel_offset);
      return;
    }
    case kFunctionInvocation:
      helper_.ReadByte();      // read kind.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      VisitArguments();        // read arguments.
      helper_.SkipDartType();  // read function_type.
      return;
    case kEqualsCall:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read left.
      VisitExpression();       // read right.
      helper_.SkipDartType();  // read function_type.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kEqualsNull:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kAbstractSuperMethodInvocation:
      // Abstract super method invocations must be converted into super
      // method invocations during mixin transformation.
      UNREACHABLE();
      break;
    case kSuperMethodInvocation:
      HandleLoadReceiver();
      helper_.ReadPosition();  // read position.
      helper_.SkipName();      // read name.
      VisitArguments();        // read arguments.
      // read interface_target_reference.
      helper_.SkipInterfaceMemberNameReference();
      return;
    case kStaticInvocation:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read procedure_reference.
      VisitArguments();                      // read arguments.
      return;
    case kConstructorInvocation:
      helper_.ReadPosition();                // read position.
      helper_.SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                      // read arguments.
      return;
    case kNot:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kNullCheck:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kLogicalExpression:
      needs_expr_temp_ = true;
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read left.
      helper_.SkipBytes(1);    // read operator.
      VisitExpression();       // read right.
      return;
    case kConditionalExpression: {
      needs_expr_temp_ = true;
      helper_.ReadPosition();          // read position.
      VisitExpression();               // read condition.
      VisitExpression();               // read then.
      VisitExpression();               // read otherwise.
      helper_.SkipOptionalDartType();  // read unused static type.
      return;
    }
    case kStringConcatenation: {
      helper_.ReadPosition();  // read position.
      VisitListOfExpressions();
      return;
    }
    case kIsExpression:
      needs_expr_temp_ = true;
      helper_.ReadPosition();  // read position.
      helper_.ReadFlags();     // read flags.
      VisitExpression();       // read operand.
      VisitDartType();         // read type.
      return;
    case kAsExpression:
      helper_.ReadPosition();  // read position.
      helper_.ReadFlags();     // read flags.
      VisitExpression();       // read operand.
      VisitDartType();         // read type.
      return;
    case kTypeLiteral:
      helper_.ReadPosition();  // read file offset.
      VisitDartType();         // read type.
      return;
    case kThisExpression:
      HandleLoadReceiver();
      helper_.ReadPosition();  // read file offset.
      return;
    case kRethrow:
      helper_.ReadPosition();  // read position.
      return;
    case kThrow:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kListLiteral: {
      helper_.ReadPosition();  // read position.
      VisitDartType();         // read type.
      VisitListOfExpressions();
      return;
    }
    case kSetLiteral: {
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      return;
    }
    case kMapLiteral: {
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
    case kRecordLiteral:
      helper_.ReadPosition();         // read position.
      VisitListOfExpressions();       // read positionals.
      VisitListOfNamedExpressions();  // read named.
      VisitDartType();                // read recordType.
      return;
    case kRecordIndexGet:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read receiver.
      helper_.SkipDartType();  // read recordType.
      helper_.ReadUInt();      // read index.
      return;
    case kRecordNameGet:
      helper_.ReadPosition();         // read position.
      VisitExpression();              // read receiver.
      helper_.SkipDartType();         // read recordType.
      helper_.SkipStringReference();  // read name.
      return;
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

      helper_.ReadPosition();      // read position.
      VisitVariableDeclaration();  // read variable declaration.
      VisitExpression();           // read expression.

      ExitScope(helper_.reader_.min_position(), helper_.reader_.max_position());
      return;
    }
    case kBlockExpression: {
      PositionScope scope(&helper_.reader_);
      intptr_t offset = helper_.ReaderOffset() - 1;  // -1 to include tag byte.

      EnterScope(offset);

      helper_.ReadPosition();  // read position.
      intptr_t list_length =
          helper_.ReadListLength();  // read number of statements.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitStatement();  // read ith statement.
      }
      VisitExpression();  // read expression.

      ExitScope(helper_.reader_.min_position(), helper_.reader_.max_position());
      return;
    }
    case kBigIntLiteral:
      helper_.ReadPosition();         // read position.
      helper_.SkipStringReference();  // read string reference.
      return;
    case kStringLiteral:
      helper_.ReadPosition();         // read position.
      helper_.SkipStringReference();  // read string reference.
      return;
    case kSpecializedIntLiteral:
      helper_.ReadPosition();  // read position.
      return;
    case kNegativeIntLiteral:
      helper_.ReadPosition();  // read position.
      helper_.ReadUInt();      // read value.
      return;
    case kPositiveIntLiteral:
      helper_.ReadPosition();  // read position.
      helper_.ReadUInt();      // read value.
      return;
    case kDoubleLiteral:
      helper_.ReadPosition();  // read position.
      helper_.ReadDouble();    // read value.
      return;
    case kTrueLiteral:
      helper_.ReadPosition();  // read position.
      return;
    case kFalseLiteral:
      helper_.ReadPosition();  // read position.
      return;
    case kNullLiteral:
      helper_.ReadPosition();  // read position.
      return;
    case kConstantExpression:
      helper_.ReadPosition();
      helper_.SkipDartType();
      helper_.SkipConstantReference();
      return;
    case kFileUriConstantExpression:
      helper_.ReadPosition();
      helper_.ReadUInt();
      helper_.SkipDartType();
      helper_.SkipConstantReference();
      return;
    case kInstantiation: {
      helper_.ReadPosition();  // read position.
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
      helper_.ReadPosition();  // read file offset.
      helper_.ReadUInt();      // library index
      break;
    case kAwaitExpression:
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read operand.
      if (helper_.ReadTag() == kSomething) {
        VisitDartType();  // read runtime check type.
      }
      return;
    case kFileUriExpression:
      helper_.ReadUInt();      // read uri.
      helper_.ReadPosition();  // read position.
      VisitExpression();       // read expression.
      return;
    case kConstStaticInvocation:
    case kConstConstructorInvocation:
    case kConstListLiteral:
    case kConstSetLiteral:
    case kConstMapLiteral:
    case kSymbolLiteral:
    case kListConcatenation:
    case kSetConcatenation:
    case kMapConcatenation:
    case kInstanceCreation:
    case kStaticTearOff:
    case kSwitchExpression:
    case kPatternAssignment:
    // These nodes are internal to the front end and
    // removed by the constant evaluator.
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
      helper_.ReadPosition();  // read block start offset.
      helper_.ReadPosition();  // read block end offset.
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
      if (IG->asserts()) {
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
      if (IG->asserts()) {
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
      helper_.ReadPosition();  // read position.
      VisitStatement();        // read body.
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
      VisitListOfExpressions();  // read updates.
      VisitStatement();          // read body.

      ExitScope(position, helper_.reader_.max_position());
      --depth_.loop_;
      return;
    }
    case kSwitchStatement: {
      AddSwitchVariable();
      helper_.ReadPosition();                     // read position.
      helper_.ReadBool();                         // read exhaustive flag.
      VisitExpression();                          // read condition.
      helper_.SkipOptionalDartType();             // read expression type.
      int case_count = helper_.ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        helper_.ReadPosition();  // read file offset.
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
          (result_->finally_return_variable == nullptr)) {
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
      helper_.ReadPosition();  // read position.
      VisitStatement();        // read body.
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

      helper_.ReadPosition();  // read position.
      VisitStatement();        // read body.

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
      helper_.ReadPosition();  // read position.
      helper_.ReadByte();      // read flags.
      VisitExpression();       // read expression.
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
    case kForInStatement:
    case kAsyncForInStatement:
    case kIfCaseStatement:
    case kPatternSwitchStatement:
    case kPatternVariableDeclaration:
    // These nodes are internal to the front end and
    // removed by the constant evaluator.
    default:
      ReportUnexpectedTag("declaration", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitListOfExpressions() {
  const intptr_t list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitExpression();
  }
}

void ScopeBuilder::VisitListOfNamedExpressions() {
  const intptr_t list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    helper_.SkipStringReference();  // read ith name index.
    VisitExpression();              // read ith expression.
  }
}

void ScopeBuilder::VisitArguments() {
  helper_.ReadUInt();  // read argument_count.

  // Types
  intptr_t list_length = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitDartType();  // read ith type.
  }

  VisitListOfExpressions();       // Positional.
  VisitListOfNamedExpressions();  // Named.
}

void ScopeBuilder::VisitVariableDeclaration() {
  PositionScope scope(&helper_.reader_);

  const intptr_t kernel_offset =
      helper_.data_program_offset_ + helper_.ReaderOffset();
  // MetadataHelper expects relative offsets and adjusts them internally
  const InferredTypeMetadata inferred_type =
      inferred_type_metadata_helper_.GetInferredType(helper_.ReaderOffset());
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kAnnotations);
  const intptr_t annotations_offset = helper_.ReaderOffset();
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  AbstractType& type = BuildAndVisitVariableType();

  const String& name = (H.StringSize(helper.name_index_) == 0)
                           ? GenerateName(":var", name_index_++)
                           : H.DartSymbolObfuscate(helper.name_index_);

  intptr_t initializer_offset = helper_.ReaderOffset();
  Tag tag = helper_.ReadTag();  // read (first part of) initializer.
  if (tag == kSomething) {
    VisitExpression();  // read (actual) initializer.
  }

  // Go to next token position so it ends *after* the last potentially
  // debuggable position in the initializer.
  TokenPosition end_position = helper_.reader_.max_position();
  if (end_position.IsReal()) {
    end_position = end_position.Next();
  }
  LocalVariable* variable =
      MakeVariable(helper.position_, end_position, name, type, kernel_offset,
                   helper.IsLate(), &inferred_type);
  if (helper.annotation_count_ > 0) {
    variable->set_annotations_offset(annotations_offset);
  }
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  if (helper.IsLate()) {
    variable->set_is_late();
    variable->set_late_init_offset(initializer_offset);
  }
  if (helper.IsSynthesized()) {
    variable->set_invisible(true);
  }

  scope_->AddVariable(variable);
  result_->locals.Insert(kernel_offset, variable);
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
    case kNullType:
      // those contain nothing.
      return;
    case kNeverType:
      helper_.ReadNullability();
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
    case kRecordType:
      VisitRecordType();
      return;
    case kTypeParameterType:
      VisitTypeParameterType();
      return;
    case kIntersectionType:
      VisitIntersectionType();
      return;
    case kExtensionType:
      VisitExtensionType();
      return;
    case kFutureOrType:
      VisitFutureOrType();
      return;
    default:
      ReportUnexpectedTag("type", tag);
      UNREACHABLE();
  }
}

void ScopeBuilder::VisitInterfaceType(bool simple) {
  helper_.ReadNullability();  // read nullability.
  helper_.ReadUInt();         // read klass_name.
  if (!simple) {
    intptr_t length = helper_.ReadListLength();  // read number of types.
    for (intptr_t i = 0; i < length; ++i) {
      VisitDartType();  // read the ith type.
    }
  }
}

void ScopeBuilder::VisitFunctionType(bool simple) {
  helper_.ReadNullability();  // read nullability.

  if (!simple) {
    intptr_t list_length =
        helper_.ReadListLength();  // read type_parameters list length.
    for (int i = 0; i < list_length; ++i) {
      TypeParameterHelper helper(&helper_);
      helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);
      VisitDartType();  // read bound.
      helper.ReadUntilExcludingAndSetJustRead(
          TypeParameterHelper::kDefaultType);
      VisitDartType();  // read default type.
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
      VisitDartType();     // read named_parameters[i].type.
      helper_.ReadByte();  // read flags
    }
  }

  VisitDartType();  // read return type.
}

void ScopeBuilder::VisitRecordType() {
  helper_.ReadNullability();  // read nullability.
  const intptr_t positional_count =
      helper_.ReadListLength();  // read positional list length.
  for (intptr_t i = 0; i < positional_count; ++i) {
    VisitDartType();  // read positional[i].
  }
  const intptr_t named_count =
      helper_.ReadListLength();  // read named list length.
  for (intptr_t i = 0; i < named_count; ++i) {
    helper_.SkipStringReference();  // read named[i].name.
    VisitDartType();                // read named[i].type.
    helper_.ReadFlags();            // read named[i].flags
  }
}

void ScopeBuilder::VisitTypeParameterType() {
  Function& function = Function::Handle(Z, parsed_function_->function().ptr());

  helper_.ReadNullability();  // read nullability.

  // The index here is the index identifying the type parameter binding site
  // inside the DILL file, which uses a different indexing system than the VM
  // uses for its 'TypeParameter's internally. This index includes both class
  // and function type parameters.

  intptr_t index = helper_.ReadUInt();  // read index for parameter.

  if (!function.IsImplicitStaticClosureFunction()) {
    while (function.IsClosureFunction()) {
      function = function.parent_function();
    }

    if (function.IsFactory()) {
      // The type argument vector is passed as the very first argument to the
      // factory constructor function.
      HandleSpecialLoad(&result_->type_arguments_variable,
                        Symbols::TypeArgumentsParameter(),
                        LocalVariable::kNoKernelOffset);
    } else {
      // If the type parameter is a parameter to this or an enclosing function,
      // we can read it directly from the function type arguments vector later.
      // Otherwise, the type arguments vector we need is stored on the instance
      // object, so we need to capture 'this'.
      Class& parent_class = Class::Handle(Z, function.Owner());
      if (index < parent_class.NumTypeParameters()) {
        HandleLoadReceiver();
      }
    }
  }
}

void ScopeBuilder::VisitIntersectionType() {
  VisitDartType();         // read left.
  helper_.SkipDartType();  // read right.
}

void ScopeBuilder::VisitExtensionType() {
  // We skip the extension type and only use the type erasure.
  helper_.ReadNullability();
  helper_.SkipCanonicalNameReference();  // read index for canonical name.
  helper_.SkipListOfDartTypes();         // read type arguments
  VisitDartType();                       // read type erasure.
}

void ScopeBuilder::VisitFutureOrType() {
  helper_.ReadNullability();
  VisitDartType();  // read type argument.
}

void ScopeBuilder::HandleLocalFunction(intptr_t parent_kernel_offset) {
  // "Peek" ahead into the function node
  const intptr_t offset = helper_.ReaderOffset();

  FunctionNodeHelper function_node_helper(&helper_);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);

  LocalScope* saved_function_scope = current_function_scope_;
  DepthState saved_depth_state = depth_;
  depth_ = DepthState(depth_.function_ + 1);
  EnterScope(parent_kernel_offset);
  current_function_scope_ = scope_;
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
  AddPositionalAndNamedParameters(0, kTypeCheckForNonDynamicallyInvokedMethod,
                                  default_attrs);

  if (function_node_helper.async_marker_ != FunctionNodeHelper::kSync) {
    // Read return type which is used to create a result of async/async*/sync*
    // function. It may reference receiver or type arguments of the enclosing
    // function which need to be captured.
    VisitDartType();
  }

  // "Peek" is now done.
  helper_.SetOffset(offset);

  VisitFunctionNode();  // read function node.

  // Remember if this closure and all closures nested within it don't
  // capture any variables from outer scopes.
  if (scope_->function_level() == 1) {
    if (scope_->NumCapturedVariables() == 0) {
      result_->closure_offsets_without_captures.Add(offset);
    }
  }

  ExitScope(function_node_helper.position_, function_node_helper.end_position_);
  depth_ = saved_depth_state;
  current_function_scope_ = saved_function_scope;
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
  // Convert kernel offset of variable declaration to absolute.
  const intptr_t kernel_offset =
      helper_.data_program_offset_ + helper_.ReaderOffset();
  // MetadataHelper expects relative offsets and adjusts them internally
  const InferredTypeMetadata inferred_type =
      inferred_type_metadata_helper_.GetInferredType(helper_.ReaderOffset());
  const InferredTypeMetadata inferred_arg_type =
      inferred_arg_type_metadata_helper_.GetInferredType(
          helper_.ReaderOffset());
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kAnnotations);
  const intptr_t annotations_offset = helper_.ReaderOffset();
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  String& name = H.DartSymbolObfuscate(helper.name_index_);
  ASSERT(name.Length() > 0);
  AbstractType& type = BuildAndVisitVariableType();  // read type.
  helper.SetJustRead(VariableDeclarationHelper::kType);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);

  LocalVariable* variable = MakeVariable(
      helper.position_, helper.position_, name, type, kernel_offset,
      /*is_late=*/false, &inferred_type, &inferred_arg_type);
  if (helper.annotation_count_ > 0) {
    variable->set_annotations_offset(annotations_offset);
  }
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  if (helper.IsCovariant()) {
    variable->set_is_explicit_covariant_parameter();
  }

  const bool needs_covariant_check_in_method =
      helper.IsCovariant() ||
      (helper.IsGenericCovariantImpl() &&
       (attrs.has_non_this_uses || attrs.has_tearoff_uses));
  if (needs_covariant_check_in_method) {
    variable->set_needs_covariant_check_in_method();
  }

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
    case kTypeCheckForImplicitClosureFunction:
      if (needs_covariant_check_in_method) {
        // Don't type check covariant parameters - they will be checked by
        // a function we forward to. Their types however are not known.
        variable->set_type_check_mode(LocalVariable::kSkipTypeCheck);
      } else {
        // All non-covariant checks are either checked by the type system or
        // by a dynamic closure call dispatcher.
        variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
      }
      break;
    case kTypeCheckForStaticFunction:
      variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
      break;
  }

  // TODO(sjindel): We can also skip these checks on dynamic invocations as
  // well.
  if (inferred_arg_type.IsSkipCheck()) {
    variable->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  }

  scope_->InsertParameterAt(pos, variable);
  result_->locals.Insert(kernel_offset, variable);

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
    const AbstractType& static_type,
    intptr_t kernel_offset /* = LocalVariable::kNoKernelOffset */,
    bool is_late /* = false */,
    const InferredTypeMetadata* inferred_type_md /* = nullptr */,
    const InferredTypeMetadata* inferred_arg_type_md /* = nullptr */) {
  CompileType* inferred_type = nullptr;
  if (inferred_type_md != nullptr && !inferred_type_md->IsTrivial()) {
    inferred_type = new (Z)
        CompileType(inferred_type_md->ToCompileType(Z, &static_type, is_late));
  } else {
    inferred_type = new (Z) CompileType(CompileType::FromAbstractType(
        static_type, CompileType::kCanBeNull, is_late));
  }
  CompileType* inferred_arg_type = nullptr;
  const Object* inferred_arg_value = nullptr;
  if (inferred_arg_type_md != nullptr && !inferred_arg_type_md->IsTrivial()) {
    inferred_arg_type =
        new (Z) CompileType(inferred_arg_type_md->ToCompileType(Z));
    if (inferred_arg_type_md->IsConstant()) {
      inferred_arg_value = &inferred_arg_type_md->constant_value;
    }
  }
  return new (Z) LocalVariable(declaration_pos, token_pos, name, static_type,
                               kernel_offset, inferred_type, inferred_arg_type,
                               inferred_arg_value);
}

void ScopeBuilder::AddExceptionVariable(
    GrowableArray<LocalVariable*>* variables,
    const char* prefix,
    intptr_t nesting_depth) {
  LocalVariable* v = nullptr;

  // No need to create variables for try/catch-statements inside
  // nested functions.
  if (depth_.function_ > 0) return;
  if (variables->length() >= nesting_depth) return;

  // If variable was not lifted by the transformer introduce a new
  // one into the current function scope.
  if (v == nullptr) {
    v = MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     GenerateName(prefix, nesting_depth - 1),
                     AbstractType::dynamic_type());

    // If transformer did not lift the variable then there is no need
    // to lift it into the context when we encounter a YieldStatement.
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
    raw_variable->set_is_forced_stack();
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

void ScopeBuilder::AddSwitchVariable() {
  if ((depth_.function_ == 0) && (result_->switch_variable == nullptr)) {
    LocalVariable* variable =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::SwitchExpr(), AbstractType::dynamic_type());
    variable->set_is_forced_stack();
    current_function_scope_->AddVariable(variable);
    result_->switch_variable = variable;
  }
}

void ScopeBuilder::VisitVariableGet(intptr_t declaration_binary_offset) {
  LocalVariable* variable = LookupVariable(declaration_binary_offset);
  if (variable->is_late()) {
    // Late variable initializer expressions may also contain local variables
    // that need to be captured.
    AlternativeReadingScope alt(&helper_.reader_, variable->late_init_offset());
    if (helper_.ReadTag() != kNothing) {
      VisitExpression();
    }
  }
}

LocalVariable* ScopeBuilder::LookupVariable(
    intptr_t declaration_binary_offset) {
  LocalVariable* variable = result_->locals.Lookup(declaration_binary_offset);
  if (variable == nullptr) {
    // We have not seen a declaration of the variable, so it must be the
    // case that we are compiling a nested function and the variable is
    // declared in an outer scope.  In that case, look it up in the scope by
    // name and add it to the variable map to simplify later lookup.
    ASSERT(current_function_scope_->parent() != nullptr);
    StringIndex var_name = GetNameFromVariableDeclaration(
        declaration_binary_offset - helper_.data_program_offset_,
        parsed_function_->function());

    const String& name = H.DartSymbolObfuscate(var_name);
    variable = current_function_scope_->parent()->LookupVariable(
        name, declaration_binary_offset, true);
    ASSERT(variable != nullptr);
    result_->locals.Insert(declaration_binary_offset, variable);
  }

  ASSERT(variable->owner() != nullptr);
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
  return variable;
}

StringIndex ScopeBuilder::GetNameFromVariableDeclaration(
    intptr_t kernel_offset,
    const Function& function) {
  const auto& kernel_data = TypedDataView::Handle(Z, function.KernelLibrary());
  ASSERT(!kernel_data.IsNull());

  // Temporarily go to the variable declaration, read the name.
  AlternativeReadingScopeWithNewData alt(&helper_.reader_, &kernel_data,
                                         kernel_offset);
  VariableDeclarationHelper helper(&helper_);
  helper.ReadUntilIncluding(VariableDeclarationHelper::kNameIndex);
  return helper.name_index_;
}

const String& ScopeBuilder::GenerateName(const char* prefix, intptr_t suffix) {
  char name[64];
  Utils::SNPrint(name, 64, "%s%" Pd "", prefix, suffix);
  return H.DartSymbolObfuscate(name);
}

void ScopeBuilder::HandleLoadReceiver() {
  if (!parsed_function_->has_receiver_var() &&
      current_function_scope_->parent() != nullptr) {
    // Lazily populate receiver variable using the parent function scope.
    parsed_function_->set_receiver_var(
        current_function_scope_->parent()->LookupVariable(
            Symbols::This(), LocalVariable::kNoKernelOffset, true));
  }

  if ((current_function_scope_->parent() != nullptr) ||
      (scope_->function_level() > 0)) {
    // Every scope we use the [receiver] from needs to be notified of the usage
    // in order to ensure that preserving the context scope on that particular
    // use-site also includes the [receiver].
    scope_->CaptureVariable(parsed_function_->receiver_var());
  }

  parsed_function_->set_receiver_used();
}

void ScopeBuilder::HandleSpecialLoad(LocalVariable** variable,
                                     const String& symbol,
                                     intptr_t kernel_offset) {
  if (current_function_scope_->parent() != nullptr) {
    // We are building the scope tree of a closure function and saw [node]. We
    // lazily populate the variable using the parent function scope.
    if (*variable == nullptr) {
      *variable = current_function_scope_->parent()->LookupVariable(
          symbol, kernel_offset, true);
      ASSERT(*variable != nullptr);
    }
  }

  if ((current_function_scope_->parent() != nullptr) ||
      (scope_->function_level() > 0)) {
    // Every scope we use the [variable] from needs to be notified of the usage
    // in order to ensure that preserving the context scope on that particular
    // use-site also includes the [variable].
    scope_->CaptureVariable(*variable);
  }
}

}  // namespace kernel
}  // namespace dart
