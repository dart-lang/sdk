// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_generator.h"

#include "vm/assembler.h"
#include "vm/ast.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/intermediate_language.h"
#include "vm/object_store.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/parser.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/verifier.h"

namespace dart {

DEFINE_FLAG(bool, deoptimize_alot, false,
    "Deoptimizes all live frames when we are about to return to Dart code from"
    " native entries.");
DEFINE_FLAG(int, max_subtype_cache_entries, 100,
    "Maximum number of subtype cache entries (number of checks cached).");
DEFINE_FLAG(int, optimization_counter_threshold, 30000,
    "Function's usage-counter value before it is optimized, -1 means never");
DEFINE_FLAG(charp, optimization_filter, NULL, "Optimize only named function");
DEFINE_FLAG(int, reoptimization_counter_threshold, 4000,
    "Counter threshold before a function gets reoptimized.");
DEFINE_FLAG(bool, stop_on_excessive_deoptimization, false,
    "Debugging: stops program if deoptimizing same function too often");
DEFINE_FLAG(bool, trace_deoptimization, false, "Trace deoptimization");
DEFINE_FLAG(bool, trace_deoptimization_verbose, false,
    "Trace deoptimization verbose");
DEFINE_FLAG(bool, trace_failed_optimization_attempts, false,
    "Traces all failed optimization attempts");
DEFINE_FLAG(bool, trace_ic, false, "Trace IC handling");
DEFINE_FLAG(bool, trace_ic_miss_in_optimized, false,
    "Trace IC miss in optimized code");
DEFINE_FLAG(bool, trace_optimized_ic_calls, false,
    "Trace IC calls in optimized code.");
DEFINE_FLAG(bool, trace_patching, false, "Trace patching of code.");
DEFINE_FLAG(bool, trace_runtime_calls, false, "Trace runtime calls");
DEFINE_FLAG(bool, trace_type_checks, false, "Trace runtime type checks.");

DECLARE_FLAG(int, deoptimization_counter_threshold);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, warn_on_javascript_compatibility);

DEFINE_FLAG(bool, use_osr, true, "Use on-stack replacement.");
DEFINE_FLAG(bool, trace_osr, false, "Trace attempts at on-stack replacement.");

DEFINE_FLAG(int, stacktrace_every, 0,
            "Compute debugger stacktrace on every N stack overflow checks");
DEFINE_FLAG(charp, stacktrace_filter, NULL,
            "Compute stacktrace in named function on stack overflow checks");
DEFINE_FLAG(int, deoptimize_every, 0,
            "Deoptimize on every N stack overflow checks");
DEFINE_FLAG(charp, deoptimize_filter, NULL,
            "Deoptimize in named function on stack overflow checks");

#ifdef DEBUG
DEFINE_FLAG(charp, gc_at_instance_allocation, NULL,
            "Perform a GC before allocation of instances of "
            "the specified class");
#endif

DEFINE_RUNTIME_ENTRY(TraceFunctionEntry, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  const String& function_name = String::Handle(function.name());
  const String& class_name =
      String::Handle(Class::Handle(function.Owner()).Name());
  OS::PrintErr("> Entering '%s.%s'\n",
      class_name.ToCString(), function_name.ToCString());
}


DEFINE_RUNTIME_ENTRY(TraceFunctionExit, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  const String& function_name = String::Handle(function.name());
  const String& class_name =
      String::Handle(Class::Handle(function.Owner()).Name());
  OS::PrintErr("< Exiting '%s.%s'\n",
      class_name.ToCString(), function_name.ToCString());
}


// Allocation of a fixed length array of given element type.
// This runtime entry is never called for allocating a List of a generic type,
// because a prior run time call instantiates the element type if necessary.
// Arg0: array length.
// Arg1: array type arguments, i.e. vector of 1 type, the element type.
// Return value: newly allocated array of length arg0.
DEFINE_RUNTIME_ENTRY(AllocateArray, 2) {
  const Instance& length = Instance::CheckedHandle(arguments.ArgAt(0));
  if (!length.IsSmi()) {
    const String& error = String::Handle(String::NewFormatted(
        "Length must be an integer in the range [0..%" Pd "].",
        Array::kMaxElements));
    Exceptions::ThrowArgumentError(error);
  }
  const intptr_t len = Smi::Cast(length).Value();
  if (len < 0) {
    const String& error = String::Handle(String::NewFormatted(
        "Length (%" Pd ") must be an integer in the range [0..%" Pd "].",
        len, Array::kMaxElements));
    Exceptions::ThrowArgumentError(error);
  }

  const Array& array = Array::Handle(Array::New(len));
  arguments.SetReturn(array);
  TypeArguments& element_type =
      TypeArguments::CheckedHandle(arguments.ArgAt(1));
  // An Array is raw or takes one type argument. However, its type argument
  // vector may be longer than 1 due to a type optimization reusing the type
  // argument vector of the instantiator.
  ASSERT(element_type.IsNull() ||
         ((element_type.Length() >= 1) && element_type.IsInstantiated()));
  array.SetTypeArguments(element_type);  // May be null.
}


// Helper returning the token position of the Dart caller.
static intptr_t GetCallerLocation() {
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  return caller_frame->GetTokenPos();
}


// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 2) {
  const Class& cls = Class::CheckedHandle(arguments.ArgAt(0));

#ifdef DEBUG
  if (FLAG_gc_at_instance_allocation != NULL) {
    const String& name = String::Handle(cls.Name());
    if (String::EqualsIgnoringPrivateKey(
            name,
            String::Handle(String::New(FLAG_gc_at_instance_allocation)))) {
      Isolate::Current()->heap()->CollectAllGarbage();
    }
  }
#endif

  const Instance& instance = Instance::Handle(Instance::New(cls));

  arguments.SetReturn(instance);
  if (cls.NumTypeArguments() == 0) {
    // No type arguments required for a non-parameterized type.
    ASSERT(Instance::CheckedHandle(arguments.ArgAt(1)).IsNull());
    return;
  }
  TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(1));
  // Unless null (for a raw type), the type argument vector may be longer than
  // necessary due to a type optimization reusing the type argument vector of
  // the instantiator.
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.IsInstantiated() &&
          (type_arguments.Length() >= cls.NumTypeArguments())));
  instance.SetTypeArguments(type_arguments);
}


