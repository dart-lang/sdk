// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi.h"
#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/exceptions.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

// The following functions are runtime checks on type arguments.
// Some checks are also performed in kernel transformation, these are asserts.
// Some checks are only performed at runtime to allow for generic code, these
// throw ArgumentExceptions.

static void ThrowTypeArgumentError(const AbstractType& type_arg,
                                   const char* expected) {
  const String& error = String::Handle(String::NewFormatted(
      "Type argument (%s) should be a %s",
      String::Handle(type_arg.UserVisibleName()).ToCString(), expected));
  Exceptions::ThrowArgumentError(error);
}

static bool IsPointerType(const AbstractType& type) {
  // Do a fast check for predefined types.
  classid_t type_cid = type.type_class_id();
  if (RawObject::IsFfiPointerClassId(type_cid)) {
    return true;
  }

  // Do a slow check for subtyping.
  const Class& pointer_class =
      Class::Handle(Isolate::Current()->object_store()->ffi_pointer_class());
  AbstractType& pointer_type =
      AbstractType::Handle(pointer_class.DeclarationType());
  pointer_type ^= pointer_type.InstantiateFrom(Object::null_type_arguments(),
                                               Object::null_type_arguments(),
                                               kNoneFree, NULL, Heap::kNew);
  ASSERT(pointer_type.IsInstantiated());
  ASSERT(type.IsInstantiated());
  return type.IsSubtypeOf(pointer_type, Heap::kNew);
}

static bool IsConcreteNativeType(const AbstractType& type) {
  // Do a fast check for predefined types.
  classid_t type_cid = type.type_class_id();
  if (RawObject::IsFfiNativeTypeTypeClassId(type_cid)) {
    return false;
  }
  if (RawObject::IsFfiTypeClassId(type_cid)) {
    return true;
  }

  // Do a slow check for subtyping.
  const Class& native_type_class = Class::Handle(
      Isolate::Current()->object_store()->ffi_native_type_class());
  AbstractType& native_type_type =
      AbstractType::Handle(native_type_class.DeclarationType());
  return type.IsSubtypeOf(native_type_type, Heap::kNew);
}

static void CheckIsConcreteNativeType(const AbstractType& type) {
  if (!IsConcreteNativeType(type)) {
    ThrowTypeArgumentError(type, "concrete sub type of NativeType");
  }
}

static bool IsNativeFunction(const AbstractType& type_arg) {
  classid_t type_cid = type_arg.type_class_id();
  return RawObject::IsFfiTypeNativeFunctionClassId(type_cid);
}

