// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_to_il.h"

#include <utility>

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/abi.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/ffi/recognized_method.h"
#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/compiler/frontend/prologue_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/runtime_api.h"
#include "vm/kernel_isolate.h"
#include "vm/kernel_loader.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool,
            print_huge_methods,
            false,
            "Print huge methods (less optimized)");

DEFINE_FLAG(int,
            force_switch_dispatch_type,
            -1,
            "Force switch statements to use a particular dispatch type: "
            "-1=auto, 0=linear scan, 1=binary search, 2=jump table");

namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()
#define IG IsolateGroup::Current()

FlowGraphBuilder::FlowGraphBuilder(
    ParsedFunction* parsed_function,
    ZoneGrowableArray<const ICData*>* ic_data_array,
    ZoneGrowableArray<intptr_t>* context_level_array,
    InlineExitCollector* exit_collector,
    bool optimizing,
    intptr_t osr_id,
    intptr_t first_block_id,
    bool inlining_unchecked_entry)
    : BaseFlowGraphBuilder(parsed_function,
                           first_block_id - 1,
                           osr_id,
                           context_level_array,
                           exit_collector,
                           inlining_unchecked_entry),
      translation_helper_(Thread::Current()),
      thread_(translation_helper_.thread()),
      zone_(translation_helper_.zone()),
      parsed_function_(parsed_function),
      optimizing_(optimizing),
      ic_data_array_(*ic_data_array),
      next_function_id_(0),
      loop_depth_(0),
      try_depth_(0),
      catch_depth_(0),
      block_expression_depth_(0),
      graph_entry_(nullptr),
      scopes_(nullptr),
      breakable_block_(nullptr),
      switch_block_(nullptr),
      try_catch_block_(nullptr),
      try_finally_block_(nullptr),
      catch_block_(nullptr),
      prepend_type_arguments_(Function::ZoneHandle(zone_)),
      throw_new_null_assertion_(Function::ZoneHandle(zone_)) {
  const auto& info = KernelProgramInfo::Handle(
      Z, parsed_function->function().KernelProgramInfo());
  H.InitFromKernelProgramInfo(info);
}

FlowGraphBuilder::~FlowGraphBuilder() {}

Fragment FlowGraphBuilder::EnterScope(
    intptr_t kernel_offset,
    const LocalScope** context_scope /* = nullptr */) {
  Fragment instructions;
  const LocalScope* scope = scopes_->scopes.Lookup(kernel_offset);
  if (scope->num_context_variables() > 0) {
    instructions += PushContext(scope);
    instructions += Drop();
  }
  if (context_scope != nullptr) {
    *context_scope = scope;
  }
  return instructions;
}

Fragment FlowGraphBuilder::ExitScope(intptr_t kernel_offset) {
  Fragment instructions;
  const intptr_t context_size =
      scopes_->scopes.Lookup(kernel_offset)->num_context_variables();
  if (context_size > 0) {
    instructions += PopContext();
  }
  return instructions;
}

Fragment FlowGraphBuilder::AdjustContextTo(int depth) {
  ASSERT(depth <= context_depth_ && depth >= 0);
  Fragment instructions;
  if (depth < context_depth_) {
    instructions += LoadContextAt(depth);
    instructions += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->current_context_var());
    instructions += Drop();
    context_depth_ = depth;
  }
  return instructions;
}

Fragment FlowGraphBuilder::PushContext(const LocalScope* scope) {
  ASSERT(scope->num_context_variables() > 0);
  Fragment instructions = AllocateContext(scope->context_slots());
  LocalVariable* context = MakeTemporary();
  instructions += LoadLocal(context);
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions += StoreNativeField(Slot::Context_parent(),
                                   StoreFieldInstr::Kind::kInitializing);
  instructions += StoreLocal(TokenPosition::kNoSource,
                             parsed_function_->current_context_var());
  ++context_depth_;
  return instructions;
}

Fragment FlowGraphBuilder::PopContext() {
  return AdjustContextTo(context_depth_ - 1);
}

Fragment FlowGraphBuilder::LoadInstantiatorTypeArguments() {
  // TODO(27590): We could use `active_class_->IsGeneric()`.
  Fragment instructions;
  if (scopes_ != nullptr && scopes_->type_arguments_variable != nullptr) {
#ifdef DEBUG
    Function& function =
        Function::Handle(Z, parsed_function_->function().ptr());
    while (function.IsClosureFunction()) {
      function = function.parent_function();
    }
    ASSERT(function.IsFactory());
#endif
    instructions += LoadLocal(scopes_->type_arguments_variable);
  } else if (parsed_function_->has_receiver_var() &&
             active_class_.ClassNumTypeArguments() > 0) {
    ASSERT(!parsed_function_->function().IsFactory());
    instructions += LoadLocal(parsed_function_->receiver_var());
    instructions += LoadNativeField(
        Slot::GetTypeArgumentsSlotFor(thread_, *active_class_.klass));
  } else {
    instructions += NullConstant();
  }
  return instructions;
}

// This function is responsible for pushing a type arguments vector which
// contains all type arguments of enclosing functions prepended to the type
// arguments of the current function.
Fragment FlowGraphBuilder::LoadFunctionTypeArguments() {
  Fragment instructions;

  const Function& function = parsed_function_->function();

  if (function.IsGeneric() || function.HasGenericParent()) {
    ASSERT(parsed_function_->function_type_arguments() != nullptr);
    instructions += LoadLocal(parsed_function_->function_type_arguments());
  } else {
    instructions += NullConstant();
  }

  return instructions;
}

Fragment FlowGraphBuilder::TranslateInstantiatedTypeArguments(
    const TypeArguments& type_arguments) {
  Fragment instructions;

  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    // There are no type references to type parameters so we can just take it.
    instructions += Constant(type_arguments);
  } else {
    // The [type_arguments] vector contains a type reference to a type
    // parameter we need to resolve it.
    if (type_arguments.CanShareInstantiatorTypeArguments(
            *active_class_.klass)) {
      // If the instantiator type arguments are just passed on, we don't need to
      // resolve the type parameters.
      //
      // This is for example the case here:
      //     class Foo<T> {
      //       newList() => new List<T>();
      //     }
      // We just use the type argument vector from the [Foo] object and pass it
      // directly to the `new List<T>()` factory constructor.
      instructions += LoadInstantiatorTypeArguments();
    } else if (type_arguments.CanShareFunctionTypeArguments(
                   parsed_function_->function())) {
      instructions += LoadFunctionTypeArguments();
    } else {
      // Otherwise we need to resolve [TypeParameterType]s in the type
      // expression based on the current instantiator type argument vector.
      if (!type_arguments.IsInstantiated(kCurrentClass)) {
        instructions += LoadInstantiatorTypeArguments();
      } else {
        instructions += NullConstant();
      }
      if (!type_arguments.IsInstantiated(kFunctions)) {
        instructions += LoadFunctionTypeArguments();
      } else {
        instructions += NullConstant();
      }
      instructions += InstantiateTypeArguments(type_arguments);
    }
  }
  return instructions;
}

Fragment FlowGraphBuilder::CatchBlockEntry(const Array& handler_types,
                                           intptr_t handler_index,
                                           bool needs_stacktrace,
                                           bool is_synthesized) {
  LocalVariable* exception_var = CurrentException();
  LocalVariable* stacktrace_var = CurrentStackTrace();
  LocalVariable* raw_exception_var = CurrentRawException();
  LocalVariable* raw_stacktrace_var = CurrentRawStackTrace();

  CatchBlockEntryInstr* entry = new (Z) CatchBlockEntryInstr(
      is_synthesized,  // whether catch block was synthesized by FE compiler
      AllocateBlockId(), CurrentTryIndex(), graph_entry_, handler_types,
      handler_index, needs_stacktrace, GetNextDeoptId(), exception_var,
      stacktrace_var, raw_exception_var, raw_stacktrace_var);
  graph_entry_->AddCatchEntry(entry);

  Fragment instructions(entry);

  // Auxiliary variables introduced by the try catch can be captured if we are
  // inside a function with yield/resume points. In this case we first need
  // to restore the context to match the context at entry into the closure.
  const bool should_restore_closure_context =
      CurrentException()->is_captured() || CurrentCatchContext()->is_captured();
  LocalVariable* context_variable = parsed_function_->current_context_var();
  if (should_restore_closure_context) {
    ASSERT(parsed_function_->function().IsClosureFunction());

    LocalVariable* closure_parameter = parsed_function_->ParameterVariable(0);
    ASSERT(!closure_parameter->is_captured());
    instructions += LoadLocal(closure_parameter);
    instructions += LoadNativeField(Slot::Closure_context());
    instructions += StoreLocal(TokenPosition::kNoSource, context_variable);
    instructions += Drop();
  }

  if (exception_var->is_captured()) {
    instructions += LoadLocal(context_variable);
    instructions += LoadLocal(raw_exception_var);
    instructions += StoreNativeField(
        Slot::GetContextVariableSlotFor(thread_, *exception_var));
  }
  if (stacktrace_var->is_captured()) {
    instructions += LoadLocal(context_variable);
    instructions += LoadLocal(raw_stacktrace_var);
    instructions += StoreNativeField(
        Slot::GetContextVariableSlotFor(thread_, *stacktrace_var));
  }

  // :saved_try_context_var can be captured in the context of
  // of the closure, in this case CatchBlockEntryInstr restores
  // :current_context_var to point to closure context in the
  // same way as normal function prologue does.
  // Update current context depth to reflect that.
  const intptr_t saved_context_depth = context_depth_;
  ASSERT(!CurrentCatchContext()->is_captured() ||
         CurrentCatchContext()->owner()->context_level() == 0);
  context_depth_ = 0;
  instructions += LoadLocal(CurrentCatchContext());
  instructions += StoreLocal(TokenPosition::kNoSource,
                             parsed_function_->current_context_var());
  instructions += Drop();
  context_depth_ = saved_context_depth;

  return instructions;
}

Fragment FlowGraphBuilder::TryCatch(int try_handler_index) {
  // The body of the try needs to have it's own block in order to get a new try
  // index.
  //
  // => We therefore create a block for the body (fresh try index) and another
  //    join block (with current try index).
  Fragment body;
  JoinEntryInstr* entry = BuildJoinEntry(try_handler_index);
  body += LoadLocal(parsed_function_->current_context_var());
  body += StoreLocal(TokenPosition::kNoSource, CurrentCatchContext());
  body += Drop();
  body += Goto(entry);
  return Fragment(body.entry, entry);
}

Fragment FlowGraphBuilder::CheckStackOverflowInPrologue(
    TokenPosition position) {
  ASSERT(loop_depth_ == 0);
  return BaseFlowGraphBuilder::CheckStackOverflowInPrologue(position);
}

Fragment FlowGraphBuilder::CloneContext(
    const ZoneGrowableArray<const Slot*>& context_slots) {
  LocalVariable* context_variable = parsed_function_->current_context_var();

  Fragment instructions = LoadLocal(context_variable);

  CloneContextInstr* clone_instruction = new (Z) CloneContextInstr(
      InstructionSource(), Pop(), context_slots, GetNextDeoptId());
  instructions <<= clone_instruction;
  Push(clone_instruction);

  instructions += StoreLocal(TokenPosition::kNoSource, context_variable);
  instructions += Drop();
  return instructions;
}

Fragment FlowGraphBuilder::InstanceCall(
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
  const intptr_t total_count = argument_count + (type_args_len > 0 ? 1 : 0);
  InputsArray arguments = GetArguments(total_count);
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      InstructionSource(position), name, kind, std::move(arguments),
      type_args_len, argument_names, checked_argument_count, ic_data_array_,
      GetNextDeoptId(), interface_target, tearoff_interface_target);
  if ((result_type != nullptr) && !result_type->IsTrivial()) {
    call->SetResultType(Z, result_type->ToCompileType(Z));
  }
  if (use_unchecked_entry) {
    call->set_entry_kind(Code::EntryKind::kUnchecked);
  }
  if (is_call_on_this) {
    call->mark_as_call_on_this();
  }
  if (call_site_attrs != nullptr && call_site_attrs->receiver_type != nullptr &&
      call_site_attrs->receiver_type->IsInstantiated()) {
    call->set_receivers_static_type(call_site_attrs->receiver_type);
  } else if (!interface_target.IsNull()) {
    const Class& owner = Class::Handle(Z, interface_target.Owner());
    const AbstractType& type =
        AbstractType::ZoneHandle(Z, owner.DeclarationType());
    call->set_receivers_static_type(&type);
  }
  call->set_receiver_is_not_smi(receiver_is_not_smi);
  Push(call);
  if (result_type != nullptr && result_type->IsConstant()) {
    Fragment instructions(call);
    instructions += Drop();
    instructions += Constant(result_type->constant_value);
    return instructions;
  }
  return Fragment(call);
}

Fragment FlowGraphBuilder::FfiCall(
    const compiler::ffi::CallMarshaller& marshaller) {
  Fragment body;

  FfiCallInstr* const call = new (Z) FfiCallInstr(
      GetNextDeoptId(), marshaller, parsed_function_->function().FfiIsLeaf());

  for (intptr_t i = call->InputCount() - 1; i >= 0; --i) {
    call->SetInputAt(i, Pop());
  }

  Push(call);
  body <<= call;

  return body;
}

Fragment FlowGraphBuilder::CCall(
    const compiler::ffi::NativeCallingConvention& native_calling_convention) {
  Fragment body;

  const intptr_t num_arguments =
      native_calling_convention.argument_locations().length() + 1;
  InputsArray arguments(num_arguments);
  arguments.FillWith(nullptr, 0, num_arguments);
  for (intptr_t i = num_arguments - 1; i >= 0; --i) {
    arguments[i] = Pop();
  }
  auto* const call =
      new (Z) CCallInstr(native_calling_convention, std::move(arguments));

  Push(call);
  body <<= call;

  return body;
}

Fragment FlowGraphBuilder::CCall(intptr_t num_arguments,
                                 Representation representation) {
  const auto& native_function_type =
      *compiler::ffi::NativeFunctionType::FromUnboxedRepresentation(
          Z, num_arguments, representation);
  const auto& native_calling_convention =
      compiler::ffi::NativeCallingConvention::FromSignature(
          Z, native_function_type);
  return CCall(native_calling_convention);
}

Fragment FlowGraphBuilder::RethrowException(TokenPosition position,
                                            int catch_try_index) {
  Fragment instructions;
  Value* stacktrace = Pop();
  Value* exception = Pop();
  instructions += Fragment(new (Z) ReThrowInstr(
                               InstructionSource(position), catch_try_index,
                               GetNextDeoptId(), exception, stacktrace))
                      .closed();
  // Use its side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  return instructions;
}

Fragment FlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  // Captured 'this' is immutable, so within the outer method we don't need to
  // load it from the context.
  const ParsedFunction* pf = parsed_function_;
  if (pf->function().HasThisParameter() && pf->has_receiver_var() &&
      variable == pf->receiver_var()) {
    ASSERT(variable == pf->ParameterVariable(0));
    variable = pf->RawParameterVariable(0);
  }
  if (variable->is_captured()) {
    Fragment instructions;
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions +=
        LoadNativeField(Slot::GetContextVariableSlotFor(thread_, *variable));
    return instructions;
  } else {
    return BaseFlowGraphBuilder::LoadLocal(variable);
  }
}

IndirectGotoInstr* FlowGraphBuilder::IndirectGoto(intptr_t target_count) {
  Value* index = Pop();
  return new (Z) IndirectGotoInstr(target_count, index);
}

Fragment FlowGraphBuilder::ThrowLateInitializationError(
    TokenPosition position,
    const char* throw_method_name,
    const String& name) {
  const auto& dart_internal = Library::Handle(Z, Library::InternalLibrary());
  const Class& klass =
      Class::ZoneHandle(Z, dart_internal.LookupClass(Symbols::LateError()));
  ASSERT(!klass.IsNull());

  const auto& error = klass.EnsureIsFinalized(thread_);
  ASSERT(error == Error::null());
  const Function& throw_new =
      Function::ZoneHandle(Z, klass.LookupStaticFunctionAllowPrivate(
                                  H.DartSymbolObfuscate(throw_method_name)));
  ASSERT(!throw_new.IsNull());

  Fragment instructions;

  // Call LateError._throwFoo.
  instructions += Constant(name);
  instructions += StaticCall(position, throw_new,
                             /* argument_count = */ 1, ICData::kStatic);
  instructions += Drop();

  return instructions;
}

Fragment FlowGraphBuilder::StoreLateField(const Field& field,
                                          LocalVariable* instance,
                                          LocalVariable* setter_value) {
  Fragment instructions;
  TargetEntryInstr* is_uninitialized;
  TargetEntryInstr* is_initialized;
  const TokenPosition position = field.token_pos();
  const bool is_static = field.is_static();
  const bool is_final = field.is_final();

  if (is_final) {
    // Check whether the field has been initialized already.
    if (is_static) {
      instructions += LoadStaticField(field, /*calls_initializer=*/false);
    } else {
      instructions += LoadLocal(instance);
      instructions += LoadField(field, /*calls_initializer=*/false);
    }
    instructions += Constant(Object::sentinel());
    instructions += BranchIfStrictEqual(&is_uninitialized, &is_initialized);
    JoinEntryInstr* join = BuildJoinEntry();

    {
      // If the field isn't initialized, do nothing.
      Fragment initialize(is_uninitialized);
      initialize += Goto(join);
    }

    {
      // If the field is already initialized, throw a LateInitializationError.
      Fragment already_initialized(is_initialized);
      already_initialized += ThrowLateInitializationError(
          position, "_throwFieldAlreadyInitialized",
          String::ZoneHandle(Z, field.name()));
      already_initialized += Goto(join);
    }

    instructions = Fragment(instructions.entry, join);
  }

  if (!is_static) {
    instructions += LoadLocal(instance);
  }
  instructions += LoadLocal(setter_value);
  if (is_static) {
    instructions += StoreStaticField(position, field);
  } else {
    instructions += StoreFieldGuarded(field);
  }

  return instructions;
}

Fragment FlowGraphBuilder::NativeCall(const String& name,
                                      const Function& function) {
  InlineBailout("kernel::FlowGraphBuilder::NativeCall");
  // +1 for result placeholder.
  const intptr_t num_args =
      function.NumParameters() + (function.IsGeneric() ? 1 : 0) + 1;

  Fragment instructions;
  instructions += NullConstant();  // Placeholder for the result.

  InputsArray arguments = GetArguments(num_args);
  NativeCallInstr* call = new (Z) NativeCallInstr(
      name, function, FLAG_link_natives_lazily,
      InstructionSource(function.end_token_pos()), std::move(arguments));
  Push(call);
  instructions <<= call;
  return instructions;
}

Fragment FlowGraphBuilder::Return(TokenPosition position,
                                  bool omit_result_type_check) {
  Fragment instructions;
  const Function& function = parsed_function_->function();

  // Emit a type check of the return type in checked mode for all functions
  // and in strong mode for native functions.
  if (!omit_result_type_check && function.is_native()) {
    const AbstractType& return_type =
        AbstractType::Handle(Z, function.result_type());
    instructions += CheckAssignable(return_type, Symbols::FunctionResult());
  }

  if (NeedsDebugStepCheck(function, position)) {
    instructions += DebugStepCheck(position);
  }

  instructions += BaseFlowGraphBuilder::Return(position);

  return instructions;
}

Fragment FlowGraphBuilder::StaticCall(TokenPosition position,
                                      const Function& target,
                                      intptr_t argument_count,
                                      ICData::RebindRule rebind_rule) {
  return StaticCall(position, target, argument_count, Array::null_array(),
                    rebind_rule);
}

void FlowGraphBuilder::SetResultTypeForStaticCall(
    StaticCallInstr* call,
    const Function& target,
    intptr_t argument_count,
    const InferredTypeMetadata* result_type) {
  if (call->InitResultType(Z)) {
    ASSERT((result_type == nullptr) || (result_type->cid == kDynamicCid) ||
           (result_type->cid == call->result_cid()));
    return;
  }
  if ((result_type != nullptr) && !result_type->IsTrivial()) {
    call->SetResultType(Z, result_type->ToCompileType(Z));
  }
}

Fragment FlowGraphBuilder::StaticCall(TokenPosition position,
                                      const Function& target,
                                      intptr_t argument_count,
                                      const Array& argument_names,
                                      ICData::RebindRule rebind_rule,
                                      const InferredTypeMetadata* result_type,
                                      intptr_t type_args_count,
                                      bool use_unchecked_entry) {
  const intptr_t total_count = argument_count + (type_args_count > 0 ? 1 : 0);
  InputsArray arguments = GetArguments(total_count);
  StaticCallInstr* call = new (Z) StaticCallInstr(
      InstructionSource(position), target, type_args_count, argument_names,
      std::move(arguments), ic_data_array_, GetNextDeoptId(), rebind_rule);
  SetResultTypeForStaticCall(call, target, argument_count, result_type);
  if (use_unchecked_entry) {
    call->set_entry_kind(Code::EntryKind::kUnchecked);
  }
  Push(call);
  if (result_type != nullptr && result_type->IsConstant()) {
    Fragment instructions(call);
    instructions += Drop();
    instructions += Constant(result_type->constant_value);
    return instructions;
  }
  return Fragment(call);
}

Fragment FlowGraphBuilder::StringInterpolateSingle(TokenPosition position) {
  Fragment instructions;
  instructions += StaticCall(
      position, CompilerState::Current().StringBaseInterpolateSingle(),
      /* argument_count = */ 1, ICData::kStatic);
  return instructions;
}

Fragment FlowGraphBuilder::StringInterpolate(TokenPosition position) {
  Fragment instructions;
  instructions +=
      StaticCall(position, CompilerState::Current().StringBaseInterpolate(),
                 /* argument_count = */ 1, ICData::kStatic);
  return instructions;
}

