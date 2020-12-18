// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_to_il.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/aot/precompiler.h"
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
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

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
      for_in_depth_(0),
      block_expression_depth_(0),
      graph_entry_(NULL),
      scopes_(NULL),
      breakable_block_(NULL),
      switch_block_(NULL),
      try_catch_block_(NULL),
      try_finally_block_(NULL),
      catch_block_(NULL),
      prepend_type_arguments_(Function::ZoneHandle(zone_)),
      throw_new_null_assertion_(Function::ZoneHandle(zone_)) {
  const Script& script =
      Script::Handle(Z, parsed_function->function().script());
  H.InitFromScript(script);
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
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Slot::Context_parent(),
                         StoreInstanceFieldInstr::Kind::kInitializing);
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
        Function::Handle(Z, parsed_function_->function().raw());
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
    ASSERT(parsed_function_->function_type_arguments() != NULL);
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
    instructions += StoreInstanceField(
        TokenPosition::kNoSource,
        Slot::GetContextVariableSlotFor(thread_, *exception_var));
  }
  if (stacktrace_var->is_captured()) {
    instructions += LoadLocal(context_variable);
    instructions += LoadLocal(raw_stacktrace_var);
    instructions += StoreInstanceField(
        TokenPosition::kNoSource,
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
  JoinEntryInstr* entry = new (Z)
      JoinEntryInstr(AllocateBlockId(), try_handler_index, GetNextDeoptId());
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
    bool receiver_is_not_smi) {
  const intptr_t total_count = argument_count + (type_args_len > 0 ? 1 : 0);
  InputsArray* arguments = GetArguments(total_count);
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      InstructionSource(position), name, kind, arguments, type_args_len,
      argument_names, checked_argument_count, ic_data_array_, GetNextDeoptId(),
      interface_target, tearoff_interface_target);
  if ((result_type != NULL) && !result_type->IsTrivial()) {
    call->SetResultType(Z, result_type->ToCompileType(Z));
  }
  if (use_unchecked_entry) {
    call->set_entry_kind(Code::EntryKind::kUnchecked);
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

  FfiCallInstr* const call =
      new (Z) FfiCallInstr(Z, GetNextDeoptId(), marshaller);

  for (intptr_t i = call->InputCount() - 1; i >= 0; --i) {
    call->SetInputAt(i, Pop());
  }

  Push(call);
  body <<= call;

  return body;
}

Fragment FlowGraphBuilder::ThrowException(TokenPosition position) {
  Fragment instructions;
  Value* exception = Pop();
  instructions += Fragment(new (Z) ThrowInstr(InstructionSource(position),
                                              GetNextDeoptId(), exception))
                      .closed();
  // Use its side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  return instructions;
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

Fragment FlowGraphBuilder::ThrowLateInitializationError(
    TokenPosition position,
    const char* throw_method_name,
    const String& name) {
  const Class& klass =
      Class::ZoneHandle(Z, Library::LookupCoreClass(Symbols::LateError()));
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
  TargetEntryInstr *is_uninitialized, *is_initialized;
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
    instructions += StoreInstanceFieldGuarded(field);
  }

  return instructions;
}

Fragment FlowGraphBuilder::NativeCall(const String* name,
                                      const Function* function) {
  InlineBailout("kernel::FlowGraphBuilder::NativeCall");
  const intptr_t num_args =
      function->NumParameters() + (function->IsGeneric() ? 1 : 0);
  InputsArray* arguments = GetArguments(num_args);
  NativeCallInstr* call = new (Z)
      NativeCallInstr(name, function, FLAG_link_natives_lazily,
                      InstructionSource(function->end_token_pos()), arguments);
  Push(call);
  return Fragment(call);
}

Fragment FlowGraphBuilder::Return(TokenPosition position,
                                  bool omit_result_type_check,
                                  intptr_t yield_index) {
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

  instructions += BaseFlowGraphBuilder::Return(position, yield_index);

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
    ASSERT((result_type == NULL) || (result_type->cid == kDynamicCid) ||
           (result_type->cid == call->result_cid()));
    return;
  }
  if ((result_type != NULL) && !result_type->IsTrivial()) {
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
  InputsArray* arguments = GetArguments(total_count);
  StaticCallInstr* call = new (Z) StaticCallInstr(
      InstructionSource(position), target, type_args_count, argument_names,
      arguments, ic_data_array_, GetNextDeoptId(), rebind_rule);
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
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  const Class& cls =
      Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
  ASSERT(!cls.IsNull());
  const Function& function = Function::ZoneHandle(
      Z, Resolver::ResolveStatic(
             cls, Library::PrivateCoreLibName(Symbols::InterpolateSingle()),
             kTypeArgsLen, kNumberOfArguments, kNoArgumentNames));
  Fragment instructions;
  instructions +=
      StaticCall(position, function, /* argument_count = */ 1, ICData::kStatic);
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

  // Create instance of _FallThroughError
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

Fragment FlowGraphBuilder::ThrowNoSuchMethodError(const Function& target) {
  const Class& klass = Class::ZoneHandle(
      Z, Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  ASSERT(!klass.IsNull());
  const auto& error = klass.EnsureIsFinalized(H.thread());
  ASSERT(error == Error::null());
  const Function& throw_function = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!throw_function.IsNull());

  Fragment instructions;

  const Class& owner = Class::Handle(Z, target.Owner());
  AbstractType& receiver = AbstractType::ZoneHandle();
  InvocationMirror::Kind kind = InvocationMirror::Kind::kMethod;
  if (target.IsImplicitGetterFunction() || target.IsGetterFunction()) {
    kind = InvocationMirror::kGetter;
  } else if (target.IsImplicitSetterFunction() || target.IsSetterFunction()) {
    kind = InvocationMirror::kSetter;
  }
  InvocationMirror::Level level;
  if (owner.IsTopLevel()) {
    level = InvocationMirror::Level::kTopLevel;
  } else {
    receiver = owner.RareType();
    if (target.kind() == FunctionLayout::kConstructor) {
      level = InvocationMirror::Level::kConstructor;
    } else {
      level = InvocationMirror::Level::kStatic;
    }
  }

  // Call NoSuchMethodError._throwNew static function.
  instructions += Constant(receiver);                              // receiver
  instructions += Constant(String::ZoneHandle(Z, target.name()));  // memberName
  instructions += IntConstant(InvocationMirror::EncodeType(level, kind));
  instructions += IntConstant(0);  // type arguments length
  instructions += NullConstant();  // type arguments
  instructions += NullConstant();  // arguments
  instructions += NullConstant();  // argumentNames

  instructions += StaticCall(TokenPosition::kNoSource, throw_function,
                             /* argument_count = */ 7, ICData::kStatic);

  // Properly close graph with a ThrowInstr, although it is not executed.
  instructions += ThrowException(TokenPosition::kNoSource);
  instructions += Drop();

  return instructions;
}

LocalVariable* FlowGraphBuilder::LookupVariable(intptr_t kernel_offset) {
  LocalVariable* local = scopes_->locals.Lookup(kernel_offset);
  ASSERT(local != NULL);
  return local;
}

FlowGraph* FlowGraphBuilder::BuildGraph() {
  const Function& function = parsed_function_->function();

#ifdef DEBUG
  // If we attached the native name to the function after it's creation (namely
  // after reading the constant table from the kernel blob), we must have done
  // so before building flow graph for the functions (since FGB depends needs
  // the native name to be there).
  const Script& script = Script::Handle(Z, function.script());
  const KernelProgramInfo& info =
      KernelProgramInfo::Handle(script.kernel_program_info());
  ASSERT(info.IsNull() ||
         info.potential_natives() == GrowableObjectArray::null());

  // Check that all functions that are explicitly marked as recognized with the
  // vm:recognized annotation are in fact recognized. The check can't be done on
  // function creation, since the recognized status isn't set until later.
  if ((function.IsRecognized() !=
       MethodRecognizer::IsMarkedAsRecognized(function)) &&
      !function.IsDynamicInvocationForwarder()) {
    if (function.IsRecognized()) {
      FATAL1(
          "Recognized method %s is not marked with the vm:recognized pragma.",
          function.ToQualifiedCString());
    } else {
      FATAL1(
          "Non-recognized method %s is marked with the vm:recognized pragma.",
          function.ToQualifiedCString());
    }
  }
#endif

  auto& kernel_data = ExternalTypedData::Handle(Z, function.KernelData());
  intptr_t kernel_data_program_offset = function.KernelDataProgramOffset();

  StreamingFlowGraphBuilder streaming_flow_graph_builder(
      this, kernel_data, kernel_data_program_offset);
  return streaming_flow_graph_builder.BuildGraph();
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
  body += NativeCall(&name, &function);
  // We typecheck results of native calls for type safety.
  body +=
      Return(TokenPosition::kNoSource, /* omit_result_type_check = */ false);
  return body;
}

bool FlowGraphBuilder::IsRecognizedMethodForFlowGraph(
    const Function& function) {
  const MethodRecognizer::Kind kind = function.recognized_kind();

  switch (kind) {
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
    case MethodRecognizer::kFfiLoadInt8:
    case MethodRecognizer::kFfiLoadInt16:
    case MethodRecognizer::kFfiLoadInt32:
    case MethodRecognizer::kFfiLoadInt64:
    case MethodRecognizer::kFfiLoadUint8:
    case MethodRecognizer::kFfiLoadUint16:
    case MethodRecognizer::kFfiLoadUint32:
    case MethodRecognizer::kFfiLoadUint64:
    case MethodRecognizer::kFfiLoadIntPtr:
    case MethodRecognizer::kFfiLoadFloat:
    case MethodRecognizer::kFfiLoadDouble:
    case MethodRecognizer::kFfiLoadPointer:
    case MethodRecognizer::kFfiStoreInt8:
    case MethodRecognizer::kFfiStoreInt16:
    case MethodRecognizer::kFfiStoreInt32:
    case MethodRecognizer::kFfiStoreInt64:
    case MethodRecognizer::kFfiStoreUint8:
    case MethodRecognizer::kFfiStoreUint16:
    case MethodRecognizer::kFfiStoreUint32:
    case MethodRecognizer::kFfiStoreUint64:
    case MethodRecognizer::kFfiStoreIntPtr:
    case MethodRecognizer::kFfiStoreFloat:
    case MethodRecognizer::kFfiStoreDouble:
    case MethodRecognizer::kFfiStorePointer:
    case MethodRecognizer::kFfiFromAddress:
    case MethodRecognizer::kFfiGetAddress:
    case MethodRecognizer::kObjectEquals:
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
    case MethodRecognizer::kGrowableArrayLength:
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
    case MethodRecognizer::kTypedListLength:
    case MethodRecognizer::kTypedListViewLength:
    case MethodRecognizer::kByteDataViewLength:
    case MethodRecognizer::kByteDataViewOffsetInBytes:
    case MethodRecognizer::kTypedDataViewOffsetInBytes:
    case MethodRecognizer::kByteDataViewTypedData:
    case MethodRecognizer::kTypedDataViewTypedData:
    case MethodRecognizer::kClassIDgetID:
    case MethodRecognizer::kGrowableArrayCapacity:
    case MethodRecognizer::kListFactory:
    case MethodRecognizer::kObjectArrayAllocate:
    case MethodRecognizer::kCopyRangeFromUint8ListToOneByteString:
    case MethodRecognizer::kLinkedHashMap_getIndex:
    case MethodRecognizer::kLinkedHashMap_setIndex:
    case MethodRecognizer::kLinkedHashMap_getData:
    case MethodRecognizer::kLinkedHashMap_setData:
    case MethodRecognizer::kLinkedHashMap_getHashMask:
    case MethodRecognizer::kLinkedHashMap_setHashMask:
    case MethodRecognizer::kLinkedHashMap_getUsedData:
    case MethodRecognizer::kLinkedHashMap_setUsedData:
    case MethodRecognizer::kLinkedHashMap_getDeletedKeys:
    case MethodRecognizer::kLinkedHashMap_setDeletedKeys:
    case MethodRecognizer::kWeakProperty_getKey:
    case MethodRecognizer::kWeakProperty_setKey:
    case MethodRecognizer::kWeakProperty_getValue:
    case MethodRecognizer::kWeakProperty_setValue:
    case MethodRecognizer::kFfiAbi:
    case MethodRecognizer::kReachabilityFence:
    case MethodRecognizer::kUtf8DecoderScan:
      return true;
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
    case MethodRecognizer::kTypedData_ByteDataView_factory:
      body += BuildTypedDataViewFactoryConstructor(function, kByteDataViewCid);
      break;
    case MethodRecognizer::kTypedData_Int8ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(function,
                                                   kTypedDataInt8ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Uint8ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(function,
                                                   kTypedDataUint8ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Uint8ClampedArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataUint8ClampedArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Int16ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(function,
                                                   kTypedDataInt16ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Uint16ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataUint16ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Int32ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(function,
                                                   kTypedDataInt32ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Uint32ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataUint32ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Int64ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(function,
                                                   kTypedDataInt64ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Uint64ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataUint64ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Float32ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataFloat32ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Float64ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataFloat64ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Float32x4ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataFloat32x4ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Int32x4ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataInt32x4ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Float64x2ArrayView_factory:
      body += BuildTypedDataViewFactoryConstructor(
          function, kTypedDataFloat64x2ArrayViewCid);
      break;
    case MethodRecognizer::kTypedData_Int8Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataInt8ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Uint8Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataUint8ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Uint8ClampedArray_factory:
      body += BuildTypedDataFactoryConstructor(function,
                                               kTypedDataUint8ClampedArrayCid);
      break;
    case MethodRecognizer::kTypedData_Int16Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataInt16ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Uint16Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataUint16ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Int32Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataInt32ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Uint32Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataUint32ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Int64Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataInt64ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Uint64Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataUint64ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Float32Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataFloat32ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Float64Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataFloat64ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Float32x4Array_factory:
      body += BuildTypedDataFactoryConstructor(function,
                                               kTypedDataFloat32x4ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Int32x4Array_factory:
      body +=
          BuildTypedDataFactoryConstructor(function, kTypedDataInt32x4ArrayCid);
      break;
    case MethodRecognizer::kTypedData_Float64x2Array_factory:
      body += BuildTypedDataFactoryConstructor(function,
                                               kTypedDataFloat64x2ArrayCid);
      break;

    case MethodRecognizer::kObjectEquals:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StrictCompare(Token::kEQ_STRICT);
      break;
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::String_length());
      if (kind == MethodRecognizer::kStringBaseIsEmpty) {
        body += IntConstant(0);
        body += StrictCompare(Token::kEQ_STRICT);
      }
      break;
    case MethodRecognizer::kGrowableArrayLength:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::GrowableObjectArray_length());
      break;
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::Array_length());
      break;
    case MethodRecognizer::kTypedListLength:
    case MethodRecognizer::kTypedListViewLength:
    case MethodRecognizer::kByteDataViewLength:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::TypedDataBase_length());
      break;
    case MethodRecognizer::kByteDataViewOffsetInBytes:
    case MethodRecognizer::kTypedDataViewOffsetInBytes:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::TypedDataView_offset_in_bytes());
      break;
    case MethodRecognizer::kByteDataViewTypedData:
    case MethodRecognizer::kTypedDataViewTypedData:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::TypedDataView_data());
      break;
    case MethodRecognizer::kClassIDgetID:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadClassId();
      break;
    case MethodRecognizer::kGrowableArrayCapacity:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::GrowableObjectArray_data());
      body += LoadNativeField(Slot::Array_length());
      break;
    case MethodRecognizer::kListFactory: {
      ASSERT(function.IsFactory() && (function.NumParameters() == 2) &&
             function.HasOptionalParameters());
      // factory List<E>([int length]) {
      //   return (:arg_desc.positional_count == 2) ? new _List<E>(length)
      //                                            : new _GrowableList<E>(0);
      // }
      const Library& core_lib = Library::Handle(Z, Library::CoreLibrary());

      TargetEntryInstr *allocate_non_growable, *allocate_growable;

      body += LoadArgDescriptor();
      body += LoadNativeField(Slot::ArgumentsDescriptor_positional_count());
      body += IntConstant(2);
      body += BranchIfStrictEqual(&allocate_non_growable, &allocate_growable);

      JoinEntryInstr* join = BuildJoinEntry();

      {
        const Class& cls = Class::Handle(
            Z, core_lib.LookupClass(
                   Library::PrivateCoreLibName(Symbols::_List())));
        ASSERT(!cls.IsNull());
        const Function& func = Function::ZoneHandle(
            Z, cls.LookupFactoryAllowPrivate(Symbols::_ListFactory()));
        ASSERT(!func.IsNull());

        Fragment allocate(allocate_non_growable);
        allocate += LoadLocal(parsed_function_->RawParameterVariable(0));
        allocate += LoadLocal(parsed_function_->RawParameterVariable(1));
        allocate +=
            StaticCall(TokenPosition::kNoSource, func, 2, ICData::kStatic);
        allocate += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->expression_temp_var());
        allocate += Drop();
        allocate += Goto(join);
      }

      {
        const Class& cls = Class::Handle(
            Z, core_lib.LookupClass(
                   Library::PrivateCoreLibName(Symbols::_GrowableList())));
        ASSERT(!cls.IsNull());
        const Function& func = Function::ZoneHandle(
            Z, cls.LookupFactoryAllowPrivate(Symbols::_GrowableListFactory()));
        ASSERT(!func.IsNull());

        Fragment allocate(allocate_growable);
        allocate += LoadLocal(parsed_function_->RawParameterVariable(0));
        allocate += IntConstant(0);
        allocate +=
            StaticCall(TokenPosition::kNoSource, func, 2, ICData::kStatic);
        allocate += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->expression_temp_var());
        allocate += Drop();
        allocate += Goto(join);
      }

      body = Fragment(body.entry, join);
      body += LoadLocal(parsed_function_->expression_temp_var());
      break;
    }
    case MethodRecognizer::kObjectArrayAllocate:
      ASSERT(function.IsFactory() && (function.NumParameters() == 2));
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += CreateArray();
      break;
    case MethodRecognizer::kCopyRangeFromUint8ListToOneByteString:
      ASSERT(function.NumParameters() == 5);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += LoadLocal(parsed_function_->RawParameterVariable(2));
      body += LoadLocal(parsed_function_->RawParameterVariable(3));
      body += LoadLocal(parsed_function_->RawParameterVariable(4));
      body += MemoryCopy(kTypedDataUint8ArrayCid, kOneByteStringCid);
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getIndex:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::LinkedHashMap_index());
      break;
    case MethodRecognizer::kLinkedHashMap_setIndex:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 Slot::LinkedHashMap_index());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getData:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::LinkedHashMap_data());
      break;
    case MethodRecognizer::kLinkedHashMap_setData:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 Slot::LinkedHashMap_data());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getHashMask:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::LinkedHashMap_hash_mask());
      break;
    case MethodRecognizer::kLinkedHashMap_setHashMask:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(
          TokenPosition::kNoSource, Slot::LinkedHashMap_hash_mask(),
          StoreInstanceFieldInstr::Kind::kOther, kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getUsedData:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::LinkedHashMap_used_data());
      break;
    case MethodRecognizer::kLinkedHashMap_setUsedData:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(
          TokenPosition::kNoSource, Slot::LinkedHashMap_used_data(),
          StoreInstanceFieldInstr::Kind::kOther, kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getDeletedKeys:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::LinkedHashMap_deleted_keys());
      break;
    case MethodRecognizer::kLinkedHashMap_setDeletedKeys:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(
          TokenPosition::kNoSource, Slot::LinkedHashMap_deleted_keys(),
          StoreInstanceFieldInstr::Kind::kOther, kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kWeakProperty_getKey:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::WeakProperty_key());
      break;
    case MethodRecognizer::kWeakProperty_setKey:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 Slot::WeakProperty_key());
      body += NullConstant();
      break;
    case MethodRecognizer::kWeakProperty_getValue:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadNativeField(Slot::WeakProperty_value());
      break;
    case MethodRecognizer::kWeakProperty_setValue:
      ASSERT(function.NumParameters() == 2);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += LoadLocal(parsed_function_->RawParameterVariable(1));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 Slot::WeakProperty_value());
      body += NullConstant();
      break;
    case MethodRecognizer::kUtf8DecoderScan:
      ASSERT(function.NumParameters() == 5);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // decoder
      body += LoadLocal(parsed_function_->RawParameterVariable(1));  // bytes
      body += LoadLocal(parsed_function_->RawParameterVariable(2));  // start
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedIntPtr);
      body += LoadLocal(parsed_function_->RawParameterVariable(3));  // end
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedIntPtr);
      body += LoadLocal(parsed_function_->RawParameterVariable(4));  // table
      body += Utf8Scan();
      body += Box(kUnboxedIntPtr);
      break;
    case MethodRecognizer::kReachabilityFence:
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));
      body += ReachabilityFence();
      body += NullConstant();
      break;
    case MethodRecognizer::kFfiAbi:
      ASSERT(function.NumParameters() == 0);
      body += IntConstant(static_cast<int64_t>(compiler::ffi::TargetAbi()));
      break;
    case MethodRecognizer::kFfiLoadInt8:
    case MethodRecognizer::kFfiLoadInt16:
    case MethodRecognizer::kFfiLoadInt32:
    case MethodRecognizer::kFfiLoadInt64:
    case MethodRecognizer::kFfiLoadUint8:
    case MethodRecognizer::kFfiLoadUint16:
    case MethodRecognizer::kFfiLoadUint32:
    case MethodRecognizer::kFfiLoadUint64:
    case MethodRecognizer::kFfiLoadIntPtr:
    case MethodRecognizer::kFfiLoadFloat:
    case MethodRecognizer::kFfiLoadDouble:
    case MethodRecognizer::kFfiLoadPointer: {
      const classid_t ffi_type_arg_cid =
          compiler::ffi::RecognizedMethodTypeArgCid(kind);
      const classid_t typed_data_cid =
          compiler::ffi::ElementTypedDataCid(ffi_type_arg_cid);
      const auto& native_rep = compiler::ffi::NativeType::FromTypedDataClassId(
          zone_, ffi_type_arg_cid);

      ASSERT(function.NumParameters() == 2);
      LocalVariable* arg_pointer = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_offset = parsed_function_->RawParameterVariable(1);

      body += LoadLocal(arg_offset);
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_offset_not_null = MakeTemporary();

      body += LoadLocal(arg_pointer);
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      // No GC from here til LoadIndexed.
      body += LoadUntagged(compiler::target::PointerBase::data_field_offset());
      body += LoadLocal(arg_offset_not_null);
      body += UnboxTruncate(kUnboxedFfiIntPtr);
      body += LoadIndexed(typed_data_cid, /*index_scale=*/1,
                          /*index_unboxed=*/true);
      if (kind == MethodRecognizer::kFfiLoadFloat ||
          kind == MethodRecognizer::kFfiLoadDouble) {
        if (kind == MethodRecognizer::kFfiLoadFloat) {
          body += FloatToDouble();
        }
        body += Box(kUnboxedDouble);
      } else {
        body += Box(native_rep.AsRepresentationOverApprox(zone_));
        if (kind == MethodRecognizer::kFfiLoadPointer) {
          const auto class_table = thread_->isolate()->class_table();
          ASSERT(class_table->HasValidClassAt(kFfiPointerCid));
          const auto& pointer_class =
              Class::ZoneHandle(H.zone(), class_table->At(kFfiPointerCid));

          // We find the reified type to use for the pointer allocation.
          //
          // Call sites to this recognized method are guaranteed to pass a
          // Pointer<Pointer<X>> as RawParameterVariable(0). This function
          // will return a Pointer<X> object - for which we inspect the
          // reified type on the argument.
          //
          // The following is safe to do, as (1) we are guaranteed to have a
          // Pointer<Pointer<X>> as argument, and (2) the bound on the pointer
          // type parameter guarantees X is an interface type.
          ASSERT(function.NumTypeParameters() == 1);
          LocalVariable* address = MakeTemporary();
          body += LoadLocal(parsed_function_->RawParameterVariable(0));
          body += LoadNativeField(
              Slot::GetTypeArgumentsSlotFor(thread_, pointer_class));
          body += LoadNativeField(Slot::GetTypeArgumentsIndexSlot(
              thread_, Pointer::kNativeTypeArgPos));
          body += LoadNativeField(Slot::Type_arguments());
          body += AllocateObject(TokenPosition::kNoSource, pointer_class, 1);
          LocalVariable* pointer = MakeTemporary();
          body += LoadLocal(pointer);
          body += LoadLocal(address);
          body += UnboxTruncate(kUnboxedFfiIntPtr);
          body += ConvertUnboxedToUntagged(kUnboxedFfiIntPtr);
          body += StoreUntagged(compiler::target::Pointer::data_field_offset());
          body += DropTempsPreserveTop(1);  // Drop [address] keep [pointer].
        }
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
    case MethodRecognizer::kFfiStoreIntPtr:
    case MethodRecognizer::kFfiStoreFloat:
    case MethodRecognizer::kFfiStoreDouble:
    case MethodRecognizer::kFfiStorePointer: {
      const classid_t ffi_type_arg_cid =
          compiler::ffi::RecognizedMethodTypeArgCid(kind);
      const classid_t typed_data_cid =
          compiler::ffi::ElementTypedDataCid(ffi_type_arg_cid);
      const auto& native_rep = compiler::ffi::NativeType::FromTypedDataClassId(
          zone_, ffi_type_arg_cid);

      LocalVariable* arg_pointer = parsed_function_->RawParameterVariable(0);
      LocalVariable* arg_offset = parsed_function_->RawParameterVariable(1);
      LocalVariable* arg_value = parsed_function_->RawParameterVariable(2);

      if (kind == MethodRecognizer::kFfiStorePointer) {
        // Do type check before anything untagged is on the stack.
        const auto class_table = thread_->isolate()->class_table();
        ASSERT(class_table->HasValidClassAt(kFfiPointerCid));
        const auto& pointer_class =
            Class::ZoneHandle(H.zone(), class_table->At(kFfiPointerCid));
        const auto& pointer_type_args =
            TypeArguments::Handle(pointer_class.type_parameters());
        const auto& pointer_type_arg =
            AbstractType::ZoneHandle(pointer_type_args.TypeAt(0));

        // But we type check it as a method on a generic class at runtime.
        body += LoadLocal(arg_value);        // value.
        body += Constant(pointer_type_arg);  // dst_type.
        // We pass the Pointer type argument as instantiator_type_args.
        //
        // Call sites to this recognized method are guaranteed to pass a
        // Pointer<Pointer<X>> as RawParameterVariable(0). This function
        // will takes a Pointer<X> object - for which we inspect the
        // reified type on the argument.
        //
        // The following is safe to do, as (1) we are guaranteed to have a
        // Pointer<Pointer<X>> as argument, and (2) the bound on the pointer
        // type parameter guarantees X is an interface type.
        body += LoadLocal(arg_pointer);
        body += CheckNullOptimized(TokenPosition::kNoSource,
                                   String::ZoneHandle(Z, function.name()));
        body += LoadNativeField(
            Slot::GetTypeArgumentsSlotFor(thread_, pointer_class));
        body += NullConstant();  // function_type_args.
        body += AssertAssignable(TokenPosition::kNoSource, Symbols::Empty());
        body += Drop();
      }

      ASSERT(function.NumParameters() == 3);
      body += LoadLocal(arg_offset);
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_offset_not_null = MakeTemporary();
      body += LoadLocal(arg_value);
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      LocalVariable* arg_value_not_null = MakeTemporary();

      body += LoadLocal(arg_pointer);  // Pointer.
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      // No GC from here til StoreIndexed.
      body += LoadUntagged(compiler::target::PointerBase::data_field_offset());
      body += LoadLocal(arg_offset_not_null);
      body += UnboxTruncate(kUnboxedFfiIntPtr);
      body += LoadLocal(arg_value_not_null);
      if (kind == MethodRecognizer::kFfiStorePointer) {
        // This can only be Pointer, so it is always safe to LoadUntagged.
        body += LoadUntagged(compiler::target::Pointer::data_field_offset());
        body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
      } else if (kind == MethodRecognizer::kFfiStoreFloat ||
                 kind == MethodRecognizer::kFfiStoreDouble) {
        body += UnboxTruncate(kUnboxedDouble);
        if (kind == MethodRecognizer::kFfiStoreFloat) {
          body += DoubleToFloat();
        }
      } else {
        body += UnboxTruncate(native_rep.AsRepresentationOverApprox(zone_));
      }
      body += StoreIndexedTypedData(typed_data_cid, /*index_scale=*/1,
                                    /*index_unboxed=*/true);
      body += Drop();  // Drop [arg_value].
      body += Drop();  // Drop [arg_offset].
      body += NullConstant();
    } break;
    case MethodRecognizer::kFfiFromAddress: {
      const auto class_table = thread_->isolate()->class_table();
      ASSERT(class_table->HasValidClassAt(kFfiPointerCid));
      const auto& pointer_class =
          Class::ZoneHandle(H.zone(), class_table->At(kFfiPointerCid));

      ASSERT(function.NumTypeParameters() == 1);
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawTypeArgumentsVariable());
      body += AllocateObject(TokenPosition::kNoSource, pointer_class, 1);
      body += LoadLocal(MakeTemporary());  // Duplicate Pointer.
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // Address.
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      body += UnboxTruncate(kUnboxedFfiIntPtr);
      body += ConvertUnboxedToUntagged(kUnboxedFfiIntPtr);
      body += StoreUntagged(compiler::target::Pointer::data_field_offset());
    } break;
    case MethodRecognizer::kFfiGetAddress: {
      ASSERT(function.NumParameters() == 1);
      body += LoadLocal(parsed_function_->RawParameterVariable(0));  // Pointer.
      body += CheckNullOptimized(TokenPosition::kNoSource,
                                 String::ZoneHandle(Z, function.name()));
      // This can only be Pointer, so it is always safe to LoadUntagged.
      body += LoadUntagged(compiler::target::Pointer::data_field_offset());
      body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
      body += Box(kUnboxedFfiIntPtr);
    } break;
    default: {
      UNREACHABLE();
      break;
    }
  }

  body += Return(TokenPosition::kNoSource, /* omit_result_type_check = */ true);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, last_used_block_id_,
                           prologue_info);
}

