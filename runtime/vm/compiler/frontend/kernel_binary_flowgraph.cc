// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"

#include "vm/compiler/ffi.h"
#include "vm/compiler/frontend/bytecode_flow_graph_builder.h"
#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/compiler/frontend/flow_graph_builder.h"  // For dart::FlowGraphBuilder::SimpleInstanceOfType.
#include "vm/compiler/frontend/prologue_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DECLARE_FLAG(bool, enable_interpreter);

namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()
#define B (flow_graph_builder_)

Class& StreamingFlowGraphBuilder::GetSuperOrDie() {
  Class& klass = Class::Handle(Z, parsed_function()->function().Owner());
  ASSERT(!klass.IsNull());
  klass = klass.SuperClass();
  ASSERT(!klass.IsNull());
  return klass;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfFieldInitializer() {
  FieldHelper field_helper(this);
  field_helper.ReadUntilExcluding(FieldHelper::kInitializer);

  Tag initializer_tag = ReadTag();  // read first part of initializer.
  if (initializer_tag != kSomething) {
    UNREACHABLE();
  }

  B->graph_entry_ = new (Z) GraphEntryInstr(*parsed_function(), B->osr_id_);

  auto normal_entry = B->BuildFunctionEntry(B->graph_entry_);
  B->graph_entry_->set_normal_entry(normal_entry);

  Fragment body(normal_entry);
  body += B->CheckStackOverflowInPrologue(field_helper.position_);
  if (field_helper.IsConst()) {
    // this will (potentially) read the initializer, but reset the position.
    body += Constant(Instance::ZoneHandle(
        Z, constant_evaluator_.EvaluateExpression(ReaderOffset())));
    SkipExpression();  // read the initializer.
  } else {
    body += BuildExpression();  // read initializer.
  }
  body += Return(TokenPosition::kNoSource);

  PrologueInfo prologue_info(-1, -1);
  if (B->IsCompiledForOsr()) {
    B->graph_entry_->RelinkToOsrEntry(Z, B->last_used_block_id_ + 1);
  }
  return new (Z) FlowGraph(*parsed_function(), B->graph_entry_,
                           B->last_used_block_id_, prologue_info);
}

void StreamingFlowGraphBuilder::EvaluateConstFieldValue(const Field& field) {
  ASSERT(field.is_const() && field.IsUninitialized());

  FieldHelper field_helper(this);
  field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
  Tag initializer_tag = ReadTag();  // read first part of initializer.

  ASSERT(initializer_tag == kSomething);

  Instance& value = Instance::Handle(
      Z, constant_evaluator_.EvaluateExpression(ReaderOffset()));
  field.SetStaticValue(value);
}

void StreamingFlowGraphBuilder::SetupDefaultParameterValues() {
  intptr_t optional_parameter_count =
      parsed_function()->function().NumOptionalParameters();
  if (optional_parameter_count > 0) {
    ZoneGrowableArray<const Instance*>* default_values =
        new ZoneGrowableArray<const Instance*>(Z, optional_parameter_count);

    AlternativeReadingScope alt(&reader_);
    FunctionNodeHelper function_node_helper(this);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kPositionalParameters);

    if (parsed_function()->function().HasOptionalNamedParameters()) {
      // List of positional.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipVariableDeclaration();  // read ith variable declaration.
      }

      // List of named.
      list_length = ReadListLength();  // read list length.
      ASSERT(optional_parameter_count == list_length);
      ASSERT(!parsed_function()->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < list_length; ++i) {
        Instance* default_value;

        // Read ith variable declaration
        VariableDeclarationHelper helper(this);
        helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
        Tag tag = ReadTag();  // read (first part of) initializer.
        if (tag == kSomething) {
          // this will (potentially) read the initializer,
          // but reset the position.
          default_value = &Instance::ZoneHandle(
              Z, constant_evaluator_.EvaluateExpression(ReaderOffset()));
          SkipExpression();  // read (actual) initializer.
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    } else {
      // List of positional.
      intptr_t list_length = ReadListLength();  // read list length.
      ASSERT(list_length == function_node_helper.required_parameter_count_ +
                                optional_parameter_count);
      ASSERT(parsed_function()->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < function_node_helper.required_parameter_count_;
           ++i) {
        SkipVariableDeclaration();  // read ith variable declaration.
      }
      for (intptr_t i = 0; i < optional_parameter_count; ++i) {
        Instance* default_value;

        // Read ith variable declaration
        VariableDeclarationHelper helper(this);
        helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
        Tag tag = ReadTag();  // read (first part of) initializer.
        if (tag == kSomething) {
          // this will (potentially) read the initializer,
          // but reset the position.
          default_value = &Instance::ZoneHandle(
              Z, constant_evaluator_.EvaluateExpression(ReaderOffset()));
          SkipExpression();  // read (actual) initializer.
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }

      // List of named.
      list_length = ReadListLength();  // read list length.
      ASSERT(list_length == 0);
    }
    parsed_function()->set_default_parameter_values(default_values);
  }
}

Fragment StreamingFlowGraphBuilder::BuildFieldInitializer(
    NameIndex canonical_name) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  Field& field =
      Field::ZoneHandle(Z, H.LookupFieldByKernelField(canonical_name));
  if (PeekTag() == kNullLiteral) {
    SkipExpression();  // read past the null literal.
    if (H.thread()->IsMutatorThread()) {
      field.RecordStore(Object::null_object());
    } else {
      ASSERT(field.is_nullable(/* silence_assert = */ true));
    }
    return Fragment();
  }

  Fragment instructions;
  instructions += LoadLocal(parsed_function()->receiver_var());
  // All closures created inside BuildExpression will have
  // field.RawOwner() as its owner.
  closure_owner_ = field.RawOwner();
  instructions += BuildExpression();
  closure_owner_ = Object::null();
  instructions += flow_graph_builder_->StoreInstanceFieldGuarded(field, true);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInitializers(
    const Class& parent_class) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  Fragment instructions;

  // Start by getting the position of the constructors initializer.
  intptr_t initializers_offset = -1;
  {
    AlternativeReadingScope alt(&reader_);
    SkipFunctionNode();  // read constructors function node.
    initializers_offset = ReaderOffset();
  }

  // These come from:
  //   class A {
  //     var x = (expr);
  //   }
  // We don't want to do that when this is a Redirecting Constructors though
  // (i.e. has a single initializer being of type kRedirectingInitializer).
  bool is_redirecting_constructor = false;
  {
    AlternativeReadingScope alt(&reader_, initializers_offset);
    intptr_t list_length = ReadListLength();  // read initializers list length.
    bool no_field_initializers = true;
    for (intptr_t i = 0; i < list_length; ++i) {
      if (PeekTag() == kRedirectingInitializer) {
        is_redirecting_constructor = true;
      } else if (PeekTag() == kFieldInitializer) {
        no_field_initializers = false;
      }
      SkipInitializer();
    }
    ASSERT(is_redirecting_constructor ? no_field_initializers : true);
  }

  if (!is_redirecting_constructor) {
    Array& class_fields = Array::Handle(Z, parent_class.fields());
    Field& class_field = Field::Handle(Z);
    for (intptr_t i = 0; i < class_fields.Length(); ++i) {
      class_field ^= class_fields.At(i);
      if (!class_field.is_static()) {
        ExternalTypedData& kernel_data =
            ExternalTypedData::Handle(Z, class_field.KernelData());
        ASSERT(!kernel_data.IsNull());
        intptr_t field_offset = class_field.kernel_offset();
        AlternativeReadingScopeWithNewData alt(&reader_, &kernel_data,
                                               field_offset);
        FieldHelper field_helper(this);
        field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
        Tag initializer_tag = ReadTag();  // read first part of initializer.
        if (initializer_tag == kSomething) {
          EnterScope(field_offset);
          instructions += BuildFieldInitializer(
              field_helper.canonical_name_);  // read initializer.
          ExitScope(field_offset);
        }
      }
    }
  }

  // These to come from:
  //   class A {
  //     var x;
  //     var y;
  //     A(this.x) : super(expr), y = (expr);
  //   }
  {
    AlternativeReadingScope alt(&reader_, initializers_offset);
    intptr_t list_length = ReadListLength();  // read initializers list length.
    for (intptr_t i = 0; i < list_length; ++i) {
      Tag tag = ReadTag();
      bool isSynthetic = ReadBool();  // read isSynthetic flag.
      switch (tag) {
        case kInvalidInitializer:
          UNIMPLEMENTED();
          return Fragment();
        case kFieldInitializer: {
          NameIndex canonical_name =
              ReadCanonicalNameReference();  // read field_reference.
          instructions += BuildFieldInitializer(canonical_name);  // read value.
          break;
        }
        case kAssertInitializer: {
          instructions += BuildStatement();
          break;
        }
        case kSuperInitializer: {
          TokenPosition position = ReadPosition();  // read position.
          NameIndex canonical_target =
              ReadCanonicalNameReference();  // read target_reference.

          instructions += LoadLocal(parsed_function()->receiver_var());
          instructions += PushArgument();

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(
              &argument_names, &argument_count,
              /* positional_parameter_count = */ NULL);  // read arguments.
          argument_count += 1;

          Class& parent_klass = GetSuperOrDie();

          const Function& target = Function::ZoneHandle(
              Z, H.LookupConstructorByKernelConstructor(
                     parent_klass, H.CanonicalNameString(canonical_target)));
          instructions += StaticCall(
              isSynthetic ? TokenPosition::kNoSource : position, target,
              argument_count, argument_names, ICData::kStatic);
          instructions += Drop();
          break;
        }
        case kRedirectingInitializer: {
          TokenPosition position = ReadPosition();  // read position.
          NameIndex canonical_target =
              ReadCanonicalNameReference();  // read target_reference.

          instructions += LoadLocal(parsed_function()->receiver_var());
          instructions += PushArgument();

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(
              &argument_names, &argument_count,
              /* positional_parameter_count = */ NULL);  // read arguments.
          argument_count += 1;

          const Function& target = Function::ZoneHandle(
              Z, H.LookupConstructorByKernelConstructor(canonical_target));
          instructions += StaticCall(
              isSynthetic ? TokenPosition::kNoSource : position, target,
              argument_count, argument_names, ICData::kStatic);
          instructions += Drop();
          break;
        }
        case kLocalInitializer: {
          // The other initializers following this one might read the variable.
          // This is used e.g. for evaluating the arguments to a super call
          // first, run normal field initializers next and then make the actual
          // super call:
          //
          //   The frontend converts
          //
          //      class A {
          //        var x;
          //        A(a, b) : super(a + b), x = 2*b {}
          //      }
          //
          //   to
          //
          //      class A {
          //        var x;
          //        A(a, b) : tmp = a + b, x = 2*b, super(tmp) {}
          //      }
          //
          // (This is strictly speaking not what one should do in terms of the
          //  specification but that is how it is currently implemented.)
          LocalVariable* variable =
              LookupVariable(ReaderOffset() + data_program_offset_);

          // Variable declaration
          VariableDeclarationHelper helper(this);
          helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
          ASSERT(!helper.IsConst());
          Tag tag = ReadTag();  // read (first part of) initializer.
          if (tag != kSomething) {
            UNREACHABLE();
          }

          instructions += BuildExpression();  // read initializer.
          instructions += StoreLocal(TokenPosition::kNoSource, variable);
          instructions += Drop();
          break;
        }
        default:
          ReportUnexpectedTag("initializer", tag);
          UNREACHABLE();
      }
    }
  }
  return instructions;
}

void StreamingFlowGraphBuilder::ReadDefaultFunctionTypeArguments(
    const Function& function) {
  if (!function.IsGeneric()) {
    return;
  }
  AlternativeReadingScope alt(&reader_);
  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  intptr_t num_type_params = ReadListLength();
  ASSERT(num_type_params == function.NumTypeParameters());
  TypeArguments& default_types =
      TypeArguments::Handle(Z, TypeArguments::New(num_type_params));
  for (intptr_t i = 0; i < num_type_params; ++i) {
    TypeParameterHelper helper(this);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kDefaultType);
    if (ReadTag() == kSomething) {
      default_types.SetTypeAt(i, T.BuildType());
    } else {
      default_types.SetTypeAt(i, Object::dynamic_type());
    }
    helper.Finish();
  }
  default_types = default_types.Canonicalize();
  parsed_function()->SetDefaultFunctionTypeArguments(default_types);
}

Fragment StreamingFlowGraphBuilder::DebugStepCheckInPrologue(
    const Function& dart_function,
    TokenPosition position) {
  if (!NeedsDebugStepCheck(dart_function, position)) {
    return {};
  }

  // Place this check at the last parameter to ensure parameters
  // are in scope in the debugger at method entry.
  const int parameter_count = dart_function.NumParameters();
  TokenPosition check_pos = TokenPosition::kNoSource;
  if (parameter_count > 0) {
    const LocalVariable& parameter =
        *parsed_function()->ParameterVariable(parameter_count - 1);
    check_pos = parameter.token_pos();
  }
  if (!check_pos.IsDebugPause()) {
    // No parameters or synthetic parameters.
    check_pos = position;
    ASSERT(check_pos.IsDebugPause());
  }

  return DebugStepCheck(check_pos);
}

Fragment StreamingFlowGraphBuilder::SetAsyncStackTrace(
    const Function& dart_function) {
  if (!FLAG_causal_async_stacks ||
      !(dart_function.IsAsyncClosure() || dart_function.IsAsyncGenClosure())) {
    return {};
  }

  // The code we are building will be executed right after we enter
  // the function and before any nested contexts are allocated.
  ASSERT(B->context_depth_ ==
         scopes()->yield_jump_variable->owner()->context_level());

  Fragment instructions;
  LocalScope* scope = parsed_function()->scope();

  const Function& target = Function::ZoneHandle(
      Z, I->object_store()->async_set_thread_stack_trace());
  ASSERT(!target.IsNull());

  // Fetch and load :async_stack_trace
  LocalVariable* async_stack_trace_var =
      scope->LookupVariable(Symbols::AsyncStackTraceVar(), false);
  ASSERT((async_stack_trace_var != NULL) &&
         async_stack_trace_var->is_captured());

  Fragment code;
  code += LoadLocal(async_stack_trace_var);
  code += PushArgument();
  // Call _asyncSetThreadStackTrace
  code += StaticCall(TokenPosition::kNoSource, target,
                     /* argument_count = */ 1, ICData::kStatic);
  code += Drop();
  return code;
}

Fragment StreamingFlowGraphBuilder::TypeArgumentsHandling(
    const Function& dart_function) {
  Fragment prologue = B->BuildDefaultTypeHandling(dart_function);

  if (dart_function.IsClosureFunction() &&
      dart_function.NumParentTypeParameters() > 0) {
    LocalVariable* closure = parsed_function()->ParameterVariable(0);

    // Function with yield points can not be generic itself but the outer
    // function can be.
    ASSERT(yield_continuations().is_empty() || !dart_function.IsGeneric());

    LocalVariable* fn_type_args = parsed_function()->function_type_arguments();
    ASSERT(fn_type_args != NULL && closure != NULL);

    if (dart_function.IsGeneric()) {
      prologue += LoadLocal(fn_type_args);
      prologue += PushArgument();
      prologue += LoadLocal(closure);
      prologue += LoadNativeField(Slot::Closure_function_type_arguments());
      prologue += PushArgument();
      prologue += IntConstant(dart_function.NumParentTypeParameters());
      prologue += PushArgument();
      prologue += IntConstant(dart_function.NumTypeParameters() +
                              dart_function.NumParentTypeParameters());
      prologue += PushArgument();

      const Library& dart_internal =
          Library::Handle(Z, Library::InternalLibrary());
      const Function& prepend_function =
          Function::ZoneHandle(Z, dart_internal.LookupFunctionAllowPrivate(
                                      Symbols::PrependTypeArguments()));
      ASSERT(!prepend_function.IsNull());

      prologue += StaticCall(TokenPosition::kNoSource, prepend_function, 4,
                             ICData::kStatic);
      prologue += StoreLocal(TokenPosition::kNoSource, fn_type_args);
      prologue += Drop();
    } else {
      prologue += LoadLocal(closure);
      prologue += LoadNativeField(Slot::Closure_function_type_arguments());
      prologue += StoreLocal(TokenPosition::kNoSource, fn_type_args);
      prologue += Drop();
    }
  }

  return prologue;
}

Fragment StreamingFlowGraphBuilder::CompleteBodyWithYieldContinuations(
    Fragment body) {
  // The code we are building will be executed right after we enter
  // the function and before any nested contexts are allocated.
  // Reset current context_depth_ to match this.
  const intptr_t current_context_depth = B->context_depth_;
  B->context_depth_ = scopes()->yield_jump_variable->owner()->context_level();

  // Prepend an entry corresponding to normal entry to the function.
  yield_continuations().InsertAt(
      0, YieldContinuation(new (Z) DropTempsInstr(0, NULL), kInvalidTryIndex));
  yield_continuations()[0].entry->LinkTo(body.entry);

  // Load :await_jump_var into a temporary.
  Fragment dispatch;
  dispatch += LoadLocal(scopes()->yield_jump_variable);
  dispatch += StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
  dispatch += Drop();

  BlockEntryInstr* block = NULL;
  for (intptr_t i = 0; i < yield_continuations().length(); i++) {
    if (i == 1) {
      // This is not a normal entry but a resumption.  Restore
      // :current_context_var from :await_ctx_var.
      // Note: after this point context_depth_ does not match current context
      // depth so we should not access any local variables anymore.
      dispatch += LoadLocal(scopes()->yield_context_variable);
      dispatch += StoreLocal(TokenPosition::kNoSource,
                             parsed_function()->current_context_var());
      dispatch += Drop();
    }
    if (i == (yield_continuations().length() - 1)) {
      // We reached the last possibility, no need to build more ifs.
      // Continue to the last continuation.
      // Note: continuations start with nop DropTemps instruction
      // which acts like an anchor, so we need to skip it.
      block->set_try_index(yield_continuations()[i].try_index);
      dispatch <<= yield_continuations()[i].entry->next();
      break;
    }

    // Build comparison:
    //
    //   if (:await_jump_var == i) {
    //     -> yield_continuations()[i]
    //   } else ...
    //
    TargetEntryInstr* then;
    TargetEntryInstr* otherwise;
    dispatch += LoadLocal(scopes()->switch_variable);
    dispatch += IntConstant(i);
    dispatch += B->BranchIfStrictEqual(&then, &otherwise);

    // True branch is linked to appropriate continuation point.
    // Note: continuations start with nop DropTemps instruction
    // which acts like an anchor, so we need to skip it.
    then->LinkTo(yield_continuations()[i].entry->next());
    then->set_try_index(yield_continuations()[i].try_index);
    // False branch will contain the next comparison.
    dispatch = Fragment(dispatch.entry, otherwise);
    block = otherwise;
  }
  B->context_depth_ = current_context_depth;
  return dispatch;
}

Fragment StreamingFlowGraphBuilder::CheckStackOverflowInPrologue(
    const Function& dart_function) {
  if (dart_function.is_native()) return {};
  return B->CheckStackOverflowInPrologue(dart_function.token_pos());
}

