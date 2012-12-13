// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>

#include "bin/utils.h"
#include "bin/log.h"

static void FormatMessageIntoBuffer(DWORD code,
                                    wchar_t* buffer,
                                    int buffer_length) {
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
      Log::PrintErr("FormatMessage failed %d\n", GetLastError());
    }
    _snwprintf(buffer, buffer_length, L"OS Error %d", code);
  }
  buffer[buffer_length - 1] = '\0';
}


OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_code(GetLastError());

  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtils::WideToUtf8(message);
  SetMessage(utf8);
  free(utf8);
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);

  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  char* utf8 = StringUtils::WideToUtf8(message);
  SetMessage(utf8);
  free(utf8);
}

char* StringUtils::ConsoleStringToUtf8(char* str) {
  int len = MultiByteToWideChar(CP_ACP, 0, str, -1, NULL, 0);
  wchar_t* unicode = new wchar_t[len+1];
  MultiByteToWideChar(CP_ACP, 0, str, -1, unicode, len);
  unicode[len] = '\0';
  char* utf8 = StringUtils::WideToUtf8(unicode);
  delete[] unicode;
  return utf8;
}

char* StringUtils::Utf8ToConsoleString(char* utf8) {
  wchar_t* unicode = Utf8ToWide(utf8);
  int len = WideCharToMultiByte(CP_ACP, 0, unicode, -1, NULL, 0, NULL, NULL);
  char* ansi = reinterpret_cast<char*>(malloc(len + 1));
  WideCharToMultiByte(CP_ACP, 0, unicode, -1, ansi, len, NULL, NULL);
  ansi[len] = '\0';
  free(unicode);
  return ansi;
}

char* StringUtils::WideToUtf8(wchar_t* wide) {
  int len = WideCharToMultiByte(CP_UTF8, 0, wide, -1, NULL, 0, NULL, NULL);
  char* utf8 = reinterpret_cast<char*>(malloc(len + 1));
  WideCharToMultiByte(CP_UTF8, 0, wide, -1, utf8, len, NULL, NULL);
  utf8[len] = '\0';
  return utf8;
}


wchar_t* StringUtils::Utf8ToWide(char* utf8) {
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
  wchar_t* unicode =
      reinterpret_cast<wchar_t*>(malloc((len + 1) * sizeof(wchar_t)));
  MultiByteToWideChar(CP_UTF8, 0, utf8, -1, unicode, len);
  unicode[len] = '\0';
  return unicode;
}

const char* StringUtils::Utf8ToConsoleString(const char* utf8) {
  return const_cast<const char*>(Utf8ToConsoleString(const_cast<char*>(utf8)));
}

const char* StringUtils::ConsoleStringToUtf8(const char* str) {
  return const_cast<const char*>(ConsoleStringToUtf8(const_cast<char*>(str)));
}

const char* StringUtils::WideToUtf8(const wchar_t* wide) {
  return const_cast<const char*>(WideToUtf8(const_cast<wchar_t*>(wide)));
}

const wchar_t* StringUtils::Utf8ToWide(const char* utf8) {
  return const_cast<const wchar_t*>(Utf8ToWide(const_cast<char*>(utf8)));
}

wchar_t** ShellUtils::GetUnicodeArgv(int* argc) {
  wchar_t* command_line = GetCommandLineW();
  return CommandLineToArgvW(command_line, argc);
}

void ShellUtils::FreeUnicodeArgv(wchar_t** argv) {
  LocalFree(argv);
}