Fragment FlowGraphBuilder::BuildTypedDataViewFactoryConstructor(
    const Function& function,
    classid_t cid) {
  auto token_pos = function.token_pos();
  auto class_table = Thread::Current()->isolate()->class_table();

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
  body += StoreInstanceField(token_pos, Slot::TypedDataView_data(),
                             StoreInstanceFieldInstr::Kind::kInitializing);

  body += LoadLocal(view_object);
  body += LoadLocal(offset_in_bytes);
  body += StoreInstanceField(token_pos, Slot::TypedDataView_offset_in_bytes(),
                             StoreInstanceFieldInstr::Kind::kInitializing,
                             kNoStoreBarrier);

  body += LoadLocal(view_object);
  body += LoadLocal(length);
  body += StoreInstanceField(token_pos, Slot::TypedDataBase_length(),
                             StoreInstanceFieldInstr::Kind::kInitializing,
                             kNoStoreBarrier);

  // Update the inner pointer.
  //
  // WARNING: Notice that we assume here no GC happens between those 4
  // instructions!
  body += LoadLocal(view_object);
  body += LoadLocal(typed_data);
  body += LoadUntagged(compiler::target::TypedDataBase::data_field_offset());
  body += ConvertUntaggedToUnboxed(kUnboxedIntPtr);
  body += LoadLocal(offset_in_bytes);
  body += UnboxSmiToIntptr();
  body += AddIntptrIntegers();
  body += ConvertUnboxedToUntagged(kUnboxedIntPtr);
  body += StoreUntagged(compiler::target::TypedDataBase::data_field_offset());

  return body;
}