Fragment FlowGraphBuilder::ThrowTypeError() {
  const Class& klass =
      Class::ZoneHandle(Z, Library::LookupCoreClass(Symbols::TypeError()));
  ASSERT(!klass.IsNull());
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(Symbols::TypeError());
  pieces.Add(Symbols::Dot());
  pieces.Add(H.DartSymbolObfuscate("_create"));

  const Function& constructor = Function::ZoneHandle(
      Z, klass.LookupConstructorAllowPrivate(
             String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces))));
  ASSERT(!constructor.IsNull());

  const String& url = H.DartString(
      parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  Fragment instructions;

  // Create instance of _TypeError
  instructions += AllocateObject(TokenPosition::kNoSource, klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _TypeError._create constructor.
  instructions += LoadLocal(instance);                             // this
  instructions += Constant(url);                                   // url
  instructions += NullConstant();                                  // line
  instructions += IntConstant(0);                                  // column
  instructions += Constant(H.DartSymbolPlain("Malformed type."));  // message

  instructions += StaticCall(TokenPosition::kNoSource, constructor,
                             /* argument_count = */ 5, ICData::kStatic);
  instructions += Drop();

  // Throw the exception
  instructions += ThrowException(TokenPosition::kNoSource);

  return instructions;
}

Fragment FlowGraphBuilder::ThrowNoSuchMethodError(TokenPosition position,
                                                  const Function& target,
                                                  bool incompatible_arguments,
                                                  bool receiver_pushed) {
  const Class& owner = Class::Handle(Z, target.Owner());
  auto& receiver = Instance::ZoneHandle();
  InvocationMirror::Kind kind = InvocationMirror::Kind::kMethod;
  if (target.IsImplicitGetterFunction() || target.IsGetterFunction() ||
      target.IsRecordFieldGetter()) {
    kind = InvocationMirror::kGetter;
  } else if (target.IsImplicitSetterFunction() || target.IsSetterFunction()) {
    kind = InvocationMirror::kSetter;
  }
  InvocationMirror::Level level;
  if (owner.IsTopLevel()) {
    if (incompatible_arguments) {
      receiver = target.UserVisibleSignature();
    }
    level = InvocationMirror::Level::kTopLevel;
  } else {
    receiver = owner.RareType();
    if (target.kind() == UntaggedFunction::kConstructor) {
      level = InvocationMirror::Level::kConstructor;
    } else if (target.IsRecordFieldGetter()) {
      level = InvocationMirror::Level::kDynamic;
    } else {
      level = InvocationMirror::Level::kStatic;
    }
  }

  Fragment instructions;
  if (!receiver_pushed) {
    instructions += Constant(receiver);  // receiver
  }
  instructions +=
      ThrowNoSuchMethodError(position, String::ZoneHandle(Z, target.name()),
                             level, kind, /*receiver_pushed*/ true);
  return instructions;
}

Fragment FlowGraphBuilder::ThrowNoSuchMethodError(TokenPosition position,
                                                  const String& selector,
                                                  InvocationMirror::Level level,
                                                  InvocationMirror::Kind kind,
                                                  bool receiver_pushed) {
  const Class& klass = Class::ZoneHandle(
      Z, Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  ASSERT(!klass.IsNull());
  const auto& error = klass.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& throw_function = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!throw_function.IsNull());

  Fragment instructions;
  if (!receiver_pushed) {
    instructions += NullConstant();  // receiver
  }
  instructions += Constant(selector);
  instructions += IntConstant(InvocationMirror::EncodeType(level, kind));
  instructions += IntConstant(0);  // type arguments length
  instructions += NullConstant();  // type arguments
  instructions += NullConstant();  // arguments
  instructions += NullConstant();  // argumentNames
  instructions += StaticCall(position, throw_function, /* argument_count = */ 7,
                             ICData::kNoRebind);
  return instructions;
}

LocalVariable* FlowGraphBuilder::LookupVariable(intptr_t kernel_offset) {
  LocalVariable* local = scopes_->locals.Lookup(kernel_offset);
  ASSERT(local != nullptr);
  ASSERT(local->kernel_offset() == kernel_offset);
  return local;
}

FlowGraph* FlowGraphBuilder::BuildGraph() {
  const Function& function = parsed_function_->function();

#ifdef DEBUG
  // Check that all functions that are explicitly marked as recognized with the
  // vm:recognized annotation are in fact recognized. The check can't be done on
  // function creation, since the recognized status isn't set until later.
  if ((function.IsRecognized() !=
       MethodRecognizer::IsMarkedAsRecognized(function)) &&
      !function.IsDynamicInvocationForwarder()) {
    if (function.IsRecognized()) {
      FATAL("Recognized method %s is not marked with the vm:recognized pragma.",
            function.ToQualifiedCString());
    } else {
      FATAL("Non-recognized method %s is marked with the vm:recognized pragma.",
            function.ToQualifiedCString());
    }
  }
#endif

  auto& kernel_data = TypedDataView::Handle(Z, function.KernelLibrary());
  intptr_t kernel_data_program_offset = function.KernelLibraryOffset();

  StreamingFlowGraphBuilder streaming_flow_graph_builder(
      this, kernel_data, kernel_data_program_offset);
  auto result = streaming_flow_graph_builder.BuildGraph();

  FinalizeCoverageArray();
  result->set_coverage_array(coverage_array());

  if (streaming_flow_graph_builder.num_ast_nodes() >
      FLAG_huge_method_cutoff_in_ast_nodes) {
    if (FLAG_print_huge_methods) {
      OS::PrintErr(
          "Warning: \'%s\' from \'%s\' is too large. Some optimizations have "
          "been "
          "disabled, and the compiler might run out of memory. "
          "Consider refactoring this code into smaller components.\n",
          function.QualifiedUserVisibleNameCString(),
          String::Handle(Z, Library::Handle(
                                Z, Class::Handle(Z, function.Owner()).library())
                                .url())
              .ToCString());
    }
    result->mark_huge_method();
  }

  return result;
}

Fragment FlowGraphBuilder::NativeFunctionBody(const Function& function,
                                              LocalVariable* first_parameter) {
  ASSERT(function.is_native());
  ASSERT(!IsRecognizedMethodForFlowGraph(function));

  Fragment body;
  String& name = String::ZoneHandle(Z, function.native_name());
  if (function.IsGeneric()) {
    body += LoadLocal(parsed_function_->RawTypeArgumentsVariable());
  }
  for (intptr_t i = 0; i < function.NumParameters(); ++i) {
    body += LoadLocal(parsed_function_->RawParameterVariable(i));
  }
  body += NativeCall(name, function);
  // We typecheck results of native calls for type safety.
  body +=
      Return(TokenPosition::kNoSource, /* omit_result_type_check = */ false);
  return body;
}

#define LOAD_NATIVE_FIELD(V)                                                   \
  V(ByteDataViewLength, TypedDataBase_length)                                  \
  V(ByteDataViewOffsetInBytes, TypedDataView_offset_in_bytes)                  \
  V(ByteDataViewTypedData, TypedDataView_typed_data)                           \
  V(Finalizer_getCallback, Finalizer_callback)                                 \
  V(FinalizerBase_getAllEntries, FinalizerBase_all_entries)                    \
  V(FinalizerBase_getDetachments, FinalizerBase_detachments)                   \
  V(FinalizerEntry_getDetach, FinalizerEntry_detach)                           \
  V(FinalizerEntry_getNext, FinalizerEntry_next)                               \
  V(FinalizerEntry_getToken, FinalizerEntry_token)                             \
  V(FinalizerEntry_getValue, FinalizerEntry_value)                             \
  V(NativeFinalizer_getCallback, NativeFinalizer_callback)                     \
  V(GrowableArrayLength, GrowableObjectArray_length)                           \
  V(ReceivePort_getSendPort, ReceivePort_send_port)                            \
  V(ReceivePort_getHandler, ReceivePort_handler)                               \
  V(ImmutableLinkedHashBase_getData, ImmutableLinkedHashBase_data)             \
  V(ImmutableLinkedHashBase_getIndex, ImmutableLinkedHashBase_index)           \
  V(LinkedHashBase_getData, LinkedHashBase_data)                               \
  V(LinkedHashBase_getDeletedKeys, LinkedHashBase_deleted_keys)                \
  V(LinkedHashBase_getHashMask, LinkedHashBase_hash_mask)                      \
  V(LinkedHashBase_getIndex, LinkedHashBase_index)                             \
  V(LinkedHashBase_getUsedData, LinkedHashBase_used_data)                      \
  V(ObjectArrayLength, Array_length)                                           \
  V(Record_shape, Record_shape)                                                \
  V(SuspendState_getFunctionData, SuspendState_function_data)                  \
  V(SuspendState_getThenCallback, SuspendState_then_callback)                  \
  V(SuspendState_getErrorCallback, SuspendState_error_callback)                \
  V(TypedDataViewOffsetInBytes, TypedDataView_offset_in_bytes)                 \
  V(TypedDataViewTypedData, TypedDataView_typed_data)                          \
  V(TypedListBaseLength, TypedDataBase_length)                                 \
  V(WeakProperty_getKey, WeakProperty_key)                                     \
  V(WeakProperty_getValue, WeakProperty_value)                                 \
  V(WeakReference_getTarget, WeakReference_target)

#define STORE_NATIVE_FIELD(V)                                                  \
  V(Finalizer_setCallback, Finalizer_callback)                                 \
  V(FinalizerBase_setAllEntries, FinalizerBase_all_entries)                    \
  V(FinalizerBase_setDetachments, FinalizerBase_detachments)                   \
  V(FinalizerEntry_setToken, FinalizerEntry_token)                             \
  V(NativeFinalizer_setCallback, NativeFinalizer_callback)                     \
  V(ReceivePort_setHandler, ReceivePort_handler)                               \
  V(LinkedHashBase_setData, LinkedHashBase_data)                               \
  V(LinkedHashBase_setIndex, LinkedHashBase_index)                             \
  V(SuspendState_setFunctionData, SuspendState_function_data)                  \
  V(SuspendState_setThenCallback, SuspendState_then_callback)                  \
  V(SuspendState_setErrorCallback, SuspendState_error_callback)                \
  V(WeakProperty_setKey, WeakProperty_key)                                     \
  V(WeakProperty_setValue, WeakProperty_value)                                 \
  V(WeakReference_setTarget, WeakReference_target)

#define STORE_NATIVE_FIELD_NO_BARRIER(V)                                       \
  V(LinkedHashBase_setDeletedKeys, LinkedHashBase_deleted_keys)                \
  V(LinkedHashBase_setHashMask, LinkedHashBase_hash_mask)                      \
  V(LinkedHashBase_setUsedData, LinkedHashBase_used_data)

bool FlowGraphBuilder::IsRecognizedMethodForFlowGraph(
    const Function& function) {
  const MethodRecognizer::Kind kind = function.recognized_kind();

  switch (kind) {
    case MethodRecognizer::kRecord_fieldAt:
    case MethodRecognizer::kRecord_fieldNames:
    case MethodRecognizer::kRecord_numFields:
    case MethodRecognizer::kSuspendState_clone:
    case MethodRecognizer::kSuspendState_resume:
    case MethodRecognizer::kTypedData_memMove1:
    case MethodRecognizer::kTypedData_memMove2:
    case MethodRecognizer::kTypedData_memMove4:
    case MethodRecognizer::kTypedData_memMove8:
    case MethodRecognizer::kTypedData_memMove16:
    case MethodRecognizer::kTypedData_ByteDataView_factory:
    case MethodRecognizer::kTypedData_Int8ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint8ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint8ClampedArrayView_factory:
    case MethodRecognizer::kTypedData_Int16ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint16ArrayView_factory:
    case MethodRecognizer::kTypedData_Int32ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint32ArrayView_factory:
    case MethodRecognizer::kTypedData_Int64ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint64ArrayView_factory:
    case MethodRecognizer::kTypedData_Float32ArrayView_factory:
    case MethodRecognizer::kTypedData_Float64ArrayView_factory:
    case MethodRecognizer::kTypedData_Float32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_Int32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_Float64x2ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableByteDataView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt8ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint8ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint8ClampedArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt16ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint16ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat64x2ArrayView_factory:
    case MethodRecognizer::kTypedData_Int8Array_factory:
    case MethodRecognizer::kTypedData_Uint8Array_factory:
    case MethodRecognizer::kTypedData_Uint8ClampedArray_factory:
    case MethodRecognizer::kTypedData_Int16Array_factory:
    case MethodRecognizer::kTypedData_Uint16Array_factory:
    case MethodRecognizer::kTypedData_Int32Array_factory:
    case MethodRecognizer::kTypedData_Uint32Array_factory:
    case MethodRecognizer::kTypedData_Int64Array_factory:
    case MethodRecognizer::kTypedData_Uint64Array_factory:
    case MethodRecognizer::kTypedData_Float32Array_factory:
    case MethodRecognizer::kTypedData_Float64Array_factory:
    case MethodRecognizer::kTypedData_Float32x4Array_factory:
    case MethodRecognizer::kTypedData_Int32x4Array_factory:
    case MethodRecognizer::kTypedData_Float64x2Array_factory:
    case MethodRecognizer::kMemCopy:
    case MethodRecognizer::kFfiLoadInt8:
    case MethodRecognizer::kFfiLoadInt16:
    case MethodRecognizer::kFfiLoadInt32:
    case MethodRecognizer::kFfiLoadInt64:
    case MethodRecognizer::kFfiLoadUint8:
    case MethodRecognizer::kFfiLoadUint16:
    case MethodRecognizer::kFfiLoadUint32:
    case MethodRecognizer::kFfiLoadUint64:
    case MethodRecognizer::kFfiLoadFloat:
    case MethodRecognizer::kFfiLoadFloatUnaligned:
    case MethodRecognizer::kFfiLoadDouble:
    case MethodRecognizer::kFfiLoadDoubleUnaligned:
    case MethodRecognizer::kFfiLoadPointer:
    case MethodRecognizer::kFfiNativeCallbackFunction:
    case MethodRecognizer::kFfiNativeAsyncCallbackFunction:
    case MethodRecognizer::kFfiNativeIsolateLocalCallbackFunction:
    case MethodRecognizer::kFfiStoreInt8:
    case MethodRecognizer::kFfiStoreInt16:
    case MethodRecognizer::kFfiStoreInt32:
    case MethodRecognizer::kFfiStoreInt64:
    case MethodRecognizer::kFfiStoreUint8:
    case MethodRecognizer::kFfiStoreUint16:
    case MethodRecognizer::kFfiStoreUint32:
    case MethodRecognizer::kFfiStoreUint64:
    case MethodRecognizer::kFfiStoreFloat:
    case MethodRecognizer::kFfiStoreFloatUnaligned:
    case MethodRecognizer::kFfiStoreDouble:
    case MethodRecognizer::kFfiStoreDoubleUnaligned:
    case MethodRecognizer::kFfiStorePointer:
    case MethodRecognizer::kFfiFromAddress:
    case MethodRecognizer::kFfiGetAddress:
    case MethodRecognizer::kFfiAsExternalTypedDataInt8:
    case MethodRecognizer::kFfiAsExternalTypedDataInt16:
    case MethodRecognizer::kFfiAsExternalTypedDataInt32:
    case MethodRecognizer::kFfiAsExternalTypedDataInt64:
    case MethodRecognizer::kFfiAsExternalTypedDataUint8:
    case MethodRecognizer::kFfiAsExternalTypedDataUint16:
    case MethodRecognizer::kFfiAsExternalTypedDataUint32:
    case MethodRecognizer::kFfiAsExternalTypedDataUint64:
    case MethodRecognizer::kFfiAsExternalTypedDataFloat:
    case MethodRecognizer::kFfiAsExternalTypedDataDouble:
    case MethodRecognizer::kGetNativeField:
    case MethodRecognizer::kFinalizerBase_exchangeEntriesCollectedWithNull:
    case MethodRecognizer::kFinalizerBase_getIsolateFinalizers:
    case MethodRecognizer::kFinalizerBase_setIsolate:
    case MethodRecognizer::kFinalizerBase_setIsolateFinalizers:
    case MethodRecognizer::kFinalizerEntry_allocate:
    case MethodRecognizer::kFinalizerEntry_getExternalSize:
    case MethodRecognizer::kObjectEquals:
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
    case MethodRecognizer::kClassIDgetID:
    case MethodRecognizer::kGrowableArrayAllocateWithData:
    case MethodRecognizer::kGrowableArrayCapacity:
    case MethodRecognizer::kObjectArrayAllocate:
    case MethodRecognizer::kCopyRangeFromUint8ListToOneByteString:
    case MethodRecognizer::kImmutableLinkedHashBase_setIndexStoreRelease:
    case MethodRecognizer::kFfiAbi:
    case MethodRecognizer::kUtf8DecoderScan:
    case MethodRecognizer::kHas63BitSmis:
    case MethodRecognizer::kExtensionStreamHasListener:
    case MethodRecognizer::kSmi_hashCode:
    case MethodRecognizer::kMint_hashCode:
    case MethodRecognizer::kDouble_hashCode:
#define CASE(method, slot) case MethodRecognizer::k##method:
      LOAD_NATIVE_FIELD(CASE)
      STORE_NATIVE_FIELD(CASE)
      STORE_NATIVE_FIELD_NO_BARRIER(CASE)
#undef CASE
      return true;
    case MethodRecognizer::kDoubleToInteger:
    case MethodRecognizer::kDoubleMod:
    case MethodRecognizer::kDoubleRoundToDouble:
    case MethodRecognizer::kDoubleTruncateToDouble:
    case MethodRecognizer::kDoubleFloorToDouble:
    case MethodRecognizer::kDoubleCeilToDouble:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2:
    case MethodRecognizer::kMathExp:
    case MethodRecognizer::kMathLog:
    case MethodRecognizer::kMathSqrt:
      return FlowGraphCompiler::SupportsUnboxedDoubles();
    case MethodRecognizer::kDoubleCeilToInt:
    case MethodRecognizer::kDoubleFloorToInt:
      if (!FlowGraphCompiler::SupportsUnboxedDoubles()) return false;
#if defined(TARGET_ARCH_X64)
      return CompilerState::Current().is_aot() || FLAG_target_unknown_cpu;
#elif defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV32) ||            \
    defined(TARGET_ARCH_RISCV64)
      return true;
#else
      return false;
#endif
    default:
      return false;
  }
}

FlowGraph* FlowGraphBuilder::BuildGraphOfRecognizedMethod(
    const Function& function) {
  ASSERT(IsRecognizedMethodForFlowGraph(function));

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment body(instruction_cursor);
  body += CheckStackOverflowInPrologue(function.token_pos());

  const MethodRecognizer::Kind kind = function.recognized_kind();
  switch (kind) {
    case MethodRecognizer::kRecord_fieldAt:
      ASSERT_EQUAL(function.NumParameters(), 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += LoadIndexed(
          kRecordCid, /*index_scale*/ compiler::target::kCompressedWordSize);
      break;
    case MethodRecognizer::kRecord_fieldNames:
      body += LoadObjectStore();
      body += RawLoadField(
          compiler::target::ObjectStore::record_field_names_offset());
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::Record_shape());
      body += IntConstant(compiler::target::RecordShape::kFieldNamesIndexShift);
      body += SmiBinaryOp(Token::kSHR);
      body += IntConstant(compiler::target::RecordShape::kFieldNamesIndexMask);
      body += SmiBinaryOp(Token::kBIT_AND);
      body += LoadIndexed(
          kArrayCid, /*index_scale=*/compiler::target::kCompressedWordSize);
      break;
    case MethodRecognizer::kRecord_numFields:
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::Record_shape());
      body += IntConstant(compiler::target::RecordShape::kNumFieldsMask);
      body += SmiBinaryOp(Token::kBIT_AND);
      break;
    case MethodRecognizer::kSuspendState_clone: {
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += Call1ArgStub(TokenPosition::kNoSource,
                           Call1ArgStubInstr::StubId::kCloneSuspendState);
      break;
    }
    case MethodRecognizer::kSuspendState_resume: {
      const Code& resume_stub =
          Code::ZoneHandle(Z, IG->object_store()->resume_stub());
      body += NullConstant();
      body += TailCall(resume_stub);
      break;
    }
    case MethodRecognizer::kTypedData_memMove1:
      // Pick an appropriate typed data cid based on the element size.
      body += BuildTypedDataMemMove(function, kTypedDataUint8ArrayCid);
      break;
    case MethodRecognizer::kTypedData_memMove2:
      body += BuildTypedDataMemMove(function, kTypedDataUint16ArrayCid);
      break;
    case MethodRecognizer::kTypedData_memMove4:
      body += BuildTypedDataMemMove(function, kTypedDataUint32ArrayCid);
      break;
    case MethodRecognizer::kTypedData_memMove8:
      body += BuildTypedDataMemMove(function, kTypedDataUint64ArrayCid);
      break;
    case MethodRecognizer::kTypedData_memMove16:
      body += BuildTypedDataMemMove(function, kTypedDataInt32x4ArrayCid);
      break;
#define CASE(name)                                                             \
  case MethodRecognizer::kTypedData_##name##_factory:                          \
    body += BuildTypedDataFactoryConstructor(function, kTypedData##name##Cid); \
    break;                                                                     \
  case MethodRecognizer::kTypedData_##name##View_factory:                      \
    body += BuildTypedDataViewFactoryConstructor(function,                     \
                                                 kTypedData##name##ViewCid);   \
    break;                                                                     \
  case MethodRecognizer::kTypedData_Unmodifiable##name##View_factory:          \
    body += BuildTypedDataViewFactoryConstructor(                              \
        function, kUnmodifiableTypedData##name##ViewCid);                      \
    break;
      CLASS_LIST_TYPED_DATA(CASE)
#undef CASE
    case MethodRecognizer::kTypedData_ByteDataView_factory:
      body += BuildTypedDataViewFactoryConstructor(function, kByteDataViewCid);
      break;
    case MethodRecognizer::kTypedData_UnmodifiableByteDataView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kUnmodifiableByteDataViewCid);
      break;
    case MethodRecognizer::kObjectEquals:
      ASSERT_EQUAL(function.NumParameters(), 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StrictCompare(Token::kEQ_STRICT);
      break;
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::String_length());
      if (kind == MethodRecognizer::kStringBaseIsEmpty) {
        body += IntConstant(0);
        body += StrictCompare(Token::kEQ_STRICT);
      }
      break;
    case MethodRecognizer::kClassIDgetID:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadClassId();
      break;
    case MethodRecognizer::kGrowableArrayAllocateWithData: {
      ASSERT(function.IsFactory());
      ASSERT_EQUAL(function.NumParameters(), 2);
      const Class& cls =
          Class::ZoneHandle(Z, compiler::GrowableObjectArrayClass().ptr());
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += AllocateObject(TokenPosition::kNoSource, cls, 1);
      LocalVariable* object = MakeTemporary();
      body += LoadLocal(object);
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreNativeField(Slot::GrowableObjectArray_data(),
                               StoreFieldInstr::Kind::kInitializing,
                               kNoStoreBarrier);
      body += LoadLocal(object);
      body += IntConstant(0);
      body += StoreNativeField(Slot::GrowableObjectArray_length(),
                               StoreFieldInstr::Kind::kInitializing,
                               kNoStoreBarrier);
      break;
    }
    case MethodRecognizer::kGrowableArrayCapacity:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::GrowableObjectArray_data());
      body += LoadNativeField(Slot::Array_length());
      break;
    case MethodRecognizer::kObjectArrayAllocate:
      ASSERT(function.IsFactory() && (function.NumParameters() == 2));
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += CreateArray();
      break;
    case MethodRecognizer::kCopyRangeFromUint8ListToOneByteString:
      ASSERT_EQUAL(function.NumParameters(), 5);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += LoadLocal(parsed_function_->RawParameterVariable(2));
      body += LoadLocal(parsed_function_->RawParameterVariable(3));
      body += LoadLocal(parsed_function_->RawParameterVariable(4));
      body += MemoryCopy(kTypedDataUint8ArrayCid, kOneByteStringCid,
                         /*unboxed_inputs=*/false,
                         /*can_overlap=*/false);
      body += NullConstant();
      break;
    case MethodRecognizer::kImmutableLinkedHashBase_setIndexStoreRelease:
      ASSERT_EQUAL(function.NumParameters(), 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      // Uses a store-release barrier so that other isolates will see the
      // contents of the index after seeing the index itself.
      body += StoreNativeField(Slot::ImmutableLinkedHashBase_index(),
                               StoreFieldInstr::Kind::kOther, kEmitStoreBarrier,
                               compiler::Assembler::kRelease);
      body += NullConstant();
      break;
    case MethodRecognizer::kUtf8DecoderScan:
      ASSERT_EQUAL(function.NumParameters(), 5);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // decoder
      body += LoadLocal(parsed_function_->RawParameterVariable(1));  // bytes
      body += LoadLocal(parsed_function_->RawParameterVariable(2));  // start
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedIntPtr);
      body += LoadLocal(parsed_function_->RawParameterVariable(3));  // end
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedIntPtr);
      body += LoadLocal(parsed_function_->RawParameterVariable(4));  // table
      body += Utf8Scan();
      body += Box(kUnboxedIntPtr);
      break;
    case MethodRecognizer::kMemCopy: {
      // Keep consistent with inliner.cc (except boxed param).
      ASSERT_EQUAL(function.NumParameters(), 5);
      LocalVariable* arg_target = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_target_offset_in_bytes =
          parsed_function_->RawParameterVariable(1);
      LocalVariable* arg_source = parsed_function_->RawParameterVariable(2);
      LocalVariable* arg_source_offset_in_bytes =
          parsed_function_->RawParameterVariable(3);
      LocalVariable* arg_length_in_bytes =
          parsed_function_->RawParameterVariable(4);
      body += LoadLocal(arg_source);
      body += LoadLocal(arg_target);
      body += LoadLocal(arg_source_offset_in_bytes);
      body += LoadLocal(arg_target_offset_in_bytes);
      body += LoadLocal(arg_length_in_bytes);
      // Pointers and TypedData have the same layout.
      body += MemoryCopy(kTypedDataUint8ArrayCid, kTypedDataUint8ArrayCid,
                         /*unboxed_inputs=*/false,
                         /*can_overlap=*/true);
      body += NullConstant();
    } break;
    case MethodRecognizer::kFfiAbi:
      ASSERT_EQUAL(function.NumParameters(), 0);
      body += IntConstant(static_cast<int64_t>(compiler::ffi::TargetAbi()));
      break;
    case MethodRecognizer::kFfiNativeCallbackFunction:
    case MethodRecognizer::kFfiNativeAsyncCallbackFunction:
    case MethodRecognizer::kFfiNativeIsolateLocalCallbackFunction: {
      const auto& error = String::ZoneHandle(
          Z, Symbols::New(thread_,
                          "This function should be handled on call site."));
      body += Constant(error);
      body += ThrowException(TokenPosition::kNoSource);
      break;
    }
    case MethodRecognizer::kFfiLoadInt8:
    case MethodRecognizer::kFfiLoadInt16:
    case MethodRecognizer::kFfiLoadInt32:
    case MethodRecognizer::kFfiLoadInt64:
    case MethodRecognizer::kFfiLoadUint8:
    case MethodRecognizer::kFfiLoadUint16:
    case MethodRecognizer::kFfiLoadUint32:
    case MethodRecognizer::kFfiLoadUint64:
    case MethodRecognizer::kFfiLoadFloat:
    case MethodRecognizer::kFfiLoadFloatUnaligned:
    case MethodRecognizer::kFfiLoadDouble:
    case MethodRecognizer::kFfiLoadDoubleUnaligned:
    case MethodRecognizer::kFfiLoadPointer: {
      const classid_t ffi_type_arg_cid =
          compiler::ffi::RecognizedMethodTypeArgCid(kind);
      const AlignmentType alignment =
          compiler::ffi::RecognizedMethodAlignment(kind);
      const classid_t typed_data_cid =
          compiler::ffi::ElementTypedDataCid(ffi_type_arg_cid);

      ASSERT_EQUAL(function.NumParameters(), 2);
      LocalVariable* arg_pointer = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_offset = parsed_function_->RawParameterVariable(1);

      body += LoadLocal(arg_offset);
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_offset_not_null = MakeTemporary();

      body += LoadLocal(arg_pointer);
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      // No GC from here til LoadIndexed.
      body += LoadUntagged(compiler::target::PointerBase::data_offset());
      body += LoadLocal(arg_offset_not_null);
      body += UnboxTruncate(kUnboxedFfiIntPtr);
      body += LoadIndexed(typed_data_cid, /*index_scale=*/1,
                          /*index_unboxed=*/true, alignment);
      if (kind == MethodRecognizer::kFfiLoadFloat ||
          kind == MethodRecognizer::kFfiLoadFloatUnaligned) {
        body += FloatToDouble();
      }
      // Avoid any unnecessary (and potentially deoptimizing) int
      // conversions by using the representation returned from LoadIndexed.
      body +=
          Box(LoadIndexedInstr::RepresentationOfArrayElement(typed_data_cid));
      if (kind == MethodRecognizer::kFfiLoadPointer) {
        const auto& pointer_class =
            Class::ZoneHandle(Z, IG->object_store()->ffi_pointer_class());
        const auto& type_arguments = TypeArguments::ZoneHandle(
            Z, IG->object_store()->type_argument_never());

        // We do not reify Pointer type arguments
        ASSERT(function.NumTypeParameters() == 1);
        LocalVariable* address = MakeTemporary();
        body += Constant(type_arguments);
        body += AllocateObject(TokenPosition::kNoSource, pointer_class, 1);
        LocalVariable* pointer = MakeTemporary();
        body += LoadLocal(pointer);
        body += LoadLocal(address);
        body += UnboxTruncate(kUnboxedIntPtr);
        body += StoreNativeField(Slot::PointerBase_data());
        body += DropTempsPreserveTop(1);  // Drop [address] keep [pointer].
      }
      body += DropTempsPreserveTop(1);  // Drop [arg_offset].
    } break;
    case MethodRecognizer::kFfiStoreInt8:
    case MethodRecognizer::kFfiStoreInt16:
    case MethodRecognizer::kFfiStoreInt32:
    case MethodRecognizer::kFfiStoreInt64:
    case MethodRecognizer::kFfiStoreUint8:
    case MethodRecognizer::kFfiStoreUint16:
    case MethodRecognizer::kFfiStoreUint32:
    case MethodRecognizer::kFfiStoreUint64:
    case MethodRecognizer::kFfiStoreFloat:
    case MethodRecognizer::kFfiStoreFloatUnaligned:
    case MethodRecognizer::kFfiStoreDouble:
    case MethodRecognizer::kFfiStoreDoubleUnaligned:
    case MethodRecognizer::kFfiStorePointer: {
      const classid_t ffi_type_arg_cid =
          compiler::ffi::RecognizedMethodTypeArgCid(kind);
      const AlignmentType alignment =
          compiler::ffi::RecognizedMethodAlignment(kind);
      const classid_t typed_data_cid =
          compiler::ffi::ElementTypedDataCid(ffi_type_arg_cid);

      LocalVariable* arg_pointer = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_offset = parsed_function_->RawParameterVariable(1);
      LocalVariable* arg_value = parsed_function_->RawParameterVariable(2);

      ASSERT_EQUAL(function.NumParameters(), 3);
      body += LoadLocal(arg_offset);
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_offset_not_null = MakeTemporary();
      body += LoadLocal(arg_value);
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_value_not_null = MakeTemporary();

      body += LoadLocal(arg_pointer);  // Pointer.
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      // No GC from here til StoreIndexed.
      body += LoadUntagged(compiler::target::PointerBase::data_offset());
      body += LoadLocal(arg_offset_not_null);
      body += UnboxTruncate(kUnboxedFfiIntPtr);
      body += LoadLocal(arg_value_not_null);
      if (kind == MethodRecognizer::kFfiStorePointer) {
        // This can only be Pointer, so it is always safe to LoadUntagged.
        body += LoadUntagged(compiler::target::PointerBase::data_offset());
        body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
      } else {
        // Avoid any unnecessary (and potentially deoptimizing) int
        // conversions by using the representation consumed by StoreIndexed.
        body += UnboxTruncate(
            StoreIndexedInstr::RepresentationOfArrayElement(typed_data_cid));
        if (kind == MethodRecognizer::kFfiStoreFloat ||
            kind == MethodRecognizer::kFfiStoreFloatUnaligned) {
          body += DoubleToFloat();
        }
      }
      body += StoreIndexedTypedData(typed_data_cid, /*index_scale=*/1,
                                    /*index_unboxed=*/true, alignment);
      body += Drop();  // Drop [arg_value].
      body += Drop();  // Drop [arg_offset].
      body += NullConstant();
    } break;
    case MethodRecognizer::kFfiFromAddress: {
      const auto& pointer_class =
          Class::ZoneHandle(Z, IG->object_store()->ffi_pointer_class());
      const auto& type_arguments = TypeArguments::ZoneHandle(
          Z, IG->object_store()->type_argument_never());

      ASSERT(function.NumTypeParameters() == 1);
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += Constant(type_arguments);
      body += AllocateObject(TokenPosition::kNoSource, pointer_class, 1);
      body += LoadLocal(MakeTemporary());  // Duplicate Pointer.
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // Address.
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedIntPtr);
      body += StoreNativeField(Slot::PointerBase_data());
    } break;
    case MethodRecognizer::kFfiGetAddress: {
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // Pointer.
      body += CheckNullOptimized(String::ZoneHandle(Z, function.name()));
      // This can only be Pointer, so it is always safe to LoadUntagged.
      body += LoadUntagged(compiler::target::PointerBase::data_offset());
      body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
      body += Box(kUnboxedFfiIntPtr);
    } break;
    case MethodRecognizer::kHas63BitSmis: {
#if defined(HAS_SMI_63_BITS)
      body += Constant(Bool::True());
#else
      body += Constant(Bool::False());
#endif  // defined(ARCH_IS_64_BIT)
    } break;
    case MethodRecognizer::kExtensionStreamHasListener: {
#ifdef PRODUCT
      body += Constant(Bool::False());
#else
      body += LoadServiceExtensionStream();
      body += RawLoadField(compiler::target::StreamInfo::enabled_offset());
      // StreamInfo::enabled_ is a std::atomic<intptr_t>. This is effectively
      // relaxed order access, which is acceptable for this use case.
      body += IntToBool();
#endif  // PRODUCT
    } break;
    case MethodRecognizer::kSmi_hashCode: {
      // TODO(dartbug.com/38985): We should make this LoadLocal+Unbox+
      // IntegerHash+Box. Though  this would make use of unboxed values on stack
      // which isn't allowed in unoptimized mode.
      // Once force-optimized functions can be inlined, we should change this
      // code to the above.
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += BuildIntegerHashCode(/*smi=*/true);
    } break;
    case MethodRecognizer::kMint_hashCode: {
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += BuildIntegerHashCode(/*smi=*/false);
    } break;
    case MethodRecognizer::kDouble_hashCode: {
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += UnboxTruncate(kUnboxedDouble);
      body += BuildDoubleHashCode();
      body += Box(kUnboxedInt64);
    } break;
    case MethodRecognizer::kFfiAsExternalTypedDataInt8:
    case MethodRecognizer::kFfiAsExternalTypedDataInt16:
    case MethodRecognizer::kFfiAsExternalTypedDataInt32:
    case MethodRecognizer::kFfiAsExternalTypedDataInt64:
    case MethodRecognizer::kFfiAsExternalTypedDataUint8:
    case MethodRecognizer::kFfiAsExternalTypedDataUint16:
    case MethodRecognizer::kFfiAsExternalTypedDataUint32:
    case MethodRecognizer::kFfiAsExternalTypedDataUint64:
    case MethodRecognizer::kFfiAsExternalTypedDataFloat:
    case MethodRecognizer::kFfiAsExternalTypedDataDouble: {
      const classid_t ffi_type_arg_cid =
          compiler::ffi::RecognizedMethodTypeArgCid(kind);
      const classid_t external_typed_data_cid =
          compiler::ffi::ElementExternalTypedDataCid(ffi_type_arg_cid);

      auto class_table = thread_->isolate_group()->class_table();
      ASSERT(class_table->HasValidClassAt(external_typed_data_cid));
      const auto& typed_data_class =
          Class::ZoneHandle(H.zone(), class_table->At(external_typed_data_cid));

      // We assume that the caller has checked that the arguments are non-null
      // and length is in the range [0, kSmiMax/elementSize].
      ASSERT_EQUAL(function.NumParameters(), 2);
      LocalVariable* arg_pointer = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_length = parsed_function_->RawParameterVariable(1);

      body += AllocateObject(TokenPosition::kNoSource, typed_data_class, 0);
      LocalVariable* typed_data_object = MakeTemporary();

      // Initialize the result's length field.
      body += LoadLocal(typed_data_object);
      body += LoadLocal(arg_length);
      body += StoreNativeField(Slot::TypedDataBase_length(),
                               StoreFieldInstr::Kind::kInitializing,
                               kNoStoreBarrier);

      // Initialize the result's data pointer field.
      body += LoadLocal(typed_data_object);
      body += LoadLocal(arg_pointer);
      body += LoadUntagged(compiler::target::PointerBase::data_offset());
      body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);
      body += StoreNativeField(Slot::PointerBase_data(),
                               StoreFieldInstr::Kind::kInitializing,
                               kNoStoreBarrier);
    } break;
    case MethodRecognizer::kGetNativeField: {
      auto& name = String::ZoneHandle(Z, function.name());
      // Note: This method is force optimized so we can push untagged, etc.
      // Load TypedDataArray from Instance Handle implementing
      // NativeFieldWrapper.
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // Object.
      body += CheckNullOptimized(name);
      body += LoadNativeField(Slot::Instance_native_fields_array());  // Fields.
      body += CheckNullOptimized(name);
      // Load the native field at index.
      body += IntConstant(0);  // Index.
      body += LoadIndexed(kIntPtrCid);
      body += Box(kUnboxedIntPtr);
    } break;
    case MethodRecognizer::kDoubleToInteger:
    case MethodRecognizer::kDoubleCeilToInt:
    case MethodRecognizer::kDoubleFloorToInt: {
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += DoubleToInteger(kind);
    } break;
    case MethodRecognizer::kDoubleMod:
    case MethodRecognizer::kDoubleRoundToDouble:
    case MethodRecognizer::kDoubleTruncateToDouble:
    case MethodRecognizer::kDoubleFloorToDouble:
    case MethodRecognizer::kDoubleCeilToDouble:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2:
    case MethodRecognizer::kMathExp:
    case MethodRecognizer::kMathLog: {
      for (intptr_t i = 0, n = function.NumParameters(); i < n; ++i) {
        body += LoadLocal(parsed_function_->RawParameterVariable(i));
      }
      if (!CompilerState::Current().is_aot() &&
          TargetCPUFeatures::double_truncate_round_supported() &&
          ((kind == MethodRecognizer::kDoubleTruncateToDouble) ||
           (kind == MethodRecognizer::kDoubleFloorToDouble) ||
           (kind == MethodRecognizer::kDoubleCeilToDouble))) {
        body += DoubleToDouble(kind);
      } else {
        body += InvokeMathCFunction(kind, function.NumParameters());
      }
    } break;
    case MethodRecognizer::kMathSqrt: {
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += MathUnary(MathUnaryInstr::kSqrt);
    } break;
    case MethodRecognizer::kFinalizerBase_setIsolate:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadIsolate();
      body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);
      body += StoreNativeField(Slot::FinalizerBase_isolate());
      body += NullConstant();
      break;
    case MethodRecognizer::kFinalizerBase_getIsolateFinalizers:
      ASSERT_EQUAL(function.NumParameters(), 0);
      body += LoadIsolate();
      body += RawLoadField(compiler::target::Isolate::finalizers_offset());
      break;
    case MethodRecognizer::kFinalizerBase_setIsolateFinalizers:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadIsolate();
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += RawStoreField(compiler::target::Isolate::finalizers_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kFinalizerBase_exchangeEntriesCollectedWithNull:
      ASSERT_EQUAL(function.NumParameters(), 1);
      ASSERT(this->optimizing_);
      // This relies on being force-optimized to do an 'atomic' exchange w.r.t.
      // the GC.
      // As an alternative design we could introduce an ExchangeNativeFieldInstr
      // that uses the same machine code as std::atomic::exchange. Or we could
      // use an FfiNative to do that in C.
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      // No GC from here til StoreNativeField.
      body += LoadNativeField(Slot::FinalizerBase_entries_collected());
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += NullConstant();
      body += StoreNativeField(Slot::FinalizerBase_entries_collected());
      break;
    case MethodRecognizer::kFinalizerEntry_allocate: {
      // Object value, Object token, Object detach, FinalizerBase finalizer
      ASSERT_EQUAL(function.NumParameters(), 4);

      const auto class_table = thread_->isolate_group()->class_table();
      ASSERT(class_table->HasValidClassAt(kFinalizerEntryCid));
      const auto& finalizer_entry_class =
          Class::ZoneHandle(H.zone(), class_table->At(kFinalizerEntryCid));

      body +=
          AllocateObject(TokenPosition::kNoSource, finalizer_entry_class, 0);
      LocalVariable* const entry = MakeTemporary("entry");
      // No GC from here to the end.
      body += LoadLocal(entry);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += StoreNativeField(Slot::FinalizerEntry_value());
      body += LoadLocal(entry);
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreNativeField(Slot::FinalizerEntry_token());
      body += LoadLocal(entry);
      body += LoadLocal(parsed_function_->RawParameterVariable(2));
      body += StoreNativeField(Slot::FinalizerEntry_detach());
      body += LoadLocal(entry);
      body += LoadLocal(parsed_function_->RawParameterVariable(3));
      body += StoreNativeField(Slot::FinalizerEntry_finalizer());
      body += LoadLocal(entry);
      body += UnboxedIntConstant(0, kUnboxedIntPtr);
      body += StoreNativeField(Slot::FinalizerEntry_external_size());
      break;
    }
    case MethodRecognizer::kFinalizerEntry_getExternalSize:
      ASSERT_EQUAL(function.NumParameters(), 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::FinalizerEntry_external_size());
      body += Box(kUnboxedInt64);
      break;
#define IL_BODY(method, slot)                                                  \
  case MethodRecognizer::k##method:                                            \
    ASSERT_EQUAL(function.NumParameters(), 1);                                 \
    body += LoadLocal(parsed_function_->RawParameterVariable(0));              \
    body += LoadNativeField(Slot::slot());                                     \
    break;
      LOAD_NATIVE_FIELD(IL_BODY)
#undef IL_BODY
#define IL_BODY(method, slot)                                                  \
  case MethodRecognizer::k##method:                                            \
    ASSERT_EQUAL(function.NumParameters(), 2);                                 \
    body += LoadLocal(parsed_function_->RawParameterVariable(0));              \
    body += LoadLocal(parsed_function_->RawParameterVariable(1));              \
    body += StoreNativeField(Slot::slot());                                    \
    body += NullConstant();                                                    \
    break;
      STORE_NATIVE_FIELD(IL_BODY)
#undef IL_BODY
#define IL_BODY(method, slot)                                                  \
  case MethodRecognizer::k##method:                                            \
    ASSERT_EQUAL(function.NumParameters(), 2);                                 \
    body += LoadLocal(parsed_function_->RawParameterVariable(0));              \
    body += LoadLocal(parsed_function_->RawParameterVariable(1));              \
    body += StoreNativeField(Slot::slot(), StoreFieldInstr::Kind::kOther,      \
                             kNoStoreBarrier);                                 \
    body += NullConstant();                                                    \
    break;
      STORE_NATIVE_FIELD_NO_BARRIER(IL_BODY)
#undef IL_BODY
    default: {
      UNREACHABLE();
      break;
    }
  }

  if (body.is_open()) {
    body +=
        Return(TokenPosition::kNoSource, /* omit_result_type_check = */ true);
  }

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

