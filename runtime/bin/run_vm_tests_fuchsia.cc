// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <fcntl.h>
#include <launchpad/launchpad.h>
#include <launchpad/vmo.h>
#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <magenta/syscalls/object.h>
#include <mxio/util.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// This program runs Dart VM unit tests. The Dart VM unit tests are contained
// in a separate binary whose location is defined in kRunVmTestsPath below.
// That program accepts a command line argument --list to list all the available
// tests, or the name of a single test to run. This program grabs the list of
// tests, and then runs them.

// TODO(zra): Make this a command line argument
const char* kRunVmTestsPath = "/system/bin/dart_vm_tests";

// clang-format off
// Tests that are invalid, wedge, or cause panics.
const char* kSkip[] = {
  // These expect a file to exist that we aren't putting in the image.
  "Read",
  "FileLength",
  "FilePosition",
  // No realpath, files not in image.
  "Dart2JSCompilerStats",
  "Dart2JSCompileAll",
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
};

// Expected to fail/crash.
const char* kExpectFail[] = {
  "Fail0",
  "Fail1",
  "Fail2",
  "AllocGeneric_Overflow",
  "CodeImmutability",
  "IsolateReload_PendingUnqualifiedCall_StaticToInstance",
  "IsolateReload_PendingConstructorCall_AbstractToConcrete",
  "IsolateReload_PendingConstructorCall_ConcreteToAbstract",
  "IsolateReload_PendingUnqualifiedCall_InstanceToStatic",
  "IsolateReload_PendingStaticCall_DefinedToNSM",
  "IsolateReload_PendingStaticCall_NSMToDefined",
  "ArrayNew_Overflow_Crash",
  "SNPrint_BadArgs",
};

// Bugs to fix, or things that are not yet implemented.
const char* kBugs[] = {
  // Need OS::GetCurrentThreadCPUMicros.
  "Timeline_Dart_TimelineGetTraceOnlyDartEvents",
  "Timeline_Dart_TimelineGetTraceWithDartEvents",
  "Timeline_Dart_GlobalTimelineGetTrace",
  "TimelineEventDuration",
  "TimelineEventDurationPrintJSON",
  "TimelineEventArguments",
  "TimelineEventArgumentsPrintJSON",
  "TimelineEventCallbackRecorderBasic",
  "TimelineAnalysis_ThreadBlockCount",
  "TimelineRingRecorderJSONOrder",
  "TimelinePauses_BeginEnd",
  "Timeline_Dart_TimelineGetTrace",
  "Timeline_Dart_TimelineGetTraceGlobalOverride",
  "Timeline_Dart_GlobalTimelineGetTrace_Threaded",

  // Need VirtualMemory reservation with mmap.
  "ArrayLengthMaxElements",
  "Int8ListLengthMaxElements",

  // Assumes initial thread's stack is the same size as spawned thread stacks.
  "StackOverflowStacktraceInfo",
};
// clang-format on

static bool contains(const char** list, intptr_t len, const char* str) {
  for (intptr_t i = 0; i < len; i++) {
    if (strcmp(list[i], str) == 0) {
      return true;
    }
  }
  return false;
}


static bool isSkip(const char* test) {
  return contains(kSkip, sizeof(kSkip) / sizeof(kSkip[0]), test);
}


static bool isExpectFail(const char* test) {
  return contains(kExpectFail, sizeof(kExpectFail) / sizeof(kExpectFail[0]),
                  test);
}


static bool isBug(const char* test) {
  return contains(kBugs, sizeof(kBugs) / sizeof(kBugs[0]), test);
}

#define RETURN_IF_ERROR(status)                                                \
  if (status < 0) {                                                            \
    fprintf(stderr, "%s:%d: Magenta call failed: %s\n", __FILE__, __LINE__,    \
            mx_status_get_string(static_cast<mx_status_t>(status)));           \
    fflush(0);                                                                 \
    return status;                                                             \
  }

// This is mostly taken from //magenta/system/uapp/mxsh with the addtion of
// launchpad_add_pipe calls to setup pipes for stdout and stderr.
static mx_status_t lp_setup(launchpad_t** lp_out,
                            mx_handle_t binary_vmo,
                            int argc,
                            const char* const* argv,
                            int* stdout_out,
                            int* stderr_out) {
  if ((lp_out == NULL) || (stdout_out == NULL) || (stderr_out == NULL)) {
    return ERR_INVALID_ARGS;
  }
  launchpad_t* lp;
  mx_status_t status;
  status = launchpad_create(0, argv[0], &lp);
  RETURN_IF_ERROR(status);
  status = launchpad_arguments(lp, argc, argv);
  RETURN_IF_ERROR(status);
  status = launchpad_clone_mxio_root(lp);
  RETURN_IF_ERROR(status);
  status = launchpad_add_pipe(lp, stdout_out, 1);
  RETURN_IF_ERROR(status);
  status = launchpad_add_pipe(lp, stderr_out, 2);
  RETURN_IF_ERROR(status);
  status = launchpad_add_vdso_vmo(lp);
  RETURN_IF_ERROR(status);
  status = launchpad_elf_load(lp, binary_vmo);
  RETURN_IF_ERROR(status);
  status = launchpad_load_vdso(lp, MX_HANDLE_INVALID);
  RETURN_IF_ERROR(status);
  *lp_out = lp;
  return status;
}


