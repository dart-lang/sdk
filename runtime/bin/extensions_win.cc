// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"

void* Extensions::LoadExtensionLibrary(const char* library_name) {
  const char* strings[3] = { library_name, ".dll", NULL };
  char* library_path = Concatenate(strings);
  void* lib_handle = LoadLibrary(library_path);
  free(library_path);
  return lib_handle;
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  return GetProcAddress(reinterpret_cast<HMODULE>(lib_handle), symbol);
}
