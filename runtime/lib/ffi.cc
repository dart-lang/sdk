// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_api_dl.h"
#include "include/dart_version.h"
#include "include/internal/dart_api_dl_impl.h"
#include "platform/globals.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/heap/gc_shared.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/jit/compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_NATIVE_ENTRY(Ffi_createNativeCallableListener, 1, 2) {
  const auto& send_function =
      Function::CheckedHandle(zone, arguments->NativeArg0());
  const auto& port =
      ReceivePort::CheckedHandle(zone, arguments->NativeArgAt(1));
  return Pointer::New(
      isolate->CreateAsyncFfiCallback(zone, send_function, port.Id()));
}

DEFINE_NATIVE_ENTRY(Ffi_createNativeCallableIsolateLocal, 1, 3) {
  const auto& trampoline =
      Function::CheckedHandle(zone, arguments->NativeArg0());
  const auto& target = Closure::CheckedHandle(zone, arguments->NativeArgAt(1));
  const bool keep_isolate_alive =
      Bool::CheckedHandle(zone, arguments->NativeArgAt(2)).value();
  return Pointer::New(isolate->CreateIsolateLocalFfiCallback(
      zone, trampoline, target, keep_isolate_alive));
}

DEFINE_NATIVE_ENTRY(Ffi_createNativeCallableIsolateGroupBound, 1, 2) {
  const auto& trampoline =
      Function::CheckedHandle(zone, arguments->NativeArg0());
  const auto& target = Closure::CheckedHandle(zone, arguments->NativeArgAt(1));
  return Pointer::New(
      isolate->CreateIsolateGroupBoundFfiCallback(zone, trampoline, target));
}

DEFINE_NATIVE_ENTRY(Ffi_deleteNativeCallable, 1, 1) {
  const auto& pointer = Pointer::CheckedHandle(zone, arguments->NativeArg0());
  isolate->DeleteFfiCallback(pointer.NativeAddress());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_updateNativeCallableKeepIsolateAliveCounter, 1, 1) {
  const int64_t delta =
      Integer::CheckedHandle(zone, arguments->NativeArg0()).Value();
  isolate->UpdateNativeCallableKeepIsolateAliveCounter(delta);
  return Object::null();
}

static ObjectPtr LoadStoreAbiSpecificInt(Zone* zone,
                                         NativeArguments* arguments,
                                         bool is_load,
                                         bool at_index) {
#if defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)
  const auto& type_args =
      TypeArguments::Handle(zone, arguments->NativeTypeArgs());
  const auto& base = Instance::CheckedHandle(zone, arguments->NativeArgAt(0));
  int64_t offset_in_bytes =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(1)).Value();

  const AbstractType& type_argument =
      AbstractType::Handle(zone, type_args.TypeAt(0));

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  const auto* native_type =
      compiler::ffi::NativeType::FromAbstractType(zone, type_argument, &error);
  if (error != nullptr) {
    const auto& language_error = Error::Handle(
        LanguageError::New(String::Handle(String::New(error, Heap::kOld)),
                           Report::kError, Heap::kOld));
    Report::LongJump(language_error);
  }

  if (at_index) {
    const int64_t index =
        Integer::CheckedHandle(zone, arguments->NativeArgAt(2)).Value();
    offset_in_bytes += index * native_type->SizeInBytes();
  }

  int64_t value = 0;
  if (!is_load) {
    value =
        Integer::CheckedHandle(zone, arguments->NativeArgAt(at_index ? 3 : 2))
            .Value();
  }
  {
    NoSafepointScope no_safepoint;
    void* addr;
    if (base.IsPointer()) {
      addr = reinterpret_cast<void*>(Pointer::Cast(base).NativeAddress() +
                                     offset_in_bytes);
    } else if (base.IsTypedDataBase()) {
      addr = TypedDataBase::Cast(base).DataAddr(offset_in_bytes);
    } else {
      UNREACHABLE();
    }
    if (is_load) {
      ASSERT(native_type->IsPrimitive());
      switch (native_type->AsPrimitive().representation()) {
        case compiler::ffi::kInt8:
          value = *reinterpret_cast<int8_t*>(addr);
          break;
        case compiler::ffi::kInt16:
          value = *reinterpret_cast<int16_t*>(addr);
          break;
        case compiler::ffi::kInt32:
          value = *reinterpret_cast<int32_t*>(addr);
          break;
        case compiler::ffi::kInt64:
          value = *reinterpret_cast<int64_t*>(addr);
          break;
        case compiler::ffi::kUint8:
          value = *reinterpret_cast<uint8_t*>(addr);
          break;
        case compiler::ffi::kUint16:
          value = *reinterpret_cast<uint16_t*>(addr);
          break;
        case compiler::ffi::kUint32:
          value = *reinterpret_cast<uint32_t*>(addr);
          break;
        case compiler::ffi::kUint64:
          value = *reinterpret_cast<uint64_t*>(addr);
          break;
        default:
          UNREACHABLE();
      }
    } else {
      ASSERT(native_type->IsPrimitive());
      switch (native_type->AsPrimitive().representation()) {
        case compiler::ffi::kInt8:
          *reinterpret_cast<int8_t*>(addr) = static_cast<int8_t>(value);
          break;
        case compiler::ffi::kInt16:
          *reinterpret_cast<int16_t*>(addr) = static_cast<int16_t>(value);
          break;
        case compiler::ffi::kInt32:
          *reinterpret_cast<int32_t*>(addr) = static_cast<int32_t>(value);
          break;
        case compiler::ffi::kInt64:
          *reinterpret_cast<int64_t*>(addr) = value;
          break;
        case compiler::ffi::kUint8:
          *reinterpret_cast<uint8_t*>(addr) = static_cast<uint8_t>(value);
          break;
        case compiler::ffi::kUint16:
          *reinterpret_cast<uint16_t*>(addr) = static_cast<uint16_t>(value);
          break;
        case compiler::ffi::kUint32:
          *reinterpret_cast<uint32_t*>(addr) = static_cast<uint32_t>(value);
          break;
        case compiler::ffi::kUint64:
          *reinterpret_cast<uint64_t*>(addr) = static_cast<uint64_t>(value);
          break;
        default:
          UNREACHABLE();
      }
    }
  }
  return is_load ? Integer::New(value) : Object::null();
