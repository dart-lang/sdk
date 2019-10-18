// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/platform.h"

#include <crtdbg.h>

#include "bin/console.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "platform/syslog.h"
#if !defined(PLATFORM_DISABLE_SOCKET)
#include "bin/socket.h"
#endif
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/utils_win.h"


namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
char* Platform::resolved_executable_name_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

class PlatformWin {
 public:
  static void InitOnce() {
    // Set up a no-op handler so that CRT functions return an error instead of
    // hitting an assertion failure.
    // See: https://msdn.microsoft.com/en-us/library/a9yf33zb.aspx
    _set_invalid_parameter_handler(InvalidParameterHandler);
    // Disable the message box for assertions in the CRT in Debug builds.
    // See: https://msdn.microsoft.com/en-us/library/1y71x448.aspx
    _CrtSetReportMode(_CRT_ASSERT, 0);

    // Disable dialog boxes for "critical" errors or when OpenFile cannot find
    // the requested file. However only disable error boxes for general
    // protection faults if an environment variable is set. Passing
    // SEM_NOGPFAULTERRORBOX completely disables WindowsErrorReporting (WER)
    // for the process, which means users loose ability to enable local dump
    // archiving to collect minidumps for Dart VM crashes.
    // Our test runner would set DART_SUPPRESS_WER to suppress WER UI during
    // test suite execution.
    // See: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680621(v=vs.85).aspx
    UINT uMode = SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX;
    if (getenv("DART_SUPPRESS_WER") != nullptr) {
      uMode |= SEM_NOGPFAULTERRORBOX;
    }
    SetErrorMode(uMode);
#ifndef PRODUCT
    // Set up global exception handler to be able to dump stack trace on crash.
    SetExceptionHandler();
#endif
  }

  // Windows top-level unhandled exception handler function.
  // See MSDN documentation for UnhandledExceptionFilter.
  // https://msdn.microsoft.com/en-us/library/windows/desktop/ms681401(v=vs.85).aspx
  static LONG WINAPI
  DartExceptionHandler(struct _EXCEPTION_POINTERS* ExceptionInfo) {
    if ((ExceptionInfo->ExceptionRecord->ExceptionCode ==
         EXCEPTION_ACCESS_VIOLATION) ||
        (ExceptionInfo->ExceptionRecord->ExceptionCode ==
         EXCEPTION_ILLEGAL_INSTRUCTION)) {
      Syslog::PrintErr(
          "\n===== CRASH =====\n"
          "ExceptionCode=%d, ExceptionFlags=%d, ExceptionAddress=%p\n",
          ExceptionInfo->ExceptionRecord->ExceptionCode,
          ExceptionInfo->ExceptionRecord->ExceptionFlags,
          ExceptionInfo->ExceptionRecord->ExceptionAddress);
      Dart_DumpNativeStackTrace(ExceptionInfo->ContextRecord);
      Console::RestoreConfig();
      // Note: we want to abort(...) here instead of exiting because exiting
      // would not cause WER to generate a minidump.
      Dart_PrepareToAbort();
      abort();
    }
    return EXCEPTION_CONTINUE_SEARCH;
  }

  static void SetExceptionHandler() {
    SetUnhandledExceptionFilter(DartExceptionHandler);
  }

 private:
  static void InvalidParameterHandler(const wchar_t* expression,
                                      const wchar_t* function,
                                      const wchar_t* file,
                                      unsigned int line,
                                      uintptr_t reserved) {
    // Doing nothing here means that the CRT call that invoked it will
    // return an error code and/or set errno.
  }

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(PlatformWin);
};

bool Platform::Initialize() {
  PlatformWin::InitOnce();
  return true;
}

int Platform::NumberOfProcessors() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  return info.dwNumberOfProcessors;
}

const char* Platform::OperatingSystem() {
  return "windows";
}

// We pull the version number, and other version information out of the
// registry because GetVersionEx() and friends lie about the OS version after
// Windows 8.1. See:
// https://msdn.microsoft.com/en-us/library/windows/desktop/ms724451(v=vs.85).aspx
static const wchar_t* kCurrentVersion =
    L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";

static bool GetCurrentVersionDWord(const wchar_t* field, DWORD* value) {
  DWORD value_size = sizeof(*value);
  LONG err = RegGetValue(HKEY_LOCAL_MACHINE, kCurrentVersion, field,
                         RRF_RT_REG_DWORD, NULL, value, &value_size);
  return err == ERROR_SUCCESS;
}

static bool GetCurrentVersionString(const wchar_t* field, const char** value) {
  wchar_t wversion[256];
  DWORD wversion_size = sizeof(wversion);
  LONG err = RegGetValue(HKEY_LOCAL_MACHINE, kCurrentVersion, field,
                         RRF_RT_REG_SZ, NULL, wversion, &wversion_size);
  if (err != ERROR_SUCCESS) {
    return false;
  }
  *value = StringUtilsWin::WideToUtf8(wversion);
  return true;
}

