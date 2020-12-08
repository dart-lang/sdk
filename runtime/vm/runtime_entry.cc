// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "vm/code_descriptors.h"
#include "vm/code_patcher.h"
#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/heap/verifier.h"
#include "vm/instructions.h"
#include "vm/kernel_isolate.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/thread_registry.h"
#include "vm/type_testing_stubs.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/deopt_instructions.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_FLAG(
    int,
    max_subtype_cache_entries,
    100,
    "Maximum number of subtype cache entries (number of checks cached).");
DEFINE_FLAG(
    int,
    regexp_optimization_counter_threshold,
    1000,
    "RegExp's usage-counter value before it is optimized, -1 means never");
DEFINE_FLAG(int,
            reoptimization_counter_threshold,
            4000,
            "Counter threshold before a function gets reoptimized.");
DEFINE_FLAG(bool,
            stress_write_barrier_elimination,
            false,
            "Stress test write barrier elimination.");
DEFINE_FLAG(bool, trace_deoptimization, false, "Trace deoptimization");
DEFINE_FLAG(bool,
            trace_deoptimization_verbose,
            false,
            "Trace deoptimization verbose");

DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(int, max_polymorphic_checks);

DEFINE_FLAG(bool, trace_osr, false, "Trace attempts at on-stack replacement.");

DEFINE_FLAG(int, gc_every, 0, "Run major GC on every N stack overflow checks");
DEFINE_FLAG(int,
            stacktrace_every,
            0,
            "Compute debugger stacktrace on every N stack overflow checks");
DEFINE_FLAG(charp,
            stacktrace_filter,
            NULL,
            "Compute stacktrace in named function on stack overflow checks");
DEFINE_FLAG(charp,
            deoptimize_filter,
            NULL,
            "Deoptimize in named function on stack overflow checks");

DEFINE_FLAG(bool,
            unopt_monomorphic_calls,
            true,
            "Enable specializing monomorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            unopt_megamorphic_calls,
            true,
            "Enable specializing megamorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            verbose_stack_overflow,
            false,
            "Print additional details about stack overflow.");

DECLARE_FLAG(int, reload_every);
DECLARE_FLAG(bool, reload_every_optimized);
DECLARE_FLAG(bool, reload_every_back_off);

#if defined(TESTING) || defined(DEBUG)
void VerifyOnTransition() {
  Thread* thread = Thread::Current();
  TransitionGeneratedToVM transition(thread);
  VerifyPointersVisitor::VerifyPointers();
  thread->isolate()->heap()->Verify();
}
#endif

DEFINE_RUNTIME_ENTRY(RangeError, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& index = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  if (!index.IsInteger()) {
    // Throw: new ArgumentError.value(index, "index", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, index);
    args.SetAt(1, Symbols::Index());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  // Throw: new RangeError.range(index, 0, length - 1, "length");
  const Array& args = Array::Handle(zone, Array::New(4));
  args.SetAt(0, index);
  args.SetAt(1, Integer::Handle(zone, Integer::New(0)));
  args.SetAt(
      2, Integer::Handle(
             zone, Integer::Cast(length).ArithmeticOp(
                       Token::kSUB, Integer::Handle(zone, Integer::New(1)))));
  args.SetAt(3, Symbols::Length());
  Exceptions::ThrowByType(Exceptions::kRange, args);
}

static void NullErrorHelper(Zone* zone, const String& selector) {
  // If the selector is null, this must be a null check that wasn't due to a
  // method invocation, so was due to the null check operator.
  if (selector.IsNull()) {
    const Array& args = Array::Handle(zone, Array::New(4));
    args.SetAt(
        3, String::Handle(
               zone, String::New("Null check operator used on a null value")));
    Exceptions::ThrowByType(Exceptions::kCast, args);
    return;
  }

  InvocationMirror::Kind kind = InvocationMirror::kMethod;
  if (Field::IsGetterName(selector)) {
    kind = InvocationMirror::kGetter;
  } else if (Field::IsSetterName(selector)) {
    kind = InvocationMirror::kSetter;
  }

  const Smi& invocation_type = Smi::Handle(
      zone,
      Smi::New(InvocationMirror::EncodeType(InvocationMirror::kDynamic, kind)));

  const Array& args = Array::Handle(zone, Array::New(7));
  args.SetAt(0, /* instance */ Object::null_object());
  args.SetAt(1, selector);
  args.SetAt(2, invocation_type);
  args.SetAt(3, /* func_type_args_length */ Object::smi_zero());
  args.SetAt(4, /* func_type_args */ Object::null_object());
  args.SetAt(5, /* func_args */ Object::null_object());
  args.SetAt(6, /* func_arg_names */ Object::null_object());
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
}

DEFINE_RUNTIME_ENTRY(NullError, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& code = Code::Handle(zone, caller_frame->LookupDartCode());
  const uword pc_offset = caller_frame->pc() - code.PayloadStart();

  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->heap()->CollectAllGarbage();
  }

  const CodeSourceMap& map =
      CodeSourceMap::Handle(zone, code.code_source_map());
  String& member_name = String::Handle(zone);
  if (!map.IsNull()) {
    CodeSourceMapReader reader(map, Array::null_array(),
                               Function::null_function());
    const intptr_t name_index = reader.GetNullCheckNameIndexAt(pc_offset);
    RELEASE_ASSERT(name_index >= 0);

    const ObjectPool& pool = ObjectPool::Handle(zone, code.GetObjectPool());
    member_name ^= pool.ObjectAt(name_index);
  } else {
    member_name = Symbols::OptimizedOut().raw();
  }

  NullErrorHelper(zone, member_name);
}

DEFINE_RUNTIME_ENTRY(NullErrorWithSelector, 1) {
  const String& selector = String::CheckedHandle(zone, arguments.ArgAt(0));
  NullErrorHelper(zone, selector);
}

DEFINE_RUNTIME_ENTRY(NullCastError, 0) {
  NullErrorHelper(zone, String::null_string());
}

DEFINE_RUNTIME_ENTRY(ArgumentNullError, 0) {
  const String& error = String::Handle(String::New("argument value is null"));
  Exceptions::ThrowArgumentError(error);
}

DEFINE_RUNTIME_ENTRY(ArgumentError, 1) {
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(ArgumentErrorUnboxedInt64, 0) {
  // Unboxed value is passed through a dedicated slot in Thread.
  int64_t unboxed_value = arguments.thread()->unboxed_int64_runtime_arg();
  const Integer& value = Integer::Handle(zone, Integer::New(unboxed_value));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(IntegerDivisionByZeroException, 0) {
  const Array& args = Array::Handle(zone, Array::New(0));
  Exceptions::ThrowByType(Exceptions::kIntegerDivisionByZeroException, args);
}

static Heap::Space SpaceForRuntimeAllocation() {
  return FLAG_stress_write_barrier_elimination ? Heap::kOld : Heap::kNew;
}

// Allocation of a fixed length array of given element type.
// This runtime entry is never called for allocating a List of a generic type,
// because a prior run time call instantiates the element type if necessary.
// Arg0: array length.
// Arg1: array type arguments, i.e. vector of 1 type, the element type.
// Return value: newly allocated array of length arg0.
DEFINE_RUNTIME_ENTRY(AllocateArray, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  const int64_t len = Integer::Cast(length).AsInt64Value();
  if (len < 0) {
    // Throw: new RangeError.range(length, 0, Array::kMaxElements, "length");
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0,
                                Array::kMaxElements);
  }
  if (len > Array::kMaxElements) {
    const Instance& exception = Instance::Handle(
        zone, thread->isolate()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
  }

  const Array& array = Array::Handle(
      zone,
      Array::New(static_cast<intptr_t>(len), SpaceForRuntimeAllocation()));
  arguments.SetReturn(array);
  TypeArguments& element_type =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  // An Array is raw or takes one type argument. However, its type argument
  // vector may be longer than 1 due to a type optimization reusing the type
  // argument vector of the instantiator.
  ASSERT(element_type.IsNull() ||
         (element_type.Length() >= 1 && element_type.IsInstantiated()));
  array.SetTypeArguments(element_type);  // May be null.
}

// Allocate typed data array of given class id and length.
// Arg0: class id.
// Arg1: number of elements.
// Return value: newly allocated typed data array.
DEFINE_RUNTIME_ENTRY(AllocateTypedData, 2) {
  const intptr_t cid = Smi::CheckedHandle(zone, arguments.ArgAt(0)).Value();
  const auto& length = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    const Array& args = Array::Handle(zone, Array::New(1));
    args.SetAt(0, length);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  const int64_t len = Integer::Cast(length).AsInt64Value();
  const intptr_t max = TypedData::MaxElements(cid);
  if (len < 0) {
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0, max);
  } else if (len > max) {
    const Instance& exception = Instance::Handle(
        zone, thread->isolate()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
  }
  const auto& typed_data =
      TypedData::Handle(zone, TypedData::New(cid, static_cast<intptr_t>(len)));
  arguments.SetReturn(typed_data);
}

// Helper returning the token position of the Dart caller.
static TokenPosition GetCallerLocation() {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  return caller_frame->GetTokenPos();
}

// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void ThrowIfError(const Object& result) {
  if (!result.IsNull() && result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
}

// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 2) {
  const Class& cls = Class::CheckedHandle(zone, arguments.ArgAt(0));
  const Error& error =
      Error::Handle(zone, cls.EnsureIsAllocateFinalized(thread));
  ThrowIfError(error);
  const Instance& instance =
      Instance::Handle(zone, Instance::New(cls, SpaceForRuntimeAllocation()));

  arguments.SetReturn(instance);
  if (cls.NumTypeArguments() == 0) {
    // No type arguments required for a non-parameterized type.
    ASSERT(Instance::CheckedHandle(zone, arguments.ArgAt(1)).IsNull());
  } else {
    const auto& type_arguments =
        TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
    // Unless null (for a raw type), the type argument vector may be longer than
    // necessary due to a type optimization reusing the type argument vector of
    // the instantiator.
    ASSERT(type_arguments.IsNull() ||
           (type_arguments.IsInstantiated() &&
            (type_arguments.Length() >= cls.NumTypeArguments())));
    instance.SetTypeArguments(type_arguments);
  }
}

DEFINE_LEAF_RUNTIME_ENTRY(uword /*ObjectPtr*/,
                          EnsureRememberedAndMarkingDeferred,
                          2,
                          uword /*ObjectPtr*/ object_in,
                          Thread* thread) {
  ObjectPtr object = static_cast<ObjectPtr>(object_in);
  // The allocation stubs will call this leaf method for newly allocated
  // old space objects.
  RELEASE_ASSERT(object->IsOldObject());

  // If we eliminate a generational write barriers on allocations of an object
  // we need to ensure it's either a new-space object or it has been added to
  // the remebered set.
  //
  // NOTE: We use reinterpret_cast<>() instead of ::RawCast() to avoid handle
  // allocations in debug mode. Handle allocations in leaf runtimes can cause
  // memory leaks because they will allocate into a handle scope from the next
  // outermost runtime code (to which the genenerated Dart code might not return
  // in a long time).
  bool add_to_remembered_set = true;
  if (object->ptr()->IsRemembered()) {
    // Objects must not be added to the remembered set twice because the
    // scavenger's visitor is not idempotent.
    // Might already be remembered because of type argument store in
    // AllocateArray or any field in CloneContext.
    add_to_remembered_set = false;
  } else if (object->IsArray()) {
    const intptr_t length = Array::LengthOf(static_cast<ArrayPtr>(object));
    add_to_remembered_set =
        compiler::target::WillAllocateNewOrRememberedArray(length);
  } else if (object->IsContext()) {
    const intptr_t num_context_variables =
        Context::NumVariables(static_cast<ContextPtr>(object));
    add_to_remembered_set =
        compiler::target::WillAllocateNewOrRememberedContext(
            num_context_variables);
  }

  if (add_to_remembered_set) {
    object->ptr()->AddToRememberedSet(thread);
  }

  // For incremental write barrier elimination, we need to ensure that the
  // allocation ends up in the new space or else the object needs to added
  // to deferred marking stack so it will be [re]scanned.
  if (thread->is_marking()) {
    thread->DeferredMarkingStackAddObject(object);
  }

  return static_cast<uword>(object);
}
END_LEAF_RUNTIME_ENTRY

// Instantiate type.
// Arg0: uninstantiated type.
// Arg1: instantiator type arguments.
// Arg2: function type arguments.
// Return value: instantiated type.
DEFINE_RUNTIME_ENTRY(InstantiateType, 3) {
  AbstractType& type = AbstractType::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type.IsNull());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  type = type.InstantiateFrom(instantiator_type_arguments,
                              function_type_arguments, kAllFree, Heap::kOld);
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
// Arg2: function type arguments.
// Return value: instantiated type arguments.
DEFINE_RUNTIME_ENTRY(InstantiateTypeArguments, 3) {
  TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type_arguments.IsNull() && !type_arguments.IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  // Code inlined in the caller should have optimized the case where the
  // instantiator can be reused as type argument vector.
  ASSERT(!type_arguments.IsUninstantiatedIdentity());
  type_arguments = type_arguments.InstantiateAndCanonicalizeFrom(
      instantiator_type_arguments, function_type_arguments);
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  arguments.SetReturn(type_arguments);
}

// Instantiate type.
// Arg0: instantiator type arguments
// Arg1: function type arguments
// Arg2: type to be a subtype of the other
// Arg3: type to be a supertype of the other
// Arg4: variable name of the subtype parameter
// No return value.
DEFINE_RUNTIME_ENTRY(SubtypeCheck, 5) {
  const TypeArguments& instantiator_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& function_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  AbstractType& subtype = AbstractType::CheckedHandle(zone, arguments.ArgAt(2));
  AbstractType& supertype =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(3));
  const String& dst_name = String::CheckedHandle(zone, arguments.ArgAt(4));

  ASSERT(!subtype.IsNull() && !subtype.IsTypeRef());
  ASSERT(!supertype.IsNull() && !supertype.IsTypeRef());

  // Now that AssertSubtype may be checking types only available at runtime,
  // we can't guarantee the supertype isn't the top type.
  if (supertype.IsTopTypeForSubtyping()) return;

  // The supertype or subtype may not be instantiated.
  if (AbstractType::InstantiateAndTestSubtype(
          &subtype, &supertype, instantiator_type_args, function_type_args)) {
    return;
  }

  // Throw a dynamic type error.
  const TokenPosition location = GetCallerLocation();
  Exceptions::CreateAndThrowTypeError(location, subtype, supertype, dst_name);
  UNREACHABLE();
}

// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  const Smi& num_variables = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  const Context& context = Context::Handle(
      zone, Context::New(num_variables.Value(), SpaceForRuntimeAllocation()));
  arguments.SetReturn(context);
}

// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  const Context& ctx = Context::CheckedHandle(zone, arguments.ArgAt(0));
  Context& cloned_ctx = Context::Handle(
      zone, Context::New(ctx.num_variables(), SpaceForRuntimeAllocation()));
  cloned_ctx.set_parent(Context::Handle(zone, ctx.parent()));
  Object& inst = Object::Handle(zone);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  arguments.SetReturn(cloned_ctx);
}

// Helper routine for tracing a type check.
static void PrintTypeCheck(const char* message,
                           const Instance& instance,
                           const AbstractType& type,
                           const TypeArguments& instantiator_type_arguments,
                           const TypeArguments& function_type_arguments,
                           const Bool& result) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);

  const AbstractType& instance_type =
      AbstractType::Handle(instance.GetType(Heap::kNew));
  ASSERT(instance_type.IsInstantiated() ||
         (instance.IsClosure() && instance_type.IsInstantiated(kCurrentClass)));
  if (type.IsInstantiated()) {
    OS::PrintErr("%s: '%s' %" Pd " %s '%s' %" Pd " (pc: %#" Px ").\n", message,
                 String::Handle(instance_type.Name()).ToCString(),
                 Class::Handle(instance_type.type_class()).id(),
                 (result.raw() == Bool::True().raw()) ? "is" : "is !",
                 String::Handle(type.Name()).ToCString(),
                 Class::Handle(type.type_class()).id(), caller_frame->pc());
  } else {
    // Instantiate type before printing.
    const AbstractType& instantiated_type = AbstractType::Handle(
        type.InstantiateFrom(instantiator_type_arguments,
                             function_type_arguments, kAllFree, Heap::kOld));
    OS::PrintErr("%s: '%s' %s '%s' instantiated from '%s' (pc: %#" Px ").\n",
                 message, String::Handle(instance_type.Name()).ToCString(),
                 (result.raw() == Bool::True().raw()) ? "is" : "is !",
                 String::Handle(instantiated_type.Name()).ToCString(),
                 String::Handle(type.Name()).ToCString(), caller_frame->pc());
  }
  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  if (function.IsInvokeFieldDispatcher() ||
      function.IsNoSuchMethodDispatcher()) {
    const auto& args_desc_array = Array::Handle(function.saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    OS::PrintErr(" -> Function %s [%s]\n", function.ToFullyQualifiedCString(),
                 args_desc.ToCString());
  } else {
    OS::PrintErr(" -> Function %s\n", function.ToFullyQualifiedCString());
  }
}

// This updates the type test cache, an array containing 8 elements:
// - instance class (or function if the instance is a closure)
// - instance type arguments (null if the instance class is not generic)
// - instantiator type arguments (null if the type is instantiated)
// - function type arguments (null if the type is instantiated)
// - instance parent function type arguments (null if instance is not a closure)
// - instance delayed type arguments (null if instance is not a closure)
// - destination type (null if the type was known at compile time)
// - test result
// It can be applied to classes with type arguments in which case it contains
// just the result of the class subtype test, not including the evaluation of
// type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
static void UpdateTypeTestCache(
    Zone* zone,
    Thread* thread,
    const Instance& instance,
    const AbstractType& destination_type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  ASSERT(!new_cache.IsNull());
  Class& instance_class = Class::Handle(zone);
  if (instance.IsSmi()) {
    instance_class = Smi::Class();
  } else {
    instance_class = instance.clazz();
  }
  // If the type is uninstantiated and refers to parent function type
  // parameters, the function_type_arguments have been canonicalized
  // when concatenated.
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsCanonical());
  auto& instance_class_id_or_function = Object::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  if (instance_class.IsClosureClass()) {
    const auto& closure = Closure::Cast(instance);
    const auto& closure_function = Function::Handle(zone, closure.function());
    instance_class_id_or_function = closure_function.raw();
    instance_type_arguments = closure.instantiator_type_arguments();
    instance_parent_function_type_arguments = closure.function_type_arguments();
    instance_delayed_type_arguments = closure.delayed_type_arguments();
  } else {
    instance_class_id_or_function = Smi::New(instance_class.id());
    if (instance_class.NumTypeArguments() > 0) {
      instance_type_arguments = instance.GetTypeArguments();
    }
  }
  if (FLAG_trace_type_checks) {
    const auto& instance_class_name =
        String::Handle(zone, instance_class.Name());
    TextBuffer buffer(256);
    buffer.Printf("  Updating test cache %#" Px " with result %s for:\n",
                  static_cast<uword>(new_cache.raw()), result.ToCString());
    if (instance.IsString()) {
      buffer.Printf("    instance: '%s'\n", instance.ToCString());
    } else {
      buffer.Printf("    instance: %s\n", instance.ToCString());
    }
    buffer.Printf("    class: %s (%" Pd ")\n", instance_class_name.ToCString(),
                  instance_class.id());
    buffer.Printf(
        "    raw entry: [ %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px
        ", %#" Px ", %#" Px ", %#" Px " ]\n",
        static_cast<uword>(instance_class_id_or_function.raw()),
        static_cast<uword>(destination_type.raw()),
        static_cast<uword>(instance_type_arguments.raw()),
        static_cast<uword>(instantiator_type_arguments.raw()),
        static_cast<uword>(function_type_arguments.raw()),
        static_cast<uword>(instance_parent_function_type_arguments.raw()),
        static_cast<uword>(instance_delayed_type_arguments.raw()),
        static_cast<uword>(result.raw()));
    OS::PrintErr("%s", buffer.buffer());
  }
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->subtype_test_cache_mutex());

    const intptr_t len = new_cache.NumberOfChecks();
    if (len >= FLAG_max_subtype_cache_entries) {
      if (FLAG_trace_type_checks) {
        OS::PrintErr(
            "Not updating subtype test cache as its length reached %d\n",
            FLAG_max_subtype_cache_entries);
      }
      return;
    }
    ASSERT(instance_type_arguments.IsNull() ||
           instance_type_arguments.IsCanonical());
    ASSERT(instantiator_type_arguments.IsNull() ||
           instantiator_type_arguments.IsCanonical());
    ASSERT(function_type_arguments.IsNull() ||
           function_type_arguments.IsCanonical());
    ASSERT(instance_parent_function_type_arguments.IsNull() ||
           instance_parent_function_type_arguments.IsCanonical());
    ASSERT(instance_delayed_type_arguments.IsNull() ||
           instance_delayed_type_arguments.IsCanonical());
    intptr_t colliding_index = -1;
    auto& old_result = Bool::Handle(zone);
    if (new_cache.HasCheck(
            instance_class_id_or_function, destination_type,
            instance_type_arguments, instantiator_type_arguments,
            function_type_arguments, instance_parent_function_type_arguments,
            instance_delayed_type_arguments, &colliding_index, &old_result)) {
      if (FLAG_trace_type_checks) {
        TextBuffer buffer(256);
        buffer.Printf("  Collision for test cache %#" Px " at index %" Pd ":\n",
                      static_cast<uword>(new_cache.raw()), colliding_index);
        buffer.Printf("    entry: ");
        new_cache.WriteEntryToBuffer(zone, &buffer, colliding_index, "      ");
        OS::PrintErr("%s\n", buffer.buffer());
      }
      if (!FLAG_enable_isolate_groups) {
        FATAL("Duplicate subtype test cache entry");
      }
      if (old_result.raw() != result.raw()) {
        FATAL("Existing subtype test cache entry has result %s, not %s",
              old_result.ToCString(), result.ToCString());
      }
      // Some other isolate might have updated the cache between entry was
      // found missing and now.
      return;
    }
    new_cache.AddCheck(instance_class_id_or_function, destination_type,
                       instance_type_arguments, instantiator_type_arguments,
                       function_type_arguments,
                       instance_parent_function_type_arguments,
                       instance_delayed_type_arguments, result);
    if (FLAG_trace_type_checks) {
      TextBuffer buffer(256);
      buffer.Printf("  Added new entry to test cache %#" Px " at index %" Pd
                    ":\n",
                    static_cast<uword>(new_cache.raw()), len);
      buffer.Printf("    new entry: ");
      new_cache.WriteEntryToBuffer(zone, &buffer, len, "      ");
      OS::PrintErr("%s\n", buffer.buffer());
    }
  }
}

// Check that the given instance is an instance of the given type.
// Tested instance may be null, because a null test cannot always be inlined,
// e.g 'null is T' yields true if T = Null, but false if T = bool.
// Arg0: instance being checked.
// Arg1: type.
// Arg2: type arguments of the instantiator of the type.
// Arg3: type arguments of the function of the type.
// Arg4: SubtypeTestCache.
// Return value: true or false.
DEFINE_RUNTIME_ENTRY(Instanceof, 5) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(zone, arguments.ArgAt(4));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsDynamicType());  // No need to check assignment.
  ASSERT(!cache.IsNull());
  const Bool& result = Bool::Get(instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments));
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf", instance, type, instantiator_type_arguments,
                   function_type_arguments, result);
  }
  UpdateTypeTestCache(zone, thread, instance, type, instantiator_type_arguments,
                      function_type_arguments, result, cache);
  arguments.SetReturn(result);
}

// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Tested instance may not be null, because a null test is always inlined.
// Arg0: instance being assigned.
// Arg1: type being assigned to.
// Arg2: type arguments of the instantiator of the type being assigned to.
// Arg3: type arguments of the function of the type being assigned to.
// Arg4: name of variable being assigned to.
// Arg5: SubtypeTestCache.
// Arg6: invocation mode (see TypeCheckMode)
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 7) {
  const Instance& src_instance =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));
  AbstractType& dst_type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  String& dst_name = String::Handle(zone);
  dst_name ^= arguments.ArgAt(4);
  ASSERT(dst_name.IsNull() || dst_name.IsString());

  SubtypeTestCache& cache = SubtypeTestCache::Handle(zone);
  cache ^= arguments.ArgAt(5);
  ASSERT(cache.IsNull() || cache.IsSubtypeTestCache());

  const TypeCheckMode mode = static_cast<TypeCheckMode>(
      Smi::CheckedHandle(zone, arguments.ArgAt(6)).Value());

#if defined(TARGET_ARCH_IA32)
  ASSERT(mode == kTypeCheckFromInline);
