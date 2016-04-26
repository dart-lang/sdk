// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"

#include <stdio.h>

#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

Dart_Handle Extensions::LoadExtension(const char* extension_directory,
                                      const char* extension_name,
                                      Dart_Handle parent_library) {
  if (strncmp(extension_directory, "http://", 7) == 0 ||
      strncmp(extension_directory, "https://", 8) == 0) {
    return Dart_NewApiError("Cannot load native extensions over http:");
  }

  // For example on Linux: directory/libfoo-arm.so
  const char* library_strings[] = {
    extension_directory,  // directory/
    Platform::LibraryPrefix(),  // lib
    extension_name,  // foo
    "-",
    Platform::HostArchitecture(),  // arm
    ".",
    Platform::LibraryExtension(),  // so
    NULL,
  };
  const char* library_file = Concatenate(library_strings);
  void* library_handle = LoadExtensionLibrary(library_file);
  if (library_handle == NULL) {
    // Fallback on a library file name that does not specify the host
    // architecture. For example on Linux: directory/libfoo.so
    const char* fallback_library_strings[] = {
      extension_directory,  // directory/
      Platform::LibraryPrefix(),  // lib
      extension_name,  // foo
      ".",
      Platform::LibraryExtension(),  // so
      NULL,
    };
    const char* fallback_library_file = Concatenate(fallback_library_strings);
    library_handle = LoadExtensionLibrary(fallback_library_file);
    if (library_handle == NULL) {
      return GetError();
    }
  }

  const char* strings[] = { extension_name, "_Init", NULL };
  const char* init_function_name = Concatenate(strings);
  void* init_function = ResolveSymbol(library_handle, init_function_name);
  Dart_Handle result = GetError();
  if (Dart_IsError(result)) {
    return result;
  }
  ASSERT(init_function != NULL);
  typedef Dart_Handle (*InitFunctionType)(Dart_Handle import_map);
  InitFunctionType fn = reinterpret_cast<InitFunctionType>(init_function);
  return (*fn)(parent_library);
}


// Concatenates a NULL terminated array of strings.
// The returned string is scope allocated.
const char* Extensions::Concatenate(const char** strings) {
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

}  // namespace bin
}  // namespace dart
