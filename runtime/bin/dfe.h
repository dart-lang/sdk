// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DFE_H_
#define RUNTIME_BIN_DFE_H_

#include <memory>

#include "bin/thread.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/hashmap.h"
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

  void set_verbosity(Dart_KernelCompilationVerbosityLevel verbosity) {
    verbosity_ = verbosity;
  }
  Dart_KernelCompilationVerbosityLevel verbosity() const { return verbosity_; }

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
  //
  // `snapshot` is used by the frontend to determine if compilation
  // related information should be printed to console (e.g., null safety mode).
  Dart_KernelCompilationResult CompileScript(const char* script_uri,
                                             bool incremental,
                                             const char* package_config,
                                             bool for_snapshot,
                                             bool embedd_sources);

  // Compiles specified script and reads the resulting kernel file.
  // If the compilation is successful, returns a valid in memory kernel
  // representation of the script, nullptr otherwise
  // 'error' and 'exit_code' have the error values in case of errors.
  //
  // `snapshot` is used by the frontend to determine if compilation
  // related information should be printed to console (e.g., null safety mode).
  void CompileAndReadScript(const char* script_uri,
                            uint8_t** kernel_buffer,
                            intptr_t* kernel_buffer_size,
                            char** error,
                            int* exit_code,
                            const char* package_config,
                            bool for_snapshot,
                            bool embed_sources);

  // Reads the script kernel file if specified 'script_uri' is a kernel file.
  // Returns an in memory kernel representation of the specified script is a
  // valid kernel file, sets 'kernel_buffer' to nullptr otherwise.
  //
  // If 'kernel_blob_ptr' is not nullptr, then this function can also
  // read kernel blobs. In such case it sets 'kernel_blob_ptr'
  // to a shared pointer which owns the kernel buffer.
  // Otherwise, the caller is responsible for free()ing 'kernel_buffer'.
  void ReadScript(const char* script_uri,
                  uint8_t** kernel_buffer,
                  intptr_t* kernel_buffer_size,
                  bool decode_uri = true,
                  std::shared_ptr<uint8_t>* kernel_blob_ptr = nullptr);

  bool KernelServiceDillAvailable() const;

  // Tries to read 'script_uri' as a Kernel IR file.
  // Returns `true` if successful and sets 'kernel_buffer' and 'kernel_length'
  // to be the kernel IR contents.
  //
  // If 'kernel_blob_ptr' is not nullptr, then this function can also
  // read kernel blobs. In such case it sets 'kernel_blob_ptr'
  // to a shared pointer which owns the kernel buffer.
  // Otherwise, the caller is responsible for free()ing 'kernel_buffer'
  // if `true` was returned.
  bool TryReadKernelFile(const char* script_uri,
                         uint8_t** kernel_buffer,
                         intptr_t* kernel_buffer_size,
                         bool decode_uri = true,
                         std::shared_ptr<uint8_t>* kernel_blob_ptr = nullptr);

  // We distinguish between "intent to use Dart frontend" vs "can actually
  // use Dart frontend". The method UseDartFrontend tells us about the
  // intent to use DFE. This method tells us if Dart frontend can actually
  // be used.
  bool CanUseDartFrontend() const;

  void LoadPlatform(const uint8_t** kernel_buffer,
                    intptr_t* kernel_buffer_size);
  void LoadKernelService(const uint8_t** kernel_service_buffer,
                         intptr_t* kernel_service_buffer_size);

  // Registers given kernel blob and returns blob URI which
  // can be used in TryReadKernelFile later to load the given kernel.
  // Data from [kernel_buffer] is copied, it doesn't need to stay alive.
  // Returns nullptr if failed to allocate memory.
  const char* RegisterKernelBlob(const uint8_t* kernel_buffer,
                                 intptr_t kernel_buffer_size);

  // Looks for kernel blob using the given [uri].
  // Returns non-null pointer to the kernel blob if successful and
  // sets [kernel_length].
  std::shared_ptr<uint8_t> TryFindKernelBlob(const char* uri,
                                             intptr_t* kernel_length);

  // Unregisters kernel blob with given URI.
  void UnregisterKernelBlob(const char* uri);

 private:
  bool use_dfe_;
  bool use_incremental_compiler_;
  char* frontend_filename_;
  Dart_KernelCompilationVerbosityLevel verbosity_ =
      Dart_KernelCompilationVerbosityLevel_All;

  // Kernel binary specified on the cmd line.
  uint8_t* application_kernel_buffer_;
  intptr_t application_kernel_buffer_size_;

  // Registry of kernel blobs. Maps URI (char *) to KernelBlob.
  SimpleHashMap kernel_blobs_;
  intptr_t kernel_blob_counter_ = 0;
  Mutex kernel_blobs_lock_;

  void InitKernelServiceAndPlatformDills();

  DISALLOW_COPY_AND_ASSIGN(DFE);
};

class KernelBlob {
 public:
  // Takes ownership over [uri] and [buffer].
  KernelBlob(char* uri, uint8_t* buffer, intptr_t size)
      : uri_(uri, std::free), buffer_(buffer, std::free), size_(size) {}

  std::shared_ptr<uint8_t> buffer() { return buffer_; }
  intptr_t size() const { return size_; }

 private:
  Utils::CStringUniquePtr uri_;
  std::shared_ptr<uint8_t> buffer_;
  const intptr_t size_;

  DISALLOW_COPY_AND_ASSIGN(KernelBlob);
};

class PathSanitizer {
 public:
  explicit PathSanitizer(const char* path);
  const char* sanitized_uri() const;

 private:
#if defined(DART_HOST_OS_WINDOWS)
  std::unique_ptr<char[]> sanitized_uri_;
#else
  const char* sanitized_uri_;
#endif  // defined(DART_HOST_OS_WINDOWS)

  DISALLOW_COPY_AND_ASSIGN(PathSanitizer);
};

#if !defined(DART_PRECOMPILED_RUNTIME)
extern DFE dfe;
#endif

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DFE_H_
