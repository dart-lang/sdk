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

  char* script_url;
  char* package_root;
  char* packages_file;

  const std::shared_ptr<uint8_t>& kernel_buffer() const {
    return kernel_buffer_;
  }

  intptr_t kernel_buffer_size() const { return kernel_buffer_size_; }

  // Associate the given kernel buffer with this IsolateData without giving it
  // ownership of the buffer.
  void SetKernelBufferUnowned(uint8_t* buffer, intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::shared_ptr<uint8_t>(buffer, FreeUnownedKernelBuffer);
    kernel_buffer_size_ = size;
  }

  // Associate the given kernel buffer with this IsolateData and give it
  // ownership of the buffer. This IsolateData is the first one to own the
  // buffer.
  void SetKernelBufferNewlyOwned(uint8_t* buffer, intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::shared_ptr<uint8_t>(buffer, free);
    kernel_buffer_size_ = size;
  }

  // Associate the given kernel buffer with this IsolateData and give it
  // ownership of the buffer. The buffer is already owned by another
  // IsolateData.
  void SetKernelBufferAlreadyOwned(std::shared_ptr<uint8_t> buffer,
                                   intptr_t size) {
    ASSERT(kernel_buffer_.get() == NULL);
    kernel_buffer_ = std::move(buffer);
    kernel_buffer_size_ = size;
  }

  void UpdatePackagesFile(const char* packages_file_) {
    if (packages_file != NULL) {
      free(packages_file);
      packages_file = NULL;
    }
    packages_file = strdup(packages_file_);
  }

  const char* resolved_packages_config() const {
    return resolved_packages_config_;
  }

  void set_resolved_packages_config(const char* packages_config) {
    if (resolved_packages_config_ != NULL) {
      free(resolved_packages_config_);
      resolved_packages_config_ = NULL;
    }
    resolved_packages_config_ = strdup(packages_config);
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
  Loader* loader_;
  AppSnapshot* app_snapshot_;
  MallocGrowableArray<char*>* dependencies_;
  char* resolved_packages_config_;
  std::shared_ptr<uint8_t> kernel_buffer_;
  intptr_t kernel_buffer_size_;

  static void FreeUnownedKernelBuffer(uint8_t*) {}

  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_ISOLATE_DATA_H_
