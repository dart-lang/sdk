// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/ffi.h"

#include "include/dart_api.h"
#include "platform/globals.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/ffi.h"
#include "vm/compiler/jit/compiler.h"
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
  pointer_type = pointer_type.InstantiateFrom(Object::null_type_arguments(),
                                              Object::null_type_arguments(),
                                              kNoneFree, NULL, Heap::kNew);
  ASSERT(pointer_type.IsInstantiated());
  ASSERT(type.IsInstantiated());
  return type.IsSubtypeOf(pointer_type, Heap::kNew);
}

static bool IsNativeFunction(const AbstractType& type_arg) {
  classid_t type_cid = type_arg.type_class_id();
  return RawObject::IsFfiTypeNativeFunctionClassId(type_cid);
}

static void CheckSized(const AbstractType& type_arg) {
  const classid_t type_cid = type_arg.type_class_id();
  if (RawObject::IsFfiNativeTypeTypeClassId(type_cid) ||
      RawObject::IsFfiTypeVoidClassId(type_cid) ||
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

enum class FfiVariance { kInvariant = 0, kCovariant = 1, kContravariant = 2 };

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
                                   const AbstractType& dart_type,
                                   FfiVariance variance) {
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
    return (variance == FfiVariance::kInvariant &&
            dart_type.Equals(native_type)) ||
           (variance == FfiVariance::kCovariant &&
            dart_type.IsSubtypeOf(native_type, Heap::kNew)) ||
           (variance == FfiVariance::kContravariant &&
            native_type.IsSubtypeOf(dart_type, Heap::kNew)) ||
           dart_type.IsNullType();
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
            AbstractType::Handle(dart_function.result_type()), variance)) {
      return false;
    }
    for (intptr_t i = 0; i < dart_function.NumParameters(); i++) {
      if (!DartAndCTypeCorrespond(
              AbstractType::Handle(nativefunction_function.ParameterTypeAt(i)),
              AbstractType::Handle(dart_function.ParameterTypeAt(i)),
              variance)) {
        return false;
      }
    }
  }
  return true;
}

static void CheckDartAndCTypeCorrespond(const AbstractType& native_type,
                                        const AbstractType& dart_type,
                                        FfiVariance variance) {
  if (!DartAndCTypeCorrespond(native_type, dart_type, variance)) {
    const String& error = String::Handle(String::NewFormatted(
        "Expected type '%s' to be different, it should be "
        "DartRepresentationOf('%s').",
        String::Handle(dart_type.UserVisibleName()).ToCString(),
        String::Handle(native_type.UserVisibleName()).ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
}

// The following functions are runtime checks on arguments.

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

  CheckSized(type_arg);

  GET_NON_NULL_NATIVE_ARGUMENT(Integer, argCount, arguments->NativeArgAt(0));
  int64_t count = argCount.AsInt64Value();
  classid_t type_cid = type_arg.type_class_id();

  size_t size = compiler::ffi::ElementSizeInBytes(type_cid) *
                count;  // Truncates overflow.
  size_t memory = reinterpret_cast<size_t>(malloc(size));
  if (memory == 0) {
    const String& error = String::Handle(String::NewFormatted(
        "allocating (%" Pd ") bytes of memory failed", size));
    Exceptions::ThrowArgumentError(error);
  }

  RawPointer* result = Pointer::New(
      type_arg, Integer::Handle(zone, Integer::NewFromUint64(memory)));
  return result;
}

DEFINE_NATIVE_ENTRY(Ffi_fromAddress, 1, 1) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  TypeArguments& type_args = TypeArguments::Handle(type_arg.arguments());
  AbstractType& native_type = AbstractType::Handle(
      type_args.TypeAtNullSafe(Pointer::kNativeTypeArgPos));
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
  address = Integer::New(address.AsInt64Value() +
                         index.AsInt64Value() *
                             compiler::ffi::ElementSizeInBytes(class_id));
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
  CheckDartAndCTypeCorrespond(pointer_type_arg, type_arg,
                              FfiVariance::kContravariant);

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
  CheckDartAndCTypeCorrespond(pointer_type_arg, arg_type,
                              FfiVariance::kCovariant);

  classid_t type_cid = pointer_type_arg.type_class_id();
  StoreValue(zone, pointer, type_cid, new_value);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_sizeOf, 1, 0) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  CheckSized(type_arg);

  classid_t type_cid = type_arg.type_class_id();
  return Smi::New(compiler::ffi::ElementSizeInBytes(type_cid));
}

