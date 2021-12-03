// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/native_entry.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
#include <dlfcn.h>
#endif

namespace dart {

static void* LoadDynamicLibrary(const char* library_file) {
  char* error = nullptr;
  void* handle = Utils::LoadDynamicLibrary(library_file, &error);
  if (error != nullptr) {
    const String& msg = String::Handle(String::NewFormatted(
        "Failed to load dynamic library '%s': %s",
        library_file != nullptr ? library_file : "<process>", error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return handle;
}

static void* ResolveSymbol(void* handle, const char* symbol) {
  char* error = nullptr;
  void* result = Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
  if (error != nullptr) {
    const String& msg = String::Handle(String::NewFormatted(
        "Failed to lookup symbol '%s': %s", symbol, error));
    free(error);
    Exceptions::ThrowArgumentError(msg);
  }
  return result;
}

static bool SymbolExists(void* handle, const char* symbol) {
  char* error = nullptr;
  Utils::ResolveSymbolInDynamicLibrary(handle, symbol, &error);
  if (error != nullptr) {
    free(error);
    return false;
  }
  return true;
}

DEFINE_NATIVE_ENTRY(Ffi_dl_open, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, lib_path, arguments->NativeArgAt(0));

  void* handle = LoadDynamicLibrary(lib_path.ToCString());

  return DynamicLibrary::New(handle);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_processLibrary, 0, 0) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  return DynamicLibrary::New(RTLD_DEFAULT);
#else
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0,
             String::Handle(String::New(
                 "DynamicLibrary.process is not available on this platform.")));
  Exceptions::ThrowByType(Exceptions::kUnsupported, args);
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_executableLibrary, 0, 0) {
  return DynamicLibrary::New(LoadDynamicLibrary(nullptr));
}

DEFINE_NATIVE_ENTRY(Ffi_dl_lookup, 1, 2) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));

  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

  void* handle = dlib.GetHandle();

  const uword pointer =
      reinterpret_cast<uword>(ResolveSymbol(handle, argSymbolName.ToCString()));
  return Pointer::New(type_arg, pointer);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_getHandle, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));

  intptr_t handle = reinterpret_cast<intptr_t>(dlib.GetHandle());
  return Integer::NewFromUint64(handle);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_providesSymbol, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

  void* handle = dlib.GetHandle();
  return Bool::Get(SymbolExists(handle, argSymbolName.ToCString())).ptr();
}

}  // namespace dart