static const char* VersionNumber() {
  // Try to get CurrentMajorVersionNumber. If that fails, fall back on
  // CurrentVersion. If it succeeds also get CurrentMinorVersionNumber.
  DWORD major;
  if (!GetCurrentVersionDWord(L"CurrentMajorVersionNumber", &major)) {
    const char* version;
    if (!GetCurrentVersionString(L"CurrentVersion", &version)) {
      return NULL;
    }
    return version;
  }

  DWORD minor;
  if (!GetCurrentVersionDWord(L"CurrentMinorVersionNumber", &minor)) {
    return NULL;
  }
  const char* kFormat = "%d.%d";
  int len = snprintf(NULL, 0, kFormat, major, minor);
  if (len < 0) {
    return NULL;
  }
  char* result = DartUtils::ScopedCString(len + 1);
  ASSERT(result != NULL);
  len = snprintf(result, len + 1, kFormat, major, minor);
  if (len < 0) {
    return NULL;
  }
  return result;
}

const char* Platform::OperatingSystemVersion() {
  // Get the product name, e.g. "Windows 10 Home".
  const char* name;
  if (!GetCurrentVersionString(L"ProductName", &name)) {
    return NULL;
  }

  // Get the version number, e.g. "10.0".
  const char* version_number = VersionNumber();
  if (version_number == NULL) {
    return NULL;
  }

  // Get the build number.
  const char* build;
  if (!GetCurrentVersionString(L"CurrentBuild", &build)) {
    return NULL;
  }

  // Put it all together.
  const char* kFormat = "\"%s\" %s (Build %s)";
  int len = snprintf(NULL, 0, kFormat, name, version_number, build);
  char* result = DartUtils::ScopedCString(len + 1);
  len = snprintf(result, len + 1, kFormat, name, version_number, build);
  return result;
}

const char* Platform::LibraryPrefix() {
  return "";
}

const char* Platform::LibraryExtension() {
  return "dll";
}

const char* Platform::LocaleName() {
  wchar_t locale_name[LOCALE_NAME_MAX_LENGTH];
  int result = GetUserDefaultLocaleName(locale_name, LOCALE_NAME_MAX_LENGTH);
  if (result == 0) {
    return NULL;
  }
  return StringUtilsWin::WideToUtf8(locale_name);
}

bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
#if defined(PLATFORM_DISABLE_SOCKET)
  return false;
#else
  if (!SocketBase::Initialize()) {
    return false;
  }
  return gethostname(buffer, buffer_length) == 0;
#endif
}

char** Platform::Environment(intptr_t* count) {
  wchar_t* strings = GetEnvironmentStringsW();
  if (strings == NULL) {
    return NULL;
  }
  wchar_t* tmp = strings;
  intptr_t i = 0;
  while (*tmp != '\0') {
    // Skip environment strings starting with "=".
    // These are synthetic variables corresponding to dynamic environment
    // variables like %=C:% and %=ExitCode%, and the Dart environment does
    // not include these.
    if (*tmp != '=') {
      i++;
    }
    tmp += (wcslen(tmp) + 1);
  }
  *count = i;
  char** result;
  result = reinterpret_cast<char**>(Dart_ScopeAllocate(i * sizeof(*result)));
  tmp = strings;
  for (intptr_t current = 0; current < i;) {
    // Skip the strings that were not counted above.
    if (*tmp != '=') {
      result[current++] = StringUtilsWin::WideToUtf8(tmp);
    }
    tmp += (wcslen(tmp) + 1);
  }
  FreeEnvironmentStringsW(strings);
  return result;
}

const char* Platform::GetExecutableName() {
  return executable_name_;
}

const char* Platform::ResolveExecutablePath() {
  // GetModuleFileNameW cannot directly provide information on the
  // required buffer size, so start out with a buffer large enough to
  // hold any Windows path.
  const int kTmpBufferSize = 32768;
  wchar_t* tmp_buffer =
      reinterpret_cast<wchar_t*>(Dart_ScopeAllocate(kTmpBufferSize));
  // Ensure no last error before calling GetModuleFileNameW.
  SetLastError(ERROR_SUCCESS);
  // Get the required length of the buffer.
  GetModuleFileNameW(nullptr, tmp_buffer, kTmpBufferSize);
  if (GetLastError() != ERROR_SUCCESS) {
    return NULL;
  }
  char* path = StringUtilsWin::WideToUtf8(tmp_buffer);
  // Return the canonical path as the returned path might contain symlinks.
  const char* canon_path = File::GetCanonicalPath(NULL, path);
  return canon_path;
}

intptr_t Platform::ResolveExecutablePathInto(char* result, size_t result_size) {
  // Ensure no last error before calling GetModuleFileNameW.
  SetLastError(ERROR_SUCCESS);
  const int kTmpBufferSize = 32768;
  wchar_t tmp_buffer[kTmpBufferSize];
  // Get the required length of the buffer.
  GetModuleFileNameW(nullptr, tmp_buffer, kTmpBufferSize);
  if (GetLastError() != ERROR_SUCCESS) {
    return -1;
  }
  WideToUtf8Scope wide_to_utf8_scope(tmp_buffer);
  if (wide_to_utf8_scope.length() <= result_size) {
    strncpy(result, wide_to_utf8_scope.utf8(), result_size);
    return wide_to_utf8_scope.length();
  }
  return -1;
}

void Platform::Exit(int exit_code) {
  // Restore the console's output code page
  Console::RestoreConfig();
  // On Windows we use ExitProcess so that threads can't clobber the exit_code.
  // See: https://code.google.com/p/nativeclient/issues/detail?id=2870
  Dart_PrepareToAbort();
  ::ExitProcess(exit_code);
}

void Platform::SetCoreDumpResourceLimit(int value) {
  // Not supported.
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
