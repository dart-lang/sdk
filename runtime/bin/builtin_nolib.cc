// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"


Builtin::builtin_lib_props Builtin::builtin_libraries_[] = {
  /*      url_                 source_          has_natives_  */
  { DartUtils::kBuiltinLibURL, NULL,            true  },
  { DartUtils::kJsonLibURL,    NULL,            false },
  { DartUtils::kUriLibURL,     NULL,            false },
  { DartUtils::kCryptoLibURL,  NULL,            false },
  { DartUtils::kIOLibURL,      NULL,            true  },
  { DartUtils::kUtfLibURL,     NULL,            false },
  { DartUtils::kWebLibURL,     web_source_,     false }
};


Dart_Handle Builtin::Source(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id == kWebLibrary);
  return Dart_NewString(builtin_libraries_[id].source_);
}


void Builtin::SetupLibrary(Dart_Handle library, BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);
  if (builtin_libraries_[id].has_natives_) {
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(Dart_SetNativeResolver(library, NativeLookup));
  }
}


Dart_Handle Builtin::LoadLibrary(BuiltinLibraryId id) {
  ASSERT((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
         kInvalidLibrary);
  ASSERT(id >= kBuiltinLibrary && id < kInvalidLibrary);
  Dart_Handle url = Dart_NewString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  if (Dart_IsError(library)) {
    ASSERT(id >= kCryptoLibrary && id < kInvalidLibrary);
    library = Dart_LoadLibrary(url, Source(id));
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
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library,
                                             imported_library,
                                             Dart_Null()));
}
