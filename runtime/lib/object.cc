// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "lib/invocation_mirror.h"
#include "vm/code_patcher.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/heap/heap.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(DartAsync_fatal, 0, 1) {
  // The dart:async library code entered an unrecoverable state.
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const char* msg = instance.ToCString();
  OS::PrintErr("Fatal error in dart:async: %s\n", msg);
  FATAL("%s", msg);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Object_equals, 0, 1) {
  // Implemented in the flow graph builder.
  UNREACHABLE();
  return Object::null();
}

static intptr_t GetHash(Isolate* isolate, const ObjectPtr obj) {
#if defined(HASH_IN_OBJECT_HEADER)
  return Object::GetCachedHash(obj);
#else
  Heap* heap = isolate->group()->heap();
  ASSERT(obj->IsDartInstance());
  return heap->GetHash(obj);
#endif
}

DEFINE_NATIVE_ENTRY(Object_getHash, 0, 1) {
  // Please note that no handle is created for the argument.
  // This is safe since the argument is only used in a tail call.
  // The performance benefit is more than 5% when using hashCode.
  intptr_t hash = GetHash(isolate, arguments->NativeArgAt(0));
  if (LIKELY(hash != 0)) {
    return Smi::New(hash);
  }

  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  return instance.IdentityHashCode(arguments->thread());
}

DEFINE_NATIVE_ENTRY(Object_toString, 0, 1) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  if (instance.IsString()) {
    return instance.ptr();
  }
  if (instance.IsAbstractType()) {
    return AbstractType::Cast(instance).UserVisibleName();
  }
  const char* c_str = instance.ToCString();
  return String::New(c_str);
}

DEFINE_NATIVE_ENTRY(Object_runtimeType, 0, 1) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  if (instance.IsString()) {
    return Type::StringType();
  } else if (instance.IsInteger()) {
    return Type::IntType();
  } else if (instance.IsDouble()) {
    return Type::Double();
  } else if (instance.IsAbstractType()) {
    return Type::DartTypeType();
  } else if (IsArrayClassId(instance.GetClassId())) {
    const auto& cls = Class::Handle(
        zone, thread->isolate_group()->object_store()->list_class());
    auto& type_arguments =
        TypeArguments::Handle(zone, instance.GetTypeArguments());
    type_arguments = type_arguments.FromInstanceTypeArguments(thread, cls);
    const auto& type = Type::Handle(
        zone,
        Type::New(cls, type_arguments, Nullability::kNonNullable, Heap::kNew));
    type.SetIsFinalized();
    return type.Canonicalize(thread);
  }

  return instance.GetType(Heap::kNew);
}

static bool HaveSameRuntimeTypeHelper(Zone* zone,
                                      const Instance& left,
                                      const Instance& right) {
  const intptr_t left_cid = left.GetClassId();
  const intptr_t right_cid = right.GetClassId();

  if (left_cid != right_cid) {
    if (IsIntegerClassId(left_cid)) {
      return IsIntegerClassId(right_cid);
    } else if (IsStringClassId(left_cid)) {
      return IsStringClassId(right_cid);
    } else if (IsTypeClassId(left_cid)) {
      return IsTypeClassId(right_cid);
    } else if (IsArrayClassId(left_cid)) {
      if (!IsArrayClassId(right_cid)) {
        return false;
      }
      // Still need to check type arguments.
    } else {
      return false;
    }
  }

  if (left_cid == kClosureCid) {
    const auto& left_closure = Closure::Cast(left);
    const auto& right_closure = Closure::Cast(right);
    // If all the components that make up the instantiated signature are equal,
    // then no need to instantiate.
    if (left_closure.function_type_arguments() ==
            right_closure.function_type_arguments() &&
        left_closure.delayed_type_arguments() ==
            right_closure.delayed_type_arguments() &&
        left_closure.instantiator_type_arguments() ==
            right_closure.instantiator_type_arguments()) {
      const auto& left_fun = Function::Handle(zone, left_closure.function());
      const auto& right_fun = Function::Handle(zone, right_closure.function());
      if (left_fun.signature() == right_fun.signature()) {
        return true;
      }
    }
    const AbstractType& left_type =
        AbstractType::Handle(zone, left.GetType(Heap::kNew));
    const AbstractType& right_type =
        AbstractType::Handle(zone, right.GetType(Heap::kNew));
    return left_type.IsEquivalent(right_type, TypeEquality::kSyntactical);
  }

  if (left_cid == kRecordCid) {
    const auto& left_record = Record::Cast(left);
    const auto& right_record = Record::Cast(right);
    if (left_record.shape() != right_record.shape()) {
      return false;
    }
    Instance& left_field = Instance::Handle(zone);
    Instance& right_field = Instance::Handle(zone);
    const intptr_t num_fields = left_record.num_fields();
    for (intptr_t i = 0; i < num_fields; ++i) {
      left_field ^= left_record.FieldAt(i);
      right_field ^= right_record.FieldAt(i);
      if (!HaveSameRuntimeTypeHelper(zone, left_field, right_field)) {
        return false;
      }
    }
    return true;
  }

  const Class& cls = Class::Handle(zone, left.clazz());
  if (!cls.IsGeneric()) {
    return true;
  }

  if (left.GetTypeArguments() == right.GetTypeArguments()) {
    return true;
  }
  const TypeArguments& left_type_arguments =
      TypeArguments::Handle(zone, left.GetTypeArguments());
  const TypeArguments& right_type_arguments =
      TypeArguments::Handle(zone, right.GetTypeArguments());
  const intptr_t num_type_args = cls.NumTypeArguments();
  const intptr_t num_type_params = cls.NumTypeParameters();
  return left_type_arguments.IsSubvectorEquivalent(
      right_type_arguments, num_type_args - num_type_params, num_type_params,
      TypeEquality::kSyntactical);
}