// Instantiate type.
// Arg0: uninstantiated type.
// Arg1: instantiator type arguments.
// Return value: instantiated type.
DEFINE_RUNTIME_ENTRY(InstantiateType, 2) {
  AbstractType& type = AbstractType::CheckedHandle(arguments.ArgAt(0));
  const TypeArguments& instantiator =
      TypeArguments::CheckedHandle(arguments.ArgAt(1));
  ASSERT(!type.IsNull() && !type.IsInstantiated());
  ASSERT(instantiator.IsNull() || instantiator.IsInstantiated());
  Error& bound_error = Error::Handle();
  type = type.InstantiateFrom(instantiator, &bound_error);
  if (!bound_error.IsNull()) {
    // Throw a dynamic type error.
    const intptr_t location = GetCallerLocation();
    String& bound_error_message =  String::Handle(
        String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, Symbols::Empty(), Symbols::Empty(),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  if (type.IsTypeRef()) {
    type = TypeRef::Cast(type).type();
    ASSERT(!type.IsTypeRef());
    ASSERT(type.IsCanonical());
  }
  ASSERT(!type.IsNull() && type.IsInstantiated());
  arguments.SetReturn(type);
}


// Instantiate type arguments.
// Arg0: uninstantiated type arguments.
// Arg1: instantiator type arguments.
// Return value: instantiated type arguments.
DEFINE_RUNTIME_ENTRY(InstantiateTypeArguments, 2) {
  TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(0));
  const TypeArguments& instantiator =
      TypeArguments::CheckedHandle(arguments.ArgAt(1));
  ASSERT(!type_arguments.IsNull() && !type_arguments.IsInstantiated());
  ASSERT(instantiator.IsNull() || instantiator.IsInstantiated());
  // Code inlined in the caller should have optimized the case where the
  // instantiator can be reused as type argument vector.
  ASSERT(instantiator.IsNull() || !type_arguments.IsUninstantiatedIdentity());
  if (FLAG_enable_type_checks) {
    Error& bound_error = Error::Handle();
    type_arguments =
        type_arguments.InstantiateAndCanonicalizeFrom(instantiator,
                                                      &bound_error);
    if (!bound_error.IsNull()) {
      // Throw a dynamic type error.
      const intptr_t location = GetCallerLocation();
      String& bound_error_message =  String::Handle(
          String::New(bound_error.ToErrorCString()));
      Exceptions::CreateAndThrowTypeError(
          location, Symbols::Empty(), Symbols::Empty(),
          Symbols::Empty(), bound_error_message);
      UNREACHABLE();
    }
  } else {
    type_arguments =
        type_arguments.InstantiateAndCanonicalizeFrom(instantiator, NULL);
  }
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  arguments.SetReturn(type_arguments);
}


// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  const Smi& num_variables = Smi::CheckedHandle(arguments.ArgAt(0));
  arguments.SetReturn(Context::Handle(Context::New(num_variables.Value())));
}


// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  const Context& ctx = Context::CheckedHandle(arguments.ArgAt(0));
  Context& cloned_ctx = Context::Handle(Context::New(ctx.num_variables()));
  cloned_ctx.set_parent(Context::Handle(ctx.parent()));
  Instance& inst = Instance::Handle(isolate);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  arguments.SetReturn(cloned_ctx);
}


// Helper routine for tracing a type check.
static void PrintTypeCheck(
    const char* message,
    const Instance& instance,
    const AbstractType& type,
    const TypeArguments& instantiator_type_arguments,
    const Bool& result) {
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);

  const Type& instance_type = Type::Handle(instance.GetType());
  ASSERT(instance_type.IsInstantiated());
  if (type.IsInstantiated()) {
    OS::PrintErr("%s: '%s' %" Pd " %s '%s' %" Pd " (pc: %#" Px ").\n",
                 message,
                 String::Handle(instance_type.Name()).ToCString(),
                 Class::Handle(instance_type.type_class()).id(),
                 (result.raw() == Bool::True().raw()) ? "is" : "is !",
                 String::Handle(type.Name()).ToCString(),
                 Class::Handle(type.type_class()).id(),
                 caller_frame->pc());
  } else {
    // Instantiate type before printing.
    Error& bound_error = Error::Handle();
    const AbstractType& instantiated_type = AbstractType::Handle(
        type.InstantiateFrom(instantiator_type_arguments, &bound_error));
    OS::PrintErr("%s: '%s' %s '%s' instantiated from '%s' (pc: %#" Px ").\n",
                 message,
                 String::Handle(instance_type.Name()).ToCString(),
                 (result.raw() == Bool::True().raw()) ? "is" : "is !",
                 String::Handle(instantiated_type.Name()).ToCString(),
                 String::Handle(type.Name()).ToCString(),
                 caller_frame->pc());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
  const Function& function = Function::Handle(
      caller_frame->LookupDartFunction());
  OS::PrintErr(" -> Function %s\n", function.ToFullyQualifiedCString());
}


// This updates the type test cache, an array containing 4-value elements
// (instance class, instance type arguments, instantiator type arguments and
// test_result). It can be applied to classes with type arguments in which
// case it contains just the result of the class subtype test, not including
// the evaluation of type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
// 'instantiator' can be null, in which case inst_targ
static void UpdateTypeTestCache(
    const Instance& instance,
    const AbstractType& type,
    const Instance& instantiator,
    const TypeArguments& instantiator_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  // Since the test is expensive, don't do it unless necessary.
  // The list of disallowed cases will decrease as they are implemented in
  // inlined assembly.
  if (new_cache.IsNull()) {
    if (FLAG_trace_type_checks) {
      OS::Print("UpdateTypeTestCache: cache is null\n");
    }
    return;
  }
  if (instance.IsSmi()) {
    if (FLAG_trace_type_checks) {
      OS::Print("UpdateTypeTestCache: instance is Smi\n");
    }
    return;
  }
  TypeArguments& instance_type_arguments =
      TypeArguments::Handle();
  const Class& instance_class = Class::Handle(instance.clazz());

  if (instance_class.NumTypeArguments() > 0) {
    instance_type_arguments = instance.GetTypeArguments();
  }

  const intptr_t len = new_cache.NumberOfChecks();
  if (len >= FLAG_max_subtype_cache_entries) {
    return;
  }
#if defined(DEBUG)
  ASSERT(instance_type_arguments.IsNull() ||
         instance_type_arguments.IsCanonical());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsCanonical());
  intptr_t last_instance_class_id = -1;
  TypeArguments& last_instance_type_arguments =
      TypeArguments::Handle();
  TypeArguments& last_instantiator_type_arguments =
      TypeArguments::Handle();
  Bool& last_result = Bool::Handle();
  for (intptr_t i = 0; i < len; ++i) {
    new_cache.GetCheck(
        i,
        &last_instance_class_id,
        &last_instance_type_arguments,
        &last_instantiator_type_arguments,
        &last_result);
    if ((last_instance_class_id == instance_class.id()) &&
        (last_instance_type_arguments.raw() == instance_type_arguments.raw()) &&
        (last_instantiator_type_arguments.raw() ==
         instantiator_type_arguments.raw())) {
      OS::PrintErr("  Error in test cache %p ix: %" Pd ",", new_cache.raw(), i);
      PrintTypeCheck(" duplicate cache entry", instance, type,
          instantiator_type_arguments, result);
      UNREACHABLE();
      return;
    }
  }
