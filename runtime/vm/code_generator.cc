// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_generator.h"

#include "vm/assembler_macros.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/verifier.h"

namespace dart {

DEFINE_FLAG(bool, inline_cache, true, "enable inline caches");
DEFINE_FLAG(bool, trace_deopt, false, "Trace deoptimization");
DEFINE_FLAG(bool, trace_ic, false, "trace IC handling");
DEFINE_FLAG(bool, trace_patching, false, "Trace patching of code.");
DEFINE_FLAG(bool, trace_runtime_calls, false, "Trace runtime calls.");
DEFINE_FLAG(int, optimization_counter_threshold, 2000,
    "function's usage-counter value before it is optimized, -1 means never.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, trace_type_checks);
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(int, deoptimization_counter_threshold);
DEFINE_FLAG(charp, optimization_filter, NULL, "Optimize only named function");


bool CodeGenerator::CanOptimize() {
  return
      !FLAG_report_usage_count &&
      (FLAG_optimization_counter_threshold >= 0) &&
      !Isolate::Current()->debugger()->IsActive();
}


const Array& CodeGenerator::ArgumentsDescriptor(
    int num_arguments,
    const Array& optional_arguments_names) {
  const intptr_t num_named_args =
      optional_arguments_names.IsNull() ? 0 : optional_arguments_names.Length();
  const intptr_t num_pos_args = num_arguments - num_named_args;

  // Build the argument descriptor array, which consists of the total number of
  // arguments, the number of positional arguments, alphabetically sorted
  // pairs of name/position, and a terminating null.
  const int descriptor_len = 3 + (2 * num_named_args);
  Array& descriptor = Array::ZoneHandle(Array::New(descriptor_len, Heap::kOld));

  // Set total number of passed arguments.
  descriptor.SetAt(0, Smi::Handle(Smi::New(num_arguments)));
  // Set number of positional arguments.
  descriptor.SetAt(1, Smi::Handle(Smi::New(num_pos_args)));
  // Set alphabetically sorted pairs of name/position for named arguments.
  String& name = String::Handle();
  Smi& pos = Smi::Handle();
  for (int i = 0; i < num_named_args; i++) {
    name ^= optional_arguments_names.At(i);
    pos = Smi::New(num_pos_args + i);
    int j = i;
    // Shift already inserted pairs with "larger" names.
    String& name_j = String::Handle();
    Smi& pos_j = Smi::Handle();
    while (--j >= 0) {
      name_j ^= descriptor.At(2 + (2 * j));
      const intptr_t result = name.CompareTo(name_j);
      ASSERT(result != 0);  // Duplicate argument names checked in parser.
      if (result > 0) break;
      pos_j ^= descriptor.At(3 + (2 * j));
      descriptor.SetAt(2 + (2 * (j + 1)), name_j);
      descriptor.SetAt(3 + (2 * (j + 1)), pos_j);
    }
    // Insert pair in descriptor array.
    descriptor.SetAt(2 + (2 * (j + 1)), name);
    descriptor.SetAt(3 + (2 * (j + 1)), pos);
  }
  // Set terminating null.
  descriptor.SetAt(descriptor_len - 1, Object::Handle());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  descriptor ^= descriptor.Canonicalize();
  return descriptor;
}


DEFINE_RUNTIME_ENTRY(TraceFunctionEntry, 1) {
  ASSERT(arguments.Count() == kTraceFunctionEntryRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  const String& function_name = String::Handle(function.name());
  const String& class_name =
      String::Handle(Class::Handle(function.owner()).Name());
  OS::Print("> Entering '%s.%s'\n",
      class_name.ToCString(), function_name.ToCString());
}


DEFINE_RUNTIME_ENTRY(TraceFunctionExit, 1) {
  ASSERT(arguments.Count() == kTraceFunctionExitRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  const String& function_name = String::Handle(function.name());
  const String& class_name =
      String::Handle(Class::Handle(function.owner()).Name());
  OS::Print("< Exiting '%s.%s'\n",
      class_name.ToCString(), function_name.ToCString());
}


// Allocation of a fixed length array of given element type.
// This runtime entry is never called for allocating a List of a generic type,
// because a prior run time call instantiates the element type if necessary.
// Arg0: array length.
// Arg1: array element type.
// Return value: newly allocated array of length arg0.
DEFINE_RUNTIME_ENTRY(AllocateArray, 2) {
  ASSERT(arguments.Count() == kAllocateArrayRuntimeEntry.argument_count());
  const Smi& length = Smi::CheckedHandle(arguments.At(0));
  const Array& array = Array::Handle(Array::New(length.Value()));
  arguments.SetReturn(array);
  AbstractTypeArguments& element_type =
      AbstractTypeArguments::CheckedHandle(arguments.At(1));
  // An Array is raw or takes only one type argument.
  ASSERT(element_type.IsNull() ||
         ((element_type.Length() == 1) && element_type.IsInstantiated()));
  array.SetTypeArguments(element_type);  // May be null.
}


// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Arg2: type arguments of the instantiator or kNoInstantiator.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 3) {
  ASSERT(arguments.Count() == kAllocateObjectRuntimeEntry.argument_count());
  const Class& cls = Class::CheckedHandle(arguments.At(0));
  const Instance& instance = Instance::Handle(Instance::New(cls));
  arguments.SetReturn(instance);
  if (!cls.HasTypeArguments()) {
    // No type arguments required for a non-parameterized type.
    ASSERT(Instance::CheckedHandle(arguments.At(1)).IsNull());
    return;
  }
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(1));
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.Length() == cls.NumTypeArguments()));
  // If no instantiator is provided, set the type arguments and return.
  if (Object::Handle(arguments.At(2)).IsSmi()) {
    ASSERT(Smi::CheckedHandle(arguments.At(2)).Value() ==
           StubCode::kNoInstantiator);
    instance.SetTypeArguments(type_arguments);  // May be null.
    return;
  }
  ASSERT(!type_arguments.IsInstantiated());
  const AbstractTypeArguments& instantiator =
      AbstractTypeArguments::CheckedHandle(arguments.At(2));
  ASSERT(instantiator.IsNull() || instantiator.IsInstantiated());
  if (instantiator.IsNull()) {
    type_arguments =
        InstantiatedTypeArguments::New(type_arguments, instantiator);
  } else if (instantiator.IsTypeArguments()) {
    // Code inlined in the caller should have optimized the case where the
    // instantiator is a TypeArguments and can be used as type argument vector.
    ASSERT(!type_arguments.IsUninstantiatedIdentity() ||
           (instantiator.Length() != type_arguments.Length()));
    type_arguments =
        InstantiatedTypeArguments::New(type_arguments, instantiator);
  } else {
    // If possible, use the instantiator as the type argument vector.
    if (type_arguments.IsUninstantiatedIdentity() &&
        (instantiator.Length() == type_arguments.Length())) {
      type_arguments = instantiator.raw();
    } else {
      type_arguments =
          InstantiatedTypeArguments::New(type_arguments, instantiator);
    }
  }
  ASSERT(type_arguments.IsInstantiated());
  instance.SetTypeArguments(type_arguments);
}