Fragment FlowGraphBuilder::BuildTypedDataFactoryConstructor(
    const Function& function,
    classid_t cid) {
  const auto token_pos = function.token_pos();
  ASSERT(Thread::Current()->isolate()->class_table()->HasValidClassAt(cid));

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

  LocalVariable* receiver_variable = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::This(), klass_type, /*param_type=*/nullptr);

  receiver_variable->set_is_captured();
  //  receiver_variable->set_is_final();
  LocalScope* scope = new (Z) LocalScope(NULL, 0, 0);
  scope->set_context_level(0);
  scope->AddVariable(receiver_variable);
  scope->AddContextVariable(receiver_variable);
  return scope;
}

Fragment FlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  Fragment fragment;
  fragment += AllocateClosure(TokenPosition::kNoSource, target);
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  if (!target.HasInstantiatedSignature(kCurrentClass)) {
    fragment += LoadLocal(closure);
    fragment += LoadInstantiatorTypeArguments();
    fragment += StoreInstanceField(
        TokenPosition::kNoSource, Slot::Closure_instantiator_type_arguments(),
        StoreInstanceFieldInstr::Kind::kInitializing);
  }

  // The function signature cannot have uninstantiated function type parameters,
  // because the function cannot be local and have parent generic functions.
  ASSERT(target.HasInstantiatedSignature(kFunctions));

  // Allocate a context that closes over `this`.
  // Note: this must be kept in sync with ScopeBuilder::BuildScopes.
  const LocalScope* implicit_closure_scope =
      MakeImplicitClosureScope(Z, Class::Handle(Z, target.Owner()));
  fragment += AllocateContext(implicit_closure_scope->context_slots());
  LocalVariable* context = MakeTemporary();

  // Store the function and the context in the closure.
  fragment += LoadLocal(closure);
  fragment += Constant(target);
  fragment +=
      StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_function(),
                         StoreInstanceFieldInstr::Kind::kInitializing);

  fragment += LoadLocal(closure);
  fragment += LoadLocal(context);
  fragment +=
      StoreInstanceField(TokenPosition::kNoSource, Slot::Closure_context(),
                         StoreInstanceFieldInstr::Kind::kInitializing);

  if (target.IsGeneric()) {
    // Only generic functions need to have properly initialized
    // delayed_type_arguments.
    fragment += LoadLocal(closure);
    fragment += Constant(Object::empty_type_arguments());
    fragment += StoreInstanceField(
        TokenPosition::kNoSource, Slot::Closure_delayed_type_arguments(),
        StoreInstanceFieldInstr::Kind::kInitializing);
  }

  // The context is on top of the operand stack.  Store `this`.  The context
  // doesn't need a parent pointer because it doesn't close over anything
  // else.
  fragment += LoadLocal(parsed_function_->receiver_var());
  fragment += StoreInstanceField(
      TokenPosition::kNoSource,
      Slot::GetContextVariableSlotFor(
          thread_, *implicit_closure_scope->context_variables()[0]),
      StoreInstanceFieldInstr::Kind::kInitializing);

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
  if (definition->IsConstant() || definition->IsLoadStaticField()) {
    return true;
  }
  if (definition->IsAllocateObject()) {
    return !definition->AsAllocateObject()->closure_function().IsNull();
  }
  return definition->IsLoadLocal();
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
                                           AssertAssignableInstr::Kind kind) {
  Fragment instructions;
  if (!dst_type.IsTopTypeForSubtyping()) {
    LocalVariable* top_of_stack = MakeTemporary();
    instructions += LoadLocal(top_of_stack);
    instructions += AssertAssignableLoadTypeArguments(TokenPosition::kNoSource,
                                                      dst_type, dst_name, kind);
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

  instructions += Constant(AbstractType::ZoneHandle(dst_type.raw()));

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
  instructions += Constant(AbstractType::ZoneHandle(Z, sub_type_value.raw()));
  instructions += Constant(AbstractType::ZoneHandle(Z, super_type_value.raw()));
  instructions += Constant(String::ZoneHandle(Z, dst_name_value.raw()));
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

  TypeArguments& type_parameters = TypeArguments::Handle(Z);
  if (dart_function.IsFactory()) {
    type_parameters = Class::Handle(Z, dart_function.Owner()).type_parameters();
  } else {
    type_parameters = dart_function.type_parameters();
  }
  intptr_t num_type_params = type_parameters.Length();
  if (forwarding_target != nullptr) {
    type_parameters = forwarding_target->type_parameters();
    ASSERT(type_parameters.Length() == num_type_params);
  }

  TypeParameter& type_param = TypeParameter::Handle(Z);
  String& name = String::Handle(Z);
  AbstractType& bound = AbstractType::Handle(Z);
  Fragment check_bounds;
  for (intptr_t i = 0; i < num_type_params; ++i) {
    type_param ^= type_parameters.TypeAt(i);

    bound = type_param.bound();
    if (bound.IsTopTypeForSubtyping()) {
      continue;
    }

    switch (mode) {
      case TypeChecksToBuild::kCheckAllTypeParameterBounds:
        break;
      case TypeChecksToBuild::kCheckCovariantTypeParameterBounds:
        if (!type_param.IsGenericCovariantImpl()) {
          continue;
        }
        break;
      case TypeChecksToBuild::kCheckNonCovariantTypeParameterBounds:
        if (type_param.IsGenericCovariantImpl()) {
          continue;
        }
        break;
    }

    name = type_param.name();

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

    const AbstractType* target_type = &param->type();
    if (forwarding_target != NULL) {
      // We add 1 to the parameter index to account for the receiver.
      target_type =
          &AbstractType::ZoneHandle(Z, forwarding_target->ParameterTypeAt(i));
    }

    if (target_type->IsTopTypeForSubtyping()) continue;

    const bool is_covariant = param->is_explicit_covariant_parameter();
    Fragment* checks = is_covariant ? explicit_checks : implicit_checks;

    *checks += LoadLocal(param);
    *checks += AssertAssignableLoadTypeArguments(
        TokenPosition::kNoSource, *target_type, name,
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
  return names.raw();
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
    ASSERT(type_args != NULL);
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
        Class::Handle(Z, I->object_store()->object_class()),
        Symbols::NoSuchMethod(), two_arguments);
  }
  body += StaticCall(TokenPosition::kMinSource, no_such_method,
                     /* argument_count = */ 2, ICData::kNSMDispatch);
  body += Return(TokenPosition::kNoSource);

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

  // Set up by BuildDynamicCallChecks() when needed. These values are
  // read-only, so they don't need real local variables and are created
  // using MakeTemporary().
  LocalVariable* function = nullptr;
  LocalVariable* num_fixed_params = nullptr;
  LocalVariable* num_opt_params = nullptr;
  LocalVariable* num_max_params = nullptr;
  LocalVariable* has_named_params = nullptr;
  LocalVariable* parameter_names = nullptr;
  LocalVariable* parameter_types = nullptr;
  LocalVariable* type_parameters = nullptr;
  LocalVariable* closure_data = nullptr;
  LocalVariable* default_tav_info = nullptr;
  LocalVariable* instantiator_type_args = nullptr;
  LocalVariable* parent_function_type_args = nullptr;
};

Fragment FlowGraphBuilder::TestClosureFunctionGeneric(
    const ClosureCallInfo& info,
    Fragment generic,
    Fragment not_generic) {
  JoinEntryInstr* after_branch = BuildJoinEntry();

  Fragment check;
  check += LoadLocal(info.type_parameters);
  TargetEntryInstr *is_not_generic, *is_generic;
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
  if (!I->use_strict_null_safety_checks()) return not_set;

  Fragment check_required;
  // First, we convert the index to be in terms of the number of optional
  // parameters, not total parameters (to calculate the flag index and shift).
  check_required += LoadLocal(info.vars->current_param_index);
  check_required += LoadLocal(info.num_fixed_params);
  check_required += SmiBinaryOp(Token::kSUB, /*is_truncating=*/true);
  LocalVariable* opt_index = MakeTemporary("opt_index");  // Read-only.

  // Next, we calculate the index to dereference in the parameter names array.
  check_required += LoadLocal(opt_index);
  check_required +=
      IntConstant(compiler::target::kNumParameterFlagsPerElementLog2);
  check_required += SmiBinaryOp(Token::kSHR);
  check_required += LoadLocal(info.num_max_params);
  check_required += SmiBinaryOp(Token::kADD);
  LocalVariable* flags_index = MakeTemporary("flags_index");  // Read-only.

  // Two read-only stack values (opt_index, flag_index) that must be dropped
  // after we rejoin at after_check.
  JoinEntryInstr* after_check = BuildJoinEntry();

  // Now we check to see if the flags index is within the bounds of the
  // parameters names array. If not, it cannot be required.
  check_required += LoadLocal(flags_index);
  check_required += LoadLocal(info.parameter_names);
  check_required += LoadNativeField(Slot::Array_length());
  check_required += SmiRelationalOp(Token::kLT);
  TargetEntryInstr *valid_index, *invalid_index;
  check_required += BranchIfTrue(&valid_index, &invalid_index);

  JoinEntryInstr* join_not_set = BuildJoinEntry();

  Fragment(invalid_index) + Goto(join_not_set);

  // Otherwise, we need to retrieve the value. We're guaranteed the Smis in
  // the flag slots are non-null, so after loading we can immediate check
  // the required flag bit for the given named parameter.
  check_required.current = valid_index;
  check_required += LoadLocal(info.parameter_names);
  check_required += LoadLocal(flags_index);
  check_required += LoadIndexed(kArrayCid);
  check_required += LoadLocal(opt_index);
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
  TargetEntryInstr *is_not_set, *is_set;
  check_required += BranchIfEqual(&is_not_set, &is_set);

  Fragment(is_not_set) + Goto(join_not_set);

  set.Prepend(is_set);
  set += Goto(after_check);

  not_set.Prepend(join_not_set);
  not_set += Goto(after_check);

  // After rejoining, drop the introduced temporaries.
  check_required.current = after_check;
  check_required += DropTemporary(&flags_index);
  check_required += DropTemporary(&opt_index);
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
  store_default += LoadLocal(info.default_tav_info);
  static_assert(
      Function::DefaultTypeArgumentsKindField::shift() == 0,
      "Need to generate shift for DefaultTypeArgumentsKindField bit field");
  store_default += IntConstant(Function::DefaultTypeArgumentsKindField::mask());
  store_default += SmiBinaryOp(Token::kBIT_AND);
  LocalVariable* default_tav_kind = MakeTemporary("default_tav_kind");

  // One read-only stack values (default_tav_kind) that must be dropped after
  // rejoining at done.
  JoinEntryInstr* done = BuildJoinEntry();

  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr *is_instantiated, *is_not_instantiated;
  store_default += IntConstant(static_cast<intptr_t>(
      Function::DefaultTypeArgumentsKind::kIsInstantiated));
  store_default += BranchIfEqual(&is_instantiated, &is_not_instantiated);
  store_default.current = is_not_instantiated;  // Check next case.
  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr *needs_instantiation, *can_share;
  store_default += IntConstant(static_cast<intptr_t>(
      Function::DefaultTypeArgumentsKind::kNeedsInstantiation));
  store_default += BranchIfEqual(&needs_instantiation, &can_share);
  store_default.current = can_share;  // Check next case.
  store_default += LoadLocal(default_tav_kind);
  TargetEntryInstr *can_share_instantiator, *can_share_function;
  store_default += IntConstant(static_cast<intptr_t>(
      Function::DefaultTypeArgumentsKind::kSharesInstantiatorTypeArguments));
  store_default += BranchIfEqual(&can_share_instantiator, &can_share_function);

  Fragment instantiated(is_instantiated);
  instantiated += LoadLocal(info.closure_data);
  instantiated += LoadNativeField(Slot::ClosureData_default_type_arguments());
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
  do_instantiation += LoadLocal(info.closure_data);
  do_instantiation +=
      LoadNativeField(Slot::ClosureData_default_type_arguments());
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
    if (!I->use_strict_null_safety_checks()) {
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
    has_any += LoadLocal(info.num_max_params);
    has_any += LoadLocal(info.parameter_names);
    has_any += LoadNativeField(Slot::Array_length());
    TargetEntryInstr *no_required, *has_required;
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
  check_names += LoadLocal(info.num_fixed_params);
  check_names += StoreLocal(info.vars->current_param_index);
  check_names += Drop();
  check_names += Goto(loop);

  Fragment loop_check(loop);
  loop_check += LoadLocal(info.vars->current_param_index);
  loop_check += LoadLocal(info.num_max_params);
  loop_check += SmiRelationalOp(Token::kLT);
  TargetEntryInstr *no_more, *more;
  loop_check += BranchIfTrue(&more, &no_more);

  Fragment(no_more) + Goto(done);

  Fragment loop_body(more);
  // First load the name we need to check against.
  loop_body += LoadLocal(info.parameter_names);
  loop_body += LoadLocal(info.vars->current_param_index);
  loop_body += LoadIndexed(kArrayCid);
  LocalVariable* param_name = MakeTemporary("param_name");  // Read only.

  // One additional local value on the stack within the loop body (param_name)
  // that should be dropped after rejoining at loop_incr.
  JoinEntryInstr* loop_incr = BuildJoinEntry();

  // Now iterate over the ArgumentsDescriptor names and check for a match.
  for (intptr_t i = 0; i < info.descriptor.NamedCount(); i++) {
    const auto& name = String::ZoneHandle(Z, info.descriptor.NameAt(i));
    loop_body += Constant(name);
    loop_body += LoadLocal(param_name);
    TargetEntryInstr *match, *mismatch;
    loop_body += BranchIfEqual(&match, &mismatch);
    loop_body.current = mismatch;

    // We have a match, so go to the next name after storing the corresponding
    // parameter index on the stack and incrementing the number of matched
    // arguments. (No need to check the required bit for provided parameters.)
    Fragment matched(match);
    matched += LoadLocal(info.vars->current_param_index);
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
  TargetEntryInstr *all_processed, *bad_name;
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
    TargetEntryInstr *null, *not_null;
    check_type_args_length += BranchIfNull(&null, &not_null);
    check_type_args_length.current = not_null;  // Continue in non-error case.
    check_type_args_length += LoadLocal(info.type_parameters);
    check_type_args_length += LoadNativeField(Slot::TypeArguments_length());
    check_type_args_length += IntConstant(info.descriptor.TypeArgsLen());
    TargetEntryInstr *equal, *not_equal;
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
  TargetEntryInstr *has_named, *has_positional;
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
    TargetEntryInstr *enough, *too_few;
    check_pos += BranchIfTrue(&enough, &too_few);
    check_pos.current = enough;

    Fragment(too_few) + Goto(info.throw_no_such_method);

    check_pos += IntConstant(info.descriptor.PositionalCount());
    check_pos += LoadLocal(info.num_max_params);
    check_pos += SmiRelationalOp(Token::kLTE);
    TargetEntryInstr *valid, *too_many;
    check_pos += BranchIfTrue(&valid, &too_many);
    check_pos.current = valid;

    Fragment(too_many) + Goto(info.throw_no_such_method);

    check_pos += Goto(join_after_optional);
  }

  Fragment check_named(has_named);

  TargetEntryInstr *same, *different;
  check_named += LoadLocal(info.num_fixed_params);
  check_named += IntConstant(info.descriptor.PositionalCount());
  check_named += BranchIfEqual(&same, &different);
  check_named.current = same;

  Fragment(different) + Goto(info.throw_no_such_method);

  if (info.descriptor.NamedCount() > 0) {
    check_named += IntConstant(info.descriptor.NamedCount());
    check_named += LoadLocal(info.num_opt_params);
    check_named += SmiRelationalOp(Token::kLTE);
    TargetEntryInstr *valid, *too_many;
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
  // Loop over the type parameters array.
  loop_init += IntConstant(0);
  loop_init += StoreLocal(info.vars->current_param_index);
  loop_init += Drop();
  loop_init += Goto(loop);

  Fragment loop_check(loop);
  loop_check += LoadLocal(info.vars->current_param_index);
  loop_check += LoadLocal(info.type_parameters);
  loop_check += LoadNativeField(Slot::TypeArguments_length());
  loop_check += SmiRelationalOp(Token::kLT);
  TargetEntryInstr *more, *no_more;
  loop_check += BranchIfTrue(&more, &no_more);

  Fragment(no_more) + Goto(done);

  Fragment loop_body(more);
  loop_body += LoadLocal(info.type_parameters);
  loop_body += LoadLocal(info.vars->current_param_index);
  loop_body += LoadIndexed(kTypeArgumentsCid);
  LocalVariable* current_param = MakeTemporary("current_param");  // Read-only.

  // One read-only local variable on stack (param) to drop after joining.
  JoinEntryInstr* next = BuildJoinEntry();

  loop_body += LoadLocal(current_param);
  loop_body += LoadNativeField(Slot::TypeParameter_flags());
  loop_body += Box(kUnboxedUint8);
  loop_body += IntConstant(
      TypeParameterLayout::GenericCovariantImplBit::mask_in_place());
  loop_body += SmiBinaryOp(Token::kBIT_AND);
  loop_body += IntConstant(0);
  TargetEntryInstr *is_noncovariant, *is_covariant;
  loop_body += BranchIfEqual(&is_noncovariant, &is_covariant);

  Fragment(is_covariant) + Goto(next);  // Continue if covariant.

  loop_body.current = is_noncovariant;  // Type check if non-covariant.
  loop_body += LoadLocal(info.instantiator_type_args);
  loop_body += LoadLocal(info.vars->function_type_args);
  // Load parameter.
  loop_body += LoadLocal(current_param);
  // Load bounds from parameter.
  loop_body += LoadLocal(current_param);
  loop_body += LoadNativeField(Slot::TypeParameter_bound());
  // Load name from parameter.
  loop_body += LoadLocal(current_param);
  loop_body += LoadNativeField(Slot::TypeParameter_name());
  // Assert that the type the parameter is instantiated as is consistent with
  // the bounds of the parameter.
  loop_body += AssertSubtype(TokenPosition::kNoSource);
  loop_body += Goto(next);

  Fragment loop_incr(next);
  loop_incr += DropTemporary(&current_param);
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
  instructions += LoadIndexed(kArrayCid);
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
    const auto& arg_name = String::ZoneHandle(Z, info.descriptor.NameAt(i));
    auto const param_index = info.vars->named_argument_parameter_indices.At(i);
    instructions += BuildClosureCallArgumentTypeCheck(info, param_index,
                                                      arg_index, arg_name);
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
  info.function = MakeTemporary("function");

  body += LoadLocal(info.function);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      Function::PackedNumFixedParameters>(Slot::Function_packed_fields());
  info.num_fixed_params = MakeTemporary("num_fixed_params");

  body += LoadLocal(info.function);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      Function::PackedNumOptionalParameters>(Slot::Function_packed_fields());
  info.num_opt_params = MakeTemporary("num_opt_params");

  body += LoadLocal(info.num_fixed_params);
  body += LoadLocal(info.num_opt_params);
  body += SmiBinaryOp(Token::kADD);
  info.num_max_params = MakeTemporary("num_max_params");

  body += LoadLocal(info.function);
  body += BuildExtractUnboxedSlotBitFieldIntoSmi<
      Function::PackedHasNamedOptionalParameters>(
      Slot::Function_packed_fields());

  body += IntConstant(0);
  body += StrictCompare(Token::kNE_STRICT);
  info.has_named_params = MakeTemporary("has_named_params");

  body += LoadLocal(info.function);
  body += LoadNativeField(Slot::Function_parameter_names());
  info.parameter_names = MakeTemporary("parameter_names");

  body += LoadLocal(info.function);
  body += LoadNativeField(Slot::Function_parameter_types());
  info.parameter_types = MakeTemporary("parameter_types");

  body += LoadLocal(info.function);
  body += LoadNativeField(Slot::Function_type_parameters());
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
  generic += LoadLocal(info.function);
  generic += LoadNativeField(Slot::Function_data());
  info.closure_data = MakeTemporary("closure_data");
  generic += LoadLocal(info.closure_data);
  generic += LoadNativeField(Slot::ClosureData_default_type_arguments_info());
  info.default_tav_info = MakeTemporary("default_tav_info");
  // Calculate the local function type arguments and store them in
  // info.vars->function_type_args.
  generic += BuildClosureCallDefaultTypeHandling(info);
  // Load the local function type args.
  generic += LoadLocal(info.vars->function_type_args);
  // Load the parent function type args.
  generic += LoadLocal(info.parent_function_type_args);
  // Load the number of parent type parameters.
  generic += LoadLocal(info.default_tav_info);
  static_assert(Function::NumParentTypeParametersField::shift() > 0,
                "No need to shift for NumParentTypeParametersField bit field");
  generic += IntConstant(Function::NumParentTypeParametersField::shift());
  generic += SmiBinaryOp(Token::kSHR);
  generic += IntConstant(Function::NumParentTypeParametersField::mask());
  generic += SmiBinaryOp(Token::kBIT_AND);
  // Load the number of total type parameters.
  LocalVariable* num_parents = MakeTemporary();
  generic += LoadLocal(info.type_parameters);
  generic += LoadNativeField(Slot::TypeArguments_length());
  generic += LoadLocal(num_parents);
  generic += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);

  // Call the static function for prepending type arguments.
  generic += StaticCall(TokenPosition::kNoSource,
                        PrependTypeArgumentsFunction(), 4, ICData::kStatic);
  generic += StoreLocal(info.vars->function_type_args);
  generic += Drop();
  generic += DropTemporary(&info.default_tav_info);
  generic += DropTemporary(&info.closure_data);

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
  body += DropTemporary(&info.parameter_names);
  body += DropTemporary(&info.has_named_params);
  body += DropTemporary(&info.num_max_params);
  body += DropTemporary(&info.num_opt_params);
  body += DropTemporary(&info.num_fixed_params);
  body += DropTemporary(&info.function);

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
      Class::Handle(Z, I->object_store()->closure_class());
  const bool is_closure_call = (owner.raw() == closure_class.raw()) &&
                               field_name.Equals(Symbols::Call());

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
    // Lookup the function in the closure.
    body += LoadLocal(closure);
    body += LoadNativeField(Slot::Closure_function());

    body += ClosureCall(TokenPosition::kNoSource, descriptor.TypeArgsLen(),
                        descriptor.Count(), *argument_names);
  } else {
    const intptr_t kNumArgsChecked = 1;
    body +=
        InstanceCall(TokenPosition::kMinSource,
                     is_dynamic_call ? Symbols::DynamicCall() : Symbols::Call(),
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
      type = Type::New(owner, TypeArguments::Handle(Z), owner.token_pos());
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

  TargetEntryInstr *do_checks, *skip_checks;
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
    type_args_len = function.NumTypeParameters();
    ASSERT(parsed_function_->function_type_arguments() != NULL);
    closure += LoadLocal(parsed_function_->function_type_arguments());
  }

  // Push receiver.
  if (!target.is_static()) {
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
                            (target.is_static() ? 0 : 1);
  ASSERT(argument_count == target.NumParameters());

  Array& argument_names =
      Array::ZoneHandle(Z, GetOptionalParameterNames(function));

  closure += StaticCall(TokenPosition::kNoSource, target, argument_count,
                        argument_names, ICData::kNoRebind,
                        /* result_type = */ NULL, type_args_len);

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
                                                 : function.raw());
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
      body += CheckAssignable(setter_value->type(), setter_value->name(),
                              AssertAssignableInstr::kParameterCheck);
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
        body += StoreInstanceFieldGuarded(
            field, StoreInstanceFieldInstr::Kind::kOther);
      } else {
        body += StoreStaticField(TokenPosition::kNoSource, field);
      }
    }
    body += NullConstant();
  } else if (is_getter && is_method) {
    ASSERT(!field.needs_load_guard()
                NOT_IN_PRODUCT(|| I->HasAttemptedReload()));
    body += LoadLocal(parsed_function_->ParameterVariable(0));
    body += LoadField(
        field, /*calls_initializer=*/field.NeedsInitializationCheckOnLoad());
    if (field.needs_load_guard()) {
#if defined(PRODUCT)
      UNREACHABLE();
#else
      body += CheckAssignable(AbstractType::Handle(Z, field.type()),
                              Symbols::FunctionResult());
#endif
    }
  } else if (field.is_const()) {
    ASSERT(!field.IsUninitialized());
    body += Constant(Instance::ZoneHandle(Z, field.StaticValue()));
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
    if (field.needs_load_guard()) {
#if defined(PRODUCT)
      UNREACHABLE();
#else
      ASSERT(Isolate::Current()->HasAttemptedReload());
      body += CheckAssignable(AbstractType::Handle(Z, field.type()),
                              Symbols::FunctionResult());
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
  ASSERT(function.name() != Symbols::EqualOperator().raw());

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
  }

  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.raw() == Symbols::AssignIndexToken().raw()) {
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
  auto* instr = new (Z)
      EnterHandleScopeInstr(EnterHandleScopeInstr::Kind::kEnterHandleScope);
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::GetTopHandleScope() {
  auto* instr = new (Z)
      EnterHandleScopeInstr(EnterHandleScopeInstr::Kind::kGetTopHandleScope);
  Push(instr);
  return Fragment(instr);
}

Fragment FlowGraphBuilder::ExitHandleScope() {
  auto* instr = new (Z) ExitHandleScopeInstr();
  return Fragment(instr);
}

Fragment FlowGraphBuilder::AllocateHandle(LocalVariable* api_local_scope) {
  Fragment code;
  if (api_local_scope != nullptr) {
    // Use the reference the scope we created in the trampoline.
    code += LoadLocal(api_local_scope);
  } else {
    // Or get a reference to the top handle scope.
    code += GetTopHandleScope();
  }
  Value* api_local_scope_value = Pop();
  auto* instr = new (Z) AllocateHandleInstr(api_local_scope_value);
  Push(instr);
  code <<= instr;
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

Fragment FlowGraphBuilder::WrapHandle(LocalVariable* api_local_scope) {
  Fragment code;
  LocalVariable* object = MakeTemporary();
  code += AllocateHandle(api_local_scope);

  code += LoadLocal(MakeTemporary());  // Duplicate handle pointer.
  code += ConvertUnboxedToUntagged(kUnboxedIntPtr);
  code += LoadLocal(object);
  code += RawStoreField(compiler::target::LocalHandle::raw_offset());

  code += DropTempsPreserveTop(1);  // Drop object below handle.
  return code;
}

Fragment FlowGraphBuilder::UnwrapHandle() {
  Fragment code;
  code += ConvertUnboxedToUntagged(kUnboxedIntPtr);
  code += IntConstant(compiler::target::LocalHandle::raw_offset());
  code += UnboxTruncate(kUnboxedIntPtr);
  code += LoadIndexed(kArrayCid, /*index_scale=*/1, /*index_unboxed=*/true);
  return code;
}

Fragment FlowGraphBuilder::UnhandledException() {
  const auto class_table = thread_->isolate()->class_table();
  ASSERT(class_table->HasValidClassAt(kUnhandledExceptionCid));
  const auto& klass =
      Class::ZoneHandle(H.zone(), class_table->At(kUnhandledExceptionCid));
  ASSERT(!klass.IsNull());
  Fragment body;
  body += AllocateObject(TokenPosition::kNoSource, klass, 0);
  LocalVariable* error_instance = MakeTemporary();

  body += LoadLocal(error_instance);
  body += LoadLocal(CurrentException());
  body += StoreInstanceField(
      TokenPosition::kNoSource, Slot::UnhandledException_exception(),
      StoreInstanceFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  body += LoadLocal(error_instance);
  body += LoadLocal(CurrentStackTrace());
  body += StoreInstanceField(
      TokenPosition::kNoSource, Slot::UnhandledException_stacktrace(),
      StoreInstanceFieldInstr::Kind::kInitializing, kNoStoreBarrier);

  return body;
}

Fragment FlowGraphBuilder::UnboxTruncate(Representation to) {
  auto* unbox = UnboxInstr::Create(to, Pop(), DeoptId::kNone,
                                   Instruction::kNotSpeculative);
  Push(unbox);
  return Fragment(unbox);
}

Fragment FlowGraphBuilder::NativeReturn(
    const compiler::ffi::CallbackMarshaller& marshaller) {
  auto* instr = new (Z)
      NativeReturnInstr(InstructionSource(), Pop(), marshaller, DeoptId::kNone);
  return Fragment(instr).closed();
}

Fragment FlowGraphBuilder::FfiPointerFromAddress(const Type& result_type) {
  LocalVariable* address = MakeTemporary();
  LocalVariable* result = parsed_function_->expression_temp_var();

  Class& result_class = Class::ZoneHandle(Z, result_type.type_class());
  // This class might only be instantiated as a return type of ffi calls.
  result_class.EnsureIsFinalized(thread_);

  TypeArguments& args = TypeArguments::ZoneHandle(Z, result_type.arguments());

  // A kernel transform for FFI in the front-end ensures that type parameters
  // do not appear in the type arguments to a any Pointer classes in an FFI
  // signature.
  ASSERT(args.IsNull() || args.IsInstantiated());
  args = args.Canonicalize(thread_, nullptr);

  Fragment code;
  code += Constant(args);
  code += AllocateObject(TokenPosition::kNoSource, result_class, 1);
  LocalVariable* pointer = MakeTemporary();
  code += LoadLocal(pointer);
  code += LoadLocal(address);
  code += UnboxTruncate(kUnboxedFfiIntPtr);
  code += ConvertUnboxedToUntagged(kUnboxedFfiIntPtr);
  code += StoreUntagged(compiler::target::Pointer::data_field_offset());
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

Fragment FlowGraphBuilder::WrapTypedDataBaseInStruct(
    const AbstractType& struct_type) {
  const auto& struct_sub_class = Class::ZoneHandle(Z, struct_type.type_class());
  struct_sub_class.EnsureIsFinalized(thread_);
  const auto& lib_ffi = Library::Handle(Z, Library::FfiLibrary());
  const auto& struct_class =
      Class::Handle(Z, lib_ffi.LookupClass(Symbols::Struct()));
  const auto& struct_addressof = Field::ZoneHandle(
      Z, struct_class.LookupInstanceFieldAllowPrivate(Symbols::_addressOf()));
  ASSERT(!struct_addressof.IsNull());

  Fragment body;
  LocalVariable* typed_data = MakeTemporary("typed_data_base");
  body += AllocateObject(TokenPosition::kNoSource, struct_sub_class, 0);
  body += LoadLocal(MakeTemporary("struct"));  // Duplicate Struct.
  body += LoadLocal(typed_data);
  body += StoreInstanceField(struct_addressof,
                             StoreInstanceFieldInstr::Kind::kInitializing);
  body += DropTempsPreserveTop(1);  // Drop TypedData.
  return body;
}

Fragment FlowGraphBuilder::LoadTypedDataBaseFromStruct() {
  const Library& lib_ffi = Library::Handle(zone_, Library::FfiLibrary());
  const Class& struct_class =
      Class::Handle(zone_, lib_ffi.LookupClass(Symbols::Struct()));
  const Field& struct_addressof = Field::ZoneHandle(
      zone_,
      struct_class.LookupInstanceFieldAllowPrivate(Symbols::_addressOf()));
  ASSERT(!struct_addressof.IsNull());

  Fragment body;
  body += LoadField(struct_addressof, /*calls_initializer=*/false);
  return body;
}

Fragment FlowGraphBuilder::CopyFromStructToStack(
    LocalVariable* variable,
    const GrowableArray<Representation>& representations) {
  Fragment body;
  const intptr_t num_defs = representations.length();
  int offset_in_bytes = 0;
  for (intptr_t i = 0; i < num_defs; i++) {
    body += LoadLocal(variable);
    body += LoadTypedDataBaseFromStruct();
    body += LoadUntagged(compiler::target::Pointer::data_field_offset());
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
    body += LoadUntagged(compiler::target::TypedDataBase::data_field_offset());
    body += IntConstant(offset_in_bytes);
    body += LoadLocal(definitions->At(i));
    body += StoreIndexedTypedDataUnboxed(representation, /*index_scale=*/1,
                                         /*index_unboxed=*/false);
    offset_in_bytes += RepresentationUtils::ValueSize(representation);
  }
  body += DropTempsPreserveTop(num_defs);  // Drop chunck defs keep TypedData.
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
    body += LoadUntagged(compiler::target::TypedDataBase::data_field_offset());
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
    body += LoadUntagged(compiler::target::TypedDataBase::data_field_offset());
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

Fragment FlowGraphBuilder::FfiCallConvertStructArgumentToNative(
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
    body += CopyFromStructToStack(variable, representations);
  } else {
    ASSERT(native_loc.IsPointerToMemory());
    // Only load the typed data, do copying in the FFI call machine code.
    body += LoadLocal(variable);  // User-defined struct.
    body += LoadTypedDataBaseFromStruct();
  }
  return body;
}

Fragment FlowGraphBuilder::FfiCallConvertStructReturnToDart(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index) {
  Fragment body;
  // The typed data is allocated before the FFI call, and is populated in
  // machine code. So, here, it only has to be wrapped in the struct class.
  const auto& struct_type =
      AbstractType::Handle(Z, marshaller.CType(arg_index));
  body += WrapTypedDataBaseInStruct(struct_type);
  return body;
}

Fragment FlowGraphBuilder::FfiCallbackConvertStructArgumentToDart(
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
    LocalVariable* address_of_struct = MakeTemporary("address_of_struct");
    body += IntConstant(length_in_bytes);
    body +=
        AllocateTypedData(TokenPosition::kNoSource, kTypedDataUint8ArrayCid);
    LocalVariable* typed_data_base = MakeTemporary("typed_data_base");
    body += LoadLocal(address_of_struct);
    body += LoadLocal(typed_data_base);
    body += CopyFromUnboxedAddressToTypedDataBase(length_in_bytes);
    body += DropTempsPreserveTop(1);  // address_of_struct.
  }
  // Wrap typed data in struct class.
  const auto& struct_type =
      AbstractType::Handle(Z, marshaller.CType(arg_index));
  body += WrapTypedDataBaseInStruct(struct_type);
  return body;
}

Fragment FlowGraphBuilder::FfiCallbackConvertStructReturnToNative(
    const compiler::ffi::CallbackMarshaller& marshaller,
    intptr_t arg_index) {
  Fragment body;
  const auto& native_loc = marshaller.Location(arg_index);
  if (native_loc.IsMultiple()) {
    // We pass in typed data to native return instruction, and do the copying
    // in machine code.
    body += LoadTypedDataBaseFromStruct();
  } else {
    ASSERT(native_loc.IsPointerToMemory());
    // We copy the data into the right location in IL.
    const intptr_t length_in_bytes =
        marshaller.Location(arg_index).payload_type().SizeInBytes();

    body += LoadTypedDataBaseFromStruct();
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
  ASSERT(!marshaller.IsStruct(arg_index));

  Fragment body;
  if (marshaller.IsPointer(arg_index)) {
    body += Box(kUnboxedFfiIntPtr);
    body += FfiPointerFromAddress(
        Type::CheckedHandle(Z, marshaller.CType(arg_index)));
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
  }
  return body;
}

Fragment FlowGraphBuilder::FfiConvertPrimitiveToNative(
    const compiler::ffi::BaseMarshaller& marshaller,
    intptr_t arg_index,
    LocalVariable* api_local_scope) {
  ASSERT(!marshaller.IsStruct(arg_index));

  Fragment body;
  if (marshaller.IsPointer(arg_index)) {
    // This can only be Pointer, so it is always safe to LoadUntagged.
    body += LoadUntagged(compiler::target::Pointer::data_field_offset());
    body += ConvertUntaggedToUnboxed(kUnboxedFfiIntPtr);
  } else if (marshaller.IsHandle(arg_index)) {
    body += WrapHandle(api_local_scope);
  } else {
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
  if (function.FfiCallbackTarget() != Function::null()) {
    return BuildGraphOfFfiCallback(function);
  } else {
    return BuildGraphOfFfiNative(function);
  }
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

  const auto& marshaller = *new (Z) compiler::ffi::CallMarshaller(Z, function);

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
    // Check for 'null'.
    // TODO(36780): Mention the param name instead of function reciever.
    function_body +=
        CheckNullOptimized(TokenPosition::kNoSource,
                           String::ZoneHandle(Z, marshaller.function_name()));
    function_body += StoreLocal(
        TokenPosition::kNoSource,
        parsed_function_->ParameterVariable(kFirstArgumentParameterOffset + i));
    function_body += Drop();
  }

  Fragment body;
  intptr_t try_handler_index = -1;
  LocalVariable* api_local_scope = nullptr;
  if (signature_contains_handles) {
    // Wrap in Try catch to transition from Native to Generated on a throw from
    // the dart_api.
    try_handler_index = AllocateTryIndex();
    body += TryCatch(try_handler_index);
    ++try_depth_;

    body += EnterHandleScope();
    api_local_scope = MakeTemporary("api_local_scope");
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
    if (marshaller.IsStruct(i)) {
      body += FfiCallConvertStructArgumentToNative(
          parsed_function_->ParameterVariable(kFirstArgumentParameterOffset +
                                              i),
          marshaller, i);
    } else {
      body += LoadLocal(parsed_function_->ParameterVariable(
          kFirstArgumentParameterOffset + i));
      body += FfiConvertPrimitiveToNative(marshaller, i, api_local_scope);
    }
  }

  // Push the function pointer, which is stored (as Pointer object) in the
  // first slot of the context.
  body +=
      LoadLocal(parsed_function_->ParameterVariable(kClosureParameterOffset));
  body += LoadNativeField(Slot::Closure_context());
  body += LoadNativeField(Slot::GetContextVariableSlotFor(
      thread_, *MakeImplicitClosureScope(
                    Z, Class::Handle(I->object_store()->ffi_pointer_class()))
                    ->context_variables()[0]));

  // This can only be Pointer, so it is always safe to LoadUntagged.
  body += LoadUntagged(compiler::target::Pointer::data_field_offset());
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

  if (marshaller.IsStruct(compiler::ffi::kResultIndex)) {
    body += FfiCallConvertStructReturnToDart(marshaller,
                                             compiler::ffi::kResultIndex);
  } else {
    body += FfiConvertPrimitiveToDart(marshaller, compiler::ffi::kResultIndex);
  }

  if (signature_contains_handles) {
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

FlowGraph* FlowGraphBuilder::BuildGraphOfFfiCallback(const Function& function) {
  const auto& marshaller =
      *new (Z) compiler::ffi::CallbackMarshaller(Z, function);

  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, Compiler::kNoOSRDeoptId);

  auto* const native_entry = new (Z) NativeEntryInstr(
      marshaller, graph_entry_, AllocateBlockId(), CurrentTryIndex(),
      GetNextDeoptId(), function.FfiCallbackId());

  graph_entry_->set_normal_entry(native_entry);

  Fragment function_body(native_entry);
  function_body += CheckStackOverflowInPrologue(function.token_pos());

  // Wrap the entire method in a big try/catch. This is important to ensure that
  // the VM does not crash if the callback throws an exception.
  const intptr_t try_handler_index = AllocateTryIndex();
  Fragment body = TryCatch(try_handler_index);
  ++try_depth_;

  // Box and push the arguments.
  for (intptr_t i = 0; i < marshaller.num_args(); i++) {
    const intptr_t num_defs = marshaller.NumDefinitions(i);
    auto defs = new (Z) ZoneGrowableArray<LocalVariable*>(Z, num_defs);

    for (intptr_t j = 0; j < num_defs; j++) {
      const intptr_t def_index = marshaller.DefinitionIndex(j, i);
      auto* parameter = new (Z) NativeParameterInstr(marshaller, def_index);
      Push(parameter);
      body <<= parameter;
      LocalVariable* def = MakeTemporary();
      defs->Add(def);
    }

    if (marshaller.IsStruct(i)) {
      body += FfiCallbackConvertStructArgumentToDart(marshaller, i, defs);
    } else {
      body += FfiConvertPrimitiveToDart(marshaller, i);
    }
  }

  // Call the target.
  //
  // TODO(36748): Determine the hot-reload semantics of callbacks and update the
  // rebind-rule accordingly.
  body += StaticCall(TokenPosition::kNoSource,
                     Function::ZoneHandle(Z, function.FfiCallbackTarget()),
                     marshaller.num_args(), Array::empty_array(),
                     ICData::kNoRebind);
  if (marshaller.IsVoid(compiler::ffi::kResultIndex)) {
    body += Drop();
    body += IntConstant(0);
  } else if (!marshaller.IsHandle(compiler::ffi::kResultIndex)) {
    body +=
        CheckNullOptimized(TokenPosition::kNoSource,
                           String::ZoneHandle(Z, marshaller.function_name()));
  }

  if (marshaller.IsStruct(compiler::ffi::kResultIndex)) {
    body += FfiCallbackConvertStructReturnToNative(marshaller,
                                                   compiler::ffi::kResultIndex);
  } else {
    body += FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex,
                                        /*api_local_scope=*/nullptr);
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
    catch_body += IntConstant(0);
    catch_body += UnboxTruncate(kUnboxedFfiIntPtr);
  } else if (marshaller.IsHandle(compiler::ffi::kResultIndex)) {
    catch_body += UnhandledException();
    catch_body +=
        FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex,
                                    /*api_local_scope=*/nullptr);

  } else if (marshaller.IsStruct(compiler::ffi::kResultIndex)) {
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
    catch_body += WrapTypedDataBaseInStruct(
        AbstractType::Handle(Z, marshaller.CType(compiler::ffi::kResultIndex)));
    catch_body += FfiCallbackConvertStructReturnToNative(
        marshaller, compiler::ffi::kResultIndex);

  } else {
    catch_body += Constant(
        Instance::ZoneHandle(Z, function.FfiCallbackExceptionalReturn()));
    catch_body +=
        FfiConvertPrimitiveToNative(marshaller, compiler::ffi::kResultIndex,
                                    /*api_local_scope=*/nullptr);
  }

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

bool FlowGraphBuilder::NeedsNullAssertion(const AbstractType& type) {
  if (!type.IsNonNullable()) {
    return false;
  }
  if (type.IsTypeParameter()) {
    return NeedsNullAssertion(
        AbstractType::Handle(Z, TypeParameter::Cast(type).bound()));
  }
  if (type.IsFutureOrType()) {
    return NeedsNullAssertion(AbstractType::Handle(Z, type.UnwrapFutureOr()));
  }
  return true;
}

Fragment FlowGraphBuilder::NullAssertion(LocalVariable* variable) {
  Fragment code;
  if (!NeedsNullAssertion(variable->type())) {
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
  if (I->null_safety() || !I->asserts() || !FLAG_null_assertions) {
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

}  // namespace kernel

}  // namespace dart