#endif
  new_cache.AddCheck(instance_class.id(),
                     instance_type_arguments,
                     instantiator_type_arguments,
                     result);
  if (FLAG_trace_type_checks) {
    AbstractType& test_type = AbstractType::Handle(type.raw());
    if (!test_type.IsInstantiated()) {
      Error& bound_error = Error::Handle();
      test_type = type.InstantiateFrom(instantiator_type_arguments,
                                       &bound_error);
      ASSERT(bound_error.IsNull());  // Malbounded types are not optimized.
    }
    OS::PrintErr("  Updated test cache %p ix: %" Pd " with "
        "(cid: %" Pd ", type-args: %p, instantiator: %p, result: %s)\n"
        "    instance  [class: (%p '%s' cid: %" Pd "),    type-args: %p %s]\n"
        "    test-type [class: (%p '%s' cid: %" Pd "), in-type-args: %p %s]\n",
        new_cache.raw(),
        len,

        instance_class.id(),
        instance_type_arguments.raw(),
        instantiator_type_arguments.raw(),
        result.ToCString(),

        instance_class.raw(),
        String::Handle(instance_class.Name()).ToCString(),
        instance_class.id(),
        instance_type_arguments.raw(),
        instance_type_arguments.ToCString(),

        test_type.type_class(),
        String::Handle(Class::Handle(test_type.type_class()).Name()).
            ToCString(),
        Class::Handle(test_type.type_class()).id(),
        instantiator_type_arguments.raw(),
        instantiator_type_arguments.ToCString());
  }
}


// Check that the given instance is an instance of the given type.
// Tested instance may not be null, because the null test is inlined.
// Arg0: instance being checked.
// Arg1: type.
// Arg2: instantiator (or null).
// Arg3: type arguments of the instantiator of the type.
// Arg4: SubtypeTestCache.
// Return value: true or false, or may throw a type error in checked mode.
DEFINE_RUNTIME_ENTRY(Instanceof, 5) {
  const Instance& instance = Instance::CheckedHandle(arguments.ArgAt(0));
  const AbstractType& type = AbstractType::CheckedHandle(arguments.ArgAt(1));
  const Instance& instantiator = Instance::CheckedHandle(arguments.ArgAt(2));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(3));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.ArgAt(4));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsDynamicType());  // No need to check assignment.
  ASSERT(!type.IsMalformed());  // Already checked in code generator.
  ASSERT(!type.IsMalbounded());  // Already checked in code generator.
  Error& bound_error = Error::Handle();
  const Bool& result =
      Bool::Get(instance.IsInstanceOf(type,
                                      instantiator_type_arguments,
                                      &bound_error));
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf",
        instance, type, instantiator_type_arguments, result);
  }
  if (!result.value() && !bound_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    const intptr_t location = GetCallerLocation();
    String& bound_error_message =  String::Handle(
        String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, Symbols::Empty(), Symbols::Empty(),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(instance, type, instantiator,
                      instantiator_type_arguments, result, cache);
  arguments.SetReturn(result);
}


// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Arg0: instance being assigned.
// Arg1: type being assigned to.
// Arg2: instantiator (or null).
// Arg3: type arguments of the instantiator of the type being assigned to.
// Arg4: name of variable being assigned to.
// Arg5: SubtypeTestCache.
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 6) {
  const Instance& src_instance = Instance::CheckedHandle(arguments.ArgAt(0));
  const AbstractType& dst_type =
      AbstractType::CheckedHandle(arguments.ArgAt(1));
  const Instance& dst_instantiator =
      Instance::CheckedHandle(arguments.ArgAt(2));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(3));
  const String& dst_name = String::CheckedHandle(arguments.ArgAt(4));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.ArgAt(5));
  ASSERT(!dst_type.IsDynamicType());  // No need to check assignment.
  ASSERT(!dst_type.IsMalformed());  // Already checked in code generator.
  ASSERT(!dst_type.IsMalbounded());  // Already checked in code generator.
  ASSERT(!src_instance.IsNull());  // Already checked in inlined code.

  Error& bound_error = Error::Handle();
  const bool is_instance_of = src_instance.IsInstanceOf(
      dst_type, instantiator_type_arguments, &bound_error);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck",
                   src_instance, dst_type, instantiator_type_arguments,
                   Bool::Get(is_instance_of));
  }
  if (!is_instance_of) {
    // Throw a dynamic type error.
    const intptr_t location = GetCallerLocation();
    const AbstractType& src_type = AbstractType::Handle(src_instance.GetType());
    String& src_type_name = String::Handle(src_type.UserVisibleName());
    String& dst_type_name = String::Handle();
    Library& dst_type_lib = Library::Handle();
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      const AbstractType& instantiated_dst_type = AbstractType::Handle(
          dst_type.InstantiateFrom(instantiator_type_arguments, NULL));
      // Note that instantiated_dst_type may be malbounded.
      dst_type_name = instantiated_dst_type.UserVisibleName();
      dst_type_lib =
          Class::Handle(instantiated_dst_type.type_class()).library();
    } else {
      dst_type_name = dst_type.UserVisibleName();
      dst_type_lib = Class::Handle(dst_type.type_class()).library();
    }
    String& bound_error_message =  String::Handle();
    if (!bound_error.IsNull()) {
      ASSERT(FLAG_enable_type_checks);
      bound_error_message = String::New(bound_error.ToErrorCString());
    }
    if (src_type_name.Equals(dst_type_name)) {
      // Qualify the names with their libraries.
      String& lib_name = String::Handle();
      lib_name = Library::Handle(
          Class::Handle(src_type.type_class()).library()).name();
      if (lib_name.Length() != 0) {
        lib_name = String::Concat(lib_name, Symbols::Dot());
        src_type_name = String::Concat(lib_name, src_type_name);
      }
      lib_name = dst_type_lib.name();
      if (lib_name.Length() != 0) {
        lib_name = String::Concat(lib_name, Symbols::Dot());
        dst_type_name = String::Concat(lib_name, dst_type_name);
      }
    }
    Exceptions::CreateAndThrowTypeError(location, src_type_name, dst_type_name,
                                        dst_name, bound_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(src_instance, dst_type,
                      dst_instantiator, instantiator_type_arguments,
                      Bool::True(), cache);
  arguments.SetReturn(src_instance);
}


// Report that the type of the given object is not bool in conditional context.
// Arg0: bad object.
// Return value: none, throws a TypeError.
DEFINE_RUNTIME_ENTRY(NonBoolTypeError, 1) {
  const intptr_t location = GetCallerLocation();
  const Instance& src_instance = Instance::CheckedHandle(arguments.ArgAt(0));
  ASSERT(src_instance.IsNull() || !src_instance.IsBool());
  const Type& bool_interface = Type::Handle(Type::BoolType());
  const AbstractType& src_type = AbstractType::Handle(src_instance.GetType());
  const String& src_type_name = String::Handle(src_type.UserVisibleName());
  const String& bool_type_name =
      String::Handle(bool_interface.UserVisibleName());
  const String& no_bound_error = String::Handle();
  Exceptions::CreateAndThrowTypeError(location, src_type_name, bool_type_name,
                                      Symbols::BooleanExpression(),
                                      no_bound_error);
  UNREACHABLE();
}