// Allocate a new object of a generic type and check that the instantiated type
// arguments are within the declared bounds or throw a dynamic type error.
// Arg0: index of the token of the instance creation (source location).
// Arg1: class of the object that needs to be allocated.
// Arg2: type arguments of the object that needs to be allocated.
// Arg3: type arguments of the instantiator or kNoInstantiator.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObjectWithBoundsCheck, 4) {
  ASSERT(FLAG_enable_type_checks);
  ASSERT(arguments.Count() ==
         kAllocateObjectWithBoundsCheckRuntimeEntry.argument_count());
  const Class& cls = Class::CheckedHandle(arguments.At(1));
  const Instance& instance = Instance::Handle(Instance::New(cls));
  arguments.SetReturn(instance);
  ASSERT(cls.HasTypeArguments());
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(2));
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.Length() == cls.NumTypeArguments()));
  AbstractTypeArguments& bounds_instantiator = AbstractTypeArguments::Handle();
  if (Object::Handle(arguments.At(3)).IsSmi()) {
    ASSERT(Smi::CheckedHandle(arguments.At(3)).Value() ==
           StubCode::kNoInstantiator);
  } else {
    ASSERT(!type_arguments.IsInstantiated());
    const AbstractTypeArguments& instantiator =
        AbstractTypeArguments::CheckedHandle(arguments.At(3));
    ASSERT(instantiator.IsNull() || instantiator.IsInstantiated());
    if (instantiator.IsNull()) {
      type_arguments =
          InstantiatedTypeArguments::New(type_arguments, instantiator);
    } else if (instantiator.IsTypeArguments()) {
      // Code inlined in the caller should have optimized the case where the
      // instantiator is a TypeArguments and can be used as type argument
      // vector.
      ASSERT(!type_arguments.IsUninstantiatedIdentity() ||
             (instantiator.Length() != type_arguments.Length()));
      type_arguments =
          InstantiatedTypeArguments::New(type_arguments, instantiator);
    } else {
      // If possible, use the instantiator as the type argument vector.
      if (type_arguments.IsUninstantiatedIdentity() &&
          (instantiator.Length() == type_arguments.Length())) {
        type_arguments = instantiator.raw();
      } else {
        type_arguments =
            InstantiatedTypeArguments::New(type_arguments, instantiator);
      }
    }
    bounds_instantiator = instantiator.raw();
  }
  if (!type_arguments.IsNull()) {
    ASSERT(type_arguments.IsInstantiated());
    Error& malformed_error = Error::Handle();
    if (!type_arguments.IsWithinBoundsOf(cls,
                                         bounds_instantiator,
                                         &malformed_error)) {
      ASSERT(!malformed_error.IsNull());
      // Throw a dynamic type error.
      intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
      String& malformed_error_message =  String::Handle(
          String::New(malformed_error.ToErrorCString()));
      const String& no_name = String::Handle(String::NewSymbol(""));
      Exceptions::CreateAndThrowTypeError(
          location, no_name, no_name, no_name, malformed_error_message);
      UNREACHABLE();
    }
  }
  instance.SetTypeArguments(type_arguments);
}


// Instantiate type arguments.
// Arg0: uninstantiated type arguments.
// Arg1: instantiator type arguments.
// Return value: instantiated type arguments.
DEFINE_RUNTIME_ENTRY(InstantiateTypeArguments, 2) {
  ASSERT(arguments.Count() ==
         kInstantiateTypeArgumentsRuntimeEntry.argument_count());
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(0));
  const AbstractTypeArguments& instantiator =
      AbstractTypeArguments::CheckedHandle(arguments.At(1));
  ASSERT(!type_arguments.IsNull() && !type_arguments.IsInstantiated());
  ASSERT(instantiator.IsNull() || instantiator.IsInstantiated());
  // Code inlined in the caller should have optimized the case where the
  // instantiator can be used as type argument vector.
  ASSERT(instantiator.IsNull() ||
         !type_arguments.IsUninstantiatedIdentity() ||
         !instantiator.IsTypeArguments() ||
         (instantiator.Length() != type_arguments.Length()));
  type_arguments = InstantiatedTypeArguments::New(type_arguments, instantiator);
  ASSERT(type_arguments.IsInstantiated());
  arguments.SetReturn(type_arguments);
}


// Allocate a new closure.
// The type argument vector of a closure is always the vector of type parameters
// of its signature class, i.e. an uninstantiated identity vector. Therefore,
// the instantiator type arguments can be used as the instantiated closure type
// arguments and is passed here as the type arguments.
// Arg0: local function.
// Arg1: type arguments of the closure (i.e. instantiator).
// Return value: newly allocated closure.
DEFINE_RUNTIME_ENTRY(AllocateClosure, 2) {
  ASSERT(arguments.Count() == kAllocateClosureRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(function.IsClosureFunction() && !function.IsImplicitClosureFunction());
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(1));
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  // The current context was saved in the Isolate structure when entering the
  // runtime.
  const Context& context = Context::Handle(isolate->top_context());
  ASSERT(!context.IsNull());
  const Closure& closure = Closure::Handle(Closure::New(function, context));
  closure.SetTypeArguments(type_arguments);
  arguments.SetReturn(closure);
}


// Allocate a new implicit static closure.
// Arg0: local function.
// Return value: newly allocated closure.
DEFINE_RUNTIME_ENTRY(AllocateImplicitStaticClosure, 1) {
  ASSERT(arguments.Count() ==
         kAllocateImplicitStaticClosureRuntimeEntry.argument_count());
  ObjectStore* object_store = isolate->object_store();
  ASSERT(object_store != NULL);
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(!function.IsNull());
  ASSERT(function.IsImplicitStaticClosureFunction());
  const Context& context = Context::Handle(object_store->empty_context());
  arguments.SetReturn(Closure::Handle(Closure::New(function, context)));
}


// Allocate a new implicit instance closure.
// Arg0: local function.
// Arg1: receiver object.
// Arg2: type arguments of the closure.
// Return value: newly allocated closure.
DEFINE_RUNTIME_ENTRY(AllocateImplicitInstanceClosure, 3) {
  ASSERT(arguments.Count() ==
         kAllocateImplicitInstanceClosureRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(function.IsImplicitInstanceClosureFunction());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(1));
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(2));
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  Context& context = Context::Handle();
  context = Context::New(1);
  context.SetAt(0, receiver);
  const Closure& closure = Closure::Handle(Closure::New(function, context));
  closure.SetTypeArguments(type_arguments);
  arguments.SetReturn(closure);
}


// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  ASSERT(arguments.Count() == kAllocateContextRuntimeEntry.argument_count());
  const Smi& num_variables = Smi::CheckedHandle(arguments.At(0));
  arguments.SetReturn(Context::Handle(Context::New(num_variables.Value())));
}


// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  ASSERT(arguments.Count() == kCloneContextRuntimeEntry.argument_count());
  const Context& ctx = Context::CheckedHandle(arguments.At(0));
  Context& cloned_ctx = Context::Handle(Context::New(ctx.num_variables()));
  cloned_ctx.set_parent(Context::Handle(ctx.parent()));
  for (int i = 0; i < ctx.num_variables(); i++) {
    cloned_ctx.SetAt(i, Instance::Handle(ctx.At(i)));
  }
  arguments.SetReturn(cloned_ctx);
}


