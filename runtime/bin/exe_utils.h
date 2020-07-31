// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EXE_UTILS_H_
#define RUNTIME_BIN_EXE_UTILS_H_

#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

class EXEUtils {
 public:
  // Returns the path to the directory the current executable resides in.
  static Utils::CStringUniquePtr GetDirectoryPrefixFromExeName();

 private:
  DISALLOW_COPY_AND_ASSIGN(EXEUtils);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EXE_UTILS_H_
