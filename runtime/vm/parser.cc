// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/parser.h"
#include "vm/flags.h"

#ifndef DART_PRECOMPILED_RUNTIME

#include "lib/invocation_mirror.h"
#include "platform/utils.h"
#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/frontend/scope_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/hash_table.h"
#include "vm/heap/heap.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/regexp_assembler.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timeline.h"
#include "vm/zone.h"

namespace dart {

// Quick access to the current thread, isolate and zone.
#define T (thread())
#define I (isolate())
#define Z (zone())

ParsedFunction::ParsedFunction(Thread* thread, const Function& function)
    : thread_(thread),
      function_(function),
      code_(Code::Handle(zone(), function.unoptimized_code())),
      scope_(NULL),
      regexp_compile_data_(NULL),
      function_type_arguments_(NULL),
      parent_type_arguments_(NULL),
      current_context_var_(NULL),
      arg_desc_var_(NULL),
      expression_temp_var_(NULL),
      entry_points_temp_var_(NULL),
      finally_return_temp_var_(NULL),
      guarded_fields_(new ZoneGrowableArray<const Field*>()),
      default_parameter_values_(NULL),
      raw_type_arguments_var_(NULL),
      first_parameter_index_(),
      num_stack_locals_(0),
      have_seen_await_expr_(false),
      kernel_scopes_(NULL),
      default_function_type_arguments_(TypeArguments::ZoneHandle(zone())) {
  ASSERT(function.IsZoneHandle());
  // Every function has a local variable for the current context.
  LocalVariable* temp = new (zone())
      LocalVariable(function.token_pos(), function.token_pos(),
                    Symbols::CurrentContextVar(), Object::dynamic_type());
  current_context_var_ = temp;

  const bool reify_generic_argument = function.IsGeneric();

  const bool load_optional_arguments = function.HasOptionalParameters();

  const bool check_arguments =
      function_.IsClosureFunction() || function.IsFfiTrampoline();

  const bool need_argument_descriptor =
      load_optional_arguments || check_arguments || reify_generic_argument;

  if (need_argument_descriptor) {
    arg_desc_var_ = new (zone())
        LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                      Symbols::ArgDescVar(), Object::dynamic_type());
  }
}

void ParsedFunction::AddToGuardedFields(const Field* field) const {
  if ((field->guarded_cid() == kDynamicCid) ||
      (field->guarded_cid() == kIllegalCid)) {
    return;
  }

  for (intptr_t j = 0; j < guarded_fields_->length(); j++) {
    const Field* other = (*guarded_fields_)[j];
    if (field->Original() == other->Original()) {
      // Abort background compilation early if the guarded state of this field
      // has changed during compilation. We will not be able to commit
      // the resulting code anyway.
      if (Compiler::IsBackgroundCompilation()) {
        if (!other->IsConsistentWith(*field)) {
          Compiler::AbortBackgroundCompilation(
              DeoptId::kNone,
              "Field's guarded state changed during compilation");
        }
      }
      return;
    }
  }

  // Note: the list of guarded fields must contain copies during background
  // compilation because we will look at their guarded_cid when copying
  // the array of guarded fields from callee into the caller during
  // inlining.
  ASSERT(!field->IsOriginal() || Thread::Current()->IsMutatorThread());
  guarded_fields_->Add(&Field::ZoneHandle(Z, field->raw()));
}

void ParsedFunction::Bailout(const char* origin, const char* reason) const {
  Report::MessageF(Report::kBailout, Script::Handle(function_.script()),
                   function_.token_pos(), Report::AtLocation,
                   "%s Bailout in %s: %s", origin,
                   String::Handle(function_.name()).ToCString(), reason);
  UNREACHABLE();
}

kernel::ScopeBuildingResult* ParsedFunction::EnsureKernelScopes() {
  if (kernel_scopes_ == NULL) {
    kernel::ScopeBuilder builder(this);
    kernel_scopes_ = builder.BuildScopes();
  }
  return kernel_scopes_;
}

