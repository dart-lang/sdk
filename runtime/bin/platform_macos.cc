// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "bin/platform.h"
#include "bin/platform_macos.h"

#include <CoreFoundation/CoreFoundation.h>

#if !DART_HOST_OS_IOS
#include <crt_externs.h>
#endif                    // !DART_HOST_OS_IOS
#include <dlfcn.h>
#include <errno.h>
#include <mach-o/dyld.h>
#include <pthread.h>
#include <signal.h>
#include <sys/resource.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>

#include <string>

#include "bin/console.h"
#include "bin/file.h"
#include "bin/platform_macos_cocoa.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = nullptr;
int Platform::script_index_ = 1;
char** Platform::argv_ = nullptr;

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
  if (sigaction(SIGPIPE, &act, nullptr) != 0) {
    perror("Setting signal handler failed");
    return false;
  }

  // tcsetattr raises SIGTTOU if we try to set console attributes when
  // backgrounded, which suspends the process. Ignoring the signal prevents
  // us from being suspended and lets us fail gracefully instead.
  sigset_t signal_mask;
  sigemptyset(&signal_mask);
  sigaddset(&signal_mask, SIGTTOU);
  if (sigprocmask(SIG_BLOCK, &signal_mask, nullptr) < 0) {
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
  if (sigaction(SIGSEGV, &act, nullptr) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGBUS, &act, nullptr) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGTRAP, &act, nullptr) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  if (sigaction(SIGILL, &act, nullptr) != 0) {
    perror("sigaction() failed.");
    return false;
  }
  return true;
}

int Platform::NumberOfProcessors() {
  int32_t cpus = -1;
  size_t cpus_length = sizeof(cpus);
  if (sysctlbyname("hw.logicalcpu", &cpus, &cpus_length, nullptr, 0) == 0) {
    return cpus;
  } else {
    // Failed, fallback to using sysconf.
    return sysconf(_SC_NPROCESSORS_ONLN);
  }
}

const char* Platform::OperatingSystemVersion() {
  std::string version(NSProcessInfoOperatingSystemVersionString());
  return DartUtils::ScopedCopyCString(version.c_str());
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
  ASSERT(result != nullptr);
  bool success =
      CFStringGetCString(locale_string, result, max_len, kCFStringEncodingUTF8);
  CFRelease(locale);
  if (!success) {
    return nullptr;
  }
  return result;
}

static const char* GetPreferredLanguageName() {
  CFArrayRef languages = CFLocaleCopyPreferredLanguages();
  CFIndex languages_length = CFArrayGetCount(languages);
  if (languages_length < 1) {
    CFRelease(languages);
    return nullptr;
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
  ASSERT(result != nullptr);
  bool success =
      CFStringGetCString(language, result, max_len, kCFStringEncodingUTF8);
  CFRelease(languages);
  if (!success) {
    return nullptr;
  }
  return result;
}

const char* Platform::LocaleName() {
  // First see if there is a preferred language. If not, return the
  // current locale name.
  const char* preferred_language = GetPreferredLanguageName();
  return (preferred_language != nullptr) ? preferred_language : GetLocaleName();
}

bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}

