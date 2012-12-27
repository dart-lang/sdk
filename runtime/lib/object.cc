// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Object_toString, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const char* c_str = instance.ToCString();
  return String::New(c_str);
}


DEFINE_NATIVE_ENTRY(Object_noSuchMethod, 5) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, is_method, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, member_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, func_args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, func_named_args, arguments->NativeArgAt(4));
  const Array& dart_arguments = Array::Handle(Array::New(5));
  dart_arguments.SetAt(0, instance);
  dart_arguments.SetAt(1, member_name);
  dart_arguments.SetAt(2, func_args);
  dart_arguments.SetAt(3, func_named_args);

  if (is_method.value()) {
    // Report if a function with same name (but different arguments) has been
    // found.
    Class& instance_class = Class::Handle(instance.clazz());
    Function& function =
        Function::Handle(instance_class.LookupDynamicFunction(member_name));
    while (function.IsNull()) {
      instance_class = instance_class.SuperClass();
      if (instance_class.IsNull()) break;
      function = instance_class.LookupDynamicFunction(member_name);
    }
    if (!function.IsNull()) {
      const int total_num_parameters = function.NumParameters();
      const Array& array = Array::Handle(Array::New(total_num_parameters - 1));
      // Skip receiver.
      for (int i = 1; i < total_num_parameters; i++) {
        array.SetAt(i - 1, String::Handle(function.ParameterNameAt(i)));
      }
      dart_arguments.SetAt(4, array);
    }
  }
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, dart_arguments);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Object_runtimeType, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Type& type = Type::Handle(instance.GetType());
  return type.Canonicalize();
}


DEFINE_NATIVE_ENTRY(AbstractType_toString, 1) {
  const AbstractType& type =
      AbstractType::CheckedHandle(arguments->NativeArgAt(0));
  return type.UserVisibleName();
}

}  // namespace dart