LocalVariable* ParsedFunction::EnsureExpressionTemp() {
  if (!has_expression_temp_var()) {
    LocalVariable* temp =
        new (Z) LocalVariable(function_.token_pos(), function_.token_pos(),
                              Symbols::ExprTemp(), Object::dynamic_type());
    ASSERT(temp != NULL);
    set_expression_temp_var(temp);
  }
  ASSERT(has_expression_temp_var());
  return expression_temp_var();
}

LocalVariable* ParsedFunction::EnsureEntryPointsTemp() {
  if (!has_entry_points_temp_var()) {
    LocalVariable* temp = new (Z)
        LocalVariable(function_.token_pos(), function_.token_pos(),
                      Symbols::EntryPointsTemp(), Object::dynamic_type());
    ASSERT(temp != NULL);
    set_entry_points_temp_var(temp);
  }
  ASSERT(has_entry_points_temp_var());
  return entry_points_temp_var();
}

void ParsedFunction::EnsureFinallyReturnTemp(bool is_async) {
  if (!has_finally_return_temp_var()) {
    LocalVariable* temp =
        new (Z) LocalVariable(function_.token_pos(), function_.token_pos(),
                              Symbols::FinallyRetVal(), Object::dynamic_type());
    ASSERT(temp != NULL);
    temp->set_is_final();
    if (is_async) {
      temp->set_is_captured();
    }
    set_finally_return_temp_var(temp);
  }
  ASSERT(has_finally_return_temp_var());
}

void ParsedFunction::SetRegExpCompileData(
    RegExpCompileData* regexp_compile_data) {
  ASSERT(regexp_compile_data_ == NULL);
  ASSERT(regexp_compile_data != NULL);
  regexp_compile_data_ = regexp_compile_data;
}

void ParsedFunction::AllocateVariables() {
  ASSERT(!function().IsIrregexpFunction());
  LocalScope* scope = this->scope();
  const intptr_t num_fixed_params = function().num_fixed_parameters();
  const intptr_t num_opt_params = function().NumOptionalParameters();
  const intptr_t num_params = num_fixed_params + num_opt_params;

  // Before we start allocating indices to variables, we'll setup the
  // parameters array, which can be used to access the raw parameters (i.e. not
  // the potentially variables which are in the context)

  raw_parameters_ = new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_params);
  for (intptr_t param = 0; param < num_params; ++param) {
    LocalVariable* variable = ParameterVariable(param);
    LocalVariable* raw_parameter = variable;
    if (variable->is_captured()) {
      String& tmp = String::ZoneHandle(Z);
      tmp = Symbols::FromConcat(T, Symbols::OriginalParam(), variable->name());

      RELEASE_ASSERT(scope->LocalLookupVariable(tmp) == NULL);
      raw_parameter = new LocalVariable(
          variable->declaration_token_pos(), variable->token_pos(), tmp,
          variable->type(), variable->parameter_type(),
          variable->parameter_value());
      if (variable->is_explicit_covariant_parameter()) {
        raw_parameter->set_is_explicit_covariant_parameter();
      }
      raw_parameter->set_type_check_mode(variable->type_check_mode());
      if (function().HasOptionalParameters()) {
        bool ok = scope->AddVariable(raw_parameter);
        ASSERT(ok);

        // Currently our optimizer cannot prove liveness of variables properly
        // when a function has try/catch.  It therefore makes the conservative
        // estimate that all [LocalVariable]s in the frame are live and spills
        // them before call sites (in some shape or form).
        //
        // Since we are guaranteed to not need that, we tell the try/catch
        // sync moves mechanism not to care about this variable.
        //
        // Receiver (this variable) is an exception from this rule because
        // it is immutable and we don't reload captured it from the context but
        // instead use raw_parameter to access it. This means we must still
        // consider it when emitting the catch entry moves.
        const bool is_receiver_var =
            function().HasThisParameter() && receiver_var_ == variable;
        if (!is_receiver_var) {
          raw_parameter->set_is_captured_parameter(true);
        }

      } else {
        raw_parameter->set_index(
            VariableIndex(function().NumParameters() - param));
      }
    }
    raw_parameters_->Add(raw_parameter);
  }
  if (function_type_arguments_ != NULL) {
    LocalVariable* raw_type_args_parameter = function_type_arguments_;
    if (function_type_arguments_->is_captured()) {
      String& tmp = String::ZoneHandle(Z);
      tmp = Symbols::FromConcat(T, Symbols::OriginalParam(),
                                function_type_arguments_->name());

      ASSERT(scope->LocalLookupVariable(tmp) == NULL);
      raw_type_args_parameter =
          new LocalVariable(raw_type_args_parameter->declaration_token_pos(),
                            raw_type_args_parameter->token_pos(), tmp,
                            raw_type_args_parameter->type());
      bool ok = scope->AddVariable(raw_type_args_parameter);
      ASSERT(ok);
    }
    raw_type_arguments_var_ = raw_type_args_parameter;
  }

  // The copy parameters implementation will still write to local variables
  // which we assign indices as with the old CopyParams implementation.
  VariableIndex parameter_index_start;
  VariableIndex reamining_local_variables_start;
  {
    // Compute start indices to parameters and locals, and the number of
    // parameters to copy.
    if (num_opt_params == 0) {
      parameter_index_start = first_parameter_index_ =
          VariableIndex(num_params);
      reamining_local_variables_start = VariableIndex(0);
    } else {
      parameter_index_start = first_parameter_index_ = VariableIndex(0);
      reamining_local_variables_start = VariableIndex(-num_params);
    }
  }

  if (function_type_arguments_ != NULL && num_opt_params > 0) {
    reamining_local_variables_start =
        VariableIndex(reamining_local_variables_start.value() - 1);
  }

  // Allocate parameters and local variables, either in the local frame or
  // in the context(s).
  bool found_captured_variables = false;
  VariableIndex first_local_index =
      VariableIndex(parameter_index_start.value() > 0 ? 0 : -num_params);
  VariableIndex next_free_index = scope->AllocateVariables(
      parameter_index_start, num_params, first_local_index, NULL,
      &found_captured_variables);

  num_stack_locals_ = -next_free_index.value();
}