Fragment FlowGraphBuilder::BuildTypedDataViewFactoryConstructor(
    const Function& function,
    classid_t cid) {
  auto token_pos = function.token_pos();
  auto class_table = Thread::Current()->isolate_group()->class_table();

  ASSERT(class_table->HasValidClassAt(cid));
  const auto& view_class = Class::ZoneHandle(H.zone(), class_table->At(cid));

  ASSERT(function.IsFactory() && (function.NumParameters() == 4));
  LocalVariable* typed_data = parsed_function_->RawParameterVariable(1);
  LocalVariable* offset_in_bytes = parsed_function_->RawParameterVariable(2);
  LocalVariable* length = parsed_function_->RawParameterVariable(3);

  Fragment body;

  body += AllocateObject(token_pos, view_class, /*arg_count=*/0);
  LocalVariable* view_object = MakeTemporary();

  body += LoadLocal(view_object);
  body += LoadLocal(typed_data);
  body += StoreNativeField(token_pos, Slot::TypedDataView_typed_data(),
                           StoreFieldInstr::Kind::kInitializing);

  body += LoadLocal(view_object);
  body += LoadLocal(offset_in_bytes);
  body +=
      StoreNativeField(token_pos, Slot::TypedDataView_offset_in_bytes(),
                       StoreFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  body += LoadLocal(view_object);
  body += LoadLocal(length);
  body +=
      StoreNativeField(token_pos, Slot::TypedDataBase_length(),
                       StoreFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  // Update the inner pointer.
  //
  // WARNING: Notice that we assume here no GC happens between those 4
  // instructions!
  body += LoadLocal(view_object);
  body += LoadLocal(typed_data);
  body += LoadUntagged(compiler::target::PointerBase::data_offset());
  body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);
  body += LoadLocal(offset_in_bytes);
  body += UnboxSmiToIntptr();
  body += AddIntptrIntegers();
  body += StoreNativeField(Slot::PointerBase_data());

  return body;
}

Fragment FlowGraphBuilder::BuildTypedDataMemMove(const Function& function,
                                                 intptr_t cid) {
  ASSERT_EQUAL(parsed_function_->function().NumParameters(), 5);
  LocalVariable* arg_to = parsed_function_->RawParameterVariable(0);
  LocalVariable* arg_to_start = parsed_function_->RawParameterVariable(1);
  LocalVariable* arg_count = parsed_function_->RawParameterVariable(2);
  LocalVariable* arg_from = parsed_function_->RawParameterVariable(3);
  LocalVariable* arg_from_start = parsed_function_->RawParameterVariable(4);

  Fragment body;
  // If we're copying at least this many elements, calling _nativeSetRange,
  // which calls memmove via a native call, is faster than using the code
  // currently emitted by the MemoryCopy instruction.
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)
  // On X86, the breakpoint for using a native call instead of generating a
  // loop via MemoryCopy() is around the same as the largest benchmark
  // (1048576 elements) on the machines we use.
  const intptr_t kCopyLengthForNativeCall = 1024 * 1024;
#else
  // On other architectures, when the element size is less than a word,
  // we copy in word-sized chunks when possible to get back some speed without
  // increasing the number of emitted instructions for MemoryCopy too much, but
  // memmove is even more aggressive, copying in 64-byte chunks when possible.
  // Thus, the breakpoint for a native call being faster is much lower for our
  // benchmarks than for X86.
  const intptr_t kCopyLengthForNativeCall = 1024;
#endif

  JoinEntryInstr* done = BuildJoinEntry();
  TargetEntryInstr *is_small_enough, *is_too_large;
  body += LoadLocal(arg_count);
  body += IntConstant(kCopyLengthForNativeCall);
  body += SmiRelationalOp(Token::kLT);
  body += BranchIfTrue(&is_small_enough, &is_too_large);

  Fragment use_instruction(is_small_enough);
  use_instruction += LoadLocal(arg_from);
  use_instruction += LoadLocal(arg_to);
  use_instruction += LoadLocal(arg_from_start);
  use_instruction += LoadLocal(arg_to_start);
  use_instruction += LoadLocal(arg_count);
  use_instruction += MemoryCopy(cid, cid,
                                /*unboxed_inputs=*/false, /*can_overlap=*/true);
  use_instruction += Goto(done);

  // TODO(dartbug.com/42072): Instead of doing a static call to a native
  // method, make a leaf runtime entry for memmove and use CCall.
  const Library& lib = Library::Handle(Z, Library::TypedDataLibrary());
  ASSERT(!lib.IsNull());
  const Class& typed_list_base =
      Class::Handle(Z, lib.LookupClassAllowPrivate(Symbols::_TypedListBase()));
  ASSERT(!typed_list_base.IsNull());
  const auto& error = typed_list_base.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& native_set_range = Function::ZoneHandle(
      Z,
      typed_list_base.LookupFunctionAllowPrivate(Symbols::_nativeSetRange()));
  ASSERT(!native_set_range.IsNull());

  Fragment call_native(is_too_large);
  call_native += LoadLocal(arg_to);
  call_native += LoadLocal(arg_to_start);
  call_native += LoadLocal(arg_count);
  call_native += LoadLocal(arg_from);
  call_native += LoadLocal(arg_from_start);
  call_native += StaticCall(TokenPosition::kNoSource, native_set_range, 5,
                            ICData::kNoRebind);
  call_native += Drop();
  call_native += Goto(done);

  body.current = done;
  body += NullConstant();

  return body;
}

Fragment FlowGraphBuilder::BuildTypedDataFactoryConstructor(
    const Function& function,
    classid_t cid) {
  const auto token_pos = function.token_pos();
  ASSERT(
      Thread::Current()->isolate_group()->class_table()->HasValidClassAt(cid));

  ASSERT(function.IsFactory() && (function.NumParameters() == 2));
  LocalVariable* length = parsed_function_->RawParameterVariable(1);

  Fragment instructions;
  instructions += LoadLocal(length);
  // AllocateTypedData instruction checks that length is valid (a non-negative
  // Smi below maximum allowed length).
  instructions += AllocateTypedData(token_pos, cid);
  return instructions;
}

static const LocalScope* MakeImplicitClosureScope(Zone* Z, const Class& klass) {
  ASSERT(!klass.IsNull());
  // Note that if klass is _Closure, DeclarationType will be _Closure,
  // and not the signature type.
  Type& klass_type = Type::ZoneHandle(Z, klass.DeclarationType());

  LocalVariable* receiver_variable =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::This(), klass_type);

  receiver_variable->set_is_captured();
  //  receiver_variable->set_is_final();
  LocalScope* scope = new (Z) LocalScope(nullptr, 0, 0);
  scope->set_context_level(0);
  scope->AddVariable(receiver_variable);
  scope->AddContextVariable(receiver_variable);
  return scope;
}

Fragment FlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  // The function cannot be local and have parent generic functions.
  ASSERT(!target.HasGenericParent());

  Fragment fragment;
  fragment += Constant(target);

  // Allocate a context that closes over `this`.
  // Note: this must be kept in sync with ScopeBuilder::BuildScopes.
  const LocalScope* implicit_closure_scope =
      MakeImplicitClosureScope(Z, Class::Handle(Z, target.Owner()));
  fragment += AllocateContext(implicit_closure_scope->context_slots());
  LocalVariable* context = MakeTemporary();

  // Store `this`.  The context doesn't need a parent pointer because it doesn't
  // close over anything else.
  fragment += LoadLocal(context);
  fragment += LoadLocal(parsed_function_->receiver_var());
  fragment += StoreNativeField(
      Slot::GetContextVariableSlotFor(
          thread_, *implicit_closure_scope->context_variables()[0]),
      StoreFieldInstr::Kind::kInitializing);

  fragment += AllocateClosure();
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  if (!target.HasInstantiatedSignature(kCurrentClass)) {
    fragment += LoadLocal(closure);
    fragment += LoadInstantiatorTypeArguments();
    fragment += StoreNativeField(Slot::Closure_instantiator_type_arguments(),
                                 StoreFieldInstr::Kind::kInitializing);
  }

  if (target.IsGeneric()) {
    // Only generic functions need to have properly initialized
    // delayed_type_arguments.
    fragment += LoadLocal(closure);
    fragment += Constant(Object::empty_type_arguments());
    fragment += StoreNativeField(Slot::Closure_delayed_type_arguments(),
                                 StoreFieldInstr::Kind::kInitializing);
  }

  return fragment;
}

Fragment FlowGraphBuilder::CheckVariableTypeInCheckedMode(
    const AbstractType& dst_type,
    const String& name_symbol) {
  return Fragment();
}

bool FlowGraphBuilder::NeedsDebugStepCheck(const Function& function,
                                           TokenPosition position) {
  return position.IsDebugPause() && !function.is_native() &&
         function.is_debuggable();
}

bool FlowGraphBuilder::NeedsDebugStepCheck(Value* value,
                                           TokenPosition position) {
  if (!position.IsDebugPause()) {
    return false;
  }
  Definition* definition = value->definition();
  if (definition->IsConstant() || definition->IsLoadStaticField() ||
      definition->IsLoadLocal() || definition->IsAssertAssignable() ||
      definition->IsAllocateSmallRecord() || definition->IsAllocateRecord()) {
    return true;
  }
  if (auto const alloc = definition->AsAllocateClosure()) {
    return !alloc->known_function().IsNull();
  }
  return false;
}

Fragment FlowGraphBuilder::EvaluateAssertion() {
  const Class& klass =
      Class::ZoneHandle(Z, Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const auto& error = klass.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& target = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::EvaluateAssertion()));
  ASSERT(!target.IsNull());
  return StaticCall(TokenPosition::kNoSource, target, /* argument_count = */ 1,
                    ICData::kStatic);
}

Fragment FlowGraphBuilder::CheckBoolean(TokenPosition position) {
  Fragment instructions;
  LocalVariable* top_of_stack = MakeTemporary();
  instructions += LoadLocal(top_of_stack);
  instructions += AssertBool(position);
  instructions += Drop();
  return instructions;
}

Fragment FlowGraphBuilder::CheckAssignable(const AbstractType& dst_type,
                                           const String& dst_name,
                                           AssertAssignableInstr::Kind kind,
                                           TokenPosition token_pos) {
  Fragment instructions;
  if (!dst_type.IsTopTypeForSubtyping()) {
    LocalVariable* top_of_stack = MakeTemporary();
    instructions += LoadLocal(top_of_stack);
    instructions +=
        AssertAssignableLoadTypeArguments(token_pos, dst_type, dst_name, kind);
    instructions += Drop();
  }
  return instructions;
}

Fragment FlowGraphBuilder::AssertAssignableLoadTypeArguments(
    TokenPosition position,
    const AbstractType& dst_type,
    const String& dst_name,
    AssertAssignableInstr::Kind kind) {
  Fragment instructions;

  instructions += Constant(AbstractType::ZoneHandle(dst_type.ptr()));

  if (!dst_type.IsInstantiated(kCurrentClass)) {
    instructions += LoadInstantiatorTypeArguments();
  } else {
    instructions += NullConstant();
  }

  if (!dst_type.IsInstantiated(kFunctions)) {
    instructions += LoadFunctionTypeArguments();
  } else {
    instructions += NullConstant();
  }

  instructions += AssertAssignable(position, dst_name, kind);

  return instructions;
}

Fragment FlowGraphBuilder::AssertSubtype(TokenPosition position,
                                         const AbstractType& sub_type_value,
                                         const AbstractType& super_type_value,
                                         const String& dst_name_value) {
  Fragment instructions;
  instructions += LoadInstantiatorTypeArguments();
  instructions += LoadFunctionTypeArguments();
  instructions += Constant(AbstractType::ZoneHandle(Z, sub_type_value.ptr()));
  instructions += Constant(AbstractType::ZoneHandle(Z, super_type_value.ptr()));
  instructions += Constant(String::ZoneHandle(Z, dst_name_value.ptr()));
  instructions += AssertSubtype(position);
  return instructions;
}

Fragment FlowGraphBuilder::AssertSubtype(TokenPosition position) {
  Fragment instructions;

  Value* dst_name = Pop();
  Value* super_type = Pop();
  Value* sub_type = Pop();
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();

  AssertSubtypeInstr* instr = new (Z) AssertSubtypeInstr(
      InstructionSource(position), instantiator_type_args, function_type_args,
      sub_type, super_type, dst_name, GetNextDeoptId());
  instructions += Fragment(instr);

  return instructions;
}

