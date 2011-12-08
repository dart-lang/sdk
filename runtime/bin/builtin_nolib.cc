// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"


Dart_Handle Builtin::Source() {
  UNREACHABLE();
  return Dart_Null();
}


void Builtin::SetupLibrary(Dart_Handle builtin_lib) {
  UNREACHABLE();
}


void Builtin::ImportLibrary(Dart_Handle library) {
  Dart_Handle url = Dart_NewString(DartUtils::kBuiltinLibURL);
  Dart_Handle builtin_lib = Dart_LookupLibrary(url);
  // Import the builtin library into current library.
  DART_CHECK_VALID(builtin_lib);
  DART_CHECK_VALID(Dart_LibraryImportLibrary(library, builtin_lib));
}
