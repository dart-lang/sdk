// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include <mach-o/dyld.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#include "bin/file.h"
#include "bin/platform.h"

#if !defined(TARGET_OS_IOS)
#include <crt_externs.h>  // NOLINT
#endif  // !defined(TARGET_OS_IOS)
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
  int32_t cpus = -1;
  size_t cpus_length = sizeof(cpus);
  if (sysctlbyname("hw.logicalcpu", &cpus, &cpus_length, NULL, 0) == 0) {
    return cpus;
  } else {
    // Failed, fallback to using sysconf.
    return sysconf(_SC_NPROCESSORS_ONLN);
  }
}


const char* Platform::OperatingSystem() {
  return "macos";
}


const char* Platform::LibraryExtension() {
  return "dylib";
}


bool Platform::LocalHostname(char *buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}


char** Platform::Environment(intptr_t* count) {
#if defined(TARGET_OS_IOS)
  // TODO(iposva): On Mac (desktop), _NSGetEnviron() is used to access the
  // environ from shared libraries or bundles. This is present in crt_externs.h
  // which is unavailable on iOS. On iOS, everything is statically linked for
  // now. So arguably, accessing the environ directly with a "extern char
  // **environ" will work. But this approach is brittle as the target with this
  // CU could be a dynamic framework (introduced in iOS 8). A more elegant
  // approach needs to be devised.
  return NULL;
#else
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
  // On MacOS you have to do a bit of magic to get to the
  // environment strings.
  char** environ = *(_NSGetEnviron());
  intptr_t i = 0;
  char** tmp = environ;
  while (*(tmp++) != NULL) i++;
  *count = i;
  char** result = new char*[i];
  for (intptr_t current = 0; current < i; current++) {
    result[current] = environ[current];
  }
  return result;
#endif
}


void Platform::FreeEnvironment(char** env, intptr_t count) {
  delete[] env;
}


char* Platform::ResolveExecutablePath() {
  // Get the required length of the buffer.
  uint32_t path_size = 0;
  char* path = NULL;
  if (_NSGetExecutablePath(path, &path_size) == 0) {
    return NULL;
  }
  // Allocate buffer and get executable path.
  path = reinterpret_cast<char*>(malloc(path_size));
  if (_NSGetExecutablePath(path, &path_size) != 0) {
    free(path);
    return NULL;
  }
  // Return the canonical path as the returned path might contain symlinks.
  char* canon_path = File::GetCanonicalPath(path);
  free(path);
  return canon_path;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