Fragment StreamingFlowGraphBuilder::SetupCapturedParameters(
    const Function& dart_function) {
  Fragment body;
  const LocalScope* scope = parsed_function()->scope();
  if (scope->num_context_variables() > 0) {
    body += flow_graph_builder_->PushContext(scope);
    LocalVariable* context = MakeTemporary();

    // Copy captured parameters from the stack into the context.
    LocalScope* scope = parsed_function()->scope();
    intptr_t parameter_count = dart_function.NumParameters();
    const ParsedFunction& pf = *flow_graph_builder_->parsed_function_;
    const Function& function = pf.function();

    for (intptr_t i = 0; i < parameter_count; ++i) {
      LocalVariable* variable = pf.ParameterVariable(i);
      if (variable->is_captured()) {
        LocalVariable& raw_parameter = *pf.RawParameterVariable(i);
        ASSERT((function.HasOptionalParameters() &&
                raw_parameter.owner() == scope) ||
               (!function.HasOptionalParameters() &&
                raw_parameter.owner() == NULL));
        ASSERT(!raw_parameter.is_captured());

        // Copy the parameter from the stack to the context.  Overwrite it
        // with a null constant on the stack so the original value is
        // eligible for garbage collection.
        body += LoadLocal(context);
        body += LoadLocal(&raw_parameter);
        body += flow_graph_builder_->StoreInstanceField(
            TokenPosition::kNoSource,
            Slot::GetContextVariableSlotFor(thread(), *variable));
        body += NullConstant();
        body += StoreLocal(TokenPosition::kNoSource, &raw_parameter);
        body += Drop();
      }
    }
    body += Drop();  // The context.
  }
  return body;
}

// If we run in checked mode or strong mode, we have to check the type of the
// passed arguments.
//
// TODO(#34162): If we're building an extra entry-point to skip
// type checks, we should substitute Redefinition nodes for the AssertAssignable
// instructions to ensure that the argument types are known.
void StreamingFlowGraphBuilder::CheckArgumentTypesAsNecessary(
    const Function& dart_function,
    intptr_t type_parameters_offset,
    Fragment* explicit_checks,
    Fragment* implicit_checks,
    Fragment* implicit_redefinitions) {
  if (!dart_function.NeedsArgumentTypeChecks(I)) return;

  // Check if parent function was annotated with no-dynamic-invocations.
  const ProcedureAttributesMetadata attrs =
      procedure_attributes_metadata_helper_.GetProcedureAttributes(
          dart_function.kernel_offset());

  AlternativeReadingScope _(&reader_);
  SetOffset(type_parameters_offset);
  B->BuildArgumentTypeChecks(
      MethodCanSkipTypeChecksForNonCovariantArguments(dart_function, attrs)
          ? TypeChecksToBuild::kCheckCovariantTypeParameterBounds
          : TypeChecksToBuild::kCheckAllTypeParameterBounds,
      explicit_checks, implicit_checks, implicit_redefinitions);
}

Fragment StreamingFlowGraphBuilder::ShortcutForUserDefinedEquals(
    const Function& dart_function,
    LocalVariable* first_parameter) {
  // The specification defines the result of `a == b` to be:
  //
  //   a) if either side is `null` then the result is `identical(a, b)`.
  //   b) else the result is `a.operator==(b)`
  //
  // For user-defined implementations of `operator==` we need therefore
  // implement the handling of a).
  //
  // The default `operator==` implementation in `Object` is implemented in terms
  // of identical (which we assume here!) which means that case a) is actually
  // included in b).  So we just use the normal implementation in the body.
  Fragment body;
  if ((dart_function.NumParameters() == 2) &&
      (dart_function.name() == Symbols::EqualOperator().raw()) &&
      (dart_function.Owner() != I->object_store()->object_class())) {
    TargetEntryInstr* null_entry;
    TargetEntryInstr* non_null_entry;

    body += LoadLocal(first_parameter);
    body += BranchIfNull(&null_entry, &non_null_entry);

    // The argument was `null` and the receiver is not the null class (we only
    // go into this branch for user-defined == operators) so we can return
    // false.
    Fragment null_fragment(null_entry);
    null_fragment += Constant(Bool::False());
    null_fragment += Return(dart_function.end_token_pos());

    body = Fragment(body.entry, non_null_entry);
  }
  return body;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionBody(
    const Function& dart_function,
    LocalVariable* first_parameter,
    bool constructor) {
  Fragment body;

  // TODO(27590): Currently the [VariableDeclaration]s from the
  // initializers will be visible inside the entire body of the constructor.
  // We should make a separate scope for them.
  if (constructor) {
    body += BuildInitializers(Class::Handle(Z, dart_function.Owner()));
  }

  if (body.is_closed()) return body;

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kBody);

  const bool has_body = ReadTag() == kSomething;  // read first part of body.

  if (dart_function.is_native()) {
    body += B->NativeFunctionBody(dart_function, first_parameter);
  } else if (has_body) {
    body += BuildStatement();
  }

  if (body.is_open()) {
    body += NullConstant();
    body += Return(dart_function.end_token_pos());
  }

  return body;
}

Fragment StreamingFlowGraphBuilder::BuildEveryTimePrologue(
    const Function& dart_function,
    TokenPosition token_position,
    intptr_t type_parameters_offset) {
  Fragment F;
  F += CheckStackOverflowInPrologue(dart_function);
  F += DebugStepCheckInPrologue(dart_function, token_position);
  F += SetAsyncStackTrace(dart_function);
  return F;
}

Fragment StreamingFlowGraphBuilder::BuildFirstTimePrologue(
    const Function& dart_function,
    LocalVariable* first_parameter,
    intptr_t type_parameters_offset) {
  Fragment F;
  F += SetupCapturedParameters(dart_function);
  F += ShortcutForUserDefinedEquals(dart_function, first_parameter);
  return F;
}

