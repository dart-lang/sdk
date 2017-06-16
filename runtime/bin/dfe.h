// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DFE_H_
#define RUNTIME_BIN_DFE_H_

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class DFE {
 public:
  DFE();
  ~DFE();

  const char* frontend_filename() const { return frontend_filename_; }
  void set_frontend_filename(const char* name) { frontend_filename_ = name; }
  bool UseDartFrontend() const { return frontend_filename_ != NULL; }

  const char* platform_binary_filename() const {
    return platform_binary_filename_;
  }

  void SetKernelBinaries(const char* name);

  bool UsePlatformBinary() const { return platform_binary_filename_ != NULL; }

  void* kernel_platform() const { return kernel_platform_; }

  // Method to reload a script into a running a isolate.
  // If the specified script [url] is not a kernel IR, compile it first using
  // DFE and then reload the resulting kernel IR into the isolate.
  // Returns Dart_Null if successful, otherwise an error object is returned.
  Dart_Handle ReloadScript(Dart_Isolate isolate, const char* url_string);

  // Compiles a script and reads the resulting kernel file.
  // If the compilation is successful, returns a valid in memory kernel
  // representation of the script, NULL otherwise
  // 'error' and 'exit_code' have the error values in case of errors.
  void* CompileAndReadScript(const char* script_uri,
                             char** error,
                             int* exit_code);

  // Reads the platform kernel file.
  // Returns an in memory kernel representation of the platform kernel file.
  void* ReadPlatform();

  // Reads the script kernel file if specified 'script_uri' is a kernel file.
  // Returns an in memory kernel representation of the specified script is a
  // valid kernel file, false otherwise.
  void* ReadScript(const char* script_uri);

 private:
  // Tries to read [script_uri] as a Kernel IR file.
  // Returns `true` if successful and sets [kernel_file] and [kernel_length]
  // to be the kernel IR contents.
  // The caller is responsible for free()ing [kernel_file] if `true`
  // was returned.
  bool TryReadKernelFile(const char* script_uri,
                         const uint8_t** kernel_ir,
                         intptr_t* kernel_ir_size);

  const char* frontend_filename_;
  char* platform_binary_filename_;
  void* kernel_platform_;

  DISALLOW_COPY_AND_ASSIGN(DFE);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DFE_H_