// TODO(dacoharkes): Cache the trampolines.
// We can possibly address simultaniously with 'precaching' in AOT.
static RawFunction* TrampolineFunction(const Function& dart_signature,
                                       const Function& c_signature) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  String& name =
      String::ZoneHandle(Symbols::New(Thread::Current(), "FfiTrampoline"));
  const Library& lib = Library::Handle(Library::FfiLibrary());
  const Class& owner_class = Class::Handle(lib.toplevel_class());
  Function& function =
      Function::Handle(zone, Function::New(name, RawFunction::kFfiTrampoline,
                                           /*is_static=*/true,
                                           /*is_const=*/false,
                                           /*is_abstract=*/false,
                                           /*is_external=*/false,
                                           /*is_native=*/false, owner_class,
                                           TokenPosition::kMinSource));
  function.set_is_debuggable(false);
  function.set_num_fixed_parameters(dart_signature.num_fixed_parameters());
  function.set_result_type(AbstractType::Handle(dart_signature.result_type()));
  function.set_parameter_types(Array::Handle(dart_signature.parameter_types()));

  // The signature function won't have any names for the parameters. We need to
  // assign unique names for scope building and error messages.
  const intptr_t num_params = dart_signature.num_fixed_parameters();
  const Array& parameter_names = Array::Handle(Array::New(num_params));
  for (intptr_t i = 0; i < num_params; ++i) {
    if (i == 0) {
      name = Symbols::ClosureParameter().raw();
    } else {
      name = Symbols::NewFormatted(thread, ":ffiParam%" Pd, i);
    }
    parameter_names.SetAt(i, name);
  }
  function.set_parameter_names(parameter_names);
  function.SetFfiCSignature(c_signature);

  return function.raw();
}

DEFINE_NATIVE_ENTRY(Ffi_asFunction, 1, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  ASSERT(IsNativeFunction(pointer_type_arg));
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  CheckDartAndCTypeCorrespond(pointer_type_arg, type_arg,
                              FfiVariance::kInvariant);

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

// Generates assembly to trampoline from native code into Dart.
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)
static uword CompileNativeCallback(const Function& c_signature,
                                   const Function& dart_target,
                                   const Instance& exceptional_return) {
#if defined(TARGET_ARCH_DBC)
  // https://github.com/dart-lang/sdk/issues/35774
  // FFI is supported, but callbacks are not.
  Exceptions::ThrowUnsupportedError(
      "FFI callbacks are not yet supported on DBC.");
#else
  Thread* const thread = Thread::Current();
  const int32_t callback_id = thread->AllocateFfiCallbackId();

  // Create a new Function named 'FfiCallback' and stick it in the 'dart:ffi'
  // library. Note that these functions will never be invoked by Dart, so it
  // doesn't matter that they all have the same name.
  Zone* const Z = thread->zone();
  const String& name =
      String::ZoneHandle(Symbols::New(Thread::Current(), "FfiCallback"));
  const Library& lib = Library::Handle(Library::FfiLibrary());
  const Class& owner_class = Class::Handle(lib.toplevel_class());
  const Function& function =
      Function::Handle(Z, Function::New(name, RawFunction::kFfiTrampoline,
                                        /*is_static=*/true,
                                        /*is_const=*/false,
                                        /*is_abstract=*/false,
                                        /*is_external=*/false,
                                        /*is_native=*/false, owner_class,
                                        TokenPosition::kMinSource));
  function.set_is_debuggable(false);

  // Set callback-specific fields which the flow-graph builder needs to generate
  // the body.
  function.SetFfiCSignature(c_signature);
  function.SetFfiCallbackId(callback_id);
  function.SetFfiCallbackTarget(dart_target);

  // We require that the exceptional return value for functions returning 'Void'
  // must be 'null', since native code should not look at the result.
  if (compiler::ffi::NativeTypeIsVoid(
          AbstractType::Handle(c_signature.result_type())) &&
      !exceptional_return.IsNull()) {
    Exceptions::ThrowUnsupportedError(
        "Only 'null' may be used as the exceptional return value for a "
        "callback returning void.");
  }

  // We need to load the exceptional return value as a constant in the generated
  // function. This means we need to ensure that it's in old space and has no
  // (transitively) mutable fields. This is done by checking (asserting) that
  // it's a built-in FFI class, whose fields are all immutable, or a
  // user-defined Pointer class, which has no fields.
  //
  // TODO(36730): We'll need to extend this when we support passing/returning
  // structs by value.
  ASSERT(exceptional_return.IsNull() || exceptional_return.IsNumber() ||
         exceptional_return.IsPointer());
  if (!exceptional_return.IsSmi() && exceptional_return.IsNew()) {
    function.SetFfiCallbackExceptionalReturn(
        Instance::Handle(exceptional_return.CopyShallowToOldSpace(thread)));
  } else {
    function.SetFfiCallbackExceptionalReturn(exceptional_return);
  }

  // We compile the callback immediately because we need to return a pointer to
  // the entry-point. Native calls do not use patching like Dart calls, so we
  // cannot compile it lazily.
  const Object& result =
      Object::Handle(Z, Compiler::CompileOptimizedFunction(thread, function));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  ASSERT(result.IsCode());
  const Code& code = Code::Cast(result);

  thread->SetFfiCallbackCode(callback_id, code);

  return code.EntryPoint();
#endif  // defined(TARGET_ARCH_DBC)
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)

