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
#include <string>

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

  bool has_memory_limit = false;
  size_t memory_limit = 0;
  bool has_cpu_percent_limit = false;
  size_t cpu_percent_limit = 0;
  bool has_cpu_mask_limit = false;
  size_t cpu_mask_limit = 0;
  bool has_process_limit = false;
  size_t process_limit = 0;

  int argi = 1;
  for (;;) {
    if (argi >= argc) {
      fprintf(stderr, "job_run: no command given\n");
      abort();
    }
    if (strcmp(argv[argi], "--memory") == 0) {
      has_memory_limit = true;
      memory_limit = std::stoll(argv[argi + 1]);
      argi += 2;
    } else if (strcmp(argv[argi], "--cpu-percent") == 0) {
      has_cpu_percent_limit = true;
      cpu_percent_limit = std::stoll(argv[argi + 1]);
      argi += 2;
    } else if (strcmp(argv[argi], "--cpu-mask") == 0) {
      has_cpu_mask_limit = true;
      cpu_mask_limit = std::stoll(argv[argi + 1]);
      argi += 2;
    } else if (strcmp(argv[argi], "--processes") == 0) {
      has_process_limit = true;
      process_limit = std::stoll(argv[argi + 1]);
      argi += 2;
    } else if (strcmp(argv[argi], "--") == 0) {
      argi += 1;
      break;
    } else {
      fprintf(stderr, "job_run: unknown flag %s\n", argv[argi]);
      abort();
    }
  }
  std::wstringstream wstr;
  bool first = true;
  for (; argi < argc; argi++) {
    if (first) {
      first = false;
    } else {
      wstr << " ";
    }
    wstr << argv[argi];
  }
  if (first) {
    fprintf(stderr, "job_run: command expected\n");
    abort();
  }

  HANDLE job = CreateJobObject(nullptr, nullptr);
  if (job == nullptr) {
    fprintf(stderr, "job_run: CreateJobObject %lu\n", GetLastError());
    abort();
  }

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION extended_info;
  ZeroMemory(&extended_info, sizeof(extended_info));
  extended_info.BasicLimitInformation.LimitFlags |=
      JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (has_memory_limit) {
    extended_info.BasicLimitInformation.LimitFlags |=
        JOB_OBJECT_LIMIT_JOB_MEMORY;
    extended_info.JobMemoryLimit = memory_limit;
  }
  if (has_process_limit) {
    extended_info.BasicLimitInformation.LimitFlags |=
        JOB_OBJECT_LIMIT_ACTIVE_PROCESS;
    extended_info.BasicLimitInformation.ActiveProcessLimit = process_limit;
  }
  if (has_cpu_mask_limit) {
    extended_info.BasicLimitInformation.LimitFlags |=
        (JOB_OBJECT_LIMIT_AFFINITY | JOB_OBJECT_LIMIT_SUBSET_AFFINITY);
    extended_info.BasicLimitInformation.Affinity = cpu_mask_limit;
  }
  if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation,
                               &extended_info, sizeof(extended_info))) {
    fprintf(stderr, "job_run: SetInformationJobObject(extended) %lu\n",
            GetLastError());
    abort();
  }

  if (has_cpu_percent_limit) {
    DWORD cpu_total = GetActiveProcessorCount(ALL_PROCESSOR_GROUPS);
    if (cpu_total * 100 > cpu_percent_limit) {
      JOBOBJECT_CPU_RATE_CONTROL_INFORMATION cpu_info;
      ZeroMemory(&cpu_info, sizeof(cpu_info));
      cpu_info.ControlFlags |= JOB_OBJECT_CPU_RATE_CONTROL_ENABLE |
                               JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP;
      cpu_info.CpuRate = (cpu_percent_limit * 100) / cpu_total;
      if (cpu_info.CpuRate == 0) {
        cpu_info.CpuRate = 1;  // Must be in 1..10000.
      }
      if (!SetInformationJobObject(job, JobObjectCpuRateControlInformation,
                                   &cpu_info, sizeof(cpu_info))) {
        fprintf(stderr, "job_run: SetInformationJobObject(cpu) %lu\n",
                GetLastError());
        abort();
      }
    } else {
      // Nothing to cap.
    }
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
    fprintf(stderr, "job_run: InitializeProcThreadAttributeList %lu\n",
            GetLastError());
    abort();
  }
  LPPROC_THREAD_ATTRIBUTE_LIST attribute_list =
      reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(malloc(size));
  ZeroMemory(attribute_list, size);
  if (!InitializeProcThreadAttributeList(attribute_list, 2, 0, &size)) {
    fprintf(stderr, "job_run: InitializeProcThreadAttributeList %lu\n",
            GetLastError());
    abort();
  }
  if (!UpdateProcThreadAttribute(attribute_list, 0,
                                 PROC_THREAD_ATTRIBUTE_JOB_LIST, &job,
                                 sizeof(job), nullptr, nullptr)) {
    fprintf(stderr, "job_run: UpdateProcThreadAttribute %lu\n", GetLastError());
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
    fprintf(stderr, "job_run: UpdateProcThreadAttribute %lu\n", GetLastError());
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
    fprintf(stderr, "job_run: CreateProcess %lu\n", GetLastError());
    abort();
  }

  DWORD wait_result = WaitForSingleObject(process_info.hProcess, INFINITE);
  if (wait_result != WAIT_OBJECT_0) {
    fprintf(stderr, "job_run: WaitForSingleObject %lu\n", wait_result);
    abort();
  }

  DWORD exit_code = 0;
  if (!GetExitCodeProcess(process_info.hProcess, &exit_code)) {
    fprintf(stderr, "job_run: GetExitCodeProcess %lu\n", GetLastError());
    abort();
  }

  if (!QueryInformationJobObject(job, JobObjectExtendedLimitInformation,
                                 &extended_info, sizeof(extended_info),
                                 nullptr)) {
    fprintf(stderr, "job_run: QueryInformationJobObject %lu\n", GetLastError());
    abort();
  }

  fprintf(stderr, "job_run: peak memory usage: %zu\n",
          extended_info.PeakJobMemoryUsed);

  return exit_code;
}

#else  // WINDOWS

int main(int argc, char** argv) {
  return 1;
}

#endif
