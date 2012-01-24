// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  UNREACHABLE();
  return Dart_Null();
}


void Builtin::SetupLibrary(Dart_Handle library, BuiltinLibraryId id) {
  UNREACHABLE();
}


Dart_Handle Builtin::LoadLibrary(BuiltinLibraryId id) {
  UNREACHABLE();
  return Dart_Null();
}


void Builtin::ImportLibrary(Dart_Handle library, BuiltinLibraryId id) {
  Dart_Handle url;
  if (id == kBuiltinLibrary) {
    url = Dart_NewString(DartUtils::kBuiltinLibURL);
  } else {
    ASSERT(id == kIOLibrary);
    url = Dart_NewString(DartUtils::kIOLibURL);
  }
  Dart_Handle imported_library = Dart_LookupLibrary(url);
  // Import the builtin library into current library.
  DART_CHECK_VALID(imported_library);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, imported_library));
}