DEFINE_NATIVE_ENTRY(Ffi_fromFunction, 1, 2) {
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  UNREACHABLE();
#else
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, exceptional_return,
                               arguments->NativeArgAt(1));

  if (!type_arg.IsInstantiated() || !type_arg.IsFunctionType()) {
    // TODO(35902): Remove this when dynamic invocations of fromFunction are
    // prohibited.
    Exceptions::ThrowUnsupportedError(
        "Type argument to fromFunction must an instantiated function type.");
  }

  const Function& native_signature =
      Function::Handle(Type::Cast(type_arg).signature());
  Function& func = Function::Handle(closure.function());
  TypeArguments& type_args = TypeArguments::Handle(zone);
  type_args = TypeArguments::New(1);
  type_args.SetTypeAt(Pointer::kNativeTypeArgPos, type_arg);
  type_args = type_args.Canonicalize();

  Class& native_function_class =
      Class::Handle(isolate->class_table()->At(kFfiNativeFunctionCid));
  native_function_class.EnsureIsFinalized(Thread::Current());

  Type& native_function_type = Type::Handle(
      Type::New(native_function_class, type_args, TokenPosition::kNoSource));
  native_function_type ^=
      ClassFinalizer::FinalizeType(Class::Handle(), native_function_type);
  native_function_type ^= native_function_type.Canonicalize();

  // The FE verifies that the target of a 'fromFunction' is a static method, so
  // the value we see here must be a static tearoff. See ffi_use_sites.dart for
  // details.
  //
  // TODO(36748): Define hot-reload semantics of native callbacks. We may need
  // to look up the target by name.
  ASSERT(func.IsImplicitClosureFunction());
  func = func.parent_function();
  ASSERT(func.is_static());

  const AbstractType& return_type =
      AbstractType::Handle(native_signature.result_type());
  if (compiler::ffi::NativeTypeIsVoid(return_type)) {
    if (!exceptional_return.IsNull()) {
      const String& error = String::Handle(
          String::NewFormatted("Exceptional return argument to 'fromFunction' "
                               "must be null for functions returning void."));
      Exceptions::ThrowArgumentError(error);
    }
  } else if (!compiler::ffi::NativeTypeIsPointer(return_type) &&
             exceptional_return.IsNull()) {
    const String& error = String::Handle(String::NewFormatted(
        "Exceptional return argument to 'fromFunction' must not be null."));
    Exceptions::ThrowArgumentError(error);
  }

  const uword address =
      CompileNativeCallback(native_signature, func, exceptional_return);

  const Pointer& result = Pointer::Handle(Pointer::New(
      native_function_type, Integer::Handle(zone, Integer::New(address))));

  return result.raw();
#endif
}

#if defined(TARGET_ARCH_DBC)

void FfiMarshalledArguments::SetFunctionAddress(uint64_t value) const {
  data_[kOffsetFunctionAddress] = value;
}

static intptr_t ArgumentHostRegisterIndex(host::Register reg) {
  for (intptr_t i = 0; i < host::CallingConventions::kNumArgRegs; i++) {
    if (host::CallingConventions::ArgumentRegisters[i] == reg) {
      return i;
    }
  }
  UNREACHABLE();
}

void FfiMarshalledArguments::SetRegister(host::Register reg,
                                         uint64_t value) const {
  const intptr_t reg_index = ArgumentHostRegisterIndex(reg);
  ASSERT(host::CallingConventions::ArgumentRegisters[reg_index] == reg);
  const intptr_t index = kOffsetRegisters + reg_index;
  data_[index] = value;
}

