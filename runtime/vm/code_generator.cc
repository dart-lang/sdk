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
#include "vm/flags.h"
#include "vm/object_store.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/thread_registry.h"
#include "vm/verifier.h"

namespace dart {

DEFINE_FLAG(int, max_subtype_cache_entries, 100,
    "Maximum number of subtype cache entries (number of checks cached).");
DEFINE_FLAG(int, regexp_optimization_counter_threshold, 1000,
    "RegExp's usage-counter value before it is optimized, -1 means never");
DEFINE_FLAG(charp, optimization_filter, NULL, "Optimize only named function");
// TODO(srdjan): Remove this flag once background compilation of regular
// expressions is possible.
DEFINE_FLAG(bool, regexp_opt_in_background, false,
    "Optimize reg-exp functions in background");
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

DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, enable_inlining_annotations);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(int, max_polymorphic_checks);

DEFINE_FLAG(bool, trace_osr, false, "Trace attempts at on-stack replacement.");

DEFINE_FLAG(int, stacktrace_every, 0,
            "Compute debugger stacktrace on every N stack overflow checks");
DEFINE_FLAG(charp, stacktrace_filter, NULL,
            "Compute stacktrace in named function on stack overflow checks");
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
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  if (length.IsSmi()) {
    const intptr_t len = Smi::Cast(length).Value();
    if ((len >= 0) && (len <= Array::kMaxElements)) {
      Heap::Space space = isolate->heap()->SpaceForAllocation(kArrayCid);
      const Array& array = Array::Handle(Array::New(len, space));
      arguments.SetReturn(array);
      TypeArguments& element_type =
          TypeArguments::CheckedHandle(arguments.ArgAt(1));
      // An Array is raw or takes one type argument. However, its type argument
      // vector may be longer than 1 due to a type optimization reusing the type
      // argument vector of the instantiator.
      ASSERT(element_type.IsNull() ||
             ((element_type.Length() >= 1) && element_type.IsInstantiated()));
      array.SetTypeArguments(element_type);  // May be null.
      return;
    }
  }
  // Throw: new RangeError.range(length, 0, Array::kMaxElements, "length");
  const Array& args = Array::Handle(Array::New(4));
  args.SetAt(0, length);
  args.SetAt(1, Integer::Handle(Integer::New(0)));
  args.SetAt(2, Integer::Handle(Integer::New(Array::kMaxElements)));
  args.SetAt(3, Symbols::Length());
  Exceptions::ThrowByType(Exceptions::kRange, args);
}


