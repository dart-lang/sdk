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
  };

  // Get source corresponding to built in library specified in 'id'.
  static Dart_Handle Source(BuiltinLibraryId id);

  // Get source of part file specified in 'uri'.
  static Dart_Handle PartSource(BuiltinLibraryId id, const char* part_uri);

  // Setup native resolver method built in library specified in 'id'.
  static void SetNativeResolver(BuiltinLibraryId id);

  static Dart_Handle LoadLibrary(Dart_Handle url, BuiltinLibraryId id);
  static BuiltinLibraryId FindId(const char* url_string);

  // Check if built in library specified in 'id' is already loaded, if not
  // load it.
  static Dart_Handle LoadAndCheckLibrary(BuiltinLibraryId id);

  static Dart_Handle SetLoadPort(Dart_Port port);

  static Dart_Port LoadPort() {
    ASSERT(load_port_ != ILLEGAL_PORT);
    return load_port_;
  }

 private:
  // Map specified URI to an actual file name from 'source_paths' and read
  // the file.
  static Dart_Handle GetSource(const char** source_paths, const char* uri);

  // Native method support.
  static Dart_NativeFunction NativeLookup(Dart_Handle name,
                                          int argument_count,
                                          bool* auto_setup_scope);

  static const uint8_t* NativeSymbol(Dart_NativeFunction nf);

  static const char* _builtin_source_paths_[];
  static const char* _http_source_paths_[];
  static const char* io_source_paths_[];
  static const char* io_patch_paths_[];
  static const char* html_source_paths_[];
  static const char* html_common_source_paths_[];
  static const char* js_source_paths_[];
  static const char* js_util_source_paths_[];
  static const char* indexed_db_source_paths_[];
  static const char* web_gl_source_paths_[];
  static const char* metadata_source_paths_[];
  static const char* web_sql_source_paths_[];
  static const char* svg_source_paths_[];
  static const char* web_audio_source_paths_[];

  static Dart_Port load_port_;
  static const int num_libs_;

  typedef struct {
    const char* url_;
    const char** source_paths_;
    const char* patch_url_;
    const char** patch_paths_;
    bool has_natives_;
  } builtin_lib_props;
  static builtin_lib_props builtin_libraries_[];

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Builtin);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_BUILTIN_H_
