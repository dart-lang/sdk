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
  switch (id) {
    case kBuiltinLibrary:
      url = Dart_NewString(DartUtils::kBuiltinLibURL);
      break;
    case kIOLibrary:
      url = Dart_NewString(DartUtils::kIOLibURL);
      break;
    case kJsonLibrary:
      url = Dart_NewString(DartUtils::kJsonLibURL);
      break;
    case kUriLibrary:
      url = Dart_NewString(DartUtils::kUriLibURL);
      break;
    case kUtf8Library:
      url = Dart_NewString(DartUtils::kUtf8LibURL);
      break;
    default:
      url = Dart_Error("Unknown builtin library requested.");
      UNREACHABLE();
  }
  Dart_Handle imported_library = Dart_LookupLibrary(url);
  // Import the builtin library into current library.
  DART_CHECK_VALID(imported_library);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, imported_library));
}
