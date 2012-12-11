// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"
#include "bin/log.h"
#include "bin/socket.h"

bool Platform::Initialize() {
  // Nothing to do on Windows.
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


bool Platform::LocalHostname(char *buffer, intptr_t buffer_length) {
  static bool socket_initialized = false;
  if (!socket_initialized) {
    // Initialize Socket for gethostname.
    if (!Socket::Initialize()) return false;
    socket_initialized = true;
  }
  return gethostname(buffer, buffer_length) == 0;
}


static char* WideToUtf8(wchar_t* wide) {
  int len = WideCharToMultiByte(CP_UTF8, 0, wide, -1, NULL, 0, NULL, NULL);
  char* utf8 = reinterpret_cast<char*>(malloc(len + 1));
  WideCharToMultiByte(CP_UTF8, 0, wide, -1, utf8, len, NULL, NULL);
  utf8[len] = '\0';
  return utf8;
}


char** Platform::Environment(intptr_t* count) {
  wchar_t* strings = GetEnvironmentStringsW();
  if (strings == NULL) return NULL;
  wchar_t* tmp = strings;
  intptr_t i = 0;
  while (*tmp != '\0') {
    i++;
    tmp += (wcslen(tmp) + 1);
  }
  *count = i;
  char** result = new char*[i];
  tmp = strings;
  for (intptr_t current = 0; current < i; current++) {
    result[current] = WideToUtf8(tmp);
    tmp += (wcslen(tmp) + 1);
  }
  FreeEnvironmentStringsW(strings);
  return result;
}


void Platform::FreeEnvironment(char** env, int count) {
  for (int i = 0; i < count; i++) free(env[i]);
  delete[] env;
}


char* Platform::StrError(int error_code) {
  static const int kBufferSize = 1024;
  char* error = static_cast<char*>(malloc(kBufferSize));
  DWORD message_size =
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    error_code,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    error,
                    kBufferSize,
                    NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      Log::PrintErr("FormatMessage failed %d\n", GetLastError());
    }
    snprintf(error, kBufferSize, "OS Error %d", error_code);
  }
  // Strip out \r\n at the end of the generated message and ensure
  // null termination.
  if (message_size > 2 &&
      error[message_size - 2] == '\r' &&
      error[message_size - 1] == '\n') {
    error[message_size - 2] = '\0';
  } else {
    error[kBufferSize - 1] = '\0';
  }
  return error;
}