// Report that the type of the type check is malformed or malbounded.
// Arg0: src value.
// Arg1: name of destination being assigned to.
// Arg2: type of destination being assigned to.
// Return value: none, throws an exception.
DEFINE_RUNTIME_ENTRY(BadTypeError, 3) {
  const intptr_t location = GetCallerLocation();
  const Instance& src_value = Instance::CheckedHandle(arguments.ArgAt(0));
  const String& dst_name = String::CheckedHandle(arguments.ArgAt(1));
  const AbstractType& dst_type =
      AbstractType::CheckedHandle(arguments.ArgAt(2));
  const AbstractType& src_type = AbstractType::Handle(src_value.GetType());
  const String& src_type_name = String::Handle(src_type.UserVisibleName());

  String& dst_type_name = String::Handle();
  LanguageError& error = LanguageError::Handle(dst_type.error());
  ASSERT(!error.IsNull());
  if (error.kind() == Report::kMalformedType) {
    dst_type_name = Symbols::Malformed().raw();
  } else {
    ASSERT(error.kind() == Report::kMalboundedType);
    dst_type_name = Symbols::Malbounded().raw();
  }
  const String& error_message = String::ZoneHandle(
      Symbols::New(error.ToErrorCString()));
  Exceptions::CreateAndThrowTypeError(
      location, src_type_name, dst_type_name, dst_name, error_message);
  UNREACHABLE();
}


DEFINE_RUNTIME_ENTRY(Throw, 1) {
  const Instance& exception =
      Instance::CheckedHandle(isolate, arguments.ArgAt(0));
  Exceptions::Throw(isolate, exception);
}


DEFINE_RUNTIME_ENTRY(ReThrow, 2) {
  const Instance& exception =
      Instance::CheckedHandle(isolate, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(isolate, arguments.ArgAt(1));
  Exceptions::ReThrow(isolate, exception, stacktrace);
}


// Patches static call in optimized code with the target's entry point.
// Compiles target if necessary.
DEFINE_RUNTIME_ENTRY(PatchStaticCall, 0) {
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& caller_code = Code::Handle(caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      caller_code.GetStaticCallTargetFunctionAt(caller_frame->pc()));
  if (!target_function.HasCode()) {
    const Error& error =
        Error::Handle(Compiler::CompileFunction(isolate, target_function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  const Code& target_code = Code::Handle(target_function.CurrentCode());
  // Before patching verify that we are not repeatedly patching to the same
  // target.
  ASSERT(target_code.EntryPoint() !=
         CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code));
  const Instructions& instrs =
      Instructions::Handle(caller_code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    CodePatcher::PatchStaticCallAt(caller_frame->pc(), caller_code,
                                   target_code.EntryPoint());
    caller_code.SetStaticCallTargetCodeAt(caller_frame->pc(), target_code);
  }
  if (FLAG_trace_patching) {
    OS::PrintErr("PatchStaticCall: patching caller pc %#" Px ""
        " to '%s' new entry point %#" Px " (%s)\n",
        caller_frame->pc(),
        target_function.ToFullyQualifiedCString(),
        target_code.EntryPoint(),
        target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  arguments.SetReturn(target_code);
}


// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void CheckResultError(const Object& result) {
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
}


// Gets called from debug stub when code reaches a breakpoint
// set on a runtime stub call.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  ASSERT(isolate->debugger() != NULL);
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  uword orig_stub =
      isolate->debugger()->GetPatchedStubAddress(caller_frame->pc());
  isolate->debugger()->SignalBpReached();
  ASSERT((orig_stub & kSmiTagMask) == kSmiTag);
  arguments.SetReturn(Smi::Handle(reinterpret_cast<RawSmi*>(orig_stub)));
}


DEFINE_RUNTIME_ENTRY(SingleStepHandler, 0) {
  ASSERT(isolate->debugger() != NULL);
  isolate->debugger()->DebuggerStepCallback();
}


// An instance call of the form o.f(...) could not be resolved.  Check if
// there is a getter with the same name.  If so, invoke it.  If the value is
// a closure, invoke it with the given arguments.  If the value is a
// non-closure, attempt to invoke "call" on it.
static bool ResolveCallThroughGetter(const Instance& receiver,
                                     const Class& receiver_class,
                                     const String& target_name,
                                     const Array& arguments_descriptor,
                                     Function* result) {
  // 1. Check if there is a getter with the same name.
  const String& getter_name = String::Handle(Field::GetterName(target_name));
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& getter = Function::Handle(
      Resolver::ResolveDynamicForReceiverClass(receiver_class,
                                               getter_name,
                                               args_desc));
  if (getter.IsNull() || getter.IsMethodExtractor()) {
    return false;
  }

  const Function& target_function =
      Function::Handle(receiver_class.GetInvocationDispatcher(
          target_name,
          arguments_descriptor,
          RawFunction::kInvokeFieldDispatcher));
  ASSERT(!target_function.IsNull());
  if (FLAG_trace_ic) {
    OS::PrintErr("InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        Class::Handle(receiver.clazz()).ToCString(),
        receiver.GetClassId(),
        target_function.ToCString());
  }
  *result = target_function.raw();
  return true;
}


// Handle other invocations (implicit closures, noSuchMethod).
RawFunction* InlineCacheMissHelper(
    const Instance& receiver,
    const ICData& ic_data) {
  const Array& args_descriptor = Array::Handle(ic_data.arguments_descriptor());

  const Class& receiver_class = Class::Handle(receiver.clazz());
  const String& target_name = String::Handle(ic_data.target_name());

  Function& result = Function::Handle();
  if (!ResolveCallThroughGetter(receiver,
                                receiver_class,
                                target_name,
                                args_descriptor,
                                &result)) {
    ArgumentsDescriptor desc(args_descriptor);
    const Function& target_function =
        Function::Handle(receiver_class.GetInvocationDispatcher(
            target_name,
            args_descriptor,
            RawFunction::kNoSuchMethodDispatcher));
    if (FLAG_trace_ic) {
      OS::PrintErr("NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          Class::Handle(receiver.clazz()).ToCString(),
          receiver.GetClassId(),
          target_function.ToCString());
    }
    result = target_function.raw();
  }
  return result.raw();
}

static RawFunction* InlineCacheMissHandler(
    const GrowableArray<const Instance*>& args,
    const ICData& ic_data) {
  const Instance& receiver = *args[0];
  ArgumentsDescriptor
      arguments_descriptor(Array::Handle(ic_data.arguments_descriptor()));
  String& function_name = String::Handle(ic_data.target_name());
  ASSERT(function_name.IsSymbol());
  Function& target_function = Function::Handle(
      Resolver::ResolveDynamic(receiver, function_name, arguments_descriptor));
  if (target_function.IsNull()) {
    if (FLAG_trace_ic) {
      OS::PrintErr("InlineCacheMissHandler NULL function for %s receiver: %s\n",
                   String::Handle(ic_data.target_name()).ToCString(),
                   receiver.ToCString());
    }
    target_function = InlineCacheMissHelper(receiver, ic_data);
  }
  ASSERT(!target_function.IsNull());
  if (args.length() == 1) {
    ic_data.AddReceiverCheck(args[0]->GetClassId(), target_function);
  } else {
    GrowableArray<intptr_t> class_ids(args.length());
    ASSERT(ic_data.NumArgsTested() == args.length());
    for (intptr_t i = 0; i < args.length(); i++) {
      class_ids.Add(args[i]->GetClassId());
    }
    ic_data.AddCheck(class_ids, target_function);
  }
  if (FLAG_trace_ic_miss_in_optimized || FLAG_trace_ic) {
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    if (FLAG_trace_ic_miss_in_optimized) {
      const Code& caller = Code::Handle(Code::LookupCode(caller_frame->pc()));
      if (caller.is_optimized()) {
        OS::PrintErr("IC miss in optimized code; call %s -> %s\n",
            Function::Handle(caller.function()).ToCString(),
            target_function.ToCString());
      }
    }
    if (FLAG_trace_ic) {
      OS::PrintErr("InlineCacheMissHandler %" Pd " call at %#" Px "' "
                   "adding <%s> id:%" Pd " -> <%s>\n",
          args.length(),
          caller_frame->pc(),
          Class::Handle(receiver.clazz()).ToCString(),
          receiver.GetClassId(),
          target_function.ToCString());
    }
  }
  return target_function.raw();
}


// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 2) {
  const Instance& receiver = Instance::CheckedHandle(arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(1));
  GrowableArray<const Instance*> args(1);
  args.Add(&receiver);
  if (FLAG_warn_on_javascript_compatibility) {
    if (receiver.IsDouble() &&
        String::Handle(ic_data.target_name()).Equals(Symbols::toString())) {
      const double value = Double::Cast(receiver).value();
      if (floor(value) == value) {
        Report::JSWarningFromIC(ic_data,
                                "string representation of an integral value "
                                "of type 'double' has no decimal mark and "
                                "no fractional part");
      }
    }
  }
  const Function& result =
      Function::Handle(InlineCacheMissHandler(args, ic_data));
  arguments.SetReturn(result);
}


// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Arg2: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs, 3) {
  const Instance& receiver = Instance::CheckedHandle(arguments.ArgAt(0));
  const Instance& other = Instance::CheckedHandle(arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(2));
  GrowableArray<const Instance*> args(2);
  args.Add(&receiver);
  args.Add(&other);
  const Function& result =
      Function::Handle(InlineCacheMissHandler(args, ic_data));
  arguments.SetReturn(result);
}


// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Arg2: Second argument after receiver.
//   Arg3: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerThreeArgs, 4) {
  const Instance& receiver = Instance::CheckedHandle(arguments.ArgAt(0));
  const Instance& arg1 = Instance::CheckedHandle(arguments.ArgAt(1));
  const Instance& arg2 = Instance::CheckedHandle(arguments.ArgAt(2));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(3));
  GrowableArray<const Instance*> args(3);
  args.Add(&receiver);
  args.Add(&arg1);
  args.Add(&arg2);
  const Function& result =
      Function::Handle(InlineCacheMissHandler(args, ic_data));
  arguments.SetReturn(result);
}


