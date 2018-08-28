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
#include "include/dart_tools_api.h"
#include "platform/utils.h"
#include "vm/os.h"

extern "C" {
#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
extern const uint8_t kKernelServiceDill[];
extern intptr_t kKernelServiceDillSize;
extern const uint8_t kPlatformStrongDill[];
extern intptr_t kPlatformStrongDillSize;
#else
const uint8_t* kKernelServiceDill = NULL;
intptr_t kKernelServiceDillSize = 0;
const uint8_t* kPlatformStrongDill = NULL;
intptr_t kPlatformStrongDillSize = 0;
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
}

namespace dart {
namespace bin {

#if !defined(DART_PRECOMPILED_RUNTIME)
DFE dfe;
#endif

#if defined(DART_NO_SNAPSHOT) || defined(DART_PRECOMPILER)
const uint8_t* kernel_service_dill = NULL;
const intptr_t kernel_service_dill_size = 0;
const uint8_t* platform_strong_dill = NULL;
const intptr_t platform_strong_dill_size = 0;
#else
const uint8_t* kernel_service_dill = kKernelServiceDill;
const intptr_t kernel_service_dill_size = kKernelServiceDillSize;
const uint8_t* platform_strong_dill = kPlatformStrongDill;
const intptr_t platform_strong_dill_size = kPlatformStrongDillSize;
#endif

const char kKernelServiceSnapshot[] = "kernel-service.dart.snapshot";
const char kSnapshotsDirectory[] = "snapshots";

static char* GetDirectoryPrefixFromExeName() {
  const char* name = Platform::GetExecutableName();
  const char* sep = File::PathSeparator();
  const intptr_t sep_length = strlen(sep);

  for (intptr_t i = strlen(name) - 1; i >= 0; --i) {
    const char* str = name + i;
    if (strncmp(str, sep, sep_length) == 0
#if defined(HOST_OS_WINDOWS)
        // TODO(aam): GetExecutableName doesn't work reliably on Windows,
        // the code below is a workaround for that (we would be using
        // just single Platform::Separator instead of both slashes if it did).
        || *str == '/'
#endif
    ) {
      return Utils::StrNDup(name, i + 1);
    }
  }
  return strdup("");
}

DFE::DFE()
    : use_dfe_(false),
      use_incremental_compiler_(false),
      frontend_filename_(NULL),
      application_kernel_buffer_(NULL),
      application_kernel_buffer_size_(0) {}

DFE::~DFE() {
  if (frontend_filename_ != NULL) {
    free(frontend_filename_);
  }
  frontend_filename_ = NULL;

  free(application_kernel_buffer_);
  application_kernel_buffer_ = NULL;
  application_kernel_buffer_size_ = 0;
}

void DFE::Init() {
  if (platform_strong_dill == NULL) {
    return;
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

void DFE::LoadKernelService(const uint8_t** kernel_service_buffer,
                            intptr_t* kernel_service_buffer_size) {
  *kernel_service_buffer = kernel_service_dill;
  *kernel_service_buffer_size = kernel_service_dill_size;
}

void DFE::LoadPlatform(const uint8_t** kernel_buffer,
                       intptr_t* kernel_buffer_size) {
  *kernel_buffer = platform_strong_dill;
  *kernel_buffer_size = platform_strong_dill_size;
}

bool DFE::CanUseDartFrontend() const {
  return (platform_strong_dill != NULL) &&
         (KernelServiceDillAvailable() || (frontend_filename() != NULL));
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

Dart_KernelCompilationResult DFE::CompileScript(const char* script_uri,
                                                bool incremental,
                                                const char* package_config) {
  // TODO(aam): When Frontend is ready, VM should be passing vm_outline.dill
  // instead of vm_platform.dill to Frontend for compilation.
#if defined(HOST_OS_WINDOWS)
  WindowsPathSanitizer path_sanitizer(script_uri);
  const char* sanitized_uri = path_sanitizer.sanitized_uri();
#else
  const char* sanitized_uri = script_uri;
#endif

  return Dart_CompileToKernel(sanitized_uri, platform_strong_dill,
                              platform_strong_dill_size, incremental,
                              package_config);
}

void DFE::CompileAndReadScript(const char* script_uri,
                               uint8_t** kernel_buffer,
                               intptr_t* kernel_buffer_size,
                               char** error,
                               int* exit_code,
                               const char* package_config) {
  Dart_KernelCompilationResult result =
      CompileScript(script_uri, use_incremental_compiler(), package_config);
  switch (result.status) {
    case Dart_KernelCompilationStatus_Ok:
      *kernel_buffer = result.kernel;
      *kernel_buffer_size = result.kernel_size;
      *error = NULL;
      *exit_code = 0;
      break;
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
}

void DFE::ReadScript(const char* script_uri,
                     uint8_t** kernel_buffer,
                     intptr_t* kernel_buffer_size) const {
  int64_t start = Dart_TimelineGetMicros();
  if (!TryReadKernelFile(script_uri, kernel_buffer, kernel_buffer_size)) {
    return;
  }
  if (!Dart_IsKernel(*kernel_buffer, *kernel_buffer_size)) {
    free(*kernel_buffer);
    *kernel_buffer = NULL;
    *kernel_buffer_size = -1;
  }
  int64_t end = Dart_TimelineGetMicros();
  Dart_TimelineEvent("DFE::ReadScript", start, end,
                     Dart_Timeline_Event_Duration, 0, NULL, NULL);
}

// Attempts to treat [buffer] as a in-memory kernel byte representation.
// If successful, returns [true] and places [buffer] into [kernel_ir], byte size
// into [kernel_ir_size].
// If unsuccessful, returns [false], puts [NULL] into [kernel_ir], -1 into
// [kernel_ir_size].
static bool TryReadSimpleKernelBuffer(uint8_t* buffer,
                                      uint8_t** p_kernel_ir,
                                      intptr_t* p_kernel_ir_size) {
  DartUtils::MagicNumber magic_number =
      DartUtils::SniffForMagicNumber(buffer, *p_kernel_ir_size);
  if (magic_number == DartUtils::kKernelMagicNumber) {
    // Do not free buffer if this is a kernel file - kernel_file will be
    // backed by the same memory as the buffer and caller will own it.
    // Caller is responsible for freeing the buffer when this function
    // returns true.
    *p_kernel_ir = buffer;
    return true;
  }
  free(buffer);
  *p_kernel_ir = NULL;
  *p_kernel_ir_size = -1;
  return false;
}

/// Reads [script_uri] file, returns [true] if successful, [false] otherwise.
///
/// If successful, newly allocated buffer with file contents is returned in
/// [buffer], file contents byte count - in [size].
static bool TryReadFile(const char* script_uri, uint8_t** buffer,
                        intptr_t* size) {
  void* script_file = DartUtils::OpenFileUri(script_uri, false);
  if (script_file == NULL) {
    return false;
  }
  DartUtils::ReadFile(buffer, size, script_file);
  DartUtils::CloseFile(script_file);
  if (*size <= 0 || buffer == NULL) {
    return false;
  }
  return true;
}

class KernelIRNode {
 public:
  KernelIRNode(uint8_t* kernel_ir, intptr_t kernel_size)
      : kernel_ir_(kernel_ir), kernel_size_(kernel_size) {}

  ~KernelIRNode() {
    free(kernel_ir_);
  }

  static void Add(KernelIRNode** p_head, KernelIRNode** p_tail,
                  KernelIRNode* node) {
    if (*p_head == NULL) {
      *p_head = node;
    } else {
      (*p_tail)->next_ = node;
    }
    *p_tail = node;
  }

  static void Merge(KernelIRNode* head, uint8_t** p_bytes,
                             intptr_t* p_size) {
    intptr_t size = 0;
    for (KernelIRNode* node = head; node != NULL; node = node->next_) {
      size = size + node->kernel_size_;
    }

    *p_bytes = reinterpret_cast<uint8_t*>(malloc(size));
    if (*p_bytes == NULL) {
      OUT_OF_MEMORY();
    }
    uint8_t* p = *p_bytes;
    KernelIRNode* node = head;
    while (node != NULL) {
      memmove(p, node->kernel_ir_, node->kernel_size_);
      p += node->kernel_size_;
      KernelIRNode* next = node->next_;
      node = next;
    }
    *p_size = size;
  }

  static void Delete(KernelIRNode* head) {
    KernelIRNode* node = head;
    while (node != NULL) {
      KernelIRNode* next = node->next_;
      delete (node);
      node = next;
    }
  }

 private:
  uint8_t* kernel_ir_;
  intptr_t kernel_size_;

  KernelIRNode* next_ = NULL;

  DISALLOW_COPY_AND_ASSIGN(KernelIRNode);
};

// Supports "kernel list" files as input.
// Those are text files that start with '#@dill' on new line, followed
// by absolute paths to kernel files or relative paths, that are relative
// to dart process working directory.
// Below is an example of valid kernel list file:
// ```
// #@dill
// /projects/mytest/build/bin/main.vm.dill
// /projects/mytest/build/packages/mytest/lib.vm.dill
// ```
static bool TryReadKernelListBuffer(uint8_t* buffer, uint8_t** kernel_ir,
                                    intptr_t* kernel_ir_size) {
  KernelIRNode* kernel_ir_head = NULL;
  KernelIRNode* kernel_ir_tail = NULL;
  // Add all kernels to the linked list
  char* filename =
      reinterpret_cast<char*>(buffer + kernel_list_magic_number.length);
  char* tail = strstr(filename, "\n");
  while (tail != NULL) {
    *tail = '\0';
    intptr_t this_kernel_size;
    uint8_t* this_buffer;
    if (!TryReadFile(filename, &this_buffer, &this_kernel_size)) {
      return false;
    }

    uint8_t* this_kernel_ir;
    if (!TryReadSimpleKernelBuffer(this_buffer, &this_kernel_ir,
                                   &this_kernel_size)) {
      // Abandon read if any of the files in the list are invalid.
      KernelIRNode::Delete(kernel_ir_head);
      *kernel_ir = NULL;
      *kernel_ir_size = -1;
      return false;
    }
    KernelIRNode::Add(&kernel_ir_head, &kernel_ir_tail,
                      new KernelIRNode(this_kernel_ir, this_kernel_size));
    filename = tail + 1;
    tail = strstr(filename, "\n");
  }
  free(buffer);

  KernelIRNode::Merge(kernel_ir_head, kernel_ir, kernel_ir_size);
  KernelIRNode::Delete(kernel_ir_head);
  return true;
}

bool DFE::TryReadKernelFile(const char* script_uri,
                            uint8_t** kernel_ir,
                            intptr_t* kernel_ir_size) {
  *kernel_ir = NULL;
  *kernel_ir_size = -1;

  uint8_t* buffer;
  if (!TryReadFile(script_uri, &buffer, kernel_ir_size)) {
    return false;
  }

  DartUtils::MagicNumber magic_number =
      DartUtils::SniffForMagicNumber(buffer, *kernel_ir_size);
  if (magic_number == DartUtils::kKernelListMagicNumber) {
    return TryReadKernelListBuffer(buffer, kernel_ir, kernel_ir_size);
  }
  return TryReadSimpleKernelBuffer(buffer, kernel_ir, kernel_ir_size);
}

}  // namespace bin
}  // namespace dart