DEFINE_NATIVE_ENTRY(Object_haveSameRuntimeType, 0, 2) {
  const Instance& left =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Instance& right =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(1));
  return Bool::Get(HaveSameRuntimeTypeHelper(zone, left, right)).ptr();
}

DEFINE_NATIVE_ENTRY(Object_instanceOf, 0, 4) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(2));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(3));
  ASSERT(type.IsFinalized());
  const bool is_instance_of = instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments);
  if (FLAG_trace_type_checks) {
    LogBlock lb;
    const char* result_str = is_instance_of ? "true" : "false";
    THR_Print("Native Object.instanceOf: result %s\n", result_str);
    const AbstractType& instance_type =
        AbstractType::Handle(zone, instance.GetType(Heap::kNew));
    THR_Print("  instance type: %s\n",
              String::Handle(zone, instance_type.Name()).ToCString());
    THR_Print("  test type: %s\n",
              String::Handle(zone, type.Name()).ToCString());
  }
  return Bool::Get(is_instance_of).ptr();
}

DEFINE_NATIVE_ENTRY(Object_simpleInstanceOf, 0, 2) {
  // This native is only called when the right hand side passes
  // SimpleInstanceOfType and it is a non-negative test.
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(1));
  ASSERT(type.IsFinalized());
  ASSERT(type.IsInstantiated());
  const bool is_instance_of = instance.IsInstanceOf(
      type, Object::null_type_arguments(), Object::null_type_arguments());
  return Bool::Get(is_instance_of).ptr();
}

DEFINE_NATIVE_ENTRY(AbstractType_toString, 0, 1) {
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(0));
  return type.UserVisibleName();
}

DEFINE_NATIVE_ENTRY(AbstractType_getHashCode, 0, 1) {
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(0));
  intptr_t hash_val = type.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}

DEFINE_NATIVE_ENTRY(AbstractType_equality, 0, 2) {
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Instance& other =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(1));
  if (type.ptr() == other.ptr()) {
    return Bool::True().ptr();
  }
  return Bool::Get(type.IsEquivalent(other, TypeEquality::kSyntactical)).ptr();
}

DEFINE_NATIVE_ENTRY(Type_getHashCode, 0, 1) {
  const Type& type = Type::CheckedHandle(zone, arguments->NativeArgAt(0));
  intptr_t hash_val = type.Hash();
  ASSERT(hash_val > 0);
  ASSERT(Smi::IsValid(hash_val));
  return Smi::New(hash_val);
}

DEFINE_NATIVE_ENTRY(Type_equality, 0, 2) {
  const Type& type = Type::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Instance& other =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(1));
  if (type.ptr() == other.ptr()) {
    return Bool::True().ptr();
  }
  return Bool::Get(type.IsEquivalent(other, TypeEquality::kSyntactical)).ptr();
}

