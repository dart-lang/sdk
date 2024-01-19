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

DEFINE_NATIVE_ENTRY(Ffi_deleteNativeCallable, 1, 1) {
  const auto& pointer = Pointer::CheckedHandle(zone, arguments->NativeArg0());
  isolate->DeleteFfiCallback(pointer.NativeAddress());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Ffi_updateNativeCallableKeepIsolateAliveCounter, 1, 1) {
  const int64_t delta =
      Integer::CheckedHandle(zone, arguments->NativeArg0()).AsInt64Value();
  isolate->UpdateNativeCallableKeepIsolateAliveCounter(delta);
  return Object::null();
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
