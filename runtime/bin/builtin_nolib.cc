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
    {DartUtils::kBuiltinLibURL, NULL, NULL, NULL, true},
    {DartUtils::kIOLibURL, NULL, NULL, NULL, true},
    {DartUtils::kHttpLibURL, NULL, NULL, NULL, false},
    // End marker.
    {NULL, NULL, NULL, NULL, false}};

Dart_Port Builtin::load_port_ = ILLEGAL_PORT;
const int Builtin::num_libs_ =
    sizeof(Builtin::builtin_libraries_) / sizeof(Builtin::builtin_lib_props);

Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  return DartUtils::NewError("Unreachable code in Builtin::Source (%d).", id);
}

Dart_Handle Builtin::PartSource(BuiltinLibraryId id, const char* uri) {
  return DartUtils::NewError("Unreachable code in Builtin::PartSource (%d).",
                             id);
}

Dart_Handle Builtin::GetSource(const char** source_paths, const char* uri) {
  return DartUtils::NewError("Unreachable code in Builtin::GetSource (%s).",
                             uri);
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
  return DartUtils::NewError("Unreachable code in Builtin::LoadLibrary (%d).",
                             id);
}

Builtin::BuiltinLibraryId Builtin::FindId(const char* url_string) {
  return kInvalidLibrary;
}

Dart_Handle Builtin::LoadAndCheckLibrary(BuiltinLibraryId id) {
  ASSERT(static_cast<int>(id) >= 0);
  ASSERT(static_cast<int>(id) < num_libs_);

  Dart_Handle url = DartUtils::NewString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  return library;
}

}  // namespace bin
}  // namespace dart