DEFINE_NATIVE_ENTRY(LibraryPrefix_isLoaded, 0, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Bool::Get(isolate->IsPrefixLoaded(prefix)).ptr();
}

DEFINE_NATIVE_ENTRY(LibraryPrefix_setLoaded, 0, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  isolate->SetPrefixIsLoaded(prefix);
  return Instance::null();
}

DEFINE_NATIVE_ENTRY(LibraryPrefix_loadingUnit, 0, 1) {
  const LibraryPrefix& prefix =
      LibraryPrefix::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Library& target = Library::Handle(zone, prefix.GetLibrary(0));
  const LoadingUnit& unit = LoadingUnit::Handle(zone, target.loading_unit());
  return Smi::New(unit.IsNull() ? LoadingUnit::kIllegalId : unit.id());
}

DEFINE_NATIVE_ENTRY(LibraryPrefix_issueLoad, 0, 1) {
  const Smi& id = Smi::CheckedHandle(zone, arguments->NativeArgAt(0));
  Array& units =
      Array::Handle(zone, isolate->group()->object_store()->loading_units());
  if (units.IsNull()) {
    // Not actually split.
    const Library& lib = Library::Handle(zone, Library::CoreLibrary());
    const String& sel = String::Handle(zone, String::New("_completeLoads"));
    const Function& func =
        Function::Handle(zone, lib.LookupFunctionAllowPrivate(sel));
    ASSERT(!func.IsNull());
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, id);
    args.SetAt(1, String::Handle(zone));
    args.SetAt(2, Bool::Get(false));
    return DartEntry::InvokeFunction(func, args);
  }
  ASSERT(id.Value() != LoadingUnit::kIllegalId);
  LoadingUnit& unit = LoadingUnit::Handle(zone);
  unit ^= units.At(id.Value());
  return unit.IssueLoad();
}

DEFINE_NATIVE_ENTRY(Internal_unsafeCast, 0, 1) {
  UNREACHABLE();  // Should be erased at Kernel translation time.
  return arguments->NativeArgAt(0);
}

DEFINE_NATIVE_ENTRY(Internal_nativeEffect, 0, 1) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Internal_collectAllGarbage, 0, 0) {
  isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging,
                                              /*compact=*/true);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Internal_deoptimizeFunctionsOnStack, 0, 0) {
  DeoptimizeFunctionsOnStack();
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Internal_randomInstructionsOffsetInsideAllocateObjectStub,
                    0,
                    0) {
  auto& stub = Code::Handle(
      zone, isolate->group()->object_store()->allocate_object_stub());
  const uword entry = stub.EntryPoint();
  const uword random_offset = isolate->random()->NextUInt32() % stub.Size();
  // We return the offset into the isolate instructions instead of the full
  // address because that fits into small Smis on 32-bit architectures or
  // compressed pointer builds.
  const uword instructions_start =
      reinterpret_cast<uword>(isolate->source()->snapshot_instructions);
  ASSERT(entry >= instructions_start);
  return Smi::New((entry - instructions_start) + random_offset);
}

static bool ExtractInterfaceTypeArgs(Zone* zone,
                                     const Class& instance_cls,
                                     const TypeArguments& instance_type_args,
                                     const Class& interface_cls,
                                     TypeArguments* interface_type_args) {
  Thread* thread = Thread::Current();
  Class& cur_cls = Class::Handle(zone, instance_cls.ptr());
  // The following code is a specialization of Class::IsSubtypeOf().
  Array& interfaces = Array::Handle(zone);
  Type& interface = Type::Handle(zone);
  Class& cur_interface_cls = Class::Handle(zone);
  TypeArguments& cur_interface_type_args = TypeArguments::Handle(zone);
  while (true) {
    // Additional subtyping rules related to 'FutureOr' are not applied.
    if (cur_cls.ptr() == interface_cls.ptr()) {
      *interface_type_args = instance_type_args.ptr();
      return true;
    }
    interfaces = cur_cls.interfaces();
    for (intptr_t i = 0; i < interfaces.Length(); i++) {
      interface ^= interfaces.At(i);
      ASSERT(interface.IsFinalized());
      cur_interface_cls = interface.type_class();
      cur_interface_type_args =
          interface.GetInstanceTypeArguments(thread, /*canonicalize=*/false);
      if (!cur_interface_type_args.IsNull() &&
          !cur_interface_type_args.IsInstantiated()) {
        cur_interface_type_args = cur_interface_type_args.InstantiateFrom(
            instance_type_args, Object::null_type_arguments(), kNoneFree,
            Heap::kNew);
      }
      if (ExtractInterfaceTypeArgs(zone, cur_interface_cls,
                                   cur_interface_type_args, interface_cls,
                                   interface_type_args)) {
        return true;
      }
    }
    cur_cls = cur_cls.SuperClass();
    if (cur_cls.IsNull()) {
      return false;
    }
  }
}

