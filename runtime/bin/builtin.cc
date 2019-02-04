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
    /* { url_, has_natives_ } */
    {DartUtils::kBuiltinLibURL, true},
    {DartUtils::kIOLibURL, true},
    {DartUtils::kHttpLibURL, false},
    {DartUtils::kCLILibURL, true},

    // End marker.
    {NULL, false}};

Dart_Port Builtin::load_port_ = ILLEGAL_PORT;
const int Builtin::num_libs_ =
    sizeof(Builtin::builtin_libraries_) / sizeof(Builtin::builtin_lib_props);

Dart_Handle Builtin::PartSource(BuiltinLibraryId id, const char* part_uri) {
  UNREACHABLE();
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
  return Dart_LookupLibrary(url);
}

}  // namespace bin
}  // namespace dart
