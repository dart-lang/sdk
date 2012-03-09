// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"

#include <stdio.h>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "bin/dartutils.h"

Dart_Handle Extensions::LoadExtension(const char* extension_url,
                                      Dart_Handle parent_library) {
  ASSERT(DartUtils::IsDartExtensionSchemeURL(extension_url));
  const char* library_name =
      extension_url + strlen(DartUtils::kDartExtensionScheme);
  if (strchr(library_name, '/') != NULL ||
      strchr(library_name, '\\') != NULL) {
    return Dart_Error("path components not allowed in extension library name");
  }
  void* library_handle = LoadExtensionLibrary(library_name);
  if (!library_handle) {
    return Dart_Error("cannot find extension library");
  }

  const char* strings[3] = { library_name, "_Init", NULL };
  char* init_function_name = Concatenate(strings);
  typedef Dart_Handle (*InitFunctionType)(Dart_Handle import_map);
  InitFunctionType fn = reinterpret_cast<InitFunctionType>(
      ResolveSymbol(library_handle, init_function_name));
  free(init_function_name);

  if (fn == NULL) {
    return Dart_Error("cannot find initialization function in extension");
  }
  return (*fn)(parent_library);
}


// Concatenates a NULL terminated array of strings.
// The returned string must be freed.
char* Extensions::Concatenate(const char** strings) {
  int size = 1;  // null termination.
  for (int i = 0; strings[i] != NULL; i++) {
    size += strlen(strings[i]);
  }
  char* result = reinterpret_cast<char*>(malloc(size));
  int index = 0;
  for (int i = 0; strings[i] != NULL; i++) {
    index += snprintf(result + index, size - index, "%s", strings[i]);
  }
  ASSERT(index == size - 1);
  ASSERT(result[size - 1] == '\0');
  return result;
}
