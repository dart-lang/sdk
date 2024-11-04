// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/platform.h"

#include <comdef.h>
#include <crtdbg.h>
#include <wbemidl.h>
#include <wrl/client.h>
#undef interface
#include <string>

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

#pragma comment(lib, "wbemuuid.lib")

using Microsoft::WRL::ComPtr;

namespace dart {
namespace bin {

const char* Platform::executable_name_ = nullptr;
int Platform::script_index_ = 1;
char** Platform::argv_ = nullptr;

class PlatformWin {
 public:
  static void InitOnce() {
    // Set up a no-op handler so that CRT functions return an error instead of
    // hitting an assertion failure.
    // See: https://msdn.microsoft.com/en-us/library/a9yf33zb.aspx
    _set_invalid_parameter_handler(InvalidParameterHandler);
    // Ensure no dialog boxes for assertions, errors and warnings in the CRT
    // in Debug builds.
    // See: https://msdn.microsoft.com/en-us/library/1y71x448.aspx
    _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);

    // Set location where the C runtime writes an error message for an error
    // that might end the program.
    _set_error_mode(_OUT_TO_STDERR);

    // Disable dialog boxes for "critical" errors or when OpenFile cannot find
    // the requested file. However only disable error boxes for general
    // protection faults if an environment variable is set. Passing
    // SEM_NOGPFAULTERRORBOX completely disables WindowsErrorReporting (WER)
    // for the process, which means users loose ability to enable local dump
    // archiving to collect minidumps for Dart VM crashes.
    // Our test runner would set DART_SUPPRESS_WER to suppress WER UI during
    // test suite execution.
    // See: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680621(v=vs.85).aspx
    UINT new_mode = SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX;
    if (getenv("DART_SUPPRESS_WER") != nullptr) {
      new_mode |= SEM_NOGPFAULTERRORBOX;
    }
    UINT existing_mode = SetErrorMode(new_mode);
    SetErrorMode(new_mode | existing_mode);
    // Set up global exception handler to be able to dump stack trace on crash.
    SetExceptionHandler();
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

class CoInitializeScope : public ValueObject {
 public:
  CoInitializeScope() { hres = CoInitializeEx(0, COINIT_MULTITHREADED); }

  ~CoInitializeScope() { CoUninitialize(); }

  bool IsInitialized() const { return !FAILED(hres); }

 private:
  HRESULT hres;
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

// We pull the version number, and other version information out of the
// registry because GetVersionEx() and friends lie about the OS version after
// Windows 8.1. See:
// https://msdn.microsoft.com/en-us/library/windows/desktop/ms724451(v=vs.85).aspx
static constexpr const wchar_t* kCurrentVersion =
    L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";

static bool GetCurrentVersionDWord(const wchar_t* field, DWORD* value) {
  DWORD value_size = sizeof(*value);
  LONG err = RegGetValue(HKEY_LOCAL_MACHINE, kCurrentVersion, field,
                         RRF_RT_REG_DWORD, nullptr, value, &value_size);
  return err == ERROR_SUCCESS;
}

static bool GetCurrentVersionString(const wchar_t* field, const char** value) {
  wchar_t wversion[256];
  DWORD wversion_size = sizeof(wversion);
  LONG err = RegGetValue(HKEY_LOCAL_MACHINE, kCurrentVersion, field,
                         RRF_RT_REG_SZ, nullptr, wversion, &wversion_size);
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
      return nullptr;
    }
    return version;
  }

