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

const char kPlatformBinaryName[] = "vm_platform.dill";
const char kPlatformStrongBinaryName[] = "vm_platform_strong.dill";
const char kVMServiceIOBinaryName[] = "vmservice_io.dill";

DFE::DFE()
    : frontend_filename_(NULL),
      kernel_binaries_path_(NULL),
      platform_binary_filename_(NULL),
      vmservice_io_binary_filename_(NULL),
      kernel_platform_(NULL),
      kernel_file_specified_(false) {}

DFE::~DFE() {
  frontend_filename_ = NULL;

  free(kernel_binaries_path_);
  kernel_binaries_path_ = NULL;

  free(platform_binary_filename_);
  platform_binary_filename_ = NULL;

  free(vmservice_io_binary_filename_);
  vmservice_io_binary_filename_ = NULL;

  if (kernel_platform_ != NULL) {
    delete reinterpret_cast<kernel::Program*>(kernel_platform_);
    kernel_platform_ = NULL;
  }
}

void DFE::SetKernelBinaries(const char* name) {
  kernel_binaries_path_ = strdup(name);
  vmservice_io_binary_filename_ =
      OS::SCreate(/*zone=*/NULL, "%s%s%s", name, File::PathSeparator(),
                  kVMServiceIOBinaryName);
}

const char* DFE::GetPlatformBinaryFilename() {
  if (platform_binary_filename_ == NULL) {
    platform_binary_filename_ = OS::SCreate(
        /*zone=*/NULL, "%s%s%s", kernel_binaries_path_, File::PathSeparator(),
        FLAG_strong ? kPlatformStrongBinaryName : kPlatformBinaryName);
  }
  return platform_binary_filename_;
}

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
}

Dart_Handle DFE::ReadKernelBinary(Dart_Isolate isolate,
                                  const char* url_string) {
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
    // TODO(aam): When Frontend is ready, VM should be passing vm_outline.dill
    // instead of vm_platform.dill to Frontend for compilation.
    Dart_KernelCompilationResult kresult =
        Dart_CompileToKernel(url_string, GetPlatformBinaryFilename());
    if (kresult.status != Dart_KernelCompilationStatus_Ok) {
      return Dart_NewApiError(kresult.error);
    }
    kernel_ir = kresult.kernel;
    kernel_ir_size = kresult.kernel_size;
  }
  void* kernel_program =
      Dart_ReadKernelBinary(kernel_ir, kernel_ir_size, ReleaseFetchedBytes);
  ASSERT(kernel_program != NULL);
  return Dart_NewExternalTypedData(Dart_TypedData_kUint64, kernel_program, 1);
}

void* DFE::CompileAndReadScript(const char* script_uri,
                                char** error,
                                int* exit_code) {
  // TODO(aam): When Frontend is ready, VM should be passing vm_outline.dill
  // instead of vm_platform.dill to Frontend for compilation.
  Dart_KernelCompilationResult result =
      Dart_CompileToKernel(script_uri, GetPlatformBinaryFilename());
  switch (result.status) {
    case Dart_KernelCompilationStatus_Ok:
      return Dart_ReadKernelBinary(result.kernel, result.kernel_size,
                                   ReleaseFetchedBytes);
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
  return ReadScript(GetPlatformBinaryFilename());
}

void* DFE::ReadVMServiceIO() const {
  return ReadScript(vmservice_io_binary_filename_);
}

void* DFE::ReadScript(const char* script_uri) const {
  const uint8_t* buffer = NULL;
  intptr_t buffer_length = -1;
  bool result = TryReadKernelFile(script_uri, &buffer, &buffer_length);
  if (result) {
    return Dart_ReadKernelBinary(buffer, buffer_length, ReleaseFetchedBytes);
  }
  return NULL;
}

bool DFE::TryReadKernelFile(const char* script_uri,
                            const uint8_t** kernel_ir,
                            intptr_t* kernel_ir_size) const {
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