void FlowGraphBuilder::BuildTypeArgumentTypeChecks(TypeChecksToBuild mode,
                                                   Fragment* implicit_checks) {
  const Function& dart_function = parsed_function_->function();

  const Function* forwarding_target = nullptr;
  if (parsed_function_->is_forwarding_stub()) {
    forwarding_target = parsed_function_->forwarding_stub_super_target();
    ASSERT(!forwarding_target->IsNull());
  }

  TypeParameters& type_parameters = TypeParameters::Handle(Z);
  if (dart_function.IsFactory()) {
    type_parameters = Class::Handle(Z, dart_function.Owner()).type_parameters();
  } else {
    type_parameters = dart_function.type_parameters();
  }
  const intptr_t num_type_params = type_parameters.Length();
  if (num_type_params == 0) return;
  if (forwarding_target != nullptr) {
    type_parameters = forwarding_target->type_parameters();
    ASSERT(type_parameters.Length() == num_type_params);
  }
  if (type_parameters.AllDynamicBounds()) {
    return;  // All bounds are dynamic.
  }
  TypeParameter& type_param = TypeParameter::Handle(Z);
  String& name = String::Handle(Z);
  AbstractType& bound = AbstractType::Handle(Z);
  Fragment check_bounds;
  for (intptr_t i = 0; i < num_type_params; ++i) {
    bound = type_parameters.BoundAt(i);
    if (bound.IsTopTypeForSubtyping()) {
      continue;
    }

    switch (mode) {
      case TypeChecksToBuild::kCheckAllTypeParameterBounds:
        break;
      case TypeChecksToBuild::kCheckCovariantTypeParameterBounds:
        if (!type_parameters.IsGenericCovariantImplAt(i)) {
          continue;
        }
        break;
      case TypeChecksToBuild::kCheckNonCovariantTypeParameterBounds:
        if (type_parameters.IsGenericCovariantImplAt(i)) {
          continue;
        }
        break;
    }

    name = type_parameters.NameAt(i);

    if (forwarding_target != nullptr) {
      type_param = forwarding_target->TypeParameterAt(i);
    } else if (dart_function.IsFactory()) {
      type_param = Class::Handle(Z, dart_function.Owner()).TypeParameterAt(i);
    } else {
      type_param = dart_function.TypeParameterAt(i);
    }
    ASSERT(type_param.IsFinalized());
    check_bounds +=
        AssertSubtype(TokenPosition::kNoSource, type_param, bound, name);
  }

  // Type arguments passed through partial instantiation are guaranteed to be
  // bounds-checked at the point of partial instantiation, so we don't need to
  // check them again at the call-site.
  if (dart_function.IsClosureFunction() && !check_bounds.is_empty() &&
      FLAG_eliminate_type_checks) {
    LocalVariable* closure = parsed_function_->ParameterVariable(0);
    *implicit_checks += TestDelayedTypeArgs(closure, /*present=*/{},
                                            /*absent=*/check_bounds);
  } else {
    *implicit_checks += check_bounds;
  }
}

void FlowGraphBuilder::BuildArgumentTypeChecks(
    Fragment* explicit_checks,
    Fragment* implicit_checks,
    Fragment* implicit_redefinitions) {
  const Function& dart_function = parsed_function_->function();

  const Function* forwarding_target = nullptr;
  if (parsed_function_->is_forwarding_stub()) {
    forwarding_target = parsed_function_->forwarding_stub_super_target();
    ASSERT(!forwarding_target->IsNull());
  }

  const intptr_t num_params = dart_function.NumParameters();
  for (intptr_t i = dart_function.NumImplicitParameters(); i < num_params;
       ++i) {
    LocalVariable* param = parsed_function_->ParameterVariable(i);
    const String& name = param->name();
    if (!param->needs_type_check()) {
      continue;
    }
    if (param->is_captured()) {
      param = parsed_function_->RawParameterVariable(i);
    }

    const AbstractType* target_type = &param->static_type();
    if (forwarding_target != nullptr) {
      // We add 1 to the parameter index to account for the receiver.
      target_type =
          &AbstractType::ZoneHandle(Z, forwarding_target->ParameterTypeAt(i));
    }

    if (target_type->IsTopTypeForSubtyping()) continue;

    const bool is_covariant = param->is_explicit_covariant_parameter();
    Fragment* checks = is_covariant ? explicit_checks : implicit_checks;

    *checks += LoadLocal(param);
    *checks += AssertAssignableLoadTypeArguments(
        param->token_pos(), *target_type, name,
        AssertAssignableInstr::kParameterCheck);
    *checks += StoreLocal(param);
    *checks += Drop();

    if (!is_covariant && implicit_redefinitions != nullptr && optimizing_) {
      // We generate slightly different code in optimized vs. un-optimized code,
      // which is ok since we don't allocate any deopt ids.
      AssertNoDeoptIdsAllocatedScope no_deopt_allocation(thread_);

      *implicit_redefinitions += LoadLocal(param);
      *implicit_redefinitions += RedefinitionWithType(*target_type);
      *implicit_redefinitions += StoreLocal(TokenPosition::kNoSource, param);
      *implicit_redefinitions += Drop();
    }
  }
}

BlockEntryInstr* FlowGraphBuilder::BuildPrologue(BlockEntryInstr* normal_entry,
                                                 PrologueInfo* prologue_info) {
  const bool compiling_for_osr = IsCompiledForOsr();

  kernel::PrologueBuilder prologue_builder(
      parsed_function_, last_used_block_id_, compiling_for_osr, IsInlining());
  BlockEntryInstr* instruction_cursor =
      prologue_builder.BuildPrologue(normal_entry, prologue_info);

  last_used_block_id_ = prologue_builder.last_used_block_id();

  return instruction_cursor;
}

ArrayPtr FlowGraphBuilder::GetOptionalParameterNames(const Function& function) {
  if (!function.HasOptionalNamedParameters()) {
    return Array::null();
  }

  const intptr_t num_fixed_params = function.num_fixed_parameters();
  const intptr_t num_opt_params = function.NumOptionalNamedParameters();
  const auto& names = Array::Handle(Z, Array::New(num_opt_params, Heap::kOld));
  auto& name = String::Handle(Z);
  for (intptr_t i = 0; i < num_opt_params; ++i) {
    name = function.ParameterNameAt(num_fixed_params + i);
    names.SetAt(i, name);
  }
  return names.ptr();
}

