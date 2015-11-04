// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/file.h"
#include "bin/platform.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/utils.h"
#include "bin/utils_win.h"


namespace dart {

// Defined in vm/os_thread_win.cc
extern bool private_flag_windows_run_tls_destructors;

namespace bin {

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


const char* Platform::LibraryExtension() {
  return "dll";
}


bool Platform::LocalHostname(char *buffer, intptr_t buffer_length) {
#if defined(PLATFORM_DISABLE_SOCKET)
  return false;
#else
  if (!Socket::Initialize()) return false;
  return gethostname(buffer, buffer_length) == 0;
#endif
}


char** Platform::Environment(intptr_t* count) {
  wchar_t* strings = GetEnvironmentStringsW();
  if (strings == NULL) return NULL;
  wchar_t* tmp = strings;
  intptr_t i = 0;
  while (*tmp != '\0') {
    // Skip environment strings starting with "=".
    // These are synthetic variables corresponding to dynamic environment
    // variables like %=C:% and %=ExitCode%, and the Dart environment does
    // not include these.
    if (*tmp != '=') i++;
    tmp += (wcslen(tmp) + 1);
  }
  *count = i;
  char** result = new char*[i];
  tmp = strings;
  for (intptr_t current = 0; current < i;) {
    // Skip the strings that were not counted above.
    if (*tmp != '=') result[current++] = StringUtilsWin::WideToUtf8(tmp);
    tmp += (wcslen(tmp) + 1);
  }
  FreeEnvironmentStringsW(strings);
  return result;
}


void Platform::FreeEnvironment(char** env, intptr_t count) {
  for (intptr_t i = 0; i < count; i++) {
    free(env[i]);
  }
  delete[] env;
}


char* Platform::ResolveExecutablePath() {
  // GetModuleFileNameW cannot directly provide information on the
  // required buffer size, so start out with a buffer large enough to
  // hold any Windows path.
  const int kTmpBufferSize = 32768;
  wchar_t* tmp_buffer = reinterpret_cast<wchar_t*>(malloc(kTmpBufferSize));
  // Ensure no last error before calling GetModuleFileNameW.
  SetLastError(ERROR_SUCCESS);
  // Get the required length of the buffer.
  int path_length = GetModuleFileNameW(NULL, tmp_buffer, kTmpBufferSize);
  if (GetLastError() != ERROR_SUCCESS) {
    free(tmp_buffer);
    return NULL;
  }
  char* path = StringUtilsWin::WideToUtf8(tmp_buffer);
  free(tmp_buffer);
  // Return the canonical path as the returned path might contain symlinks.
  char* canon_path = File::GetCanonicalPath(path);
  free(path);
  return canon_path;
}

void Platform::Exit(int exit_code) {
  // TODO(zra): Remove once VM shuts down cleanly.
  ::dart::private_flag_windows_run_tls_destructors = false;
  // On Windows we use ExitProcess so that threads can't clobber the exit_code.
  // See: https://code.google.com/p/nativeclient/issues/detail?id=2870
  ::ExitProcess(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
