// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PLATFORM_H_
#define RUNTIME_BIN_PLATFORM_H_

#include "bin/builtin.h"
#include "platform/globals.h"

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

  // Returns the architecture name of the processor the VM is running on
  // (ia32, x64, arm, arm64, or mips).
  static const char* HostArchitecture() {
#if defined(HOST_ARCH_ARM)
    return "arm";
#elif defined(HOST_ARCH_ARM64)
    return "arm64";
#elif defined(HOST_ARCH_IA32)
    return "ia32";
#elif defined(HOST_ARCH_MIPS)
    return "mips";
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

  // Stores the executable name.
  static void SetExecutableName(const char* executable_name) {
    executable_name_ = executable_name;
  }
  static const char* GetExecutableName() { return executable_name_; }
  static const char* GetResolvedExecutableName() {
    if (resolved_executable_name_ == NULL) {
      // Try to resolve the executable path using platform specific APIs.
      const char* resolved_name = Platform::ResolveExecutablePath();
      if (resolved_name != NULL) {
        resolved_executable_name_ = strdup(resolved_name);
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

  static DART_NORETURN void Exit(int exit_code);

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
