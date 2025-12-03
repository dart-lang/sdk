// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include <errno.h>  // NOLINT
#include <time.h>   // NOLINT
#include <memory>
#include <sstream>

#include "bin/utils.h"
#include "bin/utils_win.h"
#include "platform/assert.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

// The offset between a `FILETIME` epoch (January 1, 1601 UTC) and a Unix
// epoch (January 1, 1970 UTC) measured in 100ns intervals.
//
// See https://docs.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
static constexpr int64_t kFileTimeEpoch = 116444736000000000LL;

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

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length) {
  DWORD message_size =
      FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                     nullptr, code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                     buffer, buffer_length, nullptr);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      Syslog::PrintErr("FormatMessage failed for error code %d (error %d)\n",
                       code, GetLastError());
    }
    _snwprintf(buffer, buffer_length, L"OS Error %d", code);
    return;
  }

  // Strip trailing whitespace and a dot.
  while (message_size > 0 && iswspace(buffer[message_size - 1])) {
    message_size--;
  }
  if (message_size > 0 && buffer[message_size - 1] == L'.') {
    message_size--;
  }
  buffer[Utils::Minimum<int>(message_size, buffer_length - 1)] = 0;
}

FILETIME GetFiletimeFromMillis(int64_t millis) {
  const int64_t kTimeScaler = 10000;  // 100 ns to ms.
  TimeStamp t;
  t.t_ = millis * kTimeScaler + kFileTimeEpoch;
  return t.ft_;
}

OSError::OSError() : sub_system_(kSystem), code_(0), message_(nullptr) {
  Reload();
}

void OSError::Reload() {
  SetCodeAndMessage(kSystem, GetLastError());
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);

  const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtilsWin::WideToUtf8(message);
  SetMessage(utf8);
}

char* StringUtils::ConsoleStringToUtf8(char* str,
                                       intptr_t len,
                                       intptr_t* result_len) {
  int wide_len = MultiByteToWideChar(CP_ACP, 0, str, len, nullptr, 0);
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
  int system_len = WideCharToMultiByte(CP_ACP, 0, wide, wide_len, nullptr, 0,
                                       nullptr, nullptr);
  char* ansi;
  ansi =
      reinterpret_cast<char*>(Dart_ScopeAllocate(system_len * sizeof(*ansi)));
  if (ansi == nullptr) {
    return nullptr;
  }
  WideCharToMultiByte(CP_ACP, 0, wide, wide_len, ansi, system_len, nullptr,
                      nullptr);
  if (result_len != nullptr) {
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
      WideCharToMultiByte(CP_UTF8, 0, wide, len, nullptr, 0, nullptr, nullptr);
  char* utf8;
  utf8 = reinterpret_cast<char*>(Dart_ScopeAllocate(utf8_len * sizeof(*utf8)));
  WideCharToMultiByte(CP_UTF8, 0, wide, len, utf8, utf8_len, nullptr, nullptr);
  if (result_len != nullptr) {
    *result_len = utf8_len;
  }
  return utf8;
}

void StringUtilsWin::WideToUtf8(const wchar_t* wide, char** utf8) {
  // The parameter -1 ensures WideCharToMultiByte will include the terminating
  // NUL byte in the length.
  intptr_t len = -1;
  int utf8_len =
      WideCharToMultiByte(CP_UTF8, 0, wide, len, nullptr, 0, nullptr, nullptr);
  *utf8 = reinterpret_cast<char*>(malloc(utf8_len * sizeof(*utf8)));
  WideCharToMultiByte(CP_UTF8, 0, wide, len, *utf8, utf8_len, nullptr, nullptr);
}

wchar_t* StringUtilsWin::Utf8ToWide(char* utf8,
                                    intptr_t len,
                                    intptr_t* result_len) {
  // If len is -1 then MultiByteToWideChar will include the terminating
  // NUL byte in the length.
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, utf8, len, nullptr, 0);
  wchar_t* wide;
  wide =
      reinterpret_cast<wchar_t*>(Dart_ScopeAllocate(wide_len * sizeof(*wide)));
  MultiByteToWideChar(CP_UTF8, 0, utf8, len, wide, wide_len);
  if (result_len != nullptr) {
    *result_len = wide_len;
  }
  return wide;
}