static void CheckSized(const AbstractType& type_arg) {
  classid_t type_cid = type_arg.type_class_id();
  if (RawObject::IsFfiTypeVoidClassId(type_cid) ||
      RawObject::IsFfiTypeNativeFunctionClassId(type_cid)) {
    const String& error = String::Handle(String::NewFormatted(
        "%s does not have a predefined size (@unsized). "
        "Unsized NativeTypes do not support [sizeOf] because their size "
        "is unknown. "
        "Consequently, [allocate], [Pointer.load], [Pointer.store], and "
        "[Pointer.elementAt] are not available.",
        String::Handle(type_arg.UserVisibleName()).ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
}

// Checks that a dart type correspond to a [NativeType].
// Because this is checked already in a kernel transformation, it does not throw
// an ArgumentException but a boolean which should be asserted.
//
// [Int8]                               -> [int]
// [Int16]                              -> [int]
// [Int32]                              -> [int]
// [Int64]                              -> [int]
// [Uint8]                              -> [int]
// [Uint16]                             -> [int]
// [Uint32]                             -> [int]
// [Uint64]                             -> [int]
// [IntPtr]                             -> [int]
// [Double]                             -> [double]
// [Float]                              -> [double]
// [Pointer]<T>                         -> [Pointer]<T>
// T extends [Pointer]                  -> T
// [NativeFunction]<T1 Function(T2, T3) -> S1 Function(S2, S3)
//    where DartRepresentationOf(Tn) -> Sn
static bool DartAndCTypeCorrespond(const AbstractType& native_type,
                                   const AbstractType& dart_type) {
  classid_t native_type_cid = native_type.type_class_id();
  if (RawObject::IsFfiTypeIntClassId(native_type_cid)) {
    return dart_type.IsSubtypeOf(AbstractType::Handle(Type::IntType()),
                                 Heap::kNew);
  }
  if (RawObject::IsFfiTypeDoubleClassId(native_type_cid)) {
    return dart_type.IsSubtypeOf(AbstractType::Handle(Type::Double()),
                                 Heap::kNew);
  }
  if (RawObject::IsFfiPointerClassId(native_type_cid)) {
    return native_type.Equals(dart_type) || dart_type.IsNullType();
  }
  if (RawObject::IsFfiTypeNativeFunctionClassId(native_type_cid)) {
    if (!dart_type.IsFunctionType()) {
      return false;
    }
    TypeArguments& nativefunction_type_args =
        TypeArguments::Handle(native_type.arguments());
    AbstractType& nativefunction_type_arg =
        AbstractType::Handle(nativefunction_type_args.TypeAt(0));
    if (!nativefunction_type_arg.IsFunctionType()) {
      return false;
    }
    Function& dart_function = Function::Handle(((Type&)dart_type).signature());
    if (dart_function.NumTypeParameters() != 0 ||
        dart_function.HasOptionalPositionalParameters() ||
        dart_function.HasOptionalNamedParameters()) {
      return false;
    }
    Function& nativefunction_function =
        Function::Handle(((Type&)nativefunction_type_arg).signature());
    if (nativefunction_function.NumTypeParameters() != 0 ||
        nativefunction_function.HasOptionalPositionalParameters() ||
        nativefunction_function.HasOptionalNamedParameters()) {
      return false;
    }
    if (!(dart_function.NumParameters() ==
          nativefunction_function.NumParameters())) {
      return false;
    }
    if (!DartAndCTypeCorrespond(
            AbstractType::Handle(nativefunction_function.result_type()),
            AbstractType::Handle(dart_function.result_type()))) {
      return false;
    }
    for (intptr_t i = 0; i < dart_function.NumParameters(); i++) {
      if (!DartAndCTypeCorrespond(
              AbstractType::Handle(nativefunction_function.ParameterTypeAt(i)),
              AbstractType::Handle(dart_function.ParameterTypeAt(i)))) {
        return false;
      }
    }
  }
  return true;
}

// The following functions are runtime checks on arguments.

// Note that expected_from and expected_to are inclusive.
static void CheckRange(const Integer& argument_value,
                       intptr_t expected_from,
                       intptr_t expected_to,
                       const char* argument_name) {
  int64_t value = argument_value.AsInt64Value();
  if (value < expected_from || expected_to < value) {
    Exceptions::ThrowRangeError(argument_name, argument_value, expected_from,
                                expected_to);
  }
}

static const Pointer& AsPointer(const Instance& instance) {
  if (!instance.IsPointer()) {
    const String& error = String::Handle(String::NewFormatted(
        "Expected a Pointer object but found %s", instance.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
  return Pointer::Cast(instance);
}

static const Integer& AsInteger(const Instance& instance) {
  if (!instance.IsInteger()) {
    const String& error = String::Handle(String::NewFormatted(
        "Expected an int but found %s", instance.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
  return Integer::Cast(instance);
}

static const Double& AsDouble(const Instance& instance) {
  if (!instance.IsDouble()) {
    const String& error = String::Handle(String::NewFormatted(
        "Expected a double but found %s", instance.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
  return Double::Cast(instance);
}

// The remainder of this file implements the dart:ffi native methods.

DEFINE_NATIVE_ENTRY(Ffi_allocate, 1, 1) {
  // TODO(dacoharkes): When we have a way of determining the size of structs in
  // the VM, change the signature so we can allocate structs, subtype of
  // Pointer. https://github.com/dart-lang/sdk/issues/35782
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));

  CheckIsConcreteNativeType(type_arg);
  CheckSized(type_arg);

  GET_NON_NULL_NATIVE_ARGUMENT(Integer, argCount, arguments->NativeArgAt(0));
  int64_t count = argCount.AsInt64Value();
  classid_t type_cid = type_arg.type_class_id();
  int64_t max_count = INTPTR_MAX / ffi::ElementSizeInBytes(type_cid);
  CheckRange(argCount, 1, max_count, "count");

  size_t size = ffi::ElementSizeInBytes(type_cid) * count;
  intptr_t memory = reinterpret_cast<intptr_t>(malloc(size));
  if (memory == 0) {
    const String& error = String::Handle(String::NewFormatted(
        "allocating (%" Pd ") bytes of memory failed", size));
    Exceptions::ThrowArgumentError(error);
  }

  RawPointer* result =
      Pointer::New(type_arg, Integer::Handle(zone, Integer::New(memory)));
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_fromAddress, 1, 1) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  TypeArguments& type_args = TypeArguments::Handle(type_arg.arguments());
  AbstractType& native_type = AbstractType::Handle(
      type_args.TypeAtNullSafe(Pointer::kNativeTypeArgPos));
  CheckIsConcreteNativeType(native_type);
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, arg_ptr, arguments->NativeArgAt(0));

  // TODO(dacoharkes): should this return NULL if address is 0?
  // https://github.com/dart-lang/sdk/issues/35756

  RawPointer* result =
      Pointer::New(native_type, arg_ptr, type_arg.type_class_id());
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_elementAt, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(zone, pointer.type_argument());
  CheckSized(pointer_type_arg);

  classid_t class_id = pointer_type_arg.type_class_id();
  Integer& address = Integer::Handle(zone, pointer.GetCMemoryAddress());
  address =
      Integer::New(address.AsInt64Value() +
                   index.AsInt64Value() * ffi::ElementSizeInBytes(class_id));
  RawPointer* result = Pointer::New(pointer_type_arg, address);
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_offsetBy, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, offset, arguments->NativeArgAt(1));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());

  intptr_t address =
      Integer::Handle(zone, pointer.GetCMemoryAddress()).AsInt64Value() +
      offset.AsInt64Value();
  RawPointer* result = Pointer::New(
      pointer_type_arg, Integer::Handle(zone, Integer::New(address)));
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_cast, 1, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  TypeArguments& type_args = TypeArguments::Handle(type_arg.arguments());
  AbstractType& native_type = AbstractType::Handle(
      type_args.TypeAtNullSafe(Pointer::kNativeTypeArgPos));
  CheckIsConcreteNativeType(native_type);

  const Integer& address = Integer::Handle(zone, pointer.GetCMemoryAddress());
  RawPointer* result =
      Pointer::New(native_type, address, type_arg.type_class_id());
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_free, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));

  const Integer& address = Integer::Handle(zone, pointer.GetCMemoryAddress());
  free(reinterpret_cast<void*>(address.AsInt64Value()));
  pointer.SetCMemoryAddress(Integer::Handle(zone, Integer::New(0)));
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_address, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  return pointer.GetCMemoryAddress();
}

static RawInstance* BoxLoadPointer(Zone* zone,
                                   uint8_t* address,
                                   const AbstractType& instance_type_arg,
                                   intptr_t type_cid) {
  // TODO(dacoharkes): should this return NULL if addres is 0?
  // https://github.com/dart-lang/sdk/issues/35756
  if (address == nullptr) {
    return Instance::null();
  }
  AbstractType& type_arg =
      AbstractType::Handle(TypeArguments::Handle(instance_type_arg.arguments())
                               .TypeAt(Pointer::kNativeTypeArgPos));
  return Pointer::New(
      type_arg,
      Integer::Handle(zone, Integer::New(reinterpret_cast<intptr_t>(address))),
      type_cid);
}

static RawInstance* LoadValue(Zone* zone,
                              uint8_t* address,
                              const AbstractType& instance_type_arg) {
  classid_t type_cid = instance_type_arg.type_class_id();
  switch (type_cid) {
    case kFfiInt8Cid:
      return Integer::New(*reinterpret_cast<int8_t*>(address));
    case kFfiInt16Cid:
      return Integer::New(*reinterpret_cast<int16_t*>(address));
    case kFfiInt32Cid:
      return Integer::New(*reinterpret_cast<int32_t*>(address));
    case kFfiInt64Cid:
      return Integer::New(*reinterpret_cast<int64_t*>(address));
    case kFfiUint8Cid:
      return Integer::NewFromUint64(*reinterpret_cast<uint8_t*>(address));
    case kFfiUint16Cid:
      return Integer::NewFromUint64(*reinterpret_cast<uint16_t*>(address));
    case kFfiUint32Cid:
      return Integer::NewFromUint64(*reinterpret_cast<uint32_t*>(address));
    case kFfiUint64Cid:
      return Integer::NewFromUint64(*reinterpret_cast<uint64_t*>(address));
    case kFfiIntPtrCid:
      return Integer::New(*reinterpret_cast<intptr_t*>(address));
    case kFfiFloatCid:
      return Double::New(*reinterpret_cast<float_t*>(address));
    case kFfiDoubleCid:
      return Double::New(*reinterpret_cast<double_t*>(address));
    case kFfiPointerCid:
    default:
      ASSERT(IsPointerType(instance_type_arg));
      return BoxLoadPointer(zone, *reinterpret_cast<uint8_t**>(address),
                            instance_type_arg, type_cid);
  }
}

DEFINE_NATIVE_ENTRY(Ffi_load, 1, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  CheckSized(pointer_type_arg);
  ASSERT(DartAndCTypeCorrespond(pointer_type_arg, type_arg));

  uint8_t* address = reinterpret_cast<uint8_t*>(
      Integer::Handle(pointer.GetCMemoryAddress()).AsInt64Value());
  return LoadValue(zone, address, pointer_type_arg);
}

static void StoreValue(Zone* zone,
                       const Pointer& pointer,
                       classid_t type_cid,
                       const Instance& new_value) {
  uint8_t* address = reinterpret_cast<uint8_t*>(
      Integer::Handle(pointer.GetCMemoryAddress()).AsInt64Value());
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  switch (type_cid) {
    case kFfiInt8Cid:
      *reinterpret_cast<int8_t*>(address) = AsInteger(new_value).AsInt64Value();
      break;
    case kFfiInt16Cid:
      *reinterpret_cast<int16_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiInt32Cid:
      *reinterpret_cast<int32_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiInt64Cid:
      *reinterpret_cast<int64_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiUint8Cid:
      *reinterpret_cast<uint8_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiUint16Cid:
      *reinterpret_cast<uint16_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiUint32Cid:
      *reinterpret_cast<uint32_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiUint64Cid:
      *reinterpret_cast<uint64_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiIntPtrCid:
      *reinterpret_cast<intptr_t*>(address) =
          AsInteger(new_value).AsInt64Value();
      break;
    case kFfiFloatCid:
      *reinterpret_cast<float*>(address) = AsDouble(new_value).value();
      break;
    case kFfiDoubleCid:
      *reinterpret_cast<double*>(address) = AsDouble(new_value).value();
      break;
    case kFfiPointerCid:
    default: {
      ASSERT(IsPointerType(pointer_type_arg));
      intptr_t new_value_unwrapped = 0;
      if (!new_value.IsNull()) {
        ASSERT(new_value.IsPointer());
        new_value_unwrapped =
            Integer::Handle(AsPointer(new_value).GetCMemoryAddress())
                .AsInt64Value();
        // TODO(dacoharkes): should this return NULL if addres is 0?
        // https://github.com/dart-lang/sdk/issues/35756
      }
      *reinterpret_cast<intptr_t*>(address) = new_value_unwrapped;
    } break;
  }
}

DEFINE_NATIVE_ENTRY(Ffi_store, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, new_value, arguments->NativeArgAt(1));
  AbstractType& arg_type = AbstractType::Handle(new_value.GetType(Heap::kNew));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  CheckSized(pointer_type_arg);
  ASSERT(DartAndCTypeCorrespond(pointer_type_arg, arg_type));

  classid_t type_cid = pointer_type_arg.type_class_id();
  StoreValue(zone, pointer, type_cid, new_value);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_sizeOf, 1, 0) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  CheckIsConcreteNativeType(type_arg);
  CheckSized(type_arg);

  classid_t type_cid = type_arg.type_class_id();
  return Smi::New(ffi::ElementSizeInBytes(type_cid));
}

// Generates assembly to trampoline from Dart into C++.
//
// Attaches assembly code to the function with the folling features:
// - unboxes arguments
// - puts the arguments on the c stack
// - invokes the c function
// - reads the the result
// - boxes the result and returns it.
//
// It inspects the signature to know what to box/unbox
// Parameter `function` has the Dart types in its signature
// Parameter `c_signature` has the C++ types in its signature
static RawCode* TrampolineCode(const Function& function,
                               const Function& c_signature) {
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  // Currently we generate the trampoline when calling asFunction(), this means
  // the ffi cannot be used in AOT.
  // In order make it work in AOT we need to:
  // - collect all asFunction signatures ahead of time
  // - generate trampolines for those
  // - store these in the object store
  // - and read these from the object store when calling asFunction()
  // https://github.com/dart-lang/sdk/issues/35765
  UNREACHABLE();
#elif !defined(TARGET_ARCH_X64)
  // https://github.com/dart-lang/sdk/issues/35774
  UNREACHABLE();
#elif !defined(TARGET_OS_LINUX) && !defined(TARGET_OS_MACOS)
  // https://github.com/dart-lang/sdk/issues/35760 Arm32 && Android
  // https://github.com/dart-lang/sdk/issues/35771 Windows
  // https://github.com/dart-lang/sdk/issues/35772 Arm64
  // https://github.com/dart-lang/sdk/issues/35773 DBC
  UNREACHABLE();
#else
  extern void GenerateFfiTrampoline(Assembler * assembler,
                                    const Function& signature);
  ObjectPoolBuilder object_pool_builder;
  Assembler assembler(&object_pool_builder);
  GenerateFfiTrampoline(&assembler, c_signature);
  const Code& code = Code::Handle(Code::FinalizeCodeAndNotify(
      function, nullptr, &assembler, Code::PoolAttachment::kAttachPool));
  code.set_exception_handlers(
      ExceptionHandlers::Handle(ExceptionHandlers::New(0)));
  return code.raw();
#endif
}

// TODO(dacoharkes): Cache the trampolines.
// We can possibly address simultaniously with 'precaching' in AOT.
static RawFunction* TrampolineFunction(const Function& dart_signature,
                                       const Function& c_signature) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const String& name =
      String::ZoneHandle(Symbols::New(Thread::Current(), "FfiTrampoline"));
  const Library& lib = Library::Handle(Library::FfiLibrary());
  const Class& owner_class = Class::Handle(lib.toplevel_class());
  Function& function = Function::ZoneHandle(
      zone, Function::New(name, RawFunction::kFfiTrampoline,
                          true,   // is_static
                          false,  // is_const
                          false,  // is_abstract
                          false,  // is_external
                          true,   // is_native
                          owner_class, TokenPosition::kMinSource));

  function.set_num_fixed_parameters(dart_signature.num_fixed_parameters());
  function.set_result_type(AbstractType::Handle(dart_signature.result_type()));
  function.set_parameter_types(Array::Handle(dart_signature.parameter_types()));

  const Code& code = Code::Handle(TrampolineCode(function, c_signature));
  function.AttachCode(code);

  return function.raw();
}

DEFINE_NATIVE_ENTRY(Ffi_asFunction, 1, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  ASSERT(IsNativeFunction(pointer_type_arg));
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  ASSERT(DartAndCTypeCorrespond(pointer_type_arg, type_arg));

  Function& dart_signature = Function::Handle(Type::Cast(type_arg).signature());
  TypeArguments& nativefunction_type_args =
      TypeArguments::Handle(pointer_type_arg.arguments());
  AbstractType& nativefunction_type_arg =
      AbstractType::Handle(nativefunction_type_args.TypeAt(0));
  Function& c_signature =
      Function::Handle(Type::Cast(nativefunction_type_arg).signature());
  Function& function =
      Function::Handle(TrampolineFunction(dart_signature, c_signature));

  // Set the c function pointer in the context of the closure rather than in
  // the function so that we can reuse the function for each c function with
  // the same signature.
  Context& context = Context::Handle(Context::New(1));
  context.SetAt(0, Integer::Handle(zone, pointer.GetCMemoryAddress()));

  RawClosure* raw_closure =
      Closure::New(Object::null_type_arguments(), Object::null_type_arguments(),
                   function, context, Heap::kOld);

  return raw_closure;
}

// Generates assembly to trampoline from C++ back into Dart.
static void* GenerateFfiInverseTrampoline(const Function& signature,
                                          void* dart_entry_point) {
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  UNREACHABLE();
#elif !defined(TARGET_ARCH_X64)
  // https://github.com/dart-lang/sdk/issues/35774
  UNREACHABLE();
#elif !defined(TARGET_OS_LINUX) && !defined(TARGET_OS_MACOS)
  // https://github.com/dart-lang/sdk/issues/35760 Arm32 && Android
  // https://github.com/dart-lang/sdk/issues/35771 Windows
  // https://github.com/dart-lang/sdk/issues/35772 Arm64
  // https://github.com/dart-lang/sdk/issues/35773 DBC
  UNREACHABLE();
#else
  extern void GenerateFfiInverseTrampoline(
      Assembler * assembler, const Function& signature, void* dart_entry_point);
  ObjectPoolBuilder object_pool_builder;
  Assembler assembler(&object_pool_builder);
  GenerateFfiInverseTrampoline(&assembler, signature, dart_entry_point);
  const Code& code = Code::Handle(
      Code::FinalizeCodeAndNotify("inverse trampoline", nullptr, &assembler,
                                  Code::PoolAttachment::kAttachPool, false));

  uword entryPoint = code.EntryPoint();

  return reinterpret_cast<void*>(entryPoint);
#endif
}

// TODO(dacoharkes): Implement this feature.
// https://github.com/dart-lang/sdk/issues/35761
// For now, it always returns Pointer with address 0.
DEFINE_NATIVE_ENTRY(Ffi_fromFunction, 1, 1) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(0));

  Function& c_signature = Function::Handle(((Type&)type_arg).signature());

  Function& func = Function::Handle(closure.function());
  Code& code = Code::Handle(func.EnsureHasCode());
  void* entryPoint = reinterpret_cast<void*>(code.EntryPoint());

  THR_Print("Ffi_fromFunction: %s\n", type_arg.ToCString());
  THR_Print("Ffi_fromFunction: %s\n", c_signature.ToCString());
  THR_Print("Ffi_fromFunction: %s\n", closure.ToCString());
  THR_Print("Ffi_fromFunction: %s\n", func.ToCString());
  THR_Print("Ffi_fromFunction: %s\n", code.ToCString());
  THR_Print("Ffi_fromFunction: %p\n", entryPoint);
  THR_Print("Ffi_fromFunction: %" Pd "\n", code.Size());

  intptr_t address = reinterpret_cast<intptr_t>(
      GenerateFfiInverseTrampoline(c_signature, entryPoint));

  TypeArguments& type_args = TypeArguments::Handle(zone);
  type_args = TypeArguments::New(1);
  type_args.SetTypeAt(Pointer::kNativeTypeArgPos, type_arg);
  type_args ^= type_args.Canonicalize();

  Class& native_function_class = Class::Handle(
      Isolate::Current()->class_table()->At(kFfiNativeFunctionCid));
  native_function_class.EnsureIsFinalized(Thread::Current());

  Type& native_function_type = Type::Handle(
      Type::New(native_function_class, type_args, TokenPosition::kNoSource));
  native_function_type ^=
      ClassFinalizer::FinalizeType(Class::Handle(), native_function_type);
  native_function_type ^= native_function_type.Canonicalize();

  address = 0;  // https://github.com/dart-lang/sdk/issues/35761

  Pointer& result = Pointer::Handle(Pointer::New(
      native_function_type, Integer::Handle(zone, Integer::New(address))));

  return result.raw();
}

}  // namespace dart