#endif

  // These are guaranteed on the calling side.
  ASSERT(!dst_type.IsDynamicType());
  ASSERT(!src_instance.IsNull() || isolate->use_strict_null_safety_checks());

  const bool is_instance_of = src_instance.IsAssignableTo(
      dst_type, instantiator_type_arguments, function_type_arguments);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck", src_instance, dst_type,
                   instantiator_type_arguments, function_type_arguments,
                   Bool::Get(is_instance_of));
  }
  if (!is_instance_of) {
    if (dst_name.IsNull()) {
#if !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub.
      ASSERT(mode != kTypeCheckFromInline);

      // Grab the [dst_name] from the pool.  It's stored at one pool slot after
      // the subtype-test-cache.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();
      const intptr_t dst_name_idx = stc_pool_idx + 1;
      dst_name ^= pool.ObjectAt(dst_name_idx);
#else
      UNREACHABLE();
#endif
    }

    if (dst_name.raw() ==
        Symbols::dynamic_assert_assignable_stc_check().raw()) {
#if !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub via dynamic AssertAssignable.
      ASSERT(mode != kTypeCheckFromInline);
#endif
      // This was a dynamic closure call where the destination name was not
      // known at compile-time. Thus, fetch the original arguments and arguments
      // descriptor and re-do the type check  in the runtime, which causes the
      // error with the proper destination name to be thrown.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const auto& dispatcher =
          Function::Handle(zone, caller_frame->LookupDartFunction());
      ASSERT(dispatcher.IsInvokeFieldDispatcher());
      const auto& orig_arguments_desc =
          Array::Handle(zone, dispatcher.saved_args_desc());
      const ArgumentsDescriptor args_desc(orig_arguments_desc);
      const intptr_t arg_count = args_desc.CountWithTypeArgs();
      const auto& orig_arguments = Array::Handle(zone, Array::New(arg_count));
      auto& obj = Object::Handle(zone);
      for (intptr_t i = 0; i < arg_count; i++) {
        obj = *reinterpret_cast<ObjectPtr*>(
            ParamAddress(caller_frame->fp(), arg_count - i));
        orig_arguments.SetAt(i, obj);
      }
      const auto& receiver = Closure::CheckedHandle(
          zone, orig_arguments.At(args_desc.FirstArgIndex()));
      const auto& function = Function::Handle(zone, receiver.function());
      const auto& result = Object::Handle(
          zone, function.DoArgumentTypesMatch(orig_arguments, args_desc));
      if (result.IsError()) {
        Exceptions::PropagateError(Error::Cast(result));
      }
      // IsAssignableTo returned false, so we should have thrown a type
      // error in DoArgumentsTypesMatch.
      UNREACHABLE();
    }

    ASSERT(!dst_name.IsNull());
    // Throw a dynamic type error.
    const TokenPosition location = GetCallerLocation();
    const AbstractType& src_type =
        AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      dst_type = dst_type.InstantiateFrom(instantiator_type_arguments,
                                          function_type_arguments, kAllFree,
                                          Heap::kNew);
    }
    Exceptions::CreateAndThrowTypeError(location, src_type, dst_type, dst_name);
    UNREACHABLE();
  }

  bool should_update_cache = true;
#if !defined(TARGET_ARCH_IA32)
  bool would_update_cache_if_not_lazy = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (mode == kTypeCheckFromLazySpecializeStub) {
    // Checks against type parameters are done by loading the value of the type
    // parameter and calling its type testing stub.
    // So we have to install a specialized TTS on the value of the type
    // parameter, not the parameter itself.
    if (dst_type.IsTypeParameter()) {
      dst_type = TypeParameter::Cast(dst_type).GetFromTypeArguments(
          instantiator_type_arguments, function_type_arguments);
    }
    if (FLAG_trace_type_checks) {
      OS::PrintErr("  Specializing type testing stub for %s\n",
                   dst_type.ToCString());
    }
    TypeTestingStubGenerator::SpecializeStubFor(thread, dst_type);

    // Only create the cache if we failed to create a specialized TTS and doing
    // the same check would cause an update to the cache.
    would_update_cache_if_not_lazy =
        (!src_instance.IsNull() &&
         dst_type.type_test_stub() ==
             StubCode::DefaultNullableTypeTest().raw()) ||
        dst_type.type_test_stub() == StubCode::DefaultTypeTest().raw();
    should_update_cache = would_update_cache_if_not_lazy && cache.IsNull();
  }

  // Fast path of type testing stub wasn't able to handle given type, yet it
  // passed the type check. It means that fast-path was using outdated cid
  // ranges and new classes appeared since the stub was generated.
  // Re-generate the stub.
  if ((mode == kTypeCheckFromSlowStub) && dst_type.IsType() &&
      (TypeTestingStubGenerator::DefaultCodeForType(dst_type, /*lazy=*/false) !=
       dst_type.type_test_stub()) &&
      dst_type.IsInstantiated()) {
    if (FLAG_trace_type_checks) {
      OS::PrintErr("  Rebuilding type testing stub for %s\n",
                   dst_type.ToCString());
    }
#if defined(DEBUG)
    const auto& old_code = Code::Handle(dst_type.type_test_stub());
#endif
    TypeTestingStubGenerator::SpecializeStubFor(thread, dst_type);
#if defined(DEBUG)
    ASSERT(old_code.raw() != dst_type.type_test_stub());
#endif
    // Only create the cache when we come from a normal stub.
    should_update_cache = false;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(TARGET_ARCH_IA32)

  if (should_update_cache) {
    if (cache.IsNull()) {
#if !defined(TARGET_ARCH_IA32)
      ASSERT(mode == kTypeCheckFromSlowStub ||
             (mode == kTypeCheckFromLazySpecializeStub &&
              would_update_cache_if_not_lazy));
      // We lazily create [SubtypeTestCache] for those call sites which actually
      // need one and will patch the pool entry.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();

      // Ensure we do have a STC (lazily create it if not) and all threads use
      // the same STC.
      {
        SafepointMutexLocker ml(isolate->group()->subtype_test_cache_mutex());
        cache ^= pool.ObjectAt<std::memory_order_acquire>(stc_pool_idx);
        if (cache.IsNull()) {
          cache = SubtypeTestCache::New();
          pool.SetObjectAt<std::memory_order_release>(stc_pool_idx, cache);
        }
      }
#else
      UNREACHABLE();
#endif
    }

    UpdateTypeTestCache(zone, thread, src_instance, dst_type,
                        instantiator_type_arguments, function_type_arguments,
                        Bool::True(), cache);
  }

  arguments.SetReturn(src_instance);
}

// Report that the type of the given object is not bool in conditional context.
// Throw assertion error if the object is null. (cf. Boolean Conversion
// in language Spec.)
// Arg0: bad object.
// Return value: none, throws TypeError or AssertionError.
DEFINE_RUNTIME_ENTRY(NonBoolTypeError, 1) {
  const TokenPosition location = GetCallerLocation();
  const Instance& src_instance =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));

  if (src_instance.IsNull()) {
    const Array& args = Array::Handle(zone, Array::New(5));
    args.SetAt(
        0, String::Handle(
               zone,
               String::New(
                   "Failed assertion: boolean expression must not be null")));

    // No source code for this assertion, set url to null.
    args.SetAt(1, String::Handle(zone, String::null()));
    args.SetAt(2, Object::smi_zero());
    args.SetAt(3, Object::smi_zero());
    args.SetAt(4, String::Handle(zone, String::null()));

    Exceptions::ThrowByType(Exceptions::kAssertion, args);
    UNREACHABLE();
  }

  ASSERT(!src_instance.IsBool());
  const Type& bool_interface = Type::Handle(Type::BoolType());
  const AbstractType& src_type =
      AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
  Exceptions::CreateAndThrowTypeError(location, src_type, bool_interface,
                                      Symbols::BooleanExpression());
  UNREACHABLE();
}

DEFINE_RUNTIME_ENTRY(Throw, 1) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::Throw(thread, exception);
}

DEFINE_RUNTIME_ENTRY(ReThrow, 2) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));
  Exceptions::ReThrow(thread, exception, stacktrace);
}

// Patches static call in optimized code with the target's entry point.
// Compiles target if necessary.
DEFINE_RUNTIME_ENTRY(PatchStaticCall, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(caller_frame->pc()));
  const Code& target_code = Code::Handle(zone, target_function.EnsureHasCode());
  // Before patching verify that we are not repeatedly patching to the same
  // target.
  ASSERT(target_code.raw() !=
         CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code));
  CodePatcher::PatchStaticCallAt(caller_frame->pc(), caller_code, target_code);
  caller_code.SetStaticCallTargetCodeAt(caller_frame->pc(), target_code);
  if (FLAG_trace_patching) {
    THR_Print("PatchStaticCall: patching caller pc %#" Px
              ""
              " to '%s' new entry point %#" Px " (%s)\n",
              caller_frame->pc(), target_function.ToFullyQualifiedCString(),
              target_code.EntryPoint(),
              target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  arguments.SetReturn(target_code);
#else
  UNREACHABLE();
#endif
}

#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  UNREACHABLE();
  return;
}
#else
// Gets called from debug stub when code reaches a breakpoint
// set on a runtime stub call.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  Code& orig_stub = Code::Handle(zone);
  orig_stub = isolate->debugger()->GetPatchedStubAddress(caller_frame->pc());
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseBreakpoint());
  ThrowIfError(error);
  arguments.SetReturn(orig_stub);
}
#endif

DEFINE_RUNTIME_ENTRY(SingleStepHandler, 0) {
#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseStepping());
  ThrowIfError(error);
#endif
}

// An instance call of the form o.f(...) could not be resolved.  Check if
// there is a getter with the same name.  If so, invoke it.  If the value is
// a closure, invoke it with the given arguments.  If the value is a
// non-closure, attempt to invoke "call" on it.
static bool ResolveCallThroughGetter(const Class& receiver_class,
                                     const String& target_name,
                                     const String& demangled,
                                     const Array& arguments_descriptor,
                                     Function* result) {
  const String& getter_name = String::Handle(Field::GetterName(demangled));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& getter =
      Function::Handle(Resolver::ResolveDynamicForReceiverClass(
          receiver_class, getter_name, args_desc));
  if (getter.IsNull() || getter.IsMethodExtractor()) {
    return false;
  }
  // We do this on the target_name, _not_ on the demangled name, so that
  // FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher can detect dynamic
  // calls from the dyn: tag on the name of the dispatcher.
  const Function& target_function =
      Function::Handle(receiver_class.GetInvocationDispatcher(
          target_name, arguments_descriptor,
          FunctionLayout::kInvokeFieldDispatcher, FLAG_lazy_dispatchers));
  ASSERT(!target_function.IsNull() || !FLAG_lazy_dispatchers);
  if (FLAG_trace_ic) {
    OS::PrintErr(
        "InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        receiver_class.ToCString(), receiver_class.id(),
        target_function.IsNull() ? "null" : target_function.ToCString());
  }
  *result = target_function.raw();
  return true;
}

