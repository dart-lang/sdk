// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_BUILTIN_H_
#define BIN_BUILTIN_H_

#include <stdio.h>
#include <stdlib.h>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

#define FUNCTION_NAME(name) Builtin_##name
#define REGISTER_FUNCTION(name, count)                                         \
  { ""#name, FUNCTION_NAME(name), count },
#define DECLARE_FUNCTION(name, count)                                          \
  extern void FUNCTION_NAME(name)(Dart_NativeArguments args);


class Builtin {
 public:
  enum BuiltinLibraryId {
    kBuiltinLibrary,
    kCryptoLibrary,
    kIOLibrary,
    kJsonLibrary,
    kUriLibrary,
    kUtfLibrary,
  };

  static Dart_Handle Source(BuiltinLibraryId id);
  static void SetupLibrary(Dart_Handle library, BuiltinLibraryId id);
  static Dart_Handle LoadLibrary(BuiltinLibraryId id);
  static void ImportLibrary(Dart_Handle library, BuiltinLibraryId id);
  static void SetNativeResolver(BuiltinLibraryId id);
  static void PrintString(FILE* out, Dart_Handle object);

 private:
  static Dart_NativeFunction NativeLookup(Dart_Handle name,
                                          int argument_count);

  static const char builtin_source_[];
  static const char crypto_source_[];
  static const char io_source_[];
  static const char json_source_[];
  static const char uri_source_[];
  static const char utf_source_[];

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Builtin);
};


#endif  // BIN_BUILTIN_H_
