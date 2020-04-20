// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_BUILTIN_H_
#define RUNTIME_BIN_BUILTIN_H_

#include <stdio.h>
#include <stdlib.h>

#include "include/dart_api.h"

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

#define FUNCTION_NAME(name) Builtin_##name
#define REGISTER_FUNCTION(name, count) {"" #name, FUNCTION_NAME(name), count},
#define DECLARE_FUNCTION(name, count)                                          \
  extern void FUNCTION_NAME(name)(Dart_NativeArguments args);

class Builtin {
 public:
  // Note: Changes to this enum should be accompanied with changes to
  // the builtin_libraries_ array in builtin.cc and builtin_nolib.cc.
  enum BuiltinLibraryId {
    kInvalidLibrary = -1,
    kBuiltinLibrary = 0,
    kIOLibrary,
    kHttpLibrary,
    kCLILibrary,
  };

  // Setup native resolver method built in library specified in 'id'.
  static void SetNativeResolver(BuiltinLibraryId id);

  // Check if built in library specified in 'id' is already loaded, if not
  // load it.
  static Dart_Handle LoadAndCheckLibrary(BuiltinLibraryId id);

 private:
  // Native method support.
  static Dart_NativeFunction NativeLookup(Dart_Handle name,
                                          int argument_count,
                                          bool* auto_setup_scope);

  static const uint8_t* NativeSymbol(Dart_NativeFunction nf);

  static const int num_libs_;

  typedef struct {
    const char* url_;
    bool has_natives_;
  } builtin_lib_props;
  static builtin_lib_props builtin_libraries_[];

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Builtin);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_BUILTIN_H_
