// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dfe.h"

#include <memory>

#include "bin/abi_version.h"
#include "bin/dartutils.h"
#include "bin/directory.h"
#include "bin/error_exit.h"
#include "bin/exe_utils.h"
#include "bin/file.h"
#include "bin/main_options.h"
#include "bin/platform.h"
#include "bin/utils.h"
#include "include/dart_tools_api.h"
#include "platform/utils.h"

extern "C" {
#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
extern const uint8_t kKernelServiceDill[];
extern intptr_t kKernelServiceDillSize;
extern const uint8_t kPlatformStrongDill[];
extern intptr_t kPlatformStrongDillSize;
#else
const uint8_t* kKernelServiceDill = nullptr;
intptr_t kKernelServiceDillSize = 0;
const uint8_t* kPlatformStrongDill = nullptr;
intptr_t kPlatformStrongDillSize = 0;
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
}

namespace dart {
namespace bin {

#if !defined(DART_PRECOMPILED_RUNTIME)
DFE dfe;
#endif

const char kKernelServiceSnapshot[] = "kernel-service.dart.snapshot";
const char kSnapshotsDirectory[] = "snapshots";

DFE::DFE()
    : use_dfe_(false),
      use_incremental_compiler_(false),
      frontend_filename_(nullptr),
      application_kernel_buffer_(nullptr),
      application_kernel_buffer_size_(0) {
  // The run_vm_tests binary has the DART_PRECOMPILER set in order to allow unit
  // tests to exercise JIT and AOT pipeline.
  //
  // Only on X64 do we have kernel-service.dart.snapshot available otherwise we
  // need to fall back to the built-in one (if we have it).
#if defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM) ||                                \
    (defined(DART_PRECOMPILER) && defined(TARGET_ARCH_X64))
  kernel_service_dill_ = nullptr;
  kernel_service_dill_size_ = 0;
#else
  kernel_service_dill_ = kKernelServiceDill;
  kernel_service_dill_size_ = kKernelServiceDillSize;
#endif

#if defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
  platform_strong_dill_for_compilation_ = nullptr;
  platform_strong_dill_for_compilation_size_ = 0;
  platform_strong_dill_for_execution_ = nullptr;
  platform_strong_dill_for_execution_size_ = 0;
#else
  platform_strong_dill_for_compilation_ = kPlatformStrongDill;
  platform_strong_dill_for_compilation_size_ = kPlatformStrongDillSize;
  platform_strong_dill_for_execution_ = kPlatformStrongDill;
  platform_strong_dill_for_execution_size_ = kPlatformStrongDillSize;
#endif
}

DFE::~DFE() {
  if (frontend_filename_ != nullptr) {
    free(frontend_filename_);
  }
  frontend_filename_ = nullptr;

  free(application_kernel_buffer_);
  application_kernel_buffer_ = nullptr;
  application_kernel_buffer_size_ = 0;
}

void DFE::Init() {
  Init(Options::kAbiVersionUnset);
}

void DFE::Init(int target_abi_version) {
  if (platform_strong_dill_for_compilation_ == nullptr) {
    return;
  }

  if (!InitKernelServiceAndPlatformDills(target_abi_version)) {
    return;
  }

  Dart_SetDartLibrarySourcesKernel(platform_strong_dill_for_compilation_,
                                   platform_strong_dill_for_compilation_size_);
}

bool DFE::InitKernelServiceAndPlatformDills(int target_abi_version) {
  const char kAbiVersionsDir[] = "dart-sdk/lib/_internal/abiversions";
  const char kKernelServiceDillFile[] = "kernel_service.dill";
  const char kPlatformStrongDillFile[] = "vm_platform_strong.dill";

  if (frontend_filename_ != nullptr) {
    return true;
  }

  // |dir_prefix| includes the last path seperator.
  auto dir_prefix = EXEUtils::GetDirectoryPrefixFromExeName();

  if (target_abi_version != Options::kAbiVersionUnset) {
    kernel_service_dill_ = nullptr;
    kernel_service_dill_size_ = 0;
    platform_strong_dill_for_compilation_ = nullptr;
    platform_strong_dill_for_compilation_size_ = 0;

    // Look in the old abi version directory.
    char* script_uri =
        Utils::SCreate("%s%s/%d/%s", dir_prefix.get(), kAbiVersionsDir,
                       target_abi_version, kPlatformStrongDillFile);
    if (!TryReadKernelFile(
            script_uri,
            const_cast<uint8_t**>(&platform_strong_dill_for_compilation_),
            &platform_strong_dill_for_compilation_size_)) {
      Syslog::PrintErr("Can't find old ABI dill file: %s\n", script_uri);
      free(script_uri);
      return false;
    }
    free(script_uri);
    script_uri = Utils::SCreate("%s%s/%d/%s", dir_prefix.get(), kAbiVersionsDir,
                                target_abi_version, kKernelServiceDillFile);
    if (!TryReadKernelFile(script_uri,
                           const_cast<uint8_t**>(&kernel_service_dill_),
                           &kernel_service_dill_size_)) {
      Syslog::PrintErr("Can't find old ABI dill file: %s\n", script_uri);
      free(script_uri);
      return false;
    } else {
      frontend_filename_ = script_uri;
      return true;
    }
  }

  // Look for the frontend snapshot next to the executable.
  frontend_filename_ =
      Utils::SCreate("%s%s", dir_prefix.get(), kKernelServiceSnapshot);
  if (File::Exists(nullptr, frontend_filename_)) {
    return true;
  }
  free(frontend_filename_);
  frontend_filename_ = nullptr;

  // If the frontend snapshot is not found next to the executable, then look for
  // it in the "snapshots" directory.
  frontend_filename_ =
      Utils::SCreate("%s%s%s%s", dir_prefix.get(), kSnapshotsDirectory,
                     File::PathSeparator(), kKernelServiceSnapshot);
  if (File::Exists(nullptr, frontend_filename_)) {
    return true;
  }
  free(frontend_filename_);
  frontend_filename_ = nullptr;
  return true;
}

bool DFE::KernelServiceDillAvailable() const {
  return kernel_service_dill_ != nullptr;
}

void DFE::LoadKernelService(const uint8_t** kernel_service_buffer,
                            intptr_t* kernel_service_buffer_size) {
  *kernel_service_buffer = kernel_service_dill_;
  *kernel_service_buffer_size = kernel_service_dill_size_;
}

void DFE::LoadPlatform(const uint8_t** kernel_buffer,
                       intptr_t* kernel_buffer_size) {
  *kernel_buffer = platform_strong_dill_for_execution_;
  *kernel_buffer_size = platform_strong_dill_for_execution_size_;
}

bool DFE::CanUseDartFrontend() const {
  return (platform_strong_dill_for_compilation_ != nullptr) &&
         (KernelServiceDillAvailable() || (frontend_filename() != nullptr));
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
    if (sanitized_uri_ == nullptr) {
      OUT_OF_MEMORY();
    }
    char* s = sanitized_uri_;
    if (len > 2 && path[1] == ':') {
      *s++ = '/';
    }
    for (const char* p = path; *p != '\0'; ++p, ++s) {
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

  return Dart_CompileToKernel(
      sanitized_uri, platform_strong_dill_for_compilation_,
      platform_strong_dill_for_compilation_size_, incremental, package_config);
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
      *error = nullptr;
      *exit_code = 0;
      break;
    case Dart_KernelCompilationStatus_Error:
      free(result.kernel);
      *error = result.error;  // Copy error message.
      *exit_code = kCompilationErrorExitCode;
      break;
    case Dart_KernelCompilationStatus_Crash:
      free(result.kernel);
      *error = result.error;  // Copy error message.
      *exit_code = kDartFrontendErrorExitCode;
      break;
    case Dart_KernelCompilationStatus_Unknown:
      free(result.kernel);
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
    *kernel_buffer = nullptr;
    *kernel_buffer_size = -1;
  }
  int64_t end = Dart_TimelineGetMicros();
  Dart_TimelineEvent("DFE::ReadScript", start, end,
                     Dart_Timeline_Event_Duration, 0, nullptr, nullptr);
}

// Attempts to treat [buffer] as a in-memory kernel byte representation.
// If successful, returns [true] and places [buffer] into [kernel_ir], byte size
// into [kernel_ir_size].
// If unsuccessful, returns [false], puts [nullptr] into [kernel_ir], -1 into
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
  *p_kernel_ir = nullptr;
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
  if (script_file == nullptr) {
    return false;
  }
  DartUtils::ReadFile(buffer, size, script_file);
  DartUtils::CloseFile(script_file);
  if (buffer == nullptr) {
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
    if (*p_head == nullptr) {
      *p_head = node;
    } else {
      (*p_tail)->next_ = node;
    }
    *p_tail = node;
  }

