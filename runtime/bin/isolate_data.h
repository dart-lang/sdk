// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ISOLATE_DATA_H_
#define RUNTIME_BIN_ISOLATE_DATA_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

// Forward declaration.
template <typename T>
class MallocGrowableArray;

}  // namespace dart

namespace dart {
namespace bin {

// Forward declaration.
class AppSnapshot;
class EventHandler;
class Loader;

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  IsolateData(const char* url,
              const char* package_root,
              const char* packages_file,
              AppSnapshot* app_snapshot);
  ~IsolateData();

  Dart_Handle builtin_lib() const {
    ASSERT(builtin_lib_ != NULL);
    ASSERT(!Dart_IsError(builtin_lib_));
    return builtin_lib_;
  }
  void set_builtin_lib(Dart_Handle lib) {
    ASSERT(builtin_lib_ == NULL);
    ASSERT(lib != NULL);
    ASSERT(!Dart_IsError(lib));
    builtin_lib_ = Dart_NewPersistentHandle(lib);
  }

  char* script_url;
  char* package_root;
  char* packages_file;
  void* kernel_program;

  void UpdatePackagesFile(const char* packages_file_) {
    if (packages_file != NULL) {
      free(packages_file);
      packages_file = NULL;
    }
    packages_file = strdup(packages_file_);
  }

  // While loading a loader is associated with the isolate.
  bool HasLoader() const { return loader_ != NULL; }
  Loader* loader() const {
    ASSERT(loader_ != NULL);
    return loader_;
  }
  void set_loader(Loader* loader) {
    ASSERT((loader_ == NULL) || (loader == NULL));
    loader_ = loader;
  }
  MallocGrowableArray<char*>* dependencies() const { return dependencies_; }
  void set_dependencies(MallocGrowableArray<char*>* deps) {
    dependencies_ = deps;
  }

  void OnIsolateShutdown();

 private:
  Dart_Handle builtin_lib_;
  Loader* loader_;
  AppSnapshot* app_snapshot_;
  MallocGrowableArray<char*>* dependencies_;

  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_ISOLATE_DATA_H_
