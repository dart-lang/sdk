// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/heap/verifier.h"
#include "vm/instructions.h"
#include "vm/interpreter.h"
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
DEFINE_FLAG(bool, trace_deoptimization, false, "Trace deoptimization");
DEFINE_FLAG(bool,
            trace_deoptimization_verbose,
            false,
            "Trace deoptimization verbose");

DECLARE_FLAG(bool, enable_interpreter);
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

// Add function to a class and that class to the class dictionary so that
// frame walking can be used.
const Function& RegisterFakeFunction(const char* name, const Code& code) {
  Thread* thread = Thread::Current();
  const String& class_name = String::Handle(Symbols::New(thread, "ownerClass"));
  const Script& script = Script::Handle();
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Class& owner_class = Class::Handle(
      Class::New(lib, class_name, script, TokenPosition::kNoSource));
  const String& function_name = String::ZoneHandle(Symbols::New(thread, name));
  const Function& function = Function::ZoneHandle(Function::New(
      function_name, RawFunction::kRegularFunction, true, false, false, false,
      false, owner_class, TokenPosition::kMinSource));
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  owner_class.SetFunctions(functions);
  lib.AddClass(owner_class);
  function.AttachCode(code);
  return function;
}

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
  InvocationMirror::Kind kind = InvocationMirror::kMethod;
  if (Field::IsGetterName(selector)) {
    kind = InvocationMirror::kGetter;
  } else if (Field::IsSetterName(selector)) {
    kind = InvocationMirror::kSetter;
  }

  const Smi& invocation_type = Smi::Handle(
      zone,
      Smi::New(InvocationMirror::EncodeType(InvocationMirror::kDynamic, kind)));

  const Array& args = Array::Handle(zone, Array::New(6));
  args.SetAt(0, /* instance */ Object::null_object());
  args.SetAt(1, selector);
  args.SetAt(2, invocation_type);
  args.SetAt(3, /* func_type_args */ Object::null_object());
  args.SetAt(4, /* func_args */ Object::null_object());
  args.SetAt(5, /* func_arg_names */ Object::null_object());
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
}

DEFINE_RUNTIME_ENTRY(NullError, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  ASSERT(!caller_frame->is_interpreted());
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

  const Array& array =
      Array::Handle(zone, Array::New(static_cast<intptr_t>(len), Heap::kNew));
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

// Helper returning the token position of the Dart caller.
static TokenPosition GetCallerLocation() {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  return caller_frame->GetTokenPos();
}

// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 2) {
  const Class& cls = Class::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& instance =
      Instance::Handle(zone, Instance::New(cls, Heap::kNew));

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

DEFINE_LEAF_RUNTIME_ENTRY(RawObject*,
                          AddAllocatedObjectToRememberedSet,
                          2,
                          RawObject* object,
                          Thread* thread) {
  // The allocation stubs in will call this leaf method for newly allocated
  // old space objects.
  RELEASE_ASSERT(object->IsOldObject() && !object->IsRemembered());

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
  if (object->IsArray()) {
    const intptr_t length =
        Array::LengthOf(reinterpret_cast<RawArray*>(object));
    add_to_remembered_set =
        CreateArrayInstr::WillAllocateNewOrRemembered(length);
  } else if (object->IsContext()) {
    const intptr_t num_context_variables =
        Context::NumVariables(reinterpret_cast<RawContext*>(object));
    add_to_remembered_set =
        AllocateContextInstr::WillAllocateNewOrRemembered(
            num_context_variables) ||
        AllocateUninitializedContextInstr::WillAllocateNewOrRemembered(
            num_context_variables);
  }

  if (add_to_remembered_set) {
    object->AddToRememberedSet(thread);
  }

  // For incremental write barrier elimination, we need to ensure that the
  // allocation ends up in the new space or else the object needs to added
  // to deferred marking stack so it will be [re]scanned.
  if (thread->is_marking()) {
    thread->DeferredMarkingStackAddObject(object);
  }

  return object;
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
  type =
      type.InstantiateFrom(instantiator_type_arguments, function_type_arguments,
                           kAllFree, NULL, Heap::kOld);
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

  ASSERT(!subtype.IsNull());
  ASSERT(!supertype.IsNull());

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

// Allocate a new SubtypeTestCache for use in interpreted implicit setters.
// Return value: newly allocated SubtypeTestCache.
DEFINE_RUNTIME_ENTRY(AllocateSubtypeTestCache, 0) {
  ASSERT(FLAG_enable_interpreter);
  arguments.SetReturn(SubtypeTestCache::Handle(zone, SubtypeTestCache::New()));
}

// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  const Smi& num_variables = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  const Context& context =
      Context::Handle(zone, Context::New(num_variables.Value()));
  arguments.SetReturn(context);
}

// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  const Context& ctx = Context::CheckedHandle(zone, arguments.ArgAt(0));
  Context& cloned_ctx =
      Context::Handle(zone, Context::New(ctx.num_variables()));
  cloned_ctx.set_parent(Context::Handle(zone, ctx.parent()));
  Object& inst = Object::Handle(zone);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  arguments.SetReturn(cloned_ctx);
}

// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void ThrowIfError(const Object& result) {
  if (!result.IsNull() && result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
}

// Invoke field getter before dispatch.
// Arg0: instance.
// Arg1: field name.
// Return value: field value.
DEFINE_RUNTIME_ENTRY(GetFieldForDispatch, 2) {
  ASSERT(FLAG_enable_interpreter);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const String& name = String::CheckedHandle(zone, arguments.ArgAt(1));
  const Class& receiver_class = Class::Handle(zone, receiver.clazz());
  const String& getter_name = String::Handle(zone, Field::GetterName(name));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(Array::Handle(
      zone, ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
  const Function& getter =
      Function::Handle(zone, Resolver::ResolveDynamicForReceiverClass(
                                 receiver_class, getter_name, args_desc));
  ASSERT(!getter.IsNull());  // An InvokeFieldDispatcher function was created.
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(getter, args));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Resolve 'call' function of receiver.
// Arg0: receiver (not a closure).
// Arg1: arguments descriptor
// Return value: 'call' function'.
DEFINE_RUNTIME_ENTRY(ResolveCallFunction, 2) {
  ASSERT(FLAG_enable_interpreter);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(1));
  ArgumentsDescriptor args_desc(descriptor);
  ASSERT(!receiver.IsClosure());  // Interpreter tests for closure.
  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& call_function = Function::Handle(zone);
  do {
    call_function = cls.LookupDynamicFunction(Symbols::Call());
    if (!call_function.IsNull()) {
      if (!call_function.AreValidArguments(args_desc, NULL)) {
        call_function = Function::null();
      }
      break;
    }
    cls = cls.SuperClass();
  } while (!cls.IsNull());
  arguments.SetReturn(call_function);
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
    const AbstractType& instantiated_type =
        AbstractType::Handle(type.InstantiateFrom(instantiator_type_arguments,
                                                  function_type_arguments,
                                                  kAllFree, NULL, Heap::kOld));
    OS::PrintErr("%s: '%s' %s '%s' instantiated from '%s' (pc: %#" Px ").\n",
                 message, String::Handle(instance_type.Name()).ToCString(),
                 (result.raw() == Bool::True().raw()) ? "is" : "is !",
                 String::Handle(instantiated_type.Name()).ToCString(),
                 String::Handle(type.Name()).ToCString(), caller_frame->pc());
  }
  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  OS::PrintErr(" -> Function %s\n", function.ToFullyQualifiedCString());
}