UncheckedEntryPointStyle StreamingFlowGraphBuilder::ChooseEntryPointStyle(
    const Function& dart_function,
    const Fragment& implicit_type_checks,
    const Fragment& first_time_prologue,
    const Fragment& every_time_prologue,
    const Fragment& type_args_handling) {
  ASSERT(!dart_function.IsImplicitClosureFunction());
  if (!dart_function.MayHaveUncheckedEntryPoint(I) ||
      implicit_type_checks.is_empty()) {
    return UncheckedEntryPointStyle::kNone;
  }

  // Record which entry-point was taken into a variable and test it later if
  // either:
  //
  // 1. There is a non-empty PrologueBuilder-prologue.
  //
  // 2. There is a non-empty "first-time" prologue.
  //
  // 3. The "every-time" prologue has more than two instructions (DebugStepCheck
  //    and CheckStackOverflow).
  //
  // TODO(#34162): For regular closures we can often avoid the
  // PrologueBuilder-prologue on non-dynamic invocations.
  if (!PrologueBuilder::HasEmptyPrologue(dart_function) ||
      !type_args_handling.is_empty() || !first_time_prologue.is_empty() ||
      !(every_time_prologue.entry == every_time_prologue.current ||
        every_time_prologue.current->previous() == every_time_prologue.entry)) {
    return UncheckedEntryPointStyle::kSharedWithVariable;
  }

  return UncheckedEntryPointStyle::kSeparate;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfFunction(
    bool is_constructor) {
  const Function& dart_function = parsed_function()->function();

  intptr_t type_parameters_offset = 0;
  LocalVariable* first_parameter = nullptr;
  TokenPosition token_position = TokenPosition::kNoSource;
  {
    AlternativeReadingScope alt(&reader_);
    FunctionNodeHelper function_node_helper(this);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kTypeParameters);
    type_parameters_offset = ReaderOffset();
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kPositionalParameters);
    intptr_t list_length = ReadListLength();  // read number of positionals.
    if (list_length > 0) {
      intptr_t first_parameter_offset = ReaderOffset() + data_program_offset_;
      first_parameter = LookupVariable(first_parameter_offset);
    }
    token_position = function_node_helper.position_;
  }

  auto graph_entry = flow_graph_builder_->graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function(), flow_graph_builder_->osr_id_);

  auto normal_entry = flow_graph_builder_->BuildFunctionEntry(graph_entry);
  graph_entry->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      flow_graph_builder_->BuildPrologue(normal_entry, &prologue_info);

  // The 'every_time_prologue' runs first and is run when resuming from yield
  // points.
  const Fragment every_time_prologue = BuildEveryTimePrologue(
      dart_function, token_position, type_parameters_offset);

  // The 'first_time_prologue' run after 'every_time_prologue' and is *not* run
  // when resuming from yield points.
  const Fragment first_time_prologue = BuildFirstTimePrologue(
      dart_function, first_parameter, type_parameters_offset);

  // TODO(#34162): We can remove the default type handling (and
  // shorten the prologue type handling sequence) for non-dynamic invocations of
  // regular methods.
  const Fragment type_args_handling = TypeArgumentsHandling(dart_function);

  Fragment explicit_type_checks;
  Fragment implicit_type_checks;
  Fragment implicit_redefinitions;
  CheckArgumentTypesAsNecessary(dart_function, type_parameters_offset,
                                &explicit_type_checks, &implicit_type_checks,
                                &implicit_redefinitions);

  const Fragment body =
      BuildFunctionBody(dart_function, first_parameter, is_constructor);

  auto extra_entry_point_style = ChooseEntryPointStyle(
      dart_function, implicit_type_checks, first_time_prologue,
      every_time_prologue, type_args_handling);

  Fragment function(instruction_cursor);
  if (yield_continuations().is_empty()) {
    FunctionEntryInstr* extra_entry = nullptr;
    switch (extra_entry_point_style) {
      case UncheckedEntryPointStyle::kNone: {
        function += every_time_prologue + first_time_prologue +
                    type_args_handling + implicit_type_checks +
                    explicit_type_checks + body;
        break;
      }
      case UncheckedEntryPointStyle::kSeparate: {
        ASSERT(instruction_cursor == normal_entry);
        ASSERT(first_time_prologue.is_empty());
        ASSERT(type_args_handling.is_empty());

        const Fragment prologue_copy = BuildEveryTimePrologue(
            dart_function, token_position, type_parameters_offset);

        extra_entry = B->BuildSeparateUncheckedEntryPoint(
            normal_entry,
            /*normal_prologue=*/every_time_prologue + implicit_type_checks,
            /*extra_prologue=*/prologue_copy,
            /*shared_prologue=*/explicit_type_checks,
            /*body=*/body);
        break;
      }
      case UncheckedEntryPointStyle::kSharedWithVariable: {
        Fragment prologue(normal_entry, instruction_cursor);
        prologue += every_time_prologue;
        prologue += first_time_prologue;
        prologue += type_args_handling;
        prologue += explicit_type_checks;
        extra_entry = B->BuildSharedUncheckedEntryPoint(
            /*shared_prologue_linked_in=*/prologue,
            /*skippable_checks=*/implicit_type_checks,
            /*redefinitions_if_skipped=*/implicit_redefinitions,
            /*body=*/body);
        break;
      }
    }
    if (extra_entry != nullptr) {
      B->RecordUncheckedEntryPoint(graph_entry, extra_entry);
    }
  } else {
    // If the function's body contains any yield points, build switch statement
    // that selects a continuation point based on the value of :await_jump_var.
    ASSERT(explicit_type_checks.is_empty());

    // If the function is generic, type_args_handling might require access to
    // (possibly captured) 'this' for preparing default type arguments, in which
    // case we can't run it before the 'first_time_prologue'.
    ASSERT(!dart_function.IsGeneric());

    // TODO(#34162): We can probably ignore the implicit checks
    // here as well since the arguments are passed from generated code.
    function += every_time_prologue + type_args_handling +
                CompleteBodyWithYieldContinuations(first_time_prologue +
                                                   implicit_type_checks + body);
  }

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (flow_graph_builder_->IsCompiledForOsr()) {
    graph_entry->RelinkToOsrEntry(Z,
                                  flow_graph_builder_->last_used_block_id_ + 1);
  }
  return new (Z)
      FlowGraph(*parsed_function(), graph_entry,
                flow_graph_builder_->last_used_block_id_, prologue_info);
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraph() {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  ASSERT(flow_graph_builder_ != nullptr);

  const Function& function = parsed_function()->function();

  // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass =
      Class::Handle(zone_, parsed_function()->function().Owner());
  Function& outermost_function =
      Function::Handle(Z, function.GetOutermostFunction());

  ActiveClassScope active_class_scope(active_class(), &klass);
  ActiveMemberScope active_member(active_class(), &outermost_function);
  ActiveTypeParametersScope active_type_params(active_class(), function, Z);

  if (function.is_declared_in_bytecode()) {
    if (!(FLAG_use_bytecode_compiler || FLAG_enable_interpreter)) {
      FATAL1(
          "Cannot run bytecode function %s: specify --enable-interpreter or "
          "--use-bytecode-compiler",
          function.ToFullyQualifiedCString());
    }

    bytecode_metadata_helper_.ParseBytecodeFunction(parsed_function());

    switch (function.kind()) {
      case RawFunction::kImplicitClosureFunction:
        return B->BuildGraphOfImplicitClosureFunction(function);
      case RawFunction::kImplicitGetter:
      case RawFunction::kImplicitSetter:
        return B->BuildGraphOfFieldAccessor(function);
      case RawFunction::kImplicitStaticGetter: {
        if (IsStaticFieldGetterGeneratedAsInitializer(function, Z)) {
          break;
        }
        return B->BuildGraphOfFieldAccessor(function);
      }
      case RawFunction::kDynamicInvocationForwarder:
        return B->BuildGraphOfDynamicInvocationForwarder(function);
      case RawFunction::kMethodExtractor:
        return B->BuildGraphOfMethodExtractor(function);
      case RawFunction::kNoSuchMethodDispatcher:
        return B->BuildGraphOfNoSuchMethodDispatcher(function);
      default:
        break;
    }

    ASSERT(function.HasBytecode());

    BytecodeFlowGraphBuilder bytecode_compiler(
        flow_graph_builder_, parsed_function(),
        &(flow_graph_builder_->ic_data_array_));

    if (B->IsRecognizedMethodForFlowGraph(function)) {
      bytecode_compiler.CreateParameterVariables();
      return B->BuildGraphOfRecognizedMethod(function);
    }

    return bytecode_compiler.BuildGraph();
  }

  // Certain special functions could have a VM-internal bytecode
  // attached to them.
  ASSERT((!function.HasBytecode()) ||
         (function.kind() == RawFunction::kImplicitGetter) ||
         (function.kind() == RawFunction::kImplicitSetter) ||
         (function.kind() == RawFunction::kImplicitStaticGetter) ||
         (function.kind() == RawFunction::kMethodExtractor) ||
         (function.kind() == RawFunction::kInvokeFieldDispatcher) ||
         (function.kind() == RawFunction::kNoSuchMethodDispatcher));

  ParseKernelASTFunction();

  switch (function.kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kConstructor: {
      if (B->IsRecognizedMethodForFlowGraph(function)) {
        return B->BuildGraphOfRecognizedMethod(function);
      }
      return BuildGraphOfFunction(function.IsGenerativeConstructor());
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticGetter:
    case RawFunction::kImplicitSetter: {
      const Field& field = Field::Handle(Z, function.accessor_field());
      if (field.is_const() && field.IsUninitialized()) {
        EvaluateConstFieldValue(field);
      }
      return B->BuildGraphOfFieldAccessor(function);
    }
    case RawFunction::kFieldInitializer:
      return BuildGraphOfFieldInitializer();
    case RawFunction::kDynamicInvocationForwarder:
      return B->BuildGraphOfDynamicInvocationForwarder(function);
    case RawFunction::kMethodExtractor:
      return flow_graph_builder_->BuildGraphOfMethodExtractor(function);
    case RawFunction::kNoSuchMethodDispatcher:
      return flow_graph_builder_->BuildGraphOfNoSuchMethodDispatcher(function);
    case RawFunction::kInvokeFieldDispatcher:
      return flow_graph_builder_->BuildGraphOfInvokeFieldDispatcher(function);
    case RawFunction::kImplicitClosureFunction:
      return flow_graph_builder_->BuildGraphOfImplicitClosureFunction(function);
    case RawFunction::kFfiTrampoline:
      return flow_graph_builder_->BuildGraphOfFfiTrampoline(function);
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      break;
  }
  UNREACHABLE();
  return NULL;
}

void StreamingFlowGraphBuilder::ParseKernelASTFunction() {
  const Function& function = parsed_function()->function();

  const intptr_t kernel_offset = function.kernel_offset();
  ASSERT(kernel_offset >= 0);

  SetOffset(kernel_offset);

  // Mark forwarding stubs.
  switch (function.kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kImplicitClosureFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kConstructor:
    case RawFunction::kDynamicInvocationForwarder:
      ReadForwardingStubTarget(function);
      break;
    default:
      break;
  }

  set_scopes(parsed_function()->EnsureKernelScopes());

  switch (function.kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kConstructor:
    case RawFunction::kImplicitClosureFunction:
      ReadUntilFunctionNode();
      SetupDefaultParameterValues();
      ReadDefaultFunctionTypeArguments(function);
      break;
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticGetter:
    case RawFunction::kImplicitSetter:
    case RawFunction::kFieldInitializer:
    case RawFunction::kMethodExtractor:
    case RawFunction::kNoSuchMethodDispatcher:
    case RawFunction::kInvokeFieldDispatcher:
    case RawFunction::kFfiTrampoline:
      break;
    case RawFunction::kDynamicInvocationForwarder:
      if (PeekTag() != kField) {
        ReadUntilFunctionNode();
        SetupDefaultParameterValues();
        ReadDefaultFunctionTypeArguments(function);
      }
      break;
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      UNREACHABLE();
      break;
  }
}

void StreamingFlowGraphBuilder::ReadForwardingStubTarget(
    const Function& function) {
  if (PeekTag() == kProcedure) {
    AlternativeReadingScope alt(&reader_);
    ProcedureHelper procedure_helper(this);
    procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
    if (procedure_helper.IsForwardingStub() && !procedure_helper.IsAbstract()) {
      const NameIndex target_name =
          procedure_helper.forwarding_stub_super_target_;
      ASSERT(target_name != NameIndex::kInvalidName);
      const String& name = function.IsSetterFunction()
                               ? H.DartSetterName(target_name)
                               : H.DartProcedureName(target_name);
      const Function* forwarding_target =
          &Function::ZoneHandle(Z, H.LookupMethodByMember(target_name, name));
      ASSERT(!forwarding_target->IsNull());
      parsed_function()->MarkForwardingStub(forwarding_target);
    }
  }
}

Fragment StreamingFlowGraphBuilder::BuildStatementAt(intptr_t kernel_offset) {
  SetOffset(kernel_offset);
  return BuildStatement();  // read statement.
}

Fragment StreamingFlowGraphBuilder::BuildExpression(TokenPosition* position) {
  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);  // read tag.
  switch (tag) {
    case kInvalidExpression:
      return BuildInvalidExpression(position);
    case kVariableGet:
      return BuildVariableGet(position);
    case kSpecializedVariableGet:
      return BuildVariableGet(payload, position);
    case kVariableSet:
      return BuildVariableSet(position);
    case kSpecializedVariableSet:
      return BuildVariableSet(payload, position);
    case kPropertyGet:
      return BuildPropertyGet(position);
    case kPropertySet:
      return BuildPropertySet(position);
    case kDirectPropertyGet:
      return BuildDirectPropertyGet(position);
    case kDirectPropertySet:
      return BuildDirectPropertySet(position);
    case kSuperPropertyGet:
      return BuildSuperPropertyGet(position);
    case kSuperPropertySet:
      return BuildSuperPropertySet(position);
    case kStaticGet:
      return BuildStaticGet(position);
    case kStaticSet:
      return BuildStaticSet(position);
    case kMethodInvocation:
      return BuildMethodInvocation(position);
    case kSuperMethodInvocation:
      return BuildSuperMethodInvocation(position);
    case kDirectMethodInvocation:
      return BuildDirectMethodInvocation(position);
    case kStaticInvocation:
      return BuildStaticInvocation(false, position);
    case kConstStaticInvocation:
      return BuildStaticInvocation(true, position);
    case kConstructorInvocation:
      return BuildConstructorInvocation(false, position);
    case kConstConstructorInvocation:
      return BuildConstructorInvocation(true, position);
    case kNot:
      return BuildNot(position);
    case kNullCheck:
      return BuildNullCheck(position);
    case kLogicalExpression:
      return BuildLogicalExpression(position);
    case kConditionalExpression:
      return BuildConditionalExpression(position);
    case kStringConcatenation:
      return BuildStringConcatenation(position);
    case kListConcatenation:
    case kSetConcatenation:
    case kMapConcatenation:
    case kInstanceCreation:
    case kFileUriExpression:
      // Collection concatenation, instance creation operations and
      // in-expression URI changes are removed by the constant evaluator.
      UNREACHABLE();
      break;
    case kIsExpression:
      return BuildIsExpression(position);
    case kAsExpression:
      return BuildAsExpression(position);
    case kSymbolLiteral:
      return BuildSymbolLiteral(position);
    case kTypeLiteral:
      return BuildTypeLiteral(position);
    case kThisExpression:
      return BuildThisExpression(position);
    case kRethrow:
      return BuildRethrow(position);
    case kThrow:
      return BuildThrow(position);
    case kListLiteral:
      return BuildListLiteral(false, position);
    case kConstListLiteral:
      return BuildListLiteral(true, position);
    case kSetLiteral:
    case kConstSetLiteral:
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      break;
    case kMapLiteral:
      return BuildMapLiteral(false, position);
    case kConstMapLiteral:
      return BuildMapLiteral(true, position);
    case kFunctionExpression:
      return BuildFunctionExpression();
    case kLet:
      return BuildLet(position);
    case kBlockExpression:
      return BuildBlockExpression();
    case kBigIntLiteral:
      return BuildBigIntLiteral(position);
    case kStringLiteral:
      return BuildStringLiteral(position);
    case kSpecializedIntLiteral:
      return BuildIntLiteral(payload, position);
    case kNegativeIntLiteral:
      return BuildIntLiteral(true, position);
    case kPositiveIntLiteral:
      return BuildIntLiteral(false, position);
    case kDoubleLiteral:
      return BuildDoubleLiteral(position);
    case kTrueLiteral:
      return BuildBoolLiteral(true, position);
    case kFalseLiteral:
      return BuildBoolLiteral(false, position);
    case kNullLiteral:
      return BuildNullLiteral(position);
    case kConstantExpression:
      return BuildConstantExpression(position, tag);
    case kDeprecated_ConstantExpression:
      return BuildConstantExpression(position, tag);
    case kInstantiation:
      return BuildPartialTearoffInstantiation(position);
    case kLoadLibrary:
    case kCheckLibraryIsLoaded:
      ReadUInt();  // skip library index
      return BuildFutureNullValue(position);
    default:
      ReportUnexpectedTag("expression", tag);
      UNREACHABLE();
  }

  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStatement() {
  Tag tag = ReadTag();  // read tag.
  switch (tag) {
    case kExpressionStatement:
      return BuildExpressionStatement();
    case kBlock:
      return BuildBlock();
    case kEmptyStatement:
      return BuildEmptyStatement();
    case kAssertBlock:
      return BuildAssertBlock();
    case kAssertStatement:
      return BuildAssertStatement();
    case kLabeledStatement:
      return BuildLabeledStatement();
    case kBreakStatement:
      return BuildBreakStatement();
    case kWhileStatement:
      return BuildWhileStatement();
    case kDoStatement:
      return BuildDoStatement();
    case kForStatement:
      return BuildForStatement();
    case kForInStatement:
      return BuildForInStatement(false);
    case kAsyncForInStatement:
      return BuildForInStatement(true);
    case kSwitchStatement:
      return BuildSwitchStatement();
    case kContinueSwitchStatement:
      return BuildContinueSwitchStatement();
    case kIfStatement:
      return BuildIfStatement();
    case kReturnStatement:
      return BuildReturnStatement();
    case kTryCatch:
      return BuildTryCatch();
    case kTryFinally:
      return BuildTryFinally();
    case kYieldStatement:
      return BuildYieldStatement();
    case kVariableDeclaration:
      return BuildVariableDeclaration();
    case kFunctionDeclaration:
      return BuildFunctionDeclaration();
    default:
      ReportUnexpectedTag("statement", tag);
      UNREACHABLE();
  }
  return Fragment();
}

void StreamingFlowGraphBuilder::ReportUnexpectedTag(const char* variant,
                                                    Tag tag) {
  if ((flow_graph_builder_ == NULL) || (parsed_function() == NULL)) {
    KernelReaderHelper::ReportUnexpectedTag(variant, tag);
  } else {
    H.ReportError(script_, TokenPosition::kNoSource,
                  "Unexpected tag %d (%s) in %s, expected %s", tag,
                  Reader::TagName(tag),
                  parsed_function()->function().ToQualifiedCString(), variant);
  }
}

Tag KernelReaderHelper::ReadTag(uint8_t* payload) {
  return reader_.ReadTag(payload);
}

Tag KernelReaderHelper::PeekTag(uint8_t* payload) {
  return reader_.PeekTag(payload);
}

Nullability KernelReaderHelper::ReadNullability() {
  if (translation_helper_.info().kernel_binary_version() >= 28) {
    return reader_.ReadNullability();
  }
  return kLegacy;
}

Variance KernelReaderHelper::ReadVariance() {
  if (translation_helper_.info().kernel_binary_version() >= 34) {
    return reader_.ReadVariance();
  }
  return kCovariant;
}

void StreamingFlowGraphBuilder::loop_depth_inc() {
  ++flow_graph_builder_->loop_depth_;
}

void StreamingFlowGraphBuilder::loop_depth_dec() {
  --flow_graph_builder_->loop_depth_;
}

intptr_t StreamingFlowGraphBuilder::for_in_depth() {
  return flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::for_in_depth_inc() {
  ++flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::for_in_depth_dec() {
  --flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::catch_depth_inc() {
  ++flow_graph_builder_->catch_depth_;
}

void StreamingFlowGraphBuilder::catch_depth_dec() {
  --flow_graph_builder_->catch_depth_;
}

void StreamingFlowGraphBuilder::try_depth_inc() {
  ++flow_graph_builder_->try_depth_;
}

void StreamingFlowGraphBuilder::try_depth_dec() {
  --flow_graph_builder_->try_depth_;
}

intptr_t StreamingFlowGraphBuilder::block_expression_depth() {
  return flow_graph_builder_->block_expression_depth_;
}

void StreamingFlowGraphBuilder::block_expression_depth_inc() {
  ++flow_graph_builder_->block_expression_depth_;
}

void StreamingFlowGraphBuilder::block_expression_depth_dec() {
  --flow_graph_builder_->block_expression_depth_;
}

intptr_t StreamingFlowGraphBuilder::CurrentTryIndex() {
  return flow_graph_builder_->CurrentTryIndex();
}

intptr_t StreamingFlowGraphBuilder::AllocateTryIndex() {
  return flow_graph_builder_->AllocateTryIndex();
}

LocalVariable* StreamingFlowGraphBuilder::CurrentException() {
  return flow_graph_builder_->CurrentException();
}

LocalVariable* StreamingFlowGraphBuilder::CurrentStackTrace() {
  return flow_graph_builder_->CurrentStackTrace();
}

CatchBlock* StreamingFlowGraphBuilder::catch_block() {
  return flow_graph_builder_->catch_block_;
}

ActiveClass* StreamingFlowGraphBuilder::active_class() {
  return active_class_;
}

ScopeBuildingResult* StreamingFlowGraphBuilder::scopes() {
  return flow_graph_builder_->scopes_;
}

void StreamingFlowGraphBuilder::set_scopes(ScopeBuildingResult* scope) {
  flow_graph_builder_->scopes_ = scope;
}

ParsedFunction* StreamingFlowGraphBuilder::parsed_function() {
  return flow_graph_builder_->parsed_function_;
}

TryFinallyBlock* StreamingFlowGraphBuilder::try_finally_block() {
  return flow_graph_builder_->try_finally_block_;
}

SwitchBlock* StreamingFlowGraphBuilder::switch_block() {
  return flow_graph_builder_->switch_block_;
}

BreakableBlock* StreamingFlowGraphBuilder::breakable_block() {
  return flow_graph_builder_->breakable_block_;
}

GrowableArray<YieldContinuation>&
StreamingFlowGraphBuilder::yield_continuations() {
  return flow_graph_builder_->yield_continuations_;
}

Value* StreamingFlowGraphBuilder::stack() {
  return flow_graph_builder_->stack_;
}

void StreamingFlowGraphBuilder::Push(Definition* definition) {
  flow_graph_builder_->Push(definition);
}

Value* StreamingFlowGraphBuilder::Pop() {
  return flow_graph_builder_->Pop();
}

Tag StreamingFlowGraphBuilder::PeekArgumentsFirstPositionalTag() {
  // read parts of arguments, then go back to before doing so.
  AlternativeReadingScope alt(&reader_);
  ReadUInt();  // read number of arguments.

  SkipListOfDartTypes();  // Read list of types.

  // List of positional.
  intptr_t list_length = ReadListLength();  // read list length.
  if (list_length > 0) {
    return ReadTag();  // read first tag.
  }

  UNREACHABLE();
  return kNothing;
}

const TypeArguments& StreamingFlowGraphBuilder::PeekArgumentsInstantiatedType(
    const Class& klass) {
  // read parts of arguments, then go back to before doing so.
  AlternativeReadingScope alt(&reader_);
  ReadUInt();                               // read argument count.
  intptr_t list_length = ReadListLength();  // read types list length.
  return T.BuildInstantiatedTypeArguments(klass, list_length);  // read types.
}

intptr_t StreamingFlowGraphBuilder::PeekArgumentsCount() {
  return PeekUInt();
}

LocalVariable* StreamingFlowGraphBuilder::LookupVariable(
    intptr_t kernel_offset) {
  return flow_graph_builder_->LookupVariable(kernel_offset);
}

LocalVariable* StreamingFlowGraphBuilder::MakeTemporary() {
  return flow_graph_builder_->MakeTemporary();
}

Function& StreamingFlowGraphBuilder::FindMatchingFunction(
    const Class& klass,
    const String& name,
    int type_args_len,
    int argument_count,
    const Array& argument_names) {
  // Search the superclass chain for the selector.
  Function& function = Function::Handle(Z);
  Class& iterate_klass = Class::Handle(Z, klass.raw());
  while (!iterate_klass.IsNull()) {
    function = iterate_klass.LookupDynamicFunctionAllowPrivate(name);
    if (!function.IsNull()) {
      if (function.AreValidArguments(type_args_len, argument_count,
                                     argument_names,
                                     /* error_message = */ NULL)) {
        return function;
      }
    }
    iterate_klass = iterate_klass.SuperClass();
  }
  return Function::Handle();
}

bool StreamingFlowGraphBuilder::NeedsDebugStepCheck(const Function& function,
                                                    TokenPosition position) {
  return flow_graph_builder_->NeedsDebugStepCheck(function, position);
}

bool StreamingFlowGraphBuilder::NeedsDebugStepCheck(Value* value,
                                                    TokenPosition position) {
  return flow_graph_builder_->NeedsDebugStepCheck(value, position);
}

void StreamingFlowGraphBuilder::InlineBailout(const char* reason) {
  flow_graph_builder_->InlineBailout(reason);
}

Fragment StreamingFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
  return flow_graph_builder_->DebugStepCheck(position);
}

Fragment StreamingFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  return flow_graph_builder_->LoadLocal(variable);
}

Fragment StreamingFlowGraphBuilder::Return(TokenPosition position) {
  return flow_graph_builder_->Return(position);
}

Fragment StreamingFlowGraphBuilder::PushArgument() {
  return flow_graph_builder_->PushArgument();
}

Fragment StreamingFlowGraphBuilder::EvaluateAssertion() {
  return flow_graph_builder_->EvaluateAssertion();
}

Fragment StreamingFlowGraphBuilder::RethrowException(TokenPosition position,
                                                     int catch_try_index) {
  return flow_graph_builder_->RethrowException(position, catch_try_index);
}

Fragment StreamingFlowGraphBuilder::ThrowNoSuchMethodError() {
  return flow_graph_builder_->ThrowNoSuchMethodError();
}

Fragment StreamingFlowGraphBuilder::Constant(const Object& value) {
  return flow_graph_builder_->Constant(value);
}

Fragment StreamingFlowGraphBuilder::IntConstant(int64_t value) {
  return flow_graph_builder_->IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::LoadStaticField() {
  return flow_graph_builder_->LoadStaticField();
}

Fragment StreamingFlowGraphBuilder::RedefinitionWithType(
    const AbstractType& type) {
  return flow_graph_builder_->RedefinitionWithType(type);
}

Fragment StreamingFlowGraphBuilder::CheckNull(
    TokenPosition position,
    LocalVariable* receiver,
    const String& function_name,
    bool clear_the_temp /* = true */) {
  return flow_graph_builder_->CheckNull(position, receiver, function_name,
                                        clear_the_temp);
}

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count,
                                               ICData::RebindRule rebind_rule) {
  return flow_graph_builder_->StaticCall(position, target, argument_count,
                                         rebind_rule);
}

Fragment StreamingFlowGraphBuilder::StaticCall(
    TokenPosition position,
    const Function& target,
    intptr_t argument_count,
    const Array& argument_names,
    ICData::RebindRule rebind_rule,
    const InferredTypeMetadata* result_type,
    intptr_t type_args_count,
    bool use_unchecked_entry) {
  return flow_graph_builder_->StaticCall(
      position, target, argument_count, argument_names, rebind_rule,
      result_type, type_args_count, use_unchecked_entry);
}

Fragment StreamingFlowGraphBuilder::InstanceCall(
    TokenPosition position,
    const String& name,
    Token::Kind kind,
    intptr_t argument_count,
    intptr_t checked_argument_count) {
  const intptr_t kTypeArgsLen = 0;
  return flow_graph_builder_->InstanceCall(
      position, name, kind, kTypeArgsLen, argument_count, Array::null_array(),
      checked_argument_count, Function::null_function());
}

Fragment StreamingFlowGraphBuilder::InstanceCall(
    TokenPosition position,
    const String& name,
    Token::Kind kind,
    intptr_t type_args_len,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t checked_argument_count,
    const Function& interface_target,
    const InferredTypeMetadata* result_type,
    bool use_unchecked_entry,
    const CallSiteAttributesMetadata* call_site_attrs) {
  return flow_graph_builder_->InstanceCall(
      position, name, kind, type_args_len, argument_count, argument_names,
      checked_argument_count, interface_target, result_type,
      use_unchecked_entry, call_site_attrs);
}

Fragment StreamingFlowGraphBuilder::ThrowException(TokenPosition position) {
  return flow_graph_builder_->ThrowException(position);
}

Fragment StreamingFlowGraphBuilder::BooleanNegate() {
  return flow_graph_builder_->BooleanNegate();
}

Fragment StreamingFlowGraphBuilder::TranslateInstantiatedTypeArguments(
    const TypeArguments& type_arguments) {
  return flow_graph_builder_->TranslateInstantiatedTypeArguments(
      type_arguments);
}

Fragment StreamingFlowGraphBuilder::StrictCompare(TokenPosition position,
                                                  Token::Kind kind,
                                                  bool number_check) {
  return flow_graph_builder_->StrictCompare(position, kind, number_check);
}

Fragment StreamingFlowGraphBuilder::AllocateObject(TokenPosition position,
                                                   const Class& klass,
                                                   intptr_t argument_count) {
  return flow_graph_builder_->AllocateObject(position, klass, argument_count);
}

Fragment StreamingFlowGraphBuilder::AllocateContext(
    const ZoneGrowableArray<const Slot*>& context_slots) {
  return flow_graph_builder_->AllocateContext(context_slots);
}

Fragment StreamingFlowGraphBuilder::LoadNativeField(const Slot& field) {
  return flow_graph_builder_->LoadNativeField(field);
}

Fragment StreamingFlowGraphBuilder::StoreLocal(TokenPosition position,
                                               LocalVariable* variable) {
  return flow_graph_builder_->StoreLocal(position, variable);
}

Fragment StreamingFlowGraphBuilder::StoreStaticField(TokenPosition position,
                                                     const Field& field) {
  return flow_graph_builder_->StoreStaticField(position, field);
}

Fragment StreamingFlowGraphBuilder::StringInterpolate(TokenPosition position) {
  return flow_graph_builder_->StringInterpolate(position);
}

Fragment StreamingFlowGraphBuilder::StringInterpolateSingle(
    TokenPosition position) {
  return flow_graph_builder_->StringInterpolateSingle(position);
}

Fragment StreamingFlowGraphBuilder::ThrowTypeError() {
  return flow_graph_builder_->ThrowTypeError();
}

Fragment StreamingFlowGraphBuilder::LoadInstantiatorTypeArguments() {
  return flow_graph_builder_->LoadInstantiatorTypeArguments();
}

Fragment StreamingFlowGraphBuilder::LoadFunctionTypeArguments() {
  return flow_graph_builder_->LoadFunctionTypeArguments();
}

Fragment StreamingFlowGraphBuilder::InstantiateType(const AbstractType& type) {
  return flow_graph_builder_->InstantiateType(type);
}

Fragment StreamingFlowGraphBuilder::CreateArray() {
  return flow_graph_builder_->CreateArray();
}

Fragment StreamingFlowGraphBuilder::StoreIndexed(intptr_t class_id) {
  return flow_graph_builder_->StoreIndexed(class_id);
}

Fragment StreamingFlowGraphBuilder::CheckStackOverflow(TokenPosition position) {
  return flow_graph_builder_->CheckStackOverflow(
      position, flow_graph_builder_->GetStackDepth(),
      flow_graph_builder_->loop_depth_);
}

Fragment StreamingFlowGraphBuilder::CloneContext(
    const ZoneGrowableArray<const Slot*>& context_slots) {
  return flow_graph_builder_->CloneContext(context_slots);
}

Fragment StreamingFlowGraphBuilder::TranslateFinallyFinalizers(
    TryFinallyBlock* outer_finally,
    intptr_t target_context_depth) {
  // TranslateFinallyFinalizers can move the readers offset.
  // Save the current position and restore it afterwards.
  AlternativeReadingScope alt(&reader_);

  // Save context.
  TryFinallyBlock* const saved_finally_block = B->try_finally_block_;
  TryCatchBlock* const saved_try_catch_block = B->CurrentTryCatchBlock();
  const intptr_t saved_context_depth = B->context_depth_;
  const ProgramState state(B->breakable_block_, B->switch_block_,
                           B->loop_depth_, B->for_in_depth_, B->try_depth_,
                           B->catch_depth_, B->block_expression_depth_);

  Fragment instructions;

  // While translating the body of a finalizer we need to set the try-finally
  // block which is active when translating the body.
  while (B->try_finally_block_ != outer_finally) {
    ASSERT(B->try_finally_block_ != nullptr);
    // Adjust program context to finalizer's position.
    B->try_finally_block_->state().assignTo(B);

    // Potentially restore the context to what is expected for the finally
    // block.
    instructions += B->AdjustContextTo(B->try_finally_block_->context_depth());

    // The to-be-translated finalizer has to have the correct try-index (namely
    // the one outside the try-finally block).
    bool changed_try_index = false;
    intptr_t target_try_index = B->try_finally_block_->try_index();
    while (B->CurrentTryIndex() != target_try_index) {
      B->SetCurrentTryCatchBlock(B->CurrentTryCatchBlock()->outer());
      changed_try_index = true;
    }
    if (changed_try_index) {
      JoinEntryInstr* entry = BuildJoinEntry();
      instructions += Goto(entry);
      instructions = Fragment(instructions.entry, entry);
    }

    intptr_t finalizer_kernel_offset =
        B->try_finally_block_->finalizer_kernel_offset();
    B->try_finally_block_ = B->try_finally_block_->outer();
    instructions += BuildStatementAt(finalizer_kernel_offset);

    // We only need to make sure that if the finalizer ended normally, we
    // continue towards the next outer try-finally.
    if (!instructions.is_open()) break;
  }

  if (instructions.is_open() && target_context_depth != -1) {
    // A target context depth of -1 indicates that the code after this
    // will not care about the context chain so we can leave it any way we
    // want after the last finalizer.  That is used when returning.
    instructions += B->AdjustContextTo(target_context_depth);
  }

  // Restore.
  B->try_finally_block_ = saved_finally_block;
  B->SetCurrentTryCatchBlock(saved_try_catch_block);
  B->context_depth_ = saved_context_depth;
  state.assignTo(B);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BranchIfTrue(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfTrue(then_entry, otherwise_entry, negate);
}

Fragment StreamingFlowGraphBuilder::BranchIfEqual(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfEqual(then_entry, otherwise_entry,
                                            negate);
}

Fragment StreamingFlowGraphBuilder::BranchIfNull(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfNull(then_entry, otherwise_entry, negate);
}

Fragment StreamingFlowGraphBuilder::CatchBlockEntry(const Array& handler_types,
                                                    intptr_t handler_index,
                                                    bool needs_stacktrace,
                                                    bool is_synthesized) {
  return flow_graph_builder_->CatchBlockEntry(handler_types, handler_index,
                                              needs_stacktrace, is_synthesized);
}

Fragment StreamingFlowGraphBuilder::TryCatch(int try_handler_index) {
  return flow_graph_builder_->TryCatch(try_handler_index);
}

Fragment StreamingFlowGraphBuilder::Drop() {
  return flow_graph_builder_->Drop();
}

Fragment StreamingFlowGraphBuilder::DropTempsPreserveTop(
    intptr_t num_temps_to_drop) {
  return flow_graph_builder_->DropTempsPreserveTop(num_temps_to_drop);
}

Fragment StreamingFlowGraphBuilder::MakeTemp() {
  return flow_graph_builder_->MakeTemp();
}

Fragment StreamingFlowGraphBuilder::NullConstant() {
  return flow_graph_builder_->NullConstant();
}

JoinEntryInstr* StreamingFlowGraphBuilder::BuildJoinEntry() {
  return flow_graph_builder_->BuildJoinEntry();
}

JoinEntryInstr* StreamingFlowGraphBuilder::BuildJoinEntry(intptr_t try_index) {
  return flow_graph_builder_->BuildJoinEntry(try_index);
}

Fragment StreamingFlowGraphBuilder::Goto(JoinEntryInstr* destination) {
  return flow_graph_builder_->Goto(destination);
}

Fragment StreamingFlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  return flow_graph_builder_->BuildImplicitClosureCreation(target);
}

Fragment StreamingFlowGraphBuilder::CheckBoolean(TokenPosition position) {
  return flow_graph_builder_->CheckBoolean(position);
}

Fragment StreamingFlowGraphBuilder::CheckArgumentType(
    LocalVariable* variable,
    const AbstractType& type) {
  return flow_graph_builder_->CheckAssignable(
      type, variable->name(), AssertAssignableInstr::kParameterCheck);
}

Fragment StreamingFlowGraphBuilder::CheckTypeArgumentBound(
    const AbstractType& parameter,
    const AbstractType& bound,
    const String& dst_name) {
  return flow_graph_builder_->AssertSubtype(TokenPosition::kNoSource, parameter,
                                            bound, dst_name);
}

Fragment StreamingFlowGraphBuilder::EnterScope(
    intptr_t kernel_offset,
    const LocalScope** scope /* = nullptr */) {
  return flow_graph_builder_->EnterScope(kernel_offset, scope);
}

Fragment StreamingFlowGraphBuilder::ExitScope(intptr_t kernel_offset) {
  return flow_graph_builder_->ExitScope(kernel_offset);
}

TestFragment StreamingFlowGraphBuilder::TranslateConditionForControl() {
  // Skip all negations and go directly to the expression.
  bool negate = false;
  while (PeekTag() == kNot) {
    SkipBytes(1);
    negate = !negate;
  }

  TestFragment result;
  if (PeekTag() == kLogicalExpression) {
    // Handle '&&' and '||' operators specially to implement short circuit
    // evaluation.
    SkipBytes(1);  // tag.

    TestFragment left = TranslateConditionForControl();
    LogicalOperator op = static_cast<LogicalOperator>(ReadByte());
    TestFragment right = TranslateConditionForControl();

    result.entry = left.entry;
    if (op == kAnd) {
      left.CreateTrueSuccessor(flow_graph_builder_)->LinkTo(right.entry);
      result.true_successor_addresses = right.true_successor_addresses;
      result.false_successor_addresses = left.false_successor_addresses;
      result.false_successor_addresses->AddArray(
          *right.false_successor_addresses);
    } else {
      ASSERT(op == kOr);
      left.CreateFalseSuccessor(flow_graph_builder_)->LinkTo(right.entry);
      result.true_successor_addresses = left.true_successor_addresses;
      result.true_successor_addresses->AddArray(
          *right.true_successor_addresses);
      result.false_successor_addresses = right.false_successor_addresses;
    }
  } else {
    // Other expressions.
    TokenPosition position = TokenPosition::kNoSource;
    Fragment instructions = BuildExpression(&position);  // read expression.

    // Check if the top of the stack is already a StrictCompare that
    // can be merged with a branch. Otherwise compare TOS with
    // true value and branch on that.
    BranchInstr* branch;
    if (stack()->definition()->IsStrictCompare() &&
        stack()->definition() == instructions.current) {
      StrictCompareInstr* compare = Pop()->definition()->AsStrictCompare();
      if (negate) {
        compare->NegateComparison();
        negate = false;
      }
      branch =
          new (Z) BranchInstr(compare, flow_graph_builder_->GetNextDeoptId());
      branch->comparison()->ClearTempIndex();
      ASSERT(instructions.current->previous() != nullptr);
      instructions.current = instructions.current->previous();
    } else {
      instructions += CheckBoolean(position);
      instructions += Constant(Bool::True());
      Value* right_value = Pop();
      Value* left_value = Pop();
      StrictCompareInstr* compare = new (Z) StrictCompareInstr(
          TokenPosition::kNoSource,
          negate ? Token::kNE_STRICT : Token::kEQ_STRICT, left_value,
          right_value, false, flow_graph_builder_->GetNextDeoptId());
      branch =
          new (Z) BranchInstr(compare, flow_graph_builder_->GetNextDeoptId());
      negate = false;
    }
    instructions <<= branch;

    result = TestFragment(instructions.entry, branch);
  }

  return result.Negate(negate);
}

const TypeArguments& StreamingFlowGraphBuilder::BuildTypeArguments() {
  ReadUInt();                               // read arguments count.
  intptr_t type_count = ReadListLength();   // read type count.
  return T.BuildTypeArguments(type_count);  // read types.
}

Fragment StreamingFlowGraphBuilder::BuildArguments(Array* argument_names,
                                                   intptr_t* argument_count,
                                                   intptr_t* positional_count,
                                                   bool skip_push_arguments,
                                                   bool do_drop) {
  intptr_t dummy;
  if (argument_count == NULL) argument_count = &dummy;
  *argument_count = ReadUInt();  // read arguments count.

  // List of types.
  SkipListOfDartTypes();  // read list of types.

  {
    AlternativeReadingScope _(&reader_);
    if (positional_count == NULL) positional_count = &dummy;
    *positional_count = ReadListLength();  // read length of expression list
  }
  return BuildArgumentsFromActualArguments(argument_names, skip_push_arguments,
                                           do_drop);
}

Fragment StreamingFlowGraphBuilder::BuildArgumentsFromActualArguments(
    Array* argument_names,
    bool skip_push_arguments,
    bool do_drop) {
  Fragment instructions;

  // List of positional.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    instructions += BuildExpression();  // read ith expression.
    if (!skip_push_arguments) instructions += PushArgument();
    if (do_drop) instructions += Drop();
  }

  // List of named.
  list_length = ReadListLength();  // read list length.
  if (argument_names != NULL && list_length > 0) {
    *argument_names = Array::New(list_length, Heap::kOld);
  }
  for (intptr_t i = 0; i < list_length; ++i) {
    String& name =
        H.DartSymbolObfuscate(ReadStringReference());  // read ith name index.
    instructions += BuildExpression();                 // read ith expression.
    if (!skip_push_arguments) instructions += PushArgument();
    if (do_drop) instructions += Drop();
    if (argument_names != NULL) {
      argument_names->SetAt(i, name);
    }
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInvalidExpression(
    TokenPosition* position) {
  // The frontend will take care of emitting normal errors (like
  // [NoSuchMethodError]s) and only emit [InvalidExpression]s in very special
  // situations (e.g. an invalid annotation).
  TokenPosition pos = ReadPosition();
  if (position != NULL) *position = pos;
  const String& message = H.DartString(ReadStringReference());
  // Invalid expression message has pointer to the source code, no need to
  // report it twice.
  H.ReportError(script(), TokenPosition::kNoSource, "%s", message.ToCString());
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(TokenPosition* position) {
  (position != NULL) ? * position = ReadPosition() : ReadPosition();
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();              // read relative variable index.
  SkipOptionalDartType();  // read promoted type.
  return LoadLocal(LookupVariable(variable_kernel_position));
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(uint8_t payload,
                                                     TokenPosition* position) {
  (position != NULL) ? * position = ReadPosition() : ReadPosition();
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  return LoadLocal(LookupVariable(variable_kernel_position));
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();                                 // read relative variable index.
  Fragment instructions = BuildExpression();  // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions +=
      StoreLocal(position, LookupVariable(variable_kernel_position));
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(uint8_t payload,
                                                     TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  Fragment instructions = BuildExpression();       // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions +=
      StoreLocal(position, LookupVariable(variable_kernel_position));

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildPropertyGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertyGet(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Fragment instructions = BuildExpression();  // read receiver.

  LocalVariable* receiver = NULL;
  if (direct_call.check_receiver_for_null_) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver = MakeTemporary();
    instructions += LoadLocal(receiver);
  }

  instructions += PushArgument();

  const String& getter_name = ReadNameAsGetterName();  // read name.

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (!H.IsRoot(itarget_name) &&
      (H.IsGetter(itarget_name) || H.IsField(itarget_name))) {
    interface_target = &Function::ZoneHandle(
        Z,
        H.LookupMethodByMember(itarget_name, H.DartGetterName(itarget_name)));
    ASSERT(getter_name.raw() == interface_target->name());
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver, getter_name);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, direct_call.target_, 1, Array::null_array(),
                   ICData::kNoRebind, &result_type);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions += InstanceCall(
        position, getter_name, Token::kGET, kTypeArgsLen, 1,
        Array::null_array(), kNumArgsChecked, *interface_target, &result_type);
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += DropTempsPreserveTop(1);  // Drop receiver, preserve result.
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildPropertySet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertySet(offset);
  const CallSiteAttributesMetadata call_site_attributes =
      call_site_attributes_metadata_helper_.GetCallSiteAttributes(offset);
  const InferredTypeMetadata inferred_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  // True if callee can skip argument type checks.
  bool is_unchecked_call = inferred_type.IsSkipCheck();
#ifndef TARGET_ARCH_DBC
  if (call_site_attributes.receiver_type != nullptr &&
      call_site_attributes.receiver_type->HasTypeClass() &&
      !Class::Handle(call_site_attributes.receiver_type->type_class())
           .IsGeneric()) {
    is_unchecked_call = true;
  }
#endif

  Fragment instructions(MakeTemp());
  LocalVariable* variable = MakeTemporary();

  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  if (PeekTag() == kThisExpression) {
    is_unchecked_call = true;
  }
  instructions += BuildExpression();  // read receiver.

  LocalVariable* receiver = nullptr;
  if (direct_call.check_receiver_for_null_) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver = MakeTemporary();
    instructions += LoadLocal(receiver);
  }

  instructions += PushArgument();

  const String& setter_name = ReadNameAsSetterName();  // read name.

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, variable);
  instructions += PushArgument();

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (!H.IsRoot(itarget_name)) {
    interface_target = &Function::ZoneHandle(
        Z,
        H.LookupMethodByMember(itarget_name, H.DartSetterName(itarget_name)));
    ASSERT(setter_name.raw() == interface_target->name());
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver, setter_name);
  }

  const String* mangled_name = &setter_name;
  const Function* direct_call_target = &direct_call.target_;
  if (I->should_emit_strong_mode_checks() && H.IsRoot(itarget_name)) {
    mangled_name = &String::ZoneHandle(
        Z, Function::CreateDynamicInvocationForwarderName(setter_name));
    if (!direct_call_target->IsNull()) {
      direct_call_target = &Function::ZoneHandle(
          direct_call.target_.GetDynamicInvocationForwarder(*mangled_name));
    }
  }

  if (!direct_call_target->IsNull()) {
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, *direct_call_target, 2, Array::null_array(),
                   ICData::kNoRebind, /*result_type=*/nullptr,
                   /*type_args_count=*/0,
                   /*use_unchecked_entry=*/is_unchecked_call);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;

    instructions += InstanceCall(
        position, *mangled_name, Token::kSET, kTypeArgsLen, 2,
        Array::null_array(), kNumArgsChecked, *interface_target,
        /*result_type=*/nullptr,
        /*use_unchecked_entry=*/is_unchecked_call, &call_site_attributes);
  }

  instructions += Drop();  // Drop result of the setter invocation.

  if (direct_call.check_receiver_for_null_) {
    instructions += Drop();  // Drop receiver.
  }

  return instructions;
}

static Function& GetNoSuchMethodOrDie(Zone* zone, const Class& klass) {
  Function& nsm_function = Function::Handle(zone);
  Class& iterate_klass = Class::Handle(zone, klass.raw());
  while (!iterate_klass.IsNull()) {
    nsm_function = iterate_klass.LookupDynamicFunction(Symbols::NoSuchMethod());
    if (!nsm_function.IsNull() && nsm_function.NumParameters() == 2 &&
        nsm_function.NumTypeParameters() == 0) {
      break;
    }
    iterate_klass = iterate_klass.SuperClass();
  }
  // We are guaranteed to find noSuchMethod of class Object.
  ASSERT(!nsm_function.IsNull());

  return nsm_function;
}

// Note, that this will always mark `super` flag to true.
Fragment StreamingFlowGraphBuilder::BuildAllocateInvocationMirrorCall(
    TokenPosition position,
    const String& name,
    intptr_t num_type_arguments,
    intptr_t num_arguments,
    const Array& argument_names,
    LocalVariable* actuals_array,
    Fragment build_rest_of_actuals) {
  Fragment instructions;

  // Populate array containing the actual arguments. Just add [this] here.
  instructions += LoadLocal(actuals_array);                      // array
  instructions += IntConstant(num_type_arguments == 0 ? 0 : 1);  // index
  instructions += LoadLocal(parsed_function()->receiver_var());  // receiver
  instructions += StoreIndexed(kArrayCid);
  instructions += build_rest_of_actuals;

  // First argument is receiver.
  instructions += LoadLocal(parsed_function()->receiver_var());
  instructions += PushArgument();

  // Push the arguments for allocating the invocation mirror:
  //   - the name.
  instructions += Constant(String::ZoneHandle(Z, name.raw()));
  instructions += PushArgument();

  //   - the arguments descriptor.
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(num_type_arguments,
                                                num_arguments, argument_names));
  instructions += Constant(Array::ZoneHandle(Z, args_descriptor.raw()));
  instructions += PushArgument();

  //   - an array containing the actual arguments.
  instructions += LoadLocal(actuals_array);
  instructions += PushArgument();

  //   - [true] indicating this is a `super` NoSuchMethod.
  instructions += Constant(Bool::True());
  instructions += PushArgument();

  const Class& mirror_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(
             Library::PrivateCoreLibName(Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  instructions += StaticCall(position, allocation_function,
                             /* argument_count = */ 4, ICData::kStatic);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperPropertyGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Class& klass = GetSuperOrDie();

  StringIndex name_index = ReadStringReference();  // read name index.
  NameIndex library_reference =
      ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_')
          ? ReadCanonicalNameReference()  // read library index.
          : NameIndex();
  const String& getter_name = H.DartGetterName(library_reference, name_index);
  const String& method_name = H.DartMethodName(library_reference, name_index);

  SkipCanonicalNameReference();  // skip target_reference.

  // Search the superclass chain for the selector looking for either getter or
  // method.
  Function& function = Function::Handle(Z);
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunction(method_name);
    if (!function.IsNull()) {
      Function& target =
          Function::ZoneHandle(Z, function.ImplicitClosureFunction());
      ASSERT(!target.IsNull());
      // Generate inline code for allocation closure object with context
      // which captures `this`.
      return BuildImplicitClosureCreation(target);
    }
    function = klass.LookupDynamicFunction(getter_name);
    if (!function.IsNull()) break;
    klass = klass.SuperClass();
  }

  Fragment instructions;
  if (klass.IsNull()) {
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(1);  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    Class& parent_klass = GetSuperOrDie();

    instructions += BuildAllocateInvocationMirrorCall(
        position, getter_name,
        /* num_type_arguments = */ 0,
        /* num_arguments = */ 1,
        /* argument_names = */ Object::empty_array(), actuals_array,
        /* build_rest_of_actuals = */ Fragment());
    instructions += PushArgument();  // second argument is invocation mirror

    Function& nsm_function = GetNoSuchMethodOrDie(Z, parent_klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.raw()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += DropTempsPreserveTop(1);  // Drop array
  } else {
    ASSERT(!klass.IsNull());
    ASSERT(!function.IsNull());

    instructions += LoadLocal(parsed_function()->receiver_var());
    instructions += PushArgument();

    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, function.raw()),
                   /* argument_count = */ 1, Array::null_array(),
                   ICData::kSuper, &result_type);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperPropertySet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Class& klass = GetSuperOrDie();

  const String& setter_name = ReadNameAsSetterName();  // read name.

  Function& function =
      Function::Handle(Z, H.LookupDynamicFunction(klass, setter_name));

  Fragment instructions(MakeTemp());
  LocalVariable* value = MakeTemporary();  // this holds RHS value

  if (function.IsNull()) {
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(2);  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    Fragment build_rest_of_actuals;
    build_rest_of_actuals += LoadLocal(actuals_array);  // array
    build_rest_of_actuals += IntConstant(1);            // index
    build_rest_of_actuals += BuildExpression();         // value.
    build_rest_of_actuals += StoreLocal(position, value);
    build_rest_of_actuals += StoreIndexed(kArrayCid);

    instructions += BuildAllocateInvocationMirrorCall(
        position, setter_name, /* num_type_arguments = */ 0,
        /* num_arguments = */ 2,
        /* argument_names = */ Object::empty_array(), actuals_array,
        build_rest_of_actuals);
    instructions += PushArgument();  // second argument - invocation mirror

    SkipCanonicalNameReference();  // skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(Z, klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.raw()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += Drop();  // Drop result of NoSuchMethod invocation
    instructions += Drop();  // Drop array
  } else {
    // receiver
    instructions += LoadLocal(parsed_function()->receiver_var());
    instructions += PushArgument();

    instructions += BuildExpression();  // read value.
    instructions += StoreLocal(position, value);
    instructions += PushArgument();

    SkipCanonicalNameReference();  // skip target_reference.

    instructions += StaticCall(
        position, Function::ZoneHandle(Z, function.raw()),
        /* argument_count = */ 2, Array::null_array(), ICData::kSuper,
        /*result_type=*/nullptr, /*type_args_len=*/0,
        /*use_unchecked_entry=*/true);
    instructions += Drop();  // Drop result of the setter invocation.
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertyGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  const Tag receiver_tag = PeekTag();         // peek tag for receiver.
  Fragment instructions = BuildExpression();  // read receiver.
  const NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Function& target = Function::ZoneHandle(Z);
  if (H.IsProcedure(kernel_name)) {
    if (H.IsGetter(kernel_name)) {
      target =
          H.LookupMethodByMember(kernel_name, H.DartGetterName(kernel_name));
    } else if (receiver_tag == kThisExpression) {
      // Undo stack change for the BuildExpression.
      Pop();

      target =
          H.LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name));
      target = target.ImplicitClosureFunction();
      ASSERT(!target.IsNull());

      // Generate inline code for allocating closure object with context which
      // captures `this`.
      return BuildImplicitClosureCreation(target);
    } else {
      // Need to create implicit closure (tear-off), receiver != this.
      // Ensure method extractor exists and call it directly.
      const Function& target_method = Function::ZoneHandle(
          Z,
          H.LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name)));
      const String& getter_name = H.DartGetterName(kernel_name);
      target = target_method.GetMethodExtractor(getter_name);
    }
  } else {
    ASSERT(H.IsField(kernel_name));
    const String& getter_name = H.DartGetterName(kernel_name);
    target = H.LookupMethodByMember(kernel_name, getter_name);
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
  }

  instructions += PushArgument();
  // Static calls are marked as "no-rebind", which is currently safe because
  // DirectPropertyGet are only used in enums (index in toString) and enums
  // can't change their structure during hot reload.
  // If there are other sources of DirectPropertyGet in the future, this code
  // have to be adjusted.
  return instructions + StaticCall(position, target, 1, Array::null_array(),
                                   ICData::kNoRebind, &result_type);
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertySet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions(MakeTemp());
  LocalVariable* value = MakeTemporary();

  instructions += BuildExpression();  // read receiver.
  instructions += PushArgument();

  const NameIndex target_reference =
      ReadCanonicalNameReference();  // read target_reference.
  const String& method_name = H.DartSetterName(target_reference);
  const Function& target = Function::ZoneHandle(
      Z, H.LookupMethodByMember(target_reference, method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, value);
  instructions += PushArgument();

  // Static calls are marked as "no-rebind", which is currently safe because
  // DirectPropertyGet are only used in enums (index in toString) and enums
  // can't change their structure during hot reload.
  // If there are other sources of DirectPropertyGet in the future, this code
  // have to be adjusted.
  instructions +=
      StaticCall(position, target, 2, Array::null_array(), ICData::kNoRebind,
                 /* result_type = */ NULL);

  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildStaticGet(TokenPosition* p) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const Field& field =
        Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    if (field.is_const()) {
      return Constant(Instance::ZoneHandle(
          Z, constant_evaluator_.EvaluateExpression(offset)));
    } else {
      const Class& owner = Class::Handle(Z, field.Owner());
      const String& getter_name = H.DartGetterName(target);
      const Function& getter =
          Function::ZoneHandle(Z, owner.LookupStaticFunction(getter_name));
      if (getter.IsNull() || !field.has_initializer()) {
        Fragment instructions = Constant(field);
        return instructions + LoadStaticField();
      } else {
        return StaticCall(position, getter, 0, Array::null_array(),
                          ICData::kStatic, &result_type);
      }
    }
  } else {
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsGetter(target)) {
      return StaticCall(position, function, 0, Array::null_array(),
                        ICData::kStatic, &result_type);
    } else if (H.IsMethod(target)) {
      return Constant(Instance::ZoneHandle(
          Z, constant_evaluator_.EvaluateExpression(offset)));
    } else {
      UNIMPLEMENTED();
    }
  }

  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStaticSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const Field& field =
        Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    Fragment instructions = BuildExpression();  // read expression.
    if (NeedsDebugStepCheck(stack(), position)) {
      instructions = DebugStepCheck(position) + instructions;
    }
    LocalVariable* variable = MakeTemporary();
    instructions += LoadLocal(variable);
    return instructions + StoreStaticField(position, field);
  } else {
    ASSERT(H.IsProcedure(target));

    // Evaluate the expression on the right hand side.
    Fragment instructions = BuildExpression();  // read expression.
    LocalVariable* variable = MakeTemporary();

    // Prepare argument.
    instructions += LoadLocal(variable);
    instructions += PushArgument();

    // Invoke the setter function.
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));
    instructions += StaticCall(position, function, 1, ICData::kStatic);

    // Drop the unused result & leave the stored value on the stack.
    return instructions + Drop();
  }
}

