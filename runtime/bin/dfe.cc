// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dfe.h"
#include "bin/dartutils.h"
#include "bin/error_exit.h"
#include "bin/file.h"

#include "vm/kernel.h"

namespace dart {
namespace bin {

const char kPlatformBinaryName[] = "platform.dill";
const char kVMServiceIOBinaryName[] = "vmservice_io.dill";

DFE::DFE()
    : frontend_filename_(NULL),
      platform_binary_filename_(NULL),
      vmservice_io_binary_filename_(NULL),
      kernel_platform_(NULL),
      kernel_vmservice_io_(NULL),
      kernel_file_specified_(false) {}

DFE::~DFE() {
  frontend_filename_ = NULL;

  if (platform_binary_filename_ != NULL) {
    delete platform_binary_filename_;
    platform_binary_filename_ = NULL;
  }

  if (kernel_platform_ != NULL) {
    delete reinterpret_cast<kernel::Program*>(kernel_platform_);
    kernel_platform_ = NULL;
  }

  if (kernel_vmservice_io_ != NULL) {
    delete reinterpret_cast<kernel::Program*>(kernel_vmservice_io_);
    kernel_vmservice_io_ = NULL;
  }
}

void DFE::clear_kernel_vmservice_io() {
  kernel_vmservice_io_ = NULL;
}

void DFE::SetKernelBinaries(const char* name) {
  intptr_t len = snprintf(NULL, 0, "%s%s%s", name, File::PathSeparator(),
                          kPlatformBinaryName) +
                 1;
  platform_binary_filename_ = new char[len];
  snprintf(platform_binary_filename_, len, "%s%s%s", name,
           File::PathSeparator(), kPlatformBinaryName);

  len = snprintf(NULL, 0, "%s%s%s", name, File::PathSeparator(),
                 kVMServiceIOBinaryName) +
        1;
  vmservice_io_binary_filename_ = new char[len];
  snprintf(vmservice_io_binary_filename_, len, "%s%s%s", name,
           File::PathSeparator(), kVMServiceIOBinaryName);
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
  return kernel_platform_ = ReadScript(platform_binary_filename_);
}

void* DFE::ReadVMServiceIO() {
  return kernel_vmservice_io_ = ReadScript(vmservice_io_binary_filename_);
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
      if (DartUtils::SniffForMagicNumber(buffer, *kernel_ir_size) !=
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