// This updates the type test cache, an array containing 5-value elements
// (instance class (or function if the instance is a closure), instance type
// arguments, instantiator type arguments, function type arguments,
// and test_result). It can be applied to classes with type arguments in which
// case it contains just the result of the class subtype test, not including the
// evaluation of type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
static void UpdateTypeTestCache(
    Zone* zone,
    const Instance& instance,
    const AbstractType& type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  // Since the test is expensive, don't do it unless necessary.
  // The list of disallowed cases will decrease as they are implemented in
  // inlined assembly.
  if (new_cache.IsNull()) {
    if (FLAG_trace_type_checks) {
      OS::PrintErr("UpdateTypeTestCache: cache is null\n");
    }
    return;
  }
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
  const intptr_t len = new_cache.NumberOfChecks();
  if (len >= FLAG_max_subtype_cache_entries) {
    return;
  }
#if defined(DEBUG)
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
  auto& last_instance_class_id_or_function = Object::Handle(zone);
  auto& last_instance_type_arguments = TypeArguments::Handle(zone);
  auto& last_instantiator_type_arguments = TypeArguments::Handle(zone);
  auto& last_function_type_arguments = TypeArguments::Handle(zone);
  auto& last_instance_parent_function_type_arguments =
      TypeArguments::Handle(zone);
  auto& last_instance_delayed_type_arguments = TypeArguments::Handle(zone);
  Bool& last_result = Bool::Handle(zone);
  for (intptr_t i = 0; i < len; ++i) {
    new_cache.GetCheck(
        i, &last_instance_class_id_or_function, &last_instance_type_arguments,
        &last_instantiator_type_arguments, &last_function_type_arguments,
        &last_instance_parent_function_type_arguments,
        &last_instance_delayed_type_arguments, &last_result);
    if ((last_instance_class_id_or_function.raw() ==
         instance_class_id_or_function.raw()) &&
        (last_instance_type_arguments.raw() == instance_type_arguments.raw()) &&
        (last_instantiator_type_arguments.raw() ==
         instantiator_type_arguments.raw()) &&
        (last_function_type_arguments.raw() == function_type_arguments.raw()) &&
        (last_instance_parent_function_type_arguments.raw() ==
         instance_parent_function_type_arguments.raw()) &&
        (last_instance_delayed_type_arguments.raw() ==
         instance_delayed_type_arguments.raw())) {
      OS::PrintErr("  Error in test cache %p ix: %" Pd ",", new_cache.raw(), i);
      PrintTypeCheck(" duplicate cache entry", instance, type,
                     instantiator_type_arguments, function_type_arguments,
                     result);
      UNREACHABLE();
      return;
    }
  }
#endif
  new_cache.AddCheck(instance_class_id_or_function, instance_type_arguments,
                     instantiator_type_arguments, function_type_arguments,
                     instance_parent_function_type_arguments,
                     instance_delayed_type_arguments, result);
  if (FLAG_trace_type_checks) {
    AbstractType& test_type = AbstractType::Handle(zone, type.raw());
    if (!test_type.IsInstantiated()) {
      test_type = type.InstantiateFrom(instantiator_type_arguments,
                                       function_type_arguments, kAllFree, NULL,
                                       Heap::kNew);
    }
    const auto& type_class = Class::Handle(zone, test_type.type_class());
    const auto& instance_class_name =
        String::Handle(zone, instance_class.Name());
    OS::PrintErr(
        "  Updated test cache %p ix: %" Pd
        " with "
        "(cid-or-fun: %p, type-args: %p, i-type-args: %p, f-type-args: %p, "
        "p-type-args: %p, d-type-args: %p, result: %s)\n"
        "    instance  [class: (%p '%s' cid: %" Pd
        "),    type-args: %p %s]\n"
        "    test-type [class: (%p '%s' cid: %" Pd
        "), i-type-args: %p %s, f-type-args: %p %s]\n",
        new_cache.raw(), len, instance_class_id_or_function.raw(),
        instance_type_arguments.raw(), instantiator_type_arguments.raw(),
        function_type_arguments.raw(),
        instance_parent_function_type_arguments.raw(),
        instance_delayed_type_arguments.raw(), result.ToCString(),
        instance_class.raw(), instance_class_name.ToCString(),
        instance_class.id(), instance_type_arguments.raw(),
        instance_type_arguments.ToCString(), type_class.raw(),
        String::Handle(zone, type_class.Name()).ToCString(), type_class.id(),
        instantiator_type_arguments.raw(),
        instantiator_type_arguments.ToCString(), function_type_arguments.raw(),
        function_type_arguments.ToCString());
  }
}

// Check that the given instance is an instance of the given type.
// Tested instance may not be null, because the null test is inlined.
// Arg0: instance being checked.
// Arg1: type.
// Arg2: type arguments of the instantiator of the type.
// Arg3: type arguments of the function of the type.
// Arg4: SubtypeTestCache.
// Return value: true or false, or may throw a type error in checked mode.
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
  const Bool& result = Bool::Get(instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments));
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf", instance, type, instantiator_type_arguments,
                   function_type_arguments, result);
  }
  UpdateTypeTestCache(zone, instance, type, instantiator_type_arguments,
                      function_type_arguments, result, cache);
  arguments.SetReturn(result);
}

// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
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

#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_DBC)
  ASSERT(mode == kTypeCheckFromInline);
#endif

  ASSERT(!dst_type.IsDynamicType());  // No need to check assignment.
  ASSERT(!src_instance.IsNull());     // Already checked in inlined code.

  const bool is_instance_of = src_instance.IsInstanceOf(
      dst_type, instantiator_type_arguments, function_type_arguments);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck", src_instance, dst_type,
                   instantiator_type_arguments, function_type_arguments,
                   Bool::Get(is_instance_of));
  }
  if (!is_instance_of) {
    // Throw a dynamic type error.
    const TokenPosition location = GetCallerLocation();
    const AbstractType& src_type =
        AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      dst_type = dst_type.InstantiateFrom(instantiator_type_arguments,
                                          function_type_arguments, kAllFree,
                                          NULL, Heap::kNew);
      // Note that instantiated dst_type may be malbounded.
    }
    if (dst_name.IsNull()) {
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub.
      ASSERT(mode != kTypeCheckFromInline);

      // Grab the [dst_name] from the pool.  It's stored at one pool slot after
      // the subtype-test-cache.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(!caller_frame->is_interpreted());
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

    Exceptions::CreateAndThrowTypeError(location, src_type, dst_type, dst_name);
    UNREACHABLE();
  }

  bool should_update_cache = true;
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32) &&                 \
    !defined(DART_PRECOMPILED_RUNTIME)
  if (mode == kTypeCheckFromLazySpecializeStub) {
    TypeTestingStubGenerator::SpecializeStubFor(thread, dst_type);
    // Only create the cache when we come from a normal stub.
    should_update_cache = false;
  }