// Handles a static call in unoptimized code that has one argument type not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument.
// Arg1: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerOneArg, 2) {
  const Instance& arg = Instance::CheckedHandle(arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(1));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(ic_data.NumberOfChecks() == 1);
  const Function& target = Function::Handle(ic_data.GetTargetAt(0));
  if (!target.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(isolate,
                                                                 target));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  ASSERT(!target.IsNull() && target.HasCode());
  ic_data.AddReceiverCheck(arg.GetClassId(), target, 1);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    OS::PrintErr("StaticCallMissHandler at %#" Px
                 " target %s (%" Pd ")\n",
                 caller_frame->pc(), target.ToCString(), arg.GetClassId());
  }
  arguments.SetReturn(target);
}


// Handles a static call in unoptimized code that has two argument types not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument 0.
// Arg1: argument 1.
// Arg2: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerTwoArgs, 3) {
  const Instance& arg0 = Instance::CheckedHandle(arguments.ArgAt(0));
  const Instance& arg1 = Instance::CheckedHandle(arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(2));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(ic_data.NumberOfChecks() > 0);
  const Function& target = Function::Handle(ic_data.GetTargetAt(0));
  if (!target.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(isolate,
                                                                 target));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  ASSERT(!target.IsNull() && target.HasCode());
  GrowableArray<intptr_t> cids(2);
  cids.Add(arg0.GetClassId());
  cids.Add(arg1.GetClassId());
  ic_data.AddCheck(cids, target);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    OS::PrintErr("StaticCallMissHandler at %#" Px
                 " target %s (%" Pd ", %" Pd ")\n",
                 caller_frame->pc(), target.ToCString(), cids[0], cids[1]);
  }
  arguments.SetReturn(target);
}


// Handle a miss of a megamorphic cache.
//   Arg0: Receiver.
//   Arg1: ICData object.
//   Arg2: Arguments descriptor array.

//   Returns: target function to call.
DEFINE_RUNTIME_ENTRY(MegamorphicCacheMissHandler, 3) {
  const Instance& receiver = Instance::CheckedHandle(arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(1));
  const Array& descriptor = Array::CheckedHandle(arguments.ArgAt(2));
  const String& name = String::Handle(ic_data.target_name());
  const MegamorphicCache& cache = MegamorphicCache::Handle(
      isolate->megamorphic_cache_table()->Lookup(name, descriptor));
  Class& cls = Class::Handle(receiver.clazz());
  ASSERT(!cls.IsNull());
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic IC miss, class=%s, function=%s\n",
                 cls.ToCString(), name.ToCString());
  }

  ArgumentsDescriptor args_desc(descriptor);
  Function& target_function = Function::Handle(
      Resolver::ResolveDynamicForReceiverClass(cls,
                                               name,
                                               args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, ic_data);
  }

  ASSERT(!target_function.IsNull());
  // Insert function found into cache and return it.
  cache.EnsureCapacity();
  const Smi& class_id = Smi::Handle(Smi::New(cls.id()));
  cache.Insert(class_id, target_function);
  arguments.SetReturn(target_function);
}


// Invoke appropriate noSuchMethod function.
// Arg0: receiver (closure object)
// Arg1: arguments descriptor array.
// Arg2: arguments array.
DEFINE_RUNTIME_ENTRY(InvokeClosureNoSuchMethod, 3) {
  const Instance& receiver = Instance::CheckedHandle(arguments.ArgAt(0));
  const Array& orig_arguments_desc = Array::CheckedHandle(arguments.ArgAt(1));
  const Array& orig_arguments = Array::CheckedHandle(arguments.ArgAt(2));

  // For closure the function name is always 'call'. Replace it with the
  // name of the closurized function so that exception contains more
  // relevant information.
  ASSERT(receiver.IsClosure());
  const Function& function = Function::Handle(Closure::function(receiver));
  const String& original_function_name =
      String::Handle(function.QualifiedUserVisibleName());
  const Object& result = Object::Handle(
      DartEntry::InvokeNoSuchMethod(receiver,
                                    original_function_name,
                                    orig_arguments,
                                    orig_arguments_desc));
  CheckResultError(result);
  arguments.SetReturn(result);
}


