// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/platform.h"

#include <errno.h>        // NOLINT
#include <signal.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/resource.h>
#include <sys/system_properties.h>
#include <sys/utsname.h>  // NOLINT
#include <unistd.h>       // NOLINT

#include "bin/console.h"
#include "bin/file.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
char* Platform::resolved_executable_name_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

static void segv_handler(int signal, siginfo_t* siginfo, void* context) {
  Syslog::PrintErr(
      "\n===== CRASH =====\n"
      "si_signo=%s(%d), si_code=%d, si_addr=%p\n",
      strsignal(siginfo->si_signo), siginfo->si_signo, siginfo->si_code,
      siginfo->si_addr);
  Dart_DumpNativeStackTrace(context);
  Dart_PrepareToAbort();
  abort();
}

bool Platform::Initialize() {
  // Turn off the signal handler for SIGPIPE as it causes the process
  // to terminate on writing to a closed pipe. Without the signal
  // handler error EPIPE is set instead.
  struct sigaction act = {};
  act.sa_handler = SIG_IGN;
  if (sigaction(SIGPIPE, &act, 0) != 0) {
    perror("Setting signal handler failed");
    return false;
  }

  // tcsetattr raises SIGTTOU if we try to set console attributes when
  // backgrounded, which suspends the process. Ignoring the signal prevents
  // us from being suspended and lets us fail gracefully instead.
  sigset_t signal_mask;
  sigemptyset(&signal_mask);
  sigaddset(&signal_mask, SIGTTOU);
  if (sigprocmask(SIG_BLOCK, &signal_mask, NULL) < 0) {
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
  if (sigaction(SIGBUS, &act, NULL) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGTRAP, &act, NULL) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGILL, &act, NULL) != 0) {
    perror("sigaction() failed.");
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

const char* Platform::OperatingSystemVersion() {
  char os_version[PROP_VALUE_MAX + 1];
  int os_version_length =
      __system_property_get("ro.build.display.id", os_version);
  if (os_version_length == 0) {
    return NULL;
  }
  ASSERT(os_version_length <= PROP_VALUE_MAX);
  char* result = reinterpret_cast<char*>(
      Dart_ScopeAllocate((os_version_length + 1) * sizeof(result)));
  strncpy(result, os_version, (os_version_length + 1));
  return result;
}

const char* Platform::LibraryPrefix() {
  return "lib";
}

const char* Platform::LibraryExtension() {
  return "so";
}

const char* Platform::LocaleName() {
  char* lang = getenv("LANG");
  if (lang == NULL) {
    return "en_US";
  }
  return lang;
}

bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}

char** Platform::Environment(intptr_t* count) {
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
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
}

const char* Platform::GetExecutableName() {
  return executable_name_;
}

const char* Platform::ResolveExecutablePath() {
  return File::ReadLink("/proc/self/exe");
}

intptr_t Platform::ResolveExecutablePathInto(char* result, size_t result_size) {
  return File::ReadLinkInto("/proc/self/exe", result, result_size);
}

void Platform::Exit(int exit_code) {
  Console::RestoreConfig();
  Dart_PrepareToAbort();
  exit(exit_code);
}

void Platform::SetCoreDumpResourceLimit(int value) {
  rlimit limit = {static_cast<rlim_t>(value), static_cast<rlim_t>(value)};
  setrlimit(RLIMIT_CORE, &limit);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
