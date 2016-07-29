// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <fcntl.h>
#include <launchpad/launchpad.h>
#include <magenta/syscalls.h>
#include <mxio/util.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// This program runs Dart VM unit tests. The Dart VM unit tests are contained
// in a separate binary whose location is defined in kRunVmTestsPath below.
// That program accepts a command line argument --list to list all the available
// tests, or the name of a single test to run. This program accepts a single
// command line argument which is the path to a file containing a list of tests
// to run, one per line.

const char* kRunVmTestsPath = "/boot/bin/dart_vm_tests";

// Tests that are invalid, wedge, or cause panics.
const char* kSkip[] = {
  // These expect a file to exist that we aren't putting in the image.
  "Read",
  "FileLength",
  "FilePosition",
  // Hangs.
  "ArrayLengthMaxElements",
  "Int8ListLengthMaxElements",
  "ThreadPool_WorkerShutdown",
  "LargeMap",
  "CompileFunctionOnHelperThread",
  // The profiler is turned off.
  "Profiler_AllocationSampleTest",
  "Profiler_ArrayAllocation",
  "Profiler_BasicSourcePosition",
  "Profiler_BasicSourcePositionOptimized",
  "Profiler_BinaryOperatorSourcePosition",
  "Profiler_BinaryOperatorSourcePositionOptimized",
  "Profiler_ChainedSamples",
  "Profiler_ClosureAllocation",
  "Profiler_CodeTicks",
  "Profiler_ContextAllocation",
  "Profiler_FunctionInline",
  "Profiler_FunctionTicks",
  "Profiler_InliningIntervalBoundry",
  "Profiler_IntrinsicAllocation",
  "Profiler_SampleBufferIterateTest",
  "Profiler_SampleBufferWrapTest",
  "Profiler_SourcePosition",
  "Profiler_SourcePositionOptimized",
  "Profiler_StringAllocation",
  "Profiler_StringInterpolation",
  "Profiler_ToggleRecordAllocation",
  "Profiler_TrivialRecordAllocation",
  "Profiler_TypedArrayAllocation",
  "Profiler_GetSourceReport",
  "Service_Profile",
  // No realpath.
  "Dart2JSCompilerStats",
  "Dart2JSCompileAll",
};

// Expected to fail/crash.
const char* kExpectFail[] = {
  "Fail0",
  "Fail1",
  "Fail2",
  "IsolateReload_PendingUnqualifiedCall_InstanceToStatic",
  "IsolateReload_PendingUnqualifiedCall_StaticToInstance",
  "IsolateReload_PendingConstructorCall_AbstractToConcrete",
  "IsolateReload_PendingConstructorCall_ConcreteToAbstract",
  "IsolateReload_PendingStaticCall_DefinedToNSM",
  "IsolateReload_PendingStaticCall_NSMToDefined",
  "ArrayNew_Overflow_Crash",
  "AllocGeneric_Overflow",
  "CodeImmutability",
  "SNPrint_BadArgs",
};

// Bugs to fix, or things that are not yet impelemnted.
const char* kBugs[] = {
  // pthreads not using specified stack size.
  "StackOverflowStacktraceInfo",
  // Needs OS::GetCurrentThreadCPUMicros.
  "Timeline_Dart_TimelineDuration",
  "Timeline_Dart_TimelineInstant"
  "Timeline_Dart_TimelineAsyncDisabled",
  "Timeline_Dart_TimelineAsync",
  "Timeline_Dart_TimelineGetTrace",
  "Timeline_Dart_TimelineGetTraceOnlyDartEvents",
  "Timeline_Dart_TimelineGetTraceWithDartEvents",
  "Timeline_Dart_TimelineGetTraceGlobalOverride",
  "Timeline_Dart_GlobalTimelineGetTrace",
  "Timeline_Dart_GlobalTimelineGetTrace_Threaded",
  "TimelineEventDuration",
  "TimelineEventDurationPrintJSON",
  "TimelineEventArguments",
  "TimelineEventArgumentsPrintJSON",
  "TimelineEventBufferPrintJSON",
  "TimelineEventCallbackRecorderBasic",
  "TimelineAnalysis_ThreadBlockCount",
  "TimelineRingRecorderJSONOrder",
  "TimelinePauses_BeginEnd",
  // Crash.
  "FindCodeObject",
  // Needs NativeSymbolResolver
  "Service_PersistentHandles",
  // Need to investigate:
  "ThreadIterator_AddFindRemove",
};


static bool contains(const char** list, intptr_t len, const char* str) {
  for (intptr_t i = 0; i < len; i++) {
    if (strcmp(list[i], str) == 0) {
      return true;
    }
  }
  return false;
}


static bool isSkip(const char* test) {
  return contains(
      kSkip, sizeof(kSkip) / sizeof(kSkip[0]), test);
}


static bool isExpectFail(const char* test) {
  return contains(
      kExpectFail, sizeof(kExpectFail) / sizeof(kExpectFail[0]), test);
}


static bool isBug(const char* test) {
  return contains(kBugs, sizeof(kBugs) / sizeof(kBugs[0]), test);
}


static int run_test(const char* test_name) {
  const intptr_t kArgc = 2;
  const char* argv[3];
  argv[0] = kRunVmTestsPath;
  argv[1] = test_name;

  mx_handle_t p = launchpad_launch(argv[0], kArgc, argv);
  if (p < 0) {
    printf("process failed to start\n");
    return -1;
  }

  mx_signals_state_t state;
  mx_status_t r = mx_handle_wait_one(
      p, MX_SIGNAL_SIGNALED, MX_TIME_INFINITE, &state);
  if (r != NO_ERROR) {
    printf("[process(%x): wait failed? %d]\n", p, r);
    return -1;
  }

  mx_process_info_t proc_info;
  mx_ssize_t ret = mx_handle_get_info(
      p, MX_INFO_PROCESS, &proc_info, sizeof(proc_info));
  if (ret != sizeof(proc_info)) {
    printf("[process(%x): handle_get_info failed? %ld]\n", p, ret);
    return -1;
  }

  mx_handle_close(p);
  return proc_info.return_code;
}


static void trim(char* line) {
  const intptr_t line_len = strlen(line);
  if (line[line_len - 1] == '\n') {
    line[line_len - 1] = '\0';
  }
}


static bool should_run(const char* test) {
  return !(test[0] == '#') && !isSkip(test);
}


static void handle_result(intptr_t result, const char* test) {
  if (result != 0) {
    if (!isExpectFail(test) && !isBug(test)) {
      printf("******** Test %s FAILED\n", test);
    }
  } else {
    if (isExpectFail(test)) {
      printf("******** Test %s is expected to fail, but PASSED\n", test);
    }
    if (isBug(test)) {
      printf("******** Test %s is marked as a bug, but PASSED\n", test);
    }
  }
}


int main(int argc, char** argv) {
  if (argc <= 1) {
    fprintf(stderr, "Pass the path to a file containing the list of tests\n");
    return -1;
  }
  const char* tests_path = argv[1];

  FILE* fp = fopen(tests_path, "r");
  if (fp == NULL) {
    fprintf(stderr, "Failed to read the file: %s\n", tests_path);
    return -1;
  }

  char* test = NULL;
  size_t len = 0;
  ssize_t read;
  while ((read = getline(&test, &len, fp)) != -1) {
    trim(test);
    if (!should_run(test)) {
      continue;
    }
    intptr_t result = run_test(test);
    handle_result(result, test);
  }

  fclose(fp);
  if (test != NULL) {
    free(test);
  }
  return 0;
}
