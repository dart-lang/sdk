// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/vmstats_impl.h"

#include <signal.h>  // NOLINT


static void sig_handler(int sig, siginfo_t* siginfo, void*) {
  if (sig == SIGQUIT) {
    VmStats::DumpStack();
  } else {
    FATAL1("unrequested signal %d received\n", sig);
  }
}

void VmStats::Initialize() {
  // Enable SIGQUIT (ctrl-\) stack dumps.
  struct sigaction sigact;
  memset(&sigact, '\0', sizeof(sigact));
  sigact.sa_sigaction = sig_handler;
  sigact.sa_flags = SA_SIGINFO;
  if (sigaction(SIGQUIT, &sigact, NULL) < 0) {
    perror("sigaction");
  }
}

#endif  // defined(TARGET_OS_ANDROID)

