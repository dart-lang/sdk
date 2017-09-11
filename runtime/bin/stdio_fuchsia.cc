// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/stdio.h"

namespace dart {
namespace bin {

bool Stdin::ReadByte(int* byte) {
  UNIMPLEMENTED();
  return false;
}

bool Stdin::GetEchoMode(bool* enabled) {
  UNIMPLEMENTED();
  return false;
}

bool Stdin::SetEchoMode(bool enabled) {
  UNIMPLEMENTED();
  return false;
}

bool Stdin::GetLineMode(bool* enabled) {
  UNIMPLEMENTED();
  return false;
}

bool Stdin::SetLineMode(bool enabled) {
  UNIMPLEMENTED();
  return false;
}

bool Stdin::AnsiSupported(bool* supported) {
  UNIMPLEMENTED();
  return false;
}

bool Stdout::GetTerminalSize(intptr_t fd, int size[2]) {
  UNIMPLEMENTED();
  return false;
}

bool Stdout::AnsiSupported(intptr_t fd, bool* supported) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
