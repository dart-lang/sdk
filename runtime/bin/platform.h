// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PLATFORM_H_
#define RUNTIME_BIN_PLATFORM_H_

#include "bin/builtin.h"
#include "platform/globals.h"
#include "platform/utils.h"

#if defined(HOST_OS_MACOS)
#include "bin/platform_macos.h"
#endif  // defined(HOST_OS_MACOS)

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
  static const char* OperatingSystem();

  // Returns a string representing the version of the operating system. The
  // format of the string is determined by the platform. The returned string
  // should not be deallocated by the caller.
  static const char* OperatingSystemVersion();

  // Returns the architecture name of the processor the VM is running on
  // (ia32, x64, arm, or arm64).
  static const char* HostArchitecture() {
#if defined(HOST_ARCH_ARM)
    return "arm";
#elif defined(HOST_ARCH_ARM64)
    return "arm64";
#elif defined(HOST_ARCH_IA32)
    return "ia32";
#elif defined(HOST_ARCH_X64)
    return "x64";
#else
#error Architecture detection failed.
#endif
  }

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
    if (resolved_executable_name_ == NULL) {
      // Try to resolve the executable path using platform specific APIs.
      const char* resolved_name = Platform::ResolveExecutablePath();
      if (resolved_name != NULL) {
        resolved_executable_name_ = Utils::StrDup(resolved_name);
      }
    }
    return resolved_executable_name_;
  }

  // Stores and gets the flags passed to the executable.
  static void SetExecutableArguments(int script_index, char** argv) {
    script_index_ = script_index;
    argv_ = argv;
  }
  static int GetScriptIndex() { return script_index_; }
  static char** GetArgv() { return argv_; }

  DART_NORETURN static void Exit(int exit_code);

  static void SetCoreDumpResourceLimit(int value);

 private:
  // The path to the executable.
  static const char* executable_name_;
  // The path to the resolved executable.
  static char* resolved_executable_name_;

  static int script_index_;
  static char** argv_;  // VM flags are argv_[1 ... script_index_ - 1]

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Platform);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PLATFORM_H_
