// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/platform.h"

#include <CoreFoundation/CoreFoundation.h>

#if !HOST_OS_IOS
#include <crt_externs.h>  // NOLINT
#endif                    // !HOST_OS_IOS
#include <errno.h>        // NOLINT
#include <mach-o/dyld.h>
#include <signal.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/sysctl.h>   // NOLINT
#include <sys/types.h>    // NOLINT
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
#if HOST_OS_IOS
  return "ios";
#else
  return "macos";
#endif
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
  return "dylib";
}

static const char* GetLocaleName() {
  CFLocaleRef locale = CFLocaleCopyCurrent();
  CFStringRef locale_string = CFLocaleGetIdentifier(locale);
  CFIndex len = CFStringGetLength(locale_string);
  CFIndex max_len =
      CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingUTF8) + 1;
  char* result = reinterpret_cast<char*>(Dart_ScopeAllocate(max_len));
  ASSERT(result != NULL);
  bool success =
      CFStringGetCString(locale_string, result, max_len, kCFStringEncodingUTF8);
  CFRelease(locale);
  if (!success) {
    return NULL;
  }
  return result;
}

static const char* GetPreferredLanguageName() {
  CFArrayRef languages = CFLocaleCopyPreferredLanguages();
  CFIndex languages_length = CFArrayGetCount(languages);
  if (languages_length < 1) {
    CFRelease(languages);
    return NULL;
  }
  CFTypeRef item =
      reinterpret_cast<CFTypeRef>(CFArrayGetValueAtIndex(languages, 0));
  CFTypeID item_type = CFGetTypeID(item);
  ASSERT(item_type == CFStringGetTypeID());
  CFStringRef language = reinterpret_cast<CFStringRef>(item);
  CFIndex len = CFStringGetLength(language);
  CFIndex max_len =
      CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingUTF8) + 1;
  char* result = reinterpret_cast<char*>(Dart_ScopeAllocate(max_len));
  ASSERT(result != NULL);
  bool success =
      CFStringGetCString(language, result, max_len, kCFStringEncodingUTF8);
  CFRelease(languages);
  if (!success) {
    return NULL;
  }
  return result;
}

const char* Platform::LocaleName() {
  // First see if there is a preferred language. If not, return the
  // current locale name.
  const char* preferred_language = GetPreferredLanguageName();
  return (preferred_language != NULL) ? preferred_language : GetLocaleName();
}

bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}

char** Platform::Environment(intptr_t* count) {
#if HOST_OS_IOS
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

const char* Platform::GetExecutableName() {
  return executable_name_;
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
  const char* canon_path = File::GetCanonicalPath(NULL, path);
  return canon_path;
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

#endif  // defined(HOST_OS_MACOS)