void ParsedFunction::AllocateIrregexpVariables(intptr_t num_stack_locals) {
  ASSERT(function().IsIrregexpFunction());
  ASSERT(function().NumOptionalParameters() == 0);
  const intptr_t num_params = function().num_fixed_parameters();
  ASSERT(num_params == RegExpMacroAssembler::kParamCount);
  // Compute start indices to parameters and locals, and the number of
  // parameters to copy.
  first_parameter_index_ = VariableIndex(num_params);

  // Frame indices are relative to the frame pointer and are decreasing.
  num_stack_locals_ = num_stack_locals;
}

void ParsedFunction::AllocateBytecodeVariables(intptr_t num_stack_locals) {
  ASSERT(!function().IsIrregexpFunction());
  first_parameter_index_ = VariableIndex(function().num_fixed_parameters());
  num_stack_locals_ = num_stack_locals;
}

void ParsedFunction::SetCovariantParameters(
    const BitVector* covariant_parameters) {
  ASSERT(covariant_parameters_ == nullptr);
  ASSERT(covariant_parameters->length() == function_.NumParameters());
  covariant_parameters_ = covariant_parameters;
}

void ParsedFunction::SetGenericCovariantImplParameters(
    const BitVector* generic_covariant_impl_parameters) {
  ASSERT(generic_covariant_impl_parameters_ == nullptr);
  ASSERT(generic_covariant_impl_parameters->length() ==
         function_.NumParameters());
  generic_covariant_impl_parameters_ = generic_covariant_impl_parameters;
}

bool ParsedFunction::IsCovariantParameter(intptr_t i) const {
  ASSERT(covariant_parameters_ != nullptr);
  ASSERT((i >= 0) && (i < function_.NumParameters()));
  return covariant_parameters_->Contains(i);
}

bool ParsedFunction::IsGenericCovariantImplParameter(intptr_t i) const {
  ASSERT(generic_covariant_impl_parameters_ != nullptr);
  ASSERT((i >= 0) && (i < function_.NumParameters()));
  return generic_covariant_impl_parameters_->Contains(i);
}

}  // namespace dart

#endif  // DART_PRECOMPILED_RUNTIME
