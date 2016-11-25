// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/platform.h"

#if !TARGET_OS_IOS
#include <crt_externs.h>  // NOLINT
#endif                    // !TARGET_OS_IOS
#include <mach-o/dyld.h>
#include <signal.h>      // NOLINT
#include <string.h>      // NOLINT
#include <sys/sysctl.h>  // NOLINT
#include <sys/types.h>   // NOLINT
#include <unistd.h>      // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
char* Platform::resolved_executable_name_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

static void segv_handler(int signal, siginfo_t* siginfo, void* context) {
  Dart_DumpNativeStackTrace(context);
  abort();
}


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
  act.sa_flags = SA_SIGINFO;
  act.sa_sigaction = &segv_handler;
  if (sigemptyset(&act.sa_mask) != 0) {
    perror("sigemptyset() failed.");
    return false;
  }
  if (sigaddset(&act.sa_mask, SIGPROF) != 0) {
    perror("sigaddset() failed");
    return false;
  }
  if (sigaction(SIGSEGV, &act, NULL) != 0) {
    perror("sigaction() failed.");
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
#if TARGET_OS_IOS
  return "ios";
#else
  return "macos";
#endif
}


const char* Platform::LibraryPrefix() {
  return "lib";
}


const char* Platform::LibraryExtension() {
  return "dylib";
}


bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}


char** Platform::Environment(intptr_t* count) {
#if TARGET_OS_IOS
  // TODO(zra,chinmaygarde): On iOS, environment variables are seldom used. Wire
  // this up if someone needs it. In the meantime, we return an empty array.
  char** result;
  result = reinterpret_cast<char**>(Dart_ScopeAllocate(1 * sizeof(*result)));
  if (result == NULL) {
    return NULL;
  }
  result[0] = NULL;
  *count = 0;
  return result;
#else
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
  // On MacOS you have to do a bit of magic to get to the
  // environment strings.
  char** environ = *(_NSGetEnviron());
  intptr_t i = 0;
  char** tmp = environ;
  while (*(tmp++) != NULL) {
    i++;
  }
  *count = i;
  char** result;
  result = reinterpret_cast<char**>(Dart_ScopeAllocate(i * sizeof(*result)));
  for (intptr_t current = 0; current < i; current++) {
    result[current] = environ[current];
  }
  return result;
#endif
}


const char* Platform::ResolveExecutablePath() {
  // Get the required length of the buffer.
  uint32_t path_size = 0;
  if (_NSGetExecutablePath(NULL, &path_size) == 0) {
    return NULL;
  }
  // Allocate buffer and get executable path.
  char* path = DartUtils::ScopedCString(path_size);
  if (_NSGetExecutablePath(path, &path_size) != 0) {
    return NULL;
  }
  // Return the canonical path as the returned path might contain symlinks.
  const char* canon_path = File::GetCanonicalPath(path);
  return canon_path;
}


void Platform::Exit(int exit_code) {
  exit(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
