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


char** Platform::Environment(intptr_t* count) {
  char* strings = GetEnvironmentStrings();
  if (strings == NULL) return NULL;
  char* tmp = strings;
  intptr_t i = 0;
  while (*tmp != '\0') {
    i++;
    tmp += (strlen(tmp) + 1);
  }
  *count = i;
  char** result = new char*[i];
  tmp = strings;
  for (intptr_t current = 0; current < i; current++) {
    result[current] = StringUtils::SystemStringToUtf8(tmp);
    tmp += (strlen(tmp) + 1);
  }
  FreeEnvironmentStrings(strings);
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
