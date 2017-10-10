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

DEFINE_NATIVE_ENTRY(DartAsync_fatal, 1) {
  // The dart:async library code entered an unrecoverable state.
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const char* msg = instance.ToCString();
  OS::PrintErr("Fatal error in dart:async: %s\n", msg);
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
#if defined(HASH_IN_OBJECT_HEADER)
  return Smi::New(Object::GetCachedHash(arguments->NativeArgAt(0)));
#else
  Heap* heap = isolate->heap();
  ASSERT(arguments->NativeArgAt(0)->IsDartInstance());
  return Smi::New(heap->GetHash(arguments->NativeArgAt(0)));
#endif
}

DEFINE_NATIVE_ENTRY(Object_setHash, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, hash, arguments->NativeArgAt(1));
#if defined(HASH_IN_OBJECT_HEADER)
  Object::SetCachedHash(arguments->NativeArgAt(0), hash.Value());
#else
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  Heap* heap = isolate->heap();
  heap->SetHash(instance.raw(), hash.Value());
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Object_toString, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  if (instance.IsString()) {
    return instance.raw();
  }
  if (instance.IsAbstractType()) {
    return AbstractType::Cast(instance).UserVisibleName();
  }
  const char* c_str = instance.ToCString();
  return String::New(c_str);
}

DEFINE_NATIVE_ENTRY(Object_runtimeType, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->NativeArgAt(0));
  if (instance.IsString()) {
    return Type::StringType();
  } else if (instance.IsInteger()) {
    return Type::IntType();
  } else if (instance.IsDouble()) {
    return Type::Double();
  }
  return instance.GetType(Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Object_haveSameRuntimeType, 2) {
  const Instance& left = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Instance& right = Instance::CheckedHandle(arguments->NativeArgAt(1));

  const intptr_t left_cid = left.GetClassId();
  const intptr_t right_cid = right.GetClassId();

  if (left_cid != right_cid) {
    if (RawObject::IsIntegerClassId(left_cid)) {
      return Bool::Get(RawObject::IsIntegerClassId(right_cid)).raw();
    } else if (RawObject::IsStringClassId(right_cid)) {
      return Bool::Get(RawObject::IsStringClassId(right_cid)).raw();
    } else {
      return Bool::False().raw();
    }
  }

  const Class& cls = Class::Handle(left.clazz());
  if (cls.IsClosureClass()) {
    // TODO(vegorov): provide faster implementation for closure classes.
    const AbstractType& left_type =
        AbstractType::Handle(left.GetType(Heap::kNew));
    const AbstractType& right_type =
        AbstractType::Handle(right.GetType(Heap::kNew));
    return Bool::Get(left_type.raw() == right_type.raw()).raw();
  }

  if (!cls.IsGeneric()) {
    return Bool::True().raw();
  }

  const TypeArguments& left_type_arguments =
      TypeArguments::Handle(left.GetTypeArguments());
  const TypeArguments& right_type_arguments =
      TypeArguments::Handle(right.GetTypeArguments());
  return Bool::Get(left_type_arguments.Equals(right_type_arguments)).raw();
}

DEFINE_NATIVE_ENTRY(Object_instanceOf, 4) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle(zone, Error::null());
  const bool is_instance_of = instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments, &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Native Object.instanceOf: result %s\n", result_str);
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType(Heap::kNew));
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
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    String& bound_error_message =
        String::Handle(zone, String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(location, AbstractType::Handle(zone),
                                        AbstractType::Handle(zone),
                                        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  return Bool::Get(is_instance_of).raw();
}

DEFINE_NATIVE_ENTRY(Object_simpleInstanceOf, 2) {
  // This native is only called when the right hand side passes
  // SimpleInstanceOfType and it is a non-negative test.
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(1));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  ASSERT(type.IsInstantiated());
  Error& bound_error = Error::Handle(zone, Error::null());
  const bool is_instance_of =
      instance.IsInstanceOf(type, Object::null_type_arguments(),
                            Object::null_type_arguments(), &bound_error);
  if (!is_instance_of && !bound_error.IsNull()) {
    // Throw a dynamic type error only if the instanceof test fails.
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    String& bound_error_message =
        String::Handle(zone, String::New(bound_error.ToErrorCString()));
    Exceptions::CreateAndThrowTypeError(location, AbstractType::Handle(zone),
                                        AbstractType::Handle(zone),
                                        Symbols::Empty(), bound_error_message);
    UNREACHABLE();
  }
  return Bool::Get(is_instance_of).raw();
}

