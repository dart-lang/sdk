// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/file.h"
#include "bin/platform.h"

#include <signal.h>  // NOLINT
#include <string.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "bin/fdutils.h"


namespace dart {
namespace bin {

bool Platform::Initialize() {
  // Turn off the signal handler for SIGPIPE as it causes the process
  // to terminate on writing to a closed pipe. Without the signal
  // handler error EPIPE is set instead.
  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_handler = SIG_IGN;
  if (sigaction(SIGPIPE, &act, 0) != 0) {
    perror("Setting signal handler failed");
    return false;
  }
  return true;
}


int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}


const char* Platform::OperatingSystem() {
  return "android";
}


const char* Platform::LibraryExtension() {
  return "so";
}


bool Platform::LocalHostname(char *buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}


char** Platform::Environment(intptr_t* count) {
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
  intptr_t i = 0;
  char** tmp = environ;
  while (*(tmp++) != NULL) i++;
  *count = i;
  char** result = new char*[i];
  for (intptr_t current = 0; current < i; current++) {
    result[current] = environ[current];
  }
  return result;
}


void Platform::FreeEnvironment(char** env, intptr_t count) {
  delete[] env;
}


char* Platform::ResolveExecutablePath() {
  return File::LinkTarget("/proc/self/exe");
}

void Platform::Exit(int exit_code) {
  exit(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