#endif

  if (should_update_cache) {
    if (cache.IsNull()) {
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
      ASSERT(mode == kTypeCheckFromSlowStub);
      // We lazily create [SubtypeTestCache] for those call sites which actually
      // need one and will patch the pool entry.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(!caller_frame->is_interpreted());
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();

      // The pool entry must be initialized to `null` when we patch it.
      ASSERT(pool.ObjectAt(stc_pool_idx) == Object::null());
      cache = SubtypeTestCache::New();
      pool.SetObjectAt(stc_pool_idx, cache);
#else
      UNREACHABLE();
#endif
    }

    UpdateTypeTestCache(zone, src_instance, dst_type,
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

// Report that the type of the type check is malformed or malbounded.
// Arg0: src value.
// Arg1: name of destination being assigned to.
// Arg2: type of destination being assigned to.
// Return value: none, throws an exception.
DEFINE_RUNTIME_ENTRY(BadTypeError, 3) {
  const TokenPosition location = GetCallerLocation();
  const Instance& src_value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const String& dst_name = String::CheckedHandle(zone, arguments.ArgAt(1));
  const AbstractType& dst_type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(2));
  const AbstractType& src_type =
      AbstractType::Handle(zone, src_value.GetType(Heap::kNew));
  Exceptions::CreateAndThrowTypeError(location, src_type, dst_type, dst_name);
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
  ASSERT(!caller_frame->is_interpreted());
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
#elif !defined(TARGET_ARCH_DBC)
// Gets called from debug stub when code reaches a breakpoint
// set on a runtime stub call.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  Code& orig_stub = Code::Handle(zone);
  if (!caller_frame->is_interpreted()) {
    orig_stub = isolate->debugger()->GetPatchedStubAddress(caller_frame->pc());
  }
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseBreakpoint());
  ThrowIfError(error);
  arguments.SetReturn(orig_stub);
}
#else
// Gets called from the simulator when the breakpoint is reached.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  const Error& error = Error::Handle(isolate->debugger()->PauseBreakpoint());
  ThrowIfError(error);
}
#endif  // !defined(TARGET_ARCH_DBC)

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
static bool ResolveCallThroughGetter(const Instance& receiver,
                                     const Class& receiver_class,
                                     const String& target_name,
                                     const Array& arguments_descriptor,
                                     Function* result) {
  // 1. Check if there is a getter with the same name.
  const String& getter_name = String::Handle(Field::GetterName(target_name));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
  const Function& getter =
      Function::Handle(Resolver::ResolveDynamicForReceiverClass(
          receiver_class, getter_name, args_desc));
  if (getter.IsNull() || getter.IsMethodExtractor()) {
    return false;
  }
  const Function& target_function =
      Function::Handle(receiver_class.GetInvocationDispatcher(
          target_name, arguments_descriptor,
          RawFunction::kInvokeFieldDispatcher, FLAG_lazy_dispatchers));
  ASSERT(!target_function.IsNull() || !FLAG_lazy_dispatchers);
  if (FLAG_trace_ic) {
    OS::PrintErr(
        "InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        Class::Handle(receiver.clazz()).ToCString(), receiver.GetClassId(),
        target_function.IsNull() ? "null" : target_function.ToCString());
  }
  *result = target_function.raw();
  return true;
}

// Handle other invocations (implicit closures, noSuchMethod).
RawFunction* InlineCacheMissHelper(const Instance& receiver,
                                   const Array& args_descriptor,
                                   const String& target_name) {
  const Class& receiver_class = Class::Handle(receiver.clazz());

  // Handle noSuchMethod for dyn:methodName by getting a noSuchMethod dispatcher
  // (or a call-through getter for methodName).
  if (Function::IsDynamicInvocationForwarderName(target_name)) {
    const String& demangled = String::Handle(
        Function::DemangleDynamicInvocationForwarderName(target_name));
    return InlineCacheMissHelper(receiver, args_descriptor, demangled);
  }

  Function& result = Function::Handle();
  if (!ResolveCallThroughGetter(receiver, receiver_class, target_name,
                                args_descriptor, &result)) {
    ArgumentsDescriptor desc(args_descriptor);
    const Function& target_function =
        Function::Handle(receiver_class.GetInvocationDispatcher(
            target_name, args_descriptor, RawFunction::kNoSuchMethodDispatcher,
            FLAG_lazy_dispatchers));
    if (FLAG_trace_ic) {
      OS::PrintErr(
          "NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          Class::Handle(receiver.clazz()).ToCString(), receiver.GetClassId(),
          target_function.IsNull() ? "null" : target_function.ToCString());
    }
    result = target_function.raw();
  }
  // May be null if --no-lazy-dispatchers, in which case dispatch will be
  // handled by NoSuchMethodFromCallStub.
  ASSERT(!result.IsNull() || !FLAG_lazy_dispatchers);
  return result.raw();
}

static void TrySwitchInstanceCall(const ICData& ic_data,
                                  const Function& target_function) {
#if !defined(TARGET_ARCH_DBC) && !defined(DART_PRECOMPILED_RUNTIME)
  // Monomorphic/megamorphic calls only check the receiver CID.
  if (ic_data.NumArgsTested() != 1) return;

  ASSERT(ic_data.rebind_rule() == ICData::kInstance);

  // Monomorphic/megamorphic calls don't record exactness.
  if (ic_data.is_tracking_exactness()) return;

#if !defined(PRODUCT)
  // Monomorphic/megamorphic do not check the isolate's stepping flag.
  if (Isolate::Current()->has_attempted_stepping()) return;
#endif

  Thread* thread = Thread::Current();
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());

  // Monomorphic/megamorphic calls are only for unoptimized code.
  if (caller_frame->is_interpreted()) return;
  Zone* zone = thread->zone();
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  if (caller_code.is_optimized()) return;

  // Code is detached from its function. This will prevent us from resetting
  // the switchable call later because resets are function based and because
  // the ic_data_array belongs to the function instead of the code. This should
  // only happen because of reload, but it sometimes happens with KBC mixed mode
  // probably through a race between foreground and background compilation.
  const Function& caller_function =
      Function::Handle(zone, caller_code.function());
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
    if (target_function.HasOptionalParameters() ||
        target_function.IsGeneric()) {
      return;
    }

    // Avoid forcing foreground compilation if target function is still
    // interpreted.
    if (FLAG_enable_interpreter && !target_function.HasCode()) {
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

#endif  // !defined(TARGET_ARCH_DBC) && !defined(DART_PRECOMPILED_RUNTIME)
}

