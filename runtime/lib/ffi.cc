// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_api_dl.h"
#include "include/dart_native_api.h"
#include "include/dart_version.h"
#include "include/internal/dart_api_dl_impl.h"
#include "platform/globals.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/ffi/call.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/jit/compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// The following functions are runtime checks on type arguments.
// Some checks are also performed in kernel transformation, these are asserts.
// Some checks are only performed at runtime to allow for generic code, these
// throw ArgumentExceptions.

static void CheckSized(const AbstractType& type_arg) {
  const classid_t type_cid = type_arg.type_class_id();
  if (IsFfiNativeTypeTypeClassId(type_cid) || IsFfiTypeVoidClassId(type_cid) ||
      IsFfiTypeNativeFunctionClassId(type_cid)) {
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

// Calculate the size of a native type.
//
// You must check [IsConcreteNativeType] and [CheckSized] first to verify that
// this type has a defined size.
static size_t SizeOf(Zone* zone, const AbstractType& type) {
  if (IsFfiTypeClassId(type.type_class_id())) {
    return compiler::ffi::NativeType::FromAbstractType(zone, type)
        .SizeInBytes();
  } else {
    Class& struct_class = Class::Handle(type.type_class());
    Object& result = Object::Handle(
        struct_class.InvokeGetter(Symbols::SizeOfStructField(),
                                  /*throw_nsm_if_absent=*/false,
                                  /*respect_reflectable=*/false));
    ASSERT(!result.IsNull() && result.IsInteger());
    return Integer::Cast(result).AsInt64Value();
  }
}

// The remainder of this file implements the dart:ffi native methods.

DEFINE_NATIVE_ENTRY(Ffi_fromAddress, 1, 1) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Ffi_address, 0, 1) {
  UNREACHABLE();
}

#define DEFINE_NATIVE_ENTRY_LOAD(type)                                         \
  DEFINE_NATIVE_ENTRY(Ffi_load##type, 0, 2) { UNREACHABLE(); }
CLASS_LIST_FFI_NUMERIC(DEFINE_NATIVE_ENTRY_LOAD)
#undef DEFINE_NATIVE_ENTRY_LOAD

DEFINE_NATIVE_ENTRY(Ffi_loadPointer, 1, 2) {
  UNREACHABLE();
}

static ObjectPtr LoadValueStruct(Zone* zone,
                                 const Pointer& target,
                                 const AbstractType& instance_type_arg) {
  // Result is a struct class -- find <class name>.#fromTypedDataBase
  // constructor and call it.
  const Class& cls = Class::Handle(zone, instance_type_arg.type_class());
  const Function& constructor =
      Function::Handle(cls.LookupFunctionAllowPrivate(String::Handle(
          String::Concat(String::Handle(String::Concat(
                             String::Handle(cls.Name()), Symbols::Dot())),
                         Symbols::StructFromTypedDataBase()))));
  ASSERT(!constructor.IsNull());
  ASSERT(constructor.IsGenerativeConstructor());
  ASSERT(!Object::Handle(constructor.VerifyCallEntryPoint()).IsError());
  const Instance& new_object = Instance::Handle(Instance::New(cls));
  ASSERT(cls.is_allocated() || Dart::vm_snapshot_kind() != Snapshot::kFullAOT);
  const Array& args = Array::Handle(zone, Array::New(2));
  args.SetAt(0, new_object);
  args.SetAt(1, target);
  const Object& constructorResult =
      Object::Handle(DartEntry::InvokeFunction(constructor, args));
  ASSERT(!constructorResult.IsError());
  return new_object.raw();
}

DEFINE_NATIVE_ENTRY(Ffi_loadStruct, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  const AbstractType& pointer_type_arg =
      AbstractType::Handle(pointer.type_argument());
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, index, arguments->NativeArgAt(1));

  // TODO(36370): Make representation consistent with kUnboxedFfiIntPtr.
  const size_t address =
      pointer.NativeAddress() + static_cast<intptr_t>(index.AsInt64Value()) *
                                    SizeOf(zone, pointer_type_arg);
  const Pointer& pointer_offset =
      Pointer::Handle(zone, Pointer::New(pointer_type_arg, address));

  return LoadValueStruct(zone, pointer_offset, pointer_type_arg);
}

#define DEFINE_NATIVE_ENTRY_STORE(type)                                        \
  DEFINE_NATIVE_ENTRY(Ffi_store##type, 0, 3) { UNREACHABLE(); }
CLASS_LIST_FFI_NUMERIC(DEFINE_NATIVE_ENTRY_STORE)
#undef DEFINE_NATIVE_ENTRY_STORE

DEFINE_NATIVE_ENTRY(Ffi_storePointer, 0, 3) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Ffi_sizeOf, 1, 0) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  CheckSized(type_arg);

  return Integer::New(SizeOf(zone, type_arg));
}

