// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DFE_H_
#define RUNTIME_BIN_DFE_H_

#include <memory>

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

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
    if (frontend_filename_ != nullptr) {
      free(frontend_filename_);
    }
    frontend_filename_ = Utils::StrDup(name);
    set_use_dfe();
  }
  void set_use_dfe(bool value = true) { use_dfe_ = value; }
  bool UseDartFrontend() const { return use_dfe_; }

  void set_use_incremental_compiler(bool value) {
    use_incremental_compiler_ = value;
  }
  bool use_incremental_compiler() const { return use_incremental_compiler_; }

  // Returns the platform binary file name if the path to
  // kernel binaries was set using SetKernelBinaries.
  const char* GetPlatformBinaryFilename();

  // Set the kernel program for the main application if it was specified
  // as a dill file.
  void set_application_kernel_buffer(uint8_t* buffer, intptr_t size) {
    application_kernel_buffer_ = buffer;
    application_kernel_buffer_size_ = size;
  }
  void application_kernel_buffer(const uint8_t** buffer, intptr_t* size) const {
    *buffer = application_kernel_buffer_;
    *size = application_kernel_buffer_size_;
  }

  // Compiles specified script.
  // Returns result from compiling the script.
  Dart_KernelCompilationResult CompileScript(const char* script_uri,
                                             bool incremental,
                                             const char* package_config);

  // Compiles specified script and reads the resulting kernel file.
  // If the compilation is successful, returns a valid in memory kernel
  // representation of the script, NULL otherwise
  // 'error' and 'exit_code' have the error values in case of errors.
  void CompileAndReadScript(const char* script_uri,
                            uint8_t** kernel_buffer,
                            intptr_t* kernel_buffer_size,
                            char** error,
                            int* exit_code,
                            const char* package_config);

  // Reads the script kernel file if specified 'script_uri' is a kernel file.
  // Returns an in memory kernel representation of the specified script is a
  // valid kernel file, false otherwise.
  void ReadScript(const char* script_uri,
                  uint8_t** kernel_buffer,
                  intptr_t* kernel_buffer_size) const;

  bool KernelServiceDillAvailable() const;

  // Tries to read [script_uri] as a Kernel IR file.
  // Returns `true` if successful and sets [kernel_file] and [kernel_length]
  // to be the kernel IR contents.
  // The caller is responsible for free()ing [kernel_file] if `true`
  // was returned.
  static bool TryReadKernelFile(const char* script_uri,
                                uint8_t** kernel_buffer,
                                intptr_t* kernel_buffer_size);

  // We distinguish between "intent to use Dart frontend" vs "can actually
  // use Dart frontend". The method UseDartFrontend tells us about the
  // intent to use DFE. This method tells us if Dart frontend can actually
  // be used.
  bool CanUseDartFrontend() const;

  void LoadPlatform(const uint8_t** kernel_buffer,
                    intptr_t* kernel_buffer_size);
  void LoadKernelService(const uint8_t** kernel_service_buffer,
                         intptr_t* kernel_service_buffer_size);

 private:
  bool use_dfe_;
  bool use_incremental_compiler_;
  char* frontend_filename_;

  // Kernel binary specified on the cmd line.
  uint8_t* application_kernel_buffer_;
  intptr_t application_kernel_buffer_size_;

  void InitKernelServiceAndPlatformDills();

  DISALLOW_COPY_AND_ASSIGN(DFE);
};

class PathSanitizer {
 public:
  explicit PathSanitizer(const char* path);
  const char* sanitized_uri() const;

 private:
#if defined(HOST_OS_WINDOWS)
  std::unique_ptr<char[]> sanitized_uri_;
#else
  const char* sanitized_uri_;
#endif  // defined(HOST_OS_WINDOWS)

  DISALLOW_COPY_AND_ASSIGN(PathSanitizer);
};

#if !defined(DART_PRECOMPILED_RUNTIME)
extern DFE dfe;
#endif

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DFE_H_
