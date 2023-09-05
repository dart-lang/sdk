// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PLATFORM_H_
#define RUNTIME_BIN_PLATFORM_H_

#include "bin/builtin.h"

#include "platform/atomic.h"
#include "platform/globals.h"
#include "platform/utils.h"

#if defined(DART_HOST_OS_MACOS)
#include "bin/platform_macos.h"
#endif  // defined(DART_HOST_OS_MACOS)

namespace dart {
namespace bin {

class Platform {
 public:
  // Perform platform specific initialization.
  static bool Initialize();

  // Returns the number of processors on the machine.
  static int NumberOfProcessors();

  // Returns a string representing the operating system ("linux",
  // "macos", "windows", or "android"). The returned string should not be
  // deallocated by the caller.
  static const char* OperatingSystem() { return kHostOperatingSystemName; }

  // Returns a string representing the version of the operating system. The
  // format of the string is determined by the platform. The returned string
  // should not be deallocated by the caller.
  static const char* OperatingSystemVersion();

  // Returns the architecture name of the processor the VM is running on
  // (ia32, x64, arm, or arm64).
  static const char* HostArchitecture() { return kHostArchitectureName; }

  static const char* LibraryPrefix();

  // Returns a string representing the operating system's shared library
  // extension (e.g. 'so', 'dll', ...). The returned string should not be
  // deallocated by the caller.
  static const char* LibraryExtension();

  // Extracts the local hostname.
  static bool LocalHostname(char* buffer, intptr_t buffer_length);

  static const char* LocaleName();

  // Extracts the environment variables for the current process.  The array of
  // strings is Dart_ScopeAllocated. The number of elements in the array is
  // returned in the count argument.
  static char** Environment(intptr_t* count);

  static const char* ResolveExecutablePath();

  // This has the same effect as calling ResolveExecutablePath except that
  // Dart_ScopeAllocate is not called and that the result goes into the given
  // parameters.
  // WARNING: On Fuchsia it returns -1, i.e. doesn't work.
  // Note that `result` should be pre-allocated with size `result_size`.
  // The return-value is the length read into `result` or -1 on failure.
  static intptr_t ResolveExecutablePathInto(char* result, size_t result_size);

  // Stores the executable name.
  static void SetExecutableName(const char* executable_name) {
    executable_name_ = executable_name;
  }
  static const char* GetExecutableName();
  static const char* GetResolvedExecutableName() {
    if (resolved_executable_name_.load() == nullptr) {
      // Try to resolve the executable path using platform specific APIs.
      const char* resolved_name = Platform::ResolveExecutablePath();
      if (resolved_name != nullptr) {
        char* resolved_name_copy = Utils::StrDup(resolved_name);
        const char* expect_old_is_null = nullptr;
        if (!resolved_executable_name_.compare_exchange_strong(
                expect_old_is_null, resolved_name_copy)) {
          free(resolved_name_copy);
        }
      }
    }
    return resolved_executable_name_.load();
  }

  // Stores and gets the flags passed to the executable.
  static void SetExecutableArguments(int script_index, char** argv) {
    script_index_ = script_index;
    argv_ = argv;
  }
  static int GetScriptIndex() { return script_index_; }
  static char** GetArgv() { return argv_; }

  static void SetProcessName(const char* name);

  DART_NORETURN static void Exit(int exit_code);
  DART_NORETURN static void _Exit(int exit_code);

  static void SetCoreDumpResourceLimit(int value);

#if defined(DART_HOST_OS_FUCHSIA)
  static zx_handle_t GetVMEXResource();
#endif

 private:
  // The path to the executable.
  static const char* executable_name_;

  // The path to the resolved executable.
  //
  // We use require-release semantics to ensure initializing stores to the
  // string are visible when the string becomes visible.
  static AcqRelAtomic<const char*> resolved_executable_name_;

  static int script_index_;
  static char** argv_;  // VM flags are argv_[1 ... script_index_ - 1]

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Platform);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PLATFORM_H_
