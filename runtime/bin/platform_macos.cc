// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"

#include <signal.h>
#include <string.h>
#include <unistd.h>


bool Platform::Initialize() {
  // Turn off the signal handler for SIGPIPE as it causes the process
  // to terminate on writing to a closed pipe. Without the signal
  // handler error EPIPE is set instead.
  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_handler = SIG_IGN;
  if (sigaction(SIGPIPE, &act, 0) != 0) {
    perror("Setting signal handler failed");
    return false;
  }
  return true;
}


int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}


const char* Platform::OperatingSystem() {
  return "macos";
}


bool Platform::LocalHostname(char *buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}


char* Platform::StrError(int error_code) {
  static const int kBufferSize = 1024;
  char* error = static_cast<char*>(malloc(kBufferSize));
  error[0] = '\0';
  strerror_r(error_code, error, kBufferSize);
  return error;
}
