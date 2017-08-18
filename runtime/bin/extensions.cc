// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/extensions.h"

#include <stdio.h>

#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "bin/utils.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

static char PathSeparator() {
  const char* sep = File::PathSeparator();
  ASSERT(strlen(sep) == 1);
  return sep[0];
}

void* Extensions::MakePathAndResolve(const char* dir, const char* name) {
  // First try to find the library with a suffix specifying the architecture.
  {
    const char* path_components[] = {
        dir,
        Platform::LibraryPrefix(),
        name,
        "-",
        Platform::HostArchitecture(),  // arm
        ".",
        Platform::LibraryExtension(),  // so
        NULL,
    };
    const char* library_file = Concatenate(path_components);
    void* library_handle = LoadExtensionLibrary(library_file);
    if (library_handle != NULL) {
      return library_handle;
    }
  }

  // Fall back on a library name without the suffix.
  {
    const char* path_components[] = {
        dir,
        Platform::LibraryPrefix(),
        name,
        ".",
        Platform::LibraryExtension(),  // so
        NULL,
    };
    const char* library_file = Concatenate(path_components);
    return LoadExtensionLibrary(library_file);
  }
}

// IMPORTANT: In the absolute path case, do not extract the filename and search
// for that by passing it to LoadLibrary. That can lead to confusion in
// which the absolute path is wrong, and a different version of the library is
// loaded from the standard location.
void* Extensions::ResolveAbsPathExtension(const char* extension_path) {
  const char* last_slash = strrchr(extension_path, PathSeparator()) + 1;
  char* name = strdup(last_slash);
  char* dir = StringUtils::StrNDup(extension_path, last_slash - extension_path);
  void* library_handle = MakePathAndResolve(dir, name);
  free(dir);
  free(name);
  return library_handle;
}

void* Extensions::ResolveExtension(const char* extension_directory,
                                   const char* extension_name) {
  // If the path following dart-ext is an absolute path, then only look for the
  // library there.
  if (File::IsAbsolutePath(extension_name)) {
    return ResolveAbsPathExtension(extension_name);
  }

  // If the path following dart-ext is just a file name, first look next to
  // the importing Dart library.
  void* library_handle =
      MakePathAndResolve(extension_directory, extension_name);
  if (library_handle != NULL) {
    return library_handle;
  }

  // Then pass the library name down to the platform. E.g. dlopen will do its
  // own search in standard search locations.
  return MakePathAndResolve("", extension_name);
}

Dart_Handle Extensions::LoadExtension(const char* extension_directory,
                                      const char* extension_name,
                                      Dart_Handle parent_library) {
  void* library_handle = ResolveExtension(extension_directory, extension_name);
  if (library_handle == NULL) {
    return GetError();
  }

  const char* extension = extension_name;
  if (File::IsAbsolutePath(extension_name)) {
    extension = strrchr(extension_name, PathSeparator()) + 1;
  }

  const char* strings[] = {extension, "_Init", NULL};
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
