// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/stdio.h"

namespace dart {
namespace bin {

int Stdin::ReadByte() {
  UNIMPLEMENTED();
  return -1;
}


bool Stdin::GetEchoMode() {
  UNIMPLEMENTED();
  return false;
}


void Stdin::SetEchoMode(bool enabled) {
  UNIMPLEMENTED();
}


bool Stdin::GetLineMode() {
  UNIMPLEMENTED();
  return false;
}


void Stdin::SetLineMode(bool enabled) {
  UNIMPLEMENTED();
}


bool Stdout::GetTerminalSize(intptr_t fd, int size[2]) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