// Helper routine for tracing a type check.
static void PrintTypeCheck(
    const char* message,
    const Instance& instance,
    const AbstractType&type,
    const AbstractTypeArguments& instantiator_type_arguments,
    const Bool& result) {
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);

  const Type& instance_type = Type::Handle(instance.GetType());
  ASSERT(instance_type.IsInstantiated());
  if (type.IsInstantiated()) {
    OS::Print("%s: '%s' %s '%s' (pc: 0x%x).\n",
              message,
              String::Handle(instance_type.Name()).ToCString(),
              (result.raw() == Bool::True()) ? "is" : "is !",
              String::Handle(type.Name()).ToCString(),
              caller_frame->pc());
  } else {
    // Instantiate type before printing.
    const AbstractType& instantiated_type =
        AbstractType::Handle(type.InstantiateFrom(instantiator_type_arguments));
    OS::Print("%s: '%s' %s '%s' instantiated from '%s' (pc: 0x%x).\n",
              message,
              String::Handle(instance_type.Name()).ToCString(),
              (result.raw() == Bool::True()) ? "is" : "is !",
              String::Handle(instantiated_type.Name()).ToCString(),
              String::Handle(type.Name()).ToCString(),
              caller_frame->pc());
  }
  const Function& function = Function::Handle(
      caller_frame->LookupDartFunction());
  OS::Print(" -> Function %s\n", function.ToFullyQualifiedCString());
}


// Converts InstantiatedTypeArguments to TypeArguments and stores it
// into the instance. The assembly code can handle only type arguments of
// class TypeArguments. Because of the overhead, do it only when needed.
// Return false if the optimization was aborted.
// Set type_arguments_replaced to true if they have changed.
static bool OptimizeTypeArguments(const Instance& instance,
                                  bool* type_arguments_replaced) {
  *type_arguments_replaced = false;
  const Class& type_class = Class::ZoneHandle(instance.clazz());
  if (!type_class.HasTypeArguments()) {
    return true;
  }
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::Handle(instance.GetTypeArguments());
  if (type_arguments.IsNull()) {
    return true;
  }
  if (type_arguments.IsInstantiatedTypeArguments()) {
    do {
      InstantiatedTypeArguments& instantiated_type_arguments =
          InstantiatedTypeArguments::Handle();
      instantiated_type_arguments ^= type_arguments.raw();
      const AbstractTypeArguments& uninstantiated =
          AbstractTypeArguments::Handle(
              instantiated_type_arguments.uninstantiated_type_arguments());
      const AbstractTypeArguments& instantiator =
          AbstractTypeArguments::Handle(
              instantiated_type_arguments.instantiator_type_arguments());
      type_arguments = uninstantiated.InstantiateFrom(instantiator);
    } while (type_arguments.IsInstantiatedTypeArguments());
    TypeArguments& new_type_arguments = TypeArguments::Handle();
    new_type_arguments ^= type_arguments.raw();
    new_type_arguments ^= new_type_arguments.Canonicalize();
    instance.SetTypeArguments(new_type_arguments);
    *type_arguments_replaced = true;
  } else if (!type_arguments.IsCanonical()) {
    AbstractTypeArguments& new_type_arguments =
        AbstractTypeArguments::Handle();
    new_type_arguments ^= type_arguments.Canonicalize();
    instance.SetTypeArguments(new_type_arguments);
    *type_arguments_replaced = true;
  }
  ASSERT(AbstractTypeArguments::Handle(
      instance.GetTypeArguments()).IsTypeArguments());
  return true;
}


// This updates the type test cache, an array containing 4-value elements
// (instance class, instance type arguments, instantiator type arguments and
// test_result). It can be applied to classes with type arguments in which
// case it contains just the result of the class subtype test, not including
// the evaluation of type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
// 'instantiator' can be null, in which case inst_targ
static void UpdateTypeTestCache(
    intptr_t node_id,
    const Instance& instance,
    const AbstractType& type,
    const Instance& instantiator,
    const AbstractTypeArguments& incoming_instantiator_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  // Since the test is expensive, don't do it unless necessary.
  // The list of disallowed cases will decrease as they are implemented in
  // inlined assembly.
  if (new_cache.IsNull()) return;
  // Instantiator type arguments may be canonicalized later.
  AbstractTypeArguments& instantiator_type_arguments =
      AbstractTypeArguments::Handle(incoming_instantiator_type_arguments.raw());
  AbstractTypeArguments& instance_type_arguments =
      AbstractTypeArguments::Handle();
  const Class& instance_class = Class::Handle(instance.clazz());

  // Canonicalize type arguments.
  bool type_arguments_replaced = false;
  if (instance_class.HasTypeArguments()) {
    // Canonicalize type arguments.
    if (!OptimizeTypeArguments(instance, &type_arguments_replaced)) {
      if (FLAG_trace_type_checks) {
        PrintTypeCheck("WARNING: Cannot canonicalize instance type arguments",
            instance, type, instantiator_type_arguments, result);
      }
      return;
    }
    instance_type_arguments = instance.GetTypeArguments();
  }
  if (!instantiator.IsNull()) {
    bool replaced = false;
    if (!OptimizeTypeArguments(instantiator, &replaced)) {
      if (FLAG_trace_type_checks) {
        PrintTypeCheck("WARNING: Cannot canonicalize instantiator "
            "type arguments",
            instance, type, instantiator_type_arguments, result);
      }
      return;
    }
    if (replaced) {
      type_arguments_replaced = true;
    }
    instantiator_type_arguments ^= instantiator.GetTypeArguments();
  }

  Class& last_instance_class = Class::Handle();
  AbstractTypeArguments& last_instance_type_arguments =
      AbstractTypeArguments::Handle();
  AbstractTypeArguments& last_instantiator_type_arguments =
      AbstractTypeArguments::Handle();
  Bool& last_result = Bool::Handle();
  intptr_t len = new_cache.NumberOfChecks();
  for (intptr_t i = 0; i < len; ++i) {
    new_cache.GetCheck(
        i,
        &last_instance_class,
        &last_instance_type_arguments,
        &last_instantiator_type_arguments,
        &last_result);
    if ((last_instance_class.raw() == instance_class.raw()) &&
        (last_instance_type_arguments.raw() == instance_type_arguments.raw()) &&
        (last_instantiator_type_arguments.raw() ==
         instantiator_type_arguments.raw())) {
      if (FLAG_trace_type_checks) {
        OS::Print("%d ", i);
        if (type_arguments_replaced) {
          PrintTypeCheck("Duplicate cache entry (canonical.)", instance, type,
              instantiator_type_arguments, result);
        } else {
          PrintTypeCheck("WARNING Duplicate cache entry", instance, type,
              instantiator_type_arguments, result);
        }
      }
      // Can occur if we have canonicalized arguments.
      // TODO(srdjan): Investigate why this assert can fail.
      // ASSERT(type_arguments_replaced);
      return;
    }
  }
  new_cache.AddCheck(instance_class,
                     instance_type_arguments,
                     instantiator_type_arguments,
                     result);
  if (FLAG_trace_type_checks) {
    AbstractType& test_type = AbstractType::Handle(type.raw());
    if (!test_type.IsInstantiated()) {
      test_type = type.InstantiateFrom(instantiator_type_arguments);
    }
    OS::Print("  Updated test cache 0x%x ix:%d:\n"
        "    [0x%x %s, 0x%x %s]\n"
        "    [0x%x %s, 0x%x %s] %s\n",
        new_cache.raw(),
        len,
        instance_class.raw(),
        instance_class.ToCString(),
        instance_type_arguments.raw(),
        instance_type_arguments.ToCString(),
        test_type.type_class(),
        Class::Handle(test_type.type_class()).ToCString(),
        instantiator_type_arguments.raw(),
        instantiator_type_arguments.ToCString(),
        result.ToCString());
  }
}


