// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(TARGET_OS_LINUX) && !defined(TARGET_OS_MACOS)
// TODO(dacoharkes): implement dynamic libraries for other targets.
// see
// - runtime/vm/native_symbol.h
// - runtime/vm/native_symbol_linux.cc
// - runtime/bin/extensions.h (but we cannot import from bin)
// - runtime/bin/extensions_linux.cc
#else
#include <dlfcn.h>
#endif
#include "include/dart_api.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"

namespace dart {

// Concatenates a NULL terminated array of strings.
// The returned string is scope allocated.
// TODO(dacoharkes): Can we share this with runtime/bin/extensions.cc?
const char* Concatenate(const char** strings) {
  int size = 1;  // null termination.
  for (int i = 0; strings[i] != NULL; i++) {
    size += strlen(strings[i]);
  }
  char* result = reinterpret_cast<char*>(Dart_ScopeAllocate(size));
  int index = 0;
  for (int i = 0; strings[i] != NULL; i++) {
    index += snprintf(result + index, size - index, "%s", strings[i]);
  }
  ASSERT(index == size - 1);
  ASSERT(result[size - 1] == '\0');
  return result;
}

// TODO(dacoharkes): Can we share this with runtime/bin/extensions.cc?
const char* LibraryPath(const char* library_name) {
  const char* library_prefix = "lib";
#if defined(TARGET_OS_LINUX)
  const char* library_extension = "so";
#elif defined(TARGET_OS_MACOS)
  const char* library_extension = "dylib";
#else
  const char* library_extension = "";
  UNREACHABLE();
#endif

  const char* path_components[] = {
      library_prefix, library_name, ".", library_extension, NULL,
  };

  return Concatenate(path_components);
}

DEFINE_NATIVE_ENTRY(Ffi_dl_open, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, argName, arguments->NativeArgAt(0));

#if !defined(TARGET_OS_LINUX) && !defined(TARGET_OS_MACOS)
  UNREACHABLE();
#else
  dlerror();  // Clear any errors.
  void* handle = dlopen(LibraryPath(argName.ToCString()), RTLD_LAZY);
  if (handle == nullptr) {
    char* error = dlerror();
    const String& msg = String::Handle(
        String::NewFormatted("Failed to load dynamic library(%s)", error));
    Exceptions::ThrowArgumentError(msg);
  }

  return DynamicLibrary::New(handle);
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_lookup, 1, 2) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));

  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, argSymbolName,
                               arguments->NativeArgAt(1));

#if !defined(TARGET_OS_LINUX) && !defined(TARGET_OS_MACOS)
  UNREACHABLE();
#else
  void* handle = dlib.GetHandle();

  dlerror();  // Clear any errors.
  uint8_t* pointer =
      reinterpret_cast<uint8_t*>(dlsym(handle, argSymbolName.ToCString()));
  char* error;
  if ((error = dlerror()) != NULL) {
    const String& msg = String::Handle(
        String::NewFormatted("Failed to lookup symbol (%s)", error));
    Exceptions::ThrowArgumentError(msg);
  }

  // TODO(dacoharkes): should this return NULL if addres is 0?
  // https://github.com/dart-lang/sdk/issues/35756
  RawPointer* result = Pointer::New(type_arg, pointer);
  return result;
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_dl_getHandle, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(DynamicLibrary, dlib, arguments->NativeArgAt(0));

  intptr_t handle = reinterpret_cast<intptr_t>(dlib.GetHandle());
  return Integer::NewFromUint64(handle);
}

}  // namespace dart