// Start the test running and return file descriptors for the stdout and stderr
// pipes.
static mx_handle_t start_test(mx_handle_t binary_vmo,
                              const char* test_name,
                              int* stdout_out,
                              int* stderr_out) {
  const intptr_t kArgc = 2;
  const char* argv[kArgc];

  argv[0] = kRunVmTestsPath;
  argv[1] = test_name;

  launchpad_t* lp = NULL;
  int stdout_pipe = -1;
  int stderr_pipe = -1;
  mx_status_t status =
      lp_setup(&lp, binary_vmo, kArgc, argv, &stdout_pipe, &stderr_pipe);
  if (status != NO_ERROR) {
    if (lp != NULL) {
      launchpad_destroy(lp);
    }
    if (stdout_pipe != -1) {
      close(stdout_pipe);
    }
    if (stderr_pipe != -1) {
      close(stderr_pipe);
    }
  }
  RETURN_IF_ERROR(status);

  mx_handle_t p = launchpad_start(lp);
  launchpad_destroy(lp);
  if (p < 0) {
    close(stdout_pipe);
    close(stderr_pipe);
  }
  RETURN_IF_ERROR(p);

  if (stdout_out != NULL) {
    *stdout_out = stdout_pipe;
  } else {
    close(stdout_pipe);
  }
  if (stderr_out != NULL) {
    *stderr_out = stderr_pipe;
  } else {
    close(stderr_pipe);
  }
  return p;
}


// Drain fd into a buffer pointed to by 'buffer'. Assumes that the data is a
// C string, and null-terminates it. Returns the number of bytes read.
static intptr_t drain_fd(int fd, char** buffer) {
  const intptr_t kDrainInitSize = 64;
  char* buf = reinterpret_cast<char*>(malloc(kDrainInitSize));
  intptr_t free_space = kDrainInitSize;
  intptr_t total_read = 0;
  intptr_t read_size = 0;
  while ((read_size = read(fd, buf + total_read, free_space)) != 0) {
    if (read_size == -1) {
      break;
    }
    total_read += read_size;
    free_space -= read_size;
    if (free_space <= 1) {
      // new_size = size * 1.5.
      intptr_t new_size = (total_read << 1) - (total_read >> 1);
      buf = reinterpret_cast<char*>(realloc(buf, new_size));
      free_space = new_size - total_read;
    }
  }
  buf[total_read] = '\0';
  close(fd);
  *buffer = buf;
  return total_read;
}


// Runs test 'test_name' and gives stdout and stderr for the test in
// 'test_stdout' and 'test_stderr'. Returns the exit code from the test.
static int run_test(mx_handle_t binary_vmo,
                    const char* test_name,
                    char** test_stdout,
                    char** test_stderr) {
  int stdout_pipe = -1;
  int stderr_pipe = -1;
  mx_handle_t p = start_test(binary_vmo, test_name, &stdout_pipe, &stderr_pipe);
  RETURN_IF_ERROR(p);

  drain_fd(stdout_pipe, test_stdout);
  drain_fd(stderr_pipe, test_stderr);

  mx_status_t r =
      mx_handle_wait_one(p, MX_SIGNAL_SIGNALED, MX_TIME_INFINITE, NULL);
  RETURN_IF_ERROR(r);

  mx_info_process_t proc_info;
  mx_status_t status = mx_object_get_info(p, MX_INFO_PROCESS, &proc_info,
                                          sizeof(proc_info), nullptr, nullptr);
  RETURN_IF_ERROR(status);

  r = mx_handle_close(p);
  RETURN_IF_ERROR(r);
  return proc_info.return_code;
}


static void handle_result(intptr_t result,
                          char* test_stdout,
                          char* test_stderr,
                          const char* test) {
  if (result != 0) {
    if (!isExpectFail(test) && !isBug(test)) {
      printf("**** Test %s FAILED\n\nstdout:\n%s\nstderr:\n%s\n", test,
             test_stdout, test_stderr);
    } else {
      printf("Test %s FAILED and is expected to fail\n", test);
    }
  } else {
    if (isExpectFail(test)) {
      printf(
          "**** Test %s is expected to fail, but PASSED\n\n"
          "stdout:\n%s\nstderr:\n%s\n",
          test, test_stdout, test_stderr);
    } else if (isBug(test)) {
      printf("**** Test %s is marked as a bug, but PASSED\n", test);
    } else {
      printf("Test %s PASSED\n", test);
    }
  }
}