// Perform the subtype and return constant function based on the result.
static RawFunction* ComputeTypeCheckTarget(const Instance& receiver,
                                           const AbstractType& type,
                                           const ArgumentsDescriptor& desc) {
  bool result = receiver.IsInstanceOf(type, Object::null_type_arguments(),
                                      Object::null_type_arguments());
  ObjectStore* store = Isolate::Current()->object_store();
  const Function& target =
      Function::Handle(result ? store->simple_instance_of_true_function()
                              : store->simple_instance_of_false_function());
  ASSERT(!target.IsNull());
  return target.raw();
}

static RawFunction* InlineCacheMissHandler(
    const GrowableArray<const Instance*>& args,  // Checked arguments only.
    const ICData& ic_data,
    intptr_t count = 1) {
  const Instance& receiver = *args[0];
  ArgumentsDescriptor arguments_descriptor(
      Array::Handle(ic_data.arguments_descriptor()));
  String& function_name = String::Handle(ic_data.target_name());
  ASSERT(function_name.IsSymbol());

  Function& target_function = Function::Handle(
      Resolver::ResolveDynamic(receiver, function_name, arguments_descriptor));

  ObjectStore* store = Isolate::Current()->object_store();
  if (target_function.raw() == store->simple_instance_of_function()) {
    // Replace the target function with constant function.
    ASSERT(args.length() == 2);
    const AbstractType& type = AbstractType::Cast(*args[1]);
    target_function =
        ComputeTypeCheckTarget(receiver, type, arguments_descriptor);
  }
  if (target_function.IsNull()) {
    if (FLAG_trace_ic) {
      OS::PrintErr("InlineCacheMissHandler NULL function for %s receiver: %s\n",
                   String::Handle(ic_data.target_name()).ToCString(),
                   receiver.ToCString());
    }
    const Array& args_descriptor =
        Array::Handle(ic_data.arguments_descriptor());
    const String& target_name = String::Handle(ic_data.target_name());
    target_function =
        InlineCacheMissHelper(receiver, args_descriptor, target_name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
    return target_function.raw();
  }
  if (args.length() == 1) {
    if (ic_data.is_tracking_exactness()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
      const auto& receiver = *args[0];
      const auto state = receiver.IsNull()
                             ? StaticTypeExactnessState::NotExact()
                             : StaticTypeExactnessState::Compute(
                                   Type::Cast(AbstractType::Handle(
                                       ic_data.receivers_static_type())),
                                   receiver);
      ic_data.AddReceiverCheck(
          receiver.GetClassId(), target_function, count,
          /*exactness=*/state.CollapseSuperTypeExactness());
#else
      UNREACHABLE();
#endif
    } else {
      ic_data.AddReceiverCheck(args[0]->GetClassId(), target_function, count);
    }
  } else {
    GrowableArray<intptr_t> class_ids(args.length());
    ASSERT(ic_data.NumArgsTested() == args.length());
    for (intptr_t i = 0; i < args.length(); i++) {
      class_ids.Add(args[i]->GetClassId());
    }
    ic_data.AddCheck(class_ids, target_function, count);
  }
  if (FLAG_trace_ic_miss_in_optimized || FLAG_trace_ic) {
    DartFrameIterator iterator(Thread::Current(),
                               StackFrameIterator::kNoCrossThreadIteration);
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
      OS::PrintErr("InlineCacheMissHandler %" Pd " call at %#" Px
                   "' "
                   "adding <%s> id:%" Pd " -> <%s>\n",
                   args.length(), caller_frame->pc(),
                   Class::Handle(receiver.clazz()).ToCString(),
                   receiver.GetClassId(), target_function.ToCString());
    }
  }

  TrySwitchInstanceCall(ic_data, target_function);

  return target_function.raw();
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
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
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& other = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  GrowableArray<const Instance*> args(2);
  args.Add(&receiver);
  args.Add(&other);
  const Function& result =
      Function::Handle(InlineCacheMissHandler(args, ic_data));
  arguments.SetReturn(result);
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
  const Function& target = Function::Handle(ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  ASSERT(!target.IsNull() && target.HasCode());
  ic_data.AddReceiverCheck(arg.GetClassId(), target, 1);
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
  const Function& target = Function::Handle(ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  GrowableArray<intptr_t> cids(2);
  cids.Add(arg0.GetClassId());
  cids.Add(arg1.GetClassId());
  ic_data.AddCheck(cids, target);
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

#if !defined(TARGET_ARCH_DBC)
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
    other_target =
        Resolver::ResolveDynamicAnyArgs(zone, cls, name, false /* allow_add */);
    if (other_target.raw() != target.raw()) {
      return false;
    }
  }
  return true;
}
#endif

// Handle a miss of a single target cache.
//   Arg1: Receiver.
//   Arg0: Stub out.
//   Returns: the ICData used to continue with a polymorphic call.
DEFINE_RUNTIME_ENTRY(SingleTargetMiss, 2) {
#if defined(TARGET_ARCH_DBC)
  // DBC does not use switchable calls.
  UNREACHABLE();
#else
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  SingleTargetCache& cache = SingleTargetCache::Handle(zone);
  cache ^=
      CodePatcher::GetSwitchableCallDataAt(caller_frame->pc(), caller_code);
  Code& old_target_code = Code::Handle(zone, cache.target());
  Function& old_target = Function::Handle(zone);
  old_target ^= old_target_code.owner();

  // We lost the original ICData when we patched to the monomorphic case.
  const String& name = String::Handle(zone, old_target.name());
  ASSERT(!old_target.HasOptionalParameters());
  ASSERT(!old_target.IsGeneric());
  const int kTypeArgsLen = 0;
  const Array& descriptor =
      Array::Handle(zone, ArgumentsDescriptor::New(
                              kTypeArgsLen, old_target.num_fixed_parameters()));
  const ICData& ic_data =
      ICData::Handle(zone, ICData::New(caller_function, name, descriptor,
                                       DeoptId::kNone, 1, /* args_tested */
                                       ICData::kInstance));

  // Maybe add the new target.
  Class& cls = Class::Handle(zone, receiver.clazz());
  ArgumentsDescriptor args_desc(descriptor);
  Function& target_function = Function::Handle(
      zone, Resolver::ResolveDynamicForReceiverClass(cls, name, args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
  } else {
    ic_data.AddReceiverCheck(receiver.GetClassId(), target_function);
  }

  if (old_target.raw() == target_function.raw()) {
    intptr_t lower, upper, unchecked_lower, unchecked_upper;
    if (receiver.GetClassId() < cache.lower_limit()) {
      lower = receiver.GetClassId();
      unchecked_lower = receiver.GetClassId();
      upper = cache.upper_limit();
      unchecked_upper = cache.lower_limit() - 1;
    } else {
      lower = cache.lower_limit();
      unchecked_lower = cache.upper_limit() + 1;
      upper = receiver.GetClassId();
      unchecked_upper = receiver.GetClassId();
    }

    if (IsSingleTarget(isolate, zone, unchecked_lower, unchecked_upper,
                       target_function, name)) {
      cache.set_lower_limit(lower);
      cache.set_upper_limit(upper);
      // Return the ICData. The single target stub will jump to continue in the
      // IC call stub.
      arguments.SetArgAt(0, StubCode::ICCallThroughCode());
      arguments.SetReturn(ic_data);
      return;
    }
  }

  // Call site is not single target, switch to call using ICData.
  const Code& stub = StubCode::ICCallThroughCode();
  ASSERT(!Isolate::Current()->compilation_allowed());
  CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code, ic_data,
                                     stub);

  // Return the ICData. The single target stub will jump to continue in the
  // IC call stub.
  arguments.SetArgAt(0, stub);
  arguments.SetReturn(ic_data);
#endif
}

// Handle the first use of an instance call
//   Arg2: UnlinkedCall.
//   Arg1: Receiver.
//   Arg0: Stub out.
//   Returns: the ICData used to continue with a polymorphic call.
DEFINE_RUNTIME_ENTRY(UnlinkedCall, 3) {
#if defined(TARGET_ARCH_DBC)
  // DBC does not use switchable calls.
  UNREACHABLE();
#else
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const UnlinkedCall& unlinked =
      UnlinkedCall::CheckedHandle(zone, arguments.ArgAt(2));

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  const String& name = String::Handle(zone, unlinked.target_name());
  const Array& descriptor = Array::Handle(zone, unlinked.args_descriptor());
  const ICData& ic_data =
      ICData::Handle(zone, ICData::New(caller_function, name, descriptor,
                                       DeoptId::kNone, 1, /* args_tested */
                                       ICData::kInstance));

  Class& cls = Class::Handle(zone, receiver.clazz());
  ArgumentsDescriptor args_desc(descriptor);
  Function& target_function = Function::Handle(
      zone, Resolver::ResolveDynamicForReceiverClass(cls, name, args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
  } else {
    ic_data.AddReceiverCheck(receiver.GetClassId(), target_function);
  }

  if (!target_function.IsNull() && !target_function.HasOptionalParameters() &&
      !target_function.IsGeneric()) {
    // Patch to monomorphic call.
    ASSERT(target_function.HasCode());
    const Code& target_code = Code::Handle(zone, target_function.CurrentCode());
    const Smi& expected_cid =
        Smi::Handle(zone, Smi::New(receiver.GetClassId()));
    CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code,
                                       expected_cid, target_code);

    // Return the ICData. The miss stub will jump to continue in the IC call
    // stub.
    arguments.SetArgAt(0, StubCode::ICCallThroughCode());
    arguments.SetReturn(ic_data);
    return;
  }

  // Patch to call through stub.
  const Code& stub = StubCode::ICCallThroughCode();
  ASSERT(!Isolate::Current()->compilation_allowed());
  CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code, ic_data,
                                     stub);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  arguments.SetArgAt(0, stub);
  arguments.SetReturn(ic_data);
#endif  // !DBC
}

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_ARCH_DBC)
static RawICData* FindICDataForInstanceCall(Zone* zone,
                                            const Code& code,
                                            uword pc) {
  uword pc_offset = pc - code.PayloadStart();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone, code.pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kIcCall);
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_ARCH_DBC)