static bool CanOptimizeFunction(const Function& function, Isolate* isolate) {
  const intptr_t kLowInvocationCount = -100000000;
  if (isolate->debugger()->IsStepping() ||
      isolate->debugger()->HasBreakpoint(function)) {
    // We cannot set breakpoints and single step in optimized code,
    // so do not optimize the function.
    function.set_usage_counter(0);
    return false;
  }
  if (function.deoptimization_counter() >=
      FLAG_deoptimization_counter_threshold) {
    if (FLAG_trace_failed_optimization_attempts ||
        FLAG_stop_on_excessive_deoptimization) {
      OS::PrintErr("Too Many Deoptimizations: %s\n",
          function.ToFullyQualifiedCString());
      if (FLAG_stop_on_excessive_deoptimization) {
        FATAL("Stop on excessive deoptimization");
      }
    }
    // TODO(srdjan): Investigate excessive deoptimization.
    function.set_usage_counter(kLowInvocationCount);
    return false;
  }
  if (FLAG_optimization_filter != NULL) {
    // FLAG_optimization_filter is a comma-separated list of strings that are
    // matched against the fully-qualified function name.
    char* save_ptr;  // Needed for strtok_r.
    const char* function_name = function.ToFullyQualifiedCString();
    intptr_t len = strlen(FLAG_optimization_filter) + 1;  // Length with \0.
    char* filter = new char[len];
    strncpy(filter, FLAG_optimization_filter, len);  // strtok modifies arg 1.
    char* token = strtok_r(filter, ",", &save_ptr);
    bool found = false;
    while (token != NULL) {
      if (strstr(function_name, token) != NULL) {
        found = true;
        break;
      }
      token = strtok_r(NULL, ",", &save_ptr);
    }
    delete[] filter;
    if (!found) {
      function.set_usage_counter(kLowInvocationCount);
      return false;
    }
  }
  if (!function.IsOptimizable()) {
    if (FLAG_trace_failed_optimization_attempts) {
      OS::PrintErr("Not Optimizable: %s\n", function.ToFullyQualifiedCString());
    }
    // TODO(5442338): Abort as this should not happen.
    function.set_usage_counter(kLowInvocationCount);
    return false;
  }
  return true;
}


DEFINE_RUNTIME_ENTRY(StackOverflow, 0) {
#if defined(USING_SIMULATOR)
  uword stack_pos = Simulator::Current()->get_register(SPREG);
#else
  uword stack_pos = reinterpret_cast<uword>(&arguments);
#endif
  // Always clear the stack overflow flags.  They are meant for this
  // particular stack overflow runtime call and are not meant to
  // persist.
  uword stack_overflow_flags = isolate->GetAndClearStackOverflowFlags();

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow now and leave the interrupt for next
  // time.
  if (stack_pos < isolate->saved_stack_limit()) {
    // Use the preallocated stack overflow exception to avoid calling
    // into dart code.
    const Instance& exception =
        Instance::Handle(isolate->object_store()->stack_overflow());
    Exceptions::Throw(isolate, exception);
    UNREACHABLE();
  }

  // The following code is used to stress test deoptimization and
  // debugger stack tracing.
  bool do_deopt = false;
  bool do_stacktrace = false;
  if ((FLAG_deoptimize_every > 0) || (FLAG_stacktrace_every > 0)) {
    // TODO(turnidge): To make --deoptimize_every and
    // --stacktrace-every faster we could move this increment/test to
    // the generated code.
    int32_t count = isolate->IncrementAndGetStackOverflowCount();
    if (FLAG_deoptimize_every > 0 &&
        (count % FLAG_deoptimize_every) == 0) {
      do_deopt = true;
    }
    if (FLAG_stacktrace_every > 0 &&
        (count % FLAG_stacktrace_every) == 0) {
      do_stacktrace = true;
    }
  }
  if ((FLAG_deoptimize_filter != NULL) || (FLAG_stacktrace_filter != NULL)) {
    DartFrameIterator iterator;
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != NULL);
    const Code& code = Code::Handle(frame->LookupDartCode());
    ASSERT(!code.IsNull());
    const Function& function = Function::Handle(code.function());
    ASSERT(!function.IsNull());
    const char* function_name = function.ToFullyQualifiedCString();
    ASSERT(function_name != NULL);
    if (code.is_optimized() &&
        FLAG_deoptimize_filter != NULL &&
        strstr(function_name, FLAG_deoptimize_filter) != NULL) {
      OS::PrintErr("*** Forcing deoptimization (%s)\n",
                   function.ToFullyQualifiedCString());
      do_deopt = true;
    }
    if (FLAG_stacktrace_filter != NULL &&
        strstr(function_name, FLAG_stacktrace_filter) != NULL) {
      OS::PrintErr("*** Computing stacktrace (%s)\n",
                   function.ToFullyQualifiedCString());
      do_stacktrace = true;
    }
  }
  if (do_deopt) {
    // TODO(turnidge): Consider using DeoptimizeAt instead.
    DeoptimizeAll();
  }
  if (do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      const int num_vars = frame->NumLocalVariables();
      intptr_t unused;
      for (intptr_t v = 0; v < num_vars; v++) {
        frame->VariableAt(v, &var_name, &unused, &unused, &var_value);
      }
    }
  }

  uword interrupt_bits = isolate->GetAndClearInterrupts();
  if ((interrupt_bits & Isolate::kStoreBufferInterrupt) != 0) {
    if (FLAG_verbose_gc) {
      OS::PrintErr("Scavenge scheduled by store buffer overflow.\n");
    }
    isolate->heap()->CollectGarbage(Heap::kNew);
  }
  if ((interrupt_bits & Isolate::kMessageInterrupt) != 0) {
    isolate->message_handler()->HandleOOBMessages();
  }
  if ((interrupt_bits & Isolate::kApiInterrupt) != 0) {
    // Signal isolate interrupt event.
    Debugger::SignalIsolateInterrupted();

    Dart_IsolateInterruptCallback callback = isolate->InterruptCallback();
    if (callback) {
      if ((*callback)()) {
        return;
      } else {
        // TODO(turnidge): Unwind the stack.
        UNIMPLEMENTED();
      }
    }
  }
  if ((interrupt_bits & Isolate::kVmStatusInterrupt) != 0) {
    Dart_IsolateInterruptCallback callback = isolate->VmStatsCallback();
    if (callback) {
      (*callback)();
    }
  }

  if ((stack_overflow_flags & Isolate::kOsrRequest) != 0) {
    ASSERT(FLAG_use_osr);
    DartFrameIterator iterator;
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != NULL);
    const Code& code = Code::ZoneHandle(frame->LookupDartCode());
    ASSERT(!code.IsNull());
    const Function& function = Function::Handle(code.function());
    ASSERT(!function.IsNull());
    // Since the code is referenced from the frame and the ZoneHandle,
    // it cannot have been removed from the function.
    ASSERT(function.HasCode());
    if (!CanOptimizeFunction(function, isolate)) {
      return;
    }
    intptr_t osr_id =
        Code::Handle(function.unoptimized_code()).GetDeoptIdForOsr(frame->pc());
    if (FLAG_trace_osr) {
      OS::Print("Attempting OSR for %s at id=%" Pd ", count=%" Pd "\n",
                function.ToFullyQualifiedCString(),
                osr_id,
                function.usage_counter());
    }

    const Code& original_code = Code::Handle(function.CurrentCode());
    // Since the code is referenced from the frame and the ZoneHandle,
    // it cannot have been removed from the function.
    ASSERT(!original_code.IsNull());
    const Error& error = Error::Handle(Compiler::CompileOptimizedFunction(
        isolate, function, osr_id));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }

    const Code& optimized_code = Code::Handle(function.CurrentCode());
    // The current code will not be changed in the case that the compiler
    // bailed out during OSR compilation.
    if (optimized_code.raw() != original_code.raw()) {
      // The OSR code does not work for calling the function, so restore the
      // unoptimized code.  Patch the stack frame to return into the OSR
      // code.
      uword optimized_entry =
          Instructions::Handle(optimized_code.instructions()).EntryPoint();
      function.AttachCode(original_code);
      frame->set_pc(optimized_entry);
    }
  }
}


