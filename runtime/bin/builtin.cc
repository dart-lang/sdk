// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/platform.h"

namespace dart {
namespace bin {

Builtin::builtin_lib_props Builtin::builtin_libraries_[] = {
    /* { url_, source_, patch_url_, patch_source_, has_natives_ } */
    {DartUtils::kBuiltinLibURL, _builtin_source_paths_, NULL, NULL, true},
    {DartUtils::kIOLibURL, io_source_paths_, DartUtils::kIOLibPatchURL,
     io_patch_paths_, true},

#if defined(DART_NO_SNAPSHOT)
    // Only include these libraries in the dart_bootstrap case for now.
    {"dart:html", html_source_paths_, NULL, NULL, true},
    {"dart:html_common", html_common_source_paths_, NULL, NULL, true},
    {"dart:js", js_source_paths_, NULL, NULL, true},
    {"dart:js_util", js_util_source_paths_, NULL, NULL, true},
    {"dart:_blink", _blink_source_paths_, NULL, NULL, true},
    {"dart:indexed_db", indexed_db_source_paths_, NULL, NULL, true},
    {"cached_patches.dart", cached_patches_source_paths_, NULL, NULL, true},
    {"dart:web_gl", web_gl_source_paths_, NULL, NULL, true},
    {"metadata.dart", metadata_source_paths_, NULL, NULL, true},
    {"dart:web_sql", web_sql_source_paths_, NULL, NULL, true},
    {"dart:svg", svg_source_paths_, NULL, NULL, true},
    {"dart:web_audio", web_audio_source_paths_, NULL, NULL, true},
#endif  // defined(DART_NO_SNAPSHOT)

    // End marker.
    {NULL, NULL, NULL, NULL, false}};

Dart_Port Builtin::load_port_ = ILLEGAL_PORT;
const int Builtin::num_libs_ =
    sizeof(Builtin::builtin_libraries_) / sizeof(Builtin::builtin_lib_props);

// Patch all the specified patch files in the array 'patch_files' into the
// library specified in 'library'.
static void LoadPatchFiles(Dart_Handle library,
                           const char* patch_uri,
                           const char** patch_files) {
  for (intptr_t j = 0; patch_files[j] != NULL; j += 2) {
    // Use the sources linked in the binary.
    const char* source = patch_files[j + 1];
    Dart_Handle patch_src = Dart_NewStringFromUTF8(
        reinterpret_cast<const uint8_t*>(source), strlen(source));

    // Prepend the patch library URI to form a unique script URI for the patch.
    intptr_t len = snprintf(NULL, 0, "%s/%s", patch_uri, patch_files[j]);
    char* patch_filename = DartUtils::ScopedCString(len + 1);
    snprintf(patch_filename, len + 1, "%s/%s", patch_uri, patch_files[j]);
    Dart_Handle patch_file_uri = DartUtils::NewString(patch_filename);

    DART_CHECK_VALID(Dart_LibraryLoadPatch(library, patch_file_uri, patch_src));
  }
}


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  // Try to read the source using the path specified for the uri.
  const char* uri = builtin_libraries_[id].url_;
  const char** source_paths = builtin_libraries_[id].source_paths_;
  return GetSource(source_paths, uri);
}


Dart_Handle Builtin::PartSource(BuiltinLibraryId id, const char* part_uri) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  // Try to read the source using the path specified for the uri.
  const char** source_paths = builtin_libraries_[id].source_paths_;
  return GetSource(source_paths, part_uri);
}


Dart_Handle Builtin::GetSource(const char** source_paths, const char* uri) {
  if (source_paths == NULL) {
    return Dart_Null();  // No path mapping information exists for library.
  }
  for (intptr_t i = 0; source_paths[i] != NULL; i += 2) {
    if (!strcmp(uri, source_paths[i])) {
      // Use the sources linked in the binary.
      const char* source = source_paths[i + 1];
      return Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(source),
                                    strlen(source));
    }
  }
  return Dart_Null();  // Uri does not exist in path mapping information.
}


void Builtin::SetNativeResolver(BuiltinLibraryId id) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  if (builtin_libraries_[id].has_natives_) {
    Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
    Dart_Handle library = Dart_LookupLibrary(url);
    ASSERT(!Dart_IsError(library));
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(
        Dart_SetNativeResolver(library, NativeLookup, NativeSymbol));
  }
}


Dart_Handle Builtin::LoadLibrary(Dart_Handle url, BuiltinLibraryId id) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  Dart_Handle library = Dart_LoadLibrary(url, Dart_Null(), Source(id), 0, 0);
  if (!Dart_IsError(library) && (builtin_libraries_[id].has_natives_)) {
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(
        Dart_SetNativeResolver(library, NativeLookup, NativeSymbol));
  }
  if (builtin_libraries_[id].patch_url_ != NULL) {
    ASSERT(builtin_libraries_[id].patch_paths_ != NULL);
    LoadPatchFiles(library, builtin_libraries_[id].patch_url_,
                   builtin_libraries_[id].patch_paths_);
  }
  return library;
}


Builtin::BuiltinLibraryId Builtin::FindId(const char* url_string) {
  int id = 0;
  while (true) {
    if (builtin_libraries_[id].url_ == NULL) {
      return kInvalidLibrary;
    }
    if (strcmp(url_string, builtin_libraries_[id].url_) == 0) {
      return static_cast<BuiltinLibraryId>(id);
    }
    id++;
  }
}


Dart_Handle Builtin::LoadAndCheckLibrary(BuiltinLibraryId id) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  if (Dart_IsError(library)) {
    library = LoadLibrary(url, id);
  }
  return library;
}

}  // namespace bin
}  // namespace dart
