// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>

#include "bin/utils.h"

static void FormatMessageIntoBuffer(DWORD code,
                                    char* buffer,
                                    int buffer_length) {
  DWORD message_size =
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    code,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    buffer,
                    buffer_length,
                    NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      fprintf(stderr, "FormatMessage failed %d\n", GetLastError());
    }
    snprintf(buffer, buffer_length, "OS Error %d", code);
  }
  buffer[buffer_length - 1] = '\0';
}


OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_code(GetLastError());

  static const int kMaxMessageLength = 256;
  char message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  SetMessage(message);
}

void OSError::SetCodeAndMessage(SubSystem sub_system, int code) {
  set_sub_system(sub_system);
  set_code(code);

  static const int kMaxMessageLength = 256;
  char message[kMaxMessageLength];
  FormatMessageIntoBuffer(code_, message, kMaxMessageLength);
  SetMessage(message);
}

char* StringUtils::SystemStringToUtf8(char* str) {
  int len = MultiByteToWideChar(CP_ACP, 0, str, -1, NULL, 0);
  wchar_t* unicode = new wchar_t[len+1];
  MultiByteToWideChar(CP_ACP, 0, str, -1, unicode, len);
  unicode[len] = '\0';
  len = WideCharToMultiByte(CP_UTF8, 0, unicode, -1, NULL, 0, NULL, NULL);
  char* utf8 = reinterpret_cast<char*>(malloc(len+1));
  WideCharToMultiByte(CP_UTF8, 0, unicode, -1, utf8, len, NULL, NULL);
  utf8[len] = '\0';
  delete[] unicode;
  return utf8;
}

char* StringUtils::Utf8ToSystemString(char* utf8) {
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
  wchar_t* unicode = new wchar_t[len+1];
  MultiByteToWideChar(CP_UTF8, 0, utf8, -1, unicode, len);
  unicode[len] = '\0';
  len = WideCharToMultiByte(CP_ACP, 0, unicode, -1, NULL, 0, NULL, NULL);
  char* ansi = reinterpret_cast<char*>(malloc(len+1));
  WideCharToMultiByte(CP_ACP, 0, unicode, -1, ansi, len, NULL, NULL);
  ansi[len] = '\0';
  delete[] unicode;
  return ansi;
}

const char* StringUtils::Utf8ToSystemString(const char* utf8) {
  return const_cast<const char*>(Utf8ToSystemString(const_cast<char*>(utf8)));
}

const char* StringUtils::SystemStringToUtf8(const char* str) {
  return const_cast<const char*>(Utf8ToSystemString(const_cast<char*>(str)));
}