// for documentation see pkg/dart_internal/lib/extract_type_arguments.dart
DEFINE_NATIVE_ENTRY(Internal_extractTypeArguments, 0, 2) {
  const Instance& instance =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Instance& extract =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(1));

  Class& interface_cls = Class::Handle(zone);
  intptr_t num_type_args = 0;
  if (arguments->NativeTypeArgCount() >= 1) {
    const AbstractType& function_type_arg =
        AbstractType::Handle(zone, arguments->NativeTypeArgAt(0));
    if (function_type_arg.IsType() &&
        (Type::Cast(function_type_arg).arguments() == TypeArguments::null())) {
      interface_cls = function_type_arg.type_class();
      num_type_args = interface_cls.NumTypeParameters();
    }
  }
  if (num_type_args == 0) {
    Exceptions::ThrowArgumentError(String::Handle(
        zone,
        String::New(
            "single function type argument must specify a generic class")));
  }
  if (instance.IsNull()) {
    Exceptions::ThrowArgumentError(instance);
  }
  // Function 'extract' must be generic and accept the same number of type args,
  // unless we execute Dart 1.0 code.
  if (extract.IsNull() || !extract.IsClosure() ||
      ((num_type_args > 0) &&  // Dart 1.0 if num_type_args == 0.
       (Function::Handle(zone, Closure::Cast(extract).function())
            .NumTypeParameters() != num_type_args))) {
    Exceptions::ThrowArgumentError(String::Handle(
        zone,
        String::New("argument 'extract' is not a generic function or not one "
                    "accepting the correct number of type arguments")));
  }
  TypeArguments& extracted_type_args = TypeArguments::Handle(zone);
  if (num_type_args > 0) {
    // The passed instance must implement interface_cls.
    TypeArguments& interface_type_args = TypeArguments::Handle(zone);
    interface_type_args = TypeArguments::New(num_type_args);
    Class& instance_cls = Class::Handle(zone, instance.clazz());
    TypeArguments& instance_type_args = TypeArguments::Handle(zone);
    if (instance_cls.NumTypeArguments() > 0) {
      instance_type_args = instance.GetTypeArguments();
    }
    if (!ExtractInterfaceTypeArgs(zone, instance_cls, instance_type_args,
                                  interface_cls, &interface_type_args)) {
      Exceptions::ThrowArgumentError(String::Handle(
          zone, String::New("type of argument 'instance' is not a subtype of "
                            "the function type argument")));
    }
    if (!interface_type_args.IsNull()) {
      extracted_type_args = TypeArguments::New(num_type_args);
      const intptr_t offset = interface_cls.NumTypeArguments() - num_type_args;
      AbstractType& type_arg = AbstractType::Handle(zone);
      for (intptr_t i = 0; i < num_type_args; i++) {
        type_arg = interface_type_args.TypeAt(offset + i);
        extracted_type_args.SetTypeAt(i, type_arg);
      }
      extracted_type_args =
          extracted_type_args.Canonicalize(thread);  // Can be null.
    }
  }
  // Call the closure 'extract'.
  Array& args_desc = Array::Handle(zone);
  Array& args = Array::Handle(zone);
  if (extracted_type_args.IsNull()) {
    args_desc = ArgumentsDescriptor::NewBoxed(0, 1);
    args = Array::New(1);
    args.SetAt(0, extract);
  } else {
    args_desc = ArgumentsDescriptor::NewBoxed(num_type_args, 1);
    args = Array::New(2);
    args.SetAt(0, extracted_type_args);
    args.SetAt(1, extract);
  }
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeClosure(thread, args, args_desc));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(Internal_prependTypeArguments, 0, 4) {
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& parent_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_parent_len, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, smi_len, arguments->NativeArgAt(3));
  return function_type_arguments.Prepend(
      zone, parent_type_arguments, smi_parent_len.Value(), smi_len.Value());
}

