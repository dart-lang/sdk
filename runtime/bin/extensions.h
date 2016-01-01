// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EXTENSIONS_H_
#define BIN_EXTENSIONS_H_

#include "include/dart_api.h"
#include "platform/globals.h"


namespace dart {
namespace bin {

class Extensions {
 public:
  // TODO(whesse): Make extension load from a relative path relative to
  // the library it is in.  Currently loads from current working directory.
  static Dart_Handle LoadExtension(const char* extension_directory,
                                   const char* extension_filename,
                                   const char* extension_name,
                                   Dart_Handle parent_library);

  // Platform-specific implementations.
  static void* LoadExtensionLibrary(const char* library_file);
  static void* ResolveSymbol(void* lib_handle, const char* symbol);

 private:
  static Dart_Handle GetError();

  // The returned string must be freed.
  static char* Concatenate(const char** strings);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Extensions);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EXTENSIONS_H_