void StringUtilsWin::Utf8ToWide(const char* utf8, wchar_t** wide) {
  // The parameter -1 ensures MultiByteToWideChar will include the terminating
  // NUL byte in the length.
  intptr_t len = -1;
  intptr_t wide_len = MultiByteToWideChar(CP_UTF8, 0, utf8, len, nullptr, 0);
  *wide = reinterpret_cast<wchar_t*>(malloc(wide_len * sizeof(*wide)));
  MultiByteToWideChar(CP_UTF8, 0, utf8, len, *wide, wide_len);
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

// This code is identical to the one in process_patch.dart, please ensure
// changes made here are also done in process_patch.dart.
char* StringUtilsWin::ArgumentEscape(const char* argument) {
  std::string arg_str(argument);
  if (arg_str.empty()) {
    return Utils::StrDup(R"("")");
  }
  std::string result_str = arg_str;
  if (arg_str.find('\t') != std::string::npos ||
      arg_str.find(' ') != std::string::npos ||
      arg_str.find('"') != std::string::npos) {
    // Produce something that the C runtime on Windows will parse
    // back as this string.

    // Replace any number of '\' followed by '"' with
    // twice as many '\' followed by '\"'.
    char backslash = '\\';
    std::stringstream sb;
    size_t nextPos = 0;
    size_t quotePos = arg_str.find('"', nextPos);

    while (quotePos != std::string::npos) {
      size_t numBackslash = 0;
      size_t pos = quotePos - 1;
      while (pos != std::string::npos && arg_str[pos] == backslash) {
        numBackslash++;
        pos--;
      }
      sb << arg_str.substr(nextPos, quotePos - numBackslash - nextPos);
      for (size_t i = 0; i < numBackslash; i++) {
        sb << R"(\\)";
      }
      sb << R"(\")";
      nextPos = quotePos + 1;
      quotePos = arg_str.find('"', nextPos);
    }
    sb << arg_str.substr(nextPos);
    result_str = sb.str();

    // Add '"' at the beginning and end and replace all '\' at
    // the end with two '\'.
    std::stringstream sb2;
    sb2 << '"';
    sb2 << result_str;

    // Find the last non-backslash character to determine the actual end
    // of the string
    size_t lastCharPos = arg_str.length() - 1;
    while (lastCharPos != std::string::npos &&
           arg_str[lastCharPos] == backslash) {
      sb2 << '\\';
      lastCharPos--;
    }
    sb2 << '"';
    result_str = sb2.str();
  }
  // Allocate memory for the C-style string and copy the content
  intptr_t len = result_str.length() + 1;
  char* c_str_result = static_cast<char*>(malloc(len * sizeof(char)));
  if (c_str_result == nullptr) return nullptr;  // Allocation failure.
  snprintf(c_str_result, len * sizeof(char), "%s", result_str.c_str());
  return c_str_result;
}

bool ShellUtils::GetUtf8Argv(int argc, char** argv) {
  wchar_t* command_line = GetCommandLineW();
  int unicode_argc;
  wchar_t** unicode_argv = CommandLineToArgvW(command_line, &unicode_argc);
  if (unicode_argv == nullptr) {
    return false;
  }
  // The argc passed to main should have the same argc as we get here.
  ASSERT(argc == unicode_argc);
  if (argc < unicode_argc) {
    unicode_argc = argc;
  }
  for (int i = 0; i < unicode_argc; i++) {
    wchar_t* arg = unicode_argv[i];
    int arg_len =
        WideCharToMultiByte(CP_UTF8, 0, arg, -1, nullptr, 0, nullptr, nullptr);
    char* utf8_arg = reinterpret_cast<char*>(malloc(arg_len));
    WideCharToMultiByte(CP_UTF8, 0, arg, -1, utf8_arg, arg_len, nullptr,
                        nullptr);
    argv[i] = utf8_arg;
  }
  LocalFree(unicode_argv);
  return true;
}

static int64_t GetCurrentTimeMicros() {
  const int64_t kTimeScaler = 10;  // 100 ns to us.

  TimeStamp time;
  GetSystemTimeAsFileTime(&time.ft_);
  return (time.t_ - kFileTimeEpoch) / kTimeScaler;
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

std::unique_ptr<wchar_t[]> Utf8ToWideChar(const char* path) {
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, path, -1, nullptr, 0);
  auto result = std::make_unique<wchar_t[]>(wide_len);
  MultiByteToWideChar(CP_UTF8, 0, path, -1, result.get(), wide_len);
  return result;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
