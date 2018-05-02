// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SNAPSHOT_UTILS_H_
#define RUNTIME_BIN_SNAPSHOT_UTILS_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

class AppSnapshot {
 public:
  virtual ~AppSnapshot() {}

  virtual void SetBuffers(const uint8_t** vm_data_buffer,
                          const uint8_t** vm_instructions_buffer,
                          const uint8_t** isolate_data_buffer,
                          const uint8_t** isolate_instructions_buffer) = 0;

 protected:
  AppSnapshot() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(AppSnapshot);
};

class Snapshot {
 public:
  static void GenerateKernel(const char* snapshot_filename,
                             const char* script_name,
                             bool strong,
                             const char* package_config);
  static void GenerateScript(const char* snapshot_filename);
  static void GenerateAppJIT(const char* snapshot_filename);
  static void GenerateAppAOTAsBlobs(const char* snapshot_filename,
                                    const uint8_t* shared_data,
                                    const uint8_t* shared_instructions);
  static void GenerateAppAOTAsAssembly(const char* snapshot_filename);

  static AppSnapshot* TryReadAppSnapshot(const char* script_name);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Snapshot);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SNAPSHOT_UTILS_H_