// Handle a miss of a megamorphic cache.
//   Arg1: Receiver.
//   Arg0: continuation Code (out parameter).
//   Returns: the ICData used to continue with a polymorphic call.
DEFINE_RUNTIME_ENTRY(MonomorphicMiss, 2) {
#if defined(TARGET_ARCH_DBC)
  // DBC does not use switchable calls.
  UNREACHABLE();
#elif defined(DART_PRECOMPILED_RUNTIME)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  Smi& old_expected_cid = Smi::Handle(zone);
  old_expected_cid ^=
      CodePatcher::GetSwitchableCallDataAt(caller_frame->pc(), caller_code);
  const Code& old_target_code = Code::Handle(
      CodePatcher::GetSwitchableCallTargetAt(caller_frame->pc(), caller_code));
  Function& old_target = Function::Handle(zone);
  old_target ^= old_target_code.owner();

  // We lost the original ICData when we patched to the monomorphic case.
  const String& name = String::Handle(zone, old_target.name());
  ASSERT(!old_target.HasOptionalParameters());
  const int kTypeArgsLen = 0;
  const Array& descriptor =
      Array::Handle(zone, ArgumentsDescriptor::New(
                              kTypeArgsLen, old_target.num_fixed_parameters()));
  const ICData& ic_data =
      ICData::Handle(zone, ICData::New(caller_function, name, descriptor,
                                       DeoptId::kNone, 1, /* args_tested */
                                       ICData::kInstance));

  // Add the first target.
  ic_data.AddReceiverCheck(old_expected_cid.Value(), old_target);

  // Maybe add the new target.
  Class& cls = Class::Handle(zone, receiver.clazz());
  ArgumentsDescriptor args_desc(descriptor);
  Function& target_function = Function::Handle(
      zone, Resolver::ResolveDynamicForReceiverClass(cls, name, args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
  } else {
    ic_data.AddReceiverCheck(receiver.GetClassId(), target_function);
  }

  if (old_target.raw() == target_function.raw()) {
    intptr_t lower, upper;
    if (old_expected_cid.Value() < receiver.GetClassId()) {
      lower = old_expected_cid.Value();
      upper = receiver.GetClassId();
    } else {
      lower = receiver.GetClassId();
      upper = old_expected_cid.Value();
    }

    if (IsSingleTarget(isolate, zone, lower, upper, target_function, name)) {
      const SingleTargetCache& cache =
          SingleTargetCache::Handle(SingleTargetCache::New());
      const Code& code = Code::Handle(target_function.CurrentCode());
      cache.set_target(code);
      cache.set_entry_point(code.EntryPoint());
      cache.set_lower_limit(lower);
      cache.set_upper_limit(upper);
      const Code& stub = StubCode::SingleTargetCall();
      CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code, cache,
                                         stub);
      // Return the ICData. The miss stub will jump to continue in the IC call
      // stub.
      arguments.SetArgAt(0, StubCode::ICCallThroughCode());
      arguments.SetReturn(ic_data);
      return;
    }
  }

  // Patch to call through stub.
  const Code& stub = StubCode::ICCallThroughCode();
  ASSERT(!Isolate::Current()->compilation_allowed());
  CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code, ic_data,
                                     stub);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  arguments.SetArgAt(0, stub);
  arguments.SetReturn(ic_data);
