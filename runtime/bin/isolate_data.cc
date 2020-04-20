// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/isolate_data.h"
#include "bin/snapshot_utils.h"
#include "platform/growable_array.h"

namespace dart {
namespace bin {

IsolateGroupData::IsolateGroupData(const char* url,
                                   const char* package_root,
                                   const char* packages_file,
                                   AppSnapshot* app_snapshot,
                                   bool isolate_run_app_snapshot)
    : script_url((url != NULL) ? strdup(url) : NULL),
      package_root(NULL),
      app_snapshot_(app_snapshot),
      resolved_packages_config_(NULL),
      kernel_buffer_(NULL),
      kernel_buffer_size_(0),
      isolate_run_app_snapshot_(isolate_run_app_snapshot) {
  if (package_root != NULL) {
    ASSERT(packages_file == NULL);
    package_root = strdup(package_root);
  } else if (packages_file != NULL) {
    packages_file_ = strdup(packages_file);
  }
}

IsolateGroupData::~IsolateGroupData() {
  free(script_url);
  script_url = NULL;
  free(package_root);
  package_root = NULL;
  free(packages_file_);
  packages_file_ = NULL;
  free(resolved_packages_config_);
  resolved_packages_config_ = NULL;
  kernel_buffer_ = NULL;
  kernel_buffer_size_ = 0;
}

IsolateData::IsolateData(IsolateGroupData* isolate_group_data)
    : isolate_group_data_(isolate_group_data),
      loader_(nullptr),
      packages_file_(nullptr) {
  if (isolate_group_data->packages_file_ != nullptr) {
    packages_file_ = strdup(isolate_group_data->packages_file_);
  }
}

IsolateData::~IsolateData() {
  free(packages_file_);
  packages_file_ = nullptr;
}

}  // namespace bin
}  // namespace dart
