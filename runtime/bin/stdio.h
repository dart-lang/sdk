// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_STDIO_H_
#define RUNTIME_BIN_STDIO_H_

#include "bin/builtin.h"
#include "bin/utils.h"

#include "platform/globals.h"

namespace dart {
namespace bin {

class Stdin {
 public:
  static bool ReadByte(int* byte);

  static bool GetEchoMode(bool* enabled);
  static bool SetEchoMode(bool enabled);

  static bool GetLineMode(bool* enabled);
  static bool SetLineMode(bool enabled);

  static bool AnsiSupported(bool* supported);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Stdin);
};

class Stdout {
 public:
  static bool GetTerminalSize(intptr_t fd, int size[2]);
  static bool AnsiSupported(intptr_t fd, bool* supported);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Stdout);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_STDIO_H_