// Helper returning the token position of the Dart caller.
static TokenPosition GetCallerLocation() {
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
  Heap::Space space = isolate->heap()->SpaceForAllocation(cls.id());
  const Instance& instance = Instance::Handle(Instance::New(cls, space));

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
  type =
      type.InstantiateFrom(instantiator, &bound_error, NULL, NULL, Heap::kOld);
  if (!bound_error.IsNull()) {
    // Throw a dynamic type error.
    const TokenPosition location = GetCallerLocation();
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
  if (isolate->type_checks()) {
    Error& bound_error = Error::Handle();
    type_arguments =
        type_arguments.InstantiateAndCanonicalizeFrom(instantiator,
                                                      &bound_error);
    if (!bound_error.IsNull()) {
      // Throw a dynamic type error.
      const TokenPosition location = GetCallerLocation();
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
  Object& inst = Object::Handle(zone);
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

  const AbstractType& instance_type = AbstractType::Handle(instance.GetType());
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
        type.InstantiateFrom(instantiator_type_arguments, &bound_error,
                             NULL, NULL, Heap::kOld));
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
// (instance class (or function if the instance is a closure), instance type
// arguments, instantiator type arguments and test_result). It can be applied to
// classes with type arguments in which case it contains just the result of the
// class subtype test, not including the evaluation of type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
static void UpdateTypeTestCache(
    const Instance& instance,
    const AbstractType& type,
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
  const Class& instance_class = Class::Handle(instance.clazz());
  Object& instance_class_id_or_function = Object::Handle();
  if (instance_class.IsClosureClass()) {
    instance_class_id_or_function = Closure::Cast(instance).function();
  } else {
    instance_class_id_or_function = Smi::New(instance_class.id());
  }
  TypeArguments& instance_type_arguments = TypeArguments::Handle();
  if (instance_class.IsClosureClass() ||
      (instance_class.NumTypeArguments() > 0)) {
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
  Object& last_instance_class_id_or_function = Object::Handle();
  TypeArguments& last_instance_type_arguments = TypeArguments::Handle();
  TypeArguments& last_instantiator_type_arguments = TypeArguments::Handle();
  Bool& last_result = Bool::Handle();
  for (intptr_t i = 0; i < len; ++i) {
    new_cache.GetCheck(
        i,
        &last_instance_class_id_or_function,
        &last_instance_type_arguments,
        &last_instantiator_type_arguments,
        &last_result);
    if ((last_instance_class_id_or_function.raw() ==
         instance_class_id_or_function.raw()) &&
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
  new_cache.AddCheck(instance_class_id_or_function,
                     instance_type_arguments,
                     instantiator_type_arguments,
                     result);
  if (FLAG_trace_type_checks) {
    AbstractType& test_type = AbstractType::Handle(type.raw());
    if (!test_type.IsInstantiated()) {
      Error& bound_error = Error::Handle();
      test_type = type.InstantiateFrom(instantiator_type_arguments,
                                       &bound_error,
                                       NULL, NULL, Heap::kNew);
      ASSERT(bound_error.IsNull());  // Malbounded types are not optimized.
    }
    OS::PrintErr("  Updated test cache %p ix: %" Pd " with "
        "(cid-or-fun: %p, type-args: %p, instantiator: %p, result: %s)\n"
        "    instance  [class: (%p '%s' cid: %" Pd "),    type-args: %p %s]\n"
        "    test-type [class: (%p '%s' cid: %" Pd "), in-type-args: %p %s]\n",
        new_cache.raw(),
        len,

        instance_class_id_or_function.raw(),
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
// Arg2: type arguments of the instantiator of the type.
// Arg3: SubtypeTestCache.
// Return value: true or false, or may throw a type error in checked mode.
DEFINE_RUNTIME_ENTRY(Instanceof, 4) {
  const Instance& instance = Instance::CheckedHandle(arguments.ArgAt(0));
  const AbstractType& type = AbstractType::CheckedHandle(arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(2));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.ArgAt(3));
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
    const TokenPosition location = GetCallerLocation();
    String& bound_error_message =  String::Handle(
        String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, Symbols::Empty(), Symbols::Empty(),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(
      instance, type, instantiator_type_arguments, result, cache);
  arguments.SetReturn(result);
}


// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Arg0: instance being assigned.
// Arg1: type being assigned to.
// Arg2: type arguments of the instantiator of the type being assigned to.
// Arg3: name of variable being assigned to.
// Arg4: SubtypeTestCache.
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 5) {
  const Instance& src_instance = Instance::CheckedHandle(arguments.ArgAt(0));
  AbstractType& dst_type = AbstractType::CheckedHandle(arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(arguments.ArgAt(2));
  const String& dst_name = String::CheckedHandle(arguments.ArgAt(3));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.ArgAt(4));
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
    const TokenPosition location = GetCallerLocation();
    const AbstractType& src_type = AbstractType::Handle(src_instance.GetType());
    String& src_type_name = String::Handle(src_type.UserVisibleName());
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      dst_type = dst_type.InstantiateFrom(instantiator_type_arguments, NULL,
                                          NULL, NULL, Heap::kNew);
      // Note that instantiated dst_type may be malbounded.
    }
    String& dst_type_name = String::Handle(dst_type.UserVisibleName());
    String& bound_error_message =  String::Handle();
    if (!bound_error.IsNull()) {
      ASSERT(isolate->type_checks());
      bound_error_message = String::New(bound_error.ToErrorCString());
    }
    if (src_type_name.Equals(dst_type_name)) {
      src_type_name = src_type.UserVisibleNameWithURI();
      dst_type_name = dst_type.UserVisibleNameWithURI();
    }
    Exceptions::CreateAndThrowTypeError(location, src_type_name, dst_type_name,
                                        dst_name, bound_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(
      src_instance, dst_type, instantiator_type_arguments, Bool::True(), cache);
  arguments.SetReturn(src_instance);
}


// Report that the type of the given object is not bool in conditional context.
// Throw assertion error if the object is null. (cf. Boolean Conversion
// in language Spec.)
// Arg0: bad object.
// Return value: none, throws TypeError or AssertionError.
DEFINE_RUNTIME_ENTRY(NonBoolTypeError, 1) {
  const TokenPosition location = GetCallerLocation();
  const Instance& src_instance = Instance::CheckedHandle(arguments.ArgAt(0));

  if (src_instance.IsNull()) {
    const Array& args = Array::Handle(Array::New(4));
    args.SetAt(0, String::Handle(
        String::New("Failed assertion: boolean expression must not be null")));

    // No source code for this assertion, set url to null.
    args.SetAt(1, String::Handle(String::null()));
    args.SetAt(2, Smi::Handle(Smi::New(0)));
    args.SetAt(3, Smi::Handle(Smi::New(0)));

    Exceptions::ThrowByType(Exceptions::kAssertion, args);
    UNREACHABLE();
  }

  ASSERT(!src_instance.IsBool());
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
  const TokenPosition location = GetCallerLocation();
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
      Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::Throw(thread, exception);
}


DEFINE_RUNTIME_ENTRY(ReThrow, 2) {
  const Instance& exception =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));
  Exceptions::ReThrow(thread, exception, stacktrace);
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
        Error::Handle(Compiler::CompileFunction(thread, target_function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  const Code& target_code = Code::Handle(target_function.CurrentCode());
  // Before patching verify that we are not repeatedly patching to the same
  // target.
  ASSERT(target_code.raw() !=
         CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code));
  CodePatcher::PatchStaticCallAt(caller_frame->pc(),
                                 caller_code,
                                 target_code);
  caller_code.SetStaticCallTargetCodeAt(caller_frame->pc(), target_code);
  if (FLAG_trace_patching) {
    THR_Print("PatchStaticCall: patching caller pc %#" Px ""
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
  if (!FLAG_support_debugger) {
    UNREACHABLE();
    return;
  }
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& orig_stub = Code::Handle(
      isolate->debugger()->GetPatchedStubAddress(caller_frame->pc()));
  const Error& error = Error::Handle(isolate->debugger()->SignalBpReached());
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
  arguments.SetReturn(orig_stub);
}


DEFINE_RUNTIME_ENTRY(SingleStepHandler, 0) {
  if (!FLAG_support_debugger) {
    UNREACHABLE();
    return;
  }
  const Error& error =
      Error::Handle(isolate->debugger()->DebuggerStepCallback());
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
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
          RawFunction::kInvokeFieldDispatcher,
          FLAG_lazy_dispatchers));
  ASSERT(!target_function.IsNull() || !FLAG_lazy_dispatchers);
  if (FLAG_trace_ic) {
    OS::PrintErr("InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        Class::Handle(receiver.clazz()).ToCString(),
        receiver.GetClassId(),
        target_function.IsNull() ? "null" : target_function.ToCString());
  }
  *result = target_function.raw();
  return true;
}


// Handle other invocations (implicit closures, noSuchMethod).
RawFunction* InlineCacheMissHelper(
    const Instance& receiver,
    const Array& args_descriptor,
    const String& target_name) {
  const Class& receiver_class = Class::Handle(receiver.clazz());

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
            RawFunction::kNoSuchMethodDispatcher,
            FLAG_lazy_dispatchers));
    if (FLAG_trace_ic) {
      OS::PrintErr("NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          Class::Handle(receiver.clazz()).ToCString(),
          receiver.GetClassId(),
          target_function.IsNull() ? "null" : target_function.ToCString());
    }
    result = target_function.raw();
  }
  // May be null if --no-lazy-dispatchers, in which case dispatch will be
  // handled by InvokeNoSuchMethodDispatcher.
  ASSERT(!result.IsNull() || !FLAG_lazy_dispatchers);
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
    const Array& args_descriptor =
        Array::Handle(ic_data.arguments_descriptor());
    const String& target_name = String::Handle(ic_data.target_name());
    target_function = InlineCacheMissHelper(receiver,
                                            args_descriptor,
                                            target_name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
    return target_function.raw();
  }
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
    const Error& error = Error::Handle(Compiler::CompileFunction(thread,
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
    const Error& error = Error::Handle(Compiler::CompileFunction(thread,
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
//   Arg1: ICData or MegamorphicCache.
//   Arg2: Arguments descriptor array.
//   Returns: target function to call.
DEFINE_RUNTIME_ENTRY(MegamorphicCacheMissHandler, 3) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& ic_data_or_cache = Object::Handle(zone, arguments.ArgAt(1));
  const Array& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(2));
  String& name = String::Handle(zone);
  if (ic_data_or_cache.IsICData()) {
    name = ICData::Cast(ic_data_or_cache).target_name();
  } else {
    ASSERT(ic_data_or_cache.IsMegamorphicCache());
    name = MegamorphicCache::Cast(ic_data_or_cache).target_name();
  }
  Class& cls = Class::Handle(zone, receiver.clazz());
  ASSERT(!cls.IsNull());
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic IC miss, class=%s, function=%s\n",
                 cls.ToCString(), name.ToCString());
  }

  ArgumentsDescriptor args_desc(descriptor);
  Function& target_function = Function::Handle(zone,
      Resolver::ResolveDynamicForReceiverClass(cls,
                                               name,
                                               args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
    arguments.SetReturn(target_function);
    return;
  }

  if (ic_data_or_cache.IsICData()) {
    const ICData& ic_data = ICData::Cast(ic_data_or_cache);
    ic_data.AddReceiverCheck(receiver.GetClassId(), target_function);
    if (ic_data.NumberOfChecks() > FLAG_max_polymorphic_checks) {
      // Switch to megamorphic call.
      const MegamorphicCache& cache = MegamorphicCache::Handle(zone,
          MegamorphicCacheTable::Lookup(isolate, name, descriptor));
      DartFrameIterator iterator;
      StackFrame* miss_function_frame = iterator.NextFrame();
      ASSERT(miss_function_frame->IsDartFrame());
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(caller_frame->IsDartFrame());
      const Code& code = Code::Handle(zone, caller_frame->LookupDartCode());
      const Code& stub =
          Code::Handle(zone, StubCode::MegamorphicLookup_entry()->code());
      CodePatcher::PatchSwitchableCallAt(caller_frame->pc(),
                                         code, ic_data, cache, stub);
    }
  } else {
    const MegamorphicCache& cache = MegamorphicCache::Cast(ic_data_or_cache);
    // Insert function found into cache and return it.
    cache.EnsureCapacity();
    const Smi& class_id = Smi::Handle(zone, Smi::New(cls.id()));
    cache.Insert(class_id, target_function);
  }
  arguments.SetReturn(target_function);
}


// Invoke appropriate noSuchMethod or closure from getter.
// Arg0: receiver
// Arg1: ICData or MegamorphicCache
// Arg2: arguments descriptor array
// Arg3: arguments array
DEFINE_RUNTIME_ENTRY(InvokeNoSuchMethodDispatcher, 4) {
  ASSERT(!FLAG_lazy_dispatchers);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& ic_data_or_cache = Object::Handle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));
  String& target_name = String::Handle(zone);
  if (ic_data_or_cache.IsICData()) {
    target_name = ICData::Cast(ic_data_or_cache).target_name();
  } else {
    ASSERT(ic_data_or_cache.IsMegamorphicCache());
    target_name = MegamorphicCache::Cast(ic_data_or_cache).target_name();
  }

  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& function = Function::Handle(zone);

  // Dart distinguishes getters and regular methods and allows their calls
  // to mix with conversions, and its selectors are independent of arity. So do
  // a zigzagged lookup to see if this call failed because of an arity mismatch,
  // need for conversion, or there really is no such method.

#define NO_SUCH_METHOD()                                                       \
  const Object& result = Object::Handle(zone,                                  \
      DartEntry::InvokeNoSuchMethod(receiver,                                  \
                                    target_name,                               \
                                    orig_arguments,                            \
                                    orig_arguments_desc));                     \
  CheckResultError(result);                                                    \
  arguments.SetReturn(result);                                                 \

#define CLOSURIZE(some_function)                                               \
  const Function& closure_function =                                           \
      Function::Handle(zone, some_function.ImplicitClosureFunction());         \
  const Object& result =                                                       \
      Object::Handle(zone, closure_function.ImplicitInstanceClosure(receiver));\
  arguments.SetReturn(result);                                                 \

  const bool is_getter = Field::IsGetterName(target_name);
  if (is_getter) {
    // o.foo (o.get:foo) failed, closurize o.foo() if it exists. Or,
    // o#foo (o.get:#foo) failed, closurizee o.foo or o.foo(), whichever is
    // encountered first on the inheritance chain. Or,
    // o#foo= (o.get:#set:foo) failed, closurize o.foo= if it exists.
    String& field_name =
        String::Handle(zone, Field::NameFromGetter(target_name));

    const bool is_extractor = field_name.CharAt(0) == '#';
    if (is_extractor) {
      field_name = String::SubString(field_name, 1);
      ASSERT(!Field::IsGetterName(field_name));
      field_name = Symbols::New(field_name);

      if (!Field::IsSetterName(field_name)) {
        const String& getter_name =
            String::Handle(Field::GetterName(field_name));

        // Zigzagged lookup: closure either a regular method or a getter.
        while (!cls.IsNull()) {
          function ^= cls.LookupDynamicFunction(field_name);
          if (!function.IsNull()) {
            CLOSURIZE(function);
            return;
          }
          function ^= cls.LookupDynamicFunction(getter_name);
          if (!function.IsNull()) {
            CLOSURIZE(function);
            return;
          }
          cls = cls.SuperClass();
        }
        NO_SUCH_METHOD();
        return;
      } else {
        // Fall through for non-ziggaged lookup for o#foo=.
      }
    }

    while (!cls.IsNull()) {
      function ^= cls.LookupDynamicFunction(field_name);
      if (!function.IsNull()) {
        CLOSURIZE(function);
        return;
      }
      cls = cls.SuperClass();
    }

    // Fall through for noSuchMethod
  } else {
    // o.foo(...) failed, invoke noSuchMethod is foo exists but has the wrong
    // number of arguments, or try (o.foo).call(...)

    if ((target_name.raw() == Symbols::Call().raw()) && receiver.IsClosure()) {
      // Special case: closures are implemented with a call getter instead of a
      // call method and with lazy dispatchers the field-invocation-dispatcher
      // would perform the closure call.
      const Object& result =
        Object::Handle(zone, DartEntry::InvokeClosure(orig_arguments,
                                                      orig_arguments_desc));
      CheckResultError(result);
      arguments.SetReturn(result);
      return;
    }

    const String& getter_name =
        String::Handle(zone, Field::GetterName(target_name));
    while (!cls.IsNull()) {
      function ^= cls.LookupDynamicFunction(target_name);
      if (!function.IsNull()) {
        ArgumentsDescriptor args_desc(orig_arguments_desc);
        ASSERT(!function.AreValidArguments(args_desc, NULL));
        break;  // mismatch, invoke noSuchMethod
      }
      function ^= cls.LookupDynamicFunction(getter_name);
      if (!function.IsNull()) {
        const Array& getter_arguments = Array::Handle(Array::New(1));
        getter_arguments.SetAt(0, receiver);
        const Object& getter_result =
          Object::Handle(zone, DartEntry::InvokeFunction(function,
                                                         getter_arguments));
        CheckResultError(getter_result);
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());

        orig_arguments.SetAt(0, getter_result);
        const Object& call_result =
          Object::Handle(zone, DartEntry::InvokeClosure(orig_arguments,
                                                        orig_arguments_desc));
        CheckResultError(call_result);
        arguments.SetReturn(call_result);
        return;
      }
      cls = cls.SuperClass();
    }
  }

  NO_SUCH_METHOD();

#undef NO_SUCH_METHOD
#undef CLOSURIZE
}



// Invoke appropriate noSuchMethod function.
// Arg0: receiver (closure object)
// Arg1: arguments descriptor array.
// Arg2: arguments array.
DEFINE_RUNTIME_ENTRY(InvokeClosureNoSuchMethod, 3) {
  const Closure& receiver = Closure::CheckedHandle(arguments.ArgAt(0));
  const Array& orig_arguments_desc = Array::CheckedHandle(arguments.ArgAt(1));
  const Array& orig_arguments = Array::CheckedHandle(arguments.ArgAt(2));

  // For closure the function name is always 'call'. Replace it with the
  // name of the closurized function so that exception contains more
  // relevant information.
  const Function& function = Function::Handle(receiver.function());
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


static bool CanOptimizeFunction(const Function& function, Thread* thread) {
  if (FLAG_support_debugger) {
    Isolate* isolate = thread->isolate();
    if (isolate->debugger()->IsStepping() ||
        isolate->debugger()->HasBreakpoint(function, thread->zone())) {
      // We cannot set breakpoints and single step in optimized code,
      // so do not optimize the function.
      function.set_usage_counter(0);
      return false;
    }
  }
  if (function.deoptimization_counter() >=
      FLAG_max_deoptimization_counter_threshold) {
    if (FLAG_trace_failed_optimization_attempts ||
        FLAG_stop_on_excessive_deoptimization) {
      THR_Print("Too many deoptimizations: %s\n",
          function.ToFullyQualifiedCString());
      if (FLAG_stop_on_excessive_deoptimization) {
        FATAL("Stop on excessive deoptimization");
      }
    }
    // The function will not be optimized any longer. This situation can occur
    // mostly with small optimization counter thresholds.
    function.SetIsOptimizable(false);
    function.set_usage_counter(INT_MIN);
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
      function.set_usage_counter(INT_MIN);
      return false;
    }
  }
  if (!function.IsOptimizable()) {
    // Huge methods (code size above --huge_method_cutoff_in_code_size) become
    // non-optimizable only after the code has been generated.
    if (FLAG_trace_failed_optimization_attempts) {
      THR_Print("Not optimizable: %s\n", function.ToFullyQualifiedCString());
    }
    function.set_usage_counter(INT_MIN);
    return false;
  }
  return true;
}


DEFINE_RUNTIME_ENTRY(StackOverflow, 0) {
#if defined(USING_SIMULATOR)
  uword stack_pos = Simulator::Current()->get_register(SPREG);
#else
  uword stack_pos = Isolate::GetCurrentStackPointer();
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
    Exceptions::Throw(thread, exception);
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
    DeoptimizeFunctionsOnStack();
  }
  if (FLAG_support_debugger && do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      // Variable locations and number are unknown when precompiling.
      const int num_vars =
         FLAG_precompiled_runtime ? 0 : frame->NumLocalVariables();
      TokenPosition unused = TokenPosition::kNoSource;
      for (intptr_t v = 0; v < num_vars; v++) {
        frame->VariableAt(v, &var_name, &unused, &unused, &var_value);
      }
    }
  }

  const Error& error = Error::Handle(isolate->HandleInterrupts());
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
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
    // Don't do OSR on intrinsified functions: The intrinsic code expects to be
    // called like a regular function and can't be entered via OSR.
    if (!CanOptimizeFunction(function, thread) || function.is_intrinsic()) {
      return;
    }

    // The unoptimized code is on the stack and should never be detached from
    // the function at this point.
    ASSERT(function.unoptimized_code() != Object::null());
    intptr_t osr_id =
        Code::Handle(function.unoptimized_code()).GetDeoptIdForOsr(frame->pc());
    ASSERT(osr_id != Compiler::kNoOSRDeoptId);
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
        thread, function, osr_id));
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
      frame->set_pc_marker(optimized_code.raw());
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
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Function& function = Function::CheckedHandle(zone,
                                                     arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  if (CanOptimizeFunction(function, thread)) {
    if (FLAG_background_compilation) {
      Field& field = Field::Handle(zone, isolate->GetDeoptimizingBoxedField());
      while (!field.IsNull()) {
        if (FLAG_trace_optimization || FLAG_trace_field_guards) {
          THR_Print("Lazy disabling unboxing of %s\n", field.ToCString());
        }
        field.set_is_unboxing_candidate(false);
        field.DeoptimizeDependentCode();
        // Get next field.
        field = isolate->GetDeoptimizingBoxedField();
      }
    }
    // TODO(srdjan): Fix background compilation of regular expressions.
    if (FLAG_background_compilation &&
        (!function.IsIrregexpFunction() || FLAG_regexp_opt_in_background)) {
      if (FLAG_enable_inlining_annotations) {
        FATAL("Cannot enable inlining annotations and background compilation");
      }
      // Reduce the chance of triggering optimization while the function is
      // being optimized in the background. INT_MIN should ensure that it takes
      // long time to trigger optimization.
      // Note that the background compilation queue rejects duplicate entries.
      function.set_usage_counter(INT_MIN);
      BackgroundCompiler::EnsureInit(thread);
      ASSERT(isolate->background_compiler() != NULL);
      isolate->background_compiler()->CompileOptimized(function);
      // Continue in the same code.
      arguments.SetReturn(Code::Handle(zone, function.CurrentCode()));
      return;
    }

    // Reset usage counter for reoptimization before calling optimizer to
    // prevent recursive triggering of function optimization.
    function.set_usage_counter(0);
    if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
      if (function.HasOptimizedCode()) {
        THR_Print("ReCompiling function: '%s' \n",
                  function.ToFullyQualifiedCString());
      }
    }
    const Error& error = Error::Handle(
        zone, Compiler::CompileOptimizedFunction(thread, function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
    const Code& optimized_code = Code::Handle(zone, function.CurrentCode());
    ASSERT(!optimized_code.IsNull());
  }
  arguments.SetReturn(Code::Handle(zone, function.CurrentCode()));
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
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
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(frame->pc()));
  if (!target_function.HasCode()) {
    const Error& error = Error::Handle(
        zone, Compiler::CompileFunction(thread, target_function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  ASSERT(target_function.HasCode());

  const Code& current_target_code = Code::Handle(
      zone, target_function.CurrentCode());
  CodePatcher::PatchStaticCallAt(frame->pc(),
                                 caller_code,
                                 current_target_code);
  caller_code.SetStaticCallTargetCodeAt(frame->pc(), current_target_code);
  if (FLAG_trace_patching) {
    OS::PrintErr("FixCallersTarget: caller %#" Px " "
                 "target '%s' -> %#" Px "\n",
                 frame->pc(),
                 target_function.ToFullyQualifiedCString(),
                 current_target_code.EntryPoint());
  }
  arguments.SetReturn(current_target_code);
}


// The caller tried to allocate an instance via an invalidated allocation
// stub.
DEFINE_RUNTIME_ENTRY(FixAllocationStubTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
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
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const Code& stub = Code::Handle(
      CodePatcher::GetStaticCallTargetAt(frame->pc(), caller_code));
  Class& alloc_class = Class::ZoneHandle(zone);
  alloc_class ^= stub.owner();
  Code& alloc_stub = Code::Handle(zone, alloc_class.allocation_stub());
  if (alloc_stub.IsNull()) {
    alloc_stub = StubCode::GetAllocationStubForClass(alloc_class);
    ASSERT(!alloc_stub.IsDisabled());
  }
  CodePatcher::PatchStaticCallAt(frame->pc(),
                                 caller_code,
                                 alloc_stub);
  caller_code.SetStubCallTargetCodeAt(frame->pc(), alloc_stub);
  if (FLAG_trace_patching) {
    OS::PrintErr("FixAllocationStubTarget: caller %#" Px " alloc-class %s "
        " -> %#" Px "\n",
        frame->pc(),
        alloc_class.ToCString(),
        alloc_stub.EntryPoint());
  }
  arguments.SetReturn(alloc_stub);
#else
  UNREACHABLE();
#endif
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
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ICData::DeoptReasonId deopt_reason = ICData::kDeoptUnknown;
  uint32_t deopt_flags = 0;
  const TypedData& deopt_info = TypedData::Handle(zone,
      optimized_code.GetDeoptInfoAtPc(pc, &deopt_reason, &deopt_flags));
  ASSERT(!deopt_info.IsNull());
  const Function& function = Function::Handle(zone, optimized_code.function());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unoptimized_code =
      Code::Handle(zone, function.unoptimized_code());
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
      Instructions::Handle(zone, optimized_code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    CodePatcher::InsertDeoptimizationCallAt(pc, lazy_deopt_jump);
  }
  if (FLAG_trace_patching) {
    const String& name = String::Handle(function.name());
    OS::PrintErr("InsertDeoptimizationCallAt: %" Px " to %" Px " for %s\n", pc,
                 lazy_deopt_jump, name.ToCString());
  }
  // Mark code as dead (do not GC its embedded objects).
  optimized_code.set_is_alive(false);
}


// Currently checks only that all optimized frames have kDeoptIndex
// and unoptimized code has the kDeoptAfter.
void DeoptimizeFunctionsOnStack() {
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

#if !defined(DART_PRECOMPILED_RUNTIME)
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
#endif


// Copies saved registers and caller's frame into temporary buffers.
// Returns the stack size of unoptimized frame.
// The calling code must be optimized, but its function may not have
// have optimized code if the code is OSR code, or if the code was invalidated
// through class loading/finalization or field guard.
DEFINE_LEAF_RUNTIME_ENTRY(intptr_t, DeoptimizeCopyFrame,
                          2,
                          uword saved_registers_address,
                          uword is_lazy_deopt) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  StackZone zone(thread);
  HANDLESCOPE(thread);

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
  const Function& top_function =
      Function::Handle(thread->zone(), optimized_code.function());
  const bool deoptimizing_code = top_function.HasOptimizedCode();
  if (FLAG_trace_deoptimization) {
    const Function& function = Function::Handle(optimized_code.function());
    THR_Print("== Deoptimizing code for '%s', %s, %s\n",
       function.ToFullyQualifiedCString(),
       deoptimizing_code ? "code & frame" : "frame",
       is_lazy_deopt ? "lazy-deopt" : "");
  }

  // Copy the saved registers from the stack.
  fpu_register_t* fpu_registers;
  intptr_t* cpu_registers;
  CopySavedRegisters(saved_registers_address, &fpu_registers, &cpu_registers);

  // Create the DeoptContext.
  DeoptContext* deopt_context =
      new DeoptContext(caller_frame,
                       optimized_code,
                       DeoptContext::kDestIsOriginalFrame,
                       fpu_registers,
                       cpu_registers,
                       is_lazy_deopt != 0,
                       deoptimizing_code);
  isolate->set_deopt_context(deopt_context);

  // Stack size (FP - SP) in bytes.
  return deopt_context->DestStackAdjustment() * kWordSize;
#else
  UNREACHABLE();
  return 0;
#endif  // !DART_PRECOMPILED_RUNTIME
}
END_LEAF_RUNTIME_ENTRY


// The stack has been adjusted to fit all values for unoptimized frame.
// Fill the unoptimized frame.
DEFINE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, 1, uword last_fp) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  StackZone zone(thread);
  HANDLESCOPE(thread);

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

    // Some sanity checking of the optimized code.
    ASSERT(!optimized_code.IsNull() && optimized_code.is_optimized());
  }
#endif

  // TODO(turnidge): Compute the start of the dest frame in the
  // DeoptContext instead of passing it in here.
  intptr_t* start = reinterpret_cast<intptr_t*>(
      caller_frame->sp() - (kDartFrameFixedSize * kWordSize));
  deopt_context->set_dest_frame(start);
  deopt_context->FillDestFrame();
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}
END_LEAF_RUNTIME_ENTRY


