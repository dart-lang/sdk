// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/extensions.h"
#include <dlfcn.h>  // NOLINT


namespace dart {
namespace bin {

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  return dlopen(library_file, RTLD_LAZY);
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  dlerror();
  void* result = dlsym(lib_handle, symbol);
  if (dlerror() != NULL) return NULL;
  return result;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
