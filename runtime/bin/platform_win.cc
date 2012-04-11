// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"
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
  static bool socketInitialized = false;
  if (!socketInitialized) {
    // Initialize Socket for gethostname.
    if (!Socket::Initialize()) return false;
    socketInitialized = true;
  }
  return gethostname(buffer, buffer_length) == 0;
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
      fprintf(stderr, "FormatMessage failed %d\n", GetLastError());
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