// Check that the given instance is an instance of the given type.
// Tested instance may not be null, because the null test is inlined.
// Arg0: index of the token of the instanceof test (source location).
// Arg1: node id of the instanceof node.
// Arg2: instance being checked.
// Arg3: type.
// Arg4: instantiator (or null).
// Arg5: type arguments of the instantiator of the type.
// Arg6: SubtypeTestCache.
// Return value: true or false, or may throw a type error in checked mode.
DEFINE_RUNTIME_ENTRY(Instanceof, 7) {
  ASSERT(arguments.Count() == kInstanceofRuntimeEntry.argument_count());
  // TODO(regis): Get the token index from the PcDesc (via DartFrame).
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  intptr_t node_id = Smi::CheckedHandle(arguments.At(1)).Value();
  const Instance& instance = Instance::CheckedHandle(arguments.At(2));
  const AbstractType& type = AbstractType::CheckedHandle(arguments.At(3));
  const Instance& instantiator = Instance::CheckedHandle(arguments.At(4));
  const AbstractTypeArguments& instantiator_type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(5));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.At(6));
  ASSERT(type.IsFinalized());
  Error& malformed_error = Error::Handle();
  const Bool& result = Bool::Handle(
      instance.IsInstanceOf(type,
                            instantiator_type_arguments,
                            &malformed_error) ?
      Bool::True() : Bool::False());
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf",
        instance, type, instantiator_type_arguments, result);
  }
  if (!result.value() && !malformed_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    String& malformed_error_message =  String::Handle(
        String::New(malformed_error.ToErrorCString()));
    const String& no_name = String::Handle(String::NewSymbol(""));
    Exceptions::CreateAndThrowTypeError(
        location, no_name, no_name, no_name, malformed_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(node_id, instance, type, instantiator,
                      instantiator_type_arguments, result, cache);
  arguments.SetReturn(result);
}


// For error reporting simplify type name, e.g, all integer types (Smi, Mint,
// Bigint) a re reported as 'int'.
static RawString* GetSimpleTypeName(const Instance& value) {
  if (value.IsInteger()) {
    return String::NewSymbol("int");
  } else {
    return Type::Handle(value.GetType()).Name();
  }
}


// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Arg0: index of the token of the assignment (source location).
// Arg1: node-id of the assignment.
// Arg2: instance being assigned.
// Arg3: type being assigned to.
// Arg4: instantiator (or null).
// Arg5: type arguments of the instantiator of the type being assigned to.
// Arg6: name of variable being assigned to.
// Arg7: SubtypeTestCache.
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 8) {
  ASSERT(arguments.Count() == kTypeCheckRuntimeEntry.argument_count());
  // TODO(regis): Get the token index from the PcDesc (via DartFrame).
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  intptr_t node_id = Smi::CheckedHandle(arguments.At(1)).Value();
  const Instance& src_instance = Instance::CheckedHandle(arguments.At(2));
  const AbstractType& dst_type = AbstractType::CheckedHandle(arguments.At(3));
  const Instance& dst_instantiator = Instance::CheckedHandle(arguments.At(4));
  const AbstractTypeArguments& instantiator_type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments.At(5));
  const String& dst_name = String::CheckedHandle(arguments.At(6));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(arguments.At(7));
  ASSERT(!dst_type.IsDynamicType());  // No need to check assignment.
  ASSERT(!dst_type.IsMalformed());  // Already checked in code generator.
  ASSERT(!src_instance.IsNull());  // Already checked in inlined code.

  Error& malformed_error = Error::Handle();
  const bool is_instance_of = src_instance.IsInstanceOf(
      dst_type, instantiator_type_arguments, &malformed_error);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck",
        src_instance, dst_type, instantiator_type_arguments,
        Bool::Handle(is_instance_of ? Bool::True() : Bool::False()));
  }
  if (!is_instance_of) {
    String& src_type_name = String::Handle(GetSimpleTypeName(src_instance));
    String& dst_type_name = String::Handle();
    if (!dst_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      const AbstractType& instantiated_dst_type = AbstractType::Handle(
          dst_type.InstantiateFrom(instantiator_type_arguments));
      dst_type_name = instantiated_dst_type.Name();
    } else {
      dst_type_name = dst_type.Name();
    }
    String& malformed_error_message =  String::Handle();
    if (!malformed_error.IsNull()) {
      ASSERT(FLAG_enable_type_checks);
      malformed_error_message = String::New(malformed_error.ToErrorCString());
    }
    Exceptions::CreateAndThrowTypeError(location, src_type_name, dst_type_name,
                                        dst_name, malformed_error_message);
    UNREACHABLE();
  }
  UpdateTypeTestCache(node_id, src_instance, dst_type,
                      dst_instantiator, instantiator_type_arguments,
                      Bool::ZoneHandle(Bool::True()), cache);
  arguments.SetReturn(src_instance);
}


// Report that the type of the given object is not bool in conditional context.
// Arg0: index of the token of the assignment (source location).
// Arg1: bad object.
// Return value: none, throws a TypeError.
DEFINE_RUNTIME_ENTRY(ConditionTypeError, 2) {
  ASSERT(arguments.Count() ==
      kConditionTypeErrorRuntimeEntry.argument_count());
  // TODO(regis): Get the token index from the PcDesc (via DartFrame).
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  const Instance& src_instance = Instance::CheckedHandle(arguments.At(1));
  ASSERT(src_instance.IsNull() || !src_instance.IsBool());
  const Type& bool_interface = Type::Handle(Type::BoolInterface());
  const String& src_type_name = String::Handle(GetSimpleTypeName(src_instance));
  const String& bool_type_name = String::Handle(bool_interface.Name());
  const String& expr = String::Handle(String::NewSymbol("boolean expression"));
  const String& no_malformed_type_error =  String::Handle();
  Exceptions::CreateAndThrowTypeError(location, src_type_name, bool_type_name,
                                      expr, no_malformed_type_error);
  UNREACHABLE();
}


// Report that the type of the type check is malformed.
// Arg0: index of the token of the failed type check.
// Arg1: src value.
// Arg2: name of instance being assigned to.
// Arg3: malformed type error message.
// Return value: none, throws an exception.
DEFINE_RUNTIME_ENTRY(MalformedTypeError, 4) {
  ASSERT(arguments.Count() ==
      kMalformedTypeErrorRuntimeEntry.argument_count());
  // TODO(regis): Get the token index from the PcDesc (via DartFrame).
  intptr_t location = Smi::CheckedHandle(arguments.At(0)).Value();
  const Instance& src_value = Instance::CheckedHandle(arguments.At(1));
  const String& dst_name = String::CheckedHandle(arguments.At(2));
  const String& malformed_error = String::CheckedHandle(arguments.At(3));
  const String& dst_type_name = String::Handle(String::NewSymbol("malformed"));
  const String& src_type_name = String::Handle(GetSimpleTypeName(src_value));
  Exceptions::CreateAndThrowTypeError(location, src_type_name,
                                      dst_type_name, dst_name, malformed_error);
  UNREACHABLE();
}


DEFINE_RUNTIME_ENTRY(Throw, 1) {
  ASSERT(arguments.Count() == kThrowRuntimeEntry.argument_count());
  const Instance& exception = Instance::CheckedHandle(arguments.At(0));
  Exceptions::Throw(exception);
}


DEFINE_RUNTIME_ENTRY(ReThrow, 2) {
  ASSERT(arguments.Count() == kReThrowRuntimeEntry.argument_count());
  const Instance& exception = Instance::CheckedHandle(arguments.At(0));
  const Instance& stacktrace = Instance::CheckedHandle(arguments.At(1));
  Exceptions::ReThrow(exception, stacktrace);
}