DEFINE_RUNTIME_ENTRY(TraceICCall, 2) {
  const ICData& ic_data = ICData::CheckedHandle(arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(arguments.ArgAt(1));
  DartFrameIterator iterator;
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  OS::PrintErr("IC call @%#" Px ": ICData: %p cnt:%" Pd " nchecks: %" Pd
      " %s\n",
      frame->pc(),
      ic_data.raw(),
      function.usage_counter(),
      ic_data.NumberOfChecks(),
      function.ToFullyQualifiedCString());
}


// This is called from function that needs to be optimized.
// The requesting function can be already optimized (reoptimization).
// Returns the Code object where to continue execution.
DEFINE_RUNTIME_ENTRY(OptimizeInvokedFunction, 1) {
  const Function& function = Function::CheckedHandle(isolate,
                                                     arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  if (CanOptimizeFunction(function, isolate)) {
    // Reset usage counter for reoptimization before calling optimizer to
    // prevent recursive triggering of function optimization.
    function.set_usage_counter(0);
    const Error& error = Error::Handle(
        isolate, Compiler::CompileOptimizedFunction(isolate, function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
    const Code& optimized_code = Code::Handle(isolate, function.CurrentCode());
    ASSERT(!optimized_code.IsNull());
  }
  arguments.SetReturn(Code::Handle(isolate, function.CurrentCode()));
}


// The caller must be a static call in a Dart frame, or an entry frame.
// Patch static call to point to valid code's entry point.
DEFINE_RUNTIME_ENTRY(FixCallersTarget, 0) {
  StackFrameIterator iterator(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != NULL);
  }
  if (frame->IsEntryFrame()) {
    // Since function's current code is always unpatched, the entry frame always
    // calls to unpatched code.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(isolate, frame->LookupDartCode());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      isolate, caller_code.GetStaticCallTargetFunctionAt(frame->pc()));
  const Code& target_code = Code::Handle(
      isolate, caller_code.GetStaticCallTargetCodeAt(frame->pc()));
  ASSERT(!target_code.IsNull());
  if (!target_function.HasCode()) {
    const Error& error = Error::Handle(
        isolate, Compiler::CompileFunction(isolate, target_function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  ASSERT(target_function.HasCode());
  ASSERT(target_function.raw() == target_code.function());

  const Code& current_target_code = Code::Handle(
      isolate, target_function.CurrentCode());
  const Instructions& instrs = Instructions::Handle(
      isolate, caller_code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    CodePatcher::PatchStaticCallAt(frame->pc(), caller_code,
                                   current_target_code.EntryPoint());
    caller_code.SetStaticCallTargetCodeAt(frame->pc(), current_target_code);
  }
  if (FLAG_trace_patching) {
    OS::PrintErr("FixCallersTarget: caller %#" Px " "
        "target '%s' %#" Px " -> %#" Px "\n",
        frame->pc(),
        target_function.ToFullyQualifiedCString(),
        target_code.EntryPoint(),
        current_target_code.EntryPoint());
  }
  arguments.SetReturn(current_target_code);
}


// The caller tried to allocate an instance via an invalidated allocation
// stub.
DEFINE_RUNTIME_ENTRY(FixAllocationStubTarget, 0) {
  StackFrameIterator iterator(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != NULL);
  }
  if (frame->IsEntryFrame()) {
    // There must be a valid Dart frame.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(isolate, frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const uword target =
      CodePatcher::GetStaticCallTargetAt(frame->pc(), caller_code);
  const Code& stub = Code::Handle(isolate, Code::LookupCode(target));
  Class& alloc_class = Class::ZoneHandle(isolate);
  alloc_class ^= stub.owner();
  Code& alloc_stub = Code::Handle(isolate, alloc_class.allocation_stub());
  if (alloc_stub.IsNull()) {
    alloc_stub = isolate->stub_code()->GetAllocationStubForClass(alloc_class);
    ASSERT(!CodePatcher::IsEntryPatched(alloc_stub));
  }
  const Instructions& instrs =
      Instructions::Handle(isolate, caller_code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    CodePatcher::PatchStaticCallAt(frame->pc(),
                                   caller_code,
                                   alloc_stub.EntryPoint());
  }
  if (FLAG_trace_patching) {
    OS::PrintErr("FixAllocationStubTarget: caller %#" Px " alloc-class %s "
        " -> %#" Px "\n",
        frame->pc(),
        alloc_class.ToCString(),
        alloc_stub.EntryPoint());
  }
  arguments.SetReturn(alloc_stub);
}


const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason) {
  switch (deopt_reason) {
#define DEOPT_REASON_TO_TEXT(name) case ICData::kDeopt##name: return #name;
DEOPT_REASONS(DEOPT_REASON_TO_TEXT)
#undef DEOPT_REASON_TO_TEXT
    default:
      UNREACHABLE();
      return "";
  }
}


void DeoptimizeAt(const Code& optimized_code, uword pc) {
  ASSERT(optimized_code.is_optimized());
  ICData::DeoptReasonId deopt_reason = ICData::kDeoptUnknown;
  const DeoptInfo& deopt_info =
      DeoptInfo::Handle(optimized_code.GetDeoptInfoAtPc(pc, &deopt_reason));
  ASSERT(!deopt_info.IsNull());
  const Function& function = Function::Handle(optimized_code.function());
  const Code& unoptimized_code = Code::Handle(function.unoptimized_code());
  ASSERT(!unoptimized_code.IsNull());
  // The switch to unoptimized code may have already occurred.
  if (function.HasOptimizedCode()) {
    function.SwitchToUnoptimizedCode();
  }
  // Patch call site (lazy deoptimization is quite rare, patching it twice
  // is not a performance issue).
  uword lazy_deopt_jump = optimized_code.GetLazyDeoptPc();
  ASSERT(lazy_deopt_jump != 0);
  const Instructions& instrs =
      Instructions::Handle(optimized_code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    CodePatcher::InsertCallAt(pc, lazy_deopt_jump);
  }
  if (FLAG_trace_patching) {
    const String& name = String::Handle(function.name());
    OS::PrintErr("InsertCallAt: %" Px " to %" Px " for %s\n", pc,
                 lazy_deopt_jump, name.ToCString());
  }
  // Mark code as dead (do not GC its embedded objects).
  optimized_code.set_is_alive(false);
}


// Currently checks only that all optimized frames have kDeoptIndex
// and unoptimized code has the kDeoptAfter.
void DeoptimizeAll() {
  DartFrameIterator iterator;
  StackFrame* frame = iterator.NextFrame();
  Code& optimized_code = Code::Handle();
  while (frame != NULL) {
    optimized_code = frame->LookupDartCode();
    if (optimized_code.is_optimized()) {
      DeoptimizeAt(optimized_code, frame->pc());
    }
    frame = iterator.NextFrame();
  }
}


static void CopySavedRegisters(uword saved_registers_address,
                               fpu_register_t** fpu_registers,
                               intptr_t** cpu_registers) {
  ASSERT(sizeof(fpu_register_t) == kFpuRegisterSize);
  fpu_register_t* fpu_registers_copy =
      new fpu_register_t[kNumberOfFpuRegisters];
  ASSERT(fpu_registers_copy != NULL);
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    fpu_registers_copy[i] =
        *reinterpret_cast<fpu_register_t*>(saved_registers_address);
    saved_registers_address += kFpuRegisterSize;
  }
  *fpu_registers = fpu_registers_copy;

  ASSERT(sizeof(intptr_t) == kWordSize);
  intptr_t* cpu_registers_copy = new intptr_t[kNumberOfCpuRegisters];
  ASSERT(cpu_registers_copy != NULL);
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    cpu_registers_copy[i] =
        *reinterpret_cast<intptr_t*>(saved_registers_address);
    saved_registers_address += kWordSize;
  }
  *cpu_registers = cpu_registers_copy;
}


// Copies saved registers and caller's frame into temporary buffers.
// Returns the stack size of unoptimized frame.
DEFINE_LEAF_RUNTIME_ENTRY(intptr_t, DeoptimizeCopyFrame,
                          1, uword saved_registers_address) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);

  // All registers have been saved below last-fp as if they were locals.
  const uword last_fp = saved_registers_address
                        + (kNumberOfCpuRegisters * kWordSize)
                        + (kNumberOfFpuRegisters * kFpuRegisterSize)
                        - ((kFirstLocalSlotFromFp + 1) * kWordSize);

  // Get optimized code and frame that need to be deoptimized.
  DartFrameIterator iterator(last_fp);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
  ASSERT(optimized_code.is_optimized());

  // Copy the saved registers from the stack.
  fpu_register_t* fpu_registers;
  intptr_t* cpu_registers;
  CopySavedRegisters(saved_registers_address, &fpu_registers, &cpu_registers);

  // Create the DeoptContext.
  DeoptContext* deopt_context =
      new DeoptContext(caller_frame, optimized_code,
                       DeoptContext::kDestIsOriginalFrame,
                       fpu_registers, cpu_registers);
  isolate->set_deopt_context(deopt_context);

  // Stack size (FP - SP) in bytes.
  return deopt_context->DestStackAdjustment() * kWordSize;
}
END_LEAF_RUNTIME_ENTRY


// The stack has been adjusted to fit all values for unoptimized frame.
// Fill the unoptimized frame.
DEFINE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, 1, uword last_fp) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);

  DeoptContext* deopt_context = isolate->deopt_context();
  DartFrameIterator iterator(last_fp);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);

