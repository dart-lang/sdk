// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_ISOLATE_DATA_H_
#define BIN_ISOLATE_DATA_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

// Forward declaration.
class EventHandler;
class Loader;

typedef void (*ExitHook)(int64_t exit_code);

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  IsolateData(const char* url,
              const char* package_root,
              const char* packages_file)
      : script_url((url != NULL) ? strdup(url) : NULL),
        package_root(NULL),
        packages_file(NULL),
        udp_receive_buffer(NULL),
        builtin_lib_(NULL),
        loader_(NULL),
        exit_hook_(NULL) {
    if (package_root != NULL) {
      ASSERT(packages_file == NULL);
      this->package_root = strdup(package_root);
    } else if (packages_file != NULL) {
      this->packages_file = strdup(packages_file);
    }
  }

  ~IsolateData() {
    free(script_url);
    script_url = NULL;
    free(package_root);
    package_root = NULL;
    free(packages_file);
    packages_file = NULL;
    free(udp_receive_buffer);
    udp_receive_buffer = NULL;
    if (builtin_lib_ != NULL) {
      Dart_DeletePersistentHandle(builtin_lib_);
    }
  }

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

  ExitHook exit_hook() const { return exit_hook_; }
  void set_exit_hook(ExitHook hook) { exit_hook_ = hook; }

  char* script_url;
  char* package_root;
  char* packages_file;
  uint8_t* udp_receive_buffer;

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

 private:
  Dart_Handle builtin_lib_;
  Loader* loader_;
  ExitHook exit_hook_;

  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_ISOLATE_DATA_H_