#else   // JIT
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  ASSERT(!caller_frame->is_interpreted());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  ASSERT(!caller_code.is_optimized());

  const ICData& ic_data = ICData::Handle(
      zone, FindICDataForInstanceCall(zone, caller_code, caller_frame->pc()));
  RELEASE_ASSERT(!ic_data.IsNull());

  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& stub = ic_data.is_tracking_exactness()
                         ? StubCode::OneArgCheckInlineCacheWithExactnessCheck()
                         : StubCode::OneArgCheckInlineCache();
  CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, ic_data,
                                   stub);
  if (FLAG_trace_ic) {
    OS::PrintErr("Instance call at %" Px
                 " switching to polymorphic dispatch, %s\n",
                 caller_frame->pc(), ic_data.ToCString());
  }

  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  // ICData can be shared between unoptimized and optimized code, so beware that
  // the new receiver class may have already been added through the optimized
  // code.
  if (!ic_data.HasReceiverClassId(receiver.GetClassId())) {
    GrowableArray<const Instance*> args(1);
    args.Add(&receiver);
    // Don't count during insertion because the IC stub we continue through will
    // do an increment.
    intptr_t count = 0;
    InlineCacheMissHandler(args, ic_data, count);
  }
  arguments.SetArgAt(0, stub);
  arguments.SetReturn(ic_data);
#endif  // !defined(TARGET_ARCH_DBC)
}

// Handle a miss of a megamorphic cache.
//   Arg0: Receiver.
//   Arg1: ICData or MegamorphicCache.
//   Arg2: Arguments descriptor array.
//   Returns: target function to call.
DEFINE_RUNTIME_ENTRY(MegamorphicCacheMissHandler, 3) {
#if defined(TARGET_ARCH_DBC)
  // DBC does not use megamorphic calls right now.
  UNREACHABLE();
#else
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
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic IC miss (%s), class=%s, function<%" Pd ">=%s\n",
                 ic_data_or_cache.IsICData() ? "icdata" : "cache",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }
  Function& target_function = Function::Handle(
      zone, Resolver::ResolveDynamicForReceiverClass(cls, name, args_desc));
  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, descriptor, name);
    if (target_function.IsNull()) {
      ASSERT(!FLAG_lazy_dispatchers);
      arguments.SetReturn(target_function);
      return;
    }
  }

  if (ic_data_or_cache.IsICData()) {
    const ICData& ic_data = ICData::Cast(ic_data_or_cache);
    const intptr_t number_of_checks = ic_data.NumberOfChecks();

    if ((number_of_checks == 0) && !target_function.HasOptionalParameters() &&
        !target_function.IsGeneric() &&
        !Isolate::Current()->compilation_allowed()) {
      // This call site is unlinked: transition to a monomorphic direct call.
      // Note we cannot do this if the target has optional parameters because
      // the monomorphic direct call does not load the arguments descriptor.
      // We cannot do this if we are still in the middle of precompiling because
      // the monomorphic case hides a live instance selector from the
      // treeshaker.

      const Code& target_code =
          Code::Handle(zone, target_function.EnsureHasCode());

      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* miss_function_frame = iterator.NextFrame();
      ASSERT(miss_function_frame->IsDartFrame());
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(caller_frame->IsDartFrame());
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const Smi& expected_cid =
          Smi::Handle(zone, Smi::New(receiver.GetClassId()));

      CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code,
                                         expected_cid, target_code);
    } else {
      ic_data.AddReceiverCheck(receiver.GetClassId(), target_function);
      if (number_of_checks > FLAG_max_polymorphic_checks) {
        // Switch to megamorphic call.
        const MegamorphicCache& cache = MegamorphicCache::Handle(
            zone, MegamorphicCacheTable::Lookup(thread, name, descriptor));
        DartFrameIterator iterator(thread,
                                   StackFrameIterator::kNoCrossThreadIteration);
        StackFrame* miss_function_frame = iterator.NextFrame();
        ASSERT(miss_function_frame->IsDartFrame());
        StackFrame* caller_frame = iterator.NextFrame();
        ASSERT(caller_frame->IsDartFrame());
        const Code& caller_code =
            Code::Handle(zone, caller_frame->LookupDartCode());
        const Code& stub = StubCode::MegamorphicCall();

        CodePatcher::PatchSwitchableCallAt(caller_frame->pc(), caller_code,
                                           cache, stub);
      }
    }
  } else {
    const MegamorphicCache& cache = MegamorphicCache::Cast(ic_data_or_cache);
    // Insert function found into cache and return it.
    const Smi& class_id = Smi::Handle(zone, Smi::New(cls.id()));
    cache.Insert(class_id, target_function);
  }
  arguments.SetReturn(target_function);
#endif  // !defined(TARGET_ARCH_DBC)
}

// Handles interpreted interface call cache miss.
//   Arg0: receiver
//   Arg1: target name
//   Arg2: arguments descriptor
//   Returns: target function
// Modifies the instance call table in current interpreter.
DEFINE_RUNTIME_ENTRY(InterpretedInstanceCallMissHandler, 3) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(FLAG_enable_interpreter);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const String& target_name = String::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& arg_desc = Array::CheckedHandle(zone, arguments.ArgAt(2));

  ArgumentsDescriptor arguments_descriptor(arg_desc);
  Function& target_function = Function::Handle(
      zone,
      Resolver::ResolveDynamic(receiver, target_name, arguments_descriptor));

  // TODO(regis): In order to substitute 'simple_instance_of_function', the 2nd
  // arg to the call, the type, is needed.

  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver, arg_desc, target_name);
  }
  ASSERT(!target_function.IsNull());
  arguments.SetReturn(target_function);
#endif
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

  if (Function::IsDynamicInvocationForwarderName(target_name)) {
    target_name = Function::DemangleDynamicInvocationForwarderName(target_name);
  }

  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& function = Function::Handle(zone);

  // Dart distinguishes getters and regular methods and allows their calls
  // to mix with conversions, and its selectors are independent of arity. So do
  // a zigzagged lookup to see if this call failed because of an arity mismatch,
  // need for conversion, or there really is no such method.

#define NO_SUCH_METHOD()                                                       \
  const Object& result = Object::Handle(                                       \
      zone, DartEntry::InvokeNoSuchMethod(                                     \
                receiver, target_name, orig_arguments, orig_arguments_desc));  \
  ThrowIfError(result);                                                        \
  arguments.SetReturn(result);

