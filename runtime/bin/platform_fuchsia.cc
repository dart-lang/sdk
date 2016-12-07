// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/platform.h"

#include <string.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
char* Platform::resolved_executable_name_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

bool Platform::Initialize() {
  return true;
}


int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_CONF);
}


const char* Platform::OperatingSystem() {
  return "fuchsia";
}


const char* Platform::LibraryPrefix() {
  return "lib";
}


const char* Platform::LibraryExtension() {
  return "so";
}


bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}


char** Platform::Environment(intptr_t* count) {
  char** result =
      reinterpret_cast<char**>(Dart_ScopeAllocate(1 * sizeof(*result)));
  result[0] = NULL;
  return result;
}


const char* Platform::ResolveExecutablePath() {
  return "dart";
}


void Platform::Exit(int exit_code) {
  exit(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
