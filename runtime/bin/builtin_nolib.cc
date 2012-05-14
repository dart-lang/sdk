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
  Dart_Handle url;
  switch (id) {
    case kBuiltinLibrary:
      url = Dart_NewString(DartUtils::kBuiltinLibURL);
      break;
    case kCryptoLibrary:
      url = Dart_NewString(DartUtils::kCryptoLibURL);
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
    case kUtfLibrary:
      url = Dart_NewString(DartUtils::kUtfLibURL);
      break;
    default:
      return Dart_Error("Unknown builtin library requested.");
  }
  Dart_Handle library = Dart_LookupLibrary(url);
  if (Dart_IsError(library)) {
    UNREACHABLE();
  }
  DART_CHECK_VALID(library);
  return library;
}


void Builtin::ImportLibrary(Dart_Handle library, BuiltinLibraryId id) {
  Dart_Handle imported_library = LoadLibrary(id);
  // Import the library into current library.
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, imported_library));
}
