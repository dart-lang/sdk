// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include <termios.h>  // NOLINT

#include "bin/stdin.h"
#include "bin/fdutils.h"


namespace dart {
namespace bin {

int Stdin::ReadByte() {
  FDUtils::SetBlocking(fileno(stdin));
  int c = getchar();
  if (c == EOF) {
    c = -1;
  }
  FDUtils::SetNonBlocking(fileno(stdin));
  return c;
}


void Stdin::SetEchoMode(bool enabled) {
  struct termios term;
  tcgetattr(fileno(stdin), &term);
  if (enabled) {
    term.c_lflag |= ECHO|ECHONL;
  } else {
    term.c_lflag &= ~(ECHO|ECHONL);
  }
  tcsetattr(fileno(stdin), TCSANOW, &term);
}


void Stdin::SetLineMode(bool enabled) {
  struct termios term;
  tcgetattr(fileno(stdin), &term);
  if (enabled) {
    term.c_lflag |= ICANON;
  } else {
    term.c_lflag &= ~(ICANON);
  }
  tcsetattr(fileno(stdin), TCSANOW, &term);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)

