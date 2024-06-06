// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/resolver.h"

#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, trace_resolving, false, "Trace resolving.");

static FunctionPtr ResolveDynamicAnyArgsWithCustomLookup(
    Zone* zone,
    const Class& receiver_class,
    const String& function_name,
    bool allow_add,
    std::function<FunctionPtr(Class&, const String&)> lookup) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // No methods can be added in the precompiled runtime.
  ASSERT(!allow_add);
#endif

  if (FLAG_trace_resolving) {
    THR_Print("ResolveDynamic '%s' for class %s\n", function_name.ToCString(),
              receiver_class.NameCString(Object::kInternalName));
  }

  const bool is_dyn_call =
      Function::IsDynamicInvocationForwarderName(function_name);
  const String* const demangled_name =
      is_dyn_call
          ? &String::Handle(
                zone,
                Function::DemangleDynamicInvocationForwarderName(function_name))
          : &function_name;

  const bool is_getter = Field::IsGetterName(*demangled_name);
  const String* const method_name_to_extract =
      is_getter ? &String::Handle(zone, Field::NameFromGetter(*demangled_name))
                : nullptr;

  Thread* thread = Thread::Current();
  Function& function = Function::Handle(zone);
  for (auto& cls = Class::Handle(zone, receiver_class.ptr()); !cls.IsNull();
       cls = cls.SuperClass()) {
    if (is_dyn_call) {
      // If a dyn:* forwarder already exists, return it.
      function = cls.GetInvocationDispatcher(
          function_name, Array::null_array(),
          UntaggedFunction::kDynamicInvocationForwarder,
          /*create_if_absent=*/false);
      if (!function.IsNull()) return function.ptr();
    }

    ASSERT(cls.is_finalized());
    {
      SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
      function = lookup(cls, *demangled_name);
    }
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (allow_add && is_dyn_call && !function.IsNull()) {
      // In JIT mode, lazily create a dyn:* forwarder if one is required.
      function = function.GetDynamicInvocationForwarder(function_name);
    }
#endif
    if (!function.IsNull()) return function.ptr();

    // Getter invocation might be an attempted closurization of a method that
    // does not already have an implicit closure function or method extractor.
    if (is_getter) {
      SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
      function = lookup(cls, *method_name_to_extract);
    }
    if (!function.IsNull()) {
      // Only create method extractors if adding new methods is allowed.
      if (!allow_add) return Function::null();
      // Don't create method extractors in the precompiler, as it creates those
      // based on metadata (see Precompiler::CheckForNewDynamicFunctions).
      if (FLAG_precompiled_mode) return Function::null();
      // Use GetMethodExtractor in case a method extractor was created between
      // the earlier attempted resolution of [*demangled_name] and now.
      return function.GetMethodExtractor(*demangled_name);
    }
  }
  if (is_getter && receiver_class.IsRecordClass()) {
    // Only create record field getters if adding new methods is allowed.
    if (!allow_add) return Function::null();
    // Don't create record field getters in the precompiler.
    if (FLAG_precompiled_mode) return Function::null();
    return receiver_class.GetRecordFieldGetter(*demangled_name);
  }
  return Function::null();
}

static FunctionPtr ResolveDynamicForReceiverClassWithCustomLookup(
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc,
    bool allow_add,
    std::function<FunctionPtr(Class&, const String&)> lookup) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  Function& function = Function::Handle(
      zone, ResolveDynamicAnyArgsWithCustomLookup(
                zone, receiver_class, function_name, allow_add, lookup));

#if defined(DART_PRECOMPILED_RUNTIME)
  if (!function.IsNull() && function.signature() == FunctionType::null()) {
    // FfiTrampolines are the only functions that can still be called
    // dynamically without going through a dynamic invocation forwarder.
    RELEASE_ASSERT(!Function::IsDynamicInvocationForwarderName(function_name) &&
                   !function.IsFfiCallbackTrampoline());
    // The signature for this function was dropped in the precompiler, which
    // means it is not a possible target for a dynamic call in the program.
    // That means we're resolving an UnlinkedCall for an InstanceCall to
    // a known interface. Since there's no overloading in Dart, the type checker
    // has already checked the validity of the arguments at compile time.
    return function.ptr();
  }
#endif

  if (function.IsNull() || !function.AreValidArguments(args_desc, nullptr)) {
    // Return a null function to signal to the upper levels to dispatch to
    // "noSuchMethod" function.
    if (FLAG_trace_resolving) {
      String& error_message =
          String::Handle(zone, Symbols::New(thread, "function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArguments(args_desc, &error_message);
      }
      THR_Print("ResolveDynamic error '%s': %s.\n", function_name.ToCString(),
                error_message.ToCString());
    }
    return Function::null();
  }
  return function.ptr();
}

FunctionPtr Resolver::ResolveDynamicForReceiverClass(
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc,
    bool allow_add) {
  return ResolveDynamicForReceiverClassWithCustomLookup(
      receiver_class, function_name, args_desc, allow_add,
      std::mem_fn(&Class::LookupDynamicFunctionUnsafe));
}

FunctionPtr Resolver::ResolveDynamicForReceiverClassAllowPrivate(
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc) {
  return ResolveDynamicForReceiverClassWithCustomLookup(
      receiver_class, function_name, args_desc, /*allow_add=*/false,
      std::mem_fn(&Class::LookupDynamicFunctionAllowPrivate));
}

FunctionPtr Resolver::ResolveFunction(Zone* zone,
                                      const Class& receiver_class,
                                      const String& function_name) {
  return ResolveDynamicAnyArgsWithCustomLookup(
      zone, receiver_class, function_name, /*allow_add=*/false,
      std::mem_fn(static_cast<FunctionPtr (Class::*)(const String&) const>(
          &Class::LookupFunctionReadLocked)));
}

FunctionPtr Resolver::ResolveDynamicFunction(Zone* zone,
                                             const Class& receiver_class,
                                             const String& function_name) {
  return ResolveDynamicAnyArgsWithCustomLookup(
      zone, receiver_class, function_name, /*allow_add=*/false,
      std::mem_fn(static_cast<FunctionPtr (Class::*)(const String&) const>(
          &Class::LookupDynamicFunctionUnsafe)));
}

FunctionPtr Resolver::ResolveDynamicAnyArgs(Zone* zone,
                                            const Class& receiver_class,
                                            const String& function_name,
                                            bool allow_add) {
  return ResolveDynamicAnyArgsWithCustomLookup(
      zone, receiver_class, function_name, allow_add,
      std::mem_fn(&Class::LookupDynamicFunctionUnsafe));
}

}  // namespace dart
