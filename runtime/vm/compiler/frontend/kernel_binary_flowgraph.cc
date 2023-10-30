// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"

#include "vm/closure_functions_cache.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/recognized_method.h"
#include "vm/compiler/frontend/flow_graph_builder.h"  // For dart::FlowGraphBuilder::SimpleInstanceOfType.
#include "vm/compiler/frontend/prologue_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/kernel_binary.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()
#define IG IsolateGroup::Current()
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

  // Constants are directly accessed at use sites of Dart code. In C++ - if
  // we need to access static constants - we do so directly using the kernel
  // evaluation instead of invoking the initializer function in Dart code.
  //
  // If the field is marked as @pragma('vm:entry-point') then the embedder might
  // invoke the getter, so we'll generate the initializer function.
  ASSERT(!field_helper.IsConst() ||
         Field::Handle(Z, parsed_function()->function().accessor_field())
                 .VerifyEntryPoint(EntryPointPragma::kGetterOnly) ==
             Error::null());

  Tag initializer_tag = ReadTag();  // read first part of initializer.
  if (initializer_tag != kSomething) {
    UNREACHABLE();
  }

  B->graph_entry_ = new (Z) GraphEntryInstr(*parsed_function(), B->osr_id_);

  auto normal_entry = B->BuildFunctionEntry(B->graph_entry_);
  B->graph_entry_->set_normal_entry(normal_entry);

  Fragment body(normal_entry);
  body += B->CheckStackOverflowInPrologue(field_helper.position_);
  body += SetupCapturedParameters(parsed_function()->function());
  body += BuildExpression();  // read initializer.
  body += Return(TokenPosition::kNoSource);

  PrologueInfo prologue_info(-1, -1);
  if (B->IsCompiledForOsr()) {
    B->graph_entry_->RelinkToOsrEntry(Z, B->last_used_block_id_ + 1);
  }
  return new (Z) FlowGraph(*parsed_function(), B->graph_entry_,
                           B->last_used_block_id_, prologue_info);
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
          // This will read the initializer.
          default_value = &Instance::ZoneHandle(
              Z, constant_reader_.ReadConstantExpression());
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
          // This will read the initializer.
          default_value = &Instance::ZoneHandle(
              Z, constant_reader_.ReadConstantExpression());
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
    const Field& field,
    bool only_for_side_effects) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  if (PeekTag() == kNullLiteral) {
    SkipExpression();  // read past the null literal.
    if (H.thread()->IsDartMutatorThread()) {
      ASSERT(field.IsOriginal());
      LeaveCompilerScope cs(H.thread());
      field.RecordStore(Object::null_object());
    } else {
      ASSERT(field.is_nullable_unsafe());
    }
    return Fragment();
  }

  Fragment instructions;
  if (!only_for_side_effects) {
    instructions += LoadLocal(parsed_function()->receiver_var());
  }
  // All closures created inside BuildExpression will have
  // field.RawOwner() as its owner.
  closure_owner_ = field.RawOwner();
  instructions += BuildExpression();
  closure_owner_ = Object::null();
  if (only_for_side_effects) {
    instructions += Drop();
  } else {
    instructions += flow_graph_builder_->StoreFieldGuarded(
        field, StoreFieldInstr::Kind::kInitializing);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildLateFieldInitializer(
    const Field& field,
    bool has_initializer) {
  if (has_initializer && PeekTag() == kNullLiteral) {
    SkipExpression();  // read past the null literal.
    if (H.thread()->IsDartMutatorThread()) {
      LeaveCompilerScope cs(H.thread());
      field.RecordStore(Object::null_object());
    } else {
      ASSERT(field.is_nullable_unsafe());
    }
    return Fragment();
  }

  Fragment instructions;
  instructions += LoadLocal(parsed_function()->receiver_var());
  instructions += flow_graph_builder_->Constant(Object::sentinel());
  instructions += flow_graph_builder_->StoreField(
      field, StoreFieldInstr::Kind::kInitializing);
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

  bool is_redirecting_constructor = false;

  // Field which will be initialized by the initializer with the given index.
  GrowableArray<const Field*> initializer_fields(5);

  // Check if this is a redirecting constructor and collect all fields which
  // will be initialized by the constructor initializer list.
  {
    AlternativeReadingScope alt(&reader_, initializers_offset);

    const intptr_t list_length =
        ReadListLength();  // read initializers list length.
    initializer_fields.EnsureLength(list_length, nullptr);

    bool has_field_initializers = false;
    for (intptr_t i = 0; i < list_length; ++i) {
      if (PeekTag() == kRedirectingInitializer) {
        is_redirecting_constructor = true;
      } else if (PeekTag() == kFieldInitializer) {
        has_field_initializers = true;
        ReadTag();
        ReadBool();
        ReadPosition();
        const NameIndex field_name = ReadCanonicalNameReference();
        const Field& field =
            Field::Handle(Z, H.LookupFieldByKernelField(field_name));
        initializer_fields[i] = &field;
        SkipExpression();
        continue;
      }
      SkipInitializer();
    }
    ASSERT(!is_redirecting_constructor || !has_field_initializers);
  }

  // These come from:
  //
  //   class A {
  //     var x = (expr);
  //   }
  //
  // We don't want to do that when this is a Redirecting Constructors though
  // (i.e. has a single initializer being of type kRedirectingInitializer).
  if (!is_redirecting_constructor) {
    // Sort list of fields (represented as their kernel offsets) which will
    // be initialized by the constructor initializer list. We will not emit
    // StoreField instructions for those initializers though we will
    // still evaluate initialization expression for its side effects.
    GrowableArray<intptr_t> constructor_initialized_field_offsets(
        initializer_fields.length());
    for (auto field : initializer_fields) {
      if (field != nullptr) {
        constructor_initialized_field_offsets.Add(field->kernel_offset());
      }
    }

    constructor_initialized_field_offsets.Sort(
        [](const intptr_t* a, const intptr_t* b) {
          return static_cast<int>(*a) - static_cast<int>(*b);
        });
    constructor_initialized_field_offsets.Add(-1);

    auto& kernel_data = TypedDataView::Handle(Z);
    Array& class_fields = Array::Handle(Z, parent_class.fields());
    Field& class_field = Field::Handle(Z);
    intptr_t next_constructor_initialized_field_index = 0;
    for (intptr_t i = 0; i < class_fields.Length(); ++i) {
      class_field ^= class_fields.At(i);
      if (!class_field.is_static()) {
        const intptr_t field_offset = class_field.kernel_offset();

        // Check if this field will be initialized by the constructor
        // initializer list.
        // Note that both class_fields and the list of initialized fields
        // are sorted by their kernel offset (by construction) -
        // so we don't need to perform the search.
        bool is_constructor_initialized = false;
        const intptr_t constructor_initialized_field_offset =
            constructor_initialized_field_offsets
                [next_constructor_initialized_field_index];
        if (constructor_initialized_field_offset == field_offset) {
          next_constructor_initialized_field_index++;
          is_constructor_initialized = true;
        }

        kernel_data = class_field.KernelLibrary();
        ASSERT(!kernel_data.IsNull());
        AlternativeReadingScopeWithNewData alt(&reader_, &kernel_data,
                                               field_offset);
        FieldHelper field_helper(this);
        field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
        const Tag initializer_tag = ReadTag();
        if (class_field.is_late()) {
          if (!is_constructor_initialized) {
            instructions += BuildLateFieldInitializer(
                Field::ZoneHandle(Z, class_field.ptr()),
                initializer_tag == kSomething);
          }
        } else if (initializer_tag == kSomething) {
          EnterScope(field_offset);
          // If this field is initialized in constructor then we can ignore the
          // value produced by the field initializer. However we still need to
          // execute it for its side effects.
          instructions += BuildFieldInitializer(
              Field::ZoneHandle(Z, class_field.ptr()),
              /*only_for_side_effects=*/is_constructor_initialized);
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
          ReadPosition();  // read position.
          ReadCanonicalNameReference();
          instructions += BuildFieldInitializer(
              Field::ZoneHandle(Z, initializer_fields[i]->ptr()),
              /*only_for_size_effects=*/false);
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

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(
              &argument_names, &argument_count,
              /* positional_parameter_count = */ nullptr);  // read arguments.
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

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(
              &argument_names, &argument_count,
              /* positional_parameter_count = */ nullptr);  // read arguments.
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

Fragment StreamingFlowGraphBuilder::TypeArgumentsHandling(
    const Function& dart_function) {
  Fragment prologue = B->BuildDefaultTypeHandling(dart_function);

  if (dart_function.IsClosureFunction() &&
      dart_function.NumParentTypeArguments() > 0) {
    LocalVariable* closure = parsed_function()->ParameterVariable(0);
    LocalVariable* fn_type_args = parsed_function()->function_type_arguments();
    ASSERT(fn_type_args != nullptr && closure != nullptr);

    if (dart_function.IsGeneric()) {
      prologue += LoadLocal(fn_type_args);

      prologue += LoadLocal(closure);
      prologue += LoadNativeField(Slot::Closure_function_type_arguments());

      prologue += IntConstant(dart_function.NumParentTypeArguments());

      prologue += IntConstant(dart_function.NumTypeArguments());

      const auto& prepend_function =
          flow_graph_builder_->PrependTypeArgumentsFunction();

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
        ASSERT((function.MakesCopyOfParameters() &&
                raw_parameter.owner() == scope) ||
               (!function.MakesCopyOfParameters() &&
                raw_parameter.owner() == nullptr));
        ASSERT(!raw_parameter.is_captured());

        // Copy the parameter from the stack to the context.
        body += LoadLocal(context);
        body += LoadLocal(&raw_parameter);
        body += flow_graph_builder_->StoreNativeField(
            Slot::GetContextVariableSlotFor(thread(), *variable),
            StoreFieldInstr::Kind::kInitializing);
      }
    }
    body += Drop();  // The context.
  }
  return body;
}

Fragment StreamingFlowGraphBuilder::InitSuspendableFunction(
    const Function& dart_function) {
  Fragment body;
  if (dart_function.IsAsyncFunction()) {
    const auto& result_type =
        AbstractType::Handle(Z, dart_function.result_type());
    auto& type_args = TypeArguments::ZoneHandle(Z);
    if (result_type.IsType() &&
        (Class::Handle(Z, result_type.type_class()).IsFutureClass() ||
         result_type.IsFutureOrType())) {
      ASSERT(result_type.IsFinalized());
      type_args = Type::Cast(result_type).GetInstanceTypeArguments(H.thread());
    }

    body += TranslateInstantiatedTypeArguments(type_args);
    body += B->Call1ArgStub(TokenPosition::kNoSource,
                            Call1ArgStubInstr::StubId::kInitAsync);
    body += Drop();
  } else if (dart_function.IsAsyncGenerator()) {
    const auto& result_type =
        AbstractType::Handle(Z, dart_function.result_type());
    auto& type_args = TypeArguments::ZoneHandle(Z);
    if (result_type.IsType() &&
        (result_type.type_class() == IG->object_store()->stream_class())) {
      ASSERT(result_type.IsFinalized());
      type_args = Type::Cast(result_type).GetInstanceTypeArguments(H.thread());
    }

    body += TranslateInstantiatedTypeArguments(type_args);
    body += B->Call1ArgStub(TokenPosition::kNoSource,
                            Call1ArgStubInstr::StubId::kInitAsyncStar);
    body += Drop();
    body += NullConstant();
    body += B->Suspend(TokenPosition::kNoSource,
                       SuspendInstr::StubId::kYieldAsyncStar);
    body += Drop();
  } else if (dart_function.IsSyncGenerator()) {
    const auto& result_type =
        AbstractType::Handle(Z, dart_function.result_type());
    auto& type_args = TypeArguments::ZoneHandle(Z);
    if (result_type.IsType() &&
        (result_type.type_class() == IG->object_store()->iterable_class())) {
      ASSERT(result_type.IsFinalized());
      type_args = Type::Cast(result_type).GetInstanceTypeArguments(H.thread());
    }

    body += TranslateInstantiatedTypeArguments(type_args);
    body += B->Call1ArgStub(TokenPosition::kNoSource,
                            Call1ArgStubInstr::StubId::kInitSyncStar);
    body += Drop();
    body += NullConstant();
    body += B->Suspend(TokenPosition::kNoSource,
                       SuspendInstr::StubId::kSuspendSyncStarAtStart);
    body += Drop();
    // Clone context if there are any captured parameter variables, so
    // each invocation of .iterator would get its own copy of parameters.
    const LocalScope* scope = parsed_function()->scope();
    if (scope->num_context_variables() > 0) {
      body += CloneContext(scope->context_slots());
    }
  }
  return body;
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
      (dart_function.name() == Symbols::EqualOperator().ptr()) &&
      (dart_function.Owner() != IG->object_store()->object_class())) {
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
  } else if (dart_function.is_external()) {
    body += ThrowNoSuchMethodError(TokenPosition::kNoSource, dart_function,
                                   /*incompatible_arguments=*/false);
    body += ThrowException(TokenPosition::kNoSource);  // Close graph.
  } else if (has_body) {
    body += BuildStatement();
  }

  if (body.is_open()) {
    if (parsed_function()->function().IsSyncGenerator()) {
      // Return false from sync* function to indicate the end of iteration.
      body += Constant(Bool::False());
    } else {
      body += NullConstant();
    }
    body += Return(dart_function.end_token_pos());
  }

  return body;
}

Fragment StreamingFlowGraphBuilder::BuildRegularFunctionPrologue(
    const Function& dart_function,
    TokenPosition token_position,
    LocalVariable* first_parameter) {
  Fragment F;
  F += CheckStackOverflowInPrologue(dart_function);
  F += DebugStepCheckInPrologue(dart_function, token_position);
  F += B->InitConstantParameters();
  F += SetupCapturedParameters(dart_function);
  F += ShortcutForUserDefinedEquals(dart_function, first_parameter);
  return F;
}

Fragment StreamingFlowGraphBuilder::ClearRawParameters(
    const Function& dart_function) {
  const ParsedFunction& pf = *flow_graph_builder_->parsed_function_;
  Fragment code;
  for (intptr_t i = 0; i < dart_function.NumParameters(); ++i) {
    LocalVariable* variable = pf.ParameterVariable(i);

    if (!variable->is_captured()) continue;

    // Captured 'this' is immutable, so within the outer method we don't need to
    // load it from the context. Therefore we don't reset it to null.
    if (pf.function().HasThisParameter() && pf.has_receiver_var() &&
        variable == pf.receiver_var()) {
      ASSERT(i == 0);
      continue;
    }

    variable = pf.RawParameterVariable(i);
    code += NullConstant();
    code += StoreLocal(TokenPosition::kNoSource, variable);
    code += Drop();
  }
  return code;
}

UncheckedEntryPointStyle StreamingFlowGraphBuilder::ChooseEntryPointStyle(
    const Function& dart_function,
    const Fragment& implicit_type_checks,
    const Fragment& regular_function_prologue,
    const Fragment& type_args_handling) {
  ASSERT(!dart_function.IsImplicitClosureFunction());
  if (!dart_function.MayHaveUncheckedEntryPoint() ||
      implicit_type_checks.is_empty()) {
    return UncheckedEntryPointStyle::kNone;
  }

  // Record which entry-point was taken into a variable and test it later if
  // either:
  //
  // 1. There is a non-empty PrologueBuilder-prologue.
  //
  // 2. The regular function prologue has more than two instructions
  //    (DebugStepCheck and CheckStackOverflow).
  //
  if (!PrologueBuilder::HasEmptyPrologue(dart_function) ||
      !type_args_handling.is_empty()) {
    return UncheckedEntryPointStyle::kSharedWithVariable;
  }
  Instruction* instr = regular_function_prologue.entry;
  if (instr != nullptr && instr->IsCheckStackOverflow()) {
    instr = instr->next();
  }
  if (instr != nullptr && instr->IsDebugStepCheck()) {
    instr = instr->next();
  }
  if (instr != nullptr) {
    return UncheckedEntryPointStyle::kSharedWithVariable;
  }

  return UncheckedEntryPointStyle::kSeparate;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfFunction(
    bool is_constructor) {
  const Function& dart_function = parsed_function()->function();

  LocalVariable* first_parameter = nullptr;
  TokenPosition token_position = TokenPosition::kNoSource;
  {
    AlternativeReadingScope alt(&reader_);
    FunctionNodeHelper function_node_helper(this);
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

  const Fragment regular_prologue = BuildRegularFunctionPrologue(
      dart_function, token_position, first_parameter);

  // TODO(#34162): We can remove the default type handling (and
  // shorten the prologue type handling sequence) for non-dynamic invocations of
  // regular methods.
  const Fragment type_args_handling = TypeArgumentsHandling(dart_function);

  Fragment implicit_type_checks;
  if (dart_function.NeedsTypeArgumentTypeChecks()) {
    B->BuildTypeArgumentTypeChecks(
        TypeChecksToBuild::kCheckCovariantTypeParameterBounds,
        &implicit_type_checks);
  }

  Fragment explicit_type_checks;
  Fragment implicit_redefinitions;
  if (dart_function.NeedsArgumentTypeChecks()) {
    B->BuildArgumentTypeChecks(&explicit_type_checks, &implicit_type_checks,
                               &implicit_redefinitions);
  }

  // The RawParameter variables should be set to null to avoid retaining more
  // objects than necessary during GC.
  const Fragment body =
      ClearRawParameters(dart_function) + B->BuildNullAssertions() +
      InitSuspendableFunction(dart_function) +
      BuildFunctionBody(dart_function, first_parameter, is_constructor);

  auto extra_entry_point_style =
      ChooseEntryPointStyle(dart_function, implicit_type_checks,
                            regular_prologue, type_args_handling);

  Fragment function(instruction_cursor);
  FunctionEntryInstr* extra_entry = nullptr;
  switch (extra_entry_point_style) {
    case UncheckedEntryPointStyle::kNone: {
      function += regular_prologue + type_args_handling + implicit_type_checks +
                  explicit_type_checks + body;
      break;
    }
    case UncheckedEntryPointStyle::kSeparate: {
      ASSERT(instruction_cursor == normal_entry);
      ASSERT(type_args_handling.is_empty());

      const Fragment prologue_copy = BuildRegularFunctionPrologue(
          dart_function, token_position, first_parameter);

      extra_entry = B->BuildSeparateUncheckedEntryPoint(
          normal_entry,
          /*normal_prologue=*/regular_prologue + implicit_type_checks,
          /*extra_prologue=*/prologue_copy,
          /*shared_prologue=*/explicit_type_checks,
          /*body=*/body);
      break;
    }
    case UncheckedEntryPointStyle::kSharedWithVariable: {
      Fragment prologue(normal_entry, instruction_cursor);
      prologue += regular_prologue;
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

  // Setup an [ActiveClassScope] and an [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass =
      Class::Handle(zone_, parsed_function()->function().Owner());
  Function& outermost_function =
      Function::Handle(Z, function.GetOutermostFunction());

  ActiveClassScope active_class_scope(active_class(), &klass);
  ActiveMemberScope active_member(active_class(), &outermost_function);
  FunctionType& signature = FunctionType::Handle(Z, function.signature());
  ActiveTypeParametersScope active_type_params(active_class(), function,
                                               &signature, Z);

  ParseKernelASTFunction();

  switch (function.kind()) {
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kClosureFunction:
    case UntaggedFunction::kConstructor: {
      if (FlowGraphBuilder::IsRecognizedMethodForFlowGraph(function)) {
        return B->BuildGraphOfRecognizedMethod(function);
      }
      return BuildGraphOfFunction(function.IsGenerativeConstructor());
    }
    case UntaggedFunction::kImplicitGetter:
    case UntaggedFunction::kImplicitStaticGetter:
    case UntaggedFunction::kImplicitSetter: {
      return B->BuildGraphOfFieldAccessor(function);
    }
    case UntaggedFunction::kFieldInitializer:
      return BuildGraphOfFieldInitializer();
    case UntaggedFunction::kDynamicInvocationForwarder:
      return B->BuildGraphOfDynamicInvocationForwarder(function);
    case UntaggedFunction::kMethodExtractor:
      return flow_graph_builder_->BuildGraphOfMethodExtractor(function);
    case UntaggedFunction::kNoSuchMethodDispatcher:
      return flow_graph_builder_->BuildGraphOfNoSuchMethodDispatcher(function);
    case UntaggedFunction::kInvokeFieldDispatcher:
      return flow_graph_builder_->BuildGraphOfInvokeFieldDispatcher(function);
    case UntaggedFunction::kImplicitClosureFunction:
      return flow_graph_builder_->BuildGraphOfImplicitClosureFunction(function);
    case UntaggedFunction::kFfiTrampoline:
      return flow_graph_builder_->BuildGraphOfFfiTrampoline(function);
    case UntaggedFunction::kRecordFieldGetter:
      return flow_graph_builder_->BuildGraphOfRecordFieldGetter(function);
    case UntaggedFunction::kIrregexpFunction:
      break;
  }
  UNREACHABLE();
  return nullptr;
}

void StreamingFlowGraphBuilder::ParseKernelASTFunction() {
  const Function& function = parsed_function()->function();

  const intptr_t kernel_offset = function.kernel_offset();
  ASSERT(kernel_offset >= 0);

  SetOffset(kernel_offset);

  // Mark forwarding stubs.
  switch (function.kind()) {
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kImplicitClosureFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kClosureFunction:
    case UntaggedFunction::kConstructor:
    case UntaggedFunction::kDynamicInvocationForwarder:
      ReadForwardingStubTarget(function);
      break;
    default:
      break;
  }

  set_scopes(parsed_function()->EnsureKernelScopes());

  switch (function.kind()) {
    case UntaggedFunction::kRegularFunction:
    case UntaggedFunction::kGetterFunction:
    case UntaggedFunction::kSetterFunction:
    case UntaggedFunction::kClosureFunction:
    case UntaggedFunction::kConstructor:
    case UntaggedFunction::kImplicitClosureFunction:
      ReadUntilFunctionNode();
      SetupDefaultParameterValues();
      break;
    case UntaggedFunction::kImplicitGetter:
    case UntaggedFunction::kImplicitStaticGetter:
    case UntaggedFunction::kImplicitSetter:
    case UntaggedFunction::kFieldInitializer:
    case UntaggedFunction::kMethodExtractor:
    case UntaggedFunction::kNoSuchMethodDispatcher:
    case UntaggedFunction::kInvokeFieldDispatcher:
    case UntaggedFunction::kFfiTrampoline:
    case UntaggedFunction::kRecordFieldGetter:
      break;
    case UntaggedFunction::kDynamicInvocationForwarder:
      if (PeekTag() != kField) {
        ReadUntilFunctionNode();
        SetupDefaultParameterValues();
      }
      break;
    case UntaggedFunction::kIrregexpFunction:
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
          procedure_helper.concrete_forwarding_stub_target_;
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
  ++num_ast_nodes_;
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
    case kInstanceGet:
      return BuildInstanceGet(position);
    case kDynamicGet:
      return BuildDynamicGet(position);
    case kInstanceTearOff:
      return BuildInstanceTearOff(position);
    case kFunctionTearOff:
      // Removed by lowering kernel transformation.
      UNREACHABLE();
      break;
    case kInstanceSet:
      return BuildInstanceSet(position);
    case kDynamicSet:
      return BuildDynamicSet(position);
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
      return BuildSuperPropertyGet(position);
    case kSuperPropertySet:
      return BuildSuperPropertySet(position);
    case kStaticGet:
      return BuildStaticGet(position);
    case kStaticSet:
      return BuildStaticSet(position);
    case kInstanceInvocation:
      return BuildMethodInvocation(position, /*is_dynamic=*/false);
    case kDynamicInvocation:
      return BuildMethodInvocation(position, /*is_dynamic=*/true);
    case kLocalFunctionInvocation:
      return BuildLocalFunctionInvocation(position);
    case kFunctionInvocation:
      return BuildFunctionInvocation(position);
    case kEqualsCall:
      return BuildEqualsCall(position);
    case kEqualsNull:
      return BuildEqualsNull(position);
    case kAbstractSuperMethodInvocation:
      // Abstract super method invocations must be converted into super
      // method invocations during mixin transformation.
      UNREACHABLE();
      break;
    case kSuperMethodInvocation:
      return BuildSuperMethodInvocation(position);
    case kStaticInvocation:
      return BuildStaticInvocation(position);
    case kConstructorInvocation:
      return BuildConstructorInvocation(position);
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
    case kIsExpression:
      return BuildIsExpression(position);
    case kAsExpression:
      return BuildAsExpression(position);
    case kTypeLiteral:
      return BuildTypeLiteral(position);
    case kThisExpression:
      return BuildThisExpression(position);
    case kRethrow:
      return BuildRethrow(position);
    case kThrow:
      return BuildThrow(position);
    case kListLiteral:
      return BuildListLiteral(position);
    case kSetLiteral:
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      break;
    case kMapLiteral:
      return BuildMapLiteral(position);
    case kRecordLiteral:
      return BuildRecordLiteral(position);
    case kRecordIndexGet:
      return BuildRecordFieldGet(position, /*is_named=*/false);
    case kRecordNameGet:
      return BuildRecordFieldGet(position, /*is_named=*/true);
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
    case kFileUriConstantExpression:
      return BuildConstantExpression(position, tag);
    case kInstantiation:
      return BuildPartialTearoffInstantiation(position);
    case kLoadLibrary:
      return BuildLibraryPrefixAction(position, Symbols::LoadLibrary());
    case kCheckLibraryIsLoaded:
      return BuildLibraryPrefixAction(position, Symbols::CheckLoaded());
    case kAwaitExpression:
      return BuildAwaitExpression(position);
    case kFileUriExpression:
      return BuildFileUriExpression(position);
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

  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStatement(TokenPosition* position) {
  ++num_ast_nodes_;
  intptr_t offset = ReaderOffset();
  Tag tag = ReadTag();  // read tag.
  switch (tag) {
    case kExpressionStatement:
      return BuildExpressionStatement(position);
    case kBlock:
      return BuildBlock(position);
    case kEmptyStatement:
      return BuildEmptyStatement();
    case kAssertBlock:
      return BuildAssertBlock(position);
    case kAssertStatement:
      return BuildAssertStatement(position);
    case kLabeledStatement:
      return BuildLabeledStatement(position);
    case kBreakStatement:
      return BuildBreakStatement(position);
    case kWhileStatement:
      return BuildWhileStatement(position);
    case kDoStatement:
      return BuildDoStatement(position);
    case kForStatement:
      return BuildForStatement(position);
    case kSwitchStatement:
      return BuildSwitchStatement(position);
    case kContinueSwitchStatement:
      return BuildContinueSwitchStatement(position);
    case kIfStatement:
      return BuildIfStatement(position);
    case kReturnStatement:
      return BuildReturnStatement(position);
    case kTryCatch:
      return BuildTryCatch(position);
    case kTryFinally:
      return BuildTryFinally(position);
    case kYieldStatement:
      return BuildYieldStatement(position);
    case kVariableDeclaration:
      return BuildVariableDeclaration(position);
    case kFunctionDeclaration:
      return BuildFunctionDeclaration(offset, position);
    case kForInStatement:
    case kAsyncForInStatement:
    case kIfCaseStatement:
    case kPatternSwitchStatement:
    case kPatternVariableDeclaration:
    // These nodes are internal to the front end and
    // removed by the constant evaluator.
    default:
      ReportUnexpectedTag("statement", tag);
      UNREACHABLE();
  }
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStatementWithBranchCoverage(
    TokenPosition* position) {
  TokenPosition pos = TokenPosition::kNoSource;
  Fragment statement = BuildStatement(&pos);
  if (position != nullptr) *position = pos;
  Fragment covered_statement = flow_graph_builder_->RecordBranchCoverage(pos);
  covered_statement += statement;
  return covered_statement;
}

void StreamingFlowGraphBuilder::ReportUnexpectedTag(const char* variant,
                                                    Tag tag) {
  if ((flow_graph_builder_ == nullptr) || (parsed_function() == nullptr)) {
    KernelReaderHelper::ReportUnexpectedTag(variant, tag);
  } else {
    const auto& script = Script::Handle(Z, Script());
    H.ReportError(script, TokenPosition::kNoSource,
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
  return reader_.ReadNullability();
}

Variance KernelReaderHelper::ReadVariance() {
  return reader_.ReadVariance();
}

void StreamingFlowGraphBuilder::loop_depth_inc() {
  ++flow_graph_builder_->loop_depth_;
}

void StreamingFlowGraphBuilder::loop_depth_dec() {
  --flow_graph_builder_->loop_depth_;
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

Value* StreamingFlowGraphBuilder::stack() {
  return flow_graph_builder_->stack_;
}

void StreamingFlowGraphBuilder::set_stack(Value* top) {
  flow_graph_builder_->stack_ = top;
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

LocalVariable* StreamingFlowGraphBuilder::MakeTemporary(const char* suffix) {
  return flow_graph_builder_->MakeTemporary(suffix);
}

Fragment StreamingFlowGraphBuilder::DropTemporary(LocalVariable** variable) {
  return flow_graph_builder_->DropTemporary(variable);
}

Function& StreamingFlowGraphBuilder::FindMatchingFunction(
    const Class& klass,
    const String& name,
    int type_args_len,
    int argument_count,
    const Array& argument_names) {
  // Search the superclass chain for the selector.
  ArgumentsDescriptor args_desc(
      Array::Handle(Z, ArgumentsDescriptor::NewBoxed(
                           type_args_len, argument_count, argument_names)));
  return Function::Handle(Z,
                          Resolver::ResolveDynamicForReceiverClassAllowPrivate(
                              klass, name, args_desc, /*allow_add=*/false));
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

IndirectGotoInstr* StreamingFlowGraphBuilder::IndirectGoto(
    intptr_t target_count) {
  return flow_graph_builder_->IndirectGoto(target_count);
}

Fragment StreamingFlowGraphBuilder::Return(TokenPosition position) {
  return flow_graph_builder_->Return(position,
                                     /*omit_result_type_check=*/false);
}

Fragment StreamingFlowGraphBuilder::EvaluateAssertion() {
  return flow_graph_builder_->EvaluateAssertion();
}

Fragment StreamingFlowGraphBuilder::RethrowException(TokenPosition position,
                                                     int catch_try_index) {
  return flow_graph_builder_->RethrowException(position, catch_try_index);
}

Fragment StreamingFlowGraphBuilder::ThrowNoSuchMethodError(
    TokenPosition position,
    const Function& target,
    bool incompatible_arguments) {
  return flow_graph_builder_->ThrowNoSuchMethodError(position, target,
                                                     incompatible_arguments);
}

Fragment StreamingFlowGraphBuilder::Constant(const Object& value) {
  return flow_graph_builder_->Constant(value);
}

Fragment StreamingFlowGraphBuilder::IntConstant(int64_t value) {
  return flow_graph_builder_->IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::LoadStaticField(const Field& field,
                                                    bool calls_initializer) {
  return flow_graph_builder_->LoadStaticField(field, calls_initializer);
}

Fragment StreamingFlowGraphBuilder::RedefinitionWithType(
    const AbstractType& type) {
  return flow_graph_builder_->RedefinitionWithType(type);
}

Fragment StreamingFlowGraphBuilder::CheckNull(TokenPosition position,
                                              LocalVariable* receiver,
                                              const String& function_name) {
  return flow_graph_builder_->CheckNull(position, receiver, function_name);
}

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count,
                                               ICData::RebindRule rebind_rule) {
  if (!target.AreValidArgumentCounts(0, argument_count, 0, nullptr)) {
    Fragment instructions;
    instructions += DropArguments(argument_count, /*type_args_count=*/0);
    instructions += ThrowNoSuchMethodError(position, target,
                                           /*incompatible_arguments=*/true);
    return instructions;
  }
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
  if (!target.AreValidArguments(type_args_count, argument_count, argument_names,
                                nullptr)) {
    Fragment instructions;
    instructions += DropArguments(argument_count, type_args_count);
    instructions += ThrowNoSuchMethodError(position, target,
                                           /*incompatible_arguments=*/true);
    return instructions;
  }
  return flow_graph_builder_->StaticCall(
      position, target, argument_count, argument_names, rebind_rule,
      result_type, type_args_count, use_unchecked_entry);
}

Fragment StreamingFlowGraphBuilder::StaticCallMissing(
    TokenPosition position,
    const String& selector,
    intptr_t argument_count,
    InvocationMirror::Level level,
    InvocationMirror::Kind kind) {
  Fragment instructions;
  instructions += DropArguments(argument_count, /*type_args_count=*/0);
  instructions += flow_graph_builder_->ThrowNoSuchMethodError(
      position, selector, level, kind);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::InstanceCall(
    TokenPosition position,
    const String& name,
    Token::Kind kind,
    intptr_t argument_count,
    intptr_t checked_argument_count) {
  const intptr_t kTypeArgsLen = 0;
  return flow_graph_builder_->InstanceCall(position, name, kind, kTypeArgsLen,
                                           argument_count, Array::null_array(),
                                           checked_argument_count);
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
    const Function& tearoff_interface_target,
    const InferredTypeMetadata* result_type,
    bool use_unchecked_entry,
    const CallSiteAttributesMetadata* call_site_attrs,
    bool receiver_is_not_smi,
    bool is_call_on_this) {
  return flow_graph_builder_->InstanceCall(
      position, name, kind, type_args_len, argument_count, argument_names,
      checked_argument_count, interface_target, tearoff_interface_target,
      result_type, use_unchecked_entry, call_site_attrs, receiver_is_not_smi,
      is_call_on_this);
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
                           B->loop_depth_, B->try_depth_, B->catch_depth_,
                           B->block_expression_depth_);

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

Fragment StreamingFlowGraphBuilder::DropArguments(intptr_t argument_count,
                                                  intptr_t type_args_count) {
  Fragment instructions;
  for (intptr_t i = 0; i < argument_count; i++) {
    instructions += Drop();
  }
  if (type_args_count != 0) {
    instructions += Drop();
  }
  return instructions;
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

Fragment StreamingFlowGraphBuilder::RecordCoverage(TokenPosition position) {
  return flow_graph_builder_->RecordCoverage(position);
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
    ReadPosition();
    negate = !negate;
  }

  TestFragment result;
  if (PeekTag() == kLogicalExpression) {
    // Handle '&&' and '||' operators specially to implement short circuit
    // evaluation.
    SkipBytes(1);  // tag.
    ReadPosition();

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
      if (NeedsDebugStepCheck(stack(), position)) {
        instructions = DebugStepCheck(position) + instructions;
      }
      instructions += CheckBoolean(position);
      instructions += Constant(Bool::True());
      Value* right_value = Pop();
      Value* left_value = Pop();
      StrictCompareInstr* compare = new (Z) StrictCompareInstr(
          InstructionSource(), negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
          left_value, right_value, false,
          flow_graph_builder_->GetNextDeoptId());
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
                                                   intptr_t* positional_count) {
  intptr_t dummy;
  if (argument_count == nullptr) argument_count = &dummy;
  *argument_count = ReadUInt();  // read arguments count.

  // List of types.
  SkipListOfDartTypes();  // read list of types.

  {
    AlternativeReadingScope _(&reader_);
    if (positional_count == nullptr) positional_count = &dummy;
    *positional_count = ReadListLength();  // read length of expression list
  }
  return BuildArgumentsFromActualArguments(argument_names);
}

Fragment StreamingFlowGraphBuilder::BuildArgumentsFromActualArguments(
    Array* argument_names) {
  Fragment instructions;

  // List of positional.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    instructions += BuildExpression();  // read ith expression.
  }

  // List of named.
  list_length = ReadListLength();  // read list length.
  if (argument_names != nullptr && list_length > 0) {
    *argument_names = Array::New(list_length, Heap::kOld);
  }
  for (intptr_t i = 0; i < list_length; ++i) {
    String& name =
        H.DartSymbolObfuscate(ReadStringReference());  // read ith name index.
    instructions += BuildExpression();                 // read ith expression.
    if (argument_names != nullptr) {
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
  if (position != nullptr) *position = pos;
  const String& message = H.DartString(ReadStringReference());
  Tag tag = ReadTag();  // read (first part of) expression.
  if (tag == kSomething) {
    SkipExpression();  // read (rest of) expression.
  }

  // Invalid expression message has pointer to the source code, no need to
  // report it twice.
  const auto& script = Script::Handle(Z, Script());
  H.ReportError(script, TokenPosition::kNoSource, "%s", message.ToCString());
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(TokenPosition* position) {
  const TokenPosition pos = ReadPosition();
  if (position != nullptr) *position = pos;
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();              // read relative variable index.
  SkipOptionalDartType();  // read promoted type.
  return BuildVariableGetImpl(variable_kernel_position, pos);
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(uint8_t payload,
                                                     TokenPosition* position) {
  const TokenPosition pos = ReadPosition();
  if (position != nullptr) *position = pos;
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  return BuildVariableGetImpl(variable_kernel_position, pos);
}

Fragment StreamingFlowGraphBuilder::BuildVariableGetImpl(
    intptr_t variable_kernel_position,
    TokenPosition position) {
  LocalVariable* variable = LookupVariable(variable_kernel_position);
  if (!variable->is_late()) {
    return LoadLocal(variable);
  }

  // Late variable, so check whether it has been initialized already.
  Fragment instructions = LoadLocal(variable);
  TargetEntryInstr* is_uninitialized;
  TargetEntryInstr* is_initialized;
  instructions += Constant(Object::sentinel());
  instructions += flow_graph_builder_->BranchIfStrictEqual(&is_uninitialized,
                                                           &is_initialized);
  JoinEntryInstr* join = BuildJoinEntry();

  {
    AlternativeReadingScope alt(&reader_, variable->late_init_offset());
    const bool has_initializer = (ReadTag() != kNothing);

    if (has_initializer) {
      // If the variable isn't initialized, call the initializer and set it.
      Fragment initialize(is_uninitialized);
      initialize += BuildExpression();
      if (variable->is_final()) {
        // Late final variable, so check whether it has been assigned
        // during initialization.
        initialize += LoadLocal(variable);
        TargetEntryInstr* is_uninitialized_after_init;
        TargetEntryInstr* is_initialized_after_init;
        initialize += Constant(Object::sentinel());
        initialize += flow_graph_builder_->BranchIfStrictEqual(
            &is_uninitialized_after_init, &is_initialized_after_init);
        {
          // The variable is uninitialized, so store the initializer result.
          Fragment store_result(is_uninitialized_after_init);
          store_result += StoreLocal(position, variable);
          store_result += Drop();
          store_result += Goto(join);
        }

        {
          // Already initialized, so throw a LateInitializationError.
          Fragment already_assigned(is_initialized_after_init);
          already_assigned += flow_graph_builder_->ThrowLateInitializationError(
              position, "_throwLocalAssignedDuringInitialization",
              variable->name());
          already_assigned += Goto(join);
        }
      } else {
        // Late non-final variable. Store the initializer result.
        initialize += StoreLocal(position, variable);
        initialize += Drop();
        initialize += Goto(join);
      }
    } else {
      // The variable has no initializer, so throw a late initialization error.
      Fragment initialize(is_uninitialized);
      initialize += flow_graph_builder_->ThrowLateInitializationError(
          position, "_throwLocalNotInitialized", variable->name());
      initialize += Goto(join);
    }
  }

  {
    // Already initialized, so there's nothing to do.
    Fragment already_initialized(is_initialized);
    already_initialized += Goto(join);
  }

  Fragment done = Fragment(instructions.entry, join);
  done += LoadLocal(variable);
  return done;
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();  // read relative variable index.
  return BuildVariableSetImpl(position, variable_kernel_position);
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(uint8_t payload,
                                                     TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  return BuildVariableSetImpl(position, variable_kernel_position);
}

Fragment StreamingFlowGraphBuilder::BuildVariableSetImpl(
    TokenPosition position,
    intptr_t variable_kernel_position) {
  Fragment instructions = BuildExpression();  // read expression.
  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }

  LocalVariable* variable = LookupVariable(variable_kernel_position);
  if (variable->is_late() && variable->is_final()) {
    // Late final variable, so check whether it has been initialized.
    LocalVariable* expr_temp = MakeTemporary();
    instructions += LoadLocal(variable);
    TargetEntryInstr* is_uninitialized;
    TargetEntryInstr* is_initialized;
    instructions += Constant(Object::sentinel());
    instructions += flow_graph_builder_->BranchIfStrictEqual(&is_uninitialized,
                                                             &is_initialized);
    JoinEntryInstr* join = BuildJoinEntry();

    {
      // The variable is uninitialized, so store the expression value.
      Fragment initialize(is_uninitialized);
      initialize += LoadLocal(expr_temp);
      initialize += StoreLocal(position, variable);
      initialize += Drop();
      initialize += Goto(join);
    }

    {
      // Already initialized, so throw a LateInitializationError.
      Fragment already_initialized(is_initialized);
      already_initialized += flow_graph_builder_->ThrowLateInitializationError(
          position, "_throwLocalAlreadyInitialized", variable->name());
      already_initialized += Goto(join);
    }

    instructions = Fragment(instructions.entry, join);
  } else {
    instructions += StoreLocal(position, variable);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInstanceGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  ReadByte();                                     // read kind.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertyGet(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Fragment instructions = BuildExpression();           // read receiver.
  const String& getter_name = ReadNameAsGetterName();  // read name.
  SkipDartType();                                      // read result_type.
  const NameIndex itarget_name =
      ReadInterfaceMemberNameReference();  // read interface_target_reference.
  ASSERT(!H.IsRoot(itarget_name) && H.IsGetter(itarget_name));
  const auto& interface_target = Function::ZoneHandle(
      Z, H.LookupMethodByMember(itarget_name, H.DartGetterName(itarget_name)));
  ASSERT(getter_name.ptr() == interface_target.name());

  if (direct_call.check_receiver_for_null_) {
    auto receiver = MakeTemporary();
    instructions += CheckNull(position, receiver, getter_name);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, direct_call.target_, 1, Array::null_array(),
                   ICData::kNoRebind, &result_type);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions +=
        InstanceCall(position, getter_name, Token::kGET, kTypeArgsLen, 1,
                     Array::null_array(), kNumArgsChecked, interface_target,
                     Function::null_function(), &result_type);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDynamicGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  ReadByte();                                     // read kind.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertyGet(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Fragment instructions = BuildExpression();           // read receiver.
  const String& getter_name = ReadNameAsGetterName();  // read name.
  const auto& mangled_name = String::ZoneHandle(
      Z, Function::CreateDynamicInvocationForwarderName(getter_name));
  const Function* direct_call_target = &direct_call.target_;
  if (!direct_call_target->IsNull()) {
    direct_call_target = &Function::ZoneHandle(
        direct_call.target_.GetDynamicInvocationForwarder(mangled_name));
  }

  if (direct_call.check_receiver_for_null_) {
    auto receiver = MakeTemporary();
    instructions += CheckNull(position, receiver, getter_name);
  }

  if (!direct_call_target->IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, *direct_call_target, 1, Array::null_array(),
                   ICData::kNoRebind, &result_type);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions += InstanceCall(position, mangled_name, Token::kGET,
                                 kTypeArgsLen, 1, Array::null_array(),
                                 kNumArgsChecked, Function::null_function(),
                                 Function::null_function(), &result_type);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInstanceTearOff(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  ReadByte();                                     // read kind.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertyGet(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  Fragment instructions = BuildExpression();           // read receiver.
  const String& getter_name = ReadNameAsGetterName();  // read name.
  SkipDartType();                                      // read result_type.
  const NameIndex itarget_name =
      ReadInterfaceMemberNameReference();  // read interface_target_reference.
  ASSERT(!H.IsRoot(itarget_name) && H.IsMethod(itarget_name));
  const auto& tearoff_interface_target = Function::ZoneHandle(
      Z, H.LookupMethodByMember(itarget_name, H.DartMethodName(itarget_name)));

  if (direct_call.check_receiver_for_null_) {
    const auto receiver = MakeTemporary();
    instructions += CheckNull(position, receiver, getter_name);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, direct_call.target_, 1, Array::null_array(),
                   ICData::kNoRebind, &result_type);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions += InstanceCall(position, getter_name, Token::kGET,
                                 kTypeArgsLen, 1, Array::null_array(),
                                 kNumArgsChecked, Function::null_function(),
                                 tearoff_interface_target, &result_type);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInstanceSet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  ReadByte();                                  // read kind.

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertySet(offset);
  const CallSiteAttributesMetadata call_site_attributes =
      call_site_attributes_metadata_helper_.GetCallSiteAttributes(offset);
  const InferredTypeMetadata inferred_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  // True if callee can skip argument type checks.
  bool is_unchecked_call = inferred_type.IsSkipCheck();
  if (call_site_attributes.receiver_type != nullptr &&
      call_site_attributes.receiver_type->HasTypeClass() &&
      !Class::Handle(call_site_attributes.receiver_type->type_class())
           .IsGeneric()) {
    is_unchecked_call = true;
  }

  Fragment instructions(MakeTemp());
  LocalVariable* variable = MakeTemporary();

  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const bool is_call_on_this = PeekTag() == kThisExpression;
  if (is_call_on_this) {
    is_unchecked_call = true;
  }
  instructions += BuildExpression();  // read receiver.

  LocalVariable* receiver = nullptr;
  if (direct_call.check_receiver_for_null_) {
    receiver = MakeTemporary();
  }

  const String& setter_name = ReadNameAsSetterName();  // read name.

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, variable);

  const NameIndex itarget_name =
      ReadInterfaceMemberNameReference();  // read interface_target_reference.
  ASSERT(!H.IsRoot(itarget_name));
  const auto& interface_target = Function::ZoneHandle(
      Z, H.LookupMethodByMember(itarget_name, H.DartSetterName(itarget_name)));
  ASSERT(setter_name.ptr() == interface_target.name());

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver, setter_name);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, direct_call.target_, 2, Array::null_array(),
                   ICData::kNoRebind, /*result_type=*/nullptr,
                   /*type_args_count=*/0,
                   /*use_unchecked_entry=*/is_unchecked_call);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;

    instructions += InstanceCall(
        position, setter_name, Token::kSET, kTypeArgsLen, 2,
        Array::null_array(), kNumArgsChecked, interface_target,
        Function::null_function(),
        /*result_type=*/nullptr,
        /*use_unchecked_entry=*/is_unchecked_call, &call_site_attributes,
        /*receiver_not_smi=*/false, is_call_on_this);
  }

  instructions += Drop();  // Drop result of the setter invocation.

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDynamicSet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  ReadByte();                                  // read kind.

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertySet(offset);
  const InferredTypeMetadata inferred_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  // True if callee can skip argument type checks.
  const bool is_unchecked_call = inferred_type.IsSkipCheck();

  Fragment instructions(MakeTemp());
  LocalVariable* variable = MakeTemporary();

  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  instructions += BuildExpression();  // read receiver.

  LocalVariable* receiver = nullptr;
  if (direct_call.check_receiver_for_null_) {
    receiver = MakeTemporary();
  }

  const String& setter_name = ReadNameAsSetterName();  // read name.

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, variable);

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver, setter_name);
  }

  const Function* direct_call_target = &direct_call.target_;
  const auto& mangled_name = String::ZoneHandle(
      Z, Function::CreateDynamicInvocationForwarderName(setter_name));
  if (!direct_call_target->IsNull()) {
    direct_call_target = &Function::ZoneHandle(
        direct_call.target_.GetDynamicInvocationForwarder(mangled_name));
  }

  if (!direct_call_target->IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, *direct_call_target, 2, Array::null_array(),
                   ICData::kNoRebind, /*result_type=*/nullptr,
                   /*type_args_count=*/0,
                   /*use_unchecked_entry=*/is_unchecked_call);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;

    instructions += InstanceCall(
        position, mangled_name, Token::kSET, kTypeArgsLen, 2,
        Array::null_array(), kNumArgsChecked, Function::null_function(),
        Function::null_function(),
        /*result_type=*/nullptr,
        /*use_unchecked_entry=*/is_unchecked_call, /*call_site_attrs=*/nullptr);
  }

  instructions += Drop();  // Drop result of the setter invocation.

  return instructions;
}

static Function& GetNoSuchMethodOrDie(Thread* thread,
                                      Zone* zone,
                                      const Class& klass) {
  Function& nsm_function = Function::Handle(zone);
  Class& iterate_klass = Class::Handle(zone, klass.ptr());
  if (!iterate_klass.IsNull() &&
      iterate_klass.EnsureIsFinalized(thread) == Error::null()) {
    while (!iterate_klass.IsNull()) {
      nsm_function = Resolver::ResolveDynamicFunction(zone, iterate_klass,
                                                      Symbols::NoSuchMethod());
      if (!nsm_function.IsNull() && nsm_function.NumParameters() == 2 &&
          nsm_function.NumTypeParameters() == 0) {
        break;
      }
      iterate_klass = iterate_klass.SuperClass();
    }
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

  // Push the arguments for allocating the invocation mirror:
  //   - the name.
  instructions += Constant(String::ZoneHandle(Z, name.ptr()));

  //   - the arguments descriptor.
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::NewBoxed(
                           num_type_arguments, num_arguments, argument_names));
  instructions += Constant(Array::ZoneHandle(Z, args_descriptor.ptr()));

  //   - an array containing the actual arguments.
  instructions += LoadLocal(actuals_array);

  //   - [true] indicating this is a `super` NoSuchMethod.
  instructions += Constant(Bool::True());

  const Class& mirror_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const auto& error = mirror_class.EnsureIsFinalized(thread());
  ASSERT(error == Error::null());
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
  if (p != nullptr) *p = position;

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

  SkipInterfaceMemberNameReference();  // skip target_reference.

  // Search the superclass chain for the selector looking for either getter or
  // method.
  Function& function = Function::Handle(Z);
  if (!klass.IsNull() && klass.EnsureIsFinalized(thread()) == Error::null()) {
    while (!klass.IsNull()) {
      function = Resolver::ResolveDynamicFunction(Z, klass, method_name);
      if (!function.IsNull()) {
        Function& target =
            Function::ZoneHandle(Z, function.ImplicitClosureFunction());
        ASSERT(!target.IsNull());
        // Generate inline code for allocation closure object with context
        // which captures `this`.
        return BuildImplicitClosureCreation(target);
      }
      function = Resolver::ResolveDynamicFunction(Z, klass, getter_name);
      if (!function.IsNull()) break;
      klass = klass.SuperClass();
    }
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

    Function& nsm_function = GetNoSuchMethodOrDie(thread(), Z, parent_klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.ptr()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += DropTempsPreserveTop(1);  // Drop array
  } else {
    ASSERT(!klass.IsNull());
    ASSERT(!function.IsNull());

    instructions += LoadLocal(parsed_function()->receiver_var());

    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, function.ptr()),
                   /* argument_count = */ 1, Array::null_array(),
                   ICData::kSuper, &result_type);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperPropertySet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  Class& klass = GetSuperOrDie();

  const String& setter_name = ReadNameAsSetterName();  // read name.

  Function& function = Function::Handle(Z);
  if (klass.EnsureIsFinalized(thread()) == Error::null()) {
    function = Resolver::ResolveDynamicFunction(Z, klass, setter_name);
  }

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

    SkipInterfaceMemberNameReference();  // skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(thread(), Z, klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.ptr()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += Drop();  // Drop result of NoSuchMethod invocation
    instructions += Drop();  // Drop array
  } else {
    // receiver
    instructions += LoadLocal(parsed_function()->receiver_var());

    instructions += BuildExpression();  // read value.
    instructions += StoreLocal(position, value);

    SkipInterfaceMemberNameReference();  // skip target_reference.

    instructions += StaticCall(
        position, Function::ZoneHandle(Z, function.ptr()),
        /* argument_count = */ 2, Array::null_array(), ICData::kSuper,
        /*result_type=*/nullptr, /*type_args_len=*/0,
        /*use_unchecked_entry=*/true);
    instructions += Drop();  // Drop result of the setter invocation.
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildStaticGet(TokenPosition* p) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.
  ASSERT(H.IsGetter(target));

  const Field& field = Field::ZoneHandle(
      Z, H.LookupFieldByKernelGetterOrSetter(target, /*required=*/false));
  if (!field.IsNull()) {
    if (field.is_const()) {
      // Since the CFE inlines all references to const variables and fields,
      // it never emits a StaticGet of a const field.
      // This situation only arises because of the static const fields in
      // the ClassID class, which are generated internally in the VM
      // during loading. See also Class::InjectCIDFields.
      ASSERT(Class::Handle(field.Owner()).library() ==
                 Library::InternalLibrary() &&
             Class::Handle(field.Owner()).Name() == Symbols::ClassID().ptr());
      return Constant(Instance::ZoneHandle(
          Z, Instance::RawCast(field.StaticConstFieldValue())));
    } else if (field.is_final() && field.has_trivial_initializer()) {
      // Final fields with trivial initializers are effectively constant.
      return Constant(Instance::ZoneHandle(
          Z, Instance::RawCast(field.StaticConstFieldValue())));
    } else {
      const Class& owner = Class::Handle(Z, field.Owner());
      const String& getter_name = H.DartGetterName(target);
      const Function& getter =
          Function::ZoneHandle(Z, owner.LookupStaticFunction(getter_name));
      if (!getter.IsNull() && field.NeedsGetter()) {
        return StaticCall(position, getter, 0, Array::null_array(),
                          ICData::kStatic, &result_type);
      } else {
        if (result_type.IsConstant()) {
          return Constant(result_type.constant_value);
        }
        return LoadStaticField(field, /*calls_initializer=*/false);
      }
    }
  }

  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(target, /*required=*/false));
  if (!function.IsNull()) {
    if (H.IsGetter(target)) {
      return StaticCall(position, function, 0, Array::null_array(),
                        ICData::kStatic, &result_type);
    } else if (H.IsMethod(target)) {
      const auto& closure_function =
          Function::Handle(Z, function.ImplicitClosureFunction());
      const auto& static_closure =
          Instance::Handle(Z, closure_function.ImplicitStaticClosure());
      return Constant(Instance::ZoneHandle(Z, H.Canonicalize(static_closure)));
    } else {
      UNIMPLEMENTED();
    }
  }

  return StaticCallMissing(
      position, H.DartSymbolPlain(H.CanonicalNameString(target)),
      /* argument_count */ 0,
      H.IsLibrary(H.EnclosingName(target)) ? InvocationMirror::Level::kTopLevel
                                           : InvocationMirror::Level::kStatic,
      InvocationMirror::Kind::kGetter);
}

Fragment StreamingFlowGraphBuilder::BuildStaticSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.
  ASSERT(H.IsSetter(target));

  // Evaluate the expression on the right hand side.
  Fragment instructions = BuildExpression();  // read expression.

  // Look up the target as a setter first and, if not present, as a field
  // second. This order is needed to avoid looking up a final field as the
  // target.
  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(target, /*required=*/false));

  if (!function.IsNull()) {
    LocalVariable* variable = MakeTemporary();

    // Prepare argument.
    instructions += LoadLocal(variable);

    // Invoke the setter function.
    instructions += StaticCall(position, function, 1, ICData::kStatic);

    // Drop the unused result & leave the stored value on the stack.
    return instructions + Drop();
  }

  const Field& field = Field::ZoneHandle(
      Z, H.LookupFieldByKernelGetterOrSetter(target, /*required=*/false));
  if (!field.IsNull()) {
    if (NeedsDebugStepCheck(stack(), position)) {
      instructions = DebugStepCheck(position) + instructions;
    }
    LocalVariable* variable = MakeTemporary();
    instructions += LoadLocal(variable);
    instructions += StoreStaticField(position, field);
    return instructions;
  }

  instructions += StaticCallMissing(
      position, H.DartSymbolPlain(H.CanonicalNameString(target)),
      /* argument_count */ 1,
      H.IsLibrary(H.EnclosingName(target)) ? InvocationMirror::Level::kTopLevel
                                           : InvocationMirror::Level::kStatic,
      InvocationMirror::Kind::kSetter);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildMethodInvocation(TokenPosition* p,
                                                          bool is_dynamic) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  ReadByte();                                  // read kind.

  // read flags.
  const uint8_t flags = is_dynamic ? 0 : ReadFlags();
  const bool is_invariant = (flags & kInstanceInvocationFlagInvariant) != 0;

  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForMethodInvocation(offset);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);
  const CallSiteAttributesMetadata call_site_attributes =
      call_site_attributes_metadata_helper_.GetCallSiteAttributes(offset);

  const Tag receiver_tag = PeekTag();  // peek tag for receiver.

  bool is_unchecked_call = is_invariant || result_type.IsSkipCheck();
  if (!is_dynamic && (call_site_attributes.receiver_type != nullptr) &&
      call_site_attributes.receiver_type->HasTypeClass() &&
      !call_site_attributes.receiver_type->IsDynamicType() &&
      !Class::Handle(call_site_attributes.receiver_type->type_class())
           .IsGeneric()) {
    is_unchecked_call = true;
  }

  Fragment instructions;

  intptr_t type_args_len = 0;
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
    }
    type_args_len = list_length;
  }

  // Take note of whether the invocation is against the receiver of the current
  // function: in this case, we may skip some type checks in the callee.
  const bool is_call_on_this = (PeekTag() == kThisExpression) && !is_dynamic;
  if (is_call_on_this) {
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
    instructions +=
        BuildArguments(nullptr /* named */, nullptr /* arg count */,
                       nullptr /* positional arg count */);  // read arguments.
    SkipInterfaceMemberNameReference();  // read interface_target_reference.
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(position, strict_cmp_kind, /*number_check = */ true);
  }

  LocalVariable* receiver_temp = nullptr;
  if (direct_call.check_receiver_for_null_) {
    receiver_temp = MakeTemporary();
  }

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

  if (!is_dynamic) {
    SkipDartType();  // read function_type.
  }

  const Function* interface_target = &Function::null_function();
  // read interface_target_reference.
  const NameIndex itarget_name =
      is_dynamic ? NameIndex() : ReadInterfaceMemberNameReference();
  // TODO(dartbug.com/34497): Once front-end desugars calls via
  // fields/getters, filtering of field and getter interface targets here
  // can be turned into assertions.
  if (!H.IsRoot(itarget_name) && !H.IsGetter(itarget_name)) {
    interface_target = &Function::ZoneHandle(
        Z, H.LookupMethodByMember(itarget_name,
                                  H.DartProcedureName(itarget_name)));
    ASSERT(name.ptr() == interface_target->name());
    ASSERT(!interface_target->IsGetterFunction());
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver_temp, name);
  }

  const String* mangled_name = &name;
  // Do not mangle ==:
  //   * operator == takes an Object so its either not checked or checked
  //     at the entry because the parameter is marked covariant, neither of
  //     those cases require a dynamic invocation forwarder.
  const Function* direct_call_target = &direct_call.target_;
  if (H.IsRoot(itarget_name) &&
      (name.ptr() != Symbols::EqualOperator().ptr())) {
    mangled_name = &String::ZoneHandle(
        Z, Function::CreateDynamicInvocationForwarderName(name));
    if (!direct_call_target->IsNull()) {
      direct_call_target = &Function::ZoneHandle(
          direct_call_target->GetDynamicInvocationForwarder(*mangled_name));
    }
  }

  if (!direct_call_target->IsNull()) {
    // Even if TFA infers a concrete receiver type, the static type of the
    // call-site may still be dynamic and we need to call the dynamic invocation
    // forwarder to ensure type-checks are performed.
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, *direct_call_target, argument_count,
                   argument_names, ICData::kNoRebind, &result_type,
                   type_args_len, /*use_unchecked_entry=*/is_unchecked_call);
  } else {
    instructions += InstanceCall(
        position, *mangled_name, token_kind, type_args_len, argument_count,
        argument_names, checked_argument_count, *interface_target,
        Function::null_function(), &result_type,
        /*use_unchecked_entry=*/is_unchecked_call, &call_site_attributes,
        result_type.ReceiverNotInt(), is_call_on_this);
  }

  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.ptr() == Symbols::AssignIndexToken().ptr()) {
    instructions += Drop();
    instructions += NullConstant();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildLocalFunctionInvocation(
    TokenPosition* p) {
  const TokenPosition position = ReadPosition();
  if (p != nullptr) *p = position;
  // read variable kernel position.
  const intptr_t variable_kernel_position = ReadUInt();
  ReadUInt();  // read relative variable index.

  LocalVariable* variable = LookupVariable(variable_kernel_position);
  ASSERT(!variable->is_late());

  auto& target_function = Function::ZoneHandle(Z);
  {
    AlternativeReadingScope alt(
        &reader_, variable_kernel_position - data_program_offset_);
    SkipVariableDeclaration();
    // FunctionNode follows the variable declaration.
    const intptr_t function_node_kernel_offset = ReaderOffset();

    target_function = ClosureFunctionsCache::LookupClosureFunction(
        Function::Handle(Z,
                         parsed_function()->function().GetOutermostFunction()),
        function_node_kernel_offset);
    RELEASE_ASSERT(!target_function.IsNull());
  }

  Fragment instructions;

  // Type arguments.
  intptr_t type_args_len = 0;
  {
    AlternativeReadingScope alt(&reader_);
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }
    type_args_len = list_length;
  }

  // Receiver (closure).
  instructions += LoadLocal(variable);

  intptr_t argument_count;
  intptr_t positional_argument_count;
  Array& argument_names = Array::ZoneHandle(Z);
  instructions +=
      BuildArguments(&argument_names, &argument_count,
                     &positional_argument_count);  // read arguments.
  ++argument_count;                                // include receiver

  SkipDartType();  // read function_type.

  // Lookup the function in the closure.
  instructions += LoadLocal(variable);
  if (!FLAG_precompiled_mode) {
    instructions += LoadNativeField(Slot::Closure_function());
  }
  if (parsed_function()->function().is_debuggable()) {
    ASSERT(!parsed_function()->function().is_native());
    instructions += DebugStepCheck(position);
  }
  instructions += B->ClosureCall(target_function, position, type_args_len,
                                 argument_count, argument_names);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionInvocation(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  const FunctionAccessKind function_access_kind =
      static_cast<FunctionAccessKind>(ReadByte());  // read kind.
  const TokenPosition position = ReadPosition();    // read position.
  if (p != nullptr) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  RELEASE_ASSERT((function_access_kind == FunctionAccessKind::kFunction) ||
                 (function_access_kind == FunctionAccessKind::kFunctionType));
  const bool is_unchecked_closure_call =
      (function_access_kind == FunctionAccessKind::kFunctionType);
  Fragment instructions;

  instructions += BuildExpression();  // read receiver.
  LocalVariable* receiver_temp = MakeTemporary();

  // Type arguments.
  intptr_t type_args_len = 0;
  {
    AlternativeReadingScope alt(&reader_);
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }
    type_args_len = list_length;
  }

  // Receiver (closure).
  instructions += LoadLocal(receiver_temp);

  intptr_t argument_count;
  intptr_t positional_argument_count;
  Array& argument_names = Array::ZoneHandle(Z);
  instructions +=
      BuildArguments(&argument_names, &argument_count,
                     &positional_argument_count);  // read arguments.
  ++argument_count;                                // include receiver

  SkipDartType();  // read function_type.

  if (is_unchecked_closure_call) {
    instructions += CheckNull(position, receiver_temp, Symbols::call());
    // Lookup the function in the closure.
    instructions += LoadLocal(receiver_temp);
    if (!FLAG_precompiled_mode) {
      instructions += LoadNativeField(Slot::Closure_function());
    }
    if (parsed_function()->function().is_debuggable()) {
      ASSERT(!parsed_function()->function().is_native());
      instructions += DebugStepCheck(position);
    }
    instructions +=
        B->ClosureCall(Function::null_function(), position, type_args_len,
                       argument_count, argument_names);
  } else {
    instructions += InstanceCall(
        position, Symbols::DynamicCall(), Token::kILLEGAL, type_args_len,
        argument_count, argument_names, 1, Function::null_function(),
        Function::null_function(), &result_type,
        /*use_unchecked_entry=*/false, /*call_site_attrs=*/nullptr,
        result_type.ReceiverNotInt());
  }
  instructions += DropTempsPreserveTop(1);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildEqualsCall(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForMethodInvocation(offset);
  ASSERT(!direct_call.check_receiver_for_null_);
  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);
  const CallSiteAttributesMetadata call_site_attributes =
      call_site_attributes_metadata_helper_.GetCallSiteAttributes(offset);

  Fragment instructions;
  instructions += BuildExpression();  // read left.
  instructions += BuildExpression();  // read right.
  SkipDartType();                     // read function_type.

  const NameIndex itarget_name =
      ReadInterfaceMemberNameReference();  // read interface_target_reference.
  const auto& interface_target = Function::ZoneHandle(
      Z,
      H.LookupMethodByMember(itarget_name, H.DartProcedureName(itarget_name)));
  ASSERT(interface_target.name() == Symbols::EqualOperator().ptr());

  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 2;
  const intptr_t kNumCheckedArgs = 2;

  if (!direct_call.target_.IsNull()) {
    ASSERT(CompilerState::Current().is_aot());
    instructions +=
        StaticCall(position, direct_call.target_, kNumArgs, Array::null_array(),
                   ICData::kNoRebind, &result_type, kTypeArgsLen,
                   /*use_unchecked_entry=*/true);
  } else {
    instructions += InstanceCall(
        position, Symbols::EqualOperator(), Token::kEQ, kTypeArgsLen, kNumArgs,
        Array::null_array(), kNumCheckedArgs, interface_target,
        Function::null_function(), &result_type,
        /*use_unchecked_entry=*/true, &call_site_attributes,
        result_type.ReceiverNotInt());
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildEqualsNull(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;
  Fragment instructions;
  instructions += BuildExpression();  // read expression.
  instructions += NullConstant();
  if (parsed_function()->function().is_debuggable()) {
    instructions += DebugStepCheck(position);
  }
  instructions +=
      StrictCompare(position, Token::kEQ_STRICT, /*number_check=*/false);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperMethodInvocation(
    TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

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

    SkipInterfaceMemberNameReference();  //  skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(thread(), Z, klass);
    instructions += StaticCall(TokenPosition::kNoSource,
                               Function::ZoneHandle(Z, nsm_function.ptr()),
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
      }
    }

    // receiver
    instructions += LoadLocal(parsed_function()->receiver_var());

    Array& argument_names = Array::ZoneHandle(Z);
    intptr_t argument_count;
    instructions += BuildArguments(
        &argument_names, &argument_count,
        /* positional_argument_count = */ nullptr);  // read arguments.
    ++argument_count;                                // include receiver
    SkipInterfaceMemberNameReference();              // interfaceTargetReference
    return instructions +
           StaticCall(position, Function::ZoneHandle(Z, function.ptr()),
                      argument_count, argument_names, ICData::kSuper,
                      &result_type, type_args_len,
                      /*use_unchecked_entry_point=*/true);
  }
}

Fragment StreamingFlowGraphBuilder::BuildStaticInvocation(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.
  TokenPosition position = ReadPosition();     // read position.
  if (p != nullptr) *p = position;

  const InferredTypeMetadata result_type =
      inferred_type_metadata_helper_.GetInferredType(offset);

  NameIndex procedure_reference =
      ReadCanonicalNameReference();  // read procedure reference.
  intptr_t argument_count = PeekArgumentsCount();
  const Function& target =
      Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(
                                  procedure_reference, /*required=*/false));

  if (target.IsNull()) {
    Fragment instructions;
    Array& argument_names = Array::ZoneHandle(Z);
    instructions +=
        BuildArguments(&argument_names, nullptr /* arg count */,
                       nullptr /* positional arg count */);  // read arguments.
    instructions += StaticCallMissing(
        position, H.DartSymbolPlain(H.CanonicalNameString(procedure_reference)),
        argument_count,
        H.IsLibrary(H.EnclosingName(procedure_reference))
            ? InvocationMirror::Level::kTopLevel
            : InvocationMirror::Level::kStatic,
        InvocationMirror::Kind::kMethod);
    return instructions;
  }

  const Class& klass = Class::ZoneHandle(Z, target.Owner());
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }

  if (target.IsCachableIdempotent()) {
    return BuildCachableIdempotentCall(position, target);
  }

  const auto recognized_kind = target.recognized_kind();
  switch (recognized_kind) {
    case MethodRecognizer::kNativeEffect:
      return BuildNativeEffect();
    case MethodRecognizer::kReachabilityFence:
      return BuildReachabilityFence();
    case MethodRecognizer::kFfiAsFunctionInternal:
      return BuildFfiAsFunctionInternal();
    case MethodRecognizer::kFfiNativeCallbackFunction:
      return BuildFfiNativeCallbackFunction(
          FfiFunctionKind::kIsolateLocalStaticCallback);
    case MethodRecognizer::kFfiNativeIsolateLocalCallbackFunction:
      return BuildFfiNativeCallbackFunction(
          FfiFunctionKind::kIsolateLocalClosureCallback);
    case MethodRecognizer::kFfiNativeAsyncCallbackFunction:
      return BuildFfiNativeCallbackFunction(FfiFunctionKind::kAsyncCallback);
    case MethodRecognizer::kFfiLoadAbiSpecificInt:
      return BuildLoadAbiSpecificInt(/*at_index=*/false);
    case MethodRecognizer::kFfiLoadAbiSpecificIntAtIndex:
      return BuildLoadAbiSpecificInt(/*at_index=*/true);
    case MethodRecognizer::kFfiStoreAbiSpecificInt:
      return BuildStoreAbiSpecificInt(/*at_index=*/false);
    case MethodRecognizer::kFfiStoreAbiSpecificIntAtIndex:
      return BuildStoreAbiSpecificInt(/*at_index=*/true);
    default:
      break;
  }

  Fragment instructions;
  LocalVariable* instance_variable = nullptr;

  const bool special_case_unchecked_cast =
      klass.IsTopLevel() && (klass.library() == Library::InternalLibrary()) &&
      (target.name() == Symbols::UnsafeCast().ptr());

  const bool special_case_identical =
      klass.IsTopLevel() && (klass.library() == Library::CoreLibrary()) &&
      (target.name() == Symbols::Identical().ptr());

  const bool special_case =
      special_case_identical || special_case_unchecked_cast;

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
      instructions += AllocateObject(position, klass, 1);
    } else {
      instructions += AllocateObject(position, klass, 0);
    }

    instance_variable = MakeTemporary();

    instructions += LoadLocal(instance_variable);
  } else if (target.IsFactory()) {
    // The VM requires currently a TypeArguments object as first parameter for
    // every factory constructor :-/ !
    //
    // TODO(27590): Get rid of this after we're using core libraries compiled
    // into Kernel.
    const TypeArguments& type_arguments = PeekArgumentsInstantiatedType(klass);
    instructions += TranslateInstantiatedTypeArguments(type_arguments);
  } else if (!special_case) {
    AlternativeReadingScope alt(&reader_);
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }
    type_args_len = list_length;
  }

  Array& argument_names = Array::ZoneHandle(Z);
  instructions +=
      BuildArguments(&argument_names, nullptr /* arg count */,
                     nullptr /* positional arg count */);  // read arguments.
  ASSERT(!special_case ||
         target.AreValidArguments(type_args_len, argument_count, argument_names,
                                  nullptr));

  // Special case identical(x, y) call.
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (special_case_identical) {
    ASSERT(argument_count == 2);
    instructions +=
        StrictCompare(position, Token::kEQ_STRICT, /*number_check=*/true);
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

    // After reaching debugger(), we automatically do one single-step.
    // Ensure this doesn't cause us to exit the current scope.
    if (recognized_kind == MethodRecognizer::kDebugger) {
      instructions += DebugStepCheck(position);
    }
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildConstructorInvocation(
    TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Class& klass = Class::ZoneHandle(
      Z, H.LookupClassByKernelClass(H.EnclosingName(kernel_name),
                                    /*required=*/false));
  Fragment instructions;
  if (klass.IsNull()) {
    Array& argument_names = Array::ZoneHandle(Z);
    intptr_t argument_count;
    instructions += BuildArguments(
        &argument_names, &argument_count,
        /* positional_argument_count = */ nullptr);  // read arguments.
    instructions += StaticCallMissing(
        position, H.DartSymbolPlain(H.CanonicalNameString(kernel_name)),
        argument_count, InvocationMirror::Level::kConstructor,
        InvocationMirror::Kind::kMethod);
    return instructions;
  }
  const auto& error = klass.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());

  if (klass.NumTypeArguments() > 0) {
    if (!klass.IsGeneric()) {
      const TypeArguments& type_arguments = TypeArguments::ZoneHandle(
          Z, klass.GetDeclarationInstanceTypeArguments());
      instructions += Constant(type_arguments);
    } else {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }

    instructions += AllocateObject(position, klass, 1);
  } else {
    instructions += AllocateObject(position, klass, 0);
  }
  LocalVariable* variable = MakeTemporary();

  instructions += LoadLocal(variable);

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions += BuildArguments(
      &argument_names, &argument_count,
      /* positional_argument_count = */ nullptr);  // read arguments.

  const Function& target =
      Function::ZoneHandle(Z, H.LookupConstructorByKernelConstructor(
                                  klass, kernel_name, /*required=*/false));
  ++argument_count;

  if (target.IsNull()) {
    instructions += StaticCallMissing(
        position, H.DartSymbolPlain(H.CanonicalNameString(kernel_name)),
        argument_count, InvocationMirror::Level::kConstructor,
        InvocationMirror::Kind::kMethod);
  } else {
    instructions += StaticCall(position, target, argument_count, argument_names,
                               ICData::kStatic, /* result_type = */ nullptr);
  }
  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildNot(TokenPosition* p) {
  TokenPosition position = ReadPosition();
  if (p != nullptr) *p = position;

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
  Fragment instructions = BuildExpression(&operand_position);
  LocalVariable* expr_temp = MakeTemporary();
  instructions += CheckNull(position, expr_temp, String::null_string());

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
    ReadPosition();
    negated = !negated;
  }

  Fragment right_value(op == kAnd
                           ? left.CreateTrueSuccessor(flow_graph_builder_)
                           : left.CreateFalseSuccessor(flow_graph_builder_));

  if (PeekTag() == kLogicalExpression) {
    SkipBytes(1);
    ReadPosition();
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

Fragment StreamingFlowGraphBuilder::BuildLogicalExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();
  if (p != nullptr) *p = position;

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
    TokenPosition* p) {
  TokenPosition position = ReadPosition();
  if (p != nullptr) *p = position;

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

void StreamingFlowGraphBuilder::FlattenStringConcatenation(
    PiecesCollector* collector) {
  const auto length = ReadListLength();
  for (intptr_t i = 0; i < length; ++i) {
    const auto offset = reader_.offset();
    switch (PeekTag()) {
      case kStringLiteral: {
        ReadTag();
        ReadPosition();
        const String& s = H.DartSymbolPlain(ReadStringReference());
        // Skip empty strings.
        if (!s.Equals("")) {
          collector->Add({-1, &s});
        }
        break;
      }
      case kStringConcatenation: {
        // Flatten by hoisting nested expressions up into the outer concat.
        ReadTag();
        ReadPosition();
        FlattenStringConcatenation(collector);
        break;
      }
      default: {
        collector->Add({offset, nullptr});
        SkipExpression();
      }
    }
  }
}

Fragment StreamingFlowGraphBuilder::BuildStringConcatenation(TokenPosition* p) {
  TokenPosition position = ReadPosition();
  if (p != nullptr) {
    *p = position;
  }

  // Collect and flatten all pieces of this and any nested StringConcats.
  // The result is a single sequence of pieces, potentially flattened to
  // a single String.
  // The collector will hold concatenated strings and Reader offsets of
  // non-string pieces.
  PiecesCollector collector(Z, &H);
  FlattenStringConcatenation(&collector);
  collector.FlushRun();

  if (collector.pieces.length() == 1) {
    // No need to Interp. a single string, so return string as a Constant:
    if (collector.pieces[0].literal != nullptr) {
      return Constant(*collector.pieces[0].literal);
    }
    // A single non-string piece is handle by StringInterpolateSingle:
    AlternativeReadingScope scope(&reader_, collector.pieces[0].offset);
    Fragment instructions;
    instructions += BuildExpression();
    instructions += StringInterpolateSingle(position);
    return instructions;
  }

  Fragment instructions;
  instructions += Constant(TypeArguments::ZoneHandle(Z));
  instructions += IntConstant(collector.pieces.length());
  instructions += CreateArray();
  LocalVariable* array = MakeTemporary();
  for (intptr_t i = 0; i < collector.pieces.length(); ++i) {
    // All pieces are now either a concat'd string or an expression we can
    // read at a given offset.
    if (collector.pieces[i].literal != nullptr) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += Constant(*collector.pieces[i].literal);
    } else {
      AlternativeReadingScope scope(&reader_, collector.pieces[i].offset);
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += BuildExpression();
    }
    instructions += StoreIndexed(kArrayCid);
  }

  instructions += StringInterpolate(position);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIsTest(TokenPosition position,
                                                const AbstractType& type) {
  Fragment instructions;
  // The VM does not like an instanceOf call with a dynamic type. We need to
  // special case this situation by detecting a top type.
  if (type.IsTopTypeForInstanceOf()) {
    // Evaluate the expression on the left but ignore its result.
    instructions += Drop();

    // Let condition be always true.
    instructions += Constant(Bool::True());
  } else {
    // See if simple instanceOf is applicable.
    if (dart::SimpleInstanceOfType(type)) {
      instructions += Constant(type);
      instructions += InstanceCall(
          position, Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()),
          Token::kIS, 2, 2);  // 2 checked arguments.
      return instructions;
    }

    if (type.IsRecordType()) {
      instructions += BuildRecordIsTest(position, RecordType::Cast(type));
      return instructions;
    }

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

    instructions += Constant(type);

    instructions += InstanceCall(
        position, Library::PrivateCoreLibName(Symbols::_instanceOf()),
        Token::kIS, 4);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildRecordIsTest(TokenPosition position,
                                                      const RecordType& type) {
  // Type of a record instance depends on the runtime types of all
  // its fields, so subtype test cache cannot be used for testing
  // record types and runtime call is used.
  // So it is more efficient to test each record field separately
  // without going to runtime.

  Fragment instructions;
  JoinEntryInstr* is_true = BuildJoinEntry();
  JoinEntryInstr* is_false = BuildJoinEntry();
  LocalVariable* instance = MakeTemporary();

  // Test if instance is null.
  if (type.IsNullable()) {
    TargetEntryInstr* is_null;
    TargetEntryInstr* not_null;

    instructions += LoadLocal(instance);
    instructions += BranchIfNull(&is_null, &not_null);
    Fragment(is_null) + Goto(is_true);
    instructions.current = not_null;
  }

  // Test if instance is record.
  {
    TargetEntryInstr* is_record;
    TargetEntryInstr* not_record;

    instructions += LoadLocal(instance);
    instructions += B->LoadClassId();
    instructions += IntConstant(kRecordCid);
    instructions += BranchIfEqual(&is_record, &not_record);
    Fragment(not_record) + Goto(is_false);
    instructions.current = is_record;
  }

  // Test record shape.
  {
    TargetEntryInstr* same_shape;
    TargetEntryInstr* different_shape;

    instructions += LoadLocal(instance);
    instructions += LoadNativeField(Slot::Record_shape());
    instructions += IntConstant(type.shape().AsInt());
    instructions += BranchIfEqual(&same_shape, &different_shape);
    Fragment(different_shape) + Goto(is_false);
    instructions.current = same_shape;
  }

  // Test each record field
  for (intptr_t i = 0, n = type.NumFields(); i < n; ++i) {
    TargetEntryInstr* success;
    TargetEntryInstr* failure;

    instructions += LoadLocal(instance);
    instructions += LoadNativeField(Slot::GetRecordFieldSlot(
        H.thread(), compiler::target::Record::field_offset(i)));
    instructions +=
        BuildIsTest(position, AbstractType::ZoneHandle(Z, type.FieldTypeAt(i)));
    instructions += Constant(Bool::True());
    instructions += BranchIfEqual(&success, &failure);
    Fragment(failure) + Goto(is_false);
    instructions.current = success;
  }

  instructions += Goto(is_true);

  JoinEntryInstr* join = BuildJoinEntry();
  LocalVariable* expr_temp = parsed_function()->expression_temp_var();

  instructions.current = is_true;
  instructions += Constant(Bool::True());
  instructions += StoreLocal(TokenPosition::kNoSource, expr_temp);
  instructions += Drop();
  instructions += Goto(join);

  instructions.current = is_false;
  instructions += Constant(Bool::False());
  instructions += StoreLocal(TokenPosition::kNoSource, expr_temp);
  instructions += Drop();
  instructions += Goto(join);

  instructions.current = join;
  instructions += Drop();  // Instance.
  instructions += LoadLocal(expr_temp);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  ReadFlags();

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.

  instructions += BuildIsTest(position, type);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const uint8_t flags = ReadFlags();  // read flags.
  const bool is_unchecked_cast = (flags & kAsExpressionFlagUnchecked) != 0;
  const bool is_type_error = (flags & kAsExpressionFlagTypeError) != 0;

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.
  if (is_unchecked_cast ||
      (type.IsInstantiated() && type.IsTopTypeForSubtyping())) {
    // We already evaluated the operand on the left and just leave it there as
    // the result of unchecked cast or `obj as dynamic` expression.
  } else {
    // We do not care whether the 'as' cast as implicitly added by the frontend
    // or explicitly written by the user, in both cases we use an assert
    // assignable.
    instructions += B->AssertAssignableLoadTypeArguments(
        position, type,
        is_type_error ? Symbols::Empty() : Symbols::InTypeCast(),
        AssertAssignableInstr::kInsertedByFrontend);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildTypeLiteral(TokenPosition* position) {
  TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

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
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  return LoadLocal(parsed_function()->receiver_var());
}

Fragment StreamingFlowGraphBuilder::BuildRethrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  Fragment instructions = DebugStepCheck(position);
  instructions += LoadLocal(catch_block()->exception_var());
  instructions += LoadLocal(catch_block()->stack_trace_var());
  instructions += RethrowException(position, catch_block()->catch_try_index());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildThrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  Fragment instructions;

  instructions += BuildExpression();  // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions += ThrowException(position);
  ASSERT(instructions.is_closed());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildListLiteral(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const TypeArguments& type_arguments = T.BuildTypeArguments(1);  // read type.
  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" expressions.

  // The type argument for the factory call.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);

  // List literals up to 8 elements are lowered in the front-end
  // (pkg/vm/lib/transformations/list_literals_lowering.dart)
  const intptr_t kNumSpecializedListLiteralConstructors = 8;
  ASSERT(length > kNumSpecializedListLiteralConstructors);

  LocalVariable* type = MakeTemporary();
  instructions += LoadLocal(type);

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

  const Class& growable_list_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::_GrowableList()));
  ASSERT(!growable_list_class.IsNull());

  const Function& factory_method =
      Function::ZoneHandle(Z, growable_list_class.LookupFunctionAllowPrivate(
                                  Symbols::_GrowableListLiteralFactory()));
  ASSERT(!factory_method.IsNull());

  instructions += StaticCall(position, factory_method, 2, ICData::kStatic);
  instructions += DropTempsPreserveTop(1);  // Instantiated type_arguments.
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildMapLiteral(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  const TypeArguments& type_arguments =
      T.BuildTypeArguments(2);  // read key_type and value_type.

  // The type argument for the factory call `new Map<K, V>._fromLiteral(List)`.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);

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

  const Class& map_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::Map()));
  Function& factory_method = Function::ZoneHandle(Z);
  if (map_class.EnsureIsFinalized(H.thread()) == Error::null()) {
    factory_method = map_class.LookupFactory(
        Library::PrivateCoreLibName(Symbols::MapLiteralFactory()));
  }

  return instructions +
         StaticCall(position, factory_method, 2, ICData::kStatic);
}

Fragment StreamingFlowGraphBuilder::BuildRecordLiteral(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  // Figure out record shape.
  const intptr_t positional_count = ReadListLength();
  intptr_t named_count = -1;
  const Array* field_names = &Object::empty_array();
  {
    AlternativeReadingScope alt(&reader_);
    for (intptr_t i = 0; i < positional_count; ++i) {
      SkipExpression();
    }
    named_count = ReadListLength();
    if (named_count > 0) {
      Array& names = Array::ZoneHandle(Z, Array::New(named_count, Heap::kOld));
      for (intptr_t i = 0; i < named_count; ++i) {
        String& name =
            H.DartSymbolObfuscate(ReadStringReference());  // read ith name.
        SkipExpression();  // read ith expression.
        names.SetAt(i, name);
      }
      names.MakeImmutable();
      field_names = &names;
    }
  }
  const intptr_t num_fields = positional_count + named_count;
  const RecordShape shape =
      RecordShape::Register(thread(), num_fields, *field_names);
  Fragment instructions;

  if (num_fields == 2 ||
      (num_fields == 3 && AllocateSmallRecordABI::kValue2Reg != kNoRegister)) {
    // Generate specialized allocation for a small number of fields.
    for (intptr_t i = 0; i < positional_count; ++i) {
      instructions += BuildExpression();  // read ith expression.
    }
    ReadListLength();  // read list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      SkipStringReference();              // read ith name.
      instructions += BuildExpression();  // read ith expression.
    }
    SkipDartType();  // read recordType.

    instructions += B->AllocateSmallRecord(position, shape);

    return instructions;
  }

  instructions += B->AllocateRecord(position, shape);
  LocalVariable* record = MakeTemporary();

  // List of positional.
  intptr_t pos = 0;
  for (intptr_t i = 0; i < positional_count; ++i, ++pos) {
    instructions += LoadLocal(record);
    instructions += BuildExpression();  // read ith expression.
    instructions += B->StoreNativeField(
        Slot::GetRecordFieldSlot(thread(),
                                 compiler::target::Record::field_offset(pos)),
        StoreFieldInstr::Kind::kInitializing);
  }

  // List of named.
  ReadListLength();  // read list length.
  for (intptr_t i = 0; i < named_count; ++i, ++pos) {
    SkipStringReference();  // read ith name.
    instructions += LoadLocal(record);
    instructions += BuildExpression();  // read ith expression.
    instructions += B->StoreNativeField(
        Slot::GetRecordFieldSlot(thread(),
                                 compiler::target::Record::field_offset(pos)),
        StoreFieldInstr::Kind::kInitializing);
  }

  SkipDartType();  // read recordType.

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildRecordFieldGet(TokenPosition* p,
                                                        bool is_named) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  Fragment instructions = BuildExpression();  // read receiver.
  const RecordType& record_type =
      RecordType::Cast(T.BuildType());  // read recordType.

  intptr_t field_index = -1;
  const Array& field_names =
      Array::Handle(Z, record_type.GetFieldNames(H.thread()));
  const intptr_t num_positional_fields =
      record_type.NumFields() - field_names.Length();
  if (is_named) {
    const String& field_name = H.DartSymbolObfuscate(ReadStringReference());
    for (intptr_t i = 0, n = field_names.Length(); i < n; ++i) {
      if (field_names.At(i) == field_name.ptr()) {
        field_index = i;
        break;
      }
    }
    ASSERT(field_index >= 0 && field_index < field_names.Length());
    field_index += num_positional_fields;
  } else {
    field_index = ReadUInt();
    ASSERT(field_index < num_positional_fields);
  }

  instructions += B->LoadNativeField(Slot::GetRecordFieldSlot(
      thread(), compiler::target::Record::field_offset(field_index)));
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionExpression() {
  ReadPosition();  // read position.
  return BuildFunctionNode(TokenPosition::kNoSource, StringIndex(),
                           /*has_valid_annotation=*/false, /*has_pragma=*/false,
                           /*func_decl_offset=*/0);
}

Fragment StreamingFlowGraphBuilder::BuildLet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;
  Fragment instructions = BuildVariableDeclaration(nullptr);  // read variable.
  instructions += BuildExpression();                          // read body.
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBlockExpression() {
  block_expression_depth_inc();
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);

  ReadPosition();                                 // ignore file offset.
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
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  const String& value =
      H.DartString(ReadStringReference());  // read index into string table.
  const Integer& integer = Integer::ZoneHandle(Z, Integer::NewCanonical(value));
  if (integer.IsNull()) {
    const auto& script = Script::Handle(Z, Script());
    H.ReportError(script, TokenPosition::kNoSource,
                  "Integer literal %s is out of range", value.ToCString());
    UNREACHABLE();
  }
  return Constant(integer);
}

Fragment StreamingFlowGraphBuilder::BuildStringLiteral(
    TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  return Constant(H.DartSymbolPlain(
      ReadStringReference()));  // read index into string table.
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(uint8_t payload,
                                                    TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(bool is_negative,
                                                    TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  int64_t value = is_negative ? -static_cast<int64_t>(ReadUInt())
                              : ReadUInt();  // read value.
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildDoubleLiteral(
    TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  Double& constant = Double::ZoneHandle(
      Z, Double::NewCanonical(ReadDouble()));  // read double.
  return Constant(constant);
}

Fragment StreamingFlowGraphBuilder::BuildBoolLiteral(bool value,
                                                     TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  return Constant(Bool::Get(value));
}

Fragment StreamingFlowGraphBuilder::BuildNullLiteral(TokenPosition* position) {
  ReadPosition();  // ignore file offset.
  if (position != nullptr) *position = TokenPosition::kNoSource;

  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}

Fragment StreamingFlowGraphBuilder::BuildFutureNullValue(
    TokenPosition* position) {
  if (position != nullptr) *position = TokenPosition::kNoSource;
  const Class& future = Class::Handle(Z, IG->object_store()->future_class());
  ASSERT(!future.IsNull());
  const auto& error = future.EnsureIsFinalized(thread());
  ASSERT(error == Error::null());
  Function& constructor = Function::ZoneHandle(
      Z, Resolver::ResolveFunction(Z, future, Symbols::FutureValue()));
  ASSERT(!constructor.IsNull());

  Fragment instructions;
  instructions += BuildNullLiteral(position);
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
  } else if (tag == kFileUriConstantExpression) {
    // TODO(alexmarkov): Use file offset together with file uri.
    ReadPosition();
    ReadUInt();
    SkipDartType();
  }
  if (position != nullptr) *position = p;
  const intptr_t constant_index = ReadUInt();
  Fragment result = Constant(
      Object::ZoneHandle(Z, constant_reader_.ReadConstant(constant_index)));
  return result;
}

Fragment StreamingFlowGraphBuilder::BuildPartialTearoffInstantiation(
    TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != nullptr) *p = position;

  // Create a copy of the closure.

  Fragment instructions = BuildExpression();
  LocalVariable* original_closure = MakeTemporary();

  // Load the target function and context and allocate the closure.
  instructions += LoadLocal(original_closure);
  instructions +=
      flow_graph_builder_->LoadNativeField(Slot::Closure_function());
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(Slot::Closure_context());
  instructions += flow_graph_builder_->AllocateClosure();
  LocalVariable* new_closure = MakeTemporary();

  intptr_t num_type_args = ReadListLength();
  const TypeArguments& type_args = T.BuildTypeArguments(num_type_args);
  instructions += TranslateInstantiatedTypeArguments(type_args);
  LocalVariable* type_args_vec = MakeTemporary("type_args");

  // Check the bounds.
  //
  // TODO(sjindel): We should be able to skip this check in many cases, e.g.
  // when the closure is coming from a tearoff of a top-level method or from a
  // local closure.
  instructions += LoadLocal(original_closure);
  instructions += LoadLocal(type_args_vec);
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
  instructions += flow_graph_builder_->StoreNativeField(
      Slot::Closure_delayed_type_arguments(),
      StoreFieldInstr::Kind::kInitializing);
  instructions += DropTemporary(&type_args_vec);

  // Copy over the instantiator type arguments.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(
      Slot::Closure_instantiator_type_arguments());
  instructions += flow_graph_builder_->StoreNativeField(
      Slot::Closure_instantiator_type_arguments(),
      StoreFieldInstr::Kind::kInitializing);

  // Copy over the function type arguments.
  instructions += LoadLocal(new_closure);
  instructions += LoadLocal(original_closure);
  instructions += flow_graph_builder_->LoadNativeField(
      Slot::Closure_function_type_arguments());
  instructions += flow_graph_builder_->StoreNativeField(
      Slot::Closure_function_type_arguments(),
      StoreFieldInstr::Kind::kInitializing);

  instructions += DropTempsPreserveTop(1);  // Drop old closure.

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildLibraryPrefixAction(
    TokenPosition* position,
    const String& selector) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  const intptr_t dependency_index = ReadUInt();
  const Library& current_library = Library::Handle(
      Z, Class::Handle(Z, parsed_function()->function().Owner()).library());
  const Array& dependencies = Array::Handle(Z, current_library.dependencies());
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedZoneHandle(Z, dependencies.At(dependency_index));
  const Function& function =
      Function::ZoneHandle(Z, Library::Handle(Z, Library::CoreLibrary())
                                  .LookupFunctionAllowPrivate(selector));
  ASSERT(!function.IsNull());
  Fragment instructions;
  instructions += Constant(prefix);
  instructions += StaticCall(pos, function, 1, ICData::kStatic);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAwaitExpression(
    TokenPosition* position) {
  ASSERT(parsed_function()->function().IsAsyncFunction() ||
         parsed_function()->function().IsAsyncGenerator());
  Fragment instructions;

  const TokenPosition pos = ReadPosition();  // read file offset.
  if (position != nullptr) *position = pos;

  instructions += BuildExpression();  // read operand.

  SuspendInstr::StubId stub_id = SuspendInstr::StubId::kAwait;
  if (ReadTag() == kSomething) {
    const AbstractType& type = T.BuildType();  // read runtime check type.
    if (!type.IsType() ||
        !Class::Handle(Z, type.type_class()).IsFutureClass()) {
      FATAL("Unexpected type for runtime check in await: %s", type.ToCString());
    }
    ASSERT(type.IsFinalized());
    const auto& type_args =
        TypeArguments::ZoneHandle(Z, Type::Cast(type).arguments());
    if (!type_args.IsNull()) {
      const auto& type_arg = AbstractType::Handle(Z, type_args.TypeAt(0));
      if (!type_arg.IsTopTypeForSubtyping()) {
        instructions += TranslateInstantiatedTypeArguments(type_args);
        stub_id = SuspendInstr::StubId::kAwaitWithTypeCheck;
      }
    }
  }

  if (NeedsDebugStepCheck(parsed_function()->function(), pos)) {
    instructions += DebugStepCheck(pos);
  }
  instructions += B->Suspend(pos, stub_id);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFileUriExpression(
    TokenPosition* position) {
  ReadUInt();  // read uri

  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  return BuildExpression(position);  // read expression.
}

Fragment StreamingFlowGraphBuilder::BuildExpressionStatement(
    TokenPosition* position) {
  Fragment instructions = BuildExpression(position);  // read expression.
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBlock(TokenPosition* position) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  const TokenPosition pos = ReadPosition();  // read file offset.
  if (position != nullptr) *position = pos;

  ReadPosition();  // read file end offset.

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

Fragment StreamingFlowGraphBuilder::BuildAssertBlock(TokenPosition* position) {
  if (!IG->asserts()) {
    SkipStatementList();
    return Fragment();
  }

  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  intptr_t list_length = ReadListLength();  // read number of statements.
  for (intptr_t i = 0; i < list_length; ++i) {
    if (instructions.is_open()) {
      // read ith statement.
      instructions += BuildStatement(i == 0 ? position : nullptr);
    } else {
      SkipStatement();  // read ith statement.
    }
  }
  instructions += ExitScope(offset);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAssertStatement(
    TokenPosition* position) {
  if (!IG->asserts()) {
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
  instructions += BuildExpression(position);  // read condition.

  const TokenPosition condition_start_offset =
      ReadPosition();  // read condition start offset.
  const TokenPosition condition_end_offset =
      ReadPosition();  // read condition end offset.

  instructions += EvaluateAssertion();
  instructions += RecordCoverage(condition_start_offset);
  instructions += CheckBoolean(condition_start_offset);
  instructions += Constant(Bool::True());
  instructions += BranchIfEqual(&then, &otherwise);

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
  otherwise_fragment += IntConstant(condition_end_offset.Pos());
  Tag tag = ReadTag();  // read (first part of) message.
  if (tag == kSomething) {
    otherwise_fragment += BuildExpression();  // read (rest of) message.
  } else {
    otherwise_fragment += Constant(Instance::ZoneHandle(Z));  // null.
  }

  // Note: condition_start_offset points to the first token after the opening
  // paren, not the beginning of 'assert'.
  otherwise_fragment +=
      StaticCall(condition_start_offset, target, 3, ICData::kStatic);
  otherwise_fragment += ThrowException(TokenPosition::kNoSource);
  otherwise_fragment += Drop();

  return Fragment(instructions.entry, then);
}

Fragment StreamingFlowGraphBuilder::BuildLabeledStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  // There can be several cases:
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
  Fragment instructions = BuildStatement(position);  // read body.
  if (block.HadJumper()) {
    if (instructions.is_open()) {
      instructions += Goto(block.destination());
    }
    return Fragment(instructions.entry, block.destination());
  } else {
    return instructions;
  }
}

Fragment StreamingFlowGraphBuilder::BuildBreakStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  intptr_t target_index = ReadUInt();  // read target index.

  TryFinallyBlock* outer_finally = nullptr;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* destination = breakable_block()->BreakDestination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  // Break statement should pause before manipulation of context, which
  // will possibly cause debugger having incorrect context object.
  if (NeedsDebugStepCheck(parsed_function()->function(), pos)) {
    instructions += DebugStepCheck(pos);
  }
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    instructions += Goto(destination);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildWhileStatement(
    TokenPosition* position) {
  loop_depth_inc();
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  TestFragment condition = TranslateConditionForControl();   // read condition.
  const Fragment body = BuildStatementWithBranchCoverage();  // read body

  Fragment body_entry(condition.CreateTrueSuccessor(flow_graph_builder_));
  body_entry += body;

  Instruction* entry;
  if (body_entry.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    body_entry += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow(pos);  // may have non-empty stack
    loop.current->LinkTo(condition.entry);

    entry = Goto(join).entry;
  } else {
    entry = condition.entry;
  }

  loop_depth_dec();
  return Fragment(entry, condition.CreateFalseSuccessor(flow_graph_builder_));
}

Fragment StreamingFlowGraphBuilder::BuildDoStatement(TokenPosition* position) {
  loop_depth_inc();
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  Fragment body = BuildStatementWithBranchCoverage();  // read body.

  if (body.is_closed()) {
    SkipExpression();  // read condition.
    loop_depth_dec();
    return body;
  }

  TestFragment condition = TranslateConditionForControl();

  JoinEntryInstr* join = BuildJoinEntry();
  Fragment loop(join);
  loop += CheckStackOverflow(pos);  // may have non-empty stack
  loop += body;
  loop <<= condition.entry;

  condition.IfTrueGoto(flow_graph_builder_, join);

  loop_depth_dec();
  return Fragment(
      new (Z) GotoInstr(join, CompilerState::Current().GetNextDeoptId()),
      condition.CreateFalseSuccessor(flow_graph_builder_));
}

Fragment StreamingFlowGraphBuilder::BuildForStatement(TokenPosition* position) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  Fragment declarations;

  loop_depth_inc();

  const LocalScope* context_scope = nullptr;
  declarations += EnterScope(offset, &context_scope);

  intptr_t list_length = ReadListLength();  // read number of variables.
  for (intptr_t i = 0; i < list_length; ++i) {
    declarations += BuildVariableDeclaration(nullptr);  // read ith variable.
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
  body += BuildStatementWithBranchCoverage();  // read body.

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
    loop += CheckStackOverflow(pos);  // may have non-empty stack
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

Fragment StreamingFlowGraphBuilder::BuildSwitchStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;
  const bool is_exhaustive = ReadBool();  // read exhaustive flag.

  // We need the number of cases. So start by getting that, then go back.
  const intptr_t offset = ReaderOffset();
  SkipExpression();                        // temporarily skip condition
  SkipOptionalDartType();                  // temporarily skip expression type
  intptr_t case_count = ReadListLength();  // read number of cases.
  SetOffset(offset);

  SwitchBlock block(flow_graph_builder_, case_count);

  Fragment instructions = BuildExpression();  // read condition.
  const AbstractType* expression_type = &Object::dynamic_type();
  if (ReadTag() == kSomething) {
    expression_type = &T.BuildType();  // read expression type.
  }
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
  instructions += Drop();

  case_count = ReadListLength();  // read number of cases.

  SwitchHelper helper(Z, pos, is_exhaustive, *expression_type, &block,
                      case_count);

  // Build the case bodies and collect the expressions into the helper
  // for the next step.
  for (intptr_t i = 0; i < case_count; ++i) {
    helper.AddCaseBody(BuildSwitchCase(&helper, i));
  }

  // Build the code to dispatch to the case bodies.
  switch (helper.SelectDispatchStrategy()) {
    case kSwitchDispatchAuto:
      UNREACHABLE();
    case kSwitchDispatchLinearScan:
      instructions += BuildLinearScanSwitch(&helper);
      break;
    case kSwitchDispatchBinarySearch:
      instructions += BuildBinarySearchSwitch(&helper);
      break;
    case kSwitchDispatchJumpTable:
      instructions += BuildJumpTableSwitch(&helper);
      break;
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSwitchCase(SwitchHelper* helper,
                                                    intptr_t case_index) {
  // Generate case body and try to find out whether the body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  //
  // Also collect switch expressions into helper.

  ReadPosition();                                 // read file offset.
  const int expression_count = ReadListLength();  // read number of expressions.
  for (intptr_t j = 0; j < expression_count; ++j) {
    const TokenPosition pos = ReadPosition();  // read jth position.
    // read jth expression.
    const Instance& value =
        Instance::ZoneHandle(Z, constant_reader_.ReadConstantExpression());
    helper->AddExpression(case_index, pos, value);
  }

  const bool is_default = ReadBool();  // read is_default.
  if (is_default) helper->set_default_case(case_index);
  Fragment body_fragment = BuildStatementWithBranchCoverage();  // read body.

  if (body_fragment.entry == nullptr) {
    // Make a NOP in order to ensure linking works properly.
    body_fragment = NullConstant();
    body_fragment += Drop();
  }

  // TODO(http://dartbug.com/50595): The CFE does not insert breaks for
  // unterminated cases which never reach the end of their control flow.
  // If the CFE inserts synthesized breaks, we can add an assert here instead.
  if (!is_default && body_fragment.is_open() &&
      (case_index < (helper->case_count() - 1))) {
    const auto& error =
        String::ZoneHandle(Z, Symbols::New(thread(), "Unreachable code."));
    body_fragment += Constant(error);
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
    helper->switch_block()->DestinationDirect(case_index);
  }

  return body_fragment;
}

Fragment StreamingFlowGraphBuilder::BuildLinearScanSwitch(
    SwitchHelper* helper) {
  // Build a switch using a sequence of equality tests.
  //
  // From a test:
  // * jump directly to a body, if there is no jumper.
  // * jump to a wrapper block which jumps to the body, if there is a jumper.

  SwitchBlock* block = helper->switch_block();
  const intptr_t case_count = helper->case_count();
  const intptr_t default_case = helper->default_case();
  const GrowableArray<Fragment>& case_bodies = helper->case_bodies();
  Fragment current_instructions;
  intptr_t expression_index = 0;

  for (intptr_t i = 0; i < case_count; ++i) {
    if (i == default_case) {
      ASSERT(i == (case_count - 1));

      if (block->HadJumper(i)) {
        // There are several branches to the body, so we will make a goto to
        // the join block (and prepend a join instruction to the real body).
        JoinEntryInstr* join = block->DestinationDirect(i);
        current_instructions += Goto(join);

        current_instructions = Fragment(current_instructions.entry, join);
        current_instructions += case_bodies[i];
      } else {
        current_instructions += case_bodies[i];
      }
    } else {
      JoinEntryInstr* body_join = nullptr;
      if (block->HadJumper(i)) {
        body_join = block->DestinationDirect(i);
        case_bodies[i] = Fragment(body_join) + case_bodies[i];
      }

      const intptr_t expression_count = helper->case_expression_counts().At(i);
      for (intptr_t j = 0; j < expression_count; ++j) {
        TargetEntryInstr* then;
        TargetEntryInstr* otherwise;

        const SwitchExpression& expression =
            helper->expressions().At(expression_index++);
        current_instructions += Constant(expression.value());
        current_instructions += LoadLocal(scopes()->switch_variable);
        current_instructions += InstanceCall(
            expression.position(), Symbols::EqualOperator(), Token::kEQ,
            /*argument_count=*/2,
            /*checked_argument_count=*/2);
        current_instructions += BranchIfTrue(&then, &otherwise, false);

        Fragment then_fragment(then);

        if (body_join != nullptr) {
          // There are several branches to the body, so we will make a goto to
          // the join block (the real body has already been prepended with a
          // join instruction).
          then_fragment += Goto(body_join);
        } else {
          // There is only a single branch to the body, so we will just append
          // the body fragment.
          then_fragment += case_bodies[i];
        }

        current_instructions = Fragment(current_instructions.entry, otherwise);
      }
    }
  }

  if (case_count > 0 && !helper->has_default()) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = case_bodies[case_count - 1];
    if (last_body.is_open()) {
      ASSERT(current_instructions.is_open());
      ASSERT(current_instructions.current->IsTargetEntry());

      // Join the last "otherwise" branch and the last [SwitchCase] fragment.
      JoinEntryInstr* join = BuildJoinEntry();
      current_instructions += Goto(join);
      last_body += Goto(join);

      current_instructions = Fragment(current_instructions.entry, join);
    }
  } else {
    // All non-default cases will be closed (i.e. break/continue/throw/return)
    // So it is fine to just let more statements after the switch append to the
    // default case.
  }

  return current_instructions;
}

Fragment StreamingFlowGraphBuilder::BuildOptimizedSwitchPrelude(
    SwitchHelper* helper,
    JoinEntryInstr* join) {
  const TokenPosition pos = helper->position();
  Fragment instructions;

  if (!IG->null_safety()) {
    // Without sound null safety we need to check that the switch variable is
    // not null. If it is null, we go to [join] which is either the default
    // case or the exit of the switch statement.
    TargetEntryInstr* null_entry;
    TargetEntryInstr* non_null_entry;

    instructions += LoadLocal(scopes()->switch_variable);
    instructions += BranchIfNull(&null_entry, &non_null_entry);

    Fragment null_instructions(null_entry);
    null_instructions += Goto(join);

    instructions = Fragment(instructions.entry, non_null_entry);
  }

  if (helper->is_enum_switch()) {
    // For an enum switch, we need to load the enum index from the switch
    // variable.

    instructions += LoadLocal(scopes()->switch_variable);
    const Field& enum_index_field =
        Field::ZoneHandle(Z, IG->object_store()->enum_index_field());
    instructions += B->LoadField(enum_index_field, /*calls_initializer=*/false);
    instructions += StoreLocal(pos, scopes()->switch_variable);
    instructions += Drop();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBinarySearchSwitch(
    SwitchHelper* helper) {
  // * We build a binary tree of conditional branches where each branch bisects
  //   the remaining cases.
  //   * At holes in the switch expression range we need to add additional
  //     bound checks.
  // * At each leaf we add the body of the case or a goto, if the case has
  //   jumpers.
  //   * Leafs at the bounds of the switch expression range might need to
  //     do a bound check.

  SwitchBlock* block = helper->switch_block();
  const intptr_t case_count = helper->case_count();
  const intptr_t default_case = helper->default_case();
  const GrowableArray<Fragment>& case_bodies = helper->case_bodies();
  const intptr_t expression_count = helper->expressions().length();
  const GrowableArray<SwitchExpression*>& sorted_expressions =
      helper->sorted_expressions();
  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;

  // Entry to the default case or the exit of the switch, if there is no
  // default case.
  JoinEntryInstr* join;
  if (helper->has_default()) {
    join = block->DestinationDirect(default_case);
  } else {
    join = BuildJoinEntry();
  }

  Fragment join_instructions(join);
  if (helper->has_default()) {
    join_instructions += case_bodies.At(default_case);
  }

  Fragment current_instructions = BuildOptimizedSwitchPrelude(helper, join);

  GrowableArray<SwitchRange> stack;
  stack.Add(SwitchRange::Branch(0, expression_count - 1, current_instructions));

  while (!stack.is_empty()) {
    const SwitchRange range = stack.RemoveLast();
    Fragment branch_instructions = range.branch_instructions();

    if (range.is_leaf()) {
      const intptr_t expression_index = range.min();
      const SwitchExpression& expression =
          *sorted_expressions.At(expression_index);

      if (!range.is_bounds_checked() &&
          ((helper->RequiresLowerBoundCheck() && expression_index == 0) ||
           (helper->RequiresUpperBoundCheck() &&
            expression_index == expression_count - 1))) {
        // This leaf needs a bound check.

        branch_instructions += LoadLocal(scopes()->switch_variable);
        branch_instructions += Constant(expression.integer());
        branch_instructions +=
            StrictCompare(expression.position(), Token::kEQ_STRICT,
                          /*number_check=*/true);
        branch_instructions +=
            BranchIfTrue(&then_entry, &otherwise_entry, /*negate=*/false);

        Fragment otherwise_instructions(otherwise_entry);
        otherwise_instructions += Goto(join);

        stack.Add(SwitchRange::Leaf(expression_index, Fragment(then_entry),
                                    /*is_bounds_checked=*/true));
      } else {
        // We are at a leaf where we can add the body of the case or a goto to
        // [join].

        const intptr_t case_index = expression.case_index();

        if (case_index == default_case) {
          branch_instructions += Goto(join);
        } else {
          if (block->HadJumper(case_index)) {
            JoinEntryInstr* join = block->DestinationDirect(case_index);
            branch_instructions += Goto(join);

            if (join->next() == nullptr) {
              // The first time we reach an expression that jumps to a case
              // body we emit the body.
              branch_instructions = Fragment(join);
              branch_instructions += case_bodies.At(case_index);
            }
          } else {
            branch_instructions += case_bodies.At(case_index);
          }

          if (!helper->has_default() && case_index == case_count - 1) {
            if (branch_instructions.is_open()) {
              branch_instructions += Goto(join);
            }
          }
        }

        ASSERT(branch_instructions.is_closed());
      }
    } else {
      // Add a conditional to bisect the range.

      const intptr_t middle = range.min() + (range.max() - range.min()) / 2;
      const intptr_t next = middle + 1;
      const SwitchExpression& middle_expression =
          *sorted_expressions.At(middle);
      const SwitchExpression& next_expression = *sorted_expressions.At(next);

      branch_instructions += LoadLocal(scopes()->switch_variable);
      branch_instructions += Constant(middle_expression.integer());
      branch_instructions +=
          B->IntRelationalOp(middle_expression.position(), Token::kLTE);
      branch_instructions +=
          BranchIfTrue(&then_entry, &otherwise_entry, /*negate=*/false);

      Fragment lower_branch_instructions(then_entry);
      Fragment upper_branch_instructions(otherwise_entry);

      if (next_expression.integer().AsInt64Value() >
          middle_expression.integer().AsInt64Value() + 1) {
        // The upper branch is not contiguous with the lower branch.
        // Before continuing in the upper branch we add a bound check.

        upper_branch_instructions += LoadLocal(scopes()->switch_variable);
        upper_branch_instructions += Constant(next_expression.integer());
        upper_branch_instructions +=
            B->IntRelationalOp(next_expression.position(), Token::kGTE);
        upper_branch_instructions +=
            BranchIfTrue(&then_entry, &otherwise_entry, /*negate=*/false);

        Fragment otherwise_instructions(otherwise_entry);
        otherwise_instructions += Goto(join);

        upper_branch_instructions = Fragment(then_entry);
      }

      stack.Add(
          SwitchRange::Branch(next, range.max(), upper_branch_instructions));
      stack.Add(
          SwitchRange::Branch(range.min(), middle, lower_branch_instructions));
    }

    if (current_instructions.is_empty()) {
      current_instructions = branch_instructions;
    }
  }

  return Fragment(current_instructions.entry, join_instructions.current);
}

Fragment StreamingFlowGraphBuilder::BuildJumpTableSwitch(SwitchHelper* helper) {
  // * If input value is not integer or enum value, goto default case or
  //   switch exit.
  // * If value is enum value, load its index.
  // * If input integer is outside of jump table range, goto default case
  //   or switch exit.
  // * Jump to case with jump table.
  //     * For each expression, add entry to jump to case.
  //     * For each hole in the integer range, add entry to jump to default
  //       cause or switch exit.

  SwitchBlock* block = helper->switch_block();
  const TokenPosition pos = helper->position();
  const intptr_t case_count = helper->case_count();
  const intptr_t default_case = helper->default_case();
  const GrowableArray<Fragment>& case_bodies = helper->case_bodies();
  const Integer& expression_min = helper->expression_min();
  const Integer& expression_max = helper->expression_max();
  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;

  // Entry to the default case or the exit of the switch, if there is no
  // default case.
  JoinEntryInstr* join;
  if (helper->has_default()) {
    join = block->DestinationDirect(default_case);
  } else {
    join = BuildJoinEntry();
  }

  Fragment join_instructions(join);

  Fragment current_instructions = BuildOptimizedSwitchPrelude(helper, join);

  if (helper->RequiresLowerBoundCheck()) {
    current_instructions += LoadLocal(scopes()->switch_variable);
    current_instructions += Constant(expression_min);
    current_instructions += B->IntRelationalOp(pos, Token::kGTE);
    current_instructions += BranchIfTrue(&then_entry, &otherwise_entry,
                                         /*negate=*/false);
    Fragment otherwise_instructions(otherwise_entry);
    otherwise_instructions += Goto(join);

    current_instructions = Fragment(current_instructions.entry, then_entry);
  }

  if (helper->RequiresUpperBoundCheck()) {
    current_instructions += LoadLocal(scopes()->switch_variable);
    current_instructions += Constant(expression_max);
    current_instructions += B->IntRelationalOp(pos, Token::kLTE);
    current_instructions += BranchIfTrue(&then_entry, &otherwise_entry,
                                         /*negate=*/false);
    Fragment otherwise_instructions(otherwise_entry);
    otherwise_instructions += Goto(join);

    current_instructions = Fragment(current_instructions.entry, then_entry);
  }

  current_instructions += LoadLocal(scopes()->switch_variable);

  if (!expression_min.IsZero()) {
    // Adjust for the range of the jump table, which starts at 0.
    current_instructions += Constant(expression_min);
    current_instructions +=
        InstanceCall(pos, Symbols::Minus(), Token::kSUB, /*argument_count=*/2,
                     /*checked_argument_count=*/2);
  }

  const intptr_t table_size = helper->ExpressionRange();
  IndirectGotoInstr* indirect_goto = IndirectGoto(table_size);
  current_instructions <<= indirect_goto;
  current_instructions = current_instructions.closed();

  GrowableArray<TargetEntryInstr*> table_entries(table_size);
  table_entries.FillWith(nullptr, 0, table_size);

  // Generate the jump table entries for the switch cases.
  intptr_t expression_index = 0;
  for (intptr_t i = 0; i < case_count; ++i) {
    const int expression_count = helper->case_expression_counts().At(i);

    // Generate jump table entries for each case expression.
    if (i != default_case) {
      for (intptr_t j = 0; j < expression_count; ++j) {
        const SwitchExpression& expression =
            helper->expressions().At(expression_index++);
        const intptr_t table_offset =
            expression.integer().AsInt64Value() - expression_min.AsInt64Value();

        IndirectEntryInstr* indirect_entry =
            B->BuildIndirectEntry(table_offset, CurrentTryIndex());
        Fragment indirect_entry_instructions(indirect_entry);
        indirect_entry_instructions += Goto(block->DestinationDirect(i));

        TargetEntryInstr* entry = B->BuildTargetEntry();
        Fragment entry_instructions(entry);
        entry_instructions += Goto(indirect_entry);

        table_entries[table_offset] = entry;
      }
    }

    // Connect the case body to its join entry.
    if (i == default_case) {
      join_instructions += case_bodies.At(i);
    } else {
      Fragment case_instructions(block->DestinationDirect(i));
      case_instructions += case_bodies.At(i);

      if (i == case_count - 1) {
        // If the last case is not the default case and it is still open
        // close it by going to the exit of the switch.
        if (case_instructions.is_open()) {
          case_instructions += Goto(join);
        }
      }

      ASSERT(case_instructions.is_closed());
    }
  }

  // Generate the jump table entries for holes in the integer range.
  for (intptr_t i = 0; i < table_size; i++) {
    if (table_entries.At(i) == nullptr) {
      IndirectEntryInstr* indirect_entry =
          B->BuildIndirectEntry(i, CurrentTryIndex());
      Fragment indirect_entry_instructions(indirect_entry);
      indirect_entry_instructions += Goto(join);

      TargetEntryInstr* entry = flow_graph_builder_->BuildTargetEntry();
      Fragment entry_instructions(entry);
      entry_instructions += Goto(indirect_entry);

      table_entries[i] = entry;
    }
  }

  // Add the jump table entries to the jump table.
  for (intptr_t i = 0; i < table_size; i++) {
    indirect_goto->AddSuccessor(table_entries.At(i));
  }

  return Fragment(current_instructions.entry, join_instructions.current);
}

Fragment StreamingFlowGraphBuilder::BuildContinueSwitchStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  intptr_t target_index = ReadUInt();  // read target index.

  TryFinallyBlock* outer_finally = nullptr;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* entry = switch_block()->Destination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    if (NeedsDebugStepCheck(parsed_function()->function(), pos)) {
      instructions += DebugStepCheck(pos);
    }
    instructions += Goto(entry);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIfStatement(TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  TestFragment condition = TranslateConditionForControl();

  Fragment then_fragment(condition.CreateTrueSuccessor(flow_graph_builder_));
  then_fragment += BuildStatementWithBranchCoverage();  // read then.

  Fragment otherwise_fragment(
      condition.CreateFalseSuccessor(flow_graph_builder_));
  otherwise_fragment += BuildStatementWithBranchCoverage();  // read otherwise.

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

Fragment StreamingFlowGraphBuilder::BuildReturnStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  Tag tag = ReadTag();  // read first part of expression.

  bool inside_try_finally = try_finally_block() != nullptr;

  Fragment instructions;
  if (parsed_function()->function().IsSyncGenerator()) {
    // Return false from sync* function to indicate the end of iteration.
    instructions += Constant(Bool::False());
    if (tag != kNothing) {
      ASSERT(PeekTag() == kNullLiteral);
      SkipExpression();
    }
  } else {
    instructions +=
        (tag == kNothing ? NullConstant()
                         : BuildExpression());  // read rest of expression.
  }

  if (instructions.is_open()) {
    if (inside_try_finally) {
      LocalVariable* const finally_return_variable =
          scopes()->finally_return_variable;
      ASSERT(finally_return_variable != nullptr);
      const Function& function = parsed_function()->function();
      if (NeedsDebugStepCheck(function, pos)) {
        instructions += DebugStepCheck(pos);
      }
      instructions += StoreLocal(pos, finally_return_variable);
      instructions += Drop();
      const intptr_t target_context_depth =
          finally_return_variable->is_captured()
              ? finally_return_variable->owner()->context_level()
              : -1;
      instructions += TranslateFinallyFinalizers(nullptr, target_context_depth);
      if (instructions.is_open()) {
        const intptr_t saved_context_depth = B->context_depth_;
        if (finally_return_variable->is_captured()) {
          B->context_depth_ = target_context_depth;
        }
        instructions += LoadLocal(finally_return_variable);
        instructions += Return(TokenPosition::kNoSource);
        B->context_depth_ = saved_context_depth;
      }
    } else {
      instructions += Return(pos);
    }
  } else {
    Pop();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildTryCatch(TokenPosition* position) {
  ASSERT(block_expression_depth() == 0);  // no try-catch in block-expr
  InlineBailout("kernel::FlowgraphBuilder::VisitTryCatch");

  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  try_depth_inc();
  {
    TryCatchBlock block(flow_graph_builder_, try_handler_index);
    try_body += BuildStatementWithBranchCoverage(position);  // read body.
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
    intptr_t catch_offset = ReaderOffset();          // Catch has no tag.
    TokenPosition pos = ReadPosition();              // read position.
    const AbstractType& type_guard = T.BuildType();  // read guard.
    handler_types.SetAt(i, type_guard);

    Fragment catch_handler_body = EnterScope(catch_offset);

    Tag tag = ReadTag();  // read first part of exception.
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

      catch_handler_body += BuildStatementWithBranchCoverage();  // read body.

      // Note: ExitScope adjusts context_depth_ so even if catch_handler_body
      // is closed we still need to execute ExitScope for its side effect.
      catch_handler_body += ExitScope(catch_offset);
      if (catch_handler_body.is_open()) {
        catch_handler_body += Goto(after_try);
      }
    }

    if (!type_guard.IsCatchAllType()) {
      catch_body += LoadLocal(CurrentException());

      if (!type_guard.IsInstantiated(kCurrentClass)) {
        catch_body += LoadInstantiatorTypeArguments();
      } else {
        catch_body += NullConstant();
      }

      if (!type_guard.IsInstantiated(kFunctions)) {
        catch_body += LoadFunctionTypeArguments();
      } else {
        catch_body += NullConstant();
      }

      catch_body += Constant(type_guard);

      catch_body +=
          InstanceCall(pos, Library::PrivateCoreLibName(Symbols::_instanceOf()),
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
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildTryFinally(TokenPosition* position) {
  // Note on streaming:
  // We only stream this TryFinally if we can stream everything inside it,
  // so creating a "TryFinallyBlock" with a kernel binary offset instead of an
  // AST node isn't a problem.

  InlineBailout("kernel::FlowgraphBuilder::VisitTryFinally");

  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

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
    try_body += BuildStatementWithBranchCoverage(position);  // read body.
  }
  try_depth_dec();

  if (try_body.is_open()) {
    // Please note: The try index will be on level out of this block,
    // thereby ensuring if there's an exception in the finally block we
    // won't run it twice.
    JoinEntryInstr* finally_entry = BuildJoinEntry();

    try_body += Goto(finally_entry);

    Fragment finally_body(finally_entry);
    finally_body += BuildStatementWithBranchCoverage();  // read finalizer.
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

  // Try/finally might occur in control flow collections with non-empty
  // expression stack (via desugaring of 'await for'). Note that catch-block
  // generated for finally always throws so there is no merge.
  // Save and reset expression stack around catch body in order to maintain
  // correct stack depth, as catch entry drops expression stack.
  Value* const saved_stack_top = stack();
  set_stack(nullptr);

  finally_body += BuildStatementWithBranchCoverage();  // read finalizer
  if (finally_body.is_open()) {
    finally_body += LoadLocal(CurrentException());
    finally_body += LoadLocal(CurrentStackTrace());
    finally_body +=
        RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }

  ASSERT(stack() == nullptr);
  set_stack(saved_stack_top);
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildYieldStatement(
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();  // read position.
  if (position != nullptr) *position = pos;

  const uint8_t flags = ReadByte();  // read flags.

  Fragment instructions;
  const bool is_yield_star = (flags & kYieldStatementFlagYieldStar) != 0;

  // Load :suspend_state variable using low-level FP-relative load
  // in order to avoid confusing SSA construction (which cannot
  // track its value as it is modified implicitly by stubs).
  LocalVariable* suspend_state = parsed_function()->suspend_state_var();
  ASSERT(suspend_state != nullptr);
  instructions += IntConstant(0);
  instructions += B->LoadFpRelativeSlot(
      compiler::target::frame_layout.FrameSlotForVariable(suspend_state) *
          compiler::target::kWordSize,
      CompileType::Dynamic(), kTagged);
  instructions += LoadNativeField(Slot::SuspendState_function_data());

  instructions += BuildExpression();  // read expression.
  if (NeedsDebugStepCheck(parsed_function()->function(), pos)) {
    instructions += DebugStepCheck(pos);
  }

  if (parsed_function()->function().IsAsyncGenerator()) {
    // In the async* functions, generate the following code for yield <expr>:
    //
    // _AsyncStarStreamController controller = :suspend_state._functionData;
    // if (controller.add(<expr>)) {
    //   return;
    // }
    // if (suspend()) {
    //   return;
    // }
    //
    // Generate the following code for yield* <expr>:
    //
    // _AsyncStarStreamController controller = :suspend_state._functionData;
    // if (controller.addStream(<expr>)) {
    //   return;
    // }
    // if (suspend()) {
    //   return;
    // }
    //

    auto& add_method = Function::ZoneHandle(Z);
    if (is_yield_star) {
      add_method =
          IG->object_store()->async_star_stream_controller_add_stream();
    } else {
      add_method = IG->object_store()->async_star_stream_controller_add();
    }
    instructions +=
        StaticCall(TokenPosition::kNoSource, add_method, 2, ICData::kNoRebind);

    TargetEntryInstr *return1, *continue1;
    instructions += BranchIfTrue(&return1, &continue1, false);
    JoinEntryInstr* return_join = BuildJoinEntry();
    Fragment(return1) + Goto(return_join);
    instructions = Fragment(instructions.entry, continue1);

    // Suspend and test value passed to the resumed async* body.
    instructions += NullConstant();
    instructions += B->Suspend(pos, SuspendInstr::StubId::kYieldAsyncStar);

    TargetEntryInstr *return2, *continue2;
    instructions += BranchIfTrue(&return2, &continue2, false);
    Fragment(return2) + Goto(return_join);
    instructions = Fragment(instructions.entry, continue2);

    Fragment do_return(return_join);
    do_return += TranslateFinallyFinalizers(nullptr, -1);
    do_return += NullConstant();
    do_return += Return(TokenPosition::kNoSource);

  } else if (parsed_function()->function().IsSyncGenerator()) {
    // In the sync* functions, generate the following code for yield <expr>:
    //
    // _SyncStarIterator iterator = :suspend_state._functionData;
    // iterator._current = <expr>;
    // suspend();
    //
    // Generate the following code for yield* <expr>:
    //
    // _SyncStarIterator iterator = :suspend_state._functionData;
    // iterator._yieldStarIterable = <expr>;
    // suspend();
    //
    auto& field = Field::ZoneHandle(Z);
    if (is_yield_star) {
      field = IG->object_store()->sync_star_iterator_yield_star_iterable();
    } else {
      field = IG->object_store()->sync_star_iterator_current();
    }
    instructions += B->StoreFieldGuarded(field);
    instructions += B->Constant(Bool::True());
    instructions +=
        B->Suspend(pos, SuspendInstr::StubId::kSuspendSyncStarAtYield);
    instructions += Drop();
  } else {
    UNREACHABLE();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildVariableDeclaration(
    TokenPosition* position) {
  intptr_t kernel_position_no_tag = ReaderOffset() + data_program_offset_;
  LocalVariable* variable = LookupVariable(kernel_position_no_tag);

  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  T.BuildType();  // read type.
  bool has_initializer = (ReadTag() != kNothing);

  Fragment instructions;
  if (variable->is_late()) {
    // TODO(liama): Treat the field as non-late if the initializer is trivial.
    if (has_initializer) {
      SkipExpression();
    }
    instructions += Constant(Object::sentinel());
  } else if (!has_initializer) {
    instructions += NullConstant();
  } else {
    // Initializer
    instructions += BuildExpression();  // read (actual) initializer.
  }

  // Use position of equal sign if it exists. If the equal sign does not exist
  // use the position of the identifier.
  const TokenPosition debug_position = helper.equals_position_.IsReal()
                                           ? helper.equals_position_
                                           : helper.position_;
  if (position != nullptr) *position = helper.position_;
  if (NeedsDebugStepCheck(stack(), debug_position) && !helper.IsHoisted()) {
    instructions = DebugStepCheck(debug_position) + instructions;
  }
  instructions += StoreLocal(helper.position_, variable);
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionDeclaration(
    intptr_t offset,
    TokenPosition* position) {
  const TokenPosition pos = ReadPosition();
  if (position != nullptr) *position = pos;

  const intptr_t variable_offset = ReaderOffset() + data_program_offset_;

  // Read variable declaration.
  VariableDeclarationHelper helper(this);

  bool has_pragma = false;
  bool has_valid_annotation = false;
  helper.ReadUntilExcluding(VariableDeclarationHelper::kAnnotations);
  const intptr_t annotation_count = ReadListLength();
  for (intptr_t i = 0; i < annotation_count; ++i) {
    const intptr_t tag = PeekTag();
    if (tag != kInvalidExpression) {
      has_valid_annotation = true;
    }
    if (tag == kConstantExpression || tag == kFileUriConstantExpression) {
      auto& instance = Instance::Handle();
      instance = constant_reader_.ReadConstantExpression();
      if (instance.clazz() == IG->object_store()->pragma_class()) {
        has_pragma = true;
      }
      continue;
    }
    SkipExpression();
  }
  helper.SetJustRead(VariableDeclarationHelper::kAnnotations);

  helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

  Fragment instructions = DebugStepCheck(pos);
  instructions += BuildFunctionNode(pos, helper.name_index_,
                                    has_valid_annotation, has_pragma, offset);
  instructions += StoreLocal(pos, LookupVariable(variable_offset));
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionNode(
    TokenPosition parent_position,
    StringIndex name_index,
    bool has_valid_annotation,
    bool has_pragma,
    intptr_t func_decl_offset) {
  const intptr_t offset = ReaderOffset();

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  TokenPosition position = function_node_helper.position_;

  bool declaration = name_index >= 0;

  if (declaration) {
    position = parent_position;
  }

  const auto& member_function =
      Function::Handle(Z, parsed_function()->function().GetOutermostFunction());
  Function& function = Function::ZoneHandle(Z);

  {
    SafepointReadRwLocker ml(thread(),
                             thread()->isolate_group()->program_lock());
    function = ClosureFunctionsCache::LookupClosureFunctionLocked(
        member_function, offset);
  }

  if (function.IsNull()) {
    SafepointWriteRwLocker ml(thread(),
                              thread()->isolate_group()->program_lock());
    function = ClosureFunctionsCache::LookupClosureFunctionLocked(
        member_function, offset);
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
        if (!closure_owner_.IsNull()) {
          function = Function::NewClosureFunctionWithKind(
              UntaggedFunction::kClosureFunction, *name,
              parsed_function()->function(),
              parsed_function()->function().is_static(), position,
              closure_owner_);
        } else {
          function = Function::NewClosureFunction(
              *name, parsed_function()->function(), position);
        }

        function.set_has_pragma(has_pragma);
        if ((FLAG_enable_mirrors && has_valid_annotation) || has_pragma) {
          auto& lib =
              Library::Handle(Z, Class::Handle(Z, function.Owner()).library());
          lib.AddMetadata(function, func_decl_offset);
        }

        if (function_node_helper.async_marker_ == FunctionNodeHelper::kAsync) {
          function.set_modifier(UntaggedFunction::kAsync);
          function.set_is_inlinable(false);
          ASSERT(function.IsAsyncFunction());
        } else if (function_node_helper.async_marker_ ==
                   FunctionNodeHelper::kAsyncStar) {
          function.set_modifier(UntaggedFunction::kAsyncGen);
          function.set_is_inlinable(false);
          ASSERT(function.IsAsyncGenerator());
        } else if (function_node_helper.async_marker_ ==
                   FunctionNodeHelper::kSyncStar) {
          function.set_modifier(UntaggedFunction::kSyncGen);
          function.set_is_inlinable(false);
          ASSERT(function.IsSyncGenerator());
        } else {
          ASSERT(function_node_helper.async_marker_ ==
                 FunctionNodeHelper::kSync);
          ASSERT(!function.IsAsyncFunction());
          ASSERT(!function.IsAsyncGenerator());
          ASSERT(!function.IsSyncGenerator());
        }

        // If the start token position is synthetic, the end token position
        // should be as well.
        function.set_end_token_pos(
            position.IsReal() ? function_node_helper.end_position_ : position);

        LocalScope* scope = scopes()->function_scopes[i].scope;
        const ContextScope& context_scope = ContextScope::Handle(
            Z, scope->PreserveOuterScope(function,
                                         flow_graph_builder_->context_depth_));
        function.set_context_scope(context_scope);
        function.set_kernel_offset(offset);
        type_translator_.SetupFunctionParameters(Class::Handle(Z), function,
                                                 false,  // is_method
                                                 true,   // is_closure
                                                 &function_node_helper);
        // type_translator_.SetupUnboxingInfoMetadata is not called here at the
        // moment because closures do not have unboxed parameters and return
        // value
        function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

        // Finalize function type.
        FunctionType& signature = FunctionType::Handle(Z, function.signature());
        signature ^= ClassFinalizer::FinalizeType(signature);
        function.SetSignature(signature);

        if (has_pragma) {
          if (Library::FindPragma(thread(), /*only_core=*/false, function,
                                  Symbols::vm_invisible())) {
            function.set_is_visible(false);
          }
        }

        ASSERT(function.GetOutermostFunction() == member_function.ptr());
        ASSERT(function.kernel_offset() == offset);
        ClosureFunctionsCache::AddClosureFunctionLocked(function);
        break;
      }
    }
  }
  ASSERT(function.token_pos() == position);
  ASSERT(function.parent_function() == parsed_function()->function().ptr());

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

  Fragment instructions;
  instructions += Constant(function);
  if (scopes()->IsClosureWithEmptyContext(offset)) {
    instructions += NullConstant();
  } else {
    instructions += LoadLocal(parsed_function()->current_context_var());
  }
  instructions += flow_graph_builder_->AllocateClosure();
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  if (!function.HasInstantiatedSignature(kCurrentClass)) {
    instructions += LoadLocal(closure);
    instructions += LoadInstantiatorTypeArguments();
    instructions += flow_graph_builder_->StoreNativeField(
        Slot::Closure_instantiator_type_arguments(),
        StoreFieldInstr::Kind::kInitializing);
  }

  // TODO(30455): We only need to save these if the closure uses any captured
  // type parameters.
  instructions += LoadLocal(closure);
  instructions += LoadFunctionTypeArguments();
  instructions += flow_graph_builder_->StoreNativeField(
      Slot::Closure_function_type_arguments(),
      StoreFieldInstr::Kind::kInitializing);

  if (function.IsGeneric()) {
    // Only generic functions need to have properly initialized
    // delayed_type_arguments.
    instructions += LoadLocal(closure);
    instructions += Constant(Object::empty_type_arguments());
    instructions += flow_graph_builder_->StoreNativeField(
        Slot::Closure_delayed_type_arguments(),
        StoreFieldInstr::Kind::kInitializing);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildNativeEffect() {
  const intptr_t argc = ReadUInt();  // Read argument count.
  ASSERT(argc == 1);                 // Native side effect to ignore.
  const intptr_t list_length = ReadListLength();  // Read types list length.
  ASSERT(list_length == 0);

  const intptr_t positional_count =
      ReadListLength();  // Read positional argument count.
  ASSERT(positional_count == 1);

  BuildExpression();  // Consume expression but don't save the fragment.
  Pop();              // Restore the stack.

  const intptr_t named_args_len =
      ReadListLength();  // Skip empty named arguments.
  ASSERT(named_args_len == 0);

  Fragment code;
  code += NullConstant();  // Return type is void.
  return code;
}

Fragment StreamingFlowGraphBuilder::BuildReachabilityFence() {
  const intptr_t argc = ReadUInt();               // Read argument count.
  ASSERT(argc == 1);                              // LoadField, can be late.
  const intptr_t list_length = ReadListLength();  // Read types list length.
  ASSERT(list_length == 0);

  const intptr_t positional_count = ReadListLength();
  ASSERT(positional_count == 1);

  // The CFE transform only generates a subset of argument expressions:
  // either variable get or `this`. However, subsequent transforms can
  // generate different expressions, including: constant expressions.
  // So, build an arbitrary expression here instead.
  TokenPosition* position = nullptr;
  Fragment code = BuildExpression(position);

  const intptr_t named_args_len = ReadListLength();
  ASSERT(named_args_len == 0);

  code <<= new (Z) ReachabilityFenceInstr(Pop());
  code += NullConstant();  // Return type is void.
  return code;
}

static void ReportIfNotNull(const char* error) {
  if (error != nullptr) {
    const auto& language_error = Error::Handle(
        LanguageError::New(String::Handle(String::New(error, Heap::kOld)),
                           Report::kError, Heap::kOld));
    Report::LongJump(language_error);
  }
}

Fragment StreamingFlowGraphBuilder::BuildLoadAbiSpecificInt(bool at_index) {
  const intptr_t argument_count = ReadUInt();     // Read argument count.
  ASSERT(argument_count == 2);                    // TypedDataBase, offset/index
  const intptr_t list_length = ReadListLength();  // Read types list length.
  ASSERT(list_length == 1);                       // AbiSpecificInt.
  // Read types.
  const TypeArguments& type_arguments = T.BuildTypeArguments(list_length);
  const AbstractType& type_argument =
      AbstractType::Handle(type_arguments.TypeAt(0));

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  const auto* native_type =
      compiler::ffi::NativeType::FromAbstractType(zone_, type_argument, &error);
  ReportIfNotNull(error);

  Fragment code;
  // Read positional argument count.
  const intptr_t positional_count = ReadListLength();
  ASSERT(positional_count == 2);
  code += BuildExpression();  // Argument 1: typedDataBase.
  code += BuildExpression();  // Argument 2: offsetInBytes or index.
  if (at_index) {
    code += IntConstant(native_type->SizeInBytes());
    code += B->BinaryIntegerOp(Token::kMUL, kTagged, /* truncate= */ true);
  }

  // Skip (empty) named arguments list.
  const intptr_t named_args_len = ReadListLength();
  ASSERT(named_args_len == 0);

  // This call site is not guaranteed to be optimized. So, do a call to the
  // correct force optimized function instead of compiling the body.
  MethodRecognizer::Kind kind = compiler::ffi::FfiLoad(*native_type);
  const char* function_name = MethodRecognizer::KindToFunctionNameCString(kind);
  const Library& ffi_library = Library::Handle(Z, Library::FfiLibrary());
  const Function& target = Function::ZoneHandle(
      Z, ffi_library.LookupFunctionAllowPrivate(
             String::Handle(Z, String::New(function_name))));
  Array& argument_names = Array::ZoneHandle(Z);
  code += StaticCall(TokenPosition::kNoSource, target, argument_count,
                     argument_names, ICData::kStatic);

  return code;
}

Fragment StreamingFlowGraphBuilder::BuildStoreAbiSpecificInt(bool at_index) {
  const intptr_t argument_count = ReadUInt();
  ASSERT(argument_count == 3);
  const intptr_t list_length = ReadListLength();
  ASSERT(list_length == 1);
  // Read types.
  const TypeArguments& type_arguments = T.BuildTypeArguments(list_length);
  const AbstractType& type_argument =
      AbstractType::Handle(type_arguments.TypeAt(0));

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  const auto* native_type =
      compiler::ffi::NativeType::FromAbstractType(zone_, type_argument, &error);
  ReportIfNotNull(error);

  Fragment code;
  // Read positional argument count.
  const intptr_t positional_count = ReadListLength();
  ASSERT(positional_count == 3);
  code += BuildExpression();  // Argument 1: typedDataBase.
  code += BuildExpression();  // Argument 2: offsetInBytes or index.
  if (at_index) {
    code += IntConstant(native_type->SizeInBytes());
    code += B->BinaryIntegerOp(Token::kMUL, kTagged, /* truncate= */ true);
  }
  code += BuildExpression();  // Argument 3: value

  // Skip (empty) named arguments list.
  const intptr_t named_args_len = ReadListLength();
  ASSERT(named_args_len == 0);

  // This call site is not guaranteed to be optimized. So, do a call to the
  // correct force optimized function instead of compiling the body.
  MethodRecognizer::Kind kind = compiler::ffi::FfiStore(*native_type);
  const char* function_name = MethodRecognizer::KindToFunctionNameCString(kind);
  const Library& ffi_library = Library::Handle(Z, Library::FfiLibrary());
  const Function& target = Function::ZoneHandle(
      Z, ffi_library.LookupFunctionAllowPrivate(
             String::Handle(Z, String::New(function_name))));
  ASSERT(!target.IsNull());
  Array& argument_names = Array::ZoneHandle(Z);
  code += StaticCall(TokenPosition::kNoSource, target, argument_count,
                     argument_names, ICData::kStatic);

  return code;
}

Fragment StreamingFlowGraphBuilder::BuildFfiAsFunctionInternal() {
  const intptr_t argc = ReadUInt();               // Read argument count.
  ASSERT(argc == 2);                              // Pointer, isLeaf.
  const intptr_t list_length = ReadListLength();  // Read types list length.
  ASSERT(list_length == 2);  // Dart signature, then native signature
  // Read types.
  const TypeArguments& type_arguments = T.BuildTypeArguments(list_length);
  Fragment code;
  // Read positional argument count.
  const intptr_t positional_count = ReadListLength();
  ASSERT(positional_count == 2);
  code += BuildExpression();  // Build first positional argument (pointer).

  // The second argument, `isLeaf`, is only used internally and dictates whether
  // we can do a lightweight leaf function call.
  bool is_leaf = false;
  Fragment frag = BuildExpression();
  ASSERT(frag.entry->IsConstant());
  if (frag.entry->AsConstant()->value().ptr() == Object::bool_true().ptr()) {
    is_leaf = true;
  }
  Pop();

  // Skip (empty) named arguments list.
  const intptr_t named_args_len = ReadListLength();
  ASSERT(named_args_len == 0);

  code += B->BuildFfiAsFunctionInternalCall(type_arguments, is_leaf);
  return code;
}

Fragment StreamingFlowGraphBuilder::BuildArgumentsCachableIdempotentCall(
    intptr_t* argument_count) {
  *argument_count = ReadUInt();  // read arguments count.

  // List of types.
  const intptr_t types_list_length = ReadListLength();
  if (types_list_length != 0) {
    FATAL("Type arguments for vm:cachable-idempotent not (yet) supported.");
  }

  Fragment code;
  // List of positional.
  intptr_t positional_list_length = ReadListLength();
  for (intptr_t i = 0; i < positional_list_length; ++i) {
    code += BuildExpression();
    Definition* target_def = B->Peek();
    if (!target_def->IsConstant()) {
      FATAL(
          "Arguments for vm:cachable-idempotent must be const, argument on "
          "index %" Pd " is not.",
          i);
    }
  }

  // List of named.
  const intptr_t named_args_len = ReadListLength();
  if (named_args_len != 0) {
    FATAL("Named arguments for vm:cachable-idempotent not (yet) supported.");
  }

  return code;
}

Fragment StreamingFlowGraphBuilder::BuildCachableIdempotentCall(
    TokenPosition position,
    const Function& target) {
  // The call site must me fore optimized because the cache is untagged.
  if (!parsed_function()->function().ForceOptimize()) {
    FATAL(
        "vm:cachable-idempotent functions can only be called from "
        "vm:force-optimize functions.");
  }
  const auto& target_result_type = AbstractType::Handle(target.result_type());
  if (!target_result_type.IsIntType()) {
    FATAL("The return type vm:cachable-idempotent functions must be int.")
  }

  Fragment code;
  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  code += BuildArgumentsCachableIdempotentCall(&argument_count);

  code += flow_graph_builder_->CachableIdempotentCall(
      position, target, argument_count, argument_names,
      /*type_args_len=*/0);
  code += flow_graph_builder_->Box(kUnboxedFfiIntPtr);

  return code;
}

Fragment StreamingFlowGraphBuilder::BuildFfiNativeCallbackFunction(
    FfiFunctionKind kind) {
  // The call-site must look like this (guaranteed by the FE which inserts it):
  //
  // FfiFunctionKind::kIsolateLocalStaticCallback:
  //   _nativeCallbackFunction<NativeSignatureType>(target, exceptionalReturn)
  //
  // FfiFunctionKind::kAsyncCallback:
  //   _nativeAsyncCallbackFunction<NativeSignatureType>()
  //
  // FfiFunctionKind::kIsolateLocalClosureCallback:
  //   _nativeIsolateLocalCallbackFunction<NativeSignatureType>(
  //       exceptionalReturn)
  //
  // The FE also guarantees that the arguments are constants.

  const bool has_target = kind == FfiFunctionKind::kIsolateLocalStaticCallback;
  const bool has_exceptional_return = kind != FfiFunctionKind::kAsyncCallback;
  const intptr_t expected_argc =
      static_cast<int>(has_target) + static_cast<int>(has_exceptional_return);

  const intptr_t argc = ReadUInt();  // Read argument count.
  ASSERT(argc == expected_argc);

  const intptr_t list_length = ReadListLength();  // Read types list length.
  ASSERT(list_length == 1);                       // The native signature.
  const TypeArguments& type_arguments =
      T.BuildTypeArguments(list_length);  // Read types.
  ASSERT(type_arguments.Length() == 1 && type_arguments.IsInstantiated());
  const FunctionType& native_sig =
      FunctionType::CheckedHandle(Z, type_arguments.TypeAt(0));

  Fragment code;
  const intptr_t positional_count =
      ReadListLength();  // Read positional argument count.
  ASSERT(positional_count == expected_argc);

  // Read target expression and extract the target function.
  Function& target = Function::Handle(Z, Function::null());
  Instance& exceptional_return = Instance::ZoneHandle(Z, Instance::null());

  if (has_target) {
    // Build target argument.
    code += BuildExpression();
    Definition* target_def = B->Peek();
    ASSERT(target_def->IsConstant());
    const Closure& target_closure =
        Closure::Cast(target_def->AsConstant()->value());
    ASSERT(!target_closure.IsNull());
    target = target_closure.function();
    ASSERT(!target.IsNull() && target.IsImplicitClosureFunction());
    target = target.parent_function();
    code += Drop();
  }

  if (has_exceptional_return) {
    // Build exceptionalReturn argument.
    code += BuildExpression();
    Definition* exceptional_return_def = B->Peek();
    ASSERT(exceptional_return_def->IsConstant());
    exceptional_return ^= exceptional_return_def->AsConstant()->value().ptr();
    code += Drop();
  }

  const intptr_t named_args_len =
      ReadListLength();  // Skip (empty) named arguments list.
  ASSERT(named_args_len == 0);

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  compiler::ffi::NativeFunctionTypeFromFunctionType(zone_, native_sig, &error);
  ReportIfNotNull(error);

  const Function& result = Function::ZoneHandle(
      Z, compiler::ffi::NativeCallbackFunction(native_sig, target,
                                               exceptional_return, kind));
  code += Constant(result);

  return code;
}

}  // namespace kernel
}  // namespace dart
