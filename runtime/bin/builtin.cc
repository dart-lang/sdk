// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

namespace dart {
namespace bin {

Builtin::builtin_lib_props Builtin::builtin_libraries_[] = {
  /* { url_, source_, patch_url_, patch_source_, has_natives_ } */
  { DartUtils::kBuiltinLibURL, builtin_source_paths_, NULL, NULL, true },
  { DartUtils::kIOLibURL, io_source_paths_,
    DartUtils::kIOLibPatchURL, io_patch_paths_, true },
};


// Patch all the specified patch files in the array 'patch_files' into the
// library specified in 'library'.
static void LoadPatchFiles(Dart_Handle library,
                           const char* patch_uri,
                           const char** patch_files) {
  for (intptr_t j = 0; patch_files[j] != NULL; j += 2) {
    Dart_Handle patch_src = DartUtils::ReadStringFromFile(patch_files[j + 1]);

    // Prepend the patch library URI to form a unique script URI for the patch.
    intptr_t len = snprintf(NULL, 0, "%s/%s", patch_uri, patch_files[j]);
    char* patch_filename = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(patch_filename, len + 1, "%s/%s", patch_uri, patch_files[j]);
    Dart_Handle patch_file_uri = DartUtils::NewString(patch_filename);
    free(patch_filename);

    DART_CHECK_VALID(Dart_LibraryLoadPatch(library, patch_file_uri, patch_src));
  }
}


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);

  // Try to read the source using the path specified for the uri.
  const char* uri = builtin_libraries_[id].url_;
  const char** source_paths = builtin_libraries_[id].source_paths_;
  return GetSource(source_paths, uri);
}


Dart_Handle Builtin::PartSource(BuiltinLibraryId id, const char* part_uri) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);

  // Try to read the source using the path specified for the uri.
  const char** source_paths = builtin_libraries_[id].source_paths_;
  return GetSource(source_paths, part_uri);
}


Dart_Handle Builtin::GetSource(const char** source_paths, const char* uri) {
  if (source_paths == NULL) {
    return Dart_Null();  // No path mapping information exists for library.
  }
  const char* source_path = NULL;
  for (intptr_t i = 0; source_paths[i] != NULL; i += 2) {
    if (!strcmp(uri, source_paths[i])) {
      source_path = source_paths[i + 1];
      break;
    }
  }
  if (source_path == NULL) {
    return Dart_Null();  // Uri does not exist in path mapping information.
  }
  return DartUtils::ReadStringFromFile(source_path);
}


void Builtin::SetNativeResolver(BuiltinLibraryId id) {
  UNREACHABLE();
}


Dart_Handle Builtin::LoadLibrary(Dart_Handle url, BuiltinLibraryId id) {
  Dart_Handle library = Dart_LoadLibrary(url, Source(id), 0, 0);
  if (!Dart_IsError(library) && (builtin_libraries_[id].has_natives_)) {
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(
        Dart_SetNativeResolver(library, NativeLookup, NativeSymbol));
  }
  if (builtin_libraries_[id].patch_url_ != NULL) {
    ASSERT(builtin_libraries_[id].patch_paths_ != NULL);
    LoadPatchFiles(library,
                   builtin_libraries_[id].patch_url_,
                   builtin_libraries_[id].patch_paths_);
  }
  return library;
}


Dart_Handle Builtin::LoadAndCheckLibrary(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);
  Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  if (Dart_IsError(library)) {
    library = LoadLibrary(url, id);
  }
  DART_CHECK_VALID(library);
  return library;
}

}  // namespace bin
}  // namespace dart
