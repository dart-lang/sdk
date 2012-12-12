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
    result[current] = StringUtils::WideToUtf8(tmp);
    tmp += (wcslen(tmp) + 1);
  }
  FreeEnvironmentStringsW(strings);
  return result;
}


void Platform::FreeEnvironment(char** env, int count) {
  for (int i = 0; i < count; i++) free(env[i]);
  delete[] env;
}