// Handle other invocations (implicit closures, noSuchMethod).
FunctionPtr InlineCacheMissHelper(const Class& receiver_class,
                                  const Array& args_descriptor,
                                  const String& target_name) {
  // Create a demangled version of the target_name, if necessary, This is used
  // for the field getter in ResolveCallThroughGetter and as the target name
  // for the NoSuchMethod dispatcher (if needed).
  const String* demangled = &target_name;
  if (Function::IsDynamicInvocationForwarderName(target_name)) {
    demangled = &String::Handle(
        Function::DemangleDynamicInvocationForwarderName(target_name));
  }
  const bool is_getter = Field::IsGetterName(*demangled);
  Function& result = Function::Handle();
  if (is_getter ||
      !ResolveCallThroughGetter(receiver_class, target_name, *demangled,
                                args_descriptor, &result)) {
    ArgumentsDescriptor desc(args_descriptor);
    const Function& target_function =
        Function::Handle(receiver_class.GetInvocationDispatcher(
            *demangled, args_descriptor,
            FunctionLayout::kNoSuchMethodDispatcher, FLAG_lazy_dispatchers));
    if (FLAG_trace_ic) {
      OS::PrintErr(
          "NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          receiver_class.ToCString(), receiver_class.id(),
          target_function.IsNull() ? "null" : target_function.ToCString());
    }
    result = target_function.raw();
  }
  // May be null if --no-lazy-dispatchers, in which case dispatch will be
  // handled by NoSuchMethodFromCallStub.
  ASSERT(!result.IsNull() || !FLAG_lazy_dispatchers);
  return result.raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void TrySwitchInstanceCall(Thread* thread,
                                  StackFrame* caller_frame,
                                  const Code& caller_code,
                                  const Function& caller_function,
                                  const ICData& ic_data,
                                  const Function& target_function) {
  auto zone = thread->zone();

  // Monomorphic/megamorphic calls only check the receiver CID.
  if (ic_data.NumArgsTested() != 1) return;

  ASSERT(ic_data.rebind_rule() == ICData::kInstance);

  // Monomorphic/megamorphic calls don't record exactness.
  if (ic_data.is_tracking_exactness()) return;

#if !defined(PRODUCT)
  // Monomorphic/megamorphic do not check the isolate's stepping flag.
  if (Isolate::Current()->has_attempted_stepping()) return;
#endif

  // Monomorphic/megamorphic calls are only for unoptimized code.
  ASSERT(!caller_code.is_optimized());

  // Code is detached from its function. This will prevent us from resetting
  // the switchable call later because resets are function based and because
  // the ic_data_array belongs to the function instead of the code. This should
  // only happen because of reload, but it sometimes happens with KBC mixed mode
  // probably through a race between foreground and background compilation.
  if (caller_function.unoptimized_code() != caller_code.raw()) {
    return;
  }
#if !defined(PRODUCT)
  // Skip functions that contain breakpoints or when debugger is in single
  // stepping mode.
  if (Debugger::IsDebugging(thread, caller_function)) return;
#endif

  const intptr_t num_checks = ic_data.NumberOfChecks();

  // Monomorphic call.
  if (FLAG_unopt_monomorphic_calls && (num_checks == 1)) {
    // A call site in the monomorphic state does not load the arguments
    // descriptor, so do not allow transition to this state if the callee
    // needs it.
    if (target_function.PrologueNeedsArgumentsDescriptor()) {
      return;
    }

    const Array& data = Array::Handle(zone, ic_data.entries());
    const Code& target = Code::Handle(zone, target_function.EnsureHasCode());
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, data,
                                     target);
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to monomorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }

  // Megamorphic call.
  if (FLAG_unopt_megamorphic_calls &&
      (num_checks > FLAG_max_polymorphic_checks)) {
    const String& name = String::Handle(zone, ic_data.target_name());
    const Array& descriptor =
        Array::Handle(zone, ic_data.arguments_descriptor());
    const MegamorphicCache& cache = MegamorphicCache::Handle(
        zone, MegamorphicCacheTable::Lookup(thread, name, descriptor));
    ic_data.set_is_megamorphic(true);
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, cache,
                                     StubCode::MegamorphicCall());
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to megamorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Perform the subtype and return constant function based on the result.
static FunctionPtr ComputeTypeCheckTarget(const Instance& receiver,
                                          const AbstractType& type,
                                          const ArgumentsDescriptor& desc) {
  const bool result = receiver.IsInstanceOf(type, Object::null_type_arguments(),
                                            Object::null_type_arguments());
  const ObjectStore* store = Isolate::Current()->object_store();
  const Function& target =
      Function::Handle(result ? store->simple_instance_of_true_function()
                              : store->simple_instance_of_false_function());
  ASSERT(!target.IsNull());
  return target.raw();
}

static FunctionPtr Resolve(
    Thread* thread,
    Zone* zone,
    const GrowableArray<const Instance*>& caller_arguments,
    const Class& receiver_class,
    const String& name,
    const Array& descriptor) {
  ASSERT(name.IsSymbol());
  auto& target_function = Function::Handle(zone);
  ArgumentsDescriptor args_desc(descriptor);

  if (receiver_class.EnsureIsFinalized(thread) == Error::null()) {
    target_function = Resolver::ResolveDynamicForReceiverClass(receiver_class,
                                                               name, args_desc);
  }
  if (caller_arguments.length() == 2 &&
      target_function.raw() ==
          thread->isolate()->object_store()->simple_instance_of_function()) {
    // Replace the target function with constant function.
    const AbstractType& type = AbstractType::Cast(*caller_arguments[1]);
    target_function =
        ComputeTypeCheckTarget(*caller_arguments[0], type, args_desc);
  }

  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver_class, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
  }

  return target_function.raw();
}

// Handles a static call in unoptimized code that has one argument type not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument.
// Arg1: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerOneArg, 2) {
  const Instance& arg = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  ASSERT(!target.IsNull() && target.HasCode());
  ic_data.EnsureHasReceiverCheck(arg.GetClassId(), target, 1);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ")\n",
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
  const Instance& arg0 = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& arg1 = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(!ic_data.NumberOfChecksIs(0));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  GrowableArray<intptr_t> cids(2);
  cids.Add(arg0.GetClassId());
  cids.Add(arg1.GetClassId());
  ic_data.EnsureHasCheck(cids, target);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ", %" Pd
                 ")\n",
                 caller_frame->pc(), target.ToCString(), cids[0], cids[1]);
  }
  arguments.SetReturn(target);
}

#if defined(DART_PRECOMPILED_RUNTIME)

static bool IsSingleTarget(Isolate* isolate,
                           Zone* zone,
                           intptr_t lower_cid,
                           intptr_t upper_cid,
                           const Function& target,
                           const String& name) {
  Class& cls = Class::Handle(zone);
  ClassTable* table = isolate->class_table();
  Function& other_target = Function::Handle(zone);
  for (intptr_t cid = lower_cid; cid <= upper_cid; cid++) {
    if (!table->HasValidClassAt(cid)) continue;
    cls = table->At(cid);
    if (cls.is_abstract()) continue;
    if (!cls.is_allocated()) continue;
    other_target = Resolver::ResolveDynamicAnyArgs(zone, cls, name,
                                                   /*allow_add=*/false);
    if (other_target.raw() != target.raw()) {
      return false;
    }
  }
  return true;
}


class SavedUnlinkedCallMapKeyEqualsTraits : public AllStatic {
 public:
  static const char* Name() { return "SavedUnlinkedCallMapKeyEqualsTraits "; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& key1, const Object& key2) {
    if (!key1.IsInteger() || !key2.IsInteger()) return false;
    return Integer::Cast(key1).Equals(Integer::Cast(key2));
  }
  static uword Hash(const Object& key) {
    return Integer::Cast(key).CanonicalizeHash();
  }
};

using UnlinkedCallMap = UnorderedHashMap<SavedUnlinkedCallMapKeyEqualsTraits>;

static void SaveUnlinkedCall(Zone* zone,
                             Isolate* isolate,
                             uword frame_pc,
                             const UnlinkedCall& unlinked_call) {
  IsolateGroup* isolate_group = isolate->group();

  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  if (isolate_group->saved_unlinked_calls() == Array::null()) {
    const auto& initial_map =
        Array::Handle(zone, HashTables::New<UnlinkedCallMap>(16, Heap::kOld));
    isolate_group->set_saved_unlinked_calls(initial_map);
  }

  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());
  const auto& pc = Integer::Handle(zone, Integer::NewFromUint64(frame_pc));
  // Some other isolate might have updated unlinked_call_map[pc] too, but
  // their update should be identical to ours.
  const auto& new_or_old_value = UnlinkedCall::Handle(
      zone, UnlinkedCall::RawCast(
                unlinked_call_map.InsertOrGetValue(pc, unlinked_call)));
  RELEASE_ASSERT(new_or_old_value.raw() == unlinked_call.raw());
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
}

static UnlinkedCallPtr LoadUnlinkedCall(Zone* zone,
                                        Isolate* isolate,
                                        uword pc) {
  IsolateGroup* isolate_group = isolate->group();

  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  ASSERT(isolate_group->saved_unlinked_calls() != Array::null());
  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());

  const auto& pc_integer = Integer::Handle(zone, Integer::NewFromUint64(pc));
  const auto& unlinked_call = UnlinkedCall::Cast(
      Object::Handle(zone, unlinked_call_map.GetOrDie(pc_integer)));
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
  return unlinked_call.raw();
}

// NOTE: Right now we never delete [UnlinkedCall] objects. They are needed while
// a call site is in Unlinked/Monomorphic/MonomorphicSmiable/SingleTarget
// states.
//
// Theoretically we could free the [UnlinkedCall] object once we transition the
// call site to use ICData/MegamorphicCache, but that would require careful
// coordination between the deleter and a possible concurrent reader.
//
// To simplify the code we decided not to do that atm (only a very small
// fraction of callsites in AOT use switchable calls, the name/args-descriptor
// objects are kept alive anyways -> there is little memory savings from
// freeing the [UnlinkedCall] objects).

#endif  // defined(DART_PRECOMPILED_RUNTIME)

enum class MissHandler {
  kInlineCacheMiss,
  kSwitchableCallMiss,
};

// Handles updating of type feedback and possible patching of instance calls.
//
// It works in 3 separate steps:
//   - resolve the actual target
//   - update type feedback & (optionally) perform call site transition
//   - return the right values
//
// Depending on the JIT/AOT mode we obtain current and patch new (target, data)
// differently:
//
//   - JIT calls must be patched with CodePatcher::PatchInstanceCallAt()
//   - AOT calls must be patched with CodePatcher::PatchSwitchableCallAt()
//
// Independent of which miss handler was used or how we will return, we look at
// current (target, data) and see if we need to transition the call site to a
// new (target, data). We do this while holding `IG->patchable_call_mutex()`.
//
// Depending on which miss handler got called we might need to return
// differently:
//
//   - SwitchableCallMiss will get get (stub, data) return value
//   - InlineCache*Miss will get get function as return value
//
class PatchableCallHandler {
 public:
  PatchableCallHandler(Thread* thread,
                       const GrowableArray<const Instance*>& caller_arguments,
                       MissHandler miss_handler,
                       NativeArguments arguments,
                       StackFrame* caller_frame,
                       const Code& caller_code,
                       const Function& caller_function)
      : isolate_(thread->isolate()),
        thread_(thread),
        zone_(thread->zone()),
        caller_arguments_(caller_arguments),
        miss_handler_(miss_handler),
        arguments_(arguments),
        caller_frame_(caller_frame),
        caller_code_(caller_code),
        caller_function_(caller_function),
        name_(String::Handle()),
        args_descriptor_(Array::Handle()) {
    // We only have two arg IC calls in JIT mode.
    ASSERT(caller_arguments_.length() == 1 || !FLAG_precompiled_mode);
  }

  void ResolveSwitchAndReturn(const Object& data);

 private:
  FunctionPtr ResolveTargetFunction(const Object& data);
  void HandleMiss(const Object& old_data,
                  const Code& old_target,
                  const Function& target_function);

#if defined(DART_PRECOMPILED_RUNTIME)
  void DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                         const Function& target_function);
  void DoMonomorphicMissAOT(const Object& data,
                            const Function& target_function);
  void DoSingleTargetMissAOT(const SingleTargetCache& data,
                             const Function& target_function);
  void DoICDataMissAOT(const ICData& data, const Function& target_function);
  bool CanExtendSingleTargetRange(const String& name,
                                  const Function& old_target,
                                  const Function& target_function,
                                  intptr_t* lower,
                                  intptr_t* upper);
#else
  void DoMonomorphicMissJIT(const Object& data,
                            const Function& target_function);
  void DoICDataMissJIT(const ICData& data,
                       const Object& old_data,
                       const Function& target_function);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  void DoMegamorphicMiss(const MegamorphicCache& data,
                         const Function& target_function);

  void UpdateICDataWithTarget(const ICData& ic_data,
                              const Function& target_function);
  void TrySwitch(const ICData& ic_data, const Function& target_function);

  void ReturnAOT(const Code& stub, const Object& data);
  void ReturnJIT(const Code& stub, const Object& data, const Function& target);
  void ReturnJITorAOT(const Code& stub,
                      const Object& data,
                      const Function& target);

  const Instance& receiver() { return *caller_arguments_[0]; }

  bool should_consider_patching() {
    // In AOT we use switchable calls.
    if (FLAG_precompiled_mode) return true;

    // In JIT instance calls use a different calling sequence in unoptimized vs
    // optimized code (see [FlowGraphCompiler::EmitInstanceCallJIT] vs
    // [FlowGraphCompiler::EmitOptimizedInstanceCall]).
    //
    // The [CodePatcher::GetInstanceCallAt], [CodePatcher::PatchInstanceCallAt]
    // only recognize unoptimized call pattern.
    //
    // So we will not try to switch optimized instance calls.
    return !caller_code_.is_optimized();
  }

  ICDataPtr NewICData();
  ICDataPtr NewICDataWithTarget(intptr_t cid, const Function& target);

  Isolate* isolate_;
  Thread* thread_;
  Zone* zone_;
  const GrowableArray<const Instance*>& caller_arguments_;
  MissHandler miss_handler_;
  NativeArguments arguments_;
  StackFrame* caller_frame_;
  const Code& caller_code_;
  const Function& caller_function_;

  // Call-site information populated during resolution.
  String& name_;
  Array& args_descriptor_;
  bool is_monomorphic_hit_ = false;
};

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                                             const Function& target_function) {
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  Object& object = Object::Handle(zone_, ic_data.raw());
  Code& code = Code::Handle(zone_, StubCode::ICCallThroughCode().raw());
  // If the target function has optional parameters or is generic, it's
  // prologue requires ARGS_DESC_REG to be populated. Yet the switchable calls
  // do not populate that on the call site, which is why we don't transition
  // those call sites to monomorphic, but rather directly to call via stub
  // (which will populate the ARGS_DESC_REG from the ICData).
  //
  // Because of this we also don't generate monomorphic checks for those
  // functions.
  if (!target_function.IsNull() &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // Patch to monomorphic call.
    ASSERT(target_function.HasCode());
    const Code& target_code =
        Code::Handle(zone_, target_function.CurrentCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));

    if (unlinked.can_patch_to_monomorphic()) {
      object = expected_cid.raw();
      code = target_code.raw();
      ASSERT(code.HasMonomorphicEntry());
    } else {
      object = MonomorphicSmiableCall::New(expected_cid.Value(), target_code);
      code = StubCode::MonomorphicSmiableCheck().raw();
    }
  }
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, object,
                                     code);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
}

