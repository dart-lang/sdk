// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/native_entry.h"

#if !defined(HOST_OS_LINUX) && !defined(HOST_OS_MACOS) &&                      \
    !defined(HOST_OS_ANDROID) && !defined(HOST_OS_FUCHSIA)
// TODO(dacoharkes): Implement dynamic libraries for other targets & merge the
// implementation with:
// - runtime/bin/extensions.h
// - runtime/bin/extensions_linux.cc
// TODO(dacoharkes): Make the code from bin available in a manner similar to
// runtime/vm/dart.h Dart_FileReadCallback.
#else
#include <dlfcn.h>
#endif

namespace dart {

static void* LoadExtensionLibrary(const char* library_file) {
#if defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                        \
    defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA)
  void* handle = dlopen(library_file, RTLD_LAZY);
  if (handle == nullptr) {
    char* error = dlerror();
    const String& msg = String::Handle(
        String::NewFormatted("Failed to load dynamic library (%s)", error));
    Exceptions::ThrowArgumentError(msg);
  }

  return handle;
#elif defined(HOST_OS_WINDOWS)
  SetLastError(0);  // Clear any errors.

  void* ext;

  if (library_file == nullptr) {
    ext = GetModuleHandle(nullptr);
  } else {
    // Convert to wchar_t string.
    const int name_len =
        MultiByteToWideChar(CP_UTF8, 0, library_file, -1, NULL, 0);
    wchar_t* name = new wchar_t[name_len];
    MultiByteToWideChar(CP_UTF8, 0, library_file, -1, name, name_len);

    ext = LoadLibraryW(name);
    delete[] name;
  }

  if (ext == nullptr) {
    const int error = GetLastError();
    const String& msg = String::Handle(
        String::NewFormatted("Failed to load dynamic library (%i)", error));
    Exceptions::ThrowArgumentError(msg);
  }

  return ext;
#else
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0,
             String::Handle(String::New(
                 "The dart:ffi library is not available on this platform.")));
  Exceptions::ThrowByType(Exceptions::kUnsupported, args);
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_open, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, lib_path, arguments->NativeArgAt(0));

  void* handle = LoadExtensionLibrary(lib_path.ToCString());

  return DynamicLibrary::New(handle);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_processLibrary, 0, 0) {
#if defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                        \
    defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA)
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
  return DynamicLibrary::New(LoadExtensionLibrary(nullptr));
}

static void* ResolveSymbol(void* handle, const char* symbol) {
#if defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                        \
    defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA)
  dlerror();  // Clear any errors.
  void* pointer = dlsym(handle, symbol);
  if (pointer == nullptr) {
    char* error = dlerror();
    const String& msg = String::Handle(
        String::NewFormatted("Failed to lookup symbol (%s)", error));
    Exceptions::ThrowArgumentError(msg);
  }
  return pointer;
#elif defined(HOST_OS_WINDOWS)
  SetLastError(0);
  void* pointer = reinterpret_cast<void*>(
      GetProcAddress(reinterpret_cast<HMODULE>(handle), symbol));
  if (pointer == nullptr) {
    const int error = GetLastError();
    const String& msg = String::Handle(
        String::NewFormatted("Failed to lookup symbol (%i)", error));
    Exceptions::ThrowArgumentError(msg);
  }
  return pointer;
#else
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0,
             String::Handle(String::New(
                 "The dart:ffi library is not available on this platform.")));
  Exceptions::ThrowByType(Exceptions::kUnsupported, args);
#endif
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

}  // namespace dart
