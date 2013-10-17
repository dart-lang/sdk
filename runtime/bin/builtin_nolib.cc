// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/io_natives.h"


namespace dart {
namespace bin {

Builtin::builtin_lib_props Builtin::builtin_libraries_[] = {
  /* { url_, source_, patch_url_, patch_source_, has_natives_ } */
  { DartUtils::kBuiltinLibURL, NULL, NULL, NULL, true },
  { DartUtils::kIOLibURL, NULL, NULL, NULL, true  },
};


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  return DartUtils::NewError("Unreachable code in Builtin::Source (%d).", id);
}


Dart_Handle Builtin::PartSource(BuiltinLibraryId id, const char* uri) {
  return DartUtils::NewError(
      "Unreachable code in Builtin::PartSource (%d).", id);
}


Dart_Handle Builtin::GetSource(const char** source_paths, const char* uri) {
  return DartUtils::NewError(
      "Unreachable code in Builtin::GetSource (%s).", uri);
}


void Builtin::SetNativeResolver(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);
  if (builtin_libraries_[id].has_natives_) {
    Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
    Dart_Handle library = Dart_LookupLibrary(url);
    ASSERT(!Dart_IsError(library));
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(Dart_SetNativeResolver(library, NativeLookup));
  }
}


Dart_Handle Builtin::LoadAndCheckLibrary(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);
  Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  DART_CHECK_VALID(library);
  return library;
}

}  // namespace bin
}  // namespace dart