Fragment FlowGraphBuilder::PushExplicitParameters(
    const Function& function,
    const Function& target /* = Function::null_function()*/) {
  Fragment instructions;
  for (intptr_t i = function.NumImplicitParameters(),
                n = function.NumParameters();
       i < n; ++i) {
    Fragment push_param = LoadLocal(parsed_function_->ParameterVariable(i));
    if (!target.IsNull() && target.is_unboxed_parameter_at(i)) {
      Representation to;
      if (target.is_unboxed_integer_parameter_at(i)) {
        to = kUnboxedInt64;
      } else {
        ASSERT(target.is_unboxed_double_parameter_at(i));
        to = kUnboxedDouble;
      }
      const auto unbox = UnboxInstr::Create(to, Pop(), DeoptId::kNone,
                                            Instruction::kNotSpeculative);
      Push(unbox);
      push_param += Fragment(unbox);
    }
    instructions += push_param;
  }
  return instructions;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfMethodExtractor(
    const Function& method) {
  // A method extractor is the implicit getter for a method.
  const Function& function =
      Function::ZoneHandle(Z, method.extracted_method_closure());

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue(method.token_pos());
  body += BuildImplicitClosureCreation(function);
  body += Return(TokenPosition::kNoSource);

  // There is no prologue code for a method extractor.
  PrologueInfo prologue_info(-1, -1);
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfNoSuchMethodDispatcher(
    const Function& function) {
  // This function is specialized for a receiver class, a method name, and
  // the arguments descriptor at a call site.
  const ArgumentsDescriptor descriptor(saved_args_desc_array());

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment body(instruction_cursor);
  body += CheckStackOverflowInPrologue(function.token_pos());

  // The receiver is the first argument to noSuchMethod, and it is the first
  // argument passed to the dispatcher function.
  body += LoadLocal(parsed_function_->ParameterVariable(0));

  // The second argument to noSuchMethod is an invocation mirror.  Push the
  // arguments for allocating the invocation mirror.  First, the name.
  body += Constant(String::ZoneHandle(Z, function.name()));

  // Second, the arguments descriptor.
  body += Constant(saved_args_desc_array());

  // Third, an array containing the original arguments.  Create it and fill
  // it in.
  const intptr_t receiver_index = descriptor.TypeArgsLen() > 0 ? 1 : 0;
  body += Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
  body += IntConstant(receiver_index + descriptor.Size());
  body += CreateArray();
  LocalVariable* array = MakeTemporary();
  if (receiver_index > 0) {
    LocalVariable* type_args = parsed_function_->function_type_arguments();
    ASSERT(type_args != nullptr);
    body += LoadLocal(array);
    body += IntConstant(0);
    body += LoadLocal(type_args);
    body += StoreIndexed(kArrayCid);
  }
  for (intptr_t i = 0; i < descriptor.PositionalCount(); ++i) {
    body += LoadLocal(array);
    body += IntConstant(receiver_index + i);
    body += LoadLocal(parsed_function_->ParameterVariable(i));
    body += StoreIndexed(kArrayCid);
  }
  String& name = String::Handle(Z);
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    const intptr_t parameter_index = descriptor.PositionAt(i);
    name = descriptor.NameAt(i);
    name = Symbols::New(H.thread(), name);
    body += LoadLocal(array);
    body += IntConstant(receiver_index + parameter_index);
    body += LoadLocal(parsed_function_->ParameterVariable(parameter_index));
    body += StoreIndexed(kArrayCid);
  }

  // Fourth, false indicating this is not a super NoSuchMethod.
  body += Constant(Bool::False());

  const Class& mirror_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const auto& error = mirror_class.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(
             Library::PrivateCoreLibName(Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  body += StaticCall(TokenPosition::kMinSource, allocation_function,
                     /* argument_count = */ 4, ICData::kStatic);

  const int kTypeArgsLen = 0;
  ArgumentsDescriptor two_arguments(
      Array::Handle(Z, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, 2)));
  Function& no_such_method =
      Function::ZoneHandle(Z, Resolver::ResolveDynamicForReceiverClass(
                                  Class::Handle(Z, function.Owner()),
                                  Symbols::NoSuchMethod(), two_arguments));
  if (no_such_method.IsNull()) {
    // If noSuchMethod is not found on the receiver class, call
    // Object.noSuchMethod.
    no_such_method = Resolver::ResolveDynamicForReceiverClass(
        Class::Handle(Z, IG->object_store()->object_class()),
        Symbols::NoSuchMethod(), two_arguments);
  }
  body += StaticCall(TokenPosition::kMinSource, no_such_method,
                     /* argument_count = */ 2, ICData::kNSMDispatch);
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfRecordFieldGetter(
    const Function& function) {
  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  JoinEntryInstr* nsm = BuildJoinEntry();
  JoinEntryInstr* done = BuildJoinEntry();

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue(function.token_pos());

  String& name = String::ZoneHandle(Z, function.name());
  ASSERT(Field::IsGetterName(name));
  name = Field::NameFromGetter(name);

  // Get an array of field names.
  const Class& cls = Class::Handle(Z, IG->class_table()->At(kRecordCid));
  const auto& error = cls.EnsureIsFinalized(thread_);
  ASSERT(error == Error::null());
  const Function& get_field_names_function = Function::ZoneHandle(
      Z, cls.LookupFunctionAllowPrivate(Symbols::Get_fieldNames()));
  ASSERT(!get_field_names_function.IsNull());
  body += LoadLocal(parsed_function_->receiver_var());
  body += StaticCall(TokenPosition::kNoSource, get_field_names_function, 1,
                     ICData::kNoRebind);
  LocalVariable* field_names = MakeTemporary("field_names");

  body += LoadLocal(field_names);
  body += LoadNativeField(Slot::Array_length());
  LocalVariable* num_named = MakeTemporary("num_named");

  // num_positional = num_fields - field_names.length
  body += LoadLocal(parsed_function_->receiver_var());
  body += LoadNativeField(Slot::Record_shape());
  body += IntConstant(compiler::target::RecordShape::kNumFieldsMask);
  body += SmiBinaryOp(Token::kBIT_AND);
  body += LoadLocal(num_named);
  body += SmiBinaryOp(Token::kSUB);
  LocalVariable* num_positional = MakeTemporary("num_positional");

  const intptr_t field_index =
      Record::GetPositionalFieldIndexFromFieldName(name);
  if (field_index >= 0) {
    // Get positional record field by index.
    body += IntConstant(field_index);
    body += LoadLocal(num_positional);
    body += SmiRelationalOp(Token::kLT);
    TargetEntryInstr* valid_index;
    TargetEntryInstr* invalid_index;
    body += BranchIfTrue(&valid_index, &invalid_index);

    body.current = valid_index;
    body += LoadLocal(parsed_function_->receiver_var());
    body += LoadNativeField(Slot::GetRecordFieldSlot(
        thread_, compiler::target::Record::field_offset(field_index)));

    body += StoreLocal(TokenPosition::kNoSource,
                       parsed_function_->expression_temp_var());
    body += Drop();
    body += Goto(done);

    body.current = invalid_index;
  }

  // Search field among named fields.
  body += IntConstant(0);
  body += LoadLocal(num_named);
  body += SmiRelationalOp(Token::kLT);
  TargetEntryInstr* has_named_fields;
  TargetEntryInstr* no_named_fields;
  body += BranchIfTrue(&has_named_fields, &no_named_fields);

  Fragment(no_named_fields) + Goto(nsm);
  body.current = has_named_fields;

  LocalVariable* index = parsed_function_->expression_temp_var();
  body += IntConstant(0);
  body += StoreLocal(TokenPosition::kNoSource, index);
  body += Drop();

  JoinEntryInstr* loop = BuildJoinEntry();
  body += Goto(loop);
  body.current = loop;

  body += LoadLocal(field_names);
  body += LoadLocal(index);
  body += LoadIndexed(kArrayCid,
                      /*index_scale*/ compiler::target::kCompressedWordSize);
  body += Constant(name);
  TargetEntryInstr* found;
  TargetEntryInstr* continue_search;
  body += BranchIfEqual(&found, &continue_search);

  body.current = continue_search;
  body += LoadLocal(index);
  body += IntConstant(1);
  body += SmiBinaryOp(Token::kADD);
  body += StoreLocal(TokenPosition::kNoSource, index);
  body += Drop();

  body += LoadLocal(index);
  body += LoadLocal(num_named);
  body += SmiRelationalOp(Token::kLT);
  TargetEntryInstr* has_more_fields;
  TargetEntryInstr* no_more_fields;
  body += BranchIfTrue(&has_more_fields, &no_more_fields);

  Fragment(has_more_fields) + Goto(loop);
  Fragment(no_more_fields) + Goto(nsm);

  body.current = found;

  body += LoadLocal(parsed_function_->receiver_var());

  body += LoadLocal(num_positional);
  body += LoadLocal(index);
  body += SmiBinaryOp(Token::kADD);

  body += LoadIndexed(kRecordCid,
                      /*index_scale*/ compiler::target::kCompressedWordSize);

  body += StoreLocal(TokenPosition::kNoSource,
                     parsed_function_->expression_temp_var());
  body += Drop();
  body += Goto(done);

  body.current = done;

  body += LoadLocal(parsed_function_->expression_temp_var());
  body += DropTempsPreserveTop(3);  // field_names, num_named, num_positional
  body += Return(TokenPosition::kNoSource);

  Fragment throw_nsm(nsm);
  throw_nsm += LoadLocal(parsed_function_->receiver_var());
  throw_nsm += ThrowNoSuchMethodError(TokenPosition::kNoSource, function,
                                      /*incompatible_arguments=*/false,
                                      /*receiver_pushed=*/true);
  throw_nsm += ThrowException(TokenPosition::kNoSource);  // Close graph.

  // There is no prologue code for a record field getter.
  PrologueInfo prologue_info(-1, -1);
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

// Information used by the various dynamic closure call fragment builders.
struct FlowGraphBuilder::ClosureCallInfo {
  ClosureCallInfo(LocalVariable* closure,
                  JoinEntryInstr* throw_no_such_method,
                  const Array& arguments_descriptor_array,
                  ParsedFunction::DynamicClosureCallVars* const vars)
      : closure(ASSERT_NOTNULL(closure)),
        throw_no_such_method(ASSERT_NOTNULL(throw_no_such_method)),
        descriptor(arguments_descriptor_array),
        vars(ASSERT_NOTNULL(vars)) {}

  LocalVariable* const closure;
  JoinEntryInstr* const throw_no_such_method;
  const ArgumentsDescriptor descriptor;
  ParsedFunction::DynamicClosureCallVars* const vars;

  // Set up by BuildClosureCallDefaultTypeHandling() when needed. These values
  // are read-only, so they don't need real local variables and are created
  // using MakeTemporary().
  LocalVariable* signature = nullptr;
  LocalVariable* num_fixed_params = nullptr;
  LocalVariable* num_opt_params = nullptr;
  LocalVariable* num_max_params = nullptr;
  LocalVariable* has_named_params = nullptr;
  LocalVariable* named_parameter_names = nullptr;
  LocalVariable* parameter_types = nullptr;
  LocalVariable* type_parameters = nullptr;
  LocalVariable* num_type_parameters = nullptr;
  LocalVariable* type_parameter_flags = nullptr;
  LocalVariable* instantiator_type_args = nullptr;
  LocalVariable* parent_function_type_args = nullptr;
  LocalVariable* num_parent_type_args = nullptr;
};

Fragment FlowGraphBuilder::TestClosureFunctionGeneric(
    const ClosureCallInfo& info,
    Fragment generic,
    Fragment not_generic) {
  JoinEntryInstr* after_branch = BuildJoinEntry();

  Fragment check;
  check += LoadLocal(info.type_parameters);
  TargetEntryInstr* is_not_generic;
  TargetEntryInstr* is_generic;
  check += BranchIfNull(&is_not_generic, &is_generic);

  generic.Prepend(is_generic);
  generic += Goto(after_branch);

  not_generic.Prepend(is_not_generic);
  not_generic += Goto(after_branch);

  return Fragment(check.entry, after_branch);
}

Fragment FlowGraphBuilder::TestClosureFunctionNamedParameterRequired(
    const ClosureCallInfo& info,
    Fragment set,
    Fragment not_set) {
  // Required named arguments only exist if null_safety is enabled.
  if (!IG->use_strict_null_safety_checks()) return not_set;

  Fragment check_required;
  // We calculate the index to dereference in the parameter names array.
  check_required += LoadLocal(info.vars->current_param_index);
  check_required +=
      IntConstant(compiler::target::kNumParameterFlagsPerElementLog2);
  check_required += SmiBinaryOp(Token::kSHR);
  check_required += LoadLocal(info.num_opt_params);
  check_required += SmiBinaryOp(Token::kADD);
  LocalVariable* flags_index = MakeTemporary("flags_index");  // Read-only.

  // One read-only stack value (flag_index) that must be dropped
  // after we rejoin at after_check.
  JoinEntryInstr* after_check = BuildJoinEntry();

  // Now we check to see if the flags index is within the bounds of the
  // parameters names array. If not, it cannot be required.
  check_required += LoadLocal(flags_index);
  check_required += LoadLocal(info.named_parameter_names);
  check_required += LoadNativeField(Slot::Array_length());
  check_required += SmiRelationalOp(Token::kLT);
  TargetEntryInstr* valid_index;
  TargetEntryInstr* invalid_index;
  check_required += BranchIfTrue(&valid_index, &invalid_index);

  JoinEntryInstr* join_not_set = BuildJoinEntry();

  Fragment(invalid_index) + Goto(join_not_set);

  // Otherwise, we need to retrieve the value. We're guaranteed the Smis in
  // the flag slots are non-null, so after loading we can immediate check
  // the required flag bit for the given named parameter.
  check_required.current = valid_index;
  check_required += LoadLocal(info.named_parameter_names);
  check_required += LoadLocal(flags_index);
  check_required += LoadIndexed(
      kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  check_required += LoadLocal(info.vars->current_param_index);
  check_required +=
      IntConstant(compiler::target::kNumParameterFlagsPerElement - 1);
  check_required += SmiBinaryOp(Token::kBIT_AND);
  // If the below changes, we'll need to multiply by the number of parameter
  // flags before shifting.
  static_assert(compiler::target::kNumParameterFlags == 1,
                "IL builder assumes only one flag bit per parameter");
  check_required += SmiBinaryOp(Token::kSHR);
  check_required +=
      IntConstant(1 << compiler::target::kRequiredNamedParameterFlag);
  check_required += SmiBinaryOp(Token::kBIT_AND);
  check_required += IntConstant(0);
  TargetEntryInstr* is_not_set;
  TargetEntryInstr* is_set;
  check_required += BranchIfEqual(&is_not_set, &is_set);

  Fragment(is_not_set) + Goto(join_not_set);

  set.Prepend(is_set);
  set += Goto(after_check);

  not_set.Prepend(join_not_set);
  not_set += Goto(after_check);

  // After rejoining, drop the introduced temporaries.
  check_required.current = after_check;
  check_required += DropTemporary(&flags_index);
  return check_required;
}

Fragment FlowGraphBuilder::BuildClosureCallDefaultTypeHandling(
    const ClosureCallInfo& info) {
  if (info.descriptor.TypeArgsLen() > 0) {
    ASSERT(parsed_function_->function_type_arguments() != nullptr);
    // A TAV was provided, so we don't need default type argument handling
    // and can just take the arguments we were given.
    Fragment store_provided;
    store_provided += LoadLocal(parsed_function_->function_type_arguments());
    store_provided += StoreLocal(info.vars->function_type_args);
    store_provided += Drop();
    return store_provided;
  }

  // Load the defaults, instantiating or replacing them with the other type
  // arguments as appropriate.
  Fragment store_default;
  store_default += LoadLocal(info.closure);
  store_default += LoadNativeField(Slot::Closure_function());
  store_default += LoadNativeField(Slot::Function_data());
  LocalVariable* closure_data = MakeTemporary("closure_data");

  store_default += LoadLocal(closure_data);
  store_default += BuildExtractUnboxedSlotBitFieldIntoSmi<
      ClosureData::PackedDefaultTypeArgumentsKind>(
      Slot::ClosureData_packed_fields());
  LocalVariable* default_tav_kind = MakeTemporary("default_tav_kind");

  // Two locals to drop after join, closure_data and default_tav_kind.
  JoinEntryInstr* done = BuildJoinEntry();

  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr* is_instantiated;
  TargetEntryInstr* is_not_instantiated;
  store_default += IntConstant(static_cast<intptr_t>(
      ClosureData::DefaultTypeArgumentsKind::kIsInstantiated));
  store_default += BranchIfEqual(&is_instantiated, &is_not_instantiated);
  store_default.current = is_not_instantiated;  // Check next case.
  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr* needs_instantiation;
  TargetEntryInstr* can_share;
  store_default += IntConstant(static_cast<intptr_t>(
      ClosureData::DefaultTypeArgumentsKind::kNeedsInstantiation));
  store_default += BranchIfEqual(&needs_instantiation, &can_share);
  store_default.current = can_share;  // Check next case.
  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr* can_share_instantiator;
  TargetEntryInstr* can_share_function;
  store_default += IntConstant(static_cast<intptr_t>(
      ClosureData::DefaultTypeArgumentsKind::kSharesInstantiatorTypeArguments));
  store_default += BranchIfEqual(&can_share_instantiator, &can_share_function);

  Fragment instantiated(is_instantiated);
  instantiated += LoadLocal(info.type_parameters);
  instantiated += LoadNativeField(Slot::TypeParameters_defaults());
  instantiated += StoreLocal(info.vars->function_type_args);
  instantiated += Drop();
  instantiated += Goto(done);

  Fragment do_instantiation(needs_instantiation);
  // Load the instantiator type arguments.
  do_instantiation += LoadLocal(info.instantiator_type_args);
  // Load the parent function type arguments. (No local function type arguments
  // can be used within the defaults).
  do_instantiation += LoadLocal(info.parent_function_type_args);
  // Load the default type arguments to instantiate.
  do_instantiation += LoadLocal(info.type_parameters);
  do_instantiation += LoadNativeField(Slot::TypeParameters_defaults());
  do_instantiation += InstantiateDynamicTypeArguments();
  do_instantiation += StoreLocal(info.vars->function_type_args);
  do_instantiation += Drop();
  do_instantiation += Goto(done);

  Fragment share_instantiator(can_share_instantiator);
  share_instantiator += LoadLocal(info.instantiator_type_args);
  share_instantiator += StoreLocal(info.vars->function_type_args);
  share_instantiator += Drop();
  share_instantiator += Goto(done);

  Fragment share_function(can_share_function);
  // Since the defaults won't have local type parameters, these must all be
  // from the parent function type arguments, so we can just use it.
  share_function += LoadLocal(info.parent_function_type_args);
  share_function += StoreLocal(info.vars->function_type_args);
  share_function += Drop();
  share_function += Goto(done);

  store_default.current = done;  // Return here after branching.
  store_default += DropTemporary(&default_tav_kind);
  store_default += DropTemporary(&closure_data);

  Fragment store_delayed;
  store_delayed += LoadLocal(info.closure);
  store_delayed += LoadNativeField(Slot::Closure_delayed_type_arguments());
  store_delayed += StoreLocal(info.vars->function_type_args);
  store_delayed += Drop();

  // Use the delayed type args if present, else the default ones.
  return TestDelayedTypeArgs(info.closure, store_delayed, store_default);
}

Fragment FlowGraphBuilder::BuildClosureCallNamedArgumentsCheck(
    const ClosureCallInfo& info) {
  // When no named arguments are provided, we just need to check for possible
  // required named arguments.
  if (info.descriptor.NamedCount() == 0) {
    // No work to do if there are no possible required named parameters.
    if (!IG->use_strict_null_safety_checks()) {
      return Fragment();
    }
    // If the below changes, we can no longer assume that flag slots existing
    // means there are required parameters.
    static_assert(compiler::target::kNumParameterFlags == 1,
                  "IL builder assumes only one flag bit per parameter");
    // No named args were provided, so check for any required named params.
    // Here, we assume that the only parameter flag saved is the required bit
    // for named parameters. If this changes, we'll need to check each flag
    // entry appropriately for any set required bits.
    Fragment has_any;
    has_any += LoadLocal(info.num_opt_params);
    has_any += LoadLocal(info.named_parameter_names);
    has_any += LoadNativeField(Slot::Array_length());
    TargetEntryInstr* no_required;
    TargetEntryInstr* has_required;
    has_any += BranchIfEqual(&no_required, &has_required);

    Fragment(has_required) + Goto(info.throw_no_such_method);

    return Fragment(has_any.entry, no_required);
  }

  // Otherwise, we need to loop through the parameter names to check the names
  // of named arguments for validity (and possibly missing required ones).
  Fragment check_names;
  check_names += LoadLocal(info.vars->current_param_index);
  LocalVariable* old_index = MakeTemporary("old_index");  // Read-only.
  check_names += LoadLocal(info.vars->current_num_processed);
  LocalVariable* old_processed = MakeTemporary("old_processed");  // Read-only.

  // Two local stack values (old_index, old_processed) to drop after rejoining
  // at done.
  JoinEntryInstr* loop = BuildJoinEntry();
  JoinEntryInstr* done = BuildJoinEntry();

  check_names += IntConstant(0);
  check_names += StoreLocal(info.vars->current_num_processed);
  check_names += Drop();
  check_names += IntConstant(0);
  check_names += StoreLocal(info.vars->current_param_index);
  check_names += Drop();
  check_names += Goto(loop);

  Fragment loop_check(loop);
  loop_check += LoadLocal(info.vars->current_param_index);
  loop_check += LoadLocal(info.num_opt_params);
  loop_check += SmiRelationalOp(Token::kLT);
  TargetEntryInstr* no_more;
  TargetEntryInstr* more;
  loop_check += BranchIfTrue(&more, &no_more);

  Fragment(no_more) + Goto(done);

  Fragment loop_body(more);
  // First load the name we need to check against.
  loop_body += LoadLocal(info.named_parameter_names);
  loop_body += LoadLocal(info.vars->current_param_index);
  loop_body += LoadIndexed(
      kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  LocalVariable* param_name = MakeTemporary("param_name");  // Read only.

  // One additional local value on the stack within the loop body (param_name)
  // that should be dropped after rejoining at loop_incr.
  JoinEntryInstr* loop_incr = BuildJoinEntry();

  // Now iterate over the ArgumentsDescriptor names and check for a match.
  for (intptr_t i = 0; i < info.descriptor.NamedCount(); i++) {
    const auto& name = String::ZoneHandle(Z, info.descriptor.NameAt(i));
    loop_body += Constant(name);
    loop_body += LoadLocal(param_name);
    TargetEntryInstr* match;
    TargetEntryInstr* mismatch;
    loop_body += BranchIfEqual(&match, &mismatch);
    loop_body.current = mismatch;

    // We have a match, so go to the next name after storing the corresponding
    // parameter index on the stack and incrementing the number of matched
    // arguments. (No need to check the required bit for provided parameters.)
    Fragment matched(match);
    matched += LoadLocal(info.vars->current_param_index);
    matched += LoadLocal(info.num_fixed_params);
    matched += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
    matched += StoreLocal(info.vars->named_argument_parameter_indices.At(i));
    matched += Drop();
    matched += LoadLocal(info.vars->current_num_processed);
    matched += IntConstant(1);
    matched += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
    matched += StoreLocal(info.vars->current_num_processed);
    matched += Drop();
    matched += Goto(loop_incr);
  }

  // None of the names in the arguments descriptor matched, so check if this
  // is a required parameter.
  loop_body += TestClosureFunctionNamedParameterRequired(
      info,
      /*set=*/Goto(info.throw_no_such_method),
      /*not_set=*/{});

  loop_body += Goto(loop_incr);

  Fragment incr_index(loop_incr);
  incr_index += DropTemporary(&param_name);
  incr_index += LoadLocal(info.vars->current_param_index);
  incr_index += IntConstant(1);
  incr_index += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
  incr_index += StoreLocal(info.vars->current_param_index);
  incr_index += Drop();
  incr_index += Goto(loop);

  Fragment check_processed(done);
  check_processed += LoadLocal(info.vars->current_num_processed);
  check_processed += IntConstant(info.descriptor.NamedCount());
  TargetEntryInstr* all_processed;
  TargetEntryInstr* bad_name;
  check_processed += BranchIfEqual(&all_processed, &bad_name);

  // Didn't find a matching parameter name for at least one argument name.
  Fragment(bad_name) + Goto(info.throw_no_such_method);

  // Drop the temporaries at the end of the fragment.
  check_names.current = all_processed;
  check_names += LoadLocal(old_processed);
  check_names += StoreLocal(info.vars->current_num_processed);
  check_names += Drop();
  check_names += DropTemporary(&old_processed);
  check_names += LoadLocal(old_index);
  check_names += StoreLocal(info.vars->current_param_index);
  check_names += Drop();
  check_names += DropTemporary(&old_index);
  return check_names;
}

Fragment FlowGraphBuilder::BuildClosureCallArgumentsValidCheck(
    const ClosureCallInfo& info) {
  Fragment check_entry;
  // We only need to check the length of any explicitly provided type arguments.
  if (info.descriptor.TypeArgsLen() > 0) {
    Fragment check_type_args_length;
    check_type_args_length += LoadLocal(info.type_parameters);
    TargetEntryInstr* null;
    TargetEntryInstr* not_null;
    check_type_args_length += BranchIfNull(&null, &not_null);
    check_type_args_length.current = not_null;  // Continue in non-error case.
    check_type_args_length += LoadLocal(info.signature);
    check_type_args_length += BuildExtractUnboxedSlotBitFieldIntoSmi<
        UntaggedFunctionType::PackedNumTypeParameters>(
        Slot::FunctionType_packed_type_parameter_counts());
    check_type_args_length += IntConstant(info.descriptor.TypeArgsLen());
    TargetEntryInstr* equal;
    TargetEntryInstr* not_equal;
    check_type_args_length += BranchIfEqual(&equal, &not_equal);
    check_type_args_length.current = equal;  // Continue in non-error case.

    // The function is not generic.
    Fragment(null) + Goto(info.throw_no_such_method);

    // An incorrect number of type arguments were passed.
    Fragment(not_equal) + Goto(info.throw_no_such_method);

    // Type arguments should not be provided if there are delayed type
    // arguments, as then the closure itself is not generic.
    check_entry += TestDelayedTypeArgs(
        info.closure, /*present=*/Goto(info.throw_no_such_method),
        /*absent=*/check_type_args_length);
  }

  check_entry += LoadLocal(info.has_named_params);
  TargetEntryInstr* has_named;
  TargetEntryInstr* has_positional;
  check_entry += BranchIfTrue(&has_named, &has_positional);
  JoinEntryInstr* join_after_optional = BuildJoinEntry();
  check_entry.current = join_after_optional;

  if (info.descriptor.NamedCount() > 0) {
    // No reason to continue checking, as this function doesn't take named args.
    Fragment(has_positional) + Goto(info.throw_no_such_method);
  } else {
    Fragment check_pos(has_positional);
    check_pos += LoadLocal(info.num_fixed_params);
    check_pos += IntConstant(info.descriptor.PositionalCount());
    check_pos += SmiRelationalOp(Token::kLTE);
    TargetEntryInstr* enough;
    TargetEntryInstr* too_few;
    check_pos += BranchIfTrue(&enough, &too_few);
    check_pos.current = enough;

    Fragment(too_few) + Goto(info.throw_no_such_method);

    check_pos += IntConstant(info.descriptor.PositionalCount());
    check_pos += LoadLocal(info.num_max_params);
    check_pos += SmiRelationalOp(Token::kLTE);
    TargetEntryInstr* valid;
    TargetEntryInstr* too_many;
    check_pos += BranchIfTrue(&valid, &too_many);
    check_pos.current = valid;

    Fragment(too_many) + Goto(info.throw_no_such_method);

    check_pos += Goto(join_after_optional);
  }

  Fragment check_named(has_named);

  TargetEntryInstr* same;
  TargetEntryInstr* different;
  check_named += LoadLocal(info.num_fixed_params);
  check_named += IntConstant(info.descriptor.PositionalCount());
  check_named += BranchIfEqual(&same, &different);
  check_named.current = same;

  Fragment(different) + Goto(info.throw_no_such_method);

  if (info.descriptor.NamedCount() > 0) {
    check_named += IntConstant(info.descriptor.NamedCount());
    check_named += LoadLocal(info.num_opt_params);
    check_named += SmiRelationalOp(Token::kLTE);
    TargetEntryInstr* valid;
    TargetEntryInstr* too_many;
    check_named += BranchIfTrue(&valid, &too_many);
    check_named.current = valid;

    Fragment(too_many) + Goto(info.throw_no_such_method);
  }

  // Check the names for optional arguments. If applicable, also check that all
  // required named parameters are provided.
  check_named += BuildClosureCallNamedArgumentsCheck(info);
  check_named += Goto(join_after_optional);

  check_entry.current = join_after_optional;
  return check_entry;
}

Fragment FlowGraphBuilder::BuildClosureCallTypeArgumentsTypeCheck(
    const ClosureCallInfo& info) {
  JoinEntryInstr* done = BuildJoinEntry();
  JoinEntryInstr* loop = BuildJoinEntry();

  // We assume that the value stored in :t_type_parameters is not null (i.e.,
  // the function stored in :t_function is generic).
  Fragment loop_init;

  // A null bounds vector represents a vector of dynamic and no check is needed.
  loop_init += LoadLocal(info.type_parameters);
  loop_init += LoadNativeField(Slot::TypeParameters_bounds());
  TargetEntryInstr* null_bounds;
  TargetEntryInstr* non_null_bounds;
  loop_init += BranchIfNull(&null_bounds, &non_null_bounds);

  Fragment(null_bounds) + Goto(done);

  loop_init.current = non_null_bounds;
  // Loop over the type parameters array.
  loop_init += IntConstant(0);
  loop_init += StoreLocal(info.vars->current_param_index);
  loop_init += Drop();
  loop_init += Goto(loop);

  Fragment loop_check(loop);
  loop_check += LoadLocal(info.vars->current_param_index);
  loop_check += LoadLocal(info.num_type_parameters);
  loop_check += SmiRelationalOp(Token::kLT);
  TargetEntryInstr* more;
  TargetEntryInstr* no_more;
  loop_check += BranchIfTrue(&more, &no_more);

  Fragment(no_more) + Goto(done);

  Fragment loop_test_flag(more);
  JoinEntryInstr* next = BuildJoinEntry();
  JoinEntryInstr* check = BuildJoinEntry();
  loop_test_flag += LoadLocal(info.type_parameter_flags);
  TargetEntryInstr* null_flags;
  TargetEntryInstr* non_null_flags;
  loop_test_flag += BranchIfNull(&null_flags, &non_null_flags);

  Fragment(null_flags) + Goto(check);  // Check type if null (non-covariant).

  loop_test_flag.current = non_null_flags;  // Test flags if not null.
  loop_test_flag += LoadLocal(info.type_parameter_flags);
  loop_test_flag += LoadLocal(info.vars->current_param_index);
  loop_test_flag += IntConstant(TypeParameters::kFlagsPerSmiShift);
  loop_test_flag += SmiBinaryOp(Token::kSHR);
  loop_test_flag += LoadIndexed(
      kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  loop_test_flag += LoadLocal(info.vars->current_param_index);
  loop_test_flag += IntConstant(TypeParameters::kFlagsPerSmiMask);
  loop_test_flag += SmiBinaryOp(Token::kBIT_AND);
  loop_test_flag += SmiBinaryOp(Token::kSHR);
  loop_test_flag += IntConstant(1);
  loop_test_flag += SmiBinaryOp(Token::kBIT_AND);
  loop_test_flag += IntConstant(0);
  TargetEntryInstr* is_noncovariant;
  TargetEntryInstr* is_covariant;
  loop_test_flag += BranchIfEqual(&is_noncovariant, &is_covariant);

  Fragment(is_covariant) + Goto(next);      // Continue if covariant.
  Fragment(is_noncovariant) + Goto(check);  // Check type if non-covariant.

  Fragment loop_prep_type_param(check);
  JoinEntryInstr* dynamic_type_param = BuildJoinEntry();
  JoinEntryInstr* call = BuildJoinEntry();

  // Load type argument already stored in function_type_args if non null.
  loop_prep_type_param += LoadLocal(info.vars->function_type_args);
  TargetEntryInstr* null_ftav;
  TargetEntryInstr* non_null_ftav;
  loop_prep_type_param += BranchIfNull(&null_ftav, &non_null_ftav);

  Fragment(null_ftav) + Goto(dynamic_type_param);

  loop_prep_type_param.current = non_null_ftav;
  loop_prep_type_param += LoadLocal(info.vars->function_type_args);
  loop_prep_type_param += LoadLocal(info.vars->current_param_index);
  loop_prep_type_param += LoadLocal(info.num_parent_type_args);
  loop_prep_type_param += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
  loop_prep_type_param += LoadIndexed(
      kTypeArgumentsCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  loop_prep_type_param += StoreLocal(info.vars->current_type_param);
  loop_prep_type_param += Drop();
  loop_prep_type_param += Goto(call);

  Fragment loop_dynamic_type_param(dynamic_type_param);
  // If function_type_args is null, the instantiated type param is dynamic.
  loop_dynamic_type_param += Constant(Type::ZoneHandle(Type::DynamicType()));
  loop_dynamic_type_param += StoreLocal(info.vars->current_type_param);
  loop_dynamic_type_param += Drop();
  loop_dynamic_type_param += Goto(call);

  Fragment loop_call_check(call);
  // Load instantiators.
  loop_call_check += LoadLocal(info.instantiator_type_args);
  loop_call_check += LoadLocal(info.vars->function_type_args);
  // Load instantiated type parameter.
  loop_call_check += LoadLocal(info.vars->current_type_param);
  // Load bound from type parameters.
  loop_call_check += LoadLocal(info.type_parameters);
  loop_call_check += LoadNativeField(Slot::TypeParameters_bounds());
  loop_call_check += LoadLocal(info.vars->current_param_index);
  loop_call_check += LoadIndexed(
      kTypeArgumentsCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  // Load (canonicalized) name of type parameter in signature.
  loop_call_check += LoadLocal(info.type_parameters);
  loop_call_check += LoadNativeField(Slot::TypeParameters_names());
  loop_call_check += LoadLocal(info.vars->current_param_index);
  loop_call_check += LoadIndexed(
      kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  // Assert that the passed-in type argument is consistent with the bound of
  // the corresponding type parameter.
  loop_call_check += AssertSubtype(TokenPosition::kNoSource);
  loop_call_check += Goto(next);

  Fragment loop_incr(next);
  loop_incr += LoadLocal(info.vars->current_param_index);
  loop_incr += IntConstant(1);
  loop_incr += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
  loop_incr += StoreLocal(info.vars->current_param_index);
  loop_incr += Drop();
  loop_incr += Goto(loop);

  return Fragment(loop_init.entry, done);
}

Fragment FlowGraphBuilder::BuildClosureCallArgumentTypeCheck(
    const ClosureCallInfo& info,
    LocalVariable* param_index,
    intptr_t arg_index,
    const String& arg_name) {
  Fragment instructions;

  // Load value.
  instructions += LoadLocal(parsed_function_->ParameterVariable(arg_index));
  // Load destination type.
  instructions += LoadLocal(info.parameter_types);
  instructions += LoadLocal(param_index);
  instructions += LoadIndexed(
      kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
  // Load instantiator type arguments.
  instructions += LoadLocal(info.instantiator_type_args);
  // Load the full set of function type arguments.
  instructions += LoadLocal(info.vars->function_type_args);
  // Check that the value has the right type.
  instructions += AssertAssignable(TokenPosition::kNoSource, arg_name,
                                   AssertAssignableInstr::kParameterCheck);
  // Make sure to store the result to keep data dependencies accurate.
  instructions += StoreLocal(parsed_function_->ParameterVariable(arg_index));
  instructions += Drop();

  return instructions;
}

Fragment FlowGraphBuilder::BuildClosureCallArgumentTypeChecks(
    const ClosureCallInfo& info) {
  Fragment instructions;

  // Only check explicit arguments (i.e., skip the receiver), as the receiver
  // is always assignable to its type (stored as dynamic).
  for (intptr_t i = 1; i < info.descriptor.PositionalCount(); i++) {
    instructions += IntConstant(i);
    LocalVariable* param_index = MakeTemporary("param_index");
    // We don't have a compile-time name, so this symbol signals the runtime
    // that it should recreate the type check using info from the stack.
    instructions += BuildClosureCallArgumentTypeCheck(
        info, param_index, i, Symbols::dynamic_assert_assignable_stc_check());
    instructions += DropTemporary(&param_index);
  }

  for (intptr_t i = 0; i < info.descriptor.NamedCount(); i++) {
    const intptr_t arg_index = info.descriptor.PositionAt(i);
    auto const param_index = info.vars->named_argument_parameter_indices.At(i);
    // We have a compile-time name available, but we still want the runtime to
    // detect that the generated AssertAssignable instruction is dynamic.
    instructions += BuildClosureCallArgumentTypeCheck(
        info, param_index, arg_index,
        Symbols::dynamic_assert_assignable_stc_check());
  }

  return instructions;
}

Fragment FlowGraphBuilder::BuildDynamicClosureCallChecks(
    LocalVariable* closure) {
  ClosureCallInfo info(closure, BuildThrowNoSuchMethod(),
                       saved_args_desc_array(),
                       parsed_function_->dynamic_closure_call_vars());

  Fragment body;
  body += LoadLocal(info.closure);
  body += LoadNativeField(Slot::Closure_function());
  body += LoadNativeField(Slot::Function_signature());
  info.signature = MakeTemporary("signature");

  body += LoadLocal(info.signature);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      FunctionType::PackedNumFixedParameters>(
      Slot::FunctionType_packed_parameter_counts());
  info.num_fixed_params = MakeTemporary("num_fixed_params");

  body += LoadLocal(info.signature);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      FunctionType::PackedNumOptionalParameters>(
      Slot::FunctionType_packed_parameter_counts());
  info.num_opt_params = MakeTemporary("num_opt_params");

  body += LoadLocal(info.num_fixed_params);
  body += LoadLocal(info.num_opt_params);
  body += SmiBinaryOp(Token::kADD);
  info.num_max_params = MakeTemporary("num_max_params");

  body += LoadLocal(info.signature);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      FunctionType::PackedHasNamedOptionalParameters>(
      Slot::FunctionType_packed_parameter_counts());

  body += IntConstant(0);
  body += StrictCompare(Token::kNE_STRICT);
  info.has_named_params = MakeTemporary("has_named_params");

  body += LoadLocal(info.signature);
  body += LoadNativeField(Slot::FunctionType_named_parameter_names());
  info.named_parameter_names = MakeTemporary("named_parameter_names");

  body += LoadLocal(info.signature);
  body += LoadNativeField(Slot::FunctionType_parameter_types());
  info.parameter_types = MakeTemporary("parameter_types");

  body += LoadLocal(info.signature);
  body += LoadNativeField(Slot::FunctionType_type_parameters());
  info.type_parameters = MakeTemporary("type_parameters");

  body += LoadLocal(info.closure);
  body += LoadNativeField(Slot::Closure_instantiator_type_arguments());
  info.instantiator_type_args = MakeTemporary("instantiator_type_args");

  body += LoadLocal(info.closure);
  body += LoadNativeField(Slot::Closure_function_type_arguments());
  info.parent_function_type_args = MakeTemporary("parent_function_type_args");

  // At this point, all the read-only temporaries stored in the ClosureCallInfo
  // should be either loaded or still nullptr, if not needed for this function.
  // Now we check that the arguments to the closure call have the right shape.
  body += BuildClosureCallArgumentsValidCheck(info);

  // If the closure function is not generic, there are no local function type
  // args. Thus, use whatever was stored for the parent function type arguments,
  // which has already been checked against any parent type parameter bounds.
  Fragment not_generic;
  not_generic += LoadLocal(info.parent_function_type_args);
  not_generic += StoreLocal(info.vars->function_type_args);
  not_generic += Drop();

  // If the closure function is generic, then we first need to calculate the
  // full set of function type arguments, then check the local function type
  // arguments against the closure function's type parameter bounds.
  Fragment generic;
  // Calculate the number of parent type arguments and store them in
  // info.num_parent_type_args.
  generic += LoadLocal(info.signature);
  generic += BuildExtractUnboxedSlotBitFieldIntoSmi<
      UntaggedFunctionType::PackedNumParentTypeArguments>(
      Slot::FunctionType_packed_type_parameter_counts());
  info.num_parent_type_args = MakeTemporary("num_parent_type_args");

  // Hoist number of type parameters.
  generic += LoadLocal(info.signature);
  generic += BuildExtractUnboxedSlotBitFieldIntoSmi<
      UntaggedFunctionType::PackedNumTypeParameters>(
      Slot::FunctionType_packed_type_parameter_counts());
  info.num_type_parameters = MakeTemporary("num_type_parameters");

  // Hoist type parameter flags.
  generic += LoadLocal(info.type_parameters);
  generic += LoadNativeField(Slot::TypeParameters_flags());
  info.type_parameter_flags = MakeTemporary("type_parameter_flags");

  // Calculate the local function type arguments and store them in
  // info.vars->function_type_args.
  generic += BuildClosureCallDefaultTypeHandling(info);

  // Load the local function type args.
  generic += LoadLocal(info.vars->function_type_args);
  // Load the parent function type args.
  generic += LoadLocal(info.parent_function_type_args);
  // Load the number of parent type parameters.
  generic += LoadLocal(info.num_parent_type_args);
  // Load the number of total type parameters.
  generic += LoadLocal(info.num_parent_type_args);
  generic += LoadLocal(info.num_type_parameters);
  generic += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);

  // Call the static function for prepending type arguments.
  generic += StaticCall(TokenPosition::kNoSource,
                        PrependTypeArgumentsFunction(), 4, ICData::kStatic);
  generic += StoreLocal(info.vars->function_type_args);
  generic += Drop();

  // Now that we have the full set of function type arguments, check them
  // against the type parameter bounds. However, if the local function type
  // arguments are delayed type arguments, they have already been checked by
  // the type system and need not be checked again at the call site.
  auto const check_bounds = BuildClosureCallTypeArgumentsTypeCheck(info);
  if (FLAG_eliminate_type_checks) {
    generic += TestDelayedTypeArgs(info.closure, /*present=*/{},
                                   /*absent=*/check_bounds);
  } else {
    generic += check_bounds;
  }
  generic += DropTemporary(&info.type_parameter_flags);
  generic += DropTemporary(&info.num_type_parameters);
  generic += DropTemporary(&info.num_parent_type_args);

  // Call the appropriate fragment for setting up the function type arguments
  // and performing any needed type argument checking.
  body += TestClosureFunctionGeneric(info, generic, not_generic);

  // Check that the values provided as arguments are assignable to the types
  // of the corresponding closure function parameters.
  body += BuildClosureCallArgumentTypeChecks(info);

  // Drop all the read-only temporaries at the end of the fragment.
  body += DropTemporary(&info.parent_function_type_args);
  body += DropTemporary(&info.instantiator_type_args);
  body += DropTemporary(&info.type_parameters);
  body += DropTemporary(&info.parameter_types);
  body += DropTemporary(&info.named_parameter_names);
  body += DropTemporary(&info.has_named_params);
  body += DropTemporary(&info.num_max_params);
  body += DropTemporary(&info.num_opt_params);
  body += DropTemporary(&info.num_fixed_params);
  body += DropTemporary(&info.signature);

  return body;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher(
    const Function& function) {
  const ArgumentsDescriptor descriptor(saved_args_desc_array());
  // Find the name of the field we should dispatch to.
  const Class& owner = Class::Handle(Z, function.Owner());
  ASSERT(!owner.IsNull());
  auto& field_name = String::Handle(Z, function.name());
  // If the field name has a dyn: tag, then remove it. We don't add dynamic
  // invocation forwarders for field getters used for invoking, we just use
  // the tag in the name of the invoke field dispatcher to detect dynamic calls.
  const bool is_dynamic_call =
      Function::IsDynamicInvocationForwarderName(field_name);
  if (is_dynamic_call) {
    field_name = Function::DemangleDynamicInvocationForwarderName(field_name);
  }
  const String& getter_name = String::ZoneHandle(
      Z, Symbols::New(thread_,
                      String::Handle(Z, Field::GetterSymbol(field_name))));

  // Determine if this is `class Closure { get call => this; }`
  const Class& closure_class =
      Class::Handle(Z, IG->object_store()->closure_class());
  const bool is_closure_call = (owner.ptr() == closure_class.ptr()) &&
                               field_name.Equals(Symbols::call());

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment body(instruction_cursor);
  body += CheckStackOverflowInPrologue(function.token_pos());

  // Build any dynamic closure call checks before pushing arguments to the
  // final call on the stack to make debugging easier.
  LocalVariable* closure = nullptr;
  if (is_closure_call) {
    closure = parsed_function_->ParameterVariable(0);
    if (is_dynamic_call) {
      // The whole reason for making this invoke field dispatcher is that
      // this closure call needs checking, so we shouldn't inline a call to an
      // unchecked entry that can't tail call NSM.
      InlineBailout(
          "kernel::FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher");

      body += BuildDynamicClosureCallChecks(closure);
    }
  }

  if (descriptor.TypeArgsLen() > 0) {
    LocalVariable* type_args = parsed_function_->function_type_arguments();
    ASSERT(type_args != nullptr);
    body += LoadLocal(type_args);
  }

  if (is_closure_call) {
    // The closure itself is the first argument.
    body += LoadLocal(closure);
  } else {
    // Invoke the getter to get the field value.
    body += LoadLocal(parsed_function_->ParameterVariable(0));
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    body += InstanceCall(TokenPosition::kMinSource, getter_name, Token::kGET,
                         kTypeArgsLen, 1, Array::null_array(), kNumArgsChecked);
  }

  // Push all arguments onto the stack.
  for (intptr_t pos = 1; pos < descriptor.Count(); pos++) {
    body += LoadLocal(parsed_function_->ParameterVariable(pos));
  }

  // Construct argument names array if necessary.
  const Array* argument_names = &Object::null_array();
  if (descriptor.NamedCount() > 0) {
    const auto& array_handle =
        Array::ZoneHandle(Z, Array::New(descriptor.NamedCount(), Heap::kNew));
    String& string_handle = String::Handle(Z);
    for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
      const intptr_t named_arg_index =
          descriptor.PositionAt(i) - descriptor.PositionalCount();
      string_handle = descriptor.NameAt(i);
      array_handle.SetAt(named_arg_index, string_handle);
    }
    argument_names = &array_handle;
  }

  if (is_closure_call) {
    body += LoadLocal(closure);
    if (!FLAG_precompiled_mode) {
      // Lookup the function in the closure.
      body += LoadNativeField(Slot::Closure_function());
    }
    body += ClosureCall(Function::null_function(), TokenPosition::kNoSource,
                        descriptor.TypeArgsLen(), descriptor.Count(),
                        *argument_names);
  } else {
    const intptr_t kNumArgsChecked = 1;
    body +=
        InstanceCall(TokenPosition::kMinSource,
                     is_dynamic_call ? Symbols::DynamicCall() : Symbols::call(),
                     Token::kILLEGAL, descriptor.TypeArgsLen(),
                     descriptor.Count(), *argument_names, kNumArgsChecked);
  }

  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfNoSuchMethodForwarder(
    const Function& function,
    bool is_implicit_closure_function,
    bool throw_no_such_method_error) {
  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment body(instruction_cursor);
  body += CheckStackOverflowInPrologue(function.token_pos());

  // If we are inside the tearoff wrapper function (implicit closure), we need
  // to extract the receiver from the context. We just replace it directly on
  // the stack to simplify the rest of the code.
  if (is_implicit_closure_function && !function.is_static()) {
    if (parsed_function_->has_arg_desc_var()) {
      body += LoadArgDescriptor();
      body += LoadNativeField(Slot::ArgumentsDescriptor_size());
    } else {
      ASSERT(function.NumOptionalParameters() == 0);
      body += IntConstant(function.NumParameters());
    }
    body += LoadLocal(parsed_function_->current_context_var());
    body += LoadNativeField(Slot::GetContextVariableSlotFor(
        thread_, *parsed_function_->receiver_var()));
    body += StoreFpRelativeSlot(
        kWordSize * compiler::target::frame_layout.param_end_from_fp);
  }

  if (function.NeedsTypeArgumentTypeChecks()) {
    BuildTypeArgumentTypeChecks(TypeChecksToBuild::kCheckAllTypeParameterBounds,
                                &body);
  }

  if (function.NeedsArgumentTypeChecks()) {
    BuildArgumentTypeChecks(&body, &body, nullptr);
  }

  body += MakeTemp();
  LocalVariable* result = MakeTemporary();

  // Do "++argument_count" if any type arguments were passed.
  LocalVariable* argument_count_var = parsed_function_->expression_temp_var();
  body += IntConstant(0);
  body += StoreLocal(TokenPosition::kNoSource, argument_count_var);
  body += Drop();
  if (function.IsGeneric()) {
    Fragment then;
    Fragment otherwise;
    otherwise += IntConstant(1);
    otherwise += StoreLocal(TokenPosition::kNoSource, argument_count_var);
    otherwise += Drop();
    body += TestAnyTypeArgs(then, otherwise);
  }

  if (function.HasOptionalParameters()) {
    body += LoadArgDescriptor();
    body += LoadNativeField(Slot::ArgumentsDescriptor_size());
  } else {
    body += IntConstant(function.NumParameters());
  }
  body += LoadLocal(argument_count_var);
  body += SmiBinaryOp(Token::kADD, /* truncate= */ true);
  LocalVariable* argument_count = MakeTemporary();

  // We are generating code like the following:
  //
  // var arguments = new Array<dynamic>(argument_count);
  //
  // int i = 0;
  // if (any type arguments are passed) {
  //   arguments[0] = function_type_arguments;
  //   ++i;
  // }
  //
  // for (; i < argument_count; ++i) {
  //   arguments[i] = LoadFpRelativeSlot(
  //       kWordSize * (frame_layout.param_end_from_fp + argument_count - i));
  // }
  body += Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
  body += LoadLocal(argument_count);
  body += CreateArray();
  LocalVariable* arguments = MakeTemporary();

  {
    // int i = 0
    LocalVariable* index = parsed_function_->expression_temp_var();
    body += IntConstant(0);
    body += StoreLocal(TokenPosition::kNoSource, index);
    body += Drop();

    // if (any type arguments are passed) {
    //   arguments[0] = function_type_arguments;
    //   i = 1;
    // }
    if (function.IsGeneric()) {
      Fragment store;
      store += LoadLocal(arguments);
      store += IntConstant(0);
      store += LoadFunctionTypeArguments();
      store += StoreIndexed(kArrayCid);
      store += IntConstant(1);
      store += StoreLocal(TokenPosition::kNoSource, index);
      store += Drop();
      body += TestAnyTypeArgs(store, Fragment());
    }

    TargetEntryInstr* body_entry;
    TargetEntryInstr* loop_exit;

    Fragment condition;
    // i < argument_count
    condition += LoadLocal(index);
    condition += LoadLocal(argument_count);
    condition += SmiRelationalOp(Token::kLT);
    condition += BranchIfTrue(&body_entry, &loop_exit, /*negate=*/false);

    Fragment loop_body(body_entry);

    // arguments[i] = LoadFpRelativeSlot(
    //     kWordSize * (frame_layout.param_end_from_fp + argument_count - i));
    loop_body += LoadLocal(arguments);
    loop_body += LoadLocal(index);
    loop_body += LoadLocal(argument_count);
    loop_body += LoadLocal(index);
    loop_body += SmiBinaryOp(Token::kSUB, /*truncate=*/true);
    loop_body +=
        LoadFpRelativeSlot(compiler::target::kWordSize *
                               compiler::target::frame_layout.param_end_from_fp,
                           CompileType::Dynamic());
    loop_body += StoreIndexed(kArrayCid);

    // ++i
    loop_body += LoadLocal(index);
    loop_body += IntConstant(1);
    loop_body += SmiBinaryOp(Token::kADD, /*truncate=*/true);
    loop_body += StoreLocal(TokenPosition::kNoSource, index);
    loop_body += Drop();

    JoinEntryInstr* join = BuildJoinEntry();
    loop_body += Goto(join);

    Fragment loop(join);
    loop += condition;

    Instruction* entry =
        new (Z) GotoInstr(join, CompilerState::Current().GetNextDeoptId());
    body += Fragment(entry, loop_exit);
  }

  // Load receiver.
  if (is_implicit_closure_function) {
    if (throw_no_such_method_error) {
      const Function& parent =
          Function::ZoneHandle(Z, function.parent_function());
      const Class& owner = Class::ZoneHandle(Z, parent.Owner());
      AbstractType& type = AbstractType::ZoneHandle(Z);
      type = Type::New(owner, Object::null_type_arguments());
      type = ClassFinalizer::FinalizeType(type);
      body += Constant(type);
    } else {
      body += LoadLocal(parsed_function_->current_context_var());
      body += LoadNativeField(Slot::GetContextVariableSlotFor(
          thread_, *parsed_function_->receiver_var()));
    }
  } else {
    body += LoadLocal(parsed_function_->ParameterVariable(0));
  }

  body += Constant(String::ZoneHandle(Z, function.name()));

  if (!parsed_function_->has_arg_desc_var()) {
    // If there is no variable for the arguments descriptor (this function's
    // signature doesn't require it), then we need to create one.
    Array& args_desc = Array::ZoneHandle(
        Z, ArgumentsDescriptor::NewBoxed(0, function.NumParameters()));
    body += Constant(args_desc);
  } else {
    body += LoadArgDescriptor();
  }

  body += LoadLocal(arguments);

  if (throw_no_such_method_error) {
    const Function& parent =
        Function::ZoneHandle(Z, function.parent_function());
    const Class& owner = Class::ZoneHandle(Z, parent.Owner());
    InvocationMirror::Level im_level = owner.IsTopLevel()
                                           ? InvocationMirror::kTopLevel
                                           : InvocationMirror::kStatic;
    InvocationMirror::Kind im_kind;
    if (function.IsImplicitGetterFunction() || function.IsGetterFunction()) {
      im_kind = InvocationMirror::kGetter;
    } else if (function.IsImplicitSetterFunction() ||
               function.IsSetterFunction()) {
      im_kind = InvocationMirror::kSetter;
    } else {
      im_kind = InvocationMirror::kMethod;
    }
    body += IntConstant(InvocationMirror::EncodeType(im_level, im_kind));
  } else {
    body += NullConstant();
  }

  // Push the number of delayed type arguments.
  if (function.IsClosureFunction()) {
    LocalVariable* closure = parsed_function_->ParameterVariable(0);
    Fragment then;
    then += IntConstant(function.NumTypeParameters());
    then += StoreLocal(TokenPosition::kNoSource, argument_count_var);
    then += Drop();
    Fragment otherwise;
    otherwise += IntConstant(0);
    otherwise += StoreLocal(TokenPosition::kNoSource, argument_count_var);
    otherwise += Drop();
    body += TestDelayedTypeArgs(closure, then, otherwise);
    body += LoadLocal(argument_count_var);
  } else {
    body += IntConstant(0);
  }

  const Class& mirror_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const auto& error = mirror_class.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(Library::PrivateCoreLibName(
             Symbols::AllocateInvocationMirrorForClosure())));
  ASSERT(!allocation_function.IsNull());
  body += StaticCall(TokenPosition::kMinSource, allocation_function,
                     /* argument_count = */ 5, ICData::kStatic);

  if (throw_no_such_method_error) {
    const Class& klass = Class::ZoneHandle(
        Z, Library::LookupCoreClass(Symbols::NoSuchMethodError()));
    ASSERT(!klass.IsNull());
    const auto& error = klass.EnsureIsFinalized(H.thread());
    ASSERT(error == Error::null());
    const Function& throw_function = Function::ZoneHandle(
        Z,
        klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNewInvocation()));
    ASSERT(!throw_function.IsNull());
    body += StaticCall(TokenPosition::kNoSource, throw_function, 2,
                       ICData::kStatic);
  } else {
    body += InstanceCall(
        TokenPosition::kNoSource, Symbols::NoSuchMethod(), Token::kILLEGAL,
        /*type_args_len=*/0, /*argument_count=*/2, Array::null_array(),
        /*checked_argument_count=*/1);
  }
  body += StoreLocal(TokenPosition::kNoSource, result);
  body += Drop();

  body += Drop();  // arguments
  body += Drop();  // argument count

  AbstractType& return_type = AbstractType::Handle(function.result_type());
  if (!return_type.IsTopTypeForSubtyping()) {
    body += AssertAssignableLoadTypeArguments(TokenPosition::kNoSource,
                                              return_type, Symbols::Empty());
  }
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

Fragment FlowGraphBuilder::BuildDefaultTypeHandling(const Function& function) {
  if (function.IsGeneric()) {
    auto& default_types =
        TypeArguments::ZoneHandle(Z, function.InstantiateToBounds(thread_));

    if (!default_types.IsNull()) {
      Fragment then;
      Fragment otherwise;

      otherwise += TranslateInstantiatedTypeArguments(default_types);
      otherwise += StoreLocal(TokenPosition::kNoSource,
                              parsed_function_->function_type_arguments());
      otherwise += Drop();
      return TestAnyTypeArgs(then, otherwise);
    }
  }
  return Fragment();
}

FunctionEntryInstr* FlowGraphBuilder::BuildSharedUncheckedEntryPoint(
    Fragment shared_prologue_linked_in,
    Fragment skippable_checks,
    Fragment redefinitions_if_skipped,
    Fragment body) {
  ASSERT(shared_prologue_linked_in.entry == graph_entry_->normal_entry());
  ASSERT(parsed_function_->has_entry_points_temp_var());
  Instruction* prologue_start = shared_prologue_linked_in.entry->next();

  auto* join_entry = BuildJoinEntry();

  Fragment normal_entry(shared_prologue_linked_in.entry);
  normal_entry +=
      IntConstant(static_cast<intptr_t>(UncheckedEntryPointStyle::kNone));
  normal_entry += StoreLocal(TokenPosition::kNoSource,
                             parsed_function_->entry_points_temp_var());
  normal_entry += Drop();
  normal_entry += Goto(join_entry);

  auto* extra_target_entry = BuildFunctionEntry(graph_entry_);
  Fragment extra_entry(extra_target_entry);
  extra_entry += IntConstant(
      static_cast<intptr_t>(UncheckedEntryPointStyle::kSharedWithVariable));
  extra_entry += StoreLocal(TokenPosition::kNoSource,
                            parsed_function_->entry_points_temp_var());
  extra_entry += Drop();
  extra_entry += Goto(join_entry);

  if (prologue_start != nullptr) {
    join_entry->LinkTo(prologue_start);
  } else {
    // Prologue is empty.
    shared_prologue_linked_in.current = join_entry;
  }

  TargetEntryInstr* do_checks;
  TargetEntryInstr* skip_checks;
  shared_prologue_linked_in +=
      LoadLocal(parsed_function_->entry_points_temp_var());
  shared_prologue_linked_in += BuildEntryPointsIntrospection();
  shared_prologue_linked_in +=
      LoadLocal(parsed_function_->entry_points_temp_var());
  shared_prologue_linked_in += IntConstant(
      static_cast<intptr_t>(UncheckedEntryPointStyle::kSharedWithVariable));
  shared_prologue_linked_in +=
      BranchIfEqual(&skip_checks, &do_checks, /*negate=*/false);

  JoinEntryInstr* rest_entry = BuildJoinEntry();

  Fragment(do_checks) + skippable_checks + Goto(rest_entry);
  Fragment(skip_checks) + redefinitions_if_skipped + Goto(rest_entry);
  Fragment(rest_entry) + body;

  return extra_target_entry;
}

FunctionEntryInstr* FlowGraphBuilder::BuildSeparateUncheckedEntryPoint(
    BlockEntryInstr* normal_entry,
    Fragment normal_prologue,
    Fragment extra_prologue,
    Fragment shared_prologue,
    Fragment body) {
  auto* join_entry = BuildJoinEntry();
  auto* extra_entry = BuildFunctionEntry(graph_entry_);

  Fragment normal(normal_entry);
  normal += IntConstant(static_cast<intptr_t>(UncheckedEntryPointStyle::kNone));
  normal += BuildEntryPointsIntrospection();
  normal += normal_prologue;
  normal += Goto(join_entry);

  Fragment extra(extra_entry);
  extra +=
      IntConstant(static_cast<intptr_t>(UncheckedEntryPointStyle::kSeparate));
  extra += BuildEntryPointsIntrospection();
  extra += extra_prologue;
  extra += Goto(join_entry);

  Fragment(join_entry) + shared_prologue + body;
  return extra_entry;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfImplicitClosureFunction(
    const Function& function) {
  const Function& parent = Function::ZoneHandle(Z, function.parent_function());
  Function& target = Function::ZoneHandle(Z, function.ImplicitClosureTarget(Z));

  if (target.IsNull() ||
      (parent.num_fixed_parameters() != target.num_fixed_parameters())) {
    return BuildGraphOfNoSuchMethodForwarder(function, true,
                                             parent.is_static());
  }

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment closure(instruction_cursor);
  closure += CheckStackOverflowInPrologue(function.token_pos());
  closure += BuildDefaultTypeHandling(function);

  // For implicit closure functions, any non-covariant checks are either
  // performed by the type system or a dynamic invocation layer (dynamic closure
  // call dispatcher, mirror, etc.). Static targets never have covariant
  // arguments, and for non-static targets, they already perform the covariant
  // checks internally. Thus, no checks are needed and we just need to invoke
  // the target with the right receiver (unless static).
  //
  // TODO(dartbug.com/44195): Consider replacing the argument pushes + static
  // call with stack manipulation and a tail call instead.

  intptr_t type_args_len = 0;
  if (function.IsGeneric()) {
    if (target.IsConstructor()) {
      const auto& result_type = AbstractType::Handle(Z, function.result_type());
      ASSERT(result_type.IsFinalized());
      // Instantiate a flattened type arguments vector which
      // includes type arguments corresponding to superclasses.
      // TranslateInstantiatedTypeArguments is smart enough to
      // avoid instantiation and reuse passed function type arguments
      // if there are no extra type arguments in the flattened vector.
      const auto& instantiated_type_arguments = TypeArguments::ZoneHandle(
          Z, Type::Cast(result_type).GetInstanceTypeArguments(H.thread()));
      closure +=
          TranslateInstantiatedTypeArguments(instantiated_type_arguments);
    } else {
      type_args_len = function.NumTypeParameters();
      ASSERT(parsed_function_->function_type_arguments() != nullptr);
      closure += LoadLocal(parsed_function_->function_type_arguments());
    }
  } else if (target.IsFactory()) {
    // Factories always take an extra implicit argument for
    // type arguments even if their classes don't have type parameters.
    closure += NullConstant();
  }

  // Push receiver.
  if (target.IsGenerativeConstructor()) {
    const Class& cls = Class::ZoneHandle(Z, target.Owner());
    if (cls.NumTypeArguments() > 0) {
      if (!function.IsGeneric()) {
        closure += Constant(TypeArguments::ZoneHandle(
            Z, cls.GetDeclarationInstanceTypeArguments()));
      }
      closure += AllocateObject(function.token_pos(), cls, 1);
    } else {
      ASSERT(!function.IsGeneric());
      closure += AllocateObject(function.token_pos(), cls, 0);
    }
    LocalVariable* receiver = MakeTemporary();
    closure += LoadLocal(receiver);
  } else if (!target.is_static()) {
    // The context has a fixed shape: a single variable which is the
    // closed-over receiver.
    closure += LoadLocal(parsed_function_->ParameterVariable(0));
    closure += LoadNativeField(Slot::Closure_context());
    closure += LoadNativeField(Slot::GetContextVariableSlotFor(
        thread_, *parsed_function_->receiver_var()));
  }

  closure += PushExplicitParameters(function);

  // Forward parameters to the target.
  intptr_t argument_count = function.NumParameters() -
                            function.NumImplicitParameters() +
                            target.NumImplicitParameters();
  ASSERT(argument_count == target.NumParameters());

  Array& argument_names =
      Array::ZoneHandle(Z, GetOptionalParameterNames(function));

  closure += StaticCall(TokenPosition::kNoSource, target, argument_count,
                        argument_names, ICData::kNoRebind,
                        /* result_type = */ nullptr, type_args_len);

  if (target.IsGenerativeConstructor()) {
    // Drop result of constructor invocation, leave receiver
    // instance on the stack.
    closure += Drop();
  }

  // Return the result.
  closure += Return(function.end_token_pos());

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfFieldAccessor(
    const Function& function) {
  ASSERT(function.IsImplicitGetterOrSetter() ||
         function.IsDynamicInvocationForwarder());

  // Instead of building a dynamic invocation forwarder that checks argument
  // type and then invokes original setter we simply generate the type check
  // and inlined field store. Scope builder takes care of setting correct
  // type check mode in this case.
  const auto& target = Function::Handle(
      Z, function.IsDynamicInvocationForwarder() ? function.ForwardingTarget()
                                                 : function.ptr());
  ASSERT(target.IsImplicitGetterOrSetter());

  const bool is_method = !function.IsStaticFunction();
  const bool is_setter = target.IsImplicitSetterFunction();
  const bool is_getter = target.IsImplicitGetterFunction() ||
                         target.IsImplicitStaticGetterFunction();
  ASSERT(is_setter || is_getter);

  const auto& field = Field::ZoneHandle(Z, target.accessor_field());

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  Fragment body(normal_entry);
  if (is_setter) {
    auto const setter_value =
        parsed_function_->ParameterVariable(is_method ? 1 : 0);
    if (is_method) {
      body += LoadLocal(parsed_function_->ParameterVariable(0));
    }
    body += LoadLocal(setter_value);

    // The dyn:* forwarder has to check the parameters that the
    // actual target will not check.
    // Though here we manually inline the target, so the dyn:* forwarder has to
    // check all parameters.
    const bool needs_type_check = function.IsDynamicInvocationForwarder() ||
                                  setter_value->needs_type_check();
    if (needs_type_check) {
      body += CheckAssignable(setter_value->static_type(), setter_value->name(),
                              AssertAssignableInstr::kParameterCheck,
                              field.token_pos());
    }
    body += BuildNullAssertions();
    if (field.is_late()) {
      if (is_method) {
        body += Drop();
      }
      body += Drop();
      body += StoreLateField(
          field, is_method ? parsed_function_->ParameterVariable(0) : nullptr,
          setter_value);
    } else {
      if (is_method) {
        body += StoreFieldGuarded(field, StoreFieldInstr::Kind::kOther);
      } else {
        body += StoreStaticField(TokenPosition::kNoSource, field);
      }
    }
    body += NullConstant();
  } else {
    ASSERT(is_getter);
    if (is_method) {
      body += LoadLocal(parsed_function_->ParameterVariable(0));
      body += LoadField(
          field, /*calls_initializer=*/field.NeedsInitializationCheckOnLoad());
    } else if (field.is_const()) {
      const auto& value = Object::Handle(Z, field.StaticConstFieldValue());
      if (value.IsError()) {
        Report::LongJump(Error::Cast(value));
      }
      body += Constant(Instance::ZoneHandle(Z, Instance::RawCast(value.ptr())));
    } else {
      // Static fields
      //  - with trivial initializer
      //  - without initializer if they are not late
      // are initialized eagerly and do not have implicit getters.
      // Static fields with non-trivial initializer need getter to perform
      // lazy initialization. Late fields without initializer need getter
      // to make sure they are already initialized.
      ASSERT(field.has_nontrivial_initializer() ||
             (field.is_late() && !field.has_initializer()));
      body += LoadStaticField(field, /*calls_initializer=*/true);
    }

    if (is_method || !field.is_const()) {
#if defined(PRODUCT)
      RELEASE_ASSERT(!field.needs_load_guard());
#else
      // Always build fragment for load guard to maintain stable deopt_id
      // numbering, but link it into the graph only if field actually
      // needs load guard.
      Fragment load_guard = CheckAssignable(
          AbstractType::Handle(Z, field.type()), Symbols::FunctionResult());
      if (field.needs_load_guard()) {
        ASSERT(IG->HasAttemptedReload());
        body += load_guard;
      }
#endif
    }
  }
  body += Return(TokenPosition::kNoSource);

  PrologueInfo prologue_info(-1, -1);
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfDynamicInvocationForwarder(
    const Function& function) {
  auto& name = String::Handle(Z, function.name());
  name = Function::DemangleDynamicInvocationForwarderName(name);
  const auto& target = Function::ZoneHandle(Z, function.ForwardingTarget());
  ASSERT(!target.IsNull());

  if (target.IsImplicitSetterFunction() || target.IsImplicitGetterFunction()) {
    return BuildGraphOfFieldAccessor(function);
  }
  if (target.IsMethodExtractor()) {
    return BuildGraphOfMethodExtractor(target);
  }

  graph_entry_ = new (Z) GraphEntryInstr(*parsed_function_, osr_id_);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);
  auto instruction_cursor = BuildPrologue(normal_entry, &prologue_info);

  Fragment body;
  if (!function.is_native()) {
    body += CheckStackOverflowInPrologue(function.token_pos());
  }

  ASSERT(parsed_function_->scope()->num_context_variables() == 0);

  // Should never build a dynamic invocation forwarder for equality
  // operator.
  ASSERT(function.name() != Symbols::EqualOperator().ptr());

  // Even if the caller did not pass argument vector we would still
  // call the target with instantiate-to-bounds type arguments.
  body += BuildDefaultTypeHandling(function);

  // Build argument type checks that complement those that are emitted in the
  // target.
  BuildTypeArgumentTypeChecks(
      TypeChecksToBuild::kCheckNonCovariantTypeParameterBounds, &body);
  BuildArgumentTypeChecks(&body, &body, nullptr);

  // Push all arguments and invoke the original method.

  intptr_t type_args_len = 0;
  if (function.IsGeneric()) {
    type_args_len = function.NumTypeParameters();
    ASSERT(parsed_function_->function_type_arguments() != nullptr);
    body += LoadLocal(parsed_function_->function_type_arguments());
  }

  // Push receiver.
  ASSERT(function.NumImplicitParameters() == 1);
  body += LoadLocal(parsed_function_->receiver_var());
  body += PushExplicitParameters(function, target);

  const intptr_t argument_count = function.NumParameters();
  const auto& argument_names =
      Array::ZoneHandle(Z, GetOptionalParameterNames(function));

  body += StaticCall(TokenPosition::kNoSource, target, argument_count,
                     argument_names, ICData::kNoRebind, nullptr, type_args_len);

  if (target.has_unboxed_integer_return()) {
    body += Box(kUnboxedInt64);
  } else if (target.has_unboxed_double_return()) {
    body += Box(kUnboxedDouble);
  } else if (target.has_unboxed_record_return()) {
    // Handled in SelectRepresentations pass in optimized mode.
    ASSERT(optimizing_);
  }

  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.ptr() == Symbols::AssignIndexToken().ptr()) {
    body += Drop();
    body += NullConstant();
  }

  body += Return(TokenPosition::kNoSource);

  instruction_cursor->LinkTo(body.entry);

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (IsCompiledForOsr()) {
    graph_entry_->RelinkToOsrEntry(Z, last_used_block_id_ + 1);
  }
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

void FlowGraphBuilder::SetConstantRangeOfCurrentDefinition(
    const Fragment& fragment,
    int64_t min,
    int64_t max) {
  ASSERT(fragment.current->IsDefinition());
  Range range(RangeBoundary::FromConstant(min),
              RangeBoundary::FromConstant(max));
  fragment.current->AsDefinition()->set_range(range);
}

static classid_t TypedDataCidUnboxed(Representation unboxed_representation) {
  switch (unboxed_representation) {
    case kUnboxedFloat:
      // Note kTypedDataFloat32ArrayCid loads kUnboxedDouble.
      UNREACHABLE();
      return kTypedDataFloat32ArrayCid;
    case kUnboxedInt32:
      return kTypedDataInt32ArrayCid;
    case kUnboxedUint32:
      return kTypedDataUint32ArrayCid;
    case kUnboxedInt64:
      return kTypedDataInt64ArrayCid;
    case kUnboxedDouble:
      return kTypedDataFloat64ArrayCid;
    default:
      UNREACHABLE();
  }
  UNREACHABLE();
}

Fragment FlowGraphBuilder::StoreIndexedTypedDataUnboxed(
    Representation unboxed_representation,
    intptr_t index_scale,
    bool index_unboxed) {
  ASSERT(unboxed_representation == kUnboxedInt32 ||
         unboxed_representation == kUnboxedUint32 ||
         unboxed_representation == kUnboxedInt64 ||
         unboxed_representation == kUnboxedFloat ||
         unboxed_representation == kUnboxedDouble);
  Fragment fragment;
  if (unboxed_representation == kUnboxedFloat) {
    fragment += BitCast(kUnboxedFloat, kUnboxedInt32);
    unboxed_representation = kUnboxedInt32;
  }
  fragment += StoreIndexedTypedData(TypedDataCidUnboxed(unboxed_representation),
                                    index_scale, index_unboxed);
  return fragment;
}

Fragment FlowGraphBuilder::LoadIndexedTypedDataUnboxed(
    Representation unboxed_representation,
    intptr_t index_scale,
    bool index_unboxed) {
  ASSERT(unboxed_representation == kUnboxedInt32 ||
         unboxed_representation == kUnboxedUint32 ||
         unboxed_representation == kUnboxedInt64 ||
         unboxed_representation == kUnboxedFloat ||
         unboxed_representation == kUnboxedDouble);
  Representation representation_for_load = unboxed_representation;
  if (unboxed_representation == kUnboxedFloat) {
    representation_for_load = kUnboxedInt32;
  }
  Fragment fragment;
  fragment += LoadIndexed(TypedDataCidUnboxed(representation_for_load),
                          index_scale, index_unboxed);
  if (unboxed_representation == kUnboxedFloat) {
    fragment += BitCast(kUnboxedInt32, kUnboxedFloat);
  }
  return fragment;
}

Fragment FlowGraphBuilder::EnterHandleScope() {
  Fragment body;
  body += LoadThread();
  body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);  // argument.

  // LoadThread again, we can't store it in a temp because it will end up
  // in the environment of the FfiCall as untagged then.
  body += LoadThread();
  body += LoadUntagged(compiler::target::Thread::OffsetFromThread(
      &kEnterHandleScopeRuntimeEntry));
  body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);  // function address.

  body += CCall(/*num_arguments=*/1);

  return body;
}

Fragment FlowGraphBuilder::GetTopHandleScope() {
  Fragment body;
  body += LoadThread();
  body += LoadUntagged(compiler::target::Thread::api_top_scope_offset());
  body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);
  return body;
}

Fragment FlowGraphBuilder::ExitHandleScope() {
  Fragment code;
  code += LoadThread();
  code += ConvertUntaggedToUnboxed(kUnboxedIntPtr);  // argument.

  code += LoadThread();
  code += LoadUntagged(compiler::target::Thread::OffsetFromThread(
      &kExitHandleScopeRuntimeEntry));
  code += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);  // function address.

  code += CCall(/*num_arguments=*/1);

  code += Drop();
  return code;
}

Fragment FlowGraphBuilder::AllocateHandle() {
  Fragment code;
  // Get a reference to the top handle scope.
  code += GetTopHandleScope();

  code += LoadThread();
  code += LoadUntagged(
      compiler::target::Thread::OffsetFromThread(&kAllocateHandleRuntimeEntry));
  code += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);  // function address.

  code += CCall(/*num_arguments=*/1, kUnboxedIntPtr);

  return code;
}

Fragment FlowGraphBuilder::RawLoadField(int32_t offset) {
  Fragment code;
  code += UnboxedIntConstant(offset, kUnboxedIntPtr);
  code += LoadIndexed(kArrayCid, /*index_scale=*/1, /*index_unboxed=*/true);
  return code;
}

Fragment FlowGraphBuilder::RawStoreField(int32_t offset) {
  Fragment code;
  Value* value = Pop();
  Value* base = Pop();
  auto* instr = new (Z) RawStoreFieldInstr(base, value, offset);
  code <<= instr;
  return code;
}

Fragment FlowGraphBuilder::WrapHandle() {
  Fragment code;
  LocalVariable* object = MakeTemporary();
  code += AllocateHandle();

  code += LoadLocal(MakeTemporary());  // Duplicate handle pointer.
  code += ConvertUnboxedToUntagged(kUnboxedIntPtr);
  code += LoadLocal(object);
  code += RawStoreField(compiler::target::LocalHandle::ptr_offset());

  code += DropTempsPreserveTop(1);  // Drop object below handle.
  return code;
}

Fragment FlowGraphBuilder::UnwrapHandle() {
  Fragment code;
  code += ConvertUnboxedToUntagged(kUnboxedIntPtr);
  code += RawLoadField(compiler::target::LocalHandle::ptr_offset());
  return code;
}

Fragment FlowGraphBuilder::UnhandledException() {
  const auto class_table = thread_->isolate_group()->class_table();
  ASSERT(class_table->HasValidClassAt(kUnhandledExceptionCid));
  const auto& klass =
      Class::ZoneHandle(H.zone(), class_table->At(kUnhandledExceptionCid));
  ASSERT(!klass.IsNull());
  Fragment body;
  body += AllocateObject(TokenPosition::kNoSource, klass, 0);
  LocalVariable* error_instance = MakeTemporary();

  body += LoadLocal(error_instance);
  body += LoadLocal(CurrentException());
  body +=
      StoreNativeField(Slot::UnhandledException_exception(),
                       StoreFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  body += LoadLocal(error_instance);
  body += LoadLocal(CurrentStackTrace());
  body +=
      StoreNativeField(Slot::UnhandledException_stacktrace(),
                       StoreFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  return body;
}

Fragment FlowGraphBuilder::UnboxTruncate(Representation to) {
  auto* unbox = UnboxInstr::Create(to, Pop(), DeoptId::kNone,
                                   Instruction::kNotSpeculative);
  Push(unbox);
  return Fragment(unbox);
}

Fragment FlowGraphBuilder::LoadThread() {
  LoadThreadInstr* instr = new (Z) LoadThreadInstr();
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::LoadIsolate() {
  Fragment body;
  body += LoadThread();
  body += LoadUntagged(compiler::target::Thread::isolate_offset());
  return body;
}

Fragment FlowGraphBuilder::LoadIsolateGroup() {
  Fragment body;
  body += LoadThread();
  body += LoadUntagged(compiler::target::Thread::isolate_group_offset());
  return body;
}

Fragment FlowGraphBuilder::LoadObjectStore() {
  Fragment body;
  body += LoadIsolateGroup();
  body += LoadUntagged(compiler::target::IsolateGroup::object_store_offset());
  return body;
}

Fragment FlowGraphBuilder::LoadServiceExtensionStream() {
  Fragment body;
  body += LoadThread();
  body +=
      LoadUntagged(compiler::target::Thread::service_extension_stream_offset());
  return body;
}

// TODO(http://dartbug.com/47487): Support unboxed output value.
Fragment FlowGraphBuilder::BoolToInt() {
  // TODO(http://dartbug.com/36855) Build IfThenElseInstr, instead of letting
  // the optimizer turn this into that.

  LocalVariable* expression_temp = parsed_function_->expression_temp_var();

  Fragment instructions;
  TargetEntryInstr* is_true;
  TargetEntryInstr* is_false;

  instructions += BranchIfTrue(&is_true, &is_false);
  JoinEntryInstr* join = BuildJoinEntry();

  {
    Fragment store_1(is_true);
    store_1 += IntConstant(1);
    store_1 += StoreLocal(TokenPosition::kNoSource, expression_temp);
    store_1 += Drop();
    store_1 += Goto(join);
  }

  {
    Fragment store_0(is_false);
    store_0 += IntConstant(0);
    store_0 += StoreLocal(TokenPosition::kNoSource, expression_temp);
    store_0 += Drop();
    store_0 += Goto(join);
  }

  instructions = Fragment(instructions.entry, join);
  instructions += LoadLocal(expression_temp);
  return instructions;
}

Fragment FlowGraphBuilder::IntToBool() {
  Fragment body;
  body += IntConstant(0);
  body += StrictCompare(Token::kNE_STRICT);
  return body;
}

Fragment FlowGraphBuilder::IntRelationalOp(TokenPosition position,
                                           Token::Kind kind) {
  if (CompilerState::Current().is_aot()) {
    Value* right = Pop();
    Value* left = Pop();
    RelationalOpInstr* instr = new (Z) RelationalOpInstr(
        InstructionSource(position), kind, left, right, kMintCid,
        GetNextDeoptId(), Instruction::SpeculativeMode::kNotSpeculative);
    Push(instr);
    return Fragment(instr);
  }
  const String* name = nullptr;
  switch (kind) {
    case Token::kLT:
      name = &Symbols::LAngleBracket();
      break;
    case Token::kGT:
      name = &Symbols::RAngleBracket();
      break;
    case Token::kLTE:
      name = &Symbols::LessEqualOperator();
      break;
    case Token::kGTE:
      name = &Symbols::GreaterEqualOperator();
      break;
    default:
      UNREACHABLE();
  }
  return InstanceCall(
      position, *name, kind, /*type_args_len=*/0, /*argument_count=*/2,
      /*argument_names=*/Array::null_array(), /*checked_argument_count=*/2);
}

Fragment FlowGraphBuilder::NativeReturn(
    const compiler::ffi::CallbackMarshaller& marshaller) {
  auto* instr = new (Z)
      NativeReturnInstr(InstructionSource(), Pop(), marshaller, DeoptId::kNone);
  return Fragment(instr).closed();
}

Fragment FlowGraphBuilder::FfiPointerFromAddress() {
  LocalVariable* address = MakeTemporary();
  LocalVariable* result = parsed_function_->expression_temp_var();

  Class& result_class =
      Class::ZoneHandle(Z, IG->object_store()->ffi_pointer_class());
  // This class might only be instantiated as a return type of ffi calls.
  result_class.EnsureIsFinalized(thread_);

  TypeArguments& args =
      TypeArguments::ZoneHandle(Z, IG->object_store()->type_argument_never());

  // A kernel transform for FFI in the front-end ensures that type parameters
  // do not appear in the type arguments to a any Pointer classes in an FFI
  // signature.
  ASSERT(args.IsNull() || args.IsInstantiated());
  args = args.Canonicalize(thread_);

  Fragment code;
  code += Constant(args);
  code += AllocateObject(TokenPosition::kNoSource, result_class, 1);
  LocalVariable* pointer = MakeTemporary();
  code += LoadLocal(pointer);
  code += LoadLocal(address);
  code += UnboxTruncate(kUnboxedIntPtr);
  code += StoreNativeField(Slot::PointerBase_data());
  code += StoreLocal(TokenPosition::kNoSource, result);
  code += Drop();  // StoreLocal^
  code += Drop();  // address
  code += LoadLocal(result);

  return code;
}

Fragment FlowGraphBuilder::BitCast(Representation from, Representation to) {
  BitCastInstr* instr = new (Z) BitCastInstr(from, to, Pop());
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::Call1ArgStub(TokenPosition position,
                                        Call1ArgStubInstr::StubId stub_id) {
  Call1ArgStubInstr* instr = new (Z) Call1ArgStubInstr(
      InstructionSource(position), stub_id, Pop(), GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::Suspend(TokenPosition position,
                                   SuspendInstr::StubId stub_id) {
  Value* type_args =
      (stub_id == SuspendInstr::StubId::kAwaitWithTypeCheck) ? Pop() : nullptr;
  Value* operand = Pop();
  SuspendInstr* instr =
      new (Z) SuspendInstr(InstructionSource(position), stub_id, operand,
                           type_args, GetNextDeoptId(), GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::WrapTypedDataBaseInCompound(
    const AbstractType& compound_type) {
  const auto& compound_sub_class =
      Class::ZoneHandle(Z, compound_type.type_class());
  compound_sub_class.EnsureIsFinalized(thread_);
  const auto& lib_ffi = Library::Handle(Z, Library::FfiLibrary());
  const auto& compound_class =
      Class::Handle(Z, lib_ffi.LookupClassAllowPrivate(Symbols::Compound()));
  const auto& compound_typed_data_base =
      Field::ZoneHandle(Z, compound_class.LookupInstanceFieldAllowPrivate(
                               Symbols::_typedDataBase()));
  ASSERT(!compound_typed_data_base.IsNull());

  Fragment body;
  LocalVariable* typed_data = MakeTemporary("typed_data_base");
  body += AllocateObject(TokenPosition::kNoSource, compound_sub_class, 0);
  body += LoadLocal(MakeTemporary("compound"));  // Duplicate Struct or Union.
  body += LoadLocal(typed_data);
  body += StoreField(compound_typed_data_base,
                     StoreFieldInstr::Kind::kInitializing);
  body += DropTempsPreserveTop(1);  // Drop TypedData.
  return body;
}

Fragment FlowGraphBuilder::LoadTypedDataBaseFromCompound() {
  const auto& lib_ffi = Library::Handle(Z, Library::FfiLibrary());
  const auto& compound_class =
      Class::Handle(Z, lib_ffi.LookupClassAllowPrivate(Symbols::Compound()));
  const auto& compound_typed_data_base =
      Field::ZoneHandle(Z, compound_class.LookupInstanceFieldAllowPrivate(
                               Symbols::_typedDataBase()));
  ASSERT(!compound_typed_data_base.IsNull());

  Fragment body;
  body += LoadField(compound_typed_data_base, /*calls_initializer=*/false);
  return body;
}

Fragment FlowGraphBuilder::CopyFromCompoundToStack(
    LocalVariable* variable,
    const GrowableArray<Representation>& representations) {
  Fragment body;
  const intptr_t num_defs = representations.length();
  int offset_in_bytes = 0;
  for (intptr_t i = 0; i < num_defs; i++) {
    body += LoadLocal(variable);
    body += LoadTypedDataBaseFromCompound();
    body += LoadUntagged(compiler::target::PointerBase::data_offset());
    body += IntConstant(offset_in_bytes);
    const Representation representation = representations[i];
    offset_in_bytes += RepresentationUtils::ValueSize(representation);
    body += LoadIndexedTypedDataUnboxed(representation, /*index_scale=*/1,
                                        /*index_unboxed=*/false);
  }
  return body;
}

Fragment FlowGraphBuilder::PopFromStackToTypedDataBase(
    ZoneGrowableArray<LocalVariable*>* definitions,
    const GrowableArray<Representation>& representations) {
  Fragment body;
  const intptr_t num_defs = representations.length();
  ASSERT(definitions->length() == num_defs);

  LocalVariable* uint8_list = MakeTemporary("uint8_list");
  int offset_in_bytes = 0;
  for (intptr_t i = 0; i < num_defs; i++) {
    const Representation representation = representations[i];
    body += LoadLocal(uint8_list);
    body += LoadUntagged(compiler::target::PointerBase::data_offset());
    body += IntConstant(offset_in_bytes);
    body += LoadLocal(definitions->At(i));
    body += StoreIndexedTypedDataUnboxed(representation, /*index_scale=*/1,
                                         /*index_unboxed=*/false);
    offset_in_bytes += RepresentationUtils::ValueSize(representation);
  }
  body += DropTempsPreserveTop(num_defs);  // Drop chunk defs keep TypedData.
  return body;
}

static intptr_t chunk_size(intptr_t bytes_left) {
  ASSERT(bytes_left >= 1);
  if (bytes_left >= 8 && compiler::target::kWordSize == 8) {
    return 8;
  }
  if (bytes_left >= 4) {
    return 4;
  }
  if (bytes_left >= 2) {
    return 2;
  }
  return 1;
}

static classid_t typed_data_cid(intptr_t chunk_size) {
  switch (chunk_size) {
    case 8:
      return kTypedDataInt64ArrayCid;
    case 4:
      return kTypedDataInt32ArrayCid;
    case 2:
      return kTypedDataInt16ArrayCid;
    case 1:
      return kTypedDataInt8ArrayCid;
  }
  UNREACHABLE();
}

Fragment FlowGraphBuilder::CopyFromTypedDataBaseToUnboxedAddress(
    intptr_t length_in_bytes) {
  Fragment body;
  Value* unboxed_address_value = Pop();
  LocalVariable* typed_data_base = MakeTemporary("typed_data_base");
  Push(unboxed_address_value->definition());
  LocalVariable* unboxed_address = MakeTemporary("unboxed_address");

  intptr_t offset_in_bytes = 0;
  while (offset_in_bytes < length_in_bytes) {
    const intptr_t bytes_left = length_in_bytes - offset_in_bytes;
    const intptr_t chunk_sizee = chunk_size(bytes_left);
    const classid_t typed_data_cidd = typed_data_cid(chunk_sizee);

    body += LoadLocal(typed_data_base);
    body += LoadUntagged(compiler::target::PointerBase::data_offset());
    body += IntConstant(offset_in_bytes);
    body += LoadIndexed(typed_data_cidd, /*index_scale=*/1,
                        /*index_unboxed=*/false);
    LocalVariable* chunk_value = MakeTemporary("chunk_value");

    body += LoadLocal(unboxed_address);
    body += ConvertUnboxedToUntagged(kUnboxedFfiIntPtr);
    body += IntConstant(offset_in_bytes);
    body += LoadLocal(chunk_value);
    body += StoreIndexedTypedData(typed_data_cidd, /*index_scale=*/1,
                                  /*index_unboxed=*/false);
    body += DropTemporary(&chunk_value);

    offset_in_bytes += chunk_sizee;
  }
  ASSERT(offset_in_bytes == length_in_bytes);

  body += DropTemporary(&unboxed_address);
  body += DropTemporary(&typed_data_base);
  return body;
}

Fragment FlowGraphBuilder::CopyFromUnboxedAddressToTypedDataBase(
    intptr_t length_in_bytes) {
  Fragment body;
  Value* typed_data_base_value = Pop();
  LocalVariable* unboxed_address = MakeTemporary("unboxed_address");
  Push(typed_data_base_value->definition());
  LocalVariable* typed_data_base = MakeTemporary("typed_data_base");

  intptr_t offset_in_bytes = 0;
  while (offset_in_bytes < length_in_bytes) {
    const intptr_t bytes_left = length_in_bytes - offset_in_bytes;
    const intptr_t chunk_sizee = chunk_size(bytes_left);
    const classid_t typed_data_cidd = typed_data_cid(chunk_sizee);

    body += LoadLocal(unboxed_address);
    body += ConvertUnboxedToUntagged(kUnboxedFfiIntPtr);
    body += IntConstant(offset_in_bytes);
    body += LoadIndexed(typed_data_cidd, /*index_scale=*/1,
                        /*index_unboxed=*/false);
    LocalVariable* chunk_value = MakeTemporary("chunk_value");

    body += LoadLocal(typed_data_base);
    body += LoadUntagged(compiler::target::PointerBase::data_offset());
    body += IntConstant(offset_in_bytes);
    body += LoadLocal(chunk_value);
    body += StoreIndexedTypedData(typed_data_cidd, /*index_scale=*/1,
                                  /*index_unboxed=*/false);
    body += DropTemporary(&chunk_value);

    offset_in_bytes += chunk_sizee;
  }
  ASSERT(offset_in_bytes == length_in_bytes);

  body += DropTemporary(&typed_data_base);
  body += DropTemporary(&unboxed_address);
  return body;
}

Fragment FlowGraphBuilder::FfiCallConvertCompoundArgumentToNative(
    LocalVariable* variable,
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index) {
  Fragment body;
  const auto& native_loc = marshaller.Location(arg_index);
  if (native_loc.IsStack() || native_loc.IsMultiple()) {
    // Break struct in pieces to separate IL definitions to pass those
    // separate definitions into the FFI call.
    GrowableArray<Representation> representations;
    marshaller.RepsInFfiCall(arg_index, &representations);
    body += CopyFromCompoundToStack(variable, representations);
  } else {
    ASSERT(native_loc.IsPointerToMemory());
    // Only load the typed data, do copying in the FFI call machine code.
    body += LoadLocal(variable);  // User-defined struct.
    body += LoadTypedDataBaseFromCompound();
  }
  return body;
}

Fragment FlowGraphBuilder::FfiCallConvertCompoundReturnToDart(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index) {
  Fragment body;
  // The typed data is allocated before the FFI call, and is populated in
  // machine code. So, here, it only has to be wrapped in the struct class.
  const auto& compound_type =
      AbstractType::Handle(Z, marshaller.CType(arg_index));
  body += WrapTypedDataBaseInCompound(compound_type);
  return body;
}

Fragment FlowGraphBuilder::FfiCallbackConvertCompoundArgumentToDart(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index,
    ZoneGrowableArray<LocalVariable*>* definitions) {
  const intptr_t length_in_bytes =
      marshaller.Location(arg_index).payload_type().SizeInBytes();

  Fragment body;
  if ((marshaller.Location(arg_index).IsMultiple() ||
       marshaller.Location(arg_index).IsStack())) {
    // Allocate and populate a TypedData from the individual NativeParameters.
    body += IntConstant(length_in_bytes);
    body +=
        AllocateTypedData(TokenPosition::kNoSource, kTypedDataUint8ArrayCid);
    GrowableArray<Representation> representations;
    marshaller.RepsInFfiCall(arg_index, &representations);
    body += PopFromStackToTypedDataBase(definitions, representations);
  } else {
    ASSERT(marshaller.Location(arg_index).IsPointerToMemory());
    // Allocate a TypedData and copy contents pointed to by an address into it.
    LocalVariable* address_of_compound = MakeTemporary("address_of_compound");
    body += IntConstant(length_in_bytes);
    body +=
        AllocateTypedData(TokenPosition::kNoSource, kTypedDataUint8ArrayCid);
    LocalVariable* typed_data_base = MakeTemporary("typed_data_base");
    body += LoadLocal(address_of_compound);
    body += LoadLocal(typed_data_base);
    body += CopyFromUnboxedAddressToTypedDataBase(length_in_bytes);
    body += DropTempsPreserveTop(1);  // address_of_compound.
  }
  // Wrap typed data in compound class.
  const auto& compound_type =
      AbstractType::Handle(Z, marshaller.CType(arg_index));
  body += WrapTypedDataBaseInCompound(compound_type);
  return body;
}

Fragment FlowGraphBuilder::FfiCallbackConvertCompoundReturnToNative(
    const compiler::ffi::CallbackMarshaller& marshaller,
    intptr_t arg_index) {
  Fragment body;
  const auto& native_loc = marshaller.Location(arg_index);
  if (native_loc.IsMultiple()) {
    // We pass in typed data to native return instruction, and do the copying
    // in machine code.
    body += LoadTypedDataBaseFromCompound();
  } else {
    ASSERT(native_loc.IsPointerToMemory());
    // We copy the data into the right location in IL.
    const intptr_t length_in_bytes =
        marshaller.Location(arg_index).payload_type().SizeInBytes();

    body += LoadTypedDataBaseFromCompound();
    LocalVariable* typed_data_base = MakeTemporary("typed_data_base");

    auto* pointer_to_return =
        new (Z) NativeParameterInstr(marshaller, compiler::ffi::kResultIndex);
    Push(pointer_to_return);  // Address where return value should be stored.
    body <<= pointer_to_return;
    body += UnboxTruncate(kUnboxedFfiIntPtr);
    LocalVariable* unboxed_address = MakeTemporary("unboxed_address");

    body += LoadLocal(typed_data_base);
    body += LoadLocal(unboxed_address);
    body += CopyFromTypedDataBaseToUnboxedAddress(length_in_bytes);
    body += DropTempsPreserveTop(1);  // Keep address, drop typed_data_base.
  }
  return body;
}

Fragment FlowGraphBuilder::FfiConvertPrimitiveToDart(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index) {
  ASSERT(!marshaller.IsCompound(arg_index));

  Fragment body;
  if (marshaller.IsPointer(arg_index)) {
    body += Box(kUnboxedFfiIntPtr);
    body += FfiPointerFromAddress();
  } else if (marshaller.IsHandle(arg_index)) {
    body += UnwrapHandle();
  } else if (marshaller.IsVoid(arg_index)) {
    body += Drop();
    body += NullConstant();
  } else {
    if (marshaller.RequiresBitCast(arg_index)) {
      body += BitCast(
          marshaller.RepInFfiCall(marshaller.FirstDefinitionIndex(arg_index)),
          marshaller.RepInDart(arg_index));
    }

    body += Box(marshaller.RepInDart(arg_index));

    if (marshaller.IsBool(arg_index)) {
      body += IntToBool();
    }
  }
  return body;
}

Fragment FlowGraphBuilder::FfiConvertPrimitiveToNative(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index) {
  ASSERT(!marshaller.IsCompound(arg_index));

  Fragment body;
  if (marshaller.IsPointer(arg_index)) {
    // This can only be Pointer, so it is always safe to LoadUntagged.
    body += LoadUntagged(compiler::target::PointerBase::data_offset());
    body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
  } else if (marshaller.IsHandle(arg_index)) {
    body += WrapHandle();
  } else {
    if (marshaller.IsBool(arg_index)) {
      body += BoolToInt();
    }

    body += UnboxTruncate(marshaller.RepInDart(arg_index));
  }

  if (marshaller.RequiresBitCast(arg_index)) {
    body += BitCast(
        marshaller.RepInDart(arg_index),
        marshaller.RepInFfiCall(marshaller.FirstDefinitionIndex(arg_index)));
  }

  return body;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfFfiTrampoline(
    const Function& function) {
  switch (function.GetFfiFunctionKind()) {
    case FfiFunctionKind::kIsolateLocalStaticCallback:
    case FfiFunctionKind::kIsolateLocalClosureCallback:
      return BuildGraphOfSyncFfiCallback(function);
    case FfiFunctionKind::kAsyncCallback:
      return BuildGraphOfAsyncFfiCallback(function);
    case FfiFunctionKind::kCall:
      return BuildGraphOfFfiNative(function);
  }
  UNREACHABLE();
  return nullptr;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfFfiNative(const Function& function) {
  const intptr_t kClosureParameterOffset = 0;
  const intptr_t kFirstArgumentParameterOffset = kClosureParameterOffset + 1;

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto normal_entry = BuildFunctionEntry(graph_entry_);
  graph_entry_->set_normal_entry(normal_entry);

  PrologueInfo prologue_info(-1, -1);

  BlockEntryInstr* instruction_cursor =
      BuildPrologue(normal_entry, &prologue_info);

  Fragment function_body(instruction_cursor);
  function_body += CheckStackOverflowInPrologue(function.token_pos());

  const char* error = nullptr;
  const auto marshaller_ptr =
      compiler::ffi::CallMarshaller::FromFunction(Z, function, &error);
  // AbiSpecific integers can be incomplete causing us to not know the calling
  // convention. However, this is caught in asFunction in both JIT/AOT.
  RELEASE_ASSERT(error == nullptr);
  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;

  const bool signature_contains_handles = marshaller.ContainsHandles();

  // FFI trampolines are accessed via closures, so non-covariant argument types
  // and type arguments are either statically checked by the type system or
  // dynamically checked via dynamic closure call dispatchers.

  // Null check arguments before we go into the try catch, so that we don't
  // catch our own null errors.
  const intptr_t num_args = marshaller.num_args();
  for (intptr_t i = 0; i < num_args; i++) {
    if (marshaller.IsHandle(i)) {
      continue;
    }
    function_body += LoadLocal(
        parsed_function_->ParameterVariable(kFirstArgumentParameterOffset + i));
    // TODO(http://dartbug.com/47486): Support entry without checking for null.
    // Check for 'null'.
    function_body += CheckNullOptimized(
        String::ZoneHandle(
            Z, function.ParameterNameAt(kFirstArgumentParameterOffset + i)),
        CheckNullInstr::kArgumentError);
    function_body += StoreLocal(
        TokenPosition::kNoSource,
        parsed_function_->ParameterVariable(kFirstArgumentParameterOffset + i));
    function_body += Drop();
  }

  Fragment body;
  intptr_t try_handler_index = -1;
  if (signature_contains_handles) {
    // Wrap in Try catch to transition from Native to Generated on a throw from
    // the dart_api.
    try_handler_index = AllocateTryIndex();
    body += TryCatch(try_handler_index);
    ++try_depth_;
    // TODO(dartbug.com/48989): Remove scope for calls where we don't actually
    // need it.
    // We no longer need the scope for passing in Handle arguments, but the
    // native function might for instance be relying on this scope for Dart API.
    body += EnterHandleScope();
  }

  // Allocate typed data before FfiCall and pass it in to ffi call if needed.
  LocalVariable* typed_data = nullptr;
  if (marshaller.PassTypedData()) {
    body += IntConstant(marshaller.TypedDataSizeInBytes());
    body +=
        AllocateTypedData(TokenPosition::kNoSource, kTypedDataUint8ArrayCid);
    typed_data = MakeTemporary();
  }

  // Unbox and push the arguments.
  for (intptr_t i = 0; i < marshaller.num_args(); i++) {
    if (marshaller.IsCompound(i)) {
      body += FfiCallConvertCompoundArgumentToNative(
          parsed_function_->ParameterVariable(kFirstArgumentParameterOffset +
                                              i),
          marshaller, i);
    } else {
      body += LoadLocal(parsed_function_->ParameterVariable(
          kFirstArgumentParameterOffset + i));
      // FfiCallInstr specifies all handle locations as Stack, and will pass a
      // pointer to the stack slot as the native handle argument.
      // Therefore we do not need to wrap handles.
      if (!marshaller.IsHandle(i)) {
        body += FfiConvertPrimitiveToNative(marshaller, i);
      }
    }
  }

  // Push the function pointer, which is stored (as Pointer object) in the
  // first slot of the context.
  body +=
      LoadLocal(parsed_function_->ParameterVariable(kClosureParameterOffset));
  body += LoadNativeField(Slot::Closure_context());
  body += LoadNativeField(Slot::GetContextVariableSlotFor(
      thread_, *MakeImplicitClosureScope(
                    Z, Class::Handle(IG->object_store()->ffi_pointer_class()))
                    ->context_variables()[0]));

  // This can only be Pointer, so it is always safe to LoadUntagged.
  body += LoadUntagged(compiler::target::PointerBase::data_offset());
  body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);

  if (marshaller.PassTypedData()) {
    body += LoadLocal(typed_data);
  }

  body += FfiCall(marshaller);

  for (intptr_t i = 0; i < marshaller.num_args(); i++) {
    if (marshaller.IsPointer(i)) {
      body += LoadLocal(parsed_function_->ParameterVariable(
          kFirstArgumentParameterOffset + i));
      body += ReachabilityFence();
    }
  }

  const intptr_t num_defs = marshaller.NumReturnDefinitions();
  ASSERT(num_defs >= 1);
  auto defs = new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_defs);
  LocalVariable* def = MakeTemporary();
  defs->Add(def);

  if (marshaller.PassTypedData()) {
    // Drop call result, typed data with contents is already on the stack.
    body += Drop();
  }

  if (marshaller.IsCompound(compiler::ffi::kResultIndex)) {
    body += FfiCallConvertCompoundReturnToDart(marshaller,
                                               compiler::ffi::kResultIndex);
  } else {
    body += FfiConvertPrimitiveToDart(marshaller, compiler::ffi::kResultIndex);
  }

  if (signature_contains_handles) {
    // TODO(dartbug.com/48989): Remove scope for calls where we don't actually
    // need it.
    body += DropTempsPreserveTop(1);  // Drop api_local_scope.
    body += ExitHandleScope();
  }

  body += Return(TokenPosition::kNoSource);

  if (signature_contains_handles) {
    --try_depth_;
  }

  function_body += body;

  if (signature_contains_handles) {
    ++catch_depth_;
    Fragment catch_body =
        CatchBlockEntry(Array::empty_array(), try_handler_index,
                        /*needs_stacktrace=*/true, /*is_synthesized=*/true);

    // TODO(dartbug.com/48989): Remove scope for calls where we don't actually
    // need it.
    // TODO(41984): If we want to pass in the handle scope, move it out
    // of the try catch.
    catch_body += ExitHandleScope();

    catch_body += LoadLocal(CurrentException());
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += RethrowException(TokenPosition::kNoSource, try_handler_index);
    --catch_depth_;
  }

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

Fragment FlowGraphBuilder::LoadNativeArg(
    const compiler::ffi::CallbackMarshaller& marshaller,
    intptr_t arg_index) {
  const intptr_t num_defs = marshaller.NumDefinitions(arg_index);
  auto defs = new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_defs);

  Fragment fragment;
  for (intptr_t j = 0; j < num_defs; j++) {
    const intptr_t def_index = marshaller.DefinitionIndex(j, arg_index);
    auto* parameter = new (Z) NativeParameterInstr(marshaller, def_index);
    Push(parameter);
    fragment <<= parameter;
    LocalVariable* def = MakeTemporary();
    defs->Add(def);
  }

  if (marshaller.IsCompound(arg_index)) {
    fragment +=
        FfiCallbackConvertCompoundArgumentToDart(marshaller, arg_index, defs);
  } else {
    fragment += FfiConvertPrimitiveToDart(marshaller, arg_index);
  }
  return fragment;
}

FlowGraph* FlowGraphBuilder::BuildGraphOfSyncFfiCallback(
    const Function& function) {
  const char* error = nullptr;
  const auto marshaller_ptr =
      compiler::ffi::CallbackMarshaller::FromFunction(Z, function, &error);
  // AbiSpecific integers can be incomplete causing us to not know the calling
  // convention. However, this is caught fromFunction in both JIT/AOT.
  RELEASE_ASSERT(error == nullptr);
  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;
  const bool is_closure = function.GetFfiFunctionKind() ==
                          FfiFunctionKind::kIsolateLocalClosureCallback;

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto* const native_entry =
      new (Z) NativeEntryInstr(marshaller, graph_entry_, AllocateBlockId(),
                               CurrentTryIndex(), GetNextDeoptId());

  graph_entry_->set_normal_entry(native_entry);

  Fragment function_body(native_entry);
  function_body += CheckStackOverflowInPrologue(function.token_pos());

  // Wrap the entire method in a big try/catch. This is important to ensure that
  // the VM does not crash if the callback throws an exception.
  const intptr_t try_handler_index = AllocateTryIndex();
  Fragment body = TryCatch(try_handler_index);
  ++try_depth_;

  LocalVariable* closure = nullptr;
  if (is_closure) {
    // Load and unwrap closure persistent handle.
    body += LoadThread();
    body +=
        LoadUntagged(compiler::target::Thread::unboxed_runtime_arg_offset());
    body += RawLoadField(compiler::target::PersistentHandle::ptr_offset());
    closure = MakeTemporary();
  }

  // Box and push the arguments.
  for (intptr_t i = 0; i < marshaller.num_args(); i++) {
    body += LoadNativeArg(marshaller, i);
  }

  if (is_closure) {
    // Call the target. The +1 in the argument count is because the closure
    // itself is the first argument.
    const intptr_t argument_count = marshaller.num_args() + 1;
    body += LoadLocal(closure);
    if (!FLAG_precompiled_mode) {
      // The ClosureCallInstr() takes one explicit input (apart from arguments).
      // It uses it to find the target address (in AOT from
      // Closure::entry_point, in JIT from Closure::function_::entry_point).
      body += LoadNativeField(Slot::Closure_function());
    }
    body +=
        ClosureCall(Function::null_function(), TokenPosition::kNoSource,
                    /*type_args_len=*/0, argument_count, Array::null_array());
  } else {
    // Call the target.
    //
    // TODO(36748): Determine the hot-reload semantics of callbacks and update
    // the rebind-rule accordingly.
    body += StaticCall(TokenPosition::kNoSource,
                       Function::ZoneHandle(Z, function.FfiCallbackTarget()),
                       marshaller.num_args(), Array::empty_array(),
                       ICData::kNoRebind);
  }

  if (marshaller.IsVoid(compiler::ffi::kResultIndex)) {
    body += Drop();
    body += IntConstant(0);
  } else if (!marshaller.IsHandle(compiler::ffi::kResultIndex)) {
    body += CheckNullOptimized(
        String::ZoneHandle(Z, Symbols::New(H.thread(), "return_value")),
        CheckNullInstr::kArgumentError);
  }

  if (marshaller.IsCompound(compiler::ffi::kResultIndex)) {
    body += FfiCallbackConvertCompoundReturnToNative(
        marshaller, compiler::ffi::kResultIndex);
  } else {
    body +=
        FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex);
  }

  body += NativeReturn(marshaller);

  --try_depth_;
  function_body += body;

  ++catch_depth_;
  Fragment catch_body = CatchBlockEntry(Array::empty_array(), try_handler_index,
                                        /*needs_stacktrace=*/false,
                                        /*is_synthesized=*/true);

  // Return the "exceptional return" value given in 'fromFunction'.
  //
  // For pointer and void return types, the exceptional return is always null --
  // return 0 instead.
  if (marshaller.IsPointer(compiler::ffi::kResultIndex) ||
      marshaller.IsVoid(compiler::ffi::kResultIndex)) {
    ASSERT(function.FfiCallbackExceptionalReturn() == Object::null());
    catch_body += UnboxedIntConstant(0, kUnboxedFfiIntPtr);
  } else if (marshaller.IsHandle(compiler::ffi::kResultIndex)) {
    catch_body += UnhandledException();
    catch_body +=
        FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex);

  } else if (marshaller.IsCompound(compiler::ffi::kResultIndex)) {
    ASSERT(function.FfiCallbackExceptionalReturn() == Object::null());
    // Manufacture empty result.
    const intptr_t size =
        Utils::RoundUp(marshaller.Location(compiler::ffi::kResultIndex)
                           .payload_type()
                           .SizeInBytes(),
                       compiler::target::kWordSize);
    catch_body += IntConstant(size);
    catch_body +=
        AllocateTypedData(TokenPosition::kNoSource, kTypedDataUint8ArrayCid);
    catch_body += WrapTypedDataBaseInCompound(
        AbstractType::Handle(Z, marshaller.CType(compiler::ffi::kResultIndex)));
    catch_body += FfiCallbackConvertCompoundReturnToNative(
        marshaller, compiler::ffi::kResultIndex);

  } else {
    catch_body += Constant(
        Instance::ZoneHandle(Z, function.FfiCallbackExceptionalReturn()));
    catch_body +=
        FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex);
  }

  catch_body += NativeReturn(marshaller);
  --catch_depth_;

  PrologueInfo prologue_info(-1, -1);
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

FlowGraph* FlowGraphBuilder::BuildGraphOfAsyncFfiCallback(
    const Function& function) {
  const char* error = nullptr;
  const auto marshaller_ptr =
      compiler::ffi::CallbackMarshaller::FromFunction(Z, function, &error);
  // AbiSpecific integers can be incomplete causing us to not know the calling
  // convention. However, this is caught fromFunction in both JIT/AOT.
  RELEASE_ASSERT(error == nullptr);
  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;

  // Currently all async FFI callbacks return void. This is enforced by the
  // frontend.
  ASSERT(marshaller.IsVoid(compiler::ffi::kResultIndex));

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto* const native_entry =
      new (Z) NativeEntryInstr(marshaller, graph_entry_, AllocateBlockId(),
                               CurrentTryIndex(), GetNextDeoptId());

  graph_entry_->set_normal_entry(native_entry);

  Fragment function_body(native_entry);
  function_body += CheckStackOverflowInPrologue(function.token_pos());

  // Wrap the entire method in a big try/catch. This is important to ensure that
  // the VM does not crash if the callback throws an exception.
  const intptr_t try_handler_index = AllocateTryIndex();
  Fragment body = TryCatch(try_handler_index);
  ++try_depth_;

  // Box and push the arguments into an array, to be sent to the target.
  body += Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
  body += IntConstant(marshaller.num_args());
  body += CreateArray();
  LocalVariable* array = MakeTemporary();
  for (intptr_t i = 0; i < marshaller.num_args(); i++) {
    body += LoadLocal(array);
    body += IntConstant(i);
    body += LoadNativeArg(marshaller, i);
    body += StoreIndexed(kArrayCid);
  }

  // Send the arg array to the target. The arg array is still on the stack.
  body += Call1ArgStub(TokenPosition::kNoSource,
                       Call1ArgStubInstr::StubId::kFfiAsyncCallbackSend);

  // All async FFI callbacks return void, so just return 0.
  body += Drop();
  body += UnboxedIntConstant(0, kUnboxedFfiIntPtr);
  body += NativeReturn(marshaller);

  --try_depth_;
  function_body += body;

  ++catch_depth_;
  Fragment catch_body = CatchBlockEntry(Array::empty_array(), try_handler_index,
                                        /*needs_stacktrace=*/false,
                                        /*is_synthesized=*/true);

  // This catch indicates there's been some sort of error, but async callbacks
  // are fire-and-forget, and we don't guarantee delivery. So just return 0.
  catch_body += UnboxedIntConstant(0, kUnboxedFfiIntPtr);
  catch_body += NativeReturn(marshaller);
  --catch_depth_;

  PrologueInfo prologue_info(-1, -1);
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

void FlowGraphBuilder::SetCurrentTryCatchBlock(TryCatchBlock* try_catch_block) {
  try_catch_block_ = try_catch_block;
  SetCurrentTryIndex(try_catch_block == nullptr ? kInvalidTryIndex
                                                : try_catch_block->try_index());
}

Fragment FlowGraphBuilder::NullAssertion(LocalVariable* variable) {
  Fragment code;
  if (!variable->static_type().NeedsNullAssertion()) {
    return code;
  }

  TargetEntryInstr* then;
  TargetEntryInstr* otherwise;

  code += LoadLocal(variable);
  code += NullConstant();
  code += BranchIfEqual(&then, &otherwise);

  const Script& script =
      Script::Handle(Z, parsed_function_->function().script());
  intptr_t line = -1;
  intptr_t column = -1;
  script.GetTokenLocation(variable->token_pos(), &line, &column);

  // Build equivalent of `throw _AssertionError._throwNewNullAssertion(name)`
  // expression. We build throw (even through _throwNewNullAssertion already
  // throws) because call is not a valid last instruction for the block.
  // Blocks can only terminate with explicit control flow instructions
  // (Branch, Goto, Return or Throw).
  Fragment null_code(then);
  null_code += Constant(variable->name());
  null_code += IntConstant(line);
  null_code += IntConstant(column);
  null_code += StaticCall(variable->token_pos(),
                          ThrowNewNullAssertionFunction(), 3, ICData::kStatic);
  null_code += ThrowException(TokenPosition::kNoSource);
  null_code += Drop();

  return Fragment(code.entry, otherwise);
}

Fragment FlowGraphBuilder::BuildNullAssertions() {
  Fragment code;
  if (IG->null_safety() || !IG->asserts() || !FLAG_null_assertions) {
    return code;
  }

  const Function& dart_function = parsed_function_->function();
  for (intptr_t i = dart_function.NumImplicitParameters(),
                n = dart_function.NumParameters();
       i < n; ++i) {
    LocalVariable* variable = parsed_function_->ParameterVariable(i);
    code += NullAssertion(variable);
  }
  return code;
}

const Function& FlowGraphBuilder::ThrowNewNullAssertionFunction() {
  if (throw_new_null_assertion_.IsNull()) {
    const Class& klass = Class::ZoneHandle(
        Z, Library::LookupCoreClass(Symbols::AssertionError()));
    ASSERT(!klass.IsNull());
    const auto& error = klass.EnsureIsFinalized(H.thread());
    ASSERT(error == Error::null());
    throw_new_null_assertion_ = klass.LookupStaticFunctionAllowPrivate(
        Symbols::ThrowNewNullAssertion());
    ASSERT(!throw_new_null_assertion_.IsNull());
  }
  return throw_new_null_assertion_;
}

const Function& FlowGraphBuilder::PrependTypeArgumentsFunction() {
  if (prepend_type_arguments_.IsNull()) {
    const auto& dart_internal = Library::Handle(Z, Library::InternalLibrary());
    prepend_type_arguments_ = dart_internal.LookupFunctionAllowPrivate(
        Symbols::PrependTypeArguments());
    ASSERT(!prepend_type_arguments_.IsNull());
  }
  return prepend_type_arguments_;
}

Fragment FlowGraphBuilder::BuildIntegerHashCode(bool smi) {
  Fragment body;
  Value* unboxed_value = Pop();
  HashIntegerOpInstr* hash =
      new HashIntegerOpInstr(unboxed_value, smi, DeoptId::kNone);
  Push(hash);
  body <<= hash;
  return body;
}

Fragment FlowGraphBuilder::BuildDoubleHashCode() {
  Fragment body;
  Value* double_value = Pop();
  HashDoubleOpInstr* hash = new HashDoubleOpInstr(double_value, DeoptId::kNone);
  Push(hash);
  body <<= hash;
  body += Box(kUnboxedInt64);
  return body;
}

SwitchHelper::SwitchHelper(Zone* zone,
                           TokenPosition position,
                           bool is_exhaustive,
                           const AbstractType& expression_type,
                           SwitchBlock* switch_block,
                           intptr_t case_count)
    : zone_(zone),
      position_(position),
      is_exhaustive_(is_exhaustive),
      expression_type_(expression_type),
      switch_block_(switch_block),
      case_count_(case_count),
      case_bodies_(case_count),
      case_expression_counts_(case_count),
      expressions_(case_count),
      sorted_expressions_(case_count) {
  case_expression_counts_.FillWith(0, 0, case_count);

  if (expression_type.nullability() == Nullability::kNonNullable) {
    if (expression_type.IsIntType() || expression_type.IsSmiType()) {
      is_optimizable_ = true;
    } else if (expression_type.HasTypeClass() &&
               Class::Handle(zone_, expression_type.type_class())
                   .is_enum_class()) {
      is_optimizable_ = true;
      is_enum_switch_ = true;
    }
  }
}

int64_t SwitchHelper::ExpressionRange() const {
  const int64_t min = expression_min().AsInt64Value();
  const int64_t max = expression_max().AsInt64Value();
  ASSERT(min <= max);
  const uint64_t diff = static_cast<uint64_t>(max) - static_cast<uint64_t>(min);
  // Saturate to avoid overflow.
  if (diff > static_cast<uint64_t>(kMaxInt64 - 1)) {
    return kMaxInt64;
  }
  return static_cast<int64_t>(diff + 1);
}

bool SwitchHelper::RequiresLowerBoundCheck() const {
  if (is_enum_switch()) {
    if (expression_min().IsZero()) {
      // Enum indexes are always positive.
      return false;
    }
  }
  return true;
}

bool SwitchHelper::RequiresUpperBoundCheck() const {
  if (is_enum_switch()) {
    return has_default() || !is_exhaustive();
  }
  return true;
}

SwitchDispatch SwitchHelper::SelectDispatchStrategy() {
  // For small to medium-sized switches, binary search is faster than a
  // jump table.
  // Please update runtime/tests/vm/dart/optimized_switch_test.dart
  // when changing this constant.
  const intptr_t kJumpTableMinExpressions = 16;
  // This limit comes from IndirectGotoInstr.
  // Realistically, the current limit should never be hit by any code.
  const intptr_t kJumpTableMaxSize = kMaxInt32;
  // Sometimes the switch expressions don't cover a contiguous range.
  // If the ratio of holes to expressions is too great we fall back to a
  // binary search to avoid code size explosion.
  const double kJumpTableMaxHolesRatio = 1.0;

  if (!is_optimizable() || expressions().is_empty()) {
    // The switch is not optimizable, so we can only use linear scan.
    return kSwitchDispatchLinearScan;
  }

  if (!CompilerState::Current().is_aot()) {
    // JIT mode supports hot-reload, which currently prevents us from
    // enabling optimized switches.
    return kSwitchDispatchLinearScan;
  }

  if (FLAG_force_switch_dispatch_type == kSwitchDispatchLinearScan) {
    return kSwitchDispatchLinearScan;
  }

  PrepareForOptimizedSwitch();

  if (!is_optimizable()) {
    // While preparing for an optimized switch we might have discovered that
    // the switch is not optimizable after all.
    return kSwitchDispatchLinearScan;
  }

  if (FLAG_force_switch_dispatch_type == kSwitchDispatchBinarySearch) {
    return kSwitchDispatchBinarySearch;
  }

  const int64_t range = ExpressionRange();
  if (range > kJumpTableMaxSize) {
    return kSwitchDispatchBinarySearch;
  }

  const intptr_t num_expressions = expressions().length();
  ASSERT(num_expressions <= range);

  const intptr_t max_holes = num_expressions * kJumpTableMaxHolesRatio;
  const int64_t holes = range - num_expressions;

  if (FLAG_force_switch_dispatch_type != kSwitchDispatchJumpTable) {
    if (num_expressions < kJumpTableMinExpressions) {
      return kSwitchDispatchBinarySearch;
    }

    if (holes > max_holes) {
      return kSwitchDispatchBinarySearch;
    }
  }

  // After this point we will use a jump table.

  // In the general case, bounds checks are required before a jump table
  // to handle all possible integer values.
  // For enums, the set of possible index values is known and much smaller
  // than the set of all possible integer values. A jump table that covers
  // either or both bounds of the range of index values requires only one or
  // no bounds checks.
  // If the expressions of an enum switch don't cover the full range of
  // values we can try to extend the jump table to cover the full range, but
  // not beyond kJumpTableMaxHolesRatio.
  // The count of enum values is not available when the flow graph is
  // constructed. The lower bound is always 0 so eliminating the lower
  // bound check is still possible by extending expression_min to 0.
  //
  // In the case of an integer switch we try to extend expression_min to 0
  // for a different reason.
  // If the range starts at zero it directly maps to the jump table
  // and we don't need to adjust the switch variable before the
  // jump table.
  if (expression_min().AsInt64Value() > 0) {
    const intptr_t holes_budget = Utils::Minimum(
        // Holes still available.
        max_holes - holes,
        // Entries left in the jump table.
        kJumpTableMaxSize - range);

    const int64_t required_holes = expression_min().AsInt64Value();
    if (required_holes <= holes_budget) {
      expression_min_ = &Object::smi_zero();
    }
  }

  return kSwitchDispatchJumpTable;
}

void SwitchHelper::PrepareForOptimizedSwitch() {
  // Find the min and max of integer representations of expressions.
  // We also populate SwitchExpressions.integer for later use.
  const Field* enum_index_field = nullptr;
  for (intptr_t i = 0; i < expressions_.length(); ++i) {
    SwitchExpression& expression = expressions_[i];
    sorted_expressions_.Add(&expression);

    const Instance& value = expression.value();
    const Integer* integer = nullptr;
    if (is_enum_switch()) {
      if (enum_index_field == nullptr) {
        enum_index_field =
            &Field::Handle(zone_, IG->object_store()->enum_index_field());
      }
      integer = &Integer::ZoneHandle(
          zone_, Integer::RawCast(value.GetField(*enum_index_field)));
    } else {
      integer = &Integer::Cast(value);
    }
    expression.set_integer(*integer);
    if (i == 0) {
      expression_min_ = integer;
      expression_max_ = integer;
    } else {
      if (expression_min_->CompareWith(*integer) > 0) {
        expression_min_ = integer;
      }
      if (expression_max_->CompareWith(*integer) < 0) {
        expression_max_ = integer;
      }
    }
  }

  // Sort expressions by their integer value.
  sorted_expressions_.Sort(
      [](SwitchExpression* const* a, SwitchExpression* const* b) {
        return (*a)->integer().CompareWith((*b)->integer());
      });

  // Check that there are no duplicate case expressions.
  // Duplicate expressions are allowed in switch statements, but
  // optimized switches don't implemented them.
  for (intptr_t i = 0; i < sorted_expressions_.length() - 1; ++i) {
    const SwitchExpression& a = *sorted_expressions_.At(i);
    const SwitchExpression& b = *sorted_expressions_.At(i + 1);
    if (a.integer().Equals(b.integer())) {
      is_optimizable_ = false;
      break;
    }
  }
}

void SwitchHelper::AddExpression(intptr_t case_index,
                                 TokenPosition position,
                                 const Instance& value) {
  case_expression_counts_[case_index]++;

  expressions_.Add(SwitchExpression(case_index, position, value));

  if (is_optimizable_) {
    // Check the type of the case expression for use in an optimized switch.
    if (!value.IsInstanceOf(expression_type_, Object::null_type_arguments(),
                            Object::null_type_arguments())) {
      is_optimizable_ = false;
    }
  }
}

}  // namespace kernel

}  // namespace dart
