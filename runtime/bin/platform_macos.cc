// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/platform.h"

#include <crt_externs.h>
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
  // Unblock SIGCHLD as waiting on spawned child process depends
  // on successful interception of this signal.
  sigset_t newset;
  sigemptyset(&newset);
  sigaddset(&newset, SIGCHLD);
  if (sigprocmask(SIG_UNBLOCK, &newset, NULL) != 0) {
    perror("Unblocking SIGCHLD signal failed");
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


char** Platform::Environment(intptr_t* count) {
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
  // On MacOS you have to do a bit of magic to get to the
  // environment strings.
  char** environ = *(_NSGetEnviron());
  intptr_t i = 0;
  char** tmp = environ;
  while (*(tmp++) != NULL) i++;
  *count = i;
  char** result = new char*[i];
  for (intptr_t current = 0; current < i; current++) {
    result[current] = environ[current];
  }
  return result;
}


void Platform::FreeEnvironment(char** env, intptr_t count) {
  delete[] env;
}


char* Platform::StrError(int error_code) {
  static const int kBufferSize = 1024;
  char* error = static_cast<char*>(malloc(kBufferSize));
  error[0] = '\0';
  strerror_r(error_code, error, kBufferSize);
  return error;
}
