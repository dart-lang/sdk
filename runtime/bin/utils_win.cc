// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include <errno.h>  // NOLINT
#include <time.h>   // NOLINT

#include "bin/log.h"
#include "bin/utils.h"
#include "bin/utils_win.h"
#include "platform/assert.h"

namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length) {
  DWORD message_size = FormatMessageW(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL, code,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buffer, buffer_length, NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      Log::PrintErr("FormatMessage failed for error code %d (error %d)\n", code,
                    GetLastError());
    }
    _snwprintf(buffer, buffer_length, L"OS Error %d", code);
  }
  // Ensure string termination.
  buffer[buffer_length - 1] = 0;
}

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_code(GetLastError());

  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtilsWin::WideToUtf8(message);
  SetMessage(utf8);
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);

  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtilsWin::WideToUtf8(message);
  SetMessage(utf8);
}

char* StringUtils::ConsoleStringToUtf8(char* str,
                                       intptr_t len,
                                       intptr_t* result_len) {
  int wide_len = MultiByteToWideChar(CP_ACP, 0, str, len, NULL, 0);
  wchar_t* wide;
  wide =
      reinterpret_cast<wchar_t*>(Dart_ScopeAllocate(wide_len * sizeof(*wide)));
  MultiByteToWideChar(CP_ACP, 0, str, len, wide, wide_len);
  char* utf8 = StringUtilsWin::WideToUtf8(wide, wide_len, result_len);
  return utf8;
}

char* StringUtils::Utf8ToConsoleString(char* utf8,
                                       intptr_t len,
                                       intptr_t* result_len) {
  intptr_t wide_len;
  wchar_t* wide = StringUtilsWin::Utf8ToWide(utf8, len, &wide_len);
  int system_len =
      WideCharToMultiByte(CP_ACP, 0, wide, wide_len, NULL, 0, NULL, NULL);
  char* ansi;
  ansi =
      reinterpret_cast<char*>(Dart_ScopeAllocate(system_len * sizeof(*ansi)));
  if (ansi == NULL) {
    return NULL;
  }
  WideCharToMultiByte(CP_ACP, 0, wide, wide_len, ansi, system_len, NULL, NULL);
  if (result_len != NULL) {
    *result_len = system_len;
  }
  return ansi;
}

char* StringUtilsWin::WideToUtf8(wchar_t* wide,
                                 intptr_t len,
                                 intptr_t* result_len) {
  // If len is -1 then WideCharToMultiByte will include the terminating
  // NUL byte in the length.
  int utf8_len =
      WideCharToMultiByte(CP_UTF8, 0, wide, len, NULL, 0, NULL, NULL);
  char* utf8;
  utf8 = reinterpret_cast<char*>(Dart_ScopeAllocate(utf8_len * sizeof(*utf8)));
  WideCharToMultiByte(CP_UTF8, 0, wide, len, utf8, utf8_len, NULL, NULL);
  if (result_len != NULL) {
    *result_len = utf8_len;
  }
  return utf8;
}

wchar_t* StringUtilsWin::Utf8ToWide(char* utf8,
                                    intptr_t len,
                                    intptr_t* result_len) {
  // If len is -1 then MultiByteToWideChar will include the terminating
  // NUL byte in the length.
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, utf8, len, NULL, 0);
  wchar_t* wide;
  wide =
      reinterpret_cast<wchar_t*>(Dart_ScopeAllocate(wide_len * sizeof(*wide)));
  MultiByteToWideChar(CP_UTF8, 0, utf8, len, wide, wide_len);
  if (result_len != NULL) {
    *result_len = wide_len;
  }
  return wide;
}

const char* StringUtils::Utf8ToConsoleString(const char* utf8,
                                             intptr_t len,
                                             intptr_t* result_len) {
  return const_cast<const char*>(StringUtils::Utf8ToConsoleString(
      const_cast<char*>(utf8), len, result_len));
}

const char* StringUtils::ConsoleStringToUtf8(const char* str,
                                             intptr_t len,
                                             intptr_t* result_len) {
  return const_cast<const char*>(StringUtils::ConsoleStringToUtf8(
      const_cast<char*>(str), len, result_len));
}

