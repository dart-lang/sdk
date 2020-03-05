// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_DARTDEV_UTILS_H_
#define RUNTIME_BIN_DARTDEV_UTILS_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

class DartDevUtils {
 public:
  // Returns true if there does not exist a file at |script_uri| or the URI is
  // not an HTTP resource.
  static bool ShouldParseCommand(const char* script_uri);

  // Returns true if we were successfully able to find the DartDev snapshot.
  // Returns false if we were unable to find the snapshot, in which case the
  // VM should exit.
  static bool TryResolveDartDevSnapshotPath(char** script_name);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartDevUtils);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_DARTDEV_UTILS_H_
