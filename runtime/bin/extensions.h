// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EXTENSIONS_H_
#define BIN_EXTENSIONS_H_

#include "include/dart_api.h"
#include "platform/globals.h"

class Extensions {
 public:
  // TODO(whesse): Make extension load from a relative path relative to
  // the library it is in.  Currently loads from current working directory.
  static Dart_Handle LoadExtension(const char* extension_url,
                                   Dart_Handle parent_library);

 private:
  // The returned string must be freed.
  static char* Concatenate(const char** strings);

  // Platform-specific implementations.
  static void* LoadExtensionLibrary(const char* library_path,
                                    const char* extension_name);
  static void* ResolveSymbol(void* lib_handle, const char* symbol);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Extensions);
};

#endif  // BIN_EXTENSIONS_H_
