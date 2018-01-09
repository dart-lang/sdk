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

DFE::DFE()
    : frontend_filename_(NULL),
      kernel_binaries_path_(NULL),
      platform_binary_filename_(NULL),
      kernel_platform_(NULL),
      application_kernel_binary_(NULL),
      kernel_file_specified_(false) {}

DFE::~DFE() {
  frontend_filename_ = NULL;

  free(kernel_binaries_path_);
  kernel_binaries_path_ = NULL;

  free(platform_binary_filename_);
  platform_binary_filename_ = NULL;

  delete reinterpret_cast<kernel::Program*>(kernel_platform_);
  kernel_platform_ = NULL;

  delete reinterpret_cast<kernel::Program*>(application_kernel_binary_);
  application_kernel_binary_ = NULL;
}

void DFE::SetKernelBinaries(const char* name) {
  kernel_binaries_path_ = strdup(name);
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

class WindowsPathSanitizer {
 public:
  explicit WindowsPathSanitizer(const char* path) {
    // For Windows we need to massage the paths a bit according to
    // http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx
    //
    // Convert
    // C:\one\two\three
    // to
    // /C:/one/two/three
    //
    // (see builtin.dart#_sanitizeWindowsPath)
    intptr_t len = strlen(path);
    sanitized_uri_ = reinterpret_cast<char*>(malloc(len + 1 + 1));
    if (sanitized_uri_ == NULL) {
      OUT_OF_MEMORY();
    }
    char* s = sanitized_uri_;
    if (len > 2 && path[1] == ':') {
      *s++ = '/';
    }
    for (const char *p = path; *p; ++p, ++s) {
      *s = *p == '\\' ? '/' : *p;
    }
    *s = '\0';
  }
  ~WindowsPathSanitizer() { free(sanitized_uri_); }

  const char* sanitized_uri() { return sanitized_uri_; }

 private:
  char* sanitized_uri_;

  DISALLOW_COPY_AND_ASSIGN(WindowsPathSanitizer);
};

void* DFE::CompileAndReadScript(const char* script_uri,
                                char** error,
                                int* exit_code) {
  // TODO(aam): When Frontend is ready, VM should be passing vm_outline.dill
  // instead of vm_platform.dill to Frontend for compilation.
#if defined(HOST_OS_WINDOWS)
  WindowsPathSanitizer path_sanitizer(script_uri);
  const char* sanitized_uri = path_sanitizer.sanitized_uri();
#else
  const char* sanitized_uri = script_uri;
#endif

  Dart_KernelCompilationResult result =
      Dart_CompileToKernel(sanitized_uri, GetPlatformBinaryFilename());
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
