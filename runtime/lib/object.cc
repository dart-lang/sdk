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
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, trace_type_checks);

// Helper function in stacktrace.cc.
void _printCurrentStacktrace();

DEFINE_NATIVE_ENTRY(DartCore_fatal, 1) {
  // The core library code entered an unrecoverable state.
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const char* msg = instance.ToCString();
  OS::PrintErr("Fatal error in dart:core\n");
  _printCurrentStacktrace();
  FATAL(msg);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Object_equals, 1) {
  // Implemented in the flow graph builder.
  UNREACHABLE();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Object_getHash, 1) {
  // Please note that no handle is created for the argument.
  // This is safe since the argument is only used in a tail call.
  // The performance benefit is more than 5% when using hashCode.
  Heap* heap = isolate->heap();
  ASSERT(arguments->NativeArgAt(0)->IsDartInstance());
  return Smi::New(heap->GetHash(arguments->NativeArgAt(0)));
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
  if (instance.IsString()) {
    return instance.raw();
  }
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
      function = Closure::Cast(instance).function();
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


DEFINE_NATIVE_ENTRY(Object_instanceOf, 4) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(2));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle(zone, Error::null());
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Native Object.instanceOf: result %s\n", result_str);
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType());
    OS::Print("  instance type: %s\n",
              String::Handle(zone, instance_type.Name()).ToCString());
    OS::Print("  test type: %s\n",
              String::Handle(zone, type.Name()).ToCString());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
  if (!is_instance_of && !bound_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    String& bound_error_message = String::Handle(
        zone, String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, AbstractType::Handle(zone), AbstractType::Handle(zone),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  return Bool::Get(negate.value() ? !is_instance_of : is_instance_of).raw();
}

DEFINE_NATIVE_ENTRY(Object_simpleInstanceOf, 2) {
  // This native is only called when the right hand side passes
  // simpleInstanceOfType and it is a non-negative test.
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::Handle(TypeArguments::null());
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle(zone, Error::null());
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &bound_error);
  if (!is_instance_of && !bound_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    String& bound_error_message = String::Handle(
        zone, String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(
        location, AbstractType::Handle(zone), AbstractType::Handle(zone),
        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  return Bool::Get(is_instance_of).raw();
}

DEFINE_NATIVE_ENTRY(Object_instanceOfNum, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool is_instance_of = instance.IsNumber();
  if (negate.value()) {
    is_instance_of = !is_instance_of;
  }
  return Bool::Get(is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_instanceOfInt, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool is_instance_of = instance.IsInteger();
  if (negate.value()) {
    is_instance_of = !is_instance_of;
  }
  return Bool::Get(is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_instanceOfSmi, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool is_instance_of = instance.IsSmi();
  if (negate.value()) {
    is_instance_of = !is_instance_of;
  }
  return Bool::Get(is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_instanceOfDouble, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool is_instance_of = instance.IsDouble();
  if (negate.value()) {
    is_instance_of = !is_instance_of;
  }
  return Bool::Get(is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_instanceOfString, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Bool& negate = Bool::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool is_instance_of = instance.IsString();
  if (negate.value()) {
    is_instance_of = !is_instance_of;
  }
  return Bool::Get(is_instance_of).raw();
}


DEFINE_NATIVE_ENTRY(Object_as, 3) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(2));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle(zone);
  if (instance.IsNull()) {
    return instance.raw();
  }
  const bool is_instance_of = instance.IsInstanceOf(type,
                                                    instantiator_type_arguments,
                                                    &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Object.as: result %s\n", result_str);
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType());
    OS::Print("  instance type: %s\n",
              String::Handle(zone, instance_type.Name()).ToCString());
    OS::Print("  cast type: %s\n",
              String::Handle(zone, type.Name()).ToCString());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
  if (!is_instance_of) {
    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType());
    if (!type.IsInstantiated()) {
      // Instantiate type before reporting the error.
      type = type.InstantiateFrom(instantiator_type_arguments, NULL,
                                  NULL, NULL, Heap::kNew);
      // Note that the instantiated type may be malformed.
    }
    if (bound_error.IsNull()) {
      Exceptions::CreateAndThrowTypeError(
          location, instance_type, type,
          Symbols::InTypeCast(), Object::null_string());
    } else {
      ASSERT(isolate->type_checks());
      const String& bound_error_message =
          String::Handle(zone, String::New(bound_error.ToErrorCString()));
      Exceptions::CreateAndThrowTypeError(
          location, instance_type, AbstractType::Handle(zone),
          Symbols::Empty(), bound_error_message);
    }
    UNREACHABLE();
  }
  return instance.raw();
}


DEFINE_NATIVE_ENTRY(AbstractType_toString, 1) {
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(0));
  return type.UserVisibleName();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_invalidateDependentCode, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  prefix.InvalidateDependentCode();
  return Bool::Get(true).raw();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_load, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  bool hasCompleted = prefix.LoadLibrary();
  return Bool::Get(hasCompleted).raw();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_loadError, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  // Currently all errors are Dart instances, e.g. I/O errors
  // created by deferred loading code. LanguageErrors from
  // failed loading or finalization attempts are propagated and result
  // in the isolate's death.
  const Instance& error = Instance::Handle(zone, prefix.LoadError());
  return error.raw();
}


DEFINE_NATIVE_ENTRY(LibraryPrefix_isLoaded, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Bool::Get(prefix.is_loaded()).raw();
}


DEFINE_NATIVE_ENTRY(Internal_inquireIs64Bit, 0) {
#if defined(ARCH_IS_64_BIT)
  return Bool::True().raw();
#else
  return Bool::False().raw();
#endif  // defined(ARCH_IS_64_BIT)
}

}  // namespace dart