DEFINE_RUNTIME_ENTRY(PatchStaticCall, 0) {
  // This function is called after successful resolving and compilation of
  // the target method.
  ASSERT(arguments.Count() == kPatchStaticCallRuntimeEntry.argument_count());
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  uword target = 0;
  Function& target_function = Function::Handle();
  CodePatcher::GetStaticCallAt(caller_frame->pc(), &target_function, &target);
  ASSERT(target_function.HasCode());
  uword new_target = Code::Handle(target_function.CurrentCode()).EntryPoint();
  // Verify that we are not patching repeatedly.
  ASSERT(target != new_target);
  CodePatcher::PatchStaticCallAt(caller_frame->pc(), new_target);
  if (FLAG_trace_patching) {
    OS::Print("PatchStaticCall: patching from 0x%x to '%s' 0x%x\n",
        caller_frame->pc(),
        target_function.ToFullyQualifiedCString(),
        new_target);
  }
}


// Resolves and compiles the target function of an instance call, updates
// function cache of the receiver's class and returns the compiled code or null.
// Only the number of named arguments is checked, but not the actual names.
RawCode* ResolveCompileInstanceCallTarget(Isolate* isolate,
                                          const Instance& receiver) {
  int num_arguments = -1;
  int num_named_arguments = -1;
  uword target = 0;
  String& function_name = String::Handle();
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  CodePatcher::GetInstanceCallAt(caller_frame->pc(),
                                 &function_name,
                                 &num_arguments,
                                 &num_named_arguments,
                                 &target);
  ASSERT(function_name.IsSymbol());
  Class& receiver_class = Class::Handle();
  if (receiver.IsNull()) {
    // TODO(srdjan): Clarify behavior of null objects.
    receiver_class = isolate->object_store()->object_class();
  } else {
    receiver_class = receiver.clazz();
  }
  FunctionsCache functions_cache(receiver_class);
  Code& code = Code::Handle();
      code = functions_cache.LookupCode(function_name,
                                        num_arguments,
                                        num_named_arguments);
  if (!code.IsNull()) {
    // Function's code found in the cache.
    return code.raw();
  }

  Function& function = Function::Handle();
  function = Resolver::ResolveDynamic(receiver,
                                      function_name,
                                      num_arguments,
                                      num_named_arguments);
  if (function.IsNull()) {
    return Code::null();
  } else {
    if (!function.HasCode()) {
      const Error& error = Error::Handle(Compiler::CompileFunction(function));
      if (!error.IsNull()) {
        Exceptions::PropagateError(error);
      }
    }
    functions_cache.AddCompiledFunction(function,
                                        num_arguments,
                                        num_named_arguments);
    return function.CurrentCode();
  }
}


// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void CheckResultError(const Object& result) {
  if (result.IsError()) {
    Exceptions::PropagateError(result);
  }
}


// Resolves an instance function and compiles it if necessary.
//   Arg0: receiver object.
//   Returns: RawCode object or NULL (method not found or not compileable).
// This is called by the megamorphic stub when instance call does not need to be
// patched.
// Used by megamorphic lookup/no-such-method-handling.
DEFINE_RUNTIME_ENTRY(ResolveCompileInstanceFunction, 1) {
  ASSERT(arguments.Count() ==
         kResolveCompileInstanceFunctionRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  const Code& code = Code::Handle(
      ResolveCompileInstanceCallTarget(isolate, receiver));
  arguments.SetReturn(Code::Handle(code.raw()));
}


// Gets called from debug stub when code reaches a breakpoint.
//   Arg0: function object of the static function that was about to be called.
DEFINE_RUNTIME_ENTRY(BreakpointStaticHandler, 1) {
  ASSERT(arguments.Count() ==
      kBreakpointStaticHandlerRuntimeEntry.argument_count());
  ASSERT(isolate->debugger() != NULL);
  isolate->debugger()->SignalBpReached();
  // Make sure the static function that is about to be called is
  // compiled. The stub will jump to the entry point without any
  // further tests.
  const Function& function = Function::CheckedHandle(arguments.At(0));
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
}


// Gets called from debug stub when code reaches a breakpoint at a return
// in Dart code.
DEFINE_RUNTIME_ENTRY(BreakpointReturnHandler, 0) {
  ASSERT(arguments.Count() ==
         kBreakpointReturnHandlerRuntimeEntry.argument_count());
  ASSERT(isolate->debugger() != NULL);
  isolate->debugger()->SignalBpReached();
}


// Gets called from debug stub when code reaches a breakpoint.
DEFINE_RUNTIME_ENTRY(BreakpointDynamicHandler, 0) {
  ASSERT(arguments.Count() ==
     kBreakpointDynamicHandlerRuntimeEntry.argument_count());
  ASSERT(isolate->debugger() != NULL);
  isolate->debugger()->SignalBpReached();
}


static RawFunction* InlineCacheMissHandler(
    Isolate* isolate, const GrowableArray<const Instance*>& args) {
  const Instance& receiver = *args[0];
  const Code& target_code =
      Code::Handle(ResolveCompileInstanceCallTarget(isolate, receiver));
  if (target_code.IsNull()) {
    // Let the megamorphic stub handle special cases: NoSuchMethod,
    // closure calls.
    if (FLAG_trace_ic) {
      OS::Print("InlineCacheMissHandler NULL code for receiver: %s\n",
          receiver.ToCString());
    }
    return Function::null();
  }
  const Function& target_function =
      Function::Handle(target_code.function());
  ASSERT(!target_function.IsNull());
  if (receiver.IsNull()) {
    // Null dispatch is slow (e.g., (null).toCString()). The only
    // fast execution with null receiver is the "==" operator.
    // Special handling so that we do not pollute the inline cache with null
    // classes.
    if (FLAG_trace_ic) {
      OS::Print("InlineCacheMissHandler Null receiver target %s\n",
          target_function.ToCString());
    }
    return target_function.raw();
  }
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  ICData& ic_data = ICData::Handle(
      CodePatcher::GetInstanceCallIcDataAt(caller_frame->pc()));
#if defined(DEBUG)
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    GrowableArray<intptr_t> class_ids;
    Function& target = Function::Handle();
    ic_data.GetCheckAt(i, &class_ids, &target);
    bool matches = true;
    for (intptr_t k = 0; k < class_ids.length(); k++) {
      if (class_ids[k] != Class::Handle(args[k]->clazz()).id()) {
        matches = false;
        break;
      }
    }
    // Do not add an entry twice!
    ASSERT(!matches);
  }
#endif  // DEBUG

  if (args.length() == 1) {
    ic_data.AddReceiverCheck(Class::Handle(args[0]->clazz()).id(),
                             target_function);
  } else {
    GrowableArray<intptr_t> class_ids;
    ASSERT(ic_data.num_args_tested() == args.length());
    for (intptr_t i = 0; i < args.length(); i++) {
      class_ids.Add(Class::Handle(args[i]->clazz()).id());
    }
    ic_data.AddCheck(class_ids, target_function);
  }
  if (FLAG_trace_ic) {
    OS::Print("InlineCacheMissHandler %d call at 0x%x' "
              "adding <%s> id:%d -> <%s>\n",
        args.length(),
        caller_frame->pc(),
        Class::Handle(receiver.clazz()).ToCString(),
        Class::Handle(receiver.clazz()).id(),
        target_function.ToCString());
  }
  return target_function.raw();
}


// Handles inline cache misses by updating the IC data array of the call
// site.
//   Arg0: Receiver object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 1) {
  ASSERT(arguments.Count() ==
      kInlineCacheMissHandlerOneArgRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  GrowableArray<const Instance*> args;
  args.Add(&receiver);
  const Function& result =
      Function::Handle(InlineCacheMissHandler(isolate, args));
  arguments.SetReturn(result);
}


