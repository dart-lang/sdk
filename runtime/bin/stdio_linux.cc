// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "bin/stdio.h"

#include <errno.h>      // NOLINT
#include <sys/ioctl.h>  // NOLINT
#include <termios.h>    // NOLINT

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool Stdin::ReadByte(intptr_t fd, int* byte) {
  unsigned char b;
  ssize_t s = TEMP_FAILURE_RETRY(read(fd, &b, 1));
  if (s < 0) {
    return false;
  }
  *byte = (s == 0) ? -1 : b;
  return true;
}

bool Stdin::GetEchoMode(intptr_t fd, bool* enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
  if (status != 0) {
    return false;
  }
  *enabled = ((term.c_lflag & ECHO) != 0);
  return true;
}

bool Stdin::SetEchoMode(intptr_t fd, bool enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
  if (status != 0) {
    return false;
  }
  if (enabled) {
    term.c_lflag |= (ECHO | ECHONL);
  } else {
    term.c_lflag &= ~(ECHO | ECHONL);
  }
  status = NO_RETRY_EXPECTED(tcsetattr(fd, TCSANOW, &term));
  return (status == 0);
}

bool Stdin::GetLineMode(intptr_t fd, bool* enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
  if (status != 0) {
    return false;
  }
  *enabled = ((term.c_lflag & ICANON) != 0);
  return true;
}

bool Stdin::SetLineMode(intptr_t fd, bool enabled) {
  struct termios term;
  int status = NO_RETRY_EXPECTED(tcgetattr(fd, &term));
  if (status != 0) {
    return false;
  }
  if (enabled) {
    term.c_lflag |= ICANON;
  } else {
    term.c_lflag &= ~(ICANON);
  }
  status = NO_RETRY_EXPECTED(tcsetattr(fd, TCSANOW, &term));
  return (status == 0);
}

static bool TermIsKnownToSupportAnsi() {
  const char* term = getenv("TERM");
  if (term == NULL) {
    return false;
  }

  return strstr(term, "xterm") != NULL || strstr(term, "screen") != NULL ||
         strstr(term, "rxvt") != NULL;
}

bool Stdin::AnsiSupported(intptr_t fd, bool* supported) {
  *supported = (isatty(fd) != 0) && TermIsKnownToSupportAnsi();
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
  *supported = (isatty(fd) != 0) && TermIsKnownToSupportAnsi();
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