  DWORD minor;
  if (!GetCurrentVersionDWord(L"CurrentMinorVersionNumber", &minor)) {
    return nullptr;
  }
  return DartUtils::ScopedCStringFormatted("%d.%d", major, minor);
}

static const char* GetEdition() {
  HRESULT hres;

  CoInitializeScope co_initialize_scope;
  if (!co_initialize_scope.IsInitialized()) {
    return nullptr;
  }

  hres = CoInitializeSecurity(
      nullptr, -1, nullptr, nullptr, RPC_C_AUTHN_LEVEL_DEFAULT,
      RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE, nullptr);
  if (FAILED(hres)) {
    return nullptr;
  }

  ComPtr<IWbemLocator> locator;
  hres = CoCreateInstance(CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER,
                          IID_PPV_ARGS(&locator));
  if (FAILED(hres)) {
    return nullptr;
  }

  ComPtr<IWbemServices> service;
  hres = locator->ConnectServer(_bstr_t(L"ROOT\\CIMV2"), nullptr, nullptr, 0,
                                NULL, 0, 0, &service);
  if (FAILED(hres)) {
    return nullptr;
  }

  hres = CoSetProxyBlanket(service.Get(), RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE,
                           nullptr, RPC_C_AUTHN_LEVEL_CALL,
                           RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE);
  if (FAILED(hres)) {
    return nullptr;
  }

  ComPtr<IEnumWbemClassObject> enumerator;
  hres = service->ExecQuery(
      bstr_t("WQL"), bstr_t("SELECT * FROM Win32_OperatingSystem"),
      WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, nullptr,
      &enumerator);
  if (FAILED(hres)) {
    return nullptr;
  }

  ComPtr<IWbemClassObject> query_results;
  ULONG uReturn = 0;
  if (FAILED(hres) || enumerator == nullptr) {
    return nullptr;
  }

  hres = enumerator->Next(WBEM_INFINITE, 1, &query_results, &uReturn);
  if (FAILED(hres)) {
    return nullptr;
  }

  VARIANT caption;
  hres = query_results->Get(L"Caption", 0, &caption, 0, 0);
  if (FAILED(hres)) {
    return nullptr;
  }

  // We got an edition, skip Microsoft prefix and convert to UTF8.
  wchar_t* edition = caption.bstrVal;
  static const wchar_t kMicrosoftPrefix[] = L"Microsoft ";
  static constexpr size_t kMicrosoftPrefixLen =
      ARRAY_SIZE(kMicrosoftPrefix) - 1;
  if (wcsncmp(edition, kMicrosoftPrefix, kMicrosoftPrefixLen) == 0) {
    edition += kMicrosoftPrefixLen;
  }

  char* result = StringUtilsWin::WideToUtf8(edition);
  VariantClear(&caption);
  return result;
}

const char* Platform::OperatingSystemVersion() {
  // Get the product name, e.g. "Windows 11 Home" via WMI and fallback to the
  // ProductName on error.
  const char* name = GetEdition();
  if (name == nullptr && !GetCurrentVersionString(L"ProductName", &name)) {
    return nullptr;
  }

  // Get the version number, e.g. "10.0".
  const char* version_number = VersionNumber();
  if (version_number == nullptr) {
    return nullptr;
  }

  // Get the build number.
  const char* build;
  if (!GetCurrentVersionString(L"CurrentBuild", &build)) {
    return nullptr;
  }

  // Put it all together.
  const char* kFormat = "\"%s\" %s (Build %s)";
  int len = snprintf(nullptr, 0, kFormat, name, version_number, build);
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
    return nullptr;
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
  // 256 is max length per https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-gethostnamew#remarks
  const int HOSTNAME_MAXLENGTH = 256;
  wchar_t hostname_w[HOSTNAME_MAXLENGTH];
  if (GetHostNameW(hostname_w, HOSTNAME_MAXLENGTH) != 0) {
    return false;
  }
  return WideCharToMultiByte(CP_UTF8, 0, hostname_w, -1, buffer, buffer_length,
                             nullptr, nullptr) != 0;
#endif
}

char** Platform::Environment(intptr_t* count) {
  wchar_t* strings = GetEnvironmentStringsW();
  if (strings == nullptr) {
    return nullptr;
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
    return nullptr;
  }
  char* path = StringUtilsWin::WideToUtf8(tmp_buffer);
  // Return the canonical path as the returned path might contain symlinks.
  const char* canon_path = File::GetCanonicalPath(nullptr, path);
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

void Platform::SetProcessName(const char* name) {}

void Platform::Exit(int exit_code) {
  // Restore the console's output code page
  Console::RestoreConfig();
  // On Windows we use ExitProcess so that threads can't clobber the exit_code.
  // See: https://code.google.com/p/nativeclient/issues/detail?id=2870
  Dart_PrepareToAbort();
  ::ExitProcess(exit_code);
}

void Platform::_Exit(int exit_code) {
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

#endif  // defined(DART_HOST_OS_WINDOWS)
