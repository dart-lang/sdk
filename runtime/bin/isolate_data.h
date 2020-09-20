// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ISOLATE_DATA_H_
#define RUNTIME_BIN_ISOLATE_DATA_H_

#include <memory>
#include <utility>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/utils.h"

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

// Data associated with every isolate group in the standalone VM
// embedding. This is used to free external resources for each isolate
// group when the isolate group shuts down.
class IsolateGroupData {
 public:
  IsolateGroupData(const char* url,
                   const char* packages_file,
                   AppSnapshot* app_snapshot,
                   bool isolate_run_app_snapshot);
  ~IsolateGroupData();

  char* script_url;

  const std::shared_ptr<uint8_t>& kernel_buffer() const {
    return kernel_buffer_;
  }

  intptr_t kernel_buffer_size() const { return kernel_buffer_size_; }

  // Associate the given kernel buffer with this IsolateGroupData without
  // giving it ownership of the buffer.
  void SetKernelBufferUnowned(uint8_t* buffer, intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::shared_ptr<uint8_t>(buffer, FreeUnownedKernelBuffer);
    kernel_buffer_size_ = size;
  }

  // Associate the given kernel buffer with this IsolateGroupData and give it
  // ownership of the buffer. This IsolateGroupData is the first one to own the
  // buffer.
  void SetKernelBufferNewlyOwned(uint8_t* buffer, intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::shared_ptr<uint8_t>(buffer, free);
    kernel_buffer_size_ = size;
  }

  // Associate the given kernel buffer with this IsolateGroupData and give it
  // ownership of the buffer. The buffer is already owned by another
  // IsolateGroupData.
  void SetKernelBufferAlreadyOwned(std::shared_ptr<uint8_t> buffer,
                                   intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::move(buffer);
    kernel_buffer_size_ = size;
  }

  const char* resolved_packages_config() const {
    return resolved_packages_config_;
  }

  void set_resolved_packages_config(const char* packages_config) {
    if (resolved_packages_config_ != NULL) {
      free(resolved_packages_config_);
      resolved_packages_config_ = NULL;
    }
    resolved_packages_config_ = Utils::StrDup(packages_config);
  }

  bool RunFromAppSnapshot() const {
    // If the main isolate is using an app snapshot the [app_snapshot_] pointer
    // will be still nullptr (see main.cc:CreateIsolateGroupAndSetupHelper)
    //
    // Because of thus we have an additional boolean signaling whether the
    // isolate was started from an app snapshot.
    return app_snapshot_ != nullptr || isolate_run_app_snapshot_;
  }

  void AddLoadingUnit(AppSnapshot* loading_unit) {
    loading_units_.Add(loading_unit);
  }

 private:
  friend class IsolateData;  // For packages_file_

  std::unique_ptr<AppSnapshot> app_snapshot_;
  MallocGrowableArray<AppSnapshot*> loading_units_;
  char* resolved_packages_config_;
  std::shared_ptr<uint8_t> kernel_buffer_;
  intptr_t kernel_buffer_size_;
  char* packages_file_ = nullptr;
  bool isolate_run_app_snapshot_;

  static void FreeUnownedKernelBuffer(uint8_t*) {}

  DISALLOW_COPY_AND_ASSIGN(IsolateGroupData);
};

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  explicit IsolateData(IsolateGroupData* isolate_group_data);
  ~IsolateData();

  IsolateGroupData* isolate_group_data() const { return isolate_group_data_; }

  void UpdatePackagesFile(const char* packages_file) {
    if (packages_file != nullptr) {
      free(packages_file_);
      packages_file_ = nullptr;
    }
    packages_file_ = Utils::StrDup(packages_file);
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

  const char* packages_file() const { return packages_file_; }

 private:
  IsolateGroupData* isolate_group_data_;
  Loader* loader_;
  char* packages_file_;

  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_ISOLATE_DATA_H_
