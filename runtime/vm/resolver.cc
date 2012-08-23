// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/resolver.h"

#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, trace_resolving, false, "Trace resolving.");


// The actual names of named arguments are not checked by the dynamic resolver,
// but by the method entry code. It is important that the dynamic resolver
// checks that no named arguments are passed to a method that does not accept
// them, since the entry code of such a method does not check for named
// arguments. The dynamic resolver actually checks that a valid number of named
// arguments is passed in.
RawFunction* Resolver::ResolveDynamic(const Instance& receiver,
                                      const String& function_name,
                                      int num_arguments,
                                      int num_named_arguments) {
  // Figure out type of receiver first.
  Class& cls = Class::Handle();
  cls = receiver.clazz();
  // For lookups treat null as an instance of class Object.
  if (cls.IsNullClass()) {
    cls = Isolate::Current()->object_store()->object_class();
  }
  ASSERT(!cls.IsNull());

  return ResolveDynamicForReceiverClass(
      cls, function_name, num_arguments, num_named_arguments);
}


RawFunction* Resolver::ResolveDynamicForReceiverClass(
    const Class& receiver_class,
    const String& function_name,
    int num_arguments,
    int num_named_arguments) {

  Function& function =
      Function::Handle(ResolveDynamicAnyArgs(receiver_class, function_name));

  if (function.IsNull() ||
      !function.AreValidArgumentCounts(num_arguments,
                                       num_named_arguments,
                                       NULL)) {
    // Return a null function to signal to the upper levels to dispatch to
    // "noSuchMethod" function.
    if (FLAG_trace_resolving) {
      String& error_message = String::Handle(String::New("function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArgumentCounts(num_arguments,
                                        num_named_arguments,
                                        &error_message);
      }
      OS::Print("ResolveDynamic error '%s': %s.\n",
                function_name.ToCString(),
                error_message.ToCString());
    }
    return Function::null();
  }
  return function.raw();
}


RawFunction* Resolver::ResolveDynamicAnyArgs(
    const Class& receiver_class,
    const String& function_name) {
  Class& cls = Class::Handle(receiver_class.raw());
  if (FLAG_trace_resolving) {
    OS::Print("ResolveDynamic '%s' for class %s\n",
              function_name.ToCString(),
              String::Handle(cls.Name()).ToCString());
  }
  // Now look for an instance function whose name matches function_name
  // in the class.
  Function& function =
      Function::Handle(cls.LookupDynamicFunction(function_name));
  while (function.IsNull()) {
    cls = cls.SuperClass();
    if (cls.IsNull()) break;
    function = cls.LookupDynamicFunction(function_name);
  }
  return function.raw();
}


RawFunction* Resolver::ResolveStatic(const Library& library,
                                     const String& class_name,
                                     const String& function_name,
                                     int num_arguments,
                                     const Array& argument_names,
                                     StaticResolveType resolve_type) {
  ASSERT(!library.IsNull());
  Function& function = Function::Handle();
  if (class_name.IsNull() || (class_name.Length() == 0)) {
    // Check if we are referring to a top level function.
    const Object& object = Object::Handle(library.LookupObject(function_name));
    if (!object.IsNull() && object.IsFunction()) {
      function ^= object.raw();
      if (!function.AreValidArguments(num_arguments, argument_names, NULL)) {
        if (FLAG_trace_resolving) {
          String& error_message = String::Handle();
          // Obtain more detailed error message.
          function.AreValidArguments(num_arguments,
                                     argument_names,
                                     &error_message);
          OS::Print("ResolveStatic error '%s': %s.\n",
                    function_name.ToCString(),
                    error_message.ToCString());
        }
        function = Function::null();
      }
    } else {
      if (FLAG_trace_resolving) {
        OS::Print("ResolveStatic error '%s': %s.\n",
                  function_name.ToCString(), "top level function not found");
      }
    }
  } else {
    // Lookup class_name in the library's class dictionary to get at
    // the dart class object. If class_name is not found in the dictionary
    // ResolveStatic will return a NULL function object.
    const Class& cls = Class::Handle(library.LookupClass(class_name));
    function = ResolveStatic(cls,
                             function_name,
                             num_arguments,
                             argument_names,
                             resolve_type);
  }
  return function.raw();
}


RawFunction* Resolver::ResolveStaticByName(const Class&  cls,
                                           const String& function_name,
                                           StaticResolveType resolve_type) {
  if (cls.IsNull()) {
    // Can't resolve function if cls is null.
    return Function::null();
  }

  if (FLAG_trace_resolving) {
    OS::Print("ResolveStatic '%s'\n", function_name.ToCString());
  }

  // Now look for a static function whose name matches function_name
  // in the class.
  Function& function =
      Function::Handle(cls.LookupStaticFunction(function_name));
  if (resolve_type == kNotQualified) {
    // Walk the hierarchy.
    Class& super_class = Class::Handle(cls.SuperClass());
    while (function.IsNull()) {
      function = super_class.LookupStaticFunction(function_name);
      super_class = super_class.SuperClass();
      if (super_class.IsNull()) break;
    }
  }
  return function.raw();
}



RawFunction* Resolver::ResolveStatic(const Class&  cls,
                                     const String& function_name,
                                     int num_arguments,
                                     const Array& argument_names,
                                     StaticResolveType resolve_type) {
  const Function& function = Function::Handle(
      ResolveStaticByName(cls, function_name, resolve_type));
  if (function.IsNull() ||
      !function.AreValidArguments(num_arguments, argument_names, NULL)) {
    // Return a null function to signal to the upper levels to throw a
    // resolution error or maybe throw the error right here.
    if (FLAG_trace_resolving) {
      String& error_message = String::Handle(String::New("function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArguments(num_arguments,
                                   argument_names,
                                   &error_message);
      }
      OS::Print("ResolveStatic error '%s': %s.\n",
                function_name.ToCString(),
                error_message.ToCString());
    }
    return Function::null();
  }
  return function.raw();
}

}  // namespace dart