// Handles inline cache misses by updating the IC data array of the call
// site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs, 2) {
  ASSERT(arguments.Count() ==
      kInlineCacheMissHandlerTwoArgsRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  const Instance& other = Instance::CheckedHandle(arguments.At(1));
  GrowableArray<const Instance*> args;
  args.Add(&receiver);
  args.Add(&other);
  const Function& result =
      Function::Handle(InlineCacheMissHandler(isolate, args));
  arguments.SetReturn(result);
}


static RawFunction* LookupDynamicFunction(Isolate* isolate,
                                          const Class& in_cls,
                                          const String& name) {
  Class& cls = Class::Handle();
  // For lookups treat null as an instance of class Object.
  if (in_cls.IsNullClass()) {
    cls = isolate->object_store()->object_class();
  } else {
    cls = in_cls.raw();
  }

  Function& function = Function::Handle();
  while (!cls.IsNull()) {
    // Check if function exists.
    function = cls.LookupDynamicFunction(name);
    if (!function.IsNull()) {
      break;
    }
    cls = cls.SuperClass();
  }
  return function.raw();
}


// Resolve an implicit closure by checking if an instance function
// of the same name exists and creating a closure object of the function.
// Arg0: receiver object.
// Arg1: ic-data.
// Returns: Closure object or NULL (instance function not found).
// This is called by the megamorphic stub when it is unable to resolve an
// instance method. This is done just before the call to noSuchMethod.
DEFINE_RUNTIME_ENTRY(ResolveImplicitClosureFunction, 2) {
  ASSERT(arguments.Count() ==
         kResolveImplicitClosureFunctionRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.At(1));
  const String& original_function_name = String::Handle(ic_data.target_name());
  const String& getter_prefix = String::Handle(String::New("get:"));
  Closure& closure = Closure::Handle();
  if (!original_function_name.StartsWith(getter_prefix)) {
    // This is not a getter so can't be the case where we are trying to
    // create an implicit closure of an instance function.
    arguments.SetReturn(closure);
    return;
  }
  Class& receiver_class = Class::Handle();
  receiver_class ^= receiver.clazz();
  ASSERT(!receiver_class.IsNull());
  String& func_name = String::Handle();
  func_name = String::SubString(original_function_name, getter_prefix.Length());
  func_name = String::NewSymbol(func_name);
  const Function& function = Function::Handle(
      LookupDynamicFunction(isolate, receiver_class, func_name));
  if (function.IsNull()) {
    // There is no function of the same name so can't be the case where
    // we are trying to create an implicit closure of an instance function.
    arguments.SetReturn(closure);
    return;
  }
  Function& implicit_closure_function =
      Function::Handle(function.ImplicitClosureFunction());
  // Create a closure object for the implicit closure function.
  const Context& context = Context::Handle(Context::New(1));
  context.SetAt(0, receiver);
  closure = Closure::New(implicit_closure_function, context);
  if (receiver_class.HasTypeArguments()) {
    const AbstractTypeArguments& type_arguments =
        AbstractTypeArguments::Handle(receiver.GetTypeArguments());
    closure.SetTypeArguments(type_arguments);
  }
  arguments.SetReturn(closure);
}


// Resolve an implicit closure by invoking getter and checking if the return
// value from getter is a closure.
// Arg0: receiver object.
// Arg1: ic-data.
// Returns: Closure object or NULL (closure not found).
// This is called by the megamorphic stub when it is unable to resolve an
// instance method. This is done just before the call to noSuchMethod.
DEFINE_RUNTIME_ENTRY(ResolveImplicitClosureThroughGetter, 2) {
  ASSERT(arguments.Count() ==
         kResolveImplicitClosureThroughGetterRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.At(1));
  const String& original_function_name = String::Handle(ic_data.target_name());
  const int kNumArguments = 1;
  const int kNumNamedArguments = 0;
  const String& getter_function_name =
      String::Handle(Field::GetterName(original_function_name));
  Function& function = Function::ZoneHandle(
      Resolver::ResolveDynamic(receiver,
                               getter_function_name,
                               kNumArguments,
                               kNumNamedArguments));
  Code& code = Code::Handle();
  if (function.IsNull()) {
    arguments.SetReturn(code);
    return;  // No getter function found so can't be an implicit closure.
  }
  GrowableArray<const Object*> invoke_arguments(0);
  const Array& kNoArgumentNames = Array::Handle();
  const Object& result =
      Object::Handle(DartEntry::InvokeDynamic(receiver,
                                              function,
                                              invoke_arguments,
                                              kNoArgumentNames));
  if (result.IsError()) {
    if (result.IsUnhandledException()) {
      // If the getter throws an exception, treat as no such method.
      arguments.SetReturn(code);
      return;
    } else {
      Exceptions::PropagateError(result);
    }
  }
  if (!result.IsSmi()) {
    const Class& cls = Class::Handle(result.clazz());
    ASSERT(!cls.IsNull());
    function = cls.signature_function();
    if (!function.IsNull()) {
      arguments.SetReturn(result);
      return;  // Return closure object.
    }
  }
  Exceptions::ThrowByType(Exceptions::kObjectNotClosure, invoke_arguments);
}


// Invoke Implicit Closure function.
// Arg0: closure object.
// Arg1: arguments descriptor (originally passed as dart instance invocation).
// Arg2: arguments array (originally passed to dart instance invocation).
DEFINE_RUNTIME_ENTRY(InvokeImplicitClosureFunction, 3) {
  ASSERT(arguments.Count() ==
         kInvokeImplicitClosureFunctionRuntimeEntry.argument_count());
  const Closure& closure = Closure::CheckedHandle(arguments.At(0));
  const Array& arg_descriptor = Array::CheckedHandle(arguments.At(1));
  const Array& func_arguments = Array::CheckedHandle(arguments.At(2));
  const Function& function = Function::Handle(closure.function());
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  const Context& context = Context::Handle(closure.context());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  const Instructions& instrs = Instructions::Handle(code.instructions());
  ASSERT(!instrs.IsNull());

  // Adjust arguments descriptor array to account for removal of the receiver
  // parameter. Since the arguments descriptor array is canonicalized, create a
  // new one instead of patching the original one.
  const intptr_t len = arg_descriptor.Length();
  const intptr_t num_named_args = (len - 3) / 2;
  const Array& adjusted_arg_descriptor = Array::Handle(Array::New(len));
  Smi& smi = Smi::Handle();
  smi ^= arg_descriptor.At(0);  // Get argument length.
  smi = Smi::New(smi.Value() - 1);  // Adjust argument length.
  ASSERT(smi.Value() == func_arguments.Length());
  adjusted_arg_descriptor.SetAt(0, smi);
  smi ^= arg_descriptor.At(1);  // Get number of positional parameters.
  smi = Smi::New(smi.Value() - 1);  // Adjust number of positional params.
  adjusted_arg_descriptor.SetAt(1, smi);
  // Adjust name/position pairs for each named argument.
  String& named_arg_name = String::Handle();
  Smi& named_arg_pos = Smi::Handle();
  for (intptr_t i = 0; i < num_named_args; i++) {
    const int index = 2 + (2 * i);
    named_arg_name ^= arg_descriptor.At(index);
    ASSERT(named_arg_name.IsSymbol());
    adjusted_arg_descriptor.SetAt(index, named_arg_name);
    named_arg_pos ^= arg_descriptor.At(index + 1);
    named_arg_pos = Smi::New(named_arg_pos.Value() - 1);
    adjusted_arg_descriptor.SetAt(index + 1, named_arg_pos);
  }
  adjusted_arg_descriptor.SetAt(len - 1, Object::Handle(Object::null()));
  // It is too late to share the descriptor by canonicalizing it. However, it is
  // important that the argument names are canonicalized (i.e. are symbols).

  // Receiver parameter has already been skipped by caller.
  GrowableArray<const Object*> invoke_arguments(0);
  for (intptr_t i = 0; i < func_arguments.Length(); i++) {
    const Object& value = Object::Handle(func_arguments.At(i));
    invoke_arguments.Add(&value);
  }

  // Now Call the invoke stub which will invoke the closure.
  DartEntry::invokestub entrypoint = reinterpret_cast<DartEntry::invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  const Object& result = Object::Handle(
      entrypoint(instrs.EntryPoint(),
                 adjusted_arg_descriptor,
                 invoke_arguments.data(),
                 context));
  CheckResultError(result);
  arguments.SetReturn(result);
}


