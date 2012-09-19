// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"
#include <dlfcn.h>

void* Extensions::LoadExtensionLibrary(const char* library_path,
                                       const char* extension_name) {
  const char* strings[] = { library_path, "/lib",
                             extension_name, ".so", NULL };
  char* library_file = Concatenate(strings);
  void* lib_handle = dlopen(library_file, RTLD_LAZY);
  free(library_file);
  return lib_handle;
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  dlerror();
  void* result = dlsym(lib_handle, symbol);
  if (dlerror() != NULL) return NULL;
  return result;
}
