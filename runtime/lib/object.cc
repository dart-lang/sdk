// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);


DEFINE_NATIVE_ENTRY(Object_toString, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const char* c_str = instance.ToCString();
  return String::New(c_str);
}


DEFINE_NATIVE_ENTRY(Object_noSuchMethod, 6) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, is_method, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, member_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, invocation_type, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, func_args, arguments->NativeArgAt(4));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, func_named_args, arguments->NativeArgAt(5));
  const Array& dart_arguments = Array::Handle(Array::New(6));
  dart_arguments.SetAt(0, instance);
  dart_arguments.SetAt(1, member_name);
  dart_arguments.SetAt(2, invocation_type);
  dart_arguments.SetAt(3, func_args);
  dart_arguments.SetAt(4, func_named_args);

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
      dart_arguments.SetAt(5, array);
    }
  }
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, dart_arguments);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Object_runtimeType, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Type& type = Type::Handle(instance.GetType());
  // The static type of null is specified to be the bottom type, however, the
  // runtime type of null is the Null type, which we correctly return here.
  return type.Canonicalize();
}


DEFINE_NATIVE_ENTRY(Object_instanceOf, 5) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  // Instantiator at position 1 is not used. It is passed along so that the call
  // can be easily converted to an optimized implementation. Instantiator is
  // used to populate the subtype cache.
  const AbstractTypeArguments& instantiator_type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(arguments->NativeArgAt(3));
  const Bool& negate = Bool::CheckedHandle(arguments->NativeArgAt(4));
  ASSERT(type.IsFinalized());
  Error& malformed_error = Error::Handle();
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &malformed_error);
  if (!is_instance_of && !malformed_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const intptr_t location = caller_frame->GetTokenPos();
    String& malformed_error_message = String::Handle(
        String::New(malformed_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, Symbols::Empty(), Symbols::Empty(),
        Symbols::Empty(), malformed_error_message);
    UNREACHABLE();
  }
  return Bool::Get(negate.value() ? !is_instance_of : is_instance_of);
}


DEFINE_NATIVE_ENTRY(Object_as, 4) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  // Instantiator at position 1 is not used. It is passed along so that the call
  // can be easily converted to an optimized implementation. Instantiator is
  // used to populate the subtype cache.
  const AbstractTypeArguments& instantiator_type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  Error& malformed_error = Error::Handle();
  if (instance.IsNull()) {
    return instance.raw();
  }
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &malformed_error);
  if (!is_instance_of) {
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const intptr_t location = caller_frame->GetTokenPos();
    const AbstractType& instance_type =
        AbstractType::Handle(instance.GetType());
    const String& instance_type_name =
        String::Handle(instance_type.UserVisibleName());
    String& type_name = String::Handle();
    if (!type.IsInstantiated()) {
      // Instantiate type before reporting the error.
      const AbstractType& instantiated_type = AbstractType::Handle(
          type.InstantiateFrom(instantiator_type_arguments, NULL));
      // Note that instantiated_type may be malformed.
      type_name = instantiated_type.UserVisibleName();
    } else {
      type_name = type.UserVisibleName();
    }
    String& malformed_error_message =  String::Handle();
    if (malformed_error.IsNull()) {
      const String& dst_name = String::ZoneHandle(
          Symbols::New(Exceptions::kCastErrorDstName));

      Exceptions::CreateAndThrowTypeError(
          location, instance_type_name, type_name,
          dst_name, String::Handle());
    } else {
      ASSERT(FLAG_enable_type_checks);
      malformed_error_message = String::New(malformed_error.ToErrorCString());
      Exceptions::CreateAndThrowTypeError(
          location, instance_type_name, Symbols::Empty(),
          Symbols::Empty(), malformed_error_message);
    }
    UNREACHABLE();
  }
  return instance.raw();
}


DEFINE_NATIVE_ENTRY(AbstractType_toString, 1) {
  const AbstractType& type =
      AbstractType::CheckedHandle(arguments->NativeArgAt(0));
  return type.UserVisibleName();
}

}  // namespace dart
