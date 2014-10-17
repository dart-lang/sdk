// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/resolver.h"

#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

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
                                      const ArgumentsDescriptor& args_desc) {
  // Figure out type of receiver first.
  const Class& cls = Class::Handle(receiver.clazz());
  return ResolveDynamicForReceiverClass(cls, function_name, args_desc);
}


RawFunction* Resolver::ResolveDynamicForReceiverClass(
    const Class& receiver_class,
    const String& function_name,
    const ArgumentsDescriptor& args_desc) {

  Function& function =
      Function::Handle(ResolveDynamicAnyArgs(receiver_class, function_name));

  if (function.IsNull() ||
      !function.AreValidArguments(args_desc, NULL)) {
    // Return a null function to signal to the upper levels to dispatch to
    // "noSuchMethod" function.
    if (FLAG_trace_resolving) {
      String& error_message = String::Handle(String::New("function not found"));
      if (!function.IsNull()) {
        // Obtain more detailed error message.
        function.AreValidArguments(args_desc, &error_message);
      }
      OS::Print("ResolveDynamic error '%s': %s.\n",
                function_name.ToCString(),
                error_message.ToCString());
    }
    return Function::null();
  }
  return function.raw();
}


// Method extractors are used to create implicit closures from methods.
// When an expression obj.M is evaluated for the first time and receiver obj
// does not have a getter called M but has a method called M then an extractor
// is created and injected as a getter (under the name get:M) into the class
// owning method M.
static RawFunction* CreateMethodExtractor(const String& getter_name,
                                          const Function& method) {
  const Function& closure_function =
      Function::Handle(method.ImplicitClosureFunction());

  const Class& owner = Class::Handle(closure_function.Owner());
  Function& extractor = Function::Handle(
    Function::New(String::Handle(Symbols::New(getter_name)),
                  RawFunction::kMethodExtractor,
                  false,  // Not static.
                  false,  // Not const.
                  false,  // Not abstract.
                  false,  // Not external.
                  false,  // Not native.
                  owner,
                  0));  // No token position.

  // Initialize signature: receiver is a single fixed parameter.
  const intptr_t kNumParameters = 1;
  extractor.set_num_fixed_parameters(kNumParameters);
  extractor.SetNumOptionalParameters(0, 0);
  extractor.set_parameter_types(Object::extractor_parameter_types());
  extractor.set_parameter_names(Object::extractor_parameter_names());
  extractor.set_result_type(Type::Handle(Type::DynamicType()));

  extractor.set_extracted_method_closure(closure_function);

  owner.AddFunction(extractor);

  return extractor.raw();
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

  const bool is_getter = Field::IsGetterName(function_name);
  String& field_name = String::Handle();
  if (is_getter) {
    field_name ^= Field::NameFromGetter(function_name);
  }

  // Now look for an instance function whose name matches function_name
  // in the class.
  Function& function = Function::Handle();
  while (!cls.IsNull()) {
    function ^= cls.LookupDynamicFunction(function_name);
    if (!function.IsNull()) {
      return function.raw();
    }
    // Getter invocation might actually be a method extraction.
    if (is_getter && function.IsNull()) {
      function ^= cls.LookupDynamicFunction(field_name);
      if (!function.IsNull()) {
        // We were looking for the getter but found a method with the same name.
        // Create a method extractor and return it.
        function ^= CreateMethodExtractor(function_name, function);
        return function.raw();
      }
    }
    cls = cls.SuperClass();
  }
  return function.raw();
}


RawFunction* Resolver::ResolveStatic(const Library& library,
                                     const String& class_name,
                                     const String& function_name,
                                     intptr_t num_arguments,
                                     const Array& argument_names) {
  ASSERT(!library.IsNull());
  Function& function = Function::Handle();
  if (class_name.IsNull() || (class_name.Length() == 0)) {
    // Check if we are referring to a top level function.
    const Object& object = Object::Handle(library.ResolveName(function_name));
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
        OS::Print("ResolveStatic error: function '%s' not found.\n",
                  function_name.ToCString());
      }
    }
  } else {
    // Lookup class_name in the library's class dictionary to get at
    // the dart class object. If class_name is not found in the dictionary
    // ResolveStatic will return a NULL function object.
    const Class& cls = Class::Handle(library.LookupClass(class_name));
    if (!cls.IsNull()) {
      function = ResolveStatic(cls,
                               function_name,
                               num_arguments,
                               argument_names);
    }
    if (FLAG_trace_resolving && function.IsNull()) {
      OS::Print("ResolveStatic error: function '%s.%s' not found.\n",
                class_name.ToCString(),
                function_name.ToCString());
    }
  }
  return function.raw();
}


RawFunction* Resolver::ResolveStatic(const Class&  cls,
                                     const String& function_name,
                                     intptr_t num_arguments,
                                     const Array& argument_names) {
  ASSERT(!cls.IsNull());
  if (FLAG_trace_resolving) {
    OS::Print("ResolveStatic '%s'\n", function_name.ToCString());
  }
  const Function& function =
      Function::Handle(cls.LookupStaticFunction(function_name));
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