#if defined(DEBUG)
  {
    // The code from the deopt_context.
    const Code& code = Code::Handle(deopt_context->code());

    // The code from our frame.
    const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
    const Function& function = Function::Handle(optimized_code.function());
    ASSERT(!function.IsNull());

    // The code will be the same as before.
    ASSERT(code.raw() == optimized_code.raw());

    // Some sanity checking of the optimized/unoptimized code.
    const Code& unoptimized_code = Code::Handle(function.unoptimized_code());
    ASSERT(!optimized_code.IsNull() && optimized_code.is_optimized());
    ASSERT(!unoptimized_code.IsNull() && !unoptimized_code.is_optimized());
  }
#endif

  // TODO(turnidge): Compute the start of the dest frame in the
  // DeoptContext instead of passing it in here.
  intptr_t* start = reinterpret_cast<intptr_t*>(
      caller_frame->sp() - (kDartFrameFixedSize * kWordSize));
  deopt_context->set_dest_frame(start);
  deopt_context->FillDestFrame();
}
END_LEAF_RUNTIME_ENTRY


// This is the last step in the deoptimization, GC can occur.
// Returns number of bytes to remove from the expression stack of the
// bottom-most deoptimized frame. Those arguments were artificially injected
// under return address to keep them discoverable by GC that can occur during
// materialization phase.
DEFINE_RUNTIME_ENTRY(DeoptimizeMaterialize, 0) {
  DeoptContext* deopt_context = isolate->deopt_context();
  intptr_t deopt_arg_count = deopt_context->MaterializeDeferredObjects();
  isolate->set_deopt_context(NULL);
  delete deopt_context;

  // Return value tells deoptimization stub to remove the given number of bytes
  // from the stack.
  arguments.SetReturn(Smi::Handle(Smi::New(deopt_arg_count * kWordSize)));
}


DEFINE_LEAF_RUNTIME_ENTRY(intptr_t,
                          BigintCompare,
                          2,
                          RawBigint* left,
                          RawBigint* right) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  const Bigint& big_left = Bigint::Handle(left);
  const Bigint& big_right = Bigint::Handle(right);
  return big_left.CompareWith(big_right);
}
END_LEAF_RUNTIME_ENTRY


double DartModulo(double left, double right) {
  double remainder = fmod_ieee(left, right);
  if (remainder == 0.0) {
    // We explicitely switch to the positive 0.0 (just in case it was negative).
    remainder = +0.0;
  } else if (remainder < 0.0) {
    if (right < 0) {
      remainder -= right;
    } else {
      remainder += right;
    }
  }
  return remainder;
}


void SinCos(double arg, double* cos_res, double* sin_res) {
  // The compiler may merge the calls to sincos, if supported. This
  // typically occurs only when compiling for 64-bit targets.
  *cos_res = cos(arg);
  *sin_res = sin(arg);
}


// Update global type feedback recorded for a field recording the assignment
// of the given value.
//   Arg0: Field object;
//   Arg1: Value that is being stored.
DEFINE_RUNTIME_ENTRY(UpdateFieldCid, 2) {
  const Field& field = Field::CheckedHandle(arguments.ArgAt(0));
  const Object& value = Object::Handle(arguments.ArgAt(1));
  field.RecordStore(value);
}


DEFINE_RUNTIME_ENTRY(InitStaticField, 1) {
  const Field& field = Field::CheckedHandle(arguments.ArgAt(0));
  field.EvaluateInitializer();
}

}  // namespace dart