#define CLOSURIZE(some_function)                                               \
  const Function& closure_function =                                           \
      Function::Handle(zone, some_function.ImplicitClosureFunction());         \
  const Object& result = Object::Handle(                                       \
      zone, closure_function.ImplicitInstanceClosure(receiver));               \
  arguments.SetReturn(result);

  const bool is_getter = Field::IsGetterName(target_name);
  if (is_getter) {
    // o.foo (o.get:foo) failed, closurize o.foo() if it exists.
    String& field_name =
        String::Handle(zone, Field::NameFromGetter(target_name));
    while (!cls.IsNull()) {
      function = cls.LookupDynamicFunction(field_name);
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
      const Object& result = Object::Handle(
          zone, DartEntry::InvokeClosure(orig_arguments, orig_arguments_desc));
      ThrowIfError(result);
      arguments.SetReturn(result);
      return;
    }

    const String& getter_name =
        String::Handle(zone, Field::GetterName(target_name));
    ArgumentsDescriptor args_desc(orig_arguments_desc);
    while (!cls.IsNull()) {
      function = cls.LookupDynamicFunction(target_name);
      if (!function.IsNull()) {
        ASSERT(!function.AreValidArguments(args_desc, NULL));
        break;  // mismatch, invoke noSuchMethod
      }
      function = cls.LookupDynamicFunction(getter_name);
      if (!function.IsNull()) {
        const Array& getter_arguments = Array::Handle(Array::New(1));
        getter_arguments.SetAt(0, receiver);
        const Object& getter_result = Object::Handle(
            zone, DartEntry::InvokeFunction(function, getter_arguments));
        ThrowIfError(getter_result);
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());

        orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
        const Object& call_result = Object::Handle(
            zone,
            DartEntry::InvokeClosure(orig_arguments, orig_arguments_desc));
        ThrowIfError(call_result);
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
  if ((function.kind() == RawFunction::kClosureFunction) ||
      (function.kind() == RawFunction::kImplicitClosureFunction)) {
    // For closure the function name is always 'call'. Replace it with the
    // name of the closurized function so that exception contains more
    // relevant information.
    orig_function_name = function.QualifiedUserVisibleName();
  } else {
    orig_function_name = function.name();
  }

  const Object& result = Object::Handle(
      zone, DartEntry::InvokeNoSuchMethod(receiver, orig_function_name,
                                          orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Invoke appropriate noSuchMethod function.
// Arg0: receiver
// Arg1: arguments descriptor array.
// Arg2: arguments array.
// Arg3: function name.
DEFINE_RUNTIME_ENTRY(InvokeNoSuchMethod, 4) {
  ASSERT(FLAG_enable_interpreter);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(2));
  const String& original_function_name =
      String::CheckedHandle(zone, arguments.ArgAt(3));

  const Object& result = Object::Handle(DartEntry::InvokeNoSuchMethod(
      receiver, original_function_name, orig_arguments, orig_arguments_desc));
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
    if (!Isolate::IsVMInternalIsolate(isolate)) {
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
  if (FLAG_deoptimize_filter != nullptr || FLAG_stacktrace_filter != nullptr ||
      (FLAG_reload_every != 0)) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
    Code& code = Code::Handle();
    Function& function = Function::Handle();
    if (frame->is_interpreted()) {
      function = frame->LookupDartFunction();
    } else {
      code = frame->LookupDartCode();
      ASSERT(!code.IsNull());
      function = code.function();
    }
    ASSERT(!function.IsNull());
    const char* function_name = function.ToFullyQualifiedCString();
    ASSERT(function_name != nullptr);
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
      const Function& func = Function::Handle(cls.LookupFunction(
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
    bool success =
        isolate->ReloadSources(&js, true /* force_reload */, script_uri);
    if (!success) {
      FATAL1("*** Isolate reload failed:\n%s\n", js.ToCString());
    }
  }
  if (do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    // Collecting the stack trace and accessing local variables
    // of frames may trigger parsing of functions to compute
    // variable descriptors of functions. Parsing may trigger
    // code execution, e.g. to compute compile-time constants. Thus,
    // disable FLAG_stacktrace_every during trace collection to prevent
    // recursive stack trace collection.
    intptr_t saved_stacktrace_every = FLAG_stacktrace_every;
    FLAG_stacktrace_every = 0;
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      int num_vars = 0;
      // Variable locations and number are unknown when precompiling.
#if !defined(DART_PRECOMPILED_RUNTIME)
      // NumLocalVariables() can call EnsureHasUnoptimizedCode() for
      // non-interpreted functions.
      if (!frame->function().ForceOptimize()) {
        if (!frame->IsInterpreted()) {
          // Ensure that we have unoptimized code.
          frame->function().EnsureHasCompiledUnoptimizedCode();
        }
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
    FLAG_stacktrace_every = saved_stacktrace_every;
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
    uword optimized_entry = Instructions::EntryPoint(code.instructions());
    frame->set_pc(optimized_entry);
    frame->set_pc_marker(code.raw());
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_RUNTIME_ENTRY(StackOverflow, 0) {
#if defined(USING_SIMULATOR)
  uword stack_pos = Simulator::Current()->get_sp();
  // If simulator was never called (for example, in pure
  // interpreted mode) it may return 0 as a value of SPREG.
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

  bool interpreter_stack_overflow = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_enable_interpreter) {
    // Do not allocate an interpreter, if none is allocated yet.
    Interpreter* interpreter = thread->interpreter();
    if (interpreter != NULL) {
      interpreter_stack_overflow =
          interpreter->get_sp() >= interpreter->overflow_stack_limit();
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow now and leave the interrupt for next
  // time.
  // TODO(regis): Warning: IsCalleeFrameOf is overridden in stack_frame_dbc.h.
  if (interpreter_stack_overflow || !thread->os_thread()->HasStackHeadroom() ||
      IsCalleeFrameOf(thread->saved_stack_limit(), stack_pos)) {
    if (FLAG_verbose_stack_overflow) {
      OS::PrintErr("Stack overflow in %s\n",
                   interpreter_stack_overflow ? "interpreter" : "native code");
      OS::PrintErr("  Native SP = %" Px ", stack limit = %" Px "\n", stack_pos,
                   thread->saved_stack_limit());
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (thread->interpreter() != nullptr) {
        OS::PrintErr("  Interpreter SP = %" Px ", stack limit = %" Px "\n",
                     thread->interpreter()->get_sp(),
                     thread->interpreter()->overflow_stack_limit());
      }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

      OS::PrintErr("Call stack:\n");
      OS::PrintErr("size | frame\n");
      StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                                StackFrameIterator::kNoCrossThreadIteration);
      uword fp = stack_pos;
      StackFrame* frame = frames.NextFrame();
      while (frame != NULL) {
        if (frame->is_interpreted() == interpreter_stack_overflow) {
          uword delta = interpreter_stack_overflow ? (fp - frame->fp())
                                                   : (frame->fp() - fp);
          fp = frame->fp();
          OS::PrintErr("%4" Pd " %s\n", delta, frame->ToCString());
        } else {
          OS::PrintErr("     %s\n", frame->ToCString());
        }
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
  OS::PrintErr("IC call @%#" Px ": ICData: %p cnt:%" Pd " nchecks: %" Pd
               " %s\n",
               frame->pc(), ic_data.raw(), function.usage_counter(),
               ic_data.NumberOfChecks(), function.ToFullyQualifiedCString());
}

// This is called from interpreter when function usage counter reached
// compilation threshold and function needs to be compiled.
DEFINE_RUNTIME_ENTRY(CompileInterpretedFunction, 1) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(FLAG_enable_interpreter);

#if !defined(PRODUCT)
  if (Debugger::IsDebugging(thread, function)) {
    return;
  }
#endif  // !defined(PRODUCT)

  if (FLAG_background_compilation) {
    if (!BackgroundCompiler::IsDisabled(isolate,
                                        /* optimizing_compilation = */ false) &&
        function.is_background_optimizable()) {
      // Ensure background compiler is running, if not start it.
      BackgroundCompiler::Start(isolate);
      // Reduce the chance of triggering a compilation while the function is
      // being compiled in the background. INT_MIN should ensure that it
      // takes long time to trigger a compilation.
      // Note that the background compilation queue rejects duplicate entries.
      function.SetUsageCounter(INT_MIN);
      isolate->background_compiler()->Compile(function);
      return;
    }
  }

  // Reset usage counter for future optimization.
  function.SetUsageCounter(0);
  Object& result =
      Object::Handle(zone, Compiler::CompileFunction(thread, function));
  ThrowIfError(result);
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
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
      if (!BackgroundCompiler::IsDisabled(isolate,
                                          /* optimizing_compiler = */ true) &&
          function.is_background_optimizable()) {
        // Ensure background compiler is running, if not start it.
        BackgroundCompiler::Start(isolate);
        // Reduce the chance of triggering a compilation while the function is
        // being compiled in the background. INT_MIN should ensure that it
        // takes long time to trigger a compilation.
        // Note that the background compilation queue rejects duplicate entries.
        function.SetUsageCounter(INT_MIN);
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

#if defined(TARGET_ARCH_DBC)
  const Instructions& instrs =
      Instructions::Handle(zone, optimized_code.instructions());
  {
    WritableInstructionsScope writable(instrs.PayloadStart(), instrs.Size());
    CodePatcher::InsertDeoptimizationCallAt(frame->pc());
    if (FLAG_trace_patching) {
      const String& name = String::Handle(function.name());
      OS::PrintErr("InsertDeoptimizationCallAt: 0x%" Px " for %s\n",
                   frame->pc(), name.ToCString());
    }
    const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(zone, optimized_code.exception_handlers());
    ExceptionHandlerInfo info;
    for (intptr_t i = 0; i < handlers.num_entries(); ++i) {
      handlers.GetHandlerInfo(i, &info);
      const uword patch_pc = instrs.PayloadStart() + info.handler_pc_offset;
      CodePatcher::InsertDeoptimizationCallAt(patch_pc);
      if (FLAG_trace_patching) {
        OS::PrintErr("  at handler 0x%" Px "\n", patch_pc);
      }
    }
  }
#else  // !DBC
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
    ASSERT(!frame->is_interpreted());
    thread->isolate()->AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for fp=%" Pp ", pc=%" Pp "\n",
                frame->fp(), deopt_pc);
    }
  }
#endif  // !DBC

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
    if (!frame->is_interpreted()) {
      optimized_code = frame->LookupDartCode();
      if (optimized_code.is_optimized() &&
          !optimized_code.is_force_optimized()) {
        DeoptimizeAt(optimized_code, frame);
      }
    }
    frame = iterator.NextFrame();
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(TARGET_ARCH_DBC)
static const intptr_t kNumberOfSavedCpuRegisters = kNumberOfCpuRegisters;
static const intptr_t kNumberOfSavedFpuRegisters = kNumberOfFpuRegisters;
#else
static const intptr_t kNumberOfSavedCpuRegisters = 0;
static const intptr_t kNumberOfSavedFpuRegisters = 0;
#endif

static void CopySavedRegisters(uword saved_registers_address,
                               fpu_register_t** fpu_registers,
                               intptr_t** cpu_registers) {
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

#if !defined(TARGET_ARCH_DBC)
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
#endif  // !DBC

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

DEFINE_RUNTIME_ENTRY(InitStaticField, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  const Error& result = Error::Handle(zone, field.Initialize());
  ThrowIfError(result);
}

// Print the stop message.
DEFINE_LEAF_RUNTIME_ENTRY(void, PrintStopMessage, 1, const char* message) {
  OS::PrintErr("Stop message: %s\n", message);
}
END_LEAF_RUNTIME_ENTRY

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

uword RuntimeEntry::InterpretCallEntry() {
  uword entry = reinterpret_cast<uword>(RuntimeEntry::InterpretCall);
#if defined(USING_SIMULATOR) && !defined(TARGET_ARCH_DBC)
  // DBC does not use redirections unlike other simulators.
  entry = Simulator::RedirectExternalReference(entry,
                                               Simulator::kLeafRuntimeCall, 5);
#endif
  return entry;
}

// Interpret a function call. Should be called only for non-jitted functions.
// argc indicates the number of arguments, including the type arguments.
// argv points to the first argument.
// If argc < 0, arguments are passed at decreasing memory addresses from argv.
RawObject* RuntimeEntry::InterpretCall(RawFunction* function,
                                       RawArray* argdesc,
                                       intptr_t argc,
                                       RawObject** argv,
                                       Thread* thread) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(FLAG_enable_interpreter);
  Interpreter* interpreter = Interpreter::Current();
#if defined(DEBUG)
  uword exit_fp = thread->top_exit_frame_info();
  ASSERT(exit_fp != 0);
  ASSERT(thread == Thread::Current());
  // Caller is InterpretCall stub called from generated code.
  // We stay in "in generated code" execution state when interpreting code.
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
  ASSERT(!Function::HasCode(function));
  ASSERT(Function::HasBytecode(function));
  ASSERT(interpreter != NULL);
#endif
  RawObject* result = interpreter->Call(function, argdesc, argc, argv, thread);
  DEBUG_ASSERT(thread->top_exit_frame_info() == exit_fp);
  if (RawObject::IsErrorClassId(result->GetClassIdMayBeSmi())) {
    // Must not leak handles in the caller's zone.
    HANDLESCOPE(thread);
    // Protect the result in a handle before transitioning, which may trigger
    // GC.
    const Error& error = Error::Handle(Error::RawCast(result));
    // Propagating an error may cause allocation. Check if we need to block for
    // a safepoint by switching to "in VM" execution state.
    TransitionGeneratedToVM transition(thread);
    Exceptions::PropagateError(error);
  }
  return result;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

extern "C" void DFLRT_EnterSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);
  ASSERT(thread->execution_state() == Thread::kThreadInNative);
  thread->EnterSafepoint();
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(EnterSafepoint, 0, false, &DFLRT_EnterSafepoint);

extern "C" void DFLRT_ExitSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);

  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  thread->ExitSafepoint();
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
#if defined(HOST_OS_WINDOWS)
  void* return_address = _ReturnAddress();
#else
  void* return_address = __builtin_return_address(0);
#endif
  return GetThreadForNativeCallback(callback_id,
                                    reinterpret_cast<uword>(return_address));
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

}  // namespace dart
