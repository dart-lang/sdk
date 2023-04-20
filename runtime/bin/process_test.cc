// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Force .lib-file creation on Windows, make ninja happy with zero-build.
#if defined(_WIN32)
extern "C" __declspec(dllexport) void dummy() {}
#endif

#if defined(__has_feature)
#if __has_feature(undefined_behavior_sanitizer)
__attribute__((no_sanitize("undefined")))
#endif
#endif
void Crash() {
  int* segfault = nullptr;
  *segfault = 1;
}

/*
 * Run ./process_test <outstream> <echocount> <exitcode> <crash>
 * <outstream>: 0 = stdout, 1 = stderr, 2 = stdout and stderr
 * <echocount>: program terminates after <echocount> replies
 * <exitcode>: program terminates with exit code <exitcode>
 * <crash>: 0 = program terminates regularly, 1 = program segfaults
 */
int main(int argc, char* argv[]) {
  if (argc != 5) {
    fprintf(stderr,
            "./process_test <outstream> <echocount> <exitcode> <crash>\n");
    exit(1);
  }

  int outstream = atoi(argv[1]);
  if (outstream < 0 || outstream > 2) {
    fprintf(stderr, "unknown outstream");
    exit(1);
  }

  int echo_counter = 0;
  int echo_count = atoi(argv[2]);
  int exit_code = atoi(argv[3]);
  int crash = atoi(argv[4]);

  if (crash == 1) {
    Crash();
  }

  const int kLineSize = 128;
  char line[kLineSize];

  while ((echo_count != echo_counter) &&
         (fgets(line, kLineSize, stdin) != nullptr)) {
    if (outstream == 0) {
      fprintf(stdout, "%s", line);
      fflush(stdout);
    } else if (outstream == 1) {
      fprintf(stderr, "%s", line);
      fflush(stderr);
    } else if (outstream == 2) {
      fprintf(stdout, "%s", line);
      fprintf(stderr, "%s", line);
      fflush(stdout);
      fflush(stderr);
    }
    echo_counter++;
  }

  return exit_code;
}