// Static invocations to this method are translated directly in streaming FGB.
DEFINE_NATIVE_ENTRY(Ffi_asFunctionInternal, 2, 1) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Ffi_asExternalTypedData, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Pointer, pointer, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, count, arguments->NativeArgAt(1));
  const auto& pointer_type_arg = AbstractType::Handle(pointer.type_argument());
  const classid_t type_cid = pointer_type_arg.type_class_id();
  classid_t cid = 0;

  switch (type_cid) {
    case kFfiInt8Cid:
      cid = kExternalTypedDataInt8ArrayCid;
      break;
    case kFfiUint8Cid:
      cid = kExternalTypedDataUint8ArrayCid;
      break;
    case kFfiInt16Cid:
      cid = kExternalTypedDataInt16ArrayCid;
      break;
    case kFfiUint16Cid:
      cid = kExternalTypedDataUint16ArrayCid;
      break;
    case kFfiInt32Cid:
      cid = kExternalTypedDataInt32ArrayCid;
      break;
    case kFfiUint32Cid:
      cid = kExternalTypedDataUint32ArrayCid;
      break;
    case kFfiInt64Cid:
      cid = kExternalTypedDataInt64ArrayCid;
      break;
    case kFfiUint64Cid:
      cid = kExternalTypedDataUint64ArrayCid;
      break;
    case kFfiIntPtrCid:
      cid = kWordSize == 4 ? kExternalTypedDataInt32ArrayCid
                           : kExternalTypedDataInt64ArrayCid;
      break;
    case kFfiFloatCid:
      cid = kExternalTypedDataFloat32ArrayCid;
      break;
    case kFfiDoubleCid:
      cid = kExternalTypedDataFloat64ArrayCid;
      break;
    default: {
      const String& error = String::Handle(
          String::NewFormatted("Cannot create a TypedData from a Pointer to %s",
                               pointer_type_arg.ToCString()));
      Exceptions::ThrowArgumentError(error);
      UNREACHABLE();
    }
  }

  const intptr_t element_count = count.AsInt64Value();

  if (element_count < 0 ||
      element_count > ExternalTypedData::MaxElements(cid)) {
    const String& error = String::Handle(
        String::NewFormatted("Count must be in the range [0, %" Pd "].",
                             ExternalTypedData::MaxElements(cid)));
    Exceptions::ThrowArgumentError(error);
  }

  // The address must be aligned by the element size.
  const intptr_t element_size = ExternalTypedData::ElementSizeFor(cid);
  if (!Utils::IsAligned(pointer.NativeAddress(), element_size)) {
    const String& error = String::Handle(
        String::NewFormatted("Pointer address must be aligned to a multiple of"
                             "the element size (%" Pd ").",
                             element_size));
    Exceptions::ThrowArgumentError(error);
  }

  const auto& typed_data_class =
      Class::Handle(zone, isolate->class_table()->At(cid));
  const auto& error =
      Error::Handle(zone, typed_data_class.EnsureIsAllocateFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  // We disable msan initialization check because the memory may not be
  // initialized yet - dart code might do that later on.
  return ExternalTypedData::New(
      cid, reinterpret_cast<uint8_t*>(pointer.NativeAddress()), element_count,
      Heap::kNew, /*perform_eager_msan_initialization_check=*/false);
}

