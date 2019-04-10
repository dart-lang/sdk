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

// Find the target of an instance call, which might be
// - a user-defined method
// - a method extractor (getter call to user-defined regular method)
// - an invoke field dispatcher (regular method call to user-defined getter)
// - a dynamic invocation forwarder (dynamic call to one of the above)
// - a no-such-method dispatcher (no target or target with wrong number of
//   positional arguments)
//
// Positional arguments are checked here: the number of positional arguments
// doesn't match the target, a no-such-method-dispatcher will be returned.
// Named arguments are checked in the target's prologue.
RawFunction* Resolver::ResolveDynamic(const Instance& receiver,
                                      const String& function_name,
                                      const ArgumentsDescriptor& args_desc) {
  const Class& cls = Class::Handle(receiver.clazz());
  return ResolveDynamicForReceiverClass(cls, function_name, args_desc);
}

RawFunction* Resolver::ResolveDynamicForReceiverClass(
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc,
    bool allow_add) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  if (FLAG_trace_resolving) {
    THR_Print("ResolveDynamic '%s' for class %s\n", function_name.ToCString(),
              String::Handle(zone, receiver_class.Name()).ToCString());
  }

  Function& function = Function::Handle(
      zone, ResolveDynamicAnyArgs(zone, receiver_class, function_name,
                                  args_desc, allow_add));

  if (function.IsNull() || !function.AreValidArguments(args_desc, NULL)) {
    if (FLAG_lazy_dispatchers) {
      String& demangled = String::Handle(zone);
      if (Function::IsDynamicInvocationForwarderName(function_name)) {
        demangled =
            Function::DemangleDynamicInvocationForwarderName(function_name);
      } else {
        demangled = function_name.raw();
      }
      function = receiver_class.GetInvocationDispatcher(
          demangled, args_desc.array(), RawFunction::kNoSuchMethodDispatcher,
          allow_add);
      if (!function.IsNull()) {
        function.set_is_reflectable(true);
      }
    } else {
      function = Function::null();
    }
  }

  // FLAG_lazy_dispatchers && allow_add -> !function.IsNull()
  ASSERT(!function.IsNull() || !FLAG_lazy_dispatchers || !allow_add);

  if (FLAG_trace_resolving) {
    THR_Print("ResolveDynamic result: %s\n", function.ToCString());
  }

  return function.raw();
}

RawFunction* Resolver::ResolveDynamicAnyArgs(
    Zone* zone,
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc,
    bool allow_add) {
  Class& cls = Class::Handle(zone, receiver_class.raw());
  String& demangled = String::Handle(zone);
  Function& function = Function::Handle(zone);
  if (Function::IsDynamicInvocationForwarderName(function_name)) {
    demangled ^=
        Function::DemangleDynamicInvocationForwarderName(function_name);
#ifdef DART_PRECOMPILED_RUNTIME
    // In precompiled mode, the non-dynamic version of the function may be
    // tree-shaken away, so can't necessarily resolve the demanged name.
    while (!cls.IsNull()) {
      function = cls.GetInvocationDispatcher(
          function_name, Array::null_array(),
          RawFunction::kDynamicInvocationForwarder, /*create_if_absent=*/false);
      if (!function.IsNull()) break;
      cls = cls.SuperClass();
    }
    // Some functions don't require dynamic invocation forwarders, for example
    // if there are no parameters or all the parameters are marked
    // `generic-covariant` (meaning there's no work for the dynamic invocation
    // forwarder to do, see `kernel::DynamicInvocationForwarder`). For these
    // functions, we won't have built a `dyn:` version, but it's safe to just
    // return the original version directly.
    return !function.IsNull()
               ? function.raw()
               : ResolveDynamicAnyArgs(zone, receiver_class, demangled,
                                       args_desc, allow_add);
#else
    function = ResolveDynamicAnyArgs(zone, receiver_class, demangled, args_desc,
                                     allow_add);

    if (function.IsNull() || !function.AreValidArguments(args_desc, NULL)) {
      return Function::null();
    }

    return function.GetDynamicInvocationForwarder(function_name, allow_add);
#endif
  }

  const bool is_getter = Field::IsGetterName(function_name);
  const bool is_setter = Field::IsSetterName(function_name);
  if (is_getter) {
    demangled = Field::NameFromGetter(function_name);
  } else if (!is_setter) {
    demangled = Field::GetterSymbol(function_name);
  }

  // Now look for an instance function whose name matches function_name
  // in the class.
  while (!cls.IsNull()) {
    function = cls.LookupDynamicFunction(function_name);
    if (!function.IsNull()) {
      return function.raw();
    }
    if (is_getter) {
      // Getter invocation might actually be a method extraction.
      ASSERT(!Field::IsGetterName(demangled));
      function = cls.LookupDynamicFunction(demangled);
      if (!function.IsNull()) {
        if (FLAG_lazy_dispatchers && allow_add) {
          return function.CreateMethodExtractor(function_name);
        } else {
          return Function::null();
        }
      }
    } else if (!is_setter) {
      // Regular invocation might actually be call-through-getter.
      ASSERT(Field::IsGetterName(demangled));
      function = cls.LookupDynamicFunction(demangled);
      if (!function.IsNull()) {
        if (FLAG_lazy_dispatchers && allow_add) {
          bool is_reflectable = function.is_reflectable();
          function = cls.GetInvocationDispatcher(
              function_name, args_desc.array(),
              RawFunction::kInvokeFieldDispatcher, allow_add);
          function.set_is_reflectable(is_reflectable);
          return function.raw();
        } else {
          return Function::null();
        }
      }
    }
    cls = cls.SuperClass();
  }

  return Function::null();
}