// This is the last step in the deoptimization, GC can occur.
// Returns number of bytes to remove from the expression stack of the
// bottom-most deoptimized frame. Those arguments were artificially injected
// under return address to keep them discoverable by GC that can occur during
// materialization phase.
DEFINE_RUNTIME_ENTRY(DeoptimizeMaterialize, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DeoptContext* deopt_context = isolate->deopt_context();
  intptr_t deopt_arg_count = deopt_context->MaterializeDeferredObjects();
  isolate->set_deopt_context(NULL);
  delete deopt_context;

  // Return value tells deoptimization stub to remove the given number of bytes
  // from the stack.
  arguments.SetReturn(Smi::Handle(Smi::New(deopt_arg_count * kWordSize)));
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}


DEFINE_LEAF_RUNTIME_ENTRY(intptr_t,
                          BigintCompare,
                          2,
                          RawBigint* left,
                          RawBigint* right) {
  Thread* thread = Thread::Current();
  StackZone zone(thread);
  HANDLESCOPE(thread);
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


DEFINE_RUNTIME_ENTRY(GrowRegExpStack, 1) {
  const Array& typed_data_cell = Array::CheckedHandle(arguments.ArgAt(0));
  ASSERT(!typed_data_cell.IsNull() && typed_data_cell.Length() == 1);
  const TypedData& old_data = TypedData::CheckedHandle(typed_data_cell.At(0));
  ASSERT(!old_data.IsNull());
  const intptr_t cid = old_data.GetClassId();
  const intptr_t old_size = old_data.Length();
  const intptr_t new_size = 2 * old_size;
  const intptr_t elm_size = old_data.ElementSizeInBytes();
  const TypedData& new_data =
      TypedData::Handle(TypedData::New(cid, new_size, Heap::kOld));
  TypedData::Copy(new_data, 0, old_data, 0, old_size * elm_size);
  typed_data_cell.SetAt(0, new_data);
  arguments.SetReturn(new_data);
}


}  // namespace dart