const char* StringUtilsWin::WideToUtf8(const wchar_t* wide,
                                       intptr_t len,
                                       intptr_t* result_len) {
  return const_cast<const char*>(
      StringUtilsWin::WideToUtf8(const_cast<wchar_t*>(wide), len, result_len));
}

const wchar_t* StringUtilsWin::Utf8ToWide(const char* utf8,
                                          intptr_t len,
                                          intptr_t* result_len) {
  return const_cast<const wchar_t*>(
      StringUtilsWin::Utf8ToWide(const_cast<char*>(utf8), len, result_len));
}

char* StringUtils::StrNDup(const char* s, intptr_t n) {
  intptr_t len = strlen(s);
  if ((n < 0) || (len < 0)) {
    return NULL;
  }
  if (n < len) {
    len = n;
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  if (result == NULL) {
    return NULL;
  }
  result[len] = '\0';
  return reinterpret_cast<char*>(memmove(result, s, len));
}

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  wchar_t* command_line = GetCommandLineW();
  int unicode_argc;
  wchar_t** unicode_argv = CommandLineToArgvW(command_line, &unicode_argc);
  if (unicode_argv == NULL) {
    return false;
  }
  // The argc passed to main should have the same argc as we get here.
  ASSERT(argc == unicode_argc);
  if (argc < unicode_argc) {
    unicode_argc = argc;
  }
  for (int i = 0; i < unicode_argc; i++) {
    wchar_t* arg = unicode_argv[i];
    int arg_len = WideCharToMultiByte(CP_UTF8, 0, arg, -1, NULL, 0, NULL, NULL);
    char* utf8_arg = reinterpret_cast<char*>(malloc(arg_len));
    WideCharToMultiByte(CP_UTF8, 0, arg, -1, utf8_arg, arg_len, NULL, NULL);
    argv[i] = utf8_arg;
  }
  LocalFree(unicode_argv);
  return true;
}

// Although win32 uses 64-bit integers for representing timestamps,
// these are packed into a FILETIME structure. The FILETIME
// structure is just a struct representing a 64-bit integer. The
// TimeStamp union allows access to both a FILETIME and an integer
// representation of the timestamp. The Windows timestamp is in
// 100-nanosecond intervals since January 1, 1601.
union TimeStamp {
  FILETIME ft_;
  int64_t t_;
};

static int64_t GetCurrentTimeMicros() {
  static const int64_t kTimeEpoc = 116444736000000000LL;
  static const int64_t kTimeScaler = 10;  // 100 ns to us.

  TimeStamp time;
  GetSystemTimeAsFileTime(&time.ft_);
  return (time.t_ - kTimeEpoc) / kTimeScaler;
}

static int64_t qpc_ticks_per_second = 0;

void TimerUtils::InitOnce() {
  LARGE_INTEGER ticks_per_sec;
  if (!QueryPerformanceFrequency(&ticks_per_sec)) {
    qpc_ticks_per_second = 0;
  } else {
    qpc_ticks_per_second = static_cast<int64_t>(ticks_per_sec.QuadPart);
  }
}

int64_t TimerUtils::GetCurrentMonotonicMillis() {
  return GetCurrentMonotonicMicros() / 1000;
}

int64_t TimerUtils::GetCurrentMonotonicMicros() {
  if (qpc_ticks_per_second == 0) {
    // QueryPerformanceCounter not supported, fallback.
    return GetCurrentTimeMicros();
  }
  // Grab performance counter value.
  LARGE_INTEGER now;
  QueryPerformanceCounter(&now);
  int64_t qpc_value = static_cast<int64_t>(now.QuadPart);
  // Convert to microseconds.
  int64_t seconds = qpc_value / qpc_ticks_per_second;
  int64_t leftover_ticks = qpc_value - (seconds * qpc_ticks_per_second);
  int64_t result = seconds * kMicrosecondsPerSecond;
  result += ((leftover_ticks * kMicrosecondsPerSecond) / qpc_ticks_per_second);
  return result;
}

void TimerUtils::Sleep(int64_t millis) {
  ::Sleep(millis);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