  static void Merge(KernelIRNode* head, uint8_t** p_bytes,
                             intptr_t* p_size) {
    intptr_t size = 0;
    for (KernelIRNode* node = head; node != nullptr; node = node->next_) {
      size = size + node->kernel_size_;
    }

    *p_bytes = reinterpret_cast<uint8_t*>(malloc(size));
    if (*p_bytes == nullptr) {
      OUT_OF_MEMORY();
    }
    uint8_t* p = *p_bytes;
    KernelIRNode* node = head;
    while (node != nullptr) {
      memmove(p, node->kernel_ir_, node->kernel_size_);
      p += node->kernel_size_;
      KernelIRNode* next = node->next_;
      node = next;
    }
    *p_size = size;
  }

  static void Delete(KernelIRNode* head) {
    KernelIRNode* node = head;
    while (node != nullptr) {
      KernelIRNode* next = node->next_;
      delete (node);
      node = next;
    }
  }

 private:
  uint8_t* kernel_ir_;
  intptr_t kernel_size_;

  KernelIRNode* next_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(KernelIRNode);
};

class StringPointer {
 public:
  explicit StringPointer(char* c_str) : c_str_(c_str) {}
  ~StringPointer() { free(c_str_); }

  const char* c_str() { return c_str_; }

 private:
  char* c_str_;
  DISALLOW_COPY_AND_ASSIGN(StringPointer);
};

// Supports "kernel list" files as input.
// Those are text files that start with '#@dill' on new line, followed
// by absolute paths to kernel files or relative paths, that are relative
// to [script_uri] "kernel list" file.
// Below is an example of valid kernel list file:
// ```
// #@dill
// /projects/mytest/build/bin/main.vm.dill
// /projects/mytest/build/packages/mytest/lib.vm.dill
// ```
static bool TryReadKernelListBuffer(const char* script_uri,
                                    uint8_t* buffer,
                                    intptr_t buffer_size,
                                    uint8_t** kernel_ir,
                                    intptr_t* kernel_ir_size) {
  const char* kernel_list_dirname = DartUtils::DirName(script_uri);
  if (strcmp(kernel_list_dirname, script_uri) == 0) {
    kernel_list_dirname = "";
  }
  KernelIRNode* kernel_ir_head = nullptr;
  KernelIRNode* kernel_ir_tail = nullptr;
  // Add all kernels to the linked list
  char* filename =
      reinterpret_cast<char*>(buffer + kernel_list_magic_number.length);
  intptr_t filename_size = buffer_size - kernel_list_magic_number.length;
  char* tail = reinterpret_cast<char*>(memchr(filename, '\n', filename_size));
  while (tail != nullptr) {
    *tail = '\0';
    intptr_t this_kernel_size;
    uint8_t* this_buffer;

    StringPointer resolved_filename(
        File::IsAbsolutePath(filename)
            ? strdup(filename)
            : Utils::SCreate("%s%s", kernel_list_dirname, filename));
    if (!TryReadFile(resolved_filename.c_str(), &this_buffer,
                     &this_kernel_size)) {
      return false;
    }

    uint8_t* this_kernel_ir;
    if (!TryReadSimpleKernelBuffer(this_buffer, &this_kernel_ir,
                                   &this_kernel_size)) {
      // Abandon read if any of the files in the list are invalid.
      KernelIRNode::Delete(kernel_ir_head);
      *kernel_ir = nullptr;
      *kernel_ir_size = -1;
      return false;
    }
    KernelIRNode::Add(&kernel_ir_head, &kernel_ir_tail,
                      new KernelIRNode(this_kernel_ir, this_kernel_size));
    filename_size -= tail + 1 - filename;
    filename = tail + 1;
    tail = reinterpret_cast<char*>(memchr(filename, '\n', filename_size));
  }
  free(buffer);

  KernelIRNode::Merge(kernel_ir_head, kernel_ir, kernel_ir_size);
  KernelIRNode::Delete(kernel_ir_head);
  return true;
}

bool DFE::TryReadKernelFile(const char* script_uri,
                            uint8_t** kernel_ir,
                            intptr_t* kernel_ir_size) {
  *kernel_ir = nullptr;
  *kernel_ir_size = -1;

  uint8_t* buffer;
  if (!TryReadFile(script_uri, &buffer, kernel_ir_size)) {
    return false;
  }

  DartUtils::MagicNumber magic_number =
      DartUtils::SniffForMagicNumber(buffer, *kernel_ir_size);
  if (magic_number == DartUtils::kKernelListMagicNumber) {
    return TryReadKernelListBuffer(script_uri, buffer, *kernel_ir_size,
                                   kernel_ir, kernel_ir_size);
  }
  return TryReadSimpleKernelBuffer(buffer, kernel_ir, kernel_ir_size);
}

}  // namespace bin
}  // namespace dart
