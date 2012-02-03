// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Object_toString, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->At(0));
  const char* c_str = instance.ToCString();
  arguments->SetReturn(String::Handle(String::New(c_str)));
}


DEFINE_NATIVE_ENTRY(Object_noSuchMethod, 3) {
  const Instance& instance = Instance::CheckedHandle(arguments->At(0));
  if (instance.IsNull()) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kNullPointer, args);
  }
  GET_NATIVE_ARGUMENT(String, function_name, arguments->At(1));
  GET_NATIVE_ARGUMENT(Array, func_args, arguments->At(2));
  GrowableArray<const Object*> dart_arguments(3);
  dart_arguments.Add(&instance);
  dart_arguments.Add(&function_name);
  dart_arguments.Add(&func_args);
  // Report if a function with same name (but different arguments) has been
  // found.
  Class& instance_class = Class::Handle(instance.clazz());
  Function& function =
      Function::Handle(instance_class.LookupDynamicFunction(function_name));
  while (function.IsNull()) {
    instance_class = instance_class.SuperClass();
    if (instance_class.IsNull()) break;
    function = instance_class.LookupDynamicFunction(function_name);
  }
  if (!function.IsNull()) {
    String& tmp = String::Handle();
    String& extra_message = String::Handle();
    tmp = String::NewSymbol("\nFound '");
    extra_message = String::Concat(tmp, function_name);
    tmp = String::NewSymbol("(");
    extra_message = String::Concat(extra_message, tmp);
    const int total_num_paramaters =
        function.num_fixed_parameters() + function.num_optional_parameters();
    // 0 is the receiver ('this'), skip it.
    for (int i = 1; i < total_num_paramaters; i++) {
      if (i > 1) {
        tmp = String::NewSymbol(", ");
        extra_message = String::Concat(extra_message, tmp);
      }
      tmp = function.ParameterNameAt(i);
      extra_message = String::Concat(extra_message, tmp);
    }
    tmp = String::NewSymbol(")'");
    extra_message = String::Concat(extra_message, tmp);
    dart_arguments.Add(&extra_message);
  }
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, dart_arguments);
}

}  // namespace dart
