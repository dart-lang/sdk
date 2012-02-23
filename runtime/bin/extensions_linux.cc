// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <dlfcn.h>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "bin/extensions.h"
#include "bin/dartutils.h"

Dart_Handle Extensions::LoadExtension(const char* extension_url,
                                      Dart_Handle parent_library) {
  // TODO(whesse): Consider making loading extensions lazy, so the
  // dynamic library is loaded only when first native function is called.
  ASSERT(DartUtils::IsDartExtensionSchemeURL(extension_url));
  const char* library_name =
      extension_url + strlen(DartUtils::kDartExtensionScheme);
  if (strchr(library_name, '/') != NULL) {
    return Dart_Error("path components not allowed in extension library name");
  }
  const int buffer_length = strlen(library_name) + strlen("./lib.so") + 1;
  char* library_path = new char[buffer_length];
  snprintf(library_path, buffer_length, "./lib%s.so", library_name);

  void* lib_handle = dlopen(library_path, RTLD_LAZY);
  if (!lib_handle) {
    delete[] library_path;
    return Dart_Error("cannot find extension library");
  }
  // Reuse library_path buffer for intialization function name.
  char* library_init_function = library_path;
  snprintf(library_init_function, buffer_length, "%s_Init", library_name);
  typedef Dart_Handle (*InitFunctionType)(Dart_Handle import_map);
  InitFunctionType fn = reinterpret_cast<InitFunctionType>(
      dlsym(lib_handle, library_init_function));
  delete[] library_path;
  char *error = dlerror();
  if (error != NULL) {
    return Dart_Error(error);
  }
  return (*fn)(parent_library);
}
