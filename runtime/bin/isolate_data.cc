// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/isolate_data.h"
#include "bin/snapshot_utils.h"

#include "vm/kernel.h"

namespace dart {
namespace bin {

IsolateData::IsolateData(const char* url,
                         const char* package_root,
                         const char* packages_file,
                         AppSnapshot* app_snapshot)
    : script_url((url != NULL) ? strdup(url) : NULL),
      package_root(NULL),
      packages_file(NULL),
      udp_receive_buffer(NULL),
      kernel_program(NULL),
      builtin_lib_(NULL),
      loader_(NULL),
      app_snapshot_(app_snapshot),
      dependencies_(NULL) {
  if (package_root != NULL) {
    ASSERT(packages_file == NULL);
    this->package_root = strdup(package_root);
  } else if (packages_file != NULL) {
    this->packages_file = strdup(packages_file);
  }
}


void IsolateData::OnIsolateShutdown() {
  if (builtin_lib_ != NULL) {
    Dart_DeletePersistentHandle(builtin_lib_);
    builtin_lib_ = NULL;
  }
}


IsolateData::~IsolateData() {
  free(script_url);
  script_url = NULL;
  free(package_root);
  package_root = NULL;
  free(packages_file);
  packages_file = NULL;
  free(udp_receive_buffer);
  udp_receive_buffer = NULL;
  if (kernel_program != NULL) {
    delete reinterpret_cast<kernel::Program*>(kernel_program);
    kernel_program = NULL;
  }
  delete app_snapshot_;
  app_snapshot_ = NULL;
}

}  // namespace bin
}  // namespace dart
