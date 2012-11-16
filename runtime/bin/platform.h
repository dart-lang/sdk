// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PLATFORM_H_
#define BIN_PLATFORM_H_

#include "bin/builtin.h"

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

  // Returns a string representation of an error code. The returned
  // string must be deallocated by the caller.
  static char* StrError(int error_code);

  // Extracts the local hostname.
  static bool LocalHostname(char* buffer, intptr_t buffer_length);

  // Extracts the environment variables for the current process.  The
  // array of strings returned must be deallocated using
  // FreeEnvironment. The number of elements in the array is returned
  // in the count argument.
  static char** Environment(intptr_t* count);
  static void FreeEnvironment(char** env, intptr_t count);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Platform);
};

#endif  // BIN_PLATFORM_H_