// Invoke appropriate noSuchMethod function.
// Arg0: receiver.
// Arg1: ic-data.
// Arg2: original arguments descriptor array.
// Arg3: original arguments array.
DEFINE_RUNTIME_ENTRY(InvokeNoSuchMethodFunction, 4) {
  ASSERT(arguments.Count() ==
         kInvokeNoSuchMethodFunctionRuntimeEntry.argument_count());
  const Instance& receiver = Instance::CheckedHandle(arguments.At(0));
  const ICData& ic_data = ICData::CheckedHandle(arguments.At(1));
  const String& original_function_name = String::Handle(ic_data.target_name());
  ASSERT(!Array::CheckedHandle(arguments.At(2)).IsNull());
  const Array& orig_arguments = Array::CheckedHandle(arguments.At(3));
  // TODO(regis): The signature of the "noSuchMethod" method has to change from
  // noSuchMethod(String name, Array arguments) to something like
  // noSuchMethod(InvocationMirror call).
  const int kNumArguments = 3;
  const int kNumNamedArguments = 0;
  const Array& kNoArgumentNames = Array::Handle();
  const String& function_name =
      String::Handle(String::NewSymbol("noSuchMethod"));
  const Function& function = Function::ZoneHandle(
      Resolver::ResolveDynamic(receiver,
                               function_name,
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());
  GrowableArray<const Object*> invoke_arguments(2);
  invoke_arguments.Add(&original_function_name);
  invoke_arguments.Add(&orig_arguments);
  const Object& result = Object::Handle(
      DartEntry::InvokeDynamic(receiver,
                               function,
                               invoke_arguments,
                               kNoArgumentNames));
  CheckResultError(result);
  arguments.SetReturn(result);
}


// Report that an object is not a closure.
// Arg0: non-closure object.
// Arg1: arguments array.
DEFINE_RUNTIME_ENTRY(ReportObjectNotClosure, 2) {
  ASSERT(arguments.Count() ==
         kReportObjectNotClosureRuntimeEntry.argument_count());
  const Instance& bad_closure = Instance::CheckedHandle(arguments.At(0));
  if (bad_closure.IsNull()) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kObjectNotClosure, args);
  }
  GrowableArray<const Object*> args;
  Exceptions::ThrowByType(Exceptions::kObjectNotClosure, args);
}


DEFINE_RUNTIME_ENTRY(ClosureArgumentMismatch, 0) {
  ASSERT(arguments.Count() ==
         kClosureArgumentMismatchRuntimeEntry.argument_count());
  GrowableArray<const Object*> args;
  Exceptions::ThrowByType(Exceptions::kClosureArgumentMismatch, args);
}