Fragment StreamingFlowGraphBuilder::BuildMethodInvocation(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForMethodInvocation(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);
  const CallSiteAttributesMetadata call_site_attributes =
      call_site_attributes_metadata_helper_.GetCallSiteAttributes(offset);

  const Tag receiver_tag = PeekTag();  // peek tag for receiver.

  bool is_unchecked_closure_call = false;
  bool is_unchecked_call = result_type.IsSkipCheck();
  if (call_site_attributes.receiver_type != nullptr) {
    if (call_site_attributes.receiver_type->IsFunctionType()) {
      AlternativeReadingScope alt(&reader_);
      SkipExpression();  // skip receiver
      is_unchecked_closure_call =
          ReadNameAsMethodName().Equals(Symbols::Call());
    } else if (call_site_attributes.receiver_type->HasTypeClass() &&
               !Class::Handle(call_site_attributes.receiver_type->type_class())
                    .IsGeneric()) {
      is_unchecked_call = true;
    }
  }

  Fragment instructions;

  intptr_t type_args_len = 0;
  LocalVariable* type_arguments_temp = NULL;
  {
    AlternativeReadingScope alt(&reader_);
    SkipExpression();                         // skip receiver
    SkipName();                               // skip method name
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      if (direct_call.check_receiver_for_null_ || is_unchecked_closure_call) {
        // Don't yet push type arguments if we need to check receiver for null.
        // In this case receiver will be duplicated so instead of pushing
        // type arguments here we need to push it between receiver_temp
        // and actual receiver. See the code below.
        type_arguments_temp = MakeTemporary();
      } else {
        instructions += PushArgument();
      }
    }
    type_args_len = list_length;
  }

  // Take note of whether the invocation is against the receiver of the current
  // function: in this case, we may skip some type checks in the callee.
  if (PeekTag() == kThisExpression) {
    is_unchecked_call = true;
  }
  instructions += BuildExpression();  // read receiver.

  const String& name = ReadNameAsMethodName();  // read name.
  const Token::Kind token_kind =
      MethodTokenRecognizer::RecognizeTokenKind(name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
    ASSERT(type_args_len == 0);
    // "==" or "!=" with null on either side.
    instructions += BuildArguments(NULL /* named */, NULL /* arg count */,
                                   NULL /* positional arg count */,
                                   true);  // read arguments.
    SkipCanonicalNameReference();          // read interface_target_reference.
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(position, strict_cmp_kind, /*number_check = */ true);
  }

  LocalVariable* receiver_temp = NULL;
  if (direct_call.check_receiver_for_null_ || is_unchecked_closure_call) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver_temp = MakeTemporary();
    if (type_arguments_temp != NULL) {
      // If call has type arguments then push them before pushing the receiver.
      // The stack will contain:
      //
      //   [type_arguments_temp][receiver_temp][type_arguments][receiver] ...
      //
      instructions += LoadLocal(type_arguments_temp);
      instructions += PushArgument();
    }
    instructions += LoadLocal(receiver_temp);
  }

  instructions += PushArgument();  // push receiver as argument.

  intptr_t argument_count;
  intptr_t positional_argument_count;
  Array& argument_names = Array::ZoneHandle(Z);
  instructions +=
      BuildArguments(&argument_names, &argument_count,
                     &positional_argument_count);  // read arguments.
  ++argument_count;                                // include receiver

  intptr_t checked_argument_count = 1;
  // If we have a special operation (e.g. +/-/==) we mark both arguments as
  // to be checked.
  if (token_kind != Token::kILLEGAL) {
    ASSERT(argument_count <= 2);
    checked_argument_count = argument_count;
  }

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  // TODO(dartbug.com/34497): Once front-end desugars calls via
  // fields/getters, filtering of field and getter interface targets here
  // can be turned into assertions.
  if (!H.IsRoot(itarget_name) && !H.IsField(itarget_name) &&
      !H.IsGetter(itarget_name)) {
    interface_target = &Function::ZoneHandle(
        Z, H.LookupMethodByMember(itarget_name,
                                  H.DartProcedureName(itarget_name)));
    ASSERT(name.raw() == interface_target->name());
    ASSERT(!interface_target->IsGetterFunction());
  }

  // TODO(sjindel): Avoid the check for null on unchecked closure calls if TFA
  // allows.
  if (direct_call.check_receiver_for_null_ || is_unchecked_closure_call) {
    // Receiver temp is needed to load the function to call from the closure.
    instructions += CheckNull(position, receiver_temp, name,
                              /*clear_temp=*/!is_unchecked_closure_call);
  }

  const String* mangled_name = &name;
  // Do not mangle == or call:
  //   * operator == takes an Object so its either not checked or checked
  //     at the entry because the parameter is marked covariant, neither of
  //     those cases require a dynamic invocation forwarder;
  //   * we assume that all closures are entered in a checked way.
  const Function* direct_call_target = &direct_call.target_;
  if (I->should_emit_strong_mode_checks() &&
      (name.raw() != Symbols::EqualOperator().raw()) &&
      (name.raw() != Symbols::Call().raw()) && H.IsRoot(itarget_name)) {
    mangled_name = &String::ZoneHandle(
        Z, Function::CreateDynamicInvocationForwarderName(name));
    if (!direct_call_target->IsNull()) {
      direct_call_target = &Function::ZoneHandle(
          direct_call_target->GetDynamicInvocationForwarder(*mangled_name));
    }
  }

  if (is_unchecked_closure_call) {
    // Lookup the function in the closure.
    instructions += LoadLocal(receiver_temp);
    instructions += LoadNativeField(Slot::Closure_function());
    if (parsed_function()->function().is_debuggable()) {
      ASSERT(!parsed_function()->function().is_native());
      instructions += DebugStepCheck(position);
    }
    instructions +=
        B->ClosureCall(position, type_args_len, argument_count, argument_names,
                       /*use_unchecked_entry=*/true);
  } else if (!direct_call_target->IsNull()) {
    // Even if TFA infers a concrete receiver type, the static type of the
    // call-site may still be dynamic and we need to call the dynamic invocation
    // forwarder to ensure type-checks are performed.
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, *direct_call_target, argument_count,
                   argument_names, ICData::kNoRebind, &result_type,
                   type_args_len, /*use_unchecked_entry=*/is_unchecked_call);
  } else {
    instructions += InstanceCall(
        position, *mangled_name, token_kind, type_args_len, argument_count,
        argument_names, checked_argument_count, *interface_target, &result_type,
        /*use_unchecked_entry=*/is_unchecked_call, &call_site_attributes);
  }

  // Drop temporaries preserving result on the top of the stack.
  ASSERT((receiver_temp != NULL) || (type_arguments_temp == NULL));
  if (receiver_temp != NULL) {
    const intptr_t num_temps =
        (receiver_temp != NULL ? 1 : 0) + (type_arguments_temp != NULL ? 1 : 0);
    instructions += DropTempsPreserveTop(num_temps);
  }

  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.raw() == Symbols::AssignIndexToken().raw()) {
    instructions += Drop();
    instructions += NullConstant();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDirectMethodInvocation(
    TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  TokenPosition position = ReadPosition();     // read offset.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Tag receiver_tag = PeekTag();  // peek tag for receiver.

  Fragment instructions;
  intptr_t type_args_len = 0;
  {
    AlternativeReadingScope alt(&reader_);
    SkipExpression();                         // skip receiver
    ReadCanonicalNameReference();             // skip target reference
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
    }
    type_args_len = list_length;
  }

  instructions += BuildExpression();  // read receiver.

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.
  const String& method_name = H.DartProcedureName(kernel_name);
  const Token::Kind token_kind =
      MethodTokenRecognizer::RecognizeTokenKind(method_name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
    ASSERT(type_args_len == 0);
    // "==" or "!=" with null on either side.
    instructions += BuildArguments(NULL /* names */, NULL /* arg count */,
                                   NULL /* positional arg count */,
                                   true);  // read arguments.
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(position, strict_cmp_kind, /*number_check = */ true);
  }

  instructions += PushArgument();  // push receiver as argument.

  const Function& target =
      Function::ZoneHandle(Z, H.LookupMethodByMember(kernel_name, method_name));

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count, positional_argument_count;
  instructions +=
      BuildArguments(&argument_names, &argument_count,
                     &positional_argument_count);  // read arguments.
  ++argument_count;

  return instructions + StaticCall(position, target, argument_count,
                                   argument_names, ICData::kNoRebind,
                                   &result_type, type_args_len);
}

