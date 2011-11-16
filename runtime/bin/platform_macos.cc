// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"

#include <string.h>
#include <unistd.h>


int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}


const char* Platform::OperatingSystem() {
  return "macos";
}


char* Platform::StrError(int error_code) {
  static const int kBufferSize = 1024;
  char* error = static_cast<char*>(malloc(kBufferSize));
  error[0] = '\0';
  strerror_r(error_code, error, kBufferSize);
  return error;
}
