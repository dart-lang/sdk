// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PLATFORM_H_
#define BIN_PLATFORM_H_

#include "bin/builtin.h"


namespace dart {
namespace bin {

class Platform {
 public:
  // Perform platform specific initialization.
  static bool Initialize();

  // Returns the number of processors on the machine.
  static int NumberOfProcessors();

  // Returns a string representing the operating system ("linux",
  // "macos" or "windows"). The returned string should not be
  // deallocated by the caller.
  static const char* OperatingSystem();

  // Returns a string representing the operating system's shared library
  // extension (e.g. 'so', 'dll', ...). The returned string should not be
  // deallocated by the caller.
  static const char* LibraryExtension();

  // Extracts the local hostname.
  static bool LocalHostname(char* buffer, intptr_t buffer_length);

  // Extracts the environment variables for the current process.  The
  // array of strings returned must be deallocated using
  // FreeEnvironment. The number of elements in the array is returned
  // in the count argument.
  static char** Environment(intptr_t* count);
  static void FreeEnvironment(char** env, intptr_t count);

  static char* ResolveExecutablePath();

  // Stores the executable name.
  static void SetExecutableName(const char* executable_name) {
    executable_name_ = executable_name;
  }
  static const char* GetExecutableName() {
    return executable_name_;
  }
  static const char* GetResolvedExecutableName() {
    if (resolved_executable_name_ == NULL) {
      // Try to resolve the executable path using platform specific APIs.
      resolved_executable_name_ = Platform::ResolveExecutablePath();
    }
    return resolved_executable_name_;
  }

  // Stores and gets the flags passed to the executable.
  static void SetExecutableArguments(int script_index, char** argv) {
    script_index_ = script_index;
    argv_ = argv;
  }
  static int GetScriptIndex() {
    return script_index_;
  }
  static char** GetArgv() {
    return argv_;
  }

  static DART_NORETURN void Exit(int exit_code);

 private:
  // The path to the executable.
  static const char* executable_name_;
  // The path to the resolved executable.
  static const char* resolved_executable_name_;

  static int script_index_;
  static char** argv_;  // VM flags are argv_[1 ... script_index_ - 1]

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Platform);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_PLATFORM_H_
