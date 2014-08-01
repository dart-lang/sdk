// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "lib/invocation_mirror.h"
#include "vm/code_patcher.h"
#include "vm/exceptions.h"
#include "vm/heap.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/report.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, trace_type_checks);
DECLARE_FLAG(bool, warn_on_javascript_compatibility);


DEFINE_NATIVE_ENTRY(Object_equals, 1) {
  // Implemented in the flow graph builder.
  UNREACHABLE();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Object_getHash, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  Heap* heap = isolate->heap();
  return Smi::New(heap->GetHash(instance.raw()));
}


DEFINE_NATIVE_ENTRY(Object_setHash, 2) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, hash, arguments->NativeArgAt(1));
  Heap* heap = isolate->heap();
  heap->SetHash(instance.raw(), hash.Value());
  return Object::null();
}


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

  if (is_method.value() &&
      (((invocation_type.Value() >> InvocationMirror::kCallShift) &
        InvocationMirror::kCallMask) != InvocationMirror::kSuper)) {
    // Report if a function with same name (but different arguments) has been
    // found.
    Function& function = Function::Handle();
    if (instance.IsClosure()) {
      function = Closure::function(instance);
    } else {
      Class& instance_class = Class::Handle(instance.clazz());
      function = instance_class.LookupDynamicFunction(member_name);
      while (function.IsNull()) {
        instance_class = instance_class.SuperClass();
        if (instance_class.IsNull()) break;
        function = instance_class.LookupDynamicFunction(member_name);
      }
    }
    if (!function.IsNull()) {
      const intptr_t total_num_parameters = function.NumParameters();
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
  // Special handling for following types outside this native.
  ASSERT(!instance.IsString() && !instance.IsInteger() && !instance.IsDouble());
  return instance.GetType();
}


static void WarnOnJSIntegralNumTypeTest(
    const Instance& instance,
    const TypeArguments& instantiator_type_arguments,
    const AbstractType& type) {
  const bool instance_is_int = instance.IsInteger();
  const bool instance_is_double = instance.IsDouble();
  if (!(instance_is_int || instance_is_double)) {
    return;
  }
  AbstractType& instantiated_type = AbstractType::Handle(type.raw());
  if (!type.IsInstantiated()) {
    instantiated_type = type.InstantiateFrom(instantiator_type_arguments, NULL);
  }
  if (instance_is_double) {
    if (instantiated_type.IsIntType()) {
      const double value = Double::Cast(instance).value();
      if (floor(value) == value) {
        Report::JSWarningFromNative(
            false,  // Object_instanceOf and Object_as are not static calls.
            "integral value of type 'double' is also considered to be "
            "of type 'int'");
      }
    }
  } else {
    ASSERT(instance_is_int);
    if (instantiated_type.IsDoubleType()) {
      Report::JSWarningFromNative(
          false,  // Object_instanceOf and Object_as are not static calls.
          "integer value is also considered to be of type 'double'");
    }
  }
}


DEFINE_NATIVE_ENTRY(Object_instanceOf, 5) {
  const Instance& instance =
      Instance::CheckedHandle(isolate, arguments->NativeArgAt(0));
  // Instantiator at position 1 is not used. It is passed along so that the call
  // can be easily converted to an optimized implementation. Instantiator is
  // used to populate the subtype cache.
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(isolate, arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(isolate, arguments->NativeArgAt(3));
  const Bool& negate = Bool::CheckedHandle(isolate, arguments->NativeArgAt(4));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());

  // Check for javascript compatibility.
  if (FLAG_warn_on_javascript_compatibility) {
    WarnOnJSIntegralNumTypeTest(instance, instantiator_type_arguments, type);
  }

  Error& bound_error = Error::Handle(isolate, Error::null());
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Native Object.instanceOf: result %s\n", result_str);
    const Type& instance_type = Type::Handle(instance.GetType());
    OS::Print("  instance type: %s\n",
              String::Handle(instance_type.Name()).ToCString());
    OS::Print("  test type: %s\n", String::Handle(type.Name()).ToCString());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
  if (!is_instance_of && !bound_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const intptr_t location = caller_frame->GetTokenPos();
    String& bound_error_message = String::Handle(
        isolate, String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, Symbols::Empty(), Symbols::Empty(),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  return Bool::Get(negate.value() ? !is_instance_of : is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_as, 4) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  // Instantiator at position 1 is not used. It is passed along so that the call
  // can be easily converted to an optimized implementation. Instantiator is
  // used to populate the subtype cache.
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle();
  if (instance.IsNull()) {
    return instance.raw();
  }

  // Check for javascript compatibility.
  if (FLAG_warn_on_javascript_compatibility) {
    WarnOnJSIntegralNumTypeTest(instance, instantiator_type_arguments, type);
  }

  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Object.as: result %s\n", result_str);
    const Type& instance_type = Type::Handle(instance.GetType());
    OS::Print("  instance type: %s\n",
              String::Handle(instance_type.Name()).ToCString());
    OS::Print("  cast type: %s\n", String::Handle(type.Name()).ToCString());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
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
    String& bound_error_message =  String::Handle();
    if (bound_error.IsNull()) {
      const String& dst_name = String::ZoneHandle(
          Symbols::New(Exceptions::kCastErrorDstName));

      Exceptions::CreateAndThrowTypeError(
          location, instance_type_name, type_name,
          dst_name, Object::null_string());
    } else {
      ASSERT(FLAG_enable_type_checks);
      bound_error_message = String::New(bound_error.ToErrorCString());
      Exceptions::CreateAndThrowTypeError(
          location, instance_type_name, Symbols::Empty(),
          Symbols::Empty(), bound_error_message);
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


DEFINE_NATIVE_ENTRY(LibraryPrefix_invalidateDependentCode, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(arguments->NativeArgAt(0));
  prefix.InvalidateDependentCode();
  return Bool::Get(true).raw();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_load, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(arguments->NativeArgAt(0));
  bool hasCompleted = prefix.LoadLibrary();
  return Bool::Get(hasCompleted).raw();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_loadError, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(arguments->NativeArgAt(0));
  // Currently all errors are Dart instances, e.g. I/O errors
  // created by deferred loading code. LanguageErrors from
  // failed loading or finalization attempts are propagated and result
  // in the isolate's death.
  const Instance& error = Instance::Handle(prefix.LoadError());
  return error.raw();
}


}  // namespace dart