bool PatchableCallHandler::CanExtendSingleTargetRange(
    const String& name,
    const Function& old_target,
    const Function& target_function,
    intptr_t* lower,
    intptr_t* upper) {
  if (old_target.raw() != target_function.raw()) {
    return false;
  }
  intptr_t unchecked_lower, unchecked_upper;
  if (receiver().GetClassId() < *lower) {
    unchecked_lower = receiver().GetClassId();
    unchecked_upper = *lower - 1;
    *lower = receiver().GetClassId();
  } else {
    unchecked_upper = receiver().GetClassId();
    unchecked_lower = *upper + 1;
    *upper = receiver().GetClassId();
  }

  return IsSingleTarget(isolate_, zone_, unchecked_lower, unchecked_upper,
                        target_function, name);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
static ICDataPtr FindICDataForInstanceCall(Zone* zone,
                                           const Code& code,
                                           uword pc) {
  uword pc_offset = pc - code.PayloadStart();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone, code.pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, PcDescriptorsLayout::kIcCall);
  intptr_t deopt_id = -1;
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      deopt_id = iter.DeoptId();
      break;
    }
  }
  ASSERT(deopt_id != -1);
  return Function::Handle(zone, code.function()).FindICData(deopt_id);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissAOT(
    const Object& data,
    const Function& target_function) {
  classid_t old_expected_cid;
  if (data.IsSmi()) {
    old_expected_cid = Smi::Cast(data).Value();
  } else {
    RELEASE_ASSERT(data.IsMonomorphicSmiableCall());
    old_expected_cid = MonomorphicSmiableCall::Cast(data).expected_cid();
  }
  const bool is_monomorphic_hit = old_expected_cid == receiver().GetClassId();
  const auto& old_receiver_class =
      Class::Handle(zone_, isolate_->class_table()->At(old_expected_cid));
  const auto& old_target = Function::Handle(
      zone_, Resolve(thread_, zone_, caller_arguments_, old_receiver_class,
                     name_, args_descriptor_));

  const auto& ic_data = ICData::Handle(
      zone_, old_target.IsNull()
                 ? NewICData()
                 : NewICDataWithTarget(old_expected_cid, old_target));

  if (is_monomorphic_hit) {
    // The site just have been updated to monomorphic state with same
    // exact class id - do nothing in that case: stub will call through ic data.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  intptr_t lower = old_expected_cid;
  intptr_t upper = old_expected_cid;
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    const SingleTargetCache& cache =
        SingleTargetCache::Handle(zone_, SingleTargetCache::New());
    const Code& code = Code::Handle(zone_, target_function.CurrentCode());
    cache.set_target(code);
    cache.set_entry_point(code.EntryPoint());
    cache.set_lower_limit(lower);
    cache.set_upper_limit(upper);
    const Code& stub = StubCode::SingleTargetCall();
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, cache,
                                       stub);
    // Return the ICData. The miss stub will jump to continue in the IC call
    // stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Patch to call through stub.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissJIT(
    const Object& data,
    const Function& target_function) {
  const ICData& ic_data = ICData::Handle(
      zone_,
      FindICDataForInstanceCall(zone_, caller_code_, caller_frame_->pc()));
  RELEASE_ASSERT(!ic_data.IsNull());

  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& stub = ic_data.is_tracking_exactness()
                         ? StubCode::OneArgCheckInlineCacheWithExactnessCheck()
                         : StubCode::OneArgCheckInlineCache();
  CodePatcher::PatchInstanceCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                   stub);
  if (FLAG_trace_ic) {
    OS::PrintErr("Instance call at %" Px
                 " switching to polymorphic dispatch, %s\n",
                 caller_frame_->pc(), ic_data.ToCString());
  }

  ASSERT(caller_arguments_.length() == 1);
  UpdateICDataWithTarget(ic_data, target_function);
  ASSERT(should_consider_patching());
  TrySwitchInstanceCall(thread_, caller_frame_, caller_code_, caller_function_,
                        ic_data, target_function);
  ReturnJIT(stub, ic_data, target_function);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoSingleTargetMissAOT(
    const SingleTargetCache& data,
    const Function& target_function) {
  const Code& old_target_code = Code::Handle(zone_, data.target());
  const Function& old_target =
      Function::Handle(zone_, Function::RawCast(old_target_code.owner()));

  // We lost the original ICData when we patched to the monomorphic case.
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  intptr_t lower = data.lower_limit();
  intptr_t upper = data.upper_limit();
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    data.set_lower_limit(lower);
    data.set_upper_limit(upper);
    // Return the ICData. The single target stub will jump to continue in the
    // IC call stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Call site is not single target, switch to call using ICData.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The single target stub will jump to continue in the
  // IC call stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissAOT(const ICData& ic_data,
                                           const Function& target_function) {
  const String& name = String::Handle(zone_, ic_data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, ic_data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("ICData miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }

  if (target_function.IsNull()) {
    ReturnAOT(StubCode::NoSuchMethodDispatcher(), ic_data);
    return;
  }

  const intptr_t number_of_checks = ic_data.NumberOfChecks();

  if ((number_of_checks == 0) &&
      (!FLAG_precompiled_mode || ic_data.receiver_cannot_be_smi()) &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // This call site is unlinked: transition to a monomorphic direct call.
    // Note we cannot do this if the target has optional parameters because
    // the monomorphic direct call does not load the arguments descriptor.
    // We cannot do this if we are still in the middle of precompiling because
    // the monomorphic case hides a live instance selector from the
    // treeshaker.
    const Code& target_code =
        Code::Handle(zone_, target_function.EnsureHasCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));
    ASSERT(target_code.HasMonomorphicEntry());
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                       expected_cid, target_code);
    ReturnAOT(target_code, expected_cid);
  } else {
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function);
    if (number_of_checks > FLAG_max_polymorphic_checks) {
      // Switch to megamorphic call.
      const MegamorphicCache& cache = MegamorphicCache::Handle(
          zone_, MegamorphicCacheTable::Lookup(thread_, name, descriptor));
      const Code& stub = StubCode::MegamorphicCall();

      CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                         cache, stub);
      ReturnAOT(stub, cache);
    } else {
      ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    }
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissJIT(const ICData& ic_data,
                                           const Object& old_code,
                                           const Function& target_function) {
  ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());

  if (ic_data.NumArgsTested() == 1) {
    ASSERT(old_code.raw() == StubCode::OneArgCheckInlineCache().raw() ||
           old_code.raw() ==
               StubCode::OneArgCheckInlineCacheWithExactnessCheck().raw() ||
           old_code.raw() ==
               StubCode::OneArgOptimizedCheckInlineCache().raw() ||
           old_code.raw() ==
               StubCode::OneArgOptimizedCheckInlineCacheWithExactnessCheck()
                   .raw() ||
           old_code.raw() == StubCode::ICCallBreakpoint().raw() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    if (should_consider_patching()) {
      TrySwitchInstanceCall(thread_, caller_frame_, caller_code_,
                            caller_function_, ic_data, target_function);
    }
    const Code& stub = Code::Handle(
        zone_, ic_data.is_tracking_exactness()
                   ? StubCode::OneArgCheckInlineCacheWithExactnessCheck().raw()
                   : StubCode::OneArgCheckInlineCache().raw());
    ReturnJIT(stub, ic_data, target_function);
  } else {
    ASSERT(old_code.raw() == StubCode::TwoArgsCheckInlineCache().raw() ||
           old_code.raw() == StubCode::SmiAddInlineCache().raw() ||
           old_code.raw() == StubCode::SmiLessInlineCache().raw() ||
           old_code.raw() == StubCode::SmiEqualInlineCache().raw() ||
           old_code.raw() ==
               StubCode::TwoArgsOptimizedCheckInlineCache().raw() ||
           old_code.raw() == StubCode::ICCallBreakpoint().raw() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    ReturnJIT(StubCode::TwoArgsCheckInlineCache(), ic_data, target_function);
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void PatchableCallHandler::DoMegamorphicMiss(const MegamorphicCache& data,
                                             const Function& target_function) {
  const String& name = String::Handle(zone_, data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }
  if (target_function.IsNull()) {
    ReturnJITorAOT(StubCode::NoSuchMethodDispatcher(), data, target_function);
    return;
  }

  // Insert function found into cache.
  const Smi& class_id = Smi::Handle(zone_, Smi::New(cls.id()));
  data.EnsureContains(class_id, target_function);
  ReturnJITorAOT(StubCode::MegamorphicCall(), data, target_function);
}

void PatchableCallHandler::UpdateICDataWithTarget(
    const ICData& ic_data,
    const Function& target_function) {
  if (target_function.IsNull()) return;

  // If, upon return of the runtime, we will invoke the target directly we have
  // to increment the call count here in the ICData.
  // If we instead only insert a new ICData entry and will return to the IC stub
  // which will call the target, the stub will take care of the increment.
  const bool call_target_directly =
      miss_handler_ == MissHandler::kInlineCacheMiss;
  const intptr_t invocation_count = call_target_directly ? 1 : 0;

  if (caller_arguments_.length() == 1) {
    auto exactness = StaticTypeExactnessState::NotTracking();
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (ic_data.is_tracking_exactness()) {
      exactness = receiver().IsNull()
                      ? StaticTypeExactnessState::NotExact()
                      : StaticTypeExactnessState::Compute(
                            Type::Cast(AbstractType::Handle(
                                ic_data.receivers_static_type())),
                            receiver());
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function,
                                   invocation_count, exactness);
  } else {
    GrowableArray<intptr_t> class_ids(caller_arguments_.length());
    ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());
    for (intptr_t i = 0; i < caller_arguments_.length(); i++) {
      class_ids.Add(caller_arguments_[i]->GetClassId());
    }
    ic_data.EnsureHasCheck(class_ids, target_function, invocation_count);
  }
}

void PatchableCallHandler::ReturnAOT(const Code& stub, const Object& data) {
  ASSERT(miss_handler_ == MissHandler::kSwitchableCallMiss);
  arguments_.SetArgAt(0, stub);  // Second return value.
  arguments_.SetReturn(data);
}

void PatchableCallHandler::ReturnJIT(const Code& stub,
                                     const Object& data,
                                     const Function& target) {
  // In JIT we can have two different miss handlers to which we return slightly
  // differently.
  if (miss_handler_ == MissHandler::kSwitchableCallMiss) {
    arguments_.SetArgAt(0, stub);  // Second return value.
    arguments_.SetReturn(data);
  } else {
    ASSERT(miss_handler_ == MissHandler::kInlineCacheMiss);
    arguments_.SetReturn(target);
  }
}

void PatchableCallHandler::ReturnJITorAOT(const Code& stub,
                                          const Object& data,
                                          const Function& target) {
#if defined(DART_PRECOMPILED_MODE)
  ReturnAOT(stub, data);
#else
  ReturnJIT(stub, data, target);
#endif
}

ICDataPtr PatchableCallHandler::NewICData() {
  return ICData::New(caller_function_, name_, args_descriptor_, DeoptId::kNone,
                     /*num_args_tested=*/1, ICData::kInstance);
}

ICDataPtr PatchableCallHandler::NewICDataWithTarget(intptr_t cid,
                                                    const Function& target) {
  GrowableArray<intptr_t> cids(1);
  cids.Add(cid);
  return ICData::NewWithCheck(caller_function_, name_, args_descriptor_,
                              DeoptId::kNone, /*num_args_tested=*/1,
                              ICData::kInstance, &cids, target);
}

FunctionPtr PatchableCallHandler::ResolveTargetFunction(const Object& data) {
  switch (data.GetClassId()) {
    case kUnlinkedCallCid: {
      const auto& unlinked_call = UnlinkedCall::Cast(data);

#if defined(DART_PRECOMPILED_RUNTIME)
      // When transitioning out of UnlinkedCall to other states (e.g.
      // Monomorphic, MonomorphicSmiable, SingleTarget) we lose
      // name/arg-descriptor in AOT mode and cannot recover it.
      //
      // Even if we could recover an old target function (which was missed) -
      // which we cannot in AOT bare mode - we can still lose the name due to a
      // dyn:* call site potentially targeting non-dyn:* targets.
      //
      // => We will therefore retain the unlinked call here.
      //
      // In JIT mode we always use ICData from the call site, which has the
      // correct name/args-descriptor.
      SaveUnlinkedCall(zone_, isolate_, caller_frame_->pc(), unlinked_call);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
    case kMonomorphicSmiableCallCid:
      FALL_THROUGH;
#if defined(DART_PRECOMPILED_RUNTIME)
    case kSmiCid:
      FALL_THROUGH;
    case kSingleTargetCacheCid: {
      const auto& unlinked_call = UnlinkedCall::Handle(
          zone_, LoadUnlinkedCall(zone_, isolate_, caller_frame_->pc()));
      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
#else
    case kArrayCid: {
      // ICData three-element array: Smi(receiver CID), Smi(count),
      // Function(target). It is the Array from ICData::entries_.
      const auto& ic_data = ICData::Handle(
          zone_,
          FindICDataForInstanceCall(zone_, caller_code_, caller_frame_->pc()));
      RELEASE_ASSERT(!ic_data.IsNull());
      name_ = ic_data.target_name();
      args_descriptor_ = ic_data.arguments_descriptor();
      break;
    }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
    case kICDataCid:
      FALL_THROUGH;
    case kMegamorphicCacheCid: {
      const CallSiteData& call_site_data = CallSiteData::Cast(data);
      name_ = call_site_data.target_name();
      args_descriptor_ = call_site_data.arguments_descriptor();
      break;
    }
    default:
      UNREACHABLE();
  }
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  return Resolve(thread_, zone_, caller_arguments_, cls, name_,
                 args_descriptor_);
}

void PatchableCallHandler::ResolveSwitchAndReturn(const Object& old_data) {
  // Find out actual target (which can be time consuminmg) without holding any
  // locks.
  const auto& target_function =
      Function::Handle(zone_, ResolveTargetFunction(old_data));

  auto& code = Code::Handle(zone_);
  auto& data = Object::Handle(zone_);

  // We ensure any transition in a patchable calls are done in an atomic
  // manner, we ensure we always transition forward (e.g. Monomorphic ->
  // Polymorphic).
  //
  // Mutators are only stopped if we actually need to patch a patchable call.
  // We may not do that if we e.g. just add one more check to an ICData.
  SafepointMutexLocker ml(thread_->isolate_group()->patchable_call_mutex());

#if defined(DART_PRECOMPILED_RUNTIME)
  data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame_->pc(), caller_code_);
  DEBUG_ONLY(code = CodePatcher::GetSwitchableCallTargetAt(caller_frame_->pc(),
                                                           caller_code_));
#else
  if (should_consider_patching()) {
    code ^= CodePatcher::GetInstanceCallAt(caller_frame_->pc(), caller_code_,
                                           &data);
  } else {
    ASSERT(old_data.IsICData() || old_data.IsMegamorphicCache());
    data = old_data.raw();
  }
#endif
  HandleMiss(data, code, target_function);
}

void PatchableCallHandler::HandleMiss(const Object& old_data,
                                      const Code& old_code,
                                      const Function& target_function) {
  switch (old_data.GetClassId()) {
#if defined(DART_PRECOMPILED_RUNTIME)
    case kUnlinkedCallCid:
      ASSERT(old_code.raw() == StubCode::SwitchableCallMiss().raw());
      DoUnlinkedCallAOT(UnlinkedCall::Cast(old_data), target_function);
      break;
    case kMonomorphicSmiableCallCid:
      ASSERT(old_code.raw() == StubCode::MonomorphicSmiableCheck().raw());
      FALL_THROUGH;
    case kSmiCid:
      DoMonomorphicMissAOT(old_data, target_function);
      break;
    case kSingleTargetCacheCid:
      ASSERT(old_code.raw() == StubCode::SingleTargetCall().raw());
      DoSingleTargetMissAOT(SingleTargetCache::Cast(old_data), target_function);
      break;
    case kICDataCid:
      ASSERT(old_code.raw() == StubCode::ICCallThroughCode().raw());
      DoICDataMissAOT(ICData::Cast(old_data), target_function);
      break;
#else
    case kArrayCid:
      // ICData three-element array: Smi(receiver CID), Smi(count),
      // Function(target). It is the Array from ICData::entries_.
      DoMonomorphicMissJIT(old_data, target_function);
      break;
    case kICDataCid:
      DoICDataMissJIT(ICData::Cast(old_data), old_code, target_function);
      break;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
    case kMegamorphicCacheCid:
      ASSERT(old_code.raw() == StubCode::MegamorphicCall().raw() ||
             (old_code.IsNull() && !should_consider_patching()));
      DoMegamorphicMiss(MegamorphicCache::Cast(old_data), target_function);
      break;
    default:
      UNREACHABLE();
  }
}

static void InlineCacheMissHandler(Thread* thread,
                                   Zone* zone,
                                   const GrowableArray<const Instance*>& args,
                                   const ICData& ic_data,
                                   NativeArguments native_arguments) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  const auto& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const auto& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  PatchableCallHandler handler(thread, args, MissHandler::kInlineCacheMiss,
                               native_arguments, caller_frame, caller_code,
                               caller_function);

  handler.ResolveSwitchAndReturn(ic_data);
#else
  UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(1);
  args.Add(&receiver);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Arg2: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs, 3) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& other = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(2);
  args.Add(&receiver);
  args.Add(&other);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handle the first use of an instance call
//   Arg1: Receiver.
//   Arg0: Stub out.
//   Returns: the ICData used to continue with the call.
DEFINE_RUNTIME_ENTRY(SwitchableCallMiss, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* exit_frame = iterator.NextFrame();
  ASSERT(exit_frame->IsExitFrame());
  StackFrame* miss_handler_frame = iterator.NextFrame();
  // This runtime entry can be called either from miss stub or from
  // switchable_call_miss "dart" stub/function set up in
  // [MegamorphicCacheTable::InitMissHandler].
  ASSERT(miss_handler_frame->IsStubFrame() ||
         miss_handler_frame->IsDartFrame());
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  auto& old_data = Object::Handle(zone);
#if defined(DART_PRECOMPILED_RUNTIME)
  old_data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame->pc(), caller_code);
#else
  CodePatcher::GetInstanceCallAt(caller_frame->pc(), caller_code, &old_data);
#endif

  GrowableArray<const Instance*> caller_arguments(1);
  caller_arguments.Add(&receiver);
  PatchableCallHandler handler(thread, caller_arguments,
                               MissHandler::kSwitchableCallMiss, arguments,
                               caller_frame, caller_code, caller_function);
  handler.ResolveSwitchAndReturn(old_data);
}

// Used to find the correct receiver and function to invoke or to fall back to
// invoking noSuchMethod when lazy dispatchers are disabled. Returns the
// result of the invocation or an Error.
static ObjectPtr InvokeCallThroughGetterOrNoSuchMethod(
    Thread* thread,
    Zone* zone,
    const Instance& receiver,
    const String& target_name,
    const Array& orig_arguments,
    const Array& orig_arguments_desc) {
  ASSERT(!FLAG_lazy_dispatchers);
  const bool is_dynamic_call =
      Function::IsDynamicInvocationForwarderName(target_name);
  String& demangled_target_name = String::Handle(zone, target_name.raw());
  if (is_dynamic_call) {
    demangled_target_name =
        Function::DemangleDynamicInvocationForwarderName(target_name);
  }

  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& function = Function::Handle(zone);

  // Dart distinguishes getters and regular methods and allows their calls
  // to mix with conversions, and its selectors are independent of arity. So do
  // a zigzagged lookup to see if this call failed because of an arity mismatch,
  // need for conversion, or there really is no such method.

  const bool is_getter = Field::IsGetterName(demangled_target_name);
  if (is_getter) {
    // Tear-off of a method
    // o.foo (o.get:foo) failed, closurize o.foo() if it exists.
    const auto& function_name =
        String::Handle(zone, Field::NameFromGetter(demangled_target_name));
    while (!cls.IsNull()) {
      // We don't generate dyn:* forwarders for method extractors so there is no
      // need to try to find a dyn:get:foo first (see assertion below)
      if (function.IsNull()) {
        if (cls.EnsureIsFinalized(thread) == Error::null()) {
          function = Resolver::ResolveDynamicFunction(zone, cls, function_name);
        }
      }
      if (!function.IsNull()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
        ASSERT(!kernel::NeedsDynamicInvocationForwarder(Function::Handle(
            function.GetMethodExtractor(demangled_target_name))));
#endif
        const Function& closure_function =
            Function::Handle(zone, function.ImplicitClosureFunction());
        const Object& result = Object::Handle(
            zone, closure_function.ImplicitInstanceClosure(receiver));
        return result.raw();
      }
      cls = cls.SuperClass();
    }

    // Fall through for noSuchMethod
  } else {
    // Call through field.
    // o.foo(...) failed, invoke noSuchMethod is foo exists but has the wrong
    // number of arguments, or try (o.foo).call(...)

    if ((target_name.raw() == Symbols::Call().raw()) && receiver.IsClosure()) {
      // Special case: closures are implemented with a call getter instead of a
      // call method and with lazy dispatchers the field-invocation-dispatcher
      // would perform the closure call.
      return DartEntry::InvokeClosure(thread, orig_arguments,
                                      orig_arguments_desc);
    }

    // Dynamic call sites have to use the dynamic getter as well (if it was
    // created).
    const auto& getter_name =
        String::Handle(zone, Field::GetterName(demangled_target_name));
    const auto& dyn_getter_name = String::Handle(
        zone, is_dynamic_call
                  ? Function::CreateDynamicInvocationForwarderName(getter_name)
                  : getter_name.raw());
    ArgumentsDescriptor args_desc(orig_arguments_desc);
    while (!cls.IsNull()) {
      // If there is a function with the target name but mismatched arguments
      // we need to call `receiver.noSuchMethod()`.
      if (cls.EnsureIsFinalized(thread) == Error::null()) {
        function = Resolver::ResolveDynamicFunction(zone, cls, target_name);
      }
      if (!function.IsNull()) {
        ASSERT(!function.AreValidArguments(args_desc, NULL));
        break;  // mismatch, invoke noSuchMethod
      }
      if (is_dynamic_call) {
        function =
            Resolver::ResolveDynamicFunction(zone, cls, demangled_target_name);
        if (!function.IsNull()) {
          ASSERT(!function.AreValidArguments(args_desc, NULL));
          break;  // mismatch, invoke noSuchMethod
        }
      }

      // If there is a getter we need to call-through-getter.
      if (is_dynamic_call) {
        function = Resolver::ResolveDynamicFunction(zone, cls, dyn_getter_name);
      }
      if (function.IsNull()) {
        function = Resolver::ResolveDynamicFunction(zone, cls, getter_name);
      }
      if (!function.IsNull()) {
        const Array& getter_arguments = Array::Handle(Array::New(1));
        getter_arguments.SetAt(0, receiver);
        const Object& getter_result = Object::Handle(
            zone, DartEntry::InvokeFunction(function, getter_arguments));
        if (getter_result.IsError()) {
          return getter_result.raw();
        }
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());

        orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
        return DartEntry::InvokeClosure(thread, orig_arguments,
                                        orig_arguments_desc);
      }
      cls = cls.SuperClass();
    }
  }

  const Object& result = Object::Handle(
      zone,
      DartEntry::InvokeNoSuchMethod(thread, receiver, demangled_target_name,
                                    orig_arguments, orig_arguments_desc));
  return result.raw();
}