// Check that a set of type arguments satisfy the type parameter bounds on a
// closure.
// Arg0: Closure object
// Arg1: Type arguments to function
DEFINE_NATIVE_ENTRY(Internal_boundsCheckForPartialInstantiation, 0, 2) {
  const Closure& closure =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Function& target = Function::Handle(zone, closure.function());
  ASSERT(target.IsGeneric());  // No need to check bounds for non-generics.
  const TypeParameters& type_params =
      TypeParameters::Handle(zone, target.type_parameters());
  if (type_params.IsNull() || type_params.AllDynamicBounds()) {
    // The function is not generic or the bounds are all dynamic.
    return Object::null();
  }

  const TypeArguments& type_args_to_check =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(1));

  // This should be guaranteed by the front-end.
  ASSERT(type_args_to_check.IsNull() ||
         type_params.Length() <= type_args_to_check.Length());

  // The bounds on the closure may need instantiation.
  const TypeArguments& instantiator_type_args =
      TypeArguments::Handle(zone, closure.instantiator_type_arguments());
  const TypeArguments& function_type_args =
      TypeArguments::Handle(zone, closure.function_type_arguments());

  AbstractType& supertype = AbstractType::Handle(zone);
  AbstractType& subtype = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < type_params.Length(); ++i) {
    supertype = type_params.BoundAt(i);
    subtype = type_args_to_check.IsNull() ? Object::dynamic_type().ptr()
                                          : type_args_to_check.TypeAt(i);

    ASSERT(!subtype.IsNull());
    ASSERT(!supertype.IsNull());

    // The supertype may not be instantiated.
    if (!AbstractType::InstantiateAndTestSubtype(
            &subtype, &supertype, instantiator_type_args, function_type_args)) {
      // Throw a dynamic type error.
      TokenPosition location = TokenPosition::kNoSource;
      {
        DartFrameIterator iterator(Thread::Current(),
                                   StackFrameIterator::kNoCrossThreadIteration);
        StackFrame* caller_frame = iterator.NextFrame();
        ASSERT(caller_frame != nullptr);
        location = caller_frame->GetTokenPos();
      }
      const auto& parameter_name = String::Handle(zone, type_params.NameAt(i));
      Exceptions::CreateAndThrowTypeError(location, subtype, supertype,
                                          parameter_name);
      UNREACHABLE();
    }
  }

  return Object::null();
}

DEFINE_NATIVE_ENTRY(InvocationMirror_unpackTypeArguments, 0, 2) {
  const TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& num_type_arguments =
      Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  bool all_dynamic = type_arguments.IsNull();
  const intptr_t len =
      all_dynamic ? num_type_arguments.Value() : type_arguments.Length();
  const Array& type_list = Array::Handle(
      zone, Array::New(len, Type::Handle(zone, Type::DartTypeType())));
  AbstractType& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    if (all_dynamic) {
      type_list.SetAt(i, Object::dynamic_type());
    } else {
      type = type_arguments.TypeAt(i);
      type_list.SetAt(i, type);
    }
  }
  type_list.MakeImmutable();
  return type_list.ptr();
}

DEFINE_NATIVE_ENTRY(NoSuchMethodError_existingMethodSignature, 0, 3) {
  const Instance& receiver =
      Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, method_name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, invocation_type, arguments->NativeArgAt(2));
  InvocationMirror::Level level;
  InvocationMirror::Kind kind;
  InvocationMirror::DecodeType(invocation_type.Value(), &level, &kind);

  Function& function = Function::Handle(zone);
  if (level == InvocationMirror::Level::kTopLevel) {
    if (receiver.IsString()) return receiver.ptr();
    ASSERT(receiver.IsNull());
    return String::null();
  }
  if (receiver.IsType()) {
    const auto& cls = Class::Handle(zone, Type::Cast(receiver).type_class());
    const auto& error = Error::Handle(zone, cls.EnsureIsFinalized(thread));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
      UNREACHABLE();
    }
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
    auto& cls = Class::Handle(zone, receiver.clazz());
    if (level == InvocationMirror::kSuper) {
      cls = cls.SuperClass();
    }
    function = Resolver::ResolveDynamicAnyArgs(zone, cls, method_name,
                                               /*allow_add=*/false);
  }
  if (!function.IsNull()) {
    return function.UserVisibleSignature();
  }
  return String::null();
}

}  // namespace dart
