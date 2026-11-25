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

  BOOL in_job = FALSE;
  if (!IsProcessInJob(GetCurrentProcess(), nullptr, &in_job)) {
    fprintf(stderr, "job_query: IsProcessInJob %lu\n", GetLastError());
    abort();
  }
  if (!in_job) {
    fprintf(stderr, "job_query: not in job\n");
    return 1;
  }

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION extended_info;
  ZeroMemory(&extended_info, sizeof(extended_info));
  if (!QueryInformationJobObject(nullptr, JobObjectExtendedLimitInformation,
                                 &extended_info, sizeof(extended_info),
                                 nullptr)) {
    fprintf(stderr, "job_query: QueryInformationJobObject(extended) %lu\n",
            GetLastError());
    abort();
  }
  JOBOBJECT_CPU_RATE_CONTROL_INFORMATION cpu_info;
  ZeroMemory(&cpu_info, sizeof(cpu_info));
  if (!QueryInformationJobObject(nullptr, JobObjectCpuRateControlInformation,
                                 &cpu_info, sizeof(cpu_info), nullptr)) {
    fprintf(stderr, "job_query: QueryInformationJobObject(cpu) %lu\n",
            GetLastError());
    abort();
  }

  printf("JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE) != 0);
  printf("JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION) != 0);

  printf("JOB_OBJECT_LIMIT_BREAKAWAY_OK=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_BREAKAWAY_OK) != 0);
  printf("JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK) != 0);

  printf("JOB_OBJECT_LIMIT_JOB_MEMORY=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_JOB_MEMORY) != 0);
  if (extended_info.BasicLimitInformation.LimitFlags &
      JOB_OBJECT_LIMIT_JOB_MEMORY) {
    printf("JobMemoryLimit=%zu\n", extended_info.JobMemoryLimit);
  }
  printf("PeakJobMemoryUsed=%zu\n", extended_info.PeakJobMemoryUsed);

  printf("JOB_OBJECT_LIMIT_PROCESS_MEMORY=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_PROCESS_MEMORY) != 0);
  if (extended_info.BasicLimitInformation.LimitFlags &
      JOB_OBJECT_LIMIT_PROCESS_MEMORY) {
    printf("ProcessMemoryLimit=%zu\n", extended_info.ProcessMemoryLimit);
  }
  printf("PeakProcessMemoryUsed=%zu\n", extended_info.PeakProcessMemoryUsed);

  printf("JOB_OBJECT_LIMIT_ACTIVE_PROCESS=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_ACTIVE_PROCESS) != 0);
  if (extended_info.BasicLimitInformation.LimitFlags &
      JOB_OBJECT_LIMIT_ACTIVE_PROCESS) {
    printf("ActiveProcessLimit=%lu\n",
           extended_info.BasicLimitInformation.ActiveProcessLimit);
  }

  printf("JOB_OBJECT_LIMIT_AFFINITY=%d\n",
         (extended_info.BasicLimitInformation.LimitFlags &
          JOB_OBJECT_LIMIT_AFFINITY) != 0);
  if (extended_info.BasicLimitInformation.LimitFlags &
      JOB_OBJECT_LIMIT_AFFINITY) {
    printf("JOB_OBJECT_LIMIT_SUBSET_AFFINITY=%d\n",
           (extended_info.BasicLimitInformation.LimitFlags &
            JOB_OBJECT_LIMIT_SUBSET_AFFINITY) != 0);
    printf("Affinity=%llu\n", extended_info.BasicLimitInformation.Affinity);
  }

  printf("JOB_OBJECT_CPU_RATE_CONTROL_ENABLE=%d\n",
         (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_ENABLE) != 0);
  if (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_ENABLE) {
    printf("JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP=%d\n",
           (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP) != 0);
    if (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP) {
      printf("CpuRate=%lu\n", cpu_info.CpuRate);
    }

    printf("JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED=%d\n",
           (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED) !=
               0);
    if (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED) {
      printf("Weight=%lu\n", cpu_info.Weight);
    }

    printf("JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE=%d\n",
           (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE) !=
               0);
    if (cpu_info.ControlFlags & JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE) {
      printf("MinRate=%hu\n", cpu_info.MinRate);
      printf("MaxRate=%hu\n", cpu_info.MaxRate);
    }
  }

  return 0;
}

#else  // WINDOWS

int main(int argc, char** argv) {
  return 1;
}

#endif
