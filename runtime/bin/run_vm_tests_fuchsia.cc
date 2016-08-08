// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <fcntl.h>
#include <launchpad/launchpad.h>
#include <magenta/syscalls.h>
#include <mxio/util.h>
#include <pthread.h>
#include <runtime/sysinfo.h>
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

// TODO(zra): Make this a command line argument
const char* kRunVmTestsPath = "/boot/bin/dart_vm_tests";

// The simulator only has 512MB;
const intptr_t kOldGenHeapSizeMB = 256;

// Tests that are invalid, wedge, or cause panics.
const char* kSkip[] = {
  // These expect a file to exist that we aren't putting in the image.
  "Read",
  "FileLength",
  "FilePosition",
  // Crash and then Hang.
  "ArrayLengthMaxElements",
  "Int8ListLengthMaxElements",
  // Crashes in realloc.
  "LargeMap",
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
  // Uses too much memory.
  "PrintJSON",
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
  // pthreads not using specified stack size?
  "StackOverflowStacktraceInfo",
  // Needs OS::GetCurrentThreadCPUMicros.
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
  "TimelineEventCallbackRecorderBasic",
  "TimelineAnalysis_ThreadBlockCount",
  "TimelineRingRecorderJSONOrder",
  "TimelinePauses_BeginEnd",
  // Needs NativeSymbolResolver
  "Service_PersistentHandles",
  // Crashes in realloc:
  "FindCodeObject",
  "SourceReport_Coverage_AllFunctions_ForceCompile",
  // pthread TLS destructors are not run.
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
  const intptr_t kArgc = 3;
  const char* argv[kArgc];

  char old_gen_arg[64];
  snprintf(old_gen_arg, sizeof(old_gen_arg), "--old_gen_heap_size=%ld",
      kOldGenHeapSizeMB);

  argv[0] = kRunVmTestsPath;
  argv[1] = old_gen_arg;
  argv[2] = test_name;

  mx_handle_t p = launchpad_launch(argv[0], kArgc, argv);
  if (p < 0) {
    fprintf(stderr, "process failed to start\n");
    return -1;
  }

  mx_signals_state_t state;
  mx_status_t r = mx_handle_wait_one(
      p, MX_SIGNAL_SIGNALED, MX_TIME_INFINITE, &state);
  if (r != NO_ERROR) {
    fprintf(stderr, "[process(%x): wait failed? %d]\n", p, r);
    return -1;
  }

  mx_process_info_t proc_info;
  mx_ssize_t ret = mx_handle_get_info(
      p, MX_INFO_PROCESS, &proc_info, sizeof(proc_info));
  if (ret != sizeof(proc_info)) {
    fprintf(stderr, "[process(%x): handle_get_info failed? %ld]\n", p, ret);
    return -1;
  }

  mx_handle_close(p);
  return proc_info.return_code;
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


typedef struct {
  pthread_mutex_t* test_list_lock;
  char** test_list;
  intptr_t test_list_length;
  intptr_t* test_list_index;
} runner_args_t;


static void* test_runner_thread(void* arg) {
  runner_args_t* args = reinterpret_cast<runner_args_t*>(arg);

  pthread_mutex_lock(args->test_list_lock);
  while (*args->test_list_index < args->test_list_length) {
    const intptr_t index = *args->test_list_index;
    *args->test_list_index = index + 1;
    pthread_mutex_unlock(args->test_list_lock);
    const char* test = args->test_list[index];
    handle_result(run_test(test), test);
    pthread_mutex_lock(args->test_list_lock);
  }
  pthread_mutex_unlock(args->test_list_lock);

  return NULL;
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


static intptr_t count_lines(FILE* fp) {
  intptr_t lines = 0;

  // Make sure we're at the beginning of the file.
  rewind(fp);

  intptr_t ch;
  while ((ch = fgetc(fp)) != EOF) {
    if (ch == '\n') {
      lines++;
    }
  }

  rewind(fp);
  return lines;
}


static intptr_t read_lines(FILE* fp, char** lines, intptr_t lines_length) {
  char* test = NULL;
  size_t len = 0;
  ssize_t read;
  intptr_t i = 0;
  while (((read = getline(&test, &len, fp)) != -1) && (i < lines_length)) {
    trim(test);
    if (!should_run(test)) {
      continue;
    }
    lines[i] = strdup(test);
    i++;
  }

  if (test != NULL) {
    free(test);
  }
  return i;
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

  intptr_t lines_count = count_lines(fp);
  char** test_list =
      reinterpret_cast<char**>(malloc(sizeof(*test_list) * lines_count));
  lines_count = read_lines(fp, test_list, lines_count);
  fclose(fp);

  pthread_mutex_t args_mutex;
  pthread_mutex_init(&args_mutex, NULL);
  intptr_t test_list_index = 0;
  runner_args_t args;
  args.test_list_lock = &args_mutex;
  args.test_list = test_list;
  args.test_list_length = lines_count;
  args.test_list_index = &test_list_index;

  const intptr_t num_cpus = mxr_get_nprocs_conf();
  pthread_t* threads =
    reinterpret_cast<pthread_t*>(malloc(num_cpus * sizeof(pthread_t)));
  for (int i = 0; i < num_cpus; i++) {
    pthread_create(&threads[i], NULL, test_runner_thread, &args);
  }

  for (int i = 0; i < num_cpus; i++) {
    pthread_join(threads[i], NULL);
  }

  free(threads);
  for (int i = 0; i < lines_count; i++) {
    free(test_list[i]);
  }
  free(test_list);
  pthread_mutex_destroy(&args_mutex);

  if (test_list_index != lines_count) {
    fprintf(stderr, "Failed to attempt all the tests!\n");
    return -1;
  }

  return 0;
}
