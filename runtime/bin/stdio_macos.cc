// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include <errno.h>  // NOLINT
#include <sys/ioctl.h>  // NOLINT
#include <termios.h>  // NOLINT

#include "bin/stdio.h"
#include "bin/fdutils.h"
#include "bin/signal_blocker.h"


namespace dart {
namespace bin {

int Stdin::ReadByte() {
  int c = getchar();
  if (c == EOF) {
    c = -1;
  }
  return c;
}


bool Stdin::GetEchoMode() {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  return (term.c_lflag & ECHO) != 0;
}


void Stdin::SetEchoMode(bool enabled) {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  if (enabled) {
    term.c_lflag |= ECHO|ECHONL;
  } else {
    term.c_lflag &= ~(ECHO|ECHONL);
  }
  tcsetattr(STDIN_FILENO, TCSANOW, &term);
}


bool Stdin::GetLineMode() {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  return (term.c_lflag & ICANON) != 0;
}


void Stdin::SetLineMode(bool enabled) {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  if (enabled) {
    term.c_lflag |= ICANON;
  } else {
    term.c_lflag &= ~(ICANON);
  }
  tcsetattr(STDIN_FILENO, TCSANOW, &term);
}


bool Stdout::GetTerminalSize(int size[2]) {
  struct winsize w;
  if (TEMP_FAILURE_RETRY_BLOCK_SIGNALS(
        ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0) &&
      (w.ws_col != 0 || w.ws_row != 0)) {
    size[0] = w.ws_col;
    size[1] = w.ws_row;
    return true;
  }
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