// Invoke appropriate noSuchMethod or closure from getter.
// Arg0: receiver
// Arg1: ICData or MegamorphicCache
// Arg2: arguments descriptor array
// Arg3: arguments array
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromCallStub, 4) {
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

  const auto& result =
      Object::Handle(zone, InvokeCallThroughGetterOrNoSuchMethod(
                               thread, zone, receiver, target_name,
                               orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Invoke appropriate noSuchMethod function.
// Arg0: receiver
// Arg1: function
// Arg1: arguments descriptor array.
// Arg3: arguments array.
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromPrologue, 4) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));

  String& orig_function_name = String::Handle(zone);
  if ((function.kind() == FunctionLayout::kClosureFunction) ||
      (function.kind() == FunctionLayout::kImplicitClosureFunction)) {
    // For closure the function name is always 'call'. Replace it with the
    // name of the closurized function so that exception contains more
    // relevant information.
    orig_function_name = function.QualifiedUserVisibleName();
  } else {
    orig_function_name = function.name();
  }

  const Object& result = Object::Handle(
      zone, DartEntry::InvokeNoSuchMethod(thread, receiver, orig_function_name,
                                          orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
// The following code is used to stress test
//  - deoptimization
//  - debugger stack tracing
//  - garbage collection
//  - hot reload
static void HandleStackOverflowTestCases(Thread* thread) {
  Isolate* isolate = thread->isolate();

  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->heap()->CollectAllGarbage();
  }

  bool do_deopt = false;
  bool do_stacktrace = false;
  bool do_reload = false;
  bool do_gc = false;
  const intptr_t isolate_reload_every =
      isolate->reload_every_n_stack_overflow_checks();
  if ((FLAG_deoptimize_every > 0) || (FLAG_stacktrace_every > 0) ||
      (FLAG_gc_every > 0) || (isolate_reload_every > 0)) {
    if (!Isolate::IsSystemIsolate(isolate)) {
      // TODO(turnidge): To make --deoptimize_every and
      // --stacktrace-every faster we could move this increment/test to
      // the generated code.
      int32_t count = thread->IncrementAndGetStackOverflowCount();
      if (FLAG_deoptimize_every > 0 && (count % FLAG_deoptimize_every) == 0) {
        do_deopt = true;
      }
      if (FLAG_stacktrace_every > 0 && (count % FLAG_stacktrace_every) == 0) {
        do_stacktrace = true;
      }
      if (FLAG_gc_every > 0 && (count % FLAG_gc_every) == 0) {
        do_gc = true;
      }
      if ((isolate_reload_every > 0) && (count % isolate_reload_every) == 0) {
        do_reload = isolate->CanReload();
      }
    }
  }
  if ((FLAG_deoptimize_filter != nullptr) ||
      (FLAG_stacktrace_filter != nullptr) || (FLAG_reload_every != 0)) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
    Code& code = Code::Handle();
    Function& function = Function::Handle();
    code = frame->LookupDartCode();
    ASSERT(!code.IsNull());
    function = code.function();
    ASSERT(!function.IsNull());
    const char* function_name = nullptr;
    if ((FLAG_deoptimize_filter != nullptr) ||
        (FLAG_stacktrace_filter != nullptr)) {
      function_name = function.ToFullyQualifiedCString();
      ASSERT(function_name != nullptr);
    }
    if (!code.IsNull()) {
      if (!code.is_optimized() && FLAG_reload_every_optimized) {
        // Don't do the reload if we aren't inside optimized code.
        do_reload = false;
      }
      if (code.is_optimized() && FLAG_deoptimize_filter != nullptr &&
          strstr(function_name, FLAG_deoptimize_filter) != nullptr &&
          !function.ForceOptimize()) {
        OS::PrintErr("*** Forcing deoptimization (%s)\n",
                     function.ToFullyQualifiedCString());
        do_deopt = true;
      }
    }
    if (FLAG_stacktrace_filter != nullptr &&
        strstr(function_name, FLAG_stacktrace_filter) != nullptr) {
      OS::PrintErr("*** Computing stacktrace (%s)\n",
                   function.ToFullyQualifiedCString());
      do_stacktrace = true;
    }
  }
  if (do_deopt) {
    // TODO(turnidge): Consider using DeoptimizeAt instead.
    DeoptimizeFunctionsOnStack();
  }
  if (do_reload) {
    JSONStream js;
    // Maybe adjust the rate of future reloads.
    isolate->MaybeIncreaseReloadEveryNStackOverflowChecks();

    const char* script_uri;
    {
      NoReloadScope no_reload(isolate, thread);
      const Library& lib =
          Library::Handle(isolate->object_store()->_internal_library());
      const Class& cls = Class::Handle(
          lib.LookupClass(String::Handle(String::New("VMLibraryHooks"))));
      const Function& func = Function::Handle(Resolver::ResolveFunction(
          thread->zone(), cls,
          String::Handle(String::New("get:platformScript"))));
      Object& result = Object::Handle(
          DartEntry::InvokeFunction(func, Object::empty_array()));
      if (result.IsUnwindError()) {
        Exceptions::PropagateError(Error::Cast(result));
      }
      if (!result.IsInstance()) {
        FATAL1("Bad script uri hook: %s", result.ToCString());
      }
      result = DartLibraryCalls::ToString(Instance::Cast(result));
      if (result.IsUnwindError()) {
        Exceptions::PropagateError(Error::Cast(result));
      }
      if (!result.IsString()) {
        FATAL1("Bad script uri hook: %s", result.ToCString());
      }
      script_uri = result.ToCString();  // Zone allocated.
    }

    // Issue a reload.
    bool success = isolate->group()->ReloadSources(&js, true /* force_reload */,
                                                   script_uri);
    if (!success) {
      FATAL1("*** Isolate reload failed:\n%s\n", js.ToCString());
    }
  }
  if (do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      int num_vars = 0;
      // Variable locations and number are unknown when precompiling.
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (!frame->function().ForceOptimize()) {
        // Ensure that we have unoptimized code.
        frame->function().EnsureHasCompiledUnoptimizedCode();
        num_vars = frame->NumLocalVariables();
      }
#endif
      TokenPosition unused = TokenPosition::kNoSource;
      for (intptr_t v = 0; v < num_vars; v++) {
        frame->VariableAt(v, &var_name, &unused, &unused, &unused, &var_value);
      }
    }
    if (FLAG_stress_async_stacks) {
      isolate->debugger()->CollectAwaiterReturnStackTrace();
    }
  }
  if (do_gc) {
    isolate->heap()->CollectAllGarbage(Heap::kDebugging);
  }
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
static void HandleOSRRequest(Thread* thread) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->use_osr());
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  const Code& code = Code::ZoneHandle(frame->LookupDartCode());
  ASSERT(!code.IsNull());
  ASSERT(!code.is_optimized());
  const Function& function = Function::Handle(code.function());
  ASSERT(!function.IsNull());

  // If the code of the frame does not match the function's unoptimized code,
  // we bail out since the code was reset by an isolate reload.
  if (code.raw() != function.unoptimized_code()) {
    return;
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  ASSERT(function.HasCode());
  // Don't do OSR on intrinsified functions: The intrinsic code expects to be
  // called like a regular function and can't be entered via OSR.
  if (!Compiler::CanOptimizeFunction(thread, function) ||
      function.is_intrinsic()) {
    return;
  }

  // The unoptimized code is on the stack and should never be detached from
  // the function at this point.
  ASSERT(function.unoptimized_code() != Object::null());
  intptr_t osr_id =
      Code::Handle(function.unoptimized_code()).GetDeoptIdForOsr(frame->pc());
  ASSERT(osr_id != Compiler::kNoOSRDeoptId);
  if (FLAG_trace_osr) {
    OS::PrintErr("Attempting OSR for %s at id=%" Pd ", count=%" Pd "\n",
                 function.ToFullyQualifiedCString(), osr_id,
                 function.usage_counter());
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  const Object& result = Object::Handle(
      Compiler::CompileOptimizedFunction(thread, function, osr_id));
  ThrowIfError(result);

  if (!result.IsNull()) {
    const Code& code = Code::Cast(result);
    uword optimized_entry = code.EntryPoint();
    frame->set_pc(optimized_entry);
    frame->set_pc_marker(code.raw());
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_RUNTIME_ENTRY(AllocateMint, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->heap()->CollectAllGarbage();
  }
  constexpr uint64_t val = 0x7fffffff7fffffff;
  ASSERT(!Smi::IsValid(static_cast<int64_t>(val)));
  const auto& integer_box = Integer::Handle(zone, Integer::NewFromUint64(val));
  arguments.SetReturn(integer_box);
};

DEFINE_RUNTIME_ENTRY(StackOverflow, 0) {
#if defined(USING_SIMULATOR)
  uword stack_pos = Simulator::Current()->get_sp();
  // If simulator was never called it may return 0 as a value of SPREG.
  if (stack_pos == 0) {
    // Use any reasonable value which would not be treated
    // as stack overflow.
    stack_pos = thread->saved_stack_limit();
  }
#else
  uword stack_pos = OSThread::GetCurrentStackPointer();
#endif
  // Always clear the stack overflow flags.  They are meant for this
  // particular stack overflow runtime call and are not meant to
  // persist.
  uword stack_overflow_flags = thread->GetAndClearStackOverflowFlags();

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow now and leave the interrupt for next
  // time.
  if (!thread->os_thread()->HasStackHeadroom() ||
      IsCalleeFrameOf(thread->saved_stack_limit(), stack_pos)) {
    if (FLAG_verbose_stack_overflow) {
      OS::PrintErr("Stack overflow\n");
      OS::PrintErr("  Native SP = %" Px ", stack limit = %" Px "\n", stack_pos,
                   thread->saved_stack_limit());
      OS::PrintErr("Call stack:\n");
      OS::PrintErr("size | frame\n");
      StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                                StackFrameIterator::kNoCrossThreadIteration);
      uword fp = stack_pos;
      StackFrame* frame = frames.NextFrame();
      while (frame != NULL) {
        uword delta = (frame->fp() - fp);
        fp = frame->fp();
        OS::PrintErr("%4" Pd " %s\n", delta, frame->ToCString());
        frame = frames.NextFrame();
      }
    }

    // Use the preallocated stack overflow exception to avoid calling
    // into dart code.
    const Instance& exception =
        Instance::Handle(isolate->object_store()->stack_overflow());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  HandleStackOverflowTestCases(thread);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Handle interrupts:
  //  - store buffer overflow
  //  - OOB message (vm-service or dart:isolate)
  const Error& error = Error::Handle(thread->HandleInterrupts());
  ThrowIfError(error);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if ((stack_overflow_flags & Thread::kOsrRequest) != 0) {
    HandleOSRRequest(thread);
  }
#else
  ASSERT((stack_overflow_flags & Thread::kOsrRequest) == 0);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

DEFINE_RUNTIME_ENTRY(TraceICCall, 2) {
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(1));
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != NULL);
  OS::PrintErr(
      "IC call @%#" Px ": ICData: %#" Px " cnt:%" Pd " nchecks: %" Pd " %s\n",
      frame->pc(), static_cast<uword>(ic_data.raw()), function.usage_counter(),
      ic_data.NumberOfChecks(), function.ToFullyQualifiedCString());
}

// This is called from function that needs to be optimized.
// The requesting function can be already optimized (reoptimization).
// Returns the Code object where to continue execution.
DEFINE_RUNTIME_ENTRY(OptimizeInvokedFunction, 1) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  if (Compiler::CanOptimizeFunction(thread, function)) {
    if (FLAG_background_compilation) {
      {
        SafepointWriteRwLocker ml(thread,
                                  thread->isolate_group()->program_lock());
        Field& field =
            Field::Handle(zone, isolate->GetDeoptimizingBoxedField());
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
      if (!BackgroundCompiler::IsDisabled(isolate,
                                          /* optimizing_compiler = */ true) &&
          function.is_background_optimizable()) {
        // Ensure background compiler is running, if not start it.
        BackgroundCompiler::Start(isolate);
        // Reduce the chance of triggering a compilation while the function is
        // being compiled in the background. INT32_MIN should ensure that it
        // takes long time to trigger a compilation.
        // Note that the background compilation queue rejects duplicate entries.
        function.SetUsageCounter(INT32_MIN);
        isolate->optimizing_background_compiler()->Compile(function);
        // Continue in the same code.
        arguments.SetReturn(function);
        return;
      }
    }

    // Reset usage counter for reoptimization before calling optimizer to
    // prevent recursive triggering of function optimization.
    function.SetUsageCounter(0);
    if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
      if (function.HasOptimizedCode()) {
        THR_Print("ReCompiling function: '%s' \n",
                  function.ToFullyQualifiedCString());
      }
    }
    Object& result = Object::Handle(
        zone, Compiler::CompileOptimizedFunction(thread, function));
    ThrowIfError(result);
  }
  arguments.SetReturn(function);
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}