void FfiMarshalledArguments::SetFpuRegister(host::FpuRegister reg,
                                            uint64_t value) const {
  const intptr_t fpu_index = static_cast<intptr_t>(reg);
  ASSERT(host::CallingConventions::FpuArgumentRegisters[fpu_index] == reg);
  const intptr_t index = kOffsetFpuRegisters + fpu_index;
  data_[index] = value;
}

void FfiMarshalledArguments::SetNumStackSlots(intptr_t num_args) const {
  data_[kOffsetNumStackSlots] = num_args;
}

void FfiMarshalledArguments::SetAlignmentMask(uint64_t alignment_mask) const {
  data_[kOffsetAlignmentMask] = alignment_mask;
}

intptr_t FfiMarshalledArguments::GetNumStackSlots() const {
  return data_[kOffsetNumStackSlots];
}

void FfiMarshalledArguments::SetStackSlotValue(intptr_t index,
                                               uint64_t value) const {
  ASSERT(0 <= index && index < GetNumStackSlots());
  data_[kOffsetStackSlotValues + index] = value;
}

uint64_t* FfiMarshalledArguments::New(
    const compiler::ffi::FfiSignatureDescriptor& signature,
    const uint64_t* arg_values) {
  const intptr_t num_stack_slots = signature.num_stack_slots();
  const uint64_t alignment_mask = ~(OS::ActivationFrameAlignment() - 1);
  const intptr_t size =
      FfiMarshalledArguments::kOffsetStackSlotValues + num_stack_slots;
  uint64_t* data = Thread::Current()->GetFfiMarshalledArguments(size);
  const auto& descr = FfiMarshalledArguments(data);

  descr.SetFunctionAddress(arg_values[compiler::ffi::kFunctionAddressRegister]);
  const intptr_t num_args = signature.length();
  descr.SetNumStackSlots(num_stack_slots);
  descr.SetAlignmentMask(alignment_mask);
  for (int i = 0; i < num_args; i++) {
    uint64_t arg_value = arg_values[compiler::ffi::kFirstArgumentRegister + i];
    HostLocation loc = signature.LocationAt(i);
    // TODO(36809): For 32 bit, support pair locations.
    if (loc.IsRegister()) {
      descr.SetRegister(loc.reg(), arg_value);
    } else if (loc.IsFpuRegister()) {
      descr.SetFpuRegister(loc.fpu_reg(), arg_value);
    } else {
      ASSERT(loc.IsStackSlot() || loc.IsDoubleStackSlot());
      ASSERT(loc.stack_index() < num_stack_slots);
      descr.SetStackSlotValue(loc.stack_index(), arg_value);
    }
  }

  return data;
}

#if defined(DEBUG)
void FfiMarshalledArguments::Print() const {
  OS::PrintErr("FfiMarshalledArguments data_ 0x%" Pp "\n",
               reinterpret_cast<intptr_t>(data_));
  OS::PrintErr("  00 0x%016" Px64 " (function address, int result)\n",
               data_[0]);
  for (intptr_t i = 0; i < host::CallingConventions::kNumArgRegs; i++) {
    const intptr_t index = kOffsetRegisters + i;
    const char* result_str = i == 0 ? ", float result" : "";
    OS::PrintErr("  %02" Pd " 0x%016" Px64 " (%s%s)\n", index, data_[index],
                 RegisterNames::RegisterName(
                     host::CallingConventions::ArgumentRegisters[i]),
                 result_str);
  }
  for (intptr_t i = 0; i < host::CallingConventions::kNumFpuArgRegs; i++) {
    const intptr_t index = kOffsetFpuRegisters + i;
    OS::PrintErr("  %02" Pd " 0x%016" Px64 " (%s)\n", index, data_[index],
                 RegisterNames::FpuRegisterName(
                     host::CallingConventions::FpuArgumentRegisters[i]));
  }
  const intptr_t alignment_mask = data_[kOffsetAlignmentMask];
  OS::PrintErr("  %02" Pd " 0x%" Pp " (stack alignment mask)\n",
               kOffsetAlignmentMask, alignment_mask);
  const intptr_t num_stack_slots = data_[kOffsetNumStackSlots];
  OS::PrintErr("  %02" Pd " 0x%" Pp " (number of stack slots)\n",
               kOffsetNumStackSlots, num_stack_slots);
  for (intptr_t i = 0; i < num_stack_slots; i++) {
    const intptr_t index = kOffsetStackSlotValues + i;
    OS::PrintErr("  %02" Pd " 0x%016" Px64 " (stack slot %" Pd ")\n", index,
                 data_[index], i);
  }
}
#endif  // defined(DEBUG)

#endif  // defined(TARGET_ARCH_DBC)

}  // namespace dart
