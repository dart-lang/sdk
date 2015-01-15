// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/stdio.h"


namespace dart {
namespace bin {

int Stdin::ReadByte() {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  uint8_t buffer[1];
  DWORD read = 0;
  int c = -1;
  if (ReadFile(h, buffer, 1, &read, NULL) && read == 1) {
    c = buffer[0];
  }
  return c;
}


bool Stdin::GetEchoMode() {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) return false;
  return (mode & ENABLE_ECHO_INPUT) != 0;
}


void Stdin::SetEchoMode(bool enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) return;
  if (enabled) {
    mode |= ENABLE_ECHO_INPUT;
  } else {
    mode &= ~ENABLE_ECHO_INPUT;
  }
  SetConsoleMode(h, mode);
}


bool Stdin::GetLineMode() {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) return false;
  return (mode & ENABLE_LINE_INPUT) != 0;
}


void Stdin::SetLineMode(bool enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) return;
  if (enabled) {
    mode |= ENABLE_LINE_INPUT;
  } else {
    mode &= ~ENABLE_LINE_INPUT;
  }
  SetConsoleMode(h, mode);
}


bool Stdout::GetTerminalSize(int size[2]) {
  HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
  CONSOLE_SCREEN_BUFFER_INFO info;
  if (!GetConsoleScreenBufferInfo(h, &info)) return false;
  size[0] = info.srWindow.Right - info.srWindow.Left + 1;
  size[1] = info.srWindow.Bottom - info.srWindow.Top + 1;
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