DEFINE_NATIVE_ENTRY(Ffi_nativeCallbackFunction, 1, 2) {
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  // Calls to this function are removed by the flow-graph builder in AOT.
  // See StreamingFlowGraphBuilder::BuildFfiNativeCallbackFunction().
  UNREACHABLE();
#else
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, exceptional_return,
                               arguments->NativeArgAt(1));

  ASSERT(type_arg.IsInstantiated() && type_arg.IsFunctionType());
  const Function& native_signature =
      Function::Handle(zone, Type::Cast(type_arg).signature());
  Function& func = Function::Handle(zone, closure.function());

  // The FE verifies that the target of a 'fromFunction' is a static method, so
  // the value we see here must be a static tearoff. See ffi_use_sites.dart for
  // details.
  //
  // TODO(36748): Define hot-reload semantics of native callbacks. We may need
  // to look up the target by name.
  ASSERT(func.IsImplicitClosureFunction());
  func = func.parent_function();
  ASSERT(func.is_static());

  // We are returning an object which is not an Instance here. This is only OK
  // because we know that the result will be passed directly to
  // _pointerFromFunction and will not leak out into user code.
  arguments->SetReturn(
      Function::Handle(zone, compiler::ffi::NativeCallbackFunction(
                                 native_signature, func, exceptional_return)));

  // Because we have already set the return value.
  return Object::sentinel().raw();
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_pointerFromFunction, 1, 1) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  const Function& function =
      Function::CheckedHandle(zone, arguments->NativeArg0());

  Code& code = Code::Handle(zone);

#if defined(DART_PRECOMPILED_RUNTIME)
  code = function.CurrentCode();
#else
  // We compile the callback immediately because we need to return a pointer to
  // the entry-point. Native calls do not use patching like Dart calls, so we
  // cannot compile it lazily.
  const Object& result = Object::Handle(
      zone, Compiler::CompileOptimizedFunction(thread, function));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  ASSERT(result.IsCode());
  code ^= result.raw();
#endif

  ASSERT(!code.IsNull());
  thread->SetFfiCallbackCode(function.FfiCallbackId(), code);

#ifdef TARGET_ARCH_IA32
  // On ia32, store the stack delta that we need to use when returning.
  const intptr_t stack_return_delta =
      function.FfiCSignatureReturnsStruct() && CallingConventions::kUsesRet4
          ? compiler::target::kWordSize
          : 0;
  thread->SetFfiCallbackStackReturn(function.FfiCallbackId(),
                                    stack_return_delta);
#endif

  uword entry_point = code.EntryPoint();
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (NativeCallbackTrampolines::Enabled()) {
    entry_point = isolate->native_callback_trampolines()->TrampolineForId(
        function.FfiCallbackId());
  }
#endif

  return Pointer::New(type_arg, entry_point);
}

DEFINE_NATIVE_ENTRY(DartNativeApiFunctionPointer, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name_dart, arguments->NativeArgAt(0));
  const char* name = name_dart.ToCString();

#define RETURN_FUNCTION_ADDRESS(function_name, R, A)                           \
  if (strcmp(name, #function_name) == 0) {                                     \
    return Integer::New(reinterpret_cast<intptr_t>(function_name));            \
  }
  DART_NATIVE_API_DL_SYMBOLS(RETURN_FUNCTION_ADDRESS)
#undef RETURN_FUNCTION_ADDRESS

  const String& error = String::Handle(
      String::NewFormatted("Unknown dart_native_api.h symbol: %s.", name));
  Exceptions::ThrowArgumentError(error);
}

DEFINE_NATIVE_ENTRY(DartApiDLMajorVersion, 0, 0) {
  return Integer::New(DART_API_DL_MAJOR_VERSION);
}

DEFINE_NATIVE_ENTRY(DartApiDLMinorVersion, 0, 0) {
  return Integer::New(DART_API_DL_MINOR_VERSION);
}

static const DartApiEntry dart_api_entries[] = {
#define ENTRY(name, R, A)                                                      \
  DartApiEntry{#name, reinterpret_cast<void (*)()>(name)},
    DART_API_ALL_DL_SYMBOLS(ENTRY)
#undef ENTRY
        DartApiEntry{nullptr, nullptr}};

static const DartApi dart_api_data = {
    DART_API_DL_MAJOR_VERSION, DART_API_DL_MINOR_VERSION, dart_api_entries};

DEFINE_NATIVE_ENTRY(DartApiDLInitializeData, 0, 0) {
  return Integer::New(reinterpret_cast<intptr_t>(&dart_api_data));
}

}  // namespace dart
