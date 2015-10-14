// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/extensions.h"
#include <dlfcn.h>  // NOLINT


namespace dart {
namespace bin {

const char* kPrecompiledLibraryName = "libprecompiled.so";
const char* kPrecompiledSymbolName = "_kInstructionsSnapshot";

Dart_Handle Extensions::LoadExtensionLibrary(const char* library_file,
                                             void** library_handle) {
  ASSERT(library_handle != NULL);
  *library_handle = dlopen(library_file, RTLD_LAZY);
  if (*library_handle == NULL) {
    return Dart_NewApiError(dlerror());
  }
  return Dart_Null();
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

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
