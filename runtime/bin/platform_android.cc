// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/platform.h"

#include <errno.h>        // NOLINT
#include <signal.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/utsname.h>  // NOLINT
#include <termios.h>      // NOLINT
#include <unistd.h>       // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"
#include "platform/signal_blocker.h"

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

class PlatformPosix {
 public:
  static void SaveConsoleConfiguration() {
    SaveConsoleConfigurationHelper(STDOUT_FILENO, &stdout_initial_c_lflag_);
    SaveConsoleConfigurationHelper(STDERR_FILENO, &stderr_initial_c_lflag_);
    SaveConsoleConfigurationHelper(STDIN_FILENO, &stdin_initial_c_lflag_);
  }

  static void RestoreConsoleConfiguration() {
    RestoreConsoleConfigurationHelper(STDOUT_FILENO, stdout_initial_c_lflag_);
    RestoreConsoleConfigurationHelper(STDERR_FILENO, stderr_initial_c_lflag_);
    RestoreConsoleConfigurationHelper(STDIN_FILENO, stdin_initial_c_lflag_);
    stdout_initial_c_lflag_ = -1;
    stderr_initial_c_lflag_ = -1;
    stdin_initial_c_lflag_ = -1;
  }

 private:
  static tcflag_t stdout_initial_c_lflag_;
  static tcflag_t stderr_initial_c_lflag_;
  static tcflag_t stdin_initial_c_lflag_;

  static void SaveConsoleConfigurationHelper(intptr_t fd, tcflag_t* flag) {
    ASSERT(flag != NULL);
    struct termios term;
    int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
    if (status != 0) {
      return;
    }
    *flag = term.c_lflag;
  }

  static void RestoreConsoleConfigurationHelper(intptr_t fd, tcflag_t flag) {
    struct termios term;
    int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
    if (status != 0) {
      return;
    }
    term.c_lflag = flag;
    NO_RETRY_EXPECTED(tcsetattr(fd, TCSANOW, &term));
  }
};

tcflag_t PlatformPosix::stdout_initial_c_lflag_ = 0;
tcflag_t PlatformPosix::stderr_initial_c_lflag_ = 0;
tcflag_t PlatformPosix::stdin_initial_c_lflag_ = 0;

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
  if (sigaction(SIGBUS, &act, NULL) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGTRAP, &act, NULL) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  SaveConsoleConfiguration();
  return true;
}

int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}

const char* Platform::OperatingSystem() {
  return "android";
}

const char* Platform::OperatingSystemVersion() {
  struct utsname info;
  int ret = uname(&info);
  if (ret != 0) {
    return NULL;
  }
  const char* kFormat = "%s %s %s";
  int len =
      snprintf(NULL, 0, kFormat, info.sysname, info.release, info.version);
  if (len <= 0) {
    return NULL;
  }
  char* result = DartUtils::ScopedCString(len + 1);
  ASSERT(result != NULL);
  len = snprintf(result, len + 1, kFormat, info.sysname, info.release,
                 info.version);
  if (len <= 0) {
    return NULL;
  }
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

void Platform::Exit(int exit_code) {
  RestoreConsoleConfiguration();
  exit(exit_code);
}

void Platform::SaveConsoleConfiguration() {
  PlatformPosix::SaveConsoleConfiguration();
}

void Platform::RestoreConsoleConfiguration() {
  PlatformPosix::RestoreConsoleConfiguration();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
