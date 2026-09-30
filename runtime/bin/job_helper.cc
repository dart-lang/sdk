// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(_WIN32)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#include <processthreadsapi.h>
#include <psapi.h>

#include <sstream>

int main(int argc, char** argv) {
  // Make various kinds of error print instead of opening dialog boxes.
  UINT new_flags =
      SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX;
  UINT existing_flags = SetErrorMode(new_flags);
  SetErrorMode(existing_flags | new_flags);
  _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
  _CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
  _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
  _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
  _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_FILE);
  _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
  _set_error_mode(_OUT_TO_STDERR);
  _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);

  HANDLE job = CreateJobObject(nullptr, nullptr);
  if (job == nullptr) {
    fprintf(stderr, "CreateJobObject %lu\n", GetLastError());
    abort();
  }

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit_info;
  ZeroMemory(&limit_info, sizeof(limit_info));
  if (!QueryInformationJobObject(job, JobObjectExtendedLimitInformation,
                                 &limit_info, sizeof(limit_info), nullptr)) {
    fprintf(stderr, "QueryInformationJobObject %lu\n", GetLastError());
    abort();
  }
  limit_info.BasicLimitInformation.LimitFlags |=
      JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE | JOB_OBJECT_LIMIT_JOB_MEMORY;
  limit_info.JobMemoryLimit = static_cast<size_t>(2) << 30;  // 2GB
  if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation,
                               &limit_info, sizeof(limit_info))) {
    fprintf(stderr, "SetInformationJobObject %lu\n", GetLastError());
    abort();
  }

  if (argc < 2) {
    fprintf(stderr, "no command given\n");
    abort();
  }
  std::wstringstream wstr;
  for (int i = 1; i < argc; i++) {
    wstr << (i > 1 ? " " : "") << argv[i];
  }

  STARTUPINFOEXW startup_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.StartupInfo.cb = sizeof(startup_info);
  startup_info.StartupInfo.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  startup_info.StartupInfo.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
  startup_info.StartupInfo.hStdError = GetStdHandle(STD_ERROR_HANDLE);
  startup_info.StartupInfo.dwFlags = STARTF_USESTDHANDLES;

  SIZE_T size = 0;
  if (!InitializeProcThreadAttributeList(nullptr, 2, 0, &size) &&
      (GetLastError() != ERROR_INSUFFICIENT_BUFFER)) {
    fprintf(stderr, "InitializeProcThreadAttributeList %lu\n", GetLastError());
    abort();
  }
  LPPROC_THREAD_ATTRIBUTE_LIST attribute_list =
      reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(malloc(size));
  ZeroMemory(attribute_list, size);
  if (!InitializeProcThreadAttributeList(attribute_list, 2, 0, &size)) {
    fprintf(stderr, "InitializeProcThreadAttributeList %lu\n", GetLastError());
    abort();
  }
  if (!UpdateProcThreadAttribute(attribute_list, 0,
                                 PROC_THREAD_ATTRIBUTE_JOB_LIST, &job,
                                 sizeof(job), nullptr, nullptr)) {
    fprintf(stderr, "UpdateProcThreadAttribute %lu\n", GetLastError());
    abort();
  }
  HANDLE inherited_handles[3] = {
      startup_info.StartupInfo.hStdInput,
      startup_info.StartupInfo.hStdOutput,
      startup_info.StartupInfo.hStdError,
  };
  if (!UpdateProcThreadAttribute(
          attribute_list, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
          &inherited_handles, sizeof(inherited_handles), nullptr, nullptr)) {
    fprintf(stderr, "UpdateProcThreadAttribute %lu\n", GetLastError());
    abort();
  }
  startup_info.lpAttributeList = attribute_list;

  PROCESS_INFORMATION process_info;
  ZeroMemory(&process_info, sizeof(process_info));

  if (!CreateProcess(nullptr,            // Name
                     wstr.str().data(),  // Command line.
                     nullptr,            // Don't inherit process handle.
                     nullptr,            // Don't inherit thread handle.
                     TRUE,               // Inherit handles.
                     EXTENDED_STARTUPINFO_PRESENT,  // Flags
                     nullptr,                       // Use parent's environment.
                     nullptr,  // Use parent's working directory.
                     reinterpret_cast<STARTUPINFOW*>(&startup_info),
                     &process_info)) {
    fprintf(stderr, "CreateProcess %lu\n", GetLastError());
    abort();
  }

  DWORD wait_result = WaitForSingleObject(process_info.hProcess, INFINITE);
  if (wait_result != WAIT_OBJECT_0) {
    fprintf(stderr, "WaitForSingleObject %lu\n", wait_result);
    abort();
  }

  DWORD exit_code = 0;
  if (!GetExitCodeProcess(process_info.hProcess, &exit_code)) {
    fprintf(stderr, "GetExitCodeProcess %lu\n", GetLastError());
    abort();
  }

  if (!QueryInformationJobObject(job, JobObjectExtendedLimitInformation,
                                 &limit_info, sizeof(limit_info), nullptr)) {
    fprintf(stderr, "QueryInformationJobObject %lu\n", GetLastError());
    abort();
  }

  fprintf(stderr, "peak memory usage: %zu\n", limit_info.PeakJobMemoryUsed);

  return exit_code;
}

#else  // WINDOWS

int main(int argc, char** argv) {
  return 1;
}

#endif
