// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                        \
    defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA)

#include "bin/console.h"

#include <errno.h>
#include <sys/ioctl.h>
#include <termios.h>

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

class PosixConsole {
 public:
  static const tcflag_t kInvalidFlag = -1;

  static void Initialize() {
    SaveMode(STDOUT_FILENO, &stdout_initial_c_lflag_);
    SaveMode(STDERR_FILENO, &stderr_initial_c_lflag_);
    SaveMode(STDIN_FILENO, &stdin_initial_c_lflag_);
  }

  static void Cleanup() {
    RestoreMode(STDOUT_FILENO, stdout_initial_c_lflag_);
    RestoreMode(STDERR_FILENO, stderr_initial_c_lflag_);
    RestoreMode(STDIN_FILENO, stdin_initial_c_lflag_);
    ClearLFlags();
  }

 private:
  static tcflag_t stdout_initial_c_lflag_;
  static tcflag_t stderr_initial_c_lflag_;
  static tcflag_t stdin_initial_c_lflag_;

  static void ClearLFlags() {
    stdout_initial_c_lflag_ = kInvalidFlag;
    stderr_initial_c_lflag_ = kInvalidFlag;
    stdin_initial_c_lflag_ = kInvalidFlag;
  }

  static void SaveMode(intptr_t fd, tcflag_t* flag) {
    ASSERT(flag != NULL);
    struct termios term;
    int status = TEMP_FAILURE_RETRY(tcgetattr(fd, &term));
    if (status != 0) {
      return;
    }
    *flag = term.c_lflag;
  }

  static void RestoreMode(intptr_t fd, tcflag_t flag) {
    if (flag == kInvalidFlag) {
      return;
    }
    struct termios term;
    int status = TEMP_FAILURE_RETRY(tcgetattr(fd, &term));
    if (status != 0) {
      return;
    }
    term.c_lflag = flag;
    VOID_TEMP_FAILURE_RETRY(tcsetattr(fd, TCSANOW, &term));
  }

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(PosixConsole);
};

tcflag_t PosixConsole::stdout_initial_c_lflag_ = PosixConsole::kInvalidFlag;
tcflag_t PosixConsole::stderr_initial_c_lflag_ = PosixConsole::kInvalidFlag;
tcflag_t PosixConsole::stdin_initial_c_lflag_ = PosixConsole::kInvalidFlag;

void Console::SaveConfig() {
  PosixConsole::Initialize();
}

void Console::RestoreConfig() {
  PosixConsole::Cleanup();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||
        // defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA)