#else
  UNIMPLEMENTED();
#endif  // defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)
}

DEFINE_NATIVE_ENTRY(Ffi_loadAbiSpecificInt, 1, 2) {
  return LoadStoreAbiSpecificInt(zone, arguments, /*is_load=*/true,
                                 /*at_index=*/false);
}

DEFINE_NATIVE_ENTRY(Ffi_loadAbiSpecificIntAtIndex, 1, 3) {
  return LoadStoreAbiSpecificInt(zone, arguments, /*is_load=*/true,
                                 /*at_index=*/true);
}

DEFINE_NATIVE_ENTRY(Ffi_storeAbiSpecificInt, 1, 3) {
  return LoadStoreAbiSpecificInt(zone, arguments, /*is_load=*/false,
                                 /*at_index=*/false);
}

DEFINE_NATIVE_ENTRY(Ffi_storeAbiSpecificIntAtIndex, 1, 4) {
  return LoadStoreAbiSpecificInt(zone, arguments, /*is_load=*/false,
                                 /*at_index=*/true);
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

DEFINE_FFI_NATIVE_ENTRY(FinalizerEntry_SetExternalSize,
                        void,
                        (Dart_Handle entry_handle, intptr_t external_size)) {
  Thread* const thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  Zone* const zone = thread->zone();
  const auto& entry_object =
      Object::Handle(zone, Api::UnwrapHandle(entry_handle));
  const auto& entry = FinalizerEntry::Cast(entry_object);

  Heap::Space space;
  intptr_t external_size_diff;
  {
    NoSafepointScope no_safepoint;
    space = SpaceForExternal(entry.ptr());
    const intptr_t external_size_old = entry.external_size();
    if (FLAG_trace_finalizers) {
      THR_Print("Setting external size from  %" Pd " to  %" Pd
                " bytes in %s space\n",
                external_size_old, external_size, space == 0 ? "new" : "old");
    }
    external_size_diff = external_size - external_size_old;
    if (external_size_diff == 0) {
      return;
    }
    entry.set_external_size(external_size);
  }
  // The next call cannot be in safepoint.
  if (external_size_diff > 0) {
    if (!thread->isolate_group()->heap()->AllocatedExternal(external_size_diff,
                                                            space)) {
      Exceptions::ThrowOOM();
    }
  } else {
    thread->isolate_group()->heap()->FreedExternal(-external_size_diff, space);
  }
};

namespace {
struct AsTypedListFinalizerData {
  void (*callback)(void*);
  void* token;
};
}  // namespace

DEFINE_FFI_NATIVE_ENTRY(Pointer_asTypedListFinalizerAllocateData, void*, ()) {
  auto* result = malloc(sizeof(AsTypedListFinalizerData));
  // Initialized with FFI stores.
  MSAN_UNPOISON(result, sizeof(AsTypedListFinalizerData));
  return result;
};

void AsTypedListFinalizerCallback(void* peer) {
  const auto* data = reinterpret_cast<AsTypedListFinalizerData*>(peer);
  data->callback(data->token);
  free(peer);
}

DEFINE_FFI_NATIVE_ENTRY(Pointer_asTypedListFinalizerCallbackPointer,
                        void*,
                        ()) {
  return reinterpret_cast<void*>(&AsTypedListFinalizerCallback);
};

}  // namespace dart
