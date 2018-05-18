// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/isolate_data.h"
#include "bin/snapshot_utils.h"

namespace dart {
namespace bin {

IsolateData::IsolateData(const char* url,
                         const char* package_root,
                         const char* packages_file,
                         AppSnapshot* app_snapshot)
    : script_url((url != NULL) ? strdup(url) : NULL),
      package_root(NULL),
      packages_file(NULL),
      builtin_lib_(NULL),
      loader_(NULL),
      app_snapshot_(app_snapshot),
      dependencies_(NULL),
      resolved_packages_config_(NULL),
      kernel_buffer_(NULL),
      kernel_buffer_size_(0),
      owns_kernel_buffer_(false) {
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
  free(resolved_packages_config_);
  resolved_packages_config_ = NULL;
  if (owns_kernel_buffer_) {
    ASSERT(kernel_buffer_ != NULL);
    free(kernel_buffer_);
  }
  kernel_buffer_ = NULL;
  kernel_buffer_size_ = 0;
  delete app_snapshot_;
  app_snapshot_ = NULL;
}

}  // namespace bin
}  // namespace dart