DEFINE_RUNTIME_ENTRY(StackOverflow, 0) {
  ASSERT(arguments.Count() ==
         kStackOverflowRuntimeEntry.argument_count());
  uword stack_pos = reinterpret_cast<uword>(&arguments);

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow first.
  if (stack_pos < isolate->saved_stack_limit()) {
    // Use the preallocated stack overflow exception to avoid calling
    // into dart code.
    const Instance& exception =
        Instance::Handle(isolate->object_store()->stack_overflow());
    Exceptions::Throw(exception);
    UNREACHABLE();
  }

  uword interrupt_bits = isolate->GetAndClearInterrupts();
  if (interrupt_bits & Isolate::kMessageInterrupt) {
    isolate->message_handler()->HandleOOBMessages();
  }
  if (interrupt_bits & Isolate::kApiInterrupt) {
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
}


// Only unoptimized code has invocation counter threshold checking.
// Once the invocation counter threshold is reached any entry into the
// unoptimized code is redirected to this function.
DEFINE_RUNTIME_ENTRY(OptimizeInvokedFunction, 1) {
  const intptr_t kLowInvocationCount = -100000000;
  ASSERT(arguments.Count() ==
         kOptimizeInvokedFunctionRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  if (isolate->debugger()->IsActive()) {
    // We cannot set breakpoints in optimized code, so do not optimize
    // the function.
    function.set_usage_counter(0);
    return;
  }
  if (function.deoptimization_counter() >=
      FLAG_deoptimization_counter_threshold) {
    // TODO(srdjan): Investigate excessive deoptimization.
    function.set_usage_counter(kLowInvocationCount);
    return;
  }
  if (function.HasOptimizedCode()) {
    // The caller has been already optimized.
    // TODO(srdjan): This is a significant slowdown, the caller is probably in
    // a loop. Maybe test if the code has been optimized before calling.
    // If this happens from optimized code, then it means that the optimized
    // code needs to be reoptimized.
    function.set_usage_counter(kLowInvocationCount);
    return;
  }
  if ((FLAG_optimization_filter != NULL) &&
      (strncmp(function.ToFullyQualifiedCString(),
               FLAG_optimization_filter,
               strlen(FLAG_optimization_filter)) != 0)) {
    function.set_usage_counter(kLowInvocationCount);
    return;
  }
  if (function.is_optimizable()) {
    ASSERT(!function.HasOptimizedCode());
    const Code& unoptimized_code = Code::Handle(function.unoptimized_code());
    // Compilation patches the entry of unoptimized code.
    const Error& error =
        Error::Handle(Compiler::CompileOptimizedFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
    const Code& optimized_code = Code::Handle(function.CurrentCode());
    ASSERT(!optimized_code.IsNull());
    ASSERT(!unoptimized_code.IsNull());
  } else {
    // TODO(5442338): Abort as this should not happen.
    function.set_usage_counter(kLowInvocationCount);
  }
}


// The caller must be a static call in a Dart frame, or an entry frame.
// Patch static call to point to 'new_entry_point'.
DEFINE_RUNTIME_ENTRY(FixCallersTarget, 1) {
  ASSERT(arguments.Count() == kFixCallersTargetRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  StackFrameIterator iterator(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = iterator.NextFrame();
  while (frame != NULL && (frame->IsStubFrame() || frame->IsExitFrame())) {
    frame = iterator.NextFrame();
  }
  ASSERT(frame != NULL);
  if (!frame->IsEntryFrame()) {
    ASSERT(frame->IsDartFrame());
    uword target = 0;
    Function& target_function = Function::Handle();
    CodePatcher::GetStaticCallAt(frame->pc(), &target_function, &target);
    ASSERT(target_function.HasCode());
    const uword new_entry_point =
        Code::Handle(function.CurrentCode()).EntryPoint();
    ASSERT(target != new_entry_point);  // Why patch otherwise.
    CodePatcher::PatchStaticCallAt(frame->pc(), new_entry_point);
    if (FLAG_trace_patching) {
      OS::Print("FixCallersTarget: patching from 0x%x to '%s' 0x%x\n",
          frame->pc(),
          target_function.ToFullyQualifiedCString(),
          new_entry_point);
    }
  }
}


static const char* DeoptReasonToText(intptr_t deopt_id) {
  switch (deopt_id) {
#define DEOPT_REASON_ID_TO_TEXT(name) case k##name: return #name;
DEOPT_REASONS(DEOPT_REASON_ID_TO_TEXT)
#undef DEOPT_REASON_ID_TO_TEXT
    default:
      UNREACHABLE();
      return "";
  }
}


// The top Dart frame belongs to the optimized method that needs to be
// deoptimized. The pc of the Dart frame points to the deoptimization point.
// Find the node id of the deoptimization point and find the continuation
// pc in the unoptimized code.
// Since both unoptimized and optimized code have the same layout, we need only
// to patch the pc of the Dart frame and to disable/enable appropriate code.
DEFINE_RUNTIME_ENTRY(Deoptimize, 1) {
  ASSERT(arguments.Count() == kDeoptimizeRuntimeEntry.argument_count());
  const Smi& deoptimization_reason_id = Smi::CheckedHandle(arguments.At(0));
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
  const Function& function = Function::Handle(optimized_code.function());
  ASSERT(!function.IsNull());
  const Code& unoptimized_code = Code::Handle(function.unoptimized_code());
  ASSERT(!optimized_code.IsNull() && optimized_code.is_optimized());
  ASSERT(!unoptimized_code.IsNull() && !unoptimized_code.is_optimized());
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(optimized_code.pc_descriptors());
  ASSERT(!descriptors.IsNull());
  // Locate node id at deoptimization point inside optimized code.
  intptr_t deopt_node_id = AstNode::kNoId;
  intptr_t deopt_token_index = 0;
  for (int i = 0; i < descriptors.Length(); i++) {
    if (static_cast<uword>(descriptors.PC(i)) == caller_frame->pc()) {
      deopt_node_id = descriptors.NodeId(i);
      deopt_token_index = descriptors.TokenIndex(i);
      break;
    }
  }
  ASSERT(deopt_node_id != AstNode::kNoId);
  uword continue_at_pc =
      unoptimized_code.GetDeoptPcAtNodeId(deopt_node_id);
  ASSERT(continue_at_pc != 0);
  if (FLAG_trace_deopt) {
    OS::Print("Deoptimizing (reason %d '%s') at pc 0x%x id %d '%s' "
        "-> continue at 0x%x \n",
        deoptimization_reason_id.Value(),
        DeoptReasonToText(deoptimization_reason_id.Value()),
        caller_frame->pc(),
        deopt_node_id,
        function.ToFullyQualifiedCString(),
        continue_at_pc);
    const Class& cls = Class::Handle(function.owner());
    const Script& script = Script::Handle(cls.script());
    intptr_t line, column;
    script.GetTokenLocation(deopt_token_index, &line, &column);
    OS::Print("  Line: %d Column: %d ", line, column);
    OS::Print(">>  %s\n", String::Handle(script.GetLine(line)).ToCString());
  }
  // Patch the return PC and saved PC marker in frame to point to the
  // unoptimized version.
  caller_frame->set_pc(continue_at_pc);
  caller_frame->SetEntrypointMarker(
      unoptimized_code.EntryPoint() +
      AssemblerMacros::kOffsetOfSavedPCfromEntrypoint);

  // Clear invocation counter so that the function gets optimized after
  // types/classes have been collected.
  function.set_usage_counter(0);
  function.set_deoptimization_counter(function.deoptimization_counter() + 1);

  // We have to skip the following otherwise the compiler will complain
  // when it attempts to install unoptimized code into a function that
  // was already deoptimized.
  if (function.HasOptimizedCode()) {
    // Get unoptimized code. Compilation restores (reenables) the entry of
    // unoptimized code.
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  // TODO(srdjan): Handle better complex cases, e.g. when an older optimized
  // code is alive on frame and gets deoptimized after the function was
  // optimized a second time.
  if (FLAG_trace_deopt) {
    OS::Print("After patching ->0x%x:\n", continue_at_pc);
  }
}


// We are entering function name for a valid argument count.
void FunctionsCache::EnterFunctionAt(int i,
                                     const Array& cache,
                                     const Function& function,
                                     int num_arguments,
                                     int num_named_arguments) {
  ASSERT((i % kNumEntries) == 0);
  ASSERT(function.AreValidArgumentCounts(num_arguments, num_named_arguments));
  cache.SetAt(i + FunctionsCache::kFunctionName,
      String::Handle(function.name()));
  cache.SetAt(i + FunctionsCache::kArgCount,
      Smi::Handle(Smi::New(num_arguments)));
  cache.SetAt(i + FunctionsCache::kNamedArgCount,
      Smi::Handle(Smi::New(num_named_arguments)));
  cache.SetAt(i + FunctionsCache::kFunction, function);
}


void FunctionsCache::AddCompiledFunction(const Function& function,
                                         int num_arguments,
                                         int num_named_arguments) {
// TODO(srdjan): Evaluate if populating the function cache is needed.
// It is turned off currently because we do not populate code objects
// in snapshot and hence end up in an inconsistent state as function
// cache is populated but there are no code objects.
#if 0
  ASSERT(function.HasCode());
  Array& cache = Array::Handle(class_.functions_cache());
  // Search for first free slot. Last entry is always NULL object.
  for (intptr_t i = 0; i < (cache.Length() - kNumEntries); i += kNumEntries) {
    if (Object::Handle(cache.At(i)).IsNull()) {
      EnterFunctionAt(i,
                      cache,
                      function,
                      num_arguments,
                      num_named_arguments);
      return;
    }
  }
  intptr_t ix = cache.Length() - kNumEntries;
  // Grow by 8 entries.
  cache = Array::Grow(cache, cache.Length() + (8 * kNumEntries));
  class_.set_functions_cache(cache);
  EnterFunctionAt(ix,
                  cache,
                  function,
                  num_arguments,
                  num_named_arguments);
#endif
}


// Only the number of named arguments is checked, but not the actual names.
RawCode* FunctionsCache::LookupCode(const String& function_name,
                                    int num_arguments,
                                    int num_named_arguments) {
  const Array& cache = Array::Handle(class_.functions_cache());
  String& test_name = String::Handle();
  for (intptr_t i = 0; i < cache.Length(); i += kNumEntries) {
    test_name ^= cache.At(i + FunctionsCache::kFunctionName);
    if (test_name.IsNull()) {
      // Found NULL, no more entries to check, abort lookup.
      return Code::null();
    }
    if (function_name.Equals(test_name)) {
      Smi& smi = Smi::Handle();
      smi ^= cache.At(i + FunctionsCache::kArgCount);
      if (num_arguments == smi.Value()) {
        smi ^= cache.At(i + FunctionsCache::kNamedArgCount);
        if (num_named_arguments == smi.Value()) {
          Function& result = Function::Handle();
          result ^= cache.At(i + FunctionsCache::kFunction);
          ASSERT(!result.IsNull());
          ASSERT(result.HasCode());
          return result.CurrentCode();
        }
      }
    }
  }
  // The cache is null terminated, therefore the loop above should never
  // terminate by itself.
  UNREACHABLE();
  return Code::null();
}


// Adds a pointer to the store buffer.
// ptr: the address of a field being stored into.
DEFINE_LEAF_RUNTIME_ENTRY(void, StoreBuffer, uword ptr) {
  Isolate::Current()->store_buffer()->AddPointer(ptr);
}
END_LEAF_RUNTIME_ENTRY

}  // namespace dart
