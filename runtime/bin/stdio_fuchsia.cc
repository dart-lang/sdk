// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/stdio.h"

#include <errno.h>

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
  errno = ENOSYS;
  return false;
}

bool Stdin::SetEchoMode(intptr_t fd, bool enabled) {
  errno = ENOSYS;
  return false;
}

bool Stdin::GetLineMode(intptr_t fd, bool* enabled) {
  errno = ENOSYS;
  return false;
}

bool Stdin::SetLineMode(intptr_t fd, bool enabled) {
  errno = ENOSYS;
  return false;
}

bool Stdin::AnsiSupported(intptr_t fd, bool* supported) {
  *supported = false;
  return true;
}

bool Stdout::GetTerminalSize(intptr_t fd, int size[2]) {
  errno = ENOSYS;
  return false;
}

bool Stdout::AnsiSupported(intptr_t fd, bool* supported) {
  *supported = false;
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
