// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a utility program for testing that Dart binary correctly handles
// situations when stdout and stderr handles are the same.
//
// This can happen in certain terminal emulators, e.g. one used by GitBash
// see https://github.com/dart-lang/sdk/issues/61981 for an example.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include <cstdio>
#include <source_location>
#include <sstream>
#include <vector>

struct StdioHandles {
  HANDLE in;
  HANDLE out;
  HANDLE err;
};

static void ReportErrorAndAbort(
    std::source_location location = std::source_location::current()) {
  const auto code = GetLastError();

  wchar_t buffer[512];
  auto message_size =
      FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                     nullptr, code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                     buffer, ARRAY_SIZE(buffer), nullptr);
  if (message_size == 0) {
    _snwprintf(buffer, ARRAY_SIZE(buffer), L"OS Error %d", code);
  }
  fprintf(stderr, "error at %s:%d: %ls", location.file_name(), location.line(),
          buffer);
  abort();
}

static void LaunchProcessWith(wchar_t* command_line,
                              const StdioHandles& stdio_handles) {
  fprintf(stderr, "LAUNCHING %ls\n", command_line);

  // Setup info
  STARTUPINFOEXW startup_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.StartupInfo.cb = sizeof(startup_info);

  // Setup the handles to inherit. We only want to inherit the three
  // handles for stdin, stdout and stderr.
  startup_info.StartupInfo.hStdInput = stdio_handles.in;
  startup_info.StartupInfo.hStdOutput = stdio_handles.out;
  startup_info.StartupInfo.hStdError = stdio_handles.err;
  startup_info.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
  SIZE_T size = 0;
  // The call to determine the size of an attribute list always fails with
  // ERROR_INSUFFICIENT_BUFFER and that error should be ignored.
  if (!InitializeProcThreadAttributeList(nullptr, 1, 0, &size) &&
      (GetLastError() != ERROR_INSUFFICIENT_BUFFER)) {
    return ReportErrorAndAbort();
  }
  auto attribute_list =
      reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(malloc(size));
  ZeroMemory(attribute_list, size);
  if (!InitializeProcThreadAttributeList(attribute_list, 1, 0, &size)) {
    return ReportErrorAndAbort();
  }
  std::vector<HANDLE> inherited_handles = {stdio_handles.in};
  if (stdio_handles.out != stdio_handles.in) {
    inherited_handles.push_back(stdio_handles.out);
  }
  if (stdio_handles.err != stdio_handles.out &&
      stdio_handles.err != stdio_handles.in) {
    inherited_handles.push_back(stdio_handles.err);
  }
  if (!UpdateProcThreadAttribute(
          attribute_list, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
          inherited_handles.data(), inherited_handles.size() * sizeof(HANDLE),
          nullptr, nullptr)) {
    return ReportErrorAndAbort();
  }
  startup_info.lpAttributeList = attribute_list;

  PROCESS_INFORMATION process_info;
  ZeroMemory(&process_info, sizeof(process_info));

  // Create process.
  BOOL result = CreateProcessW(
      /*lpApplicationName=*/nullptr, command_line,
      /*lpProcessAttributes=*/nullptr,
      /*lpThreadAttributes=*/nullptr,
      /*bInheritHandles=*/TRUE,
      /*dwCreationFlags=*/EXTENDED_STARTUPINFO_PRESENT,
      /*lpEnvironment=*/nullptr,
      /*lpCurrentDirectory=*/nullptr,
      reinterpret_cast<STARTUPINFOW*>(&startup_info), &process_info);

  if (result == 0) {
    return ReportErrorAndAbort();
  }

  WaitForSingleObject(process_info.hProcess, INFINITE);
  CloseHandle(process_info.hProcess);
  CloseHandle(process_info.hThread);
}

int main(int argc, char* argv[]) {
  if (argc <= 1) {
    fprintf(stderr, "Usage: %s <executable> <arg0> ... <argN>\n", argv[0]);
    return -1;
  }

  // Generate command line. Assume that it does not contain any white-space
  // in the arguments.
  std::wstringstream wstr;
  for (int i = 1; i < argc; i++) {
    wstr << (i > 1 ? " " : "") << argv[i];
  }

  HANDLE stdin_handle = GetStdHandle(STD_INPUT_HANDLE);
  HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
  LaunchProcessWith(
      wstr.str().data(),
      {.in = stdin_handle, .out = stdout_handle, .err = stdout_handle});
  CloseHandle(stdin_handle);
  CloseHandle(stdout_handle);
  return 0;
}

#else

int main() {
  return -1;
}

#endif  // defined(DART_HOST_OS_WINDOWS)
