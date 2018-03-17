// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dfe.h"
#include "bin/dartutils.h"
#include "bin/directory.h"
#include "bin/error_exit.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "bin/utils.h"

#include "vm/kernel.h"

extern "C" {
#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
extern const uint8_t kKernelServiceDill[];
extern intptr_t kKernelServiceDillSize;
extern const uint8_t kPlatformDill[];
extern intptr_t kPlatformDillSize;
extern const uint8_t kPlatformStrongDill[];
extern intptr_t kPlatformStrongDillSize;
#else
const uint8_t* kKernelServiceDill = NULL;
intptr_t kKernelServiceDillSize = 0;
const uint8_t* kPlatformDill = NULL;
intptr_t kPlatformDillSize = 0;
const uint8_t* kPlatformStrongDill = NULL;
intptr_t kPlatformStrongDillSize = 0;
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
}

namespace dart {
namespace bin {

#if defined(DART_NO_SNAPSHOT) || defined(DART_PRECOMPILER)
const uint8_t* kernel_service_dill = NULL;
const intptr_t kernel_service_dill_size = 0;
const uint8_t* platform_dill = NULL;
const intptr_t platform_dill_size = 0;
const uint8_t* platform_strong_dill = NULL;
const intptr_t platform_strong_dill_size = 0;
#else
const uint8_t* kernel_service_dill = kKernelServiceDill;
const intptr_t kernel_service_dill_size = kKernelServiceDillSize;
const uint8_t* platform_dill = kPlatformDill;
const intptr_t platform_dill_size = kPlatformDillSize;
const uint8_t* platform_strong_dill = kPlatformStrongDill;
const intptr_t platform_strong_dill_size = kPlatformStrongDillSize;
#endif

const char kKernelServiceSnapshot[] = "kernel-service.dart.snapshot";
const char kSnapshotsDirectory[] = "snapshots";

static char* GetDirectoryPrefixFromExeName() {
  const char* name = Platform::GetExecutableName();
  const char* sep = File::PathSeparator();
  // Locate the last occurance of |sep| in |name|.
  intptr_t i;
  for (i = strlen(name) - 1; i >= 0; --i) {
    const char* str = name + i;
    if (strstr(str, sep) == str) {
      break;
    }
  }

  if (i < 0) {
    return strdup("");
  }

  return Utils::StrNDup(name, i + 1);
}

static void NoopRelease(uint8_t* buffer) {}

DFE::DFE()
    : use_dfe_(false),
      frontend_filename_(NULL),
      kernel_service_program_(NULL),
      platform_program_(NULL),
      platform_strong_program_(NULL),
      application_kernel_binary_(NULL) {}

DFE::~DFE() {
  if (frontend_filename_ != NULL) {
    free(frontend_filename_);
  }
  frontend_filename_ = NULL;

  // Do NOT delete kernel_service_program_ in the destructor.
  // It is always a full a dill file, hence it is used as
  // argument to Dart_CreateIsolateFromKernel as well as loaded
  // as the kernel program for the isolate. Hence, deleting here
  // would lead to double deletion.

  delete reinterpret_cast<kernel::Program*>(platform_program_);
  platform_program_ = NULL;

  delete reinterpret_cast<kernel::Program*>(platform_strong_program_);
  platform_strong_program_ = NULL;

  delete reinterpret_cast<kernel::Program*>(application_kernel_binary_);
  application_kernel_binary_ = NULL;
}

void DFE::Init() {
  if (platform_dill == NULL) {
    return;
  }
  // platform_dill is not NULL implies that platform_strong_dill is also
  // not NULL.
  if (platform_program_ == NULL) {
    platform_program_ =
        Dart_ReadKernelBinary(platform_dill, platform_dill_size, NoopRelease);
  }
  if (platform_strong_program_ == NULL) {
    platform_strong_program_ = Dart_ReadKernelBinary(
        platform_strong_dill, platform_strong_dill_size, NoopRelease);
  }

  if (frontend_filename_ == NULL) {
    // Look for the frontend snapshot next to the executable.
    char* dir_prefix = GetDirectoryPrefixFromExeName();
    // |dir_prefix| includes the last path seperator.
    frontend_filename_ =
        OS::SCreate(NULL, "%s%s", dir_prefix, kKernelServiceSnapshot);

    if (!File::Exists(NULL, frontend_filename_)) {
      // If the frontend snapshot is not found next to the executable,
      // then look for it in the "snapshots" directory.
      free(frontend_filename_);
      // |dir_prefix| includes the last path seperator.
      frontend_filename_ =
          OS::SCreate(NULL, "%s%s%s%s", dir_prefix, kSnapshotsDirectory,
                      File::PathSeparator(), kKernelServiceSnapshot);
    }

    free(dir_prefix);
    if (!File::Exists(NULL, frontend_filename_)) {
      free(frontend_filename_);
      frontend_filename_ = NULL;
    }
  }
}

bool DFE::KernelServiceDillAvailable() {
  return kernel_service_dill != NULL;
}

void* DFE::LoadKernelServiceProgram() {
  if (kernel_service_dill == NULL) {
    return NULL;
  }
  if (kernel_service_program_ == NULL) {
    kernel_service_program_ = Dart_ReadKernelBinary(
        kernel_service_dill, kernel_service_dill_size, NoopRelease);
  }
  return kernel_service_program_;
}

void* DFE::platform_program(bool strong) const {
  if (strong) {
    return platform_strong_program_;
  } else {
    return platform_program_;
  }
}

bool DFE::CanUseDartFrontend() const {
  return (platform_program() != NULL) &&
         (KernelServiceDillAvailable() || (frontend_filename() != NULL));
}

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
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
                                int* exit_code,
                                bool strong) {
  // TODO(aam): When Frontend is ready, VM should be passing vm_outline.dill
  // instead of vm_platform.dill to Frontend for compilation.
#if defined(HOST_OS_WINDOWS)
  WindowsPathSanitizer path_sanitizer(script_uri);
  const char* sanitized_uri = path_sanitizer.sanitized_uri();
#else
  const char* sanitized_uri = script_uri;
#endif

  const uint8_t* platform_binary =
      strong ? platform_strong_dill : platform_dill;
  intptr_t platform_binary_size =
      strong ? platform_strong_dill_size : platform_dill_size;
  Dart_KernelCompilationResult result = Dart_CompileToKernel(
      sanitized_uri, platform_binary, platform_binary_size);
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
                            intptr_t* kernel_ir_size) {
  *kernel_ir = NULL;
  *kernel_ir_size = -1;
  void* script_file = DartUtils::OpenFileUri(script_uri, false);
  if (script_file == NULL) {
    return false;
  }
  const uint8_t* buffer = NULL;
  DartUtils::ReadFile(&buffer, kernel_ir_size, script_file);
  DartUtils::CloseFile(script_file);
  if (*kernel_ir_size == 0 || buffer == NULL) {
    return false;
  }
  if (DartUtils::SniffForMagicNumber(buffer, *kernel_ir_size) !=
      DartUtils::kKernelMagicNumber) {
    free(const_cast<uint8_t*>(buffer));
    *kernel_ir = NULL;
    *kernel_ir_size = -1;
    return false;
  }
  // Do not free buffer if this is a kernel file - kernel_file will be
  // backed by the same memory as the buffer and caller will own it.
  // Caller is responsible for freeing the buffer when this function
  // returns true.
  *kernel_ir = buffer;
  return true;
}

}  // namespace bin
}  // namespace dart
