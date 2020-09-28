// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_LOADER_H_
#define RUNTIME_BIN_LOADER_H_

#include "bin/isolate_data.h"
#include "bin/thread.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class Loader {
 public:
  static Dart_Handle InitForSnapshot(const char* snapshot_uri,
                                     IsolateData* isolate_data);

  static Dart_Handle ReloadNativeExtensions();

  // A static tag handler that hides all usage of a loader for an isolate.
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                       Dart_Handle library,
                                       Dart_Handle url);
  static Dart_Handle DeferredLoadHandler(intptr_t loading_unit_id);

  static void InitOnce();

 private:
  static Dart_Handle Init(const char* packages_file,
                          const char* working_directory,
                          const char* root_script_uri);

  static Dart_Handle LoadImportExtension(const char* url_string,
                                         Dart_Handle library);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Loader);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_LOADER_H_
