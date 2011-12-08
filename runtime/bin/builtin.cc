// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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


Dart_Handle Builtin::Source() {
  Dart_Handle source = Dart_NewString(Builtin::Builtin_source_);
  return source;
}


void Builtin::SetupLibrary(Dart_Handle builtin_lib) {
  // Setup core lib, builtin import structure.
  SetupCorelibImports(builtin_lib);
  // Setup the native resolver for built in library functions.
  DART_CHECK_VALID(Dart_SetNativeResolver(builtin_lib, NativeLookup));
}


void Builtin::ImportLibrary(Dart_Handle library) {
  Dart_Handle url = Dart_NewString(DartUtils::kBuiltinLibURL);
  Dart_Handle builtin_lib = Dart_LookupLibrary(url);
  if (Dart_IsError(builtin_lib)) {
    builtin_lib = Dart_LoadLibrary(url, Source());
    if (!Dart_IsError(builtin_lib)) {
      SetupLibrary(builtin_lib);
    }
  }
  // Import the builtin library into current library.
  DART_CHECK_VALID(builtin_lib);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, builtin_lib));
}
