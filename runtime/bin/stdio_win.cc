// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/stdio.h"

namespace dart {
namespace bin {

bool Stdin::ReadByte(int* byte) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  uint8_t buffer[1];
  DWORD read = 0;
  BOOL success = ReadFile(h, buffer, 1, &read, NULL);
  if (!success && (GetLastError() != ERROR_BROKEN_PIPE)) {
    return false;
  }
  *byte = (read == 1) ? buffer[0] : -1;
  return true;
}


bool Stdin::GetEchoMode(bool* enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return false;
  }
  *enabled = ((mode & ENABLE_ECHO_INPUT) != 0);
  return true;
}


bool Stdin::SetEchoMode(bool enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return false;
  }
  if (enabled) {
    mode |= ENABLE_ECHO_INPUT;
  } else {
    mode &= ~ENABLE_ECHO_INPUT;
  }
  return SetConsoleMode(h, mode);
}


bool Stdin::GetLineMode(bool* enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return false;
  }
  *enabled = (mode & ENABLE_LINE_INPUT) != 0;
  return true;
}


bool Stdin::SetLineMode(bool enabled) {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return false;
  }
  if (enabled) {
    mode |= ENABLE_LINE_INPUT;
  } else {
    mode &= ~ENABLE_LINE_INPUT;
  }
  return SetConsoleMode(h, mode);
}


bool Stdout::GetTerminalSize(intptr_t fd, int size[2]) {
  HANDLE h;
  if (fd == 1) {
    h = GetStdHandle(STD_OUTPUT_HANDLE);
  } else {
    h = GetStdHandle(STD_ERROR_HANDLE);
  }
  CONSOLE_SCREEN_BUFFER_INFO info;
  if (!GetConsoleScreenBufferInfo(h, &info)) {
    return false;
  }
  size[0] = info.srWindow.Right - info.srWindow.Left + 1;
  size[1] = info.srWindow.Bottom - info.srWindow.Top + 1;
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)

#endif  // !defined(DART_IO_DISABLED)