DEFINE_NATIVE_ENTRY(Object_as, 4) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(2));
  AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsMalformed());
  ASSERT(!type.IsMalbounded());
  Error& bound_error = Error::Handle(zone);
  const bool is_instance_of =
      instance.IsNull() ||
      instance.IsInstanceOf(type, instantiator_type_arguments,
                            function_type_arguments, &bound_error);
  if (FLAG_trace_type_checks) {
    const char* result_str = is_instance_of ? "true" : "false";
    OS::Print("Object.as: result %s\n", result_str);
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType(Heap::kNew));
    OS::Print("  instance type: %s\n",
              String::Handle(zone, instance_type.Name()).ToCString());
    OS::Print("  cast type: %s\n",
              String::Handle(zone, type.Name()).ToCString());
    if (!bound_error.IsNull()) {
      OS::Print("  bound error: %s\n", bound_error.ToErrorCString());
    }
  }
  if (!is_instance_of) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != NULL);
    const TokenPosition location = caller_frame->GetTokenPos();
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType(Heap::kNew));
    if (!type.IsInstantiated()) {
      // Instantiate type before reporting the error.
      type = type.InstantiateFrom(instantiator_type_arguments,
                                  function_type_arguments, NULL, NULL, NULL,
                                  Heap::kNew);
      // Note that the instantiated type may be malformed.
    }
    if (bound_error.IsNull()) {
      Exceptions::CreateAndThrowTypeError(location, instance_type, type,
                                          Symbols::InTypeCast(),
                                          Object::null_string());
    } else {
      ASSERT(isolate->type_checks());
      const String& bound_error_message =
          String::Handle(zone, String::New(bound_error.ToErrorCString()));
      Exceptions::CreateAndThrowTypeError(
          location, instance_type, AbstractType::Handle(zone), Symbols::Empty(),
          bound_error_message);
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

DEFINE_NATIVE_ENTRY(Type_getHashCode, 1) {
  const Type& type = Type::CheckedHandle(zone, arguments->NativeArgAt(0));
  intptr_t hash_val = type.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
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

DEFINE_NATIVE_ENTRY(Internal_prependTypeArguments, 3) {
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& parent_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  if (function_type_arguments.IsNull() && parent_type_arguments.IsNull()) {
    return TypeArguments::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_len, arguments->NativeArgAt(2));
  const intptr_t len = smi_len.Value();
  const TypeArguments& result =
      TypeArguments::Handle(zone, TypeArguments::New(len, Heap::kNew));
  AbstractType& type = AbstractType::Handle(zone);
  const intptr_t split = parent_type_arguments.IsNull()
                             ? len - function_type_arguments.Length()
                             : parent_type_arguments.Length();
  for (intptr_t i = 0; i < split; i++) {
    type = parent_type_arguments.IsNull() ? Type::DynamicType()
                                          : parent_type_arguments.TypeAt(i);
    result.SetTypeAt(i, type);
  }
  for (intptr_t i = split; i < len; i++) {
    type = function_type_arguments.IsNull()
               ? Type::DynamicType()
               : function_type_arguments.TypeAt(i - split);
    result.SetTypeAt(i, type);
  }
  return result.Canonicalize();
}

DEFINE_NATIVE_ENTRY(InvocationMirror_unpackTypeArguments, 1) {
  const TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0));
  const intptr_t len = type_arguments.Length();
  ASSERT(len > 0);
  const Array& type_list = Array::Handle(zone, Array::New(len));
  TypeArguments& type_list_type_args =
      TypeArguments::Handle(zone, TypeArguments::New(1));
  type_list_type_args.SetTypeAt(0, Type::Handle(zone, Type::DartTypeType()));
  type_list_type_args = type_list_type_args.Canonicalize();
  type_list.SetTypeArguments(type_list_type_args);
  AbstractType& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    type = type_arguments.TypeAt(i);
    type_list.SetAt(i, type);
  }
  type_list.MakeImmutable();
  return type_list.raw();
}

DEFINE_NATIVE_ENTRY(NoSuchMethodError_existingMethodSignature, 3) {
  const Instance& receiver = Instance::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, method_name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, invocation_type, arguments->NativeArgAt(2));
  InvocationMirror::Level level;
  InvocationMirror::Kind kind;
  InvocationMirror::DecodeType(invocation_type.Value(), &level, &kind);

  Function& function = Function::Handle();
  if (receiver.IsType()) {
    Class& cls = Class::Handle(Type::Cast(receiver).type_class());
    if (level == InvocationMirror::kConstructor) {
      function = cls.LookupConstructor(method_name);
      if (function.IsNull()) {
        function = cls.LookupFactory(method_name);
      }
    } else {
      function = cls.LookupStaticFunction(method_name);
    }
  } else if (receiver.IsClosure()) {
    function = Closure::Cast(receiver).function();
  } else {
    Class& cls = Class::Handle(receiver.clazz());
    if (level != InvocationMirror::kSuper) {
      function = cls.LookupDynamicFunction(method_name);
    }
    while (function.IsNull()) {
      cls = cls.SuperClass();
      if (cls.IsNull()) break;
      function = cls.LookupDynamicFunction(method_name);
    }
  }
  if (!function.IsNull()) {
    return function.UserVisibleSignature();
  }
  return String::null();
}

}  // namespace dart