// The caller must be a static call in a Dart frame, or an entry frame.
// Patch static call to point to valid code's entry point.
DEFINE_RUNTIME_ENTRY(FixCallersTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
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
  RELEASE_ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(frame->pc()));

  const Code& current_target_code =
      Code::Handle(zone, target_function.EnsureHasCode());
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, current_target_code);
  caller_code.SetStaticCallTargetCodeAt(frame->pc(), current_target_code);
  if (FLAG_trace_patching) {
    OS::PrintErr(
        "FixCallersTarget: caller %#" Px
        " "
        "target '%s' -> %#" Px " (%s)\n",
        frame->pc(), target_function.ToFullyQualifiedCString(),
        current_target_code.EntryPoint(),
        current_target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  ASSERT(!current_target_code.IsDisabled());
  arguments.SetReturn(current_target_code);
#else
  UNREACHABLE();
#endif
}

// The caller must be a monomorphic call from unoptimized code.
// Patch call to point to new target.
DEFINE_RUNTIME_ENTRY(FixCallersTargetMonomorphic, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
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
  RELEASE_ASSERT(!caller_code.is_optimized());

  Object& cache = Object::Handle(zone);
  const Code& old_target_code = Code::Handle(
      zone, CodePatcher::GetInstanceCallAt(frame->pc(), caller_code, &cache));
  const Function& target_function =
      Function::Handle(zone, old_target_code.function());
  const Code& current_target_code =
      Code::Handle(zone, target_function.EnsureHasCode());
  CodePatcher::PatchInstanceCallAt(frame->pc(), caller_code, cache,
                                   current_target_code);
  if (FLAG_trace_patching) {
    OS::PrintErr(
        "FixCallersTargetMonomorphic: caller %#" Px
        " "
        "target '%s' -> %#" Px " (%s)\n",
        frame->pc(), target_function.ToFullyQualifiedCString(),
        current_target_code.EntryPoint(),
        current_target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  ASSERT(!current_target_code.IsDisabled());
  arguments.SetReturn(current_target_code);
#else
  UNREACHABLE();
#endif
}

// The caller tried to allocate an instance via an invalidated allocation
// stub.
DEFINE_RUNTIME_ENTRY(FixAllocationStubTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
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
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, alloc_stub);
  caller_code.SetStubCallTargetCodeAt(frame->pc(), alloc_stub);
  if (FLAG_trace_patching) {
    OS::PrintErr("FixAllocationStubTarget: caller %#" Px
                 " alloc-class %s "
                 " -> %#" Px "\n",
                 frame->pc(), alloc_class.ToCString(), alloc_stub.EntryPoint());
  }
  arguments.SetReturn(alloc_stub);
#else
  UNREACHABLE();
#endif
}

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason) {
  switch (deopt_reason) {
#define DEOPT_REASON_TO_TEXT(name)                                             \
  case ICData::kDeopt##name:                                                   \
    return #name;
    DEOPT_REASONS(DEOPT_REASON_TO_TEXT)
#undef DEOPT_REASON_TO_TEXT
    default:
      UNREACHABLE();
      return "";
  }
}

void DeoptimizeAt(const Code& optimized_code, StackFrame* frame) {
  ASSERT(optimized_code.is_optimized());

  // Force-optimized code is optimized code which cannot deoptimize and doesn't
  // have unoptimized code to fall back to.
  ASSERT(!optimized_code.is_force_optimized());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
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

  if (frame->IsMarkedForLazyDeopt()) {
    // Deopt already scheduled.
    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt already scheduled for fp=%" Pp "\n", frame->fp());
    }
  } else {
    uword deopt_pc = frame->pc();
    ASSERT(optimized_code.ContainsInstructionAt(deopt_pc));

#if defined(DEBUG)
    ValidateFrames();
#endif

    // N.B.: Update the pending deopt table before updating the frame. The
    // profiler may attempt a stack walk in between.
    thread->isolate()->AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for fp=%" Pp ", pc=%" Pp "\n",
                frame->fp(), deopt_pc);
    }
  }

  // Mark code as dead (do not GC its embedded objects).
  optimized_code.set_is_alive(false);
}