typedef struct {
  pthread_mutex_t* test_list_lock;
  char** test_list;
  intptr_t test_list_length;
  intptr_t* test_list_index;
  mx_handle_t binary_vmo;
} runner_args_t;


static void* test_runner_thread(void* arg) {
  runner_args_t* args = reinterpret_cast<runner_args_t*>(arg);

  pthread_mutex_lock(args->test_list_lock);
  mx_handle_t binary_vmo = args->binary_vmo;
  while (*args->test_list_index < args->test_list_length) {
    const intptr_t index = *args->test_list_index;
    *args->test_list_index = index + 1;
    pthread_mutex_unlock(args->test_list_lock);

    const char* test = args->test_list[index];
    char* test_stdout = NULL;
    char* test_stderr = NULL;
    mx_handle_t vmo_dup = MX_HANDLE_INVALID;
    mx_handle_duplicate(binary_vmo, MX_RIGHT_SAME_RIGHTS, &vmo_dup);
    int test_status = run_test(vmo_dup, test, &test_stdout, &test_stderr);
    handle_result(test_status, test_stdout, test_stderr, test);
    free(test_stdout);
    free(test_stderr);
    pthread_mutex_lock(args->test_list_lock);
  }
  pthread_mutex_unlock(args->test_list_lock);

  return NULL;
}


static void run_all_tests(runner_args_t* args) {
  const intptr_t num_cpus = sysconf(_SC_NPROCESSORS_CONF);
  pthread_t* threads =
      reinterpret_cast<pthread_t*>(malloc(num_cpus * sizeof(pthread_t)));
  for (int i = 0; i < num_cpus; i++) {
    pthread_create(&threads[i], NULL, test_runner_thread, args);
  }
  for (int i = 0; i < num_cpus; i++) {
    pthread_join(threads[i], NULL);
  }
  free(threads);
}


static bool should_run(const char* test) {
  return !(test[0] == '#') && !isSkip(test);
}


static char** parse_test_list(char* list_output, intptr_t* length) {
  const intptr_t list_output_length = strlen(list_output);
  intptr_t test_count = 0;
  for (int i = 0; i < list_output_length; i++) {
    if (list_output[i] == '\n') {
      test_count++;
    }
  }
  char** test_list;
  test_list = reinterpret_cast<char**>(malloc(test_count * sizeof(*test_list)));
  char* test = list_output;
  char* strtok_context;
  intptr_t idx = 0;
  while ((test = strtok_r(test, "\n", &strtok_context)) != NULL) {
    if (should_run(test)) {
      test_list[idx] = strdup(test);
      idx++;
    }
    test = NULL;
  }

  *length = idx;
  return test_list;
}


int main(int argc, char** argv) {
  // TODO(zra): Read test binary path from the command line.

  // Load in the binary.
  mx_handle_t binary_vmo = launchpad_vmo_from_file(kRunVmTestsPath);
  RETURN_IF_ERROR(binary_vmo);

  // Run with --list to grab the list of tests.
  char* list_stdout = NULL;
  char* list_stderr = NULL;
  mx_handle_t list_vmo = MX_HANDLE_INVALID;
  mx_status_t status =
      mx_handle_duplicate(binary_vmo, MX_RIGHT_SAME_RIGHTS, &list_vmo);
  RETURN_IF_ERROR(status);
  int list_result = run_test(list_vmo, "--list", &list_stdout, &list_stderr);
  if (list_result != 0) {
    fprintf(stderr, "Failed to list tests: %s\n%s\n", list_stdout, list_stderr);
    fflush(0);
    free(list_stdout);
    free(list_stderr);
    return list_result;
  }

  // Parse the test list into an array of C strings.
  intptr_t lines_count;
  char** test_list = parse_test_list(list_stdout, &lines_count);
  free(list_stdout);
  free(list_stderr);

  fprintf(stdout, "Found %ld tests\n", lines_count);
  fflush(0);

  // Run the tests across a number of threads equal to the number of cores.
  pthread_mutex_t args_mutex;
  pthread_mutex_init(&args_mutex, NULL);
  intptr_t test_list_index = 0;
  runner_args_t args;
  args.test_list_lock = &args_mutex;
  args.test_list = test_list;
  args.test_list_length = lines_count;
  args.test_list_index = &test_list_index;
  args.binary_vmo = binary_vmo;
  run_all_tests(&args);

  // Cleanup.
  for (int i = 0; i < lines_count; i++) {
    free(test_list[i]);
  }
  free(test_list);
  pthread_mutex_destroy(&args_mutex);
  status = mx_handle_close(binary_vmo);
  RETURN_IF_ERROR(status);

  // Complain if we didn't try to run all of the tests.
  if (test_list_index != lines_count) {
    fprintf(stderr, "Failed to attempt all the tests!\n");
    fflush(0);
    return -1;
  }
  return 0;
}
