// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

static void SetupCorelibImports(Dart_Handle builtin_lib) {
  // Lookup the core libraries and import the builtin library into them.
  Dart_Handle url = Dart_NewString(DartUtils::kCoreLibURL);
  Dart_Handle core_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(core_lib);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(core_lib, builtin_lib));

  url = Dart_NewString(DartUtils::kCoreImplLibURL);
  Dart_Handle coreimpl_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(coreimpl_lib);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(coreimpl_lib, builtin_lib));
}


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  Dart_Handle source;
  switch (id) {
    case kBuiltinLibrary:
      source = Dart_NewString(Builtin::builtin_source_);
      break;
    case kIOLibrary:
      source = Dart_NewString(Builtin::io_source_);
      break;
    case kJsonLibrary:
      source = Dart_NewString(Builtin::json_source_);
      break;
    case kUriLibrary:
      source = Dart_NewString(Builtin::uri_source_);
      break;
    case kUtf8Library:
      source = Dart_NewString(Builtin::utf8_source_);
      break;
    default:
      return Dart_Error("Unknown builtin source requested.");
  }
  return source;
}


void Builtin::SetupLibrary(Dart_Handle library, BuiltinLibraryId id) {
  if ((id == kJsonLibrary) || (id == kUriLibrary) || (id == kUtf8Library)) {
    // No native resolver for these pure Dart libraries.
    return;
  } else if (id == kBuiltinLibrary) {
    // Setup core lib, builtin import structure.
    SetupCorelibImports(library);
  }
  // Setup the native resolver for built in library functions.
  DART_CHECK_VALID(Dart_SetNativeResolver(library, NativeLookup));
}


Dart_Handle Builtin::LoadLibrary(BuiltinLibraryId id) {
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
      return Dart_Error("Unknown builtin library requested.");
  }
  Dart_Handle library = Dart_LookupLibrary(url);
  if (Dart_IsError(library)) {
    Dart_Handle import_map = Dart_NewList(0);
    library = Dart_LoadLibrary(url, Source(id), import_map);
    if (!Dart_IsError(library)) {
      SetupLibrary(library, id);
    }
  }
  DART_CHECK_VALID(library);
  return library;
}


void Builtin::ImportLibrary(Dart_Handle library, BuiltinLibraryId id) {
  Dart_Handle imported_library = LoadLibrary(id);
  // Import the library into current library.
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, imported_library));
}