// Currently checks only that all optimized frames have kDeoptIndex
// and unoptimized code has the kDeoptAfter.
void DeoptimizeFunctionsOnStack() {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  Code& optimized_code = Code::Handle();
  while (frame != NULL) {
    optimized_code = frame->LookupDartCode();
    if (optimized_code.is_optimized() && !optimized_code.is_force_optimized()) {
      DeoptimizeAt(optimized_code, frame);
    }
    frame = iterator.NextFrame();
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static const intptr_t kNumberOfSavedCpuRegisters = kNumberOfCpuRegisters;
static const intptr_t kNumberOfSavedFpuRegisters = kNumberOfFpuRegisters;

static void CopySavedRegisters(uword saved_registers_address,
                               fpu_register_t** fpu_registers,
                               intptr_t** cpu_registers) {
  // Tell MemorySanitizer this region is initialized by generated code. This
  // region isn't already (fully) unpoisoned by FrameSetIterator::Unpoison
  // because it is in an exit frame and stack frame iteration doesn't have
  // access to true SP for exit frames.
  MSAN_UNPOISON(reinterpret_cast<void*>(saved_registers_address),
                kNumberOfSavedFpuRegisters * kFpuRegisterSize +
                    kNumberOfSavedCpuRegisters * kWordSize);

  ASSERT(sizeof(fpu_register_t) == kFpuRegisterSize);
  fpu_register_t* fpu_registers_copy =
      new fpu_register_t[kNumberOfSavedFpuRegisters];
  ASSERT(fpu_registers_copy != NULL);
  for (intptr_t i = 0; i < kNumberOfSavedFpuRegisters; i++) {
    fpu_registers_copy[i] =
        *reinterpret_cast<fpu_register_t*>(saved_registers_address);
    saved_registers_address += kFpuRegisterSize;
  }
  *fpu_registers = fpu_registers_copy;

  ASSERT(sizeof(intptr_t) == kWordSize);
  intptr_t* cpu_registers_copy = new intptr_t[kNumberOfSavedCpuRegisters];
  ASSERT(cpu_registers_copy != NULL);
  for (intptr_t i = 0; i < kNumberOfSavedCpuRegisters; i++) {
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
DEFINE_LEAF_RUNTIME_ENTRY(intptr_t,
                          DeoptimizeCopyFrame,
                          2,
                          uword saved_registers_address,
                          uword is_lazy_deopt) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  StackZone zone(thread);
  HANDLESCOPE(thread);

  // All registers have been saved below last-fp as if they were locals.
  const uword last_fp =
      saved_registers_address + (kNumberOfSavedCpuRegisters * kWordSize) +
      (kNumberOfSavedFpuRegisters * kFpuRegisterSize) -
      ((runtime_frame_layout.first_local_from_fp + 1) * kWordSize);

  // Get optimized code and frame that need to be deoptimized.
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);

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
              (is_lazy_deopt != 0u) ? "lazy-deopt" : "");
  }

  if (is_lazy_deopt != 0u) {
    uword deopt_pc = isolate->FindPendingDeopt(caller_frame->fp());
    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt fp=%" Pp " pc=%" Pp "\n", caller_frame->fp(),
                deopt_pc);
    }

    // N.B.: Update frame before updating pending deopt table. The profiler
    // may attempt a stack walk in between.
    caller_frame->set_pc(deopt_pc);
    ASSERT(caller_frame->pc() == deopt_pc);
    ASSERT(optimized_code.ContainsInstructionAt(caller_frame->pc()));
    isolate->ClearPendingDeoptsAtOrBelow(caller_frame->fp());
  } else {
    if (FLAG_trace_deoptimization) {
      THR_Print("Eager deopt fp=%" Pp " pc=%" Pp "\n", caller_frame->fp(),
                caller_frame->pc());
    }
  }

  // Copy the saved registers from the stack.
  fpu_register_t* fpu_registers;
  intptr_t* cpu_registers;
  CopySavedRegisters(saved_registers_address, &fpu_registers, &cpu_registers);

  // Create the DeoptContext.
  DeoptContext* deopt_context = new DeoptContext(
      caller_frame, optimized_code, DeoptContext::kDestIsOriginalFrame,
      fpu_registers, cpu_registers, is_lazy_deopt != 0, deoptimizing_code);
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
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);
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

  deopt_context->set_dest_frame(caller_frame);
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
#if defined(DEBUG)
  {
    // We may rendezvous for a safepoint at entry or GC from the allocations
    // below. Check the stack is walkable.
    ValidateFrames();
  }
#endif
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

DEFINE_RUNTIME_ENTRY(RewindPostDeopt, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(PRODUCT)
  isolate->debugger()->RewindPostDeopt();
#endif  // !PRODUCT
#endif  // !DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
}

double DartModulo(double left, double right) {
  double remainder = fmod_ieee(left, right);
  if (remainder == 0.0) {
    // We explicitly switch to the positive 0.0 (just in case it was negative).
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

// Update global type feedback recorded for a field recording the assignment
// of the given value.
//   Arg0: Field object;
//   Arg1: Value that is being stored.
DEFINE_RUNTIME_ENTRY(UpdateFieldCid, 2) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& value = Object::Handle(arguments.ArgAt(1));
  field.RecordStore(value);
#else
  UNREACHABLE();
#endif
}

DEFINE_RUNTIME_ENTRY(InitInstanceField, 2) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(1));
  Object& result = Object::Handle(zone, field.InitializeInstance(instance));
  ThrowIfError(result);
  result = instance.GetField(field);
  ASSERT((result.raw() != Object::sentinel().raw()) &&
         (result.raw() != Object::transition_sentinel().raw()));
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(InitStaticField, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Object& result = Object::Handle(zone, field.InitializeStatic());
  ThrowIfError(result);
  result = field.StaticValue();
  ASSERT((result.raw() != Object::sentinel().raw()) &&
         (result.raw() != Object::transition_sentinel().raw()));
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(LateFieldAssignedDuringInitializationError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldAssignedDuringInitialization(
      String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(LateFieldNotInitializedError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldNotInitialized(String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(NotLoaded, 0) {
  // We could just use a trap instruction in the stub, but we get better stack
  // traces when there is an exit frame.
  FATAL("Not loaded");
}

// Use expected function signatures to help MSVC compiler resolve overloading.
typedef double (*UnaryMathCFunction)(double x);
typedef double (*BinaryMathCFunction)(double x, double y);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcPow,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<BinaryMathCFunction>(&pow)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    DartModulo,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&DartModulo)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan2,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&atan2_ieee)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcFloor,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&floor)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCeil,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&ceil)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTrunc,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&trunc)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcRound,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&round)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&cos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcSin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&sin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAsin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&asin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAcos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&acos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&tan)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&atan)));

extern "C" void DFLRT_EnterSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);
  ASSERT(thread->execution_state() == Thread::kThreadInNative);
  thread->EnterSafepoint();
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(EnterSafepoint, 0, false, &DFLRT_EnterSafepoint);

extern "C" void DFLRT_ExitSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "ExitSafepoint");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);

  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  thread->ExitSafepoint();
  TRACE_RUNTIME_CALL("%s", "ExitSafepoint done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(ExitSafepoint, 0, false, &DFLRT_ExitSafepoint);

// Not registered as a runtime entry because we can't use Thread to look it up.
static Thread* GetThreadForNativeCallback(uword callback_id,
                                          uword return_address) {
  Thread* const thread = Thread::Current();
  if (thread == nullptr) {
    FATAL("Cannot invoke native callback outside an isolate.");
  }
  if (thread->no_callback_scope_depth() != 0) {
    FATAL("Cannot invoke native callback when API callbacks are prohibited.");
  }
  if (!thread->IsMutatorThread()) {
    FATAL("Native callbacks must be invoked on the mutator thread.");
  }

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  thread->set_execution_state(Thread::kThreadInVM);

  thread->ExitSafepoint();
  thread->VerifyCallbackIsolate(callback_id, return_address);

  return thread;
}

#if defined(HOST_OS_WINDOWS)
#pragma intrinsic(_ReturnAddress)
#endif

// This is called directly by NativeEntryInstr. At the moment we enter this
// routine, the caller is generated code in the Isolate heap. Therefore we check
// that the return address (caller) corresponds to the declared callback ID's
// code within this Isolate.
extern "C" Thread* DLRT_GetThreadForNativeCallback(uword callback_id) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("GetThreadForNativeCallback %" Pd, callback_id);
#if defined(HOST_OS_WINDOWS)
  void* return_address = _ReturnAddress();
#else
  void* return_address = __builtin_return_address(0);
#endif
  Thread* return_value = GetThreadForNativeCallback(
      callback_id, reinterpret_cast<uword>(return_address));
  TRACE_RUNTIME_CALL("GetThreadForNativeCallback returning %p", return_value);
  return return_value;
}

// This is called by a native callback trampoline
// (see StubCodeCompiler::GenerateJITCallbackTrampolines). There is no need to
// check the return address because the trampoline will use the callback ID to
// look up the generated code. We still check that the callback ID is valid for
// this isolate.
extern "C" Thread* DLRT_GetThreadForNativeCallbackTrampoline(
    uword callback_id) {
  CHECK_STACK_ALIGNMENT;
  return GetThreadForNativeCallback(callback_id, 0);
}

// This is called directly by EnterHandleScopeInstr.
extern "C" ApiLocalScope* DLRT_EnterHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("EnterHandleScope %p", thread);
  thread->EnterApiScope();
  ApiLocalScope* return_value = thread->api_top_scope();
  TRACE_RUNTIME_CALL("EnterHandleScope returning %p", return_value);
  return return_value;
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    EnterHandleScope,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_EnterHandleScope));

// This is called directly by ExitHandleScopeInstr.
extern "C" void DLRT_ExitHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("ExitHandleScope %p", thread);
  thread->ExitApiScope();
  TRACE_RUNTIME_CALL("ExitHandleScope %s", "done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    ExitHandleScope,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_ExitHandleScope));

// This is called directly by AllocateHandleInstr.
extern "C" LocalHandle* DLRT_AllocateHandle(ApiLocalScope* scope) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("AllocateHandle %p", scope);
  LocalHandle* return_value = scope->local_handles()->AllocateHandle();
  TRACE_RUNTIME_CALL("AllocateHandle returning %p", return_value);
  return return_value;
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    AllocateHandle,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_AllocateHandle));

}  // namespace dart
