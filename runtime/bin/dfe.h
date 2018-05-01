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

  // Call Init before Dart_Initialize to prevent races between the
  // different isolates.
  void Init();

  char* frontend_filename() const { return frontend_filename_; }

  void set_frontend_filename(const char* name) {
    if (frontend_filename_ != NULL) {
      free(frontend_filename_);
    }
    frontend_filename_ = strdup(name);
    set_use_dfe();
  }
  void set_use_dfe(bool value = true) { use_dfe_ = value; }
  bool UseDartFrontend() const { return use_dfe_; }

  // Returns the platform binary file name if the path to
  // kernel binaries was set using SetKernelBinaries.
  const char* GetPlatformBinaryFilename();

  // Set the kernel program for the main application if it was specified
  // as a dill file.
  void set_application_kernel_binary(void* application_kernel_binary) {
    application_kernel_binary_ = application_kernel_binary;
  }
  void* application_kernel_binary() const { return application_kernel_binary_; }

  // Compiles a script and reads the resulting kernel file.
  // If the compilation is successful, returns a valid in memory kernel
  // representation of the script, NULL otherwise
  // 'error' and 'exit_code' have the error values in case of errors.
  void* CompileAndReadScript(const char* script_uri,
                             char** error,
                             int* exit_code,
                             bool strong,
                             const char* package_config);

  // Reads the script kernel file if specified 'script_uri' is a kernel file.
  // Returns an in memory kernel representation of the specified script is a
  // valid kernel file, false otherwise.
  void* ReadScript(const char* script_uri) const;

  static bool KernelServiceDillAvailable();

  // Tries to read [script_uri] as a Kernel IR file.
  // Returns `true` if successful and sets [kernel_file] and [kernel_length]
  // to be the kernel IR contents.
  // The caller is responsible for free()ing [kernel_file] if `true`
  // was returned.
  static bool TryReadKernelFile(const char* script_uri,
                                const uint8_t** kernel_ir,
                                intptr_t* kernel_ir_size);

  // We distinguish between "intent to use Dart frontend" vs "can actually
  // use Dart frontend". The method UseDartFrontend tells us about the
  // intent to use DFE. This method tells us if Dart frontend can actually
  // be used.
  bool CanUseDartFrontend() const;

  void* platform_program(bool strong = false) const;

  void* LoadKernelServiceProgram();

 private:
  bool use_dfe_;
  char* frontend_filename_;

  void* kernel_service_program_;
  void* platform_program_;
  void* platform_strong_program_;

  // Kernel binary specified on the cmd line.
  void* application_kernel_binary_;

  DISALLOW_COPY_AND_ASSIGN(DFE);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DFE_H_