Fragment StreamingFlowGraphBuilder::BuildSuperMethodInvocation(
    TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  intptr_t type_args_len = 0;
  {
    AlternativeReadingScope alt(&reader_);
    SkipName();                        // skip method name
    ReadUInt();                        // read argument count.
    type_args_len = ReadListLength();  // read types list length.
  }

  Class& klass = GetSuperOrDie();

  // Search the superclass chain for the selector.
  const String& method_name = ReadNameAsMethodName();  // read name.

  // Figure out selector signature.
  intptr_t argument_count;
  Array& argument_names = Array::Handle(Z);
  {
    AlternativeReadingScope alt(&reader_);
    argument_count = ReadUInt();
    SkipListOfDartTypes();

    SkipListOfExpressions();
    intptr_t named_list_length = ReadListLength();
    argument_names = Array::New(named_list_length, H.allocation_space());
    for (intptr_t i = 0; i < named_list_length; i++) {
      const String& arg_name = H.DartSymbolObfuscate(ReadStringReference());
      argument_names.SetAt(i, arg_name);
      SkipExpression();
    }
  }

  Function& function = FindMatchingFunction(
      klass, method_name, type_args_len,
      argument_count + 1 /* account for 'this' */, argument_names);

  if (function.IsNull()) {
    ReadUInt();  // argument count
    intptr_t type_list_length = ReadListLength();

    Fragment instructions;
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(argument_count + 1 /* this */ +
                                (type_list_length == 0 ? 0 : 1));  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    // Call allocationInvocationMirror to get instance of Invocation.
    Fragment build_rest_of_actuals;
    intptr_t actuals_array_index = 0;
    if (type_list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(type_list_length);
      build_rest_of_actuals += LoadLocal(actuals_array);
      build_rest_of_actuals += IntConstant(actuals_array_index);
      build_rest_of_actuals +=
          TranslateInstantiatedTypeArguments(type_arguments);
      build_rest_of_actuals += StoreIndexed(kArrayCid);
      ++actuals_array_index;
    }

    ++actuals_array_index;  // account for 'this'.
    // Read arguments
    intptr_t list_length = ReadListLength();
    intptr_t i = 0;
    while (i < list_length) {
      build_rest_of_actuals += LoadLocal(actuals_array);              // array
      build_rest_of_actuals += IntConstant(actuals_array_index + i);  // index
      build_rest_of_actuals += BuildExpression();                     // value.
      build_rest_of_actuals += StoreIndexed(kArrayCid);
      ++i;
    }
    // Read named arguments
    intptr_t named_list_length = ReadListLength();
    if (named_list_length > 0) {
      ASSERT(argument_count == list_length + named_list_length);
      while ((i - list_length) < named_list_length) {
        SkipStringReference();
        build_rest_of_actuals += LoadLocal(actuals_array);              // array
        build_rest_of_actuals += IntConstant(i + actuals_array_index);  // index
        build_rest_of_actuals += BuildExpression();  // value.
        build_rest_of_actuals += StoreIndexed(kArrayCid);
        ++i;
      }
    }
    instructions += BuildAllocateInvocationMirrorCall(
        position, method_name, type_list_length,
        /* num_arguments = */ argument_count + 1, argument_names, actuals_array,
        build_rest_of_actuals);
    instructions += PushArgument();  // second argument - invocation mirror

    SkipCanonicalNameReference();  //  skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(Z, klass);
    instructions += StaticCall(TokenPosition::kNoSource,
                               Function::ZoneHandle(Z, nsm_function.raw()),
                               /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += DropTempsPreserveTop(1);  // Drop actuals_array temp.
    return instructions;
  } else {
    Fragment instructions;

    {
      AlternativeReadingScope alt(&reader_);
      ReadUInt();                               // read argument count.
      intptr_t list_length = ReadListLength();  // read types list length.
      if (list_length > 0) {
        const TypeArguments& type_arguments =
            T.BuildTypeArguments(list_length);  // read types.
        instructions += TranslateInstantiatedTypeArguments(type_arguments);
        instructions += PushArgument();
      }
    }

    // receiver
    instructions += LoadLocal(parsed_function()->receiver_var());
    instructions += PushArgument();

    Array& argument_names = Array::ZoneHandle(Z);
    intptr_t argument_count;
    instructions += BuildArguments(
        &argument_names, &argument_count,
        /* positional_argument_count = */ NULL);  // read arguments.
    ++argument_count;                             // include receiver
    SkipCanonicalNameReference();                 // interfaceTargetReference
    return instructions +
           StaticCall(position, Function::ZoneHandle(Z, function.raw()),
                      argument_count, argument_names, ICData::kSuper,
                      &result_type, type_args_len,
                      /*use_unchecked_entry_point=*/true);
  }
}

Fragment StreamingFlowGraphBuilder::BuildStaticInvocation(bool is_const,
                                                          TokenPosition* p) {
  if (is_const) {
    const intptr_t offset = ReaderOffset() - 1;           // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();  // read position.

    SetOffset(offset);
    SkipExpression();  // read past this StaticInvocation.
    return Constant(constant_evaluator_.EvaluateStaticInvocation(offset));
  }

  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  TokenPosition position = ReadPosition();     // read position.
  if (p != NULL) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  NameIndex procedure_reference =
      ReadCanonicalNameReference();  // read procedure reference.
  intptr_t argument_count = PeekArgumentsCount();
  const Function& target = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(procedure_reference));
  const Class& klass = Class::ZoneHandle(Z, target.Owner());
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }

  const auto recognized_kind = MethodRecognizer::RecognizeKind(target);
  if (recognized_kind == MethodRecognizer::kFfiAsFunctionInternal) {
    return BuildFfiAsFunctionInternal();
  } else if (FLAG_precompiled_mode &&
             recognized_kind == MethodRecognizer::kFfiNativeCallbackFunction) {
    return BuildFfiNativeCallbackFunction();
  }

  Fragment instructions;
  LocalVariable* instance_variable = NULL;

  const bool special_case_nop_async_stack_trace_helper =
      !FLAG_causal_async_stacks &&
      recognized_kind == MethodRecognizer::kAsyncStackTraceHelper;

  const bool special_case_unchecked_cast =
      klass.IsTopLevel() && (klass.library() == Library::InternalLibrary()) &&
      (target.name() == Symbols::UnsafeCast().raw());

  const bool special_case_identical =
      klass.IsTopLevel() && (klass.library() == Library::CoreLibrary()) &&
      (target.name() == Symbols::Identical().raw());

  const bool special_case = special_case_identical ||
                            special_case_unchecked_cast ||
                            special_case_nop_async_stack_trace_helper;

  // If we cross the Kernel -> VM core library boundary, a [StaticInvocation]
  // can appear, but the thing we're calling is not a static method, but a
  // factory constructor.
  // The `H.LookupStaticmethodByKernelProcedure` will potentially resolve to the
  // forwarded constructor.
  // In that case we'll make an instance and pass it as first argument.
  //
  // TODO(27590): Get rid of this after we're using core libraries compiled
  // into Kernel.
  intptr_t type_args_len = 0;
  if (target.IsGenerativeConstructor()) {
    if (klass.NumTypeArguments() > 0) {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
      instructions += AllocateObject(position, klass, 1);
    } else {
      instructions += AllocateObject(position, klass, 0);
    }

    instance_variable = MakeTemporary();

    instructions += LoadLocal(instance_variable);
    instructions += PushArgument();
  } else if (target.IsFactory()) {
    // The VM requires currently a TypeArguments object as first parameter for
    // every factory constructor :-/ !
    //
    // TODO(27590): Get rid of this after we're using core libraries compiled
    // into Kernel.
    const TypeArguments& type_arguments = PeekArgumentsInstantiatedType(klass);
    instructions += TranslateInstantiatedTypeArguments(type_arguments);
    instructions += PushArgument();
  } else if (!special_case) {
    AlternativeReadingScope alt(&reader_);
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
    }
    type_args_len = list_length;
  }

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += BuildArguments(&argument_names, NULL /* arg count */,
                                 NULL /* positional arg count */,
                                 special_case);  // read arguments.
  ASSERT(target.AreValidArguments(type_args_len, argument_count, argument_names,
                                  NULL));

  // Special case identical(x, y) call.
  // Note: similar optimization is performed in bytecode flow graph builder -
  // see BytecodeFlowGraphBuilder::BuildDirectCall().
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (special_case_identical) {
    ASSERT(argument_count == 2);
    instructions +=
        StrictCompare(position, Token::kEQ_STRICT, /*number_check=*/true);
  } else if (special_case_nop_async_stack_trace_helper) {
    ASSERT(argument_count == 1);
    instructions += Drop();
    instructions += NullConstant();
  } else if (special_case_unchecked_cast) {
    // Simply do nothing: the result value is already pushed on the stack.
  } else {
    instructions += StaticCall(position, target, argument_count, argument_names,
                               ICData::kStatic, &result_type, type_args_len);
    if (target.IsGenerativeConstructor()) {
      // Drop the result of the constructor call and leave [instance_variable]
      // on top-of-stack.
      instructions += Drop();
    }
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildConstructorInvocation(
    bool is_const,
    TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;                 // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();  // read position.

    SetOffset(offset);
    SkipExpression();  // read past this ConstructorInvocation.
    return Constant(constant_evaluator_.EvaluateConstructorInvocation(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Class& klass = Class::ZoneHandle(
      Z, H.LookupClassByKernelClass(H.EnclosingName(kernel_name)));

  Fragment instructions;

  if (klass.NumTypeArguments() > 0) {
    if (!klass.IsGeneric()) {
      Type& type = Type::ZoneHandle(Z, T.ReceiverType(klass).raw());

      // TODO(27590): Can we move this code into [ReceiverType]?
      type ^= ClassFinalizer::FinalizeType(*active_class()->klass, type,
                                           ClassFinalizer::kFinalize);
      TypeArguments& canonicalized_type_arguments =
          TypeArguments::ZoneHandle(Z, type.arguments());
      canonicalized_type_arguments =
          canonicalized_type_arguments.Canonicalize();
      instructions += Constant(canonicalized_type_arguments);
    } else {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }

    instructions += PushArgument();
    instructions += AllocateObject(position, klass, 1);
  } else {
    instructions += AllocateObject(position, klass, 0);
  }
  LocalVariable* variable = MakeTemporary();

  instructions += LoadLocal(variable);
  instructions += PushArgument();

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions += BuildArguments(
      &argument_names, &argument_count,
      /* positional_argument_count = */ NULL);  // read arguments.

  const Function& target = Function::ZoneHandle(
      Z, H.LookupConstructorByKernelConstructor(klass, kernel_name));
  ++argument_count;
  instructions += StaticCall(position, target, argument_count, argument_names,
                             ICData::kStatic, /* result_type = */ NULL);
  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildNot(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  TokenPosition operand_position = TokenPosition::kNoSource;
  Fragment instructions =
      BuildExpression(&operand_position);  // read expression.
  instructions += CheckBoolean(operand_position);
  instructions += BooleanNegate();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildNullCheck(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  TokenPosition operand_position = TokenPosition::kNoSource;
  Fragment instructions =
      BuildExpression(&operand_position);  // read expression.
  // TODO(37479): Implement null-check semantics.
  return instructions;
}

// Translate the logical expression (lhs && rhs or lhs || rhs) in a context
// where a value is required.
//
// Translation accumulates short-circuit exits from logical
// subexpressions in the side_exits. These exits are expected to store
// true and false into :expr_temp.
//
// The result of evaluating the last
// expression in chain would be stored in :expr_temp directly to avoid
// generating graph like:
//
//     if (v) :expr_temp = true; else :expr_temp = false;
//
// Outer negations are stripped and instead negation is passed down via
// negated parameter.
Fragment StreamingFlowGraphBuilder::TranslateLogicalExpressionForValue(
    bool negated,
    TestFragment* side_exits) {
  TestFragment left = TranslateConditionForControl().Negate(negated);
  LogicalOperator op = static_cast<LogicalOperator>(ReadByte());
  if (negated) {
    op = (op == kAnd) ? kOr : kAnd;
  }

  // Short circuit the control flow after the left hand side condition.
  if (op == kAnd) {
    side_exits->false_successor_addresses->AddArray(
        *left.false_successor_addresses);
  } else {
    side_exits->true_successor_addresses->AddArray(
        *left.true_successor_addresses);
  }

  // Skip negations of the right hand side.
  while (PeekTag() == kNot) {
    SkipBytes(1);
    negated = !negated;
  }

  Fragment right_value(op == kAnd
                           ? left.CreateTrueSuccessor(flow_graph_builder_)
                           : left.CreateFalseSuccessor(flow_graph_builder_));

  if (PeekTag() == kLogicalExpression) {
    SkipBytes(1);
    // Handle nested logical expressions specially to avoid materializing
    // intermediate boolean values.
    right_value += TranslateLogicalExpressionForValue(negated, side_exits);
  } else {
    // Arbitrary expression on the right hand side. Translate it for value.
    TokenPosition position = TokenPosition::kNoSource;
    right_value += BuildExpression(&position);  // read expression.

    // Check if the top of the stack is known to be a non-nullable boolean.
    // Note that in strong mode we know that any value that reaches here
    // is at least a nullable boolean - so there is no need to compare
    // with true like in Dart 1.
    Definition* top = stack()->definition();
    const bool is_bool = top->IsStrictCompare() || top->IsBooleanNegate();
    if (!is_bool) {
      right_value += CheckBoolean(position);
    }
    if (negated) {
      right_value += BooleanNegate();
    }
    right_value += StoreLocal(TokenPosition::kNoSource,
                              parsed_function()->expression_temp_var());
    right_value += Drop();
  }

  return Fragment(left.entry, right_value.current);
}

Fragment StreamingFlowGraphBuilder::BuildLogicalExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  TestFragment exits;
  exits.true_successor_addresses = new TestFragment::SuccessorAddressArray(2);
  exits.false_successor_addresses = new TestFragment::SuccessorAddressArray(2);

  JoinEntryInstr* join = BuildJoinEntry();
  Fragment instructions =
      TranslateLogicalExpressionForValue(/*negated=*/false, &exits);
  instructions += Goto(join);

  // Generate :expr_temp = true if needed and connect it to true side-exits.
  if (!exits.true_successor_addresses->is_empty()) {
    Fragment constant_fragment(exits.CreateTrueSuccessor(flow_graph_builder_));
    constant_fragment += Constant(Bool::Get(true));
    constant_fragment += StoreLocal(TokenPosition::kNoSource,
                                    parsed_function()->expression_temp_var());
    constant_fragment += Drop();
    constant_fragment += Goto(join);
  }

  // Generate :expr_temp = false if needed and connect it to false side-exits.
  if (!exits.false_successor_addresses->is_empty()) {
    Fragment constant_fragment(exits.CreateFalseSuccessor(flow_graph_builder_));
    constant_fragment += Constant(Bool::Get(false));
    constant_fragment += StoreLocal(TokenPosition::kNoSource,
                                    parsed_function()->expression_temp_var());
    constant_fragment += Drop();
    constant_fragment += Goto(join);
  }

  return Fragment(instructions.entry, join) +
         LoadLocal(parsed_function()->expression_temp_var());
}

Fragment StreamingFlowGraphBuilder::BuildConditionalExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  TestFragment condition = TranslateConditionForControl();  // read condition.

  Value* top = stack();
  Fragment then_fragment(condition.CreateTrueSuccessor(flow_graph_builder_));
  then_fragment += BuildExpression();  // read then.
  then_fragment += StoreLocal(TokenPosition::kNoSource,
                              parsed_function()->expression_temp_var());
  then_fragment += Drop();
  ASSERT(stack() == top);

  Fragment otherwise_fragment(
      condition.CreateFalseSuccessor(flow_graph_builder_));
  otherwise_fragment += BuildExpression();  // read otherwise.
  otherwise_fragment += StoreLocal(TokenPosition::kNoSource,
                                   parsed_function()->expression_temp_var());
  otherwise_fragment += Drop();
  ASSERT(stack() == top);

  JoinEntryInstr* join = BuildJoinEntry();
  then_fragment += Goto(join);
  otherwise_fragment += Goto(join);

  SkipOptionalDartType();  // read unused static type.

  return Fragment(condition.entry, join) +
         LoadLocal(parsed_function()->expression_temp_var());
}

Fragment StreamingFlowGraphBuilder::BuildStringConcatenation(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" expressions.

  Fragment instructions;
  if (length == 1) {
    instructions += BuildExpression();  // read expression.
    instructions += StringInterpolateSingle(position);
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(TypeArguments::ZoneHandle(Z));
    instructions += IntConstant(length);
    instructions += CreateArray();
    LocalVariable* array = MakeTemporary();

    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += BuildExpression();  // read ith expression.
      instructions += StoreIndexed(kArrayCid);
    }

    instructions += StringInterpolate(position);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.

  // The VM does not like an instanceOf call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());

  if (type.IsInstantiated() && object_type.IsSubtypeOf(type, Heap::kOld)) {
    // Evaluate the expression on the left but ignore it's result.
    instructions += Drop();

    // Let condition be always true.
    instructions += Constant(Bool::True());
  } else {
    instructions += PushArgument();

    // See if simple instanceOf is applicable.
    if (dart::SimpleInstanceOfType(type)) {
      instructions += Constant(type);
      instructions += PushArgument();  // Type.
      instructions += InstanceCall(
          position, Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()),
          Token::kIS, 2, 2);  // 2 checked arguments.
      return instructions;
    }

    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Instantiator type arguments.

    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Function type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += InstanceCall(
        position, Library::PrivateCoreLibName(Symbols::_instanceOf()),
        Token::kIS, 4);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const uint8_t flags = ReadFlags();  // read flags.
  const bool is_type_error = (flags & (1 << 0)) != 0;

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.
  if (type.IsInstantiated() && type.IsTopType()) {
    // We already evaluated the operand on the left and just leave it there as
    // the result of the `obj as dynamic` expression.
  } else {
    // We do not care whether the 'as' cast as implicitly added by the frontend
    // or explicitly written by the user, in both cases we use an assert
    // assignable.
    instructions += LoadLocal(MakeTemporary());
    instructions += B->AssertAssignable(
        position, type,
        is_type_error ? Symbols::Empty() : Symbols::InTypeCast(),
        AssertAssignableInstr::kInsertedByFrontend);
    instructions += Drop();
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSymbolLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  intptr_t offset = ReaderOffset() - 1;  // EvaluateExpression needs the tag.
  SkipStringReference();                 // read index into string table.
  return Constant(
      Instance::ZoneHandle(Z, constant_evaluator_.EvaluateExpression(offset)));
}

Fragment StreamingFlowGraphBuilder::BuildTypeLiteral(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  const AbstractType& type = T.BuildType();  // read type.
  Fragment instructions;
  if (type.IsInstantiated()) {
    instructions += Constant(type);
  } else {
    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += InstantiateType(type);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildThisExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return LoadLocal(parsed_function()->receiver_var());
}

Fragment StreamingFlowGraphBuilder::BuildRethrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = DebugStepCheck(position);
  instructions += LoadLocal(catch_block()->exception_var());
  instructions += PushArgument();
  instructions += LoadLocal(catch_block()->stack_trace_var());
  instructions += PushArgument();
  instructions += RethrowException(position, catch_block()->catch_try_index());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildThrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions;

  instructions += BuildExpression();  // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions += PushArgument();
  instructions += ThrowException(position);
  ASSERT(instructions.is_closed());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildListLiteral(bool is_const,
                                                     TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;                 // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();  // read position.

    SetOffset(offset);
    SkipExpression();  // read past the ListLiteral.
    return Constant(constant_evaluator_.EvaluateListLiteral(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const TypeArguments& type_arguments = T.BuildTypeArguments(1);  // read type.
  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" expressions.

  // The type argument for the factory call.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  LocalVariable* type = MakeTemporary();

  instructions += LoadLocal(type);
  instructions += PushArgument();
  if (length == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for CreateArray.
    instructions += LoadLocal(type);
    instructions += IntConstant(length);
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += BuildExpression();  // read ith expression.
      instructions += StoreIndexed(kArrayCid);
    }
  }
  instructions += PushArgument();  // The array.

  const Class& factory_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::List()));
  const Function& factory_method = Function::ZoneHandle(
      Z, factory_class.LookupFactory(
             Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));

  instructions += StaticCall(position, factory_method, 2, ICData::kStatic);
  instructions += DropTempsPreserveTop(1);  // Instantiated type_arguments.
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildMapLiteral(bool is_const,
                                                    TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;  // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();

    SetOffset(offset);
    SkipExpression();  // Read past the MapLiteral.
    return Constant(constant_evaluator_.EvaluateMapLiteral(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const TypeArguments& type_arguments =
      T.BuildTypeArguments(2);  // read key_type and value_type.

  // The type argument for the factory call `new Map<K, V>._fromLiteral(List)`.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();

  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" map entries (i.e. key and value expressions).

  if (length == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for `new List<X>(int len)`.
    instructions += Constant(TypeArguments::ZoneHandle(Z));

    // We generate a list of tuples, i.e. [key1, value1, ..., keyN, valueN].
    instructions += IntConstant(2 * length);
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i);
      instructions += BuildExpression();  // read ith key.
      instructions += StoreIndexed(kArrayCid);

      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i + 1);
      instructions += BuildExpression();  // read ith value.
      instructions += StoreIndexed(kArrayCid);
    }
  }
  instructions += PushArgument();  // The array.

  const Class& map_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::Map()));
  const Function& factory_method = Function::ZoneHandle(
      Z, map_class.LookupFactory(
             Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));

  return instructions +
         StaticCall(position, factory_method, 2, ICData::kStatic);
}

Fragment StreamingFlowGraphBuilder::BuildFunctionExpression() {
  ReadPosition();  // read position.
  return BuildFunctionNode(TokenPosition::kNoSource, StringIndex());
}

Fragment StreamingFlowGraphBuilder::BuildLet(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildVariableDeclaration();  // read variable.
  instructions += BuildExpression();                   // read body.
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBlockExpression() {
  block_expression_depth_inc();
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  const intptr_t list_length = ReadListLength();  // read number of statements.
  for (intptr_t i = 0; i < list_length; ++i) {
    instructions += BuildStatement();  // read ith statement.
  }
  instructions += BuildExpression();  // read expression (inside scope).
  instructions += ExitScope(offset);

  block_expression_depth_dec();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBigIntLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  const String& value =
      H.DartString(ReadStringReference());  // read index into string table.
  const Integer& integer = Integer::ZoneHandle(Z, Integer::NewCanonical(value));
  if (integer.IsNull()) {
    H.ReportError(script_, TokenPosition::kNoSource,
                  "Integer literal %s is out of range", value.ToCString());
    UNREACHABLE();
  }
  return Constant(integer);
}

Fragment StreamingFlowGraphBuilder::BuildStringLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(H.DartSymbolPlain(
      ReadStringReference()));  // read index into string table.
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(uint8_t payload,
                                                    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(bool is_negative,
                                                    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  int64_t value = is_negative ? -static_cast<int64_t>(ReadUInt())
                              : ReadUInt();  // read value.
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildDoubleLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Double& constant = Double::ZoneHandle(
      Z, Double::NewCanonical(ReadDouble()));  // read double.
  return Constant(constant);
}

Fragment StreamingFlowGraphBuilder::BuildBoolLiteral(bool value,
                                                     TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(Bool::Get(value));
}

Fragment StreamingFlowGraphBuilder::BuildNullLiteral(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}

Fragment StreamingFlowGraphBuilder::BuildFutureNullValue(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;
  const Class& future = Class::Handle(Z, I->object_store()->future_class());
  ASSERT(!future.IsNull());
  const Function& constructor =
      Function::ZoneHandle(Z, future.LookupFunction(Symbols::FutureValue()));
  ASSERT(!constructor.IsNull());

  Fragment instructions;
  instructions += BuildNullLiteral(position);
  instructions += PushArgument();
  instructions += StaticCall(TokenPosition::kNoSource, constructor,
                             /* argument_count = */ 1, ICData::kStatic);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildConstantExpression(
    TokenPosition* position,
    Tag tag) {
  TokenPosition p = TokenPosition::kNoSource;
  if (tag == kConstantExpression) {
    p = ReadPosition();
    SkipDartType();
  }
  if (position != nullptr) *position = p;
  const intptr_t constant_offset = ReadUInt();
  Fragment result = Constant(Object::ZoneHandle(
      Z, constant_evaluator_.EvaluateConstantExpression(constant_offset)));
  return result;
}

Fragment StreamingFlowGraphBuilder::BuildPartialTearoffInstantiation(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  // Create a copy of the closure.

  Fragment instructions = BuildExpression();
  LocalVariable* original_closure = MakeTemporary();

  instructions += AllocateObject(
      TokenPosition::kNoSource,
      Class::ZoneHandle(Z, I->object_store()->closure_class()), 0);
  LocalVariable* new_closure = MakeTemporary();

  intptr_t num_type_args = ReadListLength();
  const TypeArguments& type_args = T.BuildTypeArguments(num_type_args);
  instructions += TranslateInstantiatedTypeArguments(type_args);
  LocalVariable* type_args_vec = MakeTemporary();

  // Check the bounds.
  //
  // TODO(sjindel): We should be able to skip this check in many cases, e.g.
  // when the closure is coming from a tearoff of a top-level method or from a
  // local closure.
  instructions += LoadLocal(original_closure);
  instructions += PushArgument();
  instructions += LoadLocal(type_args_vec);
  instructions += PushArgument();
  const Library& dart_internal = Library::Handle(Z, Library::InternalLibrary());
  const Function& bounds_check_function = Function::ZoneHandle(
      Z, dart_internal.LookupFunctionAllowPrivate(
             Symbols::BoundsCheckForPartialInstantiation()));
  ASSERT(!bounds_check_function.IsNull());
  instructions += StaticCall(TokenPosition::kNoSource, bounds_check_function, 2,
                             ICData::kStatic);
  instructions += Drop();

  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(type_args_vec);
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_delayed_type_arguments());
  instructions += Drop();  // Drop type args.

  // Copy over the target function.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions +=
      flow_graph_builder_->LoadNativeField(Slot::Closure_function());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_function());

  // Copy over the instantiator type arguments.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(
      Slot::Closure_instantiator_type_arguments());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_instantiator_type_arguments());

  // Copy over the function type arguments.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(
      Slot::Closure_function_type_arguments());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_function_type_arguments());

  // Copy over the context.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(Slot::Closure_context());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_context());

  instructions += DropTempsPreserveTop(1);  // Drop old closure.

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildExpressionStatement() {
  Fragment instructions = BuildExpression();  // read expression.
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBlock() {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  intptr_t list_length = ReadListLength();  // read number of statements.
  for (intptr_t i = 0; i < list_length; ++i) {
    if (instructions.is_open()) {
      instructions += BuildStatement();  // read ith statement.
    } else {
      SkipStatement();  // read ith statement.
    }
  }
  instructions += ExitScope(offset);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildEmptyStatement() {
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildAssertBlock() {
  if (!I->asserts()) {
    SkipStatementList();
    return Fragment();
  }

  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  intptr_t list_length = ReadListLength();  // read number of statements.
  for (intptr_t i = 0; i < list_length; ++i) {
    if (instructions.is_open()) {
      instructions += BuildStatement();  // read ith statement.
    } else {
      SkipStatement();  // read ith statement.
    }
  }
  instructions += ExitScope(offset);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAssertStatement() {
  if (!I->asserts()) {
    SetOffset(ReaderOffset() - 1);  // Include the tag.
    SkipStatement();                // read this statement.
    return Fragment();
  }

  TargetEntryInstr* then;
  TargetEntryInstr* otherwise;

  Fragment instructions;
  // Asserts can be of the following two kinds:
  //
  //    * `assert(expr)`
  //    * `assert(() { ... })`
  //
  // The call to `_AssertionError._evaluateAssertion()` will take care of both
  // and returns a boolean.
  instructions += BuildExpression();  // read condition.

  const TokenPosition condition_start_offset =
      ReadPosition();  // read condition start offset.
  const TokenPosition condition_end_offset =
      ReadPosition();  // read condition end offset.

  instructions += PushArgument();
  instructions += EvaluateAssertion();
  instructions += CheckBoolean(condition_start_offset);
  instructions += Constant(Bool::True());
  instructions += BranchIfEqual(&then, &otherwise, false);

  const Class& klass =
      Class::ZoneHandle(Z, Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const Function& target = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!target.IsNull());

  // Build equivalent of `throw _AssertionError._throwNew(start, end, message)`
  // expression. We build throw (even through _throwNew already throws) because
  // call is not a valid last instruction for the block. Blocks can only
  // terminate with explicit control flow instructions (Branch, Goto, Return
  // or Throw).
  Fragment otherwise_fragment(otherwise);
  otherwise_fragment += IntConstant(condition_start_offset.Pos());
  otherwise_fragment += PushArgument();  // start
  otherwise_fragment += IntConstant(condition_end_offset.Pos());
  otherwise_fragment += PushArgument();  // end
  Tag tag = ReadTag();                   // read (first part of) message.
  if (tag == kSomething) {
    otherwise_fragment += BuildExpression();  // read (rest of) message.
  } else {
    otherwise_fragment += Constant(Instance::ZoneHandle(Z));  // null.
  }
  otherwise_fragment += PushArgument();  // message

  // Note: condition_start_offset points to the first token after the opening
  // paren, not the beginning of 'assert'.
  otherwise_fragment +=
      StaticCall(condition_start_offset, target, 3, ICData::kStatic);
  otherwise_fragment += PushArgument();
  otherwise_fragment += ThrowException(TokenPosition::kNoSource);
  otherwise_fragment += Drop();

  return Fragment(instructions.entry, then);
}

Fragment StreamingFlowGraphBuilder::BuildLabeledStatement() {
  // There can be serveral cases:
  //
  //   * the body contains a break
  //   * the body doesn't contain a break
  //
  //   * translating the body results in a closed fragment
  //   * translating the body results in a open fragment
  //
  // => We will only know which case we are in after the body has been
  //    traversed.

  BreakableBlock block(flow_graph_builder_);
  Fragment instructions = BuildStatement();  // read body.
  if (block.HadJumper()) {
    if (instructions.is_open()) {
      instructions += Goto(block.destination());
    }
    return Fragment(instructions.entry, block.destination());
  } else {
    return instructions;
  }
}

Fragment StreamingFlowGraphBuilder::BuildBreakStatement() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t target_index = ReadUInt();       // read target index.

  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* destination = breakable_block()->BreakDestination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  // Break statement should pause before manipulation of context, which
  // will possibly cause debugger having incorrect context object.
  if (NeedsDebugStepCheck(parsed_function()->function(), position)) {
    instructions += DebugStepCheck(position);
  }
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    instructions += Goto(destination);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildWhileStatement() {
  ASSERT(block_expression_depth() == 0);  // no while in block-expr
  loop_depth_inc();
  const TokenPosition position = ReadPosition();            // read position.
  TestFragment condition = TranslateConditionForControl();  // read condition.
  const Fragment body = BuildStatement();                   // read body

  Fragment body_entry(condition.CreateTrueSuccessor(flow_graph_builder_));
  body_entry += body;

  Instruction* entry;
  if (body_entry.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    body_entry += Goto(join);

    Fragment loop(join);
    ASSERT(B->GetStackDepth() == 0);
    loop += CheckStackOverflow(position);
    loop.current->LinkTo(condition.entry);

    entry = Goto(join).entry;
  } else {
    entry = condition.entry;
  }

  loop_depth_dec();
  return Fragment(entry, condition.CreateFalseSuccessor(flow_graph_builder_));
}

Fragment StreamingFlowGraphBuilder::BuildDoStatement() {
  ASSERT(block_expression_depth() == 0);  // no do-while in block-expr
  loop_depth_inc();
  const TokenPosition position = ReadPosition();  // read position.
  Fragment body = BuildStatement();               // read body.

  if (body.is_closed()) {
    SkipExpression();  // read condition.
    loop_depth_dec();
    return body;
  }

  TestFragment condition = TranslateConditionForControl();

  JoinEntryInstr* join = BuildJoinEntry();
  Fragment loop(join);
  ASSERT(B->GetStackDepth() == 0);
  loop += CheckStackOverflow(position);
  loop += body;
  loop <<= condition.entry;

  condition.IfTrueGoto(flow_graph_builder_, join);

  loop_depth_dec();
  return Fragment(
      new (Z) GotoInstr(join, CompilerState::Current().GetNextDeoptId()),
      condition.CreateFalseSuccessor(flow_graph_builder_));
}

Fragment StreamingFlowGraphBuilder::BuildForStatement() {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  const TokenPosition position = ReadPosition();  // read position.

  Fragment declarations;

  loop_depth_inc();

  const LocalScope* context_scope = nullptr;
  declarations += EnterScope(offset, &context_scope);

  intptr_t list_length = ReadListLength();  // read number of variables.
  for (intptr_t i = 0; i < list_length; ++i) {
    declarations += BuildVariableDeclaration();  // read ith variable.
  }

  Tag tag = ReadTag();  // Read first part of condition.
  TestFragment condition;
  BlockEntryInstr* body_entry;
  BlockEntryInstr* loop_exit;
  if (tag != kNothing) {
    condition = TranslateConditionForControl();
    body_entry = condition.CreateTrueSuccessor(flow_graph_builder_);
    loop_exit = condition.CreateFalseSuccessor(flow_graph_builder_);
  } else {
    body_entry = BuildJoinEntry();
    loop_exit = BuildJoinEntry();
  }

  Fragment updates;
  list_length = ReadListLength();  // read number of updates.
  for (intptr_t i = 0; i < list_length; ++i) {
    updates += BuildExpression();  // read ith update.
    updates += Drop();
  }

  Fragment body(body_entry);
  body += BuildStatement();  // read body.

  if (body.is_open()) {
    // We allocated a fresh context before the loop which contains captured
    // [ForStatement] variables.  Before jumping back to the loop entry we clone
    // the context object (at same depth) which ensures the next iteration of
    // the body gets a fresh set of [ForStatement] variables (with the old
    // (possibly updated) values).
    if (context_scope->num_context_variables() > 0) {
      body += CloneContext(context_scope->context_slots());
    }

    body += updates;
    JoinEntryInstr* join = BuildJoinEntry();
    declarations += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow(position);  // may have non-empty stack
    if (condition.entry != nullptr) {
      loop <<= condition.entry;
    } else {
      loop += Goto(body_entry->AsJoinEntry());
    }
  } else {
    if (condition.entry != nullptr) {
      declarations <<= condition.entry;
    } else {
      declarations += Goto(body_entry->AsJoinEntry());
    }
  }

  Fragment loop(declarations.entry, loop_exit);

  loop += ExitScope(offset);

  loop_depth_dec();

  return loop;
}

Fragment StreamingFlowGraphBuilder::BuildForInStatement(bool async) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  const TokenPosition position = ReadPosition();  // read position.
  TokenPosition body_position = ReadPosition();   // read body position.
  intptr_t variable_kernel_position = ReaderOffset() + data_program_offset_;
  SkipVariableDeclaration();  // read variable.

  TokenPosition iterable_position = TokenPosition::kNoSource;
  Fragment instructions =
      BuildExpression(&iterable_position);  // read iterable.
  instructions += PushArgument();

  const String& iterator_getter =
      String::ZoneHandle(Z, Field::GetterSymbol(Symbols::Iterator()));
  instructions +=
      InstanceCall(iterable_position, iterator_getter, Token::kGET, 1);
  LocalVariable* iterator = scopes()->iterator_variables[for_in_depth()];
  instructions += StoreLocal(TokenPosition::kNoSource, iterator);
  instructions += Drop();

  for_in_depth_inc();
  loop_depth_inc();
  Fragment condition = LoadLocal(iterator);
  condition += PushArgument();
  condition +=
      InstanceCall(iterable_position, Symbols::MoveNext(), Token::kILLEGAL, 1);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, false);

  Fragment body(body_entry);
  body += EnterScope(offset);
  body += LoadLocal(iterator);
  body += PushArgument();
  const String& current_getter =
      String::ZoneHandle(Z, Field::GetterSymbol(Symbols::Current()));
  body += InstanceCall(body_position, current_getter, Token::kGET, 1);
  body += StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(variable_kernel_position));
  body += Drop();
  body += BuildStatement();  // read body.
  body += ExitScope(offset);

  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    instructions += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow(position);  // may have non-empty stack
    loop += condition;
  } else {
    instructions += condition;
  }

  loop_depth_dec();
  for_in_depth_dec();
  return Fragment(instructions.entry, loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildSwitchStatement() {
  ReadPosition();  // read position.
  // We need the number of cases. So start by getting that, then go back.
  intptr_t offset = ReaderOffset();
  SkipExpression();                   // temporarily skip condition
  int case_count = ReadListLength();  // read number of cases.
  SetOffset(offset);

  SwitchBlock block(flow_graph_builder_, case_count);

  // Instead of using a variable we should reuse the expression on the stack,
  // since it won't be assigned again, we don't need phi nodes.
  Fragment head_instructions = BuildExpression();  // read condition.
  head_instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
  head_instructions += Drop();

  case_count = ReadListLength();  // read number of cases.

  // Phase 1: Generate bodies and try to find out whether a body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  Fragment* body_fragments = Z->Alloc<Fragment>(case_count);
  intptr_t* case_expression_offsets = Z->Alloc<intptr_t>(case_count);
  int default_case = -1;

  for (intptr_t i = 0; i < case_count; ++i) {
    case_expression_offsets[i] = ReaderOffset();
    int expression_count = ReadListLength();  // read number of expressions.
    for (intptr_t j = 0; j < expression_count; ++j) {
      ReadPosition();    // read jth position.
      SkipExpression();  // read jth expression.
    }
    bool is_default = ReadBool();  // read is_default.
    if (is_default) default_case = i;
    Fragment& body_fragment = body_fragments[i] =
        BuildStatement();  // read body.

    if (body_fragment.entry == NULL) {
      // Make a NOP in order to ensure linking works properly.
      body_fragment = NullConstant();
      body_fragment += Drop();
    }

    // The Dart language specification mandates fall-throughs in [SwitchCase]es
    // to be runtime errors.
    if (!is_default && body_fragment.is_open() && (i < (case_count - 1))) {
      const Class& klass = Class::ZoneHandle(
          Z, Library::LookupCoreClass(Symbols::FallThroughError()));
      ASSERT(!klass.IsNull());

      GrowableHandlePtrArray<const String> pieces(Z, 3);
      pieces.Add(Symbols::FallThroughError());
      pieces.Add(Symbols::Dot());
      pieces.Add(H.DartSymbolObfuscate("_create"));

      const Function& constructor = Function::ZoneHandle(
          Z, klass.LookupConstructorAllowPrivate(String::ZoneHandle(
                 Z, Symbols::FromConcatAll(H.thread(), pieces))));
      ASSERT(!constructor.IsNull());
      const String& url = H.DartString(
          parsed_function()->function().ToLibNamePrefixedQualifiedCString(),
          Heap::kOld);

      // Create instance of _FallThroughError
      body_fragment += AllocateObject(TokenPosition::kNoSource, klass, 0);
      LocalVariable* instance = MakeTemporary();

      // Call _FallThroughError._create constructor.
      body_fragment += LoadLocal(instance);
      body_fragment += PushArgument();  // this

      body_fragment += Constant(url);
      body_fragment += PushArgument();  // url

      body_fragment += NullConstant();
      body_fragment += PushArgument();  // line

      body_fragment +=
          StaticCall(TokenPosition::kNoSource, constructor, 3, ICData::kStatic);
      body_fragment += Drop();

      // Throw the exception
      body_fragment += PushArgument();
      body_fragment += ThrowException(TokenPosition::kNoSource);
      body_fragment += Drop();
    }

    // If there is an implicit fall-through we have one [SwitchCase] and
    // multiple expressions, e.g.
    //
    //    switch(expr) {
    //      case a:
    //      case b:
    //        <stmt-body>
    //    }
    //
    // This means that the <stmt-body> will have more than 1 incoming edge (one
    // from `a == expr` and one from `a != expr && b == expr`). The
    // `block.Destination()` records the additional jump.
    if (expression_count > 1) {
      block.DestinationDirect(i);
    }
  }

  intptr_t end_offset = ReaderOffset();

  // Phase 2: Generate everything except the real bodies:
  //   * jump directly to a body (if there is no jumper)
  //   * jump to a wrapper block which jumps to the body (if there is a jumper)
  Fragment current_instructions = head_instructions;
  for (intptr_t i = 0; i < case_count; ++i) {
    SetOffset(case_expression_offsets[i]);
    int expression_count = ReadListLength();  // read length of expressions.

    if (i == default_case) {
      ASSERT(i == (case_count - 1));

      // Evaluate the conditions for the default [SwitchCase] just for the
      // purpose of potentially triggering a compile-time error.

      for (intptr_t j = 0; j < expression_count; ++j) {
        ReadPosition();  // read jth position.
        // this reads the expression, but doesn't skip past it.
        constant_evaluator_.EvaluateExpression(ReaderOffset());
        SkipExpression();  // read jth expression.
      }

      if (block.HadJumper(i)) {
        // There are several branches to the body, so we will make a goto to
        // the join block (and prepend a join instruction to the real body).
        JoinEntryInstr* join = block.DestinationDirect(i);
        current_instructions += Goto(join);

        current_instructions = Fragment(current_instructions.entry, join);
        current_instructions += body_fragments[i];
      } else {
        current_instructions += body_fragments[i];
      }
    } else {
      JoinEntryInstr* body_join = NULL;
      if (block.HadJumper(i)) {
        body_join = block.DestinationDirect(i);
        body_fragments[i] = Fragment(body_join) + body_fragments[i];
      }

      for (intptr_t j = 0; j < expression_count; ++j) {
        TargetEntryInstr* then;
        TargetEntryInstr* otherwise;

        TokenPosition position = ReadPosition();  // read jth position.
        current_instructions += Constant(Instance::ZoneHandle(
            Z, constant_evaluator_.EvaluateExpression(ReaderOffset())));
        SkipExpression();  // read jth expression.
        current_instructions += PushArgument();
        current_instructions += LoadLocal(scopes()->switch_variable);
        current_instructions += PushArgument();
        current_instructions +=
            InstanceCall(position, Symbols::EqualOperator(), Token::kEQ,
                         /*argument_count=*/2,
                         /*checked_argument_count=*/2);
        current_instructions += BranchIfTrue(&then, &otherwise, false);

        Fragment then_fragment(then);

        if (body_join != NULL) {
          // There are several branches to the body, so we will make a goto to
          // the join block (the real body has already been prepended with a
          // join instruction).
          then_fragment += Goto(body_join);
        } else {
          // There is only a signle branch to the body, so we will just append
          // the body fragment.
          then_fragment += body_fragments[i];
        }

        current_instructions = Fragment(otherwise);
      }
    }
  }

  if (case_count > 0 && default_case < 0) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = body_fragments[case_count - 1];
    if (last_body.is_open()) {
      ASSERT(current_instructions.is_open());
      ASSERT(current_instructions.current->IsTargetEntry());

      // Join the last "otherwise" branch and the last [SwitchCase] fragment.
      JoinEntryInstr* join = BuildJoinEntry();
      current_instructions += Goto(join);
      last_body += Goto(join);

      current_instructions = Fragment(join);
    }
  } else {
    // All non-default cases will be closed (i.e. break/continue/throw/return)
    // So it is fine to just let more statements after the switch append to the
    // default case.
  }

  SetOffset(end_offset);
  return Fragment(head_instructions.entry, current_instructions.current);
}

Fragment StreamingFlowGraphBuilder::BuildContinueSwitchStatement() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t target_index = ReadUInt();       // read target index.

  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* entry = switch_block()->Destination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    if (NeedsDebugStepCheck(parsed_function()->function(), position)) {
      instructions += DebugStepCheck(position);
    }
    instructions += Goto(entry);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIfStatement() {
  ReadPosition();  // read position.

  TestFragment condition = TranslateConditionForControl();

  Fragment then_fragment(condition.CreateTrueSuccessor(flow_graph_builder_));
  then_fragment += BuildStatement();  // read then.

  Fragment otherwise_fragment(
      condition.CreateFalseSuccessor(flow_graph_builder_));
  otherwise_fragment += BuildStatement();  // read otherwise.

  if (then_fragment.is_open()) {
    if (otherwise_fragment.is_open()) {
      JoinEntryInstr* join = BuildJoinEntry();
      then_fragment += Goto(join);
      otherwise_fragment += Goto(join);
      return Fragment(condition.entry, join);
    } else {
      return Fragment(condition.entry, then_fragment.current);
    }
  } else if (otherwise_fragment.is_open()) {
    return Fragment(condition.entry, otherwise_fragment.current);
  } else {
    return Fragment(condition.entry, nullptr);
  }
}

Fragment StreamingFlowGraphBuilder::BuildReturnStatement() {
  TokenPosition position = ReadPosition();  // read position.
  Tag tag = ReadTag();                      // read first part of expression.

  bool inside_try_finally = try_finally_block() != NULL;

  Fragment instructions = tag == kNothing
                              ? NullConstant()
                              : BuildExpression();  // read rest of expression.

  if (instructions.is_open()) {
    if (inside_try_finally) {
      ASSERT(scopes()->finally_return_variable != NULL);
      const Function& function = parsed_function()->function();
      if (NeedsDebugStepCheck(function, position)) {
        instructions += DebugStepCheck(position);
      }
      instructions += StoreLocal(position, scopes()->finally_return_variable);
      instructions += Drop();
      instructions += TranslateFinallyFinalizers(NULL, -1);
      if (instructions.is_open()) {
        instructions += LoadLocal(scopes()->finally_return_variable);
        instructions += Return(TokenPosition::kNoSource);
      }
    } else {
      instructions += Return(position);
    }
  } else {
    Pop();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildTryCatch() {
  ASSERT(block_expression_depth() == 0);  // no try-catch in block-expr
  InlineBailout("kernel::FlowgraphBuilder::VisitTryCatch");

  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  try_depth_inc();
  {
    TryCatchBlock block(flow_graph_builder_, try_handler_index);
    try_body += BuildStatement();  // read body.
    try_body += Goto(after_try);
  }
  try_depth_dec();

  const int kNeedsStracktraceBit = 1 << 0;
  const int kIsSyntheticBit = 1 << 1;

  uint8_t flags = ReadByte();
  bool needs_stacktrace =
      (flags & kNeedsStracktraceBit) == kNeedsStracktraceBit;
  bool is_synthetic = (flags & kIsSyntheticBit) == kIsSyntheticBit;

  catch_depth_inc();
  intptr_t catch_count = ReadListLength();  // read number of catches.
  const Array& handler_types =
      Array::ZoneHandle(Z, Array::New(catch_count, Heap::kOld));

  Fragment catch_body = CatchBlockEntry(handler_types, try_handler_index,
                                        needs_stacktrace, is_synthetic);
  // Fill in the body of the catch.
  for (intptr_t i = 0; i < catch_count; ++i) {
    intptr_t catch_offset = ReaderOffset();   // Catch has no tag.
    TokenPosition position = ReadPosition();  // read position.
    Tag tag = PeekTag();                      // peek guard type.
    AbstractType* type_guard = NULL;
    if (tag != kDynamicType) {
      type_guard = &T.BuildType();  // read guard.
      handler_types.SetAt(i, *type_guard);
    } else {
      SkipDartType();  // read guard.
      handler_types.SetAt(i, Object::dynamic_type());
    }

    Fragment catch_handler_body = EnterScope(catch_offset);

    tag = ReadTag();  // read first part of exception.
    if (tag == kSomething) {
      catch_handler_body += LoadLocal(CurrentException());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(ReaderOffset() + data_program_offset_));
      catch_handler_body += Drop();
      SkipVariableDeclaration();  // read exception.
    }

    tag = ReadTag();  // read first part of stack trace.
    if (tag == kSomething) {
      catch_handler_body += LoadLocal(CurrentStackTrace());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(ReaderOffset() + data_program_offset_));
      catch_handler_body += Drop();
      SkipVariableDeclaration();  // read stack trace.
    }

    {
      CatchBlock block(flow_graph_builder_, CurrentException(),
                       CurrentStackTrace(), try_handler_index);

      catch_handler_body += BuildStatement();  // read body.

      // Note: ExitScope adjusts context_depth_ so even if catch_handler_body
      // is closed we still need to execute ExitScope for its side effect.
      catch_handler_body += ExitScope(catch_offset);
      if (catch_handler_body.is_open()) {
        catch_handler_body += Goto(after_try);
      }
    }

    if (type_guard != NULL) {
      catch_body += LoadLocal(CurrentException());
      catch_body += PushArgument();  // exception
      if (!type_guard->IsInstantiated(kCurrentClass)) {
        catch_body += LoadInstantiatorTypeArguments();
      } else {
        catch_body += NullConstant();
      }
      catch_body += PushArgument();  // instantiator type arguments
      if (!type_guard->IsInstantiated(kFunctions)) {
        catch_body += LoadFunctionTypeArguments();
      } else {
        catch_body += NullConstant();
      }
      catch_body += PushArgument();  // function type arguments
      catch_body += Constant(*type_guard);
      catch_body += PushArgument();  // guard type
      catch_body += InstanceCall(
          position, Library::PrivateCoreLibName(Symbols::_instanceOf()),
          Token::kIS, 4);

      TargetEntryInstr* catch_entry;
      TargetEntryInstr* next_catch_entry;
      catch_body += BranchIfTrue(&catch_entry, &next_catch_entry, false);

      Fragment(catch_entry) + catch_handler_body;
      catch_body = Fragment(next_catch_entry);
    } else {
      catch_body += catch_handler_body;
    }
  }

  // In case the last catch body was not handling the exception and branching to
  // after the try block, we will rethrow the exception (i.e. no default catch
  // handler).
  if (catch_body.is_open()) {
    catch_body += LoadLocal(CurrentException());
    catch_body += PushArgument();
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += PushArgument();
    catch_body += RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildTryFinally() {
  ASSERT(block_expression_depth() == 0);  // no try-finally in block-expr
  // Note on streaming:
  // We only stream this TryFinally if we can stream everything inside it,
  // so creating a "TryFinallyBlock" with a kernel binary offset instead of an
  // AST node isn't a problem.

  InlineBailout("kernel::FlowgraphBuilder::VisitTryFinally");

  // There are 5 different cases where we need to execute the finally block:
  //
  //  a) 1/2/3th case: Special control flow going out of `node->body()`:
  //
  //   * [BreakStatement] transfers control to a [LabeledStatement]
  //   * [ContinueSwitchStatement] transfers control to a [SwitchCase]
  //   * [ReturnStatement] returns a value
  //
  //   => All three cases will automatically append all finally blocks
  //      between the branching point and the destination (so we don't need to
  //      do anything here).
  //
  //  b) 4th case: Translating the body resulted in an open fragment (i.e. body
  //               executes without any control flow out of it)
  //
  //   => We are responsible for jumping out of the body to a new block (with
  //      different try index) and execute the finalizer.
  //
  //  c) 5th case: An exception occurred inside the body.
  //
  //   => We are responsible for catching it, executing the finally block and
  //      rethrowing the exception.
  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  intptr_t offset = ReaderOffset();
  SkipStatement();  // temporarily read body.
  intptr_t finalizer_offset = ReaderOffset();
  SetOffset(offset);

  // Fill in the body of the try.
  try_depth_inc();
  {
    TryFinallyBlock tfb(flow_graph_builder_, finalizer_offset);
    TryCatchBlock tcb(flow_graph_builder_, try_handler_index);
    try_body += BuildStatement();  // read body.
  }
  try_depth_dec();

  if (try_body.is_open()) {
    // Please note: The try index will be on level out of this block,
    // thereby ensuring if there's an exception in the finally block we
    // won't run it twice.
    JoinEntryInstr* finally_entry = BuildJoinEntry();

    try_body += Goto(finally_entry);

    Fragment finally_body(finally_entry);
    finally_body += BuildStatement();  // read finalizer.
    finally_body += Goto(after_try);
  }

  // Fill in the body of the catch.
  catch_depth_inc();
  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, Object::dynamic_type());
  // Note: rethrow will actually force mark the handler as needing a stacktrace.
  Fragment finally_body = CatchBlockEntry(handler_types, try_handler_index,
                                          /* needs_stacktrace = */ false,
                                          /* is_synthesized = */ true);
  SetOffset(finalizer_offset);
  finally_body += BuildStatement();  // read finalizer
  if (finally_body.is_open()) {
    finally_body += LoadLocal(CurrentException());
    finally_body += PushArgument();
    finally_body += LoadLocal(CurrentStackTrace());
    finally_body += PushArgument();
    finally_body +=
        RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildYieldStatement() {
  TokenPosition position = ReadPosition();  // read position.
  uint8_t flags = ReadByte();               // read flags.

  ASSERT(flags == kNativeYieldFlags);  // Must have been desugared.

  // Collect yield position
  if (record_yield_positions_ != nullptr) {
    record_yield_positions_->Add(Smi::Handle(Z, Smi::New(position.value())));
  }
  // Setup yield/continue point:
  //
  //   ...
  //   :await_jump_var = index;
  //   :await_ctx_var = :current_context_var
  //   return <expr>
  //
  // Continuation<index>:
  //   Drop(1)
  //   ...
  //
  // BuildGraphOfFunction will create a dispatch that jumps to
  // Continuation<:await_jump_var> upon entry to the function.
  //
  Fragment instructions = IntConstant(yield_continuations().length() + 1);
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->yield_jump_variable);
  instructions += Drop();
  instructions += LoadLocal(parsed_function()->current_context_var());
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->yield_context_variable);
  instructions += Drop();
  instructions += BuildExpression();  // read expression.
  instructions += Return(position);

  // Note: DropTempsInstr serves as an anchor instruction. It will not
  // be linked into the resulting graph.
  DropTempsInstr* anchor = new (Z) DropTempsInstr(0, NULL);
  yield_continuations().Add(YieldContinuation(anchor, CurrentTryIndex()));

  Fragment continuation(instructions.entry, anchor);

  if (parsed_function()->function().IsAsyncClosure() ||
      parsed_function()->function().IsAsyncGenClosure()) {
    // If function is async closure or async gen closure it takes three
    // parameters where the second and the third are exception and stack_trace.
    // Check if exception is non-null and rethrow it.
    //
    //   :async_op([:result, :exception, :stack_trace]) {
    //     ...
    //     Continuation<index>:
    //       if (:exception != null) rethrow(:exception, :stack_trace);
    //     ...
    //   }
    //
    LocalVariable* exception_var = parsed_function()->ParameterVariable(2);
    LocalVariable* stack_trace_var = parsed_function()->ParameterVariable(3);
    ASSERT(exception_var->name().raw() == Symbols::ExceptionParameter().raw());
    ASSERT(stack_trace_var->name().raw() ==
           Symbols::StackTraceParameter().raw());

    TargetEntryInstr* no_error;
    TargetEntryInstr* error;

    continuation += LoadLocal(exception_var);
    continuation += BranchIfNull(&no_error, &error);

    Fragment rethrow(error);
    rethrow += LoadLocal(exception_var);
    rethrow += PushArgument();
    rethrow += LoadLocal(stack_trace_var);
    rethrow += PushArgument();
    rethrow += RethrowException(position, kInvalidTryIndex);
    Drop();

    continuation = Fragment(continuation.entry, no_error);
  }

  return continuation;
}

Fragment StreamingFlowGraphBuilder::BuildVariableDeclaration() {
  intptr_t kernel_position_no_tag = ReaderOffset() + data_program_offset_;
  LocalVariable* variable = LookupVariable(kernel_position_no_tag);

  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  T.BuildType();        // read type.
  Tag tag = ReadTag();  // read (first part of) initializer.

  Fragment instructions;
  if (tag == kNothing) {
    instructions += NullConstant();
  } else {
    if (helper.IsConst()) {
      const Instance& constant_value = Instance::ZoneHandle(
          Z, constant_evaluator_.EvaluateExpression(
                 ReaderOffset()));  // read initializer form current position.
      variable->SetConstValue(constant_value);
      instructions += Constant(constant_value);
      SkipExpression();  // skip initializer.
    } else {
      // Initializer
      instructions += BuildExpression();  // read (actual) initializer.
    }
  }

  // Use position of equal sign if it exists. If the equal sign does not exist
  // use the position of the identifier.
  TokenPosition debug_position =
      Utils::Maximum(helper.position_, helper.equals_position_);
  if (NeedsDebugStepCheck(stack(), debug_position)) {
    instructions = DebugStepCheck(debug_position) + instructions;
  }
  instructions += StoreLocal(helper.position_, variable);
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionDeclaration() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t variable_offset = ReaderOffset() + data_program_offset_;

  // read variable declaration.
  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

  Fragment instructions = DebugStepCheck(position);
  instructions += BuildFunctionNode(position, helper.name_index_);
  instructions += StoreLocal(position, LookupVariable(variable_offset));
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionNode(
    TokenPosition parent_position,
    StringIndex name_index) {
  intptr_t offset = ReaderOffset();

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  TokenPosition position = function_node_helper.position_;

  bool declaration = name_index >= 0;

  if (declaration) {
    position = parent_position;
  }
  if (!position.IsReal()) {
    // Positions has to be unique in regards to the parent.
    // A non-real at this point is probably -1, we cannot blindly use that
    // as others might use it too. Create a new dummy non-real TokenPosition.
    position = TokenPosition(offset).ToSynthetic();
  }

  // The VM has a per-isolate table of functions indexed by the enclosing
  // function and token position.
  Function& function = Function::ZoneHandle(Z);

  // NOTE: This is not TokenPosition in the general sense!
  function = I->LookupClosureFunction(parsed_function()->function(), position);
  if (function.IsNull()) {
    for (intptr_t i = 0; i < scopes()->function_scopes.length(); ++i) {
      if (scopes()->function_scopes[i].kernel_offset != offset) {
        continue;
      }

      const String* name;
      if (declaration) {
        name = &H.DartSymbolObfuscate(name_index);
      } else {
        name = &Symbols::AnonymousClosure();
      }
      // NOTE: This is not TokenPosition in the general sense!
      if (!closure_owner_.IsNull()) {
        function = Function::NewClosureFunctionWithKind(
            RawFunction::kClosureFunction, *name, parsed_function()->function(),
            position, closure_owner_);
      } else {
        function = Function::NewClosureFunction(
            *name, parsed_function()->function(), position);
      }

      function.set_is_debuggable(function_node_helper.dart_async_marker_ ==
                                 FunctionNodeHelper::kSync);
      switch (function_node_helper.dart_async_marker_) {
        case FunctionNodeHelper::kSyncStar:
          function.set_modifier(RawFunction::kSyncGen);
          break;
        case FunctionNodeHelper::kAsync:
          function.set_modifier(RawFunction::kAsync);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        case FunctionNodeHelper::kAsyncStar:
          function.set_modifier(RawFunction::kAsyncGen);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        default:
          // no special modifier
          break;
      }
      function.set_is_generated_body(function_node_helper.async_marker_ ==
                                     FunctionNodeHelper::kSyncYielding);
      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        function.set_is_inlinable(!FLAG_causal_async_stacks);
      }

      function.set_end_token_pos(function_node_helper.end_position_);
      LocalScope* scope = scopes()->function_scopes[i].scope;
      const ContextScope& context_scope = ContextScope::Handle(
          Z, scope->PreserveOuterScope(flow_graph_builder_->context_depth_));
      function.set_context_scope(context_scope);
      function.set_kernel_offset(offset);
      type_translator_.SetupFunctionParameters(Class::Handle(Z), function,
                                               false,  // is_method
                                               true,   // is_closure
                                               &function_node_helper);
      function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

      // Finalize function type.
      Type& signature_type = Type::Handle(Z, function.SignatureType());
      signature_type ^=
          ClassFinalizer::FinalizeType(*active_class()->klass, signature_type);
      function.SetSignatureType(signature_type);

      I->AddClosureFunction(function);
      break;
    }
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

  Fragment instructions =
      flow_graph_builder_->AllocateClosure(TokenPosition::kNoSource, function);
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  if (!function.HasInstantiatedSignature(kCurrentClass)) {
    instructions += LoadLocal(closure);
    instructions += LoadInstantiatorTypeArguments();
    instructions += flow_graph_builder_->StoreInstanceField(
        TokenPosition::kNoSource, Slot::Closure_instantiator_type_arguments());
  }

  // TODO(30455): We only need to save these if the closure uses any captured
  // type parameters.
  instructions += LoadLocal(closure);
  instructions += LoadFunctionTypeArguments();
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_function_type_arguments());

  instructions += LoadLocal(closure);
  instructions += Constant(Object::empty_type_arguments());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_delayed_type_arguments());

  // Store the function and the context in the closure.
  instructions += LoadLocal(closure);
  instructions += Constant(function);
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_function());

  instructions += LoadLocal(closure);
  instructions += LoadLocal(parsed_function()->current_context_var());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Slot::Closure_context());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFfiAsFunctionInternal() {
  const intptr_t argc = ReadUInt();               // read argument count.
  ASSERT(argc == 1);                              // pointer
  const intptr_t list_length = ReadListLength();  // read types list length.
  ASSERT(list_length == 2);  // dart signature, then native signature
  const TypeArguments& type_arguments =
      T.BuildTypeArguments(list_length);  // read types.
  Fragment code;
  const intptr_t positional_count =
      ReadListLength();  // read positional argument count
  ASSERT(positional_count == 1);
  code += BuildExpression();  // build first positional argument (pointer)
  const intptr_t named_args_len =
      ReadListLength();  // skip (empty) named arguments list
  ASSERT(named_args_len == 0);
  code += B->BuildFfiAsFunctionInternalCall(type_arguments);
  return code;
}

