// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dfe.h"
#include "bin/dartutils.h"
#include "bin/error_exit.h"

#include "vm/kernel.h"

namespace dart {
namespace bin {

DFE::DFE()
    : frontend_filename_(NULL),
      platform_binary_filename_(NULL),
      kernel_platform_(NULL) {}


DFE::~DFE() {
  frontend_filename_ = NULL;
  platform_binary_filename_ = NULL;
  if (kernel_platform_ != NULL) {
    delete reinterpret_cast<kernel::Program*>(kernel_platform_);
  }
  kernel_platform_ = NULL;
}

Dart_Handle DFE::ReloadScript(Dart_Isolate isolate, const char* url_string) {
  ASSERT(!Dart_IsServiceIsolate(isolate) && !Dart_IsKernelIsolate(isolate));
  // First check if the URL points to a Kernel IR file in which case we
  // skip the compilation step and directly reload the file.
  const uint8_t* kernel_ir = NULL;
  intptr_t kernel_ir_size = -1;
  if (!TryReadKernelFile(url_string, &kernel_ir, &kernel_ir_size)) {
    // We have a source file, compile it into a kernel ir first.
    // TODO(asiva): We will have to change this API to pass in a list of files
    // that have changed. For now just pass in the main url_string and have it
    // recompile the script.
    Dart_KernelCompilationResult kresult = Dart_CompileToKernel(url_string);
    if (kresult.status != Dart_KernelCompilationStatus_Ok) {
      return Dart_NewApiError(kresult.error);
    }
    kernel_ir = kresult.kernel;
    kernel_ir_size = kresult.kernel_size;
  }
  void* kernel_program = Dart_ReadKernelBinary(kernel_ir, kernel_ir_size);
  ASSERT(kernel_program != NULL);
  Dart_Handle result = Dart_LoadKernel(kernel_program);
  if (Dart_IsError(result)) {
    return result;
  }
  // Finalize loading. This will complete any futures for completed deferred
  // loads.
  result = Dart_FinalizeLoading(true);
  if (Dart_IsError(result)) {
    return result;
  }
  return Dart_Null();
}


void* DFE::CompileAndReadScript(const char* script_uri,
                                char** error,
                                int* exit_code) {
  Dart_KernelCompilationResult result = Dart_CompileToKernel(script_uri);
  switch (result.status) {
    case Dart_KernelCompilationStatus_Ok:
      return Dart_ReadKernelBinary(result.kernel, result.kernel_size);
    case Dart_KernelCompilationStatus_Error:
      *error = result.error;  // Copy error message.
      *exit_code = kCompilationErrorExitCode;
      break;
    case Dart_KernelCompilationStatus_Crash:
      *error = result.error;  // Copy error message.
      *exit_code = kDartFrontendErrorExitCode;
      break;
    case Dart_KernelCompilationStatus_Unknown:
      *error = result.error;  // Copy error message.
      *exit_code = kErrorExitCode;
      break;
  }
  return NULL;
}


void* DFE::ReadPlatform() {
  const uint8_t* buffer = NULL;
  intptr_t buffer_length = -1;
  bool result =
      TryReadKernelFile(platform_binary_filename_, &buffer, &buffer_length);
  if (result) {
    kernel_platform_ = Dart_ReadKernelBinary(buffer, buffer_length);
    return kernel_platform_;
  }
  return NULL;
}


void* DFE::ReadScript(const char* script_uri) {
  const uint8_t* buffer = NULL;
  intptr_t buffer_length = -1;
  bool result = TryReadKernelFile(script_uri, &buffer, &buffer_length);
  if (result) {
    return Dart_ReadKernelBinary(buffer, buffer_length);
  }
  return NULL;
}


bool DFE::TryReadKernelFile(const char* script_uri,
                            const uint8_t** kernel_ir,
                            intptr_t* kernel_ir_size) {
  *kernel_ir = NULL;
  *kernel_ir_size = -1;
  void* script_file = DartUtils::OpenFile(script_uri, false);
  if (script_file != NULL) {
    const uint8_t* buffer = NULL;
    DartUtils::ReadFile(&buffer, kernel_ir_size, script_file);
    DartUtils::CloseFile(script_file);
    if (*kernel_ir_size > 0 && buffer != NULL) {
      // We need a temporary variable because SniffForMagicNumber modifies the
      // buffer pointer to skip snapshot magic number.
      const uint8_t* temp = buffer;
      if (DartUtils::SniffForMagicNumber(&temp, kernel_ir_size) !=
          DartUtils::kKernelMagicNumber) {
        free(const_cast<uint8_t*>(buffer));
        *kernel_ir = NULL;
        *kernel_ir_size = -1;
        return false;
      } else {
        // Do not free buffer if this is a kernel file - kernel_file will be
        // backed by the same memory as the buffer and caller will own it.
        // Caller is responsible for freeing the buffer when this function
        // returns true.
        *kernel_ir = buffer;
        return true;
      }
    }
  }
  return false;
}


}  // namespace bin
}  // namespace dart
