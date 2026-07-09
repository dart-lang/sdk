// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_CONSOLE_H_
#define RUNTIME_BIN_CONSOLE_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

class Console {
 public:
  static void SaveConfig();
  static void RestoreConfig();

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Console);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_CONSOLE_H_