Fragment StreamingFlowGraphBuilder::BuildFfiNativeCallbackFunction() {
#if defined(TARGET_ARCH_DBC)
  UNREACHABLE();
#else
  // The call-site must look like this (guaranteed by the FE which inserts it):
  //
  //   _nativeCallbackFunction<NativeSignatureType>(target, exceptionalReturn)
  //
  // The FE also guarantees that all three arguments are constants.

  const intptr_t argc = ReadUInt();  // read argument count
  ASSERT(argc == 2);                 // target, exceptionalReturn

  const intptr_t list_length = ReadListLength();  // read types list length
  ASSERT(list_length == 1);                       // native signature
  const TypeArguments& type_arguments =
      T.BuildTypeArguments(list_length);  // read types.
  ASSERT(type_arguments.Length() == 1 && type_arguments.IsInstantiated());
  const Function& native_sig = Function::Handle(
      Z, Type::Cast(AbstractType::Handle(Z, type_arguments.TypeAt(0)))
             .signature());

  Fragment code;
  const intptr_t positional_count =
      ReadListLength();  // read positional argument count
  ASSERT(positional_count == 2);

  // Read target expression and extract the target function.
  code += BuildExpression();  // build first positional argument (target)
  Definition* target_def = B->Peek();
  ASSERT(target_def->IsConstant());
  const Closure& target_closure =
      Closure::Cast(target_def->AsConstant()->value());
  ASSERT(!target_closure.IsNull());
  Function& target = Function::Handle(Z, target_closure.function());
  ASSERT(!target.IsNull() && target.IsImplicitClosureFunction());
  target = target.parent_function();
  code += Drop();

  // Build second positional argument (exceptionalReturn).
  code += BuildExpression();
  Definition* exceptional_return_def = B->Peek();
  ASSERT(exceptional_return_def->IsConstant());
  const Instance& exceptional_return =
      Instance::Cast(exceptional_return_def->AsConstant()->value());
  code += Drop();

  const intptr_t named_args_len =
      ReadListLength();  // skip (empty) named arguments list
  ASSERT(named_args_len == 0);

  const Function& result =
      Function::ZoneHandle(Z, compiler::ffi::NativeCallbackFunction(
                                  native_sig, target, exceptional_return));
  code += Constant(result);
  return code;
#endif
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
