// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/stdio.h"

#include <errno.h>      // NOLINT
#include <sys/ioctl.h>  // NOLINT
#include <termios.h>    // NOLINT

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool Stdin::ReadByte(int* byte) {
  int c = NO_RETRY_EXPECTED(getchar());
  if ((c == EOF) && (errno != 0)) {
    return false;
  }
  *byte = (c == EOF) ? -1 : c;
  return true;
}

bool Stdin::GetEchoMode(bool* enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(STDIN_FILENO, &term));
  if (status != 0) {
    return false;
  }
  *enabled = ((term.c_lflag & ECHO) != 0);
  return true;
}

bool Stdin::SetEchoMode(bool enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(STDIN_FILENO, &term));
  if (status != 0) {
    return false;
  }
  if (enabled) {
    term.c_lflag |= (ECHO | ECHONL);
  } else {
    term.c_lflag &= ~(ECHO | ECHONL);
  }
  status = NO_RETRY_EXPECTED(tcsetattr(STDIN_FILENO, TCSANOW, &term));
  return (status == 0);
}

bool Stdin::GetLineMode(bool* enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(STDIN_FILENO, &term));
  if (status != 0) {
    return false;
  }
  *enabled = ((term.c_lflag & ICANON) != 0);
  return true;
}

bool Stdin::SetLineMode(bool enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(STDIN_FILENO, &term));
  if (status != 0) {
    return false;
  }
  if (enabled) {
    term.c_lflag |= ICANON;
  } else {
    term.c_lflag &= ~(ICANON);
  }
  status = NO_RETRY_EXPECTED(tcsetattr(STDIN_FILENO, TCSANOW, &term));
  return (status == 0);
}

static bool TermHasXTerm() {
  const char* term = getenv("TERM");
  if (term == NULL) {
    return false;
  }
  return strstr(term, "xterm") != NULL;
}

bool Stdin::AnsiSupported(bool* supported) {
  *supported = isatty(STDIN_FILENO) && TermHasXTerm();
  return true;
}

bool Stdout::GetTerminalSize(intptr_t fd, int size[2]) {
  struct winsize w;
  int status = NO_RETRY_EXPECTED(ioctl(fd, TIOCGWINSZ, &w));
  if ((status == 0) && ((w.ws_col != 0) || (w.ws_row != 0))) {
    size[0] = w.ws_col;
    size[1] = w.ws_row;
    return true;
  }
  return false;
}

bool Stdout::AnsiSupported(intptr_t fd, bool* supported) {
  *supported = isatty(fd) && TermHasXTerm();
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
