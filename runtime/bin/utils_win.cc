// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include <errno.h>  // NOLINT
#include <time.h>  // NOLINT

#include "bin/utils.h"
#include "bin/utils_win.h"
#include "bin/log.h"
#include "platform/assert.h"


namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length) {
  DWORD message_size =
      FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                     NULL,
                     code,
                     MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                     buffer,
                     buffer_length,
                     NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      Log::PrintErr("FormatMessage failed for error code %d (error %d)\n",
                    code,
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
  free(utf8);
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);

  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtilsWin::WideToUtf8(message);
  SetMessage(utf8);
  free(utf8);
}

char* StringUtils::ConsoleStringToUtf8(char* str,
                                       intptr_t len,
                                       intptr_t* result_len) {
  int wide_len = MultiByteToWideChar(CP_ACP, 0, str, len, NULL, 0);
  wchar_t* wide = new wchar_t[wide_len];
  MultiByteToWideChar(CP_ACP, 0, str, len, wide, wide_len);
  char* utf8 = StringUtilsWin::WideToUtf8(wide, wide_len, result_len);
  delete[] wide;
  return utf8;
}

char* StringUtils::Utf8ToConsoleString(char* utf8,
                                       intptr_t len,
                                       intptr_t* result_len) {
  intptr_t wide_len;
  wchar_t* wide = StringUtilsWin::Utf8ToWide(utf8, len, &wide_len);
  int system_len = WideCharToMultiByte(
      CP_ACP, 0, wide, wide_len, NULL, 0, NULL, NULL);
  char* ansi = reinterpret_cast<char*>(malloc(system_len));
  if (ansi == NULL) {
    free(wide);
    return NULL;
  }
  WideCharToMultiByte(CP_ACP, 0, wide, wide_len, ansi, system_len, NULL, NULL);
  free(wide);
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
  int utf8_len = WideCharToMultiByte(
      CP_UTF8, 0, wide, len, NULL, 0, NULL, NULL);
  char* utf8 = reinterpret_cast<char*>(malloc(utf8_len));
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
  wchar_t* wide =
      reinterpret_cast<wchar_t*>(malloc((wide_len) * sizeof(wchar_t)));
  MultiByteToWideChar(CP_UTF8, 0, utf8, len, wide, wide_len);
  if (result_len != NULL) {
    *result_len = wide_len;
  }
  return wide;
}

const char* StringUtils::Utf8ToConsoleString(
    const char* utf8, intptr_t len, intptr_t* result_len) {
  return const_cast<const char*>(
      StringUtils::Utf8ToConsoleString(
          const_cast<char*>(utf8), len, result_len));
}

const char* StringUtils::ConsoleStringToUtf8(
    const char* str, intptr_t len, intptr_t* result_len) {
  return const_cast<const char*>(
      StringUtils::ConsoleStringToUtf8(
          const_cast<char*>(str), len, result_len));
}

const char* StringUtilsWin::WideToUtf8(
    const wchar_t* wide, intptr_t len, intptr_t* result_len) {
  return const_cast<const char*>(
      StringUtilsWin::WideToUtf8(const_cast<wchar_t*>(wide), len, result_len));
}

const wchar_t* StringUtilsWin::Utf8ToWide(
    const char* utf8, intptr_t len, intptr_t* result_len) {
  return const_cast<const wchar_t*>(
      StringUtilsWin::Utf8ToWide(const_cast<char*>(utf8), len, result_len));
}

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  wchar_t* command_line = GetCommandLineW();
  int unicode_argc;
  wchar_t** unicode_argv = CommandLineToArgvW(command_line, &unicode_argc);
  if (unicode_argv == NULL) return false;
  // The argc passed to main should have the same argc as we get here.
  ASSERT(argc == unicode_argc);
  if (argc < unicode_argc) {
    unicode_argc = argc;
  }
  for (int i = 0; i < unicode_argc; i++) {
    wchar_t* arg = unicode_argv[i];
    argv[i] = StringUtilsWin::WideToUtf8(arg);
  }
  LocalFree(unicode_argv);
  return true;
}

int64_t TimerUtils::GetCurrentTimeMilliseconds() {
  return GetCurrentTimeMicros() / 1000;
}

int64_t TimerUtils::GetCurrentTimeMicros() {
  static const int64_t kTimeEpoc = 116444736000000000LL;
  static const int64_t kTimeScaler = 10;  // 100 ns to us.

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
  TimeStamp time;
  GetSystemTimeAsFileTime(&time.ft_);
  return (time.t_ - kTimeEpoc) / kTimeScaler;
}

void TimerUtils::Sleep(int64_t millis) {
  ::Sleep(millis);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