char** Platform::Environment(intptr_t* count) {
#if DART_HOST_OS_IOS
  // TODO(zra,chinmaygarde): On iOS, environment variables are seldom used. Wire
  // this up if someone needs it. In the meantime, we return an empty array.
  char** result;
  result = reinterpret_cast<char**>(Dart_ScopeAllocate(1 * sizeof(*result)));
  if (result == nullptr) {
    return nullptr;
  }
  result[0] = nullptr;
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
  while (*(tmp++) != nullptr) {
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
  if (_NSGetExecutablePath(nullptr, &path_size) == 0) {
    return nullptr;
  }
  // Allocate buffer and get executable path.
  char* path = DartUtils::ScopedCString(path_size);
  if (_NSGetExecutablePath(path, &path_size) != 0) {
    return nullptr;
  }
  // Return the canonical path as the returned path might contain symlinks.
  const char* canon_path = File::GetCanonicalPath(nullptr, path);
  return canon_path;
}

intptr_t Platform::ResolveExecutablePathInto(char* result, size_t result_size) {
  // Get the required length of the buffer.
  uint32_t path_size = 0;
  if (_NSGetExecutablePath(nullptr, &path_size) == 0) {
    return -1;
  }
  if (path_size > result_size) {
    return -1;
  }
  if (_NSGetExecutablePath(result, &path_size) != 0) {
    return -1;
  }
  return path_size;
}

void Platform::SetProcessName(const char* name) {
  pthread_setname_np(name);

#if !defined(DART_HOST_OS_IOS)
  // Attempt to set the name displayed in ActivityMonitor.
  // https://codereview.chromium.org/659007

  class ScopedDLHandle : public ValueObject {
   public:
    explicit ScopedDLHandle(void* handle) : handle_(handle) {}
    ~ScopedDLHandle() {
      if (handle_ != nullptr) dlclose(handle_);
    }
    void* get() { return handle_; }

   private:
    void* handle_;
    DISALLOW_COPY_AND_ASSIGN(ScopedDLHandle);
  };

  class ScopedCFStringRef : public ValueObject {
   public:
    explicit ScopedCFStringRef(const char* s)
        : ref_(CFStringCreateWithCString(nullptr, (s), kCFStringEncodingUTF8)) {
    }
    ~ScopedCFStringRef() {
      if (ref_ != nullptr) CFRelease(ref_);
    }
    CFStringRef get() { return ref_; }

   private:
    CFStringRef ref_;
    DISALLOW_COPY_AND_ASSIGN(ScopedCFStringRef);
  };

  ScopedDLHandle application_services_handle(
      dlopen("/System/Library/Frameworks/ApplicationServices.framework/"
             "Versions/A/ApplicationServices",
             RTLD_LAZY | RTLD_LOCAL));
  if (application_services_handle.get() == nullptr) return;

  ScopedCFStringRef launch_services_bundle_name("com.apple.LaunchServices");
  CFBundleRef launch_services_bundle =
      CFBundleGetBundleWithIdentifier(launch_services_bundle_name.get());
  if (launch_services_bundle == nullptr) return;

#define GET_FUNC(name, cstr)                                                   \
  ScopedCFStringRef name##_id(cstr);                                           \
  *reinterpret_cast<void**>(&name) = CFBundleGetFunctionPointerForName(        \
      launch_services_bundle, name##_id.get());                                \
  if (name == nullptr) return;

#define GET_DATA(name, cstr)                                                   \
  ScopedCFStringRef name##_id(cstr);                                           \
  *reinterpret_cast<void**>(&name) =                                           \
      CFBundleGetDataPointerForName(launch_services_bundle, name##_id.get());  \
  if (name == nullptr) return;

  CFTypeRef (*_LSGetCurrentApplicationASN)(void);
  GET_FUNC(_LSGetCurrentApplicationASN, "_LSGetCurrentApplicationASN");

  OSStatus (*_LSSetApplicationInformationItem)(int, CFTypeRef, CFStringRef,
                                               CFStringRef, CFDictionaryRef*);
  GET_FUNC(_LSSetApplicationInformationItem,
           "_LSSetApplicationInformationItem");

  CFDictionaryRef (*_LSApplicationCheckIn)(int, CFDictionaryRef);
  GET_FUNC(_LSApplicationCheckIn, "_LSApplicationCheckIn");

  void (*_LSSetApplicationLaunchServicesServerConnectionStatus)(uint64_t,
                                                                void*);
  GET_FUNC(_LSSetApplicationLaunchServicesServerConnectionStatus,
           "_LSSetApplicationLaunchServicesServerConnectionStatus");

  CFStringRef* _kLSDisplayNameKey;
  GET_DATA(_kLSDisplayNameKey, "_kLSDisplayNameKey");
  if (*_kLSDisplayNameKey == nullptr) return;

  _LSSetApplicationLaunchServicesServerConnectionStatus(0, nullptr);

  _LSApplicationCheckIn(-2, CFBundleGetInfoDictionary(CFBundleGetMainBundle()));

  CFTypeRef asn;
  asn = _LSGetCurrentApplicationASN();
  if (asn == nullptr) return;

  ScopedCFStringRef cf_name(name);
  _LSSetApplicationInformationItem(-2, asn, *_kLSDisplayNameKey, cf_name.get(),
                                   nullptr);
#undef GET_DATA
#undef GET_FUNC
#endif  // !defined(DART_HOST_OS_IOS)
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

#endif  // defined(DART_HOST_OS_MACOS)