bool Resolver::HasDefinition(Zone* zone,
                             const Class& receiver_class,
                             const String& function_name) {
  String& demangled = String::Handle(zone);
  if (Function::IsDynamicInvocationForwarderName(function_name)) {
    demangled = Function::DemangleDynamicInvocationForwarderName(function_name);
    return HasDefinition(zone, receiver_class, demangled);
  }

  const bool is_getter = Field::IsGetterName(function_name);
  const bool is_setter = Field::IsSetterName(function_name);
  if (is_getter) {
    demangled = Field::NameFromGetter(function_name);
  } else if (!is_setter) {
    demangled = Field::GetterSymbol(function_name);
  }

  Class& cls = Class::Handle(zone, receiver_class.raw());
  Function& function = Function::Handle(zone);

  // Now look for an instance function whose name matches function_name
  // in the class.
  while (!cls.IsNull()) {
    function = cls.LookupDynamicFunction(function_name);
    if (!function.IsNull()) {
      return true;
    }
    if (is_getter) {
      // Getter invocation might actually be a method extraction.
      ASSERT(!Field::IsGetterName(demangled));
      function = cls.LookupDynamicFunction(demangled);
      if (!function.IsNull()) {
        return true;
      }
    } else if (!is_setter) {
      // Regular invocation might actually be call-through-getter.
      ASSERT(Field::IsGetterName(demangled));
      function = cls.LookupDynamicFunction(demangled);
      if (!function.IsNull()) {
        return true;
      }
    }
    cls = cls.SuperClass();
  }

  // NoSuchMethod
  return false;
}

RawFunction* Resolver::ResolveStatic(const Library& library,
                                     const String& class_name,
                                     const String& function_name,
                                     intptr_t type_args_len,
                                     intptr_t num_arguments,
                                     const Array& argument_names) {
  ASSERT(!library.IsNull());
  Function& function = Function::Handle();
  if (class_name.IsNull() || (class_name.Length() == 0)) {
    // Check if we are referring to a top level function.
    const Object& object = Object::Handle(library.ResolveName(function_name));
    if (!object.IsNull() && object.IsFunction()) {
      function ^= object.raw();
      if (!function.AreValidArguments(type_args_len, num_arguments,
                                      argument_names, NULL)) {
        if (FLAG_trace_resolving) {
          String& error_message = String::Handle();
          // Obtain more detailed error message.
          function.AreValidArguments(type_args_len, num_arguments,
                                     argument_names, &error_message);
          THR_Print("ResolveStatic error '%s': %s.\n",
                    function_name.ToCString(), error_message.ToCString());
        }
        function = Function::null();
      }
    } else {
      if (FLAG_trace_resolving) {
        THR_Print("ResolveStatic error: function '%s' not found.\n",
                  function_name.ToCString());
      }
    }
  } else {
    // Lookup class_name in the library's class dictionary to get at
    // the dart class object. If class_name is not found in the dictionary
    // ResolveStatic will return a NULL function object.
    const Class& cls = Class::Handle(library.LookupClass(class_name));
    if (!cls.IsNull()) {
      function = ResolveStatic(cls, function_name, type_args_len, num_arguments,
                               argument_names);
    }
    if (FLAG_trace_resolving && function.IsNull()) {
      THR_Print("ResolveStatic error: function '%s.%s' not found.\n",
                class_name.ToCString(), function_name.ToCString());
    }
  }
  return function.raw();
}

RawFunction* Resolver::ResolveStatic(const Class& cls,
                                     const String& function_name,
                                     intptr_t type_args_len,
                                     intptr_t num_arguments,
                                     const Array& argument_names) {
  ASSERT(!cls.IsNull());
  if (FLAG_trace_resolving) {
    THR_Print("ResolveStatic '%s'\n", function_name.ToCString());
  }
  const Function& function =
      Function::Handle(cls.LookupStaticFunction(function_name));
  if (function.IsNull() ||
      !function.AreValidArguments(type_args_len, num_arguments, argument_names,
                                  NULL)) {
    // Return a null function to signal to the upper levels to throw a
    // resolution error or maybe throw the error right here.
    if (FLAG_trace_resolving) {
      String& error_message = String::Handle(String::New("function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArguments(type_args_len, num_arguments, argument_names,
                                   &error_message);
      }
      THR_Print("ResolveStatic error '%s': %s.\n", function_name.ToCString(),
                error_message.ToCString());
    }
    return Function::null();
  }
  return function.raw();
}

RawFunction* Resolver::ResolveStaticAllowPrivate(const Class& cls,
                                                 const String& function_name,
                                                 intptr_t type_args_len,
                                                 intptr_t num_arguments,
                                                 const Array& argument_names) {
  ASSERT(!cls.IsNull());
  if (FLAG_trace_resolving) {
    THR_Print("ResolveStaticAllowPrivate '%s'\n", function_name.ToCString());
  }
  const Function& function =
      Function::Handle(cls.LookupStaticFunctionAllowPrivate(function_name));
  if (function.IsNull() ||
      !function.AreValidArguments(type_args_len, num_arguments, argument_names,
                                  NULL)) {
    // Return a null function to signal to the upper levels to throw a
    // resolution error or maybe throw the error right here.
    if (FLAG_trace_resolving) {
      String& error_message = String::Handle(String::New("function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArguments(type_args_len, num_arguments, argument_names,
                                   &error_message);
      }
      THR_Print("ResolveStaticAllowPrivate error '%s': %s.\n",
                function_name.ToCString(), error_message.ToCString());
    }
    return Function::null();
  }
  return function.raw();
}

}  // namespace dart
