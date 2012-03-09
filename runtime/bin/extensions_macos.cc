// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"
#include <dlfcn.h>

void* Extensions::LoadExtensionLibrary(const char* library_name) {
  const char* strings[4] = { "./lib", library_name, ".dylib", NULL };
  char* library_path = Concatenate(strings);
  void* lib_handle = dlopen(library_path, RTLD_LAZY);
  free(library_path);
  return lib_handle;
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  void* result = dlsym(lib_handle, symbol);
  if (dlerror() != NULL) return NULL;
  return result;
}
