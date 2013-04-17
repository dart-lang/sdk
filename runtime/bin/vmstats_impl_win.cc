// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/vmstats_impl.h"

#include <signal.h>  // NOLINT


static void sig_handler(int sig) {
  if (sig == SIGBREAK) {
    VmStats::DumpStack();
  }
}

void VmStats::Initialize() {
  // Enable SIGBREAK (ctrl-break) stack dumps.
  if (signal(SIGBREAK, sig_handler) == SIG_ERR) {
    perror("Adding SIGBREAK signal handler failed");
  }
}

#endif  // defined(TARGET_OS_WINDOWS)
