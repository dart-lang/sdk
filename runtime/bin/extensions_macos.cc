// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/extensions.h"
#include <dlfcn.h>  // NOLINT


namespace dart {
namespace bin {

const char* kPrecompiledLibraryName = "libprecompiled.dylib";
const char* kPrecompiledSymbolName = "kInstructionsSnapshot";

Dart_Handle Extensions::LoadExtensionLibrary(const char* library_file,
                                             void** library_handle) {
  ASSERT(library_handle != NULL);
  *library_handle = dlopen(library_file, RTLD_LAZY);
  if (*library_handle == NULL) {
    return Dart_NewApiError(dlerror());
  }
  return Dart_Null();
}

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  return dlopen(library_file, RTLD_LAZY);
}

Dart_Handle Extensions::ResolveSymbol(void* lib_handle,
                                      const char* symbol,
                                      void** init_function) {
  ASSERT(init_function != NULL);
  dlerror();
  *init_function = dlsym(lib_handle, symbol);
  char* err_str = dlerror();
  if (err_str != NULL) {
    return Dart_NewApiError(err_str);
  }
  return Dart_Null();
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  dlerror();
  void* result = dlsym(lib_handle, symbol);
  if (dlerror() != NULL) return NULL;
  return result;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
